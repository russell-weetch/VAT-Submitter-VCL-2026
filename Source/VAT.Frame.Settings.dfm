object SettingsFrame: TSettingsFrame
  Left = 0
  Top = 0
  Width = 720
  Height = 420
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  object OrganisationLabel: TLabel
    Left = 16
    Top = 20
    Width = 75
    Height = 15
    Caption = 'Organisation'
  end
  object VrnLabel: TLabel
    Left = 16
    Top = 56
    Width = 70
    Height = 15
    Caption = 'VAT number'
  end
  object ClientIdLabel: TLabel
    Left = 16
    Top = 92
    Width = 79
    Height = 15
    Caption = 'HMRC client id'
  end
  object ClientSecretLabel: TLabel
    Left = 16
    Top = 128
    Width = 104
    Height = 15
    Caption = 'HMRC client secret'
  end
  object ModeLabel: TLabel
    Left = 16
    Top = 164
    Width = 70
    Height = 15
    Caption = 'Environment'
  end
  object ScenarioLabel: TLabel
    Left = 16
    Top = 200
    Width = 107
    Height = 15
    Caption = 'Gov-Test-Scenario'
  end
  object HmrcUserLabel: TLabel
    Left = 16
    Top = 292
    Width = 76
    Height = 15
    Caption = 'HMRC user id'
  end
  object HmrcPasswordLabel: TLabel
    Left = 16
    Top = 328
    Width = 91
    Height = 15
    Caption = 'HMRC password'
  end
  object OrganisationEdit: TEdit
    Left = 170
    Top = 16
    Width = 320
    Height = 23
    TabOrder = 0
  end
  object VrnEdit: TEdit
    Left = 170
    Top = 52
    Width = 160
    Height = 23
    TabOrder = 1
  end
  object ClientIdEdit: TEdit
    Left = 170
    Top = 88
    Width = 320
    Height = 23
    TabOrder = 2
  end
  object ClientSecretEdit: TEdit
    Left = 170
    Top = 124
    Width = 320
    Height = 23
    PasswordChar = '*'
    TabOrder = 3
  end
  object ModeCombo: TComboBox
    Left = 170
    Top = 160
    Width = 160
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 4
    Text = 'Test'
    Items.Strings = (
      'Test'
      'Live')
  end
  object ScenarioEdit: TEdit
    Left = 170
    Top = 196
    Width = 320
    Height = 23
    TabOrder = 5
  end
  object SaveButton: TButton
    Left = 170
    Top = 240
    Width = 120
    Height = 28
    Caption = 'Save settings'
    TabOrder = 6
    OnClick = SaveButtonClick
  end
  object SignInButton: TButton
    Left = 300
    Top = 240
    Width = 140
    Height = 28
    Caption = 'Sign in to HMRC'
    TabOrder = 7
    OnClick = SignInButtonClick
  end
  object HmrcUserEdit: TEdit
    Left = 170
    Top = 288
    Width = 320
    Height = 23
    ReadOnly = True
    TabOrder = 8
  end
  object HmrcPasswordEdit: TEdit
    Left = 170
    Top = 324
    Width = 320
    Height = 23
    ReadOnly = True
    TabOrder = 9
  end
  object CreateCompanyButton: TButton
    Left = 170
    Top = 364
    Width = 160
    Height = 28
    Caption = 'Create test company'
    TabOrder = 10
    OnClick = CreateCompanyButtonClick
  end
end
