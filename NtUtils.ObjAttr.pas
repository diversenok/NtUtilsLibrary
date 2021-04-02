unit NtUtils.ObjAttr;

{
  This module provides implementation for the Object Attribute builder.
  You don't need to use it directly since NtUtils.pas already exports
  necessary routines.
}

interface

uses
  NtUtils;

// Create a new instance of Object Attributes builder
function NewAttributeBuilder: IObjectAttributes;

implementation

uses
  Winapi.WinNt, Ntapi.ntdef;

type
  TNtxObjectAttributes = class (TInterfacedObject, IObjectAttributes)
  private
    Body: TObjectAttributes;
    QoS: TSecurityQualityOfService;
    FRoot: IHandle;
    FName: String;
    FNameStr: TNtUnicodeString;
    FSecurity: ISecDesc;
    FAccessMask: TAccessMask;
  public
    // Fluent builder
    function UseRoot(const RootDirectory: IHandle): IObjectAttributes;
    function UseName(const ObjectName: String): IObjectAttributes;
    function UseAttributes(const Attributes: TObjectAttributesFlags): IObjectAttributes;
    function UseSecurity(const SecurityDescriptor: ISecDesc): IObjectAttributes;
    function UseImpersonation(const Level: TSecurityImpersonationLevel): IObjectAttributes;
    function UseEffectiveOnly(const Enabled: Boolean): IObjectAttributes;
    function UseDesiredAccess(const AccessMask: TAccessMask): IObjectAttributes;

    // Accessors
    function Root: IHandle;
    function Name: String;
    function Attributes: TObjectAttributesFlags;
    function Security: ISecDesc;
    function Impersonation: TSecurityImpersonationLevel;
    function EffectiveOnly: Boolean;
    function DesiredAccess: TAccessMask;

    // Integration
    function ToNative: PObjectAttributes;
    function Duplicate: IObjectAttributes;

    constructor Create;
  end;

function TNtxObjectAttributes.Attributes;
begin
  Result := Body.Attributes;
end;

constructor TNtxObjectAttributes.Create;
begin
  inherited;
  Body.Length := SizeOf(TObjectAttributes);
  QoS.Length := SizeOf(TSecurityQualityOfService);
end;

function TNtxObjectAttributes.DesiredAccess: TAccessMask;
begin
  Result := FAccessMask;
end;

function TNtxObjectAttributes.Duplicate: IObjectAttributes;
begin
  Result := NewAttributeBuilder()
    .UseRoot(Root)
    .UseName(Name)
    .UseAttributes(Attributes)
    .UseSecurity(Security)
    .UseImpersonation(Impersonation)
    .UseEffectiveOnly(EffectiveOnly);
end;

function TNtxObjectAttributes.EffectiveOnly;
begin
  Result := QoS.EffectiveOnly;
end;

function TNtxObjectAttributes.Impersonation;
begin
  Result := QoS.ImpersonationLevel;
end;

function TNtxObjectAttributes.Name;
begin
  Result := FName;
end;

function TNtxObjectAttributes.Root;
begin
  Result := FRoot;
end;

function TNtxObjectAttributes.Security;
begin
  Result := FSecurity;
end;

function TNtxObjectAttributes.ToNative;
begin
  Result := @Body;
end;

function TNtxObjectAttributes.UseAttributes;
begin
  Body.Attributes := Attributes;
  Result := Self;
end;

function TNtxObjectAttributes.UseDesiredAccess;
begin
  FAccessMask := AccessMask;
  Result := Self;
end;

function TNtxObjectAttributes.UseEffectiveOnly;
begin
  QoS.EffectiveOnly := Enabled;
  Body.SecurityQualityOfService := @QoS;
  Result := Self;
end;

function TNtxObjectAttributes.UseImpersonation;
begin
  QoS.ImpersonationLevel := Level;
  Body.SecurityQualityOfService := @QoS;
  Result := Self;
end;

function TNtxObjectAttributes.UseName;
begin
  FName := ObjectName;
  FNameStr := TNtUnicodeString.From(FName);

  if FNameStr.Length > 0 then
    Body.ObjectName := @FNameStr
  else
    Body.ObjectName := nil;

  Result := Self;
end;

function TNtxObjectAttributes.UseRoot;
begin
  FRoot := RootDirectory;

  if Assigned(FRoot) then
    Body.RootDirectory := FRoot.Handle
  else
    Body.RootDirectory := 0;

  Result := Self;
end;

function TNtxObjectAttributes.UseSecurity;
begin
  FSecurity := SecurityDescriptor;

  if Assigned(FSecurity) then
    Body.SecurityDescriptor := FSecurity.Data
  else
    Body.SecurityDescriptor := nil;

  Result := Self;
end;

function NewAttributeBuilder;
begin
  Result := TNtxObjectAttributes.Create;
end;

end.
