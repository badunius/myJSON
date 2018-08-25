unit uJSON;

interface

uses
  SysUtils;

type
  myJDType = (dtValue, dtObject, dtArray, dtUnset);

  myJSONItem = class
  private
    // ��� ��������
    fKey: string;
    // ��� �������� ������ (��������/������/������)
    fType: myJDType;
    // �������� (��� ���� dtValue)
    fValue: string;
    // �������� �������� (��� �������/�������)
    fChild: array of myJSONItem;

    // ������
    function getItem(key: string): myJSONItem;
    function getCode: string;
    function getKey(index: integer): string;
    function getElem(index: integer): myJSONItem;  
    function hasKey(key: string): boolean;

    // ������� ��� ������ �������� Code? ��� ��� ����� ����� ��� ������ ������� ��������� �������� � ������
    procedure setCode(aCode: string);

    // �������
    procedure clear_child;
  public
    // ��� ��������� ����� ������ �������� (�����)
    property Name: string read fKey;
    // ��� ��������� ��������� �������� �� ����� (�����)
    property Item[key: string]: myJSONItem read getItem; default;
    // ��� ��������� ���� �������� ��������
    property Code: string read getCode write setCode;
    // ��� ��������� ������ �������� ���������
    property Key[index: integer]: string read getKey;
    // ��� ��������� ��������� �������� �� ������� (��� ��������, ��������, �� ��������� � ��� ��������)
    property Value[index: integer]: myJSONItem read getElem;
    // ��������� ������� ����� ����� ����������, ��� ������ �� ��������� �� ���������, ��������
    property Has[key: string]: boolean read hasKey;

    constructor Create;
    destructor Destroy; override;

    //
    function Count: integer;
    procedure Remove(n: integer);
    procedure LoadFromFile(filename: string);
    procedure SaveToFile(filename: string);

    // ������ �������� ����� (�������)
    procedure setInt(value: integer);
    procedure setNum(value: double);
    procedure setStr(value: string);
    procedure setBool(value: boolean);
    procedure setType(aType: myJDType);

    function getInt(default: integer = 0): integer;
    function getNum(default: double = 0): double;
    function getStr(default: string = ''): string;
    function getBool(default: boolean = false): boolean;
    function getType(default: myJDType = dtUnset): myJDType;
  end;

implementation

{ myJSONItem }

procedure myJSONItem.clear_child;
var
  i: integer;
begin
  // ������� ���� �������� (����������)
  for i := 0 to high(fChild) do
    fChild[i].Free;
  SetLength(fChild, 0);
end;

function myJSONItem.Count: integer;
begin
  result := Length(fChild);
end;

constructor myJSONItem.Create;
begin
  // ����� �� ������ �������� �� ���������, �� � ���� �� �������:
  // ���������� �������� ��� �� ������-�� � �����, � ��������� ����� ������
  // ��� ���������
end;

destructor myJSONItem.Destroy;
begin
  // ����� �� ��������� "�������" � ������
  clear_child;

  inherited;
end;

function myJSONItem.getBool(default: boolean): boolean;
var
  f: double;
begin
  // �������� �� ���������
  result := default;

  if self = nil
    then Exit;

  // ��������� �� ������������ ����
  if fType <> dtValue
    then Exit;

  // ��������� ����������� ��������
  if fValue = ''
    then Exit; // �� �������� - ����� �� ���������

  if fValue = 'true' then begin
    result := true;
    Exit;
  end;

  if fValue = 'false' then begin
    result := false;
    Exit;
  end;

  // ���������� �������� ��������
  if default
    then f := 1
    else f := 0;
  f := StrToFloatDef(fValue, f);

  if f > 0
    then result := true
    else result := false;
end;

function myJSONItem.getCode: string;
var
  i: integer;
begin
  result := '""';
  if self = nil
    then Exit;
  case self.fType of
    dtObject: begin
      result := '{';
      // ����������� ��, ��� � ��� ������
      for i := 0 to high(fChild) do begin
        result := result + fChild[i].Code;
        if i < high(fChild)
          then result := result + ',';
      end;
      result := result + '}';
    end;  
    dtArray: begin
      result := '[';
      // ����������� ��, ��� � ��� ������
      for i := 0 to high(fChild) do begin
        result := result + fChild[i].Code;
        if i < high(fChild)
          then result := result + ',';
      end;
      result := result + ']';
    end;
    dtValue: begin
      // �� ���� ����� �� ������ ���� � ��������, �� ��� �����, ���� � ����� �� � �������
      // �� �� ����� �����: ����� �������� � �������� ���� � ����������, � ����� ���� ��� ���������������
      // ��� ����� �� ��������� ��� �������� =/
      result := '"' + fValue + '"';
    end;
  end;

  // ���� �� �� �������� ������� � �� ������� �������, �� � ��� ���� ����
  // ����� ��� ����� ���������
  if fKey <> ''
    then result := '"' + fKey + '":' + result;
end;

function myJSONItem.getElem(index: integer): myJSONItem;
var
  i: integer;
begin
  // � ������� �� getItem �� �� ������ ��� ����������
  result := nil;
  // �������� �� ������������ ����
  if (fType <> dtObject) and (fType <> dtArray)
    then Exit;
  // range check
  if index < 0
    then Exit;

  // ����� ��������� �����
  if fType = dtObject then begin
    // ������ �� ����� ������� ������� � �������� ���� �������������
    if index <= high(fChild)
      then result := fChild[index];
    Exit;
  end;

  // � ������ ������ ���� �����, ��� ���� �� �������� ��� ����������� �������� ������� ����������
  if fType = dtArray then begin
    // ��������� �����
    if high(fChild) < index
      then SetLength(fChild, index + 1);
    // ��������� ��������, ������� � ����� (� ������ ��� ����� ��� ����, � ���� ���, �� �� ����� ��)
    for i := high(fChild) downto 0 do
      if fChild[i] = nil
        then fChild[i] := myJSONItem.Create
        else Break;
    result := fChild[index];
  end;
end;

function myJSONItem.getInt(default: integer): integer;
var
  f: double;
begin
  // ���������� �������� ��� ����� �����
  result := default;   

  if self = nil
    then Exit;

  // ��������� �� ����������� ����
  if fType <> dtValue
    then Exit;

  // ���������, � �� boolean �� � ��� � ��������
  if fValue = 'true' then begin
    result := 1;
    Exit;
  end;
  if fValue = 'false' then begin
    result := 0;
    Exit;
  end;

  // ����������� ��� ������� (������� � ����� �������)
  f := StrToFloatDef(fValue, default);
  
  // � �������� ����� �����
  result := Trunc(f);
end;

function myJSONItem.getItem(key: string): myJSONItem;
var
  i, n: integer;
begin
  result := nil;
  if self = nil
    then Exit;
  // ���������� �������� �������
  // ���� ������� ����������� - ������ ���

  // ��� ���� ��� �������� �������� �� dtObject
  if fType <> dtObject
    then setType(dtObject);

  // ���� �������
  key := LowerCase(key);
  n := -1;
  for i := 0 to high(fChild) do
    if LowerCase(fChild[i].fKey) = key then begin
      n := i;
      Break;
    end;

  // ���� �� ������� - ������
  if n < 0 then begin
    SetLength(fChild, Length(fChild) + 1);
    n := high(fChild);
    fChild[n] := myJSONItem.Create;
    fChild[n].fKey := key;
  end;

  // ����������� ���������
  result := fChild[n];
end;

function myJSONItem.getKey(index: integer): string;
var
  n: myJSONItem;
begin
  // ����������� ���� N-�� �������
  // �������� �� ��������� getElem � � ��� �������
  result := '';
  n := getElem(index);
  if n <> nil
    then result := n.fKey;
end;

function myJSONItem.getNum(default: double): double;
begin
  // ���������� �������� ��� ������� �����
  result := default;  

  if self = nil
    then Exit;

  // ��������� �� ����������� ����
  if fType <> dtValue
    then Exit;

  // ���������, � �� boolean �� � ��� � ��������
  if fValue = 'true' then begin
    result := 1;
    Exit;
  end;
  if fValue = 'false' then begin
    result := 0;
    Exit;
  end;
  
  // ����������� ��������
  result := StrToFloatDef(fValue, default);
end;

function myJSONItem.getStr(default: string): string;
begin
  // ��� ��� �������� ��� ��� - �� ����� �� �������� � ������
  result := default;   

  if self = nil
    then Exit;

  // ��������� ������ �� ����������� ����
  if fType <> dtValue
    then Exit;
  result := fValue;
end;

function myJSONItem.getType(default: myJDType): myJDType;
begin
  result := default;

  if self = nil
    then Exit;
    
  result := fType;
end;

function myJSONItem.hasKey(key: string): boolean;
var
  i: integer;
begin
  result := true;
  for i := 0 to high(fChild) do
    if fChild[i].fKey = key
      then Exit;
  result := false;
end;

procedure myJSONItem.LoadFromFile(filename: string);
var
  f: Text;
  s, b: string;
begin
  clear_child;
  AssignFile(f, filename);
  Reset(f);
  while not EOF(f) do begin
    Readln(f, b);
    s := s + b;
  end;
  Code := s;
  CloseFile(f);
end;

procedure myJSONItem.Remove(n: integer);
var
  i: integer;
begin
  // ������� N-��� �������
  if (n < 0) or (n > high(fChild)) or (length(fChild) < 1)
    then Exit;

  fChild[n].Free;
  for i := n to high(fChild) - 1 do
    fChild[i] := fChild[i + 1];

  setLength(fChild, high(fChild));
end;

procedure myJSONItem.SaveToFile(filename: string);
var
  f: Text;
begin
  AssignFile(f, filename);
  Rewrite(f);
  Write(f, Code);
  CloseFile(f);
end;

procedure myJSONItem.setBool(value: boolean);
begin
  // �������� ����� ����� ������ dtValue, ������� � ������� ����� ������������
  setType(dtValue);
  if value
    then fValue := 'true'
    else fValue := 'false';
end;

procedure myJSONItem.setCode(aCode: string);
var
  n: integer;
  isKey: boolean;   // are we reading key (otherwise - value)
  isQuote: boolean; // are we inside quotes and should treat special characters just like regular ones
  strKey,
  strVal: string;
  brOpen,
  brClose: string;
  brSkip: integer;
  brStack: string;
  aChar: string;
  bSlashed: boolean;

  function clean(str: string; sym: char): string;
  var
    i: integer;
  begin
    if Pos(sym ,str) = 0 then begin
      result := str;
      Exit;
    end;
    result := '';
    for i := 1 to Length(str) do
      if str[i] <> sym
        then result := result + str[i];
  end;

  procedure put_value;
  var
    isCode: boolean;
  begin
    // �� ��������� �������� �, ��������, ���� (� �������� �� ���)
    strKey := Trim(strKey);
    strVal := trim(strVal);
    // ���������, �������� �� �������� �����, ������� ����� ����������
    if Length(strVal) > 0 then begin
      if (strVal[1] = '{') or (strVal[1] = '[')
        then isCode := true
        else isCode := false;
    end else begin
      isCode := false;
    end;
    // ������ ����� ����������� ��� �������� � ������������ �� ����� �����
    case fType of
      dtObject: begin
        if isCode
          then self[strKey].Code := strVal
          else self[strKey].setStr(strVal);
        isKey := true;
      end;
      dtArray: begin
        if isCode
          then self.Value[self.Count].Code := strVal
          else self.Value[self.Count].setStr(strVal);
        isKey := false;
      end;
      dtValue: begin
        fKey := strKey;
        if isCode
          then Code := strVal
          else fValue := strVal;
        isKey := true;
      end;
    end;
    strKey := '';
    strVal := '';
  end;

begin
  aCode := Trim(aCode);
  // additional cleaning
  aCode := clean(aCode, #9);    // TAB
  aCode := clean(aCode, #10);   // LF
  aCode := clean(aCode, #13);   // CR

  // ������ ���������� ���� ���
  case aCode[1] of
    '{': begin
      // �� - ������
      setType(dtObject);
      isKey := true;
      isQuote := false;
      brOpen := '{';   // �� �������� � ���� ������
      brClose := '}';  // � ���������� ����
      brSkip := 0;     // ������� ��� ��� ���������� ����������� ������
      brStack := '}';
    end;
    '[': begin
      // �� - ������
      setType(dtArray);
      isKey := false; // ��� � ������� ������, ������ ��������
      isQuote := false;
      brOpen := '[';
      brClose := ']';
      brSkip := 0;
      brStack := ']';
    end;
    else begin
      // �� ���� ����-��������
      setType(dtValue);
      isKey := true;
      isQuote := (aCode[1] = '"');
      brSkip := 0;
      brStack := '';
    end;
  end;

  // �� ������������
  bSlashed := false;

  // ������ ������� ������
  for n := 2 to Length(aCode) do begin
    // ��������� ��������� ������

    // �� ������ �������������
    if bSlashed
      then aChar := aCode[n]
      else aChar := '';
    bSlashed := false;

    if aChar = '' then
    case aCode[n] of
      // ����������� �������
      '"': begin
        {if aCode[n - 1] <> '\'
          then }isQuote := not isQuote{
          else aChar := '"'};
      end;

      '\': begin
        bSlashed := true;
      end;

      ':': begin
        // ���� ���� ������ ����, ������ �� ���������� �� ����������� ������ � ��� � ���� ��� ����������� �������
        if Length(brStack) > 1 then begin
          aChar := ':';
        end else begin
          // ���� �� � ��������, ������, �������� ����
          if not isQuote
            then isKey := false
            else aChar := ':';
        end;
      end;

      ',': begin
        // ���� ���� ������ ����, ������ �� ���������� �� ����������� ������ � ��� � ���� ��� ����������� �������
        if Length(brStack) > 1 then begin
          aChar := ',';
        end else begin
          // ���� �� � ��������, ������, �������� ����
          if not isQuote
            then put_value
            else aChar := ',';
        end;
      end;

      // ����������� ������
      '{': begin
        // ��� ���� �����������, ����������� ���������� ��������� �� ����
        if not isQuote then begin
            brStack := '}' + brStack;
            aChar := '{';
        end else begin
          aChar := '{';
        end;
      end;
      '[': begin
        if not isQuote then begin
            brStack := ']' + brStack;
            aChar := '[';
        end else begin
          aChar := '[';
        end;
      end;

      // ����������� ������
      '}': begin
        // ���� ��� ���� �����������, �� ��������� ����
        if not isQuote then begin
            if Copy(brStack, 1, 1) = '}'
              then Delete(brStack, 1, 1);
            aChar := '}';
          if Length(brStack) < 1
            then Break;
        end else begin
          aChar := '}';
        end;
      end;    
      ']': begin
        // ���� ��� ���� �����������, �� ��������� ����
        if not isQuote then begin
            if Copy(brStack, 1, 1) = ']'
              then Delete(brStack, 1, 1);
            aChar := ']';
          if Length(brStack) < 1
            then Break;
        end else begin
          aChar := ']';
        end;
      end;

      else aChar := aCode[n]
    end;

    // ���������� ������ � ����, ��� ������ ������
    if isKey
      then strKey := strKey + aChar
      else strVal := strVal + aChar;
  end;
  put_value;
end;

procedure myJSONItem.setInt(value: integer);
begin
  if self = nil
    then Exit;

  // �������� ����� ����� ������ dtValue, ������� � ������� ����� ������������
  setType(dtValue);
  fValue := IntToStr(value);
end;

procedure myJSONItem.setNum(value: double);
begin             
  if self = nil
    then Exit;

  // �������� ����� ����� ������ dtValue, ������� � ������� ����� ������������
  setType(dtValue);
  fValue := FloatToStr(value);
end;

procedure myJSONItem.setStr(value: string);
begin      
  if self = nil
    then Exit;

  // �������� ����� ����� ������ dtValue, ������� � ������� ����� ������������
  setType(dtValue);
  fValue := value;
end;

procedure myJSONItem.setType(aType: myJDType);
var
  i: integer;
begin    
  if self = nil
    then Exit;
    
  // ���� ������ ��� ������ ������������� � �����, �� ����� ����������� ���� ��������
  if (aType = dtValue) and (fType <> dtValue) then begin
    clear_child;
  end;

  // ���� ����� ������������� � ������ ��� ������, �� ����� ������ � ���� ��������
  if (aType <> dtValue) and (fType = dtValue) then begin
    fValue := '';
  end;

  // ���� ������ ������������� � ������, �� ����� ���� ��� ��������� ��������� �����
  if (aType = dtObject) and (fType = dtArray) then begin
    for i := 0 to high(fChild) do
      fChild[i].fKey := IntToStr(i);
  end;

  // ���� ������ �������������� � ������, �� ����� ���������� ����� � ��� ��������
  if (aType = dtArray) and (fType = dtObject) then begin
    for i := 0 to high(fChild) do
      fChild[i].fKey := '';
  end;

  fType := aType;
end;

end.
