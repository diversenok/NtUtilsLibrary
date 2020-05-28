unit NtUiLib.Reflection.Types;

interface

uses
  DelphiUiLib.Reflection;

type
  // UNICODE_STRING
  TUnicodeStringRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(const Instance; Attributes:
      TArray<TCustomAttribute>): TRepresentation; override;
  end;

  // TClientId
  TClientIdRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(const Instance; Attributes:
      TArray<TCustomAttribute>): TRepresentation; override;
  end;

  // TProcessId
  TProcessIdRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(const Instance; Attributes:
      TArray<TCustomAttribute>): TRepresentation; override;
  end;

  // TProcessId32
  TProcessId32Representer = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(const Instance; Attributes:
      TArray<TCustomAttribute>): TRepresentation; override;
  end;

  // NTSTATUS
  TNtStatusRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(const Instance; Attributes:
      TArray<TCustomAttribute>): TRepresentation; override;
  end;

  // TWin32Error
  TWin32ErrorRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(const Instance; Attributes:
      TArray<TCustomAttribute>): TRepresentation; override;
  end;

  // TLargeInteger
  TLargeIntegerRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(const Instance; Attributes:
      TArray<TCustomAttribute>): TRepresentation; override;
  end;

  // TULargeInteger
  TULargeIntegerRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(const Instance; Attributes:
      TArray<TCustomAttribute>): TRepresentation; override;
  end;

  // PSid
  TSidRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(const Instance; Attributes:
      TArray<TCustomAttribute>): TRepresentation; override;
  end;

  // TSidAndAttributes
  TSidAndAttributesRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(const Instance; Attributes:
      TArray<TCustomAttribute>): TRepresentation; override;
  end;

  // ISid
  TISidRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(const Instance; Attributes:
      TArray<TCustomAttribute>): TRepresentation; override;
  end;

  // TGroup
  TGroupRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(const Instance; Attributes:
      TArray<TCustomAttribute>): TRepresentation; override;
  end;

  // TLogonId
  TLogonIdRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(const Instance; Attributes:
      TArray<TCustomAttribute>): TRepresentation; override;
  end;

  // TSessionId
  TSessionIdRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(const Instance; Attributes:
      TArray<TCustomAttribute>): TRepresentation; override;
  end;

  // TRect
  TRectRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(const Instance; Attributes:
      TArray<TCustomAttribute>): TRepresentation; override;
  end;

// Make sure all types from this module are accessible through reflection
procedure CompileTimeIncludeAllNtTypes;

implementation

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, DelphiApi.Reflection,
  DelphiUiLib.Strings, NtUtils, NtUiLib.Exceptions.Messages,
  DelphiUiLib.Reflection.Numeric, System.SysUtils, NtUtils.Lsa.Sid,
  NtUtils.Lsa.Logon, NtUtils.WinStation, Winapi.WinUser, NtUtils.Security.Sid,
  NtUtils.Processes.Query;

function RepresentSidWorker(Sid: PSid; Attributes: TGroupAttributes;
  AttributesPresent: Boolean): TRepresentation;
var
  Sections: array of THintSection;
  Success, KnownSidType: Boolean;
  Lookup: TTranslatedName;
  State: TGroupAttributes;
begin
  if not Assigned(Sid) then
  begin
    Result.Text := '(nil)';
    Exit;
  end;

  SetLength(Sections, 5);

  Success := LsaxLookupSid(Sid, Lookup).IsSuccess;
  KnownSidType := Success and not
    (Lookup.SidType in [SidTypeUndefined, SidTypeInvalid, SidTypeUnknown]);

  if KnownSidType then
    Result.Text := Lookup.FullName
  else
    Result.Text := RtlxConvertSidToString(Sid);

  Sections[0].Title := 'Friendly Name';
  Sections[0].Enabled := KnownSidType;
  Sections[0].Content := Lookup.FullName;

  Sections[1].Title := 'SID';
  Sections[1].Enabled := True;
  Sections[1].Content := RtlxConvertSidToString(Sid);

  Sections[2].Title := 'Type';
  Sections[2].Enabled := Success;
  Sections[2].Content := TNumeric.Represent(Lookup.SidType).Text;

  if AttributesPresent then
  begin
    // Separate state and flags
    State := Attributes and SE_GROUP_STATE_MASK;
    Attributes := Attributes and not SE_GROUP_STATE_MASK;

    Sections[3].Title := 'State';
    Sections[3].Enabled := True;
    Sections[3].Content := TNumeric.Represent(State).Text;

    Sections[4].Title := 'Flags';
    Sections[4].Enabled := Attributes <> 0;
    Sections[4].Content := TNumeric.Represent(Attributes).Text;
  end
  else
  begin
    Sections[3].Enabled := False;
    Sections[4].Enabled := False;
  end;

  Result.Hint := BuildHint(Sections);
end;

procedure CompileTimeIncludeAllNtTypes;
begin
  CompileTimeInclude(TUnicodeStringRepresenter);
  CompileTimeInclude(TClientIdRepresenter);
  CompileTimeInclude(TProcessIdRepresenter);
  CompileTimeInclude(TProcessId32Representer);
  CompileTimeInclude(TNtStatusRepresenter);
  CompileTimeInclude(TWin32ErrorRepresenter);
  CompileTimeInclude(TLargeIntegerRepresenter);
  CompileTimeInclude(TULargeIntegerRepresenter);
  CompileTimeInclude(TSidRepresenter);
  CompileTimeInclude(TSidAndAttributesRepresenter);
  CompileTimeInclude(TISidRepresenter);
  CompileTimeInclude(TGroupRepresenter);
  CompileTimeInclude(TLogonIdRepresenter);
  CompileTimeInclude(TSessionIdRepresenter);
  CompileTimeInclude(TRectRepresenter);
end;

{ TUnicodeStringRepresenter }

class function TUnicodeStringRepresenter.GetType: Pointer;
begin
  Result := TypeInfo(UNICODE_STRING);
end;

class function TUnicodeStringRepresenter.Represent(const Instance;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  Value: UNICODE_STRING absolute Instance;
begin
  if Value.Length = 0 then
    Result.Text := ''
  else
    Result.Text := Value.ToString;
end;

{ TClientIdRepresenter }

class function TClientIdRepresenter.GetType: Pointer;
begin
  Result := TypeInfo(TClientId);
end;

class function TClientIdRepresenter.Represent(const Instance;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  CID: TClientId absolute Instance;
begin
  Result.Text := Format('[PID: %d, TID: %d]', [CID.UniqueProcess,
    CID.UniqueThread]);
  // TODO: Represent TThreadId
end;

{ TProcessIdRepresenter }

class function TProcessIdRepresenter.GetType: Pointer;
begin
  Result := TypeInfo(TProcessId);
end;

class function TProcessIdRepresenter.Represent(const Instance;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  PID: TProcessId absolute Instance;
  ImageName: String;
  HintSection: THintSection;
begin
  if PID = 0 then
    ImageName := 'System Idle Process'
  else if PID = 4 then
    ImageName := 'System'
  else if NtxQueryImageNameProcessId(PID, ImageName).IsSuccess then
  begin
    ImageName := ExtractFileName(ImageName);

    HintSection.Title := 'NT Image Name';
    HintSection.Enabled := True;
    HintSection.Content := ImageName;
    Result.Hint := BuildHint([HintSection]);
  end
  else
    ImageName := 'Unknown';

  Result.Text := Format('%s [%d]', [ImageName, PID]);
end;

{ TProcessId32Representer }

class function TProcessId32Representer.GetType: Pointer;
begin
  Result := TypeInfo(TProcessId32);
end;

class function TProcessId32Representer.Represent(const Instance;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  PID32: TProcessId32 absolute Instance;
  PID: TProcessId;
begin
  PID := PID32;
  Result := TProcessIdRepresenter.Represent(PID, Attributes);
end;

{ TNtStatusRepresenter }

class function TNtStatusRepresenter.GetType: Pointer;
begin
  Result := TypeInfo(NTSTATUS);
end;

class function TNtStatusRepresenter.Represent(const Instance;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  Status: NTSTATUS absolute Instance;
begin
  Result.Text := NtxStatusToString(Status);
  Result.Hint := NtxStatusDescription(Status);
end;

{ TWin32ErrorRepresenter }

class function TWin32ErrorRepresenter.GetType: Pointer;
begin
  Result := TypeInfo(TWin32Error);
end;

class function TWin32ErrorRepresenter.Represent(const Instance;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  Error: TWin32Error absolute Instance;
begin
  Result.Text := NtxWin32ErrorToString(Error);
  Result.Hint := NtxWin32ErrorDescription(Error);
end;

{ TLargeIntegerRepresenter }

class function TLargeIntegerRepresenter.GetType: Pointer;
begin
  Result := TypeInfo(TLargeInteger);
end;

class function TLargeIntegerRepresenter.Represent(const Instance;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  Value: TLargeInteger absolute Instance;
  HintSection: THintSection;
begin
  if Value = 0 then
    Result.Text := 'Never'
  else if Value = Int64.MaxValue then
    Result.Text := 'Infinite'
  else
    Result.Text := DateTimeToStr(LargeIntegerToDateTime(Value));

  HintSection.Title := 'Raw value';
  HintSection.Enabled := True;
  HintSection.Content := IntToStrEx(Value);
  Result.Hint := BuildHint([HintSection]);
end;

{ TULargeIntegerRepresenter }

class function TULargeIntegerRepresenter.GetType: Pointer;
begin
  Result := TypeInfo(TULargeInteger);
end;

class function TULargeIntegerRepresenter.Represent(const Instance;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  Value: TULargeInteger absolute Instance;
  HintSection: THintSection;
begin
  Result.Text := TimeIntervalToString(Value div NATIVE_TIME_SECOND);

  HintSection.Title := 'Raw value';
  HintSection.Enabled := True;
  HintSection.Content := IntToStrEx(Value);
  Result.Hint := BuildHint([HintSection]);
end;

{ TSidRepresenter }

class function TSidRepresenter.GetType: Pointer;
begin
  Result := TypeInfo(PSid);
end;

class function TSidRepresenter.Represent(const Instance;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  Sid: PSid absolute Instance;
begin
  Result := RepresentSidWorker(Sid, 0, False);
end;

{ TSidAndAttributesRepresenter }

class function TSidAndAttributesRepresenter.GetType: Pointer;
begin
  Result := TypeInfo(TSidAndAttributes);
end;

class function TSidAndAttributesRepresenter.Represent(const Instance;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  Value: TSidAndAttributes absolute Instance;
begin
  Result := RepresentSidWorker(Value.Sid, Value.Attributes, True);
end;

{ TISidRepresenter }

class function TISidRepresenter.GetType: Pointer;
begin
  Result := TypeInfo(ISid);
end;

class function TISidRepresenter.Represent(const Instance;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  Sid: ISid absolute Instance;
begin
  Result := RepresentSidWorker(GetSid(Sid), 0, False);
end;

{ TGroupRepresenter }

class function TGroupRepresenter.GetType: Pointer;
begin
  Result := TypeInfo(TGroup);
end;

class function TGroupRepresenter.Represent(const Instance;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  Group: TGroup absolute Instance;
begin
  Result := RepresentSidWorker(GetSid(Group.SecurityIdentifier),
    Group.Attributes, True);
end;

{ TLogonIdRepresenter }

class function TLogonIdRepresenter.GetType: Pointer;
begin
  Result := TypeInfo(TLogonId);
end;

class function TLogonIdRepresenter.Represent(const Instance;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  LogonId: TLogonId absolute Instance;
begin
  Result.Text := LsaxQueryNameLogonSession(LogonId);
  // TODO: Add more logon info to hint
end;

{ TSessionIdRepresenter }

class function TSessionIdRepresenter.GetType: Pointer;
begin
  Result := TypeInfo(TSessionId);
end;

class function TSessionIdRepresenter.Represent(const Instance;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  SessionId: TSessionId absolute Instance;
begin
  Result.Text := WsxQueryName(SessionId);
  // TODO: Add more session info to hint
end;

{ TRectRepresenter }

class function TRectRepresenter.GetType: Pointer;
begin
  Result := TypeInfo(TRect);
end;

class function TRectRepresenter.Represent(const Instance;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  Rect: TRect absolute Instance;
begin
  Result.Text := Format('[(%d, %d), (%d, %d)]', [Rect.Left, Rect.Top,
    Rect.Right, Rect.Bottom]);
end;

end.

