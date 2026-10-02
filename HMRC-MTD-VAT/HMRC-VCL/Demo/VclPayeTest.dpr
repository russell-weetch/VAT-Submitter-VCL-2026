program VclPayeTest;

uses
  Vcl.Forms,
  fVPTMain in 'fVPTMain.pas' {frmVPTMain},
  HmrcRestSupport in '..\..\CmnUnits\HmrcRestSupport.pas',
  HmrcRestClient in '..\..\CmnUnits\HmrcRestClient.pas',
  HmrcSASupport in '..\..\CmnUnits\HmrcSASupport.pas',
  HmrcSAClient in '..\..\CmnUnits\HmrcSAClient.pas',
  fVclHmrcBase in 'Forms\fVclHmrcBase.pas' {frmVclHmrcBase},
  fTestSA in 'Forms\fTestSA.pas' {frmTestSA},
  HmrcHeaders in '..\..\CmnUnits\HmrcHeaders.pas',
  Systematic.AppVersion in '..\..\CmnUnits\Systematic.AppVersion.pas',
  Systematic.MacAddress in '..\..\CmnUnits\Systematic.MacAddress.pas',
  uSMBIOS in '..\..\CmnUnits\uSMBIOS.pas',
  VAT.Headers.Utils in '..\..\CmnUnits\VAT.Headers.Utils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmVPTMain, frmVPTMain);
  Application.Run;
end.
