unit Tests.Neslib.Json.Json5;

interface

uses
  DUnitX.TestFramework,
  Neslib.Json.Types,
  Neslib.Json.IO,
  Neslib.Json;

type
  TestJson5 = class
  public
    [Test] procedure TestUnquotedKeys;
    [Test] procedure TestTrailingCommas;
    [Test] procedure TestSingleQuotedStrings;
    [Test] procedure TestComments;
  end;

implementation

{ TestJson5 }

procedure TestJson5.TestComments;
begin
  var Doc := TJsonDocument.Parse(
    '{ '#10+
    '  // Single line comment'#10+
    '  "foo" : "bar" }');
  Assert.IsTrue(Doc.Root.IsDictionary);
  Assert.AreEqual<JsonString>('bar', Doc.Root.Values['foo'].ToString);

  Doc := TJsonDocument.Parse(
    '[ '#10+
    '  /* Multi'#10+
    '     line'#10+
    '     comment */'#10+
    '  "foo", "bar" ]');
  Assert.IsTrue(Doc.Root.IsArray);
  Assert.AreEqual(2, Doc.Root.Count);
end;

procedure TestJson5.TestSingleQuotedStrings;
begin
  var Doc := TJsonDocument.Parse('{ "foo" : "bar''baz" }');
  Assert.IsTrue(Doc.Root.IsDictionary);

  Doc := TJsonDocument.Parse('{ "foo" : ''bar"baz'' }');
  Assert.IsTrue(Doc.Root.IsDictionary);

  Doc := TJsonDocument.Parse('{ ''foo'' : "bar" }');
  Assert.IsTrue(Doc.Root.IsDictionary);
end;

procedure TestJson5.TestTrailingCommas;
begin
  var Doc := TJsonDocument.Parse('{ "foo" : "bar", }');
  Assert.IsTrue(Doc.Root.IsDictionary);

  Doc := TJsonDocument.Parse('[ "foo", "bar", ]');
  Assert.IsTrue(Doc.Root.IsArray);
end;

procedure TestJson5.TestUnquotedKeys;
begin
  var Doc := TJsonDocument.Parse('{ unquoted: "foo" }');
  var Root := Doc.Root;
  Assert.IsTrue(Root.IsDictionary);
  Assert.AreEqual<JsonString>('foo', Root.Values['unquoted'].ToString);

  Assert.WillRaise(
    procedure
    begin
      TJsonDocument.Parse('{ invalid key: "foo" }');
    end, EJsonParserError);
end;

initialization
  TDUnitX.RegisterTestFixture(TestJson5);

end.
