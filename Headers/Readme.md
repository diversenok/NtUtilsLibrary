## Header files

These files contain **Windows API** and **Native API** definitions adapted to use with Delphi. They include information from different sources, i.e.:

 - [Windows SDK](https://developer.microsoft.com/en-us/windows/downloads/windows-10-sdk/) — for most of Winapi definitions;
 - [phnt](https://github.com/processhacker/phnt) — for most of Ntapi definition;
 - [Windows WDK](https://docs.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk) — for some Ntapi definitions;
 - [\[MS-WINPROTLP\]](https://docs.microsoft.com/en-us/openspecs/windows_protocols/) specifications — for _Lsa\*_, _Sam\*_, and _WinStation\*_ functions;
 - [Microsoft Docs](https://docs.microsoft.com/en-us/windows/) & [MSDN](https://msdn.microsoft.com/) — for some functions that I can't find in headers (like _LogonUserExExW_);
 - Reverse engineering and Internet forums — for things like _Ntapi.Wdc_.
