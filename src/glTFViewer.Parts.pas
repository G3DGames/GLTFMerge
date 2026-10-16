//** @abstract(The Parts tab of the viewer: body parts and outfit pieces to put on the model, and
//** those on it.)
//**
//** @link(TglTFPartsFrame) has two lists. The upper one, "Parts loaded", shows every part found
//** in the part files loaded @(see glTF.Parts@), one row each with the columns Use, Part,
//** File, Triangles, Covers and Status; Covers lists the bones the part covers with their
//** shares. The lower one, "Parts on the model", shows the parts put on the model, with the
//** columns Take off, Node, Part, From, Triangles and Covers.
//**
//** "Add part files..." raises @link(TglTFPartsFrame.OnAddFiles), "Put on ticked parts"
//** @link(TglTFPartsFrame.OnApply) and "Take off ticked parts" @link(TglTFPartsFrame.OnRemove);
//** the main form does the work and then calls RefreshList. The settings row decides how
//** much of the body is hidden under the parts: how close a part's surface must come to the
//** skin, as a share of the body's height, and the bones never hidden. "Use on the model"
//** hides the body again with them, through @link(TglTFPartsFrame.OnRefreshModel); otherwise
//** they apply from the next change.
//**
//** On narrow screens the File and From columns are hidden, and Triangles too when narrower
//** still. The frame is designed in glTFViewer.Parts.fmx. The headings and the rows follow
//** the column lists in the code and are laid out by glTFViewer.Columns, so the columns line
//** up.
unit glTFViewer.Parts;

{
  The Parts tab of the viewer: body parts and outfit pieces to put on the
  model, and those on it.

  TglTFPartsFrame has two lists. The upper one, "Parts loaded", shows every
  part found in the part files loaded (see glTF.Parts), one row each with the
  columns Use, Part, File, Triangles, Covers and Status; Covers lists the bones
  the part covers with their shares. The lower one, "Parts on the model",
  shows the parts put on the model, with the columns Take off, Node, Part,
  From, Triangles and Covers.

  "Add part files..." raises OnAddFiles, "Put on ticked parts" OnApply and
  "Take off ticked parts" OnRemove; the main form does the work and then calls
  RefreshList. The settings row decides how much of the body is hidden under
  the parts: how close a part's surface must come to the skin, as a share of
  the body's height, and the bones never hidden. "Use on the model" hides the
  body again with them, through OnRefreshModel; otherwise they apply from the
  next change.

  On narrow screens the File and From columns are hidden, and Triangles too
  when narrower still. The frame is designed in glTFViewer.Parts.fmx. The
  headings and the rows follow the column lists in the code and are laid out
  by glTFViewer.Columns, so the columns line up.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Layouts, FMX.ListBox, FMX.Edit,
  FMX.SpinBox, FMX.EditBox, FMX.Graphics, FMX.Controls.Presentation,

  glTF.Classes, glTF.Document, glTF.Parts,
  glTFViewer.Columns;

type
  //** @abstract(Frame listing the parts loaded and the parts on the model.)
  //**
  //** Place it on a tab with Align = Client, set @link(PartLibrary) once, and call
  //** @link(Bind) after each load and @link(RefreshList) after each change. Must be used on
  //** the main thread.
  /// <summary>Frame listing the parts loaded and the parts on the model.</summary>
  /// <remarks>Place it on a tab with Align = Client, set <see cref="PartLibrary"/> once, and
  /// call <see cref="Bind"/> after each load and <see cref="RefreshList"/> after each change.
  /// Must be used on the main thread.</remarks>
  TglTFPartsFrame = class(TFrame)
    //** @abstract(The buttons for the parts loaded and the summary, at the top.)
    /// <summary>The buttons for the parts loaded and the summary, at the top.</summary>
    layBar: TLayout;

    //** @abstract(Raises OnAddFiles.)
    /// <summary>Raises OnAddFiles.</summary>
    btnAddFiles: TButton;

    //** @abstract(Raises OnClearList; enabled while parts are loaded.)
    /// <summary>Raises OnClearList; enabled while parts are loaded.</summary>
    btnClearList: TButton;

    //** @abstract(Raises OnApply; enabled while a part is ticked.)
    /// <summary>Raises OnApply; enabled while a part is ticked.</summary>
    btnApply: TButton;

    //** @abstract(How many parts are loaded, usable and ticked.)
    /// <summary>How many parts are loaded, usable and ticked.</summary>
    lblSummary: TLabel;

    //** @abstract(The settings row: how much of the body is hidden under the parts.)
    /// <summary>The settings row: how much of the body is hidden under the parts.</summary>
    laySettings: TLayout;

    //** @abstract(The text before the closeness setting.)
    /// <summary>The text before the closeness setting.</summary>
    lblGapBefore: TLabel;

    //** @abstract(How close a part must come to the skin to hide it, in percent of the body's height.)
    /// <summary>How close a part must come to the skin to hide it, in percent of the body's height.</summary>
    spnGap: TSpinBox;

    //** @abstract(The text after the closeness setting.)
    /// <summary>The text after the closeness setting.</summary>
    lblGapAfter: TLabel;

    //** @abstract(The bones never hidden, separated by commas.)
    /// <summary>The bones never hidden, separated by commas.</summary>
    edtKeep: TEdit;

    //** @abstract(Raises OnRefreshModel; enabled while parts are on the model.)
    /// <summary>Raises OnRefreshModel; enabled while parts are on the model.</summary>
    btnRefresh: TButton;

    //** @abstract(Separates the two lists.)
    /// <summary>Separates the two lists.</summary>
    splApplied: TSplitter;

    //** @abstract(The parts on the model, at the bottom.)
    /// <summary>The parts on the model, at the bottom.</summary>
    layApplied: TLayout;

    //** @abstract(The title and the button of the lower list.)
    /// <summary>The title and the button of the lower list.</summary>
    layAppliedBar: TLayout;

    //** @abstract("Parts on the model" with their number.)
    /// <summary>"Parts on the model" with their number.</summary>
    lblAppliedTitle: TLabel;

    //** @abstract(Raises OnRemove; enabled while a part on the model is ticked.)
    /// <summary>Raises OnRemove; enabled while a part on the model is ticked.</summary>
    btnRemove: TButton;

    //** @abstract(The headings of the lower list, filled in from its column list.)
    /// <summary>The headings of the lower list, filled in from its column list.</summary>
    layAppliedHeader: TLayout;

    //** @abstract(One row per part on the model.)
    /// <summary>One row per part on the model.</summary>
    lstApplied: TListBox;

    //** @abstract(The headings of the upper list, filled in from its column list.)
    /// <summary>The headings of the upper list, filled in from its column list.</summary>
    layPartsHeader: TLayout;

    //** @abstract(One row per part loaded.)
    /// <summary>One row per part loaded.</summary>
    lstParts: TListBox;

    //** @abstract(Raises OnAddFiles.)
    //**
    //** @param(Sender The button.)
    /// <summary>Raises OnAddFiles.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnAddFilesClick(Sender: TObject);

    //** @abstract(Raises OnClearList.)
    //**
    //** @param(Sender The button.)
    /// <summary>Raises OnClearList.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnClearListClick(Sender: TObject);

    //** @abstract(Raises OnApply.)
    //**
    //** @param(Sender The button.)
    /// <summary>Raises OnApply.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnApplyClick(Sender: TObject);

    //** @abstract(Raises OnRemove.)
    //**
    //** @param(Sender The button.)
    /// <summary>Raises OnRemove.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnRemoveClick(Sender: TObject);

    //** @abstract(Raises OnRefreshModel.)
    //**
    //** @param(Sender The button.)
    /// <summary>Raises OnRefreshModel.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnRefreshClick(Sender: TObject);

    //** @abstract(Shows the Covers columns for the new settings; the model follows with "Use on the model" or the next change.)
    //**
    //** @param(Sender The setting changed.)
    /// <summary>Shows the Covers columns for the new settings; the model follows with "Use on the model" or the next change.</summary>
    /// <param name="Sender">The setting changed.</param>
    procedure SettingsChange(Sender: TObject);

    //** @abstract(Lays out the headings of the upper list again.)
    //**
    //** @param(Sender The heading row.)
    /// <summary>Lays out the headings of the upper list again.</summary>
    /// <param name="Sender">The heading row.</param>
    procedure layPartsHeaderResize(Sender: TObject);

    //** @abstract(Lays out the headings of the lower list again.)
    //**
    //** @param(Sender The heading row.)
    /// <summary>Lays out the headings of the lower list again.</summary>
    /// <param name="Sender">The heading row.</param>
    procedure layAppliedHeaderResize(Sender: TObject);

    //** @abstract(Keeps the headings above the cells of the upper list.)
    //**
    //** @param(Sender The list.)
    //**
    //** @param(Canvas The canvas painted on.)
    //**
    //** @param(ARect The area painted.)
    /// <summary>Keeps the headings above the cells of the upper list.</summary>
    /// <param name="Sender">The list.</param>
    /// <param name="Canvas">The canvas painted on.</param>
    /// <param name="ARect">The area painted.</param>
    procedure lstPartsPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);

    //** @abstract(Keeps the headings above the cells of the lower list.)
    //**
    //** @param(Sender The list.)
    //**
    //** @param(Canvas The canvas painted on.)
    //**
    //** @param(ARect The area painted.)
    /// <summary>Keeps the headings above the cells of the lower list.</summary>
    /// <param name="Sender">The list.</param>
    /// <param name="Canvas">The canvas painted on.</param>
    /// <param name="ARect">The area painted.</param>
    procedure lstAppliedPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  private
    FDoc: TglTFDocument;
    FApplier: TglTFPartApplier;
    FLibrary: TglTFPartLibrary;
    FPartChecks: TList<TCheckBox>;
    FAppliedChecks: TList<TCheckBox>;
    FApplied: TArray<TglTFAppliedPart>;
    FUpdating: Boolean;
    FPartColumns: TColumnDefs;
    FAppliedColumns: TColumnDefs;
    FOnAddFiles: TNotifyEvent;
    FOnClearList: TNotifyEvent;
    FOnApply: TNotifyEvent;
    FOnRemove: TNotifyEvent;
    FOnRefreshModel: TNotifyEvent;
    procedure PartRowResize(Sender: TObject);
    procedure AppliedRowResize(Sender: TObject);
    procedure AddPartRow(AIndex: Integer; APart: TglTFPart; const AOptions: TglTFPartOptions);
    procedure AddAppliedRow(const AItem: TglTFAppliedPart);
    procedure CheckChange(Sender: TObject);
    procedure DoEvent(const AEvent: TNotifyEvent);
    procedure UpdateButtons;
    procedure ApplyWidth;
  protected
    //** @abstract(Lays the rows out again for the new width.)
    /// <summary>Lays the rows out again for the new width.</summary>
    procedure Resize; override;
  public
    //** @abstract(Creates the frame with empty lists.)
    //**
    //** @param(AOwner Owner of the frame.)
    /// <summary>Creates the frame with empty lists.</summary>
    /// <param name="AOwner">Owner of the frame.</param>
    constructor Create(AOwner: TComponent); override;

    //** @abstract(Frees the frame and its rows.)
    /// <summary>Frees the frame and its rows.</summary>
    destructor Destroy; override;

    //** @abstract(Shows the parts on a model.)
    //**
    //** The frame keeps references to both but owns neither; call Bind@(nil, nil@) before
    //** freeing them.
    //**
    //** @param(ADoc The model; nil when none is loaded.)
    //**
    //** @param(AApplier The applier for that model; nil with ADoc.)
    /// <summary>Shows the parts on a model.</summary>
    /// <param name="ADoc">The model; nil when none is loaded.</param>
    /// <param name="AApplier">The applier for that model; nil with ADoc.</param>
    /// <remarks>The frame keeps references to both but owns neither; call Bind(nil, nil)
    /// before freeing them.</remarks>
    procedure Bind(ADoc: TglTFDocument; AApplier: TglTFPartApplier);

    //** @abstract(Rebuilds both lists from the library and the model.)
    //**
    //** Call it after part files were loaded and after parts were put on or taken off. The
    //** ticks of the parts loaded are kept as long as the library has the same number of
    //** parts.
    /// <summary>Rebuilds both lists from the library and the model.</summary>
    /// <remarks>Call it after part files were loaded and after parts were put on or taken off.
    /// The ticks of the parts loaded are kept as long as the library has the same number of
    /// parts.</remarks>
    procedure RefreshList;

    //** @abstract(Unticks every part loaded.)
    /// <summary>Unticks every part loaded.</summary>
    procedure UntickParts;

    //** @abstract(Returns the settings chosen in the settings row.)
    //**
    //** @returns(The defaults with CoverGap and KeepBones as shown.)
    /// <summary>Returns the settings chosen in the settings row.</summary>
    /// <returns>The defaults with CoverGap and KeepBones as shown.</returns>
    function Options: TglTFPartOptions;

    //** @abstract(Returns the parts loaded that are ticked, in list order.)
    //**
    //** @returns(The parts; owned by the library, so valid until it is cleared. Empty when
    //** none is ticked or no library is set.)
    /// <summary>Returns the parts loaded that are ticked, in list order.</summary>
    /// <returns>The parts; owned by the library, so valid until it is cleared. Empty when none
    /// is ticked or no library is set.</returns>
    function TickedParts: TArray<TglTFPart>;

    //** @abstract(Returns the node indices of the parts on the model that are ticked.)
    //**
    //** @returns(Indices in the model's @code(Root.Nodes), as the list was last refreshed; empty
    //** when none is ticked.)
    /// <summary>Returns the node indices of the parts on the model that are ticked.</summary>
    /// <returns>Indices in the model's <c>Root.Nodes</c>, as the list was last refreshed; empty
    /// when none is ticked.</returns>
    function TickedApplied: TArray<Integer>;

    //** @abstract(The parts loaded, shown in the upper list; not owned.)
    /// <summary>The parts loaded, shown in the upper list; not owned.</summary>
    property PartLibrary: TglTFPartLibrary read FLibrary write FLibrary;

    //** @abstract(Occurs when the user clicks "Add part files...".)
    /// <summary>Occurs when the user clicks "Add part files...".</summary>
    property OnAddFiles: TNotifyEvent read FOnAddFiles write FOnAddFiles;

    //** @abstract(Occurs when the user clicks "Clear list".)
    /// <summary>Occurs when the user clicks "Clear list".</summary>
    property OnClearList: TNotifyEvent read FOnClearList write FOnClearList;

    //** @abstract(Occurs when the user clicks "Put on ticked parts"; see TickedParts.)
    /// <summary>Occurs when the user clicks "Put on ticked parts"; see TickedParts.</summary>
    property OnApply: TNotifyEvent read FOnApply write FOnApply;

    //** @abstract(Occurs when the user clicks "Take off ticked parts"; see TickedApplied.)
    /// <summary>Occurs when the user clicks "Take off ticked parts"; see
    /// TickedApplied.</summary>
    property OnRemove: TNotifyEvent read FOnRemove write FOnRemove;

    //** @abstract(Occurs when the user clicks "Use on the model"; see Options.)
    /// <summary>Occurs when the user clicks "Use on the model"; see Options.</summary>
    property OnRefreshModel: TNotifyEvent read FOnRefreshModel write FOnRefreshModel;
  end;

implementation

{$R *.fmx}

const
  ROW_HEIGHT = 26;

  // Upper list columns, in display order; Part takes the rest
  PCOL_USE = 0;
  PCOL_PART = 1;
  PCOL_FILE = 2;
  PCOL_TRIANGLES = 3;
  PCOL_COVERS = 4;
  PCOL_STATUS = 5;

  // Lower list columns
  ACOL_REMOVE = 0;
  ACOL_NODE = 1;
  ACOL_PART = 2;
  ACOL_FROM = 3;
  ACOL_TRIANGLES = 4;
  ACOL_COVERS = 5;

  // Below these frame widths (phones in portrait) some columns are hidden
  NARROW_WIDTH = 700;
  VERY_NARROW_WIDTH = 480;

{ TglTFPartsFrame }

constructor TglTFPartsFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPartChecks := TList<TCheckBox>.Create;
  FAppliedChecks := TList<TCheckBox>.Create;
  FPartColumns := [
    TColumnDef.Create('Use', 48, chNever, True),
    TColumnDef.Create('Part', 0),
    TColumnDef.Create('File', 170, chNarrow),
    TColumnDef.Create('Triangles', 80, chVeryNarrow),
    TColumnDef.Create('Covers', 230),
    TColumnDef.Create('Status', 150, chNarrow)];
  FAppliedColumns := [
    TColumnDef.Create('Take off', 64, chNever, True),
    TColumnDef.Create('Node', 50, chVeryNarrow),
    TColumnDef.Create('Part', 0),
    TColumnDef.Create('From', 170, chNarrow),
    TColumnDef.Create('Triangles', 80, chVeryNarrow),
    TColumnDef.Create('Covers', 230)];
  // The library's defaults
  FUpdating := True;
  try
    spnGap.Value := Round(100 * TglTFPartOptions.Default.CoverGap);
    edtKeep.Text := string.Join(', ', TglTFPartOptions.Default.KeepBones);
  finally
    FUpdating := False;
  end;
  // The headings come from the same lists as the rows' cells, so they match
  TColumnLayout.AddHeadings(layPartsHeader, FPartColumns);
  TColumnLayout.AddHeadings(layAppliedHeader, FAppliedColumns);
  Bind(nil, nil);
end;

destructor TglTFPartsFrame.Destroy;
begin
  FAppliedChecks.Free;
  FPartChecks.Free;
  inherited;
end;

procedure TglTFPartsFrame.lstPartsPainting(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  // The headings follow the rows, whose room the list's border and scroll
  // bar reduce
  if TColumnLayout.AlignHeader(layPartsHeader, lstParts) then
    PartRowResize(layPartsHeader);
end;

procedure TglTFPartsFrame.lstAppliedPainting(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  if TColumnLayout.AlignHeader(layAppliedHeader, lstApplied) then
    AppliedRowResize(layAppliedHeader);
end;

procedure TglTFPartsFrame.layPartsHeaderResize(Sender: TObject);
begin
  PartRowResize(layPartsHeader);
end;

procedure TglTFPartsFrame.layAppliedHeaderResize(Sender: TObject);
begin
  AppliedRowResize(layAppliedHeader);
end;

procedure TglTFPartsFrame.PartRowResize(Sender: TObject);
begin
  TColumnLayout.LayoutRow(Sender as TControl, FPartColumns, Width, NARROW_WIDTH, VERY_NARROW_WIDTH);
end;

procedure TglTFPartsFrame.AppliedRowResize(Sender: TObject);
begin
  TColumnLayout.LayoutRow(Sender as TControl, FAppliedColumns, Width, NARROW_WIDTH, VERY_NARROW_WIDTH);
end;

procedure TglTFPartsFrame.AddPartRow(AIndex: Integer; APart: TglTFPart;
  const AOptions: TglTFPartOptions);
var
  LItem: TListBoxItem;
  LCheck: TCheckBox;
  LUsable: Boolean;
  LStatus: string;
begin
  LUsable := APart.Error = '';
  LItem := TListBoxItem.Create(lstParts);
  LItem.Parent := lstParts;
  LItem.Height := ROW_HEIGHT;
  LItem.Text := '';
  LItem.Padding.Rect := TRectF.Create(TColumnLayout.RowPadding, 0, TColumnLayout.RowPadding, 0);
  LItem.Tag := AIndex;
  if not LUsable then
    LItem.Hint := APart.Error;
  LItem.ShowHint := not LUsable;

  LCheck := TColumnLayout.AddCheck(LItem, PCOL_USE);
  LCheck.Tag := AIndex;
  LCheck.Enabled := LUsable;
  LCheck.OnChange := CheckChange;
  FPartChecks.Add(LCheck);

  if LUsable then
    LStatus := 'ready'
  else
    LStatus := APart.Error;
  TColumnLayout.AddText(LItem, PCOL_PART, APart.Name, not LUsable);
  TColumnLayout.AddText(LItem, PCOL_FILE, ExtractFileName(APart.FileName), not LUsable);
  TColumnLayout.AddText(LItem, PCOL_TRIANGLES, IntToStr(APart.TriangleCount), not LUsable);
  TColumnLayout.AddText(LItem, PCOL_COVERS, APart.CoveredText(AOptions), not LUsable);
  TColumnLayout.AddText(LItem, PCOL_STATUS, LStatus, not LUsable);

  LItem.OnResize := PartRowResize;
  PartRowResize(LItem);
end;

procedure TglTFPartsFrame.AddAppliedRow(const AItem: TglTFAppliedPart);
var
  LItem: TListBoxItem;
  LCheck: TCheckBox;
begin
  LItem := TListBoxItem.Create(lstApplied);
  LItem.Parent := lstApplied;
  LItem.Height := ROW_HEIGHT;
  LItem.Text := '';
  LItem.Padding.Rect := TRectF.Create(TColumnLayout.RowPadding, 0, TColumnLayout.RowPadding, 0);
  LItem.Tag := AItem.NodeIndex;

  LCheck := TColumnLayout.AddCheck(LItem, ACOL_REMOVE);
  LCheck.Tag := AItem.NodeIndex;
  LCheck.OnChange := CheckChange;
  FAppliedChecks.Add(LCheck);

  TColumnLayout.AddText(LItem, ACOL_NODE, IntToStr(AItem.NodeIndex));
  TColumnLayout.AddText(LItem, ACOL_PART, AItem.Name);
  TColumnLayout.AddText(LItem, ACOL_FROM, AItem.FileName);
  TColumnLayout.AddText(LItem, ACOL_TRIANGLES, IntToStr(AItem.TriangleCount));
  TColumnLayout.AddText(LItem, ACOL_COVERS, AItem.CoveredText);

  LItem.OnResize := AppliedRowResize;
  AppliedRowResize(LItem);
end;

procedure TglTFPartsFrame.Bind(ADoc: TglTFDocument; AApplier: TglTFPartApplier);
begin
  FDoc := ADoc;
  FApplier := AApplier;
  RefreshList;
end;

procedure TglTFPartsFrame.RefreshList;
var
  LOptions: TglTFPartOptions;
  LTicked: TArray<Boolean>;
  LItem: TglTFAppliedPart;
  I: Integer;
begin
  LOptions := Options;

  // The ticks are kept while the list is the same length: settings changes
  // rebuild the rows, and nothing else reorders the library
  LTicked := nil;
  if Assigned(FLibrary) and (FPartChecks.Count = FLibrary.Count) then
  begin
    SetLength(LTicked, FPartChecks.Count);
    for I := 0 to FPartChecks.Count - 1 do
      LTicked[I] := FPartChecks[I].IsChecked;
  end;

  FUpdating := True;
  try
    lstParts.BeginUpdate;
    try
      lstParts.Clear;
      FPartChecks.Clear;
      if Assigned(FLibrary) then
        for I := 0 to FLibrary.Count - 1 do
        begin
          AddPartRow(I, FLibrary[I], LOptions);
          if (I < Length(LTicked)) and FPartChecks[I].Enabled then
            FPartChecks[I].IsChecked := LTicked[I];
        end;
    finally
      lstParts.EndUpdate;
    end;

    lstApplied.BeginUpdate;
    try
      lstApplied.Clear;
      FAppliedChecks.Clear;
      if Assigned(FApplier) then
        FApplied := FApplier.AppliedParts(LOptions)
      else
        FApplied := nil;
      for LItem in FApplied do
        AddAppliedRow(LItem);
    finally
      lstApplied.EndUpdate;
    end;
  finally
    FUpdating := False;
  end;
  lblAppliedTitle.Text := Format('Parts on the model (%d)', [Length(FApplied)]);
  ApplyWidth;
  UpdateButtons;
end;

procedure TglTFPartsFrame.UntickParts;
var
  LCheck: TCheckBox;
begin
  FUpdating := True;
  try
    for LCheck in FPartChecks do
      LCheck.IsChecked := False;
  finally
    FUpdating := False;
  end;
  UpdateButtons;
end;

function TglTFPartsFrame.Options: TglTFPartOptions;
var
  LBones: TArray<string>;
  LBone: string;
begin
  Result := TglTFPartOptions.Default;
  if FPartColumns = nil then
    Exit; // asked while the frame is loaded
  Result.CoverGap := spnGap.Value / 100;
  Result.KeepBones := nil;
  LBones := edtKeep.Text.Split([',', ';']);
  for LBone in LBones do
    if Trim(LBone) <> '' then
      Result.KeepBones := Result.KeepBones + [Trim(LBone)];
end;

function TglTFPartsFrame.TickedParts: TArray<TglTFPart>;
var
  LCheck: TCheckBox;
begin
  Result := nil;
  if not Assigned(FLibrary) then
    Exit;
  for LCheck in FPartChecks do
    if LCheck.IsChecked and (LCheck.Tag >= 0) and (LCheck.Tag < FLibrary.Count) then
      Result := Result + [FLibrary[LCheck.Tag]];
end;

function TglTFPartsFrame.TickedApplied: TArray<Integer>;
var
  LCheck: TCheckBox;
begin
  Result := nil;
  for LCheck in FAppliedChecks do
    if LCheck.IsChecked then
      Result := Result + [LCheck.Tag];
end;

procedure TglTFPartsFrame.CheckChange(Sender: TObject);
begin
  if not FUpdating then
    UpdateButtons;
end;

procedure TglTFPartsFrame.SettingsChange(Sender: TObject);
begin
  // The Covers columns follow the settings at once; the model only with
  // "Use on the model" or the next change
  if not FUpdating and (FPartChecks <> nil) then
    RefreshList;
end;

procedure TglTFPartsFrame.DoEvent(const AEvent: TNotifyEvent);
begin
  if Assigned(AEvent) then
    AEvent(Self);
end;

procedure TglTFPartsFrame.btnAddFilesClick(Sender: TObject);
begin
  DoEvent(FOnAddFiles);
end;

procedure TglTFPartsFrame.btnClearListClick(Sender: TObject);
begin
  DoEvent(FOnClearList);
end;

procedure TglTFPartsFrame.btnApplyClick(Sender: TObject);
begin
  DoEvent(FOnApply);
end;

procedure TglTFPartsFrame.btnRemoveClick(Sender: TObject);
begin
  DoEvent(FOnRemove);
end;

procedure TglTFPartsFrame.btnRefreshClick(Sender: TObject);
begin
  DoEvent(FOnRefreshModel);
end;

procedure TglTFPartsFrame.UpdateButtons;
var
  LLoaded: Boolean;
  LParts, LUsable, LTicked, LApplied: Integer;
  LCheck: TCheckBox;
begin
  LLoaded := Assigned(FDoc) and (FDoc.FileFormat <> gffNone);
  LParts := 0;
  if Assigned(FLibrary) then
    LParts := FLibrary.Count;
  LUsable := 0;
  LTicked := 0;
  for LCheck in FPartChecks do
  begin
    if LCheck.Enabled then
      Inc(LUsable);
    if LCheck.IsChecked then
      Inc(LTicked);
  end;
  LApplied := 0;
  for LCheck in FAppliedChecks do
    if LCheck.IsChecked then
      Inc(LApplied);

  if LParts = 0 then
    lblSummary.Text := 'No part files loaded; add some, such as the pieces of an outfit pack'
  else
    lblSummary.Text := Format('%d part(s), %d usable; %d ticked', [LParts, LUsable, LTicked]);
  btnClearList.Enabled := LParts > 0;
  btnApply.Enabled := LLoaded and (LTicked > 0);
  btnRemove.Enabled := LLoaded and (LApplied > 0);
  btnRefresh.Enabled := LLoaded and (Length(FApplied) > 0);
end;

procedure TglTFPartsFrame.Resize;
begin
  inherited;
  ApplyWidth;
end;

procedure TglTFPartsFrame.ApplyWidth;
var
  I: Integer;
begin
  if FPartColumns = nil then
    Exit; // Resize while the frame is loaded
  PartRowResize(layPartsHeader);
  for I := 0 to lstParts.Count - 1 do
    PartRowResize(lstParts.ListItems[I]);
  AppliedRowResize(layAppliedHeader);
  for I := 0 to lstApplied.Count - 1 do
    AppliedRowResize(lstApplied.ListItems[I]);
  // The summary needs the room the buttons leave
  lblSummary.Visible := Width >= 640;
end;

end.
