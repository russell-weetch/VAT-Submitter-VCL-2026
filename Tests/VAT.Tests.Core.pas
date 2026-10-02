{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Tests.Core;

interface

uses
  DUnitX.TestFramework,
  VAT.Hmrc.TestUser,
  VAT.Return.Model;

type
  [TestFixture]
  TReturnModelTests = class
  public
    [Test]
    procedure CalculatesNineBoxes;
    [Test]
    procedure RejectsShortPeriodKey;
    [Test]
    procedure ParsesSampleCsv;
    [Test]
    procedure AcceptsKnownVatNumber;
    [Test]
    procedure RejectsBadVatNumber;
    [Test]
    procedure ParsesHmrcDates;
    [Test]
    procedure ReadsHmrcErrorList;
    [Test]
    procedure ParsesSandboxCompany;
  end;

  [TestFixture]
  TPasswordTests = class
  public
    [Test]
    procedure MatchesRfc6070Vector;
    [Test]
    procedure SamePasswordProducesSameHash;
  end;

  [TestFixture]
  TLockTests = class
  public
    [Test]
    procedure OwnerCanDescribeAndRelease;
    [Test]
    procedure DeadProcessIsStale;
  end;

  [TestFixture]
  TStoreTests = class
  public
    [Test]
    procedure CreatesUserAndReturn;
  end;

implementation

uses
  System.Classes,
  System.DateUtils,
  System.IOUtils,
  System.SysUtils,
  VAT.Data.Lock,
  VAT.Entity.User,
  VAT.Entity.VATReturn,
  VAT.Enumerations,
  VAT.Store,
  VAT.Users.Password;

procedure TReturnModelTests.CalculatesNineBoxes;
var
  Boxes: TVATReturnBoxes;
  Values: TStringList;
begin
  Boxes.PeriodKey := '18A1';
  Boxes.VatDueSales := 100.25;
  Boxes.VatDueAcquisitions := 0;
  Boxes.VatReclaimed := 10.01;
  Boxes.TotalSalesExVat := 513;
  Boxes.TotalPurchasesExVat := 42;
  Boxes.Recalculate;
  Assert.AreEqual<Currency>(100.25, Boxes.TotalVatDue);
  Assert.AreEqual<Currency>(90.24, Boxes.NetVatDue);
  Assert.IsTrue(Boxes.IsValid);
  Values := TStringList.Create;
  try
    Boxes.FillSubmissionValues(Values);
    Assert.AreEqual(9, Values.Count);
    Assert.AreEqual('100.25', Values.Values['vatDueSales']);
    Assert.AreEqual('90.24', Values.Values['netVatDue']);
    Assert.AreEqual('513', Values.Values['totalValueSalesExVAT']);
  finally
    Values.Free;
  end;
end;

procedure TReturnModelTests.RejectsShortPeriodKey;
var
  Boxes: TVATReturnBoxes;
begin
  Boxes.PeriodKey := '18A';
  Boxes.Recalculate;
  Assert.IsFalse(Boxes.IsValid);
end;

procedure TReturnModelTests.ParsesSampleCsv;
var
  Boxes: TVATReturnBoxes;
begin
  Boxes := LoadReturnFromCsv(
    '"VATDUEONSALES","VATDUEONEUACQUISITIONS","VATRECLAIMED","TOTALSALES","TOTALPURCHASES","ECSUPPLIED","ECACQUIRED"' +
    sLineBreak + '100.25,0.00,10.01,513.26,42.10,0.00,0.00');
  Boxes.PeriodKey := '24A1';
  Assert.AreEqual<Currency>(100.25, Boxes.VatDueSales);
  Assert.AreEqual<Int64>(513, Boxes.TotalSalesExVat);
  Assert.AreEqual<Int64>(42, Boxes.TotalPurchasesExVat);
  Assert.AreEqual<Currency>(90.24, Boxes.NetVatDue);
  Assert.IsTrue(Boxes.IsValid);
end;

procedure TReturnModelTests.AcceptsKnownVatNumber;
begin
  Assert.IsTrue(IsValidUKVATNumber('123456782'));
end;

procedure TReturnModelTests.RejectsBadVatNumber;
begin
    Assert.IsFalse(IsValidUKVATNumber('123456700'));
    Assert.IsFalse(IsValidUKVATNumber('ABC'));
    Assert.IsTrue(IsValidUKVATNumber('736943990'));
end;

procedure TReturnModelTests.ParsesHmrcDates;
var
  Value: TDateTime;
begin
  Value := ConvertHMRCDate('2018-01-16');
  Assert.AreEqual(2018, YearOf(Value));
  Assert.AreEqual(1, MonthOf(Value));
  Assert.AreEqual(16, DayOf(Value));
  Value := ConvertHMRCDateTime('2018-01-16T08:20:27.895+0000');
  Assert.AreEqual(8, HourOf(Value));
  Assert.AreEqual(20, MinuteOf(Value));
  Assert.AreEqual(27, SecondOf(Value));
end;

procedure TReturnModelTests.ReadsHmrcErrorList;
var
  Message: string;
begin
  Message := GetHmrcErrorMessage(
    '{"code":"BUSINESS_ERROR","message":"Business validation error","errors":[{"code":"DUPLICATE_SUBMISSION","message":"The VAT return was already submitted for the given period."}]}');
  Assert.AreEqual('DUPLICATE_SUBMISSION: The VAT return was already submitted for the given period.', Message);
  Message := GetHmrcErrorMessage('{"code":"PERIOD_KEY_INVALID","message":"Invalid period key"}');
  Assert.AreEqual('PERIOD_KEY_INVALID: Invalid period key', Message);
end;

procedure TReturnModelTests.ParsesSandboxCompany;
var
  Company: THmrcTestCompany;
begin
  Company := ParseHmrcTestCompany(
    '{"userId":"973738496497","password":"fjdozjjvp4mr","userFullName":"Brett Walker",' +
    '"emailAddress":"brett.walker@example.com","organisationDetails":{"name":"Company MLORHK",' +
    '"address":{"line1":"3 Carnaby Street","line2":"Uxbridge","postcode":"TS19 1PA"}},' +
    '"vrn":"736943990","vatRegistrationDate":"2002-02-15"}');
  Assert.AreEqual('973738496497', Company.UserId);
  Assert.AreEqual('Company MLORHK', Company.Organisation);
  Assert.AreEqual(Int64(736943990), Company.VATNumber);
  Assert.AreEqual(2002, YearOf(Company.VATRegDate));
end;

procedure TPasswordTests.MatchesRfc6070Vector;
begin
  Assert.AreEqual('120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
    Pbkdf2HmacSha256Hex('password', 'salt', 1, 32));
end;

procedure TPasswordTests.SamePasswordProducesSameHash;
var
  Left, Right: string;
begin
  Left := PasswordHash('secret', 'salt', 2);
  Right := PasswordHash('secret', 'salt', 2);
  Assert.AreEqual(Left, Right);
  Assert.AreNotEqual(Left, PasswordHash('other', 'salt', 2));
end;

procedure TLockTests.OwnerCanDescribeAndRelease;
var
  Folder, FileName: string;
begin
  Folder := TPath.Combine(TPath.GetTempPath, 'vat-lock-' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(Folder);
  FileName := TPath.Combine(Folder, 'VATData.lck');
  try
    Assert.AreEqual(lsNotLocked, TVATDataLock.Status(FileName, 'mine'));
    TVATDataLock.Acquire(FileName, 'mine', 'Tester');
    Assert.AreEqual(lsLockedByMe, TVATDataLock.Status(FileName, 'mine'));
    Assert.AreEqual(lsLockedByOther, TVATDataLock.Status(FileName, 'other'));
    Assert.IsTrue(TVATDataLock.Describe(FileName, 'other').Contains('Tester'));
    Assert.IsFalse(TVATDataLock.ReleaseIfMine(FileName, 'other'));
    Assert.IsTrue(TVATDataLock.ReleaseIfMine(FileName, 'mine'));
    Assert.AreEqual(lsNotLocked, TVATDataLock.Status(FileName, 'mine'));
  finally
    TDirectory.Delete(Folder, True);
  end;
end;

procedure TLockTests.DeadProcessIsStale;
var
  Folder, FileName: string;
  Lines: TStringList;
begin
  Folder := TPath.Combine(TPath.GetTempPath, 'vat-lock-' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(Folder);
  FileName := TPath.Combine(Folder, 'VATData.lck');
  try
    TVATDataLock.Acquire(FileName, 'mine', 'Tester');
    Assert.IsFalse(TVATDataLock.IsStale(FileName));
    Lines := TStringList.Create;
    try
      Lines.LoadFromFile(FileName);
      Lines.Values['ProcessId'] := '4294967294';
      Lines.SaveToFile(FileName);
    finally
      Lines.Free;
    end;
    Assert.IsTrue(TVATDataLock.IsStale(FileName));
    TVATDataLock.Clear(FileName);
    Assert.AreEqual(lsNotLocked, TVATDataLock.Status(FileName, 'mine'));
  finally
    TDirectory.Delete(Folder, True);
  end;
end;

procedure TStoreTests.CreatesUserAndReturn;
var
  Folder, DatabaseFile: string;
  Store: TVATStore;
  User: TVATUser;
  Boxes: TVATReturnBoxes;
  Stored: TVATReturn;
begin
  Folder := TPath.Combine(TPath.GetTempPath, 'vat-store-' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(Folder);
  DatabaseFile := TPath.Combine(Folder, 'VATSubmitter.db');
  Store := TVATStore.Create(DatabaseFile);
  try
    Store.UpdateSchema;
    User := Store.AddUser('Rita', 'Jones', 'rita', 'secret', usSubmit, ulAdministrator, 0);
    Assert.IsNotNull(Store.Login('RITA', 'secret'));
    Assert.IsNull(Store.Login('rita', 'wrong'));
    Boxes.PeriodKey := '24A1';
    Boxes.VatDueSales := 10;
    Boxes.VatDueAcquisitions := 2.5;
    Boxes.VatReclaimed := 1;
    Boxes.TotalSalesExVat := 100;
    Boxes.Recalculate;
    Store.SaveBoxes(Store.LoadProfile.Id, User.Id, Boxes, False, '', '', '', '', 0, 0);
    Stored := Store.LoadReturn(Store.LoadProfile.Id, '24A1');
    Assert.AreEqual<Currency>(12.5, Stored.TotalVatDue);
    Assert.AreEqual('24A1', Stored.PeriodKey);
  finally
    Store.Free;
    TDirectory.Delete(Folder, True);
  end;
end;

initialization

  TDUnitX.RegisterTestFixture(TReturnModelTests);
  TDUnitX.RegisterTestFixture(TPasswordTests);
  TDUnitX.RegisterTestFixture(TLockTests);
  TDUnitX.RegisterTestFixture(TStoreTests);

end.
