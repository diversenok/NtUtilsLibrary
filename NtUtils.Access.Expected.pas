unit NtUtils.Access.Expected;

interface

uses
  Winapi.WinNt, Ntapi.ntpsapi, Ntapi.ntseapi, Winapi.ntlsa, Ntapi.ntsam,
  Winapi.Svc, NtUtils;

{ Process }

procedure RtlxComputeProcessQueryAccess(var LastCall: TLastCallInfo;
  InfoClass: TProcessInfoClass);

procedure RtlxComputeProcessSetAccess(var LastCall: TLastCallInfo;
  InfoClass: TProcessInfoClass);

{ Thread }

procedure RtlxComputeThreadQueryAccess(var LastCall: TLastCallInfo;
  InfoClass: TThreadInfoClass);

procedure RtlxComputeThreadSetAccess(var LastCall: TLastCallInfo;
  InfoClass: TThreadInfoClass);

{ Token }

procedure RtlxComputeTokenQueryAccess(var LastCall: TLastCallInfo;
  InfoClass: TTokenInformationClass);

procedure RtlxComputeTokenSetAccess(var LastCall: TLastCallInfo;
  InfoClass: TTokenInformationClass);

{ LSA policy }

procedure RtlxComputePolicyQueryAccess(var LastCall: TLastCallInfo;
  InfoClass: TPolicyInformationClass);

procedure RtlxComputePolicySetAccess(var LastCall: TLastCallInfo;
  InfoClass: TPolicyInformationClass);

{ SAM domain }

procedure RtlxComputeDomainQueryAccess(var LastCall: TLastCallInfo;
  InfoClass: TDomainInformationClass);

procedure RtlxComputeDomainSetAccess(var LastCall: TLastCallInfo;
  InfoClass: TDomainInformationClass);

{ SAM user }

procedure RtlxComputeUserQueryAccess(var LastCall: TLastCallInfo;
  InfoClass: TUserInformationClass);

procedure RtlxComputeUserSetAccess(var LastCall: TLastCallInfo;
  InfoClass: TUserInformationClass);

{ Service }

procedure RtlxComputeServiceControlAccess(var LastCall: TLastCallInfo;
  Control: TServiceControl);

{ Section }

procedure RtlxComputeSectionFileAccess(var LastCall: TLastCallInfo;
  Win32Protect: Cardinal);

procedure RtlxComputeSectionMapAccess(var LastCall: TLastCallInfo;
  Win32Protect: Cardinal);

{ Security }

procedure RtlxComputeSecurityReadAccess(var LastCall: TLastCallInfo;
  SecurityInformation: TSecurityInformation);

procedure RtlxComputeSecurityWriteAccess(var LastCall: TLastCallInfo;
  SecurityInformation: TSecurityInformation);

implementation

uses
  Ntapi.ntmmapi, Ntapi.ntioapi, Ntapi.ntobapi;

{ Process }

procedure RtlxComputeProcessQueryAccess(var LastCall: TLastCallInfo;
  InfoClass: TProcessInfoClass);
begin
  case InfoClass of
    ProcessBasicInformation, ProcessQuotaLimits, ProcessIoCounters,
    ProcessVmCounters, ProcessTimes, ProcessDefaultHardErrorMode,
    ProcessPooledUsageAndLimits, ProcessAffinityMask, ProcessPriorityClass,
    ProcessHandleCount, ProcessPriorityBoost, ProcessSessionInformation,
    ProcessWow64Information, ProcessImageFileName, ProcessLUIDDeviceMapsEnabled,
    ProcessIoPriority, ProcessImageInformation, ProcessCycleTime,
    ProcessPagePriority, ProcessImageFileNameWin32, ProcessAffinityUpdateMode,
    ProcessMemoryAllocationMode, ProcessGroupInformation,
    ProcessConsoleHostProcess, ProcessWindowInformation,
    ProcessCommandLineInformation, ProcessTelemetryIdInformation,
    ProcessCommitReleaseInformation, ProcessDefaultCpuSetsInformation,
    ProcessAllowedCpuSetsInformation, ProcessJobMemoryInformation,
    ProcessInPrivate, ProcessRaiseUMExceptionOnInvalidHandleClose,
    ProcessIumChallengeResponse, ProcessHighGraphicsPriorityInformation,
    ProcessSubsystemInformation, ProcessEnergyValues,
    ProcessActivityThrottleState, ProcessWakeInformation,
    ProcessEnergyTrackingState, ProcessTelemetryCoverage,
    ProcessEnableReadWriteVmLogging, ProcessUptimeInformation,
    ProcessSequenceNumber, ProcessSecurityDomainInformation,
    ProcessEnableLogging:
      LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_LIMITED_INFORMATION);

    ProcessDebugPort, ProcessWorkingSetWatch, ProcessWx86Information,
    ProcessDeviceMap, ProcessBreakOnTermination, ProcessDebugObjectHandle,
    ProcessDebugFlags, ProcessHandleTracing, ProcessExecuteFlags,
    ProcessWorkingSetWatchEx, ProcessImageFileMapping, ProcessHandleInformation,
    ProcessMitigationPolicy, ProcessHandleCheckingMode, ProcessKeepAliveCount,
    ProcessCheckStackExtentsMode, ProcessChildProcessInformation,
    ProcessWin32kSyscallFilterInformation:
      LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_INFORMATION);

    ProcessCookie:
      LastCall.Expects<TProcessAccessMask>(PROCESS_VM_WRITE);

    ProcessLdtInformation:
      LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_INFORMATION or
        PROCESS_VM_READ);

    ProcessHandleTable:
      LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_INFORMATION or
        PROCESS_DUP_HANDLE);

    ProcessCaptureTrustletLiveDump:
      LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_INFORMATION or
        PROCESS_VM_READ or PROCESS_VM_OPERATION);
  end;

  // Additional access
  case InfoClass of
    ProcessImageFileMapping:
      LastCall.Expects<TIoFileAccessMask>(FILE_EXECUTE or SYNCHRONIZE);
  end;
end;

procedure RtlxComputeProcessSetAccess(var LastCall: TLastCallInfo;
  InfoClass: TProcessInfoClass);
begin
  // Privileges
  case InfoClass of
    ProcessQuotaLimits:
      LastCall.ExpectedPrivilege := SE_INCREASE_QUOTA_PRIVILEGE;

    ProcessBasePriority, ProcessIoPriority:
      LastCall.ExpectedPrivilege := SE_INCREASE_BASE_PRIORITY_PRIVILEGE;

    ProcessExceptionPort, ProcessUserModeIOPL, ProcessWx86Information,
    ProcessSessionInformation, ProcessHighGraphicsPriorityInformation,
    ProcessEnableReadWriteVmLogging, ProcessSystemResourceManagement,
    ProcessEnableLogging:
      LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;

    ProcessAccessToken:
      LastCall.ExpectedPrivilege := SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE;

    ProcessBreakOnTermination, ProcessInstrumentationCallback,
    ProcessCheckStackExtentsMode, ProcessActivityThrottleState:
      LastCall.ExpectedPrivilege := SE_DEBUG_PRIVILEGE;
  end;

  // Access
  case InfoClass of
    ProcessBasePriority, ProcessRaisePriority, ProcessAccessToken,
    ProcessDefaultHardErrorMode, ProcessIoPortHandlers, ProcessWorkingSetWatch,
    ProcessUserModeIOPL, ProcessEnableAlignmentFaultFixup, ProcessPriorityClass,
    ProcessWx86Information, ProcessAffinityMask, ProcessPriorityBoost,
    ProcessDeviceMap, ProcessForegroundInformation, ProcessBreakOnTermination,
    ProcessDebugFlags, ProcessHandleTracing, ProcessIoPriority,
    ProcessPagePriority, ProcessInstrumentationCallback,
    ProcessWorkingSetWatchEx, ProcessMemoryAllocationMode,
    ProcessTokenVirtualizationEnabled, ProcessHandleCheckingMode,
    ProcessCheckStackExtentsMode, ProcessMemoryExhaustion,
    ProcessFaultInformation, ProcessSubsystemProcess, ProcessInPrivate,
    ProcessRaiseUMExceptionOnInvalidHandleClose, ProcessEnergyTrackingState:
      LastCall.Expects<TProcessAccessMask>(PROCESS_SET_INFORMATION);

    ProcessRevokeFileHandles, ProcessWorkingSetControl,
    ProcessDefaultCpuSetsInformation, ProcessIumChallengeResponse,
    ProcessHighGraphicsPriorityInformation, ProcessActivityThrottleState,
    ProcessDisableSystemAllowedCpuSets, ProcessEnableReadWriteVmLogging,
    ProcessSystemResourceManagement, ProcessLoaderDetour,
    ProcessCombineSecurityDomainsInformation, ProcessEnableLogging:
      LastCall.Expects<TProcessAccessMask>(PROCESS_SET_LIMITED_INFORMATION);

    ProcessExceptionPort:
      LastCall.Expects<TProcessAccessMask>(PROCESS_SUSPEND_RESUME);

    ProcessQuotaLimits:
      LastCall.Expects<TProcessAccessMask>(PROCESS_SET_QUOTA);

    ProcessSessionInformation:
      LastCall.Expects<TProcessAccessMask>(PROCESS_SET_INFORMATION or
        PROCESS_SET_SESSIONID);

    ProcessLdtInformation, ProcessLdtSize, ProcessTelemetryCoverage:
      LastCall.Expects<TProcessAccessMask>(PROCESS_SET_INFORMATION or
        PROCESS_VM_WRITE);
  end;

  // Additional access
  case InfoClass of
    ProcessAccessToken:
      LastCall.Expects<TTokenAccessMask>(TOKEN_ASSIGN_PRIMARY);

    ProcessDeviceMap:
      LastCall.Expects<TDirectoryAccessMask>(DIRECTORY_TRAVERSE);

    ProcessCombineSecurityDomainsInformation:
      LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_LIMITED_INFORMATION);
  end;
end;

{ Thread }

procedure RtlxComputeThreadQueryAccess(var LastCall: TLastCallInfo;
  InfoClass: TThreadInfoClass);
begin
  case InfoClass of
    ThreadBasicInformation, ThreadTimes, ThreadAmILastThread,
    ThreadPriorityBoost, ThreadIsTerminated, ThreadIoPriority, ThreadCycleTime,
    ThreadPagePriority, ThreadGroupInformation, ThreadIdealProcessorEx,
    ThreadSuspendCount, ThreadNameInformation, ThreadSelectedCpuSets,
    ThreadSystemThreadInformation, ThreadActualGroupAffinity,
    ThreadDynamicCodePolicyInfo, ThreadExplicitCaseSensitivity,
    ThreadSubsystemInformation:
      LastCall.Expects<TThreadAccessMask>(THREAD_QUERY_LIMITED_INFORMATION);

    ThreadDescriptorTableEntry, ThreadQuerySetWin32StartAddress,
    ThreadPerformanceCount, ThreadIsIoPending, ThreadHideFromDebugger,
    ThreadBreakOnTermination, ThreadUmsInformation, ThreadCounterProfiling,
    ThreadCpuAccountingInformation:
      LastCall.Expects<TThreadAccessMask>(THREAD_QUERY_INFORMATION);

    ThreadLastSystemCall, ThreadWow64Context:
      LastCall.Expects<TThreadAccessMask>(THREAD_GET_CONTEXT);

    ThreadTebInformation:
      LastCall.Expects<TThreadAccessMask>(THREAD_GET_CONTEXT or
        THREAD_SET_CONTEXT);
  end;
end;

procedure RtlxComputeThreadSetAccess(var LastCall: TLastCallInfo;
  InfoClass: TThreadInfoClass);
begin
  // Privileges
  case InfoClass of
    ThreadBreakOnTermination, ThreadExplicitCaseSensitivity:
      LastCall.ExpectedPrivilege := SE_DEBUG_PRIVILEGE;

    ThreadPriority, ThreadIoPriority, ThreadActualBasePriority:
      LastCall.ExpectedPrivilege := SE_INCREASE_BASE_PRIORITY_PRIVILEGE;
  end;

  // Access
  case InfoClass of
    ThreadPriority, ThreadBasePriority, ThreadAffinityMask, ThreadPriorityBoost,
    ThreadActualBasePriority, ThreadHeterogeneousCpuPolicy,
    ThreadNameInformation, ThreadSelectedCpuSets:
      LastCall.Expects<TThreadAccessMask>(THREAD_SET_LIMITED_INFORMATION);

    ThreadEnableAlignmentFaultFixup, ThreadZeroTlsCell,
    ThreadIdealProcessor, ThreadHideFromDebugger, ThreadBreakOnTermination,
    ThreadIoPriority, ThreadPagePriority, ThreadGroupInformation,
    ThreadCounterProfiling, ThreadIdealProcessorEx,
    ThreadExplicitCaseSensitivity, ThreadDbgkWerReportActive,
    ThreadPowerThrottlingState:
      LastCall.Expects<TThreadAccessMask>(THREAD_SET_INFORMATION);

    ThreadWow64Context:
      LastCall.Expects<TThreadAccessMask>(THREAD_SET_CONTEXT);

    ThreadImpersonationToken:
      LastCall.Expects<TThreadAccessMask>(THREAD_SET_THREAD_TOKEN);
  end;

  // Additional access
  case InfoClass of
    ThreadImpersonationToken:
      LastCall.Expects<TTokenAccessMask>(TOKEN_IMPERSONATE);

    ThreadCpuAccountingInformation:
      LastCall.Expects<TSessionAccessMask>(SESSION_MODIFY_ACCESS);

    ThreadAttachContainer:
      LastCall.Expects<TJobObjectAccessMask>(JOB_OBJECT_IMPERSONATE);
  end;
end;

{ Token }

procedure RtlxComputeTokenQueryAccess(var LastCall: TLastCallInfo;
  InfoClass: TTokenInformationClass);
begin
  // Privileges
  case InfoClass of
    TokenAuditPolicy:
      LastCall.ExpectedPrivilege := SE_SECURITY_PRIVILEGE;
  end;

  // Access
  case InfoClass of
    TokenSource:
      LastCall.Expects<TTokenAccessMask>(TOKEN_QUERY_SOURCE);
  else
    LastCall.Expects<TTokenAccessMask>(TOKEN_QUERY);
  end;
end;

procedure RtlxComputeTokenSetAccess(var LastCall: TLastCallInfo;
  InfoClass: TTokenInformationClass);
begin
  // Privileges
  case InfoClass of
    TokenSessionId, TokenSessionReference, TokenAuditPolicy, TokenOrigin,
    TokenIntegrityLevel, TokenUIAccess, TokenMandatoryPolicy:
      LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;

    TokenLinkedToken, TokenVirtualizationAllowed:
      LastCall.ExpectedPrivilege := SE_CREATE_TOKEN_PRIVILEGE;
  end;

  // Access
  case InfoClass of
    TokenSessionId:
      LastCall.Expects<TTokenAccessMask>(TOKEN_ADJUST_DEFAULT or
        TOKEN_ADJUST_SESSIONID);

    TokenLinkedToken:
      LastCall.Expects<TTokenAccessMask>(TOKEN_ADJUST_DEFAULT or TOKEN_QUERY);

  else
    LastCall.Expects<TTokenAccessMask>(TOKEN_ADJUST_DEFAULT);
  end;
end;

{ Policy }

procedure RtlxComputePolicyQueryAccess(var LastCall: TLastCallInfo;
  InfoClass: TPolicyInformationClass);
begin
  // See [MS-LSAD] & LsapDbRequiredAccessQueryPolicy
  case InfoClass of
    PolicyAuditLogInformation, PolicyAuditEventsInformation,
    PolicyAuditFullQueryInformation:
      LastCall.Expects<TLsaPolicyAccessMask>(POLICY_VIEW_AUDIT_INFORMATION);

    PolicyPrimaryDomainInformation, PolicyAccountDomainInformation,
    PolicyLsaServerRoleInformation, PolicyReplicaSourceInformation,
    PolicyDefaultQuotaInformation, PolicyDnsDomainInformation,
    PolicyDnsDomainInformationInt, PolicyLocalAccountDomainInformation:
      LastCall.Expects<TLsaPolicyAccessMask>(POLICY_VIEW_LOCAL_INFORMATION);

    PolicyPdAccountInformation:
      LastCall.Expects<TLsaPolicyAccessMask>(POLICY_GET_PRIVATE_INFORMATION);
  end;
end;

procedure RtlxComputePolicySetAccess(var LastCall: TLastCallInfo;
  InfoClass: TPolicyInformationClass);
begin
  // See [MS-LSAD] & LsapDbRequiredAccessSetPolicy
  case InfoClass of
    PolicyPrimaryDomainInformation, PolicyAccountDomainInformation,
    PolicyDnsDomainInformation, PolicyDnsDomainInformationInt,
    PolicyLocalAccountDomainInformation:
      LastCall.Expects<TLsaPolicyAccessMask>(POLICY_TRUST_ADMIN);

    PolicyAuditLogInformation, PolicyAuditFullSetInformation:
      LastCall.Expects<TLsaPolicyAccessMask>(POLICY_AUDIT_LOG_ADMIN);

    PolicyAuditEventsInformation:
      LastCall.Expects<TLsaPolicyAccessMask>(POLICY_SET_AUDIT_REQUIREMENTS);

    PolicyLsaServerRoleInformation, PolicyReplicaSourceInformation:
      LastCall.Expects<TLsaPolicyAccessMask>(POLICY_SERVER_ADMIN);

    PolicyDefaultQuotaInformation:
      LastCall.Expects<TLsaPolicyAccessMask>(POLICY_SET_DEFAULT_QUOTA_LIMITS);
  end;
end;

{ Domain }

procedure RtlxComputeDomainQueryAccess(var LastCall: TLastCallInfo;
  InfoClass: TDomainInformationClass);
begin
  // See [MS-SAMR]
  case InfoClass of
    DomainGeneralInformation, DomainLogoffInformation, DomainOemInformation,
    DomainNameInformation, DomainReplicationInformation,
    DomainServerRoleInformation, DomainModifiedInformation,
    DomainStateInformation, DomainUasInformation, DomainModifiedInformation2:
      LastCall.Expects<TDomainAccessMask>(DOMAIN_READ_OTHER_PARAMETERS);

    DomainPasswordInformation, DomainLockoutInformation:
      LastCall.Expects<TDomainAccessMask>(DOMAIN_READ_PASSWORD_PARAMETERS);

    DomainGeneralInformation2:
      LastCall.Expects<TDomainAccessMask>(DOMAIN_READ_PASSWORD_PARAMETERS or
        DOMAIN_READ_OTHER_PARAMETERS);
  end;
end;

procedure RtlxComputeDomainSetAccess(var LastCall: TLastCallInfo;
  InfoClass: TDomainInformationClass);
begin
  // See [MS-SAMR]
  case InfoClass of
    DomainPasswordInformation, DomainLockoutInformation:
      LastCall.Expects<TDomainAccessMask>(DOMAIN_WRITE_PASSWORD_PARAMS);

    DomainLogoffInformation, DomainOemInformation, DomainUasInformation:
      LastCall.Expects<TDomainAccessMask>(DOMAIN_WRITE_OTHER_PARAMETERS);

    DomainReplicationInformation, DomainServerRoleInformation,
    DomainStateInformation:
      LastCall.Expects<TDomainAccessMask>(DOMAIN_ADMINISTER_SERVER);
  end;
end;

{ User }

procedure RtlxComputeUserQueryAccess(var LastCall: TLastCallInfo;
  InfoClass: TUserInformationClass);
begin
  // See [MS-SAMR]
  case InfoClass of
    UserGeneralInformation, UserNameInformation, UserAccountNameInformation,
    UserFullNameInformation, UserPrimaryGroupInformation,
    UserAdminCommentInformation:
      LastCall.Expects<TUserAccessMask>(USER_READ_GENERAL);

    UserLogonHoursInformation, UserHomeInformation, UserScriptInformation,
    UserProfileInformation, UserWorkStationsInformation:
      LastCall.Expects<TUserAccessMask>(USER_READ_LOGON);

    UserControlInformation, UserExpiresInformation, UserInternal1Information,
    UserParametersInformation:
      LastCall.Expects<TUserAccessMask>(USER_READ_ACCOUNT);

    UserPreferencesInformation:
      LastCall.Expects<TUserAccessMask>(USER_READ_PREFERENCES or
        USER_READ_GENERAL);

    UserLogonInformation, UserAccountInformation:
      LastCall.Expects<TUserAccessMask>(USER_READ_GENERAL or
        USER_READ_PREFERENCES or USER_READ_LOGON or USER_READ_ACCOUNT);

    UserLogonUIInformation: ; // requires administrator and whatever access
  end;
end;

procedure RtlxComputeUserSetAccess(var LastCall: TLastCallInfo;
  InfoClass: TUserInformationClass);
begin
  // See [MS-SAMR]
  case InfoClass of
    UserLogonHoursInformation, UserNameInformation, UserAccountNameInformation,
    UserFullNameInformation, UserPrimaryGroupInformation, UserHomeInformation,
    UserScriptInformation, UserProfileInformation, UserAdminCommentInformation,
    UserWorkStationsInformation, UserControlInformation, UserExpiresInformation,
    UserParametersInformation:
      LastCall.Expects<TUserAccessMask>(USER_WRITE_ACCOUNT);

    UserPreferencesInformation:
      LastCall.Expects<TUserAccessMask>(USER_WRITE_PREFERENCES);

    UserSetPasswordInformation:
      LastCall.Expects<TUserAccessMask>(USER_FORCE_PASSWORD_CHANGE);
  end;
end;

procedure RtlxComputeServiceControlAccess(var LastCall: TLastCallInfo;
  Control: TServiceControl);
begin
  // MSDN
  case Control of
    SERVICE_CONTROL_PAUSE, SERVICE_CONTROL_CONTINUE,
    SERVICE_CONTROL_PARAM_CHANGE,
    SERVICE_CONTROL_NETBIND_ADD..SERVICE_CONTROL_NETBIND_DISABLE:
      LastCall.Expects<TServiceAccessMask>(SERVICE_PAUSE_CONTINUE);

    SERVICE_CONTROL_STOP:
      LastCall.Expects<TServiceAccessMask>(SERVICE_STOP);

    SERVICE_CONTROL_INTERROGATE:
      LastCall.Expects<TServiceAccessMask>(SERVICE_INTERROGATE);
  else
    if (Cardinal(Control) >= 128) and (Cardinal(Control) < 255) then
      LastCall.Expects<TServiceAccessMask>(SERVICE_USER_DEFINED_CONTROL);
  end;
end;

procedure RtlxComputeSectionFileAccess(var LastCall: TLastCallInfo;
  Win32Protect: Cardinal);
begin
  case Win32Protect and $FF of
    PAGE_NOACCESS, PAGE_READONLY, PAGE_WRITECOPY:
      LastCall.Expects<TIoFileAccessMask>(FILE_READ_DATA);

    PAGE_READWRITE:
      LastCall.Expects<TIoFileAccessMask>(FILE_WRITE_DATA or FILE_READ_DATA);

    PAGE_EXECUTE:
      LastCall.Expects<TIoFileAccessMask>(FILE_EXECUTE);

    PAGE_EXECUTE_READ, PAGE_EXECUTE_WRITECOPY:
      LastCall.Expects<TIoFileAccessMask>(FILE_EXECUTE or FILE_READ_DATA);

    PAGE_EXECUTE_READWRITE:
      LastCall.Expects<TIoFileAccessMask>(FILE_EXECUTE or FILE_WRITE_DATA or
        FILE_READ_DATA);
  end;
end;

procedure RtlxComputeSectionMapAccess(var LastCall: TLastCallInfo;
  Win32Protect: Cardinal);
begin
  case Win32Protect and $FF of
    PAGE_NOACCESS, PAGE_READONLY, PAGE_WRITECOPY:
      LastCall.Expects<TSectionAccessMask>(SECTION_MAP_READ);

    PAGE_READWRITE:
      LastCall.Expects<TSectionAccessMask>(SECTION_MAP_WRITE);

    PAGE_EXECUTE:
      LastCall.Expects<TSectionAccessMask>(SECTION_MAP_EXECUTE);

    PAGE_EXECUTE_READ, PAGE_EXECUTE_WRITECOPY:
      LastCall.Expects<TSectionAccessMask>(SECTION_MAP_EXECUTE or
        SECTION_MAP_READ);

    PAGE_EXECUTE_READWRITE:
      LastCall.Expects<TSectionAccessMask>(SECTION_MAP_EXECUTE or
        SECTION_MAP_WRITE);
  end;
end;

procedure RtlxComputeSecurityReadAccess(var LastCall: TLastCallInfo;
  SecurityInformation: TSecurityInformation);
const
  REQUIRE_READ_CONTROL = OWNER_SECURITY_INFORMATION or
    GROUP_SECURITY_INFORMATION or DACL_SECURITY_INFORMATION or
    LABEL_SECURITY_INFORMATION or ATTRIBUTE_SECURITY_INFORMATION or
    SCOPE_SECURITY_INFORMATION or BACKUP_SECURITY_INFORMATION;
  REQUIRE_SYSTEM_SECURITY = SACL_SECURITY_INFORMATION or
    BACKUP_SECURITY_INFORMATION;
var
  Mask: TAccessMask;
begin
  Mask := 0;

  if SecurityInformation and REQUIRE_READ_CONTROL <> 0 then
    Mask := Mask or READ_CONTROL;

  if SecurityInformation and REQUIRE_SYSTEM_SECURITY <> 0 then
    Mask := Mask or ACCESS_SYSTEM_SECURITY;

  LastCall.AttachAccess<TAccessMask>(Mask);
end;

procedure RtlxComputeSecurityWriteAccess(var LastCall: TLastCallInfo;
  SecurityInformation: TSecurityInformation);
const
  REQUIRE_WRITE_DAC = DACL_SECURITY_INFORMATION or
    ATTRIBUTE_SECURITY_INFORMATION or BACKUP_SECURITY_INFORMATION or
    PROTECTED_DACL_SECURITY_INFORMATION or UNPROTECTED_DACL_SECURITY_INFORMATION;
  REQUIRE_WRITE_OWNER = OWNER_SECURITY_INFORMATION or GROUP_SECURITY_INFORMATION
    or LABEL_SECURITY_INFORMATION or BACKUP_SECURITY_INFORMATION;
  REQUIRE_SYSTEM_SECURITY = SACL_SECURITY_INFORMATION or
    SCOPE_SECURITY_INFORMATION or BACKUP_SECURITY_INFORMATION or
    PROTECTED_SACL_SECURITY_INFORMATION or UNPROTECTED_SACL_SECURITY_INFORMATION;
var
  Mask: TAccessMask;
begin
  Mask := 0;

  if SecurityInformation and REQUIRE_WRITE_DAC <> 0 then
    Mask := Mask or WRITE_DAC;

  if SecurityInformation and REQUIRE_WRITE_OWNER <> 0 then
    Mask := Mask or WRITE_OWNER;

  if SecurityInformation and REQUIRE_SYSTEM_SECURITY <> 0 then
    Mask := Mask or ACCESS_SYSTEM_SECURITY;

  LastCall.AttachAccess<TAccessMask>(Mask);
end;

end.
