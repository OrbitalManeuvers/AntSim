unit u_Sessions;

interface

uses System.Classes;

type
  TSession = class
  private
    fName: string;
    fAnts: Integer;
    fFood: Integer;
    fOnChange: TNotifyEvent;
    fSeed: Integer;
    procedure SetAnts(const Value: Integer);
    procedure SetFood(const Value: Integer);
    procedure SetName(const Value: string);
    procedure Change;
    procedure SetSeed(const Value: Integer);
  public
    constructor Create;
    property Name: string read fName write SetName;
    property Ants: Integer read fAnts write SetAnts;
    property Food: Integer read fFood write SetFood;
    property Seed: Integer read fSeed write SetSeed;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;
  end;

implementation

{ TSession }

procedure TSession.Change;
begin
  if Assigned(fOnChange) then
    fOnChange(Self);
end;

constructor TSession.Create;
begin
  fAnts := 600;
  fFood := 20000;
  fSeed := 0; // random
end;

procedure TSession.SetAnts(const Value: Integer);
begin
  if Value <> fAnts then
  begin
    fAnts := Value;
    Change;
  end;
end;

procedure TSession.SetFood(const Value: Integer);
begin
  if Value <> fFood then
  begin
    fFood := Value;
    Change;
  end;
end;

procedure TSession.SetName(const Value: string);
begin
  if Value <> fName then
  begin
    fName := Value;
    Change;
  end;
end;

procedure TSession.SetSeed(const Value: Integer);
begin
  if Value <> fSeed then
  begin
    fSeed := Value;
    Change;
  end;
end;

end.
