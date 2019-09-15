# NtUtils library

**NtUtils** is a framework for system programming on Delphi that provides a set of functions with better error handling and language integration than regular Winapi/Ntapi [headers](./Headers/Readme.md), combined with frequently used code snippets and intelligent data types.

### Error handling
Most of the functions does not raise exceptions, but return **TNtxStatus** as a result instead. This type is an improved version of NTSTATUS that additionally stores the name of the last called API function plus some optional information (like requested access mask for open calls and information class for query/set calls). It allows building a fast, convenient, and verbose error reporting system.

![An exception](https://user-images.githubusercontent.com/30962924/60736710-8e9f6b80-9f60-11e9-8513-b5a35004de68.png)

### Data types

All fixed-size data types are structures (also known as **records**); all variable-length data types are Delphi objects that are handled through interfaces, which implies automatic reference counting. Strings and dynamic arrays use Delphi's native types, so no memory management is necessary.

### Naming conventions

Names of records, classes, and enumerations start with `T` and use CamelCase (example: `TTokenStatistics`). Pointers to records or other value-types start with `P` (example: `PTokenStatistics`). Names of interfaces start with `I` (example: `ISid`). Constants use ALL_CAPITALS.

Most functions follow the name convention: a preffix of the subsystem with _x_ at the end (Ntx, Ldrx, Lsax, Samx, Scmx, Wsx, Usrx, ...) + Action + Target/Object type/etc. Function names also use CamelCase.
