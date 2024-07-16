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

If you ever need to capture a raw handle value into an IHandle, you need a class that implements this interface plus knows how to release the underlying resource. For example, [NtUtils.Objects](./NtUtils.Objects.pas) defines such class for kernel objects that require calling `NtClose`. It also attaches a helper method to `Auto`, allowing capturing kernel handles by value via `Auto.CaptureHandle(...)`.

## Naming Convention

Names of records, classes, and enumerations start with `T` and use CamelCase (example: `TTokenStatistics`). Pointers to records or other value-types start with `P` (example: `PTokenStatistics`). Names of interfaces start with `I` (example: `ISid`). Constants use ALL_CAPITALS. All definitions from the headers layer that have known official names (such as the types defined in Windows SDK) are marked with an `SDKName` attribute specifying this name.

Most functions use the following name convention: a prefix of the subsystem with _x_ at the end (Ntx, Ldrx, Lsax, Samx, Scmx, Wsx, Usrx, ...) + Action + Target/Object type/etc. Function names also use CamelCase.

## OS Versions

The library targets Windows 7 or higher, both 32- and 64-bit editions. Though, some of the functionality might be available only on the latest 64-bit versions of Windows 11. Some examples are AppContainers and ntdll syscall unhooking. If a library function depends on an API that might not present on Windows 7, it uses delayed import and checks availability at runtime.

## Reflection (aka RTTI)

Delphi comes with a rich reflection system that the library utilizes within the [**NtUiLib**](./NtUiLib) layer. Most of the types defined in the [**Headers**](./Headers/Readme.md) layer are decorated with custom attributes (see [DelphiApi.Reflection](./Headers/DelphiApi.Reflection.pas))  to achieve it. These decorations emit useful metadata that helps the library to precisely represent complex data types (like PEB, TEB, USER_SHARED_DATA) in runtime and produce astonishing reports with a single line of code.

Here is an example representation of `TSecurityLogonSessionData` from [Ntapi.NtSecApi](./Headers/Ntapi.NtSecApi.pas) using [NtUiLib.Reflection.Types](./NtUiLib/NtUiLib.Reflection.Types.pas):

![RTTI-based report](https://user-images.githubusercontent.com/30962924/91781072-b12b2400-ebf9-11ea-923d-89d3b7c305dc.png)

