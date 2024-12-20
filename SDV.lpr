program SDV;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, tachartlazaruspkg, tachartaggpas, datetimectrls, lazcontrols,
  printer4lazarus, Main, UserTypes, Utils, TffObjects, ParseBinDb, ChannelsForm,
  LineSerieUtils, ParamOptions, LimitsForm, SIBRParam, HorLineOptions,
  ParameterSet, ParseCSV, ChartOptions, Navigation, LogicChannels
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TApp, App);
  Application.CreateForm(TShowChannelForm, ShowChannelForm);
  Application.CreateForm(TParamOptionsForm, ParamOptionsForm);
  Application.CreateForm(TLimitForm, LimitForm);
  Application.CreateForm(THorLineForm, HorLineForm);
  Application.CreateForm(TParamSetFrm, ParamSetFrm);
  Application.CreateForm(TChartOptionsForm, ChartOptionsForm);
  Application.CreateForm(TNavigationForm, NavigationForm);
  Application.CreateForm(TLogicChannelForm, LogicChannelForm);
  Application.Run;
end.

