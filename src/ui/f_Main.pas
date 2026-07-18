unit f_Main;

interface

uses System.Generics.Collections,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,

  Vcl.ActnList, System.Actions, Vcl.StdActns, Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls,
  Vcl.ActnMenus, Vcl.PlatformDefaultStyleActnCtrls,

  u_SessionParameters, fr_Session, u_SessionLibraries;

type
  TMainForm = class(TForm)
    MainActions: TActionManager;
    ActionMainMenuBar1: TActionMainMenuBar;
    actExit: TFileExit;
    actNewSession: TAction;
    actSaveSession: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure actNewSessionExecute(Sender: TObject);
    procedure actSaveSessionExecute(Sender: TObject);
  private
    SessionFrame: TSessionFrame;
    SessionLibrary: TSessionLibrary;

    function CanCloseSession: Boolean;
    function CloseSession: Boolean;
    procedure HandleLibraryModified(Sender: TObject);
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses System.IOUtils,

  d_SessionManager, u_Colonies, u_Sessions;

const
  fnSessionLibrary = 'session_library.json';

{ Utility }
function RuntimeFilePath(const aFileName: string): string;
begin
  Result := TPath.Combine(ExtractFilePath(Application.ExeName), aFileName);
end;

{ TMainForm }
procedure TMainForm.FormCreate(Sender: TObject);
begin
  var sessionFileName := RuntimeFilePath(fnSessionLibrary);
  SessionLibrary := TSessionLibrary.Create(sessionFileName);
  SessionLibrary.OnModified := HandleLibraryModified;
  actSaveSession.Enabled := False;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  SessionLibrary.Free;
end;

procedure TMainForm.HandleLibraryModified(Sender: TObject);
begin
  actSaveSession.Enabled := True;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := CanCloseSession;
end;

procedure TMainForm.actSaveSessionExecute(Sender: TObject);
begin
  SessionLibrary.Save;
  actSaveSession.Enabled := False;
end;

function TMainForm.CanCloseSession: Boolean;
begin
  Result := True;
end;

function TMainForm.CloseSession: Boolean;
begin
  if (not CanCloseSession) then
    Exit(False);

  Result := True;
end;

procedure TMainForm.actNewSessionExecute(Sender: TObject);
begin
  if not CloseSession then
    Exit;

  var session: TSession;

  // select one
  var sm := TSessionManager.Create(Application);
  try
    session := sm.SelectSession(SessionLibrary);
  finally
    sm.Free;
  end;

  if Assigned(session) then
  begin
    var params := Default(TSessionParameters);
    params.Weights := Default(TColonyWeights);
    params.TotalAnts := session.Ants;
    params.TotalFoodUnits := session.Food;

    // create UI
    SessionFrame := TSessionFrame.Create(Self);
    SessionFrame.Align := alClient;
    SessionFrame.Parent := Self;
    SessionFrame.CreateSession(params);
  end;
end;


end.
