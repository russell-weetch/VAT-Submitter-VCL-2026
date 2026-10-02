unit HmrcTestClient;

(* ****************************************************************************
  *                      HMRC API REST Test Client Unit                        *
  ******************************************************************************
  *  This unit contains the test client class with methods to use the test api *
  *  endpoints across all areas of the MTD process.                            *
  *                                                                            *
  *  Originally it used the Server Token generated when the app was registered *
  *  with the Sandbox. This is no longer provided and the process has changed  *
  *  to use an application level access token, which cannot be refreshed. Now  *
  *  it extends the RestClient, which now only handles OAuth2 and adds the new *
  *  application access token function.                                        *
  *                                                                            *
  *  The use of the access token introduces a potential issue with a conflict  *
  *  of tokens if the Hello User endpoint is tested, as this will use the      *
  *  OAuth2 token process, where everything else uses the application token.   *
  *  This hopefully handled by checking the auth mode and resetting where      *
  *  necessary.                                                                *
  ******************************************************************************
  *  created  01/01/21 from the original integrated unit.                      *
  *  updated  28/01/21. - AppToken replaces ServerToken for                    *
  *                       application-restricted endpoints.                    *
  *                                                                            *
  *  version  1.0.0   released 29/01/21                                        *
  *                                                                            *
  *  version  1.0.1   released 09/02/21    Updated application token handling  *
  *                                        and added the CallApi method for    *
  *                                        use by the SA Test form.            *
  *                                        Added loading of app level tokens.  *
  *                                        Moved VRN checks from VAT client.   *
  *                                                                            *
  *  version  1.0.2   released 15/03/21    Tidied it up a bit.                 *
  *                                                                            *
  *  original copyright Ian Hamilton 2020/21.                                  *
  *  License : GPL                                                             *
  *                                                                            *
  **************************************************************************** *)
Interface
(* ************************************************************************** *)
Uses
  System.Classes, System.SysUtils, System.UITypes, System.Variants,
  IPPeerClient, REST.Types, REST.Client, REST.Authenticator.OAuth,
  System.JSON,
  HmrcRestSupport,
  HmrcTestSupport,
  HmrcRestClient;
(* ************************************************************************** *)
Type
  (* **************************************************************************
    **             Test REST Client for the HMRC REST API service             **
    **                                                                        **
    **  This handles the "hello" test endpoints provided by the API service   **
    **  and also sets up test users and performs vrn checks.                  **
    **  At some point the API may stop supporting some or all of these.       **
    **  API Version 1.0                                                       **
    **                                                                        **
    **  The user id may be the value of "userId" for the test user, the UTR,  **
    **  the Nino, the VRN or something else yet to be added.                  **
    ************************************************************************** *)
  THmrcTestClient = Class(THMRCRestClient)
  Private
  Protected
    FAppToken    : string;              // application access token
    FTokenExpiry : TDateTime;           // date/time of access token expiry
    // ACCESS TOKEN (ATN) SECTION
    function ATN_AquireToken: integer;     // get new application access level token
    function ATN_Expired: boolean;         // has the access token expired
    function ATN_LoadToken: boolean;       // try to load an access token
    procedure ATN_Reset;                   // reset app token values in headers
    // NEW USER (NUS) SECTION
    procedure NUS_CheckMode(const AMode: THmrcAuthMode);  // check and reset authmode
    Function NUS_CheckReady: boolean;      // check the initial values have been loaded/set
  Public
    Constructor Create(AOwner: TComponent); Override;
    // universal call using supplied resource and suffix
    Function CallApi(const AMthd: integer; const ARsc, ASfx, ABdy: string): integer; overload;
    Function AddAgent: integer;            // call the user api to add a new user as an agent
    Function AddCompany: integer;          // call the user api to add a new user as a business
    Function AddPerson: integer;           // call the user api to add a new user as an individual
    function CheckVRN(Const aValue: string): integer; overload;   // vrn check - just the target
    function CheckVRN(Const aValue, aCaller: string): integer; overload;  // vrn check - target and source
    Function GetServices: integer;         // call the test api to get the list of services available
    Function TestHelloApplication: String; // call the hello application end point
    Function TestHelloUser: String;        // call the hello user end point
    Function TestHelloWorld: String;       // call the hello world end point
    Function TestFraudHeaders: integer;    // call to test the fraud headers

    property AppToken : string read FAppToken write FAppToken;
    property TokenExpiry: TDateTime read FTokenExpiry write FTokenExpiry;
  End;

Procedure Register;

(* ************************************************************************** *)
Implementation
(* ************************************************************************** *)
Uses
  REST.Utils,
  System.IOUtils;
(* ************************************************************************** *)
Procedure Register;
Begin
  RegisterComponents('HmrcRestClient', [THmrcTestClient]);
End;


{ THmrcTestClient }

(* ****************************************************************************
  *                           HMRC TEST CLIENT                                 *
  ******************************************************************************
  *                             INIT SECTION                                   *
  ******************************************************************************
  *  Init.                                                                     *
  **************************************************************************** *)
Constructor THmrcTestClient.Create(AOwner: TComponent);
Begin
  Inherited;
  FIzTest := true;
  FAuthMode := amNone;
  FAppToken := '';
  FTokenExpiry := 0;
  BaseUrl := HmrcTestUrl;
  ORequest.Resource := '';
  ORequest.ResourceSuffix := '';
  Setlength(LScopeList, 2);
  LScopeList[0] := csHello;
  LScopeList[1] := csDefault;
End;

(* ****************************************************************************
  *                         CALL API TEST SECTION                              *
  ******************************************************************************
  *  A universal call using supplied resource and suffix. Also can handle      *
  *  optional values for a list of parameters and/or json for posting. The     *
  *  request method defaults to GET, but can be changed.                       *
  **************************************************************************** *)
function THmrcTestClient.CallApi(const AMthd: integer; const ARsc, ASfx, ABdy: string): integer;
begin
  Result := RESULT_NONE;
  REQ_ClearLast;
  NUS_CheckMode(amApplication);
  AuthScope := csDefault;
  If (NUS_CheckReady) Then
  try
    ORequest.Body.ClearBody;
    ORequest.Resource := ARsc;
    ORequest.ResourceSuffix := ASfx;
    if (AMthd <> REST_GET) then
    begin
       case AMthd of
         REST_POST   : ORequest.Method := TRESTRequestMethod.rmPOST;
         REST_PUT    : ORequest.Method := TRESTRequestMethod.rmPUT;
         REST_DELETE : ORequest.Method := TRESTRequestMethod.rmDELETE;
         REST_OTHER  : ORequest.Method := TRESTRequestMethod.rmPATCH;
       end;  // case
    end;  // if not get
    // has params ??
    //if Length(SPrms) > 0 then
    //begin
    //  for ix1 := 0 to Length(SPrms) - 1 do
    //    ORequest.Params.AddItem(SPrms[ix1].Name, SPrms[ix1].Value, TRESTRequestParameterKind.pkGETorPOST);
    //end;
    // has a pre-formatted json string ??
    if (ABdy <> '') then
    begin
      ContentType := csApJson;
      ORequest.Body.JSONWriter.WriteRaw(ABdy);
    end;
    ORequest.Execute;
    FLastCode := ORequest.Response.StatusCode;
    FLastMsg := ORequest.Response.StatusText;
    If (ORequest.Response.StatusCode < 400) Then
    Begin
      FLastValue := ORequest.Response.JSONValue;
      Result := RESULT_OK;
    End
    Else
    Begin
      FLastError := csError + IntToStr(ORequest.Response.StatusCode) + '  ' + ORequest.Response.Content;
      Result := RESULT_FAIL;
    End;
  Except
    on E: exception do
    begin
      FLastError := csError + E.Message;
      Result := RESULT_ERROR;
    end;
  End
  Else
  Begin
    Result := RESULT_ERROR;
  End;
end;


(* ****************************************************************************
  *                         ACCESS TOKEN (ATN) SECTION                         *
  ******************************************************************************
  *  Get a new application access token using client id & secret. This does    *
  *  not pop up an authorisation form, but does request an access token that   *
  *  will expire after 4 hours.                                                *
  **************************************************************************** *)
Function THMRCTestClient.ATN_AquireToken: integer;
Var
  lvToken: String;
  lvTime : TDateTime;
Begin
  Result := RESULT_NONE;
  Try
    BaseUrl := HmrcTestUrl;
    ORequest.Resource := csAuthToken;
    ORequest.ResourceSuffix := '';
    // now rebuild the request to get the new access token
    ORequest.Method := TRESTRequestMethod.rmPOST;
    ORequest.Params.AddItem(csGrantType, csClientCreds, TRESTRequestParameterKind.pkGETorPOST);
    ORequest.Params.AddItem(csClientId, FClientId, TRESTRequestParameterKind.pkGETorPOST);
    ORequest.Params.AddItem(csClientSecret, FClientSecret, TRESTRequestParameterKind.pkGETorPOST);

    try
      ORequest.Execute;
    finally
      ORequest.Params.Clear;
    end;

    FLastCode := ORequest.Response.StatusCode;
    FLastMsg := ORequest.Response.StatusText;
    // see what happened
    If (ORequest.Response.Status.Success) Then
    Begin
      If ORequest.Response.GetSimpleValue(csAccessToken, lvToken) Then
      Begin
        If (lvToken <> FAppToken) Then
        Begin
          // access token for scope
          FAppToken := lvToken;
          If ORequest.Response.GetSimpleValue(csExpiresIn, lvToken) Then
            // during testing the expiry time was always 14400 - which is 4 hours in seconds. 86400 seconds in a day.
            lvTime := Now + (StrToIntDef(lvToken, 14400) / 86400)
          Else
            // access token expiry is in 4 hours
            lvTime := Now + 0.166;
          FTokenExpiry := lvTime;
          // get the new scope for the token - should be "default"
          If ORequest.Response.GetSimpleValue(csScope, lvToken) Then
          Begin
            FAuthScope := lvToken;
          End;
          // set the new access token in the authenticator
          (Authenticator As TOAuth2Authenticator).AccessToken := FAppToken;

          // check whether we can save the changes
          If (Assigned(@OnTokenChange)) Then
          Begin
            OnTokenChange(Self, FClientID, FAuthScope, FAppToken, '', lvTime, lvTime);
            FTokenState := tsOK;
          End;
          Result := RESULT_OK;
        End;
      End
      Else
      Begin
        FLastCode := ERR_NO_ACCESS_TOKEN;
        FLastError := csMsgNoTokenFnd + ORequest.Response.Content;
      End;
    End // if success
    Else
    Begin
      FLastCode := ERR_NO_ACCESS_TOKEN;
      FLastError := csMsgBadResponse + ' : ' + ORequest.Response.Content;
    End;
  Except
    On e: Exception Do
    Begin
      FLastCode := ERR_NO_ACCESS_TOKEN;
      FLastError := csMsgRefreshErr + e.Message;
      Result := RESULT_FAIL;
    End;
  End;
End;
(* ****************************************************************************
  *  Check whether access token has expired.                                   *
  **************************************************************************** *)
function THmrcTestClient.ATN_Expired: boolean;
begin
  if (FTokenExpiry < Now) then
    Result := true
  else
    Result := false;
end;


(* ****************************************************************************
  *  Load an access token for this scope. Assumes application level token.     *
  **************************************************************************** *)
function THmrcTestClient.ATN_LoadToken: boolean;
var
  loaded: boolean;
begin
  Result := false;
    // is there an access token object ? if not, then try to load one, otherwise it will need to get a new token
  if (Assigned(@DoLoadToken)) then
  begin
    loaded := false;
    DoLoadToken(Self, FClientID, FAuthScope, loaded);
    if (loaded) then
    begin
      OAccessToken := LAccessTokens.GetAccessToken(FClientID, FAuthScope);
      if (Assigned(OAccessToken)) then
      begin
        FAppToken := OAccessToken.Access;
        FTokenExpiry := OAccessToken.TimeOut;
        // and set the token in the request
        (Authenticator As TOAuth2Authenticator).AccessToken := FAppToken;
        Result := true;
      end;
    end;
  end;
end;

(* ****************************************************************************
  *  Reset access tokens in headers - cleared in REQ_Reset.                    *
  **************************************************************************** *)
procedure THmrcTestClient.ATN_Reset;
begin
  BaseUrl := HmrcTestUrl;
  (Authenticator As TOAuth2Authenticator).Scope := FAuthScope;
  ContentType := csApJson;
end;

(* ****************************************************************************
  *                             NEW USERS SECTION                              *
  ******************************************************************************
  *  Check AuthMode status and update/clear if required.                       *
  **************************************************************************** *)
procedure THmrcTestClient.NUS_CheckMode(const AMode: THmrcAuthMode);
begin
  if (FAuthMode <> AMode) then
  begin
    FAuthMode := AMode;
    FAppToken := '';
    FTokenExpiry := Now;

    REQ_RESET;

    if (AMode = amApplication) then
      ATN_Reset;

    // add gov and vendor headers if supplied
    REQ_LoadHeaders;

    if (Assigned(OAccessToken)) then
      OAccessToken := nil;
    (Authenticator As TOAuth2Authenticator).AccessToken := '';
  end;
end;

(* ****************************************************************************
  *  Check details for an application level api call.                          *
  **************************************************************************** *)
Function THmrcTestClient.NUS_CheckReady: boolean;
var
  reload: boolean;
Begin
  Result := NAT_CheckReady;
  If (Result) Then
  Begin
    if (FAuthMode = amApplication) then
    begin
      If (FAppToken = '') then
        reload := true
      else if (ATN_Expired) then
        reload := true
      else
        reload := false;
      if (reload) then
      Begin
        if (ATN_LoadToken) then
        begin
          if (ATN_Expired) then
            Result := false
          else
            Result := true;
        end  // if loadded
        else begin
          Result := false;
        end;
        if (Result = false) then
        begin
          if (ATN_AquireToken = RESULT_OK) then
          begin
            Result := true;
          end
          else begin
            FLastError := csMsgNoSvrToken;
            FLastCode := ERR_NO_SERVER_TOKEN;
            Result := False;
          end;  // else not acquired
        end;  // if false
      end;  // if token = ''
    End;  // if app mode
  End;  // if ok
End;

(* ****************************************************************************
  *                            TEST USERS SECTION                              *
  ******************************************************************************
  *  Create a new agent and return the details.                                *
  **************************************************************************** *)
Function THmrcTestClient.AddAgent: integer;
Begin
  Result := RESULT_NONE;
  REQ_ClearLast;
  NUS_CheckMode(amApplication);
  AuthScope := csDefault;
  If (NUS_CheckReady) Then
  Begin
    ORequest.Body.ClearBody;
    ORequest.Resource := 'create-test-user';
    ORequest.ResourceSuffix := 'agents';
    ORequest.Method := TRESTRequestMethod.rmPOST;
    ContentType := csApJson;
    // hard-coded json string - this is the only option allowed
    ORequest.Body.JSONWriter.WriteRaw('{"serviceNames": ["agent-services"]}');
    ORequest.Execute;
    FLastCode := ORequest.Response.StatusCode;
    FLastMsg := ORequest.Response.StatusText;
    If (ORequest.Response.StatusCode < 400) Then
    Begin
      FLastValue := ORequest.Response.JSONValue;
      Result := RESULT_OK;
    End
    Else
    Begin
      FLastError := csError + IntToStr(ORequest.Response.StatusCode) + '  ' + ORequest.Response.Content;
      Result := RESULT_FAIL;
    End;
  End
  Else
  Begin
    Result := RESULT_ERROR;
  End;
End;
(* ****************************************************************************
  *  Create a new company and return the details.                              *
  **************************************************************************** *)
Function THmrcTestClient.AddCompany: integer;
Begin
  Result := RESULT_NONE;
  REQ_ClearLast;
  NUS_CheckMode(amApplication);
  AuthScope := csDefault;
  If (NUS_CheckReady) Then
  Begin
    ORequest.Body.ClearBody;
    ORequest.Resource := 'create-test-user';
    ORequest.ResourceSuffix := 'organisations';
    ORequest.Method := TRESTRequestMethod.rmPOST;
    ContentType := csApJson;
    ORequest.Body.JSONWriter.WriteRaw('{"serviceNames": ["paye-for-employers", "submit-vat-returns", ' +
      '"national-insurance", "self-assessment", "mtd-income-tax", "mtd-vat", "lisa", "relief-at-source", ' +
      '"customs-services"]}');
    ORequest.Execute;
    FLastCode := ORequest.Response.StatusCode;
    FLastMsg := ORequest.Response.StatusText;
    If (ORequest.Response.StatusCode < 400) Then
    Begin
      FLastValue := ORequest.Response.JSONValue;
      Result := RESULT_OK;
    End
    Else
    Begin
      FLastError := csError + IntToStr(ORequest.Response.StatusCode) + '  ' + ORequest.Response.Content;
      Result := RESULT_FAIL;
    End;
  End
  Else
  Begin
    Result := RESULT_ERROR;
  End;
End;
(* ****************************************************************************
  *  Create a new individual and return the details.                           *
  **************************************************************************** *)
Function THmrcTestClient.AddPerson: integer;
Begin
  Result := RESULT_NONE;
  REQ_ClearLast;
  NUS_CheckMode(amApplication);
  AuthScope := csDefault;
  If (NUS_CheckReady) Then
  Begin
    ORequest.Body.ClearBody;
    ORequest.Client := Self;
    ORequest.Resource := 'create-test-user';
    ORequest.ResourceSuffix := 'individuals';
    ORequest.Method := TRESTRequestMethod.rmPOST;
    ContentType := csApJson;
    // hard-coded json string -  - these are the only options allowed
    ORequest.Body.JSONWriter.WriteRaw('{"serviceNames": ["national-insurance", "self-assessment", "mtd-income-tax", "customs-services"]}');
    ORequest.Execute;
    FLastCode := ORequest.Response.StatusCode;
    FLastMsg := ORequest.Response.StatusText;
    If (ORequest.Response.StatusCode < 400) Then
    Begin
      FLastValue := ORequest.Response.JSONValue;
      Result := RESULT_OK;
    End
    Else
    Begin
      FLastError := csError + IntToStr(ORequest.Response.StatusCode) + '  ' + ORequest.Response.Content;
      Result := RESULT_FAIL;
    End;
  End
  Else
  Begin
    Result := RESULT_ERROR;
  End;
End;

(* ****************************************************************************
  *                        CHECK VRN METHODS SECTION                           *
  ******************************************************************************
  *  Check the VRN exists. The response contains brief details.                *
  **************************************************************************** *)
function THmrcTestClient.CheckVRN(const aValue, aCaller: string): integer;
begin
  Result := RESULT_NONE;
  REQ_ClearLast;
  NUS_CheckMode(amApplication);
  AuthScope := csDefault;
  If (NUS_CheckReady) Then
  Begin
    ORequest.Body.ClearBody;
    ORequest.Resource := 'organisations/vat/check-vat-number/lookup';
    ORequest.ResourceSuffix := aValue + '/' + aCaller;
    ORequest.Method := TRESTRequestMethod.rmGET;
    ORequest.Execute;
    FLastCode := ORequest.Response.StatusCode;
    FLastMsg := ORequest.Response.StatusText;
    If (ORequest.Response.StatusCode < 400) Then
    Begin
      FLastValue := ORequest.Response.JSONValue;
      Result := RESULT_OK;
    End
    Else
    Begin
      FLastError := csError + IntToStr(ORequest.Response.StatusCode) + '  ' + ORequest.Response.Content;
      Result := RESULT_FAIL;
    End;
  End
  Else
  Begin
    Result := RESULT_ERROR;
  End;
end;

(* ****************************************************************************
  *  Check the VRN exists. The response contains brief details.                *
  **************************************************************************** *)
function THmrcTestClient.CheckVRN(const aValue: string): integer;
begin
  Result := RESULT_NONE;
  REQ_ClearLast;
  NUS_CheckMode(amApplication);
  AuthScope := csDefault;
  If (NUS_CheckReady) Then
  Begin
    ORequest.Body.ClearBody;
    ORequest.Resource := 'organisations/vat/check-vat-number/lookup';
    ORequest.ResourceSuffix := aValue;
    ORequest.Method := TRESTRequestMethod.rmGET;
    ORequest.Execute;
    FLastCode := ORequest.Response.StatusCode;
    FLastMsg := ORequest.Response.StatusText;
    If (ORequest.Response.StatusCode < 400) Then
    Begin
      FLastValue := ORequest.Response.JSONValue;
      Result := RESULT_OK;
    End
    Else
    Begin
      FLastError := csError + IntToStr(ORequest.Response.StatusCode) + '  ' + ORequest.Response.Content;
      Result := RESULT_FAIL;
    End;
  End
  Else
  Begin
    Result := RESULT_ERROR;
  End;
end;


(* ****************************************************************************
  *                          TEST SERVICES SECTION                             *
  ******************************************************************************
  *  Get the list of test services available.                                  *
  **************************************************************************** *)
function THmrcTestClient.GetServices: integer;
begin
  Result := RESULT_NONE;
  REQ_ClearLast;
  NUS_CheckMode(amApplication);
  AuthScope := csDefault;
  If (NUS_CheckReady) Then
  Begin
    ORequest.Resource := 'create-test-user';
    ORequest.ResourceSuffix := 'services';
    ORequest.Method := TRESTRequestMethod.rmGET;
    ORequest.Execute;
    FLastCode := ORequest.Response.StatusCode;
    FLastMsg := ORequest.Response.StatusText;
    If (ORequest.Response.StatusCode < 400) Then
    Begin
      FLastValue := ORequest.Response.JSONValue;
      Result := RESULT_OK;
    End
    Else
    Begin
      FLastError := csError + IntToStr(ORequest.Response.StatusCode) + '  ' + ORequest.Response.Content;
      Result := RESULT_FAIL;
    End;
  End
  Else
  Begin
    Result := RESULT_ERROR;
  End;
end;

(* ****************************************************************************
  *  Call the test fraud headers resource / end point.                         *
  **************************************************************************** *)
Function THmrcTestClient.TestFraudHeaders: integer;
Begin
  Result := RESULT_NONE;
  REQ_ClearLast;
  NUS_CheckMode(amApplication);
  AuthScope := csDefault;
  If (NUS_CheckReady) Then
  Begin
    REQ_LoadHeaders;
    ORequest.Resource := 'test/fraud-prevention-headers/validate';
    ORequest.ResourceSuffix := '';
    ORequest.Method := TRESTRequestMethod.rmGET;
    ORequest.Execute;
    FLastCode := ORequest.Response.StatusCode;
    FLastMsg := ORequest.Response.StatusText;
    If (ORequest.Response.StatusCode < 400) Then
    Begin
      FLastValue := ORequest.Response.JSONValue;
      Result := RESULT_OK;
    End
    Else
    Begin
      FLastError := csError + IntToStr(ORequest.Response.StatusCode) + '  ' + ORequest.Response.Content;
      Result := RESULT_FAIL;
    End;
  End
  Else
  Begin
    Result := RESULT_ERROR;
  End;
End;
(* ****************************************************************************
  *                            TEST HELLO SECTION                              *
  ******************************************************************************
  *  Call the hello application resource / end point. Uses the server token.   *
  **************************************************************************** *)
Function THmrcTestClient.TestHelloApplication: String;
Begin
  Result := '';
  REQ_ClearLast;
  NUS_CheckMode(amApplication);
  AuthScope := csDefault;  //csHello;
  If (NUS_CheckReady) Then
  Begin
    ORequest.Method := TRESTRequestMethod.rmGET;
    ORequest.Client := Self;
    ORequest.Resource := csHello;
    ORequest.ResourceSuffix := 'application';
    ORequest.Execute;
    FLastCode := ORequest.Response.StatusCode;
    FLastMsg := ORequest.Response.StatusText;
    If (ORequest.Response.StatusCode < 400) Then
    Begin
      FLastValue := ORequest.Response.JSONValue;
      Result := FLastValue.GetValue<String>(csMessage);
    End
    Else
    Begin
      FLastError := csError + IntToStr(ORequest.Response.StatusCode) + '  ' + ORequest.Response.Content;
      Result := FLastError;
    End;
  End
  Else
  Begin
    Result := FLastError;
  End;
End;
(* ****************************************************************************
  *  Call the hello user resource / end point. Requires OAuth2 access token.   *
  *  If there is no token, it will call the get new access token method and    *
  *  when it is finished, it needs to be run again to call the api.            *
  **************************************************************************** *)
Function THmrcTestClient.TestHelloUser: String;
Begin
  Result := '';
  Try
    NUS_CheckMode(amUser);
    AuthScope := csHello;
    If (REQ_CheckToken) Then
    Begin
      REQ_ClearLast;
      REQ_Reset;
      // because we may have changed it in other calls
      BaseUrl := HmrcTestUrl;
      // hello user specific
      ORequest.Resource := cshello;
      ORequest.ResourceSuffix := 'user';
      ORequest.Execute;
      FLastCode := ORequest.Response.StatusCode;
      FLastMsg := ORequest.Response.StatusText;
      If (ORequest.Response.Status.Success) Then
      Begin
        FLastValue := ORequest.Response.JSONValue;
        Result := FLastValue.GetValue<String>(csMessage);
      End
      Else
      Begin
        FLastError := IntToStr(ORequest.Response.StatusCode) + '  ' + ORequest.Response.Content;
        Result := FLastError;
      End;
    End
    Else
    Begin
      // tell the user that there is no access token and to try again
      Result := FLastError;
      // create the new access token that will be used when they try again
      NewAccessToken('');
    End;
  Except
    On e: Exception Do
    Begin
      FLastError := csMsgTestUsrErr + e.Message;
      Result := FLastError;
    End;
  End;
End;
(* ****************************************************************************
  *  Call the hello world resource / end point. No security or validation.     *
  **************************************************************************** *)
Function THmrcTestClient.TestHelloWorld: String;
Begin
  Result := '';
  REQ_ClearLast;
  NUS_CheckMode(amNone);
  AuthScope := csDefault;
  If (NAT_CheckReady) Then
  Begin
    ORequest.Method := TRESTRequestMethod.rmGET;
    ORequest.Client := Self;
    ORequest.Resource := csHello;
    ORequest.ResourceSuffix := 'world';
    ORequest.Execute;
    FLastCode := ORequest.Response.StatusCode;
    FLastMsg := ORequest.Response.StatusText;
    If (ORequest.Response.StatusCode < 400) Then
    Begin
      FLastValue := ORequest.Response.JSONValue;
      Result := FLastValue.GetValue<String>(csMessage);
    End
    Else
    Begin
      FLastError := csError + IntToStr(ORequest.Response.StatusCode) + '  ' + ORequest.Response.Content;
      Result := FLastError;
    End;
  End
  Else
    Result := FLastError;
End;

end.
