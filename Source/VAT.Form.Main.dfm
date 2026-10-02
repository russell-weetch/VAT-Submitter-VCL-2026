object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'VAT Submitter'
  ClientHeight = 700
  ClientWidth = 1100
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object StatusBar: TStatusBar
    Left = 0
    Top = 681
    Width = 1100
    Height = 19
    Align = alBottom
    SimplePanel = True
  end
  object NavPanel: TPanel
    Left = 0
    Top = 0
    Width = 160
    Height = 681
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    object ObligationsButton: TButton
      Left = 12
      Top = 16
      Width = 136
      Height = 32
      Caption = 'Obligations'
      TabOrder = 0
      Tag = 0
      OnClick = NavigateClick
    end
    object ReturnButton: TButton
      Left = 12
      Top = 56
      Width = 136
      Height = 32
      Caption = 'VAT return'
      TabOrder = 1
      Tag = 1
      OnClick = NavigateClick
    end
    object LiabilitiesButton: TButton
      Left = 12
      Top = 96
      Width = 136
      Height = 32
      Caption = 'Liabilities'
      TabOrder = 2
      Tag = 2
      OnClick = NavigateClick
    end
    object SettingsButton: TButton
      Left = 12
      Top = 136
      Width = 136
      Height = 32
      Caption = 'Settings'
      TabOrder = 3
      Tag = 3
      OnClick = NavigateClick
    end
    object UsersButton: TButton
      Left = 12
      Top = 176
      Width = 136
      Height = 32
      Caption = 'Users'
      TabOrder = 4
      Tag = 4
      OnClick = NavigateClick
    end
  end
  object Pages: TPageControl
    Left = 160
    Top = 0
    Width = 940
    Height = 681
    Align = alClient
    TabOrder = 1
    object TabObligations: TTabSheet
      Caption = 'Obligations'
      inline ObligationsPageFrame: TObligationsFrame
        Left = 0
        Top = 0
        Width = 932
        Height = 653
        Align = alClient
        TabOrder = 0
      end
    end
    object TabReturn: TTabSheet
      Caption = 'VAT return'
      inline ReturnPageFrame: TReturnFrame
        Left = 0
        Top = 0
        Width = 932
        Height = 653
        Align = alClient
        TabOrder = 0
      end
    end
    object TabLiabilities: TTabSheet
      Caption = 'Liabilities'
      inline LiabilitiesPageFrame: TLiabilitiesFrame
        Left = 0
        Top = 0
        Width = 932
        Height = 653
        Align = alClient
        TabOrder = 0
      end
    end
    object TabSettings: TTabSheet
      Caption = 'Settings'
      inline SettingsPageFrame: TSettingsFrame
        Left = 0
        Top = 0
        Width = 932
        Height = 653
        Align = alClient
        TabOrder = 0
      end
    end
    object TabUsers: TTabSheet
      Caption = 'Users'
      inline UsersPageFrame: TUsersFrame
        Left = 0
        Top = 0
        Width = 932
        Height = 653
        Align = alClient
        TabOrder = 0
      end
    end
  end
end
