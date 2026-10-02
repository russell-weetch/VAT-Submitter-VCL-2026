unit fTestClient;

(*****************************************************************************
*                HMRC PAYE API REST Test Application SA Form                 *
******************************************************************************
*                                VCL FORMS                                   *
******************************************************************************
*  A simple form to test the SA endpoints and display the results to the     *
*  screen. A copy of the vat demos test form.                                *
*                                                                            *
******************************************************************************
*  created  28/12/20    Based on the existing VAT client tests.              *
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
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.Imaging.pngimage, Vcl.ExtCtrls,
  HmrcRestSupport, HmrcRestClient, HmrcTestSupport, HmrcTestClient, HmrcHeaders,
  fVclHmrcBase;
(****************************************************************************)

type
  TfrmTestClient = class(TfrmVclHmrcBase)
    btnHelloWorld: TBitBtn;
    btnHelloApp: TBitBtn;
    btnHelloUser: TBitBtn;
    btnHeaders: TBitBtn;
    btnAgent: TBitBtn;
    btnCo: TBitBtn;
    btnPerson: TBitBtn;
    btnServices: TBitBtn;
    mmoInfo: TMemo;
    procedure btnAgentClick(Sender: TObject);
    procedure btnCoClick(Sender: TObject);
    procedure btnHeadersClick(Sender: TObject);
    procedure btnHelloAppClick(Sender: TObject);
    procedure btnHelloUserClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnHelloWorldClick(Sender: TObject);
    procedure btnPersonClick(Sender: TObject);
    procedure btnServicesClick(Sender: TObject);
  private
    OTestClient : THmrcTestClient;
    procedure SaveResponse(const Iza, Value: string);   // save the user details to Users.txt
  protected
    procedure SetDetails(const Value: THmrcClientDetails); override;
  public
  end;


(****************************************************************************)
implementation
(****************************************************************************)
uses
  System.JSON,
  IniFiles;

{$R *.dfm}

(*****************************************************************************
*                         HMRC TEST CLIENT FORM                              *
******************************************************************************
*                             INIT SECTION                                   *
******************************************************************************
*  Init.                                                                     *
*****************************************************************************)
procedure TfrmTestClient.FormCreate(Sender: TObject);
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
*  Create a new user as an Agent.                                            *
*****************************************************************************)
procedure TfrmTestClient.btnAgentClick(Sender: TObject);
begin
  // disable other services
  //btnCo.Enabled := false;
  //btnPerson.Enabled := false;
  //btnServices.Enabled := false;

  mmoInfo.Lines.Add('');
  // call api
  if (OTestClient.AddAgent = RESULT_OK) then
  begin
    mmoInfo.Lines.Add(OTestClient.LastValue.ToString);
    SaveResponse('Agent', OTestClient.LastValue.ToString);
  end
  else begin
    mmoInfo.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' + OTestClient.LastMsg);
    mmoInfo.Lines.Add(OTestClient.LastError);
  end;
end;

(*****************************************************************************
*  Create a new user as a company.                                           *
*****************************************************************************)
procedure TfrmTestClient.btnCoClick(Sender: TObject);
begin
  // disable other services
  //btnAgent.Enabled := false;
  //btnPerson.Enabled := false;
  //btnServices.Enabled := false;

  mmoInfo.Lines.Add('');
  // call api
  if (OTestClient.AddCompany = RESULT_OK) then
  begin
    mmoInfo.Lines.Add(OTestClient.LastValue.ToString);
    SaveResponse('Company', OTestClient.LastValue.ToString);
  end
  else begin
    mmoInfo.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' + OTestClient.LastMsg);
    mmoInfo.Lines.Add(OTestClient.LastError);
  end;
end;

(*****************************************************************************
*  Call test fraud headers.                                                  *
*****************************************************************************)
procedure TfrmTestClient.btnHeadersClick(Sender: TObject);
begin
  mmoInfo.Lines.Add('Testing Anti-Fraud Headers');

  AddHeaders(OTestClient, FAppValues);

  if (OTestClient.TestFraudHeaders = RESULT_OK) then
  begin
    mmoInfo.Lines.Add(OTestClient.LastValue.ToString);
  end
  else begin
    mmoInfo.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' + OTestClient.LastMsg);
    mmoInfo.Lines.Add(OTestClient.LastError);
  end;
end;

(*****************************************************************************
*  Call Hello/Application.                                                   *
*****************************************************************************)
procedure TfrmTestClient.btnHelloAppClick(Sender: TObject);
begin
  mmoInfo.Lines.Add('');
  mmoInfo.Lines.Add(OTestClient.TestHelloApplication);
end;

(*****************************************************************************
*  Call Hello/User.                                                          *
*****************************************************************************)
procedure TfrmTestClient.btnHelloUserClick(Sender: TObject);
begin
  mmoInfo.Lines.Add('');
  mmoInfo.Lines.Add(OTestClient.TestHelloUser);
end;

(*****************************************************************************
*  Call Hello/World.                                                         *
*****************************************************************************)
procedure TfrmTestClient.btnHelloWorldClick(Sender: TObject);
begin
  mmoInfo.Lines.Add('');
  mmoInfo.Lines.Add(OTestClient.TestHelloWorld);
end;

(*****************************************************************************
*  Create a new user as an individual.                                       *
*****************************************************************************)
procedure TfrmTestClient.btnPersonClick(Sender: TObject);
begin
  // disable other services
  //btnCo.Enabled := false;
  //btnAgent.Enabled := false;
  //btnServices.Enabled := false;

  mmoInfo.Lines.Add('');
  // call api
  if (OTestClient.AddPerson = RESULT_OK) then
  begin
    mmoInfo.Lines.Add(OTestClient.LastValue.ToString);
    SaveResponse('User', OTestClient.LastValue.ToString);
  end
  else begin
    mmoInfo.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' + OTestClient.LastMsg);
    mmoInfo.Lines.Add(OTestClient.LastError);
  end;
end;

(*****************************************************************************
*  Get the list of services available in the test service.                   *
*****************************************************************************)
procedure TfrmTestClient.btnServicesClick(Sender: TObject);
begin
  // disable other services
  //btnCo.Enabled := false;
  //btnAgent.Enabled := false;
  //btnPerson.Enabled := false;

  mmoInfo.Lines.Add('');
  // call api
  if (OTestClient.GetServices = RESULT_OK) then
  begin
    mmoInfo.Lines.Add(OTestClient.LastValue.ToString);
  end
  else begin
    mmoInfo.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' + OTestClient.LastMsg);
    mmoInfo.Lines.Add(OTestClient.LastError);
  end;
end;



(*****************************************************************************
*                         FILE SAVE METHODS SECTION                          *
******************************************************************************
*  Save the new user details.                                                *
*****************************************************************************)
procedure TfrmTestClient.SaveResponse(const Iza, Value: string);
var
  f: TextFile;
begin
  AssignFile(f, FFilePath + 'Users.txt');
  if (FileExists(FFilePath + 'Users.txt')) then
    Append(f)
  else
    Rewrite(f);
  try
    Writeln(f);
    Writeln(f, '// ' + Iza);
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
procedure TfrmTestClient.SetDetails(const Value: THmrcClientDetails);
begin
  inherited;

  OTestClient.ClientId     := ODetails.ClientId;
  OTestClient.ClientSecret := ODetails.ClientSecret;
  OTestClient.CallbackPort := ODetails.CallbackPort;
  OTestClient.CallbackUrl  := ODetails.CallbackUrl;
  OTestClient.ServerToken  := ODetails.ServerToken;
  //OTestClient.BaseUrl      := ODetails.BaseUrl;

  OTestClient.UID := ODetails.ClientId;
end;


end.
