unit Ntapi.VirtDisk;

{
  This file provides definitions for the low-level virtual disk API.
}

interface

uses
  Ntapi.WinNt, DelphiApi.Reflection;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

const
  // rev
  VDRVROOT_DEVICE_NAME = '\Global??\VDRVROOT';
  VHDMP_DEVICE_NAME = '\Device\VHDMP';

  // rev
  VIRTUAL_DISK_EA_NAME = 'VIRTDSK';

  // SDK::virtdisk.h
  VIRTUAL_STORAGE_TYPE_VENDOR_MICROSOFT: TGuid = '{EC984AEC-A0F9-47E9-901F-71415A66345B}';

  // rev - IOCTLS for VDRVROOT
  IOCTL_STORAGE_QUERY_VIRTUAL_DISK_SYMBOLIC_LINK = $002D592C; // in: TStorageQueryVirtualDiskSymbolicLinkRequest; out: TStorageQueryVirtualDiskSymbolicLinkResponse

  // rev - IOCTLS for VHDMP
  IOCTL_STORAGE_SURFACE_VIRTUAL_DISK = $002D191C; // in: TStorageSurfaceVirtualDiskRequest
  IOCTL_STORAGE_UNSURFACE_VIRTUAL_DISK = $002D1920; // in: TStorageUnsurfaceVirtualDiskRequest
  IOCTL_STORAGE_QUERY_VIRTUAL_DISK_NAME = $002D1934; // in: TStorageQueryVirtualDiskNameRequest; our: TStorageQueryVirtualDiskNameResponse

  // private
  GUID_DEVINTERFACE_SURFACE_VIRTUAL_DRIVE: TGuid = '{2E34D650-5819-42CA-84AE-D30803BAE505}';

  // SDK::virtdisk.h - open access masks
  VIRTUAL_DISK_ACCESS_ATTACH_RO = $00010000;
  VIRTUAL_DISK_ACCESS_ATTACH_RW = $00020000;
  VIRTUAL_DISK_ACCESS_DETACH = $00040000;
  VIRTUAL_DISK_ACCESS_GET_INFO = $00080000;
  VIRTUAL_DISK_ACCESS_CREATE = $00100000;
  VIRTUAL_DISK_ACCESS_METAOPS = $00200000;

  VIRTUAL_DISK_ACCESS_READ = $000D0000;
  VIRTUAL_DISK_ACCESS_WRITABLE = $00320000;
  VIRTUAL_DISK_ACCESS_ALL = $003F0000;

  // SDK::virtdisk.h - open flags
  OPEN_VIRTUAL_DISK_FLAG_NO_PARENTS = $00000001;
  OPEN_VIRTUAL_DISK_FLAG_BLANK_FILE = $00000002;
  OPEN_VIRTUAL_DISK_FLAG_BOOT_DRIVE = $00000004;
  OPEN_VIRTUAL_DISK_FLAG_CACHED_IO = $00000008;
  OPEN_VIRTUAL_DISK_FLAG_CUSTOM_DIFF_CHAIN = $00000010;
  OPEN_VIRTUAL_DISK_FLAG_PARENT_CACHED_IO = $00000020;
  OPEN_VIRTUAL_DISK_FLAG_VHDSET_FILE_ONLY = $00000040;
  OPEN_VIRTUAL_DISK_FLAG_IGNORE_RELATIVE_PARENT_LOCATOR = $00000080;
  OPEN_VIRTUAL_DISK_FLAG_NO_WRITE_HARDENING = $00000100;
  OPEN_VIRTUAL_DISK_FLAG_SUPPORT_COMPRESSED_VOLUMES = $00000200;
  OPEN_VIRTUAL_DISK_FLAG_SUPPORT_SPARSE_FILES_ANY_FS = $00000400;
  OPEN_VIRTUAL_DISK_FLAG_SUPPORT_ENCRYPTED_FILES = $00000800;

  // SDK::virtdisk.h - open R/W depth
  OPEN_VIRTUAL_DISK_RW_DEPTH_DEFAULT = 1;

  // SDK::virtdisk.h - attach flags
  ATTACH_VIRTUAL_DISK_FLAG_READ_ONLY = $00000001;
  ATTACH_VIRTUAL_DISK_FLAG_NO_DRIVE_LETTER = $00000002;
  ATTACH_VIRTUAL_DISK_FLAG_PERMANENT_LIFETIME = $00000004;
  ATTACH_VIRTUAL_DISK_FLAG_NO_LOCAL_HOST = $00000008;
  ATTACH_VIRTUAL_DISK_FLAG_NO_SECURITY_DESCRIPTOR = $00000010;
  ATTACH_VIRTUAL_DISK_FLAG_BYPASS_DEFAULT_ENCRYPTION_POLICY = $00000020;
  ATTACH_VIRTUAL_DISK_FLAG_NON_PNP = $00000040;
  ATTACH_VIRTUAL_DISK_FLAG_RESTRICTED_RANGE = $00000080;
  ATTACH_VIRTUAL_DISK_FLAG_SINGLE_PARTITION = $00000100;
  ATTACH_VIRTUAL_DISK_FLAG_REGISTER_VOLUME = $00000200;
  ATTACH_VIRTUAL_DISK_FLAG_AT_BOOT = $00000400;

type
  // SDK::virtdisk.h
  [NamingStyle(nsSnakeCase, 'VIRTUAL_STORAGE_TYPE_DEVICE')]
  TVirtualStorageDeviceId = (
    VIRTUAL_STORAGE_TYPE_DEVICE_UNKNOWN = 0,
    VIRTUAL_STORAGE_TYPE_DEVICE_ISO = 1,
    VIRTUAL_STORAGE_TYPE_DEVICE_VHD = 2,
    VIRTUAL_STORAGE_TYPE_DEVICE_VHDX = 3,
    VIRTUAL_STORAGE_TYPE_DEVICE_VHDSET = 4
  );

  // SDK::virtdisk.h
  [SDKName('VIRTUAL_STORAGE_TYPE')]
  TVirtualStorageType = record
    DeviceId: TVirtualStorageDeviceId;
    VendorId: TGuid;
  end;
  PVirtualStorageType = ^TVirtualStorageType;

  [SDKName('VIRTUAL_DISK_ACCESS_MASK')]
  [SubEnum(VIRTUAL_DISK_ACCESS_ALL, VIRTUAL_DISK_ACCESS_ALL, 'Full Access')]
  [FlagName(VIRTUAL_DISK_ACCESS_ATTACH_RO, 'Attach Readonly')]
  [FlagName(VIRTUAL_DISK_ACCESS_ATTACH_RW, 'Attach RW')]
  [FlagName(VIRTUAL_DISK_ACCESS_DETACH, 'Detach')]
  [FlagName(VIRTUAL_DISK_ACCESS_GET_INFO, 'Get Info')]
  [FlagName(VIRTUAL_DISK_ACCESS_CREATE, 'Create')]
  [FlagName(VIRTUAL_DISK_ACCESS_METAOPS, 'Meta Operations')]
  [FlagName(VIRTUAL_DISK_ACCESS_READ, 'Read')]
  TVirtualDiskAccessMask = type Cardinal;

  [SDKName('OPEN_VIRTUAL_DISK_FLAG')]
  [FlagName(OPEN_VIRTUAL_DISK_FLAG_NO_PARENTS, 'No Parents')]
  [FlagName(OPEN_VIRTUAL_DISK_FLAG_BLANK_FILE, 'Blank File')]
  [FlagName(OPEN_VIRTUAL_DISK_FLAG_BOOT_DRIVE, 'Boot Drive')]
  [FlagName(OPEN_VIRTUAL_DISK_FLAG_CACHED_IO, 'Cached I/O')]
  [FlagName(OPEN_VIRTUAL_DISK_FLAG_CUSTOM_DIFF_CHAIN, 'Custom Diff Chain')]
  [FlagName(OPEN_VIRTUAL_DISK_FLAG_PARENT_CACHED_IO, 'Parent Cached I/O')]
  [FlagName(OPEN_VIRTUAL_DISK_FLAG_VHDSET_FILE_ONLY, 'VhdSet File Only')]
  [FlagName(OPEN_VIRTUAL_DISK_FLAG_IGNORE_RELATIVE_PARENT_LOCATOR, 'Ignore Relative Parent Locator')]
  [FlagName(OPEN_VIRTUAL_DISK_FLAG_NO_WRITE_HARDENING, 'No Write Hardening')]
  [FlagName(OPEN_VIRTUAL_DISK_FLAG_SUPPORT_COMPRESSED_VOLUMES, 'Support Compressed Volumes')]
  [FlagName(OPEN_VIRTUAL_DISK_FLAG_SUPPORT_SPARSE_FILES_ANY_FS, 'Support Sparse Files')]
  [FlagName(OPEN_VIRTUAL_DISK_FLAG_SUPPORT_ENCRYPTED_FILES, 'Support Encrypted Files')]
  TOpenVirtualDiskFlags = type Cardinal;

  [SDKName('ATTACH_VIRTUAL_DISK_FLAG')]
  [FlagName(ATTACH_VIRTUAL_DISK_FLAG_READ_ONLY, 'Readonly')]
  [FlagName(ATTACH_VIRTUAL_DISK_FLAG_NO_DRIVE_LETTER, 'No Drive Letter')]
  [FlagName(ATTACH_VIRTUAL_DISK_FLAG_PERMANENT_LIFETIME, 'Permanent Lifetime')]
  [FlagName(ATTACH_VIRTUAL_DISK_FLAG_NO_LOCAL_HOST, 'No Local Host')]
  [FlagName(ATTACH_VIRTUAL_DISK_FLAG_NO_SECURITY_DESCRIPTOR, 'No Security Descriptor')]
  [FlagName(ATTACH_VIRTUAL_DISK_FLAG_BYPASS_DEFAULT_ENCRYPTION_POLICY, 'Bypass Default Encryption Policy')]
  [FlagName(ATTACH_VIRTUAL_DISK_FLAG_NON_PNP, 'No PnP')]
  [FlagName(ATTACH_VIRTUAL_DISK_FLAG_RESTRICTED_RANGE, 'RestrictedRange')]
  [FlagName(ATTACH_VIRTUAL_DISK_FLAG_SINGLE_PARTITION, 'Single Partition')]
  [FlagName(ATTACH_VIRTUAL_DISK_FLAG_REGISTER_VOLUME, 'Register Volume')]
  [FlagName(ATTACH_VIRTUAL_DISK_FLAG_AT_BOOT, 'At Boot')]
  TAttachVirtualDiskFlags = type Cardinal;

  // private
  [SDKName('VIRTUAL_DISK_EA_BUFFER')]
  TVirtualDiskEaBuffer = record
    Identifier: TGuid;
    VirtualStorageType: TVirtualStorageType;
    EASize: Cardinal;
    Flags: TOpenVirtualDiskFlags;
    AccessMask: TVirtualDiskAccessMask;
    RWDepth: Cardinal;
    Version: Cardinal;
    GetInfoOnly: Cardinal;
    ReadOnly: Cardinal;
    AlternateOpenId: TGuid;
    AlternateOpenType: Byte;
  end;
  PVirtualDiskEaBuffer = ^TVirtualDiskEaBuffer;

  // private
  [SDKName('STORAGE_QUERY_VIRTUAL_DISK_SYMBOLIC_LINK_LEV1_REQUEST')]
  TStorageQueryVirtualDiskSymbolicLinkRequest = record
    RequestLevel: Cardinal;
    VirtualStorageType: TVirtualStorageType;
    [Offset] FileNameOffset: Cardinal; // to WideChar[]
    [NumberOfBytes] FileNameLength: Cardinal;
  end;
  PStorageQueryVirtualDiskSymbolicLinkRequest = ^TStorageQueryVirtualDiskSymbolicLinkRequest;

  // private
  [SDKName('STORAGE_QUERY_VIRTUAL_DISK_SYMBOLIC_LINK_LEV1_RESPONSE')]
  TStorageQueryVirtualDiskSymbolicLinkResponse = record
    VirtualStorageType: TVirtualStorageType;
    [Offset] SymbolicLinkOffset: Cardinal; // to WideChar[]
    [NumberOfBytes] SymbolicLinkLength: Cardinal;
  end;
  PStorageQueryVirtualDiskSymbolicLinkResponse = ^TStorageQueryVirtualDiskSymbolicLinkResponse;

  // private + rev
  [SDKName('STORAGE_SURFACE_VIRTUAL_DISK_LEV1_REQUEST')]
  TStorageSurfaceVirtualDiskRequest = record
    RequestLevel: Cardinal;
    Flags: TAttachVirtualDiskFlags;
    [Hex] ProviderFlags: Cardinal;
    [Offset] SecurityDescriptorOffset: Cardinal;
    [NumberOfBytes] SecurityDescriptorLength: Cardinal;
    [Hex] InternalReservedFlags: Word;
    CacheMode: Word;
    QoSFlowId: TGuid;
    [Offset] RestrictedOffset: UInt64; // since ?
    [NumberOfBytes] RestrictedLength: UInt64; // since ?
  end;
  PStorageSurfaceVirtualDiskRequest = ^TStorageSurfaceVirtualDiskRequest;

  // private
  [SDKName('STORAGE_UNSURFACE_VIRTUAL_DISK_LEV1_REQUEST')]
  TStorageUnsurfaceVirtualDiskRequest = record
    RequestLevel: Cardinal;
    [Hex] Flags: Cardinal;
    [Hex] ProviderFlags: Cardinal;
  end;
  PStorageUnsurfaceVirtualDiskRequest = ^TStorageUnsurfaceVirtualDiskRequest;

  // private
  [SDKName('STORAGE_QUERY_VIRTUAL_DISK_NAME_LEV1_REQUEST')]
  TStorageQueryVirtualDiskNameRequest = record
    RequestLevel: Cardinal;
  end;
  PStorageQueryVirtualDiskNameRequest = ^TStorageQueryVirtualDiskNameRequest;

  // private
  [SDKName('STORAGE_QUERY_VIRTUAL_DISK_NAME_LEV1_RESPONSE')]
  TStorageQueryVirtualDiskNameResponse = record
    [Offset] VirtualDiskDeviceNameOffset: Cardinal;
    [NumberOfBytes] VirtualDiskDeviceNameLength: Cardinal;
  end;
  PStorageQueryVirtualDiskNameResponse = ^TStorageQueryVirtualDiskNameResponse;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
