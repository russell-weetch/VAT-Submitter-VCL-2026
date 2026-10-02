{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Enumerations;

interface

{$IF Defined(VAT_AURELIUS)}
uses
  Aurelius.Mapping.Attributes;
{$ENDIF}

type
  {$IF Defined(VAT_AURELIUS)}
  [Enumeration(TEnumMappingType.emInteger)]
  {$ENDIF}
  TReturnStatus = (rsNotProcessed, rsPrepared, rsFinalised, rsSubmitted, rsFulfilled);

  {$IF Defined(VAT_AURELIUS)}
  [Enumeration(TEnumMappingType.emInteger)]
  {$ENDIF}
  TUserStatus = (usNone, usRead, usWrite, usSubmit);

  {$IF Defined(VAT_AURELIUS)}
  [Enumeration(TEnumMappingType.emInteger)]
  {$ENDIF}
  TUserLevel = (ulDeleted, ulStandard, ulAdministrator);

  TOpMode = (opmTest, opmLive);

function ReturnStatusText(const Value: TReturnStatus): string;
function UserStatusText(const Value: TUserStatus): string;
function UserLevelText(const Value: TUserLevel): string;
function OpModeText(const Value: TOpMode): string;
function ParseOpMode(const Value: string): TOpMode;

implementation

uses
  System.Rtti,
  System.SysUtils;

function ReturnStatusText(const Value: TReturnStatus): string;
begin
  Result := TRttiEnumerationType.GetName<TReturnStatus>(Value).Substring(2);
end;

function UserStatusText(const Value: TUserStatus): string;
begin
  Result := TRttiEnumerationType.GetName<TUserStatus>(Value).Substring(2);
end;

function UserLevelText(const Value: TUserLevel): string;
begin
  Result := TRttiEnumerationType.GetName<TUserLevel>(Value).Substring(2);
end;

function OpModeText(const Value: TOpMode): string;
begin
  if Value = opmLive then
    Result := 'Live'
  else
    Result := 'Test';
end;

function ParseOpMode(const Value: string): TOpMode;
begin
  if Value.Trim.ToLower = 'live' then
    Result := opmLive
  else
    Result := opmTest;
end;

end.
