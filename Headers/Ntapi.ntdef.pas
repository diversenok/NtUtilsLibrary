unit Ntapi.ntdef;

{
  This file defines common Native API data types.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, DelphiApi.Reflection;

const
  ntdll = 'ntdll.dll';
  win32u = 'win32u.dll';

  // WDK::ntdef.h & PHNT::phnt_ntdef.h - object attributes
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

  // WDK::ntdef.h
  [SDKName('EVENT_TYPE')]
  [NamingStyle(nsCamelCase)]
  TEventType = (
    NotificationEvent = 0,
    SynchronizationEvent = 1
  );

  // WDK::ntdef.h
  [SDKName('TIMER_TYPE')]
  [NamingStyle(nsCamelCase)]
  TTimerType = (
    NotificationTimer = 0,
    SynchronizationTimer = 1
  );

  // WDK::ntdef.h
  [SDKName('ANSI_STRING')]
  TNtAnsiString = record
    [Bytes] Length: Word;
    [Bytes] MaximumLength: Word;
    Buffer: PAnsiChar;
    function ToString: AnsiString;
    class function From(Source: AnsiString): TNtAnsiString; static;
  end;
  PNtAnsiString = ^TNtAnsiString;

  // WDK::ntdef.h
  PNtUnicodeString = ^TNtUnicodeString;
  [SDKName('UNICODE_STRING')]
  TNtUnicodeString = record
    [Bytes] Length: Word;
    [Bytes] MaximumLength: Word;
    Buffer: PWideChar;
    function ToString: String;
    function RefOrNil: PNtUnicodeString;

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

  // WDK::ntdef.h
  [SDKName('OBJECT_ATTRIBUTES')]
  TObjectAttributes = record
    [Bytes, Unlisted] Length: Cardinal;
    RootDirectory: THandle;
    [opt] ObjectName: PNtUnicodeString;
    Attributes: TObjectAttributesFlags;
    [opt] SecurityDescriptor: PSecurityDescriptor;
    [opt] SecurityQualityOfService: PSecurityQualityOfService;
  end;
  PObjectAttributes = ^TObjectAttributes;

  // WDK::wdm.h
  [SDKName('CLIENT_ID')]
  TClientId = record
    UniqueProcess: TProcessId;
    UniqueThread: TThreadId;
    procedure Create(PID: TProcessId; TID: TThreadId); inline;
    class operator Equal(const A, B: TClientId): Boolean;
    class operator NotEqual(const A, B: TClientId): Boolean;
  end;
  PClientId = ^TClientId;

const
  MAX_UNICODE_STRING_SIZE = SizeOf(TNtUnicodeString) + High(Word) + 1 +
    SizeOf(WideChar);

function NT_SEVERITY(Status: NTSTATUS): Byte;
function NT_FACILITY(Status: NTSTATUS): Word;

function NT_SUCCESS(Status: NTSTATUS): Boolean; inline;
function NT_INFORMATION(Status: NTSTATUS): Boolean;
function NT_WARNING(Status: NTSTATUS): Boolean;
function NT_ERROR(Status: NTSTATUS): Boolean;

function NTSTATUS_FROM_WIN32(Win32Error: TWin32Error): NTSTATUS;
function NT_NTWIN32(Status: NTSTATUS): Boolean;
function WIN32_FROM_NTSTATUS(Status: NTSTATUS): TWin32Error;

function AlighUp(
  Length: Cardinal;
  Size: Cardinal = SizeOf(NativeUInt)
): Cardinal;

function AlighUpPtr(pData: Pointer): Pointer;

procedure InitializeObjectAttributes(
  [out] out ObjAttr: TObjectAttributes;
  [in, opt] ObjectName: PNtUnicodeString = nil;
  [in] Attributes: TObjectAttributesFlags = 0;
  [in, opt] RootDirectory: THandle = 0;
  [in, opt] QoS: PSecurityQualityOfService = nil
);

procedure InitializaQoS(
  [out] out QoS: TSecurityQualityOfService;
  [in] ImpersonationLevel: TSecurityImpersonationLevel = SecurityImpersonation;
  [in] EffectiveOnly: Boolean = False
);

implementation

uses
  Ntapi.ntstatus;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

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

function AlighUp;
begin
  {$Q-}{$R-}
  Result := (Length + Size - 1) and not (Size - 1);
  {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}
end;

function AlighUpPtr;
const
  ALIGN_M = SizeOf(UIntPtr) - 1;
begin
  {$Q-}{$R-}
  Result := Pointer((UIntPtr(pData) + ALIGN_M) and not ALIGN_M);
  {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}
end;

procedure InitializeObjectAttributes;
begin
  ObjAttr := Default(TObjectAttributes);
  ObjAttr.Length := SizeOf(ObjAttr);
  ObjAttr.ObjectName := ObjectName;
  ObjAttr.Attributes := Attributes;
  ObjAttr.RootDirectory := RootDirectory;
  ObjAttr.SecurityQualityOfService := QoS;
end;

procedure InitializaQoS;
begin
  QoS := Default(TSecurityQualityOfService);
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
  if Source <> '' then
  begin
    Result.Buffer := PWideChar(Source);
    Result.Length := System.Length(Source) * SizeOf(WideChar);
    Result.MaximumLength := Result.Length + SizeOf(WideChar);
  end
  else
  begin
    Result.Length := 0;
    Result.MaximumLength := 0;
    Result.Buffer := nil;
  end;
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

function TNtUnicodeString.RefOrNil;
begin
  if Assigned(@Self) and (Length <> 0) then
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

class operator TClientId.Equal(const A, B: TClientId): Boolean;
begin
  Result := ((A.UniqueProcess = B.UniqueProcess) or (A.UniqueProcess = 0) or
    (B.UniqueProcess = 0)) and ((A.UniqueThread = B.UniqueThread) or
    (A.UniqueThread = 0) or (B.UniqueThread = 0));
end;

class operator TClientId.NotEqual(const A, B: TClientId): Boolean;
begin
  Result := not (A = B);
end;

end.
