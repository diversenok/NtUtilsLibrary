unit DelphiApi.TypInfo;

{
  This module defines types for parsing type information emitted by the Delphi
  compiler and accessible via System.TypeInfo(T).
}

interface

{$MINENUMSIZE 1}

type
  TOrdType = (otSByte, otUByte, otSWord, otUWord, otSLong, otULong);
  TFloatType = (ftSingle, ftDouble, ftExtended, ftComp, ftCurr);
  TMemberVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished);

  TMethodKind = (mkProcedure, mkFunction, mkConstructor, mkDestructor,
    mkClassProcedure, mkClassFunction, mkClassConstructor, mkClassDestructor,
    mkOperatorOverload, mkSafeProcedure, mkSafeFunction);

  TParamFlag = (pfVar, pfConst, pfArray, pfAddress, pfReference, pfOut, pfResult);
  TParamFlags = set of TParamFlag;

  TIntfFlag = (ifHasGuid, ifDispInterface, ifDispatch, ifHasRtti, ifUnused1,
    ifUnused2, ifMethRef, ifUnused3);
  TIntfFlags = set of TIntfFlag;

  TCallConv = (ccReg, ccCdecl, ccPascal, ccStdCall, ccSafeCall);
  PCallConv = ^TCallConv;

  PTypeData = ^TTypeData;

  TTypeInfo = packed record
    Kind: TTypeKind;
    Name: ShortString;
   {TypeData: TTypeData;}
    function TypeDataStart: PTypeData;
  end;
  PTypeInfo = ^TTypeInfo;
  PPTypeInfo = ^PTypeInfo;
  PPPTypeInfo = ^PPTypeInfo;

  PAttrEntry = ^TAttrEntry;
  TAttrEntry = packed record
    AttrType: PPTypeInfo;
    AttrCtor: Pointer;
    ArgLen: Word; // The length of ArgData
    ArgData: record end;
    function Tail: PAttrEntry;
  end;

  TAttrData = packed record
    Len: Word; // The total length of this structure
    AttrEntry: record end;
   {AttrEntry: array[0..0] of TAttrEntry;}
    function AttrEntryStart: PAttrEntry;
    function CollectEntries: TArray<PAttrEntry>;
    function Tail: Pointer;
  end;
  PAttrData = ^TAttrData;

  PArrayPropInfo = ^TArrayPropInfo;
  TArrayPropInfo = packed record
    Flags: Byte;
    ReadIndex: Word;
    WriteIndex: Word;
    Name: ShortString;
   {AttrData: TAttrData;}
    function AttrDataStart: PAttrData;
    function Tail: PArrayPropInfo;
  end;

  PManagedField = ^TManagedField;
  TManagedField = packed record
    TypeRef: PPTypeInfo;
    FldOffset: NativeInt;
    function Tail: PManagedField;
  end;

  PProcedureParam = ^TProcedureParam;
  TProcedureParam = packed record
    Flags: TParamFlags;
    ParamType: PPTypeInfo;
    Name: ShortString;
   {AttrData: TAttrData;}
    function AttrDataStart: PAttrData;
    function Tail: PProcedureParam;
  end;

  TProcedureSignature = packed record
    Flags: Byte; // if 255 then record stops here, with Flags
    CC: TCallConv;
    ResultType: PPTypeInfo;
    ParamCount: Byte;
    Params: record end;
   {Params: array[1..ParamCount] of TProcedureParam;}
    function ParamsStart: PProcedureParam;
    function ParamStart(Index: Integer): PProcedureParam;
    function CollectParams: TArray<PProcedureParam>;
    function Tail: Pointer;
  end;
  PProcedureSignature = ^TProcedureSignature;
  PPProcedureSignature = ^PProcedureSignature;

  TIntfMethodParamTail = packed record
    ParamType: PPTypeInfo;
    AttrData: TAttrData;
    function Tail: Pointer;
  end;
  PIntfMethodParamTail = ^TIntfMethodParamTail;

  PIntfMethodParam = ^TIntfMethodParam;
  TIntfMethodParam = packed record
    Flags: TParamFlags;
    ParamName: ShortString;
   {TypeName: ShortString;}
   {ParamTail: TIntfMethodParamTail;}
    function TypeNameStart: PShortString;
    function ParamTailStart: PIntfMethodParamTail;
    function Tail: PIntfMethodParam;
  end;

  TIntfMethodEntryTail = packed record
    Kind: TMethodKind; // only proc or func
    CC: TCallConv;
    ParamCount: Byte;
    Params: record end;
   {Params: array[1..ParamCount] of TIntfMethodParam;}
   {ResultTypeName: ShortString;} // only if func
   {ResultType: PPTypeInfo;} // only if Len(Name) > 0
   {AttrData: TAttrData;}
    function ParamsStart: PIntfMethodParam;
    function ParamStart(Index: Integer): PIntfMethodParam;
    function CollectParams: TArray<PIntfMethodParam>;
    function ResultTypeNameStart: PShortString; // only for functions
    function ResultTypeStart: PPPTypeInfo; // only for functions with a result type name
    function AttrDataStart: PAttrData;
    function Tail: Pointer;
  end;
  PIntfMethodEntryTail = ^TIntfMethodEntryTail;

  PIntfMethodEntry = ^TIntfMethodEntry;
  TIntfMethodEntry = packed record
    Name: ShortString;
   {EntryTail: TIntfMethodEntryTail;}
    function EntryTailStart: PIntfMethodEntryTail;
    function Tail: PIntfMethodEntry;
  end;

  TIntfMethodTable = packed record
    Count: Word; // methods in this interface
    RttiCount: Word; // =Count, or $FFFF if no further data
    Entries: record end;
   {Entries: array[1..Count] of TIntfMethodEntry;}
    function EntriesStart: PIntfMethodEntry;
    function EntryStart(Index: Integer): PIntfMethodEntry;
    function CollectEntries: TArray<PIntfMethodEntry>;
    function Tail: Pointer;
  end;
  PIntfMethodTable = ^TIntfMethodTable;

  TArrayTypeData = packed record
    Size: Integer;
    ElCount: Integer; // product of lengths of all dimensions
    ElType: PPTypeInfo;
    DimCount: Byte;
    Dims: array [Byte] of PPTypeInfo;
    function CollectDims: TArray<PTypeInfo>;
    function Tail: Pointer;
  end;
  PArrayTypeData = ^TArrayTypeData;

  PRecordTypeField = ^TRecordTypeField;
  TRecordTypeField = packed record
    Field: TManagedField;
    Flags: Byte;
    Name: ShortString;
   {AttrData: TAttrData;}
    function AttrDataStart: PAttrData;
    function Tail: PRecordTypeField;
  end;

  PRecordTypeMethod = ^TRecordTypeMethod;
  TRecordTypeMethod = packed record
    Flags: Byte;
    Code: Pointer;
    Name: ShortString;
   {Sig: TProcedureSignature;}
   {AttrData: TAttrData;}
    function SigStartStart: PProcedureSignature;
    function AttrDataStart: PAttrData;
    function Tail: PRecordTypeMethod;
  end;

  PMethodParam = ^TMethodParam;
  TMethodParam = record
    Flags: TParamFlags;
    ParamName: ShortString;
   {TypeName: ShortString;}
    function TypeNameStart: PShortString;
    function Tail: PMethodParam;
  end;

  PPropInfo = ^TPropInfo;
  TPropInfo = packed record
  const
    {$IF SizeOf(Pointer) = 4}
    PROPSLOT_MASK    = $FF000000;
    PROPSLOT_FIELD   = $FF000000;
    PROPSLOT_VIRTUAL = $FE000000;
    {$ELSEIF SizeOf(Pointer) = 8}
    PROPSLOT_MASK    = $FF00000000000000;
    PROPSLOT_FIELD   = $FF00000000000000;
    PROPSLOT_VIRTUAL = $FE00000000000000;
    {$ENDIF}
  var
    PropType: PPTypeInfo;
    GetProc: NativeUInt; // Check for PROPSLOT_MASK
    SetProc: NativeUInt; // Check for PROPSLOT_MASK
    StoredProc: NativeUInt;
    Index: Integer;
    Default: Integer;
    NameIndex: SmallInt;
    Name: ShortString;
    function Tail: PPropInfo;
  end;

  TPropData = packed record
    PropCount: Word;
    PropList: record end;
   {PropList: array[1..PropCount] of TPropInfo;}
    function PropListStart: PPropInfo;
    function PropStart(Index: Integer): PPropInfo;
    function CollectProps: TArray<PPropInfo>;
    function Tail: Pointer;
  end;
  PPropData = ^TPropData;

  PPropInfoEx = ^TPropInfoEx;
  TPropInfoEx = packed record
  const
    pfVisibilityShift = 0;
    pfVisibilityBits = 2;
  var
    Flags: Byte;
    Info: PPropInfo;
    AttrData: TAttrData;
    function Visibility: TMemberVisibility;
    function Tail: PPropInfoEx;
  end;

  TPropDataEx = packed record
    PropCount: Word;
    PropList: record end;
   {PropList: array[1..PropCount] of TPropInfoEx;}
    function PropListStart: PPropInfoEx;
    function PropStart(Index: Integer): PPropInfoEx;
    function CollectProps: TArray<PPropInfoEx>;
    function Tail: Pointer;
  end;
  PPropDataEx = ^TPropDataEx;

  TTypeData = packed record
    // tkEnumeration
    function EnumHasNameList: Boolean;
    function EnumNameListStart(Index: Integer): PShortString;
    function EnumNameCount: Integer;
    function EnumName(Value: Integer): String;
    function EnumCollectNames: TArray<String>;
    function EnumUnitNameStart: PShortString;
    function EnumAttrDataStart: PAttrData;

    // tkInteger, tkChar, tkWChar
    function OrdinalNonEnumAttrDataStart: PAttrData;

    // tkSet
    function SetLoByteStart: PByte;
    function SetSizeStart: PByte;

    // tkClass
    function ClassPropDataStart: PPropData;
    function ClassPropDataExStart: PPropDataEx;
    function ClassAttrDataStart: PAttrData;
    function ClassArrayPropCountStart: PWord;
    function ClassArrayPropsStart: PArrayPropInfo;
    function ClassArrayPropStart(Index: Integer): PArrayPropInfo;
    function ClassCollectArrayProps: TArray<PArrayPropInfo>;

    // tkMethod
    function MethodParamListStart(Index: Integer): PMethodParam;
    function MethodCollectParams: TArray<PMethodParam>;
    function MethodResultTypeStart: PShortString; // only for functions
    function MethodResultTypeRefStart: PPPTypeInfo; // only for functions with type name
    function MethodCCStart: PCallConv;
    function MethodParamTypeRefsStart(Index: Integer): PPPTypeInfo;
    function MethodCollectParamTypeRefs: TArray<PTypeInfo>;
    function MethodSignatureStart: PPProcedureSignature;
    function MethodAttrDataStart: PAttrData;

    // tkInterface
    function IntfMethodsStart: PIntfMethodTable;
    function IntfAttrDataStart: PAttrData;

    // tkDynArray
    function DynArrayElType3Start: PPPTypeInfo;
    function DynArrayAttrDataStart: PAttrData;

    // tkRecord
    function RecordManagedFieldsStart(Index: Integer): PManagedField;
    function RecordCollectManagedFields: TArray<PManagedField>;
    function RecordNumOpsStart: PByte;
    function RecordOpsStart(Index: Integer): PPointer;
    function RecordCollectOps: TArray<Pointer>;
    function RecordFldCntStart: PInteger;
    function RecordFieldsStart(Index: Integer): PRecordTypeField;
    function RecordCollectFields: TArray<PRecordTypeField>;
    function RecordAttrDataStart: PAttrData;
    function RecordMethCntStart: PWord;
    function RecordMethsStart(Index: Integer): PRecordTypeMethod;
    function RecordCollectMethods: TArray<PRecordTypeMethod>;

    // tkArray
    function ArrayAttrDataStart: PAttrData;
  case TTypeKind of
    tkUnknown: ();
    tkVariant: (
      VariantAttrData: TAttrData;
    );
    tkUString, tkWString: (
      UStringAttrData: TAttrData;
    );
    tkLString: (
      LStringCodePage: Word;
      LStringAttrData: TAttrData;
    );
    tkInteger, tkChar, tkEnumeration, tkWChar: (
      OrdinalType: TOrdType;
      OrdinalMinValue: Integer;
      OrdinalMaxValue: Integer;

      // enum case
      EnumBaseType: PPTypeInfo;
      EnumNameList: ShortString;
     {EnumUnitName: ShortString;}
     {EnumAttrData: TAttrData;}

      // other ordinals case
     {OrdinalNonEnumAttrData: TAttrData;}
    );
    tkSet: (
      SetTypeOrSize: UInt8;
      SetCompType: PPTypeInfo;
      SetAttrData: TAttrData;
     {SetLoByte: UInt8;}
     {SetSize: UInt8;}
    );
    tkFloat: (
      FloatType: TFloatType;
      FloatAttrData: TAttrData;
    );
    tkString: (
      SStringMaxLength: Byte;
      SStringAttrData: TAttrData;
    );
    tkClass: (
      ClassType: TClass; // most data for instance types is in VMT offsets
      ClassParentInfo: PPTypeInfo;
      ClassPropCount: SmallInt; // total properties inc. ancestors
      ClassUnitName: ShortString;
     {ClassPropData: TPropData;}
     {ClassPropDataEx: TPropDataEx;}
     {ClassAttrData: TAttrData;}
     {ClassArrayPropCount: Word;}
     {ClassArrayPropData: array[1..ArrayPropCount] of TArrayPropInfo;}
    );
    tkMethod: (
      MethodKind: TMethodKind; // only mkFunction or mkProcedure
      MethodParamCount: Byte;
     {MethodParamList: array[1..ParamCount] of TMethodParam;}
     {MethodResultType: ShortString;} // only if MethodKind = mkFunction
     {MethodResultTypeRef: PPTypeInfo;} // only if MethodKind = mkFunction
     {MethodCC: TCallConv;}
     {MethodParamTypeRefs: array[1..ParamCount] of PPTypeInfo;}
     {MethodSignature: PProcedureSignature;}
     {MethodAttrData: TAttrData;}
    );
    tkProcedure: (
      ProcSig: PProcedureSignature;
      ProcAttrData: TAttrData;
    );
    tkInterface: (
      IntfParent : PPTypeInfo; { ancestor }
      IntfFlags : TIntfFlags;
      IntfGuid : TGuid;
      IntfUnit : ShortString
     {IntfMethods: TIntfMethodTable;}
     {IntfAttrData: TAttrData;}
    );
    tkInt64: (
      Int64MinValue: Int64;
      Int64MaxValue: Int64;
      Int64AttrData: TAttrData;
    );
    tkDynArray: (
      DynArrayElSize: Integer;
      DynArrayElType: PPTypeInfo;       // nil if type does not require cleanup
      DynArrayVarType: Integer;         // Ole Automation varType equivalent
      DynArrayElType2: PPTypeInfo;      // independent of cleanup
      DynArrayUnitName: ShortString;
     {DynArrayElType3: PPTypeInfo;} // actual element type, even if dynamic array
     {DynArrayAttrData: TAttrData;}
    );
    tkRecord: (
      RecordSize: Integer;
      RecordManagedFldCount: Integer;
     {RecordManagedFields: array[0..ManagedFldCnt - 1] of TManagedField;}
     {RecordNumOps: Byte;}
     {RecordOps: array[1..NumOps] of Pointer;}
     {RecordFldCnt: Integer;}
     {RecordFields: array[1..RecFldCnt] of TRecordTypeField;}
     {RecordAttrData: TAttrData;}
     {RecordMethCnt: Word;}
     {RecordMeths: array[1..RecMethCnt] of TRecordTypeMethod;}
    );
    tkClassRef: (
      ClassRefInstanceType: PPTypeInfo;
      ClassRefAttrData: TAttrData;
    );
    tkPointer: (
      PtrRefType: PPTypeInfo;
      PtrAttrData: TAttrData;
    );
    tkArray: (
      ArrayData: TArrayTypeData;
     {ArrayAttrData: TAttrData;}
    );
  end;

function ShortStringTail(P: PShortString): Pointer;
function IsBoolType(TypeData: PTypeData): Boolean;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Functions }

function ShortStringTail;
begin
  Result := PByte(P) + PByte(P)^ + SizeOf(Byte);
end;

function IsBoolType;
var
  BaseTypeInfo: PTypeInfo;
  BaseTypeData: PTypeData;
begin
  BaseTypeInfo := TypeData.EnumBaseType^;

  if not Assigned(BaseTypeInfo) then
    Exit(False);

  // Check for known booleans and boolean-derived types
  if (BaseTypeInfo = System.TypeInfo(Boolean)) or
    (BaseTypeInfo = System.TypeInfo(ByteBool)) or
    (BaseTypeInfo = System.TypeInfo(WordBool)) or
    (BaseTypeInfo = System.TypeInfo(LongBool)) then
    Exit(True);

  // Check for the C++ bool
  BaseTypeData := BaseTypeInfo.TypeDataStart;
  Result := (BaseTypeInfo.Kind = tkEnumeration) and
    (BaseTypeData.OrdinalMinValue = 0) and (BaseTypeData.OrdinalMaxValue = 1)
    and UTF8IdentStringCompare(@BaseTypeInfo.Name, 'bool');
end;

{ TTypeInfo }

function TTypeInfo.TypeDataStart;
begin
  Result := ShortStringTail(@Name);
end;

{ TAttrEntry }

function TAttrEntry.Tail;
begin
  Result := Pointer(PByte(@ArgData) + ArgLen);
end;

{ TAttrData }

function TAttrData.AttrEntryStart;
begin
  Result := Pointer(@AttrEntry);
end;

function TAttrData.CollectEntries;
var
  RemainingLength: Integer;
  i, Count: Integer;
  Cursor: PAttrEntry;
begin
  // Count the number of entries
  Count := 0;
  RemainingLength := Len - SizeOf(Word);
  Cursor := AttrEntryStart;

  while RemainingLength >= SizeOf(TAttrEntry) do
  begin
    Dec(RemainingLength, SizeOf(TAttrEntry) + Cursor.ArgLen);
    Inc(PByte(Cursor), SizeOf(TAttrEntry) + Cursor.ArgLen);
    Inc(Count);
  end;

  if RemainingLength <> 0 then
    Error(reRangeError);

  // Save them
  SetLength(Result, Count);
  i := 0;
  Cursor := AttrEntryStart;

  while i < Count do
  begin
    Result[i] := Cursor;
    Inc(PByte(Cursor), SizeOf(TAttrEntry) + Cursor.ArgLen);
    Inc(i);
  end;
end;

function TAttrData.Tail;
begin
  Result := PByte(@Self) + Len;
end;

{ TArrayPropInfo }

function TArrayPropInfo.AttrDataStart;
begin
  Result := ShortStringTail(@Name);
end;

function TArrayPropInfo.Tail;
begin
  Result := AttrDataStart.Tail;
end;

{ TManagedField }

function TManagedField.Tail;
begin
  Result := Pointer(PByte(@Self) + SizeOf(TManagedField));
end;

{ TProcedureParam }

function TProcedureParam.AttrDataStart;
begin
  Result := ShortStringTail(@Name);
end;

function TProcedureParam.Tail;
begin
  Result := AttrDataStart.Tail;
end;

{ TProcedureSignature }

function TProcedureSignature.CollectParams;
var
  Cursor: PProcedureParam;
  i: Integer;
begin
  SetLength(Result, ParamCount);
  Cursor := ParamsStart;

  for i := 0 to High(Result) do
  begin
    Result[i] := Cursor;
    Cursor := Cursor.Tail;
  end;
end;

function TProcedureSignature.ParamsStart;
begin
  Result := Pointer(@Params);
end;

function TProcedureSignature.ParamStart;
begin
  Result := ParamsStart;

  while Index > 0 do
  begin
    Result := Result.Tail;
    Dec(Index);
  end;
end;

function TProcedureSignature.Tail;
begin
  if Byte(Flags) = $FF then
    Result := PByte(@Flags) + SizeOf(Byte)
  else
    Result := ParamStart(ParamCount);
end;

{ TIntfMethodParamTail }

function TIntfMethodParamTail.Tail;
begin
  Result := AttrData.Tail;
end;

{ TIntfMethodParam }

function TIntfMethodParam.ParamTailStart;
begin
  Result := ShortStringTail(TypeNameStart);
end;

function TIntfMethodParam.Tail;
begin
  Result := ParamTailStart.Tail;
end;

function TIntfMethodParam.TypeNameStart;
begin
  Result := ShortStringTail(@ParamName);
end;

{ TIntfMethodEntryTail }

function TIntfMethodEntryTail.AttrDataStart;
begin
  // Locate where parameters end
  Result := Pointer(ParamStart(ParamCount));

  if Kind = mkFunction then
  begin
    // For functions, the cursor points to a string; check its length
    if (PByte(Result)^ > 0) then
      // If it has a length, skip the string and the pointer that follows
      Result := Pointer(PByte(ShortStringTail(Pointer(Result))) +
        SizeOf(PPTypeInfo))
    else
      // Otherwise, only skip the (empty) string
      Result := Pointer(PByte(Result) + SizeOf(Byte));
  end;
end;

function TIntfMethodEntryTail.CollectParams;
var
  Cursor: PIntfMethodParam;
  i: Integer;
begin
  SetLength(Result, ParamCount);
  Cursor := ParamsStart;

  for i := 0 to High(Result) do
  begin
    Result[i] := Cursor;
    Cursor := Cursor.Tail;
  end;
end;

function TIntfMethodEntryTail.ParamsStart;
begin
  Result := Pointer(@Params);
end;

function TIntfMethodEntryTail.ParamStart;
begin
  Result := ParamsStart;

  while Index > 0 do
  begin
    Result := Result.Tail;
    Dec(Index);
  end;
end;

function TIntfMethodEntryTail.ResultTypeNameStart;
begin
  if Kind = mkFunction then
    Result := Pointer(ParamStart(ParamCount))
  else
    Result := nil;
end;

function TIntfMethodEntryTail.ResultTypeStart;
var
  TypeName: PShortString;
begin
  Result := nil;

  if Kind = mkFunction then
  begin
    TypeName := ResultTypeNameStart;

    if (PByte(TypeName)^ > 0) then
      Result := ShortStringTail(TypeName)
  end;
end;

function TIntfMethodEntryTail.Tail;
begin
  Result := AttrDataStart.Tail;
end;

{ TIntfMethodEntry }

function TIntfMethodEntry.EntryTailStart;
begin
  Result := ShortStringTail(@Name);
end;

function TIntfMethodEntry.Tail;
begin
  Result := EntryTailStart.Tail;
end;

{ TIntfMethodTable }

function TIntfMethodTable.CollectEntries;
var
  Cursor: PIntfMethodEntry;
  i: Integer;
begin
  if RttiCount = $FFFF then
    Exit(nil);

  SetLength(Result, RttiCount);
  Cursor := EntriesStart;

  for i := 0 to High(Result) do
  begin
    Result[i] := Cursor;
    Cursor := Cursor.Tail;
  end;
end;

function TIntfMethodTable.EntriesStart;
begin
  Result := Pointer(@Entries);
end;

function TIntfMethodTable.EntryStart;
begin
  Result := EntriesStart;

  while Index > 0 do
  begin
    Result := Result.Tail;
    Dec(Index);
  end;
end;

function TIntfMethodTable.Tail;
begin
  if RttiCount <> $FFFF then
    Result :=  Pointer(EntryStart(Count))
  else
    Result := @Entries;
end;

{ TArrayTypeData }

function TArrayTypeData.CollectDims;
var
  i: Integer;
begin
  SetLength(Result, DimCount);

  for i := 0 to High(Result) do
    if Assigned(Dims[i]) then
      Result[i] := Dims[i]^
    else
      Result[i] := nil;
end;

function TArrayTypeData.Tail;
begin
  Result := @Dims[DimCount];
end;

{ TRecordTypeField }

function TRecordTypeField.AttrDataStart;
begin
  Result := ShortStringTail(@Name);
end;

function TRecordTypeField.Tail;
begin
  Result := AttrDataStart.Tail;
end;

{ TRecordTypeMethod }

function TRecordTypeMethod.AttrDataStart;
begin
  Result := SigStartStart.Tail;
end;

function TRecordTypeMethod.SigStartStart;
begin
  Result := ShortStringTail(@Name);
end;

function TRecordTypeMethod.Tail;
begin
  Result := AttrDataStart.Tail;
end;

{ TMethodParam }

function TMethodParam.Tail;
begin
  Result := ShortStringTail(TypeNameStart);
end;

function TMethodParam.TypeNameStart;
begin
  Result := ShortStringTail(@ParamName);
end;

{ TPropInfo }

function TPropInfo.Tail;
begin
  Result := ShortStringTail(@Name);
end;

{ TPropData }

function TPropData.CollectProps;
var
  Cursor: PPropInfo;
  i: Integer;
begin
  SetLength(Result, PropCount);
  Cursor := PropListStart;

  for i := 0 to High(Result) do
  begin
    Result[i] := Cursor;
    Cursor := Cursor.Tail;
  end;
end;

function TPropData.PropListStart;
begin
  Result := Pointer(@PropList);
end;

function TPropData.PropStart;
begin
  Result := PropListStart;

  while Index > 0 do
  begin
    Result := Result.Tail;
    Dec(Index);
  end;
end;

function TPropData.Tail;
begin
  Result := PropStart(PropCount);
end;

{ TPropInfoEx }

function TPropInfoEx.Tail;
begin
  Result := AttrData.Tail;
end;

function TPropInfoEx.Visibility;
begin
  Result := TMemberVisibility((Flags shr pfVisibilityShift) and
    ((1 shl pfVisibilityBits) - 1));
end;

{ TPropDataEx }

function TPropDataEx.CollectProps;
var
  Cursor: PPropInfoEx;
  i: Integer;
begin
  SetLength(Result, PropCount);
  Cursor := PropListStart;

  for i := 0 to High(Result) do
  begin
    Result[i] := Cursor;
    Cursor := Cursor.Tail;
  end;
end;

function TPropDataEx.PropListStart;
begin
  Result := Pointer(@PropList);
end;

function TPropDataEx.PropStart;
begin
  Result := PropListStart;

  while Index > 0 do
  begin
    Result := Result.Tail;
    Dec(Index);
  end;
end;

function TPropDataEx.Tail;
begin
  Result := PropStart(PropCount);
end;

{ TTypeData }

function TTypeData.ArrayAttrDataStart;
begin
  Result := ArrayData.Tail;
end;

function TTypeData.ClassArrayPropCountStart;
begin
  Result := ClassAttrDataStart.Tail;
end;

function TTypeData.ClassArrayPropsStart;
begin
  Result := Pointer(PByte(ClassArrayPropCountStart) + SizeOf(Word));
end;

function TTypeData.ClassArrayPropStart;
begin
  Result := Pointer(PByte(ClassArrayPropCountStart) + SizeOf(Word));

  while Index > 0 do
  begin
    Result := Result.Tail;
    Dec(Index);
  end;
end;

function TTypeData.ClassAttrDataStart;
begin
  Result := ClassPropDataExStart.Tail;
end;

function TTypeData.ClassCollectArrayProps;
var
  CountStart: PWord;
  Cursor: PArrayPropInfo;
  i: Integer;
begin
  CountStart := Self.ClassArrayPropCountStart;
  Cursor := Pointer(PByte(CountStart) + SizeOf(Word));
  SetLength(Result, CountStart^);

  for i := 0 to High(Result) do
  begin
    Result[i] := Cursor;
    Cursor := Cursor.Tail;
  end;
end;

function TTypeData.ClassPropDataExStart;
begin
  Result := ClassPropDataStart.Tail;
end;

function TTypeData.ClassPropDataStart;
begin
  Result := ShortStringTail(@ClassUnitName);
end;

function TTypeData.DynArrayAttrDataStart;
begin
  Result := Pointer(PByte(DynArrayElType3Start) + SizeOf(PPTypeInfo));
end;

function TTypeData.DynArrayElType3Start;
begin
  Result := ShortStringTail(@DynArrayUnitName);
end;

function TTypeData.EnumAttrDataStart;
begin
  Result := ShortStringTail(EnumUnitNameStart);
end;

function TTypeData.EnumCollectNames;
var
  BaseTypeData: PTypeData;
  Cursor: PShortString;
  i: Integer;
begin
  if EnumHasNameList then
    Cursor := EnumNameListStart(0)
  else
  begin
    // The base type is not nil here since it's convered by EnumHasNameList
    BaseTypeData := EnumBaseType^.TypeDataStart;
    Cursor := BaseTypeData.EnumNameListStart(OrdinalMinValue -
      BaseTypeData.OrdinalMinValue);
  end;

  SetLength(Result, EnumNameCount);

  for i := 0 to High(Result) do
  begin
    Result[i] := UTF8IdentToString(Cursor);
    Cursor := ShortStringTail(Cursor);
  end;
end;

function TTypeData.EnumHasNameList;
begin
  Result := not Assigned(EnumBaseType) or (EnumBaseType^.TypeDataStart = @Self)
    or IsBoolType(@Self);
end;

function TTypeData.EnumName;
var
  BaseTypeData: PTypeData;
  Cursor: PShortString;
begin
  if (Value < OrdinalMinValue) or (Value > OrdinalMaxValue) then
    Exit('');

  // Hack for booleans
  if (OrdinalMinValue = -2147483648) and (OrdinalMaxValue = 2147483647) and
    (Value <> 0) then
    Value := 1;

  if EnumHasNameList then
    Cursor := EnumNameListStart(Value)
  else
  begin
    // The base type is not nil here since it's convered by EnumHasNames
    BaseTypeData := EnumBaseType^.TypeDataStart;
    Cursor := BaseTypeData.EnumNameListStart(Value -
      BaseTypeData.OrdinalMinValue);
  end;

  Result := UTF8IdentToString(Cursor);
end;

function TTypeData.EnumNameCount;
begin
  if (OrdinalMinValue = -2147483648) and (OrdinalMaxValue = 2147483647) then
    Result := 2 // Hack for boolean types
  else
    Result := OrdinalMaxValue - OrdinalMinValue + 1;
end;

function TTypeData.EnumNameListStart;
begin
  Result := @EnumNameList;

  while Index > 0 do
  begin
    Result := ShortStringTail(Result);
    Dec(Index);
  end;
end;

function TTypeData.EnumUnitNameStart;
begin
  if EnumHasNameList then
    Result := EnumNameListStart(EnumNameCount)
  else
    Result := EnumNameListStart(0);
end;

function TTypeData.IntfAttrDataStart;
begin
  Result := IntfMethodsStart.Tail;
end;

function TTypeData.IntfMethodsStart;
begin
  Result := ShortStringTail(@IntfUnit);
end;

function TTypeData.MethodAttrDataStart;
begin
  Result := Pointer(PByte(MethodSignatureStart) + SizeOf(PProcedureSignature));
end;

function TTypeData.MethodCCStart;
begin
  Result := Pointer(MethodParamListStart(MethodParamCount));

  if MethodKind = mkFunction then
  begin
    // Currently pointing to a string, check its length to see if there a
    // PPTypeInfo that follows
    if PByte(Result)^ > 0 then
      Result := Pointer(PByte(ShortStringTail(Pointer(Result))) +
        SizeOf(PPTypeInfo))
    else
      Inc(PByte(Result));
  end;
end;

function TTypeData.MethodCollectParams;
var
  Cursor: PMethodParam;
  i: Integer;
begin
  SetLength(Result, MethodParamCount);
  Cursor := MethodParamListStart(0);

  for i := 0 to High(Result) do
  begin
    Result[i] := Cursor;
    Cursor := Cursor.Tail;
  end;
end;

function TTypeData.MethodCollectParamTypeRefs;
var
  Cursor: PPPTypeInfo;
  i: Integer;
begin
  SetLength(Result, MethodParamCount);
  Cursor := MethodParamTypeRefsStart(0);

  for i := 0 to High(Result) do
  begin
    if Assigned(Cursor^) then
      Result[i] := Cursor^^
    else
      Result[i] := nil;
    Inc(Cursor);
  end;
end;

function TTypeData.MethodParamListStart;
begin
  Result := Pointer(PByte(@MethodParamCount) + SizeOf(Byte));

  while Index > 0 do
  begin
    Result := Result.Tail;
    Dec(Index);
  end;
end;

function TTypeData.MethodParamTypeRefsStart;
begin
  Result := Pointer(PByte(MethodCCStart) + SizeOf(TCallConv) + Index *
    SizeOf(PPTypeInfo));
end;

function TTypeData.MethodResultTypeRefStart;
var
  Name: PShortString;
begin
  Name := MethodResultTypeStart;

  if Assigned(Name) and (PByte(Name)^ > 0) then
    Result := ShortStringTail(Name)
  else
    Result := nil;
end;

function TTypeData.MethodResultTypeStart;
begin
  if MethodKind = mkFunction then
    Result := Pointer(MethodParamListStart(MethodParamCount))
  else
    Result := nil;
end;

function TTypeData.MethodSignatureStart;
begin
  Result := Pointer(MethodParamTypeRefsStart(Self.MethodParamCount));
end;

function TTypeData.OrdinalNonEnumAttrDataStart;
begin
  Result := Pointer(@EnumBaseType); // union
end;

function TTypeData.RecordAttrDataStart;
var
  CountStart: PInteger;
  Cursor: PRecordTypeField;
  Index: Integer;
begin
  CountStart := RecordFldCntStart;
  Index := CountStart^;
  Cursor := Pointer(PByte(CountStart) + SizeOf(Integer));

  while Index > 0 do
  begin
    Cursor := Cursor.Tail;
    Dec(Index);
  end;

  Result := Pointer(Cursor);
end;

function TTypeData.RecordCollectFields;
var
  CountStart: PInteger;
  Cursor: PRecordTypeField;
  i: Integer;
begin
  CountStart := RecordFldCntStart;
  SetLength(Result, CountStart^);
  Cursor := RecordFieldsStart(0);

  for i := 0 to High(Result) do
  begin
    Result[i] := Cursor;
    Cursor := Cursor.Tail;
  end;
end;

function TTypeData.RecordCollectManagedFields;
var
  Cursor: PManagedField;
  i: Integer;
begin
  SetLength(Result, RecordManagedFldCount);
  Cursor := RecordManagedFieldsStart(0);

  for i := 0 to High(Result) do
  begin
    Result[i] := Cursor;
    Cursor := Cursor.Tail;
  end;
end;

function TTypeData.RecordCollectMethods;
var
  CountStart: PWord;
  Cursor: PRecordTypeMethod;
  i: Integer;
begin
  CountStart := RecordMethCntStart;
  SetLength(Result, CountStart^);
  Cursor := RecordMethsStart(0);

  for i := 0 to High(Result) do
  begin
    Result[i] := Cursor;
    Cursor := Cursor.Tail;
  end;
end;

function TTypeData.RecordCollectOps;
var
  CountStart: PByte;
  Cursor: PPointer;
  i: Integer;
begin
  CountStart := RecordNumOpsStart;
  SetLength(Result, CountStart^);
  Cursor := RecordOpsStart(0);

  for i := 0 to High(Result) do
  begin
    Result[i] := Cursor;
    Inc(Cursor);
  end;
end;

function TTypeData.RecordFieldsStart;
begin
  Result := Pointer(PByte(RecordFldCntStart) + SizeOf(Integer));

  while Index > 0 do
  begin
    Result := Result.Tail;
    Dec(Index);
  end;
end;

function TTypeData.RecordFldCntStart;
begin
  Result := Pointer(PByte(RecordNumOpsStart) + SizeOf(Byte) +
    RecordNumOpsStart^ * SizeOF(Pointer));
end;

function TTypeData.RecordManagedFieldsStart;
begin
  Result := Pointer(PByte(@RecordManagedFldCount) + SizeOf(Integer));

  while Index > 0 do
  begin
    Result := Result.Tail;
    Dec(Index);
  end;
end;

function TTypeData.RecordMethCntStart;
begin
  Result := RecordAttrDataStart.Tail;
end;

function TTypeData.RecordMethsStart;
begin
  Result := Pointer(PByte(RecordMethCntStart) + SizeOf(Word));

  while Index > 0 do
  begin
    Result := Result.Tail;
    Dec(Index);
  end;
end;

function TTypeData.RecordNumOpsStart;
begin
  Result := Pointer(RecordManagedFieldsStart(RecordManagedFldCount));
end;

function TTypeData.RecordOpsStart;
begin
  Result := Pointer(PByte(RecordNumOpsStart) + SizeOf(Byte) + Index *
    SizeOF(Pointer));
end;

function TTypeData.SetLoByteStart;
begin
  Result := SetAttrData.Tail;
end;

function TTypeData.SetSizeStart;
begin
  Result := SetLoByteStart + SizeOf(Byte);
end;

end.
