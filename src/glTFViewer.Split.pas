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
//** The sheet can be saved to a file and loaded again, to finish it later; saving, loading
//** and importing each start in the folder they last used, kept in the settings file.
//** "Convert" is enabled once every row is valid; the ranges then go to the callback, which
//** does the split with TglTFAnimationSplitter. The form is designed in glTFViewer.Split.fmx, grid columns
//** included, and frees itself.
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

  The sheet can be saved to a file and loaded again, to finish it later;
  saving, loading and importing each start in the folder they last used, kept
  in the settings file.
  "Convert" is enabled once every row is valid; the ranges then go to the
  callback, which does the split with TglTFAnimationSplitter. The form is
  designed in glTFViewer.Split.fmx, grid columns included, and frees itself.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math, System.Rtti,
  System.IOUtils, System.JSON, System.Generics.Collections,
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
    //** @abstract(What is split, the frame rate, the last frame and the checkbox.)
    /// <summary>What is split, the frame rate, the last frame and the checkbox.</summary>
    layTop: TLayout;

    //** @abstract(The animation's name and length.)
    /// <summary>The animation's name and length.</summary>
    lblInfo: TLabel;

    //** @abstract(Holds the frame rate and the last frame.)
    /// <summary>Holds the frame rate and the last frame.</summary>
    layFields: TLayout;

    //** @abstract(The caption of the frame rate.)
    /// <summary>The caption of the frame rate.</summary>
    lblRate: TLabel;

    //** @abstract(Frames per second; the last frame follows it.)
    /// <summary>Frames per second; the last frame follows it.</summary>
    edtRate: TEdit;

    //** @abstract(The caption of the last frame.)
    /// <summary>The caption of the last frame.</summary>
    lblLastFrame: TLabel;

    //** @abstract(The last frame; the frame rate follows it.)
    /// <summary>The last frame; the frame rate follows it.</summary>
    edtLastFrame: TEdit;

    //** @abstract(The frame rate the key frames suggest.)
    /// <summary>The frame rate the key frames suggest.</summary>
    lblHint: TLabel;

    //** @abstract(How to fill in the grid.)
    /// <summary>How to fill in the grid.</summary>
    lblHowTo: TLabel;

    //** @abstract(Whether each row must start at or after the end of the row before.)
    /// <summary>Whether each row must start at or after the end of the row before.</summary>
    chkIncreasing: TCheckBox;

    //** @abstract(One row per range, with an empty row at the end to type into.)
    /// <summary>One row per range, with an empty row at the end to type into.</summary>
    grdRanges: TStringGrid;

    //** @abstract(The row number; read-only.)
    /// <summary>The row number; read-only.</summary>
    colRow: TStringColumn;

    //** @abstract(The name of the new animation.)
    /// <summary>The name of the new animation.</summary>
    colName: TStringColumn;

    //** @abstract(The frame the range starts at.)
    /// <summary>The frame the range starts at.</summary>
    colStart: TStringColumn;

    //** @abstract(The frame the range ends at.)
    /// <summary>The frame the range ends at.</summary>
    colEnd: TStringColumn;

    //** @abstract(What is wrong with the rows, the first few problems.)
    /// <summary>What is wrong with the rows, the first few problems.</summary>
    lblProblems: TLabel;

    //** @abstract(Holds the buttons, at the bottom.)
    /// <summary>Holds the buttons, at the bottom.</summary>
    layButtons: TLayout;

    //** @abstract(Saves the rows as typed, to finish later.)
    /// <summary>Saves the rows as typed, to finish later.</summary>
    btnSaveSheet: TButton;

    //** @abstract(Loads rows saved before.)
    /// <summary>Loads rows saved before.</summary>
    btnLoadSheet: TButton;

    //** @abstract(Fills the grid from a text file with a list of ranges.)
    /// <summary>Fills the grid from a text file with a list of ranges.</summary>
    btnImportList: TButton;

    //** @abstract(Empties the grid, after asking.)
    /// <summary>Empties the grid, after asking.</summary>
    btnClear: TButton;

    //** @abstract(Closes the dialog without splitting.)
    /// <summary>Closes the dialog without splitting.</summary>
    btnCancel: TButton;

    //** @abstract(Closes the dialog and splits; enabled once every row is valid.)
    /// <summary>Closes the dialog and splits; enabled once every row is valid.</summary>
    btnConvert: TButton;

    //** @abstract(Updates the last frame from the frame rate typed.)
    //**
    //** @param(Sender The edit box.)
    /// <summary>Updates the last frame from the frame rate typed.</summary>
    /// <param name="Sender">The edit box.</param>
    procedure edtRateChangeTracking(Sender: TObject);

    //** @abstract(Updates the frame rate from the last frame typed.)
    //**
    //** @param(Sender The edit box.)
    /// <summary>Updates the frame rate from the last frame typed.</summary>
    /// <param name="Sender">The edit box.</param>
    procedure edtLastFrameChangeTracking(Sender: TObject);

    //** @abstract(Checks the rows again.)
    //**
    //** @param(Sender The checkbox.)
    /// <summary>Checks the rows again.</summary>
    /// <param name="Sender">The checkbox.</param>
    procedure chkIncreasingChange(Sender: TObject);

    //** @abstract(Asks for a file name and saves the rows.)
    //**
    //** @param(Sender The button.)
    /// <summary>Asks for a file name and saves the rows.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnSaveSheetClick(Sender: TObject);

    //** @abstract(Asks for a sheet and loads its rows.)
    //**
    //** @param(Sender The button.)
    /// <summary>Asks for a sheet and loads its rows.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnLoadSheetClick(Sender: TObject);

    //** @abstract(Asks for a text file and reads the ranges from it.)
    //**
    //** @param(Sender The button.)
    /// <summary>Asks for a text file and reads the ranges from it.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnImportListClick(Sender: TObject);

    //** @abstract(Asks, then empties the grid.)
    //**
    //** @param(Sender The button.)
    /// <summary>Asks, then empties the grid.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnClearClick(Sender: TObject);

    //** @abstract(Checks the rows and, when they are valid, closes the dialog with mrOk.)
    //**
    //** @param(Sender The button.)
    /// <summary>Checks the rows and, when they are valid, closes the dialog with mrOk.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnConvertClick(Sender: TObject);

    //** @abstract(Adds an empty row when needed, checks the rows and warns of a row that goes
    //** back in time.)
    //**
    //** @param(Sender The grid.)
    //**
    //** @param(ACol The column of the cell edited.)
    //**
    //** @param(ARow The row of the cell edited.)
    /// <summary>Adds an empty row when needed, checks the rows and warns of a row that goes
    /// back in time.</summary>
    /// <param name="Sender">The grid.</param>
    /// <param name="ACol">The column of the cell edited.</param>
    /// <param name="ARow">The row of the cell edited.</param>
    procedure grdRangesEditingDone(Sender: TObject; const ACol, ARow: Integer);

    //** @abstract(Frees the form when it closes.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Set to caFree.)
    /// <summary>Frees the form when it closes.</summary>
    /// <param name="Sender">The form.</param>
    /// <param name="Action">Set to caFree.</param>
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FRoot: TglTF;
    FIndex: Integer;
    FName: string;
    FDuration: Double;
    FFrameRate: Double;
    FLastFrame: Integer;
    FLinking: Boolean;
    FLastWarning: string;
    FRanges: TglTFAnimationRanges;
    procedure Prepare(AKeyFrameRate: Double);
    function RowIsEmpty(ARow: Integer): Boolean;
    function ReadRow(ARow: Integer; out AName: string; out AStart, AEnd: Integer): Boolean;
    function OrderProblem(ARow: Integer): string;
    procedure NumberRows;
    procedure EnsureEmptyLastRow;
    procedure SetRate(ARate: Double);
    procedure SetLastFrame(ALastFrame: Integer);
    procedure Check;
    procedure ImportList(const AFileName: string);
    procedure ClearRows;
    procedure SaveSheet(const AFileName: string);
    procedure LoadSheet(const AFileName: string);
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
    //** @param(ADone Called with the ranges and the frame rate on Convert.)
    /// <summary>Shows the dialog modally for one animation.</summary>
    /// <param name="ARoot">The tree holding the animation; read for its length, its key
    /// frames and the names already used.</param>
    /// <param name="AIndex">Index in <c>ARoot.Animations</c> of the animation to
    /// split.</param>
    /// <param name="ADone">Called with the ranges and the frame rate on Convert.</param>
    /// <remarks>The dialog frees itself when it closes; ADone is only called when the user
    /// presses Convert. Nothing is changed by the dialog itself.</remarks>
    class procedure Execute(ARoot: TglTF; AIndex: Integer; const ADone: TSplitDoneProc);
  end;

implementation

{$R *.fmx}

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

  // The kinds of dialog, each with its own folder remembered in the settings
  KEY_SAVE_SHEET = 'saveRangeSheet';
  KEY_LOAD_SHEET = 'loadRangeSheet';
  KEY_IMPORT_LIST = 'importRangeList';

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
  const ADone: TSplitDoneProc);
var
  LForm: TSplitAnimationForm;
begin
  LForm := TSplitAnimationForm.Create(Application);
  LForm.FRoot := ARoot;
  LForm.FIndex := AIndex;
  LForm.FName := ARoot.Animations[AIndex].Name;
  if LForm.FName = '' then
    LForm.FName := Format('Animation %d', [AIndex]);
  LForm.FDuration := TglTFAnimationSplitter.Duration(ARoot, ARoot.Animations[AIndex]);
  LForm.Prepare(TglTFAnimationSplitter.DetectFrameRate(ARoot, ARoot.Animations[AIndex]));
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

procedure TSplitAnimationForm.Prepare(AKeyFrameRate: Double);
begin
  // What the design cannot know: the animation, and how the grid edits
  Caption := 'Split "' + FName + '"';
  lblInfo.Text := Format('"%s" is %.2f seconds long; frames run from 0 to the last frame',
    [FName, FDuration]);
  lblHint.Text := Format('Change either: the other follows. The key frames suggest about %s ' +
    'frames per second.', [RateText(AKeyFrameRate)]);
  // Like a spreadsheet: cells are edited in place and Tab moves on
  grdRanges.Options := grdRanges.Options + [TGridOption.Editing, TGridOption.AlwaysShowEditor,
    TGridOption.Tabs] - [TGridOption.RowSelect];
  grdRanges.RowCount := 1;
  NumberRows;
end;

procedure TSplitAnimationForm.SetRate(ARate: Double);
begin
  // The last frame follows the frame rate
  FFrameRate := ARate;
  FLastFrame := TglTFAnimationSplitter.LastFrame(FDuration, ARate);
  FLinking := True;
  try
    edtRate.Text := RateText(FFrameRate);
    edtLastFrame.Text := IntToStr(FLastFrame);
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
    edtRate.Text := RateText(FFrameRate);
    edtLastFrame.Text := IntToStr(FLastFrame);
  finally
    FLinking := False;
  end;
end;

procedure TSplitAnimationForm.edtRateChangeTracking(Sender: TObject);
var
  LRate: Double;
begin
  if FLinking then
    Exit;
  if ParseRate(edtRate.Text, LRate) then
  begin
    FFrameRate := LRate;
    FLastFrame := TglTFAnimationSplitter.LastFrame(FDuration, LRate);
    FLinking := True;
    try
      edtLastFrame.Text := IntToStr(FLastFrame);
    finally
      FLinking := False;
    end;
  end
  else
    FFrameRate := 0;
  Check;
end;

procedure TSplitAnimationForm.edtLastFrameChangeTracking(Sender: TObject);
var
  LLast: Integer;
begin
  if FLinking then
    Exit;
  if TryStrToInt(Trim(edtLastFrame.Text), LLast) and (LLast > 0) and (FDuration > 0) then
  begin
    FLastFrame := LLast;
    FFrameRate := LLast / FDuration;
    FLinking := True;
    try
      edtRate.Text := RateText(FFrameRate);
    finally
      FLinking := False;
    end;
  end
  else
    FFrameRate := 0;
  Check;
end;

procedure TSplitAnimationForm.chkIncreasingChange(Sender: TObject);
begin
  FLastWarning := '';
  Check;
end;

function TSplitAnimationForm.RowIsEmpty(ARow: Integer): Boolean;
var
  C: Integer;
begin
  for C := COL_NAME to COL_END do
    if Trim(grdRanges.Cells[C, ARow]) <> '' then
      Exit(False);
  Result := True;
end;

function TSplitAnimationForm.ReadRow(ARow: Integer; out AName: string;
  out AStart, AEnd: Integer): Boolean;
begin
  AName := Trim(grdRanges.Cells[COL_NAME, ARow]);
  Result := TryStrToInt(Trim(grdRanges.Cells[COL_START, ARow]), AStart) and
    TryStrToInt(Trim(grdRanges.Cells[COL_END, ARow]), AEnd);
end;

function TSplitAnimationForm.OrderProblem(ARow: Integer): string;
var
  LName, LPrevName: string;
  LStart, LEnd, LPrevStart, LPrevEnd, R: Integer;
begin
  // The nearest filled row before ARow must end at or before ARow's start
  Result := '';
  if not chkIncreasing.IsChecked or RowIsEmpty(ARow) or not ReadRow(ARow, LName, LStart, LEnd) then
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
  for R := 0 to grdRanges.RowCount - 1 do
    grdRanges.Cells[COL_ROW, R] := IntToStr(R + 1);
end;

procedure TSplitAnimationForm.EnsureEmptyLastRow;
begin
  // There is always exactly one empty row to type into at the end
  if not RowIsEmpty(grdRanges.RowCount - 1) then
    grdRanges.RowCount := grdRanges.RowCount + 1;
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
  if FRoot = nil then
    Exit; // a change while the form is loaded, before Execute set it up
  // The rows that are not empty, as ranges; numbers that do not read are
  // reported here, the rest by ValidateRanges
  LRanges := nil;
  LRows := nil;
  LProblems := nil;
  for R := 0 to grdRanges.RowCount - 1 do
  begin
    if RowIsEmpty(R) then
      Continue;
    LRange.Notes := '';
    if not TryStrToInt(Trim(grdRanges.Cells[COL_START, R]), LRange.StartFrame) then
    begin
      LProblems := LProblems + [Format('Row %d: Start Frame must be a whole number', [R + 1])];
      Continue;
    end;
    if not TryStrToInt(Trim(grdRanges.Cells[COL_END, R]), LRange.EndFrame) then
    begin
      LProblems := LProblems + [Format('Row %d: End Frame must be a whole number', [R + 1])];
      Continue;
    end;
    LRange.Name := Trim(grdRanges.Cells[COL_NAME, R]);
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
  lblProblems.Text := Trim(LText);

  btnConvert.Enabled := (LProblems = nil) and (LRanges <> nil);
  if btnConvert.Enabled then
    FRanges := LRanges;
end;

procedure TSplitAnimationForm.grdRangesEditingDone(Sender: TObject; const ACol, ARow: Integer);
var
  LWarning: string;
begin
  EnsureEmptyLastRow;
  Check;

  // A row that goes back in time: say so at once, once per problem
  if (ACol = COL_START) or (ACol = COL_END) then
  begin
    LWarning := OrderProblem(ARow);
    if (LWarning = '') and (ARow + 1 < grdRanges.RowCount) then
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
    LJSON.AddPair('framesIncrease', TJSONBool.Create(chkIncreasing.IsChecked));
    LRows := TJSONArray.Create;
    LJSON.AddPair('rows', LRows);
    for R := 0 to grdRanges.RowCount - 1 do
      if not RowIsEmpty(R) then
      begin
        LRow := TJSONObject.Create;
        LRow.AddPair('name', grdRanges.Cells[COL_NAME, R]);
        if ReadRow(R, LName, LStart, LEnd) then
        begin
          LRow.AddPair('start', TJSONNumber.Create(LStart));
          LRow.AddPair('end', TJSONNumber.Create(LEnd));
        end
        else
        begin
          LRow.AddPair('start', grdRanges.Cells[COL_START, R]);
          LRow.AddPair('end', grdRanges.Cells[COL_END, R]);
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
      chkIncreasing.IsChecked := LIncreasing;

    LRows := TJSONObject(LJSON).GetValue('rows') as TJSONArray;
    grdRanges.RowCount := LRows.Count + 1;
    for R := 0 to grdRanges.RowCount - 1 do
    begin
      grdRanges.Cells[COL_NAME, R] := '';
      grdRanges.Cells[COL_START, R] := '';
      grdRanges.Cells[COL_END, R] := '';
    end;
    for R := 0 to LRows.Count - 1 do
      if LRows.Items[R] is TJSONObject then
      begin
        LRow := TJSONObject(LRows.Items[R]);
        grdRanges.Cells[COL_NAME, R] := CellText(LRow.GetValue('name'));
        grdRanges.Cells[COL_START, R] := CellText(LRow.GetValue('start'));
        grdRanges.Cells[COL_END, R] := CellText(LRow.GetValue('end'));
      end;
  finally
    LJSON.Free;
  end;
  EnsureEmptyLastRow;
  FLastWarning := '';
  Check;
end;

procedure TSplitAnimationForm.btnSaveSheetClick(Sender: TObject);
begin
  TPlatformDialogs.SaveFile(KEY_SAVE_SHEET, 'Save animation ranges',
    [TFileType.Create('Animation range sheet', [SHEET_EXTENSION])], 0, '',
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
      except
        on E: Exception do
          TDialogService.ShowMessage('The sheet could not be saved: ' + E.Message);
      end;
    end);
end;

procedure TSplitAnimationForm.btnLoadSheetClick(Sender: TObject);
begin
  TPlatformDialogs.OpenFile(KEY_LOAD_SHEET, 'Load animation ranges',
    [TFileType.Create('Animation range sheet', [SHEET_EXTENSION]),
     TFileType.Create('All files', ['*'])], '', '',
    procedure(AFileName: string)
    begin
      if AFileName = '' then
        Exit;
      try
        LoadSheet(AFileName);
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
  for R := 0 to grdRanges.RowCount - 1 do
  begin
    grdRanges.Cells[COL_NAME, R] := '';
    grdRanges.Cells[COL_START, R] := '';
    grdRanges.Cells[COL_END, R] := '';
  end;
  grdRanges.RowCount := 1;
  NumberRows;
  FLastWarning := '';
  Check;
end;

procedure TSplitAnimationForm.btnClearClick(Sender: TObject);
begin
  if RowIsEmpty(0) and (grdRanges.RowCount = 1) then
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
  grdRanges.RowCount := Length(LList.Ranges) + 1;
  LMaxEnd := 0;
  for R := 0 to High(LList.Ranges) do
  begin
    grdRanges.Cells[COL_NAME, R] := LList.Ranges[R].Name;
    grdRanges.Cells[COL_START, R] := IntToStr(LList.Ranges[R].StartFrame);
    grdRanges.Cells[COL_END, R] := IntToStr(LList.Ranges[R].EndFrame);
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
  for R := 0 to grdRanges.RowCount - 1 do
    if OrderProblem(R) <> '' then
      Inc(LBackwards);
  if LBackwards > 0 then
    LMessage := LMessage + sLineBreak + Format('%d row(s) do not go forward in time.',
      [LBackwards]);
  LMessage := LMessage + sLineBreak + sLineBreak + 'Please check the rows before converting; ' +
    '"Clear" empties the grid if they are wrong.';
  TDialogService.ShowMessage(LMessage);
end;

procedure TSplitAnimationForm.btnImportListClick(Sender: TObject);
begin
  TPlatformDialogs.OpenFile(KEY_IMPORT_LIST, 'Import animation list',
    [TFileType.Create('Text files', ['.txt', '.csv', '.md']),
     TFileType.Create('All files', ['*'])], '', '',
    procedure(AFileName: string)
    begin
      if AFileName = '' then
        Exit;
      try
        ImportList(AFileName);
      except
        on E: Exception do
          TDialogService.ShowMessage('The list could not be read: ' + E.Message);
      end;
    end);
end;

procedure TSplitAnimationForm.btnConvertClick(Sender: TObject);
begin
  // The cell being edited counts too
  EnsureEmptyLastRow;
  Check;
  if btnConvert.Enabled then
    ModalResult := mrOk;
end;

procedure TSplitAnimationForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

end.
