//** @abstract(Splits a file holding several models into one file per model.)
//**
//** Each root node of the default scene is a model, with all the nodes under it. Roots tied
//** together by a skin, a mesh under one root deformed by joints under another, stay together
//** as one model. @link(TglTFModelSplitter) lists the models, then saves each one as a file
//** of its own, holding only what that model uses: its nodes, meshes, materials, textures,
//** images, skins, the animation channels that move its nodes, and only their bytes.
//**
//** Each model's origin is checked against its bounding box. When the origin is inside the
//** model or near it @(within a quarter of the model's largest size@), as with a character
//** whose origin is at its feet, it stays. When it is far away, as when every model of a sheet
//** shares one origin, the model is moved so that the centre of its bounding box is its
//** origin: the shift goes into its root nodes, or, when a root's position is animated, into
//** a new parent node, so the animation is kept as it is.
//**
//** With @link(TglTFModelSplitter.ScaleUp), the default, models too small are scaled up: when
//** any model measures less than 1 unit along any axis, every model is scaled by the same
//** factor, so that the smallest size of any model along any axis becomes exactly 1 and the
//** models keep their sizes relative to each other. A size of nothing, such as the thickness of
//** a flat plane, is not counted. The scale goes where the shift goes: into the root nodes, or
//** into the new parent node when a root's position or scale is animated.
//**
//** A model is named after its first root node, made safe for a file name, or model_NNN when
//** that has no name. A name another model already has, or a file already in the output
//** folder, gets a sequential suffix: walk_1, walk_2 and so on; no file is replaced. Saving
//** follows the rules of @code(TglTFDocument.SaveToFile).
//**
//** The work is meant for a background thread: @link(TglTFModelSplitter.OnProgress) reports
//** each model and @link(TglTFModelSplitter.RequestAbort) stops after the model being saved.
//** The document must not change while the splitter runs.
unit glTF.ModelSplit;

{
  Splits a file holding several models into one file per model.

  Each root node of the default scene is a model, with all the nodes under
  it. Roots tied together by a skin, a mesh under one root deformed by joints
  under another, stay together as one model. TglTFModelSplitter lists the
  models, then saves each one as a file of its own, holding only what that
  model uses: its nodes, meshes, materials, textures, images, skins, the
  animation channels that move its nodes, and only their bytes.

  Each model's origin is checked against its bounding box. When the origin is
  inside the model or near it (within a quarter of the model's largest size),
  as with a character whose origin is at its feet, it stays. When it is far
  away, as when every model of a sheet shares one origin, the model is moved
  so that the centre of its bounding box is its origin: the shift goes into
  its root nodes, or, when a root's position is animated, into a new parent
  node, so the animation is kept as it is.

  With ScaleUp, the default, models too small are scaled up: when any model
  measures less than 1 unit along any axis, every model is scaled by the same
  factor, so that the smallest size of any model along any axis becomes
  exactly 1 and the models keep their sizes relative to each other. A size of
  nothing, such as the thickness of a flat plane, is not counted. The scale
  goes where the shift goes: into the root nodes, or into the new parent node
  when a root's position or scale is animated.

  A model is named after its first root node, made safe for a file name, or
  model_NNN when that has no name. A name another model already has, or a
  file already in the output folder, gets a sequential suffix: walk_1,
  walk_2 and so on; no file is replaced. Saving follows the rules of
  TglTFDocument.SaveToFile.

  The work is meant for a background thread: OnProgress reports each model
  and RequestAbort stops after the model being saved. The document must not
  change while the splitter runs.
}

interface

uses
  System.SysUtils, System.Classes, System.Math, System.IOUtils,
  System.Generics.Collections,

  glTF.Base, glTF.Classes, glTF.Document;

type
  //** @abstract(One model found in the file.)
  TglTFSplitModel = record
    //** @abstract(The name it is saved under, without extension: unique among the models,
    //** safe for a file name; a file already in the output folder may still add a suffix.)
    Name: string;

    //** @abstract(Its root nodes, in the default scene's order; usually one.)
    Roots: TArray<Integer>;

    //** @abstract(Its nodes: the roots, everything under them and the joints its skins use.)
    Nodes: TArray<Integer>;

    //** @abstract(How many of its nodes have a mesh.)
    MeshNodes: Integer;

    //** @abstract(Triangles in its meshes, counting a mesh once per node that shows it.)
    Triangles: Int64;

    //** @abstract(Whether it has a bounding box: False when no mesh gives positions.)
    HasBounds: Boolean;

    //** @abstract(The centre of its bounding box, in the scene's space.)
    Centre: array[0..2] of Double;

    //** @abstract(The size of its bounding box along X, Y and Z, in the scene's space.)
    Size: array[0..2] of Double;

    //** @abstract(Whether it is moved so that its centre is its origin.)
    Recentre: Boolean;
  end;

  //** @abstract(Lists the models in a document and saves each as a file of its own.)
  //**
  //** Call @link(FindModels), then @link(Run), usually from a background thread; read
  //** @link(Log) and the counts afterwards.
  TglTFModelSplitter = class
  private
    FDoc: TglTFDocument;
    FModels: TArray<TglTFSplitModel>;
    FLog: TStringList;
    FSaved: Integer;
    FFailed: Integer;
    FCurrent: Integer;
    FAbortRequested: Boolean;
    FScaleUp: Boolean;
    FScale: Double;
    FOnProgress: TglTFProgressEvent;
    procedure Report(const AStage: string; ADone: Double);
    procedure DocumentProgress(Sender: TObject; const AProgress: TglTFProgress);
    procedure Measure(var AModel: TglTFSplitModel; const AWorld: TArray<TArray<Double>>);
    function BuildModel(AIndex: Integer): TglTFDocument;
    procedure Place(ACopy: TglTFDocument; const AModel: TglTFSplitModel);
  public
    //** @abstract(Creates the splitter for a document.)
    //**
    //** @param(ADoc The document holding the models; not owned, and not changed.)
    constructor Create(ADoc: TglTFDocument);

    //** @abstract(Frees the splitter.)
    destructor Destroy; override;

    //** @abstract(Turns a node name into a name safe for a file.)
    //**
    //** Characters no file system accepts, \ / : * ? " < > | and control characters, become
    //** underscores, and spaces and dots at either end are removed.
    //**
    //** @param(AName The node name.)
    //**
    //** @returns(The safe name; empty when nothing is left.)
    class function SafeFileName(const AName: string): string; static;

    //** @abstract(Finds the models: the root nodes of the default scene, with what is under
    //** them.)
    //**
    //** Without scenes, the nodes no other node has as a child are the roots. Each model is
    //** measured, told whether it will be moved to its centre, and named; then @link(Scale)
    //** is worked out, as @link(ScaleUp) says.
    //**
    //** @returns(The number of models; see @link(Models).)
    function FindModels: Integer;

    //** @abstract(Returns the file a model would be saved to, with a suffix when the name is
    //** taken.)
    //**
    //** @param(AFolder The output folder.)
    //**
    //** @param(AName The model's name.)
    //**
    //** @param(AFormat gffGLB or gffJSON.)
    //**
    //** @param(ATaken Files already chosen in this run, lower case; the file is added.)
    //**
    //** @returns(The full path of a file that does not exist yet.)
    class function FreeFileName(const AFolder, AName: string; AFormat: TglTFFileFormat;
      ATaken: TStrings): string; static;

    //** @abstract(Saves every model found in a folder, one file each.)
    //**
    //** Each model is made from a copy of the document, cut down to what the model uses,
    //** moved to its centre when @code(Recentre) says so, and saved with AOptions. A failure
    //** is logged and counted, and the next model is done. Stops early, after the model being
    //** saved, when @link(RequestAbort) was called.
    //**
    //** @param(AFolder The output folder; created when needed.)
    //**
    //** @param(AFormat gffGLB or gffJSON.)
    //**
    //** @param(AOptions The save options, such as the turn and the EXIF choice.)
    //**
    //** @returns(The number of models saved.)
    function Run(const AFolder: string; AFormat: TglTFFileFormat;
      const AOptions: TglTFSaveOptions): Integer;

    //** @abstract(Asks Run to stop after the model it is on; may be called from any thread.)
    procedure RequestAbort;

    //** @abstract(The models found by FindModels.)
    property Models: TArray<TglTFSplitModel> read FModels;

    //** @abstract(One line per model saved and per warning, for the user.)
    property Log: TStringList read FLog;

    //** @abstract(The models Run saved.)
    property Saved: Integer read FSaved;

    //** @abstract(The models Run could not save.)
    property Failed: Integer read FFailed;

    //** @abstract(Whether RequestAbort was called.)
    property AbortRequested: Boolean read FAbortRequested;

    //** @abstract(Whether models smaller than 1 unit along any axis are scaled up; True by
    //** default. Set it before FindModels.)
    property ScaleUp: Boolean read FScaleUp write FScaleUp;

    //** @abstract(The factor every model is scaled by, worked out by FindModels: 1 when none is
    //** smaller than 1 unit along any axis, or when ScaleUp is off.)
    property Scale: Double read FScale;

    //** @abstract(Reports each model and how far its save has got; called on the thread that
    //** runs Run.)
    property OnProgress: TglTFProgressEvent read FOnProgress write FOnProgress;
  end;

implementation

uses
  glTF.Edit;

const
  // A model whose origin is further than this share of its largest size from
  // its bounding box is moved to its centre
  NEAR_SHARE = 0.25;

  // A model's size along an axis below this share of its largest size is
  // taken as no size at all, as with the thickness of a flat plane
  SIZE_OF_NOTHING = 1e-6;

type
  TMat4 = array[0..15] of Double; // column-major, as glTF

function Identity: TMat4;
var
  I: Integer;
begin
  for I := 0 to 15 do
    Result[I] := 0;
  Result[0] := 1;
  Result[5] := 1;
  Result[10] := 1;
  Result[15] := 1;
end;

function Mul(const A, B: TMat4): TMat4;
var
  R, C, K: Integer;
  S: Double;
begin
  for C := 0 to 3 do
    for R := 0 to 3 do
    begin
      S := 0;
      for K := 0 to 3 do
        S := S + A[K * 4 + R] * B[C * 4 + K];
      Result[C * 4 + R] := S;
    end;
end;

function IsIdentity(const AValues: TArray<Double>): Boolean;
var
  LIdentity: TMat4;
  I: Integer;
begin
  if Length(AValues) <> 16 then
    Exit(True);
  LIdentity := Identity;
  for I := 0 to 15 do
    if AValues[I] <> LIdentity[I] then
      Exit(False);
  Result := True;
end;

// A node's own transform: its matrix, or T * R * S
function LocalMatrix(ANode: TglTFNode): TMat4;
var
  T, R, S: TArray<Double>;
  X, Y, Z, W: Double;
  I: Integer;
begin
  if not IsIdentity(ANode.Matrix) then
  begin
    for I := 0 to 15 do
      Result[I] := ANode.Matrix[I];
    Exit;
  end;
  T := ANode.Translation;
  R := ANode.Rotation;
  S := ANode.Scale;
  if Length(T) <> 3 then
    T := [0, 0, 0];
  if Length(R) <> 4 then
    R := [0, 0, 0, 1];
  if Length(S) <> 3 then
    S := [1, 1, 1];
  X := R[0];
  Y := R[1];
  Z := R[2];
  W := R[3];
  Result[0] := (1 - 2 * (Y * Y + Z * Z)) * S[0];
  Result[1] := (2 * (X * Y + Z * W)) * S[0];
  Result[2] := (2 * (X * Z - Y * W)) * S[0];
  Result[3] := 0;
  Result[4] := (2 * (X * Y - Z * W)) * S[1];
  Result[5] := (1 - 2 * (X * X + Z * Z)) * S[1];
  Result[6] := (2 * (Y * Z + X * W)) * S[1];
  Result[7] := 0;
  Result[8] := (2 * (X * Z + Y * W)) * S[2];
  Result[9] := (2 * (Y * Z - X * W)) * S[2];
  Result[10] := (1 - 2 * (X * X + Y * Y)) * S[2];
  Result[11] := 0;
  Result[12] := T[0];
  Result[13] := T[1];
  Result[14] := T[2];
  Result[15] := 1;
end;

{ TglTFModelSplitter }

constructor TglTFModelSplitter.Create(ADoc: TglTFDocument);
begin
  inherited Create;
  FDoc := ADoc;
  FLog := TStringList.Create;
  FScaleUp := True;
  FScale := 1;
end;

destructor TglTFModelSplitter.Destroy;
begin
  FLog.Free;
  inherited;
end;

class function TglTFModelSplitter.SafeFileName(const AName: string): string;
var
  I: Integer;
begin
  Result := AName;
  for I := 1 to Length(Result) do
    if (Result[I] < ' ') or CharInSet(Result[I], ['\', '/', ':', '*', '?', '"', '<', '>', '|']) then
      Result[I] := '_';
  Result := Trim(Result);
  while (Result <> '') and CharInSet(Result[1], ['.', ' ']) do
    Delete(Result, 1, 1);
  while (Result <> '') and CharInSet(Result[Length(Result)], ['.', ' ']) do
    Delete(Result, Length(Result), 1);
end;

class function TglTFModelSplitter.FreeFileName(const AFolder, AName: string;
  AFormat: TglTFFileFormat; ATaken: TStrings): string;
var
  LExt: string;
  LSuffix: Integer;
begin
  if AFormat = gffJSON then
    LExt := '.gltf'
  else
    LExt := '.glb';
  // walk.glb, else walk_1.glb, walk_2.glb...: an existing model is never
  // replaced
  Result := TPath.Combine(AFolder, AName + LExt);
  LSuffix := 0;
  while TFile.Exists(Result) or (ATaken.IndexOf(AnsiLowerCase(Result)) >= 0) do
  begin
    Inc(LSuffix);
    Result := TPath.Combine(AFolder, Format('%s_%d%s', [AName, LSuffix, LExt]));
  end;
  ATaken.Add(AnsiLowerCase(Result));
end;

procedure TglTFModelSplitter.Measure(var AModel: TglTFSplitModel;
  const AWorld: TArray<TArray<Double>>);
var
  LRoot: TglTF;
  LNode: TglTFNode;
  LPrimitive: TglTFMeshPrimitive;
  LAccessor: TglTFAccessor;
  LMin, LMax, LOrigin: array[0..2] of Double;
  LCorner: array[0..2] of Double;
  LMat: TArray<Double>;
  LLargest, LMargin, V: Double;
  I, A, K, LPosition, LIndices: Integer;
begin
  LRoot := FDoc.Root;
  AModel.HasBounds := False;
  AModel.MeshNodes := 0;
  AModel.Triangles := 0;
  for A := 0 to 2 do
  begin
    LMin[A] := MaxDouble;
    LMax[A] := -MaxDouble;
  end;
  for I in AModel.Nodes do
  begin
    LNode := LRoot.Nodes[I];
    if (LNode.Mesh < 0) or (LNode.Mesh >= LRoot.Meshes.Count) then
      Continue;
    Inc(AModel.MeshNodes);
    LMat := AWorld[I];
    for LPrimitive in LRoot.Meshes[LNode.Mesh].Primitives do
    begin
      // Triangles, for the list: triangle lists only
      if LPrimitive.Mode = 4 then
      begin
        LIndices := LPrimitive.Indices;
        if (LIndices >= 0) and (LIndices < LRoot.Accessors.Count) then
          Inc(AModel.Triangles, LRoot.Accessors[LIndices].Count div 3)
        else if LPrimitive.HasAttribute('POSITION') then
        begin
          LPosition := LPrimitive.GetAttribute('POSITION');
          if (LPosition >= 0) and (LPosition < LRoot.Accessors.Count) then
            Inc(AModel.Triangles, LRoot.Accessors[LPosition].Count div 3);
        end;
      end;
      if not LPrimitive.HasAttribute('POSITION') then
        Continue;
      LPosition := LPrimitive.GetAttribute('POSITION');
      if (LPosition < 0) or (LPosition >= LRoot.Accessors.Count) then
        Continue;
      LAccessor := LRoot.Accessors[LPosition];
      if (Length(LAccessor.Min) < 3) or (Length(LAccessor.Max) < 3) then
        Continue;
      // The eight corners of the box, into the scene's space
      for K := 0 to 7 do
      begin
        for A := 0 to 2 do
          if (K shr A) and 1 = 0 then
            LCorner[A] := LAccessor.Min[A]
          else
            LCorner[A] := LAccessor.Max[A];
        for A := 0 to 2 do
        begin
          V := LMat[A] * LCorner[0] + LMat[4 + A] * LCorner[1] + LMat[8 + A] * LCorner[2] +
            LMat[12 + A];
          LMin[A] := Min(LMin[A], V);
          LMax[A] := Max(LMax[A], V);
        end;
        AModel.HasBounds := True;
      end;
    end;
  end;

  AModel.Recentre := False;
  if not AModel.HasBounds then
    Exit;
  LLargest := 0;
  for A := 0 to 2 do
  begin
    AModel.Centre[A] := (LMin[A] + LMax[A]) / 2;
    AModel.Size[A] := LMax[A] - LMin[A];
    LLargest := Max(LLargest, AModel.Size[A]);
  end;
  // The model's origin: its first root's position in the scene
  LMat := AWorld[AModel.Roots[0]];
  for A := 0 to 2 do
    LOrigin[A] := LMat[12 + A];
  // Inside the box, or near it, the origin stays; far away, the model is
  // moved to its centre
  LMargin := NEAR_SHARE * LLargest;
  for A := 0 to 2 do
    if (LOrigin[A] < LMin[A] - LMargin) or (LOrigin[A] > LMax[A] + LMargin) then
      AModel.Recentre := True;
end;

function TglTFModelSplitter.FindModels: Integer;
var
  LRoot: TglTF;
  LRoots, LStack, LOwner, LGroupOf: TArray<Integer>;
  LWorld: TArray<TArray<Double>>;
  LNames: TStringList;
  LIsChild: TArray<Boolean>;
  LScene, I, J, R, N, LGroup, LOther, LCount: Integer;
  LJoint: Integer;
  LNode: TglTFNode;
  LMat: TMat4;
  LName: string;
  LModel: TglTFSplitModel;
  LNodes: TList<Integer>;
  LSmallest, LLargest: Double;
  A: Integer;

  procedure AddWorld(ANode: Integer; const AParent: TMat4);
  var
    LLocal: TMat4;
    LChild, K: Integer;
  begin
    LLocal := Mul(AParent, LocalMatrix(LRoot.Nodes[ANode]));
    SetLength(LWorld[ANode], 16);
    for K := 0 to 15 do
      LWorld[ANode][K] := LLocal[K];
    for LChild in LRoot.Nodes[ANode].Children do
      if (LChild >= 0) and (LChild < LRoot.Nodes.Count) and (LWorld[LChild] = nil) then
        AddWorld(LChild, LLocal);
  end;

  function Find(AGroup: Integer): Integer;
  begin
    Result := AGroup;
    while LGroupOf[Result] <> Result do
      Result := LGroupOf[Result];
  end;

begin
  LRoot := FDoc.Root;
  FModels := nil;
  N := LRoot.Nodes.Count;

  // The roots: the default scene's, else the nodes no node has as a child
  LScene := LRoot.Scene;
  if (LScene < 0) or (LScene >= LRoot.Scenes.Count) then
    LScene := 0;
  LRoots := nil;
  if LScene < LRoot.Scenes.Count then
  begin
    for I in LRoot.Scenes[LScene].Nodes do
      if (I >= 0) and (I < N) then
        LRoots := LRoots + [I];
  end
  else
  begin
    SetLength(LIsChild, N);
    for LNode in LRoot.Nodes do
      for J in LNode.Children do
        if (J >= 0) and (J < N) then
          LIsChild[J] := True;
    for I := 0 to N - 1 do
      if not LIsChild[I] then
        LRoots := LRoots + [I];
  end;

  // Which root each node is under, and every node's place in the scene
  SetLength(LOwner, N);
  for I := 0 to N - 1 do
    LOwner[I] := -1;
  SetLength(LWorld, N);
  for R := 0 to High(LRoots) do
  begin
    LStack := [LRoots[R]];
    while Length(LStack) > 0 do
    begin
      I := LStack[High(LStack)];
      SetLength(LStack, Length(LStack) - 1);
      if LOwner[I] >= 0 then
        Continue; // already under another root
      LOwner[I] := R;
      for J in LRoot.Nodes[I].Children do
        if (J >= 0) and (J < N) then
          LStack := LStack + [J];
    end;
    if LWorld[LRoots[R]] = nil then
    begin
      LMat := Identity;
      AddWorld(LRoots[R], LMat);
    end;
  end;

  // Roots joined by a skin: a mesh under one root with joints under another
  SetLength(LGroupOf, Length(LRoots));
  for R := 0 to High(LRoots) do
    LGroupOf[R] := R;
  for I := 0 to N - 1 do
  begin
    LNode := LRoot.Nodes[I];
    if (LOwner[I] < 0) or (LNode.Skin < 0) or (LNode.Skin >= LRoot.Skins.Count) then
      Continue;
    for LJoint in LRoot.Skins[LNode.Skin].Joints + [LRoot.Skins[LNode.Skin].Skeleton] do
      if (LJoint >= 0) and (LJoint < N) and (LOwner[LJoint] >= 0) then
      begin
        LGroup := Find(LOwner[I]);
        LOther := Find(LOwner[LJoint]);
        if LGroup <> LOther then
          LGroupOf[Max(LGroup, LOther)] := Min(LGroup, LOther);
      end;
  end;

  // The models, in the order of their first roots
  LNames := TStringList.Create;
  try
    LCount := 0;
    for R := 0 to High(LRoots) do
      if Find(R) = R then
        Inc(LCount);
    SetLength(FModels, LCount);
    LCount := 0;
    for R := 0 to High(LRoots) do
      if Find(R) = R then
      begin
        LModel := Default(TglTFSplitModel);
        LNodes := TList<Integer>.Create;
        try
          for J := 0 to High(LRoots) do
            if Find(J) = R then
              LModel.Roots := LModel.Roots + [LRoots[J]];
          for I := 0 to N - 1 do
            if (LOwner[I] >= 0) and (Find(LOwner[I]) = R) then
              LNodes.Add(I);
          // Joints its skins use that are under no root at all
          for I := 0 to N - 1 do
            if (LOwner[I] >= 0) and (Find(LOwner[I]) = R) and (LRoot.Nodes[I].Skin >= 0) and
               (LRoot.Nodes[I].Skin < LRoot.Skins.Count) then
              for LJoint in LRoot.Skins[LRoot.Nodes[I].Skin].Joints do
                if (LJoint >= 0) and (LJoint < N) and (LOwner[LJoint] < 0) and
                   not LNodes.Contains(LJoint) then
                  LNodes.Add(LJoint);
          LModel.Nodes := LNodes.ToArray;
        finally
          LNodes.Free;
        end;
        // Nodes outside every scene have no place yet: as roots of their own
        for I in LModel.Nodes do
          if LWorld[I] = nil then
          begin
            LMat := Identity;
            AddWorld(I, LMat);
          end;
        Measure(LModel, LWorld);

        // Named after its first root, made unique among the models
        LName := SafeFileName(LRoot.Nodes[LModel.Roots[0]].Name);
        if LName = '' then
          LName := Format('model_%.3d', [LCount + 1]);
        J := 0;
        LModel.Name := LName;
        while LNames.IndexOf(AnsiLowerCase(LModel.Name)) >= 0 do
        begin
          Inc(J);
          LModel.Name := Format('%s_%d', [LName, J]);
        end;
        LNames.Add(AnsiLowerCase(LModel.Name));
        FModels[LCount] := LModel;
        Inc(LCount);
      end;
  finally
    LNames.Free;
  end;
  // One factor for every model, so they keep their sizes relative to each
  // other: the smallest size of any model along any axis becomes 1. A size
  // of nothing next to the model's largest (a flat plane) does not count
  FScale := 1;
  LSmallest := MaxDouble;
  for LModel in FModels do
    if LModel.HasBounds then
    begin
      LLargest := Max(LModel.Size[0], Max(LModel.Size[1], LModel.Size[2]));
      for A := 0 to 2 do
        if LModel.Size[A] > SIZE_OF_NOTHING * LLargest then
          LSmallest := Min(LSmallest, LModel.Size[A]);
    end;
  if FScaleUp and (LSmallest < 1) and (LSmallest > 0) then
    FScale := 1 / LSmallest;
  Result := Length(FModels);
end;

function TglTFModelSplitter.BuildModel(AIndex: Integer): TglTFDocument;
var
  LRoot: TglTF;
  LKeep: TArray<Boolean>;
  LDelete, LAll: TArray<Integer>;
  LScene, I: Integer;

  function Indices(ACount: Integer): TArray<Integer>;
  var
    K: Integer;
  begin
    SetLength(Result, ACount);
    for K := 0 to ACount - 1 do
      Result[K] := K;
  end;

begin
  // A copy of the whole document, cut down to the model
  Result := FDoc.CreateCopy;
  try
    LRoot := Result.Root;
    SetLength(LKeep, LRoot.Nodes.Count);
    for I in FModels[AIndex].Nodes do
      LKeep[I] := True;
    LDelete := nil;
    for I := 0 to LRoot.Nodes.Count - 1 do
      if not LKeep[I] then
        LDelete := LDelete + [I];

    // One scene: the default one, which now holds only this model's roots
    LScene := LRoot.Scene;
    if (LScene < 0) or (LScene >= LRoot.Scenes.Count) then
      LScene := 0;
    for I := LRoot.Scenes.Count - 1 downto 0 do
      if I <> LScene then
        LRoot.Scenes.Delete(I);
    if LRoot.Scenes.Count > 0 then
      LRoot.Scene := 0;

    // The other models' skins go first: a skin's joints cannot be deleted
    // while the skin is there
    for I in LDelete do
      LRoot.Nodes[I].Skin := GLTF_UNDEFINED_INDEX;
    TglTFEdit.DeleteUnusedObjects(LRoot, nil, Indices(LRoot.Skins.Count), nil, nil, FLog);

    // Then the nodes, with the animation channels that move them; then the
    // meshes and materials nothing uses, and what only they used
    TglTFEdit.DeleteNodes(LRoot, LDelete, FLog);
    LAll := Indices(LRoot.Meshes.Count);
    TglTFEdit.DeleteUnusedObjects(LRoot, LAll, Indices(LRoot.Skins.Count),
      Indices(LRoot.Materials.Count), nil, FLog);

    Place(Result, FModels[AIndex]);
  except
    Result.Free;
    raise;
  end;
end;

procedure TglTFModelSplitter.Place(ACopy: TglTFDocument; const AModel: TglTFSplitModel);
var
  LRoot: TglTF;
  LRoots: TArray<Integer>;
  LShift: array[0..2] of Double;
  LAnimated: Boolean;
  LAnimation: TglTFAnimation;
  LChannel: TglTFAnimationChannel;
  LNode, LParent: TglTFNode;
  LMatrix, LTranslation, LScale: TArray<Double>;
  I, A: Integer;
begin
  // Every point P of the model goes to Scale * (P + shift): the shift puts
  // the centre on the origin when the model is far from it
  for A := 0 to 2 do
    if AModel.Recentre then
      LShift[A] := -AModel.Centre[A]
    else
      LShift[A] := 0;
  if not AModel.Recentre and SameValue(FScale, 1) then
    Exit;
  LRoot := ACopy.Root;
  if LRoot.Scenes.Count = 0 then
    Exit;
  LRoots := LRoot.Scenes[0].Nodes;

  // A root whose position or scale is animated cannot simply be changed:
  // the animation would put it back. Then a new parent carries the change
  LAnimated := False;
  for LAnimation in LRoot.Animations do
    for LChannel in LAnimation.Channels do
      for I in LRoots do
        if (LChannel.Target.Node = I) and ((LChannel.Target.Path = 'translation') or
           (LChannel.Target.Path = 'scale')) then
          LAnimated := True;

  if LAnimated then
  begin
    LParent := TglTFNode.Create;
    LParent.Name := AModel.Name + '_origin';
    LParent.Translation := [FScale * LShift[0], FScale * LShift[1], FScale * LShift[2]];
    LParent.Scale := [FScale, FScale, FScale];
    LParent.Children := LRoots;
    LRoot.Nodes.Add(LParent);
    LRoot.Scenes[0].Nodes := [LRoot.Nodes.Count - 1];
    Exit;
  end;

  // Roots are in the scene's space: the shift is added to their position,
  // then position and size are scaled. A uniform scale leaves the rotation
  // as it is
  for I in LRoots do
  begin
    LNode := LRoot.Nodes[I];
    if not IsIdentity(LNode.Matrix) then
    begin
      LMatrix := Copy(LNode.Matrix);
      for A := 0 to 11 do
        if A mod 4 <> 3 then
          LMatrix[A] := LMatrix[A] * FScale;
      for A := 0 to 2 do
        LMatrix[12 + A] := FScale * (LMatrix[12 + A] + LShift[A]);
      LNode.Matrix := LMatrix;
    end
    else
    begin
      LTranslation := Copy(LNode.Translation);
      if Length(LTranslation) <> 3 then
        LTranslation := [0, 0, 0];
      LScale := Copy(LNode.Scale);
      if Length(LScale) <> 3 then
        LScale := [1, 1, 1];
      for A := 0 to 2 do
      begin
        LTranslation[A] := FScale * (LTranslation[A] + LShift[A]);
        LScale[A] := LScale[A] * FScale;
      end;
      LNode.Translation := LTranslation;
      LNode.Scale := LScale;
    end;
  end;
end;

procedure TglTFModelSplitter.RequestAbort;
begin
  FAbortRequested := True;
end;

procedure TglTFModelSplitter.Report(const AStage: string; ADone: Double);
var
  LProgress: TglTFProgress;
begin
  if not Assigned(FOnProgress) then
    Exit;
  LProgress.ModelIndex := FCurrent + 1;
  LProgress.ModelCount := Length(FModels);
  LProgress.ModelName := FModels[FCurrent].Name;
  LProgress.Stage := AStage;
  LProgress.Done := ADone;
  FOnProgress(Self, LProgress);
end;

procedure TglTFModelSplitter.DocumentProgress(Sender: TObject; const AProgress: TglTFProgress);
begin
  Report(AProgress.Stage, 0.3 + 0.7 * AProgress.Done);
end;

function TglTFModelSplitter.Run(const AFolder: string; AFormat: TglTFFileFormat;
  const AOptions: TglTFSaveOptions): Integer;
var
  LCopy: TglTFDocument;
  LTaken: TStringList;
  LTarget, LWarning, LNote: string;
  I: Integer;
begin
  FSaved := 0;
  FFailed := 0;
  ForceDirectories(AFolder);
  LTaken := TStringList.Create;
  try
    for I := 0 to High(FModels) do
    begin
      if FAbortRequested then
      begin
        FLog.Add(Format('Aborted: %d model(s) not saved', [Length(FModels) - I]));
        Break;
      end;
      FCurrent := I;
      Report('Separating', 0);
      try
        LCopy := BuildModel(I);
        try
          LTarget := FreeFileName(AFolder, FModels[I].Name, AFormat, LTaken);
          Report('Saving', 0.3);
          LCopy.OnProgress := DocumentProgress;
          LCopy.SaveToFile(LTarget, AOptions);
          LCopy.OnProgress := nil;
          Inc(FSaved);
          LNote := '';
          if not SameText(TPath.GetFileNameWithoutExtension(LTarget), FModels[I].Name) then
            LNote := ' (renamed: the name was already taken)';
          if FModels[I].Recentre then
            LNote := LNote + ' (moved so its centre is its origin)';
          if not SameValue(FScale, 1) then
            LNote := LNote + Format(' (scaled by %.6g)', [FScale]);
          FLog.Add(Format('Saved %s%s', [ExtractFileName(LTarget), LNote]));
          for LWarning in LCopy.SaveWarnings do
            FLog.Add('  Warning: ' + LWarning);
        finally
          LCopy.Free;
        end;
      except
        on E: Exception do
        begin
          Inc(FFailed);
          FLog.Add(Format('FAILED %s: %s', [FModels[I].Name, E.Message]));
        end;
      end;
      Report('Done', 1);
    end;
  finally
    LTaken.Free;
  end;
  Result := FSaved;
end;

end.
