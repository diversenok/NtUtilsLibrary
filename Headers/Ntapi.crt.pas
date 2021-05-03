unit Ntapi.crt;

{$MINENUMSIZE 4}
{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  Ntapi.ntdef, DelphiApi.Reflection;

type
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

// Last error value (not available on Windows 7)
function _errno: PErrno; cdecl; external ntdll delayed;

{ Memory }

// Compare memory
function memcmp(
  [in] buffer1: Pointer;
  [in] buffer2: Pointer;
  count: NativeUInt
): Integer; cdecl; external ntdll;

// Copy memory
function memmove(
  [in] dest: Pointer;
  [in] src: Pointer;
  count: NativeUInt
): Pointer; cdecl; external ntdll;

// Fill memory
function memset(
  [in] dest: Pointer;
  c: Cardinal;
  count: NativeUInt
): Pointer; cdecl; external ntdll;

{ Algorithms }

type
  TQSortComparer = function (
    [in, opt] context: Pointer;
    [in] key: Pointer;
    [in] element: Pointer
  ): Integer; cdecl;

  TBinSearchComparer = function (
    [in, opt] context: Pointer;
    [in] key: Pointer;
    [in] datum: Pointer
  ): Integer; cdecl;

// Perform quick sorting of an array
procedure qsort_s(
  [in] base: Pointer;
  num: NativeUInt;
  width: NativeUInt;
  compare: TQSortComparer;
  [in, opt] context: Pointer
); cdecl; external ntdll;

// Perform binary search in an array
function bsearch_s(
  [in] key: Pointer;
  [in] base: Pointer;
  number: NativeUInt;
  width: NativeUInt;
  compare: TBinSearchComparer;
  [in, opt] context: Pointer
): Pointer; cdecl; external ntdll;

{ Strings }

// Determine the length of a zero-terminated string
function strlen(
  [in] str: PAnsiChar
): NativeUInt; cdecl; external ntdll;

function wcslen(
  [in] str: PWideChar
): NativeUInt; cdecl; external ntdll;

// Determine the length of a zero-terminated string within a limited maximum
function strnlen(
  [in] str: PAnsiChar;
  numberOfElements: NativeUInt
): NativeUInt; cdecl; external ntdll;

function wcsnlen(
  [in] str: PWideChar;
  numberOfElements: NativeUInt
): NativeUInt; cdecl; external ntdll;

// Case-sensitive comparison
function strcmp(
  [in] string1: PAnsiChar;
  [in] string2: PAnsiChar
): Integer; cdecl; external ntdll;

function wcscmp(
  [in] string1: PWideChar;
  [in] string2: PWideChar
): Integer; cdecl; external ntdll;

// Case-sensitive comparison up to the specified length
function strncmp(
  [in] string1: PAnsiChar;
  [in] string2: PAnsiChar;
  count: NativeUInt
): Integer; cdecl; external ntdll;

function wcsncmp(
  [in] string1: PWideChar;
  [in] string2: PWideChar;
  count: NativeUInt
): Integer; cdecl; external ntdll;

// Case-insensitive comparison
function _stricmp(
  [in] string1: PAnsiChar;
  [in] string2: PAnsiChar
): Integer; cdecl; external ntdll;

function _wcsicmp(
  [in] string1: PWideChar;
  [in] string2: PWideChar
): Integer; cdecl; external ntdll;

// Case-insensitive comparison up to the specified length
function _strnicmp(
  [in] string1: PAnsiChar;
  [in] string2: PAnsiChar;
  count: NativeUInt
): Integer; cdecl; external ntdll;

function _wcsnicmp(
  [in] string1: PWideChar;
  [in] string2: PWideChar;
  count: NativeUInt
): Integer; cdecl; external ntdll;

// Find the first occurrence of a substring
function strstr(
  [in] str: PAnsiChar;
  [in] strSearch: PAnsiChar
): PAnsiChar; cdecl; external ntdll;

function wcsstr(
  [in] str: PWideChar;
  [in] strSearch: PWideChar
): PWideChar; cdecl; external ntdll;

// Find the first occurrence of a character
function strchr(
  [in] str: PAnsiChar;
  c: AnsiChar
): PAnsiChar; cdecl; external ntdll;

function wcschr(
  [in] str: PWideChar;
  c: WideChar
): PWideChar; cdecl; external ntdll;

// Find the last occurrence of a character
function strrchr(
  [in] str: PAnsiChar;
  c: AnsiChar
): PAnsiChar; cdecl; external ntdll;

function wcsrchr(
  [in] str: PWideChar;
  c: WideChar
): PWideChar; cdecl; external ntdll;

// Find the first occurrence of a character in a set
function strcspn(
  [in] str: PAnsiChar;
  [in] strCharSet: PAnsiChar
): NativeUInt; cdecl; external ntdll;

function wcscspn(
  [in] str: PWideChar;
  [in] strCharSet: PWideChar
): NativeUInt; cdecl; external ntdll;

// Find the first occurrence of a character not in a set
function strspn(
  [in] str: PAnsiChar;
  [in] strCharSet: PAnsiChar
): NativeUInt; cdecl; external ntdll;

function wcsspn(
  [in] str: PWideChar;
  [in] strCharSet: PWideChar
): NativeUInt; cdecl; external ntdll;

{ Characters }

// Check if a character is a digit
function isdigit(
  c: Integer // AnsiChar
): LongBool; cdecl; external ntdll;

function iswdigit(
  c: Integer // WideChar
): LongBool; cdecl; external ntdll;

// Check if a character is a hexadecimal digit
function isxdigit(
  c: Integer // AnsiChar
): LongBool; cdecl; external ntdll;

function iswxdigit(
  c: Integer // WideChar
): LongBool; cdecl; external ntdll;

{ Integer conversion }

// Convert a string to an signed 32-bit integer
function strtol(
  [in] strSource: PAnsiChar;
  [out, opt] char: PPAnsiChar;
   base: Integer
): Integer; cdecl; external ntdll;

function wcstol(
  [in] strSource: PWideChar;
  [out, opt] char: PPWideChar;
   base: Integer
): Integer; cdecl; external ntdll;

// Convert a string to an unsigned 32-bit integer
function strtoul(
  [in] strSource: PAnsiChar;
  [out, opt] char: PPAnsiChar;
   base: Integer
): Cardinal; cdecl; external ntdll;

function wcstoul(
  [in] strSource: PWideChar;
  [out, opt] char: PPWideChar;
   base: Integer
): Cardinal; cdecl; external ntdll;

implementation

end.
