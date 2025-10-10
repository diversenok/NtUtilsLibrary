unit Ntapi.ntlpcapi;

{
  This file includes definitions for LPC/ALPC functions.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, DelphiApi.Reflection;

{$MINENUMSIZE 4}

const
  // PHNT::ntlpcapi.h - LPC port access masks
  PORT_CONNECT = $0001;
  PORT_ALL_ACCESS = STANDARD_RIGHTS_ALL or PORT_CONNECT;

  // PHNT::ntlpcapi.h - ALPC port attribute flags
  ALPC_PORFLG_LPC_MODE = $1000; // Kernel-only
  ALPC_PORFLG_ALLOW_IMPERSONATION = $10000;
  ALPC_PORFLG_ALLOW_LPC_REQUESTS = $20000;
  ALPC_PORFLG_WAITABLE_PORT = $40000;
  ALPC_PORFLG_ALLOW_DUP_OBJECT = $80000;
  ALPC_PORFLG_SYSTEM_PROCESS = $100000; // Kernel-only
  ALPC_PORFLG_WAKE_POLICY1 = $200000;
  ALPC_PORFLG_WAKE_POLICY2 = $400000;
  ALPC_PORFLG_WAKE_POLICY3 = $800000;
  ALPC_PORFLG_DIRECT_MESSAGE = $1000000;
  ALPC_PORFLG_ALLOW_MULTIHANDLE_ATTRIBUTE = $2000000;

  // PHNT::ntlpcapi.h - ALPC port attribute duplicate object types
  ALPC_PORFLG_OBJECT_TYPE_FILE = $0001;
  ALPC_PORFLG_OBJECT_TYPE_THREAD = $0004;
  ALPC_PORFLG_OBJECT_TYPE_SEMAPHORE = $0008;
  ALPC_PORFLG_OBJECT_TYPE_EVENT = $0010;
  ALPC_PORFLG_OBJECT_TYPE_PROCESS = $0020;
  ALPC_PORFLG_OBJECT_TYPE_MUTEX = $0040;
  ALPC_PORFLG_OBJECT_TYPE_SECTION = $0080;
  ALPC_PORFLG_OBJECT_TYPE_REGKEY = $0100;
  ALPC_PORFLG_OBJECT_TYPE_TOKEN = $0200;
  ALPC_PORFLG_OBJECT_TYPE_COMPOSITION = $0400;
  ALPC_PORFLG_OBJECT_TYPE_JOB = $0800;

  // PHNT::ntlpcapi.h - ALPC message attributes
  ALPC_MESSAGE_WORK_ON_BEHALF_ATTRIBUTE = $02000000; // rev
  ALPC_MESSAGE_DIRECT_ATTRIBUTE = $04000000; // rev
  ALPC_MESSAGE_TOKEN_ATTRIBUTE = $8000000; // rev
  ALPC_MESSAGE_HANDLE_ATTRIBUTE = $10000000;
  ALPC_MESSAGE_CONTEXT_ATTRIBUTE = $20000000;
  ALPC_MESSAGE_VIEW_ATTRIBUTE = $40000000;
  ALPC_MESSAGE_SECURITY_ATTRIBUTE = $80000000;

  // PHNT::ntlpcapi.h - ALPC message flags
  ALPC_MSGFLG_REPLY_MESSAGE = $00000001;
  ALPC_MSGFLG_LPC_MODE = $00000002;
  ALPC_MSGFLG_RELEASE_MESSAGE = $00010000;
  ALPC_MSGFLG_SYNC_REQUEST = $00020000;
  ALPC_MSGFLG_TRACK_PORT_REFERENCES = $00040000;
  ALPC_MSGFLG_WAIT_USER_MODE = $00100000;
  ALPC_MSGFLG_WAIT_ALERTABLE = $00200000;
  ALPC_MSGFLG_WOW64_CALL = $080000000;

type
  [FriendlyName('ALPC port'), ValidMask(PORT_ALL_ACCESS)]
  [SubEnum(PORT_ALL_ACCESS, PORT_ALL_ACCESS, 'Full Access')]
  [FlagName(PORT_CONNECT, 'Connect')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
  TAlpcAccessMask = type TAccessMask;

  TPortMessageUnion1 = record
  case Integer of
    0: (DataLength: Word; TotalLength: Word);
    1: (Length: Cardinal);
  end;

  TPortMessageUnion2 = record
  case Integer of
    0: (_Type: Word; DataInfoOffset: Word);
    1: (ZeroInit: Cardinal);
  end;

  TPortMessageUnion4 = record
  case Integer of
    0: (ClientViewSize: NativeUInt);
    1: (CallbackId: Cardinal);
  end;

  // PHNT::ntlpcapi.h
  [SDKName('PORT_MESSAGE')]
  TPortMessage = record
    u1: TPortMessageUnion1;
    u2: TPortMessageUnion2;
    ClientId: TClientId;
    MessageId: Cardinal;
    u4: TPortMessageUnion4;
  end;
  PPortMessage = ^TPortMessage;

  // PHNT::ntlpcapi.h
  [SDKName('PORT_VIEW')]
  TPortView = record
    [RecordSize] Length: Cardinal;
    SectionHandle: THandle;
    SectionOffset: Cardinal;
    ViewSize: NativeUInt;
    ViewBase: Pointer;
    ViewRemoteBase: Pointer;
  end;
  PPortView = ^TPortView;

  // PHNT::ntlpcapi.h
  [SDKName('REMOTE_PORT_VIEW')]
  TRemotePortView = record
    [RecordSize] Length: Cardinal;
    ViewSize: NativeUInt;
    ViewBase: Pointer;
  end;
  PRemotePortView = ^TRemotePortView;

  { ALPC }

  [FlagName(ALPC_PORFLG_LPC_MODE, 'LPC Mode')]
  [FlagName(ALPC_PORFLG_ALLOW_IMPERSONATION, 'Allow Impersonation')]
  [FlagName(ALPC_PORFLG_ALLOW_LPC_REQUESTS, 'Allow LPC Requests')]
  [FlagName(ALPC_PORFLG_WAITABLE_PORT, 'Waitable Port')]
  [FlagName(ALPC_PORFLG_ALLOW_DUP_OBJECT, 'Allod Duplicate Object')]
  [FlagName(ALPC_PORFLG_SYSTEM_PROCESS, 'System Process')]
  [FlagName(ALPC_PORFLG_WAKE_POLICY1, 'Wake Policy 1')]
  [FlagName(ALPC_PORFLG_WAKE_POLICY2, 'Wake Policy 2')]
  [FlagName(ALPC_PORFLG_WAKE_POLICY3, 'Wake Policy 3')]
  [FlagName(ALPC_PORFLG_DIRECT_MESSAGE, 'Direct Message')]
  [FlagName(ALPC_PORFLG_ALLOW_MULTIHANDLE_ATTRIBUTE, 'Allow Multi-handle Attribute')]
  TAlpcPortFlags = type Cardinal;

  [FlagName(ALPC_PORFLG_OBJECT_TYPE_FILE, 'File')]
  [FlagName(ALPC_PORFLG_OBJECT_TYPE_THREAD, 'Thread')]
  [FlagName(ALPC_PORFLG_OBJECT_TYPE_SEMAPHORE, 'Semaphore')]
  [FlagName(ALPC_PORFLG_OBJECT_TYPE_EVENT, 'Event')]
  [FlagName(ALPC_PORFLG_OBJECT_TYPE_PROCESS, 'Process')]
  [FlagName(ALPC_PORFLG_OBJECT_TYPE_MUTEX, 'Mutex')]
  [FlagName(ALPC_PORFLG_OBJECT_TYPE_SECTION, 'Section')]
  [FlagName(ALPC_PORFLG_OBJECT_TYPE_REGKEY, 'Registry Key')]
  [FlagName(ALPC_PORFLG_OBJECT_TYPE_TOKEN, 'Token')]
  [FlagName(ALPC_PORFLG_OBJECT_TYPE_COMPOSITION, 'Composition')]
  [FlagName(ALPC_PORFLG_OBJECT_TYPE_JOB, 'Job')]
  TAlpcPortDupObjectTypes = type Cardinal;

  // PHNT::ntlpcapi.h
  [SDKName('ALPC_PORT_ATTRIBUTES')]
  TAlpcPortAttributes = record
    Flags: TAlpcPortFlags;
    SecurityQos: TSecurityQualityOfService;
    MaxMessageLength: NativeUInt;
    MemoryBandwidth: NativeUInt;
    MaxPoolUsage: NativeUInt;
    MaxSectionSize: NativeUInt;
    MaxViewSize: NativeUInt;
    MaxTotalSectionSize: NativeUInt;
    DupObjectTypes: TAlpcPortDupObjectTypes;
  end;
  PAlpcPortAttributes = ^TAlpcPortAttributes;

  [FlagName(ALPC_MESSAGE_WORK_ON_BEHALF_ATTRIBUTE, 'Work-on-behalf')]
  [FlagName(ALPC_MESSAGE_DIRECT_ATTRIBUTE, 'Direct')]
  [FlagName(ALPC_MESSAGE_TOKEN_ATTRIBUTE, 'Token')]
  [FlagName(ALPC_MESSAGE_HANDLE_ATTRIBUTE, 'Handle')]
  [FlagName(ALPC_MESSAGE_CONTEXT_ATTRIBUTE, 'Context')]
  [FlagName(ALPC_MESSAGE_VIEW_ATTRIBUTE, 'View')]
  [FlagName(ALPC_MESSAGE_SECURITY_ATTRIBUTE, 'Security')]
  TAlpcMessageAttributeFlags = type Cardinal;

  // PHNT::ntlpcapi.h
  [SDKName('ALPC_MESSAGE_ATTRIBUTES')]
  TAlpcMessageAttributes = record
    AllocatedAttributes: TAlpcMessageAttributeFlags;
    ValidAttributes: TAlpcMessageAttributeFlags;
  end;
  PAlpcMessageAttributes = ^TAlpcMessageAttributes;

  [FlagName(ALPC_MSGFLG_REPLY_MESSAGE, 'Reply Message')]
  [FlagName(ALPC_MSGFLG_LPC_MODE, 'LPC Mode')]
  [FlagName(ALPC_MSGFLG_RELEASE_MESSAGE, 'Release Message')]
  [FlagName(ALPC_MSGFLG_SYNC_REQUEST, 'Synchronous Request')]
  [FlagName(ALPC_MSGFLG_TRACK_PORT_REFERENCES, 'Track Port References')]
  [FlagName(ALPC_MSGFLG_WAIT_USER_MODE, 'Wait User Mode')]
  [FlagName(ALPC_MSGFLG_WAIT_ALERTABLE, 'Wait Alertable')]
  [FlagName(ALPC_MSGFLG_WOW64_CALL, 'WoW64 Call')]
  TAlpcMessageFlags = type Cardinal;

// PHNT::ntlpcapi.h
function NtConnectPort(
  [out, ReleaseWith('NtClose')] out PortHandle: THandle;
  [in] const PortName: TNtUnicodeString;
  [in] const SecurityQos: TSecurityQualityOfService;
  [in, out, opt] ClientView: PPortView;
  [in, out, opt] ServerView: PRemotePortView;
  [out, opt] MaxMessageLength: PCardinal;
  [in, out, opt, ReadsFrom, WritesTo] ConnectionInformation: Pointer;
  [in, out, opt, NumberOfBytes] ConnectionInformationLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntlpcapi.h
function NtRequestWaitReplyPort(
  [in] PortHandle: THandle;
  [in, ReadsFrom] const RequestMessage: TPortMessage;
  [out, WritesTo] out ReplyMessage: TPortMessage
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntlpcapi.h
function NtAlpcConnectPort(
  [out, ReleaseWith('NtClose')] out PortHandle: THandle;
  [in] const PortName: TNtUnicodeString;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in, opt] PortAttributes: PAlpcPortAttributes;
  [in] Flags: TAlpcMessageFlags;
  [in, opt] RequiredServerSid: PSid;
  [in, out, opt, ReadsFrom, WritesTo] ConnectionMessage: PPortMessage;
  [in, out, opt, NumberOfBytes] BufferLength: PNativeUInt;
  [in, out, opt] OutMessageAttributes: PAlpcMessageAttributes;
  [in, out, opt] InMessageAttributes: PAlpcMessageAttributes;
  [in, opt] Timeout: PLargeInteger
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntlpcapi.h
function NtAlpcSendWaitReceivePort(
  [in] PortHandle: THandle;
  [in] Flags: TAlpcMessageFlags;
  [in, out, ReadsFrom, WritesTo] SendMessage: PPortMessage;
  [in, out, opt] SendMessageAttributes: PAlpcMessageAttributes;
  [out, opt, WritesTo] ReceiveMessage: PPortMessage;
  [in, out, opt, NumberOfBytes] BufferLength: PNativeUInt;
  [in, out, opt] ReceiveMessageAttributes: PAlpcMessageAttributes;
  [in, opt] Timeout: PLargeInteger
): NTSTATUS; stdcall; external ntdll;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
