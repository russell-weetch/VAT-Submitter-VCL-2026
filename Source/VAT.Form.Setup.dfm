object SetupForm: TSetupForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Set up VAT Submitter'
  ClientHeight = 336
  ClientWidth = 500
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object DataPathLabel: TLabel
    Left = 16
    Top = 16
    Width = 63
    Height = 15
    Caption = 'Data folder'
  end
  object FirstNameLabel: TLabel
    Left = 16
    Top = 56
    Width = 57
    Height = 15
    Caption = 'First name'
  end
  object LastNameLabel: TLabel
    Left = 16
    Top = 96
    Width = 57
    Height = 15
    Caption = 'Last name'
  end
  object UserNameLabel: TLabel
    Left = 16
    Top = 136
    Width = 62
    Height = 15
    Caption = 'User name'
  end
  object PasswordLabel: TLabel
    Left = 16
    Top = 176
    Width = 57
    Height = 15
    Caption = 'Password'
  end
  object OrganisationLabel: TLabel
    Left = 16
    Top = 216
    Width = 75
    Height = 15
    Caption = 'Organisation'
  end
  object VrnLabel: TLabel
    Left = 16
    Top = 256
    Width = 70
    Height = 15
    Caption = 'VAT number'
  end
  object NoticeLabel: TLabel
    Left = 16
    Top = 216
    Width = 460
    Height = 32
    AutoSize = False
    Caption = 'HMRC creates the sandbox company, VAT number, and sign-in after you click Create.'
    Visible = False
    WordWrap = True
  end
  object DataPathEdit: TEdit
    Left = 160
    Top = 12
    Width = 320
    Height = 23
    TabOrder = 0
  end
  object FirstNameEdit: TEdit
    Left = 160
    Top = 52
    Width = 320
    Height = 23
    TabOrder = 1
  end
  object LastNameEdit: TEdit
    Left = 160
    Top = 92
    Width = 320
    Height = 23
    TabOrder = 2
  end
  object UserNameEdit: TEdit
    Left = 160
    Top = 132
    Width = 320
    Height = 23
    TabOrder = 3
  end
  object PasswordEdit: TEdit
    Left = 160
    Top = 172
    Width = 320
    Height = 23
    PasswordChar = '*'
    TabOrder = 4
  end
  object OrganisationEdit: TEdit
    Left = 160
    Top = 212
    Width = 320
    Height = 23
    TabOrder = 5
  end
  object VrnEdit: TEdit
    Left = 160
    Top = 252
    Width = 160
    Height = 23
    TabOrder = 6
  end
  object OkButton: TButton
    Left = 300
    Top = 296
    Width = 84
    Height = 28
    Caption = 'Create'
    Default = True
    ModalResult = 1
    TabOrder = 7
  end
  object CancelButton: TButton
    Left = 396
    Top = 296
    Width = 84
    Height = 28
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 8
  end
end
