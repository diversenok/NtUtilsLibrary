unit NtUtils.Lpc;

{
  This module providers wrappers for using LPC/ALPC (local inter-process
  communication).
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntlpcapi, NtUtils, DelphiApi.Reflection;

// Connect to an LPC port
function NtxConnectPort(
  out hxPort: IHandle;
  const PortName: String;
  ImpersonationLevel: TSecurityImpersonationLevel = SecurityImpersonation;
  ContextTrackingMode: Boolean = False;
  EffectiveOnly: Boolean = False
): TNtxStatus;

// Send a message to an LPC port
function NtxRequestWaitReplyPort(
  const hxPort: IHandle;
  var Msg: TPortMessage
): TNtxStatus;

implementation

uses
  NtUtils.Objects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NtxConnectPort;
var
  PortNameStr: TNtUnicodeString;
  QoS: TSecurityQualityOfService;
  hPort: THandle;
begin
  Result := RtlxInitUnicodeString(PortNameStr, PortName);

  if not Result.IsSuccess then
    Exit;

  QoS.Length := SizeOf(QoS);
  QoS.ImpersonationLevel := ImpersonationLevel;
  QoS.ContextTrackingMode := ContextTrackingMode;
  QoS.EffectiveOnly := EffectiveOnly;

  Result.Location := 'NtConnectPort';
  Result.LastCall.Parameter := PortName;
  Result.Status := NtConnectPort(hPort, PortNameStr, QoS, nil, nil, nil, nil,
    nil);

  if Result.IsSuccess then
    hxPort := Auto.CaptureHandle(hPort);
end;

function NtxRequestWaitReplyPort;
begin
  Result.Location := 'NtRequestWaitReplyPort';
  Result.Status := NtRequestWaitReplyPort(HandleOrDefault(hxPort), Msg, Msg);
end;

end.
