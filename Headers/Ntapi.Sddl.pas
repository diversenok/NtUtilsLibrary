unit Ntapi.Sddl;

{
  This file defines functions for converting SIDs from and to SDDL
  representation.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, DelphiApi.Reflection;

// Use LocalFree for deallocation

// SDK::sddl.h
function ConvertSidToStringSidW(
  [in] Sid: PSid;
  [allocates] out StringSid: PWideChar
): LongBool; stdcall; external advapi32;

// SDK::sddl.h
function ConvertStringSidToSidW(
  [in] StringSid: PWideChar;
  [allocates] out Sid: PSid
): LongBool; stdcall; external advapi32;

// SDK::sddl.h
function ConvertSecurityDescriptorToStringSecurityDescriptorW(
  [in] SecurityDescriptor: PSecurityDescriptor;
  RequestedStringSDRevision: Cardinal;
  SecurityInformation: TSecurityInformation;
  [allocates] out StringSecurityDescriptor: PWideChar;
  [out, opt] StringSecurityDescriptorLen: PCardinal
): LongBool; stdcall; external advapi32;

// SDK::sddl.h
function ConvertStringSecurityDescriptorToSecurityDescriptorW(
  [in] StringSecurityDescriptor: PWideChar;
  StringSDRevision: Cardinal;
  [allocates] out SecurityDescriptor: PSecurityDescriptor;
  [out, opt] SecurityDescriptorSize: PCardinal
): LongBool; stdcall; external advapi32;

implementation

end.
