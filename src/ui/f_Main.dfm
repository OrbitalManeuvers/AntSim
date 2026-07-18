object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'AntSim'
  ClientHeight = 963
  ClientWidth = 1066
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object ActionMainMenuBar1: TActionMainMenuBar
    Left = 0
    Top = 0
    Width = 1066
    Height = 25
    UseSystemFont = False
    ActionManager = MainActions
    Caption = 'ActionMainMenuBar1'
    Color = clMenuBar
    ColorMap.DisabledFontColor = 10461087
    ColorMap.HighlightColor = clWhite
    ColorMap.BtnSelectedFont = clBlack
    ColorMap.UnusedColor = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    Spacing = 0
  end
  object MainActions: TActionManager
    ActionBars = <
      item
        Items = <
          item
            Items = <
              item
                Action = actNewSession
                Caption = '&New Session...'
                ShortCut = 16462
              end
              item
                Action = actSaveSession
                ShortCut = 16467
              end
              item
                Caption = '-'
              end
              item
                Action = actExit
                ImageIndex = 43
                ShortCut = 32856
              end>
            Caption = '&File'
          end>
        ActionBar = ActionMainMenuBar1
      end>
    Left = 72
    Top = 288
    StyleName = 'Platform Default'
    object actNewSession: TAction
      Category = 'File'
      Caption = 'New Session...'
      ShortCut = 16462
      OnExecute = actNewSessionExecute
    end
    object actSaveSession: TAction
      Category = 'File'
      Caption = 'Save Session'
      ShortCut = 16467
      OnExecute = actSaveSessionExecute
    end
    object actExit: TFileExit
      Category = 'File'
      Caption = 'E&xit'
      Hint = 'Exit|Quits the application'
      ImageIndex = 43
      ShortCut = 32856
    end
  end
end
