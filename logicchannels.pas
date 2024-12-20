unit LogicChannels;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, channelsform;

type

  { TLogicChannelForm }

  TLogicChannelForm = class(TForm)
    ClockBtn: TButton;
    DataBtn: TButton;
    LogicChannelList: TListBox;
    procedure ClockBtnClick(Sender: TObject);
    procedure DataBtnClick(Sender: TObject);
  private

  public

  end;

var
  LogicChannelForm: TLogicChannelForm;

implementation

uses Main, ChartUtils, LineSerieUtils;

{$R *.lfm}

{ TLogicChannelForm }

procedure TLogicChannelForm.DataBtnClick(Sender: TObject);
var MiddleILine, Offset, YMin, YMax: Double;
begin
  if LogicChannelList.ItemIndex > -1 then begin
    DrawSerie(GetLineSerie(1, 1), CurrentSource, LogicChannelList.ItemIndex, 'Data');

    YMin:= GetLineSerie(1, 1).GetYMin;
    YMax:= GetLineSerie(1, 1).GetYMax;

    MiddleILine:= (YMin + YMax) / 2;
    Offset:= (YMax - YMin) * App.LogicTolerance.Value / 2 / 100;

    LowerLevelSerieData:= AddHorLineSerie(GetChart(1), 'HorizontalLine1', MiddleILine - Offset);
    UpperLevelSerieData:= AddHorLineSerie(GetChart(1), 'HorizontalLine2', MiddleILine + Offset);
  end;
end;

procedure TLogicChannelForm.ClockBtnClick(Sender: TObject);
var MiddleILine, Offset, YMin, YMax: Double;
begin
  if LogicChannelList.ItemIndex > -1 then begin
    DrawSerie(GetLineSerie(2, 1), CurrentSource, LogicChannelList.ItemIndex, 'Clock');

    YMin:= GetLineSerie(2, 1).GetYMin;
    YMax:= GetLineSerie(2, 1).GetYMax;

    MiddleILine:= (YMin + YMax) / 2;
    Offset:= (YMax - YMin) * App.LogicTolerance.Value / 2 / 100;

    LowerLevelSerieClock:= AddHorLineSerie(GetChart(2), 'HorizontalLine2', MiddleILine - Offset);
    UpperLevelSerieClock:= AddHorLineSerie(GetChart(2), 'HorizontalLine3', MiddleILine + Offset);
  end;
end;

end.

