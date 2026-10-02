{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Entity.VATReturn;

interface

uses
  {$IF Defined(VAT_AURELIUS)}
  Aurelius.Mapping.Attributes,
  {$ENDIF}
  System.SysUtils;

type
  {$IF Defined(VAT_AURELIUS)}
  [Entity]
  [Automapping]
  [Sequence('SYS_GEN')]
  [Id('FId', TIdGenerator.IdentityOrSequence)]
  {$ENDIF}
  TVATReturn = class
  private
    FId: Integer;
    FPeriodKey: string;
    FTotalVatDue: Currency;
    FVatDueSales: Currency;
    FVatDueECAcquisitions: Currency;
    FVatReclaimed: Currency;
    FTotalPurchaseValue: Currency;
    FTotalSalesValue: Currency;
    FTotalECSupplied: Currency;
    FTotalECAquired: Currency;
    FReceiptID: string;
    FReceiptTimestamp: TDateTime;
    FReceiptSignature: string;
    FChargeRefNumber: string;
    FFormBundleNumber: Int64;
    FPaymentIndicator: string;
    FProcessingDate: TDateTime;
    FXCorrelationId: string;
    FFinalised: Boolean;
    FSubmitted: TDateTime;
    FProfileId: Integer;
    FSubmittedBy: Integer;
  public
    property Id: Integer read FId write FId;
    property ProfileId: Integer read FProfileId write FProfileId;
    property PeriodKey: string read FPeriodKey write FPeriodKey;
    property VatDueSales: Currency read FVatDueSales write FVatDueSales;
    property VatDueECAcquisitions: Currency read FVatDueECAcquisitions write FVatDueECAcquisitions;
    property TotalVatDue: Currency read FTotalVatDue write FTotalVatDue;
    property VatReclaimed: Currency read FVatReclaimed write FVatReclaimed;
    property TotalSalesValue: Currency read FTotalSalesValue write FTotalSalesValue;
    property TotalPurchaseValue: Currency read FTotalPurchaseValue write FTotalPurchaseValue;
    property TotalECSupplied: Currency read FTotalECSupplied write FTotalECSupplied;
    property TotalECAquired: Currency read FTotalECAquired write FTotalECAquired;
    property Finalised: Boolean read FFinalised write FFinalised;
    property Submitted: TDateTime read FSubmitted write FSubmitted;
    property SubmittedBy: Integer read FSubmittedBy write FSubmittedBy;
    property XCorrelationId: string read FXCorrelationId write FXCorrelationId;
    property ReceiptID: string read FReceiptID write FReceiptID;
    property ReceiptTimestamp: TDateTime read FReceiptTimestamp write FReceiptTimestamp;
    property ReceiptSignature: string read FReceiptSignature write FReceiptSignature;
    property ProcessingDate: TDateTime read FProcessingDate write FProcessingDate;
    property PaymentIndicator: string read FPaymentIndicator write FPaymentIndicator;
    property FormBundleNumber: Int64 read FFormBundleNumber write FFormBundleNumber;
    property ChargeRefNumber: string read FChargeRefNumber write FChargeRefNumber;
  end;

implementation

initialization

{$IF Defined(VAT_AURELIUS)}
  RegisterEntity(TVATReturn);
{$ENDIF}

end.
