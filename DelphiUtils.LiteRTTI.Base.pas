unit DelphiUtils.LiteRTTI.Base;

{
  This module provides lightweight RTTI wrappers for parsing compiler-generated
  type information.
}

interface

uses
  DelphiApi.TypInfo;

type
  PLiteRttiTypeInfo = ^TLiteRttiTypeInfo;
  PLiteRttiAttribute = ^TLiteRttiAttribute;
  PLiteRttiInterfaceMethod = ^TLiteRttiInterfaceMethod;
  PLiteRttiInterfaceMethodParameter = ^TLiteRttiInterfaceMethodParameter;
  PLiteRttiProperty = ^TLiteRttiProperty;
  PLiteRttiPropertyEx = ^TLiteRttiPropertyEx;
  PLiteRttiArrayProperty = ^TLiteRttiArrayProperty;
  PLiteRttiProcedureSignature = ^TLiteRttiProcedureSignature;
  PLiteRttiProcedureParameter = ^TLiteRttiProcedureParameter;
  PLiteRttiManagedField = ^TLiteRttiManagedField;
  PLiteRttiField = ^TLiteRttiField;
  PLiteRttiRecordMethod = ^TLiteRttiRecordMethod;
  PLiteRttiMethodParameter = ^TLiteRttiMethodParameter;

  TLiteRttiTypeInfo = record
  private
    function TypeInfo: PTypeInfo;
    function AttrDataStart: PAttrData;
  public
    class function FromTypeInfoRef(Source: PPTypeInfo): PLiteRttiTypeInfo; static;
    type RelatedType = PTypeInfo;

    // All types
    function Kind: TTypeKind;
    function Name: String;
    function NameEquals(const Value: String): Boolean;
    function Attributes: TArray<PLiteRttiAttribute>;

    // tkInteger, tkChar, tkEnumeration, tkWChar, tkClass, tkInterface, tkDynArray
    function SupportsUnitName: Boolean;
    function UnitName: String;

    // tkInteger, tkChar, tkEnumeration, tkWChar
    function IsOrdinal: Boolean;
    function OrdinalType: TOrdType;
    function OrdinalMinValue: Integer;
    function OrdinalMaxValue: Integer;

    // tkEnumeration
    function EnumerationIsBoolean: Boolean;
    function EnumerationBaseType: PLiteRttiTypeInfo;
    function EnumerationHasNames: Boolean;
    function EnumerationNames: TArray<String>;
    function EnumerationName(Value: Integer): String;

    // tkSet
    function SetSize: Byte;
    function SetElementType: PLiteRttiTypeInfo;
    function SetLoByte: Byte;

    // tkFloat
    function FloatType: TFloatType;

    // tkInt64
    function Int64MinValue: Int64;
    function Int64MaxValue: Int64;

    // tkLString
    function AnsiStringCodePage: Word;

    // tkString
    function ShortStringMaxLength: Byte;

    // tkInterface
    function InterfaceParent: PLiteRttiTypeInfo;
    function InterfaceFlags: TIntfFlags;
    function InterfaceGuid : TGuid;
    function InterfaceMethodCount: Word;
    function InterfaceMethodRttiCount: Word;
    function InterfaceMethods: TArray<PLiteRttiInterfaceMethod>;

    // tkRecord
    function RecordSize: Integer;
    function RecordMangedFieldCount: Integer;
    function RecordMangedFields: TArray<PLiteRttiManagedField>;
    function RecordOpsCount: Byte;
    function RecordOps: TArray<Pointer>;
    function RecordFieldCount: Integer;
    function RecordFields: TArray<PLiteRttiField>;
    function RecordMethodCount: Word;
    function RecordMethods: TArray<PLiteRttiRecordMethod>;

    // tkClass
    function ClassType: TClass;
    function ClassParentType: PLiteRttiTypeInfo;
    function ClassTotalPropertiesCount: SmallInt;
    function ClassPropertyCount: Word;
    function ClassProperties: TArray<PLiteRttiProperty>;
    function ClassPropertyExCount: Word;
    function ClassPropertiesEx: TArray<PLiteRttiPropertyEx>;
    function ClassArrayPropertyCount: Word;
    function ClassArrayProperties: TArray<PLiteRttiArrayProperty>;

    // tkClassRef
    function ClassRefInstanceType: PLiteRttiTypeInfo;

    // tkPointer
    function PointerRefType: PLiteRttiTypeInfo;

    // tkProcedure
    function ProcSignature: PLiteRttiProcedureSignature;

    // tkMethod
    function MethodKind: TMethodKind;
    function MethodParameterCount: Byte;
    function MethodParameters: TArray<PLiteRttiMethodParameter>;
    function MethodResultTypeName: String;
    function MethodResultTypeRef: PLiteRttiTypeInfo;
    function MethodCallingConvention: TCallConv;
    function MethodParamTypeRefs: TArray<PLiteRttiTypeInfo>;
    function MethodSignature: PLiteRttiProcedureSignature;

    // tkDynArray
    function DynArrayElementSize: Integer;
    function DynArrayCleanupType: PLiteRttiTypeInfo;
    function DynArrayNestedElementType: PLiteRttiTypeInfo;
    function DynArrayActualElementType: PLiteRttiTypeInfo;

    // tkArray
    function ArraySize: Integer;
    function ArrayElementCount: Integer;
    function ArrayElementType: PLiteRttiTypeInfo;
    function ArrayDimentionCount: Byte;
    function ArrayDimention(Index: Integer): PLiteRttiTypeInfo;
    function ArrayDimentions: TArray<PLiteRttiTypeInfo>;
  end;

  TLiteRttiAttribute = record
  private
    function EntryStart: PAttrEntry;
    class function Collect(AttrData: PAttrData): TArray<PLiteRttiAttribute>; static;
  public
    type RelatedType = PAttrEntry;
    function AttrubuteType: PLiteRttiTypeInfo;
    function AttributeConstructor: Pointer;
    function ArgumentsLength: Word;
    function Arguments: Pointer;
  end;

  TLiteRttiInterfaceMethod = record
  private
    function Start: PIntfMethodEntry;
  public
    type RelatedType = PIntfMethodEntry;
    function Name: String;
    function Kind: TMethodKind;
    function CallingConvention: TCallConv;
    function ParameterCount: Byte;
    function Parameter(Index: Integer): PLiteRttiInterfaceMethodParameter;
    function Parameters: TArray<PLiteRttiInterfaceMethodParameter>;
    function ResultTypeName: String;
    function ResultType: PLiteRttiTypeInfo;
    function Attributes: TArray<PLiteRttiAttribute>;
  end;

  TLiteRttiInterfaceMethodParameter = record
  private
    function Start: PIntfMethodParam;
  public
    type RelatedType = PIntfMethodParam;
    function Flags: TParamFlags;
    function Name: String;
    function TypeName: String;
    function TypeInfo: PLiteRttiTypeInfo;
    function Attributes: TArray<PLiteRttiAttribute>;
  end;

  TLiteRttiProperty = record
  private
    function Start: PPropInfo;
  public
    type RelatedType = PPropInfo;
    function PropType: PLiteRttiTypeInfo;
    function GetProc: NativeUInt;
    function SetProc: NativeUInt;
    function StoredProc: NativeUInt;
    function Index: Integer;
    function Default: Integer;
    function NameIndex: SmallInt;
    function Name: String;
  end;

  TLiteRttiPropertyEx = record
  private
    function Start: PPropInfoEx;
  public
    type RelatedType = PPropInfoEx;
    function Visibility: TMemberVisibility;
    function Info: PLiteRttiProperty;
    function Attributes: TArray<PLiteRttiAttribute>;
  end;

  TLiteRttiArrayProperty = record
  private
    function Start: PArrayPropInfo;
  public
    type RelatedType = PArrayPropInfo;
    function Flags: Byte;
    function ReadIndex: Word;
    function WriteIndex: Word;
    function Name: String;
    function Attributes: TArray<PLiteRttiAttribute>;
  end;

  TLiteRttiProcedureSignature = record
  private
    function Start: PProcedureSignature;
  public
    type RelatedType = PProcedureSignature;
    function CallingConvention: TCallConv;
    function ResultType: PLiteRttiTypeInfo;
    function ParameterCount: Byte;
    function Parameters: TArray<PLiteRttiProcedureParameter>;
  end;

  TLiteRttiProcedureParameter = record
  private
    function Start: PProcedureParam;
  public
    type RelatedType = PProcedureParam;
    function Flags: TParamFlags;
    function ParamType: PLiteRttiTypeInfo;
    function Name: String;
    function Attributes: TArray<PLiteRttiAttribute>;
  end;

  TLiteRttiManagedField = record
  private
    function Start: PManagedField;
  public
    type RelatedType = PManagedField;
    function TypeRef: PLiteRttiTypeInfo;
    function FldOffset: NativeInt;
  end;

  TLiteRttiField = record
  private
    function Start: PRecordTypeField;
  public
    type RelatedType = PRecordTypeField;
    function Field: PLiteRttiManagedField;
    function Flags: Byte;
    function Name: String;
    function Attributes: TArray<PLiteRttiAttribute>;
  end;

  TLiteRttiRecordMethod = record
  private
    function Start: PRecordTypeMethod;
  public
    type RelatedType = PRecordTypeMethod;
    function Flags: Byte;
    function Code: Pointer;
    function Name: String;
    function Signature: PLiteRttiProcedureSignature;
    function Attributes: TArray<PLiteRttiAttribute>;
  end;

  TLiteRttiMethodParameter = record
  private
    function Start: PMethodParam;
  public
    type RelatedType = PMethodParam;
    function Flags: TParamFlags;
    function ParamName: String;
    function TypeName: String;
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TLiteRttiTypeInfo }

function TLiteRttiTypeInfo.AnsiStringCodePage;
begin
  if Kind <> tkLString then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.LStringCodePage;
end;

function TLiteRttiTypeInfo.ArrayDimention;
var
  ArrayTypeData: PArrayTypeData;
begin
  if Kind <> tkArray then
    Error(reAssertionFailed);

  ArrayTypeData := @TypeInfo.TypeDataStart.ArrayData;

  if (Index >= 0) and (Index < ArrayTypeData.DimCount) then
    Result := FromTypeInfoRef(ArrayTypeData.Dims[Index])
  else
    Result := nil;
end;

function TLiteRttiTypeInfo.ArrayDimentionCount;
begin
  if Kind <> tkArray then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.ArrayData.DimCount;
end;

function TLiteRttiTypeInfo.ArrayDimentions;
var
  ResultRaw: TArray<TLiteRttiTypeInfo.RelatedType> absolute Result;
begin
  if Kind <> tkArray then
    Error(reAssertionFailed);

  ResultRaw := TypeInfo.TypeDataStart.ArrayData.CollectDims;
end;

function TLiteRttiTypeInfo.ArrayElementCount;
begin
  if Kind <> tkArray then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.ArrayData.ElCount;
end;

function TLiteRttiTypeInfo.ArrayElementType;
begin
  if Kind <> tkArray then
    Error(reAssertionFailed);

  Result := FromTypeInfoRef(TypeInfo.TypeDataStart.ArrayData.ElType);
end;

function TLiteRttiTypeInfo.ArraySize;
begin
  if Kind <> tkArray then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.ArrayData.Size;
end;

function TLiteRttiTypeInfo.AttrDataStart;
begin
  case Kind of
    tkUString, tkWString, tkVariant:
      Result := @TypeInfo.TypeDataStart.UStringAttrData;
    tkLString:
      Result := @TypeInfo.TypeDataStart.LStringAttrData;
    tkString:
      Result := @TypeInfo.TypeDataStart.SStringAttrData;
    tkEnumeration:
      Result := TypeInfo.TypeDataStart.EnumAttrDataStart;
    tkInteger, tkChar, tkWChar:
      Result := TypeInfo.TypeDataStart.OrdinalNonEnumAttrDataStart;
    tkSet:
      Result := @TypeInfo.TypeDataStart.SetAttrData;
    tkFloat:
      Result := @TypeInfo.TypeDataStart.FloatAttrData;
    tkClass:
      Result := TypeInfo.TypeDataStart.ClassAttrDataStart;
    tkMethod:
      Result := TypeInfo.TypeDataStart.MethodAttrDataStart;
    tkProcedure:
      Result := @TypeInfo.TypeDataStart.ProcAttrData;
    tkInterface:
      Result := TypeInfo.TypeDataStart.IntfAttrDataStart;
    tkInt64:
      Result := @TypeInfo.TypeDataStart.Int64AttrData;
    tkDynArray:
      Result := TypeInfo.TypeDataStart.DynArrayAttrDataStart;
    tkRecord:
      Result := TypeInfo.TypeDataStart.RecordAttrDataStart;
    tkClassRef:
      Result := @TypeInfo.TypeDataStart.ClassRefAttrData;
    tkPointer:
      Result := @TypeInfo.TypeDataStart.PtrAttrData;
    tkArray:
      Result := TypeInfo.TypeDataStart.ArrayAttrDataStart;
  else
    Result := nil;
  end;
end;

function TLiteRttiTypeInfo.Attributes;
begin
  Result := TLiteRttiAttribute.Collect(AttrDataStart);
end;

function TLiteRttiTypeInfo.ClassArrayProperties;
var
  ResultRaw: TArray<TLiteRttiArrayProperty.RelatedType> absolute Result;
begin
  if Kind <> tkClass then
    Error(reAssertionFailed);

  ResultRaw := TypeInfo.TypeDataStart.ClassCollectArrayProps;
end;

function TLiteRttiTypeInfo.ClassArrayPropertyCount;
begin
  if Kind <> tkClass then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.ClassArrayPropCountStart^;
end;

function TLiteRttiTypeInfo.ClassParentType;
begin
  if Kind <> tkClass then
    Error(reAssertionFailed);

  Result := FromTypeInfoRef(TypeInfo.TypeDataStart.ClassParentInfo);
end;

function TLiteRttiTypeInfo.ClassProperties;
var
  ResultRaw: TArray<TLiteRttiProperty.RelatedType> absolute Result;
begin
  if Kind <> tkClass then
    Error(reAssertionFailed);

  ResultRaw := TypeInfo.TypeDataStart.ClassPropDataStart.CollectProps;
end;

function TLiteRttiTypeInfo.ClassPropertiesEx;
var
  ResultRaw: TArray<TLiteRttiPropertyEx.RelatedType> absolute Result;
begin
  if Kind <> tkClass then
    Error(reAssertionFailed);

  ResultRaw := TypeInfo.TypeDataStart.ClassPropDataExStart.CollectProps;
end;

function TLiteRttiTypeInfo.ClassPropertyCount;
begin
  if Kind <> tkClass then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.ClassPropDataStart.PropCount;
end;

function TLiteRttiTypeInfo.ClassPropertyExCount;
begin
  if Kind <> tkClass then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.ClassPropDataExStart.PropCount;
end;

function TLiteRttiTypeInfo.ClassRefInstanceType;
begin
  if Kind <> tkClassRef then
    Error(reAssertionFailed);

  Result := FromTypeInfoRef(TypeInfo.TypeDataStart.ClassRefInstanceType);
end;

function TLiteRttiTypeInfo.ClassTotalPropertiesCount;
begin
  if Kind <> tkClass then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.ClassPropCount;
end;

function TLiteRttiTypeInfo.ClassType;
begin
  if Kind <> tkClass then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.ClassType;
end;

function TLiteRttiTypeInfo.DynArrayActualElementType;
begin
  if Kind <> tkDynArray then
    Error(reAssertionFailed);

  Result := FromTypeInfoRef(TypeInfo.TypeDataStart.DynArrayElType3Start^);
end;

function TLiteRttiTypeInfo.DynArrayCleanupType;
begin
  if Kind <> tkDynArray then
    Error(reAssertionFailed);

  Result := FromTypeInfoRef(TypeInfo.TypeDataStart.DynArrayElType);
end;

function TLiteRttiTypeInfo.DynArrayElementSize;
begin
  if Kind <> tkDynArray then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.DynArrayElSize;
end;

function TLiteRttiTypeInfo.DynArrayNestedElementType;
begin
  if Kind <> tkDynArray then
    Error(reAssertionFailed);

  Result := FromTypeInfoRef(TypeInfo.TypeDataStart.DynArrayElType2);
end;

function TLiteRttiTypeInfo.EnumerationBaseType;
begin
  if Kind <> tkEnumeration then
    Error(reAssertionFailed);

  Result := FromTypeInfoRef(TypeInfo.TypeDataStart.EnumBaseType);
end;

function TLiteRttiTypeInfo.EnumerationHasNames;
begin
  if Kind <> tkEnumeration then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.EnumHasNameList;
end;

function TLiteRttiTypeInfo.EnumerationIsBoolean;
begin
  if Kind <> tkEnumeration then
    Error(reAssertionFailed);

  Result := IsBoolType(TypeInfo.TypeDataStart);
end;

function TLiteRttiTypeInfo.EnumerationName;
begin
  if Kind <> tkEnumeration then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.EnumName(Value)
end;

function TLiteRttiTypeInfo.EnumerationNames;
begin
  if Kind <> tkEnumeration then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.EnumCollectNames;
end;

function TLiteRttiTypeInfo.FloatType;
begin
  if Kind <> tkFloat then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.FloatType;
end;

class function TLiteRttiTypeInfo.FromTypeInfoRef;
begin
  if Assigned(Source) then
    PTypeInfo(Result) := Source^
  else
    Result := nil;
end;

function TLiteRttiTypeInfo.Int64MaxValue;
begin
  if Kind <> tkInt64 then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.Int64MaxValue;
end;

function TLiteRttiTypeInfo.Int64MinValue;
begin
  if Kind <> tkInt64 then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.Int64MinValue;
end;

function TLiteRttiTypeInfo.InterfaceFlags;
begin
  if Kind <> tkInterface then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.IntfFlags;
end;

function TLiteRttiTypeInfo.InterfaceGuid;
begin
  if Kind <> tkInterface then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.IntfGuid;
end;

function TLiteRttiTypeInfo.InterfaceMethodCount;
begin
  if Kind <> tkInterface then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.IntfMethodsStart.Count;
end;

function TLiteRttiTypeInfo.InterfaceMethodRttiCount;
begin
  if Kind <> tkInterface then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.IntfMethodsStart.RttiCount;
end;

function TLiteRttiTypeInfo.InterfaceMethods;
var
  ResultRaw: TArray<TLiteRttiInterfaceMethod.RelatedType> absolute Result;
begin
  if Kind <> tkInterface then
    Error(reAssertionFailed);

  ResultRaw := TypeInfo.TypeDataStart.IntfMethodsStart.CollectEntries;
end;

function TLiteRttiTypeInfo.InterfaceParent;
begin
  if Kind <> tkInterface then
    Error(reAssertionFailed);

  Result := FromTypeInfoRef(TypeInfo.TypeDataStart.IntfParent);
end;

function TLiteRttiTypeInfo.IsOrdinal;
begin
  Result := Kind in [tkInteger, tkChar, tkEnumeration, tkWChar];
end;

function TLiteRttiTypeInfo.Kind;
begin
  Result := TypeInfo.Kind;
end;

function TLiteRttiTypeInfo.MethodCallingConvention;
begin
  if Kind <> tkMethod then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.MethodCCStart^;
end;

function TLiteRttiTypeInfo.MethodKind;
begin
  if Kind <> tkMethod then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.MethodKind;
end;

function TLiteRttiTypeInfo.MethodParameterCount;
begin
  if Kind <> tkMethod then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.MethodParamCount;
end;

function TLiteRttiTypeInfo.MethodParameters;
var
  ResultRaw: TArray<TLiteRttiMethodParameter.RelatedType> absolute Result;
begin
  if Kind <> tkMethod then
    Error(reAssertionFailed);

  ResultRaw := TypeInfo.TypeDataStart.MethodCollectParams
end;

function TLiteRttiTypeInfo.MethodParamTypeRefs;
var
  ResultRaw: TArray<TLiteRttiTypeInfo.RelatedType> absolute Result;
begin
  if Kind <> tkMethod then
    Error(reAssertionFailed);

  ResultRaw := TypeInfo.TypeDataStart.MethodCollectParamTypeRefs;
end;

function TLiteRttiTypeInfo.MethodResultTypeName;
var
  Name: PShortString;
begin
  if Kind <> tkMethod then
    Error(reAssertionFailed);

  Name := TypeInfo.TypeDataStart.MethodResultTypeStart;

  if Assigned(Name) then
    Result := UTF8IdentToString(Name)
  else
    Result := '';
end;

function TLiteRttiTypeInfo.MethodResultTypeRef;
var
  RefStart: PPPTypeInfo;
begin
  if Kind <> tkMethod then
    Error(reAssertionFailed);

  RefStart := TypeInfo.TypeDataStart.MethodResultTypeRefStart;

  if Assigned(RefStart) then
    Result := FromTypeInfoRef(RefStart^)
  else
    Result := nil;
end;

function TLiteRttiTypeInfo.MethodSignature;
var
  Sig: PProcedureSignature;
begin
  if Kind <> tkMethod then
    Error(reAssertionFailed);

  Sig := TypeInfo.TypeDataStart.MethodSignatureStart^;

  if Assigned(Sig) and (Sig.Flags <> $FF) then
    Result := Pointer(Sig)
  else
    Result := nil;
end;

function TLiteRttiTypeInfo.Name;
begin
  Result := UTF8IdentToString(@TypeInfo.Name);
end;

function TLiteRttiTypeInfo.NameEquals;
begin
  Result := UTF8IdentStringCompare(@TypeInfo.Name, Value);
end;

function TLiteRttiTypeInfo.OrdinalMaxValue;
begin
  if not IsOrdinal then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.OrdinalMaxValue;
end;

function TLiteRttiTypeInfo.OrdinalMinValue;
begin
  if not IsOrdinal then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.OrdinalMinValue;
end;

function TLiteRttiTypeInfo.OrdinalType;
begin
  if not IsOrdinal then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.OrdinalType;
end;

function TLiteRttiTypeInfo.PointerRefType;
begin
  if Kind <> tkPointer then
    Error(reAssertionFailed);

  Result := FromTypeInfoRef(TypeInfo.TypeDataStart.PtrRefType);
end;

function TLiteRttiTypeInfo.ProcSignature;
var
  Signature: PProcedureSignature;
begin
  if Kind <> tkProcedure then
    Error(reAssertionFailed);

  Signature := TypeInfo.TypeDataStart.ProcSig;

  if Assigned(Signature) and (Signature.Flags <> $FF) then
    Result := Pointer(Signature)
  else
    Result := nil;
end;

function TLiteRttiTypeInfo.RecordFieldCount;
begin
  if Kind <> tkRecord then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.RecordFldCntStart^;
end;

function TLiteRttiTypeInfo.RecordFields;
var
  ResultRaw: TArray<TLiteRttiField.RelatedType> absolute Result;
begin
  if Kind <> tkRecord then
    Error(reAssertionFailed);

  ResultRaw := TypeInfo.TypeDataStart.RecordCollectFields;
end;

function TLiteRttiTypeInfo.RecordMangedFieldCount;
begin
  if Kind <> tkRecord then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.RecordManagedFldCount;
end;

function TLiteRttiTypeInfo.RecordMangedFields;
var
  ResultRaw: TArray<TLiteRttiManagedField.RelatedType> absolute Result;
begin
  if Kind <> tkRecord then
    Error(reAssertionFailed);

  ResultRaw := TypeInfo.TypeDataStart.RecordCollectManagedFields;
end;

function TLiteRttiTypeInfo.RecordMethodCount;
begin
  if Kind <> tkRecord then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.RecordMethCntStart^;
end;

function TLiteRttiTypeInfo.RecordMethods;
var
  ResultRaw: TArray<TLiteRttiRecordMethod.RelatedType> absolute Result;
begin
  if Kind <> tkRecord then
    Error(reAssertionFailed);

  ResultRaw := TypeInfo.TypeDataStart.RecordCollectMethods;
end;

function TLiteRttiTypeInfo.RecordOps;
begin
  if Kind <> tkRecord then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.RecordCollectOps;
end;

function TLiteRttiTypeInfo.RecordOpsCount;
begin
  if Kind <> tkRecord then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.RecordNumOpsStart^;
end;

function TLiteRttiTypeInfo.RecordSize;
begin
  if Kind <> tkRecord then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.RecordSize;
end;

function TLiteRttiTypeInfo.SetElementType;
begin
  if Kind <> tkSet then
    Error(reAssertionFailed);

  Result := FromTypeInfoRef(TypeInfo.TypeDataStart.SetCompType);
end;

function TLiteRttiTypeInfo.SetLoByte;
begin
  if Kind <> tkSet then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.SetLoByteStart^;
end;

function TLiteRttiTypeInfo.SetSize;
const
  Sizes: array [TOrdType] of Byte = (1, 1, 2, 2, 4, 4);
var
  SetTypeOrSize: Byte;
begin
  if Kind <> tkSet then
    Error(reAssertionFailed);

  SetTypeOrSize := TypeInfo.TypeDataStart.SetTypeOrSize;

  if SetTypeOrSize and $80 <> 0 then
    Result := SetTypeOrSize and not $80
  else if SetTypeOrSize <= Byte(High(Sizes)) then
    Result := Sizes[TOrdType(SetTypeOrSize)]
  else
    Result := 0;
end;

function TLiteRttiTypeInfo.ShortStringMaxLength;
begin
  if Kind <> tkString then
    Error(reAssertionFailed);

  Result := TypeInfo.TypeDataStart.SStringMaxLength;
end;

function TLiteRttiTypeInfo.SupportsUnitName;
begin
  Result := Kind in [tkEnumeration, tkClass, tkInterface, tkDynArray];
end;

function TLiteRttiTypeInfo.TypeInfo;
begin
  Result := Pointer(@Self);
end;

function TLiteRttiTypeInfo.UnitName;
begin
  case Kind of
    tkEnumeration:
      Result := UTF8IdentToString(TypeInfo.TypeDataStart.EnumUnitNameStart);

    tkClass:
      Result := UTF8IdentToString(@TypeInfo.TypeDataStart.ClassUnitName);

    tkInterface:
      Result := UTF8IdentToString(@TypeInfo.TypeDataStart.IntfUnit);

    tkDynArray:
      Result := UTF8IdentToString(@TypeInfo.TypeDataStart.DynArrayUnitName);
  else
    Result := '';
  end;
end;

{ TLiteRttiAttribute }

function TLiteRttiAttribute.Arguments;
begin
  Result := @EntryStart.ArgData;
end;

function TLiteRttiAttribute.ArgumentsLength;
begin
  Result := EntryStart.ArgLen;
end;

function TLiteRttiAttribute.AttributeConstructor;
begin
  Result := EntryStart.AttrCtor;
end;

function TLiteRttiAttribute.AttrubuteType;
begin
  Result := TLiteRttiTypeInfo.FromTypeInfoRef(EntryStart.AttrType);
end;

class function TLiteRttiAttribute.Collect;
var
  ResultRaw: TArray<TLiteRttiAttribute.RelatedType> absolute Result;
begin
  if Assigned(AttrData) then
    ResultRaw := AttrData.CollectEntries
  else
    Result := nil;
end;

function TLiteRttiAttribute.EntryStart;
begin
  Result := Pointer(@Self);
end;

{ TLiteRttiInterfaceMethod }

function TLiteRttiInterfaceMethod.Attributes;
begin
  Result := TLiteRttiAttribute.Collect(Start.EntryTailStart.AttrDataStart)
end;

function TLiteRttiInterfaceMethod.CallingConvention;
begin
  Result := Start.EntryTailStart.CC;
end;

function TLiteRttiInterfaceMethod.Kind;
begin
  Result := Start.EntryTailStart.Kind;
end;

function TLiteRttiInterfaceMethod.Name;
begin
  Result := UTF8IdentToString(@Start.Name);
end;

function TLiteRttiInterfaceMethod.Parameter;
var
  EntryTail: PIntfMethodEntryTail;
begin
  EntryTail := Start.EntryTailStart;

  if (Index >= 0) and (Index < EntryTail.ParamCount) then
    Result := Pointer(EntryTail.ParamStart(Index))
  else
    Result := nil;
end;

function TLiteRttiInterfaceMethod.ParameterCount;
begin
  Result := Start.EntryTailStart.ParamCount;
end;

function TLiteRttiInterfaceMethod.Parameters;
var
  ResultRaw: TArray<TLiteRttiInterfaceMethodParameter.RelatedType> absolute Result;
begin
  ResultRaw := Start.EntryTailStart.CollectParams;
end;

function TLiteRttiInterfaceMethod.ResultType;
var
  ResultTypeStart: PPPTypeInfo;
begin
  ResultTypeStart := Start.EntryTailStart.ResultTypeStart;

  if Assigned(ResultTypeStart) then
    Result := TLiteRttiTypeInfo.FromTypeInfoRef(ResultTypeStart^)
  else
    Result := nil;
end;

function TLiteRttiInterfaceMethod.ResultTypeName;
var
  ResultTypeNameStart: PShortString;
begin
  ResultTypeNameStart := Start.EntryTailStart.ResultTypeNameStart;

  if Assigned(ResultTypeNameStart) then
    Result := UTF8IdentToString(ResultTypeNameStart)
  else
    Result := '';
end;

function TLiteRttiInterfaceMethod.Start;
begin
  Result := Pointer(@Self);
end;

{ TLiteRttiInterfaceMethodParameter }

function TLiteRttiInterfaceMethodParameter.Attributes;
begin
  Result := TLiteRttiAttribute.Collect(@Start.ParamTailStart.AttrData);
end;

function TLiteRttiInterfaceMethodParameter.Flags;
begin
  Result := Start.Flags;
end;

function TLiteRttiInterfaceMethodParameter.Name;
begin
  Result := UTF8IdentToString(@Start.ParamName);
end;

function TLiteRttiInterfaceMethodParameter.Start;
begin
  Result := Pointer(@Self);
end;

function TLiteRttiInterfaceMethodParameter.TypeInfo;
begin
  Result := TLiteRttiTypeInfo.FromTypeInfoRef(Start.ParamTailStart.ParamType);
end;

function TLiteRttiInterfaceMethodParameter.TypeName;
begin
  Result := UTF8IdentToString(Start.TypeNameStart);
end;

{ TLiteRttiProperty }

function TLiteRttiProperty.Default;
begin
  Result := Start.Default;
end;

function TLiteRttiProperty.GetProc;
begin
  Result := Start.GetProc;
end;

function TLiteRttiProperty.Index;
begin
  Result := Start.Index;
end;

function TLiteRttiProperty.Name;
begin
  Result := UTF8IdentToString(@Start.Name);
end;

function TLiteRttiProperty.NameIndex;
begin
  Result := Start.NameIndex;
end;

function TLiteRttiProperty.PropType;
begin
  Result := TLiteRttiTypeInfo.FromTypeInfoRef(Start.PropType);
end;

function TLiteRttiProperty.SetProc;
begin
  Result := Start.SetProc;
end;

function TLiteRttiProperty.Start;
begin
  Result := Pointer(@Self);
end;

function TLiteRttiProperty.StoredProc;
begin
  Result := Start.StoredProc;
end;

{ TLiteRttiPropertyEx }

function TLiteRttiPropertyEx.Attributes;
begin
  Result := TLiteRttiAttribute.Collect(@Start.AttrData);
end;

function TLiteRttiPropertyEx.Info;
begin
  Result := PLiteRttiProperty(Start.Info);
end;

function TLiteRttiPropertyEx.Start;
begin
  Result := Pointer(@Self);
end;

function TLiteRttiPropertyEx.Visibility;
begin
  Result := Start.Visibility;
end;

{ TLiteRttiArrayProperty }

function TLiteRttiArrayProperty.Attributes;
begin
  Result := TLiteRttiAttribute.Collect(Start.AttrDataStart);
end;

function TLiteRttiArrayProperty.Flags;
begin
  Result := Start.Flags;
end;

function TLiteRttiArrayProperty.Name;
begin
  Result := UTF8IdentToString(@Start.Name);
end;

function TLiteRttiArrayProperty.ReadIndex;
begin
  Result := Start.ReadIndex;
end;

function TLiteRttiArrayProperty.Start;
begin
  Result := Pointer(@Self);
end;

function TLiteRttiArrayProperty.WriteIndex;
begin
  Result := Start.WriteIndex;
end;

{ PLiteRttiProcedureSignature }

function TLiteRttiProcedureSignature.CallingConvention;
begin
  Result := Start.CC;
end;

function TLiteRttiProcedureSignature.ParameterCount;
begin
  Result := Start.ParamCount;
end;

function TLiteRttiProcedureSignature.Parameters;
var
  ResultRaw: TArray<TLiteRttiProcedureParameter.RelatedType> absolute Result;
begin
  ResultRaw := Start.CollectParams;
end;

function TLiteRttiProcedureSignature.ResultType;
begin
  Result := TLiteRttiTypeInfo.FromTypeInfoRef(Start.ResultType);
end;

function TLiteRttiProcedureSignature.Start;
begin
  Result := Pointer(@Self);
end;

{ TLiteRttiProcedureParameter }

function TLiteRttiProcedureParameter.Attributes;
begin
  Result := TLiteRttiAttribute.Collect(Start.AttrDataStart);
end;

function TLiteRttiProcedureParameter.Flags;
begin
  Result := Start.Flags;
end;

function TLiteRttiProcedureParameter.Name;
begin
  Result := UTF8IdentToString(@Start.Name);
end;

function TLiteRttiProcedureParameter.ParamType;
begin
  Result := TLiteRttiTypeInfo.FromTypeInfoRef(Start.ParamType);
end;

function TLiteRttiProcedureParameter.Start;
begin
  Result := Pointer(@Self);
end;

{ TLiteRttiManagedField }

function TLiteRttiManagedField.FldOffset;
begin
  Result := Start.FldOffset;
end;

function TLiteRttiManagedField.Start;
begin
  Result := Pointer(@Self);
end;

function TLiteRttiManagedField.TypeRef;
begin
  Result := TLiteRttiTypeInfo.FromTypeInfoRef(Start.TypeRef);
end;

{ TLiteRttiField }

function TLiteRttiField.Attributes;
begin
  Result := TLiteRttiAttribute.Collect(Start.AttrDataStart);
end;

function TLiteRttiField.Field;
begin
  Result := Pointer(@Start.Field);
end;

function TLiteRttiField.Flags;
begin
  Result := Start.Flags;
end;

function TLiteRttiField.Name;
begin
  Result := UTF8IdentToString(@Start.Name);
end;

function TLiteRttiField.Start;
begin
  Result := Pointer(@Self);
end;

{ TLiteRttiRecordMethod }

function TLiteRttiRecordMethod.Attributes;
begin
  Result := TLiteRttiAttribute.Collect(Start.AttrDataStart);
end;

function TLiteRttiRecordMethod.Code;
begin
  Result := Start.Code;
end;

function TLiteRttiRecordMethod.Flags;
begin
  Result := Start.Flags;
end;

function TLiteRttiRecordMethod.Name;
begin
  Result := UTF8IdentToString(@Start.Name);
end;

function TLiteRttiRecordMethod.Signature;
var
  Sig: PProcedureSignature;
begin
  Sig := Start.SigStartStart;

  if Sig.Flags <> $FF then
    Result := Pointer(Sig)
  else
    Result := nil;
end;

function TLiteRttiRecordMethod.Start;
begin
  Result := Pointer(@Self);
end;

{ TLiteRttiMethodParameter }

function TLiteRttiMethodParameter.Flags;
begin
  Result := Start.Flags;
end;

function TLiteRttiMethodParameter.ParamName;
begin
  Result := UTF8IdentToString(@Start.ParamName);
end;

function TLiteRttiMethodParameter.Start;
begin
  Result := Pointer(@Self);
end;

function TLiteRttiMethodParameter.TypeName;
begin
  Result := UTF8IdentToString(Start.TypeNameStart);
end;

end.
