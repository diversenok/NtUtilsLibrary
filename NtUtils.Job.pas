unit NtUtils.Job;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, NtUtils.Exceptions, NtUtils.Objects;

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
function NtxEnurateProcessesInJob(hJob: THandle;
  out ProcessIds: TArray<NativeUInt>): TNtxStatus;

// Check whether a process is a part of  a specific/any job
function NtxIsProcessInJob(out ProcessInJob: Boolean; hProcess: THandle;
  hJob: THandle = 0): TNtxStatus;

// Assign a process to a job
function NtxAssignProcessToJob(hProcess: THandle; hJob: THandle): TNtxStatus;

// Terminate all processes in a job
function NtxTerminateJob(hJob: THandle; ExitStatus: NTSTATUS): TNtxStatus;

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

function NtxEnurateProcessesInJob(hJob: THandle;
  out ProcessIds: TArray<NativeUInt>): TNtxStatus;
const
  INITIAL_CAPACITY = 8;
var
  BufferSize, Required: Cardinal;
  Buffer: PJobBasicProcessIdList;
  i: Integer;
begin
  Result.Location := 'NtQueryInformationJobObject';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(JobObjectBasicProcessIdList);
  Result.LastCall.InfoClassType := TypeInfo(TJobObjectInfoClass);
  Result.LastCall.Expects(JOB_OBJECT_QUERY, @JobAccessType);

  // Initial buffer capacity should be enough for at least one item.
  BufferSize := SizeOf(Cardinal) * 2 + SizeOf(NativeUInt) * INITIAL_CAPACITY;

  repeat
    // Allocate a buffer for MaxCount items
    Buffer := AllocMem(BufferSize);

    Required := 0;
    Result.Status := NtQueryInformationJobObject(hJob,
      JobObjectBasicProcessIdList, Buffer, BufferSize, nil);

    // If not all processes fit into the list then calculate the required size
    if Result.Status = STATUS_BUFFER_OVERFLOW then
       Required := SizeOf(Cardinal) * 2 +
         SizeOf(NativeUInt) * Buffer.NumberOfAssignedProcesses;

    if not Result.IsSuccess then
      FreeMem(Buffer);

  until not NtxExpandBuffer(Result, BufferSize, Required, True);

  if not Result.IsSuccess then
    Exit;

  SetLength(ProcessIds, Buffer.NumberOfProcessIdsInList);

  for i := 0 to High(ProcessIds) do
    ProcessIds[i] := Buffer.ProcessIdList{$R-}[i]{$R+};

  FreeMem(Buffer);
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

class function NtxJob.Query<T>(hJob: THandle; InfoClass: TJobObjectInfoClass;
  out Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQueryInformationJobObject';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TJobObjectInfoClass);
  Result.LastCall.Expects(JOB_OBJECT_QUERY, @JobAccessType);

  Result.Status := NtQueryInformationJobObject(hJob, InfoClass, @Buffer,
    SizeOf(Buffer), nil);
end;

class function NtxJob.SetInfo<T>(hJob: THandle; InfoClass: TJobObjectInfoClass;
  const Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtSetInformationJobObject';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TJobObjectInfoClass);

  case InfoClass of
    JobObjectBasicLimitInformation, JobObjectExtendedLimitInformation:
      Result.LastCall.ExpectedPrivilege := SE_INCREASE_BASE_PRIORITY_PRIVILEGE;

    JobObjectSecurityLimitInformation:
      Result.LastCall.ExpectedPrivilege := SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE;
  end;

  case InfoClass of
    JobObjectSecurityLimitInformation:
      Result.LastCall.Expects(JOB_OBJECT_SET_SECURITY_ATTRIBUTES, @JobAccessType);
  else
    Result.LastCall.Expects(JOB_OBJECT_SET_ATTRIBUTES, @JobAccessType);
  end;

  Result.Status := NtSetInformationJobObject(hJob, InfoClass, @Buffer,
    SizeOf(Buffer));
end;

end.
