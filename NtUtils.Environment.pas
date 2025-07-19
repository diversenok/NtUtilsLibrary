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

// Capture ownership over an environment block.
// Note: the buffer needs to be allocated on the main process heap
function RtlxCaptureEnvironment(
  [in] HeapBuffer: PEnvironment;
  [in, opt] Size: NativeUInt = 0
): IEnvironment;

// Create an empty environment block or a copy of the current one
function RtlxCreateEnvironment(
  out Environment: IEnvironment;
  CloneCurrent: Boolean
): TNtxStatus;

// Determine if an environment block is used as the current
function RtlxIsCurrentEnvironment(
  [opt] const Environment: IEnvironment
): Boolean;

// Extract the start of the specified or the current environment block
function RtlxEnvironmentData(
  [opt] const Environment: IEnvironment
): PEnvironment;

// Extract the size of the specified or the current environment block
function RtlxEnvironmentSize(
  [opt] const Environment: IEnvironment
): NativeUInt;

// Swap the current environment with the new one
function RtlxSwapCurrentEnvironment(
  const Environment: IEnvironment;
  [MayReturnNil] out PreviousEnvironment: IEnvironment
): TNtxStatus;

// Set this environment as current
function RtlxSetCurrentEnvironment(
  const Environment: IEnvironment
): TNtxStatus;

// Expand environment variables in a string
function RtlxExpandString(
  const Source: String;
  out Expanded: String;
  [opt] const Environment: IEnvironment = nil
): TNtxStatus;

// Expand environment variables in a string in-place
function RtlxExpandStringVar(
  var S: String;
  [opt] const Environment: IEnvironment = nil
): TNtxStatus;

// Try to expand environment variables in a string
function RtlxTryExpandString(
  const Str: String;
  [opt] const Environment: IEnvironment = nil
): String;

// Enumerate all names and values present in an environment
function RtlxEnumerateEnvironment(
  [opt] const Environment: IEnvironment = nil
): TArray<TEnvVariable>;

// Make a for-in iterator for enumerating environment variables.
// Note: when the Status parameter is not set, the function might raise
// exceptions during enumeration.
function RtlxIterateEnvironment(
  [opt] const Environment: IEnvironment = nil
): IEnumerable<TEnvVariable>;

// Query a value of a environment variable
function RtlxQueryVariableEnvironment(
  const Name: String;
  out Value: String;
  [opt] const Environment: IEnvironment = nil
): TNtxStatus;

// Try to query an environment variable
function RtlxTryQueryVariableEnvironment(
  const Name: String;
  [opt] const Environment: IEnvironment = nil
): String;

// Add or modify an environment variable
function RtlxSetVariableEnvironment(
  const Name: String;
  const Value: String;
  [opt] const Environment: IEnvironment = nil
): TNtxStatus;

// Remove an environment variable
function RtlxDeleteVariableEnvironment(
  const Name: String;
  [opt] const Environment: IEnvironment = nil
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntrtl, Ntapi.ntstatus, Ntapi.ntpebteb,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  PPEnvironment = ^PEnvironment;

  IEnvironmentInternal = interface
    ['{6AFC5893-990B-4A92-A785-B9444ACA01A5}']
    function RawAddress: PPEnvironment;
    procedure RefreshSize;
  end;

  TAutoEnvironment = class (TCustomAutoMemory, IEnvironmentInternal)
    constructor Capture(Address: Pointer; Size: NativeUInt = 0);
    function RawAddress: PPEnvironment;
    procedure RefreshSize;
    destructor Destroy; override;
  end;

constructor TAutoEnvironment.Capture;
begin
  if Assigned(Address) and (Size = 0) then
    Size := RtlSizeHeap(RtlGetCurrentPeb.ProcessHeap, 0, Address);

  inherited Capture(Address, Size);
end;

destructor TAutoEnvironment.Destroy;
begin
  if Assigned(FData) and not FDiscardOwnership then
    RtlDestroyEnvironment(FData);

  inherited;
end;

function TAutoEnvironment.RawAddress;
begin
  Result := @PEnvironment(FData);
end;

procedure TAutoEnvironment.RefreshSize;
begin
  if Assigned(FData) then
    FSize := RtlSizeHeap(RtlGetCurrentPeb.ProcessHeap, 0, FData);
end;

function RtlxCaptureEnvironment;
begin
  IMemory(Result) := TAutoEnvironment.Capture(HeapBuffer, Size);
end;

function RtlxCreateEnvironment;
var
  Buffer: PEnvironment;
begin
  Result.Location := 'RtlCreateEnvironment';
  Result.Status := RtlCreateEnvironment(CloneCurrent, Buffer);

  if not Result.IsSuccess then
    Exit;

  Environment := RtlxCaptureEnvironment(Buffer);
end;

function RtlxIsCurrentEnvironment;
begin
  Result := not Assigned(Environment) or
    (Environment.Data = RtlGetCurrentPeb.ProcessParameters.Environment);
end;

function RtlxEnvironmentData;
begin
  if Assigned(Environment) then
    Result := Environment.Data
  else
    Result := RtlGetCurrentPeb.ProcessParameters.Environment;
end;

function RtlxEnvironmentSize;
begin
  if Assigned(Environment) then
    Result := Environment.Size
  else
    Result := RtlGetCurrentPeb.ProcessParameters.EnvironmentSize;
end;

function RtlxSwapCurrentEnvironment;
var
  OldBuffer: PEnvironment;
begin
  if RtlxIsCurrentEnvironment(Environment) then
  begin
    Result.Location := 'RtlxSwapCurrentEnvironment';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  Result.Location := 'RtlSetCurrentEnvironment';
  Result.Status := RtlSetCurrentEnvironment(Environment.Data, @OldBuffer);

  if Result.IsSuccess then
  begin
    // Don't destory the input block since we transferred its ownership
    Environment.DiscardOwnership;

    // Capture ownership over the previous environment block
    if Assigned(OldBuffer) then
      PreviousEnvironment := RtlxCaptureEnvironment(OldBuffer)
    else
      PreviousEnvironment := nil;
  end;
end;

function RtlxSetCurrentEnvironment;
var
  PreviousEnvironment: IEnvironment;
begin
  Result := RtlxSwapCurrentEnvironment(Environment, PreviousEnvironment);
end;

function RtlxExpandString;
var
  StringBuffer: IMemory;
  EnvironmentStart: PEnvironment;
  SourceStr, DestinationStr: TNtUnicodeString;
  Required: Cardinal;
begin
  Result := RtlxInitUnicodeString(SourceStr, Source);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlExpandEnvironmentStrings_U';

  EnvironmentStart := RtlxEnvironmentData(Environment);
  StringBuffer := Auto.AllocateDynamic(StringSizeZero(Source));
  repeat
    // Pass the size of the buffer in the MaximumLength field
    DestinationStr.Buffer := StringBuffer.Data;
    DestinationStr.MaximumLength := StringBuffer.Size;
    DestinationStr.Length := 0;

    Required := 0;
    Result.Status := RtlExpandEnvironmentStrings_U(EnvironmentStart, SourceStr,
      DestinationStr, @Required);

    if Required > High(Word) then
      Break;

  until not NtxExpandBufferEx(Result, StringBuffer, Required, nil);

  if Result.IsSuccess then
    Expanded := DestinationStr.ToString;
end;

function RtlxExpandStringVar;
var
  Expanded: String;
begin
  Result := RtlxExpandString(S, Expanded, Environment);

  if Result.IsSuccess then
    S := Expanded;
end;

function RtlxTryExpandString;
var
  ExpandedStr: String;
begin
  if RtlxExpandString(Str, ExpandedStr, Environment).IsSuccess then
    Result := ExpandedStr
  else
    Result := Str;
end;

function GetNextVariable(
  [in] pStart: PEnvironment;
  MaxIndex: NativeUInt;
  var CurrentIndex: NativeUInt;
  out Name: String;
  out Value: String
): Boolean;
var
  pCurrentChar, pName, pValue: PEnvironment;
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

function RtlxEnumerateEnvironment;
var
  EnvironmentStart: PEnvironment;
  Index, MaxIndex: NativeUInt;
  Name, Value: String;
begin
  Result := nil;
  Index := 0;
  EnvironmentStart := RtlxEnvironmentData(Environment);
  MaxIndex := RtlxEnvironmentSize(Environment) div SizeOf(WideChar);

  while GetNextVariable(EnvironmentStart, MaxIndex, Index, Name, Value) do
  begin
    SetLength(Result, Succ(Length(Result)));
    Result[High(Result)].Name := Name;
    Result[High(Result)].Value := Value;
  end;
end;

function RtlxIterateEnvironment;
var
  EnvironmentToVerify: PEnvironment;
  Index, VersionToVerify: NativeUInt;
begin
  Index := 0;

  if RtlxIsCurrentEnvironment(Environment) then
  begin
    // Since we don't own the current environment, we cannot capture it to
    // prolong its lifetime. The best option is to verify it hasn't changed.
    EnvironmentToVerify := RtlGetCurrentPeb.ProcessParameters.Environment;
    VersionToVerify := RtlGetCurrentPeb.ProcessParameters.EnvironmentVersion;
  end
  else
    EnvironmentToVerify := nil;

  Result := Auto.Iterate<TEnvVariable>(
    function (out Next: TEnvVariable): Boolean
    begin
      // Verify the current environment didn't change
      if Assigned(EnvironmentToVerify) and ((EnvironmentToVerify <>
        RtlGetCurrentPeb.ProcessParameters.Environment) or (VersionToVerify <>
        RtlGetCurrentPeb.ProcessParameters.EnvironmentVersion)) then
        Exit(False);

      Result := GetNextVariable(RtlxEnvironmentData(Environment),
        RtlxEnvironmentSize(Environment) div SizeOf(WideChar), Index, Next.Name,
        Next.Value)
    end
  );
end;

function RtlxQueryVariableEnvironment;
var
  Buffer: IMemory;
  EnvironmentStart: PEnvironment;
  NameStr, ValueStr: TNtUnicodeString;
begin
  Result := RtlxInitUnicodeString(NameStr, Name);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlQueryEnvironmentVariable_U';

  Buffer := Auto.AllocateDynamic(RtlGetLongestNtPathLength);
  EnvironmentStart := RtlxEnvironmentData(Environment);
  repeat
    ValueStr.Buffer := Buffer.Data;
    ValueStr.MaximumLength := Buffer.Size;
    ValueStr.Length := 0;

    Result.Status := RtlQueryEnvironmentVariable_U(EnvironmentStart, NameStr,
      ValueStr);

    if ValueStr.MaximumLength > High(Word) - SizeOf(WideChar) then
      Break;

    // Include terminating zero
    Inc(ValueStr.MaximumLength, SizeOf(WideChar));
  until not NtxExpandBufferEx(Result, Buffer, ValueStr.MaximumLength, nil);

  if Result.IsSuccess then
    Value := ValueStr.ToString;
end;

function RtlxTryQueryVariableEnvironment;
begin
  // We pass Result as the out parameter which will clear it on failure
  RtlxQueryVariableEnvironment(Name, Result, Environment);
end;

function RtlxSetVariableEnvironment;
var
  NameStr, ValueStr: TNtUnicodeString;
  EnvironmentInternal: IEnvironmentInternal;
  EnvironmentCopy: IEnvironment;
begin
  Result := RtlxInitUnicodeString(NameStr, Name);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(ValueStr, Value);

  if not Result.IsSuccess then
    Exit;

  if not RtlxIsCurrentEnvironment(Environment) then
  begin
    // Extract the internal interface needed for direct access
    Result.Location := 'RtlxSetVariableEnvironment';
    Result.HResult := Environment.QueryInterface(IEnvironmentInternal,
      EnvironmentInternal);

    if not Result.IsSuccess then
      Exit;

    // The call can reallocate the environment block
    Result.Location := 'RtlSetEnvironmentVariable';
    Result.Status := RtlSetEnvironmentVariable(EnvironmentInternal.RawAddress^,
      NameStr, ValueStr.RefOrNil);

    if not Result.IsSuccess then
      Exit;

    // Update the size to account for possible reallocation
    EnvironmentInternal.RefreshSize;
  end
  else
  begin
    // RtlSetEnvironmentVariable can't change variables in the current block,
    // it allocates an empty block and sets a variable in it instead.
    // Workaround this issue here.

    // Make a full copy
    Result := RtlxCreateEnvironment(EnvironmentCopy, True);

    if not Result.IsSuccess then
      Exit;

    // Apply changes to the copy
    Result := RtlxSetVariableEnvironment(Name, Value, EnvironmentCopy);

    if not Result.IsSuccess then
      Exit;

    // Set it as the current environment
    Result := RtlxSetCurrentEnvironment(EnvironmentCopy);
  end;
end;

function RtlxDeleteVariableEnvironment;
begin
  // Setting an empty string will remove the variable
  Result := RtlxSetVariableEnvironment(Name, '', Environment);
end;

end.
