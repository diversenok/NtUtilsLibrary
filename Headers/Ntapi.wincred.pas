unit Ntapi.wincred;

{
  This module provides definitions for credentials API.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.WinUser, DelphiApi.Reflection, DelphiApi.DelayLoad;

const
  credui = 'credui.dll';

var
  delayed_credui: TDelayedLoadDll = (DllName: credui);

const
  // SDK:wincred.h
  CREDUIWIN_GENERIC = $00000001;
  CREDUIWIN_CHECKBOX = $00000002;
  CREDUIWIN_AUTHPACKAGE_ONLY = $00000010;
  CREDUIWIN_IN_CRED_ONLY = $00000020;
  CREDUIWIN_ENUMERATE_ADMINS = $00000100;
  CREDUIWIN_ENUMERATE_CURRENT_USER = $00000200;
  CREDUIWIN_SECURE_PROMPT = $00001000;
  CREDUIWIN_PREPROMPTING = $00002000;
  CREDUIWIN_PACK_32_WOW = $10000000;
  CREDUIWIN_IGNORE_CLOUDAUTHORITY_NAME = $00040000; // Win 10 RS1+
  CREDUIWIN_DOWNLEVEL_HELLO_AS_SMART_CARD = $80000000; // Win 10 RS5+

  // SDK:wincred.h
  CRED_PACK_PROTECTED_CREDENTIALS = $01;
  CRED_PACK_WOW_BUFFER = $02;
  CRED_PACK_GENERIC_CREDENTIALS = $04;
  CRED_PACK_ID_PROVIDER_CREDENTIALS = $08;

type
  [FlagName(CREDUIWIN_GENERIC, 'Generic')]
  [FlagName(CREDUIWIN_CHECKBOX, 'Checkbox')]
  [FlagName(CREDUIWIN_AUTHPACKAGE_ONLY, 'Auth Package Only')]
  [FlagName(CREDUIWIN_IN_CRED_ONLY, 'In Cred. Only')]
  [FlagName(CREDUIWIN_ENUMERATE_ADMINS, 'Enumerate Admins')]
  [FlagName(CREDUIWIN_ENUMERATE_CURRENT_USER, 'Enumerate Current User')]
  [FlagName(CREDUIWIN_SECURE_PROMPT, 'Secure Prompt')]
  [FlagName(CREDUIWIN_PREPROMPTING, 'Pre-promting')]
  [FlagName(CREDUIWIN_PACK_32_WOW, 'Pack 32 WoW')]
  [FlagName(CREDUIWIN_IGNORE_CLOUDAUTHORITY_NAME, 'Ignore Cloud Authority Name')]
  [FlagName(CREDUIWIN_DOWNLEVEL_HELLO_AS_SMART_CARD, 'Downlevel Hello As Smart Card')]
  TCredUiWinFlags = type Cardinal;

  [FlagName(CRED_PACK_PROTECTED_CREDENTIALS, 'Protected Credentials')]
  [FlagName(CRED_PACK_WOW_BUFFER, 'WoW Buffer')]
  [FlagName(CRED_PACK_GENERIC_CREDENTIALS, 'Generic Credentials')]
  [FlagName(CRED_PACK_ID_PROVIDER_CREDENTIALS, 'ID Provider Credentials')]
  TCredPackFlags = type Cardinal;

  // SDK:wincred.h
  [SDKName('CREDUI_INFOW')]
  TCredUIInfoW = record
    [RecordSize] Size: Cardinal;
    Parent: THwnd;
    MessageText: PWideChar;
    CaptionText: PWideChar;
    Banner: THBitmap;
  end;
  PCredUIInfoW = ^TCredUIInfoW;

// SDK:wincred.h
function CredUIPromptForWindowsCredentialsW(
  [in, opt] UiInfo: PCredUIInfoW;
  [in] AuthError: TWin32Error;
  [in, out] var AuthPackage: Cardinal;
  [in, opt, ReadsFrom] InAuthBuffer: Pointer;
  [in, NumberOfBytes] InAuthBufferSize: Cardinal;
  [out, WritesTo, ReleaseWith('CoTaskMemFree')] out OutAuthBuffer: Pointer;
  [out, NumberOfBytes] out OutAuthBufferSize: Cardinal;
  [in, out, opt] Save: PLongBool;
  [in] Flags: TCredUiWinFlags
): TWin32Error; stdcall; external credui delayed;

var delayed_CredUIPromptForWindowsCredentialsW: TDelayedLoadFunction = (
  DllName: credui;
  FunctionName: 'CredUIPromptForWindowsCredentialsW';
);

// SDK:wincred.h
function CredUnPackAuthenticationBufferW(
  [in] Flags: TCredPackFlags;
  [in, ReadsFrom] AuthBuffer: Pointer;
  [in, NumberOfBytes] AuthBufferSize: Cardinal;
  [out, opt, WritesTo] UserName: PWideChar;
  [in, out, NumberOfElements] var MaxUserName: Cardinal;
  [out, opt, WritesTo] DomainName: PWideChar;
  [in, out, NumberOfElements] var MaxDomainName: Cardinal;
  [out, opt, WritesTo] Password: PWideChar;
  [in, out, NumberOfElements] var MaxPassword: Cardinal
): LongBool; stdcall; external credui delayed;

var delayed_CredUnPackAuthenticationBufferW: TDelayedLoadFunction = (
  DllName: credui;
  FunctionName: 'CredUnPackAuthenticationBufferW';
);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
