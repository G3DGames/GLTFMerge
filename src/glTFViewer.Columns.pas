//** @abstract(Column layout shared by the list frames of the viewer, so headings and rows line
//** up.)
//**
//** The Images and Animations tabs show a heading row above a list box whose rows hold one
//** control per column. Each frame describes its columns once, as an array of
//** @link(TColumnDef), and @link(TColumnLayout) places every cell, heading or row, at an x
//** position it computes itself from that array: columns appear exactly in array order, each
//** fixed column at its width, and the one column with no width takes what is left. Nothing
//** depends on FireMonkey's ordering of aligned controls.
//**
//** @link(TColumnLayout.AlignHeader) shifts the heading by the list box's own border and by
//** its vertical scroll bar when one is shown, which take room from the rows but not from the
//** heading. Columns can be marked to hide on narrow screens.
unit glTFViewer.Columns;

{
  Column layout shared by the list frames of the viewer, so headings and rows
  line up.

  The Images and Animations tabs show a heading row above a list box whose
  rows hold one control per column. Each frame describes its columns once, as
  an array of TColumnDef, and TColumnLayout places every cell, heading or
  row, at an x position it computes itself from that array: columns appear
  exactly in array order, each fixed column at its width, and the one column
  with no width takes what is left. Nothing depends on FireMonkey's ordering
  of aligned controls.

  TColumnLayout.AlignHeader shifts the heading by the list box's own border
  and by its vertical scroll bar when one is shown, which take room from the
  rows but not from the heading. Columns can be marked to hide on narrow
  screens.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  FMX.Types, FMX.Controls, FMX.StdCtrls, FMX.Layouts, FMX.ListBox, FMX.Graphics;

type
  //** @abstract(When a column is hidden.)
  /// <summary>When a column is hidden.</summary>
  TColumnHide = (
    //** @abstract(Always shown.)
    /// <summary>Always shown.</summary>
    chNever,

    //** @abstract(Hidden when the frame is narrower than its narrow width.)
    /// <summary>Hidden when the frame is narrower than its narrow width.</summary>
    chNarrow,

    //** @abstract(Hidden when the frame is narrower than its very narrow width.)
    /// <summary>Hidden when the frame is narrower than its very narrow width.</summary>
    chVeryNarrow);

  //** @abstract(One column of a list frame.)
  /// <summary>One column of a list frame.</summary>
  TColumnDef = record
    //** @abstract(The heading.)
    /// <summary>The heading.</summary>
    Title: string;

    //** @abstract(Width in pixels, including the space around the cell; 0 for the column
    //** that takes the remaining width.)
    /// <summary>Width in pixels, including the space around the cell; 0 for the column that
    /// takes the remaining width.</summary>
    Width: Single;

    //** @abstract(When the column is hidden.)
    /// <summary>When the column is hidden.</summary>
    Hide: TColumnHide;

    //** @abstract(Whether the heading is centred, as for a column of checkboxes.)
    /// <summary>Whether the heading is centred, as for a column of checkboxes.</summary>
    Centered: Boolean;

    //** @abstract(Returns a column description.)
    //**
    //** @param(ATitle The heading.)
    //**
    //** @param(AWidth Width in pixels; 0 for the column that takes the remaining width.)
    //**
    //** @param(AHide When the column is hidden.)
    //**
    //** @param(ACentered Whether the heading is centred.)
    //**
    //** @returns(The description.)
    /// <summary>Returns a column description.</summary>
    /// <param name="ATitle">The heading.</param>
    /// <param name="AWidth">Width in pixels; 0 for the column that takes the remaining
    /// width.</param>
    /// <param name="AHide">When the column is hidden.</param>
    /// <param name="ACentered">Whether the heading is centred.</param>
    /// <returns>The description.</returns>
    class function Create(const ATitle: string; AWidth: Single; AHide: TColumnHide = chNever;
      ACentered: Boolean = False): TColumnDef; static;
  end;

  //** @abstract(The columns of a list frame, in display order.)
  /// <summary>The columns of a list frame, in display order.</summary>
  TColumnDefs = TArray<TColumnDef>;

  //** @abstract(Creates heading and row cells and places them at computed positions.)
  //**
  //** All methods are class methods. Use them on the main thread. A row is any control that
  //** holds cells: the heading layout or a list box item.
  /// <summary>Creates heading and row cells and places them at computed positions.</summary>
  /// <remarks>All methods are class methods. Use them on the main thread. A row is any control
  /// that holds cells: the heading layout or a list box item.</remarks>
  TColumnLayout = class sealed
  public
    //** @abstract(Space left and right of every cell inside its column, in pixels.)
    /// <summary>Space left and right of every cell inside its column, in pixels.</summary>
    const CellMargin = 4;

    //** @abstract(Space left and right of the cells inside a row, in pixels.)
    /// <summary>Space left and right of the cells inside a row, in pixels.</summary>
    const RowPadding = 8;

    //** @abstract(Adds the headings of all columns to a heading row.)
    //**
    //** @param(AHeader The heading row.)
    //**
    //** @param(AColumns The columns.)
    /// <summary>Adds the headings of all columns to a heading row.</summary>
    /// <param name="AHeader">The heading row.</param>
    /// <param name="AColumns">The columns.</param>
    class procedure AddHeadings(AHeader: TControl; const AColumns: TColumnDefs); static;

    //** @abstract(Adds a text cell to a row.)
    //**
    //** @param(ARow The row; it owns the cell.)
    //**
    //** @param(AColumn Index of the column in the frame's TColumnDefs.)
    //**
    //** @param(AText The text; longer text is cut with an ellipsis.)
    //**
    //** @param(AGrey Grey text, for rows of missing items.)
    //**
    //** @param(ABold Bold text, for headings.)
    //**
    //** @param(ACentered Centred text.)
    //**
    //** @returns(The label.)
    /// <summary>Adds a text cell to a row.</summary>
    /// <param name="ARow">The row; it owns the cell.</param>
    /// <param name="AColumn">Index of the column in the frame's TColumnDefs.</param>
    /// <param name="AText">The text; longer text is cut with an ellipsis.</param>
    /// <param name="AGrey">Grey text, for rows of missing items.</param>
    /// <param name="ABold">Bold text, for headings.</param>
    /// <param name="ACentered">Centred text.</param>
    /// <returns>The label.</returns>
    class function AddText(ARow: TControl; AColumn: Integer; const AText: string;
      AGrey: Boolean = False; ABold: Boolean = False; ACentered: Boolean = False): TLabel; static;

    //** @abstract(Adds a checkbox cell to a row, the checkbox centred in its column.)
    //**
    //** @param(ARow The row; it owns the cell.)
    //**
    //** @param(AColumn Index of the column in the frame's TColumnDefs.)
    //**
    //** @returns(The checkbox, without text.)
    /// <summary>Adds a checkbox cell to a row, the checkbox centred in its column.</summary>
    /// <param name="ARow">The row; it owns the cell.</param>
    /// <param name="AColumn">Index of the column in the frame's TColumnDefs.</param>
    /// <returns>The checkbox, without text.</returns>
    class function AddCheck(ARow: TControl; AColumn: Integer): TCheckBox; static;

    //** @abstract(Places the cells of a row in their columns.)
    //**
    //** The cells go between the row's left and right padding: hidden columns take no room,
    //** fixed columns their width in array order, and the column with no width the rest,
    //** never less than 40 pixels. Each cell is as tall as the row. Call it when the row is
    //** created and whenever its width changes.
    //**
    //** @param(ARow The heading row or a list box item.)
    //**
    //** @param(AColumns The frame's columns.)
    //**
    //** @param(AFrameWidth The frame's width, which decides which columns are hidden.)
    //**
    //** @param(ANarrow Below this frame width chNarrow columns are hidden.)
    //**
    //** @param(AVeryNarrow Below this frame width chVeryNarrow columns are hidden too.)
    /// <summary>Places the cells of a row in their columns.</summary>
    /// <param name="ARow">The heading row or a list box item.</param>
    /// <param name="AColumns">The frame's columns.</param>
    /// <param name="AFrameWidth">The frame's width, which decides which columns are
    /// hidden.</param>
    /// <param name="ANarrow">Below this frame width chNarrow columns are hidden.</param>
    /// <param name="AVeryNarrow">Below this frame width chVeryNarrow columns are hidden
    /// too.</param>
    /// <remarks>The cells go between the row's left and right padding: hidden columns take no
    /// room, fixed columns their width in array order, and the column with no width the rest,
    /// never less than 40 pixels. Each cell is as tall as the row. Call it when the row is
    /// created and whenever its width changes.</remarks>
    class procedure LayoutRow(ARow: TControl; const AColumns: TColumnDefs;
      AFrameWidth, ANarrow, AVeryNarrow: Single); static;

    //** @abstract(Sets the heading's padding so its cells sit exactly above those of the
    //** rows.)
    //**
    //** Measures the first row against the heading, so the list box's border and its
    //** vertical scroll bar are allowed for. Does nothing while the list is empty. Changes
    //** the padding only when it differs, so it can be called whenever the list is painted;
    //** lay the heading out again when it returns True.
    //**
    //** @param(AHeader The heading, placed above the list box with the same width.)
    //**
    //** @param(AList The list box whose rows were filled with the same cells.)
    //**
    //** @returns(True when the padding was changed.)
    /// <summary>Sets the heading's padding so its cells sit exactly above those of the
    /// rows.</summary>
    /// <param name="AHeader">The heading, placed above the list box with the same
    /// width.</param>
    /// <param name="AList">The list box whose rows were filled with the same cells.</param>
    /// <returns>True when the padding was changed.</returns>
    /// <remarks>Measures the first row against the heading, so the list box's border and its
    /// vertical scroll bar are allowed for. Does nothing while the list is empty. Changes the
    /// padding only when it differs, so it can be called whenever the list is painted; lay the
    /// heading out again when it returns True.</remarks>
    class function AlignHeader(AHeader: TControl; AList: TListBox): Boolean; static;
  end;

implementation

const
  // Marks the controls that are cells; Tag holds the column index
  CELL_TAG = 'gltf.cell';

  // Width of the box of a checkbox without text
  CHECK_WIDTH = 20;
  CHECK_HEIGHT = 20;

  MIN_FILL_WIDTH = 40;

{ TColumnDef }

class function TColumnDef.Create(const ATitle: string; AWidth: Single; AHide: TColumnHide;
  ACentered: Boolean): TColumnDef;
begin
  Result.Title := ATitle;
  Result.Width := AWidth;
  Result.Hide := AHide;
  Result.Centered := ACentered;
end;

// Marks a control as the cell of a column; it is placed by LayoutRow only
procedure MarkCell(ACell: TControl; AColumn: Integer);
begin
  ACell.Align := TAlignLayout.None;
  ACell.TagString := CELL_TAG;
  ACell.Tag := AColumn;
  ACell.HitTest := False;
end;

{ TColumnLayout }

class procedure TColumnLayout.AddHeadings(AHeader: TControl; const AColumns: TColumnDefs);
var
  I: Integer;
begin
  for I := 0 to High(AColumns) do
    AddText(AHeader, I, AColumns[I].Title, False, True, AColumns[I].Centered);
end;

class function TColumnLayout.AddText(ARow: TControl; AColumn: Integer; const AText: string;
  AGrey, ABold, ACentered: Boolean): TLabel;
begin
  // Owned by its row, so a row's cells go with it
  Result := TLabel.Create(ARow);
  Result.Parent := ARow;
  MarkCell(Result, AColumn);
  Result.Text := AText;
  Result.StyledSettings := Result.StyledSettings - [TStyledSetting.Other];
  Result.TextSettings.Trimming := TTextTrimming.Character;
  Result.TextSettings.WordWrap := False;
  Result.TextSettings.VertAlign := TTextAlign.Center;
  if ACentered then
    Result.TextSettings.HorzAlign := TTextAlign.Center
  else
    Result.TextSettings.HorzAlign := TTextAlign.Leading;
  if AGrey then
  begin
    Result.StyledSettings := Result.StyledSettings - [TStyledSetting.FontColor];
    Result.TextSettings.FontColor := TAlphaColors.Gray;
  end;
  if ABold then
  begin
    Result.StyledSettings := Result.StyledSettings - [TStyledSetting.Style];
    Result.TextSettings.Font.Style := [TFontStyle.fsBold];
  end;
end;

class function TColumnLayout.AddCheck(ARow: TControl; AColumn: Integer): TCheckBox;
var
  LCell: TLayout;
begin
  // A cell like a text cell, with the checkbox centred in it, under the
  // centred heading
  LCell := TLayout.Create(ARow);
  LCell.Parent := ARow;
  MarkCell(LCell, AColumn);

  Result := TCheckBox.Create(LCell);
  Result.Parent := LCell;
  Result.Align := TAlignLayout.Center;
  Result.Width := CHECK_WIDTH;
  Result.Height := CHECK_HEIGHT;
  Result.Text := '';
end;

class procedure TColumnLayout.LayoutRow(ARow: TControl; const AColumns: TColumnDefs;
  AFrameWidth, ANarrow, AVeryNarrow: Single);
var
  LVisible: TArray<Boolean>;
  LLefts, LWidths: TArray<Single>;
  LFixed, LFill, X: Single;
  LControl: TControl;
  I: Integer;
begin
  if (ARow = nil) or (Length(AColumns) = 0) then
    Exit;

  // 1. Which columns show, and what the fixed ones take
  SetLength(LVisible, Length(AColumns));
  LFixed := 0;
  for I := 0 to High(AColumns) do
  begin
    case AColumns[I].Hide of
      chNarrow: LVisible[I] := AFrameWidth >= ANarrow;
      chVeryNarrow: LVisible[I] := AFrameWidth >= AVeryNarrow;
    else
      LVisible[I] := True;
    end;
    if LVisible[I] then
      LFixed := LFixed + AColumns[I].Width;
  end;
  LFill := Max(MIN_FILL_WIDTH, ARow.Width - ARow.Padding.Left - ARow.Padding.Right - LFixed);

  // 2. Each column's place, left to right in array order
  SetLength(LLefts, Length(AColumns));
  SetLength(LWidths, Length(AColumns));
  X := ARow.Padding.Left;
  for I := 0 to High(AColumns) do
  begin
    LLefts[I] := X;
    if not LVisible[I] then
      LWidths[I] := 0
    else if AColumns[I].Width > 0 then
      LWidths[I] := AColumns[I].Width
    else
      LWidths[I] := LFill;
    X := X + LWidths[I];
  end;

  // 3. The cells, inside their columns
  for LControl in ARow.Controls do
    if (LControl.TagString = CELL_TAG) and (LControl.Tag >= 0) and
       (LControl.Tag <= High(AColumns)) then
    begin
      I := LControl.Tag;
      LControl.Visible := LVisible[I];
      if LVisible[I] then
        LControl.SetBounds(LLefts[I] + CellMargin, 0,
          Max(0, LWidths[I] - 2 * CellMargin), ARow.Height);
    end;
end;

class function TColumnLayout.AlignHeader(AHeader: TControl; AList: TListBox): Boolean;
var
  LRow: TListBoxItem;
  LRowRect, LHeaderRect: TRectF;
  LLeft, LRight: Single;
begin
  Result := False;
  if (AHeader = nil) or (AList = nil) or (AList.Count = 0) then
    Exit;
  LRow := AList.ListItems[0];
  if (LRow = nil) or (LRow.Width <= 0) then
    Exit;

  // Where the row's cells start and end, in the heading's terms
  LRowRect := LRow.AbsoluteRect;
  LHeaderRect := AHeader.AbsoluteRect;
  LLeft := LRowRect.Left + LRow.Padding.Left - LHeaderRect.Left;
  LRight := LHeaderRect.Right - (LRowRect.Right - LRow.Padding.Right);
  if (LLeft < 0) or (LRight < 0) then
    Exit; // not laid out yet

  if (Abs(AHeader.Padding.Left - LLeft) > 0.5) or (Abs(AHeader.Padding.Right - LRight) > 0.5) then
  begin
    AHeader.Padding.Left := LLeft;
    AHeader.Padding.Right := LRight;
    Result := True;
  end;
end;

end.
