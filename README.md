# myJSON
JSON parser for delphi 7 and earlier (and maybe even later)

### types:
- myJDType 
> type of node (Object/Array/Value)
- myJSONItem 
> structure to operate JSON

### properties of myJSONItem:
- Name: string 
> Node name (read only)
- Item[name]: myJSONItem 
> Sub-item with specified name (read only, default property).
> Creates an item if it doesn't exist yet.
- Code: string 
> Encoded JSON of this node and all of it's child nodes.
> Assign encoded JSON to this property to parse it.
- Key[index]: string 
> Names of this node's childs (won't work for arrays)
- Value[index]: myJSONItem
> Values of this node's childs
- Has[name]: boolean
> return true if node has a child with specified name

### methods of myJSONItem:
- Count: integer 
> Returns count of child nodes (works for both arrays and objects)
- Remove(n)
> Removes N-th children
- LoadFromFile / SaveToFile
> Obviously

### getters and setters:
All values are stored as strings, therefore there are number of getters to do all conversion for you. Each of this getters lets you to specify default values. Each setter wil convert values to string format.
- getStr / setStr `// string`
- getInt / setInt `// integer`
- getNum / setNum `// double (float)`
- getBool / setBool `// boolean. True: 'true' or any number > 0. False: 'false' (or any other string, actually) or any number <= 0.`

## Example 1: Reading values
conf.json
```
{
  window:{
    width:400,
    height:300
   },
   fonts:[
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

a.Code := '{item1:"value 1",item2:[3,4,5]}';
a['item3'].setStr('value 3');
Writeln(a.Code); // {"item1":"value 1","item2":["3","4","5"],"item3":"value 3"}
b['desc'].setStr('And now for something completelly different');
b['c'].Code := a.Code;
Writeln(b.Code); // {"desc":"And now for something completelly different","c":{"item1":"value 1","item2":["3","4","5"],"item3":"value 3"}}
```
