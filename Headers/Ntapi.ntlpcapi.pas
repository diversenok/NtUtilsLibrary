unit Ntapi.ntlpcapi;

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, DelphiApi.Reflection;

{$MINENUMSIZE 4}

const
  // PHNT::ntlpcapi.h - LPC port access masks
  PORT_CONNECT = $0001;
  PORT_ALL_ACCESS = STANDARD_RIGHTS_ALL or PORT_CONNECT;

type
  [FriendlyName('LPC port'), ValidBits(PORT_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(PORT_CONNECT, 'Connect')]
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

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
