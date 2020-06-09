unit NtUtils.Environment;

interface

uses
  Winapi.WinNt, NtUtils;

type
  TEnvVariable = record
    Name, Value: String;
  end;

// Reference the current environment
function RtlxCurrentEnvironment: IEnvironment;

// Capture an environment
function RtlxCaptureEnvironment(HeapBuffer: PEnvironment): IEnvironment;

// Inherit or create an empty environment
function RtlxCreateEnvironment(out Env: IEnvironment; CloneCurrent: Boolean):
  TNtxStatus;

// Determine is an environment is set as current
function RtlxIsCurrentEnvironment(Env: IEnvironment): Boolean;

// Swap the current environment with the new one
function RtlxSwapCurrentEnvironment(Env: IEnvironment;
  out OldEnv: IEnvironment): TNtxStatus;

// Set this environment as current
function RtlxSetCurrentEnvironment(Env: IEnvironment): TNtxStatus;

// Expand environmental variables in a string
function RtlxExpandString(Env: IEnvironment; Source: String;
  out Expanded: String): TNtxStatus;

// Expand environmental variables in a string via a var parameter
function RtlxExpandStringVar(Env: IEnvironment; var S: String): TNtxStatus;

// Try to expand environmental variables in a string
function RtlxTryExpandString(Env: IEnvironment; Str: String): String;

// Enumerate all names and values present in an environment
function RtlxEnumerateEnvironmemt(Env: IEnvironment): TArray<TEnvVariable>;

// Query a value of a environment variable
function RtlxQueryVariableEnvironment(Env: IEnvironment; Name: String;
  out Value: String): TNtxStatus;

// Try to query an environment variable
function RtlxTryQueryVariableEnvironment(Env: IEnvironment; Name: String):
  String;

// Add or modify an environment variable
function RtlxSetVariableEnvironment(Env: IEnvironment; Name, Value: String):
  TNtxStatus;

// Remove an environment variable
function RtlxDeleteVariableEnvironment(Env: IEnvironment; Name: String):
  TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntrtl, Ntapi.ntstatus, Ntapi.ntpebteb,
  DelphiUtils.AutoObject;

type
  TAutoEnvironment = class (TCustomAutoReleasable, IEnvironment)
  protected
    FAddress: PEnvironment; // nil indicates the current environmet
  public
    constructor Capture(Address: PEnvironment);
    function GetAddress: PEnvironment;
    function GetSize: NativeUInt;
    function GetRegion: TMemory;
    function Offset(Bytes: NativeUInt): Pointer;
    destructor Destroy; override;
  end;

{ TAutoEnvironment }

constructor TAutoEnvironment.Capture(Address: PEnvironment);
begin
  FAddress := Address;
end;

destructor TAutoEnvironment.Destroy;
begin
  if FAutoRelease and Assigned(FAddress) then
    RtlDestroyEnvironment(FAddress);

  inherited;
end;

function TAutoEnvironment.GetAddress: PEnvironment;
begin
  // Always return a non-nil pointer

  if Assigned(FAddress) then
    Result := FAddress
  else
    Result := RtlGetCurrentPeb.ProcessParameters.Environment;
end;

function TAutoEnvironment.GetRegion: TMemory;
begin
  Result.Address := GetAddress;
  Result.Size := GetSize;
end;

function TAutoEnvironment.GetSize: NativeUInt;
begin
  // This is the same way as RtlSetEnvironmentVariable determines the size.
  // Make sure to use a non-nil pointer for the call.
  Result := RtlSizeHeap(RtlGetCurrentPeb.ProcessHeap, 0, GetAddress);
end;

function TAutoEnvironment.Offset(Bytes: NativeUInt): Pointer;
begin
  Result := PByte(FAddress) + Bytes;
end;

{ Functions }

function RtlxCurrentEnvironment: IEnvironment;
begin
  Result := TAutoEnvironment.Capture(nil);
end;

function RtlxCaptureEnvironment(HeapBuffer: PEnvironment): IEnvironment;
begin
  // Do not take ownership over the current environment
  if HeapBuffer = RtlGetCurrentPeb.ProcessParameters.Environment then
    HeapBuffer := nil;

  Result := TAutoEnvironment.Capture(HeapBuffer);
end;

function RtlxCreateEnvironment(out Env: IEnvironment; CloneCurrent: Boolean):
  TNtxStatus;
var
  Buffer: PEnvironment;
begin
  Result.Location := 'RtlCreateEnvironment';
  Result.Status := RtlCreateEnvironment(CloneCurrent, Buffer);

  if Result.IsSuccess then
    Env := TAutoEnvironment.Capture(Buffer);
end;

function RtlxIsCurrentEnvironment(Env: IEnvironment): Boolean;
begin
  if IUnknown(Env) is TAutoEnvironment then
    Exit(not Assigned(TAutoEnvironment(Env).FAddress));

  Result := (Env.Data = RtlGetCurrentPeb.ProcessParameters.Environment);
end;

function RtlxSwapCurrentEnvironment(Env: IEnvironment;
  out OldEnv: IEnvironment): TNtxStatus;
var
  OldEnvBuffer: PEnvironment;
begin
  if RtlxIsCurrentEnvironment(Env) then
  begin
    Result.Status := STATUS_SUCCESS;
    OldEnv := Env;
    Exit;
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
    // Store the returned pointer into a new IEnvironmnent
    OldEnv := TAutoEnvironment.Capture(OldEnvBuffer);

    // Make the used object point to the current environment
    TAutoEnvironment(Env).FAddress := nil;
  end;
end;

function RtlxSetCurrentEnvironment(Env: IEnvironment): TNtxStatus;
var
  OldEnv: IEnvironment;
begin
  Result := RtlxSwapCurrentEnvironment(Env, OldEnv);
end;

function RtlxExpandString(Env: IEnvironment; Source: String;
  out Expanded: String): TNtxStatus;
var
  xMemory: IMemory;
  SrcStr, DestStr: TNtUnicodeString;
  Required: Cardinal;
begin
  SrcStr := TNtUnicodeString.From(Source);
  Result.Location := 'RtlExpandEnvironmentStrings_U';

  xMemory := TAutoMemory.Allocate(Succ(Length(Source)) * SizeOf(WideChar));
  repeat
    // Pass the size of the buffer in the MaximumLength field
    DestStr.Buffer := xMemory.Data;
    DestStr.MaximumLength := xMemory.Size;
    DestStr.Length := 0;

    Required := 0;
    Result.Status := RtlExpandEnvironmentStrings_U(Env.Data, SrcStr, DestStr,
      @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, nil);

  if Result.IsSuccess then
    Expanded := DestStr.ToString;
end;

function RtlxExpandStringVar(Env: IEnvironment; var S: String): TNtxStatus;
var
  Expanded: String;
begin
  Result := RtlxExpandString(Env, S, Expanded);

  if Result.IsSuccess then
    S := Expanded;
end;

function RtlxTryExpandString(Env: IEnvironment; Str: String): String;
var
  Status: TNtxStatus;
  Temp: String;
begin
  Status := RtlxExpandString(Env, Str, Temp);

  if Status.IsSuccess then
    Result := Temp
  else
    Result := Str;
end;

function GetNextVariable(pStart: PWideChar; MaxIndex: NativeUInt;
  var CurrentIndex: NativeUInt; out Name: String; out Value: String): Boolean;
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

function RtlxEnumerateEnvironmemt(Env: IEnvironment): TArray<TEnvVariable>;
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

function RtlxQueryVariableEnvironment(Env: IEnvironment; Name: String;
  out Value: String): TNtxStatus;
var
  xMemory: IMemory;
  NameStr, ValueStr: TNtUnicodeString;
begin
  NameStr := TNtUnicodeString.From(Name);
  Result.Location := 'RtlQueryEnvironmentVariable_U';

  xMemory := TAutoMemory.Allocate(RtlGetLongestNtPathLength);
  repeat
    ValueStr.Buffer := xMemory.Data;
    ValueStr.MaximumLength := xMemory.Size;
    ValueStr.Length := 0;

    Result.Status := RtlQueryEnvironmentVariable_U(Env.Data, NameStr, ValueStr);

    // Include terminating zero
    Inc(ValueStr.MaximumLength, SizeOf(WideChar));
  until not NtxExpandBufferEx(Result, xMemory, ValueStr.MaximumLength, nil);

  if Result.IsSuccess then
    Value := ValueStr.ToString;
end;

function RtlxTryQueryVariableEnvironment(Env: IEnvironment; Name: String):
  String;
var
  Status: TNtxStatus;
begin
  // Will clear the result on failure
  Status := RtlxQueryVariableEnvironment(Env, Name, Result);
end;

function RtlxSetVariableEnvironment(Env: IEnvironment; Name, Value: String):
  TNtxStatus;
var
  EnvCopy: IEnvironment;
begin
  // We need direct access to the address field
  if not (IUnknown(Env) is TAutoEnvironment) then
  begin
    Result.Location := 'RtlxSetVariableEnvironment';
    Result.Status := STATUS_UNSUCCESSFUL;
    Exit;
  end;

  if not RtlxIsCurrentEnvironment(Env) then
  begin
    // This function might reallocate the environmnet block chaging the
    // pointer to the data.
    Result.Location := 'RtlSetEnvironmentVariable';
    Result.Status := RtlSetEnvironmentVariable(TAutoEnvironment(Env).FAddress,
      TNtUnicodeString.From(Name), TNtUnicodeString.From(Value).RefOrNull);
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

function RtlxDeleteVariableEnvironment(Env: IEnvironment; Name: String):
  TNtxStatus;
begin
  // Setting an empty string will remove the variable
  Result := RtlxSetVariableEnvironment(Env, Name, '');
end;

end.
