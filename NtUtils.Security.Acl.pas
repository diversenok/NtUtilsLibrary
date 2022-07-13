unit NtUtils.Security.Acl;

{
  This module adds support for Access Control List construction, modification,
  and canonicalization.
}

interface

uses
  Ntapi.WinNt, NtUtils, DelphiUtils.AutoObjects;

type
  TAceData = record
    AceType: TAceType;
    AceFlags: TAceFlags;
    Mask: TAccessMask;
    SID: ISid;
    ObjectFlags: TObjectAceFlags; // Object ACEs only
    ObjectType: TGuid;            // Object ACEs only
    InheritedObjctType: TGuid;    // Object ACEs only
    ExtraData: IMemory;           // Depending on the ACE type

    class function New(
      AceType: TAceType;
      AceFlags: TAceFlags;
      Mask: TAccessMask;
      const SID: ISid
    ): TAceData; static;
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

// Retrieve size information of an ACL
function RtlxSizeAcl(
  [in, opt] Acl: PAcl
): TAclSizeInformation;

{ Creation }

// Create a new ACL
function RtlxCreateAcl(
  out Acl: IAcl;
  Size: Cardinal = 256
): TNtxStatus;

// Create a copy of an ACL
function RtlxCopyAcl(
  out NewAcl: IAcl;
  [in] SourceAcl: PAcl
): TNtxStatus;

// Relocate the ACL if necessary to satisfy the size requirements
function RtlxEnsureFreeBytesAcl(
  var Acl: IAcl;
  RequiredFreeBytes: Cardinal
): TNtxStatus;

// Append all ACEs from one ACL to another
function RtlxAppendAcl(
  var TargetAcl: IAcl;
  [in] SourceAcl: PAcl
): TNtxStatus;

// Create an ACL from a collection of ACEs
function RtlxBuildAcl(
  out Acl: IAcl;
  const AceData: TArray<TAceData>
): TNtxStatus;

{ Operations }

// Export all ACEs from an ACL
function RtlxDumpAcl(
  [in] Acl: PAcl;
  out AceData: TArray<TAceData>
): TNtxStatus;

// Map a generic mapping for each ACE in the ACL
function RtlxMapGenericMaskAcl(
  [in, out] Acl: PAcl;
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
  var Acl: IAcl
): TNtxStatus;

{ ACE manipulation }

// Allocate an ACE from a prototype
function RtlxAllocateAce(
  const AceData: TAceData;
  out Buffer: IMemory<PAce>
): TNtxStatus;

// Save an ACE into a prototype
function RtlxCaptureAce(
  [in] Buffer: PAce;
  out AceData: TAceData
): TNtxStatus;

// Insert an ACE preserving canonical order of an ACL
function RtlxAddAce(
  [in, out] Acl: IAcl;
  const Ace: TAceData
): TNtxStatus;

// Insert an ACE into a particular location
function RtlxInsertAce(
  [in, out] Acl: IAcl;
  const Ace: TAceData;
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
  out AceData: TAceData
): TNtxStatus;

implementation

uses
  Ntapi.ntrtl, Ntapi.ntstatus, NtUtils.Security.Sid, NtUtils.Errors;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ ACL information }

function RtlxSizeAcl;
begin
  if not Assigned(Acl) or not RtlQueryInformationAcl(Acl, @Result,
    SizeOf(Result), AclSizeInformation).IsSuccess then
    Result := Default(TAclSizeInformation);
end;

{ ACL creation }

function RtlxCreateAcl;
begin
  // Align the size up to the next DWORD
  Size := (Size + SizeOf(Cardinal) - 1) and not (SizeOf(Cardinal) - 1);

  if Size < SizeOf(TAcl) then
    Size := SizeOf(TAcl)
  else if Size > MAX_ACL_SIZE then
    Size := MAX_ACL_SIZE;

  IMemory(Acl) := Auto.AllocateDynamic(Size);

  Result.Location := 'RtlCreateAcl';
  Result.Status := RtlCreateAcl(Acl.Data, Acl.Size, ACL_REVISION);
end;

function AddExtraSpace(Size: Cardinal): Cardinal;
begin
  // + 12.5% + 256 B
  Result := Size + Size shr 3 + 256;
end;

function RtlxCopyAcl;
begin
  // Create a new ACL
  Result := RtlxCreateAcl(NewAcl, AddExtraSpace(RtlxSizeAcl(
    SourceAcl).AclBytesInUse));

  if not Result.IsSuccess then
    Exit;

  // Copy all ACEs from the source
  Result := RtlxAppendAcl(NewAcl, SourceAcl);
end;

function RtlxEnsureFreeBytesAcl;
var
  SizeInfo: TAclSizeInformation;
  RequiredSize: Cardinal;
  ExpandedAcl: IAcl;
begin
  SizeInfo := RtlxSizeAcl(Acl.Data);
  RequiredSize := SizeInfo.AclBytesInUse + RequiredFreeBytes;

  // Can't grow enough
  if RequiredSize > MAX_ACL_SIZE then
  begin
    Result.Location := 'RtlxEnsureSizeAcl';
    Result.Status := STATUS_NO_MEMORY;
    Exit;
  end;

  // Reserve some extra space
  RequiredSize := AddExtraSpace(RequiredSize);

  // Already enough?
  if RequiredSize <= SizeInfo.AclBytesTotal then
  begin
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Allocate a new ACL
  Result := RtlxCreateAcl(ExpandedAcl, RequiredSize);

  if not Result.IsSuccess then
    Exit;

  // Copy existing ACEs
  Result := RtlxAppendAcl(ExpandedAcl, Acl.Data);

  // Swap the reference
  if Result.IsSuccess then
    Acl := ExpandedAcl;
end;

function RtlxAppendAcl;
var
  SourceSize, TargetSize: TAclSizeInformation;
  FirstNewAce: PAce;
begin
  SourceSize := RtlxSizeAcl(SourceAcl);
  TargetSize := RtlxSizeAcl(TargetAcl.Data);

  if SourceSize.AceCount = 0 then
  begin
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Make sure the new ACEs fit
  if TargetSize.AclBytesFree < SourceSize.AclBytesInUse - SizeOf(TAcl) then
  begin
    Result := RtlxEnsureFreeBytesAcl(TargetAcl, SourceSize.AclBytesInUse -
      SizeOf(TAcl));

    if not Result.IsSuccess then
      Exit;
  end;

  // Copy ACEs
  Result.Location := 'RtlGetAce';
  Result.Status := RtlGetAce(SourceAcl, 0, FirstNewAce);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlAddAce';
  Result.Status := RtlAddAce(TargetAcl.Data, SourceAcl.AclRevision, -1,
    FirstNewAce, SourceSize.AclBytesInUse - SizeOf(TAcl));
end;

function RtlxBuildAcl;
var
  AceBuffers: TArray<IMemory<PAce>>;
  RequiredSize: Cardinal;
  i: Integer;
begin
  RequiredSize := SizeOf(TAcl);
  SetLength(AceBuffers, Length(AceData));

  // Allocate all ACEs and compute the required ACL size
  for i := 0 to High(AceBuffers) do
  begin
    Result := RtlxAllocateAce(AceData[i], AceBuffers[i]);

    if not Result.IsSuccess then
      Exit;

    Inc(RequiredSize, AceBuffers[i].Size);
  end;

  Result := RtlxCreateAcl(Acl, RequiredSize);

  if not Result.IsSuccess then
    Exit;

  for i := 0 to High(AceBuffers) do
  begin
    Result.Location := 'RtlAddAce';
    Result.Status := RtlAddAce(Acl.Data, AceBuffers[i].Data.Header.Revision, -1,
      AceBuffers[i].Data, AceBuffers[i].Size);

    if not Result.IsSuccess then
      Exit;
  end;
end;

{ ACL operations }

function RtlxDumpAcl;
var
  i: Integer;
  Ace: PAce;
begin
  if not Assigned(Acl) then
  begin
    AceData := nil;
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  SetLength(AceData, RtlxSizeAcl(Acl).AceCount);

  for i := 0 to High(AceData) do
  begin
    Result.Location := 'RtlGetAce';
    Result.Status := RtlGetAce(Acl, i, Ace);

    if not Result.IsSuccess then
      Exit;

    Result := RtlxCaptureAce(Ace, AceData[i]);
  end;
end;

function RtlxMapGenericMaskAcl;
var
  i: Integer;
  Ace: PAce;
begin
  for i := 0 to Pred(RtlxSizeAcl(Acl).AceCount) do
  begin
    Result.Location := 'RtlGetAce';
    Result.Status := RtlGetAce(Acl, i, Ace);

    if not Result.IsSuccess then
      Exit;

    RtlMapGenericMask(Ace.NonObjectAce.Mask, GenericMapping);
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
  else
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
  AceRef: PAce;
  LastCategory, CurrentCategory: TAceCategory;
  i: Integer;
begin
  Result.Status := STATUS_SUCCESS;

  // The elements of the enumeration follow the required order
  LastCategory := Low(TAceCategory);

  for i := 0 to Pred(RtlxSizeAcl(Acl).AceCount) do
  begin
    Result.Location := 'RtlGetAce';
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
  AceRef: PAce;
  CurrentCategory: TAceCategory;
  i: Integer;
begin
  // Insert as the last by default
  Result := -1;

  for i := 0 to Pred(RtlxSizeAcl(Acl).AceCount) do
  begin
    if not RtlGetAce(Acl, i, AceRef).IsSuccess then
      Exit;

    // Determine which category the ACE belongs to
    CurrentCategory := RtlxGetCategoryAce(AceRef.Header.AceType,
      AceRef.Header.AceFlags);

    // Skip ACEs that do not require ordering
    if CurrentCategory = acUnspecified then
      Continue;

    // Insert right before the next category
    if CurrentCategory > Category then
      Exit(i);
  end;
end;

function RtlxCanonicalizeAcl;
var
  Ace: PAce;
  Aces: array [TAceCategory] of TArray<PAce>;
  i: Integer;
  Category: TAceCategory;
  NewAcl: IAcl;
begin
  // Each category is empty by default
  for Category := Low(TAceCategory) to High(TAceCategory) do
    Aces[Category] := nil;

  // Save each ACE under the corresponding category
  for i := 0 to Pred(RtlxSizeAcl(Acl.Data).AceCount) do
  begin
    Result.Location := 'RtlGetAce';
    Result.Status := RtlGetAce(Acl.Data, i, Ace);

    if not Result.IsSuccess then
      Exit;

    Category := RtlxGetCategoryAce(Ace.Header.AceType, Ace.Header.AceFlags);
    SetLength(Aces[Category], Length(Aces[Category]) + 1);
    Aces[Category][High(Aces[Category])] := Ace;
  end;

  // Allocate a new ACL
  Result := RtlxCreateAcl(NewAcl, AddExtraSpace(RtlxSizeAcl(
    Acl.Data).AclBytesInUse));

  // Add ACEs category-by-category preserving their order within each
  for Category := Low(TAceCategory) to High(TAceCategory) do
    for i := 0 to High(Aces[Category]) do
    begin
      Result.Location := 'RtlAddAce';
      Result.Status := RtlAddAce(NewAcl.Data, Aces[Category][i].Header.Revision,
        -1, Aces[Category][i], Aces[Category][i].Header.AceSize);

      if not Result.IsSuccess then
        Exit;
    end;

  // Swap the reference
  Acl := NewAcl;
end;

{ ACE manipulation }

class function TAceData.New;
begin
  Result := Default(TAceData);
  Result.AceType := AceType;
  Result.AceFlags := AceFlags;
  Result.Mask := Mask;
  Result.SID := SID;
end;

function RtlxAllocateAce;
var
  Size: Cardinal;
begin
  Result.Status := STATUS_SUCCESS;

  if AceData.AceType in NonObjectAces then
  begin
    // Non-object ACE
    Size := SizeOf(TNonObjectAce) - SizeOf(Cardinal) +
      RtlLengthSid(AceData.SID.Data);

    if Assigned(AceData.ExtraData) then
      Inc(Size, AceData.ExtraData.Size);

    IMemory(Buffer) := Auto.AllocateDynamic(Size);

    Buffer.Data.Header.AceType := AceData.AceType;
    Buffer.Data.Header.AceFlags := AceData.AceFlags;
    Buffer.Data.Header.AceSize := Size;
    Buffer.Data.NonObjectAce.Mask := AceData.Mask;

    Move(AceData.SID.Data^, Buffer.Data.NonObjectAce.Sid^,
      RtlLengthSid(AceData.SID.Data));

    if Assigned(AceData.ExtraData) then
      Move(AceData.ExtraData.Data^, Buffer.Data.NonObjectAce.ExtraData^,
        AceData.ExtraData.Size);
  end
  else if AceData.AceType in ObjectAces then
  begin
    // Object ACE
    Size := SizeOf(TObjectAce) - SizeOf(Cardinal) +
      RtlLengthSid(AceData.SID.Data);

    if Assigned(AceData.ExtraData) then
      Inc(Size, AceData.ExtraData.Size);

    IMemory(Buffer) := Auto.AllocateDynamic(Size);

    Buffer.Data.Header.AceType := AceData.AceType;
    Buffer.Data.Header.AceFlags := AceData.AceFlags;
    Buffer.Data.Header.AceSize := Size;
    Buffer.Data.ObjectAce.Mask := AceData.Mask;
    Buffer.Data.ObjectAce.Flags := AceData.ObjectFlags;
    Buffer.Data.ObjectAce.ObjectType := AceData.ObjectType;
    Buffer.Data.ObjectAce.InheritedObjectType := AceData.InheritedObjctType;

    Move(AceData.SID.Data^, Buffer.Data.ObjectAce.Sid^,
      RtlLengthSid(AceData.SID.Data));

    if Assigned(AceData.ExtraData) then
      Move(AceData.ExtraData.Data^, Buffer.Data.ObjectAce.ExtraData^,
        AceData.ExtraData.Size);
  end
  else
  begin
    Result.Location := 'RtlxAllocateAce';
    Result.Status := STATUS_UNKNOWN_REVISION;
  end;
end;

function RtlxCaptureAce;
begin
  Result.Status := STATUS_SUCCESS;
  AceData.AceType := Buffer.Header.AceType;
  AceData.AceFlags := Buffer.Header.AceFlags;

  if AceData.AceType in NonObjectAces then
  begin
    // Non-object ACE
    AceData.Mask := Buffer.NonObjectAce.Mask;
    Result := RtlxCopySid(Buffer.NonObjectAce.Sid, AceData.Sid);

    if Buffer.NonObjectAce.ExtraDataSize > 0 then
      AceData.ExtraData := Auto.CopyDynamic(Buffer.NonObjectAce.ExtraData,
        Buffer.NonObjectAce.ExtraDataSize);
  end
  else if AceData.AceType in ObjectAces then
  begin
    // Object ACE
    AceData.Mask := Buffer.ObjectAce.Mask;
    AceData.ObjectFlags := Buffer.ObjectAce.Flags;
    AceData.ObjectType := Buffer.ObjectAce.ObjectType;
    AceData.InheritedObjctType := Buffer.ObjectAce.InheritedObjectType;
    Result := RtlxCopySid(Buffer.ObjectAce.Sid, AceData.Sid);

    if Buffer.ObjectAce.ExtraDataSize > 0 then
      AceData.ExtraData := Auto.CopyDynamic(Buffer.ObjectAce.ExtraData,
        Buffer.ObjectAce.ExtraDataSize);
  end
  else
  begin
    Result.Location := 'RtlxCaptureAce';
    Result.Status := STATUS_UNKNOWN_REVISION;
  end;
end;

function RtlxAddAce;
begin
  Result := RtlxInsertAce(Acl, Ace, RtlxChooseIndexAce(Acl.Data,
    RtlxGetCategoryAce(Ace.AceType, Ace.AceFlags)));
end;

function RtlxInsertAce;
var
  AceBuffer: IMemory<PAce>;
begin
  Result := RtlxAllocateAce(Ace, AceBuffer);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxEnsureFreeBytesAcl(Acl, AceBuffer.Size);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlAddAce';
  Result.Status := RtlAddAce(Acl.Data, AceBuffer.Data.Header.Revision,
    Index, AceBuffer.Data, AceBuffer.Size);
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

  if Result.IsSuccess then
    Result := RtlxCaptureAce(AceRef, AceData);
end;

end.
