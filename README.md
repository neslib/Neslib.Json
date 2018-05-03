# Neslib.Json - Fast and memory-efficient JSON for Delphi

A fast and memory-efficient JSON object model, with support for efficiently parsing and writing in JSON-compliant format.

## Dependencies

This library only depends on the Neslib repository. It is included as submodule with this repository.

## Loading and Saving JSON

The main entry point to this library is the `IJsonDocument` interface. It is used for parsing, loading and saving JSON documents and provides access to the JSON object model. You can parse a JSON string as follows:

```Delphi
var
  Doc: IJsonDocument;
begin
  Doc := TJsonDocument.Parse('{ "Answer" : 42 }');
end;
```

Note that, unlike the official JSON specification, this library does *not* require quotes around dictionary keys (as long as the key does not contain spaces or other non-identifier characters). So the following is valid as well:

```Delphi
Doc := TJsonDocument.Parse('{ Answer : 42 }');
```

You can also use the `Load` method to load from a file or stream.

On the output side, you use `Save` to save to a file or stream, or `ToJson` to output to a JSON string.

You can also create new JSON documents from scratch using the `CreateArray` or `CreateDictionary` methods:

```Delphi
var
  Doc: IJsonDocument;
begin
  Doc := TJsonDocument.CreateArray;
  Doc.Root.Add(42);
end;
```

As you can see in this example, you access the JSON document object model through the Root property.

## JSON object model

At the heart of the JSON object model is the `TJsonValue` type. This is a record that can hold any type of JSON value.

It provides various implicit conversion operators to convert a `TJsonValue` to another (Delphi) type. In addition, there are various `To*` methods that try to convert a `TJsonValue` but return a provided default value if conversion fails.

You (can) never create `TJsonValue`'s yourself; The only way to create a `TJsonValue` is by adding a value to JSON array or dictionary:

```Delphi
var
  Doc: IJsonDocument;
begin
  Doc := TJsonDocument.CreateArray;
  Doc.Root.Add(42);
end;
```

This example adds a `TJsonValue` (with value 42) to a JSON array. To create a new array of dictionary, you use the `AddArray` or `AddDictionary` methods instead:

```Delphi
var
  Doc: IJsonDocument;
  Dict: TJsonValue;
begin
  Doc := TJsonDocument.CreateArray;
  Dict := Doc.Root.AddDictionary;
  Dict.AddOrSetValue('answer', 42);
end;
```

This creates a new dictionary and adds it to the root array. Then, the value 42 is added to this dictionary under the name 'answer'.

To check the type of a value, use the `TJsonValue.ValueType` property or one of the `TJsonValue.Is*` methods.

When trying to use methods like `Add` (or `AddOrSetValue`) on values that are not arrays (or dictionaries), an exception will be raised.

However, accessing the items in an array (using the `Items` property) or the values in a dictionary (using the `Values` property) will never result in an exception, even if the array index is out of bounds. This allows for chaining multiple array/dictionary accesses together without having to check the validity of each intermediate step. For example:

```Delphi
I := Doc.Root.Items[3].Values['foo'].Values['bar'].Items[4].ToInteger(0);
```

This will always succeed, but return 0 if any of the intermediate values are unavailable.

## Manually Reading and Writing JSON

The `IJsonDocument` interface makes it easy to read and write JSON into a document object model.

However, you can also choose to read or write JSON manually if you prefer (for example to avoid having to load an object model into memory). You can do this with the `IJsonReader` and `IJsonWriter` interfaces in the `Neslib.Json.IO` unit.

These interfaces are completely independent from any DOM implementation and don't even require the `Neslib.Json` unit. Using these interfaces is a bit more complicated and requires some more work though. See the `Neslib.Json.IO` unit for more information.

## Querying JSON documents with JSONPath

There is also an XPath-like JSONPath implementation you can use for querying JSON documents. 

There is no official JSONPath specification, but the most widely used version seems to be one developed by [Stefan Goessner](http://goessner.net/articles/JsonPath/).

### About JSONPath

A JSONPath looks like:

```json
$.store.book[0].title
```

or

```json
$['store']['book'][0]['title']
```

Both representation are identical: you can use either dot (`.`) or bracket (`[]`) notation to denote children of a dictionary. Brackets can also be used with numerical indices to denote children of an array by index.

> JSONPath only uses single quotes (') within brackets. We also allow for double quotes (") since these are easier to use in Delphi strings.
>

In short:

* Every path starts with a `$` indicating the root, followed by zero or more child operators (`.` or `[]`). A `$` by itself matches the entire document.
* A child name can be an identifier string or the asterisk (`*` or `'*'`) wildcard to match all children. For example, `$.store.book[*].author` matches the authors of all books in the store.
* In addition to a single dot (`.`), a double dot (`..`) can be used to search for any descendants instead of immediate children. For example, `$..author` matches all authors, regardless of depth. This is called recursive descent.
* Children can also be accessed by one or more indices between brackets. These indices are 0-based and are only used with arrays. You can separate multiple indices with comma's. For example, `$.store.book[0,2,3]` matches the first, third and fourth books.
* You can use the slice notation `[Start:End:Step]` to match a slice (range) of children. This matches all children from index `Start` up to (but not including) `End`, using a given `Step` size (usually 1). All are optional, but at least one value (and colon) must be given:
  * If `Start` is omitted, it is implied to be 0. A negative value indicates an offset from the end of the array.
  * If `End` is omitted, the slice extracts through the end of the array. A negative value indicates and offset from the end of the array.
  * If `Step` is omitted, is is implied to be 1.
  * Examples:
    * `List[2:]` matches the third and all following elements.
    * `List[-2:]` matches the last two elements.
    * `List[:2]` matches the first two elements.
    * `List[:-2]` matches all but the last two elements.
    * `List[2:-2]` matches all elements but the first two and last two.
    * `List[-4:-2]` matches the 3rd and 4rd elements from the end.
    * `List[::2]` matches all elements with an even index.

> JSONPath also has an @ operator to allow custom script expressions. We do not support this operator.
>

### JSONPath Examples

Example document:

```json
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
```

Example paths:

| Expression               | Result                                               |
| ------------------------ | ---------------------------------------------------- |
| `$`                      | Matches the root document (a single value)           |
| `$..*`                   | Matches all members in the document (lots of values) |
| `$.store.book[*].author` | The authors of all books in the store                |
| `$..author`              | All authors                                          |
| `$.store.*`              | All things in store (2 books and a bicycle)          |
| `$.store..price`         | The price of everything in the store                 |
| `$..book[2]`             | The third book                                       |
| `$..book[-1:]`           | The last book in order                               |
| `$..book[:2]`            | The first two books                                  |

### JSONPath in Delphi 

The JSONPath API is short and simple. It consists of a `TJsonPath` record with only a couple of methods.

For one-off matching, use the static `Match` method:

```Delphi
var
  Doc: IJsonDocument;
  Matches: TArray<TJsonValue>;
begin
  Doc := TJsonDocument.Load(...);
  Matches := TJsonPath.Match(Doc, '$.store.book[*].author');
end;
```

If you plan to use the same path on multiple (sub)documents, then it is faster to parse the path once, and then apply it multiple times:

```Delphi
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
```

You can also run the path on sub-trees:

```Delphi
var
  Doc: IJsonDocument;
  Store: TJsonValue;
  Matches: TArray<TJsonValue>;
begin
  Doc := TJsonDocument.Load(...);
  Store := Doc.Root.Values['store'];
  Matches := TJsonPath.Match(Store, '$.book[*].author');
end;
```

If you are only interested in a single (or the first) match, then you can use `MatchSingle` instead:

```Delphi
var
  Doc: IJsonDocument;
  Match: TJsonValue;
begin
  Doc := TJsonDocument.Load(...);
  if (TJsonPath.MatchSingle(Store, '$.book[*]', Match)) then
    ...
end;
```

## Memory Management

All memory management in this JSON library is automatic. An `IJsonDocument` interface owns all `TJsonValue`'s and destroys them when the document is destroyed (goes out of scope).

The only thing you need to be aware of is that you shouldn't use any TJsonValue records anymore after the document is destroyed. Doing so will lead to undefined behavior and possibly crashes.

## Customization

You can customize some behavior using these conditional defines:
* `JSON_UTF8`: to use `UTF8String` instead of `String` everywhere. All strings will be treated as 8-bit UTF-8 strings instead of 16-bit Unicode strings. This reduces memory consumption and speeds up parsing a bit. However, this means you will have to use this JSON library with UTF8Strings as well, otherwise
  Delphi will implicitly convert between Unicode strings and UTF8Strings, which can hurt performance.
* `JSON_STRING_INTERNING`: to enable string interning for dictionary keys. This reduces memory consumption in case the same key is used a lot of times (which is common when JSON is exported from a database), but is a bit slower.

The Neslib.Json unit declares the `JsonString` type as either `String` or `UTF8String`, depending on the `JSON_UTF8` define. However, this doesn't mean that *you* have to use `JsonString` as well. If you don't care about the `JSON_UTF8` define, then you can just use regular strings with this library.

## License

Neslib.Json is licensed under the Simplified BSD License. 

See License.txt for details.