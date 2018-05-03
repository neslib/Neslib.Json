unit Tests.Neslib.Json.IO;

interface

uses
  System.Math,
  System.Classes,
  System.SysUtils,
  System.Generics.Defaults,
  System.Generics.Collections,
  DUnitX.TestFramework,
  Neslib.Json,
  Neslib.Json.IO;

type
  TestJsonReader = class
  public
    [Test] procedure TestEmptyArray;
    [Test] procedure TestArrayOneElement;
    [Test] procedure TestArrayTwoElements;
    [Test] procedure TestArrayNested1;
    [Test] procedure TestArrayNested2;
    [Test] procedure TestArrayNested3;
    [Test] procedure TestBooleanFalse;
    [Test] procedure TestBooleanTrue;
    [Test] procedure TestDocumentEmpty;
    [Test] procedure TestDocumentOneElement;
    [Test] procedure TestDocumentTwoElements;
    [Test] procedure TestDocumentNested1;
    [Test] procedure TestDocumentNested2;
    [Test] procedure TestDocumentNested3;
    [Test] procedure TestFloat;
    [Test] procedure TestInfinity;
    [Test] procedure TestNegativeInfinity;
    [Test] procedure TestNaN;
    [Test] procedure TestOrdinal;
    [Test] procedure TestNull;
    [Test] procedure TestString;
    [Test] procedure TestStringEmpty;
    [Test] procedure TestUnquotedName;
    [Test] procedure TestUnquotedString;
    [Test] procedure TestEscapedString;
  end;

type
  TestJsonWriter = class
  public
    [Test] procedure TestEmptyArray;
    [Test] procedure TestEmptyDictionary;
    [Test] procedure TestSingleString;
    [Test] procedure TestPrettyPrintedOneElement;
    [Test] procedure TestPrettyPrintedTwoElements;
    [Test] procedure TestFloat;
    [Test] procedure TestOrdinal;
    [Test] procedure TestEmbeddedDocument;
    [Test] procedure TestPrettyPrintedEmbeddedDocument;
    [Test] procedure TestArray;
    [Test] procedure TestNull;
    [Test] procedure TestBoolean;
    [Test] procedure TestString;
  end;

type
  TestJsonData = class
  private
    procedure TestJsonFile(const ABaseFilename: String);
    procedure WriteValueTree(const ABuilder: TStringBuilder;
      const AValue: TJsonValue; const APath: String = '.');
  public
    [Test] procedure test_array_01;
    [Test] procedure test_array_02;
    [Test] procedure test_array_03;
    [Test] procedure test_array_04;
    [Test] procedure test_array_05;
    [Test] procedure test_array_06;
    [Test] procedure test_basic_01;
    [Test] procedure test_basic_02;
    [Test] procedure test_basic_03;
    [Test] procedure test_basic_04;
    [Test] procedure test_basic_05;
    [Test] procedure test_basic_06;
    [Test] procedure test_basic_07;
//    procedure test_basic_08; // this test is not JSON compliant
//    procedure test_basic_09; // this test is not JSON compliant
//    procedure test_comment_01; // this test is not JSON compliant
    [Test] procedure test_complex_01;
    [Test] procedure test_integer_01;
    [Test] procedure test_integer_02;
    [Test] procedure test_integer_03;
    [Test] procedure test_integer_04;
    [Test] procedure test_integer_05;
    [Test] procedure test_large_01;
    [Test] procedure test_object_01;
    [Test] procedure test_object_02;
    [Test] procedure test_object_03;
    [Test] procedure test_object_04;
//    procedure test_preserve_comment_01; // this test is not JSON compliant
    [Test] procedure test_real_01;
    [Test] procedure test_real_02;
    [Test] procedure test_real_03;
    [Test] procedure test_real_04;
    [Test] procedure test_real_05;
    [Test] procedure test_real_06;
    [Test] procedure test_real_07;
    [Test] procedure test_string_01;
    [Test] procedure test_string_02;
    [Test] procedure test_string_unicode_01;
    [Test] procedure test_string_unicode_02;
    [Test] procedure test_string_unicode_03;
    [Test] procedure test_string_unicode_04;
    [Test] procedure test_string_unicode_05;
  end;

type
  TestJsonChecker = class
  private
    procedure TestPass(const AFilename: String);
    procedure TestFail(const AFilename: String; const AErrorLine,
      AErrorColumn: Integer);
  public
    [Test] procedure test_fail1;
    [Test] procedure test_fail2;
    [Test] procedure test_fail3;
    [Test] procedure test_fail4;
    [Test] procedure test_fail5;
    [Test] procedure test_fail6;
    [Test] procedure test_fail7;
    [Test] procedure test_fail8;
    [Test] procedure test_fail9;
    [Test] procedure test_fail10;
    [Test] procedure test_fail11;
    [Test] procedure test_fail12;
    [Test] procedure test_fail13;
    [Test] procedure test_fail14;
    [Test] procedure test_fail15;
    [Test] procedure test_fail16;
    [Test] procedure test_fail17;
    [Test] procedure test_fail18;
    [Test] procedure test_fail19;
    [Test] procedure test_fail20;
    [Test] procedure test_fail21;
    [Test] procedure test_fail22;
    [Test] procedure test_fail23;
    [Test] procedure test_fail24;
    [Test] procedure test_fail25;
    [Test] procedure test_fail26;
    [Test] procedure test_fail27;
    [Test] procedure test_fail28;
    [Test] procedure test_fail29;
    [Test] procedure test_fail30;
    [Test] procedure test_fail31;
    [Test] procedure test_fail32;
    [Test] procedure test_fail33;
    [Test] procedure test_pass1;
    [Test] procedure test_pass2;
    [Test] procedure test_pass3;
  end;

implementation

uses
  TestUtils;

{$R 'JsonTestData.res'}

{ TestJsonReader }

procedure TestJsonReader.TestArrayNested1;
const
  JSON = '[1, [2, 3]]';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartArray, State);
  Reader.ReadStartArray;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(1, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartArray, State);
  Reader.ReadStartArray;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(2, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(3, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndArray, State);
  Reader.ReadEndArray;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndArray, State);
  Reader.ReadEndArray;

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Doc := TJsonDocument.Parse(JSON);
  Assert.AreEqual<JsonString>(JSON, Doc.ToJson);
end;

procedure TestJsonReader.TestArrayNested2;
const
  JSON = '[[1, 2], 3]';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartArray, State);
  Reader.ReadStartArray;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartArray, State);
  Reader.ReadStartArray;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(1, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(2, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndArray, State);
  Reader.ReadEndArray;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(3, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndArray, State);
  Reader.ReadEndArray;

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Doc := TJsonDocument.Parse(JSON);
  Assert.AreEqual<JsonString>(JSON, Doc.ToJson);
end;

procedure TestJsonReader.TestArrayNested3;
const
  JSON = '[1, [2, 3], 4]';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartArray, State);
  Reader.ReadStartArray;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(1, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartArray, State);
  Reader.ReadStartArray;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(2, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(3, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndArray, State);
  Reader.ReadEndArray;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(4, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndArray, State);
  Reader.ReadEndArray;

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Doc := TJsonDocument.Parse(JSON);
  Assert.AreEqual<JsonString>(JSON, Doc.ToJson);
end;

procedure TestJsonReader.TestArrayOneElement;
const
  JSON = '[1]';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartArray, State);
  Reader.ReadStartArray;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(1, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndArray, State);
  Reader.ReadEndArray;

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Doc := TJsonDocument.Parse(JSON);
  Assert.AreEqual<JsonString>(JSON, Doc.ToJson);
end;

procedure TestJsonReader.TestArrayTwoElements;
const
  JSON = '[1, 2]';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartArray, State);
  Reader.ReadStartArray;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(1, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(2, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndArray, State);
  Reader.ReadEndArray;

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Doc := TJsonDocument.Parse(JSON);
  Assert.AreEqual<JsonString>(JSON, Doc.ToJson);
end;

procedure TestJsonReader.TestBooleanFalse;
const
  JSON = 'false';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Boolean, State);
  Assert.IsFalse(Reader.ReadBoolean);

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Assert.WillRaise(
    procedure
    begin
      Doc := TJsonDocument.Parse(JSON);
    end, EJsonParserError);
end;

procedure TestJsonReader.TestBooleanTrue;
const
  JSON = 'true';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Boolean, State);
  Assert.IsTrue(Reader.ReadBoolean);

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Assert.WillRaise(
    procedure
    begin
      Doc := TJsonDocument.Parse(JSON);
    end, EJsonParserError);
end;

procedure TestJsonReader.TestDocumentEmpty;
const
  JSON = '{ }';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartDictionary, State);
  Reader.ReadStartDictionary;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndDictionary, State);
  Reader.ReadEndDictionary;

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Doc := TJsonDocument.Parse(JSON);
  Assert.AreEqual<JsonString>(JSON, Doc.ToJson);
end;

procedure TestJsonReader.TestDocumentNested1;
const
  JSON = '{ "a" : { "x" : 1 }, "y" : 2 }';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartDictionary, State);
  Reader.ReadStartDictionary;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Name, State);
  Assert.AreEqual<JsonString>('a', Reader.ReadName);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartDictionary, State);
  Reader.ReadStartDictionary;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Name, State);
  Assert.AreEqual<JsonString>('x', Reader.ReadName);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(1, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndDictionary, State);
  Reader.ReadEndDictionary;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Name, State);
  Assert.AreEqual<JsonString>('y', Reader.ReadName);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(2, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndDictionary, State);
  Reader.ReadEndDictionary;

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Doc := TJsonDocument.Parse(JSON);
  Assert.AreEqual<JsonString>(JSON, Doc.ToJson(False));
end;

procedure TestJsonReader.TestDocumentNested2;
const
  JSON = '{ "y" : 2, "a" : { "x" : 1 } }';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartDictionary, State);
  Reader.ReadStartDictionary;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Name, State);
  Assert.AreEqual<JsonString>('y', Reader.ReadName);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(2, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Name, State);
  Assert.AreEqual<JsonString>('a', Reader.ReadName);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartDictionary, State);
  Reader.ReadStartDictionary;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Name, State);
  Assert.AreEqual<JsonString>('x', Reader.ReadName);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(1, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndDictionary, State);
  Reader.ReadEndDictionary;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndDictionary, State);
  Reader.ReadEndDictionary;

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Doc := TJsonDocument.Parse(JSON);
  Assert.AreEqual<JsonString>(JSON, Doc.ToJson(False));
end;

procedure TestJsonReader.TestDocumentNested3;
const
  JSON = '{ "y" : 2, "a" : { "x" : 1 }, "b" : 3 }';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartDictionary, State);
  Reader.ReadStartDictionary;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Name, State);
  Assert.AreEqual<JsonString>('y', Reader.ReadName);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(2, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Name, State);
  Assert.AreEqual<JsonString>('a', Reader.ReadName);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartDictionary, State);
  Reader.ReadStartDictionary;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Name, State);
  Assert.AreEqual<JsonString>('x', Reader.ReadName);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(1, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndDictionary, State);
  Reader.ReadEndDictionary;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Name, State);
  Assert.AreEqual<JsonString>('b', Reader.ReadName);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(3, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndDictionary, State);
  Reader.ReadEndDictionary;

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Doc := TJsonDocument.Parse(JSON);
  Assert.AreEqual<JsonString>(JSON, Doc.ToJson(False));
end;

procedure TestJsonReader.TestDocumentOneElement;
const
  JSON = '{ "x" : 1 }';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartDictionary, State);
  Reader.ReadStartDictionary;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Name, State);
  Assert.AreEqual<JsonString>('x', Reader.ReadName);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(1, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndDictionary, State);
  Reader.ReadEndDictionary;

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Doc := TJsonDocument.Parse(JSON);
  Assert.AreEqual<JsonString>(JSON, Doc.ToJson(False));
end;

procedure TestJsonReader.TestDocumentTwoElements;
const
  JSON = '{ "x" : 1, "y" : 2 }';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartDictionary, State);
  Reader.ReadStartDictionary;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Name, State);
  Assert.AreEqual<JsonString>('x', Reader.ReadName);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(1, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Name, State);
  Assert.AreEqual<JsonString>('y', Reader.ReadName);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(2, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndDictionary, State);
  Reader.ReadEndDictionary;

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Doc := TJsonDocument.Parse(JSON);
  Assert.AreEqual<JsonString>(JSON, Doc.ToJson(False));
end;

procedure TestJsonReader.TestEmptyArray;
const
  JSON = '[]';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartArray, State);
  Reader.ReadStartArray;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndArray, State);
  Reader.ReadEndArray;

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Doc := TJsonDocument.Parse(JSON);
  Assert.AreEqual<JsonString>(JSON, Doc.ToJson);
end;

procedure TestJsonReader.TestEscapedString;
const
  JSON = '"a\"b\\\/\b\f\n\r\t\ucafes"';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.String, State);
  Assert.AreEqual<JsonString>('a"b\/'#8#12#10#13#9#$CAFE's', Reader.ReadString);

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Assert.WillRaise(
    procedure
    begin
      Doc := TJsonDocument.Parse(JSON);
    end, EJsonParserError);
end;

procedure TestJsonReader.TestFloat;
const
  JSON = '1.5';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Float, State);
  Assert.AreEqual<Double>(1.5, Reader.ReadFloat);

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Assert.WillRaise(
    procedure
    begin
      Doc := TJsonDocument.Parse(JSON);
    end, EJsonParserError);
end;

procedure TestJsonReader.TestInfinity;
const
  JSON = 'Infinity';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Float, State);
  Assert.IsTrue(Reader.ReadFloat.IsPositiveInfinity);

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Assert.WillRaise(
    procedure
    begin
      Doc := TJsonDocument.Parse(JSON);
    end, EJsonParserError);
end;

procedure TestJsonReader.TestNaN;
const
  JSON = 'NaN';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Float, State);
  Assert.IsTrue(Reader.ReadFloat.IsNan);

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Assert.WillRaise(
    procedure
    begin
      Doc := TJsonDocument.Parse(JSON);
    end, EJsonParserError);
end;

procedure TestJsonReader.TestNegativeInfinity;
const
  JSON = '-Infinity';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Float, State);
  Assert.IsTrue(Reader.ReadFloat.IsNegativeInfinity);

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Assert.WillRaise(
    procedure
    begin
      Doc := TJsonDocument.Parse(JSON);
    end, EJsonParserError);
end;

procedure TestJsonReader.TestNull;
const
  JSON = 'null';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Null, State);
  Reader.ReadNull;

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Assert.WillRaise(
    procedure
    begin
      Doc := TJsonDocument.Parse(JSON);
    end, EJsonParserError);
end;

procedure TestJsonReader.TestOrdinal;
const
  JSON = '-9223372036854775808';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(-9223372036854775808, Reader.ReadOrdinal);

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Assert.WillRaise(
    procedure
    begin
      Doc := TJsonDocument.Parse(JSON);
    end, EJsonParserError);
end;

procedure TestJsonReader.TestString;
const
  JSON = '"abc"';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.String, State);
  Assert.AreEqual<JsonString>('abc', Reader.ReadString);

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Assert.WillRaise(
    procedure
    begin
      Doc := TJsonDocument.Parse(JSON);
    end, EJsonParserError);
end;

procedure TestJsonReader.TestStringEmpty;
const
  JSON = '""';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.String, State);
  Assert.AreEqual<JsonString>('', Reader.ReadString);

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Assert.WillRaise(
    procedure
    begin
      Doc := TJsonDocument.Parse(JSON);
    end, EJsonParserError);
end;

procedure TestJsonReader.TestUnquotedName;
const
  JSON = '{ x : 1 }';
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.StartDictionary, State);
  Reader.ReadStartDictionary;

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Name, State);
  Assert.AreEqual<JsonString>('x', Reader.ReadName);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.Ordinal, State);
  Assert.AreEqual<Int64>(1, Reader.ReadOrdinal);

  Assert.IsTrue(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndDictionary, State);
  Reader.ReadEndDictionary;

  Assert.IsFalse(Reader.Next(State));
  Assert.AreEqual<TJsonReaderState>(TJsonReaderState.EndOfStream, State);

  Doc := TJsonDocument.Parse(JSON);
  Assert.AreEqual<JsonString>('{ "x" : 1 }', Doc.ToJson(False));
end;

procedure TestJsonReader.TestUnquotedString;
const
  JSON = 'foo';
var
  Reader: IJsonReader;
  State: TJsonReaderState;
begin
  Reader := TJsonReader.Create(JSON);
  Assert.WillRaise(
    procedure
    begin
      Reader.Next(State);
    end, EJsonParserError);
end;

{ TestJsonWriter }

procedure TestJsonWriter.TestArray;
var
  Doc: IJsonDocument;
  A: TJsonValue;
begin
  Doc := TJsonDocument.CreateDictionary;
  A := Doc.Root.AddOrSetArray('array');
  A.Add(1);
  A.Add(2);
  A.Add(3);
  Assert.AreEqual<JsonString>('{ "array" : [1, 2, 3] }', Doc.ToJson(False));
end;

procedure TestJsonWriter.TestBoolean;
var
  Doc: IJsonDocument;
begin
  Doc := TJsonDocument.CreateDictionary;
  Doc.Root.AddOrSetValue('t', True);
  Doc.Root.AddOrSetValue('f', False);
  Assert.AreEqual<JsonString>('{ "t" : true, "f" : false }', Doc.ToJson(False));
end;

procedure TestJsonWriter.TestEmbeddedDocument;
var
  Doc: IJsonDocument;
  Dict: TJsonValue;
begin
  Doc := TJsonDocument.CreateDictionary;
  Dict := Doc.Root.AddOrSetDictionary('doc');
  Dict.AddOrSetValue('a', 1);
  Dict.AddOrSetValue('b', 2);
  Assert.AreEqual<JsonString>('{ "doc" : { "a" : 1, "b" : 2 } }', Doc.ToJson(False));
end;

procedure TestJsonWriter.TestEmptyArray;
var
  Doc: IJsonDocument;
begin
  Doc := TJsonDocument.CreateArray;
  Assert.AreEqual<JsonString>('[]', Doc.ToJson);
end;

procedure TestJsonWriter.TestEmptyDictionary;
var
  Doc: IJsonDocument;
begin
  Doc := TJsonDocument.CreateDictionary;
  Assert.AreEqual<JsonString>('{ }', Doc.ToJson);
end;

procedure TestJsonWriter.TestFloat;

  procedure Test(const AValue: Double; const AExpected: JsonString);
  var
    Json: JsonString;
    Doc: IJsonDocument;
    Recon: Double;
  begin
    Doc := TJsonDocument.CreateArray;
    Doc.Root.Add(AValue);
    Json := Doc.Root.ToJson;
    Assert.AreEqual<JsonString>(AExpected, Copy(Json, Low(JsonString) + 1, Length(Json) - 2));

    Doc := nil;
    Doc := TJsonDocument.Parse(Json);
    Recon := Doc.Root.Items[0];

    if (AValue.IsNan) then
      Assert.IsTrue(Recon.IsNan)
    else if (AValue.IsPositiveInfinity) then
      Assert.IsTrue(Recon.IsPositiveInfinity)
    else if (AValue.IsNegativeInfinity) then
      Assert.IsTrue(Recon.IsNegativeInfinity)
    else
      Assert.IsTrue(SameValue(AValue, Recon));
  end;

begin
  Test(0.0, '0.0');
  Test(0.0005, '0.0005');
  Test(0.5, '0.5');
  Test(1.0, '1.0');
  Test(1.5, '1.5');
  Test(1.5E+40, '1.5E40');
  Test(1.5E-40, '1.5E-40');
  Test(1234567890.1234568E+123, '1.23456789012346E132');
  Test(Double.Epsilon, '4.94065645841247E-324');
  Test(-0.0005, '-0.0005');
  Test(-0.5, '-0.5');
  Test(-1.0, '-1.0');
  Test(-1.5, '-1.5');
  Test(-1.5E+40, '-1.5E40');
  Test(-1.5E-40, '-1.5E-40');
  Test(-1234567890.1234568E+123, '-1.23456789012346E132');
  Test(-Double.Epsilon, '-4.94065645841247E-324');

  Test(Double.NaN, 'NaN');
  Test(Double.NegativeInfinity, '-Infinity');
  Test(Double.PositiveInfinity, 'Infinity');
end;

procedure TestJsonWriter.TestNull;
var
  Doc: IJsonDocument;
begin
  Doc := TJsonDocument.CreateDictionary;
  Doc.Root.AddOrSetNull('null');
  Assert.AreEqual<JsonString>('{ "null" : null }', Doc.ToJson(False));
end;

procedure TestJsonWriter.TestOrdinal;

  procedure Test(const AValue: Int64; const AExpected: JsonString);
  var
    Json: JsonString;
    Doc: IJsonDocument;
    Recon: Int64;
  begin
    Doc := TJsonDocument.CreateArray;
    Doc.Root.Add(AValue);
    Json := Doc.Root.ToJson;
    Assert.AreEqual(AExpected, Copy(Json, Low(JsonString) + 1, Length(Json) - 2));

    Doc := nil;
    Doc := TJsonDocument.Parse(Json);
    Recon := Doc.Root.Items[0];

    Assert.AreEqual<Int64>(AValue, Recon);
  end;

begin
  Test(Int64.MinValue, '-9223372036854775808');
  Test(Int64(Integer.MinValue) - 1, '-2147483649');
  Test(Integer.MinValue, '-2147483648');
  Test(0, '0');
  Test(Integer.MaxValue, '2147483647');
  Test(Int64(Integer.MaxValue) + 1, '2147483648');
  Test(Int64.MaxValue, '9223372036854775807');
end;

procedure TestJsonWriter.TestPrettyPrintedEmbeddedDocument;
var
  Doc: IJsonDocument;
  Dict: TJsonValue;
begin
  Doc := TJsonDocument.CreateDictionary;
  Dict := Doc.Root.AddOrSetDictionary('doc');
  Dict.AddOrSetValue('a', 1);
  Dict.AddOrSetValue('b', 2);
  Assert.AreEqual<JsonString>('{'#10'  "doc" : {'#10'    "a" : 1,'#10'    "b" : 2'#10'  }'#10'}', Doc.ToJson(True));
end;

procedure TestJsonWriter.TestPrettyPrintedOneElement;
var
  Doc: IJsonDocument;
begin
  Doc := TJsonDocument.CreateDictionary;
  Doc.Root.AddOrSetValue('name', 'value');
  Assert.AreEqual<JsonString>('{'#10'  "name" : "value"'#10'}', Doc.ToJson(True));
end;

procedure TestJsonWriter.TestPrettyPrintedTwoElements;
var
  Doc: IJsonDocument;
begin
  Doc := TJsonDocument.CreateDictionary;
  Doc.Root.AddOrSetValue('a', 'x');
  Doc.Root.AddOrSetValue('b', 'y');
  Assert.AreEqual<JsonString>('{'#10'  "a" : "x",'#10'  "b" : "y"'#10'}', Doc.ToJson(True));
end;

procedure TestJsonWriter.TestSingleString;
var
  Doc: IJsonDocument;
begin
  Doc := TJsonDocument.CreateDictionary;
  Doc.Root.AddOrSetValue('abc', 'xyz');
  Assert.AreEqual<JsonString>('{ "abc" : "xyz" }', Doc.ToJson(False));
end;

procedure TestJsonWriter.TestString;

  procedure Test(const AValue, AExpected: JsonString);
  var
    Json, Recon: JsonString;
    Doc: IJsonDocument;
  begin
    Doc := TJsonDocument.CreateArray;
    Doc.Root.Add(AValue);
    Json := Doc.Root.ToJson;
    Assert.AreEqual(AExpected, Copy(Json, Low(JsonString) + 1, Length(Json) - 2));

    Doc := nil;
    Doc := TJsonDocument.Parse(Json);
    Recon := Doc.Root.Items[0];

    Assert.AreEqual(AValue, Recon);
  end;

begin
  Test('', '""');
  Test(' ', '" "');
  Test('a', '"a"');
  Test('ab', '"ab"');
  Test('abc', '"abc"');
  Test('abc'#0'def', '"abc\u0000def"');
  Test('''', '"''"');
  Test('"', '"\""');
  Test(#0, '"\u0000"');
  Test(#7, '"\u0007"');
  Test(#8, '"\b"');
  Test(#12, '"\f"');
  Test(#10, '"\n"');
  Test(#13, '"\r"');
  Test(#9, '"\t"');
  Test(#11, '"\u000b"');
  Test(#$0080, '"\u0080"');
  Test(#$0080#$0081, '"\u0080\u0081"');
  Test(#$0080#$0081#$0082, '"\u0080\u0081\u0082"');
end;

{ TestJsonData }

procedure TestJsonData.TestJsonFile(const ABaseFilename: String);
{ These tests originate from JsonCpp:
  https://github.com/open-source-parsers/jsoncpp }
var
  JsonFilename, ExpectedFilename, Expected, Actual: String;
  Json: JsonString;
  Doc: IJsonDocument;
  Builder: TStringBuilder;
begin
  JsonFilename := 'data/' + ABaseFilename + '.json';
  ExpectedFilename := 'data/' + ABaseFilename + '.expected';

  { Wrap test string in array to create valid document. }
  Json := '[' + LoadTestString(JsonFilename) + ']';
  Doc := TJsonDocument.Parse(Json);
  Assert.IsNotNull(Doc);

  Builder := TStringBuilder.Create;
  try
    { Extract first element from array (wrapped earlier) }
    WriteValueTree(Builder, Doc.Root.Items[0]);
    Actual := Trim(String(Builder.ToString));
  finally
    Builder.Free;
  end;

  Expected := String(LoadTestString(ExpectedFilename));
  Actual := Actual.Replace(#13#10, #10, [rfReplaceAll]).Trim;
  Expected := Expected.Replace(#13#10, #10, [rfReplaceAll]).Trim;
  Assert.AreEqual(Expected, Actual);
end;

procedure TestJsonData.test_array_01;
begin
  TestJsonFile('test_array_01');
end;

procedure TestJsonData.test_array_02;
begin
  TestJsonFile('test_array_02');
end;

procedure TestJsonData.test_array_03;
begin
  TestJsonFile('test_array_03');
end;

procedure TestJsonData.test_array_04;
begin
  TestJsonFile('test_array_04');
end;

procedure TestJsonData.test_array_05;
begin
  TestJsonFile('test_array_05');
end;

procedure TestJsonData.test_array_06;
begin
  TestJsonFile('test_array_06');
end;

procedure TestJsonData.test_basic_01;
begin
  TestJsonFile('test_basic_01');
end;

procedure TestJsonData.test_basic_02;
begin
  TestJsonFile('test_basic_02');
end;

procedure TestJsonData.test_basic_03;
begin
  TestJsonFile('test_basic_03');
end;

procedure TestJsonData.test_basic_04;
begin
  TestJsonFile('test_basic_04');
end;

procedure TestJsonData.test_basic_05;
begin
  TestJsonFile('test_basic_05');
end;

procedure TestJsonData.test_basic_06;
begin
  TestJsonFile('test_basic_06');
end;

procedure TestJsonData.test_basic_07;
begin
  TestJsonFile('test_basic_07');
end;

procedure TestJsonData.test_complex_01;
begin
  TestJsonFile('test_complex_01');
end;

procedure TestJsonData.test_integer_01;
begin
  TestJsonFile('test_integer_01');
end;

procedure TestJsonData.test_integer_02;
begin
  TestJsonFile('test_integer_02');
end;

procedure TestJsonData.test_integer_03;
begin
  TestJsonFile('test_integer_03');
end;

procedure TestJsonData.test_integer_04;
begin
  TestJsonFile('test_integer_04');
end;

procedure TestJsonData.test_integer_05;
begin
  TestJsonFile('test_integer_05');
end;

procedure TestJsonData.test_large_01;
begin
  TestJsonFile('test_large_01');
end;

procedure TestJsonData.test_object_01;
begin
  TestJsonFile('test_object_01');
end;

procedure TestJsonData.test_object_02;
begin
  TestJsonFile('test_object_02');
end;

procedure TestJsonData.test_object_03;
begin
  TestJsonFile('test_object_03');
end;

procedure TestJsonData.test_object_04;
begin
  TestJsonFile('test_object_04');
end;

procedure TestJsonData.test_real_01;
begin
  TestJsonFile('test_real_01');
end;

procedure TestJsonData.test_real_02;
begin
  TestJsonFile('test_real_02');
end;

procedure TestJsonData.test_real_03;
begin
  TestJsonFile('test_real_03');
end;

procedure TestJsonData.test_real_04;
begin
  TestJsonFile('test_real_04');
end;

procedure TestJsonData.test_real_05;
begin
  TestJsonFile('test_real_05');
end;

procedure TestJsonData.test_real_06;
begin
  TestJsonFile('test_real_06');
end;

procedure TestJsonData.test_real_07;
begin
  TestJsonFile('test_real_07');
end;

procedure TestJsonData.test_string_01;
begin
  TestJsonFile('test_string_01');
end;

procedure TestJsonData.test_string_02;
begin
  TestJsonFile('test_string_02');
end;

procedure TestJsonData.test_string_unicode_01;
begin
  TestJsonFile('test_string_unicode_01');
end;

procedure TestJsonData.test_string_unicode_02;
begin
  TestJsonFile('test_string_unicode_02');
end;

procedure TestJsonData.test_string_unicode_03;
begin
  TestJsonFile('test_string_unicode_03');
end;

procedure TestJsonData.test_string_unicode_04;
begin
  TestJsonFile('test_string_unicode_04');
end;

procedure TestJsonData.test_string_unicode_05;
begin
  TestJsonFile('test_string_unicode_05');
end;

procedure TestJsonData.WriteValueTree(const ABuilder: TStringBuilder;
  const AValue: TJsonValue; const APath: String);

  procedure WriteLine(const AStr: String; const AArgs: array of const);
  begin
    ABuilder.Append(Format(AStr, AArgs)).AppendLine;
  end;

var
  I: Integer;
  Elements: TArray<TJsonElement>;
  Suffix: String;
begin
  case AValue.ValueType of
    TJsonValueType.Null:
      WriteLine('%s=null', [APath]);

    TJsonValueType.Ordinal:
      WriteLine('%s=%d', [APath, AValue.ToInt64]);

    TJsonValueType.Float:
      WriteLine('%s=%.16g', [APath, AValue.ToDouble]);

    TJsonValueType.String:
      WriteLine('%s="%s"', [APath, AValue.ToString]);

    TJsonValueType.Boolean:
      if AValue.ToBoolean then
        WriteLine('%s=true', [APath])
      else
        WriteLine('%s=false', [APath]);

    TJsonValueType.&Array:
      begin
        WriteLine('%s=[]', [APath]);
        for I := 0 to AValue.Count - 1 do
          WriteValueTree(ABuilder, AValue.Items[I], Format('%s[%d]', [APath, I]));
      end;

    TJsonValueType.Dictionary:
      begin
        WriteLine('%s={}', [APath]);
        SetLength(Elements, AValue.Count);
        for I := 0 to AValue.Count - 1 do
          Elements[I] := AValue.Elements[I]^;
        TArray.Sort<TJsonElement>(Elements, TComparer<TJsonElement>.Construct(
          function (const ALeft, ARight: TJsonElement): Integer
          begin
            Result := CompareText(String(ALeft.Name), String(ARight.Name));
          end));

        if (APath <> '') and (APath[Length(APath) - 1 + Low(APath)] = '.') then
          Suffix := ''
        else
          Suffix := '.';

        for I := 0 to Length(Elements) - 1 do
          WriteValueTree(ABuilder, Elements[I].Value, APath + Suffix + String(Elements[I].Name));
      end;
  end;
end;

{ TestJsonChecker }

procedure TestJsonChecker.TestFail(const AFilename: String; const AErrorLine,
  AErrorColumn: Integer);
var
  Json: JsonString;
begin
  Json := LoadTestString('jsonchecker/' + AFilename);
  try
    TJsonDocument.Parse(Json);
  except
    on E: EJsonParserError do
    begin
      Assert.AreEqual(AErrorLine, E.LineNumber);
      Assert.AreEqual(AErrorColumn, E.ColumnNumber);
      Exit;
    end
    else
      raise;
  end;
  Assert.Fail('EJsonParserError exception expected');
end;

procedure TestJsonChecker.TestPass(const AFilename: String);
var
  Doc: IJsonDocument;
begin
  Doc := TJsonDocument.Parse(LoadTestString('jsonchecker/' + AFilename));
  Assert.IsFalse(Doc.Root.IsNull);
end;

procedure TestJsonChecker.test_fail1;
begin
  TestFail('fail1.json', 1, 1);
end;

procedure TestJsonChecker.test_fail10;
begin
  // We allow data after end of document
  TestPass('fail10.json');
end;

procedure TestJsonChecker.test_fail11;
begin
  TestFail('fail11.json', 1, 26);
end;

procedure TestJsonChecker.test_fail12;
begin
  TestFail('fail12.json', 1, 24);
end;

procedure TestJsonChecker.test_fail13;
begin
  // We allow numbers with leading zero's
  TestPass('fail13.json');
end;

procedure TestJsonChecker.test_fail14;
begin
  TestFail('fail14.json', 1, 27);
end;

procedure TestJsonChecker.test_fail15;
begin
  TestFail('fail15.json', 1, 30);
end;

procedure TestJsonChecker.test_fail16;
begin
  TestFail('fail16.json', 1, 2);
end;

procedure TestJsonChecker.test_fail17;
begin
  TestFail('fail17.json', 1, 30);
end;

procedure TestJsonChecker.test_fail18;
begin
  // We allow unlimited nesting
  TestPass('fail18.json');
end;

procedure TestJsonChecker.test_fail19;
begin
  TestFail('fail19.json', 1, 18);
end;

procedure TestJsonChecker.test_fail2;
begin
  TestFail('fail2.json', 1, 18);
end;

procedure TestJsonChecker.test_fail20;
begin
  TestFail('fail20.json', 1, 17);
end;

procedure TestJsonChecker.test_fail21;
begin
  TestFail('fail21.json', 1, 26);
end;

procedure TestJsonChecker.test_fail22;
begin
  TestFail('fail22.json', 1, 26);
end;

procedure TestJsonChecker.test_fail23;
begin
  TestFail('fail23.json', 1, 15);
end;

procedure TestJsonChecker.test_fail24;
begin
  TestFail('fail24.json', 1, 2);
end;

procedure TestJsonChecker.test_fail25;
begin
  // We allow tabs in strings
  TestPass('fail25.json');
end;

procedure TestJsonChecker.test_fail26;
begin
  TestFail('fail26.json', 1, 7);
end;

procedure TestJsonChecker.test_fail27;
begin
  // We allow line breaks in strings
  TestPass('fail27.json');
end;

procedure TestJsonChecker.test_fail28;
begin
  TestFail('fail28.json', 1, 8);
end;

procedure TestJsonChecker.test_fail29;
begin
  TestFail('fail29.json', 1, 2);
end;

procedure TestJsonChecker.test_fail3;
begin
  // we allow unquoted keys
  TestPass('fail3.json');
end;

procedure TestJsonChecker.test_fail30;
begin
  TestFail('fail30.json', 1, 2);
end;

procedure TestJsonChecker.test_fail31;
begin
  TestFail('fail31.json', 1, 2);
end;

procedure TestJsonChecker.test_fail32;
begin
  TestFail('fail32.json', 1, 41);
end;

procedure TestJsonChecker.test_fail33;
begin
  TestFail('fail33.json', 1, 12);
end;

procedure TestJsonChecker.test_fail4;
begin
  // We allow trailing comma in arrays
  TestPass('fail4.json');
end;

procedure TestJsonChecker.test_fail5;
begin
  TestFail('fail5.json', 1, 23);
end;

procedure TestJsonChecker.test_fail6;
begin
  TestFail('fail6.json', 1, 5);
end;

procedure TestJsonChecker.test_fail7;
begin
  // We allow data after end of document
  TestPass('fail7.json');
end;

procedure TestJsonChecker.test_fail8;
begin
  // We allow data after end of document
  TestPass('fail8.json');
end;

procedure TestJsonChecker.test_fail9;
begin
  // We allow trailing comma in dictionaries
  TestPass('fail9.json');
end;

procedure TestJsonChecker.test_pass1;
begin
  TestPass('pass1.json');
end;

procedure TestJsonChecker.test_pass2;
begin
  TestPass('pass2.json');
end;

procedure TestJsonChecker.test_pass3;
begin
  TestPass('pass3.json');
end;

initialization
  ReportMemoryLeaksOnShutdown := True;
  TDUnitX.RegisterTestFixture(TestJsonReader);
  TDUnitX.RegisterTestFixture(TestJsonWriter);
  TDUnitX.RegisterTestFixture(TestJsonData);
  TDUnitX.RegisterTestFixture(TestJsonChecker);

end.
