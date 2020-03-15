unit DelphiUtils.Strings;

interface

uses
  System.TypInfo, DelphiApi.Reflection;

type
  THintSection = record
    Title: String;
    Enabled: Boolean;
    Content: String;
  end;

// Boolean state to string
function TrueFalseToString(Value: LongBool): String;
function EnabledDisabledToString(Value: LongBool): String;
function AllowedDisallowedToString(Value: LongBool): String;
function YesNoToString(Value: LongBool): String;
function CheckboxToString(Value: LongBool): String;

// Misc.
function BytesToString(Size: UInt64): String;
function TimeIntervalToString(Seconds: UInt64): String;

// Bit flag manipulation
function Contains(Value, Flag: Cardinal): Boolean; inline;
function ContainsAny(Value, Flag: Cardinal): Boolean; inline;

// Convert a set of bit flags to a string
function MapFlags(Value: UInt64; Mapping: array of TFlagName; IncludeUnknown:
  Boolean = True; Default: String = '(none)'; ImportantBits: UInt64 = 0)
  : String;

function MapFlagsList(Value: UInt64; Mapping: array of TFlagName): String;

// Create a hint from a set of sections
function BuildHint(Sections: array of THintSection): String;

// Mark a value as out of bound
function OutOfBound(Value: Integer): String;

// Make enumeration names look friendly
function PrettifyCamelCase(CamelCaseText: String;
  Prefix: String = ''; Suffix: String = ''): String;
function PrettifyCamelCaseEnum(TypeInfo: PTypeInfo; Value: Integer;
  Prefix: String = ''; Suffix: String = ''): String;

function CamelCaseToSnakeCase(Text: String): string;

function PrettifySnakeCase(CapsText: String; Prefix: String = '';
  Suffix: String = ''): String;
function PrettifySnakeCaseEnum(TypeInfo: PTypeInfo; Value: Integer;
  Prefix: String = ''; Suffix: String = ''): String;

// Int representation (as 12'345'678)
function IntToStrEx(Value: UInt64; Separate: Boolean = True): String;

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

function TrueFalseToString(Value: LongBool): String;
begin
  if Value then
    Result := 'True'
  else
    Result := 'False';
end;

function EnabledDisabledToString(Value: LongBool): String;
begin
  if Value then
    Result := 'Enabled'
  else
    Result := 'Disabled';
end;

function AllowedDisallowedToString(Value: LongBool): String;
begin
  if Value then
    Result := 'Allowed'
  else
    Result := 'Disallowed';
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

function BytesToString(Size: UInt64): String;
begin
  if Size = UInt64(-1) then
    Result := 'Infinite'
  else if Size > 1 shl 30 then
    Result := Format('%.2f GiB', [Size / (1 shl 30)])
  else if Size > 1 shl 20 then
    Result := Format('%.1f MiB', [Size / (1 shl 20)])
  else if Size > 1 shl 10 then
    Result := IntToStr(Size shr 10) + ' KiB'
  else
    Result := IntToStr(Size) + ' B';
end;

function TimeIntervalToString(Seconds: UInt64): String;
const
  SecondsInDay = 86400;
  SecondsInHour = 3600;
  SecondsInMinute = 60;
var
  Value: UInt64;
  Strings: array of String;
  i: Integer;
begin
  SetLength(Strings, 4);
  i := 0;

  // Days
  if Seconds >= SecondsInDay then
  begin
    Value := Seconds div SecondsInDay;
    Seconds := Seconds mod SecondsInDay;

    if Value = 1 then
      Strings[i] := '1 day'
    else
      Strings[i] := IntToStr(Value) + ' days';

    Inc(i);
  end;

  // Hours
  if Seconds >= SecondsInHour then
  begin
    Value := Seconds div SecondsInHour;
    Seconds := Seconds mod SecondsInHour;

    if Value = 1 then
      Strings[i] := '1 hour'
    else
      Strings[i] := IntToStr(Value) + ' hours';

    Inc(i);
  end;

  // Minutes
  if Seconds >= SecondsInMinute then
  begin
    Value := Seconds div SecondsInMinute;
    Seconds := Seconds mod SecondsInMinute;

    if Value = 1 then
      Strings[i] := '1 minute'
    else
      Strings[i] := IntToStr(Value) + ' minutes';

    Inc(i);
  end;

  // Seconds
  if Seconds = 1 then
    Strings[i] := '1 second'
  else
    Strings[i] := IntToStr(Seconds) + ' seconds';

  Inc(i);
  Result := String.Join(' ', Strings, 0, i);
end;

function Contains(Value, Flag: Cardinal): Boolean;
begin
  Result := (Value and Flag = Flag);
end;

function ContainsAny(Value, Flag: Cardinal): Boolean;
begin
  Result := (Value and Flag <> 0);
end;

function MapFlags(Value: UInt64; Mapping: array of TFlagName;
  IncludeUnknown: Boolean; Default: String; ImportantBits: UInt64): String;
var
  Strings: array of String;
  i, Count: Integer;
begin
  if Value = 0 then
    Exit(Default);

  SetLength(Strings, Length(Mapping) + 2);
  Count := 0;

  // Include the default message if none of important bits present
  if (ImportantBits <> 0) and (Value and ImportantBits = 0) then
  begin
    Strings[Count] := Default;
    Inc(Count);
  end;

  // Map known bits
  for i := 0 to High(Mapping) do
    if Value and Mapping[i].Value = Mapping[i].Value then
    begin
      Strings[Count] := Mapping[i].Name;
      Value := Value and not Mapping[i].Value;
      Inc(Count);
    end;

  // Unknown bits
  if IncludeUnknown and (Value <> 0) then
  begin
    Strings[Count] := IntToHexEx(Value);
    Inc(Count);
  end;

  if Count = 0 then
    Result := Default
  else
    Result := String.Join(', ', Strings, 0, Count);
end;

function MapFlagsList(Value: UInt64; Mapping: array of TFlagName): String;
var
  Strings: array of string;
  i: Integer;
begin
  SetLength(Strings, Length(Mapping));

  for i := 0 to High(Mapping) do
  begin
    Strings[i] := CheckboxToString(Value and Mapping[i].Value =
      Mapping[i].Value) + ' ' + Mapping[i].Name;
    Value := Value and not Mapping[i].Value;
  end;

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
  // Convert a string with from CamelCase to a spaced string removing a
  // prefix/suffix: '[Prefix]MyExampleIDTest[Suffix]' => 'My Example ID Test'

  Result := CamelCaseText;

  // Remove prefix
  if Result.StartsWith(Prefix) then
    Delete(Result, Low(Result), Length(Prefix));

  // Remove suffix
  if Result.EndsWith(Suffix) then
    Delete(Result, Length(Result) - Length(Suffix) + 1, Length(Suffix));

  // Add a space before a capital that has a non-captial on either side of it

  i := Low(Result);

  // Skip leading lower-case word
  while (i <= High(Result)) and (CharInSet(Result[i], ['a'..'z'])) do
    Inc(i);

  Inc(i);
  while i <= High(Result) do
  begin
    if CharInSet(Result[i], ['A'..'Z', '0'..'9']) and
      (not CharInSet(Result[i - 1], ['A'..'Z', '0'..'9']) or ((i < High(Result))
      and not CharInSet(Result[i + 1], ['A'..'Z', '0'..'9']))) then
    begin
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

function CamelCaseToSnakeCase(Text: String): string;
var
  i: Integer;
begin
  Result := PrettifyCamelCase(Text);

  for i := Low(Result) to High(Result) do
    if CharInSet(Result[i], ['a'..'z']) then
      Result[i] := Chr(Ord('A') + Ord(Result[i]) - Ord('a'))
    else if Result[i] = ' ' then
      Result[i] := '_';
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

  if Result.StartsWith('_') then
    Delete(Result, Low(Result), 1);

  if Result.EndsWith('_') then
    Delete(Result, High(Result), 1);

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

function IntToStrEx(Value: UInt64; Separate: Boolean): String;
begin
  Result := IntToStr(Value mod 1000);
  Value := Value div 1000;

  while Value > 0 do
  begin
    Result := IntToStr(Value mod 1000) + ' ' + Result;
    Value := Value div 1000;
  end;
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
{$IFDEF Win64}
  if UIntPtr(Value) >= UIntPtr(1) shl 32 then
    Result := '0x' + IntToHex(UIntPtr(Value), 16)
  else
{$ENDIF}
    Result := '0x' + IntToHex(UIntPtr(Value), 8);
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
