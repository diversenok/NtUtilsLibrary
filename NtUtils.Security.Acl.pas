unit NtUtils.Security.Acl;

interface

uses
  Winapi.WinNt, NtUtils.Security.Sid, NtUtils, DelphiUtils.AutoObject;

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

end.
