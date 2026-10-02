unit fVrnCheck;

(*****************************************************************************
*                           VRN Checks Test Form                             *
******************************************************************************
*  This form demonstrates calls to the VRN Check API end points.             *
*                                                                            *
*  created 16/12/20.                                                         *
*  updated 16/12/20.                                                         *
*  updated 28/01/21.   Added updated fraud headers.                          *
*  version 1.0.1                                                             *
*                                                                            *
*****************************************************************************)

interface

(****************************************************************************)
uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit, FMX.Memo, FMX.EditBox,
  System.JSON, FMX.ScrollBox, FMX.Layouts, FMX.ExtCtrls,
  HmrcRestSupport, HmrcRestClient, HmrcTestSupport, HmrcTestClient, HmrcHeaders;
(****************************************************************************)

type
  TfrmVrnCheck = class(TForm)
    btnCheck1: TCornerButton;
    btnCheck2: TCornerButton;
    edtTarget: TEdit;
    edtCaller: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    mmoResponse: TMemo;
    ImageViewer1: TImageViewer;
    procedure FormCreate(Sender: TObject);
    procedure btnCheck1Click(Sender: TObject);
    procedure btnCheck2Click(Sender: TObject);
  private
    FAppValues  : TAppValues;             // application settings for the vat headers
    ODetails    : THmrcClientDetails;
    OTestClient : THmrcTestClient;
    procedure GetVRNObject(aValue: TJSONValue);  // get the VRN response as an object. NB this requires System.JSON in the uses clause
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
  IniFiles, HmrcVatSupport;

{$R *.fmx}

(*****************************************************************************
*                         HMRC VAT CLIENT FORM                               *
******************************************************************************
*                             INIT SECTION                                   *
******************************************************************************
*  Init.                                                                     *
*****************************************************************************)
procedure TfrmVrnCheck.FormCreate(Sender: TObject);
begin
  OTestClient := THmrcTestClient.Create(Self);

  // set test mode
  OTestClient.IzTest := true;    // by default it targets the live api service
end;

(*****************************************************************************
*                          BUTTON CLICKS SECTION                             *
******************************************************************************
*  Call the VRN check end point with just the target VRN.                    *
*****************************************************************************)
procedure TfrmVrnCheck.btnCheck1Click(Sender: TObject);
begin
  mmoResponse.Lines.Add('');
  if (OTestClient.CheckVrn(Trim(edtTarget.Text)) = RESULT_OK) then
  begin
    // display the response as json
    mmoResponse.Lines.Add(OTestClient.LastValue.ToString);
    // or do something else
    GetVRNObject(OTestClient.LastValue);
  end
  else begin
    mmoResponse.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' + OTestClient.LastMsg);
    mmoResponse.Lines.Add(OTestClient.LastError);
  end;
end;

(*****************************************************************************
*  Call the VRN check end point with both the target and caller VRNs.        *
*****************************************************************************)
procedure TfrmVrnCheck.btnCheck2Click(Sender: TObject);
begin
  mmoResponse.Lines.Add('');
  if (OTestClient.CheckVrn(Trim(edtTarget.Text), Trim(edtCaller.Text)) = RESULT_OK) then
  begin
    // display the response as json
    mmoResponse.Lines.Add(OTestClient.LastValue.ToString);
    // or do something else
    GetVRNObject(OTestClient.LastValue);
  end
  else begin
    mmoResponse.Lines.Add('Error ' + IntToStr(OTestClient.LastCode) + ' ' + OTestClient.LastMsg);
    mmoResponse.Lines.Add(OTestClient.LastError);
  end;
end;


(*****************************************************************************
*                      JSON RESPONSE METHODS SECTION                         *
******************************************************************************
*  Get the response as a VRNResponse object and write the values to the      *
*  screen, as we have nothing else to do with it here.                       *
*****************************************************************************)
procedure TfrmVrnCheck.GetVRNObject(aValue: TJSONValue);
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
*                         PROPERTY METHODS SECTION                           *
******************************************************************************
*  Set the AppValues.                                                        *
*****************************************************************************)
procedure TfrmVrnCheck.SetAppValues(Values: TAppValues);
begin
  FAppValues := Values;

  // add the anti-fraud headers
  AddHeaders(OTestClient, FAppValues);
end;

(*****************************************************************************
*  Set the client details.                                                   *
*****************************************************************************)
procedure TfrmVrnCheck.SetDetails(const Value: THmrcClientDetails);
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
