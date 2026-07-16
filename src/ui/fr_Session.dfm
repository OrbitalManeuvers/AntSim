object SessionFrame: TSessionFrame
  Left = 0
  Top = 0
  Width = 640
  Height = 480
  TabOrder = 0
  object Arena: TSkPaintBox
    Left = 0
    Top = 72
    Width = 640
    Height = 408
    Align = alClient
    OnDraw = ArenaDraw
    ExplicitLeft = 56
    ExplicitTop = 112
    ExplicitWidth = 497
    ExplicitHeight = 337
  end
  object ToolPanel: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 634
    Height = 66
    Align = alTop
    ShowCaption = False
    TabOrder = 0
    object ToolPages: TPageControl
      Left = 1
      Top = 1
      Width = 632
      Height = 64
      ActivePage = SimPage
      Align = alClient
      TabOrder = 0
      object SetupPage: TTabSheet
        TabVisible = False
        object TotalAnts: TLabeledEdit
          Left = 8
          Top = 25
          Width = 94
          Height = 23
          EditLabel.Width = 53
          EditLabel.Height = 15
          EditLabel.Caption = 'Total Ants'
          TabOrder = 0
          Text = '10'
        end
        object TotalFoodUnits: TLabeledEdit
          Left = 120
          Top = 25
          Width = 97
          Height = 23
          EditLabel.Width = 86
          EditLabel.Height = 15
          EditLabel.Caption = 'Total Food Units'
          TabOrder = 1
          Text = '200'
        end
        object LaunchBtn: TButton
          Left = 234
          Top = 8
          Width = 89
          Height = 40
          Caption = 'Launch Sim'
          TabOrder = 2
          OnClick = LaunchBtnClick
        end
      end
      object SimPage: TTabSheet
        ImageIndex = 1
        TabVisible = False
        object FoodCount: TLabel
          Left = 120
          Top = 18
          Width = 18
          Height = 15
          Caption = '000'
        end
        object Label2: TLabel
          Left = 11
          Top = 18
          Width = 87
          Height = 15
          Caption = 'Food remaining:'
        end
        object Placeholder: TShape
          Left = 160
          Top = 10
          Width = 281
          Height = 33
          Brush.Color = clMedGray
          Pen.Style = psClear
        end
      end
    end
  end
  object SimTimer: TTimer
    Enabled = False
    Interval = 33
    OnTimer = HandleSimTimer
    Left = 488
    Top = 26
  end
end
