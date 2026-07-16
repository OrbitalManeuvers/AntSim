unit u_Colonies;

interface

uses System.Generics.Collections, System.Types,
  u_SimTypes, u_Ants;

type
  TColonyWeights = record
    //
  end;

  TColony = class
  private
    fAnts: array of TAnt;
    fNest: TPoint;

    fWeights: TColonyWeights;
    fHomeLayer: TPheromoneLayer;
    fFoodLayer: TPheromoneLayer;
    fHomeDeposits: TPheromoneLayer;  // accumulator, zeroed after apply
    fFoodDeposits: TPheromoneLayer;

  public
    constructor Create(const aWeights: TColonyWeights; const aNestLocation: TPoint; aCount: Integer);
    destructor Destroy; override;
    procedure StepAnts(const aGrid: TCellGrid; const aNotifier: ISimNotifier);
    procedure ApplyPheromones;
  end;

const
  SPAWNS_PER_TICK = 3;
  PHEROMONE_DEPOSIT = 1.0;
  DECAY_FACTOR = 0.98;         // multiply each cell by this per tick
  WOBBLE_RANGE = Pi / 6;       // ±30° random wobble
  SENSE_ANGLE  = Pi / 4;       // ±45° cone for sensing
  SENSE_DIST   = 3;            // how far ahead to sample pheromone

implementation

uses System.Math;

{ TColony }

constructor TColony.Create(const aWeights: TColonyWeights; const aNestLocation: TPoint; aCount: Integer);
begin
  inherited Create;
  fWeights := aWeights;
  fNest := aNestLocation;
  SetLength(fAnts, aCount);

  // explicit init ...
  for var i := 0 to High(fAnts) do
  begin
    fAnts[i].State := asInNest;
    fAnts[i].Loc := fNest;
  end;
end;

destructor TColony.Destroy;
begin
  inherited;
end;

procedure TColony.StepAnts(const aGrid: TCellGrid; const aNotifier: ISimNotifier);

  function ClampGrid(aValue: Integer): Integer; inline;
  begin
    if aValue < 0 then Result := 0
    else if aValue > High(TGridDimension) then Result := High(TGridDimension)
    else Result := aValue;
  end;

  function SamplePheromone(const aLayer: TPheromoneLayer; aX, aY: Integer): Single; inline;
  begin
    Result := aLayer[ClampGrid(aX), ClampGrid(aY)];
  end;

  function SenseDirection(const aLayer: TPheromoneLayer; const aLoc: TPoint; aAngle: Single): Single;
  var
    Left, Ahead, Right: Single;
    lx, ly, ax, ay, rx, ry: Integer;
  begin
    // sample three points in a forward cone
    ax := ClampGrid(aLoc.X + Round(Cos(aAngle) * SENSE_DIST));
    ay := ClampGrid(aLoc.Y + Round(Sin(aAngle) * SENSE_DIST));
    lx := ClampGrid(aLoc.X + Round(Cos(aAngle - SENSE_ANGLE) * SENSE_DIST));
    ly := ClampGrid(aLoc.Y + Round(Sin(aAngle - SENSE_ANGLE) * SENSE_DIST));
    rx := ClampGrid(aLoc.X + Round(Cos(aAngle + SENSE_ANGLE) * SENSE_DIST));
    ry := ClampGrid(aLoc.Y + Round(Sin(aAngle + SENSE_ANGLE) * SENSE_DIST));

    Ahead := SamplePheromone(aLayer, ax, ay);
    Left  := SamplePheromone(aLayer, lx, ly);
    Right := SamplePheromone(aLayer, rx, ry);

    // bias toward strongest signal
    if (Left > Ahead) and (Left > Right) then
      Result := aAngle - SENSE_ANGLE * 0.5
    else if (Right > Ahead) and (Right > Left) then
      Result := aAngle + SENSE_ANGLE * 0.5
    else
      Result := aAngle;
  end;

var
  i: Integer;
  Spawned: Integer;
  nx, ny: Integer;
  Ant: ^TAnt;
begin
  Spawned := 0;

  for i := 0 to High(fAnts) do
  begin
    Ant := @fAnts[i];

    case Ant.State of
      asInNest:
      begin
        if Spawned < SPAWNS_PER_TICK then
        begin
          Ant.State := asSearching;
          Ant.Angle := Random * 2 * Pi; // random initial heading
          Inc(Spawned);
        end;
      end;

      asSearching:
      begin
        // sense food pheromone and adjust heading
        Ant.Angle := SenseDirection(fFoodLayer, Ant.Loc, Ant.Angle);

        // wobble
        Ant.Angle := Ant.Angle + (Random - 0.5) * 2 * WOBBLE_RANGE;

        // compute next cell
        nx := Ant.Loc.X + Round(Cos(Ant.Angle));
        ny := Ant.Loc.Y + Round(Sin(Ant.Angle));

        if (nx >= 0) and (nx <= High(TGridDimension)) and
           (ny >= 0) and (ny <= High(TGridDimension)) and
           aGrid[nx, ny].Passable then
        begin
          Ant.Loc := Point(nx, ny);
        end
        else
        begin
          // blocked: turn randomly ±90°
          if Random < 0.5 then
            Ant.Angle := Ant.Angle + Pi / 2
          else
            Ant.Angle := Ant.Angle - Pi / 2;
        end;

        // deposit home pheromone
        fHomeDeposits[Ant.Loc.X, Ant.Loc.Y] :=
          fHomeDeposits[Ant.Loc.X, Ant.Loc.Y] + PHEROMONE_DEPOSIT;

        // check for food
        if aGrid[Ant.Loc.X, Ant.Loc.Y].FoodAmount > 0 then
        begin
          aNotifier.FoodTaken(Ant.Loc);
          Ant.State := asReturning;
          Ant.Angle := Ant.Angle + Pi; // turn around
        end;

        Inc(Ant.TicksAlive);
      end;

      asReturning:
      begin
        // sense home pheromone and adjust heading
        Ant.Angle := SenseDirection(fHomeLayer, Ant.Loc, Ant.Angle);

        // wobble
        Ant.Angle := Ant.Angle + (Random - 0.5) * 2 * WOBBLE_RANGE;

        // compute next cell
        nx := Ant.Loc.X + Round(Cos(Ant.Angle));
        ny := Ant.Loc.Y + Round(Sin(Ant.Angle));

        if (nx >= 0) and (nx <= High(TGridDimension)) and
           (ny >= 0) and (ny <= High(TGridDimension)) and
           aGrid[nx, ny].Passable then
        begin
          Ant.Loc := Point(nx, ny);
        end
        else
        begin
          if Random < 0.5 then
            Ant.Angle := Ant.Angle + Pi / 2
          else
            Ant.Angle := Ant.Angle - Pi / 2;
        end;

        // deposit food pheromone
        fFoodDeposits[Ant.Loc.X, Ant.Loc.Y] :=
          fFoodDeposits[Ant.Loc.X, Ant.Loc.Y] + PHEROMONE_DEPOSIT;

        // check if at nest
        if (Abs(Ant.Loc.X - fNest.X) <= 1) and (Abs(Ant.Loc.Y - fNest.Y) <= 1) then
        begin
          aNotifier.FoodDelivered(fNest);
          Ant.State := asSearching;
          Ant.Angle := Random * 2 * Pi; // head back out in a random direction
        end;

        Inc(Ant.TicksAlive);
      end;
    end;
  end;
end;

procedure TColony.ApplyPheromones;
var
  x, y: TGridDimension;
begin
  for y := Low(TGridDimension) to High(TGridDimension) do
    for x := Low(TGridDimension) to High(TGridDimension) do
    begin
      // merge deposits into live layers
      fHomeLayer[x, y] := (fHomeLayer[x, y] + fHomeDeposits[x, y]) * DECAY_FACTOR;
      fFoodLayer[x, y] := (fFoodLayer[x, y] + fFoodDeposits[x, y]) * DECAY_FACTOR;

      // zero accumulators
      fHomeDeposits[x, y] := 0;
      fFoodDeposits[x, y] := 0;
    end;
end;

end.
