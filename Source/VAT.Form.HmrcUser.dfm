object HmrcUserForm: THmrcUserForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'HMRC sandbox sign in'
  ClientHeight = 210
  ClientWidth = 460
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  FormStyle = fsStayOnTop
  Position = poScreenCenter
  TextHeight = 15
  object PromptLabel: TLabel
    Left = 16
    Top = 12
    Width = 428
    Height = 40
    AutoSize = False
    Caption = 'Use these HMRC sandbox details in the browser. Right-click a field there and choose Paste.'
    WordWrap = True
  end
  object UserIdLabel: TLabel
    Left = 16
    Top = 68
    Width = 42
    Height = 15
    Caption = 'User id'
  end
  object PasswordLabel: TLabel
    Left = 16
    Top = 108
    Width = 57
    Height = 15
    Caption = 'Password'
  end
  object UserIdEdit: TEdit
    Left = 100
    Top = 64
    Width = 230
    Height = 23
    ReadOnly = True
    TabOrder = 0
  end
  object PasswordEdit: TEdit
    Left = 100
    Top = 104
    Width = 230
    Height = 23
    ReadOnly = True
    TabOrder = 1
  end
  object CopyUserButton: TButton
    Left = 340
    Top = 62
    Width = 100
    Height = 28
    Caption = 'Copy user'
    TabOrder = 2
    OnClick = CopyUserButtonClick
  end
  object CopyPasswordButton: TButton
    Left = 340
    Top = 102
    Width = 100
    Height = 28
    Caption = 'Copy password'
    TabOrder = 3
    OnClick = CopyPasswordButtonClick
  end
  object CloseButton: TButton
    Left = 340
    Top = 164
    Width = 100
    Height = 28
    Cancel = True
    Caption = 'Close'
    ModalResult = 2
    TabOrder = 4
  end
end
