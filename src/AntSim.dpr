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
  u_GraphicButtonBars in 'ui\u_GraphicButtonBars.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
