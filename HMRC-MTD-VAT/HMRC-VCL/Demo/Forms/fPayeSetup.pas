unit fPayeSetup;

(*****************************************************************************
*                HMRC PAYE/SA API REST Test Data Setup Form                  *
******************************************************************************
*                                VCL FORMS                                   *
******************************************************************************
*  A simple form to test the PAYE/SA test data set up endpoints and display  *
*  the results to the screen. It also writes to a text file.                 *
*                                                                            *
******************************************************************************
*  created  08/02/21    Based on the existing VAT client tests.              *
*  updated  08/02/21.   Initial release.                                     *
*                                                                            *
*  version  1.0.0       released 08/02/21    initial release for beta apis   *
*                                                                            *
*  original copyright Ian Hamilton 2021.                                     *
*  License : GPL                                                             *
*                                                                            *
*****************************************************************************)
interface
(****************************************************************************)

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Types,
  Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.Imaging.pngimage, Vcl.ExtCtrls,
  HmrcRestSupport, HmrcRestClient, HmrcTestSupport, HmrcTestClient, HmrcHeaders,
  fVclHmrcBase;
(****************************************************************************)

type
  TfrmPAYESetup = class(TfrmVclHmrcBase)
    mmoInfo: TMemo;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    edtUTR: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    cbxYear: TComboBox;
    Bevel1: TBevel;
    cbxMAStatus: TComboBox;
    Label3: TLabel;
    Bevel2: TBevel;
    edtNino: TEdit;
    Label4: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure edtUTRExit(Sender: TObject);
  private
    FSwitchOn   : boolean;                       // random boolean switch
    OTestClient : THmrcTestClient;               // the test client to do the api calls
    procedure CommonCall(const AMthd: integer; const AType, ARsc, ASfx, ABdy: string);   // shared call processor
    procedure DoBenefits;                        // call benefits set up
    procedure DoEmployment;                      // call employments set up
    procedure DoIncome;                          // call income set up
    procedure DoMAEligibility;                   // call MA eligibility set up
    procedure DoMAStatus;                        // call MA status set up
    procedure DoNI;                              // call NI set up
    procedure DoTax;                             // call tax set up
    procedure SaveResponse(const Iza, Value: string);     // write the api response to file
  public
    procedure SetDetails(const Value: THmrcClientDetails); override;    // override property method
  end;


(****************************************************************************)
implementation
(****************************************************************************)
uses
  System.JSON,
  IniFiles;

{$R *.dfm}

{ TfrmPAYESetup }

(*****************************************************************************
*                         HMRC TEST CLIENT FORM                              *
******************************************************************************
*                             INIT SECTION                                   *
******************************************************************************
*  Init.                                                                     *
*****************************************************************************)
procedure TfrmPAYESetup.FormCreate(Sender: TObject);
begin
  inherited;

  OTestClient := THmrcTestClient.Create(Self);

  OTestClient.IzTest := true;    // by default it targets the live api service
  OTestClient.OnTokenChange := SaveToken;  // this should automate token saving
  OTestClient.DoLoadToken := LoadToken;    // to load tokens on demand
end;



(*****************************************************************************
*                          BUTTON CLICKS SECTION                             *
******************************************************************************
*  Call benefits set up.                                                     *
*****************************************************************************)
procedure TfrmPAYESetup.Button1Click(Sender: TObject);
begin
  if (edtUTR.Text <> '') then
    DoBenefits;
end;

(*****************************************************************************
*  Call employment set up.                                                   *
*****************************************************************************)
procedure TfrmPAYESetup.Button2Click(Sender: TObject);
begin
  if (edtUTR.Text <> '') then
    DoEmployment;
end;

(*****************************************************************************
*  Call Income set up.                                                       *
*****************************************************************************)
procedure TfrmPAYESetup.Button3Click(Sender: TObject);
begin
  if (edtUTR.Text <> '') then
    DoIncome;
end;

(*****************************************************************************
*  Call tax set up.                                                          *
*****************************************************************************)
procedure TfrmPAYESetup.Button4Click(Sender: TObject);
begin
  if (edtUTR.Text <> '') then
    DoTax;
end;

(*****************************************************************************
*  Call MA eligibility set up.                                               *
*****************************************************************************)
procedure TfrmPAYESetup.Button5Click(Sender: TObject);
begin
  if (edtUTR.Text <> '') then
    DoMAEligibility;
end;

(*****************************************************************************
*  Call MA Status set up.                                                    *
*****************************************************************************)
procedure TfrmPAYESetup.Button6Click(Sender: TObject);
begin
  if (edtUTR.Text <> '') then
    DoMAStatus;
end;

(*****************************************************************************
*  Call NI setup.                                                            *
*****************************************************************************)
procedure TfrmPAYESetup.Button7Click(Sender: TObject);
begin
  if (edtUTR.Text <> '') then
    DoNI;
end;

(*****************************************************************************
*  Set UID.                                                                  *
*****************************************************************************)
procedure TfrmPAYESetup.edtUTRExit(Sender: TObject);
begin
  OTestClient.UID := Trim(edtUTR.Text);
end;



(*****************************************************************************
*                         COMMON CALL METHODS SECTION                        *
******************************************************************************
*  Common call handling routine. This is an intermediate between the base    *
*  call (DoXyz) and the test client universal method, to handle the result   *
*  from the test client. Exceptions are caught in the universal method and   *
*  returned as errors.                                                       *
*****************************************************************************)
procedure TfrmPAYESetup.CommonCall(const AMthd: integer; const AType, ARsc, ASfx, ABdy: string);
var
  errcode: integer;
begin
  errcode := OTestClient.CallApi(AMthd, ARsc, ASfx, ABdy);
  if errcode = RESULT_OK then
  begin
    mmoInfo.Lines.Add(' ');
    mmoInfo.Lines.Add('// ' + AType);
    mmoInfo.Lines.Add(OTestClient.Lastvalue.ToString);
    // and save to file
    SaveResponse(AType, OTestClient.LastValue.ToString);
  end
  else begin
    // handle error situation
    if (errcode = RESULT_FAIL) then
    // failed, so write response info to display
      mmoInfo.Lines.Add('Called failed with: ' + IntToStr(OTestClient.LastCode) + ' ' + OTestClient.LastMsg)
    else
    // exception, so write error info to display
      mmoInfo.Lines.Add('Exception: ' + IntToStr(OTestClient.LastCode) + ' ' + OTestClient.LastMsg);
    // and write the error/exception message
    mmoInfo.Lines.Add(OTestClient.LastError);
  end;
end;



(*****************************************************************************
*                         PROCESS HANDLING SECTION                           *
******************************************************************************
*  These methods set the parameters for the particular call and pass them    *
*  to the common call handler.                                               *
******************************************************************************
*  Call benefits set up.                                                     *
*****************************************************************************)
procedure TfrmPAYESetup.DoBenefits;
var
  prm1, prm2, prm3: string;
begin
  prm1 := csRscPaye + Trim(edtUTR.Text);
  prm2 := csSfxBens + cbxYear.Text;
  prm3 := csScenario1;

  CommonCall(REST_POST, csBenefits, prm1, prm2, prm3);
end;

(*****************************************************************************
*  Call employment setup.                                                    *
*****************************************************************************)
procedure TfrmPAYESetup.DoEmployment;
var
  prm1, prm2, prm3: string;
begin
  prm1 := csRscPaye + Trim(edtUTR.Text);
  prm2 := csSfxEmps + cbxYear.Text;
  prm3 := csScenario1;

  CommonCall(REST_POST, csEmployments, prm1, prm2, prm3);
end;

(*****************************************************************************
*  Call income setup.                                                        *
*****************************************************************************)
procedure TfrmPAYESetup.DoIncome;
var
  prm1, prm2, prm3: string;
begin
  prm1 := csRscPaye + Trim(edtUTR.Text);
  prm2 := csSfxIcm + cbxYear.Text;
  prm3 := csScenario1;

  CommonCall(REST_POST, csIncome, prm1, prm2, prm3);
end;

(*****************************************************************************
*  Call MA eligibility setup.                                                *
*****************************************************************************)
procedure TfrmPAYESetup.DoMAEligibility;
var
  prm1, prm2, prm3: string;
begin
  prm1 := csRscMAnino + Trim(edtNino.Text);
  prm2 := csSfxEligible + cbxYear.Text;
  if FSwitchOn then
  begin
    prm3 := Format(csSetEligible, ['true']);
    FSwitchOn := false;
  end
  else begin
    prm3 := Format(csSetEligible, ['false']);
    FSwitchOn := true;
  end;

  CommonCall(REST_POST, csMA, prm1, prm2, prm3);
end;

(*****************************************************************************
*  Call MA status setup.                                                     *
*****************************************************************************)
procedure TfrmPAYESetup.DoMAStatus;
var
  prm1, prm2, prm3: string;
begin
  prm1 := csRscMAstatus + Trim(edtUTR.Text);
  prm2 := csSfxStatus + cbxYear.Text;
  if FSwitchOn then
  begin
    prm3 := Format(csSetStatus, [cbxMAStatus.Text, 'true']);
    FSwitchOn := false;
  end
  else begin
    prm3 := Format(csSetStatus, [cbxMAStatus.Text, 'false']);
    FSwitchOn := true;
  end;

  CommonCall(REST_POST, csMA, prm1, prm2, prm3);
end;

(*****************************************************************************
*  Call NI setup.                                                            *
*****************************************************************************)
procedure TfrmPAYESetup.DoNI;
var
  prm1, prm2, prm3: string;
begin
  prm1 := csRscNICs + Trim(edtUTR.Text);
  prm2 := csSfxNICs + cbxYear.Text;
  if FSwitchOn then
  begin
    prm3 := csScenario1;
    FSwitchOn := false;
  end
  else begin
    prm3 := csScenario2;
    FSwitchOn := true;
  end;

  CommonCall(REST_POST, csNICs, prm1, prm2, prm3);
end;

(*****************************************************************************
*  Call tax setup.                                                           *
*****************************************************************************)
procedure TfrmPAYESetup.DoTax;
var
  prm1, prm2, prm3: string;
begin
  prm1 := csRscPaye + Trim(edtUTR.Text);
  prm2 := csSfxTax + cbxYear.Text;
  prm3 := csScenario1;

  CommonCall(REST_POST, csTax, prm1, prm2, prm3);
end;



(*****************************************************************************
*                         FILE SAVE METHODS SECTION                          *
******************************************************************************
*  Save the new data details.                                                *
*****************************************************************************)
procedure TfrmPAYESetup.SaveResponse(const Iza, Value: string);
var
  f: TextFile;
begin
  AssignFile(f, FFilePath + 'UserData.txt');
  if (FileExists(FFilePath + 'UserData.txt')) then
    Append(f)
  else
    Rewrite(f);
  try
    Writeln(f);
    Writeln(f, '// ' + Iza + '  UTR=' + edtUTR.Text + '  ' + cbxYear.Text);
    Writeln(f, Value);
  finally
    CloseFile(f);
  end;
end;

(*****************************************************************************
*                         PROPERTY METHODS SECTION                           *
******************************************************************************
*  Set the client details.                                                   *
*****************************************************************************)
procedure TfrmPAYESetup.SetDetails(const Value: THmrcClientDetails);
begin
  inherited;

  OTestClient.ClientId     := ODetails.ClientId;
  OTestClient.ClientSecret := ODetails.ClientSecret;
  OTestClient.CallbackPort := ODetails.CallbackPort;
  OTestClient.CallbackUrl  := ODetails.CallbackUrl;
  OTestClient.ServerToken  := ODetails.ServerToken;
  //OTestClient.BaseUrl      := ODetails.BaseUrl;
end;

end.
