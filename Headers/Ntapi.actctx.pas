unit Ntapi.actctx;

{
  This module includes definitions for querying and parsing activation contexts.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntrtl, Ntapi.Versions, DelphiApi.Reflection;

type
  // SDK::winnt.h
  [NamingStyle(nsSnakeCase, 'ACTIVATION_CONTEXT_PATH_TYPE'), Range(1)]
  TActivationContextPathType = (
    [Reserved] ACTIVATION_CONTEXT_PATH_TYPE_INVALID = 0,
    ACTIVATION_CONTEXT_PATH_TYPE_NONE = 1,
    ACTIVATION_CONTEXT_PATH_TYPE_WIN32_FILE = 2,
    ACTIVATION_CONTEXT_PATH_TYPE_URL = 3,
    ACTIVATION_CONTEXT_PATH_TYPE_ASSEMBLYREF = 4
  );

  // SDK::winnt.h
  [SDKName('ACTCTX_REQUESTED_RUN_LEVEL')]
  [NamingStyle(nsSnakeCase, 'ACTCTX_RUN_LEVEL')]
  TActCtxRequestedRunLevel = (
    ACTCTX_RUN_LEVEL_UNSPECIFIED = 0,
    ACTCTX_RUN_LEVEL_AS_INVOKER = 1,
    ACTCTX_RUN_LEVEL_HIGHEST_AVAILABLE = 2,
    ACTCTX_RUN_LEVEL_REQUIRE_ADMIN = 3
  );

{ Activation Context Data }

const
  // EWDK::sxstype.h - activation context data values
  ACTIVATION_CONTEXT_DATA_MAGIC = $78746341; // "Actx"
  ACTIVATION_CONTEXT_DATA_FORMAT_WHISTLER = 1;

  // EWDK::sxstype.h - activation context data flags
  ACTIVATION_CONTEXT_FLAG_NO_INHERIT = $00000001;

type
  [FlagName(ACTIVATION_CONTEXT_FLAG_NO_INHERIT, 'No Inherit')]
  TActivationContextFlags = type Cardinal;

  // EWDK::sxstypes.h
  [SDKName('ACTIVATION_CONTEXT_DATA')]
  TActivationContextData = record
    [Reserved(ACTIVATION_CONTEXT_DATA_MAGIC)] Magic: Cardinal;
    [RecordSize, Bytes] HeaderSize: Cardinal;
    [Reserved(ACTIVATION_CONTEXT_DATA_FORMAT_WHISTLER)] FormatVersion: Cardinal;
    [Bytes] TotalSize: Cardinal;
    DefaultTocOffset: Cardinal;     // TActivationContextDataTocHeader
    ExtendedTocOffset: Cardinal;    // TActivationContextDataExtendedTocHeader
    AssemblyRosterOffset: Cardinal; // TActivationContextDataAssemblyRosterHeader
    Flags: TActivationContextFlags;
  end;
  PActivationContextData = ^TActivationContextData;
  PPActivationContextData = ^PActivationContextData;

{ Section formats  }

type
  // SDK::winnt.h
  [NamingStyle(nsSnakeCase, 'ACTIVATION_CONTEXT_SECTION_FORMAT')]
  TActivationContextSectionFormat = (
    ACTIVATION_CONTEXT_SECTION_FORMAT_UNKNOWN = 0,
    ACTIVATION_CONTEXT_SECTION_FORMAT_STRING_TABLE = 1, // TActivationContextStringSectionHeader
    ACTIVATION_CONTEXT_SECTION_FORMAT_GUID_TABLE = 2    // TActivationContextGuidSectionHeader
  );

const
  // EWDK::sxstype.h - string section header values
  ACTIVATION_CONTEXT_STRING_SECTION_MAGIC = $64487353; // "SsHd"
  ACTIVATION_CONTEXT_STRING_SECTION_FORMAT_WHISTLER = 1;

  // EWDK::sxstype.h - string section header flags
  ACTIVATION_CONTEXT_STRING_SECTION_CASE_INSENSITIVE = $00000001;
  ACTIVATION_CONTEXT_STRING_SECTION_ENTRIES_IN_PSEUDOKEY_ORDER = $00000002;

type
  [FlagName(ACTIVATION_CONTEXT_STRING_SECTION_CASE_INSENSITIVE, 'Case Insensitive')]
  [FlagName(ACTIVATION_CONTEXT_STRING_SECTION_ENTRIES_IN_PSEUDOKEY_ORDER, 'In PseudoKey Order')]
  TActivationContextStringSectionFlags = type Cardinal;

  // EWDK::sxstypes.h
  [SDKName('ACTIVATION_CONTEXT_STRING_SECTION_HEADER')]
  TActivationContextStringSectionHeader = record
    [Reserved(ACTIVATION_CONTEXT_STRING_SECTION_MAGIC)] Magic: Cardinal;
    [RecordSize, Bytes] HeaderSize: Cardinal;
    [Reserved(ACTIVATION_CONTEXT_STRING_SECTION_FORMAT_WHISTLER)]
      FormatVersion: Cardinal;
    DataFormatVersion: Cardinal;
    Flags: TActivationContextStringSectionFlags;
    ElementCount: Cardinal;
    ElementListOffset: Cardinal;     // TActivationContextStringSectionEntry[], from the section header
    HashAlgorithm: THashStringAlgorithm;
    SearchStructureOffset: Cardinal; // from the section header
    UserDataOffset: Cardinal;        // from the section header
    [Bytes] UserDataSize: Cardinal;
  end;
  PActivationContextStringSectionHeader = ^TActivationContextStringSectionHeader;

  // EWDK::sxstypes.h
  [SDKName('ACTIVATION_CONTEXT_STRING_SECTION_ENTRY')]
  TActivationContextStringSectionEntry = record
    PseudoKey: Cardinal;
    KeyOffset: Cardinal; // PWideChar, from the section header
    [Bytes] KeyLength: Cardinal;
    Offset: Cardinal;    // from the section header
    [Bytes] Length: Cardinal;
    AssemblyRosterIndex: Cardinal;
  end;
  PActivationContextStringSectionEntry = ^TActivationContextStringSectionEntry;

const
  // EWDK::sxstype.h - GUID table header values
  ACTIVATION_CONTEXT_GUID_SECTION_MAGIC = $64487347; // "GsHd"
  ACTIVATION_CONTEXT_GUID_SECTION_FORMAT_WHISTLER = 1;

  // EWDK::sxstype.h - GUID table header flags
  ACTIVATION_CONTEXT_GUID_SECTION_ENTRIES_IN_ORDER = $00000001;

type
  [FlagName(ACTIVATION_CONTEXT_GUID_SECTION_ENTRIES_IN_ORDER, 'In Order')]
  TActivationContextGuidSectionFlags = type Cardinal;

  // EWDK::sxstypes.h
  [SDKName('ACTIVATION_CONTEXT_GUID_SECTION_HEADER')]
  TActivationContextGuidSectionHeader = record
    [Reserved(ACTIVATION_CONTEXT_GUID_SECTION_MAGIC)] Magic: Cardinal;
    [RecordSize, Bytes] HeaderSize: Cardinal;
    [Reserved(ACTIVATION_CONTEXT_GUID_SECTION_FORMAT_WHISTLER)]
      FormatVersion: Cardinal;
    DataFormatVersion: Cardinal;
    Flags: TActivationContextGuidSectionFlags;
    ElementCount: Cardinal;
    ElementListOffset: Cardinal;     // TActivationContextGuidSectionEntry[], from the section header
    SearchStructureOffset: Cardinal; // from the section header
    UserDataOffset: Cardinal;        // from the section header
    [Bytes] UserDataSize: Cardinal;
  end;
  PActivationContextGuidSectionHeader = ^TActivationContextGuidSectionHeader;

  // EWDK::sxstypes.h
  [SDKName('ACTIVATION_CONTEXT_GUID_SECTION_ENTRY')]
  TActivationContextGuidSectionEntry = record
    Guid: TGuid;
    Offset: Cardinal; // from the section header
    [Bytes] Length: Cardinal;
    AssemblyRosterIndex: Cardinal;
  end;
  PActivationContextGuidSectionEntry = ^TActivationContextGuidSectionEntry;

{ Known sections }

type
  // SDK::winnt.h
  [NamingStyle(nsSnakeCase, 'ACTIVATION_CONTEXT_SECTION'), Range(1)]
  TActivationContextSectionId = (
    [Reserved] ACTIVATION_CONTEXT_SECTION_RESERVED = 0,
    ACTIVATION_CONTEXT_SECTION_ASSEMBLY_INFORMATION = 1,         // TActivationContextDataAssemblyInformation
    ACTIVATION_CONTEXT_SECTION_DLL_REDIRECTION = 2,              // TActivationContextDataDllRedirection
    ACTIVATION_CONTEXT_SECTION_WINDOW_CLASS_REDIRECTION = 3,     // TActivationContextDataWindowClassRedirection
    ACTIVATION_CONTEXT_SECTION_COM_SERVER_REDIRECTION = 4,       // TActivationContextDataComServerRedirection
    ACTIVATION_CONTEXT_SECTION_COM_INTERFACE_REDIRECTION = 5,    // TActivationContextDataComInterfaceRedirection
    ACTIVATION_CONTEXT_SECTION_COM_TYPE_LIBRARY_REDIRECTION = 6, // TActivationContextDataComTypeLibraryRedirection
    ACTIVATION_CONTEXT_SECTION_COM_PROGID_REDIRECTION = 7,       // TActivationContextDataComProgIdRedirection
    ACTIVATION_CONTEXT_SECTION_GLOBAL_OBJECT_RENAME_TABLE = 8,
    ACTIVATION_CONTEXT_SECTION_CLR_SURROGATES = 9,               // TActivationContextDataClrSurrogate
    ACTIVATION_CONTEXT_SECTION_APPLICATION_SETTINGS = 10,        // TActivationContextDataApplicationSettings
    ACTIVATION_CONTEXT_SECTION_COMPATIBILITY_INFO = 11,          // TActivationContextCompatibilityInformation
    ACTIVATION_CONTEXT_SECTION_WINRT_ACTIVATABLE_CLASSES = 12    // Win 10 19H1+
  );

{ Section ID 1 }

const
  // EWDK::sxstype.h - data format for section ID 1
  ACTIVATION_CONTEXT_DATA_ASSEMBLY_INFORMATION_FORMAT_WHISTLER = 1;

  // EWDK::sxstype.h - flags for section ID 1
  ACTIVATION_CONTEXT_DATA_ASSEMBLY_INFORMATION_ROOT_ASSEMBLY = $00000001;
  ACTIVATION_CONTEXT_DATA_ASSEMBLY_INFORMATION_POLICY_APPLIED = $00000002;
  ACTIVATION_CONTEXT_DATA_ASSEMBLY_INFORMATION_ASSEMBLY_POLICY_APPLIED = $00000004;
  ACTIVATION_CONTEXT_DATA_ASSEMBLY_INFORMATION_ROOT_POLICY_APPLIED = $00000008;
  ACTIVATION_CONTEXT_DATA_ASSEMBLY_INFORMATION_PRIVATE_ASSEMBLY = $00000010;

type
  [FlagName(ACTIVATION_CONTEXT_DATA_ASSEMBLY_INFORMATION_ROOT_ASSEMBLY, 'Root Assembly')]
  [FlagName(ACTIVATION_CONTEXT_DATA_ASSEMBLY_INFORMATION_POLICY_APPLIED, 'Policy Applied')]
  [FlagName(ACTIVATION_CONTEXT_DATA_ASSEMBLY_INFORMATION_ASSEMBLY_POLICY_APPLIED, 'Assembly Policy Applied')]
  [FlagName(ACTIVATION_CONTEXT_DATA_ASSEMBLY_INFORMATION_ROOT_POLICY_APPLIED, 'Root Policy Applied')]
  [FlagName(ACTIVATION_CONTEXT_DATA_ASSEMBLY_INFORMATION_PRIVATE_ASSEMBLY, 'Private Assembly')]
  TActivationContextDataAssemblyInformationFlags = type Cardinal;

  // EWDK::sxstypes.h - section ID 1
  [SDKName('ACTIVATION_CONTEXT_DATA_ASSEMBLY_INFORMATION')]
  TActivationContextDataAssemblyInformation = packed record
    [RecordSize, Bytes] Size: Cardinal;
    Flags: TActivationContextDataAssemblyInformationFlags;
    [Bytes] EncodedAssemblyIdentityLength: Cardinal;
    EncodedAssemblyIdentityOffset: Cardinal; // PWideChar, from section header
    ManifestPathType: TActivationContextPathType;
    [Bytes] ManifestPathLength: Cardinal;
    ManifestPathOffset: Cardinal;            // PWideChar, from section header
    ManifestLastWriteTime: TLargeInteger;
    PolicyPathType: TActivationContextPathType;
    [Bytes] PolicyPathLength: Cardinal;
    PolicyPathOffset: Cardinal;              // PWideChar, from section header
    PolicyLastWriteTime: TLargeInteger;
    MetadataSatelliteRosterIndex: Cardinal;
    [Unlisted] Unused2: Cardinal;
    ManifestVersionMajor: Cardinal;
    ManifestVersionMinor: Cardinal;
    PolicyVersionMajor: Cardinal;
    PolicyVersionMinor: Cardinal;
    [Bytes] AssemblyDirectoryNameLength: Cardinal;
    AssemblyDirectoryNameOffset: Cardinal;   // PWideChar, from section header
    NumOfFilesInAssembly: Cardinal;
    [Bytes] LanguageLength: Cardinal;
    LanguageOffset: Cardinal;                // PWideChar, from section header
    RunLevel: TActCtxRequestedRunLevel;
    UiAccess: LongBool;
  end;
  PActivationContextDataAssemblyInformation = ^TActivationContextDataAssemblyInformation;

  // EWDK::sxstypes.h - user data for section ID 1
  [SDKName('ACTIVATION_CONTEXT_DATA_ASSEMBLY_GLOBAL_INFORMATION')]
  TActivationContextDataAssemblyGlobalInformation = record
    [RecordSize, Bytes] Size: Cardinal;
    [Hex] Flags: Cardinal;
    PolicyCoherencyGuid: TGuid;
    PolicyOverrideGuid: TGuid;
    ApplicationDirectoryPathType: TActivationContextPathType;
    [Bytes] ApplicationDirectoryLength: Cardinal;
    ApplicationDirectoryOffset: Cardinal; // from this struct
    ResourceName: Cardinal;
  end;
  PActivationContextDataAssemblyGlobalInformation = ^TActivationContextDataAssemblyGlobalInformation;

{ Section ID 2 }

const
  // EWDK::sxstype.h - data format for section ID 2
  ACTIVATION_CONTEXT_DATA_DLL_REDIRECTION_FORMAT_WHISTLER = 1;

  // EWDK::sxstype.h - flags for section ID 2
  ACTIVATION_CONTEXT_DATA_DLL_REDIRECTION_PATH_INCLUDES_BASE_NAME = $00000001;
  ACTIVATION_CONTEXT_DATA_DLL_REDIRECTION_PATH_OMITS_ASSEMBLY_ROOT = $00000002;
  ACTIVATION_CONTEXT_DATA_DLL_REDIRECTION_PATH_EXPAND = $00000004;
  ACTIVATION_CONTEXT_DATA_DLL_REDIRECTION_PATH_SYSTEM_DEFAULT_REDIRECTED_SYSTEM32_DLL = $00000008;

type
  [FlagName(ACTIVATION_CONTEXT_DATA_DLL_REDIRECTION_PATH_INCLUDES_BASE_NAME, 'Path Includes Base Name')]
  [FlagName(ACTIVATION_CONTEXT_DATA_DLL_REDIRECTION_PATH_OMITS_ASSEMBLY_ROOT, 'Path Omits Assembly Root')]
  [FlagName(ACTIVATION_CONTEXT_DATA_DLL_REDIRECTION_PATH_EXPAND, 'Path Expand')]
  [FlagName(ACTIVATION_CONTEXT_DATA_DLL_REDIRECTION_PATH_SYSTEM_DEFAULT_REDIRECTED_SYSTEM32_DLL, 'Path System-default Redirected System32 DLL')]
  TActivationContextDataDllRedirectionFlags = type Cardinal;

  // EWDK::sxstypes.h
  [SDKName('ACTIVATION_CONTEXT_DATA_DLL_REDIRECTION_PATH_SEGMENT')]
  TActivationContextDataDllRedirectionPathSegment = record
    [Bytes] Length: Cardinal;
    Offset: Cardinal; // from section header
  end;

  // EWDK::sxstypes.h - section ID 2
  [SDKName('ACTIVATION_CONTEXT_DATA_DLL_REDIRECTION')]
  TActivationContextDataDllRedirection = record
    [RecordSize, Bytes] Size: Cardinal;
    Flags: TActivationContextDataDllRedirectionFlags;
    [Bytes] TotalPathLength: Cardinal;
    PathSegmentCount: Cardinal;
    PathSegmentOffset: Cardinal; // TActivationContextDataDllRedirectionPathSegment, from section header
  end;
  PActivationContextDataDllRedirection = ^TActivationContextDataDllRedirection;

{ Section ID 3 }

const
  // EWDK::sxstypes.h - data format for section ID 3
  ACTIVATION_CONTEXT_DATA_WINDOW_CLASS_REDIRECTION_FORMAT_WHISTLER = 1;

type
  // EWDK::sxstypes.h - section ID 3
  [SDKName('ACTIVATION_CONTEXT_DATA_WINDOW_CLASS_REDIRECTION')]
  TActivationContextDataWindowClassRedirection = record
    [RecordSize, Bytes] Size: Cardinal;
    [Hex] Flags: Cardinal;
    [Bytes] VersionSpecificClassNameLength: Cardinal;
    VersionSpecificClassNameOffset: Cardinal; // PWideChar, from this structure
    [Bytes] DllNameLength: Cardinal;
    DllNameOffset: Cardinal;                  // PWideChar, from section header
  end;
  PActivationContextDataWindowClassRedirection = ^TActivationContextDataWindowClassRedirection;

{ Secion ID 4 }

const
  // EWDK::sxstypes.h - data format for section ID 4
  ACTIVATION_CONTEXT_DATA_COM_SERVER_REDIRECTION_FORMAT_WHISTLER = 1;

  // EWDK::sxstypes.h
  ACTIVATION_CONTEXT_DATA_COM_SERVER_MISCSTATUS_FLAG_OFFSET = 8;
  ACTIVATION_CONTEXT_DATA_COM_SERVER_MISCSTATUS_HAS_DEFAULT = $0100;
  ACTIVATION_CONTEXT_DATA_COM_SERVER_MISCSTATUS_HAS_ICON = $0200;
  ACTIVATION_CONTEXT_DATA_COM_SERVER_MISCSTATUS_HAS_CONTENT = $0400;
  ACTIVATION_CONTEXT_DATA_COM_SERVER_MISCSTATUS_HAS_THUMBNAIL = $0800;
  ACTIVATION_CONTEXT_DATA_COM_SERVER_MISCSTATUS_HAS_DOCPRINT = $1000;

type
  // EWDK::sxstypes.h
  [NamingStyle(nsSnakeCase, 'ACTIVATION_CONTEXT_DATA_COM_SERVER_REDIRECTION_THREADING_MODEL')]
  TActivationContextDataComServerRedirectionThreadingModel = (
    ACTIVATION_CONTEXT_DATA_COM_SERVER_REDIRECTION_THREADING_MODEL_INVALID = 0,
    ACTIVATION_CONTEXT_DATA_COM_SERVER_REDIRECTION_THREADING_MODEL_APARTMENT = 1,
    ACTIVATION_CONTEXT_DATA_COM_SERVER_REDIRECTION_THREADING_MODEL_FREE = 2,
    ACTIVATION_CONTEXT_DATA_COM_SERVER_REDIRECTION_THREADING_MODEL_SINGLE = 3,
    ACTIVATION_CONTEXT_DATA_COM_SERVER_REDIRECTION_THREADING_MODEL_BOTH = 4,
    ACTIVATION_CONTEXT_DATA_COM_SERVER_REDIRECTION_THREADING_MODEL_NEUTRAL = 5
  );

  // EWDK::sxstypes.h - section ID 4
  [SDKName('ACTIVATION_CONTEXT_DATA_COM_SERVER_REDIRECTION')]
  TActivationContextDataComServerRedirection = record
    [RecordSize, Bytes] Size: Cardinal;
    [Hex] Flags: Cardinal;
    ThreadingModel: TActivationContextDataComServerRedirectionThreadingModel;
    ReferenceClsid: TGuid;
    ConfiguredClsid: TGuid;
    ImplementedClsid: TGuid;
    TypeLibraryId: TGuid;
    [Bytes] ModuleLength: Cardinal;
    ModuleOffset: Cardinal;   // PWideChar, from section header
    [Bytes] ProgIdLength: Cardinal;
    ProgIdOffset: Cardinal;   // PWideChar, from this struct
    [Bytes] ShimDataLength: Cardinal;
    ShimDataOffset: Cardinal; // TActivationContextDataComServerRedirectionShim, from this struct
    MiscStatusDefault: Cardinal;
    MiscStatusContent: Cardinal;
    MiscStatusThumbnail: Cardinal;
    MiscStatusIcon: Cardinal;
    MiscStatusDocPrint: Cardinal;
  end;
  PActivationContextDataComServerRedirection = ^TActivationContextDataComServerRedirection;

  // EWDK::sxstypes.h
  [NamingStyle(nsSnakeCase, 'ACTIVATION_CONTEXT_DATA_COM_SERVER_REDIRECTION_SHIM_TYPE'), Range(1)]
  TActivationContextDataComServerRedirectionShimType = (
    [Reserved] ACTIVATION_CONTEXT_DATA_COM_SERVER_REDIRECTION_SHIM_TYPE_INVALID = 0,
    ACTIVATION_CONTEXT_DATA_COM_SERVER_REDIRECTION_SHIM_TYPE_OTHER = 1,
    ACTIVATION_CONTEXT_DATA_COM_SERVER_REDIRECTION_SHIM_TYPE_CLR_CLASS = 2
  );

  // EWDK::sxstypes.h
  [SDKName('ACTIVATION_CONTEXT_DATA_COM_SERVER_REDIRECTION_SHIM')]
  TActivationContextDataComServerRedirectionShim = record
    [RecordSize, Bytes] Size: Cardinal;
    [Hex] Flags: Cardinal;
    &Type: TActivationContextDataComServerRedirectionShimType;
    [Bytes] ModuleLength: Cardinal;
    ModuleOffset: Cardinal;      // PWideChar, from section header
    [Bytes] TypeLength: Cardinal;
    TypeOffset: Cardinal;        // PWideChar, from this struct
    [Bytes] ShimVersionLength: Cardinal;
    ShimVersionOffset: Cardinal; // PWideChar, from this struct
    [Bytes] DataLength: Cardinal;
    DataOffset: Cardinal;        // from this struct
  end;
  PActivationContextDataComServerRedirectionShim = ^TActivationContextDataComServerRedirectionShim;

{ Section ID 5 }

const
  // EWDK::sxstypes.h - data format for section ID 5
  ACTIVATION_CONTEXT_DATA_COM_INTERFACE_REDIRECTION_FORMAT_WHISTLER = 1;

  // EWDK::sxstypes.h - flags for section ID 5
  ACTIVATION_CONTEXT_DATA_COM_INTERFACE_REDIRECTION_FLAG_NUM_METHODS_VALID = $00000001;
  ACTIVATION_CONTEXT_DATA_COM_INTERFACE_REDIRECTION_FLAG_BASE_INTERFACE_VALID = $00000002;

type
  [FlagName(ACTIVATION_CONTEXT_DATA_COM_INTERFACE_REDIRECTION_FLAG_NUM_METHODS_VALID, 'NumMethods Valid')]
  [FlagName(ACTIVATION_CONTEXT_DATA_COM_INTERFACE_REDIRECTION_FLAG_BASE_INTERFACE_VALID, 'BaseInterface Valid')]
  TActivationContextDataComInterfaceRedirectionFlags = type Cardinal;

  // EWDK::sxstypes.h - section ID 5
  [SDKName('ACTIVATION_CONTEXT_DATA_COM_INTERFACE_REDIRECTION')]
  TActivationContextDataComInterfaceRedirection = record
    [RecordSize, Bytes] Size: Cardinal;
    Flags: TActivationContextDataComInterfaceRedirectionFlags;
    ProxyStubClsid32: TGuid;
    NumMethods: Cardinal;
    TypeLibraryId: TGuid;
    BaseInterface: TGuid;
    [Bytes] NameLength: Cardinal;
    NameOffset: Cardinal; // PWideChar, from this struct
  end;
  PActivationContextDataComInterfaceRedirection = ^TActivationContextDataComInterfaceRedirection;

{ Section ID 6 }

const
  // EWDK::sxstypes.h - data format for section ID 6
  ACTIVATION_CONTEXT_DATA_COM_TYPE_LIBRARY_REDIRECTION_FORMAT_WHISTLER = 1;

  // SDK::oaidl.h
  LIBFLAG_FRESTRICTED	= $1;
  LIBFLAG_FCONTROL = $2;
  LIBFLAG_FHIDDEN	= $4;
  LIBFLAG_FHASDISKIMAGE	= $8;

type
  // EWDK::sxstypes.h
  [SDKName('ACTIVATION_CONTEXT_DATA_TYPE_LIBRARY_VERSION')]
  TActivationContextDataTypeLibraryVersion = record
    Major: Word;
    Minor: Word;
  end;
  PActivationContextDataTypeLibraryVersion = ^TActivationContextDataTypeLibraryVersion;

  [SDKName('LIBFLAGS')]
  [FlagName(LIBFLAG_FRESTRICTED, 'Restricted')]
  [FlagName(LIBFLAG_FCONTROL, 'Control')]
  [FlagName(LIBFLAG_FHIDDEN, 'Hidden')]
  [FlagName(LIBFLAG_FHASDISKIMAGE, 'Has Disk Image')]
  TLibFlags = type Word;

  // EWDK::sxstypes.h - section ID 6
  [SDKName('ACTIVATION_CONTEXT_DATA_COM_TYPE_LIBRARY_REDIRECTION')]
  TActivationContextDataComTypeLibraryRedirection = record
    [RecordSize, Bytes] Size: Cardinal;
    [Hex] Flags: Cardinal;
    [Bytes] NameLength: Cardinal;
    NameOffset: Cardinal;    // from section header
    ResourceId: Word;
    LibraryFlags: TLibFlags;
    [Bytes] HelpDirLength: Cardinal;
    HelpDirOffset: Cardinal; // from this struct
    Version: TActivationContextDataTypeLibraryVersion;
  end;
  PActivationContextDataComTypeLibraryRedirection = ^TActivationContextDataComTypeLibraryRedirection;

{ Section ID 7 }

const
  // EWDK::sxstypes.h - data format for section ID 7
  ACTIVATION_CONTEXT_DATA_COM_PROGID_REDIRECTION_FORMAT_WHISTLER = 1;

type
  // EWDK::sxstypes.h - section ID 7
  [SDKName('ACTIVATION_CONTEXT_DATA_COM_PROGID_REDIRECTION')]
  TActivationContextDataComProgIdRedirection = record
    [RecordSize, Bytes] Size: Cardinal;
    [Hex] Flags: Cardinal;
    ConfiguredClsidOffset: Cardinal; // TGuid, from section header
  end;
  PActivationContextDataComProgIdRedirection = ^TActivationContextDataComProgIdRedirection;

{ Section ID 9 }

const
  // EWDK::sxstypes.h - data format for section ID 9
  ACTIVATION_CONTEXT_DATA_CLR_SURROGATE_FORMAT_WHISTLER = 1;

type
  // EWDK::sxstypes.h - section ID 9
  [SDKName('ACTIVATION_CONTEXT_DATA_CLR_SURROGATE')]
  TActivationContextDataClrSurrogate = record
    [RecordSize, Bytes] Size: Cardinal;
    [Hex] Flags: Cardinal;
    SurrogateIdent: TGuid;
    VersionOffset: Cardinal;  // PWideChar, from this struct
    [Bytes] VersionLength: Cardinal;
    TypeNameOffset: Cardinal; // PWideChar, from this struct
    [Bytes] TypeNameLength: Cardinal;
  end;
  PActivationContextDataClrSurrogate = ^TActivationContextDataClrSurrogate;

{ Section ID 10 }

const
  // EWDK::sxstype.h - flags for section ID 10
  ACTIVATION_CONTEXT_DATA_APPLICATION_SETTINGS_FORMAT_LONGHORN = 1;

type
  // EWDK::sxstypes.h - section ID 10
  [SDKName('ACTIVATION_CONTEXT_DATA_APPLICATION_SETTINGS')]
  TActivationContextDataApplicationSettings = record
    [RecordSize, Bytes] Size: Cardinal;
    [Hex] Flags: Cardinal;
    [Bytes] SettingNamespaceLength: Cardinal;
    SettingNamespaceOffset: Cardinal; // PWideChar, from this struct
    [Bytes] SettingNameLength: Cardinal;
    SettingNameOffset: Cardinal;      // PWideChar, from this struct
    [Bytes] SettingValueLength: Cardinal;
    SettingValueOffset: Cardinal;     // PWideChar, from this struct
  end;
  PActivationContextDataApplicationSettings = ^TActivationContextDataApplicationSettings;

{ Table of Content }

const
  // EWDK::sxstype.h - flags for activation context TOC header
  ACTIVATION_CONTEXT_DATA_TOC_HEADER_DENSE = $00000001;
  ACTIVATION_CONTEXT_DATA_TOC_HEADER_INORDER = $00000002;

type
  [FlagName(ACTIVATION_CONTEXT_DATA_TOC_HEADER_DENSE, 'Dense')]
  [FlagName(ACTIVATION_CONTEXT_DATA_TOC_HEADER_INORDER, 'In Order')]
  TActivationContextTocHeaderFlags = type Cardinal;

  // EWDK::sxstypes.h
  [SDKName('ACTIVATION_CONTEXT_DATA_TOC_HEADER')]
  TActivationContextDataTocHeader = record
    [RecordSize, Bytes] HeaderSize: Cardinal;
    EntryCount: Cardinal;
    FirstEntryOffset: Cardinal; // TActivationContextDataTocEntry, from activation context data
    Flags: TActivationContextTocHeaderFlags;
  end;
  PActivationContextDataTocHeader = ^TActivationContextDataTocHeader;

  // EWDK::sxstypes.h
  [SDKName('ACTIVATION_CONTEXT_DATA_TOC_ENTRY')]
  TActivationContextDataTocEntry = record
    Id: TActivationContextSectionId;
    Offset: Cardinal;  // from activation context data
    [Bytes] Length: Cardinal;
    Format: TActivationContextSectionFormat;
  end;
  PActivationContextDataTocEntry = ^TActivationContextDataTocEntry;

{ Extended Table of Content }

type
  // EWDK::sxstypes.h
  [SDKName('ACTIVATION_CONTEXT_DATA_EXTENDED_TOC_HEADER')]
  TActivationContextDataExtendedTocHeader = record
    [RecordSize, Bytes] HeaderSize: Cardinal;
    EntryCount: Cardinal;
    FirstEntryOffset: Cardinal; // TActivationContextDataExtendedTocEntry[], from activation context data
    [Hex] Flags: Cardinal;
  end;
  PActivationContextDataExtendedTocHeader = ^TActivationContextDataExtendedTocHeader;
  // EWDK::sxstypes.h
  [SDKName('ACTIVATION_CONTEXT_DATA_EXTENDED_TOC_ENTRY')]
  TActivationContextDataExtendedTocEntry = record
    ExtensionGuid: TGuid;
    TocOffset: Cardinal; // TActivationContextDataTocHeader, from activation context data
    [Bytes] Length: Cardinal;
  end;
  PActivationContextDataExtendedTocEntry = ^TActivationContextDataExtendedTocEntry;
{ Assembly Roster }

const
  // EWDK::sxstypes.h - assembly roster entry flags
  ACTIVATION_CONTEXT_DATA_ASSEMBLY_ROSTER_ENTRY_INVALID = $00000001;
  ACTIVATION_CONTEXT_DATA_ASSEMBLY_ROSTER_ENTRY_ROOT = $00000002;

type
  [FlagName(ACTIVATION_CONTEXT_DATA_ASSEMBLY_ROSTER_ENTRY_INVALID, 'Invalid')]
  [FlagName(ACTIVATION_CONTEXT_DATA_ASSEMBLY_ROSTER_ENTRY_ROOT, 'Root')]
  TActivationContextDataAssemblyRosterFlags = type Cardinal;

  // EWDK::sxstypes.h
  [SDKName('ACTIVATION_CONTEXT_DATA_ASSEMBLY_ROSTER_HEADER')]
  TActivationContextDataAssemblyRosterHeader = record
    [Bytes] HeaderSize: Cardinal;
    HashAlgorithm: THashStringAlgorithm;
    EntryCount: Cardinal;
    FirstEntryOffset: Cardinal; // TActivationContextDataAssemblyRosterEntry[], from activation context data
    AssemblyInformationSectionOffset: Cardinal; // from activation activation context context data
  end;
  PActivationContextDataAssemblyRosterHeader = ^TActivationContextDataAssemblyRosterHeader;

  // EWDK::sxstypes.h
  [SDKName('ACTIVATION_CONTEXT_DATA_ASSEMBLY_ROSTER_ENTRY')]
  TActivationContextDataAssemblyRosterEntry = record
    Flags: TActivationContextDataAssemblyRosterFlags;
    PseudoKey: Cardinal;
    AssemblyNameOffset: Cardinal; // PWideChar, from activation context data
    [Bytes] AssemblyNameLength: Cardinal;
    AssemblyInformationOffset: Cardinal; // TActivationContextDataAssemblyInformation, from activation context data
    [Bytes] AssemblyInformationLength: Cardinal;
  end;
  PActivationContextDataAssemblyRosterEntry = ^TActivationContextDataAssemblyRosterEntry;

{ hActCtx }

const
  ASSEMBLY_STORAGE_MAP_ASSEMBLY_ARRAY_IS_HEAP_ALLOCATED = $00000001;

type
  [SDKName('ASSEMBLY_STORAGE_MAP_ENTRY')]
  TAssemblyStorageMapEntry = record
    [Hex] Flags: Cardinal;
    DosPath: TNtUnicodeString;
    Handle: THandle;
  end;
  PAssemblyStorageMapEntry = ^TAssemblyStorageMapEntry;
  PPAssemblyStorageMapEntry = ^PAssemblyStorageMapEntry;

  [FlagName(ASSEMBLY_STORAGE_MAP_ASSEMBLY_ARRAY_IS_HEAP_ALLOCATED, 'Assembly Array Is Heap Allocated')]
  TAssemblyStorageMapFlags = type Cardinal;

  [SDKName('ASSEMBLY_STORAGE_MAP')]
  TAssemblyStorageMap = record
    Flags: TAssemblyStorageMapFlags;
    AssemblyCount: Cardinal;
    AssemblyArray: PPAssemblyStorageMapEntry;
  end;
  PAssemblyStorageMap = ^TAssemblyStorageMap;

  // Declared below
  PActivationContext = ^TActivationContext;

  [NamingStyle(nsSnakeCase, 'ACTIVATION_CONTEXT_NOTIFICATION'), Range(1)]
  TActivationContextNotification = (
    [Reserved] ACTIVATION_CONTEXT_NOTIFICATION_RESERVED = 0,
    ACTIVATION_CONTEXT_NOTIFICATION_DESTROY = 1, // no notification data
    ACTIVATION_CONTEXT_NOTIFICATION_ZOMBIFY = 2, // no notification data
    ACTIVATION_CONTEXT_NOTIFICATION_USED = 3
  );

  [SDKName('PACTIVATION_CONTEXT_NOTIFY_ROUTINE')]
  TActivationContextNotifyRoutine = procedure (
    [in] NotificationType: TActivationContextNotification;
    [in] ActivationContext: PActivationContext;
    [in] ActivationContextData: PActivationContextData;
    [in, opt] NotificationContext: Pointer;
    [in, opt] NotificationData: Pointer;
    [in, out] var DisableThisNotification: Boolean
  ); stdcall;

  [SDKName('ACTIVATION_CONTEXT')]
  TActivationContext = record
    RefCount: Integer;
    [Hex] Flags: Cardinal;
    Links: TListEntry;
    ActivationContextData: PActivationContextData;
    NotificationRoutine: TActivationContextNotifyRoutine;
    NotificationContext: Pointer;
    SentNotifications: array [0..7] of Cardinal;
    DisabledNotifications: array [0..7] of Cardinal;
	  StorageMap: TAssemblyStorageMap;
    InlineStorageMapEntries: array [0..31] of PAssemblyStorageMapEntry;
    StackTraceIndex: Cardinal;
	  StackTraces: array [0..3, 0..3] of Pointer;
  end;

const
  ACTCTX_PROCESS_DEFAULT = PActivationContext(0);
  ACTCTX_EMPTY = PActivationContext(-3);
  ACTCTX_SYSTEM_DEFAULT = PActivationContext(-4);

  INVALID_ACTIVATION_CONTEXT = PActivationContext(-1);

{ Activation Context Stack }

const
  ACTIVATION_CONTEXT_STACK_FLAG_QUERIES_DISABLED = $00000001;

type
  PRtlActivationContextStackFrame = ^TRtlActivationContextStackFrame;
  [SDKName('RTL_ACTIVATION_CONTEXT_STACK_FRAME')]
  TRtlActivationContextStackFrame = record
    Previous: PRtlActivationContextStackFrame;
    ActivationContext: PActivationContext;
    [Hex] Flags: Cardinal;
  end;

type
  [FlagName(ACTIVATION_CONTEXT_STACK_FLAG_QUERIES_DISABLED, 'Queries Disabled')]
  TActivationContextStackFlags = type Cardinal;

  // PHNT::ntpebteb.h
  [SDKName('ACTIVATION_CONTEXT_STACK')]
  TActivationContextStack = record
    ActiveFrame: PRtlActivationContextStackFrame;
    FrameListCache: TListEntry;
    Flags: TActivationContextStackFlags;
    NextCookieSequenceNumber: Cardinal;
    StackId: Cardinal
  end;
  PActivationContextStack = ^TActivationContextStack;

{ Information }

const
  // Activation context query flags
  RTL_QUERY_INFORMATION_ACTIVATION_CONTEXT_FLAG_USE_ACTIVE_ACTIVATION_CONTEXT = $00000001;
  RTL_QUERY_INFORMATION_ACTIVATION_CONTEXT_FLAG_ACTIVATION_CONTEXT_IS_MODULE = $00000002;
  RTL_QUERY_INFORMATION_ACTIVATION_CONTEXT_FLAG_ACTIVATION_CONTEXT_IS_ADDRESS = $00000004;
  RTL_QUERY_INFORMATION_ACTIVATION_CONTEXT_FLAG_NO_ADDREF = $80000000; // basic info only

type
  // SDK::winnt.h
  [SDKName('ACTIVATION_CONTEXT_INFO_CLASS')]
  [NamingStyle(nsCamelCase, 'ActivationContext', 'InActivationContext')]
  TActivationContextInfoClass = (
    [Reserved] ActivationContextReserved = 0,
    ActivationContextBasicInformation = 1,                      // q: TActivationContextBasicInformation
    ActivationContextDetailedInformation = 2,                   // q: TActivationContextDetailedInformation
    AssemblyDetailedInformationInActivationContext = 3,         // q: TActivationContextAssemblyDetailedInformation ?
    FileInformationInAssemblyOfAssemblyInActivationContext = 4, // q: TAssemblyFileDetailedInformation
    RunlevelInformationInActivationContext = 5,                 // q: TActivationContextRunLevelInformation
    CompatibilityInformationInActivationContext = 6,            // q: TActivationContextCompatibilityInformation
    ActivationContextManifestResourceName = 7                   // q: Cardinal
  );

  // SDK::WinBase.h - info class 1
  [SDKName('ACTIVATION_CONTEXT_BASIC_INFORMATION')]
  TActivationContextBasicInformation = record
    ActivationContext: PActivationContext;
    Flags: TActivationContextFlags;
  end;
  PActivationContextBasicInformation = ^TActivationContextBasicInformation;

  // SDK::winnt.h - info class 2
  [SDKName('ACTIVATION_CONTEXT_DETAILED_INFORMATION')]
  TActivationContextDetailedInformation = record
    Flags: TActivationContextFlags;
    [Reserved(ACTIVATION_CONTEXT_DATA_FORMAT_WHISTLER)] FormatVersion: Cardinal;
    AssemblyCount: Cardinal;
    RootManifestPathType: TActivationContextPathType;
    RootManifestPathChars: Cardinal;
    RootConfigurationPathType: TActivationContextPathType;
    RootConfigurationPathChars: Cardinal;
    AppDirPathType: TActivationContextPathType;
    AppDirPathChars: Cardinal;
    RootManifestPath: PWideChar;
    RootConfigurationPath: PWideChar;
    AppDirPath: PWideChar;
  end;
  PActivationContextDetailedInformation = ^TActivationContextDetailedInformation;

  // SDK::winnt.h - SubInstanceIndex
  [SDKName('ACTIVATION_CONTEXT_QUERY_INDEX')]
  TActivationContextQueryIndex = record
    AssemblyIndex: Cardinal;       // info class 3 & 4
    FileIndexInAssembly: Cardinal; // info class 4
  end;
  PActivationContextQueryIndex = ^TActivationContextQueryIndex;

  // SDK::winnt.h - info class 3
  [SDKName('ACTIVATION_CONTEXT_ASSEMBLY_DETAILED_INFORMATION')]
  TActivationContextAssemblyDetailedInformation = record
    [Hex] Flags: Cardinal;
    [Bytes] EncodedAssemblyIdentityLength: Cardinal;
    ManifestPathType: TActivationContextPathType;
    [Bytes] ManifestPathLength: Cardinal;
    ManifestLastWriteTime: TLargeInteger;
    PolicyPathType: TActivationContextPathType;
    [Bytes] PolicyPathLength: Cardinal;
    PolicyLastWriteTime: TLargeInteger;
    MetadataSatelliteRosterIndex: Cardinal;
    ManifestVersionMajor: Cardinal;
    ManifestVersionMinor: Cardinal;
    PolicyVersionMajor: Cardinal;
    PolicyVersionMinor: Cardinal;
    [Bytes] AssemblyDirectoryNameLength: Cardinal;
    AssemblyEncodedAssemblyIdentity: PWideChar;
    AssemblyManifestPath: PWideChar;
    AssemblyPolicyPath: PWideChar;
    AssemblyDirectoryName: PWideChar;
    FileCount: Cardinal;
  end;
  PActivationContextAssemblyDetailedInformation = ^TActivationContextAssemblyDetailedInformation;

  // SDK::winnt.h - info class 4
  [SDKName('ASSEMBLY_FILE_DETAILED_INFORMATION')]
  TAssemblyFileDetailedInformation = record
    [Hex] Flags: Cardinal;
    [Bytes] FilenameLength: Cardinal;
    [Bytes] PathLength: Cardinal;
    FileName: PWideChar;
    FilePath: PWideChar;
  end;
  PAssemblyFileDetailedInformation = ^TAssemblyFileDetailedInformation;

  // SDK::winnt.h - info class 5
  [SDKName('ACTIVATION_CONTEXT_RUN_LEVEL_INFORMATION')]
  TActivationContextRunLevelInformation = record
    [Hex] Flags: Cardinal;
    RunLevel: TActCtxRequestedRunLevel;
    UIAccess: LongBool;
  end;
  PActivationContextRunLevelInformation = ^TActivationContextRunLevelInformation;

  [FlagName(RTL_QUERY_INFORMATION_ACTIVATION_CONTEXT_FLAG_USE_ACTIVE_ACTIVATION_CONTEXT, 'Use Active Activation Context')]
  [FlagName(RTL_QUERY_INFORMATION_ACTIVATION_CONTEXT_FLAG_ACTIVATION_CONTEXT_IS_MODULE, 'Activation Context Is Module')]
  [FlagName(RTL_QUERY_INFORMATION_ACTIVATION_CONTEXT_FLAG_ACTIVATION_CONTEXT_IS_ADDRESS, 'Activation Context Is Address')]
  [FlagName(RTL_QUERY_INFORMATION_ACTIVATION_CONTEXT_FLAG_NO_ADDREF, 'No Adding Ref')]
  TRtlQueryInfoActCtxFlags = type Cardinal;

  // SDK::winnth.h
  [SDKName('ACTCTX_COMPATIBILITY_ELEMENT_TYPE')]
  [NamingStyle(nsSnakeCase, 'ACTCTX_COMPATIBILITY_ELEMENT_TYPE')]
  TActCtxCompatibilityElementType = (
    ACTCTX_COMPATIBILITY_ELEMENT_TYPE_UNKNOWN = 0,
    ACTCTX_COMPATIBILITY_ELEMENT_TYPE_OS = 1,
    ACTCTX_COMPATIBILITY_ELEMENT_TYPE_MITIGATION = 2,
    ACTCTX_COMPATIBILITY_ELEMENT_TYPE_MAXVERSIONTESTED = 3 // Win 10 19H1+
  );

  // SDK::winnth.h
  [SDKName('COMPATIBILITY_CONTEXT_ELEMENT')]
  TCompatibilityContextElement = record
    Id: TGuid;
    AType: TActCtxCompatibilityElementType;
    [MinOSVersion(OsWin1019H1)] MaxVersionTested: UInt64;
  end;
  PCompatibilityContextElement = ^TCompatibilityContextElement;

  // SDK::winnth.h - info class 6 & acivation context data section ID 11
  [SDKName('ACTIVATION_CONTEXT_COMPATIBILITY_INFORMATION')]
  TActivationContextCompatibilityInformation = record
    ElementCount: Cardinal;
    [Unlisted] Unused: Cardinal;
    Elements: TPlaceholder<TCompatibilityContextElement>;
  end;
  PActivationContextCompatibilityInformation = ^TActivationContextCompatibilityInformation;

{ Operations (ntdll) }

const
  // Flags for RtlActivateActivationContextEx
  RTL_ACTIVATE_ACTIVATION_CONTEXT_EX_FLAG_RELEASE_ON_STACK_DEALLOCATION = $00000001;

  // Flags for RtlDeactivateActivationContext
  RTL_DEACTIVATE_ACTIVATION_CONTEXT_FLAG_FORCE_EARLY_DEACTIVATION = $00000001;

type
  [FlagName(RTL_ACTIVATE_ACTIVATION_CONTEXT_EX_FLAG_RELEASE_ON_STACK_DEALLOCATION, 'Release On Stack Deallocation')]
  TRtlActivateActCtxExFlags = type Cardinal;

  [FlagName(RTL_DEACTIVATE_ACTIVATION_CONTEXT_FLAG_FORCE_EARLY_DEACTIVATION, 'Force Early Deactivation')]
  TRtlDeactivateActCtxFlags = type Cardinal;

{ Operations (kernel32) }

const
  // SDK::WinBase.h - activation context creation flags
  ACTCTX_FLAG_PROCESSOR_ARCHITECTURE_VALID = $00000001;
  ACTCTX_FLAG_LANGID_VALID = $00000002;
  ACTCTX_FLAG_ASSEMBLY_DIRECTORY_VALID = $00000004;
  ACTCTX_FLAG_RESOURCE_NAME_VALID = $00000008;
  ACTCTX_FLAG_SET_PROCESS_DEFAULT = $00000010;
  ACTCTX_FLAG_APPLICATION_NAME_VALID = $00000020;
  ACTCTX_FLAG_SOURCE_IS_ASSEMBLYREF = $00000040;
  ACTCTX_FLAG_HMODULE_VALID = $00000080;

type
  [FlagName(ACTCTX_FLAG_PROCESSOR_ARCHITECTURE_VALID, 'Processor Architecture Valid')]
  [FlagName(ACTCTX_FLAG_LANGID_VALID, 'LangID Valid')]
  [FlagName(ACTCTX_FLAG_ASSEMBLY_DIRECTORY_VALID, 'Assembly Directory Valid')]
  [FlagName(ACTCTX_FLAG_RESOURCE_NAME_VALID, 'Resource Name Valid')]
  [FlagName(ACTCTX_FLAG_SET_PROCESS_DEFAULT, 'Set Process Default')]
  [FlagName(ACTCTX_FLAG_APPLICATION_NAME_VALID, 'Application Name Valid')]
  [FlagName(ACTCTX_FLAG_SOURCE_IS_ASSEMBLYREF, 'Source Is Assembly Ref')]
  [FlagName(ACTCTX_FLAG_HMODULE_VALID, 'hModule Valid')]
  TActCtxFlags = type Cardinal;

  // SDK::WinBase.h
  [SDKName('ACTCTXW')]
  TActCtxW = record
    [RecordSize, Bytes] Size: Cardinal;
    Flags: TActCtxFlags;
    Source: PWideChar;
    ProcessorArchitecture: TProcessorArchitecture;
    LangId: Word;
    AssemblyDirectory: PWideChar;
    ResourceName: PWideChar;
    ApplicationName: PWideChar;
    hModule: HMODULE;
  end;
  PActCtxW = ^TActCtxW;

// SDK::WinBase.h
[SetsLastError]
[Result: ReleaseWith('RtlReleaseActivationContext')]
function CreateActCtxW(
  [in] const ActCtx: TActCtxW
): PActivationContext; stdcall; external kernel32;

function RtlQueryInformationActiveActivationContext(
  [in] ActivationContextInformationClass: TActivationContextInfoClass;
  [out, WritesTo] ActivationContextInformation: Pointer;
  [in, NumberOfBytes] ActivationContextInformationLength: NativeUInt;
  [out, opt, NumberOfBytes] ReturnLength: PNativeUInt
): NTSTATUS; stdcall; external ntdll;

function RtlQueryInformationActivationContext(
  [in] Flags: TRtlQueryInfoActCtxFlags;
  [in] ActivationContext: PActivationContext;
  [in, opt] SubInstanceIndex: PActivationContextQueryIndex;
  [in] ActivationContextInformationClass: TActivationContextInfoClass;
  [out, WritesTo] ActivationContextInformation: Pointer;
  [in, NumberOfBytes] ActivationContextInformationLength: NativeUInt;
  [out, opt, NumberOfBytes] ReturnLength: PNativeUInt
): NTSTATUS; stdcall; external ntdll;

function RtlQueryActivationContextApplicationSettings(
  [Reserved] Flags: Cardinal;
  [in] ActivationContext: PActivationContext;
  [in] SettingsNameSpace: PWideChar;
  [in] SettingName: PWideChar;
  [out, WritesTo] Buffer: PWideChar;
  [in, NumberOfElements] BufferLength: NativeUInt;
  [out, opt, NumberOfElements] RequiredLength: PNativeUInt
): NTSTATUS; stdcall; external ntdll;

function RtlCreateActivationContext(
  [Reserved] Flags: Cardinal;
  [in] ActivationContextData: PActivationContextData;
  [in, opt] ExtraBytes: Cardinal;
  [in, opt] NotificationRoutine: TActivationContextNotifyRoutine;
  [in, opt] NotificationContext: Pointer;
  [out, ReleaseWith('RtlReleaseActivationContext')]
    out ActivationContext: PActivationContext
): NTSTATUS; stdcall; external ntdll;

procedure RtlAddRefActivationContext(
  [in] AppCtx: PActivationContext
); stdcall; external ntdll;

procedure RtlReleaseActivationContext(
  [in] AppCtx: PActivationContext
); stdcall; external ntdll;

function RtlZombifyActivationContext(
  [in] AppCtx: PActivationContext
): NTSTATUS; stdcall; external ntdll;

function RtlGetActiveActivationContext(
  [out, ReleaseWith('RtlReleaseActivationContext')]
    out ActivationContext: PActivationContext
): NTSTATUS; stdcall; external ntdll;

function RtlIsActivationContextActive(
  [in] ActivationContext: PActivationContext
): Boolean; stdcall; external ntdll;

function RtlActivateActivationContext(
  [Reserved] Flags: Cardinal;
  [in] ActivationContext: PActivationContext;
  [out, ReleaseWith('RtlDeactivateActivationContext')] out Cookie: NativeUInt
): NTSTATUS; stdcall; external ntdll;

function RtlActivateActivationContextEx(
  [in] Flags: TRtlActivateActCtxExFlags;
  [in] Teb: Pointer; // PTeb
  [in] ActivationContext: PActivationContext;
  [out, ReleaseWith('RtlDeactivateActivationContext')] out Cookie: NativeUInt
): NTSTATUS; stdcall; external ntdll;

procedure RtlDeactivateActivationContext(
  [in] Flags: TRtlDeactivateActCtxFlags;
  [in] Cookie: NativeUInt
); stdcall; external ntdll;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
