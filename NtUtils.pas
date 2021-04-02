unit NtUtils;

{
  Base definitions for the NtUtils library.
}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, Winapi.WinError,
  DelphiUtils.AutoObject;

const
  BUFFER_LIMIT = 1024 * 1024 * 256; // 256 MB

  // For NTSTATUS, indicates that the underlying error is comes from an HRESULT;
  // For HRESULT, indicates that the underlying error is comes from an NTSTATUS.
  FACILITY_SWAP_BIT = Winapi.WinError.FACILITY_NT_BIT;

  // From ntapi.ntstatus
  STATUS_SUCCESS = NTSTATUS(0);

type
  // Forward the types for automatic lifetime management
  TMemory = DelphiUtils.AutoObject.TMemory;
  IMemory = DelphiUtils.AutoObject.IMemory;
  IMem = DelphiUtils.AutoObject.IMem;
  TAutoMemory = DelphiUtils.AutoObject.TAutoMemory;
  IAutoReleasable = DelphiUtils.AutoObject.IAutoReleasable;
  TDelayedOperation = DelphiUtils.AutoObject.TDelayedOperation;
  IHandle = DelphiUtils.AutoObject.IHandle;

  // Define commonly used IMemory aliases
  IEnvironment = IMemory<PEnvironment>;
  ISecDesc = IMemory<PSecurityDescriptor>;
  IAcl = IMemory<PAcl>;
  ISid = IMemory<PSid>;

  // A Delphi wrapper for a commonly used OBJECT_ATTRIBUTES type that allows
  // building it with a simplified (fluent) syntaxt.
  IObjectAttributes = interface
    // Fluent builder
    function UseRoot(const RootDirectory: IHandle): IObjectAttributes;
    function UseName(const ObjectName: String): IObjectAttributes;
    function UseAttributes(const Attributes: TObjectAttributesFlags): IObjectAttributes;
    function UseSecurity(const SecurityDescriptor: ISecDesc): IObjectAttributes;
    function UseImpersonation(const Level: TSecurityImpersonationLevel = SecurityImpersonation): IObjectAttributes;
    function UseEffectiveOnly(const Enabled: Boolean = True): IObjectAttributes;
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
  end;

  TGroup = record
    Sid: ISid;
    Attributes: TGroupAttributes;
  end;

  TLastCallType = (lcOtherCall, lcOpenCall, lcQuerySetCall);

  TExpectedAccess = record
    AccessMask: TAccessMask;
    AccessMaskType: Pointer;
  end;

  TLastCallInfo = record
    Location: String;
    ExpectedPrivilege: TSeWellKnownPrivilege;
    ExpectedAccess: array of TExpectedAccess;
    procedure Expects<T>(AccessMask: T);
    procedure AttachInfoClass<T>(InfoClassEnum: T);
    procedure AttachAccess<T>(Mask: T);
  case CallType: TLastCallType of
    lcOpenCall:
      (AccessMask: TAccessMask; AccessMaskType: Pointer);
    lcQuerySetCall:
      (InfoClass: Cardinal; InfoClassType: Pointer);
  end;

  /// <summary>
  ///  An enhanced NTSTATUS that stores the location of the failure.
  /// </summary>
  TNtxStatus = record
  private
    FStatus: NTSTATUS;
    function GetWinError: TWin32Error;
    procedure SetWinError(const Value: TWin32Error);
    procedure FromLastWin32(RetValue: Boolean);
    procedure SetLocation(Value: String); inline;
    function GetHResult: HRESULT;
    procedure SetHResult(const Value: HRESULT);
    function GetCanonicalStatus: NTSTATUS;
    function GetLocation: String;
  public
    LastCall: TLastCallInfo;

    function IsSuccess: Boolean; inline;
    function IsWin32: Boolean;
    function IsHResult: Boolean;

    property Status: NTSTATUS read FStatus write FStatus;
    property WinError: TWin32Error read GetWinError write SetWinError;
    property HResult: HRESULT read GetHResult write SetHResult;

    property Win32Result: Boolean write FromLastWin32;
    property CanonicalStatus: NTSTATUS read GetCanonicalStatus;
    property Location: String read GetLocation write SetLocation;
    function Matches(Status: NTSTATUS; Location: String): Boolean; inline;
  end;

  TBufferGrowthMethod = function (
    Memory: IMemory;
    Required: NativeUInt
  ): NativeUInt;

// Slightly adjust required size with + 12% to mitigate fluctuations
function Grow12Percent(Memory: IMemory; Required: NativeUInt): NativeUInt;

function NtxExpandBufferEx(
  var Status: TNtxStatus;
  var Memory: IMemory;
  Required: NativeUInt;
  GrowthMetod: TBufferGrowthMethod
): Boolean;

{ Object Attributes }

// Use an existing or create a new instance of an object attribute builder.
function AttributeBuilder(
  const ObjAttributes: IObjectAttributes = nil
): IObjectAttributes;

// Make a copy of an object attribute builder or create a new instance
function AttributeBuilderCopy(
  const ObjAttributes: IObjectAttributes = nil
): IObjectAttributes;

// Get an NT object attribute pointer from an interfaced object attributes
function AttributesRefOrNil(
  const ObjAttributes: IObjectAttributes
): PObjectAttributes;

// Let the caller override a default access mask via Object Attributes when
// creating kernel objects.
function AccessMaskOverride(
  DefaultAccess: TAccessMask;
  const ObjAttributes: IObjectAttributes
): TAccessMask;

implementation

uses
  Ntapi.ntrtl, Ntapi.ntstatus, NtUtils.ObjAttr, NtUtils.Errors;

{ Object Attributes }

function AttributeBuilder;
begin
  if Assigned(ObjAttributes) then
    Result := ObjAttributes
  else
    Result := NewAttributeBuilder;
end;

function AttributeBuilderCopy;
begin
  if Assigned(ObjAttributes) then
    Result := ObjAttributes.Duplicate
  else
    Result := NewAttributeBuilder;
end;

function AttributesRefOrNil;
begin
  if Assigned(ObjAttributes) then
    Result := ObjAttributes.ToNative
  else
    Result := nil;
end;

function AccessMaskOverride;
begin
  if Assigned(ObjAttributes) and (ObjAttributes.DesiredAccess <> 0) then
    Result := ObjAttributes.DesiredAccess
  else
    Result := DefaultAccess;
end;

{ TLastCallInfo }

procedure TLastCallInfo.AttachAccess<T>;
var
  AsAccessMask: TAccessMask absolute Mask;
begin
  CallType := lcOpenCall;
  AccessMask := AsAccessMask;
  AccessMaskType := TypeInfo(T);
end;

procedure TLastCallInfo.AttachInfoClass<T>;
var
  AsByte: Byte absolute InfoClassEnum;
  AsWord: Word absolute InfoClassEnum;
  AsCardinal: Cardinal absolute InfoClassEnum;
begin
  CallType := lcQuerySetCall;
  InfoClassType := TypeInfo(T);

  case SizeOf(T) of
    SizeOf(Byte):     InfoClass := AsByte;
    SizeOf(Word):     InfoClass := AsWord;
    SizeOf(Cardinal): InfoClass := AsCardinal;
  end;
end;

procedure TLastCallInfo.Expects<T>;
var
  Mask: TAccessMask absolute AccessMask;
begin
  if Mask = 0 then
    Exit;

  // Add new access mask
  SetLength(ExpectedAccess, Length(ExpectedAccess) + 1);
  ExpectedAccess[High(ExpectedAccess)].AccessMask := Mask;
  ExpectedAccess[High(ExpectedAccess)].AccessMaskType := TypeInfo(T);
end;

{ TNtxStatus }

procedure TNtxStatus.FromLastWin32;
begin
  if RetValue then
    Status := STATUS_SUCCESS
  else
  begin
    Status := RtlxGetLastNtStatus;

    // Make sure that we do not end up with a successful code on failure
    if IsSuccess then
      SetWinError(RtlGetLastWin32Error);
  end;
end;

function TNtxStatus.GetCanonicalStatus;
begin
  Result := Status.Canonicalize;
end;

function TNtxStatus.GetHResult;
begin
  Result := Status.ToHResult;
end;

function TNtxStatus.GetLocation: String;
begin
  Result := LastCall.Location;
end;

function TNtxStatus.GetWinError;
begin
  Result := Status.ToWin32Error;
end;

function TNtxStatus.IsHResult;
begin
  Result := Status.IsHResult;
end;

function TNtxStatus.IsSuccess;
begin
  Result := Integer(Status) >= 0; // inlined NT_SUCCESS / Succeeded
end;

function TNtxStatus.IsWin32;
begin
  Result := Status.IsWin32Error;
end;

function TNtxStatus.Matches;
begin
  Result := (Self.Status = Status) and (Self.Location = Location);
end;

procedure TNtxStatus.SetHResult;
begin
  Status := Value.ToNtStatus;
end;

procedure TNtxStatus.SetLocation;
begin
  LastCall := Default(TLastCallInfo);
  LastCall.Location := Value;
end;

procedure TNtxStatus.SetWinError;
begin
  Status := WinError.ToNtStatus;
end;

{ Functions }

function Grow12Percent;
begin
  Result := Required;
  Inc(Result, Result shr 3);
end;

function NtxExpandBufferEx;
begin
  // True means continue; False means break from the loop
  Result := False;

  case Status.Status of
    STATUS_INFO_LENGTH_MISMATCH, STATUS_BUFFER_TOO_SMALL,
    STATUS_BUFFER_OVERFLOW:
    begin
      // Grow the buffer with provided callback
      if Assigned(GrowthMetod) then
        Required := GrowthMetod(Memory, Required);

      // The buffer should always grow, not shrink
      if (Assigned(Memory) and (Required <= Memory.Size)) or (Required = 0) then
        Exit(False);

      // Check for the limitation
      if Required > BUFFER_LIMIT then
      begin
        Status.Location := 'NtxExpandBufferEx';
        Status.Status := STATUS_IMPLEMENTATION_LIMIT;
        Exit(False);
      end;

      Memory := TAutoMemory.Allocate(Required);
      Result := True;
    end;
  end;
end;

end.
