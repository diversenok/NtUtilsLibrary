unit NtUtils.DbgHelp.Dia;

{
  This module provides wrappers for usig DIA (Debug Interface Access) API for
  parsing PDB files.
}

interface

uses
  Ntapi.DbgHelp, Ntapi.ImageHlp, Ntapi.msdia, NtUtils, DelphiUtils.AutoObjects;

var
  // The path to the DLL when the CLSID is not registered
  MsdiaDllPath: String = msdia140;

type
  TDiaxTypeFormatOptions = set of (
    dtfoAllowVarAgrs // Format zero-size NoType as "..." instead of "VOID"
  );

  TDiaxFunctionDumpOptions = set of (
    dfdoDumpParameters, // Parse parameter data symbols
    dfdoDumpArguments   // Parse argument type symbols
  );

  TDiaxParameterInfo = record
    DataSymbol: IDiaSymbol;
    DataTypeSymbol: IDiaSymbol;
    TypeName: String;
    Name: String;
  end;

  TDiaxArgumentInfo = record
    ArgumentTypeSymbol: IDiaSymbol;
    TypeName: String;
  end;

  TDiaxFunctionInfo = record
    FunctionTypeSymbol: IDiaSymbol;
    ReturnTypeSymbol: IDiaSymbol;
    ReturnTypeName: String;
    FunctionName: String;
    CallingConvention: String;
    Parameters: TArray<TDiaxParameterInfo>;
    Arguments: TArray<TDiaxArgumentInfo>;
  end;

  TDiaxFunctionFormatMode = (
    dffmAuto,           // Combined
    dffmArgumentsOnly,  // Only use argument type symbols (no names)
    dffmParamatersOnly  // Only use paramater data symbols
  );

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

// Locate a named debug stream in a PDB
function DiaxSessionFindDebugStream(
  const Session: IDiaSession;
  const Name: WideString;
  out DebugStream: IDiaEnumDebugStreamData
): TNtxStatus;

// Extract PE section headers from a PDB
function DiaxSessionDumpPeSections(
  const Session: IDiaSession;
  out Sections: TArray<IMemory<PImageSectionHeader>>
): TNtxStatus;

// Open the global scope of a session
function DiaxSessionGetGlobalScope(
  const Session: IDiaSession;
  out Scope: IDiaSymbol
): TNtxStatus;

// Format an identifier based on a GUID and age
function RtlxFormatGuidAge(
  Guid: TGuid;
  Age: Cardinal
): String;

// Format a PDB identifier based on its GUID and age
function DiaxScopeFormatGuidAge(
  const Scope: IDiaSymbol;
  out GuidAge: String
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

// Count the number of children of a symbol
function DiaxSymbolCountChildren(
  out Count: Integer;
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

// Determine the name of a symbol
function DiaxSymbolNameOrEmpty(
  const Symbol: IDiaSymbol
): String;

// Determine the undecorated name of a symbol (if available)
function DiaxSymbolGetUndecoratedName(
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
function DiaxSymbolFormatTypeName(
  const Scope: IDiaSymbol;
  const Symbol: IDiaSymbol;
  out TypeName: String;
  Options: TDiaxTypeFormatOptions = []
): TNtxStatus;

// Collect information about a function for formatting
function DiaxSymbolDumpFunction(
  out Info: TDiaxFunctionInfo;
  const Scope: IDiaSymbol;
  const Symbol: IDiaSymbol;
  Options: TDiaxFunctionDumpOptions = [dfdoDumpParameters, dfdoDumpArguments]
): TNtxStatus;

// Verify whether argument types and parameter datas (which are stored
// separately) agree on the function prototype.
function DiaxValidateParamsAndArgumentsMatch(
  const Info: TDiaxFunctionInfo
): TNtxStatus;

// Format a dumped function into a string
function DiaxSymbolFormatFunctionDump(
  const Info: TDiaxFunctionInfo;
  MultiLine: Boolean = False;
  Mode: TDiaxFunctionFormatMode = dffmAuto
): String;

// Format a function type into a string
function DiaxSymbolFormatFunction(
  const Scope: IDiaSymbol;
  const Symbol: IDiaSymbol;
  out Prototype: String;
  MultiLine: Boolean = False;
  Mode: TDiaxFunctionFormatMode = dffmAuto;
  ValidateParameterMatch: Boolean = False
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

function DiaxSessionFindDebugStream;
var
  DebugStreams: IDiaEnumDebugStreams;
  StreamName: WideString;
  Count, Fetched, i: Integer;
begin
  // Access the debug stream enumerator
  Result.Location := 'IDiaEnumDebugStreams::getEnumDebugStreams';
  Result.HResult := Session.getEnumDebugStreams(DebugStreams);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IDiaEnumDebugStreams::get_Count';
  Result.HResult := DebugStreams.get_Count(Count);

  if not Result.IsSuccess then
    Exit;

  // Search for the right debug stream
  for i := 0 to Pred(Count) do
  begin
    DebugStream := nil;
    Result.Location := 'IDiaEnumDebugStreams::Next';
    Result.HResult := DebugStreams.Next(1, DebugStream, Fetched);

    if not Result.IsSuccess then
      Exit;

    Result.Location := 'IDiaEnumDebugStreams::get_name';
    Result.HResult := DebugStream.get_name(StreamName);

    if not Result.IsSuccess then
      Exit;

    // Check the name
    if StreamName = Name then
      Exit(NtxSuccess);
  end;

  Result.Location := 'DiaxSessionFindDebugStream';
  Result.LastCall.Parameter := Name;
  Result.Status := STATUS_NOT_FOUND;
end;

function DiaxSessionDumpPeSections;
var
  DebugStream: IDiaEnumDebugStreamData;
  Count, i: Integer;
  Size, Fetched: Cardinal;
begin
  Result := DiaxSessionFindDebugStream(Session, 'SECTIONHEADERS', DebugStream);

  if not Result.IsSuccess then
    Exit;

  // Determine the number of sections
  Result.Location := 'IDiaEnumDebugStreamData::get_Count';
  Result.HResult := DebugStream.get_Count(Count);

  if not Result.IsSuccess then
    Exit;

  SetLength(Sections, Count);

  for i := 0 to High(Sections) do
  begin
    // Determine the data size
    Result.Location := 'IDiaEnumDebugStreamData::Next';
    Result.HResult := DebugStream.Next(1, 0, Size, nil, Fetched);

    if not Result.IsSuccess then
      Exit;

    // Read it
    IMemory(Sections[i]) := Auto.AllocateDynamic(Size);
    Result.Location := 'IDiaEnumDebugStreamData::Next';
    Result.HResult := DebugStream.Next(1, Sections[i].Size, Size,
      Sections[i].Data, Fetched);

    if not Result.IsSuccess then
      Exit;
  end;
end;

function DiaxSessionGetGlobalScope;
begin
  Result.Location := 'IDiaSession::get_globalScope';
  Result.HResult := Session.get_globalScope(Scope);
end;

function RtlxFormatGuidAge;
var
  GuidSize: Cardinal;
begin
  // Handle truncated {Value-0000-0000-0000-000000000000} GUIDs
  if (PCardinal(@Guid.D2)^ = 0) and (PUInt64(@Guid.D4[0])^ = 0) then
    GuidSize := SizeOf(Cardinal)
  else
    GuidSize := SizeOf(TGuid);

  Guid.D1 := RtlxSwapEndianness32(Guid.D1);
  Guid.D2 := RtlxSwapEndianness16(Guid.D2);
  Guid.D3 := RtlxSwapEndianness16(Guid.D3);

  // Format the identifier as the raw GUID bytes plus the age in hex
  Result := RtlxBytesToHexStr(@Guid, GuidSize) + RtlxIntToHex(Age, 0, False);
end;

function DiaxScopeFormatGuidAge;
var
  Guid: TGuid;
  Age: Cardinal;
begin
  Result.Location := 'IDiaSymbol::get_guid';
  Result.HResult := Scope.get_guid(Guid);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IDiaSymbol::get_age';
  Result.HResult := Scope.get_age(Age);

  if not Result.IsSuccess then
    Exit;

  GuidAge := RtlxFormatGuidAge(Guid, Age);
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

function DiaxSymbolCountChildren;
var
  Enum: IDiaEnumSymbols;
begin
  Result.Location := 'IDiaSymbol::findChildren';
  Result.HResult := Symbol.findChildren(SymTag, Name, CompareFlags, Enum);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IDiaEnumSymbols::get_Count';
  Result.HResult := Enum.get_Count(Count);
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

function DiaxSymbolNameOrEmpty;
begin
  if not DiaxSymbolGetName(Symbol, Result).IsSuccess then
    Result := '';
end;

function DiaxSymbolGetUndecoratedName;
var
  WideName: WideString;
begin
  Result.Location := 'IDiaSymbol::get_undecoratedName';
  Result.HResult := Symbol.get_undecoratedName(WideName);

  if not Result.IsSuccess then
    Exit;

  if WideName = '' then
    Result.HResult := S_FALSE;

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
  else
    Result.Location := 'DiaxSymbolsAreIdentical';
    Result.LastCall.UsesInfoClass(TagA, icCompare);
    Result.Status := STATUS_UNKNOWN_REVISION;
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
        DiaxSymbolGetName(Symbol, Result.LastCall.Parameter);
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

    // Callee cleanup, LTR
    CV_CALL_NEAR_PASCAL, CV_CALL_FAR_PASCAL:
      ConventionName := '__pascal';

    // N/A cleanup, LTR
    CV_CALL_CLRCALL:
      ConventionName := '__clrcall';

    // Callee cleanup, RTL
    CV_CALL_NEAR_VECTOR:
      ConventionName := '__vectorcall';
  else
    Result.Location := 'DiaxSymbolFormatCallingConvention';
    DiaxSymbolGetName(Symbol, Result.LastCall.Parameter);
    Result.LastCall.UsesInfoClass(Convention, icFormat);
    Result.Status := STATUS_UNKNOWN_REVISION;
  end;
end;

function DiaxSymbolFormatTypeName;
var
  Tag: TSymTagEnum;
  BasicType: TBasicType;
  UdtKind: TUdtKind;
  Size: UInt64;
  Count: Cardinal;
  IsConst: LongBool;
  KindName: String;
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
      // Lookup name
      Result := DiaxSymbolGetName(Symbol, TypeName);

      if not Result.IsSuccess then
        Exit;

      if TypeName = '' then
        TypeName := '<unnamed type>';

      if Tag = SymTagUDT then
      begin
        // Lookup the type kind
        Result := DiaxSymbolGetUdtKind(Symbol, UdtKind);

        if not Result.IsSuccess then
          Exit;

        case UdtKind of
          UdtStruct:    KindName := 'struct ';
          UdtClass:     KindName := 'class ';
          UdtUnion:     KindName := 'union ';
          UdtInterface: KindName := 'interface ';
        else
          Result.Location := 'DiaxSymbolFormatTypeName';
          Result.LastCall.Parameter := TypeName;
          Result.LastCall.UsesInfoClass(UdtKind, icFormat);
          Result.Status := STATUS_UNKNOWN_REVISION;
        end;
      end
      else if Tag = SymTagEnum then
        KindName := 'enum ';

      TypeName := KindName + TypeName;
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
        Result.Location := 'DiaxSymbolFormatTypeName';
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

      Result := DiaxSymbolFormatTypeName(Scope, NestedType, TypeName);

      if not Result.IsSuccess then
        Exit;

      Result := DiaxSymbolGetCount(Symbol, Count);

      if not Result.IsSuccess then
        Exit;

      TypeName := RtlxFormatString('%s[%u]', [TypeName, Count]);
    end;

    // Pointers and typedefs require dereferencing
    SymTagPointerType, SymTagTypedef:
    begin
      Result := DiaxSymbolGetType(Symbol, NestedType);

      if not Result.IsSuccess then
        Exit;

      // Call recursively
      Result := DiaxSymbolFormatTypeName(Scope, NestedType, TypeName);

      if not Result.IsSuccess then
        Exit;

      if Tag = SymTagPointerType then
        TypeName := TypeName + '*';
    end;

    // Function types require collecting arguments
    SymTagFunctionType:
    begin
      Result := DiaxSymbolFormatFunction(Scope, Symbol, TypeName, False,
        dffmAuto);

      if not Result.IsSuccess then
        Exit;

      TypeName := '(' + TypeName + ')';
    end

  else
    // Might need more work
    Result.Location := 'DiaxSymbolGetName';
    DiaxSymbolGetName(Symbol, Result.LastCall.Parameter);
    Result.LastCall.UsesInfoClass(Tag, icParse);
    Result.Status := STATUS_NOT_IMPLEMENTED;

    if not Result.IsSuccess then
      Exit;
  end;

  // Add a const modifier
  if DiaxSymbolGetConst(Symbol, IsConst).IsSuccess and IsConst then
    TypeName := 'CONST ' + TypeName;
end;

function DiaxSymbolDumpFunction;
var
  ReferencedType: IDiaSymbol;
  Datas, Args: TArray<IDiaSymbol>;
  Tag: TSymTagEnum;
  DataKind: TDataKind;
  BasicType: TBasicType;
  FormatOptions: TDiaxTypeFormatOptions;
  i, j: Integer;
  ArgAndDataMatch: Boolean;
begin
  Info := Default(TDiaxFunctionInfo);

  // Check what kind of symbol we got
  Result := DiaxSymbolGetTag(Symbol, Tag);

  if not Result.IsSuccess then
    Exit;

  if not (Tag in [SymTagFunction, SymTagFunctionType, SymTagData,
    SymTagPointerType, SymTagTypedef]) then
  begin
    Result.Location := 'DiaxSymbolFormatFunctionEx';
    Result.LastCall.UsesInfoClass(Tag, icParse);
    Result.Status := STATUS_UNKNOWN_REVISION;
    Exit;
  end;

  // Extract the name
  if Tag in [SymTagFunction, SymTagData, SymTagTypedef] then
  begin
    Result := DiaxSymbolGetName(Symbol, Info.FunctionName);

    if not Result.IsSuccess then
      Exit;
  end;

  // Collect function parameter datas
  if (Tag = SymTagFunction) and (dfdoDumpParameters in Options) then
  begin
    Result := DiaxSymbolEnumerateChildren(Datas, Symbol, SymTagData);

    if not Result.IsSuccess then
      Exit;

    SetLength(Info.Parameters, Length(Datas));
    j := 0;
    for i := 0 to High(Datas) do
    begin
      // Check whether the data is a parameter
      Result := DiaxSymbolGetDataKind(Datas[i], DataKind);

      if not Result.IsSuccess then
        Exit;

      if DataKind <> DataIsParam then
        Continue;

      // Save its name
      Result := DiaxSymbolGetName(Datas[i], Info.Parameters[j].Name);

      if not Result.IsSuccess then
        Exit;

      // Save the symbol and its type
      Info.Parameters[j].DataSymbol := Datas[i];
      Result := DiaxSymbolGetType(Datas[i], Info.Parameters[j].DataTypeSymbol);

      if not Result.IsSuccess then
        Exit;

      // Format the type name
      Result := DiaxSymbolFormatTypeName(Scope,
        Info.Parameters[j].DataTypeSymbol,
        Info.Parameters[j].TypeName);

      if not Result.IsSuccess then
        Exit;

      Inc(j);
    end;

    SetLength(Info.Parameters, j);
  end;

  Info.FunctionTypeSymbol := Symbol;

  // Extract the referenced function type
  while Tag in [SymTagFunction, SymTagData, SymTagPointerType, SymTagTypedef] do
  begin
    Result := DiaxSymbolGetType(Info.FunctionTypeSymbol, ReferencedType);

    if not Result.IsSuccess then
      Exit;

    Result := DiaxSymbolGetTag(ReferencedType, Tag);

    if not Result.IsSuccess then
      Exit;

    Info.FunctionTypeSymbol := ReferencedType;
  end;

  // If the function has no type, there is nothing else to process
  if (Tag = SymTagBaseType) and DiaxSymbolGetBasicType(
    Info.FunctionTypeSymbol, BasicType).IsSuccess and
    (BasicType = btNoType) then
    Exit;

  if Tag <> SymTagFunctionType then
  begin
    Result.Location := 'DiaxSymbolFormatFunctionEx';
    Result.LastCall.UsesInfoClass(Tag, icParse);
    Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
    Exit;
  end;

  // Extract the return type
  Result := DiaxSymbolGetType(Info.FunctionTypeSymbol,
    Info.ReturnTypeSymbol);

  if not Result.IsSuccess then
    Exit;

  // Format it
  Result := DiaxSymbolFormatTypeName(Scope, Info.ReturnTypeSymbol,
    Info.ReturnTypeName);

  if not Result.IsSuccess then
    Exit;

  // Lookup the calling convention
  Result := DiaxSymbolFormatCallingConvention(Scope, Info.FunctionTypeSymbol,
    Info.CallingConvention);

  if not Result.IsSuccess then
    Exit;

  if dfdoDumpArguments in Options then
  begin
    // Extract arguments
    Result := DiaxSymbolEnumerateChildren(Args, Info.FunctionTypeSymbol,
      SymTagFunctionArgType);

    if not Result.IsSuccess then
      Exit;

    SetLength(Info.Arguments, Length(Args));

    for i := 0 to High(Args) do
    begin
      // Lookup the argument type
      Result := DiaxSymbolGetType(Args[i], Info.Arguments[i].ArgumentTypeSymbol);

      if not Result.IsSuccess then
        Exit;

      // Use the "..." type only for the last argument (unless it's the only one)
      if (i = High(Args)) and (Length(Args) > 1)  then
        FormatOptions := [dtfoAllowVarAgrs]
      else
        FormatOptions := [];

      // Format its type
      Result := DiaxSymbolFormatTypeName(Scope,
        Info.Arguments[i].ArgumentTypeSymbol,
        Info.Arguments[i].TypeName, FormatOptions);

      if not Result.IsSuccess then
        Exit;
    end;
  end;
end;

function DiaxValidateParamsAndArgumentsMatch;
var
  i: Integer;
  Identical: Boolean;
begin
  Identical := Length(Info.Parameters) <= Length(Info.Arguments);

  if Identical then
    for i := 0 to High(Info.Arguments) do
      if i <= High(Info.Parameters) then
      begin
        Result := DiaxSymbolsAreIdentical(Info.Parameters[i].DataTypeSymbol,
          Info.Arguments[i].ArgumentTypeSymbol, Identical);

        if not Result.IsSuccess then
          Exit;

        if not Identical then
          Break;
      end
      else
        Break;

  if Identical then
    Result := NtxSuccess
  else
  begin
    Result.Location := 'DiaxValidateParamsAndArgumentsMatch';
    Result.Status := STATUS_REVISION_MISMATCH;
    Exit;
  end
end;

function DiaxSymbolFormatFunctionDump;
var
  i: Integer;
begin
  Result := '';

  if (Info.FunctionName = '') and (Info.ReturnTypeName = '') then
    Exit;

  if Info.ReturnTypeName <> '' then
  begin
    Result := Info.ReturnTypeName + ' ';

    if Info.CallingConvention <> '' then
      Result := Result + Info.CallingConvention + ' ';
  end
  else
    Result := '';

  if Info.FunctionName <> '' then
    Result := Result + Info.FunctionName;

  RtlxSuffixStripString(' ', Result, True);

  if Info.ReturnTypeName = '' then
  begin
    if MultiLine then
      Result := Result + ';';

    Exit;
  end;

  Result := Result + '(';

  if MultiLine then
    Result := Result + #$D#$A'    ';

  case Mode of
    dffmAuto, dffmArgumentsOnly:
    for i := 0 to High(Info.Arguments) do
    begin
      Result := Result + Info.Arguments[i].TypeName;

      if (Mode = dffmAuto) and (i <= High(Info.Parameters)) then
        Result := Result + ' ' + Info.Parameters[i].Name;

      if i < High(Info.Arguments) then
      begin
        if MultiLine then
          Result := Result + ','
        else
          Result := Result + ', ';
      end;

      if MultiLine then
        Result := Result + #$D#$A'    ';
    end;

    dffmParamatersOnly:
    for i := 0 to High(Info.Parameters) do
    begin
      Result := Result + Info.Parameters[i].TypeName + ' ' +
        Info.Parameters[i].Name;

      if i < High(Info.Parameters) then
      begin
        if MultiLine then
          Result := Result + ','
        else
          Result := Result + ', ';
      end;

      if MultiLine then
        Result := Result + #$D#$A'    ';
    end;
  end;

  Result := Result + ')';

  if MultiLine then
    Result := Result + ';'
end;

function DiaxSymbolFormatFunction;
const
  OPTIONS: array [TDiaxFunctionFormatMode] of TDiaxFunctionDumpOptions = (
    [dfdoDumpParameters, dfdoDumpArguments], [dfdoDumpArguments],
    [dfdoDumpParameters]);
var
  Info: TDiaxFunctionInfo;
  Match: Boolean;
begin
  Result := DiaxSymbolDumpFunction(Info, Scope, Symbol, OPTIONS[Mode]);

  if not Result.IsSuccess then
    Exit;

  if ValidateParameterMatch and (Mode = dffmAuto) then
  begin
    Result := DiaxValidateParamsAndArgumentsMatch(Info);

    if not Result.IsSuccess then
      Exit;
  end;

  DiaxSymbolFormatFunctionDump(Info, MultiLine, Mode)
end;

end.
