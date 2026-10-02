unit HmrcTestSupport;

(*****************************************************************************
*                        HMRC API REST Support Unit                          *
******************************************************************************
*  Support types and values for the HMRC REST / TEST Client components       *
*                                                                            *
*  created 01/01/21.                                                         *
*  updated 01/01/21.                                                         *
*  version 1.0.0                                                             *
*                                                                            *
*  original copyright Ian Hamilton 2021.                                     *
*  License : GPL                                                             *
*****************************************************************************)

interface
(****************************************************************************)
uses
  System.Classes, System.SysUtils, System.Types;

(****************************************************************************)
const
  csBenefits    = 'Benefits';
  csEligible    = 'eligible';
  csEmployments = 'Employments';
  csHello       = 'hello';
  csIncome      = 'Income';
  csDefault     = 'default';
  csMA          = 'Marriage Allowance';
  csNICs        = 'NICs';
  csRscMAnino   = 'marriage-allowance-test-support/nino/';
  csRscMAstatus = 'marriage-allowance-test-support/sa/';
  csRscNICs     = 'national-insurance-test-support/sa/';
  csRscPaye     = 'individual-paye-test-support/sa/';
  csScenario1   = '{"scenario": "HAPPY_PATH_1"}';
  csScenario2   = '{"scenario": "HAPPY_PATH_2"}';
  csSetStatus   = '{"status": "%s", "deceased": %s}';
  csSetEligible = '{"eligible": %s}';
  csSfxBens     = 'benefits/annual-summary/';
  csSfxEligible = 'eligibility/';
  csSfxEmps     = 'employments/annual-summary/';
  csSfxIcm      = 'income/annual-summary/';
  csSfxNICs     = 'annual-summary/';
  csSfxStatus   = 'status/';
  csSfxTax      = 'tax/annual-summary/';
  csStatus      = 'status';
  csTax         = 'Tax';

(****************************************************************************)
implementation
(****************************************************************************)

end.
