{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Form.Main;

interface

uses
  System.Classes,
  Vcl.ComCtrls,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.StdCtrls,
  VAT.Frame.Liabilities,
  VAT.Frame.Obligations,
  VAT.Frame.Return,
  VAT.Frame.Settings,
  VAT.Frame.Users;

type
  TMainForm = class(TForm)
    StatusBar: TStatusBar;
    NavPanel: TPanel;
    ObligationsButton: TButton;
    ReturnButton: TButton;
    LiabilitiesButton: TButton;
    SettingsButton: TButton;
    UsersButton: TButton;
    Pages: TPageControl;
    TabObligations: TTabSheet;
    TabReturn: TTabSheet;
    TabLiabilities: TTabSheet;
    TabSettings: TTabSheet;
    TabUsers: TTabSheet;
    ObligationsPageFrame: TObligationsFrame;
    ReturnPageFrame: TReturnFrame;
    LiabilitiesPageFrame: TLiabilitiesFrame;
    SettingsPageFrame: TSettingsFrame;
    UsersPageFrame: TUsersFrame;
    procedure FormCreate(Sender: TObject);
    procedure NavigateClick(Sender: TObject);
    procedure OpenSession;
  private
    procedure PeriodSelected(const PeriodKey: string; Processed: Boolean);
    procedure ScenarioChosen(const Scenario: string);
    procedure SettingsChanged(Sender: TObject);
    procedure RefreshStatus;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  Vcl.Dialogs,
  VAT.DataModule,
  VAT.Enumerations;

procedure TMainForm.FormCreate(Sender: TObject);
var
  Index: Integer;
begin
  for Index := 0 to Pages.PageCount - 1 do
    Pages.Pages[Index].TabVisible := False;
  ObligationsPageFrame.OnPeriodSelected := PeriodSelected;
  ObligationsPageFrame.OnScenarioChosen := ScenarioChosen;
  ReturnPageFrame.OnScenarioChosen := ScenarioChosen;
  LiabilitiesPageFrame.OnScenarioChosen := ScenarioChosen;
  SettingsPageFrame.OnChanged := SettingsChanged;
end;

procedure TMainForm.OpenSession;
begin
  UsersButton.Visible := VatDataModule.IsAdmin;
  Pages.ActivePageIndex := 0;
  ObligationsPageFrame.LoadRows;
  SettingsPageFrame.Open;
  UsersPageFrame.LoadRows;
  RefreshStatus;
  Visible := True;
  BringToFront;
end;

procedure TMainForm.NavigateClick(Sender: TObject);
var
  PeriodKey: string;
  Processed: Boolean;
begin
  if (TButton(Sender).Tag = 4) and not VatDataModule.IsAdmin then
  begin
    ShowMessage('Only an administrator can manage users.');
    Exit;
  end;
  if TButton(Sender).Tag = 1 then
  begin
    if not ObligationsPageFrame.SelectedPeriod(PeriodKey, Processed) then
    begin
      ShowMessage('Select an obligation before opening the VAT return.');
      Exit;
    end;
    ReturnPageFrame.LoadPeriod(PeriodKey, Processed);
  end;
  Pages.ActivePageIndex := TButton(Sender).Tag;
end;

procedure TMainForm.PeriodSelected(const PeriodKey: string; Processed: Boolean);
begin
  ReturnPageFrame.LoadPeriod(PeriodKey, Processed);
  Pages.ActivePageIndex := 1;
end;

procedure TMainForm.ScenarioChosen(const Scenario: string);
begin
  SettingsPageFrame.ShowScenario(Scenario);
end;

procedure TMainForm.SettingsChanged(Sender: TObject);
begin
  RefreshStatus;
end;

procedure TMainForm.RefreshStatus;
begin
  Caption := 'VAT Submitter - ' + VatDataModule.CurrentUser.FullName + ' - ' +
    OpModeText(VatDataModule.Settings.Mode) + ' - VRN ' + VatDataModule.Profile.VATNumber.ToString;
  StatusBar.SimpleText := Caption;
end;

end.
