unit Ntapi.sqlite;

{
  This module provides definitions for interacting with SQLite database files.
}

interface

uses
  DelphiApi.Reflection, DelphiApi.DelayLoad;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

const
  sqlite3 = 'winsqlite3.dll';

var
  delayed_sqlite: TDelayedLoadDll = (DllName: sqlite3);

const
  // sqlite3.h - open flags
  SQLITE_OPEN_READONLY = $00000001;
  SQLITE_OPEN_READWRITE = $00000002;
  SQLITE_OPEN_CREATE = $00000004;
  SQLITE_OPEN_URI = $00000040;
  SQLITE_OPEN_MEMORY = $00000080;
  SQLITE_OPEN_NOMUTEX = $00008000;
  SQLITE_OPEN_FULLMUTEX = $00010000;
  SQLITE_OPEN_SHAREDCACHE = $00020000;
  SQLITE_OPEN_PRIVATECACHE = $00040000;
  SQLITE_OPEN_NOFOLLOW = $01000000;
  SQLITE_OPEN_EXRESCODE = $02000000;

  // sqlite3.h - prepare flags
  SQLITE_PREPARE_PERSISTENT = $01;
  SQLITE_PREPARE_NORMALIZE = $02;
  SQLITE_PREPARE_NO_VTAB = $04;
  SQLITE_PREPARE_DONT_LOG = $10;
  SQLITE_PREPARE_FROM_DDL = $20;

  // sqlite3.h - error codes
  SQLITE_OK = 0;
  SQLITE_ERROR = 1;
  SQLITE_INTERNAL = 2;
  SQLITE_PERM = 3;
  SQLITE_ABORT = 4;
  SQLITE_BUSY = 5;
  SQLITE_LOCKED = 6;
  SQLITE_NOMEM = 7;
  SQLITE_READONLY = 8;
  SQLITE_INTERRUPT = 9;
  SQLITE_IOERR = 10;
  SQLITE_CORRUPT = 11;
  SQLITE_NOTFOUND = 12;
  SQLITE_FULL = 13;
  SQLITE_CANTOPEN = 14;
  SQLITE_PROTOCOL = 15;
  SQLITE_EMPTY = 16;
  SQLITE_SCHEMA = 17;
  SQLITE_TOOBIG = 18;
  SQLITE_CONSTRAINT = 19;
  SQLITE_MISMATCH = 20;
  SQLITE_MISUSE = 21;
  SQLITE_NOLFS = 22;
  SQLITE_AUTH = 23;
  SQLITE_FORMAT = 24;
  SQLITE_RANGE = 25;
  SQLITE_NOTADB = 26;
  SQLITE_NOTICE = 27;
  SQLITE_WARNING = 28;
  SQLITE_ROW = 100;
  SQLITE_DONE = 101;

  // SDK::winerror.h
  FACILITY_SQLITE = $7AF;
  SQLITE_E_BASE = HResult($87AF0000);

  // Special values for TSqliteDestructorType
  SQLITE_STATIC = Pointer(0);
  SQLITE_TRANSIENT = Pointer(1);

type
  TSqliteDb = type Pointer;
  TSqliteStatement = type Pointer;
  TSqliteError = Integer;
  PPUTF8Char = ^PUTF8Char;

  [NamingStyle(nsSnakeCase, 'SQLITE_OPEN')]
  [FlagName(SQLITE_OPEN_READONLY, 'SQLITE_OPEN_READONLY')]
  [FlagName(SQLITE_OPEN_READWRITE, 'SQLITE_OPEN_READWRITE')]
  [FlagName(SQLITE_OPEN_CREATE, 'SQLITE_OPEN_CREATE')]
  [FlagName(SQLITE_OPEN_URI, 'SQLITE_OPEN_URI')]
  [FlagName(SQLITE_OPEN_MEMORY, 'SQLITE_OPEN_MEMORY')]
  [FlagName(SQLITE_OPEN_NOMUTEX, 'SQLITE_OPEN_NOMUTEX')]
  [FlagName(SQLITE_OPEN_FULLMUTEX, 'SQLITE_OPEN_FULLMUTEX')]
  [FlagName(SQLITE_OPEN_SHAREDCACHE, 'SQLITE_OPEN_SHAREDCACHE')]
  [FlagName(SQLITE_OPEN_PRIVATECACHE, 'SQLITE_OPEN_PRIVATECACHE')]
  [FlagName(SQLITE_OPEN_NOFOLLOW, 'SQLITE_OPEN_NOFOLLOW')]
  [FlagName(SQLITE_OPEN_EXRESCODE, 'SQLITE_OPEN_EXRESCODE')]
  TSqliteOpenFlags = type Cardinal;

  [NamingStyle(nsSnakeCase, 'SQLITE_PREPARE')]
  [FlagName(SQLITE_PREPARE_PERSISTENT, 'SQLITE_PREPARE_PERSISTENT')]
  [FlagName(SQLITE_PREPARE_NORMALIZE, 'SQLITE_PREPARE_NORMALIZE')]
  [FlagName(SQLITE_PREPARE_NO_VTAB, 'SQLITE_PREPARE_NO_VTAB')]
  [FlagName(SQLITE_PREPARE_DONT_LOG, 'SQLITE_PREPARE_DONT_LOG')]
  [FlagName(SQLITE_PREPARE_FROM_DDL, 'SQLITE_PREPARE_FROM_DDL')]
  TSqlitePrepareFlags = type Cardinal;

  // sqlite3.h
  [NamingStyle(nsSnakeCase, 'SQLITE'), MinValue(1)]
  TSqliteType = (
    [Reserved] SQLITE_INVALID = 0,
    SQLITE_INTEGER = 1,
    SQLITE_FLOAT = 2,
    SQLITE_TEXT = 3,
    SQLITE_BLOB = 4,
    SQLITE_NULL = 5
  );

  // sqlite3.h
  [SDKName('sqlite3_callback')]
  TSqliteExecCallback = function (
    [in] Context: Pointer;
    [in, NumberOfElements] Columns: Integer;
    [in] ColumnTexts: PPUTF8Char;
    [in] ColumnNames: PPUTF8Char
  ): TSqliteError; cdecl;

  // sqlite3.h
  [SDKName('sqlite3_destructor_type')]
  TSqliteDestructorType = procedure (
    [in] Buffer: Pointer
  ); cdecl;

// sqlite3.h
procedure sqlite3_free(
  [in] Buffer: Pointer
); cdecl; external sqlite3 delayed;

var delayed_sqlite3_free: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_free';
);

// sqlite3.h
function sqlite3_close_v2(
  [in] Db: TSqliteDb
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_close_v2: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_close_v2';
);

// sqlite3.h
function sqlite3_open(
  [in] Filename: PUTF8Char;
  [out, ReleaseWith('sqlite3_close_v2')] out Db: TSqliteDb
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_open: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_open';
);

// sqlite3.h
function sqlite3_open_v2(
  [in] Filename: PUTF8Char;
  [out, ReleaseWith('sqlite3_close_v2')] out Db: TSqliteDb;
  [in] Flags: TSqliteOpenFlags;
  [in, opt] Vfs: PUTF8Char
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_open_v2: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_open_v2';
);

// sqlite3.h
function sqlite3_exec(
  [in] Db: TSqliteDb;
  [in] Sql: PUTF8Char;
  [in, opt] Callback: TSqliteExecCallback;
  [in, opt] Context: Pointer;
  [out, opt, ReleaseWith('sqlite3_free')] ErrMsg: PPUTF8Char
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_exec: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_exec';
);

// sqlite3.h
function sqlite3_finalize(
  [in] Statement: TSqliteStatement
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_finalize: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_finalize';
);

// sqlite3.h
function sqlite3_prepare_v3(
  [in] Db: TSqliteDb;
  [in, ReadsFrom] Sql: PUTF8Char;
  [in, NumberOfBytes] SqlSize: Integer;
  [in] Flags: TSqlitePrepareFlags;
  [out, ReleaseWith('sqlite3_finalize')] out Statement: TSqliteStatement;
  [out, opt] Tail: PPUTF8Char
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_prepare_v3: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_prepare_v3';
);

// sqlite3.h
function sqlite3_bind_blob(
  [in] Statement: TSqliteStatement;
  [in] Index: Integer;
  [in, ReadsFrom] Buffer: Pointer;
  [in, NumberOfBytes] BufferSize: Cardinal;
  [in] BufferDestructor: TSqliteDestructorType
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_bind_blob: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_bind_blob';
);

// sqlite3.h
function sqlite3_bind_blob64(
  [in] Statement: TSqliteStatement;
  [in] Index: Integer;
  [in, ReadsFrom] Buffer: Pointer;
  [in, NumberOfBytes] BufferSize: UInt64;
  [in] BufferDestructor: TSqliteDestructorType
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_bind_blob64: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_bind_blob64';
);

// sqlite3.h
function sqlite3_bind_double(
  [in] Statement: TSqliteStatement;
  [in] Index: Integer;
  [in] Value: Double
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_bind_double: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_bind_double';
);

// sqlite3.h
function sqlite3_bind_int(
  [in] Statement: TSqliteStatement;
  [in] Index: Integer;
  [in] Value: Integer
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_bind_int: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_bind_int';
);

// sqlite3.h
function sqlite3_bind_int64(
  [in] Statement: TSqliteStatement;
  [in] Index: Integer;
  [in] Value: Int64
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_bind_int64: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_bind_int64';
);

// sqlite3.h
function sqlite3_bind_null(
  [in] Statement: TSqliteStatement;
  [in] Index: Integer
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_bind_null: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_bind_null';
);

// sqlite3.h
function sqlite3_bind_text(
  [in] Statement: TSqliteStatement;
  [in] Index: Integer;
  [in, ReadsFrom] Buffer: PUTF8Char;
  [in, NumberOfBytes] BufferSize: Cardinal;
  [in] BufferDestructor: TSqliteDestructorType
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_bind_text: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_bind_text';
);

// sqlite3.h
function sqlite3_bind_text16(
  [in] Statement: TSqliteStatement;
  [in] Index: Integer;
  [in, ReadsFrom] Buffer: PWideChar;
  [in, NumberOfBytes] BufferSize: Cardinal;
  [in] BufferDestructor: TSqliteDestructorType
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_bind_text16: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_bind_text16';
);

// sqlite3.h
function sqlite3_bind_zeroblob(
  [in] Statement: TSqliteStatement;
  [in] Index: Integer;
  [in, NumberOfBytes] Size: Cardinal
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_bind_zeroblob: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_bind_zeroblob';
);

// sqlite3.h
function sqlite3_bind_zeroblob64(
  [in] Statement: TSqliteStatement;
  [in] Index: Integer;
  [in, NumberOfBytes] Size: UInt64
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_bind_zeroblob64: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_bind_zeroblob64';
);

// sqlite3.h
function sqlite3_reset(
  [in] Statement: TSqliteStatement
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_reset: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_reset';
);

// sqlite3.h
function sqlite3_step(
  [in] Statement: TSqliteStatement
): TSqliteError; cdecl; external sqlite3 delayed;

var delayed_sqlite3_step: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_step';
);

// sqlite3.h
function sqlite3_column_blob(
  [in] Statement: TSqliteStatement;
  [in] Column: Integer
): Pointer; cdecl; external sqlite3 delayed;

var delayed_sqlite3_column_blob: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_column_blob';
);

// sqlite3.h
function sqlite3_column_double(
  [in] Statement: TSqliteStatement;
  [in] Column: Integer
): Double; cdecl; external sqlite3 delayed;

var delayed_sqlite3_column_double: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_column_double';
);

// sqlite3.h
function sqlite3_column_int(
  [in] Statement: TSqliteStatement;
  [in] Column: Integer
): Integer; cdecl; external sqlite3 delayed;

var delayed_sqlite3_column_int: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_column_int';
);

// sqlite3.h
function sqlite3_column_int64(
  [in] Statement: TSqliteStatement;
  [in] Column: Integer
): Int64; cdecl; external sqlite3 delayed;

var delayed_sqlite3_column_int64: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_column_int64';
);

// sqlite3.h
function sqlite3_column_text(
  [in] Statement: TSqliteStatement;
  [in] Column: Integer
): PUTF8Char; cdecl; external sqlite3 delayed;

var delayed_sqlite3_column_text: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_column_text';
);

// sqlite3.h
function sqlite3_column_text16(
  [in] Statement: TSqliteStatement;
  [in] Column: Integer
): PWideChar; cdecl; external sqlite3 delayed;

var delayed_sqlite3_column_text16: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_column_text16';
);

// sqlite3.h
function sqlite3_column_bytes(
  [in] Statement: TSqliteStatement;
  [in] Column: Integer
): Cardinal; cdecl; external sqlite3 delayed;

var delayed_sqlite3_column_bytes: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_column_bytes';
);

// sqlite3.h
function sqlite3_column_bytes16(
  [in] Statement: TSqliteStatement;
  [in] Column: Integer
): Cardinal; cdecl; external sqlite3 delayed;

var delayed_sqlite3_column_bytes16: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_column_bytes16';
);

// sqlite3.h
function sqlite3_column_type(
  [in] Statement: TSqliteStatement;
  [in] Column: Integer
): TSqliteType; cdecl; external sqlite3 delayed;

var delayed_sqlite3_column_type: TDelayedLoadFunction = (
  Dll: @delayed_sqlite;
  FunctionName: 'sqlite3_column_type';
);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
