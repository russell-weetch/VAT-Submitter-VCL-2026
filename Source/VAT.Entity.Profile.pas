{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Entity.Profile;

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
  TProfile = class
  private
    FId: Integer;
    FName: string;
    FUserId: string;
    FVATNumber: Int64;
    FEmail: string;
    FAddress2: string;
    FAddress1: string;
    FVATRegDate: TDateTime;
    FPostCode: string;
    FHMRCPassword: string;
    FOrganisationName: string;
  public
    property Id: Integer read FId write FId;
    property UserId: string read FUserId write FUserId;
    property HMRCPassword: string read FHMRCPassword write FHMRCPassword;
    property Name: string read FName write FName;
    property Email: string read FEmail write FEmail;
    property OrganisationName: string read FOrganisationName write FOrganisationName;
    property Address1: string read FAddress1 write FAddress1;
    property Address2: string read FAddress2 write FAddress2;
    property Postcode: string read FPostCode write FPostCode;
    property VATNumber: Int64 read FVATNumber write FVATNumber;
    property VATRegDate: TDateTime read FVATRegDate write FVATRegDate;
  end;

implementation

initialization

{$IF Defined(VAT_AURELIUS)}
  RegisterEntity(TProfile);
{$ENDIF}

end.
