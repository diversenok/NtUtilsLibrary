unit NtUiLib.Reflection.Types;

interface

uses
  DelphiUiLib.Reflection;

type
  // TNtUnicodeString
  TNtUnicodeStringRepresenter = class abstract (TRepresenter)
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
  NtUtils.Processes.Query, DelphiUtils.AutoObject;

function RepresentSidWorker(Sid: PSid; Attributes: TGroupAttributes;
  AttributesPresent: Boolean): TRepresentation;
var
  Sections: array of THintSection;
  Success, KnownSidType: Boolean;
  Lookup: TTranslatedName;
  State: TGroupAttributes;
  i: Integer;
begin
  if not Assigned(Sid) then
  begin
    Result.Text := '(nil)';
    Exit;
  end;

  i := 0;
  SetLength(Sections, 5);

  Success := LsaxLookupSid(Sid, Lookup).IsSuccess;
  KnownSidType := Success and not
    (Lookup.SidType in [SidTypeUndefined, SidTypeInvalid, SidTypeUnknown]);

  if KnownSidType then
    Result.Text := Lookup.FullName
  else
    Result.Text := RtlxSidToString(Sid);

  if KnownSidType then
  begin
    Sections[i].Title := 'Friendly Name';
    Sections[i].Content := Lookup.FullName;
    Inc(i);
  end;

  Sections[i].Title := 'SID';
  Sections[i].Content := RtlxSidToString(Sid);
  Inc(i);

  if Success then
  begin
    Sections[i].Title := 'Type';
    Sections[i].Content := TNumeric.Represent(Lookup.SidType).Text;
    Inc(i);
  end;

  if AttributesPresent then
  begin
    // Separate state and flags
    State := Attributes and SE_GROUP_STATE_MASK;
    Attributes := Attributes and not SE_GROUP_STATE_MASK;

    Sections[i].Title := 'State';
    Sections[i].Content := TNumeric.Represent(State).Text;
    Inc(i);

    if Attributes <> 0 then
    begin
      Sections[i].Title := 'Flags';
      Sections[i].Content := TNumeric.Represent(Attributes).Text;
      Inc(i);
    end;
  end;

  SetLength(Sections, i);
  Result.Hint := BuildHint(Sections);
end;

procedure CompileTimeIncludeAllNtTypes;
begin
  CompileTimeInclude(TNtUnicodeStringRepresenter);
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

{ TNtUnicodeStringRepresenter }

class function TNtUnicodeStringRepresenter.GetType: Pointer;
begin
  Result := TypeInfo(TNtUnicodeString);
end;

class function TNtUnicodeStringRepresenter.Represent(const Instance;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  Value: TNtUnicodeString absolute Instance;
  HintSections: TArray<THintSection>;
begin
  Result.Text := Value.ToString;

  SetLength(HintSections, 2);
  HintSections[0].Title := 'Length';
  HintSections[0].Content := IntToStrEx(Value.Length div SizeOf(WideChar));
  HintSections[1].Title := 'Maximum Length';
  HintSections[1].Content := IntToStrEx(Value.MaximumLength div
    SizeOf(WideChar));

  Result.Hint := BuildHint(HintSections);
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
begin
  if PID = 0 then
    ImageName := 'System Idle Process'
  else if PID = 4 then
    ImageName := 'System'
  else if NtxQueryImageNameProcessId(PID, ImageName).IsSuccess then
  begin
    ImageName := ExtractFileName(ImageName);
    Result.Hint := BuildHint('NT Image Name', ImageName);
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
begin
  if Value = 0 then
    Result.Text := 'Never'
  else if Value = Int64.MaxValue then
    Result.Text := 'Infinite'
  else
    Result.Text := DateTimeToStr(LargeIntegerToDateTime(Value));

  Result.Hint := BuildHint('Raw value', IntToStrEx(UInt64(Value)));
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
begin
  Result.Text := TimeIntervalToString(Value div NATIVE_TIME_SECOND);
  Result.Hint := BuildHint('Raw value', IntToStrEx(Value));
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
  Result := RepresentSidWorker(Ptr.RefOrNil<PSid>(Sid), 0, False);
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
  Result := RepresentSidWorker(Ptr.RefOrNil<PSid>(Group.SID),
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

