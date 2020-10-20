unit Winapi.ObjIdl;

interface

uses
  Winapi.WinNt;

type
  TIID = TGuid;
  TCLSID = TGuid;

  // 2262
  IEnumString = interface(IUnknown)
    ['{00000101-0000-0000-C000-000000000046}']
    function Next(Count: Integer; out Elements: TAnysizeArray<PWideChar>; Fetched: PInteger): HResult; stdcall;
    function Skip(Count: Integer): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Clone(out Enm: IEnumString): HResult; stdcall;
  end;

  // 2392
  ISequentialStream = interface(IUnknown)
    ['{0c733a30-2a1c-11ce-ade5-00aa0044773d}']
    function Read(pv: Pointer; cb: FixedUInt; pcbRead: PFixedUInt): HResult; stdcall;
    function Write(pv: Pointer; cb: FixedUInt; pcbWritten: PFixedUInt): HResult; stdcall;
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
    clsid: TCLSID;
    grfStateBits: Cardinal;
    reserved: Cardinal;
  end;

  // 2572
  IStream = interface(ISequentialStream)
    ['{0000000C-0000-0000-C000-000000000046}']
    function Seek(dlibMove: Int64; dwOrigin: Cardinal; out libNewPosition: UInt64): HResult; stdcall;
    function SetSize(libNewSize: UInt64): HResult; stdcall;
    function CopyTo(stm: IStream; cb: UInt64; out cbRead: UInt64; out cbWritten: UInt64): HResult; stdcall;
    function Commit(grfCommitFlags: Cardinal): HResult; stdcall;
    function Revert: HResult; stdcall;
    function LockRegion(libOffset: UInt64; cb: UInt64; dwLockType: Cardinal): HResult; stdcall;
    function UnlockRegion(libOffset: UInt64; cb: UInt64; dwLockType: Cardinal): HResult; stdcall;
    function Stat(out statstg: TStatStg; grfStatFlag: Cardinal): HResult; stdcall;
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
    function GetRunningObjectTable(out rot: IRunningObjectTable): HResult; stdcall;
    function RegisterObjectParam(pszKey: PWideChar; const unk: IUnknown): HResult; stdcall;
    function GetObjectParam(pszKey: PWideChar; out unk: IUnknown): HResult; stdcall;
    function EnumObjectParam(out Enum: IEnumString): HResult; stdcall;
    function RevokeObjectParam(pszKey: PWideChar): HResult; stdcall;
  end;

  IMoniker = interface;
  PIMoniker = ^IMoniker;

  // 8706
  IEnumMoniker = interface(IUnknown)
    ['{00000102-0000-0000-C000-000000000046}']
    function Next(celt: Cardinal; out elt: PIMoniker; pceltFetched: PCardinal): HResult; stdcall;
    function Skip(celt: Cardinal): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Clone(out enm: IEnumMoniker): HResult; stdcall;
  end;

  // 8983
  IRunningObjectTable = interface(IUnknown)
    ['{00000010-0000-0000-C000-000000000046}']
    function Register(grfFlags: Cardinal; const unkObject: IUnknown; const mkObjectName: IMoniker; out dwRegister: Cardinal): HResult; stdcall;
    function Revoke(dwRegister: Cardinal): HResult; stdcall;
    function IsRunning(const mkObjectName: IMoniker): HResult; stdcall;
    function GetObject(const mkObjectName: IMoniker; out unkObject: IUnknown): HResult; stdcall;
    function NoteChangeTime(dwRegister: Cardinal; const filetime: TLargeInteger): HResult; stdcall;
    function GetTimeOfLastChange(const mkObjectName: IMoniker; out filetime: TLargeInteger): HResult; stdcall;
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
    function BindToObject(const bc: IBindCtx; const mkToLeft: IMoniker; const iidResult: TIID; out vResult): HResult; stdcall;
    function BindToStorage(const bc: IBindCtx; const mkToLeft: IMoniker; const iid: TIID; out vObj): HResult; stdcall;
    function Reduce(const bc: IBindCtx; dwReduceHowFar: Cardinal; mkToLeft: PIMoniker; out mkReduced: IMoniker): HResult; stdcall;
    function ComposeWith(const mkRight: IMoniker; fOnlyIfNotGeneric: LongBool; out mkComposite: IMoniker): HResult; stdcall;
    function Enum(fForward: LongBool; out enumMoniker: IEnumMoniker): HResult; stdcall;
    function IsEqual(const mkOtherMoniker: IMoniker): HResult; stdcall;
    function Hash(out dwHash: Cardinal): HResult; stdcall;
    function IsRunning(const bc: IBindCtx; const mkToLeft: IMoniker; const mkNewlyRunning: IMoniker): HResult; stdcall;
    function GetTimeOfLastChange(const bc: IBindCtx; const mkToLeft: IMoniker; out filetime: TLargeInteger): HResult; stdcall;
    function Inverse(out mk: IMoniker): HResult; stdcall;
    function CommonPrefixWith(const mkOther: IMoniker; out mkPrefix: IMoniker): HResult; stdcall;
    function RelativePathTo(const mkOther: IMoniker; out mkRelPath: IMoniker): HResult; stdcall;
    function GetDisplayName(const bc: IBindCtx; const mkToLeft: IMoniker; out pszDisplayName: PWideChar): HResult; stdcall;
    function ParseDisplayName(const bc: IBindCtx; const mkToLeft: IMoniker; pszDisplayName: PWideChar; out chEaten: Cardinal; out mkOut: IMoniker): HResult; stdcall;
    function IsSystemMoniker(out dwMksys: Cardinal): HResult; stdcall;
  end;

implementation

end.
