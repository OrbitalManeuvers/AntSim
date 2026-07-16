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
    procedure HandleSpeedClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CreateSession(const Params: TSessionParameters);
  end;

implementation

{$R *.dfm}



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
  SimSpeed.Captions := ['Pause', '1x', '2x', '5x', '10x'];
  SimSpeed.Visible := True;
  SimSpeed.OnClick := HandleSpeedClick;
  Placeholder.Visible := False;

end;

destructor TSessionFrame.Destroy;
begin
  Controller.Free;
  Simulator.Free;
  Colonies.Free;
  inherited;
end;

procedure TSessionFrame.FoodDelivered(const aNest: TPoint);
begin
  //
end;

procedure TSessionFrame.FoodTaken(const aLoc: TPoint);
begin
  Dec(Simulator.Grid[aLoc.X, aLoc.Y].FoodAmount);
end;

procedure TSessionFrame.CreateSession(const Params: TSessionParameters);
begin
  ToolPages.ActivePage := SetupPage;
  TotalAnts.Text := Params.TotalAnts.ToString;
  TotalFoodUnits.Text := Params.TotalFoodUnits.ToString;
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

  SimTimer.Interval := 1000;
  SimTimer.Enabled := False;
end;

procedure TSessionFrame.HandleSimTimer(Sender: TObject);
begin
  SimTimer.Enabled := False;

  var colony := Colonies.First;
  if Assigned(colony) then
  begin
    colony.StepAnts(Simulator.Grid, Self);
  end;


end;

procedure TSessionFrame.HandleSpeedClick(Sender: TObject);
begin
  if SimSpeed.ItemIndex = 0 then
    SimTimer.Enabled := False
  else
  begin
    SimTimer.Interval := 1000;
    SimTimer.Enabled := True;
  end;
end;

procedure TSessionFrame.ArenaDraw(ASender: TObject; const ACanvas: ISkCanvas;
  const ADest: TRectF; const AOpacity: Single);
begin
  //
end;

end.
