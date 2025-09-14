unit DelphiUiLib.Strings;

{
  This module includes functions for preparing text for showing it to users.
}

interface

uses
  Ntapi.WinNt, DelphiApi.Reflection, NtUtils.SysUtils;

{ Text prettification }

// Insert spaces into CamelCase strings and remove a prefix/suffix
function PrettifyCamelCase(
  const CamelCaseText: String;
  const Prefix: String = '';
  const Suffix: String = ''
): String;

// Convert CamelCase to SNAKE_CASE string
function CamelCaseToSnakeCase(
  const Text: String
): string;

// Adjust capitalization and add spaces to SNAKE_CASE strings
function PrettifySnakeCase(
  const CapsText: String;
  const Prefix: String = '';
  const Suffix: String = ''
): String;

{ Integers }

// Convert an unsigned integer to a decimal string, grouping digits: 123 456 789
function UiLibUIntToDec(const Value: UInt64): String;

const
  NUMERIC_WIDTH_ROUND_TO_GROUP = NtUtils.SysUtils.NUMERIC_WIDTH_ROUND_TO_GROUP;
  NUMERIC_WIDTH_ROUND_TO_BYTE = NtUtils.SysUtils.NUMERIC_WIDTH_ROUND_TO_BYTE;

// Convert an unsigned integer to a hex string, grouping digits: 0x001F FFFF
function UiLibUIntToHex(
  const Value: UInt64;
  Width: Byte = NUMERIC_WIDTH_ROUND_TO_GROUP
): String;

// Convert a string to an integer. Supports dec, hex, and spaces between digits
function UiLibStringToUInt64(const S: String; out Value: UInt64;
  AllowMinusSign: Boolean = False; ValueSize: TIntegerSize = isUInt64): Boolean;
function UiLibStringToUIntPtr(const S: String; out Value: UIntPtr;
  AllowMinusSign: Boolean = False): Boolean;
function UiLibStringToUInt(const S: String; out Value: Cardinal;
  AllowMinusSign: Boolean = False): Boolean;

// Convert a string to an integer of raise an exception
function UiLibStringToUInt64RaiseOnError(
  const S: String; const Field: String): UInt64;
function UiLibStringToUIntPtrRaiseOnError(
  const S: String; const Field: String): UIntPtr;
function UiLibStringToUIntRaiseOnError(
  const S: String; const Field: String): Cardinal;

{ Booleans }

function BooleanToString(
  Value: LongBool;
  Kind: TBooleanKind = bkTrueFalse
): String;

function CheckboxToString(Value: LongBool): String;

{ Other }

// Convert the number of bytes to a string with bytes/KiB/MiB/GiB units
function UiLibBytesToString(
  const Bytes: UInt64
): String;

{ Time }

// Convert a Delphi timestamp to a string
function UiLibDateTimeToString(
  const DateTime: TDateTime
): String;

// Convert an NT timestamp to a string
function UiLibNativeTimeToString(
  const NativeTime: TLargeInteger
): String;

// Convert a time duration in native (100ns) units to a string
function UiLibDurationToString(
  TimeSpan: TULargeInteger
): String;

// Convert a timespan between now and the timestamprelative to now to a string
function UiLibSystemTimeDurationFromNow(
  const Timestamp: TLargeInteger
): String;

{ Hints }

type
  THintSection = record
    Title: String;
    Content: String;
    class function New(const Title, Content: String): THintSection; static;
  end;

// Create a hint from a set of sections
function BuildHint(const Sections: TArray<THintSection>): String; overload;
function BuildHint(const Title, Content: String): String; overload;
function BuildHint(const Titles, Contents: TArray<String>): String; overload;

implementation

uses
  Ntapi.ntrtl, Ntapi.WinBase, Ntapi.ntstatus, NtUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function PrettifyCamelCase;
var
  i: Integer;
begin
  // Convert a string with from CamelCase to a spaced string removing a
  // prefix/suffix: '[Prefix]MyExampleIDTest[Suffix]' => 'My Example ID Test'

  Result := CamelCaseText;

  // Remove prefix & suffix
  RtlxPrefixStripString(Prefix, Result, True);
  RtlxSuffixStripString(Suffix, Result, True);

  // Add a space before a capital that has a non-capital on either side of it

  i := Low(Result);

  // Skip leading lower-case word
  while (i <= High(Result)) and (AnsiChar(Result[i]) in ['a'..'z']) do
    Inc(i);

  Inc(i);
  while i <= High(Result) do
  begin
    if (AnsiChar(Result[i]) in ['A'..'Z', '0'..'9']) and
      (not (AnsiChar(Result[i - 1]) in ['A'..'Z', '0'..'9']) or
      ((i < High(Result)) and not (AnsiChar(Result[i + 1]) in
      ['A'..'Z', '0'..'9']))) then
    begin
      Insert(' ', Result, i);
      Inc(i);
    end;
    Inc(i);
  end;
end;

function CamelCaseToSnakeCase;
var
  i: Integer;
begin
  Result := PrettifyCamelCase(Text);

  for i := Low(Result) to High(Result) do
    if AnsiChar(Result[i]) in ['a'..'z'] then
      Result[i] := Chr(Ord('A') + Ord(Result[i]) - Ord('a'))
    else if Result[i] = ' ' then
      Result[i] := '_';
end;

function PrettifySnakeCase;
var
  i: Integer;
begin
  // Convert a string with from capitals with underscores to a spaced string
  // removing a prefix/suffix, ex.: 'ERROR_ACCESS_DENIED' => 'Access Denied'

  Result := CapsText;

  // Remove prefix & suffix
  RtlxPrefixStripString(Prefix, Result, True);
  RtlxSuffixStripString(Suffix, Result, True);
  RtlxPrefixStripString('_', Result, True);
  RtlxSuffixStripString('_', Result, True);

  i := Succ(Low(Result));
  while i <= High(Result) do
  begin
    case Result[i] of
      'A'..'Z':
        Result[i] := Chr(Ord('a') + Ord(Result[i]) - Ord('A'));
      '_':
        begin
          Result[i] := ' ';
          Inc(i); // Skip the next letter
        end;
    end;
    Inc(i);
  end;
end;

{ Integers }

function UiLibUIntToDec;
begin
  Result := RtlxIntToDec(Value, isUInt64, isUnsigned, 0, npSpace);
end;

function UiLibUIntToHex;
begin
  Result := RtlxIntToHex(Value, Width, True, npSpace);
end;

function UiLibStringToUInt64;
begin
  Result := RtlxStrToUInt64(S, Value, nsDecimal, [nsHexadecimal],
    AllowMinusSign, [npSpace], ValueSize);
end;

function UiLibStringToUIntPtr;
begin
  Result := RtlxStrToUIntPtr(S, Value, nsDecimal, [nsHexadecimal],
    AllowMinusSign, [npSpace]);
end;

function UiLibStringToUInt;
begin
  Result := RtlxStrToUInt(S, Value, nsDecimal, [nsHexadecimal],
    AllowMinusSign, [npSpace]);
end;

function UiLibStringToUInt64RaiseOnError;
var
  Status: TNtxStatus;
begin
  if not UiLibStringToUInt64(S, Result) then
  begin
    Status.Location := 'UiLibStringToUInt64';
    Status.LastCall.Parameter := Field;
    Status.Status := STATUS_INVALID_PARAMETER;;
    Status.RaiseOnError;
  end;
end;

function UiLibStringToUIntPtrRaiseOnError;
var
  Status: TNtxStatus;
begin
  if not UiLibStringToUIntPtr(S, Result) then
  begin
    Status.Location := 'UiLibStringToUIntPtr';
    Status.LastCall.Parameter := Field;
    Status.Status := STATUS_INVALID_PARAMETER;;
    Status.RaiseOnError;
  end;
end;

function UiLibStringToUIntRaiseOnError;
var
  Status: TNtxStatus;
begin
  if not UiLibStringToUInt(S, Result) then
  begin
    Status.Location := 'UiLibStringToUInt';
    Status.LastCall.Parameter := Field;
    Status.Status := STATUS_INVALID_PARAMETER;;
    Status.RaiseOnError;
  end;
end;

{ Booleans }

function BooleanToString;
const
  NAMES: array [TBooleanKind] of array [Boolean] of String = (
    ('False', 'True'),
    ('Disabled', 'Enabled'),
    ('Disallowed', 'Allowed'),
    ('No', 'Yes')
  );
begin
  if Kind > bkYesNo then
    Kind := bkTrueFalse;

  Result := Names[Kind][Value <> False];
end;

function CheckboxToString;
begin
  if Value then
    Result := '☑'
  else
    Result := '☐';
end;

{ Other }

function UiLibFixedPointToString(Value: Double; Digits: Byte): String;
var
  Decimal: Int64;
begin
  // TBD: unsafe; cannot handle the entire float range
  Decimal := Round(Power10(Value, Digits));
  Result := RtlxIntToDec(UInt64(Decimal), isUInt64, isSigned, Digits + 1);

  if (Decimal = 0) and (Value < 0) then
    Insert('-', Result, 0);

  if Digits > 0 then
    Insert('.', Result, Length(Result) - Digits + 1);
end;

function UiLibBytesToString;
const
  BYTES_PER_KB = UInt64(1) shl 10;
  BYTES_PER_MB = UInt64(1) shl 20;
  BYTES_PER_GB = UInt64(1) shl 30;
var
  IntValue: UInt64;
  FloatValue: Double;
  Digits: Integer;
  Units: String;
begin
  IntValue := 0;
  FloatValue := 0.0;

  if Bytes < BYTES_PER_KB then
  begin
    // %I64u bytes
    IntValue := Bytes;
    Digits := 0;
    Units := ' bytes';
  end
  else if (Bytes < BYTES_PER_KB * 10) and (Bytes mod BYTES_PER_KB <> 0) then
  begin
    // %0.2f KiB
    FloatValue := (Bytes * 100 / BYTES_PER_KB) / 100;
    Digits := 2;
    Units := ' KiB';
  end
  else if (Bytes < BYTES_PER_KB * 100) and (Bytes mod BYTES_PER_KB <> 0) then
  begin
    // %0.1f KiB
    FloatValue := (Bytes * 10 / BYTES_PER_KB) / 10;
    Digits := 1;
    Units := ' KiB';
  end
  else if Bytes < BYTES_PER_MB then
  begin
    // %I64u KiB
    IntValue := Bytes div BYTES_PER_KB;
    Digits := 0;
    Units := ' KiB';
  end
  else if (Bytes < BYTES_PER_MB * 10) and (Bytes mod BYTES_PER_MB <> 0) then
  begin
    // %0.2f MiB
    FloatValue := (Bytes * 100 / BYTES_PER_MB) / 100;
    Digits := 2;
    Units := ' MiB';
  end
  else if (Bytes < BYTES_PER_MB * 100) and (Bytes mod BYTES_PER_MB <> 0) then
  begin
    // %0.1f MiB
    FloatValue := (Bytes * 10 / BYTES_PER_MB) / 10;
    Digits := 1;
    Units := ' MiB';
  end
  else if Bytes < BYTES_PER_GB then
  begin
    // %I64u MiB
    IntValue := Bytes div BYTES_PER_MB;
    Digits := 0;
    Units := ' MiB';
  end
  else if (Bytes < BYTES_PER_GB * 10) and (Bytes mod BYTES_PER_GB <> 0) then
  begin
    // %0.2f GiB
    FloatValue := (Bytes * 100 / BYTES_PER_GB) / 100;
    Digits := 2;
    Units := ' GiB';
  end
  else if (Bytes < BYTES_PER_GB * 100) and (Bytes mod BYTES_PER_GB <> 0) then
  begin
    // %0.1f GiB
    FloatValue := (Bytes * 10 / BYTES_PER_GB) / 10;
    Digits := 1;
    Units := ' GiB';
  end
  else
  begin
    // %I64u GiB
    IntValue := Bytes div BYTES_PER_GB;
    Digits := 0;
    Units := ' GiB';
  end;

  if Digits = 0 then
    Result := UiLibUIntToDec(IntValue) + Units
  else
    Result := UiLibFixedPointToString(FloatValue, Digits) + Units;
end;

function AdvxFormatTime(
  out TimeString: String;
  const Time: TSystemTime
): TNtxStatus;
var
  Required: Integer;
begin
  Result.Location := 'GetTimeFormatEx';
  Required := GetTimeFormatEx(nil, 0, @Time, nil, nil, 0);
  Result.Win32Result := Required > 0;

  if not Result.IsSuccess then
    Exit;

  SetLength(TimeString, Pred(Required));
  Required := GetTimeFormatEx(nil, 0, @Time, nil, PWideChar(TimeString),
    Required);
  Result.Win32Result := Required > 0;
end;

function AdvxFormatDate(
  out DateString: String;
  const Date: TSystemTime
): TNtxStatus;
var
  Required: Integer;
begin
  Result.Location := 'GetDateFormatEx';
  Required := GetDateFormatEx(nil, 0, @Date, nil, nil, 0, nil);
  Result.Win32Result := Required > 0;

  if not Result.IsSuccess then
    Exit;

  SetLength(DateString, Pred(Required));
  Required := GetDateFormatEx(nil, 0, @Date, nil, PWideChar(DateString),
    Required, nil);
  Result.Win32Result := Required > 0;
end;

function UiLibDateTimeToString;
var
  Fields: TTimeFields;
  Time: TSystemTime;
  LocalTime: TLargeInteger;
  DatePart, TimePart: String;
begin
  // Split time into fields
  LocalTime := Trunc(NATIVE_TIME_DAY * (DateTime + DAYS_FROM_1601));
  RtlTimeToTimeFields(LocalTime, Fields);

  // Convert fields to the Win32 format
  Time.Year := Fields.Year;
  Time.Month := Fields.Month;
  Time.DayOfWeek := Fields.Weekday;
  Time.Day := Fields.Day;
  Time.Hour := Fields.Hour;
  Time.Minute := Fields.Minute;
  Time.Second := Fields.Second;
  Time.Milliseconds := Fields.Milliseconds;

  // Format
  AdvxFormatDate(DatePart, Time);
  AdvxFormatTime(TimePart, Time);
  Result := DatePart + ' ' + TimePart;
end;

function UiLibNativeTimeToString;
begin
  if NativeTime = 0 then
    Result := 'Never'
  else if NativeTime = MAX_INT64 then
    Result := 'Infinite'
  else
    Result := UiLibDateTimeToString(RtlxLargeIntegerToDateTime(NativeTime));
end;

function UiLibDurationToString;
var
  Days, Hours, Minutes, Seconds: Cardinal;
begin
  if TimeSpan = 0 then
    Result := 'None'
  else if TimeSpan < NATIVE_TIME_MILLISEC then
    Result := RtlxFormatString('%I64u us', [TimeSpan div NATIVE_TIME_MICROSEC])
  else if TimeSpan < NATIVE_TIME_SECOND then
    Result := RtlxFormatString('%I64u ms', [TimeSpan div NATIVE_TIME_MILLISEC])
  else if TimeSpan < NATIVE_TIME_MINUTE then
    Result := RtlxFormatString('%I64u sec', [TimeSpan div NATIVE_TIME_SECOND])
  else
  begin
    Seconds := (TimeSpan div NATIVE_TIME_SECOND) mod 60;
    Minutes := (TimeSpan div NATIVE_TIME_MINUTE) mod 60;
    Hours := (TimeSpan div NATIVE_TIME_HOUR) mod 24;
    Days := TimeSpan div NATIVE_TIME_DAY;

    if TimeSpan < NATIVE_TIME_HOUR then
    begin
      if Seconds <> 0 then
        Result := RtlxFormatString('%u min %u sec', [Minutes, Seconds])
      else
        Result := RtlxFormatString('%u min', [Minutes])
    end
    else if TimeSpan < NATIVE_TIME_DAY then
    begin
      if (Minutes <> 0) and (Seconds <> 0) then
        Result := RtlxFormatString('%u hours %u min %u sec',
          [Hours, Minutes, Seconds])
      else if Minutes <> 0 then
        Result := RtlxFormatString('%u hours %u min', [Hours, Minutes])
      else if Seconds <> 0 then
        Result := RtlxFormatString('%u hours %u sec', [Hours, Seconds])
      else
        Result := RtlxFormatString('%u hours', [Hours]);
    end
    else
    begin
      if (Hours <> 0) and (Minutes <> 0) then
        Result := RtlxFormatString('%I64u days %u hours %u min',
          [Days, Hours, Minutes])
      else if Hours <> 0 then
        Result := RtlxFormatString('%I64u days %u hours', [Days, Hours])
      else if Minutes <> 0 then
        Result := RtlxFormatString('%I64u days %u minutes', [Days, Minutes])
      else
        Result := RtlxFormatString('%I64u days', [Days]);
    end;
  end;
end;

function UiLibSystemTimeDurationFromNow;
var
  Now: TLargeInteger;
begin
  Now := RtlxCurrentSystemTime;

  if Now > Timestamp then
    Result := UiLibDurationToString({$Q-}{$R-}Now - Timestamp
      {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}) + ' ago'
  else if Now < Timestamp then
    Result := UiLibDurationToString({$Q-}{$R-}Timestamp - Now
      {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}) + ' later'
  else
    Result := 'Now';
end;

{ Hints }

class function THintSection.New;
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
      Items[Count] := Sections[i].Title + ':  '#$D#$A'  ' +
        Sections[i].Content + '  ';
      Inc(Count);
    end;

  SetLength(Items, Count);
  Result := RtlxJoinStrings(Items, #$D#$A);
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
    Error(reAssertionFailed);
    Exit('');
  end;

  SetLength(Sections, Length(Titles));

  for i := 0 to High(Sections) do
    Sections[i] := THintSection.New(Titles[i], Contents[i]);

  Result := BuildHint(Sections);
end;

end.
