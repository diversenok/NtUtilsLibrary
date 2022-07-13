unit NtUiLib.Exceptions;

{
  This module adds support for raising unsuccessful error codes as Delphi
  exceptions.
}

interface

uses
  NtUtils, System.SysUtils;

type
  // An exception type thrown by RaiseOnError method of TNtxStatus
  ENtError = class(EOSError)
  private
    xStatus: TNtxStatus;
  public
    constructor Create(const Status: TNtxStatus);
    property NtxStatus: TNtxStatus read xStatus;
  end;

implementation

uses
  NtUiLib.Errors;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ ENtError }

constructor ENtError.Create;
begin
  xStatus := Status;
  ErrorCode := Cardinal(Status.Win32Error);
  Message := Status.ToString;
end;

// A callback for raising NT exceptions via Status.RaiseOnError;
procedure NtxUiLibExceptionRaiser(const Status: TNtxStatus);
begin
  raise ENtError.Create(Status);
end;

initialization
  NtxExceptionRaiser := NtxUiLibExceptionRaiser;
finalization

end.
