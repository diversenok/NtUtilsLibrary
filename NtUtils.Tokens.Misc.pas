unit NtUtils.Tokens.Misc;

{
  The module includes helper functions for parsing and allocated token-related
  structures.
}

interface

uses
  Winapi.WinNt, Ntapi.ntseapi, NtUtils, NtUtils.Tokens, DelphiUtils.AutoObject;

function NtxpAllocPrivileges(
  [opt] const Privileges: TArray<TLuid>;
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
  [in] Buffer: PTokenSecurityAttributes
): TArray<TSecurityAttribute>;

function NtxpAllocSecurityAttributes(
  const Attributes: TArray<TSecurityAttribute>
): IMemory<PTokenSecurityAttributes>;

function NtxpParseClaimAttributes(
  [in] Buffer: PClaimSecurityAttributes
): TArray<TSecurityAttribute>;

implementation

uses
  Ntapi.ntdef, Ntapi.ntrtl, NtUtils.Security.Sid;

function NtxpAllocPrivileges;
var
  i: Integer;
begin
  IMemory(Result) := TAutoMemory.Allocate(SizeOf(Integer) +
    Length(Privileges) * SizeOf(TLuidAndAttributes));

  Result.Data.PrivilegeCount := Length(Privileges);

  for i := 0 to High(Privileges) do
  begin
    Result.Data.Privileges{$R-}[i]{$R+}.Luid := Privileges[i];
    Result.Data.Privileges{$R-}[i]{$R+}.Attributes := Attribute;
  end;
end;

function NtxpAllocPrivileges2;
var
  i: Integer;
begin
  IMemory(Result) := TAutoMemory.Allocate(SizeOf(Integer) +
    Length(Privileges) * SizeOf(TLuidAndAttributes));

  Result.Data.PrivilegeCount := Length(Privileges);

  for i := 0 to High(Privileges) do
    Result.Data.Privileges{$R-}[i]{$R+} := Privileges[i];
end;

function NtxpAllocWellKnownPrivileges;
var
  i: Integer;
begin
  IMemory(Result) := TAutoMemory.Allocate(SizeOf(Integer) +
    Length(Privileges) * SizeOf(TLuidAndAttributes));

  Result.Data.PrivilegeCount := Length(Privileges);

  for i := 0 to High(Privileges) do
  begin
    Result.Data.Privileges{$R-}[i]{$R+}.Luid := TLuid(Privileges[i]);
    Result.Data.Privileges{$R-}[i]{$R+}.Attributes := Attribute;
  end;
end;

function NtxpAllocPrivilegeSet;
var
  i: Integer;
begin
  IMemory(Result) := TAutoMemory.Allocate(SizeOf(Cardinal) +
    SizeOf(Cardinal) + SizeOf(TLuidAndAttributes) * Length(Privileges));

  Result.Data.PrivilegeCount := Length(Privileges);
  Result.Data.Control := 0;

  for i := 0 to High(Privileges) do
    Result.Data.Privilege{$R-}[i]{$R+} := Privileges[i];
end;

function NtxpAllocGroups;
var
  i: Integer;
begin
  IMemory(Result) := TAutoMemory.Allocate(SizeOf(Integer) +
    Length(Sids) * SizeOf(TSidAndAttributes));

  Result.Data.GroupCount := Length(Sids);

  for i := 0 to High(Sids) do
  begin
    Result.Data.Groups{$R-}[i]{$R+}.Sid := Sids[i].Data;
    Result.Data.Groups{$R-}[i]{$R+}.Attributes := Attribute;
  end;
end;

function NtxpAllocGroups2;
var
  i: Integer;
begin
  IMemory(Result) := TAutoMemory.Allocate(SizeOf(Integer) +
    Length(Groups) * SizeOf(TSidAndAttributes));

  Result.Data.GroupCount := Length(Groups);

  for i := 0 to High(Groups) do
  begin
    Result.Data.Groups{$R-}[i]{$R+}.Sid := Groups[i].SID.Data;
    Result.Data.Groups{$R-}[i]{$R+}.Attributes := Groups[i].Attributes;
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
      pAttribute := @Buffer.AttributeV1{$R-}[i]{$R+};

      Name := pAttribute.Name.ToString;
      ValueType := pAttribute.ValueType;
      Flags := pAttribute.Flags;

      // Capture values depending on their type
      case ValueType of
        SECURITY_ATTRIBUTE_TYPE_INT64, SECURITY_ATTRIBUTE_TYPE_UINT64,
        SECURITY_ATTRIBUTE_TYPE_BOOLEAN:
          begin
            SetLength(ValuesUInt64, pAttribute.ValueCount);

            for j := 0 to High(ValuesUInt64) do
              ValuesUInt64[j] := pAttribute.ValuesUInt64{$R-}[j]{$R+};
          end;

        SECURITY_ATTRIBUTE_TYPE_STRING:
          begin
            SetLength(ValuesString, pAttribute.ValueCount);

            for j := 0 to High(ValuesString) do
              ValuesString[j] := pAttribute.ValuesString{$R-}[j]{$R+}.ToString;
          end;

        SECURITY_ATTRIBUTE_TYPE_FQBN:
          begin
            SetLength(ValuesFqbn, pAttribute.ValueCount);

            for j := 0 to High(ValuesFqbn) do
              with pAttribute.ValuesFqbn{$R-}[j]{$R+} do
              begin
                ValuesFqbn[j].Version := Version;
                ValuesFqbn[j].Name := Name.ToString;
              end;
          end;

        SECURITY_ATTRIBUTE_TYPE_SID:
          begin
            SetLength(ValuesSid, pAttribute.ValueCount);

            for j := 0 to High(ValuesSid) do
              RtlxCopySid(pAttribute.ValuesOctet{$R-}[j]{$R+}.pValue,
                ValuesSid[j]);
          end;

        SECURITY_ATTRIBUTE_TYPE_OCTET_STRING:
          begin
            SetLength(ValuesOctet, pAttribute.ValueCount);

            for j := 0 to High(ValuesOctet) do
              with pAttribute.ValuesOctet{$R-}[j]{$R+} do
                ValuesOctet[i] := TAutoMemory.CaptureCopy(
                  pValue, ValueLength);
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

      SECURITY_ATTRIBUTE_TYPE_SID:
      begin
        Inc(BufferSize, Length(Attributes[i].ValuesSid) *
          SizeOf(TTokenSecurityAttributeOctetStringValue));
        BufferSize := AlighUp(BufferSize);

        for j := 0 to High(Attributes[i].ValuesSid) do
        begin
          Inc(BufferSize, RtlLengthSid(Attributes[i].ValuesSid[j].Data));
          BufferSize := AlighUp(BufferSize);
        end;
      end;

      SECURITY_ATTRIBUTE_TYPE_OCTET_STRING:
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

  IMemory(Result) := TAutoMemory.Allocate(BufferSize);

  // Fill the header
  Result.Data.Version := SECURITY_ATTRIBUTES_INFORMATION_VERSION_V1;
  Result.Data.AttributeCount := Length(Attributes);

  // Nothing else to do if there are no attributes
  if Length(Attributes) = 0 then
    Exit;

  // Point the first attribute right after the header
  pAttribute := AlighUp(Result.Offset(SizeOf(TTokenSecurityAttributes)));

  Result.Data.AttributeV1 := Pointer(pAttribute);

  // Reserve space for attribute array. Point to the variable part.
  pVariable := AlighUp(Pointer(IntPtr(pAttribute) + Length(Attributes) *
    SizeOf(TTokenSecurityAttributeV1)));

  for i := 0 to High(Attributes) do
  begin
    pAttribute.ValueType := Attributes[i].ValueType;
    pAttribute.Flags := Attributes[i].Flags;

    // Serialize the string
    TNtUnicodeString.Marshal(Attributes[i].Name, @pAttribute.Name,
      PWideChar(pVariable));

    Inc(pVariable, pAttribute.Name.MaximumLength);
    pVariable := AlighUp(pVariable);
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
        pVariable := AlighUp(pVariable);
      end;

      SECURITY_ATTRIBUTE_TYPE_STRING:
      begin
        pAttribute.ValueCount := Length(Attributes[i].ValuesString);

        // Reserve space for sequential UNICODE_STRING array
        Inc(pVariable, SizeOf(TNtUnicodeString) *
          Length(Attributes[i].ValuesString));
        pVariable := AlighUp(pVariable);

        for j := 0 to High(Attributes[i].ValuesString) do
        begin
          // Serialize each string content
          TNtUnicodeString.Marshal(Attributes[i].ValuesString[j],
            @pAttribute.ValuesString{$R-}[j]{$R+}, PWideChar(pVariable));

          // Move the variable pointer
          Inc(pVariable, pAttribute.ValuesString{$R-}[j]{$R+}.MaximumLength);
          pVariable := AlighUp(pVariable);
        end;
      end;

      SECURITY_ATTRIBUTE_TYPE_FQBN:
      begin
        pAttribute.ValueCount := Length(Attributes[i].ValuesFqbn);

        // Reserve space for sequential FQBN array
        Inc(pVariable, SizeOf(TTokenSecurityAttributeFqbnValue) *
          Length(Attributes[i].ValuesFqbn));
        pVariable := AlighUp(pVariable);

        for j := 0 to High(Attributes[i].ValuesFqbn) do
        begin
          // Copy each string content and make a closure
          pFqbn := @pAttribute.ValuesFQBN{$R-}[j]{$R+};
          pFqbn.Version := Attributes[i].ValuesFqbn[j].Version;

          TNtUnicodeString.Marshal(Attributes[i].ValuesFqbn[j].Name,
            @pFqbn.Name, PWideChar(pVariable));

          Inc(pVariable, pFqbn.Name.MaximumLength);
          pVariable := AlighUp(pVariable);
        end;
      end;

      SECURITY_ATTRIBUTE_TYPE_SID:
      begin
        pAttribute.ValueCount := Length(Attributes[i].ValuesSid);

        // Reserve space for sequential octet array
        Inc(pVariable, SizeOf(TTokenSecurityAttributeOctetStringValue) *
          Length(Attributes[i].ValuesSid));
        pVariable := AlighUp(pVariable);

        for j := 0 to High(Attributes[i].ValuesSid) do
        begin
          // Copy the SIDs
          pOct := @pAttribute.ValuesOctet{$R-}[j]{$R+};
          pOct.ValueLength := RtlLengthSid(Attributes[i].ValuesSid[j].Data);
          Move(Attributes[i].ValuesSid[j].Data^, pVariable^, pOct.ValueLength);
          pOct.pValue := pVariable;
          Inc(pVariable, pOct.ValueLength);
          pVariable := AlighUp(pVariable);
        end;
      end;

      SECURITY_ATTRIBUTE_TYPE_OCTET_STRING:
      begin
        pAttribute.ValueCount := Length(Attributes[i].ValuesOctet);

        // Reserve space for sequential octet array
        Inc(pVariable, SizeOf(TTokenSecurityAttributeOctetStringValue) *
          Length(Attributes[i].ValuesOctet));
        pVariable := AlighUp(pVariable);

        for j := 0 to High(Attributes[i].ValuesOctet) do
        begin
          // Copy the data
          pOct := @pAttribute.ValuesOctet{$R-}[j]{$R+};
          pOct.ValueLength := Cardinal(Attributes[i].ValuesOctet[j].Size);
          Move(Attributes[i].ValuesOctet[j].Data^, pVariable^,
            pOct.ValueLength);
          pOct.pValue := pVariable;
          Inc(pVariable, pOct.ValueLength);
          pVariable := AlighUp(pVariable);
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
      pAttribute := @Buffer.AttributeV1{$R-}[i]{$R+};

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
              ValuesUInt64[j] := pAttribute.ValuesUInt64{$R-}[j]{$R+};
          end;

        SECURITY_ATTRIBUTE_TYPE_STRING:
          begin
            SetLength(ValuesString, pAttribute.ValueCount);

            for j := 0 to High(ValuesString) do
              ValuesString[j] := pAttribute.ValuesString{$R-}[j]{$R+};
          end;

        SECURITY_ATTRIBUTE_TYPE_FQBN:
          begin
            SetLength(ValuesFqbn, pAttribute.ValueCount);

            for j := 0 to High(ValuesFqbn) do
              with pAttribute.ValuesFqbn{$R-}[j]{$R+} do
              begin
                ValuesFqbn[j].Version := Version;
                ValuesFqbn[j].Name := Name;
              end;
          end;

        SECURITY_ATTRIBUTE_TYPE_SID:
          begin
            SetLength(ValuesSid, pAttribute.ValueCount);

            for j := 0 to High(ValuesSid) do
              RtlxCopySid(pAttribute.ValuesOctet{$R-}[j]{$R+}.pValue,
                ValuesSid[j]);
          end;

        SECURITY_ATTRIBUTE_TYPE_OCTET_STRING:
          begin
            SetLength(ValuesOctet, pAttribute.ValueCount);

            for j := 0 to High(ValuesOctet) do
              with pAttribute.ValuesOctet{$R-}[j]{$R+} do
                ValuesOctet[i] := TAutoMemory.CaptureCopy(
                  pValue, ValueLength);
          end;
      end;
    end;
end;

end.
