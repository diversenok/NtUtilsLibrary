unit Ntapi.WinBase;

{
  This file includes some miscellaneous definitions.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.NtSecApi, Ntapi.ntseapi, DelphiApi.Reflection;

const
  // SDK::WinBase.h, flags for GetFinalPathNameByHandle
  VOLUME_NAME_DOS = $0000;
  VOLUME_NAME_GUID = $0001;
  VOLUME_NAME_NT = $00002;
  VOLUME_NAME_NONE = $0004;
  VOLUME_NAME_MASK = VOLUME_NAME_GUID or VOLUME_NAME_NT or VOLUME_NAME_NONE;

  FILE_NAME_NORMALIZED = $0000;
  FILE_NAME_OPENED = $0008;
  FILE_NAME_MASK = FILE_NAME_OPENED;

type
  [SubEnum($7, VOLUME_NAME_DOS, 'DOS Volume Name')]
  [FlagName(VOLUME_NAME_GUID, 'GUID Volume Name')]
  [FlagName(VOLUME_NAME_NT, 'NT Volume Name')]
  [FlagName(VOLUME_NAME_NONE, 'No Volume Name')]
  [SubEnum($8, FILE_NAME_NORMALIZED, 'Normalized')]
  [SubEnum($8, FILE_NAME_OPENED, 'Opened')]
  TFileFinalNameFlags = type Cardinal;

  // SDK::WinBase.h
  [NamingStyle(nsSnakeCase, 'LOGON32_PROVIDER')]
  TLogonProvider = (
    LOGON32_PROVIDER_DEFAULT = 0,
    LOGON32_PROVIDER_WINNT35 = 1,
    LOGON32_PROVIDER_WINNT40 = 2,
    LOGON32_PROVIDER_WINNT50 = 3,
    LOGON32_PROVIDER_VIRTUAL = 4
  );

  PPSid = ^PSid;

  // SDK::minwinbase.h
  [SDKName('SECURITY_ATTRIBUTES')]
  TSecurityAttributes = record
    [Bytes, Unlisted] Length: Cardinal;
    SecurityDescriptor: PSecurityDescriptor;
    InheritHandle: LongBool;
  end;
  PSecurityAttributes = ^TSecurityAttributes;

// SDK::WinBase.h
function LocalFree(
  [in, opt] hMem: Pointer
): Pointer; stdcall; external kernel32;

// SDK::debugapi.h
procedure OutputDebugStringW(
  [in, opt] OutputString: PWideChar
); stdcall; external kernel32;

// SDK::WinBase.h
function LogonUserW(
  [in] Username: PWideChar;
  [in, opt] Domain: PWideChar;
  [in, opt] Password: PWideChar;
  LogonType: TSecurityLogonType;
  LogonProvider: TLogonProvider;
  out hToken: THandle
): LongBool; stdcall; external advapi32;

// MSDocs::desktop-src/SecAuthN/LogonUserExExW.md
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function LogonUserExExW(
  [in] Username: PWideChar;
  [in, opt] Domain: PWideChar;
  [in, opt] Password: PWideChar;
  LogonType: TSecurityLogonType;
  LogonProvider: TLogonProvider;
  [in, opt] TokenGroups: PTokenGroups;
  out hToken: THandle;
  [out, opt, allocates('LocalFree')] ppLogonSid: PPSid;
  [out, opt, allocates('LocalFree')] pProfileBuffer: PPointer;
  [out, opt] pProfileLength: PCardinal;
  [out, opt] QuotaLimits: PQuotaLimits
): LongBool; stdcall; external advapi32;

// SDK::fileapi.h
[Result: Counter(ctElements)]
function GetFinalPathNameByHandleW(
  hFile: THandle;
  [in] FilePath: PWideChar;
  [Counter(ctElements)] ccbFilePath: Cardinal;
  Flags: TFileFinalNameFlags
): Cardinal; stdcall; external kernel32;

implementation

end.
