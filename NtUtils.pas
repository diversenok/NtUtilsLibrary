unit NtUtils;

{
  Base definitions for the NtUtils library.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, Ntapi.WinError,
  DelphiApi.Reflection, DelphiUtils.AutoObjects;

var
  // Controls whether TNtxStatus should capture stack traces on failure.
  // When enabled, you should also configure generation of debug symbols via
  // Project -> Options -> Building -> Delphi Compiler -> Linking -> Map File.
  // This switch controls creation of .map files which you can later convert
  // into .dbg using the map2dbg tool. Optionally, you can go one step further
  // and convert the .dbg file into a more modern .pdb via the cv2pdb tool.
  // For more details, see https://stackoverflow.com/questions/9422703 and
  // https://github.com/rainers/cv2pdb
  // You can also configure the following post-build events for the project:
  //   map2dbg.exe $(OUTPUTPATH)
  //   cv2pdb64.exe -n -s. -p$(OUTPUTNAME).pdb $(OUTPUTPATH)
  CaptureStackTraces: Boolean = False;

{ Forwarded definitions }

type
  // Forward the types for automatic lifetime management
  IAutoReleasable = DelphiUtils.AutoObjects.IAutoReleasable;
  IAutoObject = DelphiUtils.AutoObjects.IAutoObject;
  IAutoPointer = DelphiUtils.AutoObjects.IAutoPointer;
  TMemory = DelphiUtils.AutoObjects.TMemory;
  IMemory = DelphiUtils.AutoObjects.IMemory;
  IHandle = DelphiUtils.AutoObjects.IHandle;
  Auto = DelphiUtils.AutoObjects.Auto;

  // Define commonly used IAutoPointer/IMemory aliases
  IContext = IMemory<PContext>;
  IEnvironment = IMemory<PEnvironment>;
  ISecurityDescriptor = IAutoPointer<PSecurityDescriptor>;
  IAcl = IAutoPointer<PAcl>;
  ISid = IAutoPointer<PSid>;

  TGroup = record
    Sid: ISid;
    Attributes: TGroupAttributes;
    class function From(
      const Sid: ISid;
      Attributes: TGroupAttributes
    ): TGroup; static;
  end;

{ Annotations }

  // A few macros/aliases for checking bit flags and better expressing intent.
  // Note: do not use with 64-bit or native integers!
  BitTest = LongBool;
  HasAny = LongBool;

  // Forward SAL annotations
  InAttribute = DelphiApi.Reflection.InAttribute;
  OutAttribute = DelphiApi.Reflection.OutAttribute;
  OptAttribute = DelphiApi.Reflection.OptAttribute;
  MayReturnNilAttribute = DelphiApi.Reflection.MayReturnNilAttribute;
  AccessAttribute = DelphiApi.Reflection.AccessAttribute;
  ThreadSafeAttribute = DelphiApi.Reflection.ThreadSafeAttribute;

{ Error handling }

type
  [NamingStyle(nsCamelCase, 'lc')]
  TLastCallType = (lcOtherCall, lcOpenCall, lcQuerySetCall);

  [NamingStyle(nsCamelCase, 'ic')]
  TInfoClassOperation = (icUnknown, icQuery, icSet, icRead, icWrite, icControl,
    icPerform, icParse, icMarshal);

  TExpectedAccess = record
    AccessMask: TAccessMask;
    AccessMaskType: Pointer;
  end;

  TLastCallInfo = record
    Location: String;
    Parameter: String;
    StackTrace: TArray<Pointer>;
    ExpectedPrivilege: TSeWellKnownPrivilege;
    ExpectedAccess: TArray<TExpectedAccess>;
    procedure CaptureStackTrace;
    procedure OpensForAccess<T>(Mask: T);
    procedure Expects<T>(AccessMask: T);
    procedure UsesInfoClass<T>(
      InfoClassEnum: T;
      Operation: TInfoClassOperation
    );
  case CallType: TLastCallType of
    lcOpenCall: (
      AccessMask: TAccessMask;
      AccessMaskType: Pointer
    );

    lcQuerySetCall: (
      InfoClassOperation: TInfoClassOperation;
      InfoClass: Cardinal;
      InfoClassType: Pointer
    );
  end;

  // An enhanced NTSTATUS that stores additional information about the last
  // operation and the location of failure.
  TNtxStatus = record
  private
    FStatus: NTSTATUS;

    function GetWin32Error: TWin32Error;
    function GetHResult: HResult;
    function GetLocation: String;

    procedure FromWin32Error(const Value: TWin32Error);
    procedure FromWin32ErrorOrSuccess(const Value: TWin32Error);
    procedure FromLastWin32Error(const RetValue: Boolean);
    procedure FromHResult(const Value: HResult);
    procedure FromHResultAllowFalse(const Value: HResult);
    procedure FromStatus(const Value: NTSTATUS);

    procedure SetLocation(const Value: String); inline;
  public
    LastCall: TLastCallInfo;

    // Note: setting location resets the rest of the last call information
    property Location: String read GetLocation write SetLocation;

    // Creation & conversion
    property Status: NTSTATUS read FStatus write FromStatus;
    property Win32Error: TWin32Error read GetWin32Error write FromWin32Error;
    property Win32ErrorOrSuccess: TWin32Error write FromWin32ErrorOrSuccess;
    property HResult: HResult read GetHResult write FromHResult;
    property HResultAllowFalse: HResult write FromHResultAllowFalse;
    property Win32Result: Boolean write FromLastWin32Error;

    // Validation
    function IsSuccess: Boolean; inline;
    function IsWin32: Boolean;
    function IsHResult: Boolean;
    function Matches(Status: NTSTATUS; Location: String): Boolean; inline;

    // Copy into another variable
    function SaveTo(var Target: TNtxStatus): TNtxStatus;

    // Returns boolean indicating whether iteration succeeded. Converts a status
    // into success on graceful end of iteration but forwards other errors.
    // Use: `while NtxGetNextSomething(Entry).HasEntry(Result) do`
    function HasEntry(out Target: TNtxStatus): Boolean;

    // Raise an unsuccessful status as an exception. When using, consider
    // including NtUiLib.Exceptions for better integration with Delphi.
    procedure RaiseOnError;

    // A custom callback for raising exceptions (provided by NtUiLib.Exceptions)
    class var NtxExceptionRaiser: procedure (const Status: TNtxStatus);
  end;
  PNtxStatus = ^TNtxStatus;

const
  NtxSuccess: TNtxStatus = (FStatus: 0);

{ Stack tracing & exceptions }

// Get the address of the next instruction after the call
function RtlxNextInstruction: Pointer;

// Capture a stack trace of the current thread
function RtlxCaptureStackTrace(
  FramesToSkip: Integer = 0
): TArray<Pointer>;

// Raise an external exception (when System.SysUtils is not available)
procedure RtlxRaiseException(
  Status: NTSTATUS;
  [in, opt] Address: Pointer
);

type
  // An alternative base exception class when System.SysUtils is not available
  ENoSysUtilsException = class
  private
    FExceptionCode: NTSTATUS;
    FExceptionFlags: TExceptionFlags;
    FExceptionAddress: Pointer;
    FStackTrace: TArray<Pointer>;
  public
    property ExceptionCode: NTSTATUS read FExceptionCode;
    property ExceptionFlags: TExceptionFlags read FExceptionFlags;
    property ExceptionAddress: Pointer read FExceptionAddress;
    property StackTrace: TArray<Pointer> read FStackTrace;
    constructor Create(P: PExceptionRecord);
  end;

  // An access violation exception class when System.SysUtils is not available
  ENoSysUtilsAccessViolation = class (ENoSysUtilsException)
  private
    FAccessOperation: TExceptionAccessViolationOperation;
    FAccessAddress: Pointer;
  public
    property AccessOperation: TExceptionAccessViolationOperation read FAccessOperation;
    property AccessAddress: Pointer read FAccessAddress;
    constructor Create(P: PExceptionRecord);
  end;

{ Buffer Expansion }

const
  BUFFER_LIMIT = 1024 * 1024 * 1024; // 1 GiB

type
  TBufferGrowthMethod = function (
    const Memory: IMemory;
    Required: NativeUInt
  ): NativeUInt;

// Slightly adjust required size with + 12% to mitigate fluctuations
function Grow12Percent(
  const Memory: IMemory;
  Required: NativeUInt
): NativeUInt;

// Re-allocate the buffer according to the required size
function NtxExpandBufferEx(
  var Status: TNtxStatus;
  var Memory: IMemory;
  Required: NativeUInt;
  [opt] GrowthMethod: TBufferGrowthMethod
): Boolean;

{ String functions }

type
  // A macro for retrieving the buffer of a Delphi string via a typecast
  RefStrOrEmtry = PWideChar;

// Reference the buffer of a Delphi string or nil, for empty input
[Result: MayReturnNil]
function RefStrOrNil(
  [in, opt] const S: String
): PWideChar;

// Count the number of bytes required to store a string without terminating zero
[Result: NumberOfBytes]
function StringSizeNoZero(
  [in, opt] const S: String
): NativeUInt;

// Count the number of bytes required to store a string with terminating zero
[Result: NumberOfBytes]
function StringSizeZero(
  [in, opt] const S: String
): NativeUInt;

// Make a UNICODE_STRING that references a Delphi string
function RtlxInitUnicodeString(
  out Destination: TNtUnicodeString;
  [opt] const Source: String
): TNtxStatus;

// Make a ANSI_STRING that references a Delphi string
function RtlxInitAnsiString(
  out Destination: TNtAnsiString;
  [opt] const Source: AnsiString
): TNtxStatus;

// Write a string into a buffer
procedure MarshalString(
  [in] const Source: String;
  [out, WritesTo] Buffer: Pointer
);

// Write an NT unicode string into a buffer
function RtlxMarshalUnicodeString(
  [in] const Source: String;
  [out] out Target: TNtUnicodeString;
  [out, WritesTo] Buffer: Pointer
): TNtxStatus;

{ Other helper functions }

// Get a handle value from IHandle or a defulat, when not provided
function HandleOrDefault(
  [in, opt] const hxObject: IHandle;
  [in, opt] Default: THandle = 0
): THandle;

// Pseudo-handles
function NtxCurrentProcess: IHandle;
function NtxCurrentThread: IHandle;
function NtxCurrentProcessToken: IHandle;
function NtxCurrentThreadToken: IHandle;
function NtxCurrentEffectiveToken: IHandle;

{ Object Attributes }

type
  // A Delphi wrapper for a commonly used OBJECT_ATTRIBUTES type that allows
  // building it with a simplified (fluent) syntax.
  IObjectAttributes = interface
    // Fluent builder
    function UseRoot(const RootDirectory: IHandle): IObjectAttributes;
    function UseName(const ObjectName: String): IObjectAttributes;
    function UseAttributes(const Attributes: TObjectAttributesFlags): IObjectAttributes;
    function UseSecurity(const SecurityDescriptor: ISecurityDescriptor): IObjectAttributes;
    function UseImpersonation(const Level: TSecurityImpersonationLevel): IObjectAttributes;
    function UseEffectiveOnly(const Enabled: Boolean = True): IObjectAttributes;
    function UseContextTracking(const Enabled: Boolean = True): IObjectAttributes;
    function UseDesiredAccess(const AccessMask: TAccessMask): IObjectAttributes;

    // Accessor functions
    function GetRoot: IHandle;
    function GetName: String;
    function GetAttributes: TObjectAttributesFlags;
    function GetSecurity: ISecurityDescriptor;
    function GetImpersonation: TSecurityImpersonationLevel;
    function GetEffectiveOnly: Boolean;
    function GetContextTracking: Boolean;
    function GetDesiredAccess: TAccessMask;

    // Accessors
    property Root: IHandle read GetRoot;
    property Name: String read GetName;
    property Attributes: TObjectAttributesFlags read GetAttributes;
    property Security: ISecurityDescriptor read GetSecurity;
    property Impersonation: TSecurityImpersonationLevel read GetImpersonation;
    property EffectiveOnly: Boolean read GetEffectiveOnly;
    property ContextTracking: Boolean read GetContextTracking;
    property DesiredAccess: TAccessMask read GetDesiredAccess;

    // Finalize the builder and make a reference to the underlying structure.
    // Note: the operation might fail because UNICODE_STRING for the name has a
    // lower limit on the number of characters than Delphi strings.
    function Build(out Reference: PObjectAttributes): TNtxStatus;
  end;

// Make an instance of an object attribute builder
function AttributeBuilder(
  [in, opt] const Template: IObjectAttributes = nil
): IObjectAttributes;

// Get an NT object attribute pointer from an interfaced object attributes
function AttributesRefOrNil(
  [out, MayReturnNil] out Reference: PObjectAttributes;
  [in, opt] const ObjAttributes: IObjectAttributes
): TNtxStatus;

// Prepare and reference security attributes from object attributes
function ReferenceSecurityAttributes(
  [out] out SA: TSecurityAttributes;
  [in, opt] const ObjectAttributes: IObjectAttributes
): PSecurityAttributes;

// Let the caller override the default access mask via Object Attributes when
// creating kernel objects.
function AccessMaskOverride(
  [in] DefaultAccess: TAccessMask;
  [in, opt] const ObjAttributes: IObjectAttributes
): TAccessMask;

{ Shared delayed free functions }

// Free a string buffer using RtlFreeUnicodeString after use
function RtlxDelayFreeUnicodeString(
  [in] Buffer: PNtUnicodeString
): IAutoReleasable;

// Free a SID buffer using RtlFreeSid after use
function RtlxDelayFreeSid(
  [in] Buffer: PSid
): IAutoReleasable;

// Free a buffer using LocalFree after use
function AdvxDelayLocalFree(
  [in] Buffer: Pointer
): IAutoReleasable;

{ AutoObjects extensions }

type
  TNtxOperation = reference to function : TNtxStatus;
  TNtxEnumeratorProvider<T> = reference to function (out Next: T): TNtxStatus;

  NtxAuto = class abstract
    // Use an anonymous TNtxStatus-aware function as a for-in iterator
    // Note: when the Status parameter is not provided, iteration will report
    // errors via exceptions.
    class function Iterate<T>(
      [out, opt] Status: PNtxStatus;
      [in] Provider: TNtxEnumeratorProvider<T>
    ): IEnumerable<T>; static;

    // Same as above but with a one-time call to Prepare
    class function IterateEx<T>(
      [out, opt] Status: PNtxStatus;
      [in] Prepare: TNtxOperation;
      [in] Provider: TNtxEnumeratorProvider<T>
    ): IEnumerable<T>; static;
  end;

  // Internal; call NtxAuto.Iterate instead.
  // A wrapper for anonymous TNtxStatus-aware for-in loop providers
  TNtxAnonymousEnumerator<T> = class (TInterfacedObject, IEnumerator<T>,
    IEnumerable<T>)
  protected
    FCurrent: T;
    FIsPrepared: Boolean;
    FPrepare: TNtxOperation;
    FProvider: TNtxEnumeratorProvider<T>;
    FStatus: PNtxStatus;
  private
    function GetCurrent: TObject; // legacy (untyped)
    function GetEnumerator: IEnumerator; // legacy (untyped)
  public
    constructor Create(
      [out, opt] Status: PNtxStatus;
      [in, opt] const Prepare: TNtxOperation;
      [in] const Provider: TNtxEnumeratorProvider<T>
    );
    procedure Reset;
    function MoveNext: Boolean;
    function GetCurrentT: T;
    function GetEnumeratorT: IEnumerator<T>;
    function IEnumerator<T>.GetCurrent = GetCurrentT;
    function IEnumerable<T>.GetEnumerator = GetEnumeratorT;
  end;

implementation

uses
  Ntapi.ntrtl, Ntapi.ntstatus, Ntapi.ntpebteb, Ntapi.ntpsapi, Ntapi.WinBase,
  NtUtils.Errors;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TGroup }

class function TGroup.From;
begin
  Result.Sid := Sid;
  Result.Attributes := Attributes;
end;

{ TLastCallInfo }

procedure TLastCallInfo.CaptureStackTrace;
begin
  StackTrace := RtlxCaptureStackTrace(3);
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

procedure TLastCallInfo.OpensForAccess<T>;
var
  AsAccessMask: TAccessMask absolute Mask;
begin
  CallType := lcOpenCall;
  AccessMask := AsAccessMask;
  AccessMaskType := TypeInfo(T);
end;

procedure TLastCallInfo.UsesInfoClass<T>;
var
  AsByte: Byte absolute InfoClassEnum;
  AsWord: Word absolute InfoClassEnum;
  AsCardinal: Cardinal absolute InfoClassEnum;
begin
  CallType := lcQuerySetCall;
  InfoClassOperation := Operation;
  InfoClassType := TypeInfo(T);

  case SizeOf(T) of
    SizeOf(Byte):     InfoClass := AsByte;
    SizeOf(Word):     InfoClass := AsWord;
    SizeOf(Cardinal): InfoClass := AsCardinal;
  end;
end;

{ TNtxStatus }

procedure TNtxStatus.FromHResult;
begin
  // S_FALSE is a controversial value that is successful, but indicates a
  // failure. Its precise meaning depends on the context, so whenever we expect
  // it as a result we should adjust the logic correspondingly. By default,
  // consider it unsuccessful. For the opposite behavior, use HResultAllowFalse.

  if Value = S_FALSE then
    Status := System.HResult(S_FALSE_AS_ERROR).ToNtStatus
  else
    Status := Value.ToNtStatus;
end;

procedure TNtxStatus.FromHResultAllowFalse;
begin
  // Note: if you want S_FALSE to be unsuccessful, see comments in FromHResult.
  Status := Value.ToNtStatus;
end;

procedure TNtxStatus.FromLastWin32Error;
begin
  if RetValue then
    Status := STATUS_SUCCESS
  else
    Status := RtlxGetLastNtStatus(True);
end;

procedure TNtxStatus.FromStatus;
var
  OldBeingDebugged: Boolean;
begin
  // Note: all other methods of creation (from Win32 errors, HResults, etc.) end
  // up in this function.

  FStatus := Value;

  // RtlSetLastWin32ErrorAndNtStatusFromNtStatus helps us to enhance debugging
  // experience but it also has a side-effect of generating debug messages
  // whenever it encounters an unrecognized values. Since we use custom
  // NTSTATUSes to pack HRESULTs, these messages can become overwhelming.
  // Suppress them by temporarily resetting the indicator flag in PEB.

  OldBeingDebugged := RtlGetCurrentPeb.BeingDebugged;
  RtlGetCurrentPeb.BeingDebugged := False;
  RtlSetLastWin32ErrorAndNtStatusFromNtStatus(Value);
  RtlGetCurrentPeb.BeingDebugged := OldBeingDebugged;

  if not IsSuccess and CaptureStackTraces then
    LastCall.CaptureStackTrace;
end;

procedure TNtxStatus.FromWin32Error;
begin
  Status := Value.ToNtStatus;
end;

procedure TNtxStatus.FromWin32ErrorOrSuccess;
begin
  if Value = ERROR_SUCCESS then
    Status := STATUS_SUCCESS
  else
    Status := Value.ToNtStatus;
end;

function TNtxStatus.GetHResult;
begin
  Result := Status.ToHResult;
end;

function TNtxStatus.GetLocation;
begin
  Result := LastCall.Location;
end;

function TNtxStatus.GetWin32Error;
begin
  Result := Status.ToWin32Error;
end;

function TNtxStatus.HasEntry;
begin
  // When encountering a graceful end of iteration, set the result boolean to
  // false to indicate that the caller should exit the loop but convert the
  // target status to success to indicate that no unexpected errors occurred.

  Result := IsSuccess;

  case Status of
    STATUS_NO_MORE_ENTRIES, STATUS_NO_MORE_FILES, STATUS_NO_MORE_MATCHES,
    STATUS_NO_SUCH_FILE, STATUS_NO_MORE_EAS, STATUS_NO_EAS_ON_FILE,
    STATUS_NONEXISTENT_EA_ENTRY:
      Target := NtxSuccess;
  else
    Target := Self;
  end;
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

procedure TNtxStatus.RaiseOnError;
begin
  if IsSuccess then
    Exit;

  if Assigned(NtxExceptionRaiser) then
    NtxExceptionRaiser(Self)
  else
    RtlxRaiseException(Status, ReturnAddress);
end;

function TNtxStatus.SaveTo;
begin
  Target := Self;
  Result := Self;
end;

procedure TNtxStatus.SetLocation;
begin
  LastCall := Default(TLastCallInfo);
  LastCall.Location := Value;
end;

{ Stack tracing & exceptions }

function RtlxNextInstruction;
begin
  // Return address of a function is the next instruction for its caller
  Result := ReturnAddress;
end;

function RtlxCaptureStackTrace;
var
  Count, ReturnedCount: Cardinal;
begin
  // Start with a reasonable depth
  Count := 32;
  Result := nil;

  repeat
    SetLength(Result, Count);

    // Capture the trace
    ReturnedCount := RtlCaptureStackBackTrace(FramesToSkip, Count, @Result[0],
      nil);

    if ReturnedCount < Count then
      Break;

    // Retry with twice the depth
    Count := Count shl 1;
  until False;

  // Trim the output
  SetLength(Result, ReturnedCount);
end;

procedure RtlxRaiseException;
var
  ExceptionRecord: TExceptionRecord;
begin
  ExceptionRecord := Default(TExceptionRecord);
  ExceptionRecord.ExceptionCode := Status;
  ExceptionRecord.ExceptionFlags := EXCEPTION_NONCONTINUABLE;
  ExceptionRecord.ExceptionAddress := Address;

  RtlRaiseException(ExceptionRecord);
end;

constructor ENoSysUtilsException.Create;
begin
  FExceptionCode := P.ExceptionCode;
  FExceptionFlags := P.ExceptionFlags;
  FExceptionAddress := P.ExceptionAddress;

  if CaptureStackTraces then
    FStackTrace := RtlxCaptureStackTrace;
end;

constructor ENoSysUtilsAccessViolation.Create;
begin
  inherited Create(P);
  FAccessOperation := TExceptionAccessViolationOperation(
    P.ExceptionInformation[0]);
  FAccessAddress := Pointer(P.ExceptionInformation[1]);
end;

function NtUtilsExceptClsProc(P: PExceptionRecord): TClass;
begin
  if P.ExceptionCode = STATUS_ACCESS_VIOLATION then
    Result := ENoSysUtilsAccessViolation
  else
    Result := ENoSysUtilsException;
end;

function NtUtilsExceptObjProc(P: PExceptionRecord): TObject;
begin
  if P.ExceptionCode = STATUS_ACCESS_VIOLATION then
    Result := ENoSysUtilsAccessViolation.Create(P)
  else
    Result := ENoSysUtilsException.Create(P);
end;

{ Buffer expansion }

function Grow12Percent;
begin
  Result := Required;
  Inc(Result, Result shr 3);
end;

function NtxExpandBufferEx;
begin
  // True means continue; False means break from the loop
  Result := False;

  if Status.IsWin32 then
    case Status.Win32Error of
      ERROR_INSUFFICIENT_BUFFER, ERROR_MORE_DATA,
      ERROR_BAD_LENGTH: ; // Pass through
    else
      Exit;
    end
  else
  case Status.Status of
    STATUS_INFO_LENGTH_MISMATCH, STATUS_BUFFER_TOO_SMALL,
    STATUS_BUFFER_OVERFLOW, STATUS_FLT_BUFFER_TOO_SMALL: ; // Pass through
  else
    Exit;
  end;

  // Grow the buffer with provided callback
  if Assigned(GrowthMethod) then
    Required := GrowthMethod(Memory, Required);

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

  Memory := Auto.AllocateDynamic(Required);
  Result := True;
end;

{ String functions }

function RefStrOrNil;
begin
  if S <> '' then
    Result := PWideChar(S)
  else
    Result := nil;
end;

function StringSizeNoZero;
begin
  Result := Length(S) * SizeOf(WideChar);
end;

function StringSizeZero;
begin
  Result := Succ(Length(S)) * SizeOf(WideChar);
end;

function RtlxInitUnicodeString;
begin
  Destination.Buffer := PWideChar(Source);

  if Length(Source) > MAX_UNICODE_STRING then
  begin
    // Truncate the length and return and an error
    Destination.Length := MAX_UNICODE_STRING * SizeOf(WideChar);
    Destination.MaximumLength := Destination.Length;

    Result.Location := 'RtlxInitUnicodeString';
    Result.Status := STATUS_NAME_TOO_LONG;
    Exit;
  end;

  Result := NtxSuccess;
  Destination.Length := StringSizeNoZero(Source);

  // Make sure not to overflow the max length when addressing the longest string
  if Length(Source) = MAX_UNICODE_STRING then
    Destination.MaximumLength := Destination.Length
  else
    Destination.MaximumLength := StringSizeZero(Source)
end;

function RtlxInitAnsiString;
begin
  Destination.Buffer := PAnsiChar(Source);

  if Length(Source) > MAX_ANSI_STRING then
  begin
    // Truncate the length and return and an error
    Destination.Length := MAX_ANSI_STRING * SizeOf(AnsiChar);
    Destination.MaximumLength := Destination.Length;

    Result.Location := 'RtlxInitAnsiString';
    Result.Status := STATUS_NAME_TOO_LONG;
    Exit;
  end;

  Result := NtxSuccess;
  Destination.Length := Length(Source) * SizeOf(AnsiChar);

  // Make sure not to overflow the max length when addressing the longest string
  if Length(Source) = MAX_ANSI_STRING then
    Destination.MaximumLength := Destination.Length
  else
    Destination.MaximumLength := Succ(Length(Source)) * SizeOf(AnsiChar)
end;

procedure MarshalString;
begin
  Move(PWideChar(Source)^, Buffer^, StringSizeZero(Source));
end;

function RtlxMarshalUnicodeString;
begin
  Result := RtlxInitUnicodeString(Target, Source);

  if not Result.IsSuccess then
    Exit;

  Move(PWideChar(Source)^, Buffer^, Target.MaximumLength);
  Target.Buffer := Buffer;
end;

function HandleOrDefault;
begin
  if Assigned(hxObject) then
    Result := hxObject.Handle
  else
    Result := Default;
end;

function NtxCurrentProcess;
begin
  Result := Auto.RefHandle(NtCurrentProcess);
end;

function NtxCurrentThread;
begin
  Result := Auto.RefHandle(NtCurrentThread);
end;

function NtxCurrentProcessToken;
begin
  Result := Auto.RefHandle(NtCurrentProcessToken);
end;

function NtxCurrentThreadToken;
begin
  Result := Auto.RefHandle(NtCurrentThreadToken);
end;

function NtxCurrentEffectiveToken;
begin
  Result := Auto.RefHandle(NtCurrentEffectiveToken);
end;

{ Object Attributes }

type
  TNtxObjectAttributes = class (TInterfacedObject, IObjectAttributes)
  private
    FObjAttr: TObjectAttributes;
    FQoS: TSecurityQualityOfService;
    FRoot: IHandle;
    FName: String;
    FNameStr: TNtUnicodeString;
    FSecurity: ISecurityDescriptor;
    FAccessMask: TAccessMask;
    function SetRoot(const Value: IHandle): TNtxObjectAttributes;
    function SetName(const Value: String): TNtxObjectAttributes;
    function SetAttributes(const Value: TObjectAttributesFlags): TNtxObjectAttributes;
    function SetSecurity(const Value: ISecurityDescriptor): TNtxObjectAttributes;
    function SetImpersonation(const Value: TSecurityImpersonationLevel): TNtxObjectAttributes;
    function SetEffectiveOnly(const Value: Boolean): TNtxObjectAttributes;
    function SetContextTracking(const Value: Boolean): TNtxObjectAttributes;
    function SetDesiredAccess(const Value: TAccessMask): TNtxObjectAttributes;
    function Duplicate: TNtxObjectAttributes;
  public
    constructor Create;
    function GetRoot: IHandle;
    function GetName: String;
    function GetAttributes: TObjectAttributesFlags;
    function GetSecurity: ISecurityDescriptor;
    function GetImpersonation: TSecurityImpersonationLevel;
    function GetEffectiveOnly: Boolean;
    function GetContextTracking: Boolean;
    function GetDesiredAccess: TAccessMask;
    function Build(out Reference: PObjectAttributes): TNtxStatus;
    function UseRoot(const Value: IHandle): IObjectAttributes;
    function UseName(const Value: String): IObjectAttributes;
    function UseAttributes(const Value: TObjectAttributesFlags): IObjectAttributes;
    function UseSecurity(const Value: ISecurityDescriptor): IObjectAttributes;
    function UseImpersonation(const Value: TSecurityImpersonationLevel): IObjectAttributes;
    function UseEffectiveOnly(const Value: Boolean): IObjectAttributes;
    function UseContextTracking(const Value: Boolean): IObjectAttributes;
    function UseDesiredAccess(const Value: TAccessMask): IObjectAttributes;
  end;

function TNtxObjectAttributes.Build;
begin
  Result := RtlxInitUnicodeString(FNameStr, FName);

  if not Result.IsSuccess then
    Exit;

  FObjAttr.ObjectName := FNameStr.RefOrNil;
  Reference := @FObjAttr;
end;

constructor TNtxObjectAttributes.Create;
begin
  inherited;
  FObjAttr.Length := SizeOf(TObjectAttributes);
  FObjAttr.SecurityQualityOfService := @FQoS;
  FObjAttr.Attributes := OBJ_CASE_INSENSITIVE;
  FQoS.Length := SizeOf(TSecurityQualityOfService);
  FQoS.ImpersonationLevel := SecurityImpersonation;
end;

function TNtxObjectAttributes.Duplicate;
begin
  Result := TNtxObjectAttributes.Create
    .SetRoot(GetRoot)
    .SetName(GetName)
    .SetAttributes(GetAttributes)
    .SetSecurity(GetSecurity)
    .SetImpersonation(GetImpersonation)
    .SetEffectiveOnly(GetEffectiveOnly)
    .SetContextTracking(GetContextTracking);
end;

function TNtxObjectAttributes.GetAttributes;
begin
  Result := FObjAttr.Attributes;
end;

function TNtxObjectAttributes.GetContextTracking;
begin
  Result := FQoS.ContextTrackingMode;
end;

function TNtxObjectAttributes.GetDesiredAccess;
begin
  Result := FAccessMask;
end;

function TNtxObjectAttributes.GetEffectiveOnly;
begin
  Result := FQoS.EffectiveOnly;
end;

function TNtxObjectAttributes.GetImpersonation;
begin
  Result := FQoS.ImpersonationLevel;
end;

function TNtxObjectAttributes.GetName;
begin
  Result := FName;
end;

function TNtxObjectAttributes.GetRoot;
begin
  Result := FRoot;
end;

function TNtxObjectAttributes.GetSecurity;
begin
  Result := FSecurity;
end;

function TNtxObjectAttributes.SetAttributes;
begin
  FObjAttr.Attributes := Value;
  Result := Self;
end;

function TNtxObjectAttributes.SetContextTracking;
begin
  FQoS.ContextTrackingMode := Value;
  Result := Self;
end;

function TNtxObjectAttributes.SetDesiredAccess;
begin
  FAccessMask := Value;
  Result := Self;
end;

function TNtxObjectAttributes.SetEffectiveOnly;
begin
  FQoS.EffectiveOnly := Value;
  Result := Self;
end;

function TNtxObjectAttributes.SetImpersonation;
begin
  FQoS.ImpersonationLevel := Value;
  Result := Self;
end;

function TNtxObjectAttributes.SetName;
begin
  FName := Value;
  // Do not inigislize TNtUnicodeString string yet since the operation can fail
  // on strings that are too long
  Result := Self;
end;

function TNtxObjectAttributes.SetRoot;
begin
  FRoot := Value;
  FObjAttr.RootDirectory := HandleOrDefault(FRoot);
  Result := Self;
end;

function TNtxObjectAttributes.SetSecurity;
begin
  FSecurity := Value;
  FObjAttr.SecurityDescriptor := Auto.RefOrNil<PSecurityDescriptor>(FSecurity);
  Result := Self;
end;

function TNtxObjectAttributes.UseAttributes;
begin
  Result := Duplicate.SetAttributes(Value);
end;

function TNtxObjectAttributes.UseContextTracking;
begin
  Result := Duplicate.SetContextTracking(Value);
end;

function TNtxObjectAttributes.UseDesiredAccess;
begin
  Result := Duplicate.SetDesiredAccess(Value);
end;

function TNtxObjectAttributes.UseEffectiveOnly;
begin
  Result := Duplicate.SetEffectiveOnly(Value);
end;

function TNtxObjectAttributes.UseImpersonation;
begin
  Result := Duplicate.SetImpersonation(Value);
end;

function TNtxObjectAttributes.UseName;
begin
  Result := Duplicate.SetName(Value);
end;

function TNtxObjectAttributes.UseRoot;
begin
  Result := Duplicate.SetRoot(Value);
end;

function TNtxObjectAttributes.UseSecurity;
begin
  Result := Duplicate.SetSecurity(Value);
end;

function AttributeBuilder;
begin
  if Assigned(Template) then
    Result := Template
  else
    Result := TNtxObjectAttributes.Create;
end;

function AttributesRefOrNil;
begin
  if Assigned(ObjAttributes) then
    Result := ObjAttributes.Build(Reference)
  else
  begin
    Reference := nil;
    Result := NtxSuccess;
  end;
end;

function ReferenceSecurityAttributes;
begin
  if Assigned(ObjectAttributes) and (
    Assigned(ObjectAttributes.Security) or
    BitTest(ObjectAttributes.Attributes and OBJ_INHERIT)
    ) then
  begin
    SA.Length := SizeOf(SA);
    SA.InheritHandle := BitTest(ObjectAttributes.Attributes and OBJ_INHERIT);

    if Assigned(ObjectAttributes.Security) then
      SA.SecurityDescriptor := ObjectAttributes.Security.Data
    else
      SA.SecurityDescriptor := nil;

    Result := @SA;
  end
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

{ Shared delayed free functions }

function RtlxDelayFreeUnicodeString;
begin
  Result := Auto.Delay(
    procedure
    begin
      RtlFreeUnicodeString(Buffer);
    end
  );
end;

function RtlxDelayFreeSid;
begin
  Result := Auto.Delay(
    procedure
    begin
      RtlFreeSid(Buffer);
    end
  );
end;

function AdvxDelayLocalFree;
begin
  Result := Auto.Delay(
    procedure
    begin
      LocalFree(Buffer);
    end
  );
end;

{ AutoObjects extensions }

class function NtxAuto.Iterate<T>;
begin
  Result := TNtxAnonymousEnumerator<T>.Create(Status, nil, Provider);
end;

class function NtxAuto.IterateEx<T>;
begin
  Result := TNtxAnonymousEnumerator<T>.Create(Status, Prepare, Provider);
end;

constructor TNtxAnonymousEnumerator<T>.Create;
begin
  FPrepare := Prepare;
  FProvider := Provider;
  FStatus := Status;
end;

function TNtxAnonymousEnumerator<T>.GetCurrent;
begin
  Assert(False, 'Legacy (untyped) IEnumerator.GetCurrent not supported');
  Result := nil;
end;

function TNtxAnonymousEnumerator<T>.GetCurrentT;
begin
  Result := FCurrent;
end;

function TNtxAnonymousEnumerator<T>.GetEnumerator;
begin
  Assert(False, 'Legacy (untyped) IEnumerable.GetEnumerator not supported');
  Result := nil;
end;

function TNtxAnonymousEnumerator<T>.GetEnumeratorT;
begin
  Result := Self;
end;

function TNtxAnonymousEnumerator<T>.MoveNext;
var
  Status: TNtxStatus;
begin
  if Assigned(FPrepare) and not FIsPrepared then
  begin
    // Run one-time preparation
    Status := FPrepare;
    FIsPrepared := Status.IsSuccess;
    Result := FIsPrepared;
  end
  else
  begin
    // Already initialized or not required
    Status := NtxSuccess;
    Result := True;
  end;

  // Try to retrieve the next entry from the provider
  Result := Result and FProvider(FCurrent).HasEntry(Status);

  // Forward the status to the caller
  if Assigned(FStatus) then
    FStatus^ := Status
  else
    Status.RaiseOnError;
end;

procedure TNtxAnonymousEnumerator<T>.Reset;
begin
  ; // not supported
end;

initialization
  // To support try-except blocks, Delphi needs a base exception class.
  // Usually, System.SysUtils configures it to be EException by assigning
  // ExceptClsProc and ExceptObjProc callbacks during the module initialization.
  // Here we set-up our custom ENoSysUtilsException type as a fallback option,
  // in case SysUtils is not available. Note that this doesn't break anything
  // for programs compiled with SysUtils support: if we reach this code after
  // SysUtils, the callbacks are already set and we don't touch them; reaching
  // here before SysUtils also works because it will overwrite them anyway.
  if not Assigned(ExceptClsProc) and not (Assigned(ExceptObjProc)) then
  begin
    ExceptClsProc := @NtUtilsExceptClsProc;
    ExceptObjProc := @NtUtilsExceptObjProc;
  end;
end.
