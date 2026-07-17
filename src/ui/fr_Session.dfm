object SessionFrame: TSessionFrame
  Left = 0
  Top = 0
  Width = 890
  Height = 618
  DoubleBuffered = True
  ParentDoubleBuffered = False
  TabOrder = 0
  OnMouseWheel = FrameMouseWheel
  object Arena: TSkPaintBox
    Left = 0
    Top = 92
    Width = 890
    Height = 526
    Align = alClient
    OnResize = ArenaResize
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
    Width = 884
    Height = 86
    Align = alTop
    ShowCaption = False
    TabOrder = 0
    object ToolPages: TPageControl
      Left = 1
      Top = 1
      Width = 882
      Height = 84
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
        object lblRemaining: TLabel
          Left = 416
          Top = 3
          Width = 24
          Height = 15
          Caption = '0000'
        end
        object Label2: TLabel
          Left = 307
          Top = 3
          Width = 87
          Height = 15
          Caption = 'Food remaining:'
        end
        object Placeholder: TShape
          Left = 8
          Top = 10
          Width = 281
          Height = 33
          Brush.Color = clMedGray
          Pen.Style = psClear
        end
        object Label1: TLabel
          Left = 307
          Top = 19
          Width = 68
          Height = 15
          Caption = 'Food in nest:'
        end
        object Label3: TLabel
          Left = 307
          Top = 35
          Width = 55
          Height = 15
          Caption = 'Returning:'
        end
        object lblInNest: TLabel
          Left = 416
          Top = 19
          Width = 24
          Height = 15
          Caption = '0000'
        end
        object lblReturning: TLabel
          Left = 416
          Top = 35
          Width = 24
          Height = 15
          Caption = '0000'
        end
        object Label4: TLabel
          Left = 467
          Top = 3
          Width = 59
          Height = 15
          Caption = 'Total steps:'
        end
        object lblTotalSteps: TLabel
          Left = 536
          Top = 3
          Width = 24
          Height = 15
          Caption = '0000'
        end
        object DebugBtn: TSpeedButton
          Left = 816
          Top = 16
          Width = 49
          Height = 22
          Caption = 'Debug'
          OnClick = DebugBtnClick
        end
        object DisplayLayers: TCheckListBox
          Left = 582
          Top = 3
          Width = 219
          Height = 63
          Columns = 2
          ItemHeight = 17
          Items.Strings = (
            'Ants'
            'Food'
            'Nests'
            'Searching'
            'Returning')
          TabOrder = 0
          OnClickCheck = DisplayLayersClickCheck
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
