unit Ntapi.msdia;

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ImageHlp, Ntapi.DbgHelp, Ntapi.ObjIdl,
  DelphiApi.Reflection;

const
  // DIA::dia2.h
  CLSID_DiaSource: TGuid = '{e6756135-1e65-4d17-8576-610761398c3c}';

  // DIA::dia2.h - name search options
  nsfCaseSensitive = $01;
  nsfCaseInsensitive = $02;
  nsfFNameExt = $04;
  nsfRegularExpression = $08;
  nsfUndecoratedName = $10;

type
  // DIA::cvconst.h
  [SDKName('LocationType')]
  TLocationType = (
    LocIsNull = 0,
    LocIsStatic = 1,
    LocIsTLS = 2,
    LocIsRegRel = 3,
    LocIsThisRel = 4,
    LocIsEnregistered = 5,
    LocIsBitField = 6,
    LocIsSlot = 7,
    LocIsIlRel = 8,
    LocInMetaData = 9,
    LocIsConstant = 10,
    LocIsRegRelAliasIndir = 11
  );

  // DIA::cvconst.h
  [SDKName('DataKind')]
  [NamingStyle(nsCamelCase, 'DataIs')]
  TDataKind = (
    DataIsUnknown = 0,
    DataIsLocal = 1,
    DataIsStaticLocal = 2,
    DataIsParam = 3,
    DataIsObjectPtr = 4,
    DataIsFileStatic = 5,
    DataIsGlobal = 6,
    DataIsMember = 7,
    DataIsStaticMember = 8,
    DataIsConstant = 9
  );

  [SDKName('UdtKind')]
  TUdtKind = (
    UdtStruct = 0,
    UdtClass = 1,
    UdtUnion = 2,
    UdtInterface = 3,
    UdtTaggedUnion = 4
  );

  // DIA::cvconst.h
  [SDKName('BasicType')]
  TBasicType = (
    btNoType = 0,
    btVoid = 1,
    btChar = 2,
    btWChar = 3,
    btInt = 6,
    btUInt = 7,
    btFloat = 8,
    btBCD = 9,
    btBool = 10,
    btLong = 13,
    btULong = 14,
    btCurrency = 25,
    btDate = 26,
    btVariant = 27,
    btComplex = 28,
    btBit = 29,
    btBSTR = 30,
    btHresult = 31,
    btChar16 = 32,
    btChar32 = 33,
    btChar8  = 34
  );

  // DIA::dia2.h
  [SDKName('NameSearchOptions')]
  [FlagName(nsfCaseSensitive, 'Case-sensitive')]
  [FlagName(nsfCaseInsensitive, 'Case-insensitive')]
  [FlagName(nsfFNameExt, 'filename.ext Search')]
  [FlagName(nsfRegularExpression, 'Regular Expression')]
  [FlagName(nsfUndecoratedName, 'Undecorated Name')]
  TNameSearchOptions = type Cardinal;

  IDiaLineNumber = IUnknown;
  IDiaSourceFile = IUnknown;
  IDiaInputAssemblyFile = IUnknown;
  IDiaEnumTables = IUnknown;
  IDiaEnumSourceFiles = IUnknown;
  IDiaEnumLineNumbers = IUnknown;
  IDiaEnumInjectedSources = IUnknown;
  IDiaEnumDebugStreams = IUnknown;
  IDiaEnumInputAssemblyFiles = IUnknown;

  IDiaEnumSymbols = interface;
  IDiaEnumSymbolsByAddr = interface;

  // DIA::dia2.h
  IDiaSymbol = interface (IUnknown)
    ['{cb787b2f-bd6c-4635-ba52-933126bd2dcd}']

    function get_symIndexId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_symTag(
      [out] out RetVal: TSymTagEnum
    ): HResult; stdcall;

    function get_name(
      [out] out RetVal: WideString
    ): HResult; stdcall;

    function get_lexicalParent(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function get_classParent(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function get_type(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function get_dataKind(
      [out] out RetVal: TDataKind
    ): HResult; stdcall;

    function get_locationType(
      [out] out RetVal: TLocationType
    ): HResult; stdcall;

    function get_addressSection(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_addressOffset(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_relativeVirtualAddress(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_virtualAddress(
      [out] out RetVal: UInt64
    ): HResult; stdcall;

    function get_registerId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_offset(
      [out] out RetVal: Integer
    ): HResult; stdcall;

    function get_length(
      [out] out RetVal: UInt64
    ): HResult; stdcall;

    function get_slot(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_volatileType(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_constType(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_unalignedType(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_access(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_libraryName(
      [out] out RetVal: WideString
    ): HResult; stdcall;

    function get_platform(
      [out] out RetVal: Cardinal // CV_CPU_TYPE_e
    ): HResult; stdcall;

    function get_language(
      [out] out RetVal: Cardinal // CV_CFL_LANG
    ): HResult; stdcall;

    function get_editAndContinueEnabled(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_frontEndMajor(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_frontEndMinor(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_frontEndBuild(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_backEndMajor(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_backEndMinor(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_backEndBuild(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_sourceFileName(
      [out] out RetVal: WideString
    ): HResult; stdcall;

    function get_unused(
      [out] out RetVal: WideString
    ): HResult; stdcall;

    function get_thunkOrdinal(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_thisAdjust(
      [out] out RetVal: Integer
    ): HResult; stdcall;

    function get_virtualBaseOffset(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_virtual(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_intro(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_pure(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_callingConvention(
      [out] out RetVal: Cardinal // CV_call_e
    ): HResult; stdcall;

    function get_value(
      [out] out RetVal: TVarData
    ): HResult; stdcall;

    function get_baseType(
      [out] out RetVal: TBasicType
    ): HResult; stdcall;

    function get_token(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_timeStamp(
      [out] out RetVal: TUnixTime
    ): HResult; stdcall;

    function get_guid(
      [out] out RetVal: TGuid
    ): HResult; stdcall;

    function get_symbolsFileName(
      [out] out RetVal: WideString
    ): HResult; stdcall;

    function get_reference(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_count(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_bitPosition(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_arrayIndexType(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function get_packed(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_constructor(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_overloadedOperator(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_nested(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_hasNestedTypes(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_hasAssignmentOperator(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_hasCastOperator(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_scoped(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_virtualBaseClass(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_indirectVirtualBaseClass(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_virtualBasePointerOffset(
      [out] out RetVal: Integer
    ): HResult; stdcall;

    function get_virtualTableShape(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function get_lexicalParentId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_classParentId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_typeId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_arrayIndexTypeId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_virtualTableShapeId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_code(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_function(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_managed(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_msil(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_virtualBaseDispIndex(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_undecoratedName(
      [out] out RetVal: WideString
    ): HResult; stdcall;

    function get_age(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_signature(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_compilerGenerated(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_addressTaken(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_rank(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_lowerBound(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function get_upperBound(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function get_lowerBoundId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_upperBoundId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_dataBytes(
      [in, NumberOfBytes] cbData: Cardinal;
      [out, NumberOfBytes] out pcbData: Cardinal;
      [out, WritesTo] pbData: Pointer
    ): HResult; stdcall;

    function findChildren(
      [in] symtag: TSymTagEnum;
      [in, opt] name: WideString;
      [in] compareFlags: Cardinal;
      [out] out ppResult: IDiaEnumSymbols
    ): HResult; stdcall;

    function findChildrenEx(
      [in] symtag: TSymTagEnum;
      [in, opt] name: WideString;
      [in] compareFlags: Cardinal;
      [out] out ppResult: IDiaEnumSymbols
    ): HResult; stdcall;

    function findChildrenExByAddr(
      [in] symtag: TSymTagEnum;
      [in, opt] name: WideString;
      [in] compareFlags: Cardinal;
      [in] isect: Cardinal;
      [in] offset: Cardinal;
      [out] out ppResult: IDiaEnumSymbols
    ): HResult; stdcall;

    function findChildrenExByVA(
      [in] symtag: TSymTagEnum;
      [in, opt] name: WideString;
      [in] compareFlags: Cardinal;
      [in] va: UInt64;
      [out] out ppResult: IDiaEnumSymbols
    ): HResult; stdcall;

    function findChildrenExByRVA(
      [in] symtag: TSymTagEnum;
      [in, opt] name: WideString;
      [in] compareFlags: Cardinal;
      [in] rva: Cardinal;
      [out] out ppResult: IDiaEnumSymbols
    ): HResult; stdcall;

    function get_targetSection(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_targetOffset(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_targetRelativeVirtualAddress(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_targetVirtualAddress(
      [out] out RetVal: UInt64
    ): HResult; stdcall;

    function get_machineType(
      [out] out RetVal: TImageMachine32
    ): HResult; stdcall;

    function get_oemId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_oemSymbolId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_types(
      [in, NumberOfElements] cTypes: Cardinal;
      [out, NumberOfElements] out pcTypes: Cardinal;
      [out, WritesTo] pTypes: &IDiaSymbol
    ): HResult; stdcall;

    function get_typeIds(
      [in, NumberOfElements] cTypeIds: Cardinal;
      [out, NumberOfElements] out pcTypeIds: Cardinal;
      [out, WritesTo] pdwTypeIds: PCardinal
    ): HResult; stdcall;

    function get_objectPointerType(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function get_udtKind(
      [out] out RetVal: TUdtKind
    ): HResult; stdcall;

    function get_undecoratedNameEx(
      [in] undecorateOptions: TUndecorateFlags;
      [out] out name: WideString
    ): HResult; stdcall;

    function get_noReturn(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_customCallingConvention(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_noInline(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_optimizedCodeDebugInfo(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_notReached(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_interruptReturn(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_farReturn(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isStatic(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_hasDebugInfo(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isLTCG(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isDataAligned(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_hasSecurityChecks(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_compilerName(
      [out] out RetVal: WideString
    ): HResult; stdcall;

    function get_hasAlloca(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_hasSetJump(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_hasLongJump(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_hasInlAsm(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_hasEH(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_hasSEH(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_hasEHa(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isNaked(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isAggregated(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isSplitted(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_container(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function get_inlSpec(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_noStackOrdering(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_virtualBaseTableType(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function get_hasManagedCode(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isHotpatchable(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isCVTCIL(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isMSILNetmodule(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isCTypes(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isStripped(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_frontEndQFE(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_backEndQFE(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_wasInlined(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_strictGSCheck(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isCxxReturnUdt(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isConstructorVirtualBase(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_RValueReference(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_unmodifiedType(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function get_framePointerPresent(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isSafeBuffers(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_intrinsic(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_sealed(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_hfaFloat(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_hfaDouble(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_liveRangeStartAddressSection(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_liveRangeStartAddressOffset(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_liveRangeStartRelativeVirtualAddress(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_countLiveRanges(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_liveRangeLength(
      [out] out RetVal: UInt64
    ): HResult; stdcall;

    function get_offsetInUdt(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_paramBasePointerRegisterId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_localBasePointerRegisterId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_isLocationControlFlowDependent(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_stride(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_numberOfRows(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_numberOfColumns(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_isMatrixRowMajor(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_numericProperties(
      [in, NumberOfElements] cnt: Cardinal;
      [out, NumberOfElements] out pcnt: Cardinal;
      [out, WritesTo] pProperties: PCardinal
    ): HResult; stdcall;

    function get_modifierValues(
      [in, NumberOfElements] cnt: Cardinal;
      [out, NumberOfElements] out pcnt: Cardinal;
      [out, WritesTo] pModifiers: PWord
    ): HResult; stdcall;

    function get_isReturnValue(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isOptimizedAway(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_builtInKind(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_registerType(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_baseDataSlot(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_baseDataOffset(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_textureSlot(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_samplerSlot(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_uavSlot(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_sizeInUdt(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_memorySpaceKind(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_unmodifiedTypeId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_subTypeId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_subType(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function get_numberOfModifiers(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_numberOfRegisterIndices(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_isHLSLData(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isPointerToDataMember(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isPointerToMemberFunction(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isSingleInheritance(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isMultipleInheritance(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isVirtualInheritance(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_restrictedType(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isPointerBasedOnSymbolValue(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_baseSymbol(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function get_baseSymbolId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_objectFileName(
      [out] out RetVal: WideString
    ): HResult; stdcall;

    function get_isAcceleratorGroupSharedLocal(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isAcceleratorPointerTagLiveRange(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isAcceleratorStubFunction(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_numberOfAcceleratorPointerTags(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_isSdl(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isWinRTPointer(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isRefUdt(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isValueUdt(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isInterfaceUdt(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function findInlineFramesByAddr(
      [in] isect: Cardinal;
      [in] offset: Cardinal;
      [out] out ppResult: IDiaEnumSymbols
    ): HResult; stdcall;

    function findInlineFramesByRVA(
      [in] rva: Cardinal;
      [out] out ppResult: IDiaEnumSymbols
    ): HResult; stdcall;

    function findInlineFramesByVA(
      [in] va: UInt64;
      [out] out ppResult: IDiaEnumSymbols
    ): HResult; stdcall;

    function findInlineeLines(
      [out] out ppResult: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findInlineeLinesByAddr(
      [in] isect: Cardinal;
      [in] offset: Cardinal;
      [in] length: Cardinal;
      [out] out ppResult: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findInlineeLinesByRVA(
      [in] rva: Cardinal;
      [in] length: Cardinal;
      [out] out ppResult: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findInlineeLinesByVA(
      [in] va: UInt64;
      [in] length: Cardinal;
      [out] out ppResult: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findSymbolsForAcceleratorPointerTag(
      [in] tagValue: Cardinal;
      [out] out ppResult: IDiaEnumSymbols
    ): HResult; stdcall;

    function findSymbolsByRVAForAcceleratorPointerTag(
      [in] tagValue: Cardinal;
      [in] rva: Cardinal;
      [out] out ppResult: IDiaEnumSymbols
    ): HResult; stdcall;

    function get_acceleratorPointerTags(
      [in, NumberOfElements] cnt: Cardinal;
      [out, NumberOfElements] out pcnt: Cardinal;
      [out] pPointerTags: PCardinal
    ): HResult; stdcall;

    function getSrcLineOnTypeDefn(
      [out] out ppResult: IDiaLineNumber
    ): HResult; stdcall;

    function get_isPGO(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_hasValidPGOCounts(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isOptimizedForSpeed(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_PGOEntryCount(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_PGOEdgeCount(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_PGODynamicInstructionCount(
      [out] out RetVal: UInt64
    ): HResult; stdcall;

    function get_staticSize(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_finalLiveStaticSize(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_phaseName(
      [out] out RetVal: WideString
    ): HResult; stdcall;

    function get_hasControlFlowCheck(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_constantExport(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_dataExport(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_privateExport(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_noNameExport(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_exportHasExplicitlyAssignedOrdinal(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_exportIsForwarder(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_ordinal(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_frameSize(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_exceptionHandlerAddressSection(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_exceptionHandlerAddressOffset(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_exceptionHandlerRelativeVirtualAddress(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_exceptionHandlerVirtualAddress(
      [out] out RetVal: UInt64
    ): HResult; stdcall;

    function findInputAssemblyFile(
      [out] out ppResult: IDiaInputAssemblyFile
    ): HResult; stdcall;

    function get_characteristics(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_coffGroup(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function get_bindID(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_bindSpace(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_bindSlot(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;
  end;

  // DIA::dia2.h
  IDiaSession = interface (IUnknown)
    ['{2F609EE1-D1C8-4E24-8288-3326BADCD211}']
    function get_loadAddress(
      [out] out RetVal: UInt64
    ): HResult; stdcall;

    function put_loadAddress(
      [in] NewVal: UInt64
    ): HResult; stdcall;

    function get_globalScope(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function getEnumTables(
      [out] out EnumTables: IDiaEnumTables
    ): HResult; stdcall;

    function getSymbolsByAddr(
      [out] out EnumbyAddr: IDiaEnumSymbolsByAddr
    ): HResult; stdcall;

    function findChildren(
      [in, opt] const parent: IDiaSymbol;
      [in] symtag: TSymTagEnum;
      [in, opt] name: WideString;
      [in] compareFlags: TNameSearchOptions;
      [out] out Result: IDiaEnumSymbols
    ): HResult; stdcall;

    function findChildrenEx(
      [in, opt] const parent: IDiaSymbol;
      [in] symtag: TSymTagEnum;
      [in, opt] name: WideString;
      [in] compareFlags: TNameSearchOptions;
      [out] out Result: IDiaEnumSymbols
    ): HResult; stdcall;

    function findChildrenExByAddr(
      [in, opt] const parent: IDiaSymbol;
      [in] symtag: TSymTagEnum;
      [in, opt] name: WideChar;
      [in] compareFlags: TNameSearchOptions;
      [in] isect: Cardinal;
      [in] offset: Cardinal;
      [out] out Result: IDiaEnumSymbols
    ): HResult; stdcall;

    function findChildrenExByVA(
      [in, opt] const parent: IDiaSymbol;
      [in] symtag: TSymTagEnum;
      [in, opt] name: WideChar;
      [in] compareFlags: TNameSearchOptions;
      [in] va: UInt64;
      [out] out Result: IDiaEnumSymbols
    ): HResult; stdcall;

    function findChildrenExByRVA(
      [in, opt] const parent: IDiaSymbol;
      [in] symtag: TSymTagEnum;
      [in, opt] name: WideChar;
      [in] compareFlags: TNameSearchOptions;
      [in] rva: Cardinal;
      [out] out Result: IDiaEnumSymbols
    ): HResult; stdcall;

    function findSymbolByAddr(
      [in] isect: Cardinal;
      [in] offset: Cardinal;
      [in] symtag: TSymTagEnum;
      [out] out Symbol: IDiaSymbol
    ): HResult; stdcall;

    function findSymbolByRVA(
      [in] rva: Cardinal;
      [in] symtag: TSymTagEnum;
      [out] out Symbol: IDiaSymbol
    ): HResult; stdcall;

    function findSymbolByVA(
      [in] va: UInt64;
      [in] symtag: TSymTagEnum;
      [out] out Symbol: IDiaSymbol
    ): HResult; stdcall;

    function findSymbolByToken(
      [in] token: Cardinal;
      [in] symtag: TSymTagEnum;
      [out] out Symbol: IDiaSymbol
    ): HResult; stdcall;

    function symsAreEquiv(
      [in] const symbolA: IDiaSymbol;
      [in] const symbolB: IDiaSymbol
    ): HResult; stdcall;

    function symbolById(
      [in] id: Cardinal;
      [out] out Symbol: IDiaSymbol
    ): HResult; stdcall;

    function findSymbolByRVAEx(
      [in] rva: Cardinal;
      [in] symtag: TSymTagEnum;
      [out] out Symbol: IDiaSymbol;
      [out] out displacement: Integer
    ): HResult; stdcall;

    function findSymbolByVAEx(
      [in] va: UInt64;
      [in] symtag: TSymTagEnum;
      [out] out Symbol: IDiaSymbol;
      [out] out displacement: Integer
    ): HResult; stdcall;

    function findFile(
      [in] const Compiland: IDiaSymbol;
      [in] name: WideString;
      [in] compareFlags: TNameSearchOptions;
      [out] out Resul: IDiaEnumSourceFiles
    ): HResult; stdcall;

    function findFileById(
      [in] uniqueId: Cardinal;
      [out] out Result: IDiaSourceFile
    ): HResult; stdcall;

    function findLines(
      [in] const Compiland: IDiaSymbol;
      [in] const _file: IDiaSourceFile;
      [out] out Result: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findLinesByAddr(
      [in] seg: Cardinal;
      [in] offset: Cardinal;
      [in] length: Cardinal;
      [out] out Result: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findLinesByRVA(
      [in] rva: Cardinal;
      [in] length: Cardinal;
      [out] out Result: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findLinesByVA(
      [in] va: UInt64;
      [in] length: Cardinal;
      [out] out Result: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findLinesByLinenum(
      [in] const Compiland: IDiaSymbol;
      [in] const _file: IDiaSourceFile;
      [in] linenum: Cardinal;
      [in] column: Cardinal;
      [out] out Result: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findInjectedSource(
      [in] srcFile: WideString;
      [out] out Result: IDiaEnumInjectedSources
    ): HResult; stdcall;

    function getEnumDebugStreams(
      [out] out EnumDebugStreams: IDiaEnumDebugStreams
    ): HResult; stdcall;

    function findInlineFramesByAddr(
      [in] parent: IDiaSymbol;
      [in] isect: Cardinal;
      [in] offset: Cardinal;
      [out] out Result: IDiaEnumSymbols
    ): HResult; stdcall;

    function findInlineFramesByRVA(
      [in] parent: IDiaSymbol;
      [in] rva: Cardinal;
      [out] out Result: IDiaEnumSymbols
    ): HResult; stdcall;

    function findInlineFramesByVA(
      [in] parent: IDiaSymbol;
      [in] va: UInt64;
      [out] out Result: IDiaEnumSymbols
    ): HResult; stdcall;

    function findInlineeLines(
      [in] parent: IDiaSymbol;
      [out] out Result: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findInlineeLinesByAddr(
      [in] parent: IDiaSymbol;
      [in] isect: Cardinal;
      [in] offset: Cardinal;
      [in] length: Cardinal;
      [out] out Result: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findInlineeLinesByRVA(
      [in] parent: IDiaSymbol;
      [in] rva: Cardinal;
      [in] length: Cardinal;
      [out] out Result: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findInlineeLinesByVA(
      [in] parent: IDiaSymbol;
      [in] va: UInt64;
      [in] length: Cardinal;
      [out] out Result: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findInlineeLinesByLinenum(
      [in] const Compiland: IDiaSymbol;
      [in] const _file: IDiaSourceFile;
      [in] linenum: Cardinal;
      [in] column: Cardinal;
      [out] out Result: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findInlineesByName(
      [in] name: WideString;
      [in] option: Cardinal;
      [out] out Result: IDiaEnumSymbols
    ): HResult; stdcall;

    function findAcceleratorInlineeLinesByLinenum(
      [in] const parent: IDiaSymbol;
      [in] const _file: IDiaSourceFile;
      [in] linenum: Cardinal;
      [in] column: Cardinal;
      [out] out Result: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findSymbolsForAcceleratorPointerTag(
      [in] const parent: IDiaSymbol;
      [in] tagValue: Cardinal;
      [out] out Result: IDiaEnumSymbols
    ): HResult; stdcall;

    function findSymbolsByRVAForAcceleratorPointerTag(
      [in] const parent: IDiaSymbol;
      [in] tagValue: Cardinal;
      [in] rva: Cardinal;
      [out] out Result: IDiaEnumSymbols
    ): HResult; stdcall;

    function findAcceleratorInlineesByName(
      [in] name: WideString;
      [in] option: Cardinal;
      [out] out Result: IDiaEnumSymbols
    ): HResult; stdcall;

    function addressForVA(
      [in] va: UInt64;
      [out] out ISect:Cardinal;
      [out] out Offset: Cardinal
    ): HResult; stdcall;

    function addressForRVA(
      [in] rva: Cardinal;
      [out] out ISect: Cardinal;
      [out] out Offset: Cardinal
    ): HResult; stdcall;

    function findILOffsetsByAddr(
      [in] isect: Cardinal;
      [in] offset: Cardinal;
      [in] length: Cardinal;
      [out] out Result: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findILOffsetsByRVA(
      [in] rva: Cardinal;
      [in] length: Cardinal;
      [out] out Result: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findILOffsetsByVA(
      [in] va: UInt64;
      [in] length: Cardinal;
      [out] out Result: IDiaEnumLineNumbers
    ): HResult; stdcall;

    function findInputAssemblyFiles(
      [out] out Result: IDiaEnumInputAssemblyFiles
    ): HResult; stdcall;

    function findInputAssembly(
      [in] index: Cardinal;
      [out] out Resul: IDiaInputAssemblyFile
    ): HResult; stdcall;

    function findInputAssemblyById(
      [in] uniqueId: Cardinal;
      [out] out Resul: IDiaInputAssemblyFile
    ): HResult; stdcall;

    function getFuncMDTokenMapSize(
      [out] out cb: Cardinal
    ): HResult; stdcall;

    function getFuncMDTokenMap(
      [in, NumberOfBytes] cb: Cardinal;
      [out, NumberOfBytes] out pcb: Cardinal;
      [out, WritesTo] pb: Pointer
    ): HResult; stdcall;

    function getTypeMDTokenMapSize(
      [out] out cb: Cardinal
    ): HResult; stdcall;

    function getTypeMDTokenMap(
      [in, NumberOfBytes] cb: Cardinal;
      [out, NumberOfBytes] out pcb: Cardinal;
      [out, WritesTo] pb: Pointer
    ): HResult; stdcall;

    function getNumberOfFunctionFragments_VA(
      [in] vaFunc: UInt64;
      [in] cbFunc: Cardinal;
      [out] out NumFragments: Cardinal
    ): HResult; stdcall;

    function getNumberOfFunctionFragments_RVA(
      [in] rvaFunc: Cardinal;
      [in] cbFunc: Cardinal;
      [out] out NumFragments: Cardinal
    ): HResult; stdcall;

    function getFunctionFragments_VA(
      [in] vaFunc: UInt64;
      [in] cbFunc: Cardinal;
      [in, NumberOfElements] cFragments: Cardinal;
      [out, WritesTo] pVaFragment: PUInt64;
      [out, WritesTo] pLenFragment: PCardinal
    ): HResult; stdcall;

    function getFunctionFragments_RVA(
      [in] rvaFunc: Cardinal;
      [in] cbFunc: Cardinal;
      [in, NumberOfElements] cFragments: Cardinal;
      [out, WritesTo] pRvaFragment: PCardinal;
      [out, WritesTo] pLenFragment: PCardinal
    ): HResult; stdcall;

    function getExports(
      [out] out Result: IDiaEnumSymbols
    ): HResult; stdcall;

    function getHeapAllocationSites(
      [out] out Result: IDiaEnumSymbols
    ): HResult; stdcall;

    function findInputAssemblyFile(
      [in] const Symbol: IDiaSymbol;
      [out] out Result: IDiaInputAssemblyFile
    ): HResult; stdcall;
  end;
  IDiaSymbolArray = TAnysizeArray<IDiaSymbol>;
  PIDiaSymbolArray = ^IDiaSymbolArray;

  // DIA::dia2.h
  IDiaEnumSymbols = interface (IUnknown)
    ['{CAB72C48-443B-48f5-9B0B-42F0820AB29A}']

    function get__NewEnum(
      [out] out RetVal: IUnknown
    ): HResult; stdcall;

    function get_Count(
      [out] out pRetVal: Integer
    ): HResult; stdcall;

    function Item(
      [in] index: Cardinal;
      [out] out symbol: IDiaSymbol
    ): HResult; stdcall;

    function Next(
      [in, NumberOfElements] celt: Cardinal;
      [out, WritesTo] rgelt: PIDiaSymbolArray;
      [out, NumberOfElements] out celtFetched: Cardinal
    ): HResult; stdcall;

    function Skip(
      [in] celt: Cardinal
    ): HResult; stdcall;

    function Reset(
    ): HResult; stdcall;

    function Clone(
      [out] out ppenum: IDiaEnumSymbols
    ): HResult; stdcall;
  end;

  // DIA::dia2.h
  IDiaEnumSymbolsByAddr = interface (IUnknown)
    ['{624B7D9C-24EA-4421-9D06-3B577471C1FA}']

    function symbolByAddr(
      [in] isect: Cardinal;
      [in] offset: Cardinal;
      [out] out Symbol: IDiaSymbol
    ): HResult; stdcall;

    function symbolByRVA(
      [in] relativeVirtualAddress: Cardinal;
      [out] out Symbol: IDiaSymbol
    ): HResult; stdcall;

    function symbolByVA(
      [in] virtualAddress: UInt64;
      [out] out Symbol: IDiaSymbol
    ): HResult; stdcall;

    function Next(
      [in, NumberOfElements] celt: Cardinal;
      [out, WritesTo] rgelt: PIDiaSymbolArray;
      [out, NumberOfElements] out celtFetched: Cardinal
    ): HResult; stdcall;

    function Prev(
      [in, NumberOfElements] celt: Cardinal;
      [out, WritesTo] rgelt: PIDiaSymbolArray;
      [out, NumberOfElements] out celtFetched: Cardinal
    ): HResult; stdcall;

    function Clone(
      [out] out enum: IDiaEnumSymbolsByAddr
    ): HResult; stdcall;
  end;

  // DIA::dia2.h
  IDiaDataSource = interface (IUnknown)
    ['{79F1BB5F-B66E-48e5-B6A9-1545C323CA3D}']

    function get_lastError(
      [out] out RetVal: WideString
    ): HResult; stdcall;

    function LoadDataFromPdb(
      [in] Path: WideString
    ): HResult; stdcall;

    function LoadAndValidateDataFromPdb(
      [in] Path: WideString;
      [in] const sig70: TGuid;
      [in] sig: Cardinal;
      [in] age: Cardinal
    ): HResult; stdcall;

    function LoadDataForExe(
      [in] executable: WideString;
      [in] searchPath: WideString;
      [in] const Callback: IUnknown
    ): HResult; stdcall;

    function LoadDataFromIStream(
      [in] const Stream: IStream
    ): HResult; stdcall;

    function OpenSession(
      [out] out Session: IDiaSession
    ): HResult; stdcall;

    function LoadDataFromCodeViewInfo(
      [in] executable: WideString;
      [in] searchPath: WideString;
      [in, NumberOfBytes] cbCvInfo: Cardinal;
      [in, ReadsFrom] pbCvInfo: Pointer;
      [in] const Callback: IUnknown
    ): HResult; stdcall;

    function LoadDataFromMiscInfo(
      [in] executable: WideString;
      [in] searchPath: WideString;
      [in] timeStampExe: TUnixTime;
      [in] timeStampDbg: TUnixTime;
      [in, Bytes] sizeOfExe: Cardinal;
      [in, NumberOfBytes] cbMiscInfo: Cardinal;
      [in, ReadsFrom] pbMiscInfo: Pointer;
      [in] const Callback: IUnknown
    ): HResult; stdcall;
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
