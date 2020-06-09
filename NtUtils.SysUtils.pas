unit NtUtils.SysUtils;

interface

// Strings

function RtlxBuildString(Char: WideChar; Count: Cardinal): String;
function RtlxPrefixString(const SubString, S: String;
  CaseInSensitive: Boolean = False): Boolean;

// Integers

function RtlxIntToStr(Value: Cardinal; Base: Cardinal = 10; Width: Cardinal = 0)
  : String;
function RtlxInt64ToStr(Value: UInt64; Base: Cardinal = 10; Width: Cardinal = 0)
  : String;

// GUIDs

function RtlxGuidToString(const Guid: TGuid): String;

implementation

uses
  Ntapi.ntrtl, Ntapi.ntdef;

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

function RtlxInt64ToStr(Value: UInt64; Base: Cardinal; Width: Cardinal): String;
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

end.
