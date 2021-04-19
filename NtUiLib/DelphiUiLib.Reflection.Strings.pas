unit DelphiUiLib.Reflection.Strings;

{
  This module provides various helper functions for preparing strings for
  showing to the user.
}

interface

uses
  System.TypInfo, DelphiApi.Reflection;

type
  THintSection = record
    Title: String;
    Content: String;
    class function New(Title, Content: String): THintSection; static;
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

// Convert a set of bit flags to a string
function MapFlags(
  Value: UInt64;
  const Mapping: TArray<TFlagName>;
  IncludeUnknown: Boolean = True;
  const Default: String = '(none)';
  ImportantBits: UInt64 = 0
): String;

function MapFlagsList(
  Value: UInt64;
  const Mapping: TArray<TFlagName>
): String;

// Create a hint from a set of sections
function BuildHint(const Sections: TArray<THintSection>): String; overload;
function BuildHint(const Title, Content: String): String; overload;

// Convery a CamelCase-style enumeration value to a string
function PrettifyCamelCaseEnum(
  TypeInfo: PTypeInfo;
  Value: Integer;
  [opt] const Prefix: String = '';
  [opt] const Suffix: String = ''
): String;

// Convery a SNAKE_CASE-style enumeration value to a string
function PrettifySnakeCaseEnum(
  TypeInfo: PTypeInfo;
  Value: Integer;
  [opt] const Prefix: String = '';
  [opt] const Suffix: String = ''
): String;

// String to int conversion
function TryStrToUInt64Ex(
  S: String;
  out Value: UInt64
): Boolean;

function TryStrToUIntEx(
  S: String;
  out Value: Cardinal
): Boolean;

function StrToUIntEx(
  const S: String;
  const Comment: String
): Cardinal; inline;

function StrToUInt64Ex(
  const S: String;
  const Comment: String
): UInt64; inline;

implementation

uses
  DelphiUiLib.Strings, SysUtils;

function TrueFalseToString;
begin
  if Value then
    Result := 'True'
  else
    Result := 'False';
end;

function EnabledDisabledToString;
begin
  if Value then
    Result := 'Enabled'
  else
    Result := 'Disabled';
end;

function AllowedDisallowedToString;
begin
  if Value then
    Result := 'Allowed'
  else
    Result := 'Disallowed';
end;

function YesNoToString;
begin
  if Value then
    Result := 'Yes'
  else
    Result := 'No';
end;

function CheckboxToString;
begin
  if Value then
    Result := '☑'
  else
    Result := '☐';
end;

function BytesToString;
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

function TimeIntervalToString;
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

function MapFlags;
var
  Strings: TArray<String>;
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

function MapFlagsList;
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

class function THintSection.New(Title, Content: String): THintSection;
begin
  Result.Title := Title;
  Result.Content := Content;
end;

function BuildHint(const Sections: TArray<THintSection>): String;
var
  i: Integer;
  Items: TArray<String>;
begin
  SetLength(Items, Length(Sections));

  for i := Low(Sections) to High(Sections) do
    Items[i] := Sections[i].Title + ':  '#$D#$A'  ' +
      Sections[i].Content + '  ';

  Result := String.Join(#$D#$A, Items);
end;

function BuildHint(const Title, Content: String): String;
begin
  Result := BuildHint([THintSection.New(Title, Content)]);
end;

function OutOfBound(Value: Integer): String;
begin
  Result := IntToStr(Value) + ' (out of bound)';
end;

function PrettifyCamelCaseEnum;
begin
  if (TypeInfo.Kind = tkEnumeration) and (Value >= TypeInfo.TypeData.MinValue)
    and (Value <= TypeInfo.TypeData.MaxValue) then
    Result := PrettifyCamelCase(GetEnumName(TypeInfo, Integer(Value)), Prefix,
      Suffix)
  else
    Result := OutOfBound(Value);
end;

function PrettifySnakeCaseEnum;
begin
  if (TypeInfo.Kind = tkEnumeration) and (Value >= TypeInfo.TypeData.MinValue)
    and (Value <= TypeInfo.TypeData.MaxValue) then
    Result := PrettifySnakeCase(GetEnumName(TypeInfo, Integer(Value)),
      Prefix, Suffix)
  else
    Result := OutOfBound(Value);
end;

function TryStrToUInt64Ex;
var
  E: Integer;
begin
  if S.StartsWith('0x') then
    S := S.Replace('0x', '$', []);

  // Ignore space separators
  S := S.Replace(' ', '', [rfReplaceAll]);

  {$R-}
  Val(S, Value, E);
  {$R+}
  Result := (E = 0);
end;

function TryStrToUIntEx;
var
  E: Integer;
begin
  if S.StartsWith('0x') then
    S := S.Replace('0x', '$', []);

  // Ignore space separators
  S := S.Replace(' ', '', [rfReplaceAll]);

  {$R-}
  Val(S, Value, E);
  {$R+}
  Result := (E = 0);
end;

function StrToUInt64Ex;
const
  E_DECHEX = 'Invalid %s. Please specify a decimal or a hexadecimal value.';
begin
  if not TryStrToUInt64Ex(S, Result) then
    raise EConvertError.Create(Format(E_DECHEX, [Comment]));
end;

function StrToUIntEx;
begin
  {$R-}
  Result := StrToUInt64Ex(S, Comment);
  {$R+}
end;

end.
