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

implementation

end.
