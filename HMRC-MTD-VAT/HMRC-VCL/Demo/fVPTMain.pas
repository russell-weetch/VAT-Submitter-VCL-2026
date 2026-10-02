unit fVPTMain;

(*****************************************************************************
*               HMRC PAYE API REST Test Application Main Form                *
******************************************************************************
*                                VCL FORMS                                   *
******************************************************************************
*  This just provides a means to load the forms with the actual tests.       *
*                                                                            *
*  created 22/12/20.                                                         *
*  version 1.0.0                                                             *
*                                                                            *
*****************************************************************************)

interface
(****************************************************************************)

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons,
  Vcl.ExtCtrls, System.UITypes, Vcl.Imaging.pngimage,
  HmrcRestSupport, HmrcHeaders
  ;
(****************************************************************************)

type
  TfrmVPTMain = class(TForm)
    odlg: TOpenDialog;
    btnSA: TBitBtn;
    Image1: TImage;
    btnClose: TSpeedButton;
    Label1: TLabel;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnSAClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FAppValues : TAppValues;             // application settings for the vat headers
    FFilePath  : string;                 // config/ini file location for tests
    ODetails   : THmrcClientDetails;     // client id/secret for oauth2
    procedure LoadDetails;               // load saved application details
  public
    { Public declarations }
  end;

var
  frmVPTMain: TfrmVPTMain;

(****************************************************************************)
implementation
(****************************************************************************)
uses
  System.Hash, IniFiles,
  fTestSA
  ;

{$R *.dfm}


const
  // dummy substitute for the application installation guid
  ApGuid = '4CC416C1-B102-4E5C-BCC4-95ABCEFDE3F5';


(*****************************************************************************
*                          PAYE TEST MAIN FORM                               *
******************************************************************************
*                             INIT SECTION                                   *
******************************************************************************
*  Init.                                                                     *
*****************************************************************************)
procedure TfrmVPTMain.FormCreate(Sender: TObject);
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
procedure TfrmVPTMain.FormDestroy(Sender: TObject);
begin
  ODetails.Free;
end;

(*****************************************************************************
*  Load details from config file - this is just a simple demo app.           *
*****************************************************************************)
procedure TfrmVPTMain.LoadDetails;
var
  inf : TIniFile;
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
      ODetails.AppName      := inf.ReadString('REST', 'AppName', '');
      ODetails.AppGuid      := inf.ReadString('REST', 'AppGuid', '');
    finally
      inf.Free;
    end;

    if ODetails.AppGuid <> '' then
      FAppValues.AppGuid := ODetails.AppGuid;
    if ODetails.AppName <> '' then
      FAppValues.AppName := ODetails.AppName;
  end;
end;


(*****************************************************************************
*                          BUTTON CLICKS SECTION                             *
******************************************************************************
*  Close.                                                                    *
*****************************************************************************)
procedure TfrmVPTMain.btnCloseClick(Sender: TObject);
begin
  Close;
end;

(*****************************************************************************
*  Shows the form to test the HmrcSAClient endpoints.                        *
*****************************************************************************)
procedure TfrmVPTMain.btnSAClick(Sender: TObject);
var
  frm: TfrmTestSA;
begin
  frm := TfrmTestSA.Create(nil);
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
