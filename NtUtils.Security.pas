unit NtUtils.Security;

{
  Base functions for working with Security Descriptors.
}

interface

uses
  Ntapi.WinNt, NtUtils;

type
  TNtsecDescriptor = record
    Control: TSecurityDescriptorControl;
    Owner, Group: ISid;
    Dacl, Sacl: IAcl;
    class function Create(
      Control: TSecurityDescriptorControl = 0;
      Dacl: IAcl = nil;
      Sacl: IAcl = nil;
      Owner: ISid = nil;
      Group: ISid = nil
    ): TNtsecDescriptor; static;
  end;

  TSecurityQueryFunction = function (
    [Access(OBJECT_READ_SECURITY)] hObject: THandle;
    SecurityInformation: TSecurityInformation;
    out xMemory: ISecDesc
  ): TNtxStatus;

  TSecuritySetFunction = function (
    [Access(OBJECT_WRITE_SECURITY)] hObject: THandle;
    SecurityInformation: TSecurityInformation;
    [in] SD: PSecurityDescriptor
  ): TNtxStatus;

// Capture a copy of a security descriptor
function RtlxCaptureSD(
  [in] SourceSD: PSecurityDescriptor;
  out NtSd: TNtsecDescriptor
): TNtxStatus;

// Allocate a new self-relative security descriptor
function RtlxAllocateSD(
  const SD: TNtsecDescriptor;
  out xMemory: ISecDesc
): TNtxStatus;

// Query a security of an generic object
function RtlxQuerySecurity(
  [Access(OBJECT_READ_SECURITY)] hObject: THandle;
  Method: TSecurityQueryFunction;
  SecurityInformation: TSecurityInformation;
  out SD: TNtsecDescriptor
): TNtxStatus;

// Set a security on an generic object
function RtlxSetSecurity(
  [Access(OBJECT_WRITE_SECURITY)] hObject: THandle;
  Method: TSecuritySetFunction;
  SecurityInformation: TSecurityInformation;
  const SD: TNtsecDescriptor
): TNtxStatus;

{ Security Descriptor Definition Language }

// Parse a textual definition of a security descriptor
function AdvxSddlToSecurityDescriptor(
  const SDDL: String;
  out SecDesc: ISecDesc
): TNtxStatus;

// Construct a textual definition of a security descriptor
function AdvxSecurityDescriptorToSddl(
  [in] SecDesc: PSecurityDescriptor;
  SecurityInformation: TSecurityInformation;
  out SDDL: String
): TNtxStatus;

implementation

uses
  Ntapi.ntrtl, Ntapi.ntstatus, Ntapi.WinBase, Ntapi.Sddl, NtUtils.SysUtils,
  NtUtils.Security.Acl, NtUtils.Security.Sid, DelphiUtils.AutoObjects;

class function TNtsecDescriptor.Create;
begin
  Result.Control := Control;
  Result.Owner := Owner;
  Result.Group := Group;
  Result.Dacl := Dacl;
  Result.Sacl := Sacl;
end;

function RtlxCaptureSD;
var
  Revision: Cardinal;
  Sid: PSid;
  Acl: PAcl;
  Defaulted, Present: Boolean;
begin
  if not RtlValidSecurityDescriptor(SourceSD) then
  begin
    Result.Location := 'RtlValidSecurityDescriptor';
    Result.Status := STATUS_INVALID_SECURITY_DESCR;
    Exit;
  end;

  // Control flags
  Result.Location := 'RtlGetControlSecurityDescriptor';
  Result.Status := RtlGetControlSecurityDescriptor(SourceSD, NtSd.Control,
    Revision);

  if not Result.IsSuccess then
    Exit;

  // Owner
  Sid := nil;
  Result.Location := 'RtlGetOwnerSecurityDescriptor';
  Result.Status := RtlGetOwnerSecurityDescriptor(SourceSD, Sid, Defaulted);

  if not Result.IsSuccess then
    Exit;

  if Assigned(Sid) then
    Result := RtlxCopySid(Sid, NtSd.Owner);

  // Primary group
  Sid := nil;
  Result.Location := 'RtlGetGroupSecurityDescriptor';
  Result.Status := RtlGetGroupSecurityDescriptor(SourceSD, Sid, Defaulted);

  if not Result.IsSuccess then
    Exit;

  if Assigned(Sid) then
    Result := RtlxCopySid(Sid, NtSd.Group);

  // DACL
  Acl := nil;
  Result.Location := 'RtlGetDaclSecurityDescriptor';
  Result.Status := RtlGetDaclSecurityDescriptor(SourceSD, Present, Acl,
    Defaulted);

  if not Result.IsSuccess then
    Exit;

  if Assigned(Acl) then
    Result := RtlxCopyAcl(Acl, NtSd.Dacl);

  // SACL
  Acl := nil;
  Result.Location := 'RtlGetSaclSecurityDescriptor';
  Result.Status := RtlGetSaclSecurityDescriptor(SourceSD, Present, Acl,
    Defaulted);

  if Result.IsSuccess and Assigned(Acl) then
    Result := RtlxCopyAcl(Acl, NtSd.Sacl);
end;

function RtlxAllocateSD;
const
  SE_CONTROL_CUSTOM = High(TSecurityDescriptorControl)
    and not SE_OWNER_DEFAULTED and not SE_GROUP_DEFAULTED
    and not SE_DACL_PRESENT and not SE_DACL_DEFAULTED
    and not SE_SACL_PRESENT and not SE_SACL_DEFAULTED;
var
  SecDesc: TSecurityDescriptor;
  BufferSize: Cardinal;
begin
  Result.Location := 'RtlCreateSecurityDescriptor';
  Result.Status := RtlCreateSecurityDescriptor(@SecDesc,
    SECURITY_DESCRIPTOR_REVISION);

  if not Result.IsSuccess then
     Exit;

  // Owner
  Result.Location := 'RtlSetOwnerSecurityDescriptor';
  Result.Status := RtlSetOwnerSecurityDescriptor(@SecDesc, Auto.RefOrNil<PSid>(
    SD.Owner), BitTest(SD.Control and SE_OWNER_DEFAULTED));

  if not Result.IsSuccess then
     Exit;

  // Primary group
  Result.Location := 'RtlSetGroupSecurityDescriptor';
  Result.Status := RtlSetGroupSecurityDescriptor(@SecDesc, Auto.RefOrNil<PSid>(
    SD.Group), BitTest(SD.Control and SE_GROUP_DEFAULTED));

  if not Result.IsSuccess then
     Exit;

  // DACL
  Result.Location := 'RtlSetDaclSecurityDescriptor';
  Result.Status := RtlSetDaclSecurityDescriptor(@SecDesc,
    BitTest(SD.Control and SE_DACL_PRESENT), Auto.RefOrNil<PAcl>(SD.Dacl),
    BitTest(SD.Control and SE_DACL_DEFAULTED));

  if not Result.IsSuccess then
     Exit;

  // SACL
  Result.Location := 'RtlSetSaclSecurityDescriptor';
  Result.Status := RtlSetSaclSecurityDescriptor(@SecDesc,
    BitTest(SD.Control and SE_SACL_PRESENT), Auto.RefOrNil<PAcl>(SD.Sacl),
    BitTest(SD.Control and SE_SACL_DEFAULTED));

  if not Result.IsSuccess then
     Exit;

  // Control flags
  Result.Location := 'RtlSetControlSecurityDescriptor';
  Result.Status := RtlSetControlSecurityDescriptor(@SecDesc, SD.Control and
    SE_CONTROL_CUSTOM, SD.Control and SE_CONTROL_CUSTOM);

  if not Result.IsSuccess then
     Exit;

  BufferSize := RtlLengthSecurityDescriptor(@SecDesc);
  IMemory(xMemory) := Auto.AllocateDynamic(BufferSize);

  Result.Location := 'RtlMakeSelfRelativeSD';
  Result.Status := RtlMakeSelfRelativeSD(@SecDesc, xMemory.Data, BufferSize);
end;

function RtlxQuerySecurity;
var
  xMemory: ISecDesc;
begin
  Result := Method(hObject, SecurityInformation, xMemory);

  if Result.IsSuccess then
    Result := RtlxCaptureSD(xMemory.Data, SD);
end;

function RtlxSetSecurity;
var
  xMemory: ISecDesc;
begin
  Result := RtlxAllocateSD(SD, xMemory);

  if Result.IsSuccess then
    Result := Method(hObject, SecurityInformation, xMemory.Data);
end;

{ SDDL }

type
  TAutoLocalMem = class (TCustomAutoMemory, IMemory)
    procedure Release; override;
  end;

procedure TAutoLocalMem.Release;
begin
  LocalFree(FData);
  inherited;
end;

function AdvxSddlToSecurityDescriptor;
var
  pSD: PSecurityDescriptor;
  Size: Cardinal;
begin
  Size := 0;
  Result.Location := 'ConvertStringSecurityDescriptorToSecurityDescriptorW';
  Result.Win32Result := ConvertStringSecurityDescriptorToSecurityDescriptorW(
    PWideChar(SDDL), SECURITY_DESCRIPTOR_REVISION, pSD, @Size);

  if Result.IsSuccess then
    IMemory(SecDesc) := TAutoLocalMem.Capture(pSD, Size);
end;

function AdvxSecurityDescriptorToSddl;
var
  Buffer: PWideChar;
  Size: Cardinal;
begin
  Size := 0;
  Result.Location := 'ConvertSecurityDescriptorToStringSecurityDescriptorW';
  Result.Win32Result := ConvertSecurityDescriptorToStringSecurityDescriptorW(
    SecDesc, SECURITY_DESCRIPTOR_REVISION, SecurityInformation, Buffer, @Size);

  if Result.IsSuccess then
  begin
    RtlxSetStringW(SDDL, Buffer, Size);
    LocalFree(Buffer);
  end;
end;

end.
