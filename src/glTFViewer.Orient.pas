//** @abstract(The Re-Orient tab of the viewer: the turn about X, Y and Z applied when saving.)
//**
//** @link(TglTFOrientPanel) holds three angles in degrees, from -360 to 360, decimals allowed.
//** When they turn the model, a save writes it turned, its meshes, nodes, animations and
//** skins re-oriented by TglTFReorienter, so the saved model has the up and forward axes the
//** engine expects without a starting rotation. When all three are 0, the model is saved as it
//** is. The loaded model is never changed, so the angles can be tried and changed freely.
//**
//** Buttons set common turns: Z-up to glTF's Y-up, the reverse, and turning the model to face
//** the other way. The panel is built in code, so the unit needs no .fmx file; a graphical way
//** to choose the turn may come later.
unit glTFViewer.Orient;

{
  The Re-Orient tab of the viewer: the turn about X, Y and Z applied when
  saving.

  TglTFOrientPanel holds three angles in degrees, from -360 to 360, decimals
  allowed. When they turn the model, a save writes it turned, its meshes,
  nodes, animations and skins re-oriented by TglTFReorienter, so the saved
  model has the up and forward axes the engine expects without a starting
  rotation. When all three are 0, the model is saved as it is. The loaded
  model is never changed, so the angles can be tried and changed freely.

  Buttons set common turns: Z-up to glTF's Y-up, the reverse, and turning the
  model to face the other way. The panel is built in code, so the unit needs
  no .fmx file; a graphical way to choose the turn may come later.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  FMX.Types, FMX.Controls, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.Graphics,
  FMX.Controls.Presentation;

type
  //** @abstract(Panel with the X, Y and Z angles a save turns the model by.)
  //**
  //** Place it on a tab with Align = Client. Must be used on the main thread.
  /// <summary>Panel with the X, Y and Z angles a save turns the model by.</summary>
  /// <remarks>Place it on a tab with Align = Client. Must be used on the main
  /// thread.</remarks>
  TglTFOrientPanel = class(TLayout)
  private
    FEdits: array[0..2] of TEdit;
    FStatus: TLabel;
    FSetting: Boolean;
    FOnChange: TNotifyEvent;
    procedure BuildControls;
    function AddRow(AParent: TFmxObject; const ACaption: string; AOrder: Single): TEdit;
    function AddPreset(AParent: TFmxObject; const AText: string; AOrder: Single;
      AX, AY, AZ: Double): TButton;
    procedure EditChange(Sender: TObject);
    procedure PresetClick(Sender: TObject);
    procedure UpdateStatus;
  public
    //** @abstract(Creates the panel with all three angles at 0.)
    //**
    //** @param(AOwner Owner of the panel.)
    /// <summary>Creates the panel with all three angles at 0.</summary>
    /// <param name="AOwner">Owner of the panel.</param>
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

uses
  glTF.Orient;

const
  AXIS_NAMES: array[0..2] of string = ('X', 'Y', 'Z');

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

{ TglTFOrientPanel }

constructor TglTFOrientPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BuildControls;
  SetAngles(0, 0, 0);
end;

function TglTFOrientPanel.AddRow(AParent: TFmxObject; const ACaption: string;
  AOrder: Single): TEdit;
var
  LRow: TLayout;
  LLabel: TLabel;
begin
  LRow := TLayout.Create(Self);
  LRow.Parent := AParent;
  LRow.Align := TAlignLayout.Top;
  LRow.Position.Y := AOrder;
  LRow.Height := 34;
  LRow.Padding.Rect := TRectF.Create(0, 3, 0, 3);

  LLabel := TLabel.Create(Self);
  LLabel.Parent := LRow;
  LLabel.Align := TAlignLayout.Left;
  LLabel.Width := 190;
  LLabel.Text := ACaption;

  Result := TEdit.Create(Self);
  Result.Parent := LRow;
  Result.Align := TAlignLayout.Left;
  Result.Position.X := 1000;
  Result.Width := 100;
  Result.TextPrompt := '0';
  Result.OnChangeTracking := EditChange;
end;

function TglTFOrientPanel.AddPreset(AParent: TFmxObject; const AText: string; AOrder: Single;
  AX, AY, AZ: Double): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  Result.Align := TAlignLayout.Left;
  Result.Position.X := AOrder; // same-side alignment is ordered by position
  Result.Width := 170;
  Result.Margins.Right := 8;
  Result.Text := AText;
  // The angles travel in TagString as X;Y;Z
  Result.TagString := Format('%s;%s;%s', [AngleText(AX), AngleText(AY), AngleText(AZ)]);
  Result.OnClick := PresetClick;
end;

procedure TglTFOrientPanel.BuildControls;
var
  LBox, LPresets: TLayout;
  LInfo: TLabel;
  I: Integer;
begin
  LBox := TLayout.Create(Self);
  LBox.Parent := Self;
  LBox.Align := TAlignLayout.Client;
  LBox.Padding.Rect := TRectF.Create(16, 12, 16, 12);

  LInfo := TLabel.Create(Self);
  LInfo.Parent := LBox;
  LInfo.Align := TAlignLayout.Top;
  LInfo.Position.Y := 0;
  LInfo.Height := 64;
  LInfo.TextSettings.WordWrap := True;
  LInfo.TextSettings.VertAlign := TTextAlign.Leading;
  LInfo.Text := 'Turns the whole model when it is saved, so it has the up and forward axes ' +
    'your engine expects without a starting rotation. Meshes, normals, nodes, animations and ' +
    'skins are all turned; the loaded model is not changed. X is applied first, then Y, ' +
    'then Z. Leave all three at 0 to save the model as it is.';

  for I := 0 to 2 do
    FEdits[I] := AddRow(LBox, Format('Turn about %s (degrees):', [AXIS_NAMES[I]]),
      100 + I * 100);

  LPresets := TLayout.Create(Self);
  LPresets.Parent := LBox;
  LPresets.Align := TAlignLayout.Top;
  LPresets.Position.Y := 1000;
  LPresets.Height := 44;
  LPresets.Padding.Rect := TRectF.Create(0, 10, 0, 2);
  AddPreset(LPresets, 'Z-up to Y-up (X -90)', 0, -90, 0, 0);
  AddPreset(LPresets, 'Y-up to Z-up (X 90)', 1000, 90, 0, 0);
  AddPreset(LPresets, 'Face the other way (Y 180)', 2000, 0, 180, 0);
  AddPreset(LPresets, 'No turn', 3000, 0, 0, 0);

  FStatus := TLabel.Create(Self);
  FStatus.Parent := LBox;
  FStatus.Align := TAlignLayout.Top;
  FStatus.Position.Y := 2000;
  FStatus.Height := 44;
  FStatus.Margins.Top := 8;
  FStatus.TextSettings.WordWrap := True;
  FStatus.StyledSettings := FStatus.StyledSettings - [TStyledSetting.FontColor];
end;

function TglTFOrientPanel.GetAngles(out AX, AY, AZ: Double): Boolean;
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

procedure TglTFOrientPanel.SetAngles(AX, AY, AZ: Double);
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

procedure TglTFOrientPanel.UpdateStatus;
var
  LX, LY, LZ: Double;
begin
  if not GetAngles(LX, LY, LZ) then
  begin
    FStatus.TextSettings.FontColor := TAlphaColors.Red;
    FStatus.Text := 'Each angle must be a number from -360 to 360; nothing is turned until ' +
      'they are.';
  end
  else if TglTFReorienter.IsIdentity(LX, LY, LZ) then
  begin
    FStatus.TextSettings.FontColor := TAlphaColors.Gray;
    FStatus.Text := 'No turn: the model is saved as it is.';
  end
  else
  begin
    FStatus.TextSettings.FontColor := TAlphaColors.Green;
    FStatus.Text := Format('The model will be saved turned by X %s, Y %s, Z %s degrees.',
      [AngleText(LX), AngleText(LY), AngleText(LZ)]);
  end;
end;

procedure TglTFOrientPanel.EditChange(Sender: TObject);
begin
  if FSetting then
    Exit;
  UpdateStatus;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TglTFOrientPanel.PresetClick(Sender: TObject);
var
  LParts: TArray<string>;
begin
  LParts := (Sender as TButton).TagString.Split([';']);
  SetAngles(StrToFloat(LParts[0], TFormatSettings.Invariant),
    StrToFloat(LParts[1], TFormatSettings.Invariant),
    StrToFloat(LParts[2], TFormatSettings.Invariant));
end;

end.
