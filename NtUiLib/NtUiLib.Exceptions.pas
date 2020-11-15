unit NtUiLib.Exceptions;

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

constructor ENtError.CreateNtx(const Status: TNtxStatus);
begin
  xStatus := Status;
  ErrorCode := Cardinal(Status.WinError);
  Message := Status.Location + ' returned ' + RtlxNtStatusName(Status);
end;

{ TNtxStatusHelper }

function TNtxStatusHelper.Description: String;
begin
  Result := RtlxNtStatusMessage(Self);
end;

procedure TNtxStatusHelper.RaiseOnError;
begin
  if not IsSuccess then
    raise ENtError.CreateNtx(Self);
end;

function TNtxStatusHelper.Summary: String;
begin
  Result := RtlxNtStatusSummary(Self)
end;

function TNtxStatusHelper.ToString: String;
begin
  Result := Location + ': ' + RtlxNtStatusName(Self);
end;

end.
