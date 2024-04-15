unit NtUtils.Environment;

{
  This module provides operations on blocks of environment variables.
}

interface

uses
  Ntapi.WinNt, NtUtils;

type
  TEnvVariable = record
    Name, Value: String;
  end;

// Reference the current environment
function RtlxCurrentEnvironment: IEnvironment;

// Capture an environment
function RtlxCaptureEnvironment(
  [in] HeapBuffer: PEnvironment
): IEnvironment;

// Inherit or create an empty environment
function RtlxCreateEnvironment(
  out Env: IEnvironment;
  CloneCurrent: Boolean
): TNtxStatus;

// Determine is an environment is set as current
function RtlxIsCurrentEnvironment(
  const Env: IEnvironment
): Boolean;

// Swap the current environment with the new one
function RtlxSwapCurrentEnvironment(
  const Env: IEnvironment;
  out OldEnv: IEnvironment
): TNtxStatus;

// Set this environment as current
function RtlxSetCurrentEnvironment(
  const Env: IEnvironment
): TNtxStatus;

// Expand environmental variables in a string
function RtlxExpandString(
  const Env: IEnvironment;
  const Source: String;
  out Expanded: String
): TNtxStatus;

// Expand environmental variables in a string via a var parameter
function RtlxExpandStringVar(
  const Env: IEnvironment;
  var S: String
): TNtxStatus;

// Try to expand environmental variables in a string
function RtlxTryExpandString(
  const Env: IEnvironment;
  const Str: String
): String;

// Enumerate all names and values present in an environment
function RtlxEnumerateEnvironmemt(
  const Env: IEnvironment
): TArray<TEnvVariable>;

// Query a value of a environment variable
function RtlxQueryVariableEnvironment(
  const Env: IEnvironment;
  const Name: String;
  out Value: String
): TNtxStatus;

// Try to query an environment variable
function RtlxTryQueryVariableEnvironment(
  const Env: IEnvironment;
  const Name: String
): String;

// Add or modify an environment variable
function RtlxSetVariableEnvironment(
  const Env: IEnvironment;
  const Name: String;
  const Value: String
): TNtxStatus;

// Remove an environment variable
function RtlxDeleteVariableEnvironment(
  const Env: IEnvironment;
  const Name: String
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntrtl, Ntapi.ntstatus, Ntapi.ntpebteb,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

const
  CURRENT_ENVIRONMENT = PEnvironment(nil);

type
  TAutoEnvironment = class (TCustomAutoReleasable, IEnvironment,
    IAutoPointer<PEnvironment>, IAutoReleasable)
  protected
    FAddress: PEnvironment; // can be nil (aka., the current environment)
    procedure Release; override;
  public
    constructor Capture(Address: PEnvironment);
    function GetData: PEnvironment;
    function GetSize: NativeUInt;
    function GetRegion: TMemory;
    function Offset(Bytes: NativeUInt): Pointer;
  end;

{ TAutoEnvironment }

constructor TAutoEnvironment.Capture;
begin
  FAddress := Address;
end;

procedure TAutoEnvironment.Release;
begin
  if FAddress <> CURRENT_ENVIRONMENT then
    RtlDestroyEnvironment(FAddress);

  FAddress := nil;
  inherited;
end;

function TAutoEnvironment.GetData;
begin
  // Always return a valid non-nil pointer

  if FAddress = CURRENT_ENVIRONMENT then
    Result := RtlGetCurrentPeb.ProcessParameters.Environment
  else
    Result := FAddress;
end;

function TAutoEnvironment.GetRegion;
begin
  Result.Address := GetData;
  Result.Size := GetSize;
end;

function TAutoEnvironment.GetSize;
begin
  // This is the same way as RtlSetEnvironmentVariable determines the size.
  // Make sure to use a valid non-nil pointer for the call.
  Result := RtlSizeHeap(RtlGetCurrentPeb.ProcessHeap, 0, GetData);
end;

function TAutoEnvironment.Offset;
begin
  Result := PByte(FAddress) + Bytes;
end;

{ Functions }

function RtlxCurrentEnvironment;
begin
  Result := TAutoEnvironment.Capture(CURRENT_ENVIRONMENT);
end;

function RtlxCaptureEnvironment(HeapBuffer: PEnvironment): IEnvironment;
begin
  // Never take ownership over the current environment

  if HeapBuffer = RtlGetCurrentPeb.ProcessParameters.Environment then
    Result := RtlxCurrentEnvironment
  else
    Result := TAutoEnvironment.Capture(HeapBuffer);
end;

function RtlxCreateEnvironment;
var
  Buffer: PEnvironment;
begin
  Result.Location := 'RtlCreateEnvironment';
  Result.Status := RtlCreateEnvironment(CloneCurrent, Buffer);

  if Result.IsSuccess then
    Env := TAutoEnvironment.Capture(Buffer);
end;

function RtlxIsCurrentEnvironment;
begin
  Result := (Env.Data = RtlGetCurrentPeb.ProcessParameters.Environment);
end;

function RtlxSwapCurrentEnvironment;
var
  OldEnvBuffer: PEnvironment;
begin
  if RtlxIsCurrentEnvironment(Env) then
  begin
    OldEnv := Env;
    Exit(NtxSuccess);
  end;

  // We need direct access to the underlying object
  if not (IUnknown(Env) is TAutoEnvironment) then
  begin
    Result.Location := 'RtlxSetCurrentEnvironmentEx';
    Result.Status := STATUS_UNSUCCESSFUL;
    Exit;
  end;

  Result.Location := 'RtlSetCurrentEnvironment';
  Result.Status := RtlSetCurrentEnvironment(Env.Data, @OldEnvBuffer);

  if Result.IsSuccess then
  begin
    // Store the returned pointer into a new IEnvironment
    OldEnv := TAutoEnvironment.Capture(OldEnvBuffer);

    // Make the used object point to the current environment
    TAutoEnvironment(Env).FAddress := CURRENT_ENVIRONMENT;
  end;
end;

function RtlxSetCurrentEnvironment;
var
  OldEnv: IEnvironment;
begin
  Result := RtlxSwapCurrentEnvironment(Env, OldEnv);
end;

function RtlxExpandString;
var
  xMemory: IMemory;
  SrcStr, DestStr: TNtUnicodeString;
  Required: Cardinal;
begin
  Result := RtlxInitUnicodeString(SrcStr, Source);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlExpandEnvironmentStrings_U';

  xMemory := Auto.AllocateDynamic(StringSizeZero(Source));
  repeat
    // Pass the size of the buffer in the MaximumLength field
    DestStr.Buffer := xMemory.Data;
    DestStr.MaximumLength := xMemory.Size;
    DestStr.Length := 0;

    Required := 0;
    Result.Status := RtlExpandEnvironmentStrings_U(Env.Data, SrcStr, DestStr,
      @Required);

    if Required > High(Word) then
      Break;

  until not NtxExpandBufferEx(Result, xMemory, Required, nil);

  if Result.IsSuccess then
    Expanded := DestStr.ToString;
end;

function RtlxExpandStringVar;
var
  Expanded: String;
begin
  Result := RtlxExpandString(Env, S, Expanded);

  if Result.IsSuccess then
    S := Expanded;
end;

function RtlxTryExpandString;
var
  ExpandedStr: String;
begin
  if RtlxExpandString(Env, Str, ExpandedStr).IsSuccess then
    Result := ExpandedStr
  else
    Result := Str;
end;

function GetNextVariable(
  [in] pStart: PWideChar;
  MaxIndex: NativeUInt;
  var CurrentIndex: NativeUInt;
  out Name: String;
  out Value: String
): Boolean;
var
  pCurrentChar, pName, pValue: PWideChar;
  StartIndex: NativeUInt;
begin
  pCurrentChar := pStart + CurrentIndex;

  // Start parsing the name
  StartIndex := CurrentIndex;
  pName := pCurrentChar;

  // Find the end of the name
  repeat
    if CurrentIndex >= MaxIndex then
      Exit(False);

    // The equality sign is considered as a delimiter between the name and the
    // value unless it is the first character
    if (pCurrentChar^ = '=') and (StartIndex <> CurrentIndex) then
      Break;

    if pCurrentChar^ = #0 then
      Exit(False); // no more variables

    Inc(CurrentIndex);
    Inc(pCurrentChar);
  until False;

  SetString(Name, pName, CurrentIndex - StartIndex);

  // Skip the equality sign
  Inc(CurrentIndex);
  Inc(pCurrentChar);

  // Start parsing the value
  StartIndex := CurrentIndex;
  pValue := pCurrentChar;

  // Find the end of the value
  repeat
    if CurrentIndex >= MaxIndex then
      Exit(False);

    // The value is zero-terminated
    if pCurrentChar^ = #0 then
      Break;

    Inc(CurrentIndex);
    Inc(pCurrentChar);
  until False;

  SetString(Value, pValue, CurrentIndex - StartIndex);

  // Skip the #0 character
  Inc(CurrentIndex);

  Result := True;
end;

function RtlxEnumerateEnvironmemt;
var
  pStart: PWideChar;
  Index, MaxIndex: NativeUInt;
  Name, Value: String;
begin
  SetLength(Result, 0);

  Index := 0;
  pStart := PWideChar(Env.Data);
  MaxIndex := Env.Size div SizeOf(WideChar);

  while GetNextVariable(pStart, MaxIndex, Index, Name, Value) do
  begin
    SetLength(Result, Succ(Length(Result)));
    Result[High(Result)].Name := Name;
    Result[High(Result)].Value := Value;
  end;
end;

function RtlxQueryVariableEnvironment;
var
  xMemory: IMemory;
  NameStr, ValueStr: TNtUnicodeString;
begin
  Result := RtlxInitUnicodeString(NameStr, Name);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlQueryEnvironmentVariable_U';

  xMemory := Auto.AllocateDynamic(RtlGetLongestNtPathLength);
  repeat
    ValueStr.Buffer := xMemory.Data;
    ValueStr.MaximumLength := xMemory.Size;
    ValueStr.Length := 0;

    Result.Status := RtlQueryEnvironmentVariable_U(Env.Data, NameStr, ValueStr);

    if ValueStr.MaximumLength > High(Word) - SizeOf(WideChar) then
      Break;

    // Include terminating zero
    Inc(ValueStr.MaximumLength, SizeOf(WideChar));
  until not NtxExpandBufferEx(Result, xMemory, ValueStr.MaximumLength, nil);

  if Result.IsSuccess then
    Value := ValueStr.ToString;
end;

function RtlxTryQueryVariableEnvironment;
var
  Status: TNtxStatus;
begin
  // Will clear the result on failure
  Status := RtlxQueryVariableEnvironment(Env, Name, Result);
end;

function RtlxSetVariableEnvironment;
var
  NameStr, ValueStr: TNtUnicodeString;
  EnvCopy: IEnvironment;
begin
  // We need direct access to the address field
  if not (IUnknown(Env) is TAutoEnvironment) then
  begin
    Result.Location := 'RtlxSetVariableEnvironment';
    Result.Status := STATUS_UNSUCCESSFUL;
    Exit;
  end;

  Result := RtlxInitUnicodeString(NameStr, Name);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(ValueStr, Value);

  if not Result.IsSuccess then
    Exit;

  if not RtlxIsCurrentEnvironment(Env) then
  begin
    // This function might reallocate the environment block changing the
    // pointer to the data.
    Result.Location := 'RtlSetEnvironmentVariable';
    Result.Status := RtlSetEnvironmentVariable(TAutoEnvironment(Env).FAddress,
      NameStr, ValueStr.RefOrNil);
  end
  else
  begin
    // RtlSetEnvironmentVariable can't change variables in the current block,
    // it allocates an empty block and sets a variable in it.

    // Make a full copy
    Result := RtlxCreateEnvironment(EnvCopy, True);

    // Make changes to the copy
    if Result.IsSuccess then
      Result := RtlxSetVariableEnvironment(EnvCopy, Name, Value);

    // Set it as the current environment
    if Result.IsSuccess then
      Result := RtlxSetCurrentEnvironment(EnvCopy);
  end;
end;

function RtlxDeleteVariableEnvironment;
begin
  // Setting an empty string will remove the variable
  Result := RtlxSetVariableEnvironment(Env, Name, '');
end;

end.
