object LoginForm: TLoginForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Sign in'
  ClientHeight = 160
  ClientWidth = 380
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object UserNameLabel: TLabel
    Left = 16
    Top = 16
    Width = 62
    Height = 15
    Caption = 'User name'
  end
  object PasswordLabel: TLabel
    Left = 16
    Top = 68
    Width = 57
    Height = 15
    Caption = 'Password'
  end
  object UserNameEdit: TEdit
    Left = 16
    Top = 36
    Width = 348
    Height = 23
    TabOrder = 0
  end
  object PasswordEdit: TEdit
    Left = 16
    Top = 88
    Width = 348
    Height = 23
    PasswordChar = '*'
    TabOrder = 1
  end
  object OkButton: TButton
    Left = 188
    Top = 124
    Width = 84
    Height = 28
    Caption = 'Sign in'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
  object CancelButton: TButton
    Left = 280
    Top = 124
    Width = 84
    Height = 28
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end
