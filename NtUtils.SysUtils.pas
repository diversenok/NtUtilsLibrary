unit NtUtils.SysUtils;

{
  The module includes miscellaneous functions to compensate for missing
  System.SysUtils.
}

interface

// Strings

// Create string from a potenrially zero-terminated buffer
procedure RtlxSetStringW(
  out S: String;
  Buffer: PWideChar;
  MaxLength: Cardinal
);

// Make a string by repeating a character
function RtlxBuildString(
  Char: WideChar;
  Count: Cardinal
): String;

// Check if a string has a matching prefix
function RtlxPrefixString(
  const Prefix: String;
  const S: String;
  CaseInSensitive: Boolean = False
): Boolean;

// Integers

// Convert a 32-bit integer to a string
function RtlxIntToStr(
  Value: Cardinal;
  Base: Cardinal = 10;
  Width: Cardinal = 0
): String;

// Convert a 64-bit integer to a string
function RtlxInt64ToStr(
  Value: UInt64;
  Base: Cardinal = 10;
  Width: Cardinal = 0
): String;

// Convert a string to an integer
function RtlxStrToInt(
  S: String;
  out Value: Cardinal;
  Base: Cardinal = 10
): Boolean;

// GUIDs

// Convert a GUID to a string
function RtlxGuidToString(const Guid: TGuid): String;

// Paths

// Convert a filename from a Native format to Win32
function RtlxNtPathToDosPath(Path: String): String;

// Extract a path from a filename
function RtlxExtractPath(FileName: String): String;

// Extract a name from a filename with a path
function RtlxExtractName(FileName: String): String;

implementation

uses
  Winapi.WinNt, Ntapi.ntrtl, Ntapi.ntdef;

procedure RtlxSetStringW;
var
  Finish: PWideChar;
  Count: Cardinal;
begin
  Finish := Buffer;
  Count := 0;

  while (Count < MaxLength) and (Finish^ <> #0) do
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

function RtlxPrefixString;
begin
  Result := RtlPrefixUnicodeString(TNtUnicodeString.From(Prefix),
    TNtUnicodeString.From(S), CaseInSensitive);
end;

function RtlxIntToStr;
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

function RtlxInt64ToStr;
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

function RtlxStrToInt;
begin
  Result := NT_SUCCESS(RtlUnicodeStringToInteger(TNtUnicodeString.From(S), Base,
    Value));
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

end.
