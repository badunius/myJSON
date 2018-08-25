unit uJSON;

interface

uses
  SysUtils;

type
  myJDType = (dtValue, dtObject, dtArray, dtUnset);

  myJSONItem = class
  private
    // имя элемента
    fKey: string;
    // тип хранимых данных (значение/объект/массив)
    fType: myJDType;
    // значение (для типа dtValue)
    fValue: string;
    // дочерние элементы (для объекта/массива)
    fChild: array of myJSONItem;

    // методы
    function getItem(key: string): myJSONItem;
    function getCode: string;
    function getKey(index: integer): string;
    function getElem(index: integer): myJSONItem;  
    function hasKey(key: string): boolean;

    // парсинг идёт черрез свойство Code? так что можно будет код одного объекта присвоить дрругому и заебок
    procedure setCode(aCode: string);

    // утилиты
    procedure clear_child;
  public
    // для получения имени самого элемента (нужно)
    property Name: string read fKey;
    // для получения дочернего элемента по имени (ключу)
    property Item[key: string]: myJSONItem read getItem; default;
    // для получения кода текущего элемента
    property Code: string read getCode write setCode;
    // для получения ключей дочерних элементов
    property Key[index: integer]: string read getKey;
    // для получения дочернего элемента по индексу (для массивов, например, но сработает и для объектов)
    property Value[index: integer]: myJSONItem read getElem;
    // проверяет наличие ключа более элегантным, чем сверка со значением по умолчанию, способом
    property Has[key: string]: boolean read hasKey;

    constructor Create;
    destructor Destroy; override;

    //
    function Count: integer;
    procedure Remove(n: integer);
    procedure LoadFromFile(filename: string);
    procedure SaveToFile(filename: string);

    // методы конечных узлов (листьев)
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
  // удаляет всех потомков (рекурсивно)
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
  // здесь бы задать значения по умолчанию, но я пока не уверрен:
  // коррневому элементу они не сильно-то и нужны, а дочеррним будут заданы
  // при обращении
end;

destructor myJSONItem.Destroy;
begin
  // чтобы не оставлять "висяков" в памяти
  clear_child;

  inherited;
end;

function myJSONItem.getBool(default: boolean): boolean;
var
  f: double;
begin
  // значение по умолчанию
  result := default;

  if self = nil
    then Exit;

  // проверяем на соответствие типу
  if fType <> dtValue
    then Exit;

  // проверяем литеральные значения
  if fValue = ''
    then Exit; // не значения - будет по умолчанию

  if fValue = 'true' then begin
    result := true;
    Exit;
  end;

  if fValue = 'false' then begin
    result := false;
    Exit;
  end;

  // прроверяем числовые значения
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
      // перечисляем всё, что у нас внутри
      for i := 0 to high(fChild) do begin
        result := result + fChild[i].Code;
        if i < high(fChild)
          then result := result + ',';
      end;
      result := result + '}';
    end;  
    dtArray: begin
      result := '[';
      // перечисляем всё, что у нас внутри
      for i := 0 to high(fChild) do begin
        result := result + fChild[i].Code;
        if i < high(fChild)
          then result := result + ',';
      end;
      result := result + ']';
    end;
    dtValue: begin
      // по идее числа не должны быть в кавычках, но мне похуй, ведь я храню всё в строках
      // но эт точка роста: можно хрранить в нативном виде и запоминать, в каком виде они устанавливались
      // что нихуя не сработает при парсинге =/
      result := '"' + fValue + '"';
    end;
  end;

  // если мы не корневой элемент и не элемент массива, то у нас есть ключ
  // пишем его перед значением
  if fKey <> ''
    then result := '"' + fKey + '":' + result;
end;

function myJSONItem.getElem(index: integer): myJSONItem;
var
  i: integer;
begin
  // в отличие от getItem мы не меняем тип переменной
  result := nil;
  // проверка на соответствие типу
  if (fType <> dtObject) and (fType <> dtArray)
    then Exit;
  // range check
  if index < 0
    then Exit;

  // здесь небольшая вилка
  if fType = dtObject then begin
    // объект не может вернуть элемент с индексом выше максимального
    if index <= high(fChild)
      then result := fChild[index];
    Exit;
  end;

  // а массив вполне себе может, при этом он заполнит все недостающие элементы пустыми значениями
  if fType = dtArray then begin
    // проверяем длину
    if high(fChild) < index
      then SetLength(fChild, index + 1);
    // добавляем элементы, начиная с конца (в начале они могут уже быть, а если нет, то не похуй ли)
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
  // возвращает значение как целое число
  result := default;   

  if self = nil
    then Exit;

  // проверяем на соотвествие типу
  if fType <> dtValue
    then Exit;

  // проверяем, а не boolean ли у нас в значении
  if fValue = 'true' then begin
    result := 1;
    Exit;
  end;
  if fValue = 'false' then begin
    result := 0;
    Exit;
  end;

  // преобразуем как дробное (функция и целое схавает)
  f := StrToFloatDef(fValue, default);
  
  // и выделяем целую часть
  result := Trunc(f);
end;

function myJSONItem.getItem(key: string): myJSONItem;
var
  i, n: integer;
begin
  result := nil;
  if self = nil
    then Exit;
  // возвращает дочерний элемент
  // если элемент отсутствует - создаёт его

  // при этом тип элемента меняется на dtObject
  if fType <> dtObject
    then setType(dtObject);

  // ищем элемент
  key := LowerCase(key);
  n := -1;
  for i := 0 to high(fChild) do
    if LowerCase(fChild[i].fKey) = key then begin
      n := i;
      Break;
    end;

  // если не нашёлся - создаём
  if n < 0 then begin
    SetLength(fChild, Length(fChild) + 1);
    n := high(fChild);
    fChild[n] := myJSONItem.Create;
    fChild[n].fKey := key;
  end;

  // возврращаем результат
  result := fChild[n];
end;

function myJSONItem.getKey(index: integer): string;
var
  n: myJSONItem;
begin
  // возврращаем ключ N-го потомка
  // работает по прринципу getElem и с его помощью
  result := '';
  n := getElem(index);
  if n <> nil
    then result := n.fKey;
end;

function myJSONItem.getNum(default: double): double;
begin
  // возвращает значение как дробное число
  result := default;  

  if self = nil
    then Exit;

  // проверяем на соотвествие типу
  if fType <> dtValue
    then Exit;

  // проверяем, а не boolean ли у нас в значении
  if fValue = 'true' then begin
    result := 1;
    Exit;
  end;
  if fValue = 'false' then begin
    result := 0;
    Exit;
  end;
  
  // преобразуем значение
  result := StrToFloatDef(fValue, default);
end;

function myJSONItem.getStr(default: string): string;
begin
  // тут нам насррать что как - всё равно всё хранится в строке
  result := default;   

  if self = nil
    then Exit;

  // проверяем только на соотвествие типу
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
  // удаляет N-ого потомка
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
  // значения могут иметь только dtValue, массивы и объекты будут редуцированы
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
    // мы прочитали значение и, возможно, ключ (в массивах их нет)
    strKey := Trim(strKey);
    strVal := trim(strVal);
    // проверяем, является ли значение кодом, который можно распарсить
    if Length(strVal) > 0 then begin
      if (strVal[1] = '{') or (strVal[1] = '[')
        then isCode := true
        else isCode := false;
    end else begin
      isCode := false;
    end;
    // теперь нужно обрработать эту ситуацию в соответствии со своим типом
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

  // сперва определяем свой тип
  case aCode[1] of
    '{': begin
      // мы - объект
      setType(dtObject);
      isKey := true;
      isQuote := false;
      brOpen := '{';   // мы начались с этой скобки
      brClose := '}';  // и закончимся этой
      brSkip := 0;     // сколько раз нам попадалась открывающая скобка
      brStack := '}';
    end;
    '[': begin
      // мы - массив
      setType(dtArray);
      isKey := false; // нет в массиве ключей, только значения
      isQuote := false;
      brOpen := '[';
      brClose := ']';
      brSkip := 0;
      brStack := ']';
    end;
    else begin
      // мы пара ключ-значение
      setType(dtValue);
      isKey := true;
      isQuote := (aCode[1] = '"');
      brSkip := 0;
      brStack := '';
    end;
  end;

  // не экранировано
  bSlashed := false;

  // читаем остаток строки
  for n := 2 to Length(aCode) do begin
    // проверяем очередной символ

    // на случай экранирования
    if bSlashed
      then aChar := aCode[n]
      else aChar := '';
    bSlashed := false;

    if aChar = '' then
    case aCode[n] of
      // управляющие символы
      '"': begin
        {if aCode[n - 1] <> '\'
          then }isQuote := not isQuote{
          else aChar := '"'};
      end;

      '\': begin
        bSlashed := true;
      end;

      ':': begin
        // если скип больше нуля, значит мы наткнулись на открывающую скобку и шлём у хуям все управляющие символы
        if Length(brStack) > 1 then begin
          aChar := ':';
        end else begin
          // если не в кавычках, значит, дочитали ключ
          if not isQuote
            then isKey := false
            else aChar := ':';
        end;
      end;

      ',': begin
        // если скип больше нуля, значит мы наткнулись на открывающую скобку и шлём у хуям все управляющие символы
        if Length(brStack) > 1 then begin
          aChar := ',';
        end else begin
          // если не в кавычках, значит, дочитали ключ
          if not isQuote
            then put_value
            else aChar := ',';
        end;
      end;

      // открывающие скобки
      '{': begin
        // ещё одна открывающая, увеличиваем количество пропусков на один
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

      // закрывающие скобки
      '}': begin
        // если это наша закрывающая, то завершаем цикл
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
        // если это наша закрывающая, то завершаем цикл
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

    // записываем символ к тому, что сейчас читаем
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

  // значения могут иметь только dtValue, массивы и объекты будут редуцированы
  setType(dtValue);
  fValue := IntToStr(value);
end;

procedure myJSONItem.setNum(value: double);
begin             
  if self = nil
    then Exit;

  // значения могут иметь только dtValue, массивы и объекты будут редуцированы
  setType(dtValue);
  fValue := FloatToStr(value);
end;

procedure myJSONItem.setStr(value: string);
begin      
  if self = nil
    then Exit;

  // значения могут иметь только dtValue, массивы и объекты будут редуцированы
  setType(dtValue);
  fValue := value;
end;

procedure myJSONItem.setType(aType: myJDType);
var
  i: integer;
begin    
  if self = nil
    then Exit;
    
  // если массив или объект преобразуются в число, то нужно изничтожить всех потомков
  if (aType = dtValue) and (fType <> dtValue) then begin
    clear_child;
  end;

  // если число преобразуется в объект или массив, то нужно отнять у него значение
  if (aType <> dtValue) and (fType = dtValue) then begin
    fValue := '';
  end;

  // если массив преобразуется в объект, то нужно всем его элементам назначить ключи
  if (aType = dtObject) and (fType = dtArray) then begin
    for i := 0 to high(fChild) do
      fChild[i].fKey := IntToStr(i);
  end;

  // если объект преобрразуется в массив, то нужно поубиррать ключи у его потомков
  if (aType = dtArray) and (fType = dtObject) then begin
    for i := 0 to high(fChild) do
      fChild[i].fKey := '';
  end;

  fType := aType;
end;

end.
