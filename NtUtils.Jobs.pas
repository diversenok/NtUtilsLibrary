unit NtUtils.Jobs;

{
  The functions for manipulating job objects via Native API.
}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, NtUtils, NtUtils.Objects;

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

// Set information about a job
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
    class function &Set<T>(
      [Access(JOB_OBJECT_SET_ATTRIBUTES)] hJob: THandle;
      InfoClass: TJobObjectInfoClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntseapi, DelphiUtils.AutoObjects;

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
    hxJob := NtxObject.Capture(hJob);
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
    hxJob := NtxObject.Capture(hJob);
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
  Required: Cardinal;
  i: Integer;
begin
  Result.Location := 'NtQueryInformationJobObject';
  Result.LastCall.UsesInfoClass(JobObjectBasicProcessIdList, icQuery);
  Result.LastCall.Expects<TJobObjectAccessMask>(JOB_OBJECT_QUERY);

  // Initial buffer capacity should be enough for at least one item.
  IMemory(xMemory) := Auto.AllocateDynamic(
    SizeOf(TJobObjectBasicProcessIdList) +
    SizeOf(TProcessId) * (INITIAL_CAPACITY - 1));

  repeat
    Required := 0;
    Result.Status := NtQueryInformationJobObject(hJob,
      JobObjectBasicProcessIdList, xMemory.Data, xMemory.Size, nil);
  until not NtxExpandBufferEx(Result, IMemory(xMemory), Required,
    GrowProcessList);

  if Result.IsSuccess then
  begin
    SetLength(ProcessIds, xMemory.Data.NumberOfProcessIdsInList);

    for i := 0 to High(ProcessIds) do
      ProcessIds[i] := xMemory.Data.ProcessIdList{$R-}[i]{$R+};
  end;
end;

function NtxIsProcessInJob;
begin
  Result.Location := 'NtIsProcessInJob';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_LIMITED_INFORMATION);

  if hJob <> 0 then
    Result.LastCall.Expects<TJobObjectAccessMask>(JOB_OBJECT_QUERY);

  Result.Status := NtIsProcessInJob(hProcess, hJob);

  case Result.Status of
    STATUS_PROCESS_IN_JOB:     ProcessInJob := True;
    STATUS_PROCESS_NOT_IN_JOB: ProcessInJob := False;
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
