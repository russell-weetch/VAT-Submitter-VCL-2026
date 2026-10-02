object UsersFrame: TUsersFrame
  Left = 0
  Top = 0
  Width = 720
  Height = 480
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
    Width = 720
    Height = 88
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object UserNameLabel: TLabel
      Left = 16
      Top = 8
      Width = 62
      Height = 15
      Caption = 'User name'
    end
    object PasswordLabel: TLabel
      Left = 16
      Top = 48
      Width = 57
      Height = 15
      Caption = 'Password'
    end
    object UserNameEdit: TEdit
      Left = 96
      Top = 4
      Width = 200
      Height = 23
      TabOrder = 0
    end
    object PasswordEdit: TEdit
      Left = 96
      Top = 44
      Width = 200
      Height = 23
      PasswordChar = '*'
      TabOrder = 1
    end
    object AddButton: TButton
      Left = 312
      Top = 42
      Width = 160
      Height = 28
      Caption = 'Add standard user'
      TabOrder = 2
      OnClick = AddButtonClick
    end
  end
  object UsersGrid: TDBGrid
    Left = 0
    Top = 88
    Width = 720
    Height = 392
    Align = alClient
    DataSource = UserSource
    TabOrder = 1
  end
  object UserSource: TDataSource
    DataSet = Users
    Left = 520
    Top = 104
  end
  object Users: TClientDataSet
    Aggregates = <>
    FieldDefs = <
      item
        Name = 'UserName'
        DataType = ftString
        Size = 40
      end
      item
        Name = 'Name'
        DataType = ftString
        Size = 80
      end
      item
        Name = 'Status'
        DataType = ftString
        Size = 20
      end
      item
        Name = 'Level'
        DataType = ftString
        Size = 20
      end>
    IndexDefs = <>
    Params = <>
    StoreDefs = True
    Left = 600
    Top = 104
  end
end
