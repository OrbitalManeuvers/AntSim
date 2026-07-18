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
    fWeights: TColonyWeights;
    fHomeDeposits: TPheromoneLayer;  // accumulator, zeroed after apply
    fFoodDeposits: TPheromoneLayer;
    fSpawnDelay: Integer;
  public
    Ants: array of TAnt;
    Nest: TPoint;
    HomeLayer: TPheromoneLayer;
    FoodLayer: TPheromoneLayer;
    constructor Create(const aWeights: TColonyWeights; const aNestLocation: TPoint; aCount: Integer);
    destructor Destroy; override;
    procedure StepAnts(const aGrid: TCellGrid; const aNotifier: ISimNotifier);
    procedure ApplyFoodHints(const aGrid: TCellGrid; const aLocations: TList<TPoint>);
    procedure ApplyNestHint;
    procedure ApplyPheromones;
  end;

const
  SPAWNS_PER_TICK = 3;
  PHEROMONE_DEPOSIT = 1.2;
  DECAY_FACTOR = 0.985;         // multiply each cell by this per tick
  FOOD_SCENT_FACTOR = 0.7;     // how strongly food radiates into fFoodLayer
  NEST_SCENT_BASE = 8.0;       // home signal strength at nest center
  NEST_SCENT_RADIUS = 50;      // how far the nest beacon reaches
  WOBBLE_MIN = Pi / 8;         // tight wobble when on a strong trail
  WOBBLE_MAX = Pi / 3;         // wide wobble when no signal (exploratory)
  SIGNAL_THRESHOLD = 0.5;      // below this, ant is considered "lost"
  SENSE_ANGLE  = Pi / 4;       // ±45° cone for sensing
  SENSE_DIST   = 3;            // how far ahead to sample pheromone
  DIST_DECAY_RATE = 0.02;      // how quickly home deposit weakens with distance
  GIVE_UP_TICKS = 200;         // returning ant drops food and resumes searching

implementation

uses System.Math;

{ TColony }

constructor TColony.Create(const aWeights: TColonyWeights; const aNestLocation: TPoint; aCount: Integer);
begin
  inherited Create;
  fWeights := aWeights;
  Nest := aNestLocation;
  SetLength(Ants, aCount);

  // explicit init ...
  for var i := 0 to High(Ants) do
  begin
    Ants[i].State := asInNest;
    Ants[i].Loc := Nest;
    Ants[i].WobbleFactor := 0.5 + Random;  // range 0.5 to 1.5
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

  function SenseDirection(const aLayer: TPheromoneLayer; const aLoc: TPoint; aAngle: Single; out aMaxSignal: Single): Single;
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

    aMaxSignal := Max(Ahead, Max(Left, Right));

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
  signal, wobble, deposit: Single;
begin
  Spawned := 0;

  for i := 0 to High(Ants) do
  begin
    Ant := @Ants[i];

    case Ant.State of
      asInNest:
      begin
        if fSpawnDelay = 0 then
        begin
          if Spawned < SPAWNS_PER_TICK then
          begin
            Ant.State := asSearching;
            Ant.Angle := Random * 2 * Pi; // random initial heading
            Inc(Spawned);
          end;
        end;
      end;

      asSearching:
      begin
        // sense food pheromone and adjust heading
        Ant.Angle := SenseDirection(FoodLayer, Ant.Loc, Ant.Angle, signal);

        // adaptive wobble: wide when lost, tight when on a trail
        if signal < SIGNAL_THRESHOLD then
          wobble := WOBBLE_MAX
        else
          wobble := WOBBLE_MIN;

        Ant.Angle := Ant.Angle + (Random - 0.5) * 2 * wobble * Ant.WobbleFactor;

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
          Ant.TicksSincePickup := 0;
          Ant.Angle := Ant.Angle + Pi; // turn around
        end;

        Inc(Ant.TicksAlive);
      end;

      asReturning:
      begin
        // sense home pheromone and adjust heading
        Ant.Angle := SenseDirection(HomeLayer, Ant.Loc, Ant.Angle, signal);

        // adaptive wobble
        if signal < SIGNAL_THRESHOLD then
          wobble := WOBBLE_MAX
        else
          wobble := WOBBLE_MIN;
        Ant.Angle := Ant.Angle + (Random - 0.5) * 2 * wobble * Ant.WobbleFactor;

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

        // deposit food pheromone — fades with time since pickup
        deposit := PHEROMONE_DEPOSIT * (1.0 / (1.0 + Ant.TicksSincePickup * DIST_DECAY_RATE));
        fFoodDeposits[Ant.Loc.X, Ant.Loc.Y] :=
          fFoodDeposits[Ant.Loc.X, Ant.Loc.Y] + deposit;

        Inc(Ant.TicksSincePickup);

        // check if at nest
        if (Abs(Ant.Loc.X - Nest.X) <= 1) and (Abs(Ant.Loc.Y - Nest.Y) <= 1) then
        begin
          aNotifier.FoodDelivered(Nest);
          Ant.State := asSearching;
          Ant.Angle := Random * 2 * Pi; // head back out in a random direction
        end
        // give up if lost too long — drop food, resume searching
        else if Ant.TicksSincePickup > GIVE_UP_TICKS then
        begin
          aNotifier.FoodDropped(Ant.Loc);
          Ant.State := asSearching;
          Ant.Angle := Random * 2 * Pi;
        end;

        Inc(Ant.TicksAlive);
      end;
    end;
  end;

  if fSpawnDelay > 0 then
    Dec(fSpawnDelay)
  else
    fSpawnDelay := 10;
end;

procedure TColony.ApplyFoodHints(const aGrid: TCellGrid; const aLocations: TList<TPoint>);
var
  p: TPoint;
  signal: Single;
begin
  for p in aLocations do
  begin
    signal := aGrid[p.X, p.Y].FoodAmount * FOOD_SCENT_FACTOR;
    if signal > 0 then
      FoodLayer[p.X, p.Y] := FoodLayer[p.X, p.Y] + signal;
  end;
end;

procedure TColony.ApplyNestHint;
var
  dx, dy, gx, gy: Integer;
  dist, signal: Single;
begin
  for dy := -NEST_SCENT_RADIUS to NEST_SCENT_RADIUS do
    for dx := -NEST_SCENT_RADIUS to NEST_SCENT_RADIUS do
    begin
      gx := Nest.X + dx;
      gy := Nest.Y + dy;
      if (gx < 0) or (gx > High(TGridDimension)) or
         (gy < 0) or (gy > High(TGridDimension)) then
        Continue;

      dist := Sqrt(dx * dx + dy * dy);
      if dist > NEST_SCENT_RADIUS then
        Continue;

      // linear falloff: full strength at center, zero at edge
      signal := NEST_SCENT_BASE * (1.0 - dist / NEST_SCENT_RADIUS);
      HomeLayer[gx, gy] := HomeLayer[gx, gy] + signal;
    end;
end;

procedure TColony.ApplyPheromones;
var
  x, y: TGridDimension;
  nx, ny, dx, dy: Integer;
  sumHome, sumFood: Single;
  count: Integer;
  blurredHome, blurredFood: TPheromoneLayer;
begin
  // merge deposits into live layers and decay
  for y := Low(TGridDimension) to High(TGridDimension) do
    for x := Low(TGridDimension) to High(TGridDimension) do
    begin
      HomeLayer[x, y] := (HomeLayer[x, y] + fHomeDeposits[x, y]) * DECAY_FACTOR;
      FoodLayer[x, y] := (FoodLayer[x, y] + fFoodDeposits[x, y]) * DECAY_FACTOR;

      fHomeDeposits[x, y] := 0;
      fFoodDeposits[x, y] := 0;
    end;

  // 3x3 box blur (diffusion)
  for y := Low(TGridDimension) to High(TGridDimension) do
    for x := Low(TGridDimension) to High(TGridDimension) do
    begin
      sumHome := 0;
      sumFood := 0;
      count := 0;

      for dy := -1 to 1 do
        for dx := -1 to 1 do
        begin
          nx := x + dx;
          ny := y + dy;
          if (nx >= 0) and (nx <= High(TGridDimension)) and
             (ny >= 0) and (ny <= High(TGridDimension)) then
          begin
            sumHome := sumHome + HomeLayer[nx, ny];
            sumFood := sumFood + FoodLayer[nx, ny];
            Inc(count);
          end;
        end;

      blurredHome[x, y] := sumHome / count;
      blurredFood[x, y] := sumFood / count;
    end;

  HomeLayer := blurredHome;
  FoodLayer := blurredFood;
end;

end.
