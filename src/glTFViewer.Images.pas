//** @abstract(The Images tab of the viewer: every image of a document, and how images are saved.)
//**
//** @link(TglTFImagesPanel) shows one row per image with the columns #, Name, Type, Source,
//** Size, Status and Used. Rows of images whose file is missing are shown in grey. Used tells
//** whether a mesh of the model shows the image, through a material and a texture @(see
//** @code(TglTFEdit.ImagesInUse)@); a save leaves out the images marked "No", such as those of
//** a part taken off.
//**
//** By default the format decides where the images go: a GLB stores every image inside it, a
//** glTF writes every image as a separate file next to it. Ticking "Alter image save mode"
//** shows a second, short list beside the first, with an Embed tick and the name of each image
//** that is saved, so that each image can be stored inside the file or as a separate file
//** instead; @link(TglTFImagesPanel.AlterSaveMode) tells the main form to save that way. The box
//** is unticked again for each document loaded.
//**
//** On narrow screens, such as phones in portrait, the Type and Source columns are hidden, and
//** Size too when narrower still, so the name stays readable.
//**
//** The panel is built in code, so the unit needs no .fmx file. Headings and rows are laid
//** out by glTFViewer.Columns, so the columns line up.
unit glTFViewer.Images;

{
  The Images tab of the viewer: every image of a document, and how images are
  saved.

  TglTFImagesPanel shows one row per image with the columns #, Name, Type,
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

  The panel is built in code, so the unit needs no .fmx file. Headings and rows
  are laid out by glTFViewer.Columns, so the columns line up.
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
  //** @abstract(Panel listing the images of a document, with an optional list to choose how
  //** each one is saved.)
  //**
  //** Place it on a tab with Align = Client and call @link(Bind) after each load. Must be used
  //** on the main thread.
  /// <summary>Panel listing the images of a document, with an optional list to choose how each
  /// one is saved.</summary>
  /// <remarks>Place it on a tab with Align = Client and call <see cref="Bind"/> after each
  /// load. Must be used on the main thread.</remarks>
  TglTFImagesPanel = class(TLayout)
  private
    FDoc: TglTFDocument;
    FSummary: TLabel;
    FAlter: TCheckBox;
    FBtnLocate: TButton;
    FHeader: TLayout;
    FList: TListBox;
    FEmbedPanel: TLayout;
    FEmbedSplitter: TSplitter;
    FEmbedHeader: TLayout;
    FEmbedList: TListBox;
    FUpdating: Boolean;
    // The Embed ticks were set to the starting choice for this document
    FAlterStarted: Boolean;
    // Parallel to the images: whether a mesh shows each one
    FUsed: TArray<Boolean>;
    FOnLocateMissing: TNotifyEvent;
    FColumns: TColumnDefs;
    FEmbedColumns: TColumnDefs;
    procedure BuildControls;
    function AddHeader(AParent: TFmxObject; const AColumns: TColumnDefs; AOrder: Single): TLayout;
    procedure ListPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure EmbedListPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure RowResize(Sender: TObject);
    procedure EmbedRowResize(Sender: TObject);
    procedure AddRow(AIndex: Integer; AImage: TglTFImage; AUsed: Boolean);
    procedure AddEmbedRow(AIndex: Integer; AImage: TglTFImage);
    function IsMissing(AImage: TglTFImage): Boolean;
    function GetAlterSaveMode: Boolean;
    procedure AlterChange(Sender: TObject);
    procedure EmbedChange(Sender: TObject);
    procedure LocateClick(Sender: TObject);
    procedure ShowEmbedList;
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

    //** @abstract(Shows the images of a document.)
    //**
    //** "Alter image save mode" is unticked again. The panel keeps a reference to ADoc but does
    //** not own it; call Bind@(nil@) before freeing the document.
    //**
    //** @param(ADoc The document to show; nil clears the list.)
    /// <summary>Shows the images of a document.</summary>
    /// <param name="ADoc">The document to show; nil clears the list.</param>
    /// <remarks>"Alter image save mode" is unticked again. The panel keeps a reference to ADoc
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
  end;

implementation

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

  // Below these panel widths (phones in portrait) some columns are hidden
  NARROW_WIDTH = 640;
  VERY_NARROW_WIDTH = 420;

  // Widest the list of Embed choices gets, and its share of narrow panels
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

{ TglTFImagesPanel }

constructor TglTFImagesPanel.Create(AOwner: TComponent);
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
  BuildControls;
  Bind(nil);
end;

function TglTFImagesPanel.AddHeader(AParent: TFmxObject; const AColumns: TColumnDefs;
  AOrder: Single): TLayout;
begin
  // Column headings, laid out like the rows
  Result := TLayout.Create(Self);
  Result.Parent := AParent;
  Result.Align := TAlignLayout.Top;
  Result.Height := ROW_HEIGHT;
  Result.Position.Y := AOrder;
  Result.Padding.Rect := TRectF.Create(TColumnLayout.RowPadding, 0, TColumnLayout.RowPadding, 0);
  TColumnLayout.AddHeadings(Result, AColumns);
end;

procedure TglTFImagesPanel.BuildControls;
var
  LBar: TLayout;
  LNote: TLabel;
begin
  // 1. Bar: the save mode box, Locate missing and the summary
  LBar := TLayout.Create(Self);
  LBar.Parent := Self;
  LBar.Align := TAlignLayout.Top;
  LBar.Height := 40;
  LBar.Padding.Rect := TRectF.Create(6, 6, 6, 6);

  FAlter := TCheckBox.Create(Self);
  FAlter.Parent := LBar;
  FAlter.Align := TAlignLayout.Left;
  FAlter.Width := 180;
  FAlter.Position.X := 0;
  FAlter.Text := 'Alter image save mode';
  FAlter.Hint := 'Choose for each image whether it is stored inside the saved file. Unticked, ' +
    'a GLB stores every image inside it and a glTF saves every image as a separate file';
  FAlter.ShowHint := True;
  FAlter.OnChange := AlterChange;

  FBtnLocate := TButton.Create(Self);
  FBtnLocate.Parent := LBar;
  FBtnLocate.Align := TAlignLayout.Left;
  FBtnLocate.Margins.Left := 18;
  FBtnLocate.Width := 130;
  FBtnLocate.Position.X := 400;
  FBtnLocate.Text := 'Locate missing...';
  FBtnLocate.OnClick := LocateClick;

  FSummary := TLabel.Create(Self);
  FSummary.Parent := LBar;
  FSummary.Align := TAlignLayout.Client;
  FSummary.Margins.Left := 14;
  FSummary.TextSettings.WordWrap := False;
  FSummary.TextSettings.Trimming := TTextTrimming.Character;

  // 2. The Embed choices, on the right, shown only while the box is ticked
  FEmbedPanel := TLayout.Create(Self);
  FEmbedPanel.Parent := Self;
  FEmbedPanel.Align := TAlignLayout.Right;
  FEmbedPanel.Position.X := 10000;
  FEmbedPanel.Width := EMBED_WIDTH;
  FEmbedPanel.Visible := False;
  FEmbedSplitter := TSplitter.Create(Self);
  FEmbedSplitter.Parent := Self;
  FEmbedSplitter.Align := TAlignLayout.Right;
  FEmbedSplitter.Position.X := 9000; // left of the panel
  FEmbedSplitter.Width := 6;
  FEmbedSplitter.Visible := False;

  LNote := TLabel.Create(Self);
  LNote.Parent := FEmbedPanel;
  LNote.Align := TAlignLayout.Top;
  LNote.Height := 40;
  LNote.Margins.Rect := TRectF.Create(6, 2, 6, 2);
  LNote.TextSettings.WordWrap := True;
  LNote.Text := 'Ticked: stored inside the saved file. Unticked: saved as a separate file ' +
    'next to it. Only the images that are saved are listed.';
  FEmbedHeader := AddHeader(FEmbedPanel, FEmbedColumns, 100);
  FEmbedHeader.OnResize := EmbedRowResize;
  FEmbedList := TListBox.Create(Self);
  FEmbedList.Parent := FEmbedPanel;
  FEmbedList.Align := TAlignLayout.Client;
  FEmbedList.ItemHeight := ROW_HEIGHT;
  FEmbedList.OnPainting := EmbedListPainting;

  // 3. Every image, taking the rest
  FHeader := AddHeader(Self, FColumns, 100);
  FHeader.OnResize := RowResize;
  FList := TListBox.Create(Self);
  FList.Parent := Self;
  FList.Align := TAlignLayout.Client;
  FList.ItemHeight := ROW_HEIGHT;
  FList.OnPainting := ListPainting;
end;

procedure TglTFImagesPanel.ListPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  // The headings follow the rows, whose room the list's border and scroll
  // bar reduce
  if TColumnLayout.AlignHeader(FHeader, FList) then
    RowResize(FHeader);
end;

procedure TglTFImagesPanel.EmbedListPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  if TColumnLayout.AlignHeader(FEmbedHeader, FEmbedList) then
    EmbedRowResize(FEmbedHeader);
end;

procedure TglTFImagesPanel.RowResize(Sender: TObject);
begin
  if FList = nil then
    Exit; // the heading resized during construction
  TColumnLayout.LayoutRow(Sender as TControl, FColumns, FList.Width, NARROW_WIDTH, VERY_NARROW_WIDTH);
end;

procedure TglTFImagesPanel.EmbedRowResize(Sender: TObject);
begin
  // Two columns only: nothing to hide
  TColumnLayout.LayoutRow(Sender as TControl, FEmbedColumns, FEmbedPanel.Width, 0, 0);
end;

function TglTFImagesPanel.IsMissing(AImage: TglTFImage): Boolean;
begin
  Result := AImage.Data = nil;
end;

function TglTFImagesPanel.GetAlterSaveMode: Boolean;
begin
  Result := FAlter.IsChecked;
end;

procedure TglTFImagesPanel.AddRow(AIndex: Integer; AImage: TglTFImage; AUsed: Boolean);
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

  LItem := TListBoxItem.Create(FList);
  LItem.Parent := FList;
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

procedure TglTFImagesPanel.AddEmbedRow(AIndex: Integer; AImage: TglTFImage);
var
  LItem: TListBoxItem;
  LCheck: TCheckBox;
begin
  LItem := TListBoxItem.Create(FEmbedList);
  LItem.Parent := FEmbedList;
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

procedure TglTFImagesPanel.Bind(ADoc: TglTFDocument);
begin
  FDoc := ADoc;
  // Normally unticked: each document starts saving by format
  FUpdating := True;
  try
    FAlter.IsChecked := False;
  finally
    FUpdating := False;
  end;
  FAlterStarted := False;
  RefreshList;
end;

procedure TglTFImagesPanel.RefreshList;
var
  I: Integer;
begin
  FUpdating := True;
  try
    FList.BeginUpdate;
    try
      FList.Clear;
      if Assigned(FDoc) then
      begin
        FUsed := TglTFEdit.ImagesInUse(FDoc.Root);
        for I := 0 to FDoc.Root.Images.Count - 1 do
          AddRow(I, FDoc.Root.Images[I], FUsed[I]);
      end
      else
        FUsed := nil;
    finally
      FList.EndUpdate;
    end;

    // The Embed choices: the images that are saved, those a mesh shows
    FEmbedList.BeginUpdate;
    try
      FEmbedList.Clear;
      if Assigned(FDoc) and FAlter.IsChecked then
        for I := 0 to FDoc.Root.Images.Count - 1 do
          if FUsed[I] then
            AddEmbedRow(I, FDoc.Root.Images[I]);
    finally
      FEmbedList.EndUpdate;
    end;
  finally
    FUpdating := False;
  end;
  ShowEmbedList;
  ApplyWidth;
  UpdateSummary;
end;

procedure TglTFImagesPanel.ShowEmbedList;
begin
  FEmbedPanel.Visible := FAlter.IsChecked;
  FEmbedSplitter.Visible := FAlter.IsChecked;
end;

procedure TglTFImagesPanel.AlterChange(Sender: TObject);
var
  LImage: TglTFImage;
begin
  if FUpdating then
    Exit;
  // The first time for this document, every image starts ticked, as a GLB,
  // the format suggested when saving, would store it; later the choices
  // made are kept
  if FAlter.IsChecked and not FAlterStarted and Assigned(FDoc) then
  begin
    for LImage in FDoc.Root.Images do
      LImage.Embed := True;
    FAlterStarted := True;
  end;
  RefreshList;
end;

procedure TglTFImagesPanel.EmbedChange(Sender: TObject);
var
  LCheck: TCheckBox;
begin
  if FUpdating or not Assigned(FDoc) then
    Exit;
  LCheck := Sender as TCheckBox;
  if (LCheck.Tag >= 0) and (LCheck.Tag < FDoc.Root.Images.Count) then
    FDoc.Root.Images[LCheck.Tag].Embed := LCheck.IsChecked;
  UpdateSummary;
end;

procedure TglTFImagesPanel.Resize;
begin
  inherited;
  ApplyWidth;
end;

procedure TglTFImagesPanel.ApplyWidth;
var
  I: Integer;
begin
  if (FHeader = nil) or (FList = nil) or (FEmbedPanel = nil) or (FEmbedList = nil) then
    Exit; // Resize during construction
  // The Embed choices take at most their share of a narrow panel
  FEmbedPanel.Width := Min(EMBED_WIDTH, Max(160, Width * EMBED_SHARE));
  RowResize(FHeader);
  for I := 0 to FList.Count - 1 do
    RowResize(FList.ListItems[I]);
  EmbedRowResize(FEmbedHeader);
  for I := 0 to FEmbedList.Count - 1 do
    EmbedRowResize(FEmbedList.ListItems[I]);
end;

procedure TglTFImagesPanel.UpdateSummary;
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
    if FAlter.IsChecked then
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
  FSummary.Text := LText;

  FAlter.Enabled := LCount > 0;
  FBtnLocate.Enabled := Assigned(FDoc) and FDoc.HasMissingResources;
end;

procedure TglTFImagesPanel.LocateClick(Sender: TObject);
begin
  if Assigned(FOnLocateMissing) then
    FOnLocateMissing(Self);
end;

end.
