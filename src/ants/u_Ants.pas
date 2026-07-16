unit u_Ants;

interface

uses System.Types;

type
  TAntState = (asInNest, asSearching, asReturning);

  TAnt = record
    Loc: TPoint;
    Angle: Single;      // radians, 0 = east, Pi/2 = south
    State: TAntState;
    TicksAlive: Integer; // 0 while asInNest; increments each tick once active
  end;

implementation

end.
