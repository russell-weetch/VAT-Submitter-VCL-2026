object LiabilitiesFrame: TLiabilitiesFrame
  Left = 0
  Top = 0
  Width = 900
  Height = 560
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  object HeaderPanel: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 48
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object FromLabel: TLabel
      Left = 16
      Top = 16
      Width = 27
      Height = 15
      Caption = 'From'
    end
    object ToLabel: TLabel
      Left = 216
      Top = 16
      Width = 14
      Height = 15
      Caption = 'To'
    end
    object FromPicker: TDateTimePicker
      Left = 56
      Top = 12
      Width = 140
      Height = 23
      Date = 44927.000000000000000000
      Time = 0.000000000000000000
      TabOrder = 0
    end
    object ToPicker: TDateTimePicker
      Left = 240
      Top = 12
      Width = 140
      Height = 23
      Date = 44927.000000000000000000
      Time = 0.000000000000000000
      TabOrder = 1
    end
    object LiabilitiesButton: TButton
      Left = 400
      Top = 10
      Width = 120
      Height = 28
      Caption = 'Liabilities'
      TabOrder = 2
      OnClick = LiabilitiesButtonClick
    end
    object PaymentsButton: TButton
      Left = 532
      Top = 10
      Width = 120
      Height = 28
      Caption = 'Payments'
      TabOrder = 3
      OnClick = PaymentsButtonClick
    end
  end
  object ResultMemo: TMemo
    Left = 0
    Top = 48
    Width = 900
    Height = 512
    Align = alClient
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
end
