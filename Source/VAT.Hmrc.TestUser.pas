{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Hmrc.TestUser;

interface

uses
  System.SysUtils,
  VAT.Entity.Profile;

type
  THmrcTestCompany = record
    UserId: string;
    Password: string;
    FullName: string;
    Email: string;
    Organisation: string;
    Address1: string;
    Address2: string;
    Postcode: string;
    VATNumber: Int64;
    VATRegDate: TDateTime;
  end;

function ParseHmrcTestCompany(const AJson: string): THmrcTestCompany;
procedure ApplyHmrcTestCompany(const Profile: TProfile; const Company: THmrcTestCompany);

implementation

uses
  System.JSON,
  VAT.Return.Model;

function JsonText(const Parent: TJSONObject; const Name: string): string;
var
  Value: TJSONValue;
begin
  Result := '';
  if (Parent = nil) or not Parent.TryGetValue<TJSONValue>(Name, Value) or (Value = nil) then
    Exit;
  if Value is TJSONString then
    Result := TJSONString(Value).Value
  else
    Result := Value.Value;
end;

function JsonNumber(const Parent: TJSONObject; const Name: string): Int64;
var
  Text: string;
begin
  Text := JsonText(Parent, Name);
  Result := StrToInt64Def(Text, 0);
end;

function ParseHmrcTestCompany(const AJson: string): THmrcTestCompany;
var
  Root, Organisation, Address: TJSONObject;
  Value: TJSONValue;
begin
  Result := Default(THmrcTestCompany);
  Value := TJSONObject.ParseJSONValue(AJson);
  if not (Value is TJSONObject) then
  begin
    Value.Free;
    raise Exception.Create('HMRC did not return a test company.');
  end;
  Root := TJSONObject(Value);
  try
    Result.UserId := JsonText(Root, 'userId');
    Result.Password := JsonText(Root, 'password');
    Result.FullName := JsonText(Root, 'userFullName');
    Result.Email := JsonText(Root, 'emailAddress');
    Result.VATNumber := JsonNumber(Root, 'vrn');
    Result.VATRegDate := ConvertHMRCDate(JsonText(Root, 'vatRegistrationDate'));
    if Root.TryGetValue<TJSONObject>('organisationDetails', Organisation) then
    begin
      Result.Organisation := JsonText(Organisation, 'name');
      if Organisation.TryGetValue<TJSONObject>('address', Address) then
      begin
        Result.Address1 := JsonText(Address, 'line1');
        Result.Address2 := JsonText(Address, 'line2');
        Result.Postcode := JsonText(Address, 'postcode');
      end;
    end;
    if (Result.UserId = '') or (Result.VATNumber <= 0) then
      raise Exception.Create('HMRC returned a test company without a user id or VAT number.');
  finally
    Root.Free;
  end;
end;

procedure ApplyHmrcTestCompany(const Profile: TProfile; const Company: THmrcTestCompany);
begin
  Profile.UserId := Company.UserId;
  Profile.HMRCPassword := Company.Password;
  Profile.Name := Company.FullName;
  Profile.Email := Company.Email;
  Profile.OrganisationName := Company.Organisation;
  Profile.Address1 := Company.Address1;
  Profile.Address2 := Company.Address2;
  Profile.Postcode := Company.Postcode;
  Profile.VATNumber := Company.VATNumber;
  Profile.VATRegDate := Company.VATRegDate;
end;

end.
