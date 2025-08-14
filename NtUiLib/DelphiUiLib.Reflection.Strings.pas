﻿unit DelphiUiLib.Reflection.Strings;

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

// Create a hint from a set of sections
function BuildHint(const Sections: TArray<THintSection>): String; overload;
function BuildHint(const Title, Content: String): String; overload;
function BuildHint(const Titles, Contents: TArray<String>): String; overload;

// Convert a CamelCase-style enumeration value to a string
function PrettifyCamelCaseEnum(
  TypeInfo: PTypeInfo;
  Value: Integer;
  [opt] const Prefix: String = '';
  [opt] const Suffix: String = ''
): String;

// Convert a SNAKE_CASE-style enumeration value to a string
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

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

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

class function THintSection.New(Title, Content: String): THintSection;
begin
  Result.Title := Title;
  Result.Content := Content;
end;

function BuildHint(const Sections: TArray<THintSection>): String;
var
  i, Count: Integer;
  Items: TArray<String>;
begin
  SetLength(Items, Length(Sections));

  // Combine, skipping sections with empty content
  Count := 0;
  for i := Low(Sections) to High(Sections) do
    if Sections[i].Content <> '' then
    begin
      Items[Count] := Format('%s:  '#$D#$A'  %s  ', [Sections[i].Title,
        Sections[i].Content]);
      Inc(Count);
    end;

  if Count < Length(Sections) then
    SetLength(Items, Count);

  Result := String.Join(#$D#$A, Items);
end;

function BuildHint(const Title, Content: String): String;
begin
  Result := BuildHint([THintSection.New(Title, Content)]);
end;

function BuildHint(const Titles, Contents: TArray<String>): String;
var
  Sections: TArray<THintSection>;
  i: Integer;
begin
  if Length(Titles) <> Length(Contents) then
  begin
    Assert(False, 'Mismatched number of hint titles and contents');
    Exit('');
  end;

  SetLength(Sections, Length(Titles));

  for i := 0 to High(Sections) do
    Sections[i] := THintSection.New(Titles[i], Contents[i]);

  Result := BuildHint(Sections);
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

  {$Q-}{$R-}
  Val(S, Value, E);
  {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}
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

  {$Q-}{$R-}
  Val(S, Value, E);
  {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}
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
  {$Q-}{$R-}
  Result := StrToUInt64Ex(S, Comment);
  {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}
end;

end.
