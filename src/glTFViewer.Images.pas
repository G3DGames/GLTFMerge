//** @abstract(The Images tab of the viewer: every image of a document, and how images are saved.)
//**
//** @link(TglTFImagesFrame) shows one row per image with the columns #, Name, Type, Source,
//** Size, Status and Used. Rows of images whose file is missing are shown in grey. Used tells
//** whether a mesh of the model shows the image, through a material and a texture @(see
//** @code(TglTFEdit.ImagesInUse)@); a save leaves out the images marked "No", such as those of
//** a part taken off.
//**
//** By default the format decides where the images go: a GLB stores every image inside it, a
//** glTF writes every image as a separate file next to it. Ticking "Alter image save mode"
//** shows a second, short list beside the first, with an Embed tick and the name of each image
//** that is saved, so that each image can be stored inside the file or as a separate file
//** instead; @link(TglTFImagesFrame.AlterSaveMode) tells the main form to save that way. The box
//** is unticked again for each document loaded.
//**
//** On narrow screens, such as phones in portrait, the Type and Source columns are hidden, and
//** Size too when narrower still, so the name stays readable.
//**
//** The frame is designed in glTFViewer.Images.fmx. The headings and the rows follow the
//** column lists in the code and are laid out by glTFViewer.Columns, so the columns line up.
unit glTFViewer.Images;

{
  The Images tab of the viewer: every image of a document, and how images are
  saved.

  TglTFImagesFrame shows one row per image with the columns #, Name, Type,
  Source, Size, Status and Used. Rows of images whose file is missing are shown
  in grey. Used tells whether a mesh of the model shows the image, through a
  material and a texture (see TglTFEdit.ImagesInUse); a save leaves out the
  images marked "No", such as those of a part taken off.

  By default the format decides where the images go: a GLB stores every image
  inside it, a glTF writes every image as a separate file next to it. Ticking
  "Alter image save mode" shows a second, short list beside the first, with an
  Embed tick and the name of each image that is saved, so that each image can
  be stored inside the file or as a separate file instead; AlterSaveMode tells
  the main form to save that way. The box is unticked again for each document
  loaded.

  On narrow screens, such as phones in portrait, the Type and Source columns
  are hidden, and Size too when narrower still, so the name stays readable.

  The frame is designed in glTFViewer.Images.fmx. The headings and the rows
  follow the column lists in the code and are laid out by glTFViewer.Columns,
  so the columns line up.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Layouts, FMX.ListBox,
  FMX.Graphics, FMX.Controls.Presentation,

  glTF.Classes, glTF.Document,
  glTFViewer.Columns;

type
  //** @abstract(Frame listing the images of a document, with an optional list to choose how
  //** each one is saved.)
  //**
  //** Place it on a tab with Align = Client and call @link(Bind) after each load. Must be used
  //** on the main thread.
  /// <summary>Frame listing the images of a document, with an optional list to choose how each
  /// one is saved.</summary>
  /// <remarks>Place it on a tab with Align = Client and call <see cref="Bind"/> after each
  /// load. Must be used on the main thread.</remarks>
  TglTFImagesFrame = class(TFrame)
    //** @abstract(The bar with the save mode box, Locate missing and the summary.)
    /// <summary>The bar with the save mode box, Locate missing and the summary.</summary>
    layBar: TLayout;

    //** @abstract("Alter image save mode": shows the list of Embed choices.)
    /// <summary>"Alter image save mode": shows the list of Embed choices.</summary>
    chkAlter: TCheckBox;

    //** @abstract(Raises OnLocateMissing; enabled while files are missing.)
    /// <summary>Raises OnLocateMissing; enabled while files are missing.</summary>
    btnLocate: TButton;

    //** @abstract(How many images are saved, and how.)
    /// <summary>How many images are saved, and how.</summary>
    lblSummary: TLabel;

    //** @abstract(Separates the Embed choices from the list of images.)
    /// <summary>Separates the Embed choices from the list of images.</summary>
    splEmbed: TSplitter;

    //** @abstract(The Embed choices, on the right, shown while chkAlter is ticked.)
    /// <summary>The Embed choices, on the right, shown while chkAlter is ticked.</summary>
    layEmbed: TLayout;

    //** @abstract(What a tick in the Embed list means.)
    /// <summary>What a tick in the Embed list means.</summary>
    lblEmbedNote: TLabel;

    //** @abstract(The headings of the Embed list, filled in from its column list.)
    /// <summary>The headings of the Embed list, filled in from its column list.</summary>
    layEmbedHeader: TLayout;

    //** @abstract(One row per image that is saved, with its Embed tick.)
    /// <summary>One row per image that is saved, with its Embed tick.</summary>
    lstEmbed: TListBox;

    //** @abstract(The headings of the list of images, filled in from its column list.)
    /// <summary>The headings of the list of images, filled in from its column list.</summary>
    layHeader: TLayout;

    //** @abstract(One row per image.)
    /// <summary>One row per image.</summary>
    lstImages: TListBox;

    //** @abstract(Shows or hides the Embed choices.)
    //**
    //** The first time for a document, every image starts ticked, as a GLB would store it.
    //**
    //** @param(Sender The checkbox.)
    /// <summary>Shows or hides the Embed choices.</summary>
    /// <param name="Sender">The checkbox.</param>
    /// <remarks>The first time for a document, every image starts ticked, as a GLB would store
    /// it.</remarks>
    procedure chkAlterChange(Sender: TObject);

    //** @abstract(Raises OnLocateMissing.)
    //**
    //** @param(Sender The button.)
    /// <summary>Raises OnLocateMissing.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnLocateClick(Sender: TObject);

    //** @abstract(Lays out the headings of the list of images again.)
    //**
    //** @param(Sender The heading row.)
    /// <summary>Lays out the headings of the list of images again.</summary>
    /// <param name="Sender">The heading row.</param>
    procedure layHeaderResize(Sender: TObject);

    //** @abstract(Lays out the headings of the Embed list again.)
    //**
    //** @param(Sender The heading row.)
    /// <summary>Lays out the headings of the Embed list again.</summary>
    /// <param name="Sender">The heading row.</param>
    procedure layEmbedHeaderResize(Sender: TObject);

    //** @abstract(Keeps the headings above the cells of the images.)
    //**
    //** @param(Sender The list.)
    //**
    //** @param(Canvas The canvas painted on.)
    //**
    //** @param(ARect The area painted.)
    /// <summary>Keeps the headings above the cells of the images.</summary>
    /// <param name="Sender">The list.</param>
    /// <param name="Canvas">The canvas painted on.</param>
    /// <param name="ARect">The area painted.</param>
    procedure lstImagesPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);

    //** @abstract(Keeps the headings above the cells of the Embed list.)
    //**
    //** @param(Sender The list.)
    //**
    //** @param(Canvas The canvas painted on.)
    //**
    //** @param(ARect The area painted.)
    /// <summary>Keeps the headings above the cells of the Embed list.</summary>
    /// <param name="Sender">The list.</param>
    /// <param name="Canvas">The canvas painted on.</param>
    /// <param name="ARect">The area painted.</param>
    procedure lstEmbedPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  private
    FDoc: TglTFDocument;
    FUpdating: Boolean;
    // The Embed ticks were set to the starting choice for this document
    FAlterStarted: Boolean;
    // Parallel to the images: whether a mesh shows each one
    FUsed: TArray<Boolean>;
    FOnLocateMissing: TNotifyEvent;
    FOnChange: TNotifyEvent;
    FColumns: TColumnDefs;
    FEmbedColumns: TColumnDefs;
    procedure RowResize(Sender: TObject);
    procedure EmbedRowResize(Sender: TObject);
    procedure AddRow(AIndex: Integer; AImage: TglTFImage; AUsed: Boolean);
    procedure AddEmbedRow(AIndex: Integer; AImage: TglTFImage);
    function IsMissing(AImage: TglTFImage): Boolean;
    function GetAlterSaveMode: Boolean;
    procedure EmbedChange(Sender: TObject);
    procedure Changed;
    procedure ShowEmbedList;
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

    //** @abstract(Shows the images of a document.)
    //**
    //** "Alter image save mode" is unticked again. The frame keeps a reference to ADoc but does
    //** not own it; call Bind@(nil@) before freeing the document.
    //**
    //** @param(ADoc The document to show; nil clears the list.)
    /// <summary>Shows the images of a document.</summary>
    /// <param name="ADoc">The document to show; nil clears the list.</param>
    /// <remarks>"Alter image save mode" is unticked again. The frame keeps a reference to ADoc
    /// but does not own it; call Bind(nil) before freeing the document.</remarks>
    procedure Bind(ADoc: TglTFDocument);

    //** @abstract(Rebuilds the rows from the current document.)
    //**
    //** Call it after the document changes, for example after missing files were located or
    //** parts were put on or taken off; the Used column is worked out again. The state of
    //** "Alter image save mode" is kept.
    /// <summary>Rebuilds the rows from the current document.</summary>
    /// <remarks>Call it after the document changes, for example after missing files were
    /// located or parts were put on or taken off; the Used column is worked out again. The
    /// state of "Alter image save mode" is kept.</remarks>
    procedure RefreshList;

    //** @abstract(Whether "Alter image save mode" is ticked: each image's Embed tick then
    //** decides how it is saved, instead of the format.)
    /// <summary>Whether "Alter image save mode" is ticked: each image's Embed tick then decides
    /// how it is saved, instead of the format.</summary>
    property AlterSaveMode: Boolean read GetAlterSaveMode;

    //** @abstract(Occurs when the user clicks "Locate missing...".)
    //**
    //** The handler is expected to let the user find the files and then call
    //** @link(RefreshList).
    /// <summary>Occurs when the user clicks "Locate missing...".</summary>
    /// <remarks>The handler is expected to let the user find the files and then call
    /// <see cref="RefreshList"/>.</remarks>
    property OnLocateMissing: TNotifyEvent read FOnLocateMissing write FOnLocateMissing;
    //** @abstract(Occurs when the user changes what a save writes: "Alter image save mode" or an Embed tick.)
    /// <summary>Occurs when the user changes what a save writes: "Alter image save mode" or an Embed tick.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

{$R *.fmx}

uses
  glTF.Edit;

const
  ROW_HEIGHT = 26;

  // Columns, in display order (see TColumnLayout); Name takes the rest
  COL_INDEX = 0;
  COL_NAME = 1;
  COL_TYPE = 2;
  COL_SOURCE = 3;
  COL_SIZE = 4;
  COL_STATUS = 5;
  COL_USED = 6;

  // Columns of the list of Embed choices
  ECOL_EMBED = 0;
  ECOL_NAME = 1;

  // Below these frame widths (phones in portrait) some columns are hidden
  NARROW_WIDTH = 640;
  VERY_NARROW_WIDTH = 420;

  // Widest the list of Embed choices gets, and its share of narrow frames
  EMBED_WIDTH = 320;
  EMBED_SHARE = 0.45;

function SizeText(ABytes: Int64): string;
begin
  if ABytes < 1024 then
    Result := Format('%d B', [ABytes])
  else if ABytes < 1024 * 1024 then
    Result := Format('%.1f KB', [ABytes / 1024])
  else
    Result := Format('%.1f MB', [ABytes / (1024 * 1024)]);
end;

function DisplayName(AImage: TglTFImage): string;
var
  LPath: string;
begin
  if AImage.Name <> '' then
    Exit(AImage.Name);
  if (AImage.Uri <> '') and not AImage.IsDataUri then
  begin
    LPath := AImage.Uri.Replace('\', '/');
    Exit(LPath.Substring(LPath.LastIndexOf('/') + 1));
  end;
  Result := '(unnamed)';
end;

{ TglTFImagesFrame }

constructor TglTFImagesFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColumns := [
    TColumnDef.Create('#', 40),
    TColumnDef.Create('Name', 0),
    TColumnDef.Create('Type', 100, chNarrow),
    TColumnDef.Create('Source', 260, chNarrow),
    TColumnDef.Create('Size', 80, chVeryNarrow),
    TColumnDef.Create('Status', 110),
    TColumnDef.Create('Used', 56, chNever, True)];
  FEmbedColumns := [
    TColumnDef.Create('Embed', 64, chNever, True),
    TColumnDef.Create('Name', 0)];
  // The headings come from the same lists as the rows' cells, so they match
  TColumnLayout.AddHeadings(layHeader, FColumns);
  TColumnLayout.AddHeadings(layEmbedHeader, FEmbedColumns);
  Bind(nil);
end;

procedure TglTFImagesFrame.lstImagesPainting(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  // The headings follow the rows, whose room the list's border and scroll
  // bar reduce
  if TColumnLayout.AlignHeader(layHeader, lstImages) then
    RowResize(layHeader);
end;

procedure TglTFImagesFrame.lstEmbedPainting(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  if TColumnLayout.AlignHeader(layEmbedHeader, lstEmbed) then
    EmbedRowResize(layEmbedHeader);
end;

procedure TglTFImagesFrame.layHeaderResize(Sender: TObject);
begin
  RowResize(layHeader);
end;

procedure TglTFImagesFrame.layEmbedHeaderResize(Sender: TObject);
begin
  EmbedRowResize(layEmbedHeader);
end;

procedure TglTFImagesFrame.RowResize(Sender: TObject);
begin
  if FColumns = nil then
    Exit; // the heading resized while the frame is loaded
  TColumnLayout.LayoutRow(Sender as TControl, FColumns, lstImages.Width, NARROW_WIDTH,
    VERY_NARROW_WIDTH);
end;

procedure TglTFImagesFrame.EmbedRowResize(Sender: TObject);
begin
  if FEmbedColumns = nil then
    Exit; // the heading resized while the frame is loaded
  // Two columns only: nothing to hide
  TColumnLayout.LayoutRow(Sender as TControl, FEmbedColumns, layEmbed.Width, 0, 0);
end;

function TglTFImagesFrame.IsMissing(AImage: TglTFImage): Boolean;
begin
  Result := AImage.Data = nil;
end;

function TglTFImagesFrame.GetAlterSaveMode: Boolean;
begin
  Result := chkAlter.IsChecked;
end;

procedure TglTFImagesFrame.AddRow(AIndex: Integer; AImage: TglTFImage; AUsed: Boolean);
var
  LItem: TListBoxItem;
  LUsedLabel: TLabel;
  LMissing: Boolean;
  LSource, LStatus, LSize, LType: string;
begin
  LMissing := IsMissing(AImage);

  if AImage.BufferView <> GLTF_UNDEFINED_INDEX then
    LSource := Format('bufferView %d', [AImage.BufferView])
  else if AImage.IsDataUri then
    LSource := 'data URI'
  else
    LSource := AImage.Uri;

  if not LMissing then
  begin
    LStatus := 'OK';
    LSize := SizeText(Length(AImage.Data));
  end
  else
  begin
    if AImage.BufferView <> GLTF_UNDEFINED_INDEX then
      LStatus := 'Buffer missing'
    else
      LStatus := 'Missing';
    LSize := '-';
  end;

  LType := AImage.EffectiveMimeType;
  if LType = '' then
    LType := '?';

  LItem := TListBoxItem.Create(lstImages);
  LItem.Parent := lstImages;
  LItem.Height := ROW_HEIGHT;
  LItem.Text := '';
  LItem.Padding.Rect := TRectF.Create(TColumnLayout.RowPadding, 0, TColumnLayout.RowPadding, 0);
  LItem.Tag := AIndex;
  if LMissing and (AImage.Uri <> '') and not AImage.IsDataUri then
  begin
    LItem.Hint := 'Expected at ' + FDoc.ResolveUri(AImage.Uri);
    LItem.ShowHint := True;
  end;

  TColumnLayout.AddText(LItem, COL_INDEX, IntToStr(AIndex), LMissing);
  TColumnLayout.AddText(LItem, COL_NAME, DisplayName(AImage), LMissing);
  TColumnLayout.AddText(LItem, COL_TYPE, LType, LMissing);
  TColumnLayout.AddText(LItem, COL_SOURCE, LSource, LMissing);
  TColumnLayout.AddText(LItem, COL_SIZE, LSize, LMissing);
  TColumnLayout.AddText(LItem, COL_STATUS, LStatus, LMissing);
  if AUsed then
    TColumnLayout.AddText(LItem, COL_USED, 'Yes', LMissing, False, True)
  else
  begin
    // Grey, and why it will not be saved; the hint needs the cell to take
    // the mouse
    LUsedLabel := TColumnLayout.AddText(LItem, COL_USED, 'No', True, False, True);
    LUsedLabel.HitTest := True;
    LUsedLabel.Hint := 'No mesh shows this image: it is left out when saving';
    LUsedLabel.ShowHint := True;
  end;

  LItem.OnResize := RowResize;
  RowResize(LItem);
end;

procedure TglTFImagesFrame.AddEmbedRow(AIndex: Integer; AImage: TglTFImage);
var
  LItem: TListBoxItem;
  LCheck: TCheckBox;
begin
  LItem := TListBoxItem.Create(lstEmbed);
  LItem.Parent := lstEmbed;
  LItem.Height := ROW_HEIGHT;
  LItem.Text := '';
  LItem.Padding.Rect := TRectF.Create(TColumnLayout.RowPadding, 0, TColumnLayout.RowPadding, 0);
  LItem.Tag := AIndex;

  LCheck := TColumnLayout.AddCheck(LItem, ECOL_EMBED);
  LCheck.Tag := AIndex;
  LCheck.IsChecked := AImage.Embed;
  LCheck.OnChange := EmbedChange;
  TColumnLayout.AddText(LItem, ECOL_NAME, DisplayName(AImage), IsMissing(AImage));

  LItem.OnResize := EmbedRowResize;
  EmbedRowResize(LItem);
end;

procedure TglTFImagesFrame.Bind(ADoc: TglTFDocument);
begin
  FDoc := ADoc;
  // Normally unticked: each document starts saving by format
  FUpdating := True;
  try
    chkAlter.IsChecked := False;
  finally
    FUpdating := False;
  end;
  FAlterStarted := False;
  RefreshList;
end;

procedure TglTFImagesFrame.RefreshList;
var
  I: Integer;
begin
  FUpdating := True;
  try
    lstImages.BeginUpdate;
    try
      lstImages.Clear;
      if Assigned(FDoc) then
      begin
        FUsed := TglTFEdit.ImagesInUse(FDoc.Root);
        for I := 0 to FDoc.Root.Images.Count - 1 do
          AddRow(I, FDoc.Root.Images[I], FUsed[I]);
      end
      else
        FUsed := nil;
    finally
      lstImages.EndUpdate;
    end;

    // The Embed choices: the images that are saved, those a mesh shows
    lstEmbed.BeginUpdate;
    try
      lstEmbed.Clear;
      if Assigned(FDoc) and chkAlter.IsChecked then
        for I := 0 to FDoc.Root.Images.Count - 1 do
          if FUsed[I] then
            AddEmbedRow(I, FDoc.Root.Images[I]);
    finally
      lstEmbed.EndUpdate;
    end;
  finally
    FUpdating := False;
  end;
  ShowEmbedList;
  ApplyWidth;
  UpdateSummary;
end;

procedure TglTFImagesFrame.ShowEmbedList;
begin
  layEmbed.Visible := chkAlter.IsChecked;
  splEmbed.Visible := chkAlter.IsChecked;
end;

procedure TglTFImagesFrame.chkAlterChange(Sender: TObject);
var
  LImage: TglTFImage;
begin
  if FUpdating then
    Exit;
  // The first time for this document, every image starts ticked, as a GLB,
  // the format suggested when saving, would store it; later the choices
  // made are kept
  if chkAlter.IsChecked and not FAlterStarted and Assigned(FDoc) then
  begin
    for LImage in FDoc.Root.Images do
      LImage.Embed := True;
    FAlterStarted := True;
  end;
  RefreshList;
  Changed;
end;

procedure TglTFImagesFrame.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TglTFImagesFrame.EmbedChange(Sender: TObject);
var
  LCheck: TCheckBox;
begin
  if FUpdating or not Assigned(FDoc) then
    Exit;
  LCheck := Sender as TCheckBox;
  if (LCheck.Tag >= 0) and (LCheck.Tag < FDoc.Root.Images.Count) then
    FDoc.Root.Images[LCheck.Tag].Embed := LCheck.IsChecked;
  UpdateSummary;
  Changed;
end;

procedure TglTFImagesFrame.Resize;
begin
  inherited;
  ApplyWidth;
end;

procedure TglTFImagesFrame.ApplyWidth;
var
  I: Integer;
begin
  if FColumns = nil then
    Exit; // Resize while the frame is loaded
  // The Embed choices take at most their share of a narrow panel
  layEmbed.Width := Min(EMBED_WIDTH, Max(160, Width * EMBED_SHARE));
  RowResize(layHeader);
  for I := 0 to lstImages.Count - 1 do
    RowResize(lstImages.ListItems[I]);
  EmbedRowResize(layEmbedHeader);
  for I := 0 to lstEmbed.Count - 1 do
    EmbedRowResize(lstEmbed.ListItems[I]);
end;

procedure TglTFImagesFrame.UpdateSummary;
var
  LImage: TglTFImage;
  LEmbed, LMissing, LCount, LUsed, I: Integer;
  LText: string;
begin
  // The images that are saved are those used
  LCount := 0;
  LUsed := 0;
  LEmbed := 0;
  LMissing := 0;
  if Assigned(FDoc) then
    for I := 0 to FDoc.Root.Images.Count - 1 do
    begin
      LImage := FDoc.Root.Images[I];
      Inc(LCount);
      if IsMissing(LImage) then
        Inc(LMissing);
      if (I < Length(FUsed)) and not FUsed[I] then
        Continue;
      Inc(LUsed);
      if LImage.Embed then
        Inc(LEmbed);
    end;

  if not Assigned(FDoc) or (FDoc.FileFormat = gffNone) then
    LText := 'No file loaded'
  else if LCount = 0 then
    LText := 'This file has no images'
  else
  begin
    if chkAlter.IsChecked then
      LText := Format('%d image(s) saved: %d inside the file, %d as separate files',
        [LUsed, LEmbed, LUsed - LEmbed])
    else
      LText := Format('%d image(s) saved: inside the file as GLB, as separate files as glTF',
        [LUsed]);
    if LMissing > 0 then
      LText := LText + Format('; %d missing', [LMissing]);
    if LCount > LUsed then
      LText := LText + Format('; %d not used, left out', [LCount - LUsed]);
  end;
  lblSummary.Text := LText;

  chkAlter.Enabled := LCount > 0;
  btnLocate.Enabled := Assigned(FDoc) and FDoc.HasMissingResources;
end;

procedure TglTFImagesFrame.btnLocateClick(Sender: TObject);
begin
  if Assigned(FOnLocateMissing) then
    FOnLocateMissing(Self);
end;

end.
