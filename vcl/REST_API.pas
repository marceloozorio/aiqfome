unit REST_API;

interface

uses
  classes,
  SysUtils,
  StrUtils,
  Variants,
  HttpSend,
  synautil,
  ssl_openSsl,
  ContNrs,
  SynaCode,
  BlckSock,
  IdHashMessageDigest,
  IdHash,
  DateUtils,
  SerializableObjects;

type

  HttpMethodType = (hmGet, hmPost, hmPut, hmDelete);
  HttpProtocol = (http_1_0, http_1_1);
  HttpContentType = (application_json, application_xml, text_plain, text_xml, type_none, application_soap_xml_charset_utf8, multiPart_Form_Data);
  


  THashMapBase = class(TStringList)
  protected
    function CompareStrings(const s1,s2:String):Integer;override;
  public
    constructor Create;
  end;


  THashMap = class
  private
    Items: THashMapBase;
  public
    constructor create;
    destructor destroy; override;
    procedure setAttribute(name, value: string);
    function getAttribute(name: string): string;
    function getName(index: Integer): string;
    function count: integer;
    procedure clear;
    function get(index: Integer): TItemArray; overload;
    function get(name: string): TItemArray; overload;
  end;

  THash = class
  public
    class function MD5FromString(value: string): string;
    class function MD5FromStream(value: TStream): string;
    class function MD5FromFile(const fileName : string) : string;
  end;


 THttpResponse = class
  public
    content: TMemoryStream;
    code: integer;
    Error: string;
    constructor create;
    destructor destroy; override;
    procedure assign(source: THttpResponse);
    function contentToString: string;
    function hasError: boolean;
  end;

  THttpError = class(Exception)
  private

  public
    response: THttpResponse;
    constructor create(msg: string; response: THttpResponse);
    destructor destroy; override; 
  end;

  THttpClient = class
  private
    procedure processSettings(SynHttp: THTTPSend);
    function httpMethod(url: string; data: TStream; method: HttpMethodType): THttpResponse;
    class function convert(contentType: HttpContentType; boundary: string): string;
  public
    userName: string;
    password: string;
    proxyHost: string;
    proxyPort: string;
    proxyUser: string;
    proxyPassword: string;
    boundary: string;
    CertificateFile: string;
    PFXfile: string;
    TrustCertificateFile: string;
    useCertificate: boolean;
    keyPassword: string;
    protocolVersion: HttpProtocol;
    timeout: integer;
    MimeType: HttpContentType;
    Headers: TStringList;
    Cookies: TStringList;
    useSSL: boolean;
    KeepAlive:Boolean;
    constructor create;
    destructor destroy; override;
    function httpPost(url, data: string): THttpResponse; overload;
    function httpPost(url: string; data: TStream): THttpResponse; overload;
    function httpGet(url: string): THttpResponse;
    function httpPut(url: string; data: TStream): THttpResponse; overload;
    function httpPut(url, data: string): THttpResponse; overload;
    function httpDelete(url: string; data:String=''): THttpResponse;
  end;

type
   TTMultPart=record
      Key,Value:String;
end;

type
  TMultPartFormData = class
  private
     ListMultPart:TList;
     PMultPart:^TTMultPart;
  public
     constructor Create;
     destructor Destroy; override;

     procedure AddMultiPartTextValue(key:String; value:String);

     function Build(httpClient: THttpClient):String;
  end;

  implementation


{ THttpResponse }

constructor THttpResponse.create;
begin
  inherited;
  self.content:=TMemoryStream.create;
end;

destructor THttpResponse.destroy;
begin
  self.content.free;
  inherited;
end;

procedure THttpResponse.assign(source: THttpResponse);
begin
  self.content.LoadFromStream(source.content);
  self.code:=source.code;
end;

function THttpResponse.contentToString: string;
var strData: TStringStream;
begin
  strData:=TStringStream.Create('');
  self.content.Position:=0;
  self.content.SaveToStream(strData);
  Result:=strData.DataString;
  strData.Free;
end;

function THttpResponse.hasError: boolean;
begin
  result:=(Error<>'');
end;

{ THttpError }

constructor THttpError.create(msg: string; response: THttpResponse);
begin
  inherited create(msg);
  self.response:=response;
end;


destructor THttpError.destroy;
begin
  self.response.Free;
  inherited;
end;

{ THttpClient }

constructor THttpClient.create;
begin
  inherited;
  self.protocolVersion:=http_1_1;
  self.useSSL:=false;
  self.useCertificate:=false;
  self.userName:='';
  self.password:='';
  self.proxyHost:='';
  self.proxyPort:='';
  self.proxyUser:='';
  self.proxyPassword:='';
  self.keyPassword:='';
  self.TrustCertificateFile:='';
  self.CertificateFile:='';
  self.PFXfile:='';
  self.timeout:=10;
  self.MimeType:=type_none;
  self.Headers:=TStringList.Create;
  self.Cookies:=TStringList.Create;
  self.boundary:='X-RPINFO-BOUNDARY';
  self.KeepAlive:=True;
end;


destructor THttpClient.destroy;
begin
  self.Headers.Free;
  self.Cookies.Free;
  inherited;
end;

function THttpClient.httpPut(url: string; data: TStream): THttpResponse;
begin
  Result:=self.httpMethod(url, data, hmPut);
end;

function THttpClient.httpPut(url, data: string): THttpResponse;
var dataStream: TStringStream;
begin
  dataStream:=TStringStream.Create(data);
  Result:=self.httpMethod(url, dataStream, hmPut);
  dataStream.Free;
end;

function THttpClient.httpDelete(url: string; data: string=''): THttpResponse;
var dataStream: TStringStream;
begin
  if data<>'' then begin
    dataStream:=TStringStream.Create(data);
    Result:=self.httpMethod(url, dataStream, hmDelete);
    dataStream.Free;
  end else begin
    Result:=Self.httpMethod(url, nil, hmDelete);
  end;
end;

function THttpClient.httpPost(url: string; data: TStream): THttpResponse;
begin
  Result:=self.httpMethod(url, data, hmPost);  
end;

function THttpClient.httpPost(url, data: string): THttpResponse;
var dataStream: TStringStream;
begin
  dataStream:=TStringStream.Create(data);
  Result:=self.httpMethod(url, dataStream, hmPost);
  dataStream.Free;
end;

class function THttpClient.convert(contentType: HttpContentType; boundary: string): string;
begin
  Result:='';
  if contentType=application_json then begin
    Result:='application/json';
  end else if contentType=application_xml then begin
    Result:='application/xml';
  end else if contentType=text_plain then begin
    Result:='text/plain';
  end else if contentType=text_xml then begin
    Result:='text/xml';
  end else if contentType=application_soap_xml_charset_utf8 then begin
    Result:='application/soap+xml; charset=utf-8';
  end else if contentType=multiPart_Form_Data then begin
    Result:='multipart/form-data; boundary=' + boundary;
  end;
end;

procedure THttpClient.processSettings(SynHttp: THTTPSend);
var i: integer;
begin
  if self.protocolVersion=http_1_0 then begin
    SynHttp.Protocol:='1.0';
  end else if self.protocolVersion=http_1_1 then begin
    SynHttp.Protocol:='1.1';
  end;
  if trim(self.userName)<>'' then begin
    SynHttp.UserName:=self.userName;
  end;
  if trim(self.password)<>'' then begin
    SynHttp.Password:=self.password;
  end;
  if self.timeout>0 then begin
    SynHttp.Timeout:=self.timeout;
  end;
  SynHttp.MimeType:='';
  if self.MimeType<>type_none then begin
    SynHttp.MimeType:=THttpClient.convert(self.MimeType, self.boundary);
  end;
  for i:=0 to self.Headers.Count-1 do begin
    SynHttp.Headers.Add(self.Headers[i]);
  end;
  if self.useCertificate then begin
    if trim(self.CertificateFile)<>'' then begin
      SynHTTP.Sock.SSL.CertificateFile:=self.CertificateFile;
    end;
    if trim(self.PFXfile)<>'' then begin
      SynHTTP.Sock.SSL.PFXfile:=self.PFXfile;
    end;
    if trim(self.TrustCertificateFile)<>'' then begin
      SynHTTP.Sock.SSL.TrustCertificateFile:=self.TrustCertificateFile;
    end;
    SynHttp.Sock.SSL.KeyPassword:=self.keyPassword;
  end;
  if trim(self.proxyHost)<>'' then begin
    SynHttp.ProxyHost:=self.proxyHost;
  end;
  if trim(self.proxyPort)<>'' then begin
    SynHttp.ProxyPort:=self.proxyPort;
  end;
  if trim(self.proxyUser)<>'' then begin
    SynHttp.proxyUser:=self.proxyUser;
  end;
  if trim(self.proxyPassword)<>'' then begin
    SynHttp.ProxyPass:=self.proxyPassword;
  end;
  SynHttp.KeepAlive:=KeepAlive;
  SynHTTP.Sock.CloseSocket;
end;

function THttpClient.httpMethod(url: string; data: TStream; method: HttpMethodType): THttpResponse;
var tipo: string;
  SynHttp: THTTPSend;
begin
  tipo:='GET';
  if method=hmPost then begin
    tipo:='POST';
  end else if method=hmPut then begin
    tipo:='PUT';
  end else if method=hmDelete then begin
    tipo:='DELETE';
  end;
  Result:=THttpResponse.create;
  SSLImplementation:=TSSLOpenSSL;
  SynHTTP:=THTTPSend.Create;
  if self.Cookies.Count>0 then begin
    SynHttp.Cookies.Assign(self.Cookies);
  end;
  self.processSettings(SynHttp);
  if self.useSSL then begin
     SynHttp.Sock.CreateWithSSL(TSSLOpenSSL);
  end;
  SynHTTP.Sock.SSLDoConnect;
  if data<>nil then begin
    SynHTTP.Document.LoadFromStream(data);
  end;
  url:=EncodeURL(url);
  if not SynHTTP.HTTPMethod(tipo, url) then begin
    // Result.content.
    Result.Error:='Não foi possivel conectar no endereço ' + url;
  end else begin
    Result.code:=SynHTTP.ResultCode;
    SynHTTP.Document.SaveToStream(Result.content);
    Result.content.Position:=0;
  end;
  self.Cookies.Assign(SynHttp.Cookies);
  synHTTP.Free;
end;

function THttpClient.httpGet(url: string): THttpResponse;
begin
  Result:=self.httpMethod(url, nil, hmGet);
end;

{ THash }

class function THash.MD5FromFile(const fileName : string) : string;
var fs : TFileStream;
begin
  fs := TFileStream.Create(fileName, fmOpenRead OR fmShareDenyWrite) ;
  try
    Result:=THash.MD5FromStream(fs);
  finally
    fs.Free;
  end;
end;

class function THash.MD5FromString(value: string) : string;
var str: TStringStream;
begin
  str:=TStringStream.Create(value);
  try
    Result:=THash.MD5FromStream(str);
  finally
    str.Free;
  end;
end;


class function THash.MD5FromStream(value: TStream) : string;
var idmd5 : TIdHashMessageDigest5;
begin
  value.Position:=0;
  idmd5 := TIdHashMessageDigest5.Create;
  try
    {$IFDEF VER150}
    result := idmd5.AsHex(idmd5.HashValue(value)) ;
    {$ELSE IF}
    result := idmd5.HashStreamAsHex(value) ;
    {$ENDIF}
  finally
    idmd5.Free;
  end;
end;




{ THashMap }

procedure THashMap.clear;
var i: integer;
  item: TItemArray;
begin
  for i:=0 to self.Items.Count - 1 do begin
    item:=self.items.objects[i] as TItemArray;
    item.Free;
  end;
  self.Items.Clear;
end;

function THashMap.count: integer;
begin
  Result:=self.Items.Count;
end;

constructor THashMap.create;
begin
  inherited;
  self.Items:=THashMapBase.Create;
  self.Items.Sorted:=true;
end;

destructor THashMap.destroy;
begin
  Self.clear;
  self.Items.Free;
  inherited;
end;

function THashMap.get(index: Integer): TItemArray;
begin
  Result:=self.items.objects[index] as TItemArray;
end;

function THashMap.get(name: string): TItemArray;
var index: integer;
begin
  Result:=nil;
  if self.Items.Find(name, index) then begin
    Result:=self.items.objects[index] as TItemArray;    
  end;
end;

function THashMap.getAttribute(name: string): string;
var item: TItemArray;
begin
  Result:='';
  item:=self.get(name);
  if item<>nil then begin
    Result:=item.value;
  end;
end;

function THashMap.getName(index: Integer): string;
begin
  Result:=self.get(index).name;  
end;

procedure THashMap.setAttribute(name, value: string);
var item: TItemArray;
begin
  item:=self.get(name);
  if item=nil then begin
    item:=TItemArray.create(value);
    item.name:=name;
    self.Items.AddObject(name, item);
  end;
  item.value:=value;
end;

{ THashMapBase }

constructor THashMapBase.Create;
begin
  inherited;
  CaseSensitive:=true;//seta por padrão CaseSensitive=true pois ele é a opção mais rápida de comparação de dados
end;

function THashMapBase.CompareStrings(const s1,s2:String):Integer;
begin
  if CaseSensitive then begin
     //a comparação direta aqui é ainda mais rápida que utilizar CompareStr (redução de aproximadamente 45% do tempo de execução)
     if s1<s2 then Result:=-1
     else if s1>s2 then Result:=1
     else Result:=0;
  end else begin
     Result:=CompareText(s1,s2);
  end;
end;

{ TMultPartFormData }

procedure TMultPartFormData.AddMultiPartTextValue(key, value: String);
begin
   new(PMultPart);
   PMultPart^.Key:=Key;
   PMultPart^.Value:=Value;
   ListMultPart.Add(PMultPart);
end;

function TMultPartFormData.Build(httpClient: THttpClient):String;
var i: integer;
    boundary:String;
begin
   Result:='';
   boundary:=httpClient.boundary;
   if boundary<>'' then begin
      for i:=0 to ListMultPart.Count-1 do begin
          PMultPart:= ListMultPart.Items[i];
          if (Trim(PMultPart^.Key)<>'') and (Trim(PMultPart^.Value)<>'') then begin
             Result:=Result+'--'+boundary+#13+#10;
             Result:=Result+'Content-Disposition: form-data; name="'+PMultPart^.Key+'"'+#13+#10;
             Result:=Result+#13+#10;
             Result:=Result+PMultPart^.Value+#13+#10;
          end;
      end;
      if Result<>'' then begin
         Result:=Result+'--'+boundary+'--'+#13+#10;
      end;
   end;
end;

constructor TMultPartFormData.Create;
begin
   ListMultPart:=TList.Create;
end;

destructor TMultPartFormData.Destroy;
var i: integer;
begin
   for i:=0 to ListMultPart.Count-1 do begin
       PMultPart:= ListMultPart.Items[i];
       Dispose(PMultPart);
   end;
   ListMultPart.Clear; ListMultPart.Free;
   inherited;
end;

end.
