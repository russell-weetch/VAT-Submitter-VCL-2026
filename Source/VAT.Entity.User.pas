{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Entity.User;

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
  [Sequence('SYS_GEN')]
  [Id('FId', TIdGenerator.IdentityOrSequence)]
  {$ENDIF}
  TVATUser = class
  private
    FUserLevel: TUserLevel;
    FSalt: string;
    FLastName: string;
    FCreatedBy: Integer;
    FCreated: TDateTime;
    FId: Integer;
    FStatus: TUserStatus;
    FPassword: string;
    FFirstName: string;
    FUserName: string;
  public
    function FullName: string;
    property Id: Integer read FId write FId;
    property FirstName: string read FFirstName write FFirstName;
    property LastName: string read FLastName write FLastName;
    property UserName: string read FUserName write FUserName;
    property Password: string read FPassword write FPassword;
    property Salt: string read FSalt write FSalt;
    property Status: TUserStatus read FStatus write FStatus;
    property Level: TUserLevel read FUserLevel write FUserLevel;
    property Created: TDateTime read FCreated write FCreated;
    property CreatedBy: Integer read FCreatedBy write FCreatedBy;
  end;

implementation

function TVATUser.FullName: string;
begin
  Result := (FirstName + ' ' + LastName).Trim;
end;

initialization

{$IF Defined(VAT_AURELIUS)}
  RegisterEntity(TVATUser);
{$ENDIF}

end.
