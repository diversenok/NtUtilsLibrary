unit Ntapi.crt;

{
  This module provides access to some C runtime functions exported by ntdll.
}

interface

{$MINENUMSIZE 4}
{$WARN SYMBOL_PLATFORM OFF}

uses
  Ntapi.ntdef, Ntapi.Versions, DelphiApi.Reflection, DelphiApi.DelayLoad;

const
  // MMSDK::sha.h
  A_SHA_DIGEST_LEN = 20;

type
  // SDK::errno.h
  {$SCOPEDENUMS ON}
  [NamingStyle(nsSnakeCase), ValidBits([0..14, 16..25, 27..34, 36, 38..42])]
  TErrno = (
    ENOERR = 0,
    EPERM = 1,
    ENOENT = 2,
    ESRCH = 3,
    EINTR = 4,
    EIO = 5,
    ENXIO = 6,
    E2BIG = 7,
    ENOEXEC = 8,
    EBADF = 9,
    ECHILD = 10,
    EAGAIN = 11,
    ENOMEM = 12,
    EACCES = 13,
    EFAULT = 14,
    [Reserved] E15,
    EBUSY = 16,
    EEXIST = 17,
    EXDEV = 18,
    ENODEV = 19,
    ENOTDIR = 20,
    EISDIR = 21,
    EINVAL = 22,
    ENFILE = 23,
    EMFILE = 24,
    ENOTTY = 25,
    [Reserved] E26,
    EFBIG = 27,
    ENOSPC = 28,
    ESPIPE = 29,
    EROFS = 30,
    EMLINK = 31,
    EPIPE = 32,
    EDOM = 33,
    ERANGE = 34,
    [Reserved] E35,
    EDEADLK = 36,
    [Reserved] E37,
    ENAMETOOLONG = 38,
    ENOLCK = 39,
    ENOSYS = 40,
    ENOTEMPTY = 41,
    EILSEQ = 42
  );
  PErrno = ^TErrno;
  {$SCOPEDENUMS OFF}

  TShaDigest = array [0 .. A_SHA_DIGEST_LEN - 1] of Byte;

  // MMSDK::sha.h
  [SDKName('A_SHA_CTX')]
  TShaContext = record
    FinishFlag: Cardinal;
    HashVal: TShaDigest;
    state: array [0..4] of Cardinal;
    count: array [0..1] of Cardinal;
    buffer: array [0..63] of Byte;
  end;

// SDK::stlib.h - last error value
[MinOSVersion(OsWin8)]
function _errno(
): PErrno; cdecl; external ntdll delayed;

var delayed_errno: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: '_errno';
);

{ Memory }

// Compare memory
function memcmp(
  [in, ReadsFrom] Buffer1: Pointer;
  [in, ReadsFrom] Buffer2: Pointer;
  [in, NumberOfBytes] Count: NativeUInt
): Integer; cdecl; external ntdll;

// Copy memory
function memmove(
  [out, WritesTo] Dest: Pointer;
  [in, ReadsFrom] Source: Pointer;
  [in, NumberOfBytes] Count: NativeUInt
): Pointer; cdecl; external ntdll;

// Fill memory
function memset(
  [out, WritesTo] Dest: Pointer;
  [in] Value: Cardinal;
  [in, NumberOfElements] Count: NativeUInt
): Pointer; cdecl; external ntdll;

{ Algorithms }

type
  // SDK::corecrt_search.h
  TQSortComparer = function (
    [in] Key: Pointer;
    [in] Element: Pointer
  ): Integer; cdecl;

  // SDK::corecrt_search.h
  [MinOSVersion(OsWin8)]
  TQSortComparerS = function (
    [in, opt] Context: Pointer;
    [in] Key: Pointer;
    [in] Element: Pointer
  ): Integer; cdecl;

  // SDK::corecrt_search.h
  TBinSearchComparer = function (
    [in] Key: Pointer;
    [in] Datum: Pointer
  ): Integer; cdecl;

  // SDK::corecrt_search.h
  [MinOSVersion(OsWin8)]
  TBinSearchComparerS = function (
    [in, opt] Context: Pointer;
    [in] Key: Pointer;
    [in] Datum: Pointer
  ): Integer; cdecl;

// SDK::corecrt_search.h - perform quick sorting of an array
procedure qsort(
  [in, out, ReadsFrom, WritesTo] Base: Pointer;
  [in, NumberOfElements] NumOfElements: NativeUInt;
  [in] SizeOfElements: NativeUInt;
  [in] CompareFunction: TQSortComparer
); cdecl; external ntdll;

// SDK::corecrt_search.h - perform quick sorting of an array
[MinOSVersion(OsWin8)]
procedure qsort_s(
  [in, out, ReadsFrom, WritesTo] Base: Pointer;
  [in, NumberOfElements] NumOfElements: NativeUInt;
  [in] SizeOfElements: NativeUInt;
  [in] CompareFunction: TQSortComparerS;
  [in, opt] Context: Pointer
); cdecl; external ntdll delayed;

var delayed_qsort_s: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'qsort_s';
);

// SDK::corecrt_search.h - perform binary search in an array
[Result: MayReturnNil]
function bsearch(
  [in] Key: Pointer;
  [in, ReadsFrom] Base: Pointer;
  [in, NumberOfElements] NumOfElements: NativeUInt;
  [in] SizeOfElements: NativeUInt;
  [in] CompareFunction: TBinSearchComparer
): Pointer; cdecl; external ntdll;

// SDK::corecrt_search.h - perform binary search in an array
[MinOSVersion(OsWin8)]
[Result: MayReturnNil]
function bsearch_s(
  [in] Key: Pointer;
  [in, ReadsFrom] Base: Pointer;
  [in, NumberOfElements]  NumOfElements: NativeUInt;
  [in] SizeOfElements: NativeUInt;
  [in] CompareFunction: TBinSearchComparerS;
  [in, opt] Context: Pointer
): Pointer; cdecl; external ntdll delayed;

var delayed_bsearch_s: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'bsearch_s';
);

{ Strings }

// SDK::string.h - determine the length of a zero-terminated string
function strlen(
  [in] Str: PAnsiChar
): NativeUInt; cdecl; external ntdll;

// SDK::corecrt_wstring.h
function wcslen(
  [in] Str: PWideChar
): NativeUInt; cdecl; external ntdll;

// SDK::string.h - determine the length of a zero-terminated string within a limited maximum
function strnlen(
  [in] Str: PAnsiChar;
  [in] MaxCount: NativeUInt
): NativeUInt; cdecl; external ntdll;

// SDK::corecrt_wstring.h
function wcsnlen(
  [in] Str: PWideChar;
  [in] MaxCount: NativeUInt
): NativeUInt; cdecl; external ntdll;

// SDK::string.h - case-sensitive comparison
function strcmp(
  [in] String1: PAnsiChar;
  [in] String2: PAnsiChar
): Integer; cdecl; external ntdll;

// SDK::corecrt_wstring.h
function wcscmp(
  [in] String1: PWideChar;
  [in] String2: PWideChar
): Integer; cdecl; external ntdll;

// SDK::string.h - case-sensitive comparison up to the specified length
function strncmp(
  [in] String1: PAnsiChar;
  [in] String2: PAnsiChar;
  [in] MaxCount: NativeUInt
): Integer; cdecl; external ntdll;

// SDK::corecrt_wstring.h
function wcsncmp(
  [in] String1: PWideChar;
  [in] String2: PWideChar;
  [in] MaxCount: NativeUInt
): Integer; cdecl; external ntdll;

// SDK::string.h - case-insensitive comparison
function _stricmp(
  [in] String1: PAnsiChar;
  [in] String2: PAnsiChar
): Integer; cdecl; external ntdll;

// SDK::corecrt_wstring.h
function _wcsicmp(
  [in] String1: PWideChar;
  [in] String2: PWideChar
): Integer; cdecl; external ntdll;

// SDK::string.h - case-insensitive comparison up to the specified length
function _strnicmp(
  [in] String1: PAnsiChar;
  [in] String2: PAnsiChar;
  [in] MaxCount: NativeUInt
): Integer; cdecl; external ntdll;

// SDK::corecrt_wstring.h
function _wcsnicmp(
  [in] String1: PWideChar;
  [in] String2: PWideChar;
  [in] MaxCount: NativeUInt
): Integer; cdecl; external ntdll;

// SDK::string.h - find the first occurrence of a substring
[Result: MayReturnNil]
function strstr(
  [in] Str: PAnsiChar;
  [in] SubString: PAnsiChar
): PAnsiChar; cdecl; external ntdll;

// SDK::corecrt_wstring.h
[Result: MayReturnNil]
function wcsstr(
  [in] Str: PWideChar;
  [in] SubString: PWideChar
): PWideChar; cdecl; external ntdll;

// SDK::string.h - find the first occurrence of a character
[Result: MayReturnNil]
function strchr(
  [in] Str: PAnsiChar;
  [in] Ch: AnsiChar
): PAnsiChar; cdecl; external ntdll;

// SDK::corecrt_wstring.h
[Result: MayReturnNil]
function wcschr(
  [in] Str: PWideChar;
  [in] Ch: WideChar
): PWideChar; cdecl; external ntdll;

// SDK::string.h - find the last occurrence of a character
[Result: MayReturnNil]
function strrchr(
  [in] Str: PAnsiChar;
  [in] Ch: AnsiChar
): PAnsiChar; cdecl; external ntdll;

// SDK::corecrt_wstring.h
[Result: MayReturnNil]
function wcsrchr(
  [in] Str: PWideChar;
  [in] Ch: WideChar
): PWideChar; cdecl; external ntdll;

// SDK::string.h - find the first occurrence of a character in a set
function strcspn(
  [in] Str: PAnsiChar;
  [in] CharSet: PAnsiChar
): NativeUInt; cdecl; external ntdll;

// SDK::corecrt_wstring.h
function wcscspn(
  [in] Str: PWideChar;
  [in] CharSet: PWideChar
): NativeUInt; cdecl; external ntdll;

// SDK::string.h - find the first occurrence of a character not in a set
function strspn(
  [in] Str: PAnsiChar;
  [in] CharSet: PAnsiChar
): NativeUInt; cdecl; external ntdll;

// SDK::corecrt_wstring.h
function wcsspn(
  [in] Str: PWideChar;
  [in] CharSet: PWideChar
): NativeUInt; cdecl; external ntdll;

// SDK::corecrt_wstdio.h - print according to a format
[Result: NumberOfElements]
function vswprintf_s(
  [out, WritesTo] Destination: PWideChar;
  [in, NumberOfElements] SizeInWords: NativeUInt;
  [in] Format: PWideChar;
  [in, opt] Args: Pointer
): Integer; cdecl; external ntdll;

{ Characters }

// SDK::ctype.h - check if a character is a digit
function isdigit(
  [in] C: Integer // AnsiChar
): LongBool; cdecl; external ntdll;

// SDK::corecrt_wctype.h
function iswdigit(
  [in] C: Integer // WideChar
): LongBool; cdecl; external ntdll;

// SDK::ctype.h - check if a character is a hexadecimal digit
function isxdigit(
  [in] C: Integer // AnsiChar
): LongBool; cdecl; external ntdll;

// SDK::corecrt_wctype.h
function iswxdigit(
  [in] c: Integer // WideChar
): LongBool; cdecl; external ntdll;

{ Integer conversion }

// SDK::stdlib.h - convert a string to an signed 32-bit integer
function strtol(
  [in] StrSource: PAnsiChar;
  [out, opt] Char: PPAnsiChar;
  [in, opt] Base: Integer
): Integer; cdecl; external ntdll;

// SDK::corecrt_wstdlib.h
function wcstol(
  [in] StrSource: PWideChar;
  [out, opt] Char: PPWideChar;
  [in, opt] Base: Integer
): Integer; cdecl; external ntdll;

// SDK::stdlib.h - convert a string to an unsigned 32-bit integer
function strtoul(
  [in] StrSource: PAnsiChar;
  [out, opt] EndChar: PPAnsiChar;
  [in, opt] Base: Integer
): Cardinal; cdecl; external ntdll;

// SDK::corecrt_wstdlib.h
function wcstoul(
  [in] StrSource: PWideChar;
  [out, opt] EndChar: PPWideChar;
  [in, opt] Base: Integer
): Cardinal; cdecl; external ntdll;

 { SHA-1 }

// MMSDK::sha.h
procedure A_SHAInit(
  [out] out Context: TShaContext
); stdcall; external ntdll;

// MMSDK::sha.h
procedure A_SHAUpdate(
  [in, out] var Context: TShaContext;
  [in] Buffer: Pointer;
  [in, NumberOfBytes] BufferSize: Cardinal
); stdcall; external ntdll;

// MMSDK::sha.h
procedure A_SHAFinal(
  [in, out] var Context: TShaContext;
  [out] out Digest: TShaDigest
); stdcall; external ntdll;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
