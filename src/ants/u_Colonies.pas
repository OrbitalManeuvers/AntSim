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
    fAnts: TList<TAnt>;
    fNest: TPoint;

    Weights: TColonyWeights;
    HomeLayer: TPheromoneLayer;
    FoodLayer: TPheromoneLayer;
    HomeDeposits: TPheromoneLayer;  // accumulator, zeroed after apply
    FoodDeposits: TPheromoneLayer;

    function GetAnt(I: Integer): TAnt;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Ants[I: Integer]: TAnt read GetAnt;
    property AntCount: Integer read GetCount;
    property Nest: TPoint read fNest write fNest;
  end;

implementation

{ TColony }

constructor TColony.Create;
begin
  inherited Create;
  fAnts := TList<TAnt>.Create;
end;

destructor TColony.Destroy;
begin
  fAnts.Free;
  inherited;
end;

function TColony.GetAnt(I: Integer): TAnt;
begin
  Result := fAnts[I];
end;

function TColony.GetCount: Integer;
begin
  Result := fAnts.Count;
end;

end.
