program HmrcDevTest;

uses
  System.StartUpCopy,
  FMX.Forms,
  fTestMain in 'fTestMain.pas' {frmHMRCDemoMain},
  HmrcRestClient in '..\..\CmnUnits\HmrcRestClient.pas',
  HmrcRestSupport in '..\..\CmnUnits\HmrcRestSupport.pas',
  HmrcVatClient in '..\..\CmnUnits\HmrcVatClient.pas',
  HmrcVatSupport in '..\..\CmnUnits\HmrcVatSupport.pas',
  HmrcTestClient in '..\..\CmnUnits\HmrcTestClient.pas',
  HmrcTestSupport in '..\..\CmnUnits\HmrcTestSupport.pas',
  VAT.Headers.Utils in '..\..\CmnUnits\VAT.Headers.Utils.pas',
  uSMBIOS in '..\..\CmnUnits\uSMBIOS.pas',
  Systematic.MacAddress in '..\..\CmnUnits\Systematic.MacAddress.pas',
  fTestClient in 'Forms\fTestClient.pas' {frmTestClient},
  fVatFresh in 'Forms\fVatFresh.pas' {frmVatFresh},
  fVatSaved in 'Forms\fVatSaved.pas' {frmVatSaved},
  fVrnCheck in 'Forms\fVrnCheck.pas' {frmVrnCheck},
  HmrcHeaders in '..\..\CmnUnits\HmrcHeaders.pas',
  Systematic.AppVersion in '..\..\CmnUnits\Systematic.AppVersion.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmHMRCDemoMain, frmHMRCDemoMain);
  Application.Run;
end.
