unit HmrcVatSupport;

(*****************************************************************************
*                      HMRC VAT API REST Support Unit                        *
******************************************************************************
*  Support types and values for the HMRC REST / VAT Client components        *
*                                                                            *
*  created 21/12/20.    Ian H  Transfer from the RestSupport unit.           *
*  updated 03/02/21.    Ian H  Added endpoint/scope versioning.              *
*  version 1.0.1                                                             *
*                                                                            *
*  original copyright Ian Hamilton 2020/21.                                  *
*  License : GPL                                                             *
*****************************************************************************)

interface
(****************************************************************************)
uses
  System.Classes, System.SysUtils, System.Types, System.UITypes, System.Variants,
  Contnrs, IPPeerClient, REST.Types, REST.Client, REST.Authenticator.OAuth,
  System.JSON,
  HmrcRestSupport;

(****************************************************************************)
const
  csChargeRefNumber  = 'chargeRefNumber';
  csFinalised        = 'finalised';
  csFormBundleNumber = 'formBundleNumber';
  csNetVatDue        = 'netVatDue';
  csOrgsVat          = 'organisations/vat/';
  csOriginalAmount   = 'originalAmount';
  csOutstandingAmount = 'outstandingAmount';
  csPeriodKey        = 'periodKey';
  csReadVat          = 'read:vat';
  csRiteVat          = 'write:vat';
  csTotalAcquisitionsExVAT = 'totalAcquisitionsExVAT';
  csTotalValueGoodsSuppliedExVAT = 'totalValueGoodsSuppliedExVAT';
  csTotalValuePurchasesExVAT = 'totalValuePurchasesExVAT';
  csTotalValueSalesExVAT = 'totalValueSalesExVAT';
  csTotalVatDue      = 'totalVatDue';
  csUnknown          = 'unknown';
  csVatDueAcquisitions = 'vatDueAcquisitions';
  csVatDueSales      = 'vatDueSales';
  csVatNumber        = 'vatNumber';
  csVatReclaimedCurrPeriod = 'vatReclaimedCurrPeriod';

type
  (***************************************************************************
  **                     HMRC VAT Response Objects                          **
  ****************************************************************************
  **  A simple object to hold details of a liability.                       **
  ***************************************************************************)
  TVatLiability = class
  public
    XCorId      : string;
    What        : string;
    Start       : TDateTime;
    Stop        : TDateTime;
    DueBy       : TDateTime;
    Original    : currency;
    Outstanding : currency;
    constructor Create;
    procedure Clear;
  end;

  (***************************************************************************
  **  A simple object to hold details of an obligation                      **
  ***************************************************************************)
  TVatObligation = class
  public
    Periodkey : string;
    XCorId    : string;
    Status    : string;
    Start     : TDateTime;
    Stop      : TDateTime;
    DueBy     : TDateTime;
    Received  : TDateTime;
    constructor Create;
    procedure Clear;
  end;

  (***************************************************************************
  **  A simple object to hold details of a payment.                         **
  ***************************************************************************)
  TVatPayment = class
  public
    XCorId    : string;
    Amount    : currency;
    Received  : TDateTime;
    constructor Create;
    procedure Clear;
  end;

  (***************************************************************************
  **  A simple object to hold details of a tax return query.                **
  ***************************************************************************)
  TVatReturn = class
  public
    Periodkey         : string;
    XCorId            : string;
    DueOnSales        : currency;
    DueOnAcquisitions : currency;
    TotalVatDue       : currency;
    VatReclaimedCP    : currency;
    NetVatDue         : currency;
    SalesExVAT        : integer;
    PurchasesExVAT    : integer;
    GoodsExVAT        : integer;
    AcquisitionsExVAT : integer;
    constructor Create; virtual;
    procedure Clear; virtual;
    function Validates: boolean;
  end;

  (***************************************************************************
  **  Extends the base return with the extra details from submitting a vat  **
  **  return.                                                               **
  ***************************************************************************)
  TVatSubmission = class (TVatReturn)
  public
    Finalized   : boolean;
    Processed   : string;
    BundleNo    : string;
    PaymentIdct : string;
    ChargeRefNo : string;
    ReceiptId   : string;
    constructor Create; override;
    procedure Clear; override;
  end;

  (***************************************************************************
  **  A simple object to hold details of a VRN check.                       **
  ***************************************************************************)
  TVRNResponse = class
  public
    OrgName : string;
    VatNo   : string;
    Address : string;
    Postcode: string;
    Country : string;
    constructor Create;
    procedure Clear;
  end;

(*****************************************************************************
*                      RESPONSE JSON PARSING METHODS                         *
******************************************************************************
*                                                                            *
*****************************************************************************)
function ParseLiabilities(const CorId: string; aValue: TJSONValue): TObjectList;

function ParseObligations(const CorId: string; aValue: TJSONValue): TObjectList;

function ParsePayments(const CorId: string; aValue: TJSONValue): TObjectList;

function ParseReturns(const CorId: string; aValue: TJSONValue): TVatReturn;

function ParseVRNResponse(const aValue: TJSONValue): TVRNResponse;


(*****************************************************************************
*  Find version & scope by ID/name.                                          *
*****************************************************************************)
function VatEndPointVersion(const AName: string): TEndPointVersion;

function ScopeCount: integer;

function ScopeByIndex(const AValue: integer): string;

(****************************************************************************)
implementation
uses
  System.Generics.Collections;


(*****************************************************************************
*  A of current values of version & scope for SA endpoints.                  *
*  !!  Keep this up to date with API changes  !!                             *
*****************************************************************************)
const
  TVatEndPoints : array [0..2] of TEndPointVersion = (
  (ID:'VatRead'; Version:'1.0'; Scope:'read:vat'; Method:0),
  (ID:'VatWrite'; Version:'1.0'; Scope:'write:vat'; Method:1),
  (ID:'VRN'; Version:'1.0'; Scope:''; Method:0)
  );

(*****************************************************************************
*  Find version & scope by ID/name.                                          *
*****************************************************************************)
function VatEndPointVersion(const AName: string): TEndPointVersion;
var
  ix1: integer;
begin
  for ix1 := LOW(TVatEndPoints) to HIGH(TVatEndpoints) do
  begin
    if (SameText(AName, TVatEndPoints[ix1].ID)) then
    begin
      Result := TVatEndPoints[ix1];
      Break;
    end;
  end;
end;

(*****************************************************************************
*  Return number of endpoint records.                                        *
*****************************************************************************)
function ScopeCount: integer;
begin
  Result := Length(TVatEndPoints);
end;

(*****************************************************************************
*  return scope by index from endpoints.                                     *
*****************************************************************************)
function ScopeByIndex(const AValue: integer): string;
begin
  Result := TVatEndPoints[AValue].Scope;
end;


(*****************************************************************************
*                      RESPONSE JSON PARSING METHODS                         *
******************************************************************************
*  Methods to parse the json returned from the VAT API calls into lists of   *
*  objects of the appropriate types. The X-CorrelationId is in the response  *
*  header, not the body, so that must be extracted from the header and       *
*  passed in as a parameter.                                                 *
*  If the json passes the type checks and has at least one item, then a list *
*  object will be returned with one or more data objects, otherwise it will  *
*  return nil. Exception handling should be done by the calling routine.     *
******************************************************************************
*  Liabilities.                                                              *
*****************************************************************************)
function ParseLiabilities(const CorId: string; aValue: TJSONValue): TObjectList;
var
  ct1: integer;
  ix1: integer;
  obj: TVatLiability;
  lvValue : TJSONValue;
  lvArray : TJSONArray;
  lvObj   : TJSONObject;
  lvTemp: string;
begin
  Result := nil;
  // do some sanity checks
  if (Assigned(aValue)) then
  begin
    // is it a json object - all tests say yes
    if (aValue is TJSONObject) then
    begin
      // get the array bit out of the object, but still as a json value
      // we know it is called "liabilities" here
      lvValue := (aValue as TJSONObject).Values[csLiabilities];
      // check it is an array
      if (lvValue is TJSONArray) then
      begin
        // convert it to an array for convenience
        lvArray := lvValue as TJSONArray;
        ct1 := lvArray.Count;
        if (ct1 > 0) then
        begin
          // the function will return a list if there is stuff to put in it
          Result := TObjectList.Create(true);

          // loop through the array extracting the objects and processing them
          for ix1 := 0 to ct1 - 1 do
          begin
            // we need a new obligations object for the data
            obj := TVatLiability.Create;
            obj.XCorId := CorId;
            Result.Add(obj);
            // short cut as we know (expect) it is an object
            lvObj := lvArray.Items[ix1] as TJSONObject;

            If lvObj.TryGetValue<String>(csType, lvTemp) Then
              obj.What := lvTemp;
            If lvObj.TryGetValue<String>(csDue, lvTemp) Then
              obj.DueBy := HmrcDateStrToDate(lvTemp);
            If lvObj.TryGetValue<String>(csOriginalAmount, lvTemp) Then
              obj.Original := StrToFloatDef(lvTemp, 0.00);
            If lvObj.TryGetValue<String>(csOutstandingAmount, lvTemp) Then
              obj.Outstanding := StrToFloatDef(lvTemp, 0.00);

            // start and end values are in an object within the object - just unnecessary complication
            If lvObj.TryGetValue<String>(csTaxPeriod + '.' + csFrom, lvTemp) Then
              obj.Start := HmrcDateStrToDate(lvTemp);
            If lvObj.TryGetValue<String>(csTaxPeriod + '.' + csTo, lvTemp) Then
              obj.Stop := HmrcDateStrToDate(lvTemp);
          end;  // for array
        end;  // if > 0
      end;  // if an array
    end;  // if an object
  end;  // if not nil
end;


(*****************************************************************************
*  Obligations.                                                              *
*****************************************************************************)
function ParseObligations(const CorId: string; aValue: TJSONValue): TObjectList;
var
  ct1: integer;
  ix1: integer;
  obj: TVatObligation;
  lvValue : TJSONValue;
  lvArray : TJSONArray;
  lvObj   : TJSONObject;
  lvTemp: string;
begin
  Result := nil;
  // do some sanity checks
  if (Assigned(aValue)) then
  begin
    // is it a json object - all tests say yes
    if (aValue is TJSONObject) then
    begin
      // get the array bit out of the object, but still as a json value
      // we know it is called "obligations" here
      lvValue := (aValue as TJSONObject).Values[csObligations];
      // check it is an array
      if (lvValue is TJSONArray) then
      begin
        // convert it to an array for convenience
        lvArray := lvValue as TJSONArray;
        ct1 := lvArray.Count;
        if (ct1 > 0) then
        begin
          // the function will return a list if there is stuff to put in it
          Result := TObjectList.Create(true);

          // loop through the array extracting the objects and processing them
          for ix1 := 0 to ct1 - 1 do
          begin
            // we need a new obligations object for the data
            obj := TVatObligation.Create;
            obj.XCorId := CorId;
            Result.Add(obj);
            // short cut as we know (expect) it is an object
            lvObj := lvArray.Items[ix1] as TJSONObject;

            If lvObj.TryGetValue<String>(csPeriodKey, lvTemp) Then
              obj.PeriodKey := lvTemp;
            If lvObj.TryGetValue<String>(csStatus, lvTemp) Then
              obj.Status := lvTemp;
            If lvObj.TryGetValue<String>(csStart, lvTemp) Then
              obj.Start := HmrcDateStrToDate(lvTemp);
            If lvObj.TryGetValue<String>(csEnd, lvTemp) Then
              obj.Stop := HmrcDateStrToDate(lvTemp);
            If lvObj.TryGetValue<String>(csDue, lvTemp) Then
              obj.DueBy := HmrcDateStrToDate(lvTemp);
            If lvObj.TryGetValue<String>(csReceived, lvTemp) Then
              obj.Received := HmrcDateStrToDate(lvTemp);
          end;  // for array
        end;  // if > 0
      end;  // if an array
    end;  // if an object
  end;  // if not nil
end;

(*****************************************************************************
*  Payments.                                                                 *
*****************************************************************************)
function ParsePayments(const CorId: string; aValue: TJSONValue): TObjectList;
var
  ct1: integer;
  ix1: integer;
  obj: TVatPayment;
  lvValue : TJSONValue;
  lvArray : TJSONArray;
  lvObj   : TJSONObject;
  lvTemp: string;
begin
  Result := nil;
  // do some sanity checks
  if (Assigned(aValue)) then
  begin
    // is it a json object - all tests say yes
    if (aValue is TJSONObject) then
    begin
      // get the array bit out of the object, but still as a json value
      // we know it is called "payments" here
      lvValue := (aValue as TJSONObject).Values[csPayments];
      // check it is an array
      if (lvValue is TJSONArray) then
      begin
        // convert it to an array for convenience
        lvArray := lvValue as TJSONArray;
        ct1 := lvArray.Count;
        if (ct1 > 0) then
        begin
          // the function will return a list if there is stuff to put in it
          Result := TObjectList.Create(true);

          // loop through the array extracting the objects and processing them
          for ix1 := 0 to ct1 - 1 do
          begin
            // we need a new obligations object for the data
            obj := TVatPayment.Create;
            obj.XCorId := CorId;
            Result.Add(obj);
            // short cut as we know (expect) it is an object
            lvObj := lvArray.Items[ix1] as TJSONObject;

            If lvObj.TryGetValue<String>(csAmount, lvTemp) Then
              obj.Amount := StrToFloatDef(lvTemp, 0.00);
            If lvObj.TryGetValue<String>(csReceived, lvTemp) Then
              obj.Received := HmrcDateStrToDate(lvTemp);
          end;  // for array
        end;  // if > 0
      end;  // if an array
    end;  // if an object
  end;  // if not nil
end;

(*****************************************************************************
*  Check Returns.                                                            *
*****************************************************************************)
function ParseReturns(const CorId: string; aValue: TJSONValue): TVatReturn;
var
  obj: TVatReturn;
  lvObj : TJSONObject;
  lvTemp: string;
begin
  Result := nil;
  // do some sanity checks
  if (Assigned(aValue)) then
  begin
    // is it a json object - it should be
    if (aValue is TJSONObject) then
    begin
      // cast to the local object for convenience
      lvObj := aValue as TJSONObject;
      obj := TVatReturn.Create;
      obj.XCorId := CorId;

      If lvObj.TryGetValue<String>(csPeriodKey, lvTemp) Then
        obj.PeriodKey := lvTemp;
      If lvObj.TryGetValue<String>(csVatDueSales, lvTemp) Then
        obj.DueOnSales := StrToFloatDef(lvTemp, 0.00);
      If lvObj.TryGetValue<String>(csVatDueAcquisitions, lvTemp) Then
        obj.DueOnAcquisitions := StrToFloatDef(lvTemp, 0.00);
      If lvObj.TryGetValue<String>(cstotalVatDue, lvTemp) Then
        obj.TotalVatDue := StrToFloatDef(lvTemp, 0.00);
      If lvObj.TryGetValue<String>(csVatReclaimedCurrPeriod, lvTemp) Then
        obj.VatReclaimedCP := StrToFloatDef(lvTemp, 0.00);
      If lvObj.TryGetValue<String>(csNetVatDue, lvTemp) Then
        obj.NetVatDue := StrToFloatDef(lvTemp, 0.00);

      If lvObj.TryGetValue<String>(csTotalValueSalesExVAT, lvTemp) Then
        obj.SalesExVAT := StrToIntDef(lvTemp, 0);
      If lvObj.TryGetValue<String>(csTotalValuePurchasesExVAT, lvTemp) Then
        obj.PurchasesExVAT := StrToIntDef(lvTemp, 0);
      If lvObj.TryGetValue<String>(csTotalValueGoodsSuppliedExVAT, lvTemp) Then
        obj.GoodsExVAT := StrToIntDef(lvTemp, 0);
      If lvObj.TryGetValue<String>(csTotalAcquisitionsExVAT, lvTemp) Then
        obj.AcquisitionsExVAT := StrToIntDef(lvTemp, 0);

      Result := obj;
    end;  // if an object
  end;  // if not nil
end;


(*****************************************************************************
*  Parse VRN check response json into a VRNResponse object.                  *
*  The json should be an outer JSON object containing a json object called   *
*  target and another called requester. This process will extract the target *
*  details into the return object.                                           *
*****************************************************************************)
function ParseVRNResponse(const aValue: TJSONValue): TVRNResponse;
var
  obj: TVRNResponse;
  lvObj : TJSONObject;
  lvValue : TJSONValue;
  lvTemp: string;
begin
  Result := nil;
  // do some sanity checks
  if (Assigned(aValue)) then
  begin
    // is it a json object - it should be
    if (aValue is TJSONObject) then
    begin
      // get the data bit out of the object, but still as a json value
      // we know it is called "target" here
      lvValue := (aValue as TJSONObject).Values[csTarget];
      // check it is an array
      if (lvValue is TJSONObject) then
      begin
        // cast to the local object for convenience
        lvObj := lvValue as TJSONObject;
        // create return object
        obj := TVRNResponse.Create;

        If lvObj.TryGetValue<String>(csName, lvTemp) Then
          obj.OrgName := lvTemp;
        If lvObj.TryGetValue<String>(csVatNumber, lvTemp) Then
          obj.VatNo := lvTemp;
        If lvObj.TryGetValue<String>(csAddress + '.' + csLine1, lvTemp) Then
          obj.Address := lvTemp;
        If lvObj.TryGetValue<String>(csAddress + '.' + csPostcode, lvTemp) Then
          obj.Postcode := lvTemp;
        If lvObj.TryGetValue<String>(csAddress + '.' + csCountryCode, lvTemp) Then
          obj.Country := lvTemp;

         Result := obj;
      end;  // if target
    end;  // if an object
  end;  // if not nil
end;



(*****************************************************************************
*                       HMRC VAT RESPONSE DATA TYPES                         *
******************************************************************************
*                                                                            *
{ TVatLiability }
*                                                                            *
(*****************************************************************************
*                              TVatLiability                                 *
******************************************************************************
*  Init                                                                      *
*****************************************************************************)
Constructor TVatLiability.Create;
begin
  Clear;
end;

(*****************************************************************************
*  clear to defaults.                                                        *
*****************************************************************************)
procedure TVatLiability.Clear;
begin
  XCorId      := '';
  What        := '';
  Start       := 0;
  Stop        := 0;
  DueBy       := 0;
  Original    := 0.00;
  Outstanding := 0.00;
end;



{ TVatObligation }

(*****************************************************************************
*                              TVatObligation                                *
******************************************************************************
*  Init                                                                      *
*****************************************************************************)
constructor TVatObligation.Create;
begin
  Clear;
end;

(*****************************************************************************
*  clear to defaults.                                                        *
*****************************************************************************)
procedure TVatObligation.Clear;
begin
  Periodkey := '';
  XCorId    := '';
  Status    := '';
  Start     := 0;
  Stop      := 0;
  DueBy     := 0;
  Received  := 0;
end;



{ TVatPayment }

(*****************************************************************************
*                               TVatPayment                                  *
******************************************************************************
*  Init                                                                      *
*****************************************************************************)
constructor TVatPayment.Create;
begin
  Clear;
end;

(*****************************************************************************
*  clear to defaults.                                                        *
*****************************************************************************)
procedure TVatPayment.Clear;
begin
  XCorId   := '';
  Amount   := 0.00;
  Received := 0;
end;



{ TVatReturn }

(*****************************************************************************
*                                TVatReturn                                  *
******************************************************************************
*  Init                                                                      *
*****************************************************************************)
constructor TVatReturn.Create;
begin
  Clear;
end;

(*****************************************************************************
*  clear to defaults.                                                        *
*****************************************************************************)
procedure TVatReturn.Clear;
begin
  Periodkey         := '';
  XCorId            := '';
  DueOnSales        := 0.00;
  DueOnAcquisitions := 0.00;
  TotalVatDue       := 0.00;
  VatReclaimedCP    := 0.00;
  NetVatDue         := 0.00;
  SalesExVAT        := 0;
  PurchasesExVAT    := 0;
  GoodsExVAT        := 0;
  AcquisitionsExVAT := 0;
end;

(*****************************************************************************
*  check values are set and sensible. Should it be second-guessing an        *
*  accounting system here?                                                   *
*****************************************************************************)
function TVatReturn.Validates: boolean;
begin
  Result := true;
  if (PeriodKey = '') then
    Result := false
  else if NetVatDue < 0 then
    Result := false;
end;



{ TVatSubmission }

(*****************************************************************************
*                              TVatSubmission                                *
******************************************************************************
*  Init                                                                      *
*****************************************************************************)
constructor TVatSubmission.Create;
begin
  inherited;

  Clear;
end;

(*****************************************************************************
*  clear to defaults.                                                        *
*****************************************************************************)
procedure TVatSubmission.Clear;
begin
  inherited;

  Finalized   := false;
  Processed   := '';
  BundleNo    := '';
  PaymentIdct := '';
  ChargeRefNo := '';
  ReceiptId   := '';
end;


{ TVRNResponse }

(*****************************************************************************
*                              TVRNResponse                                  *
******************************************************************************
*  Init                                                                      *
*****************************************************************************)
constructor TVRNResponse.Create;
begin
  Clear;
end;

(*****************************************************************************
*  init/reset to defaults.                                                   *
*****************************************************************************)
procedure TVRNResponse.Clear;
begin
  OrgName := '';
  VatNo   := '';
  Address := '';
  Postcode:= '';
  Country := '';
end;

end.
