unit fr_Session;

interface

uses System.Generics.Collections, System.Types,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Mask, Vcl.ComCtrls,

  u_SimTypes,
  u_SessionParameters, u_SimController, u_Simulator, u_Colonies,
  u_GraphicButtonBars, System.Skia, Vcl.Skia, Vcl.CheckLst, Vcl.Buttons,
  System.ImageList, Vcl.ImgList, PngImageList, PngSpeedButton;

type
  TSessionStats = record
    RemainingFood: Integer;
    FoodInNest: Integer;
    Returning: Integer;
    TotalSteps: Integer;
  end;

  TDisplayLayer = (dlAnts, dlFood, dlNests, dlSearching, dlReturning);
  TDisplayLayers = set of TDisplayLayer;

  TZoomLevel = 1..15;

  TToolType = (ttPan, ttDropFood, ttDropBlock, ttDraw, ttErase);

  TSessionFrame = class(TFrame, ISimNotifier)
    lblRemaining: TLabel;
    Label2: TLabel;
    SimTimer: TTimer;
    Arena: TSkPaintBox;
    Label1: TLabel;
    Label3: TLabel;
    lblInNest: TLabel;
    lblReturning: TLabel;
    Label4: TLabel;
    lblTotalSteps: TLabel;
    ToolPanel: TPanel;
    lblStats: TLabel;
    shStats: TShape;
    lblRun: TLabel;
    shRun: TShape;
    shSimSpeed: TShape;
    lblView: TLabel;
    shView: TShape;
    cbDisplayLayers: TCheckListBox;
    btnPan: TPngSpeedButton;
    ToolImages: TPngImageList;
    tbZoom: TTrackBar;
    lblEdit: TLabel;
    shEdit: TShape;
    btnDropFood: TPngSpeedButton;
    btnDropBlock: TPngSpeedButton;
    btnDrawLayer: TPngSpeedButton;
    btnEraseLayer: TPngSpeedButton;
    edtFoodDrop: TEdit;
    shBlockSize: TShape;
    shTargetLayer: TShape;
    procedure HandleSimTimer(Sender: TObject);
    procedure ArenaDraw(ASender: TObject; const ACanvas: ISkCanvas;
      const ADest: TRectF; const AOpacity: Single);
    procedure ArenaResize(Sender: TObject);
    procedure ArenaMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ArenaMouseEnter(Sender: TObject);
    procedure ArenaMouseLeave(Sender: TObject);
    procedure FrameMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure DisplayLayersClickCheck(Sender: TObject);
    procedure DebugBtnClick(Sender: TObject);
    procedure tbZoomChange(Sender: TObject);
    procedure ToolClick(Sender: TObject);
    procedure ArenaMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ArenaMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
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
    TargetLayer: TButtonBar;
    BlockSize: TButtonBar;
    StepsPerTick: Integer;
    BackgroundImage: ISkImage;
    PanX: Single;
    PanY: Single;
    ZoomLevel: TZoomLevel;
    ScaleValue: Single;
    UserOffsetX: Single;
    UserOffsetY: Single;
    Stats: TSessionStats;
    Layers: TDisplayLayers;
    ZoomLocked: Boolean;
    ActiveTool: TToolType;
    WorldMouseX: Single;
    WorldMouseY: Single;
    MouseInArena: Boolean;
    MouseIsDown: Boolean;
    IsPanning: Boolean;
    DragStartX: Integer;
    DragStartY: Integer;
    DragStartOffsetX: Single;
    DragStartOffsetY: Single;
    procedure HandleSpeedClick(Sender: TObject);
    procedure HandleTargetLayerClick(Sender: TObject);
    procedure HandleBlockSizeClick(Sender: TObject);
    procedure ApplyBrush(aGridX, aGridY: Integer);
    procedure UpdateBackgroundImage;
    procedure UpdateAutoPan;
    procedure GenerateMap;
    procedure PopulateFoods(aTotalCount: Integer);
    procedure UpdateStatsDisplay;
    procedure SelectTool(aTool: TToolType);
    procedure SetZoomLevel(Value: TZoomLevel);
    function ScreenToWorld(aScreenX, aScreenY: Single): TPointF;
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

type
  TLayerEntry = record
    caption: string;
    value: TDisplayLayer;
  end;

const
  TARGET_LAYERS: array[0..1] of TLayerEntry = (
    (caption: 'Srch'; value: dlSearching),
    (caption: 'Rtrn'; value: dlReturning)
  );

type
  TBlockSize = (bsSmall, bsMedium, bsLarge);
  TBlockEntry = record
    caption: string;
    value: TBlockSize;
    size: Integer;
  end;

const
  BLOCK_SIZES: array[0..2] of TBlockEntry = (
    (caption: 'Sm'; value: bsSmall; size: 3),
    (caption: 'Med'; value: bsMedium; size: 5),
    (caption: 'Lrg'; value: bsLarge; size: 7)
  );

{ TSessionFrame }

constructor TSessionFrame.Create(AOwner: TComponent);
var
  captions: TCaptionArray;

  function CreateButtonBar(aPlaceholder: TShape; aCallBack: TNotifyEvent): TButtonBar;
  begin
    Result := TButtonBar.Create(Self);
    Result.BoundsRect := aPlaceholder.BoundsRect;
    Result.Parent := aPlaceholder.Parent;
    Result.Visible := True;
    Result.OnClick := aCallBack;
    aPlaceholder.Visible := False;
  end;

begin
  inherited;

  Colonies := TObjectList<TColony>.Create(True);
  Simulator := TSimulator.Create(Self);
  Controller := TSimController.Create;
  Controller.Simulator := Simulator;

  // sim speed
  SimSpeed := CreateButtonBar(shSimSpeed, HandleSpeedClick);

  SetLength(captions, Length(SIM_SPEEDS));
  for var i := 0 to High(SIM_SPEEDS) do
    captions[i] := SIM_SPEEDS[i].caption;
  SimSpeed.Captions := captions;

  // target layer
  TargetLayer := CreateButtonBar(shTargetLayer, HandleTargetLayerClick);
  SetLength(captions, Length(TARGET_LAYERS));
  for var i := 0 to High(TARGET_LAYERS) do
    captions[i] := TARGET_LAYERS[i].caption;
  TargetLayer.Captions := captions;
  TargetLayer.ItemIndex := 0;

  // block size
  BlockSize := CreateButtonBar(shBlockSize, HandleBlockSizeClick);
  SetLength(captions, Length(BLOCK_SIZES));
  for var i := 0 to High(BLOCK_SIZES) do
    captions[i] := BLOCK_SIZES[i].caption;
  BlockSize.Captions := captions;
  BlockSize.ItemIndex := 0;

  StepsPerTick := 0;

  tbZoom.Min := Low(TZoomLevel);
  tbZoom.Max := High(TZoomLevel);

  PanX := 0;
  PanY := 0;
  UserOffsetX := 0;
  UserOffsetY := 0;
  Arena.ControlStyle := Arena.ControlStyle + [csOpaque];

  ActiveTool := ttPan;
  MouseInArena := False;

  Stats := Default(TSessionStats);
  Layers := [dlAnts, dlFood, dlNests];

  for var layer := Low(TDisplayLayer) to High(TDisplayLayer) do
  begin
    if layer in Layers then
      cbDisplayLayers.Checked[Ord(layer)] := True;
  end;

  btnPan.Tag := Ord(ttPan);
  btnDropFood.Tag := Ord(ttDropFood);
  btnDropBlock.Tag := Ord(ttDropBlock);
  btnDrawLayer.Tag := Ord(ttDraw);
  btnEraseLayer.Tag := Ord(ttErase);
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
    if cbDisplayLayers.Checked[Ord(layer)] then
    begin
      Include(Layers, layer);
    end;

  // if we're already running, just wait for the next draw cycle
  if not Self.SimTimer.Enabled then
    Arena.Redraw;
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
      if ZoomLevel < High(TZoomLevel) then
        SetZoomLevel(Succ(ZoomLevel));
    end
    else
    begin
      if ZoomLevel > Low(TZoomLevel) then
        SetZoomLevel(Pred(ZoomLevel));
    end;

    Handled := True;
  end;
end;

procedure TSessionFrame.CreateSession(const Params: TSessionParameters);
begin
  SimSpeed.ItemIndex := 0;

  GenerateMap;
  PopulateFoods(Params.TotalFoodUnits);
  Stats.RemainingFood := Params.TotalFoodUnits;

  // create a colony
  var colony := TColony.Create(Params.Weights, Point(127, 127), Params.TotalAnts);
  Colonies.Add(colony);

  Simulator.AddColony(colony);

  UpdateBackgroundImage;

  SelectTool(ttPan);
  SetZoomLevel(3);
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

procedure TSessionFrame.SelectTool(aTool: TToolType);
begin
  ActiveTool := aTool;

  btnPan.Down := aTool = ttPan;
  btnDropFood.Down := aTool = ttDropFood;
  btnDropBlock.Down := aTool = ttDropBlock;

  btnDrawLayer.AllowAllUp := not (aTool in [ttDraw, ttErase]);
  btnEraseLayer.AllowAllUp := btnDrawLayer.AllowAllUp;
  btnDrawLayer.Down := aTool = ttDraw;
  btnEraseLayer.Down := aTool = ttErase;
end;

procedure TSessionFrame.SetZoomLevel(Value: TZoomLevel);
begin
  if not ZoomLocked then
  begin
    ZoomLocked := True;
    try
      ScaleValue := 0.4 * Ord(Value);
      tbZoom.Position := Ord(Value);

      if Value < ZoomLevel then
        Arena.Invalidate;
      ZoomLevel := Value;

      UpdateAutoPan;
      Arena.Redraw;
    finally
      ZoomLocked := False;
    end;
  end;
end;

procedure TSessionFrame.tbZoomChange(Sender: TObject);
begin
  SetZoomLevel(tbZoom.Position);
end;

procedure TSessionFrame.ToolClick(Sender: TObject);
begin
  if Sender is TSpeedButton then
    SelectTool(TToolType(TSpeedButton(Sender).Tag));
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
var
  mapWidth, mapHeight, maxOffsetX, maxOffsetY: Single;
begin
  mapWidth := GRID_EXTENT * ScaleValue;
  mapHeight := GRID_EXTENT * ScaleValue;

  // clamp offsets so map stays in view
  if mapWidth > Arena.Width then
  begin
    maxOffsetX := (mapWidth - Arena.Width) / (2 * ScaleValue);
    if UserOffsetX > maxOffsetX then UserOffsetX := maxOffsetX;
    if UserOffsetX < -maxOffsetX then UserOffsetX := -maxOffsetX;
  end
  else
    UserOffsetX := 0;

  if mapHeight > Arena.Height then
  begin
    maxOffsetY := (mapHeight - Arena.Height) / (2 * ScaleValue);
    if UserOffsetY > maxOffsetY then UserOffsetY := maxOffsetY;
    if UserOffsetY < -maxOffsetY then UserOffsetY := -maxOffsetY;
  end
  else
    UserOffsetY := 0;

  PanX := Arena.Width / 2 - (128 + UserOffsetX) * ScaleValue;
  PanY := Arena.Height / 2 - (128 + UserOffsetY) * ScaleValue;
end;

procedure TSessionFrame.ApplyBrush(aGridX, aGridY: Integer);
const
  BRUSH_RADIUS = 5;
  DRAW_STRENGTH = 3.0;
var
  bx, by: Integer;
  Colony: TColony;
begin
  for Colony in Colonies do
  begin
    for by := aGridY - BRUSH_RADIUS to aGridY + BRUSH_RADIUS do
      for bx := aGridX - BRUSH_RADIUS to aGridX + BRUSH_RADIUS do
      begin
        if (bx < 0) or (bx > High(TGridDimension)) or
           (by < 0) or (by > High(TGridDimension)) then
          Continue;

        case ActiveTool of
          ttDraw:
          begin
            if TARGET_LAYERS[TargetLayer.ItemIndex].value = dlSearching then
              Colony.FoodLayer[bx, by] := Colony.FoodLayer[bx, by] + DRAW_STRENGTH
            else
              Colony.HomeLayer[bx, by] := Colony.HomeLayer[bx, by] + DRAW_STRENGTH;
          end;
          ttErase:
          begin
            if TARGET_LAYERS[TargetLayer.ItemIndex].value = dlSearching then
              Colony.FoodLayer[bx, by] := 0
            else
              Colony.HomeLayer[bx, by] := 0;
          end;
        end;
      end;
  end;
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

procedure TSessionFrame.HandleTargetLayerClick(Sender: TObject);
begin
  //
end;

procedure TSessionFrame.HandleBlockSizeClick(Sender: TObject);
begin
  //
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
    DrawPaint: ISkPaint;
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

    // draw with blur for a smooth glow effect
    DrawPaint := TSkPaint.Create;
    DrawPaint.ImageFilter := TSkImageFilter.MakeBlur(2.5, 2.5);
    ACanvas.DrawImage(Surface.MakeImageSnapshot, 0, 0, DrawPaint);
  end;

begin
  // Apply pan/zoom transforms
  ACanvas.Translate(PanX, PanY);
  ACanvas.Scale(ScaleValue, ScaleValue);

  // Draw terrain (one draw call for the whole grid)
  if Assigned(BackgroundImage) then
    ACanvas.DrawImage(BackgroundImage, 0, 0);

  // Draw pheromone layers (clipped to grid)
  ACanvas.Save;
  ACanvas.ClipRect(RectF(0, 0, GRID_EXTENT, GRID_EXTENT));
  for Colony in Colonies do
  begin
    if dlSearching in Self.Layers then
      DrawPheromoneLayer(Colony.FoodLayer, TAlphaColors.Orange);
    if dlReturning in Self.Layers then
      DrawPheromoneLayer(Colony.HomeLayer, TAlphaColors.Lightcyan);
  end;
  ACanvas.Restore;

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
        begin
          if Ant.CooldownTicks > 0 then
            Paint.Color := TAlphaColors.Red
          else
            Paint.Color := TAlphaColors.Lightsteelblue;
        end
        else
          Paint.Color := TAlphaColors.Limegreen;

        ACanvas.DrawCircle(Ant.Loc.X + 0.5, Ant.Loc.Y + 0.5, 0.45, Paint);
      end;
    end;
  end;

  // Draw tool cursor (clipped to grid)
  if MouseInArena and (ActiveTool <> ttPan) and
     (WorldMouseX >= 1) and (WorldMouseX <= High(TGridDimension) - 1) and
     (WorldMouseY >= 1) and (WorldMouseY <= High(TGridDimension) - 1) then
  begin
    ACanvas.Save;
    ACanvas.ClipRect(RectF(0, 0, GRID_EXTENT, GRID_EXTENT));

    Paint.Style := TSkPaintStyle.Stroke;
    Paint.Color := TAlphaColors.White;
    Paint.StrokeWidth := 1.0 / ScaleValue; // 1 pixel regardless of zoom

    case ActiveTool of
      ttDropFood:
        ACanvas.DrawCircle(WorldMouseX, WorldMouseY, 1.5, Paint);
      ttDropBlock:
      begin
        var half := BLOCK_SIZES[BlockSize.ItemIndex].size / 2;
        ACanvas.DrawRect(
          RectF(WorldMouseX - half, WorldMouseY - half,
                WorldMouseX + half, WorldMouseY + half), Paint);
      end;
      ttDraw, ttErase:
        ACanvas.DrawRect(
          RectF(WorldMouseX - 5, WorldMouseY - 5,
                WorldMouseX + 5, WorldMouseY + 5), Paint);
    end;

    ACanvas.Restore;
  end;

end;

function TSessionFrame.ScreenToWorld(aScreenX, aScreenY: Single): TPointF;
begin
  Result.X := (aScreenX - PanX) / ScaleValue;
  Result.Y := (aScreenY - PanY) / ScaleValue;
end;

procedure TSessionFrame.ArenaMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  var wp := ScreenToWorld(X, Y);
  WorldMouseX := wp.X;
  WorldMouseY := wp.Y;

  // handle panning
  if IsPanning then
  begin
    var mapWidth := GRID_EXTENT * ScaleValue;
    var mapHeight := GRID_EXTENT * ScaleValue;
    var maxOffsetX: Single;
    var maxOffsetY: Single;

    if mapWidth > Arena.Width then
    begin
      UserOffsetX := DragStartOffsetX - (X - DragStartX) / ScaleValue;
      maxOffsetX := (mapWidth - Arena.Width) / (2 * ScaleValue);
      if UserOffsetX > maxOffsetX then UserOffsetX := maxOffsetX;
      if UserOffsetX < -maxOffsetX then UserOffsetX := -maxOffsetX;
    end
    else
      UserOffsetX := 0;

    if mapHeight > Arena.Height then
    begin
      UserOffsetY := DragStartOffsetY - (Y - DragStartY) / ScaleValue;
      maxOffsetY := (mapHeight - Arena.Height) / (2 * ScaleValue);
      if UserOffsetY > maxOffsetY then UserOffsetY := maxOffsetY;
      if UserOffsetY < -maxOffsetY then UserOffsetY := -maxOffsetY;
    end
    else
      UserOffsetY := 0;

    UpdateAutoPan;
    Arena.Invalidate;
    Arena.Redraw;
    Exit;
  end;

  // paint while dragging with draw/erase tools
  if MouseIsDown and (ActiveTool in [ttDraw, ttErase]) then
    ApplyBrush(Round(WorldMouseX), Round(WorldMouseY));

  // redraw cursor when sim is paused
  if not SimTimer.Enabled then
    Arena.Redraw;
end;

procedure TSessionFrame.ArenaMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  gridX, gridY: Integer;
  amount: Integer;
  p: TPoint;
begin
  MouseIsDown := False;
  IsPanning := False;

  if Button <> mbLeft then
    Exit;

  gridX := Round(WorldMouseX);
  gridY := Round(WorldMouseY);

  // bounds check
  if (gridX < 1) or (gridX > High(TGridDimension) - 1) or
     (gridY < 1) or (gridY > High(TGridDimension) - 1) then
    Exit;

  case ActiveTool of
    ttDropFood:
    begin
      amount := StrToIntDef(edtFoodDrop.Text, 100);
      p := Point(gridX, gridY);
      Simulator.Grid[p.X, p.Y].FoodAmount := Simulator.Grid[p.X, p.Y].FoodAmount + amount;
      Simulator.FoodCells.Add(p);
      Inc(Stats.RemainingFood, amount);
      UpdateStatsDisplay;
    end;

    ttDropBlock:
    begin
      var half := BLOCK_SIZES[BlockSize.ItemIndex].size div 2;
      for var by := gridY - half to gridY + half do
        for var bx := gridX - half to gridX + half do
          if (bx >= 1) and (bx <= High(TGridDimension) - 1) and
             (by >= 1) and (by <= High(TGridDimension) - 1) then
            Simulator.Grid[bx, by].Passable := False;
      UpdateBackgroundImage;
    end;
  end;

  Arena.Redraw;
end;

procedure TSessionFrame.ArenaMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    MouseIsDown := True;

    if ActiveTool = ttPan then
    begin
      IsPanning := True;
      DragStartX := X;
      DragStartY := Y;
      DragStartOffsetX := UserOffsetX;
      DragStartOffsetY := UserOffsetY;
    end
    else if ActiveTool in [ttDraw, ttErase] then
      ApplyBrush(Round(WorldMouseX), Round(WorldMouseY));
  end
  else if Button = mbMiddle then
  begin
    // middle-click pan always available
    IsPanning := True;
    DragStartX := X;
    DragStartY := Y;
    DragStartOffsetX := UserOffsetX;
    DragStartOffsetY := UserOffsetY;
  end;
end;

procedure TSessionFrame.ArenaMouseEnter(Sender: TObject);
begin
  MouseInArena := True;
end;

procedure TSessionFrame.ArenaMouseLeave(Sender: TObject);
begin
  MouseInArena := False;
  if not SimTimer.Enabled then
    Arena.Redraw;
end;

procedure TSessionFrame.ArenaResize(Sender: TObject);
begin
  UpdateAutoPan;
end;

end.
