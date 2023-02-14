unit NtUtils.Jobs;

{
  The functions for manipulating job objects via Native API.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, NtApi.ntseapi, NtUtils,
  NtUtils.Objects, Ntapi.Versions;

const
  PROCESS_ASSIGN_TO_JOB = PROCESS_SET_QUOTA or PROCESS_TERMINATE;

// Create new job object
function NtxCreateJob(
  out hxJob: IHandle;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open job object by name
function NtxOpenJob(
  out hxJob: IHandle;
  DesiredAccess: TJobObjectAccessMask;
  const ObjectName: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Query variable-size information
function NtxQueryJob(
  [Access(JOB_OBJECT_QUERY)] hJob: THandle;
  InfoClass: TJobObjectInfoClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Enumerate active processes in a job
function NtxEnumerateProcessesInJob(
  [Access(JOB_OBJECT_QUERY)] hJob: THandle;
  out ProcessIds: TArray<TProcessId>
): TNtxStatus;

// Check whether a process is a part of  a specific/any job
function NtxIsProcessInJob(
  out ProcessInJob: Boolean;
  [Access(PROCESS_QUERY_LIMITED_INFORMATION)] hProcess: THandle;
  [opt, Access(JOB_OBJECT_QUERY)] hJob: THandle = 0
): TNtxStatus;

// Assign a process to a job
function NtxAssignProcessToJob(
  [Access(PROCESS_ASSIGN_TO_JOB)] hProcess: THandle;
  [Access(JOB_OBJECT_ASSIGN_PROCESS)] hJob: THandle
): TNtxStatus;

// Terminate all processes in a job
function NtxTerminateJob(
  [Access(JOB_OBJECT_TERMINATE)] hJob: THandle;
  ExitStatus: NTSTATUS
): TNtxStatus;

// Terminate all processes in a job when the object goes out of scope
function NtxDelayedTerminateJob(
  [Access(JOB_OBJECT_TERMINATE)] const hxJob: IHandle;
  ExitStatus: NTSTATUS
): IAutoReleasable;

// Freeze/thaw all processes in a job
[MinOSVersion(OsWin8)]
function NtxFreezeThawJob(
  [Access(JOB_OBJECT_SET_ATTRIBUTES)] hJob: THandle;
  Freeze: Boolean
): TNtxStatus;

// Freeze all processes in a job and thaw them later
[MinOSVersion(OsWin8)]
function NtxFreezeJobAuto(
  [Access(JOB_OBJECT_SET_ATTRIBUTES)] const hxJob: IHandle;
  out Reverter: IAutoReleasable
): TNtxStatus;

// Set information about a job
[RequiredPrivilege(SE_INCREASE_QUOTA_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function NtxSetJob(
  [Access(JOB_OBJECT_SET_ATTRIBUTES)] hJob: THandle;
  InfoClass: TJobObjectInfoClass;
  [in] Buffer: Pointer;
  BufferSize: Cardinal
): TNtxStatus;

type
  NtxJob = class abstract
    // Query fixed-size information
    class function Query<T>(
      [Access(JOB_OBJECT_QUERY)] hJob: THandle;
      InfoClass: TJobObjectInfoClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Set fixed-size information
    [RequiredPrivilege(SE_INCREASE_QUOTA_PRIVILEGE, rpSometimes)]
    [RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
    class function &Set<T>(
      [Access(JOB_OBJECT_SET_ATTRIBUTES)] hJob: THandle;
      InfoClass: TJobObjectInfoClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

implementation

uses
  Ntapi.ntstatus, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NtxCreateJob;
var
  hJob: THandle;
begin
  Result.Location := 'NtCreateJobObject';
  Result.Status := NtCreateJobObject(
    hJob,
    AccessMaskOverride(JOB_OBJECT_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes)
  );

  if Result.IsSuccess then
    hxJob := Auto.CaptureHandle(hJob);
end;

function NtxOpenJob;
var
  hJob: THandle;
begin
  Result.Location := 'NtOpenJobObject';
  Result.LastCall.OpensForAccess(DesiredAccess);

  Result.Status := NtOpenJobObject(
    hJob,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(ObjectName).ToNative^
  );

  if Result.IsSuccess then
    hxJob := Auto.CaptureHandle(hJob);
end;

function NtxQueryJob;
var
  Required: Cardinal;
begin
  Result.Location := 'NtQueryInformationJobObject';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TJobObjectAccessMask>(JOB_OBJECT_QUERY);

  IMemory(xMemory) := Auto.AllocateDynamic(InitialBuffer);

  repeat
    Required := 0;
    Result.Status := NtQueryInformationJobObject(hJob, InfoClass, xMemory.Data,
      xMemory.Size, nil);
  until not NtxExpandBufferEx(Result, IMemory(xMemory), Required, GrowthMethod);
end;

function GrowProcessList(
  const Memory: IMemory;
  Required: NativeUInt
): NativeUInt;
begin
  Result := SizeOf(TJobObjectBasicProcessIdList) + SizeOf(TProcessId) *
    PJobObjectBasicProcessIdList(Memory.Data).NumberOfAssignedProcesses;

  Inc(Result, Result shr 3); // + 12%
end;

function NtxEnumerateProcessesInJob;
const
  INITIAL_CAPACITY = 8;
var
  xMemory: IMemory<PJobObjectBasicProcessIdList>;
  i: Integer;
begin
  Result := NtxQueryJob(hJob, JobObjectBasicProcessIdList, IMemory(xMemory),
    SizeOf(TJobObjectBasicProcessIdList) + SizeOf(TProcessId) *
    (INITIAL_CAPACITY - 1), GrowProcessList);

  if not Result.IsSuccess then
    Exit;

  SetLength(ProcessIds, xMemory.Data.NumberOfProcessIdsInList);

  for i := 0 to High(ProcessIds) do
    ProcessIds[i] := xMemory.Data.ProcessIdList{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
end;

function NtxIsProcessInJob;
begin
  Result.Location := 'NtIsProcessInJob';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_LIMITED_INFORMATION);

  if hJob <> 0 then
    Result.LastCall.Expects<TJobObjectAccessMask>(JOB_OBJECT_QUERY);

  Result.Status := NtIsProcessInJob(hProcess, hJob);

  if not Result.IsSuccess then
    Exit;

  case Result.Status of
    STATUS_PROCESS_IN_JOB:     ProcessInJob := True;
    STATUS_PROCESS_NOT_IN_JOB: ProcessInJob := False;
  else
    // Other successful codes should not appear
    Result.Location := 'NtxIsProcessInJob';
    Result.Status := STATUS_UNSUCCESSFUL;
  end;
end;

function NtxAssignProcessToJob;
begin
  Result.Location := 'NtAssignProcessToJobObject';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_ASSIGN_TO_JOB);
  Result.LastCall.Expects<TJobObjectAccessMask>(JOB_OBJECT_ASSIGN_PROCESS);
  Result.Status := NtAssignProcessToJobObject(hJob, hProcess);
end;

function NtxTerminateJob;
begin
  Result.Location := 'NtTerminateJobObject';
  Result.LastCall.Expects<TJobObjectAccessMask>(JOB_OBJECT_TERMINATE);
  Result.Status := NtTerminateJobObject(hJob, ExitStatus);
end;

function NtxDelayedTerminateJob;
begin
  Result := Auto.Delay(
    procedure
    begin
      NtxTerminateJob(hxJob.Handle, ExitStatus);
    end
  );
end;

function NtxFreezeThawJob;
var
  Info: TJobObjectFreezeInformation;
begin
  Info := Default(TJobObjectFreezeInformation);
  Info.Flags := JOB_OBJECT_OPERATION_FREEZE;
  Info.Freeze := Freeze;

  Result := NtxJob.Set(hJob, JobObjectFreezeInformation, Info);
end;

function NtxFreezeJobAuto;
begin
  Result := NtxFreezeThawJob(hxJob.Handle, True);

  if Result.IsSuccess then
    Reverter := Auto.Delay(
      procedure
      begin
        NtxFreezeThawJob(hxJob.Handle, False);
      end
    );
end;

function NtxSetJob;
begin
  Result.Location := 'NtSetInformationJobObject';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects<TJobObjectAccessMask>(JOB_OBJECT_SET_ATTRIBUTES);

  case InfoClass of
    JobObjectBasicLimitInformation, JobObjectExtendedLimitInformation:
      Result.LastCall.ExpectedPrivilege := SE_INCREASE_BASE_PRIORITY_PRIVILEGE;

    JobObjectThreadImpersonationInformation:
      Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE
  end;

  Result.Status := NtSetInformationJobObject(hJob, InfoClass, Buffer,
    BufferSize);
end;

class function NtxJob.Query<T>;
begin
  Result.Location := 'NtQueryInformationJobObject';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TJobObjectAccessMask>(JOB_OBJECT_QUERY);

  Result.Status := NtQueryInformationJobObject(hJob, InfoClass, @Buffer,
    SizeOf(Buffer), nil);
end;

class function NtxJob.&Set<T>;
begin
  Result := NtxSetJob(hJob, InfoClass, @Buffer, SizeOf(Buffer));
end;

end.
