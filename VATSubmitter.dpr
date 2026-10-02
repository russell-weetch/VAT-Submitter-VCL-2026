{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
program VATSubmitter;

uses
  Vcl.Forms,
  MidasLib,
  VAT.DataModule in 'Source\VAT.DataModule.pas' {VatDataModule: TDataModule},
  VAT.Frame.Obligations in 'Source\VAT.Frame.Obligations.pas' {ObligationsFrame: TFrame},
  VAT.Frame.Return in 'Source\VAT.Frame.Return.pas' {ReturnFrame: TFrame},
  VAT.Frame.Liabilities in 'Source\VAT.Frame.Liabilities.pas' {LiabilitiesFrame: TFrame},
  VAT.Frame.Settings in 'Source\VAT.Frame.Settings.pas' {SettingsFrame: TFrame},
  VAT.Frame.Users in 'Source\VAT.Frame.Users.pas' {UsersFrame: TFrame},
  VAT.Form.Main in 'Source\VAT.Form.Main.pas' {MainForm},
  VAT.Form.Login in 'Source\VAT.Form.Login.pas' {LoginForm},
  VAT.Form.Setup in 'Source\VAT.Form.Setup.pas' {SetupForm},
  VAT.Form.Declaration in 'Source\VAT.Form.Declaration.pas' {DeclarationForm},
  VAT.Form.HmrcUser in 'Source\VAT.Form.HmrcUser.pas' {HmrcUserForm},
  VAT.Form.HmrcSignIn in 'Source\VAT.Form.HmrcSignIn.pas' {HmrcSignInForm},
  VAT.Form.Scenario in 'Source\VAT.Form.Scenario.pas' {ScenarioForm},
  VAT.App.Settings in 'Source\VAT.App.Settings.pas',
  VAT.Data.Lock in 'Source\VAT.Data.Lock.pas',
  VAT.Enumerations in 'Source\VAT.Enumerations.pas',
  VAT.Entity.AuthToken in 'Source\VAT.Entity.AuthToken.pas',
  VAT.Entity.Obligation in 'Source\VAT.Entity.Obligation.pas',
  VAT.Entity.Profile in 'Source\VAT.Entity.Profile.pas',
  VAT.Entity.SysData in 'Source\VAT.Entity.SysData.pas',
  VAT.Entity.User in 'Source\VAT.Entity.User.pas',
  VAT.Entity.VATReturn in 'Source\VAT.Entity.VATReturn.pas',
  VAT.Hmrc.Gateway in 'Source\VAT.Hmrc.Gateway.pas',
  VAT.Hmrc.TestUser in 'Source\VAT.Hmrc.TestUser.pas',
  VAT.Return.Model in 'Source\VAT.Return.Model.pas',
  VAT.Store in 'Source\VAT.Store.pas',
  VAT.Users.Password in 'Source\VAT.Users.Password.pas',
  HmrcHeaders in 'HMRC-MTD-VAT\CmnUnits\HmrcHeaders.pas',
  HmrcRestClient in 'HMRC-MTD-VAT\CmnUnits\HmrcRestClient.pas',
  HmrcRestSupport in 'HMRC-MTD-VAT\CmnUnits\HmrcRestSupport.pas',
  HmrcTestClient in 'HMRC-MTD-VAT\CmnUnits\HmrcTestClient.pas',
  HmrcVatClient in 'HMRC-MTD-VAT\CmnUnits\HmrcVatClient.pas',
  HmrcVatSupport in 'HMRC-MTD-VAT\CmnUnits\HmrcVatSupport.pas',
  Systematic.AppVersion in 'HMRC-MTD-VAT\CmnUnits\Systematic.AppVersion.pas',
  Systematic.MacAddress in 'HMRC-MTD-VAT\CmnUnits\Systematic.MacAddress.pas',
  VAT.Headers.Utils in 'HMRC-MTD-VAT\CmnUnits\VAT.Headers.Utils.pas';

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.ShowMainForm := False;
  Application.CreateForm(TVatDataModule, VatDataModule);
  Application.CreateForm(TMainForm, MainForm);
  if not VatDataModule.PrepareSession then
  begin
    Application.Terminate;
    Exit;
  end;
  MainForm.OpenSession;
  Application.Run;
end.
