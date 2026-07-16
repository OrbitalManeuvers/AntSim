unit u_Simulator;

interface

uses
  System.Generics.Collections,
  u_SimTypes, u_Colonies;

type
  TSimulator = class
  private
    fColonies: TList<TColony>;
    fNotifier: ISimNotifier;
  public
    Grid: TCellGrid;

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
  fNotifier := aNotifier;
end;

destructor TSimulator.Destroy;
begin
  fColonies.Free; // does not free the colonies themselves
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

  // TODO: apply deposits, decay, diffusion
end;

end.
