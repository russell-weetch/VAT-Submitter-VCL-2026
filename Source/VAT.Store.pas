{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Store;

interface

uses
  System.Generics.Collections,
  Aurelius.Drivers.Interfaces,
  Aurelius.Engine.ObjectManager,
  VAT.Entity.AuthToken,
  VAT.Entity.Obligation,
  VAT.Entity.Profile,
  VAT.Entity.User,
  VAT.Entity.VATReturn,
  VAT.Enumerations,
  VAT.Return.Model;

type
  TVATStore = class
  private
    FConnection: IDBConnection;
    FManager: TObjectManager;
    function FindUserByName(const UserName: string): TVATUser;
    function FindReturnByPeriod(const PeriodKey: string): TVATReturn;
    function FindObligation(const PeriodKey: string): TVATObligation;
    function FindToken(const ProfileId: Integer; const Scope: string): TAuthToken;
  public
    constructor Create(const DatabaseFile: string);
    destructor Destroy; override;
    procedure UpdateSchema;
    function UserCount: Integer;
    function AddUser(const FirstName, LastName, UserName, Password: string;
      Status: TUserStatus; Level: TUserLevel; CreatedBy: Integer): TVATUser;
    function Login(const UserName, Password: string): TVATUser;
    function ListUsers: TList<TVATUser>;
    function LoadProfile: TProfile;
    procedure SaveProfile(const Profile: TProfile);
    function ListObligations: TList<TVATObligation>;
    procedure UpsertObligation(const ProfileId: Integer; const PeriodKey, Status: string;
      const PeriodStart, PeriodEnd, DueDate, Received: TDateTime; ReturnStatus: TReturnStatus);
    function LoadReturn(const ProfileId: Integer; const PeriodKey: string): TVATReturn;
    procedure SaveBoxes(const ProfileId, SubmittedBy: Integer; const Boxes: TVATReturnBoxes;
      const MarkSubmitted: Boolean; const CorrelationId, ReceiptId, PaymentIndicator, ChargeRef: string;
      const FormBundle: Int64; const ProcessedAt: TDateTime);
    function LoadToken(const ProfileId: Integer; const Scope: string): TAuthToken;
    procedure SaveToken(const ProfileId: Integer; const UserId, Scope, AccessToken, RefreshToken: string;
      const Expires, Stops: TDateTime);
    property Manager: TObjectManager read FManager;
  end;

implementation

uses
  System.SysUtils,
  Aurelius.Criteria.Base,
  Aurelius.Criteria.Linq,
  Aurelius.Drivers.SQLite,
  Aurelius.Engine.DatabaseManager,
  Aurelius.Schema.SQLite,
  Aurelius.Sql.SQLite,
  VAT.Users.Password;

constructor TVATStore.Create(const DatabaseFile: string);
begin
  inherited Create;
  FConnection := TSQLiteNativeConnectionAdapter.Create(DatabaseFile);
  FManager := TObjectManager.Create(FConnection);
end;

destructor TVATStore.Destroy;
begin
  FManager.Free;
  FConnection := nil;
  inherited;
end;

procedure TVATStore.UpdateSchema;
begin
  TDatabaseManager.Update(FConnection);
end;

function TVATStore.UserCount: Integer;
var
  Users: TList<TVATUser>;
begin
  Users := FManager.Find<TVATUser>.List;
  try
    Result := Users.Count;
  finally
    Users.Free;
  end;
end;

function TVATStore.FindUserByName(const UserName: string): TVATUser;
var
  Users: TList<TVATUser>;
begin
  Result := nil;
  Users := FManager.Find<TVATUser>.Where(Linq['UserName'] = UserName.Trim.ToUpper).List;
  try
    if Users.Count > 0 then
      Result := Users[0];
  finally
    Users.Free;
  end;
end;

function TVATStore.AddUser(const FirstName, LastName, UserName, Password: string;
  Status: TUserStatus; Level: TUserLevel; CreatedBy: Integer): TVATUser;
begin
  if FindUserByName(UserName) <> nil then
    raise Exception.Create('That user name already exists');
  Result := TVATUser.Create;
  Result.FirstName := FirstName.Trim;
  Result.LastName := LastName.Trim;
  Result.UserName := UserName.Trim.ToUpper;
  Result.Salt := GenerateSalt;
  Result.Password := PasswordHash(Password, Result.Salt);
  Result.Status := Status;
  Result.Level := Level;
  Result.Created := Now;
  Result.CreatedBy := CreatedBy;
  FManager.Save(Result);
  FManager.Flush;
end;

function TVATStore.Login(const UserName, Password: string): TVATUser;
begin
  Result := FindUserByName(UserName);
  if Result = nil then
    Exit(nil);
  if Password.Trim = '' then
    Exit(nil);
  if PasswordHash(Password, Result.Salt) <> Result.Password then
    Exit(nil);
  if (Result.Level = ulDeleted) or (Result.Status = usNone) then
    Exit(nil);
end;

function TVATStore.ListUsers: TList<TVATUser>;
begin
  Result := FManager.Find<TVATUser>.List;
end;

function TVATStore.LoadProfile: TProfile;
var
  Profiles: TList<TProfile>;
begin
  Profiles := FManager.Find<TProfile>.List;
  try
    if Profiles.Count = 0 then
    begin
      Result := TProfile.Create;
      Result.Name := 'New profile';
      Result.VATRegDate := Date;
      FManager.Save(Result);
      FManager.Flush;
    end
    else
      Result := Profiles[0];
  finally
    Profiles.Free;
  end;
end;

procedure TVATStore.SaveProfile(const Profile: TProfile);
begin
  FManager.Flush;
end;

function TVATStore.ListObligations: TList<TVATObligation>;
begin
  Result := FManager.Find<TVATObligation>.List;
end;

function TVATStore.FindObligation(const PeriodKey: string): TVATObligation;
var
  Items: TList<TVATObligation>;
begin
  Result := nil;
  Items := FManager.Find<TVATObligation>.Where(Linq['PeriodKey'] = PeriodKey).List;
  try
    if Items.Count > 0 then
      Result := Items[0];
  finally
    Items.Free;
  end;
end;

procedure TVATStore.UpsertObligation(const ProfileId: Integer; const PeriodKey, Status: string;
  const PeriodStart, PeriodEnd, DueDate, Received: TDateTime; ReturnStatus: TReturnStatus);
var
  Item: TVATObligation;
  IsNew: Boolean;
begin
  Item := FindObligation(PeriodKey);
  IsNew := Item = nil;
  if IsNew then
  begin
    Item := TVATObligation.Create;
    Item.PeriodKey := PeriodKey;
  end;
  Item.AccountId := ProfileId;
  Item.PeriodStart := PeriodStart;
  Item.PeriodEnd := PeriodEnd;
  Item.Due := DueDate;
  Item.Received := Received;
  Item.Status := Status;
  if (Status = 'F') and (Item.ReturnStatus <> rsSubmitted) then
    Item.ReturnStatus := rsFulfilled
  else if Item.ReturnStatus = rsNotProcessed then
    Item.ReturnStatus := ReturnStatus;
  Item.LastUpdated := Now;
  if IsNew then
    FManager.Save(Item);
  FManager.Flush;
end;

function TVATStore.FindReturnByPeriod(const PeriodKey: string): TVATReturn;
var
  Items: TList<TVATReturn>;
begin
  Result := nil;
  Items := FManager.Find<TVATReturn>.Where(Linq['PeriodKey'] = PeriodKey).List;
  try
    if Items.Count > 0 then
      Result := Items[0];
  finally
    Items.Free;
  end;
end;

function TVATStore.LoadReturn(const ProfileId: Integer; const PeriodKey: string): TVATReturn;
begin
  Result := FindReturnByPeriod(PeriodKey);
  if Result <> nil then
    Exit;
  Result := TVATReturn.Create;
  Result.ProfileId := ProfileId;
  Result.PeriodKey := PeriodKey;
  FManager.Save(Result);
  FManager.Flush;
end;

procedure TVATStore.SaveBoxes(const ProfileId, SubmittedBy: Integer; const Boxes: TVATReturnBoxes;
  const MarkSubmitted: Boolean; const CorrelationId, ReceiptId, PaymentIndicator, ChargeRef: string;
  const FormBundle: Int64; const ProcessedAt: TDateTime);
var
  Item: TVATReturn;
  Obligation: TVATObligation;
begin
  Item := LoadReturn(ProfileId, Boxes.PeriodKey);
  Item.VatDueSales := Boxes.VatDueSales;
  Item.VatDueECAcquisitions := Boxes.VatDueAcquisitions;
  Item.TotalVatDue := Boxes.TotalVatDue;
  Item.VatReclaimed := Boxes.VatReclaimed;
  Item.TotalSalesValue := Boxes.TotalSalesExVat;
  Item.TotalPurchaseValue := Boxes.TotalPurchasesExVat;
  Item.TotalECSupplied := Boxes.TotalGoodsSuppliedExVat;
  Item.TotalECAquired := Boxes.TotalAcquisitionsExVat;
  Item.Finalised := MarkSubmitted;
  if MarkSubmitted then
  begin
    Item.Submitted := Now;
    Item.SubmittedBy := SubmittedBy;
    Item.XCorrelationId := CorrelationId;
    Item.ReceiptID := ReceiptId;
    Item.ReceiptTimestamp := ProcessedAt;
    Item.ProcessingDate := ProcessedAt;
    Item.PaymentIndicator := PaymentIndicator;
    Item.FormBundleNumber := FormBundle;
    Item.ChargeRefNumber := ChargeRef;
    Obligation := FindObligation(Boxes.PeriodKey);
    if Obligation <> nil then
    begin
      Obligation.ReturnStatus := rsSubmitted;
      Obligation.LastUpdated := Now;
    end;
  end;
  FManager.Flush;
end;

function TVATStore.FindToken(const ProfileId: Integer; const Scope: string): TAuthToken;
var
  Items: TList<TAuthToken>;
begin
  Result := nil;
  Items := FManager.Find<TAuthToken>
    .Where((Linq['ProfileId'] = ProfileId) and (Linq['AuthScope'] = Scope))
    .List;
  try
    if Items.Count > 0 then
      Result := Items[0];
  finally
    Items.Free;
  end;
end;

function TVATStore.LoadToken(const ProfileId: Integer; const Scope: string): TAuthToken;
begin
  Result := FindToken(ProfileId, Scope);
end;

procedure TVATStore.SaveToken(const ProfileId: Integer; const UserId, Scope, AccessToken, RefreshToken: string;
  const Expires, Stops: TDateTime);
var
  Item: TAuthToken;
begin
  Item := FindToken(ProfileId, Scope);
  if Item = nil then
  begin
    Item := TAuthToken.Create;
    Item.ProfileId := ProfileId;
    Item.AuthScope := Scope;
    FManager.Save(Item);
  end;
  Item.UserId := UserId;
  Item.AccessToken := AccessToken;
  Item.RefreshToken := RefreshToken;
  Item.TokenExpires := Expires;
  Item.TokenStops := Stops;
  Item.Created := Now;
  FManager.Flush;
end;

end.
