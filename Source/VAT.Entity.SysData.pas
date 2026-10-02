{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Entity.SysData;

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
  TSysData = class
  private
    FId: Integer;
    FKey: string;
    FValue: string;
  public
    property Id: Integer read FId write FId;
    property Key: string read FKey write FKey;
    property Value: string read FValue write FValue;
  end;

implementation

initialization

{$IF Defined(VAT_AURELIUS)}
  RegisterEntity(TSysData);
{$ENDIF}

end.
