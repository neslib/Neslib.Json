unit Tests.Neslib.Json;

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  Neslib.Json,
  Neslib.Json.IO,
  Neslib.Json.Types;

type
  TestJsonValue = class
  private
    FDoc: IJsonDocument;
    FValue: TJsonValue;
  public
    [Setup] procedure Setup;
    [Teardown] procedure Teardown;
    [Test] procedure TestImplicitToBoolean;
    [Test] procedure TestImplicitToInt32;
    [Test] procedure TestImplicitToInt64;
    [Test] procedure TestImplicitToDouble;
    [Test] procedure TestImplicitToString;
    [Test] procedure TestToBoolean;
    [Test] procedure TestToInt32;
    [Test] procedure TestToInt64;
    [Test] procedure TestToDouble;
    [Test] procedure TestToString;
    [Test] procedure TestToJson;
    [Test] procedure TestIntLayout;
    [Test] procedure TestEqual;
    [Test] procedure TestJsonType;
    [Test] procedure TestIsNull;
    [Test] procedure TestIsBoolean;
    [Test] procedure TestIsOrdinal;
    [Test] procedure TestIsFloat;
    [Test] procedure TestIsNumeric;
    [Test] procedure TestIsString;
    [Test] procedure TestIsArray;
    [Test] procedure TestIsDictionary;

    [Test] procedure TestIllegalAdd;
    [Test] procedure TestNonExistingItem;

    [Test] procedure TestSetGet;
    [Test] procedure TestIndexOfName;
    [Test] procedure TestContains;
    [Test] procedure TestRemove;
    [Test] procedure TestTryGetValue;
    [Test] procedure TestNonExistingValue;
    [Test] procedure TestElement;

    [Test] procedure TestClear;
    [Test] procedure TestDelete;
    [Test] procedure TestCount;

    [Test] procedure TestIndexers;
  end;

implementation

const
  { These MUST match the values of the private constants in TJsonValue }
  TYPE_BITS = 2;
  TYPE_MASK = (1 shl TYPE_BITS) - 1;
  TYPE_INT  = 1;
  TYPE_HEAP = 3;

{ TestJsonValue }

procedure TestJsonValue.Setup;
var
  V: TJsonValue;
begin
  FDoc := TJsonDocument.CreateArray;
  FValue := FDoc.Root;

  { 0} FValue.AddNull;
  { 1} FValue.Add(False);
  { 2} FValue.Add(True);

  { 3} FValue.Add(-$80000000);
  { 4} FValue.Add(-$20000001);
  { 5} FValue.Add(-$20000000);
  { 6} FValue.Add(0);
  { 7} FValue.Add($1FFFFFFF);
  { 8} FValue.Add($20000000);
  { 9} FValue.Add($7FFFFFFF);

  {10} FValue.Add(-$8000000000000000);
  {11} FValue.Add(-$2000000000000001);
  {12} FValue.Add(-$2000000000000000);
  {13} FValue.Add($1FFFFFFFFFFFFFFF);
  {14} FValue.Add($2000000000000000);
  {15} FValue.Add($7FFFFFFFFFFFFFFF);

  {16} FValue.Add(-123.25);
  {17} FValue.Add(0.0);
  {18} FValue.Add(987.75);

  {19} FValue.Add('');
  {20} FValue.Add('foo');
  {21} FValue.Add('42');
  {22} FValue.Add('-4.5');

  {23} FValue.AddArray;

  {24} V := FValue.AddArray;
  V.Add(42);
  V.Add(True);
  V.Add('foo');
  V := V.AddArray;
  V.Add(4.125);
  V.AddNull;

  {25} FValue.AddDictionary;

  {26} V := FValue.AddDictionary;
  V.AddOrSetValue('val1', 42);
  V.AddOrSetValue('val2', 3.5);
  V.AddOrSetValue('val3', 'foo');
end;

procedure TestJsonValue.Teardown;
begin
  FDoc := nil;
end;

procedure TestJsonValue.TestClear;
begin
  // Array
  Assert.AreEqual(4, FValue.Items[24].Count);
  FValue.Items[24].Clear;
  Assert.AreEqual(0, FValue.Items[24].Count);

  // Dictionary
  Assert.AreEqual(3, FValue.Items[26].Count);
  FValue.Items[26].Clear;
  Assert.AreEqual(0, FValue.Items[26].Count);

  // Root
  Assert.AreEqual(27, FValue.Count);
  FValue.Clear;
  Assert.AreEqual(0, FValue.Count);

  Assert.WillRaise(
    procedure
    begin
      FValue.Items[0].Clear;
    end, EInvalidOperation);
end;

procedure TestJsonValue.TestContains;
var
  D: TJsonValue;
begin
  D := FValue.Items[26];
  Assert.IsFalse(D.Contains('foo'));
  Assert.IsTrue(D.Contains('val1'));
  Assert.IsTrue(D.Contains('val2'));
  Assert.IsTrue(D.Contains('val3'));

  Assert.WillRaise(
    procedure
    begin
      FValue.Items[0].Contains('foo');
    end, EInvalidOperation);

  Assert.WillRaise(
    procedure
    begin
      FValue.Items[24].Contains('foo');
    end, EInvalidOperation);
end;

procedure TestJsonValue.TestCount;
begin
  Assert.AreEqual(27, FValue.Count);
  Assert.AreEqual(0, FValue.Items[0].Count);
  Assert.AreEqual(4, FValue.Items[24].Count);
  Assert.AreEqual(3, FValue.Items[26].Count);
  Assert.AreEqual(0, FValue.Items[999].Count);
end;

procedure TestJsonValue.TestDelete;
begin
  // Array
  Assert.AreEqual(4, FValue.Items[24].Count);
  Assert.WillRaise(
    procedure
    begin
      FValue.Items[24].Delete(4);
    end, EArgumentOutOfRangeException);
  FValue.Items[24].Delete(3);
  Assert.AreEqual(3, FValue.Items[24].Count);

  // Dictionary
  Assert.AreEqual(3, FValue.Items[26].Count);
  Assert.WillRaise(
    procedure
    begin
      FValue.Items[26].Delete(3);
    end, EArgumentOutOfRangeException);
  FValue.Items[26].Delete(2);
  Assert.AreEqual(2, FValue.Items[26].Count);

  // Root
  Assert.AreEqual(27, FValue.Count);
  FValue.Delete(5);
  Assert.AreEqual(26, FValue.Count);

  Assert.WillRaise(
    procedure
    begin
      FValue.Items[0].Delete(0);
    end, EInvalidOperation);
end;

procedure TestJsonValue.TestElement;
var
  D: TJsonValue;
  E: PJsonElement;
begin
  E := FValue.Items[0].Elements[999];
  Assert.AreEqual<JsonString>('', E.Name);
  Assert.IsTrue(E.Value.IsNull);

  D := FValue.Items[26];

  E := D.Elements[-1];
  Assert.AreEqual<JsonString>('', E.Name);
  Assert.IsTrue(E.Value.IsNull);

  E := D.Elements[0];
  Assert.AreEqual<JsonString>('val1', E.Name);
  Assert.AreEqual<Int32>(42, E.Value);

  E := D.Elements[1];
  Assert.AreEqual<JsonString>('val2', E.Name);
  Assert.AreEqual<Double>(3.5, E.Value);

  E := D.Elements[2];
  Assert.AreEqual<JsonString>('val3', E.Name);
  Assert.AreEqual<JsonString>('foo', E.Value);
end;

procedure TestJsonValue.TestEqual;
var
  V, Sub: TJsonValue;
begin
  // Null <> False
  Assert.IsFalse(FValue.Items[0] = FValue.Items[1]);
  Assert.IsTrue(FValue.Items[0] <> FValue.Items[1]);

  // 0 <> 0.0
  Assert.IsFalse(FValue.Items[6] = FValue.Items[17]);

  // 'foo' = 'foo'
  Assert.IsTrue(FValue.Items[20] = FValue.Items[24].Items[2]);
  Assert.IsTrue(FValue.Items[20] = FValue.Items[26].Values['val3']);

  // Same objects
  Assert.IsTrue(FValue.Items[24] = FValue.Items[24]);

  // Different types
  Assert.IsFalse(FValue.Items[24] = FValue.Items[26]);

  // Different objects, same values
  V := FValue.AddArray;
  V.Add(42);
  V.Add(True);
  V.Add('foo');
  Sub := V.AddArray;
  Sub.Add(4.125);
  Sub.AddNull;
  Assert.IsTrue(FValue.Items[24] = V);

  V.Delete(1);
  Assert.IsFalse(FValue.Items[24] = V);
end;

procedure TestJsonValue.TestIllegalAdd;
begin
  { The Add* methods are already tested elsewhere.
    Here we check invalid adds. }
  Assert.WillRaise(
    procedure
    begin
      FValue.Items[0].Add(1);
    end, EInvalidOperation);

  Assert.WillNotRaise(
    procedure
    begin
      FValue.Items[23].Add(1);
    end, EInvalidOperation);

  Assert.WillRaise(
    procedure
    begin
      FValue.Items[25].Add(1);
    end, EInvalidOperation);
end;

procedure TestJsonValue.TestImplicitToBoolean;
begin
  Assert.IsFalse(FValue.Items[0]);
  Assert.IsFalse(FValue.Items[1]);
  Assert.IsTrue(FValue.Items[2]);
  Assert.IsTrue(FValue.Items[3]);
  Assert.IsTrue(FValue.Items[4]);
  Assert.IsTrue(FValue.Items[5]);
  Assert.IsFalse(FValue.Items[6]);
  Assert.IsTrue(FValue.Items[7]);
  Assert.IsTrue(FValue.Items[8]);
  Assert.IsTrue(FValue.Items[9]);
  Assert.IsTrue(FValue.Items[10]);
  Assert.IsTrue(FValue.Items[11]);
  Assert.IsTrue(FValue.Items[12]);
  Assert.IsTrue(FValue.Items[13]);
  Assert.IsTrue(FValue.Items[14]);
  Assert.IsTrue(FValue.Items[15]);
  Assert.IsTrue(FValue.Items[16]);
  Assert.IsFalse(FValue.Items[17]);
  Assert.IsTrue(FValue.Items[18]);
  Assert.IsFalse(FValue.Items[19]);
  Assert.IsTrue(FValue.Items[20]);
  Assert.IsTrue(FValue.Items[21]);
  Assert.IsTrue(FValue.Items[22]);
  Assert.IsFalse(FValue.Items[23]);
  Assert.IsFalse(FValue.Items[24]);
  Assert.IsFalse(FValue.Items[25]);
  Assert.IsFalse(FValue.Items[26]);
end;

procedure TestJsonValue.TestImplicitToDouble;
begin
  Assert.AreEqual<Double>(0, FValue.Items[0]);
  Assert.AreEqual<Double>(0, FValue.Items[1]);
  Assert.AreEqual<Double>(1, FValue.Items[2]);
  Assert.AreEqual<Double>(-$80000000, FValue.Items[3]);
  Assert.AreEqual<Double>(-$20000001, FValue.Items[4]);
  Assert.AreEqual<Double>(-$20000000, FValue.Items[5]);
  Assert.AreEqual<Double>(0, FValue.Items[6]);
  Assert.AreEqual<Double>($1FFFFFFF, FValue.Items[7]);
  Assert.AreEqual<Double>($20000000, FValue.Items[8]);
  Assert.AreEqual<Double>($7FFFFFFF, FValue.Items[9]);
  Assert.AreEqual<Double>(-$8000000000000000, FValue.Items[10]);
  Assert.AreEqual<Double>(-$2000000000000001, FValue.Items[11]);
  Assert.AreEqual<Double>(-$2000000000000000, FValue.Items[12]);
  Assert.AreEqual<Double>($1FFFFFFFFFFFFFFF, FValue.Items[13]);
  Assert.AreEqual<Double>($2000000000000000, FValue.Items[14]);
  Assert.AreEqual<Double>($7FFFFFFFFFFFFFFF, FValue.Items[15]);
  Assert.AreEqual<Double>(-123.25, FValue.Items[16]);
  Assert.AreEqual<Double>(0, FValue.Items[17]);
  Assert.AreEqual<Double>(987.75, FValue.Items[18]);
  Assert.AreEqual<Double>(0, FValue.Items[19]);
  Assert.AreEqual<Double>(0, FValue.Items[20]);
  Assert.AreEqual<Double>(42, FValue.Items[21]);
  Assert.AreEqual<Double>(-4.5, FValue.Items[22]);
  Assert.AreEqual<Double>(0, FValue.Items[23]);
  Assert.AreEqual<Double>(0, FValue.Items[24]);
  Assert.AreEqual<Double>(0, FValue.Items[25]);
  Assert.AreEqual<Double>(0, FValue.Items[26]);
end;

procedure TestJsonValue.TestImplicitToInt32;
begin
  Assert.AreEqual<Int32>(0, FValue.Items[0]);
  Assert.AreEqual<Int32>(0, FValue.Items[1]);
  Assert.AreEqual<Int32>(1, FValue.Items[2]);
  Assert.AreEqual<Int32>(-$80000000, FValue.Items[3]);
  Assert.AreEqual<Int32>(-$20000001, FValue.Items[4]);
  Assert.AreEqual<Int32>(-$20000000, FValue.Items[5]);
  Assert.AreEqual<Int32>(0, FValue.Items[6]);
  Assert.AreEqual<Int32>($1FFFFFFF, FValue.Items[7]);
  Assert.AreEqual<Int32>($20000000, FValue.Items[8]);
  Assert.AreEqual<Int32>($7FFFFFFF, FValue.Items[9]);
  Assert.AreEqual<Int32>(0, FValue.Items[10]);
  Assert.AreEqual<Int32>(-1, FValue.Items[11]);
  Assert.AreEqual<Int32>(0, FValue.Items[12]);
  Assert.AreEqual<Int32>(-1, FValue.Items[13]);
  Assert.AreEqual<Int32>(0, FValue.Items[14]);
  Assert.AreEqual<Int32>(-1, FValue.Items[15]);
  Assert.AreEqual<Int32>(-123, FValue.Items[16]);
  Assert.AreEqual<Int32>(0, FValue.Items[17]);
  Assert.AreEqual<Int32>(987, FValue.Items[18]);
  Assert.AreEqual<Int32>(0, FValue.Items[19]);
  Assert.AreEqual<Int32>(0, FValue.Items[20]);
  Assert.AreEqual<Int32>(42, FValue.Items[21]);
  Assert.AreEqual<Int32>(0, FValue.Items[22]);
  Assert.AreEqual<Int32>(0, FValue.Items[23]);
  Assert.AreEqual<Int32>(0, FValue.Items[24]);
  Assert.AreEqual<Int32>(0, FValue.Items[25]);
  Assert.AreEqual<Int32>(0, FValue.Items[26]);
end;

procedure TestJsonValue.TestImplicitToInt64;
begin
  Assert.AreEqual<Int64>(0, FValue.Items[0]);
  Assert.AreEqual<Int64>(0, FValue.Items[1]);
  Assert.AreEqual<Int64>(1, FValue.Items[2]);
  Assert.AreEqual<Int64>(-$80000000, FValue.Items[3]);
  Assert.AreEqual<Int64>(-$20000001, FValue.Items[4]);
  Assert.AreEqual<Int64>(-$20000000, FValue.Items[5]);
  Assert.AreEqual<Int64>(0, FValue.Items[6]);
  Assert.AreEqual<Int64>($1FFFFFFF, FValue.Items[7]);
  Assert.AreEqual<Int64>($20000000, FValue.Items[8]);
  Assert.AreEqual<Int64>($7FFFFFFF, FValue.Items[9]);
  Assert.AreEqual<Int64>(-$8000000000000000, FValue.Items[10]);
  Assert.AreEqual<Int64>(-$2000000000000001, FValue.Items[11]);
  Assert.AreEqual<Int64>(-$2000000000000000, FValue.Items[12]);
  Assert.AreEqual<Int64>($1FFFFFFFFFFFFFFF, FValue.Items[13]);
  Assert.AreEqual<Int64>($2000000000000000, FValue.Items[14]);
  Assert.AreEqual<Int64>($7FFFFFFFFFFFFFFF, FValue.Items[15]);
  Assert.AreEqual<Int64>(-123, FValue.Items[16]);
  Assert.AreEqual<Int64>(0, FValue.Items[17]);
  Assert.AreEqual<Int64>(987, FValue.Items[18]);
  Assert.AreEqual<Int64>(0, FValue.Items[19]);
  Assert.AreEqual<Int64>(0, FValue.Items[20]);
  Assert.AreEqual<Int64>(42, FValue.Items[21]);
  Assert.AreEqual<Int64>(0, FValue.Items[22]);
  Assert.AreEqual<Int64>(0, FValue.Items[23]);
  Assert.AreEqual<Int64>(0, FValue.Items[24]);
  Assert.AreEqual<Int64>(0, FValue.Items[25]);
  Assert.AreEqual<Int64>(0, FValue.Items[26]);
end;

procedure TestJsonValue.TestImplicitToString;
begin
  Assert.AreEqual<JsonString>('', FValue.Items[0]);
  Assert.AreEqual<JsonString>('false', FValue.Items[1]);
  Assert.AreEqual<JsonString>('true', FValue.Items[2]);
  Assert.AreEqual<JsonString>('-2147483648', FValue.Items[3]);
  Assert.AreEqual<JsonString>('-536870913', FValue.Items[4]);
  Assert.AreEqual<JsonString>('-536870912', FValue.Items[5]);
  Assert.AreEqual<JsonString>('0', FValue.Items[6]);
  Assert.AreEqual<JsonString>('536870911', FValue.Items[7]);
  Assert.AreEqual<JsonString>('536870912', FValue.Items[8]);
  Assert.AreEqual<JsonString>('2147483647', FValue.Items[9]);
  Assert.AreEqual<JsonString>('-9223372036854775808', FValue.Items[10]);
  Assert.AreEqual<JsonString>('-2305843009213693953', FValue.Items[11]);
  Assert.AreEqual<JsonString>('-2305843009213693952', FValue.Items[12]);
  Assert.AreEqual<JsonString>('2305843009213693951', FValue.Items[13]);
  Assert.AreEqual<JsonString>('2305843009213693952', FValue.Items[14]);
  Assert.AreEqual<JsonString>('9223372036854775807', FValue.Items[15]);
  Assert.AreEqual<JsonString>('-123.25', FValue.Items[16]);
  Assert.AreEqual<JsonString>('0', FValue.Items[17]);
  Assert.AreEqual<JsonString>('987.75', FValue.Items[18]);
  Assert.AreEqual<JsonString>('', FValue.Items[19]);
  Assert.AreEqual<JsonString>('foo', FValue.Items[20]);
  Assert.AreEqual<JsonString>('42', FValue.Items[21]);
  Assert.AreEqual<JsonString>('-4.5', FValue.Items[22]);
  Assert.AreEqual<JsonString>('', FValue.Items[23]);
  Assert.AreEqual<JsonString>('', FValue.Items[24]);
  Assert.AreEqual<JsonString>('', FValue.Items[25]);
  Assert.AreEqual<JsonString>('', FValue.Items[26]);
end;

procedure TestJsonValue.TestIndexers;
var
  V1, V2: TJsonValue;
  D: TJsonValue;
begin
  V1 := FValue.Items[20];
  Assert.AreEqual('foo', V1.ToString);

  V2 := FValue[20];
  Assert.AreEqual('foo', V2.ToString);

  D := FValue[26];
  Assert.IsTrue(D.IsDictionary);

  V1 := D.Values['val1'];
  Assert.AreEqual<Integer>(42, V1.ToInteger);

  V2 := D['val1'];
  Assert.AreEqual<Integer>(42, V2.ToInteger);
end;

procedure TestJsonValue.TestIndexOfName;
var
  D: TJsonValue;
begin
  D := FValue.Items[26];
  Assert.AreEqual(-1, D.IndexOfName('foo'));
  Assert.AreEqual(0, D.IndexOfName('val1'));
  Assert.AreEqual(1, D.IndexOfName('val2'));
  Assert.AreEqual(2, D.IndexOfName('val3'));

  Assert.WillRaise(
    procedure
    begin
      FValue.Items[0].IndexOfName('foo');
    end, EInvalidOperation);

  Assert.WillRaise(
    procedure
    begin
      FValue.Items[24].IndexOfName('foo');
    end, EInvalidOperation);
end;

procedure TestJsonValue.TestIntLayout;
var
  V: TJsonValue;
  U: UIntPtr absolute V;
begin
  V := FValue.Items[3];
  {$IFDEF CPU32BITS}
  Assert.IsTrue((U and TYPE_MASK) = TYPE_HEAP);
  {$ELSE}
  Assert.IsTrue((U and TYPE_MASK) = TYPE_INT);
  {$ENDIF}

  V := FValue.Items[4];
  {$IFDEF CPU32BITS}
  Assert.IsTrue((U and TYPE_MASK) = TYPE_HEAP);
  {$ELSE}
  Assert.IsTrue((U and TYPE_MASK) = TYPE_INT);
  {$ENDIF}

  V := FValue.Items[5];
  Assert.IsTrue((U and TYPE_MASK) = TYPE_INT);

  V := FValue.Items[7];
  Assert.IsTrue((U and TYPE_MASK) = TYPE_INT);

  V := FValue.Items[8];
  {$IFDEF CPU32BITS}
  Assert.IsTrue((U and TYPE_MASK) = TYPE_HEAP);
  {$ELSE}
  Assert.IsTrue((U and TYPE_MASK) = TYPE_INT);
  {$ENDIF}

  V := FValue.Items[9];
  {$IFDEF CPU32BITS}
  Assert.IsTrue((U and TYPE_MASK) = TYPE_HEAP);
  {$ELSE}
  Assert.IsTrue((U and TYPE_MASK) = TYPE_INT);
  {$ENDIF}

  V := FValue.Items[10];
  Assert.IsTrue((U and TYPE_MASK) = TYPE_HEAP);

  V := FValue.Items[11];
  Assert.IsTrue((U and TYPE_MASK) = TYPE_HEAP);

  V := FValue.Items[12];
  {$IFDEF CPU32BITS}
  Assert.IsTrue((U and TYPE_MASK) = TYPE_HEAP);
  {$ELSE}
  Assert.IsTrue((U and TYPE_MASK) = TYPE_INT);
  {$ENDIF}

  V := FValue.Items[13];
  {$IFDEF CPU32BITS}
  Assert.IsTrue((U and TYPE_MASK) = TYPE_HEAP);
  {$ELSE}
  Assert.IsTrue((U and TYPE_MASK) = TYPE_INT);
  {$ENDIF}

  V := FValue.Items[14];
  Assert.IsTrue((U and TYPE_MASK) = TYPE_HEAP);

  V := FValue.Items[15];
  Assert.IsTrue((U and TYPE_MASK) = TYPE_HEAP);
end;

procedure TestJsonValue.TestIsArray;
begin
  Assert.IsFalse(FValue.Items[0].IsArray);
  Assert.IsFalse(FValue.Items[1].IsArray);
  Assert.IsFalse(FValue.Items[2].IsArray);
  Assert.IsFalse(FValue.Items[3].IsArray);
  Assert.IsFalse(FValue.Items[4].IsArray);
  Assert.IsFalse(FValue.Items[5].IsArray);
  Assert.IsFalse(FValue.Items[6].IsArray);
  Assert.IsFalse(FValue.Items[7].IsArray);
  Assert.IsFalse(FValue.Items[8].IsArray);
  Assert.IsFalse(FValue.Items[9].IsArray);
  Assert.IsFalse(FValue.Items[10].IsArray);
  Assert.IsFalse(FValue.Items[11].IsArray);
  Assert.IsFalse(FValue.Items[12].IsArray);
  Assert.IsFalse(FValue.Items[13].IsArray);
  Assert.IsFalse(FValue.Items[14].IsArray);
  Assert.IsFalse(FValue.Items[15].IsArray);
  Assert.IsFalse(FValue.Items[16].IsArray);
  Assert.IsFalse(FValue.Items[17].IsArray);
  Assert.IsFalse(FValue.Items[18].IsArray);
  Assert.IsFalse(FValue.Items[19].IsArray);
  Assert.IsFalse(FValue.Items[20].IsArray);
  Assert.IsFalse(FValue.Items[21].IsArray);
  Assert.IsFalse(FValue.Items[22].IsArray);
  Assert.IsTrue(FValue.Items[23].IsArray);
  Assert.IsTrue(FValue.Items[24].IsArray);
  Assert.IsFalse(FValue.Items[25].IsArray);
  Assert.IsFalse(FValue.Items[26].IsArray);
end;

procedure TestJsonValue.TestIsBoolean;
begin
  Assert.IsFalse(FValue.Items[0].IsBoolean);
  Assert.IsTrue(FValue.Items[1].IsBoolean);
  Assert.IsTrue(FValue.Items[2].IsBoolean);
  Assert.IsFalse(FValue.Items[3].IsBoolean);
  Assert.IsFalse(FValue.Items[4].IsBoolean);
  Assert.IsFalse(FValue.Items[5].IsBoolean);
  Assert.IsFalse(FValue.Items[6].IsBoolean);
  Assert.IsFalse(FValue.Items[7].IsBoolean);
  Assert.IsFalse(FValue.Items[8].IsBoolean);
  Assert.IsFalse(FValue.Items[9].IsBoolean);
  Assert.IsFalse(FValue.Items[10].IsBoolean);
  Assert.IsFalse(FValue.Items[11].IsBoolean);
  Assert.IsFalse(FValue.Items[12].IsBoolean);
  Assert.IsFalse(FValue.Items[13].IsBoolean);
  Assert.IsFalse(FValue.Items[14].IsBoolean);
  Assert.IsFalse(FValue.Items[15].IsBoolean);
  Assert.IsFalse(FValue.Items[16].IsBoolean);
  Assert.IsFalse(FValue.Items[17].IsBoolean);
  Assert.IsFalse(FValue.Items[18].IsBoolean);
  Assert.IsFalse(FValue.Items[19].IsBoolean);
  Assert.IsFalse(FValue.Items[20].IsBoolean);
  Assert.IsFalse(FValue.Items[21].IsBoolean);
  Assert.IsFalse(FValue.Items[22].IsBoolean);
  Assert.IsFalse(FValue.Items[23].IsBoolean);
  Assert.IsFalse(FValue.Items[24].IsBoolean);
  Assert.IsFalse(FValue.Items[25].IsBoolean);
  Assert.IsFalse(FValue.Items[26].IsBoolean);
end;

procedure TestJsonValue.TestIsDictionary;
begin
  Assert.IsFalse(FValue.Items[0].IsDictionary);
  Assert.IsFalse(FValue.Items[1].IsDictionary);
  Assert.IsFalse(FValue.Items[2].IsDictionary);
  Assert.IsFalse(FValue.Items[3].IsDictionary);
  Assert.IsFalse(FValue.Items[4].IsDictionary);
  Assert.IsFalse(FValue.Items[5].IsDictionary);
  Assert.IsFalse(FValue.Items[6].IsDictionary);
  Assert.IsFalse(FValue.Items[7].IsDictionary);
  Assert.IsFalse(FValue.Items[8].IsDictionary);
  Assert.IsFalse(FValue.Items[9].IsDictionary);
  Assert.IsFalse(FValue.Items[10].IsDictionary);
  Assert.IsFalse(FValue.Items[11].IsDictionary);
  Assert.IsFalse(FValue.Items[12].IsDictionary);
  Assert.IsFalse(FValue.Items[13].IsDictionary);
  Assert.IsFalse(FValue.Items[14].IsDictionary);
  Assert.IsFalse(FValue.Items[15].IsDictionary);
  Assert.IsFalse(FValue.Items[16].IsDictionary);
  Assert.IsFalse(FValue.Items[17].IsDictionary);
  Assert.IsFalse(FValue.Items[18].IsDictionary);
  Assert.IsFalse(FValue.Items[19].IsDictionary);
  Assert.IsFalse(FValue.Items[20].IsDictionary);
  Assert.IsFalse(FValue.Items[21].IsDictionary);
  Assert.IsFalse(FValue.Items[22].IsDictionary);
  Assert.IsFalse(FValue.Items[23].IsDictionary);
  Assert.IsFalse(FValue.Items[24].IsDictionary);
  Assert.IsTrue(FValue.Items[25].IsDictionary);
  Assert.IsTrue(FValue.Items[26].IsDictionary);
end;

procedure TestJsonValue.TestIsFloat;
begin
  Assert.IsFalse(FValue.Items[0].IsFloat);
  Assert.IsFalse(FValue.Items[1].IsFloat);
  Assert.IsFalse(FValue.Items[2].IsFloat);
  Assert.IsFalse(FValue.Items[3].IsFloat);
  Assert.IsFalse(FValue.Items[4].IsFloat);
  Assert.IsFalse(FValue.Items[5].IsFloat);
  Assert.IsFalse(FValue.Items[6].IsFloat);
  Assert.IsFalse(FValue.Items[7].IsFloat);
  Assert.IsFalse(FValue.Items[8].IsFloat);
  Assert.IsFalse(FValue.Items[9].IsFloat);
  Assert.IsFalse(FValue.Items[10].IsFloat);
  Assert.IsFalse(FValue.Items[11].IsFloat);
  Assert.IsFalse(FValue.Items[12].IsFloat);
  Assert.IsFalse(FValue.Items[13].IsFloat);
  Assert.IsFalse(FValue.Items[14].IsFloat);
  Assert.IsFalse(FValue.Items[15].IsFloat);
  Assert.IsTrue(FValue.Items[16].IsFloat);
  Assert.IsTrue(FValue.Items[17].IsFloat);
  Assert.IsTrue(FValue.Items[18].IsFloat);
  Assert.IsFalse(FValue.Items[19].IsFloat);
  Assert.IsFalse(FValue.Items[20].IsFloat);
  Assert.IsFalse(FValue.Items[21].IsFloat);
  Assert.IsFalse(FValue.Items[22].IsFloat);
  Assert.IsFalse(FValue.Items[23].IsFloat);
  Assert.IsFalse(FValue.Items[24].IsFloat);
  Assert.IsFalse(FValue.Items[25].IsFloat);
  Assert.IsFalse(FValue.Items[26].IsFloat);
end;

procedure TestJsonValue.TestIsNull;
begin
  Assert.IsTrue(FValue.Items[0].IsNull);
  Assert.IsFalse(FValue.Items[1].IsNull);
  Assert.IsFalse(FValue.Items[2].IsNull);
  Assert.IsFalse(FValue.Items[3].IsNull);
  Assert.IsFalse(FValue.Items[4].IsNull);
  Assert.IsFalse(FValue.Items[5].IsNull);
  Assert.IsFalse(FValue.Items[6].IsNull);
  Assert.IsFalse(FValue.Items[7].IsNull);
  Assert.IsFalse(FValue.Items[8].IsNull);
  Assert.IsFalse(FValue.Items[9].IsNull);
  Assert.IsFalse(FValue.Items[10].IsNull);
  Assert.IsFalse(FValue.Items[11].IsNull);
  Assert.IsFalse(FValue.Items[12].IsNull);
  Assert.IsFalse(FValue.Items[13].IsNull);
  Assert.IsFalse(FValue.Items[14].IsNull);
  Assert.IsFalse(FValue.Items[15].IsNull);
  Assert.IsFalse(FValue.Items[16].IsNull);
  Assert.IsFalse(FValue.Items[17].IsNull);
  Assert.IsFalse(FValue.Items[18].IsNull);
  Assert.IsFalse(FValue.Items[19].IsNull);
  Assert.IsFalse(FValue.Items[20].IsNull);
  Assert.IsFalse(FValue.Items[21].IsNull);
  Assert.IsFalse(FValue.Items[22].IsNull);
  Assert.IsFalse(FValue.Items[23].IsNull);
  Assert.IsFalse(FValue.Items[24].IsNull);
  Assert.IsFalse(FValue.Items[25].IsNull);
  Assert.IsFalse(FValue.Items[26].IsNull);
end;

procedure TestJsonValue.TestIsNumeric;
begin
  Assert.IsFalse(FValue.Items[0].IsNumeric);
  Assert.IsFalse(FValue.Items[1].IsNumeric);
  Assert.IsFalse(FValue.Items[2].IsNumeric);
  Assert.IsTrue(FValue.Items[3].IsNumeric);
  Assert.IsTrue(FValue.Items[4].IsNumeric);
  Assert.IsTrue(FValue.Items[5].IsNumeric);
  Assert.IsTrue(FValue.Items[6].IsNumeric);
  Assert.IsTrue(FValue.Items[7].IsNumeric);
  Assert.IsTrue(FValue.Items[8].IsNumeric);
  Assert.IsTrue(FValue.Items[9].IsNumeric);
  Assert.IsTrue(FValue.Items[10].IsNumeric);
  Assert.IsTrue(FValue.Items[11].IsNumeric);
  Assert.IsTrue(FValue.Items[12].IsNumeric);
  Assert.IsTrue(FValue.Items[13].IsNumeric);
  Assert.IsTrue(FValue.Items[14].IsNumeric);
  Assert.IsTrue(FValue.Items[15].IsNumeric);
  Assert.IsTrue(FValue.Items[16].IsNumeric);
  Assert.IsTrue(FValue.Items[17].IsNumeric);
  Assert.IsTrue(FValue.Items[18].IsNumeric);
  Assert.IsFalse(FValue.Items[19].IsNumeric);
  Assert.IsFalse(FValue.Items[20].IsNumeric);
  Assert.IsFalse(FValue.Items[21].IsNumeric);
  Assert.IsFalse(FValue.Items[22].IsNumeric);
  Assert.IsFalse(FValue.Items[23].IsNumeric);
  Assert.IsFalse(FValue.Items[24].IsNumeric);
  Assert.IsFalse(FValue.Items[25].IsNumeric);
  Assert.IsFalse(FValue.Items[26].IsNumeric);
end;

procedure TestJsonValue.TestIsOrdinal;
begin
  Assert.IsFalse(FValue.Items[0].IsOrdinal);
  Assert.IsFalse(FValue.Items[1].IsOrdinal);
  Assert.IsFalse(FValue.Items[2].IsOrdinal);
  Assert.IsTrue(FValue.Items[3].IsOrdinal);
  Assert.IsTrue(FValue.Items[4].IsOrdinal);
  Assert.IsTrue(FValue.Items[5].IsOrdinal);
  Assert.IsTrue(FValue.Items[6].IsOrdinal);
  Assert.IsTrue(FValue.Items[7].IsOrdinal);
  Assert.IsTrue(FValue.Items[8].IsOrdinal);
  Assert.IsTrue(FValue.Items[9].IsOrdinal);
  Assert.IsTrue(FValue.Items[10].IsOrdinal);
  Assert.IsTrue(FValue.Items[11].IsOrdinal);
  Assert.IsTrue(FValue.Items[12].IsOrdinal);
  Assert.IsTrue(FValue.Items[13].IsOrdinal);
  Assert.IsTrue(FValue.Items[14].IsOrdinal);
  Assert.IsTrue(FValue.Items[15].IsOrdinal);
  Assert.IsFalse(FValue.Items[16].IsOrdinal);
  Assert.IsFalse(FValue.Items[17].IsOrdinal);
  Assert.IsFalse(FValue.Items[18].IsOrdinal);
  Assert.IsFalse(FValue.Items[19].IsOrdinal);
  Assert.IsFalse(FValue.Items[20].IsOrdinal);
  Assert.IsFalse(FValue.Items[21].IsOrdinal);
  Assert.IsFalse(FValue.Items[22].IsOrdinal);
  Assert.IsFalse(FValue.Items[23].IsOrdinal);
  Assert.IsFalse(FValue.Items[24].IsOrdinal);
  Assert.IsFalse(FValue.Items[25].IsOrdinal);
  Assert.IsFalse(FValue.Items[26].IsOrdinal);
end;

procedure TestJsonValue.TestIsString;
begin
  Assert.IsFalse(FValue.Items[0].IsString);
  Assert.IsFalse(FValue.Items[1].IsString);
  Assert.IsFalse(FValue.Items[2].IsString);
  Assert.IsFalse(FValue.Items[3].IsString);
  Assert.IsFalse(FValue.Items[4].IsString);
  Assert.IsFalse(FValue.Items[5].IsString);
  Assert.IsFalse(FValue.Items[6].IsString);
  Assert.IsFalse(FValue.Items[7].IsString);
  Assert.IsFalse(FValue.Items[8].IsString);
  Assert.IsFalse(FValue.Items[9].IsString);
  Assert.IsFalse(FValue.Items[10].IsString);
  Assert.IsFalse(FValue.Items[11].IsString);
  Assert.IsFalse(FValue.Items[12].IsString);
  Assert.IsFalse(FValue.Items[13].IsString);
  Assert.IsFalse(FValue.Items[14].IsString);
  Assert.IsFalse(FValue.Items[15].IsString);
  Assert.IsFalse(FValue.Items[16].IsString);
  Assert.IsFalse(FValue.Items[17].IsString);
  Assert.IsFalse(FValue.Items[18].IsString);
  Assert.IsTrue(FValue.Items[19].IsString);
  Assert.IsTrue(FValue.Items[20].IsString);
  Assert.IsTrue(FValue.Items[21].IsString);
  Assert.IsTrue(FValue.Items[22].IsString);
  Assert.IsFalse(FValue.Items[23].IsString);
  Assert.IsFalse(FValue.Items[24].IsString);
  Assert.IsFalse(FValue.Items[25].IsString);
  Assert.IsFalse(FValue.Items[26].IsString);
end;

procedure TestJsonValue.TestJsonType;
begin
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Null, FValue.Items[0].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Boolean, FValue.Items[1].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Boolean, FValue.Items[2].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Ordinal, FValue.Items[3].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Ordinal, FValue.Items[4].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Ordinal, FValue.Items[5].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Ordinal, FValue.Items[6].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Ordinal, FValue.Items[7].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Ordinal, FValue.Items[8].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Ordinal, FValue.Items[9].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Ordinal, FValue.Items[10].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Ordinal, FValue.Items[11].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Ordinal, FValue.Items[12].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Ordinal, FValue.Items[13].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Ordinal, FValue.Items[14].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Ordinal, FValue.Items[15].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Float, FValue.Items[16].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Float, FValue.Items[17].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Float, FValue.Items[18].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.String, FValue.Items[19].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.String, FValue.Items[20].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.String, FValue.Items[21].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.String, FValue.Items[22].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.&Array, FValue.Items[23].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.&Array, FValue.Items[24].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Dictionary, FValue.Items[25].ValueType);
  Assert.AreEqual<TJsonValueType>(TJsonValueType.Dictionary, FValue.Items[26].ValueType);
end;

procedure TestJsonValue.TestNonExistingItem;
begin
  { The Items[] property should never raise exceptions, but always return a
    Null item when not available. }
  Assert.IsTrue(FValue.Items[-1].IsNull);
  Assert.IsFalse(FValue.Items[10].IsNull);
  Assert.IsTrue(FValue.Items[999].IsNull);
  Assert.IsTrue(FValue.Items[1].Items[2].Items[3].Items[4].Items[5].IsNull);
end;

procedure TestJsonValue.TestNonExistingValue;
var
  D: TJsonValue;
begin
  D := FValue.Items[26];

  { The Values[] property should never raise exceptions, but always return a
    Null item when not available. }
  Assert.IsTrue(FValue.Values['does_not_exist'].IsNull);
  Assert.IsFalse(D.Values['val2'].IsNull);
  Assert.IsTrue(FValue.Values['a'].Values['b'].Values['c'].Values['d'].IsNull);
end;

procedure TestJsonValue.TestRemove;
var
  D: TJsonValue;
begin
  D := FValue.Items[26];
  Assert.AreEqual(3, D.Count);
  Assert.AreEqual<Int32>(42, D.Values['val1']);
  Assert.AreEqual<Double>(3.5, D.Values['val2']);
  Assert.IsFalse(D.Values['val2'].IsNull);
  Assert.AreEqual<JsonString>('foo', D.Values['val3']);

  D.Remove('foo');
  Assert.AreEqual(3, D.Count);
  D.Remove('val2');
  Assert.AreEqual(2, D.Count);
  Assert.AreEqual<Int32>(42, D.Values['val1']);
  Assert.IsTrue(D.Values['val2'].IsNull);
  Assert.AreEqual<JsonString>('foo', D.Values['val3']);

  Assert.WillRaise(
    procedure
    begin
      FValue.Items[0].Remove('foo');
    end, EInvalidOperation);

  Assert.WillRaise(
    procedure
    begin
      FValue.Items[24].Remove('foo');
    end, EInvalidOperation);
end;

procedure TestJsonValue.TestSetGet;
var
  D, A, S, V: TJsonValue;
begin
  D := FValue.AddDictionary;

  D.AddOrSetValue('bool', True);
  D.AddOrSetValue('str', 'foo');
  D.AddOrSetValue('dbl', Double(1.25));
  D.AddOrSetValue('sng', Single(-3.75));
  D.AddOrSetValue('i32', -123456);
  D.AddOrSetValue('u32', $FEDCBA98);
  D.AddOrSetValue('i64', -1234567890987);
  D.AddOrSetValue('u64', $FEDCBA9876543210);
  D.AddOrSetValue('val', 42);
  D.AddOrSetNull('nil');

  A := D.AddOrSetArray('arr');
  A.Add(1);
  A.Add(2);

  S := D.AddOrSetDictionary('dict');
  S.AddOrSetValue('foo', 1);
  S.AddOrSetValue('bar', 2);

  { Overwrite with different type }
  D.AddOrSetValue('val', 'bar');

  Assert.IsTrue(D.Values['bool']);
  Assert.AreEqual<JsonString>('foo', D.Values['str']);
  Assert.AreEqual<Double>(1.25, D.Values['dbl']);
  Assert.AreEqual<Double>(-3.75, D.Values['sng']);
  Assert.AreEqual<Int32>(-123456, D.Values['i32']);
  Assert.AreEqual<UInt32>($FEDCBA98, D.Values['u32']);
  Assert.AreEqual<Int64>(-1234567890987, D.Values['i64']);
  Assert.AreEqual<UInt64>($FEDCBA9876543210, D.Values['u64']);
  Assert.AreEqual<JsonString>('bar', D.Values['val']);
  Assert.IsTrue(D.Values['nil'].IsNull);

  V := D.Values['arr'];
  Assert.IsTrue(V.IsArray);
  Assert.AreEqual<Int32>(1, V.Items[0]);
  Assert.AreEqual<Int32>(2, V.Items[1]);

  V := D.Values['dict'];
  Assert.IsTrue(V.IsDictionary);
  Assert.AreEqual<Int32>(1, V.Values['foo']);
  Assert.AreEqual<Int32>(2, V.Values['bar']);

  Assert.WillRaise(
    procedure
    begin
      FValue.Items[0].AddOrSetValue('foo', 'bar');
    end, EInvalidOperation);

  Assert.WillRaise(
    procedure
    begin
      FValue.Items[24].AddOrSetValue('foo', 'bar');
    end, EInvalidOperation);
end;

procedure TestJsonValue.TestToBoolean;
begin
  Assert.IsFalse(FValue.Items[0].ToBoolean(True));
  Assert.IsFalse(FValue.Items[1].ToBoolean(True));
  Assert.IsTrue(FValue.Items[2].ToBoolean(True));
  Assert.IsTrue(FValue.Items[3].ToBoolean(True));
  Assert.IsTrue(FValue.Items[4].ToBoolean(True));
  Assert.IsTrue(FValue.Items[5].ToBoolean(True));
  Assert.IsFalse(FValue.Items[6].ToBoolean(True));
  Assert.IsTrue(FValue.Items[7].ToBoolean(True));
  Assert.IsTrue(FValue.Items[8].ToBoolean(True));
  Assert.IsTrue(FValue.Items[9].ToBoolean(True));
  Assert.IsTrue(FValue.Items[10].ToBoolean(True));
  Assert.IsTrue(FValue.Items[11].ToBoolean(True));
  Assert.IsTrue(FValue.Items[12].ToBoolean(True));
  Assert.IsTrue(FValue.Items[13].ToBoolean(True));
  Assert.IsTrue(FValue.Items[14].ToBoolean(True));
  Assert.IsTrue(FValue.Items[15].ToBoolean(True));
  Assert.IsTrue(FValue.Items[16].ToBoolean(True));
  Assert.IsFalse(FValue.Items[17].ToBoolean(True));
  Assert.IsTrue(FValue.Items[18].ToBoolean(True));
  Assert.IsFalse(FValue.Items[19].ToBoolean(True));
  Assert.IsTrue(FValue.Items[20].ToBoolean(True));
  Assert.IsTrue(FValue.Items[21].ToBoolean(True));
  Assert.IsTrue(FValue.Items[22].ToBoolean(True));
  Assert.IsTrue(FValue.Items[23].ToBoolean(True));
  Assert.IsTrue(FValue.Items[24].ToBoolean(True));
  Assert.IsTrue(FValue.Items[25].ToBoolean(True));
  Assert.IsTrue(FValue.Items[26].ToBoolean(True));
end;

procedure TestJsonValue.TestToDouble;
begin
  Assert.AreEqual<Double>(0, FValue.Items[0].ToDouble(9.875));
  Assert.AreEqual<Double>(0, FValue.Items[1].ToDouble(9.875));
  Assert.AreEqual<Double>(1, FValue.Items[2].ToDouble(9.875));
  Assert.AreEqual<Double>(-$80000000, FValue.Items[3].ToDouble(9.875));
  Assert.AreEqual<Double>(-$20000001, FValue.Items[4].ToDouble(9.875));
  Assert.AreEqual<Double>(-$20000000, FValue.Items[5].ToDouble(9.875));
  Assert.AreEqual<Double>(0, FValue.Items[6].ToDouble(9.875));
  Assert.AreEqual<Double>($1FFFFFFF, FValue.Items[7].ToDouble(9.875));
  Assert.AreEqual<Double>($20000000, FValue.Items[8].ToDouble(9.875));
  Assert.AreEqual<Double>($7FFFFFFF, FValue.Items[9].ToDouble(9.875));
  Assert.AreEqual<Double>(-$8000000000000000, FValue.Items[10].ToDouble(9.875));
  Assert.AreEqual<Double>(-$2000000000000001, FValue.Items[11].ToDouble(9.875));
  Assert.AreEqual<Double>(-$2000000000000000, FValue.Items[12].ToDouble(9.875));
  Assert.AreEqual<Double>($1FFFFFFFFFFFFFFF, FValue.Items[13].ToDouble(9.875));
  Assert.AreEqual<Double>($2000000000000000, FValue.Items[14].ToDouble(9.875));
  Assert.AreEqual<Double>($7FFFFFFFFFFFFFFF, FValue.Items[15].ToDouble(9.875));
  Assert.AreEqual<Double>(-123.25, FValue.Items[16].ToDouble(9.875));
  Assert.AreEqual<Double>(0, FValue.Items[17].ToDouble(9.875));
  Assert.AreEqual<Double>(987.75, FValue.Items[18].ToDouble(9.875));
  Assert.AreEqual<Double>(9.875, FValue.Items[19].ToDouble(9.875));
  Assert.AreEqual<Double>(9.875, FValue.Items[20].ToDouble(9.875));
  Assert.AreEqual<Double>(42, FValue.Items[21].ToDouble(9.875));
  Assert.AreEqual<Double>(-4.5, FValue.Items[22].ToDouble(9.875));
  Assert.AreEqual<Double>(9.875, FValue.Items[23].ToDouble(9.875));
  Assert.AreEqual<Double>(9.875, FValue.Items[24].ToDouble(9.875));
  Assert.AreEqual<Double>(9.875, FValue.Items[25].ToDouble(9.875));
  Assert.AreEqual<Double>(9.875, FValue.Items[26].ToDouble(9.875));
end;

procedure TestJsonValue.TestToInt32;
begin
  Assert.AreEqual<Int32>(0, FValue.Items[0].ToInt32(-99));
  Assert.AreEqual<Int32>(0, FValue.Items[1].ToInt32(-99));
  Assert.AreEqual<Int32>(1, FValue.Items[2].ToInt32(-99));
  Assert.AreEqual<Int32>(-$80000000, FValue.Items[3].ToInt32(-99));
  Assert.AreEqual<Int32>(-$20000001, FValue.Items[4].ToInt32(-99));
  Assert.AreEqual<Int32>(-$20000000, FValue.Items[5].ToInt32(-99));
  Assert.AreEqual<Int32>(0, FValue.Items[6].ToInt32(-99));
  Assert.AreEqual<Int32>($1FFFFFFF, FValue.Items[7].ToInt32(-99));
  Assert.AreEqual<Int32>($20000000, FValue.Items[8].ToInt32(-99));
  Assert.AreEqual<Int32>($7FFFFFFF, FValue.Items[9].ToInt32(-99));
  Assert.AreEqual<Int32>(0, FValue.Items[10].ToInt32(-99));
  Assert.AreEqual<Int32>(-1, FValue.Items[11].ToInt32(-99));
  Assert.AreEqual<Int32>(0, FValue.Items[12].ToInt32(-99));
  Assert.AreEqual<Int32>(-1, FValue.Items[13].ToInt32(-99));
  Assert.AreEqual<Int32>(0, FValue.Items[14].ToInt32(-99));
  Assert.AreEqual<Int32>(-1, FValue.Items[15].ToInt32(-99));
  Assert.AreEqual<Int32>(-123, FValue.Items[16].ToInt32(-99));
  Assert.AreEqual<Int32>(0, FValue.Items[17].ToInt32(-99));
  Assert.AreEqual<Int32>(987, FValue.Items[18].ToInt32(-99));
  Assert.AreEqual<Int32>(-99, FValue.Items[19].ToInt32(-99));
  Assert.AreEqual<Int32>(-99, FValue.Items[20].ToInt32(-99));
  Assert.AreEqual<Int32>(42, FValue.Items[21].ToInt32(-99));
  Assert.AreEqual<Int32>(-99, FValue.Items[22].ToInt32(-99));
  Assert.AreEqual<Int32>(-99, FValue.Items[23].ToInt32(-99));
  Assert.AreEqual<Int32>(-99, FValue.Items[24].ToInt32(-99));
  Assert.AreEqual<Int32>(-99, FValue.Items[25].ToInt32(-99));
  Assert.AreEqual<Int32>(-99, FValue.Items[26].ToInt32(-99));
end;

procedure TestJsonValue.TestToInt64;
begin
  Assert.AreEqual<Int64>(0, FValue.Items[0].ToInt64($9876543210));
  Assert.AreEqual<Int64>(0, FValue.Items[1].ToInt64($9876543210));
  Assert.AreEqual<Int64>(1, FValue.Items[2].ToInt64($9876543210));
  Assert.AreEqual<Int64>(-$80000000, FValue.Items[3].ToInt64($9876543210));
  Assert.AreEqual<Int64>(-$20000001, FValue.Items[4].ToInt64($9876543210));
  Assert.AreEqual<Int64>(-$20000000, FValue.Items[5].ToInt64($9876543210));
  Assert.AreEqual<Int64>(0, FValue.Items[6].ToInt64($9876543210));
  Assert.AreEqual<Int64>($1FFFFFFF, FValue.Items[7].ToInt64($9876543210));
  Assert.AreEqual<Int64>($20000000, FValue.Items[8].ToInt64($9876543210));
  Assert.AreEqual<Int64>($7FFFFFFF, FValue.Items[9].ToInt64($9876543210));
  Assert.AreEqual<Int64>(-$8000000000000000, FValue.Items[10].ToInt64($9876543210));
  Assert.AreEqual<Int64>(-$2000000000000001, FValue.Items[11].ToInt64($9876543210));
  Assert.AreEqual<Int64>(-$2000000000000000, FValue.Items[12].ToInt64($9876543210));
  Assert.AreEqual<Int64>($1FFFFFFFFFFFFFFF, FValue.Items[13].ToInt64($9876543210));
  Assert.AreEqual<Int64>($2000000000000000, FValue.Items[14].ToInt64($9876543210));
  Assert.AreEqual<Int64>($7FFFFFFFFFFFFFFF, FValue.Items[15].ToInt64($9876543210));
  Assert.AreEqual<Int64>(-123, FValue.Items[16].ToInt64($9876543210));
  Assert.AreEqual<Int64>(0, FValue.Items[17].ToInt64($9876543210));
  Assert.AreEqual<Int64>(987, FValue.Items[18].ToInt64($9876543210));
  Assert.AreEqual<Int64>($9876543210, FValue.Items[19].ToInt64($9876543210));
  Assert.AreEqual<Int64>($9876543210, FValue.Items[20].ToInt64($9876543210));
  Assert.AreEqual<Int64>(42, FValue.Items[21].ToInt64($9876543210));
  Assert.AreEqual<Int64>($9876543210, FValue.Items[22].ToInt64($9876543210));
  Assert.AreEqual<Int64>($9876543210, FValue.Items[23].ToInt64($9876543210));
  Assert.AreEqual<Int64>($9876543210, FValue.Items[24].ToInt64($9876543210));
  Assert.AreEqual<Int64>($9876543210, FValue.Items[25].ToInt64($9876543210));
  Assert.AreEqual<Int64>($9876543210, FValue.Items[26].ToInt64($9876543210));
end;

procedure TestJsonValue.TestToJson;
var
  Json: JsonString;
begin
  Json := FValue.ToJson(True);
  Assert.AreEqual<JsonString>(
    '[null, false, true, -2147483648, -536870913, -536870912, 0, 536870911, '+
    '536870912, 2147483647, -9223372036854775808, -2305843009213693953, '+
    '-2305843009213693952, 2305843009213693951, 2305843009213693952, '+
    '9223372036854775807, -123.25, 0.0, 987.75, "", "foo", "42", "-4.5", '+
    '[], [42, true, "foo", [4.125, null]], '+
    '{ }, {'#$A'    "val1" : 42,'#$A'    "val2" : 3.5,'#$A'    "val3" : "foo"'#$A'  }]',
    Json);

  Json := FValue.ToJson(False);
  Assert.AreEqual<JsonString>(
    '[null, false, true, -2147483648, -536870913, -536870912, 0, 536870911, '+
    '536870912, 2147483647, -9223372036854775808, -2305843009213693953, '+
    '-2305843009213693952, 2305843009213693951, 2305843009213693952, '+
    '9223372036854775807, -123.25, 0.0, 987.75, "", "foo", "42", "-4.5", '+
    '[], [42, true, "foo", [4.125, null]], '+
    '{ }, { "val1" : 42, "val2" : 3.5, "val3" : "foo" }]',
    Json);
end;

procedure TestJsonValue.TestToString;
begin
  Assert.AreEqual<JsonString>('', FValue.Items[0].ToString('(!)'));
  Assert.AreEqual<JsonString>('false', FValue.Items[1].ToString('(!)'));
  Assert.AreEqual<JsonString>('true', FValue.Items[2].ToString('(!)'));
  Assert.AreEqual<JsonString>('-2147483648', FValue.Items[3].ToString('(!)'));
  Assert.AreEqual<JsonString>('-536870913', FValue.Items[4].ToString('(!)'));
  Assert.AreEqual<JsonString>('-536870912', FValue.Items[5].ToString('(!)'));
  Assert.AreEqual<JsonString>('0', FValue.Items[6].ToString('(!)'));
  Assert.AreEqual<JsonString>('536870911', FValue.Items[7].ToString('(!)'));
  Assert.AreEqual<JsonString>('536870912', FValue.Items[8].ToString('(!)'));
  Assert.AreEqual<JsonString>('2147483647', FValue.Items[9].ToString('(!)'));
  Assert.AreEqual<JsonString>('-9223372036854775808', FValue.Items[10].ToString('(!)'));
  Assert.AreEqual<JsonString>('-2305843009213693953', FValue.Items[11].ToString('(!)'));
  Assert.AreEqual<JsonString>('-2305843009213693952', FValue.Items[12].ToString('(!)'));
  Assert.AreEqual<JsonString>('2305843009213693951', FValue.Items[13].ToString('(!)'));
  Assert.AreEqual<JsonString>('2305843009213693952', FValue.Items[14].ToString('(!)'));
  Assert.AreEqual<JsonString>('9223372036854775807', FValue.Items[15].ToString('(!)'));
  Assert.AreEqual<JsonString>('-123.25', FValue.Items[16].ToString('(!)'));
  Assert.AreEqual<JsonString>('0', FValue.Items[17].ToString('(!)'));
  Assert.AreEqual<JsonString>('987.75', FValue.Items[18].ToString('(!)'));
  Assert.AreEqual<JsonString>('', FValue.Items[19].ToString('(!)'));
  Assert.AreEqual<JsonString>('foo', FValue.Items[20].ToString('(!)'));
  Assert.AreEqual<JsonString>('42', FValue.Items[21].ToString('(!)'));
  Assert.AreEqual<JsonString>('-4.5', FValue.Items[22].ToString('(!)'));
  Assert.AreEqual<JsonString>('(!)', FValue.Items[23].ToString('(!)'));
  Assert.AreEqual<JsonString>('(!)', FValue.Items[24].ToString('(!)'));
  Assert.AreEqual<JsonString>('(!)', FValue.Items[25].ToString('(!)'));
  Assert.AreEqual<JsonString>('(!)', FValue.Items[26].ToString('(!)'));
end;

procedure TestJsonValue.TestTryGetValue;
var
  D, V: TJsonValue;
begin
  D := FValue.Items[26];
  Assert.IsFalse(D.TryGetValue('foo', V));
  Assert.IsTrue(V.IsNull);
  Assert.IsTrue(D.TryGetValue('val2', V));
  Assert.IsFalse(V.IsNull);
  Assert.AreEqual<Double>(3.5, V);

  Assert.WillRaise(
    procedure
    begin
      FValue.Items[0].TryGetValue('foo', V);
    end, EInvalidOperation);

  Assert.WillRaise(
    procedure
    begin
      FValue.Items[24].TryGetValue('foo', V);
    end, EInvalidOperation);
end;

initialization
  ReportMemoryLeaksOnShutdown := True;
  TDUnitX.RegisterTestFixture(TestJsonValue);

end.
