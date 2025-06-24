unit ChartOptions;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  IniPropStorage, ColorBox, TAGraph, TACustomSource;

type

  { TChartOptionsForm }

  TChartOptionsForm = class(TForm)
    Button1: TButton;
    AtDataOnly: TCheckBox;
    GChartBGColor: TColorBox;
    IniPropStorage1: TIniPropStorage;
    Label4: TLabel;
    Label5: TLabel;
    LogBase: TFloatSpinEdit;
    YInvertedChk: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    RangeMax: TFloatSpinEdit;
    RangeMin: TFloatSpinEdit;
    UseRangeChk: TCheckBox;
    LogarithmicChk: TCheckBox;
    IntervalCount: TSpinEdit;
    procedure AtDataOnlyChange(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure GChartBGColorChange(Sender: TObject);
    procedure IntervalCountChange(Sender: TObject);
    procedure LogarithmicChkChange(Sender: TObject);
    procedure LogBaseChange(Sender: TObject);
    procedure RangeMaxChange(Sender: TObject);
    procedure RangeMinChange(Sender: TObject);
    procedure UseRangeChkChange(Sender: TObject);
    procedure YInvertedChkChange(Sender: TObject);
  private

  public

  end;

var
  ChartOptionsForm: TChartOptionsForm;

implementation

uses
  Main, ChartUtils;

{$R *.lfm}

{ TChartOptionsForm }

procedure TChartOptionsForm.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TChartOptionsForm.GChartBGColorChange(Sender: TObject);
begin
  GetChart(SelectedChart).BackColor:= ChartOptionsForm.GChartBGColor.Selected;
end;

procedure TChartOptionsForm.AtDataOnlyChange(Sender: TObject);
var Chart: TChart;
begin
  Chart:= GetChart(SelectedChart);
  Chart.AxisList[0].Marks.AtDataOnly:= ChartOptionsForm.AtDataOnly.Checked;
end;

procedure TChartOptionsForm.LogarithmicChkChange(Sender: TObject);
var Chart: TChart;
begin
  Chart:= GetChart(SelectedChart);
  GetLogarithmTransform(SelectedChart).Enabled:= LogarithmicChk.Checked;
  GetLogarithmTransform(SelectedChart).Base:= ChartOptionsForm.LogBase.Value;
  if Not LogarithmicChk.Checked then ChartDefaultSettings(Chart)
  else begin
    Chart.AxisList[0].Intervals.Count:= IntervalCount.Value;
    Chart.AxisList[0].Intervals.Options:= [aipUseCount];
    UseRangeChk.Checked:= False;
  end;
end;

procedure TChartOptionsForm.LogBaseChange(Sender: TObject);
var Chart: TChart;
begin
  if (SelectedChart > 0) And (LogBase.Value > 0) And (Not (LogBase.Value = 1)) then begin
    GetLogarithmTransform(SelectedChart).Base:= LogBase.Value;
  end;
end;

procedure TChartOptionsForm.RangeMaxChange(Sender: TObject);
var Chart: TChart;
begin
  Chart:= GetChart(SelectedChart);
  Chart.AxisList[0].Range.Max:= RangeMax.Value;
end;

procedure TChartOptionsForm.RangeMinChange(Sender: TObject);
var Chart: TChart;
begin
  Chart:= GetChart(SelectedChart);
  Chart.AxisList[0].Range.Min:= RangeMin.Value;
end;

procedure TChartOptionsForm.IntervalCountChange(Sender: TObject);
var Chart: TChart;
begin
  if SelectedChart > 0 then begin
    Chart:= GetChart(SelectedChart);
    Chart.AxisList[0].Intervals.Count:= ChartOptionsForm.IntervalCount.Value;
  end;
end;

procedure TChartOptionsForm.UseRangeChkChange(Sender: TObject);
var Chart: TChart;
begin
  Chart:= GetChart(SelectedChart);
  RangeMin.Enabled:= UseRangeChk.Checked;
  RangeMax.Enabled:= UseRangeChk.Checked;
  IntervalCount.Enabled:= UseRangeChk.Checked;
  Chart.AxisList[0].Range.UseMin:= UseRangeChk.Checked;
  Chart.AxisList[0].Range.UseMax:= UseRangeChk.Checked;
  RangeMin.Value:= Chart.AxisList[0].Range.Min;
  RangeMax.Value:= Chart.AxisList[0].Range.Max;
  if UseRangeChk.Checked then Chart.AxisList[0].Intervals.Options:= [aipUseCount]
  else ChartDefaultSettings(Chart);
end;

procedure TChartOptionsForm.YInvertedChkChange(Sender: TObject);
var Chart: TChart;
begin
  Chart:= GetChart(SelectedChart);
  Chart.AxisList[0].Inverted:= YInvertedChk.Checked;
end;

end.

