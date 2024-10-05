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

type
  [FriendlyName('ALPC port'), ValidBits(PORT_ALL_ACCESS)]
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

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
