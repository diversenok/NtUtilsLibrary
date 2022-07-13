unit NtUtils.Tokens.Misc;

{
  The module includes helper functions for parsing and allocated token-related
  structures.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntseapi, NtUtils, NtUtils.Tokens, DelphiUtils.AutoObjects;

function NtxpAllocPrivileges(
  [opt] const Privileges: TArray<TPrivilegeId>;
  Attribute: TPrivilegeAttributes
): IMemory<PTokenPrivileges>;

function NtxpAllocPrivileges2(
  [opt] const Privileges: TArray<TPrivilege>
): IMemory<PTokenPrivileges>;

function NtxpAllocWellKnownPrivileges(
  [opt] const Privileges: TArray<TSeWellKnownPrivilege>;
  Attribute: TPrivilegeAttributes
): IMemory<PTokenPrivileges>;

function NtxpAllocPrivilegeSet(
  [opt] const Privileges: TArray<TPrivilege>
): IMemory<PPrivilegeSet>;

function NtxpAllocGroups(
  [opt] const Sids: TArray<ISid>;
  Attribute: TGroupAttributes
): IMemory<PTokenGroups>;

function NtxpAllocGroups2(
  [opt] const Groups: TArray<TGroup>
): IMemory<PTokenGroups>;

// Attributes

function NtxpParseSecurityAttributes(
  [in] Buffer: PTokenSecurityAttributes;
  CaptureValues: Boolean = True
): TArray<TSecurityAttribute>;

function NtxpAllocSecurityAttributes(
  const Attributes: TArray<TSecurityAttribute>
): IMemory<PTokenSecurityAttributes>;

function NtxpParseClaimAttributes(
  [in] Buffer: PClaimSecurityAttributes
): TArray<TSecurityAttribute>;

// References

function SidInfoRefOrNil(const [ref] Sid: PSid): PTokenSidInformation;
function DefaultDaclRefOrNil(const [ref] Acl: PAcl): PTokenDefaultDacl;

implementation

uses
  Ntapi.ntdef, Ntapi.ntrtl, NtUtils.Security.Sid;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NtxpAllocPrivileges;
var
  i: Integer;
begin
  IMemory(Result) := Auto.AllocateDynamic(SizeOf(Integer) +
    Length(Privileges) * SizeOf(TLuidAndAttributes));

  Result.Data.PrivilegeCount := Length(Privileges);

  for i := 0 to High(Privileges) do
  begin
    Result.Data.Privileges{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}
      .Luid := Privileges[i];
    Result.Data.Privileges{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}
      .Attributes := Attribute;
  end;
end;

function NtxpAllocPrivileges2;
var
  i: Integer;
begin
  IMemory(Result) := Auto.AllocateDynamic(SizeOf(Integer) +
    Length(Privileges) * SizeOf(TLuidAndAttributes));

  Result.Data.PrivilegeCount := Length(Privileges);

  for i := 0 to High(Privileges) do
    Result.Data.Privileges{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF} := Privileges[i];
end;

function NtxpAllocWellKnownPrivileges;
var
  i: Integer;
begin
  IMemory(Result) := Auto.AllocateDynamic(SizeOf(Integer) +
    Length(Privileges) * SizeOf(TLuidAndAttributes));

  Result.Data.PrivilegeCount := Length(Privileges);

  for i := 0 to High(Privileges) do
  begin
    Result.Data.Privileges{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}
      .Luid := TLuid(Privileges[i]);
    Result.Data.Privileges{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}
      .Attributes := Attribute;
  end;
end;

function NtxpAllocPrivilegeSet;
var
  i: Integer;
begin
  IMemory(Result) := Auto.AllocateDynamic(SizeOf(Cardinal) +
    SizeOf(Cardinal) + SizeOf(TLuidAndAttributes) * Length(Privileges));

  Result.Data.PrivilegeCount := Length(Privileges);
  Result.Data.Control := 0;

  for i := 0 to High(Privileges) do
    Result.Data.Privilege{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF} := Privileges[i];
end;

function NtxpAllocGroups;
var
  i: Integer;
begin
  IMemory(Result) := Auto.AllocateDynamic(SizeOf(Integer) +
    Length(Sids) * SizeOf(TSidAndAttributes));

  Result.Data.GroupCount := Length(Sids);

  for i := 0 to High(Sids) do
  begin
    Result.Data.Groups{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.Sid := Sids[i].Data;
    Result.Data.Groups{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.Attributes := Attribute;
  end;
end;

function NtxpAllocGroups2;
var
  i: Integer;
begin
  IMemory(Result) := Auto.AllocateDynamic(SizeOf(Integer) +
    Length(Groups) * SizeOf(TSidAndAttributes));

  Result.Data.GroupCount := Length(Groups);

  for i := 0 to High(Groups) do
  begin
    Result.Data.Groups{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}
      .Sid := Groups[i].SID.Data;
    Result.Data.Groups{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}
      .Attributes := Groups[i].Attributes;
  end;
end;

// Attributes

function NtxpParseSecurityAttributes;
var
  pAttribute: PTokenSecurityAttributeV1;
  i, j: Integer;
begin
  if Buffer.Version <> SECURITY_ATTRIBUTES_INFORMATION_VERSION_V1 then
  begin
    // Don't know how to handle those
    SetLength(Result, 0);
    Exit;
  end;

  SetLength(Result, Buffer.AttributeCount);
  for i := 0 to High(Result) do
    with Result[i] do
    begin
      pAttribute := @Buffer.AttributeV1{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};

      Name := pAttribute.Name.ToString;
      ValueType := pAttribute.ValueType;
      Flags := pAttribute.Flags;

      if not CaptureValues then
        Continue;

      // Capture values depending on their type
      case ValueType of
        SECURITY_ATTRIBUTE_TYPE_INT64, SECURITY_ATTRIBUTE_TYPE_UINT64,
        SECURITY_ATTRIBUTE_TYPE_BOOLEAN:
          begin
            SetLength(ValuesUInt64, pAttribute.ValueCount);

            for j := 0 to High(ValuesUInt64) do
              ValuesUInt64[j] := pAttribute
                .ValuesUInt64{$R-}[j]{$IFDEF R+}{$R+}{$ENDIF};
          end;

        SECURITY_ATTRIBUTE_TYPE_STRING:
          begin
            SetLength(ValuesString, pAttribute.ValueCount);

            for j := 0 to High(ValuesString) do
              ValuesString[j] := pAttribute
                .ValuesString{$R-}[j]{$IFDEF R+}{$R+}{$ENDIF}.ToString;
          end;

        SECURITY_ATTRIBUTE_TYPE_FQBN:
          begin
            SetLength(ValuesFqbn, pAttribute.ValueCount);

            for j := 0 to High(ValuesFqbn) do
              with pAttribute.ValuesFqbn{$R-}[j]{$IFDEF R+}{$R+}{$ENDIF} do
              begin
                ValuesFqbn[j].Version := Version;
                ValuesFqbn[j].Name := Name.ToString;
              end;
          end;

        SECURITY_ATTRIBUTE_TYPE_SID, SECURITY_ATTRIBUTE_TYPE_OCTET_STRING:
          begin
            SetLength(ValuesOctet, pAttribute.ValueCount);

            for j := 0 to High(ValuesOctet) do
              with pAttribute.ValuesOctet{$R-}[j]{$IFDEF R+}{$R+}{$ENDIF} do
                ValuesOctet[i] := Auto.CopyDynamic(pValue, ValueLength);
          end;
      end;
    end;
end;

function NtxpAllocSecurityAttributes;
var
  BufferSize: Cardinal;
  pAttribute: PTokenSecurityAttributeV1;
  pVariable: PByte;
  pOct: PTokenSecurityAttributeOctetStringValue;
  pFqbn: PTokenSecurityAttributeFqbnValue;
  i, j: Integer;
begin
  // Calculate size of the header
  BufferSize := AlighUp(SizeOf(TTokenSecurityAttributes));

  // Add space for all attribute headers
  Inc(BufferSize, SizeOf(TTokenSecurityAttributeV1) * Length(Attributes));
  BufferSize := AlighUp(BufferSize);

  // Include space for variable size data (content)
  for i := 0 to High(Attributes) do
  begin
    // Attribute name
    Inc(BufferSize, Succ(Length(Attributes[i].Name)) * SizeOf(WideChar));
    BufferSize := AlighUp(BufferSize);

    // Attribute data
    case Attributes[i].ValueType of
      SECURITY_ATTRIBUTE_TYPE_INT64, SECURITY_ATTRIBUTE_TYPE_UINT64,
      SECURITY_ATTRIBUTE_TYPE_BOOLEAN:
      begin
        Inc(BufferSize, Length(Attributes[i].ValuesUInt64) * SizeOf(UInt64));
        BufferSize := AlighUp(BufferSize);
      end;

      SECURITY_ATTRIBUTE_TYPE_STRING:
      begin
        Inc(BufferSize, Length(Attributes[i].ValuesString) *
          SizeOf(TNtUnicodeString));
        BufferSize := AlighUp(BufferSize);

        for j := 0 to High(Attributes[i].ValuesString) do
        begin
          Inc(BufferSize, Succ(Length(Attributes[i].ValuesString[j])) *
            SizeOf(WideChar));
          BufferSize := AlighUp(BufferSize);
        end;
      end;

      SECURITY_ATTRIBUTE_TYPE_FQBN:
      begin
        Inc(BufferSize, Length(Attributes[i].ValuesFqbn) *
          SizeOf(TTokenSecurityAttributeFqbnValue));
        BufferSize := AlighUp(BufferSize);

        for j := 0 to High(Attributes[i].ValuesFqbn) do
        begin
          Inc(BufferSize, Succ(Length(Attributes[i].ValuesFqbn[j].Name)) *
            SizeOf(WideChar));
          BufferSize := AlighUp(BufferSize);
        end;
      end;

      SECURITY_ATTRIBUTE_TYPE_SID, SECURITY_ATTRIBUTE_TYPE_OCTET_STRING:
      begin
        Inc(BufferSize, Length(Attributes[i].ValuesOctet) *
          SizeOf(TTokenSecurityAttributeOctetStringValue));
        BufferSize := AlighUp(BufferSize);

        for j := 0 to High(Attributes[i].ValuesOctet) do
        begin
          Inc(BufferSize, Cardinal(Attributes[i].ValuesOctet[j].Size));
          BufferSize := AlighUp(BufferSize);
        end;
      end;
    end;
  end;

  IMemory(Result) := Auto.AllocateDynamic(BufferSize);

  // Fill the header
  Result.Data.Version := SECURITY_ATTRIBUTES_INFORMATION_VERSION_V1;
  Result.Data.AttributeCount := Length(Attributes);

  // Nothing else to do if there are no attributes
  if Length(Attributes) = 0 then
    Exit;

  // Point the first attribute right after the header
  pAttribute := AlighUpPtr(Result.Offset(SizeOf(TTokenSecurityAttributes)));

  Result.Data.AttributeV1 := Pointer(pAttribute);

  // Reserve space for attribute array. Point to the variable part.
  pVariable := AlighUpPtr(Pointer(IntPtr(pAttribute) + Length(Attributes) *
    SizeOf(TTokenSecurityAttributeV1)));

  for i := 0 to High(Attributes) do
  begin
    pAttribute.ValueType := Attributes[i].ValueType;
    pAttribute.Flags := Attributes[i].Flags;

    // Serialize the string
    TNtUnicodeString.Marshal(Attributes[i].Name, @pAttribute.Name,
      PWideChar(pVariable));

    Inc(pVariable, pAttribute.Name.MaximumLength);
    pVariable := AlighUpPtr(pVariable);
    pAttribute.Values := pVariable;

    // Save the data
    case Attributes[i].ValueType of
      SECURITY_ATTRIBUTE_TYPE_INT64, SECURITY_ATTRIBUTE_TYPE_UINT64,
      SECURITY_ATTRIBUTE_TYPE_BOOLEAN:
      begin
        pAttribute.ValueCount := Length(Attributes[i].ValuesUInt64);
        Move(Pointer(Attributes[i].ValuesUInt64)^, pVariable^,
          pAttribute.ValueCount * SizeOf(UInt64));

        Inc(pVariable, pAttribute.ValueCount * SizeOf(UInt64));
        pVariable := AlighUpPtr(pVariable);
      end;

      SECURITY_ATTRIBUTE_TYPE_STRING:
      begin
        pAttribute.ValueCount := Length(Attributes[i].ValuesString);

        // Reserve space for sequential UNICODE_STRING array
        Inc(pVariable, SizeOf(TNtUnicodeString) *
          Length(Attributes[i].ValuesString));
        pVariable := AlighUpPtr(pVariable);

        for j := 0 to High(Attributes[i].ValuesString) do
        begin
          // Serialize each string content
          TNtUnicodeString.Marshal(Attributes[i].ValuesString[j],
            @pAttribute.ValuesString{$R-}[j]{$IFDEF R+}{$R+}{$ENDIF},
            PWideChar(pVariable));

          // Move the variable pointer
          Inc(pVariable, pAttribute.ValuesString{$R-}[j]{$IFDEF R+}{$R+}{$ENDIF}
            .MaximumLength);
          pVariable := AlighUpPtr(pVariable);
        end;
      end;

      SECURITY_ATTRIBUTE_TYPE_FQBN:
      begin
        pAttribute.ValueCount := Length(Attributes[i].ValuesFqbn);

        // Reserve space for sequential FQBN array
        Inc(pVariable, SizeOf(TTokenSecurityAttributeFqbnValue) *
          Length(Attributes[i].ValuesFqbn));
        pVariable := AlighUpPtr(pVariable);

        for j := 0 to High(Attributes[i].ValuesFqbn) do
        begin
          // Copy each string content and make a closure
          pFqbn := @pAttribute.ValuesFQBN{$R-}[j]{$IFDEF R+}{$R+}{$ENDIF};
          pFqbn.Version := Attributes[i].ValuesFqbn[j].Version;

          TNtUnicodeString.Marshal(Attributes[i].ValuesFqbn[j].Name,
            @pFqbn.Name, PWideChar(pVariable));

          Inc(pVariable, pFqbn.Name.MaximumLength);
          pVariable := AlighUpPtr(pVariable);
        end;
      end;

      SECURITY_ATTRIBUTE_TYPE_SID, SECURITY_ATTRIBUTE_TYPE_OCTET_STRING:
      begin
        pAttribute.ValueCount := Length(Attributes[i].ValuesOctet);

        // Reserve space for sequential octet array
        Inc(pVariable, SizeOf(TTokenSecurityAttributeOctetStringValue) *
          Length(Attributes[i].ValuesOctet));
        pVariable := AlighUpPtr(pVariable);

        for j := 0 to High(Attributes[i].ValuesOctet) do
        begin
          // Copy the data
          pOct := @pAttribute.ValuesOctet{$R-}[j]{$IFDEF R+}{$R+}{$ENDIF};
          pOct.ValueLength := Cardinal(Attributes[i].ValuesOctet[j].Size);
          Move(Attributes[i].ValuesOctet[j].Data^, pVariable^,
            pOct.ValueLength);
          pOct.pValue := pVariable;
          Inc(pVariable, pOct.ValueLength);
          pVariable := AlighUpPtr(pVariable);
        end;
      end
    else
      pAttribute.Values := nil;
    end;
    Inc(pAttribute);
  end;

  Assert(Result.Offset(Result.Size) = pVariable,
    'Possible memory overrun when marshling security attributes');
end;

function NtxpParseClaimAttributes;
var
  pAttribute: PClaimSecurityAttributeV1;
  i, j: Integer;
begin
  if Buffer.Version <> SECURITY_ATTRIBUTES_INFORMATION_VERSION_V1 then
  begin
    // Don't know how to handle those
    SetLength(Result, 0);
    Exit;
  end;

  SetLength(Result, Buffer.AttributeCount);
  for i := 0 to High(Result) do
    with Result[i] do
    begin
      pAttribute := @Buffer.AttributeV1{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};

      Name := pAttribute.Name;
      ValueType := pAttribute.ValueType;
      Flags := pAttribute.Flags;

      // Capture values depending on their type
      case ValueType of
        SECURITY_ATTRIBUTE_TYPE_INT64, SECURITY_ATTRIBUTE_TYPE_UINT64,
        SECURITY_ATTRIBUTE_TYPE_BOOLEAN:
          begin
            SetLength(ValuesUInt64, pAttribute.ValueCount);

            for j := 0 to High(ValuesUInt64) do
              ValuesUInt64[j] := pAttribute
                .ValuesUInt64{$R-}[j]{$IFDEF R+}{$R+}{$ENDIF};
          end;

        SECURITY_ATTRIBUTE_TYPE_STRING:
          begin
            SetLength(ValuesString, pAttribute.ValueCount);

            for j := 0 to High(ValuesString) do
              ValuesString[j] := pAttribute
                .ValuesString{$R-}[j]{$IFDEF R+}{$R+}{$ENDIF};
          end;

        SECURITY_ATTRIBUTE_TYPE_FQBN:
          begin
            SetLength(ValuesFqbn, pAttribute.ValueCount);

            for j := 0 to High(ValuesFqbn) do
              with pAttribute.ValuesFqbn{$R-}[j]{$IFDEF R+}{$R+}{$ENDIF} do
              begin
                ValuesFqbn[j].Version := Version;
                ValuesFqbn[j].Name := Name;
              end;
          end;

        SECURITY_ATTRIBUTE_TYPE_SID, SECURITY_ATTRIBUTE_TYPE_OCTET_STRING:
          begin
            SetLength(ValuesOctet, pAttribute.ValueCount);

            for j := 0 to High(ValuesOctet) do
              with pAttribute.ValuesOctet{$R-}[j]{$IFDEF R+}{$R+}{$ENDIF} do
                ValuesOctet[i] := Auto.CopyDynamic(pValue, ValueLength);
          end;
      end;
    end;
end;

function SidInfoRefOrNil;
begin
  if Assigned(Sid) then
    Result := PTokenSidInformation(@Sid)
  else
    Result := nil;
end;

function DefaultDaclRefOrNil;
begin
  if Assigned(Acl) then
    Result := PTokenDefaultDacl(@Acl)
  else
    Result := nil;
end;

end.
