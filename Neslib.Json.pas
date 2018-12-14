unit Neslib.Json;
(*< A fast and memory-efficient JSON object model, with support for efficiently
  parsing and writing in JSON-compliant format.

  @bold(Loading and Saving JSON)

  The main entry point to this library is the IJsonDocument interface. It is
  used for parsing, loading and saving JSON documents and provides access to the
  JSON object model. You can parse a JSON string as follows:

    <source>
    var
      Doc: IJsonDocument;
    begin
      Doc := TJsonDocument.Parse('{ "Answer" : 42 }');
    end;
    </source>

  Note that, unlike the official JSON specification, this library does NOT
  require quotes around dictionary keys (as long as the key does not contain
  spaces or other non-identifier characters). So the following is valid as well:

    <source>
    Doc := TJsonDocument.Parse('{ Answer : 42 }');
    </source>

  You can also use the Load method to load from a file or stream.

  On the output side, you use Save to save to a file or stream, or ToJson to
  output to a JSON string.

  You can also create new JSON documents from scratch using the CreateArray or
  CreateDictionary methods:

    <source>
    var
      Doc: IJsonDocument;
    begin
      Doc := TJsonDocument.CreateArray;
      Doc.Root.Add(42);
    end;
    </source>

  As you can see in this example, you access the JSON document object model
  through the Root property.

  @bold(JSON object model)

  At the heart of the JSON object model is the TJsonValue type. This is a record
  that can hold any type of JSON value.

  It provides various implicit conversion operators to convert a TJsonValue to
  another (Delphi) type. In addition, there are various To* methods that try
  to convert a TJsonValue but return a provided default value if conversion
  fails.

  You (can) never create TJsonValue's yourself; The only way to create a
  TJsonValue is by adding a value to JSON array or dictionary:

    <source>
    var
      Doc: IJsonDocument;
    begin
      Doc := TJsonDocument.CreateArray;
      Doc.Root.Add(42);
    end;
    </source>

  This example adds a TJsonValue (with value 42) to a JSON array. To create a
  new array of dictionary, you use the AddArray or AddDictionary methods
  instead:

    <source>
    var
      Doc: IJsonDocument;
      Dict: TJsonValue;
    begin
      Doc := TJsonDocument.CreateArray;
      Dict := Doc.Root.AddDictionary;
      Dict.AddOrSetValue('answer', 42);
    end;
    </source>

  This creates a new dictionary and adds it to the root array. Then, the value
  42 is added to this dictionary under the name 'answer'.

  To check the type of a value, use the TJsonValue.ValueType property or one
  of the TJsonValue.Is* methods.

  When trying to use methods like Add (or AddOrSetValue) on values that are not
  arrays (or dictionaries), an exception will be raised.

  However, accessing the items in an array (using the Items property) or the
  values in a dictionary (using the Values property) will never result in an
  exception, even if the array index is out of bounds. This allows for chaining
  multiple array/dictionary accesses together without having to check the
  validity of each intermediate step. For example:

    <source>
    I := Doc.Root.Items[3].Values['foo'].Values['bar'].Items[4].ToInteger(0);
    </source>

  This will always succeed, but return 0 if any of the intermediate values are
  unavailable.

  @bold(Manually Reading and Writing JSON)

  The IJsonDocument interface makes it easy to read and write JSON into a
  document object model.

  However, you can also choose to read or write JSON manually if you prefer (for
  example to avoid having to load an object model into memory). You can do this
  with the IJsonReader and IJsonWriter interfaces in the Neslib.Json.IO unit.
  These interfaces are completely independent from any DOM implementation and
  don't even require this unit. Using these interfaces is a bit more complicated
  and requires some more work though. See the Neslib.Json.IO unit for more
  information.

  @bold(Querying JSON documents with JSONPath)

  There is also an XPath-like JSONPath implementation you can use for querying
  JSON documents. This feature is documented in the Neslib.Json.Path unit.

  @bold(Memory Management)

  All memory management is automatic. An IJsonDocument interface owns all
  TJsonValue's and destroys them when the document is destroyed (goes out of
  scope).

  The only thing you need to be aware of is that you shouldn't use any
  TJsonValue records anymore after the document is destroyed. Doing so will lead
  to undefined behavior and possibly crashes.

  @bold(Customization)

  You can customize some behavior using these conditional defines:
  * JSON_UTF8: to use UTF8String instead of String everywhere. All strings will
    be treated as 8-bit UTF-8 strings instead of 16-bit Unicode strings. This
    reduces memory consumption and speeds up parsing a bit. However, this means
    you will have to use this JSON library with UTF8Strings as well, otherwise
    Delphi will implicitly convert between Unicode strings and UTF8Strings, which
    can hurt performance.
  * JSON_STRING_INTERNING: to enable string interning for dictionary keys.
    This reduces memory consumption in case the same key is used a lot of times
    (which is common when JSON is exported from a database), but is a bit
    slower.

  This unit declares the JsonString type as either String or UTF8String,
  depending on the JSON_UTF8 define. However, this doesn't mean that YOU have
  to use JsonString as well. If you don't care about the JSON_UTF8 define, then
  you can just use regular strings with this library. *)

{$INCLUDE 'Neslib.inc'}

interface

uses
  System.Classes,
  System.SysUtils,
  Neslib.Json.IO;

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
  { Data types supported by JSON }
  TJsonValueType = (
    { Null value }
    Null,

    { A Boolean value (False or True) }
    Boolean,

    { An ordinal value, such as a 32-bit or 64-bit integer }
    Ordinal,

    { A floating-point value, such as a Single or Double }
    Float,

    { A string value }
    &String,

    { An array of TJsonValue's }
    &Array,

    { A dictionary with string keys and values of type TJsonValue }
    Dictionary);

type
  PJsonElement = ^TJsonElement;
  PJsonValue = ^TJsonValue;

  { The base type for the JSON object model. Every possible type of JSON value
    can be represented with a TJsonValue record.

    This record is very light-weight (it only occupies 32 bits on a 32-bit
    system, or 64 bits on a 64-bit system). It only allocates more memory if
    it doesn't fit in this record.

    Memory management is automatic. All values are owned by a IJsonDocument,
    which takes care of destroying these values when the document is
    destroyed. }
  TJsonValue = record
  {$REGION 'Internal Declarations'}
  private const
    TYPE_BITS   = 2;
    TYPE_MASK   = (1 shl TYPE_BITS) - 1;
    VALUE_BITS  = (SizeOf(UIntPtr) * 8) - TYPE_BITS;
    VALUE_MASK  = UIntPtr.MaxValue - TYPE_MASK;
    {$IFDEF CPU64BITS}
    EXTEND_BITS = UInt64(TYPE_MASK) shl (64 - TYPE_BITS);
    MAX_INT     = (Int64(1) shl (VALUE_BITS - 1)) - 1;
    MIN_INT     = -(Int64(1) shl (VALUE_BITS - 1));
    {$ELSE}
    EXTEND_BITS = TYPE_MASK shl (32 - TYPE_BITS);
    MAX_INT     = (1 shl (VALUE_BITS - 1)) - 1;
    MIN_INT     = -(1 shl (VALUE_BITS - 1));
    {$ENDIF}
  private const
    TYPE_FIXED = $0; // Null or Boolean
    TYPE_INT   = $1; // Embedded native integer
    TYPE_STR   = $2; // String on heap
    TYPE_HEAP  = $3; // Other value on heap
  private const
    SUBTYPE_ARRAY = 0; // Array on heap
    SUBTYPE_DICT  = 1; // Dictionary on heap
    SUBTYPE_INT   = 2; // Native integer on heap
    SUBTYPE_FLOAT = 3; // Double on heap
  private type
    THeapInt = record
      SubType: UInt32;
      Value: Int64;
    end;
    PHeapInt = ^THeapInt;
  private type
    THeapFloat = record
      SubType: UInt32;
      Value: Double;
    end;
    PHeapFloat = ^THeapFloat;
  private type
    TJsonArray = record
    private
      FSubtype: UInt32;
      FItems: PJsonValue;
      FCount: Integer;
      FCapacity: Integer;
    private
      procedure Grow;
    public
      procedure Init; inline;
      procedure Free; inline;

      procedure Delete(const AIndex: Integer);
      procedure Clear;
      function Equals(const AOther: TJsonArray): Boolean;

      procedure Add(const AValue: Boolean); overload;
      procedure Add(const AValue: Int32); overload;
      procedure Add(const AValue: UInt32); overload;
      procedure Add(const AValue: Int64); overload;
      procedure Add(const AValue: UInt64); overload;
      procedure Add(const AValue: Single); overload;
      procedure Add(const AValue: Double); overload;
      procedure Add(const AValue: JsonString); overload;
      procedure AddNull; inline;
      function AddArray: TJsonValue; inline;
      function AddDictionary: TJsonValue; inline;

      function GetItem(const AIndex: Integer): TJsonValue;
    public
      procedure ReadFrom(const AReader: IJsonReader);
      procedure WriteTo(const AWriter: IJsonWriter);
    end;
    PJsonArray = ^TJsonArray;
  private type
    TElement = record
    private
      FName: JsonString;
      FValue: UIntPtr; // TJsonValue
    public
      class operator Equal(const A, B: TElement): Boolean; static;
      class operator NotEqual(const A, B: TElement): Boolean; inline; static;

      procedure Free; inline;
    end;
    PElement = ^TElement;
  private type
    TMapEntry = record
      HashCode: Integer;
      Name: JsonString;
      Index: Integer;
    end;
    PMapEntry = ^TMapEntry;
  private type
    TIndexMap = record
    private const
      EMPTY_HASH = -1;
    private
      FEntries: PMapEntry;
      FCount: Integer;
      FCapacity: Integer;
      FGrowThreshold: Integer;
    private
      procedure Resize(ANewSize: Integer);
    public
      procedure Free;
      procedure Clear;
      function Get(const AName: JsonString): Integer;
      procedure Add(const AName: JsonString; const AIndex: Integer);
    end;
    PIndexMap = ^TIndexMap;
  private type
    TJsonDictionary = record
    private const
      { We use an FIndices dictionary to map names to indices.
        However, for small dictionaries it is faster and more memory efficient
        to just perform a linear search.
        So we only use the dictionary if the number of items reaches this value. }
      INDICES_COUNT_THRESHOLD = 12;
    private
      FSubtype: UInt32;
      FElements: PElement;
      FIndices: PIndexMap;
      FCount: Integer;
      FCapacity: Integer;
    private
      function AddOrReplaceElement(const AName: JsonString): PElement;
      procedure RebuildIndices;
    public
      procedure Init; inline;
      procedure Free; inline;

      procedure Delete(const AIndex: Integer);
      procedure Clear;
      function Equals(const AOther: TJsonDictionary): Boolean;

      procedure AddOrSetValue(const AName: JsonString; const AValue: Boolean); overload;
      procedure AddOrSetValue(const AName: JsonString; const AValue: Int32); overload;
      procedure AddOrSetValue(const AName: JsonString; const AValue: UInt32); overload;
      procedure AddOrSetValue(const AName: JsonString; const AValue: Int64); overload;
      procedure AddOrSetValue(const AName: JsonString; const AValue: UInt64); overload;
      procedure AddOrSetValue(const AName: JsonString; const AValue: Single); overload;
      procedure AddOrSetValue(const AName: JsonString; const AValue: Double); overload;
      procedure AddOrSetValue(const AName: JsonString; const AValue: JsonString); overload;
      procedure AddOrSetNull(const AName: JsonString);
      function AddOrSetArray(const AName: JsonString): TJsonValue;
      function AddOrSetDictionary(const AName: JsonString): TJsonValue;

      function IndexOfName(const AName: JsonString): Integer;
      function Contains(const AName: JsonString): Boolean; inline;
      procedure Remove(const AName: JsonString);
      function TryGetValue(const AName: JsonString; out AValue: TJsonValue): Boolean;

      function GetValue(const AName: JsonString): TJsonValue;
      function GetElement(const AIndex: Integer): PJsonElement;
    public
      procedure ReadFrom(const AReader: IJsonReader);
      procedure WriteTo(const AWriter: IJsonWriter);
    end;
    PJsonDictionary = ^TJsonDictionary;
  private
    { Layout of FBits:
      * Bits 0-1: data type. One of type TYPE_* values.
      * Bits 2-31 (or 2-63 on 64-bit systems): value.

      The value depends on the TYPE_*:
      * TYPE_FIXED: 0=Null, 1=False, 2=True
      * TYPE_INT: Native integer. Sign bit must be extended.
      * TYPE_STR: Pointer to a UnicodeString on the heap, or 0 for empty string.
      * TYPE_HEAP: Pointer to another value on the heap.

      Note that any Pointer value is calculated by setting the lowest 2 bits to
      0. This is legal since Delphi always allocates dynamic memory at 4-byte
      aligned addresses. (Actually, dynamic memory is always aligned on 8-byte
      boundaries, but constant strings can be aligned on 4-byte boundaries).

      For TYPE_HEAP, the first 4 bytes of the data that is pointed to contains a
      subtype value that indicates the type of data:
      * SUBTYPE_INT: Pointer to dynamically allocated native integer on the
        heap. Only used when value doesn't fit into 30 or 62 bits (depending on
        system).
      * SUBTYPE_FLOAT: Pointer to dynamically allocated Double on the heap.
      * SUBTYPE_ARRAY: Pointer to private TJsonArray record on the heap.
      * SUBTYPE_DICT: Pointer to private TJsonDictionary record on the heap. }
    FBits: UIntPtr;
  private
    function GetValueType: TJsonValueType; inline;
    function GetIsNull: Boolean; inline;
    function GetIsBoolean: Boolean; inline;
    function GetIsOrdinal: Boolean;
    function GetIsFloat: Boolean; inline;
    function GetIsNumeric: Boolean;
    function GetIsString: Boolean; inline;
    function GetIsArray: Boolean; inline;
    function GetIsDictionary: Boolean; inline;
    function GetItem(const AIndex: Integer): TJsonValue; inline;
    function GetValue(const AName: JsonString): TJsonValue; inline;
    function GetElement(const AIndex: Integer): PJsonElement; inline;
    function GetCount: Integer; inline;
  private
    class function Create: TJsonValue; overload; inline; static;
    class function Create(const AValue: Boolean): TJsonValue; overload; inline; static;
    class function Create(const AValue: Int32): TJsonValue; overload; {$IFDEF CPU64BITS}inline;{$ENDIF} static;
    class function Create(const AValue: UInt32): TJsonValue; overload; {$IFDEF CPU64BITS}inline;{$ENDIF} static;
    class function Create(const AValue: Int64): TJsonValue; overload; {$IFDEF CPU32BITS}inline;{$ENDIF} static;
    class function Create(const AValue: UInt64): TJsonValue; overload; {$IFDEF CPU32BITS}inline;{$ENDIF} static;
    class function Create(const AValue: Double): TJsonValue; overload; inline; static;
    class function Create(const AValue: JsonString): TJsonValue; overload; inline; static;
    class function CreateArray: TJsonValue; inline; static;
    class function CreateDictionary: TJsonValue; inline; static;
    class function ReadFrom(const AReader: IJsonReader;
      const AState: TJsonReaderState): TJsonValue; static;
    procedure Free;
    procedure WriteTo(const AWriter: IJsonWriter);
  {$ENDREGION 'Internal Declarations'}
  public
    { Implicit operators that convert a TJsonValue to another type.
      These operators never raise an exception, but return a zero-value (such as
      0, False or an empty string) if the TJsonValue cannot be converted. }
    class operator Implicit(const AValue: TJsonValue): Boolean; inline; static;
    class operator Implicit(const AValue: TJsonValue): Int8; inline; static;
    class operator Implicit(const AValue: TJsonValue): UInt8; inline; static;
    class operator Implicit(const AValue: TJsonValue): Int16; inline; static;
    class operator Implicit(const AValue: TJsonValue): UInt16; inline; static;
    class operator Implicit(const AValue: TJsonValue): Int32; inline; static;
    class operator Implicit(const AValue: TJsonValue): UInt32; inline; static;
    class operator Implicit(const AValue: TJsonValue): Int64; inline; static;
    class operator Implicit(const AValue: TJsonValue): UInt64; inline; static;
    class operator Implicit(const AValue: TJsonValue): Single; inline; static;
    class operator Implicit(const AValue: TJsonValue): Double; inline; static;
    class operator Implicit(const AValue: TJsonValue): JsonString; inline; static;

    { Tests two TJsonValue's for (in)equality, based on their data type. }
    class operator Equal(const ALeft, ARight: TJsonValue): Boolean; static;
    class operator NotEqual(const ALeft, ARight: TJsonValue): Boolean; inline; static;

    { Converts the TJsonValue to another type if possible, or returns a default
      value if conversion is not possible.

      Parameters:
        ADefault: (optional) default value to return in case the TJsonValue
          cannot be converted.

      Returns:
        The converted value, or ADefault if the value cannot be converted.

      These methods never raise an exception. }
    function ToBoolean(const ADefault: Boolean = False): Boolean;
    function ToInteger(const ADefault: Integer = 0): Integer; inline; // Alias for ToInt32
    function ToInt32(const ADefault: Int32 = 0): Int32;
    function ToInt64(const ADefault: Int64 = 0): Int64;
    function ToDouble(const ADefault: Double = 0): Double;
    function ToString(const ADefault: JsonString = ''): JsonString;

    { Converts the TJsonValue to a string in JSON format.

      Parameters:
        AIndent: (optional) flag indicating whether you want indented (or
          pretty-printed) output. If True (the default), nested values will be
          indented and line breaks will be inserted. If False, then no line
          breaks and indentation will be used.

      Returns:
        The value in JSON format. }
    function ToJson(const AIndent: Boolean = True): JsonString; inline;

    { The type of this value. }
    property ValueType: TJsonValueType read GetValueType;

    { Whether this is a Null value (eg. ValueType = Null). }
    property IsNull: Boolean read GetIsNull;

    { Whether this is a Boolean value (eg. ValueType = Boolean). }
    property IsBoolean: Boolean read GetIsBoolean;

    { Whether this is an ordinal value (eg. ValueType = Ordinal). }
    property IsOrdinal: Boolean read GetIsOrdinal;

    { Whether this is a floating-point value (eg. ValueType = Float). }
    property IsFloat: Boolean read GetIsFloat;

    { Whether this is a numberic value (ordinal or floating-point). }
    property IsNumeric: Boolean read GetIsNumeric;

    { Whether this is a String value (eg. ValueType = String). }
    property IsString: Boolean read GetIsString;

    { Whether this is an Array value (eg. ValueType = Array). }
    property IsArray: Boolean read GetIsArray;

    { Whether this is a Dictionary value (eg. ValueType = Dictionary). }
    property IsDictionary: Boolean read GetIsDictionary;
  public
    (*************************************************************************)
    (* The methods in this section only apply to arrays and dictionaries     *)
    (* (that is, if IsArray or IsDictionary returns True). Unless stated     *)
    (* otherwise, they raise an EInvalidOperation exception if this is not   *)
    (* an array or dictionary.                                               *)
    (*************************************************************************)

    { Clears the array or dictionary.

      Raises:
        EInvalidOperation if this is not an array or dictionary. }
    procedure Clear; inline;

    { Deletes an item from the array or dictionary.

      Parameters:
        AIndex: index of the item to delete.

      Raises:
        EInvalidOperation if this is not an array or dictionary.
        EArgumentOutOfRangeException if AIndex is out of bounds. }
    procedure Delete(const AIndex: Integer); inline;

    { Returns the number of items in the array or dictionary.
      This property NEVER raises an exception. Instead, it returns 0 if this is
      not an array or dictionary. }
    property Count: Integer read GetCount;
  public
    (*************************************************************************)
    (* The methods in this section only apply to arrays (that is, if IsArray *)
    (* returns True). Unless stated otherwise, they raise an                 *)
    (* EInvalidOperation exception if this is not an array.                  *)
    (*************************************************************************)

    { Adds a value to the end of the array.

      Parameters:
        AValue: the value to add.

      Raises:
        EInvalidOperation if this is not an array. }
    procedure Add(const AValue: Boolean); overload; inline;
    procedure Add(const AValue: Int32); overload; inline;
    procedure Add(const AValue: UInt32); overload; inline;
    procedure Add(const AValue: Int64); overload; inline;
    procedure Add(const AValue: UInt64); overload; inline;
    procedure Add(const AValue: Single); overload; inline;
    procedure Add(const AValue: Double); overload; inline;
    procedure Add(const AValue: JsonString); overload; inline;

    { Adds a Null-value to the end of the array.

      Raises:
        EInvalidOperation if this is not an array. }
    procedure AddNull; inline;

    { Creates an array and adds it to the end of this array.

      Returns:
        The newly created array.

      Raises:
        EInvalidOperation if this is not an array. }
    function AddArray: TJsonValue; inline;

    { Creates a dictionary and adds it to the end of this array.

      Returns:
        The newly created dictionary.

      Raises:
        EInvalidOperation if this is not an array. }
    function AddDictionary: TJsonValue; inline;

    { The items in this array.

      Unlike the other array-methods, this property NEVER raises an exception.
      Instead, it returns a Null value if this is not an array or AIndex is out
      of range.

      This allows for chaining without having to check every intermediate step,
      as in Foo.Items[1].Items[3].Items[2].ToInteger. }
    property Items[const AIndex: Integer]: TJsonValue read GetItem;
  public
    (*************************************************************************)
    (* The methods in this section only apply to dictionaries (that is, if   *)
    (* IsDictionary returns True). Unless stated otherwise, they raise an    *)
    (* EInvalidOperation exception if this is not a dictionary               *)
    (*************************************************************************)

    { Adds or replaces a value in the dictionary.

      Parameters:
        AName: the name (key) of the value to add.
        AValue: the value to add.

      Raises:
        EInvalidOperation if this is not a dictionary.

      If a value with the given name already exists in the dictionary, then it
      is freed and replaced. }
    procedure AddOrSetValue(const AName: JsonString; const AValue: Boolean); overload; inline;
    procedure AddOrSetValue(const AName: JsonString; const AValue: Int32); overload; inline;
    procedure AddOrSetValue(const AName: JsonString; const AValue: UInt32); overload; inline;
    procedure AddOrSetValue(const AName: JsonString; const AValue: Int64); overload; inline;
    procedure AddOrSetValue(const AName: JsonString; const AValue: UInt64); overload; inline;
    procedure AddOrSetValue(const AName: JsonString; const AValue: Single); overload; inline;
    procedure AddOrSetValue(const AName: JsonString; const AValue: Double); overload; inline;
    procedure AddOrSetValue(const AName: JsonString; const AValue: JsonString); overload; inline;

    { Adds or replaces a Null-value in the dictionary.

      Parameters:
        AName: the name (key) of the value to add.

      Raises:
        EInvalidOperation if this is not a dictionary.

      If a value with the given name already exists in the dictionary, then it
      is freed and replaced. }
    procedure AddOrSetNull(const AName: JsonString); inline;

    { Creates an array and adds or replaces it in this dictionary.

      Parameters:
        AName: the name (key) of the value to add.

      Returns:
        The newly created array.

      Raises:
        EInvalidOperation if this is not a dictionary.

      If a value with the given name already exists in the dictionary, then it
      is freed and replaced. }
    function AddOrSetArray(const AName: JsonString): TJsonValue; inline;

    { Creates a dictionary and adds or replaces it in this dictionary.

      Parameters:
        AName: the name (key) of the value to add.

      Returns:
        The newly created dictionary.

      Raises:
        EInvalidOperation if this is not a dictionary.

      If a value with the given name already exists in the dictionary, then it
      is freed and replaced. }
    function AddOrSetDictionary(const AName: JsonString): TJsonValue; inline;

    { Looks up a name in the dictionary.

      Parameters:
        AName: the name to lookup.

      Returns:
        The index of the value with this name, or -1 if the dictionary does not
        contain a value with this name.

      Raises:
        EInvalidOperation if this is not a dictionary. }
    function IndexOfName(const AName: JsonString): Integer; inline;

    { Checks if a name exists in the dictionary.

      Parameters:
        AName: the name to check.

      Returns:
        True if the dictionary contains a value with the given name, or False
        otherwise.

      Raises:
        EInvalidOperation if this is not a dictionary. }
    function Contains(const AName: JsonString): Boolean; inline;

    { Removes a value from the dictionary.

      Parameters:
        AName: the name of the value to remove.

      Raises:
        EInvalidOperation if this is not a dictionary.

      Does nothing if the dictionary does not contain a value with the given
      name. }
    procedure Remove(const AName: JsonString); inline;

    { Tries to retrieve a value from the dictionary.

      Parameters:
        AName: the name of the value to retrieve.
        AValue: is set to the retrieved value, or to a Null value if the
          dictionary does not contain AName.

      Returns:
        True if the dictionary contains a value with the given name, or False
        otherwise.

      Raises:
        EInvalidOperation if this is not a dictionary. }
    function TryGetValue(const AName: JsonString; out AValue: TJsonValue): Boolean; inline;

    { The values in the dictionary, indexed by name.

      Unlike the other dictionary-methods, this property NEVER raises an
      exception. Instead, it returns a Null value if this is not a dictionary or
      if the dictionary does not contain a value with the given name.

      This allows for chaining without having to check every intermediate step,
      as in Foo.Value['bar'].Values['baz'].ToInteger. }
    property Values[const AName: JsonString]: TJsonValue read GetValue;

    { The elements (name/value pairs) in the dictionary by index.

      Unlike the other dictionary-methods, this property NEVER raises an
      exception. Instead, it returns nil if this is not a dictionary or if
      AIndex is out of range.

      NOTE: Do not cache the returned value; it is only valid until the
      dictionary is deleted or modified. }
    property Elements[const AIndex: Integer]: PJsonElement read GetElement;
  end;

  { An element in a JSON dictionary. }
  TJsonElement = record
  {$REGION 'Internal Declarations'}
  private
    FName: JsonString;
    FValue: TJsonValue;
  {$ENDREGION 'Internal Declarations'}
  public
    { The name of the element. }
    property Name: JsonString read FName;

    { The value of the element. }
    property Value: TJsonValue read FValue;
  end;

type
  { Represents a JSON document.
    This interface is implemented in the TJsonDocument class. }
  IJsonDocument = interface
  ['{5F8E284C-9D7F-406C-8430-4BF64E6C4DB3}']
    {$REGION 'Internal Declarations'}
    function GetRoot: TJsonValue;
    {$ENDREGION 'Internal Declarations'}

    { Saves the document to a file.

      Parameters:
        AFilename: the name of the file to save to.
        AIndent: (optional) flag indicating whether you want indented (or
          pretty-printed) output. If True, nested values will be indented and
          line breaks will be inserted. If False (the default), then no line
          breaks and indentation will be used. }
    procedure Save(const AFilename: String; const AIndent: Boolean = False); overload;

    { Saves the document to a stream.

      Parameters:
        AStream: the stream to save to.
        AIndent: (optional) flag indicating whether you want indented (or
          pretty-printed) output. If True, nested values will be indented and
          line breaks will be inserted. If False (the default), then no line
          breaks and indentation will be used. }
    procedure Save(const AStream: TStream; const AIndent: Boolean = False); overload;

    { Converts the document to a string in JSON format.

      Parameters:
        AIndent: (optional) flag indicating whether you want indented (or
          pretty-printed) output. If True (the default), nested values will be
          indented and line breaks will be inserted. If False, then no line
          breaks and indentation will be used.

      Returns:
        The document in JSON format. }
    function ToJson(const AIndent: Boolean = True): JsonString;

    { The root value of the document.
      You access the JSON object model through this property. }
    property Root: TJsonValue read GetRoot;
  end;

type
  { A JSON document. Implements the IJsonDocument interface. }
  TJsonDocument = class(TInterfacedObject, IJsonDocument)
  {$REGION 'Internal Declarations'}
  private
    FRoot: TJsonValue;
  private
    constructor Create(const ARoot: TJsonValue); overload;
  protected
    { IJsonDocument }
    function GetRoot: TJsonValue;

    procedure Save(const AFilename: String; const AIndent: Boolean = False); overload;
    procedure Save(const AStream: TStream; const AIndent: Boolean = False); overload;

    function ToJson(const AIndent: Boolean = True): JsonString;
  public
    constructor Create; overload; deprecated 'Use CreateArray, CreateDictionary, Parse or Load';
  {$ENDREGION 'Internal Declarations'}
  public
    destructor Destroy; override;

    { Creates a new document with an empty array as root.

      Returns:
        The new document.

      Use the Root property to start adding values to the array. }
    class function CreateArray: IJsonDocument; static;

    { Creates a new document with an empty dictionary as root.

      Returns:
        The new document.

      Use the Root property to start adding values to the dictionary. }
    class function CreateDictionary: IJsonDocument; static;

    { Parses a JSON string into a document.

      Parameters:
        AJson: the JSON formatted string to parse.

      Returns:
        The document or nil in case AJson is empty.

      Raises:
        EJsonParserError if AJson is invalid or does not start with an array
        or dictionary. }
    class function Parse(const AJson: JsonString): IJsonDocument; static;

    { Loads a JSON document from a file.

      Parameters:
        AFilename: the name of the file to load.

      Returns:
        The document or nil in case the file is empty.

      Raises:
        EJsonParserError if the JSON is invalid or does not start with an array
        or dictionary. }
    class function Load(const AFilename: String): IJsonDocument; overload; static;

    { Loads a JSON document from a stream.

      Parameters:
        AFilename: the stream to load.

      Returns:
        The document or nil in case the stream is empty.

      Raises:
        EJsonParserError if the JSON is invalid or does not start with an array
        or dictionary. }
    class function Load(const AStream: TStream): IJsonDocument; overload; static;

    { Loads a JSON document from a JSON reader.

      Parameters:
        AReader: the reader to use.

      Returns:
        The document or nil in case AReader is nil or the contents is empty.

      Raises:
        EJsonParserError if the JSON is invalid or does not start with an array
        or dictionary. }
    class function Load(const AReader: IJsonReader): IJsonDocument; overload; static;
  end;

type
  TJsonValueHelper = record helper for TJsonValue
  public const
    { A JSON Null value }
    Null: TJsonValue = (FBits: 0);
  end;

resourcestring
  RS_JSON_INVALID_ROOT = 'JSON document must start with an array or dictionary.';

{$REGION 'Internal Declarations'}
const
  _JSON_NULL_ELEMENT: TJsonElement = (FName: ''; FValue: (FBits: 0));
{$ENDREGION 'Internal Declarations'}

implementation

{$IF (TJsonValue.TYPE_FIXED <> 0)}
  {$MESSAGE Error 'Internal Error: TJsonValue.TYPE_FIXED must have value 0'}
{$ENDIF}

{$IF (SizeOf(TJsonValue) <> SizeOf(Pointer))}
  {$MESSAGE Error 'Internal Error: TJsonValue has invalid layout'}
{$ENDIF}

{$IF IsManagedType(TJsonValue)}
  {$MESSAGE Error 'Internal Error: TJsonValue has managed fields'}
{$ENDIF}

{$POINTERMATH ON}

uses
  System.RTLConsts,
  Neslib.Utf8,
  Neslib.Hash,
  Neslib.SysUtils;

type
  PInt32 = ^Int32;

{ TJsonValue }

procedure TJsonValue.Add(const AValue: Int64);
var
  A: PJsonArray;
begin
  A := PJsonArray(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (A.FSubtype <> SUBTYPE_ARRAY) then
    raise EInvalidOperation.Create('Add can only be used for JSON arrays');

  A.Add(AValue);
end;

procedure TJsonValue.Add(const AValue: UInt32);
var
  A: PJsonArray;
begin
  A := PJsonArray(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (A.FSubtype <> SUBTYPE_ARRAY) then
    raise EInvalidOperation.Create('Add can only be used for JSON arrays');

  A.Add(AValue);
end;

procedure TJsonValue.Add(const AValue: Int32);
var
  A: PJsonArray;
begin
  A := PJsonArray(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (A.FSubtype <> SUBTYPE_ARRAY) then
    raise EInvalidOperation.Create('Add can only be used for JSON arrays');

  A.Add(AValue);
end;

procedure TJsonValue.Add(const AValue: Boolean);
var
  A: PJsonArray;
begin
  A := PJsonArray(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (A.FSubtype <> SUBTYPE_ARRAY) then
    raise EInvalidOperation.Create('Add can only be used for JSON arrays');

  A.Add(AValue);
end;

procedure TJsonValue.Add(const AValue: UInt64);
var
  A: PJsonArray;
begin
  A := PJsonArray(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (A.FSubtype <> SUBTYPE_ARRAY) then
    raise EInvalidOperation.Create('Add can only be used for JSON arrays');

  A.Add(AValue);
end;

procedure TJsonValue.Add(const AValue: JsonString);
var
  A: PJsonArray;
begin
  A := PJsonArray(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (A.FSubtype <> SUBTYPE_ARRAY) then
    raise EInvalidOperation.Create('Add can only be used for JSON arrays');

  A.Add(AValue);
end;

procedure TJsonValue.Add(const AValue: Double);
var
  A: PJsonArray;
begin
  A := PJsonArray(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (A.FSubtype <> SUBTYPE_ARRAY) then
    raise EInvalidOperation.Create('Add can only be used for JSON arrays');

  A.Add(AValue);
end;

procedure TJsonValue.Add(const AValue: Single);
var
  A: PJsonArray;
begin
  A := PJsonArray(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (A.FSubtype <> SUBTYPE_ARRAY) then
    raise EInvalidOperation.Create('Add can only be used for JSON arrays');

  A.Add(AValue);
end;

function TJsonValue.AddArray: TJsonValue;
var
  A: PJsonArray;
begin
  A := PJsonArray(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (A.FSubtype <> SUBTYPE_ARRAY) then
    raise EInvalidOperation.Create('AddArray can only be used for JSON arrays');

  Result := A.AddArray;
end;

function TJsonValue.AddDictionary: TJsonValue;
var
  A: PJsonArray;
begin
  A := PJsonArray(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (A.FSubtype <> SUBTYPE_ARRAY) then
    raise EInvalidOperation.Create('AddDictionary can only be used for JSON arrays');

  Result := A.AddDictionary;
end;

procedure TJsonValue.AddNull;
var
  A: PJsonArray;
begin
  A := PJsonArray(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (A.FSubtype <> SUBTYPE_ARRAY) then
    raise EInvalidOperation.Create('AddNull can only be used for JSON arrays');

  A.AddNull;
end;

function TJsonValue.AddOrSetArray(const AName: JsonString): TJsonValue;
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (D.FSubtype <> SUBTYPE_DICT) then
    raise EInvalidOperation.Create('AddOrSetArray can only be used for JSON dictionaries');

  Result := D.AddOrSetArray(AName);
end;

function TJsonValue.AddOrSetDictionary(const AName: JsonString): TJsonValue;
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (D.FSubtype <> SUBTYPE_DICT) then
    raise EInvalidOperation.Create('AddOrSetDictionary can only be used for JSON dictionaries');

  Result := D.AddOrSetDictionary(AName);
end;

procedure TJsonValue.AddOrSetNull(const AName: JsonString);
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (D.FSubtype <> SUBTYPE_DICT) then
    raise EInvalidOperation.Create('AddOrSetNull can only be used for JSON dictionaries');

  D.AddOrSetNull(AName);
end;

procedure TJsonValue.AddOrSetValue(const AName: JsonString; const AValue: UInt32);
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (D.FSubtype <> SUBTYPE_DICT) then
    raise EInvalidOperation.Create('AddOrSetValue can only be used for JSON dictionaries');

  D.AddOrSetValue(AName, AValue);
end;

procedure TJsonValue.AddOrSetValue(const AName: JsonString; const AValue: Int32);
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (D.FSubtype <> SUBTYPE_DICT) then
    raise EInvalidOperation.Create('AddOrSetValue can only be used for JSON dictionaries');

  D.AddOrSetValue(AName, AValue);
end;

procedure TJsonValue.AddOrSetValue(const AName: JsonString; const AValue: Boolean);
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (D.FSubtype <> SUBTYPE_DICT) then
    raise EInvalidOperation.Create('AddOrSetValue can only be used for JSON dictionaries');

  D.AddOrSetValue(AName, AValue);
end;

procedure TJsonValue.AddOrSetValue(const AName: JsonString; const AValue: Int64);
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (D.FSubtype <> SUBTYPE_DICT) then
    raise EInvalidOperation.Create('AddOrSetValue can only be used for JSON dictionaries');

  D.AddOrSetValue(AName, AValue);
end;

procedure TJsonValue.AddOrSetValue(const AName, AValue: JsonString);
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (D.FSubtype <> SUBTYPE_DICT) then
    raise EInvalidOperation.Create('AddOrSetValue can only be used for JSON dictionaries');

  D.AddOrSetValue(AName, AValue);
end;

procedure TJsonValue.AddOrSetValue(const AName: JsonString; const AValue: Double);
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (D.FSubtype <> SUBTYPE_DICT) then
    raise EInvalidOperation.Create('AddOrSetValue can only be used for JSON dictionaries');

  D.AddOrSetValue(AName, AValue);
end;

procedure TJsonValue.AddOrSetValue(const AName: JsonString; const AValue: UInt64);
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (D.FSubtype <> SUBTYPE_DICT) then
    raise EInvalidOperation.Create('AddOrSetValue can only be used for JSON dictionaries');

  D.AddOrSetValue(AName, AValue);
end;

procedure TJsonValue.AddOrSetValue(const AName: JsonString; const AValue: Single);
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (D.FSubtype <> SUBTYPE_DICT) then
    raise EInvalidOperation.Create('AddOrSetValue can only be used for JSON dictionaries');

  D.AddOrSetValue(AName, AValue);
end;

procedure TJsonValue.Clear;
var
  A: PJsonArray;
  D: PJsonDictionary absolute A;
begin
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) then
    raise EInvalidOperation.Create('Clear can only be used for JSON arrays and dictionaries');

  A := PJsonArray(FBITS and VALUE_MASK);
  case A.FSubtype of
    SUBTYPE_ARRAY:
      A.Clear;

    SUBTYPE_DICT:
      D.Clear;
  else
    raise EInvalidOperation.Create('Clear can only be used for JSON arrays and dictionaries');
  end;
end;

function TJsonValue.Contains(const AName: JsonString): Boolean;
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (D.FSubtype <> SUBTYPE_DICT) then
    raise EInvalidOperation.Create('Contains can only be used for JSON dictionaries');

  Result := D.Contains(AName);
end;

class function TJsonValue.Create: TJsonValue;
begin
  Result.FBits := 0; // Null
end;

class function TJsonValue.Create(const AValue: Boolean): TJsonValue;
begin
  Result.FBits := (1 + Ord(AValue)) shl TYPE_BITS;
end;

class function TJsonValue.Create(const AValue: Double): TJsonValue;
var
  P: PHeapFloat;
begin
  GetMem(P, SizeOf(THeapFloat));
  Assert((UIntPtr(P) and TYPE_MASK) = 0);
  P.SubType := SUBTYPE_FLOAT;
  P.Value := AValue;
  Result.FBits := TYPE_HEAP or UIntPtr(P);
end;

class function TJsonValue.Create(const AValue: Int32): TJsonValue;
{$IFDEF CPU32BITS}
var
  P: PHeapInt;
{$ENDIF}
begin
  {$IFDEF CPU64BITS}
  Result.FBits := TYPE_INT or (Int64(AValue) shl TYPE_BITS);
  {$ELSE}
  if (AValue >= MIN_INT) and (AValue <= MAX_INT) then
    Result.FBits := TYPE_INT or (AValue shl TYPE_BITS)
  else
  begin
    GetMem(P, SizeOf(THeapInt));
    Assert((UIntPtr(P) and TYPE_MASK) = 0);
    P.SubType := SUBTYPE_INT;
    P.Value := AValue;
    Result.FBits := TYPE_HEAP or UIntPtr(P);
  end;
  {$ENDIF}
end;

class function TJsonValue.Create(const AValue: Int64): TJsonValue;
var
  P: PHeapInt;
begin
  {$IFDEF CPU64BITS}
  if (AValue >= MIN_INT) and (AValue <= MAX_INT) then
  begin
    Result.FBits := TYPE_INT or (AValue shl TYPE_BITS);
    Exit;
  end;
  {$ENDIF}

  GetMem(P, SizeOf(THeapInt));
  Assert((UIntPtr(P) and TYPE_MASK) = 0);
  P.SubType := SUBTYPE_INT;
  P.Value := AValue;
  Result.FBits := TYPE_HEAP or UIntPtr(P);
end;

class function TJsonValue.Create(const AValue: JsonString): TJsonValue;
var
  P: Pointer;
begin
  P := nil;
  JsonString(P) := AValue; // Increases ref count
  Assert((UIntPtr(P) and TYPE_MASK) = 0);
  Result.FBits := TYPE_STR or UIntPtr(P);
end;

class function TJsonValue.Create(const AValue: UInt64): TJsonValue;
var
  P: PHeapInt;
begin
  {$IFDEF CPU64BITS}
  if (Int64(AValue) >= MIN_INT) and (Int64(AValue) <= MAX_INT) then
  begin
    Result.FBits := TYPE_INT or (AValue shl TYPE_BITS);
    Exit;
  end;
  {$ENDIF}

  GetMem(P, SizeOf(THeapInt));
  Assert((UIntPtr(P) and TYPE_MASK) = 0);
  P.SubType := SUBTYPE_INT;
  P.Value := Int64(AValue);
  Result.FBits := TYPE_HEAP or UIntPtr(P);
end;

class function TJsonValue.Create(const AValue: UInt32): TJsonValue;
{$IFDEF CPU32BITS}
var
  P: PHeapInt;
{$ENDIF}
begin
  {$IFDEF CPU64BITS}
  Result.FBits := TYPE_INT or (UInt64(AValue) shl TYPE_BITS);
  {$ELSE}
  if (Int32(AValue) >= MIN_INT) and (Int32(AValue) <= MAX_INT) then
    Result.FBits := TYPE_INT or (AValue shl TYPE_BITS)
  else
  begin
    GetMem(P, SizeOf(THeapInt));
    Assert((UIntPtr(P) and TYPE_MASK) = 0);
    P.SubType := SUBTYPE_INT;
    P.Value := AValue;
    Result.FBits := TYPE_HEAP or UIntPtr(P);
  end;
  {$ENDIF}
end;

class function TJsonValue.CreateArray: TJsonValue;
var
  P: PJsonArray;
begin
  GetMem(P, SizeOf(TJsonArray));
  Assert((UIntPtr(P) and TYPE_MASK) = 0);
  P.Init;
  Result.FBits := TYPE_HEAP or UIntPtr(P);
end;

class function TJsonValue.CreateDictionary: TJsonValue;
var
  P: PJsonDictionary;
begin
  GetMem(P, SizeOf(TJsonDictionary));
  Assert((UIntPtr(P) and TYPE_MASK) = 0);
  P.Init;
  Result.FBits := TYPE_HEAP or UIntPtr(P);
end;

procedure TJsonValue.Delete(const AIndex: Integer);
var
  A: PJsonArray;
  D: PJsonDictionary absolute A;
begin
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) then
    raise EInvalidOperation.Create('Delete can only be used for JSON arrays and dictionaries');

  A := PJsonArray(FBITS and VALUE_MASK);
  case A.FSubtype of
    SUBTYPE_ARRAY:
      A.Delete(AIndex);

    SUBTYPE_DICT:
      D.Delete(AIndex);
  else
    raise EInvalidOperation.Create('Delete can only be used for JSON arrays and dictionaries');
  end;
end;

class operator TJsonValue.Equal(const ALeft, ARight: TJsonValue): Boolean;
var
  L, R: Pointer;
  LI: PHeapInt absolute L;
  RI: PHeapInt absolute R;
  LF: PHeapFloat absolute L;
  RF: PHeapFloat absolute R;
  LA: PJsonArray absolute L;
  RA: PJsonArray absolute R;
  LD: PJsonDictionary absolute L;
  RD: PJsonDictionary absolute R;
begin
  if (ALeft.FBits = ARight.FBits) then
    { This handles TYPE_FIXED and TYPE_INT }
    Exit(True);

  if ((ALeft.FBits and TYPE_MASK) <> (ARight.FBits and TYPE_MASK)) then
    Exit(False);

  case ALeft.FBits and TYPE_MASK of
    TYPE_STR:
      Result := (JsonString(ALeft.FBits and VALUE_MASK) = JsonString(ARight.FBits and VALUE_MASK));

    TYPE_HEAP:
      begin
        L := Pointer(ALeft.FBits and VALUE_MASK);
        R := Pointer(ARight.FBits and VALUE_MASK);
        if (LI.SubType <> RI.SubType) then
          Exit(False);

        case LI.SubType of
          SUBTYPE_ARRAY:
            Result := LA.Equals(RA^);

          SUBTYPE_DICT:
            Result := LD.Equals(RD^);

          SUBTYPE_INT:
            Result := (LI.Value = RI.Value);

          SUBTYPE_FLOAT:
            Result := (LF.Value = RF.Value);
        else
          Result := False;
        end;
      end;
  else
    Result := False;
  end;
end;

procedure TJsonValue.Free;
var
  P: Pointer;
  A: PJsonArray absolute P;
  D: PJsonDictionary absolute P;
begin
  case FBits and TYPE_MASK of
    TYPE_STR:
      begin
        P := Pointer(FBits and VALUE_MASK);
        JsonString(P) := ''; // Decreases ref count
      end;

    TYPE_HEAP:
      begin
        P := Pointer(FBits and VALUE_MASK);
        case A.FSubtype of
          SUBTYPE_ARRAY:
            A.Free;

          SUBTYPE_DICT:
            D.Free;
        else
          FreeMem(P);
        end;
      end;
  end;
  FBits := 0;
end;

function TJsonValue.GetCount: Integer;
var
  A: PJsonArray;
  D: PJsonDictionary absolute A;
begin
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) then
    Exit(0);

  A := PJsonArray(FBITS and VALUE_MASK);
  case A.FSubtype of
    SUBTYPE_ARRAY:
      Result := A.FCount;

    SUBTYPE_DICT:
      Result := D.FCount;
  else
    Result := 0;
  end;
end;

function TJsonValue.GetElement(const AIndex: Integer): PJsonElement;
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) = TYPE_HEAP) and (D.FSubtype = SUBTYPE_DICT) then
    Exit(D.GetElement(AIndex));

  Result := @_JSON_NULL_ELEMENT;
end;

function TJsonValue.GetIsArray: Boolean;
begin
  Result := ((FBits and TYPE_MASK) = TYPE_HEAP)
    and (PJsonArray(FBits and VALUE_MASK).FSubtype = SUBTYPE_ARRAY);
end;

function TJsonValue.GetIsBoolean: Boolean;
begin
  Result := ((FBits and TYPE_MASK) = TYPE_FIXED) and (FBits <> 0);
end;

function TJsonValue.GetIsDictionary: Boolean;
begin
  Result := ((FBits and TYPE_MASK) = TYPE_HEAP)
    and (PJsonArray(FBits and VALUE_MASK).FSubtype = SUBTYPE_DICT);
end;

function TJsonValue.GetIsFloat: Boolean;
begin
  Result := ((FBits and TYPE_MASK) = TYPE_HEAP)
    and (PHeapFloat(FBits and VALUE_MASK).Subtype = SUBTYPE_FLOAT);
end;

function TJsonValue.GetIsNull: Boolean;
begin
  Result := (FBits = 0);
end;

function TJsonValue.GetIsNumeric: Boolean;
var
  I: PHeapInt;
begin
  case FBits and TYPE_MASK of
    TYPE_INT:
      Result := True;

    TYPE_HEAP:
      begin
        I := PHeapInt(FBits and VALUE_MASK);
        Result := (I.SubType >= SUBTYPE_INT);
      end;
  else
    Result := False;
  end;
end;

function TJsonValue.GetIsOrdinal: Boolean;
var
  I: PHeapInt;
begin
  case FBits and TYPE_MASK of
    TYPE_INT:
      Result := True;

    TYPE_HEAP:
      begin
        I := PHeapInt(FBits and VALUE_MASK);
        Result := (I.SubType = SUBTYPE_INT);
      end;
  else
    Result := False;
  end;
end;

function TJsonValue.GetIsString: Boolean;
begin
  Result := ((FBits and TYPE_MASK) = TYPE_STR);
end;

function TJsonValue.GetItem(const AIndex: Integer): TJsonValue;
var
  A: PJsonArray;
begin
  A := PJsonArray(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) = TYPE_HEAP) and (A.FSubtype = SUBTYPE_ARRAY) then
    Exit(A.GetItem(AIndex));

  Result.FBits := 0;
end;

function TJsonValue.GetValueType: TJsonValueType;
var
  I: PHeapInt;
begin
  case FBits and TYPE_MASK of
    TYPE_FIXED:
      if (FBits = 0) then
        Result := TJsonValueType.Null
      else
        Result := TJsonValueType.Boolean;

    TYPE_INT:
      Result := TJsonValueType.Ordinal;

    TYPE_STR:
      Result := TJsonValueType.String;

    TYPE_HEAP:
      begin
        I := PHeapInt(FBits and VALUE_MASK);
        case I.SubType of
          SUBTYPE_ARRAY:
            Result := TJsonValueType.&Array;

          SUBTYPE_DICT:
            Result := TJsonValueType.Dictionary;

          SUBTYPE_INT:
            Result := TJsonValueType.Ordinal;

          SUBTYPE_FLOAT:
            Result := TJsonValueType.Float;
        else
          Result := TJsonValueType.Null;
          Assert(False);
        end;
      end;
  else
    Result := TJsonValueType.Null;
    Assert(False);
  end;
end;

function TJsonValue.GetValue(const AName: JsonString): TJsonValue;
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) = TYPE_HEAP) and (D.FSubtype = SUBTYPE_DICT) then
    Exit(D.GetValue(AName));

  Result.FBits := 0;
end;

class operator TJsonValue.Implicit(const AValue: TJsonValue): Int8;
begin
  Result := AValue.ToInt32(0);
end;

class operator TJsonValue.Implicit(const AValue: TJsonValue): Single;
begin
  Result := AValue.ToDouble(0);
end;

class operator TJsonValue.Implicit(const AValue: TJsonValue): UInt64;
begin
  Result := AValue.ToInt64(0);
end;

class operator TJsonValue.Implicit(const AValue: TJsonValue): UInt32;
begin
  Result := AValue.ToInt32(0);
end;

class operator TJsonValue.Implicit(const AValue: TJsonValue): UInt8;
begin
  Result := AValue.ToInt32(0);
end;

class operator TJsonValue.Implicit(const AValue: TJsonValue): Int32;
begin
  Result := AValue.ToInt32(0);
end;

class operator TJsonValue.Implicit(const AValue: TJsonValue): Int64;
begin
  Result := AValue.ToInt64(0);
end;

class operator TJsonValue.Implicit(const AValue: TJsonValue): Double;
begin
  Result := AValue.ToDouble(0);
end;

class operator TJsonValue.Implicit(const AValue: TJsonValue): Boolean;
begin
  Result := AValue.ToBoolean(False);
end;

class operator TJsonValue.Implicit(const AValue: TJsonValue): JsonString;
begin
  Result := AValue.ToString('');
end;

class operator TJsonValue.Implicit(const AValue: TJsonValue): UInt16;
begin
  Result := AValue.ToInt32(0);
end;

class operator TJsonValue.Implicit(const AValue: TJsonValue): Int16;
begin
  Result := AValue.ToInt32(0);
end;

class operator TJsonValue.NotEqual(const ALeft, ARight: TJsonValue): Boolean;
begin
  Result := not (ALeft = ARight);
end;

function TJsonValue.IndexOfName(const AName: JsonString): Integer;
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (D.FSubtype <> SUBTYPE_DICT) then
    raise EInvalidOperation.Create('IndexOfName can only be used for JSON dictionaries');

  Result := D.IndexOfName(AName);
end;

class function TJsonValue.ReadFrom(const AReader: IJsonReader;
  const AState: TJsonReaderState): TJsonValue;
begin
  case AState of
    TJsonReaderState.Null:
      begin
        AReader.ReadNull;
        Result := TJsonValue.Create;
      end;

    TJsonReaderState.Boolean:
      Result := TJsonValue.Create(AReader.ReadBoolean);

    TJsonReaderState.Ordinal:
      Result := TJsonValue.Create(AReader.ReadOrdinal);

    TJsonReaderState.Float:
      Result := TJsonValue.Create(AReader.ReadFloat);

    TJsonReaderState.String:
      Result := TJsonValue.Create(AReader.ReadString);

    TJsonReaderState.StartArray:
      begin
        Result := TJsonValue.CreateArray;
        try
          PJsonArray(Result.FBits and VALUE_MASK).ReadFrom(AReader);
        except
          Result.Free;
          raise;
        end;
      end;

    TJsonReaderState.StartDictionary:
      begin
        Result := TJsonValue.CreateDictionary;
        try
          PJsonDictionary(Result.FBits and VALUE_MASK).ReadFrom(AReader);
        except
          Result.Free;
          raise;
        end;
      end;
  else
    Assert(False);
    Result.FBits := 0;
  end;
end;

procedure TJsonValue.Remove(const AName: JsonString);
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (D.FSubtype <> SUBTYPE_DICT) then
    raise EInvalidOperation.Create('Remove can only be used for JSON dictionaries');

  D.Remove(AName);
end;

function TJsonValue.ToBoolean(const ADefault: Boolean): Boolean;
var
  I: PHeapInt;
  F: PHeapFloat absolute I;
begin
  case FBits and TYPE_MASK of
    TYPE_FIXED:
      Result := (FBits = (2 shl TYPE_BITS));

    TYPE_INT,
    TYPE_STR:
      Result := ((FBits and VALUE_MASK) <> 0);

    TYPE_HEAP:
      begin
        I := PHeapInt(FBits and VALUE_MASK);
        case I.SubType of
          SUBTYPE_INT:
            Result := (I.Value <> 0);

          SUBTYPE_FLOAT:
            Result := (F.Value <> 0);
        else
          Result := ADefault;
        end;
      end;
  else
    Result := ADefault;
  end;
end;

function TJsonValue.ToDouble(const ADefault: Double): Double;
var
  N: NativeInt;
  I: PHeapInt;
  F: PHeapFloat absolute I;
begin
  case FBits and TYPE_MASK of
    TYPE_FIXED:
      Result := Ord(FBits = (2 shl TYPE_BITS));

    TYPE_INT:
      begin
        N := FBits shr TYPE_BITS;
        if (NativeInt(FBits) < 0) then
          N := N or EXTEND_BITS;
        Result := N;
      end;

    TYPE_STR:
      Result := StrToFloatDef(JsonString(FBits and VALUE_MASK), ADefault, USFormatSettings);

    TYPE_HEAP:
      begin
        I := PHeapInt(FBits and VALUE_MASK);
        case I.SubType of
          SUBTYPE_INT:
            Result := I.Value;

          SUBTYPE_FLOAT:
            Result := F.Value;
        else
          Result := ADefault;
        end;
      end;
  else
    Result := ADefault;
  end;
end;

function TJsonValue.ToInt32(const ADefault: Int32): Int32;
var
  I: PHeapInt;
  F: PHeapFloat absolute I;
begin
  case FBits and TYPE_MASK of
    TYPE_FIXED:
      Result := Ord(FBits = (2 shl TYPE_BITS));

    TYPE_INT:
      begin
        Result := FBits shr TYPE_BITS;
        {$IFDEF CPU32BITS}
        if (NativeInt(FBits) < 0) then
          Result := Result or EXTEND_BITS;
        {$ENDIF}
      end;

    TYPE_STR:
      Result := StrToIntDef(JsonString(FBits and VALUE_MASK), ADefault);

    TYPE_HEAP:
      begin
        I := PHeapInt(FBits and VALUE_MASK);
        case I.SubType of
          SUBTYPE_INT:
            Result := I.Value;

          SUBTYPE_FLOAT:
            Result := Trunc(F.Value);
        else
          Result := ADefault;
        end;
      end;
  else
    Result := ADefault;
  end;
end;

function TJsonValue.ToInt64(const ADefault: Int64): Int64;
var
  I: PHeapInt;
  F: PHeapFloat absolute I;
begin
  case FBits and TYPE_MASK of
    TYPE_FIXED:
      Result := Ord(FBits = (2 shl TYPE_BITS));

    TYPE_INT:
      begin
        Result := FBits shr TYPE_BITS;
        if (NativeInt(FBits) < 0) then
          Result := Result or EXTEND_BITS;
      end;

    TYPE_STR:
      Result := StrToInt64Def(JsonString(FBits and VALUE_MASK), ADefault);

    TYPE_HEAP:
      begin
        I := PHeapInt(FBits and VALUE_MASK);
        case I.SubType of
          SUBTYPE_INT:
            Result := I.Value;

          SUBTYPE_FLOAT:
            Result := Trunc(F.Value);
        else
          Result := ADefault;
        end;
      end;
  else
    Result := ADefault;
  end;
end;

function TJsonValue.ToInteger(const ADefault: Integer): Integer;
begin
  Result := ToInt32(ADefault);
end;

function TJsonValue.ToJson(const AIndent: Boolean): JsonString;
var
  Writer: IJsonWriter;
begin
  Writer := TJsonWriter.Create(AIndent);
  WriteTo(Writer);
  Result := Writer.ToJson;
end;

function TJsonValue.ToString(const ADefault: JsonString): JsonString;
var
  N: NativeInt;
  I: PHeapInt;
  F: PHeapFloat absolute I;
begin
  case FBits and TYPE_MASK of
    TYPE_FIXED:
      if (FBits = 0) then
//        Result := 'null'
        Result := ''
      else if (FBits = (2 shl TYPE_BITS)) then
        Result := 'true'
      else
        Result := 'false';

    TYPE_INT:
      begin
        N := FBits shr TYPE_BITS;
        if (NativeInt(FBits) < 0) then
          N := N or EXTEND_BITS;
        {$IFDEF JSON_UTF8}
        Result := IntToUtf8Str(N);
        {$ELSE}
        Result := IntToStr(N);
        {$ENDIF}
      end;

    TYPE_STR:
      Result := JsonString(FBits and VALUE_MASK);

    TYPE_HEAP:
      begin
        I := PHeapInt(FBits and VALUE_MASK);
        case I.SubType of
          SUBTYPE_INT:
            begin
              {$IFDEF JSON_UTF8}
              Result := IntToUtf8Str(I.Value);
              {$ELSE}
              Result := IntToStr(I.Value);
              {$ENDIF}
            end;

          SUBTYPE_FLOAT:
            {$IFDEF JSON_UTF8}
            Result := FloatToUtf8Str(F.Value, USFormatSettings);
            {$ELSE}
            Result := FloatToStr(F.Value, USFormatSettings);
            {$ENDIF}
        else
          Result := ADefault;
        end;
      end;
  else
    Result := ADefault;
  end;
end;

function TJsonValue.TryGetValue(const AName: JsonString;
  out AValue: TJsonValue): Boolean;
var
  D: PJsonDictionary;
begin
  D := PJsonDictionary(FBITS and VALUE_MASK);
  if ((FBits and TYPE_MASK) <> TYPE_HEAP) or (D.FSubtype <> SUBTYPE_DICT) then
    raise EInvalidOperation.Create('TryGetValue can only be used for JSON dictionaries');

  Result := D.TryGetValue(AName, AValue);
end;

procedure TJsonValue.WriteTo(const AWriter: IJsonWriter);
var
  I64: Int64;
  I: PHeapInt;
  F: PHeapFloat absolute I;
  A: PJsonArray absolute I;
  D: PJsonDictionary absolute I;
begin
  case FBits and TYPE_MASK of
    TYPE_FIXED:
      if (FBits = 0) then
        AWriter.WriteNull
      else
        AWriter.WriteBoolean(FBits = (2 shl TYPE_BITS));

    TYPE_INT:
      begin
        I64 := FBits shr TYPE_BITS;
        if (NativeInt(FBits) < 0) then
          I64 := I64 or EXTEND_BITS;
        AWriter.WriteOrdinal(I64);
      end;

    TYPE_STR:
      AWriter.WriteString(JsonString(FBits and VALUE_MASK));

    TYPE_HEAP:
      begin
        I := PHeapInt(FBits and VALUE_MASK);
        case I.SubType of
          SUBTYPE_ARRAY:
            A.WriteTo(AWriter);

          SUBTYPE_DICT:
            D.WriteTo(AWriter);

          SUBTYPE_INT:
            AWriter.WriteOrdinal(I.Value);

          SUBTYPE_FLOAT:
            AWriter.WriteFloat(F.Value);
        else
          Assert(False);
        end;
      end;
  else
    Assert(False);
  end;
end;

{ TJsonValue.TJsonArray }

procedure TJsonValue.TJsonArray.Add(const AValue: Int64);
begin
  if (FCount >= FCapacity) then
    Grow;

  FItems[FCount] := TJsonValue.Create(AValue);
  Inc(FCount);
end;

procedure TJsonValue.TJsonArray.Add(const AValue: UInt32);
begin
  if (FCount >= FCapacity) then
    Grow;

  FItems[FCount] := TJsonValue.Create(AValue);
  Inc(FCount);
end;

procedure TJsonValue.TJsonArray.Add(const AValue: Int32);
begin
  if (FCount >= FCapacity) then
    Grow;

  FItems[FCount] := TJsonValue.Create(AValue);
  Inc(FCount);
end;

procedure TJsonValue.TJsonArray.Add(const AValue: Boolean);
begin
  if (FCount >= FCapacity) then
    Grow;

  FItems[FCount] := TJsonValue.Create(AValue);
  Inc(FCount);
end;

procedure TJsonValue.TJsonArray.Add(const AValue: JsonString);
begin
  if (FCount >= FCapacity) then
    Grow;

  FItems[FCount] := TJsonValue.Create(AValue);
  Inc(FCount);
end;

procedure TJsonValue.TJsonArray.Add(const AValue: Double);
begin
  if (FCount >= FCapacity) then
    Grow;

  FItems[FCount] := TJsonValue.Create(AValue);
  Inc(FCount);
end;

procedure TJsonValue.TJsonArray.Add(const AValue: Single);
begin
  if (FCount >= FCapacity) then
    Grow;

  FItems[FCount] := TJsonValue.Create(AValue);
  Inc(FCount);
end;

procedure TJsonValue.TJsonArray.Add(const AValue: UInt64);
begin
  if (FCount >= FCapacity) then
    Grow;

  FItems[FCount] := TJsonValue.Create(AValue);
  Inc(FCount);
end;

function TJsonValue.TJsonArray.AddArray: TJsonValue;
begin
  if (FCount >= FCapacity) then
    Grow;

  Result := TJsonValue.CreateArray;
  FItems[FCount] := Result;
  Inc(FCount);
end;

function TJsonValue.TJsonArray.AddDictionary: TJsonValue;
begin
  if (FCount >= FCapacity) then
    Grow;

  Result := TJsonValue.CreateDictionary;
  FItems[FCount] := Result;
  Inc(FCount);
end;

procedure TJsonValue.TJsonArray.AddNull;
begin
  if (FCount >= FCapacity) then
    Grow;

  FItems[FCount] := TJsonValue.Create;
  Inc(FCount);
end;

procedure TJsonValue.TJsonArray.Clear;
var
  I: Integer;
begin
  for I := 0 to FCount - 1 do
    FItems[I].Free;
  FreeMem(FItems);
  FItems := nil;
  FCount := 0;
  FCapacity := 0;
end;

procedure TJsonValue.TJsonArray.Delete(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);

  FItems[AIndex].Free;
  Dec(FCount);
  if (AIndex <> FCount) then
    Move(FItems[AIndex + 1], FItems[AIndex], (FCount - AIndex) * SizeOf(TJsonValue));
end;

function TJsonValue.TJsonArray.Equals(const AOther: TJsonArray): Boolean;
var
  I: Integer;
begin
  if (@AOther = @Self) then
    Exit(True);

  if (AOther.FCount <> FCount) then
    Exit(False);

  for I := 0 to FCount - 1 do
  begin
    if (AOther.FItems[I] <> FItems[I]) then
      Exit(False);
  end;

  Result := True;
end;

procedure TJsonValue.TJsonArray.Free;
begin
  Clear;
  FreeMem(@Self);
end;

function TJsonValue.TJsonArray.GetItem(const AIndex: Integer): TJsonValue;
begin
  if (AIndex >= 0) and (AIndex < FCount) then
    Exit(FItems[AIndex]);

  Result.FBits := 0;
end;

procedure TJsonValue.TJsonArray.Grow;
begin
  if (FCapacity > 64) then
    Inc(FCapacity, FCapacity div 4)
  else if (FCapacity > 8) then
    Inc(FCapacity, 16)
  else
    Inc(FCapacity, 4);
  ReallocMem(FItems, FCapacity * SizeOf(TJsonValue));
end;

procedure TJsonValue.TJsonArray.Init;
begin
  FSubtype := SUBTYPE_ARRAY;
  FItems := nil;
  FCount := 0;
  FCapacity := 0;
end;

procedure TJsonValue.TJsonArray.ReadFrom(const AReader: IJsonReader);
var
  State: TJsonReaderState;
  Value: TJsonValue;
begin
  AReader.ReadStartArray;
  while AReader.Next(State) and (State <> TJsonReaderState.EndArray) do
  begin
    Value := TJsonValue.ReadFrom(AReader, State);

    if (FCount >= FCapacity) then
      Grow;

    FItems[FCount] := Value;
    Inc(FCount);
  end;
  AReader.ReadEndArray;
end;

procedure TJsonValue.TJsonArray.WriteTo(const AWriter: IJsonWriter);
var
  I: Integer;
  Item: PJsonValue;
begin
  AWriter.WriteStartArray;
  Item := FItems;
  for I := 0 to FCount - 1 do
  begin
    Item.WriteTo(AWriter);
    Inc(Item);
  end;
  AWriter.WriteEndArray;
end;

{ TJsonValue.TElement }

class operator TJsonValue.TElement.Equal(const A, B: TElement): Boolean;
begin
  Result := (A.FName = B.FName) and (TJsonValue(A.FValue) = TJsonValue(B.FValue));
end;

procedure TJsonValue.TElement.Free;
begin
  FName := '';
  TJsonValue(FValue).Free;
end;

class operator TJsonValue.TElement.NotEqual(const A, B: TElement): Boolean;
begin
  Result := not (A = B);
end;

{ TJsonValue.TIndexMap }

procedure TJsonValue.TIndexMap.Add(const AName: JsonString; const AIndex: Integer);
var
  Mask, Index, HashCode, HC: Integer;
begin
  if (FCount >= FGrowThreshold) then
    Resize(FCapacity * 2);

  HashCode := MurmurHash2(AName[Low(JsonString)], Length(AName) * SizeOf(JsonChar));
  Mask := FCapacity - 1;
  Index := HashCode and Mask;

  while True do
  begin
    HC := FEntries[Index].HashCode;
    if (HC = EMPTY_HASH) then
      Break;

    if (HC = HashCode) and (FEntries[Index].Name = AName) then
    begin
      FEntries[Index].Index := AIndex;
      Exit;
    end;

    Index := (Index + 1) and Mask;
  end;

  FEntries[Index].HashCode := HashCode;
  FEntries[Index].Name := AName;
  FEntries[Index].Index := AIndex;
  Inc(FCount);
end;

procedure TJsonValue.TIndexMap.Clear;
var
  I: Integer;
begin
  for I := 0 to FCapacity - 1 do
    FEntries[I].Name := '';
  FCount := 0;
end;

procedure TJsonValue.TIndexMap.Free;
begin
  Clear;
  FreeMem(FEntries);
  FreeMem(@Self);
end;

function TJsonValue.TIndexMap.Get(const AName: JsonString): Integer;
var
  Mask, Index, HashCode, HC: Integer;
begin
  if (FCount = 0) then
    Exit(-1);

  Mask := FCapacity - 1;
  HashCode := MurmurHash2(AName[Low(JsonString)], Length(AName) * SizeOf(JsonChar));
  Index := HashCode and Mask;

  while True do
  begin
    HC := FEntries[Index].HashCode;
    if (HC = EMPTY_HASH) then
      Exit(-1);

    if (HC = HashCode) and (FEntries[Index].Name = AName) then
      Exit(FEntries[Index].Index);

    Index := (Index + 1) and Mask;
  end;
end;

procedure TJsonValue.TIndexMap.Resize(ANewSize: Integer);
const
  MIN_SIZE = 16; // Must be POT and >= 1.33 * INDICES_COUNT_THRESHOLD
var
  NewMask, I, NewIndex: Integer;
  OldEntries, NewEntries: PMapEntry;
begin
  if (ANewSize < MIN_SIZE) then
    ANewSize := MIN_SIZE;
  NewMask := ANewSize - 1;
  GetMem(NewEntries, ANewSize * SizeOf(TMapEntry));
  FillChar(NewEntries^, ANewSize * SizeOf(TMapEntry), 0);
  for I := 0 to ANewSize - 1 do
    NewEntries[I].HashCode := EMPTY_HASH;
  OldEntries := FEntries;

  for I := 0 to FCapacity - 1 do
  begin
    if (OldEntries[I].HashCode <> EMPTY_HASH) then
    begin
      NewIndex := OldEntries[I].HashCode and NewMask;
      while (NewEntries[NewIndex].HashCode <> EMPTY_HASH) do
        NewIndex := (NewIndex + 1) and NewMask;
      NewEntries[NewIndex] := OldEntries[I];
    end;
  end;

  { Release original entries (and names) }
  for I := 0 to FCapacity - 1 do
    OldEntries[I].Name := '';
  FreeMem(OldEntries);

  FCapacity := ANewSize;
  FEntries := NewEntries;
  FGrowThreshold := (ANewSize * 3) shr 2; // 75%
end;

{ TJsonValue.TJsonDictionary }

function TJsonValue.TJsonDictionary.AddOrReplaceElement(
  const AName: JsonString): PElement;
var
  Index: Integer;
begin
  Index := IndexOfName(AName);
  if (Index >= 0) then
  begin
    Result := @FElements[Index];
    TJsonValue(Result.FValue).Free;
    Result.FValue := 0;
    Exit;
  end;

  if (FCount >= FCapacity) then
  begin
    if (FCapacity > 64) then
      Inc(FCapacity, FCapacity div 4)
    else if (FCapacity > 8) then
      Inc(FCapacity, 16)
    else
      Inc(FCapacity, 4);
    ReallocMem(FElements, FCapacity * SizeOf(TElement));
    FillChar(FElements[FCount], (FCapacity - FCount) * SizeOf(TElement), 0);
  end;

  Result := @FElements[FCount];
  Result.FName := AName;
  Inc(FCount);

  if (FIndices = nil) then
    RebuildIndices
  else
    FIndices.Add(AName, FCount - 1);
end;

function TJsonValue.TJsonDictionary.AddOrSetArray(const AName: JsonString): TJsonValue;
var
  Element: PElement;
begin
  Element := AddOrReplaceElement(AName);
  Result := TJsonValue.CreateArray;
  Element.FValue := Result.FBits;
end;

function TJsonValue.TJsonDictionary.AddOrSetDictionary(
  const AName: JsonString): TJsonValue;
var
  Element: PElement;
begin
  Element := AddOrReplaceElement(AName);
  Result := TJsonValue.CreateDictionary;
  Element.FValue := Result.FBits;
end;

procedure TJsonValue.TJsonDictionary.AddOrSetNull(const AName: JsonString);
var
  Element: PElement;
begin
  Element := AddOrReplaceElement(AName);
  Element.FValue := 0;
end;

procedure TJsonValue.TJsonDictionary.AddOrSetValue(const AName: JsonString;
  const AValue: Int64);
var
  Element: PElement;
begin
  Element := AddOrReplaceElement(AName);
  TJsonValue(Element.FValue) := TJsonValue.Create(AValue);;
end;

procedure TJsonValue.TJsonDictionary.AddOrSetValue(const AName: JsonString;
  const AValue: UInt32);
var
  Element: PElement;
begin
  Element := AddOrReplaceElement(AName);
  TJsonValue(Element.FValue) := TJsonValue.Create(AValue);;
end;

procedure TJsonValue.TJsonDictionary.AddOrSetValue(const AName: JsonString;
  const AValue: Int32);
var
  Element: PElement;
begin
  Element := AddOrReplaceElement(AName);
  TJsonValue(Element.FValue) := TJsonValue.Create(AValue);;
end;

procedure TJsonValue.TJsonDictionary.AddOrSetValue(const AName: JsonString;
  const AValue: Boolean);
var
  Element: PElement;
begin
  Element := AddOrReplaceElement(AName);
  TJsonValue(Element.FValue) := TJsonValue.Create(AValue);;
end;

procedure TJsonValue.TJsonDictionary.AddOrSetValue(const AName: JsonString;
  const AValue: UInt64);
var
  Element: PElement;
begin
  Element := AddOrReplaceElement(AName);
  TJsonValue(Element.FValue) := TJsonValue.Create(AValue);;
end;

procedure TJsonValue.TJsonDictionary.AddOrSetValue(const AName, AValue: JsonString);
var
  Element: PElement;
begin
  Element := AddOrReplaceElement(AName);
  TJsonValue(Element.FValue) := TJsonValue.Create(AValue);;
end;

procedure TJsonValue.TJsonDictionary.AddOrSetValue(const AName: JsonString;
  const AValue: Double);
var
  Element: PElement;
begin
  Element := AddOrReplaceElement(AName);
  TJsonValue(Element.FValue) := TJsonValue.Create(AValue);;
end;

procedure TJsonValue.TJsonDictionary.AddOrSetValue(const AName: JsonString;
  const AValue: Single);
var
  Element: PElement;
begin
  Element := AddOrReplaceElement(AName);
  TJsonValue(Element.FValue) := TJsonValue.Create(AValue);;
end;

procedure TJsonValue.TJsonDictionary.Clear;
var
  I: Integer;
begin
  for I := 0 to FCount - 1 do
    FElements[I].Free;
  FreeMem(FElements);
  FElements := nil;

  if (FIndices <> nil) then
  begin
    FIndices.Free;
    FIndices := nil;
  end;

  FCount := 0;
  FCapacity := 0;
end;

function TJsonValue.TJsonDictionary.Contains(const AName: JsonString): Boolean;
begin
  Result := (IndexOfName(AName) <> -1);
end;

procedure TJsonValue.TJsonDictionary.Delete(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);

  FElements[AIndex].Free;

  Dec(FCount);
  if (AIndex <> FCount) then
    Move(FElements[AIndex + 1], FElements[AIndex], (FCount - AIndex) * SizeOf(TElement));

  FillChar(FElements[FCount], SizeOf(TElement), 0);

  RebuildIndices;
end;

function TJsonValue.TJsonDictionary.Equals(
  const AOther: TJsonDictionary): Boolean;
var
  I: Integer;
begin
  if (@AOther = @Self) then
    Exit(True);

  if (AOther.FCount <> FCount) then
    Exit(False);

  for I := 0 to FCount - 1 do
  begin
    if (AOther.FElements[I] <> FElements[I]) then
      Exit(False);
  end;

  Result := True;
end;

procedure TJsonValue.TJsonDictionary.Free;
begin
  Clear;
  FreeMem(@Self);
end;

function TJsonValue.TJsonDictionary.GetElement(
  const AIndex: Integer): PJsonElement;
begin
  if (AIndex >= 0) and (AIndex < FCount) then
    Exit(@FElements[AIndex]);

  Result := @_JSON_NULL_ELEMENT;
end;

function TJsonValue.TJsonDictionary.GetValue(const AName: JsonString): TJsonValue;
var
  Index: Integer;
begin
  Index := IndexOfName(AName);
  if (Index >= 0) and (Index < FCount) then
    Exit(TJsonValue(FElements[Index].FValue));

  Result.FBits := 0;
end;

function TJsonValue.TJsonDictionary.IndexOfName(const AName: JsonString): Integer;
var
  I: Integer;
begin
  if (FIndices = nil) then
  begin
    for I := 0 to FCount - 1 do
    begin
      if (FElements[I].FName = AName) then
        Exit(I);
    end;
    Result := -1;
  end
  else
    Result := FIndices.Get(AName);
end;

procedure TJsonValue.TJsonDictionary.Init;
begin
  FSubtype := SUBTYPE_DICT;
  FElements := nil;
  FIndices := nil;
  FCount := 0;
  FCapacity := 0;
end;

procedure TJsonValue.TJsonDictionary.ReadFrom(const AReader: IJsonReader);
var
  State: TJsonReaderState;
  Element: PElement;
begin
  AReader.ReadStartDictionary;
  while AReader.Next(State) and (State <> TJsonReaderState.EndDictionary) do
  begin
    Element := AddOrReplaceElement(AReader.ReadName);

    AReader.Next(State);

    TJsonValue(Element.FValue) := TJsonValue.ReadFrom(AReader, State);
  end;
  AReader.ReadEndDictionary;
end;

procedure TJsonValue.TJsonDictionary.RebuildIndices;
var
  I: Integer;
begin
  if (FCount < INDICES_COUNT_THRESHOLD) then
  begin
    if (FIndices <> nil) then
    begin
      FIndices.Free;
      FIndices := nil;
    end;
    Exit;
  end;

  if (FIndices = nil) then
  begin
    GetMem(FIndices, SizeOf(TIndexMap));
    FillChar(FIndices^, SizeOf(TIndexMap), 0);
  end
  else
    FIndices.Clear;

  for I := 0 to FCount - 1 do
    FIndices.Add(FElements[I].FName, I);
end;

procedure TJsonValue.TJsonDictionary.Remove(const AName: JsonString);
var
  Index: Integer;
begin
  Index := IndexOfName(AName);
  if (Index >= 0) then
    Delete(Index);
end;

function TJsonValue.TJsonDictionary.TryGetValue(const AName: JsonString;
  out AValue: TJsonValue): Boolean;
var
  Index: Integer;
begin
  Index := IndexOfName(AName);
  Result := (Index >= 0);
  if (Result) then
    AValue := TJsonValue(FElements[Index].FValue)
  else
    AValue.FBits := 0;
end;

procedure TJsonValue.TJsonDictionary.WriteTo(const AWriter: IJsonWriter);
var
  Elem: PElement;
  I: Integer;
begin
  AWriter.WriteStartDictionary;
  Elem := FElements;
  for I := 0 to FCount - 1 do
  begin
    AWriter.WriteName(Elem.FName);
    TJsonValue(Elem.FValue).WriteTo(AWriter);
    Inc(Elem);
  end;
  AWriter.WriteEndDictionary;
end;

{ TJsonDocument }

constructor TJsonDocument.Create;
begin
  raise EInvalidOperation.Create('To create a new JSON document, use CreateArray or CreateDictionary.' + sLineBreak
    + 'To load a JSON document, use Parse or Load.');
end;

constructor TJsonDocument.Create(const ARoot: TJsonValue);
begin
  inherited Create;
  FRoot := ARoot;
end;

class function TJsonDocument.CreateArray: IJsonDocument;
begin
  Result := TJsonDocument.Create(TJsonValue.CreateArray);
end;

class function TJsonDocument.CreateDictionary: IJsonDocument;
begin
  Result := TJsonDocument.Create(TJsonValue.CreateDictionary);
end;

destructor TJsonDocument.Destroy;
begin
  FRoot.Free;
  inherited;
end;

function TJsonDocument.GetRoot: TJsonValue;
begin
  Result := FRoot;
end;

class function TJsonDocument.Load(const AReader: IJsonReader): IJsonDocument;
var
  State: TJsonReaderState;
begin
  if (AReader = nil) then
    Exit(nil);

  if (not AReader.Next(State)) then
    Exit(TJsonDocument.Create(TJsonValue.Create));

  if (not (State in [TJsonReaderState.StartArray, TJsonReaderState.StartDictionary])) then
    raise EJsonParserError.Create(RS_JSON_INVALID_ROOT, 1, 1, 0);

  Result := TJsonDocument.Create(TJsonValue.ReadFrom(AReader, State));
end;

class function TJsonDocument.Load(const AFilename: String): IJsonDocument;
var
  Reader: IJsonReader;
begin
  Reader := TJsonReader.Load(AFilename);
  Result := Load(Reader);
end;

class function TJsonDocument.Load(const AStream: TStream): IJsonDocument;
var
  Reader: IJsonReader;
begin
  Reader := TJsonReader.Load(AStream);
  Result := Load(Reader);
end;

class function TJsonDocument.Parse(const AJson: JsonString): IJsonDocument;
var
  Reader: IJsonReader;
begin
  Reader := TJsonReader.Create(AJson);
  Result := Load(Reader);
end;

procedure TJsonDocument.Save(const AFilename: String; const AIndent: Boolean);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFilename, fmCreate);
  try
    Save(Stream, AIndent);
  finally
    Stream.Free;
  end;
end;

procedure TJsonDocument.Save(const AStream: TStream; const AIndent: Boolean);
{$IFDEF JSON_UTF8}
var
  Json: JsonString;
begin
  if (AStream = nil) then
    Exit;

  Json := FRoot.ToJson(AIndent);
  if (Json <> '') then
    AStream.WriteBuffer(Json[Low(UTF8String)], Length(Json));
{$ELSE}
var
  Json: JsonString;
  Bytes: TBytes;
begin
  if (AStream = nil) then
    Exit;

  Json := FRoot.ToJson(AIndent);
  if (Json <> '') then
  begin
    SetLength(Bytes, (Json.Length + 1) * 3);
    SetLength(Bytes, Utf16ToUtf8(Json, Json.Length, @Bytes[0]));
    AStream.WriteBuffer(Bytes[0], Length(Bytes));
  end;
{$ENDIF}
end;

function TJsonDocument.ToJson(const AIndent: Boolean): JsonString;
begin
  Result := FRoot.ToJson(AIndent);
end;

end.
