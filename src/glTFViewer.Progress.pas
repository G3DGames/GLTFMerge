//** @abstract(Progress display shown over the main form while a model loads or animations are
//** imported.)
//**
//** @link(TProgressOverlay) covers the form with a dimmed layer that takes all clicks, with a
//** box in the middle showing a title, the current model as "Model 2 of 5: walk.glb", the
//** stage, and a progress bar for the whole operation. It is fed with the
//** @code(TglTFProgress) values that TglTFDocument and TglTFAnimationImporter report. When
//** started with an abort action it also shows an Abort button, which is disabled once
//** pressed, while the work finishes the step it is on.
//**
//** Built in code, so the unit needs no .fmx file. Use it on the main thread only: progress
//** reported from a background thread must be passed on with TThread.Queue.
unit glTFViewer.Progress;

{
  Progress display shown over the main form while a model loads or animations
  are imported.

  TProgressOverlay covers the form with a dimmed layer that takes all clicks,
  with a box in the middle showing a title, the current model as
  "Model 2 of 5: walk.glb", the stage, and a progress bar for the whole
  operation. It is fed with the TglTFProgress values that TglTFDocument and
  TglTFAnimationImporter report. When started with an abort action it also
  shows an Abort button, which is disabled once pressed, while the work
  finishes the step it is on.

  Built in code, so the unit needs no .fmx file. Use it on the main thread
  only: progress reported from a background thread must be passed on with
  TThread.Queue.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  FMX.Types, FMX.Controls, FMX.StdCtrls, FMX.Layouts, FMX.Objects, FMX.Graphics,
  FMX.Controls.Presentation,

  glTF.Document;

type
  //** @abstract(A modal progress box drawn over its parent.)
  //**
  //** Create it with the form as parent; it stays hidden until @link(Start).
  /// <summary>A modal progress box drawn over its parent.</summary>
  /// <remarks>Create it with the form as parent; it stays hidden until
  /// <see cref="Start"/>.</remarks>
  TProgressOverlay = class(TLayout)
  private
    FShade: TRectangle;
    FBox: TRectangle;
    FTitle: TLabel;
    FModel: TLabel;
    FStage: TLabel;
    FBar: TProgressBar;
    FButtons: TLayout;
    FAbort: TButton;
    FOnAbort: TProc;
    function AddLabel(ABold: Boolean; AOrder: Single): TLabel;
    procedure AbortClick(Sender: TObject);
  protected
    procedure Resize; override;
  public
    //** @abstract(Creates the hidden overlay.)
    //**
    //** @param(AOwner Owner of the overlay.)
    /// <summary>Creates the hidden overlay.</summary>
    /// <param name="AOwner">Owner of the overlay.</param>
    constructor Create(AOwner: TComponent); override;

    //** @abstract(Shows the overlay with an empty bar.)
    //**
    //** @param(ATitle What is being done, for example "Importing animations".)
    //**
    //** @param(AOnAbort Called on the main thread when the user presses Abort; the button is
    //** then disabled and reads "Stopping...". nil shows no Abort button.)
    /// <summary>Shows the overlay with an empty bar.</summary>
    /// <param name="ATitle">What is being done, for example "Importing
    /// animations".</param>
    /// <param name="AOnAbort">Called on the main thread when the user presses Abort; the
    /// button is then disabled and reads "Stopping...". nil shows no Abort button.</param>
    procedure Start(const ATitle: string; const AOnAbort: TProc = nil);

    //** @abstract(Shows how far the operation has got.)
    //**
    //** @param(AProgress The model line, the stage and the overall position for the bar.)
    /// <summary>Shows how far the operation has got.</summary>
    /// <param name="AProgress">The model line, the stage and the overall position for the
    /// bar.</param>
    procedure ShowProgress(const AProgress: TglTFProgress);

    //** @abstract(Hides the overlay and forgets the abort action.)
    /// <summary>Hides the overlay and forgets the abort action.</summary>
    procedure Finish;

    //** @abstract(Does what pressing Abort does, when the button is shown and not yet pressed.)
    //**
    //** Used when the form is closed during the work.
    //**
    //** @returns(True when the abort action was called.)
    /// <summary>Does what pressing Abort does, when the button is shown and not yet
    /// pressed.</summary>
    /// <returns>True when the abort action was called.</returns>
    /// <remarks>Used when the form is closed during the work.</remarks>
    function Abort: Boolean;
  end;

implementation

const
  BOX_WIDTH = 440;
  BOX_HEIGHT = 150;
  BUTTONS_HEIGHT = 44;
  BAR_MAX = 1000;

{ TProgressOverlay }

constructor TProgressOverlay.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := TAlignLayout.Contents;
  HitTest := True; // takes the clicks meant for the form below
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

  FTitle := AddLabel(True, 0);
  FModel := AddLabel(False, 100);
  FStage := AddLabel(False, 200);

  FBar := TProgressBar.Create(Self);
  FBar.Parent := FBox;
  FBar.Align := TAlignLayout.Top;
  FBar.Position.Y := 300;
  FBar.Margins.Top := 8;
  FBar.Height := 20;
  FBar.Min := 0;
  FBar.Max := BAR_MAX;

  FButtons := TLayout.Create(Self);
  FButtons.Parent := FBox;
  FButtons.Align := TAlignLayout.Top;
  FButtons.Position.Y := 400;
  FButtons.Height := BUTTONS_HEIGHT;
  FButtons.Padding.Top := 10;
  FButtons.Visible := False;

  FAbort := TButton.Create(Self);
  FAbort.Parent := FButtons;
  FAbort.Align := TAlignLayout.Right;
  FAbort.Width := 200;
  FAbort.Text := 'Abort';
  FAbort.OnClick := AbortClick;
end;

procedure TProgressOverlay.AbortClick(Sender: TObject);
begin
  // Once only: the work stops after the step it is on
  FAbort.Enabled := False;
  FAbort.Text := 'Stopping...';
  if Assigned(FOnAbort) then
    FOnAbort();
end;

function TProgressOverlay.AddLabel(ABold: Boolean; AOrder: Single): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := FBox;
  Result.Align := TAlignLayout.Top;
  Result.Position.Y := AOrder;
  Result.Height := 24;
  // Dark text on the white box, whatever the style
  Result.StyledSettings := Result.StyledSettings - [TStyledSetting.FontColor, TStyledSetting.Style];
  Result.TextSettings.FontColor := TAlphaColors.Black;
  if ABold then
    Result.TextSettings.Font.Style := [TFontStyle.fsBold];
  Result.TextSettings.Trimming := TTextTrimming.Character;
  Result.TextSettings.WordWrap := False;
end;

procedure TProgressOverlay.Resize;
begin
  inherited;
  // Narrower on phones in portrait
  if Assigned(FBox) then
    FBox.Width := Min(BOX_WIDTH, Max(160, Width - 32));
end;

procedure TProgressOverlay.Start(const ATitle: string; const AOnAbort: TProc);
begin
  FOnAbort := AOnAbort;
  FButtons.Visible := Assigned(AOnAbort);
  FAbort.Enabled := True;
  FAbort.Text := 'Abort';
  if Assigned(AOnAbort) then
    FBox.Height := BOX_HEIGHT + BUTTONS_HEIGHT
  else
    FBox.Height := BOX_HEIGHT;
  FTitle.Text := ATitle;
  FModel.Text := '';
  FStage.Text := 'Starting...';
  FBar.Value := 0;
  Visible := True;
  BringToFront;
end;

procedure TProgressOverlay.ShowProgress(const AProgress: TglTFProgress);
begin
  if not Visible then
    Exit; // a late report after Finish
  FModel.Text := AProgress.ModelText;
  FStage.Text := AProgress.Stage;
  FBar.Value := Round(AProgress.Overall * BAR_MAX);
end;

procedure TProgressOverlay.Finish;
begin
  Visible := False;
  FOnAbort := nil;
end;

function TProgressOverlay.Abort: Boolean;
begin
  Result := Visible and Assigned(FOnAbort) and FAbort.Enabled;
  if Result then
    AbortClick(FAbort);
end;

end.
