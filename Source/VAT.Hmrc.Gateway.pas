{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Hmrc.Gateway;

interface

uses
  System.Classes,
  System.Contnrs,
  System.SysUtils,
  HmrcRestSupport,
  HmrcVatClient,
  HmrcVatSupport,
  VAT.App.Settings,
  VAT.Entity.AuthToken,
  VAT.Entity.Profile;

type
  EHmrcGatewayError = class(Exception);

  THmrcGateway = class
  private
    FOwner: TComponent;
    FSettings: TVATAppSettings;
    FProfile: TProfile;
    FOnTokenChange: THmrcTokenEvent;
    FLastCode: Integer;
    FLastError: string;
    function CreateClient: THmrcVATClient;
    procedure Prepare(const Client: THmrcVATClient; const Scope: string; const Token: TAuthToken);
    procedure ApplyScenario(const Client: THmrcVATClient);
    function MissingToken(const Client: THmrcVATClient): Boolean;
    procedure RequireSuccess(const Client: THmrcVATClient);
  public
    constructor Create(AOwner: TComponent; const Settings: TVATAppSettings; const Profile: TProfile);
    function Obligations(const FromDate, ToDate: TDateTime; const Token: TAuthToken): TObjectList;
    function Liabilities(const FromDate, ToDate: TDateTime; const Token: TAuthToken): TObjectList;
    function Payments(const FromDate, ToDate: TDateTime; const Token: TAuthToken): TObjectList;
    function FetchReturn(const PeriodKey: string; const Token: TAuthToken): TVatReturn;
    function Submit(const PeriodKey: string; const Values: TStrings; const Token: TAuthToken;
      out Confirmation: string): Integer;
    function SignIn(const Scope: string): Boolean;
    function NeedsNewToken: Boolean;
    property LastError: string read FLastError;
    property OnTokenChange: THmrcTokenEvent read FOnTokenChange write FOnTokenChange;
  end;

implementation

uses
  System.JSON,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetConsts,
  System.NetEncoding,
  HmrcHeaders,
  VAT.Enumerations,
  VAT.Form.HmrcSignIn;

type
  THmrcUserToken = record
    AccessToken: string;
    RefreshToken: string;
    ExpiresIn: Integer;
  end;

function EncodeQuery(const Value: string): string;
begin
  Result := StringReplace(TNetEncoding.URL.Encode(Value), '+', '%20', [rfReplaceAll]);
end;

function RequestUserToken(const Root, ClientId, ClientSecret, CallbackUrl, AuthCode: string): THmrcUserToken;
var
  Http: THTTPClient;
  Response: IHTTPResponse;
  Body: TStringStream;
  Json: TJSONValue;
  ExpiresValue: TJSONValue;
begin
  Http := THTTPClient.Create;
  Body := TStringStream.Create(
    'grant_type=' + csAuthCode +
    '&code=' + EncodeQuery(AuthCode) +
    '&client_id=' + EncodeQuery(ClientId) +
    '&client_secret=' + EncodeQuery(ClientSecret) +
    '&redirect_uri=' + EncodeQuery(CallbackUrl), TEncoding.UTF8);
  try
    Http.ContentType := 'application/x-www-form-urlencoded';
    Response := Http.Post(Root + '/' + csAuthToken, Body);
    if Response.StatusCode <> 200 then
      raise EHmrcGatewayError.Create('HMRC rejected the sign in (' + Response.StatusCode.ToString + ').' +
        sLineBreak + Response.ContentAsString);
    Json := TJSONObject.ParseJSONValue(Response.ContentAsString);
    if not (Json is TJSONObject) then
    begin
      Json.Free;
      raise EHmrcGatewayError.Create('HMRC did not return an access token.');
    end;
    try
      Result.AccessToken := TJSONObject(Json).GetValue<string>('access_token', '');
      Result.RefreshToken := TJSONObject(Json).GetValue<string>('refresh_token', '');
      Result.ExpiresIn := 14400;
      ExpiresValue := TJSONObject(Json).GetValue('expires_in');
      if ExpiresValue is TJSONNumber then
        Result.ExpiresIn := TJSONNumber(ExpiresValue).AsInt
      else if ExpiresValue <> nil then
        Result.ExpiresIn := StrToIntDef(ExpiresValue.Value, 14400);
      if Result.AccessToken = '' then
        raise EHmrcGatewayError.Create('HMRC did not return an access token.');
    finally
      Json.Free;
    end;
  finally
    Body.Free;
    Http.Free;
  end;
end;

constructor THmrcGateway.Create(AOwner: TComponent; const Settings: TVATAppSettings; const Profile: TProfile);
begin
  inherited Create;
  FOwner := AOwner;
  FSettings := Settings;
  FProfile := Profile;
end;

function THmrcGateway.MissingToken(const Client: THmrcVATClient): Boolean;
begin
  FLastCode := Client.LastCode;
  FLastError := Client.LastError;
  Result := (FLastCode = ERR_NO_ACCESS_TOKEN) or (FLastCode = ERR_TOKEN_EXPIRED);
end;

function THmrcGateway.NeedsNewToken: Boolean;
begin
  Result := (FLastCode = ERR_NO_ACCESS_TOKEN) or (FLastCode = ERR_TOKEN_EXPIRED);
end;

procedure THmrcGateway.RequireSuccess(const Client: THmrcVATClient);
begin
  if MissingToken(Client) then
    Exit;
  if Trim(FLastError) <> '' then
    raise EHmrcGatewayError.Create(FLastError);
  raise EHmrcGatewayError.Create('HMRC returned an error (' + FLastCode.ToString + ').');
end;

procedure THmrcGateway.ApplyScenario(const Client: THmrcVATClient);
begin
  Client.RemoveaHeader('Gov-Test-Scenario');
  if (FSettings.Mode = opmTest) and (FSettings.Scenario.Trim <> '') then
    Client.AddaHeader('Gov-Test-Scenario', FSettings.Scenario.Trim);
end;

procedure THmrcGateway.Prepare(const Client: THmrcVATClient; const Scope: string; const Token: TAuthToken);
var
  AppValues: TAppValues;
begin
  Client.IzTest := FSettings.Mode = opmTest;
  Client.ClientId := FSettings.ClientId;
  Client.ClientSecret := FSettings.ClientSecret;
  Client.ServerToken := FSettings.ServerToken;
  Client.CallbackUrl := FSettings.CallbackUrl;
  Client.CallbackPort := FSettings.CallbackPort;
  Client.SetHmrcID(FProfile.VATNumber.ToString);
  Client.OnTokenChange := FOnTokenChange;
  if Token <> nil then
    Client.AddaToken(Token.UserId, Scope, Token.AccessToken, Token.RefreshToken, Token.TokenExpires, Token.TokenStops);
  AppValues.AppGuid := FSettings.DeviceId;
  AppValues.AppName := 'VAT Submitter';
  AppValues.License := FSettings.LicenceKey;
  AppValues.MFType := '';
  AppValues.MFValue := '';
  AppValues.MFTime := 0;
  AddHeaders(Client, AppValues);
  ApplyScenario(Client);
end;

function THmrcGateway.CreateClient: THmrcVATClient;
begin
  if FSettings.ClientId.Trim = '' then
    raise EHmrcGatewayError.Create('Enter the HMRC client id on the Settings page before calling HMRC.');
  if FProfile.VATNumber <= 0 then
    raise EHmrcGatewayError.Create('Enter the organisation VAT number on the Settings page.');
  Result := THmrcVATClient.Create(FOwner);
end;

function THmrcGateway.Obligations(const FromDate, ToDate: TDateTime; const Token: TAuthToken): TObjectList;
var
  Client: THmrcVATClient;
begin
  Client := CreateClient;
  try
    Prepare(Client, 'read:vat', Token);
    Result := Client.GetObligations(FromDate, ToDate, '');
    if Result = nil then
      RequireSuccess(Client);
  finally
    Client.Free;
  end;
end;

function THmrcGateway.Liabilities(const FromDate, ToDate: TDateTime; const Token: TAuthToken): TObjectList;
var
  Client: THmrcVATClient;
begin
  Client := CreateClient;
  try
    Prepare(Client, 'read:vat', Token);
    Result := Client.GetLiabilities(FromDate, ToDate);
    if Result = nil then
      RequireSuccess(Client);
  finally
    Client.Free;
  end;
end;

function THmrcGateway.Payments(const FromDate, ToDate: TDateTime; const Token: TAuthToken): TObjectList;
var
  Client: THmrcVATClient;
begin
  Client := CreateClient;
  try
    Prepare(Client, 'read:vat', Token);
    Result := Client.GetPayments(FromDate, ToDate);
    if Result = nil then
      RequireSuccess(Client);
  finally
    Client.Free;
  end;
end;

function THmrcGateway.FetchReturn(const PeriodKey: string; const Token: TAuthToken): TVatReturn;
var
  Client: THmrcVATClient;
begin
  Client := CreateClient;
  try
    Prepare(Client, 'read:vat', Token);
    Result := Client.GetReturn(PeriodKey);
    if Result = nil then
      RequireSuccess(Client);
  finally
    Client.Free;
  end;
end;

function THmrcGateway.Submit(const PeriodKey: string; const Values: TStrings; const Token: TAuthToken;
  out Confirmation: string): Integer;
var
  Client: THmrcVATClient;
  List: TStringList;
begin
  Client := CreateClient;
  List := TStringList.Create;
  try
    List.Assign(Values);
    Prepare(Client, 'write:vat', Token);
    Result := Client.SubmitReturn(PeriodKey, List, True, Confirmation);
    if Result <> RESULT_OK then
      RequireSuccess(Client);
  finally
    List.Free;
    Client.Free;
  end;
end;

function THmrcGateway.SignIn(const Scope: string): Boolean;
var
  Root, AuthUrl, AuthCode, Part: string;
  Token: THmrcUserToken;
  Expires, Stops: TDateTime;
begin
  Result := False;
  if Trim(FSettings.ClientId) = '' then
    raise EHmrcGatewayError.Create('Enter the HMRC client id on the Settings page before calling HMRC.');
  if Trim(FSettings.CallbackUrl) = '' then
    raise EHmrcGatewayError.Create('Enter the HMRC callback URL before signing in.');
  Root := GetBaseUrl(FSettings.Mode = opmTest);
  AuthUrl := Root + '/' + csAuthorize +
    '?response_type=code' +
    '&client_id=' + EncodeQuery(FSettings.ClientId) +
    '&scope=' + EncodeQuery(Scope) +
    '&redirect_uri=' + EncodeQuery(FSettings.CallbackUrl);
  if not THmrcSignInForm.Capture(AuthUrl, FSettings.CallbackUrl, FProfile.UserId, FProfile.HMRCPassword, AuthCode) then
    Exit;
  Token := RequestUserToken(Root, FSettings.ClientId, FSettings.ClientSecret, FSettings.CallbackUrl, AuthCode);
  Expires := Date + 547;
  if Token.ExpiresIn <= 0 then
    Stops := Now + (14400 / 86400)
  else
    Stops := Now + (Token.ExpiresIn / 86400);
  if Assigned(FOnTokenChange) then
    for Part in Scope.Split([' '], TStringSplitOptions.ExcludeEmpty) do
      FOnTokenChange(nil, FProfile.VATNumber.ToString, Part, Token.AccessToken, Token.RefreshToken, Expires, Stops);
  Result := True;
end;

end.
