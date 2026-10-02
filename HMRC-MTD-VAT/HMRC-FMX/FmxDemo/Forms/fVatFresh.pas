unit fVatFresh;

(*****************************************************************************
*                       VAT With Fresh Login Test Form                       *
******************************************************************************
*  This form demonstrates calls to the 5 VAT API end points. Responses are   *
*  written to the memo, but would be processed in a meaningful way.          *
*  It does not save tokens, so requires a fresh login by the user for each   *
*  call to the HMRC API for a new user and scope. When calling the API for   *
*  the first time for a given user id and scope, it will prompt the user to  *
*  login and grant authority. After doing this, it will be necessary to call *
*  the API process again. It will retain the access token while the          *
*  application is running, so further calls for this user and scope may be   *
*  made without logging in again.                                            *
*                                                                            *
*  This code may be freely copied and adapted, if it helps, but note that it *
*  is, or a least was illegal to to either type or paste the values into     *
*  elements like the edit boxes here, in order to submit vat returns.        *
*                                                                            *
*  created 22/12/18.                                                         *
*  updated 08/01/19.                                                         *
*  updated 16/12/20.   Added working fraud headers.                          *
*  updated 28/01/21.   Added updated fraud headers.                          *
*  version 1.0.2                                                             *
*                                                                            *
*****************************************************************************)

interface
(****************************************************************************)

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit, FMX.NumberBox,
  FMX.ScrollBox, FMX.Memo, FMX.ListBox, FMX.DateTimeCtrls, FMX.EditBox,
  HmrcRestSupport, HmrcRestClient, HmrcVatClient, HmrcHeaders, FMX.Layouts, FMX.ExtCtrls;
(****************************************************************************)

type
  TfrmVatFresh = class(TForm)
    Label1: TLabel;
    edtUID: TEdit;
    btnLiabilities: TCornerButton;
    btnObligations: TCornerButton;
    btnPayments: TCornerButton;
    btnView: TCornerButton;
    btnSubmit: TCornerButton;
    mmoInfo: TMemo;
    Label2: TLabel;
    dtpFrom: TDateEdit;
    dtpTo: TDateEdit;
    Label3: TLabel;
    Label4: TLabel;
    edtViewPeriod: TEdit;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    edtDueOnSales: TNumberBox;
    edtDueOnAqu: TNumberBox;
    edtTotalDue: TNumberBox;
    edtReclaim: TNumberBox;
    edtNetDue: TNumberBox;
    edtSalesEx: TNumberBox;
    edtPurchaseEx: TNumberBox;
    edtGoodsEx: TNumberBox;
    edtAquEx: TNumberBox;
    cbxFinalised: TComboBox;
    edtSubmitPeriod: TEdit;
    edtStatus: TEdit;
    Label18: TLabel;
    ImageViewer1: TImageViewer;
    Label19: TLabel;
    Label20: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnLiabilitiesClick(Sender: TObject);
    procedure btnObligationsClick(Sender: TObject);
    procedure btnPaymentsClick(Sender: TObject);
    procedure btnSubmitClick(Sender: TObject);
    procedure btnViewClick(Sender: TObject);
    procedure edtUIDExit(Sender: TObject);
  private
    FAppValues  : TAppValues;             // application settings for the vat headers
    ODetails    : THmrcClientDetails;
    OTestClient : THmrcVATClient;
    function  ListValues: TStringList;                      // write the vat data for submission to a string list
    procedure SetDetails(const Value: THmrcClientDetails);  // set the client details in the rest client
  public
    procedure SetAppValues(Values: TAppValues);
    property ClientDetails : THmrcClientDetails read ODetails   write SetDetails;
  end;


(****************************************************************************)
implementation
(****************************************************************************)
uses
  IPPeerClient, REST.Types, REST.Client, REST.Authenticator.OAuth, REST.Utils,
  System.JSON, IniFiles, Contnrs,
  HmrcVatSupport;

{$R *.fmx}

(*****************************************************************************
*                         HMRC VAT CLIENT FORM                               *
******************************************************************************
*                             INIT SECTION                                   *
******************************************************************************
*  Init.                                                                     *
*****************************************************************************)
procedure TfrmVatFresh.FormCreate(Sender: TObject);
begin
  OTestClient := THmrcVATClient.Create(Self);

  // set test mode
  OTestClient.IzTest := true;    // by default it targets the live api service
end;


(*****************************************************************************
*                          BUTTON CLICKS SECTION                             *
******************************************************************************
*  Liabilities / Obligations / Payments                                      *
*  Call the search API method with the appropriate end point and the current *
*  search dates. If there is no access token, the user will see the login    *
*  form and will then need to call the search api again.                     *
******************************************************************************
*  Call the liabilities end point with the current search dates.             *
*****************************************************************************)
procedure TfrmVatFresh.btnLiabilitiesClick(Sender: TObject);
var
  XCorId: string;
begin
  XCorId := '';
  mmoInfo.Lines.Add('');
  if (OTestClient.GetLiabilities(dtpFrom.Date, dtpTo.Date, XCorId) = RESULT_OK) then
  begin
    // succeeded, so write data returned to display
    mmoInfo.Lines.Add(OTestClient.LastValue.ToString);
    mmoInfo.Lines.Add('Correlation Id : ' + XCorId);
    // or do something more useful with it
    // ...
  end
  // check whether it failed because there was no access token
  else if (OTestClient.LastCode = ERR_NO_ACCESS_TOKEN) then
  begin
    // so get a new access token
    OTestClient.NewAccessToken;
    // now the user needs to call the api again
    mmoInfo.Lines.Add('Please call the liabilities API again, after authority has been granted');
  end
  else begin
    // failed, so write error info to display
    mmoInfo.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' + OTestClient.LastMsg);
    mmoInfo.Lines.Add(OTestClient.LastError);
    // or handle it some other way ...
  end;
end;

(*****************************************************************************
*  Call the obligations end point with the current search dates.             *
*****************************************************************************)
procedure TfrmVatFresh.btnObligationsClick(Sender: TObject);
var
  ix1: integer;
  XCorId: string;
  XList: TObjectList;
  VatObj: TVatObligation;
begin
  XCorId := '';
  mmoInfo.Lines.Add('');
  if (OTestClient.GetObligations(dtpFrom.Date, dtpTo.Date, XCorId, Trim(edtStatus.Text)) = RESULT_OK) then
  begin
    // succeeded, so write data returned to display
    mmoInfo.Lines.Add(OTestClient.LastValue.ToString);
    mmoInfo.Lines.Add('Correlation Id : ' + XCorId);
    // or do something more useful with it
    // now convert the json into a list of vat obligation objects and write their values to the screen
    XList := HmrcVatSupport.ParseObligations(XCorId, OTestClient.LastValue);
    if (Assigned(XList)) then
    try
      for ix1 := 0 to XList.Count - 1 do
      begin
        VatObj := TVatObligation(XList[ix1]);
        mmoInfo.Lines.Add(VatObj.Periodkey);
        mmoInfo.Lines.Add(VatObj.XCorId);
        mmoInfo.Lines.Add(VatObj.Status);
        mmoInfo.Lines.Add(DateToStr(VatObj.Start));
        mmoInfo.Lines.Add(DateToStr(VatObj.Stop));
        mmoInfo.Lines.Add(DateToStr(VatObj.DueBy));
        mmoInfo.Lines.Add(DateToStr(VatObj.Received));
      end;  // for
    finally
      XList.Free;
    end;
  end
  // check whether it failed because there was no access token
  else if (OTestClient.LastCode = ERR_NO_ACCESS_TOKEN) then
  begin
    // so get a new access token
    OTestClient.NewAccessToken;
    // now the user needs to call the api again
    mmoInfo.Lines.Add('Please call the obligations API again, after authority has been granted');
  end
  else begin
    // failed, so write error info to display
    mmoInfo.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' + OTestClient.LastMsg);
    mmoInfo.Lines.Add(OTestClient.LastError);
    // or handle it some other way ...
  end;
end;

(*****************************************************************************
*  Call the payments end point with the current search dates.                *
*****************************************************************************)
procedure TfrmVatFresh.btnPaymentsClick(Sender: TObject);
var
  XCorId: string;
begin
  XCorId := '';
  mmoInfo.Lines.Add('');
  if (OTestClient.GetPayments(dtpFrom.Date, dtpTo.Date, XCorId) = RESULT_OK) then
  begin
    // succeeded, so write data returned to display
    mmoInfo.Lines.Add(OTestClient.LastValue.ToString);
    mmoInfo.Lines.Add('Correlation Id : ' + XCorId);
    // or do something more useful with it
    // ...
  end
  // check whether it failed because there was no access token
  else if (OTestClient.LastCode = ERR_NO_ACCESS_TOKEN) then
  begin
    // so get a new access token
    OTestClient.NewAccessToken;
    // now the user needs to call the api again
    mmoInfo.Lines.Add('Please call the payments API again, after authority has been granted');
  end
  else begin
    // failed, so write error info to display
    mmoInfo.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' + OTestClient.LastMsg);
    mmoInfo.Lines.Add(OTestClient.LastError);
    // or handle it some other way ...
  end;
end;


(*****************************************************************************
*  Call the submit returns end point with the current returns values.        *
*  If there is no access token, the user will see the login form and will    *
*  then need to call view returns again.                                     *
*****************************************************************************)
procedure TfrmVatFresh.btnSubmitClick(Sender: TObject);
var
  idx: integer;
  lvFinal : boolean;
  lvText  : string;
  InList  : TStringList;
  OutList : TStringList;
begin
  mmoInfo.Lines.Add('');
  // prepare data
  InList := ListValues;
  OutList := nil;
  if (cbxFinalised.ItemIndex = 0) then
    lvFinal := true
  else
    lvFinal := false;

  try
    if (OTestClient.SubmitReturn(edtSubmitPeriod.Text, InList, lvFinal, lvText) = RESULT_OK) then
    begin
      // succeeded, so write data returned to display
      mmoInfo.Lines.Add(OTestClient.LastValue.ToString);
      if (lvText <> '') then
      begin
        OutList := TStringList.Create;
        try
          OutList.Delimiter := ';';
          OutList.DelimitedText := lvText;
          for idx := 0 to OutList.Count - 1 do
            mmoInfo.Lines.Add(OutList[idx]);
        finally
          OutList.Free;
        end;
      end;
      // or do something more meaningful ...
    end
    // check whether it failed because there was no access token
    else if (OTestClient.LastCode = ERR_NO_ACCESS_TOKEN) then
    begin
      // so get a new access token
      OTestClient.NewAccessToken;
      // now the user needs to call the api again
      mmoInfo.Lines.Add('Please call the Submit Return API again, after authority has been granted');
    end
    else begin
      // failed, so write error info to display
      mmoInfo.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' + OTestClient.LastMsg);
      mmoInfo.Lines.Add(OTestClient.LastError);
      // or handle it some other way ...
    end;
  finally
    if (Assigned(InList)) then
      InList.Free;
  end;
end;

(*****************************************************************************
*  Call the view returns end point with the current search period.           *
*  If there is no access token, the user will see the login form and will    *
*  then need to call submit returns again.                                   *
*****************************************************************************)
procedure TfrmVatFresh.btnViewClick(Sender: TObject);
var
  XCorId: string;
begin
  XCorId := '';
  mmoInfo.Lines.Add('');
  if (OTestClient.GetReturn(edtViewPeriod.Text, XCorId) = RESULT_OK) then
  begin
    // succeeded, so write data returned to display
    mmoInfo.Lines.Add(OTestClient.LastValue.ToString);
    mmoInfo.Lines.Add('Correlation Id : ' + XCorId);
    // or do something more meaningful ...
  end
  // check whether it failed because there was no access token
  else if (OTestClient.LastCode = ERR_NO_ACCESS_TOKEN) then
  begin
    // so get a new access token
    OTestClient.NewAccessToken;
    // now the user needs to call the api again
    mmoInfo.Lines.Add('Please call the View Returns API again, after authority has been granted');
  end
  else begin
    // failed, so write error info to display
    mmoInfo.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' + OTestClient.LastMsg);
    mmoInfo.Lines.Add(OTestClient.LastError);
    // or handle it some other way ...
  end;
end;

(*****************************************************************************
*  Set the HMRC user id. This should be the user VRN value.                  *
*****************************************************************************)
procedure TfrmVatFresh.edtUIDExit(Sender: TObject);
begin
  if (OTestClient.SetHmrcId(edtUID.Text) <> RESULT_OK) then
    ShowMessage('Error setting user id : ' + #13#10 + OTestClient.LastError);
end;

(*****************************************************************************
*                           API METHODS SECTION                              *
******************************************************************************
*  Build list of submission values.                                          *
*****************************************************************************)
function TfrmVatFresh.ListValues: TStringList;
begin
  Result := TStringList.Create;
  Result.NameValueSeparator := '=';

  Result.Add('vatDueSales=' + FloatToStr(edtDueOnSales.Value));
  Result.Add('vatDueAcquisitions=' + FloatToStr(edtDueOnAqu.Value));
  Result.Add('totalVatDue=' + FloatToStr(edtTotalDue.Value));
  Result.Add('vatReclaimedCurrPeriod=' + FloatToStr(edtReclaim.Value));
  Result.Add('netVatDue=' + FloatToStr(edtNetDue.Value));
  Result.Add('totalValueSalesExVAT=' + FloatToStr(edtSalesEx.Value));
  Result.Add('totalValuePurchasesExVAT=' + FloatToStr(edtPurchaseEx.Value));
  Result.Add('totalValueGoodsSuppliedExVAT=' + FloatToStr(edtGoodsEx.Value));
  Result.Add('totalAcquisitionsExVAT=' + FloatToStr(edtAquEx.Value));
end;

(*****************************************************************************
*                         PROPERTY METHODS SECTION                           *
******************************************************************************
*  Set the AppValues.                                                        *
*****************************************************************************)
procedure TfrmVatFresh.SetAppValues(Values: TAppValues);
begin
  FAppValues := Values;

  // add the anti-fraud headers
  AddHeaders(OTestClient, FAppValues);
end;

(*****************************************************************************
*  Set the client details.                                                   *
*****************************************************************************)
procedure TfrmVatFresh.SetDetails(const Value: THmrcClientDetails);
begin
  ODetails := Value;
  OTestClient.ClientId     := ODetails.ClientId;
  OTestClient.ClientSecret := ODetails.ClientSecret;
  OTestClient.CallbackPort := ODetails.CallbackPort;
  OTestClient.CallbackUrl  := ODetails.CallbackUrl;
  OTestClient.ServerToken  := ODetails.ServerToken;
  OTestClient.BaseUrl      := ODetails.BaseUrl;
end;


end.
