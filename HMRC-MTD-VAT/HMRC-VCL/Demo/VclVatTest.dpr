program VclVatTest;

uses
  Vcl.Forms,
  fVclTestMain in 'fVclTestMain.pas' {frmVclTestMain},
  HmrcRestClient in '..\..\CmnUnits\HmrcRestClient.pas',
  HmrcRestSupport in '..\..\CmnUnits\HmrcRestSupport.pas',
  HmrcVatClient in '..\..\CmnUnits\HmrcVatClient.pas',
  Systematic.MacAddress in '..\..\CmnUnits\Systematic.MacAddress.pas',
  uSMBIOS in '..\..\CmnUnits\uSMBIOS.pas',
  VAT.Headers.Utils in '..\..\CmnUnits\VAT.Headers.Utils.pas',
  HmrcVatSupport in '..\..\CmnUnits\HmrcVatSupport.pas',
  HmrcTestClient in '..\..\CmnUnits\HmrcTestClient.pas',
  HmrcTestSupport in '..\..\CmnUnits\HmrcTestSupport.pas',
  HmrcHeaders in '..\..\CmnUnits\HmrcHeaders.pas',
  Systematic.AppVersion in '..\..\CmnUnits\Systematic.AppVersion.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmVclTestMain, frmVclTestMain);
  Application.Run;
end.
