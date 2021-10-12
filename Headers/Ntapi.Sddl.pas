unit Ntapi.Sddl;

{
  This file defines functions for converting SIDs from and to SDDL
  representation.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, DelphiApi.Reflection;

// SDK::sddl.h
function ConvertSidToStringSidW(
  [in] Sid: PSid;
  [allocates('LocalFree')] out StringSid: PWideChar
): LongBool; stdcall; external advapi32;

// SDK::sddl.h
function ConvertStringSidToSidW(
  [in] StringSid: PWideChar;
  [allocates('LocalFree')] out Sid: PSid
): LongBool; stdcall; external advapi32;

// SDK::sddl.h
function ConvertSecurityDescriptorToStringSecurityDescriptorW(
  [in] SecurityDescriptor: PSecurityDescriptor;
  RequestedStringSDRevision: Cardinal;
  SecurityInformation: TSecurityInformation;
  [allocates('LocalFree')] out StringSecurityDescriptor: PWideChar;
  [out, opt] StringSecurityDescriptorLen: PCardinal
): LongBool; stdcall; external advapi32;

// SDK::sddl.h
function ConvertStringSecurityDescriptorToSecurityDescriptorW(
  [in] StringSecurityDescriptor: PWideChar;
  StringSDRevision: Cardinal;
  [allocates('LocalFree')] out SecurityDescriptor: PSecurityDescriptor;
  [out, opt] SecurityDescriptorSize: PCardinal
): LongBool; stdcall; external advapi32;

implementation

end.
