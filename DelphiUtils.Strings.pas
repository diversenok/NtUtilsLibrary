unit DelphiUtils.Strings;

interface

uses
  Winapi.WinNt, System.TypInfo;

type
  THintSection = record
    Title: String;
    Enabled: Boolean;
    Content: String;
  end;

// Boolean state to string
function EnabledDisabledToString(Value: LongBool): String;
function YesNoToString(Value: LongBool): String;
function CheckboxToString(Value: LongBool): String;
function BytesToString(Size: Cardinal): String;

// Bit flag manipulation
function Contains(Value, Flag: Cardinal): Boolean; inline;
function ContainsAny(Value, Flag: Cardinal): Boolean; inline;

// Converting a set of bit flags to string
function MapFlags(Value: Cardinal; Mapping: array of TFlagName;
  Default: String = ''): String;
function MapFlagsList(Value: Cardinal; Mapping: array of TFlagName): String;

// Create a hint from a set of sections
function BuildHint(Sections: array of THintSection): String;

// Mark a value as out of bound
function OutOfBound(Value: Integer): String;

// Make enumeration names look friendly
function PrettifyCamelCase(CamelCaseText: String;
  Prefix: String = ''; Suffix: String = ''): String;
function PrettifyCamelCaseEnum(TypeInfo: PTypeInfo; Value: Integer;
  Prefix: String = ''; Suffix: String = ''): String;

function PrettifySnakeCase(CapsText: String; Prefix: String = '';
  Suffix: String = ''): String;
function PrettifySnakeCaseEnum(TypeInfo: PTypeInfo; Value: Integer;
  Prefix: String = ''; Suffix: String = ''): String;

// Hex represenation
function IntToHexEx(Value: Int64; Digits: Integer = 0): String; overload;
function IntToHexEx(Value: UInt64; Digits: Integer = 0): String; overload;
function IntToHexEx(Value: Pointer): String; overload;

// String to int conversion
function TryStrToUInt64Ex(S: String; out Value: UInt64): Boolean;
function StrToUIntEx(S: String; Comment: String): Cardinal; inline;
function StrToUInt64Ex(S: String; Comment: String): UInt64; inline;

implementation

uses
  System.SysUtils;

function EnabledDisabledToString(Value: LongBool): String;
begin
  if Value then
    Result := 'Enabled'
  else
    Result := 'Disabled';
end;

function YesNoToString(Value: LongBool): String;
begin
  if Value then
    Result := 'Yes'
  else
    Result := 'No';
end;

function CheckboxToString(Value: LongBool): String;
begin
  if Value then
    Result := '☑'
  else
    Result := '☐';
end;

function BytesToString(Size: Cardinal): String;
begin
  if Size mod 1024 = 0 then
    Result := (Size div 1024).ToString + ' kB'
  else
    Result := Size.ToString + ' B';
end;

function Contains(Value, Flag: Cardinal): Boolean;
begin
  Result := (Value and Flag = Flag);
end;

function ContainsAny(Value, Flag: Cardinal): Boolean;
begin
  Result := (Value and Flag <> 0);
end;

function MapFlags(Value: Cardinal; Mapping: array of TFlagName;
  Default: String): String;
var
  Strings: array of String;
  i, Count: Integer;
begin
  SetLength(Strings, Length(Mapping));

  Count := 0;
  for i := Low(Mapping) to High(Mapping) do
    if Contains(Value, Mapping[i].Value) then
    begin
      Strings[Count] := Mapping[i].Name;
      Inc(Count);
    end;

  SetLength(Strings, Count);

  if Count = 0 then
    Result := Default
  else
    Result := String.Join(', ', Strings);
end;

function MapFlagsList(Value: Cardinal; Mapping: array of TFlagName): String;
var
  Strings: array of string;
  i: Integer;
begin
  SetLength(Strings, Length(Mapping));

  for i := Low(Mapping) to High(Mapping) do
    Strings[i - Low(Mapping)] := CheckboxToString(Contains(Value,
      Mapping[i].Value)) + ' ' + Mapping[i].Name;

  Result := String.Join(#$D#$A, Strings);
end;

function BuildHint(Sections: array of THintSection): String;
var
  Count, i, j: Integer;
  Items: array of String;
begin
  Count := 0;
  for i := Low(Sections) to High(Sections) do
    if Sections[i].Enabled then
      Inc(Count);

  SetLength(Items, Count);

  j := 0;
  for i := Low(Sections) to High(Sections) do
    if Sections[i].Enabled then
    begin
      Items[j] := Sections[i].Title + ':  '#$D#$A'  ' + Sections[i].Content +
        '  ';
      Inc(j);
    end;
  Result := String.Join(#$D#$A, Items);
end;

function OutOfBound(Value: Integer): String;
begin
  Result := IntToStr(Value) + ' (out of bound)';
end;

function PrettifyCamelCase(CamelCaseText: String;
  Prefix: String; Suffix: String): String;
var
  i: Integer;
begin
  // Convert a string with from CamelCase to a spaced string removing prefix,
  // for example: '__MyExampleText' => 'My example text'

  Result := CamelCaseText;

  if Result.StartsWith(Prefix) then
    Delete(Result, Low(Result), Length(Prefix));

  if Result.EndsWith(Suffix) then
    Delete(Result, Length(Result) - Length(Suffix) + 1, Length(Suffix));

  i := Low(Result) + 1;
  while i <= High(Result) do
  begin
    if CharInSet(Result[i], ['A'..'Z']) then
    begin
      Result[i] := Chr(Ord('a') + Ord(Result[i]) - Ord('A'));
      Insert(' ', Result, i);
      Inc(i);
    end;
    Inc(i);
  end;
end;

function PrettifyCamelCaseEnum(TypeInfo: PTypeInfo; Value: Integer;
  Prefix: String; Suffix: String): String;
begin
  if (TypeInfo.Kind = tkEnumeration) and (Value >= TypeInfo.TypeData.MinValue)
    and (Value <= TypeInfo.TypeData.MaxValue) then
    Result := PrettifyCamelCase(GetEnumName(TypeInfo, Integer(Value)), Prefix,
      Suffix)
  else
    Result := OutOfBound(Value);
end;

function PrettifySnakeCase(CapsText: String; Prefix: String = '';
  Suffix: String = ''): String;
var
  i: Integer;
begin
  // Convert a string with from capitals with undescores to a spaced string
  // removing a prefix/suffix, ex.: 'ERROR_ACCESS_DENIED' => 'Acces denied'

  Result := CapsText;

  if Result.StartsWith(Prefix) then
    Delete(Result, Low(Result), Length(Prefix));

  if Result.EndsWith(Suffix) then
    Delete(Result, Length(Result) - Length(Suffix) + 1, Length(Suffix));

  // Capitalize the first letter
  if Length(Result) > 0 then
    case Result[Low(Result)] of
      'a'..'z':
        Result[Low(Result)] := Chr(Ord('A') + Ord(Result[Low(Result)]) -
          Ord('a'));
    end;

  // Lower the rest
  for i := Succ(Low(Result)) to High(Result) do
  begin
    case Result[i] of
      'A'..'Z':
        Result[i] := Chr(Ord('a') + Ord(Result[i]) - Ord('A'));
      '_':
          Result[i] := ' ';
    end;
  end;
end;

function PrettifySnakeCaseEnum(TypeInfo: PTypeInfo; Value: Integer;
  Prefix: String = ''; Suffix: String = ''): String;
begin
  if (TypeInfo.Kind = tkEnumeration) and (Value >= TypeInfo.TypeData.MinValue)
    and (Value <= TypeInfo.TypeData.MaxValue) then
    Result := PrettifySnakeCase(GetEnumName(TypeInfo, Integer(Value)),
      Prefix, Suffix)
  else
    Result := OutOfBound(Value);
end;

function IntToHexEx(Value: UInt64; Digits: Integer): String;
begin
  Result := '0x' + IntToHex(Value, Digits);
end;

function IntToHexEx(Value: Int64; Digits: Integer): String;
begin
  Result := '0x' + IntToHex(Value, Digits);
end;

function IntToHexEx(Value: Pointer): String;
begin
  Result := '0x' + IntToHex(NativeUInt(Value), 8);
end;

function TryStrToUInt64Ex(S: String; out Value: UInt64): Boolean;
var
  E: Integer;
begin
  if S.StartsWith('0x') then
    S := S.Replace('0x', '$', []);

  Val(S, Value, E);
  Result := (E = 0);
end;

function StrToUInt64Ex(S: String; Comment: String): UInt64;
const
  E_DECHEX = 'Invalid %s. Please specify a decimal or a hexadecimal value.';
begin
  if not TryStrToUInt64Ex(S, Result) then
    raise EConvertError.Create(Format(E_DECHEX, [Comment]));
end;

function StrToUIntEx(S: String; Comment: String): Cardinal;
begin
  {$R-}
  Result := StrToUInt64Ex(S, Comment);
  {$R+}
end;

end.
