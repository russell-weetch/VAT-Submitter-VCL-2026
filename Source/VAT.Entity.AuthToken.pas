{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Entity.AuthToken;

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
  TAuthToken = class
  private
    FId: Integer;
    FRefreshToken: string;
    FTokenExpires: TDateTime;
    FAccessToken: string;
    FAuthScope: string;
    FTokenStops: TDateTime;
    FProfileId: Integer;
    FCreated: TDateTime;
    FUserId: string;
  public
    property Id: Integer read FId write FId;
    property UserId: string read FUserId write FUserId;
    property ProfileId: Integer read FProfileId write FProfileId;
    property AccessToken: string read FAccessToken write FAccessToken;
    property AuthScope: string read FAuthScope write FAuthScope;
    property TokenExpires: TDateTime read FTokenExpires write FTokenExpires;
    property TokenStops: TDateTime read FTokenStops write FTokenStops;
    property RefreshToken: string read FRefreshToken write FRefreshToken;
    property Created: TDateTime read FCreated write FCreated;
  end;

implementation

initialization

{$IF Defined(VAT_AURELIUS)}
  RegisterEntity(TAuthToken);
{$ENDIF}

end.
