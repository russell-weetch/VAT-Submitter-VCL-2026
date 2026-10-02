unit HmrcVatClient;

(* ****************************************************************************
  *                         HMRC VAT API Client Unit                           *
  ******************************************************************************
  *  This unit contains new class definitions which inherit from               *
  *  THmrcRestClient and implement methods to access the VAT MTD end points.   *
  *                                                                            *
  ******************************************************************************
  *  created  09/12/20 from the original integrated unit.                      *
  *                                                                            *
  *  version  1.0.0       released 16/12/20                                    *
  *  version  1.0.1       released 03/02/21   New access methods return data   *
  *                                           objects & scope versioning.      *
  *                                                                            *
  *  original copyright Ian Hamilton 2018/19.                                  *
  *  Contributors: Ian Hamilton, Russell Weetch.                               *
  *  License : GPL                                                             *
  *                                                                            *
  *  VAT API version 1.0 (beta)                                                *
  *                                                                            *
  **************************************************************************** *)

interface
(* ************************************************************************** *)
Uses
  System.Classes, System.SysUtils, System.UITypes, System.Variants,
  IPPeerClient, REST.Types, REST.Client, REST.Authenticator.OAuth,
  System.JSON, Contnrs,
  HmrcRestSupport,
  HmrcRestClient,
  HmrcVatSupport;

(* ************************************************************************** *)
type
  (* **************************************************************************
    **           VAT REST Client for the HMRC REST API service                **
    **                                                                        **
    **  This handles VAT services provided by the API service.                **
    **                                                                        **
    **  The user id is the VRN.                                               **
    **  Search dates in the format YYYY-MM-DD                                 **
    **  Base resource = organisations/vat/{VRN}/                              **
    **  API Version 1.0                                                       **
    **                                                                        **
    **  There are 5 end points, 4 GET and 1 POST.                             **
    **    Liabilities - GET - (Date From + Date To)                           **
    **    Obligations - GET - (Date From + Date To + status)                  **
    **    Payments - GET - (Date From + Date To)                              **
    **    Returns - GET - (Period ID)                                         **
    **    SubmitReturns - POST - (List of values)                             **
    **                                                                        **
    **  There are some basic sanity checks run on the parameters supplied for **
    **  the GET calls and on the data to be submitted. Other checks are       **
    **  performed by HMRC, which may cause the call to fail.                  **
    **                                                                        **
    **  The calls to Liabilities, Obligations and Payments are identical,     **
    **  except for the final part of the url. These calls are handled by the  **
    **  SearchLOP method, which accepts the name as a parameter, along with   **
    **  the start and end dates for the search.                               **
    **                                                                        **
    **  The Returns call takes a single VAT period id as a Resource Suffix.   **
    **                                                                        **
    **  The Submit Returns method takes a vat period, a list of values and a  **
    **  finalised (true/false) value. If successful it will return the        **
    **  receipt/confirmation details in a list.                               **
    **                                                                        **
    **  According to HMRC documentation, all apps must access the Obligations **
    **  and SubmitReturns end points. The others are optional.                **
    **                                                                        **
    ************************************************************************** *)
  THmrcVATClient = Class(THMRCRestClient)
  Private
  Protected
    FDateFrom: String; // start date for search
    FDateTo: String;   // end date for search

    // search liabilities & payments
    Function API_SearchLP(Const aType: String; Const FromDate, ToDate: TDateTime; Var ACorlnId: String): integer;
    function CHK_HazNoData(const aCode: integer; Const aValue: TJSONValue): boolean; // is it 404 nothing found ?
    procedure INT_Scopes; override;
    Function PRM_CheckDates(Const dtFrom, dtTo: TDateTime): boolean; // basic checks on dates supplied
    Function PRM_CheckPeriod(Const Value: String): boolean;          // basic checks on period format
    Function PRM_CheckValues(Const Values: TStringList): boolean;    // check the list of values for submission
  Public
    Constructor Create(AOwner: TComponent); Override;
    // search liabilities for a date range
    Function GetLiabilities(Const FromDate, ToDate: TDateTime; Var ACorrelationId: String): integer; overload;
    Function GetLiabilities(Const FromDate, ToDate: TDateTime): TObjectList; overload;
    // search obligations for a date range
    Function GetObligations(Const FromDate, ToDate: TDateTime; Var ACorrelationId: String;
                            aStatus: String = ''): integer; overload;
    Function GetObligations(Const FromDate, ToDate: TDateTime; aStatus: String = ''): TObjectList; overload;
    // search payments for a date range
    Function GetPayments(Const FromDate, ToDate: TDateTime; Var ACorrelationId: String): integer; overload;
    Function GetPayments(Const FromDate, ToDate: TDateTime): TObjectList; overload;
    // do a returns check for a vat period
    Function GetReturn(Const aPeriod: String; Var ACorrelationId: String): integer; overload;
    Function GetReturn(Const aPeriod: String): TVatReturn; overload;
    // submit a return
    Function SubmitReturn(Const aPeriod: String; Const Values: TStringList;
                          Const IzFinal: boolean; Var Confirm: String): integer; overload;
    Function SubmitReturn(aVatObj: TVatSubmission): integer; overload;
    // override to apply some kind of validation
    Function SetHmrcID(Const Value: String): integer; Override;

  End;

Procedure Register;

(* ************************************************************************** *)
Implementation

(* ************************************************************************** *)
Uses
  REST.Utils,
  System.IOUtils
  ;

Procedure Register;
Begin
  RegisterComponents('HmrcRestClient', [THmrcVATClient]);
End;

{ THmrcVATClient }

(* ****************************************************************************
  *                            HMRC VAT CLIENT                                 *
  ******************************************************************************
  *                             INIT SECTION                                   *
  ******************************************************************************
  *  Init.                                                                     *
  **************************************************************************** *)
Constructor THmrcVATClient.Create(AOwner: TComponent);
Begin
  Inherited;

  FApiVersion := '1.0';
  FApiVersioning := false;
  FAuthMode := amUser; // usually user authentication, but VRN calls are application auth.

  INT_Scopes;
End;

(* ****************************************************************************
  *  Set the length of the scopes list and add the scopes in use.              *
  **************************************************************************** *)
procedure THmrcVATClient.INT_Scopes;
var
  ct1, ix1: integer;
begin
  ct1 := ScopeCount;
  Setlength(LScopeList, ct1);
  for ix1 := 0 to ct1 - 1 do
    LScopeList[ix1] := ScopeByIndex(ix1);
end;

(* ****************************************************************************
  *                    RESPONSE VALIDATION METHODS SECTION                     *
  ******************************************************************************
  *  Check the response code value and the message value of the response.      *
  **************************************************************************** *)
function THmrcVATClient.CHK_HazNoData(const aCode: integer; const aValue: TJSONValue): boolean;
var
  sv1: string;
begin
  Result := false;
  // is it 404 (not found)
  if aCode = 404 then
  begin
    // check the message for the "no data" response
    // is it a json object? If not then the test fails
    if (aValue is TJSONObject) then
    begin
      If aValue.TryGetValue<String>(csMessage, sv1) Then
      begin
        if (SameText(sv1, csResponseNodata)) then
          Result := true;
      end;  // if get message
    end;  // if jo
  end;  // if 404
end;

(* ****************************************************************************
  *                          API METHODS SECTION                               *
  ******************************************************************************
  *  Call VAT Liabilities / Payments for a date range. The only difference is  *
  *  the last element of the resource.                                         *
  **************************************************************************** *)
Function THmrcVATClient.API_SearchLP(Const aType: String; Const FromDate, ToDate: TDateTime; Var ACorlnId: String): integer;
Begin
  Result := RESULT_NONE;
  Try
    REQ_ClearLast;
    If (FUID <> '') Then
    Begin
      If (PRM_CheckDates(FromDate, ToDate)) Then
      Begin
        AuthMode := amUser;
        AuthScope := csReadVat;
        If (REQ_CheckToken) Then
        Begin
          REQ_ClearLast;
          REQ_Reset;

          // search specific
          ORequest.Resource := csOrgsVat + FUID + '/' + aType;
          ORequest.Params.AddItem(csFrom, FDateFrom, TRESTRequestParameterKind.pkGETorPOST);
          ORequest.Params.AddItem(csTo, FDateTo, TRESTRequestParameterKind.pkGETorPOST);

          ORequest.Execute;

          FLastCode := ORequest.Response.StatusCode;
          FLastMsg := ORequest.Response.StatusText;
          If (ORequest.Response.Status.Success) Then
          Begin
            FLastValue := ORequest.Response.JSONValue;
            ACorlnId := ORequest.Response.Headers.Values[csXCorrelationid];
            Result := RESULT_OK;
          End
          Else
          Begin
            FLastError := ORequest.Response.Content;
            If CHK_HazNoData(FLastCode, ORequest.Response.JSONValue) then
              Result := RESULT_NODATA
            Else
              Result := RESULT_FAIL;
          End; // else failed
        End // if token
        Else
        Begin
          // error message set in CheckToken
          Result := RESULT_FAIL;
        End;
      End // if dates
      Else
      Begin
        // error message set in check dates
        Result := RESULT_FAIL;
      End;
    End // if uid
    Else
    Begin
      FLastCode := ERR_NO_USER_ID;
      FLastMsg := csMsgNoUserId;
      Result := RESULT_FAIL;
    End;
  Except
    On e: Exception Do
    Begin
      FLastError := e.Message;
      Result := RESULT_ERROR;
    End;
  End;
End;

(* ****************************************************************************
  *  Get VAT liabilities details for a given date range.                       *
  **************************************************************************** *)
Function THmrcVATClient.GetLiabilities(Const FromDate, ToDate: TDateTime; Var ACorrelationId: String): integer;
Begin
  Result := API_SearchLP(csLiabilities, FromDate, ToDate, ACorrelationId);
End;

(* ****************************************************************************
  *  Get VAT liabilities details for a given date range as a data object.      *
  **************************************************************************** *)
function THmrcVATClient.GetLiabilities(const FromDate, ToDate: TDateTime): TObjectList;
var
  CorId: String;
begin
  Result := nil;
  if GetLiabilities(FromDate, ToDate, CorId) = RESULT_OK then
    Result := ParseLiabilities(CorId, LastValue);
end;

(* ****************************************************************************
  *  Get VAT obkigations details for a given date range.                       *
  **************************************************************************** *)
Function THmrcVATClient.GetObligations(Const FromDate, ToDate: TDateTime; Var ACorrelationId: String; aStatus: String = ''): integer;
Begin
  Result := RESULT_NONE;
  Try
    REQ_ClearLast;
    If (FUID <> '') Then
    Begin
      If (PRM_CheckDates(FromDate, ToDate)) Then
      Begin
        AuthMode := amUser;
        AuthScope := csReadVat;
        If (REQ_CheckToken) Then
        Begin
          REQ_ClearLast;
          REQ_Reset;

          // search specific
          ORequest.Resource := csOrgsVat + FUID + '/' + csObligations;
          ORequest.Params.AddItem(csFrom, FDateFrom, TRESTRequestParameterKind.pkGETorPOST);
          ORequest.Params.AddItem(csTo, FDateTo, TRESTRequestParameterKind.pkGETorPOST);
          If (aStatus = 'F') Or (aStatus = 'O') Then
            ORequest.Params.AddItem(csStatus, aStatus, TRESTRequestParameterKind.pkGETorPOST);

          ORequest.Execute;

          FLastCode := ORequest.Response.StatusCode;
          FLastMsg := ORequest.Response.StatusText;
          If (ORequest.Response.Status.Success) Then
          Begin
            FLastValue := ORequest.Response.JSONValue;
            ACorrelationId := ORequest.Response.Headers.Values[csXCorrelationid];
            Result := RESULT_OK;
          End
          Else
          Begin
            FLastError := ORequest.Response.Content;
            If CHK_HazNoData(FLastCode, ORequest.Response.JSONValue) then
              Result := RESULT_NODATA
            Else
              Result := RESULT_FAIL;
          End; // else failed
        End // if token
        Else
        Begin
          // error message set in CheckToken
          Result := RESULT_FAIL;
        End;
      End // if dates
      Else
      Begin
        // error message set in check dates
        Result := RESULT_FAIL;
      End;
    End // if uid
    Else
    Begin
      FLastCode := ERR_NO_USER_ID;
      FLastMsg := csMsgNoUserId;
      Result := RESULT_FAIL;
    End;
  Except
    On e: Exception Do
    Begin
      FLastError := e.Message;
      Result := RESULT_ERROR;
    End;
  End;
End;

(* ****************************************************************************
  *  Get VAT obkigations details for a given date range as a data object.      *
  **************************************************************************** *)
function THmrcVATClient.GetObligations(const FromDate, ToDate: TDateTime; aStatus: String): TObjectList;
var
  CorId: String;
begin
  Result := nil;
  if GetObligations(FromDate, ToDate, CorId, aStatus) = RESULT_OK then
    Result := ParseObligations(CorId, LastValue);
end;


(* ****************************************************************************
  *  Get VAT payments details for a given date range.                          *
  **************************************************************************** *)
Function THmrcVATClient.GetPayments(Const FromDate, ToDate: TDateTime; Var ACorrelationId: String): integer;
Begin
  Result := API_SearchLP(csPayments, FromDate, ToDate, ACorrelationId);
End;

(* ****************************************************************************
  *  Get VAT payments details for a given date range as a data object.         *
  **************************************************************************** *)
function THmrcVATClient.GetPayments(const FromDate, ToDate: TDateTime): TObjectList;
var
  CorId: String;
begin
  Result := nil;
  if GetPayments(FromDate, ToDate, CorId) = RESULT_OK then
    Result := ParsePayments(CorId, LastValue);
end;


(* ****************************************************************************
  *  Get VAT Returns details for a given period.                               *
  **************************************************************************** *)
Function THmrcVATClient.GetReturn(Const aPeriod: String; Var ACorrelationId: String): integer;
Begin
  Result := RESULT_NONE;
  Try
    REQ_ClearLast;
    If (FUID <> '') Then
    Begin
      If (PRM_CheckPeriod(aPeriod)) Then
      Begin
        AuthMode := amUser;
        AuthScope := csReadVat;
        If (REQ_CheckToken) Then
        Begin
          REQ_Reset;

          // view returns specific
          ORequest.Resource := csOrgsVat + FUID + '/' + csReturns;
          ORequest.ResourceSuffix := URIEncode(aPeriod);

          ORequest.Execute;

          FLastCode := ORequest.Response.StatusCode;
          FLastMsg := ORequest.Response.StatusText;
          If (ORequest.Response.Status.Success) Then
          Begin
            FLastValue := ORequest.Response.JSONValue;
            ACorrelationId := ORequest.Response.Headers.Values[csXCorrelationid];
            Result := RESULT_OK;
          End
          Else
          Begin
            FLastError := ORequest.Response.Content;
            If CHK_HazNoData(FLastCode, ORequest.Response.JSONValue) then
              Result := RESULT_NODATA
            Else
              Result := RESULT_FAIL;
            Result := RESULT_FAIL;
          End; // else failed
        End // if token
        Else
        Begin
          // error message set in CheckToken
          Result := RESULT_FAIL;
        End;
      End // if dates
      Else
      Begin
        // error message set in check period
        Result := RESULT_FAIL;
      End;
    End // if uid
    Else
    Begin
      FLastCode := ERR_NO_USER_ID;
      FLastMsg := csMsgNoUserId;
      Result := RESULT_FAIL;
    End;
  Except
    On e: Exception Do
    Begin
      FLastError := e.Message;
      Result := RESULT_ERROR;
    End;
  End;
End;

(* ****************************************************************************
  *  Get VAT Returns details for a given period as a data object.              *
  **************************************************************************** *)
function THmrcVATClient.GetReturn(const aPeriod: String): TVatReturn;
var
  CorId: String;
begin
  Result := nil;
  if (GetReturn(aPeriod, CorId) = RESULT_OK) then
    Result := ParseReturns(CorId, LastValue);
end;


(* ****************************************************************************
  *  Submit VAT Returns details for a given period. Parse the confirmation     *
  *  details into a string list.                                               *
  **************************************************************************** *)
Function THmrcVATClient.SubmitReturn(Const aPeriod: String; Const Values: TStringList; Const IzFinal: boolean;
  Var Confirm: String): integer;
Var
  S, lLogName, lCorrelation, lCorrelationId, lReceipt, lReceiptId, lJSON: String;
  lVal: TArray<String>;
Begin
  Result := RESULT_NONE;
  Confirm := '';
  Try
    REQ_ClearLast;
    If (FUID <> '') Then
    Begin
      If (PRM_CheckPeriod(aPeriod)) Then
      Begin
        If (PRM_CheckValues(Values)) Then
        Begin
          AuthMode := amUser;
          AuthScope := csRiteVat;
          If (REQ_CheckToken) Then
          Begin
            REQ_ClearLast;
            REQ_Reset;
            // that set it to GET, so change it
            ORequest.Method := TRESTRequestMethod.rmPOST;

            // submit returns specific
            ORequest.Resource := csOrgsVat + FUID + '/' + csReturns;

            // the json is accepted if created like this using the JSONWriter element of the request
            ORequest.Body.JSONWriter.WriteStartObject;
            // add period
            ORequest.Body.JSONWriter.WritePropertyname(csPeriodKey);
            ORequest.Body.JSONWriter.WriteValue(aPeriod);
            // add the list of numeric values
            ORequest.Body.JSONWriter.WritePropertyname(Values.Names[0]);
            ORequest.Body.JSONWriter.WriteValue(StrToFloat(Values.ValueFromIndex[0]));
            ORequest.Body.JSONWriter.WritePropertyname(Values.Names[1]);
            ORequest.Body.JSONWriter.WriteValue(StrToFloat(Values.ValueFromIndex[1]));
            ORequest.Body.JSONWriter.WritePropertyname(Values.Names[2]);
            ORequest.Body.JSONWriter.WriteValue(StrToFloat(Values.ValueFromIndex[2]));
            ORequest.Body.JSONWriter.WritePropertyname(Values.Names[3]);
            ORequest.Body.JSONWriter.WriteValue(StrToFloat(Values.ValueFromIndex[3]));
            ORequest.Body.JSONWriter.WritePropertyname(Values.Names[4]);
            ORequest.Body.JSONWriter.WriteValue(StrToFloat(Values.ValueFromIndex[4]));
            ORequest.Body.JSONWriter.WritePropertyname(Values.Names[5]);
            ORequest.Body.JSONWriter.WriteValue(StrToFloat(Values.ValueFromIndex[5]));
            ORequest.Body.JSONWriter.WritePropertyname(Values.Names[6]);
            ORequest.Body.JSONWriter.WriteValue(StrToFloat(Values.ValueFromIndex[6]));
            ORequest.Body.JSONWriter.WritePropertyname(Values.Names[7]);
            ORequest.Body.JSONWriter.WriteValue(StrToFloat(Values.ValueFromIndex[7]));
            ORequest.Body.JSONWriter.WritePropertyname(Values.Names[8]);
            ORequest.Body.JSONWriter.WriteValue(StrToFloat(Values.ValueFromIndex[8]));
            // add the finalised state
            ORequest.Body.JSONWriter.WritePropertyname(csFinalised);
            ORequest.Body.JSONWriter.WriteValue(IzFinal);
            // and close
            ORequest.Body.JSONWriter.WriteEndObject;

            ORequest.Execute;

            FLastCode := ORequest.Response.StatusCode;
            FLastMsg := ORequest.Response.StatusText;
            If (ORequest.Response.Status.Success) Then
            Begin
              // we actually need to extract values from the response headers
              lCorrelation := ORequest.Response.Headers[ORequest.Response.Headers.IndexOfName(csXCorrelationid)];
              Try
                lVal := lCorrelation.Split(['=']);
                lCorrelationId := lVal[1];
              Except
                lCorrelationId := csUnknown;
                lCorrelation := csXCorrelationid + '=' + lCorrelationId;
              End;

              lReceipt := ORequest.Response.Headers[ORequest.Response.Headers.IndexOfName(csReceiptId)];
              Try
                lVal := lReceipt.Split(['=']);
                lReceiptId := lVal[1];
              Except
                lReceiptId := csUnknown;
                lReceipt := csReceiptId + '=' + lReceiptId;
              End;

              // IH 12/12/20
              // Rearrangement of RW's log process to check whether there is a log folder set and only log if required
              if (StoreFolder <> '') then
              begin
                lLogName := aPeriod + '_' + FormatDateTime('yyyymmddhhnnss', Now) + '.json';
                lLogName := TPath.Combine(StoreFolder, lLogName);

                lJSON := '{' + sLineBreak + '    "correlation-id":"$",'.Replace('$', lCorrelationId) + sLineBreak +
                    '    "receipt-id":"$",'.Replace('$', lReceiptId);
                TFile.WriteAllText(lLogName, ORequest.Response.JSONText.Replace('{', lJSON));
              end;
              // end of change

              FLastValue := ORequest.Response.JSONValue;

              // initialise the responses string with header data
              Confirm := lCorrelation + ';' + lReceipt;
              Try
                If FLastValue.TryGetValue<String>(csProcessingdate, S) Then
                  Confirm := Confirm + ';' + csProcessingdate + '=' + S;
                If FLastValue.TryGetValue<String>(csPaymentIndicator, S) Then
                  Confirm := Confirm + ';' + csPaymentIndicator + '=' + S;
                If FLastValue.TryGetValue<String>(csFormBundleNumber, S) Then
                  Confirm := Confirm + ';' + csFormBundleNumber + '=' + S;
                If FLastValue.TryGetValue<String>(csChargeRefNumber, S) Then
                  Confirm := Confirm + ';' + csChargeRefNumber + '=' + S;
              Except
                // let's not fail just because of an error here
              End;
              Result := RESULT_OK;
            End
            Else
            Begin
              FLastError := ORequest.Response.Content;
              Result := RESULT_FAIL;
            End; // else failed
          End // if token
          Else
          Begin
            // error message set in CheckToken
            Result := RESULT_FAIL;
          End;
        End // if values
        Else
        Begin
          FLastCode := ERR_INVALID_DATA;
          FLastMsg := csMsgBadData;
          Result := RESULT_FAIL;
        End;
      End // if dates
      Else
      Begin
        // error message set in check period
        Result := RESULT_FAIL;
      End;
    End // if uid
    Else
    Begin
      FLastCode := ERR_NO_USER_ID;
      FLastMsg := csMsgNoUserId;
      Result := RESULT_FAIL;
    End;
  Except
    On e: Exception Do
    Begin
      FLastError := e.Message;
      Result := RESULT_ERROR;
    End;
  End;
End;

(* ****************************************************************************
  *  Overloaded method to submit VAT Returns details for a given period.       *
  *  Accepts input as a vat submission object and writes the response data     *
  *  back to the object.                                                       *
  **************************************************************************** *)
Function THmrcVATClient.SubmitReturn(aVatObj: TVatSubmission): integer;
Var
  S, lLogName, lCorrelation, lCorrelationId, lReceipt, lReceiptId, lJSON: String;
  lVal: TArray<String>;
Begin
  Result := RESULT_NONE;
  // check object exists
  if (Not Assigned(aVatObj)) then
  begin
    FLastCode := ERR_INVALID_DATA;
    FLastMsg := csMsgNoData;
    Result := RESULT_FAIL;

    Exit;
  end;

  Try
    REQ_ClearLast;
    If (FUID <> '') Then
    Begin
      If (PRM_CheckPeriod(aVatObj.PeriodKey)) Then
      Begin
        If (aVatObj.Validates) Then
        Begin
          AuthMode := amUser;
          AuthScope := csRiteVat;
          If (REQ_CheckToken) Then
          Begin
            REQ_ClearLast;
            REQ_Reset;
            // that set it to GET, so change it
            ORequest.Method := TRESTRequestMethod.rmPOST;

            // submit returns specific
            ORequest.Resource := csOrgsVat + FUID + '/' + csReturns;

            // the json is accepted if created like this using the JSONWriter element of the request
            ORequest.Body.JSONWriter.WriteStartObject;
            // add period
            ORequest.Body.JSONWriter.WritePropertyname(csPeriodKey);
            ORequest.Body.JSONWriter.WriteValue(aVatObj.PeriodKey);
            // add the list of numeric values
            ORequest.Body.JSONWriter.WritePropertyname(csVatDueSales);
            ORequest.Body.JSONWriter.WriteValue(aVatObj.DueOnSales);
            ORequest.Body.JSONWriter.WritePropertyname(csVatDueAcquisitions);
            ORequest.Body.JSONWriter.WriteValue(aVatObj.DueOnAcquisitions);
            ORequest.Body.JSONWriter.WritePropertyname(cstotalVatDue);
            ORequest.Body.JSONWriter.WriteValue(aVatObj.TotalVatDue);
            ORequest.Body.JSONWriter.WritePropertyname(csVatReclaimedCurrPeriod);
            ORequest.Body.JSONWriter.WriteValue(aVatObj.VatReclaimedCP);
            ORequest.Body.JSONWriter.WritePropertyname(csNetVatDue);
            ORequest.Body.JSONWriter.WriteValue(aVatObj.NetVatDue);
            ORequest.Body.JSONWriter.WritePropertyname(csTotalValueSalesExVAT);
            ORequest.Body.JSONWriter.WriteValue(aVatObj.SalesExVat);
            ORequest.Body.JSONWriter.WritePropertyname(csTotalValuePurchasesExVAT);
            ORequest.Body.JSONWriter.WriteValue(aVatObj.PurchasesExVat);
            ORequest.Body.JSONWriter.WritePropertyname(csTotalValueGoodsSuppliedExVAT);
            ORequest.Body.JSONWriter.WriteValue(aVatObj.GoodsExVat);
            ORequest.Body.JSONWriter.WritePropertyname(csTotalAcquisitionsExVAT);
            ORequest.Body.JSONWriter.WriteValue(aVatObj.AcquisitionsExVAT);
            // add the finalised state
            ORequest.Body.JSONWriter.WritePropertyname(csFinalised);
            ORequest.Body.JSONWriter.WriteValue(aVatObj.Finalized);
            // and close
            ORequest.Body.JSONWriter.WriteEndObject;

            ORequest.Execute;

            FLastCode := ORequest.Response.StatusCode;
            FLastMsg := ORequest.Response.StatusText;
            If (ORequest.Response.Status.Success) Then
            Begin
              // we actually need to extract values from the response headers
              lCorrelation := ORequest.Response.Headers[ORequest.Response.Headers.IndexOfName(csXCorrelationid)];
              Try
                lVal := lCorrelation.Split(['=']);
                lCorrelationId := lVal[1];
              Except
                lCorrelationId := csUnknown;
                lCorrelation := csXCorrelationid + '=' + lCorrelationId;
              End;

              lReceipt := ORequest.Response.Headers[ORequest.Response.Headers.IndexOfName(csReceiptId)];
              Try
                lVal := lReceipt.Split(['=']);
                lReceiptId := lVal[1];
              Except
                lReceiptId := csUnknown;
                lReceipt := csReceiptId + '=' + lReceiptId;
              End;

              // IH 12/12/20
              // Rearrangement of RW's log process to check whether there is a log folder set and only log if required
              if (StoreFolder <> '') then
              begin
                lLogName := aVatObj.PeriodKey + '_' + FormatDateTime('yyyymmddhhnnss', Now) + '.json';
                lLogName := TPath.Combine(StoreFolder, lLogName);

                lJSON := '{' + sLineBreak + '    "correlation-id":"$",'.Replace('$', lCorrelationId) + sLineBreak +
                    '    "receipt-id":"$",'.Replace('$', lReceiptId);
                TFile.WriteAllText(lLogName, ORequest.Response.JSONText.Replace('{', lJSON));
              end;
              // end of change

              FLastValue := ORequest.Response.JSONValue;

              // update the vat object with header data and response data
              aVatObj.XCorId := lCorrelation;
              aVatObj.ReceiptId := lReceipt;
              Try
                If FLastValue.TryGetValue<String>(csProcessingdate, S) Then
                  aVatObj.Processed := S;
                If FLastValue.TryGetValue<String>(csPaymentIndicator, S) Then
                  aVatObj.PaymentIdct := S;
                If FLastValue.TryGetValue<String>(csFormBundleNumber, S) Then
                  aVatObj.BundleNo := S;
                If FLastValue.TryGetValue<String>(csChargeRefNumber, S) Then
                  aVatObj.ChargeRefNo := S;
              Except
                // let's not fail just because of an error here
              End;
              Result := RESULT_OK;
            End
            Else
            Begin
              FLastError := ORequest.Response.Content;
              Result := RESULT_FAIL;
            End; // else failed
          End // if token
          Else
          Begin
            // error message set in CheckToken
            Result := RESULT_FAIL;
          End;
        End // if values
        Else
        Begin
          FLastCode := ERR_INVALID_DATA;
          FLastMsg := csMsgBadData;
          Result := RESULT_FAIL;
        End;
      End // if dates
      Else
      Begin
        // error message set in check period
        Result := RESULT_FAIL;
      End;
    End // if uid
    Else
    Begin
      FLastCode := ERR_NO_USER_ID;
      FLastMsg := csMsgNoUserId;
      Result := RESULT_FAIL;
    End;
  Except
    On e: Exception Do
    Begin
      FLastError := e.Message;
      Result := RESULT_ERROR;
    End;
  End;
End;



(* ****************************************************************************
  *                     INPUT VALIDATION METHODS SECTION                       *
  ******************************************************************************
  *  Check the vat search parameters are valid date ranges.                    *
  **************************************************************************** *)
Function THmrcVATClient.PRM_CheckDates(Const dtFrom, dtTo: TDateTime): boolean;
Begin
  Result := true;
  If (dtFrom > dtTo) Then
  Begin
    FLastCode := ERR_DATE_ERROR;
    FLastError := csMsgDateError;
    Result := False;
  End
  Else If ((dtTo - dtFrom) > 365) Then
  Begin
    FLastCode := ERR_DATE_RANGE;
    FLastError := csMsgDateRange;
    Result := False;
  End
  Else If (dtFrom < 1) Then
  Begin
    FLastCode := ERR_DATE_LOW;
    FLastError := csMsgDateLow;
    Result := False;
  End
  Else If (dtFrom > (Date + 365)) Then
  Begin
    FLastCode := ERR_DATE_HIGH;
    FLastError := csMsgDateHigh;
    Result := False;
  End
  Else
  Begin
    FDateFrom := REQ_DateFormat(dtFrom);
    FDateTo := REQ_DateFormat(dtTo);
  End;
End;

(* ****************************************************************************
  *  Check the vat period is sort of sensible.                                 *
  **************************************************************************** *)
Function THmrcVATClient.PRM_CheckPeriod(Const Value: String): boolean;
Begin
  Result := true;
  If (Length(Value) <> 4) Then
  Begin
    FLastCode := ERR_INVALID_PERIOD;
    FLastError := csMsgBadPeriod;
    Result := False;
  End;
End;

(* ****************************************************************************
  *  Check the values supplied for submission are valid. Are there 9 and are   *
  *  they all numeric. It does not check for sign and decimal places.          *
  **************************************************************************** *)
Function THmrcVATClient.PRM_CheckValues(Const Values: TStringList): boolean;
Var
  idx: integer;
Begin
  Result := true;
  If (Values = Nil) Then
  Begin
    FLastCode := ERR_NO_DATA;
    FLastError := csMsgNoData;
    Result := False;
  End
  Else If (Values.Count <> 9) Then
  Begin
    FLastCode := ERR_INVALID_DATA;
    FLastError := csMsgBadData;
    Result := False;
  End
  Else
  Begin
    For idx := 0 To Values.Count - 1 Do
    Begin
      If (Values.ValueFromIndex[idx] = '') Then
      Begin
        FLastCode := ERR_INVALID_DATA;
        FLastError := csMsgBadData;
        Result := False;
        Break;
      End
      Else If (StrToFloatDef(Values.ValueFromIndex[idx], 0) = 0) And
        (StrToFloatDef(Values.ValueFromIndex[idx], 10) = 10) Then
      Begin
        FLastCode := ERR_INVALID_DATA;
        FLastError := csMsgBadData;
        Result := False;
        Break;
      End;
    End; // for idx
  End;
End;

(* ****************************************************************************
  *  Perform basic checks on the user id as a VRN.                             *
  **************************************************************************** *)
Function THmrcVATClient.SetHmrcID(Const Value: String): integer;
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
  Else If (Length(lvUid) <> 9) Then
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
End;

end.
