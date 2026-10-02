inherited frmTestClient: TfrmTestClient
  Caption = 'Test API Client'
  ClientHeight = 361
  OnCreate = FormCreate
  ExplicitHeight = 400
  PixelsPerInch = 96
  TextHeight = 13
  object btnHelloWorld: TBitBtn
    Left = 464
    Top = 33
    Width = 129
    Height = 33
    Caption = 'Hello World'
    TabOrder = 0
    OnClick = btnHelloWorldClick
  end
  object btnHelloApp: TBitBtn
    Left = 464
    Top = 89
    Width = 129
    Height = 33
    Caption = 'Hello App'
    TabOrder = 1
    OnClick = btnHelloAppClick
  end
  object btnHelloUser: TBitBtn
    Left = 464
    Top = 145
    Width = 129
    Height = 33
    Caption = 'Hello User'
    TabOrder = 2
    OnClick = btnHelloUserClick
  end
  object btnHeaders: TBitBtn
    Left = 32
    Top = 145
    Width = 129
    Height = 33
    Caption = 'Test Fraud Headers'
    TabOrder = 3
    OnClick = btnHeadersClick
  end
  object btnAgent: TBitBtn
    Left = 248
    Top = 33
    Width = 129
    Height = 33
    Caption = 'New Agent'
    TabOrder = 4
    OnClick = btnAgentClick
  end
  object btnCo: TBitBtn
    Left = 248
    Top = 89
    Width = 129
    Height = 33
    Caption = 'New Company'
    TabOrder = 5
    OnClick = btnCoClick
  end
  object btnPerson: TBitBtn
    Left = 248
    Top = 145
    Width = 129
    Height = 33
    Caption = 'New Person'
    TabOrder = 6
    OnClick = btnPersonClick
  end
  object btnServices: TBitBtn
    Left = 32
    Top = 89
    Width = 129
    Height = 33
    Caption = 'Get Services'
    TabOrder = 7
    OnClick = btnServicesClick
  end
  object mmoInfo: TMemo
    Left = 32
    Top = 200
    Width = 561
    Height = 145
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssBoth
    TabOrder = 8
  end
end
