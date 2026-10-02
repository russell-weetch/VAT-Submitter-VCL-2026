object ReturnFrame: TReturnFrame
  Left = 0
  Top = 0
  Width = 900
  Height = 620
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  object PeriodLabel: TLabel
    Left = 16
    Top = 16
    Width = 59
    Height = 15
    Caption = 'Period key'
  end
  object Box1Label: TLabel
    Left = 16
    Top = 68
    Width = 32
    Height = 15
    Caption = 'Box 1'
  end
  object Box2Label: TLabel
    Left = 16
    Top = 100
    Width = 32
    Height = 15
    Caption = 'Box 2'
  end
  object Box3Label: TLabel
    Left = 16
    Top = 132
    Width = 32
    Height = 15
    Caption = 'Box 3'
  end
  object Box4Label: TLabel
    Left = 16
    Top = 164
    Width = 32
    Height = 15
    Caption = 'Box 4'
  end
  object Box5Label: TLabel
    Left = 16
    Top = 196
    Width = 32
    Height = 15
    Caption = 'Box 5'
  end
  object Box6Label: TLabel
    Left = 16
    Top = 228
    Width = 32
    Height = 15
    Caption = 'Box 6'
  end
  object Box7Label: TLabel
    Left = 16
    Top = 260
    Width = 32
    Height = 15
    Caption = 'Box 7'
  end
  object Box8Label: TLabel
    Left = 16
    Top = 292
    Width = 32
    Height = 15
    Caption = 'Box 8'
  end
  object Box9Label: TLabel
    Left = 16
    Top = 324
    Width = 32
    Height = 15
    Caption = 'Box 9'
  end
  object PaymentLabel: TLabel
    Left = 320
    Top = 68
    Width = 280
    Height = 15
    AutoSize = False
  end
  object ProcessedLabel: TLabel
    Left = 320
    Top = 16
    Width = 320
    Height = 15
    Caption = 'This return has been processed and cannot be changed.'
    Visible = False
  end
  object PeriodEdit: TEdit
    Left = 110
    Top = 12
    Width = 80
    Height = 23
    TabOrder = 0
  end
  object Box1Edit: TEdit
    Left = 110
    Top = 64
    Width = 160
    Height = 23
    TabOrder = 1
    Text = '0'
    OnChange = BoxEditChange
  end
  object Box2Edit: TEdit
    Left = 110
    Top = 96
    Width = 160
    Height = 23
    TabOrder = 2
    Text = '0'
    OnChange = BoxEditChange
  end
  object Box3Edit: TEdit
    Left = 110
    Top = 128
    Width = 160
    Height = 23
    ReadOnly = True
    TabOrder = 3
    Text = '0'
  end
  object Box4Edit: TEdit
    Left = 110
    Top = 160
    Width = 160
    Height = 23
    TabOrder = 4
    Text = '0'
    OnChange = BoxEditChange
  end
  object Box5Edit: TEdit
    Left = 110
    Top = 192
    Width = 160
    Height = 23
    ReadOnly = True
    TabOrder = 5
    Text = '0'
  end
  object Box6Edit: TEdit
    Left = 110
    Top = 224
    Width = 160
    Height = 23
    TabOrder = 6
    Text = '0'
    OnChange = BoxEditChange
  end
  object Box7Edit: TEdit
    Left = 110
    Top = 256
    Width = 160
    Height = 23
    TabOrder = 7
    Text = '0'
    OnChange = BoxEditChange
  end
  object Box8Edit: TEdit
    Left = 110
    Top = 288
    Width = 160
    Height = 23
    TabOrder = 8
    Text = '0'
    OnChange = BoxEditChange
  end
  object Box9Edit: TEdit
    Left = 110
    Top = 320
    Width = 160
    Height = 23
    TabOrder = 9
    Text = '0'
    OnChange = BoxEditChange
  end
  object SaveButton: TButton
    Left = 320
    Top = 120
    Width = 120
    Height = 28
    Caption = 'Save'
    TabOrder = 10
    OnClick = SaveButtonClick
  end
  object ImportButton: TButton
    Left = 320
    Top = 156
    Width = 120
    Height = 28
    Caption = 'Import CSV'
    TabOrder = 11
    OnClick = ImportButtonClick
  end
  object SubmitButton: TButton
    Left = 320
    Top = 192
    Width = 120
    Height = 28
    Caption = 'Submit'
    TabOrder = 12
    OnClick = SubmitButtonClick
  end
  object FetchButton: TButton
    Left = 320
    Top = 228
    Width = 120
    Height = 28
    Caption = 'View at HMRC'
    TabOrder = 13
    OnClick = FetchButtonClick
  end
  object ImportDialog: TOpenDialog
    Filter = 'CSV files|*.csv'
    Left = 480
    Top = 120
  end
end
