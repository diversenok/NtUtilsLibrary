unit NtUtils.Security.Acl;

{
  This module adds support for Access Control List construction, modification,
  and canonicalization.
}

interface

uses
  Winapi.WinNt, NtUtils, DelphiUtils.AutoObject;

type
  TAce = record
    AceType: TAceType;
    AceFlags: TAceFlags;
    Mask: TAccessMask;
    SID: ISid;
    function Size: Cardinal;
    function Allocate: IMemory<PAce>;
  end;

  // Define the canonical order
  TAceCategory = (
    acExplicitDenyObject,
    acExplicitDenyChild,
    acExplicitAllowObject,
    acExplicitAllowChild,
    acImplicit,
    acUnspecified // does not require ordering
  );

{ Information }

// Query ACL size information
function RtlxQuerySizeAcl(
  [in] Acl: PAcl;
  out SizeInfo: TAclSizeInformation
): TNtxStatus;

{ ACL manipulation }

// Create a new ACL
function RtlxCreateAcl(
  out Acl: IAcl;
  Size: Cardinal = 256
): TNtxStatus;

// Relocate the ACL if necessary to satisfy the size requirements
function RtlxExpandAcl(
  [in, out] Acl: IAcl;
  NewSize: Cardinal
): TNtxStatus;

// Append all ACEs from one ACL to another
function RtlxAppendAcl(
  [in, out] TargetAcl: IAcl;
  [in] SourceAcl: PAcl
): TNtxStatus;

// Create a copy of an ACL
function RtlxCopyAcl(
  [in] SourceAcl: PAcl;
  out NewAcl: IAcl
): TNtxStatus;

// Map a generic mapping for each ACE in the ACL
function RtlxMapGenericMaskAcl(
  const Acl: IAcl;
  const GenericMapping: TGenericMapping
): TNtxStatus;

{ Ordering }

// Determine which canonical categrory an ACE belongs to
function RtlxGetCategoryAce(
  AceType: TAceType;
  AceFlags: TAceFlags
): TAceCategory;

// Check if an ACL matches requirements for being canonical
function RtlxIsCanonicalAcl(
  [in] Acl: PAcl;
  out IsCanonical: Boolean
): TNtxStatus;

// Determine appropriate location for insertion of an ACE
function RtlxChooseIndexAce(
  [in] Acl: PAcl;
  Category: TAceCategory
): Integer;

// Reorder ACEs to make a canonical ACL
function RtlxCanonicalizeAcl(
  [in, out] Acl: IAcl
): TNtxStatus;

{ ACE manipulation }

// Insert an ACE preserving canonical order of an ACL
function RtlxAddAce(
  [in, out] Acl: IAcl;
  const Ace: TAce
): TNtxStatus;

// Insert an ACE into a particular location
function RtlxInsertAce(
  [in, out] Acl: IAcl;
  const Ace: TAce;
  Index: Integer
): TNtxStatus;

// Remove an ACE by index
function RtlxDeleteAce(
  [in] Acl: PAcl;
  Index: Integer
): TNtxStatus;

// Obtain a copy of an ACE
function RtlxGetAce(
  [in] Acl: PAcl;
  Index: Integer;
  out Ace: TAce
): TNtxStatus;

{ Helper functions }

// Craft a DACL that denies everything
function RtlxAllocateDenyingDacl(
  out Dacl: IAcl
): TNtxStatus;

// Craft a security descriptor that denies everything
function RtlxAllocateDenyingSd: ISecDesc;

implementation

uses
  Ntapi.ntrtl, Ntapi.ntstatus, Ntapi.ntdef, NtUtils.Security.Sid,
  NtUtils.Security;

{ TAce }

function TAce.Allocate;
begin
  IMemory(Result) := TAutoMemory.Allocate(Size);
  Result.Data.Header.AceType := AceType;
  Result.Data.Header.AceFlags := AceFlags;
  Result.Data.Header.AceSize := Size;
  Result.Data.Mask := Mask;
  Move(Sid.Data^, Result.Data.Sid^, RtlLengthSid(Sid.Data));
end;

function TAce.Size;
begin
  Result := SizeOf(TAce_Internal) - SizeOf(Cardinal) + RtlLengthSid(Sid.Data);
end;

{ Information }

function RtlxQuerySizeAcl;
begin
  Result.Location := 'RtlQueryInformationAcl';
  Result.LastCall.AttachInfoClass(AclSizeInformation);
  Result.Status := RtlQueryInformationAcl(Acl, SizeInfo);
end;

{ ACL manipulation }

function RtlxCreateAcl;
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

function RtlxExpandAcl;
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

function RtlxAppendAcl;
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

function RtlxCopyAcl;
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

function RtlxMapGenericMaskAcl;
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

{ Ordering }

function RtlxGetCategoryAce;
begin
  // Only DACL-specific ACEs require ordering
  if not (AceType in AccessAllowedAces + AccessDeniedAces) then
    Exit(acUnspecified);

  // Implicit (inherited) ACEs always come after expilcit ACEs
  if BitTest(AceFlags and INHERITED_ACE) then
    Exit(acImplicit);

  // Explicit deny ACEs come before explicit allow ACEs
  if AceType in AccessDeniedAces then
  begin
    // ACEs on the object come before ACEs on a child or property
    if BitTest(AceFlags and INHERIT_ONLY_ACE) then
      Result := acExplicitDenyChild
    else
      Result := acExplicitDenyObject;
  end
  else // AceType in AccessDeniedAces
  begin
    // ACEs on the object come before ACEs on a child or property
    if BitTest(AceFlags and INHERIT_ONLY_ACE) then
      Result := acExplicitAllowChild
    else
      Result := acExplicitAllowObject;
  end;
end;

function RtlxIsCanonicalAcl;
var
  SizeInfo: TAclSizeInformation;
  AceRef: PAce;
  LastCategory, CurrentCategory: TAceCategory;
  i: Integer;
begin
  Result := RtlxQuerySizeAcl(Acl, SizeInfo);

  if not Result.IsSuccess then
    Exit;

  // The elements of the enumeration follow the required order
  LastCategory := Low(TAceCategory);

  Result.Location := 'RtlGetAce';

  for i := 0 to Pred(SizeInfo.AceCount) do
  begin
    Result.Status := RtlGetAce(Acl, i, AceRef);

    if not Result.IsSuccess then
      Exit;

    // Determine which category the ACE belongs to
    CurrentCategory := RtlxGetCategoryAce(AceRef.Header.AceType,
      AceRef.Header.AceFlags);

    // Skip ACEs that do not require ordering
    if CurrentCategory = acUnspecified then
      Continue;

    // Categories should always grow
    if not (CurrentCategory >= LastCategory) then
    begin
      IsCanonical := False;
      Exit;
    end;

    LastCategory := CurrentCategory;
  end;

  IsCanonical := True;
end;

function RtlxChooseIndexAce;
var
  SizeInfo: TAclSizeInformation;
  AceRef: PAce;
  CurrentCategory: TAceCategory;
  i: Integer;
begin
  // Insert as the last by default
  Result := -1;

  if not RtlxQuerySizeAcl(Acl, SizeInfo).IsSuccess then
    Exit;

  for i := 0 to Pred(SizeInfo.AceCount) do
  begin
    if not NT_SUCCESS(RtlGetAce(Acl, i, AceRef)) then
      Exit;

    // Determine which category the ACE belongs to
    CurrentCategory := RtlxGetCategoryAce(AceRef.Header.AceType,
      AceRef.Header.AceFlags);

    // Skip ACEs that do not require ordering
    if CurrentCategory = acUnspecified then
      Continue;

    // Insert right before hitting the next category
    if CurrentCategory > Category then
      Exit(i);
  end;
end;

function RtlxCanonicalizeAcl;
var
  SizeInfo: TAclSizeInformation;
  Categories: array of TAceCategory;
  AceRef: PAce;
  i: Integer;
  c: TAceCategory;
  NewAcl: IAcl;
begin
  // We need to realocate the memory
  if not (IUnknown(Acl) is TAutoMemory) then
  begin
    Result.Location := 'RtlxCanonicalizeAcl';
    Result.Status := STATUS_NOT_SUPPORTED;
    Exit;
  end;

  // Determine the amount of ACEs and requried memory
  Result := RtlxQuerySizeAcl(Acl.Data, SizeInfo);

  if not Result.IsSuccess then
    Exit;

  // Allocate a buffer for reordering
  Result := RtlxCreateAcl(NewAcl, SizeInfo.AclBytesTotal);

  Result.Location := 'RtlGetAce';
  SetLength(Categories, SizeInfo.AceCount);

  for i := 0 to High(Categories) do
  begin
    Result.Status := RtlGetAce(Acl.Data, i, AceRef);

    if not Result.IsSuccess then
      Exit;

    // Save which category each ACE belongs to
    Categories[i] := RtlxGetCategoryAce(AceRef.Header.AceType,
      AceRef.Header.AceFlags);
  end;

  // Add ACEs category-by-category preserving their order within each
  for c := Low(TAceCategory) to High(TAceCategory) do
    for i := 0 to High(Categories) do
      if Categories[i] = c then
      begin
        Result.Location := 'RtlGetAce';
        Result.Status := RtlGetAce(Acl.Data, i, AceRef);

        if not Result.IsSuccess then
          Exit;

        Result.Location := 'RtlAddAce';
        Result.Status := RtlAddAce(NewAcl.Data, ACL_REVISION, -1, AceRef,
          AceRef.Header.AceSize);

        if not Result.IsSuccess then
          Exit;
      end;

  // Make the current ACL point to the new one
  TAutoMemory(Acl).SwapWith(TAutoMemory(NewAcl));
end;

{ ACE manipulation }

function RtlxAddAce;
begin
  Result := RtlxInsertAce(Acl, Ace, RtlxChooseIndexAce(Acl.Data,
    RtlxGetCategoryAce(Ace.AceType, Ace.AceFlags)));
end;

function RtlxInsertAce;
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

function RtlxDeleteAce;
begin
  Result.Location := 'RtlDeleteAce';
  Result.Status := RtlDeleteAce(Acl, Index);
end;

function RtlxGetAce;
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

{ Helper functions }

function RtlxAllocateDenyingDacl;
var
  Ace: TAce;
begin
  Ace.AceType := ACCESS_DENIED_ACE_TYPE;
  Ace.AceFlags := 0;
  Ace.Mask := GENERIC_ALL;

  Result := RtlxNewSid(Ace.SID, SECURITY_CREATOR_SID_AUTHORITY,
    [SECURITY_CREATOR_OWNER_RIGHTS_RID]);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxCreateAcl(Dacl, Ace.Size);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxAddAce(Dacl, Ace);
end;

function RtlxAllocateDenyingSd;
var
  Dacl: IAcl;
begin
  if not RtlxAllocateDenyingDacl(Dacl).IsSuccess or not RtlxAllocateSD(
    TNtsecDescriptor.Create(SE_DACL_PRESENT, Dacl), Result).IsSuccess then
    Result := nil;
end;

end.
