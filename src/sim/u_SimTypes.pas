unit u_SimTypes;

interface

uses System.Types;

const
  GRID_EXTENT = 256;

type
  TGridDimension = 0 .. GRID_EXTENT - 1;

  TCell = record
    Passable: Boolean;
    FoodAmount: Integer;
  end;
  TCellGrid = array[TGridDimension, TGridDimension] of TCell;

  TPheromoneLayer = array[TGridDimension, TGridDimension] of Single;

  ISimNotifier = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    procedure FoodTaken(const aLoc: TPoint);
    procedure FoodDelivered(const aNest: TPoint);
    procedure FoodDropped(const aLoc: TPoint);
  end;

  TSimRate = (sr0x, sr1x); // , sr5x, ...

implementation

end.
