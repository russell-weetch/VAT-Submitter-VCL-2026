{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Form.Declaration;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  VAT.Return.Model;

type
  TDeclarationForm = class(TForm)
    TitleLabel: TLabel;
    SummaryMemo: TMemo;
    LegalLabel: TLabel;
    SubmitButton: TButton;
    CancelButton: TButton;
    procedure ShowReturn(const Boxes: TVATReturnBoxes);
  end;

var
  DeclarationForm: TDeclarationForm;

implementation

{$R *.dfm}

uses
  System.SysUtils;

procedure TDeclarationForm.ShowReturn(const Boxes: TVATReturnBoxes);
begin
  SummaryMemo.Lines.Clear;
  SummaryMemo.Lines.Add('Period key: ' + Boxes.PeriodKey);
  SummaryMemo.Lines.Add('Box 1 VAT due on sales: ' + CurrToStrF(Boxes.VatDueSales, ffCurrency, 2));
  SummaryMemo.Lines.Add('Box 2 VAT due on acquisitions: ' + CurrToStrF(Boxes.VatDueAcquisitions, ffCurrency, 2));
  SummaryMemo.Lines.Add('Box 3 Total VAT due: ' + CurrToStrF(Boxes.TotalVatDue, ffCurrency, 2));
  SummaryMemo.Lines.Add('Box 4 VAT reclaimed: ' + CurrToStrF(Boxes.VatReclaimed, ffCurrency, 2));
  SummaryMemo.Lines.Add('Box 5 Net VAT: ' + CurrToStrF(Boxes.NetVatDue, ffCurrency, 2));
  SummaryMemo.Lines.Add('Box 6 Total sales ex VAT: ' + Boxes.TotalSalesExVat.ToString);
  SummaryMemo.Lines.Add('Box 7 Total purchases ex VAT: ' + Boxes.TotalPurchasesExVat.ToString);
  SummaryMemo.Lines.Add('Box 8 Goods supplied ex VAT: ' + Boxes.TotalGoodsSuppliedExVat.ToString);
  SummaryMemo.Lines.Add('Box 9 Acquisitions ex VAT: ' + Boxes.TotalAcquisitionsExVat.ToString);
  SummaryMemo.Lines.Add('');
  SummaryMemo.Lines.Add(Boxes.PaymentText);
end;

end.
