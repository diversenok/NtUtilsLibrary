unit Ntapi.appmodel.mrm;

{
  This module provides definitions for reading package resource index (PRI)
  files.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ObjBase, Ntapi.ObjIdl, Ntapi.Versions,
  DelphiApi.Reflection, DelphiApi.DelayLoad;

const
  MrmCoreR = 'MrmCoreR.dll';

var
  delayed_MrmCoreR: TDelayedLoadDll = (DllName: MrmCoreR);

const
  // rev
  CLSID_MrtResourceManager: TClsid = '{DBCE7E40-7345-439D-B12C-114A11819A09}';
  CLSID_MrtResourceManagerQueue: TClsid = '{C60F637A-07F3-411D-B577-22E519F8B63B}';
  CLSID_MrtResourceValidator: TClsid = '{CE264EED-3CD3-4BC5-9774-D3A18BE9B0F2}';
  CLSID_MrtStringResolver: TClsid = '{ADE27590-4C84-4ABB-AE56-8233CC73D80F}';

  // private - resource validation options
  NAMED_RESOURCE_ALWAYS_YIELDS_RESULT = 1;
  MAP_COMPLETE = 101;
  MAP_ALL_RESOURCES_YIELD_RESULT = 102;
  PRI_FILE_BLOCK_AUTOMERGE_ENABLED = 201;
  PRI_FILE_VERSION_8_REQUIRED = 202;

type
  IUri = IUnknown; // TBD

  // private
  {$SCOPEDENUMS ON}
  [SDKName('RESOURCE_LAYOUT_DIRECTION')]
  TResourceLayoutDirection = (
    LTR = 0,
    RTL = 0,
    TTBLTR = 2,
    TTBRTL = 3
  );
  {$SCOPEDENUMS OFF}

  // private
  [SDKName('RESOURCE_SCALE')]
  [NamingStyle(nsSnakeCase, 'SCALE')]
  TResourceScale = (
    SCALE100_PERCENT = 0,
    SCALE140_PERCENT = 1,
    SCALE180_PERCENT = 2,
    SCALE80_PERCENT = 3,
    SCALE150_PERCENT = 4,
    SCALE160_PERCENT = 5,
    SCALE225_PERCENT = 6,
    SCALE120_PERCENT = 7,
    SCALE125_PERCENT = 8,
    SCALE200_PERCENT = 9,
    SCALE220_PERCENT = 10,
    SCALE240_PERCENT = 11,
    SCALE250_PERCENT = 12,
    SCALE300_PERCENT = 13,
    SCALE400_PERCENT = 14,
    SCALE500_PERCENT = 15
  );

  // private
  {$SCOPEDENUMS ON}
  [SDKName('RESOURCE_CONTRAST')]
  TResourceContrast = (
    STANDARD = 0,
    HIGH = 1,
    BLACK_BACKGROUND = 2,
    WHITE_BACKGROUND = 3
  );
  {$SCOPEDENUMS OFF}

  // private
  [SDKName('RESOURCE_QUALIFIER')]
  TResourceQualifier = record
    [ReleaseWith('CoTaskMemFree')] QualifierName: PWideChar;
    [ReleaseWith('CoTaskMemFree')] QualifierValue: PWideChar;
    IsDefault: LongBool;
    Priority: Cardinal;
    MatchedScore: Double;
    DefaultScore: Double;
  end;
  PResourceQualifier = ^TResourceQualifier;

  // private
  [MinOSVersion(OsWin8)]
  IResourceCandidate = interface  (IUnknown)
    ['{F98CE1CB-901B-41F4-BF42-83D51895E1E2}']

    function ToString(
      [out, ReleaseWith('CoTaskMemFree')] out Value: PWideChar
    ): HResult; stdcall;

    function ToFilePath(
      [out, ReleaseWith('CoTaskMemFree')] out Value: PWideChar
    ): HResult; stdcall;

    function GetType(
      [out, ReleaseWith('CoTaskMemFree')] out InstanceType: PWideChar
    ): HResult; stdcall;

    function GetQualifierCount(
      [out] out Count: Cardinal
    ): HResult; stdcall;

    function GetQualifier(
      [in] Index: Integer;
      [out] out ResourceQualifier: TResourceQualifier
    ): HResult; stdcall;

    function GetQualifierValue(
      [in] Attribute: PWideChar;
      [out, ReleaseWith('CoTaskMemFree')] out AttributeValue: PWideChar
    ): HResult; stdcall;

    function IsDefault(
      [out] out IsDefault: LongBool
    ): HResult; stdcall;

    function IsMatchAsDefault(
      [out] out IsMatchDefault: LongBool
    ): HResult; stdcall;

    function IsMatch(
      [out] out IsMatch: LongBool
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin81)]
  IResourceCandidate2 = interface (IUnknown)
    ['{8C09FA9C-1846-4E32-B36C-93E2B94395CF}']

    function ToStream(
      [out] out ResourceCandidateStream: IStream
    ): HResult; stdcall;

    function GetOrigin(
      [out, ReleaseWith('CoTaskMemFree')] out OriginOut: PWideChar
    ): HResult; stdcall;

    function GetQuery(
      [out, ReleaseWith('CoTaskMemFree')] out QueryOut: PWideChar
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin8)]
  IResourceCandidateCollection = interface (IUnknown)
    ['{5EC76092-DC01-4023-94F5-2000564D2C47}']

    function GetCount(
      [out] out Count: Cardinal
    ): HResult; stdcall;

    function GetCandidate(
      [in] Index: Integer;
      [out] out ResourceCandidate: IResourceCandidate
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin8)]
  IResourceContext = interface (IUnknown)
    ['{E3C22B30-8502-4B2F-9133-559674587E51}']

    function GetLanguage(
      [out, ReleaseWith('CoTaskMemFree')] out Language: PWideChar
    ): HResult; stdcall;

    function GetHomeRegion(
      [out, ReleaseWith('CoTaskMemFree')] out HomeRegion: PWideChar
    ): HResult; stdcall;

    function GetLayoutDirection(
      [out] out LayoutDirection: TResourceLayoutDirection
    ): HResult; stdcall;

    function GetTargetSize(
      [out] out TargetSize: Word
    ): HResult; stdcall;

    function GetScale(
      [out] out Scale: TResourceScale
    ): HResult; stdcall;

    function GetContrast(
      [out] out Contrast: TResourceContrast
    ): HResult; stdcall;

    function GetAlternateForm(
      [out, ReleaseWith('CoTaskMemFree')] out AlternateForm: PWideChar
    ): HResult; stdcall;

    function GetQualifierValue(
      [in] Attribute: PWideChar;
      [out, ReleaseWith('CoTaskMemFree')] out AttributeValue: PWideChar
    ): HResult; stdcall;

    function SetLanguage(
      [in] Language: PWideChar
    ): HResult; stdcall;

    function SetHomeRegion(
      [in] HomeRegion: PWideChar
    ): HResult; stdcall;

    function SetLayoutDirection(
      [in] LayoutDirection: TResourceLayoutDirection
    ): HResult; stdcall;

    function SetTargetSize(
      [in] TargetSize: Word
    ): HResult; stdcall;

    function SetScale(
      [in] Scale: TResourceScale
    ): HResult; stdcall;

    function SetContrast(
      [in] Contrast: TResourceContrast
    ): HResult; stdcall;

    function SetAlternateForm(
      [in] AlternateForm: PWideChar
    ): HResult; stdcall;

    function SetQualifierValue(
      [in] Attribute: PWideChar;
      [in] QualifierValue: PWideChar
    ): HResult; stdcall;

    function TrySetQualifierValue(
      [in] Attribute: PWideChar;
      [in] QualifierValue: PWideChar;
      [out] out Result: LongBool
    ): HResult; stdcall;

    function Reset(
    ): HResult; stdcall;

    function ResetQualifierValue(
      [in] QualifierName: PWideChar
    ): HResult; stdcall;

    function Clone(
      [out] out ResourceContext: IResourceContext
    ): HResult; stdcall;

    function OverrideToMatch(
      [in] ResourceCandidate: IResourceCandidate
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin81)]
  IResourceContext2 = interface (IUnknown)
    ['{50C5BEA6-0BF1-4829-9945-920C64F27EB5}']

    function IsSystemComponentProfile(
      [out] out SystemComponent: LongBool
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin10TH1)]
  IResourceContext3 = interface (IUnknown)
    ['{998CAE81-2106-4253-9C01-1C0DB7B69F84}']
    function GetIntegerScale(
      [out] out ScaleOut: Integer
    ): HResult; stdcall;

    function SetIntegerScale(
      [in] Scale: Integer
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin8)]
  INamedResource = interface (IUnknown)
    ['{C2AC6F97-54F2-445A-8F62-D87B9537F9B2}']

    function GetUri(
      [out, ReleaseWith('CoTaskMemFree')] out Name: PWideChar
    ): HResult; stdcall;

    function GetCandidateCount(
      [out] out Value: Cardinal
    ): HResult; stdcall;

    function GetCandidate(
      [in] Index: Integer;
      [out] out ResourceCandidate: IResourceCandidate
    ): HResult; stdcall;

    function Resolve(
      [out] out ResourceCandidate: IResourceCandidate
    ): HResult; stdcall;

    function ResolveForContext(
      [in] ResourceContext: IResourceContext;
      [out] out ResourceCandidate: IResourceCandidate
    ): HResult; stdcall;

    function ResolveAll(
      [out] out ResourceCandidateCollection: IResourceCandidateCollection
    ): HResult; stdcall;

    function ResolveAllForContext(
      [in] ResourceContext: IResourceContext;
      [out] out ResourceCandidateCollection: IResourceCandidateCollection
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin8)]
  IResourceMap = interface (IUnknown)
    ['{6E21E72B-B9B0-42AE-A686-983CF784EDCD}']

    function GetUri(
      [out, ReleaseWith('CoTaskMemFree')] out Name: PWideChar
    ): HResult; stdcall;

    function GetSubtree(
      [in] ScopeName: PWideChar;
      [out] out ResourceMap: IResourceMap
    ): HResult; stdcall;

    function GetString(
      [in] Id: PWideChar;
      [out, ReleaseWith('CoTaskMemFree')] out pszString: PWideChar
    ): HResult; stdcall;

    function GetStringForContext(
      [in] ResourceContext: IResourceContext;
      [in] Id: PWideChar;
      [out, ReleaseWith('CoTaskMemFree')] out pszString: PWideChar
    ): HResult; stdcall;

    function GetFilePath(
      [in] Id: PWideChar;
      [out, ReleaseWith('CoTaskMemFree')] out pszString: PWideChar
    ): HResult; stdcall;

    function GetFilePathForContext(
      [in] ResourceContext: IResourceContext;
      [in] Id: PWideChar;
      [out, ReleaseWith('CoTaskMemFree')] out pszString: PWideChar
    ): HResult; stdcall;

    function GetNamedResourceCount(
      [out] out Count: Cardinal
    ): HResult; stdcall;

    function GetNamedResourceUri(
      [in] Index: Integer;
      [out, ReleaseWith('CoTaskMemFree')] out ResourceName: PWideChar
    ): HResult; stdcall;

    function GetNamedResource(
      [in] Id: PWideChar;
      [in] const IID: TIid;
      [out] out NamedResource
    ): HResult; stdcall;

    function GetFullyQualifiedReference(
      [in] Reference: PWideChar;
      [in] PackageFullName: PWideChar;
      [out, ReleaseWith('CoTaskMemFree')] out Value: PWideChar
    ): HResult; stdcall;

    function GetFilePathByUri(
      [in] Id: IUri;
      [out, ReleaseWith('CoTaskMemFree')] out pszString: PWideChar
    ): HResult; stdcall;

    function GetFilePathForContextByUri(
      [in] ResourceContext: IResourceContext;
      [in] Id: IUri;
      [out, ReleaseWith('CoTaskMemFree')] out pszString: PWideChar
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin81)]
  IResourceMap2 = interface (IUnknown)
    ['{2FE6EC6E-DA7E-4B2A-A8F9-90B289061F20}']

    function GetStream(
      [in] Id: PWideChar;
      [out] out Stream: IStream
    ): HResult; stdcall;

    function GetStreamForContext(
      [in] ResourceContext: IResourceContext;
      [in] Id: PWideChar;
      [out] out Stream: IStream
    ): HResult; stdcall;

    function GetCandidateWithQuery(
      [in] KeyName: PWideChar;
      [out] out ResourceCandidate2: IResourceCandidate2
    ): HResult; stdcall;

    function GetCandidateForContext(
      [in] ResourceContext: IResourceContext;
      [in] KeyName: PWideChar;
      [out] out ResourceCandidate2: IResourceCandidate2
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin10TH1)]
  IResourceMap3 = interface (IUnknown)
    ['{CD192776-F66C-42D8-A549-2C5AE0F3A348}']

    function GetStringByIndex(
      [in] Index: Integer;
      [out, ReleaseWith('CoTaskMemFree')] out AString: PWideChar
    ): HResult; stdcall;

    function GetNamedResourceByIndex(
      [in] Index: Integer;
      [in] const IID: TIid;
      [out] out NamedResource
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin8)]
  IResourceReferenceHandler = interface (IUnknown)
    ['{BFF55471-5BC4-4A95-A700-38BFA4B897EF}']

    function GetString(
      [in] Id: PWideChar;
      [out, ReleaseWith('CoTaskMemFree')] out pszString;
      [out] out Found: LongBool
    ): HResult; stdcall;

    function GetStringForContext(
      [in] const ResourceContext: IResourceContext;
      [in] Id: PWideChar;
      [out, ReleaseWith('CoTaskMemFree')] out pszString;
      [out] out Found: LongBool
    ): HResult; stdcall;

    function GetNamedResource(
      [in] Id: PWideChar;
      [in] const iid: TIid;
      [out] out NamedResource
    ): HResult; stdcall;

    function IsFullyQualifiedResourceReference(
      [in] Id: PWideChar;
      [out] out IsReference: LongBool
    ): HResult; stdcall;
  end;

  // rev
  [MinOsVersion(OsWin1019H1)]
  IPriFilePathCollection = interface (IUnknown)
    ['{99F94871-7E70-4D31-9BF2-74A291F92EB1}']

    function GetCount(
      [out] out Count: Cardinal
    ): HResult; stdcall;

    function GetAt(
      [in] Index: Integer;
      [out, ReleaseWith('CoTaskMemFree')] out PriFilePath: PWideChar
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin8)]
  IMrtResourceManager = interface (IUnknown)
    ['{130A2F65-2BE7-4309-9A58-A9052FF2B61C}']

    function Initialize(
    ): HResult; stdcall;

    function InitializeForCurrentApplication(
    ): HResult; stdcall;

    function InitializeForPackage(
      [in] PackageFullName: PWideChar
    ): HResult; stdcall;

    function InitializeForFile(
      [in] FilePath: PWideChar
    ): HResult; stdcall;

    function GetMainResourceMap(
      [in] const IID: TIid;
      [out] out ResourceMap
    ): HResult; stdcall;

    function GetResourceMap(
      [in] Path: PWideChar;
      [in] const IID: TIid;
      [out] out ResourceMap
    ): HResult; stdcall;

    function GetDefaultContext(
      [in] const IID: TIid;
      [out] out ResourceContext
    ): HResult; stdcall;

    function GetReference(
      [in] const IID: TIid;
      [out] out ResourceReferenceHandler
    ): HResult; stdcall;

    function IsResourceReference(
      [in] Reference: PWideChar;
      [out] out IsResourceReference: LongBool
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin81)]
  IMrtResourceManager2 = interface (IUnknown)
    ['{439DD7C9-0EEB-4715-BAA7-F0877694E616}']

    function InitializeForPackageFile(
      [in] AFile: PWideChar;
      [in] PackageFullName: PWideChar
    ): HResult; stdcall;

    function TryInitializeForCurrentApplication(
    ): HResult; stdcall;

    function InitializeForInboxApplication(
      [in] AFile: PWideChar;
      [in] PackageFullName: PWideChar
    ): HResult; stdcall;
  end;

  // rev
  [MinOsVersion(OsWin10RS2)]
  IMrtResourceManager3 = interface (IUnknown)
    ['{76FDFEC5-E7DF-473B-891B-02453923B247}']

    function InitializeForBundledPackageVariant(
      [in] PackageFullName: PWideChar;
      [in] Unknown2: PWideChar;
      [in] Unknown3: PWideChar
    ): HResult; stdcall;

    function InitializeForPackageOrBundle(
      [in] PackageFullName: PWideChar
    ): HResult; stdcall;
  end;

  // rev
  [MinOsVersion(OsWin1019H1)]
  IMrtResourceManager4 = interface (IUnknown)
    ['{B506D088-F6A5-433B-9411-346515563394}']

    function GetAllIndividualPriFiles(
      [out] out PriFilePathCollection: IPriFilePathCollection
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin8)]
  IResourceManagerQueue = interface (IUnknown)
    ['{DB3C3F20-E4C9-4DCA-81A9-A69EBE2A0B2B}']

    function GetString(
      [in] Reference: PWideChar;
      [in] OverrideContextAttribute: PWideChar;
      [in] OverrideContextValue: PWideChar;
      [out, ReleaseWith('CoTaskMemFree')] out pszString: PWideChar
    ): HResult; stdcall;

    function IsResourceReference(
      [in] Reference: PWideChar
    ): HResult; stdcall;
  end;

  [SDKName('VALIDATE_OPTIONS')]
  [SubEnum(MAX_UINT, NAMED_RESOURCE_ALWAYS_YIELDS_RESULT, 'NAMED_RESOURCE_ALWAYS_YIELDS_RESULT')]
  [SubEnum(MAX_UINT, MAP_COMPLETE, 'MAP_COMPLETE')]
  [SubEnum(MAX_UINT, MAP_ALL_RESOURCES_YIELD_RESULT, 'MAP_ALL_RESOURCES_YIELD_RESULT')]
  [SubEnum(MAX_UINT, PRI_FILE_BLOCK_AUTOMERGE_ENABLED, 'PRI_FILE_BLOCK_AUTOMERGE_ENABLED')]
  [SubEnum(MAX_UINT, PRI_FILE_VERSION_8_REQUIRED, 'PRI_FILE_VERSION_8_REQUIRED')]
  IResourceValidateOptions = type Cardinal;

  // private
  [MinOSVersion(OsWin8)]
  IResourceValidator = interface (IUnknown)
    ['{7BB324BA-6DFE-4551-945F-935E101ECB96}']

    function SetOption(
      [in] Options: IResourceValidateOptions
    ): HResult; stdcall;

    function ValidateResourceMap(
      [in] ResourceMap: IResourceMap
    ): HResult; stdcall;

    function ValidateNamedResource(
      [in] NamedResource: INamedResource
    ): HResult; stdcall;

    function ValidatePriFile(
      [in] PriFilePath: PWideChar
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin8)]
  IMrtStringResolver = interface (IUnknown)
    ['{CFA81E06-A062-4E18-A62D-925397413383}']

    function Add(
      [in] Key: PWideChar;
      [in] StringValue: PWideChar;
      [in] Attribute: PWideChar;
      [in] QualifierValue: PWideChar
    ): HResult; stdcall;

    function AddWithQualifiers(
      [in] Key: PWideChar;
      [in] Value: PWideChar;
      [in, NumberOfElements] NumConditions: Cardinal;
      [in, ReadsFrom] Conditions: PResourceQualifier;
      [in] UseDefaults: LongBool
    ): HResult; stdcall;

    function Resolve(
      [in] Key: PWideChar;
      [out, ReleaseWith('CoTaskMemFree')] out ResultValue: PWideChar
    ): HResult; stdcall;

    function ResolveForContext(
      [in] const ResourceContext: IResourceContext;
      [in] Key: PWideChar;
      [out, ReleaseWith('CoTaskMemFree')] out ResultValue: PWideChar
    ): HResult; stdcall;

    function ResolveAll(
      [in] Key: PWideChar;
      [out] out Results: IResourceCandidateCollection
    ): HResult; stdcall;

    function ResolveAllForContext(
      [in] const ResourceContext: IResourceContext;
      [in] Key: PWideChar;
      [out] out Results: IResourceCandidateCollection
    ): HResult; stdcall;

    function GetDefaultContext(
      [in] const IID: TIid;
      [out] out Context
    ): HResult; stdcall;
  end;

// private
[MinOSVersion(OsWin8)]
function ResourceManagerQueueIsResourceReference(
  [in] Reference: PWideChar
): HResult; stdcall; external MrmCoreR delayed;

var delayed_ResourceManagerQueueIsResourceReference: TDelayedLoadFunction = (
  Dll: @delayed_MrmCoreR;
  FunctionName: 'ResourceManagerQueueIsResourceReference';
);

// private
[MinOSVersion(OsWin8)]
function ResourceManagerQueueGetString(
  [in] Reference: PWideChar;
  [in, opt] OverrideContextAttribute: PWideChar;
  [in, opt] OverrideContextValue: PWideChar;
  [out, WritesTo] szString: PWideChar;
  [in, NumberOfElements] cchSize: NativeUInt;
  [out, opt, NumberOfElements] cchCount: PNativeUInt
): HResult; stdcall; external MrmCoreR delayed;

var delayed_ResourceManagerQueueGetString: TDelayedLoadFunction = (
  Dll: @delayed_MrmCoreR;
  FunctionName: 'ResourceManagerQueueGetString';
);

// private
[MinOSVersion(OsWin8)]
function ResourceManagerQueueGetStringDirect(
  [in] Reference: PWideChar;
  [in, opt] OverrideContextAttribute: PWideChar;
  [in, opt] OverrideContextValue: PWideChar;
  [out, WritesTo] pszString: PWideChar;
  [in, NumberOfElements] cchSize: NativeUInt;
  [out, opt, NumberOfElements] cchCount: PNativeUInt
): HResult; stdcall; external MrmCoreR delayed;

var delayed_ResourceManagerQueueGetStringDirect: TDelayedLoadFunction = (
  Dll: @delayed_MrmCoreR;
  FunctionName: 'ResourceManagerQueueGetStringDirect';
);

// private
[MinOSVersion(OsWin81)]
function GetMergedSystemPri(
  [in] MainPriPath: PWideChar;
  [in, NumberOfElements] cchResult: Cardinal;
  [out, WritesTo] ResultOut: PWideChar;
  [out, opt, NumberOfElements] cchWritten: PCardinal
): HResult; stdcall; external MrmCoreR delayed;

var delayed_GetMergedSystemPri: TDelayedLoadFunction = (
  Dll: @delayed_MrmCoreR;
  FunctionName: 'GetMergedSystemPri';
);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
