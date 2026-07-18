unit u_SessionLibraries;

interface

uses System.Classes, System.Generics.Collections,
  u_Sessions;

type
  TSessionLibrary = class
  private
    fFileName: string;
    fUntitled: Integer;
    fSessions: TObjectList<TSession>;
    fOnModified: TNotifyEvent;
    procedure Load;
    function GetSession(I: Integer): TSession;
    function GetCount: Integer;
    procedure HandleSessionChanged(Sender: TObject);
  public
    constructor Create(const aFileName: string);
    destructor Destroy; override;
    procedure Save;

    function CreateSession(const aName: string = ''): TSession;

    property Sessions[I: Integer]: TSession read GetSession;
    property Count: Integer read GetCount;
    property OnModified: TNotifyEvent read fOnModified write fOnModified;
  end;

implementation

uses System.SysUtils, System.IOUtils, System.JSON;

{ TSessionLibrary }

constructor TSessionLibrary.Create(const aFileName: string);
begin
  inherited Create;
  fFileName := aFileName;
  fSessions := TObjectList<TSession>.Create(True);
  fUntitled := 1;
  if TFile.Exists(aFileName) then
    Load;
end;

function TSessionLibrary.CreateSession(const aName: string): TSession;
begin
  Result := TSession.Create;
  Result.Name := 'Untitled' + Format('%.03d', [fUntitled]);
  Result.OnChange := HandleSessionChanged;
  fSessions.Add(Result);
  Inc(fUntitled);
end;

destructor TSessionLibrary.Destroy;
begin
  fSessions.Free;
  inherited;
end;

function TSessionLibrary.GetSession(I: Integer): TSession;
begin
  Result := fSessions[I];
end;

procedure TSessionLibrary.HandleSessionChanged(Sender: TObject);
begin
  if Assigned(fOnModified) then
    fOnModified(Self);
end;

function TSessionLibrary.GetCount: Integer;
begin
  Result := fSessions.Count;
end;

procedure TSessionLibrary.Load;
begin
  var json: TJSONObject := TJSONValue.ParseJSONValue(TFile.ReadAllText(fFileName)) as TJSONObject;
  if Assigned(json) then
  begin

  end;


end;

procedure TSessionLibrary.Save;
begin
  //
end;

end.
