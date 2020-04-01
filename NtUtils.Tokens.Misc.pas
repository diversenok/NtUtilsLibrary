unit NtUtils.Tokens.Misc;

interface

uses
  Winapi.WinNt, Ntapi.ntseapi, NtUtils.Security.Sid, DelphiUtils.AutoObject;
function NtxpAllocPrivileges(Privileges: TArray<TLuid>; Attribute: Cardinal)
  : IMemory<PTokenPrivileges>;

function NtxpAllocPrivileges2(Privileges: TArray<TPrivilege>):
  IMemory<PTokenPrivileges>;

function NtxpAllocPrivilegeSet(Privileges: TArray<TPrivilege>):
  IMemory<PPrivilegeSet>;

function NtxpAllocGroups(Sids: TArray<ISid>; Attribute: Cardinal):
  IMemory<PTokenGroups>;

function NtxpAllocGroups2(Groups: TArray<TGroup>): IMemory<PTokenGroups>;

implementation

function NtxpAllocPrivileges(Privileges: TArray<TLuid>;
  Attribute: Cardinal): IMemory<PTokenPrivileges>;
var
  i: Integer;
begin
  Result := TAutoMemoryP.Allocate<PTokenPrivileges>(SizeOf(Integer) +
    Length(Privileges) * SizeOf(TLUIDAndAttributes));

  Result.Data.PrivilegeCount := Length(Privileges);

  for i := 0 to High(Privileges) do
  begin
    Result.Data.Privileges{$R-}[i]{$R+}.Luid := Privileges[i];
    Result.Data.Privileges{$R-}[i]{$R+}.Attributes := Attribute;
  end;
end;

function NtxpAllocPrivileges2(Privileges: TArray<TPrivilege>):
  IMemory<PTokenPrivileges>;
var
  i: Integer;
begin
  Result := TAutoMemoryP.Allocate<PTokenPrivileges>(SizeOf(Integer) +
    Length(Privileges) * SizeOf(TLUIDAndAttributes));

  Result.Data.PrivilegeCount := Length(Privileges);

  for i := 0 to High(Privileges) do
    Result.Data.Privileges{$R-}[i]{$R+} := Privileges[i];
end;

function NtxpAllocPrivilegeSet(Privileges: TArray<TPrivilege>):
  IMemory<PPrivilegeSet>;
var
  i: Integer;
begin
  Result := TAutoMemoryP.Allocate<PPrivilegeSet>(SizeOf(Cardinal) +
    SizeOf(Cardinal) + SizeOf(TLuidAndAttributes) * Length(Privileges));

  Result.Data.PrivilegeCount := Length(Privileges);
  Result.Data.Control := 0;

  for i := 0 to High(Privileges) do
    Result.Data.Privilege{$R-}[i]{$R+} := Privileges[i];
end;

function NtxpAllocGroups(Sids: TArray<ISid>; Attribute: Cardinal):
  IMemory<PTokenGroups>;
var
  i: Integer;
begin
  Result := TAutoMemoryP.Allocate<PTokenGroups>(SizeOf(Integer) +
    Length(Sids) * SizeOf(TSIDAndAttributes));

  Result.Data.GroupCount := Length(Sids);

  for i := 0 to High(Sids) do
  begin
    Result.Data.Groups{$R-}[i]{$R+}.Sid := Sids[i].Sid;
    Result.Data.Groups{$R-}[i]{$R+}.Attributes := Attribute;
  end;
end;

function NtxpAllocGroups2(Groups: TArray<TGroup>): IMemory<PTokenGroups>;
var
  i: Integer;
begin
  Result := TAutoMemoryP.Allocate<PTokenGroups>(SizeOf(Integer) +
    Length(Groups) * SizeOf(TSIDAndAttributes));

  Result.Data.GroupCount := Length(Groups);

  for i := 0 to High(Groups) do
  begin
    Result.Data.Groups{$R-}[i]{$R+}.Sid := Groups[i].SecurityIdentifier.Sid;
    Result.Data.Groups{$R-}[i]{$R+}.Attributes := Groups[i].Attributes;
  end;
end;

end.
