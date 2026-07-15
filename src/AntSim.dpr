program AntSim;

uses
  Vcl.Forms,
  f_Main in 'ui\f_Main.pas' {MainForm},
  u_SimTypes in 'sim\u_SimTypes.pas',
  u_Ants in 'ants\u_Ants.pas',
  u_Colonies in 'ants\u_Colonies.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
