program VclRestTest;

uses
  Vcl.Forms,
  fVclRestTest in 'fVclRestTest.pas' {frmVclRestTest},
  fVat1 in 'fVat1.pas' {frmVat1},
  uSMBIOS in '..\..\CmnUnits\uSMBIOS.pas',
  VAT.Headers.Utils in '..\..\CmnUnits\VAT.Headers.Utils.pas',
  HmrcHeaders in '..\..\CmnUnits\HmrcHeaders.pas',
  Systematic.AppVersion in '..\..\CmnUnits\Systematic.AppVersion.pas',
  Systematic.MacAddress in '..\..\CmnUnits\Systematic.MacAddress.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmVclRestTest, frmVclRestTest);
  Application.Run;
end.
