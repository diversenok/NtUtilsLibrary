## Header files

These files contain **Windows API** and **Native API** definitions adapted to use with Delphi. They include information from multiple sources, as marked per declaration:

 - **SDK** - Windows [Software Development Kit](https://developer.microsoft.com/en-us/windows/downloads/windows-10-sdk/) provides a significant portion of basic types plus non-ntdll function prototypes.
 - **WDK** - [Windows Driver Kit](https://docs.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk) provides definitions for various system calls.
 - **DDK** - Windows Driver Development Kit is an outdated version of WDK (from the times of Windows 7) that includes a few removed definitions.
 - **ADK** - [Windows Assessment and Deployment Kit](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install) includes DISM and WIM API definitions. 
 - **DIA** - [Debug Interface Access SDK](https://learn.microsoft.com/en-us/visualstudio/debugger/debug-interface-access/debug-interface-access-sdk) provides interfaces for working with debug symbols.
 - **MSDocs** - [Microsoft Documentation](https://docs.microsoft.com/en-us/windows/) provides a few types and functions that do not appear in the official headers.
 - **MS-WINPROTLP** - official [Windows Protocol Specifications](https://docs.microsoft.com/en-us/openspecs/windows_protocols/) that thoroughly document RPC-based functions.
 - **PHNT** - [Process Hacker/System Informer Headers](https://github.com/winsiderss/systeminformer/tree/master/phnt/include) that contain a detailed collection of Native API definitions.
 - **ReactOS** - an open-source [operating system](https://github.com/reactos/reactos) that is binary compatible with Windows.
 - **NtApiDotNet** - [a .NET library for system programming](https://github.com/googleprojectzero/sandbox-attacksurface-analysis-tools/tree/master/NtApiDotNet).
