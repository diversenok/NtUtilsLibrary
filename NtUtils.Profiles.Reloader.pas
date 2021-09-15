unit NtUtils.Profiles.Reloader;

{
  This module provides support for hot reloading of user profiles.
}

interface

uses
  Ntapi.WinNt, Ntapi.UserEnv, Ntapi.ntseapi, DelphiApi.Reflection, NtUtils,
  NtUtils.Objects.Snapshots, NtUtils.Profiles;

type
  TProcessOperation = reference to procedure (
    const Status: TNtxStatus;
    ProcessId: TProcessId
  );

  THandleOperation = reference to procedure (
    const Status: TNtxStatus;
    const Handle: TProcessHandleEntry
  );

  TNamedHandleOperation = reference to procedure (
    const Status: TNtxStatus;
    const Handle: TProcessHandleEntry;
    const KeyName: String
  );

  TKeyOperation = reference to procedure (
    const Status: TNtxStatus;
    const KeyName: String
  );

  TKeyValueOperation = reference to procedure (
    const Status: TNtxStatus;
    const KeyName: String;
    const ValueName: String
  );

  [NamingStyle(nsCamelCase, 'pr')]
  TProfileReloaderPhase = (
    prHandleCapture,
    prVolatileKeyBackup,
    prUnload,
    prLoad,
    prVolatileKeyRestore,
    prHandleRetargeting
  );

  TPhaseChange = reference to procedure (
    Phase: TProfileReloaderPhase
  );

  // NOTE: be extremely careful not to use any functions in the event callbacks
  // that rely on inter-process communication (including console I/O) since it
  // has a great chance of deadlocking the entire operation.

  TProfileReloaderEvents = record
    // Brief status updates
    OnPhaseChange: TPhaseChange;

    // Detailed process handle backup
    OnProcessPrepare: TProcessOperation;
    OnHandleNameCheck: THandleOperation;

    // Detailed volatile key backup
    OnKeyInspect: TKeyOperation;
    OnKeyBackup: TKeyOperation;

    // Detailed volatile key restore
    OnKeyRestore: TKeyOperation;
    OnValueRestore: TKeyValueOperation;

    // Detailed process handle re-targeting
    OnHandleUpdate: TNamedHandleOperation;
  end;

// Load a user profile with volatile registry
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpAlways)]
function UnvxLoadProfileVolatile(
  out hxKey: IHandle;
  [Access(TOKEN_LOAD_PROFILE)] const hxToken: IHandle
): TNtxStatus;

// Load a user profile with volatile registry monitoring the progress
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpAlways)]
function UnvxLoadProfileVolatileEx(
  out hxKey: IHandle;
  [Access(TOKEN_LOAD_PROFILE)] const hxToken: IHandle;
  const Events: TProfileReloaderEvents
): TNtxStatus;

// Hot-reload a profile
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpAlways)]
function UnvxReloadProfile(
  [in] Sid: PSid;
  MakeVolatile: Boolean
): TNtxStatus;

// Hot-reload a profile monitoring the progress
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpAlways)]
function UnvxReloadProfileEx(
  [in] Sid: PSid;
  MakeVolatile: Boolean;
  const Events: TProfileReloaderEvents
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntregapi, Ntapi.ntpsapi, Ntapi.ntstatus, NtUtils.SysUtils,
  NtUtils.Registry, NtUtils.Processes, NtUtils.Files, NtUtils.Objects,
  NtUtils.Objects.Remote, NtUtils.Shellcode, NtUtils.Security.Sid,
  NtUtils.Tokens, NtUtils.Tokens.Info, NtUtils.Processes.Snapshots,
  NtUtils.Environment, DelphiUtils.Arrays;

const
  PROFILE_CLASSES_HIVE = '_Classes';
  PROFILE_HIVE_FILE = '\NTUSER.DAT';
  PROFILE_MANDATORY_HIVE_FILE = '\NTUSER.MAN';
  PROFILE_CLASSES_FILE = '\AppData\Local\Microsoft\Windows\UsrClass.dat';

{ ----------------------- Capturing Handle Information ----------------------- }

{
  Forsibly reloading the hives of a profile invalidates registry handles.
  So, we need to snaphot them and save for a replacement on a later stage.
}

type
  TOpenedKeyEntry = record
    Name: String;
    IsDeleted: Boolean;
    Info: TProcessHandleEntry;
  end;

  THiveConsumer = record
    ProcessId: TProcessId;
    [Access(PROCESS_DUP_HANDLE or PROCESS_QUERY_INFORMATION or
      PROCESS_SUSPEND_RESUME)] hxProcess: IHandle;
    Resumer: IAutoReleasable;
    Keys: TArray<TOpenedKeyEntry>;
  end;

var
  // Type index for registry keys
  KeyTypeIndex: Word;

// Provides a function for finding names for registry key handles
function KeyNameFinder(
  [Access(PROCESS_DUP_HANDLE)] const hxProcess: IHandle;
  const Events: TProfileReloaderEvents
): TConvertRoutine<TProcessHandleEntry, TOpenedKeyEntry>;
begin
  Result := function (
      const Entry: TProcessHandleEntry;
      out Key: TOpenedKeyEntry
    ): Boolean
    var
      hxKey: IHandle;
      Status: TNtxStatus;
    begin
      // We are only interested in registry keys
      if Entry.ObjectTypeIndex <> KeyTypeIndex then
        Exit(False);

      Key.Info := Entry;

      // Get a copy of the handle
      Status := NtxDuplicateHandleFrom(hxProcess.Handle, Entry.HandleValue,
        hxKey);

      // Query its name
      if Status.IsSuccess then
        Status := NtxQueryNameObject(hxKey.Handle, Key.Name);

      // Report progress
      if Assigned(Events.OnHandleNameCheck) then
        Events.OnHandleNameCheck(Status, Entry);

      // We cannot query names for deleted keys, so we cannot say for sure it
      // belongs to the hive. In any case, we can later replace the handle with
      // a deleted one from the reloaded hive. Otherwise, if it does belong to
      // our hive, unloading it will cause registry functions to return
      // STATUS_HIVE_UNLOADED instead of expected STATUS_KEY_DELETED.
      Key.IsDeleted := Status.Status = STATUS_KEY_DELETED;
      Result := Status.IsSuccess or Key.IsDeleted;
    end;
end;

// Provides a function to check if a key points to a profile
function IsWithinProfile(
  const UserKeyPath: String;
  FullProfile: Boolean
): TCondition<TOpenedKeyEntry>;
begin
  Result := function (const Key: TOpenedKeyEntry): Boolean
    begin
      // Should be under HKU/S-1-... or HKU/S-1-..._Classes for full profiles
      Result := Key.IsDeleted or RtlxIsPathUnderRoot(Key.Name, UserKeyPath) or
        (FullProfile and RtlxIsPathUnderRoot(Key.Name,
        UserKeyPath + PROFILE_CLASSES_HIVE))
    end;
end;

// Provides a function for capturing state of processes that use the hive
function ConsumerInfoCapturer(
  const UserKeyPath: String;
  FullProfile: Boolean;
  const Events: TProfileReloaderEvents
): TConvertRoutine<TProcessEntry, THiveConsumer>;
begin
  Result := function (
      const Process: TProcessEntry;
      out Consumer: THiveConsumer
    ): Boolean
    var
      Status: TNtxStatus;
      AllKeys: TArray<TOpenedKeyEntry>;
      Handles: TArray<TProcessHandleEntry>;
    begin
      Consumer.ProcessId := Process.Basic.ProcessID;

      // Open the process for inspection and safe handle manipulation
      Status := NtxOpenProcess(Consumer.hxProcess, Consumer.ProcessId,
        PROCESS_DUP_HANDLE or PROCESS_QUERY_INFORMATION or
        PROCESS_SUSPEND_RESUME);

      // Suspending processes does prevent race conditions, but is also risky
      // since we can deadlock.
      if Status.IsSuccess and (Consumer.ProcessId <> NtCurrentProcessId) and
        NtxSuspendProcess(Consumer.hxProcess.Handle).IsSuccess then
        Consumer.Resumer := NtxDelayedResumeProcess(Consumer.hxProcess);

      // TODO: add deadlock protection that resumes the process after a timeout

      // Snapshot all handles it has
      if Status.IsSuccess then
        Status := NtxEnumerateHandlesProcess(Consumer.hxProcess.Handle,
          Handles);

      // Report progress
      if Assigned(Events.OnProcessPrepare) then
        Events.OnProcessPrepare(Status, Consumer.ProcessId);

      // Find registry keys and determine their names
      if Status.IsSuccess then
        AllKeys := TArray.Convert<TProcessHandleEntry, TOpenedKeyEntry>(Handles,
          KeyNameFinder(Consumer.hxProcess, Events));

      // Capture only the keys within the profile
      if Status.IsSuccess then
        Consumer.Keys := TArray.Filter<TOpenedKeyEntry>(AllKeys,
          IsWithinProfile(UserKeyPath, FullProfile));

      Result := Status.IsSuccess and (Length(Consumer.Keys) > 0);
    end
end;

// Capture names and values for all open registry handles within a profile
function CaptureProfileConsumers(
  out HiveConsumers: TArray<THiveConsumer>;
  const UserKeyPath: String;
  FullProfile: Boolean;
  const Events: TProfileReloaderEvents
): TNtxStatus;
var
  TypeIndex: Integer;
  Processes: TArray<TProcessEntry>;
begin
  // Determine the type index for registry keys
  Result := NtxFindType('Key', TypeIndex);

  if not Result.IsSuccess then
    Exit;

  KeyTypeIndex := Word(TypeIndex);

  // Find all candidates for being hive consumers. Note that, unfortunately, we
  // cannot use NtQueryOpenSubKeysEx for that because it always attributes the
  // keys to the process that opened them, and not to the one that holds the
  // handle. So, after a round of handle replacement, ALL existing handles
  // within the hives will have our process ID associated. Therefore, subsequent
  // profile reloads will not find all consumers and will, probably, crash them
  // without handle replacement. Probing all processes on the system might seem
  // as overkill, but I cannot find a better solution.
  Result := NtxEnumerateProcesses(Processes);

  if not Result.IsSuccess then
    Exit;

  // For each process, suspend it and save relevant key information
  HiveConsumers := TArray.Convert<TProcessEntry, THiveConsumer>(Processes,
    ConsumerInfoCapturer(UserKeyPath, FullProfile, Events));
end;

{ ------------------------ Backing Up Volatile Keys ------------------------- }

{
  Unloading a hive deletes all volatile keys within it. We need to traverse the
  registry and backup all such keys so we can restore them later.
}

type
  TVolatileKey = record
    KeyName: String;
    IsSymlink: Boolean;
    SymlinkTarget: String;
    Security: ISecDesc;
    Values: TArray<TRegValueDataEntry>;
  end;

// Recursively process the keys, collecting the volatile ones
function TraverseKeys(
  var VolatileKeys: TArray<TVolatileKey>;
  const Events: TProfileReloaderEvents;
  Name: String;
  [opt] const RootName: String = '';
  [opt] ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;
var
  hxKey: IHandle;
  Flags: TKeyFlagsInformation;
  SubKeys: TArray<String>;
  i: Integer;
begin
  Result.Status := STATUS_SUCCESS;
  ObjectAttributes := AttributeBuilder(ObjectAttributes)
    .UseAttributes(OBJ_OPENLINK);

  try
    // Open the key for inspection
    Result := NtxOpenKey(hxKey, Name, KEY_ENUMERATE_SUB_KEYS or KEY_QUERY_VALUE
      or READ_CONTROL, REG_OPTION_BACKUP_RESTORE, ObjectAttributes);

    if RootName <> '' then
      Name := RootName + '\' + Name;

    if not Result.IsSuccess then
      Exit;

    // Check for interesting flags
    Result := NtxKey.Query(hxKey.Handle, KeyFlagsInformation, Flags);

    if not Result.IsSuccess then
      Exit;

    if BitTest(Flags.KeyFlags and REG_FLAG_VOLATILE) then
    begin
      // Volatile keys require backup
      SetLength(VolatileKeys, Length(VolatileKeys) + 1);

      with VolatileKeys[High(VolatileKeys)] do
      begin
        KeyName := Name;

        if BitTest(Flags.KeyFlags and REG_FLAG_LINK) then
        begin
          // Save targets for symlinks
          Result := NtxQueryValueKeyString(hxKey.Handle, REG_SYMLINK_VALUE_NAME,
            SymlinkTarget);

          if Result.IsSuccess then
            IsSymlink := True;
        end
        else
        begin
          // Save all values for regular keys
          Result := NtxEnumerateValuesDataKey(hxKey.Handle, Values);
        end;

        // Save the security descriptor
        if Result.IsSuccess then
          Result := NtxQuerySecurityObject(hxKey.Handle,
            OWNER_SECURITY_INFORMATION or GROUP_SECURITY_INFORMATION or
            DACL_SECURITY_INFORMATION or LABEL_SECURITY_INFORMATION or
            SACL_SECURITY_INFORMATION, Security);

        // Report progress
        if Assigned(Events.OnKeyBackup) then
          Events.OnKeyBackup(Result, Name);
      end;
    end;

    // Traverse every non-symlink key
    if not BitTest(Flags.KeyFlags and REG_FLAG_LINK) then
      Result := NtxEnumerateSubKeys(hxKey.Handle, SubKeys)
    else
      SubKeys := nil;

    if not Result.IsSuccess then
      Exit;

  finally
    // Report progress
    if Assigned(Events.OnKeyInspect) then
      Events.OnKeyInspect(Result, Name);
  end;

  // Process sub-keys recursively
  for i := 0 to High(SubKeys) do
    TraverseKeys(VolatileKeys, Events, SubKeys[i], Name,
      ObjectAttributes.UseRoot(hxKey));
end;

// Collect all volatile keys within the profile's hives
function BackupVolatileKeys(
  const UserKeyPath: String;
  FullProfile: Boolean;
  out VolatileKeys: TArray<TVolatileKey>;
  const Events: TProfileReloaderEvents
): TNtxStatus;
var
  VolatileKeys2: TArray<TVolatileKey>;
begin
  // Find all volatile keys under HKU\S-1-...
  Result := TraverseKeys(VolatileKeys, Events, UserKeyPath);

  if not Result.IsSuccess then
    Exit;

  if FullProfile then
  begin
    // Find all volatile keys under HKU\S-1-..._Classes
    Result := TraverseKeys(VolatileKeys2, Events, UserKeyPath +
      PROFILE_CLASSES_HIVE);

    if Result.IsSuccess then
      VolatileKeys := VolatileKeys + VolatileKeys2
    else
      VolatileKeys := nil;  
  end;  
end;

{ ---------------------------- Unloading Profile ---------------------------- }

// Forcibly dismount the registry hives of the profile
function ForceUnloadProfile(
  const UserKeyPath: string;
  FullProfile: Boolean
): TNtxStatus;
begin
  Result := NtxUnloadKey(UserKeyPath, True);

  if FullProfile and Result.IsSuccess then
    Result := NtxUnloadKey(UserKeyPath + PROFILE_CLASSES_HIVE, True);
end;

{ ----------------------------- Loading Profile ----------------------------- }

// Mount the registry hives of the profile
function LoadProfile(
  const KeyPath: String;
  ProfilePath: String;
  FullProfile: Boolean;
  LoadFlags: TRegLoadFlags
): TNtxStatus;
var
  hxUserKey, hxClassesKey: IHandle;
begin
  // Make the profile path absolute
  Result := RtlxExpandStringVar(RtlxCurrentEnvironment, ProfilePath);

  if not Result.IsSuccess then
    Exit;

  // Convert it to a native format
  Result := RtlxDosPathToNtPathVar(ProfilePath);

  if not Result.IsSuccess then
    Exit;

  // TODO: should probably use NtLoadKey3 when available

  // Load the main hive
  Result := NtxLoadKeyEx(hxUserKey, ProfilePath + PROFILE_HIVE_FILE, KeyPath,
    LoadFlags);

  // If we are missing the regular hive file, retry with mandatory one
  if Result.Status = STATUS_OBJECT_NAME_NOT_FOUND then
    Result := NtxLoadKeyEx(hxUserKey, ProfilePath +
      PROFILE_MANDATORY_HIVE_FILE, KeyPath, LoadFlags);

  if not Result.IsSuccess then
    Exit;  

  if FullProfile then
  begin
    // Load the Classes key using the User key as a trust class key
    // to make the symlink to Classes work
    Result := NtxLoadKeyEx(hxClassesKey, ProfilePath + PROFILE_CLASSES_FILE,
      KeyPath + PROFILE_CLASSES_HIVE, LoadFlags, hxUserKey.Handle);

    // Undo partial profile load
    if not Result.IsSuccess then
      NtxUnloadKey(KeyPath, True);
  end;
end;

{ ------------------------- Restoring Volatile Keys ------------------------- }

{
  Unloading the hive deleted all volatile keys. Fortunately, we captured their
  names, values, and security descriptors so we recreate them.
}

// Restore volatile keys from the snapshot.
procedure RestoreVolatileKeys(
  const Keys: TArray<TVolatileKey>;
  const Events: TProfileReloaderEvents
);
var
  i, j: Integer;
  Result: TNtxStatus;
  hxKey: IHandle;
begin
  for i := 0 to High(Keys) do
  begin
    if Keys[i].IsSymlink then
      // Create a volatile symlink
      Result := NtxCreateSymlinkKey(Keys[i].KeyName, Keys[i].SymlinkTarget,
        REG_OPTION_VOLATILE or REG_OPTION_BACKUP_RESTORE,
        AttributeBuilder.UseSecurity(Keys[i].Security))
    else
    begin
      // Create a regular volatile key
      Result := NtxCreateKey(hxKey, Keys[i].KeyName, KEY_SET_VALUE,
        REG_OPTION_VOLATILE or REG_OPTION_BACKUP_RESTORE,
        AttributeBuilder.UseSecurity(Keys[i].Security));

      // Restore each value
      if Result.IsSuccess then
        for j := 0 to High(Keys[i].Values) do
          with Keys[i].Values[j] do
          begin
            Result := NtxSetValueKey(hxKey.Handle, ValueName, ValueType,
              ValueData.Data, ValueData.Size);

            // Report progress with values
            if Assigned(Events.OnValueRestore) then
              Events.OnValueRestore(Result, Keys[i].KeyName, ValueName);
          end;
    end;

    // Report progress with keys
    if Assigned(Events.OnKeyRestore) then
      Events.OnKeyRestore(Result, Keys[i].KeyName);
  end;
end;

{ --------------------------- Retargeting Handles --------------------------- }

{
  Forsibly reloding a hive invalidates outstanding handles within it.
  Fortunately, we took a snapshot, so we can reoped equivalent keys within the
  new hive and replace all these broken handles.
}

// For each process, replace the handles pointing to the old hive with
// equivalent handles pointing to the new one.
procedure RetargetKeyHandles(
  const UserKeyPath: string;
  const HiveConsumers: TArray<THiveConsumer>;
  const Events: TProfileReloaderEvents
);
const
  UNPROTECT_TIMEOUT = 1000 * MILLISEC;
var
  i, j: Integer;
  hxDeletedKey, hxKey: IHandle;
  Result: TNtxStatus;
  hxProcessRCE: IHandle;
begin
  // Create a dummy key for deletion. We want to replace the handles to the keys
  // that do not exist in the new hive with a handle to a valid but deleted key.
  // This way registry operations return STATUS_KEY_DELETED instead of
  // unexpected STATUS_HIVE_UNLOADED.
  if not NtxCreateKey(hxDeletedKey, UserKeyPath + '\' + RtlxGuidToString(
    RtlxRandomGuid), KEY_ALL_ACCESS, REG_OPTION_VOLATILE).IsSuccess then
    hxDeletedKey := nil;

  for i := 0 to High(HiveConsumers) do
    for j := 0 to High(HiveConsumers[i].Keys) do
      with HiveConsumers[i], Keys[j], Info do
      begin
        // Open the key within the new hive
        if not IsDeleted then
          Result := NtxOpenKey(hxKey, Name, GrantedAccess,
            REG_OPTION_BACKUP_RESTORE);

        // For an already deleted or a non-existent key, prepare a handle that
        // simulates its deletion.
        if IsDeleted or (Result.Status = STATUS_OBJECT_NAME_NOT_FOUND) then
        begin
          if Assigned(hxDeletedKey) then
            Result := NtxDuplicateHandleLocal(hxDeletedKey.Handle, hxKey,
              GrantedAccess)
          else
          begin
            Result.Location := 'RetargetKeyHandles';
            Result.Status := STATUS_CANNOT_DELETE;
          end;
        end;

        // Replacing protected handles requires lifting protection first
        if BitTest(HandleAttributes and OBJ_PROTECT_CLOSE) then
        begin
          // We need more access to the target process to do that
          if Result.IsSuccess then
            Result := NtxOpenProcess(hxProcessRCE, ProcessId,
              PROCESS_SET_HANDLE_FLAGS);

          // Unprotect the handle by setting attributes remotely
          if Result.IsSuccess then
            Result := NtxSetFlagsHandleRemote(hxProcessRCE, HandleValue,
              BitTest(HandleAttributes and OBJ_INHERIT), False,
              UNPROTECT_TIMEOUT);
        end;

        // Replace the old broken handle with a new equivalent one
        if Result.IsSuccess then
          Result := NtxReplaceHandle(hxProcess.Handle, HandleValue,
            hxKey.Handle, BitTest(HandleAttributes and OBJ_INHERIT));

        // Protect the handle back if necessary
        if Result.IsSuccess and Assigned(hxProcessRCE) and
          BitTest(HandleAttributes and OBJ_PROTECT_CLOSE) then
          Result := NtxSetFlagsHandleRemote(hxProcessRCE, HandleValue,
            BitTest(HandleAttributes and OBJ_INHERIT), True,
            UNPROTECT_TIMEOUT);

        // Report progress
        if Assigned(Events.OnHandleUpdate) then
          Events.OnHandleUpdate(Result, Info, Name);
      end;

  // Complete deletion for the dummy key
  NtxDeleteKey(hxDeletedKey.Handle);
end;

{ -------------------------------- Combined --------------------------------- }

// Combine all phases of profile reloading
function ReloadProfile(
  [in] Sid: PSid;
  LoadFlags: TRegLoadFlags;
  const Events: TProfileReloaderEvents
): TNtxStatus;
var
  UserKeyPath: String;
  Info: TProfileInfo;
  HiveConumers: TArray<THiveConsumer>;
  VolatileBackup: TArray<TVolatileKey>;
begin
  // Determine information about the profile
  Result := UnvxQueryProfile(Sid, Info);

  if not Result.IsSuccess then
    Exit;

  UserKeyPath := REG_PATH_USER + '\' + RtlxSidToString(Sid);

  { Phase one: determine who uses the hives we are about to reload }

  if Assigned(Events.OnPhaseChange) then
    Events.OnPhaseChange(prHandleCapture);

  Result := CaptureProfileConsumers(HiveConumers, UserKeyPath, Info.FullProfile,
    Events);

  if not Result.IsSuccess then
    Exit;

  { Phase two: backup volatile keys, so we can restore them afterwards }

  if Assigned(Events.OnPhaseChange) then
    Events.OnPhaseChange(prVolatileKeyBackup);

  Result := BackupVolatileKeys(UserKeyPath, Info.FullProfile, VolatileBackup,
    Events);

  if not Result.IsSuccess then
    Exit;

  { Phase three: unload the profile }

  if Assigned(Events.OnPhaseChange) then
    Events.OnPhaseChange(prUnload);

  Result := ForceUnloadProfile(UserKeyPath, Info.FullProfile);

  if not Result.IsSuccess then
    Exit;

  { Phase four: load the profile back }

  if Assigned(Events.OnPhaseChange) then
    Events.OnPhaseChange(prLoad);

  Result := LoadProfile(UserKeyPath, Info.ProfilePath, Info.FullProfile,
    LoadFlags);

  if not Result.IsSuccess then
    Exit;

  { Phase five: restore volatile keys from the backup }

  if Assigned(Events.OnPhaseChange) then
    Events.OnPhaseChange(prVolatileKeyRestore);

  RestoreVolatileKeys(VolatileBackup, Events);

  { Phase six: retarget the handles from the old hive to the new one }

  if Assigned(Events.OnPhaseChange) then
    Events.OnPhaseChange(prHandleRetargeting);

  RetargetKeyHandles(UserKeyPath, HiveConumers, Events);
end;

function EnsurePrivileges: TNtxStatus;
begin
  // Backup and Restore are essential;
  // Debug is extremely helpful, though not strictly necessary
  Result := NtxAdjustPrivileges(NtxCurrentEffectiveToken, [SE_BACKUP_PRIVILEGE,
    SE_RESTORE_PRIVILEGE, SE_DEBUG_PRIVILEGE], SE_PRIVILEGE_ENABLED, False);
end;

{ --------------------------------- Public  --------------------------------- }

function UnvxLoadProfileVolatileEx;
var
  Sid: ISid;
begin
  Result := EnsurePrivileges;

  if not Result.IsSuccess then
    Exit;

  // Determine the SID which is part of the key path
  Result := NtxQuerySidToken(hxToken, TokenUser, Sid);

  if not Result.IsSuccess then
    Exit;

  // Ask the User Profile Service to load the profile the normal way
  Result := UnvxLoadProfile(hxKey, hxToken);

  if not Result.IsSuccess then
    Exit;

  // Reload the profile, making it read-only
  Result := ReloadProfile(Sid.Data, REG_OPEN_READ_ONLY, Events);
end;

function UnvxLoadProfileVolatile;
begin
  Result := UnvxLoadProfileVolatileEx(hxKey, hxToken,
    Default(TProfileReloaderEvents));
end;

function UnvxReloadProfileEx;
var
  Flags: TRegLoadFlags;
begin
  Result := EnsurePrivileges;

  if not Result.IsSuccess then
    Exit;

  if MakeVolatile then
    Flags := REG_OPEN_READ_ONLY
  else
    Flags := 0;

  Result := ReloadProfile(Sid, Flags, Events);
end;

function UnvxReloadProfile;
begin
  Result := UnvxReloadProfileEx(Sid, MakeVolatile,
    Default(TProfileReloaderEvents));
end;

end.
