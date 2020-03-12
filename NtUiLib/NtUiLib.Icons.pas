unit NtUiLib.Icons;

{ This module provides storage for icons extracted from executable files. Once
  obtained, the icon is cached in an ImageList and can be used in the UI. }

interface

uses
  System.SysUtils, System.Generics.Collections, Vcl.Controls;

type
  TProcessIcons = class
  strict private
    class var Images: TImageList;
    class var Mapping: TDictionary<String, Integer>;
  public
    class constructor Create;
    class destructor Destroy;
    class property ImageList: TImageList read Images;
    class function GetIcon(FileName: String): Integer; static;
    class function GetIconByPid(PID: NativeUInt): Integer; static;
  end;

implementation

uses
  Vcl.ImgList, Vcl.Graphics, Winapi.WinUser, Winapi.Shell, Winapi.WinNt,
  NtUtils.Processes.Query;

{ TProcessIcons }

class constructor TProcessIcons.Create;
begin
  Mapping := TDictionary<String, Integer>.Create;

  Images := TImageList.Create(nil);
  Images.ColorDepth := cd32Bit;
  Images.AllocBy := 32;

  // Add default icon
  GetIcon(USER_SHARED_DATA.NtSystemRoot + '\system32\user32.dll');
end;

class destructor TProcessIcons.Destroy;
begin
  Images.Free;
  Mapping.Free;
end;

class function TProcessIcons.GetIcon(FileName: string): Integer;
var
  ObjIcon: TIcon;
  LargeHIcon, SmallHIcon: HICON;
begin
  Result := 0; // Default icon. See the constructor.

  // Unknown filename means defalut icon
  if FileName = '' then
    Exit;

  // Check if the icon for this file is already here
  if Mapping.TryGetValue(FileName, Result) then
    Exit;

  LargeHIcon := 0;
  SmallHIcon := 0;

  // Try to query the icon. Save it to our ImageList on success.
  if (ExtractIconExW(PWideChar(FileName), 0, LargeHIcon, SmallHIcon, 1) <> 0)
    and (SmallHIcon <> 0) then
  begin
    ObjIcon := TIcon.Create;
    ObjIcon.Handle := SmallHIcon;
    Result := Images.AddIcon(ObjIcon);
    ObjIcon.Free;
  end;

  DestroyIcon(SmallHIcon);
  DestroyIcon(LargeHIcon);

  // Save the icon index for future use
  Mapping.Add(FileName, Result);
end;

class function TProcessIcons.GetIconByPid(PID: NativeUInt): Integer;
begin
  Result := GetIcon(NtxTryQueryImageProcessById(PID));
end;

end.
