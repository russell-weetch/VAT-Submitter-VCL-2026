unit fTestSA;

(*****************************************************************************
*                HMRC PAYE API REST Test Application SA Form                 *
******************************************************************************
*                                VCL FORMS                                   *
******************************************************************************
*  A simple form to test the SA endpoints and display the results to the     *
*  screen.                                                                   *
*                                                                            *
******************************************************************************
*  created  22/12/20    Based on the existing VAT client tests.              *
*  updated  05/02/21.   Initial release.                                     *
*                                                                            *
*  version  1.0.0       released 05/02/21    initial release for beta apis   *
*                                                                            *
*  original copyright Ian Hamilton 2020/21.                                  *
*  License : GPL                                                             *
*                                                                            *
*****************************************************************************)
interface
(****************************************************************************)

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.StdCtrls,
  fVclHmrcBase, HmrcHeaders, HmrcRestSupport, HmrcRestClient, HmrcSASupport, HmrcSAClient
  ;
(****************************************************************************)

type
  TfrmTestSA = class(TfrmVclHmrcBase)
    Button1: TButton;
    mmoInfo: TMemo;
    cbxYear: TComboBox;
    lblUID: TLabel;
    edtUID: TEdit;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    edtFname: TEdit;
    edtSname: TEdit;
    edtNino: TEdit;
    edtDOB: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Bevel1: TBevel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure edtUIDExit(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    OTestClient : THmrcSAClient;
    procedure DoBenefits;                        // call the benefits endpoint
    procedure DoEmployments;                     // call the employments endpoint
    procedure DoError(const AValue: integer);    // common error handling
    procedure DoIncome;                          // call the income endpoint
    procedure DoNI;                              // call the NI endpoint
    procedure DoMAEligibility;                   // call the MA eligibility endpoint
    procedure DoMAStatus;                        // call the MA status endpoint
    procedure DoTax;                             // call the tax endpoint
  protected
    procedure SetDetails(const Value: THmrcClientDetails); override; // set the client details in the rest client
  public
    procedure SetAppValues(Values: TAppValues); override;
  end;


(****************************************************************************)
implementation
(****************************************************************************)
uses
  IPPeerClient, REST.Types, REST.Client, REST.Utils, REST.Authenticator.OAuth,
  System.JSON, System.Generics.Collections,
  IniFiles;

{$R *.dfm}



(*****************************************************************************
*                          HMRC TEST MAIN FORM                               *
******************************************************************************
*                             INIT SECTION                                   *
******************************************************************************
*  Init. Set the application info for the vat headers. Hashing the license   *
*  key, as HMRC do not actually need it, just a consistent value.            *
*****************************************************************************)
procedure TfrmTestSA.FormCreate(Sender: TObject);
begin
  OTestClient := THmrcSAClient.Create(Self);

  // set test mode
  OTestClient.IzTest := true;    // by default it targets the live api service

  OTestClient.OnTokenChange := SaveToken;  // to save new and changed tokens
  OTestClient.DoLoadToken := LoadToken;    // to load tokens on demand
end;



(*****************************************************************************
*                         CONTROLS METHODS SECTION                           *
******************************************************************************
*                          BUTTON METHODS SECTION                            *
******************************************************************************
*  Handle the benefits button click.                                         *
*****************************************************************************)
procedure TfrmTestSA.Button1Click(Sender: TObject);
begin
  DoBenefits;
end;

(*****************************************************************************
*  Handle the employments button click.                                      *
*****************************************************************************)
procedure TfrmTestSA.Button2Click(Sender: TObject);
begin
  DoEmployments;
end;

(*****************************************************************************
*  Handle the National Insurance button click.                               *
*****************************************************************************)
procedure TfrmTestSA.Button3Click(Sender: TObject);
begin
  DoNI;
end;

(*****************************************************************************
*  Handle the Tax button click.                                              *
*****************************************************************************)
procedure TfrmTestSA.Button4Click(Sender: TObject);
begin
  DoTax;
end;

(*****************************************************************************
*  Handle the Income button click.                                           *
*****************************************************************************)
procedure TfrmTestSA.Button5Click(Sender: TObject);
begin
  DoIncome;
end;

(*****************************************************************************
*  Handle the Marriage Allowance Status button click.                        *
*****************************************************************************)
procedure TfrmTestSA.Button6Click(Sender: TObject);
begin
  DoMAStatus;
end;

(*****************************************************************************
*  Handle the Marriage Allowance Eligibility button click.                   *
*****************************************************************************)
procedure TfrmTestSA.Button7Click(Sender: TObject);
begin
  DoMAEligibility;
end;

(*****************************************************************************
*                           EDIT METHODS SECTION                             *
******************************************************************************
*  Move the UTR to the rest client UID.                                      *
*****************************************************************************)
procedure TfrmTestSA.edtUIDExit(Sender: TObject);
begin
  OTestClient.SetHmrcId(Trim(edtUID.Text));
end;



(*****************************************************************************
*                      SA CLIENT ACCESS METHODS SECTION                      *
******************************************************************************
*  Common error handling routine.                                            *
*****************************************************************************)
procedure TfrmTestSA.DoError(const AValue: integer);
begin
  // check whether it failed because there was no access token
  if (OTestClient.LastCode = ERR_NO_ACCESS_TOKEN) then
  begin
    // so get a new access token
    OTestClient.NewAccessToken;
    // now the user needs to call the api again
    mmoInfo.Lines.Add('Please call the API again, after authority has been granted');
  end  // else no token

  // handle error situation
  else begin
    if (AValue = RESULT_NONE) then
      // failed, but should only be because the UID is invalid
      mmoInfo.Lines.Add('No UID (UTR) or UID is invalid')
    else if (AValue = RESULT_FAIL) then
      // general failure, so write response info to display
      mmoInfo.Lines.Add('Called failed with: ' + IntToStr(OTestClient.LastCode) + ' ' + OTestClient.LastMsg)
    else
      // exception, so write error info to display
      mmoInfo.Lines.Add('Exception: ' + IntToStr(OTestClient.LastCode) + ' ' + OTestClient.LastMsg);

    // and write the error/exception message
    mmoInfo.Lines.Add(OTestClient.LastError);
    // or handle it some other way ...
  end;  // else failure
end;


(*****************************************************************************
*  Call the benefits endpoint.                                               *
*****************************************************************************)
procedure TfrmTestSA.DoBenefits;
var
  errcode: integer;
  Benefit: TSABenefits;
  Benefits: TSABenefitsList;
begin
  Benefits := OTestClient.GetBenefits(cbxYear.Text, errcode);
  if (Assigned(Benefits)) then
  try
    // succeeded, so write data returned to display
    mmoInfo.Lines.Add('');
    mmoInfo.Lines.Add('Benefits');
    for Benefit in Benefits.Benefits do
    begin
      mmoInfo.Lines.Add('');
      mmoInfo.Lines.Add('PayeRef : ' + Benefit.PayeRef);
      mmoInfo.Lines.Add('Car benefit : ' + IntToStr(Benefit.CCVBens));
      // ... etc...
    end;
    // or do something more useful with it
    // ...
  finally
    Benefits.Free;
  end  // if success
  else
    DoError(errcode);
end;

(*****************************************************************************
*  Call the employments endpoint.                                            *
*****************************************************************************)
procedure TfrmTestSA.DoEmployments;
var
  errcode: integer;
  Employment: TSAEmployment;
  Employments: TSAEmploymentsList;
begin
  Employments := OTestClient.GetEmployment(cbxYear.Text, errcode);
  if (Assigned(Employments)) then
  try
    mmoInfo.Lines.Add('');
    mmoInfo.Lines.Add('Employments');
    // succeeded, so write data returned to display
    for Employment in Employments.Employments do
    begin
      mmoInfo.Lines.Add('');
      mmoInfo.Lines.Add('PayeRef : ' + Employment.PayeRef);
      mmoInfo.Lines.Add('Name : ' + Employment.EmpName);
      // ... etc...
    end;
  finally
    Employments.Free;
  end  // if success
  else
    DoError(errcode);
end;

(*****************************************************************************
*  Call the income endpoint.                                                 *
*****************************************************************************)
procedure TfrmTestSA.DoIncome;
var
  errcode: integer;
  Income: TSAIncome;
  Incomes: TSAIncomes;
begin
  Incomes := OTestClient.GetIncome(cbxYear.Text, errcode);
  if (Assigned(Incomes)) then
  try
    // succeeded, so write data returned to display
    mmoInfo.Lines.Add('');
    mmoInfo.Lines.Add('Income');
    // benefits
    mmoInfo.Lines.Add('Benefits');
    mmoInfo.Lines.Add('  Annuities : ' + DoshFormat(Incomes.Benefits.OPRA));
    mmoInfo.Lines.Add('  Incapacity : ' + DoshFormat(Incomes.Benefits.IBen));
    mmoInfo.Lines.Add('  Jobseeker : ' + DoshFormat(Incomes.Benefits.JSA));
    mmoInfo.Lines.Add('  SEISS net : ' + DoshFormat(Incomes.Benefits.SNP));
    // and pay
    mmoInfo.Lines.Add('Pay');
    for Income in Incomes.PayList do
    begin
      mmoInfo.Lines.Add('  PayeRef : ' + Income.PayeRef);
      mmoInfo.Lines.Add('  Pay : ' + DoshFormat(Income.Pay));
    end;
    // or do something more useful with it
    // ...
  finally
    Incomes.Free;
  end  // if success
  else
    DoError(errcode);
end;

(*****************************************************************************
*  Call the MA eligibility endpoint.                                         *
*****************************************************************************)
procedure TfrmTestSA.DoMAEligibility;
var
  errcode: integer;
  Mae: TSAMrgAllowance;
begin
  // initialize the data object
  Mae := TSAMrgAllowance.Create;
  try
    Mae.UTR       := OTestClient.UID;
    Mae.TaxYear   := cbxYear.Text;
    Mae.Nino      := Trim(edtNino.Text);
    Mae.Firstname := Trim(edtFname.Text);
    Mae.Surname   := Trim(edtSname.Text);
    Mae.DOB       := Trim(edtDOB.Text);

    errcode := OTestClient.GetMAEligibility(Mae);
    if (errcode = RESULT_OK) then
    begin
      // succeeded, so write data returned to display
      mmoInfo.Lines.Add('');
      mmoInfo.Lines.Add('MA Eligibility');
      mmoInfo.Lines.Add('  Eligible : ' + BoolToStr(Mae.Eligible));
      // or do something more useful with it
      // ...
    end  // if success
    else begin
      DoError(errcode);
    end;
  finally
    Mae.Free;
  end;
end;

(*****************************************************************************
*  Call the MA status endpoint.                                              *
*****************************************************************************)
procedure TfrmTestSA.DoMAStatus;
var
  errcode: integer;
  AStatus: string;
  IzDed: boolean;
begin
  errcode := OTestClient.GetMAStatus(cbxYear.Text, AStatus, IzDed);
  // check the status
  if (errcode = RESULT_OK) then
  begin
    // succeeded, so write data returned to display
    mmoInfo.Lines.Add('');
    mmoInfo.Lines.Add('MA Status');
    mmoInfo.Lines.Add('  Status : ' + AStatus);
    mmoInfo.Lines.Add('  Deceased : ' + BoolToStr(IzDed));
    // or do something more useful with it
    // ...
  end  // if success
  else
    DoError(errcode);
end;

(*****************************************************************************
*  Call the NI endpoint.                                                     *
*****************************************************************************)
procedure TfrmTestSA.DoNI;
var
  errcode: integer;
  Nic: TSANI;
begin
  Nic := OTestClient.GetNI(cbxYear.Text, errcode);
  if (Assigned(Nic)) then
  try
    // succeeded, so write data returned to display
    mmoInfo.Lines.Add('');
    mmoInfo.Lines.Add('NIC');
    mmoInfo.Lines.Add('  Class1 : ' + DoshFormat(Nic.Class1));
    mmoInfo.Lines.Add('  Class2 : ' + DoshFormat(Nic.Class2));
    mmoInfo.Lines.Add('  Max NICs : ' + BoolToStr(Nic.MaxNICs));
    // or do something more useful with it
    // ...
  finally
    Nic.Free;
  end  // if success
  else
    DoError(errcode);
end;

(*****************************************************************************
*  Call the tax endpoint.                                                    *
*****************************************************************************)
procedure TfrmTestSA.DoTax;
var
  errcode: integer;
  Income: TSAIncome;
  Taxed: TSAIndividualTax;
begin
  Taxed := OTestClient.GetTax(cbxYear.Text, errcode);
  if (Assigned(Taxed)) then
  try
    // succeeded, so write data returned to display
    mmoInfo.Lines.Add('');
    mmoInfo.Lines.Add('Tax');
    // benefits
    mmoInfo.Lines.Add('Benefits');
    mmoInfo.Lines.Add('  Annuities : ' + DoshFormat(Taxed.Benefits.OPRA));
    mmoInfo.Lines.Add('  Incapacity : ' + DoshFormat(Taxed.Benefits.IBen));
    // and pay
    mmoInfo.Lines.Add('Pay');
    for Income in Taxed.PayList do
    begin
      mmoInfo.Lines.Add('  PayeRef : ' + Income.PayeRef);
      mmoInfo.Lines.Add('  Pay : ' + DoshFormat(Income.Pay));
    end;
    mmoInfo.Lines.Add('Refunds');
    mmoInfo.Lines.Add('  Refund : ' + DoshFormat(Taxed.TaxRefund));
    // or do something more useful with it
    // ...
  finally
    Taxed.Free;
  end  // if success
  else
    DoError(errcode);
end;



(*****************************************************************************
*                         PROPERTY METHODS SECTION                           *
******************************************************************************
*  Set the AppValues. (override).                                            *
*****************************************************************************)
procedure TfrmTestSA.SetAppValues(Values: TAppValues);
begin
  inherited;

  // add the anti-fraud headers
  AddHeaders(OTestClient, FAppValues);
end;

(*****************************************************************************
*  Set the client details.                                                   *
*****************************************************************************)
procedure TfrmTestSA.SetDetails(const Value: THmrcClientDetails);
begin
  inherited;

  OTestClient.ClientId     := ODetails.ClientId;
  OTestClient.ClientSecret := ODetails.ClientSecret;
  OTestClient.CallbackPort := ODetails.CallbackPort;
  OTestClient.CallbackUrl  := ODetails.CallbackUrl;
  OTestClient.ServerToken  := ODetails.ServerToken;
end;


end.
