unit NtUtils.SysUtils;

{
  The module includes miscellaneous functions to compensate for missing
  System.SysUtils.
}

interface

uses
  Ntapi.WinNt, DelphiApi.Reflection, DelphiUtils.AutoObjects;

// Strings

// Create string from a potenrially zero-terminated buffer
function RtlxCaptureString(
  [in] Buffer: PWideChar;
  MaxChars: Cardinal
): String;

// Create string from a potenrially zero-terminated buffer
function RtlxCaptureAnsiString(
  [in] Buffer: PAnsiChar;
  MaxChars: Cardinal
): AnsiString;

// Make a string by repeating a character
function RtlxBuildString(
  Char: WideChar;
  Count: Cardinal
): String;

// Convert an array of strings to a wide multi-zero-terminated string
function RtlxBuildWideMultiSz(
  const Strings: TArray<String>
): IMemory<PWideMultiSz>;

// Convert an array of strings to an ANSI multi-zero-terminated string
function RtlxBuildAnsiMultiSz(
  const Strings: TArray<AnsiString>
): IMemory<PAnsiMultiSz>;

// Convert a wide multi-zero-terminated string into an array of string
function RtlxParseWideMultiSz(
  [in] Buffer: PWideMultiSz;
  MaximumLength: Cardinal = $FFFFFFFF
): TArray<String>;

// Convert an ANSI multi-zero-terminated string into an array of string
function RtlxParseAnsiMultiSz(
  [in] Buffer: PAnsiMultiSz;
  MaximumLength: Cardinal = $FFFFFFFF
): TArray<AnsiString>;

// Compare two unicode strings in a case-(in)sensitive way
function RtlxCompareStrings(
  const String1: String;
  const String2: String;
  CaseSensitive: Boolean = False
): Integer;

// Compare two ANSI strings in a case-(in)sensitive way
function RtlxCompareAnsiStrings(
  const String1: AnsiString;
  const String2: AnsiString;
  CaseSensitive: Boolean = False
): Integer;

// Check if two unicode strings are equal in a case-(in)sensitive way
function RtlxEqualStrings(
  const String1: String;
  const String2: String;
  CaseSensitive: Boolean = False
): Boolean;

// Check if two ANSI strings are equal in a case-(in)sensitive way
function RtlxEqualAnsiStrings(
  const String1: AnsiString;
  const String2: AnsiString;
  CaseSensitive: Boolean = False
): Boolean;

// Compute a hash of a string
function RtlxHashString(
  const Source: String;
  CaseSensitive: Boolean = False
): Cardinal;

// Check if a string has a matching prefix
function RtlxPrefixString(
  const Prefix: String;
  const S: String;
  CaseSensitive: Boolean = False
): Boolean;

// Check if an ANSI string has a matching prefix
function RtlxPrefixAnsiString(
  const Prefix: AnsiString;
  const S: AnsiString;
  CaseSensitive: Boolean = False
): Boolean;

// Format a string similar to System.SysUtils.Format but using ntdll's CRT
// Differences:
//  - supports %wZ for TNtUnicodeString
//  - supports %z for TNtAnsiString
//  - does not support floating point formats
// For more details, see:
// https://docs.microsoft.com/en-us/cpp/c-runtime-library/format-specification-syntax-printf-and-wprintf-functions
function RtlxFormatString(
  const Format: String;
  const Args: array of const
): String;

// Integers

// Convert a 32-bit integer to a string
function RtlxUIntToStr(
  Value: Cardinal;
  Base: Cardinal = 10;
  Width: Cardinal = 0
): String;

// Convert a 64-bit integer to a string
function RtlxUInt64ToStr(
  Value: UInt64;
  Base: Cardinal = 10;
  Width: Cardinal = 0
): String;

// Convert a native-size integer to a string
function RtlxUIntPtrToStr(
  Value: UIntPtr;
  Base: Cardinal = 10;
  Width: Cardinal = 0
): String;

// Convert a pointer value to a string
function RtlxPtrToStr(
  Value: Pointer;
  Width: Cardinal = 8
): String;

// Convert a string to an integer
function RtlxStrToUInt(
  const S: String;
  out Value: Cardinal
): Boolean;

// Random

// Generate a random number
function RtlxRandom: Cardinal;

// Generate a random GUID
function RtlxRandomGuid: TGuid;

// GUIDs

// Convert a GUID to a string
function RtlxGuidToString(
  const Guid: TGuid
): String;

// Paths

// Split the path into the parent (directory) and child (filename) components
function RtlxSplitPath(
  const Path: String;
  out ParentName: String;
  out ChildName: String
): Boolean;

// Extract a parent component from a path
function RtlxExtractRootPath(
  const Path: String
): String;

// Extract a child component from a path
function RtlxExtractNamePath(
  const Path: String
): String;

// Check if one path is under another path
// NOTE: only use on normized & final paths
function RtlxIsPathUnderRoot(
  const Path: String;
  const Root: String
): Boolean;

implementation

uses
  Ntapi.ntrtl, Ntapi.ntdef, Ntapi.crt, Ntapi.ntpebteb;

function RtlxCaptureString;
var
  Finish: PWideChar;
  Count: Cardinal;
begin
  Finish := Buffer;
  Count := 0;

  while (Count < MaxChars) and (Finish^ <> #0) do
  begin
    Inc(Finish);
    Inc(Count);
  end;

  SetString(Result, Buffer, Count);
end;

function RtlxCaptureAnsiString;
var
  Finish: PAnsiChar;
  Count: Cardinal;
begin
  Finish := Buffer;
  Count := 0;

  while (Count < MaxChars) and (Finish^ <> #0) do
  begin
    Inc(Finish);
    Inc(Count);
  end;

  SetString(Result, Buffer, Count);
end;

function RtlxBuildString;
var
  i: Integer;
begin
  SetLength(Result, Count);

  for i := Low(Result) to High(Result) do
    Result[i] := Char;
end;

function RtlxBuildWideMultiSz;
var
  S: String;
  Size: Cardinal;
  Buffer: PWideMultiSz;
begin
  Size := 2 * SizeOf(WideChar);

  for S in Strings do
    Inc(Size, Succ(Length(S)) * SizeOf(WideChar));

  // Allocate a buffer for all strings + additional zero terminators
  Imemory(Result) := Auto.AllocateDynamic(Size);
  Buffer := Result.Data;

  for S in Strings do
  begin
    memmove(Buffer, PWideChar(S), Length(S) * SizeOf(WideChar));
    Inc(Buffer, Succ(Length(S)));
  end;
end;

function RtlxBuildAnsiMultiSz;
var
  S: AnsiString;
  Size: Cardinal;
  Buffer: PAnsiMultiSz;
begin
  Size := 2 * SizeOf(AnsiChar);

  for S in Strings do
    Inc(Size, Succ(Length(S)) * SizeOf(AnsiChar));

  // Allocate a buffer for all strings + additional zero terminators
  Imemory(Result) := Auto.AllocateDynamic(Size);
  Buffer := Result.Data;

  for S in Strings do
  begin
    memmove(Buffer, PAnsiChar(S), Length(S) * SizeOf(AnsiChar));
    Inc(Buffer, Succ(Length(S)));
  end;
end;

function RtlxParseWideMultiSz;
var
  Count, j: Integer;
  pCurrentChar, pItemStart, pBlockEnd: PWideChar;
begin
  // Save where the buffer ends to make sure we don't pass this point
  pBlockEnd := PWideChar(Buffer) + MaximumLength;

  // Count strings
  Count := 0;
  pCurrentChar := PWideChar(Buffer);

  while (pCurrentChar < pBlockEnd) and (pCurrentChar^ <> #0) do
  begin
    // Skip one zero-terminated string
    while (pCurrentChar < pBlockEnd) and (pCurrentChar^ <> #0) do
      Inc(pCurrentChar);

    Inc(Count);
    Inc(pCurrentChar);
  end;

  SetLength(Result, Count);

  // Save the content
  j := 0;
  pCurrentChar := PWideChar(Buffer);

  while (pCurrentChar < pBlockEnd) and (pCurrentChar^ <> #0) do
  begin
    // Parse one string
    Count := 0;
    pItemStart := pCurrentChar;

    while (pCurrentChar < pBlockEnd) and (pCurrentChar^ <> #0) do
    begin
      Inc(pCurrentChar);
      Inc(Count);
    end;

    // Save it
    SetString(Result[j], pItemStart, Count);

    Inc(j);
    Inc(pCurrentChar);
  end;
end;

function RtlxParseAnsiMultiSz;
var
  Count, j: Integer;
  pCurrentChar, pItemStart, pBlockEnd: PAnsiChar;
begin
  // Save where the buffer ends to make sure we don't pass this point
  pBlockEnd := PAnsiChar(Buffer) + MaximumLength;

  // Count strings
  Count := 0;
  pCurrentChar := PAnsiChar(Buffer);

  while (pCurrentChar < pBlockEnd) and (pCurrentChar^ <> #0) do
  begin
    // Skip one zero-terminated string
    while (pCurrentChar < pBlockEnd) and (pCurrentChar^ <> #0) do
      Inc(pCurrentChar);

    Inc(Count);
    Inc(pCurrentChar);
  end;

  SetLength(Result, Count);

  // Save the content
  j := 0;
  pCurrentChar := PAnsiChar(Buffer);

  while (pCurrentChar < pBlockEnd) and (pCurrentChar^ <> #0) do
  begin
    // Parse one string
    Count := 0;
    pItemStart := pCurrentChar;

    while (pCurrentChar < pBlockEnd) and (pCurrentChar^ <> #0) do
    begin
      Inc(pCurrentChar);
      Inc(Count);
    end;

    // Save it
    SetString(Result[j], pItemStart, Count);

    Inc(j);
    Inc(pCurrentChar);
  end;
end;

function RtlxCompareStrings;
begin
  Result := RtlCompareUnicodeString(TNtUnicodeString.From(String1),
    TNtUnicodeString.From(String2), not CaseSensitive);
end;

function RtlxCompareAnsiStrings;
begin
  Result := RtlCompareString(TNtAnsiString.From(String1),
    TNtAnsiString.From(String2), not CaseSensitive);
end;

function RtlxEqualStrings;
begin
  Result := RtlEqualUnicodeString(TNtUnicodeString.From(String1),
    TNtUnicodeString.From(String2), not CaseSensitive);
end;

function RtlxEqualAnsiStrings;
begin
  Result := RtlEqualString(TNtAnsiString.From(String1),
    TNtAnsiString.From(String2), not CaseSensitive);
end;

function RtlxHashString;
begin
  if not NT_SUCCESS(RtlHashUnicodeString(TNtUnicodeString.From(Source),
    not CaseSensitive, HASH_STRING_ALGORITHM_DEFAULT, Result)) then
    Result := Length(Source);
end;

function RtlxPrefixString;
begin
  Result := RtlPrefixUnicodeString(TNtUnicodeString.From(Prefix),
    TNtUnicodeString.From(S), not CaseSensitive);
end;

function RtlxPrefixAnsiString;
begin
  Result := RtlPrefixString(TNtAnsiString.From(Prefix),
    TNtAnsiString.From(S), not CaseSensitive);
end;

function RtlxpAllocateVarArgs(
  const Args: array of const
): IMemory;
var
  Buffer: Pointer;
  i: Integer;
begin
  Result := Auto.AllocateDynamic(Length(Args) * SizeOf(Pointer));
  Buffer := Result.Data;

  for i := 0 to High(Args) do
  begin
    case Args[i].VType of
      vtInteger:       Integer(Buffer^) := Args[i].VInteger;
      vtBoolean:       Boolean(Buffer^) := Args[i].VBoolean;
      vtChar:          AnsiChar(Buffer^) := Args[i].VChar;
      vtExtended:      Double(Buffer^) := Double(Args[i].VExtended^);
      vtString:        Pointer(Buffer^) := Args[i].VString;
      vtPointer:       Pointer(Buffer^) := Args[i].VPointer;
      vtPChar:         Pointer(Buffer^) := Args[i].VPChar;
      vtObject:        Pointer(Buffer^) := Args[i].VObject;
      vtClass:         Pointer(Buffer^) := Args[i].VClass;
      vtWideChar:      WideChar(Buffer^) := Args[i].VWideChar;
      vtPWideChar:     Pointer(Buffer^) := Args[i].VPWideChar;
      vtAnsiString:    Pointer(Buffer^) := Args[i].VAnsiString;
      vtCurrency:      Pointer(Buffer^) := Args[i].VCurrency;
      vtVariant:       Pointer(Buffer^) := Args[i].VVariant;
      vtInterface:     Pointer(Buffer^) := Args[i].VInterface;
      vtWideString:    Pointer(Buffer^) := Args[i].VWideString;
      vtInt64:         Pointer(Buffer^) := Args[i].VInt64;
      vtUnicodeString: Pointer(Buffer^) := Args[i].VUnicodeString;
    end;

    Inc(PByte(Buffer), SizeOf(Pointer));
  end;
end;

function RtlxFormatString;
var
  Buffer: IMemory<PWideChar>;
  NewSize: Cardinal;
  Count: Integer;
begin
  NewSize := $100;

  repeat
    IMemory(Buffer) := Auto.AllocateDynamic(NewSize);

    Count := vswprintf_s(Buffer.Data, Buffer.Size div SizeOf(WideChar),
      PWideChar(Format), RtlxpAllocateVarArgs(Args).Data);

    if Count >= 0 then
    begin
      SetString(Result, Buffer.Data, Count);
      Exit;
    end;

    if Buffer.Size >= High(Word) then
      Exit('');

    NewSize := Buffer.Size * 2;

    if NewSize > High(Word) then
      NewSize := High(Word);

  until False;
end;

function RtlxUIntToStr;
var
  Str: TNtUnicodeString;
  Buffer: array [0..32] of WideChar;
begin
  Str.Length := 0;
  Str.MaximumLength := SizeOf(Buffer);
  Str.Buffer := PWideChar(@Buffer);

  if NT_SUCCESS(RtlIntegerToUnicodeString(Value, Base, Str)) then
  begin
    Result := Str.ToString;

    if Length(Result) < Integer(Width) then
      Result := RtlxBuildString('0', Integer(Width) - Length(Result)) + Result;

    case Base of
      2: Result := '0b' + Result;
      8: Result := '0o' + Result;
      16: Result := '0x' + Result;
    end;
  end
  else
    Result := '';
end;

function RtlxUInt64ToStr;
var
  Str: TNtUnicodeString;
  Buffer: array [0..64] of WideChar;
begin
  Str.Length := 0;
  Str.MaximumLength := SizeOf(Buffer);
  Str.Buffer := PWideChar(@Buffer);

  if NT_SUCCESS(RtlInt64ToUnicodeString(Value, Base, Str)) then
  begin
    Result := Str.ToString;

    if Length(Result) < Integer(Width) then
      Result := RtlxBuildString('0', Integer(Width) - Length(Result)) + Result;

    case Base of
      2: Result := '0b' + Result;
      8: Result := '0o' + Result;
      16: Result := '0x' + Result;
    end;
  end
  else
    Result := '';
end;

function RtlxUIntPtrToStr;
begin
  {$IF SizeOf(Value) = SizeOf(UInt64)}
  Result := RtlxUInt64ToStr(Value, Base, Width);
  {$ELSE}
  Result := RtlxUIntToStr(Value, Base, Width);
  {$ENDIF}
end;

function RtlxPtrToStr;
begin
  Result := RtlxUIntPtrToStr(UIntPtr(Value), 16, Width);
end;

function RtlxStrToUInt;
var
  echar: PWideChar;
  TempValue: Cardinal;
begin
  echar := nil;
  TempValue := wcstoul(PWideChar(S), @echar, 0);
  Result := Assigned(echar) and (echar^ = #0);

  if Result then
    Value := TempValue;
end;

var
  RtlxpSeed: Cardinal;

procedure RtlxpInitializeSeed;
begin
  RtlxpSeed := USER_SHARED_DATA.GetTickCount xor $55555555 xor
    (NtCurrentTeb.ClientID.UniqueThread shl 8) xor
    NtCurrentTeb.ClientID.UniqueProcess shr 2;
end;

function RtlxRandom: Cardinal;
begin
  if RtlxpSeed = 0 then
    RtlxpInitializeSeed;

  Result := RtlUniform(RtlxpSeed)
end;

function RtlxRandomGuid: TGuid;
var
  Buffer: array [0..3] of Cardinal absolute Result;
  i: Integer;
begin
  for i := Low(Buffer) to High(Buffer) do
    Buffer[i] := RtlxRandom;
end;

function RtlxGuidToString;
var
  Str: TNtUnicodeString;
begin
  FillChar(Str, SizeOf(TNtUnicodeString), 0);

  if NT_SUCCESS(RtlStringFromGUID(Guid, Str)) then
  begin
    Result := Str.ToString;
    RtlFreeUnicodeString(Str);
  end
  else
    Result := '';
end;

function RtlxSplitPath;
var
  i: Integer;
begin
  for i := High(Path) downto Low(Path) do
    if Path[i] = '\' then
    begin
      ParentName := Copy(Path, 1, i - Low(Path));
      ChildName := Copy(Path, i + Low(Path), Length(Path));
      Exit(True);
    end;

  Result := False;
end;

function RtlxExtractRootPath;
var
  i: Integer;
begin
  for i := High(Path) downto Low(Path) do
    if Path[i] = '\' then
      Exit(Copy(Path, 1, i - Low(Path)));

  Result := Path;
end;

function RtlxExtractNamePath;
var
  i: Integer;
begin
  for i := High(Path) downto Low(Path) do
    if Path[i] = '\' then
      Exit(Copy(Path, i + Low(Path), Length(Path)));

  Result := Path;
end;

function RtlxIsPathUnderRoot;
begin
  // The path must have the root as a prefix.
  Result := RtlxPrefixString(Root, Path);

  // Prevent scenarios like C:\foobar being condidered as a path under C:\foo
  if Result and (Length(Path) > Length(Root)) then
    Result := Path[High(Root) + 1] = '\'
end;

end.
