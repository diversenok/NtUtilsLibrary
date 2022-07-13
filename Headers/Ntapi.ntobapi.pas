unit Ntapi.ntobapi;

{
  This file defines functions for manipulating kernel objects and their handles.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, Ntapi.Versions,
  DelphiApi.Reflection;

const
  // WDK::wdm.h - object directory access masks
  DIRECTORY_QUERY = $0001;
  DIRECTORY_TRAVERSE = $0002;
  DIRECTORY_CREATE_OBJECT = $0004;
  DIRECTORY_CREATE_SUBDIRECTORY = $0008;
  DIRECTORY_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $000f;

  // PHNT::ntobapi.h - boundary descriptor version
  BOUNDARY_DESCRIPTOR_VERSION = 1;

  // PHNT::ntrtl.h - boundary descriptor flags
  BOUNDARY_DESCRIPTOR_ADD_APPCONTAINER_SID = $1;

  // WDK::wdm.h - object symlink access masks
  SYMBOLIC_LINK_QUERY = $0001;
  SYMBOLIC_LINK_SET = $0002;
  SYMBOLIC_LINK_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $0001;
  SYMBOLIC_LINK_ALL_ACCESS_EX = STANDARD_RIGHTS_REQUIRED or SPECIFIC_RIGHTS_ALL;

  // WDK::wdm.h - handle duplication options
  DUPLICATE_CLOSE_SOURCE = $00000001;
  DUPLICATE_SAME_ACCESS = $00000002;
  DUPLICATE_SAME_ATTRIBUTES = $00000004;

  // rev - kernel type index offset
  OB_TYPE_INDEX_TABLE_TYPE_OFFSET = 2;

type
  [FlagName(DUPLICATE_CLOSE_SOURCE, 'Close Source')]
  [FlagName(DUPLICATE_SAME_ACCESS, 'Same Access')]
  [FlagName(DUPLICATE_SAME_ATTRIBUTES, 'Same Attributes')]
  TDuplicateOptions = type Cardinal;

  [FriendlyName('directory'), ValidMask(DIRECTORY_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(DIRECTORY_QUERY, 'Query')]
  [FlagName(DIRECTORY_TRAVERSE, 'Traverse')]
  [FlagName(DIRECTORY_CREATE_OBJECT, 'Create Object')]
  [FlagName(DIRECTORY_CREATE_SUBDIRECTORY, 'Create Sub-directories')]
  TDirectoryAccessMask = type TAccessMask;

  [FriendlyName('symlink'), ValidMask(SYMBOLIC_LINK_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(SYMBOLIC_LINK_QUERY, 'Query')]
  [FlagName(SYMBOLIC_LINK_SET, 'Set')]
  TSymlinkAccessMask = type TAccessMask;

  // PHNT::ntobapi.h & partially WDK::ntifs.h
  [SDKName('OBJECT_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'Object')]
  TObjectInformationClass = (
    ObjectBasicInformation = 0,     // q: TObjectBasicInformaion
    ObjectNameInformation = 1,      // q: TNtUnicodeString
    ObjectTypeInformation = 2,      // q: TObjectTypeInformation
    ObjectTypesInformation = 3,     // q: TObjectTypesInformation + TObjectTypeInformation
    ObjectHandleFlagInformation = 4 // q+s: TObjectHandleFlagInformation
  );

  // PHNT::ntobapi.h - info class 0
  [SDKName('OBJECT_BASIC_INFORMATION')]
  TObjectBasicInformation = record
    Attributes: TObjectAttributesFlags;
    GrantedAccess: TAccessMask;
    HandleCount: Cardinal;
    PointerCount: Cardinal;
    [Bytes] PagedPoolCharge: Cardinal;
    [Bytes] NonPagedPoolCharge: Cardinal;
    Reserved: array [0..2] of Cardinal;
    [Bytes] NameInfoSize: Cardinal;
    [Bytes] TypeInfoSize: Cardinal;
    [Bytes] SecurityDescriptorSize: Cardinal;
    CreationTime: TLargeInteger;
  end;
  PObjectBasicInformation = ^TObjectBasicInformation;

  // PHNT::ntobapi.h - info class 2
  [SDKName('OBJECT_TYPE_INFORMATION')]
  TObjectTypeInformation = record
    TypeName: TNtUnicodeString;
    TotalNumberOfObjects: Cardinal;
    TotalNumberOfHandles: Cardinal;
    [Bytes] TotalPagedPoolUsage: Cardinal;
    [Bytes] TotalNonPagedPoolUsage: Cardinal;
    [Bytes] TotalNamePoolUsage: Cardinal;
    [Bytes] TotalHandleTableUsage: Cardinal;
    HighWaterNumberOfObjects: Cardinal;
    HighWaterNumberOfHandles: Cardinal;
    [Bytes] HighWaterPagedPoolUsage: Cardinal;
    [Bytes] HighWaterNonPagedPoolUsage: Cardinal;
    [Bytes] HighWaterNamePoolUsage: Cardinal;
    [Bytes] HighWaterHandleTableUsage: Cardinal;
    InvalidAttributes: TObjectAttributesFlags;
    GenericMapping: TGenericMapping;
    ValidAccessMask: TAccessMask;
    SecurityRequired: Boolean;
    MaintainHandleCount: Boolean;
    TypeIndex: Byte;
    ReservedByte: Byte;
    PoolType: Cardinal;
    [Bytes] DefaultPagedPoolCharge: Cardinal;
    [Bytes] DefaultNonPagedPoolCharge: Cardinal;
  end;
  PObjectTypeInformation = ^TObjectTypeInformation;

  // PHNT::ntobapi.h - info class 3
  [SDKName('OBJECT_TYPES_INFORMATION')]
  TObjectTypesInformation = record
    NumberOfTypes: Cardinal;
    FirstEntry: TObjectTypeInformation;
    // + aligned array [0 .. NumberOfTypes - 1] of TObjectTypeInformation
  end;
  PObjectTypesInformation = ^TObjectTypesInformation;

  // PHNT::ntobapi.h - info class 4
  [SDKName('OBJECT_HANDLE_FLAG_INFORMATION')]
  TObjectHandleFlagInformation = record
    Inherit: Boolean;
    ProtectFromClose: Boolean;
  end;

  // PHNT::ntobapi.h
  [SDKName('OBJECT_DIRECTORY_INFORMATION')]
  TObjectDirectoryInformation = record
    Name: TNtUnicodeString;
    TypeName: TNtUnicodeString;
  end;
  PObjectDirectoryInformation = ^TObjectDirectoryInformation;

  // PHNT::ntobapi.h
  [SDKName('BOUNDARY_ENTRY_TYPE')]
  [NamingStyle(nsCamelCase, 'OBNS_')]
  TBoundaryEntryType = (
    OBNS_Invalid = 0,
    OBNS_Name = 1,
    OBNS_SID = 2,
    OBNS_IL = 3
  );

  // PHNT::ntobapi.h
  [SDKName('OBJECT_BOUNDARY_ENTRY')]
  TObjectBoundaryEntry = record
    EntryType: TBoundaryEntryType;
    [Bytes] EntrySize: Cardinal;
  end;

  [FlagName(BOUNDARY_DESCRIPTOR_ADD_APPCONTAINER_SID, 'Add AppContainer SID')]
  TBoundaryDescriptorFlags = type Cardinal;

  // PHNT::ntobapi.h
  [SDKName('OBJECT_BOUNDARY_DESCRIPTOR')]
  TObjectBoundaryDescriptor = record
    [Reserved(BOUNDARY_DESCRIPTOR_VERSION)] Version: Cardinal;
    [Counter(ctElements)] Items: Cardinal;
    [Counter(ctBytes)] TotalSize: Cardinal;
    Flags: TBoundaryDescriptorFlags;
  end;
  PObjectBoundaryDescriptor = ^TObjectBoundaryDescriptor;

  // NtApiDotNet::NtSymbolicLink.cs
  [MinOSVersion(OsWin10TH1)]
  [SDKName('SYMBOLIC_LINK_INFO_CLASS')]
  [NamingStyle(nsCamelCase, 'SymbolicLink'), Range(1)]
  TLinkInformationClass = (
    SymbolicLinkReserved = 0,
    SymbolicLinkGlobalInformation = 1, // s: LongBool
    SymbolicLinkAccessMask = 2         // s: TSymlinkAccessMask
  );

  // WDK::ntdef.h
  [NamingStyle(nsCamelCase, 'Wait')]
  TWaitType = (
    WaitAll = 0,
    WaitAny = 1,
    WaitNotification = 2
  );

{ Object }

// WDK::ntifs.h
function NtQueryObject(
  [in, Access(0)] ObjectHandle: THandle;
  [in] ObjectInformationClass: TObjectInformationClass;
  [out, WritesTo] ObjectInformation: Pointer;
  [in, NumberOfBytes] ObjectInformationLength: Cardinal;
  [out, opt, NumberOfBytes] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntobapi.h
function NtSetInformationObject(
  [in, Access(0)] Handle: THandle;
  [in] ObjectInformationClass: TObjectInformationClass;
  [in, ReadsFrom] ObjectInformation: Pointer;
  [in, NumberOfBytes] ObjectInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtDuplicateObject(
  [in, Access(PROCESS_DUP_HANDLE)] SourceProcessHandle: THandle;
  [in] SourceHandle: THandle;
  [in, Access(PROCESS_DUP_HANDLE)] TargetProcessHandle: THandle;
  [out, ReleaseWith('NtClose')] out TargetHandle: THandle;
  [in, opt] DesiredAccess: TAccessMask;
  [in, opt] HandleAttributes: TObjectAttributesFlags;
  [in] Options: TDuplicateOptions
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
[RequiredPrivilege(SE_CREATE_PERMANENT_PRIVILEGE, rpAlways)]
function NtMakeTemporaryObject(
  [in, Access(_DELETE)] Handle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntobapi.h
[Result: ReleaseWith('NtMakeTemporaryObject')]
[RequiredPrivilege(SE_CREATE_PERMANENT_PRIVILEGE, rpAlways)]
function NtMakePermanentObject(
  [in, Access(_DELETE)] Handle: THandle
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtWaitForSingleObject(
  [in, Access(SYNCHRONIZE)] Handle: THandle;
  [in] Alertable: LongBool;
  [in, opt] Timeout: PLargeInteger
): NTSTATUS; stdcall; external ntdll; overload;

// PHNT::ntobapi.h
function NtWaitForMultipleObjects(
  [in, NumberOfElements] Count: Cardinal;
  [in, ReadsFrom, Access(SYNCHRONIZE)] const Handles: TArray<THandle>;
  [in] WaitType: TWaitType;
  [in] Alertable: Boolean;
  [in, opt] Timeout: PLargeInteger
): NTSTATUS; stdcall; external ntdll; overload;

// WDK::ntifs.h
function NtSetSecurityObject(
  [in, Access(OBJECT_WRITE_SECURITY)] Handle: THandle;
  [in] SecurityInformation: TSecurityInformation;
  [in] SecurityDescriptor: PSecurityDescriptor
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtQuerySecurityObject(
  [in, Access(OBJECT_READ_SECURITY)] Handle: THandle;
  [in] SecurityInformation: TSecurityInformation;
  [out, WritesTo] SecurityDescriptor: PSecurityDescriptor;
  [in, NumberOfBytes] Length: Cardinal;
  [out, NumberOfBytes] out LengthNeeded: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtClose(
  [in] Handle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntobapi.h
[MinOSVersion(OsWin10TH1)]
function NtCompareObjects(
  [in, Access(0)] FirstObjectHandle: THandle;
  [in, Access(0)] SecondObjectHandle: THandle
): NTSTATUS; stdcall; external ntdll delayed;

{ Directory }

// WDK::wdm.h
function NtCreateDirectoryObject(
  [out, ReleaseWith('NtClose')] out DirectoryHandle: THandle;
  [in] DesiredAccess: TDirectoryAccessMask;
  [in] const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntobapi.h
[MinOSVersion(OsWin8)]
function NtCreateDirectoryObjectEx(
  [out, ReleaseWith('NtClose')] out DirectoryHandle: THandle;
  [in] DesiredAccess: TDirectoryAccessMask;
  [in] const ObjectAttributes: TObjectAttributes;
  [in, opt, Access(DIRECTORY_QUERY or DIRECTORY_TRAVERSE)]
    ShadowDirectoryHandle: THandle;
  [in] Flags: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

// WDK::ntifs.h
function NtOpenDirectoryObject(
  [out, ReleaseWith('NtClose')] out DirectoryHandle: THandle;
  [in] DesiredAccess: TDirectoryAccessMask;
  [in] const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntobapi.h
function NtQueryDirectoryObject(
  [in, Access(DIRECTORY_QUERY)] DirectoryHandle: THandle;
  [out, WritesTo] Buffer: Pointer;
  [in, NumberOfBytes] Length: Cardinal;
  [in] ReturnSingleEntry: Boolean;
  [in] RestartScan: Boolean;
  [in, out] var Context: Cardinal;
  [out, opt, NumberOfBytes] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

{ Private namespace }

// PHNT::ntrtl.h
[Result: MayReturnNil, ReleaseWith('RtlDeleteBoundaryDescriptor')]
function RtlCreateBoundaryDescriptor(
  [in] const Name: TNtUnicodeString;
  [in] Flags: TBoundaryDescriptorFlags
): PObjectBoundaryDescriptor; stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlDeleteBoundaryDescriptor(
  [in] BoundaryDescriptor: PObjectBoundaryDescriptor
); stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlAddSIDToBoundaryDescriptor(
  [in, out] var BoundaryDescriptor: PObjectBoundaryDescriptor;
  [in] RequiredSid: PSid
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlAddIntegrityLabelToBoundaryDescriptor(
  [in, out] var BoundaryDescriptor: PObjectBoundaryDescriptor;
  [in] IntegrityLabel: PSid
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntobapi.h
function NtCreatePrivateNamespace(
  [out, ReleaseWith('NtClose')] out NamespaceHandle: THandle;
  [in] DesiredAccess: TDirectoryAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in] BoundaryDescriptor: PObjectBoundaryDescriptor
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntobapi.h
function NtOpenPrivateNamespace(
  [out, ReleaseWith('NtClose')] out NamespaceHandle: THandle;
  [in] DesiredAccess: TDirectoryAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in] BoundaryDescriptor: PObjectBoundaryDescriptor
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntobapi.h
function NtDeletePrivateNamespace(
  [in] NamespaceHandle: THandle
): NTSTATUS; stdcall; external ntdll;

{ Symbolic link }

// PHNT::ntobapi.h
function NtCreateSymbolicLinkObject(
  [out, ReleaseWith('NtClose')] out LinkHandle: THandle;
  [in] DesiredAccess: TSymlinkAccessMask;
  [in] const ObjectAttributes: TObjectAttributes;
  [in] const LinkTarget: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtOpenSymbolicLinkObject(
  [out, ReleaseWith('NtClose')] out LinkHandle: THandle;
  [in] DesiredAccess: TSymlinkAccessMask;
  [in] const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtQuerySymbolicLinkObject(
  [in, Access(SYMBOLIC_LINK_QUERY)] LinkHandle: THandle;
  [in, out, WritesTo] var LinkTarget: TNtUnicodeString;
  [out, opt, NumberOfBytes] ReturnedLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// NtApiDotNet::NtSymbolicLink.cs
[MinOSVersion(OsWin10TH1)]
function NtSetInformationSymbolicLink(
  [in, Access(SYMBOLIC_LINK_SET)] LinkHandle: THandle;
  [in] LinkInformationClass: TLinkInformationClass;
  [in, ReadsFrom] LinkInformation: Pointer;
  [in, NumberOfBytes] LinkInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
