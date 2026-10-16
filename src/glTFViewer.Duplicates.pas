//** @abstract(Question shown when an imported animation's name is already used.)
//**
//** @link(TDuplicateFrame) offers the choices of @code(TglTFDuplicateAction): replace the old
//** animation, keep the old one and ignore the imported one, or rename the imported one, with a
//** unique name suggested and editable. A tick applies the same choice to the remaining
//** duplicates of the import, and "Abort import" stops the import after the animations
//** already added.
//**
//** It is not a separate modal form but a panel drawn over the main form, like the progress
//** box, so the application keeps running normally while it waits: the import, waiting in
//** its background thread, gets the answer through a callback. The frame is designed in
//** glTFViewer.Duplicates.fmx.
unit glTFViewer.Duplicates;

{
  Question shown when an imported animation's name is already used.

  TDuplicateFrame offers the choices of TglTFDuplicateAction: replace the old
  animation, keep the old one and ignore the imported one, or rename the
  imported one, with a unique name suggested and editable. A tick applies the
  same choice to the remaining duplicates of the import, and "Abort import"
  stops the import after the animations already added.

  It is not a separate modal form but a panel drawn over the main form, like
  the progress box, so the application keeps running normally while it waits:
  the import, waiting in its background thread, gets the answer through a
  callback. The frame is designed in glTFViewer.Duplicates.fmx.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.Objects,
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
  //** Create it once with the form as parent; it covers the form, and stays hidden until
  //** @link(Ask). Use it on the main thread only.
  /// <summary>Asks, over its parent form, what to do with a duplicate animation.</summary>
  /// <remarks>Create it once with the form as parent; it covers the form, and stays hidden
  /// until <see cref="Ask"/>. Use it on the main thread only.</remarks>
  TDuplicateFrame = class(TFrame)
    //** @abstract(Dims the form and takes the input meant for it.)
    /// <summary>Dims the form and takes the input meant for it.</summary>
    rectShade: TRectangle;

    //** @abstract(The box in the middle.)
    /// <summary>The box in the middle.</summary>
    rectBox: TRectangle;

    //** @abstract(What clashes with what.)
    /// <summary>What clashes with what.</summary>
    lblInfo: TLabel;

    //** @abstract(Replace the old animation with the imported one.)
    /// <summary>Replace the old animation with the imported one.</summary>
    rbReplace: TRadioButton;

    //** @abstract(Keep the old animation and ignore the imported one.)
    /// <summary>Keep the old animation and ignore the imported one.</summary>
    rbKeep: TRadioButton;

    //** @abstract(Import the animation under the name in edtName.)
    /// <summary>Import the animation under the name in edtName.</summary>
    rbRename: TRadioButton;

    //** @abstract(The new name, a unique one suggested.)
    /// <summary>The new name, a unique one suggested.</summary>
    edtName: TEdit;

    //** @abstract(Why the name typed cannot be used.)
    /// <summary>Why the name typed cannot be used.</summary>
    lblError: TLabel;

    //** @abstract(Do the same for the other duplicates of the import.)
    /// <summary>Do the same for the other duplicates of the import.</summary>
    chkForAll: TCheckBox;

    //** @abstract(Holds the buttons, at the bottom of the box.)
    /// <summary>Holds the buttons, at the bottom of the box.</summary>
    layButtons: TLayout;

    //** @abstract(Stops the import after the animations already added.)
    /// <summary>Stops the import after the animations already added.</summary>
    btnAbortImport: TButton;

    //** @abstract(Answers with the choice made.)
    /// <summary>Answers with the choice made.</summary>
    btnOK: TButton;

    //** @abstract(Enables the name box while Rename is chosen.)
    //**
    //** @param(Sender The radio button.)
    /// <summary>Enables the name box while Rename is chosen.</summary>
    /// <param name="Sender">The radio button.</param>
    procedure RadioChange(Sender: TObject);

    //** @abstract(Checks the name as it is typed.)
    //**
    //** @param(Sender The edit box.)
    /// <summary>Checks the name as it is typed.</summary>
    /// <param name="Sender">The edit box.</param>
    procedure edtNameChangeTracking(Sender: TObject);

    //** @abstract(Answers with the choice made, unless the new name cannot be used.)
    //**
    //** @param(Sender The button.)
    /// <summary>Answers with the choice made, unless the new name cannot be used.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnOKClick(Sender: TObject);

    //** @abstract(Answers "Abort import".)
    //**
    //** @param(Sender The button; nil when called by Cancel.)
    /// <summary>Answers "Abort import".</summary>
    /// <param name="Sender">The button; nil when called by Cancel.</param>
    procedure btnAbortImportClick(Sender: TObject);
  private
    FValidate: TFunc<string, string>;
    FDone: TProc<TDuplicateChoice>;
    procedure Answer(const AChoice: TDuplicateChoice);
  protected
    //** @abstract(Keeps the box narrower than the form, for phones in portrait.)
    /// <summary>Keeps the box narrower than the form, for phones in portrait.</summary>
    procedure Resize; override;
  public
    //** @abstract(Creates the hidden frame.)
    //**
    //** @param(AOwner Owner of the frame.)
    /// <summary>Creates the hidden frame.</summary>
    /// <param name="AOwner">Owner of the frame.</param>
    constructor Create(AOwner: TComponent); override;

    //** @abstract(Shows the question; returns at once.)
    //**
    //** The frame covers the form and takes all input until the user answers. Rename is
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
    /// <remarks>The frame covers the form and takes all input until the user answers. Rename
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

{$R *.fmx}

const
  BOX_WIDTH = 520;

{ TDuplicateFrame }

constructor TDuplicateFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := TAlignLayout.Contents;
  HitTest := True; // takes the input meant for the form below
  Visible := False;
end;

procedure TDuplicateFrame.Resize;
begin
  inherited;
  // Narrower on phones in portrait
  if Assigned(rectBox) then
    rectBox.Width := Min(BOX_WIDTH, Max(200, Width - 32));
end;

procedure TDuplicateFrame.Ask(const AMessage, ASuggestedName: string;
  const AValidate: TFunc<string, string>; const ADone: TProc<TDuplicateChoice>);
begin
  FValidate := AValidate;
  FDone := ADone;
  lblInfo.Text := AMessage;
  edtName.Text := ASuggestedName;
  chkForAll.IsChecked := False;
  rbRename.IsChecked := True;
  RadioChange(nil);
  Visible := True;
  BringToFront;
end;

procedure TDuplicateFrame.RadioChange(Sender: TObject);
begin
  if (edtName = nil) or (rbRename = nil) then
    Exit; // while the frame is loaded
  edtName.Enabled := rbRename.IsChecked;
  edtNameChangeTracking(nil);
end;

procedure TDuplicateFrame.edtNameChangeTracking(Sender: TObject);
begin
  if lblError = nil then
    Exit; // while the frame is loaded
  if rbRename.IsChecked and Assigned(FValidate) then
    lblError.Text := FValidate(edtName.Text)
  else
    lblError.Text := '';
end;

procedure TDuplicateFrame.Answer(const AChoice: TDuplicateChoice);
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

procedure TDuplicateFrame.btnOKClick(Sender: TObject);
var
  LChoice: TDuplicateChoice;
begin
  if rbRename.IsChecked then
  begin
    edtNameChangeTracking(nil);
    if lblError.Text <> '' then
      Exit; // the name cannot be used; the reason is shown
    LChoice.Action := daRename;
    LChoice.NewName := Trim(edtName.Text);
  end
  else if rbReplace.IsChecked then
    LChoice.Action := daReplace
  else
    LChoice.Action := daKeep;
  LChoice.ForAll := chkForAll.IsChecked;
  Answer(LChoice);
end;

procedure TDuplicateFrame.Cancel;
begin
  if Visible and Assigned(FDone) then
    btnAbortImportClick(nil);
end;

procedure TDuplicateFrame.btnAbortImportClick(Sender: TObject);
var
  LChoice: TDuplicateChoice;
begin
  LChoice.Action := daAbort;
  LChoice.NewName := '';
  LChoice.ForAll := False;
  Answer(LChoice);
end;

end.
