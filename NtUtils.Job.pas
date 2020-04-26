unit NtUtils.Job;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, NtUtils, NtUtils.Objects;

const
  PROCESS_ASSIGN_TO_JOB = PROCESS_SET_QUOTA or PROCESS_TERMINATE;

// Create new job object
function NtxCreateJob(out hxJob: IHandle; ObjectName: String = '';
  RootDirectory: THandle = 0; HandleAttributes: Cardinal = 0): TNtxStatus;

// Open job object by name
function NtxOpenJob(out hxJob: IHandle; DesiredAccess: TAccessMask;
  ObjectName: String; RootDirectory: THandle = 0;
  HandleAttributes: Cardinal = 0): TNtxStatus;

// Enumerate active processes in a job
function NtxEnumerateProcessesInJob(hJob: THandle;
  out ProcessIds: TArray<TProcessId>): TNtxStatus;

// Check whether a process is a part of  a specific/any job
function NtxIsProcessInJob(out ProcessInJob: Boolean; hProcess: THandle;
  hJob: THandle = 0): TNtxStatus;

// Assign a process to a job
function NtxAssignProcessToJob(hProcess: THandle; hJob: THandle): TNtxStatus;

// Terminate all processes in a job
function NtxTerminateJob(hJob: THandle; ExitStatus: NTSTATUS): TNtxStatus;

// Set information about a job
function NtxSetJob(hJob: THandle; InfoClass: TJobObjectInfoClass;
  Buffer: Pointer; BufferSize: Cardinal): TNtxStatus;

type
  NtxJob = class
    // Query fixed-size information
    class function Query<T>(hJob: THandle;
      InfoClass: TJobObjectInfoClass; out Buffer: T): TNtxStatus; static;

    // Set fixed-size information
    class function SetInfo<T>(hJob: THandle;
      InfoClass: TJobObjectInfoClass; const Buffer: T): TNtxStatus; static;
  end;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntseapi;

function NtxCreateJob(out hxJob: IHandle; ObjectName: String;
  RootDirectory: THandle; HandleAttributes: Cardinal): TNtxStatus;
var
  hJob: THandle;
  ObjAttr: TObjectAttributes;
  NameStr: UNICODE_STRING;
begin
  if ObjectName <> '' then
  begin
    NameStr.FromString(ObjectName);
    InitializeObjectAttributes(ObjAttr, @NameStr, HandleAttributes,
      RootDirectory);
  end
  else
    InitializeObjectAttributes(ObjAttr, nil, HandleAttributes);

  Result.Location := 'NtCreateJobObject';
  Result.Status := NtCreateJobObject(hJob, JOB_OBJECT_ALL_ACCESS, @ObjAttr);

  if Result.IsSuccess then
    hxJob := TAutoHandle.Capture(hJob);
end;

function NtxOpenJob(out hxJob: IHandle; DesiredAccess: TAccessMask;
  ObjectName: String; RootDirectory: THandle; HandleAttributes: Cardinal):
  TNtxStatus;
var
  hJob: THandle;
  ObjAttr: TObjectAttributes;
  NameStr: UNICODE_STRING;
begin
  NameStr.FromString(ObjectName);
  InitializeObjectAttributes(ObjAttr, @NameStr, HandleAttributes,
    RootDirectory);

  Result.Location := 'NtOpenJobObject';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @JobAccessType;
  Result.Status := NtOpenJobObject(hJob, DesiredAccess, ObjAttr);

  if Result.IsSuccess then
    hxJob := TAutoHandle.Capture(hJob);
end;

function GrowProcessList(Memory: IMemory; Required: NativeUInt): NativeUInt;
begin
  Result := SizeOf(TJobObjectBasicProcessIdList) + SizeOf(TProcessId) *
    PJobObjectBasicProcessIdList(Memory.Data).NumberOfAssignedProcesses;

  Inc(Result, Result shr 3); // + 12%
end;

function NtxEnumerateProcessesInJob(hJob: THandle;
  out ProcessIds: TArray<TProcessId>): TNtxStatus;
const
  INITIAL_CAPACITY = 8;
var
  xMemory: IMemory;
  Required: Cardinal;
  Buffer: PJobObjectBasicProcessIdList;
  i: Integer;
begin
  Result.Location := 'NtQueryInformationJobObject';
  Result.LastCall.AttachInfoClass(JobObjectBasicProcessIdList);
  Result.LastCall.Expects(JOB_OBJECT_QUERY, @JobAccessType);

  // Initial buffer capacity should be enough for at least one item.
  xMemory := TAutoMemory.Allocate(SizeOf(TJobObjectBasicProcessIdList) +
    SizeOf(TProcessId) * (INITIAL_CAPACITY - 1));

  repeat
    Required := 0;
    Result.Status := NtQueryInformationJobObject(hJob,
      JobObjectBasicProcessIdList, xMemory.Data, xMemory.Size, nil);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowProcessList);

  if Result.IsSuccess then
  begin
    Buffer := xMemory.Data;
    SetLength(ProcessIds, Buffer.NumberOfProcessIdsInList);

    for i := 0 to High(ProcessIds) do
      ProcessIds[i] := Buffer.ProcessIdList{$R-}[i]{$R+};
  end;
end;

function NtxIsProcessInJob(out ProcessInJob: Boolean; hProcess: THandle;
  hJob: THandle): TNtxStatus;
begin
  Result.Location := 'NtIsProcessInJob';
  Result.LastCall.Expects(PROCESS_QUERY_LIMITED_INFORMATION,
    @ProcessAccessType);

  if hJob <> 0 then
    Result.LastCall.Expects(JOB_OBJECT_QUERY, @JobAccessType);

  Result.Status := NtIsProcessInJob(hProcess, hJob);

  case Result.Status of
    STATUS_PROCESS_IN_JOB:     ProcessInJob := True;
    STATUS_PROCESS_NOT_IN_JOB: ProcessInJob := False;
  end;
end;

function NtxAssignProcessToJob(hProcess: THandle; hJob: THandle): TNtxStatus;
begin
  Result.Location := 'NtAssignProcessToJobObject';
  Result.LastCall.Expects(PROCESS_ASSIGN_TO_JOB, @ProcessAccessType);
  Result.LastCall.Expects(JOB_OBJECT_ASSIGN_PROCESS, @JobAccessType);
  Result.Status := NtAssignProcessToJobObject(hJob, hProcess);
end;

function NtxTerminateJob(hJob: THandle; ExitStatus: NTSTATUS): TNtxStatus;
begin
  Result.Location := 'NtTerminateJobObject';
  Result.LastCall.Expects(JOB_OBJECT_TERMINATE, @JobAccessType);
  Result.Status := NtTerminateJobObject(hJob, ExitStatus);
end;

function NtxSetJob(hJob: THandle; InfoClass: TJobObjectInfoClass;
  Buffer: Pointer; BufferSize: Cardinal): TNtxStatus;
begin
  Result.Location := 'NtSetInformationJobObject';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects(JOB_OBJECT_SET_ATTRIBUTES, @JobAccessType);

  case InfoClass of
    JobObjectBasicLimitInformation, JobObjectExtendedLimitInformation:
      Result.LastCall.ExpectedPrivilege := SE_INCREASE_BASE_PRIORITY_PRIVILEGE;

    JobObjectThreadImpersonationInformation:
      Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE
  end;

  Result.Status := NtSetInformationJobObject(hJob, InfoClass, Buffer,
    BufferSize);
end;

class function NtxJob.Query<T>(hJob: THandle; InfoClass: TJobObjectInfoClass;
  out Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQueryInformationJobObject';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects(JOB_OBJECT_QUERY, @JobAccessType);

  Result.Status := NtQueryInformationJobObject(hJob, InfoClass, @Buffer,
    SizeOf(Buffer), nil);
end;

class function NtxJob.SetInfo<T>(hJob: THandle; InfoClass: TJobObjectInfoClass;
  const Buffer: T): TNtxStatus;
begin
  Result := NtxSetJob(hJob, InfoClass, @Buffer, SizeOf(Buffer));
end;

end.
