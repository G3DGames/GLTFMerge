//** @abstract(The Split tab of the viewer: the models a file holds, each to be saved as a file
//** of its own.)
//**
//** @link(TglTFSplitModelsFrame) lists the models TglTFModelSplitter finds: one per root node
//** of the default scene, with everything under it. The columns are #, Name, Nodes, Meshes,
//** Triangles, Size and Origin. Name is the file name the model gets, its root node's name or
//** model_NNN; Size is its size along X, Y and Z as saved; Origin says whether the model keeps
//** its origin or is moved so that its centre is its origin.
//**
//** "Scale up small models", ticked by default, scales every model by one factor when any is
//** under 1 unit along any axis, so that the smallest size becomes 1 unit; the summary gives
//** the factor.
//**
//** "Save as" chooses GLB, the default, or glTF. "Split" raises
//** @link(TglTFSplitModelsFrame.OnSplit); the main form asks for the output folder and saves
//** the models there, a model whose name is taken by a file already there getting a
//** sequential suffix.
//**
//** On narrow screens the Nodes and Meshes columns are hidden, and Triangles too when narrower
//** still. The frame is designed in glTFViewer.SplitModels.fmx; the headings and the rows
//** follow the column list in the code and are laid out by glTFViewer.Columns.
unit glTFViewer.SplitModels;

{
  The Split tab of the viewer: the models a file holds, each to be saved as a
  file of its own.

  TglTFSplitModelsFrame lists the models TglTFModelSplitter finds: one per
  root node of the default scene, with everything under it. The columns are
  #, Name, Nodes, Meshes, Triangles, Size and Origin. Name is the file name
  the model gets, its root node's name or model_NNN; Size is its size along
  X, Y and Z as saved; Origin says whether the model keeps its origin or is
  moved so that its centre is its origin.

  "Scale up small models", ticked by default, scales every model by one
  factor when any is under 1 unit along any axis, so that the smallest size
  becomes 1 unit; the summary gives the factor.

  "Save as" chooses GLB, the default, or glTF. "Split" raises OnSplit; the
  main form asks for the output folder and saves the models there, a model
  whose name is taken by a file already there getting a sequential suffix.

  On narrow screens the Nodes and Meshes columns are hidden, and Triangles too
  when narrower still. The frame is designed in glTFViewer.SplitModels.fmx;
  the headings and the rows follow the column list in the code and are laid
  out by glTFViewer.Columns.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Layouts, FMX.ListBox,
  FMX.Graphics, FMX.Controls.Presentation,

  glTF.Document, glTF.ModelSplit,
  glTFViewer.Columns;

type
  //** @abstract(Frame listing the models a document holds, to save each as a file of its
  //** own.)
  //**
  //** Place it on a tab with Align = Client and call @link(Bind) after each load and
  //** @link(RefreshList) after the nodes change. Must be used on the main thread.
  /// <summary>Frame listing the models a document holds, to save each as a file of its
  /// own.</summary>
  /// <remarks>Place it on a tab with Align = Client and call <see cref="Bind"/> after each
  /// load and <see cref="RefreshList"/> after the nodes change. Must be used on the main
  /// thread.</remarks>
  TglTFSplitModelsFrame = class(TFrame)
    //** @abstract(The bar with Split, the format and the summary, at the top.)
    /// <summary>The bar with Split, the format and the summary, at the top.</summary>
    layBar: TLayout;

    //** @abstract(Raises OnSplit; enabled while there are models.)
    /// <summary>Raises OnSplit; enabled while there are models.</summary>
    btnSplit: TButton;

    //** @abstract(The caption of the format.)
    /// <summary>The caption of the format.</summary>
    lblFormat: TLabel;

    //** @abstract(Save the models as .glb, the default.)
    /// <summary>Save the models as .glb, the default.</summary>
    rbGLB: TRadioButton;

    //** @abstract(Save the models as .gltf, with separate files.)
    /// <summary>Save the models as .gltf, with separate files.</summary>
    rbGLTF: TRadioButton;

    //** @abstract("Scale up small models": scale every model so the smallest size is 1 unit.)
    /// <summary>"Scale up small models": scale every model so the smallest size is 1
    /// unit.</summary>
    chkScaleUp: TCheckBox;

    //** @abstract(How many models there are and how many are moved to their centre.)
    /// <summary>How many models there are and how many are moved to their centre.</summary>
    lblSummary: TLabel;

    //** @abstract(The column headings, filled in from the column list.)
    /// <summary>The column headings, filled in from the column list.</summary>
    layHeader: TLayout;

    //** @abstract(One row per model.)
    /// <summary>One row per model.</summary>
    lstModels: TListBox;

    //** @abstract(Raises OnSplit.)
    //**
    //** @param(Sender The button.)
    /// <summary>Raises OnSplit.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnSplitClick(Sender: TObject);

    //** @abstract(Lists the models again, with their sizes as the box now says.)
    //**
    //** @param(Sender The checkbox.)
    /// <summary>Lists the models again, with their sizes as the box now says.</summary>
    /// <param name="Sender">The checkbox.</param>
    procedure chkScaleUpChange(Sender: TObject);

    //** @abstract(Lays out the headings again when their width changes.)
    //**
    //** @param(Sender The heading row.)
    /// <summary>Lays out the headings again when their width changes.</summary>
    /// <param name="Sender">The heading row.</param>
    procedure layHeaderResize(Sender: TObject);

    //** @abstract(Keeps the headings above the cells of the rows.)
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
    procedure lstModelsPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  private
    FDoc: TglTFDocument;
    FCount: Integer;
    FOnSplit: TNotifyEvent;
    FColumns: TColumnDefs;
    procedure RowResize(Sender: TObject);
    procedure LayoutRow(ARow: TControl);
    procedure AddRow(AIndex: Integer; const AModel: TglTFSplitModel; AScale: Double);
    function GetOutputFormat: TglTFFileFormat;
    function GetScaleUp: Boolean;
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

    //** @abstract(Shows the models of a document.)
    //**
    //** The frame keeps a reference to ADoc but does not own it; call Bind@(nil@) before
    //** freeing the document.
    //**
    //** @param(ADoc The document to show; nil clears the list.)
    /// <summary>Shows the models of a document.</summary>
    /// <param name="ADoc">The document to show; nil clears the list.</param>
    /// <remarks>The frame keeps a reference to ADoc but does not own it; call Bind(nil) before
    /// freeing the document.</remarks>
    procedure Bind(ADoc: TglTFDocument);

    //** @abstract(Finds the models of the current document again and rebuilds the rows.)
    /// <summary>Finds the models of the current document again and rebuilds the
    /// rows.</summary>
    procedure RefreshList;

    //** @abstract(The format chosen: gffGLB or gffJSON.)
    /// <summary>The format chosen: gffGLB or gffJSON.</summary>
    property OutputFormat: TglTFFileFormat read GetOutputFormat;

    //** @abstract(Whether "Scale up small models" is ticked.)
    /// <summary>Whether "Scale up small models" is ticked.</summary>
    property ScaleUp: Boolean read GetScaleUp;

    //** @abstract(The number of models listed.)
    /// <summary>The number of models listed.</summary>
    property ModelCount: Integer read FCount;

    //** @abstract(Occurs when the user clicks "Split".)
    //**
    //** The handler is expected to ask for the output folder and save the models there with
    //** TglTFModelSplitter, in @link(OutputFormat).
    /// <summary>Occurs when the user clicks "Split".</summary>
    /// <remarks>The handler is expected to ask for the output folder and save the models there
    /// with TglTFModelSplitter, in <see cref="OutputFormat"/>.</remarks>
    property OnSplit: TNotifyEvent read FOnSplit write FOnSplit;
  end;

implementation

{$R *.fmx}

const
  ROW_HEIGHT = 26;

  // Columns, in display order (see TColumnLayout); Name takes the rest
  COL_INDEX = 0;
  COL_NAME = 1;
  COL_NODES = 2;
  COL_MESHES = 3;
  COL_TRIANGLES = 4;
  COL_SIZE = 5;
  COL_ORIGIN = 6;

  // Below these frame widths (phones in portrait) some columns are hidden
  NARROW_WIDTH = 600;
  VERY_NARROW_WIDTH = 420;

{ TglTFSplitModelsFrame }

constructor TglTFSplitModelsFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColumns := [
    TColumnDef.Create('#', 50),
    TColumnDef.Create('Name', 0),
    TColumnDef.Create('Nodes', 70, chNarrow),
    TColumnDef.Create('Meshes', 70, chNarrow),
    TColumnDef.Create('Triangles', 90, chVeryNarrow),
    TColumnDef.Create('Size', 170, chNarrow),
    TColumnDef.Create('Origin', 170)];
  // The headings come from the same list as the rows' cells, so they match
  TColumnLayout.AddHeadings(layHeader, FColumns);
  Bind(nil);
end;

procedure TglTFSplitModelsFrame.lstModelsPainting(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  if TColumnLayout.AlignHeader(layHeader, lstModels) then
    LayoutRow(layHeader);
end;

procedure TglTFSplitModelsFrame.LayoutRow(ARow: TControl);
begin
  TColumnLayout.LayoutRow(ARow, FColumns, Width, NARROW_WIDTH, VERY_NARROW_WIDTH);
end;

procedure TglTFSplitModelsFrame.RowResize(Sender: TObject);
begin
  LayoutRow(Sender as TControl);
end;

procedure TglTFSplitModelsFrame.layHeaderResize(Sender: TObject);
begin
  LayoutRow(layHeader);
end;

function TglTFSplitModelsFrame.GetOutputFormat: TglTFFileFormat;
begin
  if rbGLTF.IsChecked then
    Result := gffJSON
  else
    Result := gffGLB;
end;

// A size for the list: 3 significant digits, as 2.75 or 0.00204
function SizeText(AValue: Double): string;
begin
  Result := FormatFloat('0.###', AValue);
  if (AValue <> 0) and (Abs(AValue) < 0.01) then
    Result := FloatToStrF(AValue, ffGeneral, 3, 0);
end;

function TglTFSplitModelsFrame.GetScaleUp: Boolean;
begin
  Result := chkScaleUp.IsChecked;
end;

procedure TglTFSplitModelsFrame.chkScaleUpChange(Sender: TObject);
begin
  if FColumns <> nil then // nil while the frame is loaded
    RefreshList;
end;

procedure TglTFSplitModelsFrame.AddRow(AIndex: Integer; const AModel: TglTFSplitModel;
  AScale: Double);
var
  LItem: TListBoxItem;
  LOrigin, LSize: string;
begin
  LItem := TListBoxItem.Create(lstModels);
  LItem.Parent := lstModels;
  LItem.Height := ROW_HEIGHT;
  LItem.Text := '';
  LItem.Padding.Rect := TRectF.Create(TColumnLayout.RowPadding, 0, TColumnLayout.RowPadding, 0);
  LItem.Tag := AIndex;

  if not AModel.HasBounds then
    LOrigin := 'kept (no geometry)'
  else if AModel.Recentre then
    LOrigin := 'moved to its centre'
  else
    LOrigin := 'kept';
  TColumnLayout.AddText(LItem, COL_INDEX, IntToStr(AIndex + 1));
  TColumnLayout.AddText(LItem, COL_NAME, AModel.Name);
  TColumnLayout.AddText(LItem, COL_NODES, IntToStr(Length(AModel.Nodes)));
  TColumnLayout.AddText(LItem, COL_MESHES, IntToStr(AModel.MeshNodes));
  TColumnLayout.AddText(LItem, COL_TRIANGLES, IntToStr(AModel.Triangles));
  if AModel.HasBounds then
    LSize := Format('%s x %s x %s', [SizeText(AScale * AModel.Size[0]),
      SizeText(AScale * AModel.Size[1]), SizeText(AScale * AModel.Size[2])])
  else
    LSize := '-';
  TColumnLayout.AddText(LItem, COL_SIZE, LSize);
  TColumnLayout.AddText(LItem, COL_ORIGIN, LOrigin);

  LItem.OnResize := RowResize;
  LayoutRow(LItem);
end;

procedure TglTFSplitModelsFrame.Bind(ADoc: TglTFDocument);
begin
  FDoc := ADoc;
  RefreshList;
end;

procedure TglTFSplitModelsFrame.RefreshList;
var
  LSplitter: TglTFModelSplitter;
  LModels: TArray<TglTFSplitModel>;
  LMoved, I: Integer;
  LLoaded: Boolean;
  LScale: Double;
begin
  LModels := nil;
  LScale := 1;
  LLoaded := Assigned(FDoc) and (FDoc.FileFormat <> gffNone);
  if LLoaded then
  begin
    LSplitter := TglTFModelSplitter.Create(FDoc);
    try
      try
        LSplitter.ScaleUp := chkScaleUp.IsChecked;
        LSplitter.FindModels;
        LModels := LSplitter.Models;
        LScale := LSplitter.Scale;
      except
        // A broken node tree: nothing to list
        LModels := nil;
      end;
    finally
      LSplitter.Free;
    end;
  end;

  lstModels.BeginUpdate;
  try
    lstModels.Clear;
    for I := 0 to High(LModels) do
      AddRow(I, LModels[I], LScale);
  finally
    lstModels.EndUpdate;
  end;
  FCount := Length(LModels);
  ApplyWidth;

  LMoved := 0;
  for I := 0 to High(LModels) do
    if LModels[I].Recentre then
      Inc(LMoved);
  if not LLoaded then
    lblSummary.Text := 'No file loaded'
  else if FCount = 0 then
    lblSummary.Text := 'No models: the default scene has no nodes'
  else if FCount = 1 then
    lblSummary.Text := 'One model: splitting saves it on its own'
  else
    lblSummary.Text := Format('%d models; %d moved so their centre is their origin',
      [FCount, LMoved]);
  if (FCount > 0) and not SameValue(LScale, 1) then
    lblSummary.Text := lblSummary.Text + Format('; all scaled by %s', [SizeText(LScale)]);
  btnSplit.Enabled := FCount > 0;
end;

procedure TglTFSplitModelsFrame.Resize;
begin
  inherited;
  ApplyWidth;
end;

procedure TglTFSplitModelsFrame.ApplyWidth;
var
  I: Integer;
begin
  if FColumns = nil then
    Exit; // Resize while the frame is loaded
  LayoutRow(layHeader);
  for I := 0 to lstModels.Count - 1 do
    LayoutRow(lstModels.ListItems[I]);
end;

procedure TglTFSplitModelsFrame.btnSplitClick(Sender: TObject);
begin
  if Assigned(FOnSplit) then
    FOnSplit(Self);
end;

end.
