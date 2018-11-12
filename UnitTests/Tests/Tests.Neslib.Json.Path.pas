unit Tests.Neslib.Json.Path;

interface

uses
  DUnitX.TestFramework,
  Neslib.Json,
  Neslib.Json.Path;

type
  TestJsonPathErrors = class
  private
    procedure TestFail(const AExpression: JsonString);
  public
    [Test] procedure TestInvalidRoot;
    [Test] procedure TestInvalidOperator;
    [Test] procedure TestMissingMember;
    [Test] procedure TestMissingWildcardQuote;
    [Test] procedure TestWildcardQuoteMismatch;
    [Test] procedure TestWildcardMissingCloseBracket;
    [Test] procedure TestWildcardMissingCloseBracket2;
    [Test] procedure TestMissingNameQuote;
    [Test] procedure TestNameQuoteMismatch;
    [Test] procedure TestNameMissingCloseBracket;
    [Test] procedure TestEmptyName;
    [Test] procedure TestIndexMissingCloseBracket;
    [Test] procedure TestNegativeIndex;
    [Test] procedure TestNegativeListIndex;
    [Test] procedure TestTooManySliceArguments;
    [Test] procedure TestInvalidSliceStart;
    [Test] procedure TestInvalidSliceEnd;
    [Test] procedure TestInvalidSliceStep;
    [Test] procedure TestInvalidBracketOperator;
    [Test] procedure TestInvalidIndex;
    [Test] procedure TestInvalidIndexDelimiter;
    [Test] procedure TestSliceMissingCloseBracket;
    [Test] procedure TestIndicesMissingCloseBracket;
    [Test] procedure TestInvalidRecursiveDescent;
  end;

type
  TestJsonPathBase = class
  protected
    FDoc: IJsonDocument;
    procedure Test(const AExpression: JsonString;
      const AExpected: array of JsonString);
  end;

type
  TestJsonPathExamples = class(TestJsonPathBase)
  public
    [Setup] procedure Setup;
    [Teardown] procedure Teardown;
    [Test] procedure TestMatchRoot;
    [Test] procedure TestMatchTitleOfFirstBookDot;
    [Test] procedure TestMatchTitleOfFirstBookBracket;
    [Test] procedure TestMatchAllAuthors;
    [Test] procedure TestMatchAuthorsFromAllBooks;
    [Test] procedure TestMatchAllThingsInStore;
    [Test] procedure TestMatchPriceOfAllThingsInStore;
    [Test] procedure TestMatchThirdBook;
    [Test] procedure TestMatchLastBook;
    [Test] procedure TestMatchFirstTwoBooksUsingSlice;
    [Test] procedure TestMatchFirstTwoBooksUsingList;
    [Test] procedure TestMatchAllBooks;
    [Test] procedure TestSingleMatch;
  end;

type
  TestJsonPath = class(TestJsonPathBase)
  public
    [Test] procedure Test1;
    [Test] procedure Test2;
    [Test] procedure Test3;
  end;

type
  TestJsonPathIssues = class
  public
    [Test] procedure TestIssue1;
  end;

implementation

const
  JSON =
    '{ "store": {'#10+
    '    "book": [ '#10+
    '      { "category": "reference",'#10+
    '        "author": "Nigel Rees",'#10+
    '        "title": "Sayings of the Century",'#10+
    '        "price": 8.95'#10+
    '      },'#10+
    '      { "category": "fiction",'#10+
    '        "author": "Evelyn Waugh",'#10+
    '        "title": "Sword of Honour",'#10+
    '        "price": 12.99'#10+
    '      },'#10+
    '      { "category": "fiction",'#10+
    '        "author": "Herman Melville",'#10+
    '        "title": "Moby Dick",'#10+
    '        "isbn": "0-553-21311-3",'#10+
    '        "price": 8.99'#10+
    '      },'#10+
    '      { "category": "fiction",'#10+
    '        "author": "J. R. R. Tolkien",'#10+
    '        "title": "The Lord of the Rings",'#10+
    '        "isbn": "0-395-19395-8",'#10+
    '        "price": 22.99'#10+
    '      }'#10+
    '    ],'#10+
    '    "bicycle": {'#10+
    '      "color": "red",'#10+
    '      "price": 19.95'#10+
    '    }'#10+
    '  }'#10+
    '}';

{ TestJsonPathErrors }

procedure TestJsonPathErrors.TestEmptyName;
begin
  TestFail('$[""]');
end;

procedure TestJsonPathErrors.TestFail(const AExpression: JsonString);
begin
  Assert.WillRaise(
    procedure
    begin
      TJsonPath.Create(AExpression);
    end, EJsonPathError);
end;

procedure TestJsonPathErrors.TestIndexMissingCloseBracket;
begin
  TestFail('$[1');
end;

procedure TestJsonPathErrors.TestIndicesMissingCloseBracket;
begin
  TestFail('$[1,2,3');
end;

procedure TestJsonPathErrors.TestInvalidBracketOperator;
begin
  TestFail('$[store]');
end;

procedure TestJsonPathErrors.TestInvalidIndex;
begin
  TestFail('$[1,2,a,4]');
end;

procedure TestJsonPathErrors.TestInvalidIndexDelimiter;
begin
  TestFail('$[1,2;4]');
end;

procedure TestJsonPathErrors.TestInvalidOperator;
begin
  TestFail('$store');
end;

procedure TestJsonPathErrors.TestInvalidRecursiveDescent;
begin
  TestFail('$..');
end;

procedure TestJsonPathErrors.TestInvalidRoot;
begin
  TestFail('.store.*');
end;

procedure TestJsonPathErrors.TestInvalidSliceEnd;
begin
  TestFail('$[1:a:3]');
end;

procedure TestJsonPathErrors.TestInvalidSliceStart;
begin
  TestFail('$[a:2:3]');
end;

procedure TestJsonPathErrors.TestInvalidSliceStep;
begin
  TestFail('$[1:2:a]');
end;

procedure TestJsonPathErrors.TestMissingMember;
begin
  TestFail('$.store.');
end;

procedure TestJsonPathErrors.TestMissingNameQuote;
begin
  TestFail('$["store]');
end;

procedure TestJsonPathErrors.TestMissingWildcardQuote;
begin
  TestFail('$["*]');
end;

procedure TestJsonPathErrors.TestNameMissingCloseBracket;
begin
  TestFail('$["store"');
end;

procedure TestJsonPathErrors.TestNameQuoteMismatch;
begin
  TestFail('$[''store"]');
end;

procedure TestJsonPathErrors.TestNegativeIndex;
begin
  TestFail('$[-1]');
end;

procedure TestJsonPathErrors.TestNegativeListIndex;
begin
  TestFail('$[1,-2,3]');
end;

procedure TestJsonPathErrors.TestSliceMissingCloseBracket;
begin
  TestFail('$[1:2:3');
end;

procedure TestJsonPathErrors.TestTooManySliceArguments;
begin
  TestFail('$[1:2:3:4]');
end;

procedure TestJsonPathErrors.TestWildcardMissingCloseBracket;
begin
  TestFail('$["*"');
end;

procedure TestJsonPathErrors.TestWildcardMissingCloseBracket2;
begin
  TestFail('$[*');
end;

procedure TestJsonPathErrors.TestWildcardQuoteMismatch;
begin
  TestFail('$[''*"]');
end;

{ TestJsonPathBase }

procedure TestJsonPathBase.Test(const AExpression: JsonString;
  const AExpected: array of JsonString);
var
  Matches: TArray<TJsonValue>;
  I: Integer;
begin
  Matches := TJsonPath.Match(FDoc, AExpression);
  Assert.AreEqual(Length(AExpected), Length(Matches));

  for I := 0 to Length(Matches) - 1 do
    Assert.AreEqual(AExpected[I], Matches[I].ToJson(False));
end;

{ TestJsonPathExamples }

procedure TestJsonPathExamples.Setup;
begin
  FDoc := TJsonDocument.Parse(JSON);
end;

procedure TestJsonPathExamples.Teardown;
begin
  FDoc := nil;
end;

procedure TestJsonPathExamples.TestMatchAllAuthors;
begin
  Test('$..author', ['"Nigel Rees"', '"Evelyn Waugh"', '"Herman Melville"',
    '"J. R. R. Tolkien"']);
end;

procedure TestJsonPathExamples.TestMatchAllBooks;
begin
  Test('$.store.book[*]', [
    '{ "category" : "reference", "author" : "Nigel Rees", "title" : "Sayings of the Century", "price" : 8.95 }',
    '{ "category" : "fiction", "author" : "Evelyn Waugh", "title" : "Sword of Honour", "price" : 12.99 }',
    '{ "category" : "fiction", "author" : "Herman Melville", "title" : "Moby Dick", "isbn" : "0-553-21311-3", "price" : 8.99 }',
    '{ "category" : "fiction", "author" : "J. R. R. Tolkien", "title" : "The Lord of the Rings", "isbn" : "0-395-19395-8", "price" : 22.99 }']);
end;

procedure TestJsonPathExamples.TestMatchAllThingsInStore;
var
  Matches: TArray<TJsonValue>;
begin
  Matches := TJsonPath.Match(FDoc, '$.store.*');
  Assert.AreEqual(2, Length(Matches));

  // First match is array of 4 books
  Assert.IsTrue(Matches[0].IsArray);
  Assert.AreEqual(4, Matches[0].Count);

  // Second match is single dictionary with red bicycle
  Assert.IsTrue(Matches[1].IsDictionary);
  Assert.AreEqual<JsonString>('red', Matches[1].Values['color'].ToString);
end;

procedure TestJsonPathExamples.TestMatchAuthorsFromAllBooks;
begin
  Test('$.store.book[*].author', ['"Nigel Rees"', '"Evelyn Waugh"',
    '"Herman Melville"', '"J. R. R. Tolkien"']);
end;

procedure TestJsonPathExamples.TestMatchFirstTwoBooksUsingList;
begin
  Test('$..book[0,1]', [
    '{ "category" : "reference", "author" : "Nigel Rees", "title" : "Sayings of the Century", "price" : 8.95 }',
    '{ "category" : "fiction", "author" : "Evelyn Waugh", "title" : "Sword of Honour", "price" : 12.99 }']);
end;

procedure TestJsonPathExamples.TestMatchFirstTwoBooksUsingSlice;
begin
  Test('$..book[:2]', [
    '{ "category" : "reference", "author" : "Nigel Rees", "title" : "Sayings of the Century", "price" : 8.95 }',
    '{ "category" : "fiction", "author" : "Evelyn Waugh", "title" : "Sword of Honour", "price" : 12.99 }']);
end;

procedure TestJsonPathExamples.TestMatchLastBook;
begin
  Test('$..book[-1:]', ['{ "category" : "fiction", "author" : "J. R. R. Tolkien", "title" : "The Lord of the Rings", "isbn" : "0-395-19395-8", "price" : 22.99 }']);
end;

procedure TestJsonPathExamples.TestMatchPriceOfAllThingsInStore;
begin
  Test('$.store..price', ['8.95', '12.99', '8.99', '22.99', '19.95']);
end;

procedure TestJsonPathExamples.TestMatchRoot;
var
  Matches: TArray<TJsonValue>;
begin
  Matches := TJsonPath.Match(FDoc, '$');
  Assert.AreEqual(1, Length(Matches));
  Assert.IsTrue(Matches[0] = FDoc.Root);
end;

procedure TestJsonPathExamples.TestMatchThirdBook;
begin
  Test('$..book[2]', ['{ "category" : "fiction", "author" : "Herman Melville", "title" : "Moby Dick", "isbn" : "0-553-21311-3", "price" : 8.99 }']);
end;

procedure TestJsonPathExamples.TestMatchTitleOfFirstBookBracket;
begin
  Test('$["store"][''book''][0]["title"]', ['"Sayings of the Century"']);
end;

procedure TestJsonPathExamples.TestMatchTitleOfFirstBookDot;
begin
  Test('$.store.book[0].title', ['"Sayings of the Century"']);
end;

procedure TestJsonPathExamples.TestSingleMatch;
var
  Match: TJsonValue;
begin
  Assert.IsTrue(TJsonPath.MatchSingle(FDoc, '$.store.bicycle', Match));
  Assert.AreEqual<JsonString>('{ "color" : "red", "price" : 19.95 }', Match.ToJson(False));

  Assert.IsTrue(TJsonPath.MatchSingle(FDoc, '$.store.bicycle.*', Match));
  Assert.AreEqual<JsonString>('"red"', Match.ToJson(False));
end;

{ TestJsonPath }

{ Tests from the original JSONPath package. }

procedure TestJsonPath.Test1;
begin
  FDoc := TJsonDocument.CreateDictionary;
  FDoc.Root.AddOrSetValue('a', 'a');
  FDoc.Root.AddOrSetValue('b', 'b');
  FDoc.Root.AddOrSetValue('c d', 'e');

  Test('$.a', ['"a"']);
  Test('$[''a'']', ['"a"']);
  Test('$["a"]', ['"a"']);
  Test('$["c d"]', ['"e"']);
//  Test('$."c d"', ['"e"']); // We don't support this syntax
  Test('$.*', ['"a"', '"b"', '"e"']);
  Test('$["*"]', ['"a"', '"b"', '"e"']);
  Test('$[*]', ['"a"', '"b"', '"e"']);
end;

procedure TestJsonPath.Test2;
begin
  FDoc := TJsonDocument.CreateArray;
  FDoc.Root.Add(1);
  FDoc.Root.Add('2');
  FDoc.Root.Add(3.14);
  FDoc.Root.Add(True);
  FDoc.Root.AddNull;

  Test('$[0]', ['1']);
  Test('$[4]', ['null']);
  Test('$[*]', ['1', '"2"', '3.14', 'true', 'null']);
  Test('$[-1:]', ['null']);
end;

procedure TestJsonPath.Test3;
var
  A, D: TJsonValue;
begin
  FDoc := TJsonDocument.CreateDictionary;
  A := FDoc.Root.AddOrSetArray('points');

  D := A.AddDictionary;
  D.AddOrSetValue('id', 'i1');
  D.AddOrSetValue('x', 4);
  D.AddOrSetValue('y', -5);

  D := A.AddDictionary;
  D.AddOrSetValue('id', 'i2');
  D.AddOrSetValue('x', -2);
  D.AddOrSetValue('y', 2);
  D.AddOrSetValue('z', 1);

  D := A.AddDictionary;
  D.AddOrSetValue('id', 'i3');
  D.AddOrSetValue('x', 8);
  D.AddOrSetValue('y', 3);

  D := A.AddDictionary;
  D.AddOrSetValue('id', 'i4');
  D.AddOrSetValue('x', -6);
  D.AddOrSetValue('y', -1);

  D := A.AddDictionary;
  D.AddOrSetValue('id', 'i5');
  D.AddOrSetValue('x', 0);
  D.AddOrSetValue('y', 2);
  D.AddOrSetValue('z', 1);

  D := A.AddDictionary;
  D.AddOrSetValue('id', 'i6');
  D.AddOrSetValue('x', 1);
  D.AddOrSetValue('y', 4);

  Test('$.points[1]', ['{ "id" : "i2", "x" : -2, "y" : 2, "z" : 1 }']);
  Test('$.points[4].x', ['0']);
  Test('$.points[*].x', ['4', '-2', '8', '-6', '0', '1']);
end;

{ TestJsonPathIssues }

procedure TestJsonPathIssues.TestIssue1;
// https://github.com/neslib/Neslib.Json/issues/1
const
  JSON =
    '{ "store": {'#10+
    '    "book": [ '#10+
    '      { "category": "reference",'#10+
    '        "author": "Nigel Rees",'#10+
    '        "title": "Sayings of the Century",'#10+
    '        "price": 8.95,'#10+
    '        "Sale": {'#10+
    '          "OnSale" : "Yes"'#10+
    '        }'#10+
    '      },'#10+
    '      { "category": "fiction",'#10+
    '        "author": "Evelyn Waugh",'#10+
    '        "title": "Sword of Honour",'#10+
    '        "price": 12.99'#10+
    '      },'#10+
    '      { "category": "fiction",'#10+
    '        "author": "Herman Melville",'#10+
    '        "title": "Moby Dick",'#10+
    '        "isbn": "0-553-21311-3",'#10+
    '        "price": 8.99'#10+
    '      },'#10+
    '      { "category": "fiction",'#10+
    '        "author": "J. R. R. Tolkien",'#10+
    '        "title": "The Lord of the Rings",'#10+
    '        "isbn": "0-395-19395-8",'#10+
    '        "price": 22.99'#10+
    '      }'#10+
    '    ],'#10+
    '    "bicycle": {'#10+
    '      "color": "red",'#10+
    '      "price": 19.95'#10+
    '    }'#10+
    '  }'#10+
    '}';
var
  Doc: IJsonDocument;
  Matches: TArray<TJsonValue>;
begin
  Doc := TJsonDocument.Parse(JSON);
  Matches := TJsonPath.Match(Doc, '$.store.book[0].Sale.OnSale');
  Assert.AreEqual(1, Length(Matches));
  Assert.AreEqual('"Yes"', Matches[0].ToJson);
  Assert.AreEqual('Yes', Matches[0].ToString);
end;

initialization
  ReportMemoryLeaksOnShutdown := True;
  TDUnitX.RegisterTestFixture(TestJsonPathErrors);
  TDUnitX.RegisterTestFixture(TestJsonPathExamples);
  TDUnitX.RegisterTestFixture(TestJsonPath);
  TDUnitX.RegisterTestFixture(TestJsonPathIssues);

end.
