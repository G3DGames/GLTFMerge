//** @abstract(The Parts tab of the viewer: body parts and outfit pieces to put on the model, and
//** those on it.)
//**
//** @link(TglTFPartsPanel) has two lists. The upper one, "Parts loaded", shows every part found
//** in the part files loaded @(see glTF.Parts@), one row each with the columns Use, Part,
//** File, Triangles, Covers and Status; Covers lists the bones the part covers with their
//** shares. The lower one, "Parts on the model", shows the parts put on the model, with the
//** columns Take off, Node, Part, From, Triangles and Covers.
//**
//** "Add part files..." raises @link(TglTFPartsPanel.OnAddFiles), "Put on ticked parts"
//** @link(TglTFPartsPanel.OnApply) and "Take off ticked parts" @link(TglTFPartsPanel.OnRemove);
//** the main form does the work and then calls RefreshList. The settings row decides how
//** much of the body is hidden under the parts: how close a part's surface must come to the
//** skin, as a share of the body's height, and the bones never hidden. "Use on the model"
//** hides the body again with them, through @link(TglTFPartsPanel.OnRefreshModel); otherwise
//** they apply from the next change.
//**
//** On narrow screens the File and From columns are hidden, and Triangles too when narrower
//** still. The panel is built in code, so the unit needs no .fmx file; headings and rows are
//** laid out by glTFViewer.Columns, so the columns line up.
unit glTFViewer.Parts;

{
  The Parts tab of the viewer: body parts and outfit pieces to put on the
  model, and those on it.

  TglTFPartsPanel has two lists. The upper one, "Parts loaded", shows every
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
  when narrower still. The panel is built in code, so the unit needs no .fmx
  file; headings and rows are laid out by glTFViewer.Columns, so the columns
  line up.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.StdCtrls, FMX.Layouts, FMX.ListBox, FMX.Edit,
  FMX.SpinBox, FMX.EditBox, FMX.Graphics, FMX.Controls.Presentation,

  glTF.Classes, glTF.Document, glTF.Parts,
  glTFViewer.Columns;

type
  //** @abstract(Panel listing the parts loaded and the parts on the model.)
  //**
  //** Place it on a tab with Align = Client, set @link(PartLibrary) once, and call
  //** @link(Bind) after each load and @link(RefreshList) after each change. Must be used on
  //** the main thread.
  /// <summary>Panel listing the parts loaded and the parts on the model.</summary>
  /// <remarks>Place it on a tab with Align = Client, set <see cref="PartLibrary"/> once, and
  /// call <see cref="Bind"/> after each load and <see cref="RefreshList"/> after each change.
  /// Must be used on the main thread.</remarks>
  TglTFPartsPanel = class(TLayout)
  private
    FDoc: TglTFDocument;
    FApplier: TglTFPartApplier;
    FLibrary: TglTFPartLibrary;
    FSummary: TLabel;
    FBtnAdd: TButton;
    FBtnClear: TButton;
    FBtnApply: TButton;
    FBtnRemove: TButton;
    FBtnRefresh: TButton;
    FGap: TSpinBox;
    FKeep: TEdit;
    FPartsHeader: TLayout;
    FPartsList: TListBox;
    FAppliedHeader: TLayout;
    FAppliedList: TListBox;
    FAppliedTitle: TLabel;
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
    procedure BuildControls;
    function AddButton(AParent: TFmxObject; const AText: string; AWidth, AGap, AOrder: Single;
      AOnClick: TNotifyEvent): TButton;
    function AddLabel(AParent: TFmxObject; const AText: string; AAlign: TAlignLayout;
      AWidth, AOrder: Single): TLabel;
    function AddList(out AHeader: TLayout; const AColumns: TColumnDefs; AParent: TFmxObject;
      AOrder: Single): TListBox;
    procedure PartsPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure AppliedPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure PartRowResize(Sender: TObject);
    procedure AppliedRowResize(Sender: TObject);
    procedure AddPartRow(AIndex: Integer; APart: TglTFPart; const AOptions: TglTFPartOptions);
    procedure AddAppliedRow(const AItem: TglTFAppliedPart);
    procedure CheckChange(Sender: TObject);
    procedure SettingsChange(Sender: TObject);
    procedure ButtonClick(Sender: TObject);
    procedure UpdateButtons;
    procedure ApplyWidth;
  protected
    procedure Resize; override;
  public
    //** @abstract(Creates the panel with empty lists.)
    //**
    //** @param(AOwner Owner of the panel.)
    /// <summary>Creates the panel with empty lists.</summary>
    /// <param name="AOwner">Owner of the panel.</param>
    constructor Create(AOwner: TComponent); override;

    //** @abstract(Frees the panel and its rows.)
    /// <summary>Frees the panel and its rows.</summary>
    destructor Destroy; override;

    //** @abstract(Shows the parts on a model.)
    //**
    //** The panel keeps references to both but owns neither; call Bind@(nil, nil@) before
    //** freeing them.
    //**
    //** @param(ADoc The model; nil when none is loaded.)
    //**
    //** @param(AApplier The applier for that model; nil with ADoc.)
    /// <summary>Shows the parts on a model.</summary>
    /// <param name="ADoc">The model; nil when none is loaded.</param>
    /// <param name="AApplier">The applier for that model; nil with ADoc.</param>
    /// <remarks>The panel keeps references to both but owns neither; call Bind(nil, nil)
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

const
  ROW_HEIGHT = 26;
  APPLIED_HEIGHT = 230;

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

  // Below these panel widths (phones in portrait) some columns are hidden
  NARROW_WIDTH = 700;
  VERY_NARROW_WIDTH = 480;

  // Tags of the buttons, for ButtonClick
  TAG_ADD = 1;
  TAG_CLEAR = 2;
  TAG_APPLY = 3;
  TAG_REMOVE = 4;
  TAG_REFRESH = 5;

{ TglTFPartsPanel }

constructor TglTFPartsPanel.Create(AOwner: TComponent);
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
  BuildControls;
  Bind(nil, nil);
end;

destructor TglTFPartsPanel.Destroy;
begin
  FAppliedChecks.Free;
  FPartChecks.Free;
  inherited;
end;

function TglTFPartsPanel.AddButton(AParent: TFmxObject; const AText: string;
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

function TglTFPartsPanel.AddLabel(AParent: TFmxObject; const AText: string;
  AAlign: TAlignLayout; AWidth, AOrder: Single): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := AParent;
  Result.Align := AAlign;
  if AWidth > 0 then
    Result.Width := AWidth;
  Result.Position.X := AOrder;
  Result.Position.Y := AOrder;
  Result.Text := AText;
  Result.TextSettings.WordWrap := False;
  Result.TextSettings.Trimming := TTextTrimming.Character;
end;

function TglTFPartsPanel.AddList(out AHeader: TLayout; const AColumns: TColumnDefs;
  AParent: TFmxObject; AOrder: Single): TListBox;
begin
  // Column headings, laid out like the rows, above the list
  AHeader := TLayout.Create(Self);
  AHeader.Parent := AParent;
  AHeader.Align := TAlignLayout.Top;
  AHeader.Height := ROW_HEIGHT;
  AHeader.Position.Y := AOrder;
  AHeader.Padding.Rect := TRectF.Create(TColumnLayout.RowPadding, 0, TColumnLayout.RowPadding, 0);
  TColumnLayout.AddHeadings(AHeader, AColumns);

  Result := TListBox.Create(Self);
  Result.Parent := AParent;
  Result.Align := TAlignLayout.Client;
  Result.ItemHeight := ROW_HEIGHT;
end;

procedure TglTFPartsPanel.BuildControls;
var
  LBar, LSettings, LLower, LLowerBar: TLayout;
  LSplitter: TSplitter;
begin
  // 1. Buttons for the parts loaded
  LBar := TLayout.Create(Self);
  LBar.Parent := Self;
  LBar.Align := TAlignLayout.Top;
  LBar.Height := 40;
  LBar.Padding.Rect := TRectF.Create(6, 6, 6, 6);
  FBtnAdd := AddButton(LBar, 'Add part files...', 130, 0, 0, ButtonClick);
  FBtnAdd.Tag := TAG_ADD;
  FBtnClear := AddButton(LBar, 'Clear list', 90, 6, 200, ButtonClick);
  FBtnClear.Tag := TAG_CLEAR;
  FBtnApply := AddButton(LBar, 'Put on ticked parts', 150, 18, 400, ButtonClick);
  FBtnApply.Tag := TAG_APPLY;
  FSummary := AddLabel(LBar, '', TAlignLayout.Client, 0, 1000);
  FSummary.Margins.Left := 14;

  // 2. Settings: which bones a part covers
  LSettings := TLayout.Create(Self);
  LSettings.Parent := Self;
  LSettings.Align := TAlignLayout.Top;
  LSettings.Position.Y := 100;
  LSettings.Height := 36;
  LSettings.Padding.Rect := TRectF.Create(6, 4, 6, 4);
  AddLabel(LSettings, 'Hide the body where a part comes within', TAlignLayout.Left, 250, 0);
  FGap := TSpinBox.Create(Self);
  FGap.Parent := LSettings;
  FGap.Align := TAlignLayout.Left;
  FGap.Position.X := 100;
  FGap.Width := 90;
  FGap.Min := 0;
  FGap.Max := 20;
  FGap.Value := Round(100 * TglTFPartOptions.Default.CoverGap);
  FGap.Hint := 'As a share of the body''s height. Raise it for loose clothes if skin shows ' +
    'through; lower it if skin near a part goes missing';
  FGap.ShowHint := True;
  FGap.OnChange := SettingsChange;
  AddLabel(LSettings, '% of its height. Never hide:', TAlignLayout.Left, 175, 200).Margins.Left := 6;
  FKeep := TEdit.Create(Self);
  FKeep.Parent := LSettings;
  FKeep.Align := TAlignLayout.Left;
  FKeep.Position.X := 300;
  FKeep.Width := 160;
  FKeep.Text := string.Join(', ', TglTFPartOptions.Default.KeepBones);
  FKeep.TextPrompt := 'bone names, e.g. Head';
  FKeep.OnChange := SettingsChange;
  FBtnRefresh := AddButton(LSettings, 'Use on the model', 130, 8, 400, ButtonClick);
  FBtnRefresh.Tag := TAG_REFRESH;

  // 3. The parts on the model, at the bottom, below a splitter
  // Bottom-aligned controls stack by position: the larger Y goes lower
  LLower := TLayout.Create(Self);
  LLower.Parent := Self;
  LLower.Align := TAlignLayout.Bottom;
  LLower.Position.Y := 10000;
  LLower.Height := APPLIED_HEIGHT;
  LSplitter := TSplitter.Create(Self);
  LSplitter.Parent := Self;
  LSplitter.Align := TAlignLayout.Bottom;
  LSplitter.Position.Y := 9000;
  LSplitter.Height := 6;

  LLowerBar := TLayout.Create(Self);
  LLowerBar.Parent := LLower;
  LLowerBar.Align := TAlignLayout.Top;
  LLowerBar.Height := 40;
  LLowerBar.Padding.Rect := TRectF.Create(6, 6, 6, 6);
  FAppliedTitle := AddLabel(LLowerBar, 'Parts on the model', TAlignLayout.Left, 260, 0);
  FAppliedTitle.StyledSettings := FAppliedTitle.StyledSettings - [TStyledSetting.Style];
  FAppliedTitle.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBtnRemove := AddButton(LLowerBar, 'Take off ticked parts', 160, 12, 400, ButtonClick);
  FBtnRemove.Tag := TAG_REMOVE;
  FAppliedList := AddList(FAppliedHeader, FAppliedColumns, LLower, 100);
  FAppliedList.OnPainting := AppliedPainting;
  FAppliedHeader.OnResize := AppliedRowResize;

  // 4. The parts loaded, taking the rest
  FPartsList := AddList(FPartsHeader, FPartColumns, Self, 200);
  FPartsList.OnPainting := PartsPainting;
  FPartsHeader.OnResize := PartRowResize;
end;

procedure TglTFPartsPanel.PartsPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  // The headings follow the rows, whose room the list's border and scroll
  // bar reduce
  if TColumnLayout.AlignHeader(FPartsHeader, FPartsList) then
    PartRowResize(FPartsHeader);
end;

procedure TglTFPartsPanel.AppliedPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  if TColumnLayout.AlignHeader(FAppliedHeader, FAppliedList) then
    AppliedRowResize(FAppliedHeader);
end;

procedure TglTFPartsPanel.PartRowResize(Sender: TObject);
begin
  TColumnLayout.LayoutRow(Sender as TControl, FPartColumns, Width, NARROW_WIDTH, VERY_NARROW_WIDTH);
end;

procedure TglTFPartsPanel.AppliedRowResize(Sender: TObject);
begin
  TColumnLayout.LayoutRow(Sender as TControl, FAppliedColumns, Width, NARROW_WIDTH, VERY_NARROW_WIDTH);
end;

procedure TglTFPartsPanel.AddPartRow(AIndex: Integer; APart: TglTFPart;
  const AOptions: TglTFPartOptions);
var
  LItem: TListBoxItem;
  LCheck: TCheckBox;
  LUsable: Boolean;
  LStatus: string;
begin
  LUsable := APart.Error = '';
  LItem := TListBoxItem.Create(FPartsList);
  LItem.Parent := FPartsList;
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

procedure TglTFPartsPanel.AddAppliedRow(const AItem: TglTFAppliedPart);
var
  LItem: TListBoxItem;
  LCheck: TCheckBox;
begin
  LItem := TListBoxItem.Create(FAppliedList);
  LItem.Parent := FAppliedList;
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

procedure TglTFPartsPanel.Bind(ADoc: TglTFDocument; AApplier: TglTFPartApplier);
begin
  FDoc := ADoc;
  FApplier := AApplier;
  RefreshList;
end;

procedure TglTFPartsPanel.RefreshList;
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
    FPartsList.BeginUpdate;
    try
      FPartsList.Clear;
      FPartChecks.Clear;
      if Assigned(FLibrary) then
        for I := 0 to FLibrary.Count - 1 do
        begin
          AddPartRow(I, FLibrary[I], LOptions);
          if (I < Length(LTicked)) and FPartChecks[I].Enabled then
            FPartChecks[I].IsChecked := LTicked[I];
        end;
    finally
      FPartsList.EndUpdate;
    end;

    FAppliedList.BeginUpdate;
    try
      FAppliedList.Clear;
      FAppliedChecks.Clear;
      if Assigned(FApplier) then
        FApplied := FApplier.AppliedParts(LOptions)
      else
        FApplied := nil;
      for LItem in FApplied do
        AddAppliedRow(LItem);
    finally
      FAppliedList.EndUpdate;
    end;
  finally
    FUpdating := False;
  end;
  FAppliedTitle.Text := Format('Parts on the model (%d)', [Length(FApplied)]);
  ApplyWidth;
  UpdateButtons;
end;

procedure TglTFPartsPanel.UntickParts;
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

function TglTFPartsPanel.Options: TglTFPartOptions;
var
  LBones: TArray<string>;
  LBone: string;
begin
  Result := TglTFPartOptions.Default;
  if Assigned(FGap) then
    Result.CoverGap := FGap.Value / 100;
  if Assigned(FKeep) then
  begin
    Result.KeepBones := nil;
    LBones := FKeep.Text.Split([',', ';']);
    for LBone in LBones do
      if Trim(LBone) <> '' then
        Result.KeepBones := Result.KeepBones + [Trim(LBone)];
  end;
end;

function TglTFPartsPanel.TickedParts: TArray<TglTFPart>;
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

function TglTFPartsPanel.TickedApplied: TArray<Integer>;
var
  LCheck: TCheckBox;
begin
  Result := nil;
  for LCheck in FAppliedChecks do
    if LCheck.IsChecked then
      Result := Result + [LCheck.Tag];
end;

procedure TglTFPartsPanel.CheckChange(Sender: TObject);
begin
  if not FUpdating then
    UpdateButtons;
end;

procedure TglTFPartsPanel.SettingsChange(Sender: TObject);
begin
  // The Covers columns follow the settings at once; the model only with
  // "Use on the model" or the next change
  if not FUpdating then
    RefreshList;
end;

procedure TglTFPartsPanel.ButtonClick(Sender: TObject);
var
  LEvent: TNotifyEvent;
begin
  case (Sender as TComponent).Tag of
    TAG_ADD: LEvent := FOnAddFiles;
    TAG_CLEAR: LEvent := FOnClearList;
    TAG_APPLY: LEvent := FOnApply;
    TAG_REMOVE: LEvent := FOnRemove;
    TAG_REFRESH: LEvent := FOnRefreshModel;
  else
    LEvent := nil;
  end;
  if Assigned(LEvent) then
    LEvent(Self);
end;

procedure TglTFPartsPanel.UpdateButtons;
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
    FSummary.Text := 'No part files loaded; add some, such as the pieces of an outfit pack'
  else
    FSummary.Text := Format('%d part(s), %d usable; %d ticked', [LParts, LUsable, LTicked]);
  FBtnClear.Enabled := LParts > 0;
  FBtnApply.Enabled := LLoaded and (LTicked > 0);
  FBtnRemove.Enabled := LLoaded and (LApplied > 0);
  FBtnRefresh.Enabled := LLoaded and (Length(FApplied) > 0);
end;

procedure TglTFPartsPanel.Resize;
begin
  inherited;
  ApplyWidth;
end;

procedure TglTFPartsPanel.ApplyWidth;
var
  I: Integer;
begin
  if (FPartsHeader = nil) or (FPartsList = nil) or (FAppliedHeader = nil) or
     (FAppliedList = nil) or (FSummary = nil) then
    Exit; // Resize during construction
  PartRowResize(FPartsHeader);
  for I := 0 to FPartsList.Count - 1 do
    PartRowResize(FPartsList.ListItems[I]);
  AppliedRowResize(FAppliedHeader);
  for I := 0 to FAppliedList.Count - 1 do
    AppliedRowResize(FAppliedList.ListItems[I]);
  // The summary needs the room the buttons leave
  FSummary.Visible := Width >= 640;
end;

end.
