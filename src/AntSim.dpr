program AntSim;

uses
  Vcl.Forms,
  f_Main in 'ui\f_Main.pas' {MainForm},
  u_SimTypes in 'sim\u_SimTypes.pas',
  u_Ants in 'ants\u_Ants.pas',
  u_Colonies in 'ants\u_Colonies.pas',
  u_SimController in 'sim\u_SimController.pas',
  u_Simulator in 'sim\u_Simulator.pas',
  u_SessionParameters in 'sim\u_SessionParameters.pas',
  fr_Session in 'ui\fr_Session.pas' {SessionFrame: TFrame},
  u_GraphicButtonBars in 'ui\u_GraphicButtonBars.pas',
  Vcl.Themes,
  Vcl.Styles,
  d_SessionManager in 'ui\d_SessionManager.pas' {SessionManager},
  u_Sessions in 'sim\u_Sessions.pas',
  u_SessionLibraries in 'sim\u_SessionLibraries.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Klondike');
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
