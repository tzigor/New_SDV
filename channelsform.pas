unit channelsform;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  LineSerieUtils, ChartUtils, TASeries, LCLType, ComCtrls, IniPropStorage,
  ExtCtrls, TAGraph, DateUtils, Types, StrUtils, TAChartUtils, ParameterSet,
  SIBRParam, uComplex;

type

  { TShowChannelForm }

  TShowChannelForm = class(TForm)
    PrintToCSVbtn: TButton;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    DrawGroupBtn: TButton;
    ChannelList: TListBox;
    FastLabel: TLabel;
    FastMode: TCheckBox;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    SaveDialog1: TSaveDialog;
    SIBRParamLbl: TLabel;
    MultiColumns: TCheckBox;
    DrawBtn: TBitBtn;
    CloseList: TBitBtn;
    FileList: TListBox;
    RecordCount: TLabel;
    RecordsNumber: TTrackBar;
    SIBRParamList: TListBox;
    SlowLabel: TLabel;
    Splitter1: TSplitter;
    procedure ChannelListDblClick(Sender: TObject);
    procedure ChannelListDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure CloseListClick(Sender: TObject);
    procedure DrawBtnClick(Sender: TObject);
    procedure DrawGroupBtnClick(Sender: TObject);
    procedure FastModeChange(Sender: TObject);
    procedure FileListDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure FileListKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FileListSelectionChange(Sender: TObject; User: boolean);
    procedure FormCreate(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure Image2Click(Sender: TObject);
    procedure Image3Click(Sender: TObject);
    procedure MultiColumnsChange(Sender: TObject);
    procedure PrintToCSVbtnClick(Sender: TObject);
    procedure RecordsNumberChange(Sender: TObject);
    procedure SIBRParamListClick(Sender: TObject);
    procedure SIBRParamListDblClick(Sender: TObject);
    procedure SIBRParamListDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
  private

  public

  end;

  function DrawChart(SelectedParamName: String; ItemIndex: Integer; NewChart, SIBRParam: Boolean): Integer;

var
  ShowChannelForm: TShowChannelForm;

implementation
uses Main, Utils, UserTypes;

{$R *.lfm}

{ TShowChannelForm }

procedure TShowChannelForm.CloseListClick(Sender: TObject);
begin
  ShowChannelForm.Close;
end;

procedure TShowChannelForm.ChannelListDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
begin
   with ChannelList do begin
     if StrInArray(Items[Index], AmplitudesChannels)
        Or StrInArray(Items[Index], AmplitudesChannelsExt)  then Canvas.Font.Color:= clBlue
     else if StrInArray(Items[Index], PhaseChannels)
             OR StrInArray(Items[Index], PhaseChannelsExt) then Canvas.Font.Color:= RGBToColor(200, 70, 70)
           else if StrInArray(Items[Index], VoltChannels) then Canvas.Font.Color:= RGBToColor(255, 0, 0)
                else if StrInArray(Items[Index], SystemChannels) then Canvas.Font.Color:= RGBToColor(200, 0, 200);

     if (odSelected in State) then begin
       Canvas.Brush.Color:= clBlue;
       Canvas.Font.Color:= clWhite;
     end;

     Canvas.FillRect(ARect);
     Canvas.TextOut(ARect.Left, ARect.Top, Items[Index]);
    end
end;

function DrawChart(SelectedParamName: String; ItemIndex: Integer; NewChart, SIBRParam: Boolean): Integer;
var Chart, ExChart    : TChart;
    i, ExChartIndx    : Byte;
    nStr              : String;
begin
    if NewChart then begin
       if ChartsCount < MAX_CHART_NUMBER then begin
         CurrentChart:= GetFreeChart;
         Inc(ChartsCount);
       end
       else begin
         Result:= -1; { MAX_CHART_NUMBER limit exceeded }
         Exit;
       end;
    end;
    Chart:= GetChart(CurrentChart);
    ChartDefaultSettings(Chart);
    CurrentSerie:= GetFreeLineSerie(CurrentChart);
    if CurrentSerie = 0 then begin
       Result:= -2; { MAX_SERIE_NUMBER limit exceeded }
       Exit;
    end;

    Chart.Title.Text[0]:= Chart.Name;
    ParametersUnits[CurrentChart, CurrentSerie]:= '';
    if Not SIBRParam then begin
      ParametersUnits[CurrentChart, CurrentSerie]:= DataSources[CurrentSource].TFFDataChannels[ItemIndex].Units;
    end;
    if ItemIndex > -1 then DrawSerie(GetLineSerie(CurrentChart, CurrentSerie), CurrentSource, ItemIndex, SelectedParamName);
    Chart.Visible:= True;
    GetSplitter(GetChartNumber(Chart.Name)).Visible:= True;
    ChartsPosition();

    ExChartIndx:= GetFirstVisibleChart();
    if (ExChartIndx > 0) And (CurrentChart <> ExChartIndx) then begin
      ExChart:= GetChart(ExChartIndx);
      for i:=MAX_SERIE_NUMBER + 1 to ExChart.SeriesCount do begin
        if i - MAX_SERIE_NUMBER < 10 then nStr:= '0'+ IntToStr(i - MAX_SERIE_NUMBER)
        else nStr:= IntToStr(i - MAX_SERIE_NUMBER);
        if (NPos('VerticalLine' + nStr, ExChart.Series[i - 1].Name, 1) > 0) And NewChart then begin
           AddConstLineSerie(Chart, ExChart.Series[i - 1].Name, TConstantLine(ExChart.Series[i - 1]).Position);
        end;
      end;
    end;
    ProgressDone;
end;

procedure DrawMultiSeries(ToOneChart : Boolean);
var i, Status  : Integer;
    Multichart : Boolean = True;
begin
    for i:=0 to ShowChannelForm.ChannelList.Count - 1 do begin
      if ShowChannelForm.ChannelList.Selected[i] then begin
          Status:= DrawChart(ShowChannelForm.ChannelList.Items[i], i, Multichart, SIBRParamListActive);
          if ToOneChart then Multichart:= False;
          if Status = -1 then begin
             ShowMessage('Too many charts. Limit is ' + IntToStr(MAX_CHART_NUMBER));
             Exit;
          end;
          if Status = -2 then begin
             ShowMessage('Too many series. Limit is ' + IntToStr(MAX_SERIE_NUMBER));
             Exit;
          end;
      end;
    end;
    ShowChannelForm.ChannelList.ClearSelection;
    for i:=0 to ShowChannelForm.SIBRParamList.Count - 1 do begin
      if ShowChannelForm.SIBRParamList.Selected[i] then begin
          Status:= DrawChart(ShowChannelForm.SIBRParamList.Items[i], i, Multichart, SIBRParamListActive);
          if ToOneChart then Multichart:= False;
          if Status = -1 then begin
             ShowMessage('Too many charts. Limit is ' + IntToStr(MAX_CHART_NUMBER));
             Exit;
          end;
          if Status = -2 then begin
             ShowMessage('Too many series. Limit is ' + IntToStr(MAX_SERIE_NUMBER));
             Exit;
          end;
      end;
    end;
    ShowChannelForm.SIBRParamList.ClearSelection;
end;

procedure TShowChannelForm.DrawBtnClick(Sender: TObject);
begin
  DrawMultiSeries(False);
end;

procedure TShowChannelForm.DrawGroupBtnClick(Sender: TObject);
begin
  DrawMultiSeries(True);
end;

procedure PrintToCSV();
var i, FramesCount  : LongInt;
    j, numParam     : Integer;
    CSVData         : TStringList;
    Header, Name    : String;
    Channels        : TStringList;
    isAplitude      : Boolean = False;
    isPhaseShift    : Boolean = False;
    ValidValue      : Boolean;
    SelectedSource  : Word;
    StartParamPos   : Word;
    Step            : Word;
    Value           : Double;
    RawR, RawX      : Double;
    Indexes         : Array of Word;
    DataLine        : String;
    iPrevPercent, n : Integer;
    DataSelected    : Boolean = False;
    SDateTime       : String;
begin
  Header:= 'TIME' + CSVSeparator;
  CSVData:= TStringList.Create;
  Channels:= TStringList.Create;
  SetLength(Indexes, 0);

  for i:=0 to ShowChannelForm.ChannelList.Count - 1 do
    if ShowChannelForm.ChannelList.Selected[i] then begin
       Header:= Header + ShowChannelForm.ChannelList.Items[i] + CSVSeparator;
       Channels.Add(ShowChannelForm.ChannelList.Items[i]);
       Insert(i, Indexes, DATA_MAX_SIZE);
       DataSelected:= True;
    end;
  for i:=0 to ShowChannelForm.SIBRParamList.Count - 1 do
    if ShowChannelForm.SIBRParamList.Selected[i] then begin
       Header:= Header + ShowChannelForm.SIBRParamList.Items[i] + CSVSeparator;
       Channels.Add(ShowChannelForm.SIBRParamList.Items[i]);
       Insert(i, Indexes, DATA_MAX_SIZE);
       DataSelected:= True;
    end;

  if DataSelected then begin

      CSVData.Add(LeftStr(Header, Length(Header)-1));

      ShowChannelForm.ChannelList.ClearSelection;
      ShowChannelForm.SIBRParamList.ClearSelection;

      SelectedSource:= CurrentSource;
      FramesCount:= Length(DataSources[SelectedSource].FrameRecords);

      ProgressInit(100, 'Process channel');
      iPrevPercent:= 0;

      for i:=0 to FramesCount - 1 do begin

         DateTimeToString(SDateTime, 'hh:mm:ss dd-mmm-yy', DataSources[SelectedSource].FrameRecords[i].DateTime);

         DataLine:= SDateTime + CSVSeparator;
         for j:=0 to Channels.Count - 1 do begin
            Name:= Channels[j];

            if FindPart('AR???F', Name) > 0 then isAplitude:= True;
            if FindPart('PR???F', Name) > 0 then isPhaseShift:= True;

            if isAplitude Or isPhaseShift then begin
                numParam:= NameToInt(Name);
                if numParam >= 1000 then begin
                   StartParamPos:= GetParamPosition('VR1C0F1r');
                   numParam:= numParam - 1000;
                end
                else StartParamPos:= GetParamPosition('VR1T0F1r');
                if (numParam mod 2) = 0 then Step:= (numParam div 2) * 8
                else Step:= ((numParam div 2) * 8) + 2;
            end;

            if Name in CondChannels then Value:= GetSonde(SelectedSource, Name, i)
            else if Name in CondCompChannels then Value:= GetCompSonde(SelectedSource, Name, i)
                 else begin
                    if isAplitude Or isPhaseShift then begin
                        ValidValue:= GetChannelValue(DataSources[SelectedSource].TFFDataChannels,
                                       DataSources[SelectedSource].FrameRecords[i],
                                       StartParamPos + Step,
                                       RawR);
                        ValidValue:= GetChannelValue(DataSources[SelectedSource].TFFDataChannels,
                                       DataSources[SelectedSource].FrameRecords[i],
                                       StartParamPos + Step + 1,
                                       RawX) And ValidValue;

                        if isAplitude then Value:= Sqrt(Sqr(RawR)+Sqr(RawX));
                        if isPhaseShift then
                          if RawR <> 0 then Value:= Angle(cInit(RawR, RawX)) * 180/Pi;
                    end
                    else ValidValue:= GetChannelValue(DataSources[SelectedSource].TFFDataChannels,
                                       DataSources[SelectedSource].FrameRecords[i],
                                       Indexes[j],
                                       Value);
                 end;

            if ValidValue then begin
               DataLine:= DataLine + FloatToStr(Value) + CSVSeparator;
            end;

         end;

         CSVData.Add(LeftStr(DataLine, Length(DataLine)-1));

         n:= Trunc(i * 100 / FramesCount);
         if (n > iPrevPercent) then begin
           App.ProcessProgress.Position:= n;
           iPrevPercent:= n;
         end;

      end;

      ShowChannelForm.SaveDialog1.FileName:= ReplaceText(DataSources[SelectedSource].SourceName, ExtractFileExt(DataSources[SelectedSource].SourceName), '.csv');
      if ShowChannelForm.SaveDialog1.Execute then
         CSVData.SaveToFile(ShowChannelForm.SaveDialog1.FileName);
  end
  else ShowMessage('No data selected');

  CSVData.Clear;
  CSVData.Free;
  Channels.Clear;
  Channels.Free;
  SetLength(Indexes, 0);
  ProgressDone();
end;

procedure TShowChannelForm.ChannelListDblClick(Sender: TObject);
var Status  : Integer;
begin
  if ChannelList.ItemIndex = -1 then Exit;
  Status:= DrawChart(ShowChannelForm.ChannelList.Items[ChannelList.ItemIndex], ChannelList.ItemIndex, True, False);
  ShowChannelForm.ChannelList.ClearSelection;
  if Status = -1 then begin
     ShowMessage('Too many charts. Limit is ' + IntToStr(MAX_CHART_NUMBER));
     Exit;
  end;
end;

procedure TShowChannelForm.SIBRParamListDblClick(Sender: TObject);
var Status  : Integer;
begin
  if SIBRParamList.ItemIndex = -1 then Exit;
  Status:= DrawChart(ShowChannelForm.SIBRParamList.Items[SIBRParamList.ItemIndex], SIBRParamList.ItemIndex, True, False);
  ShowChannelForm.SIBRParamList.ClearSelection;
  if Status = -1 then begin
     ShowMessage('Too many charts. Limit is ' + IntToStr(MAX_CHART_NUMBER));
     Exit;
  end;
end;

//procedure TShowChannelForm.DrawBtnClick(Sender: TObject);
//var Chart, ExChart    : TChart;
//    i, ExChartIndx    : Byte;
//    nStr              : String;
//    SelectedParamName : String;
//begin
//   if ChartsCount < MAX_CHART_NUMBER then begin
//      CurrentChart:= GetFreeChart;
//      Chart:= GetChart(CurrentChart);
//      Inc(ChartsCount);
//      CurrentSerie:= GetFreeLineSerie(CurrentChart);
//      Chart.Visible:= True;
//      Chart.Title.Text[0]:= Chart.Name;
//      ParametersUnits[CurrentChart, CurrentSerie]:= '';
//      if ChannelList.ItemIndex > -1 then begin
//        SelectedParamName:= ChannelList.Items[ChannelList.ItemIndex];
//        ParametersUnits[CurrentChart, CurrentSerie]:= DataSources[CurrentSource].TFFDataChannels[ChannelList.ItemIndex].Units;
//      end;
//      if SIBRParamList.ItemIndex > -1 then SelectedParamName:= SIBRParamList.Items[SIBRParamList.ItemIndex];
//      DrawSerie(GetLineSerie(CurrentChart, CurrentSerie), CurrentSource, ChannelList.ItemIndex, SelectedParamName);
//      ChartsPosition();
//
//      ExChartIndx:= GetFirstVisibleChart();
//      if (ExChartIndx > 0) And (CurrentChart <> ExChartIndx) then begin
//        ExChart:= GetChart(ExChartIndx);
//        for i:=MAX_SERIE_NUMBER + 1 to ExChart.SeriesCount do begin
//          if i - MAX_SERIE_NUMBER < 10 then nStr:= '0'+ IntToStr(i - MAX_SERIE_NUMBER)
//          else nStr:= IntToStr(i - MAX_SERIE_NUMBER);
//          if NPos('VerticalLine' + nStr, ExChart.Series[i - 1].Name, 1) > 0 then begin
//             AddConstLineSerie(Chart, ExChart.Series[i - 1].Name, TConstantLine(ExChart.Series[i - 1]).Position);
//          end;
//        end;
//      end;
//
//   end
//   else Application.MessageBox('Too many charts','Error', MB_ICONERROR + MB_OK);
//   ProgressDone;
//end;

procedure TShowChannelForm.FastModeChange(Sender: TObject);
begin
  SetFastMode(FastMode.Checked);
end;

procedure TShowChannelForm.FileListDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
begin
  with FileList do begin
    if (odSelected in State) then begin
       if Focused then begin
         Canvas.Brush.Color:= clHighlight;
         Canvas.Font.Color:= clWhite;
       end
       else begin
         Canvas.Brush.Color:= clSilver;
         Canvas.Font.Color:= clBlack;
       end
    end;
    Canvas.FillRect(ARect);
    Canvas.TextOut(ARect.Left, ARect.Top, Items[Index]);
  end;
end;

procedure TShowChannelForm.FileListKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
Var i, j, Source  : Byte;
    Serie         : TLineSeries;
    SerieSource   : Byte;
    SerieName     : String;
begin
  if (Key = 46) Or (Key = 8) then begin

    Source:= FileList.ItemIndex;
    for i:= 1 to MAX_CHART_NUMBER do
       for j:= 1 to MAX_SERIE_NUMBER do begin
          Serie:= GetLineSerie(i, j);
          SerieSource:= GetSerieSource(Serie.Title);
          if SerieSource = Source then begin
            Serie.Legend.Visible:= False;
            Serie.Clear;
          end
          else if SerieSource > Source then begin
                 Dec(SerieSource);
                 SerieName:= Serie.Title;
                 Delete(SerieName, 1, 2);
                 Serie.Title:= AddLidZeros(IntToStr(SerieSource + 1), 2) + SerieName
               end;
       end;

    RemoveEmptyCharts();
    Delete(DataSources, FileList.ItemIndex, 1);
    Dec(SourceCount);
    if SourceCount > 0 then PrepareChannelForm()
    else ShowChannelForm.Close;
  end;
end;

procedure TShowChannelForm.FileListSelectionChange(Sender: TObject;
  User: boolean);
begin
  if (SourceCount > 1) And Not NewFileOpened then begin
    CurrentSource:= FileList.ItemIndex;
    if Length(DataSources[CurrentSource].FrameRecords) > 50000 then FastMode.Checked:= True
    else FastMode.Checked:= False;
    FillChannelList();
  end;
  NewFileOpened:= False;
end;

procedure TShowChannelForm.FormCreate(Sender: TObject);
var i: Byte;
begin
  SetFastMode(ShowChannelForm.FastMode.Checked);
  for i:= 0 to 19 do ShowChannelForm.SIBRParamList.Items.Add(AmplitudesChannels[i]);
  for i:= 0 to 19 do ShowChannelForm.SIBRParamList.Items.Add(PhaseChannels[i]);
  for i:= 0 to 11 do  ShowChannelForm.SIBRParamList.Items.Add(CondChannels[i]);
  for i:= 0 to 11 do ShowChannelForm.SIBRParamList.Items.Add(CondCompChannels[i]);
end;

procedure TShowChannelForm.MultiColumnsChange(Sender: TObject);
begin
  if MultiColumns.Checked then begin
    ChannelList.Columns:= 3;
    SIBRParamList.Columns:= 3;
  end
  else begin
    ChannelList.Columns:= 0;
    SIBRParamList.Columns:= 0;
  end;
end;

procedure TShowChannelForm.PrintToCSVbtnClick(Sender: TObject);
begin
  PrintToCSV();
end;

procedure TShowChannelForm.RecordsNumberChange(Sender: TObject);
begin
  RecordCount.Caption:= 'Divide by ' + IntToStr(RecordsNumber.Position);
  FastModeDivider:= RecordsNumber.Position;
end;

procedure TShowChannelForm.SIBRParamListClick(Sender: TObject);
begin

end;

procedure TShowChannelForm.SIBRParamListDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
begin
     with SIBRParamList do begin
     if Items[Index] in AmplitudesChannels then Canvas.Font.Color:= clBlue
     else if Items[Index] in CondChannels then Canvas.Font.Color:= RGBToColor(0, 100, 0)
          else if Items[Index] in CondCompChannels then Canvas.Font.Color:= RGBToColor(255, 0, 0);

     if (odSelected in State) then begin
       Canvas.Brush.Color:= clBlue;
       Canvas.Font.Color:= clWhite;
     end;

     Canvas.FillRect(ARect);
     Canvas.TextOut(ARect.Left, ARect.Top, Items[Index]);
    end
end;

procedure TShowChannelForm.Image1Click(Sender: TObject);
begin
  ParamSetFileName:= 'Paramsets.lib';
  LibMode:= 1; { Save }
  ParamSetFrm.SaveSet.Visible:= True;
  ParamSetFrm.LoadSet.Visible:= False;
  SaveParamSet();
  if Not ParamSetEmpty() then FillSetList();
end;

procedure TShowChannelForm.Image2Click(Sender: TObject);
begin
  ParamSetFileName:= 'Paramsets.lib';
  LibMode:= 2; { Load }
  ParamSetFrm.SaveSet.Visible:= False;
  ParamSetFrm.LoadSet.Visible:= True;
  FillSetList();
end;

procedure TShowChannelForm.Image3Click(Sender: TObject);
begin
  LibMode:= 3; { Import }
  App.OpenDialog.Filter:= 'lib files|*.lib|all files|*.*|';
  App.OpenDialog.DefaultExt:= '.lib';
  if App.OpenDialog.Execute then begin
     ParamSetFileName:= App.OpenDialog.FileName;
     ParamSetFrm.SaveSet.Visible:= False;
     ParamSetFrm.LoadSet.Visible:= True;
     FillSetList();
  end;
end;

end.

