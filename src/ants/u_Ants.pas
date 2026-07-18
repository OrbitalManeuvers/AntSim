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
    TicksSincePickup: Integer; // reset to 0 when food is picked up; increments while returning
    WobbleFactor: Single; // individual variation: 0.5 = tight, 1.5 = loose
  end;

implementation

end.
