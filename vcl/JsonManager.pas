unit JsonManager;

interface
uses
  SysUtils,
  Classes,
  Variants,
  SerializableObjects,
  TypInfo,
  uJson,
  SyncObjs,
  {$IFDEF VER150}
  Forms,
  {$ELSE}
  VCL.Forms,
  {$ENDIF}
  DateHelper,
  Contnrs;

type
  TTreeJsonNodes = class;

  TNode = class
  public
    key:String;
    value:Variant;
    constructor create(key: String; value: variant);
    destructor destroy;override;
  end;

  TNodes= class
  public
    itens: TStringList;
    constructor create;
    destructor destroy; override;
    function count: integer;
    procedure add(item: TNode);
    function get(index: integer): TNode;
    procedure clear;
  end;

  TTreeJsonNode = class(TNode)
  public
    childs: TTreeJsonNodes;
    class function getNodes(json: String): TTreeJsonNodes;
    class procedure processList(parentName: String; list: TJSONArray; parent: TTreeJsonNode);
    class procedure processPrimitiveType(name: string; obj: TZAbstractObject; parent: TTreeJsonNode);
    class procedure processObject(name: string; obj: TJSONObject; parent: TTreeJsonNode);
    class procedure processBoolean(name: string; obj: _Boolean; parent: TTreeJsonNode);
    class procedure processString(name: string; obj: _String; parent: TTreeJsonNode);
    class procedure processDouble(name: string; obj: _Number; parent: TTreeJsonNode);
    class procedure processInteger(name: string; obj: _Integer; parent: TTreeJsonNode);

    constructor create(key: String; value: variant);
    destructor destroy; override;
  end;

  TTreeJsonNodes = class
  public
    itens: TObjectList;
    procedure add(item: TTreeJsonNode);
    function get(index: integer): TTreeJsonNode;
    function count: integer;
    procedure clear;

    constructor create;
    destructor destroy; override;
  end;

  TJsonManager = class
  private
    class procedure serialize(List: TObjectList; JSON: TJSONArray); overload;
    class procedure serialize(List: TStringList; JSON: TJSONArray); overload;
    class procedure serialize(List: TSortedCollection; JSON: TJSONArray); overload;
    class procedure serialize(owner: TCustomPersistent; PropInfo: PPropInfo; JSON: TJSONobject); overload;
    class procedure serialize(itemArray: TItemArray; JSON: TJSONArray); overload;
    class procedure loadEntity(JSON: TZAbstractObject; Entity: TCustomPersistent; DecodeUTF8:boolean); overload;
    class procedure loadEntity(JSON: TJSONArray; List: TStringList; DecodeUTF8:boolean); overload;
    class procedure loadEntityField(Obj: TCustomPersistent; PropInfo: PPropInfo; JsonObject: TJsonObject; DecodeUTF8:boolean);overload;
    class function valueToVariant(jsonObject: TZAbstractObject): variant;
    class procedure processClass(owner: TCustomPersistent; PropInfo: PPropInfo; JSON: TJSONobject);
    class procedure loadStringList(fieldName: string; strList: TStringList; jsonObj: TJSONObject; DecodeUTF8: boolean);
    class procedure loadCollection(fieldName: string; List: TCollection; jsonObj: TJSONObject; DecodeUTF8: boolean);
    class procedure loadSortedCollection(fieldName: string; sortedList: TSortedCollection; jsonObj: TJSONObject; DecodeUTF8: boolean);
    class procedure loadDateTimeObject(fieldName: string; dateTimeObject: TDateTimeObject; jsonObj: TJSONObject);
    class function isJsonObject(jsonObj: TObject): boolean;
    class procedure processDouble(name: string; obj: _Number; nodes: TNodes);
    class procedure processList(parentName: String; list: TJSONArray; nodes: TNodes);
    class procedure processObject(name: string; obj: TJSONObject; nodes: TNodes);
    class procedure processInteger(name: string; obj: _Integer; nodes: TNodes);
    class procedure processPrimitiveType(name: string; obj: TZAbstractObject; nodes: TNodes);
    class procedure processBoolean(name: string; obj: _Boolean; nodes: TNodes);
    class procedure processString(name: string; obj: _String; nodes: TNodes);
  public
    class function serialize(sortedList: TSortedCollection): string; overload;
    class function serialize(List: TObjectList):String; overload;
    class function serialize(List: TStringList):String; overload;
    class function serialize(Entity: TCustomPersistent): String; overload;
    class function deserialize(JSON: string; classType: TclassType): TCustomPersistent; overload;
    class function deserialize(JSON: string; classType: TclassType; DecodeUTF8:boolean): TCustomPersistent; overload;
    class function valueIsType(PropInfo: PPropInfo; type_info: PTypeInfo): boolean;
    class procedure saveToFile(fileName: string; Entity: TCustomPersistent); overload;
    class procedure saveToFile(fileName: string; Entity: TCollection); overload;
    class procedure saveToStream(Stream: TStream; Entity: TCustomPersistent); overload;
    class procedure saveToStream(Stream: TStream;  Entity: TCollection); overload;
    class function loadFromStream(Stream: TStream; classType: TclassType): TCustomPersistent; overload;
    class function loadFromStream(Stream: TStream; ListType: TCollectionType; itemType: TclassType): TCollection; overload;
    class function loadFromFile(fileName: string; classType: TclassType): TCustomPersistent; overload;
    class function loadFromFile(fileName: string; ListType: TCollectionType; itemType: TclassType): TCollection; overload;
    class function deserialize(JSON: String; ListType: TCollectionType; itemType: TclassType): TCollection; overload;
    class function deserialize(JSON: String; ListType: TCollectionType; itemType: TclassType; DecodeUTF8:boolean): TCollection; overload;
    class function deserialize(JSON: String; ListType: TSortedCollectionType; itemType: TclassType; DecodeUTF8:boolean): TSortedCollection; overload;
    class function deserialize(JSON: String; ListType: TSortedCollectionType; itemType: TclassType): TSortedCollection; overload;
    class function isDebug: boolean;
    class procedure setDebug(debugValue: boolean);
    class function getNodes(json: String): TNodes;


  end;



implementation

class function TJsonManager.deserialize(JSON: string; classType: TclassType): TCustomPersistent;
begin
  Result:=TJsonManager.deserialize(JSON, classType, false);
end;

class function TJsonManager.deserialize(JSON: string; classType: TclassType; DecodeUTF8:boolean): TCustomPersistent;
var obj: TCustomPersistent;
  JsonObject: TZAbstractObject;
  jsonobj: TObject;
  source: string;
  strStream: TStringStream;
  ms: TMemoryStream;
  msg: string;
begin
  try
    source:=JSON;
    if trim(JSON)='' then begin
      source:='{}';
    end;
    jsonobj:=TJSONObject.create(source);
    obj:=classType.newInstance;
    if assigned(jsonobj) then begin
      JsonObject:=jsonobj as TZAbstractObject;
      TJsonManager.loadEntity(jsonObject, obj, DecodeUTF8);
      jsonObject.Free;
    end;
    Result:=obj;
  except
    on e: exception do begin
      msg:='Erro: ' + e.Message + #13#10 + ' - Json: ' + #13#10 + JSON;
      if not TJsonManager.isDebug then begin
        raise Exception.Create(msg);
      end else begin
        ms:=TMemoryStream.Create;
        try
          strStream:=TStringStream.Create(msg);
          try
            ms.LoadFromStream(strStream);
            ms.SaveToFile(ExtractFilePath(Application.exeName) + '\' + classType.ClassName + '_DeserializeJsonError.txt');
          finally
            strStream.free;
          end;
        finally
          ms.free;
        end;
        raise Exception.Create(msg);
      end;
    end;
  end;
end;

class function TJsonManager.serialize(Entity: TCustomPersistent): String;
var NroProp, i:integer;
  ListProp:TPropList;
  PropInfo:PPropInfo;
  JsonObject: TJSONobject;
begin
  JsonObject:=TJSONobject.Create;
  NroProp:=GetPropList(Entity.ClassInfo, tkAny, @ListProp);
  for i:=0 to NroProp-1 do begin
    PropInfo:=GetPropInfo(Entity,ListProp[i].Name,tkAny);
    if Assigned(PropInfo) then begin
      TJsonManager.serialize(Entity, PropInfo, JsonObject);
    end;
  end;
  Result:=JsonObject.toString;
  if trim(Result)='' then begin
    Result:='{}';
  end;
  JsonObject.Free;
end;

class function TJsonManager.serialize(List: TStringList): String;
var jsonArray:TJSONArray;
begin
  jsonArray:=TJSONArray.create;
  try
    self.serialize(List,jsonArray);
    result:=jsonArray.toString;
  finally
    jsonArray.Free;
  end;
end;

class function TJsonManager.valueIsType(PropInfo: PPropInfo; type_info: PTypeInfo): boolean;
begin
 result:=(GetTypeData(PropInfo.PropType^)^.BaseType^ = type_info);
end;

class procedure TJsonManager.serialize(itemArray: TItemArray; JSON: TJSONArray);
var int64Value: Int64;
  floatValue: Double;
  strValue: string;
  intValue:integer;
  JsonObj: TJSONObject;
begin
  if VarIsType(itemArray.value, varInteger) then begin
    intValue:=itemArray.value;
    JSON.put(intValue);
  end else if varIsType(ItemArray.value, varInt64) then begin
    int64Value:=itemArray.value;
    JSON.put(int64Value);
  end else if varIsType(ItemArray.value, varDouble) then begin
    floatValue:=itemArray.value;
    JSON.put(floatValue);
  end else if varIsType(ItemArray.value, varString) or varIsType(ItemArray.value, varOleStr) or varIsType(ItemArray.value, varStrArg) then begin
    strValue:=itemArray.value;
    JSON.put(strValue);
  end else begin
    JsonObj:=TJSONObject.Create;
    strValue:=itemArray.value;
    JsonObj.put('value' ,strValue);
    JSON.put(JsonObj);
    // Revisar
  end;
end;

class procedure TJsonManager.processClass(owner: TCustomPersistent; PropInfo: PPropInfo; JSON: TJSONobject);
var classe: TClass;
  strList: TStringList;
  name: string;
  PropInfo2: PPropInfo;
  JsonList: TJSONArray;
  list: TObjectList;
  indexlist: TSortedCollection;
  dateTimeObject: TDateTimeObject;
  Obj: TCustomPersistent;
  JsonObject: TJSONobject;
  NroProp, i: integer;
  ListProp:TPropList;
begin
//  classe:=GetObjectPropClass(owner, PropInfo);
  classe:=GetObjectProp(owner, PropInfo).ClassType;
  name := owner.RenameFor(Propinfo.Name);
  if Assigned(classe) then begin
    if (not classe.InheritsFrom(TSortedCollection)) and classe.InheritsFrom(TStringList) then begin
      strList:=GetObjectProp(owner, PropInfo) as TStringList;
      JsonList:=TJSONArray.create;
      JSON.put(Name, JsonList);
      TJsonManager.serialize(strList, JsonList);
    end else if classe.InheritsFrom(TCollection)  then begin
      list:=GetObjectProp(owner, PropInfo) as TCollection;
      JsonList:=TJSONArray.Create;
      JSON.put(Name, JsonList);
      TJsonManager.serialize(list, JsonList);
    end else if classe.InheritsFrom(TSortedCollection)  then begin
      indexlist:=GetObjectProp(owner, PropInfo) as TSortedCollection;
      JsonList:=TJSONArray.Create;
      JSON.put(Name, JsonList);
      TJsonManager.serialize(indexlist, JsonList);
    end else if classe.InheritsFrom(TDateTimeObject) then begin
      dateTimeObject:=GetObjectProp(owner, PropInfo) as TDateTimeObject;
      JSON.put(Name,dateTimeObject.formatDateTime);
    end else if classe.InheritsFrom(TCustomPersistent) then begin
      Obj:=GetObjectProp(owner, PropInfo) as TCustomPersistent;
      JsonObject:=TJSONobject.Create;
      JSON.put(Name, JsonObject);
      NroProp:=GetPropList(Obj.ClassInfo, tkAny, @ListProp);
      for i:=0 to NroProp-1 do begin
        PropInfo2:=GetPropInfo(Obj,ListProp[i].Name,tkAny);
        if Assigned(PropInfo2) then begin
          TJsonManager.serialize(Obj, PropInfo2, JsonObject);
        end;
      end;
    end;
  end;
end;

class procedure TJsonManager.serialize(owner: TCustomPersistent; PropInfo: PPropInfo; JSON: TJSONobject);
var int64Value: Int64;
  floatValue: Double;
  strValue: string;
  intValue:integer;
  dateValue: TDateTime;
  boolValue: boolean;
  variantValue: variant;
  JsonObj: TJSONObject;
  name: string;
begin
  if not owner.isExcludedField(PropInfo.Name) then begin
    name := owner.RenameFor(Propinfo.Name);
    if GetTypeData(PropInfo^.PropType^)=GetTypeData(TypeInfo(TDateTime)) then begin
      dateValue:=GetFloatProp(owner,PropInfo);
      JSON.put(Name, formatDateTime('dd/mm/yyyy', dateValue));
    end else if GetTypeData(PropInfo^.PropType^)=GetTypeData(TypeInfo(Boolean)) then begin
      boolValue:=false;
      variantValue:=GetPropValue(owner, PropInfo.Name);
      name := owner.RenameFor(Propinfo.Name);
      if not VarIsNull(variantValue) then begin
        boolValue:=variantValue;
      end;
      JSON.put(Name, boolValue);
    end else begin
      Case PropInfo.PropType^.Kind of
        tkInteger: begin
          intValue:=GetOrdProp(owner,PropInfo);
          JSON.put(Name, intValue);
        end;
        tkInt64: begin
          int64Value:=GetInt64Prop(owner, PropInfo);
          JSON.put(Name, int64Value);
        end;
        tkFloat: begin
          floatValue:=GetFloatProp(owner, PropInfo);
          JSON.put(Name, floatValue, owner.getCurrencyDecimals(name));
        end;
        tkUnknown,tkLString,tkWString,tkString,{$ifndef VER150} tkUString,{$endif}tkChar: begin
          strValue:=GetStrProp(owner,PropInfo);
          JSON.put(Name, strValue);
        end;
        tkVariant: begin
          JsonObj:=TJSONObject.create;
          strValue:=GetVariantProp(owner, PropInfo);
          JsonObj.put('value', strValue);
          JSON.put(Name, JsonObj);
        end;
        tkEnumeration: begin
          strValue:=GetEnumProp(owner,PropInfo);
          JSON.put(Name, strValue);
        end;
        tkClass: begin
          self.processClass(owner, PropInfo, JSON);
        end;
      end;
    end;
  end;
end;

class procedure TJsonManager.serialize(List: TObjectList; JSON: TJSONArray);
var JsonObject: TJSONobject;
  obj: TCustomPersistent;
  itemArray: TItemArray;
  i, j: integer;
  NroProp:integer;
  ListProp:TPropList;
  PropInfo: PPropInfo;
begin
  for i:=0 to list.Count - 1 do begin
    obj:=list[i] as TCustomPersistent;
    if obj.InheritsFrom(TItemArray) then begin
      itemArray:=obj as TItemArray;
      TJsonManager.serialize(itemArray, JSON);
    end else begin
      JsonObject:=TJSONobject.Create;
      NroProp:=GetPropList(Obj.ClassInfo, tkAny, @ListProp);
      for j:=0 to NroProp-1 do begin
        PropInfo:=GetPropInfo(Obj,ListProp[j].Name,tkAny);
        if Assigned(PropInfo) then begin
          TJsonManager.serialize(Obj, PropInfo, JsonObject);
        end;
      end;
      JSON.put(JsonObject);
    end;
  end;
end;

class procedure TJsonManager.serialize(List: TSortedCollection; JSON: TJSONArray);
var JsonObject: TJSONobject;
  obj: TCustomPersistent;
  itemArray: TItemArray;
  i, j: integer;
  NroProp:integer;
  ListProp:TPropList;
  PropInfo: PPropInfo;
begin
  for i:=0 to list.Count - 1 do begin
    obj:=List.get(i) as TCustomPersistent;
    JsonObject:=TJSONobject.Create;
    if obj.InheritsFrom(TItemArray) then begin
      itemArray:=obj as TItemArray;
      TJsonManager.serialize(itemArray, JSON);
    end else begin
      NroProp:=GetPropList(Obj.ClassInfo, tkAny, @ListProp);
      for j:=0 to NroProp-1 do begin
        PropInfo:=GetPropInfo(Obj,ListProp[j].Name,tkAny);
        if Assigned(PropInfo) then begin
          TJsonManager.serialize(Obj, PropInfo, JsonObject);
        end;
      end;
      JSON.put(JsonObject);
    end;
  end;
end;

class procedure TJsonManager.serialize(List: TStringList; JSON: TJSONArray);
var item: string;
  i: integer;
begin
  for i:=0 to list.Count - 1 do begin
    item:=List[i];
    JSON.put(item);
  end;
end;

class function TJsonManager.valueToVariant(jsonObject: TZAbstractObject): variant;
begin
  Result:=variants.Null;
  if jsonObject is _Number then begin
    Result:=_Number(jsonObject).doubleValue;
  end else if jsonObject is _Boolean then begin
    Result:=_Boolean(jsonObject).toString=_Boolean(jsonObject)._TRUE.toString;
  end else if jsonObject is _Double then begin
    Result:=_Double(jsonObject).doubleValue;
  end else if jsonObject is _Integer then begin
    Result:=_Integer(jsonObject).intValue;
  end else if jsonObject is _String then begin
    Result:=_String(jsonObject).toString;
  end else if jsonObject is NULL then begin
    Result:=variants.Null;
  end;
end;

class procedure TJsonManager.loadEntityField(Obj: TCustomPersistent; PropInfo: PPropInfo; JsonObject: TJsonObject; DecodeUTF8:boolean);
var int64Value: Int64;
  intValue: Integer;
  itemArray: TItemArray;
  dateValue: TDateTime;
  doubleValue: Double;
  strValue:String;
  boolValue: Boolean;
  variantValue: Variant;
  name: string;
begin
  if JsonObject<>nil then begin
    try
      name:=PropInfo.Name;
      variantValue:=TJsonManager.valueToVariant(JsonObject);
      if obj.InheritsFrom(TItemArray) then begin
        itemArray:=obj as TItemArray;
        itemArray.value:=variantValue;
      end else begin
        if GetTypeData(PropInfo^.PropType^)=GetTypeData(TypeInfo(TDateTime)) then begin
          if not VarIsNull(variantValue) then begin
            if TryStrToDateTime(variantValue, dateValue) then begin
              SetFloatProp(Obj,PropInfo,dateValue);
            end;
          end;
        end else if GetTypeData(PropInfo^.PropType^)=GetTypeData(TypeInfo(Boolean)) then begin
          if not VarIsNull(variantValue) then begin
            strValue:=variantValue;
            if TryStrToBool(strValue, boolValue) then begin
              SetPropValue(Obj,PropInfo.Name,boolValue);
            end;
          end;
        end else begin
          Case PropInfo.PropType^.Kind of
            tkInteger: begin
              if not VarIsNull(variantValue) then begin
                strValue:=variantValue;
                if tryStrToInt(strValue, intValue) then begin
                  SetOrdProp(Obj,PropInfo,intValue);
                end;
              end;
            end;
            tkInt64: begin
              if not VarIsNull(variantValue) then begin
                strValue:=variantValue;
                if TryStrToInt64(strValue, int64Value) then begin
                  SetInt64Prop(Obj,PropInfo,int64Value);
                end;
              end;
            end;
            tkFloat: begin
              if not VarIsNull(variantValue) then begin
                strValue:=variantValue;
                if TryStrToFloat(strValue, doubleValue) then begin
                  setFloatProp(Obj,PropInfo,doubleValue);
                end;
              end;
            end;
            tkUnknown,tkLString,tkWString,{$ifndef VER150} tkUString,{$endif}tkString,tkChar: begin
              if not VarIsNull(variantValue) then begin
                strValue:=variantValue;
                if DecodeUTF8 then begin
                  if UTF8Decode(variantValue)<>'' then begin
                    strValue:=UTF8Decode(variantValue);
                  end;
                end;
                SetStrProp(Obj,PropInfo,strValue);
              end;
            end;
            tkVariant: begin
              if not VarIsNull(variantValue) then begin
                SetVariantProp(Obj,PropInfo,variantValue);
              end;
            end;
            tkEnumeration: begin
              if not VarIsNull(variantValue) then begin
                strValue:=variantValue;
                SetEnumProp(Obj,PropInfo,variantValue);
              end;
            end;
          end;
        end;
      end;
    except
      on e: exception do begin
        strValue:='';
        if not VarIsNull(variantValue) then begin
          strValue:=variantValue;
        end;
        raise Exception.create('Objeto: ' + Obj.ClassName + '.' + name + ' - conteúdo: ' + strValue + #13#10 + 'Exception: ' + e.Message);
      end;
    end;
  end;
end;

class procedure TJsonManager.loadEntity(JSON: TJSONArray; List: TStringList; DecodeUTF8:boolean);
var i: integer;
  item: string;
begin
  List.Clear;
  for i:=0 to JSON.length -1 do begin
    item:=JSON.getString(i);
    List.Add(item);
  end;
end;

class procedure TJsonManager.loadStringList(fieldName: string; strList: TStringList; jsonObj: TJSONObject; DecodeUTF8: boolean);
var jsonBase: TZAbstractObject;
  JsonList: TJSONArray;
begin
  strList.Clear;
  if TJsonManager.isJsonObject(jsonObj) then begin
    jsonBase:=jsonObj.opt(fieldName);
    if jsonBase<>nil then begin
      if not (jsonBase is NULL) then begin
        JsonList:=JsonBase as TJSONArray;
        TJsonManager.loadEntity(JsonList, strList, DecodeUTF8);
      end;
    end;
  end;
end;

class procedure TJsonManager.loadCollection(fieldName: string; List: TCollection; jsonObj: TJSONObject; DecodeUTF8: boolean);
var jsonBase: TZAbstractObject;
  JsonList: TJSONArray;
  classType: TclassType;
  i: integer;
  attr: TCustomPersistent;
begin
  List.Clear;
  classType:=list.getItemType;
  if TJsonManager.isJsonObject(jsonObj) then begin
    jsonBase:=jsonObj.opt(fieldName);
    if jsonBase<>nil then begin
      if (not (jsonBase is NULL)) and (jsonBase is TJSONArray) then begin
        JsonList:=JsonBase as TJSONArray;
        for i:=0 to JsonList.length - 1 do begin
          attr:=classType.newInstance;
          jsonBase:=JsonList.opt(i);
          TJsonManager.loadEntity(jsonBase, attr, DecodeUTF8);
          list.Add(attr);
        end;
      end;
    end;
  end;
end;

class procedure TJsonManager.loadSortedCollection(fieldName: string; sortedList: TSortedCollection; jsonObj: TJSONObject; DecodeUTF8: boolean);
var jsonBase: TZAbstractObject;
  JsonList: TJSONArray;
  classType: TclassType;
  i: integer;
  attr: TCustomPersistent;
begin
  sortedList.Clear;
  classType:=sortedList.getItemType;
  if TJsonManager.isJsonObject(jsonObj) then begin
    jsonBase:=jsonObj.opt(fieldName);
    if jsonBase<>nil then begin
      if not (jsonBase is NULL) then begin
        JsonList:=JsonBase as TJSONArray;
        for i:=0 to JsonList.length - 1 do begin
          attr:=classType.newInstance;
          jsonBase:=JsonList.opt(i);
          TJsonManager.loadEntity(jsonBase, attr, DecodeUTF8);
          sortedList.add(attr);
        end;
      end;
    end;
  end;
end;

class procedure TJsonManager.loadDateTimeObject(fieldName: string; dateTimeObject: TDateTimeObject; jsonObj: TJSONObject);
var variantValue: variant;
  jsonBase: TZAbstractObject;
begin
  if TJsonManager.isJsonObject(jsonObj) then begin
    jsonBase:=jsonObj.opt(fieldName);
    if jsonBase<>nil then begin
      if not (jsonBase is NULL) then begin
        variantValue:=TJsonManager.valueToVariant(jsonBase);
        dateTimeObject.loadFrom(variantValue);
      end;
    end;
  end;
end;

class function TJsonManager.isJsonObject(jsonObj: TObject): boolean;
begin
  result:=true;
  if jsonObj is TJSONArray then begin
    result:=false;
  end;
  if jsonObj is _Boolean then begin
    result:=false;
  end;
  if jsonObj is _Integer then begin
    result:=false;
  end;
  if jsonObj is _Number then begin
    result:=false;
  end;
  if jsonObj is _String then begin
    result:=false;
  end;
  if jsonObj is _Double then begin
    result:=false;
  end;
  if jsonObj is NULL then begin
    result:=false;
  end;
end;

class procedure TJsonManager.loadEntity(JSON: TZAbstractObject; Entity: TCustomPersistent; DecodeUTF8:boolean);
var obj:TObject;
  NroProp, i:integer;
  ListProp: TPropList;
  PropInfo: PPropInfo;
  fieldName: String;
  classe: TClass;
  field: TCustomPersistent;
  list: TCollection;
  sortedList: TSortedCollection;
  strList: TStringList;
  jsonBase: TZAbstractObject;
  jsonObj: TJSONObject;
  dateTimeObject: TDateTimeObject;
begin
  if (JSON<>nil) and (not (JSON is NULL)) then begin
    jsonObj:=TJSONObject(json);
    NroProp:=GetPropList(Entity.ClassInfo, tkAny, @ListProp);
    for i:=0 to NroProp-1 do begin
      fieldName:=Entity.RenameFor(ListProp[i].Name);
      PropInfo:=GetPropInfo(Entity,ListProp[i].Name,tkAny);
      if Assigned(PropInfo) then begin
        classe:=GetObjectPropClass(PropInfo);
        obj:=GetObjectProp(Entity, PropInfo);
        if Assigned(obj) and (PropInfo.PropType^.Kind=tkClass) then begin
          if obj.InheritsFrom(TDateTimeObject) then begin
            dateTimeObject:=obj as TDateTimeObject;
            TJsonManager.loadDateTimeObject(fieldName, dateTimeObject, jsonObj);
          end else if (not classe.InheritsFrom(TSortedCollection)) and classe.InheritsFrom(TStringList)  then begin
            strList:=obj as TStringList;
            TJsonManager.loadStringList(fieldName, strList, jsonObj, DecodeUTF8);
          end else if classe.InheritsFrom(TCustomPersistent) then begin
            field:=obj as TCustomPersistent;
            if TJsonManager.isJsonObject(jsonObj) then begin
              jsonBase:=jsonObj.opt(fieldName);
              if jsonBase<>nil then begin
                TJsonManager.loadEntity(jsonBase, field, DecodeUTF8);
              end;
            end;
          end else if classe.InheritsFrom(TCollection) then begin
            list:=obj as TCollection;
            TJsonManager.loadCollection(fieldName, list, jsonObj, DecodeUtf8);
          end else if classe.InheritsFrom(TSortedCollection) then begin
            sortedList:=obj as TSortedCollection;
            TJsonManager.loadSortedCollection(fieldName, sortedList, jsonObj, DecodeUTF8);
          end;
        end else begin
          try
          if TJsonManager.isJsonObject(jsonObj) then begin
            jsonBase:=jsonObj.opt(fieldName);
            if jsonBase<>nil then begin
              TJsonManager.loadEntityField(Entity, PropInfo, TJSONObject(jsonBase), DecodeUTF8);
            end;
          end;
          except
            jsonBase:=jsonObj.get(fieldName);
            if jsonBase<>nil then begin
              TJsonManager.loadEntityField(Entity, PropInfo, TJSONObject(jsonBase), DecodeUTF8);
            end;
          end;
        end;
      end;
    end;
  end;
end;

class procedure TJsonManager.saveToFile(fileName: string; Entity: TCustomPersistent);
var stream: TMemoryStream;
begin
  stream:=TMemoryStream.Create;
  TJsonManager.saveToStream(stream, Entity);
  stream.SaveToFile(fileName);
  stream.Free;
end;

class procedure TJsonManager.saveToFile(fileName: string; Entity: TCollection);
var stream: TMemoryStream;
begin
  stream:=TMemoryStream.Create;
  TJsonManager.saveToStream(stream, Entity);
  stream.SaveToFile(fileName);
  stream.Free;
end;

class function TJsonManager.loadFromFile(fileName: string; classType: TclassType):TCustomPersistent;
var stream: TMemoryStream;
begin
  stream:=TMemoryStream.Create;
  stream.LoadFromFile(fileName);
  stream.Position:=0;
  Result:=TJsonManager.loadFromStream(stream,classType);
  stream.Free;
end;

class procedure TJsonManager.saveToStream(Stream: TStream;  Entity: TCustomPersistent);
var json: string;
  StrStream: TStringStream;
  ms: TMemoryStream;
begin
  json:=TJsonManager.serialize(Entity);
  ms:=TMemoryStream.create;
  StrStream:=TStringStream.Create(json);
  StrStream.Position:=0;
  ms.LoadFromStream(StrStream);
  StrStream.Free;
  ms.Position:=0;
  ms.SaveToStream(Stream);
  ms.free;
end;

class procedure TJsonManager.saveToStream(Stream: TStream;  Entity: TCollection);
var json: string;
  StrStream: TStringStream;
  ms: TMemoryStream;
begin
  json:=TJsonManager.serialize(Entity);
  ms:=TMemoryStream.create;
  StrStream:=TStringStream.Create(json);
  StrStream.Position:=0;
  ms.LoadFromStream(StrStream);
  StrStream.Free;
  ms.Position:=0;
  ms.SaveToStream(Stream);
  ms.free;
end;

class function TJsonManager.loadFromStream(Stream: TStream; classType: TclassType): TCustomPersistent;
var json: string;
  StrStream: TStringStream;
  ms: TMemoryStream;
begin
  Stream.Position:=0;
  StrStream:=TStringStream.Create('');
  ms:=TMemoryStream.create;
  ms.LoadFromStream(Stream);
  ms.Position:=0;
  ms.SaveToStream(StrStream);
  json:=StrStream.DataString;
  StrStream.Free;
  ms.free;
  Result:=TJsonManager.deserialize(json,classType);
end;

class function TJsonManager.serialize(List: TObjectList): String;
var jsonArray:TJSONArray;
begin
  jsonArray:=TJSONArray.create;
  try
    self.serialize(List,jsonArray);
    result:=jsonArray.toString;
  finally
    jsonArray.Free;
  end;
end;

class function TJsonManager.serialize(sortedList: TSortedCollection): string;
var jsonArray:TJSONArray;
begin
  jsonArray:=TJSONArray.create;
  try
    self.serialize(sortedList,jsonArray);
    result:=jsonArray.toString;
  finally
    jsonArray.Free;
  end;
end;



class function TJsonManager.deserialize(JSON: String; ListType: TSortedCollectionType; itemType: TclassType; DecodeUTF8: boolean): TSortedCollection;
var list: TSortedCollection;
  jsonArray: TJSONArray;
  jsonBase: TZAbstractObject;
  source: string;
  attr: TCustomPersistent;
  i: integer;
  strStream: TStringStream;
  ms: TMemoryStream;
  msg: string;
begin
  try
    source:=JSON;
    if trim(JSON)='' then begin
      source:='[]';
    end;
    jsonArray:=TJSONArray.create(source);
    list:=ListType.newInstance(itemType,true);
    for i:=0 to JsonArray.length - 1 do begin
      attr:=itemType.newInstance;
      jsonBase:=JsonArray.opt(i);
      TJsonManager.loadEntity(jsonBase, attr, DecodeUTF8);
      list.Add(attr);
    end;
    list.Sort;
    jsonArray.Free;
    Result:=list;
  except
    on e: exception do begin
      msg:='Erro: ' + e.Message + #13#10 + ' - Json: ' + #13#10 + JSON;
      if not TJsonManager.isDebug then begin
        raise Exception.Create(msg);
      end else begin
        ms:=TMemoryStream.Create;
        try
          strStream:=TStringStream.Create(msg);
          try
            ms.LoadFromStream(strStream);
            ms.SaveToFile(ExtractFilePath(Application.exeName) + '\' + ListType.ClassName + '_DeserializeJsonError.txt');
          finally
            strStream.free;
          end;
        finally
          ms.free;
        end;
        raise Exception.Create(msg);
      end;
    end;
  end;
end;

class function TJsonManager.deserialize(JSON: String; ListType: TSortedCollectionType; itemType: TclassType): TSortedCollection;
begin
  result:=self.deserialize(JSON,ListType,itemType,false);
end;

class function TJsonManager.deserialize(JSON: String; ListType: TCollectionType; itemType: TclassType): TCollection;
begin
  result:=self.deserialize(JSON,ListType,itemType,false);
end;

class function TJsonManager.deserialize(JSON: String; ListType: TCollectionType; itemType: TclassType; DecodeUTF8: boolean): TCollection;
var list: TCollection;
  jsonArray: TJSONArray;
  jsonBase: TZAbstractObject;
  source: string;
  attr: TCustomPersistent;
  i: integer;
  strStream: TStringStream;
  ms: TMemoryStream;
  msg: string;
begin
  try
    source:=JSON;
    if trim(JSON)='' then begin
      source:='[]';
    end;
    jsonArray:=TJSONArray.create(source);
    list:=ListType.newInstance(itemType,true);
    for i:=0 to JsonArray.length - 1 do begin
      attr:=itemType.newInstance;
      jsonBase:=JsonArray.opt(i);
      TJsonManager.loadEntity(jsonBase, attr, DecodeUTF8);
      list.Add(attr);
    end;
    jsonArray.Free;
    Result:=list;
  except
    on e: exception do begin
      msg:='Erro: ' + e.Message + #13#10 + ' - Json: ' + #13#10 + JSON;
      if not TJsonManager.isDebug then begin
        raise Exception.Create(msg);
      end else begin
        ms:=TMemoryStream.Create;
        try
          strStream:=TStringStream.Create(msg);
          try
            ms.LoadFromStream(strStream);
            ms.SaveToFile(ExtractFilePath(Application.exeName) + '\' + ListType.ClassName + '_DeserializeJsonError.txt');
          finally
            strStream.free;
          end;
        finally
          ms.free;
        end;
        raise Exception.Create(msg);
      end;
    end;
  end;
end;

class function TJsonManager.loadFromFile(fileName: string; ListType: TCollectionType; itemType: TclassType): TCollection;
var stream: TMemoryStream;
begin
  stream:=TMemoryStream.Create;
  stream.LoadFromFile(fileName);
  stream.Position:=0;
  Result:=TJsonManager.loadFromStream(stream,ListType,itemType);
  stream.Free;
end;

class function TJsonManager.loadFromStream(Stream: TStream; ListType: TCollectionType; itemType: TclassType): TCollection;
var json: string;
  StrStream: TStringStream;
  ms: TMemoryStream;
begin
  Stream.Position:=0;
  StrStream:=TStringStream.Create('');
  ms:=TMemoryStream.create;
  ms.LoadFromStream(Stream);
  ms.Position:=0;
  ms.SaveToStream(StrStream);
  json:=StrStream.DataString;
  StrStream.Free;
  ms.free;
  Result:=TJsonManager.deserialize(json,ListType,itemType);
end;

var debug: boolean = false;
  criticalSection: TCriticalSection;

class function TJsonManager.isDebug: boolean;
begin
  criticalSection.Acquire;
  try
    result:=debug;
  finally
    criticalSection.Release;
  end;
end;

class procedure TJsonManager.setDebug(debugValue: boolean);
begin
  criticalSection.Acquire;
  try
    debug:=debugValue;
  finally
    criticalSection.Release;
  end;
end;

class procedure TJsonManager.processList(parentName:String;list:TJSONArray; nodes: TNodes);
var i: integer;
  name: string;
  obj: TZAbstractObject;
begin
  for i:=0 to list.length-1 do begin
    obj:=list.get(i);
    name:=parentName + '[' + IntToStr(i) + ']';
    if obj is TJSONObject then begin
      self.processObject(name, TJSONObject(obj), nodes);
    end else if obj is TJSONArray then begin
      self.processList(name, TJSONArray(obj), nodes);
    end else begin
      self.processPrimitiveType(name, obj, nodes);
    end;
  end;
end;

class procedure TJsonManager.processPrimitiveType(name: string; obj: TZAbstractObject; nodes: TNodes);
begin
  if obj is _Number then begin
    self.processDouble(name, _Number(obj), nodes);
  end else if obj is _Integer then begin
    self.processInteger(name, _Integer(obj), nodes);
  end else if obj is _Boolean then begin
    self.processBoolean(name, _Boolean(obj), nodes);
  end else if obj is _String then begin
    self.processString(name, _String(obj), nodes);
  end else if obj is NULL then begin
    nodes.add(TNode.create(name, variants.Null));
  end;
end;

class procedure TJsonManager.processObject(name: string; obj: TJSONObject; nodes: TNodes);
var i: integer;
  nodeName, parentName: string;
  prop: TZAbstractObject;
  names: TJSONArray;
begin
  names:=obj.names;
  if names<>nil then begin
    for i:=0 to names.length-1 do begin
      nodeName:=_String(names.get(i)).toString;
      prop:=obj.get(nodeName);
      parentName:=name + '.' + nodeName;
      if prop is TJSONArray then begin
        self.processList(parentName, TJSONArray(prop), nodes);
      end else if prop is TJSONObject then begin
        self.processObject(parentName, TJSONObject(prop), nodes);
      end else begin
        self.processPrimitiveType(parentName, prop, nodes);
      end;
    end;
  end;
  names.free;
end;

class procedure TJsonManager.processBoolean(name: string; obj: _Boolean; nodes: TNodes);
var boolValue: boolean;
begin
  boolValue:=obj.toString=obj._TRUE.toString;
  nodes.add(TNode.create(name, boolValue));
end;

class procedure TJsonManager.processString(name: string; obj: _String; nodes: TNodes);
begin
  nodes.add(TNode.create(name, obj.toString));
end;

class procedure TJsonManager.processDouble(name: string; obj: _Number; nodes: TNodes);
begin
  nodes.add(TNode.create(name, obj.doubleValue));
end;

class procedure TJsonManager.processInteger(name: string; obj: _Integer; nodes: TNodes);
begin
  nodes.add(TNode.create(name, obj.intValue));
end;

class function TJsonManager.getNodes(json: String): TNodes;
var jsonObj, obj: TJSONObject;
  abstractObj: TZAbstractObject;
  arrayObj:TJSONArray;
  i: integer;
  name: string;
  nodes: TNodes;
  names: TJSONArray;
begin
  nodes:=TNodes.create;
  jsonObj:=TJSONObject.create(json);
  names:=jsonObj.names;
  if names<>nil then begin
    for i:=0 to names.length-1 do begin
      name:=_String(names.get(i)).toString;
      abstractObj:=jsonObj.get(name);
      if abstractObj is TJSONObject then begin
        obj:=TJSONObject(abstractObj);
        self.processObject(name, obj, nodes);
      end else if abstractObj is TJSONArray then begin
        arrayObj:=TJSONArray(abstractObj);
        self.processList(name, arrayObj, nodes);
      end;
    end;
  end;
  names.Free;
  jsonObj.free;
  result:=nodes;
end;

{ TNode }

constructor TNode.create(key: String; value: variant);
begin
  inherited create;
  Self.value:=value;
  Self.key:=key;
end;

destructor TNode.destroy;
begin
  inherited;
end;

{ TNodes }

procedure TNodes.add(item: TNode);
begin
  Self.itens.AddObject(item.key, item);
end;

procedure TNodes.clear;
var i:Integer;
    item:TNode;
begin
  for i:=0 to Self.itens.Count-1 do begin
    item:=Self.get(i);
    item.Free;
  end;
  Self.itens.Clear;
end;

function TNodes.count: integer;
begin
  Result:=Self.itens.Count;
end;

constructor TNodes.create;
begin
  inherited;
  Self.itens:=TStringList.Create;
end;

destructor TNodes.destroy;
begin
  Self.clear;
  Self.itens.Free;
  inherited;
end;

function TNodes.get(index: integer): TNode;
begin
  Result:=TNode(Self.itens.Objects[index]);
end;

{ TTreeJsonNode }

constructor TTreeJsonNode.create(key: String; value: variant);
begin
  inherited create(key, value);
  self.childs:=TTreeJsonNodes.create;
end;

destructor TTreeJsonNode.destroy;
begin
  self.childs.free;
  inherited;
end;

class function TTreeJsonNode.getNodes(json: String): TTreeJsonNodes;
var jsonObj, obj: TJSONObject;
  abstractObj: TZAbstractObject;
  arrayObj:TJSONArray;
  i: integer;
  name: string;
  nodes: TTreeJsonNodes;
  node: TTreeJsonNode;
  names: TJSONArray;
begin
  json:=UTF8Decode(json);
  jsonObj:=TJSONObject.create(json);
  names:=jsonObj.names;
  nodes:=TTreeJsonNodes.create;
  if names<>nil then begin
    for i:=0 to names.length-1 do begin
      name:=_String(names.get(i)).toString;
      abstractObj:=jsonObj.get(name);
      if abstractObj is TJSONObject then begin
        node:=TTreeJsonNode.create(name, '');
        obj:=TJSONObject(abstractObj);
        self.processObject(name, obj,  node);
        nodes.add(node);
      end else if abstractObj is TJSONArray then begin
        node:=TTreeJsonNode.create(name, '');
        arrayObj:=TJSONArray(abstractObj);
        self.processList(name, arrayObj,  node);
        nodes.add(node);
      end;
    end;
  end;
  result:=nodes;
  names.Free;
  jsonObj.free;
end;

class procedure TTreeJsonNode.processList(parentName:String;list:TJSONArray; parent: TTreeJsonNode);
var i: integer;
  name: string;
  obj: TZAbstractObject;
  node: TTreeJsonNode;
begin
  for i:=0 to list.length-1 do begin
    obj:=list.get(i);
    name:='[' + IntToStr(i) + ']';
    if obj is TJSONObject then begin
      node:=TTreeJsonNode.create(name, '');
      self.processObject(name, TJSONObject(obj), node);
      parent.childs.add(node);
    end else if obj is TJSONArray then begin
      node:=TTreeJsonNode.create(name, '');
      self.processList(name, TJSONArray(obj), node);
      parent.childs.add(node);
    end else begin
      self.processPrimitiveType(name, obj, parent);
    end;
  end;
end;

class procedure TTreeJsonNode.processObject(name: string; obj: TJSONObject; parent: TTreeJsonNode);
var i: integer;
  nodeName: string;
  prop: TZAbstractObject;
  names: TJSONArray;
  node: TTreeJsonNode;
begin
  names:=obj.names;
  if names<>nil then begin
    for i:=0 to names.length-1 do begin
      nodeName:=_String(names.get(i)).toString;
      if upperCase(nodeName)=upperCase('dadosResidenciais') then begin
        //asm int 3 end;
      end;
      prop:=obj.get(nodeName);
      if prop is TJSONArray then begin
        node:=TTreeJsonNode.create(nodeName, '');
        self.processList(nodeName, TJSONArray(prop), node);
        parent.childs.add(node);
      end else if prop is TJSONObject then begin
        node:=TTreeJsonNode.create(nodeName, '');
        self.processObject(nodeName, TJSONObject(prop), node);
        parent.childs.add(node);
      end else begin
        processPrimitiveType(nodeName, prop, parent);
      end;
    end;
  end;
  names.free;
end;

class procedure TTreeJsonNode.processPrimitiveType(name: string; obj: TZAbstractObject; parent: TTreeJsonNode);
begin
  if obj is _Number then begin
    self.processDouble(name, _Number(obj), parent);
  end else if obj is _Integer then begin
    self.processInteger(name, _Integer(obj), parent);
  end else if obj is _Boolean then begin
    self.processBoolean(name, _Boolean(obj), parent);
  end else if obj is _String then begin
    self.processString(name, _String(obj), parent);
  end else if obj is NULL then begin
    parent.childs.add(TTreeJsonNode.create(name, variants.Null));
  end;
end;

class procedure TTreeJsonNode.processBoolean(name: string; obj: _Boolean; parent: TTreeJsonNode);
var boolValue: boolean;
begin
  boolValue:=obj.toString=obj._TRUE.toString;
  parent.childs.add(TTreeJsonNode.create(name, boolValue));
end;

class procedure TTreeJsonNode.processString(name: string; obj: _String; parent: TTreeJsonNode);
begin
  parent.childs.add(TTreeJsonNode.create(name, obj.toString));
end;

class procedure TTreeJsonNode.processDouble(name: string; obj: _Number; parent: TTreeJsonNode);
begin
  parent.childs.add(TTreeJsonNode.create(name, obj.doubleValue));
end;

class procedure TTreeJsonNode.processInteger(name: string; obj: _Integer; parent: TTreeJsonNode);
begin
  parent.childs.add(TTreeJsonNode.create(name, obj.intValue));
end;

{  TTreeJsonNodes }

constructor TTreeJsonNodes.create;
begin
  inherited;
  self.itens:=TObjectList.Create;
end;

destructor TTreeJsonNodes.destroy;
begin
  self.itens.Free;
  inherited;
end;

function TTreeJsonNodes.count: integer;
begin
  result:= self.itens.Count;
end;

procedure TTreeJsonNodes.clear;
begin
  self.itens.Clear;
end;

procedure TTreeJsonNodes.add(item: TTreeJsonNode);
begin
  self.itens.Add(item);
end;

function TTreeJsonNodes.get(index: integer): TTreeJsonNode;
begin
  result:=self.itens[index] as TTreeJsonNode;
end;

initialization
  criticalSection:=TCriticalSection.Create;
finalization
  criticalSection.Free;
end.
