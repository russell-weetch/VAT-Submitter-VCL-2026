unit HmrcSAClient;
(* ****************************************************************************
 *                        HMRC SA API REST Client Unit                        *
 ******************************************************************************
 *  This unit contains new class definition(s) which inherit from             *
 *  THmrcRestClient and implement methods to access the MTD Self Assessment   *
 *  (SA) end points. There appear to be some end points that are common to 2  *
 *  or all of the PAYE / SA groups of functions. These will (probably) be     *
 *  accessed by all affected clients.                                         *
 *                                                                            *
 ******************************************************************************
 *  created  28/12/20    Based on the existing VAT client.                    *
 *  updated  08/02/21.   Initial release.                                     *
 *                                                                            *
 *  version  1.0.0       released 08/02/21    initial release for beta apis   *
 *                                                                            *
 *  original copyright Ian Hamilton 2018/21.                                  *
 *  License : GPL                                                             *
 *                                                                            *
 **************************************************************************** *)
Interface
(* ************************************************************************** *)
Uses
  System.Classes, System.SysUtils, System.UITypes, System.Variants, REST.Types, REST.Client,
  System.JSON, System.Generics.Collections,
  HmrcRestSupport, HmrcSASupport, HmrcRestClient;
(* ************************************************************************** *)

Type
  (* **************************************************************************
  **            SA REST Client for the HMRC REST API service                 **
  **                                                                         **
  **  This handles Self Assessment services provided by the API service.     **
  **                                                                         **
  **  The user id is the UTR.  (10 digits)                                   **
  **  Tax year in the format YYYY-YY                                         **
  *************************************************************************** *
  *                                                                           *
  *  Compatible API versions  -  as at February 2021                          *
  *  Benefits            1.1                                                  *
  *  Employments         1.2                                                  *
  *  Income              1.2                                                  *
  *  Marriage Allowance  2.0                                                  *
  *  National Insurance  1.1                                                  *
  *  Tax                 1.1                                                  *
  ************************************************************************** *)
  THmrcSAClient = Class(THMRCRestClient)
  protected
    function GEN_IzValidId: boolean; override; // does the UID look valid
  public
    constructor Create(AOwner: TComponent); override;
    // get the individual benefits
    function GetBenefits(Const AValue: string): integer; overload;
    function GetBenefits(Const AValue: string; var ACode: integer): TSABenefitsList; overload;
    // get the individual employments
    function GetEmployment(Const AValue: string): integer; overload;
    function GetEmployment(Const AValue: string; var ACode: integer): TSAEmploymentsList; overload;
    // get the individual income
    function GetIncome(Const AValue: string): integer; overload;
    function GetIncome(Const AValue: string; var ACode: integer): TSAIncomes; overload;
    // get the marriage allowance eligibility
    function GetMAEligibility(AValue: TSAMrgAllowance): integer;
    // get the marriage allowance status
    function GetMAStatus(const AValue: string): integer; overload;
    function GetMAStatus(const AValue: string; var AStatus: string; var ADead: boolean): integer; overload;
    // get the national insurance
    function GetNI(Const AValue: string): integer; overload;
    function GetNI(Const AValue: string; var ACode: integer): TSANI; overload;
    // get the individual tax
    function GetTax(Const AValue: string): integer; overload;
    function GetTax(Const AValue: string; var ACode: integer): TSAIndividualTax; overload;

    Function SetHmrcID(Const Value: String): integer; Override; // override to apply some kind of validation
  end;

Procedure Register;

(* ************************************************************************** *)
implementation
(* ************************************************************************** *)
uses
  REST.Utils, System.IOUtils;

Procedure Register;
begin
  RegisterComponents('HmrcRestClient', [THmrcSAClient]);
end;

{ THmrcSAClient }

(*****************************************************************************
*                            HMRC SA CLIENT                                  *
******************************************************************************
*                         INIT METHODS SECTION                               *
******************************************************************************
*  Init. Base class inits to amNone                                          *
*****************************************************************************)
constructor THmrcSAClient.Create(AOwner: TComponent);
begin
  inherited;

  FAuthMode := amUser;
end;


(*****************************************************************************
*                        GENERIC CALLS SECTION                               *
******************************************************************************
*  Get benefits details by taxyear.                                          *
*****************************************************************************)
function THmrcSAClient.GetBenefits(const AValue: string): integer;
var
  vsn: TEndPointVersion;
begin
  if (not GEN_IzValidId) then
    Result := RESULT_NONE
  else begin
    vsn := SAEndPointVersion(csBenefits);
    Result := CallApi(vsn, csRscBens + FUID, csSfxAnSum + AValue, '', nil);
  end;
end;

(*****************************************************************************
*  Get benefits details by taxyear as a list of data objects.                *
*****************************************************************************)
function THmrcSAClient.GetBenefits(const AValue: string; var ACode: integer): TSABenefitsList;
var
  vsn: TEndPointVersion;
begin
  Result := nil;
  ACode := RESULT_NONE;
  if (not GEN_IzValidId) then
    Exit
  else begin
    vsn := SAEndPointVersion(csBenefits);

    ACode := CallApi(vsn, csRscBens + FUID, csSfxAnSum + AValue, '', nil);

    if ACode = RESULT_OK then
    begin
      Result := ParseSABenefits(FLastValue);
      if (Assigned(Result)) then
      begin
        Result.UTR := FUID;
        Result.Taxyear := AValue;
      end;
    end;  // ok
  end;  // else valid id
end;

(*****************************************************************************
*  Get employment details by taxyear.                                        *
*****************************************************************************)
function THmrcSAClient.GetEmployment(const AValue: string): integer;
var
  vsn: TEndPointVersion;
begin
  if (not GEN_IzValidId) then
    Result := RESULT_NONE
  else begin
    vsn := SAEndPointVersion(csEmployment);
    Result := CallApi(vsn, csRscEmp + FUID, csSfxAnSum + AValue, '', nil);
  end;
end;

(*****************************************************************************
*  Get employment details by taxyear as a list of data objects.              *
*****************************************************************************)
function THmrcSAClient.GetEmployment(const AValue: string; var ACode: integer): TSAEmploymentsList;
var
  vsn: TEndPointVersion;
begin
  Result := nil;
  ACode := RESULT_NONE;
  if (not GEN_IzValidId) then
    Exit
  else begin
    vsn := SAEndPointVersion(csEmployment);

    ACode := CallApi(vsn, csRscEmp + FUID, csSfxAnSum + AValue, '', nil);

    if ACode = RESULT_OK then
    begin
      Result := ParseSAEmployments(FLastValue);
      if (Assigned(Result)) then
      begin
        Result.UTR := FUID;
        Result.Taxyear := AValue;
      end;
    end;  // ok
  end;  // else valid
end;

(*****************************************************************************
*  Get income details by taxyear.                                            *
*****************************************************************************)
function THmrcSAClient.GetIncome(const AValue: string): integer;
var
  vsn: TEndPointVersion;
begin
  if (not GEN_IzValidId) then
    Result := RESULT_NONE
  else begin
    vsn := SAEndPointVersion(csIncome);
    Result := CallApi(vsn, csRscIcm + FUID, csSfxAnSum + AValue, '', nil);
  end;
end;

(*****************************************************************************
*  Get income details by taxyear as a data object.                           *
*****************************************************************************)
function THmrcSAClient.GetIncome(const AValue: string; var ACode: integer): TSAIncomes;
var
  vsn: TEndPointVersion;
begin
  Result := nil;
  ACode := RESULT_NONE;
  if (not GEN_IzValidId) then
    Exit
  else begin
    vsn := SAEndPointVersion(csIncome);

    ACode := CallApi(vsn, csRscIcm + FUID, csSfxAnSum + AValue, '', nil);

    if ACode = RESULT_OK then
    begin
      Result := ParseIncomes(FLastValue);
      if (Assigned(Result)) then
      begin
        Result.UTR := FUID;
        Result.Taxyear := AValue;
      end;
    end;  // ok
  end;  // else valid
end;

(*****************************************************************************
*  Get MA Eligibility details by taxyear.                                    *
*****************************************************************************)
function THmrcSAClient.GetMAEligibility(AValue: TSAMrgAllowance): integer;
var
  bdy: string;
  vsn: TEndPointVersion;
begin
  if (Not Assigned(AValue)) then
    Result := RESULT_FAIL
  else if (not GEN_IzValidId) then
    Result := RESULT_NONE
  else begin
    vsn := SAEndPointVersion(csMAEligible);
    bdy := AValue.BuildRequest;

    Result := CallApi(vsn, csRscMA + FUID, csEligibility, bdy, nil);

    if Result = RESULT_OK then
      AValue.Eligible := ParseMrgEligibility(FLastValue);   // update MA object with result
  end;
end;

(*****************************************************************************
*  Get MA status details by taxyear. NB Taxyear is a parameter, not in url   *
*****************************************************************************)
function THmrcSAClient.GetMAStatus(const AValue: string): integer;
var
  vsn: TEndPointVersion;
  prm: TRestParams;
begin
  if (not GEN_IzValidId) then
    Result := RESULT_NONE
  else begin
    vsn := SAEndPointVersion(csMAStatus);
    SetLength(prm, 1);
    prm[0].Name := csTaxYear;
    prm[0].Value := AValue;
    prm[0].DataIz := praPlainText;

    Result := CallApi(vsn, csRscMA + FUID, csStatus, '', prm);
  end;  // else valid
end;

(*****************************************************************************
*  Get MA status details by taxyear.                                         *
*  status should be [Transferor, Recipient, None] (v2.0 Feb21)               *
*****************************************************************************)
function THmrcSAClient.GetMAStatus(const AValue: string; var AStatus: string; var ADead: boolean): integer;
var
  XStatus: string;
begin
  AStatus := 'None';
  Result := GetMAStatus(AValue);
  if (Result = RESULT_OK) then
  begin
    ADead := ParseMrgAllowance(FLastValue, XStatus);
    AStatus := XStatus;
  end;
end;

(*****************************************************************************
*  Get NI details by taxyear.                                                *
*****************************************************************************)
function THmrcSAClient.GetNI(const AValue: string): integer;
var
  vsn: TEndPointVersion;
begin
  if (not GEN_IzValidId) then
    Result := RESULT_NONE
  else begin
    vsn := SAEndPointVersion(csNI);
    Result := CallApi(vsn, csRscNI + FUID, csSfxAnSum + AValue, '', nil);
  end;
end;

(*****************************************************************************
*  Get NI details by taxyear as a data object.                               *
*****************************************************************************)
function THmrcSAClient.GetNI(const AValue: string; var ACode: integer): TSANI;
var
  vsn: TEndPointVersion;
begin
  Result := nil;
  ACode := RESULT_NONE;
  if (not GEN_IzValidId) then
    Exit
  else begin
    vsn := SAEndPointVersion(csNI);

    ACode := CallApi(vsn, csRscNI + FUID, csSfxAnSum + AValue, '', nil);

    if ACode = RESULT_OK then
    begin
      Result := ParseNI(FLastValue);
      if (Assigned(Result)) then
      begin
        Result.UTR := FUID;
        Result.Taxyear := AValue;
      end;
    end;  // ok
  end;  // else valid
end;

(*****************************************************************************
*  Get tax details by taxyear.                                               *
*****************************************************************************)
function THmrcSAClient.GetTax(const AValue: string): integer;
var
  vsn: TEndPointVersion;
begin
  if (not GEN_IzValidId) then
    Result := RESULT_NONE
  else begin
    vsn := SAEndPointVersion(csTax);
    Result := CallApi(vsn, csRscTax + FUID, csSfxAnSum + AValue, '', nil);
  end;
end;

(*****************************************************************************
*  Get tax details by taxyear as a data object.                              *
*****************************************************************************)
function THmrcSAClient.GetTax(const AValue: string; var ACode: integer): TSAIndividualTax;
var
  vsn: TEndPointVersion;
begin
  Result := nil;
  ACode := RESULT_NONE;
  if (not GEN_IzValidId) then
    Exit
  else begin
    vsn := SAEndPointVersion(csTax);

    ACode := CallApi(vsn, csRscTax + FUID, csSfxAnSum + AValue, '', nil);

    if ACode = RESULT_OK then
    begin
      Result := ParseIndividualTax(FLastValue);
      if (Assigned(Result)) then
      begin
        Result.UTR := FUID;
        Result.Taxyear := AValue;
      end;
    end;  // ok
  end;  // else valid
end;



(*****************************************************************************
*                           OTHER METHODS SECTION                            *
******************************************************************************
*  Perform basic checks on the user id as a UTR.                             *
*****************************************************************************)
function THmrcSAClient.GEN_IzValidId: boolean;
begin
  if (Length(FUID) <> 10) then
    Result := false
  else if (StrToInt64Def(FUID, 0) = 0) then
    Result := false
  else
    Result := true;
end;

(*****************************************************************************
*  Perform basic checks on the user id as a UTR.                             *
*****************************************************************************)
function THmrcSAClient.SetHmrcID(const Value: String): integer;
Var
  lvUid: String;
Begin
  Result := RESULT_OK;

  lvUid := Trim(Value);
  // check it is not empty
  If (lvUid = '') Then
  Begin
    FLastCode := ERR_NO_USER_ID;
    FLastError := csMsgNoUserId;
    Result := RESULT_FAIL;
  End
  // check length is sensible
  Else If (Length(lvUid) <> 10) Then
  Begin
    FLastCode := ERR_INVALID_USER_ID;
    FLastError := csMsgBadUserId;
    Result := RESULT_FAIL;
  End
  // check it is a number
  Else If (StrToInt64Def(lvUid, 0) = 0) Then
  Begin
    FLastCode := ERR_INVALID_USER_ID;
    FLastError := csMsgBadUserId;
    Result := RESULT_FAIL;
  End
  // no problem so set it as the current user id
  Else
  Begin
    FUID := lvUid;
  End;
end;

end.