;// This file defines constant messages for the most common NTSTATUS, HRESULT,
;// and Win32 errors. To avoid collisions, we store them embedded into 
;// NTSTATUS codes, which means:
;//
;// 1. NTSTATUS constants appear as is.
;// 2. HRESULT errors have a facility swap bit (aka NT-facility bit, reserved
;//    bit, or just bit 28) set. For example, E_NOTIMPL (which has a value of
;//    0x80004001 as an HRESULT) appears as 0x90004001 when stored inside an 
;//    NTSTATUS.
;// 3. Win32 errors follow semantics of NTSTATUS_FROM_WIN32 which represents
;//    them as 0xC007xxxx (an unsuccessful NTSTATUS with the Win32 facility).
;//    Note that some Windows functions embed Win32 errors into HRESULTS as 
;//    0x8007xxxx (an HRESULT with the Win32 facility). The caller needs to 
;//    convert such codes to their NTSTATUS representation before looking them
;//    up in the message table.
;//
;// There is a pre-compiled version of this file available: NtUiLib.Errors.res
;//
;// Compiling the message table requires three files that come with
;// Windows SDK: mc.exe, rc.exe, and rcdll.dll. You can find them under
;// %Program Files%\Windows Kits\10\bin\%SDK Version%\%Platform%
;// 
;// Unfortunately, mc.exe does not allow controling the reserved (28) bit
;// and the customer (29) bit through the message text file. Since we are
;// intensively using the reserved bit as a facility swap bit, compiling this
;// file requires patching mc.exe so we can bypass this limitation.
;// 
;// To adjust the maximum value of a facility from 0x0FFF to 0x3FFF, patch
;// this hex sequence in the 64-bit version of mc.exe:
;//
;//   41 B8 FF 0F 00 00 -> 41 B8 FF 3F 00 00
;//
;// Which corresponds to changing
;//
;//   mov r8d, 00000FFF -> mov r8d, 00003FFF
;//
;// so we can use facilities like 0x1xxx to set the reserved bit.
;//
;// After that, compiling the message table requires two simple steps:
;//
;//  1. call mc.exe NtUiLib.Errors.mc -A
;//  2. call rc.exe NtUiLib.Errors.rc
;// 
;// The first action produces a .bin and an .rc file; the second one compiles
;// them into a .res file. We use ASCII (-A switch) to save space since the 
;// constant names do not require localization.
;//

LanguageNames = (
  Neutral = 0x:NtUiLib_Errors
)

SeverityNames = (
  Success = 0x0
  Informational = 0x1
  Warning = 0x2
  Error = 0x3
)

FacilityNames = (
  Null = 0x0
  Debugger = 0x1
  RpcStubs = 0x2
  RpcRuntime = 0x3
  Win32 = 0x7
  TerminalServer = 0xA
  MUI = 0xB
  XmlLite = 0xC
  SxS = 0x15
  Transaction = 0x19
  Log = 0x1A
  VolMgr = 0x38
  BCD = 0x39
  VHD = 0x3A
  SystemIntegrity = 0xE9
  AppExec = 0xEC
  HRESULT_Null = 0x1000
  HRESULT_RPC = 0x1001
  HRESULT_Dispatch = 0x1002
  HRESULT_Storage = 0x1003
  HRESULT_Interface = 0x1004
  HRESULT_Windows = 0x1008
  HRESULT_Security = 0x1009
  HRESULT_WER = 0x101B
  HRESULT_Graphics = 0x1026
  HRESULT_Shell = 0x1027
  HRESULT_VolMgr = 0x1038
  HRESULT_BCD = 0x1039
  HRESULT_VHD = 0x103A
)

;// ------------------------------ NTSTATUS ------------------------------ //

; /* Success */

MessageId = 0x0000 ; // NTSTATUS(0x00000000)
Severity = Success
Facility = Null
Language = Neutral
STATUS_SUCCESS
.

MessageId = 0x0080 ; // NTSTATUS(0x00000080)
Severity = Success
Facility = Null
Language = Neutral
STATUS_ABANDONED
.

MessageId = 0x00C0 ; // NTSTATUS(0x000000C0)
Severity = Success
Facility = Null
Language = Neutral
STATUS_USER_APC
.

MessageId = 0x00FF ; // NTSTATUS(0x000000FF)
Severity = Success
Facility = Null
Language = Neutral
STATUS_ALREADY_COMPLETE
.

MessageId = 0x0100 ; // NTSTATUS(0x00000100)
Severity = Success
Facility = Null
Language = Neutral
STATUS_KERNEL_APC
.

MessageId = 0x0101 ; // NTSTATUS(0x00000101)
Severity = Success
Facility = Null
Language = Neutral
STATUS_ALERTED
.

MessageId = 0x0102 ; // NTSTATUS(0x00000102)
Severity = Success
Facility = Null
Language = Neutral
STATUS_TIMEOUT
.

MessageId = 0x0103 ; // NTSTATUS(0x00000103)
Severity = Success
Facility = Null
Language = Neutral
STATUS_PENDING
.

MessageId = 0x0104 ; // NTSTATUS(0x00000104)
Severity = Success
Facility = Null
Language = Neutral
STATUS_REPARSE
.

MessageId = 0x0105 ; // NTSTATUS(0x00000105)
Severity = Success
Facility = Null
Language = Neutral
STATUS_MORE_ENTRIES
.

MessageId = 0x0106 ; // NTSTATUS(0x00000106)
Severity = Success
Facility = Null
Language = Neutral
STATUS_NOT_ALL_ASSIGNED
.

MessageId = 0x0107 ; // NTSTATUS(0x00000107)
Severity = Success
Facility = Null
Language = Neutral
STATUS_SOME_NOT_MAPPED
.

MessageId = 0x0108 ; // NTSTATUS(0x00000108)
Severity = Success
Facility = Null
Language = Neutral
STATUS_OPLOCK_BREAK_IN_PROGRESS
.

MessageId = 0x0109 ; // NTSTATUS(0x00000109)
Severity = Success
Facility = Null
Language = Neutral
STATUS_VOLUME_MOUNTED
.

MessageId = 0x010A ; // NTSTATUS(0x0000010A)
Severity = Success
Facility = Null
Language = Neutral
STATUS_RXACT_COMMITTED
.

MessageId = 0x010B ; // NTSTATUS(0x0000010B)
Severity = Success
Facility = Null
Language = Neutral
STATUS_NOTIFY_CLEANUP
.

MessageId = 0x010C ; // NTSTATUS(0x0000010C)
Severity = Success
Facility = Null
Language = Neutral
STATUS_NOTIFY_ENUM_DIR
.

MessageId = 0x010D ; // NTSTATUS(0x0000010D)
Severity = Success
Facility = Null
Language = Neutral
STATUS_NO_QUOTAS_FOR_ACCOUNT
.

MessageId = 0x010E ; // NTSTATUS(0x0000010E)
Severity = Success
Facility = Null
Language = Neutral
STATUS_PRIMARY_TRANSPORT_CONNECT_FAILED
.

MessageId = 0x0110 ; // NTSTATUS(0x00000110)
Severity = Success
Facility = Null
Language = Neutral
STATUS_PAGE_FAULT_TRANSITION
.

MessageId = 0x0111 ; // NTSTATUS(0x00000111)
Severity = Success
Facility = Null
Language = Neutral
STATUS_PAGE_FAULT_DEMAND_ZERO
.

MessageId = 0x0112 ; // NTSTATUS(0x00000112)
Severity = Success
Facility = Null
Language = Neutral
STATUS_PAGE_FAULT_COPY_ON_WRITE
.

MessageId = 0x0113 ; // NTSTATUS(0x00000113)
Severity = Success
Facility = Null
Language = Neutral
STATUS_PAGE_FAULT_GUARD_PAGE
.

MessageId = 0x0114 ; // NTSTATUS(0x00000114)
Severity = Success
Facility = Null
Language = Neutral
STATUS_PAGE_FAULT_PAGING_FILE
.

MessageId = 0x0115 ; // NTSTATUS(0x00000115)
Severity = Success
Facility = Null
Language = Neutral
STATUS_CACHE_PAGE_LOCKED
.

MessageId = 0x0116 ; // NTSTATUS(0x00000116)
Severity = Success
Facility = Null
Language = Neutral
STATUS_CRASH_DUMP
.

MessageId = 0x0117 ; // NTSTATUS(0x00000117)
Severity = Success
Facility = Null
Language = Neutral
STATUS_BUFFER_ALL_ZEROS
.

MessageId = 0x0118 ; // NTSTATUS(0x00000118)
Severity = Success
Facility = Null
Language = Neutral
STATUS_REPARSE_OBJECT
.

MessageId = 0x0119 ; // NTSTATUS(0x00000119)
Severity = Success
Facility = Null
Language = Neutral
STATUS_RESOURCE_REQUIREMENTS_CHANGED
.

MessageId = 0x0120 ; // NTSTATUS(0x00000120)
Severity = Success
Facility = Null
Language = Neutral
STATUS_TRANSLATION_COMPLETE
.

MessageId = 0x0121 ; // NTSTATUS(0x00000121)
Severity = Success
Facility = Null
Language = Neutral
STATUS_DS_MEMBERSHIP_EVALUATED_LOCALLY
.

MessageId = 0x0122 ; // NTSTATUS(0x00000122)
Severity = Success
Facility = Null
Language = Neutral
STATUS_NOTHING_TO_TERMINATE
.

MessageId = 0x0123 ; // NTSTATUS(0x00000123)
Severity = Success
Facility = Null
Language = Neutral
STATUS_PROCESS_NOT_IN_JOB
.

MessageId = 0x0124 ; // NTSTATUS(0x00000124)
Severity = Success
Facility = Null
Language = Neutral
STATUS_PROCESS_IN_JOB
.

MessageId = 0x0125 ; // NTSTATUS(0x00000125)
Severity = Success
Facility = Null
Language = Neutral
STATUS_VOLSNAP_HIBERNATE_READY
.

MessageId = 0x0126 ; // NTSTATUS(0x00000126)
Severity = Success
Facility = Null
Language = Neutral
STATUS_FSFILTER_OP_COMPLETED_SUCCESSFULLY
.

MessageId = 0x0127 ; // NTSTATUS(0x00000127)
Severity = Success
Facility = Null
Language = Neutral
STATUS_INTERRUPT_VECTOR_ALREADY_CONNECTED
.

MessageId = 0x0128 ; // NTSTATUS(0x00000128)
Severity = Success
Facility = Null
Language = Neutral
STATUS_INTERRUPT_STILL_CONNECTED
.

MessageId = 0x0129 ; // NTSTATUS(0x00000129)
Severity = Success
Facility = Null
Language = Neutral
STATUS_PROCESS_CLONED
.

MessageId = 0x012A ; // NTSTATUS(0x0000012A)
Severity = Success
Facility = Null
Language = Neutral
STATUS_FILE_LOCKED_WITH_ONLY_READERS
.

MessageId = 0x012B ; // NTSTATUS(0x0000012B)
Severity = Success
Facility = Null
Language = Neutral
STATUS_FILE_LOCKED_WITH_WRITERS
.

MessageId = 0x012C ; // NTSTATUS(0x0000012C)
Severity = Success
Facility = Null
Language = Neutral
STATUS_VALID_IMAGE_HASH
.

MessageId = 0x012D ; // NTSTATUS(0x0000012D)
Severity = Success
Facility = Null
Language = Neutral
STATUS_VALID_CATALOG_HASH
.

MessageId = 0x012E ; // NTSTATUS(0x0000012E)
Severity = Success
Facility = Null
Language = Neutral
STATUS_VALID_STRONG_CODE_HASH
.

MessageId = 0x012F ; // NTSTATUS(0x0000012F)
Severity = Success
Facility = Null
Language = Neutral
STATUS_GHOSTED
.

MessageId = 0x0130 ; // NTSTATUS(0x00000130)
Severity = Success
Facility = Null
Language = Neutral
STATUS_DATA_OVERWRITTEN
.

MessageId = 0x0202 ; // NTSTATUS(0x00000202)
Severity = Success
Facility = Null
Language = Neutral
STATUS_RESOURCEMANAGER_READ_ONLY
.

MessageId = 0x0210 ; // NTSTATUS(0x00000210)
Severity = Success
Facility = Null
Language = Neutral
STATUS_RING_PREVIOUSLY_EMPTY
.

MessageId = 0x0211 ; // NTSTATUS(0x00000211)
Severity = Success
Facility = Null
Language = Neutral
STATUS_RING_PREVIOUSLY_FULL
.

MessageId = 0x0212 ; // NTSTATUS(0x00000212)
Severity = Success
Facility = Null
Language = Neutral
STATUS_RING_PREVIOUSLY_ABOVE_QUOTA
.

MessageId = 0x0213 ; // NTSTATUS(0x00000213)
Severity = Success
Facility = Null
Language = Neutral
STATUS_RING_NEWLY_EMPTY
.

MessageId = 0x0214 ; // NTSTATUS(0x00000214)
Severity = Success
Facility = Null
Language = Neutral
STATUS_RING_SIGNAL_OPPOSITE_ENDPOINT
.

MessageId = 0x0215 ; // NTSTATUS(0x00000215)
Severity = Success
Facility = Null
Language = Neutral
STATUS_OPLOCK_SWITCHED_TO_NEW_HANDLE
.

MessageId = 0x0216 ; // NTSTATUS(0x00000216)
Severity = Success
Facility = Null
Language = Neutral
STATUS_OPLOCK_HANDLE_CLOSED
.

MessageId = 0x0367 ; // NTSTATUS(0x00000367)
Severity = Success
Facility = Null
Language = Neutral
STATUS_WAIT_FOR_OPLOCK
.

MessageId = 0x0368 ; // NTSTATUS(0x00000368)
Severity = Success
Facility = Null
Language = Neutral
STATUS_REPARSE_GLOBAL
.

MessageId = 0x0001 ; // NTSTATUS(0x00010001)
Severity = Success
Facility = Debugger
Language = Neutral
DBG_EXCEPTION_HANDLED
.

MessageId = 0x0002 ; // NTSTATUS(0x00010002)
Severity = Success
Facility = Debugger
Language = Neutral
DBG_CONTINUE
.

; /* Informational */

MessageId = 0x0000 ; // NTSTATUS(0x40000000)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_OBJECT_NAME_EXISTS
.

MessageId = 0x0001 ; // NTSTATUS(0x40000001)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_THREAD_WAS_SUSPENDED
.

MessageId = 0x0002 ; // NTSTATUS(0x40000002)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_WORKING_SET_LIMIT_RANGE
.

MessageId = 0x0003 ; // NTSTATUS(0x40000003)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_IMAGE_NOT_AT_BASE
.

MessageId = 0x0004 ; // NTSTATUS(0x40000004)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_RXACT_STATE_CREATED
.

MessageId = 0x0005 ; // NTSTATUS(0x40000005)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_SEGMENT_NOTIFICATION
.

MessageId = 0x0006 ; // NTSTATUS(0x40000006)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_LOCAL_USER_SESSION_KEY
.

MessageId = 0x0007 ; // NTSTATUS(0x40000007)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_BAD_CURRENT_DIRECTORY
.

MessageId = 0x0008 ; // NTSTATUS(0x40000008)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_SERIAL_MORE_WRITES
.

MessageId = 0x0009 ; // NTSTATUS(0x40000009)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_REGISTRY_RECOVERED
.

MessageId = 0x000A ; // NTSTATUS(0x4000000A)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_FT_READ_RECOVERY_FROM_BACKUP
.

MessageId = 0x000B ; // NTSTATUS(0x4000000B)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_FT_WRITE_RECOVERY
.

MessageId = 0x000C ; // NTSTATUS(0x4000000C)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_SERIAL_COUNTER_TIMEOUT
.

MessageId = 0x000D ; // NTSTATUS(0x4000000D)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_NULL_LM_PASSWORD
.

MessageId = 0x000E ; // NTSTATUS(0x4000000E)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_IMAGE_MACHINE_TYPE_MISMATCH
.

MessageId = 0x000F ; // NTSTATUS(0x4000000F)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_RECEIVE_PARTIAL
.

MessageId = 0x0010 ; // NTSTATUS(0x40000010)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_RECEIVE_EXPEDITED
.

MessageId = 0x0011 ; // NTSTATUS(0x40000011)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_RECEIVE_PARTIAL_EXPEDITED
.

MessageId = 0x0012 ; // NTSTATUS(0x40000012)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_EVENT_DONE
.

MessageId = 0x0013 ; // NTSTATUS(0x40000013)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_EVENT_PENDING
.

MessageId = 0x0014 ; // NTSTATUS(0x40000014)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_CHECKING_FILE_SYSTEM
.

MessageId = 0x0015 ; // NTSTATUS(0x40000015)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_FATAL_APP_EXIT
.

MessageId = 0x0016 ; // NTSTATUS(0x40000016)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_PREDEFINED_HANDLE
.

MessageId = 0x0017 ; // NTSTATUS(0x40000017)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_WAS_UNLOCKED
.

MessageId = 0x0018 ; // NTSTATUS(0x40000018)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_SERVICE_NOTIFICATION
.

MessageId = 0x0019 ; // NTSTATUS(0x40000019)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_WAS_LOCKED
.

MessageId = 0x001A ; // NTSTATUS(0x4000001A)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_LOG_HARD_ERROR
.

MessageId = 0x001B ; // NTSTATUS(0x4000001B)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_ALREADY_WIN32
.

MessageId = 0x001C ; // NTSTATUS(0x4000001C)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_WX86_UNSIMULATE
.

MessageId = 0x001D ; // NTSTATUS(0x4000001D)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_WX86_CONTINUE
.

MessageId = 0x001E ; // NTSTATUS(0x4000001E)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_WX86_SINGLE_STEP
.

MessageId = 0x001F ; // NTSTATUS(0x4000001F)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_WX86_BREAKPOINT
.

MessageId = 0x0020 ; // NTSTATUS(0x40000020)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_WX86_EXCEPTION_CONTINUE
.

MessageId = 0x0021 ; // NTSTATUS(0x40000021)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_WX86_EXCEPTION_LASTCHANCE
.

MessageId = 0x0022 ; // NTSTATUS(0x40000022)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_WX86_EXCEPTION_CHAIN
.

MessageId = 0x0023 ; // NTSTATUS(0x40000023)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_IMAGE_MACHINE_TYPE_MISMATCH_EXE
.

MessageId = 0x0024 ; // NTSTATUS(0x40000024)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_NO_YIELD_PERFORMED
.

MessageId = 0x0025 ; // NTSTATUS(0x40000025)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_TIMER_RESUME_IGNORED
.

MessageId = 0x0026 ; // NTSTATUS(0x40000026)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_ARBITRATION_UNHANDLED
.

MessageId = 0x0027 ; // NTSTATUS(0x40000027)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_CARDBUS_NOT_SUPPORTED
.

MessageId = 0x0028 ; // NTSTATUS(0x40000028)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_WX86_CREATEWX86TIB
.

MessageId = 0x0029 ; // NTSTATUS(0x40000029)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_MP_PROCESSOR_MISMATCH
.

MessageId = 0x002A ; // NTSTATUS(0x4000002A)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_HIBERNATED
.

MessageId = 0x002B ; // NTSTATUS(0x4000002B)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_RESUME_HIBERNATION
.

MessageId = 0x002C ; // NTSTATUS(0x4000002C)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_FIRMWARE_UPDATED
.

MessageId = 0x002D ; // NTSTATUS(0x4000002D)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_DRIVERS_LEAKING_LOCKED_PAGES
.

MessageId = 0x002E ; // NTSTATUS(0x4000002E)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_MESSAGE_RETRIEVED
.

MessageId = 0x002F ; // NTSTATUS(0x4000002F)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_SYSTEM_POWERSTATE_TRANSITION
.

MessageId = 0x0030 ; // NTSTATUS(0x40000030)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_ALPC_CHECK_COMPLETION_LIST
.

MessageId = 0x0031 ; // NTSTATUS(0x40000031)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_SYSTEM_POWERSTATE_COMPLEX_TRANSITION
.

MessageId = 0x0032 ; // NTSTATUS(0x40000032)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_ACCESS_AUDIT_BY_POLICY
.

MessageId = 0x0033 ; // NTSTATUS(0x40000033)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_ABANDON_HIBERFILE
.

MessageId = 0x0034 ; // NTSTATUS(0x40000034)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_BIZRULES_NOT_ENABLED
.

MessageId = 0x0035 ; // NTSTATUS(0x40000035)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_FT_READ_FROM_COPY
.

MessageId = 0x0036 ; // NTSTATUS(0x40000036)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_IMAGE_AT_DIFFERENT_BASE
.

MessageId = 0x0037 ; // NTSTATUS(0x40000037)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_PATCH_DEFERRED
.

MessageId = 0x0038 ; // NTSTATUS(0x40000038)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_EMULATION_BREAKPOINT
.

MessageId = 0x0039 ; // NTSTATUS(0x40000039)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_EMULATION_SYSCALL
.

MessageId = 0x0294 ; // NTSTATUS(0x40000294)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_WAKE_SYSTEM
.

MessageId = 0x0370 ; // NTSTATUS(0x40000370)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_DS_SHUTTING_DOWN
.

MessageId = 0x0807 ; // NTSTATUS(0x40000807)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_DISK_REPAIR_REDIRECTED
.

MessageId = 0xA144 ; // NTSTATUS(0x4000A144)
Severity = Informational
Facility = Null
Language = Neutral
STATUS_SERVICES_FAILED_AUTOSTART
.

MessageId = 0x0001 ; // NTSTATUS(0x40010001)
Severity = Informational
Facility = Debugger
Language = Neutral
DBG_REPLY_LATER
.

MessageId = 0x0002 ; // NTSTATUS(0x40010002)
Severity = Informational
Facility = Debugger
Language = Neutral
DBG_UNABLE_TO_PROVIDE_HANDLE
.

MessageId = 0x0003 ; // NTSTATUS(0x40010003)
Severity = Informational
Facility = Debugger
Language = Neutral
DBG_TERMINATE_THREAD
.

MessageId = 0x0004 ; // NTSTATUS(0x40010004)
Severity = Informational
Facility = Debugger
Language = Neutral
DBG_TERMINATE_PROCESS
.

MessageId = 0x0005 ; // NTSTATUS(0x40010005)
Severity = Informational
Facility = Debugger
Language = Neutral
DBG_CONTROL_C
.

MessageId = 0x0006 ; // NTSTATUS(0x40010006)
Severity = Informational
Facility = Debugger
Language = Neutral
DBG_PRINTEXCEPTION_C
.

MessageId = 0x0007 ; // NTSTATUS(0x40010007)
Severity = Informational
Facility = Debugger
Language = Neutral
DBG_RIPEXCEPTION
.

MessageId = 0x0008 ; // NTSTATUS(0x40010008)
Severity = Informational
Facility = Debugger
Language = Neutral
DBG_CONTROL_BREAK
.

MessageId = 0x0009 ; // NTSTATUS(0x40010009)
Severity = Informational
Facility = Debugger
Language = Neutral
DBG_COMMAND_EXCEPTION
.

MessageId = 0x000A ; // NTSTATUS(0x4001000A)
Severity = Informational
Facility = Debugger
Language = Neutral
DBG_PRINTEXCEPTION_WIDE_C
.

MessageId = 0x0056 ; // NTSTATUS(0x40020056)
Severity = Informational
Facility = RpcStubs
Language = Neutral
RPC_NT_UUID_LOCAL_ONLY
.

MessageId = 0x00AF ; // NTSTATUS(0x400200AF)
Severity = Informational
Facility = RpcStubs
Language = Neutral
RPC_NT_SEND_INCOMPLETE
.

MessageId = 0x0004 ; // NTSTATUS(0x400A0004)
Severity = Informational
Facility = TerminalServer
Language = Neutral
STATUS_CTX_CDM_CONNECT
.

MessageId = 0x0005 ; // NTSTATUS(0x400A0005)
Severity = Informational
Facility = TerminalServer
Language = Neutral
STATUS_CTX_CDM_DISCONNECT
.

MessageId = 0x000D ; // NTSTATUS(0x4015000D)
Severity = Informational
Facility = SxS
Language = Neutral
STATUS_SXS_RELEASE_ACTIVATION_CONTEXT
.

MessageId = 0x0001 ; // NTSTATUS(0x40190001)
Severity = Informational
Facility = Transaction
Language = Neutral
STATUS_HEURISTIC_DAMAGE_POSSIBLE
.

MessageId = 0x0034 ; // NTSTATUS(0x40190034)
Severity = Informational
Facility = Transaction
Language = Neutral
STATUS_RECOVERY_NOT_NEEDED
.

MessageId = 0x0035 ; // NTSTATUS(0x40190035)
Severity = Informational
Facility = Transaction
Language = Neutral
STATUS_RM_ALREADY_STARTED
.

MessageId = 0x000C ; // NTSTATUS(0x401A000C)
Severity = Informational
Facility = Log
Language = Neutral
STATUS_LOG_NO_RESTART
.

; /* Warning */

MessageId = 0x0001 ; // NTSTATUS(0x80000001)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_GUARD_PAGE_VIOLATION
.

MessageId = 0x0002 ; // NTSTATUS(0x80000002)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_DATATYPE_MISALIGNMENT
.

MessageId = 0x0003 ; // NTSTATUS(0x80000003)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_BREAKPOINT
.

MessageId = 0x0004 ; // NTSTATUS(0x80000004)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_SINGLE_STEP
.

MessageId = 0x0005 ; // NTSTATUS(0x80000005)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_BUFFER_OVERFLOW
.

MessageId = 0x0006 ; // NTSTATUS(0x80000006)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_NO_MORE_FILES
.

MessageId = 0x0007 ; // NTSTATUS(0x80000007)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_WAKE_SYSTEM_DEBUGGER
.

MessageId = 0x000A ; // NTSTATUS(0x8000000A)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_HANDLES_CLOSED
.

MessageId = 0x000B ; // NTSTATUS(0x8000000B)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_NO_INHERITANCE
.

MessageId = 0x000C ; // NTSTATUS(0x8000000C)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_GUID_SUBSTITUTION_MADE
.

MessageId = 0x000D ; // NTSTATUS(0x8000000D)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_PARTIAL_COPY
.

MessageId = 0x000E ; // NTSTATUS(0x8000000E)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_DEVICE_PAPER_EMPTY
.

MessageId = 0x000F ; // NTSTATUS(0x8000000F)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_DEVICE_POWERED_OFF
.

MessageId = 0x0010 ; // NTSTATUS(0x80000010)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_DEVICE_OFF_LINE
.

MessageId = 0x0011 ; // NTSTATUS(0x80000011)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_DEVICE_BUSY
.

MessageId = 0x0012 ; // NTSTATUS(0x80000012)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_NO_MORE_EAS
.

MessageId = 0x0013 ; // NTSTATUS(0x80000013)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_INVALID_EA_NAME
.

MessageId = 0x0014 ; // NTSTATUS(0x80000014)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_EA_LIST_INCONSISTENT
.

MessageId = 0x0015 ; // NTSTATUS(0x80000015)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_INVALID_EA_FLAG
.

MessageId = 0x0016 ; // NTSTATUS(0x80000016)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_VERIFY_REQUIRED
.

MessageId = 0x0017 ; // NTSTATUS(0x80000017)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_EXTRANEOUS_INFORMATION
.

MessageId = 0x0018 ; // NTSTATUS(0x80000018)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_RXACT_COMMIT_NECESSARY
.

MessageId = 0x001A ; // NTSTATUS(0x8000001A)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_NO_MORE_ENTRIES
.

MessageId = 0x001B ; // NTSTATUS(0x8000001B)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_FILEMARK_DETECTED
.

MessageId = 0x001C ; // NTSTATUS(0x8000001C)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_MEDIA_CHANGED
.

MessageId = 0x001D ; // NTSTATUS(0x8000001D)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_BUS_RESET
.

MessageId = 0x001E ; // NTSTATUS(0x8000001E)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_END_OF_MEDIA
.

MessageId = 0x001F ; // NTSTATUS(0x8000001F)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_BEGINNING_OF_MEDIA
.

MessageId = 0x0020 ; // NTSTATUS(0x80000020)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_MEDIA_CHECK
.

MessageId = 0x0021 ; // NTSTATUS(0x80000021)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_SETMARK_DETECTED
.

MessageId = 0x0022 ; // NTSTATUS(0x80000022)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_NO_DATA_DETECTED
.

MessageId = 0x0023 ; // NTSTATUS(0x80000023)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_REDIRECTOR_HAS_OPEN_HANDLES
.

MessageId = 0x0024 ; // NTSTATUS(0x80000024)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_SERVER_HAS_OPEN_HANDLES
.

MessageId = 0x0025 ; // NTSTATUS(0x80000025)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_ALREADY_DISCONNECTED
.

MessageId = 0x0026 ; // NTSTATUS(0x80000026)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_LONGJUMP
.

MessageId = 0x0027 ; // NTSTATUS(0x80000027)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_CLEANER_CARTRIDGE_INSTALLED
.

MessageId = 0x0028 ; // NTSTATUS(0x80000028)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_PLUGPLAY_QUERY_VETOED
.

MessageId = 0x0029 ; // NTSTATUS(0x80000029)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_UNWIND_CONSOLIDATE
.

MessageId = 0x002A ; // NTSTATUS(0x8000002A)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_REGISTRY_HIVE_RECOVERED
.

MessageId = 0x002B ; // NTSTATUS(0x8000002B)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_DLL_MIGHT_BE_INSECURE
.

MessageId = 0x002C ; // NTSTATUS(0x8000002C)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_DLL_MIGHT_BE_INCOMPATIBLE
.

MessageId = 0x002D ; // NTSTATUS(0x8000002D)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_STOPPED_ON_SYMLINK
.

MessageId = 0x002E ; // NTSTATUS(0x8000002E)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_CANNOT_GRANT_REQUESTED_OPLOCK
.

MessageId = 0x002F ; // NTSTATUS(0x8000002F)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_NO_ACE_CONDITION
.

MessageId = 0x0030 ; // NTSTATUS(0x80000030)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_DEVICE_SUPPORT_IN_PROGRESS
.

MessageId = 0x0031 ; // NTSTATUS(0x80000031)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_DEVICE_POWER_CYCLE_REQUIRED
.

MessageId = 0x0032 ; // NTSTATUS(0x80000032)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_NO_WORK_DONE
.

MessageId = 0x0033 ; // NTSTATUS(0x80000033)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_RETURN_ADDRESS_HIJACK_ATTEMPT
.

MessageId = 0x0034 ; // NTSTATUS(0x80000034)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_RECOVERABLE_BUGCHECK
.

MessageId = 0x01B6 ; // NTSTATUS(0x800001B6)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_DEVICE_RESET_REQUIRED
.

MessageId = 0x0288 ; // NTSTATUS(0x80000288)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_DEVICE_REQUIRES_CLEANING
.

MessageId = 0x0289 ; // NTSTATUS(0x80000289)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_DEVICE_DOOR_OPEN
.

MessageId = 0x0803 ; // NTSTATUS(0x80000803)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_DATA_LOST_REPAIR
.

MessageId = 0xCF00 ; // NTSTATUS(0x8000CF00)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_PROPERTY_BLOB_CHECKSUM_MISMATCH
.

MessageId = 0xCF04 ; // NTSTATUS(0x8000CF04)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_PROPERTY_BLOB_TOO_LARGE
.

MessageId = 0xCF05 ; // NTSTATUS(0x8000CF05)
Severity = Warning
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_TOO_MANY_PROPERTY_BLOBS
.

MessageId = 0x0001 ; // NTSTATUS(0x80010001)
Severity = Warning
Facility = Debugger
Language = Neutral
DBG_EXCEPTION_NOT_HANDLED
.

MessageId = 0x0009 ; // NTSTATUS(0x80190009)
Severity = Warning
Facility = Transaction
Language = Neutral
STATUS_COULD_NOT_RESIZE_LOG
.

MessageId = 0x0029 ; // NTSTATUS(0x80190029)
Severity = Warning
Facility = Transaction
Language = Neutral
STATUS_NO_TXF_METADATA
.

MessageId = 0x0031 ; // NTSTATUS(0x80190031)
Severity = Warning
Facility = Transaction
Language = Neutral
STATUS_CANT_RECOVER_WITH_HANDLE_OPEN
.

MessageId = 0x0041 ; // NTSTATUS(0x80190041)
Severity = Warning
Facility = Transaction
Language = Neutral
STATUS_TXF_METADATA_ALREADY_PRESENT
.

MessageId = 0x0042 ; // NTSTATUS(0x80190042)
Severity = Warning
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_SCOPE_CALLBACKS_NOT_SET
.

MessageId = 0x0001 ; // NTSTATUS(0x80380001)
Severity = Warning
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_INCOMPLETE_REGENERATION
.

MessageId = 0x0002 ; // NTSTATUS(0x80380002)
Severity = Warning
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_INCOMPLETE_DISK_MIGRATION
.

MessageId = 0x0001 ; // NTSTATUS(0x80390001)
Severity = Warning
Facility = BCD
Language = Neutral
STATUS_BCD_NOT_ALL_ENTRIES_IMPORTED
.

MessageId = 0x0003 ; // NTSTATUS(0x80390003)
Severity = Warning
Facility = BCD
Language = Neutral
STATUS_BCD_NOT_ALL_ENTRIES_SYNCHRONIZED
.

MessageId = 0x0001 ; // NTSTATUS(0x803A0001)
Severity = Warning
Facility = VHD
Language = Neutral
STATUS_QUERY_STORAGE_ERROR
.

; /* Error */

MessageId = 0x0001 ; // NTSTATUS(0xC0000001)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNSUCCESSFUL
.

MessageId = 0x0002 ; // NTSTATUS(0xC0000002)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_IMPLEMENTED
.

MessageId = 0x0003 ; // NTSTATUS(0xC0000003)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_INFO_CLASS
.

MessageId = 0x0004 ; // NTSTATUS(0xC0000004)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INFO_LENGTH_MISMATCH
.

MessageId = 0x0005 ; // NTSTATUS(0xC0000005)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ACCESS_VIOLATION
.

MessageId = 0x0006 ; // NTSTATUS(0xC0000006)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IN_PAGE_ERROR
.

MessageId = 0x0007 ; // NTSTATUS(0xC0000007)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PAGEFILE_QUOTA
.

MessageId = 0x0008 ; // NTSTATUS(0xC0000008)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_HANDLE
.

MessageId = 0x0009 ; // NTSTATUS(0xC0000009)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_INITIAL_STACK
.

MessageId = 0x000A ; // NTSTATUS(0xC000000A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_INITIAL_PC
.

MessageId = 0x000B ; // NTSTATUS(0xC000000B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_CID
.

MessageId = 0x000C ; // NTSTATUS(0xC000000C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TIMER_NOT_CANCELED
.

MessageId = 0x000D ; // NTSTATUS(0xC000000D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PARAMETER
.

MessageId = 0x000E ; // NTSTATUS(0xC000000E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_SUCH_DEVICE
.

MessageId = 0x000F ; // NTSTATUS(0xC000000F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_SUCH_FILE
.

MessageId = 0x0010 ; // NTSTATUS(0xC0000010)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_DEVICE_REQUEST
.

MessageId = 0x0011 ; // NTSTATUS(0xC0000011)
Severity = Error
Facility = Null
Language = Neutral
STATUS_END_OF_FILE
.

MessageId = 0x0012 ; // NTSTATUS(0xC0000012)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WRONG_VOLUME
.

MessageId = 0x0013 ; // NTSTATUS(0xC0000013)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_MEDIA_IN_DEVICE
.

MessageId = 0x0014 ; // NTSTATUS(0xC0000014)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNRECOGNIZED_MEDIA
.

MessageId = 0x0015 ; // NTSTATUS(0xC0000015)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NONEXISTENT_SECTOR
.

MessageId = 0x0016 ; // NTSTATUS(0xC0000016)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MORE_PROCESSING_REQUIRED
.

MessageId = 0x0017 ; // NTSTATUS(0xC0000017)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_MEMORY
.

MessageId = 0x0018 ; // NTSTATUS(0xC0000018)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CONFLICTING_ADDRESSES
.

MessageId = 0x0019 ; // NTSTATUS(0xC0000019)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_MAPPED_VIEW
.

MessageId = 0x001A ; // NTSTATUS(0xC000001A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNABLE_TO_FREE_VM
.

MessageId = 0x001B ; // NTSTATUS(0xC000001B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNABLE_TO_DELETE_SECTION
.

MessageId = 0x001C ; // NTSTATUS(0xC000001C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_SYSTEM_SERVICE
.

MessageId = 0x001D ; // NTSTATUS(0xC000001D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ILLEGAL_INSTRUCTION
.

MessageId = 0x001E ; // NTSTATUS(0xC000001E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_LOCK_SEQUENCE
.

MessageId = 0x001F ; // NTSTATUS(0xC000001F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_VIEW_SIZE
.

MessageId = 0x0020 ; // NTSTATUS(0xC0000020)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_FILE_FOR_SECTION
.

MessageId = 0x0021 ; // NTSTATUS(0xC0000021)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ALREADY_COMMITTED
.

MessageId = 0x0022 ; // NTSTATUS(0xC0000022)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ACCESS_DENIED
.

MessageId = 0x0023 ; // NTSTATUS(0xC0000023)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BUFFER_TOO_SMALL
.

MessageId = 0x0024 ; // NTSTATUS(0xC0000024)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OBJECT_TYPE_MISMATCH
.

MessageId = 0x0025 ; // NTSTATUS(0xC0000025)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NONCONTINUABLE_EXCEPTION
.

MessageId = 0x0026 ; // NTSTATUS(0xC0000026)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_DISPOSITION
.

MessageId = 0x0027 ; // NTSTATUS(0xC0000027)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNWIND
.

MessageId = 0x0028 ; // NTSTATUS(0xC0000028)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_STACK
.

MessageId = 0x0029 ; // NTSTATUS(0xC0000029)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_UNWIND_TARGET
.

MessageId = 0x002A ; // NTSTATUS(0xC000002A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_LOCKED
.

MessageId = 0x002B ; // NTSTATUS(0xC000002B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PARITY_ERROR
.

MessageId = 0x002C ; // NTSTATUS(0xC000002C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNABLE_TO_DECOMMIT_VM
.

MessageId = 0x002D ; // NTSTATUS(0xC000002D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_COMMITTED
.

MessageId = 0x002E ; // NTSTATUS(0xC000002E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PORT_ATTRIBUTES
.

MessageId = 0x002F ; // NTSTATUS(0xC000002F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PORT_MESSAGE_TOO_LONG
.

MessageId = 0x0030 ; // NTSTATUS(0xC0000030)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PARAMETER_MIX
.

MessageId = 0x0031 ; // NTSTATUS(0xC0000031)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_QUOTA_LOWER
.

MessageId = 0x0032 ; // NTSTATUS(0xC0000032)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DISK_CORRUPT_ERROR
.

MessageId = 0x0033 ; // NTSTATUS(0xC0000033)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OBJECT_NAME_INVALID
.

MessageId = 0x0034 ; // NTSTATUS(0xC0000034)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OBJECT_NAME_NOT_FOUND
.

MessageId = 0x0035 ; // NTSTATUS(0xC0000035)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OBJECT_NAME_COLLISION
.

MessageId = 0x0036 ; // NTSTATUS(0xC0000036)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PORT_DO_NOT_DISTURB
.

MessageId = 0x0037 ; // NTSTATUS(0xC0000037)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PORT_DISCONNECTED
.

MessageId = 0x0038 ; // NTSTATUS(0xC0000038)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_ALREADY_ATTACHED
.

MessageId = 0x0039 ; // NTSTATUS(0xC0000039)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OBJECT_PATH_INVALID
.

MessageId = 0x003A ; // NTSTATUS(0xC000003A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OBJECT_PATH_NOT_FOUND
.

MessageId = 0x003B ; // NTSTATUS(0xC000003B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OBJECT_PATH_SYNTAX_BAD
.

MessageId = 0x003C ; // NTSTATUS(0xC000003C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DATA_OVERRUN
.

MessageId = 0x003D ; // NTSTATUS(0xC000003D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DATA_LATE_ERROR
.

MessageId = 0x003E ; // NTSTATUS(0xC000003E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DATA_ERROR
.

MessageId = 0x003F ; // NTSTATUS(0xC000003F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CRC_ERROR
.

MessageId = 0x0040 ; // NTSTATUS(0xC0000040)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SECTION_TOO_BIG
.

MessageId = 0x0041 ; // NTSTATUS(0xC0000041)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PORT_CONNECTION_REFUSED
.

MessageId = 0x0042 ; // NTSTATUS(0xC0000042)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PORT_HANDLE
.

MessageId = 0x0043 ; // NTSTATUS(0xC0000043)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SHARING_VIOLATION
.

MessageId = 0x0044 ; // NTSTATUS(0xC0000044)
Severity = Error
Facility = Null
Language = Neutral
STATUS_QUOTA_EXCEEDED
.

MessageId = 0x0045 ; // NTSTATUS(0xC0000045)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PAGE_PROTECTION
.

MessageId = 0x0046 ; // NTSTATUS(0xC0000046)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MUTANT_NOT_OWNED
.

MessageId = 0x0047 ; // NTSTATUS(0xC0000047)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SEMAPHORE_LIMIT_EXCEEDED
.

MessageId = 0x0048 ; // NTSTATUS(0xC0000048)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PORT_ALREADY_SET
.

MessageId = 0x0049 ; // NTSTATUS(0xC0000049)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SECTION_NOT_IMAGE
.

MessageId = 0x004A ; // NTSTATUS(0xC000004A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SUSPEND_COUNT_EXCEEDED
.

MessageId = 0x004B ; // NTSTATUS(0xC000004B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_THREAD_IS_TERMINATING
.

MessageId = 0x004C ; // NTSTATUS(0xC000004C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_WORKING_SET_LIMIT
.

MessageId = 0x004D ; // NTSTATUS(0xC000004D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INCOMPATIBLE_FILE_MAP
.

MessageId = 0x004E ; // NTSTATUS(0xC000004E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SECTION_PROTECTION
.

MessageId = 0x004F ; // NTSTATUS(0xC000004F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_EAS_NOT_SUPPORTED
.

MessageId = 0x0050 ; // NTSTATUS(0xC0000050)
Severity = Error
Facility = Null
Language = Neutral
STATUS_EA_TOO_LARGE
.

MessageId = 0x0051 ; // NTSTATUS(0xC0000051)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NONEXISTENT_EA_ENTRY
.

MessageId = 0x0052 ; // NTSTATUS(0xC0000052)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_EAS_ON_FILE
.

MessageId = 0x0053 ; // NTSTATUS(0xC0000053)
Severity = Error
Facility = Null
Language = Neutral
STATUS_EA_CORRUPT_ERROR
.

MessageId = 0x0054 ; // NTSTATUS(0xC0000054)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_LOCK_CONFLICT
.

MessageId = 0x0055 ; // NTSTATUS(0xC0000055)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOCK_NOT_GRANTED
.

MessageId = 0x0056 ; // NTSTATUS(0xC0000056)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DELETE_PENDING
.

MessageId = 0x0057 ; // NTSTATUS(0xC0000057)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CTL_FILE_NOT_SUPPORTED
.

MessageId = 0x0058 ; // NTSTATUS(0xC0000058)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNKNOWN_REVISION
.

MessageId = 0x0059 ; // NTSTATUS(0xC0000059)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REVISION_MISMATCH
.

MessageId = 0x005A ; // NTSTATUS(0xC000005A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_OWNER
.

MessageId = 0x005B ; // NTSTATUS(0xC000005B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PRIMARY_GROUP
.

MessageId = 0x005C ; // NTSTATUS(0xC000005C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_IMPERSONATION_TOKEN
.

MessageId = 0x005D ; // NTSTATUS(0xC000005D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CANT_DISABLE_MANDATORY
.

MessageId = 0x005E ; // NTSTATUS(0xC000005E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_LOGON_SERVERS
.

MessageId = 0x005F ; // NTSTATUS(0xC000005F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_SUCH_LOGON_SESSION
.

MessageId = 0x0060 ; // NTSTATUS(0xC0000060)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_SUCH_PRIVILEGE
.

MessageId = 0x0061 ; // NTSTATUS(0xC0000061)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PRIVILEGE_NOT_HELD
.

MessageId = 0x0062 ; // NTSTATUS(0xC0000062)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_ACCOUNT_NAME
.

MessageId = 0x0063 ; // NTSTATUS(0xC0000063)
Severity = Error
Facility = Null
Language = Neutral
STATUS_USER_EXISTS
.

MessageId = 0x0064 ; // NTSTATUS(0xC0000064)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_SUCH_USER
.

MessageId = 0x0065 ; // NTSTATUS(0xC0000065)
Severity = Error
Facility = Null
Language = Neutral
STATUS_GROUP_EXISTS
.

MessageId = 0x0066 ; // NTSTATUS(0xC0000066)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_SUCH_GROUP
.

MessageId = 0x0067 ; // NTSTATUS(0xC0000067)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MEMBER_IN_GROUP
.

MessageId = 0x0068 ; // NTSTATUS(0xC0000068)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MEMBER_NOT_IN_GROUP
.

MessageId = 0x0069 ; // NTSTATUS(0xC0000069)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LAST_ADMIN
.

MessageId = 0x006A ; // NTSTATUS(0xC000006A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WRONG_PASSWORD
.

MessageId = 0x006B ; // NTSTATUS(0xC000006B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ILL_FORMED_PASSWORD
.

MessageId = 0x006C ; // NTSTATUS(0xC000006C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PASSWORD_RESTRICTION
.

MessageId = 0x006D ; // NTSTATUS(0xC000006D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOGON_FAILURE
.

MessageId = 0x006E ; // NTSTATUS(0xC000006E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ACCOUNT_RESTRICTION
.

MessageId = 0x006F ; // NTSTATUS(0xC000006F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_LOGON_HOURS
.

MessageId = 0x0070 ; // NTSTATUS(0xC0000070)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_WORKSTATION
.

MessageId = 0x0071 ; // NTSTATUS(0xC0000071)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PASSWORD_EXPIRED
.

MessageId = 0x0072 ; // NTSTATUS(0xC0000072)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ACCOUNT_DISABLED
.

MessageId = 0x0073 ; // NTSTATUS(0xC0000073)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NONE_MAPPED
.

MessageId = 0x0074 ; // NTSTATUS(0xC0000074)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_MANY_LUIDS_REQUESTED
.

MessageId = 0x0075 ; // NTSTATUS(0xC0000075)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LUIDS_EXHAUSTED
.

MessageId = 0x0076 ; // NTSTATUS(0xC0000076)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_SUB_AUTHORITY
.

MessageId = 0x0077 ; // NTSTATUS(0xC0000077)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_ACL
.

MessageId = 0x0078 ; // NTSTATUS(0xC0000078)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_SID
.

MessageId = 0x0079 ; // NTSTATUS(0xC0000079)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_SECURITY_DESCR
.

MessageId = 0x007A ; // NTSTATUS(0xC000007A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PROCEDURE_NOT_FOUND
.

MessageId = 0x007B ; // NTSTATUS(0xC000007B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_IMAGE_FORMAT
.

MessageId = 0x007C ; // NTSTATUS(0xC000007C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_TOKEN
.

MessageId = 0x007D ; // NTSTATUS(0xC000007D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_INHERITANCE_ACL
.

MessageId = 0x007E ; // NTSTATUS(0xC000007E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RANGE_NOT_LOCKED
.

MessageId = 0x007F ; // NTSTATUS(0xC000007F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DISK_FULL
.

MessageId = 0x0080 ; // NTSTATUS(0xC0000080)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SERVER_DISABLED
.

MessageId = 0x0081 ; // NTSTATUS(0xC0000081)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SERVER_NOT_DISABLED
.

MessageId = 0x0082 ; // NTSTATUS(0xC0000082)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_MANY_GUIDS_REQUESTED
.

MessageId = 0x0083 ; // NTSTATUS(0xC0000083)
Severity = Error
Facility = Null
Language = Neutral
STATUS_GUIDS_EXHAUSTED
.

MessageId = 0x0084 ; // NTSTATUS(0xC0000084)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_ID_AUTHORITY
.

MessageId = 0x0085 ; // NTSTATUS(0xC0000085)
Severity = Error
Facility = Null
Language = Neutral
STATUS_AGENTS_EXHAUSTED
.

MessageId = 0x0086 ; // NTSTATUS(0xC0000086)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_VOLUME_LABEL
.

MessageId = 0x0087 ; // NTSTATUS(0xC0000087)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SECTION_NOT_EXTENDED
.

MessageId = 0x0088 ; // NTSTATUS(0xC0000088)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_MAPPED_DATA
.

MessageId = 0x0089 ; // NTSTATUS(0xC0000089)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RESOURCE_DATA_NOT_FOUND
.

MessageId = 0x008A ; // NTSTATUS(0xC000008A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RESOURCE_TYPE_NOT_FOUND
.

MessageId = 0x008B ; // NTSTATUS(0xC000008B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RESOURCE_NAME_NOT_FOUND
.

MessageId = 0x008C ; // NTSTATUS(0xC000008C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ARRAY_BOUNDS_EXCEEDED
.

MessageId = 0x008D ; // NTSTATUS(0xC000008D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FLOAT_DENORMAL_OPERAND
.

MessageId = 0x008E ; // NTSTATUS(0xC000008E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FLOAT_DIVIDE_BY_ZERO
.

MessageId = 0x008F ; // NTSTATUS(0xC000008F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FLOAT_INEXACT_RESULT
.

MessageId = 0x0090 ; // NTSTATUS(0xC0000090)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FLOAT_INVALID_OPERATION
.

MessageId = 0x0091 ; // NTSTATUS(0xC0000091)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FLOAT_OVERFLOW
.

MessageId = 0x0092 ; // NTSTATUS(0xC0000092)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FLOAT_STACK_CHECK
.

MessageId = 0x0093 ; // NTSTATUS(0xC0000093)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FLOAT_UNDERFLOW
.

MessageId = 0x0094 ; // NTSTATUS(0xC0000094)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INTEGER_DIVIDE_BY_ZERO
.

MessageId = 0x0095 ; // NTSTATUS(0xC0000095)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INTEGER_OVERFLOW
.

MessageId = 0x0096 ; // NTSTATUS(0xC0000096)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PRIVILEGED_INSTRUCTION
.

MessageId = 0x0097 ; // NTSTATUS(0xC0000097)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_MANY_PAGING_FILES
.

MessageId = 0x0098 ; // NTSTATUS(0xC0000098)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_INVALID
.

MessageId = 0x0099 ; // NTSTATUS(0xC0000099)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ALLOTTED_SPACE_EXCEEDED
.

MessageId = 0x009A ; // NTSTATUS(0xC000009A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INSUFFICIENT_RESOURCES
.

MessageId = 0x009B ; // NTSTATUS(0xC000009B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DFS_EXIT_PATH_FOUND
.

MessageId = 0x009C ; // NTSTATUS(0xC000009C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_DATA_ERROR
.

MessageId = 0x009D ; // NTSTATUS(0xC000009D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_NOT_CONNECTED
.

MessageId = 0x009E ; // NTSTATUS(0xC000009E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_POWER_FAILURE
.

MessageId = 0x009F ; // NTSTATUS(0xC000009F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FREE_VM_NOT_AT_BASE
.

MessageId = 0x00A0 ; // NTSTATUS(0xC00000A0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MEMORY_NOT_ALLOCATED
.

MessageId = 0x00A1 ; // NTSTATUS(0xC00000A1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WORKING_SET_QUOTA
.

MessageId = 0x00A2 ; // NTSTATUS(0xC00000A2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MEDIA_WRITE_PROTECTED
.

MessageId = 0x00A3 ; // NTSTATUS(0xC00000A3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_NOT_READY
.

MessageId = 0x00A4 ; // NTSTATUS(0xC00000A4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_GROUP_ATTRIBUTES
.

MessageId = 0x00A5 ; // NTSTATUS(0xC00000A5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_IMPERSONATION_LEVEL
.

MessageId = 0x00A6 ; // NTSTATUS(0xC00000A6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CANT_OPEN_ANONYMOUS
.

MessageId = 0x00A7 ; // NTSTATUS(0xC00000A7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_VALIDATION_CLASS
.

MessageId = 0x00A8 ; // NTSTATUS(0xC00000A8)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_TOKEN_TYPE
.

MessageId = 0x00A9 ; // NTSTATUS(0xC00000A9)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_MASTER_BOOT_RECORD
.

MessageId = 0x00AA ; // NTSTATUS(0xC00000AA)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INSTRUCTION_MISALIGNMENT
.

MessageId = 0x00AB ; // NTSTATUS(0xC00000AB)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INSTANCE_NOT_AVAILABLE
.

MessageId = 0x00AC ; // NTSTATUS(0xC00000AC)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PIPE_NOT_AVAILABLE
.

MessageId = 0x00AD ; // NTSTATUS(0xC00000AD)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PIPE_STATE
.

MessageId = 0x00AE ; // NTSTATUS(0xC00000AE)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PIPE_BUSY
.

MessageId = 0x00AF ; // NTSTATUS(0xC00000AF)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ILLEGAL_FUNCTION
.

MessageId = 0x00B0 ; // NTSTATUS(0xC00000B0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PIPE_DISCONNECTED
.

MessageId = 0x00B1 ; // NTSTATUS(0xC00000B1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PIPE_CLOSING
.

MessageId = 0x00B2 ; // NTSTATUS(0xC00000B2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PIPE_CONNECTED
.

MessageId = 0x00B3 ; // NTSTATUS(0xC00000B3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PIPE_LISTENING
.

MessageId = 0x00B4 ; // NTSTATUS(0xC00000B4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_READ_MODE
.

MessageId = 0x00B5 ; // NTSTATUS(0xC00000B5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IO_TIMEOUT
.

MessageId = 0x00B6 ; // NTSTATUS(0xC00000B6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_FORCED_CLOSED
.

MessageId = 0x00B7 ; // NTSTATUS(0xC00000B7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PROFILING_NOT_STARTED
.

MessageId = 0x00B8 ; // NTSTATUS(0xC00000B8)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PROFILING_NOT_STOPPED
.

MessageId = 0x00B9 ; // NTSTATUS(0xC00000B9)
Severity = Error
Facility = Null
Language = Neutral
STATUS_COULD_NOT_INTERPRET
.

MessageId = 0x00BA ; // NTSTATUS(0xC00000BA)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_IS_A_DIRECTORY
.

MessageId = 0x00BB ; // NTSTATUS(0xC00000BB)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SUPPORTED
.

MessageId = 0x00BC ; // NTSTATUS(0xC00000BC)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REMOTE_NOT_LISTENING
.

MessageId = 0x00BD ; // NTSTATUS(0xC00000BD)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DUPLICATE_NAME
.

MessageId = 0x00BE ; // NTSTATUS(0xC00000BE)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_NETWORK_PATH
.

MessageId = 0x00BF ; // NTSTATUS(0xC00000BF)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NETWORK_BUSY
.

MessageId = 0x00C0 ; // NTSTATUS(0xC00000C0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_DOES_NOT_EXIST
.

MessageId = 0x00C1 ; // NTSTATUS(0xC00000C1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_MANY_COMMANDS
.

MessageId = 0x00C2 ; // NTSTATUS(0xC00000C2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ADAPTER_HARDWARE_ERROR
.

MessageId = 0x00C3 ; // NTSTATUS(0xC00000C3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_NETWORK_RESPONSE
.

MessageId = 0x00C4 ; // NTSTATUS(0xC00000C4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNEXPECTED_NETWORK_ERROR
.

MessageId = 0x00C5 ; // NTSTATUS(0xC00000C5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_REMOTE_ADAPTER
.

MessageId = 0x00C6 ; // NTSTATUS(0xC00000C6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PRINT_QUEUE_FULL
.

MessageId = 0x00C7 ; // NTSTATUS(0xC00000C7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_SPOOL_SPACE
.

MessageId = 0x00C8 ; // NTSTATUS(0xC00000C8)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PRINT_CANCELLED
.

MessageId = 0x00C9 ; // NTSTATUS(0xC00000C9)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NETWORK_NAME_DELETED
.

MessageId = 0x00CA ; // NTSTATUS(0xC00000CA)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NETWORK_ACCESS_DENIED
.

MessageId = 0x00CB ; // NTSTATUS(0xC00000CB)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_DEVICE_TYPE
.

MessageId = 0x00CC ; // NTSTATUS(0xC00000CC)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_NETWORK_NAME
.

MessageId = 0x00CD ; // NTSTATUS(0xC00000CD)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_MANY_NAMES
.

MessageId = 0x00CE ; // NTSTATUS(0xC00000CE)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_MANY_SESSIONS
.

MessageId = 0x00CF ; // NTSTATUS(0xC00000CF)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SHARING_PAUSED
.

MessageId = 0x00D0 ; // NTSTATUS(0xC00000D0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REQUEST_NOT_ACCEPTED
.

MessageId = 0x00D1 ; // NTSTATUS(0xC00000D1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REDIRECTOR_PAUSED
.

MessageId = 0x00D2 ; // NTSTATUS(0xC00000D2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NET_WRITE_FAULT
.

MessageId = 0x00D3 ; // NTSTATUS(0xC00000D3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PROFILING_AT_LIMIT
.

MessageId = 0x00D4 ; // NTSTATUS(0xC00000D4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SAME_DEVICE
.

MessageId = 0x00D5 ; // NTSTATUS(0xC00000D5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_RENAMED
.

MessageId = 0x00D6 ; // NTSTATUS(0xC00000D6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VIRTUAL_CIRCUIT_CLOSED
.

MessageId = 0x00D7 ; // NTSTATUS(0xC00000D7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_SECURITY_ON_OBJECT
.

MessageId = 0x00D8 ; // NTSTATUS(0xC00000D8)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CANT_WAIT
.

MessageId = 0x00D9 ; // NTSTATUS(0xC00000D9)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PIPE_EMPTY
.

MessageId = 0x00DA ; // NTSTATUS(0xC00000DA)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CANT_ACCESS_DOMAIN_INFO
.

MessageId = 0x00DB ; // NTSTATUS(0xC00000DB)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CANT_TERMINATE_SELF
.

MessageId = 0x00DC ; // NTSTATUS(0xC00000DC)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_SERVER_STATE
.

MessageId = 0x00DD ; // NTSTATUS(0xC00000DD)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_DOMAIN_STATE
.

MessageId = 0x00DE ; // NTSTATUS(0xC00000DE)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_DOMAIN_ROLE
.

MessageId = 0x00DF ; // NTSTATUS(0xC00000DF)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_SUCH_DOMAIN
.

MessageId = 0x00E0 ; // NTSTATUS(0xC00000E0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DOMAIN_EXISTS
.

MessageId = 0x00E1 ; // NTSTATUS(0xC00000E1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DOMAIN_LIMIT_EXCEEDED
.

MessageId = 0x00E2 ; // NTSTATUS(0xC00000E2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OPLOCK_NOT_GRANTED
.

MessageId = 0x00E3 ; // NTSTATUS(0xC00000E3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_OPLOCK_PROTOCOL
.

MessageId = 0x00E4 ; // NTSTATUS(0xC00000E4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INTERNAL_DB_CORRUPTION
.

MessageId = 0x00E5 ; // NTSTATUS(0xC00000E5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INTERNAL_ERROR
.

MessageId = 0x00E6 ; // NTSTATUS(0xC00000E6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_GENERIC_NOT_MAPPED
.

MessageId = 0x00E7 ; // NTSTATUS(0xC00000E7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_DESCRIPTOR_FORMAT
.

MessageId = 0x00E8 ; // NTSTATUS(0xC00000E8)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_USER_BUFFER
.

MessageId = 0x00E9 ; // NTSTATUS(0xC00000E9)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNEXPECTED_IO_ERROR
.

MessageId = 0x00EA ; // NTSTATUS(0xC00000EA)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNEXPECTED_MM_CREATE_ERR
.

MessageId = 0x00EB ; // NTSTATUS(0xC00000EB)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNEXPECTED_MM_MAP_ERROR
.

MessageId = 0x00EC ; // NTSTATUS(0xC00000EC)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNEXPECTED_MM_EXTEND_ERR
.

MessageId = 0x00ED ; // NTSTATUS(0xC00000ED)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_LOGON_PROCESS
.

MessageId = 0x00EE ; // NTSTATUS(0xC00000EE)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOGON_SESSION_EXISTS
.

MessageId = 0x00EF ; // NTSTATUS(0xC00000EF)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PARAMETER_1
.

MessageId = 0x00F0 ; // NTSTATUS(0xC00000F0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PARAMETER_2
.

MessageId = 0x00F1 ; // NTSTATUS(0xC00000F1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PARAMETER_3
.

MessageId = 0x00F2 ; // NTSTATUS(0xC00000F2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PARAMETER_4
.

MessageId = 0x00F3 ; // NTSTATUS(0xC00000F3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PARAMETER_5
.

MessageId = 0x00F4 ; // NTSTATUS(0xC00000F4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PARAMETER_6
.

MessageId = 0x00F5 ; // NTSTATUS(0xC00000F5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PARAMETER_7
.

MessageId = 0x00F6 ; // NTSTATUS(0xC00000F6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PARAMETER_8
.

MessageId = 0x00F7 ; // NTSTATUS(0xC00000F7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PARAMETER_9
.

MessageId = 0x00F8 ; // NTSTATUS(0xC00000F8)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PARAMETER_10
.

MessageId = 0x00F9 ; // NTSTATUS(0xC00000F9)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PARAMETER_11
.

MessageId = 0x00FA ; // NTSTATUS(0xC00000FA)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PARAMETER_12
.

MessageId = 0x00FB ; // NTSTATUS(0xC00000FB)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REDIRECTOR_NOT_STARTED
.

MessageId = 0x00FC ; // NTSTATUS(0xC00000FC)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REDIRECTOR_STARTED
.

MessageId = 0x00FD ; // NTSTATUS(0xC00000FD)
Severity = Error
Facility = Null
Language = Neutral
STATUS_STACK_OVERFLOW
.

MessageId = 0x00FE ; // NTSTATUS(0xC00000FE)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_SUCH_PACKAGE
.

MessageId = 0x00FF ; // NTSTATUS(0xC00000FF)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_FUNCTION_TABLE
.

MessageId = 0x0100 ; // NTSTATUS(0xC0000100)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VARIABLE_NOT_FOUND
.

MessageId = 0x0101 ; // NTSTATUS(0xC0000101)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DIRECTORY_NOT_EMPTY
.

MessageId = 0x0102 ; // NTSTATUS(0xC0000102)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_CORRUPT_ERROR
.

MessageId = 0x0103 ; // NTSTATUS(0xC0000103)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_A_DIRECTORY
.

MessageId = 0x0104 ; // NTSTATUS(0xC0000104)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_LOGON_SESSION_STATE
.

MessageId = 0x0105 ; // NTSTATUS(0xC0000105)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOGON_SESSION_COLLISION
.

MessageId = 0x0106 ; // NTSTATUS(0xC0000106)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NAME_TOO_LONG
.

MessageId = 0x0107 ; // NTSTATUS(0xC0000107)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILES_OPEN
.

MessageId = 0x0108 ; // NTSTATUS(0xC0000108)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CONNECTION_IN_USE
.

MessageId = 0x0109 ; // NTSTATUS(0xC0000109)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MESSAGE_NOT_FOUND
.

MessageId = 0x010A ; // NTSTATUS(0xC000010A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PROCESS_IS_TERMINATING
.

MessageId = 0x010B ; // NTSTATUS(0xC000010B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_LOGON_TYPE
.

MessageId = 0x010C ; // NTSTATUS(0xC000010C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_GUID_TRANSLATION
.

MessageId = 0x010D ; // NTSTATUS(0xC000010D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CANNOT_IMPERSONATE
.

MessageId = 0x010E ; // NTSTATUS(0xC000010E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IMAGE_ALREADY_LOADED
.

MessageId = 0x0117 ; // NTSTATUS(0xC0000117)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_LDT
.

MessageId = 0x0118 ; // NTSTATUS(0xC0000118)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_LDT_SIZE
.

MessageId = 0x0119 ; // NTSTATUS(0xC0000119)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_LDT_OFFSET
.

MessageId = 0x011A ; // NTSTATUS(0xC000011A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_LDT_DESCRIPTOR
.

MessageId = 0x011B ; // NTSTATUS(0xC000011B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_IMAGE_NE_FORMAT
.

MessageId = 0x011C ; // NTSTATUS(0xC000011C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RXACT_INVALID_STATE
.

MessageId = 0x011D ; // NTSTATUS(0xC000011D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RXACT_COMMIT_FAILURE
.

MessageId = 0x011E ; // NTSTATUS(0xC000011E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MAPPED_FILE_SIZE_ZERO
.

MessageId = 0x011F ; // NTSTATUS(0xC000011F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_MANY_OPENED_FILES
.

MessageId = 0x0120 ; // NTSTATUS(0xC0000120)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CANCELLED
.

MessageId = 0x0121 ; // NTSTATUS(0xC0000121)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CANNOT_DELETE
.

MessageId = 0x0122 ; // NTSTATUS(0xC0000122)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_COMPUTER_NAME
.

MessageId = 0x0123 ; // NTSTATUS(0xC0000123)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_DELETED
.

MessageId = 0x0124 ; // NTSTATUS(0xC0000124)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SPECIAL_ACCOUNT
.

MessageId = 0x0125 ; // NTSTATUS(0xC0000125)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SPECIAL_GROUP
.

MessageId = 0x0126 ; // NTSTATUS(0xC0000126)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SPECIAL_USER
.

MessageId = 0x0127 ; // NTSTATUS(0xC0000127)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MEMBERS_PRIMARY_GROUP
.

MessageId = 0x0128 ; // NTSTATUS(0xC0000128)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_CLOSED
.

MessageId = 0x0129 ; // NTSTATUS(0xC0000129)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_MANY_THREADS
.

MessageId = 0x012A ; // NTSTATUS(0xC000012A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_THREAD_NOT_IN_PROCESS
.

MessageId = 0x012B ; // NTSTATUS(0xC000012B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOKEN_ALREADY_IN_USE
.

MessageId = 0x012C ; // NTSTATUS(0xC000012C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PAGEFILE_QUOTA_EXCEEDED
.

MessageId = 0x012D ; // NTSTATUS(0xC000012D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_COMMITMENT_LIMIT
.

MessageId = 0x012E ; // NTSTATUS(0xC000012E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_IMAGE_LE_FORMAT
.

MessageId = 0x012F ; // NTSTATUS(0xC000012F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_IMAGE_NOT_MZ
.

MessageId = 0x0130 ; // NTSTATUS(0xC0000130)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_IMAGE_PROTECT
.

MessageId = 0x0131 ; // NTSTATUS(0xC0000131)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_IMAGE_WIN_16
.

MessageId = 0x0132 ; // NTSTATUS(0xC0000132)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOGON_SERVER_CONFLICT
.

MessageId = 0x0133 ; // NTSTATUS(0xC0000133)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TIME_DIFFERENCE_AT_DC
.

MessageId = 0x0134 ; // NTSTATUS(0xC0000134)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SYNCHRONIZATION_REQUIRED
.

MessageId = 0x0135 ; // NTSTATUS(0xC0000135)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DLL_NOT_FOUND
.

MessageId = 0x0136 ; // NTSTATUS(0xC0000136)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OPEN_FAILED
.

MessageId = 0x0137 ; // NTSTATUS(0xC0000137)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IO_PRIVILEGE_FAILED
.

MessageId = 0x0138 ; // NTSTATUS(0xC0000138)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ORDINAL_NOT_FOUND
.

MessageId = 0x0139 ; // NTSTATUS(0xC0000139)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ENTRYPOINT_NOT_FOUND
.

MessageId = 0x013A ; // NTSTATUS(0xC000013A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CONTROL_C_EXIT
.

MessageId = 0x013B ; // NTSTATUS(0xC000013B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOCAL_DISCONNECT
.

MessageId = 0x013C ; // NTSTATUS(0xC000013C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REMOTE_DISCONNECT
.

MessageId = 0x013D ; // NTSTATUS(0xC000013D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REMOTE_RESOURCES
.

MessageId = 0x013E ; // NTSTATUS(0xC000013E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LINK_FAILED
.

MessageId = 0x013F ; // NTSTATUS(0xC000013F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LINK_TIMEOUT
.

MessageId = 0x0140 ; // NTSTATUS(0xC0000140)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_CONNECTION
.

MessageId = 0x0141 ; // NTSTATUS(0xC0000141)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_ADDRESS
.

MessageId = 0x0142 ; // NTSTATUS(0xC0000142)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DLL_INIT_FAILED
.

MessageId = 0x0143 ; // NTSTATUS(0xC0000143)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MISSING_SYSTEMFILE
.

MessageId = 0x0144 ; // NTSTATUS(0xC0000144)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNHANDLED_EXCEPTION
.

MessageId = 0x0145 ; // NTSTATUS(0xC0000145)
Severity = Error
Facility = Null
Language = Neutral
STATUS_APP_INIT_FAILURE
.

MessageId = 0x0146 ; // NTSTATUS(0xC0000146)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PAGEFILE_CREATE_FAILED
.

MessageId = 0x0147 ; // NTSTATUS(0xC0000147)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_PAGEFILE
.

MessageId = 0x0148 ; // NTSTATUS(0xC0000148)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_LEVEL
.

MessageId = 0x0149 ; // NTSTATUS(0xC0000149)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WRONG_PASSWORD_CORE
.

MessageId = 0x014A ; // NTSTATUS(0xC000014A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ILLEGAL_FLOAT_CONTEXT
.

MessageId = 0x014B ; // NTSTATUS(0xC000014B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PIPE_BROKEN
.

MessageId = 0x014C ; // NTSTATUS(0xC000014C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REGISTRY_CORRUPT
.

MessageId = 0x014D ; // NTSTATUS(0xC000014D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REGISTRY_IO_FAILED
.

MessageId = 0x014E ; // NTSTATUS(0xC000014E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_EVENT_PAIR
.

MessageId = 0x014F ; // NTSTATUS(0xC000014F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNRECOGNIZED_VOLUME
.

MessageId = 0x0150 ; // NTSTATUS(0xC0000150)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SERIAL_NO_DEVICE_INITED
.

MessageId = 0x0151 ; // NTSTATUS(0xC0000151)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_SUCH_ALIAS
.

MessageId = 0x0152 ; // NTSTATUS(0xC0000152)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MEMBER_NOT_IN_ALIAS
.

MessageId = 0x0153 ; // NTSTATUS(0xC0000153)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MEMBER_IN_ALIAS
.

MessageId = 0x0154 ; // NTSTATUS(0xC0000154)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ALIAS_EXISTS
.

MessageId = 0x0155 ; // NTSTATUS(0xC0000155)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOGON_NOT_GRANTED
.

MessageId = 0x0156 ; // NTSTATUS(0xC0000156)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_MANY_SECRETS
.

MessageId = 0x0157 ; // NTSTATUS(0xC0000157)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SECRET_TOO_LONG
.

MessageId = 0x0158 ; // NTSTATUS(0xC0000158)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INTERNAL_DB_ERROR
.

MessageId = 0x0159 ; // NTSTATUS(0xC0000159)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FULLSCREEN_MODE
.

MessageId = 0x015A ; // NTSTATUS(0xC000015A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_MANY_CONTEXT_IDS
.

MessageId = 0x015B ; // NTSTATUS(0xC000015B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOGON_TYPE_NOT_GRANTED
.

MessageId = 0x015C ; // NTSTATUS(0xC000015C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_REGISTRY_FILE
.

MessageId = 0x015D ; // NTSTATUS(0xC000015D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NT_CROSS_ENCRYPTION_REQUIRED
.

MessageId = 0x015E ; // NTSTATUS(0xC000015E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DOMAIN_CTRLR_CONFIG_ERROR
.

MessageId = 0x015F ; // NTSTATUS(0xC000015F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FT_MISSING_MEMBER
.

MessageId = 0x0160 ; // NTSTATUS(0xC0000160)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ILL_FORMED_SERVICE_ENTRY
.

MessageId = 0x0161 ; // NTSTATUS(0xC0000161)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ILLEGAL_CHARACTER
.

MessageId = 0x0162 ; // NTSTATUS(0xC0000162)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNMAPPABLE_CHARACTER
.

MessageId = 0x0163 ; // NTSTATUS(0xC0000163)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNDEFINED_CHARACTER
.

MessageId = 0x0169 ; // NTSTATUS(0xC0000169)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DISK_RECALIBRATE_FAILED
.

MessageId = 0x016A ; // NTSTATUS(0xC000016A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DISK_OPERATION_FAILED
.

MessageId = 0x016B ; // NTSTATUS(0xC000016B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DISK_RESET_FAILED
.

MessageId = 0x016C ; // NTSTATUS(0xC000016C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SHARED_IRQ_BUSY
.

MessageId = 0x016D ; // NTSTATUS(0xC000016D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FT_ORPHANING
.

MessageId = 0x016E ; // NTSTATUS(0xC000016E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BIOS_FAILED_TO_CONNECT_INTERRUPT
.

MessageId = 0x0172 ; // NTSTATUS(0xC0000172)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PARTITION_FAILURE
.

MessageId = 0x0173 ; // NTSTATUS(0xC0000173)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_BLOCK_LENGTH
.

MessageId = 0x0174 ; // NTSTATUS(0xC0000174)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_NOT_PARTITIONED
.

MessageId = 0x0175 ; // NTSTATUS(0xC0000175)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNABLE_TO_LOCK_MEDIA
.

MessageId = 0x0176 ; // NTSTATUS(0xC0000176)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNABLE_TO_UNLOAD_MEDIA
.

MessageId = 0x0177 ; // NTSTATUS(0xC0000177)
Severity = Error
Facility = Null
Language = Neutral
STATUS_EOM_OVERFLOW
.

MessageId = 0x0178 ; // NTSTATUS(0xC0000178)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_MEDIA
.

MessageId = 0x017A ; // NTSTATUS(0xC000017A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_SUCH_MEMBER
.

MessageId = 0x017B ; // NTSTATUS(0xC000017B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_MEMBER
.

MessageId = 0x017C ; // NTSTATUS(0xC000017C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_KEY_DELETED
.

MessageId = 0x017D ; // NTSTATUS(0xC000017D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_LOG_SPACE
.

MessageId = 0x017E ; // NTSTATUS(0xC000017E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_MANY_SIDS
.

MessageId = 0x017F ; // NTSTATUS(0xC000017F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LM_CROSS_ENCRYPTION_REQUIRED
.

MessageId = 0x0180 ; // NTSTATUS(0xC0000180)
Severity = Error
Facility = Null
Language = Neutral
STATUS_KEY_HAS_CHILDREN
.

MessageId = 0x0181 ; // NTSTATUS(0xC0000181)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CHILD_MUST_BE_VOLATILE
.

MessageId = 0x0182 ; // NTSTATUS(0xC0000182)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_CONFIGURATION_ERROR
.

MessageId = 0x0183 ; // NTSTATUS(0xC0000183)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DRIVER_INTERNAL_ERROR
.

MessageId = 0x0184 ; // NTSTATUS(0xC0000184)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_DEVICE_STATE
.

MessageId = 0x0185 ; // NTSTATUS(0xC0000185)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IO_DEVICE_ERROR
.

MessageId = 0x0186 ; // NTSTATUS(0xC0000186)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_PROTOCOL_ERROR
.

MessageId = 0x0187 ; // NTSTATUS(0xC0000187)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BACKUP_CONTROLLER
.

MessageId = 0x0188 ; // NTSTATUS(0xC0000188)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOG_FILE_FULL
.

MessageId = 0x0189 ; // NTSTATUS(0xC0000189)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_LATE
.

MessageId = 0x018A ; // NTSTATUS(0xC000018A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_TRUST_LSA_SECRET
.

MessageId = 0x018B ; // NTSTATUS(0xC000018B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_TRUST_SAM_ACCOUNT
.

MessageId = 0x018C ; // NTSTATUS(0xC000018C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TRUSTED_DOMAIN_FAILURE
.

MessageId = 0x018D ; // NTSTATUS(0xC000018D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TRUSTED_RELATIONSHIP_FAILURE
.

MessageId = 0x018E ; // NTSTATUS(0xC000018E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_EVENTLOG_FILE_CORRUPT
.

MessageId = 0x018F ; // NTSTATUS(0xC000018F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_EVENTLOG_CANT_START
.

MessageId = 0x0190 ; // NTSTATUS(0xC0000190)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TRUST_FAILURE
.

MessageId = 0x0191 ; // NTSTATUS(0xC0000191)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MUTANT_LIMIT_EXCEEDED
.

MessageId = 0x0192 ; // NTSTATUS(0xC0000192)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NETLOGON_NOT_STARTED
.

MessageId = 0x0193 ; // NTSTATUS(0xC0000193)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ACCOUNT_EXPIRED
.

MessageId = 0x0194 ; // NTSTATUS(0xC0000194)
Severity = Error
Facility = Null
Language = Neutral
STATUS_POSSIBLE_DEADLOCK
.

MessageId = 0x0195 ; // NTSTATUS(0xC0000195)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NETWORK_CREDENTIAL_CONFLICT
.

MessageId = 0x0196 ; // NTSTATUS(0xC0000196)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REMOTE_SESSION_LIMIT
.

MessageId = 0x0197 ; // NTSTATUS(0xC0000197)
Severity = Error
Facility = Null
Language = Neutral
STATUS_EVENTLOG_FILE_CHANGED
.

MessageId = 0x0198 ; // NTSTATUS(0xC0000198)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOLOGON_INTERDOMAIN_TRUST_ACCOUNT
.

MessageId = 0x0199 ; // NTSTATUS(0xC0000199)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOLOGON_WORKSTATION_TRUST_ACCOUNT
.

MessageId = 0x019A ; // NTSTATUS(0xC000019A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOLOGON_SERVER_TRUST_ACCOUNT
.

MessageId = 0x019B ; // NTSTATUS(0xC000019B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DOMAIN_TRUST_INCONSISTENT
.

MessageId = 0x019C ; // NTSTATUS(0xC000019C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FS_DRIVER_REQUIRED
.

MessageId = 0x019D ; // NTSTATUS(0xC000019D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IMAGE_ALREADY_LOADED_AS_DLL
.

MessageId = 0x019E ; // NTSTATUS(0xC000019E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INCOMPATIBLE_WITH_GLOBAL_SHORT_NAME_REGISTRY_SETTING
.

MessageId = 0x019F ; // NTSTATUS(0xC000019F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SHORT_NAMES_NOT_ENABLED_ON_VOLUME
.

MessageId = 0x01A0 ; // NTSTATUS(0xC00001A0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SECURITY_STREAM_IS_INCONSISTENT
.

MessageId = 0x01A1 ; // NTSTATUS(0xC00001A1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_LOCK_RANGE
.

MessageId = 0x01A2 ; // NTSTATUS(0xC00001A2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_ACE_CONDITION
.

MessageId = 0x01A3 ; // NTSTATUS(0xC00001A3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IMAGE_SUBSYSTEM_NOT_PRESENT
.

MessageId = 0x01A4 ; // NTSTATUS(0xC00001A4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOTIFICATION_GUID_ALREADY_DEFINED
.

MessageId = 0x01A5 ; // NTSTATUS(0xC00001A5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_EXCEPTION_HANDLER
.

MessageId = 0x01A6 ; // NTSTATUS(0xC00001A6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DUPLICATE_PRIVILEGES
.

MessageId = 0x01A7 ; // NTSTATUS(0xC00001A7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_ALLOWED_ON_SYSTEM_FILE
.

MessageId = 0x01A8 ; // NTSTATUS(0xC00001A8)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REPAIR_NEEDED
.

MessageId = 0x01A9 ; // NTSTATUS(0xC00001A9)
Severity = Error
Facility = Null
Language = Neutral
STATUS_QUOTA_NOT_ENABLED
.

MessageId = 0x01AA ; // NTSTATUS(0xC00001AA)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_APPLICATION_PACKAGE
.

MessageId = 0x01AB ; // NTSTATUS(0xC00001AB)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_METADATA_OPTIMIZATION_IN_PROGRESS
.

MessageId = 0x01AC ; // NTSTATUS(0xC00001AC)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SAME_OBJECT
.

MessageId = 0x01AD ; // NTSTATUS(0xC00001AD)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FATAL_MEMORY_EXHAUSTION
.

MessageId = 0x01AE ; // NTSTATUS(0xC00001AE)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ERROR_PROCESS_NOT_IN_JOB
.

MessageId = 0x01AF ; // NTSTATUS(0xC00001AF)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CPU_SET_INVALID
.

MessageId = 0x01B0 ; // NTSTATUS(0xC00001B0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IO_DEVICE_INVALID_DATA
.

MessageId = 0x01B1 ; // NTSTATUS(0xC00001B1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IO_UNALIGNED_WRITE
.

MessageId = 0x01B2 ; // NTSTATUS(0xC00001B2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CONTROL_STACK_VIOLATION
.

MessageId = 0x01B3 ; // NTSTATUS(0xC00001B3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WEAK_WHFBKEY_BLOCKED
.

MessageId = 0x01B4 ; // NTSTATUS(0xC00001B4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SERVER_TRANSPORT_CONFLICT
.

MessageId = 0x01B5 ; // NTSTATUS(0xC00001B5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CERTIFICATE_VALIDATION_PREFERENCE_CONFLICT
.

MessageId = 0x0201 ; // NTSTATUS(0xC0000201)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NETWORK_OPEN_RESTRICTION
.

MessageId = 0x0202 ; // NTSTATUS(0xC0000202)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_USER_SESSION_KEY
.

MessageId = 0x0203 ; // NTSTATUS(0xC0000203)
Severity = Error
Facility = Null
Language = Neutral
STATUS_USER_SESSION_DELETED
.

MessageId = 0x0204 ; // NTSTATUS(0xC0000204)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RESOURCE_LANG_NOT_FOUND
.

MessageId = 0x0205 ; // NTSTATUS(0xC0000205)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INSUFF_SERVER_RESOURCES
.

MessageId = 0x0206 ; // NTSTATUS(0xC0000206)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_BUFFER_SIZE
.

MessageId = 0x0207 ; // NTSTATUS(0xC0000207)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_ADDRESS_COMPONENT
.

MessageId = 0x0208 ; // NTSTATUS(0xC0000208)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_ADDRESS_WILDCARD
.

MessageId = 0x0209 ; // NTSTATUS(0xC0000209)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_MANY_ADDRESSES
.

MessageId = 0x020A ; // NTSTATUS(0xC000020A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ADDRESS_ALREADY_EXISTS
.

MessageId = 0x020B ; // NTSTATUS(0xC000020B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ADDRESS_CLOSED
.

MessageId = 0x020C ; // NTSTATUS(0xC000020C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CONNECTION_DISCONNECTED
.

MessageId = 0x020D ; // NTSTATUS(0xC000020D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CONNECTION_RESET
.

MessageId = 0x020E ; // NTSTATUS(0xC000020E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_MANY_NODES
.

MessageId = 0x020F ; // NTSTATUS(0xC000020F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TRANSACTION_ABORTED
.

MessageId = 0x0210 ; // NTSTATUS(0xC0000210)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TRANSACTION_TIMED_OUT
.

MessageId = 0x0211 ; // NTSTATUS(0xC0000211)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TRANSACTION_NO_RELEASE
.

MessageId = 0x0212 ; // NTSTATUS(0xC0000212)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TRANSACTION_NO_MATCH
.

MessageId = 0x0213 ; // NTSTATUS(0xC0000213)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TRANSACTION_RESPONDED
.

MessageId = 0x0214 ; // NTSTATUS(0xC0000214)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TRANSACTION_INVALID_ID
.

MessageId = 0x0215 ; // NTSTATUS(0xC0000215)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TRANSACTION_INVALID_TYPE
.

MessageId = 0x0216 ; // NTSTATUS(0xC0000216)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SERVER_SESSION
.

MessageId = 0x0217 ; // NTSTATUS(0xC0000217)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_CLIENT_SESSION
.

MessageId = 0x0218 ; // NTSTATUS(0xC0000218)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CANNOT_LOAD_REGISTRY_FILE
.

MessageId = 0x0219 ; // NTSTATUS(0xC0000219)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEBUG_ATTACH_FAILED
.

MessageId = 0x021A ; // NTSTATUS(0xC000021A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SYSTEM_PROCESS_TERMINATED
.

MessageId = 0x021B ; // NTSTATUS(0xC000021B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DATA_NOT_ACCEPTED
.

MessageId = 0x021C ; // NTSTATUS(0xC000021C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_BROWSER_SERVERS_FOUND
.

MessageId = 0x021D ; // NTSTATUS(0xC000021D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VDM_HARD_ERROR
.

MessageId = 0x021E ; // NTSTATUS(0xC000021E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DRIVER_CANCEL_TIMEOUT
.

MessageId = 0x021F ; // NTSTATUS(0xC000021F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REPLY_MESSAGE_MISMATCH
.

MessageId = 0x0220 ; // NTSTATUS(0xC0000220)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MAPPED_ALIGNMENT
.

MessageId = 0x0221 ; // NTSTATUS(0xC0000221)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IMAGE_CHECKSUM_MISMATCH
.

MessageId = 0x0222 ; // NTSTATUS(0xC0000222)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOST_WRITEBEHIND_DATA
.

MessageId = 0x0223 ; // NTSTATUS(0xC0000223)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLIENT_SERVER_PARAMETERS_INVALID
.

MessageId = 0x0224 ; // NTSTATUS(0xC0000224)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PASSWORD_MUST_CHANGE
.

MessageId = 0x0225 ; // NTSTATUS(0xC0000225)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_FOUND
.

MessageId = 0x0226 ; // NTSTATUS(0xC0000226)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_TINY_STREAM
.

MessageId = 0x0227 ; // NTSTATUS(0xC0000227)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RECOVERY_FAILURE
.

MessageId = 0x0228 ; // NTSTATUS(0xC0000228)
Severity = Error
Facility = Null
Language = Neutral
STATUS_STACK_OVERFLOW_READ
.

MessageId = 0x0229 ; // NTSTATUS(0xC0000229)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FAIL_CHECK
.

MessageId = 0x022A ; // NTSTATUS(0xC000022A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DUPLICATE_OBJECTID
.

MessageId = 0x022B ; // NTSTATUS(0xC000022B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OBJECTID_EXISTS
.

MessageId = 0x022C ; // NTSTATUS(0xC000022C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CONVERT_TO_LARGE
.

MessageId = 0x022D ; // NTSTATUS(0xC000022D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RETRY
.

MessageId = 0x022E ; // NTSTATUS(0xC000022E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FOUND_OUT_OF_SCOPE
.

MessageId = 0x022F ; // NTSTATUS(0xC000022F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ALLOCATE_BUCKET
.

MessageId = 0x0230 ; // NTSTATUS(0xC0000230)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PROPSET_NOT_FOUND
.

MessageId = 0x0231 ; // NTSTATUS(0xC0000231)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MARSHALL_OVERFLOW
.

MessageId = 0x0232 ; // NTSTATUS(0xC0000232)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_VARIANT
.

MessageId = 0x0233 ; // NTSTATUS(0xC0000233)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DOMAIN_CONTROLLER_NOT_FOUND
.

MessageId = 0x0234 ; // NTSTATUS(0xC0000234)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ACCOUNT_LOCKED_OUT
.

MessageId = 0x0235 ; // NTSTATUS(0xC0000235)
Severity = Error
Facility = Null
Language = Neutral
STATUS_HANDLE_NOT_CLOSABLE
.

MessageId = 0x0236 ; // NTSTATUS(0xC0000236)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CONNECTION_REFUSED
.

MessageId = 0x0237 ; // NTSTATUS(0xC0000237)
Severity = Error
Facility = Null
Language = Neutral
STATUS_GRACEFUL_DISCONNECT
.

MessageId = 0x0238 ; // NTSTATUS(0xC0000238)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ADDRESS_ALREADY_ASSOCIATED
.

MessageId = 0x0239 ; // NTSTATUS(0xC0000239)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ADDRESS_NOT_ASSOCIATED
.

MessageId = 0x023A ; // NTSTATUS(0xC000023A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CONNECTION_INVALID
.

MessageId = 0x023B ; // NTSTATUS(0xC000023B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CONNECTION_ACTIVE
.

MessageId = 0x023C ; // NTSTATUS(0xC000023C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NETWORK_UNREACHABLE
.

MessageId = 0x023D ; // NTSTATUS(0xC000023D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_HOST_UNREACHABLE
.

MessageId = 0x023E ; // NTSTATUS(0xC000023E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PROTOCOL_UNREACHABLE
.

MessageId = 0x023F ; // NTSTATUS(0xC000023F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PORT_UNREACHABLE
.

MessageId = 0x0240 ; // NTSTATUS(0xC0000240)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REQUEST_ABORTED
.

MessageId = 0x0241 ; // NTSTATUS(0xC0000241)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CONNECTION_ABORTED
.

MessageId = 0x0242 ; // NTSTATUS(0xC0000242)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_COMPRESSION_BUFFER
.

MessageId = 0x0243 ; // NTSTATUS(0xC0000243)
Severity = Error
Facility = Null
Language = Neutral
STATUS_USER_MAPPED_FILE
.

MessageId = 0x0244 ; // NTSTATUS(0xC0000244)
Severity = Error
Facility = Null
Language = Neutral
STATUS_AUDIT_FAILED
.

MessageId = 0x0245 ; // NTSTATUS(0xC0000245)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TIMER_RESOLUTION_NOT_SET
.

MessageId = 0x0246 ; // NTSTATUS(0xC0000246)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CONNECTION_COUNT_LIMIT
.

MessageId = 0x0247 ; // NTSTATUS(0xC0000247)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOGIN_TIME_RESTRICTION
.

MessageId = 0x0248 ; // NTSTATUS(0xC0000248)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOGIN_WKSTA_RESTRICTION
.

MessageId = 0x0249 ; // NTSTATUS(0xC0000249)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IMAGE_MP_UP_MISMATCH
.

MessageId = 0x0250 ; // NTSTATUS(0xC0000250)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INSUFFICIENT_LOGON_INFO
.

MessageId = 0x0251 ; // NTSTATUS(0xC0000251)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_DLL_ENTRYPOINT
.

MessageId = 0x0252 ; // NTSTATUS(0xC0000252)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_SERVICE_ENTRYPOINT
.

MessageId = 0x0253 ; // NTSTATUS(0xC0000253)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LPC_REPLY_LOST
.

MessageId = 0x0254 ; // NTSTATUS(0xC0000254)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IP_ADDRESS_CONFLICT1
.

MessageId = 0x0255 ; // NTSTATUS(0xC0000255)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IP_ADDRESS_CONFLICT2
.

MessageId = 0x0256 ; // NTSTATUS(0xC0000256)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REGISTRY_QUOTA_LIMIT
.

MessageId = 0x0257 ; // NTSTATUS(0xC0000257)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PATH_NOT_COVERED
.

MessageId = 0x0258 ; // NTSTATUS(0xC0000258)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_CALLBACK_ACTIVE
.

MessageId = 0x0259 ; // NTSTATUS(0xC0000259)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LICENSE_QUOTA_EXCEEDED
.

MessageId = 0x025A ; // NTSTATUS(0xC000025A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PWD_TOO_SHORT
.

MessageId = 0x025B ; // NTSTATUS(0xC000025B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PWD_TOO_RECENT
.

MessageId = 0x025C ; // NTSTATUS(0xC000025C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PWD_HISTORY_CONFLICT
.

MessageId = 0x025E ; // NTSTATUS(0xC000025E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PLUGPLAY_NO_DEVICE
.

MessageId = 0x025F ; // NTSTATUS(0xC000025F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNSUPPORTED_COMPRESSION
.

MessageId = 0x0260 ; // NTSTATUS(0xC0000260)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_HW_PROFILE
.

MessageId = 0x0261 ; // NTSTATUS(0xC0000261)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PLUGPLAY_DEVICE_PATH
.

MessageId = 0x0262 ; // NTSTATUS(0xC0000262)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DRIVER_ORDINAL_NOT_FOUND
.

MessageId = 0x0263 ; // NTSTATUS(0xC0000263)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DRIVER_ENTRYPOINT_NOT_FOUND
.

MessageId = 0x0264 ; // NTSTATUS(0xC0000264)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RESOURCE_NOT_OWNED
.

MessageId = 0x0265 ; // NTSTATUS(0xC0000265)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_MANY_LINKS
.

MessageId = 0x0266 ; // NTSTATUS(0xC0000266)
Severity = Error
Facility = Null
Language = Neutral
STATUS_QUOTA_LIST_INCONSISTENT
.

MessageId = 0x0267 ; // NTSTATUS(0xC0000267)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_IS_OFFLINE
.

MessageId = 0x0268 ; // NTSTATUS(0xC0000268)
Severity = Error
Facility = Null
Language = Neutral
STATUS_EVALUATION_EXPIRATION
.

MessageId = 0x0269 ; // NTSTATUS(0xC0000269)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ILLEGAL_DLL_RELOCATION
.

MessageId = 0x026A ; // NTSTATUS(0xC000026A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LICENSE_VIOLATION
.

MessageId = 0x026B ; // NTSTATUS(0xC000026B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DLL_INIT_FAILED_LOGOFF
.

MessageId = 0x026C ; // NTSTATUS(0xC000026C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DRIVER_UNABLE_TO_LOAD
.

MessageId = 0x026D ; // NTSTATUS(0xC000026D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DFS_UNAVAILABLE
.

MessageId = 0x026E ; // NTSTATUS(0xC000026E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VOLUME_DISMOUNTED
.

MessageId = 0x026F ; // NTSTATUS(0xC000026F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WX86_INTERNAL_ERROR
.

MessageId = 0x0270 ; // NTSTATUS(0xC0000270)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WX86_FLOAT_STACK_CHECK
.

MessageId = 0x0271 ; // NTSTATUS(0xC0000271)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VALIDATE_CONTINUE
.

MessageId = 0x0272 ; // NTSTATUS(0xC0000272)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_MATCH
.

MessageId = 0x0273 ; // NTSTATUS(0xC0000273)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_MORE_MATCHES
.

MessageId = 0x0275 ; // NTSTATUS(0xC0000275)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_A_REPARSE_POINT
.

MessageId = 0x0276 ; // NTSTATUS(0xC0000276)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IO_REPARSE_TAG_INVALID
.

MessageId = 0x0277 ; // NTSTATUS(0xC0000277)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IO_REPARSE_TAG_MISMATCH
.

MessageId = 0x0278 ; // NTSTATUS(0xC0000278)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IO_REPARSE_DATA_INVALID
.

MessageId = 0x0279 ; // NTSTATUS(0xC0000279)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IO_REPARSE_TAG_NOT_HANDLED
.

MessageId = 0x027A ; // NTSTATUS(0xC000027A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PWD_TOO_LONG
.

MessageId = 0x027B ; // NTSTATUS(0xC000027B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_STOWED_EXCEPTION
.

MessageId = 0x027C ; // NTSTATUS(0xC000027C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CONTEXT_STOWED_EXCEPTION
.

MessageId = 0x0280 ; // NTSTATUS(0xC0000280)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REPARSE_POINT_NOT_RESOLVED
.

MessageId = 0x0281 ; // NTSTATUS(0xC0000281)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DIRECTORY_IS_A_REPARSE_POINT
.

MessageId = 0x0282 ; // NTSTATUS(0xC0000282)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RANGE_LIST_CONFLICT
.

MessageId = 0x0283 ; // NTSTATUS(0xC0000283)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SOURCE_ELEMENT_EMPTY
.

MessageId = 0x0284 ; // NTSTATUS(0xC0000284)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DESTINATION_ELEMENT_FULL
.

MessageId = 0x0285 ; // NTSTATUS(0xC0000285)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ILLEGAL_ELEMENT_ADDRESS
.

MessageId = 0x0286 ; // NTSTATUS(0xC0000286)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MAGAZINE_NOT_PRESENT
.

MessageId = 0x0287 ; // NTSTATUS(0xC0000287)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REINITIALIZATION_NEEDED
.

MessageId = 0x028A ; // NTSTATUS(0xC000028A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ENCRYPTION_FAILED
.

MessageId = 0x028B ; // NTSTATUS(0xC000028B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DECRYPTION_FAILED
.

MessageId = 0x028C ; // NTSTATUS(0xC000028C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RANGE_NOT_FOUND
.

MessageId = 0x028D ; // NTSTATUS(0xC000028D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_RECOVERY_POLICY
.

MessageId = 0x028E ; // NTSTATUS(0xC000028E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_EFS
.

MessageId = 0x028F ; // NTSTATUS(0xC000028F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WRONG_EFS
.

MessageId = 0x0290 ; // NTSTATUS(0xC0000290)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_USER_KEYS
.

MessageId = 0x0291 ; // NTSTATUS(0xC0000291)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_NOT_ENCRYPTED
.

MessageId = 0x0292 ; // NTSTATUS(0xC0000292)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_EXPORT_FORMAT
.

MessageId = 0x0293 ; // NTSTATUS(0xC0000293)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_ENCRYPTED
.

MessageId = 0x0295 ; // NTSTATUS(0xC0000295)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WMI_GUID_NOT_FOUND
.

MessageId = 0x0296 ; // NTSTATUS(0xC0000296)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WMI_INSTANCE_NOT_FOUND
.

MessageId = 0x0297 ; // NTSTATUS(0xC0000297)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WMI_ITEMID_NOT_FOUND
.

MessageId = 0x0298 ; // NTSTATUS(0xC0000298)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WMI_TRY_AGAIN
.

MessageId = 0x0299 ; // NTSTATUS(0xC0000299)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SHARED_POLICY
.

MessageId = 0x029A ; // NTSTATUS(0xC000029A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_POLICY_OBJECT_NOT_FOUND
.

MessageId = 0x029B ; // NTSTATUS(0xC000029B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_POLICY_ONLY_IN_DS
.

MessageId = 0x029C ; // NTSTATUS(0xC000029C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VOLUME_NOT_UPGRADED
.

MessageId = 0x029D ; // NTSTATUS(0xC000029D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REMOTE_STORAGE_NOT_ACTIVE
.

MessageId = 0x029E ; // NTSTATUS(0xC000029E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REMOTE_STORAGE_MEDIA_ERROR
.

MessageId = 0x029F ; // NTSTATUS(0xC000029F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_TRACKING_SERVICE
.

MessageId = 0x02A0 ; // NTSTATUS(0xC00002A0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SERVER_SID_MISMATCH
.

MessageId = 0x02A1 ; // NTSTATUS(0xC00002A1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_NO_ATTRIBUTE_OR_VALUE
.

MessageId = 0x02A2 ; // NTSTATUS(0xC00002A2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_INVALID_ATTRIBUTE_SYNTAX
.

MessageId = 0x02A3 ; // NTSTATUS(0xC00002A3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_ATTRIBUTE_TYPE_UNDEFINED
.

MessageId = 0x02A4 ; // NTSTATUS(0xC00002A4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_ATTRIBUTE_OR_VALUE_EXISTS
.

MessageId = 0x02A5 ; // NTSTATUS(0xC00002A5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_BUSY
.

MessageId = 0x02A6 ; // NTSTATUS(0xC00002A6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_UNAVAILABLE
.

MessageId = 0x02A7 ; // NTSTATUS(0xC00002A7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_NO_RIDS_ALLOCATED
.

MessageId = 0x02A8 ; // NTSTATUS(0xC00002A8)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_NO_MORE_RIDS
.

MessageId = 0x02A9 ; // NTSTATUS(0xC00002A9)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_INCORRECT_ROLE_OWNER
.

MessageId = 0x02AA ; // NTSTATUS(0xC00002AA)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_RIDMGR_INIT_ERROR
.

MessageId = 0x02AB ; // NTSTATUS(0xC00002AB)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_OBJ_CLASS_VIOLATION
.

MessageId = 0x02AC ; // NTSTATUS(0xC00002AC)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_CANT_ON_NON_LEAF
.

MessageId = 0x02AD ; // NTSTATUS(0xC00002AD)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_CANT_ON_RDN
.

MessageId = 0x02AE ; // NTSTATUS(0xC00002AE)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_CANT_MOD_OBJ_CLASS
.

MessageId = 0x02AF ; // NTSTATUS(0xC00002AF)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_CROSS_DOM_MOVE_FAILED
.

MessageId = 0x02B0 ; // NTSTATUS(0xC00002B0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_GC_NOT_AVAILABLE
.

MessageId = 0x02B1 ; // NTSTATUS(0xC00002B1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DIRECTORY_SERVICE_REQUIRED
.

MessageId = 0x02B2 ; // NTSTATUS(0xC00002B2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REPARSE_ATTRIBUTE_CONFLICT
.

MessageId = 0x02B3 ; // NTSTATUS(0xC00002B3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CANT_ENABLE_DENY_ONLY
.

MessageId = 0x02B4 ; // NTSTATUS(0xC00002B4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FLOAT_MULTIPLE_FAULTS
.

MessageId = 0x02B5 ; // NTSTATUS(0xC00002B5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FLOAT_MULTIPLE_TRAPS
.

MessageId = 0x02B6 ; // NTSTATUS(0xC00002B6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_REMOVED
.

MessageId = 0x02B7 ; // NTSTATUS(0xC00002B7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_JOURNAL_DELETE_IN_PROGRESS
.

MessageId = 0x02B8 ; // NTSTATUS(0xC00002B8)
Severity = Error
Facility = Null
Language = Neutral
STATUS_JOURNAL_NOT_ACTIVE
.

MessageId = 0x02B9 ; // NTSTATUS(0xC00002B9)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOINTERFACE
.

MessageId = 0x02BA ; // NTSTATUS(0xC00002BA)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_RIDMGR_DISABLED
.

MessageId = 0x02C1 ; // NTSTATUS(0xC00002C1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_ADMIN_LIMIT_EXCEEDED
.

MessageId = 0x02C2 ; // NTSTATUS(0xC00002C2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DRIVER_FAILED_SLEEP
.

MessageId = 0x02C3 ; // NTSTATUS(0xC00002C3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MUTUAL_AUTHENTICATION_FAILED
.

MessageId = 0x02C4 ; // NTSTATUS(0xC00002C4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CORRUPT_SYSTEM_FILE
.

MessageId = 0x02C5 ; // NTSTATUS(0xC00002C5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DATATYPE_MISALIGNMENT_ERROR
.

MessageId = 0x02C6 ; // NTSTATUS(0xC00002C6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WMI_READ_ONLY
.

MessageId = 0x02C7 ; // NTSTATUS(0xC00002C7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WMI_SET_FAILURE
.

MessageId = 0x02C8 ; // NTSTATUS(0xC00002C8)
Severity = Error
Facility = Null
Language = Neutral
STATUS_COMMITMENT_MINIMUM
.

MessageId = 0x02C9 ; // NTSTATUS(0xC00002C9)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REG_NAT_CONSUMPTION
.

MessageId = 0x02CA ; // NTSTATUS(0xC00002CA)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TRANSPORT_FULL
.

MessageId = 0x02CB ; // NTSTATUS(0xC00002CB)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_SAM_INIT_FAILURE
.

MessageId = 0x02CC ; // NTSTATUS(0xC00002CC)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ONLY_IF_CONNECTED
.

MessageId = 0x02CD ; // NTSTATUS(0xC00002CD)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_SENSITIVE_GROUP_VIOLATION
.

MessageId = 0x02CE ; // NTSTATUS(0xC00002CE)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PNP_RESTART_ENUMERATION
.

MessageId = 0x02CF ; // NTSTATUS(0xC00002CF)
Severity = Error
Facility = Null
Language = Neutral
STATUS_JOURNAL_ENTRY_DELETED
.

MessageId = 0x02D0 ; // NTSTATUS(0xC00002D0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_CANT_MOD_PRIMARYGROUPID
.

MessageId = 0x02D1 ; // NTSTATUS(0xC00002D1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SYSTEM_IMAGE_BAD_SIGNATURE
.

MessageId = 0x02D2 ; // NTSTATUS(0xC00002D2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PNP_REBOOT_REQUIRED
.

MessageId = 0x02D3 ; // NTSTATUS(0xC00002D3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_POWER_STATE_INVALID
.

MessageId = 0x02D4 ; // NTSTATUS(0xC00002D4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_INVALID_GROUP_TYPE
.

MessageId = 0x02D5 ; // NTSTATUS(0xC00002D5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_NO_NEST_GLOBALGROUP_IN_MIXEDDOMAIN
.

MessageId = 0x02D6 ; // NTSTATUS(0xC00002D6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_NO_NEST_LOCALGROUP_IN_MIXEDDOMAIN
.

MessageId = 0x02D7 ; // NTSTATUS(0xC00002D7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_GLOBAL_CANT_HAVE_LOCAL_MEMBER
.

MessageId = 0x02D8 ; // NTSTATUS(0xC00002D8)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_GLOBAL_CANT_HAVE_UNIVERSAL_MEMBER
.

MessageId = 0x02D9 ; // NTSTATUS(0xC00002D9)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_UNIVERSAL_CANT_HAVE_LOCAL_MEMBER
.

MessageId = 0x02DA ; // NTSTATUS(0xC00002DA)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_GLOBAL_CANT_HAVE_CROSSDOMAIN_MEMBER
.

MessageId = 0x02DB ; // NTSTATUS(0xC00002DB)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_LOCAL_CANT_HAVE_CROSSDOMAIN_LOCAL_MEMBER
.

MessageId = 0x02DC ; // NTSTATUS(0xC00002DC)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_HAVE_PRIMARY_MEMBERS
.

MessageId = 0x02DD ; // NTSTATUS(0xC00002DD)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WMI_NOT_SUPPORTED
.

MessageId = 0x02DE ; // NTSTATUS(0xC00002DE)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INSUFFICIENT_POWER
.

MessageId = 0x02DF ; // NTSTATUS(0xC00002DF)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SAM_NEED_BOOTKEY_PASSWORD
.

MessageId = 0x02E0 ; // NTSTATUS(0xC00002E0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SAM_NEED_BOOTKEY_FLOPPY
.

MessageId = 0x02E1 ; // NTSTATUS(0xC00002E1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_CANT_START
.

MessageId = 0x02E2 ; // NTSTATUS(0xC00002E2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_INIT_FAILURE
.

MessageId = 0x02E3 ; // NTSTATUS(0xC00002E3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SAM_INIT_FAILURE
.

MessageId = 0x02E4 ; // NTSTATUS(0xC00002E4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_GC_REQUIRED
.

MessageId = 0x02E5 ; // NTSTATUS(0xC00002E5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_LOCAL_MEMBER_OF_LOCAL_ONLY
.

MessageId = 0x02E6 ; // NTSTATUS(0xC00002E6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_NO_FPO_IN_UNIVERSAL_GROUPS
.

MessageId = 0x02E7 ; // NTSTATUS(0xC00002E7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_MACHINE_ACCOUNT_QUOTA_EXCEEDED
.

MessageId = 0x02E8 ; // NTSTATUS(0xC00002E8)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MULTIPLE_FAULT_VIOLATION
.

MessageId = 0x02E9 ; // NTSTATUS(0xC00002E9)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CURRENT_DOMAIN_NOT_ALLOWED
.

MessageId = 0x02EA ; // NTSTATUS(0xC00002EA)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CANNOT_MAKE
.

MessageId = 0x02EB ; // NTSTATUS(0xC00002EB)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SYSTEM_SHUTDOWN
.

MessageId = 0x02EC ; // NTSTATUS(0xC00002EC)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_INIT_FAILURE_CONSOLE
.

MessageId = 0x02ED ; // NTSTATUS(0xC00002ED)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_SAM_INIT_FAILURE_CONSOLE
.

MessageId = 0x02EE ; // NTSTATUS(0xC00002EE)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNFINISHED_CONTEXT_DELETED
.

MessageId = 0x02EF ; // NTSTATUS(0xC00002EF)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_TGT_REPLY
.

MessageId = 0x02F0 ; // NTSTATUS(0xC00002F0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OBJECTID_NOT_FOUND
.

MessageId = 0x02F1 ; // NTSTATUS(0xC00002F1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_IP_ADDRESSES
.

MessageId = 0x02F2 ; // NTSTATUS(0xC00002F2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WRONG_CREDENTIAL_HANDLE
.

MessageId = 0x02F3 ; // NTSTATUS(0xC00002F3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CRYPTO_SYSTEM_INVALID
.

MessageId = 0x02F4 ; // NTSTATUS(0xC00002F4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MAX_REFERRALS_EXCEEDED
.

MessageId = 0x02F5 ; // NTSTATUS(0xC00002F5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MUST_BE_KDC
.

MessageId = 0x02F6 ; // NTSTATUS(0xC00002F6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_STRONG_CRYPTO_NOT_SUPPORTED
.

MessageId = 0x02F7 ; // NTSTATUS(0xC00002F7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_MANY_PRINCIPALS
.

MessageId = 0x02F8 ; // NTSTATUS(0xC00002F8)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_PA_DATA
.

MessageId = 0x02F9 ; // NTSTATUS(0xC00002F9)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PKINIT_NAME_MISMATCH
.

MessageId = 0x02FA ; // NTSTATUS(0xC00002FA)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SMARTCARD_LOGON_REQUIRED
.

MessageId = 0x02FB ; // NTSTATUS(0xC00002FB)
Severity = Error
Facility = Null
Language = Neutral
STATUS_KDC_INVALID_REQUEST
.

MessageId = 0x02FC ; // NTSTATUS(0xC00002FC)
Severity = Error
Facility = Null
Language = Neutral
STATUS_KDC_UNABLE_TO_REFER
.

MessageId = 0x02FD ; // NTSTATUS(0xC00002FD)
Severity = Error
Facility = Null
Language = Neutral
STATUS_KDC_UNKNOWN_ETYPE
.

MessageId = 0x02FE ; // NTSTATUS(0xC00002FE)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SHUTDOWN_IN_PROGRESS
.

MessageId = 0x02FF ; // NTSTATUS(0xC00002FF)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SERVER_SHUTDOWN_IN_PROGRESS
.

MessageId = 0x0300 ; // NTSTATUS(0xC0000300)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SUPPORTED_ON_SBS
.

MessageId = 0x0301 ; // NTSTATUS(0xC0000301)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WMI_GUID_DISCONNECTED
.

MessageId = 0x0302 ; // NTSTATUS(0xC0000302)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WMI_ALREADY_DISABLED
.

MessageId = 0x0303 ; // NTSTATUS(0xC0000303)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WMI_ALREADY_ENABLED
.

MessageId = 0x0304 ; // NTSTATUS(0xC0000304)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MFT_TOO_FRAGMENTED
.

MessageId = 0x0305 ; // NTSTATUS(0xC0000305)
Severity = Error
Facility = Null
Language = Neutral
STATUS_COPY_PROTECTION_FAILURE
.

MessageId = 0x030C ; // NTSTATUS(0xC000030C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PASSWORD_CHANGE_REQUIRED
.

MessageId = 0x030D ; // NTSTATUS(0xC000030D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOST_MODE_LOGON_RESTRICTION
.

MessageId = 0x0320 ; // NTSTATUS(0xC0000320)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PKINIT_FAILURE
.

MessageId = 0x0321 ; // NTSTATUS(0xC0000321)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SMARTCARD_SUBSYSTEM_FAILURE
.

MessageId = 0x0322 ; // NTSTATUS(0xC0000322)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_KERB_KEY
.

MessageId = 0x0350 ; // NTSTATUS(0xC0000350)
Severity = Error
Facility = Null
Language = Neutral
STATUS_HOST_DOWN
.

MessageId = 0x0351 ; // NTSTATUS(0xC0000351)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNSUPPORTED_PREAUTH
.

MessageId = 0x0352 ; // NTSTATUS(0xC0000352)
Severity = Error
Facility = Null
Language = Neutral
STATUS_EFS_ALG_BLOB_TOO_BIG
.

MessageId = 0x0353 ; // NTSTATUS(0xC0000353)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PORT_NOT_SET
.

MessageId = 0x0354 ; // NTSTATUS(0xC0000354)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEBUGGER_INACTIVE
.

MessageId = 0x0355 ; // NTSTATUS(0xC0000355)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_VERSION_CHECK_FAILURE
.

MessageId = 0x0356 ; // NTSTATUS(0xC0000356)
Severity = Error
Facility = Null
Language = Neutral
STATUS_AUDITING_DISABLED
.

MessageId = 0x0357 ; // NTSTATUS(0xC0000357)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PRENT4_MACHINE_ACCOUNT
.

MessageId = 0x0358 ; // NTSTATUS(0xC0000358)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_AG_CANT_HAVE_UNIVERSAL_MEMBER
.

MessageId = 0x0359 ; // NTSTATUS(0xC0000359)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_IMAGE_WIN_32
.

MessageId = 0x035A ; // NTSTATUS(0xC000035A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_IMAGE_WIN_64
.

MessageId = 0x035B ; // NTSTATUS(0xC000035B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_BINDINGS
.

MessageId = 0x035C ; // NTSTATUS(0xC000035C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NETWORK_SESSION_EXPIRED
.

MessageId = 0x035D ; // NTSTATUS(0xC000035D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_APPHELP_BLOCK
.

MessageId = 0x035E ; // NTSTATUS(0xC000035E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ALL_SIDS_FILTERED
.

MessageId = 0x035F ; // NTSTATUS(0xC000035F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SAFE_MODE_DRIVER
.

MessageId = 0x0361 ; // NTSTATUS(0xC0000361)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ACCESS_DISABLED_BY_POLICY_DEFAULT
.

MessageId = 0x0362 ; // NTSTATUS(0xC0000362)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ACCESS_DISABLED_BY_POLICY_PATH
.

MessageId = 0x0363 ; // NTSTATUS(0xC0000363)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ACCESS_DISABLED_BY_POLICY_PUBLISHER
.

MessageId = 0x0364 ; // NTSTATUS(0xC0000364)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ACCESS_DISABLED_BY_POLICY_OTHER
.

MessageId = 0x0365 ; // NTSTATUS(0xC0000365)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FAILED_DRIVER_ENTRY
.

MessageId = 0x0366 ; // NTSTATUS(0xC0000366)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_ENUMERATION_ERROR
.

MessageId = 0x0368 ; // NTSTATUS(0xC0000368)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MOUNT_POINT_NOT_RESOLVED
.

MessageId = 0x0369 ; // NTSTATUS(0xC0000369)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_DEVICE_OBJECT_PARAMETER
.

MessageId = 0x036A ; // NTSTATUS(0xC000036A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MCA_OCCURED
.

MessageId = 0x036B ; // NTSTATUS(0xC000036B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DRIVER_BLOCKED_CRITICAL
.

MessageId = 0x036C ; // NTSTATUS(0xC000036C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DRIVER_BLOCKED
.

MessageId = 0x036D ; // NTSTATUS(0xC000036D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DRIVER_DATABASE_ERROR
.

MessageId = 0x036E ; // NTSTATUS(0xC000036E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SYSTEM_HIVE_TOO_LARGE
.

MessageId = 0x036F ; // NTSTATUS(0xC000036F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_IMPORT_OF_NON_DLL
.

MessageId = 0x0371 ; // NTSTATUS(0xC0000371)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_SECRETS
.

MessageId = 0x0372 ; // NTSTATUS(0xC0000372)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ACCESS_DISABLED_NO_SAFER_UI_BY_POLICY
.

MessageId = 0x0373 ; // NTSTATUS(0xC0000373)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FAILED_STACK_SWITCH
.

MessageId = 0x0374 ; // NTSTATUS(0xC0000374)
Severity = Error
Facility = Null
Language = Neutral
STATUS_HEAP_CORRUPTION
.

MessageId = 0x0380 ; // NTSTATUS(0xC0000380)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SMARTCARD_WRONG_PIN
.

MessageId = 0x0381 ; // NTSTATUS(0xC0000381)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SMARTCARD_CARD_BLOCKED
.

MessageId = 0x0382 ; // NTSTATUS(0xC0000382)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SMARTCARD_CARD_NOT_AUTHENTICATED
.

MessageId = 0x0383 ; // NTSTATUS(0xC0000383)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SMARTCARD_NO_CARD
.

MessageId = 0x0384 ; // NTSTATUS(0xC0000384)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SMARTCARD_NO_KEY_CONTAINER
.

MessageId = 0x0385 ; // NTSTATUS(0xC0000385)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SMARTCARD_NO_CERTIFICATE
.

MessageId = 0x0386 ; // NTSTATUS(0xC0000386)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SMARTCARD_NO_KEYSET
.

MessageId = 0x0387 ; // NTSTATUS(0xC0000387)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SMARTCARD_IO_ERROR
.

MessageId = 0x0388 ; // NTSTATUS(0xC0000388)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DOWNGRADE_DETECTED
.

MessageId = 0x0389 ; // NTSTATUS(0xC0000389)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SMARTCARD_CERT_REVOKED
.

MessageId = 0x038A ; // NTSTATUS(0xC000038A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ISSUING_CA_UNTRUSTED
.

MessageId = 0x038B ; // NTSTATUS(0xC000038B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REVOCATION_OFFLINE_C
.

MessageId = 0x038C ; // NTSTATUS(0xC000038C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PKINIT_CLIENT_FAILURE
.

MessageId = 0x038D ; // NTSTATUS(0xC000038D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SMARTCARD_CERT_EXPIRED
.

MessageId = 0x038E ; // NTSTATUS(0xC000038E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DRIVER_FAILED_PRIOR_UNLOAD
.

MessageId = 0x038F ; // NTSTATUS(0xC000038F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SMARTCARD_SILENT_CONTEXT
.

MessageId = 0x0401 ; // NTSTATUS(0xC0000401)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PER_USER_TRUST_QUOTA_EXCEEDED
.

MessageId = 0x0402 ; // NTSTATUS(0xC0000402)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ALL_USER_TRUST_QUOTA_EXCEEDED
.

MessageId = 0x0403 ; // NTSTATUS(0xC0000403)
Severity = Error
Facility = Null
Language = Neutral
STATUS_USER_DELETE_TRUST_QUOTA_EXCEEDED
.

MessageId = 0x0404 ; // NTSTATUS(0xC0000404)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_NAME_NOT_UNIQUE
.

MessageId = 0x0405 ; // NTSTATUS(0xC0000405)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_DUPLICATE_ID_FOUND
.

MessageId = 0x0406 ; // NTSTATUS(0xC0000406)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_GROUP_CONVERSION_ERROR
.

MessageId = 0x0407 ; // NTSTATUS(0xC0000407)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VOLSNAP_PREPARE_HIBERNATE
.

MessageId = 0x0408 ; // NTSTATUS(0xC0000408)
Severity = Error
Facility = Null
Language = Neutral
STATUS_USER2USER_REQUIRED
.

MessageId = 0x0409 ; // NTSTATUS(0xC0000409)
Severity = Error
Facility = Null
Language = Neutral
STATUS_STACK_BUFFER_OVERRUN
.

MessageId = 0x040A ; // NTSTATUS(0xC000040A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_S4U_PROT_SUPPORT
.

MessageId = 0x040B ; // NTSTATUS(0xC000040B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CROSSREALM_DELEGATION_FAILURE
.

MessageId = 0x040C ; // NTSTATUS(0xC000040C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REVOCATION_OFFLINE_KDC
.

MessageId = 0x040D ; // NTSTATUS(0xC000040D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ISSUING_CA_UNTRUSTED_KDC
.

MessageId = 0x040E ; // NTSTATUS(0xC000040E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_KDC_CERT_EXPIRED
.

MessageId = 0x040F ; // NTSTATUS(0xC000040F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_KDC_CERT_REVOKED
.

MessageId = 0x0410 ; // NTSTATUS(0xC0000410)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PARAMETER_QUOTA_EXCEEDED
.

MessageId = 0x0411 ; // NTSTATUS(0xC0000411)
Severity = Error
Facility = Null
Language = Neutral
STATUS_HIBERNATION_FAILURE
.

MessageId = 0x0412 ; // NTSTATUS(0xC0000412)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DELAY_LOAD_FAILED
.

MessageId = 0x0413 ; // NTSTATUS(0xC0000413)
Severity = Error
Facility = Null
Language = Neutral
STATUS_AUTHENTICATION_FIREWALL_FAILED
.

MessageId = 0x0414 ; // NTSTATUS(0xC0000414)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VDM_DISALLOWED
.

MessageId = 0x0415 ; // NTSTATUS(0xC0000415)
Severity = Error
Facility = Null
Language = Neutral
STATUS_HUNG_DISPLAY_DRIVER_THREAD
.

MessageId = 0x0416 ; // NTSTATUS(0xC0000416)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INSUFFICIENT_RESOURCE_FOR_SPECIFIED_SHARED_SECTION_SIZE
.

MessageId = 0x0417 ; // NTSTATUS(0xC0000417)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_CRUNTIME_PARAMETER
.

MessageId = 0x0418 ; // NTSTATUS(0xC0000418)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NTLM_BLOCKED
.

MessageId = 0x0419 ; // NTSTATUS(0xC0000419)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_SRC_SID_EXISTS_IN_FOREST
.

MessageId = 0x041A ; // NTSTATUS(0xC000041A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_DOMAIN_NAME_EXISTS_IN_FOREST
.

MessageId = 0x041B ; // NTSTATUS(0xC000041B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_FLAT_NAME_EXISTS_IN_FOREST
.

MessageId = 0x041C ; // NTSTATUS(0xC000041C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_USER_PRINCIPAL_NAME
.

MessageId = 0x041D ; // NTSTATUS(0xC000041D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FATAL_USER_CALLBACK_EXCEPTION
.

MessageId = 0x0420 ; // NTSTATUS(0xC0000420)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ASSERTION_FAILURE
.

MessageId = 0x0421 ; // NTSTATUS(0xC0000421)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VERIFIER_STOP
.

MessageId = 0x0423 ; // NTSTATUS(0xC0000423)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CALLBACK_POP_STACK
.

MessageId = 0x0424 ; // NTSTATUS(0xC0000424)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INCOMPATIBLE_DRIVER_BLOCKED
.

MessageId = 0x0425 ; // NTSTATUS(0xC0000425)
Severity = Error
Facility = Null
Language = Neutral
STATUS_HIVE_UNLOADED
.

MessageId = 0x0426 ; // NTSTATUS(0xC0000426)
Severity = Error
Facility = Null
Language = Neutral
STATUS_COMPRESSION_DISABLED
.

MessageId = 0x0427 ; // NTSTATUS(0xC0000427)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_SYSTEM_LIMITATION
.

MessageId = 0x0428 ; // NTSTATUS(0xC0000428)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_IMAGE_HASH
.

MessageId = 0x0429 ; // NTSTATUS(0xC0000429)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_CAPABLE
.

MessageId = 0x042A ; // NTSTATUS(0xC000042A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REQUEST_OUT_OF_SEQUENCE
.

MessageId = 0x042B ; // NTSTATUS(0xC000042B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IMPLEMENTATION_LIMIT
.

MessageId = 0x042C ; // NTSTATUS(0xC000042C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ELEVATION_REQUIRED
.

MessageId = 0x042D ; // NTSTATUS(0xC000042D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_SECURITY_CONTEXT
.

MessageId = 0x042F ; // NTSTATUS(0xC000042F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PKU2U_CERT_FAILURE
.

MessageId = 0x0432 ; // NTSTATUS(0xC0000432)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BEYOND_VDL
.

MessageId = 0x0433 ; // NTSTATUS(0xC0000433)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ENCOUNTERED_WRITE_IN_PROGRESS
.

MessageId = 0x0434 ; // NTSTATUS(0xC0000434)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PTE_CHANGED
.

MessageId = 0x0435 ; // NTSTATUS(0xC0000435)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PURGE_FAILED
.

MessageId = 0x0440 ; // NTSTATUS(0xC0000440)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CRED_REQUIRES_CONFIRMATION
.

MessageId = 0x0441 ; // NTSTATUS(0xC0000441)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CS_ENCRYPTION_INVALID_SERVER_RESPONSE
.

MessageId = 0x0442 ; // NTSTATUS(0xC0000442)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CS_ENCRYPTION_UNSUPPORTED_SERVER
.

MessageId = 0x0443 ; // NTSTATUS(0xC0000443)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CS_ENCRYPTION_EXISTING_ENCRYPTED_FILE
.

MessageId = 0x0444 ; // NTSTATUS(0xC0000444)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CS_ENCRYPTION_NEW_ENCRYPTED_FILE
.

MessageId = 0x0445 ; // NTSTATUS(0xC0000445)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CS_ENCRYPTION_FILE_NOT_CSE
.

MessageId = 0x0446 ; // NTSTATUS(0xC0000446)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_LABEL
.

MessageId = 0x0450 ; // NTSTATUS(0xC0000450)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DRIVER_PROCESS_TERMINATED
.

MessageId = 0x0451 ; // NTSTATUS(0xC0000451)
Severity = Error
Facility = Null
Language = Neutral
STATUS_AMBIGUOUS_SYSTEM_DEVICE
.

MessageId = 0x0452 ; // NTSTATUS(0xC0000452)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SYSTEM_DEVICE_NOT_FOUND
.

MessageId = 0x0453 ; // NTSTATUS(0xC0000453)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RESTART_BOOT_APPLICATION
.

MessageId = 0x0454 ; // NTSTATUS(0xC0000454)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INSUFFICIENT_NVRAM_RESOURCES
.

MessageId = 0x0455 ; // NTSTATUS(0xC0000455)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_SESSION
.

MessageId = 0x0456 ; // NTSTATUS(0xC0000456)
Severity = Error
Facility = Null
Language = Neutral
STATUS_THREAD_ALREADY_IN_SESSION
.

MessageId = 0x0457 ; // NTSTATUS(0xC0000457)
Severity = Error
Facility = Null
Language = Neutral
STATUS_THREAD_NOT_IN_SESSION
.

MessageId = 0x0458 ; // NTSTATUS(0xC0000458)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_WEIGHT
.

MessageId = 0x0459 ; // NTSTATUS(0xC0000459)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REQUEST_PAUSED
.

MessageId = 0x0460 ; // NTSTATUS(0xC0000460)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_RANGES_PROCESSED
.

MessageId = 0x0461 ; // NTSTATUS(0xC0000461)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DISK_RESOURCES_EXHAUSTED
.

MessageId = 0x0462 ; // NTSTATUS(0xC0000462)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NEEDS_REMEDIATION
.

MessageId = 0x0463 ; // NTSTATUS(0xC0000463)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_FEATURE_NOT_SUPPORTED
.

MessageId = 0x0464 ; // NTSTATUS(0xC0000464)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_UNREACHABLE
.

MessageId = 0x0465 ; // NTSTATUS(0xC0000465)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_TOKEN
.

MessageId = 0x0466 ; // NTSTATUS(0xC0000466)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SERVER_UNAVAILABLE
.

MessageId = 0x0467 ; // NTSTATUS(0xC0000467)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_NOT_AVAILABLE
.

MessageId = 0x0468 ; // NTSTATUS(0xC0000468)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_INSUFFICIENT_RESOURCES
.

MessageId = 0x0469 ; // NTSTATUS(0xC0000469)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PACKAGE_UPDATING
.

MessageId = 0x046A ; // NTSTATUS(0xC000046A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_READ_FROM_COPY
.

MessageId = 0x046B ; // NTSTATUS(0xC000046B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FT_WRITE_FAILURE
.

MessageId = 0x046C ; // NTSTATUS(0xC000046C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FT_DI_SCAN_REQUIRED
.

MessageId = 0x046D ; // NTSTATUS(0xC000046D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OBJECT_NOT_EXTERNALLY_BACKED
.

MessageId = 0x046E ; // NTSTATUS(0xC000046E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_EXTERNAL_BACKING_PROVIDER_UNKNOWN
.

MessageId = 0x046F ; // NTSTATUS(0xC000046F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_COMPRESSION_NOT_BENEFICIAL
.

MessageId = 0x0470 ; // NTSTATUS(0xC0000470)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DATA_CHECKSUM_ERROR
.

MessageId = 0x0471 ; // NTSTATUS(0xC0000471)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INTERMIXED_KERNEL_EA_OPERATION
.

MessageId = 0x0472 ; // NTSTATUS(0xC0000472)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TRIM_READ_ZERO_NOT_SUPPORTED
.

MessageId = 0x0473 ; // NTSTATUS(0xC0000473)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TOO_MANY_SEGMENT_DESCRIPTORS
.

MessageId = 0x0474 ; // NTSTATUS(0xC0000474)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_OFFSET_ALIGNMENT
.

MessageId = 0x0475 ; // NTSTATUS(0xC0000475)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_FIELD_IN_PARAMETER_LIST
.

MessageId = 0x0476 ; // NTSTATUS(0xC0000476)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OPERATION_IN_PROGRESS
.

MessageId = 0x0477 ; // NTSTATUS(0xC0000477)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_INITIATOR_TARGET_PATH
.

MessageId = 0x0478 ; // NTSTATUS(0xC0000478)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SCRUB_DATA_DISABLED
.

MessageId = 0x0479 ; // NTSTATUS(0xC0000479)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_REDUNDANT_STORAGE
.

MessageId = 0x047A ; // NTSTATUS(0xC000047A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RESIDENT_FILE_NOT_SUPPORTED
.

MessageId = 0x047B ; // NTSTATUS(0xC000047B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_COMPRESSED_FILE_NOT_SUPPORTED
.

MessageId = 0x047C ; // NTSTATUS(0xC000047C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DIRECTORY_NOT_SUPPORTED
.

MessageId = 0x047D ; // NTSTATUS(0xC000047D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IO_OPERATION_TIMEOUT
.

MessageId = 0x047E ; // NTSTATUS(0xC000047E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SYSTEM_NEEDS_REMEDIATION
.

MessageId = 0x047F ; // NTSTATUS(0xC000047F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_APPX_INTEGRITY_FAILURE_CLR_NGEN
.

MessageId = 0x0480 ; // NTSTATUS(0xC0000480)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SHARE_UNAVAILABLE
.

MessageId = 0x0481 ; // NTSTATUS(0xC0000481)
Severity = Error
Facility = Null
Language = Neutral
STATUS_APISET_NOT_HOSTED
.

MessageId = 0x0482 ; // NTSTATUS(0xC0000482)
Severity = Error
Facility = Null
Language = Neutral
STATUS_APISET_NOT_PRESENT
.

MessageId = 0x0483 ; // NTSTATUS(0xC0000483)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_HARDWARE_ERROR
.

MessageId = 0x0484 ; // NTSTATUS(0xC0000484)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FIRMWARE_SLOT_INVALID
.

MessageId = 0x0485 ; // NTSTATUS(0xC0000485)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FIRMWARE_IMAGE_INVALID
.

MessageId = 0x0486 ; // NTSTATUS(0xC0000486)
Severity = Error
Facility = Null
Language = Neutral
STATUS_STORAGE_TOPOLOGY_ID_MISMATCH
.

MessageId = 0x0487 ; // NTSTATUS(0xC0000487)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WIM_NOT_BOOTABLE
.

MessageId = 0x0488 ; // NTSTATUS(0xC0000488)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BLOCKED_BY_PARENTAL_CONTROLS
.

MessageId = 0x0489 ; // NTSTATUS(0xC0000489)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NEEDS_REGISTRATION
.

MessageId = 0x048A ; // NTSTATUS(0xC000048A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_QUOTA_ACTIVITY
.

MessageId = 0x048B ; // NTSTATUS(0xC000048B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CALLBACK_INVOKE_INLINE
.

MessageId = 0x048C ; // NTSTATUS(0xC000048C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BLOCK_TOO_MANY_REFERENCES
.

MessageId = 0x048D ; // NTSTATUS(0xC000048D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MARKED_TO_DISALLOW_WRITES
.

MessageId = 0x048E ; // NTSTATUS(0xC000048E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NETWORK_ACCESS_DENIED_EDP
.

MessageId = 0x048F ; // NTSTATUS(0xC000048F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ENCLAVE_FAILURE
.

MessageId = 0x0490 ; // NTSTATUS(0xC0000490)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PNP_NO_COMPAT_DRIVERS
.

MessageId = 0x0491 ; // NTSTATUS(0xC0000491)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PNP_DRIVER_PACKAGE_NOT_FOUND
.

MessageId = 0x0492 ; // NTSTATUS(0xC0000492)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PNP_DRIVER_CONFIGURATION_NOT_FOUND
.

MessageId = 0x0493 ; // NTSTATUS(0xC0000493)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PNP_DRIVER_CONFIGURATION_INCOMPLETE
.

MessageId = 0x0494 ; // NTSTATUS(0xC0000494)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PNP_FUNCTION_DRIVER_REQUIRED
.

MessageId = 0x0495 ; // NTSTATUS(0xC0000495)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PNP_DEVICE_CONFIGURATION_PENDING
.

MessageId = 0x0496 ; // NTSTATUS(0xC0000496)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_HINT_NAME_BUFFER_TOO_SMALL
.

MessageId = 0x0497 ; // NTSTATUS(0xC0000497)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PACKAGE_NOT_AVAILABLE
.

MessageId = 0x0499 ; // NTSTATUS(0xC0000499)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_IN_MAINTENANCE
.

MessageId = 0x049A ; // NTSTATUS(0xC000049A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SUPPORTED_ON_DAX
.

MessageId = 0x049B ; // NTSTATUS(0xC000049B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FREE_SPACE_TOO_FRAGMENTED
.

MessageId = 0x049C ; // NTSTATUS(0xC000049C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DAX_MAPPING_EXISTS
.

MessageId = 0x049D ; // NTSTATUS(0xC000049D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CHILD_PROCESS_BLOCKED
.

MessageId = 0x049E ; // NTSTATUS(0xC000049E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_STORAGE_LOST_DATA_PERSISTENCE
.

MessageId = 0x04A0 ; // NTSTATUS(0xC00004A0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PARTITION_TERMINATING
.

MessageId = 0x04A1 ; // NTSTATUS(0xC00004A1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_EXTERNAL_SYSKEY_NOT_SUPPORTED
.

MessageId = 0x04A2 ; // NTSTATUS(0xC00004A2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ENCLAVE_VIOLATION
.

MessageId = 0x04A3 ; // NTSTATUS(0xC00004A3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_PROTECTED_UNDER_DPL
.

MessageId = 0x04A4 ; // NTSTATUS(0xC00004A4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VOLUME_NOT_CLUSTER_ALIGNED
.

MessageId = 0x04A5 ; // NTSTATUS(0xC00004A5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_PHYSICALLY_ALIGNED_FREE_SPACE_FOUND
.

MessageId = 0x04A6 ; // NTSTATUS(0xC00004A6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_APPX_FILE_NOT_ENCRYPTED
.

MessageId = 0x04A7 ; // NTSTATUS(0xC00004A7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RWRAW_ENCRYPTED_FILE_NOT_ENCRYPTED
.

MessageId = 0x04A8 ; // NTSTATUS(0xC00004A8)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RWRAW_ENCRYPTED_INVALID_EDATAINFO_FILEOFFSET
.

MessageId = 0x04A9 ; // NTSTATUS(0xC00004A9)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RWRAW_ENCRYPTED_INVALID_EDATAINFO_FILERANGE
.

MessageId = 0x04AA ; // NTSTATUS(0xC00004AA)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RWRAW_ENCRYPTED_INVALID_EDATAINFO_PARAMETER
.

MessageId = 0x04AB ; // NTSTATUS(0xC00004AB)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FT_READ_FAILURE
.

MessageId = 0x04AC ; // NTSTATUS(0xC00004AC)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PATCH_CONFLICT
.

MessageId = 0x04AD ; // NTSTATUS(0xC00004AD)
Severity = Error
Facility = Null
Language = Neutral
STATUS_STORAGE_RESERVE_ID_INVALID
.

MessageId = 0x04AE ; // NTSTATUS(0xC00004AE)
Severity = Error
Facility = Null
Language = Neutral
STATUS_STORAGE_RESERVE_DOES_NOT_EXIST
.

MessageId = 0x04AF ; // NTSTATUS(0xC00004AF)
Severity = Error
Facility = Null
Language = Neutral
STATUS_STORAGE_RESERVE_ALREADY_EXISTS
.

MessageId = 0x04B0 ; // NTSTATUS(0xC00004B0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_STORAGE_RESERVE_NOT_EMPTY
.

MessageId = 0x04B1 ; // NTSTATUS(0xC00004B1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_A_DAX_VOLUME
.

MessageId = 0x04B2 ; // NTSTATUS(0xC00004B2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_DAX_MAPPABLE
.

MessageId = 0x04B3 ; // NTSTATUS(0xC00004B3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CASE_DIFFERING_NAMES_IN_DIR
.

MessageId = 0x04B4 ; // NTSTATUS(0xC00004B4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_NOT_SUPPORTED
.

MessageId = 0x04B5 ; // NTSTATUS(0xC00004B5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SUPPORTED_WITH_BTT
.

MessageId = 0x04B6 ; // NTSTATUS(0xC00004B6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ENCRYPTION_DISABLED
.

MessageId = 0x04B7 ; // NTSTATUS(0xC00004B7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ENCRYPTING_METADATA_DISALLOWED
.

MessageId = 0x04B8 ; // NTSTATUS(0xC00004B8)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CANT_CLEAR_ENCRYPTION_FLAG
.

MessageId = 0x04B9 ; // NTSTATUS(0xC00004B9)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNSATISFIED_DEPENDENCIES
.

MessageId = 0x04BA ; // NTSTATUS(0xC00004BA)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CASE_SENSITIVE_PATH
.

MessageId = 0x04BB ; // NTSTATUS(0xC00004BB)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNSUPPORTED_PAGING_MODE
.

MessageId = 0x04BC ; // NTSTATUS(0xC00004BC)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNTRUSTED_MOUNT_POINT
.

MessageId = 0x04BD ; // NTSTATUS(0xC00004BD)
Severity = Error
Facility = Null
Language = Neutral
STATUS_HAS_SYSTEM_CRITICAL_FILES
.

MessageId = 0x04BE ; // NTSTATUS(0xC00004BE)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OBJECT_IS_IMMUTABLE
.

MessageId = 0x04BF ; // NTSTATUS(0xC00004BF)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FT_READ_FROM_COPY_FAILURE
.

MessageId = 0x04C0 ; // NTSTATUS(0xC00004C0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IMAGE_LOADED_AS_PATCH_IMAGE
.

MessageId = 0x04C1 ; // NTSTATUS(0xC00004C1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_STORAGE_STACK_ACCESS_DENIED
.

MessageId = 0x04C2 ; // NTSTATUS(0xC00004C2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INSUFFICIENT_VIRTUAL_ADDR_RESOURCES
.

MessageId = 0x04C3 ; // NTSTATUS(0xC00004C3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ENCRYPTED_FILE_NOT_SUPPORTED
.

MessageId = 0x04C4 ; // NTSTATUS(0xC00004C4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SPARSE_FILE_NOT_SUPPORTED
.

MessageId = 0x04C5 ; // NTSTATUS(0xC00004C5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PAGEFILE_NOT_SUPPORTED
.

MessageId = 0x04C6 ; // NTSTATUS(0xC00004C6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VOLUME_NOT_SUPPORTED
.

MessageId = 0x04C7 ; // NTSTATUS(0xC00004C7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SUPPORTED_WITH_BYPASSIO
.

MessageId = 0x04C8 ; // NTSTATUS(0xC00004C8)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_BYPASSIO_DRIVER_SUPPORT
.

MessageId = 0x04C9 ; // NTSTATUS(0xC00004C9)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SUPPORTED_WITH_ENCRYPTION
.

MessageId = 0x04CA ; // NTSTATUS(0xC00004CA)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SUPPORTED_WITH_COMPRESSION
.

MessageId = 0x04CB ; // NTSTATUS(0xC00004CB)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SUPPORTED_WITH_REPLICATION
.

MessageId = 0x04CC ; // NTSTATUS(0xC00004CC)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SUPPORTED_WITH_DEDUPLICATION
.

MessageId = 0x04CD ; // NTSTATUS(0xC00004CD)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SUPPORTED_WITH_AUDITING
.

MessageId = 0x04CE ; // NTSTATUS(0xC00004CE)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SUPPORTED_WITH_MONITORING
.

MessageId = 0x04CF ; // NTSTATUS(0xC00004CF)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SUPPORTED_WITH_SNAPSHOT
.

MessageId = 0x04D0 ; // NTSTATUS(0xC00004D0)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SUPPORTED_WITH_VIRTUALIZATION
.

MessageId = 0x04D1 ; // NTSTATUS(0xC00004D1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INDEX_OUT_OF_BOUNDS
.

MessageId = 0x04D2 ; // NTSTATUS(0xC00004D2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BYPASSIO_FLT_NOT_SUPPORTED
.

MessageId = 0x04D3 ; // NTSTATUS(0xC00004D3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VOLUME_WRITE_ACCESS_DENIED
.

MessageId = 0x04D4 ; // NTSTATUS(0xC00004D4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PATCH_NOT_REGISTERED
.

MessageId = 0x04D5 ; // NTSTATUS(0xC00004D5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SUPPORTED_WITH_CACHED_HANDLE
.

MessageId = 0x0500 ; // NTSTATUS(0xC0000500)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_TASK_NAME
.

MessageId = 0x0501 ; // NTSTATUS(0xC0000501)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_TASK_INDEX
.

MessageId = 0x0502 ; // NTSTATUS(0xC0000502)
Severity = Error
Facility = Null
Language = Neutral
STATUS_THREAD_ALREADY_IN_TASK
.

MessageId = 0x0503 ; // NTSTATUS(0xC0000503)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CALLBACK_BYPASS
.

MessageId = 0x0504 ; // NTSTATUS(0xC0000504)
Severity = Error
Facility = Null
Language = Neutral
STATUS_UNDEFINED_SCOPE
.

MessageId = 0x0505 ; // NTSTATUS(0xC0000505)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_CAP
.

MessageId = 0x0506 ; // NTSTATUS(0xC0000506)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_GUI_PROCESS
.

MessageId = 0x0507 ; // NTSTATUS(0xC0000507)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_HUNG
.

MessageId = 0x0508 ; // NTSTATUS(0xC0000508)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CONTAINER_ASSIGNED
.

MessageId = 0x0509 ; // NTSTATUS(0xC0000509)
Severity = Error
Facility = Null
Language = Neutral
STATUS_JOB_NO_CONTAINER
.

MessageId = 0x050A ; // NTSTATUS(0xC000050A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DEVICE_UNRESPONSIVE
.

MessageId = 0x050B ; // NTSTATUS(0xC000050B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REPARSE_POINT_ENCOUNTERED
.

MessageId = 0x050C ; // NTSTATUS(0xC000050C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ATTRIBUTE_NOT_PRESENT
.

MessageId = 0x050D ; // NTSTATUS(0xC000050D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_A_TIERED_VOLUME
.

MessageId = 0x050E ; // NTSTATUS(0xC000050E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ALREADY_HAS_STREAM_ID
.

MessageId = 0x050F ; // NTSTATUS(0xC000050F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_JOB_NOT_EMPTY
.

MessageId = 0x0510 ; // NTSTATUS(0xC0000510)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ALREADY_INITIALIZED
.

MessageId = 0x0511 ; // NTSTATUS(0xC0000511)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ENCLAVE_NOT_TERMINATED
.

MessageId = 0x0512 ; // NTSTATUS(0xC0000512)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ENCLAVE_IS_TERMINATING
.

MessageId = 0x0513 ; // NTSTATUS(0xC0000513)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SMB1_NOT_AVAILABLE
.

MessageId = 0x0514 ; // NTSTATUS(0xC0000514)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SMR_GARBAGE_COLLECTION_REQUIRED
.

MessageId = 0x0515 ; // NTSTATUS(0xC0000515)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INTERRUPTED
.

MessageId = 0x0516 ; // NTSTATUS(0xC0000516)
Severity = Error
Facility = Null
Language = Neutral
STATUS_THREAD_NOT_RUNNING
.

MessageId = 0x0517 ; // NTSTATUS(0xC0000517)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SESSION_KEY_TOO_SHORT
.

MessageId = 0x0518 ; // NTSTATUS(0xC0000518)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FS_METADATA_INCONSISTENT
.

MessageId = 0x0602 ; // NTSTATUS(0xC0000602)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FAIL_FAST_EXCEPTION
.

MessageId = 0x0603 ; // NTSTATUS(0xC0000603)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IMAGE_CERT_REVOKED
.

MessageId = 0x0604 ; // NTSTATUS(0xC0000604)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DYNAMIC_CODE_BLOCKED
.

MessageId = 0x0605 ; // NTSTATUS(0xC0000605)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IMAGE_CERT_EXPIRED
.

MessageId = 0x0606 ; // NTSTATUS(0xC0000606)
Severity = Error
Facility = Null
Language = Neutral
STATUS_STRICT_CFG_VIOLATION
.

MessageId = 0x060A ; // NTSTATUS(0xC000060A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SET_CONTEXT_DENIED
.

MessageId = 0x060B ; // NTSTATUS(0xC000060B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CROSS_PARTITION_VIOLATION
.

MessageId = 0x0700 ; // NTSTATUS(0xC0000700)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PORT_CLOSED
.

MessageId = 0x0701 ; // NTSTATUS(0xC0000701)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MESSAGE_LOST
.

MessageId = 0x0702 ; // NTSTATUS(0xC0000702)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_MESSAGE
.

MessageId = 0x0703 ; // NTSTATUS(0xC0000703)
Severity = Error
Facility = Null
Language = Neutral
STATUS_REQUEST_CANCELED
.

MessageId = 0x0704 ; // NTSTATUS(0xC0000704)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RECURSIVE_DISPATCH
.

MessageId = 0x0705 ; // NTSTATUS(0xC0000705)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LPC_RECEIVE_BUFFER_EXPECTED
.

MessageId = 0x0706 ; // NTSTATUS(0xC0000706)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LPC_INVALID_CONNECTION_USAGE
.

MessageId = 0x0707 ; // NTSTATUS(0xC0000707)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LPC_REQUESTS_NOT_ALLOWED
.

MessageId = 0x0708 ; // NTSTATUS(0xC0000708)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RESOURCE_IN_USE
.

MessageId = 0x0709 ; // NTSTATUS(0xC0000709)
Severity = Error
Facility = Null
Language = Neutral
STATUS_HARDWARE_MEMORY_ERROR
.

MessageId = 0x070A ; // NTSTATUS(0xC000070A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_THREADPOOL_HANDLE_EXCEPTION
.

MessageId = 0x070B ; // NTSTATUS(0xC000070B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_THREADPOOL_SET_EVENT_ON_COMPLETION_FAILED
.

MessageId = 0x070C ; // NTSTATUS(0xC000070C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_THREADPOOL_RELEASE_SEMAPHORE_ON_COMPLETION_FAILED
.

MessageId = 0x070D ; // NTSTATUS(0xC000070D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_THREADPOOL_RELEASE_MUTEX_ON_COMPLETION_FAILED
.

MessageId = 0x070E ; // NTSTATUS(0xC000070E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_THREADPOOL_FREE_LIBRARY_ON_COMPLETION_FAILED
.

MessageId = 0x070F ; // NTSTATUS(0xC000070F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_THREADPOOL_RELEASED_DURING_OPERATION
.

MessageId = 0x0710 ; // NTSTATUS(0xC0000710)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CALLBACK_RETURNED_WHILE_IMPERSONATING
.

MessageId = 0x0711 ; // NTSTATUS(0xC0000711)
Severity = Error
Facility = Null
Language = Neutral
STATUS_APC_RETURNED_WHILE_IMPERSONATING
.

MessageId = 0x0712 ; // NTSTATUS(0xC0000712)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PROCESS_IS_PROTECTED
.

MessageId = 0x0713 ; // NTSTATUS(0xC0000713)
Severity = Error
Facility = Null
Language = Neutral
STATUS_MCA_EXCEPTION
.

MessageId = 0x0714 ; // NTSTATUS(0xC0000714)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CERTIFICATE_MAPPING_NOT_UNIQUE
.

MessageId = 0x0715 ; // NTSTATUS(0xC0000715)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SYMLINK_CLASS_DISABLED
.

MessageId = 0x0716 ; // NTSTATUS(0xC0000716)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_IDN_NORMALIZATION
.

MessageId = 0x0717 ; // NTSTATUS(0xC0000717)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_UNICODE_TRANSLATION
.

MessageId = 0x0718 ; // NTSTATUS(0xC0000718)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ALREADY_REGISTERED
.

MessageId = 0x0719 ; // NTSTATUS(0xC0000719)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CONTEXT_MISMATCH
.

MessageId = 0x071A ; // NTSTATUS(0xC000071A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PORT_ALREADY_HAS_COMPLETION_LIST
.

MessageId = 0x071B ; // NTSTATUS(0xC000071B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CALLBACK_RETURNED_THREAD_PRIORITY
.

MessageId = 0x071C ; // NTSTATUS(0xC000071C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_THREAD
.

MessageId = 0x071D ; // NTSTATUS(0xC000071D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CALLBACK_RETURNED_TRANSACTION
.

MessageId = 0x071E ; // NTSTATUS(0xC000071E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CALLBACK_RETURNED_LDR_LOCK
.

MessageId = 0x071F ; // NTSTATUS(0xC000071F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CALLBACK_RETURNED_LANG
.

MessageId = 0x0720 ; // NTSTATUS(0xC0000720)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CALLBACK_RETURNED_PRI_BACK
.

MessageId = 0x0721 ; // NTSTATUS(0xC0000721)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CALLBACK_RETURNED_THREAD_AFFINITY
.

MessageId = 0x0722 ; // NTSTATUS(0xC0000722)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LPC_HANDLE_COUNT_EXCEEDED
.

MessageId = 0x0723 ; // NTSTATUS(0xC0000723)
Severity = Error
Facility = Null
Language = Neutral
STATUS_EXECUTABLE_MEMORY_WRITE
.

MessageId = 0x0724 ; // NTSTATUS(0xC0000724)
Severity = Error
Facility = Null
Language = Neutral
STATUS_KERNEL_EXECUTABLE_MEMORY_WRITE
.

MessageId = 0x0725 ; // NTSTATUS(0xC0000725)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ATTACHED_EXECUTABLE_MEMORY_WRITE
.

MessageId = 0x0726 ; // NTSTATUS(0xC0000726)
Severity = Error
Facility = Null
Language = Neutral
STATUS_TRIGGERED_EXECUTABLE_MEMORY_WRITE
.

MessageId = 0x0800 ; // NTSTATUS(0xC0000800)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DISK_REPAIR_DISABLED
.

MessageId = 0x0801 ; // NTSTATUS(0xC0000801)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_DOMAIN_RENAME_IN_PROGRESS
.

MessageId = 0x0802 ; // NTSTATUS(0xC0000802)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DISK_QUOTA_EXCEEDED
.

MessageId = 0x0804 ; // NTSTATUS(0xC0000804)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CONTENT_BLOCKED
.

MessageId = 0x0805 ; // NTSTATUS(0xC0000805)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_CLUSTERS
.

MessageId = 0x0806 ; // NTSTATUS(0xC0000806)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VOLUME_DIRTY
.

MessageId = 0x0808 ; // NTSTATUS(0xC0000808)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DISK_REPAIR_UNSUCCESSFUL
.

MessageId = 0x0809 ; // NTSTATUS(0xC0000809)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CORRUPT_LOG_OVERFULL
.

MessageId = 0x080A ; // NTSTATUS(0xC000080A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CORRUPT_LOG_CORRUPTED
.

MessageId = 0x080B ; // NTSTATUS(0xC000080B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CORRUPT_LOG_UNAVAILABLE
.

MessageId = 0x080C ; // NTSTATUS(0xC000080C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CORRUPT_LOG_DELETED_FULL
.

MessageId = 0x080D ; // NTSTATUS(0xC000080D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CORRUPT_LOG_CLEARED
.

MessageId = 0x080E ; // NTSTATUS(0xC000080E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ORPHAN_NAME_EXHAUSTED
.

MessageId = 0x080F ; // NTSTATUS(0xC000080F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PROACTIVE_SCAN_IN_PROGRESS
.

MessageId = 0x0810 ; // NTSTATUS(0xC0000810)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ENCRYPTED_IO_NOT_POSSIBLE
.

MessageId = 0x0811 ; // NTSTATUS(0xC0000811)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CORRUPT_LOG_UPLEVEL_RECORDS
.

MessageId = 0x0901 ; // NTSTATUS(0xC0000901)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_CHECKED_OUT
.

MessageId = 0x0902 ; // NTSTATUS(0xC0000902)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CHECKOUT_REQUIRED
.

MessageId = 0x0903 ; // NTSTATUS(0xC0000903)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_FILE_TYPE
.

MessageId = 0x0904 ; // NTSTATUS(0xC0000904)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_TOO_LARGE
.

MessageId = 0x0905 ; // NTSTATUS(0xC0000905)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FORMS_AUTH_REQUIRED
.

MessageId = 0x0906 ; // NTSTATUS(0xC0000906)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VIRUS_INFECTED
.

MessageId = 0x0907 ; // NTSTATUS(0xC0000907)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VIRUS_DELETED
.

MessageId = 0x0908 ; // NTSTATUS(0xC0000908)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_MCFG_TABLE
.

MessageId = 0x0909 ; // NTSTATUS(0xC0000909)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CANNOT_BREAK_OPLOCK
.

MessageId = 0x090A ; // NTSTATUS(0xC000090A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_KEY
.

MessageId = 0x090B ; // NTSTATUS(0xC000090B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BAD_DATA
.

MessageId = 0x090C ; // NTSTATUS(0xC000090C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NO_KEY
.

MessageId = 0x0910 ; // NTSTATUS(0xC0000910)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_HANDLE_REVOKED
.

MessageId = 0x0911 ; // NTSTATUS(0xC0000911)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SECTION_DIRECT_MAP_ONLY
.

MessageId = 0x0912 ; // NTSTATUS(0xC0000912)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BLOCK_WEAK_REFERENCE_INVALID
.

MessageId = 0x0913 ; // NTSTATUS(0xC0000913)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BLOCK_SOURCE_WEAK_REFERENCE_INVALID
.

MessageId = 0x0914 ; // NTSTATUS(0xC0000914)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BLOCK_TARGET_WEAK_REFERENCE_INVALID
.

MessageId = 0x0915 ; // NTSTATUS(0xC0000915)
Severity = Error
Facility = Null
Language = Neutral
STATUS_BLOCK_SHARED
.

MessageId = 0x0C08 ; // NTSTATUS(0xC0000C08)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VRF_VOLATILE_CFG_AND_IO_ENABLED
.

MessageId = 0x0C09 ; // NTSTATUS(0xC0000C09)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VRF_VOLATILE_NOT_STOPPABLE
.

MessageId = 0x0C0A ; // NTSTATUS(0xC0000C0A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VRF_VOLATILE_SAFE_MODE
.

MessageId = 0x0C0B ; // NTSTATUS(0xC0000C0B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VRF_VOLATILE_NOT_RUNNABLE_SYSTEM
.

MessageId = 0x0C0C ; // NTSTATUS(0xC0000C0C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VRF_VOLATILE_NOT_SUPPORTED_RULECLASS
.

MessageId = 0x0C0D ; // NTSTATUS(0xC0000C0D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VRF_VOLATILE_PROTECTED_DRIVER
.

MessageId = 0x0C0E ; // NTSTATUS(0xC0000C0E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VRF_VOLATILE_NMI_REGISTERED
.

MessageId = 0x0C0F ; // NTSTATUS(0xC0000C0F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_VRF_VOLATILE_SETTINGS_CONFLICT
.

MessageId = 0x0C76 ; // NTSTATUS(0xC0000C76)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DIF_IOCALLBACK_NOT_REPLACED
.

MessageId = 0x0C77 ; // NTSTATUS(0xC0000C77)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DIF_LIVEDUMP_LIMIT_EXCEEDED
.

MessageId = 0x0C78 ; // NTSTATUS(0xC0000C78)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DIF_VOLATILE_SECTION_NOT_LOCKED
.

MessageId = 0x0C79 ; // NTSTATUS(0xC0000C79)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DIF_VOLATILE_DRIVER_HOTPATCHED
.

MessageId = 0x0C7A ; // NTSTATUS(0xC0000C7A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DIF_VOLATILE_INVALID_INFO
.

MessageId = 0x0C7B ; // NTSTATUS(0xC0000C7B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DIF_VOLATILE_DRIVER_IS_NOT_RUNNING
.

MessageId = 0x0C7C ; // NTSTATUS(0xC0000C7C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DIF_VOLATILE_PLUGIN_IS_NOT_RUNNING
.

MessageId = 0x0C7D ; // NTSTATUS(0xC0000C7D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DIF_VOLATILE_PLUGIN_CHANGE_NOT_ALLOWED
.

MessageId = 0x0C7E ; // NTSTATUS(0xC0000C7E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DIF_VOLATILE_NOT_ALLOWED
.

MessageId = 0x0C7F ; // NTSTATUS(0xC0000C7F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DIF_BINDING_API_NOT_FOUND
.

MessageId = 0x9898 ; // NTSTATUS(0xC0009898)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WOW_ASSERTION
.

MessageId = 0xA000 ; // NTSTATUS(0xC000A000)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_SIGNATURE
.

MessageId = 0xA001 ; // NTSTATUS(0xC000A001)
Severity = Error
Facility = Null
Language = Neutral
STATUS_HMAC_NOT_SUPPORTED
.

MessageId = 0xA002 ; // NTSTATUS(0xC000A002)
Severity = Error
Facility = Null
Language = Neutral
STATUS_AUTH_TAG_MISMATCH
.

MessageId = 0xA003 ; // NTSTATUS(0xC000A003)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_STATE_TRANSITION
.

MessageId = 0xA004 ; // NTSTATUS(0xC000A004)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_KERNEL_INFO_VERSION
.

MessageId = 0xA005 ; // NTSTATUS(0xC000A005)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PEP_INFO_VERSION
.

MessageId = 0xA006 ; // NTSTATUS(0xC000A006)
Severity = Error
Facility = Null
Language = Neutral
STATUS_HANDLE_REVOKED
.

MessageId = 0xA007 ; // NTSTATUS(0xC000A007)
Severity = Error
Facility = Null
Language = Neutral
STATUS_EOF_ON_GHOSTED_RANGE
.

MessageId = 0xA008 ; // NTSTATUS(0xC000A008)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CC_NEEDS_CALLBACK_SECTION_DRAIN
.

MessageId = 0xA010 ; // NTSTATUS(0xC000A010)
Severity = Error
Facility = Null
Language = Neutral
STATUS_IPSEC_QUEUE_OVERFLOW
.

MessageId = 0xA011 ; // NTSTATUS(0xC000A011)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ND_QUEUE_OVERFLOW
.

MessageId = 0xA012 ; // NTSTATUS(0xC000A012)
Severity = Error
Facility = Null
Language = Neutral
STATUS_HOPLIMIT_EXCEEDED
.

MessageId = 0xA013 ; // NTSTATUS(0xC000A013)
Severity = Error
Facility = Null
Language = Neutral
STATUS_PROTOCOL_NOT_SUPPORTED
.

MessageId = 0xA014 ; // NTSTATUS(0xC000A014)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FASTPATH_REJECTED
.

MessageId = 0xA080 ; // NTSTATUS(0xC000A080)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOST_WRITEBEHIND_DATA_NETWORK_DISCONNECTED
.

MessageId = 0xA081 ; // NTSTATUS(0xC000A081)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOST_WRITEBEHIND_DATA_NETWORK_SERVER_ERROR
.

MessageId = 0xA082 ; // NTSTATUS(0xC000A082)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOST_WRITEBEHIND_DATA_LOCAL_DISK_ERROR
.

MessageId = 0xA083 ; // NTSTATUS(0xC000A083)
Severity = Error
Facility = Null
Language = Neutral
STATUS_XML_PARSE_ERROR
.

MessageId = 0xA084 ; // NTSTATUS(0xC000A084)
Severity = Error
Facility = Null
Language = Neutral
STATUS_XMLDSIG_ERROR
.

MessageId = 0xA085 ; // NTSTATUS(0xC000A085)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WRONG_COMPARTMENT
.

MessageId = 0xA086 ; // NTSTATUS(0xC000A086)
Severity = Error
Facility = Null
Language = Neutral
STATUS_AUTHIP_FAILURE
.

MessageId = 0xA087 ; // NTSTATUS(0xC000A087)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_OID_MAPPED_GROUP_CANT_HAVE_MEMBERS
.

MessageId = 0xA088 ; // NTSTATUS(0xC000A088)
Severity = Error
Facility = Null
Language = Neutral
STATUS_DS_OID_NOT_FOUND
.

MessageId = 0xA089 ; // NTSTATUS(0xC000A089)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INCORRECT_ACCOUNT_TYPE
.

MessageId = 0xA08A ; // NTSTATUS(0xC000A08A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LOCAL_POLICY_MODIFICATION_NOT_SUPPORTED
.

MessageId = 0xA100 ; // NTSTATUS(0xC000A100)
Severity = Error
Facility = Null
Language = Neutral
STATUS_HASH_NOT_SUPPORTED
.

MessageId = 0xA101 ; // NTSTATUS(0xC000A101)
Severity = Error
Facility = Null
Language = Neutral
STATUS_HASH_NOT_PRESENT
.

MessageId = 0xA121 ; // NTSTATUS(0xC000A121)
Severity = Error
Facility = Null
Language = Neutral
STATUS_SECONDARY_IC_PROVIDER_NOT_REGISTERED
.

MessageId = 0xA141 ; // NTSTATUS(0xC000A141)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CANNOT_SWITCH_RUNLEVEL
.

MessageId = 0xA142 ; // NTSTATUS(0xC000A142)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_RUNLEVEL_SETTING
.

MessageId = 0xA143 ; // NTSTATUS(0xC000A143)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RUNLEVEL_SWITCH_TIMEOUT
.

MessageId = 0xA145 ; // NTSTATUS(0xC000A145)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RUNLEVEL_SWITCH_AGENT_TIMEOUT
.

MessageId = 0xA146 ; // NTSTATUS(0xC000A146)
Severity = Error
Facility = Null
Language = Neutral
STATUS_RUNLEVEL_SWITCH_IN_PROGRESS
.

MessageId = 0xA200 ; // NTSTATUS(0xC000A200)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_APPCONTAINER
.

MessageId = 0xA201 ; // NTSTATUS(0xC000A201)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_SUPPORTED_IN_APPCONTAINER
.

MessageId = 0xA202 ; // NTSTATUS(0xC000A202)
Severity = Error
Facility = Null
Language = Neutral
STATUS_INVALID_PACKAGE_SID_LENGTH
.

MessageId = 0xA203 ; // NTSTATUS(0xC000A203)
Severity = Error
Facility = Null
Language = Neutral
STATUS_LPAC_ACCESS_DENIED
.

MessageId = 0xA204 ; // NTSTATUS(0xC000A204)
Severity = Error
Facility = Null
Language = Neutral
STATUS_ADMINLESS_ACCESS_DENIED
.

MessageId = 0xA281 ; // NTSTATUS(0xC000A281)
Severity = Error
Facility = Null
Language = Neutral
STATUS_APP_DATA_NOT_FOUND
.

MessageId = 0xA282 ; // NTSTATUS(0xC000A282)
Severity = Error
Facility = Null
Language = Neutral
STATUS_APP_DATA_EXPIRED
.

MessageId = 0xA283 ; // NTSTATUS(0xC000A283)
Severity = Error
Facility = Null
Language = Neutral
STATUS_APP_DATA_CORRUPT
.

MessageId = 0xA284 ; // NTSTATUS(0xC000A284)
Severity = Error
Facility = Null
Language = Neutral
STATUS_APP_DATA_LIMIT_EXCEEDED
.

MessageId = 0xA285 ; // NTSTATUS(0xC000A285)
Severity = Error
Facility = Null
Language = Neutral
STATUS_APP_DATA_REBOOT_REQUIRED
.

MessageId = 0xA2A1 ; // NTSTATUS(0xC000A2A1)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OFFLOAD_READ_FLT_NOT_SUPPORTED
.

MessageId = 0xA2A2 ; // NTSTATUS(0xC000A2A2)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OFFLOAD_WRITE_FLT_NOT_SUPPORTED
.

MessageId = 0xA2A3 ; // NTSTATUS(0xC000A2A3)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OFFLOAD_READ_FILE_NOT_SUPPORTED
.

MessageId = 0xA2A4 ; // NTSTATUS(0xC000A2A4)
Severity = Error
Facility = Null
Language = Neutral
STATUS_OFFLOAD_WRITE_FILE_NOT_SUPPORTED
.

MessageId = 0xA2A5 ; // NTSTATUS(0xC000A2A5)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WOF_WIM_HEADER_CORRUPT
.

MessageId = 0xA2A6 ; // NTSTATUS(0xC000A2A6)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WOF_WIM_RESOURCE_TABLE_CORRUPT
.

MessageId = 0xA2A7 ; // NTSTATUS(0xC000A2A7)
Severity = Error
Facility = Null
Language = Neutral
STATUS_WOF_FILE_RESOURCE_TABLE_CORRUPT
.

MessageId = 0xC001 ; // NTSTATUS(0xC000C001)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CIMFS_IMAGE_CORRUPT
.

MessageId = 0xC002 ; // NTSTATUS(0xC000C002)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CIMFS_IMAGE_VERSION_NOT_SUPPORTED
.

MessageId = 0xCE01 ; // NTSTATUS(0xC000CE01)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_SYSTEM_VIRTUALIZATION_UNAVAILABLE
.

MessageId = 0xCE02 ; // NTSTATUS(0xC000CE02)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_SYSTEM_VIRTUALIZATION_METADATA_CORRUPT
.

MessageId = 0xCE03 ; // NTSTATUS(0xC000CE03)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_SYSTEM_VIRTUALIZATION_BUSY
.

MessageId = 0xCE04 ; // NTSTATUS(0xC000CE04)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_SYSTEM_VIRTUALIZATION_PROVIDER_UNKNOWN
.

MessageId = 0xCE05 ; // NTSTATUS(0xC000CE05)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_SYSTEM_VIRTUALIZATION_INVALID_OPERATION
.

MessageId = 0xCF00 ; // NTSTATUS(0xC000CF00)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_SYNC_ROOT_METADATA_CORRUPT
.

MessageId = 0xCF01 ; // NTSTATUS(0xC000CF01)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_PROVIDER_NOT_RUNNING
.

MessageId = 0xCF02 ; // NTSTATUS(0xC000CF02)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_METADATA_CORRUPT
.

MessageId = 0xCF03 ; // NTSTATUS(0xC000CF03)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_METADATA_TOO_LARGE
.

MessageId = 0xCF06 ; // NTSTATUS(0xC000CF06)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_PROPERTY_VERSION_NOT_SUPPORTED
.

MessageId = 0xCF07 ; // NTSTATUS(0xC000CF07)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_A_CLOUD_FILE
.

MessageId = 0xCF08 ; // NTSTATUS(0xC000CF08)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_NOT_IN_SYNC
.

MessageId = 0xCF09 ; // NTSTATUS(0xC000CF09)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_ALREADY_CONNECTED
.

MessageId = 0xCF0A ; // NTSTATUS(0xC000CF0A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_NOT_SUPPORTED
.

MessageId = 0xCF0B ; // NTSTATUS(0xC000CF0B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_INVALID_REQUEST
.

MessageId = 0xCF0C ; // NTSTATUS(0xC000CF0C)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_READ_ONLY_VOLUME
.

MessageId = 0xCF0D ; // NTSTATUS(0xC000CF0D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_CONNECTED_PROVIDER_ONLY
.

MessageId = 0xCF0E ; // NTSTATUS(0xC000CF0E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_VALIDATION_FAILED
.

MessageId = 0xCF0F ; // NTSTATUS(0xC000CF0F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_AUTHENTICATION_FAILED
.

MessageId = 0xCF10 ; // NTSTATUS(0xC000CF10)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_INSUFFICIENT_RESOURCES
.

MessageId = 0xCF11 ; // NTSTATUS(0xC000CF11)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_NETWORK_UNAVAILABLE
.

MessageId = 0xCF12 ; // NTSTATUS(0xC000CF12)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_UNSUCCESSFUL
.

MessageId = 0xCF13 ; // NTSTATUS(0xC000CF13)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_NOT_UNDER_SYNC_ROOT
.

MessageId = 0xCF14 ; // NTSTATUS(0xC000CF14)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_IN_USE
.

MessageId = 0xCF15 ; // NTSTATUS(0xC000CF15)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_PINNED
.

MessageId = 0xCF16 ; // NTSTATUS(0xC000CF16)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_REQUEST_ABORTED
.

MessageId = 0xCF17 ; // NTSTATUS(0xC000CF17)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_PROPERTY_CORRUPT
.

MessageId = 0xCF18 ; // NTSTATUS(0xC000CF18)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_ACCESS_DENIED
.

MessageId = 0xCF19 ; // NTSTATUS(0xC000CF19)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_INCOMPATIBLE_HARDLINKS
.

MessageId = 0xCF1A ; // NTSTATUS(0xC000CF1A)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_PROPERTY_LOCK_CONFLICT
.

MessageId = 0xCF1B ; // NTSTATUS(0xC000CF1B)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_REQUEST_CANCELED
.

MessageId = 0xCF1D ; // NTSTATUS(0xC000CF1D)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_PROVIDER_TERMINATED
.

MessageId = 0xCF1E ; // NTSTATUS(0xC000CF1E)
Severity = Error
Facility = Null
Language = Neutral
STATUS_NOT_A_CLOUD_SYNC_ROOT
.

MessageId = 0xCF1F ; // NTSTATUS(0xC000CF1F)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_REQUEST_TIMEOUT
.

MessageId = 0xCF20 ; // NTSTATUS(0xC000CF20)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_DEHYDRATION_DISALLOWED
.

MessageId = 0xCF21 ; // NTSTATUS(0xC000CF21)
Severity = Error
Facility = Null
Language = Neutral
STATUS_CLOUD_FILE_US_MESSAGE_TIMEOUT
.

MessageId = 0xF500 ; // NTSTATUS(0xC000F500)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_SNAP_IN_PROGRESS
.

MessageId = 0xF501 ; // NTSTATUS(0xC000F501)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_SNAP_USER_SECTION_NOT_SUPPORTED
.

MessageId = 0xF502 ; // NTSTATUS(0xC000F502)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_SNAP_MODIFY_NOT_SUPPORTED
.

MessageId = 0xF503 ; // NTSTATUS(0xC000F503)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_SNAP_IO_NOT_COORDINATED
.

MessageId = 0xF504 ; // NTSTATUS(0xC000F504)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_SNAP_UNEXPECTED_ERROR
.

MessageId = 0xF505 ; // NTSTATUS(0xC000F505)
Severity = Error
Facility = Null
Language = Neutral
STATUS_FILE_SNAP_INVALID_PARAMETER
.

MessageId = 0x0001 ; // NTSTATUS(0xC0010001)
Severity = Error
Facility = Debugger
Language = Neutral
DBG_NO_STATE_CHANGE
.

MessageId = 0x0002 ; // NTSTATUS(0xC0010002)
Severity = Error
Facility = Debugger
Language = Neutral
DBG_APP_NOT_IDLE
.

MessageId = 0x0001 ; // NTSTATUS(0xC0020001)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_STRING_BINDING
.

MessageId = 0x0002 ; // NTSTATUS(0xC0020002)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_WRONG_KIND_OF_BINDING
.

MessageId = 0x0003 ; // NTSTATUS(0xC0020003)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_BINDING
.

MessageId = 0x0004 ; // NTSTATUS(0xC0020004)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_PROTSEQ_NOT_SUPPORTED
.

MessageId = 0x0005 ; // NTSTATUS(0xC0020005)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_RPC_PROTSEQ
.

MessageId = 0x0006 ; // NTSTATUS(0xC0020006)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_STRING_UUID
.

MessageId = 0x0007 ; // NTSTATUS(0xC0020007)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_ENDPOINT_FORMAT
.

MessageId = 0x0008 ; // NTSTATUS(0xC0020008)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_NET_ADDR
.

MessageId = 0x0009 ; // NTSTATUS(0xC0020009)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NO_ENDPOINT_FOUND
.

MessageId = 0x000A ; // NTSTATUS(0xC002000A)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_TIMEOUT
.

MessageId = 0x000B ; // NTSTATUS(0xC002000B)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_OBJECT_NOT_FOUND
.

MessageId = 0x000C ; // NTSTATUS(0xC002000C)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_ALREADY_REGISTERED
.

MessageId = 0x000D ; // NTSTATUS(0xC002000D)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_TYPE_ALREADY_REGISTERED
.

MessageId = 0x000E ; // NTSTATUS(0xC002000E)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_ALREADY_LISTENING
.

MessageId = 0x000F ; // NTSTATUS(0xC002000F)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NO_PROTSEQS_REGISTERED
.

MessageId = 0x0010 ; // NTSTATUS(0xC0020010)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NOT_LISTENING
.

MessageId = 0x0011 ; // NTSTATUS(0xC0020011)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_UNKNOWN_MGR_TYPE
.

MessageId = 0x0012 ; // NTSTATUS(0xC0020012)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_UNKNOWN_IF
.

MessageId = 0x0013 ; // NTSTATUS(0xC0020013)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NO_BINDINGS
.

MessageId = 0x0014 ; // NTSTATUS(0xC0020014)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NO_PROTSEQS
.

MessageId = 0x0015 ; // NTSTATUS(0xC0020015)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_CANT_CREATE_ENDPOINT
.

MessageId = 0x0016 ; // NTSTATUS(0xC0020016)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_OUT_OF_RESOURCES
.

MessageId = 0x0017 ; // NTSTATUS(0xC0020017)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_SERVER_UNAVAILABLE
.

MessageId = 0x0018 ; // NTSTATUS(0xC0020018)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_SERVER_TOO_BUSY
.

MessageId = 0x0019 ; // NTSTATUS(0xC0020019)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_NETWORK_OPTIONS
.

MessageId = 0x001A ; // NTSTATUS(0xC002001A)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NO_CALL_ACTIVE
.

MessageId = 0x001B ; // NTSTATUS(0xC002001B)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_CALL_FAILED
.

MessageId = 0x001C ; // NTSTATUS(0xC002001C)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_CALL_FAILED_DNE
.

MessageId = 0x001D ; // NTSTATUS(0xC002001D)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_PROTOCOL_ERROR
.

MessageId = 0x001F ; // NTSTATUS(0xC002001F)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_UNSUPPORTED_TRANS_SYN
.

MessageId = 0x0021 ; // NTSTATUS(0xC0020021)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_UNSUPPORTED_TYPE
.

MessageId = 0x0022 ; // NTSTATUS(0xC0020022)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_TAG
.

MessageId = 0x0023 ; // NTSTATUS(0xC0020023)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_BOUND
.

MessageId = 0x0024 ; // NTSTATUS(0xC0020024)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NO_ENTRY_NAME
.

MessageId = 0x0025 ; // NTSTATUS(0xC0020025)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_NAME_SYNTAX
.

MessageId = 0x0026 ; // NTSTATUS(0xC0020026)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_UNSUPPORTED_NAME_SYNTAX
.

MessageId = 0x0028 ; // NTSTATUS(0xC0020028)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_UUID_NO_ADDRESS
.

MessageId = 0x0029 ; // NTSTATUS(0xC0020029)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_DUPLICATE_ENDPOINT
.

MessageId = 0x002A ; // NTSTATUS(0xC002002A)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_UNKNOWN_AUTHN_TYPE
.

MessageId = 0x002B ; // NTSTATUS(0xC002002B)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_MAX_CALLS_TOO_SMALL
.

MessageId = 0x002C ; // NTSTATUS(0xC002002C)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_STRING_TOO_LONG
.

MessageId = 0x002D ; // NTSTATUS(0xC002002D)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_PROTSEQ_NOT_FOUND
.

MessageId = 0x002E ; // NTSTATUS(0xC002002E)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_PROCNUM_OUT_OF_RANGE
.

MessageId = 0x002F ; // NTSTATUS(0xC002002F)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_BINDING_HAS_NO_AUTH
.

MessageId = 0x0030 ; // NTSTATUS(0xC0020030)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_UNKNOWN_AUTHN_SERVICE
.

MessageId = 0x0031 ; // NTSTATUS(0xC0020031)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_UNKNOWN_AUTHN_LEVEL
.

MessageId = 0x0032 ; // NTSTATUS(0xC0020032)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_AUTH_IDENTITY
.

MessageId = 0x0033 ; // NTSTATUS(0xC0020033)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_UNKNOWN_AUTHZ_SERVICE
.

MessageId = 0x0034 ; // NTSTATUS(0xC0020034)
Severity = Error
Facility = RpcStubs
Language = Neutral
EPT_NT_INVALID_ENTRY
.

MessageId = 0x0035 ; // NTSTATUS(0xC0020035)
Severity = Error
Facility = RpcStubs
Language = Neutral
EPT_NT_CANT_PERFORM_OP
.

MessageId = 0x0036 ; // NTSTATUS(0xC0020036)
Severity = Error
Facility = RpcStubs
Language = Neutral
EPT_NT_NOT_REGISTERED
.

MessageId = 0x0037 ; // NTSTATUS(0xC0020037)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NOTHING_TO_EXPORT
.

MessageId = 0x0038 ; // NTSTATUS(0xC0020038)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INCOMPLETE_NAME
.

MessageId = 0x0039 ; // NTSTATUS(0xC0020039)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_VERS_OPTION
.

MessageId = 0x003A ; // NTSTATUS(0xC002003A)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NO_MORE_MEMBERS
.

MessageId = 0x003B ; // NTSTATUS(0xC002003B)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NOT_ALL_OBJS_UNEXPORTED
.

MessageId = 0x003C ; // NTSTATUS(0xC002003C)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INTERFACE_NOT_FOUND
.

MessageId = 0x003D ; // NTSTATUS(0xC002003D)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_ENTRY_ALREADY_EXISTS
.

MessageId = 0x003E ; // NTSTATUS(0xC002003E)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_ENTRY_NOT_FOUND
.

MessageId = 0x003F ; // NTSTATUS(0xC002003F)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NAME_SERVICE_UNAVAILABLE
.

MessageId = 0x0040 ; // NTSTATUS(0xC0020040)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_NAF_ID
.

MessageId = 0x0041 ; // NTSTATUS(0xC0020041)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_CANNOT_SUPPORT
.

MessageId = 0x0042 ; // NTSTATUS(0xC0020042)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NO_CONTEXT_AVAILABLE
.

MessageId = 0x0043 ; // NTSTATUS(0xC0020043)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INTERNAL_ERROR
.

MessageId = 0x0044 ; // NTSTATUS(0xC0020044)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_ZERO_DIVIDE
.

MessageId = 0x0045 ; // NTSTATUS(0xC0020045)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_ADDRESS_ERROR
.

MessageId = 0x0046 ; // NTSTATUS(0xC0020046)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_FP_DIV_ZERO
.

MessageId = 0x0047 ; // NTSTATUS(0xC0020047)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_FP_UNDERFLOW
.

MessageId = 0x0048 ; // NTSTATUS(0xC0020048)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_FP_OVERFLOW
.

MessageId = 0x0049 ; // NTSTATUS(0xC0020049)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_CALL_IN_PROGRESS
.

MessageId = 0x004A ; // NTSTATUS(0xC002004A)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NO_MORE_BINDINGS
.

MessageId = 0x004B ; // NTSTATUS(0xC002004B)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_GROUP_MEMBER_NOT_FOUND
.

MessageId = 0x004C ; // NTSTATUS(0xC002004C)
Severity = Error
Facility = RpcStubs
Language = Neutral
EPT_NT_CANT_CREATE
.

MessageId = 0x004D ; // NTSTATUS(0xC002004D)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_OBJECT
.

MessageId = 0x004F ; // NTSTATUS(0xC002004F)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NO_INTERFACES
.

MessageId = 0x0050 ; // NTSTATUS(0xC0020050)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_CALL_CANCELLED
.

MessageId = 0x0051 ; // NTSTATUS(0xC0020051)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_BINDING_INCOMPLETE
.

MessageId = 0x0052 ; // NTSTATUS(0xC0020052)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_COMM_FAILURE
.

MessageId = 0x0053 ; // NTSTATUS(0xC0020053)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_UNSUPPORTED_AUTHN_LEVEL
.

MessageId = 0x0054 ; // NTSTATUS(0xC0020054)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NO_PRINC_NAME
.

MessageId = 0x0055 ; // NTSTATUS(0xC0020055)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NOT_RPC_ERROR
.

MessageId = 0x0057 ; // NTSTATUS(0xC0020057)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_SEC_PKG_ERROR
.

MessageId = 0x0058 ; // NTSTATUS(0xC0020058)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_NOT_CANCELLED
.

MessageId = 0x0062 ; // NTSTATUS(0xC0020062)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_ASYNC_HANDLE
.

MessageId = 0x0063 ; // NTSTATUS(0xC0020063)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_INVALID_ASYNC_CALL
.

MessageId = 0x0064 ; // NTSTATUS(0xC0020064)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_PROXY_ACCESS_DENIED
.

MessageId = 0x0065 ; // NTSTATUS(0xC0020065)
Severity = Error
Facility = RpcStubs
Language = Neutral
RPC_NT_COOKIE_AUTH_FAILED
.

MessageId = 0x0001 ; // NTSTATUS(0xC0030001)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_NO_MORE_ENTRIES
.

MessageId = 0x0002 ; // NTSTATUS(0xC0030002)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_SS_CHAR_TRANS_OPEN_FAIL
.

MessageId = 0x0003 ; // NTSTATUS(0xC0030003)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_SS_CHAR_TRANS_SHORT_FILE
.

MessageId = 0x0004 ; // NTSTATUS(0xC0030004)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_SS_IN_NULL_CONTEXT
.

MessageId = 0x0005 ; // NTSTATUS(0xC0030005)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_SS_CONTEXT_MISMATCH
.

MessageId = 0x0006 ; // NTSTATUS(0xC0030006)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_SS_CONTEXT_DAMAGED
.

MessageId = 0x0007 ; // NTSTATUS(0xC0030007)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_SS_HANDLES_MISMATCH
.

MessageId = 0x0008 ; // NTSTATUS(0xC0030008)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_SS_CANNOT_GET_CALL_HANDLE
.

MessageId = 0x0009 ; // NTSTATUS(0xC0030009)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_NULL_REF_POINTER
.

MessageId = 0x000A ; // NTSTATUS(0xC003000A)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_ENUM_VALUE_OUT_OF_RANGE
.

MessageId = 0x000B ; // NTSTATUS(0xC003000B)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_BYTE_COUNT_TOO_SMALL
.

MessageId = 0x000C ; // NTSTATUS(0xC003000C)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_BAD_STUB_DATA
.

MessageId = 0x0059 ; // NTSTATUS(0xC0030059)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_INVALID_ES_ACTION
.

MessageId = 0x005A ; // NTSTATUS(0xC003005A)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_WRONG_ES_VERSION
.

MessageId = 0x005B ; // NTSTATUS(0xC003005B)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_WRONG_STUB_VERSION
.

MessageId = 0x005C ; // NTSTATUS(0xC003005C)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_INVALID_PIPE_OBJECT
.

MessageId = 0x005D ; // NTSTATUS(0xC003005D)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_INVALID_PIPE_OPERATION
.

MessageId = 0x005E ; // NTSTATUS(0xC003005E)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_WRONG_PIPE_VERSION
.

MessageId = 0x005F ; // NTSTATUS(0xC003005F)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_PIPE_CLOSED
.

MessageId = 0x0060 ; // NTSTATUS(0xC0030060)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_PIPE_DISCIPLINE_ERROR
.

MessageId = 0x0061 ; // NTSTATUS(0xC0030061)
Severity = Error
Facility = RpcRuntime
Language = Neutral
RPC_NT_PIPE_EMPTY
.

MessageId = 0x0001 ; // NTSTATUS(0xC00A0001)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_WINSTATION_NAME_INVALID
.

MessageId = 0x0002 ; // NTSTATUS(0xC00A0002)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_INVALID_PD
.

MessageId = 0x0003 ; // NTSTATUS(0xC00A0003)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_PD_NOT_FOUND
.

MessageId = 0x0006 ; // NTSTATUS(0xC00A0006)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_CLOSE_PENDING
.

MessageId = 0x0007 ; // NTSTATUS(0xC00A0007)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_NO_OUTBUF
.

MessageId = 0x0008 ; // NTSTATUS(0xC00A0008)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_MODEM_INF_NOT_FOUND
.

MessageId = 0x0009 ; // NTSTATUS(0xC00A0009)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_INVALID_MODEMNAME
.

MessageId = 0x000A ; // NTSTATUS(0xC00A000A)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_RESPONSE_ERROR
.

MessageId = 0x000B ; // NTSTATUS(0xC00A000B)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_MODEM_RESPONSE_TIMEOUT
.

MessageId = 0x000C ; // NTSTATUS(0xC00A000C)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_MODEM_RESPONSE_NO_CARRIER
.

MessageId = 0x000D ; // NTSTATUS(0xC00A000D)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_MODEM_RESPONSE_NO_DIALTONE
.

MessageId = 0x000E ; // NTSTATUS(0xC00A000E)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_MODEM_RESPONSE_BUSY
.

MessageId = 0x000F ; // NTSTATUS(0xC00A000F)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_MODEM_RESPONSE_VOICE
.

MessageId = 0x0010 ; // NTSTATUS(0xC00A0010)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_TD_ERROR
.

MessageId = 0x0012 ; // NTSTATUS(0xC00A0012)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_LICENSE_CLIENT_INVALID
.

MessageId = 0x0013 ; // NTSTATUS(0xC00A0013)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_LICENSE_NOT_AVAILABLE
.

MessageId = 0x0014 ; // NTSTATUS(0xC00A0014)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_LICENSE_EXPIRED
.

MessageId = 0x0015 ; // NTSTATUS(0xC00A0015)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_WINSTATION_NOT_FOUND
.

MessageId = 0x0016 ; // NTSTATUS(0xC00A0016)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_WINSTATION_NAME_COLLISION
.

MessageId = 0x0017 ; // NTSTATUS(0xC00A0017)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_WINSTATION_BUSY
.

MessageId = 0x0018 ; // NTSTATUS(0xC00A0018)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_BAD_VIDEO_MODE
.

MessageId = 0x0022 ; // NTSTATUS(0xC00A0022)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_GRAPHICS_INVALID
.

MessageId = 0x0024 ; // NTSTATUS(0xC00A0024)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_NOT_CONSOLE
.

MessageId = 0x0026 ; // NTSTATUS(0xC00A0026)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_CLIENT_QUERY_TIMEOUT
.

MessageId = 0x0027 ; // NTSTATUS(0xC00A0027)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_CONSOLE_DISCONNECT
.

MessageId = 0x0028 ; // NTSTATUS(0xC00A0028)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_CONSOLE_CONNECT
.

MessageId = 0x002A ; // NTSTATUS(0xC00A002A)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_SHADOW_DENIED
.

MessageId = 0x002B ; // NTSTATUS(0xC00A002B)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_WINSTATION_ACCESS_DENIED
.

MessageId = 0x002E ; // NTSTATUS(0xC00A002E)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_INVALID_WD
.

MessageId = 0x002F ; // NTSTATUS(0xC00A002F)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_WD_NOT_FOUND
.

MessageId = 0x0030 ; // NTSTATUS(0xC00A0030)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_SHADOW_INVALID
.

MessageId = 0x0031 ; // NTSTATUS(0xC00A0031)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_SHADOW_DISABLED
.

MessageId = 0x0032 ; // NTSTATUS(0xC00A0032)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_RDP_PROTOCOL_ERROR
.

MessageId = 0x0033 ; // NTSTATUS(0xC00A0033)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_CLIENT_LICENSE_NOT_SET
.

MessageId = 0x0034 ; // NTSTATUS(0xC00A0034)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_CLIENT_LICENSE_IN_USE
.

MessageId = 0x0035 ; // NTSTATUS(0xC00A0035)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_SHADOW_ENDED_BY_MODE_CHANGE
.

MessageId = 0x0036 ; // NTSTATUS(0xC00A0036)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_SHADOW_NOT_RUNNING
.

MessageId = 0x0037 ; // NTSTATUS(0xC00A0037)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_LOGON_DISABLED
.

MessageId = 0x0038 ; // NTSTATUS(0xC00A0038)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_CTX_SECURITY_LAYER_ERROR
.

MessageId = 0x0039 ; // NTSTATUS(0xC00A0039)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_TS_INCOMPATIBLE_SESSIONS
.

MessageId = 0x003A ; // NTSTATUS(0xC00A003A)
Severity = Error
Facility = TerminalServer
Language = Neutral
STATUS_TS_VIDEO_SUBSYSTEM_ERROR
.

MessageId = 0x0001 ; // NTSTATUS(0xC00B0001)
Severity = Error
Facility = MUI
Language = Neutral
STATUS_MUI_FILE_NOT_FOUND
.

MessageId = 0x0002 ; // NTSTATUS(0xC00B0002)
Severity = Error
Facility = MUI
Language = Neutral
STATUS_MUI_INVALID_FILE
.

MessageId = 0x0003 ; // NTSTATUS(0xC00B0003)
Severity = Error
Facility = MUI
Language = Neutral
STATUS_MUI_INVALID_RC_CONFIG
.

MessageId = 0x0004 ; // NTSTATUS(0xC00B0004)
Severity = Error
Facility = MUI
Language = Neutral
STATUS_MUI_INVALID_LOCALE_NAME
.

MessageId = 0x0005 ; // NTSTATUS(0xC00B0005)
Severity = Error
Facility = MUI
Language = Neutral
STATUS_MUI_INVALID_ULTIMATEFALLBACK_NAME
.

MessageId = 0x0006 ; // NTSTATUS(0xC00B0006)
Severity = Error
Facility = MUI
Language = Neutral
STATUS_MUI_FILE_NOT_LOADED
.

MessageId = 0x0007 ; // NTSTATUS(0xC00B0007)
Severity = Error
Facility = MUI
Language = Neutral
STATUS_RESOURCE_ENUM_USER_STOP
.

MessageId = 0xE01D ; // NTSTATUS(0xC00CE01D)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INVALID_DECIMAL
.

MessageId = 0xE01E ; // NTSTATUS(0xC00CE01E)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INVALID_HEXIDECIMAL
.

MessageId = 0xE01F ; // NTSTATUS(0xC00CE01F)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INVALID_UNICODE
.

MessageId = 0xE06E ; // NTSTATUS(0xC00CE06E)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INVALID_ENCODING
.

MessageId = 0xEE01 ; // NTSTATUS(0xC00CEE01)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INPUT_END
.

MessageId = 0xEE02 ; // NTSTATUS(0xC00CEE02)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_ENCODING
.

MessageId = 0xEE03 ; // NTSTATUS(0xC00CEE03)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_ENCODING_SWITCH
.

MessageId = 0xEE04 ; // NTSTATUS(0xC00CEE04)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_ENCODING_SIGNATURE
.

MessageId = 0xEE21 ; // NTSTATUS(0xC00CEE21)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_WHITESPACE
.

MessageId = 0xEE22 ; // NTSTATUS(0xC00CEE22)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_SEMICOLON
.

MessageId = 0xEE23 ; // NTSTATUS(0xC00CEE23)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_GREATER_THAN
.

MessageId = 0xEE24 ; // NTSTATUS(0xC00CEE24)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_QUOTE
.

MessageId = 0xEE25 ; // NTSTATUS(0xC00CEE25)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_EQUAL
.

MessageId = 0xEE26 ; // NTSTATUS(0xC00CEE26)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_LESS_THAN
.

MessageId = 0xEE27 ; // NTSTATUS(0xC00CEE27)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_HEX_DIGIT
.

MessageId = 0xEE28 ; // NTSTATUS(0xC00CEE28)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_DIGIT
.

MessageId = 0xEE29 ; // NTSTATUS(0xC00CEE29)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_LEFT_BRACKET
.

MessageId = 0xEE2A ; // NTSTATUS(0xC00CEE2A)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_LEFT_PAREN
.

MessageId = 0xEE2B ; // NTSTATUS(0xC00CEE2B)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_XML_CHARACTER
.

MessageId = 0xEE2C ; // NTSTATUS(0xC00CEE2C)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_NAME_CHARACTER
.

MessageId = 0xEE2D ; // NTSTATUS(0xC00CEE2D)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_SYNTAX
.

MessageId = 0xEE2E ; // NTSTATUS(0xC00CEE2E)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INCORRECT_CDATA_SECTION
.

MessageId = 0xEE2F ; // NTSTATUS(0xC00CEE2F)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INCORRECT_COMMENT
.

MessageId = 0xEE30 ; // NTSTATUS(0xC00CEE30)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INCORRECT_CONDITIONAL_SECTION
.

MessageId = 0xEE31 ; // NTSTATUS(0xC00CEE31)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INCORRECT_ATTLIST_DECLARATION
.

MessageId = 0xEE32 ; // NTSTATUS(0xC00CEE32)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INCORRECT_DOCTYPE_DECLARATION
.

MessageId = 0xEE33 ; // NTSTATUS(0xC00CEE33)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INCORRECT_ELEMENT_DECLARATION
.

MessageId = 0xEE34 ; // NTSTATUS(0xC00CEE34)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INCORRECT_ENTITY_DECLARATION
.

MessageId = 0xEE35 ; // NTSTATUS(0xC00CEE35)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INCORRECT_NOTATION_DECLARATION
.

MessageId = 0xEE36 ; // NTSTATUS(0xC00CEE36)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_NDATA
.

MessageId = 0xEE37 ; // NTSTATUS(0xC00CEE37)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_PUBLIC
.

MessageId = 0xEE38 ; // NTSTATUS(0xC00CEE38)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_SYSTEM
.

MessageId = 0xEE39 ; // NTSTATUS(0xC00CEE39)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_NAME
.

MessageId = 0xEE3A ; // NTSTATUS(0xC00CEE3A)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_ROOT_ELEMENT
.

MessageId = 0xEE3B ; // NTSTATUS(0xC00CEE3B)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_ELEMENT_MATCH
.

MessageId = 0xEE3C ; // NTSTATUS(0xC00CEE3C)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_UNIQUE_ATTRIBUTE
.

MessageId = 0xEE3D ; // NTSTATUS(0xC00CEE3D)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_TEXTXMLDECL
.

MessageId = 0xEE3E ; // NTSTATUS(0xC00CEE3E)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_LEADING_XML
.

MessageId = 0xEE3F ; // NTSTATUS(0xC00CEE3F)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INCORRECT_TEXT_DECLARATION
.

MessageId = 0xEE40 ; // NTSTATUS(0xC00CEE40)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INCORRECT_XML_DECLARATION
.

MessageId = 0xEE41 ; // NTSTATUS(0xC00CEE41)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INCORRECT_ENCODING_NAME
.

MessageId = 0xEE42 ; // NTSTATUS(0xC00CEE42)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INCORRECT_PUBLIC_ID
.

MessageId = 0xEE43 ; // NTSTATUS(0xC00CEE43)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_PES_INTERNAL_SUBSET
.

MessageId = 0xEE44 ; // NTSTATUS(0xC00CEE44)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_PES_BETWEEN_DECLARATIONS
.

MessageId = 0xEE45 ; // NTSTATUS(0xC00CEE45)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_NO_RECURSION
.

MessageId = 0xEE46 ; // NTSTATUS(0xC00CEE46)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_ENTITY_CONTENT
.

MessageId = 0xEE47 ; // NTSTATUS(0xC00CEE47)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_UNDECLARED_ENTITY
.

MessageId = 0xEE48 ; // NTSTATUS(0xC00CEE48)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_PARSED_ENTITY
.

MessageId = 0xEE49 ; // NTSTATUS(0xC00CEE49)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_NO_EXTERNAL_ENTITY_REF
.

MessageId = 0xEE4A ; // NTSTATUS(0xC00CEE4A)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INCORRECT_PROCESSING_INSTRUCTION
.

MessageId = 0xEE4B ; // NTSTATUS(0xC00CEE4B)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INCORRECT_SYSTEM_ID
.

MessageId = 0xEE4C ; // NTSTATUS(0xC00CEE4C)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EXPECTED_QUESTIONMARK
.

MessageId = 0xEE4D ; // NTSTATUS(0xC00CEE4D)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_CDATA_SECTION_END
.

MessageId = 0xEE4E ; // NTSTATUS(0xC00CEE4E)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_MORE_DATA
.

MessageId = 0xEE4F ; // NTSTATUS(0xC00CEE4F)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_DTD_PROHIBITED
.

MessageId = 0xEE50 ; // NTSTATUS(0xC00CEE50)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INVALID_XML_SPACE_ATTRIBUTE
.

MessageId = 0xEE61 ; // NTSTATUS(0xC00CEE61)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_ILLEGAL_QUALIFIED_NAME_CHARACTER
.

MessageId = 0xEE62 ; // NTSTATUS(0xC00CEE62)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_QUALIFIED_NAME_COLON
.

MessageId = 0xEE63 ; // NTSTATUS(0xC00CEE63)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_NAME_COLON
.

MessageId = 0xEE64 ; // NTSTATUS(0xC00CEE64)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_DECLARED_PREFIX
.

MessageId = 0xEE65 ; // NTSTATUS(0xC00CEE65)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_UNDECLARED_PREFIX
.

MessageId = 0xEE66 ; // NTSTATUS(0xC00CEE66)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_EMPTY_URI
.

MessageId = 0xEE67 ; // NTSTATUS(0xC00CEE67)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_XML_PREFIX_RESERVED
.

MessageId = 0xEE68 ; // NTSTATUS(0xC00CEE68)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_XMLNS_PREFIX_RESERVED
.

MessageId = 0xEE69 ; // NTSTATUS(0xC00CEE69)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_XML_URI_RESERVED
.

MessageId = 0xEE6A ; // NTSTATUS(0xC00CEE6A)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_XMLNS_URI_RESERVED
.

MessageId = 0xEE81 ; // NTSTATUS(0xC00CEE81)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_MAX_ELEMENT_DEPTH
.

MessageId = 0xEE82 ; // NTSTATUS(0xC00CEE82)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_MAX_ENTITY_EXPANSION
.

MessageId = 0xEF01 ; // NTSTATUS(0xC00CEF01)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_NON_WHITESPACE
.

MessageId = 0xEF02 ; // NTSTATUS(0xC00CEF02)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_NS_PREFIX_DECLARED
.

MessageId = 0xEF03 ; // NTSTATUS(0xC00CEF03)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_NS_PREFIX_WITH_EMPTY_NS_URI
.

MessageId = 0xEF04 ; // NTSTATUS(0xC00CEF04)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_DUPLICATE_ATTRIBUTE
.

MessageId = 0xEF05 ; // NTSTATUS(0xC00CEF05)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_XMLNS_PREFIX_DECLARATION
.

MessageId = 0xEF06 ; // NTSTATUS(0xC00CEF06)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_XML_PREFIX_DECLARATION
.

MessageId = 0xEF07 ; // NTSTATUS(0xC00CEF07)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_XML_URI_DECLARATION
.

MessageId = 0xEF08 ; // NTSTATUS(0xC00CEF08)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_XMLNS_URI_DECLARATION
.

MessageId = 0xEF09 ; // NTSTATUS(0xC00CEF09)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_NAMESPACE_UNDECLARED
.

MessageId = 0xEF0A ; // NTSTATUS(0xC00CEF0A)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INVALID_XML_SPACE
.

MessageId = 0xEF0B ; // NTSTATUS(0xC00CEF0B)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INVALID_ACTION
.

MessageId = 0xEF0C ; // NTSTATUS(0xC00CEF0C)
Severity = Error
Facility = XmlLite
Language = Neutral
STATUS_XMLLITE_INVALID_SURROGATE_PAIR
.

MessageId = 0x0001 ; // NTSTATUS(0xC0150001)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_SECTION_NOT_FOUND
.

MessageId = 0x0002 ; // NTSTATUS(0xC0150002)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_CANT_GEN_ACTCTX
.

MessageId = 0x0003 ; // NTSTATUS(0xC0150003)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_INVALID_ACTCTXDATA_FORMAT
.

MessageId = 0x0004 ; // NTSTATUS(0xC0150004)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_ASSEMBLY_NOT_FOUND
.

MessageId = 0x0005 ; // NTSTATUS(0xC0150005)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_MANIFEST_FORMAT_ERROR
.

MessageId = 0x0006 ; // NTSTATUS(0xC0150006)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_MANIFEST_PARSE_ERROR
.

MessageId = 0x0007 ; // NTSTATUS(0xC0150007)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_ACTIVATION_CONTEXT_DISABLED
.

MessageId = 0x0008 ; // NTSTATUS(0xC0150008)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_KEY_NOT_FOUND
.

MessageId = 0x0009 ; // NTSTATUS(0xC0150009)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_VERSION_CONFLICT
.

MessageId = 0x000A ; // NTSTATUS(0xC015000A)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_WRONG_SECTION_TYPE
.

MessageId = 0x000B ; // NTSTATUS(0xC015000B)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_THREAD_QUERIES_DISABLED
.

MessageId = 0x000C ; // NTSTATUS(0xC015000C)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_ASSEMBLY_MISSING
.

MessageId = 0x000E ; // NTSTATUS(0xC015000E)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_PROCESS_DEFAULT_ALREADY_SET
.

MessageId = 0x000F ; // NTSTATUS(0xC015000F)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_EARLY_DEACTIVATION
.

MessageId = 0x0010 ; // NTSTATUS(0xC0150010)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_INVALID_DEACTIVATION
.

MessageId = 0x0011 ; // NTSTATUS(0xC0150011)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_MULTIPLE_DEACTIVATION
.

MessageId = 0x0012 ; // NTSTATUS(0xC0150012)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_SYSTEM_DEFAULT_ACTIVATION_CONTEXT_EMPTY
.

MessageId = 0x0013 ; // NTSTATUS(0xC0150013)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_PROCESS_TERMINATION_REQUESTED
.

MessageId = 0x0014 ; // NTSTATUS(0xC0150014)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_CORRUPT_ACTIVATION_STACK
.

MessageId = 0x0015 ; // NTSTATUS(0xC0150015)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_CORRUPTION
.

MessageId = 0x0016 ; // NTSTATUS(0xC0150016)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_INVALID_IDENTITY_ATTRIBUTE_VALUE
.

MessageId = 0x0017 ; // NTSTATUS(0xC0150017)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_INVALID_IDENTITY_ATTRIBUTE_NAME
.

MessageId = 0x0018 ; // NTSTATUS(0xC0150018)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_IDENTITY_DUPLICATE_ATTRIBUTE
.

MessageId = 0x0019 ; // NTSTATUS(0xC0150019)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_IDENTITY_PARSE_ERROR
.

MessageId = 0x001A ; // NTSTATUS(0xC015001A)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_COMPONENT_STORE_CORRUPT
.

MessageId = 0x001B ; // NTSTATUS(0xC015001B)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_FILE_HASH_MISMATCH
.

MessageId = 0x001C ; // NTSTATUS(0xC015001C)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_MANIFEST_IDENTITY_SAME_BUT_CONTENTS_DIFFERENT
.

MessageId = 0x001D ; // NTSTATUS(0xC015001D)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_IDENTITIES_DIFFERENT
.

MessageId = 0x001E ; // NTSTATUS(0xC015001E)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_ASSEMBLY_IS_NOT_A_DEPLOYMENT
.

MessageId = 0x001F ; // NTSTATUS(0xC015001F)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_FILE_NOT_PART_OF_ASSEMBLY
.

MessageId = 0x0020 ; // NTSTATUS(0xC0150020)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_ADVANCED_INSTALLER_FAILED
.

MessageId = 0x0021 ; // NTSTATUS(0xC0150021)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_XML_ENCODING_MISMATCH
.

MessageId = 0x0022 ; // NTSTATUS(0xC0150022)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_MANIFEST_TOO_BIG
.

MessageId = 0x0023 ; // NTSTATUS(0xC0150023)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_SETTING_NOT_REGISTERED
.

MessageId = 0x0024 ; // NTSTATUS(0xC0150024)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_TRANSACTION_CLOSURE_INCOMPLETE
.

MessageId = 0x0025 ; // NTSTATUS(0xC0150025)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SMI_PRIMITIVE_INSTALLER_FAILED
.

MessageId = 0x0026 ; // NTSTATUS(0xC0150026)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_GENERIC_COMMAND_FAILED
.

MessageId = 0x0027 ; // NTSTATUS(0xC0150027)
Severity = Error
Facility = SxS
Language = Neutral
STATUS_SXS_FILE_HASH_MISSING
.

MessageId = 0x0001 ; // NTSTATUS(0xC0190001)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTIONAL_CONFLICT
.

MessageId = 0x0002 ; // NTSTATUS(0xC0190002)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_INVALID_TRANSACTION
.

MessageId = 0x0003 ; // NTSTATUS(0xC0190003)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_NOT_ACTIVE
.

MessageId = 0x0004 ; // NTSTATUS(0xC0190004)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TM_INITIALIZATION_FAILED
.

MessageId = 0x0005 ; // NTSTATUS(0xC0190005)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_RM_NOT_ACTIVE
.

MessageId = 0x0006 ; // NTSTATUS(0xC0190006)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_RM_METADATA_CORRUPT
.

MessageId = 0x0007 ; // NTSTATUS(0xC0190007)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_NOT_JOINED
.

MessageId = 0x0008 ; // NTSTATUS(0xC0190008)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_DIRECTORY_NOT_RM
.

MessageId = 0x000A ; // NTSTATUS(0xC019000A)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTIONS_UNSUPPORTED_REMOTE
.

MessageId = 0x000B ; // NTSTATUS(0xC019000B)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_LOG_RESIZE_INVALID_SIZE
.

MessageId = 0x000C ; // NTSTATUS(0xC019000C)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_REMOTE_FILE_VERSION_MISMATCH
.

MessageId = 0x000F ; // NTSTATUS(0xC019000F)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_CRM_PROTOCOL_ALREADY_EXISTS
.

MessageId = 0x0010 ; // NTSTATUS(0xC0190010)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_PROPAGATION_FAILED
.

MessageId = 0x0011 ; // NTSTATUS(0xC0190011)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_CRM_PROTOCOL_NOT_FOUND
.

MessageId = 0x0012 ; // NTSTATUS(0xC0190012)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_SUPERIOR_EXISTS
.

MessageId = 0x0013 ; // NTSTATUS(0xC0190013)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_REQUEST_NOT_VALID
.

MessageId = 0x0014 ; // NTSTATUS(0xC0190014)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_NOT_REQUESTED
.

MessageId = 0x0015 ; // NTSTATUS(0xC0190015)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_ALREADY_ABORTED
.

MessageId = 0x0016 ; // NTSTATUS(0xC0190016)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_ALREADY_COMMITTED
.

MessageId = 0x0017 ; // NTSTATUS(0xC0190017)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_INVALID_MARSHALL_BUFFER
.

MessageId = 0x0018 ; // NTSTATUS(0xC0190018)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_CURRENT_TRANSACTION_NOT_VALID
.

MessageId = 0x0019 ; // NTSTATUS(0xC0190019)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_LOG_GROWTH_FAILED
.

MessageId = 0x0021 ; // NTSTATUS(0xC0190021)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_OBJECT_NO_LONGER_EXISTS
.

MessageId = 0x0022 ; // NTSTATUS(0xC0190022)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_STREAM_MINIVERSION_NOT_FOUND
.

MessageId = 0x0023 ; // NTSTATUS(0xC0190023)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_STREAM_MINIVERSION_NOT_VALID
.

MessageId = 0x0024 ; // NTSTATUS(0xC0190024)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_MINIVERSION_INACCESSIBLE_FROM_SPECIFIED_TRANSACTION
.

MessageId = 0x0025 ; // NTSTATUS(0xC0190025)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_CANT_OPEN_MINIVERSION_WITH_MODIFY_INTENT
.

MessageId = 0x0026 ; // NTSTATUS(0xC0190026)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_CANT_CREATE_MORE_STREAM_MINIVERSIONS
.

MessageId = 0x0028 ; // NTSTATUS(0xC0190028)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_HANDLE_NO_LONGER_VALID
.

MessageId = 0x0030 ; // NTSTATUS(0xC0190030)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_LOG_CORRUPTION_DETECTED
.

MessageId = 0x0032 ; // NTSTATUS(0xC0190032)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_RM_DISCONNECTED
.

MessageId = 0x0033 ; // NTSTATUS(0xC0190033)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_ENLISTMENT_NOT_SUPERIOR
.

MessageId = 0x0036 ; // NTSTATUS(0xC0190036)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_FILE_IDENTITY_NOT_PERSISTENT
.

MessageId = 0x0037 ; // NTSTATUS(0xC0190037)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_CANT_BREAK_TRANSACTIONAL_DEPENDENCY
.

MessageId = 0x0038 ; // NTSTATUS(0xC0190038)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_CANT_CROSS_RM_BOUNDARY
.

MessageId = 0x0039 ; // NTSTATUS(0xC0190039)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TXF_DIR_NOT_EMPTY
.

MessageId = 0x003A ; // NTSTATUS(0xC019003A)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_INDOUBT_TRANSACTIONS_EXIST
.

MessageId = 0x003B ; // NTSTATUS(0xC019003B)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TM_VOLATILE
.

MessageId = 0x003C ; // NTSTATUS(0xC019003C)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_ROLLBACK_TIMER_EXPIRED
.

MessageId = 0x003D ; // NTSTATUS(0xC019003D)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TXF_ATTRIBUTE_CORRUPT
.

MessageId = 0x003E ; // NTSTATUS(0xC019003E)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_EFS_NOT_ALLOWED_IN_TRANSACTION
.

MessageId = 0x003F ; // NTSTATUS(0xC019003F)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTIONAL_OPEN_NOT_ALLOWED
.

MessageId = 0x0040 ; // NTSTATUS(0xC0190040)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTED_MAPPING_UNSUPPORTED_REMOTE
.

MessageId = 0x0043 ; // NTSTATUS(0xC0190043)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_REQUIRED_PROMOTION
.

MessageId = 0x0044 ; // NTSTATUS(0xC0190044)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_CANNOT_EXECUTE_FILE_IN_TRANSACTION
.

MessageId = 0x0045 ; // NTSTATUS(0xC0190045)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTIONS_NOT_FROZEN
.

MessageId = 0x0046 ; // NTSTATUS(0xC0190046)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_FREEZE_IN_PROGRESS
.

MessageId = 0x0047 ; // NTSTATUS(0xC0190047)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_NOT_SNAPSHOT_VOLUME
.

MessageId = 0x0048 ; // NTSTATUS(0xC0190048)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_NO_SAVEPOINT_WITH_OPEN_FILES
.

MessageId = 0x0049 ; // NTSTATUS(0xC0190049)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_SPARSE_NOT_ALLOWED_IN_TRANSACTION
.

MessageId = 0x004A ; // NTSTATUS(0xC019004A)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TM_IDENTITY_MISMATCH
.

MessageId = 0x004B ; // NTSTATUS(0xC019004B)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_FLOATED_SECTION
.

MessageId = 0x004C ; // NTSTATUS(0xC019004C)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_CANNOT_ACCEPT_TRANSACTED_WORK
.

MessageId = 0x004D ; // NTSTATUS(0xC019004D)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_CANNOT_ABORT_TRANSACTIONS
.

MessageId = 0x004E ; // NTSTATUS(0xC019004E)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_NOT_FOUND
.

MessageId = 0x004F ; // NTSTATUS(0xC019004F)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_RESOURCEMANAGER_NOT_FOUND
.

MessageId = 0x0050 ; // NTSTATUS(0xC0190050)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_ENLISTMENT_NOT_FOUND
.

MessageId = 0x0051 ; // NTSTATUS(0xC0190051)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTIONMANAGER_NOT_FOUND
.

MessageId = 0x0052 ; // NTSTATUS(0xC0190052)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTIONMANAGER_NOT_ONLINE
.

MessageId = 0x0053 ; // NTSTATUS(0xC0190053)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTIONMANAGER_RECOVERY_NAME_COLLISION
.

MessageId = 0x0054 ; // NTSTATUS(0xC0190054)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_NOT_ROOT
.

MessageId = 0x0055 ; // NTSTATUS(0xC0190055)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_OBJECT_EXPIRED
.

MessageId = 0x0056 ; // NTSTATUS(0xC0190056)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_COMPRESSION_NOT_ALLOWED_IN_TRANSACTION
.

MessageId = 0x0057 ; // NTSTATUS(0xC0190057)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_RESPONSE_NOT_ENLISTED
.

MessageId = 0x0058 ; // NTSTATUS(0xC0190058)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_RECORD_TOO_LONG
.

MessageId = 0x0059 ; // NTSTATUS(0xC0190059)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_NO_LINK_TRACKING_IN_TRANSACTION
.

MessageId = 0x005A ; // NTSTATUS(0xC019005A)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_OPERATION_NOT_SUPPORTED_IN_TRANSACTION
.

MessageId = 0x005B ; // NTSTATUS(0xC019005B)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_INTEGRITY_VIOLATED
.

MessageId = 0x005C ; // NTSTATUS(0xC019005C)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTIONMANAGER_IDENTITY_MISMATCH
.

MessageId = 0x005D ; // NTSTATUS(0xC019005D)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_RM_CANNOT_BE_FROZEN_FOR_SNAPSHOT
.

MessageId = 0x005E ; // NTSTATUS(0xC019005E)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_MUST_WRITETHROUGH
.

MessageId = 0x005F ; // NTSTATUS(0xC019005F)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_NO_SUPERIOR
.

MessageId = 0x0060 ; // NTSTATUS(0xC0190060)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_EXPIRED_HANDLE
.

MessageId = 0x0061 ; // NTSTATUS(0xC0190061)
Severity = Error
Facility = Transaction
Language = Neutral
STATUS_TRANSACTION_NOT_ENLISTED
.

MessageId = 0x0001 ; // NTSTATUS(0xC01A0001)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_SECTOR_INVALID
.

MessageId = 0x0002 ; // NTSTATUS(0xC01A0002)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_SECTOR_PARITY_INVALID
.

MessageId = 0x0003 ; // NTSTATUS(0xC01A0003)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_SECTOR_REMAPPED
.

MessageId = 0x0004 ; // NTSTATUS(0xC01A0004)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_BLOCK_INCOMPLETE
.

MessageId = 0x0005 ; // NTSTATUS(0xC01A0005)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_INVALID_RANGE
.

MessageId = 0x0006 ; // NTSTATUS(0xC01A0006)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_BLOCKS_EXHAUSTED
.

MessageId = 0x0007 ; // NTSTATUS(0xC01A0007)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_READ_CONTEXT_INVALID
.

MessageId = 0x0008 ; // NTSTATUS(0xC01A0008)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_RESTART_INVALID
.

MessageId = 0x0009 ; // NTSTATUS(0xC01A0009)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_BLOCK_VERSION
.

MessageId = 0x000A ; // NTSTATUS(0xC01A000A)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_BLOCK_INVALID
.

MessageId = 0x000B ; // NTSTATUS(0xC01A000B)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_READ_MODE_INVALID
.

MessageId = 0x000D ; // NTSTATUS(0xC01A000D)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_METADATA_CORRUPT
.

MessageId = 0x000E ; // NTSTATUS(0xC01A000E)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_METADATA_INVALID
.

MessageId = 0x000F ; // NTSTATUS(0xC01A000F)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_METADATA_INCONSISTENT
.

MessageId = 0x0010 ; // NTSTATUS(0xC01A0010)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_RESERVATION_INVALID
.

MessageId = 0x0011 ; // NTSTATUS(0xC01A0011)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_CANT_DELETE
.

MessageId = 0x0012 ; // NTSTATUS(0xC01A0012)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_CONTAINER_LIMIT_EXCEEDED
.

MessageId = 0x0013 ; // NTSTATUS(0xC01A0013)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_START_OF_LOG
.

MessageId = 0x0014 ; // NTSTATUS(0xC01A0014)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_POLICY_ALREADY_INSTALLED
.

MessageId = 0x0015 ; // NTSTATUS(0xC01A0015)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_POLICY_NOT_INSTALLED
.

MessageId = 0x0016 ; // NTSTATUS(0xC01A0016)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_POLICY_INVALID
.

MessageId = 0x0017 ; // NTSTATUS(0xC01A0017)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_POLICY_CONFLICT
.

MessageId = 0x0018 ; // NTSTATUS(0xC01A0018)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_PINNED_ARCHIVE_TAIL
.

MessageId = 0x0019 ; // NTSTATUS(0xC01A0019)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_RECORD_NONEXISTENT
.

MessageId = 0x001A ; // NTSTATUS(0xC01A001A)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_RECORDS_RESERVED_INVALID
.

MessageId = 0x001B ; // NTSTATUS(0xC01A001B)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_SPACE_RESERVED_INVALID
.

MessageId = 0x001C ; // NTSTATUS(0xC01A001C)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_TAIL_INVALID
.

MessageId = 0x001D ; // NTSTATUS(0xC01A001D)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_FULL
.

MessageId = 0x001E ; // NTSTATUS(0xC01A001E)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_MULTIPLEXED
.

MessageId = 0x001F ; // NTSTATUS(0xC01A001F)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_DEDICATED
.

MessageId = 0x0020 ; // NTSTATUS(0xC01A0020)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_ARCHIVE_NOT_IN_PROGRESS
.

MessageId = 0x0021 ; // NTSTATUS(0xC01A0021)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_ARCHIVE_IN_PROGRESS
.

MessageId = 0x0022 ; // NTSTATUS(0xC01A0022)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_EPHEMERAL
.

MessageId = 0x0023 ; // NTSTATUS(0xC01A0023)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_NOT_ENOUGH_CONTAINERS
.

MessageId = 0x0024 ; // NTSTATUS(0xC01A0024)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_CLIENT_ALREADY_REGISTERED
.

MessageId = 0x0025 ; // NTSTATUS(0xC01A0025)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_CLIENT_NOT_REGISTERED
.

MessageId = 0x0026 ; // NTSTATUS(0xC01A0026)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_FULL_HANDLER_IN_PROGRESS
.

MessageId = 0x0027 ; // NTSTATUS(0xC01A0027)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_CONTAINER_READ_FAILED
.

MessageId = 0x0028 ; // NTSTATUS(0xC01A0028)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_CONTAINER_WRITE_FAILED
.

MessageId = 0x0029 ; // NTSTATUS(0xC01A0029)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_CONTAINER_OPEN_FAILED
.

MessageId = 0x002A ; // NTSTATUS(0xC01A002A)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_CONTAINER_STATE_INVALID
.

MessageId = 0x002B ; // NTSTATUS(0xC01A002B)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_STATE_INVALID
.

MessageId = 0x002C ; // NTSTATUS(0xC01A002C)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_PINNED
.

MessageId = 0x002D ; // NTSTATUS(0xC01A002D)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_METADATA_FLUSH_FAILED
.

MessageId = 0x002E ; // NTSTATUS(0xC01A002E)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_INCONSISTENT_SECURITY
.

MessageId = 0x002F ; // NTSTATUS(0xC01A002F)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_APPENDED_FLUSH_FAILED
.

MessageId = 0x0030 ; // NTSTATUS(0xC01A0030)
Severity = Error
Facility = Log
Language = Neutral
STATUS_LOG_PINNED_RESERVATION
.

MessageId = 0x0001 ; // NTSTATUS(0xC0380001)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DATABASE_FULL
.

MessageId = 0x0002 ; // NTSTATUS(0xC0380002)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_CONFIGURATION_CORRUPTED
.

MessageId = 0x0003 ; // NTSTATUS(0xC0380003)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_CONFIGURATION_NOT_IN_SYNC
.

MessageId = 0x0004 ; // NTSTATUS(0xC0380004)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PACK_CONFIG_UPDATE_FAILED
.

MessageId = 0x0005 ; // NTSTATUS(0xC0380005)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_CONTAINS_NON_SIMPLE_VOLUME
.

MessageId = 0x0006 ; // NTSTATUS(0xC0380006)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_DUPLICATE
.

MessageId = 0x0007 ; // NTSTATUS(0xC0380007)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_DYNAMIC
.

MessageId = 0x0008 ; // NTSTATUS(0xC0380008)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_ID_INVALID
.

MessageId = 0x0009 ; // NTSTATUS(0xC0380009)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_INVALID
.

MessageId = 0x000A ; // NTSTATUS(0xC038000A)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_LAST_VOTER
.

MessageId = 0x000B ; // NTSTATUS(0xC038000B)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_LAYOUT_INVALID
.

MessageId = 0x000C ; // NTSTATUS(0xC038000C)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_LAYOUT_NON_BASIC_BETWEEN_BASIC_PARTITIONS
.

MessageId = 0x000D ; // NTSTATUS(0xC038000D)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_LAYOUT_NOT_CYLINDER_ALIGNED
.

MessageId = 0x000E ; // NTSTATUS(0xC038000E)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_LAYOUT_PARTITIONS_TOO_SMALL
.

MessageId = 0x000F ; // NTSTATUS(0xC038000F)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_LAYOUT_PRIMARY_BETWEEN_LOGICAL_PARTITIONS
.

MessageId = 0x0010 ; // NTSTATUS(0xC0380010)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_LAYOUT_TOO_MANY_PARTITIONS
.

MessageId = 0x0011 ; // NTSTATUS(0xC0380011)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_MISSING
.

MessageId = 0x0012 ; // NTSTATUS(0xC0380012)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_NOT_EMPTY
.

MessageId = 0x0013 ; // NTSTATUS(0xC0380013)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_NOT_ENOUGH_SPACE
.

MessageId = 0x0014 ; // NTSTATUS(0xC0380014)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_REVECTORING_FAILED
.

MessageId = 0x0015 ; // NTSTATUS(0xC0380015)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_SECTOR_SIZE_INVALID
.

MessageId = 0x0016 ; // NTSTATUS(0xC0380016)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_SET_NOT_CONTAINED
.

MessageId = 0x0017 ; // NTSTATUS(0xC0380017)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_USED_BY_MULTIPLE_MEMBERS
.

MessageId = 0x0018 ; // NTSTATUS(0xC0380018)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DISK_USED_BY_MULTIPLE_PLEXES
.

MessageId = 0x0019 ; // NTSTATUS(0xC0380019)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DYNAMIC_DISK_NOT_SUPPORTED
.

MessageId = 0x001A ; // NTSTATUS(0xC038001A)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_EXTENT_ALREADY_USED
.

MessageId = 0x001B ; // NTSTATUS(0xC038001B)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_EXTENT_NOT_CONTIGUOUS
.

MessageId = 0x001C ; // NTSTATUS(0xC038001C)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_EXTENT_NOT_IN_PUBLIC_REGION
.

MessageId = 0x001D ; // NTSTATUS(0xC038001D)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_EXTENT_NOT_SECTOR_ALIGNED
.

MessageId = 0x001E ; // NTSTATUS(0xC038001E)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_EXTENT_OVERLAPS_EBR_PARTITION
.

MessageId = 0x001F ; // NTSTATUS(0xC038001F)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_EXTENT_VOLUME_LENGTHS_DO_NOT_MATCH
.

MessageId = 0x0020 ; // NTSTATUS(0xC0380020)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_FAULT_TOLERANT_NOT_SUPPORTED
.

MessageId = 0x0021 ; // NTSTATUS(0xC0380021)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_INTERLEAVE_LENGTH_INVALID
.

MessageId = 0x0022 ; // NTSTATUS(0xC0380022)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_MAXIMUM_REGISTERED_USERS
.

MessageId = 0x0023 ; // NTSTATUS(0xC0380023)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_MEMBER_IN_SYNC
.

MessageId = 0x0024 ; // NTSTATUS(0xC0380024)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_MEMBER_INDEX_DUPLICATE
.

MessageId = 0x0025 ; // NTSTATUS(0xC0380025)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_MEMBER_INDEX_INVALID
.

MessageId = 0x0026 ; // NTSTATUS(0xC0380026)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_MEMBER_MISSING
.

MessageId = 0x0027 ; // NTSTATUS(0xC0380027)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_MEMBER_NOT_DETACHED
.

MessageId = 0x0028 ; // NTSTATUS(0xC0380028)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_MEMBER_REGENERATING
.

MessageId = 0x0029 ; // NTSTATUS(0xC0380029)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_ALL_DISKS_FAILED
.

MessageId = 0x002A ; // NTSTATUS(0xC038002A)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_NO_REGISTERED_USERS
.

MessageId = 0x002B ; // NTSTATUS(0xC038002B)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_NO_SUCH_USER
.

MessageId = 0x002C ; // NTSTATUS(0xC038002C)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_NOTIFICATION_RESET
.

MessageId = 0x002D ; // NTSTATUS(0xC038002D)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_NUMBER_OF_MEMBERS_INVALID
.

MessageId = 0x002E ; // NTSTATUS(0xC038002E)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_NUMBER_OF_PLEXES_INVALID
.

MessageId = 0x002F ; // NTSTATUS(0xC038002F)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PACK_DUPLICATE
.

MessageId = 0x0030 ; // NTSTATUS(0xC0380030)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PACK_ID_INVALID
.

MessageId = 0x0031 ; // NTSTATUS(0xC0380031)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PACK_INVALID
.

MessageId = 0x0032 ; // NTSTATUS(0xC0380032)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PACK_NAME_INVALID
.

MessageId = 0x0033 ; // NTSTATUS(0xC0380033)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PACK_OFFLINE
.

MessageId = 0x0034 ; // NTSTATUS(0xC0380034)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PACK_HAS_QUORUM
.

MessageId = 0x0035 ; // NTSTATUS(0xC0380035)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PACK_WITHOUT_QUORUM
.

MessageId = 0x0036 ; // NTSTATUS(0xC0380036)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PARTITION_STYLE_INVALID
.

MessageId = 0x0037 ; // NTSTATUS(0xC0380037)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PARTITION_UPDATE_FAILED
.

MessageId = 0x0038 ; // NTSTATUS(0xC0380038)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PLEX_IN_SYNC
.

MessageId = 0x0039 ; // NTSTATUS(0xC0380039)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PLEX_INDEX_DUPLICATE
.

MessageId = 0x003A ; // NTSTATUS(0xC038003A)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PLEX_INDEX_INVALID
.

MessageId = 0x003B ; // NTSTATUS(0xC038003B)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PLEX_LAST_ACTIVE
.

MessageId = 0x003C ; // NTSTATUS(0xC038003C)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PLEX_MISSING
.

MessageId = 0x003D ; // NTSTATUS(0xC038003D)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PLEX_REGENERATING
.

MessageId = 0x003E ; // NTSTATUS(0xC038003E)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PLEX_TYPE_INVALID
.

MessageId = 0x003F ; // NTSTATUS(0xC038003F)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PLEX_NOT_RAID5
.

MessageId = 0x0040 ; // NTSTATUS(0xC0380040)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PLEX_NOT_SIMPLE
.

MessageId = 0x0041 ; // NTSTATUS(0xC0380041)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_STRUCTURE_SIZE_INVALID
.

MessageId = 0x0042 ; // NTSTATUS(0xC0380042)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_TOO_MANY_NOTIFICATION_REQUESTS
.

MessageId = 0x0043 ; // NTSTATUS(0xC0380043)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_TRANSACTION_IN_PROGRESS
.

MessageId = 0x0044 ; // NTSTATUS(0xC0380044)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_UNEXPECTED_DISK_LAYOUT_CHANGE
.

MessageId = 0x0045 ; // NTSTATUS(0xC0380045)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_VOLUME_CONTAINS_MISSING_DISK
.

MessageId = 0x0046 ; // NTSTATUS(0xC0380046)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_VOLUME_ID_INVALID
.

MessageId = 0x0047 ; // NTSTATUS(0xC0380047)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_VOLUME_LENGTH_INVALID
.

MessageId = 0x0048 ; // NTSTATUS(0xC0380048)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_VOLUME_LENGTH_NOT_SECTOR_SIZE_MULTIPLE
.

MessageId = 0x0049 ; // NTSTATUS(0xC0380049)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_VOLUME_NOT_MIRRORED
.

MessageId = 0x004A ; // NTSTATUS(0xC038004A)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_VOLUME_NOT_RETAINED
.

MessageId = 0x004B ; // NTSTATUS(0xC038004B)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_VOLUME_OFFLINE
.

MessageId = 0x004C ; // NTSTATUS(0xC038004C)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_VOLUME_RETAINED
.

MessageId = 0x004D ; // NTSTATUS(0xC038004D)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_NUMBER_OF_EXTENTS_INVALID
.

MessageId = 0x004E ; // NTSTATUS(0xC038004E)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_DIFFERENT_SECTOR_SIZE
.

MessageId = 0x004F ; // NTSTATUS(0xC038004F)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_BAD_BOOT_DISK
.

MessageId = 0x0050 ; // NTSTATUS(0xC0380050)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PACK_CONFIG_OFFLINE
.

MessageId = 0x0051 ; // NTSTATUS(0xC0380051)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PACK_CONFIG_ONLINE
.

MessageId = 0x0052 ; // NTSTATUS(0xC0380052)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_NOT_PRIMARY_PACK
.

MessageId = 0x0053 ; // NTSTATUS(0xC0380053)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PACK_LOG_UPDATE_FAILED
.

MessageId = 0x0054 ; // NTSTATUS(0xC0380054)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_NUMBER_OF_DISKS_IN_PLEX_INVALID
.

MessageId = 0x0055 ; // NTSTATUS(0xC0380055)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_NUMBER_OF_DISKS_IN_MEMBER_INVALID
.

MessageId = 0x0056 ; // NTSTATUS(0xC0380056)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_VOLUME_MIRRORED
.

MessageId = 0x0057 ; // NTSTATUS(0xC0380057)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PLEX_NOT_SIMPLE_SPANNED
.

MessageId = 0x0058 ; // NTSTATUS(0xC0380058)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_NO_VALID_LOG_COPIES
.

MessageId = 0x0059 ; // NTSTATUS(0xC0380059)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_PRIMARY_PACK_PRESENT
.

MessageId = 0x005A ; // NTSTATUS(0xC038005A)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_NUMBER_OF_DISKS_INVALID
.

MessageId = 0x005B ; // NTSTATUS(0xC038005B)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_MIRROR_NOT_SUPPORTED
.

MessageId = 0x005C ; // NTSTATUS(0xC038005C)
Severity = Error
Facility = VolMgr
Language = Neutral
STATUS_VOLMGR_RAID5_NOT_SUPPORTED
.

MessageId = 0x0002 ; // NTSTATUS(0xC0390002)
Severity = Error
Facility = BCD
Language = Neutral
STATUS_BCD_TOO_MANY_ELEMENTS
.

MessageId = 0x0001 ; // NTSTATUS(0xC03A0001)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_DRIVE_FOOTER_MISSING
.

MessageId = 0x0002 ; // NTSTATUS(0xC03A0002)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_DRIVE_FOOTER_CHECKSUM_MISMATCH
.

MessageId = 0x0003 ; // NTSTATUS(0xC03A0003)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_DRIVE_FOOTER_CORRUPT
.

MessageId = 0x0004 ; // NTSTATUS(0xC03A0004)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_FORMAT_UNKNOWN
.

MessageId = 0x0005 ; // NTSTATUS(0xC03A0005)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_FORMAT_UNSUPPORTED_VERSION
.

MessageId = 0x0006 ; // NTSTATUS(0xC03A0006)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_SPARSE_HEADER_CHECKSUM_MISMATCH
.

MessageId = 0x0007 ; // NTSTATUS(0xC03A0007)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_SPARSE_HEADER_UNSUPPORTED_VERSION
.

MessageId = 0x0008 ; // NTSTATUS(0xC03A0008)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_SPARSE_HEADER_CORRUPT
.

MessageId = 0x0009 ; // NTSTATUS(0xC03A0009)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_BLOCK_ALLOCATION_FAILURE
.

MessageId = 0x000A ; // NTSTATUS(0xC03A000A)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_BLOCK_ALLOCATION_TABLE_CORRUPT
.

MessageId = 0x000B ; // NTSTATUS(0xC03A000B)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_INVALID_BLOCK_SIZE
.

MessageId = 0x000C ; // NTSTATUS(0xC03A000C)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_BITMAP_MISMATCH
.

MessageId = 0x000D ; // NTSTATUS(0xC03A000D)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_PARENT_VHD_NOT_FOUND
.

MessageId = 0x000E ; // NTSTATUS(0xC03A000E)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_CHILD_PARENT_ID_MISMATCH
.

MessageId = 0x000F ; // NTSTATUS(0xC03A000F)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_CHILD_PARENT_TIMESTAMP_MISMATCH
.

MessageId = 0x0010 ; // NTSTATUS(0xC03A0010)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_METADATA_READ_FAILURE
.

MessageId = 0x0011 ; // NTSTATUS(0xC03A0011)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_METADATA_WRITE_FAILURE
.

MessageId = 0x0012 ; // NTSTATUS(0xC03A0012)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_INVALID_SIZE
.

MessageId = 0x0013 ; // NTSTATUS(0xC03A0013)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_INVALID_FILE_SIZE
.

MessageId = 0x0014 ; // NTSTATUS(0xC03A0014)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VIRTDISK_PROVIDER_NOT_FOUND
.

MessageId = 0x0015 ; // NTSTATUS(0xC03A0015)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VIRTDISK_NOT_VIRTUAL_DISK
.

MessageId = 0x0016 ; // NTSTATUS(0xC03A0016)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_PARENT_VHD_ACCESS_DENIED
.

MessageId = 0x0017 ; // NTSTATUS(0xC03A0017)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_CHILD_PARENT_SIZE_MISMATCH
.

MessageId = 0x0018 ; // NTSTATUS(0xC03A0018)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_DIFFERENCING_CHAIN_CYCLE_DETECTED
.

MessageId = 0x0019 ; // NTSTATUS(0xC03A0019)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_DIFFERENCING_CHAIN_ERROR_IN_PARENT
.

MessageId = 0x001A ; // NTSTATUS(0xC03A001A)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VIRTUAL_DISK_LIMITATION
.

MessageId = 0x001B ; // NTSTATUS(0xC03A001B)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_INVALID_TYPE
.

MessageId = 0x001C ; // NTSTATUS(0xC03A001C)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_INVALID_STATE
.

MessageId = 0x001D ; // NTSTATUS(0xC03A001D)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VIRTDISK_UNSUPPORTED_DISK_SECTOR_SIZE
.

MessageId = 0x001E ; // NTSTATUS(0xC03A001E)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VIRTDISK_DISK_ALREADY_OWNED
.

MessageId = 0x001F ; // NTSTATUS(0xC03A001F)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VIRTDISK_DISK_ONLINE_AND_WRITABLE
.

MessageId = 0x0020 ; // NTSTATUS(0xC03A0020)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_CTLOG_TRACKING_NOT_INITIALIZED
.

MessageId = 0x0021 ; // NTSTATUS(0xC03A0021)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_CTLOG_LOGFILE_SIZE_EXCEEDED_MAXSIZE
.

MessageId = 0x0022 ; // NTSTATUS(0xC03A0022)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_CTLOG_VHD_CHANGED_OFFLINE
.

MessageId = 0x0023 ; // NTSTATUS(0xC03A0023)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_CTLOG_INVALID_TRACKING_STATE
.

MessageId = 0x0024 ; // NTSTATUS(0xC03A0024)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_CTLOG_INCONSISTENT_TRACKING_FILE
.

MessageId = 0x0028 ; // NTSTATUS(0xC03A0028)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_METADATA_FULL
.

MessageId = 0x0029 ; // NTSTATUS(0xC03A0029)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_INVALID_CHANGE_TRACKING_ID
.

MessageId = 0x002A ; // NTSTATUS(0xC03A002A)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_CHANGE_TRACKING_DISABLED
.

MessageId = 0x0030 ; // NTSTATUS(0xC03A0030)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_MISSING_CHANGE_TRACKING_INFORMATION
.

MessageId = 0x0031 ; // NTSTATUS(0xC03A0031)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_RESIZE_WOULD_TRUNCATE_DATA
.

MessageId = 0x0032 ; // NTSTATUS(0xC03A0032)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_COULD_NOT_COMPUTE_MINIMUM_VIRTUAL_SIZE
.

MessageId = 0x0033 ; // NTSTATUS(0xC03A0033)
Severity = Error
Facility = VHD
Language = Neutral
STATUS_VHD_ALREADY_AT_OR_BELOW_MINIMUM_VIRTUAL_SIZE
.

MessageId = 0x0001 ; // NTSTATUS(0xC0E90001)
Severity = Error
Facility = SystemIntegrity
Language = Neutral
STATUS_SYSTEM_INTEGRITY_ROLLBACK_DETECTED
.

MessageId = 0x0002 ; // NTSTATUS(0xC0E90002)
Severity = Error
Facility = SystemIntegrity
Language = Neutral
STATUS_SYSTEM_INTEGRITY_POLICY_VIOLATION
.

MessageId = 0x0003 ; // NTSTATUS(0xC0E90003)
Severity = Error
Facility = SystemIntegrity
Language = Neutral
STATUS_SYSTEM_INTEGRITY_INVALID_POLICY
.

MessageId = 0x0004 ; // NTSTATUS(0xC0E90004)
Severity = Error
Facility = SystemIntegrity
Language = Neutral
STATUS_SYSTEM_INTEGRITY_POLICY_NOT_SIGNED
.

MessageId = 0x0005 ; // NTSTATUS(0xC0E90005)
Severity = Error
Facility = SystemIntegrity
Language = Neutral
STATUS_SYSTEM_INTEGRITY_TOO_MANY_POLICIES
.

MessageId = 0x0006 ; // NTSTATUS(0xC0E90006)
Severity = Error
Facility = SystemIntegrity
Language = Neutral
STATUS_SYSTEM_INTEGRITY_SUPPLEMENTAL_POLICY_NOT_AUTHORIZED
.

MessageId = 0x0007 ; // NTSTATUS(0xC0E90007)
Severity = Error
Facility = SystemIntegrity
Language = Neutral
STATUS_SYSTEM_INTEGRITY_REPUTATION_MALICIOUS
.

MessageId = 0x0008 ; // NTSTATUS(0xC0E90008)
Severity = Error
Facility = SystemIntegrity
Language = Neutral
STATUS_SYSTEM_INTEGRITY_REPUTATION_PUA
.

MessageId = 0x0009 ; // NTSTATUS(0xC0E90009)
Severity = Error
Facility = SystemIntegrity
Language = Neutral
STATUS_SYSTEM_INTEGRITY_REPUTATION_DANGEROUS_EXT
.

MessageId = 0x000A ; // NTSTATUS(0xC0E9000A)
Severity = Error
Facility = SystemIntegrity
Language = Neutral
STATUS_SYSTEM_INTEGRITY_REPUTATION_OFFLINE
.

MessageId = 0x000B ; // NTSTATUS(0xC0E9000B)
Severity = Error
Facility = SystemIntegrity
Language = Neutral
STATUS_SYSTEM_INTEGRITY_REPUTATION_UNFRIENDLY_FILE
.

MessageId = 0x000C ; // NTSTATUS(0xC0E9000C)
Severity = Error
Facility = SystemIntegrity
Language = Neutral
STATUS_SYSTEM_INTEGRITY_REPUTATION_UNATTAINABLE
.

MessageId = 0x0000 ; // NTSTATUS(0xC0EC0000)
Severity = Error
Facility = AppExec
Language = Neutral
STATUS_APPEXEC_CONDITION_NOT_SATISFIED
.

MessageId = 0x0001 ; // NTSTATUS(0xC0EC0001)
Severity = Error
Facility = AppExec
Language = Neutral
STATUS_APPEXEC_HANDLE_INVALIDATED
.

MessageId = 0x0002 ; // NTSTATUS(0xC0EC0002)
Severity = Error
Facility = AppExec
Language = Neutral
STATUS_APPEXEC_INVALID_HOST_GENERATION
.

MessageId = 0x0003 ; // NTSTATUS(0xC0EC0003)
Severity = Error
Facility = AppExec
Language = Neutral
STATUS_APPEXEC_UNEXPECTED_PROCESS_REGISTRATION
.

MessageId = 0x0004 ; // NTSTATUS(0xC0EC0004)
Severity = Error
Facility = AppExec
Language = Neutral
STATUS_APPEXEC_INVALID_HOST_STATE
.

MessageId = 0x0005 ; // NTSTATUS(0xC0EC0005)
Severity = Error
Facility = AppExec
Language = Neutral
STATUS_APPEXEC_NO_DONOR
.

MessageId = 0x0006 ; // NTSTATUS(0xC0EC0006)
Severity = Error
Facility = AppExec
Language = Neutral
STATUS_APPEXEC_HOST_ID_MISMATCH
.

MessageId = 0x0007 ; // NTSTATUS(0xC0EC0007)
Severity = Error
Facility = AppExec
Language = Neutral
STATUS_APPEXEC_UNKNOWN_USER
.

MessageId = 0x0008 ; // NTSTATUS(0xC0EC0008)
Severity = Error
Facility = AppExec
Language = Neutral
STATUS_APPEXEC_APP_COMPAT_BLOCK
.

MessageId = 0x0009 ; // NTSTATUS(0xC0EC0009)
Severity = Error
Facility = AppExec
Language = Neutral
STATUS_APPEXEC_CALLER_WAIT_TIMEOUT
.

MessageId = 0x000A ; // NTSTATUS(0xC0EC000A)
Severity = Error
Facility = AppExec
Language = Neutral
STATUS_APPEXEC_CALLER_WAIT_TIMEOUT_TERMINATION
.

MessageId = 0x000B ; // NTSTATUS(0xC0EC000B)
Severity = Error
Facility = AppExec
Language = Neutral
STATUS_APPEXEC_CALLER_WAIT_TIMEOUT_LICENSING
.

MessageId = 0x000C ; // NTSTATUS(0xC0EC000C)
Severity = Error
Facility = AppExec
Language = Neutral
STATUS_APPEXEC_CALLER_WAIT_TIMEOUT_RESOURCES
.

;// ------------------------------ HRESULTs ------------------------------ //

; /* Success */

MessageId = 0x0000 ; // HRESULT(0x00000000)
Severity = Success
Facility = HRESULT_Null
Language = Neutral
S_OK
.

MessageId = 0x0001 ; // HRESULT(0x00000001)
Severity = Success
Facility = HRESULT_Null
Language = Neutral
S_FALSE
.

MessageId = 0x0200 ; // HRESULT(0x00030200)
Severity = Success
Facility = HRESULT_Storage
Language = Neutral
STG_S_CONVERTED
.

MessageId = 0x0201 ; // HRESULT(0x00030201)
Severity = Success
Facility = HRESULT_Storage
Language = Neutral
STG_S_BLOCK
.

MessageId = 0x0202 ; // HRESULT(0x00030202)
Severity = Success
Facility = HRESULT_Storage
Language = Neutral
STG_S_RETRYNOW
.

MessageId = 0x0203 ; // HRESULT(0x00030203)
Severity = Success
Facility = HRESULT_Storage
Language = Neutral
STG_S_MONITORING
.

MessageId = 0x0204 ; // HRESULT(0x00030204)
Severity = Success
Facility = HRESULT_Storage
Language = Neutral
STG_S_MULTIPLEOPENS
.

MessageId = 0x0205 ; // HRESULT(0x00030205)
Severity = Success
Facility = HRESULT_Storage
Language = Neutral
STG_S_CONSOLIDATIONFAILED
.

MessageId = 0x0206 ; // HRESULT(0x00030206)
Severity = Success
Facility = HRESULT_Storage
Language = Neutral
STG_S_CANNOTCONSOLIDATE
.

MessageId = 0x0207 ; // HRESULT(0x00030207)
Severity = Success
Facility = HRESULT_Storage
Language = Neutral
STG_S_POWER_CYCLE_REQUIRED
.

MessageId = 0x0000 ; // HRESULT(0x00040000)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
OLE_S_USEREG
.

MessageId = 0x0001 ; // HRESULT(0x00040001)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
OLE_S_STATIC
.

MessageId = 0x0002 ; // HRESULT(0x00040002)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
OLE_S_MAC_CLIPFORMAT
.

MessageId = 0x0180 ; // HRESULT(0x00040180)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
OLEOBJ_S_INVALIDVERB
.

MessageId = 0x0181 ; // HRESULT(0x00040181)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
OLEOBJ_S_CANNOT_DOVERB_NOW
.

MessageId = 0x0182 ; // HRESULT(0x00040182)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
OLEOBJ_S_INVALIDHWND
.

MessageId = 0x01E2 ; // HRESULT(0x000401E2)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
MK_S_REDUCED_TO_SELF
.

MessageId = 0x01E4 ; // HRESULT(0x000401E4)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
MK_S_ME
.

MessageId = 0x01E5 ; // HRESULT(0x000401E5)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
MK_S_HIM
.

MessageId = 0x01E6 ; // HRESULT(0x000401E6)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
MK_S_US
.

MessageId = 0x01E7 ; // HRESULT(0x000401E7)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
MK_S_MONIKERALREADYREGISTERED
.

MessageId = 0x0200 ; // HRESULT(0x00040200)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
EVENT_S_SOME_SUBSCRIBERS_FAILED
.

MessageId = 0x0202 ; // HRESULT(0x00040202)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
EVENT_S_NOSUBSCRIBERS
.

MessageId = 0x1300 ; // HRESULT(0x00041300)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
SCHED_S_TASK_READY
.

MessageId = 0x1301 ; // HRESULT(0x00041301)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
SCHED_S_TASK_RUNNING
.

MessageId = 0x1302 ; // HRESULT(0x00041302)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
SCHED_S_TASK_DISABLED
.

MessageId = 0x1303 ; // HRESULT(0x00041303)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
SCHED_S_TASK_HAS_NOT_RUN
.

MessageId = 0x1304 ; // HRESULT(0x00041304)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
SCHED_S_TASK_NO_MORE_RUNS
.

MessageId = 0x1305 ; // HRESULT(0x00041305)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
SCHED_S_TASK_NOT_SCHEDULED
.

MessageId = 0x1306 ; // HRESULT(0x00041306)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
SCHED_S_TASK_TERMINATED
.

MessageId = 0x1307 ; // HRESULT(0x00041307)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
SCHED_S_TASK_NO_VALID_TRIGGERS
.

MessageId = 0x1308 ; // HRESULT(0x00041308)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
SCHED_S_EVENT_TRIGGER
.

MessageId = 0x131B ; // HRESULT(0x0004131B)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
SCHED_S_SOME_TRIGGERS_FAILED
.

MessageId = 0x131C ; // HRESULT(0x0004131C)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
SCHED_S_BATCH_LOGON_PROBLEM
.

MessageId = 0x1325 ; // HRESULT(0x00041325)
Severity = Success
Facility = HRESULT_Interface
Language = Neutral
SCHED_S_TASK_QUEUED
.

MessageId = 0x0012 ; // HRESULT(0x00080012)
Severity = Success
Facility = HRESULT_Windows
Language = Neutral
CO_S_NOTALLINTERFACES
.

MessageId = 0x0013 ; // HRESULT(0x00080013)
Severity = Success
Facility = HRESULT_Windows
Language = Neutral
CO_S_MACHINENAMENOTFOUND
.

MessageId = 0x0000 ; // HRESULT(0x001B0000)
Severity = Success
Facility = HRESULT_Windows
Language = Neutral
WER_S_REPORT_DEBUG
.

MessageId = 0x0001 ; // HRESULT(0x001B0001)
Severity = Success
Facility = HRESULT_Windows
Language = Neutral
WER_S_REPORT_UPLOADED
.

MessageId = 0x0002 ; // HRESULT(0x001B0002)
Severity = Success
Facility = HRESULT_Windows
Language = Neutral
WER_S_REPORT_QUEUED
.

MessageId = 0x0003 ; // HRESULT(0x001B0003)
Severity = Success
Facility = HRESULT_Windows
Language = Neutral
WER_S_DISABLED
.

MessageId = 0x0004 ; // HRESULT(0x001B0004)
Severity = Success
Facility = HRESULT_Windows
Language = Neutral
WER_S_SUSPENDED_UPLOAD
.

MessageId = 0x0005 ; // HRESULT(0x001B0005)
Severity = Success
Facility = HRESULT_Windows
Language = Neutral
WER_S_DISABLED_QUEUE
.

MessageId = 0x0006 ; // HRESULT(0x001B0006)
Severity = Success
Facility = HRESULT_Windows
Language = Neutral
WER_S_DISABLED_ARCHIVE
.

MessageId = 0x0007 ; // HRESULT(0x001B0007)
Severity = Success
Facility = HRESULT_Windows
Language = Neutral
WER_S_REPORT_ASYNC
.

MessageId = 0x0008 ; // HRESULT(0x001B0008)
Severity = Success
Facility = HRESULT_Windows
Language = Neutral
WER_S_IGNORE_ASSERT_INSTANCE
.

MessageId = 0x0009 ; // HRESULT(0x001B0009)
Severity = Success
Facility = HRESULT_Windows
Language = Neutral
WER_S_IGNORE_ALL_ASSERTS
.

MessageId = 0x000A ; // HRESULT(0x001B000A)
Severity = Success
Facility = HRESULT_Windows
Language = Neutral
WER_S_ASSERT_CONTINUE
.

MessageId = 0x000B ; // HRESULT(0x001B000B)
Severity = Success
Facility = HRESULT_Windows
Language = Neutral
WER_S_THROTTLED
.

MessageId = 0x000C ; // HRESULT(0x001B000C)
Severity = Success
Facility = HRESULT_Windows
Language = Neutral
WER_S_REPORT_UPLOADED_CAB
.

MessageId = 0x3005 ; // HRESULT(0x00263005)
Severity = Success
Facility = HRESULT_Graphics
Language = Neutral
DWM_S_GDI_REDIRECTION_SURFACE
.

MessageId = 0x3008 ; // HRESULT(0x00263008)
Severity = Success
Facility = HRESULT_Graphics
Language = Neutral
DWM_S_GDI_REDIRECTION_SURFACE_BLT_VIA_GDI
.

MessageId = 0x0258 ; // HRESULT(0x00270258)
Severity = Success
Facility = HRESULT_Shell
Language = Neutral
S_STORE_LAUNCHED_FOR_REMEDIATION
.

MessageId = 0x0259 ; // HRESULT(0x00270259)
Severity = Success
Facility = HRESULT_Shell
Language = Neutral
S_APPLICATION_ACTIVATION_ERROR_HANDLED_BY_DIALOG
.

; /* Warning */

MessageId = 0x0001 ; // HRESULT(0x80000001)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_NOTIMPL
.

MessageId = 0x0002 ; // HRESULT(0x80000002)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_OUTOFMEMORY
.

MessageId = 0x0003 ; // HRESULT(0x80000003)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_INVALIDARG
.

MessageId = 0x0004 ; // HRESULT(0x80000004)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_NOINTERFACE
.

MessageId = 0x0005 ; // HRESULT(0x80000005)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_POINTER
.

MessageId = 0x0006 ; // HRESULT(0x80000006)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_HANDLE
.

MessageId = 0x0007 ; // HRESULT(0x80000007)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_ABORT
.

MessageId = 0x0008 ; // HRESULT(0x80000008)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_FAIL
.

MessageId = 0x0009 ; // HRESULT(0x80000009)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_ACCESSDENIED
.

MessageId = 0x000A ; // HRESULT(0x8000000A)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_PENDING
.

MessageId = 0x000B ; // HRESULT(0x8000000B)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_BOUNDS
.

MessageId = 0x000C ; // HRESULT(0x8000000C)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_CHANGED_STATE
.

MessageId = 0x000D ; // HRESULT(0x8000000D)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_ILLEGAL_STATE_CHANGE
.

MessageId = 0x000E ; // HRESULT(0x8000000E)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_ILLEGAL_METHOD_CALL
.

MessageId = 0x000F ; // HRESULT(0x8000000F)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
RO_E_METADATA_NAME_NOT_FOUND
.

MessageId = 0x0010 ; // HRESULT(0x80000010)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
RO_E_METADATA_NAME_IS_NAMESPACE
.

MessageId = 0x0011 ; // HRESULT(0x80000011)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
RO_E_METADATA_INVALID_TYPE_FORMAT
.

MessageId = 0x0012 ; // HRESULT(0x80000012)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
RO_E_INVALID_METADATA_FILE
.

MessageId = 0x0013 ; // HRESULT(0x80000013)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
RO_E_CLOSED
.

MessageId = 0x0014 ; // HRESULT(0x80000014)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
RO_E_EXCLUSIVE_WRITE
.

MessageId = 0x0015 ; // HRESULT(0x80000015)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
RO_E_CHANGE_NOTIFICATION_IN_PROGRESS
.

MessageId = 0x0016 ; // HRESULT(0x80000016)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
RO_E_ERROR_STRING_NOT_FOUND
.

MessageId = 0x0017 ; // HRESULT(0x80000017)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_STRING_NOT_NULL_TERMINATED
.

MessageId = 0x0018 ; // HRESULT(0x80000018)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_ILLEGAL_DELEGATE_ASSIGNMENT
.

MessageId = 0x0019 ; // HRESULT(0x80000019)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_ASYNC_OPERATION_NOT_STARTED
.

MessageId = 0x001A ; // HRESULT(0x8000001A)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_APPLICATION_EXITING
.

MessageId = 0x001B ; // HRESULT(0x8000001B)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_APPLICATION_VIEW_EXITING
.

MessageId = 0x001C ; // HRESULT(0x8000001C)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
RO_E_MUST_BE_AGILE
.

MessageId = 0x001D ; // HRESULT(0x8000001D)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
RO_E_UNSUPPORTED_FROM_MTA
.

MessageId = 0x001E ; // HRESULT(0x8000001E)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
RO_E_COMMITTED
.

MessageId = 0x001F ; // HRESULT(0x8000001F)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
RO_E_BLOCKED_CROSS_ASTA_CALL
.

MessageId = 0x0020 ; // HRESULT(0x80000020)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
RO_E_CANNOT_ACTIVATE_FULL_TRUST_SERVER
.

MessageId = 0x0021 ; // HRESULT(0x80000021)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
RO_E_CANNOT_ACTIVATE_UNIVERSAL_APPLICATION_SERVER
.

MessageId = 0x4001 ; // HRESULT(0x80004001)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_NOTIMPL
.

MessageId = 0x4002 ; // HRESULT(0x80004002)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_NOINTERFACE
.

MessageId = 0x4003 ; // HRESULT(0x80004003)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_POINTER
.

MessageId = 0x4004 ; // HRESULT(0x80004004)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_ABORT
.

MessageId = 0x4005 ; // HRESULT(0x80004005)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_FAIL
.

MessageId = 0x4006 ; // HRESULT(0x80004006)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_INIT_TLS
.

MessageId = 0x4007 ; // HRESULT(0x80004007)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_INIT_SHARED_ALLOCATOR
.

MessageId = 0x4008 ; // HRESULT(0x80004008)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_INIT_MEMORY_ALLOCATOR
.

MessageId = 0x4009 ; // HRESULT(0x80004009)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_INIT_CLASS_CACHE
.

MessageId = 0x400A ; // HRESULT(0x8000400A)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_INIT_RPC_CHANNEL
.

MessageId = 0x400B ; // HRESULT(0x8000400B)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_INIT_TLS_SET_CHANNEL_CONTROL
.

MessageId = 0x400C ; // HRESULT(0x8000400C)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_INIT_TLS_CHANNEL_CONTROL
.

MessageId = 0x400D ; // HRESULT(0x8000400D)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_INIT_UNACCEPTED_USER_ALLOCATOR
.

MessageId = 0x400E ; // HRESULT(0x8000400E)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_INIT_SCM_MUTEX_EXISTS
.

MessageId = 0x400F ; // HRESULT(0x8000400F)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_INIT_SCM_FILE_MAPPING_EXISTS
.

MessageId = 0x4010 ; // HRESULT(0x80004010)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_INIT_SCM_MAP_VIEW_OF_FILE
.

MessageId = 0x4011 ; // HRESULT(0x80004011)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_INIT_SCM_EXEC_FAILURE
.

MessageId = 0x4012 ; // HRESULT(0x80004012)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_INIT_ONLY_SINGLE_THREADED
.

MessageId = 0x4013 ; // HRESULT(0x80004013)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_CANT_REMOTE
.

MessageId = 0x4014 ; // HRESULT(0x80004014)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_BAD_SERVER_NAME
.

MessageId = 0x4015 ; // HRESULT(0x80004015)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_WRONG_SERVER_IDENTITY
.

MessageId = 0x4016 ; // HRESULT(0x80004016)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_OLE1DDE_DISABLED
.

MessageId = 0x4017 ; // HRESULT(0x80004017)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_RUNAS_SYNTAX
.

MessageId = 0x4018 ; // HRESULT(0x80004018)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_CREATEPROCESS_FAILURE
.

MessageId = 0x4019 ; // HRESULT(0x80004019)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_RUNAS_CREATEPROCESS_FAILURE
.

MessageId = 0x401A ; // HRESULT(0x8000401A)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_RUNAS_LOGON_FAILURE
.

MessageId = 0x401B ; // HRESULT(0x8000401B)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_LAUNCH_PERMSSION_DENIED
.

MessageId = 0x401C ; // HRESULT(0x8000401C)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_START_SERVICE_FAILURE
.

MessageId = 0x401D ; // HRESULT(0x8000401D)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_REMOTE_COMMUNICATION_FAILURE
.

MessageId = 0x401E ; // HRESULT(0x8000401E)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_SERVER_START_TIMEOUT
.

MessageId = 0x401F ; // HRESULT(0x8000401F)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_CLSREG_INCONSISTENT
.

MessageId = 0x4020 ; // HRESULT(0x80004020)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_IIDREG_INCONSISTENT
.

MessageId = 0x4021 ; // HRESULT(0x80004021)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_NOT_SUPPORTED
.

MessageId = 0x4022 ; // HRESULT(0x80004022)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_RELOAD_DLL
.

MessageId = 0x4023 ; // HRESULT(0x80004023)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_MSI_ERROR
.

MessageId = 0x4024 ; // HRESULT(0x80004024)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_ATTEMPT_TO_CREATE_OUTSIDE_CLIENT_CONTEXT
.

MessageId = 0x4025 ; // HRESULT(0x80004025)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_SERVER_PAUSED
.

MessageId = 0x4026 ; // HRESULT(0x80004026)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_SERVER_NOT_PAUSED
.

MessageId = 0x4027 ; // HRESULT(0x80004027)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_CLASS_DISABLED
.

MessageId = 0x4028 ; // HRESULT(0x80004028)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_CLRNOTAVAILABLE
.

MessageId = 0x4029 ; // HRESULT(0x80004029)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_ASYNC_WORK_REJECTED
.

MessageId = 0x402A ; // HRESULT(0x8000402A)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_SERVER_INIT_TIMEOUT
.

MessageId = 0x402B ; // HRESULT(0x8000402B)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_NO_SECCTX_IN_ACTIVATE
.

MessageId = 0x4030 ; // HRESULT(0x80004030)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_TRACKER_CONFIG
.

MessageId = 0x4031 ; // HRESULT(0x80004031)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_THREADPOOL_CONFIG
.

MessageId = 0x4032 ; // HRESULT(0x80004032)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_SXS_CONFIG
.

MessageId = 0x4033 ; // HRESULT(0x80004033)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_MALFORMED_SPN
.

MessageId = 0x4034 ; // HRESULT(0x80004034)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_UNREVOKED_REGISTRATION_ON_APARTMENT_SHUTDOWN
.

MessageId = 0x4035 ; // HRESULT(0x80004035)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
CO_E_PREMATURE_STUB_RUNDOWN
.

MessageId = 0xFFFF ; // HRESULT(0x8000FFFF)
Severity = Warning
Facility = HRESULT_Null
Language = Neutral
E_UNEXPECTED
.

MessageId = 0x0001 ; // HRESULT(0x80010001)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_CALL_REJECTED
.

MessageId = 0x0002 ; // HRESULT(0x80010002)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_CALL_CANCELED
.

MessageId = 0x0003 ; // HRESULT(0x80010003)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_CANTPOST_INSENDCALL
.

MessageId = 0x0004 ; // HRESULT(0x80010004)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_CANTCALLOUT_INASYNCCALL
.

MessageId = 0x0005 ; // HRESULT(0x80010005)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_CANTCALLOUT_INEXTERNALCALL
.

MessageId = 0x0006 ; // HRESULT(0x80010006)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_CONNECTION_TERMINATED
.

MessageId = 0x0007 ; // HRESULT(0x80010007)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_SERVER_DIED
.

MessageId = 0x0008 ; // HRESULT(0x80010008)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_CLIENT_DIED
.

MessageId = 0x0009 ; // HRESULT(0x80010009)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_INVALID_DATAPACKET
.

MessageId = 0x000A ; // HRESULT(0x8001000A)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_CANTTRANSMIT_CALL
.

MessageId = 0x000B ; // HRESULT(0x8001000B)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_CLIENT_CANTMARSHAL_DATA
.

MessageId = 0x000C ; // HRESULT(0x8001000C)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_CLIENT_CANTUNMARSHAL_DATA
.

MessageId = 0x000D ; // HRESULT(0x8001000D)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_SERVER_CANTMARSHAL_DATA
.

MessageId = 0x000E ; // HRESULT(0x8001000E)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_SERVER_CANTUNMARSHAL_DATA
.

MessageId = 0x000F ; // HRESULT(0x8001000F)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_INVALID_DATA
.

MessageId = 0x0010 ; // HRESULT(0x80010010)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_INVALID_PARAMETER
.

MessageId = 0x0011 ; // HRESULT(0x80010011)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_CANTCALLOUT_AGAIN
.

MessageId = 0x0012 ; // HRESULT(0x80010012)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_SERVER_DIED_DNE
.

MessageId = 0x0100 ; // HRESULT(0x80010100)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_SYS_CALL_FAILED
.

MessageId = 0x0101 ; // HRESULT(0x80010101)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_OUT_OF_RESOURCES
.

MessageId = 0x0102 ; // HRESULT(0x80010102)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_ATTEMPTED_MULTITHREAD
.

MessageId = 0x0103 ; // HRESULT(0x80010103)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_NOT_REGISTERED
.

MessageId = 0x0104 ; // HRESULT(0x80010104)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_FAULT
.

MessageId = 0x0105 ; // HRESULT(0x80010105)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_SERVERFAULT
.

MessageId = 0x0106 ; // HRESULT(0x80010106)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_CHANGED_MODE
.

MessageId = 0x0107 ; // HRESULT(0x80010107)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_INVALIDMETHOD
.

MessageId = 0x0108 ; // HRESULT(0x80010108)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_DISCONNECTED
.

MessageId = 0x0109 ; // HRESULT(0x80010109)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_RETRY
.

MessageId = 0x010A ; // HRESULT(0x8001010A)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_SERVERCALL_RETRYLATER
.

MessageId = 0x010B ; // HRESULT(0x8001010B)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_SERVERCALL_REJECTED
.

MessageId = 0x010C ; // HRESULT(0x8001010C)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_INVALID_CALLDATA
.

MessageId = 0x010D ; // HRESULT(0x8001010D)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_CANTCALLOUT_ININPUTSYNCCALL
.

MessageId = 0x010E ; // HRESULT(0x8001010E)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_WRONG_THREAD
.

MessageId = 0x010F ; // HRESULT(0x8001010F)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_THREAD_NOT_INIT
.

MessageId = 0x0110 ; // HRESULT(0x80010110)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_VERSION_MISMATCH
.

MessageId = 0x0111 ; // HRESULT(0x80010111)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_INVALID_HEADER
.

MessageId = 0x0112 ; // HRESULT(0x80010112)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_INVALID_EXTENSION
.

MessageId = 0x0113 ; // HRESULT(0x80010113)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_INVALID_IPID
.

MessageId = 0x0114 ; // HRESULT(0x80010114)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_INVALID_OBJECT
.

MessageId = 0x0115 ; // HRESULT(0x80010115)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_S_CALLPENDING
.

MessageId = 0x0116 ; // HRESULT(0x80010116)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_S_WAITONTIMER
.

MessageId = 0x0117 ; // HRESULT(0x80010117)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_CALL_COMPLETE
.

MessageId = 0x0118 ; // HRESULT(0x80010118)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_UNSECURE_CALL
.

MessageId = 0x0119 ; // HRESULT(0x80010119)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_TOO_LATE
.

MessageId = 0x011A ; // HRESULT(0x8001011A)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_NO_GOOD_SECURITY_PACKAGES
.

MessageId = 0x011B ; // HRESULT(0x8001011B)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_ACCESS_DENIED
.

MessageId = 0x011C ; // HRESULT(0x8001011C)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_REMOTE_DISABLED
.

MessageId = 0x011D ; // HRESULT(0x8001011D)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_INVALID_OBJREF
.

MessageId = 0x011E ; // HRESULT(0x8001011E)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_NO_CONTEXT
.

MessageId = 0x011F ; // HRESULT(0x8001011F)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_TIMEOUT
.

MessageId = 0x0120 ; // HRESULT(0x80010120)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_NO_SYNC
.

MessageId = 0x0121 ; // HRESULT(0x80010121)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_FULLSIC_REQUIRED
.

MessageId = 0x0122 ; // HRESULT(0x80010122)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_INVALID_STD_NAME
.

MessageId = 0x0123 ; // HRESULT(0x80010123)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_FAILEDTOIMPERSONATE
.

MessageId = 0x0124 ; // HRESULT(0x80010124)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_FAILEDTOGETSECCTX
.

MessageId = 0x0125 ; // HRESULT(0x80010125)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_FAILEDTOOPENTHREADTOKEN
.

MessageId = 0x0126 ; // HRESULT(0x80010126)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_FAILEDTOGETTOKENINFO
.

MessageId = 0x0127 ; // HRESULT(0x80010127)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_TRUSTEEDOESNTMATCHCLIENT
.

MessageId = 0x0128 ; // HRESULT(0x80010128)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_FAILEDTOQUERYCLIENTBLANKET
.

MessageId = 0x0129 ; // HRESULT(0x80010129)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_FAILEDTOSETDACL
.

MessageId = 0x012A ; // HRESULT(0x8001012A)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_ACCESSCHECKFAILED
.

MessageId = 0x012B ; // HRESULT(0x8001012B)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_NETACCESSAPIFAILED
.

MessageId = 0x012C ; // HRESULT(0x8001012C)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_WRONGTRUSTEENAMESYNTAX
.

MessageId = 0x012D ; // HRESULT(0x8001012D)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_INVALIDSID
.

MessageId = 0x012E ; // HRESULT(0x8001012E)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_CONVERSIONFAILED
.

MessageId = 0x012F ; // HRESULT(0x8001012F)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_NOMATCHINGSIDFOUND
.

MessageId = 0x0130 ; // HRESULT(0x80010130)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_LOOKUPACCSIDFAILED
.

MessageId = 0x0131 ; // HRESULT(0x80010131)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_NOMATCHINGNAMEFOUND
.

MessageId = 0x0132 ; // HRESULT(0x80010132)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_LOOKUPACCNAMEFAILED
.

MessageId = 0x0133 ; // HRESULT(0x80010133)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_SETSERLHNDLFAILED
.

MessageId = 0x0134 ; // HRESULT(0x80010134)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_FAILEDTOGETWINDIR
.

MessageId = 0x0135 ; // HRESULT(0x80010135)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_PATHTOOLONG
.

MessageId = 0x0136 ; // HRESULT(0x80010136)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_FAILEDTOGENUUID
.

MessageId = 0x0137 ; // HRESULT(0x80010137)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_FAILEDTOCREATEFILE
.

MessageId = 0x0138 ; // HRESULT(0x80010138)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_FAILEDTOCLOSEHANDLE
.

MessageId = 0x0139 ; // HRESULT(0x80010139)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_EXCEEDSYSACLLIMIT
.

MessageId = 0x013A ; // HRESULT(0x8001013A)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_ACESINWRONGORDER
.

MessageId = 0x013B ; // HRESULT(0x8001013B)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_INCOMPATIBLESTREAMVERSION
.

MessageId = 0x013C ; // HRESULT(0x8001013C)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_FAILEDTOOPENPROCESSTOKEN
.

MessageId = 0x013D ; // HRESULT(0x8001013D)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_DECODEFAILED
.

MessageId = 0x013F ; // HRESULT(0x8001013F)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_ACNOTINITIALIZED
.

MessageId = 0x0140 ; // HRESULT(0x80010140)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
CO_E_CANCEL_DISABLED
.

MessageId = 0xFFFF ; // HRESULT(0x8001FFFF)
Severity = Warning
Facility = HRESULT_RPC
Language = Neutral
RPC_E_UNEXPECTED
.

MessageId = 0x0001 ; // HRESULT(0x80020001)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_UNKNOWNINTERFACE
.

MessageId = 0x0003 ; // HRESULT(0x80020003)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_MEMBERNOTFOUND
.

MessageId = 0x0004 ; // HRESULT(0x80020004)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_PARAMNOTFOUND
.

MessageId = 0x0005 ; // HRESULT(0x80020005)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_TYPEMISMATCH
.

MessageId = 0x0006 ; // HRESULT(0x80020006)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_UNKNOWNNAME
.

MessageId = 0x0007 ; // HRESULT(0x80020007)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_NONAMEDARGS
.

MessageId = 0x0008 ; // HRESULT(0x80020008)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_BADVARTYPE
.

MessageId = 0x0009 ; // HRESULT(0x80020009)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_EXCEPTION
.

MessageId = 0x000A ; // HRESULT(0x8002000A)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_OVERFLOW
.

MessageId = 0x000B ; // HRESULT(0x8002000B)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_BADINDEX
.

MessageId = 0x000C ; // HRESULT(0x8002000C)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_UNKNOWNLCID
.

MessageId = 0x000D ; // HRESULT(0x8002000D)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_ARRAYISLOCKED
.

MessageId = 0x000E ; // HRESULT(0x8002000E)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_BADPARAMCOUNT
.

MessageId = 0x000F ; // HRESULT(0x8002000F)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_PARAMNOTOPTIONAL
.

MessageId = 0x0010 ; // HRESULT(0x80020010)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_BADCALLEE
.

MessageId = 0x0011 ; // HRESULT(0x80020011)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_NOTACOLLECTION
.

MessageId = 0x0012 ; // HRESULT(0x80020012)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_DIVBYZERO
.

MessageId = 0x0013 ; // HRESULT(0x80020013)
Severity = Warning
Facility = HRESULT_Dispatch
Language = Neutral
DISP_E_BUFFERTOOSMALL
.

MessageId = 0x0001 ; // HRESULT(0x80030001)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_INVALIDFUNCTION
.

MessageId = 0x0002 ; // HRESULT(0x80030002)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_FILENOTFOUND
.

MessageId = 0x0003 ; // HRESULT(0x80030003)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_PATHNOTFOUND
.

MessageId = 0x0004 ; // HRESULT(0x80030004)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_TOOMANYOPENFILES
.

MessageId = 0x0005 ; // HRESULT(0x80030005)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_ACCESSDENIED
.

MessageId = 0x0006 ; // HRESULT(0x80030006)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_INVALIDHANDLE
.

MessageId = 0x0008 ; // HRESULT(0x80030008)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_INSUFFICIENTMEMORY
.

MessageId = 0x0009 ; // HRESULT(0x80030009)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_INVALIDPOINTER
.

MessageId = 0x0012 ; // HRESULT(0x80030012)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_NOMOREFILES
.

MessageId = 0x0013 ; // HRESULT(0x80030013)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_DISKISWRITEPROTECTED
.

MessageId = 0x0019 ; // HRESULT(0x80030019)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_SEEKERROR
.

MessageId = 0x001D ; // HRESULT(0x8003001D)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_WRITEFAULT
.

MessageId = 0x001E ; // HRESULT(0x8003001E)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_READFAULT
.

MessageId = 0x0020 ; // HRESULT(0x80030020)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_SHAREVIOLATION
.

MessageId = 0x0021 ; // HRESULT(0x80030021)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_LOCKVIOLATION
.

MessageId = 0x0050 ; // HRESULT(0x80030050)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_FILEALREADYEXISTS
.

MessageId = 0x0057 ; // HRESULT(0x80030057)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_INVALIDPARAMETER
.

MessageId = 0x0070 ; // HRESULT(0x80030070)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_MEDIUMFULL
.

MessageId = 0x00F0 ; // HRESULT(0x800300F0)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_PROPSETMISMATCHED
.

MessageId = 0x00FA ; // HRESULT(0x800300FA)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_ABNORMALAPIEXIT
.

MessageId = 0x00FB ; // HRESULT(0x800300FB)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_INVALIDHEADER
.

MessageId = 0x00FC ; // HRESULT(0x800300FC)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_INVALIDNAME
.

MessageId = 0x00FD ; // HRESULT(0x800300FD)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_UNKNOWN
.

MessageId = 0x00FE ; // HRESULT(0x800300FE)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_UNIMPLEMENTEDFUNCTION
.

MessageId = 0x00FF ; // HRESULT(0x800300FF)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_INVALIDFLAG
.

MessageId = 0x0100 ; // HRESULT(0x80030100)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_INUSE
.

MessageId = 0x0101 ; // HRESULT(0x80030101)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_NOTCURRENT
.

MessageId = 0x0102 ; // HRESULT(0x80030102)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_REVERTED
.

MessageId = 0x0103 ; // HRESULT(0x80030103)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_CANTSAVE
.

MessageId = 0x0104 ; // HRESULT(0x80030104)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_OLDFORMAT
.

MessageId = 0x0105 ; // HRESULT(0x80030105)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_OLDDLL
.

MessageId = 0x0106 ; // HRESULT(0x80030106)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_SHAREREQUIRED
.

MessageId = 0x0107 ; // HRESULT(0x80030107)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_NOTFILEBASEDSTORAGE
.

MessageId = 0x0108 ; // HRESULT(0x80030108)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_EXTANTMARSHALLINGS
.

MessageId = 0x0109 ; // HRESULT(0x80030109)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_DOCFILECORRUPT
.

MessageId = 0x0110 ; // HRESULT(0x80030110)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_BADBASEADDRESS
.

MessageId = 0x0111 ; // HRESULT(0x80030111)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_DOCFILETOOLARGE
.

MessageId = 0x0112 ; // HRESULT(0x80030112)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_NOTSIMPLEFORMAT
.

MessageId = 0x0201 ; // HRESULT(0x80030201)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_INCOMPLETE
.

MessageId = 0x0202 ; // HRESULT(0x80030202)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_TERMINATED
.

MessageId = 0x0208 ; // HRESULT(0x80030208)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_FIRMWARE_SLOT_INVALID
.

MessageId = 0x0209 ; // HRESULT(0x80030209)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_FIRMWARE_IMAGE_INVALID
.

MessageId = 0x020A ; // HRESULT(0x8003020A)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_DEVICE_UNRESPONSIVE
.

MessageId = 0x0305 ; // HRESULT(0x80030305)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_STATUS_COPY_PROTECTION_FAILURE
.

MessageId = 0x0306 ; // HRESULT(0x80030306)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_CSS_AUTHENTICATION_FAILURE
.

MessageId = 0x0307 ; // HRESULT(0x80030307)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_CSS_KEY_NOT_PRESENT
.

MessageId = 0x0308 ; // HRESULT(0x80030308)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_CSS_KEY_NOT_ESTABLISHED
.

MessageId = 0x0309 ; // HRESULT(0x80030309)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_CSS_SCRAMBLED_SECTOR
.

MessageId = 0x030A ; // HRESULT(0x8003030A)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_CSS_REGION_MISMATCH
.

MessageId = 0x030B ; // HRESULT(0x8003030B)
Severity = Warning
Facility = HRESULT_Storage
Language = Neutral
STG_E_RESETS_EXHAUSTED
.

MessageId = 0x0000 ; // HRESULT(0x80040000)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_OLEVERB
.

MessageId = 0x0001 ; // HRESULT(0x80040001)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_ADVF
.

MessageId = 0x0002 ; // HRESULT(0x80040002)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_ENUM_NOMORE
.

MessageId = 0x0003 ; // HRESULT(0x80040003)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_ADVISENOTSUPPORTED
.

MessageId = 0x0004 ; // HRESULT(0x80040004)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_NOCONNECTION
.

MessageId = 0x0005 ; // HRESULT(0x80040005)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_NOTRUNNING
.

MessageId = 0x0006 ; // HRESULT(0x80040006)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_NOCACHE
.

MessageId = 0x0007 ; // HRESULT(0x80040007)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_BLANK
.

MessageId = 0x0008 ; // HRESULT(0x80040008)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_CLASSDIFF
.

MessageId = 0x0009 ; // HRESULT(0x80040009)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_CANT_GETMONIKER
.

MessageId = 0x000A ; // HRESULT(0x8004000A)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_CANT_BINDTOSOURCE
.

MessageId = 0x000B ; // HRESULT(0x8004000B)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_STATIC
.

MessageId = 0x000C ; // HRESULT(0x8004000C)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_PROMPTSAVECANCELLED
.

MessageId = 0x000D ; // HRESULT(0x8004000D)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_INVALIDRECT
.

MessageId = 0x000E ; // HRESULT(0x8004000E)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_WRONGCOMPOBJ
.

MessageId = 0x000F ; // HRESULT(0x8004000F)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_INVALIDHWND
.

MessageId = 0x0010 ; // HRESULT(0x80040010)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_NOT_INPLACEACTIVE
.

MessageId = 0x0011 ; // HRESULT(0x80040011)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_CANTCONVERT
.

MessageId = 0x0012 ; // HRESULT(0x80040012)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLE_E_NOSTORAGE
.

MessageId = 0x0110 ; // HRESULT(0x80040110)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CLASS_E_NOAGGREGATION
.

MessageId = 0x0111 ; // HRESULT(0x80040111)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CLASS_E_CLASSNOTAVAILABLE
.

MessageId = 0x0112 ; // HRESULT(0x80040112)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CLASS_E_NOTLICENSED
.

MessageId = 0x0150 ; // HRESULT(0x80040150)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
REGDB_E_READREGDB
.

MessageId = 0x0151 ; // HRESULT(0x80040151)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
REGDB_E_WRITEREGDB
.

MessageId = 0x0152 ; // HRESULT(0x80040152)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
REGDB_E_KEYMISSING
.

MessageId = 0x0153 ; // HRESULT(0x80040153)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
REGDB_E_INVALIDVALUE
.

MessageId = 0x0154 ; // HRESULT(0x80040154)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
REGDB_E_CLASSNOTREG
.

MessageId = 0x0155 ; // HRESULT(0x80040155)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
REGDB_E_IIDNOTREG
.

MessageId = 0x0156 ; // HRESULT(0x80040156)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
REGDB_E_BADTHREADINGMODEL
.

MessageId = 0x0157 ; // HRESULT(0x80040157)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
REGDB_E_PACKAGEPOLICYVIOLATION
.

MessageId = 0x0160 ; // HRESULT(0x80040160)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CAT_E_CATIDNOEXIST
.

MessageId = 0x0161 ; // HRESULT(0x80040161)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CAT_E_NODESCRIPTION
.

MessageId = 0x0164 ; // HRESULT(0x80040164)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CS_E_PACKAGE_NOTFOUND
.

MessageId = 0x0165 ; // HRESULT(0x80040165)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CS_E_NOT_DELETABLE
.

MessageId = 0x0166 ; // HRESULT(0x80040166)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CS_E_CLASS_NOTFOUND
.

MessageId = 0x0167 ; // HRESULT(0x80040167)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CS_E_INVALID_VERSION
.

MessageId = 0x0168 ; // HRESULT(0x80040168)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CS_E_NO_CLASSSTORE
.

MessageId = 0x0169 ; // HRESULT(0x80040169)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CS_E_OBJECT_NOTFOUND
.

MessageId = 0x016A ; // HRESULT(0x8004016A)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CS_E_OBJECT_ALREADY_EXISTS
.

MessageId = 0x016B ; // HRESULT(0x8004016B)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CS_E_INVALID_PATH
.

MessageId = 0x016C ; // HRESULT(0x8004016C)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CS_E_NETWORK_ERROR
.

MessageId = 0x016D ; // HRESULT(0x8004016D)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CS_E_ADMIN_LIMIT_EXCEEDED
.

MessageId = 0x016E ; // HRESULT(0x8004016E)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CS_E_SCHEMA_MISMATCH
.

MessageId = 0x016F ; // HRESULT(0x8004016F)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CS_E_INTERNAL_ERROR
.

MessageId = 0x0180 ; // HRESULT(0x80040180)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLEOBJ_E_NOVERBS
.

MessageId = 0x0181 ; // HRESULT(0x80040181)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
OLEOBJ_E_INVALIDVERB
.

MessageId = 0x01D0 ; // HRESULT(0x800401D0)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CLIPBRD_E_CANT_OPEN
.

MessageId = 0x01D1 ; // HRESULT(0x800401D1)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CLIPBRD_E_CANT_EMPTY
.

MessageId = 0x01D2 ; // HRESULT(0x800401D2)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CLIPBRD_E_CANT_SET
.

MessageId = 0x01D3 ; // HRESULT(0x800401D3)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CLIPBRD_E_BAD_DATA
.

MessageId = 0x01D4 ; // HRESULT(0x800401D4)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CLIPBRD_E_CANT_CLOSE
.

MessageId = 0x01E0 ; // HRESULT(0x800401E0)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
MK_E_CONNECTMANUALLY
.

MessageId = 0x01E1 ; // HRESULT(0x800401E1)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
MK_E_EXCEEDEDDEADLINE
.

MessageId = 0x01E2 ; // HRESULT(0x800401E2)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
MK_E_NEEDGENERIC
.

MessageId = 0x01E3 ; // HRESULT(0x800401E3)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
MK_E_UNAVAILABLE
.

MessageId = 0x01E4 ; // HRESULT(0x800401E4)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
MK_E_SYNTAX
.

MessageId = 0x01E5 ; // HRESULT(0x800401E5)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
MK_E_NOOBJECT
.

MessageId = 0x01E6 ; // HRESULT(0x800401E6)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
MK_E_INVALIDEXTENSION
.

MessageId = 0x01E7 ; // HRESULT(0x800401E7)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
MK_E_INTERMEDIATEINTERFACENOTSUPPORTED
.

MessageId = 0x01E8 ; // HRESULT(0x800401E8)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
MK_E_NOTBINDABLE
.

MessageId = 0x01E9 ; // HRESULT(0x800401E9)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
MK_E_NOTBOUND
.

MessageId = 0x01EA ; // HRESULT(0x800401EA)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
MK_E_CANTOPENFILE
.

MessageId = 0x01EB ; // HRESULT(0x800401EB)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
MK_E_MUSTBOTHERUSER
.

MessageId = 0x01EC ; // HRESULT(0x800401EC)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
MK_E_NOINVERSE
.

MessageId = 0x01ED ; // HRESULT(0x800401ED)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
MK_E_NOSTORAGE
.

MessageId = 0x01EE ; // HRESULT(0x800401EE)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
MK_E_NOPREFIX
.

MessageId = 0x01EF ; // HRESULT(0x800401EF)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
MK_E_ENUMERATION_FAILED
.

MessageId = 0x01F0 ; // HRESULT(0x800401F0)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_NOTINITIALIZED
.

MessageId = 0x01F1 ; // HRESULT(0x800401F1)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_ALREADYINITIALIZED
.

MessageId = 0x01F2 ; // HRESULT(0x800401F2)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_CANTDETERMINECLASS
.

MessageId = 0x01F3 ; // HRESULT(0x800401F3)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_CLASSSTRING
.

MessageId = 0x01F4 ; // HRESULT(0x800401F4)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_IIDSTRING
.

MessageId = 0x01F5 ; // HRESULT(0x800401F5)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_APPNOTFOUND
.

MessageId = 0x01F6 ; // HRESULT(0x800401F6)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_APPSINGLEUSE
.

MessageId = 0x01F7 ; // HRESULT(0x800401F7)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_ERRORINAPP
.

MessageId = 0x01F8 ; // HRESULT(0x800401F8)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_DLLNOTFOUND
.

MessageId = 0x01F9 ; // HRESULT(0x800401F9)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_ERRORINDLL
.

MessageId = 0x01FA ; // HRESULT(0x800401FA)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_WRONGOSFORAPP
.

MessageId = 0x01FB ; // HRESULT(0x800401FB)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_OBJNOTREG
.

MessageId = 0x01FC ; // HRESULT(0x800401FC)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_OBJISREG
.

MessageId = 0x01FD ; // HRESULT(0x800401FD)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_OBJNOTCONNECTED
.

MessageId = 0x01FE ; // HRESULT(0x800401FE)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_APPDIDNTREG
.

MessageId = 0x01FF ; // HRESULT(0x800401FF)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_RELEASED
.

MessageId = 0x0201 ; // HRESULT(0x80040201)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
EVENT_E_ALL_SUBSCRIBERS_FAILED
.

MessageId = 0x0203 ; // HRESULT(0x80040203)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
EVENT_E_QUERYSYNTAX
.

MessageId = 0x0204 ; // HRESULT(0x80040204)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
EVENT_E_QUERYFIELD
.

MessageId = 0x0205 ; // HRESULT(0x80040205)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
EVENT_E_INTERNALEXCEPTION
.

MessageId = 0x0206 ; // HRESULT(0x80040206)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
EVENT_E_INTERNALERROR
.

MessageId = 0x0207 ; // HRESULT(0x80040207)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
EVENT_E_INVALID_PER_USER_SID
.

MessageId = 0x0208 ; // HRESULT(0x80040208)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
EVENT_E_USER_EXCEPTION
.

MessageId = 0x0209 ; // HRESULT(0x80040209)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
EVENT_E_TOO_MANY_METHODS
.

MessageId = 0x020A ; // HRESULT(0x8004020A)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
EVENT_E_MISSING_EVENTCLASS
.

MessageId = 0x020B ; // HRESULT(0x8004020B)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
EVENT_E_NOT_ALL_REMOVED
.

MessageId = 0x020C ; // HRESULT(0x8004020C)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
EVENT_E_COMPLUS_NOT_INSTALLED
.

MessageId = 0x020D ; // HRESULT(0x8004020D)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
EVENT_E_CANT_MODIFY_OR_DELETE_UNCONFIGURED_OBJECT
.

MessageId = 0x020E ; // HRESULT(0x8004020E)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
EVENT_E_CANT_MODIFY_OR_DELETE_CONFIGURED_OBJECT
.

MessageId = 0x020F ; // HRESULT(0x8004020F)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
EVENT_E_INVALID_EVENT_CLASS_PARTITION
.

MessageId = 0x0210 ; // HRESULT(0x80040210)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
EVENT_E_PER_USER_SID_NOT_LOGGED_ON
.

MessageId = 0x1309 ; // HRESULT(0x80041309)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_TRIGGER_NOT_FOUND
.

MessageId = 0x130A ; // HRESULT(0x8004130A)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_TASK_NOT_READY
.

MessageId = 0x130B ; // HRESULT(0x8004130B)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_TASK_NOT_RUNNING
.

MessageId = 0x130C ; // HRESULT(0x8004130C)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_SERVICE_NOT_INSTALLED
.

MessageId = 0x130D ; // HRESULT(0x8004130D)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_CANNOT_OPEN_TASK
.

MessageId = 0x130E ; // HRESULT(0x8004130E)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_INVALID_TASK
.

MessageId = 0x130F ; // HRESULT(0x8004130F)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_ACCOUNT_INFORMATION_NOT_SET
.

MessageId = 0x1310 ; // HRESULT(0x80041310)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_ACCOUNT_NAME_NOT_FOUND
.

MessageId = 0x1311 ; // HRESULT(0x80041311)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_ACCOUNT_DBASE_CORRUPT
.

MessageId = 0x1312 ; // HRESULT(0x80041312)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_NO_SECURITY_SERVICES
.

MessageId = 0x1313 ; // HRESULT(0x80041313)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_UNKNOWN_OBJECT_VERSION
.

MessageId = 0x1314 ; // HRESULT(0x80041314)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_UNSUPPORTED_ACCOUNT_OPTION
.

MessageId = 0x1315 ; // HRESULT(0x80041315)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_SERVICE_NOT_RUNNING
.

MessageId = 0x1316 ; // HRESULT(0x80041316)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_UNEXPECTEDNODE
.

MessageId = 0x1317 ; // HRESULT(0x80041317)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_NAMESPACE
.

MessageId = 0x1318 ; // HRESULT(0x80041318)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_INVALIDVALUE
.

MessageId = 0x1319 ; // HRESULT(0x80041319)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_MISSINGNODE
.

MessageId = 0x131A ; // HRESULT(0x8004131A)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_MALFORMEDXML
.

MessageId = 0x131D ; // HRESULT(0x8004131D)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_TOO_MANY_NODES
.

MessageId = 0x131E ; // HRESULT(0x8004131E)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_PAST_END_BOUNDARY
.

MessageId = 0x131F ; // HRESULT(0x8004131F)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_ALREADY_RUNNING
.

MessageId = 0x1320 ; // HRESULT(0x80041320)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_USER_NOT_LOGGED_ON
.

MessageId = 0x1321 ; // HRESULT(0x80041321)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_INVALID_TASK_HASH
.

MessageId = 0x1322 ; // HRESULT(0x80041322)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_SERVICE_NOT_AVAILABLE
.

MessageId = 0x1323 ; // HRESULT(0x80041323)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_SERVICE_TOO_BUSY
.

MessageId = 0x1324 ; // HRESULT(0x80041324)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_TASK_ATTEMPTED
.

MessageId = 0x1326 ; // HRESULT(0x80041326)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_TASK_DISABLED
.

MessageId = 0x1327 ; // HRESULT(0x80041327)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_TASK_NOT_V1_COMPAT
.

MessageId = 0x1328 ; // HRESULT(0x80041328)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_START_ON_DEMAND
.

MessageId = 0x1329 ; // HRESULT(0x80041329)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_TASK_NOT_UBPM_COMPAT
.

MessageId = 0x1330 ; // HRESULT(0x80041330)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
SCHED_E_DEPRECATED_FEATURE_USED
.

MessageId = 0xE002 ; // HRESULT(0x8004E002)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CONTEXT_E_ABORTED
.

MessageId = 0xE003 ; // HRESULT(0x8004E003)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CONTEXT_E_ABORTING
.

MessageId = 0xE004 ; // HRESULT(0x8004E004)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CONTEXT_E_NOCONTEXT
.

MessageId = 0xE005 ; // HRESULT(0x8004E005)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CONTEXT_E_WOULD_DEADLOCK
.

MessageId = 0xE006 ; // HRESULT(0x8004E006)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CONTEXT_E_SYNCH_TIMEOUT
.

MessageId = 0xE007 ; // HRESULT(0x8004E007)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CONTEXT_E_OLDREF
.

MessageId = 0xE00C ; // HRESULT(0x8004E00C)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CONTEXT_E_ROLENOTFOUND
.

MessageId = 0xE00F ; // HRESULT(0x8004E00F)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CONTEXT_E_TMNOTAVAILABLE
.

MessageId = 0xE021 ; // HRESULT(0x8004E021)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_ACTIVATIONFAILED
.

MessageId = 0xE022 ; // HRESULT(0x8004E022)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_ACTIVATIONFAILED_EVENTLOGGED
.

MessageId = 0xE023 ; // HRESULT(0x8004E023)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_ACTIVATIONFAILED_CATALOGERROR
.

MessageId = 0xE024 ; // HRESULT(0x8004E024)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_ACTIVATIONFAILED_TIMEOUT
.

MessageId = 0xE025 ; // HRESULT(0x8004E025)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_INITIALIZATIONFAILED
.

MessageId = 0xE026 ; // HRESULT(0x8004E026)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CONTEXT_E_NOJIT
.

MessageId = 0xE027 ; // HRESULT(0x8004E027)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CONTEXT_E_NOTRANSACTION
.

MessageId = 0xE028 ; // HRESULT(0x8004E028)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_THREADINGMODEL_CHANGED
.

MessageId = 0xE029 ; // HRESULT(0x8004E029)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_NOIISINTRINSICS
.

MessageId = 0xE02A ; // HRESULT(0x8004E02A)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_NOCOOKIES
.

MessageId = 0xE02B ; // HRESULT(0x8004E02B)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_DBERROR
.

MessageId = 0xE02C ; // HRESULT(0x8004E02C)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_NOTPOOLED
.

MessageId = 0xE02D ; // HRESULT(0x8004E02D)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_NOTCONSTRUCTED
.

MessageId = 0xE02E ; // HRESULT(0x8004E02E)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_NOSYNCHRONIZATION
.

MessageId = 0xE02F ; // HRESULT(0x8004E02F)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_ISOLEVELMISMATCH
.

MessageId = 0xE030 ; // HRESULT(0x8004E030)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_CALL_OUT_OF_TX_SCOPE_NOT_ALLOWED
.

MessageId = 0xE031 ; // HRESULT(0x8004E031)
Severity = Warning
Facility = HRESULT_Interface
Language = Neutral
CO_E_EXIT_TRANSACTION_SCOPE_NOT_CALLED
.

MessageId = 0x0001 ; // HRESULT(0x80080001)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
CO_E_CLASS_CREATE_FAILED
.

MessageId = 0x0002 ; // HRESULT(0x80080002)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
CO_E_SCM_ERROR
.

MessageId = 0x0003 ; // HRESULT(0x80080003)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
CO_E_SCM_RPC_FAILURE
.

MessageId = 0x0004 ; // HRESULT(0x80080004)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
CO_E_BAD_PATH
.

MessageId = 0x0005 ; // HRESULT(0x80080005)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
CO_E_SERVER_EXEC_FAILURE
.

MessageId = 0x0006 ; // HRESULT(0x80080006)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
CO_E_OBJSRV_RPC_FAILURE
.

MessageId = 0x0007 ; // HRESULT(0x80080007)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
MK_E_NO_NORMALIZED
.

MessageId = 0x0008 ; // HRESULT(0x80080008)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
CO_E_SERVER_STOPPING
.

MessageId = 0x0009 ; // HRESULT(0x80080009)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
MEM_E_INVALID_ROOT
.

MessageId = 0x0010 ; // HRESULT(0x80080010)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
MEM_E_INVALID_LINK
.

MessageId = 0x0011 ; // HRESULT(0x80080011)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
MEM_E_INVALID_SIZE
.

MessageId = 0x0015 ; // HRESULT(0x80080015)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
CO_E_MISSING_DISPLAYNAME
.

MessageId = 0x0016 ; // HRESULT(0x80080016)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
CO_E_RUNAS_VALUE_MUST_BE_AAA
.

MessageId = 0x0017 ; // HRESULT(0x80080017)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
CO_E_ELEVATION_DISABLED
.

MessageId = 0x0200 ; // HRESULT(0x80080200)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_PACKAGING_INTERNAL
.

MessageId = 0x0201 ; // HRESULT(0x80080201)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_INTERLEAVING_NOT_ALLOWED
.

MessageId = 0x0202 ; // HRESULT(0x80080202)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_RELATIONSHIPS_NOT_ALLOWED
.

MessageId = 0x0203 ; // HRESULT(0x80080203)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_MISSING_REQUIRED_FILE
.

MessageId = 0x0204 ; // HRESULT(0x80080204)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_INVALID_MANIFEST
.

MessageId = 0x0205 ; // HRESULT(0x80080205)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_INVALID_BLOCKMAP
.

MessageId = 0x0206 ; // HRESULT(0x80080206)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_CORRUPT_CONTENT
.

MessageId = 0x0207 ; // HRESULT(0x80080207)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_BLOCK_HASH_INVALID
.

MessageId = 0x0208 ; // HRESULT(0x80080208)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_REQUESTED_RANGE_TOO_LARGE
.

MessageId = 0x0209 ; // HRESULT(0x80080209)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_INVALID_SIP_CLIENT_DATA
.

MessageId = 0x020A ; // HRESULT(0x8008020A)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_INVALID_KEY_INFO
.

MessageId = 0x020B ; // HRESULT(0x8008020B)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_INVALID_CONTENTGROUPMAP
.

MessageId = 0x020C ; // HRESULT(0x8008020C)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_INVALID_APPINSTALLER
.

MessageId = 0x020D ; // HRESULT(0x8008020D)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_DELTA_BASELINE_VERSION_MISMATCH
.

MessageId = 0x020E ; // HRESULT(0x8008020E)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_DELTA_PACKAGE_MISSING_FILE
.

MessageId = 0x020F ; // HRESULT(0x8008020F)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_INVALID_DELTA_PACKAGE
.

MessageId = 0x0210 ; // HRESULT(0x80080210)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_DELTA_APPENDED_PACKAGE_NOT_ALLOWED
.

MessageId = 0x0211 ; // HRESULT(0x80080211)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_INVALID_PACKAGING_LAYOUT
.

MessageId = 0x0212 ; // HRESULT(0x80080212)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_INVALID_PACKAGESIGNCONFIG
.

MessageId = 0x0213 ; // HRESULT(0x80080213)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_RESOURCESPRI_NOT_ALLOWED
.

MessageId = 0x0214 ; // HRESULT(0x80080214)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_FILE_COMPRESSION_MISMATCH
.

MessageId = 0x0215 ; // HRESULT(0x80080215)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_INVALID_PAYLOAD_PACKAGE_EXTENSION
.

MessageId = 0x0216 ; // HRESULT(0x80080216)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_INVALID_ENCRYPTION_EXCLUSION_FILE_LIST
.

MessageId = 0x0217 ; // HRESULT(0x80080217)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_INVALID_PACKAGE_FOLDER_ACLS
.

MessageId = 0x0218 ; // HRESULT(0x80080218)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
APPX_E_INVALID_PUBLISHER_BRIDGING
.

MessageId = 0x7019 ; // HRESULT(0x80097019)
Severity = Warning
Facility = HRESULT_Security
Language = Neutral
ERROR_CRED_REQUIRES_CONFIRMATION
.

MessageId = 0x8000 ; // HRESULT(0x801B8000)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
WER_E_CRASH_FAILURE
.

MessageId = 0x8001 ; // HRESULT(0x801B8001)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
WER_E_CANCELED
.

MessageId = 0x8002 ; // HRESULT(0x801B8002)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
WER_E_NETWORK_FAILURE
.

MessageId = 0x8003 ; // HRESULT(0x801B8003)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
WER_E_NOT_INITIALIZED
.

MessageId = 0x8004 ; // HRESULT(0x801B8004)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
WER_E_ALREADY_REPORTING
.

MessageId = 0x8005 ; // HRESULT(0x801B8005)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
WER_E_DUMP_THROTTLED
.

MessageId = 0x8006 ; // HRESULT(0x801B8006)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
WER_E_INSUFFICIENT_CONSENT
.

MessageId = 0x8007 ; // HRESULT(0x801B8007)
Severity = Warning
Facility = HRESULT_Windows
Language = Neutral
WER_E_TOO_HEAVY
.

MessageId = 0x0001 ; // HRESULT(0x80260001)
Severity = Warning
Facility = HRESULT_Graphics
Language = Neutral
ERROR_HUNG_DISPLAY_DRIVER_THREAD
.

MessageId = 0x3001 ; // HRESULT(0x80263001)
Severity = Warning
Facility = HRESULT_Graphics
Language = Neutral
DWM_E_COMPOSITIONDISABLED
.

MessageId = 0x3002 ; // HRESULT(0x80263002)
Severity = Warning
Facility = HRESULT_Graphics
Language = Neutral
DWM_E_REMOTING_NOT_SUPPORTED
.

MessageId = 0x3003 ; // HRESULT(0x80263003)
Severity = Warning
Facility = HRESULT_Graphics
Language = Neutral
DWM_E_NO_REDIRECTION_SURFACE_AVAILABLE
.

MessageId = 0x3004 ; // HRESULT(0x80263004)
Severity = Warning
Facility = HRESULT_Graphics
Language = Neutral
DWM_E_NOT_QUEUING_PRESENTS
.

MessageId = 0x3005 ; // HRESULT(0x80263005)
Severity = Warning
Facility = HRESULT_Graphics
Language = Neutral
DWM_E_ADAPTER_NOT_FOUND
.

MessageId = 0x3007 ; // HRESULT(0x80263007)
Severity = Warning
Facility = HRESULT_Graphics
Language = Neutral
DWM_E_TEXTURE_TOO_LARGE
.

MessageId = 0x0250 ; // HRESULT(0x80270250)
Severity = Warning
Facility = HRESULT_Shell
Language = Neutral
E_MONITOR_RESOLUTION_TOO_LOW
.

MessageId = 0x0251 ; // HRESULT(0x80270251)
Severity = Warning
Facility = HRESULT_Shell
Language = Neutral
E_ELEVATED_ACTIVATION_NOT_SUPPORTED
.

MessageId = 0x0252 ; // HRESULT(0x80270252)
Severity = Warning
Facility = HRESULT_Shell
Language = Neutral
E_UAC_DISABLED
.

MessageId = 0x0253 ; // HRESULT(0x80270253)
Severity = Warning
Facility = HRESULT_Shell
Language = Neutral
E_FULL_ADMIN_NOT_SUPPORTED
.

MessageId = 0x0254 ; // HRESULT(0x80270254)
Severity = Warning
Facility = HRESULT_Shell
Language = Neutral
E_APPLICATION_NOT_REGISTERED
.

MessageId = 0x0255 ; // HRESULT(0x80270255)
Severity = Warning
Facility = HRESULT_Shell
Language = Neutral
E_MULTIPLE_EXTENSIONS_FOR_APPLICATION
.

MessageId = 0x0256 ; // HRESULT(0x80270256)
Severity = Warning
Facility = HRESULT_Shell
Language = Neutral
E_MULTIPLE_PACKAGES_FOR_FAMILY
.

MessageId = 0x0257 ; // HRESULT(0x80270257)
Severity = Warning
Facility = HRESULT_Shell
Language = Neutral
E_APPLICATION_MANAGER_NOT_RUNNING
.

MessageId = 0x025A ; // HRESULT(0x8027025A)
Severity = Warning
Facility = HRESULT_Shell
Language = Neutral
E_APPLICATION_ACTIVATION_TIMED_OUT
.

MessageId = 0x025B ; // HRESULT(0x8027025B)
Severity = Warning
Facility = HRESULT_Shell
Language = Neutral
E_APPLICATION_ACTIVATION_EXEC_FAILURE
.

MessageId = 0x025C ; // HRESULT(0x8027025C)
Severity = Warning
Facility = HRESULT_Shell
Language = Neutral
E_APPLICATION_TEMPORARY_LICENSE_ERROR
.

MessageId = 0x025D ; // HRESULT(0x8027025D)
Severity = Warning
Facility = HRESULT_Shell
Language = Neutral
E_APPLICATION_TRIAL_LICENSE_EXPIRED
.

; /* Error */

MessageId = 0x0001 ; // HRESULT(0xC0090001)
Severity = Error
Facility = HRESULT_Security
Language = Neutral
ERROR_AUDITING_DISABLED
.

MessageId = 0x0002 ; // HRESULT(0xC0090002)
Severity = Error
Facility = HRESULT_Security
Language = Neutral
ERROR_ALL_SIDS_FILTERED
.

MessageId = 0x0003 ; // HRESULT(0xC0090003)
Severity = Error
Facility = HRESULT_Security
Language = Neutral
ERROR_BIZRULES_NOT_ENABLED
.

MessageId = 0x0001 ; // HRESULT(0xC0380001)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DATABASE_FULL
.

MessageId = 0x0002 ; // HRESULT(0xC0380002)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_CONFIGURATION_CORRUPTED
.

MessageId = 0x0003 ; // HRESULT(0xC0380003)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_CONFIGURATION_NOT_IN_SYNC
.

MessageId = 0x0004 ; // HRESULT(0xC0380004)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PACK_CONFIG_UPDATE_FAILED
.

MessageId = 0x0005 ; // HRESULT(0xC0380005)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_CONTAINS_NON_SIMPLE_VOLUME
.

MessageId = 0x0006 ; // HRESULT(0xC0380006)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_DUPLICATE
.

MessageId = 0x0007 ; // HRESULT(0xC0380007)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_DYNAMIC
.

MessageId = 0x0008 ; // HRESULT(0xC0380008)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_ID_INVALID
.

MessageId = 0x0009 ; // HRESULT(0xC0380009)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_INVALID
.

MessageId = 0x000A ; // HRESULT(0xC038000A)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_LAST_VOTER
.

MessageId = 0x000B ; // HRESULT(0xC038000B)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_LAYOUT_INVALID
.

MessageId = 0x000C ; // HRESULT(0xC038000C)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_LAYOUT_NON_BASIC_BETWEEN_BASIC_PARTITIONS
.

MessageId = 0x000D ; // HRESULT(0xC038000D)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_LAYOUT_NOT_CYLINDER_ALIGNED
.

MessageId = 0x000E ; // HRESULT(0xC038000E)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_LAYOUT_PARTITIONS_TOO_SMALL
.

MessageId = 0x000F ; // HRESULT(0xC038000F)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_LAYOUT_PRIMARY_BETWEEN_LOGICAL_PARTITIONS
.

MessageId = 0x0010 ; // HRESULT(0xC0380010)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_LAYOUT_TOO_MANY_PARTITIONS
.

MessageId = 0x0011 ; // HRESULT(0xC0380011)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_MISSING
.

MessageId = 0x0012 ; // HRESULT(0xC0380012)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_NOT_EMPTY
.

MessageId = 0x0013 ; // HRESULT(0xC0380013)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_NOT_ENOUGH_SPACE
.

MessageId = 0x0014 ; // HRESULT(0xC0380014)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_REVECTORING_FAILED
.

MessageId = 0x0015 ; // HRESULT(0xC0380015)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_SECTOR_SIZE_INVALID
.

MessageId = 0x0016 ; // HRESULT(0xC0380016)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_SET_NOT_CONTAINED
.

MessageId = 0x0017 ; // HRESULT(0xC0380017)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_USED_BY_MULTIPLE_MEMBERS
.

MessageId = 0x0018 ; // HRESULT(0xC0380018)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DISK_USED_BY_MULTIPLE_PLEXES
.

MessageId = 0x0019 ; // HRESULT(0xC0380019)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DYNAMIC_DISK_NOT_SUPPORTED
.

MessageId = 0x001A ; // HRESULT(0xC038001A)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_EXTENT_ALREADY_USED
.

MessageId = 0x001B ; // HRESULT(0xC038001B)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_EXTENT_NOT_CONTIGUOUS
.

MessageId = 0x001C ; // HRESULT(0xC038001C)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_EXTENT_NOT_IN_PUBLIC_REGION
.

MessageId = 0x001D ; // HRESULT(0xC038001D)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_EXTENT_NOT_SECTOR_ALIGNED
.

MessageId = 0x001E ; // HRESULT(0xC038001E)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_EXTENT_OVERLAPS_EBR_PARTITION
.

MessageId = 0x001F ; // HRESULT(0xC038001F)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_EXTENT_VOLUME_LENGTHS_DO_NOT_MATCH
.

MessageId = 0x0020 ; // HRESULT(0xC0380020)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_FAULT_TOLERANT_NOT_SUPPORTED
.

MessageId = 0x0021 ; // HRESULT(0xC0380021)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_INTERLEAVE_LENGTH_INVALID
.

MessageId = 0x0022 ; // HRESULT(0xC0380022)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_MAXIMUM_REGISTERED_USERS
.

MessageId = 0x0023 ; // HRESULT(0xC0380023)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_MEMBER_IN_SYNC
.

MessageId = 0x0024 ; // HRESULT(0xC0380024)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_MEMBER_INDEX_DUPLICATE
.

MessageId = 0x0025 ; // HRESULT(0xC0380025)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_MEMBER_INDEX_INVALID
.

MessageId = 0x0026 ; // HRESULT(0xC0380026)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_MEMBER_MISSING
.

MessageId = 0x0027 ; // HRESULT(0xC0380027)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_MEMBER_NOT_DETACHED
.

MessageId = 0x0028 ; // HRESULT(0xC0380028)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_MEMBER_REGENERATING
.

MessageId = 0x0029 ; // HRESULT(0xC0380029)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_ALL_DISKS_FAILED
.

MessageId = 0x002A ; // HRESULT(0xC038002A)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_NO_REGISTERED_USERS
.

MessageId = 0x002B ; // HRESULT(0xC038002B)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_NO_SUCH_USER
.

MessageId = 0x002C ; // HRESULT(0xC038002C)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_NOTIFICATION_RESET
.

MessageId = 0x002D ; // HRESULT(0xC038002D)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_NUMBER_OF_MEMBERS_INVALID
.

MessageId = 0x002E ; // HRESULT(0xC038002E)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_NUMBER_OF_PLEXES_INVALID
.

MessageId = 0x002F ; // HRESULT(0xC038002F)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PACK_DUPLICATE
.

MessageId = 0x0030 ; // HRESULT(0xC0380030)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PACK_ID_INVALID
.

MessageId = 0x0031 ; // HRESULT(0xC0380031)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PACK_INVALID
.

MessageId = 0x0032 ; // HRESULT(0xC0380032)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PACK_NAME_INVALID
.

MessageId = 0x0033 ; // HRESULT(0xC0380033)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PACK_OFFLINE
.

MessageId = 0x0034 ; // HRESULT(0xC0380034)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PACK_HAS_QUORUM
.

MessageId = 0x0035 ; // HRESULT(0xC0380035)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PACK_WITHOUT_QUORUM
.

MessageId = 0x0036 ; // HRESULT(0xC0380036)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PARTITION_STYLE_INVALID
.

MessageId = 0x0037 ; // HRESULT(0xC0380037)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PARTITION_UPDATE_FAILED
.

MessageId = 0x0038 ; // HRESULT(0xC0380038)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PLEX_IN_SYNC
.

MessageId = 0x0039 ; // HRESULT(0xC0380039)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PLEX_INDEX_DUPLICATE
.

MessageId = 0x003A ; // HRESULT(0xC038003A)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PLEX_INDEX_INVALID
.

MessageId = 0x003B ; // HRESULT(0xC038003B)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PLEX_LAST_ACTIVE
.

MessageId = 0x003C ; // HRESULT(0xC038003C)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PLEX_MISSING
.

MessageId = 0x003D ; // HRESULT(0xC038003D)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PLEX_REGENERATING
.

MessageId = 0x003E ; // HRESULT(0xC038003E)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PLEX_TYPE_INVALID
.

MessageId = 0x003F ; // HRESULT(0xC038003F)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PLEX_NOT_RAID5
.

MessageId = 0x0040 ; // HRESULT(0xC0380040)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PLEX_NOT_SIMPLE
.

MessageId = 0x0041 ; // HRESULT(0xC0380041)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_STRUCTURE_SIZE_INVALID
.

MessageId = 0x0042 ; // HRESULT(0xC0380042)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_TOO_MANY_NOTIFICATION_REQUESTS
.

MessageId = 0x0043 ; // HRESULT(0xC0380043)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_TRANSACTION_IN_PROGRESS
.

MessageId = 0x0044 ; // HRESULT(0xC0380044)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_UNEXPECTED_DISK_LAYOUT_CHANGE
.

MessageId = 0x0045 ; // HRESULT(0xC0380045)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_VOLUME_CONTAINS_MISSING_DISK
.

MessageId = 0x0046 ; // HRESULT(0xC0380046)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_VOLUME_ID_INVALID
.

MessageId = 0x0047 ; // HRESULT(0xC0380047)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_VOLUME_LENGTH_INVALID
.

MessageId = 0x0048 ; // HRESULT(0xC0380048)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_VOLUME_LENGTH_NOT_SECTOR_SIZE_MULTIPLE
.

MessageId = 0x0049 ; // HRESULT(0xC0380049)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_VOLUME_NOT_MIRRORED
.

MessageId = 0x004A ; // HRESULT(0xC038004A)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_VOLUME_NOT_RETAINED
.

MessageId = 0x004B ; // HRESULT(0xC038004B)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_VOLUME_OFFLINE
.

MessageId = 0x004C ; // HRESULT(0xC038004C)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_VOLUME_RETAINED
.

MessageId = 0x004D ; // HRESULT(0xC038004D)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_NUMBER_OF_EXTENTS_INVALID
.

MessageId = 0x004E ; // HRESULT(0xC038004E)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_DIFFERENT_SECTOR_SIZE
.

MessageId = 0x004F ; // HRESULT(0xC038004F)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_BAD_BOOT_DISK
.

MessageId = 0x0050 ; // HRESULT(0xC0380050)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PACK_CONFIG_OFFLINE
.

MessageId = 0x0051 ; // HRESULT(0xC0380051)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PACK_CONFIG_ONLINE
.

MessageId = 0x0052 ; // HRESULT(0xC0380052)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_NOT_PRIMARY_PACK
.

MessageId = 0x0053 ; // HRESULT(0xC0380053)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PACK_LOG_UPDATE_FAILED
.

MessageId = 0x0054 ; // HRESULT(0xC0380054)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_NUMBER_OF_DISKS_IN_PLEX_INVALID
.

MessageId = 0x0055 ; // HRESULT(0xC0380055)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_NUMBER_OF_DISKS_IN_MEMBER_INVALID
.

MessageId = 0x0056 ; // HRESULT(0xC0380056)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_VOLUME_MIRRORED
.

MessageId = 0x0057 ; // HRESULT(0xC0380057)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PLEX_NOT_SIMPLE_SPANNED
.

MessageId = 0x0058 ; // HRESULT(0xC0380058)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_NO_VALID_LOG_COPIES
.

MessageId = 0x0059 ; // HRESULT(0xC0380059)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_PRIMARY_PACK_PRESENT
.

MessageId = 0x005A ; // HRESULT(0xC038005A)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_NUMBER_OF_DISKS_INVALID
.

MessageId = 0x005B ; // HRESULT(0xC038005B)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_MIRROR_NOT_SUPPORTED
.

MessageId = 0x005C ; // HRESULT(0xC038005C)
Severity = Error
Facility = HRESULT_VolMgr
Language = Neutral
ERROR_VOLMGR_RAID5_NOT_SUPPORTED
.

MessageId = 0x0002 ; // HRESULT(0xC0390002)
Severity = Error
Facility = HRESULT_BCD
Language = Neutral
ERROR_BCD_TOO_MANY_ELEMENTS
.

MessageId = 0x0001 ; // HRESULT(0xC03A0001)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_DRIVE_FOOTER_MISSING
.

MessageId = 0x0002 ; // HRESULT(0xC03A0002)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_DRIVE_FOOTER_CHECKSUM_MISMATCH
.

MessageId = 0x0003 ; // HRESULT(0xC03A0003)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_DRIVE_FOOTER_CORRUPT
.

MessageId = 0x0004 ; // HRESULT(0xC03A0004)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_FORMAT_UNKNOWN
.

MessageId = 0x0005 ; // HRESULT(0xC03A0005)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_FORMAT_UNSUPPORTED_VERSION
.

MessageId = 0x0006 ; // HRESULT(0xC03A0006)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_SPARSE_HEADER_CHECKSUM_MISMATCH
.

MessageId = 0x0007 ; // HRESULT(0xC03A0007)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_SPARSE_HEADER_UNSUPPORTED_VERSION
.

MessageId = 0x0008 ; // HRESULT(0xC03A0008)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_SPARSE_HEADER_CORRUPT
.

MessageId = 0x0009 ; // HRESULT(0xC03A0009)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_BLOCK_ALLOCATION_FAILURE
.

MessageId = 0x000A ; // HRESULT(0xC03A000A)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_BLOCK_ALLOCATION_TABLE_CORRUPT
.

MessageId = 0x000B ; // HRESULT(0xC03A000B)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_INVALID_BLOCK_SIZE
.

MessageId = 0x000C ; // HRESULT(0xC03A000C)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_BITMAP_MISMATCH
.

MessageId = 0x000D ; // HRESULT(0xC03A000D)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_PARENT_VHD_NOT_FOUND
.

MessageId = 0x000E ; // HRESULT(0xC03A000E)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_CHILD_PARENT_ID_MISMATCH
.

MessageId = 0x000F ; // HRESULT(0xC03A000F)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_CHILD_PARENT_TIMESTAMP_MISMATCH
.

MessageId = 0x0010 ; // HRESULT(0xC03A0010)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_METADATA_READ_FAILURE
.

MessageId = 0x0011 ; // HRESULT(0xC03A0011)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_METADATA_WRITE_FAILURE
.

MessageId = 0x0012 ; // HRESULT(0xC03A0012)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_INVALID_SIZE
.

MessageId = 0x0013 ; // HRESULT(0xC03A0013)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_INVALID_FILE_SIZE
.

MessageId = 0x0014 ; // HRESULT(0xC03A0014)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VIRTDISK_PROVIDER_NOT_FOUND
.

MessageId = 0x0015 ; // HRESULT(0xC03A0015)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VIRTDISK_NOT_VIRTUAL_DISK
.

MessageId = 0x0016 ; // HRESULT(0xC03A0016)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_PARENT_VHD_ACCESS_DENIED
.

MessageId = 0x0017 ; // HRESULT(0xC03A0017)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_CHILD_PARENT_SIZE_MISMATCH
.

MessageId = 0x0018 ; // HRESULT(0xC03A0018)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_DIFFERENCING_CHAIN_CYCLE_DETECTED
.

MessageId = 0x0019 ; // HRESULT(0xC03A0019)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_DIFFERENCING_CHAIN_ERROR_IN_PARENT
.

MessageId = 0x001A ; // HRESULT(0xC03A001A)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VIRTUAL_DISK_LIMITATION
.

MessageId = 0x001B ; // HRESULT(0xC03A001B)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_INVALID_TYPE
.

MessageId = 0x001C ; // HRESULT(0xC03A001C)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_INVALID_STATE
.

MessageId = 0x001D ; // HRESULT(0xC03A001D)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VIRTDISK_UNSUPPORTED_DISK_SECTOR_SIZE
.

MessageId = 0x001E ; // HRESULT(0xC03A001E)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VIRTDISK_DISK_ALREADY_OWNED
.

MessageId = 0x001F ; // HRESULT(0xC03A001F)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VIRTDISK_DISK_ONLINE_AND_WRITABLE
.

MessageId = 0x0020 ; // HRESULT(0xC03A0020)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_CTLOG_TRACKING_NOT_INITIALIZED
.

MessageId = 0x0021 ; // HRESULT(0xC03A0021)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_CTLOG_LOGFILE_SIZE_EXCEEDED_MAXSIZE
.

MessageId = 0x0022 ; // HRESULT(0xC03A0022)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_CTLOG_VHD_CHANGED_OFFLINE
.

MessageId = 0x0023 ; // HRESULT(0xC03A0023)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_CTLOG_INVALID_TRACKING_STATE
.

MessageId = 0x0024 ; // HRESULT(0xC03A0024)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_CTLOG_INCONSISTENT_TRACKING_FILE
.

MessageId = 0x0025 ; // HRESULT(0xC03A0025)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_RESIZE_WOULD_TRUNCATE_DATA
.

MessageId = 0x0026 ; // HRESULT(0xC03A0026)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_COULD_NOT_COMPUTE_MINIMUM_VIRTUAL_SIZE
.

MessageId = 0x0027 ; // HRESULT(0xC03A0027)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_ALREADY_AT_OR_BELOW_MINIMUM_VIRTUAL_SIZE
.

MessageId = 0x0028 ; // HRESULT(0xC03A0028)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_METADATA_FULL
.

MessageId = 0x0029 ; // HRESULT(0xC03A0029)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_INVALID_CHANGE_TRACKING_ID
.

MessageId = 0x002A ; // HRESULT(0xC03A002A)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_CHANGE_TRACKING_DISABLED
.

MessageId = 0x0030 ; // HRESULT(0xC03A0030)
Severity = Error
Facility = HRESULT_VHD
Language = Neutral
ERROR_VHD_MISSING_CHANGE_TRACKING_INFORMATION
.

;// ---------------------------- Win32 Errors ---------------------------- //

MessageId = 0 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SUCCESS
.

MessageId = 1 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_FUNCTION
.

MessageId = 2 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_NOT_FOUND
.

MessageId = 3 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PATH_NOT_FOUND
.

MessageId = 4 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_OPEN_FILES
.

MessageId = 5 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ACCESS_DENIED
.

MessageId = 6 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_HANDLE
.

MessageId = 7 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ARENA_TRASHED
.

MessageId = 8 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_ENOUGH_MEMORY
.

MessageId = 9 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_BLOCK
.

MessageId = 10 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_ENVIRONMENT
.

MessageId = 11 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_FORMAT
.

MessageId = 12 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_ACCESS
.

MessageId = 13 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_DATA
.

MessageId = 14 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OUTOFMEMORY
.

MessageId = 15 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_DRIVE
.

MessageId = 16 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CURRENT_DIRECTORY
.

MessageId = 17 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SAME_DEVICE
.

MessageId = 18 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_MORE_FILES
.

MessageId = 19 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WRITE_PROTECT
.

MessageId = 20 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_UNIT
.

MessageId = 21 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_READY
.

MessageId = 22 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_COMMAND
.

MessageId = 23 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CRC
.

MessageId = 24 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_LENGTH
.

MessageId = 25 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SEEK
.

MessageId = 26 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_DOS_DISK
.

MessageId = 27 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SECTOR_NOT_FOUND
.

MessageId = 28 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OUT_OF_PAPER
.

MessageId = 29 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WRITE_FAULT
.

MessageId = 30 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_READ_FAULT
.

MessageId = 31 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_GEN_FAILURE
.

MessageId = 32 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SHARING_VIOLATION
.

MessageId = 33 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOCK_VIOLATION
.

MessageId = 34 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WRONG_DISK
.

MessageId = 36 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SHARING_BUFFER_EXCEEDED
.

MessageId = 38 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HANDLE_EOF
.

MessageId = 39 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HANDLE_DISK_FULL
.

MessageId = 50 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SUPPORTED
.

MessageId = 51 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REM_NOT_LIST
.

MessageId = 52 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DUP_NAME
.

MessageId = 53 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_NETPATH
.

MessageId = 54 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NETWORK_BUSY
.

MessageId = 55 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEV_NOT_EXIST
.

MessageId = 56 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_CMDS
.

MessageId = 57 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ADAP_HDW_ERR
.

MessageId = 58 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_NET_RESP
.

MessageId = 59 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNEXP_NET_ERR
.

MessageId = 60 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_REM_ADAP
.

MessageId = 62 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SPOOL_SPACE
.

MessageId = 64 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NETNAME_DELETED
.

MessageId = 65 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NETWORK_ACCESS_DENIED
.

MessageId = 66 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_DEV_TYPE
.

MessageId = 67 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_NET_NAME
.

MessageId = 68 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_NAMES
.

MessageId = 69 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_SESS
.

MessageId = 70 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SHARING_PAUSED
.

MessageId = 71 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REQ_NOT_ACCEP
.

MessageId = 72 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REDIR_PAUSED
.

MessageId = 80 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_EXISTS
.

MessageId = 82 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANNOT_MAKE
.

MessageId = 83 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FAIL_I24
.

MessageId = 84 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OUT_OF_STRUCTURES
.

MessageId = 85 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ALREADY_ASSIGNED
.

MessageId = 86 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_PASSWORD
.

MessageId = 87 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_PARAMETER
.

MessageId = 88 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NET_WRITE_FAULT
.

MessageId = 89 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_PROC_SLOTS
.

MessageId = 100 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_SEMAPHORES
.

MessageId = 101 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EXCL_SEM_ALREADY_OWNED
.

MessageId = 102 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SEM_IS_SET
.

MessageId = 103 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_SEM_REQUESTS
.

MessageId = 104 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_AT_INTERRUPT_TIME
.

MessageId = 105 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SEM_OWNER_DIED
.

MessageId = 106 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SEM_USER_LIMIT
.

MessageId = 107 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DISK_CHANGE
.

MessageId = 108 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DRIVE_LOCKED
.

MessageId = 109 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BROKEN_PIPE
.

MessageId = 110 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OPEN_FAILED
.

MessageId = 111 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BUFFER_OVERFLOW
.

MessageId = 112 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DISK_FULL
.

MessageId = 113 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_MORE_SEARCH_HANDLES
.

MessageId = 114 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_TARGET_HANDLE
.

MessageId = 117 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_CATEGORY
.

MessageId = 118 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_VERIFY_SWITCH
.

MessageId = 119 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_DRIVER_LEVEL
.

MessageId = 120 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CALL_NOT_IMPLEMENTED
.

MessageId = 121 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SEM_TIMEOUT
.

MessageId = 122 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSUFFICIENT_BUFFER
.

MessageId = 123 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_NAME
.

MessageId = 124 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_LEVEL
.

MessageId = 125 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_VOLUME_LABEL
.

MessageId = 126 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MOD_NOT_FOUND
.

MessageId = 127 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PROC_NOT_FOUND
.

MessageId = 128 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WAIT_NO_CHILDREN
.

MessageId = 129 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CHILD_NOT_COMPLETE
.

MessageId = 130 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DIRECT_ACCESS_HANDLE
.

MessageId = 131 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NEGATIVE_SEEK
.

MessageId = 132 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SEEK_ON_DEVICE
.

MessageId = 133 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IS_JOIN_TARGET
.

MessageId = 134 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IS_JOINED
.

MessageId = 135 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IS_SUBSTED
.

MessageId = 136 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_JOINED
.

MessageId = 137 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SUBSTED
.

MessageId = 138 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_JOIN_TO_JOIN
.

MessageId = 139 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SUBST_TO_SUBST
.

MessageId = 140 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_JOIN_TO_SUBST
.

MessageId = 141 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SUBST_TO_JOIN
.

MessageId = 142 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BUSY_DRIVE
.

MessageId = 143 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SAME_DRIVE
.

MessageId = 144 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DIR_NOT_ROOT
.

MessageId = 145 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DIR_NOT_EMPTY
.

MessageId = 146 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IS_SUBST_PATH
.

MessageId = 147 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IS_JOIN_PATH
.

MessageId = 148 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PATH_BUSY
.

MessageId = 149 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IS_SUBST_TARGET
.

MessageId = 150 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_TRACE
.

MessageId = 151 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_EVENT_COUNT
.

MessageId = 152 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_MUXWAITERS
.

MessageId = 153 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_LIST_FORMAT
.

MessageId = 154 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LABEL_TOO_LONG
.

MessageId = 155 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_TCBS
.

MessageId = 156 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SIGNAL_REFUSED
.

MessageId = 157 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DISCARDED
.

MessageId = 158 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_LOCKED
.

MessageId = 159 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_THREADID_ADDR
.

MessageId = 160 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_ARGUMENTS
.

MessageId = 161 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_PATHNAME
.

MessageId = 162 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SIGNAL_PENDING
.

MessageId = 164 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MAX_THRDS_REACHED
.

MessageId = 167 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOCK_FAILED
.

MessageId = 170 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BUSY
.

MessageId = 171 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_SUPPORT_IN_PROGRESS
.

MessageId = 173 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANCEL_VIOLATION
.

MessageId = 174 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ATOMIC_LOCKS_NOT_SUPPORTED
.

MessageId = 180 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_SEGMENT_NUMBER
.

MessageId = 182 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_ORDINAL
.

MessageId = 183 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ALREADY_EXISTS
.

MessageId = 186 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_FLAG_NUMBER
.

MessageId = 187 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SEM_NOT_FOUND
.

MessageId = 188 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_STARTING_CODESEG
.

MessageId = 189 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_STACKSEG
.

MessageId = 190 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_MODULETYPE
.

MessageId = 191 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_EXE_SIGNATURE
.

MessageId = 192 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EXE_MARKED_INVALID
.

MessageId = 193 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_EXE_FORMAT
.

MessageId = 194 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ITERATED_DATA_EXCEEDS_64k
.

MessageId = 195 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_MINALLOCSIZE
.

MessageId = 196 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DYNLINK_FROM_INVALID_RING
.

MessageId = 197 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IOPL_NOT_ENABLED
.

MessageId = 198 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_SEGDPL
.

MessageId = 199 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_AUTODATASEG_EXCEEDS_64k
.

MessageId = 200 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RING2SEG_MUST_BE_MOVABLE
.

MessageId = 201 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RELOC_CHAIN_XEEDS_SEGLIM
.

MessageId = 202 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INFLOOP_IN_RELOC_CHAIN
.

MessageId = 203 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ENVVAR_NOT_FOUND
.

MessageId = 205 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SIGNAL_SENT
.

MessageId = 206 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILENAME_EXCED_RANGE
.

MessageId = 207 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RING2_STACK_IN_USE
.

MessageId = 208 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_META_EXPANSION_TOO_LONG
.

MessageId = 209 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_SIGNAL_NUMBER
.

MessageId = 210 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_THREAD_1_INACTIVE
.

MessageId = 212 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOCKED
.

MessageId = 214 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_MODULES
.

MessageId = 215 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NESTING_NOT_ALLOWED
.

MessageId = 216 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EXE_MACHINE_TYPE_MISMATCH
.

MessageId = 217 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EXE_CANNOT_MODIFY_SIGNED_BINARY
.

MessageId = 218 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EXE_CANNOT_MODIFY_STRONG_SIGNED_BINARY
.

MessageId = 220 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_CHECKED_OUT
.

MessageId = 221 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CHECKOUT_REQUIRED
.

MessageId = 222 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_FILE_TYPE
.

MessageId = 223 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_TOO_LARGE
.

MessageId = 224 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FORMS_AUTH_REQUIRED
.

MessageId = 225 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_VIRUS_INFECTED
.

MessageId = 226 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_VIRUS_DELETED
.

MessageId = 229 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PIPE_LOCAL
.

MessageId = 230 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_PIPE
.

MessageId = 231 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PIPE_BUSY
.

MessageId = 232 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_DATA
.

MessageId = 233 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PIPE_NOT_CONNECTED
.

MessageId = 234 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MORE_DATA
.

MessageId = 235 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_WORK_DONE
.

MessageId = 240 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_VC_DISCONNECTED
.

MessageId = 254 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_EA_NAME
.

MessageId = 255 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EA_LIST_INCONSISTENT
.

MessageId = 258 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
WAIT_TIMEOUT
.

MessageId = 259 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_MORE_ITEMS
.

MessageId = 266 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANNOT_COPY
.

MessageId = 267 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DIRECTORY
.

MessageId = 275 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EAS_DIDNT_FIT
.

MessageId = 276 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EA_FILE_CORRUPT
.

MessageId = 277 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EA_TABLE_FULL
.

MessageId = 278 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_EA_HANDLE
.

MessageId = 282 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EAS_NOT_SUPPORTED
.

MessageId = 288 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_OWNER
.

MessageId = 298 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_POSTS
.

MessageId = 299 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PARTIAL_COPY
.

MessageId = 300 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OPLOCK_NOT_GRANTED
.

MessageId = 301 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_OPLOCK_PROTOCOL
.

MessageId = 302 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DISK_TOO_FRAGMENTED
.

MessageId = 303 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DELETE_PENDING
.

MessageId = 304 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INCOMPATIBLE_WITH_GLOBAL_SHORT_NAME_REGISTRY_SETTING
.

MessageId = 305 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SHORT_NAMES_NOT_ENABLED_ON_VOLUME
.

MessageId = 306 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SECURITY_STREAM_IS_INCONSISTENT
.

MessageId = 307 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_LOCK_RANGE
.

MessageId = 308 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IMAGE_SUBSYSTEM_NOT_PRESENT
.

MessageId = 309 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOTIFICATION_GUID_ALREADY_DEFINED
.

MessageId = 310 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_EXCEPTION_HANDLER
.

MessageId = 311 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DUPLICATE_PRIVILEGES
.

MessageId = 312 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_RANGES_PROCESSED
.

MessageId = 313 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_ALLOWED_ON_SYSTEM_FILE
.

MessageId = 314 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DISK_RESOURCES_EXHAUSTED
.

MessageId = 315 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_TOKEN
.

MessageId = 316 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_FEATURE_NOT_SUPPORTED
.

MessageId = 317 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MR_MID_NOT_FOUND
.

MessageId = 318 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SCOPE_NOT_FOUND
.

MessageId = 319 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNDEFINED_SCOPE
.

MessageId = 320 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_CAP
.

MessageId = 321 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_UNREACHABLE
.

MessageId = 322 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_NO_RESOURCES
.

MessageId = 323 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DATA_CHECKSUM_ERROR
.

MessageId = 324 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INTERMIXED_KERNEL_EA_OPERATION
.

MessageId = 326 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_LEVEL_TRIM_NOT_SUPPORTED
.

MessageId = 327 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OFFSET_ALIGNMENT_VIOLATION
.

MessageId = 328 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_FIELD_IN_PARAMETER_LIST
.

MessageId = 329 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OPERATION_IN_PROGRESS
.

MessageId = 330 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_DEVICE_PATH
.

MessageId = 331 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_DESCRIPTORS
.

MessageId = 332 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SCRUB_DATA_DISABLED
.

MessageId = 333 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_REDUNDANT_STORAGE
.

MessageId = 334 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RESIDENT_FILE_NOT_SUPPORTED
.

MessageId = 335 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_COMPRESSED_FILE_NOT_SUPPORTED
.

MessageId = 336 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DIRECTORY_NOT_SUPPORTED
.

MessageId = 337 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_READ_FROM_COPY
.

MessageId = 338 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FT_WRITE_FAILURE
.

MessageId = 339 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FT_DI_SCAN_REQUIRED
.

MessageId = 340 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_KERNEL_INFO_VERSION
.

MessageId = 341 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_PEP_INFO_VERSION
.

MessageId = 342 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OBJECT_NOT_EXTERNALLY_BACKED
.

MessageId = 343 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EXTERNAL_BACKING_PROVIDER_UNKNOWN
.

MessageId = 344 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_COMPRESSION_NOT_BENEFICIAL
.

MessageId = 345 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STORAGE_TOPOLOGY_ID_MISMATCH
.

MessageId = 346 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BLOCKED_BY_PARENTAL_CONTROLS
.

MessageId = 347 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BLOCK_TOO_MANY_REFERENCES
.

MessageId = 348 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MARKED_TO_DISALLOW_WRITES
.

MessageId = 349 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ENCLAVE_FAILURE
.

MessageId = 350 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FAIL_NOACTION_REBOOT
.

MessageId = 351 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FAIL_SHUTDOWN
.

MessageId = 352 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FAIL_RESTART
.

MessageId = 353 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MAX_SESSIONS_REACHED
.

MessageId = 354 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NETWORK_ACCESS_DENIED_EDP
.

MessageId = 355 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_HINT_NAME_BUFFER_TOO_SMALL
.

MessageId = 356 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EDP_POLICY_DENIES_OPERATION
.

MessageId = 357 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EDP_DPL_POLICY_CANT_BE_SATISFIED
.

MessageId = 358 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_SYNC_ROOT_METADATA_CORRUPT
.

MessageId = 359 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_IN_MAINTENANCE
.

MessageId = 360 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SUPPORTED_ON_DAX
.

MessageId = 361 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DAX_MAPPING_EXISTS
.

MessageId = 362 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_PROVIDER_NOT_RUNNING
.

MessageId = 363 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_METADATA_CORRUPT
.

MessageId = 364 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_METADATA_TOO_LARGE
.

MessageId = 365 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_PROPERTY_BLOB_TOO_LARGE
.

MessageId = 366 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_PROPERTY_BLOB_CHECKSUM_MISMATCH
.

MessageId = 367 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CHILD_PROCESS_BLOCKED
.

MessageId = 368 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STORAGE_LOST_DATA_PERSISTENCE
.

MessageId = 369 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_SYSTEM_VIRTUALIZATION_UNAVAILABLE
.

MessageId = 370 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_SYSTEM_VIRTUALIZATION_METADATA_CORRUPT
.

MessageId = 371 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_SYSTEM_VIRTUALIZATION_BUSY
.

MessageId = 372 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_SYSTEM_VIRTUALIZATION_PROVIDER_UNKNOWN
.

MessageId = 373 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_GDI_HANDLE_LEAK
.

MessageId = 374 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_TOO_MANY_PROPERTY_BLOBS
.

MessageId = 375 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_PROPERTY_VERSION_NOT_SUPPORTED
.

MessageId = 376 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_A_CLOUD_FILE
.

MessageId = 377 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_NOT_IN_SYNC
.

MessageId = 378 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_ALREADY_CONNECTED
.

MessageId = 379 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_NOT_SUPPORTED
.

MessageId = 380 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_INVALID_REQUEST
.

MessageId = 381 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_READ_ONLY_VOLUME
.

MessageId = 382 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_CONNECTED_PROVIDER_ONLY
.

MessageId = 383 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_VALIDATION_FAILED
.

MessageId = 384 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SMB1_NOT_AVAILABLE
.

MessageId = 385 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_SYSTEM_VIRTUALIZATION_INVALID_OPERATION
.

MessageId = 386 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_AUTHENTICATION_FAILED
.

MessageId = 387 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_INSUFFICIENT_RESOURCES
.

MessageId = 388 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_NETWORK_UNAVAILABLE
.

MessageId = 389 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_UNSUCCESSFUL
.

MessageId = 390 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_NOT_UNDER_SYNC_ROOT
.

MessageId = 391 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_IN_USE
.

MessageId = 392 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_PINNED
.

MessageId = 393 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_REQUEST_ABORTED
.

MessageId = 394 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_PROPERTY_CORRUPT
.

MessageId = 395 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_ACCESS_DENIED
.

MessageId = 396 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_INCOMPATIBLE_HARDLINKS
.

MessageId = 397 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_PROPERTY_LOCK_CONFLICT
.

MessageId = 398 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_REQUEST_CANCELED
.

MessageId = 399 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EXTERNAL_SYSKEY_NOT_SUPPORTED
.

MessageId = 400 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_THREAD_MODE_ALREADY_BACKGROUND
.

MessageId = 401 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_THREAD_MODE_NOT_BACKGROUND
.

MessageId = 402 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PROCESS_MODE_ALREADY_BACKGROUND
.

MessageId = 403 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PROCESS_MODE_NOT_BACKGROUND
.

MessageId = 404 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_PROVIDER_TERMINATED
.

MessageId = 405 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_A_CLOUD_SYNC_ROOT
.

MessageId = 406 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_PROTECTED_UNDER_DPL
.

MessageId = 407 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_VOLUME_NOT_CLUSTER_ALIGNED
.

MessageId = 408 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_PHYSICALLY_ALIGNED_FREE_SPACE_FOUND
.

MessageId = 409 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPX_FILE_NOT_ENCRYPTED
.

MessageId = 410 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RWRAW_ENCRYPTED_FILE_NOT_ENCRYPTED
.

MessageId = 411 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RWRAW_ENCRYPTED_INVALID_EDATAINFO_FILEOFFSET
.

MessageId = 412 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RWRAW_ENCRYPTED_INVALID_EDATAINFO_FILERANGE
.

MessageId = 413 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RWRAW_ENCRYPTED_INVALID_EDATAINFO_PARAMETER
.

MessageId = 414 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LINUX_SUBSYSTEM_NOT_PRESENT
.

MessageId = 415 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FT_READ_FAILURE
.

MessageId = 416 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STORAGE_RESERVE_ID_INVALID
.

MessageId = 417 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STORAGE_RESERVE_DOES_NOT_EXIST
.

MessageId = 418 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STORAGE_RESERVE_ALREADY_EXISTS
.

MessageId = 419 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STORAGE_RESERVE_NOT_EMPTY
.

MessageId = 420 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_A_DAX_VOLUME
.

MessageId = 421 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_DAX_MAPPABLE
.

MessageId = 422 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TIME_SENSITIVE_THREAD
.

MessageId = 423 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DPL_NOT_SUPPORTED_FOR_USER
.

MessageId = 424 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CASE_DIFFERING_NAMES_IN_DIR
.

MessageId = 425 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_NOT_SUPPORTED
.

MessageId = 426 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_REQUEST_TIMEOUT
.

MessageId = 427 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_TASK_QUEUE
.

MessageId = 428 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SRC_SRV_DLL_LOAD_FAILED
.

MessageId = 429 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SUPPORTED_WITH_BTT
.

MessageId = 430 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ENCRYPTION_DISABLED
.

MessageId = 431 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ENCRYPTING_METADATA_DISALLOWED
.

MessageId = 432 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANT_CLEAR_ENCRYPTION_FLAG
.

MessageId = 433 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SUCH_DEVICE
.

MessageId = 434 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_DEHYDRATION_DISALLOWED
.

MessageId = 435 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_SNAP_IN_PROGRESS
.

MessageId = 436 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_SNAP_USER_SECTION_NOT_SUPPORTED
.

MessageId = 437 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_SNAP_MODIFY_NOT_SUPPORTED
.

MessageId = 438 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_SNAP_IO_NOT_COORDINATED
.

MessageId = 439 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_SNAP_UNEXPECTED_ERROR
.

MessageId = 440 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_SNAP_INVALID_PARAMETER
.

MessageId = 441 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNSATISFIED_DEPENDENCIES
.

MessageId = 442 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CASE_SENSITIVE_PATH
.

MessageId = 443 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNEXPECTED_NTCACHEMANAGER_ERROR
.

MessageId = 444 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LINUX_SUBSYSTEM_UPDATE_REQUIRED
.

MessageId = 445 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DLP_POLICY_WARNS_AGAINST_OPERATION
.

MessageId = 446 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DLP_POLICY_DENIES_OPERATION
.

MessageId = 447 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SECURITY_DENIES_OPERATION
.

MessageId = 448 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNTRUSTED_MOUNT_POINT
.

MessageId = 449 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DLP_POLICY_SILENTLY_FAIL
.

MessageId = 450 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CAPAUTHZ_NOT_DEVUNLOCKED
.

MessageId = 451 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CAPAUTHZ_CHANGE_TYPE
.

MessageId = 452 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CAPAUTHZ_NOT_PROVISIONED
.

MessageId = 453 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CAPAUTHZ_NOT_AUTHORIZED
.

MessageId = 454 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CAPAUTHZ_NO_POLICY
.

MessageId = 455 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CAPAUTHZ_DB_CORRUPTED
.

MessageId = 456 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CAPAUTHZ_SCCD_INVALID_CATALOG
.

MessageId = 457 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CAPAUTHZ_SCCD_NO_AUTH_ENTITY
.

MessageId = 458 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CAPAUTHZ_SCCD_PARSE_ERROR
.

MessageId = 459 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CAPAUTHZ_SCCD_DEV_MODE_REQUIRED
.

MessageId = 460 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CAPAUTHZ_SCCD_NO_CAPABILITY_MATCH
.

MessageId = 470 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CIMFS_IMAGE_CORRUPT
.

MessageId = 471 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CIMFS_IMAGE_VERSION_NOT_SUPPORTED
.

MessageId = 472 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STORAGE_STACK_ACCESS_DENIED
.

MessageId = 473 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSUFFICIENT_VIRTUAL_ADDR_RESOURCES
.

MessageId = 474 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INDEX_OUT_OF_BOUNDS
.

MessageId = 475 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLOUD_FILE_US_MESSAGE_TIMEOUT
.

MessageId = 483 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_HARDWARE_ERROR
.

MessageId = 487 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_ADDRESS
.

MessageId = 488 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HAS_SYSTEM_CRITICAL_FILES
.

MessageId = 489 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ENCRYPTED_FILE_NOT_SUPPORTED
.

MessageId = 490 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SPARSE_FILE_NOT_SUPPORTED
.

MessageId = 491 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PAGEFILE_NOT_SUPPORTED
.

MessageId = 492 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_VOLUME_NOT_SUPPORTED
.

MessageId = 493 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SUPPORTED_WITH_BYPASSIO
.

MessageId = 494 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_BYPASSIO_DRIVER_SUPPORT
.

MessageId = 495 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SUPPORTED_WITH_ENCRYPTION
.

MessageId = 496 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SUPPORTED_WITH_COMPRESSION
.

MessageId = 497 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SUPPORTED_WITH_REPLICATION
.

MessageId = 498 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SUPPORTED_WITH_DEDUPLICATION
.

MessageId = 499 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SUPPORTED_WITH_AUDITING
.

MessageId = 500 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_USER_PROFILE_LOAD
.

MessageId = 501 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SESSION_KEY_TOO_SHORT
.

MessageId = 502 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ACCESS_DENIED_APPDATA
.

MessageId = 503 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SUPPORTED_WITH_MONITORING
.

MessageId = 504 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SUPPORTED_WITH_SNAPSHOT
.

MessageId = 505 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SUPPORTED_WITH_VIRTUALIZATION
.

MessageId = 506 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BYPASSIO_FLT_NOT_SUPPORTED
.

MessageId = 507 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_RESET_REQUIRED
.

MessageId = 508 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_VOLUME_WRITE_ACCESS_DENIED
.

MessageId = 509 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SUPPORTED_WITH_CACHED_HANDLE
.

MessageId = 510 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FS_METADATA_INCONSISTENT
.

MessageId = 511 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BLOCK_WEAK_REFERENCE_INVALID
.

MessageId = 512 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BLOCK_SOURCE_WEAK_REFERENCE_INVALID
.

MessageId = 513 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BLOCK_TARGET_WEAK_REFERENCE_INVALID
.

MessageId = 514 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BLOCK_SHARED
.

MessageId = 534 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ARITHMETIC_OVERFLOW
.

MessageId = 535 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PIPE_CONNECTED
.

MessageId = 536 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PIPE_LISTENING
.

MessageId = 537 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_VERIFIER_STOP
.

MessageId = 538 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ABIOS_ERROR
.

MessageId = 539 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WX86_WARNING
.

MessageId = 540 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WX86_ERROR
.

MessageId = 541 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TIMER_NOT_CANCELED
.

MessageId = 542 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNWIND
.

MessageId = 543 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_STACK
.

MessageId = 544 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_UNWIND_TARGET
.

MessageId = 545 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_PORT_ATTRIBUTES
.

MessageId = 546 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PORT_MESSAGE_TOO_LONG
.

MessageId = 547 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_QUOTA_LOWER
.

MessageId = 548 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_ALREADY_ATTACHED
.

MessageId = 549 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTRUCTION_MISALIGNMENT
.

MessageId = 550 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PROFILING_NOT_STARTED
.

MessageId = 551 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PROFILING_NOT_STOPPED
.

MessageId = 552 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_COULD_NOT_INTERPRET
.

MessageId = 553 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PROFILING_AT_LIMIT
.

MessageId = 554 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANT_WAIT
.

MessageId = 555 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANT_TERMINATE_SELF
.

MessageId = 556 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNEXPECTED_MM_CREATE_ERR
.

MessageId = 557 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNEXPECTED_MM_MAP_ERROR
.

MessageId = 558 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNEXPECTED_MM_EXTEND_ERR
.

MessageId = 559 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_FUNCTION_TABLE
.

MessageId = 560 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_GUID_TRANSLATION
.

MessageId = 561 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_LDT_SIZE
.

MessageId = 563 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_LDT_OFFSET
.

MessageId = 564 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_LDT_DESCRIPTOR
.

MessageId = 565 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_THREADS
.

MessageId = 566 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_THREAD_NOT_IN_PROCESS
.

MessageId = 567 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PAGEFILE_QUOTA_EXCEEDED
.

MessageId = 568 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOGON_SERVER_CONFLICT
.

MessageId = 569 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYNCHRONIZATION_REQUIRED
.

MessageId = 570 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NET_OPEN_FAILED
.

MessageId = 571 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IO_PRIVILEGE_FAILED
.

MessageId = 572 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CONTROL_C_EXIT
.

MessageId = 573 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MISSING_SYSTEMFILE
.

MessageId = 574 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNHANDLED_EXCEPTION
.

MessageId = 575 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APP_INIT_FAILURE
.

MessageId = 576 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PAGEFILE_CREATE_FAILED
.

MessageId = 577 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_IMAGE_HASH
.

MessageId = 578 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_PAGEFILE
.

MessageId = 579 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ILLEGAL_FLOAT_CONTEXT
.

MessageId = 580 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_EVENT_PAIR
.

MessageId = 581 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DOMAIN_CTRLR_CONFIG_ERROR
.

MessageId = 582 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ILLEGAL_CHARACTER
.

MessageId = 583 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNDEFINED_CHARACTER
.

MessageId = 585 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BIOS_FAILED_TO_CONNECT_INTERRUPT
.

MessageId = 586 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BACKUP_CONTROLLER
.

MessageId = 587 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MUTANT_LIMIT_EXCEEDED
.

MessageId = 588 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FS_DRIVER_REQUIRED
.

MessageId = 589 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANNOT_LOAD_REGISTRY_FILE
.

MessageId = 590 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEBUG_ATTACH_FAILED
.

MessageId = 591 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_PROCESS_TERMINATED
.

MessageId = 592 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DATA_NOT_ACCEPTED
.

MessageId = 593 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_VDM_HARD_ERROR
.

MessageId = 594 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DRIVER_CANCEL_TIMEOUT
.

MessageId = 595 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REPLY_MESSAGE_MISMATCH
.

MessageId = 596 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOST_WRITEBEHIND_DATA
.

MessageId = 597 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLIENT_SERVER_PARAMETERS_INVALID
.

MessageId = 598 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_TINY_STREAM
.

MessageId = 599 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STACK_OVERFLOW_READ
.

MessageId = 600 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CONVERT_TO_LARGE
.

MessageId = 601 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FOUND_OUT_OF_SCOPE
.

MessageId = 602 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ALLOCATE_BUCKET
.

MessageId = 603 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MARSHALL_OVERFLOW
.

MessageId = 604 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_VARIANT
.

MessageId = 605 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_COMPRESSION_BUFFER
.

MessageId = 606 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_AUDIT_FAILED
.

MessageId = 607 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TIMER_RESOLUTION_NOT_SET
.

MessageId = 608 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSUFFICIENT_LOGON_INFO
.

MessageId = 609 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_DLL_ENTRYPOINT
.

MessageId = 610 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_SERVICE_ENTRYPOINT
.

MessageId = 611 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IP_ADDRESS_CONFLICT1
.

MessageId = 612 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IP_ADDRESS_CONFLICT2
.

MessageId = 613 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REGISTRY_QUOTA_LIMIT
.

MessageId = 614 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_CALLBACK_ACTIVE
.

MessageId = 615 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PWD_TOO_SHORT
.

MessageId = 616 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PWD_TOO_RECENT
.

MessageId = 617 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PWD_HISTORY_CONFLICT
.

MessageId = 618 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNSUPPORTED_COMPRESSION
.

MessageId = 619 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_HW_PROFILE
.

MessageId = 620 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_PLUGPLAY_DEVICE_PATH
.

MessageId = 621 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_QUOTA_LIST_INCONSISTENT
.

MessageId = 622 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVALUATION_EXPIRATION
.

MessageId = 623 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ILLEGAL_DLL_RELOCATION
.

MessageId = 624 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DLL_INIT_FAILED_LOGOFF
.

MessageId = 625 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_VALIDATE_CONTINUE
.

MessageId = 626 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_MORE_MATCHES
.

MessageId = 627 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RANGE_LIST_CONFLICT
.

MessageId = 628 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVER_SID_MISMATCH
.

MessageId = 629 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANT_ENABLE_DENY_ONLY
.

MessageId = 630 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FLOAT_MULTIPLE_FAULTS
.

MessageId = 631 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FLOAT_MULTIPLE_TRAPS
.

MessageId = 632 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOINTERFACE
.

MessageId = 633 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DRIVER_FAILED_SLEEP
.

MessageId = 634 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CORRUPT_SYSTEM_FILE
.

MessageId = 635 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_COMMITMENT_MINIMUM
.

MessageId = 637 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_IMAGE_BAD_SIGNATURE
.

MessageId = 639 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSUFFICIENT_POWER
.

MessageId = 640 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MULTIPLE_FAULT_VIOLATION
.

MessageId = 641 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_SHUTDOWN
.

MessageId = 642 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PORT_NOT_SET
.

MessageId = 644 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RANGE_NOT_FOUND
.

MessageId = 646 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SAFE_MODE_DRIVER
.

MessageId = 647 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FAILED_DRIVER_ENTRY
.

MessageId = 648 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_ENUMERATION_ERROR
.

MessageId = 649 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MOUNT_POINT_NOT_RESOLVED
.

MessageId = 650 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_DEVICE_OBJECT_PARAMETER
.

MessageId = 652 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DRIVER_DATABASE_ERROR
.

MessageId = 653 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_HIVE_TOO_LARGE
.

MessageId = 654 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DRIVER_FAILED_PRIOR_UNLOAD
.

MessageId = 655 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_VOLSNAP_PREPARE_HIBERNATE
.

MessageId = 656 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HIBERNATION_FAILURE
.

MessageId = 657 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PWD_TOO_LONG
.

MessageId = 665 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_SYSTEM_LIMITATION
.

MessageId = 668 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ASSERTION_FAILURE
.

MessageId = 669 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ACPI_ERROR
.

MessageId = 670 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WOW_ASSERTION
.

MessageId = 675 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WAKE_SYSTEM_DEBUGGER
.

MessageId = 676 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HANDLES_CLOSED
.

MessageId = 677 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EXTRANEOUS_INFORMATION
.

MessageId = 678 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RXACT_COMMIT_NECESSARY
.

MessageId = 679 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MEDIA_CHECK
.

MessageId = 680 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_GUID_SUBSTITUTION_MADE
.

MessageId = 681 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STOPPED_ON_SYMLINK
.

MessageId = 682 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LONGJUMP
.

MessageId = 683 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PLUGPLAY_QUERY_VETOED
.

MessageId = 684 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNWIND_CONSOLIDATE
.

MessageId = 685 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REGISTRY_HIVE_RECOVERED
.

MessageId = 686 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DLL_MIGHT_BE_INSECURE
.

MessageId = 687 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DLL_MIGHT_BE_INCOMPATIBLE
.

MessageId = 688 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DBG_EXCEPTION_NOT_HANDLED
.

MessageId = 689 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DBG_REPLY_LATER
.

MessageId = 690 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DBG_UNABLE_TO_PROVIDE_HANDLE
.

MessageId = 691 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DBG_TERMINATE_THREAD
.

MessageId = 692 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DBG_TERMINATE_PROCESS
.

MessageId = 693 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DBG_CONTROL_C
.

MessageId = 694 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DBG_PRINTEXCEPTION_C
.

MessageId = 695 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DBG_RIPEXCEPTION
.

MessageId = 696 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DBG_CONTROL_BREAK
.

MessageId = 697 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DBG_COMMAND_EXCEPTION
.

MessageId = 698 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OBJECT_NAME_EXISTS
.

MessageId = 699 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_THREAD_WAS_SUSPENDED
.

MessageId = 700 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IMAGE_NOT_AT_BASE
.

MessageId = 701 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RXACT_STATE_CREATED
.

MessageId = 702 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SEGMENT_NOTIFICATION
.

MessageId = 703 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_CURRENT_DIRECTORY
.

MessageId = 704 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FT_READ_RECOVERY_FROM_BACKUP
.

MessageId = 705 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FT_WRITE_RECOVERY
.

MessageId = 706 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IMAGE_MACHINE_TYPE_MISMATCH
.

MessageId = 707 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RECEIVE_PARTIAL
.

MessageId = 708 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RECEIVE_EXPEDITED
.

MessageId = 709 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RECEIVE_PARTIAL_EXPEDITED
.

MessageId = 710 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVENT_DONE
.

MessageId = 711 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVENT_PENDING
.

MessageId = 712 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CHECKING_FILE_SYSTEM
.

MessageId = 713 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FATAL_APP_EXIT
.

MessageId = 714 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PREDEFINED_HANDLE
.

MessageId = 715 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WAS_UNLOCKED
.

MessageId = 716 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_NOTIFICATION
.

MessageId = 717 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WAS_LOCKED
.

MessageId = 718 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_HARD_ERROR
.

MessageId = 719 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ALREADY_WIN32
.

MessageId = 720 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IMAGE_MACHINE_TYPE_MISMATCH_EXE
.

MessageId = 721 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_YIELD_PERFORMED
.

MessageId = 722 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TIMER_RESUME_IGNORED
.

MessageId = 723 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ARBITRATION_UNHANDLED
.

MessageId = 724 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CARDBUS_NOT_SUPPORTED
.

MessageId = 725 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MP_PROCESSOR_MISMATCH
.

MessageId = 726 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HIBERNATED
.

MessageId = 727 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RESUME_HIBERNATION
.

MessageId = 728 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FIRMWARE_UPDATED
.

MessageId = 729 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DRIVERS_LEAKING_LOCKED_PAGES
.

MessageId = 730 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WAKE_SYSTEM
.

MessageId = 731 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WAIT
.

MessageId = 735 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ABANDONED_WAIT
.

MessageId = 737 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_USER_APC
.

MessageId = 738 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_KERNEL_APC
.

MessageId = 739 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ALERTED
.

MessageId = 740 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ELEVATION_REQUIRED
.

MessageId = 741 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REPARSE
.

MessageId = 742 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OPLOCK_BREAK_IN_PROGRESS
.

MessageId = 743 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_VOLUME_MOUNTED
.

MessageId = 744 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RXACT_COMMITTED
.

MessageId = 745 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOTIFY_CLEANUP
.

MessageId = 746 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PRIMARY_TRANSPORT_CONNECT_FAILED
.

MessageId = 747 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PAGE_FAULT_TRANSITION
.

MessageId = 748 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PAGE_FAULT_DEMAND_ZERO
.

MessageId = 749 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PAGE_FAULT_COPY_ON_WRITE
.

MessageId = 750 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PAGE_FAULT_GUARD_PAGE
.

MessageId = 751 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PAGE_FAULT_PAGING_FILE
.

MessageId = 752 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CACHE_PAGE_LOCKED
.

MessageId = 753 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CRASH_DUMP
.

MessageId = 754 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BUFFER_ALL_ZEROS
.

MessageId = 755 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REPARSE_OBJECT
.

MessageId = 756 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RESOURCE_REQUIREMENTS_CHANGED
.

MessageId = 757 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSLATION_COMPLETE
.

MessageId = 758 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOTHING_TO_TERMINATE
.

MessageId = 759 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PROCESS_NOT_IN_JOB
.

MessageId = 760 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PROCESS_IN_JOB
.

MessageId = 761 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_VOLSNAP_HIBERNATE_READY
.

MessageId = 762 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FSFILTER_OP_COMPLETED_SUCCESSFULLY
.

MessageId = 763 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INTERRUPT_VECTOR_ALREADY_CONNECTED
.

MessageId = 764 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INTERRUPT_STILL_CONNECTED
.

MessageId = 765 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WAIT_FOR_OPLOCK
.

MessageId = 766 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DBG_EXCEPTION_HANDLED
.

MessageId = 767 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DBG_CONTINUE
.

MessageId = 768 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CALLBACK_POP_STACK
.

MessageId = 769 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_COMPRESSION_DISABLED
.

MessageId = 770 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANTFETCHBACKWARDS
.

MessageId = 771 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANTSCROLLBACKWARDS
.

MessageId = 772 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ROWSNOTRELEASED
.

MessageId = 773 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_ACCESSOR_FLAGS
.

MessageId = 774 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ERRORS_ENCOUNTERED
.

MessageId = 775 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_CAPABLE
.

MessageId = 776 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REQUEST_OUT_OF_SEQUENCE
.

MessageId = 777 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_VERSION_PARSE_ERROR
.

MessageId = 778 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BADSTARTPOSITION
.

MessageId = 779 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MEMORY_HARDWARE
.

MessageId = 780 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DISK_REPAIR_DISABLED
.

MessageId = 781 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSUFFICIENT_RESOURCE_FOR_SPECIFIED_SHARED_SECTION_SIZE
.

MessageId = 782 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_POWERSTATE_TRANSITION
.

MessageId = 783 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_POWERSTATE_COMPLEX_TRANSITION
.

MessageId = 785 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ACCESS_AUDIT_BY_POLICY
.

MessageId = 786 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ACCESS_DISABLED_NO_SAFER_UI_BY_POLICY
.

MessageId = 787 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ABANDON_HIBERFILE
.

MessageId = 788 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOST_WRITEBEHIND_DATA_NETWORK_DISCONNECTED
.

MessageId = 789 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOST_WRITEBEHIND_DATA_NETWORK_SERVER_ERROR
.

MessageId = 790 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOST_WRITEBEHIND_DATA_LOCAL_DISK_ERROR
.

MessageId = 791 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_MCFG_TABLE
.

MessageId = 792 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DISK_REPAIR_REDIRECTED
.

MessageId = 793 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DISK_REPAIR_UNSUCCESSFUL
.

MessageId = 794 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CORRUPT_LOG_OVERFULL
.

MessageId = 795 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CORRUPT_LOG_CORRUPTED
.

MessageId = 796 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CORRUPT_LOG_UNAVAILABLE
.

MessageId = 797 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CORRUPT_LOG_DELETED_FULL
.

MessageId = 798 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CORRUPT_LOG_CLEARED
.

MessageId = 799 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ORPHAN_NAME_EXHAUSTED
.

MessageId = 800 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OPLOCK_SWITCHED_TO_NEW_HANDLE
.

MessageId = 801 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANNOT_GRANT_REQUESTED_OPLOCK
.

MessageId = 802 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANNOT_BREAK_OPLOCK
.

MessageId = 803 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OPLOCK_HANDLE_CLOSED
.

MessageId = 804 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_ACE_CONDITION
.

MessageId = 805 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_ACE_CONDITION
.

MessageId = 806 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_HANDLE_REVOKED
.

MessageId = 807 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IMAGE_AT_DIFFERENT_BASE
.

MessageId = 808 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ENCRYPTED_IO_NOT_POSSIBLE
.

MessageId = 809 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_METADATA_OPTIMIZATION_IN_PROGRESS
.

MessageId = 810 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_QUOTA_ACTIVITY
.

MessageId = 811 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HANDLE_REVOKED
.

MessageId = 812 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CALLBACK_INVOKE_INLINE
.

MessageId = 813 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CPU_SET_INVALID
.

MessageId = 814 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ENCLAVE_NOT_TERMINATED
.

MessageId = 815 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ENCLAVE_VIOLATION
.

MessageId = 816 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVER_TRANSPORT_CONFLICT
.

MessageId = 817 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CERTIFICATE_VALIDATION_PREFERENCE_CONFLICT
.

MessageId = 818 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FT_READ_FROM_COPY_FAILURE
.

MessageId = 819 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SECTION_DIRECT_MAP_ONLY
.

MessageId = 994 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EA_ACCESS_DENIED
.

MessageId = 995 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OPERATION_ABORTED
.

MessageId = 996 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IO_INCOMPLETE
.

MessageId = 997 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IO_PENDING
.

MessageId = 998 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOACCESS
.

MessageId = 999 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SWAPERROR
.

MessageId = 1001 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STACK_OVERFLOW
.

MessageId = 1002 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_MESSAGE
.

MessageId = 1003 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CAN_NOT_COMPLETE
.

MessageId = 1004 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_FLAGS
.

MessageId = 1005 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNRECOGNIZED_VOLUME
.

MessageId = 1006 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_INVALID
.

MessageId = 1007 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FULLSCREEN_MODE
.

MessageId = 1008 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_TOKEN
.

MessageId = 1009 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BADDB
.

MessageId = 1010 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BADKEY
.

MessageId = 1011 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANTOPEN
.

MessageId = 1012 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANTREAD
.

MessageId = 1013 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANTWRITE
.

MessageId = 1014 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REGISTRY_RECOVERED
.

MessageId = 1015 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REGISTRY_CORRUPT
.

MessageId = 1016 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REGISTRY_IO_FAILED
.

MessageId = 1017 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_REGISTRY_FILE
.

MessageId = 1018 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_KEY_DELETED
.

MessageId = 1019 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_LOG_SPACE
.

MessageId = 1020 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_KEY_HAS_CHILDREN
.

MessageId = 1021 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CHILD_MUST_BE_VOLATILE
.

MessageId = 1022 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOTIFY_ENUM_DIR
.

MessageId = 1051 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEPENDENT_SERVICES_RUNNING
.

MessageId = 1052 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_SERVICE_CONTROL
.

MessageId = 1053 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_REQUEST_TIMEOUT
.

MessageId = 1054 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_NO_THREAD
.

MessageId = 1055 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_DATABASE_LOCKED
.

MessageId = 1056 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_ALREADY_RUNNING
.

MessageId = 1057 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_SERVICE_ACCOUNT
.

MessageId = 1058 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_DISABLED
.

MessageId = 1059 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CIRCULAR_DEPENDENCY
.

MessageId = 1060 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_DOES_NOT_EXIST
.

MessageId = 1061 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_CANNOT_ACCEPT_CTRL
.

MessageId = 1062 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_NOT_ACTIVE
.

MessageId = 1063 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FAILED_SERVICE_CONTROLLER_CONNECT
.

MessageId = 1064 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EXCEPTION_IN_SERVICE
.

MessageId = 1065 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DATABASE_DOES_NOT_EXIST
.

MessageId = 1066 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_SPECIFIC_ERROR
.

MessageId = 1067 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PROCESS_ABORTED
.

MessageId = 1068 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_DEPENDENCY_FAIL
.

MessageId = 1069 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_LOGON_FAILED
.

MessageId = 1070 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_START_HANG
.

MessageId = 1071 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_SERVICE_LOCK
.

MessageId = 1072 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_MARKED_FOR_DELETE
.

MessageId = 1073 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_EXISTS
.

MessageId = 1074 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ALREADY_RUNNING_LKG
.

MessageId = 1075 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_DEPENDENCY_DELETED
.

MessageId = 1076 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BOOT_ALREADY_ACCEPTED
.

MessageId = 1077 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_NEVER_STARTED
.

MessageId = 1078 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DUPLICATE_SERVICE_NAME
.

MessageId = 1079 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DIFFERENT_SERVICE_ACCOUNT
.

MessageId = 1080 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANNOT_DETECT_DRIVER_FAILURE
.

MessageId = 1081 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANNOT_DETECT_PROCESS_ABORT
.

MessageId = 1082 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_RECOVERY_PROGRAM
.

MessageId = 1083 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_NOT_IN_EXE
.

MessageId = 1084 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SAFEBOOT_SERVICE
.

MessageId = 1100 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_END_OF_MEDIA
.

MessageId = 1101 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILEMARK_DETECTED
.

MessageId = 1102 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BEGINNING_OF_MEDIA
.

MessageId = 1103 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SETMARK_DETECTED
.

MessageId = 1104 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_DATA_DETECTED
.

MessageId = 1105 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PARTITION_FAILURE
.

MessageId = 1106 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_BLOCK_LENGTH
.

MessageId = 1107 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_NOT_PARTITIONED
.

MessageId = 1108 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNABLE_TO_LOCK_MEDIA
.

MessageId = 1109 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNABLE_TO_UNLOAD_MEDIA
.

MessageId = 1110 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MEDIA_CHANGED
.

MessageId = 1111 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BUS_RESET
.

MessageId = 1112 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_MEDIA_IN_DRIVE
.

MessageId = 1113 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_UNICODE_TRANSLATION
.

MessageId = 1114 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DLL_INIT_FAILED
.

MessageId = 1115 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SHUTDOWN_IN_PROGRESS
.

MessageId = 1116 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SHUTDOWN_IN_PROGRESS
.

MessageId = 1117 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IO_DEVICE
.

MessageId = 1118 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERIAL_NO_DEVICE
.

MessageId = 1119 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IRQ_BUSY
.

MessageId = 1120 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MORE_WRITES
.

MessageId = 1121 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_COUNTER_TIMEOUT
.

MessageId = 1126 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DISK_RECALIBRATE_FAILED
.

MessageId = 1127 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DISK_OPERATION_FAILED
.

MessageId = 1128 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DISK_RESET_FAILED
.

MessageId = 1129 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EOM_OVERFLOW
.

MessageId = 1130 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_ENOUGH_SERVER_MEMORY
.

MessageId = 1131 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_POSSIBLE_DEADLOCK
.

MessageId = 1132 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MAPPED_ALIGNMENT
.

MessageId = 1140 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SET_POWER_STATE_VETOED
.

MessageId = 1141 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SET_POWER_STATE_FAILED
.

MessageId = 1142 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_LINKS
.

MessageId = 1150 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OLD_WIN_VERSION
.

MessageId = 1151 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APP_WRONG_OS
.

MessageId = 1152 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SINGLE_INSTANCE_APP
.

MessageId = 1153 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RMODE_APP
.

MessageId = 1154 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_DLL
.

MessageId = 1155 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_ASSOCIATION
.

MessageId = 1156 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DDE_FAIL
.

MessageId = 1157 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DLL_NOT_FOUND
.

MessageId = 1158 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_MORE_USER_HANDLES
.

MessageId = 1159 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MESSAGE_SYNC_ONLY
.

MessageId = 1160 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SOURCE_ELEMENT_EMPTY
.

MessageId = 1161 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DESTINATION_ELEMENT_FULL
.

MessageId = 1162 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ILLEGAL_ELEMENT_ADDRESS
.

MessageId = 1163 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MAGAZINE_NOT_PRESENT
.

MessageId = 1164 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_REINITIALIZATION_NEEDED
.

MessageId = 1165 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_REQUIRES_CLEANING
.

MessageId = 1166 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_DOOR_OPEN
.

MessageId = 1167 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_NOT_CONNECTED
.

MessageId = 1168 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_FOUND
.

MessageId = 1169 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_MATCH
.

MessageId = 1170 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SET_NOT_FOUND
.

MessageId = 1171 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_POINT_NOT_FOUND
.

MessageId = 1172 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_TRACKING_SERVICE
.

MessageId = 1173 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_VOLUME_ID
.

MessageId = 1175 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNABLE_TO_REMOVE_REPLACED
.

MessageId = 1176 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNABLE_TO_MOVE_REPLACEMENT
.

MessageId = 1177 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNABLE_TO_MOVE_REPLACEMENT_2
.

MessageId = 1178 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_JOURNAL_DELETE_IN_PROGRESS
.

MessageId = 1179 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_JOURNAL_NOT_ACTIVE
.

MessageId = 1180 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_POTENTIAL_FILE_FOUND
.

MessageId = 1181 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_JOURNAL_ENTRY_DELETED
.

MessageId = 1184 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PARTITION_TERMINATING
.

MessageId = 1190 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SHUTDOWN_IS_SCHEDULED
.

MessageId = 1191 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SHUTDOWN_USERS_LOGGED_ON
.

MessageId = 1192 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SHUTDOWN_DISKS_NOT_IN_MAINTENANCE_MODE
.

MessageId = 1200 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_DEVICE
.

MessageId = 1201 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CONNECTION_UNAVAIL
.

MessageId = 1202 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_ALREADY_REMEMBERED
.

MessageId = 1203 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_NET_OR_BAD_PATH
.

MessageId = 1204 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_PROVIDER
.

MessageId = 1205 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANNOT_OPEN_PROFILE
.

MessageId = 1206 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_PROFILE
.

MessageId = 1207 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_CONTAINER
.

MessageId = 1208 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EXTENDED_ERROR
.

MessageId = 1209 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_GROUPNAME
.

MessageId = 1210 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_COMPUTERNAME
.

MessageId = 1211 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_EVENTNAME
.

MessageId = 1212 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_DOMAINNAME
.

MessageId = 1213 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_SERVICENAME
.

MessageId = 1214 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_NETNAME
.

MessageId = 1215 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_SHARENAME
.

MessageId = 1216 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_PASSWORDNAME
.

MessageId = 1217 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_MESSAGENAME
.

MessageId = 1218 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_MESSAGEDEST
.

MessageId = 1219 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SESSION_CREDENTIAL_CONFLICT
.

MessageId = 1220 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REMOTE_SESSION_LIMIT_EXCEEDED
.

MessageId = 1221 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DUP_DOMAINNAME
.

MessageId = 1222 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_NETWORK
.

MessageId = 1223 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANCELLED
.

MessageId = 1224 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_USER_MAPPED_FILE
.

MessageId = 1225 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CONNECTION_REFUSED
.

MessageId = 1226 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_GRACEFUL_DISCONNECT
.

MessageId = 1227 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ADDRESS_ALREADY_ASSOCIATED
.

MessageId = 1228 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ADDRESS_NOT_ASSOCIATED
.

MessageId = 1229 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CONNECTION_INVALID
.

MessageId = 1230 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CONNECTION_ACTIVE
.

MessageId = 1231 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NETWORK_UNREACHABLE
.

MessageId = 1232 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HOST_UNREACHABLE
.

MessageId = 1233 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PROTOCOL_UNREACHABLE
.

MessageId = 1234 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PORT_UNREACHABLE
.

MessageId = 1235 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REQUEST_ABORTED
.

MessageId = 1236 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CONNECTION_ABORTED
.

MessageId = 1237 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RETRY
.

MessageId = 1238 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CONNECTION_COUNT_LIMIT
.

MessageId = 1239 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOGIN_TIME_RESTRICTION
.

MessageId = 1240 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOGIN_WKSTA_RESTRICTION
.

MessageId = 1241 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INCORRECT_ADDRESS
.

MessageId = 1242 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ALREADY_REGISTERED
.

MessageId = 1243 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_NOT_FOUND
.

MessageId = 1244 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_AUTHENTICATED
.

MessageId = 1245 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_LOGGED_ON
.

MessageId = 1246 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CONTINUE
.

MessageId = 1247 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ALREADY_INITIALIZED
.

MessageId = 1248 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_MORE_DEVICES
.

MessageId = 1249 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SUCH_SITE
.

MessageId = 1250 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DOMAIN_CONTROLLER_EXISTS
.

MessageId = 1251 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ONLY_IF_CONNECTED
.

MessageId = 1252 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OVERRIDE_NOCHANGES
.

MessageId = 1253 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_USER_PROFILE
.

MessageId = 1254 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SUPPORTED_ON_SBS
.

MessageId = 1255 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVER_SHUTDOWN_IN_PROGRESS
.

MessageId = 1256 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HOST_DOWN
.

MessageId = 1257 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NON_ACCOUNT_SID
.

MessageId = 1258 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NON_DOMAIN_SID
.

MessageId = 1259 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPHELP_BLOCK
.

MessageId = 1260 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ACCESS_DISABLED_BY_POLICY
.

MessageId = 1261 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REG_NAT_CONSUMPTION
.

MessageId = 1262 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CSCSHARE_OFFLINE
.

MessageId = 1263 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PKINIT_FAILURE
.

MessageId = 1264 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SMARTCARD_SUBSYSTEM_FAILURE
.

MessageId = 1265 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DOWNGRADE_DETECTED
.

MessageId = 1271 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MACHINE_LOCKED
.

MessageId = 1272 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SMB_GUEST_LOGON_BLOCKED
.

MessageId = 1273 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CALLBACK_SUPPLIED_INVALID_DATA
.

MessageId = 1274 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYNC_FOREGROUND_REFRESH_REQUIRED
.

MessageId = 1275 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DRIVER_BLOCKED
.

MessageId = 1276 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_IMPORT_OF_NON_DLL
.

MessageId = 1277 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ACCESS_DISABLED_WEBBLADE
.

MessageId = 1278 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ACCESS_DISABLED_WEBBLADE_TAMPER
.

MessageId = 1279 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RECOVERY_FAILURE
.

MessageId = 1280 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ALREADY_FIBER
.

MessageId = 1281 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ALREADY_THREAD
.

MessageId = 1282 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STACK_BUFFER_OVERRUN
.

MessageId = 1283 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PARAMETER_QUOTA_EXCEEDED
.

MessageId = 1284 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEBUGGER_INACTIVE
.

MessageId = 1285 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DELAY_LOAD_FAILED
.

MessageId = 1286 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_VDM_DISALLOWED
.

MessageId = 1287 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNIDENTIFIED_ERROR
.

MessageId = 1288 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_CRUNTIME_PARAMETER
.

MessageId = 1289 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BEYOND_VDL
.

MessageId = 1290 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INCOMPATIBLE_SERVICE_SID_TYPE
.

MessageId = 1291 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DRIVER_PROCESS_TERMINATED
.

MessageId = 1292 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IMPLEMENTATION_LIMIT
.

MessageId = 1293 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PROCESS_IS_PROTECTED
.

MessageId = 1294 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_NOTIFY_CLIENT_LAGGING
.

MessageId = 1295 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DISK_QUOTA_EXCEEDED
.

MessageId = 1296 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CONTENT_BLOCKED
.

MessageId = 1297 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INCOMPATIBLE_SERVICE_PRIVILEGE
.

MessageId = 1298 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APP_HANG
.

MessageId = 1299 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_LABEL
.

MessageId = 1300 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_ALL_ASSIGNED
.

MessageId = 1301 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SOME_NOT_MAPPED
.

MessageId = 1302 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_QUOTAS_FOR_ACCOUNT
.

MessageId = 1303 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOCAL_USER_SESSION_KEY
.

MessageId = 1304 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NULL_LM_PASSWORD
.

MessageId = 1305 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNKNOWN_REVISION
.

MessageId = 1306 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REVISION_MISMATCH
.

MessageId = 1307 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_OWNER
.

MessageId = 1308 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_PRIMARY_GROUP
.

MessageId = 1309 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_IMPERSONATION_TOKEN
.

MessageId = 1310 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANT_DISABLE_MANDATORY
.

MessageId = 1311 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_LOGON_SERVERS
.

MessageId = 1312 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SUCH_LOGON_SESSION
.

MessageId = 1313 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SUCH_PRIVILEGE
.

MessageId = 1314 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PRIVILEGE_NOT_HELD
.

MessageId = 1315 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_ACCOUNT_NAME
.

MessageId = 1316 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_USER_EXISTS
.

MessageId = 1317 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SUCH_USER
.

MessageId = 1318 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_GROUP_EXISTS
.

MessageId = 1319 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SUCH_GROUP
.

MessageId = 1320 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MEMBER_IN_GROUP
.

MessageId = 1321 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MEMBER_NOT_IN_GROUP
.

MessageId = 1322 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LAST_ADMIN
.

MessageId = 1323 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WRONG_PASSWORD
.

MessageId = 1324 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ILL_FORMED_PASSWORD
.

MessageId = 1325 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PASSWORD_RESTRICTION
.

MessageId = 1326 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOGON_FAILURE
.

MessageId = 1327 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ACCOUNT_RESTRICTION
.

MessageId = 1328 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_LOGON_HOURS
.

MessageId = 1329 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_WORKSTATION
.

MessageId = 1330 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PASSWORD_EXPIRED
.

MessageId = 1331 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ACCOUNT_DISABLED
.

MessageId = 1332 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NONE_MAPPED
.

MessageId = 1333 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_LUIDS_REQUESTED
.

MessageId = 1334 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LUIDS_EXHAUSTED
.

MessageId = 1335 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_SUB_AUTHORITY
.

MessageId = 1336 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_ACL
.

MessageId = 1337 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_SID
.

MessageId = 1338 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_SECURITY_DESCR
.

MessageId = 1340 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_INHERITANCE_ACL
.

MessageId = 1341 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVER_DISABLED
.

MessageId = 1342 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVER_NOT_DISABLED
.

MessageId = 1343 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_ID_AUTHORITY
.

MessageId = 1344 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ALLOTTED_SPACE_EXCEEDED
.

MessageId = 1345 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_GROUP_ATTRIBUTES
.

MessageId = 1346 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_IMPERSONATION_LEVEL
.

MessageId = 1347 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANT_OPEN_ANONYMOUS
.

MessageId = 1348 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_VALIDATION_CLASS
.

MessageId = 1349 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_TOKEN_TYPE
.

MessageId = 1350 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SECURITY_ON_OBJECT
.

MessageId = 1351 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANT_ACCESS_DOMAIN_INFO
.

MessageId = 1352 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_SERVER_STATE
.

MessageId = 1353 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_DOMAIN_STATE
.

MessageId = 1354 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_DOMAIN_ROLE
.

MessageId = 1355 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SUCH_DOMAIN
.

MessageId = 1356 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DOMAIN_EXISTS
.

MessageId = 1357 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DOMAIN_LIMIT_EXCEEDED
.

MessageId = 1358 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INTERNAL_DB_CORRUPTION
.

MessageId = 1359 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INTERNAL_ERROR
.

MessageId = 1360 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_GENERIC_NOT_MAPPED
.

MessageId = 1361 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_DESCRIPTOR_FORMAT
.

MessageId = 1362 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_LOGON_PROCESS
.

MessageId = 1363 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOGON_SESSION_EXISTS
.

MessageId = 1364 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SUCH_PACKAGE
.

MessageId = 1365 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_LOGON_SESSION_STATE
.

MessageId = 1366 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOGON_SESSION_COLLISION
.

MessageId = 1367 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_LOGON_TYPE
.

MessageId = 1368 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANNOT_IMPERSONATE
.

MessageId = 1369 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RXACT_INVALID_STATE
.

MessageId = 1370 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RXACT_COMMIT_FAILURE
.

MessageId = 1371 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SPECIAL_ACCOUNT
.

MessageId = 1372 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SPECIAL_GROUP
.

MessageId = 1373 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SPECIAL_USER
.

MessageId = 1374 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MEMBERS_PRIMARY_GROUP
.

MessageId = 1375 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOKEN_ALREADY_IN_USE
.

MessageId = 1376 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SUCH_ALIAS
.

MessageId = 1377 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MEMBER_NOT_IN_ALIAS
.

MessageId = 1378 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MEMBER_IN_ALIAS
.

MessageId = 1379 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ALIAS_EXISTS
.

MessageId = 1380 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOGON_NOT_GRANTED
.

MessageId = 1381 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_SECRETS
.

MessageId = 1382 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SECRET_TOO_LONG
.

MessageId = 1383 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INTERNAL_DB_ERROR
.

MessageId = 1384 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_CONTEXT_IDS
.

MessageId = 1385 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOGON_TYPE_NOT_GRANTED
.

MessageId = 1386 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NT_CROSS_ENCRYPTION_REQUIRED
.

MessageId = 1387 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SUCH_MEMBER
.

MessageId = 1388 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_MEMBER
.

MessageId = 1389 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TOO_MANY_SIDS
.

MessageId = 1390 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LM_CROSS_ENCRYPTION_REQUIRED
.

MessageId = 1391 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_INHERITANCE
.

MessageId = 1392 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_CORRUPT
.

MessageId = 1393 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DISK_CORRUPT
.

MessageId = 1394 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_USER_SESSION_KEY
.

MessageId = 1395 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LICENSE_QUOTA_EXCEEDED
.

MessageId = 1396 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WRONG_TARGET_NAME
.

MessageId = 1397 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MUTUAL_AUTH_FAILED
.

MessageId = 1398 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TIME_SKEW
.

MessageId = 1399 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CURRENT_DOMAIN_NOT_ALLOWED
.

MessageId = 1400 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_WINDOW_HANDLE
.

MessageId = 1401 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_MENU_HANDLE
.

MessageId = 1402 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_CURSOR_HANDLE
.

MessageId = 1403 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_ACCEL_HANDLE
.

MessageId = 1404 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_HOOK_HANDLE
.

MessageId = 1405 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_DWP_HANDLE
.

MessageId = 1406 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TLW_WITH_WSCHILD
.

MessageId = 1407 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANNOT_FIND_WND_CLASS
.

MessageId = 1408 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WINDOW_OF_OTHER_THREAD
.

MessageId = 1409 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HOTKEY_ALREADY_REGISTERED
.

MessageId = 1410 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLASS_ALREADY_EXISTS
.

MessageId = 1411 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLASS_DOES_NOT_EXIST
.

MessageId = 1412 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLASS_HAS_WINDOWS
.

MessageId = 1413 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_INDEX
.

MessageId = 1414 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_ICON_HANDLE
.

MessageId = 1415 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PRIVATE_DIALOG_INDEX
.

MessageId = 1416 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LISTBOX_ID_NOT_FOUND
.

MessageId = 1417 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_WILDCARD_CHARACTERS
.

MessageId = 1418 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLIPBOARD_NOT_OPEN
.

MessageId = 1419 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HOTKEY_NOT_REGISTERED
.

MessageId = 1420 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WINDOW_NOT_DIALOG
.

MessageId = 1421 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CONTROL_ID_NOT_FOUND
.

MessageId = 1422 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_COMBOBOX_MESSAGE
.

MessageId = 1423 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WINDOW_NOT_COMBOBOX
.

MessageId = 1424 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_EDIT_HEIGHT
.

MessageId = 1425 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DC_NOT_FOUND
.

MessageId = 1426 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_HOOK_FILTER
.

MessageId = 1427 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_FILTER_PROC
.

MessageId = 1428 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HOOK_NEEDS_HMOD
.

MessageId = 1429 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_GLOBAL_ONLY_HOOK
.

MessageId = 1430 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_JOURNAL_HOOK_SET
.

MessageId = 1431 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HOOK_NOT_INSTALLED
.

MessageId = 1432 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_LB_MESSAGE
.

MessageId = 1433 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SETCOUNT_ON_BAD_LB
.

MessageId = 1434 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LB_WITHOUT_TABSTOPS
.

MessageId = 1435 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DESTROY_OBJECT_OF_OTHER_THREAD
.

MessageId = 1436 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CHILD_WINDOW_MENU
.

MessageId = 1437 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SYSTEM_MENU
.

MessageId = 1438 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_MSGBOX_STYLE
.

MessageId = 1439 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_SPI_VALUE
.

MessageId = 1440 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SCREEN_ALREADY_LOCKED
.

MessageId = 1441 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HWNDS_HAVE_DIFF_PARENT
.

MessageId = 1442 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_CHILD_WINDOW
.

MessageId = 1443 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_GW_COMMAND
.

MessageId = 1444 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_THREAD_ID
.

MessageId = 1445 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NON_MDICHILD_WINDOW
.

MessageId = 1446 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_POPUP_ALREADY_ACTIVE
.

MessageId = 1447 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SCROLLBARS
.

MessageId = 1448 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_SCROLLBAR_RANGE
.

MessageId = 1449 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_SHOWWIN_COMMAND
.

MessageId = 1450 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SYSTEM_RESOURCES
.

MessageId = 1451 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NONPAGED_SYSTEM_RESOURCES
.

MessageId = 1452 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PAGED_SYSTEM_RESOURCES
.

MessageId = 1453 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WORKING_SET_QUOTA
.

MessageId = 1454 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PAGEFILE_QUOTA
.

MessageId = 1455 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_COMMITMENT_LIMIT
.

MessageId = 1456 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MENU_ITEM_NOT_FOUND
.

MessageId = 1457 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_KEYBOARD_HANDLE
.

MessageId = 1458 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HOOK_TYPE_NOT_ALLOWED
.

MessageId = 1459 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REQUIRES_INTERACTIVE_WINDOWSTATION
.

MessageId = 1460 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TIMEOUT
.

MessageId = 1461 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_MONITOR_HANDLE
.

MessageId = 1462 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INCORRECT_SIZE
.

MessageId = 1463 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYMLINK_CLASS_DISABLED
.

MessageId = 1464 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYMLINK_NOT_SUPPORTED
.

MessageId = 1465 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_XML_PARSE_ERROR
.

MessageId = 1466 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_XMLDSIG_ERROR
.

MessageId = 1467 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RESTART_APPLICATION
.

MessageId = 1468 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WRONG_COMPARTMENT
.

MessageId = 1469 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_AUTHIP_FAILURE
.

MessageId = 1470 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_NVRAM_RESOURCES
.

MessageId = 1471 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_GUI_PROCESS
.

MessageId = 1500 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVENTLOG_FILE_CORRUPT
.

MessageId = 1501 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVENTLOG_CANT_START
.

MessageId = 1502 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_FILE_FULL
.

MessageId = 1503 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVENTLOG_FILE_CHANGED
.

MessageId = 1504 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CONTAINER_ASSIGNED
.

MessageId = 1505 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_JOB_NO_CONTAINER
.

MessageId = 1550 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_TASK_NAME
.

MessageId = 1551 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_TASK_INDEX
.

MessageId = 1552 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_THREAD_ALREADY_IN_TASK
.

MessageId = 1601 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_SERVICE_FAILURE
.

MessageId = 1602 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_USEREXIT
.

MessageId = 1603 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_FAILURE
.

MessageId = 1604 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_SUSPEND
.

MessageId = 1605 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNKNOWN_PRODUCT
.

MessageId = 1606 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNKNOWN_FEATURE
.

MessageId = 1607 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNKNOWN_COMPONENT
.

MessageId = 1608 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNKNOWN_PROPERTY
.

MessageId = 1609 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_HANDLE_STATE
.

MessageId = 1610 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_CONFIGURATION
.

MessageId = 1611 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INDEX_ABSENT
.

MessageId = 1612 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_SOURCE_ABSENT
.

MessageId = 1613 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_PACKAGE_VERSION
.

MessageId = 1614 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PRODUCT_UNINSTALLED
.

MessageId = 1615 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_QUERY_SYNTAX
.

MessageId = 1616 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_FIELD
.

MessageId = 1617 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_REMOVED
.

MessageId = 1618 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_ALREADY_RUNNING
.

MessageId = 1619 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_PACKAGE_OPEN_FAILED
.

MessageId = 1620 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_PACKAGE_INVALID
.

MessageId = 1621 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_UI_FAILURE
.

MessageId = 1622 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_LOG_FAILURE
.

MessageId = 1623 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_LANGUAGE_UNSUPPORTED
.

MessageId = 1624 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_TRANSFORM_FAILURE
.

MessageId = 1625 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_PACKAGE_REJECTED
.

MessageId = 1626 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FUNCTION_NOT_CALLED
.

MessageId = 1627 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FUNCTION_FAILED
.

MessageId = 1628 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_TABLE
.

MessageId = 1629 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DATATYPE_MISMATCH
.

MessageId = 1630 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNSUPPORTED_TYPE
.

MessageId = 1631 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CREATE_FAILED
.

MessageId = 1632 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_TEMP_UNWRITABLE
.

MessageId = 1633 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_PLATFORM_UNSUPPORTED
.

MessageId = 1634 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_NOTUSED
.

MessageId = 1635 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PATCH_PACKAGE_OPEN_FAILED
.

MessageId = 1636 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PATCH_PACKAGE_INVALID
.

MessageId = 1637 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PATCH_PACKAGE_UNSUPPORTED
.

MessageId = 1638 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PRODUCT_VERSION
.

MessageId = 1639 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_COMMAND_LINE
.

MessageId = 1640 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_REMOTE_DISALLOWED
.

MessageId = 1641 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SUCCESS_REBOOT_INITIATED
.

MessageId = 1642 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PATCH_TARGET_NOT_FOUND
.

MessageId = 1643 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PATCH_PACKAGE_REJECTED
.

MessageId = 1644 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_TRANSFORM_REJECTED
.

MessageId = 1645 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_REMOTE_PROHIBITED
.

MessageId = 1646 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PATCH_REMOVAL_UNSUPPORTED
.

MessageId = 1647 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNKNOWN_PATCH
.

MessageId = 1648 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PATCH_NO_SEQUENCE
.

MessageId = 1649 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PATCH_REMOVAL_DISALLOWED
.

MessageId = 1650 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_PATCH_XML
.

MessageId = 1651 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PATCH_MANAGED_ADVERTISED_PRODUCT
.

MessageId = 1652 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_SERVICE_SAFEBOOT
.

MessageId = 1653 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FAIL_FAST_EXCEPTION
.

MessageId = 1654 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_REJECTED
.

MessageId = 1655 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DYNAMIC_CODE_BLOCKED
.

MessageId = 1656 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SAME_OBJECT
.

MessageId = 1657 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STRICT_CFG_VIOLATION
.

MessageId = 1660 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SET_CONTEXT_DENIED
.

MessageId = 1661 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CROSS_PARTITION_VIOLATION
.

MessageId = 1662 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RETURN_ADDRESS_HIJACK_ATTEMPT
.

MessageId = 1700 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_STRING_BINDING
.

MessageId = 1701 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_WRONG_KIND_OF_BINDING
.

MessageId = 1702 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_BINDING
.

MessageId = 1703 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_PROTSEQ_NOT_SUPPORTED
.

MessageId = 1704 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_RPC_PROTSEQ
.

MessageId = 1705 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_STRING_UUID
.

MessageId = 1706 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_ENDPOINT_FORMAT
.

MessageId = 1707 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_NET_ADDR
.

MessageId = 1708 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NO_ENDPOINT_FOUND
.

MessageId = 1709 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_TIMEOUT
.

MessageId = 1710 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_OBJECT_NOT_FOUND
.

MessageId = 1711 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_ALREADY_REGISTERED
.

MessageId = 1712 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_TYPE_ALREADY_REGISTERED
.

MessageId = 1713 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_ALREADY_LISTENING
.

MessageId = 1714 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NO_PROTSEQS_REGISTERED
.

MessageId = 1715 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NOT_LISTENING
.

MessageId = 1716 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_UNKNOWN_MGR_TYPE
.

MessageId = 1717 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_UNKNOWN_IF
.

MessageId = 1718 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NO_BINDINGS
.

MessageId = 1719 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NO_PROTSEQS
.

MessageId = 1720 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_CANT_CREATE_ENDPOINT
.

MessageId = 1721 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_OUT_OF_RESOURCES
.

MessageId = 1722 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_SERVER_UNAVAILABLE
.

MessageId = 1723 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_SERVER_TOO_BUSY
.

MessageId = 1724 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_NETWORK_OPTIONS
.

MessageId = 1725 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NO_CALL_ACTIVE
.

MessageId = 1726 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_CALL_FAILED
.

MessageId = 1727 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_CALL_FAILED_DNE
.

MessageId = 1728 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_PROTOCOL_ERROR
.

MessageId = 1729 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_PROXY_ACCESS_DENIED
.

MessageId = 1730 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_UNSUPPORTED_TRANS_SYN
.

MessageId = 1732 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_UNSUPPORTED_TYPE
.

MessageId = 1733 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_TAG
.

MessageId = 1734 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_BOUND
.

MessageId = 1735 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NO_ENTRY_NAME
.

MessageId = 1736 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_NAME_SYNTAX
.

MessageId = 1737 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_UNSUPPORTED_NAME_SYNTAX
.

MessageId = 1739 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_UUID_NO_ADDRESS
.

MessageId = 1740 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_DUPLICATE_ENDPOINT
.

MessageId = 1741 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_UNKNOWN_AUTHN_TYPE
.

MessageId = 1742 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_MAX_CALLS_TOO_SMALL
.

MessageId = 1743 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_STRING_TOO_LONG
.

MessageId = 1744 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_PROTSEQ_NOT_FOUND
.

MessageId = 1745 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_PROCNUM_OUT_OF_RANGE
.

MessageId = 1746 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_BINDING_HAS_NO_AUTH
.

MessageId = 1747 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_UNKNOWN_AUTHN_SERVICE
.

MessageId = 1748 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_UNKNOWN_AUTHN_LEVEL
.

MessageId = 1749 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_AUTH_IDENTITY
.

MessageId = 1750 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_UNKNOWN_AUTHZ_SERVICE
.

MessageId = 1751 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
EPT_S_INVALID_ENTRY
.

MessageId = 1752 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
EPT_S_CANT_PERFORM_OP
.

MessageId = 1753 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
EPT_S_NOT_REGISTERED
.

MessageId = 1754 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NOTHING_TO_EXPORT
.

MessageId = 1755 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INCOMPLETE_NAME
.

MessageId = 1756 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_VERS_OPTION
.

MessageId = 1757 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NO_MORE_MEMBERS
.

MessageId = 1758 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NOT_ALL_OBJS_UNEXPORTED
.

MessageId = 1759 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INTERFACE_NOT_FOUND
.

MessageId = 1760 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_ENTRY_ALREADY_EXISTS
.

MessageId = 1761 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_ENTRY_NOT_FOUND
.

MessageId = 1762 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NAME_SERVICE_UNAVAILABLE
.

MessageId = 1763 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_NAF_ID
.

MessageId = 1764 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_CANNOT_SUPPORT
.

MessageId = 1765 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NO_CONTEXT_AVAILABLE
.

MessageId = 1766 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INTERNAL_ERROR
.

MessageId = 1767 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_ZERO_DIVIDE
.

MessageId = 1768 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_ADDRESS_ERROR
.

MessageId = 1769 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_FP_DIV_ZERO
.

MessageId = 1770 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_FP_UNDERFLOW
.

MessageId = 1771 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_FP_OVERFLOW
.

MessageId = 1772 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_NO_MORE_ENTRIES
.

MessageId = 1773 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_SS_CHAR_TRANS_OPEN_FAIL
.

MessageId = 1774 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_SS_CHAR_TRANS_SHORT_FILE
.

MessageId = 1775 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_SS_IN_NULL_CONTEXT
.

MessageId = 1777 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_SS_CONTEXT_DAMAGED
.

MessageId = 1778 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_SS_HANDLES_MISMATCH
.

MessageId = 1779 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_SS_CANNOT_GET_CALL_HANDLE
.

MessageId = 1780 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_NULL_REF_POINTER
.

MessageId = 1781 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_ENUM_VALUE_OUT_OF_RANGE
.

MessageId = 1782 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_BYTE_COUNT_TOO_SMALL
.

MessageId = 1783 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_BAD_STUB_DATA
.

MessageId = 1784 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_USER_BUFFER
.

MessageId = 1785 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNRECOGNIZED_MEDIA
.

MessageId = 1786 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_TRUST_LSA_SECRET
.

MessageId = 1787 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_TRUST_SAM_ACCOUNT
.

MessageId = 1788 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRUSTED_DOMAIN_FAILURE
.

MessageId = 1789 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRUSTED_RELATIONSHIP_FAILURE
.

MessageId = 1790 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRUST_FAILURE
.

MessageId = 1791 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_CALL_IN_PROGRESS
.

MessageId = 1792 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NETLOGON_NOT_STARTED
.

MessageId = 1793 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ACCOUNT_EXPIRED
.

MessageId = 1794 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REDIRECTOR_HAS_OPEN_HANDLES
.

MessageId = 1796 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNKNOWN_PORT
.

MessageId = 1797 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNKNOWN_PRINTER_DRIVER
.

MessageId = 1798 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNKNOWN_PRINTPROCESSOR
.

MessageId = 1799 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_SEPARATOR_FILE
.

MessageId = 1800 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_PRIORITY
.

MessageId = 1801 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_PRINTER_NAME
.

MessageId = 1803 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_PRINTER_COMMAND
.

MessageId = 1804 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_DATATYPE
.

MessageId = 1805 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_ENVIRONMENT
.

MessageId = 1806 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NO_MORE_BINDINGS
.

MessageId = 1807 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOLOGON_INTERDOMAIN_TRUST_ACCOUNT
.

MessageId = 1808 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOLOGON_WORKSTATION_TRUST_ACCOUNT
.

MessageId = 1809 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOLOGON_SERVER_TRUST_ACCOUNT
.

MessageId = 1810 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DOMAIN_TRUST_INCONSISTENT
.

MessageId = 1811 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVER_HAS_OPEN_HANDLES
.

MessageId = 1812 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RESOURCE_DATA_NOT_FOUND
.

MessageId = 1813 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RESOURCE_TYPE_NOT_FOUND
.

MessageId = 1814 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RESOURCE_NAME_NOT_FOUND
.

MessageId = 1815 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RESOURCE_LANG_NOT_FOUND
.

MessageId = 1816 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_ENOUGH_QUOTA
.

MessageId = 1817 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NO_INTERFACES
.

MessageId = 1818 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_CALL_CANCELLED
.

MessageId = 1819 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_BINDING_INCOMPLETE
.

MessageId = 1820 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_COMM_FAILURE
.

MessageId = 1821 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_UNSUPPORTED_AUTHN_LEVEL
.

MessageId = 1822 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NO_PRINC_NAME
.

MessageId = 1823 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NOT_RPC_ERROR
.

MessageId = 1824 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_UUID_LOCAL_ONLY
.

MessageId = 1825 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_SEC_PKG_ERROR
.

MessageId = 1826 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NOT_CANCELLED
.

MessageId = 1827 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_INVALID_ES_ACTION
.

MessageId = 1828 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_WRONG_ES_VERSION
.

MessageId = 1829 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_WRONG_STUB_VERSION
.

MessageId = 1830 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_INVALID_PIPE_OBJECT
.

MessageId = 1831 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_WRONG_PIPE_ORDER
.

MessageId = 1832 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_WRONG_PIPE_VERSION
.

MessageId = 1833 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_COOKIE_AUTH_FAILED
.

MessageId = 1834 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_DO_NOT_DISTURB
.

MessageId = 1835 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_SYSTEM_HANDLE_COUNT_EXCEEDED
.

MessageId = 1836 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_SYSTEM_HANDLE_TYPE_MISMATCH
.

MessageId = 1898 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_GROUP_MEMBER_NOT_FOUND
.

MessageId = 1899 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
EPT_S_CANT_CREATE
.

MessageId = 1900 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_OBJECT
.

MessageId = 1901 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_TIME
.

MessageId = 1902 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_FORM_NAME
.

MessageId = 1903 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_FORM_SIZE
.

MessageId = 1904 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ALREADY_WAITING
.

MessageId = 1906 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_PRINTER_STATE
.

MessageId = 1907 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PASSWORD_MUST_CHANGE
.

MessageId = 1908 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DOMAIN_CONTROLLER_NOT_FOUND
.

MessageId = 1909 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ACCOUNT_LOCKED_OUT
.

MessageId = 1910 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
OR_INVALID_OXID
.

MessageId = 1911 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
OR_INVALID_OID
.

MessageId = 1912 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
OR_INVALID_SET
.

MessageId = 1913 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_SEND_INCOMPLETE
.

MessageId = 1914 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_ASYNC_HANDLE
.

MessageId = 1915 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INVALID_ASYNC_CALL
.

MessageId = 1916 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_PIPE_CLOSED
.

MessageId = 1917 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_PIPE_DISCIPLINE_ERROR
.

MessageId = 1918 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_X_PIPE_EMPTY
.

MessageId = 1919 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SITENAME
.

MessageId = 1920 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANT_ACCESS_FILE
.

MessageId = 1921 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANT_RESOLVE_FILENAME
.

MessageId = 1922 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_ENTRY_TYPE_MISMATCH
.

MessageId = 1923 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_NOT_ALL_OBJS_EXPORTED
.

MessageId = 1924 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_INTERFACE_NOT_EXPORTED
.

MessageId = 1925 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_PROFILE_NOT_ADDED
.

MessageId = 1926 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_PRF_ELT_NOT_ADDED
.

MessageId = 1927 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_PRF_ELT_NOT_REMOVED
.

MessageId = 1928 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_GRP_ELT_NOT_ADDED
.

MessageId = 1929 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
RPC_S_GRP_ELT_NOT_REMOVED
.

MessageId = 1930 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_KM_DRIVER_BLOCKED
.

MessageId = 1931 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CONTEXT_EXPIRED
.

MessageId = 1932 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PER_USER_TRUST_QUOTA_EXCEEDED
.

MessageId = 1933 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ALL_USER_TRUST_QUOTA_EXCEEDED
.

MessageId = 1934 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_USER_DELETE_TRUST_QUOTA_EXCEEDED
.

MessageId = 1935 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_AUTHENTICATION_FIREWALL_FAILED
.

MessageId = 1936 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REMOTE_PRINT_CONNECTIONS_BLOCKED
.

MessageId = 1937 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NTLM_BLOCKED
.

MessageId = 1938 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PASSWORD_CHANGE_REQUIRED
.

MessageId = 1939 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOST_MODE_LOGON_RESTRICTION
.

MessageId = 2000 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_PIXEL_FORMAT
.

MessageId = 2001 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_DRIVER
.

MessageId = 2002 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_WINDOW_STYLE
.

MessageId = 2003 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_METAFILE_NOT_SUPPORTED
.

MessageId = 2004 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSFORM_NOT_SUPPORTED
.

MessageId = 2005 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLIPPING_NOT_SUPPORTED
.

MessageId = 2010 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_CMM
.

MessageId = 2011 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_PROFILE
.

MessageId = 2012 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TAG_NOT_FOUND
.

MessageId = 2013 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TAG_NOT_PRESENT
.

MessageId = 2014 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DUPLICATE_TAG
.

MessageId = 2015 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PROFILE_NOT_ASSOCIATED_WITH_DEVICE
.

MessageId = 2016 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PROFILE_NOT_FOUND
.

MessageId = 2017 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_COLORSPACE
.

MessageId = 2018 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ICM_NOT_ENABLED
.

MessageId = 2019 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DELETING_ICM_XFORM
.

MessageId = 2020 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_TRANSFORM
.

MessageId = 2021 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_COLORSPACE_MISMATCH
.

MessageId = 2022 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_COLORINDEX
.

MessageId = 2023 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PROFILE_DOES_NOT_MATCH_DEVICE
.

MessageId = 2108 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CONNECTED_OTHER_PASSWORD
.

MessageId = 2109 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CONNECTED_OTHER_PASSWORD_DEFAULT
.

MessageId = 2202 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_USERNAME
.

MessageId = 2250 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_CONNECTED
.

MessageId = 2401 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OPEN_FILES
.

MessageId = 2402 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ACTIVE_CONNECTIONS
.

MessageId = 2404 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEVICE_IN_USE
.

MessageId = 3050 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REQUEST_PAUSED
.

MessageId = 3060 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPEXEC_CONDITION_NOT_SATISFIED
.

MessageId = 3061 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPEXEC_HANDLE_INVALIDATED
.

MessageId = 3062 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPEXEC_INVALID_HOST_GENERATION
.

MessageId = 3063 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPEXEC_UNEXPECTED_PROCESS_REGISTRATION
.

MessageId = 3064 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPEXEC_INVALID_HOST_STATE
.

MessageId = 3065 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPEXEC_NO_DONOR
.

MessageId = 3066 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPEXEC_HOST_ID_MISMATCH
.

MessageId = 3067 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPEXEC_UNKNOWN_USER
.

MessageId = 3068 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPEXEC_APP_COMPAT_BLOCK
.

MessageId = 3069 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPEXEC_CALLER_WAIT_TIMEOUT
.

MessageId = 3070 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPEXEC_CALLER_WAIT_TIMEOUT_TERMINATION
.

MessageId = 3071 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPEXEC_CALLER_WAIT_TIMEOUT_LICENSING
.

MessageId = 3072 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPEXEC_CALLER_WAIT_TIMEOUT_RESOURCES
.

MessageId = 3950 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IO_REISSUE_AS_CACHED
.

MessageId = 4200 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WMI_GUID_NOT_FOUND
.

MessageId = 4201 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WMI_INSTANCE_NOT_FOUND
.

MessageId = 4202 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WMI_ITEMID_NOT_FOUND
.

MessageId = 4203 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WMI_TRY_AGAIN
.

MessageId = 4204 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WMI_DP_NOT_FOUND
.

MessageId = 4205 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WMI_UNRESOLVED_INSTANCE_REF
.

MessageId = 4206 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WMI_ALREADY_ENABLED
.

MessageId = 4207 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WMI_GUID_DISCONNECTED
.

MessageId = 4208 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WMI_SERVER_UNAVAILABLE
.

MessageId = 4209 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WMI_DP_FAILED
.

MessageId = 4210 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WMI_INVALID_MOF
.

MessageId = 4211 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WMI_INVALID_REGINFO
.

MessageId = 4212 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WMI_ALREADY_DISABLED
.

MessageId = 4213 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WMI_READ_ONLY
.

MessageId = 4214 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WMI_SET_FAILURE
.

MessageId = 4250 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_APPCONTAINER
.

MessageId = 4251 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPCONTAINER_REQUIRED
.

MessageId = 4252 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SUPPORTED_IN_APPCONTAINER
.

MessageId = 4253 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_PACKAGE_SID_LENGTH
.

MessageId = 4390 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_A_REPARSE_POINT
.

MessageId = 4391 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REPARSE_ATTRIBUTE_CONFLICT
.

MessageId = 4392 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_REPARSE_DATA
.

MessageId = 4393 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REPARSE_TAG_INVALID
.

MessageId = 4394 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REPARSE_TAG_MISMATCH
.

MessageId = 4395 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REPARSE_POINT_ENCOUNTERED
.

MessageId = 4440 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OFFLOAD_READ_FLT_NOT_SUPPORTED
.

MessageId = 4441 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OFFLOAD_WRITE_FLT_NOT_SUPPORTED
.

MessageId = 4442 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OFFLOAD_READ_FILE_NOT_SUPPORTED
.

MessageId = 4443 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OFFLOAD_WRITE_FILE_NOT_SUPPORTED
.

MessageId = 4444 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ALREADY_HAS_STREAM_ID
.

MessageId = 4445 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SMR_GARBAGE_COLLECTION_REQUIRED
.

MessageId = 4446 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WOF_WIM_HEADER_CORRUPT
.

MessageId = 4447 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WOF_WIM_RESOURCE_TABLE_CORRUPT
.

MessageId = 4448 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WOF_FILE_RESOURCE_TABLE_CORRUPT
.

MessageId = 4449 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OBJECT_IS_IMMUTABLE
.

MessageId = 4550 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_INTEGRITY_ROLLBACK_DETECTED
.

MessageId = 4551 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_INTEGRITY_POLICY_VIOLATION
.

MessageId = 4552 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_INTEGRITY_INVALID_POLICY
.

MessageId = 4553 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_INTEGRITY_POLICY_NOT_SIGNED
.

MessageId = 4554 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_INTEGRITY_TOO_MANY_POLICIES
.

MessageId = 4555 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_INTEGRITY_SUPPLEMENTAL_POLICY_NOT_AUTHORIZED
.

MessageId = 4556 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_INTEGRITY_REPUTATION_MALICIOUS
.

MessageId = 4557 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_INTEGRITY_REPUTATION_PUA
.

MessageId = 4558 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_INTEGRITY_REPUTATION_DANGEROUS_EXT
.

MessageId = 4559 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_INTEGRITY_REPUTATION_OFFLINE
.

MessageId = 4580 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_INTEGRITY_REPUTATION_UNFRIENDLY_FILE
.

MessageId = 4581 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_INTEGRITY_REPUTATION_UNATTAINABLE
.

MessageId = 6000 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ENCRYPTION_FAILED
.

MessageId = 6001 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DECRYPTION_FAILED
.

MessageId = 6002 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_ENCRYPTED
.

MessageId = 6003 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_RECOVERY_POLICY
.

MessageId = 6004 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_EFS
.

MessageId = 6005 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WRONG_EFS
.

MessageId = 6006 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_USER_KEYS
.

MessageId = 6007 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_NOT_ENCRYPTED
.

MessageId = 6008 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_EXPORT_FORMAT
.

MessageId = 6009 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_READ_ONLY
.

MessageId = 6010 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DIR_EFS_DISALLOWED
.

MessageId = 6011 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EFS_SERVER_NOT_TRUSTED
.

MessageId = 6012 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_RECOVERY_POLICY
.

MessageId = 6013 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EFS_ALG_BLOB_TOO_BIG
.

MessageId = 6014 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_VOLUME_NOT_SUPPORT_EFS
.

MessageId = 6015 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EFS_DISABLED
.

MessageId = 6016 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EFS_VERSION_NOT_SUPPORT
.

MessageId = 6017 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CS_ENCRYPTION_INVALID_SERVER_RESPONSE
.

MessageId = 6018 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CS_ENCRYPTION_UNSUPPORTED_SERVER
.

MessageId = 6019 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CS_ENCRYPTION_EXISTING_ENCRYPTED_FILE
.

MessageId = 6020 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CS_ENCRYPTION_NEW_ENCRYPTED_FILE
.

MessageId = 6021 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CS_ENCRYPTION_FILE_NOT_CSE
.

MessageId = 6022 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ENCRYPTION_POLICY_DENIES_OPERATION
.

MessageId = 6023 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_WIP_ENCRYPTION_FAILED
.

MessageId = 6200 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
SCHED_E_SERVICE_NOT_LOCALSYSTEM
.

MessageId = 6600 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_SECTOR_INVALID
.

MessageId = 6601 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_SECTOR_PARITY_INVALID
.

MessageId = 6602 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_SECTOR_REMAPPED
.

MessageId = 6603 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_BLOCK_INCOMPLETE
.

MessageId = 6604 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_INVALID_RANGE
.

MessageId = 6605 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_BLOCKS_EXHAUSTED
.

MessageId = 6606 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_READ_CONTEXT_INVALID
.

MessageId = 6607 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_RESTART_INVALID
.

MessageId = 6608 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_BLOCK_VERSION
.

MessageId = 6609 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_BLOCK_INVALID
.

MessageId = 6610 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_READ_MODE_INVALID
.

MessageId = 6611 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_NO_RESTART
.

MessageId = 6612 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_METADATA_CORRUPT
.

MessageId = 6613 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_METADATA_INVALID
.

MessageId = 6614 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_METADATA_INCONSISTENT
.

MessageId = 6615 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_RESERVATION_INVALID
.

MessageId = 6616 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_CANT_DELETE
.

MessageId = 6617 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_CONTAINER_LIMIT_EXCEEDED
.

MessageId = 6618 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_START_OF_LOG
.

MessageId = 6619 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_POLICY_ALREADY_INSTALLED
.

MessageId = 6620 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_POLICY_NOT_INSTALLED
.

MessageId = 6621 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_POLICY_INVALID
.

MessageId = 6622 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_POLICY_CONFLICT
.

MessageId = 6623 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_PINNED_ARCHIVE_TAIL
.

MessageId = 6624 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_RECORD_NONEXISTENT
.

MessageId = 6625 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_RECORDS_RESERVED_INVALID
.

MessageId = 6626 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_SPACE_RESERVED_INVALID
.

MessageId = 6627 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_TAIL_INVALID
.

MessageId = 6628 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_FULL
.

MessageId = 6629 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_COULD_NOT_RESIZE_LOG
.

MessageId = 6630 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_MULTIPLEXED
.

MessageId = 6631 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_DEDICATED
.

MessageId = 6632 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_ARCHIVE_NOT_IN_PROGRESS
.

MessageId = 6633 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_ARCHIVE_IN_PROGRESS
.

MessageId = 6634 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_EPHEMERAL
.

MessageId = 6635 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_NOT_ENOUGH_CONTAINERS
.

MessageId = 6636 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_CLIENT_ALREADY_REGISTERED
.

MessageId = 6637 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_CLIENT_NOT_REGISTERED
.

MessageId = 6638 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_FULL_HANDLER_IN_PROGRESS
.

MessageId = 6639 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_CONTAINER_READ_FAILED
.

MessageId = 6640 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_CONTAINER_WRITE_FAILED
.

MessageId = 6641 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_CONTAINER_OPEN_FAILED
.

MessageId = 6642 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_CONTAINER_STATE_INVALID
.

MessageId = 6643 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_STATE_INVALID
.

MessageId = 6644 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_PINNED
.

MessageId = 6645 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_METADATA_FLUSH_FAILED
.

MessageId = 6646 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_INCONSISTENT_SECURITY
.

MessageId = 6647 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_APPENDED_FLUSH_FAILED
.

MessageId = 6648 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_PINNED_RESERVATION
.

MessageId = 6700 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_TRANSACTION
.

MessageId = 6701 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_NOT_ACTIVE
.

MessageId = 6702 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_REQUEST_NOT_VALID
.

MessageId = 6703 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_NOT_REQUESTED
.

MessageId = 6704 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_ALREADY_ABORTED
.

MessageId = 6705 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_ALREADY_COMMITTED
.

MessageId = 6706 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TM_INITIALIZATION_FAILED
.

MessageId = 6707 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RESOURCEMANAGER_READ_ONLY
.

MessageId = 6708 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_NOT_JOINED
.

MessageId = 6709 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_SUPERIOR_EXISTS
.

MessageId = 6710 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CRM_PROTOCOL_ALREADY_EXISTS
.

MessageId = 6711 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_PROPAGATION_FAILED
.

MessageId = 6712 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CRM_PROTOCOL_NOT_FOUND
.

MessageId = 6713 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_INVALID_MARSHALL_BUFFER
.

MessageId = 6714 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CURRENT_TRANSACTION_NOT_VALID
.

MessageId = 6715 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_NOT_FOUND
.

MessageId = 6716 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RESOURCEMANAGER_NOT_FOUND
.

MessageId = 6717 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ENLISTMENT_NOT_FOUND
.

MessageId = 6718 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTIONMANAGER_NOT_FOUND
.

MessageId = 6719 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTIONMANAGER_NOT_ONLINE
.

MessageId = 6720 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTIONMANAGER_RECOVERY_NAME_COLLISION
.

MessageId = 6721 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_NOT_ROOT
.

MessageId = 6722 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_OBJECT_EXPIRED
.

MessageId = 6723 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_RESPONSE_NOT_ENLISTED
.

MessageId = 6724 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_RECORD_TOO_LONG
.

MessageId = 6725 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_IMPLICIT_TRANSACTION_NOT_SUPPORTED
.

MessageId = 6726 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_INTEGRITY_VIOLATED
.

MessageId = 6727 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTIONMANAGER_IDENTITY_MISMATCH
.

MessageId = 6728 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RM_CANNOT_BE_FROZEN_FOR_SNAPSHOT
.

MessageId = 6729 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_MUST_WRITETHROUGH
.

MessageId = 6730 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_NO_SUPERIOR
.

MessageId = 6731 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HEURISTIC_DAMAGE_POSSIBLE
.

MessageId = 6800 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTIONAL_CONFLICT
.

MessageId = 6801 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RM_NOT_ACTIVE
.

MessageId = 6802 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RM_METADATA_CORRUPT
.

MessageId = 6803 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DIRECTORY_NOT_RM
.

MessageId = 6805 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTIONS_UNSUPPORTED_REMOTE
.

MessageId = 6806 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_RESIZE_INVALID_SIZE
.

MessageId = 6807 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OBJECT_NO_LONGER_EXISTS
.

MessageId = 6808 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STREAM_MINIVERSION_NOT_FOUND
.

MessageId = 6809 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STREAM_MINIVERSION_NOT_VALID
.

MessageId = 6810 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MINIVERSION_INACCESSIBLE_FROM_SPECIFIED_TRANSACTION
.

MessageId = 6811 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANT_OPEN_MINIVERSION_WITH_MODIFY_INTENT
.

MessageId = 6812 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANT_CREATE_MORE_STREAM_MINIVERSIONS
.

MessageId = 6814 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REMOTE_FILE_VERSION_MISMATCH
.

MessageId = 6815 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_HANDLE_NO_LONGER_VALID
.

MessageId = 6816 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_TXF_METADATA
.

MessageId = 6817 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_CORRUPTION_DETECTED
.

MessageId = 6818 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANT_RECOVER_WITH_HANDLE_OPEN
.

MessageId = 6819 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RM_DISCONNECTED
.

MessageId = 6820 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ENLISTMENT_NOT_SUPERIOR
.

MessageId = 6821 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RECOVERY_NOT_NEEDED
.

MessageId = 6822 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RM_ALREADY_STARTED
.

MessageId = 6823 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FILE_IDENTITY_NOT_PERSISTENT
.

MessageId = 6824 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANT_BREAK_TRANSACTIONAL_DEPENDENCY
.

MessageId = 6825 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANT_CROSS_RM_BOUNDARY
.

MessageId = 6826 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TXF_DIR_NOT_EMPTY
.

MessageId = 6827 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INDOUBT_TRANSACTIONS_EXIST
.

MessageId = 6828 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TM_VOLATILE
.

MessageId = 6829 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ROLLBACK_TIMER_EXPIRED
.

MessageId = 6830 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TXF_ATTRIBUTE_CORRUPT
.

MessageId = 6831 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EFS_NOT_ALLOWED_IN_TRANSACTION
.

MessageId = 6832 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTIONAL_OPEN_NOT_ALLOWED
.

MessageId = 6833 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_LOG_GROWTH_FAILED
.

MessageId = 6834 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTED_MAPPING_UNSUPPORTED_REMOTE
.

MessageId = 6835 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TXF_METADATA_ALREADY_PRESENT
.

MessageId = 6836 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_SCOPE_CALLBACKS_NOT_SET
.

MessageId = 6837 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_REQUIRED_PROMOTION
.

MessageId = 6838 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANNOT_EXECUTE_FILE_IN_TRANSACTION
.

MessageId = 6839 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTIONS_NOT_FROZEN
.

MessageId = 6840 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_FREEZE_IN_PROGRESS
.

MessageId = 6841 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NOT_SNAPSHOT_VOLUME
.

MessageId = 6842 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_SAVEPOINT_WITH_OPEN_FILES
.

MessageId = 6843 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DATA_LOST_REPAIR
.

MessageId = 6844 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SPARSE_NOT_ALLOWED_IN_TRANSACTION
.

MessageId = 6845 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TM_IDENTITY_MISMATCH
.

MessageId = 6846 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_FLOATED_SECTION
.

MessageId = 6847 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANNOT_ACCEPT_TRANSACTED_WORK
.

MessageId = 6848 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CANNOT_ABORT_TRANSACTIONS
.

MessageId = 6849 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_BAD_CLUSTERS
.

MessageId = 6850 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_COMPRESSION_NOT_ALLOWED_IN_TRANSACTION
.

MessageId = 6851 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_VOLUME_DIRTY
.

MessageId = 6852 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NO_LINK_TRACKING_IN_TRANSACTION
.

MessageId = 6853 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OPERATION_NOT_SUPPORTED_IN_TRANSACTION
.

MessageId = 6854 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EXPIRED_HANDLE
.

MessageId = 6855 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TRANSACTION_NOT_ENLISTED
.

MessageId = 7001 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_WINSTATION_NAME_INVALID
.

MessageId = 7002 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_INVALID_PD
.

MessageId = 7003 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_PD_NOT_FOUND
.

MessageId = 7004 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_WD_NOT_FOUND
.

MessageId = 7005 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_CANNOT_MAKE_EVENTLOG_ENTRY
.

MessageId = 7006 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_SERVICE_NAME_COLLISION
.

MessageId = 7007 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_CLOSE_PENDING
.

MessageId = 7008 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_NO_OUTBUF
.

MessageId = 7009 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_MODEM_INF_NOT_FOUND
.

MessageId = 7010 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_INVALID_MODEMNAME
.

MessageId = 7011 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_MODEM_RESPONSE_ERROR
.

MessageId = 7012 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_MODEM_RESPONSE_TIMEOUT
.

MessageId = 7013 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_MODEM_RESPONSE_NO_CARRIER
.

MessageId = 7014 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_MODEM_RESPONSE_NO_DIALTONE
.

MessageId = 7015 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_MODEM_RESPONSE_BUSY
.

MessageId = 7016 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_MODEM_RESPONSE_VOICE
.

MessageId = 7017 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_TD_ERROR
.

MessageId = 7022 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_WINSTATION_NOT_FOUND
.

MessageId = 7023 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_WINSTATION_ALREADY_EXISTS
.

MessageId = 7024 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_WINSTATION_BUSY
.

MessageId = 7025 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_BAD_VIDEO_MODE
.

MessageId = 7035 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_GRAPHICS_INVALID
.

MessageId = 7037 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_LOGON_DISABLED
.

MessageId = 7038 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_NOT_CONSOLE
.

MessageId = 7040 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_CLIENT_QUERY_TIMEOUT
.

MessageId = 7041 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_CONSOLE_DISCONNECT
.

MessageId = 7042 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_CONSOLE_CONNECT
.

MessageId = 7044 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_SHADOW_DENIED
.

MessageId = 7045 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_WINSTATION_ACCESS_DENIED
.

MessageId = 7049 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_INVALID_WD
.

MessageId = 7050 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_SHADOW_INVALID
.

MessageId = 7051 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_SHADOW_DISABLED
.

MessageId = 7052 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_CLIENT_LICENSE_IN_USE
.

MessageId = 7053 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_CLIENT_LICENSE_NOT_SET
.

MessageId = 7054 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_LICENSE_NOT_AVAILABLE
.

MessageId = 7055 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_LICENSE_CLIENT_INVALID
.

MessageId = 7056 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_LICENSE_EXPIRED
.

MessageId = 7057 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_SHADOW_NOT_RUNNING
.

MessageId = 7058 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_SHADOW_ENDED_BY_MODE_CHANGE
.

MessageId = 7059 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ACTIVATION_COUNT_EXCEEDED
.

MessageId = 7060 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_WINSTATIONS_DISABLED
.

MessageId = 7061 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_ENCRYPTION_LEVEL_REQUIRED
.

MessageId = 7062 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_SESSION_IN_USE
.

MessageId = 7063 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_NO_FORCE_LOGOFF
.

MessageId = 7064 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_ACCOUNT_RESTRICTION
.

MessageId = 7065 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RDP_PROTOCOL_ERROR
.

MessageId = 7066 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_CDM_CONNECT
.

MessageId = 7067 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_CDM_DISCONNECT
.

MessageId = 7068 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CTX_SECURITY_LAYER_ERROR
.

MessageId = 7069 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TS_INCOMPATIBLE_SESSIONS
.

MessageId = 7070 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_TS_VIDEO_SUBSYSTEM_ERROR
.

MessageId = 14000 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_SECTION_NOT_FOUND
.

MessageId = 14001 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_CANT_GEN_ACTCTX
.

MessageId = 14002 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_INVALID_ACTCTXDATA_FORMAT
.

MessageId = 14003 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_ASSEMBLY_NOT_FOUND
.

MessageId = 14004 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_MANIFEST_FORMAT_ERROR
.

MessageId = 14005 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_MANIFEST_PARSE_ERROR
.

MessageId = 14006 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_ACTIVATION_CONTEXT_DISABLED
.

MessageId = 14007 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_KEY_NOT_FOUND
.

MessageId = 14008 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_VERSION_CONFLICT
.

MessageId = 14009 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_WRONG_SECTION_TYPE
.

MessageId = 14010 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_THREAD_QUERIES_DISABLED
.

MessageId = 14011 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_PROCESS_DEFAULT_ALREADY_SET
.

MessageId = 14012 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_UNKNOWN_ENCODING_GROUP
.

MessageId = 14013 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_UNKNOWN_ENCODING
.

MessageId = 14014 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_INVALID_XML_NAMESPACE_URI
.

MessageId = 14015 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_ROOT_MANIFEST_DEPENDENCY_NOT_INSTALLED
.

MessageId = 14016 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_LEAF_MANIFEST_DEPENDENCY_NOT_INSTALLED
.

MessageId = 14017 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_INVALID_ASSEMBLY_IDENTITY_ATTRIBUTE
.

MessageId = 14018 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_MANIFEST_MISSING_REQUIRED_DEFAULT_NAMESPACE
.

MessageId = 14019 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_MANIFEST_INVALID_REQUIRED_DEFAULT_NAMESPACE
.

MessageId = 14020 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_PRIVATE_MANIFEST_CROSS_PATH_WITH_REPARSE_POINT
.

MessageId = 14021 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_DUPLICATE_DLL_NAME
.

MessageId = 14022 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_DUPLICATE_WINDOWCLASS_NAME
.

MessageId = 14023 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_DUPLICATE_CLSID
.

MessageId = 14024 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_DUPLICATE_IID
.

MessageId = 14025 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_DUPLICATE_TLBID
.

MessageId = 14026 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_DUPLICATE_PROGID
.

MessageId = 14027 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_DUPLICATE_ASSEMBLY_NAME
.

MessageId = 14028 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_FILE_HASH_MISMATCH
.

MessageId = 14029 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_POLICY_PARSE_ERROR
.

MessageId = 14030 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_MISSINGQUOTE
.

MessageId = 14031 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_COMMENTSYNTAX
.

MessageId = 14032 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_BADSTARTNAMECHAR
.

MessageId = 14033 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_BADNAMECHAR
.

MessageId = 14034 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_BADCHARINSTRING
.

MessageId = 14035 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_XMLDECLSYNTAX
.

MessageId = 14036 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_BADCHARDATA
.

MessageId = 14037 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_MISSINGWHITESPACE
.

MessageId = 14038 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_EXPECTINGTAGEND
.

MessageId = 14039 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_MISSINGSEMICOLON
.

MessageId = 14040 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_UNBALANCEDPAREN
.

MessageId = 14041 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_INTERNALERROR
.

MessageId = 14042 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_UNEXPECTED_WHITESPACE
.

MessageId = 14043 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_INCOMPLETE_ENCODING
.

MessageId = 14044 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_MISSING_PAREN
.

MessageId = 14045 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_EXPECTINGCLOSEQUOTE
.

MessageId = 14046 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_MULTIPLE_COLONS
.

MessageId = 14047 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_INVALID_DECIMAL
.

MessageId = 14048 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_INVALID_HEXIDECIMAL
.

MessageId = 14049 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_INVALID_UNICODE
.

MessageId = 14050 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_WHITESPACEORQUESTIONMARK
.

MessageId = 14051 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_UNEXPECTEDENDTAG
.

MessageId = 14052 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_UNCLOSEDTAG
.

MessageId = 14053 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_DUPLICATEATTRIBUTE
.

MessageId = 14054 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_MULTIPLEROOTS
.

MessageId = 14055 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_INVALIDATROOTLEVEL
.

MessageId = 14056 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_BADXMLDECL
.

MessageId = 14057 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_MISSINGROOT
.

MessageId = 14058 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_UNEXPECTEDEOF
.

MessageId = 14059 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_BADPEREFINSUBSET
.

MessageId = 14060 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_UNCLOSEDSTARTTAG
.

MessageId = 14061 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_UNCLOSEDENDTAG
.

MessageId = 14062 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_UNCLOSEDSTRING
.

MessageId = 14063 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_UNCLOSEDCOMMENT
.

MessageId = 14064 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_UNCLOSEDDECL
.

MessageId = 14065 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_UNCLOSEDCDATA
.

MessageId = 14066 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_RESERVEDNAMESPACE
.

MessageId = 14067 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_INVALIDENCODING
.

MessageId = 14068 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_INVALIDSWITCH
.

MessageId = 14069 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_BADXMLCASE
.

MessageId = 14070 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_INVALID_STANDALONE
.

MessageId = 14071 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_UNEXPECTED_STANDALONE
.

MessageId = 14072 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_INVALID_VERSION
.

MessageId = 14073 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_XML_E_MISSINGEQUALS
.

MessageId = 14074 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_PROTECTION_RECOVERY_FAILED
.

MessageId = 14075 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_PROTECTION_PUBLIC_KEY_TOO_SHORT
.

MessageId = 14076 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_PROTECTION_CATALOG_NOT_VALID
.

MessageId = 14077 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_UNTRANSLATABLE_HRESULT
.

MessageId = 14078 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_PROTECTION_CATALOG_FILE_MISSING
.

MessageId = 14079 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_MISSING_ASSEMBLY_IDENTITY_ATTRIBUTE
.

MessageId = 14080 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_INVALID_ASSEMBLY_IDENTITY_ATTRIBUTE_NAME
.

MessageId = 14081 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_ASSEMBLY_MISSING
.

MessageId = 14082 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_CORRUPT_ACTIVATION_STACK
.

MessageId = 14083 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_CORRUPTION
.

MessageId = 14084 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_EARLY_DEACTIVATION
.

MessageId = 14085 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_INVALID_DEACTIVATION
.

MessageId = 14086 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_MULTIPLE_DEACTIVATION
.

MessageId = 14087 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_PROCESS_TERMINATION_REQUESTED
.

MessageId = 14088 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_RELEASE_ACTIVATION_CONTEXT
.

MessageId = 14089 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_SYSTEM_DEFAULT_ACTIVATION_CONTEXT_EMPTY
.

MessageId = 14090 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_INVALID_IDENTITY_ATTRIBUTE_VALUE
.

MessageId = 14091 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_INVALID_IDENTITY_ATTRIBUTE_NAME
.

MessageId = 14092 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_IDENTITY_DUPLICATE_ATTRIBUTE
.

MessageId = 14093 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_IDENTITY_PARSE_ERROR
.

MessageId = 14094 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MALFORMED_SUBSTITUTION_STRING
.

MessageId = 14095 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_INCORRECT_PUBLIC_KEY_TOKEN
.

MessageId = 14096 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNMAPPED_SUBSTITUTION_STRING
.

MessageId = 14097 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_ASSEMBLY_NOT_LOCKED
.

MessageId = 14098 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_COMPONENT_STORE_CORRUPT
.

MessageId = 14099 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_ADVANCED_INSTALLER_FAILED
.

MessageId = 14100 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_XML_ENCODING_MISMATCH
.

MessageId = 14101 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_MANIFEST_IDENTITY_SAME_BUT_CONTENTS_DIFFERENT
.

MessageId = 14102 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_IDENTITIES_DIFFERENT
.

MessageId = 14103 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_ASSEMBLY_IS_NOT_A_DEPLOYMENT
.

MessageId = 14104 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_FILE_NOT_PART_OF_ASSEMBLY
.

MessageId = 14105 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_MANIFEST_TOO_BIG
.

MessageId = 14106 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_SETTING_NOT_REGISTERED
.

MessageId = 14107 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_TRANSACTION_CLOSURE_INCOMPLETE
.

MessageId = 14108 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SMI_PRIMITIVE_INSTALLER_FAILED
.

MessageId = 14109 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_GENERIC_COMMAND_FAILED
.

MessageId = 14110 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_FILE_HASH_MISSING
.

MessageId = 14111 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SXS_DUPLICATE_ACTIVATABLE_CLASS
.

MessageId = 15000 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_INVALID_CHANNEL_PATH
.

MessageId = 15001 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_INVALID_QUERY
.

MessageId = 15002 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_PUBLISHER_METADATA_NOT_FOUND
.

MessageId = 15003 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_EVENT_TEMPLATE_NOT_FOUND
.

MessageId = 15004 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_INVALID_PUBLISHER_NAME
.

MessageId = 15005 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_INVALID_EVENT_DATA
.

MessageId = 15007 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_CHANNEL_NOT_FOUND
.

MessageId = 15008 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_MALFORMED_XML_TEXT
.

MessageId = 15009 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_SUBSCRIPTION_TO_DIRECT_CHANNEL
.

MessageId = 15010 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_CONFIGURATION_ERROR
.

MessageId = 15011 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_QUERY_RESULT_STALE
.

MessageId = 15012 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_QUERY_RESULT_INVALID_POSITION
.

MessageId = 15013 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_NON_VALIDATING_MSXML
.

MessageId = 15014 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_FILTER_ALREADYSCOPED
.

MessageId = 15015 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_FILTER_NOTELTSET
.

MessageId = 15016 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_FILTER_INVARG
.

MessageId = 15017 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_FILTER_INVTEST
.

MessageId = 15018 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_FILTER_INVTYPE
.

MessageId = 15019 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_FILTER_PARSEERR
.

MessageId = 15020 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_FILTER_UNSUPPORTEDOP
.

MessageId = 15021 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_FILTER_UNEXPECTEDTOKEN
.

MessageId = 15022 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_INVALID_OPERATION_OVER_ENABLED_DIRECT_CHANNEL
.

MessageId = 15023 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_INVALID_CHANNEL_PROPERTY_VALUE
.

MessageId = 15024 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_INVALID_PUBLISHER_PROPERTY_VALUE
.

MessageId = 15025 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_CHANNEL_CANNOT_ACTIVATE
.

MessageId = 15026 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_FILTER_TOO_COMPLEX
.

MessageId = 15027 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_MESSAGE_NOT_FOUND
.

MessageId = 15028 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_MESSAGE_ID_NOT_FOUND
.

MessageId = 15029 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_UNRESOLVED_VALUE_INSERT
.

MessageId = 15030 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_UNRESOLVED_PARAMETER_INSERT
.

MessageId = 15031 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_MAX_INSERTS_REACHED
.

MessageId = 15032 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_EVENT_DEFINITION_NOT_FOUND
.

MessageId = 15033 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_MESSAGE_LOCALE_NOT_FOUND
.

MessageId = 15034 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_VERSION_TOO_OLD
.

MessageId = 15035 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_VERSION_TOO_NEW
.

MessageId = 15036 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_CANNOT_OPEN_CHANNEL_OF_QUERY
.

MessageId = 15037 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_PUBLISHER_DISABLED
.

MessageId = 15038 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_EVT_FILTER_OUT_OF_RANGE
.

MessageId = 15100 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MUI_FILE_NOT_FOUND
.

MessageId = 15101 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MUI_INVALID_FILE
.

MessageId = 15102 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MUI_INVALID_RC_CONFIG
.

MessageId = 15103 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MUI_INVALID_LOCALE_NAME
.

MessageId = 15104 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MUI_INVALID_ULTIMATEFALLBACK_NAME
.

MessageId = 15105 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MUI_FILE_NOT_LOADED
.

MessageId = 15106 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RESOURCE_ENUM_USER_STOP
.

MessageId = 15107 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MUI_INTLSETTINGS_UILANG_NOT_INSTALLED
.

MessageId = 15108 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MUI_INTLSETTINGS_INVALID_LOCALE_NAME
.

MessageId = 15110 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_RUNTIME_NO_DEFAULT_OR_NEUTRAL_RESOURCE
.

MessageId = 15111 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_INVALID_PRICONFIG
.

MessageId = 15112 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_INVALID_FILE_TYPE
.

MessageId = 15113 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_UNKNOWN_QUALIFIER
.

MessageId = 15114 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_INVALID_QUALIFIER_VALUE
.

MessageId = 15115 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_NO_CANDIDATE
.

MessageId = 15116 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_NO_MATCH_OR_DEFAULT_CANDIDATE
.

MessageId = 15117 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_RESOURCE_TYPE_MISMATCH
.

MessageId = 15118 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_DUPLICATE_MAP_NAME
.

MessageId = 15119 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_DUPLICATE_ENTRY
.

MessageId = 15120 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_INVALID_RESOURCE_IDENTIFIER
.

MessageId = 15121 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_FILEPATH_TOO_LONG
.

MessageId = 15122 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_UNSUPPORTED_DIRECTORY_TYPE
.

MessageId = 15126 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_INVALID_PRI_FILE
.

MessageId = 15127 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_NAMED_RESOURCE_NOT_FOUND
.

MessageId = 15135 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_MAP_NOT_FOUND
.

MessageId = 15136 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_UNSUPPORTED_PROFILE_TYPE
.

MessageId = 15137 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_INVALID_QUALIFIER_OPERATOR
.

MessageId = 15138 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_INDETERMINATE_QUALIFIER_VALUE
.

MessageId = 15139 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_AUTOMERGE_ENABLED
.

MessageId = 15140 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_TOO_MANY_RESOURCES
.

MessageId = 15141 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_UNSUPPORTED_FILE_TYPE_FOR_MERGE
.

MessageId = 15142 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_UNSUPPORTED_FILE_TYPE_FOR_LOAD_UNLOAD_PRI_FILE
.

MessageId = 15143 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_NO_CURRENT_VIEW_ON_THREAD
.

MessageId = 15144 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DIFFERENT_PROFILE_RESOURCE_MANAGER_EXIST
.

MessageId = 15145 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_OPERATION_NOT_ALLOWED_FROM_SYSTEM_COMPONENT
.

MessageId = 15146 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_DIRECT_REF_TO_NON_DEFAULT_RESOURCE
.

MessageId = 15147 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_GENERATION_COUNT_MISMATCH
.

MessageId = 15148 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PRI_MERGE_VERSION_MISMATCH
.

MessageId = 15149 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PRI_MERGE_MISSING_SCHEMA
.

MessageId = 15150 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PRI_MERGE_LOAD_FILE_FAILED
.

MessageId = 15151 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PRI_MERGE_ADD_FILE_FAILED
.

MessageId = 15152 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PRI_MERGE_WRITE_FILE_FAILED
.

MessageId = 15153 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PRI_MERGE_MULTIPLE_PACKAGE_FAMILIES_NOT_ALLOWED
.

MessageId = 15154 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PRI_MERGE_MULTIPLE_MAIN_PACKAGES_NOT_ALLOWED
.

MessageId = 15155 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PRI_MERGE_BUNDLE_PACKAGES_NOT_ALLOWED
.

MessageId = 15156 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PRI_MERGE_MAIN_PACKAGE_REQUIRED
.

MessageId = 15157 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PRI_MERGE_RESOURCE_PACKAGE_REQUIRED
.

MessageId = 15158 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PRI_MERGE_INVALID_FILE_NAME
.

MessageId = 15159 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_PACKAGE_NOT_FOUND
.

MessageId = 15160 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_MISSING_DEFAULT_LANGUAGE
.

MessageId = 15161 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MRM_SCOPE_ITEM_CONFLICT
.

MessageId = 15501 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_COM_TASK_STOP_PENDING
.

MessageId = 15600 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_OPEN_PACKAGE_FAILED
.

MessageId = 15601 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_PACKAGE_NOT_FOUND
.

MessageId = 15602 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_INVALID_PACKAGE
.

MessageId = 15603 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_RESOLVE_DEPENDENCY_FAILED
.

MessageId = 15604 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_OUT_OF_DISK_SPACE
.

MessageId = 15605 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_NETWORK_FAILURE
.

MessageId = 15606 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_REGISTRATION_FAILURE
.

MessageId = 15607 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_DEREGISTRATION_FAILURE
.

MessageId = 15608 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_CANCEL
.

MessageId = 15609 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_FAILED
.

MessageId = 15610 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REMOVE_FAILED
.

MessageId = 15611 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PACKAGE_ALREADY_EXISTS
.

MessageId = 15612 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NEEDS_REMEDIATION
.

MessageId = 15613 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_PREREQUISITE_FAILED
.

MessageId = 15614 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PACKAGE_REPOSITORY_CORRUPTED
.

MessageId = 15615 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_POLICY_FAILURE
.

MessageId = 15616 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PACKAGE_UPDATING
.

MessageId = 15617 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEPLOYMENT_BLOCKED_BY_POLICY
.

MessageId = 15618 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PACKAGES_IN_USE
.

MessageId = 15619 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RECOVERY_FILE_CORRUPT
.

MessageId = 15620 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INVALID_STAGED_SIGNATURE
.

MessageId = 15621 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DELETING_EXISTING_APPLICATIONDATA_STORE_FAILED
.

MessageId = 15622 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_PACKAGE_DOWNGRADE
.

MessageId = 15623 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SYSTEM_NEEDS_REMEDIATION
.

MessageId = 15624 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPX_INTEGRITY_FAILURE_CLR_NGEN
.

MessageId = 15625 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_RESILIENCY_FILE_CORRUPT
.

MessageId = 15626 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_FIREWALL_SERVICE_NOT_RUNNING
.

MessageId = 15627 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PACKAGE_MOVE_FAILED
.

MessageId = 15628 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_VOLUME_NOT_EMPTY
.

MessageId = 15629 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_VOLUME_OFFLINE
.

MessageId = 15630 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_VOLUME_CORRUPT
.

MessageId = 15631 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_NEEDS_REGISTRATION
.

MessageId = 15632 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_WRONG_PROCESSOR_ARCHITECTURE
.

MessageId = 15633 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEV_SIDELOAD_LIMIT_EXCEEDED
.

MessageId = 15634 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_OPTIONAL_PACKAGE_REQUIRES_MAIN_PACKAGE
.

MessageId = 15635 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PACKAGE_NOT_SUPPORTED_ON_FILESYSTEM
.

MessageId = 15636 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PACKAGE_MOVE_BLOCKED_BY_STREAMING
.

MessageId = 15637 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_OPTIONAL_PACKAGE_APPLICATIONID_NOT_UNIQUE
.

MessageId = 15638 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PACKAGE_STAGING_ONHOLD
.

MessageId = 15639 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_INVALID_RELATED_SET_UPDATE
.

MessageId = 15640 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_OPTIONAL_PACKAGE_REQUIRES_MAIN_PACKAGE_FULLTRUST_CAPABILITY
.

MessageId = 15641 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEPLOYMENT_BLOCKED_BY_USER_LOG_OFF
.

MessageId = 15642 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PROVISION_OPTIONAL_PACKAGE_REQUIRES_MAIN_PACKAGE_PROVISIONED
.

MessageId = 15643 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PACKAGES_REPUTATION_CHECK_FAILED
.

MessageId = 15644 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PACKAGES_REPUTATION_CHECK_TIMEDOUT
.

MessageId = 15645 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEPLOYMENT_OPTION_NOT_SUPPORTED
.

MessageId = 15646 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPINSTALLER_ACTIVATION_BLOCKED
.

MessageId = 15647 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REGISTRATION_FROM_REMOTE_DRIVE_NOT_SUPPORTED
.

MessageId = 15648 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPX_RAW_DATA_WRITE_FAILED
.

MessageId = 15649 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEPLOYMENT_BLOCKED_BY_VOLUME_POLICY_PACKAGE
.

MessageId = 15650 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEPLOYMENT_BLOCKED_BY_VOLUME_POLICY_MACHINE
.

MessageId = 15651 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEPLOYMENT_BLOCKED_BY_PROFILE_POLICY
.

MessageId = 15652 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DEPLOYMENT_FAILED_CONFLICTING_MUTABLE_PACKAGE_DIRECTORY
.

MessageId = 15653 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SINGLETON_RESOURCE_INSTALLED_IN_ACTIVE_USER
.

MessageId = 15654 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_DIFFERENT_VERSION_OF_PACKAGED_SERVICE_INSTALLED
.

MessageId = 15655 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SERVICE_EXISTS_AS_NON_PACKAGED_SERVICE
.

MessageId = 15656 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PACKAGED_SERVICE_REQUIRES_ADMIN_PRIVILEGES
.

MessageId = 15657 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_REDIRECTION_TO_DEFAULT_ACCOUNT_NOT_ALLOWED
.

MessageId = 15658 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PACKAGE_LACKS_CAPABILITY_TO_DEPLOY_ON_HOST
.

MessageId = 15659 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNSIGNED_PACKAGE_INVALID_CONTENT
.

MessageId = 15660 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_UNSIGNED_PACKAGE_INVALID_PUBLISHER_NAMESPACE
.

MessageId = 15661 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_SIGNED_PACKAGE_INVALID_PUBLISHER_NAMESPACE
.

MessageId = 15662 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PACKAGE_EXTERNAL_LOCATION_NOT_ALLOWED
.

MessageId = 15663 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_FULLTRUST_HOSTRUNTIME_REQUIRES_MAIN_PACKAGE_FULLTRUST_CAPABILITY
.

MessageId = 15664 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PACKAGE_LACKS_CAPABILITY_FOR_MANDATORY_STARTUPTASKS
.

MessageId = 15665 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_INSTALL_RESOLVE_HOSTRUNTIME_DEPENDENCY_FAILED
.

MessageId = 15666 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_MACHINE_SCOPE_NOT_ALLOWED
.

MessageId = 15667 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_CLASSIC_COMPAT_MODE_NOT_ALLOWED
.

MessageId = 15668 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STAGEFROMUPDATEAGENT_PACKAGE_NOT_APPLICABLE
.

MessageId = 15669 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PACKAGE_NOT_REGISTERED_FOR_USER
.

MessageId = 15670 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_PACKAGE_NAME_MISMATCH
.

MessageId = 15671 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPINSTALLER_URI_IN_USE
.

MessageId = 15672 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_APPINSTALLER_IS_MANAGED_BY_SYSTEM
.

MessageId = 15700 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
APPMODEL_ERROR_NO_PACKAGE
.

MessageId = 15701 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
APPMODEL_ERROR_PACKAGE_RUNTIME_CORRUPT
.

MessageId = 15702 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
APPMODEL_ERROR_PACKAGE_IDENTITY_CORRUPT
.

MessageId = 15703 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
APPMODEL_ERROR_NO_APPLICATION
.

MessageId = 15704 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
APPMODEL_ERROR_DYNAMIC_PROPERTY_READ_FAILED
.

MessageId = 15705 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
APPMODEL_ERROR_DYNAMIC_PROPERTY_INVALID
.

MessageId = 15706 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
APPMODEL_ERROR_PACKAGE_NOT_AVAILABLE
.

MessageId = 15707 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
APPMODEL_ERROR_NO_MUTABLE_DIRECTORY
.

MessageId = 15800 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_LOAD_STORE_FAILED
.

MessageId = 15801 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_GET_VERSION_FAILED
.

MessageId = 15802 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_SET_VERSION_FAILED
.

MessageId = 15803 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_STRUCTURED_RESET_FAILED
.

MessageId = 15804 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_OPEN_CONTAINER_FAILED
.

MessageId = 15805 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_CREATE_CONTAINER_FAILED
.

MessageId = 15806 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_DELETE_CONTAINER_FAILED
.

MessageId = 15807 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_READ_SETTING_FAILED
.

MessageId = 15808 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_WRITE_SETTING_FAILED
.

MessageId = 15809 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_DELETE_SETTING_FAILED
.

MessageId = 15810 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_QUERY_SETTING_FAILED
.

MessageId = 15811 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_READ_COMPOSITE_SETTING_FAILED
.

MessageId = 15812 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_WRITE_COMPOSITE_SETTING_FAILED
.

MessageId = 15813 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_ENUMERATE_CONTAINER_FAILED
.

MessageId = 15814 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_ENUMERATE_SETTINGS_FAILED
.

MessageId = 15815 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_COMPOSITE_SETTING_VALUE_SIZE_LIMIT_EXCEEDED
.

MessageId = 15816 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_SETTING_VALUE_SIZE_LIMIT_EXCEEDED
.

MessageId = 15817 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_SETTING_NAME_SIZE_LIMIT_EXCEEDED
.

MessageId = 15818 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_STATE_CONTAINER_NAME_SIZE_LIMIT_EXCEEDED
.

MessageId = 15841 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
ERROR_API_UNAVAILABLE
.

MessageId = 15861 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
STORE_ERROR_UNLICENSED
.

MessageId = 15862 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
STORE_ERROR_UNLICENSED_USER
.

MessageId = 15863 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
STORE_ERROR_PENDING_COM_TRANSACTION
.

MessageId = 15864 ; // Win32
Severity = Error
Facility = Win32
Language = Neutral
STORE_ERROR_LICENSE_REVOKED
.
