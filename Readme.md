# NtUtils Library

**NtUtils** is a framework for system programming on Delphi that provides a set of functions with better error handling and language integration than regular Winapi/Ntapi [headers](./Headers/Readme.md), combined with frequently used code snippets and intelligent data types.

You can find some example programs [**here**](./Examples.md).

## Dependencies

The library has a layered structure with three layers in total:
 - [**Headers**](./Headers/Readme.md) layer that defines data types and function prototypes from Windows and Native API. It brings zero dependencies and contains almost no code.
 - [**NtUtils**]() layer that provides the most functionality necessary for system programming. It depends exclusively on the headers and **not even on System.SysUtils**, so with some effort, you might be able to compile remarkably small executables that require only ntdll to work. Of course, in this case, you will be limited in what you can call, but still.
 - [**NtUiLib**](./NtUiLib) layer that adds support for reflective data representation for the end-users. It depends on NtUtils, `System.SysUtils`, `System.Rtti`, and `System.Generics.Collections`.

Therefore, everything you need is already included with the latest free versions of Delphi. As a bonus, compiling console applications without RTTI (aka reflection) yields extremely small executables. See [examples](./Examples.md) for more details.

Since including every file from the library into your projects usually seems redundant, you can configure Delphi for auto-discovery. This way, you can specify a unit in the `uses` section, and Delphi will automatically include it and its dependencies into the project. To configure the folders where Delphi performs the search, go to Project -> Options -> Building -> Delphi Compiler and add the following lines into the Search Path:

```
.\NtUtilsLibrary
.\NtUtilsLibrary\Headers
.\NtUtilsLibrary\NtUiLib
```

If the folder names or locations are different for your project, you need to adjust these lines correspondingly.

## Error Handling

Most of the functions do not raise exceptions but return a **TNtxStatus** (see [NtUtils.pas](./NtUtils.pas)) as a result instead. This type is an improved version of NTSTATUS (though it can hold HRESULT and Win32 errors as well) that additionally stores the name of the last called API function plus some optional information (like requested access mask for open calls and information class for query/set calls). It allows building a fast, convenient, and verbose error reporting system. Later I am planning to add an option to make it automatically capture stack-traces as well.

![An exception](https://user-images.githubusercontent.com/30962924/110462614-345d9300-80d1-11eb-9d97-df8b0ea12d1c.png)

If you prefer using exceptions in your code, you can include [NtUiLib.Exceptions](./NtUiLib.Exceptions.pas) that adds `RaiseOnError()` method to **TNtxStatus**.

## Data Types

All fixed-size data types are structures (also known as records). All pointers outside of the local scope a wrapped into a generic **IMemory\<P\>** interface (see [DelphiUtils.AutoObject](./DelphiUtils.AutoObject.pas)). It implies automatic reference counting (Delphi does not have a garbage collector, but the compiler emits all necessary cleanup code into function epilogues, just like it does for strings and arrays). Therefore, you do not need to call destructors or use *try-finally* blocks to prevent memory leaks; everything happens automatically. To dynamically allocate reference-counted memory, you can use the following syntax:

```pascal
function GiveMeSomeAutoMemory: IMemory<PMyDataType>;
begin
  IMemory(Result) := TAutoMemory.Allocate(4096);
end;
```

There are some aliases available for commonly used variable-size pointer types, here are some examples:
 - IMemory = IMemory\<Pointer\>;
 - ISid = IMemory\<PSid\>;
 - IAcl = IMemory\<PAcl\>;

## Handle Types

Handles use the **IHandle** type (see [DelphiUtils.AutoObject](./DelphiUtils.AutoObject.pas)), which follows the same rules as IMemory, so you do not need to close any of them. You will also find some aliases for IHandle (IScmHandle, ISamHandle, ILsaHandle, etc.), which are available just for the sake of code readability.

If you ever need to capture a raw handle value into an IHandle, you need a class that implements this interface plus knows how to release the underlying resource. For example, TAutoHandle from [NtUtils.Objects](./NtUtils.Objects.pas) does it for kernel objects that require calling NtClose.

## Naming Convention

Names of records, classes, and enumerations start with `T` and use CamelCase (example: `TTokenStatistics`). Pointers to records or other value-types start with `P` (example: `PTokenStatistics`). Names of interfaces start with `I` (example: `ISid`). Constants use ALL_CAPITALS.

Most functions follow the name convention: a preffix of the subsystem with _x_ at the end (Ntx, Ldrx, Lsax, Samx, Scmx, Wsx, Usrx, ...) + Action + Target/Object type/etc. Function names also use CamelCase.

## OS Versions

The library targets Windows 7 or higher, both 32- and 64-bit editions. Though, some of the functionality might be available only on the latest 64-bit versions Windows 10. The examples are AppContainers and ntdll syscall unhooking. If a library function depends on an API that might not present on Windows 7, it uses delayed import and checks availability in runtime.

## Reflection (aka RTTI)

Delphi comes with a rich reflection system that the library utilizes within the [**NtUiLib**](./NtUiLib) layer. Most of the types defined in the [**Headers**](./Headers/Readme.md) layer are decorated with custom attributes (see [DelphiApi.Reflection](./Headers/DelphiApi.Reflection.pas))  to achieve it. These decorations emit useful metadata that helps the library to precisely represent complex data types (like PEB, TEB, USER_SHARED_DATA) in runtime and produce astonishing reports with a single line of code.

Here is an example representation of TSecurityLogonSessionData from [Winapi.NtSecApi](./Headers/Winapi.NtSecApi.pas) using [NtUiLib.Reflection.Types](./NtUiLib/NtUiLib.Reflection.Types.pas):

![RTTI-based report](https://user-images.githubusercontent.com/30962924/91781072-b12b2400-ebf9-11ea-923d-89d3b7c305dc.png)

