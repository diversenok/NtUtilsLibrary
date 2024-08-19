# NtUtils Library

**NtUtils** is a framework for Windows system programming in Delphi that provides a set of functions with better error handling and language integration than regular Winapi/Ntapi [headers](./Headers/Readme.md), combined with frequently used code snippets and intelligent data types.

You can find some example code in a [**dedicated repository**](https://github.com/diversenok/NtUtilsLibrary-Examples).

## Dependencies

### Library Structure

The library has a layered structure with three layers in total:
 - [**Headers**](./Headers/Readme.md) layer defines data types and annotated function prototypes from Windows and Native API. It brings zero dependencies and contains almost no code. Note that the library is self-sufficient and **doesn't import Winapi units** that are included with Delphi. It's possible to mix the built-in `Winapi.*.pas` and library `Ntapi.*.pas` headers in your program; although, it might require explicitly specifying the namespace prefix in case of conflicting names.
 - [**NtUtils**]() layer provides most of the functionality of the library by offerring hundreds of wrappers for various categories of OS APIs. It depends exclusively on the headers layer and **not even on System.SysUtils**, so it barely increases the size of compiled executables.
 - [**NtUiLib**](./NtUiLib) layer adds support for reflective data representation meant for the end-users. It depends on NtUtils, `System.SysUtils`, `System.Rtti`, and `System.Generics.Collections`.

Therefore, everything you need is already included with the latest [free version of Delphi](https://www.embarcadero.com/products/delphi/starter). As a bonus, compiling console applications without RTTI (aka reflection) yields extremely small executables. See [examples](https://github.com/diversenok/NtUtilsLibrary-Examples) for more details.

### Unit Auto-discovery

Since including every file from the library into your projects is usually redundant, you can configure Delphi for file auto-discovery. This way, you can specify a unit in the `uses` section, and Delphi will automatically include it and its dependencies into the project. To configure the folders where Delphi performs the search, go to Project -> Options -> Building -> Delphi Compiler and add the following lines into the Search Path:

```
.\NtUtilsLibrary
.\NtUtilsLibrary\Headers
.\NtUtilsLibrary\NtUiLib
```

If the folder names or locations are different for your project, you need to adjust these lines correspondingly.

## Error Handling

### TNtxStatus

The library indicates failures to the caller by returning unsuccessful **TNtxStatus** values. `TNtxStatus` (defined in [NtUtils.pas](./NtUtils.pas)) is a structure that stores an error code (compatible with `NTSTATUS`, `HRESULT`, and a Win32 Errors) plus metadata about the nature of the attempted operation, such as the location of the failure, a stacktrace, and other details like expected/requested access mask for open calls or the info class value for query/set calls. To check if `TNtxStatus` is successful, use its `IsSuccess` method. To access or set the underlying error code (depending on its type and the caller's preference) use properties such as `Status`, `HResult`, `HResultAllowFalse`, `Win32Error`, `Win32ErrorOrSuccess`, `IsHResult`, `IsWin32`, etc.

### Exceptions

If you prefer using exceptions, you can always call `RaiseOnError()` on a given `TNtxStatus`. Note that unless you really want to use exceptions without importing `System.SysUtils` (which is possible), it's better to include [NtUiLib.Exceptions](./NtUiLib.Exceptions.pas) that brings a dedicated `ENtError` exception class  (derived from the built-in `EOSError`).

### Error Representation

[NtUiLib.Errors](./NtUiLib.Errors.pas) attaches four methods for representing `TNtxStatus` values as strings. For instance, if the error with value `0xC0000061` comes from an attempt to change a session ID of a token, these methods will return the following information:

Method        | Returned string
------------- | ---------------
`Name`        | `STATUS_PRIVILEGE_NOT_HELD`
`Description` | `A required privilege is not held by the client`
`Summary`     | `Privilege Not Held`
`ToString`    | `NtSetInformationToken returned STATUS_PRIVILEGE_NOT_HELD`

If you want to go even further and show a pretty message box to the user, [NtUiLib.Errors.Dialog](./NtUiLib/NtUiLib.Errors.Dialog.pas) offers `ShowNtxStatus()`. Additionally, including [NtUiLib.Exceptions.Dialog](./NtUiLib/NtUiLib.Exceptions.Dialog.pas) will bring necessary reflection support and enrich the dialog even further. Here is an example of how it might look:

![An exception](https://user-images.githubusercontent.com/30962924/110462614-345d9300-80d1-11eb-9d97-df8b0ea12d1c.png)

### Stack Traces & Debug Symbols

`TNtxStatus` supports capturing stack traces (disabled by default). To enable it, set `NtUtils.CaptureStackTraces` to True. Keep in mind that displaying stack traces in a meaningful way requires configuring generation of debug symbols for your executable. Unfortunately, Delphi can only output `.map` files (configured via Project -> Options -> Building -> Delphi Compiler -> Linking -> Map File) which are generally not enough. You'll need a 3-rd party [**map2dbg** tool](https://stackoverflow.com/questions/9422703) to convert them into `.dbg` files, so that symbol API can understand them. While `.dbg` files might be enough, it's better to process them even further by converting into the modern `.pdb` via [**cv2pdb**](https://github.com/rainers/cv2pdb).

To generate debug symbols automatically, add the following post-build events into your project:
```
map2dbg.exe $(OUTPUTPATH)
cv2pdb64.exe -n -s. -p$(OUTPUTNAME).pdb $(OUTPUTPATH)
``` 

## Automatic Lifetime Management

### Memory

Delphi does not include a garbage collector, so only a few types are managed out-of-the-box: records, strings, dynamic arrays, and interfaces. Classes and pointers, on the other hand, require explicit cleaning-up which (in its safe form) requires using *try-finally* blocks and, therefore, complicates the program significantly.  To address this issue, the library includes facilities for automatic lifetime management for memory and other resources, implemented in [DelphiUtils.AutoObjects](./DelphiUtils.AutoObjects.pas). By using types from this module, we instruct the compiler to automatically generate exception-safe code for counting references and automatically releasing objects in function epilogues. This module defines several interfaces for various types of resources that might require cleanup. It introduces the following hierarchy:

```mermaid
graph LR;
  subgraph id1[Any resource]
    IAutoReleasable
  end
  subgraph id2[A THandle value]
    IHandle
  end
  subgraph id3[A Delphi class]
    IAutoObject[IAutoObject&ltT&gt]
  end
  subgraph id4[A pointer]
    IAutoPointer[IAutoPointer&ltP&gt]
  end
  subgraph id5[A memory region]
    IMemory[IMemory&ltP&gt]
  end
  IAutoReleasable --> IHandle;
  IAutoReleasable --> IAutoObject;
  IAutoReleasable --> IAutoPointer;
  IAutoPointer --> IMemory;
```

`IAutoReleasable` is the base type for all resources that require taking action on (automatic) cleanup. `IHandle` serves as a wrapper for resources defined by a THandle value. `IAutoObject<T>` is a generic wrapper for automatically releasing Delphi classes (i.e., anything derived from TObject). `IAutoPointer<P>` defines a similar interface for releasing dynamically allocated pointers (where the size of the region is irrelevant). `IMemory<P>` provides a wrapper for memory regions of known sizes that can be accessed via a typed pointer, such as managed and unmanaged boxed records.

The recipe for using this facility is the following:

1. Define every variable that needs to maintain (a potentially shared) ownership over an object using one of the interfaces:
   - For classes, use **IAutoObject\<TMyClass\>**.
   - For dynamic memory accessible via a pointer, use **IMemory**, also known as **IMemory\<Pointer\>**.
   - For (managed) boxed records, use **IMemory\<PMyRecord\>**.
   
2. Use the **Auto** helper for allocating/copying/capturing automatic objects:
   - Use **Auto.From\<TMyClass\>(...)** to capture ownership of a class object derived from TObject.
   - Use **Auto.AllocateDynamic(...)** and **Auto.CopyDynamic(...)** for unmanaged structures.
   - Use **Auto.Allocate\<TMyRecord\>(...)** and **Auto.Copy\<TMyRecord\>(...)** for storing managed boxed records on the heap.

3. When necessary, use left-side casting that helps avoiding duplicating type information and can shorten the syntax.

For example, here is a safe code for working with TStringList using the classical approach:

```pascal
var
  x: TStringList;
begin
  x := TStringList.Create;
  try
    x.Add('Hi there');
    x.SaveToFile('test.txt');
  finally
    x.Free;
  end;
end;
```

As you can imagine, using more objects in this function will significantly and non-linearly increase its complexity. Alternatively, here is the equivalent code that uses **IAutoObject** and scales up way better:

```pascal
uses
  DelphiUtils.AutoObjects;
var
  x: IAutoObject<TStringList>;
begin
  x := Auto.From(TStringList.Create);
  x.Self.Add('Hi there');
  x.Self.SaveToFile('test.txt');
end; 
```

The compiler emits necessary clean-up code into the function epilogue and makes sure it executes even if exceptions occur. Additionally, this approach allows maintaining shared ownership over the underlying object, which lets you save a reference that can outlive the current function (by capturing it in an anonymous function and returning it, for example). If you don't need this functionality and want to maintain a single owner that frees the object when the function exits, you can simplify the syntax even further:

```pascal
uses
  NtUtils;
var
  x: TStringList;
begin
  x := Auto.From(TStringList.Create).Self;
  x.Add('Hi there');
  x.SaveToFile('test.txt');
end; 
```

This code is still equivalent to the initial one. Internally, it creates a hidden local variable that stores the interface and later releases the object.

When working with dynamic memory allocations, it can be convenient to use left-side casting as following:

```pascal
var
  x: IMemory<PByteArray>;
begin
  IMemory(x) := Auto.AllocateDynamic(100);
  x.Data[15] := 20;
end;
```

You can also create boxed (allocated on the heap) managed records that allow sharing value types as if they are reference types. Note that they can also include managed fields like Delphi strings and dynamic arrays - the compiler emits code for releasing them automatically:

```pascal
type
  TMyRecord = record
    MyInteger: Integer;
    MyArray: TArray<Integer>;
  end;                   
  PMyRecord = ^TMyRecord;

var
  x: IMemory<PMyRecord>;
begin
  IMemory(x) := Auto.Allocate<TMyRecord>;
  x.Data.MyInteger := 42;
  x.Data.MyArray := [1, 2, 3];
end;
```

Since Delphi uses reference counting, it is still possible to leak memory if two objects have a circular dependency. You can prevent it from happening by using *weak references*. Such reference does not count for prolonging lifetime, and the variable that stores them becomes automatically becomes **nil** when the target object gets destroyed. You need to upgrade a weak reference to a strong one before you can use it. See **Weak\<I\>** from DelphiUtils.AutoObjects for more details.

There are some aliases available for commonly used variable-size pointer types, here are some examples:

 - IAutoPointer = IAutoPointer\<Pointer\>;
 - IMemory = IMemory\<Pointer\>;
 - ISid = IAutoPointer\<PSid\>;
 - IAcl = IAutoPointer\<PAcl\>;
 - ISecurityDescriptor = IAutoPointer\<PSecurityDescriptor\>;
 - etc.

### Handles

Handles use the **IHandle** type (see [DelphiUtils.AutoObjects](./DelphiUtils.AutoObjects.pas)), which follows the logic discussed above, so they do not require explicit closing. You can also find some aliases for IHandle (IScmHandle, ISamHandle, ILsaHandle, etc.), which are available merely for the sake of code readability.

If you ever need to take ownership of a handle value into an IHandle, you need a class that implements this interface plus knows how to release the underlying resource. For example, [NtUtils.Objects](./NtUtils.Objects.pas) defines such class for kernel objects that require calling `NtClose`. It also attaches a helper method to `Auto`, allowing capturing kernel handles by value via `Auto.CaptureHandle(...)`. To create a non-owning IHandle, use `Auto.RefHandle(...)`.

## Naming Convention

Names of records, classes, and enumerations start with `T` and use CamelCase (example: `TTokenStatistics`). Pointers to records or other value-types start with `P` (example: `PTokenStatistics`). Names of interfaces start with `I` (example: `ISid`). Constants use ALL_CAPITALS. All definitions from the headers layer that have known official names (such as the types defined in Windows SDK) are marked with an `SDKName` attribute specifying this name.

Most functions use the following name convention: a prefix of the subsystem with _x_ at the end (Ntx, Ldrx, Lsax, Samx, Scmx, Wsx, Usrx, ...) + Action + Target/Object type/etc. Function names also use CamelCase.

## OS Versions

The library targets Windows 7 or higher, both 32- and 64-bit editions. Though, some of the functionality might be available only on the latest 64-bit versions of Windows 11. Some examples are AppContainers and ntdll syscall unhooking. If a library function depends on an API that might not present on Windows 7, it uses delayed import and checks availability at runtime.

## Reflection (aka RTTI)

Delphi comes with a rich reflection system that the library utilizes within the [**NtUiLib**](./NtUiLib) layer. Most of the types defined in the [**Headers**](./Headers/Readme.md) layer are decorated with custom attributes (see [DelphiApi.Reflection](./Headers/DelphiApi.Reflection.pas))  to achieve it. These decorations emit useful metadata that helps the library to precisely represent complex data types (like PEB, TEB, USER_SHARED_DATA) in runtime and produce astonishing reports with a single line of code.

Here is an example representation of `TSecurityLogonSessionData` from [Ntapi.NtSecApi](./Headers/Ntapi.NtSecApi.pas) using [NtUiLib.Reflection.Types](./NtUiLib/NtUiLib.Reflection.Types.pas):

![RTTI-based report](https://user-images.githubusercontent.com/30962924/91781072-b12b2400-ebf9-11ea-923d-89d3b7c305dc.png)

## Unit overview

Here the overview of the purpose of different modules. 

### Base library modules

Support unit                                                                                     | Description
------------------------------------------------------------------------------------------------ | -----------
[DelphiUtils.AutoObjects](./DelphiUtils.AutoObjects.pas)                                         | Automatic resource lifetime management
[DelphiUtils.AutoEvents](./DelphiUtils.AutoEvents.pas)                                           | Multi-subscriber anonymous events
[DelphiUtils.Arrays](./DelphiUtils.Arrays.pas)                                                   | TArray helpers
[DelphiUtils.Lists](./DelphiUtils.Lists.pas)                                                     | A genetic double-linked list primitive
[DelphiUtils.Async](./DelphiUtils.Async.pas)                                                     | Async I/O support definitions
[DelphiUtils.ExternalImport](./DelphiUtils.ExternalImport.pas)                                   | Delphi external keyword IAT helpers
[DelphiUtils.RangeChecks](./DelphiUtils.RangeChecks.pas)                                         | Range checking helpers
[NtUtils](./NtUtils.pas)                                                                         | Common library types
[NtUtils.SysUtils](./NtUtils.SysUtils.pas)                                                       | String manipulation
[NtUtils.Errors](./NtUtils.Errors.pas)                                                           | Error code conversion
[NtUiLib.Errors](./NtUiLib.Errors.pas)                                                           | Error code name lookup
[NtUiLib.Exceptions](./NtUiLib.Exceptions.pas)                                                   | SysUtils exception integration
[DelphiUiLib.Strings](./DelphiUiLib.Strings.pas)                                                 | String prettification
[DelphiUiLib.Reflection](./NtUiLib/DelphiUiLib.Reflection.pas)                                   | Base RTTI support
[DelphiUiLib.Reflection.Numeric](./NtUiLib/DelphiUiLib.Reflection.Numeric.pas)                   | RTTI representation of numeric types
[DelphiUiLib.Reflection.Records](./NtUiLib/DelphiUiLib.Reflection.Records.pas)                   | RTTI representation of record types
[DelphiUiLib.Reflection.Strings](./NtUiLib/DelphiUiLib.Reflection.Strings.pas)                   | RTTI prettification of strings
[NtUiLib.Reflection.Types](./NtUiLib/NtUiLib.Reflection.Types.pas)                               | RTTI representation for common types
[NtUiLib.Console](./NtUiLib.Console.pas)                                                         | Console I/O helpers
[NtUiLib.TaskDialog](./NtUiLib/NtUiLib.TaskDialog.pas)                                           | TaskDialog-based GUI
[NtUiLib.Errors.Dialog](./NtUiLib/NtUiLib.Errors.Dialog.pas)                                     | GUI error dialog
[NtUiLib.Exceptions.Dialog](./NtUiLib/NtUiLib.Exceptions.Dialog.pas)                             | GUI exception dialog

### System API wrappers

System unit                                                                                      | Description
------------------------------------------------------------------------------------------------ | -----------
[NtUtils.ActCtx](./NtUtils.ActCtx.pas)                                                           | Activation contexts
[NtUtils.AntiHooking](./NtUtils.AntiHooking.pas)                                                 | Unhooking and direct syscall
[NtUtils.Com](./NtUtils.Com.pas)                                                                 | COM, IDispatch, WinRT
[NtUtils.Csr](./NtUtils.Csr.pas)                                                                 | CSRSS/SxS registration
[NtUtils.DbgHelp](./NtUtils.DbgHelp.pas)                                                         | DbgHelp and debug symbols
[NtUtils.Debug](./NtUtils.Debug.pas)                                                             | Debug objects
[NtUtils.Dism](./NtUtils.Dism.pas)                                                               | DISM API
[NtUtils.Environment](./NtUtils.Environment.pas)                                                 | Environment variables
[NtUtils.Environment.User](./NtUtils.Environment.User.pas)                                       | User environment variables
[NtUtils.Environment.Remote](./NtUtils.Environment.Remote.pas)                                   | Environment variables of other processes
[NtUtils.Files](./NtUtils.Files.pas)                                                             | Win32/NT filenames
[NtUtils.Files.Open](./NtUtils.Files.Open.pas)                                                   | File and pipe open/create
[NtUtils.Files.Operations](./NtUtils.Files.Operations.pas)                                       | File operations
[NtUtils.Files.Directories](./NtUtils.Files.Directories.pas)                                     | File directory enumeration
[NtUtils.Files.Volumes](./NtUtils.Files.Volumes.pas)                                             | Volume operations
[NtUtils.Files.Control](./NtUtils.Files.Control.pas)                                             | FSCTL operations
[NtUtils.ImageHlp](./NtUtils.ImageHlp.pas)                                                       | PE parsing
[NtUtils.ImageHlp.Syscalls](./NtUtils.ImageHlp.Syscalls.pas)                                     | Syscall number retrieval
[NtUtils.ImageHlp.DbgHelp](./NtUtils.ImageHlp.DbgHelp.pas)                                       | Public symbols without DbgHelp
[NtUtils.Jobs](./NtUtils.Jobs.pas)                                                               | Job objects and silos
[NtUtils.Jobs.Remote](./NtUtils.Jobs.Remote.pas)                                                 | Cross-process job object queries
[NtUtils.Ldr](./NtUtils.Ldr.pas)                                                                 | LDR routines and parsing
[NtUtils.Lsa](./NtUtils.Lsa.pas)                                                                 | LSA policy
[NtUtils.Lsa.Audit](./NtUtils.Lsa.Audit.pas)                                                     | Audit policy
[NtUtils.Lsa.Sid](./NtUtils.Lsa.Sid.pas)                                                         | SID lookup
[NtUtils.Lsa.Logon](./NtUtils.Lsa.Logon.pas)                                                     | Logon sessions
[NtUtils.Manifests](./NtUtils.Manifests.pas)                                                     | Fusion/SxS manifest builder
[NtUtils.Memory](./NtUtils.Memory.pas)                                                           | Memory operations
[NtUtils.MiniDumps](./NtUtils.MiniDumps.pas)                                                     | Minidump format parsing
[NtUtils.Objects](./NtUtils.Objects.pas)                                                         | Kernel objects and handles
[NtUtils.Objects.Snapshots](./NtUtils.Objects.Snapshots.pas)                                     | Handle snapshotting
[NtUtils.Objects.Namespace](./NtUtils.Objects.Namespace.pas)                                     | NT object namespace
[NtUtils.Objects.Remote](./NtUtils.Objects.Remote.pas)                                           | Cross-process handle operations
[NtUtils.Objects.Compare](./NtUtils.Objects.Compare.pas)                                         | Handle comparison
[NtUtils.Packages](./NtUtils.Packages.pas)                                                       | App packages & package families
[NtUtils.Packages.SRCache](./NtUtils.Packages.SRCache.pas)                                       | State repository cache
[NtUtils.Packages.WinRT](./NtUtils.Packages.WinRT.pas)                                           | WinRT-based package info
[NtUtils.Power](./NtUtils.Power.pas)                                                             | Power-related functions
[NtUtils.Processes](./NtUtils.Processes.pas)                                                     | Process objects
[NtUtils.Processes.Info](./NtUtils.Processes.Info.pas)                                           | Process query/set info
[NtUtils.Processes.Info.Remote](./NtUtils.Processes.Info.Remote.pas)                             | Process query/set via code injection
[NtUtils.Processes.Modules](./NtUtils.Processes.Modules.pas)                                     | Cross-process LDR enumeration
[NtUtils.Processes.Snapshots](./NtUtils.Processes.Snapshots.pas)                                 | Process enumeration
[NtUtils.Processes.Create](./NtUtils.Processes.Create.pas)                                       | Common process creation definitions
[NtUtils.Processes.Create.Win32](./NtUtils.Processes.Create.Win32.pas)                           | Win32 process creation methods
[NtUtils.Processes.Create.Shell](./NtUtils.Processes.Create.Shell.pas)                           | Shell process creation methods
[NtUtils.Processes.Create.Native](./NtUtils.Processes.Create.Native.pas)                         | NtCreateUserProcess and co.
[NtUtils.Processes.Create.Manual](./NtUtils.Processes.Create.Manual.pas)                         | NtCreateProcessEx
[NtUtils.Processes.Create.Com](./NtUtils.Processes.Create.Com.pas)                               | COM-based process creation
[NtUtils.Processes.Create.Package](./NtUtils.Processes.Create.Package.pas)                       | Appx activation
[NtUtils.Processes.Create.Remote](./NtUtils.Processes.Create.Remote.pas)                         | Process creation via code injection
[NtUtils.Processes.Create.Clone](./NtUtils.Processes.Create.Clone.pas)                           | Process cloning
[NtUtils.Profiles](./NtUtils.Profiles.pas)                                                       | User & AppContainer profiles
[NtUtils.Registry](./NtUtils.Registry.pas)                                                       | Registry keys
[NtUtils.Registry.Offline](./NtUtils.Registry.Offline.pas)                                       | Offline hive manipulation
[NtUtils.Registry.VReg](./NtUtils.Registry.VReg.pas)                                             | Silo-based registry virtualization
[NtUtils.Sam](./NtUtils.Sam.pas)                                                                 | SAM database
[NtUtils.Sections](./NtUtils.Sections.pas)                                                       | Section/memory projection objects
[NtUtils.Security](./NtUtils.Security.pas)                                                       | Security descriptors
[NtUtils.Security.Acl](./NtUtils.Security.Acl.pas)                                               | ACLs and ACEs
[NtUtils.Security.Sid](./NtUtils.Security.Sid.pas)                                               | SIDs
[NtUtils.Security.AppContainer](./NtUtils.Security.AppContainer.pas)                             | AppContainer & capability SIDs
[NtUtils.Shellcode](./NtUtils.Shellcode.pas)                                                     | Code injection
[NtUtils.Shellcode.Dll](./NtUtils.Shellcode.Dll.pas)                                             | DLL injection
[NtUtils.Shellcode.Exe](./NtUtils.Shellcode.Exe.pas)                                             | EXE injection
[NtUtils.Svc](./NtUtils.Svc.pas)                                                                 | SCM services
[NtUtils.Svc.SingleTaskSvc](./NtUtils.Svc.SingleTaskSvc.pas)                                     | Service implementation
[NtUtils.Synchronization](./NtUtils.Synchronization.pas)                                         | Synchronization primitives
[NtUtils.System](./NtUtils.System.pas)                                                           | System information
[NtUtils.TaskScheduler](./NtUtils.TaskScheduler.pas)                                             | Task scheduler
[NtUtils.Threads](./NtUtils.Threads.pas)                                                         | Thread objects
[NtUtils.Tokens.Info](./NtUtils.Tokens.Info.pas)                                                 | Thread query/set info
[NtUtils.Threads.Worker](./NtUtils.Threads.Worker.pas)                                           | Thread workers (thread pools)
[NtUtils.Tokens](./NtUtils.Tokens.pas)                                                           | Token objects
[NtUtils.Tokens.Impersonate](./NtUtils.Tokens.Impersonate.pas)                                   | Token impersonation
[NtUtils.Tokens.Logon](./NtUtils.Tokens.Logon.pas)                                               | User & S4U logon
[NtUtils.Tokens.AppModel](./NtUtils.Tokens.AppModel.pas)                                         | Token AppModel policy
[NtUtils.Transactions](./NtUtils.Transactions.pas)                                               | Transaction (TmTx) objects
[NtUtils.Transactions.Remote](./NtUtils.Transactions.Remote.pas)                                 | Forcing processes into transactions
[NtUtils.UserManager](./NtUtils.UserManager.pas)                                                 | User Manager service (Umgr) API
[NtUtils.Wim](./NtUtils.Wim.pas)                                                                 | Windows Imaging (*.wim) API
[NtUtils.WinSafer](./NtUtils.WinSafer.pas)                                                       | Safer API
[NtUtils.WinStation](./NtUtils.WinStation.pas)                                                   | Terminal server API
[NtUtils.WinUser](./NtUtils.WinUser.pas)                                                         | User32/GUI API
[NtUtils.WinUser.WindowAffinity](./NtUtils.WinUser.WindowAffinity.pas)                           | Window affinity modification
[NtUtils.WinUser.WinstaLock](./NtUtils.WinUser.WinstaLock.pas)                                   | Locking & unlocking window stations
[NtUtils.XmlLite](./NtUtils.XmlLite.pas)                                                         | XML parsing & crafting via XmlLite
[NtUiLib.AutoCompletion](./NtUiLib/NtUiLib.AutoCompletion.pas)                                   | Auto-completion for edit controls
[NtUiLib.AutoCompletion.Namespace](./NtUiLib/NtUiLib.AutoCompletion.Namespace.pas)               | NT object namespace auto-completion
[NtUiLib.AutoCompletion.Sid](./NtUiLib/NtUiLib.AutoCompletion.Sid.pas)                           | SID auto-completion
[NtUiLib.AutoCompletion.Sid.Common](./NtUiLib/NtUiLib.AutoCompletion.Sid.Common.pas)             | Simple SID name providers/recognizers
[NtUiLib.AutoCompletion.Sid.AppContainer](./NtUiLib/NtUiLib.AutoCompletion.Sid.AppContainer.pas) | AppContainer & package SID providers/recognizers
[NtUiLib.AutoCompletion.Sid.Capabilities](./NtUiLib/NtUiLib.AutoCompletion.Sid.Capabilities.pas) | Capability SID providers/recognizers
[NtUiLib.WinCred](./NtUiLib/NtUiLib.WinCred.pas)                                                 | Credentials dialog
