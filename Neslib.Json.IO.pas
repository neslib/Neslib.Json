unit Neslib.Json.IO;
{< Classes for reading and writing JSON. }

{$INCLUDE 'Neslib.inc'}

interface

uses
  System.Classes,
  System.SysUtils;

type
  {$IFDEF JSON_UTF8}
  JsonChar = UTF8Char;
  PJsonChar = PUTF8Char;
  JsonString = UTF8String;
  {$ELSE}
  JsonChar = WideChar;
  PJsonChar = PWideChar;
  JsonString = String;
  {$ENDIF}

type
  { The current state of an IJsonReader. }
  TJsonReaderState = (
    { The end of the JSON stream has been reached. }
    EndOfStream,

    { The reader is positioned at a Null value. }
    Null,

    { The reader is positioned at a Boolean value. }
    Boolean,

    { The reader is positioned at an ordinal value. }
    Ordinal,

    { The reader is positioned at a floating-point value. }
    Float,

    { The reader is positioned at a string value. }
    &String,

    { The reader is positioned at the name of a name/value pair in a dictionary. }
    Name,

    { The reader is positioned at the start of an array. }
    StartArray,

    { The reader is positioned at the end of an array. }
    EndArray,

    { The reader is positioned at the start of a dictionary. }
    StartDictionary,

    { The reader is positioned at the end of a dictionary. }
    EndDictionary);

type
  { Exception type that is raised on parsing errors. }
  EJsonParserError = class(Exception)
  {$REGION 'Internal Declarations'}
  private
    FLineNumber: Integer;
    FColumnNumber: Integer;
    FPosition: Integer;
  public
    constructor Create(const AMsg: String; const ALineNumber,
      AColumnNumber, APosition: Integer);
  {$ENDREGION 'Internal Declarations'}
  public
    { The line number of the error in the source text, starting at 1. }
    property LineNumber: Integer read FLineNumber;

    { The column number of the error in the source text, starting at 1. }
    property ColumnNumber: Integer read FColumnNumber;

    { The position of the error in the source text, starting at 0.
      The position is the offset (in characters) from the beginning of the
      text. }
    property Position: Integer read FPosition;
  end;

type
  { Interface for reading data in JSON format.
    Implemented in TJsonReader. }
  IJsonReader = interface
  ['{05F6A53B-9773-4047-99B0-4332C7C287CD}']
    { Reads the next piece of data from the JSON stream.

      Parameters:
        AState: is set to the current state of the reader. That is, it indicates
          at what kind of value the reader is currently positioned. Depending
          on AState, you use one of the Read* methods to read the actual
          value.

      Returns:
        True if more data is available, or False if the end of the stream has
        been reached.

      Raises:
        EJsonParserError if the JSON data is invalid. }
    function Next(out AState: TJsonReaderState): Boolean;

    { Reads a Null value from the stream.
      You should call this method if the AState parameter of the Next method
      is set to Null.

      Raises:
        EJsonParserError if the reader is not positioned at a Null value. }
    procedure ReadNull;

    { Reads a Boolean value from the stream.
      You should call this method if the AState parameter of the Next method
      is set to Boolean.

      Returns:
        The read value.

      Raises:
        EJsonParserError if the reader is not positioned at a Boolean value. }
    function ReadBoolean: Boolean;

    { Reads an ordinal value from the stream.
      You should call this method if the AState parameter of the Next method
      is set to Ordinal.

      Returns:
        The read value.

      Raises:
        EJsonParserError if the reader is not positioned at an ordinal value. }
    function ReadOrdinal: Int64;

    { Reads a floating-point value from the stream.
      You should call this method if the AState parameter of the Next method
      is set to Float.

      Returns:
        The read value.

      Raises:
        EJsonParserError if the reader is not positioned at a floating-point
        value. }
    function ReadFloat: Double;

    { Reads a string value from the stream.
      You should call this method if the AState parameter of the Next method
      is set to String.

      Returns:
        The read value.

      Raises:
        EJsonParserError if the reader is not positioned at a string value.

      NOTE: Do NOT use this method to read dictionary names. Use ReadName
      instead. }
    function ReadString: JsonString;

    { Reads a dictionary name from the stream.
      You should call this method if the AState parameter of the Next method
      is set to Name.

      Returns:
        The read dictionary name.

      Raises:
        EJsonParserError if the reader is not positioned at a dictionary name. }
    function ReadName: JsonString;

    { Consumes the "start array" token ([) from the stream.
      You should call this method if the AState parameter of the Next method
      is set to StartArray.

      Raises:
        EJsonParserError if the reader is not positioned at the start of an
        array. }
    procedure ReadStartArray;

    { Consumes the "end array" token (]) from the stream.
      You should call this method if the AState parameter of the Next method
      is set to EndArray.

      Raises:
        EJsonParserError if the reader is not positioned at the end of an
        array. }
    procedure ReadEndArray;

    (*Consumes the "start dictionary" token ({) from the stream.
      You should call this method if the AState parameter of the Next method
      is set to StartDictionary.

      Raises:
        EJsonParserError if the reader is not positioned at the start of a
        dictionary.*)
    procedure ReadStartDictionary;

    (*Consumes the "end dictionary" token (}) from the stream.
      You should call this method if the AState parameter of the Next method
      is set to EndDictionary.

      Raises:
        EJsonParserError if the reader is not positioned at the end of a
        dictionary.*)
    procedure ReadEndDictionary;
  end;

type
  { Interface for writing data in JSON format.
    Implemented in TJsonWriter. }
  IJsonWriter = interface
  ['{B94DDA07-B67A-4C75-B3F7-FFD0BC788404}']
    { Writes a Null value. }
    procedure WriteNull;

    { Writes a Boolean value.

      Parameters:
        AValue: the value to write. }
    procedure WriteBoolean(const AValue: Boolean);

    { Writes an ordinal value.

      Parameters:
        AValue: the value to write. }
    procedure WriteOrdinal(const AValue: Int64);

    { Writes a floating-point value.

      Parameters:
        AValue: the value to write. }
    procedure WriteFloat(const AValue: Double);

    { Writes a string value.

      Parameters:
        AValue: the value to write.

      NOTE: Do NOT use this method to write dictionary names. Use WriteName
      instead. }
    procedure WriteString(const AValue: JsonString);

    { Writes a dictionary name.

      Parameters:
        AValue: the dictionary name to write. }
    procedure WriteName(const AName: JsonString);

    { Writes a "start array" token ([) }
    procedure WriteStartArray;

    { Writes an "end array" token (]) }
    procedure WriteEndArray;

    (* Writes a "start dictionary" token ({) *)
    procedure WriteStartDictionary;

    (* Writes an "end dictionary" token (}) *)
    procedure WriteEndDictionary;

    { Returns the written data in JSON format. }
    function ToJson: JsonString;
  end;

type
  { Class for reading data in JSON format.
    Implements IJsonReader. }
  TJsonReader = class(TInterfacedObject, IJsonReader)
  {$REGION 'Internal Declarations'}
  private type
    TState = (TopLevel, &Array, DictionaryName, DictionaryValue);
  private type
    PContext = ^TContext;
    TContext = record
    public
      State: TState;
      HasElements: Boolean;
    public
      procedure Init(const AState: TState); inline;
    end;
  {$IFDEF JSON_STRING_INTERNING}
  private type
    TInternedStrings = record
    private const
      EMPTY_HASH = -1;
    private type
      TItem = record
        HashCode: Integer;
        Str: JsonString;
      end;
    private
      FItems: TArray<TItem>;
      FCount: Integer;
      FGrowThreshold: Integer;
    private
      procedure Resize(ANewSize: Integer);
    public
      function Intern(const AStr: JsonString): JsonString;
    end;
  private
    FInternedStrings: TInternedStrings;
  {$ENDIF !JSON_STRING_INTERNING}
  private
    FJson: JsonString;
    FBuffer: PJsonChar;
    FCurrent: PJsonChar;
    FLineStart: PJsonChar;
    FLineNumber: Integer;
    FContextStack: TArray<TContext>;
    FContextIndex: Integer;
    FOrdValue: Int64;
    FFloatValue: Double;
    FStringValue: JsonString;
    FContext: PContext;
    FState: TJsonReaderState;
    FBoolValue: Boolean;
  private
    procedure PushContext(const AState: TState);
    procedure PopContext;
    function ParseError(const AMsg: PResStringRec): EJsonParserError; overload;
    function ParseError(const AMsg: String): EJsonParserError; overload;
    procedure SkipWhitespace;
    function ParseNumber: TJsonReaderState;
    procedure ParseString;
    procedure ParseUnquotedString;
    procedure ParseEscapedString(const AStart, ACur: PJsonChar);
  private
    class function IsDelimiter(const AChar: JsonChar): Boolean; static; inline;
  protected
    { IJsonReader }
    function Next(out AState: TJsonReaderState): Boolean;
    procedure ReadNull;
    function ReadBoolean: Boolean;
    function ReadOrdinal: Int64;
    function ReadFloat: Double;
    function ReadString: JsonString;
    function ReadName: JsonString;
    procedure ReadStartArray;
    procedure ReadEndArray;
    procedure ReadStartDictionary;
    procedure ReadEndDictionary;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a reader using a JSON formatted string to parse.

      Parameters:
        AJson: the JSON string to parse. }
    constructor Create(const AJson: JsonString);

    { Creates a reader from a file.

      Parameters:
        AFilename: the name of the file to load.

      Returns:
        The reader. }
    class function Load(const AFilename: String): IJsonReader; overload; static;

    { Creates a reader from a stream.

      Parameters:
        AStream: the stream to load.

      Returns:
        The reader. }
    class function Load(const AStream: TStream): IJsonReader; overload; static;
  end;

type
  { Class for writing data in JSON format.
    Implements IJsonWriter. }
  TJsonWriter = class(TInterfacedObject, IJsonWriter)
  {$REGION 'Internal Declarations'}
  private type
    TState = (TopLevel, &Array, Dictionary);
  private type
    PContext = ^TContext;
    TContext = record
    public
      Indent: Integer;
      State: TState;
      HasElements: Boolean;
    public
      procedure Init(const AParent: PContext; const AState: TState;
        const AIndent: Integer); inline;
    end;
  private
    FBuffer: PByte;
    FSize: Integer;
    FCapacity: Integer;
    FContextStack: TArray<TContext>;
    FContextIndex: Integer;
    FContext: PContext;
    FIndent: Integer;
    FIndentation: TArray<JsonChar>;
    FName: JsonString;
    FLineBreak: JsonChar;
  private
    procedure PushContext(const AState: TState; const AIndent: Integer);
    procedure PopContext;
    procedure WriteStartValue;
    procedure WriteQuotedString(const AValue: JsonString); inline;
    procedure WriteEscapedString(const AValue: JsonString);
  private
    procedure Append(const AValue; const ASize: Integer); overload;
    procedure Append(const AValue: JsonString); overload; inline;
    procedure Append(const AValue: JsonChar); overload; inline;
    procedure Append(const AValue: Int64); overload; inline;
  protected
    procedure WriteNull;
    procedure WriteBoolean(const AValue: Boolean);
    procedure WriteOrdinal(const AValue: Int64);
    procedure WriteFloat(const AValue: Double);
    procedure WriteString(const AValue: JsonString);
    procedure WriteName(const AName: JsonString);
    procedure WriteStartArray;
    procedure WriteEndArray;
    procedure WriteStartDictionary;
    procedure WriteEndDictionary;

    function ToJson: JsonString;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a new writer.

      Parameters:
        AIndent: flag indicating whether you want indented (or pretty-printed)
          output. If True, nested values will be indented and line breaks will
          be inserted. If False, then no line breaks and indentation will be
          used. }
    constructor Create(const AIndent: Boolean);

    { Destructor }
    destructor Destroy; override;
  end;

resourcestring
  RS_JSON_UNEXPECTED_EOF          = 'Unexpected end of JSON data.';
  RS_JSON_UNEXPECTED_CHARACTER    = 'Unexpected character in JSON data.';
  RS_JSON_UNEXPECTED_COMMA        = 'Unexpected comma in JSON data.';
  RS_JSON_INVALID_STATE           = 'JSON reader called in invalid state.';
  RS_JSON_INVALID_NUMBER          = 'Invalid number in JSON data.';
  RS_JSON_INVALID_STRING          = 'Invalid character JSON string.';
  RS_JSON_CLOSE_BRACKET_EXPECTED  = 'Close bracket ("]") expected in JSON data.';
  RS_JSON_CLOSE_BRACE_EXPECTED    = 'Curly close brace ("}") expected in JSON data.';
  RS_JSON_DUPLICATE_COMMA         = 'Duplicate comma (",") in JSON data.';
  RS_JSON_COMMA_EXPECTED          = 'Comma (",") expected in JSON data.';
  RS_JSON_COLON_EXPECTED          = 'Colon (":") expected in JSON data.';
  RS_JSON_NAME_EXPECTED           = 'Dictionary name expected in JSON data.';
  RS_JSON_ILLEGAL_UNQUOTED_STRING = 'Unquoted string in JSON data only valid for dictionary names.';
  RS_JSON_INVALID_CODEPOINT       = 'Invalid Unicode codepoint in JSON string.';

{$REGION 'Internal Declarations'}
const
  _FLAG_DELIMITER    = $80; // Whitespace, ',', ':', '"', '{', '}', '[', ']'

const
  _CHAR_BITS: array [#0..#127] of Byte = (
    $8F, $80, $80, $80, $80, $80, $80, $80,  // #$00-#$07
    $80, $80, $80, $80, $80, $80, $80, $80,  // #$08-#$0F
    $80, $80, $80, $80, $80, $80, $80, $80,  // #$10-#$17
    $80, $80, $80, $80, $80, $80, $80, $80,  // #$18-#$1F
    $80, $00, $85, $00, $07, $00, $00, $00,  //  !"#$%&'
    $00, $00, $00, $00, $88, $06, $06, $00,  // ()*+,-./
    $06, $06, $06, $06, $06, $06, $06, $06,  // 01234567
    $06, $06, $80, $00, $00, $00, $00, $00,  // 89:;<=>?
    $00, $07, $07, $07, $07, $07, $07, $07,  // @ABCDEFG
    $07, $07, $07, $07, $07, $07, $07, $07,  // HIJKLMNO
    $07, $07, $07, $07, $07, $07, $07, $07,  // PQRSTUVW
    $07, $07, $07, $83, $00, $84, $00, $07,  // XYZ[\]^_
    $00, $07, $07, $07, $07, $07, $07, $07,  // `abcdefg
    $07, $07, $07, $07, $07, $07, $07, $07,  // hijklmno
    $07, $07, $07, $07, $07, $07, $07, $07,  // pqrstuvw
    $07, $07, $07, $81, $00, $82, $00, $00); // xyz{|}~
{$ENDREGION 'Internal Declarations'}

implementation

uses
  System.Math,
  Neslib.Utf8,
  Neslib.SysUtils,
  Neslib.Hash;

const
  // Character tokens and flags
  TOKEN_INVALID     = $00; // #0
  TOKEN_START_DICT  = $01; // '{'
  TOKEN_END_DICT    = $02; // '}'
  TOKEN_START_ARRAY = $03; // '['
  TOKEN_END_ARRAY   = $04; // ']'
  TOKEN_STRING      = $05; // '"'
  TOKEN_NUMBER      = $06; // '0'-'9', '-', '.'
  TOKEN_IDENTIFIER  = $07; // '_', '$', 'a'..'z', 'A'..'Z'
  TOKEN_COMMA       = $08; // ','
  TOKEN_EOF         = $0F;
  TOKEN_MASK        = $0F;

type
  TCharBuffer = record
  private const
    SIZE = 256;
  private type
    TBuffer = array [0..SIZE - 1] of JsonChar;
    PBuffer = ^TBuffer;
  private
    FStatic: TBuffer;
    FDynamic: PBuffer;
    FCurrent: PJsonChar;
    FCurrentEnd: PJsonChar;
    FDynamicCount: Integer;
  public
    procedure Initialize; inline;
    procedure Release; inline;
    procedure Append(const AChar: JsonChar); inline;
    function ToString: JsonString; inline;
  end;

procedure TCharBuffer.Append(const AChar: JsonChar);
begin
  if (FCurrent < FCurrentEnd) then
  begin
    FCurrent^ := AChar;
    Inc(FCurrent);
    Exit;
  end;

  ReallocMem(FDynamic, (FDynamicCount + 1) * SizeOf(TBuffer));
  FCurrent := PJsonChar(FDynamic) + (FDynamicCount * SIZE);
  FCurrentEnd := FCurrent + SIZE;
  Inc(FDynamicCount);

  FCurrent^ := AChar;
  Inc(FCurrent);
end;

function TCharBuffer.ToString: JsonString;
var
  I, StrIndex, TrailingLength: Integer;
  Src: PBuffer;
  Start: PJsonChar;
begin
  if (FDynamic = nil) then
  begin
    Start := @FStatic;
    SetString(Result, Start, FCurrent - Start);
    Exit;
  end;

  TrailingLength := SIZE - (FCurrentEnd - FCurrent);
  SetLength(Result, (FDynamicCount * SIZE) + TrailingLength);
  Move(FStatic, Result[Low(JsonString)], SizeOf(TBuffer));
  StrIndex := Low(JsonString) + SIZE;

  Src := FDynamic;
  for I := 0 to FDynamicCount - 2 do
  begin
    Move(Src^, Result[StrIndex], SizeOf(TBuffer));
    Inc(Src);
    Inc(StrIndex, SIZE);
  end;

  Move(Src^, Result[StrIndex], TrailingLength * SizeOf(JsonChar));
end;

procedure TCharBuffer.Initialize;
begin
  FDynamic := nil;
  FCurrent := @FStatic;
  FCurrentEnd := FCurrent + SIZE;
  FDynamicCount := 0;
end;

procedure TCharBuffer.Release;
begin
  FreeMem(FDynamic);
end;

{ EJsonParserError }

constructor EJsonParserError.Create(const AMsg: String; const ALineNumber,
  AColumnNumber, APosition: Integer);
begin
  inherited CreateFmt('(%d:%d) %s', [ALineNumber, AColumnNumber, AMsg]);
  FLineNumber := ALineNumber;
  FColumnNumber := AColumnNumber;
  FPosition := APosition;
end;

{ TJsonReader }

constructor TJsonReader.Create(const AJson: JsonString);
begin
  inherited Create;
  FJson := AJson;
  FBuffer := PJsonChar(AJson);
  FCurrent := FBuffer;
  FLineStart := FBuffer;
  FLineNumber := 1;
  FContextIndex := -1;
  PushContext(TState.TopLevel);
end;

class function TJsonReader.IsDelimiter(const AChar: JsonChar): Boolean;
begin
  Result := (AChar < #$80) and ((_CHAR_BITS[AChar] and _FLAG_DELIMITER) <> 0);
end;

class function TJsonReader.Load(const AFilename: String): IJsonReader;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyWrite);
  try
    Result := Load(Stream);
  finally
    Stream.Free;
  end;
end;

class function TJsonReader.Load(const AStream: TStream): IJsonReader;
{$IFDEF JSON_UTF8}
var
  Json: JsonString;
begin
  if (AStream = nil) then
    Exit(nil);

  SetLength(Json, AStream.Size);
  if (Json <> '') then
    AStream.ReadBuffer(Json[Low(JsonString)], Length(Json));
{$ELSE}
var
  Bytes: TBytes;
  Json: JsonString;
begin
  if (AStream = nil) then
    Exit(nil);

  SetLength(Bytes, AStream.Size);
  if (Bytes <> nil) then
  begin
    AStream.ReadBuffer(Bytes, Length(Bytes));
    Json := Utf8ToUtf16(@Bytes[0], Length(Bytes));
  end;
{$ENDIF}

  Result := TJsonReader.Create(Json);
end;

function TJsonReader.Next(out AState: TJsonReaderState): Boolean;
var
  C: JsonChar;
  HasComma, NeedComma: Boolean;
begin
  Result := True;
  HasComma := False;

  Assert(Assigned(FContext));
  NeedComma := (FContext.State <> TState.TopLevel) and (FContext.HasElements);

  if (FContext.State = TState.DictionaryValue) then
  begin
    SkipWhitespace;
    if (FCurrent^ <> ':' ) then
      raise ParseError(@RS_JSON_COLON_EXPECTED);

    NeedComma := False;
    Inc(FCurrent);
  end;

  SkipWhitespace;
  C := FCurrent^;
  while True do
  begin
    case (_CHAR_BITS[C] and TOKEN_MASK) of
      TOKEN_EOF:
        begin
          if (FContextIndex > 0) then
            raise ParseError(@RS_JSON_UNEXPECTED_EOF);

          FState := TJsonReaderState.EndOfStream;
          Result := False;
          Break;
        end;

      TOKEN_START_DICT:
        begin
          if (NeedComma) then
            raise ParseError(@RS_JSON_COMMA_EXPECTED);

          if (FContext.State = TState.DictionaryName) then
            raise ParseError(@RS_JSON_NAME_EXPECTED);

          FState := TJsonReaderState.StartDictionary;
          Inc(FCurrent);
          Break;
        end;

      TOKEN_END_DICT:
        begin
          if (FContext.State <> TState.DictionaryName) then
            raise ParseError(@RS_JSON_UNEXPECTED_CHARACTER);

          FState := TJsonReaderState.EndDictionary;
          Inc(FCurrent);
          Break;
        end;

      TOKEN_START_ARRAY:
        begin
          if (NeedComma) then
            raise ParseError(@RS_JSON_COMMA_EXPECTED);

          if (FContext.State = TState.DictionaryName) then
            raise ParseError(@RS_JSON_NAME_EXPECTED);

          FState := TJsonReaderState.StartArray;
          Inc(FCurrent);
          Break;
        end;

      TOKEN_END_ARRAY:
        begin
          if (FContext.State <> TState.&Array) then
            raise ParseError(@RS_JSON_UNEXPECTED_CHARACTER);

          FState := TJsonReaderState.EndArray;
          Inc(FCurrent);
          Break;
        end;

      TOKEN_STRING:
        begin
          if (NeedComma) then
            raise ParseError(@RS_JSON_COMMA_EXPECTED);

          if (FContext.State = TState.DictionaryName) then
            FState := TJsonReaderState.Name
          else
            FState := TJsonReaderState.String;

          ParseString;
          Break;
        end;

      TOKEN_NUMBER:
        begin
          if (NeedComma) then
            raise ParseError(@RS_JSON_COMMA_EXPECTED);

          if (FContext.State = TState.DictionaryName) then
            raise ParseError(@RS_JSON_NAME_EXPECTED);

          FState := ParseNumber;
          Break;
        end;

      TOKEN_IDENTIFIER:
        begin
          if (NeedComma) then
            raise ParseError(@RS_JSON_COMMA_EXPECTED);

          FState := TJsonReaderState.Name;
          case C of
            'I': if (FCurrent[1] = 'n') and (FCurrent[2] = 'f')
                    and (FCurrent[3] = 'i') and (FCurrent[4] = 'n')
                    and (FCurrent[5] = 'i') and (FCurrent[6] = 't')
                    and (FCurrent[7] = 'y') and IsDelimiter(FCurrent[8]) then
                 begin
                   FState := TJsonReaderState.Float;
                   FFloatValue := Infinity;
                   Inc(FCurrent, 8);
                 end;

            'N': if (FCurrent[1] = 'a') and (FCurrent[2] = 'N')
                   and IsDelimiter(FCurrent[3]) then
                 begin
                   FState := TJsonReaderState.Float;
                   FFloatValue := NaN;
                   Inc(FCurrent, 3);
                 end;

            'f': if (FCurrent[1] = 'a') and (FCurrent[2] = 'l')
                    and (FCurrent[3] = 's') and (FCurrent[4] = 'e')
                    and IsDelimiter(FCurrent[5]) then
                 begin
                   FState := TJsonReaderState.Boolean;
                   FBoolValue := False;
                   Inc(FCurrent, 5);
                 end;

            'n': if (FCurrent[1] = 'u') and (FCurrent[2] = 'l')
                   and (FCurrent[3] = 'l') and IsDelimiter(FCurrent[4]) then
                 begin
                   FState := TJsonReaderState.Null;
                   Inc(FCurrent, 4);
                 end;

            't': if (FCurrent[1] = 'r') and (FCurrent[2] = 'u')
                   and (FCurrent[3] = 'e') and IsDelimiter(FCurrent[4]) then
                 begin
                   FState := TJsonReaderState.Boolean;
                   FBoolValue := True;
                   Inc(FCurrent, 4);
                 end;
          end;

          if (FState = TJsonReaderState.Name) then
          begin
            if (FContext.State <> TState.DictionaryName) then
              raise ParseError(@RS_JSON_ILLEGAL_UNQUOTED_STRING);

            ParseUnquotedString;
          end;

          Break;
        end;

      TOKEN_COMMA:
        begin
          if (HasComma) then
            raise ParseError(@RS_JSON_DUPLICATE_COMMA);

          if (not NeedComma) then
            raise ParseError(@RS_JSON_UNEXPECTED_COMMA);

          Inc(FCurrent);
          HasComma := True;
          NeedComma := False;
          SkipWhitespace;
          C := FCurrent^;
        end
    else
      raise ParseError(@RS_JSON_UNEXPECTED_CHARACTER);
    end;
  end;
  AState := FState;
end;

function TJsonReader.ParseError(const AMsg: PResStringRec): EJsonParserError;
begin
  Result := ParseError(LoadResString(AMsg));
end;

function TJsonReader.ParseError(const AMsg: String): EJsonParserError;
var
  ColumnNumber, Position: Integer;
  TextStart: PJsonChar;
begin
  if (FCurrent = nil) then
  begin
    ColumnNumber := 1;
    Position := 0;
  end
  else
  begin
    TextStart := FBuffer;
    ColumnNumber := FCurrent - FLineStart + 1;
    Position := FCurrent - TextStart;
  end;
  Result := EJsonParserError.Create(AMsg, FLineNumber, ColumnNumber, Position);
end;

procedure TJsonReader.ParseEscapedString(const AStart, ACur: PJsonChar);
var
  Buf: TCharBuffer;
  Cur: PJsonChar;
  I: Integer;
  C: JsonChar;
  S: JsonString;
  {$IFDEF JSON_UTF8}
  Codepoint: UInt32;
  {$ENDIF}
begin
  {$IFDEF JSON_UTF8}
  Codepoint := 0;
  {$ENDIF}

  Cur := ACur;
  Buf.Initialize;
  try
    while True do
    begin
      C := Cur^;
      Inc(Cur);
      case C of
        #0:
          begin
            FCurrent := Cur;
            raise ParseError(@RS_JSON_INVALID_STRING);
          end;

        '\':
          begin
            C := Cur^;
            Inc(Cur);
            case C of
              '"', '\', '/': Buf.Append(C);
              'b': Buf.Append(#8);
              't': Buf.Append(#9);
              'n': Buf.Append(#10);
              'f': Buf.Append(#12);
              'r': Buf.Append(#13);
              'u': begin
                     FCurrent := Cur;
                     SetLength(S, 5);
                     S[Low(JsonString) + 0] := '$';

                     if (Cur^ = #0) then
                       raise ParseError(@RS_JSON_INVALID_STRING);
                     S[Low(JsonString) + 1] := Cur^;
                     Inc(Cur);

                     if (Cur^ = #0) then
                       raise ParseError(@RS_JSON_INVALID_STRING);
                     S[Low(JsonString) + 2] := Cur^;
                     Inc(Cur);

                     if (Cur^ = #0) then
                       raise ParseError(@RS_JSON_INVALID_STRING);
                     S[Low(JsonString) + 3] := Cur^;
                     Inc(Cur);

                     if (Cur^ = #0) then
                       raise ParseError(@RS_JSON_INVALID_STRING);
                     S[Low(JsonString) + 4] := Cur^;
                     Inc(Cur);

                     I := StrToIntDef(S, -1);
                     if (I < 0) then
                       raise ParseError(@RS_JSON_INVALID_CODEPOINT);

                     {$IFDEF JSON_UTF8}
                     if (I < $80) then
                       Buf.Append(JsonChar(I))
                     else if (I < $800) then
                     begin
                       Buf.Append(JsonChar($C0 or (I shr 6)));
                       Buf.Append(JsonChar($80 or (I and $3F)));
                     end
                     else if (I >= $D800) and (I <= $DBFF) then
                       { High Surrogate. Should be followed by Low Surrogate. }
                       Codepoint := I shl 10
                     else if (I >= $DC00) and (I <= $DFFF) then
                     begin
                       { Low Surrogate. High Surrogate should have been parsed
                         already. }
                       Inc(Codepoint, I - $35FDC00);
                       Buf.Append(JsonChar($F0 or (Codepoint shr 18)));
                       Buf.Append(JsonChar($80 or ((Codepoint shr 12) and $3F)));
                       Buf.Append(JsonChar($80 or ((Codepoint shr 6) and $3F)));
                       Buf.Append(JsonChar($80 or (Codepoint and $3F)));
                     end
                     else
                     begin
                       Buf.Append(JsonChar($E0 or (I shr 12)));
                       Buf.Append(JsonChar($80 or ((I shr 6) and $3F)));
                       Buf.Append(JsonChar($80 or (I and $3F)));
                     end;
                     {$ELSE}
                     Buf.Append(JsonChar(I));
                     {$ENDIF}
                   end;
            else
              FCurrent := Cur - 1;
              raise ParseError(@RS_JSON_INVALID_STRING);
            end;
          end;

        '"':
          begin
            SetString(FStringValue, AStart, ACur - AStart);
            FStringValue := FStringValue + Buf.ToString;
            FCurrent := Cur;
            Exit;
          end;
      else
        Buf.Append(C);
      end;
    end;
  finally
    Buf.Release;
  end;
end;

function TJsonReader.ParseNumber: TJsonReaderState;
{ Lexical grammar:
    NumberLiteral: ['-'] DecimalLiteral
    DecimalLiteral: 'Infinity'
                  | ['.'] DecimalDigits [ExponentPart]
                  | DecimalDigits '.' [DecimalDigits] [ExponentPart]
    DecimalDigits: ('0'..'9')+
    ExponentPart: ('e' | 'E') ['+' | '-'] DecimalDigits

  There are 3 special values: Infinity, -Infinity and NaN.
  The values Infinity and NaN are handled elsewhere (in Next), so here we only
  need to handle -Infinity.

  Note that, in contrast with the original specification, we allow numbers that
  start with a '.' and the 3 special values. }
var
  Power, Exponent: Integer;
  IntegerPart: Int64;
  Value: Double;
  Cur: PJsonChar;
  C: JsonChar;
  IsNegative, IsNegativeExponent: Boolean;
begin
  Cur := FCurrent;

  { NumberLiteral: ['-'] DecimalLiteral }
  IntegerPart := 0;
  IsNegative := False;
  if (Cur^ = '-') then
  begin
    IsNegative := True;
    Inc(Cur);
    if (Cur^ = 'I') then
    begin
      { DecimalLiteral: 'Infinity' }
      if (Cur[1] = 'n') and (Cur[2] = 'f') and (Cur[3] = 'i') and (Cur[4] = 'n')
        and (Cur[5] = 'i') and (Cur[6] = 't') and (Cur[7] = 'y')
        and IsDelimiter(Cur[8]) then
      begin
        FCurrent := Cur + 8;
        FFloatValue := NegInfinity;
        Exit(TJsonReaderState.Float);
      end
      else
        raise ParseError(@RS_JSON_INVALID_NUMBER);
    end;
  end;

  { Parse integer part (before optional '.') }
  while True do
  begin
    C := Cur^;
    if (C >= '0') and (C <= '9') then
    begin
      IntegerPart := (IntegerPart * 10) + (Ord(C) - Ord('0'));
      Inc(Cur);
    end
    else
      Break;
  end;

  if IsDelimiter(C) then
  begin
    { Ordinal value. }
    FCurrent := Cur;

    if (IsNegative) then
      IntegerPart := -IntegerPart;

    FOrdValue := IntegerPart;
    Exit(TJsonReaderState.Ordinal);
  end;

  { Floating-point value }
  Value := IntegerPart;
  Power := 0;

  if (C = '.') then
  begin
    { Parse fractional part }
    Inc(Cur);
    C := Cur^;

    { Fractional part must start with a digit... }
    if (C >= '0') and (C <= '9') then
    begin
      Value := (Value * 10.0) + (Ord(C) - Ord('0'));
      Inc(Cur);
      Dec(Power);
    end
    else
      raise ParseError(@RS_JSON_INVALID_NUMBER);

    { ...followed by some more optional digits }
    while True do
    begin
      C := Cur^;
      if (C >= '0') and (C <= '9') then
      begin
        Value := (Value * 10.0) + (Ord(C) - Ord('0'));
        Inc(Cur);
        Dec(Power);
      end
      else
        Break;
    end;
  end;

  if (C = 'e') or (C = 'E') then
  begin
    { Parse exponent }
    Inc(Cur);
    Exponent := 0;
    C := Cur^;
    IsNegativeExponent := False;
    if (C = '-') then
    begin
      IsNegativeExponent := True;
      Inc(Cur);
      C := Cur^;
    end
    else if (C = '+') then
    begin
      Inc(Cur);
      C := Cur^;
    end;

    { Exponent must start with a digit... }
    if (C >= '0') and (C <= '9') then
    begin
      Exponent := (Exponent * 10) + (Ord(C) - Ord('0'));
      Inc(Cur);
    end
    else
      raise ParseError(@RS_JSON_INVALID_NUMBER);

    { ...followed by some more optional digits }
    while True do
    begin
      C := Cur^;
      if (C >= '0') and (C <= '9') then
      begin
        Exponent := (Exponent * 10) + (Ord(C) - Ord('0'));
        Inc(Cur);
      end
      else
        Break;
    end;

    if (IsNegativeExponent) then
      Exponent := -Exponent;

    Inc(Power, Exponent);
  end;

  if IsDelimiter(C) then
  begin
    FCurrent := Cur;
    Value := Power10(Value, Power);
    if (IsNegative) then
      Value := -Value;
    FFloatValue := Value;
    Exit(TJsonReaderState.Float);
  end;

  raise ParseError(@RS_JSON_INVALID_NUMBER);
end;

procedure TJsonReader.ParseString;
var
  Cur, Start: PJsonChar;
begin
  Cur := FCurrent + 1; // Skip '"'
  Start := Cur;

  while True do
  begin
    case Cur^ of
      #0:
        begin
          FCurrent := Cur;
          raise ParseError(@RS_JSON_INVALID_STRING);
        end;

      '\':
        begin
          ParseEscapedString(Start, Cur);
          Exit;
        end;

      '"':
        begin
          SetString(FStringValue, Start, Cur - Start);

          {$IFDEF JSON_STRING_INTERNING}
          if (FState = TJsonReaderState.Name) then
            FStringValue := FInternedStrings.Intern(FStringValue);
          {$ENDIF}

          FCurrent := Cur + 1;
          Exit;
        end;
    end;
    Inc(Cur);
  end;
end;

procedure TJsonReader.ParseUnquotedString;
var
  Cur, Start: PJsonChar;
begin
  Cur := FCurrent;
  Start := Cur;

  while (not IsDelimiter(Cur^)) do
    Inc(Cur);

  SetString(FStringValue, Start, Cur - Start);

  {$IFDEF JSON_STRING_INTERNING}
  FStringValue := FInternedStrings.Intern(FStringValue);
  {$ENDIF}

  FCurrent := Cur;
end;

procedure TJsonReader.PopContext;
begin
  Dec(FContextIndex);
  if (FContextIndex < 0) then
    raise ParseError(@RS_JSON_INVALID_STATE);

  FContext := @FContextStack[FContextIndex];
end;

procedure TJsonReader.PushContext(const AState: TState);
begin
  Inc(FContextIndex);
  if (FContextIndex >= Length(FContextStack)) then
    SetLength(FContextStack, FContextIndex + 8);

  FContextStack[FContextIndex].Init(AState);
  FContext := @FContextStack[FContextIndex];
end;

function TJsonReader.ReadBoolean: Boolean;
begin
  if (FState <> TJsonReaderState.Boolean) then
    raise ParseError(@RS_JSON_INVALID_STATE);

  Assert(Assigned(FContext));
  FContext.HasElements := True;

  if (FContext.State = TState.DictionaryValue) then
    FContext.State := TState.DictionaryName;

  // Value has already been parsed
  Result := FBoolValue;
end;

procedure TJsonReader.ReadEndArray;
begin
  if (FState <> TJsonReaderState.EndArray) then
    raise ParseError(@RS_JSON_INVALID_STATE);

  Assert(Assigned(FContext));
  if (FContext.State <> TState.&Array) then
    raise ParseError(@RS_JSON_CLOSE_BRACKET_EXPECTED);

  PopContext;

  if (FContext.State = TState.DictionaryValue) then
    FContext.State := TState.DictionaryName;

  // ']' has already been consumed
  SkipWhitespace;
end;

procedure TJsonReader.ReadEndDictionary;
begin
  if (FState <> TJsonReaderState.EndDictionary) then
    raise ParseError(@RS_JSON_INVALID_STATE);

  Assert(Assigned(FContext));
  if (FContext.State <> TState.DictionaryName) then
    raise ParseError(@RS_JSON_CLOSE_BRACE_EXPECTED);

  PopContext;

  if (FContext.State = TState.DictionaryValue) then
    FContext.State := TState.DictionaryName;

  // '}' has already been consumed
  SkipWhitespace;
end;

function TJsonReader.ReadFloat: Double;
begin
  if (FState <> TJsonReaderState.Float) then
    raise ParseError(@RS_JSON_INVALID_STATE);

  Assert(Assigned(FContext));
  FContext.HasElements := True;

  if (FContext.State = TState.DictionaryValue) then
    FContext.State := TState.DictionaryName;

  // Number has already been parsed
  Result := FFloatValue;
end;

function TJsonReader.ReadName: JsonString;
begin
  if (FState <> TJsonReaderState.Name) then
    raise ParseError(@RS_JSON_INVALID_STATE);

  Assert(Assigned(FContext));
  FContext.State := TState.DictionaryValue;
  FContext.HasElements := True;

  // Name has already been parsed
  Result := FStringValue;
end;

procedure TJsonReader.ReadNull;
begin
  if (FState <> TJsonReaderState.Null) then
    raise ParseError(@RS_JSON_INVALID_STATE);

  Assert(Assigned(FContext));
  FContext.HasElements := True;

  if (FContext.State = TState.DictionaryValue) then
    FContext.State := TState.DictionaryName;

  // Value has already been parsed
end;

function TJsonReader.ReadOrdinal: Int64;
begin
  if (FState <> TJsonReaderState.Ordinal) then
    raise ParseError(@RS_JSON_INVALID_STATE);

  Assert(Assigned(FContext));
  FContext.HasElements := True;

  if (FContext.State = TState.DictionaryValue) then
    FContext.State := TState.DictionaryName;

  // Number has already been parsed
  Result := FOrdValue;
end;

procedure TJsonReader.ReadStartArray;
begin
  if (FState <> TJsonReaderState.StartArray) then
    raise ParseError(@RS_JSON_INVALID_STATE);

  Assert(Assigned(FContext));
  FContext.HasElements := True;
  PushContext(TState.&Array);

  // '[' has already been consumed
  SkipWhitespace;
end;

procedure TJsonReader.ReadStartDictionary;
begin
  if (FState <> TJsonReaderState.StartDictionary) then
    raise ParseError(@RS_JSON_INVALID_STATE);

  Assert(Assigned(FContext));
  FContext.HasElements := True;
  PushContext(TState.DictionaryName);

  // '{' has already been consumed
  SkipWhitespace;
end;

function TJsonReader.ReadString: JsonString;
begin
  if (FState <> TJsonReaderState.String) then
    raise ParseError(@RS_JSON_INVALID_STATE);

  Assert(Assigned(FContext));
  FContext.HasElements := True;

  if (FContext.State = TState.DictionaryValue) then
    FContext.State := TState.DictionaryName;

  // Name has already been parsed
  Result := FStringValue;
end;

procedure TJsonReader.SkipWhitespace;
var
  Cur: PJsonChar;
  C: JsonChar;
begin
  Cur := FCurrent;
  C := Cur^;
  while (C <> #0) and (C <= ' ') do
  begin
    Inc(Cur);
    if (C = #10) then
    begin
      Inc(FLineNumber);
      FLineStart := Cur;
    end;
    C := Cur^;
  end;
  FCurrent := Cur;
end;

{ TJsonReader.TContext }

procedure TJsonReader.TContext.Init(const AState: TState);
begin
  State := AState;
  HasElements := False;
end;

{$IFDEF JSON_STRING_INTERNING}

{ TJsonReader.TInternedStrings }

function TJsonReader.TInternedStrings.Intern(const AStr: JsonString): JsonString;
var
  Mask, Index, HashCode, HC: Integer;
begin
  if (FCount >= FGrowThreshold) then
    Resize(Length(FItems) * 2);

  HashCode := MurmurHash2(AStr[Low(JsonString)], Length(AStr) * SizeOf(JsonChar));
  Mask := Length(FItems) - 1;
  Index := HashCode and Mask;

  while True do
  begin
    HC := FItems[Index].HashCode;
    if (HC = EMPTY_HASH) then
      Break;

    if (HC = HashCode) and (FItems[Index].Str = AStr) then
      Exit(FItems[Index].Str);

    Index := (Index + 1) and Mask;
  end;

  FItems[Index].HashCode := HashCode;
  FItems[Index].Str := AStr;
  Inc(FCount);
  Result := AStr;
end;

procedure TJsonReader.TInternedStrings.Resize(ANewSize: Integer);
var
  NewMask, I, NewIndex: Integer;
  OldItems, NewItems: TArray<TItem>;
begin
  if (ANewSize < 4) then
    ANewSize := 4;
  NewMask := ANewSize - 1;
  SetLength(NewItems, ANewSize);
  for I := 0 to ANewSize - 1 do
    NewItems[I].HashCode := EMPTY_HASH;
  OldItems := FItems;

  for I := 0 to Length(OldItems) - 1 do
  begin
    if (OldItems[I].HashCode <> EMPTY_HASH) then
    begin
      NewIndex := OldItems[I].HashCode and NewMask;
      while (NewItems[NewIndex].HashCode <> EMPTY_HASH) do
        NewIndex := (NewIndex + 1) and NewMask;
      NewItems[NewIndex] := OldItems[I];
    end;
  end;

  FItems := NewItems;
  FGrowThreshold := (ANewSize * 3) shr 2; // 75%
end;

{$ENDIF !JSON_STRING_INTERNING}

{ TJsonWriter }

procedure TJsonWriter.Append(const AValue: JsonString);
begin
  if (AValue <> '') then
    Append(AValue[Low(JsonString)], Length(AValue) * SizeOf(JsonChar));
end;

procedure TJsonWriter.Append(const AValue: JsonChar);
begin
  Append(AValue, SizeOf(JsonChar));
end;

procedure TJsonWriter.Append(const AValue; const ASize: Integer);
begin
  if ((FSize + ASize) > FCapacity) then
  begin
    repeat
      FCapacity := FCapacity shl 1;
    until (FCapacity >= (FSize + ASize));
    ReallocMem(FBuffer, FCapacity);
  end;
  Move(AValue, FBuffer[FSize], ASize);
  Inc(FSize, ASize);
end;

procedure TJsonWriter.Append(const AValue: Int64);
begin
  {$IFDEF JSON_UTF8}
  Append(IntToUtf8Str(AValue));
  {$ELSE}
  Append(IntToStr(AValue));
  {$ENDIF}
end;

constructor TJsonWriter.Create(const AIndent: Boolean);
begin
  inherited Create;
  FLineBreak := ' ';
  if (AIndent) then
  begin
    FLineBreak := #10;
    FIndent := 2;
  end;

  GetMem(FBuffer, 512);
  FCapacity := 512;

  FContextIndex := -1;
  PushContext(TState.TopLevel, 0);
end;

destructor TJsonWriter.Destroy;
begin
  FreeMem(FBuffer);
  inherited;
end;

procedure TJsonWriter.PopContext;
begin
  Dec(FContextIndex);
  if (FContextIndex < 0) then
  begin
    FContext := nil;
    FContextIndex := -1;
  end
  else
    FContext := @FContextStack[FContextIndex];
end;

procedure TJsonWriter.PushContext(const AState: TState; const AIndent: Integer);
var
  ParentContext: PContext;
  I, OrigLen: Integer;
begin
  Inc(FContextIndex);
  if (FContextIndex >= Length(FContextStack)) then
    SetLength(FContextStack, FContextIndex + 8);

  if (FContextIndex > 0) then
    ParentContext := @FContextStack[FContextIndex - 1]
  else
    ParentContext := nil;

  FContextStack[FContextIndex].Init(ParentContext, AState, AIndent);
  FContext := @FContextStack[FContextIndex];

  OrigLen := Length(FIndentation);
  if (FContext.Indent > OrigLen) then
  begin
    SetLength(FIndentation, OrigLen + 16);
    for I := OrigLen to Length(FIndentation) - 1 do
      FIndentation[I] := ' ';
  end;
end;

function TJsonWriter.ToJson: JsonString;
begin
  SetString(Result, PJsonChar(FBuffer), FSize div SizeOf(JsonChar));
end;

procedure TJsonWriter.WriteBoolean(const AValue: Boolean);
begin
  WriteStartValue;
  if (AValue) then
    Append('true')
  else
    Append('false');
end;

procedure TJsonWriter.WriteEndArray;
begin
  Append(']');
  PopContext;
end;

procedure TJsonWriter.WriteEndDictionary;
begin
  Assert(Assigned(FContext));
  if (FIndent <> 0) and (FContext.HasElements) then
  begin
    Append(#10);
    if (FContextIndex > 0) then
      Append(FIndentation[0], FContextStack[FContextIndex - 1].Indent * SizeOf(JsonChar));
    Append('}');
  end
  else
    Append(' }');

  PopContext;
end;

procedure TJsonWriter.WriteEscapedString(const AValue: JsonString);
var
  P, PEnd: PJsonChar;
  C: JsonChar;
  {$IFDEF JSON_UTF8}
  Codepoint: UInt32;
  {$ENDIF}
begin
  P := PJsonChar(AValue);
  PEnd := P + Length(AValue);
  while (P < PEnd) do
  begin
    C := P^;
    case C of
      '"', '\':
        begin
          Append('\');
          Append(C);
        end;

       #8: Append('\b');
       #9: Append('\t');
      #10: Append('\n');
      #12: Append('\f');
      #13: Append('\r');
    else
      {$IFDEF JSON_UTF8}
      if (C < ' ') then
      begin
        Append('\u');
        Append(LowerCase(IntToUtf8Hex(Ord(C), 4)));
      end
      else
      if (C >= #$80) then
      begin
        Append('\u');
        Codepoint := Ord(C);

        { Start of 2, 3 or 4-byte UTF8 sequence }
        if ((Codepoint shr 5) = $06) and ((P + 1) < PEnd) then
        begin
          Inc(P);
          Codepoint := ((Codepoint shl 6) and $7FF) + (Ord(P^) and $3F);
          Append(LowerCase(IntToUtf8Hex(Codepoint, 4)));
        end
        else if ((Codepoint shr 4) = $0E) and ((P + 2) < PEnd) then
        begin
          Inc(P);
          Codepoint := ((Codepoint shl 12) and $FFFF) + ((Ord(P^) shl 6) and $FFF);
          Inc(P);
          Inc(Codepoint, Ord(P^) and $3F);

          Assert(Codepoint <= $FFFF);
          Append(LowerCase(IntToUtf8Hex(Codepoint, 4)));
        end else if ((P + 3) < PEnd) then
        begin
          { Surrogate pair }
          Assert((Codepoint shr 3) = $1E);
          Inc(P);
          Codepoint := ((Codepoint shl 18) and $1FFFFF) + ((Ord(P^) shl 12) and $3FFFF);
          Inc(P);
          Inc(Codepoint, (Ord(P^) shl 6) and $FFF);
          Inc(P);
          Inc(Codepoint, Ord(P^) and $3F);

          Assert(Codepoint > $FFFF);
          Append(LowerCase(IntToUtf8Hex($D7C0 + (Codepoint shr 10), 4)));
          Append(LowerCase(IntToUtf8Hex($DC00 + (Codepoint and $3FF), 4)));
        end;
      end
      {$ELSE}
      if (C < ' ') or (C >= #$0080) then
      begin
        Append('\u');
        Append(LowerCase(IntToHex(Ord(C), 4)));
      end
      {$ENDIF}
      else
        Append(C);
    end;
    Inc(P);
  end;
end;

procedure TJsonWriter.WriteFloat(const AValue: Double);
var
  S: JsonString;
  I: Int64;
begin
  WriteStartValue;

  {$IFDEF JSON_UTF8}
  S := FloatToUtf8Str(AValue, USFormatSettings);
  {$ELSE}
  S := FloatToStr(AValue, USFormatSettings);
  {$ENDIF}

  if (S = 'NAN') then
    S := 'NaN' // JSON compliant
  else if (S = 'INF') then
    S := 'Infinity'
  else if (S = '-INF') then
    S := '-Infinity'
  else if (TryStrToInt64(S, I)) then
    { If S looks like an integer, then add ".0" }
    S := S + '.0';

  Append(S);
end;

procedure TJsonWriter.WriteName(const AName: JsonString);
begin
  FName := AName;
end;

procedure TJsonWriter.WriteNull;
begin
  WriteStartValue;
  Append('null');
end;

procedure TJsonWriter.WriteOrdinal(const AValue: Int64);
begin
  WriteStartValue;
  Append(AValue);
end;

procedure TJsonWriter.WriteQuotedString(const AValue: JsonString);
begin
  Append('"');
  WriteEscapedString(AValue);
  Append('"');
end;

procedure TJsonWriter.WriteStartArray;
begin
  WriteStartValue;
  Append('[');
  PushContext(TState.&Array, FIndent);
end;

procedure TJsonWriter.WriteStartDictionary;
begin
  WriteStartValue;
  Append('{');
  PushContext(TState.Dictionary, FIndent);
end;

procedure TJsonWriter.WriteStartValue;
begin
  Assert(Assigned(FContext));
  case FContext.State of
    TState.TopLevel:
      ;

    TState.&Array:
      begin
        if (FContext.HasElements) then
          Append(', ');
      end;

    TState.Dictionary:
      begin
        if (FContext.HasElements) then
          Append(',');

        Append(FLineBreak);
        Append(FIndentation[0], FContext.Indent * SizeOf(JsonChar));
        WriteQuotedString(FName);
        Append(' : ');
      end;
  else
    Assert(False);
  end;

  FContext.HasElements := True;
end;

procedure TJsonWriter.WriteString(const AValue: JsonString);
begin
  WriteStartValue;
  WriteQuotedString(AValue);
end;

{ TJsonWriter.TContext }

procedure TJsonWriter.TContext.Init(const AParent: PContext;
  const AState: TState; const AIndent: Integer);
begin
  if Assigned(AParent) then
    Indent := AParent.Indent + AIndent
  else
    Indent := AIndent;
  State := AState;
  HasElements := False;
end;

end.
