unit Winapi.Shlwapi;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinUser;

const
  shlwapi = 'shlwapi.dll';

  // 2394
  SHACF_URLMRU = $00000004;
  SHACF_FILESYS_ONLY = $00000010;
  SHACF_FILESYS_DIRS = $00000020;

  // ShlDisp.7542, flags for IAutoComplete2
  ACO_AUTOSUGGEST	= $0001;
  ACO_AUTOAPPEND = $0002;
  ACO_SEARCH = $0004;
  ACO_FILTERPREFIXES = $0008;
  ACO_USETAB = $0010;
  ACO_UPDOWNKEYDROPSLIST = $0020;
  ACO_RTLREADING = $0040;
  ACO_WORD_FILTER	= $0080;
  ACO_NOPREFIXFILTERING	= $0100;

  // ShlGuid.247
  CLSID_AutoComplete: TGUID = '{00BB2763-6A77-11D0-A535-00C04FD7D062}';

type
  // ShlDisp.7430
  IAutoComplete = interface(IUnknown)
    ['{00BB2762-6A77-11D0-A535-00C04FD7D062}']
    function Init(hwndEdit: HWND; punkACL: IUnknown; pwszRegKeyPath: PWideChar;
      pwszQuickComplete: PWideChar): HResult; stdcall;
    function Enable(fEnable: LongBool): HResult; stdcall;
  end;

  // ShlDisp.7546
  IAutoComplete2 = interface(IAutoComplete)
    ['{EAC04BC0-3791-11D2-BB95-0060977B464C}']
    function SetOptions(dwFlag: Cardinal): HResult; stdcall;
    function GetOptions(var pdwFlag: Cardinal): HResult; stdcall;
  end;

  // ShlObj_core.1329
  IACList = interface(IUnknown)
    ['{77A130B0-94FD-11D0-A544-00C04FD7D062}']
    function Expand(Root: PWideChar): HResult; stdcall;
  end;

// 2412
function SHAutoComplete(hwndEdit: HWND; dwFlags: Cardinal): HRESULT; stdcall;
  external shlwapi;

implementation

end.
