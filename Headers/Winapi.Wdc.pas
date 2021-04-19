unit Winapi.Wdc;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

interface

uses
  DelphiApi.Reflection;

const
  wdc = 'wdc.dll';

// rev
function WdcRunTaskAsInteractiveUser(
  [in] CommandLine: PWideChar;
  [in, opt] CurrentDirectory: PWideChar;
  [Reserved] dwReserved: Cardinal
): HResult; stdcall; external wdc delayed;

implementation

end.
