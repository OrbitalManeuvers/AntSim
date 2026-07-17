unit f_Main;

interface

uses System.Generics.Collections,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,

  Vcl.ActnList, System.Actions, Vcl.StdActns, Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls,
  Vcl.ActnMenus, Vcl.PlatformDefaultStyleActnCtrls,

  u_SessionParameters, fr_Session;

type
  TMainForm = class(TForm)
    MainActions: TActionManager;
    ActionMainMenuBar1: TActionMainMenuBar;
    actExit: TFileExit;
    actNewSession: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure actNewSessionExecute(Sender: TObject);
  private
    SessionFrame: TSessionFrame;

    function CanCloseSession: Boolean;
    function CloseSession: Boolean;
    procedure CreateNewSession(const aFileName: string);
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses System.IOUtils;

{ TMainForm }
procedure TMainForm.FormCreate(Sender: TObject);
begin
//  RandSeed := 42;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
   //
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := CanCloseSession;
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

procedure TMainForm.CreateNewSession(const aFileName: string);
begin

  var params := Default(TSessionParameters);
  params.TotalAnts := 500;
  params.TotalFoodUnits := 20000;

  if (aFilename <> '') and TFile.Exists(aFileName) then
  begin
    // load from file
  end;

  // create UI
  SessionFrame := TSessionFrame.Create(Self);
  SessionFrame.Align := alClient;
  SessionFrame.Parent := Self;
  SessionFrame.CreateSession(params);
end;

procedure TMainForm.actNewSessionExecute(Sender: TObject);
begin
  if not CloseSession then
    Exit;

  CreateNewSession('');
end;


end.
