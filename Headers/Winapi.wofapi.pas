unit Winapi.wofapi;

{$MINENUMSIZE 4}

interface

uses
  DelphiApi.Reflection;

const
  // ntifs.7786
  FSCTL_SET_EXTERNAL_BACKING = $0009030C;

  // ntifs.13234
  WOF_CURRENT_VERSION = 1;

  // ntifs.13326
  FILE_PROVIDER_CURRENT_VERSION = 1;
  FILE_PROVIDER_FLAG_COMPRESS_ON_WRITE = $0001;

type
  // ntifs.13236
  [NamingStyle(nsSnakeCase, 'WOF_PROVIDER')]
  TWofProvider = (
    WOF_PROVIDER_UNKNOWN = 0,
    WOF_PROVIDER_WIM = 1,
    WOF_PROVIDER_FILE = 2,
    WOF_PROVIDER_CLOUD = 3
  );

  // ntifs.13330
  [NamingStyle(nsSnakeCase, 'FILE_PROVIDER_COMPRESSION')]
  TFileProviderCompression = (
    FILE_PROVIDER_COMPRESSION_XPRESS4K = 0,
    FILE_PROVIDER_COMPRESSION_LZX = 1,
    FILE_PROVIDER_COMPRESSION_XPRESS8K = 2,
    FILE_PROVIDER_COMPRESSION_XPRESS16K = 3
  );

  // ntifs.13240
  TWofExternalInfo = record
    Version: Cardinal;
    Provider: TWofProvider;
  end;

  // ntifs.13334
  TFileProviderExternalInfoV1 = record
    WofInfo: TWofExternalInfo; // Embedded for convenience
    Version: Cardinal;
    Algorithm: TFileProviderCompression;
    Flags: Cardinal;
  end;

implementation

end.
