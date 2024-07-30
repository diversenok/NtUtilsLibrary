unit NtUtils.Files.Volumes;

{
  This module provides functions for performing some volume-wide operations.
}

interface

uses
  Ntapi.ntioapi, Ntapi.ntioapi.fsctl, Ntapi.ntseapi, Ntapi.Versions,
  DelphiApi.Reflection, NtUtils, NtUtils.Security, DelphiUtils.AutoObjects,
  NtUtils.Files;

type
  TNtxVolumeSecurityDescriptor = record
    [Hex] Hash: Cardinal;
    SecurityId: Cardinal;
    [Hex] Offset: UInt64;
    Data: TSecurityDescriptorData;
  end;

  TNtxFileLayoutStreamInfoType = (
    siNotPresent,
    siData,
    siReparsePoint,
    siExtendedAttribute,
    siDesiredStorageClass
  );

  TNtxFileLayoutStreamInfo = record
    InfoType: TNtxFileLayoutStreamInfoType;
    [Hex] DataFlags: Cardinal;                    // Data
    [Bytes] ValidDataLength: UInt64;              // Data
    Data: IMemory;                                // Data
    ReparseFlags: TStreamInformationReparseFlags; // Reprse point
    ReparseData: IMemory<PReparseDataBuffer>;     // Reprse point
    [Hex] EaFlags: Word;                          // Extended attribute
    EAs: TArray<TNtxExtendedAttribute>;           // Extended attribute
    DesiredStorageClass: TFileDesiredStorageClassInformation; // DSC
  end;

  TNtxFileLayoutStreamEntry = record
    [Hex] Flags: Cardinal;
    [Bytes] AllocationSize: UInt64;
    [Bytes] EndOfFile: UInt64;
    AttributeTypeCode: TAttributeTypeCode;
    AttributeFlags: TFileAttributes;
    StreamIdentifier: String;
    ExtentsFlags: TStreamExtentEntryFlags;
    [Hex] ExtentsStartingVcn: UInt64;
    Extents: TArray<TRetrievalPointersBufferExtents>;
    ExtraInfo: TNtxFileLayoutStreamInfo;
  end;

  TNtxFileLayoutNameEntry = record
    Flags: TFileLayoutNameFlags;
    ParentFileReferenceNumber: TFileId;
    FileName: String;
  end;

  TNtxFileLayoutEntry = record
    [Hex] Flags: Cardinal;
    FileAttributes: TFileAttributes;
    FileReferenceNumber: TFileId;
    Names: TArray<TNtxFileLayoutNameEntry>;
    Streams: TArray<TNtxFileLayoutStreamEntry>;
    InfoValid: Boolean;
    Info: TFileLayoutInfoEntry;
  end;

// Replace one SID with another in all security descriptors of the volume
[RequiredPrivilege(SE_MANAGE_VOLUME_PRIVILEGE, rpForBypassingChecks)]
function NtxChangeVolumeSids(
  const hxVolume: IHandle;
  const CurrentSid: ISid;
  const NewSid: ISid;
  [out, opt] ResultDetails: PSdChangeMachineSidOutput = nil
): TNtxStatus;

// Query statistics about security descriptors on the volume
[RequiredPrivilege(SE_MANAGE_VOLUME_PRIVILEGE, rpForBypassingChecks)]
function NtxQuerySecurityStatsVolume(
  const hxVolume: IHandle;
  out Stats: TSdQueryStatsOutput
): TNtxStatus;

// Iterate over security descriptors on the volume one at a time
[RequiredPrivilege(SE_MANAGE_VOLUME_PRIVILEGE, rpForBypassingChecks)]
function NtxGetNextSecurityDescriptorVolume(
  const hxVolume: IHandle;
  var Cursor: UInt64;
  out Entry: TNtxVolumeSecurityDescriptor
): TNtxStatus;

// Enumerate security descriptors on the volume in blocks
[RequiredPrivilege(SE_MANAGE_VOLUME_PRIVILEGE, rpForBypassingChecks)]
function NtxEnumerateSecurityDescriptorsVolume(
  const hxVolume: IHandle;
  var Cursor: UInt64;
  out Entries: TArray<TNtxVolumeSecurityDescriptor>;
  BufferSize: NativeUInt = $4000
): TNtxStatus;

// Make a for-in iterator for enumerating security descriptors on a volume.
// Note: when the Status parameter is not set, the function might raise
// exceptions during enumeration.
[RequiredPrivilege(SE_MANAGE_VOLUME_PRIVILEGE, rpForBypassingChecks)]
function NtxIterateSecurityDescriptorsVolume(
  [out, opt] Status: PNtxStatus;
  const hxVolume: IHandle;
  CacheSize: NativeUInt = $4000
): IEnumerable<TNtxVolumeSecurityDescriptor>;

// Query layout information for multiple files
[MinOSVersion(OsWin8)]
[RequiredPrivilege(SE_MANAGE_VOLUME_PRIVILEGE, rpForBypassingChecks)]
function NtxQueryLayoutFiles(
  const hxVolume: IHandle;
  const FileIds: TArray<TFileId>;
  out Entries: TArray<TNtxFileLayoutEntry>;
  Flags: TQueryFileLayoutInputFlags = QUERY_FILE_LAYOUT_ALL
): TNtxStatus;

// Query layout information for a single file
[MinOSVersion(OsWin8)]
[RequiredPrivilege(SE_MANAGE_VOLUME_PRIVILEGE, rpForBypassingChecks)]
function NtxQueryLayoutFile(
  const hxVolume: IHandle;
  const FileId: TFileId;
  out Entry: TNtxFileLayoutEntry;
  Flags: TQueryFileLayoutInputFlags = QUERY_FILE_LAYOUT_ALL
): TNtxStatus;

implementation

uses
  Ntapi.ntrtl, Ntapi.ntdef, Ntapi.ntstatus, NtUtils.Files.Control;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NtxChangeVolumeSids;
var
  Input: IMemory<PSdGlobalChangeInput>;
  Output: TSdGlobalChangeOutput;
begin
  IMemory(Input) := Auto.AllocateDynamic(SizeOf(TSdGlobalChangeInput) +
    RtlLengthSid(CurrentSid.Data) + RtlLengthSid(NewSid.Data));

  // Prepare the structure
  Input.Data.ChangeType := SD_GLOBAL_CHANGE_TYPE_MACHINE_SID;
  Input.Data.SdChange.CurrentMachineSIDOffset := SizeOf(TSdGlobalChangeInput);
  Input.Data.SdChange.CurrentMachineSIDLength := RtlLengthSid(CurrentSid.Data);
  Input.Data.SdChange.NewMachineSIDOffset :=
    Input.Data.SdChange.CurrentMachineSIDOffset +
    Input.Data.SdChange.CurrentMachineSIDLength;
  Input.Data.SdChange.NewMachineSIDLength := RtlLengthSid(NewSid.Data);

  // Marshal the SIDs
  Move(CurrentSid.Data^,
    Input.Offset(Input.Data.SdChange.CurrentMachineSIDOffset)^,
    Input.Data.SdChange.CurrentMachineSIDLength);
  Move(NewSid.Data^,
    Input.Offset(Input.Data.SdChange.NewMachineSIDOffset)^,
    Input.Data.SdChange.NewMachineSIDLength);

  // Issue the FSCTL
  Result := NtxFsControlFile(hxVolume, FSCTL_SD_GLOBAL_CHANGE, Input.Data,
    Input.Size, @Output, SizeOf(Output));

  if Result.IsSuccess and Assigned(ResultDetails) then
    ResultDetails^ := Output.SdChange;
end;

function NtxQuerySecurityStatsVolume;
var
  Input: TSdGlobalChangeInput;
  Output: TSdGlobalChangeOutput;
begin
  Input := Default(TSdGlobalChangeInput);
  Input.ChangeType := SD_GLOBAL_CHANGE_TYPE_QUERY_STATS;

  // Issue the FSCTL
  Result := NtxFsControlFile(hxVolume, FSCTL_SD_GLOBAL_CHANGE,
    @Input, SizeOf(Input), @Output, SizeOf(Output));

  if Result.IsSuccess then
    Stats := Output.SdQueryStats;
end;

function NtxGetNextSecurityDescriptorVolume;
const
  INITIAL_SIZE = SizeOf(TSdGlobalChangeOutput) + $200;
var
  Input: TSdGlobalChangeInput;
  Output: IMemory<PSdGlobalChangeOutput>;
begin
  Input := Default(TSdGlobalChangeInput);
  Input.ChangeType := SD_GLOBAL_CHANGE_TYPE_ENUM_SDS;
  Input.SdEnumSds.StartingOffset := Cursor;
  Input.SdEnumSds.MaxSDEntriesToReturn := 1;

  // Issue the FSCTL
  Result := NtxFsControlFileEx(hxVolume, FSCTL_SD_GLOBAL_CHANGE,
    IMemory(Output), INITIAL_SIZE, nil, @Input, SizeOf(Input));

  if not Result.IsSuccess then
    Exit;

  if Output.Data.SdEnumSds.NumSDEntriesReturned < 1 then
  begin
    Result.Location := 'NtxGetNextSecurityDescriptorVolume';
    Result.Status := STATUS_NO_MORE_MATCHES;
    Exit;
  end;

  // Capture the result
  Cursor := Output.Data.SdEnumSds.NextOffset;
  Entry.Hash := Output.Data.SdEnumSds.SDEntry.Hash;
  Entry.SecurityId := Output.Data.SdEnumSds.SDEntry.SecurityId;
  Entry.Offset := Output.Data.SdEnumSds.SDEntry.Offset;
  Result := RtlxCaptureSecurityDescriptor(Pointer(@Output.Data.SdEnumSds
    .SDEntry.Descriptor), Entry.Data);
end;

function NtxEnumerateSecurityDescriptorsVolume;
var
  Input: TSdGlobalChangeInput;
  Output: IMemory<PSdGlobalChangeOutput>;
  Entry: PSdEnumSDsEntry;
  i: Integer;
begin
  Input := Default(TSdGlobalChangeInput);
  Input.ChangeType := SD_GLOBAL_CHANGE_TYPE_ENUM_SDS;
  Input.SdEnumSds.StartingOffset := Cursor;

  if BufferSize < SizeOf(TSdGlobalChangeOutput) then
    BufferSize := SizeOf(TSdGlobalChangeOutput);

  // Issue the FSCTL
  Result := NtxFsControlFileEx(hxVolume, FSCTL_SD_GLOBAL_CHANGE,
    IMemory(Output), BufferSize, nil, @Input, SizeOf(Input));

  if not Result.IsSuccess then
    Exit;

  if Output.Data.SdEnumSds.NumSDEntriesReturned < 1 then
  begin
    Result.Location := 'NtxIterateSecurityDescriptorsVolume';
    Result.Status := STATUS_NO_MORE_ENTRIES;
    Exit;
  end;

  // Save the result
  Cursor := Output.Data.SdEnumSds.NextOffset;
  SetLength(Entries, Output.Data.SdEnumSds.NumSDEntriesReturned);
  Entry := @Output.Data.SdEnumSds.SDEntry;

  for i := 0 to High(Entries) do
  begin
    Entries[i].Hash := Entry.Hash;
    Entries[i].SecurityId := Entry.SecurityId;
    Entries[i].Offset := Entries[i].Offset;
    Result := RtlxCaptureSecurityDescriptor(Pointer(@Entry.Descriptor),
      Entries[i].Data);

    if not Result.IsSuccess then
      Exit;

    // Advance to the next entry
    Inc(PByte(Entry), AlignUp(Entry.Length, 16));
  end;
end;

function NtxIterateSecurityDescriptorsVolume;
var
  VolumeCursor: UInt64;
  Buffer: TArray<TNtxVolumeSecurityDescriptor>;
  i: Integer;
begin
  VolumeCursor := 0;
  Buffer := nil;
  i := 0;

  Result := NtxAuto.Iterate<TNtxVolumeSecurityDescriptor>(Status,
    function (out Entry: TNtxVolumeSecurityDescriptor): TNtxStatus
    begin
      if i > High(Buffer) then
      begin
        // Retrieve a new block of security descriptors
        Result := NtxEnumerateSecurityDescriptorsVolume(hxVolume, VolumeCursor,
          Buffer, CacheSize);

        if not Result.IsSuccess then
          Exit;

        // Return the first entry and advance
        Entry := Buffer[0];
        i := 1;
      end
      else
      begin
        // Return an item from a previously queried block until it runs out
        Result := NtxSuccess;
        Entry := Buffer[i];
        Inc(i);
      end;
    end
  );
end;

function NtxQueryLayoutFiles;
const
  INITIAL_SIZE = SizeOf(TQueryFileLayoutOutput);
var
  Input: IMemory<PQueryFileLayoutInput>;
  Output: IMemory<PQueryFileLayoutOutput>;
  i, j, k: Integer;
  FileEntry: PFileLayoutEntry;
  NameEntry: PFileLayoutNameEntry;
  StreamEntry: PStreamLayoutEntry;
  ExtentEntry: PStreamExtentEntry;
  InfoEntry: PFileLayoutInfoEntry;
  StreamInfo: PStreamInformationEntry;
begin
  IMemory(Input) := Auto.AllocateDynamic(SizeOf(TQueryFileLayoutInput) +
    SizeOf(TFileReferenceRange) * Pred(Length(FileIds)));

  Input.Data.FilterEntryCount := Length(FileIds);
  Input.Data.Flags := Flags or QUERY_FILE_LAYOUT_RESTART;
  Input.Data.FilterType := QUERY_FILE_LAYOUT_FILTER_TYPE_FILEID;

  // Record all file IDs to query
  for i := 0 to High(FileIds) do
  begin
    Input.Data.FileReferenceRanges{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}
      .StartingFileReferenceNumber := FileIds[i];
    Input.Data.FileReferenceRanges{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}
      .EndingFileReferenceNumber := FileIds[i];
  end;

  // Issue the FSCTL
  Result := NtxFsControlFileEx(hxVolume, FSCTL_QUERY_FILE_LAYOUT,
    IMemory(Output), INITIAL_SIZE, nil, Input.Data, Input.Size);

  if not Result.IsSuccess then
    Exit;

  Entries := nil;
  SetLength(Entries, Output.Data.FileEntryCount);
  FileEntry := Output.Offset(Output.Data.FirstFileOffset);

  for i := 0 to High(Entries) do
  begin
    Entries[i].Flags := FileEntry.Flags;
    Entries[i].FileAttributes := FileEntry.FileAttributes;
    Entries[i].FileReferenceNumber := FileEntry.FileReferenceNumber;

    // Collect names
    if FileEntry.FirstNameOffset <> 0 then
    begin
      // Count names
      j := 1;
      NameEntry := Pointer(PByte(FileEntry) + FileEntry.FirstNameOffset);

      while NameEntry.NextNameOffset <> 0 do
      begin
        Inc(j);
        Inc(PByte(NameEntry), NameEntry.NextNameOffset);
      end;

      // Save names
      SetLength(Entries[i].Names, j);
      NameEntry := Pointer(PByte(FileEntry) + FileEntry.FirstNameOffset);

      for j := 0 to High(Entries[i].Names) do
      begin
        Entries[i].Names[j].Flags := NameEntry.Flags;
        Entries[i].Names[j].ParentFileReferenceNumber :=
          NameEntry.ParentFileReferenceNumber;
        SetString(Entries[i].Names[j].FileName, PWideChar(@NameEntry.FileName),
          NameEntry.FileNameLength div SizeOf(WideChar));

        // Move to the next name
        Inc(PByte(NameEntry), NameEntry.NextNameOffset);
      end;
    end;

    // Collect steams
    if FileEntry.FirstStreamOffset <> 0 then
    begin
      j := 1;
      StreamEntry := Pointer(PByte(FileEntry) + FileEntry.FirstStreamOffset);

      while StreamEntry.NextStreamOffset <> 0 do
      begin
        Inc(j);
        Inc(PByte(StreamEntry), StreamEntry.NextStreamOffset);
      end;

      // Save streams
      SetLength(Entries[i].Streams, j);
      StreamEntry := Pointer(PByte(FileEntry) + FileEntry.FirstStreamOffset);

      for j := 0 to High(Entries[i].Streams) do
      begin
        Entries[i].Streams[j].Flags := StreamEntry.Flags;
        Entries[i].Streams[j].AllocationSize := StreamEntry.AllocationSize;
        Entries[i].Streams[j].EndOfFile := StreamEntry.EndOfFile;
        Entries[i].Streams[j].AttributeTypeCode := StreamEntry.AttributeTypeCode;
        Entries[i].Streams[j].AttributeFlags := StreamEntry.AttributeFlags;

        SetString(Entries[i].Streams[j].StreamIdentifier,
          PWideChar(@StreamEntry.StreamIdentifier),
          StreamEntry.StreamIdentifierLength div SizeOf(WideChar));

        // Collect stream extents
        if StreamEntry.ExtentInformationOffset <> 0 then
        begin
          ExtentEntry := Pointer(PByte(StreamEntry) +
            StreamEntry.ExtentInformationOffset);

          Entries[i].Streams[j].ExtentsFlags := ExtentEntry.Flags;
          Entries[i].Streams[j].ExtentsStartingVcn :=
            ExtentEntry.RetrievalPointers.StartingVcn;

          SetLength(Entries[i].Streams[j].Extents,
            ExtentEntry.RetrievalPointers.ExtentCount);

          for k := 0 to High(Entries[i].Streams[j].Extents) do
            Entries[i].Streams[j].Extents[k] := ExtentEntry.RetrievalPointers
              .Extents{$R-}[k]{$IFDEF R+}{$R+}{$ENDIF};
        end;

        // Collect extended stream information
        if StreamEntry.StreamInformationOffset <> 0 then
        begin
          StreamInfo := Pointer(PByte(StreamEntry) +
            StreamEntry.StreamInformationOffset);

          case StreamEntry.AttributeTypeCode of
            ATTRIBUTE_TYPE_CODE_DATA:
              begin
                // Collect information about the data attribute
                Entries[i].Streams[j].ExtraInfo.InfoType := siData;
                Entries[i].Streams[j].ExtraInfo.DataFlags :=
                  StreamInfo.Data.Flags;
                Entries[i].Streams[j].ExtraInfo.ValidDataLength :=
                  StreamInfo.Data.Vdl;

                // Copy the resident data
                if StreamInfo.Data.Length >=
                  UIntPtr(@PStreamInformationEntry(nil).Data.Data) then
                  Entries[i].Streams[j].ExtraInfo.Data := Auto.CopyDynamic(
                    @StreamInfo.Data.Data, StreamInfo.Data.Length -
                    UIntPtr(@PStreamInformationEntry(nil).Data.Data))
                else
                  Entries[i].Streams[j].ExtraInfo.Data :=
                    Auto.AllocateDynamic(0);
              end;

            ATTRIBUTE_TYPE_CODE_REPARSE_POINT:
              begin
                // Collect information about the reparse point
                Entries[i].Streams[j].ExtraInfo.InfoType := siReparsePoint;
                Entries[i].Streams[j].ExtraInfo.ReparseFlags :=
                  StreamInfo.ReparsePoint.Flags;

                IMemory(Entries[i].Streams[j].ExtraInfo.ReparseData) :=
                  Auto.CopyDynamic(PByte(StreamInfo) +
                  StreamInfo.ReparsePoint.ReparseDataOffset,
                  StreamInfo.ReparsePoint.ReparseDataSize);
              end;

            ATTRIBUTE_TYPE_CODE_EA:
              begin
                // Collect the list of extended attributes
                Entries[i].Streams[j].ExtraInfo.InfoType := siExtendedAttribute;
                Entries[i].Streams[j].ExtraInfo.EaFlags :=
                  StreamInfo.ExtendedAttribute.Flags;

                Entries[i].Streams[j].ExtraInfo.EAs :=
                  RtlxCaptureFullEaInformation(Pointer(PByte(StreamInfo) +
                  StreamInfo.ExtendedAttribute.EaInformationOffset));
              end;

            ATTRIBUTE_TYPE_CODE_LOGGED_UTILITY_STREAM:
              if Entries[i].Streams[j].StreamIdentifier = ':$DSC' then
              begin
                // Collect desired storage class information
                Entries[i].Streams[j].ExtraInfo.InfoType := siDesiredStorageClass;
                Entries[i].Streams[j].ExtraInfo.DesiredStorageClass :=
                  StreamInfo.DesiredStorageClass;
              end;
          end;
        end;

        // Move to the next stream
        Inc(PByte(StreamEntry), StreamEntry.NextStreamOffset);
      end;
    end;

    // Copy extra file information
    if FileEntry.ExtraInfoOffset <> 0 then
    begin
      InfoEntry := Pointer(PByte(FileEntry) + FileEntry.ExtraInfoOffset);

      // The number of available fields depends on the OS version
      if RtlOsVersionAtLeast(OsWin10RS5) then
        Entries[i].Info := InfoEntry^
      else
        Move(InfoEntry^, Entries[i].Info, UIntPtr(@PFileLayoutInfoEntry(nil)
          .StorageReserveId));

      Entries[i].InfoValid := True;
    end;

    // Move to the next file
    Inc(PByte(FileEntry), FileEntry.NextFileOffset);
  end;
end;

function NtxQueryLayoutFile;
var
  Entries: TArray<TNtxFileLayoutEntry>;
begin
  Result := NtxQueryLayoutFiles(hxVolume, [FileId], Entries, Flags);

  if not Result.IsSuccess then
    Exit;

  if Length(Entries) < 1 then
  begin
    Result.Location := 'NtxQueryLayoutFile';
    Result.Status := STATUS_END_OF_FILE;
    Exit;
  end;

  Entry := Entries[0];
end;

end.
