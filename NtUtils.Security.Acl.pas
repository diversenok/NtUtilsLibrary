unit NtUtils.Security.Acl;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, NtUtils.Security.Sid, NtUtils,
  DelphiApi.Reflection, DelphiUtils.AutoObject;

type
  TAce = record
    AceType: TAceType;
    AceFlags: TAceFlags;
    Mask: TAccessMask;
    SID: ISid;
    function Size: Cardinal;
    function Allocate: IMemory<PAce>;
  end;

  IAcl = IMemory<PAcl>;

{ Information }

// Get a pointer to ACL or nil
function AclRefOrNil(Acl: IAcl): PAcl;

// Query ACL size information
function RtlxQuerySizeAcl(Acl: PAcl; out SizeInfo: TAclSizeInformation):
  TNtxStatus;

{ ACL manipulation }

// Create a new ACL
function RtlxCreateAcl(out Acl: IAcl; Size: Cardinal): TNtxStatus;

// Relocate the ACL if necessary to satisfy the size requirements
function RtlxExpandAcl(Acl: IAcl; NewSize: Cardinal): TNtxStatus;

// Append all ACEs from one ACL to another
function RtlxAppendAcl(TargetAcl: IAcl; SourceAcl: PAcl): TNtxStatus;

// Create a copy of an ACL
function RtlxCopyAcl(SourceAcl: PAcl; out NewAcl: IAcl): TNtxStatus;

// Map a generic mapping for each ACE in the ACL
function RtlxMapGenericMaskAcl(Acl: IAcl; const GenericMapping: TGenericMapping)
  : TNtxStatus;

{ ACE manipulation }

// Insert an ACE into a particular loaction
function RtlxInsertAce(Acl: IAcl; const Ace: TAce; Index: Integer = -1)
  : TNtxStatus;

// Remove an ACE by index
function RtlxDeleteAce(Acl: PAcl; Index: Integer): TNtxStatus;

// Obtain a copy of an ACE
function RtlxGetAce(Acl: PAcl; Index: Integer; out Ace: TAce): TNtxStatus;

{ Security descriptors }

// Prepare security descriptor
function RtlxCreateSecurityDescriptor(var SecDesc: TSecurityDescriptor):
  TNtxStatus;

// Get owner from the security descriptor
function RtlxGetOwnerSD(pSecDesc: PSecurityDescriptor; out Owner: ISid):
  TNtxStatus;

// Get primary group from the security descriptor
function RtlxGetPrimaryGroupSD(pSecDesc: PSecurityDescriptor; out Group: ISid):
  TNtxStatus;

// Get DACL from the security descriptor
function RtlxGetDaclSD(pSecDesc: PSecurityDescriptor; out Dacl: IAcl):
  TNtxStatus;

// Get SACL from the security descriptor
function RtlxGetSaclSD(pSecDesc: PSecurityDescriptor; out Sacl: IAcl):
  TNtxStatus;

// Prepare a security descriptor with an owner
function RtlxPrepareOwnerSD(var SecDesc: TSecurityDescriptor; Owner: ISid):
  TNtxStatus;

// Prepare a security descriptor with a primary group
function RtlxPreparePrimaryGroupSD(var SecDesc: TSecurityDescriptor; Group: ISid):
  TNtxStatus;

// Prepare a security descriptor with a DACL
function RtlxPrepareDaclSD(var SecDesc: TSecurityDescriptor; Dacl: IAcl):
  TNtxStatus;

// Prepare a security descriptor with a SACL
function RtlxPrepareSaclSD(var SecDesc: TSecurityDescriptor; Sacl: IAcl):
  TNtxStatus;

// Compute required access to read/write security
function RtlxComputeReadAccess(SecurityInformation: TSecurityInformation)
  : TAccessMask;
function RtlxComputeWriteAccess(SecurityInformation: TSecurityInformation)
  : TAccessMask;

implementation

uses
  Ntapi.ntrtl, Ntapi.ntstatus;

{ TAce }

function TAce.Allocate: IMemory<PAce>;
begin
  IMemory(Result) := TAutoMemory.Allocate(Size);
  Result.Data.Header.AceType := AceType;
  Result.Data.Header.AceFlags := AceFlags;
  Result.Data.Header.AceSize := Size;
  Result.Data.Mask := Mask;
  Move(Sid.Data^, Result.Data.Sid^, RtlLengthSid(Sid.Data));
end;

function TAce.Size: Cardinal;
begin
  Result := SizeOf(TAce_Internal) - SizeOf(Cardinal) + RtlLengthSid(Sid.Data);
end;

{ IAcl }

function AclRefOrNil(Acl: IAcl): PAcl;
begin
  if Assigned(Acl) then
    Result := Acl.Data
  else
    Result := nil;
end;

function RtlxQuerySizeAcl(Acl: PAcl; out SizeInfo: TAclSizeInformation):
  TNtxStatus;
begin
  Result.Location := 'RtlQueryInformationAcl';
  Result.LastCall.AttachInfoClass(AclSizeInformation);
  Result.Status := RtlQueryInformationAcl(Acl, SizeInfo);
end;

 { Creation and allocation }

function RtlxCreateAcl(out Acl: IAcl; Size: Cardinal): TNtxStatus;
begin
  // Align the size up to the next DWORD
  Size := (Size + SizeOf(Cardinal) - 1) and not (SizeOf(Cardinal) - 1);

  if Size > MAX_ACL_SIZE then
    Size := MAX_ACL_SIZE;

  IMemory(Acl) := TAutoMemory.Allocate(Size);

  Result.Location := 'RtlCreateAcl';
  Result.Status := RtlCreateAcl(Acl.Data, Acl.Size, ACL_REVISION);
end;

function AddExtraSpace(Size: Cardinal): Cardinal;
begin
  // + 12.5% + 256 B
  Result := Size + Size shr 3 + 256;
end;

function RtlxExpandAcl(Acl: IAcl; NewSize: Cardinal): TNtxStatus;
var
  ExpandedAcl: IAcl;
begin
  Result.Location := 'RtlxExpandAcl';
  Result.Status := STATUS_SUCCESS;

  // Can't reallocate memory of unknown types
  if not (IUnknown(Acl) is TAutoMemory) then
    Result.Status := STATUS_NOT_SUPPORTED

  // Can't grow any more
  else if Acl.Size >= MAX_ACL_SIZE then
    Result.Status := STATUS_NO_MEMORY

  // Prevent shrinking
  else if NewSize < Acl.Size then
    Result.Status := STATUS_INVALID_PARAMETER;

  if not Result.IsSuccess then
    Exit;

  // Allocate a new ACL reserving some extra space
  Result := RtlxCreateAcl(ExpandedAcl, AddExtraSpace(NewSize));

  // Copy existing ACEs
  if Result.IsSuccess then
    Result := RtlxAppendAcl(ExpandedAcl, Acl.Data);

  // Swap references making the current ACL point to a new one
  if Result.IsSuccess then
    TAutoMemory(Acl).SwapWith(TAutoMemory(ExpandedAcl));
end;

function RtlxAppendAcl(TargetAcl: IAcl; SourceAcl: PAcl): TNtxStatus;
var
  SourceSize, TargetSize: TAclSizeInformation;
  Ace: PAce;
  i: Integer;
begin
  Result := RtlxQuerySizeAcl(SourceAcl, SourceSize);

  if not Result.IsSuccess or (SourceSize.AceCount = 0) then
    Exit;

  Result := RtlxQuerySizeAcl(TargetAcl.Data, TargetSize);

  if not Result.IsSuccess then
    Exit;

  // Expand the target ACL if necessary
  if TargetSize.AclBytesFree < SourceSize.AclBytesInUse then
  begin
    Result := RtlxExpandAcl(TargetAcl, TargetSize.AclBytesInUse +
      SourceSize.AclBytesInUse);

    if not Result.IsSuccess then
      Exit;
  end;

  // Copy ACEs
  for i := 0 to Pred(SourceSize.AceCount) do
  begin
    Result.Location := 'RtlGetAce';
    Result.Status := RtlGetAce(SourceAcl, i, Ace);

    if not Result.IsSuccess then
      Break;

    Result.Location := 'RtlAddAce';
    Result.Status := RtlAddAce(TargetAcl.Data, ACL_REVISION, -1, Ace,
      Ace.Header.AceSize);

    if not Result.IsSuccess then
      Break;
  end;
end;

function RtlxCopyAcl(SourceAcl: PAcl; out NewAcl: IAcl): TNtxStatus;
var
  SizeInfo: TAclSizeInformation;
begin
  if not Assigned(SourceAcl) or not RtlValidAcl(SourceAcl) then
  begin
    Result.Location := 'RtlValidAcl';
    Result.Status := STATUS_INVALID_ACL;
    Exit;
  end;

  // Determine the required size
  Result := RtlxQuerySizeAcl(SourceAcl, SizeInfo);

  if not Result.IsSuccess then
    Exit;

  // Create a new ACL reserving some extra space
  Result := RtlxCreateAcl(NewAcl, AddExtraSpace(SizeInfo.AclBytesInUse));

  if not Result.IsSuccess then
    Exit;

  // Copy all ACEs from the source
  Result := RtlxAppendAcl(NewAcl, SourceAcl);
end;

function RtlxMapGenericMaskAcl(Acl: IAcl; const GenericMapping: TGenericMapping)
  : TNtxStatus;
var
  i: Integer;
  SizeInfo: TAclSizeInformation;
  Ace: PAce;
begin
  Result := RtlxQuerySizeAcl(Acl.Data, SizeInfo);

  if not Result.IsSuccess then
    Exit;

  // Map generic mask on all ACEs
  Result.Location := 'RtlGetAce';
  for i := 0 to Pred(SizeInfo.AceCount) do
  begin
    Result.Status := RtlGetAce(Acl.Data, i, Ace);

    if not Result.IsSuccess then
      Break;

    RtlMapGenericMask(Ace.Mask, GenericMapping)
  end;
end;

function RtlxInsertAce(Acl: IAcl; const Ace: TAce; Index: Integer): TNtxStatus;
var
  SizeInfo: TAclSizeInformation;
begin
  // Determine the available memory in the ACL
  Result := RtlxQuerySizeAcl(Acl.Data, SizeInfo);

  if not Result.IsSuccess then
    Exit;

  // Expand it if necessary
  if SizeInfo.AclBytesFree < Ace.Size then
    Result := RtlxExpandAcl(Acl, SizeInfo.AclBytesInUse + Ace.Size);

  if not Result.IsSuccess then
    Exit;

  // Add the ACE
  Result.Location := 'RtlAddAce';
  Result.Status := RtlAddAce(Acl.Data, ACL_REVISION, Index, Ace.Allocate.Data,
    Ace.Size);
end;

function RtlxDeleteAce(Acl: PAcl; Index: Integer): TNtxStatus;
begin
  Result.Location := 'RtlDeleteAce';
  Result.Status := RtlDeleteAce(Acl, Index);
end;

function RtlxGetAce(Acl: PAcl; Index: Integer; out Ace: TAce): TNtxStatus;
var
  AceRef: PAce;
begin
  Result.Location := 'RtlGetAce';
  Result.Status := RtlGetAce(Acl, Index, AceRef);

  if not Result.IsSuccess then
    Exit;

  Ace.AceType := AceRef.Header.AceType;
  Ace.AceFlags := AceRef.Header.AceFlags;

  if AceRef.Header.AceType in NonObjectAces then
  begin
    Ace.Mask := AceRef.Mask;
    Result := RtlxCopySid(AceRef.Sid, Ace.Sid);
  end
  else
  begin
    // Unsupported ace type
    Result.Location := 'RtlxGetAce';
    Result.Status := STATUS_UNKNOWN_REVISION;
  end;
end;

function RtlxCreateSecurityDescriptor(var SecDesc: TSecurityDescriptor):
  TNtxStatus;
begin
  FillChar(SecDesc, SizeOf(SecDesc), 0);
  Result.Location := 'RtlCreateSecurityDescriptor';
  Result.Status := RtlCreateSecurityDescriptor(SecDesc,
    SECURITY_DESCRIPTOR_REVISION);
end;

function RtlxGetOwnerSD(pSecDesc: PSecurityDescriptor; out Owner: ISid):
  TNtxStatus;
var
  Defaulted: Boolean;
  OwnerSid: PSid;
begin
  Result.Location := 'RtlGetOwnerSecurityDescriptor';
  Result.Status := RtlGetOwnerSecurityDescriptor(pSecDesc, OwnerSid, Defaulted);

  if Result.IsSuccess then
    Result := RtlxCopySid(OwnerSid, Owner);
end;

function RtlxGetPrimaryGroupSD(pSecDesc: PSecurityDescriptor; out Group: ISid):
  TNtxStatus;
var
  Defaulted: Boolean;
  GroupSid: PSid;
begin
  Result.Location := 'RtlGetGroupSecurityDescriptor';
  Result.Status := RtlGetGroupSecurityDescriptor(pSecDesc, GroupSid, Defaulted);

  if Result.IsSuccess then
    Result := RtlxCopySid(GroupSid, Group);
end;

function RtlxGetDaclSD(pSecDesc: PSecurityDescriptor; out Dacl: IAcl):
  TNtxStatus;
var
  pDaclRef: PAcl;
  DaclPresent, Defaulted: Boolean;
begin
  Result.Location := 'RtlGetDaclSecurityDescriptor';
  Result.Status := RtlGetDaclSecurityDescriptor(pSecDesc, DaclPresent, pDaclRef,
    Defaulted);

  if Result.IsSuccess and DaclPresent and Assigned(pDaclRef) then
    Result := RtlxCopyAcl(pDaclRef, Dacl)
  else
    Dacl := nil;
end;

function RtlxGetSaclSD(pSecDesc: PSecurityDescriptor; out Sacl: IAcl):
  TNtxStatus;
var
  pSaclRef: PAcl;
  SaclPresent, Defaulted: Boolean;
begin
  Result.Location := 'RtlGetSaclSecurityDescriptor';
  Result.Status := RtlGetSaclSecurityDescriptor(pSecDesc, SaclPresent, pSaclRef,
    Defaulted);

  if Result.IsSuccess and SaclPresent and Assigned(pSaclRef) then
    Result := RtlxCopyAcl(pSaclRef, Sacl)
  else
    Sacl := nil;
end;

function RtlxPrepareOwnerSD(var SecDesc: TSecurityDescriptor; Owner: ISid):
  TNtxStatus;
begin
  Result := RtlxCreateSecurityDescriptor(SecDesc);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlSetOwnerSecurityDescriptor';

  if Assigned(Owner) then
    Result.Status := RtlSetOwnerSecurityDescriptor(SecDesc, Owner.Data, False)
  else
    Result.Status := RtlSetOwnerSecurityDescriptor(SecDesc, nil, True);
end;

function RtlxPreparePrimaryGroupSD(var SecDesc: TSecurityDescriptor; Group: ISid):
  TNtxStatus;
begin
  Result := RtlxCreateSecurityDescriptor(SecDesc);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlSetGroupSecurityDescriptor';

  if Assigned(Group) then
    Result.Status := RtlSetGroupSecurityDescriptor(SecDesc, Group.Data, False)
  else
    Result.Status := RtlSetGroupSecurityDescriptor(SecDesc, nil, True);
end;

function RtlxPrepareDaclSD(var SecDesc: TSecurityDescriptor; Dacl: IAcl):
  TNtxStatus;
begin
  Result := RtlxCreateSecurityDescriptor(SecDesc);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlSetDaclSecurityDescriptor';

  if Assigned(Dacl) then
    Result.Status := RtlSetDaclSecurityDescriptor(SecDesc, True, Dacl.Data,
      False)
  else
    Result.Status := RtlSetDaclSecurityDescriptor(SecDesc, True, nil, False);
end;

function RtlxPrepareSaclSD(var SecDesc: TSecurityDescriptor; Sacl: IAcl):
  TNtxStatus;
begin
  Result := RtlxCreateSecurityDescriptor(SecDesc);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlSetSaclSecurityDescriptor';

  if Assigned(Sacl) then
    Result.Status := RtlSetSaclSecurityDescriptor(SecDesc, True, Sacl.Data,
      False)
  else
    Result.Status := RtlSetSaclSecurityDescriptor(SecDesc, True, nil, False);
end;

function RtlxComputeReadAccess(SecurityInformation: TSecurityInformation)
  : TAccessMask;
const
  REQUIRE_READ_CONTROL = OWNER_SECURITY_INFORMATION or
    GROUP_SECURITY_INFORMATION or DACL_SECURITY_INFORMATION or
    LABEL_SECURITY_INFORMATION or ATTRIBUTE_SECURITY_INFORMATION or
    SCOPE_SECURITY_INFORMATION or BACKUP_SECURITY_INFORMATION;
  REQUIRE_SYSTEM_SECURITY = SACL_SECURITY_INFORMATION or
    BACKUP_SECURITY_INFORMATION;
begin
  Result := 0;

  if SecurityInformation and REQUIRE_READ_CONTROL <> 0 then
    Result := Result or READ_CONTROL;

  if SecurityInformation and REQUIRE_SYSTEM_SECURITY <> 0 then
    Result := Result or ACCESS_SYSTEM_SECURITY;
end;

function RtlxComputeWriteAccess(SecurityInformation: TSecurityInformation)
  : TAccessMask;
const
  REQUIRE_WRITE_DAC = DACL_SECURITY_INFORMATION or
    ATTRIBUTE_SECURITY_INFORMATION or BACKUP_SECURITY_INFORMATION or
    PROTECTED_DACL_SECURITY_INFORMATION or
    UNPROTECTED_DACL_SECURITY_INFORMATION;
  REQUIRE_WRITE_OWNER = OWNER_SECURITY_INFORMATION or GROUP_SECURITY_INFORMATION
    or LABEL_SECURITY_INFORMATION or BACKUP_SECURITY_INFORMATION;
  REQUIRE_SYSTEM_SECURITY = SACL_SECURITY_INFORMATION or
    SCOPE_SECURITY_INFORMATION or
    BACKUP_SECURITY_INFORMATION or PROTECTED_SACL_SECURITY_INFORMATION or
    UNPROTECTED_SACL_SECURITY_INFORMATION;
begin
  Result := 0;

  if SecurityInformation and REQUIRE_WRITE_DAC <> 0 then
    Result := Result or WRITE_DAC;

  if SecurityInformation and REQUIRE_WRITE_OWNER <> 0 then
    Result := Result or WRITE_OWNER;

  if SecurityInformation and REQUIRE_SYSTEM_SECURITY <> 0 then
    Result := Result or ACCESS_SYSTEM_SECURITY;
end;

end.
