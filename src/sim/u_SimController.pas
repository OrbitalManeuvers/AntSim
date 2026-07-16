unit u_SimController;

interface

uses u_SimTypes, u_Simulator;

type
  TSimController = class
  private
    fSimulator: TSimulator;
    fRate: TSimRate;
    procedure SetSimulator(const Value: TSimulator);
    procedure SetRate(const Value: TSimRate);

  public
    constructor Create;
    destructor Destroy; override;
    property Rate: TSimRate read fRate write SetRate;
    property Simulator: TSimulator read fSimulator write SetSimulator;
  end;

implementation


{ TSimController }

constructor TSimController.Create;
begin
  inherited Create;
end;

destructor TSimController.Destroy;
begin

  inherited;
end;

procedure TSimController.SetRate(const Value: TSimRate);
begin
  fRate := Value;
end;

procedure TSimController.SetSimulator(const Value: TSimulator);
begin
  fSimulator := Value;
end;

end.
