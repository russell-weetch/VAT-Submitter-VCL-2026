unit fTestClient;

(*****************************************************************************
*                          HMRC API REST Test Form                           *
******************************************************************************
*  This tests the 3 Hello... end points, tests the anit-fraud headers and    *
*  creates new users on the HMRC test system.                                *
*                                                                            *
*  For the hello/user endpoint, if successful, the access token will be      *
*  saved in a file called CurrentTokens.ini in the same folder as the client *
*  details.                                                                  *
*  For new agents/orgs/users, it only allows one create function at a time,  *
*  because when testing, subsequent calls always retained the service types  *
*  from the first call. New user details are saved to Users.txt.             *
*                                                                            *
*  created 22/12/18.                                                         *
*  updated 14/12/20.                                                         *
*  updated 28/01/21.   Added updated fraud headers.                          *
*  version 1.0.2                                                             *
*                                                                            *
*****************************************************************************)

interface
(****************************************************************************)

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ScrollBox, FMX.Memo,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit,
  HmrcRestClient, HmrcRestSupport, HmrcTestClient, HmrcTestSupport, HmrcHeaders, FMX.Layouts, FMX.ExtCtrls;

(****************************************************************************)

type
  TfrmTestClient = class(TForm)
    btnWorld: TCornerButton;
    btnApp: TCornerButton;
    btnUser: TCornerButton;
    btnAgent: TCornerButton;
    btnCompany: TCornerButton;
    btnPerson: TCornerButton;
    mmoResponse: TMemo;
    edtUID: TEdit;
    Label1: TLabel;
    btnServices: TCornerButton;
    btnHeaders: TCornerButton;
    ImageViewer1: TImageViewer;
    procedure FormCreate(Sender: TObject);
    procedure btnAgentClick(Sender: TObject);
    procedure btnAppClick(Sender: TObject);
    procedure btnCompanyClick(Sender: TObject);
    procedure btnHeadersClick(Sender: TObject);
    procedure btnPersonClick(Sender: TObject);
    procedure btnServicesClick(Sender: TObject);
    procedure btnUserClick(Sender: TObject);
    procedure btnWorldClick(Sender: TObject);
    procedure edtUIDDblClick(Sender: TObject);
  private
    FAppValues  : TAppValues;             // application settings for the vat headers
    FFilePath   : string;
    OTestClient : THmrcTestClient;
    ODetails: THmrcClientDetails;
    procedure LoadTokens(const AValue: string);     // load application access token
    procedure SaveUser(const Iza, Value: string);   // save the user details to Users.txt
    procedure SaveToken(Sender: TObject; const uid, scp, atn, rtn: string; const exp, tmo: TDateTime);
                                                    // save the supplied token details to file
    procedure SetDetails(const Value: THmrcClientDetails);      // set client details
  public
    procedure SetAppValues(Values: TAppValues);
    property ClientDetails : THmrcClientDetails read ODetails   write SetDetails;
    property FilePath      : string             read FFilePath  write FFilePath;
  end;


(****************************************************************************)
implementation
(****************************************************************************)
uses
  IPPeerClient, REST.Types, REST.Client, REST.Utils, REST.Authenticator.OAuth,
  System.JSON, IniFiles;

{$R *.fmx}

(*****************************************************************************
*                         HMRC TEST CLIENT FORM                              *
******************************************************************************
*                             INIT SECTION                                   *
******************************************************************************
*  Init.                                                                     *
*****************************************************************************)
procedure TfrmTestClient.FormCreate(Sender: TObject);
begin
  OTestClient := THmrcTestClient.Create(Self);

  OTestClient.IzTest := true;    // by default it targets the live api service
  OTestClient.OnTokenChange := SaveToken;  // this should automate token saving

end;


(*****************************************************************************
*                          BUTTON CLICKS SECTION                             *
******************************************************************************
*  Create a new user as an Agent.                                            *
*****************************************************************************)
procedure TfrmTestClient.btnAgentClick(Sender: TObject);
begin
  btnCompany.Enabled := false;
  btnPerson.Enabled := false;
  btnServices.Enabled := false;

  mmoResponse.Lines.Add('');
  if (OTestClient.AddAgent = RESULT_OK) then
  begin
    mmoResponse.Lines.Add(OTestClient.LastValue.ToString);
    SaveUser('Agent', OTestClient.LastValue.ToString);
  end
  else begin
    mmoResponse.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' +
                          OTestClient.LastMsg);
    mmoResponse.Lines.Add(OTestClient.LastError);
  end;
end;

(*****************************************************************************
*  Call Hello/Application.                                                   *
*****************************************************************************)
procedure TfrmTestClient.btnAppClick(Sender: TObject);
begin
  mmoResponse.Lines.Add('');

  mmoResponse.Lines.Add(OTestClient.TestHelloApplication);
end;

(*****************************************************************************
*  Create a new user as a company.                                           *
*****************************************************************************)
procedure TfrmTestClient.btnCompanyClick(Sender: TObject);
begin
  btnAgent.Enabled := false;
  btnPerson.Enabled := false;
  btnServices.Enabled := false;

  mmoResponse.Lines.Add('');
  if (OTestClient.AddCompany = RESULT_OK) then
  begin
    mmoResponse.Lines.Add(OTestClient.LastValue.ToString);
    SaveUser('Company', OTestClient.LastValue.ToString);
  end
  else begin
    mmoResponse.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' +
                          OTestClient.LastMsg);
    mmoResponse.Lines.Add(OTestClient.LastError);
  end;
end;

(*****************************************************************************
*  Call test fraud headers.                                                  *
*****************************************************************************)
procedure TfrmTestClient.btnHeadersClick(Sender: TObject);
begin
  mmoResponse.Lines.Add('Testing Anti-Fraud Headers');

  AddHeaders(OTestClient, FAppValues);

  if (OTestClient.TestFraudHeaders = RESULT_OK) then
  begin
    mmoResponse.Lines.Add(OTestClient.LastValue.ToString);
  end
  else begin
    mmoResponse.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' +
                          OTestClient.LastMsg);
    mmoResponse.Lines.Add(OTestClient.LastError);
  end;
end;

(*****************************************************************************
*  Create a new user as an individual.                                       *
*****************************************************************************)
procedure TfrmTestClient.btnPersonClick(Sender: TObject);
begin
  btnCompany.Enabled := false;
  btnAgent.Enabled := false;
  btnServices.Enabled := false;

  mmoResponse.Lines.Add('');
  if (OTestClient.AddPerson = RESULT_OK) then
  begin
    mmoResponse.Lines.Add(OTestClient.LastValue.ToString);
    SaveUser('User', OTestClient.LastValue.ToString);
  end
  else begin
    mmoResponse.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' +
                          OTestClient.LastMsg);
    mmoResponse.Lines.Add(OTestClient.LastError);
  end;
end;

(*****************************************************************************
*  Get the list of services available in the test service.                   *
*****************************************************************************)
procedure TfrmTestClient.btnServicesClick(Sender: TObject);
begin
  btnCompany.Enabled := false;
  btnAgent.Enabled := false;
  btnPerson.Enabled := false;

  mmoResponse.Lines.Add('');
  if (OTestClient.GetServices = RESULT_OK) then
  begin
    mmoResponse.Lines.Add(OTestClient.LastValue.ToString);
  end
  else begin
    mmoResponse.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' +
                          OTestClient.LastMsg);
    mmoResponse.Lines.Add(OTestClient.LastError);
  end;
end;

(*****************************************************************************
*  Call Hello/User.                                                          *
*****************************************************************************)
procedure TfrmTestClient.btnUserClick(Sender: TObject);
begin
  mmoResponse.Lines.Add('');

  mmoResponse.Lines.Add(OTestClient.TestHelloUser);
end;

(*****************************************************************************
*  Call Hello/World.                                                         *
*****************************************************************************)
procedure TfrmTestClient.btnWorldClick(Sender: TObject);
begin
  mmoResponse.Lines.Add('');

  mmoResponse.Lines.Add(OTestClient.TestHelloWorld);
end;

(*****************************************************************************
*  Set the HMRC user id. This should be the user id value.                   *
*****************************************************************************)
procedure TfrmTestClient.edtUIDDblClick(Sender: TObject);
begin
  if (OTestClient.SetHmrcId(edtUID.Text) <> RESULT_OK) then
    ShowMessage('Error setting user id : ' + #13#10 + OTestClient.LastError);
end;


(*****************************************************************************
*                       FILE LOAD/SAVE METHODS SECTION                       *
******************************************************************************
*  Load application access token.                                            *
*****************************************************************************)
procedure TfrmTestClient.LoadTokens(const AValue: string);
var
  lvAccess  : string;
  lvTemp    : string;
  lvExpires : TDateTime;
  f : TIniFile;
begin
  f := TIniFile.Create(FFilePath + 'CurrentTokens.ini');
  try
    if (f.SectionExists(AValue)) then
    begin
      lvAccess  := f.ReadString(AValue, 'default', '');
      lvTemp    := f.ReadString(AValue, 'Expires', '');
      lvExpires := StrToDateTimeDef(lvTemp,Now);

      OTestClient.AppToken := lvAccess;
      OTestClient.TokenExpiry := lvExpires;
    end;
  finally
    f.Free;
  end;
end;

(*****************************************************************************
*  Save the new user details.                                                *
*****************************************************************************)
procedure TfrmTestClient.SaveUser(const Iza, Value: string);
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
*  Save these details to the tokens file.                                    *
*****************************************************************************)
procedure TfrmTestClient.SaveToken(Sender: TObject; const uid, scp, atn, rtn: string; const exp, tmo: TDateTime);
var
  f : TIniFile;
begin
  mmoResponse.Lines.Add('');

  mmoResponse.Lines.Add(uid + ' : ' + scp + ' : ' + atn);

  f := TIniFile.Create(FFilePath + 'CurrentTokens.ini');
  try
    f.WriteString(uid, scp, atn);
    f.WriteString(uid, 'Expires', DateTimeToStr(exp));
  finally
    f.Free;
  end;
end;


(*****************************************************************************
*                         PROPERTY METHODS SECTION                           *
******************************************************************************
*  Set the AppValues.                                                        *
*****************************************************************************)
procedure TfrmTestClient.SetAppValues(Values: TAppValues);
begin
  FAppValues := Values;
end;

(*****************************************************************************
*  Set the client details.                                                   *
*****************************************************************************)
procedure TfrmTestClient.SetDetails(const Value: THmrcClientDetails);
begin
  ODetails := Value;
  OTestClient.ClientId     := ODetails.ClientId;
  OTestClient.ClientSecret := ODetails.ClientSecret;
  OTestClient.CallbackPort := ODetails.CallbackPort;
  OTestClient.CallbackUrl  := ODetails.CallbackUrl;
  OTestClient.ServerToken  := ODetails.ServerToken;
  OTestClient.BaseUrl      := ODetails.BaseUrl;

  LoadTokens(ODetails.ClientId);
end;



end.
