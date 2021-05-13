unit Winapi.Sddl;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, DelphiApi.Reflection;

// Use LocalFree for deallocation

function ConvertSidToStringSidW(
  [in] Sid: PSid;
  [allocates] out StringSid: PWideChar
): LongBool; stdcall; external advapi32;

function ConvertStringSidToSidW(
  [in] StringSid: PWideChar;
  [allocates] out Sid: PSid
): LongBool; stdcall; external advapi32;

function ConvertSecurityDescriptorToStringSecurityDescriptorW(
  [in] SecurityDescriptor: PSecurityDescriptor;
  RequestedStringSDRevision: Cardinal;
  SecurityInformation: TSecurityInformation;
  [allocates] out StringSecurityDescriptor: PWideChar;
  [out, opt] StringSecurityDescriptorLen: PCardinal
): LongBool; stdcall; external advapi32;

function ConvertStringSecurityDescriptorToSecurityDescriptorW(
  [in] StringSecurityDescriptor: PWideChar;
  StringSDRevision: Cardinal;
  [allocates] out SecurityDescriptor: PSecurityDescriptor;
  [out, opt] SecurityDescriptorSize: PCardinal
): LongBool; stdcall; external advapi32;

implementation

end.
