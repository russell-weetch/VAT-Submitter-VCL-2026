program MTDCoreTests;

uses
  Vcl.Forms,
  fCoreTestMain in 'fCoreTestMain.pas' {frmCoreTestMain},
  fVclHmrcBase in 'Forms\fVclHmrcBase.pas' {frmVclHmrcBase},
  fTestClient in 'Forms\fTestClient.pas' {frmTestClient},
  HmrcHeaders in '..\..\CmnUnits\HmrcHeaders.pas',
  HmrcRestClient in '..\..\CmnUnits\HmrcRestClient.pas',
  HmrcRestSupport in '..\..\CmnUnits\HmrcRestSupport.pas',
  HmrcTestClient in '..\..\CmnUnits\HmrcTestClient.pas',
  HmrcTestSupport in '..\..\CmnUnits\HmrcTestSupport.pas',
  Systematic.AppVersion in '..\..\CmnUnits\Systematic.AppVersion.pas',
  Systematic.MacAddress in '..\..\CmnUnits\Systematic.MacAddress.pas',
  uSMBIOS in '..\..\CmnUnits\uSMBIOS.pas',
  VAT.Headers.Utils in '..\..\CmnUnits\VAT.Headers.Utils.pas',
  fPayeSetup in 'Forms\fPayeSetup.pas' {frmPAYESetup};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmCoreTestMain, frmCoreTestMain);
  Application.Run;
end.
