unit u_SessionParameters;

interface

uses System.Generics.Collections,

  u_SimTypes, u_Colonies;

type
  TSessionParameters = record
    // colony definitions
    // map definition/selection
    Weights: TColonyWeights;
    TotalAnts: Integer;
    TotalFoodUnits: Integer;
  end;

implementation


end.
