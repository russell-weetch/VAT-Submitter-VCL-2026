unit fVatSaved;

(*****************************************************************************
*                  VAT With Saved Access Tokens Test Form                    *
******************************************************************************
*  This form demonstrates calls to the 5 VAT API end points. Responses are   *
*  written to the memo, but would be processed in a meaningful way. It is    *
*  basically the same form as the fresh login example, but uses stored       *
*  access tokens.                                                            *
*                                                                            *
*  It loads and saves access tokens, but requires a fresh login by the user  *
*  when calling the API for the first time for a given user id and scope. In *
*  this case it will prompt the user to login and grant authority. After     *
*  doing this, it will be necessary to call the API process again. Access    *
*  tokens are saved to an ini file for simplicity. This is to demonstrate    *
*  the process, but in a real application, they should be stored in a more   *
*  secure way.                                                               *
*                                                                            *
*  This code may be freely copied and adapted, if it helps, but note that it *
*  is, or a least was illegal to to either type or paste the values into     *
*  elements like the edit boxes here, in order to submit vat returns.        *
*                                                                            *
*  created 22/12/18.                                                         *
*  updated 09/01/19.                                                         *
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
  System.JSON,
  HmrcRestSupport, HmrcRestClient, HmrcVatClient, HmrcVatSupport, HmrcHeaders, FMX.Layouts, FMX.ExtCtrls;
(****************************************************************************)

type
  TfrmVatSaved = class(TForm)
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
    Label18: TLabel;
    edtStatus: TEdit;
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
    FFilePath   : string;
    ODetails    : THmrcClientDetails;
    OTestClient : THmrcVATClient;
    procedure FillSubmission(aObj: TVatSubmission);  // put the data for the submission in the object
    procedure LoadTokens;                // load any stored access tokens for the current user
    procedure ParseObligationsJson(aValue: TJSONValue);  // parse the obligations json returned
    procedure SaveToken(Sender: TObject; const uid, scp, atn, rtn: string; const exp, tmo: TDateTime);
                                         // save the supplied token details to file
    procedure SetDetails(const Value: THmrcClientDetails);  // set the client details in the rest client
  public
    procedure SetAppValues(Values: TAppValues);
    property ClientDetails : THmrcClientDetails read ODetails   write SetDetails;
    property FilePath      : string             read FFilePath  write FFilePath;
  end;


(****************************************************************************)
implementation
(****************************************************************************)
uses
  IPPeerClient, REST.Types, REST.Client, REST.Authenticator.OAuth, REST.Utils,
  Contnrs, IniFiles;

{$R *.fmx}

(*****************************************************************************
*                         HMRC VAT CLIENT FORM                               *
******************************************************************************
*                             INIT SECTION                                   *
******************************************************************************
*  Init.                                                                     *
*****************************************************************************)
procedure TfrmVatSaved.FormCreate(Sender: TObject);
begin
  OTestClient := THmrcVATClient.Create(Self);

  OTestClient.IzTest := true;   // by default it targets the live api service
  OTestClient.OnTokenChange := SaveToken;  // this should automate token saving
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
procedure TfrmVatSaved.btnLiabilitiesClick(Sender: TObject);
var
  XCorId: string;
  XResult: integer;
begin
  XCorId := '';
  mmoInfo.Lines.Add('');
  // call the api
  XResult := OTestClient.GetLiabilities(dtpFrom.Date, dtpTo.Date, XCorId);
  // and check the result
  if (XResult = RESULT_OK) then
  begin
    // succeeded, so write data returned to display
    mmoInfo.Lines.Add(OTestClient.LastValue.ToString);
    mmoInfo.Lines.Add('Correlation Id : ' + XCorId);
    // or do something more useful with it
    // ...
  end

  // check whether it failed because there was no data
  else if (XResult = RESULT_NODATA) then
  begin
    mmoInfo.Lines.Add('The call worked, but no data was found/returned');
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
procedure TfrmVatSaved.btnObligationsClick(Sender: TObject);
var
  XCorId: string;
  XResult: integer;
begin
  XCorId := '';
  mmoInfo.Lines.Add('');
  // call the api
  XResult := OTestClient.GetObligations(dtpFrom.Date, dtpTo.Date, XCorId, Trim(edtStatus.Text));
  // and check the result
  if (XResult = RESULT_OK) then
  begin
    // succeeded, so write data returned to display
    mmoInfo.Lines.Add('Correlation Id : ' + XCorId);
    mmoInfo.Lines.Add(OTestClient.LastValue.ToString);
    // or do something more useful with it ...

    // write the various elements to the screen using the parsing function below
    ParseObligationsJson(OTestClient.LastValue);
  end  // if ok

  // check whether it failed because there was no data
  else if (XResult = RESULT_NODATA) then
  begin
    mmoInfo.Lines.Add('The call worked, but no data was found/returned');
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
procedure TfrmVatSaved.btnPaymentsClick(Sender: TObject);
var
  XCorId: string;
  XResult: integer;
begin
  XCorId := '';
  mmoInfo.Lines.Add('');
  // call the api
  XResult := OTestClient.GetPayments(dtpFrom.Date, dtpTo.Date, XCorId);
  // and check the result
  if (XResult = RESULT_OK) then
  begin
    // succeeded, so write data returned to display
    mmoInfo.Lines.Add(OTestClient.LastValue.ToString);
    mmoInfo.Lines.Add('Correlation Id : ' + XCorId);
    // or do something more useful with it
    // ...
  end

  // check whether it failed because there was no data
  else if (XResult = RESULT_NODATA) then
  begin
    mmoInfo.Lines.Add('The call worked, but no data was found/returned');
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
procedure TfrmVatSaved.btnSubmitClick(Sender: TObject);
var
  idx: integer;
  lvText  : string;
  XResult: integer;
  obj: TVatSubmission;
begin
  mmoInfo.Lines.Add('');
  // prepare data
  obj := TVatSubmission.Create;
  try
    FillSubmission(obj);

    // submit the return with the list of values
    if (OTestClient.SubmitReturn(obj) = RESULT_OK) then
    begin
      // succeeded, so write data returned to display
      mmoInfo.Lines.Add('Correlation Id : ' + obj.XCorId);
      mmoInfo.Lines.Add('Processed : ' + obj.Processed);
      mmoInfo.Lines.Add('Bundle Number : ' + obj.BundleNo);
      mmoInfo.Lines.Add('Payment Indicator : ' + obj.PaymentIdct);
      mmoInfo.Lines.Add('Charge Ref Number  : ' + obj.ChargeRefNo);
      mmoInfo.Lines.Add('Receipt Id : ' + obj.ReceiptId);
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
    obj.Free;
  end;
end;

(*****************************************************************************
*  Call the view returns end point with the current search period.           *
*  If there is no access token, the user will see the login form and will    *
*  then need to call submit returns again.                                   *
*****************************************************************************)
procedure TfrmVatSaved.btnViewClick(Sender: TObject);
var
  XCorId: string;
  XResult: integer;
  VatObj : TVatReturn;
begin
  XCorId := '';
  mmoInfo.Lines.Add('');
  // call the api
  XResult := OTestClient.GetReturn(edtViewPeriod.Text, XCorId);
  // and check the result
  if (XResult = RESULT_OK) then
  begin
    // succeeded, so write data returned to display
    mmoInfo.Lines.Add(OTestClient.LastValue.ToString);
    mmoInfo.Lines.Add('Correlation Id : ' + XCorId);
    // or do something more meaningful ...

    // going to convert the json into a vat return object and then write the values to the screen.
    VatObj := ParseReturns(XCorId, OTestClient.LastValue);
    if (Assigned(VatObj)) then
    try
      mmoInfo.Lines.Add(VatObj.Periodkey);
      mmoInfo.Lines.Add(VatObj.XCorId);
      mmoInfo.Lines.Add(FloatToStr(VatObj.DueOnSales));
      mmoInfo.Lines.Add(FloatToStr(VatObj.DueOnAcquisitions));
      mmoInfo.Lines.Add(FloatToStr(VatObj.TotalVatDue));
      mmoInfo.Lines.Add(FloatToStr(VatObj.VatReclaimedCP));
      mmoInfo.Lines.Add(FloatToStr(VatObj.NetVatDue));
      mmoInfo.Lines.Add(VatObj.SalesExVAT.ToString);
      mmoInfo.Lines.Add(VatObj.PurchasesExVAT.ToString);
      mmoInfo.Lines.Add(VatObj.GoodsExVAT.ToString);
      mmoInfo.Lines.Add(VatObj.AcquisitionsExVAT.ToString);

    finally
      VatObj.Free;
    end;
  end

  // check whether it failed because there was no data
  else if (XResult = RESULT_NODATA) then
  begin
    mmoInfo.Lines.Add('The call worked, but no data was found/returned');
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
procedure TfrmVatSaved.edtUIDExit(Sender: TObject);
begin
  if (not AnsiSameText(edtUID.Text, OTestClient.UID)) then
  begin
    if (OTestClient.SetHmrcId(edtUID.Text) = RESULT_OK) then
      LoadTokens
    else
      ShowMessage('Error setting user id : ' + #13#10 + OTestClient.LastError);
  end;
end;

(*****************************************************************************
*                           API METHODS SECTION                              *
******************************************************************************
*  Build list of submission values in the object.                            *
*****************************************************************************)
procedure TfrmVatSaved.FillSubmission(aObj: TVatSubmission);
begin
  if (Assigned(aObj)) then
  begin
    aObj.Periodkey := edtSubmitPeriod.Text;
    aObj.DueOnSales := edtDueOnSales.Value;
    aObj.DueOnAcquisitions := edtDueOnAqu.Value;
    aObj.TotalVatDue := edtTotalDue.Value;
    aObj.VatReclaimedCP := edtReclaim.Value;
    aObj.NetVatDue := edtNetDue.Value;
    aObj.SalesExVAT := Trunc(edtSalesEx.Value);
    aObj.PurchasesExVAT := Trunc(edtPurchaseEx.Value);
    aObj.GoodsExVAT := Trunc(edtGoodsEx.Value);
    aObj.AcquisitionsExVAT := Trunc(edtAquEx.Value);
    if (cbxFinalised.ItemIndex = 0) then
      aObj.Finalized := true
    else
      aObj.Finalized := false;
  end;
end;


(*****************************************************************************
*                           JSON METHODS SECTION                             *
******************************************************************************
*  Parse the obligations value returned.                                     *
*  Comments and "unnecessary" code have been left in, just to show the       *
*  stages that may be relevant to this, it depends on what is actually       *
*  required of the data at the end of the day. It is all here in one lump    *
*  for clarity, but processing the array and then the individual objects     *
*  could be extracted into separate functions.                               *
*****************************************************************************)
procedure TfrmVatSaved.ParseObligationsJson(aValue: TJSONValue);
var
  ix1: integer;
  ix2: integer;
  lvValue : TJSONValue;
  lvArray : TJSONArray;
  lvObj   : TJSONObject;
  lvTemp: string;
begin
  if (Assigned(aValue)) then
  begin
    // extracting values directly from the json value using a known path
    // BUT we do not know how many !!!
    mmoInfo.Lines.Add(aValue.GetValue<string>('obligations[0].start'));
    mmoInfo.Lines.Add(aValue.GetValue<string>('obligations[1].start'));
    //mmoInfo.Lines.Add(aValue.GetValue<string>('obligations[2].start'));   // raises an exception

    // is it a json object - all tests say yes
    if (aValue is TJSONObject) then
    begin
      mmoInfo.Lines.Add('JSON Object : ' + aValue.ToString);

      // now we can get a count - this will be the number of objects in the array
      mmoInfo.Lines.Add(IntToStr((aValue as TJSONObject).Count));

      // get the array bit out of the object, but still as a json value
      // we know it is called "obligations" here
      lvValue := (aValue as TJSONObject).Values['obligations'];
      mmoInfo.Lines.Add(lvValue.ToString);

      // check it is an array
      if (lvValue is TJSONArray) then
      begin
        // convert it to an array for convenience
        lvArray := lvValue as TJSONArray;
        mmoInfo.Lines.Add('JSON Array : ' + lvValue.ToString);
        mmoInfo.Lines.Add('Array size = ' + IntToStr(lvArray.Count));

          // we can get the items out of the array as json values
    //      lvValue := lvArray.Items[0];
    //  if (lvValue is TJSONObject) then
    //    mmoInfo.Lines.Add('JSON Object : ' + lvValue.ToString)

        // loop through the array extracting the objects and processing them
        for ix1 := 0 to lvArray.Count - 1 do
        begin
          mmoInfo.lines.add('');  // for clarity
          // short cut as we know (expect) it is an object
          lvObj := lvArray.Items[ix1] as TJSONObject;
          mmoInfo.Lines.Add('JSON Object : ' + lvObj.ToString);

          // the object has a count for iteration
          for ix2 := 0 to lvObj.Count - 1 do
          begin
            // we know (expect) it contains string pairs
            mmoInfo.Lines.Add(lvObj.Pairs[ix2].ToString);

            // pairs can be split into json string (the name) and json value (the value)
            mmoInfo.Lines.Add(lvObj.Pairs[ix2].JSONString.ToString);
            mmoInfo.Lines.Add(lvObj.Pairs[ix2].JSONValue.ToString);
          end;  // for object pairs
        end;  // for array
      end  // if an array
      else if (aValue is TJSONArray) then
      begin
        mmoInfo.Lines.Add('JSON Array : ' + aValue.ToString);
      end
      else if (aValue is TJSONString) then
      begin
        mmoInfo.Lines.Add('JSON string : ' + aValue.ToString);
      end
      else begin
        mmoInfo.Lines.Add('Unknown JSON format : ' + aValue.ToString);
      end;
    end;  // if an object
  end;  // if not nil
end;


(*****************************************************************************
*                          TOKEN METHODS SECTION                             *
******************************************************************************
*  This is a demo so for simplicity the tokens are saved to an ini file. The *
*  Date/Time conversions used here are those that worked in the development  *
*  environment used - Tokyo 10.2.3 on W10. It may be necessary to change the *
*  date/time methods for other set ups.                                      *
******************************************************************************
*  Load any saved access tokens for the current user.                        *
*****************************************************************************)
procedure TfrmVatSaved.LoadTokens;
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

      OTestClient.AddaToken(lvUid, lvScope, lvAccess, lvRefresh, lvStops, lvExpires);

      lvScope := 'write:vat';
      lvAccess  := f.ReadString(lvUid, lvScope + '_Access', '');
      lvRefresh := f.ReadString(lvUid, lvScope + '_Refresh', '');
      lvTemp    := f.ReadString(lvUid, lvScope + '_Expires', '');
      lvExpires := StrToDateTimeDef(lvTemp,Now);
      lvTemp    := f.ReadString(lvUid, lvScope + '_Stops', '');
      lvStops   := StrToDateDef(lvTemp,Date);

      OTestClient.AddaToken(lvUid, lvScope, lvAccess, lvRefresh, lvStops, lvExpires);
    end;
  finally
    f.Free;
  end;
end;

(*****************************************************************************
*  Save these details to the tokens file.                                    *
*****************************************************************************)
procedure TfrmVatSaved.SaveToken(Sender: TObject; const uid, scp, atn, rtn: string; const exp, tmo: TDateTime);
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
*                         PROPERTY METHODS SECTION                           *
******************************************************************************
*  Set the AppValues.                                                        *
*****************************************************************************)
procedure TfrmVatSaved.SetAppValues(Values: TAppValues);
begin
  FAppValues := Values;

  AddHeaders(OTestClient, FAppValues);
end;

(*****************************************************************************
*  Set the client details.                                                   *
*****************************************************************************)
procedure TfrmVatSaved.SetDetails(const Value: THmrcClientDetails);
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
