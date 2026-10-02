unit fVclRestTest;

(*****************************************************************************
*               VCL HMRC API REST Test Application Main Form                 *
******************************************************************************
*  This uses an HmrcTestClient to access the Hello end points and the new    *
*  user end points.                                                          *
*    Hello World uses no authentication at all                               *
*    Hello Application uses a server token                                   *
*    Hello User uses OAuth2 authentication and will require a login to       *
*      grant authorisation.                                                  *
*                                                                            *
*  The new user end points are all application authentication and require    *
*  a server toekn.                                                           *
*                                                                            *
*  For more examples, see the FMX demo app.                                  *
*                                                                            *
*  created 12/01/19.                                                         *
*  updated 15/12/20.                                                         *
*  version 1.0.1                                                             *
*                                                                            *
*****************************************************************************)

interface
(****************************************************************************)

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.JSON,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, IPPeerClient,
  REST.Client, HmrcRestSupport, HmrcRestClient, Data.Bind.Components, Data.Bind.ObjectScope, REST.Types,
  HmrcTestClient, HmrcHeaders, Vcl.Imaging.pngimage, Vcl.ExtCtrls;
(****************************************************************************)

type
  TfrmVclRestTest = class(TForm)
    btnHelloUser: TBitBtn;
    mmoInfo: TMemo;
    TestClient: THmrcTestClient;
    btnHelloWorld: TBitBtn;
    btnHelloApp: TBitBtn;
    BtnNewAgent: TBitBtn;
    btnNewCompany: TBitBtn;
    btnNewPerson: TBitBtn;
    odlg: TOpenDialog;
    btnVatForm: TBitBtn;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure btnHelloUserClick(Sender: TObject);
    procedure btnHelloAppClick(Sender: TObject);
    procedure btnHelloWorldClick(Sender: TObject);
    procedure BtnNewAgentClick(Sender: TObject);
    procedure btnNewCompanyClick(Sender: TObject);
    procedure btnNewPersonClick(Sender: TObject);
    procedure btnVatFormClick(Sender: TObject);
  private
    FAppValues : TAppValues;             // application settings for the vat headers
    Headed: boolean;
    procedure DisplayList(aList: string);
    procedure LoadSettings;  // load client ID, etc from config file
    procedure ParseCompany(aValue: TJSONValue);
    function  ParseJSON(aValue: TJSONValue): string;
  public
  end;

var
  frmVclRestTest: TfrmVclRestTest;

(****************************************************************************)
implementation
(****************************************************************************)
uses
  IniFiles, System.Hash, fVat1;
{$R *.dfm}

const
  // dummy substitute for the application installation guid
  ApGuid = '{C8801C57-95A1-4409-A986-74A6A3E3478B}';

(*****************************************************************************
*                          HMRC TEST MAIN FORM                               *
******************************************************************************
*                             INIT SECTION                                   *
******************************************************************************
*  Init.                                                                     *
*****************************************************************************)
procedure TfrmVclRestTest.FormCreate(Sender: TObject);
begin
  //TestClient.IzTest := true;    // by default it targets the live api service
                                  // set as a property in the object inspector
  Headed := false;
  FAppValues.AppGuid := ApGuid;
  FAppValues.AppName := 'HmrcDevTest';
  // your actual license key or some dummy value here - uses System.Hash
  FAppValues.License := THashSHA1.GetHashString('ABC456XYZ');
  // dummy incorrect values to pass the headers test - clearly nonsense for testing only
  FAppValues.MFType  := 'AUTH_CODE';
  FAppValues.MFTime  := Now - 0.01;   // about 15 minutes ago
  FAppValues.MFValue := 'def123';     // hash it here to obscure it if required

  AddHeaders(TestClient, FAppValues);
  // load client ID, etc from config file
  LoadSettings;;
end;

(*****************************************************************************
*  Load details from config file - this is just a simple demo app.           *
*****************************************************************************)
procedure TfrmVclRestTest.LoadSettings;
var
  inf : TIniFile;
begin
  if (odlg.Execute) then
  begin
    inf := TIniFile.Create(odlg.FileName);
    try
      TestClient.ClientId     := inf.ReadString('REST', 'AppKey', '');
      TestClient.ClientSecret := inf.ReadString('REST', 'AppSecret', '');
      TestClient.CallbackPort := inf.ReadString('REST', 'CallbackPort', '');
      TestClient.CallbackUrl  := inf.ReadString('REST', 'CallbackUrl', '');
      TestClient.ServerToken  := inf.ReadString('REST', 'ServerToken', '');
      TestClient.BaseUrl      := inf.ReadString('REST', 'BaseUrl', '');
    finally
      inf.Free;
    end;
  end;
end;


(*****************************************************************************
*                          BUTTON CLICKS SECTION                             *
******************************************************************************
*  Call Hello/Application.                                                   *
*****************************************************************************)
procedure TfrmVclRestTest.btnHelloAppClick(Sender: TObject);
begin
  mmoInfo.Lines.Add(TestClient.TestHelloApplication);
end;

(*****************************************************************************
*  Call Hello/User.                                                          *
*****************************************************************************)
procedure TfrmVclRestTest.btnHelloUserClick(Sender: TObject);
begin
  mmoInfo.Lines.Add(TestClient.TestHelloUser);
end;

(*****************************************************************************
*  Call Hello/World.                                                         *
*****************************************************************************)
procedure TfrmVclRestTest.btnHelloWorldClick(Sender: TObject);
begin
  mmoInfo.Lines.Add(TestClient.TestHelloWorld);
end;

(*****************************************************************************
*  Create a new user as an Agent.                                            *
*****************************************************************************)
procedure TfrmVclRestTest.BtnNewAgentClick(Sender: TObject);
begin
  mmoInfo.Lines.Add('');
  if (TestClient.AddAgent = RESULT_OK) then
  begin
    mmoInfo.Lines.Add(TestClient.LastValue.ToString);
  end
  else begin
    mmoInfo.Lines.Add('Error ' + IntToStr(TestClient.LastCode) + ' ' +
                          TestClient.LastMsg);
    mmoInfo.Lines.Add(TestClient.LastError);
  end;
end;

(*****************************************************************************
*  Create a new user as a company.                                           *
*****************************************************************************)
procedure TfrmVclRestTest.btnNewCompanyClick(Sender: TObject);
begin
  mmoInfo.Lines.Add('');
  if (TestClient.AddCompany = RESULT_OK) then
  begin
    mmoInfo.Lines.Add(TestClient.LastValue.ToString);
    ParseCompany(TestClient.LastValue);
  end
  else begin
    mmoInfo.Lines.Add('Error ' + IntToStr(TestClient.LastCode) + ' ' +
                          TestClient.LastMsg);
    mmoInfo.Lines.Add(TestClient.LastError);
  end;
end;

(*****************************************************************************
*  Create a new user as an Individual.                                       *
*****************************************************************************)
procedure TfrmVclRestTest.btnNewPersonClick(Sender: TObject);
begin
  mmoInfo.Lines.Add('');
  if (TestClient.AddPerson = RESULT_OK) then
  begin
    mmoInfo.Lines.Add(TestClient.LastValue.ToString);
    DisplayList(ParseJSON(TestClient.LastValue));
  end
  else begin
    mmoInfo.Lines.Add('Error ' + IntToStr(TestClient.LastCode) + ' ' +
                          TestClient.LastMsg);
    mmoInfo.Lines.Add(TestClient.LastError);
  end;
end;

(*****************************************************************************
*  Show the vat form.                                                        *
*****************************************************************************)
procedure TfrmVclRestTest.btnVatFormClick(Sender: TObject);
begin
  ShowVatForm(FAppValues);
end;


(*****************************************************************************
*                          JSON HANDLING SECTION                             *
******************************************************************************
*  Parse JSON returned from create company call. We know it is a JSON Object *
*  so it can be transversed by index or by name. We also know what elements  *
*  it contains, based on the API call. Here the values are extracted by name *
*****************************************************************************)
procedure TfrmVclRestTest.ParseCompany(aValue: TJSONValue);
var
  ix1 : integer;
  lvValue      : TJSONValue;
  lvAddressObj : TJSONObject;
  lvCompanyObj : TJSONObject;
  lvUserObj    : TJSONObject;
  aList : TStringList;

begin
  aList := TStringList.Create;
  try
    // cast the supplied value as a json object
    lvUserObj := (aValue as TJSONObject);

    lvValue := lvUserObj.Values['userId'];
    aList.Add('userId=' + lvValue.ToString);
    lvValue := lvUserObj.Values['password'];
    aList.Add('password=' + lvValue.ToString);
    lvValue := lvUserObj.Values['userFullName'];
    aList.Add('userFullName=' + lvValue.ToString);
    lvValue := lvUserObj.Values['emailAddress'];
    aList.Add('emailAddress=' + lvValue.ToString);

    // get the organisation details
    lvValue := lvUserObj.Values['organisationDetails'];
    aList.Add('CompanyDetails [');

    // cast the extracted value as a json object
    lvCompanyObj := lvValue as TJSONObject;
    mmoInfo.Lines.Add(lvCompanyObj.ToString);

    lvValue := lvCompanyObj.Values['name'];
    aList.Add('name=' + lvValue.ToString);

    // get the address details from the organisation details
    lvValue := lvCompanyObj.Values['address'];
    aList.Add('Address [');

    // cast the extracted value as a json object
    lvAddressObj := lvValue as TJSONObject;

    lvValue := lvAddressObj.Values['line1'];
    aList.Add('AddressLine1=' + lvValue.ToString);
    lvValue := lvAddressObj.Values['line2'];
    aList.Add('AddressLine2=' + lvValue.ToString);
    lvValue := lvAddressObj.Values['postcode'];
    aList.Add('Postcode=' + lvValue.ToString);
    aList.Add(']');
    aList.Add(']');

    // back to the user object properties
    lvValue := lvUserObj.Values['saUtr'];
    aList.Add('saUtr=' + lvValue.ToString);
    lvValue := lvUserObj.Values['nino'];
    aList.Add('nino=' + lvValue.ToString);
    lvValue := lvUserObj.Values['mtdItId'];
    aList.Add('mtdItId=' + lvValue.ToString);
    lvValue := lvUserObj.Values['empRef'];
    aList.Add('empRef=' + lvValue.ToString);
    lvValue := lvUserObj.Values['vrn'];
    aList.Add('vrn=' + lvValue.ToString);

    for ix1 := 0 to aList.Count - 1 do
      mmoInfo.Lines.Add(aList[ix1]);
  finally
    aList.Free;
  end;
end;


(*****************************************************************************
*  Accept a delimited string and parse into separate strings and add to a    *
*  string list, then display in the memo.                                    *
*****************************************************************************)
procedure TfrmVclRestTest.DisplayList(aList: string);
var
  ix1 : integer;
  sw1 : integer;
  sv1 : string;
  tmp : string;
  lst : TStringList;
begin
  mmoInfo.Lines.Add('');
        mmoInfo.Lines.Add(aList);
  mmoInfo.Lines.Add('');
  lst := TStringList.Create;
  try
    if (aList <> '') then
    begin
      tmp := aList;
      sw1 := Pos(';', tmp);
      while (sw1 > 0) and (tmp <> '') do
      begin
        sv1 := Copy(tmp, 1, sw1 - 1);
        lst.Add(StringReplace(sv1, '"','',[rfReplaceAll]));

        tmp := Copy(tmp, sw1 + 1, Length(tmp));
        sw1 := Pos(';', tmp);
      end;
      lst.Add(StringReplace(tmp, '"','',[rfReplaceAll]));

      for ix1 := 0 to lst.Count - 1 do
        mmoInfo.Lines.Add(lst[ix1]);
    end;
  finally
    lst.Free;
  end;
end;


(*****************************************************************************
*  Parse a json value into the component elements and add then to a          *
*  delimited string. Look for JSONObect, JSONArray or just a string value.   *
*  It "loses" the names of nested objects and arrays.                        *
*****************************************************************************)
  function TfrmVclRestTest.ParseJSON(aValue: TJSONValue): string;
  var
    ix1: integer;
    lvValue : TJSONValue;
    lvObj : TJSONObject;
    lvAry : TJSONArray;
    lvPair: TJSONPair;
    lvTemp: string;
  begin
    Result := '';

    if (aValue is TJSONObject) then
    begin
      lvObj := aValue AS TJSONObject;
      for ix1 := 0 to lvObj.Count - 1 do
      begin

        lvPair := lvObj.Pairs[ix1];
        lvValue := lvPair.JsonValue;
        if (lvValue is TJSONObject) then
        begin
          lvTemp := ParseJSON(lvValue);
          if (lvTemp <> '') then
          begin
            if (Result <> '') then
              Result := Result + ';';
            Result := Result + lvTemp;
          end;
        end  // if object
        else if (lvValue is TJSONArray) then
        begin
          lvTemp := ParseJSON(aValue);
          if (lvTemp <> '') then
          begin
            if (Result <> '') then
              Result := Result + ';';
            Result := Result + lvTemp;
          end;
        end  // if array
        else begin
          if (Result <> '') then
            Result := Result + ';';
          Result := Result + lvPair.ToString;
        end;
      end;  //for
    end  // if an object
    else if (aValue is TJSONArray) then
    begin
      lvAry := aValue AS TJSONArray;
      for ix1 := 0 to lvAry.Count - 1 do
      begin

        lvValue := lvAry.Items[ix1];
        if (lvValue is TJSONObject) then
        begin
          lvTemp := ParseJSON(lvValue);
          if (lvTemp <> '') then
          begin
            if (Result <> '') then
              Result := Result + ';';
            Result := Result + lvTemp;
          end;
        end  // if object
        else if (lvValue is TJSONArray) then
        begin
          lvTemp := ParseJSON(aValue);
          if (lvTemp <> '') then
          begin
            if (Result <> '') then
              Result := Result + ';';
            Result := Result + lvTemp;
          end;
        end  // if array
        else begin
          if (Result <> '') then
            Result := Result + ';';
          Result := Result + lvValue.ToString;
        end;
      end;  //for
    end
    else //if (aValue is TJSONString) then
    begin
      if (Result <> '') then
        Result := Result + ';';
      Result := Result + aValue.ToString;
    end;
  end;


end.
