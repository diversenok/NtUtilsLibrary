unit Ntapi.crt;

interface

uses
  Ntapi.ntdef, DelphiApi.Reflection;

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

implementation

end.
