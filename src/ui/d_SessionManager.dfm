object SessionManager: TSessionManager
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Session Manager'
  ClientHeight = 386
  ClientWidth = 668
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 17
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 53
    Height = 17
    Caption = 'Sessions:'
  end
  object btnNewSession: TSpeedButton
    Left = 16
    Top = 352
    Width = 65
    Height = 26
    Caption = 'New'
  end
  object btnDeleteSession: TSpeedButton
    Left = 96
    Top = 352
    Width = 65
    Height = 26
    Caption = 'Delete'
  end
  object Label2: TLabel
    Left = 304
    Top = 52
    Width = 38
    Height = 17
    Caption = 'Name:'
  end
  object Label3: TLabel
    Left = 304
    Top = 83
    Width = 38
    Height = 17
    Caption = 'Notes:'
  end
  object Label5: TLabel
    Left = 304
    Top = 248
    Width = 30
    Height = 17
    Caption = 'Map:'
  end
  object Label6: TLabel
    Left = 304
    Top = 280
    Width = 28
    Height = 17
    Caption = 'Ants:'
  end
  object Label7: TLabel
    Left = 304
    Top = 312
    Width = 33
    Height = 17
    Caption = 'Food:'
  end
  object btnBrowse: TSpeedButton
    Left = 626
    Top = 248
    Width = 23
    Height = 22
    Caption = '...'
    OnClick = btnBrowseClick
  end
  object SessionList: TControlList
    Left = 8
    Top = 32
    Width = 265
    Height = 305
    ItemHeight = 35
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    TabOrder = 0
    OnBeforeDrawItem = SessionListBeforeDrawItem
    OnItemClick = SessionListItemClick
    object lblSessionName: TLabel
      AlignWithMargins = True
      Left = 8
      Top = 2
      Width = 249
      Height = 31
      Margins.Left = 8
      Margins.Top = 2
      Margins.Right = 4
      Margins.Bottom = 2
      Align = alClient
      Caption = 'lblSessionName'
      ShowAccelChar = False
      Layout = tlCenter
      ExplicitLeft = 24
      ExplicitTop = 8
      ExplicitWidth = 93
      ExplicitHeight = 17
    end
  end
  object edtName: TEdit
    Left = 368
    Top = 49
    Width = 281
    Height = 25
    TabOrder = 1
  end
  object mmoNotes: TMemo
    Left = 368
    Top = 80
    Width = 281
    Height = 81
    TabOrder = 2
  end
  object edtMap: TEdit
    Left = 368
    Top = 245
    Width = 250
    Height = 25
    ReadOnly = True
    TabOrder = 3
  end
  object edtAnts: TEdit
    Left = 368
    Top = 277
    Width = 89
    Height = 25
    NumbersOnly = True
    TabOrder = 4
    Text = '600'
    OnChange = edtAntsChange
  end
  object edtFood: TEdit
    Left = 368
    Top = 309
    Width = 89
    Height = 25
    NumbersOnly = True
    TabOrder = 5
    Text = '60000'
    OnChange = edtFoodChange
  end
  object btnLaunch: TButton
    Left = 480
    Top = 352
    Width = 75
    Height = 26
    Caption = 'Launch'
    Default = True
    ModalResult = 1
    TabOrder = 6
    OnClick = btnLaunchClick
  end
  object btnCancel: TButton
    Left = 574
    Top = 352
    Width = 75
    Height = 26
    Cancel = True
    Caption = 'Close'
    ModalResult = 2
    TabOrder = 7
  end
end
