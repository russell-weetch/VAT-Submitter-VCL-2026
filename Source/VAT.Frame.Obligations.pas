{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Frame.Obligations;

interface

uses
  System.Classes,
  System.SysUtils,
  Data.DB,
  Datasnap.DBClient,
  Vcl.ComCtrls,
  Vcl.Controls,
  Vcl.DBGrids,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Grids,
  Vcl.StdCtrls;

type
  TPeriodSelectedEvent = procedure(const PeriodKey: string; Processed: Boolean) of object;
  TScenarioChosenEvent = procedure(const Scenario: string) of object;

  TObligationsFrame = class(TFrame)
    HeaderPanel: TPanel;
    FromLabel: TLabel;
    ToLabel: TLabel;
    FromPicker: TDateTimePicker;
    ToPicker: TDateTimePicker;
    RefreshButton: TButton;
    ObligationsGrid: TDBGrid;
    ObligationSource: TDataSource;
    Obligations: TClientDataSet;
    procedure RefreshButtonClick(Sender: TObject);
    procedure ObligationsGridDblClick(Sender: TObject);
  private
    FOnPeriodSelected: TPeriodSelectedEvent;
    FOnScenarioChosen: TScenarioChosenEvent;
    procedure EnsureData;
  protected
    procedure Loaded; override;
  public
    procedure LoadRows;
    procedure SetRange(const FromDate, ToDate: TDateTime);
    function SelectedPeriod(out PeriodKey: string; out Processed: Boolean): Boolean;
    property OnPeriodSelected: TPeriodSelectedEvent read FOnPeriodSelected write FOnPeriodSelected;
    property OnScenarioChosen: TScenarioChosenEvent read FOnScenarioChosen write FOnScenarioChosen;
  end;

implementation

{$R *.dfm}

uses
  System.Contnrs,
  System.DateUtils,
  System.Generics.Collections,
  HmrcVatSupport,
  VAT.App.Settings,
  VAT.DataModule,
  VAT.Enumerations,
  VAT.Entity.AuthToken,
  VAT.Entity.Obligation,
  VAT.Form.Scenario,
  VAT.Hmrc.Gateway,
  Vcl.Dialogs;

procedure TObligationsFrame.Loaded;
begin
  inherited;
  EnsureData;
  FromPicker.Date := StartOfTheMonth(IncMonth(Date, -3));
  ToPicker.Date := EndOfTheMonth(Date);
end;

procedure TObligationsFrame.EnsureData;
begin
  if not Obligations.Active then
    Obligations.CreateDataSet;
end;

procedure TObligationsFrame.SetRange(const FromDate, ToDate: TDateTime);
begin
  if FromDate > 0 then
    FromPicker.Date := FromDate;
  if ToDate > 0 then
    ToPicker.Date := ToDate;
end;

procedure TObligationsFrame.LoadRows;
var
  Items: TList<VAT.Entity.Obligation.TVATObligation>;
  Item: VAT.Entity.Obligation.TVATObligation;
begin
  EnsureData;
  Obligations.EmptyDataSet;
  Items := VatDataModule.Store.ListObligations;
  try
    for Item in Items do
    begin
      Obligations.Append;
      Obligations.FieldByName('PeriodKey').AsString := Item.PeriodKey;
      Obligations.FieldByName('PeriodStart').AsDateTime := Item.PeriodStart;
      Obligations.FieldByName('PeriodEnd').AsDateTime := Item.PeriodEnd;
      Obligations.FieldByName('Due').AsDateTime := Item.Due;
      Obligations.FieldByName('Status').AsString := Item.Status;
      Obligations.FieldByName('ReturnStatus').AsString := ReturnStatusText(Item.ReturnStatus);
      Obligations.Post;
    end;
  finally
    Items.Free;
  end;
end;

procedure TObligationsFrame.RefreshButtonClick(Sender: TObject);
var
  Gateway: THmrcGateway;
  Items: TObjectList;
  Item: HmrcVatSupport.TVatObligation;
  Index: Integer;
  Token: TAuthToken;
  Settings: TVATAppSettings;
  Scenario: string;
  FromDate, ToDate: TDateTime;
  Attempt: Integer;
begin
  {$IFDEF DEBUG}
  if not ChooseGovScenario(sgObligations, Scenario, FromDate, ToDate) then
    Exit;
  Settings := VatDataModule.Settings;
  Settings.Mode := opmTest;
  Settings.Scenario := Scenario;
  VatDataModule.ReplaceSettings(Settings);
  SetRange(FromDate, ToDate);
  if Assigned(FOnScenarioChosen) then
    FOnScenarioChosen(Scenario);
  {$ENDIF}
  Gateway := VatDataModule.Gateway;
  try
    Items := nil;
    for Attempt := 1 to 2 do
    begin
      Token := VatDataModule.Store.LoadToken(VatDataModule.Profile.Id, 'read:vat');
      Items := Gateway.Obligations(FromPicker.Date, ToPicker.Date, Token);
      if (Items <> nil) or (not Gateway.NeedsNewToken) or (Attempt = 2) then
        Break;
      if not VatDataModule.RenewHmrcAccess('read:vat') then
        Exit;
    end;
    try
      if Items = nil then
      begin
        if Trim(Gateway.LastError) <> '' then
          ShowMessage(Gateway.LastError);
        Exit;
      end;
      for Index := 0 to Items.Count - 1 do
      begin
        Item := HmrcVatSupport.TVatObligation(Items[Index]);
        VatDataModule.Store.UpsertObligation(VatDataModule.Profile.Id, Item.Periodkey, Item.Status,
          Item.Start, Item.Stop, Item.DueBy, Item.Received, rsNotProcessed);
      end;
    finally
      Items.Free;
    end;
    LoadRows;
  finally
    Gateway.Free;
  end;
end;

procedure TObligationsFrame.ObligationsGridDblClick(Sender: TObject);
var
  PeriodKey: string;
  Processed: Boolean;
begin
  if not SelectedPeriod(PeriodKey, Processed) then
    Exit;
  if Assigned(FOnPeriodSelected) then
    FOnPeriodSelected(PeriodKey, Processed);
end;

function TObligationsFrame.SelectedPeriod(out PeriodKey: string; out Processed: Boolean): Boolean;
var
  ReturnText: string;
begin
  PeriodKey := '';
  Processed := False;
  Result := Obligations.Active and (not Obligations.IsEmpty);
  if not Result then
    Exit;
  PeriodKey := Trim(Obligations.FieldByName('PeriodKey').AsString);
  Result := PeriodKey <> '';
  ReturnText := Obligations.FieldByName('ReturnStatus').AsString;
  Processed := SameText(Obligations.FieldByName('Status').AsString, 'F') or
    SameText(ReturnText, 'Submitted') or SameText(ReturnText, 'Fulfilled');
end;

end.
