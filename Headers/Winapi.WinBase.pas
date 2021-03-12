unit Winapi.WinBase;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Winapi.NtSecApi, Ntapi.ntseapi, DelphiApi.Reflection;

type
  [NamingStyle(nsSnakeCase, 'LOGON32_PROVIDER')]
  TLogonProvider = (
    LOGON32_PROVIDER_DEFAULT = 0,
    LOGON32_PROVIDER_WINNT35 = 1,
    LOGON32_PROVIDER_WINNT40 = 2,
    LOGON32_PROVIDER_WINNT50 = 3,
    LOGON32_PROVIDER_VIRTUAL = 4
  );

  // minwinbase.46
  TSecurityAttributes = record
    [Bytes, Unlisted] Length: Cardinal;
    SecurityDescriptor: PSecurityDescriptor;
    InheritHandle: LongBool;
  end;
  PSecurityAttributes = ^TSecurityAttributes;

// 1180
function LocalFree(
  hMem: Pointer
): Pointer; stdcall; external kernel32;

// debugapi.62
procedure OutputDebugStringW(
  OutputString: PWideChar
); stdcall; external kernel32;

// 7202
function LogonUserW(
  Username: PWideChar;
  Domain: PWideChar;
  Password: PWideChar;
  LogonType: TSecurityLogonType;
  LogonProvider: TLogonProvider;
  out hToken: THandle
): LongBool; stdcall; external advapi32;

// winbasep ?
function LogonUserExExW(
  Username: PWideChar;
  Domain: PWideChar;
  Password: PWideChar;
  dwLogonType: TSecurityLogonType;
  LogonProvider: TLogonProvider;
  pTokenGroups: PTokenGroups;
  out hToken: THandle;
  ppLogonSid: PPointer;
  pProfileBuffer: PPointer;
  pProfileLength: PCardinal;
  QuotaLimits: PQuotaLimits
): LongBool; stdcall; external advapi32;

// WinUser.10833, reverse and move to rtl
function LoadStringW(
  hInstance: HINST;
  ID: Cardinal;
  out Buffer: PWideChar;
  BufferMax: Integer = 0
): Integer; stdcall; external kernelbase;

implementation

end.
