{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Frame.Return;

interface

uses
  System.Classes,
  System.SysUtils,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Forms,
  Vcl.StdCtrls,
  VAT.Frame.Obligations,
  VAT.Return.Model;

type
  TReturnFrame = class(TFrame)
    PeriodLabel: TLabel;
    PeriodEdit: TEdit;
    Box1Label: TLabel;
    Box2Label: TLabel;
    Box3Label: TLabel;
    Box4Label: TLabel;
    Box5Label: TLabel;
    Box6Label: TLabel;
    Box7Label: TLabel;
    Box8Label: TLabel;
    Box9Label: TLabel;
    Box1Edit: TEdit;
    Box2Edit: TEdit;
    Box3Edit: TEdit;
    Box4Edit: TEdit;
    Box5Edit: TEdit;
    Box6Edit: TEdit;
    Box7Edit: TEdit;
    Box8Edit: TEdit;
    Box9Edit: TEdit;
    PaymentLabel: TLabel;
    ProcessedLabel: TLabel;
    SaveButton: TButton;
    ImportButton: TButton;
    SubmitButton: TButton;
    FetchButton: TButton;
    ImportDialog: TOpenDialog;
    procedure BoxEditChange(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure ImportButtonClick(Sender: TObject);
    procedure SubmitButtonClick(Sender: TObject);
    procedure FetchButtonClick(Sender: TObject);
  private
    FOnScenarioChosen: TScenarioChosenEvent;
    FReadOnly: Boolean;
    function ReadBoxes: TVATReturnBoxes;
    procedure ShowBoxes(const Boxes: TVATReturnBoxes);
    procedure ApplyReadOnly(ReadOnly: Boolean);
  public
    procedure LoadPeriod(const PeriodKey: string; Processed: Boolean);
    property OnScenarioChosen: TScenarioChosenEvent read FOnScenarioChosen write FOnScenarioChosen;
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils,
  HmrcVatSupport,
  HmrcRestSupport,
  VAT.App.Settings,
  VAT.DataModule,
  VAT.Enumerations,
  VAT.Entity.AuthToken,
  VAT.Entity.VATReturn,
  VAT.Form.Declaration,
  VAT.Form.Scenario,
  VAT.Hmrc.Gateway;

function TReturnFrame.ReadBoxes: TVATReturnBoxes;
begin
  Result.PeriodKey := Trim(PeriodEdit.Text);
  Result.VatDueSales := StrToCurrDef(Box1Edit.Text, 0);
  Result.VatDueAcquisitions := StrToCurrDef(Box2Edit.Text, 0);
  Result.VatReclaimed := StrToCurrDef(Box4Edit.Text, 0);
  Result.TotalSalesExVat := Trunc(StrToFloatDef(Box6Edit.Text, 0));
  Result.TotalPurchasesExVat := Trunc(StrToFloatDef(Box7Edit.Text, 0));
  Result.TotalGoodsSuppliedExVat := Trunc(StrToFloatDef(Box8Edit.Text, 0));
  Result.TotalAcquisitionsExVat := Trunc(StrToFloatDef(Box9Edit.Text, 0));
  Result.Recalculate;
  Box3Edit.Text := CurrToStr(Result.TotalVatDue);
  Box5Edit.Text := CurrToStr(Result.NetVatDue);
  PaymentLabel.Caption := Result.PaymentText;
end;

procedure TReturnFrame.ShowBoxes(const Boxes: TVATReturnBoxes);
begin
  Box1Edit.Text := CurrToStr(Boxes.VatDueSales);
  Box2Edit.Text := CurrToStr(Boxes.VatDueAcquisitions);
  Box4Edit.Text := CurrToStr(Boxes.VatReclaimed);
  Box6Edit.Text := Boxes.TotalSalesExVat.ToString;
  Box7Edit.Text := Boxes.TotalPurchasesExVat.ToString;
  Box8Edit.Text := Boxes.TotalGoodsSuppliedExVat.ToString;
  Box9Edit.Text := Boxes.TotalAcquisitionsExVat.ToString;
  ReadBoxes;
end;

procedure TReturnFrame.BoxEditChange(Sender: TObject);
begin
  if (Sender = Box3Edit) or (Sender = Box5Edit) then
    Exit;
  ReadBoxes;
end;

procedure TReturnFrame.ApplyReadOnly(ReadOnly: Boolean);
begin
  FReadOnly := ReadOnly;
  PeriodEdit.ReadOnly := True;
  Box1Edit.ReadOnly := ReadOnly;
  Box2Edit.ReadOnly := ReadOnly;
  Box3Edit.ReadOnly := True;
  Box4Edit.ReadOnly := ReadOnly;
  Box5Edit.ReadOnly := True;
  Box6Edit.ReadOnly := ReadOnly;
  Box7Edit.ReadOnly := ReadOnly;
  Box8Edit.ReadOnly := ReadOnly;
  Box9Edit.ReadOnly := ReadOnly;
  SaveButton.Enabled := not ReadOnly;
  ImportButton.Enabled := not ReadOnly;
  SubmitButton.Enabled := not ReadOnly;
  ProcessedLabel.Visible := ReadOnly;
end;

procedure TReturnFrame.LoadPeriod(const PeriodKey: string; Processed: Boolean);
var
  Item: VAT.Entity.VATReturn.TVATReturn;
begin
  Item := VatDataModule.Store.LoadReturn(VatDataModule.Profile.Id, PeriodKey);
  ApplyReadOnly(Processed or (Item.Submitted > 0));
  PeriodEdit.Text := Item.PeriodKey;
  Box1Edit.Text := CurrToStr(Item.VatDueSales);
  Box2Edit.Text := CurrToStr(Item.VatDueECAcquisitions);
  Box4Edit.Text := CurrToStr(Item.VatReclaimed);
  Box6Edit.Text := Trunc(Item.TotalSalesValue).ToString;
  Box7Edit.Text := Trunc(Item.TotalPurchaseValue).ToString;
  Box8Edit.Text := Trunc(Item.TotalECSupplied).ToString;
  Box9Edit.Text := Trunc(Item.TotalECAquired).ToString;
  ReadBoxes;
end;

procedure TReturnFrame.SaveButtonClick(Sender: TObject);
var
  Boxes: TVATReturnBoxes;
  Messages: TArray<string>;
begin
  if FReadOnly then
    Exit;
  if not VatDataModule.CanWrite then
  begin
    ShowMessage('You do not have permission to change a return.');
    Exit;
  end;
  Boxes := ReadBoxes;
  Messages := Boxes.ValidationMessages;
  if Length(Messages) > 0 then
  begin
    ShowMessage(string.Join(sLineBreak, Messages));
    Exit;
  end;
  VatDataModule.Store.SaveBoxes(VatDataModule.Profile.Id, VatDataModule.CurrentUser.Id, Boxes,
    False, '', '', '', '', 0, 0);
  ShowMessage('Return saved.');
end;

procedure TReturnFrame.ImportButtonClick(Sender: TObject);
var
  Boxes: TVATReturnBoxes;
begin
  if FReadOnly then
    Exit;
  if not ImportDialog.Execute then
    Exit;
  Boxes := LoadReturnFromCsv(TFile.ReadAllText(ImportDialog.FileName));
  Boxes.PeriodKey := Trim(PeriodEdit.Text);
  ShowBoxes(Boxes);
end;

procedure TReturnFrame.SubmitButtonClick(Sender: TObject);
var
  Boxes: TVATReturnBoxes;
  Declaration: TDeclarationForm;
  Values: TStringList;
  Gateway: THmrcGateway;
  Confirmation: string;
  Token: TAuthToken;
  Messages: TArray<string>;
  Settings: TVATAppSettings;
  Scenario: string;
  FromDate, ToDate: TDateTime;
  Attempt: Integer;
  Submitted: Boolean;
begin
  if FReadOnly then
    Exit;
  if not VatDataModule.CanSubmit then
  begin
    ShowMessage('You do not have permission to submit a return.');
    Exit;
  end;
  Boxes := ReadBoxes;
  Messages := Boxes.ValidationMessages;
  if Length(Messages) > 0 then
  begin
    ShowMessage(string.Join(sLineBreak, Messages));
    Exit;
  end;
  {$IFDEF DEBUG}
  if not ChooseGovScenario(sgVATReturn, Scenario, FromDate, ToDate) then
    Exit;
  Settings := VatDataModule.Settings;
  Settings.Mode := opmTest;
  Settings.Scenario := Scenario;
  VatDataModule.ReplaceSettings(Settings);
  if Assigned(FOnScenarioChosen) then
    FOnScenarioChosen(Scenario);
  {$ENDIF}
  Declaration := TDeclarationForm.Create(nil);
  try
    Declaration.ShowReturn(Boxes);
    if Declaration.ShowModal <> mrOk then
      Exit;
  finally
    Declaration.Free;
  end;
  Values := TStringList.Create;
  Gateway := VatDataModule.Gateway;
  try
    Boxes.FillSubmissionValues(Values);
    Submitted := False;
    Confirmation := '';
    for Attempt := 1 to 2 do
    begin
      Token := VatDataModule.Store.LoadToken(VatDataModule.Profile.Id, 'write:vat');
      Submitted := Gateway.Submit(Boxes.PeriodKey, Values, Token, Confirmation) = RESULT_OK;
      if Submitted or (not Gateway.NeedsNewToken) or (Attempt = 2) then
        Break;
      if not VatDataModule.RenewHmrcAccess('write:vat') then
        Exit;
    end;
    if not Submitted then
    begin
      if Trim(Gateway.LastError) <> '' then
        ShowMessage(Gateway.LastError);
      Exit;
    end;
    VatDataModule.Store.SaveBoxes(VatDataModule.Profile.Id, VatDataModule.CurrentUser.Id, Boxes,
      True, Confirmation, '', '', '', 0, Now);
    ShowMessage('Submitted.' + sLineBreak + Confirmation);
  finally
    Gateway.Free;
    Values.Free;
  end;
end;

procedure TReturnFrame.FetchButtonClick(Sender: TObject);
var
  Gateway: THmrcGateway;
  Item: HmrcVatSupport.TVatReturn;
  Token: TAuthToken;
  Boxes: TVATReturnBoxes;
  Attempt: Integer;
begin
  Gateway := VatDataModule.Gateway;
  try
    Item := nil;
    for Attempt := 1 to 2 do
    begin
      Token := VatDataModule.Store.LoadToken(VatDataModule.Profile.Id, 'read:vat');
      Item := Gateway.FetchReturn(Trim(PeriodEdit.Text), Token);
      if (Item <> nil) or (not Gateway.NeedsNewToken) or (Attempt = 2) then
        Break;
      if not VatDataModule.RenewHmrcAccess('read:vat') then
        Exit;
    end;
    if Item = nil then
    begin
      if Trim(Gateway.LastError) <> '' then
        ShowMessage(Gateway.LastError);
      Exit;
    end;
    try
      Boxes.VatDueSales := Item.DueOnSales;
      Boxes.VatDueAcquisitions := Item.DueOnAcquisitions;
      Boxes.VatReclaimed := Item.VatReclaimedCP;
      Boxes.TotalSalesExVat := Item.SalesExVAT;
      Boxes.TotalPurchasesExVat := Item.PurchasesExVAT;
      Boxes.TotalGoodsSuppliedExVat := Item.GoodsExVAT;
      Boxes.TotalAcquisitionsExVat := Item.AcquisitionsExVAT;
      Boxes.PeriodKey := Trim(PeriodEdit.Text);
      Boxes.Recalculate;
      ShowBoxes(Boxes);
    finally
      Item.Free;
    end;
  finally
    Gateway.Free;
  end;
end;

end.
