object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'AntSim'
  ClientHeight = 644
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
                Caption = '&New Session'
                ShortCut = 16462
              end
              item
                Caption = '-'
              end
              item
                Action = actExit
                ImageIndex = 43
              end>
            Caption = '&File'
          end>
        ActionBar = ActionMainMenuBar1
      end>
    Left = 72
    Top = 288
    StyleName = 'Platform Default'
    object actExit: TFileExit
      Category = 'File'
      Caption = 'E&xit'
      Hint = 'Exit|Quits the application'
      ImageIndex = 43
    end
    object actNewSession: TAction
      Category = 'File'
      Caption = 'New Session'
      ShortCut = 16462
      OnExecute = actNewSessionExecute
    end
  end
end
