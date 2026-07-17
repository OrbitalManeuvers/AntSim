unit fr_Session;

interface

uses System.Generics.Collections, System.Types,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Mask, Vcl.ComCtrls,

  u_SimTypes,
  u_SessionParameters, u_SimController, u_Simulator, u_Colonies,
  u_GraphicButtonBars, System.Skia, Vcl.Skia, Vcl.CheckLst, Vcl.Buttons;

type
  TSessionStats = record
    RemainingFood: Integer;
    FoodInNest: Integer;
    Returning: Integer;
    TotalSteps: Integer;
  end;

  TDisplayLayer = (dlAnts, dlFood, dlNests, dlSearching, dlReturning);
  TDisplayLayers = set of TDisplayLayer;

  TSessionFrame = class(TFrame, ISimNotifier)
    ToolPanel: TPanel;
    ToolPages: TPageControl;
    SetupPage: TTabSheet;
    SimPage: TTabSheet;
    TotalAnts: TLabeledEdit;
    TotalFoodUnits: TLabeledEdit;
    LaunchBtn: TButton;
    lblRemaining: TLabel;
    Label2: TLabel;
    SimTimer: TTimer;
    Placeholder: TShape;
    Arena: TSkPaintBox;
    Label1: TLabel;
    Label3: TLabel;
    lblInNest: TLabel;
    lblReturning: TLabel;
    Label4: TLabel;
    lblTotalSteps: TLabel;
    DisplayLayers: TCheckListBox;
    DebugBtn: TSpeedButton;
    procedure LaunchBtnClick(Sender: TObject);
    procedure HandleSimTimer(Sender: TObject);
    procedure ArenaDraw(ASender: TObject; const ACanvas: ISkCanvas;
      const ADest: TRectF; const AOpacity: Single);
    procedure ArenaResize(Sender: TObject);
    procedure FrameMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure DisplayLayersClickCheck(Sender: TObject);
    procedure DebugBtnClick(Sender: TObject);
  private
    { ISimNotifier }
    procedure FoodTaken(const aLoc: TPoint);
    procedure FoodDelivered(const aNest: TPoint);
    procedure FoodDropped(const aLoc: TPoint);
  private
    Colonies: TObjectList<TColony>;
    Controller: TSimController;
    Simulator: TSimulator;
    SimSpeed: TButtonBar;
    StepsPerTick: Integer;
    BackgroundImage: ISkImage;
    PanX: Single;
    PanY: Single;
    Zoom: Single;
    UserOffsetX: Single;
    UserOffsetY: Single;
    Stats: TSessionStats;
    Layers: TDisplayLayers;
    procedure HandleSpeedClick(Sender: TObject);
    procedure UpdateBackgroundImage;
    procedure UpdateAutoPan;
    procedure GenerateMap;
    procedure PopulateFoods(aTotalCount: Integer);
    procedure UpdateStatsDisplay;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CreateSession(const Params: TSessionParameters);
  end;

implementation

{$R *.dfm}

uses System.UITypes, System.Math,
  u_Ants;

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

  PanX := 0;
  PanY := 0;
  Zoom := 2.0;
  UserOffsetX := 0;
  UserOffsetY := 0;
  Arena.ControlStyle := Arena.ControlStyle + [csOpaque];

  Stats := Default(TSessionStats);
  Layers := [dlAnts, dlFood, dlNests];
  for var layer := Low(TDisplayLayer) to High(TDisplayLayer) do
  begin
    if layer in Layers then
      DisplayLayers.Checked[Ord(layer)] := True;
  end;
end;

procedure TSessionFrame.DebugBtnClick(Sender: TObject);
begin
  // pause the sim
  var wasRunning := SimTimer.Enabled;
  try
    SimTimer.Enabled := False;

    var c := Colonies.First;
    if not Assigned(c) then
      Exit;

    var lines := TStringList.Create(dupIgnore, False, False);
    try
      for var i := 0 to High(c.Ants) do
        if c.Ants[i].State = asReturning then
        begin
          lines.Add(Format('#%.03d  L:%d,%d  A:%d PU: %d', [
            i,
            c.Ants[i].Loc.X,
            c.Ants[i].Loc.Y,
            c.Ants[i].TicksAlive,
            c.Ants[i].TicksSincePickup
            ]));
        end;

        ShowMessage(lines.text);

    finally
      lines.Free;
    end;


  finally
    if wasRunning then
      SimTimer.Enabled := True;
  end;
end;

destructor TSessionFrame.Destroy;
begin
  Controller.Free;
  Simulator.Free;
  Colonies.Free;
  inherited;
end;

procedure TSessionFrame.DisplayLayersClickCheck(Sender: TObject);
begin
  Layers := [];
  for var layer := Low(TDisplayLayer) to High(TDisplayLayer) do
    if DisplayLayers.Checked[Ord(layer)] then
    begin
      Include(Layers, layer);
    end;

  // if we're already running, just wait for the next draw cycle
  if not Self.SimTimer.Enabled then
    Arena.Redraw;
end;

procedure TSessionFrame.CreateSession(const Params: TSessionParameters);
begin
  ToolPages.ActivePage := SetupPage;
  TotalAnts.Text := Params.TotalAnts.ToString;
  TotalFoodUnits.Text := Params.TotalFoodUnits.ToString;
end;

procedure TSessionFrame.FoodDelivered(const aNest: TPoint);
begin
  Inc(Stats.FoodInNest);
  Dec(Stats.Returning);
  UpdateStatsDisplay;
end;

procedure TSessionFrame.FoodDropped(const aLoc: TPoint);
begin
  Dec(Stats.Returning);
  UpdateStatsDisplay;
end;

procedure TSessionFrame.FoodTaken(const aLoc: TPoint);
begin
  Dec(Simulator.Grid[aLoc.X, aLoc.Y].FoodAmount);
  Dec(Stats.RemainingFood);
  Inc(Stats.Returning);
  UpdateStatsDisplay;
end;

procedure TSessionFrame.FrameMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  var p := Arena.ScreenToClient(MousePos);
  if Arena.BoundsRect.Contains(p) then
  begin
    if WheelDelta > 0 then
    begin
      Zoom := Zoom * 1.1;
    end
    else
    begin
      Zoom := Zoom / 1.1;
      Arena.Invalidate;  // makes sure the old, larger image gets erased
    end;

    UpdateAutoPan;

    Arena.Redraw;
  end;
end;

procedure TSessionFrame.LaunchBtnClick(Sender: TObject);
begin
  ToolPages.ActivePage := SimPage;
  SimSpeed.ItemIndex := 0;

  GenerateMap;

  var foodUnits := StrToIntDef(TotalFoodUnits.Text, 10);
  PopulateFoods(foodUnits);
  Stats.RemainingFood := foodUnits;

  // this will come from the params someday ...
  var weights := Default(TColonyWeights);

  var antCount := StrToIntDef(TotalAnts.Text, 1);

  // create a colony
  var colony := TColony.Create(weights, Point(127, 127), antCount);
  Colonies.Add(colony);

  Simulator.AddColony(colony);

  UpdateBackgroundImage;
  UpdateAutoPan;

  UpdateStatsDisplay;
  Arena.Redraw;
end;

procedure TSessionFrame.PopulateFoods(aTotalCount: Integer);
begin
  if Simulator.FoodCells.Count > 0 then
  begin
    var perCell := aTotalCount div Simulator.FoodCells.Count;
    var remainder := aTotalCount - (perCell * Simulator.FoodCells.Count);
    for var p in Simulator.FoodCells do
      Simulator.Grid[p.X, p.Y].FoodAmount := perCell;
    var p := Simulator.FoodCells.Last;
    Inc(Simulator.Grid[p.X, p.Y].FoodAmount, remainder);
  end;
end;

procedure TSessionFrame.GenerateMap;
begin
  // create default map. will come from session parameters/image file eventually
  for var y := 0 to High(TGridDimension) do
    for var x := 0 to High(TGridDimension) do
    begin
      Simulator.Grid[x, y].Passable := (x > 0) and (x < High(TGridDimension)) and
        (y > 0) and (y < High(TGridDimension));
      Simulator.Grid[x, y].FoodAmount := 0;
    end;

  // test terrain
  for var x := 80 to 84 do
    for var y := 80 to 84 do
      Simulator.Grid[x, y].Passable := False;

  for var x := 80 to 84 do
    for var y := 120 to 123 do
      Simulator.Grid[x, y].Passable := False;



  // identify food locations
  Simulator.FoodCells.Add(Point(95, 60));
  Simulator.FoodCells.Add(Point(80, 64));
  Simulator.FoodCells.Add(Point(100, 80));

  Simulator.FoodCells.Add(Point(64, 80));
  Simulator.FoodCells.Add(Point(64, 100));
  Simulator.FoodCells.Add(Point(64, 150));
  Simulator.FoodCells.Add(Point(64, 192));

  Simulator.FoodCells.Add(Point(182, 64));
  Simulator.FoodCells.Add(Point(192, 94));
  Simulator.FoodCells.Add(Point(162, 104));
  Simulator.FoodCells.Add(Point(102, 142));
end;

procedure TSessionFrame.UpdateAutoPan;
begin
  PanX := Arena.Width / 2 - (128 + UserOffsetX) * Zoom;
  PanY := Arena.Height / 2 - (128 + UserOffsetY) * Zoom;
end;

// after grid is built, or when terrain changes
procedure TSessionFrame.UpdateBackgroundImage;
var
  Surface: ISkSurface;
  Canvas: ISkCanvas;
  Paint: ISkPaint;
begin
  Paint := TSkPaint.Create;
  Paint.Style := TSkPaintStyle.Fill;

  Surface := TSkSurface.MakeRaster(256, 256);
  Canvas := Surface.Canvas;

  for var y := 0 to 255 do
    for var x := 0 to 255 do
    begin
      if Simulator.Grid[x, y].Passable then
        Paint.Color := TAlphaColors.Black   // or whatever ground color
      else
        Paint.Color := TAlphaColors.Darkslateblue;  // walls

      Canvas.DrawPoint(x, y, Paint);
    end;

  BackgroundImage := Surface.MakeImageSnapshot;
end;

procedure TSessionFrame.UpdateStatsDisplay;
begin
  if Stats.TotalSteps mod 5 = 0 then
  begin
    lblRemaining.Caption := Stats.RemainingFood.ToString;
    lblInNest.Caption := Stats.FoodInNest.ToString;
    lblReturning.Caption := Stats.Returning.ToString;
  end;
  if Stats.TotalSteps mod 50 = 0 then
    lblTotalSteps.Caption := Stats.TotalSteps.ToString;
end;

procedure TSessionFrame.HandleSimTimer(Sender: TObject);
begin
  for var step := 0 to StepsPerTick - 1 do
  begin
    Simulator.Step;
    Inc(Stats.TotalSteps);
  end;

  Arena.Redraw;
  UpdateStatsDisplay;
end;

procedure TSessionFrame.HandleSpeedClick(Sender: TObject);
begin
  StepsPerTick := SIM_SPEEDS[SimSpeed.ItemIndex].value;
  SimTimer.Enabled := StepsPerTick > 0;
end;

procedure TSessionFrame.ArenaDraw(ASender: TObject; const ACanvas: ISkCanvas;
  const ADest: TRectF; const AOpacity: Single);
var
  Paint: ISkPaint;
  Colony: TColony;
  i: Integer;
  Ant: TAnt;

  procedure DrawPheromoneLayer(const aLayer: TPheromoneLayer; aColor: Cardinal);
  var
    Surface: ISkSurface;
    LayerCanvas: ISkCanvas;
    LayerPaint: ISkPaint;
    maxVal: Single;
    alpha: Byte;
    x, y: Integer;
  begin
    // find max value for normalization
    maxVal := 0;
    for y := 0 to High(TGridDimension) do
      for x := 0 to High(TGridDimension) do
        if aLayer[x, y] > maxVal then
          maxVal := aLayer[x, y];

    if maxVal > 3 then
      maxVal := 3;

    if maxVal < 0.01 then
      Exit; // nothing to draw

    Surface := TSkSurface.MakeRaster(GRID_EXTENT, GRID_EXTENT);
    LayerCanvas := Surface.Canvas;
    LayerCanvas.Clear(TAlphaColors.Null);

    LayerPaint := TSkPaint.Create;
    LayerPaint.Style := TSkPaintStyle.Fill;

    for y := 0 to High(TGridDimension) do
      for x := 0 to High(TGridDimension) do
      begin
        if aLayer[x, y] > 0.01 then
        begin
          alpha := Round(Min(aLayer[x, y] / maxVal, 1.0) * 180);
          LayerPaint.Color := (Cardinal(alpha) shl 24) or (aColor and $00FFFFFF);
          LayerCanvas.DrawPoint(x, y, LayerPaint);
        end;
      end;

    ACanvas.DrawImage(Surface.MakeImageSnapshot, 0, 0);
  end;

begin
  // Apply pan/zoom transforms
  ACanvas.Translate(PanX, PanY);
  ACanvas.Scale(Zoom, Zoom);

  // Draw terrain (one draw call for the whole grid)
  if Assigned(BackgroundImage) then
    ACanvas.DrawImage(BackgroundImage, 0, 0);

  // Draw pheromone layers
  for Colony in Colonies do
  begin
    if dlSearching in Self.Layers then
      DrawPheromoneLayer(Colony.FoodLayer, TAlphaColors.Orange);
    if dlReturning in Self.Layers then
      DrawPheromoneLayer(Colony.HomeLayer, TAlphaColors.Lightseagreen);
  end;

  Paint := TSkPaint.Create;
  Paint.Style := TSkPaintStyle.Fill;
  Paint.AntiAlias := True;

  // Draw food locations
  if dlFood in Self.Layers then
  begin
    Paint.Color := TAlphaColors.Orange;
    for var p in Simulator.FoodCells do
    begin
      if Simulator.Grid[p.X, p.Y].FoodAmount > 0 then
        ACanvas.DrawCircle(p.X, p.Y, 1.0, Paint);
    end;
  end;

  // draw nests
  if dlNests in Self.Layers then
  begin
    Paint.Color := TAlphaColors.Red;
    Paint.Style := TSkPaintStyle.Stroke;
    for Colony in Colonies do
    begin
      var p := Colony.Nest;
      ACanvas.DrawCircle(p.X, p.Y, 1.0, Paint);
    end;
  end;

  if dlAnts in Self.Layers then
  begin
    Paint.Style := TSkPaintStyle.Fill;
    // Draw ants
    for Colony in Colonies do
    begin
      for i := 0 to High(Colony.Ants) do
      begin
        Ant := Colony.Ants[i];
        if Ant.State = asInNest then
          Continue;

        if Ant.State = asSearching then
          Paint.Color := TAlphaColors.Lightsteelblue
        else
          Paint.Color := TAlphaColors.Limegreen;

        ACanvas.DrawCircle(Ant.Loc.X + 0.5, Ant.Loc.Y + 0.5, 0.45, Paint);
      end;
    end;
  end;

end;

procedure TSessionFrame.ArenaResize(Sender: TObject);
begin
  UpdateAutoPan;
end;

end.
