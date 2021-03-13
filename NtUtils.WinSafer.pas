unit NtUtils.WinSafer;

{
  This module provides functions for restricting tokens via Safer API.
}

interface

uses
  Winapi.WinSafer, NtUtils, NtUtils.Objects;

type
  ISaferHandle = IHandle;

// Open a Safer level
function SafexOpenLevel(
  out hxLevel: ISaferHandle;
  ScopeId: TSaferScopeId;
  LevelId: TSaferLevelId
): TNtxStatus;

// Query Safer level information
function SafexQueryLevel(
  hLevel: TSaferHandle;
  InfoClass: TSaferObjectInfoClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Query Safer level name
function SafexQueryNameLevel(
  hLevel: TSaferHandle;
  out Name: String
): TNtxStatus;

// Query Safer level description
function SafexQueryDescriptionLevel(
  hLevel: TSaferHandle;
  out Description: String
): TNtxStatus;

// Restricts a token unsing Safer API level
function SafexComputeSaferToken(
  out hxNewToken: IHandle;
  hExistingToken: THandle;
  hLevel: TSaferHandle;
  MakeSanboxInert: Boolean = False
): TNtxStatus;

// Restricts a token unsing Safer API level identified by its IDs
function SafexComputeSaferTokenById(
  out hxNewToken: IHandle;
  hExistingToken: THandle;
  ScopeId: TSaferScopeId;
  LevelId: TSaferLevelId;
  MakeSanboxInert: Boolean = False
): TNtxStatus;

implementation

uses
  Ntapi.ntseapi, NtUtils.Tokens, DelphiUtils.AutoObject;

type
  TSaferAutoHandle = class(TCustomAutoHandle, ISaferHandle)
    procedure Release; override;
  end;

procedure TSaferAutoHandle.Release;
begin
  SaferCloseLevel(FHandle);
  inherited;
end;

function SafexOpenLevel;
var
  hLevel: TSaferHandle;
begin
  Result.Location := 'SaferCreateLevel';
  Result.Win32Result := SaferCreateLevel(ScopeId, LevelId, SAFER_LEVEL_OPEN,
    hLevel);

  if Result.IsSuccess then
    hxLevel := TSaferAutoHandle.Capture(hLevel);
end;

function SafexQueryLevel;
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

function SafexQueryNameLevel;
var
  xMemory: IMemory<PWideChar>;
begin
  Result := SafexQueryLevel(hLevel, SaferObjectFriendlyName, IMemory(xMemory),
    SizeOf(WideChar));

  if Result.IsSuccess then
    SetString(Name, xMemory.Data, xMemory.Size div SizeOf(WideChar) - 1);
end;

function SafexQueryDescriptionLevel;
var
  xMemory: IMemory<PWideChar>;
begin
  Result := SafexQueryLevel(hLevel, SaferObjectDescription, IMemory(xMemory),
    SizeOf(WideChar));

  if Result.IsSuccess then
    SetString(Description, xMemory.Data, xMemory.Size div SizeOf(WideChar) - 1);
end;

function SafexComputeSaferToken;
var
  hxExistingToken: IHandle;
  hNewToken: THandle;
  Flags: TSaferComputeOptions;
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

function SafexComputeSaferTokenById;
var
  hxLevel: ISaferHandle;
begin
  Result := SafexOpenLevel(hxLevel, ScopeId, LevelId);

  if Result.IsSuccess then
    Result := SafexComputeSaferToken(hxNewToken, hExistingToken, hxLevel.Handle,
      MakeSanboxInert);
end;

end.
