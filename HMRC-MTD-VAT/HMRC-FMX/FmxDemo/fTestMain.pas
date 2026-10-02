unit fTestMain;

(*****************************************************************************
*                 HMRC API REST Test Application Main Form                   *
******************************************************************************
*                                FMX FORMS                                   *
******************************************************************************
*  This just provides a means to load the forms with the actual tests.       *
*                                                                            *
*  created 22/12/18.                                                         *
*  version 1.0.0                                                             *
*                                                                            *
*****************************************************************************)

interface
(****************************************************************************)

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls,
  HmrcRestSupport, HmrcHeaders, FMX.Layouts, FMX.ExtCtrls;
(****************************************************************************)

type
  TfrmHMRCDemoMain = class(TForm)
    btnTestClient: TCornerButton;
    btnVatFresh: TCornerButton;
    btnVatSaved: TCornerButton;
    odlg: TOpenDialog;
    btnVrnChecks: TCornerButton;
    ImageViewer1: TImageViewer;
    Label1: TLabel;
    btnClose: TCornerButton;
    procedure btnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnTestClientClick(Sender: TObject);
    procedure btnVatFreshClick(Sender: TObject);
    procedure btnVatSavedClick(Sender: TObject);
    procedure btnVrnChecksClick(Sender: TObject);
  private
    FFilePath  : string;                 // where to find ini files
    FAppValues : TAppValues;             // application settings for the vat headers
    ODetails   : THmrcClientDetails;     // application keys for hmrc
    procedure LoadDetails;
  public
  end;

var
  frmHMRCDemoMain: TfrmHMRCDemoMain;

(****************************************************************************)
implementation
(****************************************************************************)
uses
  System.Hash, IniFiles, fTestClient, fVatFresh, fVatSaved, fVrnCheck;
{$R *.fmx}

const
  // dummy substitute for the application installation guid
  ApGuid = '{2BE68571-041E-47DA-9DA9-42AC4510453A}';

(*****************************************************************************
*                          HMRC TEST MAIN FORM                               *
******************************************************************************
*                             INIT SECTION                                   *
******************************************************************************
*  Init. Set the application info for the vat headers. Hashing the license   *
*  key, as HMRC do not actually need it, just a consistent value.            *
*****************************************************************************)
procedure TfrmHMRCDemoMain.FormCreate(Sender: TObject);
begin
  FFilePath := '';
  ODetails  := THmrcClientDetails.Create;

  FAppValues.AppGuid := ApGuid;
  FAppValues.AppName := 'HmrcDevTest';
  // your actual license key or some dummy value here - uses System.Hash
  FAppValues.License := THashSHA1.GetHashString('ABC123XYZ');
  // dummy incorrect values to pass the headers test - clearly nonsense for testing only
  FAppValues.MFType  := 'AUTH_CODE';
  FAppValues.MFTime  := Now - 0.01;   // about 15 minutes ago
  FAppValues.MFValue := 'abc123';     // hash it here to obscure it

  LoadDetails;
end;

(*****************************************************************************
*  Free details.                                                             *
*****************************************************************************)
procedure TfrmHMRCDemoMain.FormDestroy(Sender: TObject);
begin
  ODetails.Free;
end;

(*****************************************************************************
*  Load details from config file - this is just a simple demo app.           *
*****************************************************************************)
procedure TfrmHMRCDemoMain.LoadDetails;
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
      ODetails.BaseUrl      := inf.ReadString('REST', 'BaseUrl', '');
    finally
      inf.Free;
    end;
  end;
end;


(*****************************************************************************
*                          BUTTON CLICKS SECTION                             *
******************************************************************************
*  Close.                                                                    *
*****************************************************************************)
procedure TfrmHMRCDemoMain.btnCloseClick(Sender: TObject);
begin
  Close;
end;

(*****************************************************************************
*  Shows the form to test the HmrcTestClient. This will test the Hello World *
*  examples and create new test users on the HMRC system.                    *
*****************************************************************************)
procedure TfrmHMRCDemoMain.btnTestClientClick(Sender: TObject);
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
*  Shows the form to test the HmrcVATClient without saving the access tokens *
*  so it will require the user to login fresh each time.                     *
*****************************************************************************)
procedure TfrmHMRCDemoMain.btnVatFreshClick(Sender: TObject);
var
  frm: TfrmVatFresh;
begin
  frm := TfrmVatFresh.Create(nil);
  try
    frm.ClientDetails := ODetails;
    frm.SetAppValues(FAppValues);
    frm.ShowModal;
  finally
    frm.Free;
  end;
end;

(*****************************************************************************
*  Shows the form to test the HmrcVATClient using stored access tokens. This *
*  will load and save access/refresh tokens after the initial grant.         *
*****************************************************************************)
procedure TfrmHMRCDemoMain.btnVatSavedClick(Sender: TObject);
var
  frm: TfrmVatSaved;
begin
  frm := TfrmVatSaved.Create(nil);
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
*  Shows the form to test the HmrcVATClient checking VRNs. This does not     *
*  need the access tokens, as it uses application level authorisation.       *
*****************************************************************************)
procedure TfrmHMRCDemoMain.btnVrnChecksClick(Sender: TObject);
var
  frm: TfrmVrnCheck;
begin
  frm := TfrmVrnCheck.Create(nil);
  try
    frm.ClientDetails := ODetails;
    frm.SetAppValues(FAppValues);
    frm.ShowModal;
  finally
    frm.Free;
  end;
end;




end.
