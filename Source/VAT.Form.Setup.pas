{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Form.Setup;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls;

type
  TSetupForm = class(TForm)
    DataPathLabel: TLabel;
    DataPathEdit: TEdit;
    FirstNameLabel: TLabel;
    FirstNameEdit: TEdit;
    LastNameLabel: TLabel;
    LastNameEdit: TEdit;
    UserNameLabel: TLabel;
    UserNameEdit: TEdit;
    PasswordLabel: TLabel;
    PasswordEdit: TEdit;
    OrganisationLabel: TLabel;
    OrganisationEdit: TEdit;
    VrnLabel: TLabel;
    VrnEdit: TEdit;
    NoticeLabel: TLabel;
    OkButton: TButton;
    CancelButton: TButton;
    procedure FormCreate(Sender: TObject);
  end;

var
  SetupForm: TSetupForm;

implementation

{$R *.dfm}

uses
  VAT.App.Settings;

procedure TSetupForm.FormCreate(Sender: TObject);
begin
  {$IFDEF DEBUG}
  Caption := Caption + ' (TEST)';
  NoticeLabel.Visible := True;
  OrganisationLabel.Visible := False;
  OrganisationEdit.Visible := False;
  VrnLabel.Visible := False;
  VrnEdit.Visible := False;
  FirstNameEdit.Text := DebugFirstName;
  LastNameEdit.Text := DebugLastName;
  UserNameEdit.Text := DebugUserName;
  PasswordEdit.Text := DebugPassword;
  {$ENDIF}
end;

end.
