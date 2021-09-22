unit Ntapi.wofapi;

{
  This file includes structures for interacting with Windows Overlay Filter.
}

interface

{$MINENUMSIZE 4}

uses
  DelphiApi.Reflection;

const
  // WDK::ntifs.h
  FSCTL_SET_EXTERNAL_BACKING = $0009030C;
  FSCTL_GET_EXTERNAL_BACKING = $00090310;

  // WDK::ntifs.h
  WOF_CURRENT_VERSION = 1;

  // WDK::ntifs.h
  FILE_PROVIDER_CURRENT_VERSION = 1;
  FILE_PROVIDER_FLAG_COMPRESS_ON_WRITE = $0001;

type
  // WDK::ntifs.h
  [NamingStyle(nsSnakeCase, 'WOF_PROVIDER')]
  TWofProvider = (
    WOF_PROVIDER_UNKNOWN = 0,
    WOF_PROVIDER_WIM = 1,
    WOF_PROVIDER_FILE = 2,
    WOF_PROVIDER_CLOUD = 3
  );

  // WDK::ntifs.h
  [NamingStyle(nsSnakeCase, 'FILE_PROVIDER_COMPRESSION')]
  TFileProviderCompression = (
    FILE_PROVIDER_COMPRESSION_XPRESS4K = 0,
    FILE_PROVIDER_COMPRESSION_LZX = 1,
    FILE_PROVIDER_COMPRESSION_XPRESS8K = 2,
    FILE_PROVIDER_COMPRESSION_XPRESS16K = 3
  );

  // WDK::ntifs.h
  [SDKName('WOF_EXTERNAL_INFO')]
  TWofExternalInfo = record
    Version: Cardinal;
    Provider: TWofProvider;
  end;

  // WDK::ntifs.h
  [SDKName('FILE_PROVIDER_EXTERNAL_INFO_V1')]
  TFileProviderExternalInfoV1 = record
    WofInfo: TWofExternalInfo; // Embedded for convenience
    Version: Cardinal;
    Algorithm: TFileProviderCompression;
    Flags: Cardinal;
  end;
  PFileProviderExternalInfoV1 = ^TFileProviderExternalInfoV1;

implementation

end.
