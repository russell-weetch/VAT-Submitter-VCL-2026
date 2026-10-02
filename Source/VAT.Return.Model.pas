{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Return.Model;

interface

uses
  System.Classes,
  System.SysUtils;

type
  EVATReturnError = class(Exception);

  TVATReturnBoxes = record
  public
    PeriodKey: string;
    VatDueSales: Currency;
    VatDueAcquisitions: Currency;
    TotalVatDue: Currency;
    VatReclaimed: Currency;
    NetVatDue: Currency;
    TotalSalesExVat: Int64;
    TotalPurchasesExVat: Int64;
    TotalGoodsSuppliedExVat: Int64;
    TotalAcquisitionsExVat: Int64;
    procedure Recalculate;
    function ValidationMessages: TArray<string>;
    function IsValid: Boolean;
    procedure FillSubmissionValues(const Values: TStrings);
    function PaymentText: string;
  end;

function IsValidUKVATNumber(const Value: string): Boolean;
function NormaliseVATNumber(const Value: string): string;
function ConvertHMRCDate(const Value: string): TDateTime;
function ConvertHMRCDateTime(const Value: string): TDateTime;
function DateTimeToHMRCDateTime(const Value: TDateTime): string;
function FormatHMRCDate(const Value: TDateTime): string;
function GetHmrcErrorMessage(const Value: string): string;
function LoadReturnFromCsv(const CsvText: string): TVATReturnBoxes;

implementation

uses
  System.JSON,
  System.Math;

function MoneyEqual(const Left, Right: Currency): Boolean;
begin
  Result := RoundTo(Left, -2) = RoundTo(Right, -2);
end;

function MoreThanTwoDecimals(const Value: Currency): Boolean;
begin
  Result := Value <> RoundTo(Value, -2);
end;

function NormaliseVATNumber(const Value: string): string;
var
  Ch: Char;
begin
  Result := '';
  for Ch in Value.Trim.ToUpper do
    if CharInSet(Ch, ['0'..'9']) then
      Result := Result + Ch;
end;

function CheckDigits(const SevenDigits: string; const Adjustment: Integer): Integer;
const
  Weights: array[1..7] of Integer = (8, 7, 6, 5, 4, 3, 2);
var
  Index, Total: Integer;
begin
  Total := Adjustment;
  for Index := 1 to 7 do
    Total := Total + StrToInt(SevenDigits[Index]) * Weights[Index];
  Result := 97 - (Total mod 97);
  if Result = 97 then
    Result := 0;
end;

function IsValidUKVATNumber(const Value: string): Boolean;
var
  Digits, Seven: string;
  Check: Integer;
begin
  Digits := NormaliseVATNumber(Value);
  if Digits.Length = 12 then
    Digits := Digits.Substring(0, 9);
  Result := Digits.Length = 9;
  if not Result then
    Exit;
  Seven := Digits.Substring(0, 7);
  Check := StrToInt(Digits.Substring(7, 2));
  Result := (Check = CheckDigits(Seven, 0)) or (Check = CheckDigits(Seven, 55));
end;

function ConvertHMRCDate(const Value: string): TDateTime;
var
  Parts: TArray<string>;
  Year, Month, Day: Integer;
begin
  Result := 0;
  if Value.Trim = '' then
    Exit;
  Parts := Value.Trim.Split(['-']);
  if Length(Parts) < 3 then
    Exit;
  Year := StrToIntDef(Parts[0], 0);
  Month := StrToIntDef(Parts[1], 0);
  Day := StrToIntDef(Copy(Parts[2], 1, 2), 0);
  if not TryEncodeDate(Year, Month, Day, Result) then
    Result := 0;
end;

function StripTimeZone(const Value: string): string;
var
  ZoneAt: Integer;
begin
  Result := Value.Trim;
  if Result.EndsWith('Z') then
    Result := Result.Substring(0, Result.Length - 1);
  ZoneAt := Result.IndexOf('+');
  if ZoneAt < 0 then
    ZoneAt := Result.LastIndexOf('-');
  if ZoneAt > 0 then
    Result := Result.Substring(0, ZoneAt);
end;

function ConvertHMRCTime(const Value: string): TDateTime;
var
  Parts: TArray<string>;
  Hour, Minute, Second, Milli: Integer;
  MilliText: string;
begin
  Result := 0;
  Parts := StripTimeZone(Value).Split([':', '.']);
  if Length(Parts) < 3 then
    Exit;
  Hour := StrToIntDef(Parts[0], -1);
  Minute := StrToIntDef(Parts[1], -1);
  Second := StrToIntDef(Parts[2], -1);
  Milli := 0;
  if Length(Parts) > 3 then
  begin
    MilliText := Parts[3];
    if MilliText.Length > 3 then
      MilliText := MilliText.Substring(0, 3);
    while MilliText.Length < 3 do
      MilliText := MilliText + '0';
    Milli := StrToIntDef(MilliText, 0);
  end;
  if not TryEncodeTime(Hour, Minute, Second, Milli, Result) then
    Result := 0;
end;

function ConvertHMRCDateTime(const Value: string): TDateTime;
var
  Parts: TArray<string>;
begin
  if Value.Trim = '' then
    Exit(0);
  Parts := Value.Trim.Split(['T']);
  if Length(Parts) < 2 then
    Exit(ConvertHMRCDate(Value));
  Result := ConvertHMRCDate(Parts[0]) + ConvertHMRCTime(Parts[1]);
end;

function DateTimeToHMRCDateTime(const Value: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', Value);
end;

function FormatHMRCDate(const Value: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd', Value);
end;

function GetHmrcErrorMessage(const Value: string): string;
var
  Root, Item: TJSONObject;
  Errors: TJSONArray;
  Entry: TJSONValue;
  Code, Message: string;
begin
  Result := Value.Trim;
  Root := TJSONObject.ParseJSONValue(Value) as TJSONObject;
  if Root = nil then
    Exit;
  try
    if Root.TryGetValue<TJSONArray>('errors', Errors) then
    begin
      Result := '';
      for Entry in Errors do
      begin
        Item := Entry as TJSONObject;
        Code := '';
        Message := '';
        Item.TryGetValue<string>('code', Code);
        Item.TryGetValue<string>('message', Message);
        if Result <> '' then
          Result := Result + sLineBreak;
        Result := Result + Code + ': ' + Message;
      end;
      Exit;
    end;
    Code := '';
    Message := '';
    if not Root.TryGetValue<string>('code', Code) then
      Code := 'No Code';
    if not Root.TryGetValue<string>('message', Message) then
      Message := 'no message';
    Result := Code + ': ' + Message;
  finally
    Root.Free;
  end;
end;

function CsvField(const Line: string; const Index: Integer): string;
var
  Parts: TArray<string>;
begin
  Parts := Line.Split([',']);
  if (Index < 0) or (Index > High(Parts)) then
    Exit('');
  Result := Parts[Index].Trim.DeQuotedString('"');
end;

function LoadReturnFromCsv(const CsvText: string): TVATReturnBoxes;
var
  Lines: TArray<string>;
  Index: Integer;
  Header: string;
  Amount: Double;
begin
  Result := Default(TVATReturnBoxes);
  Lines := CsvText.Replace(#13#10, #10, [rfReplaceAll]).Replace(#13, #10, [rfReplaceAll]).Trim.Split([#10]);
  while (Length(Lines) > 0) and (Lines[0].Trim = '') do
    Delete(Lines, 0, 1);
  if Length(Lines) < 2 then
    raise EVATReturnError.Create('The CSV file needs a header row and one value row.');
  for Index := 0 to 20 do
  begin
    Header := CsvField(Lines[0], Index).ToUpper;
    if Header = '' then
      Break;
    Amount := StrToFloatDef(CsvField(Lines[1], Index), 0, TFormatSettings.Invariant);
    if Header = 'VATDUEONSALES' then
      Result.VatDueSales := Amount
    else if Header = 'VATDUEONEUACQUISITIONS' then
      Result.VatDueAcquisitions := Amount
    else if Header = 'VATRECLAIMED' then
      Result.VatReclaimed := Amount
    else if Header = 'TOTALSALES' then
      Result.TotalSalesExVat := Trunc(Amount)
    else if Header = 'TOTALPURCHASES' then
      Result.TotalPurchasesExVat := Trunc(Amount)
    else if Header = 'ECSUPPLIED' then
      Result.TotalGoodsSuppliedExVat := Trunc(Amount)
    else if Header = 'ECACQUIRED' then
      Result.TotalAcquisitionsExVat := Trunc(Amount);
  end;
  Result.Recalculate;
end;

procedure TVATReturnBoxes.Recalculate;
begin
  TotalVatDue := RoundTo(VatDueSales, -2) + RoundTo(VatDueAcquisitions, -2);
  NetVatDue := Abs(TotalVatDue - RoundTo(VatReclaimed, -2));
end;

function TVATReturnBoxes.ValidationMessages: TArray<string>;
var
  Messages: TArray<string>;

  procedure Add(const Text: string);
  begin
    Messages := Messages + [Text];
  end;

begin
  if PeriodKey.Trim.Length <> 4 then
    Add('Period key must be 4 characters.');
  if (VatDueSales < 0) or (VatDueAcquisitions < 0) or (VatReclaimed < 0) then
    Add('VAT amounts cannot be negative.');
  if MoreThanTwoDecimals(VatDueSales) or MoreThanTwoDecimals(VatDueAcquisitions) or
    MoreThanTwoDecimals(VatReclaimed) then
    Add('Boxes 1, 2 and 4 are in pounds and pence.');
  if not MoneyEqual(TotalVatDue, VatDueSales + VatDueAcquisitions) then
    Add('Box 3 must equal box 1 plus box 2.');
  if not MoneyEqual(NetVatDue, Abs(TotalVatDue - VatReclaimed)) then
    Add('Box 5 must be the absolute difference between box 3 and box 4.');
  if (TotalSalesExVat < 0) or (TotalPurchasesExVat < 0) or
    (TotalGoodsSuppliedExVat < 0) or (TotalAcquisitionsExVat < 0) then
    Add('Boxes 6 to 9 cannot be negative.');
  Result := Messages;
end;

function TVATReturnBoxes.IsValid: Boolean;
begin
  Result := Length(ValidationMessages) = 0;
end;

procedure TVATReturnBoxes.FillSubmissionValues(const Values: TStrings);
var
  Settings: TFormatSettings;
begin
  Settings := TFormatSettings.Invariant;
  Values.Clear;
  Values.Add('vatDueSales=' + CurrToStr(VatDueSales, Settings));
  Values.Add('vatDueAcquisitions=' + CurrToStr(VatDueAcquisitions, Settings));
  Values.Add('totalVatDue=' + CurrToStr(TotalVatDue, Settings));
  Values.Add('vatReclaimedCurrPeriod=' + CurrToStr(VatReclaimed, Settings));
  Values.Add('netVatDue=' + CurrToStr(NetVatDue, Settings));
  Values.Add('totalValueSalesExVAT=' + TotalSalesExVat.ToString);
  Values.Add('totalValuePurchasesExVAT=' + TotalPurchasesExVat.ToString);
  Values.Add('totalValueGoodsSuppliedExVAT=' + TotalGoodsSuppliedExVat.ToString);
  Values.Add('totalAcquisitionsExVAT=' + TotalAcquisitionsExVat.ToString);
end;

function TVATReturnBoxes.PaymentText: string;
var
  Net: Currency;
begin
  Net := RoundTo(TotalVatDue - VatReclaimed, -2);
  if Net = 0 then
    Result := 'Nothing to pay or receive'
  else if Net > 0 then
    Result := 'You must pay ' + CurrToStrF(Net, ffCurrency, 2)
  else
    Result := 'You will receive ' + CurrToStrF(Abs(Net), ffCurrency, 2);
end;

end.
