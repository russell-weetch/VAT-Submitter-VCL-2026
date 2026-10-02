{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Frame.Settings;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls;

type
  TSettingsFrame = class(TFrame)
    OrganisationLabel: TLabel;
    VrnLabel: TLabel;
    ClientIdLabel: TLabel;
    ClientSecretLabel: TLabel;
    ModeLabel: TLabel;
    ScenarioLabel: TLabel;
    HmrcUserLabel: TLabel;
    HmrcPasswordLabel: TLabel;
    OrganisationEdit: TEdit;
    VrnEdit: TEdit;
    ClientIdEdit: TEdit;
    ClientSecretEdit: TEdit;
    ModeCombo: TComboBox;
    ScenarioEdit: TEdit;
    HmrcUserEdit: TEdit;
    HmrcPasswordEdit: TEdit;
    SaveButton: TButton;
    SignInButton: TButton;
    CreateCompanyButton: TButton;
    procedure SaveButtonClick(Sender: TObject);
    procedure SignInButtonClick(Sender: TObject);
    procedure CreateCompanyButtonClick(Sender: TObject);
  private
    FOnChanged: TNotifyEvent;
  protected
    procedure Loaded; override;
  public
    procedure Open;
    procedure ShowScenario(const Value: string);
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  Vcl.Dialogs,
  VAT.App.Settings,
  VAT.DataModule,
  VAT.Enumerations,
  VAT.Hmrc.Gateway,
  VAT.Return.Model;

procedure TSettingsFrame.Loaded;
begin
  inherited;
  {$IFDEF DEBUG}
  ModeCombo.Enabled := False;
  {$ELSE}
  CreateCompanyButton.Visible := False;
  {$ENDIF}
end;

procedure TSettingsFrame.ShowScenario(const Value: string);
begin
  ScenarioEdit.Text := Value;
end;

procedure TSettingsFrame.Open;
begin
  OrganisationEdit.Text := VatDataModule.Profile.OrganisationName;
  if VatDataModule.Profile.VATNumber > 0 then
    VrnEdit.Text := VatDataModule.Profile.VATNumber.ToString
  else
    VrnEdit.Text := '';
  HmrcUserEdit.Text := VatDataModule.Profile.UserId;
  HmrcPasswordEdit.Text := VatDataModule.Profile.HMRCPassword;
  ClientIdEdit.Text := VatDataModule.Settings.ClientId;
  ClientSecretEdit.Text := VatDataModule.Settings.ClientSecret;
  {$IFDEF DEBUG}
  if ClientIdEdit.Text = '' then
    ClientIdEdit.Text := DebugClientId;
  if ClientSecretEdit.Text = '' then
    ClientSecretEdit.Text := DebugClientSecret;
  {$ENDIF}
  ScenarioEdit.Text := VatDataModule.Settings.Scenario;
  if VatDataModule.Settings.Mode = opmLive then
    ModeCombo.ItemIndex := 1
  else
    ModeCombo.ItemIndex := 0;
end;

procedure TSettingsFrame.SaveButtonClick(Sender: TObject);
var
  Settings: TVATAppSettings;
begin
  if not IsValidUKVATNumber(VrnEdit.Text) then
  begin
    ShowMessage('Enter a valid 9 digit UK VAT number.');
    Exit;
  end;
  VatDataModule.Profile.OrganisationName := Trim(OrganisationEdit.Text);
  VatDataModule.Profile.Name := Trim(OrganisationEdit.Text);
  VatDataModule.Profile.VATNumber := StrToInt64(NormaliseVATNumber(VrnEdit.Text));
  VatDataModule.Store.SaveProfile(VatDataModule.Profile);
  Settings := VatDataModule.Settings;
  Settings.ClientId := Trim(ClientIdEdit.Text);
  Settings.ClientSecret := Trim(ClientSecretEdit.Text);
  Settings.Scenario := Trim(ScenarioEdit.Text);
  {$IFDEF DEBUG}
  Settings.Mode := opmTest;
  {$ELSE}
  if ModeCombo.ItemIndex = 1 then
    Settings.Mode := opmLive
  else
    Settings.Mode := opmTest;
  {$ENDIF}
  Settings.Save;
  VatDataModule.ReplaceSettings(Settings);
  ShowMessage('Settings saved.');
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

procedure TSettingsFrame.CreateCompanyButtonClick(Sender: TObject);
var
  Detail: string;
begin
  if VatDataModule.CreateSandboxCompany(Detail) then
  begin
    Open;
    if Assigned(FOnChanged) then
      FOnChanged(Self);
  end;
  ShowMessage(Detail);
end;

procedure TSettingsFrame.SignInButtonClick(Sender: TObject);
var
  Gateway: THmrcGateway;
begin
  Gateway := VatDataModule.Gateway;
  try
    if Gateway.SignIn('read:vat write:vat') then
      ShowMessage('HMRC accepted the sign in. The access token has been stored.');
  finally
    Gateway.Free;
  end;
end;

end.
