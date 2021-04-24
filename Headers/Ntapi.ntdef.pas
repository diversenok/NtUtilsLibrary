unit Ntapi.ntdef;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, DelphiApi.Reflection;

const
  ntdll = 'ntdll.dll';

  OBJ_PROTECT_CLOSE = $00000001;
  OBJ_INHERIT = $00000002;
  OBJ_AUDIT_OBJECT_CLOSE = $00000004;
  OBJ_PERMANENT = $00000010;
  OBJ_EXCLUSIVE = $00000020;
  OBJ_CASE_INSENSITIVE = $00000040;
  OBJ_OPENIF = $00000080;
  OBJ_OPENLINK  = $00000100;
  OBJ_KERNEL_HANDLE = $00000200;
  OBJ_FORCE_ACCESS_CHECK = $00000400;
  OBJ_IGNORE_IMPERSONATED_DEVICEMAP = $00000800;
  OBJ_DONT_REPARSE = $00001000;
  OBJ_KERNEL_EXCLUSIVE = $00010000;

type
  NTSTATUS = type Cardinal;
  TPriority = type Integer;

  [NamingStyle(nsCamelCase)]
  TEventType = (
    NotificationEvent = 0,
    SynchronizationEvent = 1
  );

  [NamingStyle(nsCamelCase)]
  TTimerType = (
    NotificationTimer = 0,
    SynchronizationTimer = 1
  );

  // ntdef.1508
  TNtAnsiString = record
    [Bytes] Length: Word;
    [Bytes] MaximumLength: Word;
    Buffer: PAnsiChar;
    function ToString: AnsiString;
    class function From(Source: AnsiString): TNtAnsiString; static;
  end;
  PNtAnsiString = ^TNtAnsiString;

  // ntdef.1550
  PNtUnicodeString = ^TNtUnicodeString;
  TNtUnicodeString = record
    [Bytes] Length: Word;
    [Bytes] MaximumLength: Word;
    Buffer: PWideChar;
    function ToString: String;
    function RefOrNull: PNtUnicodeString;

    class function RequiredSize(const Source: String): NativeUInt; static;
    class function From(const Source: String): TNtUnicodeString; static;

    class procedure Marshal(
      Source: String;
      Target: PNtUnicodeString;
      VariablePart: PWideChar = nil
    ); static;

    // Marshal a string to a buffer and adjust pointers for remote access
    class procedure MarshalEx(
      Source: String;
      LocalAddress: PNtUnicodeString;
      RemoteAddress: Pointer = nil;
      VariableOffset: Cardinal = 0
    ); static;
  end;

  [FlagName(OBJ_PROTECT_CLOSE, 'Protected')]
  [FlagName(OBJ_INHERIT, 'Inherit')]
  [FlagName(OBJ_AUDIT_OBJECT_CLOSE, 'Audit Object Close')]
  [FlagName(OBJ_PERMANENT, 'Permanent')]
  [FlagName(OBJ_EXCLUSIVE, 'Exclusive')]
  [FlagName(OBJ_CASE_INSENSITIVE, 'Case Insensitive')]
  [FlagName(OBJ_OPENIF, 'Open-if')]
  [FlagName(OBJ_OPENLINK, 'Open link')]
  [FlagName(OBJ_KERNEL_HANDLE, 'Kernel Handle')]
  [FlagName(OBJ_FORCE_ACCESS_CHECK, 'Force Access Check')]
  [FlagName(OBJ_IGNORE_IMPERSONATED_DEVICEMAP, 'Ignore Impersonated Device Map')]
  [FlagName(OBJ_DONT_REPARSE, 'Don''t Reparse')]
  [FlagName(OBJ_KERNEL_EXCLUSIVE, 'Kernel Exclusive')]
  TObjectAttributesFlags = type Cardinal;

  // ntdef.1805
  TObjectAttributes = record
    [Bytes, Unlisted] Length: Cardinal;
    RootDirectory: THandle;
    ObjectName: PNtUnicodeString;
    Attributes: TObjectAttributesFlags;
    SecurityDescriptor: PSecurityDescriptor;
    SecurityQualityOfService: PSecurityQualityOfService;
  end;
  PObjectAttributes = ^TObjectAttributes;

  // wdm.7745
  TClientId = record
    UniqueProcess: TProcessId;
    UniqueThread: TThreadId;
    procedure Create(PID: TProcessId; TID: TThreadId); inline;
  end;
  PClientId = ^TClientId;

const
  MAX_UNICODE_STRING_SIZE = SizeOf(TNtUnicodeString) + High(Word) + 1 +
    SizeOf(WideChar);

function NT_SEVERITY(Status: NTSTATUS): Byte; inline;
function NT_FACILITY(Status: NTSTATUS): Word; inline;

function NT_SUCCESS(Status: NTSTATUS): Boolean; inline;
function NT_INFORMATION(Status: NTSTATUS): Boolean; inline;
function NT_WARNING(Status: NTSTATUS): Boolean; inline;
function NT_ERROR(Status: NTSTATUS): Boolean; inline;

function NTSTATUS_FROM_WIN32(Win32Error: TWin32Error): NTSTATUS; inline;
function NT_NTWIN32(Status: NTSTATUS): Boolean; inline;
function WIN32_FROM_NTSTATUS(Status: NTSTATUS): TWin32Error; inline;

function AlighUp(Length: Cardinal; Size: Cardinal): Cardinal; overload;
function AlighUp(Length: Cardinal): Cardinal; overload;
function AlighUp(pData: Pointer): Pointer; overload;

procedure InitializeObjectAttributes(
  out ObjAttr: TObjectAttributes;
  [in, opt] ObjectName: PNtUnicodeString = nil;
  Attributes: TObjectAttributesFlags = 0;
  RootDirectory: THandle = 0;
  [in, opt] QoS: PSecurityQualityOfService = nil
); inline;

procedure InitializaQoS(
  var QoS: TSecurityQualityOfService;
  ImpersonationLevel: TSecurityImpersonationLevel = SecurityImpersonation;
  EffectiveOnly: Boolean = False
); inline;

implementation

uses
  Ntapi.ntstatus;

function NT_SEVERITY;
begin
  Result := Status shr NT_SEVERITY_SHIFT;
end;

function NT_FACILITY;
begin
  Result := (Status shr NT_FACILITY_SHIFT) and NT_FACILITY_MASK;
end;

// 00000000..7FFFFFFF
function NT_SUCCESS;
begin
  Result := Integer(Status) >= 0;
end;

// 40000000..7FFFFFFF
function NT_INFORMATION;
begin
  Result := (NT_SEVERITY(Status) = SEVERITY_INFORMATIONAL);
end;

// 80000000..BFFFFFFF
function NT_WARNING;
begin
  Result := (NT_SEVERITY(Status) = SEVERITY_WARNING);
end;

// C0000000..FFFFFFFF
function NT_ERROR;
begin
  Result := (NT_SEVERITY(Status) = SEVERITY_ERROR);
end;

function NTSTATUS_FROM_WIN32;
begin
  // Note: the result is a fake NTSTATUS which is only suitable for storing
  // the error code without collisions with well-known NTSTATUS values.
  // Before formatting error messages convert it back to Win32.
  // Template: C007xxxx

  Result := Cardinal(SEVERITY_ERROR shl NT_SEVERITY_SHIFT) or
    (FACILITY_NTWIN32 shl NT_FACILITY_SHIFT) or (Win32Error and $FFFF);
end;

function NT_NTWIN32;
begin
  Result := (NT_FACILITY(Status) = FACILITY_NTWIN32);
end;

function WIN32_FROM_NTSTATUS;
begin
  Result := Status and $FFFF;
end;

function AlighUp(Length: Cardinal; Size: Cardinal): Cardinal;
begin
  Result := {$Q-}(Length + Size - 1) and not (Size - 1){$Q+};
end;

function AlighUp(Length: Cardinal): Cardinal; overload;
const
  ALIGN_M = SizeOf(NativeUInt) - 1;
begin
  Result := {$Q-}(Length + ALIGN_M) and not ALIGN_M{$Q+};
end;

function AlighUp(pData: Pointer): Pointer; overload;
const
  ALIGN_M = SizeOf(NativeUInt) - 1;
begin
  Result := {$Q-}Pointer((IntPtr(pData) + ALIGN_M) and not ALIGN_M){$Q+};
end;

procedure InitializeObjectAttributes;
begin
  FillChar(ObjAttr, SizeOf(ObjAttr), 0);
  ObjAttr.Length := SizeOf(ObjAttr);
  ObjAttr.ObjectName := ObjectName;
  ObjAttr.Attributes := Attributes;
  ObjAttr.RootDirectory := RootDirectory;
  ObjAttr.SecurityQualityOfService := QoS;
end;

procedure InitializaQoS;
begin
  FillChar(QoS, SizeOf(QoS), 0);
  QoS.Length := SizeOf(QoS);
  QoS.ImpersonationLevel := ImpersonationLevel;
  QoS.EffectiveOnly := EffectiveOnly;
end;

{ TNtAnsiString }

class function TNtAnsiString.From;
begin
  Result.Buffer := PAnsiChar(Source);
  Result.Length := System.Length(Source) * SizeOf(AnsiChar);
  Result.MaximumLength := Result.Length + SizeOf(AnsiChar);
end;

function TNtAnsiString.ToString;
begin
  SetString(Result, Buffer, Length div SizeOf(AnsiChar));
end;

{ TNtUnicodeString }

class function TNtUnicodeString.From;
begin
  Result.Buffer := PWideChar(Source);
  Result.Length := System.Length(Source) * SizeOf(WideChar);
  Result.MaximumLength := Result.Length + SizeOf(WideChar);
end;

class procedure TNtUnicodeString.Marshal;
begin
  Target.Length := System.Length(Source) * SizeOf(WideChar);
  Target.MaximumLength := Target.Length + SizeOf(WideChar);

  if not Assigned(VariablePart) then
    VariablePart := Pointer(UIntPtr(Target) + SizeOf(TNtUnicodeString));

  Target.Buffer := VariablePart;
  Move(PWideChar(Source)^, VariablePart^, Target.MaximumLength);
end;

class procedure TNtUnicodeString.MarshalEx;
begin
  if VariableOffset = 0 then
    VariableOffset := SizeOf(TNtUnicodeString);

  LocalAddress.Length := System.Length(Source) * SizeOf(WideChar);
  LocalAddress.MaximumLength := LocalAddress.Length + SizeOf(WideChar);
  LocalAddress.Buffer := Pointer(UIntPtr(RemoteAddress) + VariableOffset);

  Move(PWideChar(Source)^, Pointer(UIntPtr(LocalAddress) + VariableOffset)^,
    LocalAddress.MaximumLength);
end;

function TNtUnicodeString.RefOrNull;
begin
  if Length <> 0 then
    Result := @Self
  else
    Result := nil;
end;

class function TNtUnicodeString.RequiredSize;
begin
  Result := SizeOf(TNtUnicodeString) +
    Succ(System.Length(Source)) * SizeOf(WideChar);
end;

function TNtUnicodeString.ToString;
begin
  SetString(Result, Buffer, Length div SizeOf(WideChar));
end;

{ TClientId }

procedure TClientId.Create;
begin
  UniqueProcess := PID;
  UniqueThread := TID;
end;

end.
