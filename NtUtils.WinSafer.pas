unit NtUtils.WinSafer;

interface

uses
  Winapi.WinSafer, NtUtils, NtUtils.Objects;

// Open a Safer level
function SafexOpenLevel(out hLevel: TSaferHandle; ScopeId: TSaferScopeId;
  LevelId: TSaferLevelId): TNtxStatus;

// Close a Safer level
procedure SafexCloseLevel(var hLevel: TSaferHandle);

// Query Safer level information
function SafexQueryInformationLevel(hLevel: TSaferHandle;
  InfoClass: TSaferObjectInfoClass; out Status: TNtxStatus;
  Returned: PCardinal = nil): Pointer;

// Query Safer level name
function SafexQueryNameLevel(hLevel: TSaferHandle; out Name: String)
  : TNtxStatus;

// Query Safer level description
function SafexQueryDescriptionLevel(hLevel: TSaferHandle;
  out Description: String): TNtxStatus;

// Restrict a token unsing Safer Api. Supports pseudo-handles
function SafexComputeSaferToken(out hxNewToken: IHandle; hExistingToken: THandle;
  hLevel: TSaferHandle; MakeSanboxInert: Boolean = False): TNtxStatus;
function SafexComputeSaferTokenById(out hxNewToken: IHandle;
  hExistingToken: THandle; ScopeId: TSaferScopeId;
  LevelId: TSaferLevelId; MakeSanboxInert: Boolean = False): TNtxStatus;

implementation

uses
  Ntapi.ntseapi, NtUtils.Tokens;

function SafexOpenLevel(out hLevel: TSaferHandle; ScopeId: TSaferScopeId;
  LevelId: TSaferLevelId): TNtxStatus;
begin
  Result.Location := 'SaferCreateLevel';
  Result.Win32Result := SaferCreateLevel(ScopeId, LevelId, SAFER_LEVEL_OPEN,
    hLevel);
end;

procedure SafexCloseLevel(var hLevel: TSaferHandle);
begin
  SaferCloseLevel(hLevel);
  hLevel := 0;
end;

function SafexQueryInformationLevel(hLevel: TSaferHandle;
  InfoClass: TSaferObjectInfoClass; out Status: TNtxStatus;
  Returned: PCardinal): Pointer;
var
  BufferSize, Required: Cardinal;
begin
  Status.Location := 'SaferGetLevelInformation';
  Status.LastCall.CallType := lcQuerySetCall;
  Status.LastCall.InfoClass := Cardinal(InfoClass);
  Status.LastCall.InfoClassType := TypeInfo(TSaferObjectInfoClass);

  BufferSize := 0;
  repeat
    Result := AllocMem(BufferSize);

    Required := 0;
    Status.Win32Result := SaferGetLevelInformation(hLevel, InfoClass, Result,
      BufferSize, Required);

    if not Status.IsSuccess then
    begin
      FreeMem(Result);
      Result := nil;
    end;

  until not NtxExpandBuffer(Status, BufferSize, Required);

  if Status.IsSuccess and Assigned(Returned) then
    Returned^ := BufferSize;
end;

function SafexQueryNameLevel(hLevel: TSaferHandle; out Name: String)
  : TNtxStatus;
var
  Buffer: PWideChar;
  Returned: Cardinal;
begin
  Buffer := SafexQueryInformationLevel(hLevel, SaferObjectFriendlyName, Result,
    @Returned);

  if Result.IsSuccess then
  begin
    // Exclude the ending #0
    if Returned > SizeOf(WideChar) then
      SetString(Name, Buffer, Returned div SizeOf(WideChar) - 1)
    else
      Name := '';
    FreeMem(Buffer);
  end;
end;

function SafexQueryDescriptionLevel(hLevel: TSaferHandle;
  out Description: String): TNtxStatus;
var
  Buffer: PWideChar;
  Returned: Cardinal;
begin
  Buffer := SafexQueryInformationLevel(hLevel, SaferObjectDescription, Result,
    @Returned);

  if Result.IsSuccess then
  begin
    // Exclude the ending #0
    if Returned > SizeOf(WideChar) then
      SetString(Description, Buffer, Returned div SizeOf(WideChar) - 1)
    else
      Description := '';
    FreeMem(Buffer);
  end;
end;

function SafexComputeSaferToken(out hxNewToken: IHandle; hExistingToken: THandle;
  hLevel: TSaferHandle; MakeSanboxInert: Boolean): TNtxStatus;
var
  hxExistingToken: IHandle;
  hNewToken: THandle;
  Flags: Cardinal;
begin
  // Manage pseudo-handles for input
  Result := NtxExpandPseudoToken(hxExistingToken, hExistingToken,
    TOKEN_DUPLICATE or TOKEN_QUERY);

  if not Result.IsSuccess then
    Exit;

  Flags := 0;
  if MakeSanboxInert then
    Flags := Flags or SAFER_TOKEN_MAKE_INERT;

  Result.Location := 'SaferComputeTokenFromLevel';
  Result.LastCall.Expects(TOKEN_DUPLICATE or TOKEN_QUERY, @TokenAccessType);

  Result.Win32Result := SaferComputeTokenFromLevel(hLevel, hExistingToken,
    hNewToken, Flags, nil);

  if Result.IsSuccess then
    hxNewToken := TAutoHandle.Capture(hNewToken);

  SaferCloseLevel(hLevel);
end;

function SafexComputeSaferTokenById(out hxNewToken: IHandle;
  hExistingToken: THandle; ScopeId: TSaferScopeId;
  LevelId: TSaferLevelId; MakeSanboxInert: Boolean = False): TNtxStatus;
var
  hLevel: TSaferHandle;
begin
  Result := SafexOpenLevel(hLevel, ScopeId, LevelId);

  if Result.IsSuccess then
  begin
    Result := SafexComputeSaferToken(hxNewToken, hExistingToken, hLevel,
      MakeSanboxInert);

    SafexCloseLevel(hLevel);
  end;
end;

end.
