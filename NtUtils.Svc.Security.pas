unit NtUtils.Svc.Security;

interface

uses
  Winapi.WinNt, Winapi.Svc, NtUtils, NtUtils.Security.Acl, NtUtils.Security.Sid,
  DelphiUtils.AutoObject;

type
  TAce = NtUtils.Security.Acl.TAce;
  IAcl = NtUtils.Security.Acl.IAcl;
  TAcl = NtUtils.Security.Acl.TAcl;
  ISid = NtUtils.Security.Sid.ISid;

{ Query security }

// Security descriptor
function ScmxQuerySecurityObject(ScmHandle: TScmHandle; SecurityInformation:
  TSecurityInformation; out SecDesc: IMemory<PSecurityDescriptor>): TNtxStatus;

// Owner
function ScmxQueryOwnerObject(ScmHandle: TScmHandle; out Owner: ISid):
  TNtxStatus;

// Primary group
function ScmxQueryPrimaryGroupObject(ScmHandle: TScmHandle;
  out PrimaryGroup: ISid): TNtxStatus;

// DACL
function ScmxQueryDaclObject(ScmHandle: TScmHandle; out Dacl: IAcl): TNtxStatus;

// SACL
function ScmxQuerySaclObject(ScmHandle: TScmHandle; out Sacl: IAcl): TNtxStatus;

// Mandatory label
function ScmxQueryLabelObject(ScmHandle: TScmHandle; out Sacl: IAcl):
  TNtxStatus;

{ Set security }

// Security descriptor
function ScmxSetSecurityObject(ScmHandle: TScmHandle; SecInfo:
  TSecurityInformation; const SecDesc: TSecurityDescriptor): TNtxStatus;

// Owner
function ScmxSetOwnerObject(ScmHandle: TScmHandle; Owner: ISid): TNtxStatus;

// Primary group
function ScmxSetPrimaryGroupObject(ScmHandle: TScmHandle; Group: ISid):
  TNtxStatus;

// DACL
function ScmxSetDaclObject(ScmHandle: TScmHandle; Dacl: IAcl): TNtxStatus;

// SACL
function ScmxSetSaclObject(ScmHandle: TScmHandle; Sacl: IAcl): TNtxStatus;

// Mandatory label
function ScmxSetLabelObject(ScmHandle: TScmHandle; Sacl: IAcl): TNtxStatus;

implementation

uses
  Ntapi.ntrtl;

// Security descriptor
function ScmxQuerySecurityObject(ScmHandle: TScmHandle; SecurityInformation:
  TSecurityInformation; out SecDesc: IMemory<PSecurityDescriptor>): TNtxStatus;
var
  xMemory: IMemory;
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceObjectSecurity';
  Result.LastCall.Expects(RtlxComputeReadAccess(SecurityInformation),
    @NonSpecificAccessType);

  xMemory := TAutoMemory.Allocate(0);
  repeat
    Required := 0;
    Result.Win32Result := QueryServiceObjectSecurity(ScmHandle,
      SecurityInformation, xMemory.Data, xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, nil);

  if Result.IsSuccess then
    SecDesc := xMemory as IMemory<PSecurityDescriptor>;
end;

// Owner
function ScmxQueryOwnerObject(ScmHandle: TScmHandle; out Owner: ISid):
  TNtxStatus;
var
  pSD: IMemory<PSecurityDescriptor>;
begin
  Result := ScmxQuerySecurityObject(ScmHandle, OWNER_SECURITY_INFORMATION, pSD);

  if Result.IsSuccess then
    Result := RtlxGetOwnerSD(pSD.Data, Owner);
end;

// Primary group
function ScmxQueryPrimaryGroupObject(ScmHandle: TScmHandle;
  out PrimaryGroup: ISid): TNtxStatus;
var
  pSD: IMemory<PSecurityDescriptor>;begin
  Result := ScmxQuerySecurityObject(ScmHandle, GROUP_SECURITY_INFORMATION, pSD);

  if Result.IsSuccess then
    Result := RtlxGetPrimaryGroupSD(pSD.Data, PrimaryGroup);
end;

// DACL
function ScmxQueryDaclObject(ScmHandle: TScmHandle; out Dacl: IAcl): TNtxStatus;
var
  pSD: IMemory<PSecurityDescriptor>;
begin
  Result := ScmxQuerySecurityObject(ScmHandle, DACL_SECURITY_INFORMATION, pSD);

  if Result.IsSuccess then
    Result := RtlxGetDaclSD(pSD.Data, Dacl);
end;

// SACL
function ScmxQuerySaclObject(ScmHandle: TScmHandle; out Sacl: IAcl): TNtxStatus;
var
  pSD: IMemory<PSecurityDescriptor>;
begin
  Result := ScmxQuerySecurityObject(ScmHandle, SACL_SECURITY_INFORMATION, pSD);

  if Result.IsSuccess then
    Result := RtlxGetSaclSD(pSD.Data, Sacl);
end;

// Mandatory label
function ScmxQueryLabelObject(ScmHandle: TScmHandle; out Sacl: IAcl):
  TNtxStatus;
var
  pSD: IMemory<PSecurityDescriptor>;
begin
  Result := ScmxQuerySecurityObject(ScmHandle, LABEL_SECURITY_INFORMATION, pSD);

  if Result.IsSuccess then
    Result := RtlxGetSaclSD(pSD.Data, Sacl);
end;

{ Set security }

// Security descriptor
function ScmxSetSecurityObject(ScmHandle: TScmHandle; SecInfo:
  TSecurityInformation; const SecDesc: TSecurityDescriptor): TNtxStatus;
begin
  Result.Location := 'SetServiceObjectSecurity';
  Result.LastCall.Expects(RtlxComputeWriteAccess(SecInfo),
    @NonSpecificAccessType);

  Result.Win32Result := SetServiceObjectSecurity(ScmHandle, SecInfo, SecDesc);
end;

// Owner
function ScmxSetOwnerObject(ScmHandle: TScmHandle; Owner: ISid): TNtxStatus;
var
  SD: TSecurityDescriptor;
begin
  Result := RtlxPrepareOwnerSD(SD, Owner);

  if Result.IsSuccess then
    Result := ScmxSetSecurityObject(ScmHandle, OWNER_SECURITY_INFORMATION, SD);
end;

// Primary group
function ScmxSetPrimaryGroupObject(ScmHandle: TScmHandle; Group: ISid):
  TNtxStatus;
var
  SD: TSecurityDescriptor;
begin
  Result := RtlxPreparePrimaryGroupSD(SD, Group);

  if Result.IsSuccess then
    Result := ScmxSetSecurityObject(ScmHandle, GROUP_SECURITY_INFORMATION, SD);
end;

// DACL
function ScmxSetDaclObject(ScmHandle: TScmHandle; Dacl: IAcl): TNtxStatus;
var
  SD: TSecurityDescriptor;
begin
  Result := RtlxPrepareDaclSD(SD, Dacl);

  if Result.IsSuccess then
    Result := ScmxSetSecurityObject(ScmHandle, DACL_SECURITY_INFORMATION, SD);
end;

// SACL
function ScmxSetSaclObject(ScmHandle: TScmHandle; Sacl: IAcl): TNtxStatus;
var
  SD: TSecurityDescriptor;
begin
  Result := RtlxPrepareSaclSD(SD, Sacl);

  if Result.IsSuccess then
    Result := ScmxSetSecurityObject(ScmHandle, SACL_SECURITY_INFORMATION, SD);
end;

// Mandatory label
function ScmxSetLabelObject(ScmHandle: TScmHandle; Sacl: IAcl): TNtxStatus;
var
  SD: TSecurityDescriptor;
begin
  Result := RtlxPrepareSaclSD(SD, Sacl);

  if Result.IsSuccess then
    Result := ScmxSetSecurityObject(ScmHandle, LABEL_SECURITY_INFORMATION, SD);
end;

end.
