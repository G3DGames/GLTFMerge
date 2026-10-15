//** @abstract(Re-orients a whole glTF model: turns it about the X, Y and Z axes and bakes the
//** turn into the data.)
//**
//** Models are often exported with a different up or forward axis from the one an engine
//** expects, and are then given a starting rotation in the engine. @link(TglTFReorienter)
//** does that turn once, in the file: the model saved afterwards is the right way up, with
//** nothing extra to apply.
//**
//** The turn is X degrees about the X axis, then Y about the Y axis, then Z about the Z axis,
//** each counter-clockwise looking down the axis towards the origin, as usual in glTF's
//** right-handed space. For example X = -90 turns a Z-up model into glTF's Y-up.
//**
//** Every vertex ends up exactly where the turn takes it, and so does everything else:
//**
//** @unorderedList(
//**   @item(Mesh data: positions, normals and tangents, and the same in morph targets, are
//**     turned; the min and max of the accessors that have them are computed again.)
//**   @item(Nodes: each node's transform R L R@-1 keeps the hierarchy as it was, turned as
//**     a whole; the root nodes take the turn itself.)
//**   @item(Animations: translation, rotation and scale key frames are turned the same way
//**     as the transforms they animate, including CUBICSPLINE tangents.)
//**   @item(Skins: the inverse bind matrices are turned to match.)
//**   @item(Cameras and lights, which look down their node's -Z axis, keep their node's
//**     turn, so they still point the same way in the turned model.)
//** )
//**
//** Winding and handedness do not change, as a rotation is not a mirror. A non-uniform
//** scale can only be turned exactly by a multiple of 90 degrees; otherwise the node becomes
//** a matrix, or a warning is given when its scale is animated. Quantized data
//** @(KHR_mesh_quantization@) is turned and quantized again. Positions given by the
//** EXT_mesh_gpu_instancing extension are not turned; a warning says so.
unit glTF.Orient;

{
  Re-orients a whole glTF model: turns it about the X, Y and Z axes and bakes
  the turn into the data.

  Models are often exported with a different up or forward axis from the one
  an engine expects, and are then given a starting rotation in the engine.
  TglTFReorienter does that turn once, in the file: the model saved afterwards
  is the right way up, with nothing extra to apply.

  The turn is X degrees about the X axis, then Y about the Y axis, then Z
  about the Z axis, each counter-clockwise looking down the axis towards the
  origin, as usual in glTF's right-handed space. For example X = -90 turns a
  Z-up model into glTF's Y-up.

  Every vertex ends up exactly where the turn takes it, and so does everything
  else:

  - Mesh data: positions, normals and tangents, and the same in morph targets,
    are turned; the min and max of the accessors that have them are computed
    again.
  - Nodes: each node's transform R L R^-1 keeps the hierarchy as it was,
    turned as a whole; the root nodes take the turn itself.
  - Animations: translation, rotation and scale key frames are turned the same
    way as the transforms they animate, including CUBICSPLINE tangents.
  - Skins: the inverse bind matrices are turned to match.
  - Cameras and lights, which look down their node's -Z axis, keep their
    node's turn, so they still point the same way in the turned model.

  Winding and handedness do not change, as a rotation is not a mirror. A
  non-uniform scale can only be turned exactly by a multiple of 90 degrees;
  otherwise the node becomes a matrix, or a warning is given when its scale is
  animated. Quantized data (KHR_mesh_quantization) is turned and quantized
  again. Positions given by the EXT_mesh_gpu_instancing extension are not
  turned; a warning says so.
}

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Generics.Collections,

  glTF.Base,
  glTF.Classes;

type
  //** @abstract(Turns a whole model about the X, Y and Z axes.)
  //**
  //** All methods are class methods. Apply changes the tree it is given, including its
  //** buffers' bytes, which it copies first, so arrays shared with another tree are not
  //** changed. TglTFDocument uses it on the copy it saves; see
  //** @code(TglTFSaveOptions.RotateX).
  //**
  //** @longCode(#
  //** // A Z-up model to glTF's Y-up
  //** TglTFReorienter.Apply(Doc.Root, -90, 0, 0, Warnings);
  //** #)
  /// <summary>Turns a whole model about the X, Y and Z axes.</summary>
  /// <remarks>All methods are class methods. Apply changes the tree it is given, including its
  /// buffers' bytes, which it copies first, so arrays shared with another tree are not
  /// changed. TglTFDocument uses it on the copy it saves; see
  /// <c>TglTFSaveOptions.RotateX</c>.</remarks>
  /// <example><code>
  /// // A Z-up model to glTF's Y-up
  /// TglTFReorienter.Apply(Doc.Root, -90, 0, 0, Warnings);
  /// </code></example>
  TglTFReorienter = class sealed
  public
    //** @abstract(Tells whether a turn changes anything.)
    //**
    //** @param(AX Degrees about the X axis.)
    //**
    //** @param(AY Degrees about the Y axis.)
    //**
    //** @param(AZ Degrees about the Z axis.)
    //**
    //** @returns(True when all three are 0, or the turn they make is no turn at all, such
    //** as 360 about one axis.)
    /// <summary>Tells whether a turn changes anything.</summary>
    /// <param name="AX">Degrees about the X axis.</param>
    /// <param name="AY">Degrees about the Y axis.</param>
    /// <param name="AZ">Degrees about the Z axis.</param>
    /// <returns>True when all three are 0, or the turn they make is no turn at all, such as
    /// 360 about one axis.</returns>
    class function IsIdentity(AX, AY, AZ: Double): Boolean; static;

    //** @abstract(Turns the whole model and bakes the turn into its data.)
    //**
    //** See the unit description for what changes. Does nothing when IsIdentity is True.
    //**
    //** @param(ARoot The tree to change; its buffer data must be loaded.)
    //**
    //** @param(AX Degrees about the X axis, applied first.)
    //**
    //** @param(AY Degrees about the Y axis, applied second.)
    //**
    //** @param(AZ Degrees about the Z axis, applied last.)
    //**
    //** @param(AWarnings Receives a line for everything that could not be turned exactly;
    //** may be nil.)
    //**
    //** @raises(EglTFError Data that must be turned is not loaded.)
    /// <summary>Turns the whole model and bakes the turn into its data.</summary>
    /// <param name="ARoot">The tree to change; its buffer data must be loaded.</param>
    /// <param name="AX">Degrees about the X axis, applied first.</param>
    /// <param name="AY">Degrees about the Y axis, applied second.</param>
    /// <param name="AZ">Degrees about the Z axis, applied last.</param>
    /// <param name="AWarnings">Receives a line for everything that could not be turned
    /// exactly; may be nil.</param>
    /// <exception cref="EglTFError">Data that must be turned is not loaded.</exception>
    /// <remarks>See the unit description for what changes. Does nothing when IsIdentity is
    /// True.</remarks>
    class procedure Apply(ARoot: TglTF; AX, AY, AZ: Double; AWarnings: TStrings); static;
  end;

implementation

const
  EPSILON = 1e-9;

type
  TQuat = array[0..3] of Double; // x, y, z, w as in glTF
  TMat3 = array[0..2, 0..2] of Double; // [row, column]
  TElementProc = reference to procedure(var AValues: TArray<Double>);

  // What a node's transform becomes: L' = A L B, A and B being the turn,
  // its inverse or nothing
  TNodeTurn = record
    Left: Boolean;    // A = R
    Right: Boolean;   // B = R^-1
  end;

  // The work of one Apply call
  TReorientJob = class
  private
    FRoot: TglTF;
    FWarnings: TStrings;
    FQuat, FInverse: TQuat;
    FMat: TMat3;
    FAxisAligned: Boolean;
    FCopied: TList<Integer>;
    FDone: TDictionary<Integer, string>;
    FClamped: Boolean;
    procedure Warn(const AText: string);
    function OwnData(ABuffer: Integer): TBytes;
    procedure VisitElements(AAccessor: Integer; const AProc: TElementProc);
    procedure VisitView(AAccessor: TglTFAccessor; AView: Integer; AByteOffset: Int64;
      ACount, AStride: Integer; const AProc: TElementProc);
    function Claim(AAccessor: Integer; const AKind: string): Boolean;
    procedure RecomputeMinMax(AAccessor: Integer);
    procedure TurnVectors(AAccessor: Integer; const AKind: string);
    procedure TurnMeshes;
    procedure TurnNodesAndAnimations;
    procedure TurnSkins(const ATurns: TArray<TNodeTurn>);
    function TurnScale(var AScale: array of Double): Boolean;
    function TurnVector(const AVector: array of Double): TArray<Double>;
  public
    constructor Create(ARoot: TglTF; AX, AY, AZ: Double; AWarnings: TStrings);
    destructor Destroy; override;
    procedure Run;
  end;

{ Quaternions and matrices }

function QuatMul(const A, B: TQuat): TQuat;
begin
  Result[0] := A[3] * B[0] + A[0] * B[3] + A[1] * B[2] - A[2] * B[1];
  Result[1] := A[3] * B[1] - A[0] * B[2] + A[1] * B[3] + A[2] * B[0];
  Result[2] := A[3] * B[2] + A[0] * B[1] - A[1] * B[0] + A[2] * B[3];
  Result[3] := A[3] * B[3] - A[0] * B[0] - A[1] * B[1] - A[2] * B[2];
end;

function AxisQuat(AAxis: Integer; ADegrees: Double): TQuat;
var
  LHalf: Double;
begin
  LHalf := DegToRad(ADegrees) / 2;
  Result[0] := 0;
  Result[1] := 0;
  Result[2] := 0;
  Result[AAxis] := Sin(LHalf);
  Result[3] := Cos(LHalf);
end;

function Snap(AValue: Double): Double;
begin
  // So that turns by multiples of 90 degrees give exact 0, 1 and -1
  if Abs(AValue) < 1e-12 then
    Result := 0
  else if Abs(AValue - 1) < 1e-12 then
    Result := 1
  else if Abs(AValue + 1) < 1e-12 then
    Result := -1
  else
    Result := AValue;
end;

function MatFromQuat(const Q: TQuat): TMat3;
var
  X, Y, Z, W: Double;
  R, C: Integer;
begin
  X := Q[0];
  Y := Q[1];
  Z := Q[2];
  W := Q[3];
  Result[0, 0] := 1 - 2 * (Y * Y + Z * Z);
  Result[0, 1] := 2 * (X * Y - Z * W);
  Result[0, 2] := 2 * (X * Z + Y * W);
  Result[1, 0] := 2 * (X * Y + Z * W);
  Result[1, 1] := 1 - 2 * (X * X + Z * Z);
  Result[1, 2] := 2 * (Y * Z - X * W);
  Result[2, 0] := 2 * (X * Z - Y * W);
  Result[2, 1] := 2 * (Y * Z + X * W);
  Result[2, 2] := 1 - 2 * (X * X + Y * Y);
  for R := 0 to 2 do
    for C := 0 to 2 do
      Result[R, C] := Snap(Result[R, C]);
end;

function TurnQuat(AX, AY, AZ: Double): TQuat;
begin
  // X first, then Y, then Z: R = Rz Ry Rx
  Result := QuatMul(AxisQuat(2, AZ), QuatMul(AxisQuat(1, AY), AxisQuat(0, AX)));
end;

// A 4x4 column-major matrix with the turn (or its inverse) in its 3x3 part
function Mat4(const M: TMat3; AInverse: Boolean): TArray<Double>;
var
  R, C: Integer;
begin
  Result := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1];
  for R := 0 to 2 do
    for C := 0 to 2 do
      if AInverse then
        Result[C * 4 + R] := M[C, R] // the transpose
      else
        Result[C * 4 + R] := M[R, C];
end;

function Mat4Mul(const A, B: TArray<Double>): TArray<Double>;
var
  R, C, K: Integer;
  S: Double;
begin
  SetLength(Result, 16);
  for C := 0 to 3 do
    for R := 0 to 3 do
    begin
      S := 0;
      for K := 0 to 3 do
        S := S + A[K * 4 + R] * B[C * 4 + K];
      Result[C * 4 + R] := S;
    end;
end;

// A node's TRS as a column-major matrix
function TRSMatrix(const T, Q, S: TArray<Double>): TArray<Double>;
var
  LQuat: TQuat;
  LMat: TMat3;
  R, C: Integer;
begin
  LQuat[0] := Q[0];
  LQuat[1] := Q[1];
  LQuat[2] := Q[2];
  LQuat[3] := Q[3];
  LMat := MatFromQuat(LQuat);
  SetLength(Result, 16);
  for C := 0 to 2 do
  begin
    for R := 0 to 2 do
      Result[C * 4 + R] := LMat[R, C] * S[C];
    Result[C * 4 + 3] := 0;
  end;
  Result[12] := T[0];
  Result[13] := T[1];
  Result[14] := T[2];
  Result[15] := 1;
end;

function IsIdentityMatrix(const M: TArray<Double>): Boolean;
var
  I: Integer;
begin
  Result := Length(M) = 16;
  if Result then
    for I := 0 to 15 do
      if M[I] <> IfThen((I mod 5) = 0, 1, 0) then
        Exit(False);
end;

{ Reading and writing elements }

function ComponentSize(AComponentType: Integer): Integer;
begin
  case AComponentType of
    GLTF_COMPONENT_BYTE, GLTF_COMPONENT_UNSIGNED_BYTE: Result := 1;
    GLTF_COMPONENT_SHORT, GLTF_COMPONENT_UNSIGNED_SHORT: Result := 2;
  else
    Result := 4;
  end;
end;

function ReadValue(const AData: TBytes; AOffset: Int64; AType: Integer;
  ANormalized: Boolean): Double;
var
  LShortInt: ShortInt;
  LSmallInt: SmallInt;
  LWord: Word;
  LCardinal: Cardinal;
  LSingle: Single;
begin
  case AType of
    GLTF_COMPONENT_BYTE:
    begin
      LShortInt := ShortInt(AData[AOffset]);
      if ANormalized then
        Result := Max(LShortInt / 127, -1)
      else
        Result := LShortInt;
    end;
    GLTF_COMPONENT_UNSIGNED_BYTE:
      if ANormalized then
        Result := AData[AOffset] / 255
      else
        Result := AData[AOffset];
    GLTF_COMPONENT_SHORT:
    begin
      Move(AData[AOffset], LSmallInt, 2);
      if ANormalized then
        Result := Max(LSmallInt / 32767, -1)
      else
        Result := LSmallInt;
    end;
    GLTF_COMPONENT_UNSIGNED_SHORT:
    begin
      Move(AData[AOffset], LWord, 2);
      if ANormalized then
        Result := LWord / 65535
      else
        Result := LWord;
    end;
    GLTF_COMPONENT_UNSIGNED_INT:
    begin
      Move(AData[AOffset], LCardinal, 4);
      Result := LCardinal;
    end;
  else
    Move(AData[AOffset], LSingle, 4);
    Result := LSingle;
  end;
end;

// Writes a value, quantizing it for integer types; True when it had to be
// clamped to the type's range
function WriteValue(var AData: TBytes; AOffset: Int64; AType: Integer; ANormalized: Boolean;
  AValue: Double): Boolean;
var
  LInt: Int64;
  LSmallInt: SmallInt;
  LWord: Word;
  LCardinal: Cardinal;
  LSingle: Single;
  LClamped: Boolean;

  function Quantize(AScale, ALow, AHigh: Double): Int64;
  var
    LValue: Double;
  begin
    if ANormalized then
      LValue := Round(AValue * AScale)
    else
      LValue := Round(AValue);
    Result := Round(EnsureRange(LValue, ALow, AHigh));
    if (LValue < ALow) or (LValue > AHigh) then
      LClamped := True;
  end;

begin
  LClamped := False;
  case AType of
    GLTF_COMPONENT_BYTE:
    begin
      LInt := Quantize(127, -128, 127);
      AData[AOffset] := Byte(ShortInt(LInt));
    end;
    GLTF_COMPONENT_UNSIGNED_BYTE:
    begin
      LInt := Quantize(255, 0, 255);
      AData[AOffset] := Byte(LInt);
    end;
    GLTF_COMPONENT_SHORT:
    begin
      LSmallInt := SmallInt(Quantize(32767, -32768, 32767));
      Move(LSmallInt, AData[AOffset], 2);
    end;
    GLTF_COMPONENT_UNSIGNED_SHORT:
    begin
      LWord := Word(Quantize(65535, 0, 65535));
      Move(LWord, AData[AOffset], 2);
    end;
    GLTF_COMPONENT_UNSIGNED_INT:
    begin
      LCardinal := Cardinal(Quantize(1, 0, High(Cardinal)));
      Move(LCardinal, AData[AOffset], 4);
    end;
  else
    LSingle := AValue;
    Move(LSingle, AData[AOffset], 4);
  end;
  Result := LClamped;
end;

{ TReorientJob }

constructor TReorientJob.Create(ARoot: TglTF; AX, AY, AZ: Double; AWarnings: TStrings);
var
  R, C: Integer;
begin
  inherited Create;
  FRoot := ARoot;
  FWarnings := AWarnings;
  FQuat := TurnQuat(AX, AY, AZ);
  FInverse := FQuat;
  FInverse[0] := -FQuat[0];
  FInverse[1] := -FQuat[1];
  FInverse[2] := -FQuat[2];
  FMat := MatFromQuat(FQuat);
  // A turn that only swaps axes (multiples of 90 degrees) keeps any scale
  // a scale along the axes
  FAxisAligned := True;
  for R := 0 to 2 do
    for C := 0 to 2 do
      if (FMat[R, C] <> 0) and (Abs(FMat[R, C]) <> 1) then
        FAxisAligned := False;
  FCopied := TList<Integer>.Create;
  FDone := TDictionary<Integer, string>.Create;
end;

destructor TReorientJob.Destroy;
begin
  FDone.Free;
  FCopied.Free;
  inherited;
end;

procedure TReorientJob.Warn(const AText: string);
begin
  if Assigned(FWarnings) and (FWarnings.IndexOf(AText) < 0) then
    FWarnings.Add(AText);
end;

function TReorientJob.OwnData(ABuffer: Integer): TBytes;
begin
  // Copied once before the first change: the array may be shared with the
  // document the tree was copied from
  if not FCopied.Contains(ABuffer) then
  begin
    FRoot.Buffers[ABuffer].Data := Copy(FRoot.Buffers[ABuffer].Data);
    FCopied.Add(ABuffer);
  end;
  Result := FRoot.Buffers[ABuffer].Data;
end;

procedure TReorientJob.VisitView(AAccessor: TglTFAccessor; AView: Integer; AByteOffset: Int64;
  ACount, AStride: Integer; const AProc: TElementProc);
var
  LView: TglTFBufferView;
  LData: TBytes;
  LValues: TArray<Double>;
  LComponents, LSize, I, C: Integer;
  LBase, LOffset: Int64;
begin
  if (AView < 0) or (AView >= FRoot.BufferViews.Count) or (ACount <= 0) then
    Exit;
  LView := FRoot.BufferViews[AView];
  if (LView.Buffer < 0) or (LView.Buffer >= FRoot.Buffers.Count) or
     (FRoot.Buffers[LView.Buffer].Data = nil) then
    raise EglTFError.CreateFmt('Cannot re-orient: the data of bufferView %d is not available',
      [AView]);
  LComponents := AAccessor.ComponentCount;
  LSize := ComponentSize(AAccessor.ComponentType);
  if AStride <= 0 then
    AStride := LSize * LComponents;
  LBase := LView.ByteOffset + AByteOffset;
  if LBase + Int64(ACount - 1) * AStride + LSize * LComponents >
     Length(FRoot.Buffers[LView.Buffer].Data) then
    raise EglTFError.CreateFmt('Cannot re-orient: bufferView %d lies outside its buffer', [AView]);

  LData := OwnData(LView.Buffer);
  SetLength(LValues, LComponents);
  for I := 0 to ACount - 1 do
  begin
    LOffset := LBase + Int64(I) * AStride;
    for C := 0 to LComponents - 1 do
      LValues[C] := ReadValue(LData, LOffset + C * LSize, AAccessor.ComponentType,
        AAccessor.Normalized);
    AProc(LValues);
    for C := 0 to LComponents - 1 do
      if WriteValue(LData, LOffset + C * LSize, AAccessor.ComponentType, AAccessor.Normalized,
         LValues[C]) then
        FClamped := True;
  end;
end;

procedure TReorientJob.VisitElements(AAccessor: Integer; const AProc: TElementProc);
var
  LAccessor: TglTFAccessor;
  LStride: Integer;
begin
  LAccessor := FRoot.Accessors[AAccessor];
  FClamped := False;
  // The elements themselves, then the sparse replacements: the turn is
  // linear, so turning both gives the turned accessor
  if LAccessor.BufferView <> GLTF_UNDEFINED_INDEX then
  begin
    LStride := 0;
    if (LAccessor.BufferView >= 0) and (LAccessor.BufferView < FRoot.BufferViews.Count) then
      LStride := FRoot.BufferViews[LAccessor.BufferView].ByteStride;
    VisitView(LAccessor, LAccessor.BufferView, LAccessor.ByteOffset, LAccessor.Count, LStride,
      AProc);
  end;
  if Assigned(LAccessor.Sparse) and Assigned(LAccessor.Sparse.Values) then
    VisitView(LAccessor, LAccessor.Sparse.Values.BufferView, LAccessor.Sparse.Values.ByteOffset,
      LAccessor.Sparse.Count, 0, AProc);
  if FClamped then
    Warn(Format('Accessor %d: some turned values did not fit its component type and were ' +
      'clamped', [AAccessor]));
end;

function TReorientJob.Claim(AAccessor: Integer; const AKind: string): Boolean;
var
  LKind: string;
begin
  // Each accessor is turned once; one used in two ways that need different
  // turns can only get the first
  if (AAccessor < 0) or (AAccessor >= FRoot.Accessors.Count) then
    Exit(False);
  if FDone.TryGetValue(AAccessor, LKind) then
  begin
    if LKind <> AKind then
      Warn(Format('Accessor %d is used in two ways that need different turns; it was turned ' +
        'for its first use only', [AAccessor]));
    Exit(False);
  end;
  FDone.Add(AAccessor, AKind);
  Result := True;
end;

function TReorientJob.TurnVector(const AVector: array of Double): TArray<Double>;
var
  R: Integer;
begin
  SetLength(Result, 3);
  for R := 0 to 2 do
    Result[R] := FMat[R, 0] * AVector[0] + FMat[R, 1] * AVector[1] + FMat[R, 2] * AVector[2];
end;

function TReorientJob.TurnScale(var AScale: array of Double): Boolean;
var
  LScale: array[0..2] of Double;
  R, C: Integer;
begin
  // R S R^-1 is a scale along the axes only when the turn swaps axes, or
  // when the scale is the same along every axis
  if (Abs(AScale[0] - AScale[1]) < EPSILON) and (Abs(AScale[0] - AScale[2]) < EPSILON) then
    Exit(True);
  if not FAxisAligned then
    Exit(False);
  for R := 0 to 2 do
  begin
    LScale[R] := 0;
    for C := 0 to 2 do
      LScale[R] := LScale[R] + Sqr(FMat[R, C]) * AScale[C];
  end;
  for R := 0 to 2 do
    AScale[R] := LScale[R];
  Result := True;
end;

procedure TReorientJob.RecomputeMinMax(AAccessor: Integer);
var
  LAccessor: TglTFAccessor;
  LMin, LMax: TArray<Double>;
  LFirst: Boolean;
  LComponents, C: Integer;
begin
  LAccessor := FRoot.Accessors[AAccessor];
  if (Length(LAccessor.Min) = 0) and (Length(LAccessor.Max) = 0) then
    Exit;
  if LAccessor.ComponentType <> GLTF_COMPONENT_FLOAT then
  begin
    Warn(Format('Accessor %d: its min and max were not recomputed, as its values are not ' +
      'floats', [AAccessor]));
    Exit;
  end;
  LComponents := LAccessor.ComponentCount;
  SetLength(LMin, LComponents);
  SetLength(LMax, LComponents);
  LFirst := True;
  // Visiting with a procedure that changes nothing reads every element
  VisitElements(AAccessor,
    procedure(var AValues: TArray<Double>)
    var
      K: Integer;
    begin
      for K := 0 to High(AValues) do
        if LFirst then
        begin
          LMin[K] := AValues[K];
          LMax[K] := AValues[K];
        end
        else
        begin
          LMin[K] := Min(LMin[K], AValues[K]);
          LMax[K] := Max(LMax[K], AValues[K]);
        end;
      LFirst := False;
    end);
  if not LFirst then
  begin
    // Rounded the way the values are stored
    for C := 0 to LComponents - 1 do
    begin
      LMin[C] := Single(LMin[C]);
      LMax[C] := Single(LMax[C]);
    end;
    LAccessor.Min := LMin;
    LAccessor.Max := LMax;
  end;
end;

procedure TReorientJob.TurnVectors(AAccessor: Integer; const AKind: string);
begin
  if not Claim(AAccessor, AKind) then
    Exit;
  // The first three components are a direction or a position; a tangent's
  // fourth, its handedness, does not change
  VisitElements(AAccessor,
    procedure(var AValues: TArray<Double>)
    var
      LTurned: TArray<Double>;
    begin
      if Length(AValues) < 3 then
        Exit;
      LTurned := TurnVector(AValues);
      AValues[0] := LTurned[0];
      AValues[1] := LTurned[1];
      AValues[2] := LTurned[2];
    end);
  RecomputeMinMax(AAccessor);
end;

procedure TReorientJob.TurnMeshes;
const
  TURNED_ATTRIBUTES: array[0..2] of string = ('POSITION', 'NORMAL', 'TANGENT');
var
  LMesh: TglTFMesh;
  LPrimitive: TglTFMeshPrimitive;
  LTarget: TglTFAttributeMap;
  LName: string;
  LIndex: Integer;
begin
  for LMesh in FRoot.Meshes do
    for LPrimitive in LMesh.Primitives do
      for LName in TURNED_ATTRIBUTES do
      begin
        if LPrimitive.Attributes.TryGetValue(LName, LIndex) then
          TurnVectors(LIndex, 'vector');
        for LTarget in LPrimitive.Targets do
          if LTarget.TryGetValue(LName, LIndex) then
            TurnVectors(LIndex, 'vector');
      end;
end;

procedure TReorientJob.TurnSkins(const ATurns: TArray<TNodeTurn>);
var
  LSkin: TglTFSkin;
  LJoints: TArray<Integer>;
  LInverse, LTurn: TArray<Double>;
  LElement: Integer;
begin
  // The joint matrices W' IBM' must turn the turned vertices as W IBM did
  // the original ones: IBM' = (R or 1) IBM R^-1
  LTurn := Mat4(FMat, False);
  LInverse := Mat4(FMat, True);
  for LSkin in FRoot.Skins do
  begin
    if LSkin.InverseBindMatrices = GLTF_UNDEFINED_INDEX then
    begin
      Warn('A skin without inverse bind matrices cannot keep its bind pose when turned');
      Continue;
    end;
    if not Claim(LSkin.InverseBindMatrices, 'ibm') then
      Continue;
    LJoints := LSkin.Joints;
    LElement := 0;
    VisitElements(LSkin.InverseBindMatrices,
      procedure(var AValues: TArray<Double>)
      var
        LJointTurnsRight: Boolean;
      begin
        LJointTurnsRight := True;
        if (LElement < Length(LJoints)) and (LJoints[LElement] >= 0) and
           (LJoints[LElement] < Length(ATurns)) then
          LJointTurnsRight := ATurns[LJoints[LElement]].Right;
        if LJointTurnsRight then
          AValues := Mat4Mul(Mat4Mul(LTurn, AValues), LInverse)
        else
          AValues := Mat4Mul(AValues, LInverse);
        Inc(LElement);
      end);
  end;
end;

procedure TReorientJob.TurnNodesAndAnimations;
var
  LTurns: TArray<TNodeTurn>;
  LParents: TArray<Integer>;
  LAnimated: TArray<Boolean>;
  LNode: TglTFNode;
  LAnimation: TglTFAnimation;
  LChannel: TglTFAnimationChannel;
  LSampler: TglTFAnimationSampler;
  LIdentity: TQuat;
  LQ: TQuat;
  LT, LR, LS, LMatrix: TArray<Double>;
  LTurn: TNodeTurn;
  LKind: string;
  LLeftQuat, LRightQuat: TQuat;
  I, LChild, N: Integer;

  // The quaternions of a node's turn: L' = A L B
  procedure TurnQuats(const ATurn: TNodeTurn; out ALeft, ARight: TQuat);
  begin
    if ATurn.Left then
      ALeft := FQuat
    else
      ALeft := LIdentity;
    if ATurn.Right then
      ARight := FInverse
    else
      ARight := LIdentity;
  end;

begin
  LIdentity[0] := 0;
  LIdentity[1] := 0;
  LIdentity[2] := 0;
  LIdentity[3] := 1;
  N := FRoot.Nodes.Count;

  // 1. Parents, and which nodes are animated
  SetLength(LParents, N);
  for I := 0 to N - 1 do
    LParents[I] := GLTF_UNDEFINED_INDEX;
  for I := 0 to N - 1 do
    for LChild in FRoot.Nodes[I].Children do
      if (LChild >= 0) and (LChild < N) then
        LParents[LChild] := I;
  SetLength(LAnimated, N);
  for LAnimation in FRoot.Animations do
    for LChannel in LAnimation.Channels do
      if (LChannel.Target.Node >= 0) and (LChannel.Target.Node < N) then
        LAnimated[LChannel.Target.Node] := True;

  // 2. Each node's turn. A node whose content is turned (a mesh, or nothing)
  //    gets R on its right, so its frame is turned with the model; a camera
  //    or light, whose content cannot be turned, keeps its own frame. Every
  //    node then gets R on its left when its parent's frame is turned, so
  //    that L' = (R or 1) L (R^-1 or 1)
  SetLength(LTurns, N);
  for I := 0 to N - 1 do
  begin
    LNode := FRoot.Nodes[I];
    LTurns[I].Right := not ((LNode.Camera <> GLTF_UNDEFINED_INDEX) or
      LNode.HasExtension('KHR_lights_punctual'));
    if not LTurns[I].Right and (LNode.Mesh <> GLTF_UNDEFINED_INDEX) then
    begin
      LTurns[I].Right := True;
      Warn(Format('Node %d has a mesh and a camera or light: the camera or light now points ' +
        'in a turned direction', [I]));
    end;
    if LNode.HasExtension('EXT_mesh_gpu_instancing') then
      Warn(Format('Node %d: the instances of EXT_mesh_gpu_instancing were not turned', [I]));
  end;
  for I := 0 to N - 1 do
    LTurns[I].Left := (LParents[I] = GLTF_UNDEFINED_INDEX) or LTurns[LParents[I]].Right;

  // 3. The transforms
  for I := 0 to N - 1 do
  begin
    LNode := FRoot.Nodes[I];
    LTurn := LTurns[I];
    if LNode.HasMatrix or not IsIdentityMatrix(LNode.Matrix) then
    begin
      LMatrix := LNode.Matrix;
      if LTurn.Left then
        LMatrix := Mat4Mul(Mat4(FMat, False), LMatrix);
      if LTurn.Right then
        LMatrix := Mat4Mul(LMatrix, Mat4(FMat, True));
      LNode.Matrix := LMatrix;
      Continue;
    end;

    LT := Copy(LNode.Translation);
    LR := Copy(LNode.Rotation);
    LS := Copy(LNode.Scale);
    if LTurn.Right and not TurnScale(LS) then
    begin
      if not LAnimated[I] then
      begin
        // Exact as a matrix: L' = A T R S B
        LMatrix := TRSMatrix(LNode.Translation, LNode.Rotation, LNode.Scale);
        if LTurn.Left then
          LMatrix := Mat4Mul(Mat4(FMat, False), LMatrix);
        LMatrix := Mat4Mul(LMatrix, Mat4(FMat, True));
        LNode.Matrix := LMatrix;
        LNode.Translation := [0, 0, 0];
        LNode.Rotation := [0, 0, 0, 1];
        LNode.Scale := [1, 1, 1];
        Continue;
      end;
      Warn(Format('Node %d: its scale differs per axis and is animated, so it cannot be turned ' +
        'exactly by this angle; turn by multiples of 90 degrees to keep it exact', [I]));
    end;
    if LTurn.Left then
      LT := TurnVector(LT);
    LQ[0] := LR[0];
    LQ[1] := LR[1];
    LQ[2] := LR[2];
    LQ[3] := LR[3];
    TurnQuats(LTurn, LLeftQuat, LRightQuat);
    LQ := QuatMul(LLeftQuat, QuatMul(LQ, LRightQuat));
    LNode.Translation := LT;
    LNode.Rotation := [LQ[0], LQ[1], LQ[2], LQ[3]];
    LNode.Scale := LS;
  end;

  // 4. Animations: the same turns on the key frames. The maps are linear, so
  //    CUBICSPLINE tangents are turned like the values
  for LAnimation in FRoot.Animations do
    for LChannel in LAnimation.Channels do
    begin
      if (LChannel.Target.Node < 0) or (LChannel.Target.Node >= N) or
         (LChannel.Sampler < 0) or (LChannel.Sampler >= LAnimation.Samplers.Count) then
        Continue;
      LTurn := LTurns[LChannel.Target.Node];
      TurnQuats(LTurn, LLeftQuat, LRightQuat);
      LSampler := LAnimation.Samplers[LChannel.Sampler];
      LKind := Format('%s %s %s', [LChannel.Target.Path, BoolToStr(LTurn.Left, True),
        BoolToStr(LTurn.Right, True)]);
      case LChannel.Target.AnimationPath of
        apTranslation:
          if LTurn.Left and Claim(LSampler.Output, LKind) then
            VisitElements(LSampler.Output,
              procedure(var AValues: TArray<Double>)
              var
                LTurned: TArray<Double>;
              begin
                LTurned := TurnVector(AValues);
                AValues[0] := LTurned[0];
                AValues[1] := LTurned[1];
                AValues[2] := LTurned[2];
              end);
        apRotation:
          if (LTurn.Left or LTurn.Right) and Claim(LSampler.Output, LKind) then
          begin
            VisitElements(LSampler.Output,
              procedure(var AValues: TArray<Double>)
              var
                LKey: TQuat;
              begin
                LKey[0] := AValues[0];
                LKey[1] := AValues[1];
                LKey[2] := AValues[2];
                LKey[3] := AValues[3];
                LKey := QuatMul(LLeftQuat, QuatMul(LKey, LRightQuat));
                AValues[0] := LKey[0];
                AValues[1] := LKey[1];
                AValues[2] := LKey[2];
                AValues[3] := LKey[3];
              end);
          end;
        apScale:
          if LTurn.Right and Claim(LSampler.Output, LKind) then
            VisitElements(LSampler.Output,
              procedure(var AValues: TArray<Double>)
              begin
                // Tangents of a uniform scale are uniform too, so the same
                // test applies to them
                if not TurnScale(AValues) then
                  Warn(Format('Animated scale of node %d differs per axis and cannot be ' +
                    'turned exactly by this angle', [LChannel.Target.Node]));
              end);
      end;
    end;

  TurnSkins(LTurns);
end;

procedure TReorientJob.Run;
begin
  TurnMeshes;
  TurnNodesAndAnimations;
end;

{ TglTFReorienter }

class function TglTFReorienter.IsIdentity(AX, AY, AZ: Double): Boolean;
var
  LQuat: TQuat;
begin
  if (AX = 0) and (AY = 0) and (AZ = 0) then
    Exit(True);
  // q and -q are the same turn
  LQuat := TurnQuat(AX, AY, AZ);
  Result := (Abs(LQuat[0]) < EPSILON) and (Abs(LQuat[1]) < EPSILON) and
    (Abs(LQuat[2]) < EPSILON);
end;

class procedure TglTFReorienter.Apply(ARoot: TglTF; AX, AY, AZ: Double; AWarnings: TStrings);
var
  LJob: TReorientJob;
begin
  if IsIdentity(AX, AY, AZ) then
    Exit;
  LJob := TReorientJob.Create(ARoot, AX, AY, AZ, AWarnings);
  try
    LJob.Run;
  finally
    LJob.Free;
  end;
end;

end.
