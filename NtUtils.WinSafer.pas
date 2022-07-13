unit NtUtils.WinSafer;

{
  This module provides functions for restricting tokens via Safer API.
}

interface

uses
  Ntapi.ntseapi, Ntapi.WinSafer, NtUtils, NtUtils.Objects;

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
  [opt] GrowthMethod: TBufferGrowthMethod = nil
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
  [Access(TOKEN_DUPLICATE or TOKEN_QUERY)] hxExistingToken: IHandle;
  hLevel: TSaferHandle;
  MakeSanboxInert: Boolean = False
): TNtxStatus;

// Restricts a token unsing Safer API level identified by its IDs
function SafexComputeSaferTokenById(
  out hxNewToken: IHandle;
  [Access(TOKEN_DUPLICATE or TOKEN_QUERY)] const hxExistingToken: IHandle;
  ScopeId: TSaferScopeId;
  LevelId: TSaferLevelId;
  MakeSanboxInert: Boolean = False
): TNtxStatus;

implementation

uses
  NtUtils.Tokens, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TSaferAutoHandle = class(TCustomAutoHandle, ISaferHandle)
    procedure Release; override;
  end;

procedure TSaferAutoHandle.Release;
begin
  if FHandle <> 0 then
    SaferCloseLevel(FHandle);

  FHandle := 0;
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
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Required := 0;
    Result.Win32Result := SaferGetLevelInformation(hLevel, InfoClass,
      xMemory.Data, xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function SafexQueryNameLevel;
var
  xMemory: IWideChar;
begin
  Result := SafexQueryLevel(hLevel, SaferObjectFriendlyName, IMemory(xMemory),
    SizeOf(WideChar));

  if Result.IsSuccess then
    SetString(Name, xMemory.Data, xMemory.Size div SizeOf(WideChar) - 1);
end;

function SafexQueryDescriptionLevel;
var
  xMemory: IWideChar;
begin
  Result := SafexQueryLevel(hLevel, SaferObjectDescription, IMemory(xMemory),
    SizeOf(WideChar));

  if Result.IsSuccess then
    SetString(Description, xMemory.Data, xMemory.Size div SizeOf(WideChar) - 1);
end;

function SafexComputeSaferToken;
var
  hNewToken: THandle;
  Flags: TSaferComputeOptions;
begin
  // Add support for pseudo-handles on input
  Result := NtxExpandToken(hxExistingToken, TOKEN_DUPLICATE or TOKEN_QUERY);

  if not Result.IsSuccess then
    Exit;

  Flags := 0;
  if MakeSanboxInert then
    Flags := Flags or SAFER_TOKEN_MAKE_INERT;

  Result.Location := 'SaferComputeTokenFromLevel';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_DUPLICATE or TOKEN_QUERY);

  Result.Win32Result := SaferComputeTokenFromLevel(hLevel,
    hxExistingToken.Handle, hNewToken, Flags);

  if Result.IsSuccess then
    hxNewToken := Auto.CaptureHandle(hNewToken);
end;

function SafexComputeSaferTokenById;
var
  hxLevel: ISaferHandle;
begin
  Result := SafexOpenLevel(hxLevel, ScopeId, LevelId);

  if Result.IsSuccess then
    Result := SafexComputeSaferToken(hxNewToken, hxExistingToken,
      hxLevel.Handle, MakeSanboxInert);
end;

end.
