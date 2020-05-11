unit NtUiLib.Exceptions.Report;

interface

uses
  NtUtils;

// Construct a verbose report about an error
function NtxVerboseStatusMessage(const Status: TNtxStatus): String;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntseapi, System.TypInfo, DelphiUiLib.Strings,
  NtUiLib.AccessMasks, NtUiLib.Exceptions.Messages, System.Rtti,
  DelphiApi.Reflection;

function ProvidesPrivilege(const LastCall: TLastCallInfo): Boolean;
begin
  Result := (LastCall.ExpectedPrivilege >= SE_CREATE_TOKEN_PRIVILEGE) and
    (LastCall.ExpectedPrivilege <= High(TSeWellKnownPrivilege));
end;

function GetFriendlyName(AType: Pointer): String;
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  a: TCustomAttribute;
begin
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(AType);

  for a in RttiType.GetAttributes do
    if a is FriendlyNameAttribute then
      Exit(FriendlyNameAttribute(a).Name);

  Result := '';
end;

function NtxVerboseStatusMessage(const Status: TNtxStatus): String;
var
  i: Integer;
begin
  // LastCall: <function name>
  Result := 'Last call: ' + Status.Location;

  case Status.LastCall.CallType of
    lcOpenCall:
      // Desired access: <mask>
      Result := Result + #$D#$A + 'Desired ' +
        GetFriendlyName(Status.LastCall.AccessMaskType) + ' access: ' +
        FormatAccess(Status.LastCall.AccessMask,
        Status.LastCall.AccessMaskType);

    lcQuerySetCall:
      // Information class: <name>
      Result := Result + #$D#$A + 'Information class: ' + GetEnumName(
        Status.LastCall.InfoClassType, Integer(Status.LastCall.InfoClass));
  end;

  // Expected <type> access: <mask>
  if Status.Status = STATUS_ACCESS_DENIED then
    for i := 0 to High(Status.LastCall.ExpectedAccess) do
      with Status.LastCall.ExpectedAccess[i] do
        Result := Result + #$D#$A + 'Expected ' +
          GetFriendlyName(AccessMaskType) + ' access: ' +
          FormatAccess(AccessMask, AccessMaskType);

  // Result: <STATUS_*/ERROR_*>
  Result := Result + #$D#$A + 'Result: ' + NtxStatusToString(Status.Status);

  // <textual description>
  Result := Result + #$D#$A#$D#$A + NtxFormatErrorMessage(Status.Status);

  // <privilege name>
  if (Status.Status = STATUS_PRIVILEGE_NOT_HELD) and
    ProvidesPrivilege(Status.LastCall) then
    Result := Result + ': "' + PrettifySnakeCaseEnum(
      TypeInfo(TSeWellKnownPrivilege),
      Integer(Status.LastCall.ExpectedPrivilege), 'SE_') + '"';
end;

end.
