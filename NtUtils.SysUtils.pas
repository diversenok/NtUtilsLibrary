unit NtUtils.SysUtils;

interface

// Strings

// Create string from a potenrially zero-terminated buffer
procedure RtlxSetStringW(out S: String; Buffer: PWideChar; MaxLength: Cardinal);

function RtlxBuildString(Char: WideChar; Count: Cardinal): String;
function RtlxPrefixString(const SubString, S: String;
  CaseInSensitive: Boolean = False): Boolean;

// Integers

function RtlxIntToStr(Value: Cardinal; Base: Cardinal = 10; Width: Cardinal = 0)
  : String; overload;
function RtlxIntToStr(Value: UInt64; Base: Cardinal = 10; Width: Cardinal = 0)
  : String; overload;

function RtlxStrToInt(var Value: Cardinal; S: String; Base: Cardinal = 10):
  Boolean;

// GUIDs

function RtlxGuidToString(const Guid: TGuid): String;

// Paths

function RtlxNtPathToDosPath(Path: String): String;

implementation

uses
  Winapi.WinNt, Ntapi.ntrtl, Ntapi.ntdef;

procedure RtlxSetStringW(out S: String; Buffer: PWideChar; MaxLength: Cardinal);
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

function RtlxBuildString(Char: WideChar; Count: Cardinal): String;
var
  i: Integer;
begin
  SetLength(Result, Count);

  for i := Low(Result) to High(Result) do
    Result[i] := Char;
end;

function RtlxPrefixString(const SubString, S: String;
  CaseInSensitive: Boolean): Boolean;
begin
  Result := RtlPrefixUnicodeString(TNtUnicodeString.From(SubString),
    TNtUnicodeString.From(S), CaseInSensitive);
end;

function RtlxIntToStr(Value: Cardinal; Base: Cardinal; Width: Cardinal): String;
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

function RtlxIntToStr(Value: UInt64; Base: Cardinal; Width: Cardinal): String;
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

function RtlxStrToInt(var Value: Cardinal; S: String; Base: Cardinal): Boolean;
begin
  Result := NT_SUCCESS(RtlUnicodeStringToInteger(TNtUnicodeString.From(S), Base,
    Value));
end;

function RtlxGuidToString(const Guid: TGuid): String;
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

function RtlxNtPathToDosPath(Path: String): String;
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

end.
