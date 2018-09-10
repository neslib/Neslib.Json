unit Neslib.Json.Path;
(*< XPath-like query language for JSON. There is no official JSONPath
  specification, but the most widely used version seems to be one developed by
  Stefan Goessner:

    http://goessner.net/articles/JsonPath/

  @bold(About JSONPath)

  A JSONPath looks like:

    $.store.book[0].title

  or

    $['store']['book'][0]['title']

  Both representations are identical: you can use either dot (.) or bracket ([])
  notation to denote children of a dictionary. Brackets can also be used with
  numerical indices to denote children of an array by index.

  NOTE: JSONPath only uses single quotes (') within brackets. We also allow for
  double quotes (") since these are easier to use in Delphi strings.

  * Every path starts with a $ indicating the root, followed by zero or more
    child operators (. or []). A $ by itself matches the entire document.
  * A child name can be an identifier string or the asterisk (* or '*') wildcard
    to match all children. For example,
      $.store.book[*].author
    matches the authors of all books in the store.
  * In addition to a single dot (.), a double dot (..) can be used to search for
    any descendants instead of immediate children. For example,
      $..author
    matches all authors, regardless of depth. This is called recursive descent.
  * Children can also be accessed by one or more indices between brackets. These
    indices are 0-based and are only used with arrays. You can separate multiple
    indices with comma's. For example,
      $.store.book[0,2,3]
    matches the first, third and fourth books.
  * You can use the slice notation [Start:End:Step] to match a slice (range)
    of children. This matches all children from index Start up to (but not
    including) End, using a given Step size (usually 1). All are optional, but
    at least one value (and colon) must be given:
    * If Start is omitted, it is implied to be 0. A negative value indicates
      an offset from the end of the array.
    * If End is omitted, the slice extracts through the end of the array. A
      negative value indicates and offset from the end of the array.
    * If Step is omitted, is is implied to be 1.
    * Examples:
      * List[2:] matches the third and all following elements.
      * List[-2:] matches the last two elements.
      * List[:2] matches the first two elements.
      * List[:-2] matches all but the last two elements.
      * List[2:-2] matches all elements but the first two and last two.
      * List[-4:-2] matches the 3rd and 4rd elements from the end.
      * List[::2] matches all elements with an even index.

  NOTE: JSONPath also has an @ operator to allow custom script expressions. We
  do not support this operator.

  @Bold(Examples)

  Example document:

    { "store": {
        "book": [
          { "category": "reference",
            "author": "Nigel Rees",
            "title": "Sayings of the Century",
            "price": 8.95
          },
          { "category": "fiction",
            "author": "J. R. R. Tolkien",
            "title": "The Lord of the Rings",
            "isbn": "0-395-19395-8",
            "price": 22.99
          }
        ],
        "bicycle": {
          "color": "red",
          "price": 19.95
        }
      }
    }

  Example paths:

  $                       Matches the root document (a single value)
  $..*                    Matches all members in the document (lots of values)
  $.store.book[*].author  The authors of all books in the store
  $..author               All authors
  $.store.*               All things in store (2 books and a bicycle)
  $.store..price          The price of everything in the store
  $..book[2]              The third book
  $..book[-1:]            The last book in order
  $..book[:2]             The first two books

  @bold(JSONPath in Delphi)

  The JSONPath API is short and simple. It consists of a TJsonPath record with
  only a couple of methods.

  For one-off matching, use the static Match method:

    <source>
    var
      Doc: IJsonDocument;
      Matches: TArray<TJsonValue>;
    begin
      Doc := TJsonDocument.Load(...);
      Matches := TJsonPath.Match(Doc, '$.store.book[*].author');
    end;
    </source>

  If you plan to use the same path on multiple (sub)documents, then it is faster
  to parse the path once, and then apply it multiple times:

    <source>
    var
      Doc1, Doc2: IJsonDocument;
      Path: TJsonPath;
      Matches1, Matches2: TArray<TJsonValue>;
    begin
      Doc1 := TJsonDocument.Load(...);
      Doc2 := TJsonDocument.Load(...);

      Path := TJsonPath.Create('$.store.book[*].author');

      Matches1 := Path.Match(Doc1);
      Matches2 := Path.Match(Doc2);
    end;
    </source>

  You can also run the path on sub-trees:

    <source>
    var
      Doc: IJsonDocument;
      Store: TJsonValue;
      Matches: TArray<TJsonValue>;
    begin
      Doc := TJsonDocument.Load(...);
      Store := Doc.Root.Values['store'];
      Matches := TJsonPath.Match(Store, '$.book[*].author');
    end;
    </source>

  If you are only interested in a single (or the first) match, then you can use
  MatchSingle instead:

    <source>
    var
      Doc: IJsonDocument;
      Match: TJsonValue;
    begin
      Doc := TJsonDocument.Load(...);
      if (TJsonPath.MatchSingle(Store, '$.book[*]', Match)) then
        ...
    end;
    </source> *)

{$INCLUDE 'Neslib.inc'}

interface

uses
  System.SysUtils,
  Neslib.Json;

type
  { Exception type that is raised for invalid JSONPath expressions. }
  EJsonPathError = class(Exception);

type
  { Creating and executing JSONPath expressions. }
  TJsonPath = record
  {$REGION 'Internal Declarations'}
  private type
    TOperatorType = (
      ChildName,        // Name of a child element (as in .store or ['store'])
      ChildIndex,       // Index of a child element (as in [3])
      RecursiveDescent, // .. operator
      Wildcard,         // * operator
      IndexList,        // [a,b,c,...]
      Slice);           // [start:end:step]
  private type
    POperator = ^TOperator;
    TOperator = record
    public
      procedure Init(const AType: TOperatorType);
    public
      OperatorType: TOperatorType;
      Next: POperator;
      Name: JsonString;                  // For ChildName
      Indices: TArray<Integer>;          // For IndexList
      case Byte of
        0: (Index: Integer);             // For ChildIndex
        1: (Start, Stop, Step: Integer); // For Slice
    end;
  private
    FOperators: TArray<TOperator>;
    FOperatorCount: Integer;
    FMatches: TArray<TJsonValue>;
    FMatchCount: Integer;
    FSingleMatch: Boolean;
  private
    class procedure SkipWhitespace(var ACur: PJsonChar); inline; static;
    class function ParseInteger(var ACur: PJsonChar; out AValue: Integer): Boolean; static;
    class function IsQuote(const AChar: JsonChar): Boolean; inline; static;
  private
    procedure AddOperator(const AOperator: TOperator);
    procedure AddMatch(const AMatch: TJsonValue);
    procedure ParseDotOperator(var ACur: PJsonChar);
    procedure ParseBracketOperator(var ACur: PJsonChar);
    function Match(const ARoot: TJsonValue;
      const AMatchSingle: Boolean): TArray<TJsonValue>; overload;
    procedure VisitOperator(const AOp: POperator; const ARoot: TJsonValue);
  {$ENDREGION 'Internal Declarations'}
  public
    { Parses a JSONPath expression that can be used for matching later.

      Parameters:
        AExpression: the JSONPath expression to parse.

      Raises:
        EJsonPathError if AExpression is invalid.

      If you plan to use the same JSONPath expression multiple times, then it
      is faster to parse it just once using this constructor, and execute it
      multiple times using one of the (non-static) Match* methods. }
    constructor Create(const AExpression: JsonString);

    { Executes this JSONPath expression on a document.

      Parameters:
        ADoc: the document to use this JSONPath on.

      Returns:
        An array of JSON values that match this JSONPath expression. }
    function Match(const ADoc: IJsonDocument): TArray<TJsonValue>; overload; inline;

    { Executes this JSONPath expression on a JSON value.

      Parameters:
        ARoot: the root TJsonValue to use this JSONPath on.

      Returns:
        An array of JSON values that match this JSONPath expression. }
    function Match(const ARoot: TJsonValue): TArray<TJsonValue>; overload; inline;

    { Executes this JSONPath expression on a document and returns the first
      match.

      Parameters:
        ADoc: the document to use this JSONPath on.
        AMatch: is set to the first match found, or a Null value if no match
          is found.

      Returns:
        True if a match is found or False otherwise. }
    function MatchSingle(const ADoc: IJsonDocument; out AMatch: TJsonValue): Boolean; overload; inline;

    { Executes this JSONPath expression on a JSON value and returns the first
      match.

      Parameters:
        ARoot: the root TJsonValue to use this JSONPath on.
        AMatch: is set to the first match found, or a Null value if no match
          is found.

      Returns:
        True if a match is found or False otherwise. }
    function MatchSingle(const ARoot: TJsonValue; out AMatch: TJsonValue): Boolean; overload; inline;

    { Executes a JSONPath expression on a document.

      Parameters:
        ADoc: the document to use the expression on.
        AExpression: the JSONPath expression to run.

      Returns:
        An array of JSON values that match this JSONPath expression.

      Raises:
        EJsonPathError if AExpression is invalid.

      If you plan to use the same expression multiple times, then it is faster
      to parse it just once using the constructor, and execute it multiple times
      using one of the (non-static) Match* methods. }
    class function Match(const ADoc: IJsonDocument;
      const AExpression: JsonString): TArray<TJsonValue>; overload; inline; static;

    { Executes a JSONPath expression on JSON value.

      Parameters:
        ARoot: the root TJsonValue to use the expression on.
        AExpression: the JSONPath expression to run.

      Returns:
        An array of JSON values that match this JSONPath expression.

      Raises:
        EJsonPathError if AExpression is invalid.

      If you plan to use the same expression multiple times, then it is faster
      to parse it just once using the constructor, and execute it multiple times
      using one of the (non-static) Match* methods. }
    class function Match(const ARoot: TJsonValue;
      const AExpression: JsonString): TArray<TJsonValue>; overload; static;

    { Executes a JSONPath expression on a document and returns the first match.

      Parameters:
        ADoc: the document to use the expression on.
        AExpression: the JSONPath expression to run.
        AMatch: is set to the first match found, or a Null value if no match
          is found.

      Returns:
        True if a match is found or False otherwise.

      Raises:
        EJsonPathError if AExpression is invalid.

      If you plan to use the same expression multiple times, then it is faster
      to parse it just once using the constructor, and execute it multiple times
      using one of the (non-static) Match* methods. }
    class function MatchSingle(const ADoc: IJsonDocument;
      const AExpression: JsonString; out AMatch: TJsonValue): Boolean; overload; inline; static;

    { Executes a JSONPath expression on a JSON value and returns the first match.

      Parameters:
        ARoot: the root TJsonValue to use the expression on.
        AExpression: the JSONPath expression to run.
        AMatch: is set to the first match found, or a Null value if no match
          is found.

      Returns:
        True if a match is found or False otherwise.

      Raises:
        EJsonPathError if AExpression is invalid.

      If you plan to use the same expression multiple times, then it is faster
      to parse it just once using the constructor, and execute it multiple times
      using one of the (non-static) Match* methods. }
    class function MatchSingle(const ARoot: TJsonValue;
      const AExpression: JsonString; out AMatch: TJsonValue): Boolean; overload; static;
  end;

resourcestring
  RS_JSON_PATH_INVALID_ROOT = 'A JSON path must start with a root ($) operator.';
  RS_JSON_PATH_DUPLICATE_ROOT = 'Multiple root operators ($) in JSON path.';
  RS_JSON_PATH_INVALID_OPERATOR = 'Operator in JSON path must start with dot (.) or bracket ([).';
  RS_JSON_PATH_MISSING_MEMBER_NAME = 'Child operator in JSON path is missing a member name.';
  RS_JSON_PATH_QUOTE_EXPECTED = 'Missing end quote in JSON path.';
  RS_JSON_PATH_QUOTE_MISMATCH = 'Quote mismatch in JSON path.';
  RS_JSON_PATH_MISSING_CLOSE_BRACKET = 'Missing close bracket (]) in JSON path.';
  RS_JSON_PATH_TOO_MANY_SLICE_ARGUMENTS = 'Too many slice arguments in JSON path.';
  RS_JSON_PATH_INVALID_SLICE_END = 'Invalid slice end value in JSON path.';
  RS_JSON_PATH_INVALID_SLICE_STEP = 'Invalid slice step value in JSON path.';
  RS_JSON_PATH_INVALID_BRACKET_OPERATOR = 'Invalid text between brackets in JSON path.';
  RS_JSON_PATH_INVALID_INDEX = 'Invalid index in JSON path.';
  RS_JSON_PATH_NEGATIVE_ARRAY_INDEX = 'Negative array index in JSON path not allowed.';
  RS_JSON_PATH_INVALID_RECURSIVE_DESCENT = 'Recursive descent operator (..) in JSON path must be followed by another operator.';

implementation

{ TJsonPath }

procedure TJsonPath.AddMatch(const AMatch: TJsonValue);
begin
  if (FMatchCount >= Length(FMatches)) then
  begin
    if (FMatchCount = 0) then
      SetLength(FMatches, 4)
    else
      SetLength(FMatches, FMatchCount * 2);
  end;
  FMatches[FMatchCount] := AMatch;
  Inc(FMatchCount);
end;

procedure TJsonPath.AddOperator(const AOperator: TOperator);
var
  I: Integer;
begin
  if (FOperatorCount >= Length(FOperators)) then
  begin
    if (FOperatorCount = 0) then
      SetLength(FOperators, 4)
    else
    begin
      SetLength(FOperators, FOperatorCount * 2);
      { Issue #1: adjust the Next pointers after a resize }
      for I := 0 to FOperatorCount - 1 do
        FOperators[I].Next := @FOperators[I + 1];
    end;
  end;
  FOperators[FOperatorCount] := AOperator;

  if (FOperatorCount > 0) then
    FOperators[FOperatorCount - 1].Next := @FOperators[FOperatorCount];

  Inc(FOperatorCount);
end;

constructor TJsonPath.Create(const AExpression: JsonString);
var
  P: PJsonChar;
begin
  FOperators := nil;
  FOperatorCount := 0;

  if (AExpression = '') then
    raise EJsonPathError.Create(RS_JSON_PATH_INVALID_ROOT);

  P := PJsonChar(AExpression);
  SkipWhitespace(P);
  if (P^ <> '$') then
    raise EJsonPathError.Create(RS_JSON_PATH_INVALID_ROOT);
  Inc(P);

  while (P^ <> #0) do
  begin
    SkipWhitespace(P);
    if (P^ = '.') then
      ParseDotOperator(P)
    else if (P^ = '[') then
      ParseBracketOperator(P)
    else if (P^ = '$') then
      raise EJsonPathError.Create(RS_JSON_PATH_DUPLICATE_ROOT)
    else
      raise EJsonPathError.Create(RS_JSON_PATH_INVALID_OPERATOR);
  end;

  if (FOperatorCount > 0)
    and (FOperators[FOperatorCount - 1].OperatorType = TOperatorType.RecursiveDescent)
  then
    raise EJsonPathError.Create(RS_JSON_PATH_INVALID_RECURSIVE_DESCENT);
end;

class function TJsonPath.IsQuote(const AChar: JsonChar): Boolean;
begin
  Result := (AChar = '''') or (AChar = '"');
end;

function TJsonPath.Match(const ARoot: TJsonValue): TArray<TJsonValue>;
begin
  Result := Match(ARoot, False);
end;

function TJsonPath.Match(const ADoc: IJsonDocument): TArray<TJsonValue>;
begin
  if (ADoc <> nil) then
    Result := Match(ADoc.Root);
end;

class function TJsonPath.Match(const ADoc: IJsonDocument;
  const AExpression: JsonString): TArray<TJsonValue>;
begin
  if (ADoc <> nil) then
    Result := Match(ADoc.Root, AExpression);
end;

class function TJsonPath.Match(const ARoot: TJsonValue;
  const AExpression: JsonString): TArray<TJsonValue>;
var
  Path: TJsonPath;
begin
  if (AExpression = '') then
    Exit;

  Path := TJsonPath.Create(AExpression);
  Result := Path.Match(ARoot, False);
end;

function TJsonPath.Match(const ARoot: TJsonValue;
  const AMatchSingle: Boolean): TArray<TJsonValue>;
begin
  if (FOperatorCount = 0) then
    Exit(TArray<TJsonValue>.Create(ARoot));

  FMatches := nil;
  FMatchCount := 0;
  FSingleMatch := AMatchSingle;

  VisitOperator(@FOperators[0], ARoot);

  SetLength(FMatches, FMatchCount);
  Result := FMatches;
end;

function TJsonPath.MatchSingle(const ADoc: IJsonDocument;
  out AMatch: TJsonValue): Boolean;
begin
  if (ADoc = nil) then
  begin
    AMatch := TJsonValue.Null;
    Exit(False);
  end;
  Result := MatchSingle(ADoc.Root, AMatch);
end;

function TJsonPath.MatchSingle(const ARoot: TJsonValue;
  out AMatch: TJsonValue): Boolean;
var
  Matches: TArray<TJsonValue>;
begin
  Matches := Match(ARoot, True);
  if (Matches = nil) then
  begin
    AMatch := TJsonValue.Null;
    Exit(False);
  end;

  AMatch := Matches[0];
  Result := True;
end;

class function TJsonPath.MatchSingle(const ADoc: IJsonDocument;
  const AExpression: JsonString; out AMatch: TJsonValue): Boolean;
begin
  if (ADoc <> nil) then
    Result := MatchSingle(ADoc.Root, AExpression, AMatch)
  else
  begin
    AMatch := TJsonValue.Null;
    Result := False;
  end;
end;

class function TJsonPath.MatchSingle(const ARoot: TJsonValue;
  const AExpression: JsonString; out AMatch: TJsonValue): Boolean;
var
  Path: TJsonPath;
begin
  if (AExpression = '') then
  begin
    AMatch := TJsonValue.Null;
    Exit(False);
  end;

  Path := TJsonPath.Create(AExpression);
  Result := Path.MatchSingle(ARoot, AMatch);
end;

procedure TJsonPath.ParseBracketOperator(var ACur: PJsonChar);
var
  P, Start, Stop: PJsonChar;
  QuoteChar: JsonChar;
  Op: TOperator;
  I, Count: Integer;
begin
  // Initial '[' has already been parsed
  Assert(ACur^ = '[');
  P := ACur + 1;
  SkipWhitespace(P);

  if IsQuote(P^) then
  begin
    // ['ident'] or ["ident"]
    QuoteChar := P^;
    Inc(P);
    if (P^ = '*') then
    begin
      // ['*'] or ["*"]
      if (not IsQuote(P[1])) then
        raise EJsonPathError.Create(RS_JSON_PATH_QUOTE_EXPECTED);

      if (P[1] <> QuoteChar) then
        raise EJsonPathError.Create(RS_JSON_PATH_QUOTE_MISMATCH);

      Inc(P, 2);
      SkipWhitespace(P);
      if (P^ <> ']') then
        raise EJsonPathError.Create(RS_JSON_PATH_MISSING_CLOSE_BRACKET);

      Op.Init(TOperatorType.Wildcard);
      AddOperator(Op);
      Inc(P);
    end
    else
    begin
      // ['ident'] or ["ident"]
      Start := P;

      // Scan for end quote
      while (P^ <> #0) and (not IsQuote(P^)) do
        Inc(P);

      if (P^ = #0) then
        raise EJsonPathError.Create(RS_JSON_PATH_QUOTE_EXPECTED);

      if (P = Start) then
        raise EJsonPathError.Create(RS_JSON_PATH_MISSING_MEMBER_NAME);

      if (P^ <> QuoteChar) then
        raise EJsonPathError.Create(RS_JSON_PATH_QUOTE_MISMATCH);

      Stop := P;
      Inc(P);
      SkipWhitespace(P);
      if (P^ <> ']') then
        raise EJsonPathError.Create(RS_JSON_PATH_MISSING_CLOSE_BRACKET);

      Op.Init(TOperatorType.ChildName);
      SetString(Op.Name, Start, Stop - Start);
      AddOperator(Op);
      Inc(P);
    end;
  end
  else if (P^ = '*') then
  begin
    // [*]
    Inc(P);
    SkipWhitespace(P);
    if (P^ <> ']') then
      raise EJsonPathError.Create(RS_JSON_PATH_MISSING_CLOSE_BRACKET);

    Op.Init(TOperatorType.Wildcard);
    AddOperator(Op);
    Inc(P);
  end
  else
  begin
    // [index]
    // [index, index, ...]
    // [start:end:step]
    Op.Init(TOperatorType.Wildcard); // Temporary
    if (not ParseInteger(P, I)) then
    begin
      // [:end:step]
      SkipWhitespace(P);
      if (P^ <> ':') then
        raise EJsonPathError.Create(RS_JSON_PATH_INVALID_BRACKET_OPERATOR);

      Op.Init(TOperatorType.Slice);
    end
    else
    begin
      // [index]
      // [index, index, ...]
      SkipWhitespace(P);
      if (P^ = ']') then
      begin
        // [index]
        if (I < 0) then
          raise EJsonPathError.Create(RS_JSON_PATH_NEGATIVE_ARRAY_INDEX);
        Op.Init(TOperatorType.ChildIndex);
        Op.Index := I;
      end
      else if (P^ = ',') then
      begin
        // [index, index, ...]
        if (I < 0) then
          raise EJsonPathError.Create(RS_JSON_PATH_NEGATIVE_ARRAY_INDEX);
        Op.Init(TOperatorType.IndexList);
        SetLength(Op.Indices, 4);
        Op.Indices[0] := I;
        Count := 1;

        while True do
        begin
          Inc(P);
          SkipWhitespace(P);
          if (not ParseInteger(P, I)) then
            raise EJsonPathError.Create(RS_JSON_PATH_INVALID_INDEX);

          if (I < 0) then
            raise EJsonPathError.Create(RS_JSON_PATH_NEGATIVE_ARRAY_INDEX);

          if (Count >= Length(Op.Indices)) then
            SetLength(Op.Indices, Count * 2);
          Op.Indices[Count] := I;
          Inc(Count);

          if (P^ = ']') then
            Break;

          if (P^ <> ',') then
            raise EJsonPathError.Create(RS_JSON_PATH_INVALID_INDEX);
        end;
        SetLength(Op.Indices, Count);
      end
      else
      begin
        if (P^ <> ':') then
          raise EJsonPathError.Create(RS_JSON_PATH_INVALID_BRACKET_OPERATOR);

        // [start:end:step]
        Op.Init(TOperatorType.Slice);
        Op.Start := I;
      end;
    end;

    if (Op.OperatorType = TOperatorType.Slice) and (P^ = ':') then
    begin
      // Parse :end part of slice
      Inc(P);
      SkipWhitespace(P);
      if (not ParseInteger(P, I)) then
      begin
        if (P^ <> ':') and (P^ <> ']') then
          raise EJsonPathError.Create(RS_JSON_PATH_INVALID_SLICE_END);
      end
      else
        Op.Stop := I;

      Op.Step := 1;
      if (P^ = ':') then
      begin
        // Parse :step part of slice
        Inc(P);
        SkipWhitespace(P);
        if (not ParseInteger(P, I)) and (P^ <> ']') then
          raise EJsonPathError.Create(RS_JSON_PATH_INVALID_SLICE_STEP);

        Op.Step := I;
      end;

      if (P^ = ':') then
        raise EJsonPathError.Create(RS_JSON_PATH_TOO_MANY_SLICE_ARGUMENTS);

      if (P^ <> ']') then
        raise EJsonPathError.Create(RS_JSON_PATH_MISSING_CLOSE_BRACKET);
    end;

    AddOperator(Op);
    Inc(P);
  end;

  ACur := P;
end;

procedure TJsonPath.ParseDotOperator(var ACur: PJsonChar);
var
  P, Start: PJsonChar;
  Op: TOperator;
begin
  // Initial '.' has already been parsed
  Assert(ACur^ = '.');
  P := ACur + 1;

  if (P^ = '.') then
  begin
    // ..
    Op.Init(TOperatorType.RecursiveDescent);
    AddOperator(Op);
  end
  else if (P^ = '*') then
  begin
    // .*
    Op.Init(TOperatorType.Wildcard);
    AddOperator(Op);
    Inc(P);
  end
  else
  begin
    // .ident
    Start := P;

    // Scan for start of next operator
    while (P^ <> #0) and (P^ <> '.') and (P^ <> '[') do
      Inc(P);

    if (P = Start) then
      raise EJsonPathError.Create(RS_JSON_PATH_MISSING_MEMBER_NAME);

    Op.Init(TOperatorType.ChildName);
    SetString(Op.Name, Start, P - Start);
    AddOperator(Op);
  end;

  ACur := P;
end;

class function TJsonPath.ParseInteger(var ACur: PJsonChar;
  out AValue: Integer): Boolean;
var
  P: PJsonChar;
  C: JsonChar;
  IsNegative: Boolean;
  Value: Integer;
begin
  P := ACur;
  SkipWhitespace(P);

  IsNegative := False;
  if (P^ = '-') then
  begin
    IsNegative := True;
    Inc(P);
  end;

  C := P^;
  if (C < '0') or (C > '9') then
    Exit(False);

  Value := Ord(C) - Ord('0');
  Inc(P);

  while True do
  begin
    C := P^;
    if (C < '0') or (C > '9') then
      Break;

    Value := (Value * 10) + (Ord(C) - Ord('0'));
    Inc(P);
  end;

  if IsNegative then
    Value := -Value;

  SkipWhitespace(P);
  ACur := P;
  AValue := Value;
  Result := True;
end;

class procedure TJsonPath.SkipWhitespace(var ACur: PJsonChar);
begin
  while (ACur^ <= ' ') and (ACur^ <> #0) do
    Inc(ACur);
end;

procedure TJsonPath.VisitOperator(const AOp: POperator; const ARoot: TJsonValue);
var
  I, Index, Start, Stop: Integer;
  Value: TJsonValue;
  Element: PJsonElement;
  NextOp: POperator;
begin
  Assert(Assigned(AOp));
  if (FSingleMatch) and (FMatchCount <> 0) then
    Exit;

  case AOp.OperatorType of
    TOperatorType.ChildName:
      if ARoot.IsDictionary and ARoot.TryGetValue(AOp.Name, Value) then
      begin
        if (AOp.Next = nil) then
          AddMatch(Value)
        else
          VisitOperator(AOp.Next, Value);
      end;

    TOperatorType.ChildIndex:
      if ARoot.IsArray and (AOp.Index < ARoot.Count) then
      begin
        Assert(AOp.Index >= 0);
        Value := ARoot.Items[AOp.Index];
        if (AOp.Next = nil) then
          AddMatch(Value)
        else
          VisitOperator(AOp.Next, Value);
      end;

    TOperatorType.RecursiveDescent:
      begin
        NextOp := AOp.Next;
        Assert(Assigned(NextOp));
        case ARoot.ValueType of
          TJsonValueType.&Array:
            begin
              for I := 0 to ARoot.Count - 1 do
              begin
                if (NextOp.OperatorType = TOperatorType.ChildIndex)
                  and (NextOp.Index = I)
                then
                  VisitOperator(NextOp, ARoot)
                else
                  VisitOperator(AOp, ARoot.Items[I]);
              end;
            end;

          TJsonValueType.Dictionary:
            begin
              for I := 0 to ARoot.Count - 1 do
              begin
                Element := ARoot.Elements[I];
                if(NextOp.OperatorType = TOperatorType.ChildName)
                  and (NextOp.Name = Element.Name)
                then
                  VisitOperator(NextOp, ARoot)
                else
                  VisitOperator(AOp, Element.Value);
              end;
            end;
        end;
      end;

    TOperatorType.Wildcard:
      case ARoot.ValueType of
        TJsonValueType.&Array:
          begin
            for I := 0 to ARoot.Count - 1 do
            begin
              Value := ARoot.Items[I];
              if (AOp.Next = nil) then
                AddMatch(Value)
              else
                VisitOperator(AOp.Next, Value);
            end;
          end;

        TJsonValueType.Dictionary:
          begin
            for I := 0 to ARoot.Count - 1 do
            begin
              Element := ARoot.Elements[I];
              if (AOp.Next = nil) then
                AddMatch(Element.Value)
              else
                VisitOperator(AOp.Next, Element.Value);
            end;
          end;
      end;

    TOperatorType.IndexList:
      if ARoot.IsArray then
      begin
        for I := 0 to Length(AOp.Indices) - 1 do
        begin
          Index := AOp.Indices[I];
          Assert(Index >= 0);
          if (Index < ARoot.Count) then
          begin
            Value := ARoot.Items[Index];
            if (AOp.Next = nil) then
              AddMatch(Value)
            else
              VisitOperator(AOp.Next, Value);
          end;
        end;
      end;

    TOperatorType.Slice:
      if ARoot.IsArray then
      begin
        if (AOp.Start < 0) then
        begin
          Start := ARoot.Count + AOp.Start;
          Stop := ARoot.Count + AOp.Stop;
        end
        else
        begin
          Start := AOp.Start;
          Stop := AOp.Stop;
        end;

        if (Stop > ARoot.Count) then
          Stop := ARoot.Count;

        I := Start;
        Assert(AOp.Step > 0);
        while (I < Stop) do
        begin
          Value := ARoot.Items[I];
          if (AOp.Next = nil) then
            AddMatch(Value)
          else
            VisitOperator(AOp.Next, Value);

          Inc(I, AOp.Step);
        end;
      end
  else
    Assert(False);
  end;
end;

{ TJsonPath.TOperator }

procedure TJsonPath.TOperator.Init(const AType: TOperatorType);
begin
  OperatorType := AType;
  Next := nil;
  Name := '';
  Indices := [];
  Start := 0;
  Stop := 0;
  Step := 0;
end;

end.
