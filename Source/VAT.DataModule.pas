{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.DataModule;

interface

uses
  System.Classes,
  System.SysUtils,
  HmrcRestSupport,
  VAT.App.Settings,
  VAT.Data.Lock,
  VAT.Entity.Profile,
  VAT.Entity.User,
  VAT.Hmrc.Gateway,
  VAT.Store;

type
  TVatDataModule = class(TDataModule)
  private
    FSettings: TVATAppSettings;
    FStore: TVATStore;
    FLockKey: string;
    FCurrentUser: TVATUser;
    FProfile: TProfile;
    procedure EnsureFolders;
    function RunSetup: Boolean;
    function RunLogin: Boolean;
    procedure TokenChanged(Sender: TObject; const Uid, Scope, AccessToken, RefreshToken: string;
      const Expires, TimeOut: TDateTime);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function PrepareSession: Boolean;
    function Gateway: THmrcGateway;
    function CanWrite: Boolean;
    function CanSubmit: Boolean;
    function IsAdmin: Boolean;
    procedure ReplaceSettings(const Value: TVATAppSettings);
    procedure ReloadProfile;
    function CreateSandboxCompany(out Detail: string): Boolean;
    function RenewHmrcAccess(const Scope: string): Boolean;
    property Settings: TVATAppSettings read FSettings;
    property Store: TVATStore read FStore;
    property CurrentUser: TVATUser read FCurrentUser;
    property Profile: TProfile read FProfile;
  end;

var
  VatDataModule: TVatDataModule;

implementation

uses
  System.UITypes,
  System.JSON,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetConsts,
  System.NetEncoding,
  Vcl.Dialogs,
  Vcl.Forms,
  VAT.Entity.AuthToken,
  VAT.Enumerations,
  VAT.Form.Login,
  VAT.Form.Setup,
  VAT.Hmrc.TestUser,
  VAT.Return.Model;

constructor TVatDataModule.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  FLockKey := StringReplace(TGUID.NewGuid.ToString, '-', '', [rfReplaceAll]).Trim(['{', '}']);
  FSettings.Load;
end;

destructor TVatDataModule.Destroy;
begin
  if FStore <> nil then
    TVATDataLock.ReleaseIfMine(FSettings.LockFile, FLockKey);
  FStore.Free;
  inherited;
end;

procedure TVatDataModule.EnsureFolders;
begin
  if not System.SysUtils.DirectoryExists(FSettings.DataPath) then
    ForceDirectories(FSettings.DataPath);
end;

function TVatDataModule.RunSetup: Boolean;
var
  Setup: TSetupForm;
  {$IFDEF DEBUG}
  Detail: string;
  {$ENDIF}
begin
  Result := False;
  Setup := TSetupForm.Create(nil);
  try
    Setup.DataPathEdit.Text := FSettings.DataPath;
    if Setup.ShowModal <> mrOk then
      Exit;
    if Trim(Setup.PasswordEdit.Text) = '' then
    begin
      ShowMessage('Enter a password for the administrator.');
      Exit;
    end;
    {$IFNDEF DEBUG}
    if not IsValidUKVATNumber(Setup.VrnEdit.Text) then
    begin
      ShowMessage('Enter a valid 9 digit UK VAT number.');
      Exit;
    end;
    {$ENDIF}
    FSettings.DataPath := Trim(Setup.DataPathEdit.Text);
    FSettings.Save;
    EnsureFolders;
    FreeAndNil(FStore);
    FStore := TVATStore.Create(FSettings.DatabaseFile);
    FStore.UpdateSchema;
    FStore.AddUser(Setup.FirstNameEdit.Text, Setup.LastNameEdit.Text, Setup.UserNameEdit.Text,
      Setup.PasswordEdit.Text, usSubmit, ulAdministrator, 0);
    FCurrentUser := FStore.Login(Setup.UserNameEdit.Text, Setup.PasswordEdit.Text);
    FProfile := FStore.LoadProfile;
    {$IFDEF DEBUG}
    FProfile.Name := 'Test Profile';
    FStore.SaveProfile(FProfile);
    if not CreateSandboxCompany(Detail) then
      ShowMessage(Detail)
    else
      ShowMessage(Detail);
    {$ELSE}
    FProfile.OrganisationName := Trim(Setup.OrganisationEdit.Text);
    FProfile.VATNumber := StrToInt64(NormaliseVATNumber(Setup.VrnEdit.Text));
    FProfile.Name := Trim(Setup.OrganisationEdit.Text);
    FStore.SaveProfile(FProfile);
    {$ENDIF}
    Result := True;
  finally
    Setup.Free;
  end;
end;

function TVatDataModule.RunLogin: Boolean;
var
  Login: TLoginForm;
  User: TVATUser;
begin
  Result := False;
  Login := TLoginForm.Create(nil);
  try
    while Login.ShowModal = mrOk do
    begin
      User := FStore.Login(Login.UserNameEdit.Text, Login.PasswordEdit.Text);
      if User = nil then
      begin
        ShowMessage('That user name or password is not valid.');
        Continue;
      end;
      FCurrentUser := User;
      TVATDataLock.UpdateOwner(FSettings.LockFile, User.Id.ToString, User.FullName);
      Exit(True);
    end;
  finally
    Login.Free;
  end;
end;

function TVatDataModule.PrepareSession: Boolean;
begin
  Result := False;
  EnsureFolders;
  if not System.SysUtils.FileExists(FSettings.DatabaseFile) then
  begin
    if not RunSetup then
      Exit;
  end
  else
  begin
    FStore := TVATStore.Create(FSettings.DatabaseFile);
    FStore.UpdateSchema;
    if FStore.UserCount = 0 then
    begin
      FreeAndNil(FStore);
      if not RunSetup then
        Exit;
    end;
  end;
  case TVATDataLock.Status(FSettings.LockFile, FLockKey) of
    lsLockedByOther:
      begin
        if not TVATDataLock.IsStale(FSettings.LockFile) then
        begin
          if MessageDlg(TVATDataLock.Describe(FSettings.LockFile, FLockKey) + sLineBreak + sLineBreak +
            'Clear the lock and continue?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
            Exit;
        end;
        TVATDataLock.Clear(FSettings.LockFile);
        TVATDataLock.Acquire(FSettings.LockFile, FLockKey, 'logging in');
      end;
    lsNotLocked:
      TVATDataLock.Acquire(FSettings.LockFile, FLockKey, 'logging in');
  end;
  FProfile := FStore.LoadProfile;
  if FCurrentUser <> nil then
  begin
    TVATDataLock.UpdateOwner(FSettings.LockFile, FCurrentUser.Id.ToString, FCurrentUser.FullName);
    Exit(True);
  end;
  Result := RunLogin;
end;

function RequestSandboxToken(const ClientId, ClientSecret: string): string;
var
  Http: THTTPClient;
  Response: IHTTPResponse;
  Body: TStringStream;
  Json: TJSONValue;
begin
  Http := THTTPClient.Create;
  Body := TStringStream.Create(
    'grant_type=client_credentials' +
    '&client_id=' + TNetEncoding.URL.Encode(ClientId) +
    '&client_secret=' + TNetEncoding.URL.Encode(ClientSecret), TEncoding.UTF8);
  try
    Http.ContentType := 'application/x-www-form-urlencoded';
    Response := Http.Post(HmrcTestUrl + '/' + csAuthToken, Body);
    if Response.StatusCode <> 200 then
      raise Exception.Create('HMRC rejected the sandbox token request (' +
        Response.StatusCode.ToString + ').' + sLineBreak + Response.ContentAsString);
    Json := TJSONObject.ParseJSONValue(Response.ContentAsString);
    if not (Json is TJSONObject) then
    begin
      Json.Free;
      raise Exception.Create('HMRC did not return a sandbox access token.');
    end;
    try
      Result := TJSONObject(Json).GetValue<string>('access_token', '');
      if Result = '' then
        raise Exception.Create('HMRC did not return a sandbox access token.');
    finally
      Json.Free;
    end;
  finally
    Body.Free;
    Http.Free;
  end;
end;

function RequestSandboxCompany(const AccessToken: string): string;
var
  Http: THTTPClient;
  Response: IHTTPResponse;
  Body: TStringStream;
begin
  Http := THTTPClient.Create;
  Body := TStringStream.Create('{"serviceNames":["mtd-vat"]}', TEncoding.UTF8);
  try
    Http.ContentType := 'application/json';
    Http.Accept := 'application/vnd.hmrc.1.0+json';
    Http.CustomHeaders['Authorization'] := 'Bearer ' + AccessToken;
    Response := Http.Post(HmrcTestUrl + '/create-test-user/organisations', Body);
    if (Response.StatusCode <> 200) and (Response.StatusCode <> 201) then
      raise Exception.Create('HMRC rejected the test company request (' +
        Response.StatusCode.ToString + ').' + sLineBreak + Response.ContentAsString);
    Result := Response.ContentAsString;
  finally
    Body.Free;
    Http.Free;
  end;
end;

function TVatDataModule.CreateSandboxCompany(out Detail: string): Boolean;
var
  Company: THmrcTestCompany;
begin
  Result := False;
  Detail := '';
  if FSettings.ClientId.Trim = '' then
  begin
    Detail := 'The HMRC sandbox client id is missing.';
    Exit;
  end;
  if FSettings.ClientSecret.Trim = '' then
  begin
    Detail := 'The HMRC sandbox client secret is missing.';
    Exit;
  end;
  try
    Company := ParseHmrcTestCompany(RequestSandboxCompany(RequestSandboxToken(
      FSettings.ClientId, FSettings.ClientSecret)));
    ApplyHmrcTestCompany(FProfile, Company);
    FStore.SaveProfile(FProfile);
    Detail := 'Test company created.' + sLineBreak +
      'Company: ' + Company.Organisation + sLineBreak +
      'VAT number: ' + Company.VATNumber.ToString + sLineBreak +
      'HMRC user id: ' + Company.UserId + sLineBreak +
      'HMRC password: ' + Company.Password;
    Result := True;
  except
    on E: Exception do
      Detail := 'Unable to create a test company.' + sLineBreak + E.Message;
  end;
end;

function TVatDataModule.RenewHmrcAccess(const Scope: string): Boolean;
var
  Gateway: THmrcGateway;
  Token: TAuthToken;
begin
  Result := False;
  MessageDlg('Your validation token has either not been set or has expired. You will now be taken through the process.',
    mtInformation, [mbOK], 0);
  Gateway := Self.Gateway;
  try
    try
      Gateway.SignIn(Scope);
    except
      on E: Exception do
      begin
        ShowMessage(E.Message);
        Exit;
      end;
    end;
  finally
    Gateway.Free;
  end;
  Token := FStore.LoadToken(FProfile.Id, Scope);
  Result := (Token <> nil) and (Trim(Token.AccessToken) <> '') and (Token.TokenStops > Now);
  if not Result then
    ShowMessage('HMRC sign in was not completed.');
end;

procedure TVatDataModule.ReplaceSettings(const Value: TVATAppSettings);
begin
  FSettings := Value;
end;

procedure TVatDataModule.ReloadProfile;
begin
  FProfile := FStore.LoadProfile;
end;

procedure TVatDataModule.TokenChanged(Sender: TObject; const Uid, Scope, AccessToken, RefreshToken: string;
  const Expires, TimeOut: TDateTime);
begin
  if FStore = nil then
    Exit;
  FStore.SaveToken(FProfile.Id, Uid, Scope, AccessToken, RefreshToken, Expires, TimeOut);
end;

function TVatDataModule.Gateway: THmrcGateway;
begin
  Result := THmrcGateway.Create(Self, FSettings, FProfile);
  Result.OnTokenChange := TokenChanged;
end;

function TVatDataModule.CanWrite: Boolean;
begin
  Result := (FCurrentUser <> nil) and (FCurrentUser.Status >= usWrite);
end;

function TVatDataModule.CanSubmit: Boolean;
begin
  Result := (FCurrentUser <> nil) and (FCurrentUser.Status >= usSubmit);
end;

function TVatDataModule.IsAdmin: Boolean;
begin
  Result := (FCurrentUser <> nil) and (FCurrentUser.Level = ulAdministrator);
end;

end.
