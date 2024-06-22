unit NtUtils.Security;

{
  Base functions for working with Security Descriptors.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntseapi, Ntapi.Versions, NtUtils, NtUtils.Security.Acl;

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
    [Access(OBJECT_READ_SECURITY)] const hxObject: IHandle;
    SecurityInformation: TSecurityInformation;
    out xMemory: ISecurityDescriptor
  ): TNtxStatus;

  TSecuritySetFunction = function (
    [Access(OBJECT_WRITE_SECURITY)] const hxObject: IHandle;
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
  [Access(OBJECT_READ_SECURITY)] const hxObject: IHandle;
  Method: TSecurityQueryFunction;
  SecurityInformation: TSecurityInformation;
  out SD: TSecurityDescriptorData
): TNtxStatus;

// Query DACL of an generic object
function RtlxQueryDaclObject(
  [Access(READ_CONTROL)] const hxObject: IHandle;
  Method: TSecurityQueryFunction;
  [MayReturnNil] out Dacl: IAcl
): TNtxStatus;

// Query SACL of an generic object
function RtlxQuerySaclObject(
  [Access(ACCESS_SYSTEM_SECURITY)] const hxObject: IHandle;
  Method: TSecurityQueryFunction;
  [MayReturnNil] out Sacl: IAcl;
  SecurityInformation: TSecurityInformation = SACL_SECURITY_INFORMATION
): TNtxStatus;

// Query owner of a generic object
function RtlxQueryOwnerObject(
  [Access(READ_CONTROL)] const hxObject: IHandle;
  Method: TSecurityQueryFunction;
  out Owner: ISid
): TNtxStatus;

// Query primary group of a generic object
function RtlxQueryGroupObject(
  [Access(READ_CONTROL)] const hxObject: IHandle;
  Method: TSecurityQueryFunction;
  out PrimaryGroup: ISid
): TNtxStatus;

// Query mandatory label of a generic object
function RtlxQueryLabelObject(
  [Access(READ_CONTROL)] const hxObject: IHandle;
  Method: TSecurityQueryFunction;
  out LabelRid: TIntegrityRid;
  out Policy: TMandatoryLabelMask
): TNtxStatus;

// Query trust label of a generic object
[MinOSVersion(OsWin81)]
function RtlxQueryTrustObject(
  [Access(READ_CONTROL)] const hxObject: IHandle;
  Method: TSecurityQueryFunction;
  out TrustType: TSecurityTrustType;
  out TrustLevel: TSecurityTrustLevel;
  out AccessMask: TAccessMask
): TNtxStatus;

{ Object Security: Set }

// Set a security on an generic object
function RtlxSetSecurityObject(
  [Access(OBJECT_WRITE_SECURITY)] const hxObject: IHandle;
  Method: TSecuritySetFunction;
  SecurityInformation: TSecurityInformation;
  const SD: TSecurityDescriptorData
): TNtxStatus;

// Set DACL on an generic object
function RtlxSetDaclObject(
  [Access(WRITE_DAC)] const hxObject: IHandle;
  Method: TSecuritySetFunction;
  const Dacl: IAcl;
  SecurityInformation: TSecurityInformation = DACL_SECURITY_INFORMATION
): TNtxStatus;

// Set SACL on an generic object
function RtlxSetSaclObject(
  [Access(ACCESS_SYSTEM_SECURITY)] const hxObject: IHandle;
  Method: TSecuritySetFunction;
  const Sacl: IAcl;
  SecurityInformation: TSecurityInformation = SACL_SECURITY_INFORMATION
): TNtxStatus;

// Set owner on an generic object
function RtlxSetOwnerObject(
  [Access(WRITE_OWNER)] const hxObject: IHandle;
  Method: TSecuritySetFunction;
  const Owner: ISid
): TNtxStatus;

// Set primary group on an generic object
function RtlxSetGroupObject(
  [Access(WRITE_OWNER)] const hxObject: IHandle;
  Method: TSecuritySetFunction;
  const PrimaryGroup: ISid
): TNtxStatus;

// Set mandatory label on an generic object
function RtlxSetLabelObject(
  [Access(WRITE_OWNER)] const hxObject: IHandle;
  Method: TSecuritySetFunction;
  LabelRid: TIntegrityRid;
  Policy: TMandatoryLabelMask
): TNtxStatus;

// Set trust label on an generic object
[MinOSVersion(OsWin81)]
function RtlxSetTrustObject(
  [Access(WRITE_DAC)] const hxObject: IHandle;
  Method: TSecuritySetFunction;
  TrustType: TSecurityTrustType;
  TrustLevel: TSecurityTrustLevel;
  AccessMask: TAccessMask
): TNtxStatus;

{ Denying DACL }

// Craft a DACL that denies everything
function RtlxAllocateDenyingDacl: IAcl;

// Craft a security descriptor that denies everything
function RtlxAllocateDenyingSd: ISecurityDescriptor;

{ SDDL }

// Parse a textual definition of a security descriptor
function AdvxSecurityDescriptorFromSddl(
  const SDDL: String;
  out SecDesc: ISecurityDescriptor
): TNtxStatus;

// Parse a textual definition of a security descriptor and capture the result
function AdvxSecurityDescriptorDataFromSddl(
  const SDDL: String;
  out SD: TSecurityDescriptorData
): TNtxStatus;

// Construct a textual definition of a security descriptor
function AdvxSecurityDescriptorToSddl(
  [in] SecDesc: PSecurityDescriptor;
  SecurityInformation: TSecurityInformation;
  out SDDL: String
): TNtxStatus;

// Construct a textual definition of a captured security descriptor
function AdvxSecurityDescriptorDataToSddl(
  const SD: TSecurityDescriptorData;
  SecurityInformation: TSecurityInformation;
  out SDDL: String
): TNtxStatus;

// Convert an ACE to SDDL
function AdvxAceToSddl(
  const Ace: TAceData;
  out AceSDDL: String
): TNtxStatus;

// Parse a SDDL of an ACE
function AdvxAceFromSddl(
  const AceSDDL: String;
  IsAccessAce: Boolean;
  out Ace: TAceData
): TNtxStatus;

// Convert a condition of a callback ACE to SDDL
function AdvxAceConditionToSddl(
  [opt] const AceCondition: IMemory;
  out ConditionString: String
): TNtxStatus;

// Convert a SDDL condition string to a binary form suitable for callback ACEs
function AdvxAceConditionFromSddl(
  const ConditionString: String;
  [MayReturnNil] out AceCondition: IMemory
): TNtxStatus;

implementation

uses
  Ntapi.ntrtl, Ntapi.ntstatus, Ntapi.WinBase, NtUtils.SysUtils,
  NtUtils.Security.Sid, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

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
    Result := RtlxCaptureAcl(SdData.Dacl, Acl);

  // SACL
  Acl := nil;
  Result.Location := 'RtlGetSaclSecurityDescriptor';
  Result.Status := RtlGetSaclSecurityDescriptor(SourceSD, Present, Acl,
    Defaulted);

  if Result.IsSuccess and Assigned(Acl) then
    Result := RtlxCaptureAcl(SdData.Sacl, Acl);
end;

function RtlxAllocateSecurityDescriptor;
const
  SE_CONTROL_CUSTOM = High(TSecurityDescriptorControl)
    and not SE_OWNER_DEFAULTED and not SE_GROUP_DEFAULTED
    and not SE_DACL_PRESENT and not SE_DACL_DEFAULTED
    and not SE_SACL_PRESENT and not SE_SACL_DEFAULTED
    and not SE_SELF_RELATIVE;
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
  Result := Method(hxObject, SecurityInformation, xMemory);

  if Result.IsSuccess then
    Result := RtlxCaptureSecurityDescriptor(xMemory.Data, SD);
end;

function RtlxQueryDaclObject;
var
  SD: TSecurityDescriptorData;
begin
  Result := RtlxQuerySecurityObject(hxObject, Method, DACL_SECURITY_INFORMATION,
    SD);

  if Result.IsSuccess then
    Dacl := SD.Dacl;
end;

function RtlxQuerySaclObject;
var
  SD: TSecurityDescriptorData;
begin
  Result := RtlxQuerySecurityObject(hxObject, Method, SecurityInformation,
    SD);

  if Result.IsSuccess then
    Sacl := SD.Sacl;
end;

function RtlxQueryOwnerObject;
var
  SD: TSecurityDescriptorData;
begin
  Result := RtlxQuerySecurityObject(hxObject, Method,
    OWNER_SECURITY_INFORMATION, SD);

  if not Result.IsSuccess then
    Exit;

  if not Assigned(SD.Owner) then
  begin
    Result.Location := 'RtlxQueryOwnerObject';
    Result.Status := STATUS_INVALID_SID;
    Exit;
  end;

  Owner := SD.Owner;
end;

function RtlxQueryGroupObject;
var
  SD: TSecurityDescriptorData;
begin
  Result := RtlxQuerySecurityObject(hxObject, Method,
    GROUP_SECURITY_INFORMATION, SD);

  if not Result.IsSuccess then
    Exit;

  if not Assigned(SD.Group) then
  begin
    Result.Location := 'RtlxQueryGroupObject';
    Result.Status := STATUS_INVALID_SID;
    Exit;
  end;

  PrimaryGroup := SD.Group;
end;

function RtlxQueryLabelObject;
var
  SD: TSecurityDescriptorData;
  Ace: TAceData;
  i: Integer;
begin
  Result := RtlxQuerySecurityObject(hxObject, Method,
    LABEL_SECURITY_INFORMATION, SD);

  if not Result.IsSuccess then
    Exit;

  for i := 0 to Pred(RtlxSizeAcl(SD.Sacl).AceCount) do
  begin
    Result := RtlxGetAce(SD.Sacl, i, Ace);

    if not Result.IsSuccess then
      Exit;

    if Ace.AceType <> SYSTEM_MANDATORY_LABEL_ACE_TYPE then
      Continue;

    // Skip inherit-only ACEs
    if BitTest(Ace.AceFlags and INHERIT_ONLY_ACE) then
      Continue;

    // The system only takes the first entry into account
    LabelRid := RtlxRidSid(Ace.SID, SECURITY_MANDATORY_UNTRUSTED_RID);
    Policy := Ace.Mask;
    Exit;
  end;

  Result.Location := 'RtlxQueryLabelObject';
  Result.Status := STATUS_NOT_FOUND;
end;

function RtlxQueryTrustObject;
var
  SD: TSecurityDescriptorData;
  Ace: TAceData;
  SubAuthorities: TArray<Cardinal>;
  i: Integer;
begin
  Result := RtlxQuerySecurityObject(hxObject, Method,
    PROCESS_TRUST_LABEL_SECURITY_INFORMATION, SD);

  if not Result.IsSuccess then
    Exit;

  for i := 0 to Pred(RtlxSizeAcl(SD.Sacl).AceCount) do
  begin
    Result := RtlxGetAce(SD.Sacl, i, Ace);

    if not Result.IsSuccess then
      Exit;

    if Ace.AceType <> SYSTEM_PROCESS_TRUST_LABEL_ACE_TYPE then
      Continue;

    // Skip inherit-only ACEs
    if BitTest(Ace.AceFlags and INHERIT_ONLY_ACE) then
      Continue;

    // The system only takes the first entry into account
    AccessMask := Ace.Mask;
    SubAuthorities := RtlxSubAuthoritiesSid(Ace.SID);

    if Length(SubAuthorities) >= SECURITY_PROCESS_TRUST_AUTHORITY_RID_COUNT then
    begin
      TrustType := SubAuthorities[Pred(High(SubAuthorities))];
      TrustLevel := SubAuthorities[High(SubAuthorities)];
    end
    else
    begin
      TrustType := SECURITY_PROCESS_PROTECTION_TYPE_NONE_RID;
      TrustLevel := SECURITY_PROCESS_PROTECTION_LEVEL_NONE_RID;
    end;

    Exit;
  end;

  Result.Location := 'RtlxQueryTrustObject';
  Result.Status := STATUS_NOT_FOUND;
end;

function RtlxSetSecurityObject;
var
  xMemory: ISecurityDescriptor;
begin
  Result := RtlxAllocateSecurityDescriptor(SD, xMemory);

  if Result.IsSuccess then
    Result := Method(hxObject, SecurityInformation, xMemory.Data);
end;

function RtlxSetDaclObject;
begin
  Result := RtlxSetSecurityObject(hxObject, Method, SecurityInformation,
    TSecurityDescriptorData.Create(SE_DACL_PRESENT, Dacl));
end;

function RtlxSetSaclObject;
begin
  Result := RtlxSetSecurityObject(hxObject, Method, SecurityInformation,
    TSecurityDescriptorData.Create(SE_SACL_PRESENT, nil, Sacl));
end;

function RtlxSetOwnerObject;
begin
  Result := RtlxSetSecurityObject(hxObject, Method, OWNER_SECURITY_INFORMATION,
    TSecurityDescriptorData.Create(0, nil, nil, Owner));
end;

function RtlxSetGroupObject;
begin
  Result := RtlxSetSecurityObject(hxObject, Method, GROUP_SECURITY_INFORMATION,
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

  Result := RtlxSetSecurityObject(hxObject, Method, LABEL_SECURITY_INFORMATION,
    TSecurityDescriptorData.Create(SE_SACL_PRESENT, nil, Sacl));
end;

function RtlxSetTrustObject;
var
  Sacl: IAcl;
begin
  Result := RtlxBuildAcl(Sacl, [
    TAceData.New(SYSTEM_PROCESS_TRUST_LABEL_ACE_TYPE, 0, AccessMask,
      RtlxMakeSid(SECURITY_PROCESS_TRUST_AUTHORITY, [TrustType, TrustLevel])
    )
  ]);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxSetSecurityObject(hxObject, Method,
    PROCESS_TRUST_LABEL_SECURITY_INFORMATION,
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
  TAutoLocalMem = class (TCustomAutoMemory, IMemory, IAutoPointer, IAutoReleasable)
    procedure Release; override;
  end;

procedure TAutoLocalMem.Release;
begin
  if Assigned(FData) then
    LocalFree(FData);

  FData := nil;
  inherited;
end;

function AdvxSecurityDescriptorFromSddl;
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

function AdvxSecurityDescriptorDataFromSddl;
var
  SecDesc: ISecurityDescriptor;
begin
  Result := AdvxSecurityDescriptorFromSddl(SDDL, SecDesc);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxCaptureSecurityDescriptor(SecDesc.Data, SD);
end;

function AdvxSecurityDescriptorToSddl;
var
  Buffer: PWideChar;
  BufferDeallocator: IAutoReleasable;
  Size: Cardinal;
begin
  Size := 0;
  Result.Location := 'ConvertSecurityDescriptorToStringSecurityDescriptorW';
  Result.Win32Result := ConvertSecurityDescriptorToStringSecurityDescriptorW(
    SecDesc, SECURITY_DESCRIPTOR_REVISION, SecurityInformation, Buffer, @Size);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := AdvxDelayLocalFree(Buffer);
  SDDL := RtlxCaptureString(Buffer, Size);
end;

function AdvxSecurityDescriptorDataToSddl;
var
  SecDesc: ISecurityDescriptor;
begin
  Result := RtlxAllocateSecurityDescriptor(SD, SecDesc);

  if not Result.IsSuccess then
    Exit;

  Result := AdvxSecurityDescriptorToSddl(SecDesc.Data, SecurityInformation,
    SDDL);
end;

function AdvxAceToSddl;
var
  SecDesc: TSecurityDescriptorData;
  Acl: IAcl;
begin
  // Make an ACL with this ACE
  Result := RtlxBuildAcl(Acl, [Ace]);

  if not Result.IsSuccess then
    Exit;

  // Construct a security descriptor definition
  if Ace.AceType in AccessAces then
    SecDesc := TSecurityDescriptorData.Create(SE_DACL_PRESENT, Acl)
  else if Ace.AceType in SystemAces then
    SecDesc := TSecurityDescriptorData.Create(SE_SACL_PRESENT, nil, Acl)
  else
  begin
    // Unrecognized type
    Result.Location := 'AdvxAceToSddl';
    Result.Status := STATUS_INVALID_ACL;
    Exit;
  end;

  // Convert it to SDDL
  Result := AdvxSecurityDescriptorDataToSddl(SecDesc,
    AceSecurityInformation[Ace.AceType], AceSDDL);

  if not Result.IsSuccess then
    Exit;

  // Extract the ACE portion
  if not RtlxPrefixStripString('D:', AceSDDL) and
    not RtlxPrefixStripString('S:', AceSDDL) then
  begin
    AceSDDL := '';
    Result.Location := 'AdvxAceToSddl';
    Result.Status := STATUS_UNSUCCESSFUL;
  end;
end;

function AdvxAceFromSddl;
var
  SD: TSecurityDescriptorData;
  Acl: IAcl;
begin
  // Make a security descriptor SDDL with one ACE
  if IsAccessAce then
    Result := AdvxSecurityDescriptorDataFromSddl('D:' + AceSDDL, SD)
  else
    Result := AdvxSecurityDescriptorDataFromSddl('S:' + AceSDDL, SD);

  if not Result.IsSuccess then
    Exit;

  // Extract either DACL or SACL
  if IsAccessAce and BitTest(SD.Control and SE_DACL_PRESENT) and
    Assigned(SD.Dacl) and (RtlxSizeAcl(SD.Dacl).AceCount = 1)  then
    Acl := SD.Dacl
  else if not IsAccessAce and BitTest(SD.Control and SE_SACL_PRESENT) and
    Assigned(SD.Sacl) and (RtlxSizeAcl(SD.Sacl).AceCount = 1) then
    Acl := SD.Sacl
  else
  begin
    Result.Location := 'AdvxAceFromSddl';
    Result.Status := STATUS_UNSUCCESSFUL;
    Exit;
  end;

  // Extract the ACE in its binary form
  Result := RtlxGetAce(Acl, 0, Ace);
end;

function AdvxAceConditionToSddl;
var
  AceCopy: TAceData;
begin
  if not Assigned(AceCondition) then
  begin
    ConditionString := '';
    Exit(NtxSuccess);
  end;

  // Make an ACE with a known SDDL representation except for the condition part
  AceCopy := Default(TAceData);
  AceCopy.AceType := ACCESS_ALLOWED_CALLBACK_ACE_TYPE;
  AceCopy.Mask := GENERIC_ALL;
  AceCopy.SID := RtlxMakeSid(SECURITY_NT_AUTHORITY,
    [SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_USERS]);
  AceCopy.ExtraData := AceCondition;

  // Convert the ACE to SDDL
  Result := AdvxAceToSddl(AceCopy, ConditionString);

  if not Result.IsSuccess then
    Exit;

  // Extract the condition
  if not RtlxPrefixStripString('(XA;;GA;;;BU;(', ConditionString) or
    not RtlxSuffixStripString('))', ConditionString) then
  begin
    ConditionString := '';
    Result.Location := 'AdvxAceConditionToSddl';
    Result.Status := STATUS_UNSUCCESSFUL;
  end;
end;

function AdvxAceConditionFromSddl;
var
  SD: TSecurityDescriptorData;
  Ace: TAceData;
begin
  if ConditionString = '' then
  begin
    AceCondition := nil;
    Exit(NtxSuccess);
  end;

  // Make a security descriptor with one callback ACE
  Result := AdvxSecurityDescriptorDataFromSddl('D:(XA;;GA;;;BU;(' +
    ConditionString + '))', SD);

  if not Result.IsSuccess then
    Exit;

  if BitTest(SD.Control and SE_DACL_PRESENT) and Assigned(SD.Dacl) and
    (RtlxSizeAcl(SD.Dacl).AceCount = 1) then
  begin
    // Extract the ACE in its binary form
    Result := RtlxGetAce(SD.Dacl, 0, Ace);

    if not Result.IsSuccess then
      Exit;

    if Assigned(Ace.ExtraData) then
    begin
      AceCondition := Ace.ExtraData;
      Exit;
    end;
  end;

  Result.Location := 'AdvxAceConditionFromSDDL';
  Result.Status := STATUS_UNSUCCESSFUL;
end;

end.
