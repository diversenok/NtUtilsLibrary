unit Ntapi.ObjIdl;

{
  This file defines COM interfaces.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.WinUser, DelphiApi.Reflection;

const
  // SDK::wtypes.h - stream commit flags
  STGC_OVERWRITE = $01;
  STGC_ONLYIFCURRENT = $02;
  STGC_DANGEROUSLYCOMMITMERELYTODISKCACHE	= $04;
  STGC_CONSOLIDATE = $08;

  // SDK::wtypes.h - stream lock flags
  STATFLAG_NONAME	= $01;
  STATFLAG_NOOPEN	= $02;

  // SDK::ShlObj_core.h
  CSIDL_DESKTOP = $0000;

  // SDK::ExDisp.h
  SWC_EXPLORER = $00;
  SWC_BROWSER = $01;
  SWC_3RDPARTY = $02;
  SWC_CALLBACK = $04;
  SWC_DESKTOP = $08;

  // SDK::ExDisp.h
  SWFO_NEEDDISPATCH = $01;
  SWFO_INCLUDEPENDING = $02;
  SWFO_COOKIEPASSED = $04;

  // SDK::ExDisp.h
  CLSID_ShellWindows: TGuid = '{9BA05972-F6A8-11CF-A442-00A0C90A8F39}';

  // SDK::ShlGuid.h
  SID_STopLevelBrowser: TGuid = '{4C96BE40-915C-11CF-99D3-00AA004AE837}';

type
  TIid = TGuid;
  TClsid = TGuid;
  TVariantBool = type SmallInt;

  // SDK::objidl.h
  [SDKName('IEnumString')]
  IEnumString = interface(IUnknown)
    ['{00000101-0000-0000-C000-000000000046}']
    function Next(
      [in, NumberOfElements] Count: Integer;
      [out, WritesTo, ReleaseWith('CoTaskMemFree')] out Elements:
        TAnysizeArray<PWideChar>;
      [out, NumberOfElements] out Fetched: Integer
    ): HResult; stdcall;

    function Skip(
      [in,  NumberOfElements] Count: Integer
    ): HResult; stdcall;

    function Reset(
    ): HResult; stdcall;

    function Clone(
      [out] out Enm: IEnumString
    ): HResult; stdcall;
  end;

  // SDK::objidl.h
  [SDKName('ISequentialStream')]
  ISequentialStream = interface(IUnknown)
    ['{0c733a30-2a1c-11ce-ade5-00aa0044773d}']
    function Read(
      [out, WritesTo] pv: Pointer;
      [in, NumberOfBytes] cb: FixedUInt;
      [out, NumberOfBytes] out cbRead: FixedUInt
    ): HResult; stdcall;

    function Write(
      [in, ReadsFrom] pv: Pointer;
      [in, NumberOfBytes] cb: FixedUInt;
      [out, NumberOfBytes] out cbWritten: FixedUInt
    ): HResult; stdcall;
  end;

  // SDK::objidl.h
  [SDKName('STREAM_SEEK')]
  [NamingStyle(nsSnakeCase, 'STREAM_SEEK')]
  TStreamSeek = (
    STREAM_SEEK_SET	= 0,
    STREAM_SEEK_CUR	= 1,
    STREAM_SEEK_END	= 2
  );

  // SDK::objidl.h
  [SDKName('LOCKTYPE')]
  [NamingStyle(nsSnakeCase, 'LOCK'), ValidMask($B)]
  TLockType = (
    LOCK_WRITE	= 1,
    LOCK_EXCLUSIVE	= 2,
    [Reserved] LOCK_RESERVED = 3,
    LOCK_ONLYONCE	= 4
  );

  // SDK::wtypes.h
  [SDKName('STGC')]
  [FlagName(STGC_OVERWRITE, 'Overwrite')]
  [FlagName(STGC_ONLYIFCURRENT, 'Only If Current')]
  [FlagName(STGC_DANGEROUSLYCOMMITMERELYTODISKCACHE, 'Dangerous Commit Merely To Disk Cache')]
  [FlagName(STGC_CONSOLIDATE, 'Consolidate')]
  TStGc = type Cardinal;

  // SDK::wtypes.h
  [SDKName('STATFLAG')]
  [FlagName(STATFLAG_NONAME, 'No Name')]
  [FlagName(STATFLAG_NOOPEN, 'No Open')]
  TStatFlags = type Cardinal;

  // SDK::objidl.h
  [SDKName('STATSTG')]
  TStatStg = record
    [ReleaseWith('CoTaskMemFree')] pwcsName: PWideChar;
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

  // SDK::objidl.h
  [SDKName('IStream')]
  IStream = interface(ISequentialStream)
    ['{0000000C-0000-0000-C000-000000000046}']
    function Seek(
      [in, NumberOfBytes] dlibMove: Int64;
      [in] Origin: TStreamSeek;
      [out] out libNewPosition: UInt64
    ): HResult; stdcall;

    function SetSize(
      [in, NumberOfBytes] libNewSize: UInt64
    ): HResult; stdcall;

    function CopyTo(
      [in] const stm: IStream;
      [in, NumberOfBytes] cb: UInt64;
      [out, NumberOfBytes] out cbRead: UInt64;
      [out, NumberOfBytes] out cbWritten: UInt64
    ): HResult; stdcall;

    function Commit(
      [in] CommitFlags: TStGc
    ): HResult; stdcall;

    function Revert(
    ): HResult; stdcall;

    function LockRegion(
      [in] libOffset: UInt64;
      [in, NumberOfBytes] cb: UInt64;
      [in] LockType: TLockType
    ): HResult; stdcall;

    function UnlockRegion(
      [in] libOffset: UInt64;
      [in, NumberOfBytes] cb: UInt64;
      [in] LockType: TLockType
    ): HResult; stdcall;

    function Stat(
      [out] out statstg: TStatStg;
      [in] grfStatFlag: TStatFlags
    ): HResult; stdcall;

    function Clone(
      [out] out stm: IStream
    ): HResult; stdcall;
  end;

  // SDK::objidl.h
  [SDKName('BIND_OPTS')]
  TBindOpts = record
    cbStruct: Cardinal;
    grfFlags: Cardinal;
    grfMode: Cardinal;
    dwTickCountDeadline: Cardinal;
  end;

  IRunningObjectTable = interface;

  // SDK::objidl.h
  [SDKName('IBindCtx')]
  IBindCtx = interface(IUnknown)
    ['{0000000E-0000-0000-C000-000000000046}']
    function RegisterObjectBound(
      [in] const unk: IUnknown
    ): HResult; stdcall;

    function RevokeObjectBound(
      [in] const unk: IUnknown
    ): HResult; stdcall;

    function ReleaseBoundObjects(
    ): HResult; stdcall;

    function SetBindOptions(
      [in] const bindopts: TBindOpts
    ): HResult; stdcall;

    function GetBindOptions(
      [in, out] var bindopts: TBindOpts
    ): HResult; stdcall;

    function GetRunningObjectTable(
      [out] out rot: IRunningObjectTable
    ): HResult; stdcall;

    function RegisterObjectParam(
      [in] pszKey: PWideChar;
      [in] const unk: IUnknown
    ): HResult; stdcall;

    function GetObjectParam(
      [in] pszKey: PWideChar;
      [out] out unk: IUnknown
    ): HResult; stdcall;

    function EnumObjectParam(
      [out] out Enum: IEnumString
    ): HResult; stdcall;

    function RevokeObjectParam(
      [in] pszKey: PWideChar
    ): HResult; stdcall;
  end;

  IMoniker = interface;

  // SDK::objidl.h
  [SDKName('IEnumMoniker')]
  IEnumMoniker = interface(IUnknown)
    ['{00000102-0000-0000-C000-000000000046}']
    function Next(
      [in, NumberOfElements] celt: Cardinal;
      [out] out elt: TAnysizeArray<IMoniker>;
      [out, opt, NumberOfElements] pceltFetched: PCardinal
    ): HResult; stdcall;

    function Skip(
      [in, NumberOfElements] celt: Cardinal
    ): HResult; stdcall;

    function Reset(
    ): HResult; stdcall;

    function Clone(
      [out] out enm: IEnumMoniker
    ): HResult; stdcall;
  end;

  // SDK::objidl.h
  [SDKName('IRunningObjectTable')]
  IRunningObjectTable = interface(IUnknown)
    ['{00000010-0000-0000-C000-000000000046}']
    function &Register(
      [in] grfFlags: Cardinal;
      [in] const unkObject: IUnknown;
      [in] const mkObjectName: IMoniker;
      [out] out dwRegister: Cardinal
    ): HResult; stdcall;

    function Revoke(
      [in] dwRegister: Cardinal
    ): HResult; stdcall;

    function IsRunning(
      [in] const mkObjectName: IMoniker
    ): HResult; stdcall;

    function GetObject(
      [in] const mkObjectName: IMoniker;
      [out] out unkObject: IUnknown
    ): HResult; stdcall;

    function NoteChangeTime(
      [in] dwRegister: Cardinal;
      [in] const [ref] filetime: TLargeInteger
    ): HResult; stdcall;

    function GetTimeOfLastChange(
      [in] const mkObjectName: IMoniker;
      [out] out filetime: TLargeInteger
    ): HResult; stdcall;

    function EnumRunning(
      [out] out enumMoniker: IEnumMoniker
    ): HResult; stdcall;
  end;

  // SDK::objidl.h
  [SDKName('IPersist')]
  IPersist = interface(IUnknown)
    ['{0000010C-0000-0000-C000-000000000046}']
    function GetClassID(
      [out] out classID: TClsid
    ): HResult; stdcall;
  end;

  // SDK::objidl.h
  [SDKName('IPersistStream')]
  IPersistStream = interface(IPersist)
    ['{00000109-0000-0000-C000-000000000046}']
    function IsDirty(
    ): HResult; stdcall;

    function Load(
      [in] const stm: IStream
    ): HResult; stdcall;

    function Save(
      [in] const stm: IStream;
      [in] fClearDirty: LongBool
    ): HResult; stdcall;

    function GetSizeMax(
      [out, NumberOfBytes] out cbSize: UInt64
    ): HResult; stdcall;
  end;

  // SDK::objidl.h
  [SDKName('MKSYS')]
  [NamingStyle(nsSnakeCase, 'MKSYS'), ValidMask($7BF)]
  TMkSys = (
    MKSYS_NONE = 0,
    MKSYS_GENERICCOMPOSITE = 1,
    MKSYS_FILEMONIKER = 2,
    MKSYS_ANTIMONIKER = 3,
    MKSYS_ITEMMONIKER = 4,
    MKSYS_POINTERMONIKER = 5,
    [Reserved] MKSYS_6 = 6,
    MKSYS_CLASSMONIKER = 7,
    MKSYS_OBJREFMONIKER = 8,
    MKSYS_SESSIONMONIKER = 9,
    MKSYS_LUAMONIKER = 10
  );

  // SDK::objidl.h
  [SDKName('IMoniker')]
  IMoniker = interface(IPersistStream)
    ['{0000000F-0000-0000-C000-000000000046}']
    function BindToObject(
      [in] const bc: IBindCtx;
      [in, opt] const mkToLeft: IMoniker;
      [in] const iidResult: TIid;
      [out] out vResult
    ): HResult; stdcall;

    function BindToStorage(
      [in] const bc: IBindCtx;
      [in, opt] const mkToLeft: IMoniker;
      [in] const iid: TIid;
      [out] out vObj
    ): HResult; stdcall;

    function Reduce(
      [in] const bc: IBindCtx;
      [in] dwReduceHowFar: Cardinal;
      [in, out, opt] var mkToLeft: IMoniker;
      [out] out mkReduced: IMoniker
    ): HResult; stdcall;

    function ComposeWith(
      [in] const mkRight: IMoniker;
      [in] fOnlyIfNotGeneric: LongBool;
      [out] out mkComposite: IMoniker
    ): HResult; stdcall;

    function Enum(
      [in] fForward: LongBool;
      [out] out enumMoniker: IEnumMoniker
    ): HResult; stdcall;

    function IsEqual(
      [in] const mkOtherMoniker: IMoniker
    ): HResult; stdcall;

    function Hash(
      [out] out dwHash: Cardinal
    ): HResult; stdcall;

    function IsRunning(
      [in] const bc: IBindCtx;
      [in, opt] const mkToLeft: IMoniker;
      [in] const mkNewlyRunning: IMoniker
    ): HResult; stdcall;

    function GetTimeOfLastChange(
      [in] const bc: IBindCtx;
      [in, opt] const mkToLeft: IMoniker;
      [out] out filetime: TLargeInteger
    ): HResult; stdcall;

    function Inverse(
      [out] out mk: IMoniker
    ): HResult; stdcall;

    function CommonPrefixWith(
      [in] const mkOther: IMoniker;
      [out] out mkPrefix: IMoniker
    ): HResult; stdcall;

    function RelativePathTo(
      [in] const mkOther: IMoniker;
      [out] out mkRelPath: IMoniker
    ): HResult; stdcall;

    function GetDisplayName(
      [in] const bc: IBindCtx;
      [in, opt] const mkToLeft: IMoniker;
      [out, ReleaseWith('CoGetMalloc::Free')] out pszDisplayName: PWideChar
    ): HResult; stdcall;

    function ParseDisplayName(
      [in] const bc: IBindCtx;
      [in, opt] const mkToLeft: IMoniker;
      [in] pszDisplayName: PWideChar;
      [out, NumberOfElements] out chEaten: Cardinal;
      [out] out mkOut: IMoniker
    ): HResult; stdcall;

    function IsSystemMoniker(
      [out] out dwMksys: TMkSys
    ): HResult; stdcall;
  end;

  // SDK::ExDisp.h
  [SDKName('ShellWindowTypeConstants')]
  [SubEnum(MAX_UINT, SWC_EXPLORER, 'Explorer')]
  [FlagName(SWC_BROWSER, 'Browser')]
  [FlagName(SWC_3RDPARTY, '3-rd Party')]
  [FlagName(SWC_CALLBACK, 'Callback')]
  [FlagName(SWC_DESKTOP, 'Desktop')]
  TShellWindowTypeConstants = type Cardinal;

  // SDK::ExDisp.h
  [SDKName('ShellWindowFindWindowOptions')]
  [FlagName(SWFO_NEEDDISPATCH, 'Need Dispatch')]
  [FlagName(SWFO_INCLUDEPENDING, 'Include Pending')]
  [FlagName(SWFO_COOKIEPASSED, 'Cookie Passed')]
  TShellWindowFindWindowOptions = type Cardinal;

  // SDK::objidl.h
  [SDKName('IShellWindows')]
  IShellWindows = interface (IDispatch)
    ['{85CB6900-4D95-11CF-960C-0080C7F4EE85}']
    function get_Count(
      [out] out Count: Integer
    ): HResult; stdcall;

    function Item(
      [in] index: TVarData;
      [out] out Folder: IDispatch
    ): HResult; stdcall;

    function _NewEnum(
      [out] out ppunk: IUnknown
    ): HResult; stdcall;

    function &Register(
      [in] const pid: IDispatch;
      [in] hwnd: Integer;
      [in] swClass: TShellWindowTypeConstants;
      [out] out plCookie: Integer
    ): HResult; stdcall;

    function RegisterPending(
      [in] lThreadId: TThreadId32;
      [in] const pvarloc: TVarData;
      [Reserved] const varlocRoot: TVarData;
      [in] swClass: TShellWindowTypeConstants;
      [out] out plCookie: Integer
    ): HResult; stdcall;

    function Revoke(
      [in] lCookie: Integer
    ): HResult; stdcall;

    function OnNavigate(
      [in] lCookie: Integer;
      [in] const pvarLoc: TVarData
    ): HResult; stdcall;

    function OnActivated(
      [in] lCookie: Integer;
      [in] fActive: TVariantBool
    ): HResult; stdcall;

    function FindWindowSW(
      [in] const varLoc: TVarData;
      [Reserved] const varLocRoot: TVarData;
      [in] swClass: TShellWindowTypeConstants;
      [out] out hwnd: Integer;
      [in] swfwOptions: TShellWindowFindWindowOptions;
      [out] out dispOut: IDispatch
    ): HResult; stdcall;

    function OnCreated(
      [in] Cookie: Integer;
      [in] const punk: IUnknown
    ): HResult; stdcall;

    function ProcessAttachDetach(
      [in] fAttach: TVariantBool
    ): HResult; stdcall;
  end;

  // SDK::objidl.h
  [SDKName('IServiceProvider')]
  IServiceProvider = interface (IUnknown)
    ['{6d5140c1-7436-11ce-8034-00aa006009fa}']
    function QueryService(
      [in] const guidService: TGuid;
      [in] const riid: TIid;
      [out] out vObject
    ): HResult; stdcall;
  end;

  // SDK::oleidl.h
  [SDKName('IOleWindow')]
  IOleWindow = interface (IUnknown)
    function GetWindow(
      [out] out hwnd: THwnd
    ): HResult; stdcall;

    function ContextSensitiveHelp(
      [in] fEnterMode: LongBool
    ): HResult; stdcall;
  end;

  IShellBrowser = interface;

  // SDK::ShObjIdl_core.h
  [SDKName('SVGIO')]
  [NamingStyle(nsSnakeCase, 'SVGIO')]
  TSvgio = (
    SVGIO_BACKGROUND = 0,
    SVGIO_SELECTION = 1,
    SVGIO_ALLVIEW = 2,
    SVGIO_CHECKED = 3
  );

  // SDK::ShObjIdl_core.h
  [SDKName('IShellView')]
  IShellView = interface (IOleWindow)
    ['{88E39E80-3578-11CF-AE69-08002B2E1262}']
    function TranslateAccelerator(
      [in] pmsg: Pointer
    ): HResult; stdcall;

    function EnableModeless(
      [in] fEnable: LongBool
    ): HResult; stdcall;

    function UIActivate(
      [in] uState: Cardinal
    ): HResult; stdcall;

    function Refresh(
    ): HResult; stdcall;

    function CreateViewWindow(
      [in, opt] const svPrevious: IShellView;
      [in] pfs: Pointer;
      [in] const psb: IShellBrowser;
      [in] const prcView: TRect;
      [out] out hWnd: THwnd
    ): HResult; stdcall;

    function DestroyViewWindow(
    ): HResult; stdcall;

    function GetCurrentInfo(
      [out] pfs: Pointer
    ): HResult; stdcall;

    function AddPropertySheetPages(
      [Reserved] dwReserved: Cardinal;
      [in] pfn: Pointer;
      [in, opt] lparam: LPARAM
    ): HResult; stdcall;

    function SaveViewState(
    ): HResult; stdcall;

    function SelectItem(
      [in] idlItem: Pointer;
      [in] uFlags: Cardinal
    ): HResult; stdcall;

    function GetItemObject(
      [in] uItem: TSvgio;
      [in] const riid: TIid;
      [out] out pv
    ): HResult; stdcall;
  end;

  // SDK::ShObjIdl_core.h
  [SDKName('IShellBrowser')]
  IShellBrowser = interface (IOleWindow)
    ['{000214E2-0000-0000-C000-000000000046}']
    function InsertMenusSB(
      [in] hmenuShared: NativeUInt;
      [in] lpMenuWidths: Pointer
    ): HResult; stdcall;

    function SetMenuSB(
      [in] hmenuShared: NativeUInt;
      [in] holemenuRes: NativeUInt;
      [in] hwndActiveObject: NativeUInt
    ): HResult; stdcall;

    function RemoveMenusSB(
      [in] hmenuShared: NativeUInt
    ): HResult; stdcall;

    function SetStatusTextSB(
      [in] pszStatusText: PWideChar
    ): HResult; stdcall;

    function EnableModelessSB(
      [in] fEnable: LongBool
    ): HResult; stdcall;

    function TranslateAcceleratorSB(
      [in] pmsg: Pointer;
      [in] wID: Word
    ): HResult; stdcall;

    function BrowseObject(
      [in] pidl: Pointer;
      [in] wFlags: Cardinal
    ): HResult; stdcall;

    function GetViewStateStream(
      [in] grfMode: Cardinal;
      [out] out Strm: IStream
    ): HResult; stdcall;

    function GetControlWindow(
      [in] id: Cardinal;
      [out] out hwnd: THwnd
    ): HResult; stdcall;

    function SendControlMsg(
      [in] id: Cardinal;
      [in] uMsg: Cardinal;
      [in] wParam: WPARAM;
      [in] lParam: LPARAM;
      [out] out pret: NativeInt
    ): HResult; stdcall;

    function QueryActiveShellView(
      [out] out shv: IShellView
    ): HResult; stdcall;

    function OnViewWindowActive(
      [in] const shv: IShellView
    ): HResult; stdcall;

    function SetToolbarItems(
      [in] lpButtons: Pointer;
      [in] nButtons: Cardinal;
      [in] uFlags: Cardinal
    ): HResult; stdcall;
  end;

  FolderItem = IUnknown;
  FolderItems = IUnknown;

  // SDK::ShlDisp.h
  [SDKName('IShellFolderViewDual')]
  IShellFolderViewDual = interface (IDispatch)
    ['{E7A1AF80-4D96-11CF-960C-0080C7F4EE85}']
    function get_Application(
      [out] out ppid: IDispatch
    ): HResult; stdcall;

    function get_Parent(
      [out] out ppid: IDispatch
    ): HResult; stdcall;

    function get_Folder(
      [out] out ppid: IDispatch
    ): HResult; stdcall;

    function SelectedItems(
      [out] out ppid: FolderItems
    ): HResult; stdcall;

    function get_FocusedItem(
      [out] out ppid: FolderItem
    ): HResult; stdcall;

    function SelectItem(
      [in] const vfi: TVarData;
      [in] dwFlags: Cardinal
    ): HResult; stdcall;

    function PopupItemMenu(
      [in] pfi: FolderItem;
      [in] vx: TVarData;
      [in] vy: TVarData;
      [out] out pbs: WideString
    ): HResult; stdcall;

    function get_Script(
      [out] out ppDisp: IDispatch
    ): HResult; stdcall;

    function get_ViewOptions(
      [out] out plViewOptions: Cardinal
    ): HResult; stdcall;
  end;

  Folder = IUnknown;

  // SDK::ShlDisp.h
  [SDKName('IShellDispatch')]
  IShellDispatch = interface (IDispatch)
    ['{D8F015C0-C278-11CE-A49E-444553540000}']
    function get_Application(
      [out] out ppid: IDispatch
    ): HResult; stdcall;

    function get_Parent(
      [out] out ppid: IDispatch
    ): HResult; stdcall;

    function NameSpace(
      [in] vDir: TVarData;
      [out] out ppsdf: Folder
    ): HResult; stdcall;

    function BrowseForFolder(
      [in] Hwnd: Integer;
      [in] Title: WideString;
      [in] Options: Cardinal;
      [in] RootFolder: TVarData;
      [out] out ppsdf: Folder
    ): HResult; stdcall;

    function Windows(
      [out] out ppid: IDispatch
    ): HResult; stdcall;

    function Open(
      [in] vDir: TVarData
    ): HResult; stdcall;

    function Explore(
      [in] vDir: TVarData
    ): HResult; stdcall;

    function MinimizeAll(
    ): HResult; stdcall;

    function UndoMinimizeALL(
    ): HResult; stdcall;

    function FileRun(
    ): HResult; stdcall;

    function CascadeWindows(
    ): HResult; stdcall;

    function TileVertically(
    ): HResult; stdcall;

    function TileHorizontally(
    ): HResult; stdcall;

    function ShutdownWindows(
    ): HResult; stdcall;

    function Suspend(
    ): HResult; stdcall;

    function EjectPC(
    ): HResult; stdcall;

    function SetTime(
    ): HResult; stdcall;

    function TrayProperties(
    ): HResult; stdcall;

    function Help(
    ): HResult; stdcall;

    function FindFiles(
    ): HResult; stdcall;

    function FindComputer(
    ): HResult; stdcall;

    function RefreshMenu(
    ): HResult; stdcall;

    function ControlPanelItem(
      [in] bstrDir: WideString
    ): HResult; stdcall;
  end;

  // SDK::ShlDisp.h
  [SDKName('IShellDispatch2')]
  IShellDispatch2 = interface (IShellDispatch)
    ['{A4C6892C-3BA9-11d2-9DEA-00C04FB16162}']
    function IsRestricted(
      [in] Group: WideString;
      [in] Restriction: WideString;
      [out] out RestrictValue: Cardinal
    ): HResult; stdcall;

    function ShellExecute(
      [in] FileName: WideString;
      [in, opt] vArgs: TVarData;
      [in, opt] vDir: TVarData;
      [in, opt] vOperation: TVarData;
      [in, opt] vShow: TVarData
    ): HResult; stdcall;

    function FindPrinter(
      [in, opt] name: WideString;
      [in, opt] location: WideString;
      [in, opt] model: WideString
    ): HResult; stdcall;

    function GetSystemInformation(
      [in] name: WideString;
      [out] out pv: TVarData
    ): HResult; stdcall;

    function ServiceStart(
      [in] ServiceName: WideString;
      [in] Persistent: TVarData;
      [out] out Success: TVarData
    ): HResult; stdcall;

    function ServiceStop(
      [in] ServiceName: WideString;
      [in] Persistent: TVarData;
      [out] out Success: TVarData
    ): HResult; stdcall;

    function IsServiceRunning(
      [in] ServiceName: WideString;
      [out] out Running: TVarData
    ): HResult; stdcall;

    function CanStartStopService(
      [in] ServiceName: WideString;
      [out] out CanStartStop: TVarData
    ): HResult; stdcall;

    function ShowBrowserBar(
      [in] bstrClsid: WideString;
      [in] bShow: TVarData;
      [out] out Success: TVarData
    ): HResult; stdcall;
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
