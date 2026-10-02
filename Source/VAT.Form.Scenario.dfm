object ScenarioForm: TScenarioForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Gov-Test-Scenario'
  ClientHeight = 280
  ClientWidth = 560
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object ScenarioList: TListBox
    Left = 16
    Top = 16
    Width = 528
    Height = 210
    ItemHeight = 15
    TabOrder = 0
  end
  object UseButton: TButton
    Left = 360
    Top = 240
    Width = 84
    Height = 28
    Caption = 'Use'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object CancelButton: TButton
    Left = 452
    Top = 240
    Width = 84
    Height = 28
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
