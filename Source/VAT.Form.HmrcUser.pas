{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Form.HmrcUser;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls;

type
  THmrcUserForm = class(TForm)
    PromptLabel: TLabel;
    UserIdLabel: TLabel;
    PasswordLabel: TLabel;
    UserIdEdit: TEdit;
    PasswordEdit: TEdit;
    CopyUserButton: TButton;
    CopyPasswordButton: TButton;
    CloseButton: TButton;
    procedure CopyUserButtonClick(Sender: TObject);
    procedure CopyPasswordButtonClick(Sender: TObject);
    procedure ShowDetails(const UserId, Password: string);
  end;

var
  HmrcUserForm: THmrcUserForm;

procedure ShowHmrcUser(const UserId, Password: string);

implementation

{$R *.dfm}

uses
  System.SysUtils,
  Vcl.Clipbrd;

procedure THmrcUserForm.CopyUserButtonClick(Sender: TObject);
begin
  Clipboard.AsText := UserIdEdit.Text;
end;

procedure THmrcUserForm.CopyPasswordButtonClick(Sender: TObject);
begin
  Clipboard.AsText := PasswordEdit.Text;
end;

procedure THmrcUserForm.ShowDetails(const UserId, Password: string);
begin
  UserIdEdit.Text := UserId;
  PasswordEdit.Text := Password;
  Show;
end;

procedure ShowHmrcUser(const UserId, Password: string);
begin
  if Trim(UserId) = '' then
    Exit;
  if HmrcUserForm = nil then
    HmrcUserForm := THmrcUserForm.Create(Application);
  HmrcUserForm.ShowDetails(UserId, Password);
end;

end.
