unit Ntapi.ntlpcapi;

interface

uses
  Winapi.WinNt, DelphiApi.Reflection;

const
  PORT_CONNECT = $0001;
  PORT_ALL_ACCESS = STANDARD_RIGHTS_ALL or PORT_CONNECT;

  AlpcAccessMapping: array [0..0] of TFlagName = (
    (Value: PORT_CONNECT; Name: 'Connect')
  );

  AlpcAccessType: TAccessMaskType = (
    TypeName: 'ALPC port';
    FullAccess: PORT_ALL_ACCESS;
    Count: Length(AlpcAccessMapping);
    Mapping: PFlagNameRefs(@AlpcAccessMapping);
  );

implementation

end.
