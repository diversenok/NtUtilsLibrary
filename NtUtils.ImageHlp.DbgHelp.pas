unit NtUtils.ImageHlp.DbgHelp;

{
  This module provides lightweight functionality for working with debug symbols
  directly exported by executable images. For PDB symbols, use
  NtUtils.DbgHelp instead.
}


interface

uses
  NtUtils, NtUtils.Ldr, NtUtils.Files, DelphiApi.Reflection;

type
  TImageHlpSymbol = record
    [Hex] RVA: Cardinal;
    Name: String;
  end;

  TRtlxBestMatchSymbol = record
    Module: TLdrxModuleInfo;
    Symbol: TImageHlpSymbol;
    [Hex] Offset: Cardinal;
    function ToString: String;
  end;

// Lookup all exported symbols in a module
function RtlxEnumSymbols(
  out Symbols: TArray<TImageHlpSymbol>;
  const Image: TMemory;
  MappedAsImage: Boolean;
  RangeChecks: Boolean = True
): TNtxStatus;

// Lookup all exported symbols in a file
function RtlxEnumSymbolsFile(
  out Symbols: TArray<TImageHlpSymbol>;
  const FileParameters: IFileParameters
): TNtxStatus;

// Find a nearest symbol in a module
function RtlxFindBestMatchModule(
  const Module: TLdrxModuleInfo;
  const Symbols: TArray<TImageHlpSymbol>;
  RVA: Cardinal
): TRtlxBestMatchSymbol;

implementation

uses
  NtUtils.SysUtils, NtUtils.ImageHlp, NtUtils.Sections, DelphiUtils.Arrays;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function TRtlxBestMatchSymbol.ToString;
begin
  Result := Module.BaseDllName;

  if Symbol.Name <> '' then
    Result := Result + '!' + Symbol.Name;

  if Offset <> 0 then
  begin
    if Result <> '' then
      Result := Result + '+';

    Result := Result + RtlxUInt64ToStr(Offset, nsHexadecimal);
  end;
end;

function RtlxEnumSymbols;
var
  ExportEntries: TArray<TExportEntry>;
begin
  Result := RtlxEnumerateExportImage(ExportEntries, Image, MappedAsImage,
    RangeChecks);

  if not Result.IsSuccess then
    Exit;

  // Capture all non-forwarder exports
  Symbols := TArray.Convert<TExportEntry, TImageHlpSymbol>(ExportEntries,
    function (const Entry: TExportEntry; out Symbol: TImageHlpSymbol): Boolean
    begin
      Result := not Entry.Forwards;

      if not Result then
        Exit;

      Symbol.RVA := Entry.VirtualAddress;

      if Entry.Name <> '' then
        Symbol.Name := String(Entry.Name)
      else
        Symbol.Name := 'Ordinal#' + RtlxUIntToStr(Entry.Ordinal);
    end
  );

  // Sort them to allow binary search
  TArray.SortInline<TImageHlpSymbol>(Symbols,
    function (const A, B: TImageHlpSymbol): Integer
    begin
      {$Q-}{$R-}
      Cardinal(Result) := A.RVA - B.RVA;
      {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}
    end
  );
end;

function RtlxEnumSymbolsFile;
var
  MappedFile: IMemory;
begin
  Result := RtlxMapFileByName(FileParameters, NtxCurrentProcess, MappedFile);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxEnumSymbols(Symbols, MappedFile.Region, False);
end;

function RtlxFindBestMatchModule;
var
  BestMatch: Integer;
begin
  // We expect the symbols to be sorted
  BestMatch := TArray.BinarySearchEx<TImageHlpSymbol>(Symbols,
    function (const Entry: TImageHlpSymbol): Integer
    begin
      {$Q-}{$R-}
      Cardinal(Result) := Entry.RVA - RVA;
      {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}
    end
  );

  if BestMatch = -1 then
  begin
    // Make a pseudo-symbol for the entire module
    Result.Symbol.RVA := 0;
    Result.Symbol.Name := '';
  end
  else if BestMatch >= 0 then
    Result.Symbol := Symbols[BestMatch] // Exact match
  else
    Result.Symbol := Symbols[-(BestMatch + 2)]; // Nearest symbol below

  Result.Module := Module;
  Result.Offset := RVA - Result.Symbol.RVA;
end;

end.

