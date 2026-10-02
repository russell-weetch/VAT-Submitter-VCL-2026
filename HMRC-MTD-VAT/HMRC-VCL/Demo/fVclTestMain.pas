unit fVclTestMain;

(*****************************************************************************
*                         VCL VAT Checks Test Form                           *
******************************************************************************
*  This form demonstrates calls to the VRN Check API and VAT API end points. *
*                                                                            *
*  created 16/12/20.                                                         *
*  updated 16/12/20.                                                         *
*  version 1.0.0                                                             *
*                                                                            *
*****************************************************************************)

interface
(****************************************************************************)

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.WinXPickers,
  System.UITypes, System.JSON,
  HmrcRestSupport, HmrcRestClient, HmrcTestClient, HmrcTestSupport, HmrcVatClient, HmrcHeaders, Vcl.Imaging.pngimage,
  Vcl.ExtCtrls;
(****************************************************************************)

type
  TfrmVclTestMain = class(TForm)
    odlg: TOpenDialog;
    mmoResponse: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    edtUID: TEdit;
    dtpStart: TDatePicker;
    dtpEnd: TDatePicker;
    edtCaller: TEdit;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;
    Label5: TLabel;
    Label6: TLabel;
    edtStatus: TEdit;
    edtPeriod: TEdit;
    Image1: TImage;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure BitBtn5Click(Sender: TObject);
    procedure edtUIDExit(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FAppValues : TAppValues;             // application settings for the vat headers
    FFilePath : string;
    ODetails  : THmrcClientDetails;
    OTester   : THmrcTestClient;
    OVatter   : THmrcVatClient;
    procedure GetVRNObject(aValue: TJSONValue);  // get the VRN response as an object. NB this requires System.JSON in the uses clause

    procedure LoadSettings;              // load application keys from file
    procedure LoadTokens;                // load any stored access tokens for the current user
    procedure SaveToken(Sender: TObject; const uid, scp, atn, rtn: string; const exp, tmo: TDateTime);
                                         // save the supplied token details to file
    procedure VatCheckReturns;           // call the vat api check returns end point
    procedure VatLiabilities;            // call the vat api liabilities end point
    procedure VatObligations;            // call the vat api obligations end point
  public
    { Public declarations }
  end;

var
  frmVclTestMain: TfrmVclTestMain;

(****************************************************************************)
implementation
(****************************************************************************)
uses
  IniFiles, IPPeerClient, REST.Types, REST.Utils, REST.Client, REST.Authenticator.OAuth,
  Contnrs, DateUtils, System.Hash,
  HmrcVatSupport;

{$R *.dfm}

const
  // dummy substitute for the application installation guid
  ApGuid = '{8E4E54BA-B848-4BFB-BF7B-F7B44B00B40A}';

(*****************************************************************************
*                         HMRC VAT CLIENT FORM                               *
******************************************************************************
*                             INIT SECTION                                   *
******************************************************************************
*  Init. Set fraud header values and then add headers to rest clients.       *
*****************************************************************************)
procedure TfrmVclTestMain.FormCreate(Sender: TObject);
begin
  FFilePath := '';

  ODetails := THmrcClientDetails.Create;
  OTester  := THmrcTestClient.Create(Self);
  OVatter  := THmrcVatClient.Create(Self);

  OTester.IzTest := true;
  OVatter.IzTest := true;
  OVatter.OnTokenChange := SaveToken;  // this should automate token saving

  FAppValues.AppGuid := ApGuid;
  FAppValues.AppName := 'HmrcDevTest';
  // your actual license key or some dummy value here - uses System.Hash
  FAppValues.License := THashSHA1.GetHashString('ABC321XYZ');
  // dummy incorrect values to pass the headers test - clearly nonsense for testing only
  FAppValues.MFType  := 'AUTH_CODE';
  FAppValues.MFTime  := Now - 0.01;   // about 15 minutes ago
  FAppValues.MFValue := 'xyz789';     // hash it here to obscure it

  LoadSettings;

  AddHeaders(OTester, FAppValues);
  AddHeaders(OVatter, FAppValues);
end;

(*****************************************************************************
*  Clear up.                                                                 *
*****************************************************************************)
procedure TfrmVclTestMain.FormDestroy(Sender: TObject);
begin
  ODetails.Free;
end;

(*****************************************************************************
*                          BUTTON CLICKS SECTION                             *
******************************************************************************
*  Call the VRN check end point with just the target VRN.                    *
*****************************************************************************)
procedure TfrmVclTestMain.BitBtn1Click(Sender: TObject);
begin
  mmoResponse.Lines.Add('');
  if (OTester.CheckVrn(Trim(edtUID.Text)) = RESULT_OK) then
  begin
    //display the response to show it worked
    mmoResponse.Lines.Add(OTester.LastValue.ToString);
    // or do something more interesting ...
    GetVRNObject(OTester.LastValue);
  end
  else begin
    mmoResponse.Lines.Add('Error ' + IntToStr(OTester.LastCode) + ' ' + OTester.LastMsg);
    mmoResponse.Lines.Add(OTester.LastError);
  end;
end;

(*****************************************************************************
*  Call the VRN check end point with both the target and caller VRNs.        *
*****************************************************************************)
procedure TfrmVclTestMain.BitBtn2Click(Sender: TObject);
begin
  mmoResponse.Lines.Add('');
  if (OTester.CheckVrn(Trim(edtUID.Text), Trim(edtCaller.Text)) = RESULT_OK) then
  begin
    //display the response to show it worked
    mmoResponse.Lines.Add(OTester.LastValue.ToString);
    // or do something more interesting ...
  end
  else begin
    mmoResponse.Lines.Add('Error ' + IntToStr(OTester.LastCode) + ' ' + OTester.LastMsg);
    mmoResponse.Lines.Add(OTester.LastError);
  end;
end;

(*****************************************************************************
*  Call the vat obligations end point.                                       *
*****************************************************************************)
procedure TfrmVclTestMain.BitBtn3Click(Sender: TObject);
begin
  VatObligations;
end;

(*****************************************************************************
*  Call the vat liabilities end point.                                       *
*****************************************************************************)
procedure TfrmVclTestMain.BitBtn4Click(Sender: TObject);
begin
  VatLiabilities;
end;

(*****************************************************************************
*  Call the check vat returns end point.                                     *
*****************************************************************************)
procedure TfrmVclTestMain.BitBtn5Click(Sender: TObject);
begin
  VatCheckReturns;
end;

(*****************************************************************************
*  Set the HMRC user id. This should be the user VRN value. Try to load any  *
*  stored access tokens for this vrn.                                        *
*****************************************************************************)
procedure TfrmVclTestMain.edtUIDExit(Sender: TObject);
begin
  if (not AnsiSameText(edtUID.Text, OVatter.UID)) then
  begin
    if (OVatter.SetHmrcId(edtUID.Text) = RESULT_OK) then
      LoadTokens
    else
      ShowMessage('Error setting user id : ' + #13#10 + OVatter.LastError);
  end;
end;

(*****************************************************************************
*                         KEY/TOKEN METHODS SECTION                          *
******************************************************************************
*  This is a demo, so for simplicity the tokens are saved to an ini file.    *
*  The Date/Time conversions used here are those that worked in the          *
*  development environment used - Tokyo 10.2.3 on W10. It may be necessary   *
*  to change the date/time methods for other setups.                         *
******************************************************************************
*  Load the application keys.                                                *
*****************************************************************************)
procedure TfrmVclTestMain.LoadSettings;
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
    finally
      inf.Free;
    end;

  OTester.ClientId     := ODetails.ClientId;
  OTester.ClientSecret := ODetails.ClientSecret;
  OTester.CallbackPort := ODetails.CallbackPort;
  OTester.CallbackUrl  := ODetails.CallbackUrl;

  OVatter.ClientId     := ODetails.ClientId;
  OVatter.ClientSecret := ODetails.ClientSecret;
  OVatter.CallbackPort := ODetails.CallbackPort;
  OVatter.CallbackUrl  := ODetails.CallbackUrl;

  end;
end;

(*****************************************************************************
*  Load any saved access tokens for the current user.                        *
*****************************************************************************)
procedure TfrmVclTestMain.LoadTokens;
var
  lvTemp    : string;
  lvUid     : string;
  lvAccess  : string;
  lvRefresh : string;
  lvScope   : string;
  lvStops   : TDateTime;
  lvExpires : TDateTime;
  f : TIniFile;
begin
  f := TIniFile.Create(FFilePath + 'CurrentTokens.ini');
  try
    lvUid := edtUID.Text;
    if (f.SectionExists(lvUid)) then
    begin
      lvScope := 'read:vat';
      lvAccess  := f.ReadString(lvUid, lvScope + '_Access', '');
      lvRefresh := f.ReadString(lvUid, lvScope + '_Refresh', '');
      lvTemp    := f.ReadString(lvUid, lvScope + '_Stops', '');
      lvStops   := StrToDateDef(lvTemp,Date);
      lvTemp    := f.ReadString(lvUid, lvScope + '_Expires', '');
      lvExpires := StrToDateTimeDef(lvTemp,Now);

      OVatter.AddaToken(lvUid, lvScope, lvAccess, lvRefresh, lvStops, lvExpires);

      lvScope := 'write:vat';
      lvAccess  := f.ReadString(lvUid, lvScope + '_Access', '');
      lvRefresh := f.ReadString(lvUid, lvScope + '_Refresh', '');
      lvTemp    := f.ReadString(lvUid, lvScope + '_Expires', '');
      lvExpires := StrToDateTimeDef(lvTemp,Now);
      lvTemp    := f.ReadString(lvUid, lvScope + '_Stops', '');
      lvStops   := StrToDateDef(lvTemp,Date);

      OVatter.AddaToken(lvUid, lvScope, lvAccess, lvRefresh, lvStops, lvExpires);
    end;
  finally
    f.Free;
  end;
end;

(*****************************************************************************
*  Save these details to the tokens file.                                    *
*****************************************************************************)
procedure TfrmVclTestMain.SaveToken(Sender: TObject; const uid, scp, atn, rtn: string; const exp, tmo: TDateTime);
var
  f : TIniFile;
begin
  f := TIniFile.Create(FFilePath + 'CurrentTokens.ini');
  try
      f.WriteString(uid, scp + '_Access', atn);
      f.WriteString(uid, scp + '_Refresh', rtn);
      f.WriteString(uid, scp + '_Stops', DateToStr(exp));
      f.WriteString(uid, scp + '_Expires', DateTimeToStr(tmo));
  finally
    f.Free;
  end;
end;


(*****************************************************************************
*                     JSON EXTRACTION METHODS SECTION                        *
******************************************************************************
*  Note that by declaring the data type as TJSONValue it requires            *
*  System.JSON to be included in the uses list.                              *
******************************************************************************
*  Convert the supplied json value into a VRNResponse object and write the   *
*  details to the sceen.                                                     *
*****************************************************************************)
procedure TfrmVclTestMain.GetVRNObject(aValue: TJSONValue);
var
  obj: TVRNResponse;
begin
  obj := HmrcVatSupport.ParseVRNResponse(aValue);
  if Assigned(obj) then
  try
    mmoResponse.Lines.Add('');
    mmoResponse.Lines.Add('VRN response data');
    mmoResponse.Lines.Add('  Name: ' + obj.OrgName);
    mmoResponse.Lines.Add('  Vat No: ' + obj.VatNo);
    mmoResponse.Lines.Add('  Address: ' + obj.Address);
    mmoResponse.Lines.Add('  Postcode: ' + obj.Postcode);
    mmoResponse.Lines.Add('  Country: ' + obj.Country);
  finally
    obj.Free;
  end;
end;


(*****************************************************************************
*                         VAT API METHODS SECTION                            *
******************************************************************************
*  Call the VAT returns end point. Convert the returned json into a returns  *
*  object and write the details to the sceen.                                *
*****************************************************************************)
procedure TfrmVclTestMain.VatCheckReturns;
var
  XCorId: string;
  XResult: integer;
  VatObj : TVatReturn;
begin
  XCorId := '';
  mmoResponse.Lines.Add('');
  // call the api
  XResult := OVatter.GetReturn(edtPeriod.Text, XCorId);
  // and check the result
  if (XResult = RESULT_OK) then
  begin
    // succeeded, so write data returned to display
    mmoResponse.Lines.Add(OVatter.LastValue.ToString);
    mmoResponse.Lines.Add('Correlation Id : ' + XCorId);
    // or do something more meaningful ...

    // going to convert the json into a vat return object and then write the values to the screen.
    VatObj := ParseReturns(XCorId, OVatter.LastValue);
    if (Assigned(VatObj)) then
    try
      mmoResponse.Lines.Add(VatObj.Periodkey);
      mmoResponse.Lines.Add(VatObj.XCorId);
      mmoResponse.Lines.Add(FloatToStr(VatObj.DueOnSales));
      mmoResponse.Lines.Add(FloatToStr(VatObj.DueOnAcquisitions));
      mmoResponse.Lines.Add(FloatToStr(VatObj.TotalVatDue));
      mmoResponse.Lines.Add(FloatToStr(VatObj.VatReclaimedCP));
      mmoResponse.Lines.Add(FloatToStr(VatObj.NetVatDue));
      mmoResponse.Lines.Add(VatObj.SalesExVAT.ToString);
      mmoResponse.Lines.Add(VatObj.PurchasesExVAT.ToString);
      mmoResponse.Lines.Add(VatObj.GoodsExVAT.ToString);
      mmoResponse.Lines.Add(VatObj.AcquisitionsExVAT.ToString);

    finally
      VatObj.Free;
    end;
  end

  // check whether it failed because there was no data
  else if (XResult = RESULT_NODATA) then
  begin
    mmoResponse.Lines.Add('The call worked, but no data was found/returned');
  end

  // check whether it failed because there was no access token
  else if (OVatter.LastCode = ERR_NO_ACCESS_TOKEN) then
  begin
    // so get a new access token
    OVatter.NewAccessToken;
    // now the user needs to call the api again
    mmoResponse.Lines.Add('Please call the View Returns API again, after authority has been granted');
  end

  else begin
    // failed, so write error info to display
    mmoResponse.Lines.Add('Error ' + IntToStr(OVatter.LastCode) + ' ' + OVatter.LastMsg);
    mmoResponse.Lines.Add(OVatter.LastError);
    // or handle it some other way ...
  end;
end;

(*****************************************************************************
*  Call the VAT Liabilities end point. write the returned json to the sceen. *
*****************************************************************************)
procedure TfrmVclTestMain.VatLiabilities;
var
  XCorId: string;
  XResult: integer;
begin
  XCorId := '';
  mmoResponse.Lines.Add('');
  // call the api
  XResult := OVatter.GetLiabilities(dtpStart.Date, dtpEnd.Date, XCorId);
  // and check the result
  if (XResult = RESULT_OK) then
  begin
    // succeeded, so write data returned to display
    mmoResponse.Lines.Add(OVatter.LastValue.ToString);
    mmoResponse.Lines.Add('Correlation Id : ' + XCorId);
    // or do something more useful with it
    // ...
  end

  // check whether it failed because there was no data
  else if (XResult = RESULT_NODATA) then
  begin
    mmoResponse.Lines.Add('The call worked, but no data was found/returned');
  end

  // check whether it failed because there was no access token
  else if (OVatter.LastCode = ERR_NO_ACCESS_TOKEN) then
  begin
    // so get a new access token
    OVatter.NewAccessToken;
    // now the user needs to call the api again
    mmoResponse.Lines.Add('Please call the liabilities API again, after authority has been granted');
  end

  else begin
    // failed, so write error info to display
    mmoResponse.Lines.Add('Error ' + IntToStr(OVatter.LastCode) + ' ' + OVatter.LastMsg);
    mmoResponse.Lines.Add(OVatter.LastError);
    // or handle it some other way ...
  end;
end;

(*****************************************************************************
*  Call the VAT Obligations end point. Convert the returned json into a list *
*  of obligation objects and write their details to the sceen.               *
*****************************************************************************)
procedure TfrmVclTestMain.VatObligations;
var
  ix1: integer;
  XList: TObjectList;
  VatObj: TVatObligation;
begin
  mmoResponse.Lines.Add('');
  // call the api
  XList := OVatter.GetObligations(dtpStart.Date, dtpEnd.Date, '');
  // and check the result
  if (Assigned(XList)) then
  try
    // do whatever is required with the data
    // just displaying it here, because there is nothing else useful to do
    if (XList.Count > 0) then
      for ix1 := 0 to XList.Count - 1 do
      begin
        VatObj := TVatObligation(XList[ix1]);
        mmoResponse.Lines.Add(VatObj.Periodkey);
        mmoResponse.Lines.Add(VatObj.XCorId);
        mmoResponse.Lines.Add(VatObj.Status);
        mmoResponse.Lines.Add(DateToStr(VatObj.Start));
        mmoResponse.Lines.Add(DateToStr(VatObj.Stop));
        mmoResponse.Lines.Add(DateToStr(VatObj.DueBy));
        mmoResponse.Lines.Add(DateToStr(VatObj.Received));
      end;  // for
  finally
    XList.Free;
  end
  // check whether it failed because there was no access token
  else if (OVatter.LastCode = ERR_NO_ACCESS_TOKEN) then
  begin
    // so get a new access token
    OVatter.NewAccessToken;
    // now the user needs to call the api again
    mmoResponse.Lines.Add('Please call the obligations API again, after authority has been granted');
  end
  else begin
    // failed, so write error info to display
    mmoResponse.Lines.Add('Error ' + IntToStr(OVatter.LastCode) + ' ' + OVatter.LastMsg);
    mmoResponse.Lines.Add(OVatter.LastError);
    // or handle it some other way ...
  end;
end;



end.
