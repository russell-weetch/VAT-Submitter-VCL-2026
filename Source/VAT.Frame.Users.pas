{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Frame.Users;

interface

uses
  System.Classes,
  Data.DB,
  Datasnap.DBClient,
  Vcl.Controls,
  Vcl.DBGrids,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Grids,
  Vcl.StdCtrls;

type
  TUsersFrame = class(TFrame)
    HeaderPanel: TPanel;
    UserNameLabel: TLabel;
    PasswordLabel: TLabel;
    UserNameEdit: TEdit;
    PasswordEdit: TEdit;
    AddButton: TButton;
    UsersGrid: TDBGrid;
    UserSource: TDataSource;
    Users: TClientDataSet;
    procedure AddButtonClick(Sender: TObject);
  private
    procedure EnsureData;
  protected
    procedure Loaded; override;
  public
    procedure LoadRows;
  end;

implementation

{$R *.dfm}

uses
  System.Generics.Collections,
  System.SysUtils,
  Vcl.Dialogs,
  VAT.DataModule,
  VAT.Entity.User,
  VAT.Enumerations;

procedure TUsersFrame.Loaded;
begin
  inherited;
  EnsureData;
end;

procedure TUsersFrame.EnsureData;
begin
  if not Users.Active then
    Users.CreateDataSet;
end;

procedure TUsersFrame.LoadRows;
var
  Items: TList<TVATUser>;
  Item: TVATUser;
begin
  EnsureData;
  Users.EmptyDataSet;
  if (VatDataModule = nil) or (VatDataModule.Store = nil) then
    Exit;
  Items := VatDataModule.Store.ListUsers;
  try
    for Item in Items do
    begin
      Users.Append;
      Users.FieldByName('UserName').AsString := Item.UserName;
      Users.FieldByName('Name').AsString := Item.FullName;
      Users.FieldByName('Status').AsString := UserStatusText(Item.Status);
      Users.FieldByName('Level').AsString := UserLevelText(Item.Level);
      Users.Post;
    end;
  finally
    Items.Free;
  end;
end;

procedure TUsersFrame.AddButtonClick(Sender: TObject);
begin
  if not VatDataModule.IsAdmin then
    Exit;
  if (Trim(UserNameEdit.Text) = '') or (Trim(PasswordEdit.Text) = '') then
  begin
    ShowMessage('Enter a user name and password.');
    Exit;
  end;
  VatDataModule.Store.AddUser('', '', UserNameEdit.Text, PasswordEdit.Text, usWrite, ulStandard,
    VatDataModule.CurrentUser.Id);
  UserNameEdit.Text := '';
  PasswordEdit.Text := '';
  LoadRows;
end;

end.
