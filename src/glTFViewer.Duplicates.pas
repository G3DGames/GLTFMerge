//** @abstract(Question shown when an imported animation's name is already used.)
//**
//** @link(TDuplicatePanel) offers the choices of @code(TglTFDuplicateAction): replace the old
//** animation, keep the old one and ignore the imported one, or rename the imported one, with a
//** unique name suggested and editable. A tick applies the same choice to the remaining
//** duplicates of the import, and "Abort import" stops the import after the animations
//** already added.
//**
//** It is not a separate modal form but a panel drawn over the main form, like the progress
//** box, so the application keeps running normally while it waits: the import, waiting in
//** its background thread, gets the answer through a callback. The panel is built in code,
//** so the unit needs no .fmx file.
unit glTFViewer.Duplicates;

{
  Question shown when an imported animation's name is already used.

  TDuplicatePanel offers the choices of TglTFDuplicateAction: replace the old
  animation, keep the old one and ignore the imported one, or rename the
  imported one, with a unique name suggested and editable. A tick applies the
  same choice to the remaining duplicates of the import, and "Abort import"
  stops the import after the animations already added.

  It is not a separate modal form but a panel drawn over the main form, like
  the progress box, so the application keeps running normally while it waits:
  the import, waiting in its background thread, gets the answer through a
  callback. The panel is built in code, so the unit needs no .fmx file.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  FMX.Types, FMX.Controls, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.Objects,
  FMX.Graphics, FMX.Controls.Presentation,

  glTF.Animations;

type
  //** @abstract(The answer given to the duplicate question.)
  /// <summary>The answer given to the duplicate question.</summary>
  TDuplicateChoice = record
    //** @abstract(What to do with this animation; daAbort when the user chose "Abort
    //** import".)
    /// <summary>What to do with this animation; daAbort when the user chose "Abort
    /// import".</summary>
    Action: TglTFDuplicateAction;

    //** @abstract(The new name, when Action is daRename; already checked with the validation
    //** function.)
    /// <summary>The new name, when Action is daRename; already checked with the validation
    /// function.</summary>
    NewName: string;

    //** @abstract(Whether the same action is to be taken for the remaining duplicates, without
    //** asking; renamed ones then get a suggested name.)
    /// <summary>Whether the same action is to be taken for the remaining duplicates, without
    /// asking; renamed ones then get a suggested name.</summary>
    ForAll: Boolean;
  end;

  //** @abstract(Asks, over its parent form, what to do with a duplicate animation.)
  //**
  //** Create it once with the form as parent; it stays hidden until @link(Ask). Use it on the
  //** main thread only.
  /// <summary>Asks, over its parent form, what to do with a duplicate animation.</summary>
  /// <remarks>Create it once with the form as parent; it stays hidden until
  /// <see cref="Ask"/>. Use it on the main thread only.</remarks>
  TDuplicatePanel = class(TLayout)
  private
    FShade: TRectangle;
    FBox: TRectangle;
    FInfo: TLabel;
    FReplace: TRadioButton;
    FKeep: TRadioButton;
    FRename: TRadioButton;
    FNameEdit: TEdit;
    FError: TLabel;
    FForAll: TCheckBox;
    FValidate: TFunc<string, string>;
    FDone: TProc<TDuplicateChoice>;
    function AddRadio(const AText: string; AOrder: Single): TRadioButton;
    function AddDarkLabel(AOrder, AHeight: Single): TLabel;
    procedure RadioChange(Sender: TObject);
    procedure NameChange(Sender: TObject);
    procedure OKClick(Sender: TObject);
    procedure AbortClick(Sender: TObject);
    procedure Answer(const AChoice: TDuplicateChoice);
  protected
    procedure Resize; override;
  public
    //** @abstract(Creates the hidden panel.)
    //**
    //** @param(AOwner Owner of the panel.)
    /// <summary>Creates the hidden panel.</summary>
    /// <param name="AOwner">Owner of the panel.</param>
    constructor Create(AOwner: TComponent); override;

    //** @abstract(Shows the question; returns at once.)
    //**
    //** The panel covers the form and takes all input until the user answers. Rename is
    //** selected at first, with ASuggestedName in its edit box.
    //**
    //** @param(AMessage What clashes with what, shown at the top.)
    //**
    //** @param(ASuggestedName A unique name to offer for renaming.)
    //**
    //** @param(AValidate Returns why a name cannot be used, or an empty string when it can.)
    //**
    //** @param(ADone Called on the main thread with the answer, after the panel is hidden.)
    /// <summary>Shows the question; returns at once.</summary>
    /// <param name="AMessage">What clashes with what, shown at the top.</param>
    /// <param name="ASuggestedName">A unique name to offer for renaming.</param>
    /// <param name="AValidate">Returns why a name cannot be used, or an empty string when it
    /// can.</param>
    /// <param name="ADone">Called on the main thread with the answer, after the panel is
    /// hidden.</param>
    /// <remarks>The panel covers the form and takes all input until the user answers. Rename
    /// is selected at first, with ASuggestedName in its edit box.</remarks>
    procedure Ask(const AMessage, ASuggestedName: string;
      const AValidate: TFunc<string, string>; const ADone: TProc<TDuplicateChoice>);

    //** @abstract(Answers the question shown with "Abort import", as if the user had pressed
    //** it; does nothing when no question is shown.)
    //**
    //** Used when the form is closed while an import waits for an answer.
    /// <summary>Answers the question shown with "Abort import", as if the user had pressed
    /// it; does nothing when no question is shown.</summary>
    /// <remarks>Used when the form is closed while an import waits for an answer.</remarks>
    procedure Cancel;
  end;

implementation

const
  BOX_WIDTH = 520;
  BOX_HEIGHT = 330;

{ TDuplicatePanel }

constructor TDuplicatePanel.Create(AOwner: TComponent);
var
  LButtons: TLayout;
  LButton: TButton;
begin
  inherited Create(AOwner);
  Align := TAlignLayout.Contents;
  HitTest := True; // takes the input meant for the form below
  Visible := False;

  FShade := TRectangle.Create(Self);
  FShade.Parent := Self;
  FShade.Align := TAlignLayout.Contents;
  FShade.Fill.Color := $66000000;
  FShade.Stroke.Kind := TBrushKind.None;
  FShade.HitTest := True;

  FBox := TRectangle.Create(Self);
  FBox.Parent := Self;
  FBox.Align := TAlignLayout.Center;
  FBox.Width := BOX_WIDTH;
  FBox.Height := BOX_HEIGHT;
  FBox.Fill.Color := TAlphaColors.White;
  FBox.Stroke.Color := TAlphaColors.Gray;
  FBox.XRadius := 6;
  FBox.YRadius := 6;
  FBox.Padding.Rect := TRectF.Create(16, 12, 16, 12);

  // Top to bottom; each Position.Y is larger than where the controls above
  // end, so the order holds
  FInfo := AddDarkLabel(0, 60);
  FInfo.TextSettings.WordWrap := True;
  FInfo.TextSettings.Font.Style := [TFontStyle.fsBold];

  FReplace := AddRadio('Replace the old animation with this one', 1000);
  FKeep := AddRadio('Keep the old animation and ignore this one', 2000);
  FRename := AddRadio('Import this one under a new name:', 3000);

  FNameEdit := TEdit.Create(Self);
  FNameEdit.Parent := FBox;
  FNameEdit.Align := TAlignLayout.Top;
  FNameEdit.Position.Y := 4000;
  FNameEdit.Margins.Rect := TRectF.Create(26, 2, 0, 2);
  FNameEdit.OnChangeTracking := NameChange;

  FError := AddDarkLabel(5000, 20);
  FError.Margins.Left := 26;
  FError.TextSettings.FontColor := TAlphaColors.Red;

  FForAll := TCheckBox.Create(Self);
  FForAll.Parent := FBox;
  FForAll.Align := TAlignLayout.Top;
  FForAll.Position.Y := 6000;
  FForAll.Height := 26;
  FForAll.Margins.Top := 4;
  FForAll.Text := 'Do the same for the other duplicates of this import';

  LButtons := TLayout.Create(Self);
  LButtons.Parent := FBox;
  LButtons.Align := TAlignLayout.Bottom;
  LButtons.Height := 36;

  LButton := TButton.Create(Self);
  LButton.Parent := LButtons;
  LButton.Align := TAlignLayout.Right;
  LButton.Position.X := 2000;
  LButton.Width := 100;
  LButton.Text := 'OK';
  LButton.OnClick := OKClick;

  LButton := TButton.Create(Self);
  LButton.Parent := LButtons;
  LButton.Align := TAlignLayout.Right;
  LButton.Position.X := 1000;
  LButton.Margins.Right := 8;
  LButton.Width := 120;
  LButton.Text := 'Abort import';
  LButton.OnClick := AbortClick;
end;

function TDuplicatePanel.AddDarkLabel(AOrder, AHeight: Single): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := FBox;
  Result.Align := TAlignLayout.Top;
  Result.Position.Y := AOrder;
  Result.Height := AHeight;
  // Dark text on the white box, whatever the style
  Result.StyledSettings := Result.StyledSettings -
    [TStyledSetting.FontColor, TStyledSetting.Style, TStyledSetting.Other];
  Result.TextSettings.FontColor := TAlphaColors.Black;
  Result.TextSettings.WordWrap := False;
  Result.TextSettings.Trimming := TTextTrimming.Character;
end;

function TDuplicatePanel.AddRadio(const AText: string; AOrder: Single): TRadioButton;
begin
  Result := TRadioButton.Create(Self);
  Result.Parent := FBox;
  Result.Align := TAlignLayout.Top;
  Result.Position.Y := AOrder;
  Result.Height := 26;
  Result.GroupName := 'gltf.duplicate';
  Result.Text := AText;
  Result.OnChange := RadioChange;
end;

procedure TDuplicatePanel.Resize;
begin
  inherited;
  // Narrower on phones in portrait
  if Assigned(FBox) then
    FBox.Width := Min(BOX_WIDTH, Max(200, Width - 32));
end;

procedure TDuplicatePanel.Ask(const AMessage, ASuggestedName: string;
  const AValidate: TFunc<string, string>; const ADone: TProc<TDuplicateChoice>);
begin
  FValidate := AValidate;
  FDone := ADone;
  FInfo.Text := AMessage;
  FNameEdit.Text := ASuggestedName;
  FForAll.IsChecked := False;
  FRename.IsChecked := True;
  RadioChange(nil);
  Visible := True;
  BringToFront;
end;

procedure TDuplicatePanel.RadioChange(Sender: TObject);
begin
  if FNameEdit = nil then
    Exit; // during construction
  FNameEdit.Enabled := FRename.IsChecked;
  NameChange(nil);
end;

procedure TDuplicatePanel.NameChange(Sender: TObject);
begin
  if FRename.IsChecked and Assigned(FValidate) then
    FError.Text := FValidate(FNameEdit.Text)
  else
    FError.Text := '';
end;

procedure TDuplicatePanel.Answer(const AChoice: TDuplicateChoice);
var
  LDone: TProc<TDuplicateChoice>;
begin
  // Hidden first, so the callback may ask again
  LDone := FDone;
  FDone := nil;
  FValidate := nil;
  Visible := False;
  if Assigned(LDone) then
    LDone(AChoice);
end;

procedure TDuplicatePanel.OKClick(Sender: TObject);
var
  LChoice: TDuplicateChoice;
begin
  if FRename.IsChecked then
  begin
    NameChange(nil);
    if FError.Text <> '' then
      Exit; // the name cannot be used; the reason is shown
    LChoice.Action := daRename;
    LChoice.NewName := Trim(FNameEdit.Text);
  end
  else if FReplace.IsChecked then
    LChoice.Action := daReplace
  else
    LChoice.Action := daKeep;
  LChoice.ForAll := FForAll.IsChecked;
  Answer(LChoice);
end;

procedure TDuplicatePanel.Cancel;
begin
  if Visible and Assigned(FDone) then
    AbortClick(nil);
end;

procedure TDuplicatePanel.AbortClick(Sender: TObject);
var
  LChoice: TDuplicateChoice;
begin
  LChoice.Action := daAbort;
  LChoice.NewName := '';
  LChoice.ForAll := False;
  Answer(LChoice);
end;

end.
