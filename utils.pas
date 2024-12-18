unit Utils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, DateUtils,
  UserTypes, StrUtils, Buttons, LCLType, TASeries, TADataTools, TATools,
  LCLIntf, Clipbrd, TAGraph, ParseCSV, GraphUtil, ExtCtrls;

function GetErrorMessage(error: Byte): PChar;
procedure LoadByteArray(const AFileName: string);
procedure SaveByteArray(AByteArray: TBytes; const AFileName: string);
function LoadSourceFile(FileExt: String; MinFileSize: LongWord): Boolean;
function LoadSourceByteArray(FileName: String; MinFileSize: LongWord): Boolean;
procedure LoadFile(FileType: Byte);
function ReadCurrentByte(): Byte;
function isEndOfFile(): Boolean;
procedure IncDataOffset(n: LongWord);
procedure ProgressInit(n: LongWord; PLabel: String);
procedure ProgressDone();
function SWHint(SW: Integer; SWDescr: array of String; DT: TDateTime): String;
function GetSticker(Serie: TLineSeries; x, y: Double): String;
procedure StickLabel(ChartLineSerie: TLineSeries);
procedure SetNavigation(NavMode: Byte);
procedure SetFastMode(Value: Boolean);
function Expon2(n: Integer): Integer;
procedure MakeScreenShot();
function AddLidZeros(S: String; N: Byte): String;
function StrInArray(Value: String; Arr: array of String): Boolean;
function GetParamPosition(Param: String): Integer;
function SmartStrToDateTime(Str: String; var DateTime: TDateTime): Boolean;
function GetMonthStr(aMonth: Byte): String;
function SetStringLength(Str: String; n: Word): String;
function GetFileName(AName, AExt: String): String;
function GetTypeLength(RepCode: String): Byte;

implementation

uses Main, channelsform, ParseBinDb;

function AddLidZeros(S: String; N: Byte): String;
begin
  Result:= AddChar('0', S, N - Length(S) + 1);
end;

function GetErrorMessage(error: Byte): PChar;
begin
  case error of
     0: Result:= 'NO_ERROR';
     1: Result:= 'FILE_NOT_FOUND';
     2: Result:= 'WRONG_FILE_FORMAT';
     3: Result:= 'UNEXPECTED_END_OF_FILE';
     6: Result:= 'WRONG DATE FORMAT';
  end;
end;

procedure LoadByteArray(const AFileName: String);
var
  AStream: TStream;
  ADataLeft: LongWord;
begin
  AStream:= TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    try
      AStream.Position:= 0;
      ADataLeft:= AStream.Size;
      SetLength(Bytes, ADataLeft div SizeOf(Byte));
      AStream.Read(PByte(Bytes)^, ADataLeft);
    except
      on Exception : EStreamError do
         Bytes:= Nil;
    end;
  finally
    AStream.Free;
  end;
end;

function LoadSourceByteArray(FileName: String; MinFileSize: LongWord): Boolean;
begin
   Result:= False;
   LoadByteArray(FileName);
   if Bytes <> Nil then begin
      CurrentFileSize:= Length(Bytes);
      DataOffset:= 0;
      if CurrentFileSize >= MinFileSize then begin
         EndOfFile:= False;
         Result:= True;
         CurrentOpenedFile:= FileName;
      end;
   end;
end;

function LoadSourceFile(FileExt: String; MinFileSize: LongWord): Boolean; // Load bin file to the Bytes array
begin
  Result:= False;
  App.OpenDialog.Filter:= 'bin files|*.' + FileExt + '|all files|*.*|';
  App.OpenDialog.DefaultExt:= '.' + FileExt;
  if App.OpenDialog.Execute then Result:= LoadSourceByteArray(App.OpenDialog.FileName, MinFileSize);
end;

procedure LoadFile(FileType: Byte);
var DataSource  : TDataSource;
begin
   SetNavigation(NAVIGATION_OFF);
   DataSource.SourceName:= CurrentOpenedFile;
   if FileType = BIN_DB_TYPE then DataSource.FrameRecords:= BinDbParser(3);
   if FileType = CSV_TYPE then DataSource.FrameRecords:= CSVParser(4);
   DataSource.TFFDataChannels:= TffStructure.GetTFFDataChannels;
   TffStructure.Done;
   if ErrorCode = NO_ERROR then begin
      Insert(DataSource, DataSources, DATA_MAX_SIZE);
      if Length(DataSources[CurrentSource].FrameRecords) > 50000 then ShowChannelForm.FastMode.Checked:= True
      else ShowChannelForm.FastMode.Checked:= False;
      NewFileOpened:= True;
      Inc(SourceCount);
      CurrentSource:= SourceCount - 1;
      OpenChannelForm();
   end
   else Application.MessageBox(GetErrorMessage(ErrorCode),'Error', MB_ICONERROR + MB_OK);
   Application.ProcessMessages;
   SetNavigation(NavigationMode);
end;

procedure SaveByteArray(AByteArray: TBytes; const AFileName: string);
var
  AStream: TStream;
begin
  try
    if FileExists(AFileName) then DeleteFile(AFileName);
    AStream := TFileStream.Create(AFileName, fmCreate);
    try
       AStream.WriteBuffer(Pointer(AByteArray)^, Length(AByteArray));
    finally
       AStream.Free;
    end;
  except
    Application.MessageBox('Target file is being used by another process','Error', MB_ICONERROR + MB_OK);
  end;
end;

function ReadCurrentByte(): Byte;
begin
  if Not EndOfFile then begin
     Result:= Bytes[DataOffset];
     Inc(DataOffset);
     if DataOffset >= currentFileSize then begin
        EndOfFile:= True;
     end;
  end;
end;

function isEndOfFile(): Boolean;
begin
  if DataOffset >= currentFileSize then begin
     EndOfFile:= True;
     Result:= True;
  end
  else Result:= False;
end;

procedure IncDataOffset(n: LongWord);
var i: LongWord;
begin
   for i:=1 to n do ReadCurrentByte;
end;

procedure ProgressInit(n: LongWord; PLabel: String);
begin
  App.ProcessLabel.Visible:= True;
  App.ProcessProgress.Max:= n;
  App.ProcessProgress.Position:= 0;
  App.ProcessProgress.Visible:= True;
  App.ProcessLabel.Caption:= PLabel;
  App.ProcessLabel.Refresh;
end;

procedure ProgressDone();
begin
  App.ProcessLabel.Visible:= False;
  App.ProcessProgress.Position:= 0;
  App.ProcessProgress.Visible:= False;
  App.ProcessLabel.Caption:= '';
  App.ProcessLabel.Refresh;
end;

function SWHint(SW: Integer; SWDescr: array of String; DT: TDateTime): String;
var i: Byte;
    wStr: String;
begin
   wStr:= wStr + 'Value - ' + IntToStr(SW) + #13#10;
   for i:=0 to 15 do
     if (SW and expon2(i)) > 0 then wStr:= wStr + '1 - ' + SWDescr[i] + #13#10;
   Result:= wStr + DateTimeToStr(DT);
end;

function GetSticker(Serie: TLineSeries; x, y: Double): String;
var AfterDot : Byte;
    AddStr   : String;
    sUnit    : String;
begin
  if Abs(y) > 10000 then AfterDot:= 0
  else AfterDot:= 3;
  if App.ExtHint.Checked then AddStr:= 'Min = ' + FloatToStrF(Serie.GetYMin, ffFixed, 12, AfterDot) + ', ' +
                                       'Max = ' + FloatToStrF(Serie.GetYMax, ffFixed, 12, AfterDot)
  else AddStr:= '';
  sUnit:= ParametersUnits[StrToInt(MidStr(Serie.Name, 6, 1)), StrToInt(MidStr(Serie.Name, 12, 1))];
  if App.ByDotsCh.Checked then Result:= Serie.Title + ' = ' + FloatToStrF(y, ffFixed, 12, AfterDot) + ' ' + sUnit + NewLine + AddStr
  else Result:= Serie.Title + ' = ' + FloatToStrF(y, ffFixed, 12, AfterDot) + ' ' + sUnit + NewLine + AddStr + NewLine + FormatDateTime('dd.mm.yy hh:nn:ss', x) //  DateTimeToStr(x);
end;

procedure StickLabel(ChartLineSerie: TLineSeries);
var y: Double;
    x: TDateTime;
begin
  if ChartLineSerie.Count > 0 then begin
     x:= ChartLineSerie.GetXValue(ChartPointIndex);
     y:= ChartLineSerie.GetYValue(ChartPointIndex);
     ChartLineSerie.ListSource.Item[ChartPointIndex]^.Text:= GetSticker(ChartLineSerie, x, y);
     ChartLineSerie.ParentChart.Repaint;
  end;
end;

procedure SetFastMode(Value: Boolean);
begin
  ShowChannelForm.RecordsNumber.Enabled:= Value;
  ShowChannelForm.RecordCount.Visible:= Value;
  if Value = True then begin
     FastModeDivider:= ShowChannelForm.RecordsNumber.Position;
     ShowChannelForm.SlowLabel.Font.Color:= clBlue;
     ShowChannelForm.FastLabel.Font.Color:= clBlue;
  end
  else begin
     FastModeDivider:= 1;
     ShowChannelForm.SlowLabel.Font.Color:= clSilver;
     ShowChannelForm.FastLabel.Font.Color:= clSilver;
  end;
end;

procedure SetNavigation(NavMode: Byte);
begin
  App.ChartToolset1PanDragTool1.Enabled:= False;
  App.ChartToolset1ZoomDragTool1.Enabled:= False;
  App.DistanceTool.Enabled:= False;
  App.ChartToolset1DataPointClickTool4.Enabled:= False;
  App.ChartToolset1DataPointHintTool1.Enabled:= False;
  App.AllocateArea.Shift:= [ssShift,ssCtrl,ssLeft];
  App.ZoomOff.Visible:= True;
  App.ZoomOn.Visible:= False;
  App.PanOff.Visible:= True;
  App.PanOn.Visible:= False;
  App.DistanceXOff.Visible:= True;
  App.DistanceXOn.Visible:= False;
  App.DistanceYOff.Visible:= True;
  App.DistanceYOn.Visible:= False;
  App.CutZoneOff.Visible:= True;
  App.CutZoneOn.Visible:= False;
  App.CropBtn.Caption:= 'Crop';
  case NavMode of
     ZOOM_MODE:     begin
                       App.ChartToolset1ZoomDragTool1.Enabled:= True;
                       App.ChartToolset1DataPointClickTool4.Enabled:= True;
                       App.ChartToolset1DataPointHintTool1.Enabled:= True;
                       App.ZoomOff.Visible:= False;
                       App.ZoomOn.Visible:= True;
                    end;
     PAN_MODE:      begin
                       App.ChartToolset1PanDragTool1.Enabled:= True;
                       App.ChartToolset1DataPointClickTool4.Enabled:= True;
                       App.ChartToolset1DataPointHintTool1.Enabled:= True;
                       App.PanOff.Visible:= False;
                       App.PanOn.Visible:= True;
                    end;
     DISTANCE_MODE_X: begin
                       App.DistanceTool.Enabled:= True;
                       App.DistanceTool.MeasureMode:= cdmOnlyX;
                       App.DistanceXOff.Visible:= False;
                       App.DistanceXOn.Visible:= True;
                    end;
     DISTANCE_MODE_Y: begin
                       App.DistanceTool.Enabled:= True;
                       App.DistanceTool.MeasureMode:= cdmOnlyY;
                       App.DistanceYOff.Visible:= False;
                       App.DistanceYOn.Visible:= True;
                    end;
     ALLOCATE_AREA_MODE: begin
                       App.AllocateArea.Shift:= [ssLeft];
                       App.CutZoneOff.Visible:= False;
                       App.CutZoneOn.Visible:= True;
                       App.CropBtn.Caption:= 'Cut';
                    end;
  end;
end;

function Expon2(n: Integer): Integer;
var i, exp: Integer;
begin
  exp:= 1;
  for i:=1 to n do exp:= exp * 2;
  Result:= exp;
end;

procedure MakeScreenShot();
var
  R: TRect;
  Bitmap: TBitmap;
begin
  Bitmap := TBitmap.Create;
  try
    R := Rect(0, 0, App.ChartScrollBox.Width, App.ChartScrollBox.Height);
    Bitmap.SetSize(App.ChartScrollBox.Width, App.ChartScrollBox.Height);
    Bitmap.Canvas.CopyRect(R, App.ChartScrollBox.Canvas, R);
    Clipboard.Assign(Bitmap);
  finally
    Bitmap.Free;
  end;
end;

function StrInArray(Value: String; Arr: array of String): Boolean;
var i, Len: Word;
begin
  Len:= Length(Arr);
  for i:=0 to Len - 1 do
    if Value = Arr[i] then begin
       Result:= True;
       Exit;
    end;
  Result:= False;
end;

function GetParamPosition(Param: String): Integer;
var i: Integer;
begin
  Result:= -1;
  for i:=0 to ShowChannelForm.ChannelList.Count - 1 do
    if ShowChannelForm.ChannelList.Items[i] = Param then begin
       Result:= i;
       Exit;
    end;
end;

function TryScanDateTime(DTStr, DTFormat: String; var DateTime: TDateTime): Boolean;
begin
 try
   DateTime:= ScanDateTime(DTFormat, DTStr);
   Result:= True;
 except
   on E: EConvertError do begin
     Result:= False;
   end;
 end;
end;

function SmartStrToDateTime(Str: String; var DateTime: TDateTime): Boolean;
var UnixDateTime : LongInt;
begin
  Result:= True;
  if Not TryStrToDateTime(Str, DateTime) then
    if Not TryScanDateTime(Str, 'hh:mm:ss dd-mmm-yy', DateTime) then
       if Not TryScanDateTime(Str, 'hh:mm:ss dd-mmm-yyyy', DateTime) then
          if Not TryScanDateTime(Str, 'dd/mm/yy hh:mm:ss', DateTime) then
             if Not TryScanDateTime(Str, 'dd/mm/yyyy hh:mm:ss', DateTime) then
                if Not TryScanDateTime(Str, App.DateTimeFormat.Text, DateTime) then begin
                   try
                     TryStrToInt(Str, UnixDateTime);
                     DateTime:= UnixToDateTime(UnixDateTime);
                   except
                     on E: EConvertError do begin
                        DateTime:= 0;
                        Result:= False;
                     end;
                   end;
                end;
end;

function GetMonthStr(aMonth: Byte): String;
const Monthses: array of String = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
begin
  Result:= Monthses[aMonth - 1];
end;

function SetStringLength(Str: String; n: Word): String;
begin
  Result:= AddCharR(' ', LeftBStr(Str, n), n);
end;

function GetFileName(AName, AExt: String): String;
begin
  with App.SaveDialog1 do begin
    FileName := AName;
    DefaultExt := AExt;
    if not Execute then Abort;
    Result := FileName;
  end;
end;

function GetTypeLength(RepCode: String): Byte;
begin
   case LowerCase(RepCode) of
     'i1', 'u1'       : Result:= 1;
     'i2', 'u2'       : Result:= 2;
     'f4', 'u4', 'i4' : Result:= 4;
     'f8', 'i8', 'u8' : Result:= 8;
   end;
end;

end.

