unit NtUtils;

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
  TMemory = DelphiUtils.AutoObject.TMemory;
  IMemory = DelphiUtils.AutoObject.IMemory;
  TAutoMemory = DelphiUtils.AutoObject.TAutoMemory;
  IAutoReleasable = DelphiUtils.AutoObject.IAutoReleasable;
  TDelayedOperation = DelphiUtils.AutoObject.TDelayedOperation;
  IHandle = DelphiUtils.AutoObject.IHandle;

  IEnvironment = IMemory<PEnvironment>;
  ISecDesc = IMemory<PSecurityDescriptor>;
  IAcl = IMemory<PAcl>;
  ISid = IMemory<PSid>;

  IObjectAttributes = interface
    function UseRoot(const RootDirectory: IHandle): IObjectAttributes;
    function UseName(const ObjectName: String): IObjectAttributes;
    function UseAttributes(const Attributes: TObjectAttributesFlags): IObjectAttributes;
    function UseSecurity(const SecurityDescriptor: ISecDesc): IObjectAttributes;
    function UseImpersonation(const Level: TSecurityImpersonationLevel = SecurityImpersonation): IObjectAttributes;
    function UseEffectiveOnly(const Enabled: Boolean = True): IObjectAttributes;
    function ToNative: PObjectAttributes;
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
    ExpectedPrivilege: TSeWellKnownPrivilege;
    ExpectedAccess: array of TExpectedAccess;
    procedure Expects<T>(AccessMask: T);
    procedure AttachInfoClass<T>(InfoClassEnum: T);
    procedure AttachAccess<T>(Mask: TAccessMask);
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
    FLocation: String;
    function GetWinError: TWin32Error;
    procedure SetWinError(const Value: TWin32Error);
    procedure FromLastWin32(RetValue: Boolean);
    procedure SetLocation(Value: String); inline;
    function GetHResult: HRESULT;
    procedure SetHResult(const Value: HRESULT);
    function GetCanonicalStatus: NTSTATUS;
  public
    Status: NTSTATUS;
    LastCall: TLastCallInfo;
    function IsSuccess: Boolean; inline;
    function IsWin32: Boolean; inline;
    function IsHResult: Boolean; inline;
    property WinError: TWin32Error read GetWinError write SetWinError;
    property HResult: HRESULT read GetHResult write SetHResult;
    property Win32Result: Boolean write FromLastWin32;
    property CanonicalStatus: NTSTATUS read GetCanonicalStatus;
    property Location: String read FLocation write SetLocation;
    function Matches(Status: NTSTATUS; Location: String): Boolean; inline;
  end;

  TBufferGrowthMethod = function (Memory: IMemory; Required: NativeUInt):
    NativeUInt;

// RtlGetLastNtStatus with extra checks to ensure the result is correct
function RtlxGetLastNtStatus: NTSTATUS;

// Slightly adjust required size with + 12% to mitigate fluctuations
function Grow12Percent(Memory: IMemory; Required: NativeUInt): NativeUInt;

function NtxExpandBufferEx(var Status: TNtxStatus; var Memory: IMemory;
  Required: NativeUInt; GrowthMetod: TBufferGrowthMethod): Boolean;

// Use an existing or create a new instance of an object attribute builder.
function AttributeBuilder(const ObjAttributes: IObjectAttributes = nil):
  IObjectAttributes;

// Get an NT object attribute pointer from an interfaced object attributes
function AttributesRefOrNil(const ObjAttributes: IObjectAttributes):
  PObjectAttributes;

implementation

uses
  Ntapi.ntrtl, Ntapi.ntstatus;

type
  TNtxObjectAttributes = class (TInterfacedObject, IObjectAttributes)
  private
    ObjAttr: TObjectAttributes;
    hxRootDirectory: IHandle;
    Name: String;
    NameStr: TNtUnicodeString;
    Security: ISecDesc;
    QoS: TSecurityQualityOfService;
  public
    function UseRoot(const RootDirectory: IHandle): IObjectAttributes;
    function UseName(const ObjectName: String): IObjectAttributes;
    function UseAttributes(const Attributes: TObjectAttributesFlags): IObjectAttributes;
    function UseSecurity(const SecurityDescriptor: ISecDesc): IObjectAttributes;
    function UseImpersonation(const Level: TSecurityImpersonationLevel): IObjectAttributes;
    function UseEffectiveOnly(const Enabled: Boolean): IObjectAttributes;
    function ToNative: PObjectAttributes;
    constructor Create;
  end;

{ TNtxObjectAttributes }

constructor TNtxObjectAttributes.Create;
begin
  inherited;
  ObjAttr.Length := SizeOf(TObjectAttributes);
  QoS.Length := SizeOf(TSecurityQualityOfService);
end;

function TNtxObjectAttributes.ToNative: PObjectAttributes;
begin
  Result := @ObjAttr;
end;

function TNtxObjectAttributes.UseAttributes(const Attributes:
  TObjectAttributesFlags): IObjectAttributes;
begin
  ObjAttr.Attributes := Attributes;
  Result := Self;
end;

function TNtxObjectAttributes.UseEffectiveOnly(const Enabled: Boolean):
  IObjectAttributes;
begin
  QoS.EffectiveOnly := Enabled;
  ObjAttr.SecurityQualityOfService := @QoS;
  Result := Self;
end;

function TNtxObjectAttributes.UseImpersonation(const Level:
  TSecurityImpersonationLevel): IObjectAttributes;
begin
  QoS.ImpersonationLevel := Level;
  ObjAttr.SecurityQualityOfService := @QoS;
  Result := Self;
end;

function TNtxObjectAttributes.UseName(const ObjectName: String):
  IObjectAttributes;
begin
  Name := ObjectName;
  NameStr := TNtUnicodeString.From(Name);
  ObjAttr.ObjectName := @NameStr;
  Result := Self;
end;

function TNtxObjectAttributes.UseRoot(const RootDirectory: IHandle):
  IObjectAttributes;
begin
  hxRootDirectory := RootDirectory;

  if Assigned(hxRootDirectory) then
    ObjAttr.RootDirectory := hxRootDirectory.Handle;

  Result := Self;
end;

function TNtxObjectAttributes.UseSecurity(const SecurityDescriptor: ISecDesc):
  IObjectAttributes;
begin
  Security := SecurityDescriptor;

  if Assigned(Security) then
    ObjAttr.SecurityDescriptor := Security.Data;

  Result := Self;
end;

function AttributeBuilder(const ObjAttributes: IObjectAttributes):
  IObjectAttributes;
begin
  if Assigned(ObjAttributes) then
    Result := ObjAttributes
  else
    Result := TNtxObjectAttributes.Create;
end;

function AttributesRefOrNil(const ObjAttributes: IObjectAttributes):
  PObjectAttributes;
begin
  if Assigned(ObjAttributes) then
    Result := ObjAttributes.ToNative
  else
    Result := nil;
end;

{ TLastCallInfo }

procedure TLastCallInfo.AttachAccess<T>(Mask: TAccessMask);
begin
  CallType := lcOpenCall;
  AccessMask := Mask;
  AccessMaskType := TypeInfo(T);
end;

procedure TLastCallInfo.AttachInfoClass<T>(InfoClassEnum: T);
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

procedure TLastCallInfo.Expects<T>(AccessMask: T);
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

procedure TNtxStatus.FromLastWin32(RetValue: Boolean);
begin
  if RetValue then
    Status := STATUS_SUCCESS
  else
  begin
    Status := RtlxGetLastNtStatus;

    // Make sure that we do not end up with a successful code
    if IsSuccess then
      SetWinError(RtlGetLastWin32Error);
  end;
end;

function TNtxStatus.GetCanonicalStatus: NTSTATUS;
begin
  // Win32 Error can appear embedded into HRESULts or NTSTATUSes.
  // The canonical representation we chose is inside an HRESULT which we store
  // as an NTSTATUS.

  if IsWin32 then
    Result := WIN32_HRESULT_BITS or FACILITY_SWAP_BIT or
      (WinError and WIN32_CODE_MASK)
  else
    Result := Status;
end;

function TNtxStatus.GetHResult: HRESULT;
begin
  // If the status has the Win32 Facility, then it was derived from a Win32
  // error. The HRESULT should be 0x8007xxxx in this case.

  // Statuses with a FACILITY_SWAP_BIT were derived from HRESULTs.
  // To get the original HRESULT back by removing this bit.

  // Statuses without the FACILITY_SWAP_BIT are native NTSTATUS codes.
  // Setting this bit (which, in case of HRESULTs, is called the NT Facility
  // bit) yeilds a valid HRESULT derived from an NTSTATUS.

  if IsWin32 then
    Cardinal(Result) := WIN32_HRESULT_BITS or (Status and WIN32_CODE_MASK)
  else
    Cardinal(Result) := Status xor FACILITY_SWAP_BIT;
end;

function TNtxStatus.GetWinError: TWin32Error;
begin
  // If the status comes from a Win32 error, reconstruct it
  if IsWin32 then
    Result := Status and WIN32_CODE_MASK

  // The status is a native NTSTATUS, ask ntdll to map it.
  else if not IsHResult then
    Result := RtlNtStatusToDosErrorNoTeb(Status)

  // A successful code that we do not know how to convert
  else if IsSuccess then
    Result := ERROR_SUCCESS

  // The original code comes from an HRESULT; even though it's not a Win32
  // error, they are reasonably compatible, so we can use them interchangeably
  // when formatting error messages.
  else
    Result := TWin32Error(HResult)
end;

function TNtxStatus.IsHResult: Boolean;
begin
  // Just like HRESULTs can store NTSTATUSes using the NT Facility bit, we make
  // NTSTATUSes store HRESULTs using the same bit. We call it a swap bit.

  Result := Status and FACILITY_SWAP_BIT <> 0;
end;

function TNtxStatus.IsSuccess: Boolean;
begin
  Result := Integer(Status) >= 0; // inlined NT_SUCCESS / Succeeded
end;

function TNtxStatus.IsWin32: Boolean;
begin
  // Regardles of whether the status is a native NTSTATUS or a converted HRESULT,
  // Win32 Facility indicates that the error originally comes from Win32.

  Result := Status and HRESULT_FACILITY_MASK = FACILITY_WIN32_BITS;
end;

function TNtxStatus.Matches(Status: NTSTATUS; Location: String): Boolean;
begin
  Result := (Self.Status = Status) and (Self.Location = Location);
end;

procedure TNtxStatus.SetHResult(const Value: HRESULT);
begin
  // If the HRESULT does not have the NT Facility bit (which we also call a
  // swap bit), set it to indicate that our NTSTATUS comes from an HRESULT.

  // If the HRESULT does include this bit, then it was derived from an NTSTATUS.
  // Clear it to get the status back.

  Status := Cardinal(Value) xor FACILITY_SWAP_BIT;
end;

procedure TNtxStatus.SetLocation(Value: String);
begin
  FLocation := Value;
  LastCall := Default(TLastCallInfo);
end;

procedure TNtxStatus.SetWinError(const Value: TWin32Error);
begin
  // Although Win32 errors are supposed to positive be 16-bit values, if we
  // encounter a negative error, it is clearly an HRESULT.
  if Integer(Value) < 0 then
    Status := FACILITY_SWAP_BIT or Value
  else
    // We have two options: we can embed the error into an NTSTATUS or an
    // HRESULT. Prefer the latter as a general rule.
    Status := WIN32_HRESULT_BITS or FACILITY_SWAP_BIT or
      (Value and WIN32_CODE_MASK);
end;

{ Functions }

function Grow12Percent(Memory: IMemory; Required: NativeUInt): NativeUInt;
begin
  Result := Required;
  Inc(Result, Result shr 3);
end;

function NtxExpandBufferEx(var Status: TNtxStatus; var Memory: IMemory;
  Required: NativeUInt; GrowthMetod: TBufferGrowthMethod): Boolean;
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

function RtlxGetLastNtStatus: NTSTATUS;
begin
  // If the last Win32 error was set using RtlNtStatusToDosError call followed
  // by RtlSetLastWin32Error call (aka SetLastError), the LastStatusValue in TEB
  // should contain the correct NTSTATUS value. The way to check whether it is
  // correct is to convert it to Win32 error and compare with LastErrorValue
  // from TEB. If, for some reason, they don't match, return a fake NTSTATUS
  // with a Win32 facility.

  if RtlNtStatusToDosErrorNoTeb(RtlGetLastNtStatus) = RtlGetLastWin32Error then
    Result := RtlGetLastNtStatus
  else
  case RtlGetLastWin32Error of

    // Explicitly convert buffer-related errors
    ERROR_INSUFFICIENT_BUFFER: Result := STATUS_BUFFER_TOO_SMALL;
    ERROR_MORE_DATA:           Result := STATUS_BUFFER_OVERFLOW;
    ERROR_BAD_LENGTH:          Result := STATUS_INFO_LENGTH_MISMATCH;

    // After converting, ERROR_SUCCESS becomes unsuccessful, fix it
    ERROR_SUCCESS:             Result := STATUS_SUCCESS;

    // Common errors which we might want to compare
    ERROR_ACCESS_DENIED:       Result := STATUS_ACCESS_DENIED;
    ERROR_PRIVILEGE_NOT_HELD:  Result := STATUS_PRIVILEGE_NOT_HELD;
  else
    Result := WIN32_HRESULT_BITS or FACILITY_SWAP_BIT or
      (RtlGetLastWin32Error and WIN32_CODE_MASK);
  end;
end;

end.
