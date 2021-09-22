unit Ntapi.ntlpcapi;

interface

uses
  Ntapi.WinNt, DelphiApi.Reflection;

{$MINENUMSIZE 4}

const
  // PHNT::ntlpcapi.h - LPC port access masks
  PORT_CONNECT = $0001;
  PORT_ALL_ACCESS = STANDARD_RIGHTS_ALL or PORT_CONNECT;

type
  [FriendlyName('LPC port'), ValidMask(PORT_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(PORT_CONNECT, 'Connect')]
  TAlpcAccessMask = type TAccessMask;

implementation

end.
