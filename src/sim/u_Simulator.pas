unit u_Simulator;

interface

uses
  System.Generics.Collections, System.Types,
  u_SimTypes, u_Colonies;

type
  TSimulator = class
  private
    fColonies: TList<TColony>;
    fNotifier: ISimNotifier;
  public
    Grid: TCellGrid;
    FoodCells: TList<TPoint>;

    constructor Create(const aNotifier: ISimNotifier);
    destructor Destroy; override;

    procedure AddColony(aColony: TColony);
    procedure Step;
  end;

implementation

constructor TSimulator.Create(const aNotifier: ISimNotifier);
begin
  inherited Create;
  fColonies := TList<TColony>.Create;
  FoodCells := TList<TPoint>.Create;
  fNotifier := aNotifier;
end;

destructor TSimulator.Destroy;
begin
  fColonies.Free; // does not free the colonies themselves
  FoodCells.Free;
  inherited;
end;

procedure TSimulator.AddColony(aColony: TColony);
begin
  fColonies.Add(aColony);
end;

procedure TSimulator.Step;
var
  Col: TColony;
begin
  for Col in fColonies do
    Col.StepAnts(Grid, fNotifier);

  for Col in fColonies do
  begin
    Col.ApplyFoodHints(Grid, FoodCells);
    Col.ApplyNestHint;
    Col.ApplyPheromones;
  end;
end;

end.
