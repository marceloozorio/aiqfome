unit SerializableObjects;

interface
uses
  SysUtils,
  Classes,
  Contnrs,
  TypInfo;


type
  TClassType = class of TCustomPersistent;
  TCollectionType = class of TCollection;
  TSortedCollectionType = class of TSortedCollection;
  TSortedCollection = class;

  TLevel = (tl_Self, tl_Owner);
  TAttributeType = (
                      at_String,
                      at_Double,
                      at_Integer,
                      at_Int64,
                      at_Boolean,
                      at_Enum,
                      at_DateTime
  );

  TProperty = class;
  TCollection = class;






  
{$M+}
  TCustomPersistent = class
  private
    Fname: string;
    FClassType: string;
    FProperties: TCollection;
    procedure Setname(const Value: string);
    class procedure loadDateTimeObject(dateClone,dateSource: TObject);
    class procedure loadStringList(cloneObj, sourceObj: TObject; DecodeUTF8: boolean);
    class procedure loadCollection(cloneObj, sourceObj: TObject; DecodeUTF8: boolean);
    class procedure loadSortedCollection(cloneObj, sourceObj: TCustomPersistent; DecodeUTF8: boolean);
    class procedure loadEntityField(clone, source: TCustomPersistent; PropInfoClone, PropInfoSource: PPropInfo; DecodeUTF8: boolean = false);
    class function loadEntity(clone, source: TCustomPersistent; DecodeUTF8: boolean = false): TCustomPersistent;
  public
    constructor create;
    destructor destroy; override;
    class function newInstance: TCustomPersistent; reintroduce; overload; virtual;
    function isExcludedField(fieldName: string): boolean; virtual;
    function RenameFor(fieldName: string): string; virtual;
    function getDecimalFormat(fieldName: string):string; virtual;
    function getCurrencyDecimals(fieldName: string): Byte; virtual;
    function getNameSpaceURI(): string;virtual;
    function clone: TCustomPersistent;
    procedure assign(source: TCustomPersistent);
    
    function toJson: string;
    function toXml: string;
  published
    property name: string read Fname write Setname;
    property classType: string read FClassType write FClassType;
    property properties: TCollection read FProperties write FProperties;
  end;
{$M-}

  TProperty = class(TCustomPersistent)
  private
    FTipo: TAttributeType;
  public
    function isExcludedField(fieldName: string): boolean; override;
  published
    property tipo: TAttributeType read FTipo write FTipo;
  end;

  TItemArray = class(TCustomPersistent)
  private
    Fvalue: variant;
  public
    constructor create(value: variant);
    class function newInstance: TCustomPersistent; reintroduce; overload; override;
  published
    property value: variant read FValue write FValue;
  end;
 
  TCollection = class(TObjectList)
  private
    ItemType: TclassType;
    level: TLevel;
  public
    name: string;
    constructor create(itemType: TclassType; ownsObject: boolean=true);
    function getItemType: TclassType;
    function getLevel: TLevel;
    procedure setLevel(level: TLevel);
    class function newInstance(itemType: TclassType; ownsObject: boolean=true): TCollection; reintroduce; overload; virtual;
  end;

  TSortedCollection = class(TStringList)
  private
    ItemType: TclassType;
  public
    ownsObjects: boolean;
    constructor create(itemType: TclassType; ownsObjects: boolean=true);
    procedure add(key: string; item: TObject); overload;
    procedure add(item: TObject); overload; virtual; abstract;
    function get(index: integer): TObject; overload;
    function get(key: string): TObject; overload;
    procedure clear; override;
    function count: integer;
    function getItemType: TclassType;
    destructor destroy; override;
    class function newInstance(itemType: TclassType; ownsObject: boolean=true): TSortedCollection; reintroduce; overload; virtual;
  end;

  //Classe para ser usada quando uma seção do JSON contém um vetor de inteiros
  TIntegerCollection = class(TCollection)
  public
    constructor Create(OwnsObject:Boolean=true);
    procedure Add(Value:Integer);
    function Get(Index:Integer):Integer;
    class function NewInstance(ItemType:TClassType;OwnsObject:Boolean=true):TCollection;overload;override;
  end;


implementation

uses
  XmlManager,
  JsonManager,
  Variants,
  DateHelper;

{ TCollection }

constructor TCollection.create(itemType: TclassType; ownsObject: boolean);
begin
  inherited create(ownsObject);
  self.ItemType:=itemType;
  self.level:=tl_Self;
  self.name:='';
end;

function TCollection.getItemType: TclassType;
begin
  Result:=self.ItemType;
end;

function TCollection.getLevel: TLevel;
begin
  Result:=self.level;  
end;

class function TCollection.newInstance(itemType: TclassType; ownsObject: boolean): TCollection;
begin
  result:=TCollection.create(itemType,ownsObject);
end;

procedure TCollection.setLevel(level: TLevel);
begin
  self.level:=level;
end;

{ TSortedCollection }


constructor TSortedCollection.create(itemType: TclassType; ownsObjects: boolean);
begin
  inherited create;
  self.ownsObjects:=ownsObjects;
  self.ItemType:=itemType;
end;

function TSortedCollection.getItemType: TclassType;
begin
  Result:=self.ItemType;
end;

procedure TSortedCollection.add(key: string; item: TObject);
begin
  self.AddObject(key, item);
end;

procedure TSortedCollection.clear;
var i: integer;
  obj: TObject;
begin
  if self.ownsObjects then begin
    for i:=0 to self.count-1 do begin
      obj:=self.get(i);
      obj.Free;
    end;
  end;
  inherited clear;
end;

function TSortedCollection.count: integer;
begin
  result:=inherited count;
end;

destructor TSortedCollection.destroy;
begin
  self.clear;
  inherited;
end;

function TSortedCollection.get(index: integer): TObject;
begin
  Result:=inherited Objects[index];
end;

function TSortedCollection.get(key: string): TObject;
var index: integer;
begin
  Result:=nil;
  index:=inherited IndexOf(key);
  if index<>-1 then begin
    Result:=self.get(index);
  end;
end;

class function TItemArray.newInstance: TCustomPersistent;
begin
  Result:=TItemArray.Create('');
end;

constructor TItemArray.create(value: variant);
begin
  inherited create;
  self.value:=value;
end;

function TCustomPersistent.isExcludedField(fieldName: string): boolean;
begin
  Result:=false;
  if fieldName='name' then begin
    Result:=true;
  end else if fieldName='classType' then begin
    Result:=true;  
  end else if fieldName='attributes' then begin
    Result:=true;
  end else if fieldName='properties' then begin
    Result:=true;
  end;
end;

class function TSortedCollection.newInstance(itemType: TclassType; ownsObject: boolean): TSortedCollection;
begin
  result:=TSortedCollection.create(itemType,ownsObject);
end;

{ TIntegerCollection }

constructor TIntegerCollection.Create(OwnsObject:Boolean=true);
begin
  inherited Create(TItemArray,OwnsObject);
end;

procedure TIntegerCollection.Add(Value:Integer);
begin
  inherited Add(TItemArray.create(Value));
end;

function TIntegerCollection.Get(Index:Integer):Integer;
begin
  Result:=TItemArray(Items[Index]).value;
end;

class function TIntegerCollection.NewInstance(ItemType:TClassType;OwnsObject:Boolean=true):TCollection;
begin
  Result:=TIntegerCollection.Create(OwnsObject);
end;

{ TCustomPersistent }

class function TCustomPersistent.newInstance: TCustomPersistent;
begin
  raise Exception.create('Método newInstance não foi implementado');
end;

function TCustomPersistent.RenameFor(fieldName: string): string;
begin
  Result:=fieldName;
end;

function TCustomPersistent.getDecimalFormat(fieldName: string):string;
begin
  Result:='0.00';
end;

function TCustomPersistent.getCurrencyDecimals(fieldName: string): Byte;
begin
  Result:=2;
end;

procedure TCustomPersistent.Setname(const Value: string);
begin
  Fname:=Value;
end;


function TCustomPersistent.getNameSpaceURI: string;
begin
  Result:='';
end;

constructor TCustomPersistent.create;
begin
  inherited;
  self.FProperties:=TCollection.create(TCustomPersistent);
end;

destructor TCustomPersistent.destroy;
begin
  self.FProperties.free;
  inherited;
end;

{ TAttribute }

function TProperty.isExcludedField(fieldName: string): boolean;
begin
  result:=false;
end;

function TCustomPersistent.toJson: string;
begin
  Result:=TJsonManager.serialize(self);
end;

function TCustomPersistent.toXml: string;
begin
  Result:=TXmlManager.serialize(self);
end;

function TCustomPersistent.clone: TCustomPersistent;
var clone: TCustomPersistent;
begin
  clone:=Self.newInstance;
  TCustomPersistent.loadEntity(clone, self);
  Result:=clone;
end;

procedure TCustomPersistent.assign(source: TCustomPersistent);
begin
  TCustomPersistent.loadEntity(self, source);
end;

class function TCustomPersistent.loadEntity(clone, source: TCustomPersistent; DecodeUTF8: boolean = false): TCustomPersistent;
var  NroProp, i:integer;
  objSource, objClone:TObject;
  PropInfoClone, PropInfoSource: PPropInfo;
  ListProp:TPropList;
  name:String;
  classe: TClass;
begin
    NroProp:=GetPropList(source.ClassInfo, tkAny, @ListProp);
    for i:=0 to NroProp-1 do begin
      PropInfoSource:=GetPropInfo(source,ListProp[i].Name,tkAny);
      PropInfoClone:=GetPropInfo(clone,ListProp[i].Name,tkAny);

      name:=PropInfoClone.Name;
      if (Assigned(PropInfoSource)) and (Assigned(PropInfoClone)) then begin
        if Assigned(source) and (PropInfoSource.PropType^.Kind=tkClass) then begin
          objSource:=GetObjectProp(source, PropInfoSource);
          objClone:=GetObjectProp(clone, PropInfoClone);
          classe:=GetObjectProp(source, PropInfoSource).ClassType;
          if objSource.InheritsFrom(TDateTimeObject) then begin
            TCustomPersistent.loadDateTimeObject(objClone, objSource );
          end else if (not classe.InheritsFrom(TSortedCollection)) and classe.InheritsFrom(TStringList)  then begin
            TCustomPersistent.loadStringList(clone, source, DecodeUTF8);
          end else if classe.InheritsFrom(TCustomPersistent) then begin
            TCustomPersistent.loadEntity(TCustomPersistent(objClone), TCustomPersistent(objSource), DecodeUTF8);
          end else if classe.InheritsFrom(TCollection) then begin
            TCustomPersistent.loadCollection(objClone, objSource, DecodeUtf8);
          end else if classe.InheritsFrom(TSortedCollection) then begin
            TCustomPersistent.loadSortedCollection(clone, source, DecodeUTF8);
          end;
        end else begin
          try
            TCustomPersistent.loadEntityField(clone, source, PropInfoClone, PropInfoSource, DecodeUTF8);
          except
            TCustomPersistent.loadEntityField(clone, source, PropInfoClone, PropInfoSource, DecodeUTF8);
          end;
        end;
      end;
    end;
  Result:=clone;
end;

class procedure TCustomPersistent.loadEntityField(clone, source: TCustomPersistent; PropInfoClone, PropInfoSource: PPropInfo; DecodeUTF8: boolean = false);
var int64Value: Int64;
  intValue: Integer;
  itemArray: TItemArray;
  dateValue: TDateTime;
  doubleValue: Double;
  strValue:String;
  boolValue: Boolean;
  variantValue: Variant;
  name: string;
  obj: TCustomPersistent;
begin
  obj:=clone;
    try
      name:=PropInfoClone.Name;
      if obj.InheritsFrom(TItemArray) then begin
        itemArray:=obj as TItemArray;
        itemArray.value:=variantValue;
      end else begin
        if GetTypeData(PropInfoSource^.PropType^)=GetTypeData(TypeInfo(TDateTime)) then begin
          if not VarIsNull(variantValue) then begin
            if TryStrToDateTime(variantValue, dateValue) then begin
              dateValue:=GetFloatProp(source, PropInfoSource);
              SetFloatProp(Obj,PropInfoClone,dateValue);
            end;
          end;
        end else if GetTypeData(PropInfoSource^.PropType^)=GetTypeData(TypeInfo(Boolean)) then begin
          if not VarIsNull(variantValue) then begin
            boolValue:=false;
            variantValue:=GetPropValue(source, PropInfoSource.Name);
            if not VarIsNull(variantValue) then begin
              boolValue:=variantValue;
              SetPropValue(clone, name, boolValue);
            end;                                   
          end;
        end else begin
          Case PropInfoSource.PropType^.Kind of
            tkInteger: begin
              if not VarIsNull(variantValue) then begin
                intValue:=GetOrdProp(source, PropInfoSource);
                SetOrdProp(clone,PropInfoClone,intValue);
              end;
            end;
            tkInt64: begin
              if not VarIsNull(variantValue) then begin
                int64Value:=GetInt64Prop(source, PropInfoSource);
                SetInt64Prop(clone,PropInfoClone,int64Value);
              end;
            end;
            tkFloat: begin
              if not VarIsNull(variantValue) then begin
                doubleValue:=GetFloatProp(source, PropInfoSource);
                setFloatProp(clone,PropInfoClone,doubleValue);
              end;
            end;
            tkUnknown,tkLString,tkWString,{$ifndef VER150} tkUString,{$endif}tkString,tkChar: begin
              if not VarIsNull(variantValue) then begin
                strValue:=GetStrProp(source, PropInfoSource);
                if DecodeUTF8 then begin
                  if UTF8Decode(variantValue)<>'' then begin
                    strValue:=UTF8Decode(variantValue);
                  end;
                end;
                SetStrProp(clone,PropInfoClone,strValue);
              end;
            end;
            tkVariant: begin
              variantValue:= GetVariantProp(source, PropInfoSource);
              if not VarIsNull(variantValue) then begin
                SetVariantProp(clone,PropInfoClone,variantValue);
              end;
            end;
            tkEnumeration: begin
              variantValue:= GetEnumProp(source, PropInfoSource);
              if not VarIsNull(variantValue) then begin
                strValue:=variantValue;
                SetEnumProp(clone,PropInfoClone,variantValue);
              end;
            end;
          end;
        end;
      end;
    except
      on e: exception do begin
        strValue:='';
        variantValue:= GetStrProp(source, PropInfoSource);
        if not VarIsNull(variantValue) then begin
          strValue:=variantValue;
        end;
        raise Exception.create('Objeto: ' + Obj.ClassName + '.' + name + ' - conteúdo: ' + strValue + #13#10 + 'Exception: ' + e.Message);
      end;
    end;
end;

class procedure TCustomPersistent.loadDateTimeObject(dateClone,dateSource: TObject);
var clone, source: TDateTimeObject;
begin
  source:=dateSource as TDateTimeObject;
  clone:=dateClone as TDateTimeObject;
  clone.assign(source);
end;

class procedure TCustomPersistent.loadStringList(cloneObj, sourceObj: TObject; DecodeUTF8: boolean);
var classType: TClassType;
  i: integer;
  attr: TCustomPersistent;
  obj: TObject;
  list, listResult: TStringList;
begin
  list:=TStringList(sourceObj);
  listResult:=TStringList(cloneObj);
  for i:=0 to List.Count-1 do begin
    obj:=List.Objects[i];
    attr:=classType.newInstance;
    TCustomPersistent.loadEntity(attr, TCustomPersistent(obj), DecodeUTF8);
    listResult.AddObject('',attr);
  end;
end;

class procedure TCustomPersistent.loadCollection(cloneObj, sourceObj: TObject; DecodeUTF8: boolean);
var classType: TClassType;
  i: integer;
  attr: TCustomPersistent;
  obj: TObject;
  list, listResult: TCollection;
begin
  list:=TCollection(sourceObj);
  classType:=list.getItemType;
  listResult:=TCollection(cloneObj);
  for i:=0 to List.Count-1 do begin
    obj:=List.GetItem(i);
    attr:=classType.newInstance;
    TCustomPersistent.loadEntity(attr, TCustomPersistent(obj), DecodeUTF8);
    listResult.Add(attr);
  end;
end;

class procedure TCustomPersistent.loadSortedCollection(cloneObj, sourceObj: TCustomPersistent; DecodeUTF8: boolean);
var classType: TClassType;
  i: integer;
  attr: TCustomPersistent;
  obj: TObject;
  list, listResult: TSortedCollection;
begin
  list:=TSortedCollection(sourceObj);
  classType:=list.getItemType;
  listResult:=TSortedCollection(cloneObj);
  for i:=0 to List.Count-1 do begin
    obj:=List.get(i);
    attr:=classType.newInstance;
    TCustomPersistent.loadEntity(attr, TCustomPersistent(obj), DecodeUTF8);
    listResult.Add(attr);
  end;
end;


end.
