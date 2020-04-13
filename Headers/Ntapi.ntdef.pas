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
  KPRIORITY = Integer;

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
  ANSI_STRING = record
    [Bytes] Length: Word;
    [Bytes] MaximumLength: Word;
    Buffer: PAnsiChar;
    procedure FromString(Value: AnsiString);
  end;
  PANSI_STRING = ^ANSI_STRING;

  // ntdef.1550
  UNICODE_STRING = record
    [Bytes] Length: Word;
    [Bytes] MaximumLength: Word;
    Buffer: PWideChar;
    function ToString: String;
    procedure FromString(Value: string);
  end;
  PUNICODE_STRING = ^UNICODE_STRING;

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
    ObjectName: PUNICODE_STRING;
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
  MAX_UNICODE_STRING_SIZE = SizeOf(UNICODE_STRING) + High(Word) + 1 +
    SizeOf(WideChar);

function NT_SEVERITY(Status: NTSTATUS): Byte; inline;
function NT_FACILITY(Status: NTSTATUS): Word; inline;

function NT_SUCCESS(Status: NTSTATUS): Boolean; inline;
function NT_INFORMATION(Status: NTSTATUS): Boolean; inline;
function NT_WARNING(Status: NTSTATUS): Boolean; inline;
function NT_ERROR(Status: NTSTATUS): Boolean; inline;

function NTSTATUS_FROM_WIN32(Win32Error: Cardinal): NTSTATUS; inline;
function NT_NTWIN32(Status: NTSTATUS): Boolean; inline;
function WIN32_FROM_NTSTATUS(Status: NTSTATUS): TWin32Error; inline;

function Offset(P: Pointer; Size: NativeUInt): Pointer;

function AlighUp(Length: Cardinal; Size: Cardinal): Cardinal; overload;
function AlighUp(Length: Cardinal): Cardinal; overload;
function AlighUp(pData: Pointer): Pointer; overload;

procedure InitializeObjectAttributes(var ObjAttr: TObjectAttributes;
  ObjectName: PUNICODE_STRING = nil; Attributes: Cardinal = 0;
  RootDirectory: THandle = 0; QoS: PSecurityQualityOfService = nil); inline;

procedure InitializaQoS(var QoS: TSecurityQualityOfService;
  ImpersonationLevel: TSecurityImpersonationLevel = SecurityImpersonation;
  EffectiveOnly: Boolean = False); inline;

implementation

uses
  Ntapi.ntstatus;

function NT_SEVERITY(Status: NTSTATUS): Byte;
begin
  Result := Status shr NT_SEVERITY_SHIFT;
end;

function NT_FACILITY(Status: NTSTATUS): Word;
begin
  Result := (Status shr NT_FACILITY_SHIFT) and NT_FACILITY_MASK;
end;

// 00000000..7FFFFFFF
function NT_SUCCESS(Status: NTSTATUS): Boolean;
begin
  Result := Integer(Status) >= 0;
end;

// 40000000..7FFFFFFF
function NT_INFORMATION(Status: NTSTATUS): Boolean;
begin
  Result := (NT_SEVERITY(Status) = SEVERITY_INFORMATIONAL);
end;

// 80000000..BFFFFFFF
function NT_WARNING(Status: NTSTATUS): Boolean;
begin
  Result := (NT_SEVERITY(Status) = SEVERITY_WARNING);
end;

// C0000000..FFFFFFFF
function NT_ERROR(Status: NTSTATUS): Boolean;
begin
  Result := (NT_SEVERITY(Status) = SEVERITY_ERROR);
end;

function NTSTATUS_FROM_WIN32(Win32Error: Cardinal): NTSTATUS; inline;
begin
  // Note: the result is a fake NTSTATUS which is only suitable for storing
  // the error code without collisions with well-known NTSTATUS values.
  // Before formatting error messages convert it back to Win32.
  // Template: C007xxxx

  Result := Cardinal(SEVERITY_ERROR shl NT_SEVERITY_SHIFT) or
    (FACILITY_NTWIN32 shl NT_FACILITY_SHIFT) or (Win32Error and $FFFF);
end;

function NT_NTWIN32(Status: NTSTATUS): Boolean;
begin
  Result := (NT_FACILITY(Status) = FACILITY_NTWIN32);
end;

function WIN32_FROM_NTSTATUS(Status: NTSTATUS): TWin32Error;
begin
  Result := Status and $FFFF;
end;

function Offset(P: Pointer; Size: NativeUInt): Pointer;
begin
  Result := Pointer(NativeUInt(P) + Size);
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

procedure InitializeObjectAttributes(var ObjAttr: TObjectAttributes;
  ObjectName: PUNICODE_STRING; Attributes: Cardinal; RootDirectory: THandle;
  QoS: PSecurityQualityOfService);
begin
  FillChar(ObjAttr, SizeOf(ObjAttr), 0);
  ObjAttr.Length := SizeOf(ObjAttr);
  ObjAttr.ObjectName := ObjectName;
  ObjAttr.Attributes := Attributes;
  ObjAttr.RootDirectory := RootDirectory;
  ObjAttr.SecurityQualityOfService := QoS;
end;

procedure InitializaQoS(var QoS: TSecurityQualityOfService;
  ImpersonationLevel: TSecurityImpersonationLevel; EffectiveOnly: Boolean);
begin
  FillChar(QoS, SizeOf(QoS), 0);
  QoS.Length := SizeOf(QoS);
  QoS.ImpersonationLevel := ImpersonationLevel;
  QoS.EffectiveOnly := EffectiveOnly;
end;

{ ANSI_STRING }

procedure ANSI_STRING.FromString(Value: AnsiString);
begin
  Self.Buffer := PAnsiChar(Value);
  Self.Length := System.Length(Value) * SizeOf(AnsiChar);
  Self.MaximumLength := Self.Length + SizeOf(AnsiChar);
end;

{ UNICODE_STRING }

procedure UNICODE_STRING.FromString(Value: String);
begin
  Self.Buffer := PWideChar(Value);
  Self.Length := System.Length(Value) * SizeOf(WideChar);
  Self.MaximumLength := Self.Length + SizeOf(WideChar);
end;

function UNICODE_STRING.ToString: String;
begin
  SetString(Result, Buffer, Length div SizeOf(WideChar));
end;

{ TClientId }

procedure TClientId.Create(PID: TProcessId; TID: TThreadId);
begin
  UniqueProcess := PID;
  UniqueThread := TID;
end;

end.
