unit NtUiLib.Exceptions;

{
  This module adds support for raising unsuccessful error codes as exceptions.
}

interface

uses
  NtUtils, System.SysUtils;

type
  ENtError = class(EOSError)
  private
    xStatus: TNtxStatus;
  public
    constructor CreateNtx(const Status: TNtxStatus);
    property NtxStatus: TNtxStatus read xStatus;
  end;

  TNtxStatusHelper = record helper for TNtxStatus
    procedure RaiseOnError; inline;
    function ToString: String;
    function Description: String;
    function Summary: String;
  end;

implementation

uses
  NtUiLib.Errors;

{ ENtError }

constructor ENtError.CreateNtx;
begin
  xStatus := Status;
  ErrorCode := Cardinal(Status.Win32Error);
  Message := Status.Location + ' returned ' + RtlxNtStatusName(Status.Status);
end;

{ TNtxStatusHelper }

function TNtxStatusHelper.Description;
begin
  Result := RtlxNtStatusMessage(Self.Status);
end;

procedure TNtxStatusHelper.RaiseOnError;
begin
  if not IsSuccess then
    raise ENtError.CreateNtx(Self);
end;

function TNtxStatusHelper.Summary;
begin
  Result := RtlxNtStatusSummary(Self.Status)
end;

function TNtxStatusHelper.ToString;
begin
  Result := Location + ': ' + RtlxNtStatusName(Self.Status);
end;

end.
