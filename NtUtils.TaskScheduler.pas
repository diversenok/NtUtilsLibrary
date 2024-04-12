unit NtUtils.TaskScheduler;

{
  This file provides wrappers for interacting with the Task Scheduler service.
}

interface

uses
  Ntapi.taskschd, Ntapi.ObjBase, NtUtils;

type
  ITaskService = Ntapi.taskschd.ITaskService;
  ITaskFolder = Ntapi.taskschd.ITaskFolder;
  IRegisteredTask = Ntapi.taskschd.IRegisteredTask;

  // Opening registered tasks requires opening a task folder first. This
  // enumeration defines which folder the caller wants to use by default.
  TRootTaskFolderMode = (
    rmUseGlobalRoot,
    rmUseClosestParent
  );

// Make a connection to the ITaskService interface
[RequiresCOM]
function ComxTaskSchedulerConnect(
  out TaskService: ITaskService;
  [opt] const ServerName: String = '';
  [opt] const DomainName: String = '';
  [opt] const UserName: String = '';
  [opt] const Password: String = ''
): TNtxStatus;

// Open a task folder from under the root
[RequiresCOM]
function ComxTaskSchedulerOpenFolder(
  out TaskFolder: ITaskFolder;
  const Path: String;
  [opt] TaskService: ITaskService = nil
): TNtxStatus;

// Enumerate all sub-folders of a task scheduler folder object
[RequiresCOM]
function ComxTaskSchedulerEnumerateFolders(
  out SubFolders: TArray<ITaskFolder>;
  const TaskFolder: ITaskFolder
): TNtxStatus;

// Make a for-in iterator for enumerating sub-folders of a task scheduler folder.
// Note: when the Status parameter is not set, the function might raise
// exceptions during enumeration.
[RequiresCOM]
function ComxTaskSchedulerIterateFolders(
  [out, opt] Status: PNtxStatus;
  const TaskFolder: ITaskFolder
): IEnumerable<ITaskFolder>;

// Enumerate all tasks in a task scheduler folder
[RequiresCOM]
function ComxTaskSchedulerEnumerateTasks(
  out Tasks: TArray<IRegisteredTask>;
  const TaskFolder: ITaskFolder;
  Flags: TTaskEnumFlags = TASK_ENUM_HIDDEN
): TNtxStatus;

// Make a for-in iterator for enumerating tasks in a task scheduler folder.
// Note: when the Status parameter is not set, the function might raise
// exceptions during enumeration.
[RequiresCOM]
function ComxTaskSchedulerIterateTasks(
  [out, opt] Status: PNtxStatus;
  const TaskFolder: ITaskFolder;
  Flags: TTaskEnumFlags = TASK_ENUM_HIDDEN
): IEnumerable<IRegisteredTask>;

// Open a task by name
[RequiresCOM]
function ComxTaskSchedulerOpenTask(
  out Task: IRegisteredTask;
  const Path: String;
  [opt] Root: ITaskFolder = nil;
  RootMode: TRootTaskFolderMode = rmUseGlobalRoot
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, NtUtils.Com, NtUtils.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function ComxTaskSchedulerConnect;
var
  ServerStr, UserStr, DomainStr, PasswordStr: WideString;
begin
  Result := ComxCreateInstanceWithFallback(taskschd, CLSID_TaskScheduler,
    ITaskService, TaskService, 'CLSID_TaskScheduler');

  if not Result.IsSuccess then
    Exit;

  ServerStr := ServerName;
  UserStr := UserName;
  DomainStr := DomainName;
  PasswordStr := Password;

  Result.Location := 'ITaskService::Connect';
  Result.HResult := TaskService.Connect(VarFromWideString(ServerStr),
    VarFromWideString(DomainStr), VarFromWideString(UserStr),
    VarFromWideString(PasswordStr));
end;

function ComxTaskSchedulerOpenFolder;
begin
  // Connect if necessary
  if not Assigned(TaskService) then
  begin
    Result := ComxTaskSchedulerConnect(TaskService);

    if not Result.IsSuccess then
      Exit;
  end;

  Result.Location := 'ITaskService::GetFolder';
  Result.LastCall.Parameter := Path;
  Result.HResult := TaskService.GetFolder(Path, TaskFolder);
end;

function ComxTaskSchedulerEnumerateFolders;
var
  FolderCollection: ITaskFolderCollection;
  Count: Cardinal;
  i: Integer;
begin
  Result.Location := 'ITaskFolder::GetFolders';
  Result.HResult := TaskFolder.GetFolders(0, FolderCollection);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'ITaskFolderCollection::get_Count';
  Result.HResult := FolderCollection.get_Count(Count);

  if not Result.IsSuccess then
    Exit;

  SetLength(SubFolders, Count);

  for i := 0 to High(SubFolders) do
  begin
    Result.Location := 'ITaskFolderCollection::get_Item';
    Result.HResult := FolderCollection.get_Item(VarFromInteger(Succ(i)),
      SubFolders[i]);

    if not Result.IsSuccess then
      Exit;
  end;
end;

function ComxTaskSchedulerIterateFolders;
var
  FolderCollection: ITaskFolderCollection;
  Index, Count: Cardinal;
begin
  // Task folder indexing starts with 1
  FolderCollection := nil;
  Index := 1;

  Result := NtxAuto.Iterate<ITaskFolder>(Status,
    function (out Entry: ITaskFolder): TNtxStatus
    begin
      // Initialize the task folder collection
      if not Assigned(FolderCollection) then
      begin
        Result.Location := 'ITaskFolder::GetFolders';
        Result.HResult := TaskFolder.GetFolders(0, FolderCollection);

        if not Result.IsSuccess then
          Exit;

        Result.Location := 'ITaskFolderCollection::get_Count';
        Result.HResult := FolderCollection.get_Count(Count);

        if not Result.IsSuccess then
          Exit;
      end;

      if Index <= Count then
      begin
        // Retrieve an entry by index
        Result.Location := 'ITaskFolderCollection::get_Item';
        Result.HResult := FolderCollection.get_Item(VarFromCardinal(Index),
          Entry)
      end
      else
      begin
        // Report the end
        Result.Location := 'ComxTaskSchedulerIterateFolders';
        Result.Status := STATUS_NO_MORE_ENTRIES;
      end;

      if not Result.IsSuccess then
        Exit;

      // Advance to the next entry
      Inc(Index);
    end
  );
end;

function ComxTaskSchedulerEnumerateTasks;
var
  TaskCollection: IRegisteredTaskCollection;
  Count: Cardinal;
  i: Integer;
begin
  Result.Location := 'ITaskFolder::GetTasks';
  Result.HResult := TaskFolder.GetTasks(Flags, TaskCollection);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IRegisteredTaskCollection::get_Count';
  Result.HResult := TaskCollection.get_Count(Count);

  if not Result.IsSuccess then
    Exit;

  SetLength(Tasks, Count);

  for i := 0 to High(Tasks) do
  begin
    Result.Location := 'IRegisteredTaskCollection::get_Item';
    Result.HResult := TaskCollection.get_Item(VarFromInteger(Succ(i)),
      Tasks[i]);

    if not Result.IsSuccess then
      Exit;
  end;
end;

function ComxTaskSchedulerIterateTasks;
var
  TaskCollection: IRegisteredTaskCollection;
  Index, Count: Cardinal;
begin
  // Task indexing starts with 1
  TaskCollection := nil;
  Index := 1;

  Result := NtxAuto.Iterate<IRegisteredTask>(Status,
    function (out Entry: IRegisteredTask): TNtxStatus
    begin
      // Initialize the task collection
      if not Assigned(TaskCollection) then
      begin
        Result.Location := 'ITaskFolder::GetTasks';
        Result.HResult := TaskFolder.GetTasks(Flags, TaskCollection);

        if not Result.IsSuccess then
          Exit;

        Result.Location := 'IRegisteredTaskCollection::get_Count';
        Result.HResult := TaskCollection.get_Count(Count);

        if not Result.IsSuccess then
          Exit;
      end;

      if Index <= Count then
      begin
        // Retrieve an entry by index
        Result.Location := 'IRegisteredTaskCollection::get_Item';
        Result.HResult := TaskCollection.get_Item(VarFromCardinal(Index),
          Entry)
      end
      else
      begin
        // Report the end
        Result.Location := 'ComxTaskSchedulerIterateTasks';
        Result.Status := STATUS_NO_MORE_ENTRIES;
      end;

      if not Result.IsSuccess then
        Exit;

      // Advance to the next entry
      Inc(Index);
    end
  );
end;

function ComxTaskSchedulerOpenTask;
var
  ParentName, ChildName: String;
begin
  // We need to open the task relative to something. If not explicitly given a
  // root, either open the global one or the closest parent path, depending on
  // the preference.

  // Split or use as-is
  if Assigned(Root) or (RootMode <> rmUseClosestParent) or not
    RtlxSplitPath(Path, ParentName, ChildName) then
  begin
    ParentName := '';
    ChildName := Path;
  end;

  // Open the root if not provided
  if not Assigned(Root) then
  begin
    Result := ComxTaskSchedulerOpenFolder(Root, ParentName);

    if not Result.IsSuccess then
      Exit;
  end;

  Result.Location := 'ITaskFolder::GetTask';
  Result.LastCall.Parameter := Path;
  Result.HResult := Root.GetTask(ChildName, Task);
end;

end.
