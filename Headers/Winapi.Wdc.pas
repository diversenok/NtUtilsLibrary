unit Winapi.Wdc;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

interface

const
  wdc = 'wdc.dll';

// rev
function WdcRunTaskAsInteractiveUser(
  CommandLine: PWideChar;
  CurrentDirectory: PWideChar;
  dwReserved: Cardinal
): HResult; stdcall; external wdc delayed;

implementation

end.
