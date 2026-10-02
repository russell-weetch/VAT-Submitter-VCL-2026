unit fVat1;

(****************************************************************************)
interface
(****************************************************************************)

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ComCtrls, IPPeerClient,
  Data.Bind.Components, Data.Bind.ObjectScope, REST.Client, System.JSON, REST.Types,
  HmrcRestClient, HmrcVatClient, HmrcHeaders, Vcl.Imaging.pngimage, Vcl.ExtCtrls;
(****************************************************************************)

type
  TfrmVat1 = class(TForm)
    HmrcVATClient1: THmrcVATClient;
    btnObligation: TBitBtn;
    edtVRN: TEdit;
    mmoInfo: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    dtpFrom: TDateTimePicker;
    dtpTo: TDateTimePicker;
    Label4: TLabel;
    cbxStatus: TComboBox;
    odlg: TOpenDialog;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure btnObligationClick(Sender: TObject);
    procedure edtVRNExit(Sender: TObject);
  private
    FAppValues : TAppValues;             // application settings for the vat headers
    procedure LoadSettings;              // load client details from ini file
    procedure ParseObligations(aValue: TJSONValue);  // parse the obligations json returned
  public
    procedure SetAppValues(Values: TAppValues);
  end;

procedure ShowVatForm(Hdrs: TAppValues);

(****************************************************************************)
implementation
(****************************************************************************)
uses
  IniFiles, REST.Utils, HmrcRestSupport;

{$R *.dfm}

(****************************************************************************)
procedure ShowVatForm(Hdrs: TAppValues);
var
  frmVat1: TfrmVat1;
begin
  frmVat1 := TfrmVat1.Create(nil);
  try
    frmVat1.SetAppValues(Hdrs);
    frmVat1.ShowModal;
  finally
    frmVat1.Free;
  end;

end;

(*****************************************************************************
*                         HMRC VAT CLIENT FORM                              *
******************************************************************************
*                             INIT SECTION                                   *
******************************************************************************
*  Init.                                                                     *
*****************************************************************************)
procedure TfrmVat1.FormCreate(Sender: TObject);
begin
  LoadSettings;
end;


(*****************************************************************************
*  Load details from config file - this is just a simple demo app.           *
*  These values could all be set in the component at design time.            *
*****************************************************************************)
procedure TfrmVat1.LoadSettings;
var
  inf : TIniFile;
begin
  if (odlg.Execute) then
  begin
    inf := TIniFile.Create(odlg.FileName);
    try
      HmrcVATClient1.ClientId     := inf.ReadString('REST', 'AppKey', '');
      HmrcVATClient1.ClientSecret := inf.ReadString('REST', 'AppSecret', '');
      HmrcVATClient1.CallbackPort := inf.ReadString('REST', 'CallbackPort', '');
      HmrcVATClient1.CallbackUrl  := inf.ReadString('REST', 'CallbackUrl', '');
      HmrcVATClient1.ServerToken  := inf.ReadString('REST', 'ServerToken', '');
      HmrcVATClient1.BaseUrl      := inf.ReadString('REST', 'BaseUrl', '');
    finally
      inf.Free;
    end;
  end;
end;


(*****************************************************************************
*                          BUTTON CLICKS SECTION                             *
******************************************************************************
*  Liabilities / Obligations / Payments                                      *
*  Call the search API method with the appropriate end point and the current *
*  search dates. If there is no access token, the user will see the login    *
*  form and will then need to call the search api again.                     *
******************************************************************************
*  Call the obligations end point with the current search dates and status.  *
*****************************************************************************)
procedure TfrmVat1.btnObligationClick(Sender: TObject);
var
  XCorId: string;
  lvResult : integer;
begin
  XCorId := '';
  mmoInfo.Lines.Add('');
  // check whether to add the Status parameter
  if (cbxStatus.ItemIndex = 2) then
    lvResult := HmrcVATClient1.GetObligations(dtpFrom.Date, dtpTo.Date, XCorId, 'O')
  else if (cbxStatus.ItemIndex = 1) then
    lvResult := HmrcVATClient1.GetObligations(dtpFrom.Date, dtpTo.Date, XCorId, 'F')
  else
    lvResult := HmrcVATClient1.GetObligations(dtpFrom.Date, dtpTo.Date, XCorId, '');
  // now look at what happened
  if (lvResult = RESULT_OK) then
  begin
    // succeeded, so write data returned to display
    mmoInfo.Lines.Add(HmrcVATClient1.LastValue.ToString);
    mmoInfo.Lines.Add('Correlation Id = ' + XCorId);
    // or do something more useful with it
    ParseObligations(HmrcVATClient1.LastValue);
  end
  // check whether it failed because there was no access token
  else if (HmrcVATClient1.LastCode = ERR_NO_ACCESS_TOKEN) then
  begin
    // so get a new access token
    HmrcVATClient1.NewAccessToken;
    // now the user needs to call the api again
    mmoInfo.Lines.Add('Please call the obligations API again, once authorisation has been granted');
  end
  else begin
    // failed, so write error info to display
    mmoInfo.Lines.Add('Error ' + IntToStr(HmrcVATClient1.LastCode) + ' ' + HmrcVATClient1.LastMsg);
    mmoInfo.Lines.Add(HmrcVATClient1.LastError);
    // or handle it some other way ...
  end;
end;

(*****************************************************************************
*  Set the HMRC user id. This should be the user VRN value.                  *
*****************************************************************************)
procedure TfrmVat1.edtVRNExit(Sender: TObject);
begin
  HmrcVATClient1.UID := Trim(edtVRN.Text);
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
procedure TfrmVat1.ParseObligations(aValue: TJSONValue);
var
  ix1: integer;
  ix2: integer;
  lvValue : TJSONValue;
  lvArray : TJSONArray;
  lvObj   : TJSONObject;
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
*  Set the AppValues.                                                        *
*****************************************************************************)
procedure TfrmVat1.SetAppValues(Values: TAppValues);
begin
  FAppValues := Values;

  // add the anti-fraud headers
  AddHeaders(HmrcVatClient1, FAppValues);
end;


end.
