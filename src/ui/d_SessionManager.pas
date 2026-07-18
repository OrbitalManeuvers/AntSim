unit d_SessionManager;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons,
  Vcl.ControlList, System.Actions, Vcl.ActnList,

  u_Sessions, u_SessionLibraries;

type
  TSessionManager = class(TForm)
    Label1: TLabel;
    SessionList: TControlList;
    btnNewSession: TSpeedButton;
    btnDeleteSession: TSpeedButton;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    edtName: TEdit;
    mmoNotes: TMemo;
    edtMap: TEdit;
    btnBrowse: TSpeedButton;
    edtAnts: TEdit;
    edtFood: TEdit;
    btnLaunch: TButton;
    btnCancel: TButton;
    lblSessionName: TLabel;
    procedure btnLaunchClick(Sender: TObject);
    procedure SessionListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure btnBrowseClick(Sender: TObject);
    procedure SessionListItemClick(Sender: TObject);
    procedure edtAntsChange(Sender: TObject);
    procedure edtFoodChange(Sender: TObject);
  private
    fLibrary: TSessionLibrary;
    procedure UpdateControls;
    procedure SelectionChanged;
  public
    function SelectSession(aLibrary: TSessionLibrary): TSession;
  end;


implementation

{$R *.dfm}

procedure TSessionManager.btnBrowseClick(Sender: TObject);
begin
  //
end;

procedure TSessionManager.btnLaunchClick(Sender: TObject);
begin
  //
end;

procedure TSessionManager.edtAntsChange(Sender: TObject);
begin
  if SessionList.ItemIndex <> -1 then
  begin
    var value := StrToIntDef(edtAnts.Text, -1);
    if value <> -1 then
      fLibrary.Sessions[SessionList.ItemIndex].Ants := Value;
  end;
end;

procedure TSessionManager.edtFoodChange(Sender: TObject);
begin
  if SessionList.ItemIndex <> -1 then
  begin
    var value := StrToIntDef(edtFood.Text, -1);
    if value <> -1 then
      fLibrary.Sessions[SessionList.ItemIndex].Food := Value;
  end;
end;

procedure TSessionManager.SessionListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if SessionList.ItemIndex <> -1 then
    lblSessionName.Caption := fLibrary.Sessions[SessionList.ItemIndex].Name;
end;

procedure TSessionManager.SessionListItemClick(Sender: TObject);
begin
  SelectionChanged;
end;

procedure TSessionManager.SelectionChanged;
begin
  if SessionList.ItemIndex <> -1 then
  begin
    var s := fLibrary.Sessions[SessionList.ItemIndex];
    edtName.Text := s.Name;
    mmoNotes.Text := '';
    edtAnts.Text := s.Ants.ToString;
    edtFood.Text := s.Food.ToString;
  end;

  UpdateControls;
end;

function TSessionManager.SelectSession(aLibrary: TSessionLibrary): TSession;
begin
  Result := nil;
  fLibrary := aLibrary;

  // create a session if none exists
  if fLibrary.Count = 0 then
    fLibrary.CreateSession('');

  SessionList.ItemCount := fLibrary.Count;
  SessionList.ItemIndex := 0;
  SelectionChanged;

  if ShowModal = mrOK then
    Result := fLibrary.Sessions[SessionList.ItemIndex];
end;

procedure TSessionManager.UpdateControls;
begin
  btnLaunch.Enabled := SessionList.ItemIndex <> -1;
end;

end.
