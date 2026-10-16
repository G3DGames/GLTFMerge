//** @abstract(The Animations tab of the viewer: every animation of a document, with its Export
//** choice.)
//**
//** @link(TglTFAnimationsFrame) shows one row per animation with the columns Export, #, Name,
//** From, Channels and Duration. From is "model" for animations that came with the loaded
//** file and the file name for imported ones. The Export column edits
//** @code(TglTFAnimation.ExportOnSave): a save leaves out the animations not ticked, with the
//** data only they used. "Export all" and "Export none" change every flag at once.
//**
//** Clicking a name edits it in place: Enter keeps the new name, Escape or a name left
//** unchanged keeps the old one, and clicking elsewhere counts as Enter. A name is accepted
//** only when it is not empty and no other animation has it, case ignored @(see
//** @code(TglTFEdit.AnimationNameProblem)@); the text turns red while it cannot be used, and a
//** name not accepted is reported and the old one kept.
//**
//** "Clear animations" raises @link(TglTFAnimationsFrame.OnClear), to empty the list.
//** "Split long animation..." appears while an animation is over 10 seconds long and raises
//** @link(TglTFAnimationsFrame.OnSplit).
//** "Import animations..." raises @link(TglTFAnimationsFrame.OnImport); the main form shows
//** the file dialog and does the import, then calls RefreshList.
//**
//** On narrow screens the From column is hidden, and Channels too when narrower still. The
//** frame is designed in glTFViewer.Animations.fmx. The headings and the rows follow the
//** column list in the code and are laid out by glTFViewer.Columns, so the columns line up.
unit glTFViewer.Animations;

{
  The Animations tab of the viewer: every animation of a document, with its
  Export choice.

  TglTFAnimationsFrame shows one row per animation with the columns Export, #,
  Name, From, Channels and Duration. From is "model" for animations that came
  with the loaded file and the file name for imported ones. The Export column
  edits TglTFAnimation.ExportOnSave: a save leaves out the animations not
  ticked, with the data only they used. "Export all" and "Export none" change
  every flag at once.

  Clicking a name edits it in place: Enter keeps the new name, Escape or a
  name left unchanged keeps the old one, and clicking elsewhere counts as
  Enter. A name is accepted only when it is not empty and no other animation
  has it, case ignored (see TglTFEdit.AnimationNameProblem); the text turns
  red while it cannot be used, and a name not accepted is reported and the old
  one kept.

  "Clear animations" raises OnClear, to empty the list. "Split long
  animation..." appears while an animation is over 10 seconds long and raises
  OnSplit. "Import animations..." raises OnImport; the main form shows the
  file dialog and does the import, then calls RefreshList.

  On narrow screens the From column is hidden, and Channels too when narrower
  still. The frame is designed in glTFViewer.Animations.fmx. The headings and
  the rows follow the column list in the code and are laid out by
  glTFViewer.Columns, so the columns line up.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Layouts, FMX.ListBox,
  FMX.Graphics, FMX.Controls.Presentation, FMX.Edit,

  glTF.Classes, glTF.Document, glTF.AnimationSplit,
  glTFViewer.Columns;

type
  //** @abstract(Reports that an animation was renamed.)
  //**
  //** @param(Sender The frame.)
  //**
  //** @param(AIndex Index of the animation in the document.)
  //**
  //** @param(AOldName The name it had.)
  //**
  //** @param(ANewName The name it has now.)
  /// <summary>Reports that an animation was renamed.</summary>
  /// <param name="Sender">The frame.</param>
  /// <param name="AIndex">Index of the animation in the document.</param>
  /// <param name="AOldName">The name it had.</param>
  /// <param name="ANewName">The name it has now.</param>
  TglTFAnimationRenameEvent = procedure(Sender: TObject; AIndex: Integer;
    const AOldName, ANewName: string) of object;

  //** @abstract(Frame listing the animations of a document, with an Export checkbox per
  //** animation.)
  //**
  //** Place it on a tab with Align = Client and call @link(Bind) after each load and
  //** @link(RefreshList) after each import. Must be used on the main thread.
  /// <summary>Frame listing the animations of a document, with an Export checkbox per
  /// animation.</summary>
  /// <remarks>Place it on a tab with Align = Client and call <see cref="Bind"/> after each
  /// load and <see cref="RefreshList"/> after each import. Must be used on the main
  /// thread.</remarks>
  TglTFAnimationsFrame = class(TFrame)
    //** @abstract(The bar of buttons and the summary, at the top.)
    /// <summary>The bar of buttons and the summary, at the top.</summary>
    layBar: TLayout;

    //** @abstract(Raises OnImport; enabled once a file is loaded.)
    /// <summary>Raises OnImport; enabled once a file is loaded.</summary>
    btnImport: TButton;

    //** @abstract(Ticks Export for every animation.)
    /// <summary>Ticks Export for every animation.</summary>
    btnExportAll: TButton;

    //** @abstract(Unticks Export for every animation.)
    /// <summary>Unticks Export for every animation.</summary>
    btnExportNone: TButton;

    //** @abstract(Raises OnClear.)
    /// <summary>Raises OnClear.</summary>
    btnClear: TButton;

    //** @abstract(Raises OnSplit; shown only while an animation is long.)
    /// <summary>Raises OnSplit; shown only while an animation is long.</summary>
    btnSplit: TButton;

    //** @abstract(How many animations there are and how many will be saved.)
    /// <summary>How many animations there are and how many will be saved.</summary>
    lblSummary: TLabel;

    //** @abstract(The column headings, filled in from the column list.)
    /// <summary>The column headings, filled in from the column list.</summary>
    layHeader: TLayout;

    //** @abstract(One row per animation.)
    /// <summary>One row per animation.</summary>
    lstAnimations: TListBox;

    //** @abstract(Edits a name in place; moved over the name clicked, hidden otherwise.)
    /// <summary>Edits a name in place; moved over the name clicked, hidden
    /// otherwise.</summary>
    edtRename: TEdit;

    //** @abstract(Keeps the new name on Enter; keeps the old one on Escape.)
    //**
    //** @param(Sender The edit box.)
    //**
    //** @param(Key The key pressed; 0 once handled.)
    //**
    //** @param(KeyChar The character typed.)
    //**
    //** @param(Shift The modifier keys held.)
    /// <summary>Keeps the new name on Enter; keeps the old one on Escape.</summary>
    /// <param name="Sender">The edit box.</param>
    /// <param name="Key">The key pressed; 0 once handled.</param>
    /// <param name="KeyChar">The character typed.</param>
    /// <param name="Shift">The modifier keys held.</param>
    procedure edtRenameKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);

    //** @abstract(Keeps the new name when the edit box loses the focus, as Enter does.)
    //**
    //** @param(Sender The edit box.)
    /// <summary>Keeps the new name when the edit box loses the focus, as Enter
    /// does.</summary>
    /// <param name="Sender">The edit box.</param>
    procedure edtRenameExit(Sender: TObject);

    //** @abstract(Shows, as it is typed, whether the name can be used.)
    //**
    //** @param(Sender The edit box.)
    /// <summary>Shows, as it is typed, whether the name can be used.</summary>
    /// <param name="Sender">The edit box.</param>
    procedure edtRenameChangeTracking(Sender: TObject);

    //** @abstract(Raises OnImport.)
    //**
    //** @param(Sender The button.)
    /// <summary>Raises OnImport.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnImportClick(Sender: TObject);

    //** @abstract(Ticks Export for every animation.)
    //**
    //** @param(Sender The button.)
    /// <summary>Ticks Export for every animation.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnExportAllClick(Sender: TObject);

    //** @abstract(Unticks Export for every animation.)
    //**
    //** @param(Sender The button.)
    /// <summary>Unticks Export for every animation.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnExportNoneClick(Sender: TObject);

    //** @abstract(Raises OnClear.)
    //**
    //** @param(Sender The button.)
    /// <summary>Raises OnClear.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnClearClick(Sender: TObject);

    //** @abstract(Raises OnSplit.)
    //**
    //** @param(Sender The button.)
    /// <summary>Raises OnSplit.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnSplitClick(Sender: TObject);

    //** @abstract(Lays out the headings again when their width changes.)
    //**
    //** @param(Sender The heading row.)
    /// <summary>Lays out the headings again when their width changes.</summary>
    /// <param name="Sender">The heading row.</param>
    procedure layHeaderResize(Sender: TObject);

    //** @abstract(Keeps the headings above the cells of the rows.)
    //**
    //** The list's border and scroll bar take room from the rows but not from the headings.
    //**
    //** @param(Sender The list.)
    //**
    //** @param(Canvas The canvas painted on.)
    //**
    //** @param(ARect The area painted.)
    /// <summary>Keeps the headings above the cells of the rows.</summary>
    /// <param name="Sender">The list.</param>
    /// <param name="Canvas">The canvas painted on.</param>
    /// <param name="ARect">The area painted.</param>
    /// <remarks>The list's border and scroll bar take room from the rows but not from the
    /// headings.</remarks>
    procedure lstAnimationsPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  private
    FDoc: TglTFDocument;
    FChecks: TList<TCheckBox>;
    FUpdating: Boolean;
    FOnImport: TNotifyEvent;
    FOnClear: TNotifyEvent;
    FOnSplit: TNotifyEvent;
    FOnChange: TNotifyEvent;
    FOnRename: TglTFAnimationRenameEvent;
    FColumns: TColumnDefs;
    // The animation whose name is being edited, -1 for none, and its name cell
    FRenameIndex: Integer;
    FRenameLabel: TLabel;
    procedure RowResize(Sender: TObject);
    procedure LayoutRow(ARow: TControl);
    procedure AddRow(AIndex: Integer; AAnimation: TglTFAnimation);
    function Duration(AAnimation: TglTFAnimation): string;
    procedure ExportChange(Sender: TObject);
    procedure SetAll(AValue: Boolean);
    procedure Changed;
    procedure NameClick(Sender: TObject);
    procedure BeginRename(ALabel: TLabel);
    procedure CommitRename;
    procedure EndRename;
    procedure UpdateSummary;
    procedure ApplyWidth;
  protected
    //** @abstract(Lays the rows out again for the new width.)
    /// <summary>Lays the rows out again for the new width.</summary>
    procedure Resize; override;
  public
    //** @abstract(Creates the frame with an empty list.)
    //**
    //** @param(AOwner Owner of the frame.)
    /// <summary>Creates the frame with an empty list.</summary>
    /// <param name="AOwner">Owner of the frame.</param>
    constructor Create(AOwner: TComponent); override;

    //** @abstract(Frees the frame and its rows.)
    /// <summary>Frees the frame and its rows.</summary>
    destructor Destroy; override;

    //** @abstract(Shows the animations of a document.)
    //**
    //** The frame keeps a reference to ADoc but does not own it; call Bind@(nil@) before
    //** freeing the document.
    //**
    //** @param(ADoc The document to show; nil clears the list.)
    /// <summary>Shows the animations of a document.</summary>
    /// <param name="ADoc">The document to show; nil clears the list.</param>
    /// <remarks>The frame keeps a reference to ADoc but does not own it; call Bind(nil) before
    /// freeing the document.</remarks>
    procedure Bind(ADoc: TglTFDocument);

    //** @abstract(Rebuilds the rows from the current document.)
    //**
    //** Call it after animations were imported.
    /// <summary>Rebuilds the rows from the current document.</summary>
    /// <remarks>Call it after animations were imported.</remarks>
    procedure RefreshList;

    //** @abstract(Occurs when the user clicks "Import animations...".)
    //**
    //** The handler is expected to let the user choose the files, import them and then call
    //** @link(RefreshList).
    /// <summary>Occurs when the user clicks "Import animations...".</summary>
    /// <remarks>The handler is expected to let the user choose the files, import them and then
    /// call <see cref="RefreshList"/>.</remarks>
    property OnImport: TNotifyEvent read FOnImport write FOnImport;

    //** @abstract(Occurs when the user clicks "Clear animations".)
    //**
    //** The handler is expected to confirm, remove every animation from the document and
    //** then call @link(RefreshList).
    /// <summary>Occurs when the user clicks "Clear animations".</summary>
    /// <remarks>The handler is expected to confirm, remove every animation from the document
    /// and then call <see cref="RefreshList"/>.</remarks>
    property OnClear: TNotifyEvent read FOnClear write FOnClear;

    //** @abstract(Occurs when the user clicks "Split long animation...".)
    //**
    //** The button is only shown while the document has an animation longer than
    //** @code(TglTFAnimationSplitter.LongAnimationSeconds), which is likely to be several
    //** animations joined together. The handler is expected to show the split dialog for it
    //** and then call @link(RefreshList).
    /// <summary>Occurs when the user clicks "Split long animation...".</summary>
    /// <remarks>The button is only shown while the document has an animation longer than
    /// <c>TglTFAnimationSplitter.LongAnimationSeconds</c>, which is likely to be several
    /// animations joined together. The handler is expected to show the split dialog for it
    /// and then call <see cref="RefreshList"/>.</remarks>
    property OnSplit: TNotifyEvent read FOnSplit write FOnSplit;
    //** @abstract(Occurs when the user changes what a save writes: an Export tick.)
    /// <summary>Occurs when the user changes what a save writes: an Export tick.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    //** @abstract(Occurs after an animation was renamed in the list, after OnChange.)
    /// <summary>Occurs after an animation was renamed in the list, after OnChange.</summary>
    property OnRename: TglTFAnimationRenameEvent read FOnRename write FOnRename;
  end;

implementation

{$R *.fmx}

uses
  FMX.DialogService,
  glTF.Edit;

const
  ROW_HEIGHT = 26;

  // Columns, in display order (see TColumnLayout); Name takes the rest
  COL_EXPORT = 0;
  COL_INDEX = 1;
  COL_NAME = 2;
  COL_FROM = 3;
  COL_CHANNELS = 4;
  COL_DURATION = 5;

  // Below these frame widths (phones in portrait) some columns are hidden
  NARROW_WIDTH = 600;
  VERY_NARROW_WIDTH = 420;

{ TglTFAnimationsFrame }

constructor TglTFAnimationsFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRenameIndex := -1;
  FChecks := TList<TCheckBox>.Create;
  FColumns := [
    TColumnDef.Create('Export', 64, chNever, True),
    TColumnDef.Create('#', 40),
    TColumnDef.Create('Name', 0),
    TColumnDef.Create('From', 220, chNarrow),
    TColumnDef.Create('Channels', 80, chVeryNarrow),
    TColumnDef.Create('Duration', 90)];
  // The headings come from the same list as the rows' cells, so they match
  TColumnLayout.AddHeadings(layHeader, FColumns);
  Bind(nil);
end;

destructor TglTFAnimationsFrame.Destroy;
begin
  FChecks.Free;
  inherited;
end;

procedure TglTFAnimationsFrame.lstAnimationsPainting(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  if TColumnLayout.AlignHeader(layHeader, lstAnimations) then
    LayoutRow(layHeader);
end;

procedure TglTFAnimationsFrame.LayoutRow(ARow: TControl);
begin
  TColumnLayout.LayoutRow(ARow, FColumns, Width, NARROW_WIDTH, VERY_NARROW_WIDTH);
  // The name being edited stays over its cell
  if (FRenameLabel <> nil) and (FRenameLabel.Parent = ARow) then
    edtRename.BoundsRect := FRenameLabel.BoundsRect;
end;

procedure TglTFAnimationsFrame.RowResize(Sender: TObject);
begin
  LayoutRow(Sender as TControl);
end;

procedure TglTFAnimationsFrame.layHeaderResize(Sender: TObject);
begin
  LayoutRow(layHeader);
end;

function TglTFAnimationsFrame.Duration(AAnimation: TglTFAnimation): string;
var
  LSampler: TglTFAnimationSampler;
  LAccessor: TglTFAccessor;
  LEnd: Double;
  LKnown: Boolean;
begin
  // The last key frame time: the largest "max" of the sampler inputs
  LEnd := 0;
  LKnown := False;
  for LSampler in AAnimation.Samplers do
    if (LSampler.Input >= 0) and (LSampler.Input < FDoc.Root.Accessors.Count) then
    begin
      LAccessor := FDoc.Root.Accessors[LSampler.Input];
      if Length(LAccessor.Max) > 0 then
      begin
        LEnd := Max(LEnd, LAccessor.Max[0]);
        LKnown := True;
      end;
    end;
  if LKnown then
    Result := Format('%.2f s', [LEnd])
  else
    Result := '?';
end;

procedure TglTFAnimationsFrame.AddRow(AIndex: Integer; AAnimation: TglTFAnimation);
var
  LItem: TListBoxItem;
  LCheck: TCheckBox;
  LLabel: TLabel;
  LName, LFrom: string;
begin
  LName := AAnimation.Name;
  if LName = '' then
    LName := Format('(animation %d)', [AIndex]);
  LFrom := AAnimation.Origin;
  if LFrom = '' then
    LFrom := 'model';

  LItem := TListBoxItem.Create(lstAnimations);
  LItem.Parent := lstAnimations;
  LItem.Height := ROW_HEIGHT;
  LItem.Text := '';
  LItem.Padding.Rect := TRectF.Create(TColumnLayout.RowPadding, 0, TColumnLayout.RowPadding, 0);
  LItem.Tag := AIndex;

  LCheck := TColumnLayout.AddCheck(LItem, COL_EXPORT);
  LCheck.Tag := AIndex;
  LCheck.IsChecked := AAnimation.ExportOnSave;
  LCheck.OnChange := ExportChange;
  FChecks.Add(LCheck);

  TColumnLayout.AddText(LItem, COL_INDEX, IntToStr(AIndex));
  // Clicking the name edits it
  LLabel := TColumnLayout.AddText(LItem, COL_NAME, LName);
  LLabel.HitTest := True;
  LLabel.Cursor := crIBeam;
  LLabel.Hint := 'Click to rename';
  LLabel.ShowHint := True;
  LLabel.OnClick := NameClick;
  TColumnLayout.AddText(LItem, COL_FROM, LFrom);
  TColumnLayout.AddText(LItem, COL_CHANNELS, IntToStr(AAnimation.Channels.Count));
  TColumnLayout.AddText(LItem, COL_DURATION, Duration(AAnimation));

  LItem.OnResize := RowResize;
  LayoutRow(LItem);
end;

procedure TglTFAnimationsFrame.Bind(ADoc: TglTFDocument);
begin
  FDoc := ADoc;
  RefreshList;
end;

procedure TglTFAnimationsFrame.RefreshList;
var
  I: Integer;
begin
  // The rows are rebuilt: a name being edited keeps its old value
  EndRename;
  FUpdating := True;
  lstAnimations.BeginUpdate;
  try
    lstAnimations.Clear;
    FChecks.Clear;
    if Assigned(FDoc) then
      for I := 0 to FDoc.Root.Animations.Count - 1 do
        AddRow(I, FDoc.Root.Animations[I]);
  finally
    lstAnimations.EndUpdate;
    FUpdating := False;
  end;
  ApplyWidth;
  UpdateSummary;
end;

procedure TglTFAnimationsFrame.Resize;
begin
  inherited;
  ApplyWidth;
end;

procedure TglTFAnimationsFrame.ApplyWidth;
var
  I: Integer;
begin
  if FColumns = nil then
    Exit; // Resize while the frame is loaded
  LayoutRow(layHeader);
  for I := 0 to lstAnimations.Count - 1 do
    LayoutRow(lstAnimations.ListItems[I]);
  // The summary needs the room the buttons leave
  lblSummary.Visible := Width >= 960;
end;

procedure TglTFAnimationsFrame.UpdateSummary;
var
  LAnimation: TglTFAnimation;
  LCount, LExport, LImported: Integer;
  LLoaded: Boolean;
begin
  LCount := 0;
  LExport := 0;
  LImported := 0;
  LLoaded := Assigned(FDoc) and (FDoc.FileFormat <> gffNone);
  if Assigned(FDoc) then
    for LAnimation in FDoc.Root.Animations do
    begin
      Inc(LCount);
      if LAnimation.ExportOnSave then
        Inc(LExport);
      if LAnimation.Origin <> '' then
        Inc(LImported);
    end;

  if not LLoaded then
    lblSummary.Text := 'No file loaded'
  else if LCount = 0 then
    lblSummary.Text := 'No animations; import some from other files'
  else
    lblSummary.Text := Format('%d animation(s), %d imported; %d will be saved',
      [LCount, LImported, LExport]);

  btnImport.Enabled := LLoaded;
  btnExportAll.Enabled := LCount > 0;
  btnExportNone.Enabled := LCount > 0;
  btnClear.Enabled := LCount > 0;
  // Offered while one animation is long enough to be several joined together
  btnSplit.Visible := (LCount > 0) and
    (TglTFAnimationSplitter.FindLongAnimation(FDoc.Root) >= 0);
end;

procedure TglTFAnimationsFrame.ExportChange(Sender: TObject);
var
  LCheck: TCheckBox;
begin
  if FUpdating or not Assigned(FDoc) then
    Exit;
  LCheck := Sender as TCheckBox;
  FDoc.Root.Animations[LCheck.Tag].ExportOnSave := LCheck.IsChecked;
  UpdateSummary;
  Changed;
end;

procedure TglTFAnimationsFrame.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TglTFAnimationsFrame.SetAll(AValue: Boolean);
var
  LAnimation: TglTFAnimation;
  LCheck: TCheckBox;
begin
  if not Assigned(FDoc) then
    Exit;
  for LAnimation in FDoc.Root.Animations do
    LAnimation.ExportOnSave := AValue;

  FUpdating := True;
  try
    for LCheck in FChecks do
      LCheck.IsChecked := AValue;
  finally
    FUpdating := False;
  end;
  UpdateSummary;
  Changed;
end;

procedure TglTFAnimationsFrame.NameClick(Sender: TObject);
begin
  BeginRename(Sender as TLabel);
end;

procedure TglTFAnimationsFrame.BeginRename(ALabel: TLabel);
var
  LItem: TControl;
begin
  if not Assigned(FDoc) or not (ALabel.Parent is TListBoxItem) then
    Exit;
  LItem := TControl(ALabel.Parent);
  if (LItem.Tag = FRenameIndex) and edtRename.Visible then
    Exit; // already editing this one
  // Another name being edited is kept first, as when clicking elsewhere
  CommitRename;
  if (LItem.Tag < 0) or (LItem.Tag >= FDoc.Root.Animations.Count) then
    Exit;

  FRenameIndex := LItem.Tag;
  FRenameLabel := ALabel;
  edtRename.Parent := LItem;
  edtRename.BoundsRect := ALabel.BoundsRect;
  edtRename.Text := FDoc.Root.Animations[FRenameIndex].Name;
  edtRename.Visible := True;
  edtRename.BringToFront;
  edtRename.SetFocus;
  edtRename.SelectAll;
  edtRenameChangeTracking(edtRename);
end;

procedure TglTFAnimationsFrame.EndRename;
begin
  if FRenameIndex < 0 then
    Exit;
  // Cleared first: hiding the edit box takes its focus, which would keep the
  // name again (edtRenameExit)
  FRenameIndex := -1;
  FRenameLabel := nil;
  edtRename.Visible := False;
  // Out of the row, which may be freed with the list's rows
  edtRename.Parent := Self;
  UpdateSummary;
end;

procedure TglTFAnimationsFrame.CommitRename;
var
  LIndex: Integer;
  LLabel: TLabel;
  LOld, LNew, LProblem: string;
begin
  if (FRenameIndex < 0) or not Assigned(FDoc) then
    Exit;
  LIndex := FRenameIndex;
  LLabel := FRenameLabel;
  LNew := Trim(edtRename.Text);
  EndRename;
  if (LIndex >= FDoc.Root.Animations.Count) then
    Exit;
  LOld := FDoc.Root.Animations[LIndex].Name;
  if LNew = LOld then
    Exit; // unchanged

  // Only a name no other animation has, case ignored
  LProblem := TglTFEdit.RenameAnimation(FDoc.Root, LIndex, LNew);
  if LProblem <> '' then
  begin
    TDialogService.ShowMessage(Format('Animation %d keeps its name "%s": %s.',
      [LIndex, LOld, LProblem]));
    Exit;
  end;
  LLabel.Text := FDoc.Root.Animations[LIndex].Name;
  Changed;
  if Assigned(FOnRename) then
    FOnRename(Self, LIndex, LOld, FDoc.Root.Animations[LIndex].Name);
end;

procedure TglTFAnimationsFrame.edtRenameKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  case Key of
    vkReturn:
      begin
        Key := 0;
        CommitRename;
      end;
    vkEscape:
      begin
        Key := 0;
        EndRename;
      end;
  end;
end;

procedure TglTFAnimationsFrame.edtRenameExit(Sender: TObject);
begin
  CommitRename;
end;

procedure TglTFAnimationsFrame.edtRenameChangeTracking(Sender: TObject);
var
  LProblem: string;
begin
  if (FRenameIndex < 0) or not Assigned(FDoc) then
    Exit;
  // Red, with the reason in the hint and the summary, while it cannot be used
  LProblem := TglTFEdit.AnimationNameProblem(FDoc.Root, edtRename.Text, FRenameIndex);
  if LProblem <> '' then
  begin
    edtRename.StyledSettings := edtRename.StyledSettings - [TStyledSetting.FontColor];
    edtRename.TextSettings.FontColor := TAlphaColors.Red;
    lblSummary.Text := LProblem;
  end
  else
  begin
    edtRename.StyledSettings := edtRename.StyledSettings + [TStyledSetting.FontColor];
    lblSummary.Text := 'Enter keeps the new name, Escape the old one';
  end;
  edtRename.Hint := LProblem;
  edtRename.ShowHint := LProblem <> '';
end;

procedure TglTFAnimationsFrame.btnSplitClick(Sender: TObject);
begin
  if Assigned(FOnSplit) then
    FOnSplit(Self);
end;

procedure TglTFAnimationsFrame.btnClearClick(Sender: TObject);
begin
  if Assigned(FOnClear) then
    FOnClear(Self);
end;

procedure TglTFAnimationsFrame.btnImportClick(Sender: TObject);
begin
  if Assigned(FOnImport) then
    FOnImport(Self);
end;

procedure TglTFAnimationsFrame.btnExportAllClick(Sender: TObject);
begin
  SetAll(True);
end;

procedure TglTFAnimationsFrame.btnExportNoneClick(Sender: TObject);
begin
  SetAll(False);
end;

end.
