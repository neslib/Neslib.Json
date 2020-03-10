unit Neslib.Json.Types;
{< Common JSON types. }

interface

{$IFDEF JSON_STRING_INTERNING}
uses
  Neslib.Collections;
{$ENDIF}

type
  {$IFDEF JSON_UTF8}
  JsonChar = UTF8Char;
  PJsonChar = PUTF8Char;
  JsonString = UTF8String;
  {$IFDEF JSON_STRING_INTERNING}
  TJsonStringInternPool = TUTF8StringInternPool;
  {$ENDIF}
  {$ELSE}
  JsonChar = WideChar;
  PJsonChar = PWideChar;
  JsonString = String;
  {$IFDEF JSON_STRING_INTERNING}
  TJsonStringInternPool = TStringInternPool;
  {$ENDIF}
  {$ENDIF}

implementation

end.
