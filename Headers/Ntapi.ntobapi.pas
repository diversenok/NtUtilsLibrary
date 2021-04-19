unit Ntapi.ntobapi;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, DelphiApi.Reflection;

const
  DIRECTORY_QUERY = $0001;
  DIRECTORY_TRAVERSE = $0002;
  DIRECTORY_CREATE_OBJECT = $0004;
  DIRECTORY_CREATE_SUBDIRECTORY = $0008;
  DIRECTORY_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $000f;

  SYMBOLIC_LINK_QUERY = $0001;
  SYMBOLIC_LINK_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $0001;

  // wdm.7536
  DUPLICATE_CLOSE_SOURCE = $00000001;
  DUPLICATE_SAME_ACCESS = $00000002;
  DUPLICATE_SAME_ATTRIBUTES = $00000004;

  // rev
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
  TSymlinkAccessMask = type TAccessMask;

  [NamingStyle(nsCamelCase, 'Object')]
  TObjectInformationClass = (
    ObjectBasicInformation = 0,     // q: TObjectBasicInformaion
    ObjectNameInformation = 1,      // q: UNICODE_STRING
    ObjectTypeInformation = 2,      // q: TObjectTypeInformation
    ObjectTypesInformation = 3,     // q: TObjectTypesInformation + TObjectTypeInformation
    ObjectHandleFlagInformation = 4 // q+s: TObjectHandleFlagInformation
  );

  TObjectBasicInformaion = record
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
  PObjectBasicInformaion = ^TObjectBasicInformaion;

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

  TObjectTypesInformation = record
    NumberOfTypes: Cardinal;
    FirstEntry: TObjectTypeInformation;
    // + aligned array of [1..NumberOfTypes - 1] of TObjectTypeInformation
  end;
  PObjectTypesInformation = ^TObjectTypesInformation;

  TObjectHandleFlagInformation = record
    Inherit: Boolean;
    ProtectFromClose: Boolean;
  end;

  TObjectDirectoryInformation = record
    Name: TNtUnicodeString;
    TypeName: TNtUnicodeString;
  end;
  PObjectDirectoryInformation = ^TObjectDirectoryInformation;

  // ntdef
  [NamingStyle(nsCamelCase, 'Wait')]
  TWaitType = (
    WaitAll = 0,
    WaitAny = 1,
    WaitNotification = 2
  );

{ Object }

function NtQueryObject(
  ObjectHandle: THandle;
  ObjectInformationClass: TObjectInformationClass;
  [out] ObjectInformation: Pointer;
  ObjectInformationLength: Cardinal;
  [out, opt] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

function NtSetInformationObject(
  Handle: THandle;
  ObjectInformationClass: TObjectInformationClass;
  [in] ObjectInformation: Pointer;
  ObjectInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtDuplicateObject(
  SourceProcessHandle: THandle;
  SourceHandle: THandle;
  TargetProcessHandle: THandle;
  out TargetHandle: THandle;
  DesiredAccess: TAccessMask;
  HandleAttributes: TObjectAttributesFlags;
  Options: TDuplicateOptions
): NTSTATUS; stdcall; external ntdll;

function NtMakeTemporaryObject(
  Handle: THandle
): NTSTATUS; stdcall; external ntdll;

function NtMakePermanentObject(
  Handle: THandle
): NTSTATUS; stdcall; external ntdll;

function NtWaitForSingleObject(
  Handle: THandle;
  Alertable: LongBool;
  [in, opt] Timeout: PLargeInteger
): NTSTATUS; stdcall; external ntdll; overload;

function NtWaitForMultipleObjects(
  Count: Integer;
  Handles: TArray<THandle>;
  WaitType: TWaitType;
  Alertable: Boolean;
  [in, opt] Timeout: PLargeInteger
): NTSTATUS; stdcall; external ntdll; overload;

function NtSetSecurityObject(
  Handle: THandle;
  SecurityInformation: TSecurityInformation;
  [in] SecurityDescriptor: PSecurityDescriptor
): NTSTATUS; stdcall; external ntdll;

function NtQuerySecurityObject(
  Handle: THandle;
  SecurityInformation: TSecurityInformation;
  [out] SecurityDescriptor: PSecurityDescriptor;
  Length: Cardinal;
  out LengthNeeded: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtClose(
  Handle: THandle
): NTSTATUS; stdcall; external ntdll;

// Win 10 THRESHOLD+
function NtCompareObjects(
  FirstObjectHandle: THandle;
  SecondObjectHandle: THandle
): NTSTATUS; stdcall; external ntdll delayed;

{ Directory }

function NtCreateDirectoryObject(
  out DirectoryHandle: THandle;
  DesiredAccess: TDirectoryAccessMask;
  const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

function NtOpenDirectoryObject(
  out DirectoryHandle: THandle;
  DesiredAccess: TDirectoryAccessMask;
  const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

function NtQueryDirectoryObject(
  DirectoryHandle: THandle;
  [out] Buffer: Pointer;
  Length: Cardinal;
  ReturnSingleEntry: Boolean;
  RestartScan: Boolean;
  var Context: Cardinal;
  [out, opt] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

{ Symbolic link }

function NtCreateSymbolicLinkObject(
  out LinkHandle: THandle;
  DesiredAccess: TSymlinkAccessMask;
  const ObjectAttributes: TObjectAttributes;
  const LinkTarget: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

function NtOpenSymbolicLinkObject(
  out LinkHandle: THandle;
  DesiredAccess: TSymlinkAccessMask;
  const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

function NtQuerySymbolicLinkObject(
  LinkHandle: THandle;
  var LinkTarget: TNtUnicodeString;
  [out, opt] ReturnedLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

implementation

end.
