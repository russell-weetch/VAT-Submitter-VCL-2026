{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Form.Scenario;

interface

uses
  System.Classes,
  System.SysUtils,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls;

type
  THmrcScenarioGroup = (sgObligations, sgVATReturn, sgLiabilities, sgPayments);

  TScenarioForm = class(TForm)
    ScenarioList: TListBox;
    UseButton: TButton;
    CancelButton: TButton;
  public
    procedure Prepare(Group: THmrcScenarioGroup);
  end;

function ChooseGovScenario(Group: THmrcScenarioGroup; out Scenario: string; out FromDate, ToDate: TDateTime): Boolean;

implementation

{$R *.dfm}

uses
  VAT.Return.Model;

type
  TScenarioItem = record
    Value: string;
    Description: string;
    DateFrom: string;
    DateTo: string;
  end;

const
  ObligationScenarios: array[0..10] of TScenarioItem = (
    (Value: ''; Description: 'Default, quarterly obligations and one fulfilled'),
    (Value: 'QUARTERLY_NONE_MET'; Description: 'Quarterly obligations and none fulfilled'),
    (Value: 'QUARTERLY_ONE_MET'; Description: 'Quarterly obligations and one fulfilled'),
    (Value: 'QUARTERLY_TWO_MET'; Description: 'Quarterly obligations and two fulfilled'),
    (Value: 'QUARTERLY_THREE_MET'; Description: 'Quarterly obligations and three fulfilled'),
    (Value: 'QUARTERLY_FOUR_MET'; Description: 'Quarterly obligations and four fulfilled'),
    (Value: 'MONTHLY_NONE_MET'; Description: 'Monthly obligations and none fulfilled'),
    (Value: 'MONTHLY_ONE_MET'; Description: 'Monthly obligations and one fulfilled'),
    (Value: 'MONTHLY_TWO_MET'; Description: 'Monthly obligations and two fulfilled'),
    (Value: 'MONTHLY_THREE_MET'; Description: 'Monthly obligations and three fulfilled'),
    (Value: 'NOT_FOUND'; Description: 'No obligation data is found')
  );
  ReturnScenarios: array[0..5] of TScenarioItem = (
    (Value: ''; Description: 'Default'),
    (Value: 'INVALID_VRN'; Description: 'Submission fails validation because the VRN is invalid'),
    (Value: 'INVALID_PERIODKEY'; Description: 'Submission fails validation because the period key is invalid'),
    (Value: 'INVALID_PAYLOAD'; Description: 'Submission fails validation because the payload is invalid'),
    (Value: 'DUPLICATE_SUBMISSION'; Description: 'VAT has already been submitted for that period'),
    (Value: 'TAX_PERIOD_NOT_ENDED'; Description: 'The tax period has not ended')
  );
  LiabilityScenarios: array[0..2] of TScenarioItem = (
    (Value: ''; Description: 'Default'),
    (Value: 'SINGLE_LIABILITY'; Description: 'One liability'; DateFrom: '2017-01-02'; DateTo: '2017-02-02'),
    (Value: 'MULTIPLE_LIABILITIES'; Description: 'Several liabilities'; DateFrom: '2017-04-05'; DateTo: '2017-12-21')
  );
  PaymentScenarios: array[0..2] of TScenarioItem = (
    (Value: ''; Description: 'Default'),
    (Value: 'SINGLE_PAYMENT'; Description: 'One payment'; DateFrom: '2017-01-02'; DateTo: '2017-02-02'),
    (Value: 'MULTIPLE_PAYMENTS'; Description: 'Several payments'; DateFrom: '2017-02-27'; DateTo: '2017-12-21')
  );

function ItemCaption(const Item: TScenarioItem): string;
begin
  if Item.Value = '' then
    Result := 'Default - ' + Item.Description
  else
    Result := Item.Value + ' - ' + Item.Description;
end;

procedure TScenarioForm.Prepare(Group: THmrcScenarioGroup);
var
  Index: Integer;
begin
  ScenarioList.Items.BeginUpdate;
  try
    ScenarioList.Items.Clear;
    case Group of
      sgObligations:
        for Index := Low(ObligationScenarios) to High(ObligationScenarios) do
          ScenarioList.Items.Add(ItemCaption(ObligationScenarios[Index]));
      sgVATReturn:
        for Index := Low(ReturnScenarios) to High(ReturnScenarios) do
          ScenarioList.Items.Add(ItemCaption(ReturnScenarios[Index]));
      sgLiabilities:
        for Index := Low(LiabilityScenarios) to High(LiabilityScenarios) do
          ScenarioList.Items.Add(ItemCaption(LiabilityScenarios[Index]));
      sgPayments:
        for Index := Low(PaymentScenarios) to High(PaymentScenarios) do
          ScenarioList.Items.Add(ItemCaption(PaymentScenarios[Index]));
    end;
    ScenarioList.ItemIndex := 0;
  finally
    ScenarioList.Items.EndUpdate;
  end;
end;

function ChooseGovScenario(Group: THmrcScenarioGroup; out Scenario: string; out FromDate, ToDate: TDateTime): Boolean;
var
  Dialog: TScenarioForm;
  Index: Integer;
  Item: TScenarioItem;
begin
  Scenario := '';
  FromDate := 0;
  ToDate := 0;
  Result := False;
  Dialog := TScenarioForm.Create(nil);
  try
    Dialog.Prepare(Group);
    if Dialog.ShowModal <> mrOk then
      Exit;
    Index := Dialog.ScenarioList.ItemIndex;
    if Index < 0 then
      Exit;
    Item := Default(TScenarioItem);
    case Group of
      sgObligations:
        if Index <= High(ObligationScenarios) then
          Item := ObligationScenarios[Index];
      sgVATReturn:
        if Index <= High(ReturnScenarios) then
          Item := ReturnScenarios[Index];
      sgLiabilities:
        if Index <= High(LiabilityScenarios) then
          Item := LiabilityScenarios[Index];
      sgPayments:
        if Index <= High(PaymentScenarios) then
          Item := PaymentScenarios[Index];
    end;
    Scenario := Item.Value;
    if Item.DateFrom <> '' then
      FromDate := ConvertHMRCDate(Item.DateFrom);
    if Item.DateTo <> '' then
      ToDate := ConvertHMRCDate(Item.DateTo);
    Result := True;
  finally
    Dialog.Free;
  end;
end;

end.
