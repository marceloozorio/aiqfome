program Project1;

uses
  Vcl.Forms,
  aiqfome in 'aiqfome.pas' {Form1},
  HttpSend in 'vcl/HttpSend.pas' {HttpSend},
  ssl_openssl_lib in 'vcl/ssl_openssl_lib.pas' {ssl_openssl_lib},
  ssl_openssl in 'vcl/ssl_openssl.pas' {ssl_openssl},
  synsock in 'vcl/synsock.pas' {synsock},
  synacode in 'vcl/synacode.pas' {synacode},
  synafpc in 'vcl/synafpc.pas' {synafpc},
  synautil in 'vcl/synautil.pas' {synautil},
  synaip in 'vcl/synaip.pas' {synaip},
  blcksock in 'vcl/blcksock.pas' {blcksock},
  REST_API in 'vcl/REST_API.pas' {REST_API},
  XmlManager in 'vcl/XmlManager.pas' {XmlManager},
  uJson in 'vcl/uJson.pas' {uJson},
  StringFunctions in 'vcl/StringFunctions.pas' {StringFunctions},
  DateHelper in 'vcl/DateHelper.pas' {DateHelper},
  SerializableObjects in 'vcl/SerializableObjects.pas' {SerializableObjects},
  JsonManager in 'vcl/JsonManager.pas' {JsonManager};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
