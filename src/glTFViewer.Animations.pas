//** @abstract(The Animations tab of the viewer: every animation of a document, with its Export
//** choice.)
//**
//** @link(TglTFAnimationsPanel) shows one row per animation with the columns Export, #, Name,
//** From, Channels and Duration. From is "model" for animations that came with the loaded
//** file and the file name for imported ones. The Export column edits
//** @code(TglTFAnimation.ExportOnSave): a save leaves out the animations not ticked, with the
//** data only they used. "Export all" and "Export none" change every flag at once.
//**
//** "Clear animations" raises @link(TglTFAnimationsPanel.OnClear), to empty the list.
//** "Import animations..." raises @link(TglTFAnimationsPanel.OnImport); the main form shows
//** the file dialog and does the import, then calls RefreshList.
//**
//** On narrow screens the From column is hidden, and Channels too when narrower still. The
//** panel is built in code, so the unit needs no .fmx file; headings and rows are laid out by
//** glTFViewer.Columns, so the columns line up.
unit glTFViewer.Animations;

{
  The Animations tab of the viewer: every animation of a document, with its
  Export choice.

  TglTFAnimationsPanel shows one row per animation with the columns Export, #,
  Name, From, Channels and Duration. From is "model" for animations that came
  with the loaded file and the file name for imported ones. The Export column
  edits TglTFAnimation.ExportOnSave: a save leaves out the animations not
  ticked, with the data only they used. "Export all" and "Export none" change
  every flag at once.

  "Clear animations" raises OnClear, to empty the list. "Import
  animations..." raises OnImport; the main form shows the file dialog
  and does the import, then calls RefreshList.

  On narrow screens the From column is hidden, and Channels too when narrower
  still. The panel is built in code, so the unit needs no .fmx file; headings
  and rows are laid out by glTFViewer.Columns, so the columns line up.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.StdCtrls, FMX.Layouts, FMX.ListBox,
  FMX.Graphics, FMX.Controls.Presentation,

  glTF.Classes, glTF.Document,
  glTFViewer.Columns;

type
  //** @abstract(Panel listing the animations of a document, with an Export checkbox per
  //** animation.)
  //**
  //** Place it on a tab with Align = Client and call @link(Bind) after each load and
  //** @link(RefreshList) after each import. Must be used on the main thread.
  /// <summary>Panel listing the animations of a document, with an Export checkbox per
  /// animation.</summary>
  /// <remarks>Place it on a tab with Align = Client and call <see cref="Bind"/> after each
  /// load and <see cref="RefreshList"/> after each import. Must be used on the main
  /// thread.</remarks>
  TglTFAnimationsPanel = class(TLayout)
  private
    FDoc: TglTFDocument;
    FSummary: TLabel;
    FBtnImport: TButton;
    FBtnAll: TButton;
    FBtnNone: TButton;
    FBtnClear: TButton;
    FHeader: TLayout;
    FList: TListBox;
    FChecks: TList<TCheckBox>;
    FUpdating: Boolean;
    FOnImport: TNotifyEvent;
    FOnClear: TNotifyEvent;
    FColumns: TColumnDefs;
    procedure BuildControls;
    function AddButton(AParent: TFmxObject; const AText: string; AWidth, AGap, AOrder: Single;
      AOnClick: TNotifyEvent): TButton;
    procedure ListPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure RowResize(Sender: TObject);
    procedure LayoutRow(ARow: TControl);
    procedure AddRow(AIndex: Integer; AAnimation: TglTFAnimation);
    function Duration(AAnimation: TglTFAnimation): string;
    procedure ExportChange(Sender: TObject);
    procedure ImportClick(Sender: TObject);
    procedure ClearClick(Sender: TObject);
    procedure AllClick(Sender: TObject);
    procedure NoneClick(Sender: TObject);
    procedure SetAll(AValue: Boolean);
    procedure UpdateSummary;
    procedure ApplyWidth;
  protected
    procedure Resize; override;
  public
    //** @abstract(Creates the panel with an empty list.)
    //**
    //** @param(AOwner Owner of the panel.)
    /// <summary>Creates the panel with an empty list.</summary>
    /// <param name="AOwner">Owner of the panel.</param>
    constructor Create(AOwner: TComponent); override;

    //** @abstract(Frees the panel and its rows.)
    /// <summary>Frees the panel and its rows.</summary>
    destructor Destroy; override;

    //** @abstract(Shows the animations of a document.)
    //**
    //** The panel keeps a reference to ADoc but does not own it; call Bind@(nil@) before
    //** freeing the document.
    //**
    //** @param(ADoc The document to show; nil clears the list.)
    /// <summary>Shows the animations of a document.</summary>
    /// <param name="ADoc">The document to show; nil clears the list.</param>
    /// <remarks>The panel keeps a reference to ADoc but does not own it; call Bind(nil) before
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
  end;

implementation

const
  ROW_HEIGHT = 26;

  // Columns, in display order (see TColumnLayout); Name takes the rest
  COL_EXPORT = 0;
  COL_INDEX = 1;
  COL_NAME = 2;
  COL_FROM = 3;
  COL_CHANNELS = 4;
  COL_DURATION = 5;

  // Below these panel widths (phones in portrait) some columns are hidden
  NARROW_WIDTH = 600;
  VERY_NARROW_WIDTH = 420;

{ TglTFAnimationsPanel }

constructor TglTFAnimationsPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChecks := TList<TCheckBox>.Create;
  FColumns := [
    TColumnDef.Create('Export', 64, chNever, True),
    TColumnDef.Create('#', 40),
    TColumnDef.Create('Name', 0),
    TColumnDef.Create('From', 220, chNarrow),
    TColumnDef.Create('Channels', 80, chVeryNarrow),
    TColumnDef.Create('Duration', 90)];
  BuildControls;
  Bind(nil);
end;

destructor TglTFAnimationsPanel.Destroy;
begin
  FChecks.Free;
  inherited;
end;

function TglTFAnimationsPanel.AddButton(AParent: TFmxObject; const AText: string;
  AWidth, AGap, AOrder: Single; AOnClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  Result.Align := TAlignLayout.Left;
  Result.Width := AWidth;
  Result.Margins.Left := AGap;
  Result.Position.X := AOrder; // same-side alignment is ordered by position
  Result.Text := AText;
  Result.OnClick := AOnClick;
end;

procedure TglTFAnimationsPanel.BuildControls;
var
  LBar: TLayout;
begin
  // Button bar
  LBar := TLayout.Create(Self);
  LBar.Parent := Self;
  LBar.Align := TAlignLayout.Top;
  LBar.Height := 40;
  LBar.Padding.Rect := TRectF.Create(6, 6, 6, 6);

  FBtnImport := AddButton(LBar, 'Import animations...', 150, 0, 0, ImportClick);
  FBtnAll := AddButton(LBar, 'Export all', 100, 18, 200, AllClick);
  FBtnNone := AddButton(LBar, 'Export none', 100, 6, 400, NoneClick);
  FBtnClear := AddButton(LBar, 'Clear animations', 130, 18, 600, ClearClick);

  FSummary := TLabel.Create(Self);
  FSummary.Parent := LBar;
  FSummary.Align := TAlignLayout.Client;
  FSummary.Margins.Left := 14;

  // Column headings, laid out like the rows
  FHeader := TLayout.Create(Self);
  FHeader.Parent := Self;
  FHeader.Align := TAlignLayout.Top;
  FHeader.Height := ROW_HEIGHT;
  FHeader.Position.Y := 100;
  FHeader.Padding.Rect := TRectF.Create(TColumnLayout.RowPadding, 0, TColumnLayout.RowPadding, 0);
  TColumnLayout.AddHeadings(FHeader, FColumns);
  FHeader.OnResize := RowResize;

  FList := TListBox.Create(Self);
  FList.Parent := Self;
  FList.Align := TAlignLayout.Client;
  FList.ItemHeight := ROW_HEIGHT;
  // The headings follow the rows, whose room the list's border and scroll
  // bar reduce
  FList.OnPainting := ListPainting;
end;

procedure TglTFAnimationsPanel.ListPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  // The headings follow the rows, whose room the list's border and scroll
  // bar reduce
  if TColumnLayout.AlignHeader(FHeader, FList) then
    LayoutRow(FHeader);
end;

procedure TglTFAnimationsPanel.LayoutRow(ARow: TControl);
begin
  TColumnLayout.LayoutRow(ARow, FColumns, Width, NARROW_WIDTH, VERY_NARROW_WIDTH);
end;

procedure TglTFAnimationsPanel.RowResize(Sender: TObject);
begin
  LayoutRow(Sender as TControl);
end;

function TglTFAnimationsPanel.Duration(AAnimation: TglTFAnimation): string;
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

procedure TglTFAnimationsPanel.AddRow(AIndex: Integer; AAnimation: TglTFAnimation);
var
  LItem: TListBoxItem;
  LCheck: TCheckBox;
  LName, LFrom: string;
begin
  LName := AAnimation.Name;
  if LName = '' then
    LName := Format('(animation %d)', [AIndex]);
  LFrom := AAnimation.Origin;
  if LFrom = '' then
    LFrom := 'model';

  LItem := TListBoxItem.Create(FList);
  LItem.Parent := FList;
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
  TColumnLayout.AddText(LItem, COL_NAME, LName);
  TColumnLayout.AddText(LItem, COL_FROM, LFrom);
  TColumnLayout.AddText(LItem, COL_CHANNELS, IntToStr(AAnimation.Channels.Count));
  TColumnLayout.AddText(LItem, COL_DURATION, Duration(AAnimation));

  LItem.OnResize := RowResize;
  LayoutRow(LItem);
end;

procedure TglTFAnimationsPanel.Bind(ADoc: TglTFDocument);
begin
  FDoc := ADoc;
  RefreshList;
end;

procedure TglTFAnimationsPanel.RefreshList;
var
  I: Integer;
begin
  FUpdating := True;
  FList.BeginUpdate;
  try
    FList.Clear;
    FChecks.Clear;
    if Assigned(FDoc) then
      for I := 0 to FDoc.Root.Animations.Count - 1 do
        AddRow(I, FDoc.Root.Animations[I]);
  finally
    FList.EndUpdate;
    FUpdating := False;
  end;
  ApplyWidth;
  UpdateSummary;
end;

procedure TglTFAnimationsPanel.Resize;
begin
  inherited;
  ApplyWidth;
end;

procedure TglTFAnimationsPanel.ApplyWidth;
var
  I: Integer;
begin
  if (FHeader = nil) or (FList = nil) or (FSummary = nil) then
    Exit; // Resize during construction
  LayoutRow(FHeader);
  for I := 0 to FList.Count - 1 do
    LayoutRow(FList.ListItems[I]);
  // The summary needs the room the buttons leave
  FSummary.Visible := Width >= 760;
end;

procedure TglTFAnimationsPanel.UpdateSummary;
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
    FSummary.Text := 'No file loaded'
  else if LCount = 0 then
    FSummary.Text := 'No animations; import some from other files'
  else
    FSummary.Text := Format('%d animation(s), %d imported; %d will be saved',
      [LCount, LImported, LExport]);

  FBtnImport.Enabled := LLoaded;
  FBtnAll.Enabled := LCount > 0;
  FBtnNone.Enabled := LCount > 0;
  FBtnClear.Enabled := LCount > 0;
end;

procedure TglTFAnimationsPanel.ExportChange(Sender: TObject);
var
  LCheck: TCheckBox;
begin
  if FUpdating or not Assigned(FDoc) then
    Exit;
  LCheck := Sender as TCheckBox;
  FDoc.Root.Animations[LCheck.Tag].ExportOnSave := LCheck.IsChecked;
  UpdateSummary;
end;

procedure TglTFAnimationsPanel.SetAll(AValue: Boolean);
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
end;

procedure TglTFAnimationsPanel.ClearClick(Sender: TObject);
begin
  if Assigned(FOnClear) then
    FOnClear(Self);
end;

procedure TglTFAnimationsPanel.ImportClick(Sender: TObject);
begin
  if Assigned(FOnImport) then
    FOnImport(Self);
end;

procedure TglTFAnimationsPanel.AllClick(Sender: TObject);
begin
  SetAll(True);
end;

procedure TglTFAnimationsPanel.NoneClick(Sender: TObject);
begin
  SetAll(False);
end;

end.
