inherited frmPAYESetup: TfrmPAYESetup
  Caption = 'PAYE/SA Test Data Setup'
  ClientHeight = 610
  ClientWidth = 636
  OnCreate = FormCreate
  ExplicitWidth = 652
  ExplicitHeight = 649
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 176
    Top = 28
    Width = 20
    Height = 13
    Caption = 'UTR'
  end
  object Label2: TLabel
    Left = 472
    Top = 28
    Width = 43
    Height = 13
    Caption = 'Tax Year'
  end
  object Bevel1: TBevel
    Left = 169
    Top = 16
    Width = 459
    Height = 41
    Shape = bsFrame
  end
  object Label3: TLabel
    Left = 329
    Top = 145
    Width = 31
    Height = 13
    Caption = 'Status'
  end
  object Bevel2: TBevel
    Left = 168
    Top = 135
    Width = 298
    Height = 59
    Shape = bsFrame
  end
  object Label4: TLabel
    Left = 336
    Top = 28
    Width = 26
    Height = 13
    Caption = 'NINO'
  end
  object mmoInfo: TMemo
    Left = 8
    Top = 208
    Width = 620
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
  end
  object Button1: TButton
    Left = 8
    Top = 72
    Width = 137
    Height = 41
    Caption = 'Benefits'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 168
    Top = 72
    Width = 137
    Height = 41
    Caption = 'Employments'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 329
    Top = 72
    Width = 137
    Height = 41
    Caption = 'Income'
    TabOrder = 3
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 490
    Top = 72
    Width = 137
    Height = 41
    Caption = 'Tax'
    TabOrder = 4
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 8
    Top = 144
    Width = 137
    Height = 41
    Caption = 'MA Eligibility'
    TabOrder = 5
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 176
    Top = 144
    Width = 129
    Height = 41
    Caption = 'MA Status'
    TabOrder = 6
    OnClick = Button6Click
  end
  object Button7: TButton
    Left = 491
    Top = 144
    Width = 137
    Height = 41
    Caption = 'National Insurance'
    TabOrder = 7
    OnClick = Button7Click
  end
  object edtUTR: TEdit
    Left = 202
    Top = 25
    Width = 103
    Height = 21
    MaxLength = 10
    NumbersOnly = True
    TabOrder = 8
    TextHint = 'UTR'
    OnExit = edtUTRExit
  end
  object cbxYear: TComboBox
    Left = 521
    Top = 25
    Width = 96
    Height = 21
    ItemIndex = 2
    TabOrder = 9
    Text = '2019-20'
    Items.Strings = (
      '2017-18'
      '2018-19'
      '2019-20'
      '2020-21'
      '2021-22')
  end
  object cbxMAStatus: TComboBox
    Left = 329
    Top = 162
    Width = 101
    Height = 21
    ItemIndex = 0
    TabOrder = 10
    Text = 'Transferor'
    Items.Strings = (
      'Transferor'
      'Recipient'
      'None')
  end
  object edtNino: TEdit
    Left = 368
    Top = 25
    Width = 89
    Height = 21
    MaxLength = 10
    TabOrder = 11
    TextHint = 'UTR'
  end
end
