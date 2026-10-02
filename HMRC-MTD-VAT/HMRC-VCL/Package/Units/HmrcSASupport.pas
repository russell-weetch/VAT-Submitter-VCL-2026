unit HmrcSASupport;

(*****************************************************************************
*                        HMRC SA API REST Support Unit                       *
******************************************************************************
*  Support types and values for the HMRC SA REST Client components           *
*                                                                            *
*  created 28/12/20.                                                         *
*  updated 05/02/21.                                                         *
*                                                                            *
*  version 1.0.0      released 05/02/21  initial release for beta apis       *
*                                                                            *
*  original copyright Ian Hamilton 2020/21.                                  *
*****************************************************************************)

interface
(****************************************************************************)
uses
  System.Classes, System.SysUtils, System.Types, System.UITypes, System.Variants,
  System.JSON, System.Generics.Collections,
  HmrcRestSupport;


(****************************************************************************)

const
  csAcmPBE      = 'accommodationProvidedByEmployer';
  csBenefits    = 'Benefits';
  csCCVBens     = 'companyCarsAndVansBenefit';
  csClass1      = 'class1';
  csClass2      = 'class2';
  csDeceased    = 'deceased';
  csEligibility = 'eligibility';
  csEligible    = 'eligible';
  csEmployment  = 'Employment';
  csEmployments = 'employments';
  csEmpName     = 'employerName';
  csEmpPayeRef  = 'employerPayeReference';
  csExpPayRcd   = 'expensesPaymentsReceived';
  csFuelBens    = 'fuelForCompanyCarsAndvansBenefit';
  csGoodsPBE    = 'goodsEtcProvidedByEmployer';
  csIncBen      = 'incapacityBenefit';
  csIncome      = 'Income';
  csJobSA       = 'jobseekersAllowance';
  csMAEligible  = 'MAEligible';
  csMAStatus    = 'MAStatus';
  csMaxNICs     = 'maxNICsReached';
  csNI          = 'NI';
  csOPWFlag     = 'offPayrollWorkFlag';
  csOtherBens   = 'otherBenefits';
  csOtherPRA    = 'otherPensionsAndRetirementAnnuities';
  csPayFromEmp  = 'payFromEmployment';
  csPayeRef     = 'employerPayeReference';
  csPensAOSB    = 'pensionsAnnuitiesAndOtherStateBenefits';
  csPMDIns      = 'privateMedicalDentalInsurance';
  csReadBen     = 'read:individual-benefits';
  csReadEmp     = 'read:individual-employment';
  csReadIcm     = 'read:individual-income';
  csReadMA      = 'read:marriage-allowance';
  csReadNIC     = 'read:national-insurance';
  csReadTax     = 'read:individual-tax';
  csRefunds     = 'refunds';
  csRscBens     = 'individual-benefits/sa/';
  csRscEmp      = 'individual-employment/sa/';
  csRscIcm      = 'individual-income/sa/';
  csRscMA       = 'marriage-allowance/sa/';
  csRscNI       = 'national-insurance/sa/';
  csRscTax      = 'individual-tax/sa/';
  csSeissNP     = 'self-employment income support scheme';
  csSfxAnSum    = 'annual-summary/';
  csStatus      = 'status';
  csTax         = 'Tax';
  csTaxYear     = 'taxYear';
  csTaxrefund   = 'taxRefundedOrSetOff';
  csTotalDue    = 'totalDue';
  csTotalNIC    = 'totalNICableEarnings';
  csVCCEMA      = 'vouchersCreditCardsExcessMileageAllowance';


type
  (***************************************************************************
  **                      HMRC SA Response Objects                          **
  ****************************************************************************
  **  A simple object to hold details of a liability.                       **
  ***************************************************************************)
  TSABenefits = class
  public
    PayeRef   : string;   // required      // employerPayeReference
    CCVBens   : integer;  // optional      // companyCarsAndVansBenefit
    FuelBens  : integer;  // optional      // fuelForCompanyCarsAndvansBenefit
    PMDIns    : integer;  // optional      // privateMedicalDentalInsurance
    VCCEMA    : integer;  // optional      // vouchersCreditCardsExcessMileageAllowance
    GoodsPBE  : integer;  // optional      // goodsEtcProvidedByEmployer
    AcmPBE    : integer;  // optional      // accommodationProvidedByEmployer
    OtherBens : integer;  // optional      // otherBenefits
    ExpPayRcd : integer;  // optional      // expensesPaymentsReceived
    constructor Create;
    procedure Clear;
  end;

  (***************************************************************************
  **  A simple object to hold details of an employment                      **
  ***************************************************************************)
  TSAEmployment = class
  public
    PayeRef : string;   // required       // employerPayeReference
    EmpName : string;   // required       // employerName
    OPWFlag : boolean;  // optional       // offPayrollWorkFlag
    constructor Create;
    procedure Clear;
  end;

  (***************************************************************************
  **  A simple object to hold details of an employment income               **
  ***************************************************************************)
  TSAIncome = class
  public
    PayeRef : string;  // required    // employerPayeReference
    Pay     : double;  // required    // payFromEmployment
    constructor Create;
    procedure Clear;
  end;

  (***************************************************************************
  **  A simple object to hold details of a marriage allowance               **
  ***************************************************************************)
  TSAMrgAllowance = class
  public
    UTR       : string;
    TaxYear   : string;  // YYYY-YY        // taxYear
    Nino      : string;                    // nino
    Firstname : string;  // max len 35     // firstname
    Surname   : string;  // max len 35     // surname
    DOB       : string;  // YYYY-MM-DD     // dateOfBirth
    Status    : string;  // [Transferor, Recipient, None]
    Eligible  : boolean;                   // elligible
    Deceased  : boolean;                   // deceased
    constructor Create;
    function  BuildRequest: string;   // build json string for eligibility request
    procedure Clear;
  end;

  (***************************************************************************
  **  A simple object to hold details of a National Insurance record        **
  ***************************************************************************)
  TSANI = class
  public
    UTR     : string;
    TaxYear : string;
    Class1  : double;            // totalNICableEarnings
    Class2  : double;            // totalDue
    MaxNICs : boolean;           // maxNICsReached
    constructor Create;
    procedure Clear;
  end;

  (***************************************************************************
  **  A simple object to hold details of a state benefits record            **
  ***************************************************************************)
  TSAStateBens = class
  public
    OPRA : double;  // optional   // otherPensionsAndRetirementAnnuities  // pensions other than state pension
    IBen : double;  // optional   // incapacityBenefit
    JSA  : double;  // optional   // jobseekersAllowance
    SNP  : double;  // optional   // seissNetPaid   // self-employment income support scheme
    constructor Create;
    procedure Clear;
  end;

  (***************************************************************************
  *                    Multi-class SA Response Objects                       *
  ****************************************************************************
  **  An object to hold a list of employment benefit details.               **
  ***************************************************************************)
  TSABenefitsList = class
  public
    UTR      : string;
    TaxYear  : string;
    Benefits : TObjectList<TSABenefits>;  // required    // list of employment benefits
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;

  (***************************************************************************
  **  An object to hold a list of employments details.                      **
  ***************************************************************************)
  TSAEmploymentsList = class
  public
    UTR     : string;
    TaxYear : string;
    Employments : TObjectList<TSAEmployment>;  // required    // list of employment history
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;

  (***************************************************************************
  **  An object to hold benefit details and a list of an employment income  **
  ***************************************************************************)
  TSAIncomes = class
  public
    UTR      : string;
    TaxYear  : string;
    Benefits : TSAStateBens;            // required    // benefits received
    PayList  : TObjectList<TSAIncome>;  // required    // list of employment pay
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;

  (***************************************************************************
  **  An object to hold benefit details and a list of an employment income  **
  ***************************************************************************)
  TSAIndividualTax = class
  public
    UTR       : string;
    TaxYear   : string;
    TaxRefund : double;                  // required    // taxRefundedOrSetOff
    Benefits  : TSAStateBens;            // required    // benefits received
    PayList   : TObjectList<TSAIncome>;  // required    // list of employment pay
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;


(*****************************************************************************
*                      RESPONSE JSON PARSING METHODS                         *
******************************************************************************
*  Methods to parse the json returned from the SA API calls into objects or  *
*  lists of objects of the appropriate types.                                *
*  If the json passes the type checks and has at least one item, then an     *
*  object will be returned with one or more data objects, otherwise it will  *
*  return nil. Exception handling should be done by the calling routine.     *
*****************************************************************************)
function ParseIncomes(aValue: TJSONValue): TSAIncomes;

function ParseIndividualTax(aValue: TJSONValue): TSAIndividualTax;

function ParseMrgAllowance(const aValue: TJSONValue; var AStatus: string): boolean;

function ParseMrgEligibility(const aValue: TJSONValue): boolean;

function ParseNI(const aValue: TJSONValue): TSANI;

function ParseSABenefits(aValue: TJSONValue): TSABenefitsList;

function ParseSAEmployments(aValue: TJSONValue): TSAEmploymentsList;


(*****************************************************************************
*  Get version & scope for SA endpoint by name.                              *
*****************************************************************************)
function SAEndPointVersion(const AName: string): TEndPointVersion;


(****************************************************************************)
implementation
(****************************************************************************)
//uses

(*****************************************************************************
*  A of current values of version & scope for SA endpoints.                  *
*  !!  Keep this up to date with API changes  !!                             *
*****************************************************************************)
const
  TSAEndPoints : array [0..6] of TEndPointVersion = (
  (ID:csBenefits; Version:'1.1'; Scope:csReadBen; Method:REST_GET),
  (ID:csEmployment; Version:'1.2'; Scope:csReadEmp; Method:REST_GET),
  (ID:csIncome; Version:'1.2'; Scope:csReadIcm; Method:REST_GET),
  (ID:csTax; Version:'1.1'; Scope:csReadTax; Method:REST_GET),
  (ID:csMAStatus; Version:'2.0'; Scope:csReadMA; Method:REST_GET),
  (ID:csMAEligible; Version:'2.0'; Scope:csReadMA; Method:REST_POST),
  (ID:csNI; Version:'1.1'; Scope:csReadNIC; Method:REST_GET)
  );

(*****************************************************************************
*  Find version & scope by ID/name.                                          *
*****************************************************************************)
function SAEndPointVersion(const AName: string): TEndPointVersion;
var
  ix1: integer;
begin
  for ix1 := LOW(TSAEndPoints) to HIGH(TSAEndpoints) do
  begin
    if (SameText(AName, TSAEndPoints[ix1].ID)) then
    begin
      Result := TSAEndPoints[ix1];
      Break;
    end;
  end;
end;


(*****************************************************************************
*                      RESPONSE JSON PARSING METHODS                         *
******************************************************************************
*  Return an incomes object from the endpoint.                               *
*****************************************************************************)
function ParseIncomes(aValue: TJSONValue): TSAIncomes;
var
  ct1: integer;
  ix1: integer;
  obj: TSAIncome;
  lvValue : TJSONValue;
  lvArray : TJSONArray;
  lvObj   : TJSONObject;
  lvTemp: string;
  lvFloat: double;
begin
  Result := nil;
  // do some sanity checks
  if (Assigned(aValue)) then
  begin
    // is it a json object - the docs say yes
    if (aValue is TJSONObject) then
    begin
      Result := TSAIncomes.Create;
      // get the benefits object bit out of the object, but still as a json value
      // we know it is called "pensionsAnnuitiesAndOtherStateBenefits" here
      lvValue := (aValue as TJSONObject).Values[csPensAOSB];
      if (lvValue is TJSONObject) then
      begin
        lvObj := lvValue as TJSONObject;

        if lvObj.TryGetValue<double>(csOtherPRA, lvFloat) then
          Result.Benefits.OPRA := lvFloat;
        if lvObj.TryGetValue<double>(csIncBen, lvFloat) then
          Result.Benefits.IBen := lvFloat;
        if lvObj.TryGetValue<double>(csJobSA, lvFloat) then
          Result.Benefits.JSA := lvFloat;
        if lvObj.TryGetValue<double>(csSeissNP, lvFloat) then
          Result.Benefits.SNP := lvFloat;
      end;  // if object

      // get the array bit out of the object, but still as a json value
      // we know it is called "employments" here
      lvValue := (aValue as TJSONObject).Values[csEmployments];
      // check it is an array
      if (lvValue is TJSONArray) then
      begin
        // convert it to an array for convenience
        lvArray := lvValue as TJSONArray;
        ct1 := lvArray.Count;
        if (ct1 > 0) then
        begin
          // loop through the array extracting the objects and processing them
          for ix1 := 0 to ct1 - 1 do
          begin
            // we need a new obligations object for the data
            obj := TSAIncome.Create;
            Result.PayList.Add(obj);
            // short cut as we know (expect) it is an object
            lvObj := lvArray.Items[ix1] as TJSONObject;

            If lvObj.TryGetValue<String>(csEmpPayeRef, lvTemp) Then
              obj.PayeRef := lvTemp;
            If lvObj.TryGetValue<double>(csPayFromEmp, lvFloat) Then
              obj.Pay := lvFloat;
          end;  // for array
        end;  // if > 0
      end;  // if an array
    end;  // if an object
  end;  // if not nil
end;

(*****************************************************************************
*  Return an individual tax object from the endpoint.                        *
*****************************************************************************)
function ParseIndividualTax(aValue: TJSONValue): TSAIndividualTax;
var
  ct1: integer;
  ix1: integer;
  obj: TSAIncome;
  lvValue : TJSONValue;
  lvArray : TJSONArray;
  lvObj   : TJSONObject;
  lvTemp: string;
  lvFloat: double;
begin
  Result := nil;
  // do some sanity checks
  if (Assigned(aValue)) then
  begin
    // is it a json object - the docs say yes
    if (aValue is TJSONObject) then
    begin
      Result := TSAIndividualTax.Create;
      // get the tax refund - another object witrh one property - refunds.taxRefundedOrSetOff
      If (aValue as TJSONObject).TryGetValue<double>(csRefunds + '.' + csTaxRefund, lvFloat) Then
        Result.TaxRefund:= lvFloat;
      // get the benefits object bit out of the object, but still as a json value
      // we know it is called "pensionsAnnuitiesAndOtherStateBenefits" here
      lvValue := (aValue as TJSONObject).Values[csPensAOSB];
      if (lvValue is TJSONObject) then
      begin
        lvObj := lvValue as TJSONObject;

        if lvObj.TryGetValue<double>(csOtherPRA, lvFloat) then
          Result.Benefits.OPRA := lvFloat;
        if lvObj.TryGetValue<double>(csIncBen, lvFloat) then
          Result.Benefits.IBen := lvFloat;
        //if lvObj.TryGetValue<double>(csJobSA, lvFloat) then
        //  Result.Benefits.JSA := lvFloat;
        //if lvObj.TryGetValue<double>(csSeissNP, lvFloat) then
        //  Result.Benefits.SNP := lvFloat;
      end;  // if object

      // get the array bit out of the object, but still as a json value
      // we know it is called "employments" here
      lvValue := (aValue as TJSONObject).Values[csEmployments];
      // check it is an array
      if (lvValue is TJSONArray) then
      begin
        // convert it to an array for convenience
        lvArray := lvValue as TJSONArray;
        ct1 := lvArray.Count;
        if (ct1 > 0) then
        begin
          // loop through the array extracting the objects and processing them
          for ix1 := 0 to ct1 - 1 do
          begin
            // we need a new obligations object for the data
            obj := TSAIncome.Create;
            Result.PayList.Add(obj);
            // short cut as we know (expect) it is an object
            lvObj := lvArray.Items[ix1] as TJSONObject;

            If lvObj.TryGetValue<String>(csEmpPayeRef, lvTemp) Then
              obj.PayeRef := lvTemp;
            If lvObj.TryGetValue<double>(csPayFromEmp, lvFloat) Then
              obj.Pay := lvFloat;
          end;  // for array
        end;  // if > 0
      end;  // if an array
    end;  // if an object
  end;  // if not nil
end;

(*****************************************************************************
*  Return a marriage allowance status from the endpoint.                     *
*****************************************************************************)
function ParseMrgAllowance(const aValue: TJSONValue; var AStatus: string): boolean;
var
  lvObj: TJSONObject;
  lvBool: boolean;
  lvTemp: string;
begin
  Result := false;
  AStatus := '';
  // do some sanity checks
  if (Assigned(aValue)) then
  begin
    // is it a json object
    if (aValue is TJSONObject) then
    begin
      lvObj := aValue as TJSONObject;

      if lvObj.TryGetValue<string>(csStatus, lvTemp) then
        AStatus := lvTemp;
      if lvObj.TryGetValue<boolean>(csDeceased, lvBool) then
        Result := lvBool;
    end;
  end;
end;

(*****************************************************************************
*  Return a marriage allowance eligibility state from the endpoint.          *
*****************************************************************************)
function ParseMrgEligibility(const aValue: TJSONValue): boolean;
var
  lvBool: boolean;
begin
  Result := false;
  // do some sanity checks
  if (Assigned(aValue)) then
  begin
    // is it a json object
    if (aValue is TJSONObject) then
    begin
      if TJSONObject(aValue).TryGetValue<Boolean>(csEligible, lvBool) then
      begin
        Result := lvBool;
      end;
    end;
  end;
end;

(*****************************************************************************
*  Return a National Insurance statement from the endpoint.                  *
*****************************************************************************)
function ParseNI(const aValue: TJSONValue): TSANI;
var
  lvObj: TJSONObject;
  lvBool: boolean;
  lvNumber: double;
begin
  Result := nil;
  // do some sanity checks
  if (Assigned(aValue)) then
  begin
    // is it a json object
    if (aValue is TJSONObject) then
    begin
      lvObj := aValue as TJSONObject;
      Result := TSANI.Create;

      if lvObj.TryGetValue<double>(csClass1 + '.' + csTotalNIC, lvNumber) then
        Result.Class1 := lvNumber;
      if lvObj.TryGetValue<double>(csClass2 + '.' + csTotalDue, lvNumber) then
        Result.Class2 := lvNumber;
      if lvObj.TryGetValue<boolean>(csMaxNICs, lvBool) then
        Result.MaxNICs := lvBool;
    end;
  end;
end;

(*****************************************************************************
*  Return a list of employment benefits from the endpoint.                   *
*****************************************************************************)
function ParseSABenefits(aValue: TJSONValue): TSABenefitsList;
var
  ct1: integer;
  ix1: integer;
  obj: TSABenefits;
  lvValue : TJSONValue;
  lvArray : TJSONArray;
  lvObj   : TJSONObject;
  lvTemp: string;
  lvInt: integer;
begin
  Result := nil;
  // do some sanity checks
  if (Assigned(aValue)) then
  begin
    // is it a json object - all tests say yes
    if (aValue is TJSONObject) then
    begin
      // get the array bit out of the object, but still as a json value
      // we know it is called "employments" here
      lvValue := (aValue as TJSONObject).Values[csEmployments];
      // check it is an array
      if (lvValue is TJSONArray) then
      begin
        // convert it to an array for convenience
        lvArray := lvValue as TJSONArray;
        ct1 := lvArray.Count;
        if (ct1 > 0) then
        begin
          // the function will return a list if there is stuff to put in it
          Result := TSABenefitsList.Create;

          // loop through the array extracting the objects and processing them
          for ix1 := 0 to ct1 - 1 do
          begin
            // we need a new obligations object for the data
            obj := TSABenefits.Create;
            Result.Benefits.Add(obj);
            // short cut as we know (expect) it is an object
            lvObj := lvArray.Items[ix1] as TJSONObject;

            If lvObj.TryGetValue<String>(csEmpPayeRef, lvTemp) Then
              obj.PayeRef := lvTemp;
            If lvObj.TryGetValue<integer>(csCCVBens, lvInt) Then
              obj.CCVBens := lvInt;
            If lvObj.TryGetValue<integer>(csFuelBens, lvInt) Then
              obj.FuelBens := lvInt;
            If lvObj.TryGetValue<integer>(csPMDIns, lvInt) Then
              obj.PMDIns := lvInt;
            If lvObj.TryGetValue<integer>(csVCCEMA, lvInt) Then
              obj.VCCEMA := lvInt;
            If lvObj.TryGetValue<integer>(csGoodsPBE, lvInt) Then
              obj.GoodsPBE := lvInt;
            If lvObj.TryGetValue<integer>(csAcmPBE, lvInt) Then
              obj.AcmPBE := lvInt;
            If lvObj.TryGetValue<integer>(csOtherBens, lvInt) Then
              obj.OtherBens := lvInt;
            If lvObj.TryGetValue<integer>(csExpPayRcd, lvInt) Then
              obj.ExpPayRcd := lvInt;
          end;  // for array
        end;  // if > 0
      end;  // if an array
    end;  // if an object
  end;  // if not nil
end;

(*****************************************************************************
*  Return a list of employment histories from the endpoint.                  *
*****************************************************************************)
function ParseSAEmployments(aValue: TJSONValue): TSAEmploymentsList;
var
  ct1: integer;
  ix1: integer;
  obj: TSAEmployment;
  lvValue : TJSONValue;
  lvArray : TJSONArray;
  lvObj   : TJSONObject;
  lvTemp: string;
  lvBool: boolean;
begin
  Result := nil;
  // do some sanity checks
  if (Assigned(aValue)) then
  begin
    // is it a json object - all tests say yes
    if (aValue is TJSONObject) then
    begin
      // get the array bit out of the object, but still as a json value
      // we know it is called "employments" here
      lvValue := (aValue as TJSONObject).Values[csEmployments];
      // check it is an array
      if (lvValue is TJSONArray) then
      begin
        // convert it to an array for convenience
        lvArray := lvValue as TJSONArray;
        ct1 := lvArray.Count;
        if (ct1 > 0) then
        begin
          // the function will return a list if there is stuff to put in it
          Result := TSAEmploymentsList.Create;

          // loop through the array extracting the objects and processing them
          for ix1 := 0 to ct1 - 1 do
          begin
            // we need a new obligations object for the data
            obj := TSAEmployment.Create;
            Result.Employments.Add(obj);
            // short cut as we know (expect) it is an object
            lvObj := lvArray.Items[ix1] as TJSONObject;

            If lvObj.TryGetValue<String>(csEmpPayeRef, lvTemp) Then
              obj.PayeRef := lvTemp;
            If lvObj.TryGetValue<String>(csEmpName, lvTemp) Then
              obj.EmpName := lvTemp;
            If lvObj.TryGetValue<boolean>(csOPWFlag, lvBool) Then
              obj.OPWFlag := lvBool;
          end;  // for array
        end;  // if > 0
      end;  // if an array
    end;  // if an object
  end;  // if not nil
end;




(*****************************************************************************
*                           DATA CLASSES SECTION                             *
*****************************************************************************)
{ TSABenefits }
(*****************************************************************************
*                                TSABenefits                                 *
******************************************************************************
*  Init                                                                      *
*****************************************************************************)
constructor TSABenefits.Create;
begin
  Clear;
end;

(*****************************************************************************
*  clear to defaults.                                                        *
*****************************************************************************)
procedure TSABenefits.Clear;
begin
  PayeRef   := '';
  CCVBens   := 0;
  FuelBens  := 0;
  PMDIns    := 0;
  VCCEMA    := 0;
  GoodsPBE  := 0;
  AcmPBE    := 0;
  OtherBens := 0;
  ExpPayRcd := 0;
end;

{ TSAEmployments }

(*****************************************************************************
*                              TSAEmployments                                *
******************************************************************************
*  Init                                                                      *
*****************************************************************************)
constructor TSAEmployment.Create;
begin
  Clear;
end;

(*****************************************************************************
*  clear to defaults.                                                        *
*****************************************************************************)
procedure TSAEmployment.Clear;
begin
  PayeRef := '';
  EmpName := '';
  OPWFlag := false;
end;

{ TSAIncomeTax }

(*****************************************************************************
*                                TSAIncomeTax                                *
******************************************************************************
*  Init                                                                      *
*****************************************************************************)
constructor TSAIncome.Create;
begin
  Clear;
end;

(*****************************************************************************
*  clear to defaults.                                                        *
*****************************************************************************)
procedure TSAIncome.Clear;
begin
  PayeRef := '';
  Pay     := 0.00;
end;

{ TSAMrgAllowance }

(*****************************************************************************
*                              TSAMrgAllowance                               *
******************************************************************************
*  Init                                                                      *
*****************************************************************************)
constructor TSAMrgAllowance.Create;
begin
  Clear;
end;

(*****************************************************************************
*  build json string/object for eligibility request.                          *
*****************************************************************************)
function TSAMrgAllowance.BuildRequest: string;
begin
  Result := '{' +
  '"nino": "' + Nino + '", ' +
  '"firstname": "' + Firstname + '", ' +
  '"surname": "' + Surname + '", ' +
  '"dateOfBirth": "' + DOB + '", ' +
  '"taxYear": "' + TaxYear + '"}' ;
end;

(*****************************************************************************
*  clear to defaults.                                                        *
*****************************************************************************)
procedure TSAMrgAllowance.Clear;
begin
  UTR       := '';
  TaxYear   := '';
  Nino      := '';
  Firstname := '';
  Surname   := '';
  DOB       := '';
  TaxYear   := '';
  Status    := 'None';
  Eligible  := false;
  Deceased  := false;
end;

{ TSANI }

(*****************************************************************************
*                                   TSANI                                    *
******************************************************************************
*  Init                                                                      *
*****************************************************************************)
constructor TSANI.Create;
begin
  Clear;
end;

(*****************************************************************************
*  clear to defaults.                                                        *
*****************************************************************************)
procedure TSANI.Clear;
begin
  UTR     := '';
  TaxYear := '';
  Class1  := 0.00;
  Class2  := 0.00;
  MaxNICs := false;
end;

{ TSAStateBens }

(*****************************************************************************
*                                TSAStateBens                                *
******************************************************************************
*  Init                                                                      *
*****************************************************************************)
constructor TSAStateBens.Create;
begin
  Clear;
end;

(*****************************************************************************
*  clear to defaults.                                                        *
*****************************************************************************)
procedure TSAStateBens.Clear;
begin
  OPRA := 0.00;
  IBen := 0.00;
  JSA  := 0.00;
  SNP  := 0.00;
end;



{ TSABenefitsList }

(*****************************************************************************
*                              TSABenefitsList                               *
******************************************************************************
*  Init                                                                      *
*****************************************************************************)
constructor TSABenefitsList.Create;
begin
  UTR     := '';
  TaxYear := '';
  Benefits := TObjectList<TSABenefits>.Create(true);
end;

(*****************************************************************************
*  clean up.                                                                 *
*****************************************************************************)
destructor TSABenefitsList.Destroy;
begin
  Benefits.Free;

  inherited;
end;

(*****************************************************************************
*  clear to defaults.                                                        *
*****************************************************************************)
procedure TSABenefitsList.Clear;
begin
  UTR     := '';
  TaxYear := '';
  Benefits.Clear;
end;


{ TSAEmploymentsList }

(*****************************************************************************
*                           TSAEmploymentsList                               *
******************************************************************************
*  Init                                                                      *
*****************************************************************************)
constructor TSAEmploymentsList.Create;
begin
  UTR     := '';
  TaxYear := '';
  Employments := TObjectList<TSAEmployment>.Create(true);
end;

(*****************************************************************************
*  clean up.                                                                 *
*****************************************************************************)
destructor TSAEmploymentsList.Destroy;
begin
  Employments.Free;

  inherited;
end;

(*****************************************************************************
*  clear to defaults.                                                        *
*****************************************************************************)
procedure TSAEmploymentsList.Clear;
begin
  UTR     := '';
  TaxYear := '';
  Employments.Clear;
end;


{ TSAIncomes }

(*****************************************************************************
*                                TSAIncomes                                  *
******************************************************************************
*  Init                                                                      *
*****************************************************************************)
constructor TSAIncomes.Create;
begin
  UTR     := '';
  TaxYear := '';
  Benefits := TSAStateBens.Create;
  PayList  := TObjectList<TSAIncome>.Create(true);
end;

(*****************************************************************************
*  clean up.                                                                 *
*****************************************************************************)
destructor TSAIncomes.Destroy;
begin
  PayList.Free;
  Benefits.Free;

  inherited;
end;

(*****************************************************************************
*  clear to defaults.                                                        *
*****************************************************************************)
procedure TSAIncomes.Clear;
begin
  UTR     := '';
  TaxYear := '';
  Benefits.Clear;
  PayList.Clear;
end;

{ TSAIndividualTax }

(*****************************************************************************
*                             TSAIndividualTax                               *
******************************************************************************
*  Init                                                                      *
*****************************************************************************)
constructor TSAIndividualTax.Create;
begin
  UTR       := '';
  TaxYear   := '';
  TaxRefund := 0.00;
  Benefits  := TSAStateBens.Create;
  PayList   := TObjectList<TSAIncome>.Create(true);
end;

(*****************************************************************************
*  clean up.                                                                 *
*****************************************************************************)
destructor TSAIndividualTax.Destroy;
begin
  PayList.Free;
  Benefits.Free;

  inherited;
end;

(*****************************************************************************
*  clear to defaults.                                                        *
*****************************************************************************)
procedure TSAIndividualTax.Clear;
begin
  UTR       := '';
  TaxYear   := '';
  TaxRefund := 0.00;
  Benefits.Clear;
  PayList.Clear;
end;



end.
