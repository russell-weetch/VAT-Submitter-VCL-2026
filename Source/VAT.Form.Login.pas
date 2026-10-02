{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Form.Login;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls;

type
  TLoginForm = class(TForm)
    UserNameLabel: TLabel;
    UserNameEdit: TEdit;
    PasswordLabel: TLabel;
    PasswordEdit: TEdit;
    OkButton: TButton;
    CancelButton: TButton;
    procedure FormCreate(Sender: TObject);
  end;

var
  LoginForm: TLoginForm;

implementation

{$R *.dfm}

uses
  VAT.App.Settings;

procedure TLoginForm.FormCreate(Sender: TObject);
begin
  {$IFDEF DEBUG}
  UserNameEdit.Text := DebugUserName;
  PasswordEdit.Text := DebugPassword;
  {$ENDIF}
end;

end.
