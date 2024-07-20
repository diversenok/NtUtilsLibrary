unit NtUtils.Registry.VReg;

{
  This module provides support for loading differencing registry hives and
  applying silo registry virtualization.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntregapi, Ntapi.ntseapi, Ntapi.Versions,
  DelphiApi.Reflection, NtUtils;

type
  TVRxNamespaceNode = record
    ContainerPath: String;
    HostPathLength: String;
    [Hex] Flags: Cardinal;
    [opt] AccessMask: TRegKeyAccessMask;

    class function Create(
      const ContainerPath: String;
      const HostPathLength: String;
      [Hex] Flags: Cardinal = 0;
      [opt] AccessMask: TAccessMask = 0
    ): TVRxNamespaceNode; static;
  end;

{ Silo operations }

// Open the virtual registry device
[RequiresAdmin]
[MinOSVersion(OsWin10RS1)]
function NtxVRegOpen(
  out hxVRegDevice: IHandle
): TNtxStatus;

// Issue an IOCTL to the virtual registry device
[MinOSVersion(OsWin10RS1)]
function NtxVRegIoControl(
  const hxVRegDevice: IHandle;
  IoControlCode: Cardinal;
  [in, opt] InputBuffer: Pointer = nil;
  InputBufferLength: Cardinal = 0;
  [out, opt] OutputBuffer: Pointer = nil;
  OutputBufferLength: Cardinal = 0
): TNtxStatus;

// Initialize registry virtualization for an silo
[MinOSVersion(OsWin10RS1)]
function NtxVRegInitializeForJob(
  const hxVRegDevice: IHandle;
  [Access(JOB_OBJECT_QUERY or JOB_OBJECT_SET_ATTRIBUTES)] const hxSiloJob: IHandle
): TNtxStatus;

// Load a (differencing) hive for a lifetime of a silo
[MinOSVersion(OsWin10RS1)]
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function NtxVRegLoadDifferencingHive(
  const hxVRegDevice: IHandle;
  [Access(JOB_OBJECT_QUERY or JOB_OBJECT_SET_ATTRIBUTES)] const hxSiloJob: IHandle;
  const HivePath: String;
  const KeyPath: String;
  const NextLayerKeyPath: String;
  Flags: TVRLoadFlags;
  LoadFlags: TRegLoadFlags;
  NextLayerIsHost: Boolean;
  [opt] const hxFileAccessToken: IHandle = nil
): TNtxStatus;

// Apply registry redirection to a silo
[MinOSVersion(OsWin10RS1)]
function NtxVRegCreateNamespaceNode(
  const hxVRegDevice: IHandle;
  [Access(JOB_OBJECT_QUERY or JOB_OBJECT_SET_ATTRIBUTES)] const hxSiloJob: IHandle;
  const ContainerPath: String;
  const HostPath: String;
  Flags: Cardinal = 0;
  [opt] AccessMask: TRegKeyAccessMask = 0
): TNtxStatus;

// Apply multiple registry redirections to a silo
[MinOSVersion(OsWin10RS1)]
function NtxVRegCreateNamespaceNodes(
  const hxVRegDevice: IHandle;
  [Access(JOB_OBJECT_QUERY or JOB_OBJECT_SET_ATTRIBUTES)] const hxSiloJob: IHandle;
  const Nodes: TArray<TVRxNamespaceNode>
): TNtxStatus;

{ Host operations }

// Load a (differencing) hive
[MinOSVersion(OsWin10RS1)]
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function NtxVRegLoadDifferencingHiveForHost(
  const hxVRegDevice: IHandle;
  const TargetHivePath: String;
  const TargetKeyPath: String;
  const NextLayerKeyPath: String;
  Flags: TVRLoadFlags;
  LoadFlags: TRegLoadFlags;
  [opt] const hxFileAccessToken: IHandle = nil
): TNtxStatus;

// Unload a (differencing) hive
[MinOSVersion(OsWin10RS1)]
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function NtxVRegUnloadDifferencingHiveForHost(
  const hxVRegDevice: IHandle;
  const TargetKeyPath: String
): TNtxStatus;

implementation

uses
  Ntapi.ntioapi.fsctl, NtUtils.Files, NtUtils.Files.Open, NtUtils.Files.Control,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NtxVRegOpen;
begin
  Result := NtxOpenFile(hxVRegDevice,
    FileParameters.UseFileName(VR_DEVICE_NAME));
end;

function NtxVRegIoControl;
begin
  Result := NtxDeviceIoControlFile(hxVRegDevice, IoControlCode,
    InputBuffer, InputBufferLength, OutputBuffer, OutputBufferLength);

  // Attach additional information
  case IoControlCode of
    IOCTL_VR_LOAD_DIFFERENCING_HIVE, IOCTL_VR_LOAD_DIFFERENCING_HIVE_FOR_HOST:
      Result.LastCall.ExpectedPrivilege := SE_RESTORE_PRIVILEGE;
  end;

  Result.LastCall.UsesInfoClass(TVRIoctlFunction(FUNCTION_FROM_IOCTL(
    IoControlCode)), icPerform);
end;

function NtxVRegInitializeForJob;
var
  Input: THandle;
begin
  Input := HandleOrDefault(hxSiloJob);

  Result := NtxVRegIoControl(hxVRegDevice, IOCTL_VR_INITIALIZE_JOB_FOR_VREG,
    @Input, SizeOf(Input));
end;

function NtxVRegLoadDifferencingHive;
var
  Buffer: IMemory<PVRLoadDifferencingHive>;
  BodySize: NativeUInt;
  VariablePart: Pointer;
begin
  // Select the appropriate structure size
  if RtlOsVersionAtLeast(OsWin1021H2) then
    BodySize := SizeOf(TVRLoadDifferencingHive)
  else
    BodySize := UIntPtr(@PVRLoadDifferencingHive(nil).NextLayerKeyPathLength) +
      SizeOf(Word);

  IMemory(Buffer) := Auto.AllocateDynamic(BodySize +
    StringSizeNoZero(KeyPath) + StringSizeNoZero(HivePath) +
    StringSizeNoZero(NextLayerKeyPath)
  );

  // Serialize static data
  Buffer.Data.Job := HandleOrDefault(hxSiloJob);
  Buffer.Data.NextLayerIsHost := NextLayerIsHost;
  Buffer.Data.Flags := Flags;
  Buffer.Data.LoadFlags := LoadFlags;
  Buffer.Data.KeyPathLength := StringSizeNoZero(KeyPath);
  Buffer.Data.HivePathLength := StringSizeNoZero(HivePath);
  Buffer.Data.NextLayerKeyPathLength := StringSizeNoZero(NextLayerKeyPath);

  if RtlOsVersionAtLeast(OsWin1021H2) then
    Buffer.Data.FileAccessToken := HandleOrDefault(hxFileAccessToken);

  // Serialize strings
  VariablePart := Buffer.Offset(BodySize);
  Move(PWideChar(KeyPath)^, VariablePart^, StringSizeNoZero(KeyPath));
  Inc(PByte(VariablePart), StringSizeNoZero(KeyPath));
  Move(PWideChar(HivePath)^, VariablePart^, StringSizeNoZero(HivePath));
  Inc(PByte(VariablePart), StringSizeNoZero(HivePath));
  Move(PWideChar(NextLayerKeyPath)^, VariablePart^,
    StringSizeNoZero(NextLayerKeyPath));

  // Issue the request
  Result := NtxVRegIoControl(hxVRegDevice, IOCTL_VR_LOAD_DIFFERENCING_HIVE,
    Buffer.Data, Buffer.Size);
end;

function NtxVRegCreateNamespaceNode;
var
  Buffer: IMemory<PVRCreateNamespaceNode>;
  BodySize: NativeUInt;
  VariablePart: Pointer;
begin
  // Select the appropriate structure size
  if RtlOsVersionAtLeast(OsWin1021H2) then
    BodySize := SizeOf(TVRCreateNamespaceNode)
  else
    BodySize := UIntPtr(@PVRCreateNamespaceNode(nil).AccessMask);

  IMemory(Buffer) := Auto.AllocateDynamic(BodySize +
    StringSizeNoZero(ContainerPath) + StringSizeNoZero(HostPath));

  // Serialize static data
  Buffer.Data.Job := HandleOrDefault(hxSiloJob);
  Buffer.Data.ContainerPathLength := StringSizeNoZero(ContainerPath);
  Buffer.Data.HostPathLength := StringSizeNoZero(HostPath);
  Buffer.Data.Flags := Flags;

  if RtlOsVersionAtLeast(OsWin1021H2) then
    Buffer.Data.AccessMask := AccessMask;

  // Serialize strings
  VariablePart := Buffer.Offset(BodySize);
  Move(PWideChar(ContainerPath)^, VariablePart^, StringSizeNoZero(ContainerPath));
  Inc(PByte(VariablePart), StringSizeNoZero(ContainerPath));
  Move(PWideChar(HostPath)^, VariablePart^, StringSizeNoZero(HostPath));

  // Issue the request
  Result := NtxVRegIoControl(hxVRegDevice, IOCTL_VR_CREATE_NAMESPACE_NODE,
    Buffer.Data, Buffer.Size);
end;

function NtxVRegCreateNamespaceNodes;
var
  Buffer: IMemory<PVRCreateMultipleNamespaceNodes>;
  NodeData: PNamespaceNodeData;
  VariablePart: Pointer;
  RequiredSize: NativeUInt;
  i: Integer;
begin
  // Compute the required buffer size
  RequiredSize := SizeOf(TVRCreateMultipleNamespaceNodes) +
    Length(Nodes) * SizeOf(TNamespaceNodeData);

  for i := 0 to High(Nodes) do
  begin
    Inc(RequiredSize, StringSizeNoZero(Nodes[i].ContainerPath));
    Inc(RequiredSize, StringSizeNoZero(Nodes[i].HostPathLength));
  end;

  IMemory(Buffer) := Auto.AllocateDynamic(RequiredSize);

  // Write the global header
  Buffer.Data.Job := HandleOrDefault(hxSiloJob);
  Buffer.Data.NumNewKeys := Length(Nodes);
  NodeData := Pointer(@Buffer.Data.Keys);
  i := 0;

  repeat
    // Write each node header
    NodeData.AccessMask := Nodes[i].AccessMask;
    NodeData.Flags := Nodes[i].Flags;
    NodeData.ContainerPathLength := StringSizeNoZero(Nodes[i].ContainerPath);
    NodeData.HostPathLength := StringSizeNoZero(Nodes[i].HostPathLength);

    // Serialize strings
    VariablePart := PByte(NodeData) + SizeOf(TNamespaceNodeData);
    Move(PWideChar(Nodes[i].ContainerPath)^, VariablePart^,
      StringSizeNoZero(Nodes[i].ContainerPath));
    Inc(PByte(VariablePart), StringSizeNoZero(Nodes[i].ContainerPath));
    Move(PWideChar(Nodes[i].HostPathLength)^, VariablePart^,
      StringSizeNoZero(Nodes[i].HostPathLength));
    Inc(PByte(VariablePart), StringSizeNoZero(Nodes[i].HostPathLength));

    // Advance to the next entry
    NodeData := VariablePart;
    Inc(i);
  until i > High(Nodes);

  // Issue the request
  Result := NtxVRegIoControl(hxVRegDevice,
    IOCTL_VR_CREATE_MULTIPLE_NAMESPACE_NODES, Buffer.Data, Buffer.Size);
end;

function NtxVRegLoadDifferencingHiveForHost;
var
  Buffer: IMemory<PVRLoadDifferencingHiveForHost>;
  BodySize: NativeUInt;
  VariablePart: PByte;
begin
  // Select the appropriate structure size
  if RtlOsVersionAtLeast(OsWin1020H1) then
    BodySize := SizeOf(TVRLoadDifferencingHiveForHost)
  else
    BodySize := UIntPtr(@PVRLoadDifferencingHiveForHost(nil)
      .NextLayerKeyPathLength) + SizeOf(Word);

  IMemory(Buffer) := Auto.AllocateDynamic(
    BodySize +
    StringSizeNoZero(TargetKeyPath) +
    StringSizeNoZero(TargetHivePath) +
    StringSizeNoZero(NextLayerKeyPath)
  );

  // Serialize static data
  Buffer.Data.LoadFlags := LoadFlags;
  Buffer.Data.Flags := Flags;
  Buffer.Data.TargetKeyPathLength := StringSizeNoZero(TargetKeyPath);
  Buffer.Data.TargetHivePathLength := StringSizeNoZero(TargetHivePath);
  Buffer.Data.NextLayerKeyPathLength := StringSizeNoZero(NextLayerKeyPath);

  if RtlOsVersionAtLeast(OsWin1020H1) then
    Buffer.Data.FileAccessToken := HandleOrDefault(hxFileAccessToken);

  // Marshal strings
  VariablePart := Buffer.Offset(BodySize);
  Move(PWideChar(TargetKeyPath)^, VariablePart^, StringSizeNoZero(TargetKeyPath));
  Inc(VariablePart, StringSizeNoZero(TargetKeyPath));
  Move(PWideChar(TargetHivePath)^, VariablePart^, StringSizeNoZero(TargetHivePath));
  Inc(VariablePart, StringSizeNoZero(TargetHivePath));
  Move(PWideChar(NextLayerKeyPath)^, VariablePart^, StringSizeNoZero(NextLayerKeyPath));

  // Fixup the structure on RS1 where it misses one field
  if RtlOsVersion < OsWin10RS2 then
    Move(
      Buffer.Offset(UIntPtr(@PVRLoadDifferencingHiveForHost(nil).TargetKeyPathLength))^,
      Buffer.Offset(UIntPtr(@PVRLoadDifferencingHiveForHost(nil).Flags))^,
      Buffer.Size - UIntPtr(@PVRLoadDifferencingHiveForHost(nil).TargetKeyPathLength)
    );

  // Issue the request
  Result := NtxVRegIoControl(hxVRegDevice,
    IOCTL_VR_LOAD_DIFFERENCING_HIVE_FOR_HOST, Buffer.Data, Buffer.Size);
end;

function NtxVRegUnloadDifferencingHiveForHost;
var
  Buffer: IMemory<PVRUnloadDifferencingHiveForHost>;
begin
  IMemory(Buffer) := Auto.AllocateDynamic(
    SizeOf(TVRUnloadDifferencingHiveForHost) +
    StringSizeNoZero(TargetKeyPath)
  );

  // Prepare the buffer
  Buffer.Data.TargetKeyPathLength := StringSizeNoZero(TargetKeyPath);
  Move(PWideChar(TargetKeyPath)^, Buffer.Data.TargetKeyPath,
    StringSizeNoZero(TargetKeyPath));

  // Issue the request
  Result := NtxVRegIoControl(hxVRegDevice,
    IOCTL_VR_UNLOAD_DIFFERENCING_HIVE_FOR_HOST, Buffer.Data, Buffer.Size);
end;

{ TVRxNamespaceNode }

class function TVRxNamespaceNode.Create;
begin
  Result.ContainerPath := ContainerPath;
  Result.HostPathLength := HostPathLength;
  Result.Flags := Flags;
  Result.AccessMask := AccessMask;
end;

end.
