unit Ntapi.taskschd;

{
  This module includes definitions for interacting with Task Scheduler.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.WinBase, Ntapi.ObjBase, DelphiApi.Reflection;

const
  // SDK::taskschd.h - RunEx flags
  TASK_RUN_AS_SELF = $0001;
  TASK_RUN_IGNORE_CONSTRAINTS = $0002;
  TASK_RUN_USE_SESSION_ID = $0004;
  TASK_RUN_USER_SID = $0008;

  // SDK::taskschd.h
  CLSID_TaskScheduler: TGuid = '{0f87369f-a4e5-4cfc-bd3e-73e6154572dd}';

  // rev
  TASK_MANAGER_TASK_FOLDER = '\Microsoft\Windows\Task Manager';
  TASK_MANAGER_TASK_NAME = 'Interactive';
  TASK_MANAGER_TASK_PATH = TASK_MANAGER_TASK_FOLDER + '\' +
    TASK_MANAGER_TASK_NAME;

type
  // SDK::taskschd.h
  [SDKName('TASK_LOGON_TYPE')]
  [NamingStyle(nsSnakeCase, 'TASK_LOGON')]
  TTaskLogonType = (
    TASK_LOGON_NONE = 0,
    TASK_LOGON_PASSWORD = 1,
    TASK_LOGON_S4U = 2,
    TASK_LOGON_INTERACTIVE_TOKEN = 3,
    TASK_LOGON_GROUP = 4,
    TASK_LOGON_SERVICE_ACCOUNT = 5,
    TASK_LOGON_INTERACTIVE_TOKEN_OR_PASSWORD = 6
  );

  // SDK::taskschd.h
  [SDKName('TASK_STATE')]
  [NamingStyle(nsSnakeCase, 'TASK_STATE')]
  TTaskState = (
    TASK_STATE_UNKNOWN = 0,
    TASK_STATE_DISABLED = 1,
    TASK_STATE_QUEUED = 2,
    TASK_STATE_READY = 3,
    TASK_STATE_RUNNING = 4
  );

  // SDK::taskschd.h
  [SDKName('TASK_RUN_FLAGS')]
  [FlagName(TASK_RUN_AS_SELF, 'As Self')]
  [FlagName(TASK_RUN_IGNORE_CONSTRAINTS, 'Ignore Constraints')]
  [FlagName(TASK_RUN_USE_SESSION_ID, 'Use Session ID')]
  [FlagName(TASK_RUN_USER_SID, 'User SID')]
  TTaskRunFlag = type Cardinal;

  // TBD
  ITaskDefinition = type IUnknown;
  ITaskFolderCollection = type IUnknown;
  IRegisteredTaskCollection = type IUnknown;
  IRunningTaskCollection = type IUnknown;

  IRunningTask = interface (IDispatch)
    ['{653758fb-7b9a-4f1e-a471-beeb8e9b834e}']
    function get_Name(
      [out] out Name: WideString
    ): HResult; stdcall;

    function get_InstanceGuid(
      [out] Guid: WideString
    ): HResult; stdcall;

    function get_Path(
      [out] Path: WideString
    ): HResult; stdcall;

    function get_State(
      [out] out State: TTaskState
    ): HResult; stdcall;

    function get_CurrentAction(
      [out] out Name: WideString
    ): HResult; stdcall;

    function Stop(
    ): HResult; stdcall;

    function Refresh(
    ): HResult; stdcall;

    function get_EnginePID(
      [out] out PID: TProcessId32
    ): HResult; stdcall;
  end;

  // SDK::taskschd.h
  IRegisteredTask = interface (IDispatch)
    ['{9c86f320-dee3-4dd1-b972-a303f26b061e}']

    function get_Name(
      [out] out Name: WideString
    ): HResult; stdcall;

    function get_Path(
      [out] out Path: WideString
    ): HResult; stdcall;

    function get_State(
      [out] out State: TTaskState
    ): HResult; stdcall;

    function get_Enabled(
      [out] out Enabled: TVariantBool
    ): HResult; stdcall;

    function put_Enabled(
      [in] Enabled: TVariantBool
    ): HResult; stdcall;

    function Run(
      [in] params: TVarData;
      [out] out RunningTask: IRunningTask
    ): HResult; stdcall;

    function RunEx(
      [in] params: TVarData;
      [in] flags: TTaskRunFlag;
      [in] sessionID: TSessionId;
      [in] user: WideString;
      [out] out RunningTask: IRunningTask
    ): HResult; stdcall;

    function GetInstances(
      [in] flags: Cardinal;
      [out] out RunningTasks: IRunningTaskCollection
    ): HResult; stdcall;

    function get_LastRunTime(
      [out] out LastRunTime: TDateTime
    ): HResult; stdcall;

    function get_LastTaskResult(
      [out] out LastTaskResult: HResult
    ): HResult; stdcall;

    function get_NumberOfMissedRuns(
      [out] out NumberOfMissedRuns: Cardinal
    ): HResult; stdcall;

    function get_NextRunTime(
      [out] out NextRunTime: TDateTime
    ): HResult; stdcall;

    function get_Definition(
      [out] out Definition: ITaskDefinition
    ): HResult; stdcall;

    function get_Xml(
      [out] out Xml: WideString
    ): HResult; stdcall;

    function GetSecurityDescriptor(
      [in] securityInformation: TSecurityInformation;
      [out] out Sddl: WideString
    ): HResult; stdcall;

    function SetSecurityDescriptor(
      [in] sddl: WideString;
      [in] flags: Cardinal
    ): HResult; stdcall;

    function Stop(
      [Reserved] flags: Cardinal
    ): HResult; stdcall;

    function GetRunTimes(
      [in] const StartTime: TSystemTime;
      [in] const EndTime: TSystemTime;
      [in, out, NumberOfElements] var Count: Cardinal;
      [out, ReleaseWith('CoTaskMemFree')] out RunTimes: PSystemTimeArray
    ): HResult; stdcall;
  end;

  // SDK::taskschd.h
  ITaskFolder = interface (IDispatch)
    ['{8cfac062-a080-4c15-9a88-aa7c2af80dfc}']

    function get_Name(
      [out] out Name: WideString
    ): HResult; stdcall;

    function get_Path(
      [out] out Path: WideString
    ): HResult; stdcall;

    function GetFolder(
      [in] path: WideString;
      [out] out Folder: ITaskFolder
    ): HResult; stdcall;

    function GetFolders(
      [in] flags: Cardinal;
      [out] out Folders: ITaskFolderCollection
    ): HResult; stdcall;

    function CreateFolder(
      [in] subFolderName: WideString;
      [in, opt] sddl: TVarData;
      [out] out Folder: ITaskFolder
    ): HResult; stdcall;

    function DeleteFolder(
      [in] subFolderName: WideString;
      [in] flags: Cardinal
    ): HResult; stdcall;

    function GetTask(
      [in] path: WideString;
      [out] out Task: IRegisteredTask
    ): HResult; stdcall;

    function GetTasks(
      [in] flags: Cardinal;
      [out] out Tasks: IRegisteredTaskCollection
    ): HResult; stdcall;

    function DeleteTask(
      [in] name: WideChar;
      [in] flags: Cardinal
    ): HResult; stdcall;

    function RegisterTask(
      [in] path: WideString;
      [in] xmlText: WideString;
      [in] flags: Cardinal;
      [in] userId: TVarData;
      [in] password: TVarData;
      [in] logonType: TTaskLogonType;
      [in, opt] sddl: TVarData;
      [out] out Task: IRegisteredTask
    ): HResult; stdcall;

    function RegisterTaskDefinition(
      [in] path: WideString;
      [in] Definition: ITaskDefinition;
      [in] flags: Cardinal;
      [in] userId: TVarData;
      [in] password: TVarData;
      [in] logonType: TTaskLogonType;
      [in, opt] sddl: TVarData;
      [out] out Task: IRegisteredTask
    ): HResult; stdcall;

    function GetSecurityDescriptor(
      [in] securityInformation: TSecurityInformation;
      [out] out Sddl: WideString
    ): HResult; stdcall;

    function SetSecurityDescriptor(
      [in] sddl: WideString;
      [in] flags: Cardinal
    ): HResult; stdcall;
  end;

  // SDK::taskschd.h
  ITaskService = interface (IDispatch)
    ['{2faba4c7-4da9-4013-9697-20cc3fd40f85}']

    function GetFolder(
      [in, opt] Path: WideString;
      [out] out Folder: ITaskFolder
    ): HResult; stdcall;

    function GetRunningTasks(
      [in] flags: Cardinal;
      [out] out RunningTasks: IRunningTaskCollection
    ): HResult; stdcall;

    function NewTask(
      [in] flags: Cardinal;
      [out] out Definition: ITaskDefinition
    ): HResult; stdcall;

    function Connect(
      [in, opt] serverName: TVarData;
      [in, opt] user: TVarData;
      [in, opt] domain: TVarData;
      [in, opt] password: TVarData
    ): HResult; stdcall;

    function get_Connected(
      [out] out Connected: TVariantBool
    ): HResult; stdcall;

    function get_TargetServer(
      [out] out Server: WideString
    ): HResult; stdcall;

    function get_ConnectedUser(
      [out] out User: WideString
    ): HResult; stdcall;

    function get_ConnectedDomain(
      [out] out Domain: WideString
    ): HResult; stdcall;

    function get_HighestVersion(
      [out] out Version: Cardinal
    ): HResult; stdcall;
  end;

implementation

end.
