Unit HmrcRestClient;
(* ****************************************************************************
  *                         HMRC API REST Client Unit                          *
  ******************************************************************************
  *                             VCL/FMX VERSION                                *
  ******************************************************************************
  *  This unit contains new class definitions which inherit from TRESTClient   *
  *  and add the necessary data and processes to connect to the HMRC API. It   *
  *  was originally developed as a part of the UK-DevGroup collaborative       *
  *  attempt to access the HMRC API using OAuth2 in Nov/Dec 2018.              *
  *                                                                            *
  *  Originally in a single unit, the stuff has now been separated into 3      *
  *  units: the base unit with the HmrcRestClient, which handles the           *
  *  authorisation, the VAT client unit and the PAYE client unit, which have   *
  *  methods related to the specific APIs.                                     *
  *                                                                            *
  *  It was originally developed to work with the v1.0 beta version of the     *
  *  API and HMRC warn that there are likely to be breaking changes during     *
  *  the development of their API services, so you should ensure that you are  *
  *  using an up to date version of these components.                          *
  *                                                                            *
  *  There are 3 classes of authorisation: none, application and user. These   *
  *  seem to be a standard set for REST with JSON over HTTP, which is what     *
  *  this is about. The user based process uses an OAuth2 authorisation to get *
  *  an access token from a target url, which will be on the gov/hmrc site.    *
  *  All of the API services appear to require OAuth2, except for the create   *
  *  (test) user processess, which require application authorisation and 2 of  *
  *  the "hello" connection tests. These are all handled in the                *
  *  THmrcTestClient class.                                                    *
  *                                                                            *
  *  HMRC have added an extra level to the process as "scope" and everything   *
  *  happens within a given scope. Access tokens relate to a particular scope  *
  *  and must be both aquired and used within that scope. Each API resource /  *
  *  endpoint has a scope assigned, which must be used in all calls to it.     *
  *                                                                            *
  *  The connection details and application/client key/id and secret are       *
  *  supplied by the application, being stored and loaded as appropriate.      *
  *                                                                            *
  *  The headers required for requests and submissions to the HMRC API are     *
  *  listed on the HMRC website. They depend to a certain extent on the type   *
  *  of application, so the programmer is responsible for ensuring that the    *
  *  correct values are used and for checking that the requirements have not   *
  *  changed over time.                                                        *
  *                                                                            *
  *  All calls are made in the name of a "user" on the HMRC system. They have  *
  *  a UserId as a string, which uniquely identifies them to HMRC. The classes *
  *  here have a single value, FUID, to hold this and the application will     *
  *  pass the appropriate values. For the NI API, this will be the NINo, for   *
  *  VAT it will be the VRN, etc.                                              *
  *                                                                            *
  *  Valid calls which return no data are returned with a 404 NOT FOUND error. *
  *  Why is known only to HMRC, but it appears to be the standard way of       *
  *  handling this in the web world and it does seem weird to traditional      *
  *  Delphi/database programmers. What it means is that if 404 is returned,    *
  *  it is necessary to check the text that goes with it, to see whether       *
  *  there is actually a problem, or just no data.                             *
  *                                                                            *
  *  This was written in 10.2.3 (Tokyo) and should work in some recent         *
  *  earlier versions. It uses units from the REST set which should be found   *
  *  in C:\Program Files (x86)\Embarcadero\Studio\19.0\source\data\rest or     *
  *  whatever the corresponding location would be on the machine used to       *
  *  run this code.                                                            *
  *                                                                            *
  *  Most of this code is framework neutral, but the authorisation form is     *
  *  is either VCL or FMX. There are 2 versions of this unit, one for each     *
  *  framework. It would be possible to have just one version, with IFDEFs     *
  *  around the framework specific elements, but that would require            *
  *  conditional defines in each project using the components.                 *
  *                                                                            *
  *  It has been updated by Russell Weetch based on experience with live VAT   *
  *  submissions during 2020 and he has also provided a couple of support      *
  *  units: VAT.Headers.Utils.pas & Systematic.FMX.MacAddress.pas to help      *
  *  with setting the anti-fraud headers. These 2 units are not required to    *
  *  actually make the HmrcClient component work though.                       *
  *                                                                            *
  *  There are alternative authorisation forms for VCL & FMX FMX versions,     *
  *  requires an IFDEF to pick the right unit. Note for VCL apps it requires   *
  *  a conditional define of VCL in the project manager.                       *
  *  {$IFDEF VCL}                                                              *
  *    REST.Authenticator.OAuth.WebForm.VCL                                    *
  *  {$ELSE}                                                                   *
  *    REST.Authenticator.OAuth.WebForm.FMX                                    *
  *  {$ENDIF VCL}                                                              *
  *                                                                            *
  *  Anyone is welcome to bend this for their own purposes, but no liability   *
  *  can be accepted by the authors or other contributors for any loss of or   *
  *  damage to hardware, software, data, finance, income, reputation or any    *
  *  other identifiable facet resulting from the use of this code, howsoever   *
  *  caused. In any event, maximum liability shall not exceed the amount paid  *
  *  by the user for the code.                                                 *
  *                                                                            *
  ******************************************************************************
  *  created  21/11/18 from the initial test case.                             *
  *                                                                            *
  *  version  0.8.1 beta  released 12/01/19    to include the api versions     *
  *                                            available at that time.         *
  *  version  1.0.0       released 16/12/20    includes updates from Russell   *
  *                                            Weetch.                         *
  *  version  1.0.1       released 28/01/21    updates to token methods.       *
  *                                            Combined VCL & FMX version.     *
  *  version  1.0.2       released 08/02/21    API & scope versioning. Added   *
  *                                            the universal call method.      *
  *  version  1.0.3       released 15/03/21    Tidied up Reset for 10.4.2      *
  *                                                                            *
  *  original copyright Ian Hamilton 2018/21.                                  *
  *  Contributors: Ian Hamilton, Russell Weetch.                               *
  *  License : GPL                                                             *
  *                                                                            *
  **************************************************************************** *)
Interface
(* ************************************************************************** *)
Uses
  System.Classes, System.SysUtils, System.UITypes, System.Variants,
  IPPeerClient, REST.Types, REST.Client, REST.Authenticator.OAuth,
  System.JSON,
  HmrcRestSupport;
(* ************************************************************************** *)
Type
  (* **************************************************************************
    **          Base REST Client for the HMRC REST API service                **
    **                                                                        **
    **  This handles authentication and connections, but should not be used   **
    **  directly.                                                             **
    **                                                                        **
    **  In general, the relevant User Id and scope should be set before       **
    **  making any calls to the API.                                          **
    **  Headers can be added one at a time using the AddaHeader method, or    **
    **  supplied as a list using SetHeaderList.                               **
    **  By default, IzTest is set to false, so it will automatically target   **
    **  the LIVE API service. If using it for testing please remember to set  **
    **  IzTest to true to target the TEST API.                                **
    **                                                                        **
    **  All methods will return a result as an integer. This can have 1 of 4  **
    **  values:                                                               **
    **    0 (RESULT_NONE) : Nothing - this should not be returned             **
    **    1 (RESULT_OK)   : Success - get the JSON Value returned by the API  **
    **                                from LastValue                          **
    **   -1 (RESULT_FAIL) : Failure - get the error messages from LastError   **
    **                                and LastMsg                             **
    **   -3 (RESULT_ERROR): Exception - get the exception message from        **
    **                                  LastError                             **
    **                                                                        **
    ************************************************************************** *)
  THMRCRestClient = Class(TRESTClient)
  Strict private
   class var FResetCount: Integer;
  Private
  Protected
    FApiVersion: String;                // the version of the api to target
    FApiVersioning: boolean;            // is the version of the api variable for each endpoint
    FAuthMode: THmrcAuthMode;           // the level of authentication required
    FAuthScope: String;                 // the scope of the authorisation
    FCallbackPort: String;              // call back port for authentication process
    FCallbackUrl: String;               // call back url for authentication process
    FClientId: String;                  // application/client key for login
    FClientSecret: String;              // application/client secret for login
    FIzTest: boolean;                   // test or production api
    FLastCode: integer;                 // the response code of the last http call or error value
    FLastError: String;                 // the last error/failure message
    FLastMsg: String;                   // the last http response status text
    FLastValue: TJSONValue;             // the last api response as a json value
    FOwnsHeaders: boolean;              // does it own the header list, it will need to free the list if true
    FServerToken: String;               // token for application login
    FStoreFolder: String;               // directory for api response log
    FTokenState: THmrcTokenState;       // status of current hmrc access tokens
    FUID: String;                       // unique ID for this user/customer for this service
    LAccessTokens: THmrcAccessTokens;   // a list of user access tokens from the authentication process
    LHeaderList: TStringList;           // a list for the header values required by hmrc
    LScopeList: TScopeArray;            // list of relevant scopes
    OAccessToken: THmrcAccessToken;     // the current access token
    ORequest: TRESTRequest;             // Rest client component
    // GENERAL METHODS (GEN) SECTION
    function GEN_IzValidId: boolean; virtual; // does the UID look valid
    procedure GEN_LogError(const AValue: string);  // write error code and messages to a log file
    procedure GEN_LogResponse(const AValue: string);  // write response data to a log file
    procedure INT_Scopes; virtual;
    // NEW ACCESS TOKEN (NAT) SECTION
    Function NAT_BildAuthUrl: String;     // build the OAuth2 login url
    Function NAT_CheckReady: boolean;     // check the initial values have been loaded/set
    Procedure NAT_SetOAuth2;              // set authentication parameters to get a new access token
    // a TOAuth2WebFormRedirectEvent to handle part 2 to get the access token
    Procedure NAT_TryForToken(Const aUrl: String; Var DoCloseWebView: boolean);
    // the WebForm OnClose event - close the login form
    Procedure NAT_WebFormClose(Sender: TObject; Var Action: TCloseAction);
    // REFRESH ACCESS TOKEN (RAT) SECTION
    Function RAT_RefreshToken: integer;   // get a new access token using the current refresh token
    Procedure RAT_SetOAuth2;              // set authentication parameters to refresh an access token
    // REQUEST (REQ) SECTION
    Function REQ_BildAccept: String;      // build the accept parameter string
    Function REQ_CheckToken: boolean;     // check whether there is a token and whether it is current. Try to refresh.
    Procedure REQ_ClearLast;              // clear the last response values
    Function REQ_DateFormat(Const Value: TDateTime): String; // convert date to HMRC compatible date string
    Procedure REQ_Reset;                  // reset request to defaults
    Procedure REQ_LoadHeaders;            // RPW added 21/02/2020
    // PROPERTY METHODS SECTION
    Function GetLastCode: integer;
    Function GetLastError: String;
    Function GetLastMsg: String;
    Function GetLastValue: TJSONValue;
    Procedure SetApiVersion(Const Value: String);
    Procedure SetAuthMode(Const Value: THmrcAuthMode);
    Procedure SetAuthScope(Const Value: String); virtual;
    Procedure SetCallbackUrl(Const Value: String);
    Procedure SetIzTest(Const Value: boolean);
    Procedure SetUID(Const Value: String); virtual;
  Public
    DoLoadToken: THmrcTokenLoadEvent;     // pointer to method to load saved tokens
    OnTokenChange: THmrcTokenEvent;       // pointer to method to save / update saved token
    Constructor Create(AOwner: TComponent); Override;
    Destructor Destroy; Override;
    Procedure AddaHeader(Const aName, aValue: String; Const NoEncode: boolean = False);  // add a header to the list
    Procedure AddaToken(Const uid, scp, atn, rtn: String; Const exp, tmo: TDateTime); // add a token to the tokens list
    function CallApi(const AScope: TEndPointVersion; const ARsc, ASfx, ABdy: string;
               const SPrms: TRestParams): integer; overload; virtual;     // a universal process to execute an api call
    Function ListScopes: String;          // return list of relevant scopes as a comma separated list
    Function NewAccessToken(aScope: string): boolean; // (NAT) try to login and authenticate with a user
    function ReloadToken(ScopeOnly: boolean = false): boolean;                        // (RAT) reload the current access token
    Procedure RemoveaHeader(Const aName: String);                                     // remove a header from the list
    Procedure SetaToken(Const scp, uid, atn, rtn: String; Const exp, tmo: TDateTime); // set the token values in the tokens list
    Procedure SetHeaderList(Const Value: TStringList; OwnsList: boolean = true);      // set a list of header values
    Function SetHmrcID(Const Value: String): integer; Virtual;                        // set HMRC "User" ID
    class procedure InitialiseClassVars;
    Property LastCode: integer Read GetLastCode;
    Property LastError: String Read GetLastError;
    Property LastMsg: String Read GetLastMsg;
    Property LastValue: TJSONValue Read GetLastValue;
  Published
    Property ApiVersion: String Read FApiVersion Write SetApiVersion;
    Property AuthMode: THmrcAuthMode Read FAuthMode Write SetAuthMode;
    Property AuthScope: String Read FAuthScope Write SetAuthScope;
    Property CallbackPort: String Read FCallbackPort Write FCallbackPort;
    Property CallbackUrl: String Read FCallbackUrl Write SetCallbackUrl;
    Property ClientId: String Read FClientId Write FClientId;
    Property ClientSecret: String Read FClientSecret Write FClientSecret;
    Property IzTest: boolean Read FIzTest Write SetIzTest;
    Property ServerToken: String Read FServerToken Write FServerToken;
    Property Uid: String Read FUID Write SetUID;
    // RPW
    Property StoreFolder: String Read FStoreFolder Write FStoreFolder;
    Property HeaderList: TStringList Read LHeaderList;
  End;

(* ************************************************************************** *)
Implementation
(* ************************************************************************** *)
Uses
  REST.Utils,
  System.IOUtils,
  {$IFDEF FMX}
    FMX.Dialogs,
    REST.Authenticator.OAuth.WebForm.FMX
  {$ELSE}
    VCL.Dialogs,
    REST.Authenticator.OAuth.WebForm.Win
  {$ENDIF FMX}
  ;
(* ****************************************************************************
  *                           HMRC REST CLIENT                                 *
  ******************************************************************************
  *                             INIT SECTION                                   *
  ******************************************************************************
  *  Init.                                                                     *
  **************************************************************************** *)
Constructor THMRCRestClient.Create(AOwner: TComponent);
Begin
  Inherited;
  ContentType := csApJson;
  FApiVersion := '1.0';
  FAuthMode := amNone;
  FAuthScope := '';
  FClientId := '';
  FClientSecret := '';
  BaseUrl := HmrcProdUrl;
  FCallbackUrl := '';
  FCallbackPort := '';
  FIzTest := False;
  FOwnsHeaders := true;
  FServerToken := '';
  FTokenState := tsNone;
  FUID := '';
  StoreFolder := '';
  REQ_ClearLast;
  DoLoadToken := Nil;
  OnTokenChange := Nil;
  Setlength(LScopeList, 0);
  // The base class has an FAuthenticator defined as a TCustomAuthenticator
  Authenticator := TOAuth2Authenticator.Create(Self);
  LAccessTokens := THmrcAccessTokens.Create;
  OAccessToken := Nil;
  LHeaderList := TStringList.Create;
  ORequest := TRESTRequest.Create(Nil);
  ORequest.Client := Self;
  ORequest.Accept := REQ_BildAccept;
  (Authenticator As TOAuth2Authenticator).TokenType := TOAuth2TokenType.ttBEARER;
End;
(* ****************************************************************************
  *  Free request.                                                             *
  **************************************************************************** *)
Destructor THMRCRestClient.Destroy;
Begin
  ORequest.DisposeOf;
  If (Assigned(LAccessTokens)) Then
    LAccessTokens.Free;
  If (Assigned(LHeaderList)) And (FOwnsHeaders) Then
    LHeaderList.Free;
  Inherited;
End;
(* ****************************************************************************
  *  Initialise values.                                                        *
  **************************************************************************** *)
class procedure THMRCRestClient.InitialiseClassVars;
begin
  FResetCount := 0;
end;
(* ****************************************************************************
  *  Dummy method to override.                                                 *
  **************************************************************************** *)
procedure THMRCRestClient.INT_Scopes;
begin
  ;
end;

(* ****************************************************************************
  *                         GENERAL METHODS SECTION                            *
  ******************************************************************************
  *  Check UID format/exists.                                                  *
  **************************************************************************** *)
function THMRCRestClient.GEN_IzValidId: boolean;
begin
  if (FUID <> '') then
    Result := true
  else
    Result := false;
end;

(* ****************************************************************************
  *  Write the responses to a log file if required.                            *
  **************************************************************************** *)
procedure THMRCRestClient.GEN_LogError(const AValue: string);
var
  fname: string;
  txt: string;
begin
  if (FStoreFolder <> '') then
  try
    fname := AValue + '_' + FormatDateTime('yyyymmddhhnnss', Now) + '.log';
    fname := TPath.Combine(StoreFolder, fname);
    txt := csMsgCallFail + IntToStr(FLastCode) + ' : ' + FLastMsg + ' : ' + FLastError;
    TFile.WriteAllText(fname, txt);
  except
    on E: exception do
      ;
  end;
end;

(* ****************************************************************************
  *  Write the responses to a log file if required.                            *
  **************************************************************************** *)
procedure THMRCRestClient.GEN_LogResponse(const AValue: string);
var
  fname: string;
begin
  if (FStoreFolder <> '') then
  try
    fname := AValue + '_' + FormatDateTime('yyyymmddhhnnss', Now) + '.log';
    fname := TPath.Combine(StoreFolder, fname);
    TFile.WriteAllText(fname, FLastValue.ToString);
  except
    on E: exception do
      ;
  end;
end;

(* ****************************************************************************
  *                       PUBLIC METHODS SECTION                               *
  ******************************************************************************
  *                          API CALL SECTION                                  *
  ******************************************************************************
  *  A universal call using supplied resource and suffix, but only for User    *
  *  mode authentication calls, as it performs user mode checks. It can handle *
  *  optional values for a list of parameters and/or json for posting. The     *
  *  request method defaults to GET, but can be changed.                       *
  **************************************************************************** *)
function THmrcRestClient.CallApi(const AScope: TEndPointVersion; const ARsc, ASfx, ABdy: string;
                                       const SPrms: TRestParams): integer;
var
  ix1: integer;
begin
  Result := RESULT_NONE;
  REQ_ClearLast;
  // set version and scope before reset
  ApiVersion := AScope.Version;
  AuthScope := AScope.Scope;
  // check for valid token
  If (REQ_CheckToken) Then
  try
    REQ_RESET;
    // set new target
    BaseUrl := GetBaseUrl(FIzTest);
    ORequest.Resource := ARsc;
    ORequest.ResourceSuffix := ASfx;
    // check it is using the right method
    if (AScope.Method <> REST_GET) then
    begin
       case AScope.Method of
         REST_POST   : ORequest.Method := TRESTRequestMethod.rmPOST;
         REST_PUT    : ORequest.Method := TRESTRequestMethod.rmPUT;
         REST_DELETE : ORequest.Method := TRESTRequestMethod.rmDELETE;
         REST_OTHER  : ORequest.Method := TRESTRequestMethod.rmPATCH;
       end;  // case
    end;  // if not get
    // has params ??
    if (Assigned(SPrms)) and (Length(SPrms) > 0) then
    begin
      for ix1 := 0 to Length(SPrms) - 1 do
      begin
        if (SPrms[ix1].DataIz = praQuotedText) then
          ORequest.Params.AddItem(SPrms[ix1].Name, DoubleQuote(SPrms[ix1].Value), TRESTRequestParameterKind.pkGETorPOST)
        else
          ORequest.Params.AddItem(SPrms[ix1].Name, SPrms[ix1].Value, TRESTRequestParameterKind.pkGETorPOST);
      end;
    end;
    // has a pre-formatted json string ??
    if (ABdy <> '') then
    begin
      ContentType := csApJson;
      ORequest.Body.JSONWriter.WriteRaw(ABdy);
    end;

    ORequest.Execute;

    FLastCode := ORequest.Response.StatusCode;
    FLastMsg := ORequest.Response.StatusText;
    // handle response
    If (ORequest.Response.StatusCode < 400) Then
    Begin
      FLastValue := ORequest.Response.JSONValue;
      // log the reponse if required - store folder is set
      if (FStoreFolder <> '') then
        GEN_LogResponse(AScope.ID);
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
      FLastCode := ERR_EXCEPTION;
      FLastMsg := csMsgException;
      FLastError := e.Message;
      Result := RESULT_ERROR;
    end;
  End
  Else
  Begin
    Result := RESULT_ERROR;
    // error messages set in check token
  End;

  // log the errors if required - store folder is set
  if (Result <> RESULT_OK) and (FStoreFolder <> '') then
    GEN_LogError(AScope.ID);
end;


(* *****************************************************************************
  *                       HEADER METHODS SECTION                               *
  ******************************************************************************
  *  Add a name and value to the headers list.                                 *
  **************************************************************************** *)
Procedure THMRCRestClient.AddaHeader(Const aName, aValue: String; Const NoEncode: boolean = False);
Const
  _dont_encode: Array [boolean] Of String = ('encode', 'noencode');
Begin
  LHeaderList.Add(aName + '|' + aValue + '|' + _dont_encode[NoEncode]);
End;

(* ****************************************************************************
  *  Remove an item from the headers list by name.                             *
  **************************************************************************** *)
Procedure THMRCRestClient.RemoveaHeader(Const aName: String);
Var
  I: integer;
Begin
  For I := 0 To LHeaderList.Count - 1 Do
  Begin
    If LHeaderList[I].StartsWith(aName) Then
    Begin
      LHeaderList.Delete(I);
      Exit;
    End;
  End;
End;

(* ****************************************************************************
  *                         TOKEN METHODS SECTION                              *
  ******************************************************************************
  *                     GENERAL TOKEN METHODS SECTION                          *
  ******************************************************************************
  *  Add a new token to the tokens list.                                       *
  **************************************************************************** *)
Procedure THMRCRestClient.AddaToken(Const uid, scp, atn, rtn: String; Const exp, tmo: TDateTime);
Begin
  LAccessTokens.AddToken(uid, scp, atn, rtn, exp, tmo);
End;

(* ****************************************************************************
  *  Set the token values in the tokens list.                                  *
  **************************************************************************** *)
procedure THMRCRestClient.SetaToken(const scp, uid, atn, rtn: String; const exp, tmo: TDateTime);
begin
  LAccessTokens.SetToken(scp, uid, atn, rtn, exp, tmo);
end;

(* ****************************************************************************
 *                         OTHER METHODS SECTION                               *
  ******************************************************************************
  *  Return the list of relevant scopes.                                       *
  **************************************************************************** *)
Function THMRCRestClient.ListScopes: String;
Var
  idx: integer;
Begin
  Result := '';
  If (Length(LScopeList) > 0) Then
    For idx := 0 To Length(LScopeList) - 1 Do
    Begin
      If (idx > 0) Then
        Result := Result + ',';
      Result := Result + LScopeList[idx];
    End;
End;

(* ****************************************************************************
  *  Set User ID for HMRC user login.                                          *
  **************************************************************************** *)
Function THMRCRestClient.SetHmrcID(Const Value: String): integer;
Begin
  REQ_ClearLast;
  If (Value <> '') Then
  Begin
    Uid := Value;
    Result := RESULT_OK
  End
  Else
  Begin
    FLastCode := ERR_NO_USER_ID;
    FLastError := csMsgNoUserId;
    Result := RESULT_FAIL;
  End;
End;


(* ****************************************************************************
  *                     NEW ACCESS TOKEN (NAT) SECTION                         *
  ******************************************************************************
  *  Build the login part of the initial url for authentication.               *
  **************************************************************************** *)
Function THMRCRestClient.NAT_BildAuthUrl: String;
Begin
  Result := BaseUrl + '/' + csAuthorize;
  Result := Result + '?' + csClientId + '=' + FClientId;
  Result := Result + '&' + csRedirectUri + '=' + URIEncode(FCallbackUrl);
  Result := Result + '&' + csResponseType + '=' + csCode;
  Result := Result + '&' + csScope + '=' + FAuthScope;
End;

(* ****************************************************************************
  *  Check whether any required key/secret and urls are set.                   *
  **************************************************************************** *)
Function THMRCRestClient.NAT_CheckReady: boolean;
Begin
  Result := False;
  If (FClientId = '') Then
  Begin
    FLastCode := ERR_NO_CLIENT_ID;
    FLastError := csMsgNoClient;
  End
  Else If (FClientSecret = '') Then
  Begin
    FLastCode := ERR_NO_CLIENT_SECRET;
    FLastError := csMsgNoClient;
  End
  Else If (BaseUrl = '') Then
  Begin
    FLastCode := ERR_NO_TARGET_URL;
    FLastError := csMsgNoUri;
  End
  Else if (FAuthMode = amUser) then
  begin
    If (FCallbackUrl = '') Then
    Begin
      FLastCode := ERR_NO_CALLBACK_URL;
      FLastError := csMsgNoUri;
    End
    Else If (FCallbackPort = '') Or (StrToIntDef(FCallbackPort, 0) = 0) Then
    Begin
      FLastCode := ERR_NO_CALLBACK_PORT;
      FLastError := csMsgNoPort;
    End
    else
    begin
      Result := true;
    end;
  end  // if user
  Else
  Begin
    Result := true;
  End;
End;

(* ****************************************************************************
  *  Set OAuth2 params for HMRC user login.                                    *
  **************************************************************************** *)
Procedure THMRCRestClient.NAT_SetOAuth2;
Begin
  (Authenticator As TOAuth2Authenticator).AccessToken := '';
  (Authenticator As TOAuth2Authenticator).RefreshToken := '';
  (Authenticator As TOAuth2Authenticator).TokenType := TOAuth2TokenType.ttBEARER;
  (Authenticator As TOAuth2Authenticator).ResponseType := TOAuth2ResponseType.rtTOKEN;
  (Authenticator As TOAuth2Authenticator).AccessTokenParamName := csAccessToken;
  (Authenticator As TOAuth2Authenticator).ClientId := FClientId;
  (Authenticator As TOAuth2Authenticator).ClientSecret := FClientSecret;
  (Authenticator As TOAuth2Authenticator).Scope := FAuthScope;
  (Authenticator As TOAuth2Authenticator).AuthorizationEndpoint := BaseUrl + '/' + csAuthToken;
  (Authenticator As TOAuth2Authenticator).RedirectionEndpoint := FCallbackUrl;
End;

(* ****************************************************************************
  *  Got a code, so now change that for an access token.                       *
  **************************************************************************** *)
Procedure THMRCRestClient.NAT_TryForToken(Const aUrl: String; Var DoCloseWebView: boolean);
Var
  lvPos: integer;
  lvCode: String;
  lvToken: String;
Begin
  lvCode := '';
  lvToken := '';
  // look for the parameter in the response url
  lvPos := Pos('code=', aUrl);
  If (lvPos > 0) Then
  Begin
    lvCode := Copy(aUrl, lvPos + 5, Length(aUrl));
    If (Pos('&', lvCode) > 0) Then
    Begin
      lvCode := Copy(lvCode, 1, Pos('&', lvCode) - 1);
    End;
    If (lvCode = '') Then
      Exit;
    // so it will close the login form
    DoCloseWebView := true;
    // clear the request
    ORequest.ResetToDefaults;
    ORequest.Client := Self;
    ORequest.Accept := REQ_BildAccept; // was set in create event, but has just been cleared
    // check and initialise the authenticator
    If (Not Assigned(Authenticator)) Then
      Authenticator := TOAuth2Authenticator.Create(Self);
    NAT_SetOAuth2;
    (Authenticator As TOAuth2Authenticator).AuthCode := lvCode;
    // now rebuild the request to get the access token
    ORequest.Method := TRESTRequestMethod.rmPOST;
    ORequest.Resource := csAuthToken;
    ORequest.Params.AddItem(csGrantType, csAuthCode, TRESTRequestParameterKind.pkGETorPOST);
    ORequest.Params.AddItem(csCode, URIEncode(lvCode), TRESTRequestParameterKind.pkGETorPOST);
    ORequest.Params.AddItem(csClientId, FClientId, TRESTRequestParameterKind.pkGETorPOST);
    ORequest.Params.AddItem(csClientSecret, FClientSecret, TRESTRequestParameterKind.pkGETorPOST);
    ORequest.Params.AddItem(csRedirectUri, FCallbackUrl, TRESTRequestParameterKind.pkGETorPOST);
    ORequest.Execute;
    // see what happened
    If (ORequest.Response.Status.Success) Then
    Begin
      // lvJson := ORequest.Response.JSONValue;
      If ORequest.Response.GetSimpleValue(csAccessToken, lvToken) Then
      Begin
        // check it has an access token object
        If (Not Assigned(OAccessToken)) Then
          OAccessToken := LAccessTokens.FindToken(FUID, FAuthScope);
        If (OAccessToken.Access <> lvToken) Then
        Begin
          OAccessToken.Access := lvToken; // new access token
          If ORequest.Response.GetSimpleValue(csExpiresIn, lvToken) Then
            // during testing the expiry time was always 14400 - which is 4 hours in seconds. 86400 seconds in a day.
            OAccessToken.TimeOut := Now + (StrToIntDef(lvToken, 14400) / 86400)
          Else
            OAccessToken.TimeOut := Now + 0.166; // lasts for 4 hours
          If ORequest.Response.GetSimpleValue(csRefreshToken, lvToken) Then
            OAccessToken.Refresh := lvToken; // new refresh token
          OAccessToken.Expires := Date + 547; // can refresh for up to 18 months
          // set the new access token in the authenticator
          (Authenticator As TOAuth2Authenticator).AccessToken := OAccessToken.Access;
          // this token now needs to be saved, but that is for the owner application
          // check whether we can save the changes
          If (Assigned(@OnTokenChange)) Then
          Begin
            OnTokenChange(Self, FUID, FAuthScope, OAccessToken.Access, OAccessToken.Refresh, OAccessToken.Expires,
              OAccessToken.TimeOut);
            FTokenState := tsOK;
          End
          Else
            FTokenState := tsUpdated;
        End;
      End // if token
      Else
      Begin
        Raise Exception.Create(csMsgNoTokenRtn);
      End;
    End // if success
    Else
    Begin
      Raise Exception.Create(csMsgBadResponse);
    End;
  End; // if pos > 0
End;

(* ****************************************************************************
  *  Close the login form - fired as an event.                                 *
  **************************************************************************** *)
Procedure THMRCRestClient.NAT_WebFormClose(Sender: TObject; Var Action: TCloseAction);
Var
  lvForm: Tfrm_OAuthWebForm;
Begin
  lvForm := Sender AS Tfrm_OAuthWebForm;
  If (lvForm <> Nil) Then
  Begin
    lvForm.OnAfterRedirect := Nil;
    lvForm.Release;
  End;
End;

(* ****************************************************************************
  *  Try to login and get a new user access token.                             *
  *  Added the optional authorisation scope 09/12/20, in case it is used in a  *
  *  situation where the scope has not been set.                               *
  **************************************************************************** *)
Function THMRCRestClient.NewAccessToken(aScope: string): boolean;
Var
  lvForm: Tfrm_OAuthWebForm;
  lURL: String;
Begin
  Result := False;
  // supplied an authorisation scope
  if (aScope <> '') then
    FAuthScope := aScope;
  If (NAT_CheckReady) Then
  Begin
    lURL := NAT_BildAuthUrl;
    lvForm := Tfrm_OAuthWebForm.Create(Owner);
    lvForm.OnAfterRedirect := NAT_TryForToken; // possibly use OnBeforeRedirect on Android/Mobile ??
    lvForm.Caption := csHmrcLogin;
    lvForm.OnClose := NAT_WebFormClose;
    lvForm.ShowWithURL(lUrl);
    // do we know the outcome here ?
    Result := true; // at least there were no errors up to this point
  End
  Else
    Raise Exception.Create(FLastError);
End;

(* ****************************************************************************
  *                    REFRESH ACCESS TOKEN (RAT) SECTION                      *
  ******************************************************************************
  *  Get a new access token using the current refresh token.                   *
  **************************************************************************** *)
Function THMRCRestClient.RAT_RefreshToken: integer;
Var
  lvToken: String;
Begin
  Result := RESULT_NONE;
  Try
    REQ_ClearLast;
    REQ_Reset;
    RAT_SetOAuth2;
    // now rebuild the request to get the new access token
    ORequest.Method := TRESTRequestMethod.rmPOST;
    ORequest.Resource := csAuthToken;
    ORequest.Params.AddItem(csGrantType, csRefreshToken, TRESTRequestParameterKind.pkGETorPOST);
    ORequest.Params.AddItem(csRefreshToken, OAccessToken.Refresh, TRESTRequestParameterKind.pkGETorPOST);
    ORequest.Params.AddItem(csClientId, FClientId, TRESTRequestParameterKind.pkGETorPOST);
    ORequest.Params.AddItem(csClientSecret, FClientSecret, TRESTRequestParameterKind.pkGETorPOST);
    ORequest.Params.AddItem(csRedirectUri, FCallbackUrl, TRESTRequestParameterKind.pkGETorPOST);
    ORequest.Execute;
    FLastCode := ORequest.Response.StatusCode;
    FLastMsg := ORequest.Response.StatusText;
    // see what happened
    If (ORequest.Response.Status.Success) Then
    Begin
      If ORequest.Response.GetSimpleValue(csAccessToken, lvToken) Then
      Begin
        If (OAccessToken.Access <> lvToken) Then
        Begin
          // access token for scope
          OAccessToken.Access := lvToken;
          If ORequest.Response.GetSimpleValue(csExpiresIn, lvToken) Then
            // during testing the expiry time was always 14400 - which is 4 hours in seconds.
            OAccessToken.TimeOut := Now + (StrToIntDef(lvToken, 14400) / 86400)
          Else
            // access token expiry is in 4 hours
            OAccessToken.TimeOut := Now + 0.166;
          // get the new refresh token
          If ORequest.Response.GetSimpleValue(csRefreshToken, lvToken) Then
          Begin
            OAccessToken.Refresh := lvToken;
          End;
          // set the new access token in the authenticator
          (Authenticator As TOAuth2Authenticator).AccessToken := OAccessToken.Access;
          // check whether we can save the changes
          If (Assigned(@OnTokenChange)) Then
          Begin
            OnTokenChange(Self, FUID, FAuthScope, OAccessToken.Access, OAccessToken.Refresh, OAccessToken.Expires,
              OAccessToken.TimeOut);
            FTokenState := tsOK;
          End
          Else
            FTokenState := tsUpdated;
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
  *  Set OAuth2 params for HMRC access token refresh.                          *
  *  Assumes that there is a current access token to refresh.                  *
  **************************************************************************** *)
Procedure THMRCRestClient.RAT_SetOAuth2;
Begin
  (Authenticator As TOAuth2Authenticator).AccessToken := '';
  (Authenticator As TOAuth2Authenticator).RefreshToken := OAccessToken.Refresh;
  (Authenticator As TOAuth2Authenticator).TokenType := TOAuth2TokenType.ttBEARER;
  (Authenticator As TOAuth2Authenticator).ResponseType := TOAuth2ResponseType.rtTOKEN;
  (Authenticator As TOAuth2Authenticator).ClientId := FClientId;
  (Authenticator As TOAuth2Authenticator).ClientSecret := FClientSecret;
  (Authenticator As TOAuth2Authenticator).Scope := FAuthScope;
  (Authenticator As TOAuth2Authenticator).AuthorizationEndpoint := BaseUrl + '/' + csAuthToken;
  (Authenticator As TOAuth2Authenticator).RedirectionEndpoint := FCallbackUrl;
End;

(* ****************************************************************************
  *  Reload the current access token either by uid & scope or just scope.      *
  **************************************************************************** *)
function THMRCRestClient.ReloadToken(ScopeOnly: boolean): boolean;
begin
  Result := false;
  if (ScopeOnly) then
    OAccessToken := LAccessTokens.TokenByScope(FAuthScope)
  else
    OAccessToken := LAccessTokens.GetAccessToken(FUID, FAuthScope);

  if (Assigned(OAccessToken)) then
    Result := true;
end;


(* ****************************************************************************
  *                          REQUEST SETTING SECTION                           *
  ******************************************************************************
  *  Create the accept header for the request with the current api version.    *
  **************************************************************************** *)
Function THMRCRestClient.REQ_BildAccept: String;
Begin
  Result := csApVnd + FApiVersion + csWithJson;
End;

(* ****************************************************************************
  *  Check whether there is a token, it is current and can be refreshed.       *
  *  Here it is only interested in User mode OAuth2 access tokens.
  **************************************************************************** *)
Function THMRCRestClient.REQ_CheckToken: boolean;
var
  loaded: boolean;
Begin
  Result := true;
  FTokenState := tsNone;
  // only interested in User mode OAuth2 access tokens
  If (FAuthMode = amUser) Then
  Begin
    // is there an access token object ? if not, then try to load one, otherwise it will need to get a new token
    If (Not Assigned(OAccessToken)) Then
    Begin
      if (Assigned(@DoLoadToken)) then
      begin
        loaded := false;
        DoLoadToken(Self, FUID, FAuthScope, loaded);
        if (loaded) then
          OAccessToken := LAccessTokens.GetAccessToken(FUID, FAuthScope);
      end;
    end;
    // does it have an access token now?
    If (Assigned(OAccessToken)) Then
    Begin
      // no token should be an error condition, but just get a new access token - not failed yet
      If (OAccessToken.Access <> '') Then
      Begin
        // has it expired ?
        If (OAccessToken.Expires < Date) Then
        Begin
          FTokenState := tsExpired;
          FLastError := csMsgTokenExp;
          FLastCode := ERR_TOKEN_EXPIRED;
          Result := False;
        End // if expired
        Else
        Begin
          // has it timed out ?
          If (OAccessToken.TimeOut < Now) Then
          Begin
            // does it have a refresh token
            If (OAccessToken.Refresh <> '') Then
            Begin
              // try to refresh the access token
              If (RAT_RefreshToken <> RESULT_OK) Then
              Begin
                // ???    // set token state to expired
                FTokenState := tsExpired;
                FLastError := csMsgTokenExp;
                FLastCode := ERR_TOKEN_EXPIRED;
                Result := False;
              End;
            End
            Else
            Begin
              // cannot refresh, so set as expired
              FTokenState := tsExpired;
              FLastError := csMsgTokenExp;
              FLastCode := ERR_TOKEN_EXPIRED;
              Result := False;
            End;
          End // if timed out
          Else
          Begin
            FTokenState := tsOK;
          End; // else ok
        End; // else not expired
      End // if not empty
      Else
      Begin
        FLastError := csMsgNoTokenFnd;
        FLastCode := ERR_NO_ACCESS_TOKEN;
        Result := False;
      End; // else no token value
    End // if has access token
    Else
    Begin
      FLastError := csMsgNoTokenFnd;
      FLastCode := ERR_NO_ACCESS_TOKEN;
      Result := False;
    End; // else no token object
  End;
End;

(* ****************************************************************************
  *  Clear the last response values.                                           *
  **************************************************************************** *)
Procedure THMRCRestClient.REQ_ClearLast;
Begin
  FLastCode := 0;
  FLastError := '';
  FLastMsg := '';
  FLastValue := Nil;
End;

(* ****************************************************************************
  *  convert date to HMRC compatible date string.                              *
  **************************************************************************** *)
Function THMRCRestClient.REQ_DateFormat(Const Value: TDateTime): String;
Begin
  Result := FormatDateTime('YYYY-MM-DD', Value);
End;

(* ****************************************************************************
  *  Load header list into headers with requierd encoding.                     *
  **************************************************************************** *)
Procedure THMRCRestClient.REQ_LoadHeaders;
Var
  ix1: integer;
  Vals: TArray<String>;
Begin
  If (Assigned(LHeaderList)) And (LHeaderList.Count > 0) Then
  Begin
    For ix1 := 0 To LHeaderList.Count - 1 Do
    Begin
      Vals := LHeaderList[ix1].Split(['|']);
      If (Length(Vals) = 3) And (Vals[2] = 'noencode') Then
      Begin
        ORequest.Params.AddHeader(Vals[0], Vals[1]).Options := [poDoNotEncode];
      End
      Else
      Begin
        // don't think we need to encode here as it could result in double encoding, which is not pretty
        ORequest.Params.AddHeader(Vals[0], Vals[1]);
        // ORequest.Params.AddHeader(Vals[0], UriEncode(Vals[1]));
      End;
    End;
  End;
End;

(* ****************************************************************************
  *  Reset the request parameters to defaults and rebuild headers.             *
  **************************************************************************** *)
Procedure THMRCRestClient.REQ_Reset;
Begin
  if FResetCount > 0 then
    ORequest.ResetToDefaults;

  Inc(FResetCount);
  // because we did reset to defaults
  ContentType := csApJson;
  ORequest.Method := TRESTRequestMethod.rmGET;
  ORequest.Client := Self;
  ORequest.Accept := REQ_BildAccept;
  // add gov and vendor headers if supplied
  REQ_LoadHeaders;
  // check access token and scope are set
  if (Assigned(OAccessToken)) then
    (Authenticator As TOAuth2Authenticator).AccessToken := OAccessToken.Access
  else
    (Authenticator As TOAuth2Authenticator).AccessToken := '';
  (Authenticator As TOAuth2Authenticator).Scope := FAuthScope;
End;


(* ****************************************************************************
  *                         PROPERTY METHODS SECTION                           *
  ******************************************************************************
  *  Get the last http status code.                                            *
  **************************************************************************** *)
Function THMRCRestClient.GetLastCode: integer;
Begin
  Result := FLastCode;
End;

(* ****************************************************************************
  *  Get the last error/failure message.                                       *
  **************************************************************************** *)
Function THMRCRestClient.GetLastError: String;
Begin
  Result := FLastError;
End;

(* ****************************************************************************
  *  Get the last http status message.                                         *
  **************************************************************************** *)
Function THMRCRestClient.GetLastMsg: String;
Begin
  Result := FLastMsg;
End;

(* ****************************************************************************
  *  Get the last response json value.                                         *
  **************************************************************************** *)
Function THMRCRestClient.GetLastValue: TJSONValue;
Begin
  Result := FLastValue;
End;

(* ****************************************************************************
  *  Reset the accept parameters with the new api version.                     *
  **************************************************************************** *)
Procedure THMRCRestClient.SetApiVersion(Const Value: String);
Begin
  If (Not AnsiSametext(Value, FApiVersion)) Then
  Begin
    FApiVersion := Value;
    ORequest.Accept := REQ_BildAccept;
    Self.Accept := REQ_BildAccept;
  End;
End;

(* ****************************************************************************
  *  Set OAuth2 params for HMRC user login.                                    *
  **************************************************************************** *)
Procedure THMRCRestClient.SetAuthMode(Const Value: THmrcAuthMode);
Begin
  FAuthMode := Value;
End;

(* ****************************************************************************
  *  Set OAuth2 params for HMRC user login and try to find the access token.   *
  **************************************************************************** *)
Procedure THMRCRestClient.SetAuthScope(Const Value: String);
Begin
  if (FAuthScope <> Value) then
  begin
    FAuthScope := Value;
    (Authenticator As TOAuth2Authenticator).Scope := FAuthScope;

    if (FUID <> '') then
    begin
      if (Assigned(OAccessToken)) then
      begin
        if (AnsiSameText(OAccessToken.UID, FUID)) and (AnsiSameText(OAccessToken.Scope, FAuthScope)) then
          Exit
        else
          OAccessToken := LAccessTokens.GetAccessToken(FUID, FAuthScope);
      end
      else
        OAccessToken := LAccessTokens.GetAccessToken(FUID, FAuthScope);
    end;  // if uid
  end;  // if changed
End;

(* ****************************************************************************
  *  Set OAuth2 params for HMRC user login.                                    *
  **************************************************************************** *)
Procedure THMRCRestClient.SetCallbackUrl(Const Value: String);
Begin
  FCallbackUrl := Value;
End;

(* ****************************************************************************
  *  Set the header list.                                                      *
  **************************************************************************** *)
Procedure THMRCRestClient.SetHeaderList(Const Value: TStringList; OwnsList: boolean);
Begin
  If (Assigned(Value)) Then
  Begin
    If (Assigned(LHeaderList)) And (FOwnsHeaders) Then
      LHeaderList.Free;
    LHeaderList := Value;
    FOwnsHeaders := OwnsList;
  End;
End;

(* ****************************************************************************
  *  Set the test status - changes the base url.                               *
  **************************************************************************** *)
Procedure THMRCRestClient.SetIzTest(Const Value: boolean);
Begin
  If (FIzTest <> Value) Then
  Begin
    FIzTest := Value;
    If (FIzTest) Then
      BaseUrl := HmrcTestUrl
    Else
      BaseUrl := HmrcProdUrl;
  End;
End;

(* ****************************************************************************
  *  Set User ID for HMRC user login and try to find the access token.         *
  **************************************************************************** *)
Procedure THMRCRestClient.SetUID(Const Value: String);
Begin
  if (FUID <> Value) then
  begin
    FUID := Value;

    if (FAuthScope <> '') then
    begin
      if (Assigned(OAccessToken)) then
      begin
        if (AnsiSameText(OAccessToken.UID, FUID)) and (AnsiSameText(OAccessToken.Scope, FAuthScope)) then
          Exit
        else
          OAccessToken := LAccessTokens.GetAccessToken(FUID, FAuthScope);
      end
      else
        OAccessToken := LAccessTokens.GetAccessToken(FUID, FAuthScope);
    end;  // if scope
  end;  // if changed
End;

(* ************************************************************************** *)
initialization
THMRCRestClient.InitialiseClassVars;
End.
