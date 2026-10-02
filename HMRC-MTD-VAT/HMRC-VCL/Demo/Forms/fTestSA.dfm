inherited frmTestSA: TfrmTestSA
  Caption = 'Test SA Client'
  ClientHeight = 691
  ClientWidth = 530
  OnCreate = FormCreate
  ExplicitWidth = 546
  ExplicitHeight = 730
  PixelsPerInch = 96
  TextHeight = 13
  object lblUID: TLabel
    Left = 196
    Top = 28
    Width = 49
    Height = 13
    Caption = 'UID (UTR)'
  end
  object Label1: TLabel
    Left = 191
    Top = 194
    Width = 47
    Height = 13
    Caption = 'Firstname'
  end
  object Label2: TLabel
    Left = 191
    Top = 221
    Width = 42
    Height = 13
    Caption = 'Surname'
  end
  object Label3: TLabel
    Left = 386
    Top = 194
    Width = 24
    Height = 13
    Caption = 'NINo'
  end
  object Label4: TLabel
    Left = 389
    Top = 221
    Width = 21
    Height = 13
    Caption = 'DOB'
  end
  object Bevel1: TBevel
    Left = 16
    Top = 184
    Width = 497
    Height = 62
    Shape = bsFrame
  end
  object Button1: TButton
    Left = 16
    Top = 64
    Width = 137
    Height = 41
    Caption = 'Benefits'
    TabOrder = 0
    OnClick = Button1Click
  end
  object mmoInfo: TMemo
    Left = 16
    Top = 264
    Width = 497
    Height = 419
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
  end
  object cbxYear: TComboBox
    Left = 416
    Top = 25
    Width = 97
    Height = 21
    ItemIndex = 2
    TabOrder = 2
    Text = '2018-19'
    Items.Strings = (
      '2016-17'
      '2017-18'
      '2018-19'
      '2019-20'
      '2020-21'
      '')
  end
  object edtUID: TEdit
    Left = 251
    Top = 25
    Width = 126
    Height = 21
    NumbersOnly = True
    TabOrder = 3
    TextHint = 'UTR'
    OnExit = edtUIDExit
  end
  object Button2: TButton
    Left = 196
    Top = 64
    Width = 137
    Height = 41
    Caption = 'Employments'
    TabOrder = 4
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 196
    Top = 128
    Width = 137
    Height = 41
    Caption = 'National Insurance'
    TabOrder = 5
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 376
    Top = 128
    Width = 137
    Height = 41
    Caption = 'Tax'
    TabOrder = 6
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 376
    Top = 64
    Width = 137
    Height = 41
    Caption = 'Income'
    TabOrder = 7
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 16
    Top = 128
    Width = 137
    Height = 41
    Caption = 'MA Status'
    TabOrder = 8
    OnClick = Button6Click
  end
  object Button7: TButton
    Left = 24
    Top = 193
    Width = 137
    Height = 41
    Caption = 'MA Eligibility'
    TabOrder = 9
    OnClick = Button7Click
  end
  object edtFname: TEdit
    Left = 244
    Top = 191
    Width = 133
    Height = 21
    TabOrder = 10
    TextHint = 'firstname'
  end
  object edtSname: TEdit
    Left = 244
    Top = 218
    Width = 133
    Height = 21
    TabOrder = 11
    TextHint = 'surname'
  end
  object edtNino: TEdit
    Left = 416
    Top = 191
    Width = 84
    Height = 21
    TabOrder = 12
    TextHint = 'NINo'
  end
  object edtDOB: TEdit
    Left = 416
    Top = 218
    Width = 84
    Height = 21
    TabOrder = 13
    TextHint = 'YYYY-MM-DD'
  end
end
