unit NtUtils.Strings;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, DelphiUtils.Strings,
  NtUtils.Security.Sid, DelphiApi.Reflection;

const
  ObjAttributesFlags: array [0..1] of TFlagName = (
    (Value: OBJ_PERMANENT; Name: 'Permanent'),
    (Value: OBJ_EXCLUSIVE; Name: 'Exclusive')
  );

function ElevationToString(Value: TTokenElevationType): String;
function IntegrityToString(Rid: Cardinal): String;
function NativeTimeToString(NativeTime: TLargeInteger): String;

implementation

uses
  System.SysUtils;

function ElevationToString(Value: TTokenElevationType): String;
begin
  case Value of
    TokenElevationTypeDefault: Result := 'N/A';
    TokenElevationTypeFull: Result := 'Full';
    TokenElevationTypeLimited: Result := 'Limited';
  else
     Result := OutOfBound(Integer(Value));
  end;
end;

function IntegrityToString(Rid: Cardinal): String;
begin
  case Rid of
    SECURITY_MANDATORY_UNTRUSTED_RID:         Result := 'Untrusted';
    SECURITY_MANDATORY_LOW_RID:               Result := 'Low';
    SECURITY_MANDATORY_MEDIUM_RID:            Result := 'Medium';
    SECURITY_MANDATORY_MEDIUM_PLUS_RID:       Result := 'Medium +';
    SECURITY_MANDATORY_HIGH_RID:              Result := 'High';
    SECURITY_MANDATORY_SYSTEM_RID:            Result := 'System';
    SECURITY_MANDATORY_PROTECTED_PROCESS_RID: Result := 'Protected';
  else
    Result := IntToHexEx(Rid, 4);
  end;
end;

function NativeTimeToString(NativeTime: TLargeInteger): String;
begin
  if NativeTime = 0 then
    Result := 'Never'
  else if NativeTime = Int64.MaxValue then
    Result := 'Infinite'
  else
    Result := DateTimeToStr(LargeIntegerToDateTime(NativeTime));
end;

end.

