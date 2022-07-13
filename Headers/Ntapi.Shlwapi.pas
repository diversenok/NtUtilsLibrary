unit Ntapi.Shlwapi;

{
  This module includes definitions for some Lightweight Shell API functions.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinUser, DelphiApi.Reflection;

const
  shlwapi = 'shlwapi.dll';

  // SDK::ShlDisp.h - flags for IAutoComplete2
  ACO_AUTOSUGGEST = $0001;
  ACO_AUTOAPPEND = $0002;
  ACO_SEARCH = $0004;
  ACO_FILTERPREFIXES = $0008;
  ACO_USETAB = $0010;
  ACO_UPDOWNKEYDROPSLIST = $0020;
  ACO_RTLREADING = $0040;
  ACO_WORD_FILTER = $0080;
  ACO_NOPREFIXFILTERING = $0100;

  // SDK::ShlGuid.h
  CLSID_AutoComplete: TGUID = '{00BB2763-6A77-11D0-A535-00C04FD7D062}';

  // SDK::Shlwapi.h - shell auto-complete flags
  SHACF_FILESYSTEM = $00000001;
  SHACF_URLHISTORY = $00000002;
  SHACF_URLMRU = $00000004;
  SHACF_USETAB = $00000008;
  SHACF_FILESYS_ONLY = $00000010;
  SHACF_FILESYS_DIRS = $00000020;
  SHACF_VIRTUAL_NAMESPACE = $00000040;
  SHACF_AUTOSUGGEST_FORCE_ON = $10000000;
  SHACF_AUTOSUGGEST_FORCE_OFF = $20000000;
  SHACF_AUTOAPPEND_FORCE_ON = $40000000;
  SHACF_AUTOAPPEND_FORCE_OFF = $80000000;

type
  [FlagName(ACO_AUTOSUGGEST, 'Auto-suggest')]
  [FlagName(ACO_AUTOAPPEND, 'Auto-append')]
  [FlagName(ACO_SEARCH, 'Search')]
  [FlagName(ACO_FILTERPREFIXES, 'Filter Prefixes')]
  [FlagName(ACO_USETAB, 'Use Tab')]
  [FlagName(ACO_UPDOWNKEYDROPSLIST, 'Up/Down Key Drops List')]
  [FlagName(ACO_RTLREADING, 'Right-To-Left')]
  [FlagName(ACO_WORD_FILTER, 'Word Filter')]
  [FlagName(ACO_NOPREFIXFILTERING, 'No Prefix Filtering')]
  TAutoCompleteFlags = type Cardinal;

  [FlagName(SHACF_FILESYSTEM, 'Filesystem')]
  [FlagName(SHACF_URLHISTORY, 'URL History')]
  [FlagName(SHACF_URLMRU, 'URLS in Recently Used')]
  [FlagName(SHACF_USETAB, 'Use Tab')]
  [FlagName(SHACF_FILESYS_ONLY, 'Filesystem Only')]
  [FlagName(SHACF_FILESYS_DIRS, 'Filesystem Direcotries')]
  [FlagName(SHACF_VIRTUAL_NAMESPACE, 'Virtual Namespace')]
  [FlagName(SHACF_AUTOSUGGEST_FORCE_ON, 'Auto-suggest Force On')]
  [FlagName(SHACF_AUTOSUGGEST_FORCE_OFF, 'Auto-suggest Force Off')]
  [FlagName(SHACF_AUTOAPPEND_FORCE_ON, 'Auto-append Force On')]
  [FlagName(SHACF_AUTOAPPEND_FORCE_OFF, 'Auto-append Force Off')]
  TShAutoCompleteFlags = type Cardinal;

  // SDK::ShlDisp.h
  [SDKName('IAutoComplete')]
  IAutoComplete = interface(IUnknown)
    ['{00BB2762-6A77-11D0-A535-00C04FD7D062}']

    function Init(
      [in] hwndEdit: THwnd;
      [in] const punkACL: IUnknown;
      [in, opt] pwszRegKeyPath: PWideChar;
      [in, opt] pwszQuickComplete: PWideChar
    ): HResult; stdcall;

    function Enable(
      [in] fEnable: LongBool
    ): HResult; stdcall;
  end;

  // SDK::ShlDisp.h
  [SDKName('IAutoComplete2')]
  IAutoComplete2 = interface(IAutoComplete)
    ['{EAC04BC0-3791-11D2-BB95-0060977B464C}']

    function SetOptions(
      [in] Flags: TAutoCompleteFlags
    ): HResult; stdcall;

    function GetOptions(
      [out] out Flag: TAutoCompleteFlags
    ): HResult; stdcall;
  end;

  // SDK::ShlObj_core.h
  [SDKName('IACList')]
  IACList = interface(IUnknown)
    ['{77A130B0-94FD-11D0-A544-00C04FD7D062}']

    function Expand(
      [in] Root: PWideChar
    ): HResult; stdcall;
  end;

// SDK::Shlwapi.h
function SHAutoComplete(
  [in] hwndEdit: THwnd;
  [in] Flags: TShAutoCompleteFlags
): HResult; stdcall; external shlwapi;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
