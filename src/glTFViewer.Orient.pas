//** @abstract(The Re-Orient tab of the viewer: the turn about X, Y and Z applied when saving.)
//**
//** @link(TglTFOrientFrame) holds three angles in degrees, from -360 to 360, decimals allowed.
//** When they turn the model, a save writes it turned, its meshes, nodes, animations and
//** skins re-oriented by TglTFReorienter, so the saved model has the up and forward axes the
//** engine expects without a starting rotation. When all three are 0, the model is saved as it
//** is. The loaded model is never changed, so the angles can be tried and changed freely.
//**
//** Buttons, one above the other, set common turns: Z-up to glTF's Y-up, the reverse, turning
//** the model to face the other way, flipping it upside down and no turn; each button's Tag
//** picks its angles from a table in the code. The frame is designed in glTFViewer.Orient.fmx;
//** the Bulk Re-Orient dialog shows one too @(see glTFViewer.BulkOrient@). A graphical way to
//** choose the turn may come later.
unit glTFViewer.Orient;

{
  The Re-Orient tab of the viewer: the turn about X, Y and Z applied when
  saving.

  TglTFOrientFrame holds three angles in degrees, from -360 to 360, decimals
  allowed. When they turn the model, a save writes it turned, its meshes,
  nodes, animations and skins re-oriented by TglTFReorienter, so the saved
  model has the up and forward axes the engine expects without a starting
  rotation. When all three are 0, the model is saved as it is. The loaded
  model is never changed, so the angles can be tried and changed freely.

  Buttons, one above the other, set common turns: Z-up to glTF's Y-up, the
  reverse, turning the model to face the other way, flipping it upside down
  and no turn; each button's Tag picks its angles from a table in the code.
  The frame is designed in glTFViewer.Orient.fmx; the Bulk Re-Orient dialog
  shows one too (see glTFViewer.BulkOrient). A graphical way to choose the
  turn may come later.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.Graphics,
  FMX.Controls.Presentation;

type
  //** @abstract(Frame with the X, Y and Z angles a save turns the model by.)
  //**
  //** Place it on a tab with Align = Client. Must be used on the main thread.
  /// <summary>Frame with the X, Y and Z angles a save turns the model by.</summary>
  /// <remarks>Place it on a tab with Align = Client. Must be used on the main
  /// thread.</remarks>
  TglTFOrientFrame = class(TFrame)
    //** @abstract(Holds everything, with space around it.)
    /// <summary>Holds everything, with space around it.</summary>
    layBox: TLayout;

    //** @abstract(What the turn does.)
    /// <summary>What the turn does.</summary>
    lblInfo: TLabel;

    //** @abstract(The row of the X angle.)
    /// <summary>The row of the X angle.</summary>
    layX: TLayout;

    //** @abstract(The caption of the X angle.)
    /// <summary>The caption of the X angle.</summary>
    lblX: TLabel;

    //** @abstract(Degrees about the X axis, applied first.)
    /// <summary>Degrees about the X axis, applied first.</summary>
    edtX: TEdit;

    //** @abstract(The row of the Y angle.)
    /// <summary>The row of the Y angle.</summary>
    layY: TLayout;

    //** @abstract(The caption of the Y angle.)
    /// <summary>The caption of the Y angle.</summary>
    lblY: TLabel;

    //** @abstract(Degrees about the Y axis, applied second.)
    /// <summary>Degrees about the Y axis, applied second.</summary>
    edtY: TEdit;

    //** @abstract(The row of the Z angle.)
    /// <summary>The row of the Z angle.</summary>
    layZ: TLayout;

    //** @abstract(The caption of the Z angle.)
    /// <summary>The caption of the Z angle.</summary>
    lblZ: TLabel;

    //** @abstract(Degrees about the Z axis, applied last.)
    /// <summary>Degrees about the Z axis, applied last.</summary>
    edtZ: TEdit;

    //** @abstract(The buttons that set common turns.)
    /// <summary>The buttons that set common turns.</summary>
    layPresets: TLayout;

    //** @abstract(Holds the preset buttons, one above the other.)
    /// <summary>Holds the preset buttons, one above the other.</summary>
    layPresetColumn: TLayout;

    //** @abstract(Turns a Z-up model to glTF's Y-up: X -90.)
    /// <summary>Turns a Z-up model to glTF's Y-up: X -90.</summary>
    btnZUpToYUp: TButton;

    //** @abstract(Turns a Y-up model to Z-up: X 90.)
    /// <summary>Turns a Y-up model to Z-up: X 90.</summary>
    btnYUpToZUp: TButton;

    //** @abstract(Turns the model to face the other way: Y 180.)
    /// <summary>Turns the model to face the other way: Y 180.</summary>
    btnTurnAround: TButton;

    //** @abstract(Turns the model upside down: X 180.)
    /// <summary>Turns the model upside down: X 180.</summary>
    btnFlip: TButton;

    //** @abstract(Sets all three angles to 0.)
    /// <summary>Sets all three angles to 0.</summary>
    btnNoTurn: TButton;

    //** @abstract(The turn a save will apply, or why the angles cannot be used.)
    /// <summary>The turn a save will apply, or why the angles cannot be used.</summary>
    lblStatus: TLabel;

    //** @abstract(Shows what the angles typed will do and raises OnChange.)
    //**
    //** @param(Sender The edit box typed in.)
    /// <summary>Shows what the angles typed will do and raises OnChange.</summary>
    /// <param name="Sender">The edit box typed in.</param>
    procedure AngleChangeTracking(Sender: TObject);

    //** @abstract(Sets the angles of the preset whose index is the button's Tag.)
    //**
    //** @param(Sender The preset button.)
    /// <summary>Sets the angles of the preset whose index is the button's Tag.</summary>
    /// <param name="Sender">The preset button.</param>
    procedure PresetClick(Sender: TObject);
  private
    FEdits: array[0..2] of TEdit;
    FSetting: Boolean;
    FOnChange: TNotifyEvent;
    procedure UpdateStatus;
  public
    //** @abstract(Creates the frame with all three angles at 0.)
    //**
    //** @param(AOwner Owner of the frame.)
    /// <summary>Creates the frame with all three angles at 0.</summary>
    /// <param name="AOwner">Owner of the frame.</param>
    constructor Create(AOwner: TComponent); override;

    //** @abstract(Returns the angles entered.)
    //**
    //** @param(AX Degrees about the X axis, applied first.)
    //**
    //** @param(AY Degrees about the Y axis, applied second.)
    //**
    //** @param(AZ Degrees about the Z axis, applied last.)
    //**
    //** @returns(False when an angle is not a number from -360 to 360; the angles are then
    //** all 0.)
    /// <summary>Returns the angles entered.</summary>
    /// <param name="AX">Degrees about the X axis, applied first.</param>
    /// <param name="AY">Degrees about the Y axis, applied second.</param>
    /// <param name="AZ">Degrees about the Z axis, applied last.</param>
    /// <returns>False when an angle is not a number from -360 to 360; the angles are then all
    /// 0.</returns>
    function GetAngles(out AX, AY, AZ: Double): Boolean;

    //** @abstract(Sets the three angles.)
    //**
    //** @param(AX Degrees about the X axis.)
    //**
    //** @param(AY Degrees about the Y axis.)
    //**
    //** @param(AZ Degrees about the Z axis.)
    /// <summary>Sets the three angles.</summary>
    /// <param name="AX">Degrees about the X axis.</param>
    /// <param name="AY">Degrees about the Y axis.</param>
    /// <param name="AZ">Degrees about the Z axis.</param>
    procedure SetAngles(AX, AY, AZ: Double);

    //** @abstract(Occurs when an angle changes.)
    /// <summary>Occurs when an angle changes.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

{$R *.fmx}

uses
  glTF.Orient;

const
  // The angles X, Y, Z of the preset buttons, by their Tag
  PRESET_ANGLES: array[0..4, 0..2] of Double = (
    (-90, 0, 0),  // Z-up to Y-up
    (90, 0, 0),   // Y-up to Z-up
    (0, 180, 0),  // face the other way
    (180, 0, 0),  // flip upside down
    (0, 0, 0));   // no turn

function AngleText(AValue: Double): string;
begin
  Result := FormatFloat('0.###', AValue, TFormatSettings.Invariant);
end;

function ParseAngle(const AText: string; out AValue: Double): Boolean;
var
  LText: string;
begin
  LText := Trim(AText);
  if LText = '' then
  begin
    AValue := 0;
    Exit(True);
  end;
  Result := (TryStrToFloat(LText, AValue, TFormatSettings.Invariant) or
    TryStrToFloat(LText, AValue)) and (AValue >= -360) and (AValue <= 360);
end;

{ TglTFOrientFrame }

constructor TglTFOrientFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEdits[0] := edtX;
  FEdits[1] := edtY;
  FEdits[2] := edtZ;
  SetAngles(0, 0, 0);
end;

function TglTFOrientFrame.GetAngles(out AX, AY, AZ: Double): Boolean;
begin
  Result := ParseAngle(FEdits[0].Text, AX) and ParseAngle(FEdits[1].Text, AY) and
    ParseAngle(FEdits[2].Text, AZ);
  if not Result then
  begin
    AX := 0;
    AY := 0;
    AZ := 0;
  end;
end;

procedure TglTFOrientFrame.SetAngles(AX, AY, AZ: Double);
begin
  FSetting := True;
  try
    FEdits[0].Text := AngleText(AX);
    FEdits[1].Text := AngleText(AY);
    FEdits[2].Text := AngleText(AZ);
  finally
    FSetting := False;
  end;
  UpdateStatus;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TglTFOrientFrame.UpdateStatus;
var
  LX, LY, LZ: Double;
begin
  if not GetAngles(LX, LY, LZ) then
  begin
    lblStatus.TextSettings.FontColor := TAlphaColors.Red;
    lblStatus.Text := 'Each angle must be a number from -360 to 360; nothing is turned until ' +
      'they are.';
  end
  else if TglTFReorienter.IsIdentity(LX, LY, LZ) then
  begin
    lblStatus.TextSettings.FontColor := TAlphaColors.Gray;
    lblStatus.Text := 'No turn: the model is saved as it is.';
  end
  else
  begin
    lblStatus.TextSettings.FontColor := TAlphaColors.Green;
    lblStatus.Text := Format('The model will be saved turned by X %s, Y %s, Z %s degrees.',
      [AngleText(LX), AngleText(LY), AngleText(LZ)]);
  end;
end;

procedure TglTFOrientFrame.AngleChangeTracking(Sender: TObject);
begin
  if FSetting or (FEdits[0] = nil) then
    Exit; // set by SetAngles, or while the frame is loaded
  UpdateStatus;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TglTFOrientFrame.PresetClick(Sender: TObject);
var
  LIndex: Integer;
begin
  LIndex := (Sender as TComponent).Tag;
  if (LIndex >= Low(PRESET_ANGLES)) and (LIndex <= High(PRESET_ANGLES)) then
    SetAngles(PRESET_ANGLES[LIndex, 0], PRESET_ANGLES[LIndex, 1], PRESET_ANGLES[LIndex, 2]);
end;

end.
