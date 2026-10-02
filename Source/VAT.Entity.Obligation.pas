{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Entity.Obligation;

interface

uses
  {$IF Defined(VAT_AURELIUS)}
  Aurelius.Mapping.Attributes,
  {$ENDIF}
  VAT.Enumerations,
  System.SysUtils;

type
  {$IF Defined(VAT_AURELIUS)}
  [Entity]
  [Automapping]
  [Id('FPeriodKey', TIdGenerator.None)]
  {$ENDIF}
  TVATObligation = class
  private
    FPeriodStart: TDateTime;
    FPeriodEnd: TDateTime;
    FPeriodKey: string;
    FStatus: string;
    FReceived: TDateTime;
    FDue: TDateTime;
    FAccountId: Integer;
    FReturnStatus: TReturnStatus;
    FUpdated: TDateTime;
  public
    property AccountId: Integer read FAccountId write FAccountId;
    property PeriodKey: string read FPeriodKey write FPeriodKey;
    property PeriodStart: TDateTime read FPeriodStart write FPeriodStart;
    property PeriodEnd: TDateTime read FPeriodEnd write FPeriodEnd;
    property Due: TDateTime read FDue write FDue;
    property Received: TDateTime read FReceived write FReceived;
    property Status: string read FStatus write FStatus;
    property ReturnStatus: TReturnStatus read FReturnStatus write FReturnStatus;
    property LastUpdated: TDateTime read FUpdated write FUpdated;
  end;

implementation

initialization

{$IF Defined(VAT_AURELIUS)}
  RegisterEntity(TVATObligation);
{$ENDIF}

end.
