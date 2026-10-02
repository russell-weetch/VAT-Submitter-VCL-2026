object ObligationsFrame: TObligationsFrame
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
    object RefreshButton: TButton
      Left = 400
      Top = 10
      Width = 160
      Height = 28
      Caption = 'Refresh from HMRC'
      TabOrder = 2
      OnClick = RefreshButtonClick
    end
  end
  object ObligationsGrid: TDBGrid
    Left = 0
    Top = 48
    Width = 900
    Height = 512
    Align = alClient
    DataSource = ObligationSource
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete]
    TabOrder = 1
    OnDblClick = ObligationsGridDblClick
  end
  object ObligationSource: TDataSource
    DataSet = Obligations
    Left = 640
    Top = 64
  end
  object Obligations: TClientDataSet
    Aggregates = <>
    FieldDefs = <
      item
        Name = 'PeriodKey'
        DataType = ftString
        Size = 16
      end
      item
        Name = 'PeriodStart'
        DataType = ftDate
      end
      item
        Name = 'PeriodEnd'
        DataType = ftDate
      end
      item
        Name = 'Due'
        DataType = ftDate
      end
      item
        Name = 'Status'
        DataType = ftString
        Size = 8
      end
      item
        Name = 'ReturnStatus'
        DataType = ftString
        Size = 20
      end>
    IndexDefs = <>
    Params = <>
    StoreDefs = True
    Left = 720
    Top = 64
  end
end
