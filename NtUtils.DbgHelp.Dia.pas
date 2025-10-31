unit NtUtils.DbgHelp.Dia;

{
  This module provides wrappers for usig DIA (Debug Interface Access) API for
  parsing PDB files.
}

interface

uses
  Ntapi.DbgHelp, Ntapi.ImageHlp, Ntapi.msdia, NtUtils;

var
  // The path to the DLL when the CLSID is not registered
  MsdiaDllPath: String = msdia140;

type
  TDiaxTypeFormatOptions = set of (
    dtfoAllowVarAgrs // Format zero-size NoType as "..." instead of "VOID"
  );

  TDiaxFunctionFormatOptions = set of (
    dffoMultiLine, // Format a function with each parameter on a new line
    dffoValidateArdDataMatch // Verify that argument types match param data types
  );

  TDiaxArgumentFormat = record
    TypeName: String;
    Name: String;
  end;

  TDiaxFunctionFormat = record
    ReturnTypeName: String;
    CallingConvention: String;
    FunctionName: String;
    Arguments: TArray<TDiaxArgumentFormat>;
  end;

{ PDB }

// Open a DIA session to on a PDB file
function DiaxRtlxLoadPdb(
  out Session: IDiaSession;
  const PdbPath: String
): TNtxStatus;

// Open a DIA session to on an EXE/DLL file
function DiaxRtlxLoadExe(
  out Session: IDiaSession;
  const ExePath: String;
  const SearchPath: String = 'C:\Symbols'
): TNtxStatus;

{ Symbom enumeration }

// Find the first matching child of a symbol
function DiaxSymbolFindChild(
  out Child: IDiaSymbol;
  const Symbol: IDiaSymbol;
  const Name: String;
  CompareFlags: TNameSearchOptions = 0;
  SymTag: TSymTagEnum = TSymTagEnum.SymTagNull
): TNtxStatus;

// Iterate over children of a symbol
function DiaxSymbolIterateChildren(
  [opt] Status: PNtxStatus;
  const Symbol: IDiaSymbol;
  SymTag: TSymTagEnum = TSymTagEnum.SymTagNull;
  [opt] const Name: String = '';
  CompareFlags: TNameSearchOptions = 0
): IEnumerable<IDiaSymbol>;

// Enumerate children of a symbol
function DiaxSymbolEnumerateChildren(
  out Children: TArray<IDiaSymbol>;
  const Symbol: IDiaSymbol;
  SymTag: TSymTagEnum = TSymTagEnum.SymTagNull;
  [opt] const Name: String = '';
  CompareFlags: TNameSearchOptions = 0
): TNtxStatus;

{ Symbol information }

// Determine the tag type of a symbol
function DiaxSymbolGetTag(
  const Symbol: IDiaSymbol;
  out Tag: TSymTagEnum
): TNtxStatus;

// Determine the type symbol associated with a symbol
function DiaxSymbolGetType(
  const Symbol: IDiaSymbol;
  out SymbolType: IDiaSymbol
): TNtxStatus;

// Determine the type symbol associated with a symbol. Do not fail if no type
function DiaxSymbolGetTypeOrNil(
  const Symbol: IDiaSymbol;
  out SymbolType: IDiaSymbol
): TNtxStatus;

// Determine the locally unique ID of the symbol
function DiaxSymbolGetIndexId(
  const Symbol: IDiaSymbol;
  out IndexId: Cardinal
): TNtxStatus;

// Determine the basic type of a symbol
function DiaxSymbolGetBasicType(
  const Symbol: IDiaSymbol;
  out BasicType: TBasicType
): TNtxStatus;

// Determine the kind of a UDT symbol
function DiaxSymbolGetUdtKind(
  const Symbol: IDiaSymbol;
  out Kind: TUdtKind
): TNtxStatus;

// Determine the name of a symbol
function DiaxSymbolGetName(
  const Symbol: IDiaSymbol;
  out Name: String
): TNtxStatus;

// Determine the length/size of a symbol
function DiaxSymbolGetSize(
  const Symbol: IDiaSymbol;
  out Size: UInt64
): TNtxStatus;

// Determine the number of elements in an array symbol
function DiaxSymbolGetCount(
  const Symbol: IDiaSymbol;
  out Count: Cardinal
): TNtxStatus;

// Determine the kind of a data symbol
function DiaxSymbolGetDataKind(
  const Symbol: IDiaSymbol;
  out Kind: TDataKind
): TNtxStatus;

// Determine if a symbol is constant
function DiaxSymbolGetConst(
  const Symbol: IDiaSymbol;
  out IsConst: LongBool
): TNtxStatus;

// Determine if a symbol is volatile
function DiaxSymbolGetVolatile(
  const Symbol: IDiaSymbol;
  out IsVolatile: LongBool
): TNtxStatus;

// Determine the calling convention of a function symbol
function DiaxSymbolGetCallingConvention(
  const Symbol: IDiaSymbol;
  out Convention: TCvCallE
): TNtxStatus;

// Determine the image machine type of a symbol
function DiaxSymbolMachine(
  const Symbol: IDiaSymbol;
  out MachineType: TImageMachine32
): TNtxStatus;

// Determines if two symbols are equivalent or point to the same user type
function DiaxSymbolsAreIdentical(
  const SymbolA: IDiaSymbol;
  const SymbolB: IDiaSymbol;
  out Identical: Boolean
): TNtxStatus;

{ Symbol formatting }

// Determine the name for a calling convention of a function symbol
function DiaxSymbolFormatCallingConvention(
  const Scope: IDiaSymbol;
  const Symbol: IDiaSymbol;
  out ConventionName: String
): TNtxStatus;

// Format a complex symbol type name
function DiaxSymbolFormatType(
  const Scope: IDiaSymbol;
  const Symbol: IDiaSymbol;
  out TypeName: String;
  Options: TDiaxTypeFormatOptions = []
): TNtxStatus;

// Format a function or a function type symbol into a string
function DiaxSymbolFormatFunction(
  const Scope: IDiaSymbol;
  const Symbol: IDiaSymbol;
  out FormatString: String;
  Options: TDiaxFunctionFormatOptions = [dffoMultiLine, dffoValidateArdDataMatch]
): TNtxStatus;

// Format a function or a function type symbol
function DiaxSymbolFormatFunctionEx(
  const Scope: IDiaSymbol;
  const Symbol: IDiaSymbol;
  out Format: TDiaxFunctionFormat;
  Options: TDiaxFunctionFormatOptions = [dffoValidateArdDataMatch]
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.WinError, NtUtils.Com, NtUtils.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ PDB }

function DiaxRtlxLoadPdb;
var
  DataSource: IDiaDataSource;
begin
  Result := RtlxComCreateInstance(MsdiaDllPath, CLSID_DiaSource, IDiaDataSource,
    DataSource, 'CLSID_DiaSource');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IDiaDataSource::LoadDataFromPdb';
  Result.HResult := DataSource.LoadDataFromPdb(PdbPath);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IDiaDataSource::OpenSession';
  Result.HResult := DataSource.OpenSession(Session);
end;

function DiaxRtlxLoadExe;
var
  DataSource: IDiaDataSource;
begin
  Result := RtlxComCreateInstance(MsdiaDllPath, CLSID_DiaSource, IDiaDataSource,
    DataSource, 'CLSID_DiaSource');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IDiaDataSource::LoadDataForExe';
  Result.HResult := DataSource.LoadDataForExe(ExePath, SearchPath, nil);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IDiaDataSource::OpenSession';
  Result.HResult := DataSource.OpenSession(Session);
end;

{ Symbol enumeration }

function DiaxSymbolFindChild;
var
  Enum: IDiaEnumSymbols;
  Count: Integer;
begin
  Result.Location := 'IDiaSymbol::findChildren';
  Result.HResult := Symbol.findChildren(SymTag, Name, CompareFlags,
    Enum);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IDiaEnumSymbols::get_Count';
  Result.HResult := Enum.get_Count(Count);

  if not Result.IsSuccess then
    Exit;

  if Count > 0 then
  begin
    Result.Location := 'IDiaEnumSymbols::Item';
    Result.HResult := Enum.Item(0, Child);
  end
  else
  begin
    Result.Location := 'DiaxSymbolFindChild';
    Result.Status := STATUS_NOT_FOUND;
  end;
end;

function DiaxSymbolIterateChildren;
var
  Enum: IDiaEnumSymbols;
  Index, Count: Integer;
begin
  Index := 0;

  Result := NtxAuto.IterateEx<IDiaSymbol>(
    Status,
    function : TNtxStatus
    begin
      Result.Location := 'IDiaSymbol::findChildren';
      Result.HResult := Symbol.findChildren(SymTag, Name, CompareFlags, Enum);

      if not Result.IsSuccess then
        Exit;

      Result.Location := 'IDiaEnumSymbols::get_Count';
      Result.HResult := Enum.get_Count(Count);
    end,
    function (out Entry: IDiaSymbol): TNtxStatus
    begin
      if Index < Count then
      begin
        Result.Location := 'IDiaEnumSymbols::Item';
        Result.HResult := Enum.Item(Index, Entry);
      end
      else
      begin
        Result.Location := 'DiaxSymbolIterateChildren';
        Result.Status := STATUS_NO_MORE_ENTRIES;
      end;

      if Result.IsSuccess then
        Inc(Index);
    end
  );
end;

function DiaxSymbolEnumerateChildren;
var
  Enum: IDiaEnumSymbols;
  Count, Fetched: Integer;
begin
  Result.Location := 'IDiaSymbol::findChildren';
  Result.HResult := Symbol.findChildren(SymTag, Name, CompareFlags, Enum);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IDiaEnumSymbols::get_Count';
  Result.HResult := Enum.get_Count(Count);

  if not Result.IsSuccess then
    Exit;

  Children := nil;

  if Count > 0 then
  begin
    SetLength(Children, Count);

    // Retrieve all entries
    Result.Location := 'IDiaEnumSymbols::Next';
    Result.HResult := Enum.Next(Count, Children[0], Fetched);

    // Truncate if necessary
    if Result.IsSuccess and (Fetched < Count) then
      SetLength(Children, Fetched);
  end;
end;

{ Symbol information }

function DiaxSymbolGetTag;
begin
  Result.Location := 'IDiaSymbol::get_symTag';
  Result.HResult := Symbol.get_symTag(Tag);
end;

function DiaxSymbolGetType;
begin
  Result.Location := 'IDiaSymbol::get_type';
  Result.HResult := Symbol.get_type(SymbolType);
end;

function DiaxSymbolGetTypeOrNil;
begin
  Result.Location := 'IDiaSymbol::get_type';
  Result.HResultAllowFalse := Symbol.get_type(SymbolType);

  if Result.HResult = S_FALSE then
    SymbolType := nil;
end;

function DiaxSymbolGetIndexId;
begin
  Result.Location := 'IDiaSymbol::get_symIndexId';
  Result.HResult := Symbol.get_symIndexId(IndexId);
end;

function DiaxSymbolGetBasicType;
begin
  Result.Location := 'IDiaSymbol::get_baseType';
  Result.HResult := Symbol.get_baseType(BasicType);
end;

function DiaxSymbolGetUdtKind;
begin
  Result.Location := 'IDiaSymbol::get_udtKind';
  Result.HResult := Symbol.get_udtKind(Kind);
end;

function DiaxSymbolGetName;
var
  WideName: WideString;
begin
  Result.Location := 'IDiaSymbol::get_name';
  Result.HResult := Symbol.get_name(WideName);

  if Result.IsSuccess then
    Name := WideName;
end;

function DiaxSymbolGetSize;
begin
  Result.Location := 'IDiaSymbol::get_length';
  Result.HResult := Symbol.get_length(Size);
end;

function DiaxSymbolGetCount;
begin
  Result.Location := 'IDiaSymbol::get_count';
  Result.HResult := Symbol.get_count(Count);
end;

function DiaxSymbolGetDataKind;
begin
  Result.Location := 'IDiaSymbol::get_dataKind';
  Result.HResult := Symbol.get_dataKind(Kind);
end;

function DiaxSymbolGetConst;
begin
  Result.Location := 'IDiaSymbol::get_constType';
  Result.HResult := Symbol.get_constType(IsConst);
end;

function DiaxSymbolGetVolatile;
begin
  Result.Location := 'IDiaSymbol::get_volatileType';
  Result.HResult := Symbol.get_volatileType(IsVolatile);
end;

function DiaxSymbolGetCallingConvention;
begin
  Result.Location := 'IDiaSymbol::get_callingConvention';
  Result.HResult := Symbol.get_callingConvention(Convention);
end;

function DiaxSymbolMachine;
begin
  Result.Location := 'IDiaSymbol::get_machineType';
  Result.HResult := Symbol.get_machineType(MachineType);
end;

function DiaxSymbolsAreIdentical;
var
  IdA, IdB: Cardinal;
  TagA, TagB: TSymTagEnum;
  NameA, NameB: String;
  PointerA, PointerB: IDiaSymbol;
  BasicTypeA, BasicTypeB: TBasicType;
  SizeA, SizeB: UInt64;
begin
  if SymbolA = SymbolB then
  begin
    // The same pointer
    Identical := True;
    Exit(NtxSuccess);
  end;

  // Compare IDs
  Result := DiaxSymbolGetIndexId(SymbolA, IdA);

  if not Result.IsSuccess then
    Exit;

  Result := DiaxSymbolGetIndexId(SymbolB, IdB);

  if not Result.IsSuccess then
    Exit;

  if IdA = IdB then
  begin
    // The same symbol
    Identical := True;
    Exit(NtxSuccess);
  end;

  // Compare tags
  Result := DiaxSymbolGetTag(SymbolA, TagA);

  if not Result.IsSuccess then
    Exit;

  Result := DiaxSymbolGetTag(SymbolB, TagB);

  if not Result.IsSuccess then
    Exit;

  if TagA <> TagB then
  begin
    // Different kinds of symbols
    Identical := False;
    Exit(NtxSuccess);
  end;

  case TagA of
    SymTagBaseType:
    begin
      // Lookup sizes
      Result := DiaxSymbolGetSize(SymbolA, SizeA);

      if not Result.IsSuccess then
        Exit;

      Result := DiaxSymbolGetSize(SymbolB, SizeB);

      if not Result.IsSuccess then
        Exit;

      if SizeA <> SizeB then
      begin
        // Different sizes
        Identical := False;
        Exit(NtxSuccess);
      end;

      // Lookup basic types
      Result := DiaxSymbolGetBasicType(SymbolA, BasicTypeA);

      if not Result.IsSuccess then
        Exit;

      Result := DiaxSymbolGetBasicType(SymbolB, BasicTypeB);

      if not Result.IsSuccess then
        Exit;

      // Compare the underlying types
      Identical := BasicTypeA = BasicTypeB;
      Exit(NtxSuccess);
    end;

    SymTagUDT, SymTagEnum:
    begin
      // Lookup names
      Result := DiaxSymbolGetName(SymbolA, NameA);

      if not Result.IsSuccess then
        Exit;

      Result := DiaxSymbolGetName(SymbolB, NameB);

      if not Result.IsSuccess then
        Exit;

      Identical := NameA = NameB;
      Exit(NtxSuccess);
    end;

    SymTagPointerType:
    begin
      // Lookup referenced pointer types
      Result := DiaxSymbolGetType(SymbolA, PointerA);

      if not Result.IsSuccess then
        Exit;

      Result := DiaxSymbolGetType(SymbolB, PointerB);

      if not Result.IsSuccess then
        Exit;

      // Recurse
      Result := DiaxSymbolsAreIdentical(PointerA, PointerB, Identical);
    end;
  end;
end;

{ Symbol formatting }

function DiaxSymbolFormatCallingConvention;
var
  Convention: TCvCallE;
  Machine: TImageMachine32;
begin
  // Lookup the common
  Result := DiaxSymbolGetCallingConvention(Symbol, Convention);

  if not Result.IsSuccess then
    Exit;

  case Convention of
    CV_CALL_NEAR_C, CV_CALL_FAR_C:
    begin
      // We need to know the architecture bitness
      Result := DiaxSymbolMachine(Scope, Machine);

      if not Result.IsSuccess then
        Exit;

      case Machine of
        // Caller cleanup, RTL
        IMAGE_FILE_MACHINE_I386, IMAGE_FILE_MACHINE_ARMNT:
          ConventionName := '__cdecl';

        // Callee cleanup, RTL
        IMAGE_FILE_MACHINE_AMD64, IMAGE_FILE_MACHINE_ARM64,
          IMAGE_FILE_MACHINE_IA64:
          ConventionName := '__stdcall';
      else
        Result.Location := 'DiaxSymbolFormatCallingConvention';
        Result.LastCall.UsesInfoClass(Machine, icParse);
        Result.Status := STATUS_UNKNOWN_REVISION;
      end;
    end;

    // Callee cleanup, RTL
    CV_CALL_NEAR_FAST, CV_CALL_FAR_FAST:
      ConventionName := '__fastcall';

    // Callee cleanup, RTL
    CV_CALL_NEAR_STD, CV_CALL_FAR_STD:
      ConventionName := '__stdcall';

    // Callee cleanup, RTL
    CV_CALL_THISCALL:
      ConventionName := '__thiscall';

    // N/A cleanup, LTR
    CV_CALL_CLRCALL:
      ConventionName := '__clrcall';

    // Callee cleanup, RTL
    CV_CALL_NEAR_VECTOR:
      ConventionName := '__vectorcall';
  else
    Result.Location := 'DiaxSymbolFormatCallingConvention';
    Result.LastCall.UsesInfoClass(Convention, icParse);
    Result.Status := STATUS_UNKNOWN_REVISION;
  end;
end;

function DiaxSymbolFormatType;
var
  Tag: TSymTagEnum;
  BasicType: TBasicType;
  UdtKind: TUdtKind;
  Size: UInt64;
  Count: Cardinal;
  IsConst: LongBool;
  StringPart: String;
  NestedType: IDiaSymbol;
begin
  // Classify by symbol tag
  Result := DiaxSymbolGetTag(Symbol, Tag);

  if not Result.IsSuccess then
    Exit;

  case Tag of
    // User-defined types use their name
    SymTagUDT, SymTagEnum:
    begin
      if Tag = SymTagUDT then
      begin
        // Lookup the type kind
        Result := DiaxSymbolGetUdtKind(Symbol, UdtKind);

        if not Result.IsSuccess then
          Exit;

        case UdtKind of
          UdtStruct: StringPart := 'struct ';
          UdtClass: StringPart := 'class ';
          UdtUnion: StringPart := 'union ';
          UdtInterface: StringPart := 'interface ';
        else
          Result.Location := 'DiaxSymbolFormatSDKType';
          Result.LastCall.UsesInfoClass(UdtKind, icParse);
          Result.Status := STATUS_UNKNOWN_REVISION;
        end;
      end
      else if Tag = SymTagEnum then
        StringPart := 'enum ';

      // Lookup name
      Result := DiaxSymbolGetName(Symbol, TypeName);

      if not Result.IsSuccess then
        Exit;

      if TypeName = '' then
        TypeName := '<unnamed type>';

      TypeName := StringPart + TypeName;
    end;

    // Base types require identification
    SymTagBaseType:
    begin
      // Lookup the built-in type
      Result := DiaxSymbolGetBasicType(Symbol, BasicType);

      if not Result.IsSuccess then
        Exit;

      // And its size
      Result := DiaxSymbolGetSize(Symbol, Size);

      if not Result.IsSuccess then
        Exit;

      if (BasicType = btVoid) and (Size = 0) then
        TypeName := 'VOID'
      else if (BasicType = btChar) and (Size = SizeOf(AnsiChar)) then
        TypeName := 'CHAR'
      else if (BasicType = btWChar) and (Size = SizeOf(WideChar)) then
        TypeName := 'WCHAR'
      else if (BasicType = btInt) and (Size = SizeOf(ShortInt)) then
        TypeName := 'INT8'
      else if (BasicType = btInt) and (Size = SizeOf(SmallInt)) then
        TypeName := 'INT16'
      else if (BasicType = btInt) and (Size = SizeOf(Integer)) then
        TypeName := 'INT32'
      else if (BasicType = btInt) and (Size = SizeOf(Int64)) then
        TypeName := 'INT64'
      else if (BasicType = btUInt) and (Size = SizeOf(Byte)) then
        TypeName := 'UINT8'
      else if (BasicType = btUInt) and (Size = SizeOf(Word)) then
        TypeName := 'UINT16'
      else if (BasicType = btUInt) and (Size = SizeOf(Cardinal)) then
        TypeName := 'UINT32'
      else if (BasicType = btUInt) and (Size = SizeOf(UInt64)) then
        TypeName := 'UINT64'
      else if (BasicType = btLong) and (Size = SizeOf(Integer)) then
        TypeName := 'LONG'
      else if (BasicType = btLong) and (Size = SizeOf(Int64)) then
        TypeName := 'LONG64'
      else if (BasicType = btULong) and (Size = SizeOf(Cardinal)) then
        TypeName := 'ULONG'
      else if (BasicType = btULong) and (Size = SizeOf(UInt64)) then
        TypeName := 'ULONG64'
      else if (BasicType = btFloat) and (Size = SizeOf(Single)) then
        TypeName := 'FLOAT'
      else if (BasicType = btFloat) and (Size = SizeOf(Double)) then
        TypeName := 'DOUBLE'
      else if (BasicType = btFloat) and (Size = 10) then
        TypeName := 'LDOUBLE'
      else if (BasicType = btBool) and (Size = SizeOf(Boolean)) then
        TypeName := 'BOOLEAN'
      else if (BasicType = btBool) and (Size = SizeOf(LongBool)) then
        TypeName := 'BOOL'
      else if (BasicType = btVariant) and (Size = SizeOf(TVarData)) then
        TypeName := 'VARIANT'
      else if (BasicType = btHresult) and (Size = SizeOf(HResult)) then
        TypeName := 'HRESULT'
      else if (BasicType = btChar8) and (Size = SizeOf(AnsiChar)) then
        TypeName := 'CHAR8'
      else if (BasicType = btChar16) and (Size = SizeOf(WideChar)) then
        TypeName := 'CHAR16'
      else if (BasicType = btChar32) and (Size = SizeOf(Cardinal)) then
        TypeName := 'CHAR32'
      else if (BasicType = btNoType) and (Size = 0) then
      begin
        if dtfoAllowVarAgrs in Options then
          TypeName := '...'
        else
          TypeName := 'VOID';
      end
      else
      begin
        Result.Location := 'DiaxSymbolFormatSDKType';
        Result.LastCall.UsesInfoClass(BasicType, icParse);
        Result.Status := STATUS_UNKNOWN_REVISION;

        if not Result.IsSuccess then
          Exit;
      end;
    end;

    // Arrays use element type
    SymTagArrayType:
    begin
      Result := DiaxSymbolGetType(Symbol, NestedType);

      if not Result.IsSuccess then
        Exit;

      Result := DiaxSymbolFormatType(Scope, NestedType, TypeName);

      if not Result.IsSuccess then
        Exit;

      Result := DiaxSymbolGetCount(Symbol, Count);

      if not Result.IsSuccess then
        Exit;

      TypeName := RtlxFormatString('%s [%u]', [TypeName, Count]);
    end;

    // Pointers and typedefs require dereferencing
    SymTagPointerType, SymTagTypedef:
    begin
      Result := DiaxSymbolGetType(Symbol, NestedType);

      if not Result.IsSuccess then
        Exit;

      // Call recursively
      Result := DiaxSymbolFormatType(Scope, NestedType, TypeName);

      if not Result.IsSuccess then
        Exit;

      if Tag = SymTagPointerType then
        TypeName := TypeName + '*';
    end;

    // Function types require collecting arguments
    SymTagFunctionType:
    begin
      Result := DiaxSymbolFormatFunction(Scope, Symbol, TypeName, []);

      if not Result.IsSuccess then
        Exit;

      TypeName := '(' + TypeName + ')';
    end

  else
    // Might need more work
    Result.Location := 'DiaxSymbolFormatSDKType';
    Result.LastCall.UsesInfoClass(Tag, icParse);
    Result.Status := STATUS_NOT_IMPLEMENTED;

    if not Result.IsSuccess then
      Exit;
  end;

  // Add a const modifier
  if DiaxSymbolGetConst(Symbol, IsConst).IsSuccess and IsConst then
    TypeName := 'CONST ' + TypeName;
end;

function DiaxSymbolFormatFunction;
var
  Format: TDiaxFunctionFormat;
  i: Integer;
begin
  // Collect and format return/argument types
  Result := DiaxSymbolFormatFunctionEx(Scope, Symbol, Format);

  if not Result.IsSuccess then
    Exit;

  if (Format.FunctionName = '') and (Format.ReturnTypeName = '') then
  begin
    // No information to format
    Result.Location := 'DiaxSymbolFormatFunction';
    Result.HResult := S_FALSE;
    Exit;
  end;

  if Format.ReturnTypeName <> '' then
  begin
    FormatString := Format.ReturnTypeName + ' ';

    if Format.CallingConvention <> '' then
      FormatString := FormatString + Format.CallingConvention + ' ';
  end
  else
    FormatString := '';

  if Format.FunctionName <> '' then
    FormatString := FormatString + Format.FunctionName;

  RtlxSuffixStripString(' ', FormatString, True);

  if Format.ReturnTypeName = '' then
  begin
    if dffoMultiLine in Options then
      FormatString := FormatString + ';';

    Exit;
  end;

  FormatString := FormatString + '(';

  for i := 0 to High(Format.Arguments) do
  begin
    if dffoMultiLine in Options then
      FormatString := FormatString + #$D#$A'    ';

    FormatString := FormatString + Format.Arguments[i].TypeName;

    if Format.Arguments[i].Name <> '' then
      FormatString := FormatString + ' ' + Format.Arguments[i].Name;

    if i < High(Format.Arguments) then
    begin
      if dffoMultiLine in Options then
        FormatString := FormatString + ','
      else
        FormatString := FormatString + ', ';
    end;
  end;

  if dffoMultiLine in Options then
      FormatString := FormatString + #$D#$A'    ';

  FormatString := FormatString + ')';

  if dffoMultiLine in Options then
    FormatString := FormatString + ';'
end;

function DiaxSymbolFormatFunctionEx;
var
  Tag: TSymTagEnum;
  FunctionType, ReturnType: IDiaSymbol;
  Args, ArgTypes, Datas, DataTypes: TArray<IDiaSymbol>;
  FormatOptions: TDiaxTypeFormatOptions;
  DataKind: TDataKind;
  ArgAndDataMatch: Boolean;
  i, j: Integer;
begin
  Format := Default(TDiaxFunctionFormat);
  Datas := nil;
  DataTypes := nil;

  // Check if we got a function or only its type
  Result := DiaxSymbolGetTag(Symbol, Tag);

  if not Result.IsSuccess then
    Exit;

  case Tag of
    SymTagFunction:
    begin
      // Lookup the function name
      Result := DiaxSymbolGetName(Symbol, Format.FunctionName);

      if not Result.IsSuccess then
        Exit;

      // Lookup the function type
      Result := DiaxSymbolGetTypeOrNil(Symbol, FunctionType);

      // No type - nothing to explore
      if not Result.IsSuccess or (Result.HResult = S_FALSE) then
        Exit;

      // Lookup function datas
      Result := DiaxSymbolEnumerateChildren(Datas, Symbol, SymTagData);

      if not Result.IsSuccess then
        Exit;

      SetLength(DataTypes, Length(Datas));
      for i := 0 to High(Datas) do
      begin
        // And the corresponding data types
        Result := DiaxSymbolGetType(Datas[i], DataTypes[i]);

        if not Result.IsSuccess then
          Exit;
      end;
    end;

    SymTagTypedef:
    begin
      // Lookup the function typedef name
      Result := DiaxSymbolGetName(Symbol, Format.FunctionName);

      if not Result.IsSuccess then
        Exit;

      // Lookup the underlying type
      Result := DiaxSymbolGetType(Symbol, FunctionType);

      if not Result.IsSuccess then
        Exit;

      // Check that the underying type is a function definition
      Result := DiaxSymbolGetTag(FunctionType, Tag);

      if not Result.IsSuccess then
        Exit;

      if Tag <> SymTagFunctionType then
      begin
        Result.Location := 'DiaxSymbolFormatFunctionEx';
        Result.LastCall.UsesInfoClass(Tag, icParse);
        Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
        Exit;
      end;
    end;

    SymTagFunctionType:
      FunctionType := Symbol;
  else
    Result.Location := 'DiaxSymbolFormatFunctionEx';
    Result.LastCall.UsesInfoClass(Tag, icParse);
    Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
    Exit;
  end;

  // Lookup the return type
  Result := DiaxSymbolGetTypeOrNil(FunctionType, ReturnType);

  if not Result.IsSuccess or (Result.HResult = S_FALSE) then
    Exit;

  // Format
  Result := DiaxSymbolFormatType(Scope, ReturnType, Format.ReturnTypeName);

  if not Result.IsSuccess then
    Exit;

  // Lookup the calling convention
  Result := DiaxSymbolFormatCallingConvention(Scope, FunctionType,
    Format.CallingConvention);

  if not Result.IsSuccess then
    Exit;

  // Lookup arguments
  Result := DiaxSymbolEnumerateChildren(Args, FunctionType,
    SymTagFunctionArgType);

  if not Result.IsSuccess then
    Exit;

  SetLength(Format.Arguments, Length(Args));
  SetLength(ArgTypes, Length(Args));

  for i := 0 to High(Args) do
  begin
    // Lookup argument types
    Result := DiaxSymbolGetType(Args[i], ArgTypes[i]);

    if not Result.IsSuccess then
      Exit;

    // Use the "..." type only for the last argument (unless it's the only one)
    if (i = High(Args)) and (Length(Args) > 1)  then
      FormatOptions := [dtfoAllowVarAgrs]
    else
      FormatOptions := [];

    // Format them
    Result := DiaxSymbolFormatType(Scope, ArgTypes[i],
      Format.Arguments[i].TypeName, FormatOptions);
  end;

  // Lookup arguments names
  if Length(Datas) > 0 then
  begin
    j := 0;
    for i := 0 to High(Args) do
    begin
      while j <= High(Datas) do
      begin
        // Lookup the kind of the data
        Result := DiaxSymbolGetDataKind(Datas[j], DataKind);

        if not Result.IsSuccess then
          Exit;

        // We are only interested in parameters
        if DataKind = TDataKind.DataIsParam then
        begin
          // Verify the data type matches the argument type
          if (dffoValidateArdDataMatch in Options) and
            (not DiaxSymbolsAreIdentical(ArgTypes[i], DataTypes[j],
            ArgAndDataMatch).IsSuccess or not ArgAndDataMatch) then
          begin
            Result.Location := 'DiaxSymbolFormatFunctionEx';
            Result.LastCall.UsesInfoClass(DataKind, icParse);
            Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
            Exit;
          end;

          // Lookup the argument name
          Result := DiaxSymbolGetName(Datas[j], Format.Arguments[i].Name);

          if not Result.IsSuccess then
            Exit;
          Inc(j);
          Break;
        end;

        // Try the next data
        Inc(j);
      end;
    end;
  end;
end;

end.
