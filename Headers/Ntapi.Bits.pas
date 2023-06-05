unit Ntapi.Bits;

{
  This module provides definitions for Background Intelligent Transfer Service.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, DelphiApi.Reflection;

const
  // SDK::Bits.h
  CLSID_BackgroundCopyManager: TGuid = '{4991D34B-80A1-4291-83B6-3328366B9097}';

const
  // SDK::Bits.h
  BG_NOTIFY_JOB_TRANSFERRED = $0001;
  BG_NOTIFY_JOB_ERROR = $0002;
  BG_NOTIFY_DISABLE = $0004;
  BG_NOTIFY_JOB_MODIFICATION = $0008;
  BG_NOTIFY_FILE_TRANSFERRED = $0010;
  BG_NOTIFY_FILE_RANGES_TRANSFERRED = $0020;

type
  // SDK::Bits.h
  [SDKName('BG_JOB_TYPE')]
  [NamingStyle(nsSnakeCase, 'BG_JOB_TYPE')]
  TBgJobType = (
    BG_JOB_TYPE_DOWNLOAD = 0,
    BG_JOB_TYPE_UPLOAD = 1,
    BG_JOB_TYPE_UPLOAD_REPLY = 2
  );

  // SDK::Bits.h
  [SDKName('BG_FILE_INFO')]
  TBgFileInfo = record
    RemoteName: PWideChar;
    LocalName: PWideChar;
  end;
  PBgFileInfo = ^TBgFileInfo;
  TBgFileInfoArray = TAnysizeArray<TBgFileInfo>;
  PBgFileInfoArray = ^TBgFileInfoArray;

  // SDK::Bits.h
  [SDKName('BG_JOB_PROGRESS')]
  TBgJobProgress = record
    [Bytes] BytesTotal: UInt64;
    [Bytes] BytesTransferred: UInt64;
    FilesTotal: Cardinal;
    FilesTransferred: Cardinal;
  end;
  PBgJobProgress = ^TBgJobProgress;

  // SDK::Bits.h
  [SDKName('BG_JOB_TIMES')]
  TBgJobTimes = record
    CreationTime: TLargeInteger;
    ModificationTime: TLargeInteger;
    TransferCompletionTime: TLargeInteger;
  end;
  PBgJobTimes = ^TBgJobTimes;

  // SDK::Bits.h
  [SDKName('BG_JOB_STATE')]
  [NamingStyle(nsSnakeCase, 'BG_JOB_STATE')]
  TBgJobState = (
    BG_JOB_STATE_QUEUED = 0,
    BG_JOB_STATE_CONNECTING = 1,
    BG_JOB_STATE_TRANSFERRING = 2,
    BG_JOB_STATE_SUSPENDED = 3,
    BG_JOB_STATE_ERROR = 4,
    BG_JOB_STATE_TRANSIENT_ERROR = 5,
    BG_JOB_STATE_TRANSFERRED = 6,
    BG_JOB_STATE_ACKNOWLEDGED = 7,
    BG_JOB_STATE_CANCELLED = 8
  );

  // SDK::Bits.h
  [SDKName('BG_JOB_PRIORITY')]
  [NamingStyle(nsSnakeCase, 'BG_JOB_PRIORITY')]
  TBgJobPriority = (
    BG_JOB_PRIORITY_FOREGROUND = 0,
    BG_JOB_PRIORITY_HIGH = 1,
    BG_JOB_PRIORITY_NORMAL = 2,
    BG_JOB_PRIORITY_LOW = 3
  );

  [FlagName(BG_NOTIFY_JOB_TRANSFERRED, 'Job Transferred')]
  [FlagName(BG_NOTIFY_JOB_ERROR, 'Job Error')]
  [FlagName(BG_NOTIFY_DISABLE, 'Disable')]
  [FlagName(BG_NOTIFY_JOB_MODIFICATION, 'Job Modification')]
  [FlagName(BG_NOTIFY_FILE_TRANSFERRED, 'File Transferred')]
  [FlagName(BG_NOTIFY_FILE_RANGES_TRANSFERRED, 'File Ranges Transferred')]
  TBgJobNotifyFlags = type Cardinal;

  // SDK::Bits.h
  [SDKName('BG_JOB_PROXY_USAGE')]
  TBgJobProxyUsage = (
    BG_JOB_PROXY_USAGE_PRECONFIG = 0,
    BG_JOB_PROXY_USAGE_NO_PROXY = 1,
    BG_JOB_PROXY_USAGE_OVERRIDE = 2,
    BG_JOB_PROXY_USAGE_AUTODETECT = 3
  );

  // SDK::Bits1_5.h
  [SDKName('BG_JOB_REPLY_PROGRESS')]
  TBgJobReplyProgress = record
    [Bytes] BytesTotal: UInt64;
    [Bytes] BytesTransferred: UInt64;
  end;
  PBgJobReplyProgress = ^TBgJobReplyProgress;

  IBackgroundCopyJob = interface;
  IEnumBackgroundCopyJobs = IUnknown;

  // SDK::Bits.h
  IBackgroundCopyManager = interface (IUnknown)
    ['{5ce34c0d-0dc9-4c1f-897c-daa1b78cee7c}']
    function CreateJob(
      [in] DisplayName: PWideChar;
      [in] JobType: TBgJobType;
      [out] out JobId: TGuid;
      [out] out Job: IBackgroundCopyJob
    ): HResult; stdcall;

    function GetJob(
      [in] const jobID: TGuid;
      [out] out Job: IBackgroundCopyJob
    ): HResult; stdcall;

    function EnumJobs(
      [in] Flags: Cardinal;
      [out] Enum: IEnumBackgroundCopyJobs
    ): HResult; stdcall;

    function GetErrorDescription(
      [in] Result: HResult;
      [in] LanguageId: Cardinal;
      [out, ReleaseWith('CoTaskMemFree')] out ErrorDescription: PWideChar
    ): HResult; stdcall;
  end;

  IEnumBackgroundCopyFiles = IUnknown;
  IBackgroundCopyError = IUnknown;

  // SDK::Bits.h
  IBackgroundCopyJob = interface (IUnknown)
    ['{37668d37-507e-4160-9316-26306d150b12}']

    function AddFileSet(
      [in, NumberOfElements] FileCount: Cardinal;
      [in, ReadsFrom] FileSet: PBgFileInfoArray
    ): HResult; stdcall;

    function AddFile(
      [in] RemoteUrl: PWideChar;
      [in] LocalName: PWideChar
    ): HResult; stdcall;

    function EnumFiles(
      [out] out Enum: IEnumBackgroundCopyFiles
    ): HResult; stdcall;

    function Suspend: HResult; stdcall;
    function Resume: HResult; stdcall;
    function Cancel: HResult; stdcall;
    function Complete: HResult; stdcall;

    function GetId(
      [out] out Val: TGuid
    ): HResult; stdcall;

    function GetType(
      [out] out Val: TBgJobType
    ): HResult; stdcall;

    function GetProgress(
      [out] out Val: TBgJobProgress
    ): HResult; stdcall;

    function GetTimes(
      [out] out Val: TBgJobTimes
    ): HResult; stdcall;

    function GetState(
      [out] out Val: TBgJobState
    ): HResult; stdcall;

    function GetError(
      [out] out Error: IBackgroundCopyError
    ): HResult; stdcall;

    function GetOwner(
      [out, ReleaseWith('CoTaskMemFree')] out Val: PWideChar
    ): HResult; stdcall;

    function SetDisplayName(
      [in] Val: PWideChar
    ): HResult; stdcall;

    function GetDisplayName(
      [out, ReleaseWith('CoTaskMemFree')] out Val: PWideChar
    ): HResult; stdcall;

    function SetDescription(
      [in] Val: PWideChar
    ): HResult; stdcall;

    function GetDescription(
      [out, ReleaseWith('CoTaskMemFree')] out Val: PWideChar
    ): HResult; stdcall;

    function SetPriority(
      [in] Val: TBgJobPriority
    ): HResult; stdcall;

    function GetPriority(
      [out] out Val: TBgJobPriority
    ): HResult; stdcall;

    function SetNotifyFlags(
      [in] Val: TBgJobNotifyFlags
    ): HResult; stdcall;

    function GetNotifyFlags(
      [out] out Val: TBgJobNotifyFlags
    ): HResult; stdcall;

    function SetNotifyInterface(
      [in] const Val: IUnknown
    ): HResult; stdcall;

    function GetNotifyInterface(
      [out] out Val: IUnknown
    ): HResult; stdcall;

    function SetMinimumRetryDelay(
      [in] Seconds: Cardinal
    ): HResult; stdcall;

    function GetMinimumRetryDelay(
      [out] out Seconds: Cardinal
    ): HResult; stdcall;

    function SetNoProgressTimeout(
      [in] Seconds: Cardinal
    ): HResult; stdcall;

    function GetNoProgressTimeout(
      [out] out Seconds: Cardinal
    ): HResult; stdcall;

    function GetErrorCount(
      [out] out Errors: Cardinal
    ): HResult; stdcall;

    function SetProxySettings(
      [in] ProxyUsage: TBgJobProxyUsage;
      [in] ProxyList: PWideChar;
      [in] ProxyBypassList: PWideChar
    ): HResult; stdcall;

    function GetProxySettings(
      [out] out ProxyUsage: TBgJobProxyUsage;
      [out, ReleaseWith('CoTaskMemFree')] out ProxyList: PWideChar;
      [out, ReleaseWith('CoTaskMemFree')] out ProxyBypassList: PWideChar
    ): HResult; stdcall;

    function TakeOwnership: HResult; stdcall;
  end;

  // SDK::Bits1_5.h
  IBackgroundCopyJob2 = interface (IBackgroundCopyJob)
    ['{54b50739-686f-45eb-9dff-d6a9a0faa9af}']
    function SetNotifyCmdLine(
      [in] ProgramPath: PWideChar;
      [in] Parameters: PWideChar
    ): HResult; stdcall;

    function GetNotifyCmdLine(
      [out, ReleaseWith('CoTaskMemFree')] out ProgramPath: PWideChar;
      [out, ReleaseWith('CoTaskMemFree')] out Parameters: PWideChar
    ): HResult; stdcall;

    function GetReplyProgress(
      [out] out Progress: TBgJobReplyProgress
    ): HResult; stdcall;

    function GetReplyData(
      [out, ReleaseWith('CoTaskMemFree')] out Buffer: Pointer;
      [out, NumberOfBytes] out Length: UInt64
    ): HResult; stdcall;

    function SetReplyFileName(
      [in] ReplyFileName: PWideChar
    ): HResult; stdcall;

    function GetReplyFileName(
      [out, ReleaseWith('CoTaskMemFree')] out ReplyFileName: PWideChar
    ): HResult; stdcall;

    function SetCredentials(
      [in] credentials: Pointer
    ): HResult; stdcall;

    function RemoveCredentials(
      [in] Target: Cardinal;
      [in] Scheme: Cardinal
    ): HResult; stdcall;
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
