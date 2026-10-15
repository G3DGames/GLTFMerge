//** @abstract(Modal dialog that splits one long animation into named frame ranges.)
//**
//** @link(TSplitAnimationForm) shows the animation's length with two linked fields: the frame
//** rate, 30 frames per second unless changed, and the last frame. Changing either updates the
//** other, so when the last frame is known, for example 1800 for a 60-second animation, it can
//** simply be typed in. Below them is a grid like a spreadsheet with the columns Row,
//** Animation Name, Start Frame and End Frame. There is always one empty row at the end, so
//** typing in it is all it takes to add a range; a row left empty is ignored.
//**
//** Every row is checked as it is edited: names are required and unique, frames must be from
//** 0 to the last frame, and End Frame must be after Start Frame. While "Frames increase from
//** row to row" is ticked, as it is by default, each row must also start at or after the end
//** of the row before; a row that does not is reported in a message as soon as it is entered.
//** Gaps between ranges are allowed.
//**
//** "Import list..." fills the grid from a text file, such as the list of ranges that comes
//** with many animation files, using @code(TglTFAnimationSplitter.ParseRangeList); a message
//** says what was read, and "Clear" empties the grid when the result is not right.
//**
//** The sheet can be saved to a file and loaded again, to finish it later. "Convert" is
//** enabled once every row is valid; the ranges then go to the callback, which does the split
//** with TglTFAnimationSplitter. The form is built in code and frees itself.
unit glTFViewer.Split;

{
  Modal dialog that splits one long animation into named frame ranges.

  TSplitAnimationForm shows the animation's length with two linked fields: the
  frame rate, 30 frames per second unless changed, and the last frame.
  Changing either updates the other, so when the last frame is known, for
  example 1800 for a 60-second animation, it can simply be typed in. Below
  them is a grid like a spreadsheet with the columns Row, Animation Name,
  Start Frame and End Frame. There is always one empty row at the end, so
  typing in it is all it takes to add a range; a row left empty is ignored.

  Every row is checked as it is edited: names are required and unique, frames
  must be from 0 to the last frame, and End Frame must be after Start Frame.
  While "Frames increase from row to row" is ticked, as it is by default, each
  row must also start at or after the end of the row before; a row that does
  not is reported in a message as soon as it is entered. Gaps between ranges
  are allowed.

  "Import list..." fills the grid from a text file, such as the list of ranges
  that comes with many animation files, using
  TglTFAnimationSplitter.ParseRangeList; a message says what was read, and
  "Clear" empties the grid when the result is not right.

  The sheet can be saved to a file and loaded again, to finish it later.
  "Convert" is enabled once every row is valid; the ranges then go to the
  callback, which does the split with TglTFAnimationSplitter. The form is
  built in code and frees itself.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math, System.Rtti,
  System.IOUtils, System.JSON,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.Grid,
  FMX.Grid.Style, FMX.Graphics, FMX.Controls.Presentation, FMX.ScrollBox, FMX.DialogService,

  glTF.Classes, glTF.AnimationSplit;

type
  //** @abstract(Called with the result of the split dialog.)
  //**
  //** @param(ARanges The ranges entered, in grid order, empty rows left out.)
  //**
  //** @param(AFrameRate The frame rate that turns the frames entered into seconds: the last
  //** frame divided by the animation's length.)
  /// <summary>Called with the result of the split dialog.</summary>
  /// <param name="ARanges">The ranges entered, in grid order, empty rows left out.</param>
  /// <param name="AFrameRate">The frame rate that turns the frames entered into seconds: the
  /// last frame divided by the animation's length.</param>
  TSplitDoneProc = reference to procedure(const ARanges: TglTFAnimationRanges;
    AFrameRate: Double);

  //** @abstract(Lets the user enter the frame ranges a long animation is split into.)
  //**
  //** Use @link(Execute) rather than creating it directly. Must be used on the main thread.
  /// <summary>Lets the user enter the frame ranges a long animation is split into.</summary>
  /// <remarks>Use <see cref="Execute"/> rather than creating it directly. Must be used on the
  /// main thread.</remarks>
  TSplitAnimationForm = class(TForm)
  private
    FRoot: TglTF;
    FIndex: Integer;
    FName: string;
    FDuration: Double;
    FFolder: string;
    FFrameRate: Double;
    FLastFrame: Integer;
    FLinking: Boolean;
    FLastWarning: string;
    FInfo: TLabel;
    FRateEdit: TEdit;
    FLastEdit: TEdit;
    FHint: TLabel;
    FIncreasing: TCheckBox;
    FGrid: TStringGrid;
    FProblems: TLabel;
    FConvert: TButton;
    FRanges: TglTFAnimationRanges;
    procedure BuildControls(AKeyFrameRate: Double);
    function AddColumn(const AHeader: string; AWidth: Single): TStringColumn;
    function AddField(AParent: TFmxObject; const ACaption: string; AOrder: Single): TEdit;
    function AddButton(AParent: TFmxObject; const AText: string; AAlign: TAlignLayout;
      AOrder: Single; AOnClick: TNotifyEvent): TButton;
    function RowIsEmpty(ARow: Integer): Boolean;
    function ReadRow(ARow: Integer; out AName: string; out AStart, AEnd: Integer): Boolean;
    function OrderProblem(ARow: Integer): string;
    procedure NumberRows;
    procedure EnsureEmptyLastRow;
    procedure SetRate(ARate: Double);
    procedure SetLastFrame(ALastFrame: Integer);
    procedure Check;
    procedure GridEditingDone(Sender: TObject; const ACol, ARow: Integer);
    procedure RateChange(Sender: TObject);
    procedure LastFrameChange(Sender: TObject);
    procedure IncreasingChange(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure LoadClick(Sender: TObject);
    procedure ImportClick(Sender: TObject);
    procedure ClearClick(Sender: TObject);
    procedure ImportList(const AFileName: string);
    procedure ClearRows;
    procedure SaveSheet(const AFileName: string);
    procedure LoadSheet(const AFileName: string);
    procedure ConvertClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  public
    //** @abstract(Shows the dialog modally for one animation.)
    //**
    //** The dialog frees itself when it closes; ADone is only called when the user presses
    //** Convert. Nothing is changed by the dialog itself.
    //**
    //** @param(ARoot The tree holding the animation; read for its length, its key frames and
    //** the names already used.)
    //**
    //** @param(AIndex Index in @code(ARoot.Animations) of the animation to split.)
    //**
    //** @param(AFolder Folder the Save and Load buttons start in, usually the model's.)
    //**
    //** @param(ADone Called with the ranges and the frame rate on Convert.)
    /// <summary>Shows the dialog modally for one animation.</summary>
    /// <param name="ARoot">The tree holding the animation; read for its length, its key
    /// frames and the names already used.</param>
    /// <param name="AIndex">Index in <c>ARoot.Animations</c> of the animation to
    /// split.</param>
    /// <param name="AFolder">Folder the Save and Load buttons start in, usually the
    /// model's.</param>
    /// <param name="ADone">Called with the ranges and the frame rate on Convert.</param>
    /// <remarks>The dialog frees itself when it closes; ADone is only called when the user
    /// presses Convert. Nothing is changed by the dialog itself.</remarks>
    class procedure Execute(ARoot: TglTF; AIndex: Integer; const AFolder: string;
      const ADone: TSplitDoneProc);
  end;

implementation

uses
  glTFViewer.Dialogs;

const
  COL_ROW = 0;
  COL_NAME = 1;
  COL_START = 2;
  COL_END = 3;
  MAX_PROBLEMS_SHOWN = 4;

  // Most animations are made at this rate
  DEFAULT_FRAME_RATE = 30;

  SHEET_EXTENSION = '.json';

function ParseRate(const AText: string; out ARate: Double): Boolean;
begin
  Result := (TryStrToFloat(Trim(AText), ARate, TFormatSettings.Invariant) or
    TryStrToFloat(Trim(AText), ARate)) and (ARate > 0) and (ARate <= 1000);
end;

function RateText(ARate: Double): string;
begin
  Result := FormatFloat('0.###', ARate, TFormatSettings.Invariant);
end;

{ TSplitAnimationForm }

class procedure TSplitAnimationForm.Execute(ARoot: TglTF; AIndex: Integer;
  const AFolder: string; const ADone: TSplitDoneProc);
var
  LForm: TSplitAnimationForm;
begin
  LForm := TSplitAnimationForm.CreateNew(Application);
  LForm.FRoot := ARoot;
  LForm.FIndex := AIndex;
  LForm.FFolder := AFolder;
  LForm.FName := ARoot.Animations[AIndex].Name;
  if LForm.FName = '' then
    LForm.FName := Format('Animation %d', [AIndex]);
  LForm.FDuration := TglTFAnimationSplitter.Duration(ARoot, ARoot.Animations[AIndex]);
  LForm.OnClose := LForm.FormClose;
  LForm.BuildControls(TglTFAnimationSplitter.DetectFrameRate(ARoot, ARoot.Animations[AIndex]));
  LForm.SetRate(DEFAULT_FRAME_RATE);
  LForm.Check;

  // ShowModal with a result procedure works on every platform; the form
  // frees itself in OnClose
  LForm.ShowModal(
    procedure(AResult: TModalResult)
    begin
      if (AResult = mrOk) and Assigned(ADone) then
        ADone(LForm.FRanges, LForm.FFrameRate);
    end);
end;

function TSplitAnimationForm.AddColumn(const AHeader: string; AWidth: Single): TStringColumn;
begin
  Result := TStringColumn.Create(FGrid);
  Result.Header := AHeader;
  Result.Width := AWidth;
  FGrid.AddObject(Result);
end;

function TSplitAnimationForm.AddField(AParent: TFmxObject; const ACaption: string;
  AOrder: Single): TEdit;
var
  LLabel: TLabel;
begin
  LLabel := TLabel.Create(Self);
  LLabel.Parent := AParent;
  LLabel.Align := TAlignLayout.Left;
  LLabel.Position.X := AOrder;
  LLabel.AutoSize := True;
  LLabel.TextSettings.WordWrap := False;
  LLabel.Margins.Right := 6;
  LLabel.Text := ACaption;

  Result := TEdit.Create(Self);
  Result.Parent := AParent;
  Result.Align := TAlignLayout.Left;
  Result.Position.X := AOrder + 500;
  Result.Width := 80;
  Result.Margins.Right := 18;
end;

function TSplitAnimationForm.AddButton(AParent: TFmxObject; const AText: string;
  AAlign: TAlignLayout; AOrder: Single; AOnClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  Result.Align := AAlign;
  Result.Position.X := AOrder; // same-side alignment is ordered by position
  Result.Width := 110;
  Result.Margins.Left := 4;
  Result.Margins.Right := 4;
  Result.Text := AText;
  Result.OnClick := AOnClick;
end;

procedure TSplitAnimationForm.BuildControls(AKeyFrameRate: Double);
var
  LTop, LFields, LButtons: TLayout;
  LLabel: TLabel;
  LButton: TButton;
begin
  Caption := 'Split "' + FName + '"';
  Width := 860;
  Height := 580;
  Position := TFormPosition.MainFormCenter;
  BorderIcons := [TBorderIcon.biSystemMenu];
  Padding.Rect := TRectF.Create(12, 10, 12, 10);

  // Top: what is being split, the frame rate and the last frame
  LTop := TLayout.Create(Self);
  LTop.Parent := Self;
  LTop.Align := TAlignLayout.Top;
  LTop.Height := 128;

  FInfo := TLabel.Create(Self);
  FInfo.Parent := LTop;
  FInfo.Align := TAlignLayout.Top;
  FInfo.Height := 22;
  FInfo.StyledSettings := FInfo.StyledSettings - [TStyledSetting.Style];
  FInfo.TextSettings.Font.Style := [TFontStyle.fsBold];
  FInfo.Text := Format('"%s" is %.2f seconds long; frames run from 0 to the last frame',
    [FName, FDuration]);

  LFields := TLayout.Create(Self);
  LFields.Parent := LTop;
  LFields.Align := TAlignLayout.Top;
  LFields.Position.Y := 100;
  LFields.Height := 32;
  LFields.Padding.Rect := TRectF.Create(0, 4, 0, 4);
  FRateEdit := AddField(LFields, 'Frame rate (per second):', 0);
  FLastEdit := AddField(LFields, 'Last frame:', 1000);
  FRateEdit.OnChangeTracking := RateChange;
  FLastEdit.OnChangeTracking := LastFrameChange;

  FHint := TLabel.Create(Self);
  FHint.Parent := LTop;
  FHint.Align := TAlignLayout.Top;
  FHint.Position.Y := 200;
  FHint.Height := 20;
  FHint.Text := Format('Change either: the other follows. The key frames suggest about %s ' +
    'frames per second.', [RateText(AKeyFrameRate)]);

  LLabel := TLabel.Create(Self);
  LLabel.Parent := LTop;
  LLabel.Align := TAlignLayout.Top;
  LLabel.Position.Y := 300;
  LLabel.Height := 20;
  LLabel.Text := 'Type one row per animation; a new empty row appears as you go. Gaps ' +
    'between the ranges are fine, and a row left empty is ignored.';

  FIncreasing := TCheckBox.Create(Self);
  FIncreasing.Parent := LTop;
  FIncreasing.Align := TAlignLayout.Top;
  FIncreasing.Position.Y := 400;
  FIncreasing.Height := 24;
  FIncreasing.Text := 'Frames increase from row to row (a row may start where the row ' +
    'before ends)';
  FIncreasing.IsChecked := True;
  FIncreasing.OnChange := IncreasingChange;

  // Bottom: what is wrong, and the buttons
  LButtons := TLayout.Create(Self);
  LButtons.Parent := Self;
  LButtons.Align := TAlignLayout.Bottom;
  LButtons.Height := 40;
  LButtons.Padding.Top := 8;

  AddButton(LButtons, 'Save sheet...', TAlignLayout.Left, 0, SaveClick);
  AddButton(LButtons, 'Load sheet...', TAlignLayout.Left, 1000, LoadClick);
  AddButton(LButtons, 'Import list...', TAlignLayout.Left, 2000, ImportClick).Hint :=
    'Read the ranges from a text file, such as the list that comes with the animation';
  AddButton(LButtons, 'Clear', TAlignLayout.Left, 3000, ClearClick).Hint :=
    'Empty the grid';
  FConvert := AddButton(LButtons, 'Convert', TAlignLayout.Right, 2000, ConvertClick);
  LButton := AddButton(LButtons, 'Cancel', TAlignLayout.Right, 1000, nil);
  LButton.Cancel := True;
  LButton.ModalResult := mrCancel;

  FProblems := TLabel.Create(Self);
  FProblems.Parent := Self;
  FProblems.Align := TAlignLayout.Bottom;
  FProblems.Position.Y := 0;
  FProblems.Height := 80;
  FProblems.Margins.Top := 6;
  FProblems.StyledSettings := FProblems.StyledSettings -
    [TStyledSetting.FontColor, TStyledSetting.Other];
  FProblems.TextSettings.FontColor := TAlphaColors.Red;
  FProblems.TextSettings.WordWrap := True;
  FProblems.TextSettings.VertAlign := TTextAlign.Leading;

  // The grid, like a spreadsheet; the row numbers cannot be edited
  FGrid := TStringGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := TAlignLayout.Client;
  FGrid.Options := FGrid.Options + [TGridOption.Editing, TGridOption.AlwaysShowEditor,
    TGridOption.Tabs] - [TGridOption.RowSelect];
  AddColumn('Row', 50).ReadOnly := True;
  AddColumn('Animation Name', 280);
  AddColumn('Start Frame', 110);
  AddColumn('End Frame', 110);
  FGrid.RowCount := 1;
  NumberRows;
  FGrid.OnEditingDone := GridEditingDone;
end;

procedure TSplitAnimationForm.SetRate(ARate: Double);
begin
  // The last frame follows the frame rate
  FFrameRate := ARate;
  FLastFrame := TglTFAnimationSplitter.LastFrame(FDuration, ARate);
  FLinking := True;
  try
    FRateEdit.Text := RateText(FFrameRate);
    FLastEdit.Text := IntToStr(FLastFrame);
  finally
    FLinking := False;
  end;
end;

procedure TSplitAnimationForm.SetLastFrame(ALastFrame: Integer);
begin
  // The frame rate follows the last frame, exactly, so the last frame is the
  // end of the animation
  FLastFrame := ALastFrame;
  if FDuration > 0 then
    FFrameRate := ALastFrame / FDuration;
  FLinking := True;
  try
    FRateEdit.Text := RateText(FFrameRate);
    FLastEdit.Text := IntToStr(FLastFrame);
  finally
    FLinking := False;
  end;
end;

procedure TSplitAnimationForm.RateChange(Sender: TObject);
var
  LRate: Double;
begin
  if FLinking then
    Exit;
  if ParseRate(FRateEdit.Text, LRate) then
  begin
    FFrameRate := LRate;
    FLastFrame := TglTFAnimationSplitter.LastFrame(FDuration, LRate);
    FLinking := True;
    try
      FLastEdit.Text := IntToStr(FLastFrame);
    finally
      FLinking := False;
    end;
  end
  else
    FFrameRate := 0;
  Check;
end;

procedure TSplitAnimationForm.LastFrameChange(Sender: TObject);
var
  LLast: Integer;
begin
  if FLinking then
    Exit;
  if TryStrToInt(Trim(FLastEdit.Text), LLast) and (LLast > 0) and (FDuration > 0) then
  begin
    FLastFrame := LLast;
    FFrameRate := LLast / FDuration;
    FLinking := True;
    try
      FRateEdit.Text := RateText(FFrameRate);
    finally
      FLinking := False;
    end;
  end
  else
    FFrameRate := 0;
  Check;
end;

procedure TSplitAnimationForm.IncreasingChange(Sender: TObject);
begin
  FLastWarning := '';
  Check;
end;

function TSplitAnimationForm.RowIsEmpty(ARow: Integer): Boolean;
var
  C: Integer;
begin
  for C := COL_NAME to COL_END do
    if Trim(FGrid.Cells[C, ARow]) <> '' then
      Exit(False);
  Result := True;
end;

function TSplitAnimationForm.ReadRow(ARow: Integer; out AName: string;
  out AStart, AEnd: Integer): Boolean;
begin
  AName := Trim(FGrid.Cells[COL_NAME, ARow]);
  Result := TryStrToInt(Trim(FGrid.Cells[COL_START, ARow]), AStart) and
    TryStrToInt(Trim(FGrid.Cells[COL_END, ARow]), AEnd);
end;

function TSplitAnimationForm.OrderProblem(ARow: Integer): string;
var
  LName, LPrevName: string;
  LStart, LEnd, LPrevStart, LPrevEnd, R: Integer;
begin
  // The nearest filled row before ARow must end at or before ARow's start
  Result := '';
  if not FIncreasing.IsChecked or RowIsEmpty(ARow) or not ReadRow(ARow, LName, LStart, LEnd) then
    Exit;
  for R := ARow - 1 downto 0 do
    if not RowIsEmpty(R) then
    begin
      if ReadRow(R, LPrevName, LPrevStart, LPrevEnd) and (LStart < LPrevEnd) then
        Result := Format('Row %d starts at frame %d, before row %d ends at frame %d',
          [ARow + 1, LStart, R + 1, LPrevEnd]);
      Exit;
    end;
end;

procedure TSplitAnimationForm.NumberRows;
var
  R: Integer;
begin
  for R := 0 to FGrid.RowCount - 1 do
    FGrid.Cells[COL_ROW, R] := IntToStr(R + 1);
end;

procedure TSplitAnimationForm.EnsureEmptyLastRow;
begin
  // There is always exactly one empty row to type into at the end
  if not RowIsEmpty(FGrid.RowCount - 1) then
    FGrid.RowCount := FGrid.RowCount + 1;
  NumberRows;
end;

procedure TSplitAnimationForm.Check;
var
  LRanges: TglTFAnimationRanges;
  LRows: TArray<Integer>;
  LProblems, LSplitProblems: TArray<string>;
  LRange: TglTFAnimationRange;
  LProblem, LText: string;
  R, I: Integer;
begin
  // The rows that are not empty, as ranges; numbers that do not read are
  // reported here, the rest by ValidateRanges
  LRanges := nil;
  LRows := nil;
  LProblems := nil;
  for R := 0 to FGrid.RowCount - 1 do
  begin
    if RowIsEmpty(R) then
      Continue;
    LRange.Notes := '';
    if not TryStrToInt(Trim(FGrid.Cells[COL_START, R]), LRange.StartFrame) then
    begin
      LProblems := LProblems + [Format('Row %d: Start Frame must be a whole number', [R + 1])];
      Continue;
    end;
    if not TryStrToInt(Trim(FGrid.Cells[COL_END, R]), LRange.EndFrame) then
    begin
      LProblems := LProblems + [Format('Row %d: End Frame must be a whole number', [R + 1])];
      Continue;
    end;
    LRange.Name := Trim(FGrid.Cells[COL_NAME, R]);
    LRanges := LRanges + [LRange];
    LRows := LRows + [R];
    LProblem := OrderProblem(R);
    if LProblem <> '' then
      LProblems := LProblems + [LProblem];
  end;

  if FFrameRate <= 0 then
    LProblems := LProblems + ['Enter a frame rate above 0, or the last frame']
  else if LRanges <> nil then
  begin
    TglTFAnimationSplitter.ValidateRanges(FRoot, FIndex, FLastFrame, LRanges, LSplitProblems);
    for I := 0 to High(LSplitProblems) do
      if LSplitProblems[I] <> '' then
        LProblems := LProblems + [Format('Row %d: %s', [LRows[I] + 1, LSplitProblems[I]])];
  end;

  LText := '';
  for I := 0 to Min(High(LProblems), MAX_PROBLEMS_SHOWN - 1) do
    LText := LText + LProblems[I] + sLineBreak;
  if Length(LProblems) > MAX_PROBLEMS_SHOWN then
    LText := LText + Format('... and %d more', [Length(LProblems) - MAX_PROBLEMS_SHOWN]);
  FProblems.Text := Trim(LText);

  FConvert.Enabled := (LProblems = nil) and (LRanges <> nil);
  if FConvert.Enabled then
    FRanges := LRanges;
end;

procedure TSplitAnimationForm.GridEditingDone(Sender: TObject; const ACol, ARow: Integer);
var
  LWarning: string;
begin
  EnsureEmptyLastRow;
  Check;

  // A row that goes back in time: say so at once, once per problem
  if (ACol = COL_START) or (ACol = COL_END) then
  begin
    LWarning := OrderProblem(ARow);
    if (LWarning = '') and (ARow + 1 < FGrid.RowCount) then
      LWarning := OrderProblem(ARow + 1);
    if (LWarning <> '') and (LWarning <> FLastWarning) then
    begin
      FLastWarning := LWarning;
      TDialogService.ShowMessage(LWarning + '.' + sLineBreak + sLineBreak +
        'Rows are expected to go forward in time. Untick "Frames increase from row to row" ' +
        'if this is intended.');
    end;
  end;
end;

procedure TSplitAnimationForm.SaveSheet(const AFileName: string);
var
  LJSON, LRow: TJSONObject;
  LRows: TJSONArray;
  LName: string;
  LStart, LEnd, R: Integer;
begin
  // The rows as typed, so a sheet with mistakes can be saved and finished later
  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('animation', FName);
    LJSON.AddPair('durationSeconds', TJSONNumber.Create(FDuration));
    LJSON.AddPair('frameRate', TJSONNumber.Create(FFrameRate));
    LJSON.AddPair('lastFrame', TJSONNumber.Create(FLastFrame));
    LJSON.AddPair('framesIncrease', TJSONBool.Create(FIncreasing.IsChecked));
    LRows := TJSONArray.Create;
    LJSON.AddPair('rows', LRows);
    for R := 0 to FGrid.RowCount - 1 do
      if not RowIsEmpty(R) then
      begin
        LRow := TJSONObject.Create;
        LRow.AddPair('name', FGrid.Cells[COL_NAME, R]);
        if ReadRow(R, LName, LStart, LEnd) then
        begin
          LRow.AddPair('start', TJSONNumber.Create(LStart));
          LRow.AddPair('end', TJSONNumber.Create(LEnd));
        end
        else
        begin
          LRow.AddPair('start', FGrid.Cells[COL_START, R]);
          LRow.AddPair('end', FGrid.Cells[COL_END, R]);
        end;
        LRows.AddElement(LRow);
      end;
    TFile.WriteAllText(AFileName, LJSON.Format(2), TEncoding.UTF8);
  finally
    LJSON.Free;
  end;
end;

procedure TSplitAnimationForm.LoadSheet(const AFileName: string);
var
  LJSON: TJSONValue;
  LRows: TJSONArray;
  LRow: TJSONObject;
  LRate: Double;
  LLast, R: Integer;
  LIncreasing: Boolean;

  function CellText(AValue: TJSONValue): string;
  begin
    if AValue = nil then
      Result := ''
    else if AValue is TJSONString then
      Result := TJSONString(AValue).Value // TJSONNumber too
    else
      Result := AValue.ToString;
  end;

begin
  LJSON := TJSONObject.ParseJSONValue(TFile.ReadAllText(AFileName, TEncoding.UTF8));
  try
    if not (LJSON is TJSONObject) or
       not (TJSONObject(LJSON).GetValue('rows') is TJSONArray) then
      raise Exception.Create('This is not an animation range sheet');

    // The last frame wins over the frame rate when both are there, as it
    // is what the user typed when the frame rate was wrong
    if TJSONObject(LJSON).TryGetValue<Integer>('lastFrame', LLast) and (LLast > 0) then
      SetLastFrame(LLast)
    else if TJSONObject(LJSON).TryGetValue<Double>('frameRate', LRate) and (LRate > 0) then
      SetRate(LRate);
    if TJSONObject(LJSON).TryGetValue<Boolean>('framesIncrease', LIncreasing) then
      FIncreasing.IsChecked := LIncreasing;

    LRows := TJSONObject(LJSON).GetValue('rows') as TJSONArray;
    FGrid.RowCount := LRows.Count + 1;
    for R := 0 to FGrid.RowCount - 1 do
    begin
      FGrid.Cells[COL_NAME, R] := '';
      FGrid.Cells[COL_START, R] := '';
      FGrid.Cells[COL_END, R] := '';
    end;
    for R := 0 to LRows.Count - 1 do
      if LRows.Items[R] is TJSONObject then
      begin
        LRow := TJSONObject(LRows.Items[R]);
        FGrid.Cells[COL_NAME, R] := CellText(LRow.GetValue('name'));
        FGrid.Cells[COL_START, R] := CellText(LRow.GetValue('start'));
        FGrid.Cells[COL_END, R] := CellText(LRow.GetValue('end'));
      end;
  finally
    LJSON.Free;
  end;
  EnsureEmptyLastRow;
  FLastWarning := '';
  Check;
end;

procedure TSplitAnimationForm.SaveClick(Sender: TObject);
begin
  TPlatformDialogs.SaveFile('Save animation ranges',
    [TFileType.Create('Animation range sheet', [SHEET_EXTENSION])], 0, FFolder,
    FName + '.ranges',
    procedure(AFileName: string; ATypeIndex: Integer)
    var
      LFileName: string;
    begin
      if AFileName = '' then
        Exit;
      LFileName := AFileName;
      if not LFileName.EndsWith(SHEET_EXTENSION, True) then
        LFileName := LFileName + SHEET_EXTENSION;
      try
        SaveSheet(LFileName);
        FFolder := TPath.GetDirectoryName(LFileName);
      except
        on E: Exception do
          TDialogService.ShowMessage('The sheet could not be saved: ' + E.Message);
      end;
    end);
end;

procedure TSplitAnimationForm.LoadClick(Sender: TObject);
begin
  TPlatformDialogs.OpenFile('Load animation ranges',
    [TFileType.Create('Animation range sheet', [SHEET_EXTENSION]),
     TFileType.Create('All files', ['*'])], FFolder, '',
    procedure(AFileName: string)
    begin
      if AFileName = '' then
        Exit;
      try
        LoadSheet(AFileName);
        FFolder := TPath.GetDirectoryName(AFileName);
      except
        on E: Exception do
          TDialogService.ShowMessage('The sheet could not be loaded: ' + E.Message);
      end;
    end);
end;

procedure TSplitAnimationForm.ClearRows;
var
  R: Integer;
begin
  for R := 0 to FGrid.RowCount - 1 do
  begin
    FGrid.Cells[COL_NAME, R] := '';
    FGrid.Cells[COL_START, R] := '';
    FGrid.Cells[COL_END, R] := '';
  end;
  FGrid.RowCount := 1;
  NumberRows;
  FLastWarning := '';
  Check;
end;

procedure TSplitAnimationForm.ClearClick(Sender: TObject);
begin
  if RowIsEmpty(0) and (FGrid.RowCount = 1) then
    Exit;
  TPlatformDialogs.Confirm('Clear every row of the grid?',
    procedure(AConfirmed: Boolean)
    begin
      if AConfirmed then
        ClearRows;
    end);
end;

procedure TSplitAnimationForm.ImportList(const AFileName: string);
var
  LList: TglTFRangeList;
  LMessage: string;
  LMaxEnd, LBackwards, R: Integer;
begin
  if not TglTFAnimationSplitter.ParseRangeList(TFile.ReadAllText(AFileName), LList) then
  begin
    TDialogService.ShowMessage(Format('Sorry, no animation ranges could be recognised in %s. ' +
      'We tried, but they will have to be typed in.', [ExtractFileName(AFileName)]));
    Exit;
  end;

  // The grid becomes the list, in its order
  ClearRows;
  FGrid.RowCount := Length(LList.Ranges) + 1;
  LMaxEnd := 0;
  for R := 0 to High(LList.Ranges) do
  begin
    FGrid.Cells[COL_NAME, R] := LList.Ranges[R].Name;
    FGrid.Cells[COL_START, R] := IntToStr(LList.Ranges[R].StartFrame);
    FGrid.Cells[COL_END, R] := IntToStr(LList.Ranges[R].EndFrame);
    LMaxEnd := Max(LMaxEnd, LList.Ranges[R].EndFrame);
  end;
  EnsureEmptyLastRow;
  Check;

  LMessage := Format('Read %d animation range(s) from %s, lines %d to %d.',
    [Length(LList.Ranges), ExtractFileName(AFileName), LList.FirstLine, LList.LastLine]);
  if LList.SkippedLines <> nil then
    LMessage := LMessage + sLineBreak + Format('%d line(s) in between were not understood and ' +
      'were skipped, the first being line %d.', [Length(LList.SkippedLines),
      LList.SkippedLines[0]]);
  if LMaxEnd > FLastFrame then
    LMessage := LMessage + sLineBreak + Format('The list goes up to frame %d but the last ' +
      'frame is set to %d: check the frame rate or the last frame.', [LMaxEnd, FLastFrame]);
  LBackwards := 0;
  for R := 0 to FGrid.RowCount - 1 do
    if OrderProblem(R) <> '' then
      Inc(LBackwards);
  if LBackwards > 0 then
    LMessage := LMessage + sLineBreak + Format('%d row(s) do not go forward in time.',
      [LBackwards]);
  LMessage := LMessage + sLineBreak + sLineBreak + 'Please check the rows before converting; ' +
    '"Clear" empties the grid if they are wrong.';
  TDialogService.ShowMessage(LMessage);
end;

procedure TSplitAnimationForm.ImportClick(Sender: TObject);
begin
  TPlatformDialogs.OpenFile('Import animation list',
    [TFileType.Create('Text files', ['.txt', '.csv', '.md']),
     TFileType.Create('All files', ['*'])], FFolder, '',
    procedure(AFileName: string)
    begin
      if AFileName = '' then
        Exit;
      try
        ImportList(AFileName);
        FFolder := TPath.GetDirectoryName(AFileName);
      except
        on E: Exception do
          TDialogService.ShowMessage('The list could not be read: ' + E.Message);
      end;
    end);
end;

procedure TSplitAnimationForm.ConvertClick(Sender: TObject);
begin
  // The cell being edited counts too
  EnsureEmptyLastRow;
  Check;
  if FConvert.Enabled then
    ModalResult := mrOk;
end;

procedure TSplitAnimationForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

end.
