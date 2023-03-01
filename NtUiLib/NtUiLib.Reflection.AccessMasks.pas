unit NtUiLib.Reflection.AccessMasks;

{
  The module provides logic for representing access masks as strings via
  Runtime Type Information.
}

interface

uses
  Ntapi.WinNt;

// Prepare a textual representation of an access mask
function FormatAccess(
  const Access: TAccessMask;
  MaskType: Pointer = nil; // Use TypeInfo(T)
  IncludePrefix: Boolean = False
): String;

type
  TAccessMaskHelper = record helper for TAccessMask
    function Format<T>(IncludePrefix: Boolean = False): String;
  end;

implementation

uses
  DelphiApi.Reflection, DelphiUiLib.Strings, DelphiUiLib.Reflection.Numeric,
  System.Rtti, NtUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

procedure ConcatFlags(var Result: String; NewFlags: String);
begin
  if (Result <> '') and (NewFlags <> '') then
    Result := Result + ', ' + NewFlags
  else if NewFlags <> '' then
    Result := NewFlags;
end;

function FormatAccess;
var
  UnmappedBits: TAccessMask;
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
    UnmappedBits := Access;
    Result := '';

    if not Assigned(MaskType) then
      MaskType := TypeInfo(TAccessMask);

    RttiContext := TRttiContext.Create;
    RttiType := RttiContext.GetType(MaskType);

    // Determine which bits are necessary for having full access
    for a in RttiType.GetAttributes do
      if a is ValidBitsAttribute then
      begin
        FullAccess := Cardinal(ValidBitsAttribute(a).ValidMask);

        // Map and exclude
        if Access and FullAccess = FullAccess then
        begin
          Result := 'Full access';
          UnmappedBits := UnmappedBits and not FullAccess;
        end;

        Break;
      end;

    // Custom access mask
    if HasAny(UnmappedBits) and (MaskType <> TypeInfo(TAccessMask)) then
    begin
      // Represent type-specific access, if any
      Reflection := GetNumericReflection(MaskType, UnmappedBits);

      if Reflection.UnknownBits <> UnmappedBits then
      begin
        // Some bits were mapped
        ConcatFlags(Result, Reflection.Text);
        UnmappedBits := Reflection.UnknownBits;
      end;
    end;

    // Map standard, generic, and other access rights, including unknown bits
    if HasAny(UnmappedBits) then
      ConcatFlags(Result, GetNumericReflection(TypeInfo(TAccessMask),
        UnmappedBits).Text);
  end;

  if IncludePrefix then
    Result := IntToHexEx(Access, 6) + ' (' + Result + ')';
end;

{ TAccessMaskHelper }

function TAccessMaskHelper.Format<T>;
begin
  Result := FormatAccess(Self, TypeInfo(T), IncludePrefix);
end;

end.
