object HmrcSignInForm: THmrcSignInForm
  Left = 0
  Top = 0
  Caption = 'Sign in to HMRC'
  ClientHeight = 720
  ClientWidth = 960
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object CredentialPanel: TPanel
    Left = 0
    Top = 632
    Width = 960
    Height = 88
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object PromptLabel: TLabel
      Left = 16
      Top = 8
      Width = 620
      Height = 15
      Caption = 'Copy these HMRC details into the page above. This row stays available while the page is open.'
    end
    object UserIdLabel: TLabel
      Left = 16
      Top = 40
      Width = 42
      Height = 15
      Caption = 'User id'
    end
    object PasswordLabel: TLabel
      Left = 390
      Top = 40
      Width = 57
      Height = 15
      Caption = 'Password'
    end
    object UserIdEdit: TEdit
      Left = 72
      Top = 36
      Width = 220
      Height = 23
      ReadOnly = True
      TabOrder = 0
    end
    object PasswordEdit: TEdit
      Left = 456
      Top = 36
      Width = 220
      Height = 23
      ReadOnly = True
      TabOrder = 1
    end
    object CopyUserButton: TButton
      Left = 300
      Top = 34
      Width = 72
      Height = 28
      Caption = 'Copy'
      TabOrder = 2
      OnClick = CopyUserButtonClick
    end
    object CopyPasswordButton: TButton
      Left = 684
      Top = 34
      Width = 72
      Height = 28
      Caption = 'Copy'
      TabOrder = 3
      OnClick = CopyPasswordButtonClick
    end
  end
  object Browser: TWebBrowser
    Left = 0
    Top = 0
    Width = 960
    Height = 632
    Align = alClient
    TabOrder = 1
    OnBeforeNavigate2 = BrowserBeforeNavigate2
  end
end
