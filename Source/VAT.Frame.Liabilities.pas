{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Frame.Liabilities;

interface

uses
  System.Classes,
  System.Contnrs,
  System.SysUtils,
  Vcl.ComCtrls,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.StdCtrls,
  VAT.Form.Scenario,
  VAT.Frame.Obligations;

type
  TLiabilitiesFrame = class(TFrame)
    HeaderPanel: TPanel;
    FromLabel: TLabel;
    ToLabel: TLabel;
    FromPicker: TDateTimePicker;
    ToPicker: TDateTimePicker;
    LiabilitiesButton: TButton;
    PaymentsButton: TButton;
    ResultMemo: TMemo;
    procedure LiabilitiesButtonClick(Sender: TObject);
    procedure PaymentsButtonClick(Sender: TObject);
  private
    FOnScenarioChosen: TScenarioChosenEvent;
    procedure SetRange(const FromDate, ToDate: TDateTime);
    function ChooseDates(Group: THmrcScenarioGroup): Boolean;
    procedure DescribeList(const Title: string; const Items: TObjectList);
  protected
    procedure Loaded; override;
  public
    property OnScenarioChosen: TScenarioChosenEvent read FOnScenarioChosen write FOnScenarioChosen;
  end;

implementation

{$R *.dfm}

uses
  System.DateUtils,
  HmrcVatSupport,
  VAT.App.Settings,
  VAT.DataModule,
  VAT.Enumerations,
  VAT.Entity.AuthToken,
  VAT.Hmrc.Gateway,
  Vcl.Dialogs;

procedure TLiabilitiesFrame.Loaded;
begin
  inherited;
  FromPicker.Date := StartOfTheMonth(IncMonth(Date, -3));
  ToPicker.Date := EndOfTheMonth(Date);
end;

procedure TLiabilitiesFrame.SetRange(const FromDate, ToDate: TDateTime);
begin
  if FromDate > 0 then
    FromPicker.Date := FromDate;
  if ToDate > 0 then
    ToPicker.Date := ToDate;
end;

function TLiabilitiesFrame.ChooseDates(Group: THmrcScenarioGroup): Boolean;
{$IFDEF DEBUG}
var
  Settings: TVATAppSettings;
  Scenario: string;
  FromDate, ToDate: TDateTime;
{$ENDIF}
begin
  {$IFDEF DEBUG}
  Result := ChooseGovScenario(Group, Scenario, FromDate, ToDate);
  if not Result then
    Exit;
  Settings := VatDataModule.Settings;
  Settings.Mode := opmTest;
  Settings.Scenario := Scenario;
  VatDataModule.ReplaceSettings(Settings);
  SetRange(FromDate, ToDate);
  if Assigned(FOnScenarioChosen) then
    FOnScenarioChosen(Scenario);
  {$ELSE}
  Result := True;
  {$ENDIF}
end;

procedure TLiabilitiesFrame.DescribeList(const Title: string; const Items: TObjectList);
var
  Index: Integer;
  Liability: HmrcVatSupport.TVatLiability;
  Payment: HmrcVatSupport.TVatPayment;
begin
  ResultMemo.Lines.Add(Title);
  if (Items = nil) or (Items.Count = 0) then
  begin
    ResultMemo.Lines.Add('No rows returned.');
    Exit;
  end;
  for Index := 0 to Items.Count - 1 do
  begin
    if Items[Index] is HmrcVatSupport.TVatLiability then
    begin
      Liability := HmrcVatSupport.TVatLiability(Items[Index]);
      ResultMemo.Lines.Add(Format('%s %s to %s due %s original %m outstanding %m',
        [Liability.What, DateToStr(Liability.Start), DateToStr(Liability.Stop), DateToStr(Liability.DueBy),
        Liability.Original, Liability.Outstanding]));
    end
    else if Items[Index] is HmrcVatSupport.TVatPayment then
    begin
      Payment := HmrcVatSupport.TVatPayment(Items[Index]);
      ResultMemo.Lines.Add(Format('Received %s amount %m', [DateToStr(Payment.Received), Payment.Amount]));
    end;
  end;
end;

procedure TLiabilitiesFrame.LiabilitiesButtonClick(Sender: TObject);
var
  Gateway: THmrcGateway;
  Items: TObjectList;
  Token: TAuthToken;
  Attempt: Integer;
begin
  if not ChooseDates(sgLiabilities) then
    Exit;
  Gateway := VatDataModule.Gateway;
  try
    Items := nil;
    for Attempt := 1 to 2 do
    begin
      Token := VatDataModule.Store.LoadToken(VatDataModule.Profile.Id, 'read:vat');
      Items := Gateway.Liabilities(FromPicker.Date, ToPicker.Date, Token);
      if (Items <> nil) or (not Gateway.NeedsNewToken) or (Attempt = 2) then
        Break;
      if not VatDataModule.RenewHmrcAccess('read:vat') then
        Exit;
    end;
    try
      if (Items = nil) and (Trim(Gateway.LastError) <> '') then
        ShowMessage(Gateway.LastError)
      else
        DescribeList('Liabilities', Items);
    finally
      Items.Free;
    end;
  finally
    Gateway.Free;
  end;
end;

procedure TLiabilitiesFrame.PaymentsButtonClick(Sender: TObject);
var
  Gateway: THmrcGateway;
  Items: TObjectList;
  Token: TAuthToken;
  Attempt: Integer;
begin
  if not ChooseDates(sgPayments) then
    Exit;
  Gateway := VatDataModule.Gateway;
  try
    Items := nil;
    for Attempt := 1 to 2 do
    begin
      Token := VatDataModule.Store.LoadToken(VatDataModule.Profile.Id, 'read:vat');
      Items := Gateway.Payments(FromPicker.Date, ToPicker.Date, Token);
      if (Items <> nil) or (not Gateway.NeedsNewToken) or (Attempt = 2) then
        Break;
      if not VatDataModule.RenewHmrcAccess('read:vat') then
        Exit;
    end;
    try
      if (Items = nil) and (Trim(Gateway.LastError) <> '') then
        ShowMessage(Gateway.LastError)
      else
        DescribeList('Payments', Items);
    finally
      Items.Free;
    end;
  finally
    Gateway.Free;
  end;
end;

end.
