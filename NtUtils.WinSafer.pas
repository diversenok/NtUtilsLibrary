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
function SafexQueryLevel(hLevel: TSaferHandle; InfoClass: TSaferObjectInfoClass;
  out xMemory: IMemory; InitialBuffer: Cardinal = 0; GrowthMethod:
  TBufferGrowthMethod = nil): TNtxStatus;

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

function SafexQueryLevel(hLevel: TSaferHandle; InfoClass:
  TSaferObjectInfoClass; out xMemory: IMemory; InitialBuffer: Cardinal = 0;
  GrowthMethod: TBufferGrowthMethod = nil): TNtxStatus;
var
  Required: Cardinal;
begin
  Result.Location := 'SaferGetLevelInformation';
  Result.LastCall.AttachInfoClass(InfoClass);

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Win32Result := SaferGetLevelInformation(hLevel, InfoClass,
      xMemory.Data, xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function SafexQueryNameLevel(hLevel: TSaferHandle; out Name: String)
  : TNtxStatus;
var
  xMemory: IMemory;
begin
  Result := SafexQueryLevel(hLevel, SaferObjectFriendlyName, xMemory,
    SizeOf(WideChar));

  if Result.IsSuccess then
    SetString(Name, PWideChar(xMemory.Data),
      xMemory.Size div SizeOf(WideChar) - 1);
end;

function SafexQueryDescriptionLevel(hLevel: TSaferHandle;
  out Description: String): TNtxStatus;
var
  xMemory: IMemory;
begin
  Result := SafexQueryLevel(hLevel, SaferObjectDescription, xMemory,
    SizeOf(WideChar));

  if Result.IsSuccess then
    SetString(Description, PWideChar(xMemory.Data),
      xMemory.Size div SizeOf(WideChar) - 1);
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
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_DUPLICATE or TOKEN_QUERY);

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
