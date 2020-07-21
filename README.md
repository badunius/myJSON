# myJSON
JSON parser for delphi 7 and earlier (and maybe even later)

## Types:
- `myJSONItem` -
JSON node
- `myJDType` -
type of node (Object/Array/Value)
- `myJVType` -
value's subtype (Text/Number/Boolean)

## myJSONItem
### properties
- `Name: string` - 
  Node name (read only)
- `Item[name]: myJSONItem` - 
  Sub-item with specified name (read only, default property).
  Creates an item if it doesn't exist yet.
- `Code: string` -
Encoded JSON of this node and all of it's child nodes.
Assign encoded JSON to this property to parse it.
- `Key[index]: string` -
Names of this node's children (won't work for arrays)
- `Value[index]: myJSONItem` -
Values of this node's child
- `Has[name]: boolean` - 
returns `true` if node has a child with specified name

### methods
- `Count: integer` -
Returns count of child nodes (works for both arrays and objects)
- `Remove(n)` -
Removes N-th child
- `LoadFromFile / SaveToFile` - 
Obviously
- `Clear` -
Removes all child nodes, won't work on leaf nodes
- `setArray(newLength: integer)` - 
Explicitly sets type to dtArray and allocates the memory

### getters and setters:

All values are stored as strings, therefore there are number of getters to do all conversion for you. Each of this getters lets you to specify default values. Each setter will convert values to string.

- getStr / setStr `// string`
- getInt / setInt `// integer`
- getNum / setNum `// double (float)`
- getBool / setBool `// boolean. True: 'true' or any number > 0. False: 'false' (or any other string, actually) or any number <= 0.`

There are also methods for working with null-values

- `isNull: boolean` - returns `true` if value is explicitly set to `null`
- `setNull` - explicitly sets value to `null`

As it turned out assigning `Code` to `Code` works well for root elements, or when you assign root element's code to some child element.
However, when you try to clone children this way, `Code` getter will return it with the leading `"key":`, and when the receiver will parse it, it'll see `"key"` and treat it as if it was a text value. Therefore I added (there were other options though) a method for reading value as an encoded JSON string

- `getJSON: string` - returns value as an encoded JSON string (without adding key to it even if there is one)

## Example 1: Reading values
conf.json
```json
{
  "window": {
    "width": 400,
    "height": 300
   },
   "fonts": [
     "Arial",
     "Tahoma"
   ]
}
```

test1.pas
```pascal
...
config := myJSONItem.Create;
list := TStringList.Create;
...
config.LoadFromFile('conf.json');
wnd.Width := config['window']['width'].getInt(DEFAULT_WIDTH);
for i := 0 to config['fonts'].Count - 1 do
  list.Add(config['fonts'].Value[i].getStr);
...
config.Free;
```

## Example 2: Assigning values
```pascal
...
a := myJSONItem.Create;
b := myJSONItem.Create;

a.Code := '{"item1":"value 1","item2":[3,4,5]}';
a['item3'].setStr('value 3');
Writeln(a.Code); // {"item1":"value 1","item2":[3,4,5],"item3":"value 3"}
b['desc'].setStr('And now for something completelly different');
b['c'].Code := a.Code;
Writeln(b.Code); // {"desc":"And now for something completelly different","c":{"item1":"value 1","item2":[3,4,5],"item3":"value 3"}}
```
