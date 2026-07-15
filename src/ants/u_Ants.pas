unit u_Ants;

interface

uses System.Types;

type
  TAntState = (asSearching, asReturning);

  TAnt = record
    Loc: TPoint;
    State: TAntState;
  end;

implementation

end.
