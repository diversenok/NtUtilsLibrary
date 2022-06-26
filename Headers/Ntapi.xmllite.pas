unit Ntapi.xmllite;

{
  This module provides definitions for parsing and generating XML using
  xmllite.dll
}

interface

{$MINENUMSIZE 4}

uses
  DelphiApi.Reflection;

const
   xmllite = 'xmllite.dll';

type
  IXmlReaderInput = IUnknown;
  IXmlWriterOutput = IUnknown;

  [SDKName('XmlNodeType')]
  [NamingStyle(nsCamelCase, 'XmlNodeType_')]
  TXmlNodeType = (
    XmlNodeType_None = 0,
    XmlNodeType_Element = 1,
    XmlNodeType_Attribute = 2,
    XmlNodeType_Text = 3,
    XmlNodeType_CDATA = 4,
    XmlNodeType_ProcessingInstruction = 7,
    XmlNodeType_Comment = 8,
    XmlNodeType_DocumentType = 10,
    XmlNodeType_Whitespace = 13,
    XmlNodeType_EndElement = 15,
    XmlNodeType_XmlDeclaration = 17
  );

  [SDKName('XmlConformanceLevel')]
  [NamingStyle(nsCamelCase, 'XmlConformanceLevel_')]
  TXmlConformanceLevel = (
    XmlConformanceLevel_Auto = 0,
    XmlConformanceLevel_Fragment = 1,
    XmlConformanceLevel_Document = 2
  );

  [SDKName('DtdProcessing')]
  [NamingStyle(nsCamelCase, 'DtdProcessing_')]
  TDtdProcessing = (
    DtdProcessing_Prohibit = 0,
    DtdProcessing_Parse = 1
  );

  [SDKName('XmlReadState')]
  [NamingStyle(nsCamelCase, 'XmlReadState_')]
  TXmlReadState = (
    XmlReadState_Initial = 0,
    XmlReadState_Interactive = 1,
    XmlReadState_Error = 2,
    XmlReadState_EndOfFile = 3,
    XmlReadState_Closed = 4
  );

  [SDKName('XmlReaderProperty')]
  [NamingStyle(nsCamelCase, 'XmlReaderProperty_')]
  TXmlReaderProperty = (
    XmlReaderProperty_MultiLanguage = 0,
    XmlReaderProperty_ConformanceLevel = 1,
    XmlReaderProperty_RandomAccess = 2,
    XmlReaderProperty_XmlResolver = 3,
    XmlReaderProperty_DtdProcessing = 4,
    XmlReaderProperty_ReadState = 5,
    XmlReaderProperty_MaxElementDepth = 6,
    XmlReaderProperty_MaxEntityExpansion = 7
  );

  [SDKName('XmlStandalone')]
  [NamingStyle(nsCamelCase, 'XmlStandalone_')]
  TXmlStandalone = (
    XmlStandalone_Omit = 0,
    XmlStandalone_Yes = 1,
    XmlStandalone_No = 2
  );

  [SDKName('XmlWriterProperty')]
  [NamingStyle(nsCamelCase, 'XmlWriterProperty_')]
  TXmlWriterProperty = (
    XmlWriterProperty_MultiLanguage = 0,
    XmlWriterProperty_Indent = 1,
    XmlWriterProperty_ByteOrderMark = 2,
    XmlWriterProperty_OmitXmlDeclaration = 3,
    XmlWriterProperty_ConformanceLevel = 4,
    XmlWriterProperty_CompactEmptyElement = 5
  );

  IXmlReader = interface (IUnknown)
  ['{7279FC81-709D-4095-B63D-69FE4B0D9030}']

    function SetInput(
      [opt] const Input: IUnknown
    ): HResult; stdcall;

    function GetProperty(
      nProperty: TXmlReaderProperty;
      out pValue: NativeUInt
    ): HResult; stdcall;

    function SetProperty(
      nProperty: TXmlReaderProperty;
      [opt] Value: NativeUInt
    ): HResult; stdcall;

    function Read(
      [opt] out NodeType: TXmlNodeType
    ): HResult; stdcall;

    function GetNodeType(
      out NodeType: TXmlNodeType
    ): HResult; stdcall;

    function MoveToFirstAttribute(
    ): HResult; stdcall;

    function MoveToNextAttribute(
    ): HResult; stdcall;

    function MoveToAttributeByName(
      [in] LocalName: PWideChar;
      [in, opt] NamespaceUri: PWideChar
    ): HResult; stdcall;

    function MoveToElement(
    ): HResult; stdcall;

    function GetQualifiedName(
      [allocates, MayReturnNil] out QualifiedName: PWideChar;
      [out, opt] pcwchQualifiedName: PCardinal
    ): HResult; stdcall;

    function GetNamespaceUri(
      [allocates, MayReturnNil] out NamespaceUri: PWideChar;
      [out, opt] pcwchNamespaceUri: PCardinal
    ): HResult; stdcall;

    function GetLocalName(
      [allocates, MayReturnNil] out LocalName: PWideChar;
      [out, opt] pcwchLocalName: PCardinal
    ): HResult; stdcall;

    function GetPrefix(
      [allocates, MayReturnNil] out Prefix: PWideChar;
      [out, opt] pcwchPrefix: PCardinal
    ): HResult; stdcall;

    function GetValue(
      [allocates, MayReturnNil] out Value: PWideChar;
      [out, opt] pcwchValue: PCardinal
    ): HResult; stdcall;

    function ReadValueChunk(
      [out] Buffer: PWideChar;
      cwchChunkSize: Cardinal;
      var cwchRead: Cardinal
    ): HResult; stdcall;

    function GetBaseUri(
      [allocates, MayReturnNil] out BaseUri: PWideChar;
      [out, opt] pcwchBaseUri: PCardinal
    ): HResult; stdcall;

    function IsDefault(
    ): LongBool; stdcall;

    function IsEmptyElement(
    ): LongBool; stdcall;

    function GetLineNumber(
      out nLineNumber: Cardinal
    ): HResult; stdcall;

    function GetLinePosition(
      out nLinePosition: Cardinal
    ): HResult; stdcall;

    function GetAttributeCount(
      out nAttributeCount: Cardinal
    ): HResult; stdcall;

    function GetDepth(
      out nDepth: Cardinal
    ): HResult; stdcall;

    function IsEOF(
    ): LongBool; stdcall;
  end;

  IXmlResolver = interface (IUnknown)
  ['{7279FC82-709D-4095-B63D-69FE4B0D9030}']
    function ResolveUri(
      [in, opt] BaseUri: PWideChar;
      [in, opt] PublicIdentifier: PWideChar;
      [in, opt] SystemIdentifier: PWideChar;
      out ResolvedInput: IUnknown
    ): HResult; stdcall;
  end;


  IXmlWriter = interface (IUnknown)
  ['{7279FC88-709D-4095-B63D-69FE4B0D9030}']

    function SetOutput(
      [opt] const Output: IUnknown
    ): HResult; stdcall;

    function GetProperty(
      nProperty: TXmlWriterProperty;
      out pValue: NativeUInt
    ): HResult; stdcall;

    function SetProperty(
      nProperty: TXmlWriterProperty;
      [opt] Value: NativeUInt
    ): HResult; stdcall;

    function WriteAttributes(
      const Reader: IXmlReader;
      WriteDefaultAttributes: LongBool
    ): HResult; stdcall;

    function WriteAttributeString(
      [in, opt] Prefix: PWideChar;
      [in, opt] LocalName: PWideChar;
      [in, opt] NamespaceUri: PWideChar;
      [in, opt] Value: PWideChar
    ): HResult; stdcall;

    function WriteCData(
      [in, opt] Text: PWideChar
    ): HResult; stdcall;


    function WriteCharEntity(
      wch: WideChar
    ): HResult; stdcall;

    function WriteChars(
      [in, opt] pwch: PWideChar;
      cwch: Cardinal
    ): HResult; stdcall;

    function WriteComment(
      [in, opt] Comment: PWideChar
    ): HResult; stdcall;

    function WriteDocType(
      [in, opt] Name: PWideChar;
      [in, opt] PublicId: PWideChar;
      [in, opt] SystemId: PWideChar;
      [in, opt] Subset: PWideChar
    ): HResult; stdcall;

  function WriteElementString(
      [in, opt] Prefix: PWideChar;
      [in] LocalName: PWideChar;
      [in, opt] NamespaceUri: PWideChar;
      [in, opt] Value: PWideChar
    ): HResult; stdcall;

    function WriteEndDocument(
    ): HResult; stdcall;

    function WriteEndElement(
    ): HResult; stdcall;

    function WriteEntityRef(
      [in] Name: PWideChar
    ): HResult; stdcall;

    function WriteFullEndElement(
    ): HResult; stdcall;

    function WriteName(
      [in] Name: PWideChar
    ): HResult; stdcall;

    function WriteNmToken(
      [in] NmToken: PWideChar
    ): HResult; stdcall;

    function WriteNode(
      const Reader: IXmlReader;
      WriteDefaultAttributes: LongBool
    ): HResult; stdcall;

    function WriteNodeShallow(
      const Reader: IXmlReader;
      WriteDefaultAttributes: LongBool
    ): HResult; stdcall;

    function WriteProcessingInstruction(
      [in] Name: PWideChar;
      [in, opt] Text: PWideChar
    ): HResult; stdcall;

    function WriteQualifiedName(
      [in] LocalName: PWideChar;
      [in, opt] NamespaceUri: PWideChar
    ): HResult; stdcall;

    function WriteRaw(
      [in, opt] Data: PWideChar
    ): HResult; stdcall;

    function WriteRawChars(
      [in, opt] pwch: PWideChar;
      cwch: Cardinal
    ): HResult; stdcall;

    function WriteStartDocument(
      standalone: TXmlStandalone
    ): HResult; stdcall;

    function WriteStartElement(
      [in, opt] Prefix: PWideChar;
      [in] LocalName: PWideChar;
      [in, opt] NamespaceUri: PWideChar
    ): HResult; stdcall;

    function WriteString(
      [in, opt] Text: PWideChar
    ): HResult; stdcall;

    function WriteSurrogateCharEntity(
      wchLow: WideChar;
      wchHigh: WideChar
    ): HResult; stdcall;

    function WriteWhitespace(
      [in, opt] Whitespace: PWideChar
    ): HResult; stdcall;

    function Flush(
    ): HResult; stdcall;
  end;

  // TODO: IMalloc
  IMalloc = IUnknown;

function CreateXmlReader(
  const riid: TGuid;
  out ReaderObject;
  [opt] const Malloc: IMalloc
): HResult; stdcall; external xmllite;

function CreateXmlReaderInputWithEncodingCodePage(
  const InputStream: IUnknown;
  [opt] const Malloc: IMalloc;
  nEncodingCodePage: Cardinal;
  EncodingHint: LongBool;
  [in, opt] BaseUri: PWideChar;
  out Input: IXmlReaderInput
): HResult; stdcall; external xmllite;

function CreateXmlReaderInputWithEncodingName(
  const InputStream: IUnknown;
  [opt] const Malloc: IMalloc;
  [in] EncodingName: PWideChar;
  EncodingHint: LongBool;
  [in, opt] BaseUri: PWideChar;
  out Input: IXmlReaderInput
): HResult; stdcall; external xmllite;

function CreateXmlWriter(
  const riid: TGuid;
  out WriterObject;
  [opt] const Malloc: IMalloc
): HResult; stdcall; external xmllite;

function CreateXmlWriterOutputWithEncodingCodePage(
  const OutputStream: IUnknown;
  [opt] const Malloc: IMalloc;
  EncodingCodePage: Cardinal;
  out Output: IXmlWriterOutput
): HResult; stdcall; external xmllite;

function CreateXmlWriterOutputWithEncodingName(
  const OutputStream: IUnknown;
  [opt] const Malloc: IMalloc;
  [in] EncodingName: PWideChar;
  out Output: IXmlWriterOutput
): HResult; stdcall; external xmllite;

implementation

end.
