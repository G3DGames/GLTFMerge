//** @abstract(Progress display shown over the main form while a model loads or animations are
//** imported.)
//**
//** @link(TProgressFrame) covers the form with a dimmed layer that takes all clicks, with a
//** box in the middle showing a title, the current model as "Model 2 of 5: walk.glb", the
//** stage, and a progress bar for the whole operation. It is fed with the
//** @code(TglTFProgress) values that TglTFDocument and TglTFAnimationImporter report. When
//** started with an abort action it also shows an Abort button, which is disabled once
//** pressed, while the work finishes the step it is on.
//**
//** The frame is designed in glTFViewer.Progress.fmx. Use it on the main thread only: progress
//** reported from a background thread must be passed on with TThread.Queue.
unit glTFViewer.Progress;

{
  Progress display shown over the main form while a model loads or animations
  are imported.

  TProgressFrame covers the form with a dimmed layer that takes all clicks,
  with a box in the middle showing a title, the current model as
  "Model 2 of 5: walk.glb", the stage, and a progress bar for the whole
  operation. It is fed with the TglTFProgress values that TglTFDocument and
  TglTFAnimationImporter report. When started with an abort action it also
  shows an Abort button, which is disabled once pressed, while the work
  finishes the step it is on.

  The frame is designed in glTFViewer.Progress.fmx. Use it on the main thread
  only: progress reported from a background thread must be passed on with
  TThread.Queue.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Layouts, FMX.Objects, FMX.Graphics,
  FMX.Controls.Presentation,

  glTF.Document;

type
  //** @abstract(A modal progress box drawn over its parent.)
  //**
  //** Create it with the form as parent; it covers the form, and stays hidden until
  //** @link(Start).
  /// <summary>A modal progress box drawn over its parent.</summary>
  /// <remarks>Create it with the form as parent; it covers the form, and stays hidden until
  /// <see cref="Start"/>.</remarks>
  TProgressFrame = class(TFrame)
    //** @abstract(Dims the form and takes the clicks meant for it.)
    /// <summary>Dims the form and takes the clicks meant for it.</summary>
    rectShade: TRectangle;

    //** @abstract(The box in the middle.)
    /// <summary>The box in the middle.</summary>
    rectBox: TRectangle;

    //** @abstract(What is being done.)
    /// <summary>What is being done.</summary>
    lblTitle: TLabel;

    //** @abstract(The current model, as "Model 2 of 5: walk.glb".)
    /// <summary>The current model, as "Model 2 of 5: walk.glb".</summary>
    lblModel: TLabel;

    //** @abstract(The stage the work is at.)
    /// <summary>The stage the work is at.</summary>
    lblStage: TLabel;

    //** @abstract(How far the whole operation has got, from 0 to 1000.)
    /// <summary>How far the whole operation has got, from 0 to 1000.</summary>
    pbOverall: TProgressBar;

    //** @abstract(Holds the Abort button; shown when the work can be aborted.)
    /// <summary>Holds the Abort button; shown when the work can be aborted.</summary>
    layButtons: TLayout;

    //** @abstract(Stops the work after the step it is on.)
    /// <summary>Stops the work after the step it is on.</summary>
    btnAbort: TButton;

    //** @abstract(Disables the button and calls the abort action.)
    //**
    //** @param(Sender The button.)
    /// <summary>Disables the button and calls the abort action.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnAbortClick(Sender: TObject);
  private
    FOnAbort: TProc;
  protected
    //** @abstract(Keeps the box narrower than the form, for phones in portrait.)
    /// <summary>Keeps the box narrower than the form, for phones in portrait.</summary>
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

{$R *.fmx}

const
  BOX_WIDTH = 440;
  BOX_HEIGHT = 150;
  BUTTONS_HEIGHT = 44;

{ TProgressFrame }

constructor TProgressFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := TAlignLayout.Contents;
  HitTest := True; // takes the clicks meant for the form below
  Visible := False;
end;

procedure TProgressFrame.btnAbortClick(Sender: TObject);
begin
  // Once only: the work stops after the step it is on
  btnAbort.Enabled := False;
  btnAbort.Text := 'Stopping...';
  if Assigned(FOnAbort) then
    FOnAbort();
end;

procedure TProgressFrame.Resize;
begin
  inherited;
  // Narrower on phones in portrait
  if Assigned(rectBox) then
    rectBox.Width := Min(BOX_WIDTH, Max(160, Width - 32));
end;

procedure TProgressFrame.Start(const ATitle: string; const AOnAbort: TProc);
begin
  FOnAbort := AOnAbort;
  layButtons.Visible := Assigned(AOnAbort);
  btnAbort.Enabled := True;
  btnAbort.Text := 'Abort';
  if Assigned(AOnAbort) then
    rectBox.Height := BOX_HEIGHT + BUTTONS_HEIGHT
  else
    rectBox.Height := BOX_HEIGHT;
  lblTitle.Text := ATitle;
  lblModel.Text := '';
  lblStage.Text := 'Starting...';
  pbOverall.Value := 0;
  Visible := True;
  BringToFront;
end;

procedure TProgressFrame.ShowProgress(const AProgress: TglTFProgress);
begin
  if not Visible then
    Exit; // a late report after Finish
  lblModel.Text := AProgress.ModelText;
  lblStage.Text := AProgress.Stage;
  pbOverall.Value := Round(AProgress.Overall * pbOverall.Max);
end;

procedure TProgressFrame.Finish;
begin
  Visible := False;
  FOnAbort := nil;
end;

function TProgressFrame.Abort: Boolean;
begin
  Result := Visible and Assigned(FOnAbort) and btnAbort.Enabled;
  if Result then
    btnAbortClick(btnAbort);
end;

end.
