unit XmlManager;

interface

uses
  xmldoc,
  XMLIntf,
  XmlDom,
  Contnrs,
  Classes,
  Variants,
  SerializableObjects,
  TypInfo,
  {$IFDEF VER150}
  Forms,
  {$ELSE}
  Vcl.Forms,
  {$ENDIF}
  DateHelper,
  SysUtils,
  MadExcept,
  REST_API;
  
type

  TXmlNodes = class(TCollection)

  public
  end;

  TXmlManager = class
  private
    class procedure serialize(List: TStringList; XML: IXMLNode); overload;
    class procedure serialize(List: TSortedCollection; XML: IXMLNode); overload;
    class procedure serialize(List: TObjectList; XML: IXMLNode); overload;
    class procedure serialize(owner: TCustomPersistent; PropInfo: PPropInfo; XML: IXMLNode); overload;
    class procedure serialize(itemArray: TItemArray; XML: IXMLNode); overload;
    class procedure loadEntity(XML: IXMLNode; Entity: TCustomPersistent; DecodeUTF8:boolean); overload;
    class procedure loadEntity(XML: IXMLNode; List: TStringList; DecodeUTF8:boolean); overload;
    class procedure loadEntityField(Obj: TCustomPersistent; PropInfo: PPropInfo; XmlNode: IXMLNode; DecodeUTF8:boolean);overload;
    class function getElementsByTagName(xmlNode: IXMLNode; tagName: string): TXmlNodes;
    class procedure exportXmlAtributes(XMLNode: IXMLNode; Entity: TCustomPersistent);
    class procedure loadXmlAtributes(XMLNode: IXMLNode; Entity: TCustomPersistent);
    class procedure processClass(owner: TCustomPersistent; PropInfo: PPropInfo; XmlNode: IXMLNode);
    class procedure loadStringList(fieldName: string; strList: TStringList; XML: IXMLNode; DecodeUTF8: boolean);
    class procedure loadCollection(fieldName: string; List: TCollection; XML: IXMLNode; DecodeUTF8: boolean);
    class procedure loadSortedCollection(fieldName: string; sortedList: TSortedCollection; XML: IXMLNode; DecodeUTF8: boolean);
    class procedure loadDateTimeObject(fieldName: string; dateTimeObject: TDateTimeObject; XML: IXMLNode);
    class function GetTextXmlNode(XmlNode: IXMLNode):Variant;
    class function createXmlDocument: TXMLDocument;
  public
    class function serialize(Entity: TCustomPersistent;Encoding:String='';DecimalSeparator:Char='.'): String; overload;
    class function deserialize(XML: string; classType: TclassType): TCustomPersistent; overload;
    class function deserialize(XML: string; classType: TclassType; DecodeUTF8:boolean): TCustomPersistent; overload;
    class function valueIsType(PropInfo: PPropInfo; type_info: PTypeInfo): boolean;
    class procedure setVendorName(name: string);
    class function getVendorName: string;
    class procedure saveToFile(fileName: string; Entity: TCustomPersistent);
    class procedure saveToStream(Stream: TStream; Entity: TCustomPersistent);
  end;


implementation

function getDecimalSeparator: char;
begin
  Result:={$ifndef VER150} FormatSettings.{$endif}DecimalSeparator;
end;

procedure SetDecimalSeparator(Value: char);
begin
  {$ifndef VER150}FormatSettings.{$endif}DecimalSeparator:=Value;
end;

function GetThousandSeparator: char;
begin
  Result:={$ifndef VER150} FormatSettings.{$endif}ThousandSeparator;
end;

procedure SetThousandSeparator(Value: char);
begin
  {$ifndef VER150} FormatSettings.{$endif}ThousandSeparator:=Value;
end;

class function TXmlManager.deserialize(XML: string; classType: TclassType): TCustomPersistent;
begin
  Result:=TXmlManager.deserialize(XML, classType, false);
end;

class function TXmlManager.deserialize(XML: string; classType: TclassType; DecodeUTF8:boolean): TCustomPersistent;
var obj: TCustomPersistent;
  xmlDoc: TXMLDocument;
  xmlNode: IXMLNode;
begin
  xmlDoc:=TXmlManager.createXmlDocument;
  xmlDoc.DOMVendor:=GetDOMVendor(TXmlManager.getVendorName);
  xmlDoc.Active:=true;
  xmlDoc.LoadFromXML(XML);
  xmlNode:=xmlDoc.DocumentElement;
  obj:=classType.newInstance;
  if assigned(xmlNode) then begin
    TXmlManager.loadXmlAtributes(xmlNode, obj);
    TXmlManager.loadEntity(xmlNode, obj, DecodeUTF8);
  end;
  xmlDoc.Free;              
  Result:=obj;
end;

class function TXmlManager.createXmlDocument: TXMLDocument;
begin
  {$IFDEF VER150}
  result:=TXMLDocument.Create(Application);
  {$ELSE}
  result:=TXMLDocument.Create(Vcl.Forms.Application);
  {$ENDIF}
end;

class function TXmlManager.serialize(Entity: TCustomPersistent;Encoding:String='';DecimalSeparator:Char='.'): String;
var NroProp, i:integer;
  ListProp:PPropList;
  info: PTypeInfo;
  data: PTypeData;
  PropInfo:PPropInfo;
  xmlNode: IXMLNode;
  xmlDoc: TXMLDocument;
  name: string;
  DecimalSep:Char;
begin
  DecimalSep:=GetDecimalSeparator;
  SetDecimalSeparator(DecimalSeparator);
  xmlDoc:=TXmlManager.createXmlDocument;
  xmlDoc.DOMVendor:=GetDOMVendor(TXmlManager.getVendorName);
  xmlDoc.Active:=true;
  if Encoding<>'' then begin
    xmlDoc.Encoding:=Encoding;
  end;
  name:=trim(Entity.name);
  if name='' then begin
    name:='object';
  end;
  xmlNode:=xmlDoc.AddChild(name);
  info:=Entity.ClassInfo;
  data:=GetTypeData(info);
  GetMem(ListProp, data^.PropCount * SizeOf(PPropInfo));
  NroProp:=GetPropList(info, tkAny, ListProp, false);
  try
    TXmlManager.exportXmlAtributes(xmlNode, Entity);
    for i:=0 to NroProp-1 do begin
      PropInfo:=GetPropInfo(Entity,ListProp[i].Name,tkAny);
      if Assigned(PropInfo) then begin
        TXmlManager.serialize(Entity, PropInfo, xmlNode);
      end;
    end;
  finally
     FreeMem(ListProp, data^.PropCount * SizeOf(PPropInfo));
  end;
  xmlDoc.saveToXml(Result);
  xmlDoc.Free;
  SetDecimalSeparator(DecimalSep);
end;

class function TXmlManager.valueIsType(PropInfo: PPropInfo; type_info: PTypeInfo): boolean;
begin
  result:=(GetTypeData(PropInfo.PropType^)^.BaseType^ = type_info);
end;

class procedure TXmlManager.processClass(owner: TCustomPersistent; PropInfo: PPropInfo; XmlNode: IXMLNode);
var  list: TObjectList;
  indexlist: TSortedCollection;
  strList: TStringList;
  classe: TClass;
  Obj: TCustomPersistent;
  dateTimeObject: TDateTimeObject;
  info: PTypeInfo;
  data: PTypeData;
  PropInfo2: PPropInfo;
  ListProp: PPropList;
  NroProp, i: integer;
begin
  classe:=GetObjectPropClass(owner, PropInfo); 
  if Assigned(classe) then begin
    if (not classe.InheritsFrom(TSortedCollection)) and classe.InheritsFrom(TStringList) then begin
      strList:=GetObjectProp(owner, PropInfo) as TStringList;
      TXmlManager.serialize(strList, XmlNode);
    end else if classe.InheritsFrom(TSortedCollection)  then begin
      indexlist:=GetObjectProp(owner, PropInfo) as TSortedCollection;
      TXmlManager.serialize(indexlist, XmlNode);
    end else if classe.InheritsFrom(TCollection)  then begin
      list:=GetObjectProp(owner, PropInfo) as TCollection;
      TXmlManager.serialize(list, XmlNode);
    end else if classe.InheritsFrom(TDateTimeObject) then begin
      dateTimeObject:=GetObjectProp(owner, PropInfo) as TDateTimeObject;
      XmlNode.NodeValue:=dateTimeObject.formatDateTime;
    end else if classe.InheritsFrom(TCustomPersistent) then begin
      Obj:=GetObjectProp(owner, PropInfo) as TCustomPersistent;
      TXmlManager.exportXmlAtributes(xmlNode, obj);
      info:=Obj.ClassInfo;
      data:=GetTypeData(info);
      GetMem(ListProp, data^.PropCount * SizeOf(PPropInfo));
      NroProp:=GetPropList(info, tkAny, ListProp, false);
      try
        for i:=0 to NroProp-1 do begin
          PropInfo2:=GetPropInfo(Obj,ListProp[i].Name,tkAny);
          if Assigned(PropInfo2) then begin
            TXmlManager.serialize(Obj, PropInfo2, XmlNode);
          end;
        end;
      finally
        FreeMem(ListProp, data^.PropCount * SizeOf(PPropInfo));
      end;
    end;
  end;
end;

class procedure TXmlManager.serialize(owner: TCustomPersistent; PropInfo: PPropInfo; XML: IXMLNode);
var int64Value: Int64;
  floatValue: Double;
  strValue: string;
  classe: TClass;
  intValue:integer;
  dateValue: TDateTime;
  list: TCollection;
  XmlNode: IXMLNode;
  boolValue: boolean;
  variantValue: variant;
  name: string;
begin
  if not owner.isExcludedField(PropInfo.Name) then begin
    XmlNode:=nil;
    name := owner.RenameFor(Propinfo.Name);
    if PropInfo.PropType^.Kind=tkClass then begin
      classe:=GetObjectPropClass(owner, PropInfo);
      if classe.InheritsFrom(TCollection) then begin
        list:=GetObjectProp(owner, PropInfo) as TCollection;
        if TCollection(list).getLevel=tl_Owner then begin
          XmlNode:=XML;
        end;
      end;
    end;
    if XmlNode=nil then begin
      XmlNode:=XML.AddChild(name);
    end;
    if GetTypeData(PropInfo^.PropType^)=GetTypeData(TypeInfo(TDateTime)) then begin
      dateValue:=GetFloatProp(owner,PropInfo);
      XmlNode.NodeValue:=dateValue;
    end else if GetTypeData(PropInfo^.PropType^)=GetTypeData(TypeInfo(Boolean)) then begin
      boolValue:=false;
      if not VarIsNull(variantValue) then begin
        boolValue:=variantValue;
      end;
      XmlNode.NodeValue:=boolValue;
    end else begin
      Case PropInfo.PropType^.Kind of
        tkInteger: begin
          intValue:=GetOrdProp(owner,PropInfo);
          XmlNode.NodeValue:=intValue;
        end;
        tkInt64: begin
          int64Value:=GetInt64Prop(owner, PropInfo);
          XmlNode.NodeValue:=int64Value;
        end;
        tkFloat: begin
          floatValue:=GetFloatProp(owner, PropInfo);
          XmlNode.NodeValue:=FormatFloat(owner.getDecimalFormat(name), floatValue);
        end;
        {$IFDEF VER150}
        tkUnknown,tkLString,tkWString,tkString,tkChar: begin
        {$ELSE}
        tkUnknown,tkLString,tkWString,tkString,tkChar,tkUString: begin
        {$ENDIF}
          strValue:=GetStrProp(owner,PropInfo);
          XmlNode.NodeValue:=strValue;
        end;
        tkVariant: begin
          XmlNode.NodeValue:=GetVariantProp(owner, PropInfo);
        end;
        tkClass: begin
          TXmlManager.processClass(owner, PropInfo, XmlNode);
        end;
      end;
    end;
  end;
end;

class procedure TXmlManager.serialize(List: TSortedCollection; XML: IXMLNode);
var xmlNode: IXMLNode;
  obj: TCustomPersistent;
  itemArray: TItemArray;
  info: PTypeInfo;
  data: PTypeData;
  i, j: integer;
  NroProp:integer;
  ListProp:PPropList;
  PropInfo: PPropInfo;
  name: string;
begin
  for i:=0 to list.Count - 1 do begin
    obj:=List.get(i) as TCustomPersistent;
    name:=List[i];
    if obj.InheritsFrom(TItemArray) then begin
      itemArray:=obj as TItemArray;
      TXmlManager.serialize(itemArray, xmlNode);//Revisar
    end else begin
      xmlNode:=XML.AddChild(name);
      info:=obj.ClassInfo;
      data:=GetTypeData(info);
      GetMem(ListProp, data^.PropCount * SizeOf(PPropInfo));
      NroProp:=GetPropList(info, tkAny, ListProp, false);
      try
        for j:=0 to NroProp-1 do begin
          PropInfo:=GetPropInfo(Obj,ListProp[j].Name,tkAny);
          if Assigned(PropInfo) then begin
            TXmlManager.serialize(Obj, PropInfo, xmlNode);
          end;
        end;
      finally
        FreeMem(ListProp, data^.PropCount * SizeOf(PPropInfo));
      end;
    end;
  end;
end;

class procedure TXmlManager.serialize(List: TStringList; XML: IXMLNode);
var item: string;
  i: integer;
  xmlNode: IXMLNode;
begin
  for i:=0 to list.Count - 1 do begin
    item:=List[i];
    xmlNode:=XML.AddChild('item');
    xmlNode.NodeValue:=item;
  end;
end;

class function TXmlManager.GetTextXmlNode(XmlNode: IXMLNode):Variant;
var PosIni,PosFim,Tam:Integer;
begin
  PosIni:=Pos('>',XmlNode.XML)+1;
  PosFim:=LastDelimiter('<',XmlNode.XML)-1;
  Tam:=Length(XmlNode.XML);
  PosFim:=Tam-PosIni-(Tam-PosFim)+1;
  Result:=Copy(XmlNode.XML,PosIni,PosFim);
end;

class procedure TXmlManager.loadEntityField(Obj: TCustomPersistent; PropInfo: PPropInfo; xmlNode: IXMLNode; DecodeUTF8:boolean);
var int64Value: Int64;
  itemArray: TItemArray;
  strValue:String;
  variantValue: Variant;
  doubleValue: Double;
begin
  if XmlNode<>nil then begin
    try
      variantValue:=XmlNode.NodeValue;
    except
      variantValue:=TXmlManager.GetTextXmlNode(XmlNode);
    end;
    if obj.InheritsFrom(TItemArray) then begin
      itemArray:=obj as TItemArray;
      itemArray.value:=variantValue;
    end else begin
      if GetTypeData(PropInfo^.PropType^)=GetTypeData(TypeInfo(TDateTime)) then begin
        if not VarIsNull(variantValue) then begin
          SetFloatProp(Obj,PropInfo,variantValue);
        end;
      end else if GetTypeData(PropInfo^.PropType^)=GetTypeData(TypeInfo(Boolean)) then begin
        if not VarIsNull(variantValue) then begin
          SetPropValue(Obj,PropInfo.Name,StrToBool(variantValue));
        end;
      end else begin
        Case PropInfo.PropType^.Kind of
          tkInteger: begin
            if not VarIsNull(variantValue) then begin
              SetOrdProp(Obj,PropInfo,variantValue);
            end;
          end;
          tkInt64: begin
            if not VarIsNull(variantValue) then begin
              if variantValue='.' then variantValue:=0; //FA11861 - 03/12/21
              int64Value:=variantValue;
              SetInt64Prop(Obj,PropInfo,int64Value);
            end;
          end;
          tkFloat: begin
            if not VarIsNull(variantValue) then begin
              variantValue:=StringReplace(variantValue,'.',getDecimalSeparator,[rfReplaceAll]);
              if TryStrToFloat(variantValue, doubleValue) then begin
                setFloatProp(Obj,PropInfo,doubleValue);
              end;
            end;
          end;
          {$IFDEF VER150}
          tkUnknown,tkLString,tkWString,tkString,tkChar: begin
          {$ELSE}
          tkUnknown,tkLString,tkWString,tkString,tkChar,tkUString: begin
          {$ENDIF}
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
        end;
      end;
    end;
  end;
end;

class procedure TXmlManager.loadEntity(Xml: IXMLNode; List: TStringList; DecodeUTF8:boolean);
var i: integer;
  item: string;
begin
  for i:=0 to XML.ChildNodes.Count -1 do begin
    item:=XML.ChildNodes[i].NodeValue;
    List.Add(item);
  end;
end;

class function TXmlManager.getElementsByTagName(xmlNode: IXMLNode; tagName: string): TXmlNodes;
var Nodes: TXmlNodes;
  i: integer;
  node: IXMLNode;
begin
  Nodes:=TXmlNodes.create(TCustomPersistent, false);
  for i:=0 to xmlNode.ChildNodes.Count - 1 do begin
    node:=xmlNode.ChildNodes.Get(i);
    if IXmlNode(node).NodeName=tagName then begin
      nodes.Add(TXmlNode(node));
    end;
  end;
  Result:=Nodes;
end;

class procedure TXmlManager.loadXmlAtributes(XMLNode: IXMLNode; Entity: TCustomPersistent);
var i: integer;
  attributes: THashMap;
  attribute: IXmlNode;
  PropInfo:PPropInfo;
begin
  PropInfo:=GetPropInfo(Entity,'attributes',tkAny);
  if PropInfo<> nil then begin
    attributes:=THashMap(GetObjectProp(Entity, PropInfo));
    if (attributes<>nil) and (XMLNode<>nil) then begin
      for i:=0 to XMLNode.AttributeNodes.Count - 1 do begin
        attribute:=XMLNode.AttributeNodes.Get(i);
        attributes.setAttribute(attribute.NodeName, attribute.NodeValue);
      end;
    end;
  end;
end;

class  procedure TXmlManager.exportXmlAtributes(XMLNode: IXMLNode; Entity: TCustomPersistent);
var i: integer;
  attributes: THashMap;
  name: string;
  PropInfo:PPropInfo;
begin
  PropInfo:=GetPropInfo(Entity,'attributes',tkAny);
  if PropInfo<> nil then begin
    attributes:=THashMap(GetObjectProp(Entity, PropInfo));
    if (attributes<>nil) and (XMLNode<>nil) then begin
      for i:=0 to attributes.count - 1 do begin
        name:=attributes.getName(i);
        XMLNode.Attributes[name]:=attributes.getAttribute(name);
      end;
    end;
  end;
end;

class procedure TXmlManager.loadCollection(fieldName: string; List: TCollection; XML: IXMLNode; DecodeUTF8: boolean);
var classType: TClassType;
  nodes: TXmlNodes;
  child: IXmlNode;
  i, j: integer;
  xmlNodeList: IXMLNode;
  attr: TCustomPersistent;
begin
  classType:=list.getItemType;
  if TCollection(list).getLevel=tl_self then begin
    nodes:=TXmlNodes.create(TCustomPersistent, false);
    child:=XML.ChildNodes.FindNode(fieldName);
    if child<>nil then begin
      nodes.Add(TXmlNode(child));
    end;
  end else begin
    nodes:=TXmlManager.getElementsByTagName(XML, list.name);
  end;
  for i:=0 to nodes.Count - 1 do begin
    {$IFDEF VER150}
    xmlNodeList:=IXmlNode(nodes.get(i));
    {$ELSE}
    xmlNodeList:=IXmlNode(TXMLNode(nodes.get(i)));
    {$ENDIF}
    if list.getLevel=tl_Self then begin
      for j:=0 to xmlNodeList.ChildNodes.Count - 1 do begin
        attr:=classType.newInstance;
        child:=xmlNodeList.ChildNodes[j];
        if list.getLevel=tl_Self then begin
          attr.name:=child.NodeName;
        end else begin
          attr.name:=list.name;
        end;
        TXmlManager.loadXmlAtributes(child, attr);
        TXmlManager.loadEntity(child, attr, DecodeUTF8);
        list.Add(attr);
      end;
    end else begin
      attr:=classType.newInstance;
      child:=xmlNodeList;
      if list.getLevel=tl_Self then begin
        attr.name:=child.NodeName;
      end else begin
        attr.name:=list.name;
      end;
      TXmlManager.loadXmlAtributes(child, attr);
      TXmlManager.loadEntity(child, attr, DecodeUTF8);
      list.Add(attr);
    end;
  end;
  nodes.Free;
end;

class procedure TXmlManager.loadDateTimeObject(fieldName: string; dateTimeObject: TDateTimeObject; XML: IXMLNode);
var child: IXMLNode;
begin
  child:=XML.ChildNodes.FindNode(fieldName);
  if child<>nil then begin
    dateTimeObject.loadFrom(child.NodeValue);
  end;
end;

class procedure TXmlManager.loadSortedCollection(fieldName: string; sortedList: TSortedCollection; XML: IXMLNode; DecodeUTF8: boolean);
var classType: TclassType;
  xmlNodeList, child: IXMLNode;
  i: integer;
  attr: TCustomPersistent;
begin
  classType:=sortedList.getItemType;
  child:=XML.ChildNodes.FindNode(fieldName);
  if child<>nil then begin
    xmlNodeList:=child;
    for i:=0 to xmlNodeList.ChildNodes.Count - 1 do begin
      attr:=classType.newInstance;
      child:=xmlNodeList.ChildNodes[i];
      TXmlManager.loadXmlAtributes(child, attr);
      TXmlManager.loadEntity(child, attr, DecodeUTF8);
      sortedList.add(attr);
    end;
  end;
end;

class procedure TXmlManager.loadStringList(fieldName: string; strList: TStringList; XML: IXMLNode; DecodeUTF8: boolean);
var child: IXMLNode;
begin
  child:=XML.ChildNodes.FindNode(fieldName);
  if child<>nil then begin
    TXmlManager.loadEntity(child, strList, DecodeUTF8);
  end;
end;

class procedure TXmlManager.loadEntity(XML: IXMLNode; Entity: TCustomPersistent; DecodeUTF8:boolean);
var obj:TObject;
  NroProp, i:integer;
  ListProp:PPropList;
  info: PTypeInfo;
  data: PTypeData;
  PropInfo:PPropInfo;
  fieldName, nameSpaceURI:String;
  classe: TClass;
  field: TCustomPersistent;
  list: TCollection;
  sortedList: TSortedCollection;
  strList: TStringList;
  xmlNode, child: IXMLNode;
  dateTimeObject: TDateTimeObject;
begin
  if (XML<>nil) then begin
    xmlNode:=XML;
    info:=Entity.ClassInfo;
    data:=GetTypeData(info);
    GetMem(ListProp, data^.PropCount * SizeOf(PPropInfo));
    NroProp:=GetPropList(info, tkAny, ListProp, false);
    try
      try
        for i:=0 to NroProp-1 do begin
          fieldName:=Entity.RenameFor(ListProp[i].Name);
          if not Entity.isExcludedField(ListProp[i].Name) then begin
            PropInfo:=GetPropInfo(Entity,ListProp[i].Name,tkAny);
            if Assigned(PropInfo) then begin
              classe:=GetObjectPropClass(PropInfo);
              obj:=GetObjectProp(Entity, PropInfo);
              if Assigned(obj) and (PropInfo.PropType^.Kind=tkClass) then begin
                if (not classe.InheritsFrom(TSortedCollection)) and classe.InheritsFrom(TStringList)  then begin
                  strList:=obj as TStringList;
                  TXmlManager.loadStringList(fieldName, strList, XML, DecodeUTF8);
                end else if obj.InheritsFrom(TDateTimeObject) then begin
                  dateTimeObject:=obj as TDateTimeObject;
                  TXmlManager.loadDateTimeObject(fieldName, dateTimeObject, XML);
                end else if classe.InheritsFrom(TCustomPersistent) then begin
                  field:=obj as TCustomPersistent;
                  nameSpaceURI:=field.getNameSpaceURI;
                  if nameSpaceURI<>'' then begin
                    child:=XML.ChildNodes.FindNode(fieldName,nameSpaceURI);
                  end else begin
                    child:=XML.ChildNodes.FindNode(fieldName);
                  end;
                  if child<>nil then begin
                    TXmlManager.loadXmlAtributes(child, field);
                    TXmlManager.loadEntity(child, field, DecodeUTF8);
                  end;
                end else if classe.InheritsFrom(TCollection) then begin
                  list:=obj as TCollection;
                  TXmlManager.loadCollection(fieldName, list, XML, DecodeUTF8);
                end else if classe.InheritsFrom(TSortedCollection) then begin
                  sortedList:=obj as TSortedCollection;
                  TXmlManager.loadSortedCollection(fieldName, sortedList, XML, DecodeUTF8);
                end;
              end else if PropInfo.PropType^.Kind<>tkClass  then begin
                child:=XML.ChildNodes.FindNode(fieldName);
                if child<>nil then begin
                  TXmlManager.loadEntityField(Entity, PropInfo, child, DecodeUTF8);
                end;
              end;
            end;
          end;
        end;
      except
        on e: Exception do begin
          raise Exception.Create('Erro o processar o atributo "' + fieldName+'"; Erro: ' + e.Message + ';Stack: ' + MadExcept.GetCrashStackTrace);
        end;
      end;
    finally
      FreeMem(ListProp, data^.PropCount * SizeOf(PPropInfo));
    end;
  end;
end;

class procedure TXmlManager.serialize(itemArray: TItemArray; XML: IXMLNode);
var int64Value: Int64;
  floatValue: Double;
  strValue: string;
  intValue:integer;
  xmlNode: IXMLNode;
begin
  xmlNode:=xml.AddChild('item');
  if VarIsType(itemArray.value, varInteger) then begin
    intValue:=itemArray.value;
    xmlNode.NodeValue:=intValue;
  end else if varIsType(ItemArray.value, varInt64) then begin
    int64Value:=itemArray.value;
    xmlNode.NodeValue:=int64Value;
  end else if varIsType(ItemArray.value, varDouble) then begin
    floatValue:=itemArray.value;
    xmlNode.NodeValue:=floatValue;
  end else if varIsType(ItemArray.value, varString) or varIsType(ItemArray.value, varOleStr) or varIsType(ItemArray.value, varStrArg) then begin
    strValue:=itemArray.value;
    xmlNode.NodeValue:=strValue;
  end else begin
    strValue:=itemArray.value;
    xmlNode.NodeValue:=strValue;
    // Revisar
  end;
end;

class procedure TXmlManager.serialize(List: TObjectList; XML: IXMLNode);
var xmlNode: IXMLNode;
  obj: TCustomPersistent;
  itemArray: TItemArray;
  i, j: integer;
  NroProp:integer;
  ListProp:PPropList;
  info: PTypeInfo;
  data: PTypeData;
  PropInfo: PPropInfo;
  name: string;
begin
  for i:=0 to list.Count - 1 do begin
    obj:=list[i] as TCustomPersistent;
    if obj.InheritsFrom(TItemArray) then begin
      itemArray:=obj as TItemArray;
      TXmlManager.serialize(itemArray, XML);
    end else begin
      info:=Obj.ClassInfo;
      data:=GetTypeData(info);
      GetMem(ListProp, data^.PropCount * SizeOf(PPropInfo));
      NroProp:=GetPropList(info, tkAny, ListProp, false);
      try
        name:=trim(Obj.name);
        if name='' then begin
          name:='object';
        end;
        xmlNode:=XML.AddChild(name);
        TXmlManager.exportXmlAtributes(xmlNode, obj);
        for j:=0 to NroProp-1 do begin
          PropInfo:=GetPropInfo(Obj,ListProp[j].Name,tkAny);
          if Assigned(PropInfo) then begin
            TXmlManager.serialize(Obj, PropInfo, xmlNode);
          end;
        end;
      finally
        FreeMem(ListProp, data^.PropCount * SizeOf(PPropInfo));
      end;
    end;
  end;
end;

var vendorName: string = 'OXml';
class procedure TXmlManager.setVendorName(name: string);
begin
  vendorName:=name;
end;

class function TXmlManager.getVendorName: string;
begin
  Result:=vendorName;
end;

class procedure TXmlManager.saveToFile(fileName: string; Entity: TCustomPersistent);
var stream: TMemoryStream;
begin
  stream:=TMemoryStream.Create;
  TXmlManager.saveToStream(stream, Entity);
  stream.SaveToFile(fileName);
  stream.Free;
end;

class procedure TXmlManager.saveToStream(Stream: TStream;  Entity: TCustomPersistent);
var xml: string;
  StrStream: TStringStream;
  ms: TMemoryStream;
begin
  xml:=TXmlManager.serialize(Entity);
  ms:=TMemoryStream.create;
  StrStream:=TStringStream.Create(xml);
  StrStream.Position:=0;
  ms.LoadFromStream(StrStream);
  StrStream.Free;
  ms.Position:=0;
  ms.SaveToStream(Stream);
  ms.free;
end;

end.
