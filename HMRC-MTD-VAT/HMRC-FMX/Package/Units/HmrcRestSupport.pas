unit HmrcRestSupport;

(*****************************************************************************
*                        HMRC API REST Support Unit                          *
******************************************************************************
*  Support types and values for the HMRC REST Client components              *
*                                                                            *
*  created 24/11/18.                                                         *
*  updated 16/12/20.    Added VAT support types and processes.               *
*  updated 27/12/20.    Removed VAT support to separate unit.                *
*  updated 08/02/21.    Added endpoint version and a couple of constants +   *
*                       Rest Params record and array.                        *
*                                                                            *
*  version 1.0.4                                                             *
*                                                                            *
*  original copyright Ian Hamilton 2018/21.                                  *
*  License : GPL                                                             *
*****************************************************************************)

interface
(****************************************************************************)
uses
  System.Classes, System.SysUtils, System.Types, System.UITypes, System.Variants,
  System.JSON;

(****************************************************************************)
const
  REST_ = 'REST';

  // some string constants
  csAccessToken      = 'access_token';
  csAddress          = 'address';
  csAmount           = 'amount';
  csApJson           = 'application/json';
  csApVnd            = 'application/vnd.hmrc.';
  csAuthorization    = 'Authorization';
  csAuthorize        = 'oauth/authorize';
  csAuthToken        = 'oauth/token';
  csAuthCode         = 'authorization_code';
  csClientCreds      = 'client_credentials';
  csClientId         = 'client_id';
  csClientSecret     = 'client_secret';
  csCode             = 'code';
  csContentType      = 'content-type';
  csCountryCode      = 'countryCode';
  csDue              = 'due';
  csEnd              = 'end';
  csError            = 'Error : ';
  csExpiresIn        = 'expires_in';
  csFinalised        = 'finalised';
  csFrom             = 'from';
  csGrantType        = 'grant_type';
  csHmrcLogin        = 'HMRC Service Login';
  csIsoDate          = 'YYYYMMDD';
  csLBearer          = 'bearer';
  csLiabilities      = 'liabilities';
  csLine1            = 'line1';
  csMessage          = 'message';
  csName             = 'name';
  csObligations      = 'obligations';
  csPaymentIndicator = 'paymentIndicator';
  csPayments         = 'payments';
  csPeriodKey        = 'periodKey';
  csPostcode         = 'postcode';
  csProcessingDate   = 'processingDate';
  csReceiptId        = 'Receipt-Id';
  csReceived         = 'received';
  csRedirectUri      = 'redirect_uri';
  csRefreshToken     = 'refresh_token';
  csResponseType     = 'response_type';
  csReturns          = 'returns';
  csScope            = 'scope';
  csStart            = 'start';
  csStatus           = 'status';
  csTarget           = 'target';
  csTaxPeriod        = 'taxPeriod';
  csTo               = 'to';
  csTokenType        = 'token_type';
  csType             = 'type';
  csUBearer          = 'Bearer';
  csWithJson         = '+json';
  csXCorrelationid   = 'X-Correlationid';

  // some messages
  csMsgBadData     = 'The data is either invalid or incomplete';
  csMsgBadPeriod   = 'The VAT Period is invalid';
  csMsgBadResponse = 'HTTP Reponse error.';
  csMsgBadTarget   = 'The target name is invalid.';
  csMsgBadUserId   = 'Invalid User ID found.';
  csMsgCallFail    = 'Called failed with: ';
  csMsgDateError   = 'Search date error - the start date must be before the end date.';
  csMsgDateHigh    = 'The start date is too late.';
  csMsgDateLow     = 'The start date is too early.';
  csMsgDateRange   = 'The search date range is too great.';
  csMsgException   = 'Processing Error.';
  csMsgNewToken    = 'Please get a new token.';
  csMsgNoClient    = 'A client id and secret must be supplied.';
  csMsgNoData      = 'No data was supplied for submission.';
  csMsgNoPort      = 'A valid callback port must be supplied.';
  csMsgNoSvrToken  = 'No server token found.';
  csMsgNoTokenFnd  = 'No access token found. PLease get an access token and try again.';
  csMsgNoTokenRtn  = 'No access token returned.';
  csMsgNoUri       = 'Base and callback URLs must be supplied.';
  csMsgNoUserId    = 'No User ID found.';
  csMsgNoAcsToken  = 'There is no access token for this user and scope. ';
  csMsgNoRefresh   = 'Unable to refresh the access token.';
  csMsgNoRfsToken  = 'There is no refresh token for this user and scope.';
  csMsgRefreshErr  = 'Error trying to refresh the access token : ';
  csMsgTestUsrErr  = 'Hello user test error : ';
  csMsgTokenErr    = 'Unknown token error - unable to continue.';
  csMsgTokenExp    = 'The access token for this user and scope has expired.';

  csResponseNoData = 'The remote endpoint has indicated that no data can be found';

  HmrcProdUrl = 'https://api.service.hmrc.gov.uk';
  HmrcTestUrl = 'https://test-api.service.hmrc.gov.uk';

  // some random error values
  ERR_NO_ACCESS_TOKEN   = 1101;
  ERR_NO_CALLBACK_PORT  = 1102;
  ERR_NO_CALLBACK_URL   = 1103;
  ERR_NO_CLIENT_ID      = 1104;
  ERR_NO_CLIENT_SECRET  = 1105;
  ERR_NO_DATA           = 1106;
  ERR_NO_REFRESH_TOKEN  = 1107;
  ERR_NO_SERVER_TOKEN   = 1108;
  ERR_NO_TARGET_URL     = 1109;
  ERR_NO_USER_ID        = 1110;

  ERR_EXCEPTION         = 1113;

  ERR_TOKEN_EXPIRED     = 1115;

  ERR_DATE_ERROR        = 1121;
  ERR_DATE_LOW          = 1122;
  ERR_DATE_HIGH         = 1123;
  ERR_DATE_RANGE        = 1124;

  ERR_INVALID_USER_ID   = 1131;
  ERR_INVALID_PERIOD    = 1132;
  ERR_INVALID_TARGET    = 1133;
  ERR_INVALID_DATA      = 1134;

  // function result values
  RESULT_NONE   = 0;
  RESULT_OK     = 1;
  RESULT_FAIL   = -1;
  RESULT_NODATA = -2;
  RESULT_ERROR  = -3;

  REST_GET    = 0;
  REST_POST   = 1;
  REST_PUT    = 2;
  REST_DELETE = 3;
  REST_OTHER  = 4;

(****************************************************************************)
type
  (***************************************************************************
  **            HMRC REST API service authentication modes                  **
  ***************************************************************************)
  THmrcAuthMode = (amNone, amApplication, amUser);

  (***************************************************************************
  **          HMRC REST API service current token status modes              **
  ***************************************************************************)
  THmrcTokenState = (tsNone, tsOK, tsRefresh, tsExpired, tsUpdated);

  (***************************************************************************
  **              HMRC REST API token saving signature                      **
  ** where                                                                  **
  **   uid = the unique identifier (VAT : VRN / NI : NINo / PAYE : UTR).    **
  **   scp = the scope for which the tokens were granted.                   **
  **   atn = the access token.                                              **
  **   rtn = the refresh token.                                             **
  **   exp = the expiry date/time of the access token.                      **
  **   tmo = the date on which the refresh process will time out and stop   **
  **         working.                                                       **
  ***************************************************************************)
  THmrcTokenEvent = procedure(Sender: TObject; const uid, scp, atn, rtn: string; const exp, tmo: TDateTime) of object;

  THmrcTokenLoadEvent = procedure(Sender: TObject; const uid, scp: string; var haz: boolean) of object;

  (***************************************************************************
  **              Relevant scopes as an array of string                     **
  ***************************************************************************)
  TScopeArray = Array of string;

  (***************************************************************************
  **                HMRC REST API user access tokens                        **
  ****************************************************************************
  **  A simple object to hold an access token.                              **
  ***************************************************************************)
  THmrcAccessToken = class
  public
    UID     : string;     // User/ company/ Agent ID
    Scope   : string;     // Authorisation scope
    Access  : string;     // access token
    Refresh : string;     // refresh token
    Expires : TDateTime;  // when it can no longer be refreshed (18 months)  // DateToStr
    TimeOut : TDateTime;  // When the current access token times out (4 hours) // Format[DD-MM-YYYY HH:NN:SS]  DateTimeToStr
    Status  : THmrcTokenState;  // current token state
  end;

  (***************************************************************************
  **  A list to hold access tokens.                                         **
  ***************************************************************************)
  THmrcAccessTokens = class (TList)
  public
    Destructor Destroy; override;
    // add a new access token for user id and scope
    procedure AddToken(const aUID, aScope, aToken, aRefresh: string; const anExpiry, aTimeOut: TDateTime);
    // find or create an access token for user id and scope
    function  FindToken(const aUID, aScope: string): THmrcAccessToken;
    // get an access token for user id and scope, but return nil if not found
    function  GetAccessToken(const aUID, aScope: string): THmrcAccessToken;
    // set the values for the token onject with this scope
    procedure SetToken(const aScope, aUID, aToken, aRefresh: string; const anExpiry, aTimeOut: TDateTime);
    // get the access token onject with this scope, but return nil if not found
    function  TokenByScope(const AScope: string): THmrcAccessToken;
  end;

  (***************************************************************************
  **                   HMRC REST API Client Details                         **
  ****************************************************************************
  **  A simple object to hold the list of application/client details.       **
  ***************************************************************************)
  THmrcClientDetails = class
  private
    FClientId     : string;
    FClientSecret : string;
    FCallbackPort : string;
    FCallbackUrl  : string;
    FServerToken  : string;
    FBaseUrl      : string;
    FAppName      : string;
    FAppGuid      : string;
  public
    property ClientId     : string  read FClientId      write FClientId;
    property ClientSecret : string  read FClientSecret  write FClientSecret;
    property CallbackPort : string  read FCallbackPort  write FCallbackPort;
    property CallbackUrl  : string  read FCallbackUrl   write FCallbackUrl;
    property ServerToken  : string  read FServerToken   write FServerToken;
    property BaseUrl      : string  read FBaseUrl       write FBaseUrl;
    property AppName      : string  read FAppName       write FAppName;
    property AppGuid      : string  read FAppGuid       write FAppGuid;
  end;

  (***************************************************************************
  **                   HMRC REST API VERSION & SCOPE                        **
  ****************************************************************************
  **  A simple record to hold the current values of version & scope.        **
  ***************************************************************************)
  TEndPointVersion = Record
    ID      : string;
    Version : string;
    Scope   : string;
    Method  : integer;
  end;


  (***************************************************************************
  **                   Rest Params for universal call                       **
  ****************************************************************************
  **  A simple record to hold a name, value and data type + an array.       **
  ***************************************************************************)
  TParamAz = (praPlainText, praQuotedText, praNumber);

  TRestParam = Record
    Name  : string;
    Value : string;
    DataIz: TParamAz;
  end;

  PRestParam = ^TRestParam;

  TRestParams = Array of TRestParam;



(*****************************************************************************
*                             GENERAL METHODS                                *
******************************************************************************
*  Date functions                                                            *
*****************************************************************************)
function HmrcDateStrToDate(const aValue: string): TDateTime; overload;

function HmrcDateStrToDate(const aValue: string; aDefault: TDateTime): TDateTime; overload;

Function DoshFormat(const AValue: double): string; inline;

function DoubleQuote(const AValue: string): string; inline;

// return the base url for either test or production
function GetBaseUrl(const IsTest: boolean): string;


(****************************************************************************)
implementation
(****************************************************************************)


(*****************************************************************************
*                             GENERAL METHODS                                *
******************************************************************************
*                         DATE CONVERSION METHODS                            *
******************************************************************************
* Convert a date in HMRC (ISO) date string format (YYYY-MM-DD) to a date.    *
*****************************************************************************)
function HmrcDateStrToDate(const aValue: string): TDateTime; overload;
var
  yr, mn, dy: Word;
begin
  if (Length(aValue) = 10) then
  begin
    yr := StrToIntDef(Copy(aValue, 1, 4), 0);
    mn := StrToIntDef(Copy(aValue, 6, 2), 0);
    dy := StrToIntDef(Copy(aValue, 9, 2), 0);
  end
  else if (Length(aValue) = 8) then
  begin
    yr := StrToIntDef(Copy(aValue, 1, 4), 0);
    mn := StrToIntDef(Copy(aValue, 5, 2), 0);
    dy := StrToIntDef(Copy(aValue, 7, 2), 0);
  end
  else begin
    Result := 0;
    Exit;
  end;

  if (yr = 0) or (mn = 0) or (dy = 0) then
    Result := 0
  else
    Result := EncodeDate(yr, mn, dy);
end;

(*****************************************************************************
*  As above, but with a default value for error situations.                  *
*****************************************************************************)
function HmrcDateStrToDate(const aValue: string; aDefault: TDateTime): TDateTime; overload;
var
  yr, mn, dy: Word;
begin
  if (Length(aValue) = 10) then
  begin
    yr := StrToIntDef(Copy(aValue, 1, 4), 0);
    mn := StrToIntDef(Copy(aValue, 6, 2), 0);
    dy := StrToIntDef(Copy(aValue, 9, 2), 0);
  end
  else if (Length(aValue) = 8) then
  begin
    yr := StrToIntDef(Copy(aValue, 1, 4), 0);
    mn := StrToIntDef(Copy(aValue, 5, 2), 0);
    dy := StrToIntDef(Copy(aValue, 7, 2), 0);
  end
  else begin
    Result := aDefault;
    Exit;
  end;

  if (yr = 0) or (mn = 0) or (dy = 0) then
    Result := aDefault
  else
    Result := EncodeDate(yr, mn, dy);
end;

(*****************************************************************************
*                           FORMAT FUNCTIONS                                 *
******************************************************************************
*  Format a double as currency.                                              *
*****************************************************************************)
Function DoshFormat(const AValue: double): string;
begin
  Result := '£' + Trim(Format('%12.2f', [AValue]));
end;

(*****************************************************************************
*  Just bracket the supplied string with double quotes.                      *
*****************************************************************************)
function DoubleQuote(const AValue: string): string; inline;
begin
  Result := '"' + AValue + '"';
end;

(*****************************************************************************
*                             URL FUNCTIONS                                  *
******************************************************************************
*  return the base url for either test or production.                        *
*****************************************************************************)
function GetBaseUrl(const IsTest: boolean): string;
begin
  if IsTest then
    Result := HmrcTestUrl
  else
    Result := HmrcProdUrl;
end;

{ THmrcAccessTokens }

(*****************************************************************************
*                   HMRC REST API user access tokens                         *
******************************************************************************
*  Clear up.                                                                 *
*****************************************************************************)
destructor THmrcAccessTokens.Destroy;
var
  idx: integer;
  obj: THmrcAccessToken;
begin
  if Count > 0 then
    for idx := Count - 1 downto 0 do
    begin
      obj := THmrcAccessToken(Items[idx]);
      Remove(obj);
      obj.Free;
    end;

  inherited;
end;

(*****************************************************************************
*  Add a new token to the list.                                              *
*****************************************************************************)
procedure THmrcAccessTokens.AddToken(const aUID, aScope, aToken, aRefresh: string; const anExpiry, aTimeOut: TDateTime);
var
  idx: integer;
  dun: boolean;
  obj: THmrcAccessToken;
begin
  dun := false;
  // check whether this combination already exists
  if Count > 0 then
  begin
    for idx := 0 to Count - 1 do
    begin
      obj := THmrcAccessToken(Items[idx]);
      if (AnsiSameText(obj.UID, aUID)) and (AnsiSameText(obj.Scope, aScope)) then
      begin
        dun := true;
        Break;
      end;
    end;
  end;
  // need to add it to the list
  if (not dun) then
  begin
    obj := THmrcAccessToken.Create;
    obj.UID := aUID;
    obj.Scope := aScope;
    Self.Add(obj);
  end;
  obj.Access  := aToken;
  obj.Refresh := aRefresh;
  obj.Expires := anExpiry;
  obj.TimeOut := aTimeOut;

  // check status
  if (anExpiry < Date) then
    obj.Status := tsExpired
  else if (aTimeOut < Now) then
    obj.Status := tsRefresh
  else
    obj.Status := tsOK;
end;

(*****************************************************************************
*  Add a new token to the list.                                              *
*****************************************************************************)
function THmrcAccessTokens.FindToken(const aUID, aScope: string): THmrcAccessToken;
var
  idx: integer;
  dun: boolean;
  obj: THmrcAccessToken;
begin
  Result := nil;
  dun := false;
  // check whether this combination already exists
  if Count > 0 then
  begin
    for idx := 0 to Count - 1 do
    begin
      obj := THmrcAccessToken(Items[idx]);
      if (AnsiSameText(obj.UID, aUID)) and (AnsiSameText(obj.Scope, aScope)) then
      begin
        dun := true;
        Result := obj;
        Break;
      end;
    end;
  end;
  // need to add it to the list
  if (not dun) then
  begin
    obj := THmrcAccessToken.Create;
    obj.UID := aUID;
    obj.Scope := aScope;
    obj.Status := tsUpdated;
    Self.Add(obj);
    Result := obj;
  end;
end;

(*****************************************************************************
*  Find a token in the list.                                                 *
*****************************************************************************)
function THmrcAccessTokens.GetAccessToken(const aUID, aScope: string): THmrcAccessToken;
var
  idx: integer;
  obj: THmrcAccessToken;
begin
  Result := nil;
  if Count > 0 then
  begin
    for idx := 0 to Count - 1 do
    begin
      obj := THmrcAccessToken(Items[idx]);
      if (AnsiSameText(obj.UID, aUID)) and (AnsiSameText(obj.Scope, aScope)) then
      begin
        Result := obj;
        Break;
      end;
    end;
  end;
end;

(*****************************************************************************
*  Set the values for the token in the list with this scope.                 *
*****************************************************************************)
procedure THmrcAccessTokens.SetToken(const aScope, aUID, aToken, aRefresh: string; const anExpiry, aTimeOut: TDateTime);
var
  obj: THmrcAccessToken;
begin
  // find or add a scope
  obj := TokenByScope(aScope);
  if (not Assigned(obj)) then
  begin
    obj := THmrcAccessToken.Create;
    Self.Add(obj);
  end;
  // now set values
  obj.UID := aUID;
  obj.Scope := aScope;
  obj.Access  := aToken;
  obj.Refresh := aRefresh;
  obj.Expires := anExpiry;
  obj.TimeOut := aTimeOut;

  // check status
  if (anExpiry < Date) then
    obj.Status := tsExpired
  else if (aTimeOut < Now) then
    obj.Status := tsRefresh
  else
    obj.Status := tsOK;
end;

(*****************************************************************************
*  Find the token in the list for this scope.                                *
*****************************************************************************)
function THmrcAccessTokens.TokenByScope(const AScope: string): THmrcAccessToken;
var
  idx: integer;
  obj: THmrcAccessToken;
begin
  Result := nil;
  if Count > 0 then
  begin
    for idx := 0 to Count - 1 do
    begin
      obj := THmrcAccessToken(Items[idx]);
      if (AnsiSameText(obj.Scope, AScope)) then
      begin
        Result := obj;
        Break;
      end;
    end;
  end;
end;





end.

