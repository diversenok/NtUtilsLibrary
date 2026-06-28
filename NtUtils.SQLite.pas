unit NtUtils.SQLite;

{
  This module provides helper functions for interacting with SQLite databases.
}

interface

uses
  Ntapi.sqlite, NtUtils, DelphiUtils.AutoObjects, DelphiApi.Reflection;

type
  ISQLiteDb = IPointer<TSqliteDb>;
  ISQLiteStatement = IPointer<TSqliteStatement>;

  TAnonymousSqliteExecCallback = reference to function(
    const ColumnTexts, ColumnNames: TArray<UTF8String>
  ): TSqliteError;

// Open or creata an SQLite database with extra flags
function SqlxOpen(
  out hxDb: ISQLiteDb;
  const FileName: String;
  Flags: TSqliteOpenFlags
): TNtxStatus;

// Execute an SQL query/statement
function SqlxExec(
  const hxDb: ISQLiteDb;
  const SQL: String;
  [opt] Callback: TAnonymousSqliteExecCallback = nil
): TNtxStatus;

// Prepre an SQL query/statement for later use
function SqlxPrepare(
  out hxStatement: ISQLiteStatement;
  const hxDb: ISQLiteDb;
  const SQL: String;
  Flags: TSqlitePrepareFlags = 0
): TNtxStatus;

// Bind a BLOB parameter with a static lifetime to a SQL query/statement
function SqlxBindBlobStatic(
  const hxStatement: ISQLiteStatement;
  Index: Integer;
  [in] Buffer: Pointer;
  BufferSize: Cardinal;
  TransientCopy: Boolean = False
): TNtxStatus;

// Bind a BLOB parameter to an SQL query/statement
function SqlxBindBlob(
  const hxStatement: ISQLiteStatement;
  Index: Integer;
  const Buffer: IMemory
): TNtxStatus;

// Bind a floating-point parameter to an SQL query/statement
function SqlxBindDouble(
  const hxStatement: ISQLiteStatement;
  Index: Integer;
  Value: Double
): TNtxStatus;

// Bind an integer parameter to an SQL query/statement
function SqlxBindInteger(
  const hxStatement: ISQLiteStatement;
  Index: Integer;
  Value: Integer
): TNtxStatus;

// Bind a 64-bit integer parameter to an SQL query/statement
function SqlxBindInt64(
  const hxStatement: ISQLiteStatement;
  Index: Integer;
  Value: Int64
): TNtxStatus;

// Bind a NULL parameter to an SQL query/statement
function SqlxBindNull(
  const hxStatement: ISQLiteStatement;
  Index: Integer
): TNtxStatus;

// Bind a UTF-8 string parameter to an SQL query/statement
function SqlxBindTextA(
  const hxStatement: ISQLiteStatement;
  Index: Integer;
  const Value: UTF8String
): TNtxStatus;

// Bind a UTF-16 string parameter to an SQL query/statement
function SqlxBindTextW(
  const hxStatement: ISQLiteStatement;
  Index: Integer;
  const Value: String
): TNtxStatus;

// Bind a zeroed-out BLOB parameter to an SQL query/statement
function SqlxBindZeroBlob(
  const hxStatement: ISQLiteStatement;
  Index: Integer;
  Size: Cardinal
): TNtxStatus;

// Reset a prepared SQL query/statement to its initial state
function SqlxReset(
  const hxStatement: ISQLiteStatement
): TNtxStatus;

// Execute a step of the SQL query/statement
function SqlxStep(
  const hxStatement: ISQLiteStatement;
  ExpectedReturn: Boolean = True
): TNtxStatus;

// Retrieve a BLOB result from a statement
function SqlxColumnBlob(
  const hxStatement: ISQLiteStatement;
  Column: Integer;
  out Data: IMemory
): TNtxStatus;

// Retrieve a floating-point result from a statement
function SqlxColumnDouble(
  const hxStatement: ISQLiteStatement;
  Column: Integer;
  out Data: Double
): TNtxStatus;

// Retrieve an integer result from a statement
function SqlxColumnInteger(
  const hxStatement: ISQLiteStatement;
  Column: Integer;
  out Data: Integer
): TNtxStatus;

// Retrieve an 64-bit integer result from a statement
function SqlxColumnInt64(
  const hxStatement: ISQLiteStatement;
  Column: Integer;
  out Data: Int64
): TNtxStatus;

// Retrieve an UTF-8 test result from a statement
function SqlxColumnTextA(
  const hxStatement: ISQLiteStatement;
  Column: Integer;
  out Data: UTF8String
): TNtxStatus;

// Retrieve an UTF-8 test result from a statement
function SqlxColumnTextW(
  const hxStatement: ISQLiteStatement;
  Column: Integer;
  out Data: String
): TNtxStatus;

// Determine the type of result from a statement
function SqlxColumnType(
  const hxStatement: ISQLiteStatement;
  Column: Integer;
  out Data: TSqliteType
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.WinError, NtUtils.Ldr, DelphiUtils.AutoEvents;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TSqliteAutoDb = class (TCustomAutoPointer)
    destructor Destroy; override;
  end;

  TSqliteAutoStatement = class (TCustomAutoPointer)
    destructor Destroy; override;
  end;

destructor TSqliteAutoDb.Destroy;
begin
  if LdrxCheckDelayedImport(delayed_sqlite3_close_v2).IsSuccess then
    sqlite3_close_v2(FData);

  inherited;
end;

destructor TSqliteAutoStatement.Destroy;
begin
  if LdrxCheckDelayedImport(delayed_sqlite3_finalize).IsSuccess then
    sqlite3_finalize(FData);

  inherited;
end;

function SqlxTranslateError(
  ReturnCode: Integer
): HRESULT;
begin
  case ReturnCode of
    SQLITE_OK:
      Result := S_OK;
    SQLITE_ROW:
      Result := HResult(STATUS_MORE_ENTRIES or FACILITY_NT_BIT);
    SQLITE_DONE:
      Result := HResult(STATUS_NO_MORE_ENTRIES or FACILITY_NT_BIT);
  else
    Result := SQLITE_E_BASE or ReturnCode;
  end;
end;

function SqlxOpen;
var
  hDb: TSqliteDb;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_open_v2);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'sqlite3_open_v2';
  Result.HResult := SqlxTranslateError(sqlite3_open_v2(PUTF8Char(
    UTF8String(FileName)), hDb, Flags, nil));

  if Result.IsSuccess then
    IPointer(hxDb) := TSqliteAutoDb.Capture(hDb);
end;

function SqlxExecCallbackDispatcher(
  [in] Context: Pointer;
  [in, NumberOfElements] Columns: Integer;
  [in] ColumnTexts: PPUTF8Char;
  [in] ColumnNames: PPUTF8Char
): TSqliteError; cdecl;
var
  Callback: TAnonymousSqliteExecCallback absolute Context;
  Texts, Names: TArray<UTF8String>;
  i: Integer;
begin
  // Collect results and names
  SetLength(Texts, Columns);
  SetLength(Names, Columns);

  for i := 0 to High(Texts) do
  begin
    Texts[i] := UTF8String(ColumnTexts^);
    Names[i] := UTF8String(ColumnNames^);
    Inc(ColumnTexts);
    Inc(ColumnNames);
  end;

  Result := SQLITE_ABORT;

  try
    Result := Callback(Texts, Names);
  except
    on E: TObject do
      if not Assigned(AutoExceptionHanlder) or not
        AutoExceptionHanlder(E) then
        raise;
  end;
end;

function SqlxExec;
var
  Dispatcher: TSqliteExecCallback;
  Context: Pointer absolute Callback;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_exec);

  if not Result.IsSuccess then
    Exit;

  if Assigned(Callback) then
    Dispatcher := SqlxExecCallbackDispatcher
  else
    Dispatcher := nil;

  Result.Location := 'sqlite3_exec';
  Result.LastCall.Parameter := SQL;
  Result.HResult := SqlxTranslateError(sqlite3_exec(
    hxDb.Data, PUTF8Char(UTF8String(SQL)), Dispatcher, Context, nil));
end;

function SqlxPrepare;
var
  hStatement: TSqliteStatement;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_prepare_v3);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'sqlite3_prepare_v3';
  Result.LastCall.Parameter := SQL;
  Result.HResult := SqlxTranslateError(sqlite3_prepare_v3(hxDb.Data,
    PUTF8Char(UTF8String(SQL)), -1, Flags, hStatement, nil));

  if Result.IsSuccess then
    IPointer(hxStatement) := TSqliteAutoStatement.Capture(hStatement);
end;

function SqlxBindBlobStatic;
const
  Deallocator: array [Boolean] of Pointer = (SQLITE_STATIC, SQLITE_TRANSIENT);
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_bind_blob);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'sqlite3_bind_blob';
  Result.HResult := SqlxTranslateError(sqlite3_bind_blob(hxStatement.Data,
    Index, Buffer, BufferSize, Deallocator[TransientCopy <> False]));
end;

procedure SqlxpBindBlobDestructor(
  [in] Buffer: Pointer
); cdecl;
var
  AutoBuffer: IMemory absolute Buffer;
begin
  AutoBuffer._Release;
end;

function SqlxBindBlob;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_bind_blob);

  if not Result.IsSuccess then
    Exit;

  Buffer._AddRef;
  Result.Location := 'sqlite3_bind_blob';
  Result.HResult := SqlxTranslateError(sqlite3_bind_blob(hxStatement.Data,
    Index, Buffer.Data, Buffer.Size, SqlxpBindBlobDestructor));
end;

function SqlxBindDouble;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_bind_double);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'sqlite3_bind_double';
  Result.HResult := SqlxTranslateError(sqlite3_bind_double(hxStatement.Data,
    Index, Value));
end;

function SqlxBindInteger;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_bind_int);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'sqlite3_bind_int';
  Result.HResult := SqlxTranslateError(sqlite3_bind_int(hxStatement.Data,
    Index, Value));
end;

function SqlxBindInt64;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_bind_int64);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'sqlite3_bind_int64';
  Result.HResult := SqlxTranslateError(sqlite3_bind_int64(hxStatement.Data,
    Index, Value));
end;

function SqlxBindNull;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_bind_null);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'sqlite3_bind_null';
  Result.HResult := SqlxTranslateError(sqlite3_bind_null(hxStatement.Data,
    Index));
end;

procedure SqlxBindTextADestructor(
  [in] Buffer: Pointer
); cdecl;
var
  AutoBuffer: UTF8String absolute Buffer;
begin
  Finalize(AutoBuffer);
end;

function SqlxBindTextA;
var
  Dummy: Pointer;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_bind_text);

  if not Result.IsSuccess then
    Exit;

  Dummy := nil;
  UTF8String(Dummy) := Value;
  Result.Location := 'sqlite3_bind_text';
  Result.HResult := SqlxTranslateError(sqlite3_bind_text(hxStatement.Data,
    Index, Dummy, Length(Value), SqlxBindTextADestructor));
end;

procedure SqlxBindTextWDestructor(
  [in] Buffer: Pointer
); cdecl;
var
  AutoBuffer: String absolute Buffer;
begin
  Finalize(AutoBuffer);
end;

function SqlxBindTextW;
var
  ValueRef: Pointer;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_bind_text16);

  if not Result.IsSuccess then
    Exit;

  ValueRef := nil;
  String(ValueRef) := Value;
  Result.Location := 'sqlite3_bind_text16';
  Result.HResult := SqlxTranslateError(sqlite3_bind_text16(hxStatement.Data,
    Index, ValueRef, Length(Value) * SizeOf(WideChar), SqlxBindTextWDestructor));
end;

function SqlxBindZeroBlob;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_bind_zeroblob);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'delayed_sqlite3_bind_zeroblob';
  Result.HResult := SqlxTranslateError(sqlite3_bind_zeroblob(hxStatement.Data,
    Index, Size));
end;

function SqlxReset;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_reset);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'sqlite3_reset';
  Result.HResult := SqlxTranslateError(sqlite3_reset(hxStatement.Data));
end;

function SqlxStep;
var
  Code: TSqliteError;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_step);

  if not Result.IsSuccess then
    Exit;

  Code := sqlite3_step(hxStatement.Data);

  if not ExpectedReturn and (Code = SQLITE_DONE) then
    Code := SQLITE_OK;

  Result.Location := 'sqlite3_step';
  Result.HResult := SqlxTranslateError(Code);
end;

function SqlxColumnBlob;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_column_blob);

  if not Result.IsSuccess then
    Exit;

  Result := LdrxCheckDelayedImport(delayed_sqlite3_column_bytes);

  if not Result.IsSuccess then
    Exit;

  Data := Auto.CopyDynamic(
    sqlite3_column_blob(hxStatement.Data, Column),
    sqlite3_column_bytes(hxStatement.Data, Column)
  );
end;

function SqlxColumnDouble;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_column_double);

  if not Result.IsSuccess then
    Exit;

  Data := sqlite3_column_double(hxStatement.Data, Column);
end;

function SqlxColumnInteger;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_column_int);

  if not Result.IsSuccess then
    Exit;

  Data := sqlite3_column_int(hxStatement.Data, Column);
end;

function SqlxColumnInt64;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_column_int64);

  if not Result.IsSuccess then
    Exit;

  Data := sqlite3_column_int64(hxStatement.Data, Column);
end;

function SqlxColumnTextA;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_column_text);

  if not Result.IsSuccess then
    Exit;

  Result := LdrxCheckDelayedImport(delayed_sqlite3_column_bytes);

  if not Result.IsSuccess then
    Exit;

  SetString(
    Data,
    sqlite3_column_text(hxStatement.Data, Column),
    sqlite3_column_bytes(hxStatement.Data, Column)
  );
end;

function SqlxColumnTextW;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_column_text16);

  if not Result.IsSuccess then
    Exit;

  Result := LdrxCheckDelayedImport(delayed_sqlite3_column_bytes16);

  if not Result.IsSuccess then
    Exit;

  SetString(
    Data,
    sqlite3_column_text16(hxStatement.Data, Column),
    sqlite3_column_bytes16(hxStatement.Data, Column) div SizeOf(WideChar)
  );
end;

function SqlxColumnType;
begin
  Result := LdrxCheckDelayedImport(delayed_sqlite3_column_type);

  if not Result.IsSuccess then
    Exit;

  Data := sqlite3_column_type(hxStatement.Data, Column);
end;

end.
