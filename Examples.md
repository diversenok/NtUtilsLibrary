# Examples

1. Build and output process tree into the console (**168 kiB** on x64)

```pascal
program ShowProcessTree;

{$APPTYPE CONSOLE}

uses
  NtUtils, NtUtils.SysUtils, NtUtils.Processes.Snapshots, NtUtils.Console, DelphiUtils.Arrays;

procedure PrintSubTree(const Node: TTreeNode<TProcessEntry>; Depth: Integer = 0);
var
  Child: ^TTreeNode<TProcessEntry>;
begin
  // Output the image name with a padding that indicates hierarchy
  writeln(RtlxBuildString(' ', Depth), Node.Entry.ImageName, ' [', Node.Entry.Basic.ProcessID, ']');

  // Show children recursively
  for Child in Node.Children do
    PrintSubTree(Child^, Depth + 1);
end;

procedure Main;
var
  Processes: TArray<TProcessEntry>;
  Tree: TArray<TTreeNode<TProcessEntry>>;
  Node: TTreeNode<TProcessEntry>;
begin
  // Ask the library to snapshot processes
  if not NtxEnumerateProcesses(Processes).IsSuccess then
    Exit;

  // Find all parent-child relationships and build a tree using the built-in parent checker
  Tree := TArray.BuildTree<TProcessEntry>(Processes, ParentProcessChecker);

  // Show each process with no parent as a tree root, then use recursion
  for Node in Tree do
    if not Assigned(Node.Parent) then
      PrintSubTree(Node);
end;

begin
  Main;
end.
```

2. Enumerate symbolic links in HKLM and printe their targets (**144 KiB** on x64, requires around 20 seconds to complete)

```pascal
program FindRegistrySymlinks;

{$APPTYPE CONSOLE}

uses
  Ntapi.ntdef, DelphiApi.Reflection, Ntapi.ntregapi, NtUtils, NtUtils.Registry, NtUtils.Console;

type
  TOnFoundSymlink =  reference to procedure(Name, Target: String);

procedure FindSymlinks(
  const OnFoundSymlink: TOnFoundSymlink;
  Name: String;
  [opt] RootName: String = '';
  [opt] ObjectAttributes: IObjectAttributes = nil
);
var
  hxKey: IHandle;
  Flags: TKeyFlagsInformation;
  SubKeys: TArray<String>;
  SubKey: String;
  SymlinkTarget: String;
begin
  // Do not follow symlinks, open them
  ObjectAttributes := AttributeBuilder(ObjectAttributes).UseAttributes(OBJ_OPENLINK);

  if not NtxOpenKey(hxKey, Name, KEY_ENUMERATE_SUB_KEYS or KEY_QUERY_VALUE, 0, ObjectAttributes).IsSuccess then
    Exit;

  if RootName <> '' then
    Name := RootName + '\' + Name;

  // Query flags to determine if the key is a symlink
  if not NtxKey.Query(hxKey.Handle, KeyFlagsInformation, Flags).IsSuccess then
    Exit;

  if BitTest(Flags.KeyFlags and REG_FLAG_LINK) then
  begin
    // It is, query the target
    if NtxQueryValueKeyString(hxKey.Handle, REG_SYMLINK_VALUE_NAME, SymlinkTarget).IsSuccess then
      OnFoundSymlink(Name, SymlinkTarget);
  end
  else
  begin
    // It is not, process recursively
    if NtxEnumerateSubKeys(hxKey.Handle, SubKeys).IsSuccess then
      for SubKey in SubKeys do
        FindSymlinks(OnFoundSymlink, SubKey, Name, ObjectAttributes.UseRoot(hxKey));
  end;
end;

begin
  writeln('Scanning HKLM for symlinks, it might take a while...');
  FindSymlinks(
      procedure(Name, Target: String)
      begin
        writeln(Name, ' -> ', Target);
      end,
      REG_PATH_MACHINE
    );
  writeln('Completed.');
end.
```

3. Enumerate imports of an EXE or a DLL (**274 KiB** on x64)

```pascal
program EnumerateImports;

{$APPTYPE CONSOLE}

uses
  NtUtils, NtUtils.Files, NtUtils.Files.Open, NtUtils.Sections, NtUtils.ImageHlp, NtUtils.Console, NtUiLib.Errors;

function Main: TNtxStatus;
var
  FileName: String;
  xMemory: IMemory;
  Imports: TArray<TImportDllEntry>;
  Import: TImportDllEntry;
  FunctionEntry: TImportEntry;
begin
  FileName := ParamStr(1);

  if FileName = '' then
  begin
    writeln('You can pass the filename as a parameter. Using the current executable.');
    writeln;
    FileName := ParamStr(0);
  end;

  // Open the file, create a section, and map it into the calling process
  Result := RtlxMapReadonlyFile(xMemory, FileOpenParameters.UseFileName(FileName, fnWin32));

  if not Result.IsSuccess then
    Exit;

  // Parse the PE structure and find normal & delayed imports
  Result := RtlxEnumerateImportImage(Imports, xMemory.Data, xMemory.Size, False, [itNormal, itDelayed]);

  if not Result.IsSuccess then
    Exit;

  // Print them
  for Import in Imports do
  begin
    writeln(Import.DllName);

    for FunctionEntry in Import.Functions do
    begin
      if FunctionEntry.ImportByName then
        write('  ', FunctionEntry.Name)
      else
        write('  #', FunctionEntry.Ordinal);

      if FunctionEntry.DelayedImport then
        writeln(' (delayed)')
      else
        writeln;
    end;
  end;
end;

procedure ReportFailures(const Status: TNtxStatus);
begin
  // Use the constant name such as STATUS_ACCESS_DENIED when available
  if not Status.IsSuccess then
    writeln(Status.ToString, #$D#$A#$D#$A, RtlxNtStatusMessage(Status.Status));
end;

begin
  ReportFailures(Main);
end.
````

4. Output the content of KUSER_SHARED_DATA via reflection (**2.03 MiB** on x64).

```pascal
program ShowUserSharedData;

{$APPTYPE CONSOLE}

uses
  Ntapi.WinNt, NtUtils.Console, DelphiUiLib.Strings, DelphiUiLib.Reflection.Records, NtUiLib.Reflection.Types;

begin
  // Ask the reflection system to traverse the structure
  TRecord.Traverse(USER_SHARED_DATA,
    procedure (const Field: TFieldReflection)
    begin
      writeln(IntToHexEx(Field.Offset), ' ', Field.FieldName, ' : ', Field.Reflection.Text);
    end
  );
end.
```