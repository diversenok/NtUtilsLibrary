unit Ntapi.WinBase;

{
  This file includes some miscellaneous definitions.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.NtSecApi, Ntapi.ntseapi, DelphiApi.Reflection;

type
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

// SDK::WinUser.h
// TODO: reverse and move to rtl
function LoadStringW(
  hInstance: HINST;
  ID: Cardinal;
  out Buffer: PWideChar;
  BufferMax: Integer = 0
): Integer; stdcall; external kernelbase;

implementation

end.
