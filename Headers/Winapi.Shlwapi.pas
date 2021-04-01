unit Winapi.Shlwapi;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinUser, DelphiApi.Reflection;

const
  shlwapi = 'shlwapi.dll';

  // ShlDisp.7542, flags for IAutoComplete2
  ACO_AUTOSUGGEST = $0001;
  ACO_AUTOAPPEND = $0002;
  ACO_SEARCH = $0004;
  ACO_FILTERPREFIXES = $0008;
  ACO_USETAB = $0010;
  ACO_UPDOWNKEYDROPSLIST = $0020;
  ACO_RTLREADING = $0040;
  ACO_WORD_FILTER = $0080;
  ACO_NOPREFIXFILTERING = $0100;

  // ShlGuid.247
  CLSID_AutoComplete: TGUID = '{00BB2763-6A77-11D0-A535-00C04FD7D062}';

  // 2394
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

  // ShlDisp.7430
  IAutoComplete = interface(IUnknown)
    ['{00BB2762-6A77-11D0-A535-00C04FD7D062}']

    function Init(
      hwndEdit: HWND;
      punkACL: IUnknown;
      pwszRegKeyPath: PWideChar;
      pwszQuickComplete: PWideChar
    ): HResult; stdcall;

    function Enable(fEnable: LongBool): HResult; stdcall;
  end;

  // ShlDisp.7546
  IAutoComplete2 = interface(IAutoComplete)
    ['{EAC04BC0-3791-11D2-BB95-0060977B464C}']
    function SetOptions(Flag: TAutoCompleteFlags): HResult; stdcall;
    function GetOptions(var Flag: TAutoCompleteFlags): HResult; stdcall;
  end;

  // ShlObj_core.1329
  IACList = interface(IUnknown)
    ['{77A130B0-94FD-11D0-A544-00C04FD7D062}']
    function Expand(Root: PWideChar): HResult; stdcall;
  end;

// 2412
function SHAutoComplete(
  hwndEdit: HWND;
  Flags: TShAutoCompleteFlags
): HResult; stdcall; external shlwapi;

implementation

end.
