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
    Module: TModuleEntry;
    Symbol: TImageHlpSymbol;
    [Hex] Offset: Cardinal;
    function ToString: String;
  end;

// Lookup all exported symbols in a module
function RtlxEnumSymbols(
  out Symbols: TArray<TImageHlpSymbol>;
  [in] BaseAddress: Pointer;
  ImageSize: Cardinal;
  MappedAsImage: Boolean
): TNtxStatus;

// Lookup all exported symbols in a file
function RtlxEnumSymbolsFile(
  out Symbols: TArray<TImageHlpSymbol>;
  const FileParmeters: IFileOpenParameters
): TNtxStatus;

// Find a nearest symbol in a module
function RtlxFindBestMatchModule(
  const Module: TModuleEntry;
  const Symbols: TArray<TImageHlpSymbol>;
  RVA: Cardinal
): TRtlxBestMatchSymbol;

implementation

uses
  NtUtils.SysUtils, NtUtils.ImageHlp, NtUtils.Sections, DelphiUtils.Arrays;

function TRtlxBestMatchSymbol.ToString;
begin
  Result := Module.BaseDllName;

  if Symbol.Name <> '' then
    Result := Result + '!' + Symbol.Name;

  if Offset <> 0 then
  begin
    if Result <> '' then
      Result := Result + '+';

    Result := Result + RtlxUInt64ToStr(Offset, 16);
  end;
end;

function RtlxEnumSymbols;
var
  ExportEntries: TArray<TExportEntry>;
begin
  Result := RtlxEnumerateExportImage(ExportEntries, BaseAddress, ImageSize,
    MappedAsImage);

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
      {$Q-}
      Cardinal(Result) := A.RVA - B.RVA;
      {$Q+}
    end
  );
end;

function RtlxEnumSymbolsFile;
var
  MappedFile: IMemory;
begin
  Result := RtlxOpenAndMapFile(MappedFile, FileParmeters);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxEnumSymbols(Symbols, MappedFile.Data, MappedFile.Size, False);
end;

function RtlxFindBestMatchModule;
var
  BestMatch: Integer;
begin
  // We expect the symbols to be sorted
  BestMatch := TArray.BinarySearchEx<TImageHlpSymbol>(Symbols,
    function (const Entry: TImageHlpSymbol): Integer
    begin
      {$Q-}
      Cardinal(Result) := Entry.RVA - RVA;
      {$Q+}
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

