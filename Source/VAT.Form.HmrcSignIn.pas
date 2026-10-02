{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Form.HmrcSignIn;

interface

uses
  System.Classes,
  SHDocVw,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.OleCtrls,
  Vcl.StdCtrls;

type
  THmrcSignInForm = class(TForm)
    CredentialPanel: TPanel;
    PromptLabel: TLabel;
    UserIdLabel: TLabel;
    PasswordLabel: TLabel;
    UserIdEdit: TEdit;
    PasswordEdit: TEdit;
    CopyUserButton: TButton;
    CopyPasswordButton: TButton;
    Browser: TWebBrowser;
    procedure FormCreate(Sender: TObject);
    procedure CopyUserButtonClick(Sender: TObject);
    procedure CopyPasswordButtonClick(Sender: TObject);
    procedure BrowserBeforeNavigate2(ASender: TObject; const pDisp: IDispatch; const URL, Flags,
      TargetFrameName, PostData, Headers: OleVariant; var Cancel: WordBool);
  private
    FCallbackUrl: string;
    FAuthCode: string;
  public
    class function Capture(const AuthorizeUrl, CallbackUrl, UserId, Password: string;
      out AuthCode: string): Boolean;
  end;

var
  HmrcSignInForm: THmrcSignInForm;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  System.Net.URLClient,
  System.Variants,
  Vcl.Clipbrd;

function QueryValue(const Address, Name: string): string;
var
  Uri: TURI;
  Index: Integer;
begin
  Result := '';
  try
    Uri := TURI.Create(Address);
  except
    Exit;
  end;
  for Index := 0 to High(Uri.Params) do
    if SameText(Uri.Params[Index].Name, Name) then
      Exit(Uri.Params[Index].Value);
end;

function IsCallback(const Address, CallbackUrl: string): Boolean;
var
  AddressUri, CallbackUri: TURI;
begin
  Result := False;
  if (Trim(Address) = '') or (Trim(CallbackUrl) = '') then
    Exit;
  try
    AddressUri := TURI.Create(Address);
    CallbackUri := TURI.Create(CallbackUrl);
  except
    Exit;
  end;
  Result := SameText(AddressUri.Scheme, CallbackUri.Scheme) and SameText(AddressUri.Host, CallbackUri.Host) and
    (AddressUri.Port = CallbackUri.Port);
end;

class function THmrcSignInForm.Capture(const AuthorizeUrl, CallbackUrl, UserId, Password: string;
  out AuthCode: string): Boolean;
var
  Form: THmrcSignInForm;
begin
  AuthCode := '';
  Form := THmrcSignInForm.Create(nil);
  try
    Form.FCallbackUrl := CallbackUrl;
    Form.UserIdEdit.Text := UserId;
    Form.PasswordEdit.Text := Password;
    Form.CredentialPanel.Visible := Trim(UserId) <> '';
    Form.Browser.Navigate(AuthorizeUrl);
    Result := Form.ShowModal = mrOk;
    if Result then
      AuthCode := Form.FAuthCode;
  finally
    Form.Free;
  end;
end;

procedure THmrcSignInForm.FormCreate(Sender: TObject);
begin
  Browser.SelectedEngine := TWebBrowser.TSelectedEngine.EdgeIfAvailable;
end;

procedure THmrcSignInForm.CopyUserButtonClick(Sender: TObject);
begin
  Clipboard.AsText := UserIdEdit.Text;
end;

procedure THmrcSignInForm.CopyPasswordButtonClick(Sender: TObject);
begin
  Clipboard.AsText := PasswordEdit.Text;
end;

procedure THmrcSignInForm.BrowserBeforeNavigate2(ASender: TObject; const pDisp: IDispatch; const URL, Flags,
  TargetFrameName, PostData, Headers: OleVariant; var Cancel: WordBool);
var
  Address, Failure: string;
begin
  Address := VarToStr(URL);
  if not IsCallback(Address, FCallbackUrl) then
    Exit;
  Cancel := True;
  FAuthCode := QueryValue(Address, 'code');
  if FAuthCode <> '' then
    ModalResult := mrOk
  else
  begin
    Failure := QueryValue(Address, 'error_description');
    if Failure = '' then
      Failure := QueryValue(Address, 'error');
    if Failure = '' then
      Failure := 'HMRC did not return an authorisation code.';
    raise Exception.Create(Failure);
  end;
end;

end.
