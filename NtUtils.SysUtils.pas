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
procedure RtlxSetStringW(
  out S: String;
  [in] Buffer: PWideChar;
  MaxChars: Cardinal
);

// Make a string by repeating a character
function RtlxBuildString(
  Char: WideChar;
  Count: Cardinal
): String;

// Convert an array of strings to multi-zero-terminated string
function RtlxBuildMultiSz(
  const Strings: TArray<String>
): IMemory<PMultiSzWideChar>;

// Convert a multi-zero-terminated string into an array of string
function RtlxParseMultiSz(
  [in] Buffer: PMultiSzWideChar;
  MaximumLength: Cardinal = $FFFFFFFF
): TArray<String>;

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

// Convert a filename from a Native format to Win32
function RtlxNtPathToDosPath(
  const Path: String
): String;

// Extract a path from a filename
function RtlxExtractPath(
  const FileName: String
): String;

// Extract a name from a filename with a path
function RtlxExtractName(
  const FileName: String
): String;

function RtlxIsPathUnderRoot(
  const Path: String;
  const Root: String
): Boolean;

implementation

uses
  Ntapi.ntrtl, Ntapi.ntdef, Ntapi.crt;

procedure RtlxSetStringW;
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

  SetString(S, Buffer, Count);
end;

function RtlxBuildString;
var
  i: Integer;
begin
  SetLength(Result, Count);

  for i := Low(Result) to High(Result) do
    Result[i] := Char;
end;

function RtlxBuildMultiSz;
var
  S: String;
  Size: Cardinal;
  Buffer: PMultiSzWideChar;
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

function RtlxParseMultiSz;
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
  RtlpSeed: Cardinal;

function RtlxRandom: Cardinal;
begin
  Result := RtlUniform(RtlpSeed)
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

function RtlxNtPathToDosPath;
const
  DOS_DEVICES = '\??\';
  SYSTEM_ROOT = '\SystemRoot';
begin
  Result := Path;

  // Remove the DOS devices prefix
  if RtlxPrefixString(DOS_DEVICES, Result) then
    Delete(Result, Low(String), Length(DOS_DEVICES))

  // Expand the SystemRoot symlink
  else if RtlxPrefixString(SYSTEM_ROOT, Result) then
    Result := USER_SHARED_DATA.NtSystemRoot + Copy(Result,
      Succ(Length(SYSTEM_ROOT)), Length(Result))

  // Otherwise, follow the symlink to the global root of the namespace
  else Result := '\\.\Global\GLOBALROOT' + Path;
end;

function RtlxExtractPath;
var
  pFileName, pDelimiter: PWideChar;
begin
  pFileName := PWideChar(FileName);
  pDelimiter := wcsrchr(pFileName, '\');

  if Assigned(pDelimiter) then
    Result := Copy(FileName, 0, (UIntPtr(pDelimiter) - UIntPtr(pFileName)) div
      SizeOf(WideChar))
  else
    Result := FileName;
end;

function RtlxExtractName;
var
  pFileName, pDelimiter: PWideChar;
begin
  pFileName := PWideChar(FileName);
  pDelimiter := wcsrchr(pFileName, '\');

  if Assigned(pDelimiter) then
    Result := Copy(FileName, (UIntPtr(pDelimiter) - UIntPtr(pFileName)) div
      SizeOf(WideChar) + Cardinal(Low(String)) + 1, Length(FileName))
  else
    Result := FileName;
end;

function RtlxIsPathUnderRoot;
begin
  // The path must have the root as a prefix.
  Result := RtlxPrefixString(Root, Path);

  // Prevent scenarios like C:\foobar being condidered as a path under C:\foo
  if Result and (Length(Path) > Length(Root)) then
    Result := Path[High(Root) + 1] = '\'
end;

initialization
  RtlpSeed := USER_SHARED_DATA.GetTickCount xor $55555555;
finalization
end.
