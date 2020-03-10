unit TestUtils;

interface

uses
  System.SysUtils,
  Neslib.Json.Types,
  Neslib.Json;

function LoadTestData(const APath: String): TBytes;
function LoadTestString(const APath: String): JsonString;

implementation

uses
  System.Classes,
  System.Types,
  System.Zip;

var
  GTestDataStream: TStream = nil;
  GTestDataZipFile: TZipFile = nil;

function LoadTestData(const APath: String): TBytes;
begin
  if (GTestDataZipFile = nil) then
  begin
    System.Assert(GTestDataStream = nil);
    GTestDataStream := TResourceStream.Create(HInstance, 'JSON_TEST_DATA', RT_RCDATA);
    GTestDataZipFile := TZipFile.Create;
    GTestDataZipFile.Open(GTestDataStream, TZipMode.zmRead);
  end;

  GTestDataZipFile.Read(APath, Result);
end;

function LoadTestString(const APath: String): JsonString;
var
  Bytes: TBytes;
begin
  Bytes := LoadTestData(APath);
  {$IFDEF JSON_UTF8}
  SetLength(Result, Length(Bytes));
  Move(Bytes[0], Result[Low(JsonString)], Length(Bytes));
  {$ELSE}
  Result := TEncoding.UTF8.GetString(Bytes);
  {$ENDIF}
end;

initialization

finalization
  GTestDataZipFile.Free;
  GTestDataStream.Free;

end.
