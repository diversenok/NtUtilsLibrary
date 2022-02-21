unit Ntapi.crt;

{
  This module provides access to some C runtime functions exported by ntdll.
}

interface

{$MINENUMSIZE 4}
{$WARN SYMBOL_PLATFORM OFF}

uses
  Ntapi.ntdef, Ntapi.Versions, DelphiApi.Reflection;

type
  // SDK::errno.h
  {$SCOPEDENUMS ON}
  [NamingStyle(nsSnakeCase), ValidMask($7D7FBFF7FFF)]
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
    E15,
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
    E26,
    EFBIG = 27,
    ENOSPC = 28,
    ESPIPE = 29,
    EROFS = 30,
    EMLINK = 31,
    EPIPE = 32,
    EDOM = 33,
    ERANGE = 34,
    E35,
    EDEADLK = 36,
    E37,
    ENAMETOOLONG = 38,
    ENOLCK = 39,
    ENOSYS = 40,
    ENOTEMPTY = 41,
    EILSEQ = 42
  );
  PErrno = ^TErrno;
  {$SCOPEDENUMS OFF}

// SDK::stlib.h - last error value
[MinOSVersion(OsWin8)]
function _errno: PErrno; cdecl; external ntdll delayed;

{ Memory }

// Compare memory
function memcmp(
  [in] Buffer1: Pointer;
  [in] Buffer2: Pointer;
  Count: NativeUInt
): Integer; cdecl; external ntdll;

// Copy memory
function memmove(
  [in] Dest: Pointer;
  [in] Source: Pointer;
  Count: NativeUInt
): Pointer; cdecl; external ntdll;

// Fill memory
function memset(
  [in] Dest: Pointer;
  Value: Cardinal;
  Count: NativeUInt
): Pointer; cdecl; external ntdll;

{ Algorithms }

type
  // SDK::corecrt_search.h
  TQSortComparer = function (
    [in, opt] Context: Pointer;
    [in] Key: Pointer;
    [in] Element: Pointer
  ): Integer; cdecl;

  // SDK::corecrt_search.h
  TBinSearchComparer = function (
    [in, opt] Context: Pointer;
    [in] Key: Pointer;
    [in] Datum: Pointer
  ): Integer; cdecl;

// SDK::corecrt_search.h - perform quick sorting of an array
procedure qsort_s(
  [in] Base: Pointer;
  NumOfElements: NativeUInt;
  SizeOfElements: NativeUInt;
  CompareFunction: TQSortComparer;
  [in, opt] Context: Pointer
); cdecl; external ntdll;

// SDK::corecrt_search.h - perform binary search in an array
function bsearch_s(
  [in] Key: Pointer;
  [in] Base: Pointer;
  NumOfElements: NativeUInt;
  SizeOfElements: NativeUInt;
  CompareFunction: TBinSearchComparer;
  [in, opt] Context: Pointer
): Pointer; cdecl; external ntdll;

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
  MaxCount: NativeUInt
): NativeUInt; cdecl; external ntdll;

// SDK::corecrt_wstring.h
function wcsnlen(
  [in] Str: PWideChar;
  MaxCount: NativeUInt
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
  MaxCount: NativeUInt
): Integer; cdecl; external ntdll;

// SDK::corecrt_wstring.h
function wcsncmp(
  [in] String1: PWideChar;
  [in] String2: PWideChar;
  MaxCount: NativeUInt
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
  MaxCount: NativeUInt
): Integer; cdecl; external ntdll;

// SDK::corecrt_wstring.h
function _wcsnicmp(
  [in] String1: PWideChar;
  [in] String2: PWideChar;
  MaxCount: NativeUInt
): Integer; cdecl; external ntdll;

// SDK::string.h - find the first occurrence of a substring
function strstr(
  [in] Str: PAnsiChar;
  [in] SubString: PAnsiChar
): PAnsiChar; cdecl; external ntdll;

// SDK::corecrt_wstring.h
function wcsstr(
  [in] Str: PWideChar;
  [in] SubString: PWideChar
): PWideChar; cdecl; external ntdll;

// SDK::string.h - find the first occurrence of a character
function strchr(
  [in] Str: PAnsiChar;
  Ch: AnsiChar
): PAnsiChar; cdecl; external ntdll;

// SDK::corecrt_wstring.h
function wcschr(
  [in] Str: PWideChar;
  Ch: WideChar
): PWideChar; cdecl; external ntdll;

// SDK::string.h - find the last occurrence of a character
function strrchr(
  [in] Str: PAnsiChar;
  Ch: AnsiChar
): PAnsiChar; cdecl; external ntdll;

// SDK::corecrt_wstring.h
function wcsrchr(
  [in] Str: PWideChar;
  Ch: WideChar
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
[Result: Counter(ctElements)]
function vswprintf_s(
  [out] Destination: PWideChar;
  [Counter(ctElements)] SizeInWords: NativeUInt;
  [in] Format: PWideChar;
  [in, opt] Args: Pointer
): Integer; cdecl; external ntdll;

{ Characters }

// SDK::ctype.h - check if a character is a digit
function isdigit(
  C: Integer // AnsiChar
): LongBool; cdecl; external ntdll;

// SDK::corecrt_wctype.h
function iswdigit(
  C: Integer // WideChar
): LongBool; cdecl; external ntdll;

// SDK::ctype.h - check if a character is a hexadecimal digit
function isxdigit(
  C: Integer // AnsiChar
): LongBool; cdecl; external ntdll;

// SDK::corecrt_wctype.h
function iswxdigit(
  c: Integer // WideChar
): LongBool; cdecl; external ntdll;

{ Integer conversion }

// SDK::stdlib.h - convert a string to an signed 32-bit integer
function strtol(
  [in] StrSource: PAnsiChar;
  [out, opt] Char: PPAnsiChar;
  Base: Integer
): Integer; cdecl; external ntdll;

// SDK::corecrt_wstdlib.h
function wcstol(
  [in] StrSource: PWideChar;
  [out, opt] Char: PPWideChar;
  Base: Integer
): Integer; cdecl; external ntdll;

// SDK::stdlib.h - convert a string to an unsigned 32-bit integer
function strtoul(
  [in] StrSource: PAnsiChar;
  [out, opt] EndChar: PPAnsiChar;
  Base: Integer
): Cardinal; cdecl; external ntdll;

// SDK::corecrt_wstdlib.h
function wcstoul(
  [in] StrSource: PWideChar;
  [out, opt] EndChar: PPWideChar;
  Base: Integer
): Cardinal; cdecl; external ntdll;

implementation

end.
