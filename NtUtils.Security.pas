unit NtUtils.Security;

{
  Base functions for working with Security Descriptors.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntseapi, NtUtils;

type
  TSecurityDescriptorData = record
    Control: TSecurityDescriptorControl;
    Owner, Group: ISid;
    Dacl, Sacl: IAcl;

    class function Create(
      Control: TSecurityDescriptorControl = 0;
      Dacl: IAcl = nil;
      Sacl: IAcl = nil;
      Owner: ISid = nil;
      Group: ISid = nil
    ): TSecurityDescriptorData; static;
  end;

  TSecurityQueryFunction = function (
    [Access(OBJECT_READ_SECURITY)] hObject: THandle;
    SecurityInformation: TSecurityInformation;
    out xMemory: ISecurityDescriptor
  ): TNtxStatus;

  TSecuritySetFunction = function (
    [Access(OBJECT_WRITE_SECURITY)] hObject: THandle;
    SecurityInformation: TSecurityInformation;
    [in] SD: PSecurityDescriptor
  ): TNtxStatus;

// Capture a copy of a security descriptor
function RtlxCaptureSecurityDescriptor(
  [in] SourceSD: PSecurityDescriptor;
  out SdData: TSecurityDescriptorData
): TNtxStatus;

// Allocate a new self-relative security descriptor
function RtlxAllocateSecurityDescriptor(
  const SD: TSecurityDescriptorData;
  out xMemory: ISecurityDescriptor
): TNtxStatus;

{ Object Security: Query }

// Query a security of an generic object
function RtlxQuerySecurityObject(
  [Access(OBJECT_READ_SECURITY)] hObject: THandle;
  Method: TSecurityQueryFunction;
  SecurityInformation: TSecurityInformation;
  out SD: TSecurityDescriptorData
): TNtxStatus;

// Query DACL of an generic object
function RtlxQueryDaclObject(
  [Access(READ_CONTROL)] hObject: THandle;
  Method: TSecurityQueryFunction;
  out Dacl: IAcl
): TNtxStatus;

// Query SACL of an generic object
function RtlxQuerySaclObject(
  [Access(ACCESS_SYSTEM_SECURITY)] hObject: THandle;
  Method: TSecurityQueryFunction;
  out Sacl: IAcl
): TNtxStatus;

// Query owner of a generic object
function RtlxQueryOwnerObject(
  [Access(READ_CONTROL)] hObject: THandle;
  Method: TSecurityQueryFunction;
  out Owner: ISid
): TNtxStatus;

// Query primary group of a generic object
function RtlxQueryGroupObject(
  [Access(READ_CONTROL)] hObject: THandle;
  Method: TSecurityQueryFunction;
  out PrimaryGroup: ISid
): TNtxStatus;

// Query mandatory label of a generic object
function RtlxQueryLabelObject(
  [Access(READ_CONTROL)] hObject: THandle;
  Method: TSecurityQueryFunction;
  out LabelRid: TIntegrityRid;
  out Policy: TMandatoryLabelMask
): TNtxStatus;

{ Object Security: Set }

// Set a security on an generic object
function RtlxSetSecurityObject(
  [Access(OBJECT_WRITE_SECURITY)] hObject: THandle;
  Method: TSecuritySetFunction;
  SecurityInformation: TSecurityInformation;
  const SD: TSecurityDescriptorData
): TNtxStatus;

// Set DACL on an generic object
function RtlxSetDaclObject(
  [Access(WRITE_DAC)] hObject: THandle;
  Method: TSecuritySetFunction;
  const Dacl: IAcl
): TNtxStatus;

// Set SACL on an generic object
function RtlxSetSaclObject(
  [Access(ACCESS_SYSTEM_SECURITY)] hObject: THandle;
  Method: TSecuritySetFunction;
  const Sacl: IAcl
): TNtxStatus;

// Set owner on an generic object
function RtlxSetOwnerObject(
  [Access(WRITE_OWNER)] hObject: THandle;
  Method: TSecuritySetFunction;
  const Owner: ISid
): TNtxStatus;

// Set primary group on an generic object
function RtlxSetGroupObject(
  [Access(WRITE_OWNER)] hObject: THandle;
  Method: TSecuritySetFunction;
  const PrimaryGroup: ISid
): TNtxStatus;

// Set mandatory label on an generic object
function RtlxSetLabelObject(
  [Access(WRITE_OWNER)] hObject: THandle;
  Method: TSecuritySetFunction;
  LabelRid: TIntegrityRid;
  Policy: TMandatoryLabelMask
): TNtxStatus;

{ Denying DACL }

// Craft a DACL that denies everything
function RtlxAllocateDenyingDacl: IAcl;

// Craft a security descriptor that denies everything
function RtlxAllocateDenyingSd: ISecurityDescriptor;

{ SDDL }

// Parse a textual definition of a security descriptor
function AdvxSddlToSecurityDescriptor(
  const SDDL: String;
  out SecDesc: ISecurityDescriptor
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

class function TSecurityDescriptorData.Create;
begin
  Result.Control := Control;
  Result.Owner := Owner;
  Result.Group := Group;
  Result.Dacl := Dacl;
  Result.Sacl := Sacl;
end;

function RtlxCaptureSecurityDescriptor;
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
  Result.Status := RtlGetControlSecurityDescriptor(SourceSD, SdData.Control,
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
    Result := RtlxCopySid(Sid, SdData.Owner);

  // Primary group
  Sid := nil;
  Result.Location := 'RtlGetGroupSecurityDescriptor';
  Result.Status := RtlGetGroupSecurityDescriptor(SourceSD, Sid, Defaulted);

  if not Result.IsSuccess then
    Exit;

  if Assigned(Sid) then
    Result := RtlxCopySid(Sid, SdData.Group);

  // DACL
  Acl := nil;
  Result.Location := 'RtlGetDaclSecurityDescriptor';
  Result.Status := RtlGetDaclSecurityDescriptor(SourceSD, Present, Acl,
    Defaulted);

  if not Result.IsSuccess then
    Exit;

  if Assigned(Acl) then
    Result := RtlxCopyAcl(SdData.Dacl, Acl);

  // SACL
  Acl := nil;
  Result.Location := 'RtlGetSaclSecurityDescriptor';
  Result.Status := RtlGetSaclSecurityDescriptor(SourceSD, Present, Acl,
    Defaulted);

  if Result.IsSuccess and Assigned(Acl) then
    Result := RtlxCopyAcl(SdData.Sacl, Acl);
end;

function RtlxAllocateSecurityDescriptor;
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

{ Object Security }

function RtlxQuerySecurityObject;
var
  xMemory: ISecurityDescriptor;
begin
  Result := Method(hObject, SecurityInformation, xMemory);

  if Result.IsSuccess then
    Result := RtlxCaptureSecurityDescriptor(xMemory.Data, SD);
end;

function RtlxQueryDaclObject;
var
  SD: TSecurityDescriptorData;
begin
  Result := RtlxQuerySecurityObject(hObject, Method, DACL_SECURITY_INFORMATION,
    SD);

  if Result.IsSuccess then
    Dacl := SD.Dacl;
end;

function RtlxQuerySaclObject;
var
  SD: TSecurityDescriptorData;
begin
  Result := RtlxQuerySecurityObject(hObject, Method, SACL_SECURITY_INFORMATION,
    SD);

  if Result.IsSuccess then
    Sacl := SD.Sacl;
end;

function RtlxQueryOwnerObject;
var
  SD: TSecurityDescriptorData;
begin
  Result := RtlxQuerySecurityObject(hObject, Method, OWNER_SECURITY_INFORMATION,
    SD);

  if Result.IsSuccess then
    Owner := SD.Owner;
end;

function RtlxQueryGroupObject;
var
  SD: TSecurityDescriptorData;
begin
  Result := RtlxQuerySecurityObject(hObject, Method, GROUP_SECURITY_INFORMATION,
    SD);

  if Result.IsSuccess then
    PrimaryGroup := SD.Group;
end;

function RtlxQueryLabelObject;
var
  SD: TSecurityDescriptorData;
  Aces: TArray<TAceData>;
  i: Integer;
begin
  Result := RtlxQuerySecurityObject(hObject, Method, LABEL_SECURITY_INFORMATION,
    SD);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxDumpAcl(Auto.RefOrNil<PAcl>(SD.Sacl), Aces);

  if not Result.IsSuccess then
    Exit;

  for i := 0 to High(Aces) do
    if Aces[i].AceType = SYSTEM_MANDATORY_LABEL_ACE_TYPE then
    begin
      // The system only takes the first entry into account
      LabelRid := RtlxRidSid(Aces[i].SID, SECURITY_MANDATORY_UNTRUSTED_RID);
      Policy := Aces[i].Mask;
      Exit;
    end;

  Result.Location := 'RtlxQueryLabelObject';
  Result.Status := STATUS_NOT_FOUND;
end;

function RtlxSetSecurityObject;
var
  xMemory: ISecurityDescriptor;
begin
  Result := RtlxAllocateSecurityDescriptor(SD, xMemory);

  if Result.IsSuccess then
    Result := Method(hObject, SecurityInformation, xMemory.Data);
end;

function RtlxSetDaclObject;
begin
  Result := RtlxSetSecurityObject(hObject, Method, DACL_SECURITY_INFORMATION,
    TSecurityDescriptorData.Create(SE_DACL_PRESENT, Dacl));
end;

function RtlxSetSaclObject;
begin
  Result := RtlxSetSecurityObject(hObject, Method, SACL_SECURITY_INFORMATION,
    TSecurityDescriptorData.Create(SE_SACL_PRESENT, nil, Sacl));
end;

function RtlxSetOwnerObject;
begin
  Result := RtlxSetSecurityObject(hObject, Method, OWNER_SECURITY_INFORMATION,
    TSecurityDescriptorData.Create(0, nil, nil, Owner));
end;

function RtlxSetGroupObject;
begin
  Result := RtlxSetSecurityObject(hObject, Method, GROUP_SECURITY_INFORMATION,
    TSecurityDescriptorData.Create(0, nil, nil, nil, PrimaryGroup));
end;

function RtlxSetLabelObject;
var
  Sacl: IAcl;
begin
  Result := RtlxBuildAcl(Sacl, [
    TAceData.New(SYSTEM_MANDATORY_LABEL_ACE_TYPE, 0, Policy,
      RtlxMakeSid(SECURITY_MANDATORY_LABEL_AUTHORITY, [LabelRid])
    )
  ]);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxSetSecurityObject(hObject, Method, LABEL_SECURITY_INFORMATION,
    TSecurityDescriptorData.Create(SE_SACL_PRESENT, nil, Sacl));
end;

{ Denying DACL }

function RtlxAllocateDenyingDacl;
begin
  if not RtlxBuildAcl(Result, [
    TAceData.New(ACCESS_DENIED_ACE_TYPE, 0, GENERIC_ALL,
      RtlxMakeSid(SECURITY_CREATOR_SID_AUTHORITY,
        [SECURITY_CREATOR_OWNER_RIGHTS_RID]))
  ]).IsSuccess then
    Result := nil;
end;

function RtlxAllocateDenyingSd;
begin
  if not RtlxAllocateSecurityDescriptor(TSecurityDescriptorData.Create(
    SE_DACL_PRESENT, RtlxAllocateDenyingDacl), Result).IsSuccess then
    Result := nil;
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
    SDDL := RtlxCaptureString(Buffer, Size);
    LocalFree(Buffer);
  end;
end;

end.
