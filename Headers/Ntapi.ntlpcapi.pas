unit Ntapi.ntlpcapi;

interface

uses
  Winapi.WinNt, DelphiApi.Reflection;

const
  PORT_CONNECT = $0001;
  PORT_ALL_ACCESS = STANDARD_RIGHTS_ALL or PORT_CONNECT;

type
  [FriendlyName('LPC port'), ValidMask(PORT_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(PORT_CONNECT, 'Connect')]
  TAlpcAccessMask = type TAccessMask;

implementation

end.
