unit Ntapi.msdia;

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ImageHlp, Ntapi.DbgHelp, Ntapi.ObjIdl,
  DelphiApi.Reflection;

const
  msdia100 = 'msdia100.dll';
  msdia120 = 'msdia120.dll';
  msdia140 = 'msdia140.dll';

  // DIA::dia2.h
  CLSID_DiaSource: TGuid = '{e6756135-1e65-4d17-8576-610761398c3c}';

  // DIA::dia2.idl - errors
  E_PDB_OK = $806D0001;
  E_PDB_USAGE = $806D0002;
  E_PDB_OUT_OF_MEMORY = $806D0003;
  E_PDB_FILE_SYSTEM = $806D0004;
  E_PDB_NOT_FOUND = $806D0005;
  E_PDB_INVALID_SIG = $806D0006;
  E_PDB_INVALID_AGE = $806D0007;
  E_PDB_PRECOMP_REQUIRED = $806D0008;
  E_PDB_OUT_OF_TI = $806D0009;
  E_PDB_NOT_IMPLEMENTED = $806D000A;
  E_PDB_V1_PDB = $806D000B;
  E_PDB_FORMAT = $806D000C;
  E_PDB_LIMIT = $806D000D;
  E_PDB_CORRUPT = $806D000E;
  E_PDB_TI16 = $806D000F;
  E_PDB_ACCESS_DENIED = $806D0010;
  E_PDB_ILLEGAL_TYPE_EDIT = $806D0011;
  E_PDB_INVALID_EXECUTABLE = $806D0012;
  E_PDB_DBG_NOT_FOUND = $806D0013;
  E_PDB_NO_DEBUG_INFO = $806D0014;
  E_PDB_INVALID_EXE_TIMESTAMP = $806D0015;
  E_PDB_RESERVED = $806D0016;
  E_PDB_DEBUG_INFO_NOT_IN_PDB = $806D0017;
  E_PDB_SYMSRV_BAD_CACHE_PATH = $806D0018;
  E_PDB_SYMSRV_CACHE_FULL = $806D0019;
  E_PDB_OBJECT_DISPOSED = $806D001A;

  // DIA::dia2.h - name search options
  nsfCaseSensitive = $01;
  nsfCaseInsensitive = $02;
  nsfFNameExt = $04;
  nsfRegularExpression = $08;
  nsfUndecoratedName = $10;

  // DIA::cvconst.h - platform types
  CV_CFL_8080 = $00;
  CV_CFL_8086 = $01;
  CV_CFL_80286 = $02;
  CV_CFL_80386 = $03;
  CV_CFL_80486 = $04;
  CV_CFL_PENTIUM = $05;
  CV_CFL_PENTIUMII = $06;
  CV_CFL_PENTIUMIII = $07;
  CV_CFL_MIPS = $10;
  CV_CFL_MIPS16 = $11;
  CV_CFL_MIPS32 = $12;
  CV_CFL_MIPS64 = $13;
  CV_CFL_MIPSI = $14;
  CV_CFL_MIPSII = $15;
  CV_CFL_MIPSIII = $16;
  CV_CFL_MIPSIV = $17;
  CV_CFL_MIPSV = $18;
  CV_CFL_M68000 = $20;
  CV_CFL_M68010 = $21;
  CV_CFL_M68020 = $22;
  CV_CFL_M68030 = $23;
  CV_CFL_M68040 = $24;
  CV_CFL_ALPHA_21064 = $30;
  CV_CFL_ALPHA_21164 = $31;
  CV_CFL_ALPHA_21164A = $32;
  CV_CFL_ALPHA_21264 = $33;
  CV_CFL_ALPHA_21364 = $34;
  CV_CFL_PPC601 = $40;
  CV_CFL_PPC603 = $41;
  CV_CFL_PPC604 = $42;
  CV_CFL_PPC620 = $43;
  CV_CFL_PPCFP = $44;
  CV_CFL_PPCBE = $45;
  CV_CFL_SH3 = $50;
  CV_CFL_SH3E = $51;
  CV_CFL_SH3DSP = $52;
  CV_CFL_SH4 = $53;
  CV_CFL_SHMEDIA = $54;
  CV_CFL_ARM3 = $60;
  CV_CFL_ARM4 = $61;
  CV_CFL_ARM4T = $62;
  CV_CFL_ARM5 = $63;
  CV_CFL_ARM5T = $64;
  CV_CFL_ARM6 = $65;
  CV_CFL_ARM_XMAC = $66;
  CV_CFL_ARM_WMMX = $67;
  CV_CFL_ARM7 = $68;
  CV_CFL_OMNI = $70;
  CV_CFL_IA64 = $80;
  CV_CFL_IA64_2 = $81;
  CV_CFL_CEE = $90;
  CV_CFL_AM33 = $A0;
  CV_CFL_M32R = $B0;
  CV_CFL_TRICORE = $C0;
  CV_CFL_X64 = $D0;
  CV_CFL_EBC = $E0;
  CV_CFL_THUMB = $F0;
  CV_CFL_ARMNT = $F4;
  CV_CFL_ARM64 = $F6;
  CV_CFL_HYBRID_X86_ARM64 = $F7;
  CV_CFL_ARM64EC = $F8;
  CV_CFL_ARM64X = $F9;
  CV_CFL_UNKNOWN = $FF;
  CV_CFL_D3D11_SHADER = $100;

type
  // DIA::cvconst.h
  [SDKName('CV_call_e')]
  [NamingStyle(nsSnakeCase, 'CV_CALL')]
  TCvCallE = (
    CV_CALL_NEAR_C = 0,
    CV_CALL_FAR_C = 1,
    CV_CALL_NEAR_PASCAL = 2,
    CV_CALL_FAR_PASCAL = 3,
    CV_CALL_NEAR_FAST = 4,
    CV_CALL_FAR_FAST = 5,
    CV_CALL_SKIPPED = 6,
    CV_CALL_NEAR_STD = 7,
    CV_CALL_FAR_STD = 8,
    CV_CALL_NEAR_SYS = 9,
    CV_CALL_FAR_SYS = 10,
    CV_CALL_THISCALL = 11,
    CV_CALL_MIPSCALL = 12,
    CV_CALL_GENERIC = 13,
    CV_CALL_ALPHACALL = 14,
    CV_CALL_PPCCALL = 15,
    CV_CALL_SHCALL = 16,
    CV_CALL_ARMCALL = 17,
    CV_CALL_AM33CALL = 18,
    CV_CALL_TRICALL = 19,
    CV_CALL_SH5CALL = 20,
    CV_CALL_M32RCALL = 21,
    CV_CALL_CLRCALL = 22,
    CV_CALL_INLINE = 23,
    CV_CALL_NEAR_VECTOR = 24,
    CV_CALL_SWIFT = 25
  );

  // DIA::cvconst.h
  [SDKName('CV_access_e')]
  [NamingStyle(nsCamelCase, 'CV_'), MinValue(1)]
  TCvAccessE = (
    [Reserved] CV_reserverd = 0,
    CV_private = 1,
    CV_protected = 2,
    CV_public = 3
  );

  // DIA::cvconst.h
  [SDKName('THUNK_ORDINAL')]
  [NamingStyle(nsSnakeCase, 'THUNK_ORDINAL')]
  TThunkOrdinal = (
    THUNK_ORDINAL_NOTYPE = 0,
    THUNK_ORDINAL_ADJUSTOR = 1,
    THUNK_ORDINAL_VCALL = 2,
    THUNK_ORDINAL_PCODE = 3,
    THUNK_ORDINAL_LOAD = 4,
    THUNK_ORDINAL_TRAMP_INCREMENTAL = 5,
    THUNK_ORDINAL_TRAMP_BRANCHISLAND = 6,
    THUNK_ORDINAL_TRAMP_STRICTICF = 7,
    THUNK_ORDINAL_TRAMP_ARM64XSAMEADDRESS = 8,
    THUNK_ORDINAL_TRAMP_FUNCOVERRIDING = 9
  );

  // DIA::cvconst.h
  [SDKName('CV_SourceChksum_t')]
  [NamingStyle(nsSnakeCase, 'CHKSUM_TYPE')]
  TCvSourceChecksumT = (
    CHKSUM_TYPE_NONE = 0,
    CHKSUM_TYPE_MD5 = 1,
    CHKSUM_TYPE_SHA1 = 2,
    CHKSUM_TYPE_SHA_256 = 3
  );

  // DIA::cvconst.h
  [SDKName('LocationType')]
  [NamingStyle(nsCamelCase, 'LocIs')]
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

  // DIA::cvconst.h
  [SDKName('UdtKind')]
  [NamingStyle(nsCamelCase, 'Udt')]
  TUdtKind = (
    UdtStruct = 0,
    UdtClass = 1,
    UdtUnion = 2,
    UdtInterface = 3,
    UdtTaggedUnion = 4
  );

  // DIA::cvconst.h
  [SDKName('BasicType')]
  [NamingStyle(nsPreserveCase, 'bt'), ValidValues([0..3, 6..10, 13..14, 25..34])]
  TBasicType = (
    btNoType = 0,
    btVoid = 1,
    btChar = 2,
    btWChar = 3,
    [Reserved] btReserved4 = 4,
    [Reserved] btReserved5 = 5,
    btInt = 6,
    btUInt = 7,
    btFloat = 8,
    btBCD = 9,
    btBool = 10,
    [Reserved] btReserved11,
    [Reserved] btReserved12,
    btLong = 13,
    btULong = 14,
    [Reserved] btReserved15,
    [Reserved] btReserved16,
    [Reserved] btReserved17,
    [Reserved] btReserved18,
    [Reserved] btReserved19,
    [Reserved] btReserved20,
    [Reserved] btReserved21,
    [Reserved] btReserved22,
    [Reserved] btReserved23,
    [Reserved] btReserved24,
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

  // DIA::cvconst.h
  [SDKName('CV_CFL_LANG')]
  [NamingStyle(nsSnakeCase, 'CV_CFL')]
  TCvCflLang = (
    CV_CFL_C = 0,
    CV_CFL_CXX = 1,
    CV_CFL_FORTRAN = 2,
    CV_CFL_MASM = 3,
    CV_CFL_PASCAL = 4,
    CV_CFL_BASIC = 5,
    CV_CFL_COBOL = 6,
    CV_CFL_LINK = 7,
    CV_CFL_CVTRES = 8,
    CV_CFL_CVTPGD = 9,
    CV_CFL_CSHARP = 10,
    CV_CFL_VB = 11,
    CV_CFL_ILASM = 12,
    CV_CFL_JAVA = 13,
    CV_CFL_JSCRIPT = 14,
    CV_CFL_MSIL = 15,
    CV_CFL_HLSL = 16,
    CV_CFL_OBJC = 17,
    CV_CFL_OBJCXX = 18,
    CV_CFL_SWIFT = 19,
    CV_CFL_ALIASOBJ = 20,
    CV_CFL_RUST = 21,
    CV_CFL_GO = 22
  );

  // DIA::cvconst.h
  [SDKName('CV_CPU_TYPE_e')]
  [NamingStyle(nsSnakeCase, 'CV_CFL')]
  [SubEnum(MAX_UINT, CV_CFL_8080, 'CV_CFL_8080')]
  [SubEnum(MAX_UINT, CV_CFL_8086, 'CV_CFL_8086')]
  [SubEnum(MAX_UINT, CV_CFL_80286, 'CV_CFL_80286')]
  [SubEnum(MAX_UINT, CV_CFL_80386, 'CV_CFL_80386')]
  [SubEnum(MAX_UINT, CV_CFL_80486, 'CV_CFL_80486')]
  [SubEnum(MAX_UINT, CV_CFL_PENTIUM, 'CV_CFL_PENTIUM')]
  [SubEnum(MAX_UINT, CV_CFL_PENTIUMII, 'CV_CFL_PENTIUMII')]
  [SubEnum(MAX_UINT, CV_CFL_PENTIUMIII, 'CV_CFL_PENTIUMIII')]
  [SubEnum(MAX_UINT, CV_CFL_MIPS, 'CV_CFL_MIPS')]
  [SubEnum(MAX_UINT, CV_CFL_MIPS16, 'CV_CFL_MIPS16')]
  [SubEnum(MAX_UINT, CV_CFL_MIPS32, 'CV_CFL_MIPS32')]
  [SubEnum(MAX_UINT, CV_CFL_MIPS64, 'CV_CFL_MIPS64')]
  [SubEnum(MAX_UINT, CV_CFL_MIPSI, 'CV_CFL_MIPSI')]
  [SubEnum(MAX_UINT, CV_CFL_MIPSII, 'CV_CFL_MIPSII')]
  [SubEnum(MAX_UINT, CV_CFL_MIPSIII, 'CV_CFL_MIPSIII')]
  [SubEnum(MAX_UINT, CV_CFL_MIPSIV, 'CV_CFL_MIPSIV')]
  [SubEnum(MAX_UINT, CV_CFL_MIPSV, 'CV_CFL_MIPSV')]
  [SubEnum(MAX_UINT, CV_CFL_M68000, 'CV_CFL_M68000')]
  [SubEnum(MAX_UINT, CV_CFL_M68010, 'CV_CFL_M68010')]
  [SubEnum(MAX_UINT, CV_CFL_M68020, 'CV_CFL_M68020')]
  [SubEnum(MAX_UINT, CV_CFL_M68030, 'CV_CFL_M68030')]
  [SubEnum(MAX_UINT, CV_CFL_M68040, 'CV_CFL_M68040')]
  [SubEnum(MAX_UINT, CV_CFL_ALPHA_21064, 'CV_CFL_ALPHA_21064')]
  [SubEnum(MAX_UINT, CV_CFL_ALPHA_21164, 'CV_CFL_ALPHA_21164')]
  [SubEnum(MAX_UINT, CV_CFL_ALPHA_21164A, 'CV_CFL_ALPHA_21164A')]
  [SubEnum(MAX_UINT, CV_CFL_ALPHA_21264, 'CV_CFL_ALPHA_21264')]
  [SubEnum(MAX_UINT, CV_CFL_ALPHA_21364, 'CV_CFL_ALPHA_21364')]
  [SubEnum(MAX_UINT, CV_CFL_PPC601, 'CV_CFL_PPC601')]
  [SubEnum(MAX_UINT, CV_CFL_PPC603, 'CV_CFL_PPC603')]
  [SubEnum(MAX_UINT, CV_CFL_PPC604, 'CV_CFL_PPC604')]
  [SubEnum(MAX_UINT, CV_CFL_PPC620, 'CV_CFL_PPC620')]
  [SubEnum(MAX_UINT, CV_CFL_PPCFP, 'CV_CFL_PPCFP')]
  [SubEnum(MAX_UINT, CV_CFL_PPCBE, 'CV_CFL_PPCBE')]
  [SubEnum(MAX_UINT, CV_CFL_SH3, 'CV_CFL_SH3')]
  [SubEnum(MAX_UINT, CV_CFL_SH3E, 'CV_CFL_SH3E')]
  [SubEnum(MAX_UINT, CV_CFL_SH3DSP, 'CV_CFL_SH3DSP')]
  [SubEnum(MAX_UINT, CV_CFL_SH4, 'CV_CFL_SH4')]
  [SubEnum(MAX_UINT, CV_CFL_SHMEDIA, 'CV_CFL_SHMEDIA')]
  [SubEnum(MAX_UINT, CV_CFL_ARM3, 'CV_CFL_ARM3')]
  [SubEnum(MAX_UINT, CV_CFL_ARM4, 'CV_CFL_ARM4')]
  [SubEnum(MAX_UINT, CV_CFL_ARM4T, 'CV_CFL_ARM4T')]
  [SubEnum(MAX_UINT, CV_CFL_ARM5, 'CV_CFL_ARM5')]
  [SubEnum(MAX_UINT, CV_CFL_ARM5T, 'CV_CFL_ARM5T')]
  [SubEnum(MAX_UINT, CV_CFL_ARM6, 'CV_CFL_ARM6')]
  [SubEnum(MAX_UINT, CV_CFL_ARM_XMAC, 'CV_CFL_ARM_XMAC')]
  [SubEnum(MAX_UINT, CV_CFL_ARM_WMMX, 'CV_CFL_ARM_WMMX')]
  [SubEnum(MAX_UINT, CV_CFL_ARM7, 'CV_CFL_ARM7')]
  [SubEnum(MAX_UINT, CV_CFL_OMNI, 'CV_CFL_OMNI')]
  [SubEnum(MAX_UINT, CV_CFL_IA64, 'CV_CFL_IA64')]
  [SubEnum(MAX_UINT, CV_CFL_IA64_2, 'CV_CFL_IA64_2')]
  [SubEnum(MAX_UINT, CV_CFL_CEE, 'CV_CFL_CEE')]
  [SubEnum(MAX_UINT, CV_CFL_AM33, 'CV_CFL_AM33')]
  [SubEnum(MAX_UINT, CV_CFL_M32R, 'CV_CFL_M32R')]
  [SubEnum(MAX_UINT, CV_CFL_TRICORE, 'CV_CFL_TRICORE')]
  [SubEnum(MAX_UINT, CV_CFL_X64, 'CV_CFL_X64')]
  [SubEnum(MAX_UINT, CV_CFL_EBC, 'CV_CFL_EBC')]
  [SubEnum(MAX_UINT, CV_CFL_THUMB, 'CV_CFL_THUMB')]
  [SubEnum(MAX_UINT, CV_CFL_ARMNT, 'CV_CFL_ARMNT')]
  [SubEnum(MAX_UINT, CV_CFL_ARM64, 'CV_CFL_ARM64')]
  [SubEnum(MAX_UINT, CV_CFL_HYBRID_X86_ARM64, 'CV_CFL_HYBRID_X86_ARM64')]
  [SubEnum(MAX_UINT, CV_CFL_ARM64EC, 'CV_CFL_ARM64EC')]
  [SubEnum(MAX_UINT, CV_CFL_ARM64X, 'CV_CFL_ARM64X')]
  [SubEnum(MAX_UINT, CV_CFL_UNKNOWN, 'CV_CFL_UNKNOWN')]
  [SubEnum(MAX_UINT, CV_CFL_D3D11_SHADER, 'CV_CFL_D3D11_SHADER')]
  TCvCpuTypeE = type Cardinal;

  // DIA::cvconst.h
  [SDKName('CV_HLSLREG_e')]
  [NamingStyle(nsSnakeCase, 'CV_HLSLREG')]
  TCvHlslRegE = (
    CV_HLSLREG_TEMP = 0,
    CV_HLSLREG_INPUT = 1,
    CV_HLSLREG_OUTPUT = 2,
    CV_HLSLREG_INDEXABLE_TEMP = 3,
    CV_HLSLREG_IMMEDIATE32 = 4,
    CV_HLSLREG_IMMEDIATE64 = 5,
    CV_HLSLREG_SAMPLER = 6,
    CV_HLSLREG_RESOURCE = 7,
    CV_HLSLREG_CONSTANT_BUFFER = 8,
    CV_HLSLREG_IMMEDIATE_CONSTANT_BUFFER = 9,
    CV_HLSLREG_LABEL = 10,
    CV_HLSLREG_INPUT_PRIMITIVEID = 11,
    CV_HLSLREG_OUTPUT_DEPTH = 12,
    CV_HLSLREG_NULL = 13,
    CV_HLSLREG_RASTERIZER = 14,
    CV_HLSLREG_OUTPUT_COVERAGE_MASK = 15,
    CV_HLSLREG_STREAM = 16,
    CV_HLSLREG_FUNCTION_BODY = 17,
    CV_HLSLREG_FUNCTION_TABLE = 18,
    CV_HLSLREG_INTERFACE = 19,
    CV_HLSLREG_FUNCTION_INPUT = 20,
    CV_HLSLREG_FUNCTION_OUTPUT = 21,
    CV_HLSLREG_OUTPUT_CONTROL_POINT_ID = 22,
    CV_HLSLREG_INPUT_FORK_INSTANCE_ID = 23,
    CV_HLSLREG_INPUT_JOIN_INSTANCE_ID = 24,
    CV_HLSLREG_INPUT_CONTROL_POINT = 25,
    CV_HLSLREG_OUTPUT_CONTROL_POINT = 26,
    CV_HLSLREG_INPUT_PATCH_CONSTANT = 27,
    CV_HLSLREG_INPUT_DOMAIN_POINT = 28,
    CV_HLSLREG_THIS_POINTER = 29,
    CV_HLSLREG_UNORDERED_ACCESS_VIEW = 30,
    CV_HLSLREG_THREAD_GROUP_SHARED_MEMORY = 31,
    CV_HLSLREG_INPUT_THREAD_ID = 32,
    CV_HLSLREG_INPUT_THREAD_GROUP_ID = 33,
    CV_HLSLREG_INPUT_THREAD_ID_IN_GROUP = 34,
    CV_HLSLREG_INPUT_COVERAGE_MASK = 35,
    CV_HLSLREG_INPUT_THREAD_ID_IN_GROUP_FLATTENED = 36,
    CV_HLSLREG_INPUT_GS_INSTANCE_ID = 37,
    CV_HLSLREG_OUTPUT_DEPTH_GREATER_EQUAL = 38,
    CV_HLSLREG_OUTPUT_DEPTH_LESS_EQUAL = 39,
    CV_HLSLREG_CYCLE_COUNTER = 40
  );

  // DIA::cvconst.h
  [SDKName('CV_HLSLMemorySpace_e')]
  [NamingStyle(nsSnakeCase, 'CV_HLSL_MEMSPACE')]
  TCvHlslMemorySpaceE = (
    CV_HLSL_MEMSPACE_DATA = 0,
    CV_HLSL_MEMSPACE_SAMPLER = 1,
    CV_HLSL_MEMSPACE_RESOURCE = 2,
    CV_HLSL_MEMSPACE_RWRESOURCE = 3
  );

  // DIA::cvconst.h
  [SDKName('CV_CoroutineKind_e')]
  [NamingStyle(nsSnakeCase, 'CV_COROUTINEKIND')]
  TCvCoroutineKindE = (
    CV_COROUTINEKIND_NONE = 0,
    CV_COROUTINEKIND_PRIMARY = 1,
    CV_COROUTINEKIND_INIT = 2,
    CV_COROUTINEKIND_RESUME = 3,
    CV_COROUTINEKIND_DESTROY = 4
  );

  // DIA::cvconst.h
  [SDKName('CV_AssociationKind_e')]
  [NamingStyle(nsSnakeCase, 'CV_COROUTINEKIND')]
  TCvAssociationKindE = (
    CV_ASSOCIATIONKIND_NONE = 0,
    CV_ASSOCIATIONKIND_COROUTINE = 1
  );

  TDiaTagValueUnion = record
  case Integer of
    1: (data8: Byte);
    2: (data16: Word);
    4: (data32: Cardinal);
    8: (data64: UInt64);
    16: (data128: TGuid);
  end;

  // DIA::dia2.h
  [SDKName('DiaTagValue')]
  TDiaTagValue = record
    value: TDiaTagValueUnion;
    valueSizeBytes: Byte;
  end;
  PDiaTagValue = ^TDiaTagValue;

  // DIA::dia2.h
  [SDKName('NameSearchOptions')]
  [FlagName(nsfCaseSensitive, 'Case-sensitive')]
  [FlagName(nsfCaseInsensitive, 'Case-insensitive')]
  [FlagName(nsfFNameExt, 'filename.ext Search')]
  [FlagName(nsfRegularExpression, 'Regular Expression')]
  [FlagName(nsfUndecoratedName, 'Undecorated Name')]
  TNameSearchOptions = type Cardinal;

  // A helper generic base for DIA enum interfaces
  IDiaEnum<I> = interface (IUnknown)
    function get__NewEnum(
      [out] out RetVal: IUnknown
    ): HResult; stdcall;

    function get_Count(
      [out] out RetVal: Integer
    ): HResult; stdcall;

    function Item(
      [in] index: Cardinal;
      [out] out Item: I
    ): HResult; stdcall;

    function Next(
      [in, NumberOfElements] Count: Integer;
      [out, WritesTo] out Elements: I;
      [out, NumberOfElements] out Fetched: Integer
    ): HResult; stdcall;

    function Skip(
      [in] Count: Cardinal
    ): HResult; stdcall;

    function Reset(
    ): HResult; stdcall;

    function Clone(
      [out] out Enum: IDiaEnum<I>
    ): HResult; stdcall;
  end;
  IDiaEnumSymbols = interface;

  IDiaSession = interface;

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
      [in, opt] searchPath: WideString;
      [in, opt] const Callback: IUnknown
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

  IDiaSymbol = interface;
  IDiaSourceFile = interface;
  IDiaInputAssemblyFile = interface;
  IDiaLineNumber = interface;
  IDiaInjectedSource = IInterface;
  IDiaSegment = IInterface;
  IDiaSectionContrib = IInterface;
  IDiaFrameData = IInterface;

  // DIA::dia2.h
  IDiaEnumSymbols = interface (IDiaEnum<IDiaSymbol>)
    ['{CAB72C48-443B-48f5-9B0B-42F0820AB29A}']
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
      [out, WritesTo] rgelt: &IDiaSymbol;
      [out, NumberOfElements] out celtFetched: Cardinal
    ): HResult; stdcall;

    function Prev(
      [in, NumberOfElements] celt: Cardinal;
      [out, WritesTo] rgelt: &IDiaSymbol;
      [out, NumberOfElements] out celtFetched: Cardinal
    ): HResult; stdcall;

    function Clone(
      [out] out enum: IDiaEnumSymbolsByAddr
    ): HResult; stdcall;
  end;

  // DIA::dia2.h
  IDiaEnumSourceFiles = interface (IDiaEnum<IDiaSourceFile>)
    ['{10F3DBD9-664F-4469-B808-9471C7A50538}']
  end;

  // DIA::dia2.h
  IDiaEnumInputAssemblyFiles = interface (IDiaEnum<IDiaSourceFile>)
    ['{1C7FF653-51F7-457E-8419-B20F57EF7E4D}']
  end;

  // DIA::dia2.h
  IDiaEnumLineNumbers = interface (IDiaEnum<IDiaLineNumber>)
    ['{FE30E878-54AC-44f1-81BA-39DE940F6052}']
  end;

  // DIA::dia2.h
  IDiaEnumInjectedSources = interface (IDiaEnum<IDiaInjectedSource>)
    ['{D5612573-6925-4468-8883-98CDEC8C384A}']
  end;

  // DIA::dia2.h
  IDiaEnumSegments = interface (IDiaEnum<IDiaSegment>)
    ['{E8368CA9-01D1-419d-AC0C-E31235DBDA9F}']
  end;

  // DIA::dia2.h
  IDiaEnumSectionContribs = interface (IDiaEnum<IDiaSectionContrib>)
    ['{1994DEB2-2C82-4b1d-A57F-AFF424D54A68}']
  end;

  // DIA::dia2.h
  IDiaEnumFrameData = interface (IDiaEnum<IDiaFrameData>)
    ['{9FC77A4B-3C1C-44ed-A798-6C1DEEA53E1F}']
    function frameByRVA(
      [in] RelativeVirtualAddress: Cardinal;
      [out] out Frame: IDiaFrameData
    ): HResult; stdcall;

    function frameByVA(
      [in] VirtualAddress: UInt64;
      [out] out Frame: IDiaFrameData
    ): HResult; stdcall;
  end;

  IDiaEnumDebugStreamData = IInterface;

  // DIA::dia2.h
  IDiaEnumDebugStreams = interface (IDiaEnum<IDiaEnumDebugStreamData>)
    ['{08CBB41E-47A6-4f87-92F1-1C9C87CED044}']
  end;

  IDiaAddressMap = IInterface;
  IDiaEnumTables = IUnknown;

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
      [in, opt] name: WideString;
      [in] compareFlags: TNameSearchOptions;
      [in] isect: Cardinal;
      [in] offset: Cardinal;
      [out] out Result: IDiaEnumSymbols
    ): HResult; stdcall;

    function findChildrenExByVA(
      [in, opt] const parent: IDiaSymbol;
      [in] symtag: TSymTagEnum;
      [in, opt] name: WideString;
      [in] compareFlags: TNameSearchOptions;
      [in] va: UInt64;
      [out] out Result: IDiaEnumSymbols
    ): HResult; stdcall;

    function findChildrenExByRVA(
      [in, opt] const parent: IDiaSymbol;
      [in] symtag: TSymTagEnum;
      [in, opt] name: WideString;
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
      [out] out RetVal: Cardinal // CV_HREG_e
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
      [out] out RetVal: TCvAccessE
    ): HResult; stdcall;

    function get_libraryName(
      [out] out RetVal: WideString
    ): HResult; stdcall;

    function get_platform(
      [out] out RetVal: TCvCpuTypeE
    ): HResult; stdcall;

    function get_language(
      [out] out RetVal: TCvCflLang
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
      [out] out RetVal: TThunkOrdinal
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
      [out] out RetVal: TCvCallE
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
      [in] compareFlags: TNameSearchOptions;
      [out] out ppResult: IDiaEnumSymbols
    ): HResult; stdcall;

    function findChildrenEx(
      [in] symtag: TSymTagEnum;
      [in, opt] name: WideString;
      [in] compareFlags: TNameSearchOptions;
      [out] out ppResult: IDiaEnumSymbols
    ): HResult; stdcall;

    function findChildrenExByAddr(
      [in] symtag: TSymTagEnum;
      [in, opt] name: WideString;
      [in] compareFlags: TNameSearchOptions;
      [in] isect: Cardinal;
      [in] offset: Cardinal;
      [out] out ppResult: IDiaEnumSymbols
    ): HResult; stdcall;

    function findChildrenExByVA(
      [in] symtag: TSymTagEnum;
      [in, opt] name: WideString;
      [in] compareFlags: TNameSearchOptions;
      [in] va: UInt64;
      [out] out ppResult: IDiaEnumSymbols
    ): HResult; stdcall;

    function findChildrenExByRVA(
      [in] symtag: TSymTagEnum;
      [in, opt] name: WideString;
      [in] compareFlags: TNameSearchOptions;
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
      [out, WritesTo] pModifiers: PCardinal // CV_modifier_e
    ): HResult; stdcall;

    function get_isReturnValue(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isOptimizedAway(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_builtInKind(
      [out] out RetVal: Cardinal // CV_builtin_e
    ): HResult; stdcall;

    function get_registerType(
      [out] out RetVal: TCvHlslRegE
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
      [out] out RetVal: TCvHlslMemorySpaceE
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
      [out] out RetVal: TImageSectionCharacteristics
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
  IDiaSymbol2 = interface (IDiaSymbol)
    ['{611e86cd-b7d1-4546-8a15-070e2b07a427}']
    function get_isObjCClass(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isObjCCategory(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_isObjCProtocol(
      [out] out RetVal: LongBool
    ): HResult; stdcall;
  end;

  // DIA::dia2.h
  IDiaSymbol3 = interface (IDiaSymbol2)
    ['{99b665f7-c1b2-49d3-89b2-a384361acab5}']
    function get_inlinee(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function get_inlineeId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;
  end;

  // DIA::dia2.h
  IDiaSymbol4 = interface (IDiaSymbol3)
    ['{bf6c88a7-e9d6-4346-99a1-d053de5a7808}']
    function get_noexcept(
      [out] out RetVal: LongBool
    ): HResult; stdcall;
  end;

  // DIA::dia2.h
  IDiaSymbol5 = interface (IDiaSymbol4)
    ['{abe2de00-dc2d-4793-af9a-ef1d90832644}']
    function get_hasAbsoluteAddress(
      [out] out RetVal: LongBool
    ): HResult; stdcall;
  end;

  // DIA::dia2.h
  IDiaSymbol6 = interface (IDiaSymbol5)
    ['{8133dad3-75fe-4234-ac7e-f8e7a1d3cbb3}']
    function get_isStaticMemberFunc(
      [out] out RetVal: LongBool
    ): HResult; stdcall;
  end;

  // DIA::dia2.h
  IDiaSymbol7 = interface (IDiaSymbol6)
    ['{64ce6cd5-7315-4328-86d6-10e303e010b4}']
    function get_isSignRet(
      [out] out RetVal: LongBool
    ): HResult; stdcall;
  end;

  // DIA::dia2.h
  IDiaSymbol8 = interface (IDiaSymbol7)
    ['{7f2e041f-1294-41bd-b83a-e715972d2ce3}']
    function get_coroutineKind(
      [out] out RetVal: TCvCoroutineKindE
    ): HResult; stdcall;

    function get_associatedSymbolKind(
      [out] out RetVal: TCvAssociationKindE
    ): HResult; stdcall;

    function get_associatedSymbolSection(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_associatedSymbolOffset(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_associatedSymbolRva(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_associatedSymbolAddr(
      [out] out RetVal: UInt64
    ): HResult; stdcall;
  end;

    // DIA::dia2.h
  IDiaSymbol9 = interface (IDiaSymbol8)
    ['{a89e5969-92a1-4f8a-b704-00121c37abbb}']
    function get_framePadSize(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_framePadOffset(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_isRTCs(
      [out] out RetVal: LongBool
    ): HResult; stdcall;
  end;

  // DIA::dia2.h
  IDiaSymbol10 = interface (IDiaSymbol9)
    ['{9034a70b-b0b7-4605-8a97-33772f3a7b8c}']
    function get_sourceLink(
      [in, NumberOfBytes] cb: Cardinal;
      [out, NumberOfBytes] out pcb: Cardinal;
      [out, WritesTo] pb: Pointer
    ): HResult; stdcall;
  end;

  // DIA::dia2.h
  IDiaSymbol11 = interface (IDiaSymbol10)
    ['{b6f54fcd-05e3-433d-b305-b0c1437d2d16}']
    function get_discriminatedUnionTag(
      [out] out TagType: IDiaSymbol;
      [out] out TagOffset: Cardinal;
      [out] out TagMask: TDiaTagValue
    ): HResult; stdcall;

    function get_tagRanges(
      [in, NumberOfBytes] count: Cardinal;
      [out] out RangeValues: Cardinal;
      [out, WritesTo] pRangeValues: PDiaTagValue
    ): HResult; stdcall;
  end;

  // DIA::dia2.h
  IDiaSourceFile = interface (IUnknown)
    ['{A2EF5353-F5A8-4eb3-90D2-CB526ACB3CDD}']
    function get_uniqueId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_fileName(
      [out] out RetVal: WideString
    ): HResult; stdcall;

    function get_checksumType(
      [out] out RetVal: TCvSourceChecksumT
    ): HResult; stdcall;

    function get_compilands(
      [out] out RetVal: IDiaEnumSymbols
    ): HResult; stdcall;

    function get_checksum(
      [in, NumberOfBytes] cbData: Cardinal;
      [out, NumberOfBytes] out pcbData: Cardinal;
      [out, WritesTo] pbData: Pointer
    ): HResult; stdcall;
  end;

  // DIA::dia2.h
  IDiaInputAssemblyFile = interface (IUnknown)
    ['{3BFE56B0-390C-4863-9430-1F3D083B7684}']
    function get_uniqueId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_index(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_timestamp(
      [out] out RetVal: TUnixTime
    ): HResult; stdcall;

    function get_pdbAvailableAtILMerge(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_fileName(
      [out] out RetVal: WideString
    ): HResult; stdcall;

    function get_version(
      [in, NumberOfBytes] cbData: Cardinal;
      [out, NumberOfBytes] out pcbData: Cardinal;
      [out, WritesTo] Data: Pointer
    ): HResult; stdcall;
  end;

  // DIA::dia2.h
  IDiaLineNumber = interface (IUnknown)
    ['{B388EB14-BE4D-421d-A8A1-6CF7AB057086}']
    function get_compiland(
      [out] out RetVal: IDiaSymbol
    ): HResult; stdcall;

    function get_sourceFile(
      [out] out RetVal: IDiaSourceFile
    ): HResult; stdcall;

    function get_lineNumber(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_lineNumberEnd(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_columnNumber(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_columnNumberEnd(
      [out] out RetVal: Cardinal
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

    function get_length(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_sourceFileId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;

    function get_statement(
      [out] out RetVal: LongBool
    ): HResult; stdcall;

    function get_compilandId(
      [out] out RetVal: Cardinal
    ): HResult; stdcall;
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
