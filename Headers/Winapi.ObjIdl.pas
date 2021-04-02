unit Winapi.ObjIdl;

interface

uses
  Winapi.WinNt, Winapi.WinUser, DelphiApi.Reflection;

const
  CSIDL_DESKTOP = $0000;

  SWC_EXPLORER = $00;
  SWC_BROWSER = $01;
  SWC_3RDPARTY = $02;
  SWC_CALLBACK = $04;
  SWC_DESKTOP = $08;

  SWFO_NEEDDISPATCH = $01;
  SWFO_INCLUDEPENDING = $02;
  SWFO_COOKIEPASSED = $04;

  CLSID_ShellWindows: TGuid = '{9BA05972-F6A8-11CF-A442-00A0C90A8F39}';
  SID_STopLevelBrowser: TGuid = '{4C96BE40-915C-11CF-99D3-00AA004AE837}';

type
  TIid = TGuid;
  TClsid = TGuid;
  TVariantBool = type SmallInt;

  // 2262
  IEnumString = interface(IUnknown)
    ['{00000101-0000-0000-C000-000000000046}']
    function Next(
      Count: Integer;
      out Elements: TAnysizeArray<PWideChar>;
      Fetched: PInteger
    ): HResult; stdcall;

    function Skip(Count: Integer): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Clone(out Enm: IEnumString): HResult; stdcall;
  end;

  // 2392
  ISequentialStream = interface(IUnknown)
    ['{0c733a30-2a1c-11ce-ade5-00aa0044773d}']
    function Read(
      pv: Pointer;
      cb: FixedUInt;
      pcbRead: PFixedUInt
    ): HResult; stdcall;

    function Write(
      pv: Pointer;
      cb: FixedUInt;
      pcbWritten: PFixedUInt
    ): HResult; stdcall;
  end;

  // 2526
  TStatStg = record
    pwcsName: PWideChar;
    dwType: Cardinal;
    cbSize: Int64;
    mtime: TLargeInteger;
    ctime: TLargeInteger;
    atime: TLargeInteger;
    grfMode: Cardinal;
    grfLocksSupported: Cardinal;
    clsid: TClsid;
    grfStateBits: Cardinal;
    reserved: Cardinal;
  end;

  // 2572
  IStream = interface(ISequentialStream)
    ['{0000000C-0000-0000-C000-000000000046}']
    function Seek(
      dlibMove: Int64;
      dwOrigin: Cardinal;
      out libNewPosition: UInt64
    ): HResult; stdcall;

    function SetSize(libNewSize: UInt64): HResult; stdcall;

    function CopyTo(
      stm: IStream;
      cb: UInt64;
      out cbRead: UInt64;
      out cbWritten: UInt64
    ): HResult; stdcall;

    function Commit(grfCommitFlags: Cardinal): HResult; stdcall;
    function Revert: HResult; stdcall;

    function LockRegion(
      libOffset: UInt64;
      cb: UInt64;
      dwLockType: Cardinal
    ): HResult; stdcall;

    function UnlockRegion(
      libOffset: UInt64;
      cb: UInt64;
      dwLockType: Cardinal
    ): HResult; stdcall;

    function Stat(
      out statstg: TStatStg;
      grfStatFlag: Cardinal
    ): HResult; stdcall;

    function Clone(out stm: IStream): HResult; stdcall;
  end;

  // 8435
  TBindOpts = record
    cbStruct: Cardinal;
    grfFlags: Cardinal;
    grfMode: Cardinal;
    dwTickCountDeadline: Cardinal;
  end;

  IRunningObjectTable = interface;

  // 8503
  IBindCtx = interface(IUnknown)
    ['{0000000E-0000-0000-C000-000000000046}']
    function RegisterObjectBound(const unk: IUnknown): HResult; stdcall;
    function RevokeObjectBound(const unk: IUnknown): HResult; stdcall;
    function ReleaseBoundObjects: HResult; stdcall;
    function SetBindOptions(const bindopts: TBindOpts): HResult; stdcall;
    function GetBindOptions(var bindopts: TBindOpts): HResult; stdcall;

    function GetRunningObjectTable(
      out rot: IRunningObjectTable
    ): HResult; stdcall;

    function RegisterObjectParam(
      pszKey: PWideChar;
      const unk: IUnknown
    ): HResult; stdcall;

    function GetObjectParam(
      pszKey: PWideChar;
      out unk: IUnknown
    ): HResult; stdcall;

    function EnumObjectParam(out Enum: IEnumString): HResult; stdcall;
    function RevokeObjectParam(pszKey: PWideChar): HResult; stdcall;
  end;

  IMoniker = interface;
  PIMoniker = ^IMoniker;

  // 8706
  IEnumMoniker = interface(IUnknown)
    ['{00000102-0000-0000-C000-000000000046}']
    function Next(
      celt: Cardinal;
      out elt: PIMoniker;
      pceltFetched: PCardinal
    ): HResult; stdcall;

    function Skip(celt: Cardinal): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Clone(out enm: IEnumMoniker): HResult; stdcall;
  end;

  // 8983
  IRunningObjectTable = interface(IUnknown)
    ['{00000010-0000-0000-C000-000000000046}']
    function &Register(
      grfFlags: Cardinal;
      const unkObject: IUnknown;
      const mkObjectName: IMoniker;
      out dwRegister: Cardinal
    ): HResult; stdcall;

    function Revoke(dwRegister: Cardinal): HResult; stdcall;
    function IsRunning(const mkObjectName: IMoniker): HResult; stdcall;

    function GetObject(
      const mkObjectName: IMoniker;
      out unkObject: IUnknown
    ): HResult; stdcall;

    function NoteChangeTime(
      dwRegister: Cardinal;
      const filetime: TLargeInteger
    ): HResult; stdcall;

    function GetTimeOfLastChange(
      const mkObjectName: IMoniker;
      out filetime: TLargeInteger
    ): HResult; stdcall;

    function EnumRunning(out enumMoniker: IEnumMoniker): HResult; stdcall;
  end;

  // 9149
  IPersist = interface(IUnknown)
    ['{0000010C-0000-0000-C000-000000000046}']
    function GetClassID(out classID: TClsid): HResult; stdcall;
  end;

  // 9231
  IPersistStream = interface(IPersist)
    ['{00000109-0000-0000-C000-000000000046}']
    function IsDirty: HResult; stdcall;
    function Load(const stm: IStream): HResult; stdcall;
    function Save(const stm: IStream; fClearDirty: LongBool): HResult; stdcall;
    function GetSizeMax(out cbSize: UInt64): HResult; stdcall;
  end;

  // 9375
  IMoniker = interface(IPersistStream)
    ['{0000000F-0000-0000-C000-000000000046}']
    function BindToObject(
      const bc: IBindCtx;
      const mkToLeft: IMoniker;
      const iidResult: TIid;
      out vResult
    ): HResult; stdcall;

    function BindToStorage(
      const bc: IBindCtx;
      const mkToLeft: IMoniker;
      const iid: TIid;
      out vObj
    ): HResult; stdcall;

    function Reduce(
      const bc: IBindCtx;
      dwReduceHowFar: Cardinal;
      mkToLeft: PIMoniker;
      out mkReduced: IMoniker
    ): HResult; stdcall;

    function ComposeWith(
      const mkRight: IMoniker;
      fOnlyIfNotGeneric: LongBool;
      out mkComposite: IMoniker
    ): HResult; stdcall;

    function Enum(
      fForward: LongBool;
      out enumMoniker: IEnumMoniker
    ): HResult; stdcall;

    function IsEqual(const mkOtherMoniker: IMoniker): HResult; stdcall;
    function Hash(out dwHash: Cardinal): HResult; stdcall;

    function IsRunning(
      const bc: IBindCtx;
      const mkToLeft: IMoniker;
      const mkNewlyRunning: IMoniker
    ): HResult; stdcall;

    function GetTimeOfLastChange(
      const bc: IBindCtx;
      const mkToLeft: IMoniker;
      out filetime: TLargeInteger
    ): HResult; stdcall;

    function Inverse(out mk: IMoniker): HResult; stdcall;

    function CommonPrefixWith(
      const mkOther: IMoniker;
      out mkPrefix: IMoniker
    ): HResult; stdcall;

    function RelativePathTo(
      const mkOther: IMoniker;
      out mkRelPath: IMoniker
    ): HResult; stdcall;

    function GetDisplayName(
      const bc: IBindCtx;
      const mkToLeft: IMoniker;
      out pszDisplayName: PWideChar
    ): HResult; stdcall;

    function ParseDisplayName(
      const bc: IBindCtx;
      const mkToLeft: IMoniker;
      pszDisplayName: PWideChar;
      out chEaten: Cardinal;
      out mkOut: IMoniker
    ): HResult; stdcall;

    function IsSystemMoniker(out dwMksys: Cardinal): HResult; stdcall;
  end;

  IShellWindows = interface (IDispatch)
    ['{85CB6900-4D95-11CF-960C-0080C7F4EE85}']
    function get_Count(out Count: Integer): HResult; stdcall;
    function Item(index: TVarData; out Folder: IDispatch): HResult; stdcall;
    function _NewEnum(out ppunk: IUnknown): HResult; stdcall;
    function &Register(pid: IDispatch; hwnd: Integer; swClass: Integer;
      out plCookie: Integer): HResult; stdcall;

    function RegisterPending(lThreadId: TThreadId32; const pvarloc: TVarData;
      const varlocRoot: TVarData; swClass: Integer; out plCookie: Integer):
      HResult; stdcall;

    function Revoke(lCookie: Integer): HResult; stdcall;

    function OnNavigate(
      lCookie: Integer;
      const pvarLoc: TVarData
    ): HResult; stdcall;

    function OnActivated(
      lCookie: Integer;
      fActive: TVariantBool
    ): HResult; stdcall;

    function FindWindowSW(
      const varLoc: TVarData;
      const varLocRoot: TVarData;
      swClass: Integer;
      out hwnd: Integer;
      swfwOptions: Integer;
      out dispOut: IDispatch
    ): HResult; stdcall;

    function OnCreated(Cookie: Integer; punk: IUnknown): HResult; stdcall;

    function ProcessAttachDetach(fAttach: TVariantBool): HResult; stdcall;
  end;

  IServiceProvider = interface (IUnknown)
    ['{6d5140c1-7436-11ce-8034-00aa006009fa}']
    function QueryService(
      const guidService: TGuid;
      const riid: TIid;
      out vObject
    ): HResult; stdcall;
  end;

  IOleWindow = interface (IUnknown)
    function GetWindow(out hwnd: HWND): HResult; stdcall;
    function ContextSensitiveHelp(fEnterMode: LongBool): HResult; stdcall;
  end;

  IShellBrowser = interface;

  [NamingStyle(nsSnakeCase, 'SVGIO')]
  TSvgio = (
    SVGIO_BACKGROUND = 0,
    SVGIO_SELECTION = 1,
    SVGIO_ALLVIEW = 2,
    SVGIO_CHECKED = 3
  );

  IShellView = interface (IOleWindow)
    ['{88E39E80-3578-11CF-AE69-08002B2E1262}']
    function TranslateAccelerator(pmsg: Pointer): HResult; stdcall;
    function EnableModeless(fEnable: LongBool): HResult; stdcall;
    function UIActivate(uState: Cardinal): HResult; stdcall;
    function Refresh: HResult; stdcall;

    function CreateViewWindow(
      svPrevious: IShellView;
      pfs: Pointer;
      psb: IShellBrowser;
      const prcView: TRect;
      out hWnd: HWND
    ): HResult; stdcall;

    function DestroyViewWindow: HResult; stdcall;
    function GetCurrentInfo(pfs: Pointer): HResult; stdcall;

    function AddPropertySheetPages(
      dwReserved: Cardinal;
      pfn: Pointer;
      lparam: LPARAM
    ): HResult; stdcall;

    function SaveViewState: HResult; stdcall;
    function SelectItem(
      idlItem: Pointer;
      uFlags: Cardinal
    ): HResult; stdcall;

    function GetItemObject(
      uItem: TSvgio;
      const riid: TIid;
      out pv
    ): HResult; stdcall;
  end;

  IShellBrowser = interface (IOleWindow)
    ['{000214E2-0000-0000-C000-000000000046}']
    function InsertMenusSB(
      hmenuShared: NativeUInt;
      lpMenuWidths: Pointer
    ): HResult; stdcall;

    function SetMenuSB(
      hmenuShared: NativeUInt;
      holemenuRes: NativeUInt;
      hwndActiveObject: NativeUInt
    ): HResult; stdcall;

    function RemoveMenusSB(hmenuShared: NativeUInt): HResult; stdcall;
    function SetStatusTextSB(pszStatusText: PWideChar): HResult; stdcall;
    function EnableModelessSB(fEnable: LongBool): HResult; stdcall;
    function TranslateAcceleratorSB(pmsg: Pointer; wID: Word): HResult; stdcall;
    function BrowseObject(pidl: Pointer; wFlags: Cardinal): HResult; stdcall;

    function GetViewStateStream(
      grfMode: Cardinal;
      out Strm: IStream
    ): HResult; stdcall;

    function GetControlWindow(id: Cardinal; out hwnd: HWND): HResult; stdcall;

    function SendControlMsg(
      id: Cardinal;
      uMsg: Cardinal;
      wParam: WPARAM;
      lParam: LPARAM;
      out pret: NativeInt
    ): HResult; stdcall;

    function QueryActiveShellView(out shv: IShellView): HResult; stdcall;
    function OnViewWindowActive(shv: IShellView): HResult; stdcall;

    function SetToolbarItems(
      lpButtons: Pointer;
      nButtons: Cardinal;
      uFlags: Cardinal
    ): HResult; stdcall;
  end;

  FolderItem = IUnknown;
  FolderItems = IUnknown;

  IShellFolderViewDual = interface (IDispatch)
    ['{E7A1AF80-4D96-11CF-960C-0080C7F4EE85}']
    function get_Application(out ppid: IDispatch): HResult; stdcall;
    function get_Parent(out ppid: IDispatch): HResult; stdcall;
    function get_Folder(out ppid: IDispatch): HResult; stdcall;
    function SelectedItems(out ppid: FolderItems): HResult; stdcall;
    function get_FocusedItem(out ppid: FolderItem): HResult; stdcall;

    function SelectItem(
      const vfi: TVarData;
      dwFlags: Cardinal
    ): HResult; stdcall;

    function PopupItemMenu(
      pfi: FolderItem;
      vx: TVarData;
      vy: TVarData;
      pbs: Pointer
    ): HResult; stdcall;

    function get_Script(out ppDisp: IDispatch): HResult; stdcall;
    function get_ViewOptions(out plViewOptions: Cardinal): HResult; stdcall;
  end;

  Folder = IUnknown;

  IShellDispatch = interface (IDispatch)
    ['{D8F015C0-C278-11CE-A49E-444553540000}']
    function get_Application(out ppid: IDispatch): HResult; stdcall;
    function get_Parent(out ppid: IDispatch): HResult; stdcall;
    function NameSpace(vDir: TVarData; out ppsdf: Folder): HResult; stdcall;

    function BrowseForFolder(
      Hwnd: Integer;
      Title: WideString;
      Options: Cardinal;
      RootFolder: TVarData;
      out ppsdf: Folder
    ): HResult; stdcall;

    function Windows(out ppid: IDispatch): HResult; stdcall;
    function Open(vDir: TVarData): HResult; stdcall;
    function Explore(vDir: TVarData): HResult; stdcall;
    function MinimizeAll: HResult; stdcall;
    function UndoMinimizeALL: HResult; stdcall;
    function FileRun: HResult; stdcall;
    function CascadeWindows: HResult; stdcall;
    function TileVertically: HResult; stdcall;
    function TileHorizontally: HResult; stdcall;
    function ShutdownWindows: HResult; stdcall;
    function Suspend: HResult; stdcall;
    function EjectPC: HResult; stdcall;
    function SetTime: HResult; stdcall;
    function TrayProperties: HResult; stdcall;
    function Help: HResult; stdcall;
    function FindFiles: HResult; stdcall;
    function FindComputer: HResult; stdcall;
    function RefreshMenu: HResult; stdcall;
    function ControlPanelItem(bstrDir: WideString): HResult; stdcall;
  end;

  IShellDispatch2 = interface (IShellDispatch)
    ['{A4C6892C-3BA9-11d2-9DEA-00C04FB16162}']
    function IsRestricted(
      Group: WideString;
      Restriction: WideString;
      out RestrictValue: Cardinal
    ): HResult; stdcall;

    function ShellExecute(
      FileName: WideString;
      vArgs: TVarData;
      vDir: TVarData;
      vOperation: TVarData;
      vShow: TVarData
    ): HResult; stdcall;

    function FindPrinter(
      name: WideString;
      location: WideString;
      model: WideString
    ): HResult; stdcall;

    function GetSystemInformation(
      name: WideString;
      out pv: TVarData
    ): HResult; stdcall;

    function ServiceStart(
      ServiceName: WideString;
      Persistent: TVarData;
      out Success: TVarData
    ): HResult; stdcall;

    function ServiceStop(
      ServiceName: WideString;
      Persistent: TVarData;
      out Success: TVarData
    ): HResult; stdcall;

    function IsServiceRunning(
      ServiceName: WideString;
      out Running: TVarData
    ): HResult; stdcall;

    function CanStartStopService(
      ServiceName: WideString;
      out CanStartStop: TVarData
    ): HResult; stdcall;

    function ShowBrowserBar(
      bstrClsid: WideString;
      bShow: TVarData;
      out Success: TVarData
    ): HResult; stdcall;
  end;


implementation

end.
