unit NtUiLib.AccessMasks;

interface

uses
  Winapi.WinNt;

// Prepare a textial representation of an access mask
function FormatAccess(Access: TAccessMask; MaskType: Pointer;
  IncludePrefix: Boolean = False): String;

implementation

uses
  DelphiApi.Reflection, DelphiUiLib.Strings, DelphiUiLib.Reflection.Numeric,
  System.SysUtils, System.Rtti;

procedure ConcatFlags(var Result: String; NewFlags: String);
begin
  if (Result <> '') and (NewFlags <> '') then
    Result := Result + ', ' + NewFlags
  else if NewFlags <> '' then
    Result := NewFlags;
end;

function FormatAccess(Access: TAccessMask; MaskType: Pointer;
  IncludePrefix: Boolean): String;
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  a: TCustomAttribute;
  FullAccess: TAccessMask;
  Reflection: TNumericReflection;
begin
  if Access = 0 then
    Result := 'No access'
  else
  begin
    Result := '';

    RttiContext := TRttiContext.Create;
    RttiType := RttiContext.GetType(MaskType);

    // Determine which bits are necessary for having full access
    for a in RttiType.GetAttributes do
      if a is ValidMaskAttribute then
      begin
        FullAccess := ValidMaskAttribute(a).ValidMask;

        // Map and exclude
        if Access and FullAccess = FullAccess then
        begin
          Result := 'Full access';
          Access := Access and not FullAccess;
        end;

        Break;
      end;

    if MaskType <> TypeInfo(TAccessMask) then
    begin
      // Represent type-specific access, if any
      Reflection := GetNumericReflection(MaskType, Access);
      ConcatFlags(Result, Reflection.Name);

      Access := Reflection.UnknownBits;
    end;

    // Map standard, generic, and other access rights, including unknown bits
    if Access <> 0 then
      ConcatFlags(Result, GetNumericReflection(TypeInfo(TAccessMask),
        Access).Name);
  end;

  if IncludePrefix then
    Result := IntToHexEx(Access, 6) + ' (' + Result + ')';
end;

end.
