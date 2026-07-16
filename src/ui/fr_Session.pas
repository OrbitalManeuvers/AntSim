unit fr_Session;

interface

uses System.Generics.Collections, System.Types,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Mask, Vcl.ComCtrls,

  u_SimTypes,
  u_SessionParameters, u_SimController, u_Simulator, u_Colonies,
  u_GraphicButtonBars, System.Skia, Vcl.Skia;

type
  TSessionFrame = class(TFrame, ISimNotifier)
    ToolPanel: TPanel;
    ToolPages: TPageControl;
    SetupPage: TTabSheet;
    SimPage: TTabSheet;
    TotalAnts: TLabeledEdit;
    TotalFoodUnits: TLabeledEdit;
    LaunchBtn: TButton;
    FoodCount: TLabel;
    Label2: TLabel;
    SimTimer: TTimer;
    Placeholder: TShape;
    Arena: TSkPaintBox;
    procedure LaunchBtnClick(Sender: TObject);
    procedure HandleSimTimer(Sender: TObject);
    procedure ArenaDraw(ASender: TObject; const ACanvas: ISkCanvas;
      const ADest: TRectF; const AOpacity: Single);
  private
    { ISimNotifier }
    procedure FoodTaken(const aLoc: TPoint);
    procedure FoodDelivered(const aNest: TPoint);
  private
    Colonies: TObjectList<TColony>;
    Controller: TSimController;
    Simulator: TSimulator;
    SimSpeed: TButtonBar;
    StepsPerTick: Integer;
    procedure HandleSpeedClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CreateSession(const Params: TSessionParameters);
  end;

implementation

{$R *.dfm}

type
  TSpeedEntry = record
    caption: string;
    value: Integer
  end;

const
  SIM_SPEEDS: array[0..3] of TSpeedEntry = (
    (caption: 'Pause'; value: 0),
    (caption: '1x'; value: 1),
    (caption: '2x'; value: 2),
    (caption: '4x'; value: 4)
  );


{ TSessionFrame }

constructor TSessionFrame.Create(AOwner: TComponent);
begin
  inherited;
  Colonies := TObjectList<TColony>.Create(True);
  Simulator := TSimulator.Create(Self);
  Controller := TSimController.Create;
  Controller.Simulator := Simulator;

  SimSpeed := TButtonBar.Create(Self);
  SimSpeed.BoundsRect := Placeholder.BoundsRect;
  SimSpeed.Parent := Placeholder.Parent;

  var captions: TCaptionArray;
  SetLength(captions, Length(SIM_SPEEDS));
  for var i := 0 to High(SIM_SPEEDS) do
    captions[i] := SIM_SPEEDS[i].caption;

  SimSpeed.Captions := captions;
  SimSpeed.Visible := True;
  SimSpeed.OnClick := HandleSpeedClick;
  Placeholder.Visible := False;

  StepsPerTick := 0;
end;

destructor TSessionFrame.Destroy;
begin
  Controller.Free;
  Simulator.Free;
  Colonies.Free;
  inherited;
end;

procedure TSessionFrame.CreateSession(const Params: TSessionParameters);
begin
  ToolPages.ActivePage := SetupPage;
  TotalAnts.Text := Params.TotalAnts.ToString;
  TotalFoodUnits.Text := Params.TotalFoodUnits.ToString;
end;

procedure TSessionFrame.FoodDelivered(const aNest: TPoint);
begin
  //
end;

procedure TSessionFrame.FoodTaken(const aLoc: TPoint);
begin
  Dec(Simulator.Grid[aLoc.X, aLoc.Y].FoodAmount);
end;

procedure TSessionFrame.LaunchBtnClick(Sender: TObject);
begin
  ToolPages.ActivePage := SimPage;
  SimSpeed.ItemIndex := 0;

  // create default map
  for var y := 0 to High(TGridDimension) do
    for var x := 0 to High(TGridDimension) do
    begin
      Simulator.Grid[x, y].Passable := (x > 0) and (x < High(TGridDimension)) and
        (y > 0) and (y < High(TGridDimension));
      Simulator.Grid[x, y].FoodAmount := 0;
    end;

  var foodUnits := StrToIntDef(TotalFoodUnits.Text, 10);
  FoodCount.Caption := foodUnits.ToString;

  // food near corners
  Simulator.Grid[64, 64].FoodAmount := foodUnits div 4;
  Simulator.Grid[64, 192].FoodAmount := foodUnits div 4;
  Simulator.Grid[192, 64].FoodAmount := foodUnits div 4;
  Simulator.Grid[192, 192].FoodAmount := foodUnits div 4;

  // this will come from the params someday ...
  var weights := Default(TColonyWeights);

  var antCount := StrToIntDef(TotalAnts.Text, 1);

  // create a colony
  var colony := TColony.Create(weights, Point(127, 127), antCount);
  Colonies.Add(colony);

  Simulator.AddColony(colony);
end;

procedure TSessionFrame.HandleSimTimer(Sender: TObject);
begin
  for var step := 0 to StepsPerTick - 1 do
    Simulator.Step;
end;

procedure TSessionFrame.HandleSpeedClick(Sender: TObject);
begin
  StepsPerTick := SIM_SPEEDS[SimSpeed.ItemIndex].value;
  SimTimer.Enabled := StepsPerTick > 0;
end;

procedure TSessionFrame.ArenaDraw(ASender: TObject; const ACanvas: ISkCanvas;
  const ADest: TRectF; const AOpacity: Single);
begin
  //
end;

end.
