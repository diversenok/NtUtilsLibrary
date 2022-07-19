unit NtUtils.XmlLite;

interface

uses
  Ntapi.WinNt, Ntapi.ObjIdl, Ntapi.xmllite, NtUtils, DelphiApi.Reflection;

type
  TXmlxNode = record
    NodeType: TXmlNodeType;
    Depth: Cardinal;
    IsEmpty: LongBool;
    QualifiedName: String;
    LocalName: String;
    Prefix: String;
    NamespaceUri: String;
  end;

  TXmlxFilter = reference to function (const Node: TXmlxNode): Boolean;

  IXmlxReader = interface
    // Iterators: while Reader.MoveToNext.Save(Result) do {...}
    function MoveToNext: TNtxStatus;
    function MoveToNextAttribute: TNtxStatus;

    // Node state
    function GetParents: TArray<TXmlxNode>;
    function GetCurrent: TXmlxNode;
    function GetValue(out Value: String): TNtxStatus;
    function GetBaseUri(out BaseUri: String): TNtxStatus;
    function GetAttributeCount(out AttributeCount: Cardinal): TNtxStatus;
    function GetLineNumber(out LineNumber: Cardinal): TNtxStatus;
    function GetLinePosition(out LinePosition: Cardinal): TNtxStatus;
    function IsEOF: LongBool;
    function IsDefault: LongBool;
    property Parents: TArray<TXmlxNode> read GetParents;
    property Current: TXmlxNode read GetCurrent;

    // Checks if the hierary of nodes up to the current one matches the filters.
    // The current node is considered matching when each of its parents and the
    // node itself satisfy the corresponding filters. I.e., the parent at depth
    // 0 satisfies the filter #0, a parent on depth 1 satisfies the filter #1,
    // and so on.
    function Matches(const Hierarchy: TArray<TXmlxFilter>): Boolean;
  end;

{ Reader creation }

// Start reading an XML from a stream
function XmlxCreateReader(
  out Reader: IXmlxReader;
  const Input: IStream
): TNtxStatus;

// Start reading an XML from a file
function XmlxCreateReaderOnFile(
  out Reader: IXmlxReader;
  [Access(GENERIC_READ)] const FileName: String
): TNtxStatus;

{ Built-in filters }

function ByLocalName(const LocalName: String): TXmlxFilter;
function ByQualifiedName(const QualifiedName: String): TXmlxFilter;

implementation

uses
  Ntapi.ntstatus, Ntapi.Shlwapi, Ntapi.ntioapi, NtUtils.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  IXmlxReaderWrapper = class (TInterfacedObject, IXmlxReader)
  private
    FReader: IXmlReader;
    FNodeStack: TArray<TXmlxNode>;
    function SaveNodeData: TNtxStatus;
  public
    constructor Create(const Reader: IXmlReader);
    function MoveToNext: TNtxStatus;
    function MoveToNextAttribute: TNtxStatus;
    function GetParents: TArray<TXmlxNode>;
    function GetCurrent: TXmlxNode;
    function GetValue(out Value: String): TNtxStatus;
    function GetBaseUri(out BaseUri: String): TNtxStatus;
    function GetAttributeCount(out AttributeCount: Cardinal): TNtxStatus;
    function GetLineNumber(out LineNumber: Cardinal): TNtxStatus;
    function GetLinePosition(out LinePosition: Cardinal): TNtxStatus;
    function IsEOF: LongBool;
    function IsDefault: LongBool;
    function Matches(const Hierarchy: TArray<TXmlxFilter>): Boolean;
  end;

{ IXmlxReaderWrapper }

constructor IXmlxReaderWrapper.Create;
begin
  inherited Create;
  FReader := Reader;
end;

function IXmlxReaderWrapper.GetAttributeCount;
begin
  Result.Location := 'IXmlReader::GetAttributeCount';
  Result.HResult := FReader.GetAttributeCount(AttributeCount)
end;

function IXmlxReaderWrapper.GetBaseUri;
var
  Buffer: PWideChar;
  BufferLength: Cardinal;
begin
  Result.Location := 'IXmlReader::GetBaseUri';
  Result.HResult := FReader.GetBaseUri(Buffer, @BufferLength);

  if Result.IsSuccess then
    SetString(BaseUri, Buffer, BufferLength);
end;

function IXmlxReaderWrapper.GetCurrent;
begin
  if Length(FNodeStack) > 0 then
    Result := FNodeStack[High(FNodeStack)]
  else
    Result := Default(TXmlxNode);
end;

function IXmlxReaderWrapper.GetLineNumber;
begin
  Result.Location := 'IXmlReader::GetLineNumber';
  Result.HResult := FReader.GetLineNumber(LineNumber);
end;

function IXmlxReaderWrapper.GetLinePosition;
begin
  Result.Location := 'IXmlReader::GetLinePosition';
  Result.HResult := FReader.GetLinePosition(LinePosition);
end;

function IXmlxReaderWrapper.GetParents;
begin
  // Copy all items except for the last
  Result := Copy(FNodeStack, 0, Length(FNodeStack) - 1);
end;

function IXmlxReaderWrapper.GetValue;
var
  Buffer: PWideChar;
  BufferLength: Cardinal;
begin
  Result.Location := 'IXmlReader::GetValue';
  Result.HResult := FReader.GetValue(Buffer, @BufferLength);

  if Result.IsSuccess then
    SetString(Value, Buffer, BufferLength);
end;

function IXmlxReaderWrapper.IsDefault;
begin
  Result := FReader.IsDefault;
end;

function IXmlxReaderWrapper.IsEOF;
begin
  Result := FReader.IsEOF;
end;

function IXmlxReaderWrapper.Matches;
var
  i: Integer;
begin
  Result := False;

  // Check if the depth is right
  if Length(FNodeStack) <> Length(Hierarchy) then
    Exit;

  // Check all nodes starting from the root
  for i := 0 to High(Hierarchy) do
    if Assigned(Hierarchy[i]) and not Hierarchy[i](FNodeStack[i]) then
      Exit;

  // All tests passed, that's a match
  Result := True;
end;

function IXmlxReaderWrapper.MoveToNext;
var
  NextNodeType: TXmlNodeType;
begin
  // Advance the reader skipping attributes
  Result.Location := 'IXmlReader::Read';
  Result.HResultAllowFalse := FReader.Read(NextNodeType);

  if Result.HResult = S_FALSE then
    Result.Status := STATUS_NO_MORE_ENTRIES;

  // Save the new node on the stack
  if Result.IsSuccess then
    Result := SaveNodeData;
end;

function IXmlxReaderWrapper.MoveToNextAttribute;
begin
  // Advance the reader considering attributes
  Result.Location := 'IXmlReader::MoveToNextAttribute';
  Result.HResultAllowFalse := FReader.MoveToNextAttribute;

  if Result.HResult = S_FALSE then
    Result.Status := STATUS_NO_MORE_ENTRIES;

  // Save the new node on the stack
  if Result.IsSuccess then
    Result := SaveNodeData;
end;

function IXmlxReaderWrapper.SaveNodeData;
var
  Node: TXmlxNode;
  Buffer: PWideChar;
  BufferLength: Cardinal;
begin
  Node.IsEmpty := FReader.IsEmptyElement;

  // Save node type
  Result.Location := 'IXmlReader::GetNodeType';
  Result.HResult := FReader.GetNodeType(Node.NodeType);

  if not Result.IsSuccess then
    Exit;

  // Save depth
  Result.Location := 'IXmlReader::GetDepth';
  Result.HResult := FReader.GetDepth(Node.Depth);

  if not Result.IsSuccess then
    Exit;

  // Save qualified name
  Result.Location := 'IXmlReader::GetQualifiedName';
  Result.HResult := FReader.GetQualifiedName(Buffer, @BufferLength);

  if not Result.IsSuccess then
    Exit;

  SetString(Node.QualifiedName, Buffer, BufferLength);

  // Save local name
  Result.Location := 'IXmlReader::GetLocalName';
  Result.HResult := FReader.GetLocalName(Buffer, @BufferLength);

  if not Result.IsSuccess then
    Exit;

  SetString(Node.LocalName, Buffer, BufferLength);

  // Save prefix
  Result.Location := 'IXmlReader::GetPrefix';
  Result.HResult := FReader.GetPrefix(Buffer, @BufferLength);

  if not Result.IsSuccess then
    Exit;

  SetString(Node.Prefix, Buffer, BufferLength);

  // Save namespace URI
  Result.Location := 'IXmlReader::GetNamespaceUri';
  Result.HResult := FReader.GetNamespaceUri(Buffer, @BufferLength);

  if not Result.IsSuccess then
    Exit;

  SetString(Node.NamespaceUri, Buffer, BufferLength);

  // Update the node stack. Depending on the new depth, we will either truncate
  // by one and replace the last, replace the last, or append.
  SetLength(FNodeStack, Node.Depth + 1);
  FNodeStack[Node.Depth] := Node;
end;

{ Creation functions }

function XmlxCreateReader;
var
  ReaderRaw: IXmlReader;
begin
  Result.Location := 'CreateXmlReader';
  Result.HResult := CreateXmlReader(IXmlReader, ReaderRaw, nil);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IXmlReader::SetInput';
  Result.HResult := ReaderRaw.SetInput(Input);

  if Result.IsSuccess then
    Reader := IXmlxReaderWrapper.Create(ReaderRaw);
end;

function XmlxCreateReaderOnFile;
var
  Stream: IStream;
begin
  Result.Location := 'SHCreateStreamOnFileEx';
  Result.LastCall.OpensForAccess<TIoFileAccessMask>(GENERIC_READ);
  Result.HResult := SHCreateStreamOnFileEx(PWideChar(FileName), STGM_READ, 0,
    False, nil, Stream);

  if Result.IsSuccess then
    Result := XmlxCreateReader(Reader, Stream);
end;

{ Filters }

function ByLocalName;
begin
  Result := function (const Node: TXmlxNode): Boolean
    begin
      Result := RtlxEqualStrings(Node.LocalName, LocalName);
    end;
end;

function ByQualifiedName;
begin
  Result := function (const Node: TXmlxNode): Boolean
    begin
      Result := RtlxEqualStrings(Node.QualifiedName, QualifiedName);
    end;
end;

end.
