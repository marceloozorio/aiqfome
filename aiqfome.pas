unit aiqfome;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, SerializableObjects, REST_API,
  JsonManager, System.ImageList, Vcl.ImgList, CommCtrl, Vcl.Imaging.pngimage,
  Vcl.Grids;

type
  TFamilyPokemon = class(TCustomPersistent)
  public
    FID: integer;
    FEvolutionStage: integer;
    FEvolutionLine: TStringList;
    constructor create;
    class function newInstance: TCustomPersistent;override;
  published
    property id: integer read FID write FID;
    property evolutionStage: integer read FEvolutionStage write FEvolutionStage;
    property evolutionLine: TStringList read FEvolutionLine write FEvolutionLine;
  end;

  TAbilitiesPokemon = class(TCustomPersistent)
  public
    FNormal: TStringList;
    FHidden: TStringList;

    constructor create;
    class function newInstance: TCustomPersistent; override;
  published
    property normal: TStringList read FNormal write FNormal;
    property hidden: TStringList read FHidden write FHidden;
  end;

  TPokemon = class(TCustomPersistent)
  public
    FNumber: integer;
    FName: string;
    FSpecies: string;
    FTypes: TStringList;
    FAbilities: TAbilitiesPokemon;
    FEggGroups: TStringList;
    FGender: TStringList;
    FHeight: Double;
    FWeight: Double;
    FFamily: TFamilyPokemon;
    FStarter: boolean;
    FLegendary: boolean;
    FMythical: boolean;
    FUltraBeast: boolean;
    FMega: boolean;
    FGen: integer;
    FSprite: string;
    FDescription: string;
    FImageStream: TPNGObject;

    constructor create;
    class function newInstance: TCustomPersistent;override;
    function GetBoolStr(bool: boolean): string;
    function GetStarter: string;
    function GetLegendary: string;
    function GetMythical: string;
    function GetUltraBeast: string;
    function GetMega: string;
  published
    property number: integer read FNumber write FNumber;
    property name: string read FName write FName;
    property species: string read FSpecies write FSpecies;
    property types: TStringList read FTypes write FTypes;
    property abilities: TAbilitiesPokemon read FAbilities write FAbilities;
    property eggGroups: TStringList read FEggGroups write FEggGroups;
    property gender: TStringList read FGender write FGender;
    property height: Double read FHeight write FHeight;
    property weight: Double read FWeight write FWeight;
    property family: TFamilyPokemon read FFamily write FFamily;
    property starter: boolean read FStarter write FStarter;
    property legendary: boolean read FLegendary write FLegendary;
    property mythical: boolean read FMythical write FMythical;
    property ultraBeast: boolean read FUltraBeast write FUltraBeast;
    property mega: boolean read FMega write FMega;
    property gen: integer read FGen write FGen;
    property sprite: string read FSprite write FSprite;
    property description: string read FDescription write FDescription;
  end;

  TPokemons = class(TCollection)
  public
    constructor Create(ownsObject:boolean=true);
    function Get(index:Integer): TPokemon;
  end;

  TListaPokemons = class(TCustomPersistent)
  public
    FPokemons: TPokemons;

    constructor create;
    destructor destroy; override;
    class function newInstance: TCustomPersistent; override;
  published
    property pokemons: TPokemons read FPokemons write FPokemons;
  end;

  TAtualizar = class(TThread)
  private
    FListView: TListView;
    FImageList: TImageList;
    FListaPokemons: TListaPokemons;
    FResponse: THttpResponse;
    FHHTTPConn: THttpClient;
  public
    constructor Create(AList : TListView; AImageList: TImageList); reintroduce;
    procedure Execute; override;
    procedure Print;
  end;

  TForm1 = class(TForm)
    ListView: TListView;
    btnAtualizar: TButton;
    Grid: TStringGrid;
    img: TImage;
    loading: TPanel;
    ImageList: TImageList;
    procedure btnAtualizarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ListViewSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
  private
    FListaPokemons: TListaPokemons;
    procedure TerminateAtualizar(Sender: TObject);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure LoadPNGAsIcon(const APNG: TPNGObject; var ICO: TIcon);
var
  Header: PBitmapV5Header;
  hNewBitmap, hMonoBitmap: HBITMAP;
  Bits: Pointer;
  x, y: Integer;
  DC: HDC;
  IconInfo: _ICONINFO;
  Pixel: ^Integer;
  ScanLine: PRGBTriple;
  AlphaScanline: pByteArray;
  PNG: TPNGObject;
begin
  PNG:=TPNGObject.Create;
  PNG.Assign(APNG);
  try
    if not Assigned(ICO) then ICO:=TIcon.Create;
    New(Header);
    FillMemory(Header, SizeOf(BitmapV5Header), 1);
    Header.bV5Size:=SizeOf(BitmapV5Header);
    Header.bV5Width:=PNG.Width;
    Header.bV5Height:=-PNG.Height;
    Header.bV5Planes:=1;
    Header.bV5BitCount:=32;
    Header.bV5Compression:=BI_BITFIELDS;
    Header.bV5RedMask:=$00FF0000;
    Header.bV5GreenMask:=$0000FF00;
    Header.bV5BlueMask:=$000000FF;
    Header.bV5AlphaMask:=$FF000000;
    DC:=GetDC(0);
    hNewBitmap := CreateDIBSection(DC, PBitmapInfo(Header)^, DIB_RGB_COLORS, Bits, 0, 0);
    Dispose(Header);
    ReleaseDC(0, DC);
    hMonoBitmap:=CreateBitmap(PNG.Width, PNG.Height, 1, 1, nil);
    Pixel:=Bits;
    for y:=0 to PNG.Height - 1 do begin
      ScanLine:=PNG.ScanLine[y];
      AlphaScanline:=PNG.AlphaScanline[y];
      for x:=0 to PNG.Width-1 do begin
        if Assigned(AlphaScanline) then Pixel^:=AlphaScanline[x] else Pixel^:=255;

        Pixel^:=Pixel^ shl 8;
        Inc(Pixel^, ScanLine^.rgbtRed);
        Pixel^:=Pixel^ shl 8;
        Inc(Pixel^, ScanLine^.rgbtGreen);
        Pixel^:=Pixel^ shl 8;
        Inc(Pixel^, ScanLine^.rgbtBlue);
        Inc(Pixel);
        Inc(ScanLine);
      end;
    end;
    IconInfo.fIcon:=true;
    IconInfo.hbmMask:=hMonoBitmap;
    IconInfo.hbmColor:=hNewBitmap;
    ICO.Handle:=CreateIconIndirect(IconInfo);

    DeleteObject(hNewBitmap);
    DeleteObject(hMonoBitmap);
  finally
    PNG.Free;
  end;
end;

procedure TForm1.btnAtualizarClick(Sender: TObject);
var
  Atualizar: TAtualizar;
begin
  loading.Show;
  Atualizar:=TAtualizar.Create(ListView, ImageList);
  Atualizar.OnTerminate:=TerminateAtualizar;
  Atualizar.Start;
end;

{ TAtualziar }

constructor TAtualizar.Create(AList: TListView; AImageList: TImageList);
begin
  inherited Create(True);
  FreeOnTerminate:=True;
  FListView:=AList;
  FImageList:=AImageList;
  FListaPokemons:=TListaPokemons.create;
  FResponse:=THttpResponse.create;
  FHHTTPConn:=THttpClient.create;

  FHHTTPConn.protocolVersion:=http_1_1;
//  FHHTTPConn.MimeType:=application_json;
  FHHTTPConn.timeout:=-1;
end;

procedure TAtualizar.Execute;
begin
  inherited;

  FListaPokemons.FPokemons.Clear;

  FResponse:=FHHTTPConn.httpGet('http://pokeapi.glitch.me/v1/pokemon/6');

  if not FResponse.hasError then begin
    FListaPokemons:=TListaPokemons(TJsonManager.deserialize('{"pokemons": ' + FResponse.contentToString + '}',TListaPokemons));

    Synchronize(Self.Print);
  end else begin
    ShowMessage('Falha na consulta');
  end;
end;

procedure TAtualizar.Print;
var
  item: TListItem;
  i: integer;
  Pokemon: TPokemon;
  stream: TMemoryStream;

  procedure SetIcon(APNG: TPNGObject);
  var
    Icon: TIcon;
  begin
    Icon:=TIcon.Create;
    LoadPNGAsIcon(APNG,Icon);
    FImageList.AddIcon(Icon);
  end;
begin
  FListView.Items.Clear;

  for i:=0 to FListaPokemons.FPokemons.Count-1 do begin
    Pokemon:=FListaPokemons.FPokemons.Get(i);

    item:=FListView.Items.Add;
    item.Caption:=Pokemon.FName;
    item.ImageIndex:=i;

    if Trim(Pokemon.FSprite) <> '' then begin
      FResponse:=FHHTTPConn.httpGet(Pokemon.FSprite);

      if FResponse.code = 200 then begin
        stream:=FResponse.content;
        Pokemon.FImageStream.LoadFromStream(stream);

        SetIcon(Pokemon.FImageStream);
      end else begin
        Pokemon.FImageStream:=nil;
      end;
    end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FListaPokemons:=TListaPokemons.Create;

  Grid.ColWidths[0]:=120;
  Grid.ColWidths[1]:=280;

  Grid.Cells[0,0]:='Number';
  Grid.Cells[0,1]:='Name';
  Grid.Cells[0,2]:='Species';
  Grid.Cells[0,3]:='Types';
  Grid.Cells[0,4]:='Abilities - Normal';
  Grid.Cells[0,5]:='Abilities - Hidden';
  Grid.Cells[0,6]:='EggGroups';
  Grid.Cells[0,7]:='Gender';
  Grid.Cells[0,8]:='Height';
  Grid.Cells[0,9]:='Weight';
  Grid.Cells[0,10]:='Family - ID';
  Grid.Cells[0,11]:='Family - EvolutionStage';
  Grid.Cells[0,12]:='Family - EvolutionLine';
  Grid.Cells[0,13]:='Starter';
  Grid.Cells[0,14]:='Legendary';
  Grid.Cells[0,15]:='Mythical';
  Grid.Cells[0,16]:='UltraBeast';
  Grid.Cells[0,17]:='Mega';
  Grid.Cells[0,18]:='Gen';
  Grid.Cells[0,19]:='Description';
end;

procedure TForm1.ListViewSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  Pokemon: TPokemon;
begin
  if FListaPokemons.FPokemons.Count > 0 then begin
    Pokemon:=FListaPokemons.FPokemons.Get(Item.Index);

    Grid.Cells[1,0]:=IntToStr(Pokemon.FNumber);
    Grid.Cells[1,1]:=Pokemon.FName;
    Grid.Cells[1,2]:=Pokemon.FSpecies;
    Grid.Cells[1,3]:=Pokemon.FTypes.DelimitedText;
    Grid.Cells[1,4]:=Pokemon.FAbilities.FNormal.DelimitedText;
    Grid.Cells[1,5]:=Pokemon.FAbilities.FHidden.DelimitedText;
    Grid.Cells[1,6]:=Pokemon.FEggGroups.DelimitedText;
    Grid.Cells[1,7]:=Pokemon.FGender.DelimitedText;
    Grid.Cells[1,8]:=FloatToStr(Pokemon.FHeight);
    Grid.Cells[1,9]:=FloatToStr(Pokemon.FWeight);
    Grid.Cells[1,10]:=IntToStr(Pokemon.FFamily.FID);
    Grid.Cells[1,11]:=IntToStr(Pokemon.FFamily.FEvolutionStage);
    Grid.Cells[1,12]:=Pokemon.FFamily.FEvolutionLine.DelimitedText;
    Grid.Cells[1,13]:=Pokemon.GetStarter;
    Grid.Cells[1,14]:=Pokemon.GetLegendary;
    Grid.Cells[1,15]:=Pokemon.GetMythical;
    Grid.Cells[1,16]:=Pokemon.GetUltraBeast;
    Grid.Cells[1,17]:=Pokemon.GetMega;
    Grid.Cells[1,18]:=IntToStr(Pokemon.FGen);
    Grid.Cells[1,19]:=Pokemon.FDescription;

    if Pokemon.FImageStream <> nil then img.Picture.Assign(Pokemon.FImageStream)
  end;
end;

procedure TForm1.TerminateAtualizar(Sender: TObject);
begin
  if Sender is TThread then begin
    FListaPokemons:=TAtualizar(TThread(Sender)).FListaPokemons;
    loading.hide;
  end;
end;

{ TPokemons }

constructor TPokemons.Create(ownsObject: boolean);
begin
  inherited Create(TPokemon,ownsObject);
  name:='pokemons';
end;

function TPokemons.Get(index: Integer): TPokemon;
begin
  Result:=Self.Items[index] as TPokemon;
end;

{ TPokemon }

constructor TPokemon.create;
begin
  inherited;
  FTypes:=TStringList.Create;
  FAbilities:=TAbilitiesPokemon.Create;
  FEggGroups:=TStringList.Create;
  FGender:=TStringList.Create;
  FFamily:=TFamilyPokemon.Create;
  FImageStream:=TPNGObject.Create;
end;

function TPokemon.GetBoolStr(bool: boolean): string;
begin
  Result:='false';
  if bool then Result:='true'; 
end;

function TPokemon.GetLegendary: string;
begin
  Result:=GetBoolStr(FLegendary);
end;

function TPokemon.GetMega: string;
begin
  Result:=GetBoolStr(FMega);
end;

function TPokemon.GetMythical: string;
begin
  Result:=GetBoolStr(FMythical);
end;

function TPokemon.GetStarter: string;
begin
  Result:=GetBoolStr(FStarter);
end;

function TPokemon.GetUltraBeast: string;
begin
  Result:=GetBoolStr(FUltraBeast);
end;

class function TPokemon.newInstance: TCustomPersistent;
begin
  Result:=TPokemon.create;
end;

{ TFamilyPokemon }

constructor TFamilyPokemon.create;
begin
  inherited;
  FEvolutionLine:=TStringList.Create;
end;

class function TFamilyPokemon.newInstance: TCustomPersistent;
begin
  Result:=TFamilyPokemon.create;
end;

{ TListaPokemons }

constructor TListaPokemons.create;
begin
  inherited;
  FPokemons:=TPokemons.create;
end;

destructor TListaPokemons.destroy;
begin
  FPokemons.Free;
  inherited;
end;

class function TListaPokemons.newInstance: TCustomPersistent;
begin
  Result:=TListaPokemons.create;
end;

{ TAbilitiesPokemon }

constructor TAbilitiesPokemon.create;
begin
  inherited;
  FNormal:=TStringList.Create;
  FHidden:=TStringList.Create;
end;

class function TAbilitiesPokemon.newInstance: TCustomPersistent;
begin
  Result:=TAbilitiesPokemon.create;
end;

end.
