unit NtUtils.SysUtils;

{
  The module includes miscellaneous functions to compensate for missing
  System.SysUtils.
}

interface

uses
  Ntapi.WinNt, NtUtils, DelphiUtils.AutoObjects, DelphiUtils.Arrays,
  DelphiApi.Reflection;

const
  BOM_LE = #$FEFF;
  BOM_BE = #$FFFE;
  DEFAULT_PATH_SEPARATOR = '\';
  DEFAULT_EXTENSION_SEPARATOR = '.';

type
  TIntegerSize = (
    isByte,
    isWord,
    isCardinal,
    isUInt64,
    isUIntPtr =
      {$IF SizeOf(UIntPtr) = SizeOf(UInt64)}isUInt64{$ELSE}isCardinal{$ENDIF}
  );

  TNumericSystem = (nsBinary, nsOctal, nsDecimal, nsHexadecimal);
  TNumericSystems = set of TNumericSystem;

  TRtlxParameterLocation = record
    FirstCharIndex: Integer;
    LastCharIndex: Integer;
  end;

const
  NUMERIC_SYSTEM_RADIX: array [TNumericSystem] of Byte = (2, 8, 10, 16);

// Strings

// Return a string if non-empty or a default string
function RtlxStringOrDefault(
  [opt] const Value: String;
  const Default: String
): String;

// Create string from a potentially zero-terminated buffer
function RtlxCaptureString(
  [in] Buffer: PWideChar;
  MaxChars: Cardinal
): String;

// Change byte order for each character of a string
procedure RtlxSwapEndiannessString(
  var S: String
);

// Create a string from a buffer honoring its byte order mask
function RtlxSetStringWithEndian(
  Buffer: PWideChar;
  Length: Cardinal
): String;

// Create string from a potentially zero-terminated buffer
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
  [NumberOfElements] MaximumLength: Cardinal = $FFFFFFFF
): TArray<String>;

// Convert an ANSI multi-zero-terminated string into an array of string
function RtlxParseAnsiMultiSz(
  [in] Buffer: PAnsiMultiSz;
  [NumberOfElements] MaximumLength: Cardinal = $FFFFFFFF
): TArray<AnsiString>;

// Compare two unicode strings in a case-(in)sensitive way
function RtlxCompareStrings(
  const StringA: String;
  const StringB: String;
  CaseSensitive: Boolean = False
): Integer;

// Get a comparer callback for string arrays
function RtlxGetStringComparer(
  CaseSensitive: Boolean = False
): TComparer<String>;

// Compare two ANSI strings in a case-(in)sensitive way
function RtlxCompareAnsiStrings(
  const StringA: AnsiString;
  const StringB: AnsiString;
  CaseSensitive: Boolean = False
): Integer;

// Get a comparer callback for ANSI string arrays
function RtlxGetAnsiStringComparer(
  CaseSensitive: Boolean = False
): TComparer<AnsiString>;

// Check if two unicode strings are equal in a case-(in)sensitive way
function RtlxEqualStrings(
  const StringA: String;
  const StringB: String;
  CaseSensitive: Boolean = False
): Boolean;

// Get an equality check callback for string arrays
function RtlxGetEqualityCheckString(
  CaseSensitive: Boolean = False
): TEqualityCheck<String>;

// Check if two ANSI strings are equal in a case-(in)sensitive way
function RtlxEqualAnsiStrings(
  const StringA: AnsiString;
  const StringB: AnsiString;
  CaseSensitive: Boolean = False
): Boolean;

// Get an equality check callback for ANSI string arrays
function RtlxGetEqualityCheckAnsiString(
  CaseSensitive: Boolean = False
): TEqualityCheck<AnsiString>;

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

// Check if a string has a matching prefix and remove it
function RtlxPrefixStripString(
  const Prefix: String;
  var S: String;
  CaseSensitive: Boolean = False
): Boolean;

// Check if an ANSI string has a matching prefix
function RtlxPrefixAnsiString(
  const Prefix: AnsiString;
  const S: AnsiString;
  CaseSensitive: Boolean = False
): Boolean;

// Check if an ANSI string has a matching prefix and remove it
function RtlxPrefixStripAnsiString(
  const Prefix: AnsiString;
  var S: AnsiString;
  CaseSensitive: Boolean = False
): Boolean;

// Check if a string has a matching suffix
function RtlxSuffixString(
  const Suffix: String;
  const S: String;
  CaseSensitive: Boolean = False
): Boolean;

// Check if a string has a matching suffix and remove it
function RtlxSuffixStripString(
  const Suffix: String;
  var S: String;
  CaseSensitive: Boolean = False
): Boolean;

// Convert a string to lower case
function RtlxLowerString(
  const Source: String
): String;

// Convert a string to upper case
function RtlxUpperString(
  const Source: String
): String;

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

// Switch a 32-bit integer between big- and little-endian
function RtlxSwapEndianness(
  Value: Cardinal
): Cardinal;

// Convert a 32-bit integer to a string
function RtlxUIntToStr(
  Value: Cardinal;
  Base: TNumericSystem = nsHexadecimal;
  Width: Cardinal = 0;
  PrefixBases: TNumericSystems = [nsBinary, nsOctal, nsHexadecimal]
): String;

// Convert a 64-bit integer to a string
function RtlxUInt64ToStr(
  Value: UInt64;
  Base: TNumericSystem = nsHexadecimal;
  Width: Cardinal = 0;
  PrefixBases: TNumericSystems = [nsBinary, nsOctal, nsHexadecimal]
): String;

// Convert a native-size integer to a string
function RtlxUIntPtrToStr(
  Value: UIntPtr;
  Base: TNumericSystem = nsHexadecimal;
  Width: Cardinal = 0;
  PrefixBases: TNumericSystems = [nsBinary, nsOctal, nsHexadecimal]
): String;

// Convert a pointer value to a string
function RtlxPtrToStr(
  Value: Pointer;
  Width: Cardinal = 8;
  AddHexPrefix: Boolean = True
): String;

// Convert a string to an 64-bit integer
function RtlxStrToUInt64(
  const S: String;
  out Value: UInt64;
  DefaultBase: TNumericSystem = nsDecimal;
  RecognizeBases: TNumericSystems = [nsDecimal, nsHexadecimal];
  AllowMinusSign: Boolean = True;
  ValueSize: TIntegerSize = isUInt64
): Boolean;

// Convert a string to a 32-bit integer
function RtlxStrToUInt(
  const S: String;
  out Value: Cardinal;
  DefaultBase: TNumericSystem = nsDecimal;
  RecognizeBases: TNumericSystems = [nsDecimal, nsHexadecimal];
  AllowMinusSign: Boolean = True
): Boolean;

// Convert a string to a natively-sized integer
function RtlxStrToUIntPtr(
  const S: String;
  out Value: UIntPtr;
  DefaultBase: TNumericSystem = nsDecimal;
  RecognizeBases: TNumericSystems = [nsDecimal, nsHexadecimal];
  AllowMinusSign: Boolean = True
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

// Try to parse a string containing a GUID
function RtlxStringToGuid(
  const GuidString: String;
  out Guid: TGuid
): TNtxStatus;

// Paths

// Split the path into the parent (directory) and child (filename) components
function RtlxSplitPath(
  const Path: String;
  out ParentName: String;
  out ChildName: String;
  const PathSeparator: Char = DEFAULT_PATH_SEPARATOR
): Boolean;

// Extract a parent component from a path
function RtlxExtractRootPath(
  const Path: String;
  const PathSeparator: Char = DEFAULT_PATH_SEPARATOR
): String;

// Extract a child component from a path
function RtlxExtractNamePath(
  const Path: String;
  const PathSeparator: Char = DEFAULT_PATH_SEPARATOR
): String;

// Extract a file extension a path
function RtlxExtractExtensionPath(
  const Path: String;
  const PathSeparator: Char = DEFAULT_PATH_SEPARATOR;
  const ExtensionSeparator: Char = DEFAULT_EXTENSION_SEPARATOR
): String;

// Construct a filename with a different extension
function RtlxReplaceExtensionPath(
  const Path: String;
  const NewExtension: String;
  const PathSeparator: Char = DEFAULT_PATH_SEPARATOR;
  const ExtensionSeparator: Char = DEFAULT_EXTENSION_SEPARATOR
): String;

// Check if one path is under another path
// NOTE: only use on normalized & final paths
function RtlxIsPathUnderRoot(
  const Path: String;
  const Root: String;
  const PathSeparator: Char = DEFAULT_PATH_SEPARATOR
): Boolean;

// Join to strings using a path separator
function RtlxCombinePaths(
  const Parent: String;
  const Child: String;
  const PathSeparator: Char = DEFAULT_PATH_SEPARATOR
): String;

// Comman lines

// Splits the command line into parameters.
// When given an image name, will try to recognize it as the zero parameter.
function RtlxParseCommandLine(
  const CommandLine: String;
  [opt] const ImageName: String = ''
): TArray<TRtlxParameterLocation>;

// Determine the number of available command line parameter
function RtlxParamCount: Integer;

// Retrieve a command line parameter by index
function RtlxParamStr(
  Index: Integer;
  Unquote: Boolean = True
): String;

// Retrieve all command line parameters starting from an index
function RtlxParamStrFrom(
  Index: Integer
): String;

implementation

uses
  Ntapi.ntrtl, Ntapi.ntdef, Ntapi.crt, Ntapi.ntpebteb, NtUtils.Synchronization;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function RtlxStringOrDefault;
begin
  if Value <> '' then
    Result := Value
  else
    Result := Default;
end;

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

procedure RtlxSwapEndiannessString;
var
  i: Integer;
begin
  for i := Low(S) to High(S) do
    S[i] := Chr((Word(Ord(S[i])) shr 8) or (Word(Ord(S[i])) shl 8));
end;

function RtlxSetStringWithEndian;
begin
  if Length < 1 then
    Exit('');

  if (Buffer[0] = BOM_LE) or (Buffer[0] = BOM_BE) then
  begin
    // Known bytes order; skip it and copy the rest
    SetString(Result, PWideChar(@Buffer[1]), Pred(Length));

    // Swap order if necessary
    if Buffer[0] = BOM_BE then
      RtlxSwapEndiannessString(Result);
  end
  else
  begin
    // Unspecified; copy entirely
    SetString(Result, Buffer, Length);
  end;
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
  i: Integer;
  Size: Cardinal;
  Buffer: PWideMultiSz;
begin
  // Always include two terminating zeros
  Size := 2 * SizeOf(WideChar);

  for i := 0 to High(Strings) do
    Inc(Size, StringSizeZero(Strings[i]));

  // Allocate a buffer for all strings + additional zero terminators
  IMemory(Result) := Auto.AllocateDynamic(Size);
  Buffer := Result.Data;

  for i := 0 to High(Strings) do
  begin
    MarshalString(Strings[i], Buffer);
    Inc(PByte(Buffer), StringSizeZero(Strings[i]));
  end;
end;

function RtlxBuildAnsiMultiSz;
var
  i: Integer;
  Size: Cardinal;
  Buffer: PAnsiMultiSz;
begin
  // Always include two terminating zeros
  Size := 2 * SizeOf(AnsiChar);

  for i := 0 to High(Strings) do
    Inc(Size, Succ(Length(Strings[i])) * SizeOf(AnsiChar));

  // Allocate a buffer for all strings + additional zero terminators
  Imemory(Result) := Auto.AllocateDynamic(Size);
  Buffer := Result.Data;

  for i := 0 to High(Strings) do
  begin
    Size := Succ(Length(Strings[i])) * SizeOf(AnsiChar);
    Move(PAnsiChar(Strings[i])^, Buffer^, Size);
    Inc(PByte(Buffer), Size);
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
var
  StringAStr, StringBStr: TNtUnicodeString;
  RemainingLengthA, RemainingLengthB: Cardinal;
begin
  // RtlCompareUnicodeString uses UNICODE_STRINGs which can only address
  // up to 32k characters. For longer strings, perform comparison in blocks.

  StringAStr.Buffer := PWideChar(StringA);
  StringBStr.Buffer := PWideChar(StringB);

  RemainingLengthA := Length(StringA);
  RemainingLengthB := Length(StringB);

  repeat
    // Compute the size of a block for string A
    if RemainingLengthA > MAX_UNICODE_STRING then
    begin
      StringAStr.Length := MAX_UNICODE_STRING * SizeOf(WideChar);
      Dec(RemainingLengthA, MAX_UNICODE_STRING);
    end
    else
    begin
      StringAStr.Length := RemainingLengthA * SizeOf(WideChar);
      RemainingLengthA := 0;
    end;

    StringAStr.MaximumLength := StringAStr.Length;

    // Compute the size of a block for string B
    if RemainingLengthB > MAX_UNICODE_STRING then
    begin
      StringBStr.Length := MAX_UNICODE_STRING * SizeOf(WideChar);
      Dec(RemainingLengthB, MAX_UNICODE_STRING);
    end
    else
    begin
      StringBStr.Length := RemainingLengthB * SizeOf(WideChar);
      RemainingLengthB := 0;
    end;

    StringBStr.MaximumLength := StringBStr.Length;

    // Compare the string blocks
    Result := RtlCompareUnicodeString(StringAStr, StringBStr, not CaseSensitive);

    // Did it find a difference already?
    if Result <> 0 then
      Break;

    // Did both strings run out?
    if (RemainingLengthA = 0) and (RemainingLengthB = 0) then
      Break;

    // Advance the buffers to the next block
    Inc(PByte(StringAStr.Buffer), StringAStr.Length);
    Inc(PByte(StringBStr.Buffer), StringBStr.Length);
  until False;
end;

function RtlxGetStringComparer;
begin
  Result := function (const A, B: String): Integer
    begin
      Result := RtlxCompareStrings(A, B, CaseSensitive);
    end;
end;

function RtlxCompareAnsiStrings;
var
  StringAStr, StringBStr: TNtAnsiString;
  RemainingLengthA, RemainingLengthB: Cardinal;
begin
  // RtlCompareString uses ANSI_STRINGs which can only address up to 65k
  // characters. For longer strings, perform comparison in blocks.

  StringAStr.Buffer := PAnsiChar(StringA);
  StringBStr.Buffer := PAnsiChar(StringB);

  RemainingLengthA := Length(StringA);
  RemainingLengthB := Length(StringB);

  repeat
    // Compute the size of a block for string A
    if RemainingLengthA > MAX_ANSI_STRING then
    begin
      StringAStr.Length := MAX_ANSI_STRING * SizeOf(AnsiChar);
      Dec(RemainingLengthA, MAX_ANSI_STRING);
    end
    else
    begin
      StringAStr.Length := RemainingLengthA * SizeOf(AnsiChar);
      RemainingLengthA := 0;
    end;

    StringAStr.MaximumLength := StringAStr.Length;

    // Compute the size of a block for string B
    if RemainingLengthB > MAX_ANSI_STRING then
    begin
      StringBStr.Length := MAX_ANSI_STRING * SizeOf(AnsiChar);
      Dec(RemainingLengthB, MAX_ANSI_STRING);
    end
    else
    begin
      StringBStr.Length := RemainingLengthB * SizeOf(AnsiChar);
      RemainingLengthB := 0;
    end;

    StringBStr.MaximumLength := StringBStr.Length;

    // Compare the string blocks
    Result := RtlCompareString(StringAStr, StringBStr, not CaseSensitive);

    // Did it find a difference already?
    if Result <> 0 then
      Break;

    // Did both strings run out?
    if (RemainingLengthA = 0) and (RemainingLengthB = 0) then
      Break;

    // Advance the buffers to the next block
    Inc(PByte(StringAStr.Buffer), StringAStr.Length);
    Inc(PByte(StringBStr.Buffer), StringBStr.Length);
  until False;
end;

function RtlxGetAnsiStringComparer;
begin
  Result := function (const A, B: AnsiString): Integer
    begin
      Result := RtlxCompareAnsiStrings(A, B, CaseSensitive);
    end;
end;

function RtlxEqualStrings;
var
  StringAStr, StringBStr: TNtUnicodeString;
  RemainingLength: Cardinal;
begin
  // Shortcut for strings of different lengths
  if Length(StringA) <> Length(StringB) then
    Exit(False);

  // RtlEqualUnicodeString uses UNICODE_STRINGs which can only address
  // up to 32k characters. For longer strings, perform comparison in blocks.

  StringAStr.Buffer := PWideChar(StringA);
  StringBStr.Buffer := PWideChar(StringB);
  RemainingLength := Length(StringA);

  repeat
    // Compute the size of a block
    if RemainingLength > MAX_UNICODE_STRING then
    begin
      StringAStr.Length := MAX_UNICODE_STRING * SizeOf(WideChar);
      StringBStr.Length := MAX_UNICODE_STRING * SizeOf(WideChar);
      Dec(RemainingLength, MAX_UNICODE_STRING);
    end
    else
    begin
      StringAStr.Length := RemainingLength * SizeOf(WideChar);
      StringBStr.Length := RemainingLength * SizeOf(WideChar);
      RemainingLength := 0;
    end;

    StringAStr.MaximumLength := StringAStr.Length;
    StringBStr.MaximumLength := StringBStr.Length;

    // Compare the string blocks
    Result := RtlEqualUnicodeString(StringAStr, StringBStr, not CaseSensitive);

    // Did it find a difference already?
    if not Result then
      Break;

    // Did the strings run out?
    if RemainingLength = 0 then
      Break;

    // Advance the buffers to the next block
    Inc(PByte(StringAStr.Buffer), StringAStr.Length);
    Inc(PByte(StringBStr.Buffer), StringBStr.Length);
  until False;
end;

function RtlxGetEqualityCheckString;
begin
  Result := function (const A, B: String): Boolean
    begin
      Result := RtlxEqualStrings(A, B, CaseSensitive);
    end;
end;

function RtlxEqualAnsiStrings;
var
  StringAStr, StringBStr: TNtAnsiString;
  RemainingLength: Cardinal;
begin
  // Shortcut for strings of different lengths
  if Length(StringA) <> Length(StringB) then
    Exit(False);

  // RtlEqualString uses ANSI_STRINGs which can only address up to 65k
  // characters. For longer strings, perform comparison in blocks.

  StringAStr.Buffer := PAnsiChar(StringA);
  StringBStr.Buffer := PAnsiChar(StringB);
  RemainingLength := Length(StringA);

  repeat
    // Compute the size of a block
    if RemainingLength > MAX_ANSI_STRING then
    begin
      StringAStr.Length := MAX_ANSI_STRING * SizeOf(AnsiChar);
      StringBStr.Length := MAX_ANSI_STRING * SizeOf(AnsiChar);
      Dec(RemainingLength, MAX_ANSI_STRING);
    end
    else
    begin
      StringAStr.Length := RemainingLength * SizeOf(AnsiChar);
      StringBStr.Length := RemainingLength * SizeOf(AnsiChar);
      RemainingLength := 0;
    end;

    StringAStr.MaximumLength := StringAStr.Length;
    StringBStr.MaximumLength := StringBStr.Length;

    // Compare the string blocks
    Result := RtlEqualString(StringAStr, StringBStr, not CaseSensitive);

    // Did it find a difference already?
    if not Result then
      Break;

    // Did the strings run out?
    if RemainingLength = 0 then
      Break;

    // Advance the buffers to the next block
    Inc(PByte(StringAStr.Buffer), StringAStr.Length);
    Inc(PByte(StringBStr.Buffer), StringBStr.Length);
  until False;
end;

function RtlxGetEqualityCheckAnsiString;
begin
  Result := function (const A, B: AnsiString): Boolean
    begin
      Result := RtlxEqualAnsiStrings(A, B, CaseSensitive);
    end;
end;

function RtlxHashString;
var
  SourceStr: TNtUnicodeString;
begin
  if not RtlxInitUnicodeString(SourceStr, Source).IsSuccess or not
    NT_SUCCESS(RtlHashUnicodeString(SourceStr, not CaseSensitive,
    HASH_STRING_ALGORITHM_DEFAULT, Result)) then
    Result := Length(Source);
end;

function RtlxPrefixString;
begin
  if Length(Prefix) > Length(S) then
    Exit(False);

  Result := RtlxEqualStrings(Prefix, Copy(S, 1, Length(Prefix)), CaseSensitive);
end;

function RtlxPrefixStripString;
begin
  Result := RtlxPrefixString(Prefix, S, CaseSensitive);

  if Result then
    Delete(S, Low(S), Length(Prefix));
end;

function RtlxPrefixAnsiString;
begin
  if Length(Prefix) > Length(S) then
    Exit(False);

  Result := RtlxEqualAnsiStrings(Prefix, Copy(S, 1, Length(Prefix)),
    CaseSensitive);
end;

function RtlxPrefixStripAnsiString;
begin
  Result := RtlxPrefixAnsiString(Prefix, S, CaseSensitive);

  if Result then
    Delete(S, Low(S), Length(Prefix));
end;

function RtlxSuffixString;
begin
  if Length(Suffix) > Length(S) then
    Exit(False);

  Result := RtlxEqualStrings(Suffix, Copy(S, Length(S) - Length(Suffix) + 1,
    Length(Suffix)), CaseSensitive);
end;

function RtlxSuffixStripString;
begin
  Result := RtlxSuffixString(Suffix, S, CaseSensitive);

  if Result then
    Delete(S, Low(S) + High(S) - Length(Suffix), Length(Suffix));
end;

function RtlxLowerString;
var
  i: Integer;
begin
  // Make a writable unique copy to modify
  Result := Source;
  UniqueString(Result);

  for i := Low(Result) to High(Result) do
    Result[i] := RtlDowncaseUnicodeChar(Result[i]);
end;

function RtlxUpperString;
var
  i: Integer;
begin
  // Make a writable unique copy to modify
  Result := Source;
  UniqueString(Result);

  for i := Low(Result) to High(Result) do
    Result[i] := RtlUpcaseUnicodeChar(Result[i]);
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
      vtInt64:         Int64(Buffer^) := Args[i].VInt64^;
      vtUnicodeString: Pointer(Buffer^) := Args[i].VUnicodeString;
    end;

    Inc(PByte(Buffer), SizeOf(Pointer));
  end;
end;

function RtlxFormatString;
var
  Buffer: IMemory<PWideChar>;
  VarArgsBuffer: IMemory;
  NewSize: Cardinal;
  Count: Integer;
begin
  NewSize := $100;
  VarArgsBuffer := RtlxpAllocateVarArgs(Args);

  repeat
    IMemory(Buffer) := Auto.AllocateDynamic(NewSize);

    Count := vswprintf_s(Buffer.Data, Buffer.Size div SizeOf(WideChar),
      PWideChar(Format), VarArgsBuffer.Data);

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

function RtlxSwapEndianness;
begin
  Result := (Value shr 24) or (Value shl 24) or
    ((Value and $00FF0000) shr 8) or ((Value and $0000FF00) shl 8);
end;

function RtlxUIntToStr;
var
  Str: TNtUnicodeString;
  Buffer: array [0..32] of WideChar;
begin
  Str.Length := 0;
  Str.MaximumLength := SizeOf(Buffer);
  Str.Buffer := @Buffer[0];

  if not NT_SUCCESS(RtlIntegerToUnicodeString(Value, NUMERIC_SYSTEM_RADIX[Base],
    Str)) then
    Exit('');

  Result := Str.ToString;

  if Length(Result) < Integer(Width) then
    Result := RtlxBuildString('0', Integer(Width) - Length(Result)) + Result;

  if Base in PrefixBases then
    case Base of
      nsBinary:      Result := '0b' + Result;
      nsOctal:       Result := '0o' + Result;
      nsDecimal:     Result := '0n' + Result;
      nsHexadecimal: Result := '0x' + Result;
    end;
end;

function RtlxUInt64ToStr;
var
  Str: TNtUnicodeString;
  Buffer: array [0..64] of WideChar;
begin
  Str.Length := 0;
  Str.MaximumLength := SizeOf(Buffer);
  Str.Buffer := @Buffer[0];

  if not NT_SUCCESS(RtlInt64ToUnicodeString(Value, NUMERIC_SYSTEM_RADIX[Base],
    Str)) then
    Exit('');

  Result := Str.ToString;

  if Length(Result) < Integer(Width) then
    Result := RtlxBuildString('0', Integer(Width) - Length(Result)) + Result;

  if Base in PrefixBases then
    case Base of
      nsBinary:      Result := '0b' + Result;
      nsOctal:       Result := '0o' + Result;
      nsDecimal:     Result := '0n' + Result;
      nsHexadecimal: Result := '0x' + Result;
    end;
end;

function RtlxUIntPtrToStr;
begin
  {$IF SizeOf(Value) = SizeOf(UInt64)}
  Result := RtlxUInt64ToStr(Value, Base, Width, PrefixBases);
  {$ELSE}
  Result := RtlxUIntToStr(Value, Base, Width, PrefixBases);
  {$ENDIF}
end;

function RtlxPtrToStr;
const
  PREFIX_BASES: array [Boolean] of TNumericSystems = ([], [nsHexadecimal]);
begin
  Result := RtlxUIntPtrToStr(UIntPtr(Value), nsHexadecimal, Width,
    PREFIX_BASES[AddHexPrefix <> False]);
end;

function RtlxStrToUInt64;
const
  MAX_VALUE: array [TIntegerSize] of UInt64 = (Byte(-1), Word(-1), Cardinal(-1),
    UInt64(-1));
var
  Cursor: PWideChar;
  Remaining: Cardinal;
  Negate: Boolean;
  CurrentSystem: TNumericSystem;
  Accumulated: UInt64;
  CurrentDigit: Byte;
  MaxNonOverflow: UInt64;
begin
  Result := False;

  if Length(S) <= 0 then
    Exit;

  Cursor := PWideChar(S);
  Remaining := Length(S); // including the cursor
  Negate := False;
  CurrentSystem := DefaultBase;
  Accumulated := 0;

  // Check for the minus sign
  if AllowMinusSign and (Remaining >= 1) and (Cursor[0] = '-') then
  begin
    Negate := True;
    Inc(Cursor);
    Dec(Remaining);
  end;

  repeat
    // Check for the numeric system
    if (RecognizeBases <> []) and (Remaining >= 2) and (Cursor[0] = '0') then
    begin
      case Cursor[1] of
        'b', 'B': CurrentSystem := nsBinary;
        'o', 'O': CurrentSystem := nsOctal;
        'n', 'N': CurrentSystem := nsDecimal;
        'x', 'X': CurrentSystem := nsHexadecimal;
      else
        Break;
      end;

      if not (CurrentSystem in RecognizeBases) then
      begin
        // Undo recognition when the caller explicitly disabled the one we got
        CurrentSystem := DefaultBase;
        Break;
      end;

      // Consume the characters
      Inc(Cursor, 2);
      Dec(Remaining, 2);
    end;
  until True;

  if Remaining <= 0 then
    Exit;

  MaxNonOverflow := MAX_VALUE[ValueSize] div NUMERIC_SYSTEM_RADIX[CurrentSystem];

  // The bulk of parsing
  while Remaining > 0 do
  begin
    case Cursor[0] of
      '0'..'9': CurrentDigit := Ord(Cursor[0]) - Ord('0') + $0;
      'a'..'f': CurrentDigit := Ord(Cursor[0]) - Ord('a') + $a;
      'A'..'F': CurrentDigit := Ord(Cursor[0]) - Ord('A') + $A;
    else
      Exit;
    end;

    if CurrentDigit >= NUMERIC_SYSTEM_RADIX[CurrentSystem] then
      Exit;

    // Make sure shifting doesn't cause an overflow
    if Accumulated > MaxNonOverflow then
      Exit;

    {$Q-}
    Accumulated := Accumulated * NUMERIC_SYSTEM_RADIX[CurrentSystem];
    {$IFDEF Q+}{$Q+}{$ENDIF}

    // Make sure digit addition doesn't cause an overflow
    if Accumulated > (MAX_VALUE[ValueSize] - CurrentDigit) then
      Exit;

    {$Q-}
    Inc(Accumulated, CurrentDigit);
    {$IFDEF Q+}{$Q+}{$ENDIF}

    Inc(Cursor);
    Dec(Remaining);
  end;

  {$Q-}
  if Negate then
    Accumulated := -Accumulated;
  {$IFDEF Q+}{$Q+}{$ENDIF}

  Value := Accumulated;
  Result := True;
end;

function RtlxStrToUInt;
var
  Value64: UInt64;
begin
  Result := RtlxStrToUInt64(S, Value64, DefaultBase, RecognizeBases,
    AllowMinusSign, isCardinal);

  if Result then
    Value := Cardinal(Value64);
end;

function RtlxStrToUIntPtr;
var
  Value64: UInt64;
begin
  Result := RtlxStrToUInt64(S, Value64, DefaultBase, RecognizeBases,
    AllowMinusSign, isUIntPtr);

  if Result then
    Value := UIntPtr(Value64)
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

  // Make it UUID version 4
  Result.D3 := (Result.D3 and $0FFF) or $4000;

  // Make it UUID variant 1
  Result.D4[0] := (Result.D4[0] and $3F) or $80;
end;

function RtlxGuidToString;
var
  Buffer: TNtUnicodeString;
  BufferDeallocator: IAutoReleasable;
begin
  Buffer := Default(TNtUnicodeString);

  if not NT_SUCCESS(RtlStringFromGUID(Guid, Buffer)) then
    Exit('');

  BufferDeallocator := RtlxDelayFreeUnicodeString(@Buffer);
  Result := Buffer.ToString;
end;

function RtlxStringToGuid;
var
  GuidStr: TNtUnicodeString;
begin
  Result := RtlxInitUnicodeString(GuidStr, GuidString);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlGUIDFromString';
  Result.Status := RtlGUIDFromString(GuidStr, Guid);
end;

function RtlxSplitPath;
var
  i: Integer;
begin
  for i := High(Path) downto Low(Path) do
    if Path[i] = PathSeparator then
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
    if Path[i] = PathSeparator then
      Exit(Copy(Path, 1, i - Low(Path)));

  Result := Path;
end;

function RtlxExtractNamePath;
var
  i: Integer;
begin
  for i := High(Path) downto Low(Path) do
    if Path[i] = PathSeparator then
      Exit(Copy(Path, i + Low(Path), Length(Path)));

  Result := Path;
end;

function RtlxExtractExtensionPath;
var
  i: Integer;
begin
  for i := High(Path) downto Low(Path) do
    if Path[i] = ExtensionSeparator then
      Exit(Copy(Path, i + Low(Path), Length(Path)))
    else if Path[i] = PathSeparator then
      Break;

  Result := '';
end;

function RtlxReplaceExtensionPath;
var
  i: Integer;
begin
  for i := High(Path) downto Low(Path) do
    if Path[i] = ExtensionSeparator then
      Exit(Copy(Path, 1, i - Low(Path) + 1) + NewExtension)
    else if Path[i] = PathSeparator then
      Break;

  Result := Path + ExtensionSeparator + NewExtension;
end;

function RtlxIsPathUnderRoot;
begin
  // The path must have the root as a prefix.
  Result := RtlxPrefixString(Root, Path);

  // Prevent scenarios like C:\foobar being considered as a path under C:\foo
  if Result and (Length(Path) > Length(Root)) then
    Result := (Path[High(Root) + 1] = PathSeparator)
end;

function RtlxCombinePaths;
begin
  // Make sure concatenation doesn't add two path separators
  if (Length(Parent) > 0) and (Parent[High(Parent)] = PathSeparator) then
    Result := Parent + Child
  else
    Result := Parent + PathSeparator + Child;
end;

// Command lines

function RtlxParseCommandLine(
  const CommandLine: String;
  [opt] const ImageName: String = ''
): TArray<TRtlxParameterLocation>;
var
  InsideParameter, Quoted: Boolean;
  Symbol: WideChar;
  Index: Integer;
begin
  Index := Low(String);
  InsideParameter := False;
  Quoted := False;

  // Recognize the image name in an unquoted form
  if (ImageName <> '') and RtlxPrefixString(ImageName, CommandLine) then
  begin
    SetLength(Result, 1);
    Result[0].FirstCharIndex := Low(ImageName);
    Result[0].LastCharIndex := High(ImageName);
    Inc(Index, Length(ImageName));
  end
  else
    Result := nil;

  for Index := Index to High(CommandLine) do
  begin
    Symbol := CommandLine[Index];

    if not InsideParameter then
    begin
      // Still outside?
      if Symbol = ' ' then
        Continue;

      // Found a start of a parameter
      SetLength(Result, Succ(Length(Result)));
      Result[High(Result)].FirstCharIndex := Index;

      InsideParameter := True;
      Quoted := (Symbol = '"');
    end
    else
    begin
      // Still inside?
      if (Quoted and (Symbol <> '"')) or (not Quoted and (Symbol <> ' ')) then
        Continue;

      // Found an end of a parameter; include quotes but not spaces
      if Quoted then
        Result[High(Result)].LastCharIndex := Index
      else
        Result[High(Result)].LastCharIndex := Pred(Index);

      InsideParameter := False;
      Quoted := False;
    end;
  end;

  // Make sure the of the command line terminates parameters
  if InsideParameter then
    Result[High(Result)].LastCharIndex := High(CommandLine);
end;

var
  FCommandLineParsed: TRtlRunOnce;
  FCommandLine: String;
  FParametersLocations: TArray<TRtlxParameterLocation>;

[ThreadSafe]
procedure RtlxParamMakeSureInitialized;
var
  InitState: IAcquiredRunOnce;
begin
  if RtlxRunOnceBegin(@FCommandLineParsed, InitState) then
  begin
    FCommandLine := RtlGetCurrentPeb.ProcessParameters.CommandLine.ToString;
    FParametersLocations := RtlxParseCommandLine(FCommandLine,
      RtlGetCurrentPeb.ProcessParameters.ImagePathName.ToString);

    InitState.Complete;
  end;
end;

function RtlxParamCount;
begin
  RtlxParamMakeSureInitialized;

  Result := Length(FParametersLocations);
end;

function RtlxParamStr;
var
  First, Last: Integer;
begin
  RtlxParamMakeSureInitialized;

  if (Index < Low(FParametersLocations)) or
    (Index > High(FParametersLocations)) then
    Exit('');

  First := FParametersLocations[Index].FirstCharIndex;
  Last := FParametersLocations[Index].LastCharIndex;

  if Unquote and (FCommandLine[First] = '"') then
    Inc(First);

  if Unquote and (FCommandLine[Last] = '"') then
    Dec(Last);

  Result := Copy(FCommandLine, First - Low(String) + 1, Last - First + 1);
end;

function RtlxParamStrFrom;
begin
  RtlxParamMakeSureInitialized;

  if Index < Low(FParametersLocations) then
    Exit(FCommandLine);

  if Index > High(FParametersLocations) then
    Exit('');

  // Extract everything up to the end
  Result := Copy(FCommandLine, FParametersLocations[Index].FirstCharIndex
    - Low(String) + 1, Length(FCommandLine));
end;

end.
