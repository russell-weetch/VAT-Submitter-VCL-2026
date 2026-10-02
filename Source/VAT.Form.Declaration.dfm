object DeclarationForm: TDeclarationForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Declare and submit'
  ClientHeight = 420
  ClientWidth = 560
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object TitleLabel: TLabel
    Left = 16
    Top = 12
    Width = 296
    Height = 15
    Caption = 'Check the nine boxes before you send them to HMRC.'
  end
  object LegalLabel: TLabel
    Left = 16
    Top = 276
    Width = 528
    Height = 80
    AutoSize = False
    Caption =
      'When you submit this VAT information you are making a legal declaration that the information is true and complete. A false declaration can result in prosecution.'
    WordWrap = True
  end
  object SummaryMemo: TMemo
    Left = 16
    Top = 40
    Width = 528
    Height = 220
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object SubmitButton: TButton
    Left = 360
    Top = 376
    Width = 84
    Height = 28
    Caption = 'Submit'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object CancelButton: TButton
    Left = 456
    Top = 376
    Width = 84
    Height = 28
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
