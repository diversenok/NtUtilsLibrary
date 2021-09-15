# Examples

1. Building and outputting process tree into a console (**140 kiB** on x64)

```pascal
program ShowProcessTree;

{$APPTYPE CONSOLE}

uses
  NtUtils, NtUtils.SysUtils, NtUtils.Processes.Snapshots, DelphiUtils.Arrays;

procedure PrintSubTree(const Node: TTreeNode<TProcessEntry>; Depth: Integer = 0);
var
  i: Integer;
begin
  // Output the image name with a padding that indicates hierarchy
  writeln(RtlxBuildString(' ', Depth), Node.Entry.ImageName, ' [', Node.Entry.Basic.ProcessID, ']');

  // Show children recursively
  for i := 0 to High(Node.Children) do
    PrintSubTree(Node.Children[i]^, Depth + 1);
end;

function Main: TNtxStatus;
var
  Processes: TArray<TProcessEntry>;
  Tree: TArray<TTreeNode<TProcessEntry>>;
  i: Integer;
begin
  // Ask the library to snapshot processes
  Result := NtxEnumerateProcesses(Processes);

  if not Result.IsSuccess then
    Exit;

  // Find all parent-child relationships and build a tree using the built-in parent checker
  Tree := TArray.BuildTree<TProcessEntry>(Processes, ParentProcessChecker);

  // Show each process with no parent as a tree root, then use recursion
  for i := 0 to High(Tree) do
    if not Assigned(Tree[i].Parent) then
      PrintSubTree(Tree[i]);
end;

begin
  Main;
  readln;
end.
```

2. Scanning HKLM hive for symbolic links and printing their targets (**131 KiB** on x64, requires around 10 seconds to complete)

```pascal
program FindRegistrySymlinks;

{$APPTYPE CONSOLE}

uses
  NtUtils, Ntapi.ntdef, Ntapi.ntseapi, Ntapi.ntregapi, NtUtils.Registry, NtUtils.Registry.HKCU, NtUtils.Profiles.Reloader;

type
  TOnFoundSymlink =  reference to procedure(Name, Target: String);

procedure FindSymlinks(
  OnFoundSymlink: TOnFoundSymlink;
  Name: String;
  RootName: String = '';
  ObjectAttributes: IObjectAttributes = nil
);
var
  hxKey: IHandle;
  Flags: TKeyFlagsInformation;
  SubKeys: TArray<String>;
  SymlinkTarget: String;
  i: Integer;
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

  if LongBool(Flags.KeyFlags and REG_FLAG_LINK) then
  begin
    // It is, query the target
    if NtxQueryValueKeyString(hxKey.Handle, REG_SYMLINK_VALUE_NAME, SymlinkTarget).IsSuccess then
      OnFoundSymlink(Name, SymlinkTarget);
  end
  else
  begin
    // It is not, process recursively
    if NtxEnumerateSubKeys(hxKey.Handle, SubKeys).IsSuccess then
      for i := 0 to High(SubKeys) do
        FindSymlinks(OnFoundSymlink, SubKeys[i], Name, ObjectAttributes.UseRoot(hxKey));
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
  readln;
end.
```

3. Enumerating imports of an EXE or a DLL and showing detailed error messages on failure (**259 KiB** on x64)

```pascal
program EnumerateImports;

{$APPTYPE CONSOLE}

uses
  NtUtils, NtUtils.Files, NtUtils.Sections, NtUtils.ImageHlp, NtUiLib.Errors;

function Main: TNtxStatus;
var
  FileName: String;
  xMemory: IMemory;
  Imports: TArray<TImportDllEntry>;
  i, j: Integer;
begin
  FileName := ParamStr(1);

  if FileName = '' then
  begin
    writeln('You can pass the filename as a parameter. Using the current executable.');
    writeln;
    FileName := ParamStr(0);
  end;

  // Convert the name to NT format
  Result := RtlxDosPathToNtPathVar(FileName);

  if not Result.IsSuccess then
    Exit;

  // Open the file, create a section, and map it into the calling process
  Result := RtlxMapReadonlyFile(xMemory, FileName);

  if not Result.IsSuccess then
    Exit;

  // Parse the PE structure and find normal & delayed imports
  Result := RtlxEnumerateImportImage(Imports, xMemory.Data, xMemory.Size, False);

  if not Result.IsSuccess then
    Exit;

  // Print them
  for i := 0 to High(Imports) do
  begin
    writeln(Imports[i].DllName);

    for j := 0 to High(Imports[i].Functions) do
    begin
      if Imports[i].Functions[j].ImportByName then
        write('  ', Imports[i].Functions[j].Name)
      else
        write('  #', Imports[i].Functions[j].Ordinal);

      if Imports[i].Functions[j].DelayedImport then
        writeln(' (delayed)')
      else
        writeln;
    end;
  end;
end;

procedure ReportFailures(const xStatus: TNtxStatus);
begin
  // Use the constant name such as STATUS_ACCESS_DENIED when available
  if not xStatus.IsSuccess then
  begin
    writeln(xStatus.Location, ' returned ', RtlxNtStatusName(xStatus.Status));
    writeln;
    writeln(RtlxNtStatusMessage(xStatus.Status));
  end;
end;

begin
  ReportFailures(Main);
  readln;
end.
````

4. Querying an image section of a process via shllcode without accessing the executable file (**280 KiB** on x64).

````pascal
program QuerySection;

{$APPTYPE CONSOLE}

uses
  NtUtils, Ntapi.WinNt, Ntapi.ntmmapi, NtUtils.SysUtils,
  NtUtils.Processes, NtUtils.Processes.Info.Remote, NtUtils.Sections,
  NtUiLib.Errors;

function Main: TNtxStatus;
var
  hxProcess, hxSectiom: IHandle;
  PID: TProcessId;
  xMemory: IMemory;
begin
  write('PID: ');
  readln(PID);

  Result := NtxOpenProcess(hxProcess, PID, PROCESS_QUERY_SECTION);

  if not Result.IsSuccess then
    Exit;

  // Only the process itself can open its image section.
  // This function executes NtQueryInformationProcess(ProcessImageSection) in
  // the context of the target and copies the handle back.
  Result := NtxQuerySectionProcess(hxSectiom, hxProcess);

  if not Result.IsSuccess then
    Exit;

  writeln('Handle value: ', RtlxIntToStr(hxSectiom.Handle, 16));
  hxSectiom.AutoRelease := False;

  // Map the section locally so the user can inspect its content via
  // Process Hacker or a similar tool.
  xMemory := Default(IMemory);
  Result := NtxMapViewOfSection(xMemory, hxSectiom.Handle, NtxCurrentProcess,
    PAGE_READONLY);

  if not Result.IsSuccess then
    Exit;

  writeln('Mapped at: ', RtlxInt64ToStr(UIntPtr(xMemory.Data), 16));
end;

procedure ReportFailures(const xStatus: TNtxStatus);
begin
  if not xStatus.IsSuccess then
    write(xStatus.Location, ' returned ');

  writeln(RtlxNtStatusName(xStatus.Status));
end;

begin
  writeln('Open a section of a process.');
  ReportFailures(Main);
  readln;
end.
````

5. Outputting the content of KUSER_SHARED_DATA via reflection (**1.96 MiB** on x64).

```pascal
program ShowUserSharedData;

{$APPTYPE CONSOLE}

uses
  Ntapi.WinNt, DelphiUiLib.Strings, DelphiUiLib.Reflection.Records, NtUiLib.Reflection.Types;

begin
  // Ask the reflection system to traverse the structure
  TRecord.Traverse(USER_SHARED_DATA,
    procedure (const Field: TFieldReflection)
    begin
      writeln(IntToHexEx(Field.Offset), ' ', Field.FieldName, ' : ', Field.Reflection.Text);
    end
  );

  readln;
end.
```