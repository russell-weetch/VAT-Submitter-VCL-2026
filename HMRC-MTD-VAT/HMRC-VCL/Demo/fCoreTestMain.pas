unit fCoreTestMain;

(*****************************************************************************
*                HMRC MTD API REST Test Application Main Form                *
******************************************************************************
*                                VCL FORMS                                   *
******************************************************************************
*  This just provides a means to load the forms with the actual tests.       *
*                                                                            *
*  created 05/02/21.                                                         *
*  version 1.0.0                                                             *
*                                                                            *
*****************************************************************************)

interface
(****************************************************************************)

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.StdCtrls,
  HmrcRestSupport, HmrcHeaders, Vcl.WinXPickers, REST.Types, REST.Client, Data.Bind.Components, Data.Bind.ObjectScope
  ;
(****************************************************************************)

type
  TfrmCoreTestMain = class(TForm)
    Image1: TImage;
    Button1: TButton;
    Button2: TButton;
    odlg: TOpenDialog;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    FAppValues : TAppValues;             // application settings for the fraud headers
    FFilePath  : string;                 // config/ini file location for tests
    ODetails   : THmrcClientDetails;     // client id/secret for oauth2
    procedure LoadDetails;               // load saved application details
  public
    { Public declarations }
  end;

var
  frmCoreTestMain: TfrmCoreTestMain;

(****************************************************************************)
implementation
(****************************************************************************)
uses
  IniFiles, System.Hash, fTestClient, fPayeSetup;

{$R *.dfm}

const
  // dummy substitute for the application installation guid
  ApGuid = '2C3ACC67-DD94-4D1D-B731-7B1175CF3044';



(*****************************************************************************
*                          REST TEST MAIN FORM                               *
******************************************************************************
*                             INIT SECTION                                   *
******************************************************************************
*  Init.                                                                     *
*****************************************************************************)
procedure TfrmCoreTestMain.FormCreate(Sender: TObject);
begin
  FFilePath := '';
  ODetails  := THmrcClientDetails.Create;

  // initialize application specific values for anti-fraud headers
  FAppValues.AppGuid := ApGuid;
  FAppValues.AppName := 'HmrcDevTest';
  // your actual license key or some dummy value here - uses System.Hash
  FAppValues.License := THashSHA1.GetHashString('ABC123XYZ');
  // dummy incorrect values to pass the headers test - clearly nonsense for testing only
  FAppValues.MFType  := 'AUTH_CODE';
  FAppValues.MFTime  := Now - 0.01;   // about 15 minutes ago
  FAppValues.MFValue := 'abc123';     // hash it here to obscure it if required

  LoadDetails;     // client id/secret for oauth2
end;

(*****************************************************************************
*  Free details.                                                             *
*****************************************************************************)
procedure TfrmCoreTestMain.FormDestroy(Sender: TObject);
begin
  ODetails.Free;
end;

(*****************************************************************************
*  Load details from config file - this is just a simple demo app.           *
*****************************************************************************)
procedure TfrmCoreTestMain.LoadDetails;
var
  inf : TIniFile;
  tmp: string;
begin
  if (odlg.Execute) then
  begin
    FFilePath := ExtractFilePath(odlg.Filename);

    inf := TIniFile.Create(odlg.FileName);
    try
      ODetails.ClientId     := inf.ReadString('REST', 'AppKey', '');
      ODetails.ClientSecret := inf.ReadString('REST', 'AppSecret', '');
      ODetails.CallbackPort := inf.ReadString('REST', 'CallbackPort', '');
      ODetails.CallbackUrl  := inf.ReadString('REST', 'CallbackUrl', '');
      ODetails.ServerToken  := inf.ReadString('REST', 'ServerToken', '');
      //ODetails.BaseUrl      := inf.ReadString('REST', 'BaseUrl', '');

      tmp := inf.ReadString('REST', 'AppGuid', '');
      if (tmp <> '') then
        FAppValues.AppGuid := tmp;

      tmp := inf.ReadString('REST', 'AppName', '');
      if (tmp <> '') then
        FAppValues.AppName := tmp;
    finally
      inf.Free;
    end;
  end;
end;


(*****************************************************************************
*                          BUTTON CLICKS SECTION                             *
******************************************************************************
*  Shows the form to test the HmrcTestClient. This will test the Hello World *
*  examples and create new test users on the HMRC system.                    *
*****************************************************************************)
procedure TfrmCoreTestMain.Button1Click(Sender: TObject);
var
  frm: TfrmTestClient;
begin
  frm := TfrmTestClient.Create(nil);
  try
    frm.FilePath := FFilepath;
    frm.ClientDetails := ODetails;
    frm.SetAppValues(FAppValues);
    frm.ShowModal;
  finally
    frm.Free;
  end;
end;

(*****************************************************************************
*  Shows the form to set up the HmrcPAYEClient endpoints data.               *
*****************************************************************************)
procedure TfrmCoreTestMain.Button2Click(Sender: TObject);
var
  frm: TfrmPAYESetup;
begin
  frm := TfrmPAYESetup.Create(nil);
  try
    frm.FilePath := FFilepath;
    frm.ClientDetails := ODetails;
    frm.SetAppValues(FAppValues);
    frm.ShowModal;
  finally
    frm.Free;
  end;
end;



end.
