unit NtUtils.Access.Expected;

interface

uses
  Ntapi.ntpsapi, Ntapi.ntseapi, Winapi.ntlsa, Ntapi.ntsam, Winapi.Svc,
  NtUtils.Exceptions;

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

implementation

uses
  Ntapi.ntmmapi, Ntapi.ntioapi, Winapi.WinNt, Ntapi.ntobapi;

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
      LastCall.Expects(PROCESS_QUERY_LIMITED_INFORMATION, @ProcessAccessType);

    ProcessDebugPort, ProcessWorkingSetWatch, ProcessWx86Information,
    ProcessDeviceMap, ProcessBreakOnTermination, ProcessDebugObjectHandle,
    ProcessDebugFlags, ProcessHandleTracing, ProcessExecuteFlags,
    ProcessWorkingSetWatchEx, ProcessImageFileMapping, ProcessHandleInformation,
    ProcessMitigationPolicy, ProcessHandleCheckingMode, ProcessKeepAliveCount,
    ProcessCheckStackExtentsMode, ProcessChildProcessInformation,
    ProcessWin32kSyscallFilterInformation:
      LastCall.Expects(PROCESS_QUERY_INFORMATION, @ProcessAccessType);

    ProcessCookie:
      LastCall.Expects(PROCESS_VM_WRITE, @ProcessAccessType);

    ProcessLdtInformation:
      LastCall.Expects(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ,
        @ProcessAccessType);

    ProcessHandleTable:
      LastCall.Expects(PROCESS_QUERY_INFORMATION or PROCESS_DUP_HANDLE,
        @ProcessAccessType);

    ProcessCaptureTrustletLiveDump:
      LastCall.Expects(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ or
        PROCESS_VM_OPERATION, @ProcessAccessType);
  end;

  // Additional access
  case InfoClass of
    ProcessImageFileMapping:
      LastCall.Expects(FILE_EXECUTE or SYNCHRONIZE);
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
      LastCall.Expects(PROCESS_SET_INFORMATION, @ProcessAccessType);

    ProcessRevokeFileHandles, ProcessWorkingSetControl,
    ProcessDefaultCpuSetsInformation, ProcessIumChallengeResponse,
    ProcessHighGraphicsPriorityInformation, ProcessActivityThrottleState,
    ProcessDisableSystemAllowedCpuSets, ProcessEnableReadWriteVmLogging,
    ProcessSystemResourceManagement, ProcessLoaderDetour,
    ProcessCombineSecurityDomainsInformation, ProcessEnableLogging:
      LastCall.Expects(PROCESS_SET_LIMITED_INFORMATION, @ProcessAccessType);

    ProcessExceptionPort:
      LastCall.Expects(PROCESS_SUSPEND_RESUME, @ProcessAccessType);

    ProcessQuotaLimits:
      LastCall.Expects(PROCESS_SET_QUOTA, @ProcessAccessType);

    ProcessSessionInformation:
      LastCall.Expects(PROCESS_SET_INFORMATION or PROCESS_SET_SESSIONID,
       @ProcessAccessType);

    ProcessLdtInformation, ProcessLdtSize, ProcessTelemetryCoverage:
      LastCall.Expects(PROCESS_SET_INFORMATION or PROCESS_VM_WRITE,
        @ProcessAccessType);
  end;

  // Additional access
  case InfoClass of
    ProcessAccessToken:
      LastCall.Expects(TOKEN_ASSIGN_PRIMARY, @TokenAccessType);

    ProcessDeviceMap:
      LastCall.Expects(DIRECTORY_TRAVERSE, @DirectoryAccessType);

    ProcessCombineSecurityDomainsInformation:
      LastCall.Expects(PROCESS_QUERY_LIMITED_INFORMATION, @ProcessAccessType);
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
      LastCall.Expects(THREAD_QUERY_LIMITED_INFORMATION, @ThreadAccessType);

    ThreadDescriptorTableEntry, ThreadQuerySetWin32StartAddress,
    ThreadPerformanceCount, ThreadIsIoPending, ThreadHideFromDebugger,
    ThreadBreakOnTermination, ThreadUmsInformation, ThreadCounterProfiling,
    ThreadCpuAccountingInformation:
      LastCall.Expects(THREAD_QUERY_INFORMATION, @ThreadAccessType);

    ThreadLastSystemCall, ThreadWow64Context:
      LastCall.Expects(THREAD_GET_CONTEXT, @ThreadAccessType);

    ThreadTebInformation:
      LastCall.Expects(THREAD_GET_CONTEXT or THREAD_SET_CONTEXT,
        @ThreadAccessType);
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
      LastCall.Expects(THREAD_SET_LIMITED_INFORMATION, @ThreadAccessType);

    ThreadEnableAlignmentFaultFixup, ThreadZeroTlsCell,
    ThreadIdealProcessor, ThreadHideFromDebugger, ThreadBreakOnTermination,
    ThreadIoPriority, ThreadPagePriority, ThreadGroupInformation,
    ThreadCounterProfiling, ThreadIdealProcessorEx,
    ThreadExplicitCaseSensitivity, ThreadDbgkWerReportActive,
    ThreadPowerThrottlingState:
      LastCall.Expects(THREAD_SET_INFORMATION, @ThreadAccessType);

    ThreadWow64Context:
      LastCall.Expects(THREAD_SET_CONTEXT, @ThreadAccessType);

    ThreadImpersonationToken:
      LastCall.Expects(THREAD_SET_THREAD_TOKEN, @ThreadAccessType);
  end;

  // Additional access
  case InfoClass of
    ThreadImpersonationToken:
      LastCall.Expects(TOKEN_IMPERSONATE, @TokenAccessType);

    ThreadCpuAccountingInformation:
      LastCall.Expects(SESSION_MODIFY_ACCESS, @SessionAccessType);

    ThreadAttachContainer:
      LastCall.Expects(JOB_OBJECT_IMPERSONATE, @JobAccessType);
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
      LastCall.Expects(TOKEN_QUERY_SOURCE, @TokenAccessType);
  else
    LastCall.Expects(TOKEN_QUERY, @TokenAccessType);
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
      LastCall.Expects(TOKEN_ADJUST_DEFAULT or TOKEN_ADJUST_SESSIONID,
        @TokenAccessType);

    TokenLinkedToken:
      LastCall.Expects(TOKEN_ADJUST_DEFAULT or TOKEN_QUERY, @TokenAccessType);

  else
    LastCall.Expects(TOKEN_ADJUST_DEFAULT, @TokenAccessType);
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
      LastCall.Expects(POLICY_VIEW_AUDIT_INFORMATION, @PolicyAccessType);

    PolicyPrimaryDomainInformation, PolicyAccountDomainInformation,
    PolicyLsaServerRoleInformation, PolicyReplicaSourceInformation,
    PolicyDefaultQuotaInformation, PolicyDnsDomainInformation,
    PolicyDnsDomainInformationInt, PolicyLocalAccountDomainInformation:
      LastCall.Expects(POLICY_VIEW_LOCAL_INFORMATION, @PolicyAccessType);

    PolicyPdAccountInformation:
      LastCall.Expects(POLICY_GET_PRIVATE_INFORMATION, @PolicyAccessType);
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
      LastCall.Expects(POLICY_TRUST_ADMIN, @PolicyAccessType);

    PolicyAuditLogInformation, PolicyAuditFullSetInformation:
      LastCall.Expects(POLICY_AUDIT_LOG_ADMIN, @PolicyAccessType);

    PolicyAuditEventsInformation:
      LastCall.Expects(POLICY_SET_AUDIT_REQUIREMENTS, @PolicyAccessType);

    PolicyLsaServerRoleInformation, PolicyReplicaSourceInformation:
      LastCall.Expects(POLICY_SERVER_ADMIN, @PolicyAccessType);

    PolicyDefaultQuotaInformation:
      LastCall.Expects(POLICY_SET_DEFAULT_QUOTA_LIMITS, @PolicyAccessType);
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
      LastCall.Expects(DOMAIN_READ_OTHER_PARAMETERS, @DomainAccessType);

    DomainPasswordInformation, DomainLockoutInformation:
      LastCall.Expects(DOMAIN_READ_PASSWORD_PARAMETERS, @DomainAccessType);

    DomainGeneralInformation2:
      LastCall.Expects(DOMAIN_READ_PASSWORD_PARAMETERS or
        DOMAIN_READ_OTHER_PARAMETERS, @DomainAccessType);
  end;
end;

procedure RtlxComputeDomainSetAccess(var LastCall: TLastCallInfo;
  InfoClass: TDomainInformationClass);
begin
  // See [MS-SAMR]
  case InfoClass of
    DomainPasswordInformation, DomainLockoutInformation:
      LastCall.Expects(DOMAIN_WRITE_PASSWORD_PARAMS, @DomainAccessType);

    DomainLogoffInformation, DomainOemInformation, DomainUasInformation:
      LastCall.Expects(DOMAIN_WRITE_OTHER_PARAMETERS, @DomainAccessType);

    DomainReplicationInformation, DomainServerRoleInformation,
    DomainStateInformation:
      LastCall.Expects(DOMAIN_ADMINISTER_SERVER, @DomainAccessType);
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
      LastCall.Expects(USER_READ_GENERAL, @UserAccessType);

    UserLogonHoursInformation, UserHomeInformation, UserScriptInformation,
    UserProfileInformation, UserWorkStationsInformation:
      LastCall.Expects(USER_READ_LOGON, @UserAccessType);

    UserControlInformation, UserExpiresInformation, UserInternal1Information,
    UserParametersInformation:
      LastCall.Expects(USER_READ_ACCOUNT, @UserAccessType);

    UserPreferencesInformation:
      LastCall.Expects(USER_READ_PREFERENCES or USER_READ_GENERAL,
        @UserAccessType);

    UserLogonInformation, UserAccountInformation:
      LastCall.Expects(USER_READ_GENERAL or USER_READ_PREFERENCES or
        USER_READ_LOGON or USER_READ_ACCOUNT, @UserAccessType);

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
      LastCall.Expects(USER_WRITE_ACCOUNT, @UserAccessType);

    UserPreferencesInformation:
      LastCall.Expects(USER_WRITE_PREFERENCES, @UserAccessType);

    UserSetPasswordInformation:
      LastCall.Expects(USER_FORCE_PASSWORD_CHANGE, @UserAccessType);
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
      LastCall.Expects(SERVICE_PAUSE_CONTINUE, @ScmAccessType);

    SERVICE_CONTROL_STOP:
      LastCall.Expects(SERVICE_STOP, @ScmAccessType);

    SERVICE_CONTROL_INTERROGATE:
      LastCall.Expects(SERVICE_INTERROGATE, @ScmAccessType);
  else
    if (Cardinal(Control) >= 128) and (Cardinal(Control) < 255) then
      LastCall.Expects(SERVICE_USER_DEFINED_CONTROL, @ScmAccessType);
  end;
end;

procedure RtlxComputeSectionFileAccess(var LastCall: TLastCallInfo;
  Win32Protect: Cardinal);
begin
  case Win32Protect and $FF of
    PAGE_NOACCESS, PAGE_READONLY, PAGE_WRITECOPY:
      LastCall.Expects(FILE_READ_DATA, @FileAccessType);

    PAGE_READWRITE:
      LastCall.Expects(FILE_WRITE_DATA or FILE_READ_DATA, @FileAccessType);

    PAGE_EXECUTE:
      LastCall.Expects(FILE_EXECUTE, @FileAccessType);

    PAGE_EXECUTE_READ, PAGE_EXECUTE_WRITECOPY:
      LastCall.Expects(FILE_EXECUTE or FILE_READ_DATA, @FileAccessType);

    PAGE_EXECUTE_READWRITE:
      LastCall.Expects(FILE_EXECUTE or FILE_WRITE_DATA or FILE_READ_DATA,
        @FileAccessType);
  end;
end;

procedure RtlxComputeSectionMapAccess(var LastCall: TLastCallInfo;
  Win32Protect: Cardinal);
begin
  case Win32Protect and $FF of
    PAGE_NOACCESS, PAGE_READONLY, PAGE_WRITECOPY:
      LastCall.Expects(SECTION_MAP_READ, @SectionAccessType);

    PAGE_READWRITE:
      LastCall.Expects(SECTION_MAP_WRITE, @SectionAccessType);

    PAGE_EXECUTE:
      LastCall.Expects(SECTION_MAP_EXECUTE, @SectionAccessType);

    PAGE_EXECUTE_READ, PAGE_EXECUTE_WRITECOPY:
      LastCall.Expects(SECTION_MAP_EXECUTE or SECTION_MAP_READ,
        @SectionAccessType);

    PAGE_EXECUTE_READWRITE:
      LastCall.Expects(SECTION_MAP_EXECUTE or SECTION_MAP_WRITE,
        @SectionAccessType);
  end;
end;

end.
