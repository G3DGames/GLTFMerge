//** @abstract(Fills an FMX tree view with the structure of a glTF document.)
//**
//** Scenes show their full node hierarchy, with meshes, materials, textures and images resolved
//** inline; the default scene is shown in bold and expanded. Materials, textures and images
//** also get their own sections, including which objects use them. Every other top-level array
//** has a section too.
//**
//** The reader does not yet check that indices point to existing objects, so every reference is
//** range-checked here and shown with a warning sign when it is invalid. A node hierarchy that
//** loops is cut off with a warning instead of recursing for ever.
//**
//** Every tree item is a styled control, which FireMonkey is slow to create in large numbers,
//** so the long lists are cut off: the Nodes, Accessors and Buffer views sections after 250
//** entries and each animation after 30 channels, with a line saying how many more there are.
unit glTFViewer.Tree;

{
  Fills an FMX tree view with the structure of a glTF document.

  Scenes show their full node hierarchy, with meshes, materials, textures and
  images resolved inline; the default scene is shown in bold and expanded.
  Materials, textures and images also get their own sections, including which
  objects use them. Every other top-level array has a section too.

  The reader does not yet check that indices point to existing objects, so
  every reference is range-checked here and shown with a warning sign when it
  is invalid. A node hierarchy that loops is cut off with a warning instead of
  recursing for ever.

  Every tree item is a styled control, which FireMonkey is slow to create in
  large numbers, so the long lists are cut off: the Nodes, Accessors and
  Buffer views sections after 250 entries and each animation after 30
  channels, with a line saying how many more there are.
}

interface

uses
  System.SysUtils, System.Classes, System.UITypes, System.Generics.Collections,
  System.Generics.Defaults,
  FMX.Types, FMX.TreeView,

  glTF.Base, glTF.Classes, glTF.Document;

type
  //** @abstract(Builds the structure tree of a glTF document.)
  //**
  //** Use the class methods @link(Build) and @link(ShowMessage); an instance only lives while a
  //** tree is built. Must be used on the main thread.
  /// <summary>Builds the structure tree of a glTF document.</summary>
  /// <remarks>Use the class methods <see cref="Build"/> and <see cref="ShowMessage"/>; an
  /// instance only lives while a tree is built. Must be used on the main thread.</remarks>
  TglTFTreeBuilder = class
  private
    FTree: TTreeView;
    FDoc: TglTFDocument;
    FRoot: TglTF;
    // Nodes on the current branch, to stop on cyclic hierarchies
    FNodePath: TList<Integer>;

    function Add(AParent: TFmxObject; const AText: string): TTreeViewItem;
    function Section(AParent: TFmxObject; const ATitle: string; ACount: Integer): TTreeViewItem;
    procedure MakeBold(AItem: TTreeViewItem);
    procedure AddMeta(AParent: TFmxObject; AProp: TglTFProperty; const APrefix: string = '');

    function AccessorText(AIndex: Integer): string;
    function ImageSourceText(AImage: TglTFImage): string;
    function SamplerText(AIndex: Integer): string;
    function NodeParent(AIndex: Integer): Integer;
    function TextureUsers(ATexture: Integer): string;
    function ImageUsers(AImage: Integer): string;

    function AddNodeHierarchy(AParent: TFmxObject; AIndex: Integer): TTreeViewItem;
    procedure AddNodeContent(AItem: TTreeViewItem; ANode: TglTFNode; ARecursive: Boolean);
    procedure AddTransform(AItem: TTreeViewItem; ANode: TglTFNode);
    procedure AddMeshRef(AParent: TFmxObject; AIndex: Integer);
    procedure AddMeshContent(AItem: TTreeViewItem; AMesh: TglTFMesh);
    procedure AddMaterialRef(AParent: TFmxObject; AIndex: Integer);
    procedure AddMaterialContent(AItem: TTreeViewItem; AMaterial: TglTFMaterial);
    procedure AddTextureInfo(AParent: TFmxObject; const ASlot: string;
      AInfo: TglTFTextureInfo; const AExtra: string = '');
    procedure AddTextureContent(AItem: TTreeViewItem; AIndex: Integer);
    function AddImageRef(AParent: TFmxObject; AIndex: Integer): TTreeViewItem;

    procedure AddAsset(AParent: TFmxObject);
    procedure AddExtensionsUsed(AParent: TFmxObject);
    procedure AddScenes(AParent: TFmxObject);
    procedure AddNodes(AParent: TFmxObject);
    procedure AddMaterials(AParent: TFmxObject);
    procedure AddTextures(AParent: TFmxObject);
    procedure AddImages(AParent: TFmxObject);
    procedure AddSamplers(AParent: TFmxObject);
    procedure AddMeshes(AParent: TFmxObject);
    procedure AddCameras(AParent: TFmxObject);
    procedure AddSkins(AParent: TFmxObject);
    procedure AddAnimations(AParent: TFmxObject);
    procedure AddAccessors(AParent: TFmxObject);
    procedure AddBufferViews(AParent: TFmxObject);
    procedure AddBuffers(AParent: TFmxObject);

    procedure BuildTree;
  public
    //** @abstract(Creates a builder for one tree and document; used by @link(Build).)
    //**
    //** @param(ATree The tree view to fill; not owned.)
    //**
    //** @param(ADoc The document to show; not owned.)
    /// <summary>Creates a builder for one tree and document; used by
    /// <see cref="Build"/>.</summary>
    /// <param name="ATree">The tree view to fill; not owned.</param>
    /// <param name="ADoc">The document to show; not owned.</param>
    constructor Create(ATree: TTreeView; ADoc: TglTFDocument);

    //** @abstract(Frees the builder; the tree and the document are not affected.)
    /// <summary>Frees the builder; the tree and the document are not affected.</summary>
    destructor Destroy; override;

    //** @abstract(Clears a tree view and fills it with the structure of a document.)
    //**
    //** The tree holds only text; it keeps no references to the document's objects, so the
    //** document can be freed or reloaded afterwards.
    //**
    //** @param(ATree The tree view to fill.)
    //**
    //** @param(ADoc The document to show.)
    /// <summary>Clears a tree view and fills it with the structure of a document.</summary>
    /// <param name="ATree">The tree view to fill.</param>
    /// <param name="ADoc">The document to show.</param>
    /// <remarks>The tree holds only text; it keeps no references to the document's objects, so
    /// the document can be freed or reloaded afterwards.</remarks>
    class procedure Build(ATree: TTreeView; ADoc: TglTFDocument);

    //** @abstract(Clears a tree view and shows a single line of text in it.)
    //**
    //** Used when nothing is loaded or a load failed.
    //**
    //** @param(ATree The tree view.)
    //**
    //** @param(AText The text to show, for example a load error.)
    /// <summary>Clears a tree view and shows a single line of text in it.</summary>
    /// <param name="ATree">The tree view.</param>
    /// <param name="AText">The text to show, for example a load error.</param>
    /// <remarks>Used when nothing is loaded or a load failed.</remarks>
    class procedure ShowMessage(ATree: TTreeView; const AText: string);
  end;

implementation

const
  ARROW = ' ' + #$2192 + ' ';   // →
  WARN = #$26A0 + ' ';          // ⚠

  // Every tree item is a styled control, so tens of thousands of them take
  // FireMonkey a very long time to create and lay out. The long lists are
  // cut off after these counts
  MAX_LISTED = 250;     // nodes, accessors, bufferViews
  MAX_CHANNELS = 30;    // channels shown per animation

  TIMES = #$00D7;               // ×
  ELLIPSIS = #$2026;            // …
  MAX_INLINE_JSON = 100;

{ Formatting helpers }

// The line that stands for the items not listed
function MoreText(ACount: Integer; const AWhat: string): string;
begin
  Result := Format('%s %d more %s not listed', [ELLIPSIS, ACount, AWhat]);
end;

function FloatText(AValue: Double): string;
begin
  Result := FloatToStr(AValue, TFormatSettings.Invariant);
end;

function FloatArrayText(const AValues: TArray<Double>): string;
var
  I: Integer;
begin
  Result := '[';
  for I := 0 to High(AValues) do
  begin
    if I > 0 then
      Result := Result + ', ';
    Result := Result + FloatText(AValues[I]);
  end;
  Result := Result + ']';
end;

function Shorten(const AText: string; AMax: Integer = MAX_INLINE_JSON): string;
begin
  if Length(AText) <= AMax then
    Result := AText
  else
    Result := Copy(AText, 1, AMax) + ELLIPSIS;
end;

function Caption(const AKind: string; AIndex: Integer; const AName: string): string;
begin
  Result := Format('%s %d', [AKind, AIndex]);
  if AName <> '' then
    Result := Result + ' "' + AName + '"';
end;

function Missing(const AKind: string; AIndex, ACount: Integer): string;
begin
  Result := Format('%s%s %d does not exist (%d defined)', [WARN, AKind, AIndex, ACount]);
end;

function ValidIndex(AIndex, ACount: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < ACount);
end;

function ComponentTypeName(AType: Integer): string;
begin
  case AType of
    GLTF_COMPONENT_BYTE: Result := 'BYTE';
    GLTF_COMPONENT_UNSIGNED_BYTE: Result := 'UNSIGNED_BYTE';
    GLTF_COMPONENT_SHORT: Result := 'SHORT';
    GLTF_COMPONENT_UNSIGNED_SHORT: Result := 'UNSIGNED_SHORT';
    GLTF_COMPONENT_UNSIGNED_INT: Result := 'UNSIGNED_INT';
    GLTF_COMPONENT_FLOAT: Result := 'FLOAT';
  else
    Result := IntToStr(AType);
  end;
end;

function ModeName(AMode: Integer): string;
begin
  case AMode of
    GLTF_MODE_POINTS: Result := 'POINTS';
    GLTF_MODE_LINES: Result := 'LINES';
    GLTF_MODE_LINE_LOOP: Result := 'LINE_LOOP';
    GLTF_MODE_LINE_STRIP: Result := 'LINE_STRIP';
    GLTF_MODE_TRIANGLES: Result := 'TRIANGLES';
    GLTF_MODE_TRIANGLE_STRIP: Result := 'TRIANGLE_STRIP';
    GLTF_MODE_TRIANGLE_FAN: Result := 'TRIANGLE_FAN';
  else
    Result := 'mode ' + IntToStr(AMode);
  end;
end;

function FilterName(AFilter: Integer): string;
begin
  case AFilter of
    0: Result := 'auto';
    GLTF_FILTER_NEAREST: Result := 'NEAREST';
    GLTF_FILTER_LINEAR: Result := 'LINEAR';
    GLTF_FILTER_NEAREST_MIPMAP_NEAREST: Result := 'NEAREST_MIPMAP_NEAREST';
    GLTF_FILTER_LINEAR_MIPMAP_NEAREST: Result := 'LINEAR_MIPMAP_NEAREST';
    GLTF_FILTER_NEAREST_MIPMAP_LINEAR: Result := 'NEAREST_MIPMAP_LINEAR';
    GLTF_FILTER_LINEAR_MIPMAP_LINEAR: Result := 'LINEAR_MIPMAP_LINEAR';
  else
    Result := IntToStr(AFilter);
  end;
end;

function WrapName(AWrap: Integer): string;
begin
  case AWrap of
    GLTF_WRAP_CLAMP_TO_EDGE: Result := 'CLAMP_TO_EDGE';
    GLTF_WRAP_MIRRORED_REPEAT: Result := 'MIRRORED_REPEAT';
    GLTF_WRAP_REPEAT: Result := 'REPEAT';
  else
    Result := IntToStr(AWrap);
  end;
end;

function TargetName(ATarget: Integer): string;
begin
  case ATarget of
    GLTF_TARGET_ARRAY_BUFFER: Result := 'ARRAY_BUFFER';
    GLTF_TARGET_ELEMENT_ARRAY_BUFFER: Result := 'ELEMENT_ARRAY_BUFFER';
  else
    Result := IntToStr(ATarget);
  end;
end;

function DataUriMimeType(const AUri: string): string;
var
  LEnd: Integer;
begin
  // data:[<mime>][;base64],<data>
  Result := Copy(AUri, 6, MaxInt);
  LEnd := Result.IndexOfAny([';', ',']);
  if LEnd >= 0 then
    Result := Copy(Result, 1, LEnd);
  if Result = '' then
    Result := 'no MIME type';
end;

function UriText(const AUri: string): string;
begin
  if AUri.StartsWith('data:', True) then
    Result := Format('embedded data URI (%s, %d characters)', [DataUriMimeType(AUri), Length(AUri)])
  else
    Result := AUri;
end;

{ TglTFTreeBuilder }

constructor TglTFTreeBuilder.Create(ATree: TTreeView; ADoc: TglTFDocument);
begin
  inherited Create;
  FTree := ATree;
  FDoc := ADoc;
  FRoot := ADoc.Root;
  FNodePath := TList<Integer>.Create;
end;

destructor TglTFTreeBuilder.Destroy;
begin
  FNodePath.Free;
  inherited;
end;

class procedure TglTFTreeBuilder.Build(ATree: TTreeView; ADoc: TglTFDocument);
var
  LBuilder: TglTFTreeBuilder;
begin
  LBuilder := TglTFTreeBuilder.Create(ATree, ADoc);
  try
    LBuilder.BuildTree;
  finally
    LBuilder.Free;
  end;
end;

class procedure TglTFTreeBuilder.ShowMessage(ATree: TTreeView; const AText: string);
var
  LItem: TTreeViewItem;
begin
  ATree.BeginUpdate;
  try
    ATree.Clear;
    LItem := TTreeViewItem.Create(ATree);
    LItem.Text := AText;
    LItem.Parent := ATree;
  finally
    ATree.EndUpdate;
  end;
end;

function TglTFTreeBuilder.Add(AParent: TFmxObject; const AText: string): TTreeViewItem;
begin
  Result := TTreeViewItem.Create(FTree);
  Result.Text := AText;
  Result.Parent := AParent;
end;

function TglTFTreeBuilder.Section(AParent: TFmxObject; const ATitle: string;
  ACount: Integer): TTreeViewItem;
begin
  if ACount = 0 then
    Result := Add(AParent, ATitle + ' (none)')
  else
    Result := Add(AParent, Format('%s (%d)', [ATitle, ACount]));
end;

procedure TglTFTreeBuilder.MakeBold(AItem: TTreeViewItem);
begin
  AItem.StyledSettings := AItem.StyledSettings - [TStyledSetting.Style];
  AItem.TextSettings.Font.Style := [TFontStyle.fsBold];
end;

procedure TglTFTreeBuilder.AddMeta(AParent: TFmxObject; AProp: TglTFProperty;
  const APrefix: string);
var
  LName: string;
  I: Integer;
begin
  if AProp = nil then
    Exit;

  for LName in AProp.ExtensionNames do
    Add(AParent, Format('%sExtension %s: %s',
      [APrefix, LName, Shorten(AProp.FindExtension(LName).ToJSON)]));

  if AProp.HasExtras then
    Add(AParent, APrefix + 'Extras: ' + Shorten(AProp.Extras.ToJSON));

  if Assigned(AProp.UnknownProperties) then
    for I := 0 to AProp.UnknownProperties.Count - 1 do
      Add(AParent, Format('%sNon-standard property "%s": %s',
        [APrefix, AProp.UnknownProperties.Pairs[I].JsonString.Value,
         Shorten(AProp.UnknownProperties.Pairs[I].JsonValue.ToJSON)]));
end;

{ Text for references }

function TglTFTreeBuilder.AccessorText(AIndex: Integer): string;
var
  LAccessor: TglTFAccessor;
begin
  if not ValidIndex(AIndex, FRoot.Accessors.Count) then
    Exit(Missing('Accessor', AIndex, FRoot.Accessors.Count));

  LAccessor := FRoot.Accessors[AIndex];
  Result := Format('%s: %s %s %s%d', [Caption('Accessor', AIndex, LAccessor.Name),
    LAccessor.&Type, ComponentTypeName(LAccessor.ComponentType), TIMES, LAccessor.Count]);
  if LAccessor.Normalized then
    Result := Result + ' normalized';
  if Assigned(LAccessor.Sparse) then
    Result := Result + ', sparse';
end;

function TglTFTreeBuilder.ImageSourceText(AImage: TglTFImage): string;
begin
  if AImage.IsDefined('bufferView') then
    Result := Format('bufferView %d, %s', [AImage.BufferView, AImage.MimeType])
  else
    Result := UriText(AImage.Uri);
end;

function TglTFTreeBuilder.SamplerText(AIndex: Integer): string;
var
  LSampler: TglTFSampler;
begin
  if not ValidIndex(AIndex, FRoot.Samplers.Count) then
    Exit(Missing('Sampler', AIndex, FRoot.Samplers.Count));

  LSampler := FRoot.Samplers[AIndex];
  Result := Format('%s: mag %s, min %s, wrap %s / %s',
    [Caption('Sampler', AIndex, LSampler.Name), FilterName(LSampler.MagFilter),
     FilterName(LSampler.MinFilter), WrapName(LSampler.WrapS), WrapName(LSampler.WrapT)]);
end;

function TglTFTreeBuilder.NodeParent(AIndex: Integer): Integer;
var
  I, LChild: Integer;
begin
  for I := 0 to FRoot.Nodes.Count - 1 do
    for LChild in FRoot.Nodes[I].Children do
      if LChild = AIndex then
        Exit(I);
  Result := GLTF_UNDEFINED_INDEX;
end;

function TglTFTreeBuilder.TextureUsers(ATexture: Integer): string;
var
  LResult: string;
  I: Integer;
  LMaterial: TglTFMaterial;

  procedure Check(AMaterialIndex: Integer; AMat: TglTFMaterial; const ASlot: string;
    AInfo: TglTFTextureInfo);
  begin
    if Assigned(AInfo) and (AInfo.Index = ATexture) then
    begin
      if LResult <> '' then
        LResult := LResult + ', ';
      LResult := LResult + Format('%s (%s)', [Caption('Material', AMaterialIndex, AMat.Name), ASlot]);
    end;
  end;

begin
  LResult := '';
  for I := 0 to FRoot.Materials.Count - 1 do
  begin
    LMaterial := FRoot.Materials[I];
    if Assigned(LMaterial.PbrMetallicRoughness) then
    begin
      Check(I, LMaterial, 'baseColorTexture', LMaterial.PbrMetallicRoughness.BaseColorTexture);
      Check(I, LMaterial, 'metallicRoughnessTexture', LMaterial.PbrMetallicRoughness.MetallicRoughnessTexture);
    end;
    Check(I, LMaterial, 'normalTexture', LMaterial.NormalTexture);
    Check(I, LMaterial, 'occlusionTexture', LMaterial.OcclusionTexture);
    Check(I, LMaterial, 'emissiveTexture', LMaterial.EmissiveTexture);
  end;
  Result := LResult;
end;

function TglTFTreeBuilder.ImageUsers(AImage: Integer): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FRoot.Textures.Count - 1 do
    if FRoot.Textures[I].Source = AImage then
    begin
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + Caption('Texture', I, FRoot.Textures[I].Name);
    end;
end;

{ Nodes }

function TglTFTreeBuilder.AddNodeHierarchy(AParent: TFmxObject; AIndex: Integer): TTreeViewItem;
var
  LNode: TglTFNode;
begin
  if not ValidIndex(AIndex, FRoot.Nodes.Count) then
    Exit(Add(AParent, Missing('Node', AIndex, FRoot.Nodes.Count)));

  if FNodePath.Contains(AIndex) then
    Exit(Add(AParent, Format('%sNode %d: cycle in the node hierarchy', [WARN, AIndex])));

  LNode := FRoot.Nodes[AIndex];
  Result := Add(AParent, Caption('Node', AIndex, LNode.Name));
  FNodePath.Add(AIndex);
  try
    AddNodeContent(Result, LNode, True);
  finally
    FNodePath.Delete(FNodePath.Count - 1);
  end;
end;

procedure TglTFTreeBuilder.AddNodeContent(AItem: TTreeViewItem; ANode: TglTFNode;
  ARecursive: Boolean);
var
  LChild: Integer;
  LChildren: TTreeViewItem;
  LCamera: TglTFCamera;
  LSkin: TglTFSkin;
begin
  AddTransform(AItem, ANode);

  if ANode.Mesh <> GLTF_UNDEFINED_INDEX then
    AddMeshRef(AItem, ANode.Mesh);

  if ANode.Camera <> GLTF_UNDEFINED_INDEX then
  begin
    if ValidIndex(ANode.Camera, FRoot.Cameras.Count) then
    begin
      LCamera := FRoot.Cameras[ANode.Camera];
      Add(AItem, Format('%s (%s)', [Caption('Camera', ANode.Camera, LCamera.Name), LCamera.&Type]));
    end
    else
      Add(AItem, Missing('Camera', ANode.Camera, FRoot.Cameras.Count));
  end;

  if ANode.Skin <> GLTF_UNDEFINED_INDEX then
  begin
    if ValidIndex(ANode.Skin, FRoot.Skins.Count) then
    begin
      LSkin := FRoot.Skins[ANode.Skin];
      Add(AItem, Format('%s (%d joints)', [Caption('Skin', ANode.Skin, LSkin.Name), Length(LSkin.Joints)]));
    end
    else
      Add(AItem, Missing('Skin', ANode.Skin, FRoot.Skins.Count));
  end;

  if ANode.IsDefined('weights') then
    Add(AItem, 'Morph weights: ' + FloatArrayText(ANode.Weights));

  AddMeta(AItem, ANode);

  if Length(ANode.Children) = 0 then
    Exit;

  if ARecursive then
  begin
    for LChild in ANode.Children do
      AddNodeHierarchy(AItem, LChild);
  end
  else
  begin
    // Flat node list: children as references only
    LChildren := Add(AItem, Format('Children (%d)', [Length(ANode.Children)]));
    for LChild in ANode.Children do
      if ValidIndex(LChild, FRoot.Nodes.Count) then
        Add(LChildren, Caption('Node', LChild, FRoot.Nodes[LChild].Name))
      else
        Add(LChildren, Missing('Node', LChild, FRoot.Nodes.Count));
  end;
end;

procedure TglTFTreeBuilder.AddTransform(AItem: TTreeViewItem; ANode: TglTFNode);
begin
  if ANode.HasMatrix then
    Add(AItem, 'Matrix: ' + FloatArrayText(ANode.Matrix))
  else
  begin
    if ANode.IsDefined('translation') then
      Add(AItem, 'Translation: ' + FloatArrayText(ANode.Translation));
    if ANode.IsDefined('rotation') then
      Add(AItem, 'Rotation: ' + FloatArrayText(ANode.Rotation));
    if ANode.IsDefined('scale') then
      Add(AItem, 'Scale: ' + FloatArrayText(ANode.Scale));
  end;
end;

{ Meshes }

procedure TglTFTreeBuilder.AddMeshRef(AParent: TFmxObject; AIndex: Integer);
var
  LMesh: TglTFMesh;
  LItem: TTreeViewItem;
begin
  if not ValidIndex(AIndex, FRoot.Meshes.Count) then
  begin
    Add(AParent, Missing('Mesh', AIndex, FRoot.Meshes.Count));
    Exit;
  end;

  LMesh := FRoot.Meshes[AIndex];
  LItem := Add(AParent, Format('%s (%d primitive(s))',
    [Caption('Mesh', AIndex, LMesh.Name), LMesh.Primitives.Count]));
  AddMeshContent(LItem, LMesh);
end;

procedure TglTFTreeBuilder.AddMeshContent(AItem: TTreeViewItem; AMesh: TglTFMesh);
var
  I: Integer;
  LPrimitive: TglTFMeshPrimitive;
  LPrimItem: TTreeViewItem;
  LSemantics: TArray<string>;
  LSemantic: string;
begin
  for I := 0 to AMesh.Primitives.Count - 1 do
  begin
    LPrimitive := AMesh.Primitives[I];
    LPrimItem := Add(AItem, Format('Primitive %d (%s)', [I, ModeName(LPrimitive.Mode)]));

    if LPrimitive.Material <> GLTF_UNDEFINED_INDEX then
      AddMaterialRef(LPrimItem, LPrimitive.Material)
    else
      Add(LPrimItem, 'Material: (default material)');

    LSemantics := LPrimitive.Attributes.Keys.ToArray;
    TArray.Sort<string>(LSemantics);
    for LSemantic in LSemantics do
      Add(LPrimItem, LSemantic + ARROW + AccessorText(LPrimitive.Attributes[LSemantic]));

    if LPrimitive.Indices <> GLTF_UNDEFINED_INDEX then
      Add(LPrimItem, 'indices' + ARROW + AccessorText(LPrimitive.Indices))
    else
      Add(LPrimItem, 'indices: (not indexed)');

    if LPrimitive.Targets.Count > 0 then
      Add(LPrimItem, Format('Morph targets: %d', [LPrimitive.Targets.Count]));

    AddMeta(LPrimItem, LPrimitive);
  end;

  if AMesh.IsDefined('weights') then
    Add(AItem, 'Default morph weights: ' + FloatArrayText(AMesh.Weights));

  AddMeta(AItem, AMesh);
end;

{ Materials, textures and images }

procedure TglTFTreeBuilder.AddMaterialRef(AParent: TFmxObject; AIndex: Integer);
var
  LMaterial: TglTFMaterial;
begin
  if not ValidIndex(AIndex, FRoot.Materials.Count) then
  begin
    Add(AParent, Missing('Material', AIndex, FRoot.Materials.Count));
    Exit;
  end;

  LMaterial := FRoot.Materials[AIndex];
  AddMaterialContent(Add(AParent, Caption('Material', AIndex, LMaterial.Name)), LMaterial);
end;

procedure TglTFTreeBuilder.AddMaterialContent(AItem: TTreeViewItem; AMaterial: TglTFMaterial);
var
  LPbr: TglTFPbrMetallicRoughness;
  LPbrItem: TTreeViewItem;
  LText: string;
begin
  LText := 'Alpha mode: ' + AMaterial.AlphaMode;
  if AMaterial.AlphaModeKind = amMask then
    LText := LText + ', cutoff ' + FloatText(AMaterial.AlphaCutoff);
  Add(AItem, LText);
  Add(AItem, 'Double sided: ' + BoolToStr(AMaterial.DoubleSided, True));

  LPbr := AMaterial.PbrMetallicRoughness;
  if Assigned(LPbr) then
  begin
    LPbrItem := Add(AItem, 'PBR metallic-roughness');
    Add(LPbrItem, 'Base colour factor: ' + FloatArrayText(LPbr.BaseColorFactor));
    Add(LPbrItem, 'Metallic factor: ' + FloatText(LPbr.MetallicFactor));
    Add(LPbrItem, 'Roughness factor: ' + FloatText(LPbr.RoughnessFactor));
    AddTextureInfo(LPbrItem, 'Base colour texture', LPbr.BaseColorTexture);
    AddTextureInfo(LPbrItem, 'Metallic-roughness texture', LPbr.MetallicRoughnessTexture);
    AddMeta(LPbrItem, LPbr);
    LPbrItem.IsExpanded := True;
  end
  else
    Add(AItem, 'PBR metallic-roughness: (spec defaults)');

  if Assigned(AMaterial.NormalTexture) then
    AddTextureInfo(AItem, 'Normal texture', AMaterial.NormalTexture,
      ', scale ' + FloatText(AMaterial.NormalTexture.Scale));
  if Assigned(AMaterial.OcclusionTexture) then
    AddTextureInfo(AItem, 'Occlusion texture', AMaterial.OcclusionTexture,
      ', strength ' + FloatText(AMaterial.OcclusionTexture.Strength));
  AddTextureInfo(AItem, 'Emissive texture', AMaterial.EmissiveTexture);
  if AMaterial.IsDefined('emissiveFactor') then
    Add(AItem, 'Emissive factor: ' + FloatArrayText(AMaterial.EmissiveFactor));

  AddMeta(AItem, AMaterial);
end;

procedure TglTFTreeBuilder.AddTextureInfo(AParent: TFmxObject; const ASlot: string;
  AInfo: TglTFTextureInfo; const AExtra: string);
var
  LItem: TTreeViewItem;
begin
  if AInfo = nil then
    Exit;

  LItem := Add(AParent, Format('%s%sTexture %d (texCoord %d%s)',
    [ASlot, ARROW, AInfo.Index, AInfo.TexCoord, AExtra]));
  AddTextureContent(LItem, AInfo.Index);
  AddMeta(LItem, AInfo); // e.g. KHR_texture_transform
  LItem.IsExpanded := True;
end;

procedure TglTFTreeBuilder.AddTextureContent(AItem: TTreeViewItem; AIndex: Integer);
var
  LTexture: TglTFTexture;
begin
  if not ValidIndex(AIndex, FRoot.Textures.Count) then
  begin
    Add(AItem, Missing('Texture', AIndex, FRoot.Textures.Count));
    Exit;
  end;

  LTexture := FRoot.Textures[AIndex];
  if LTexture.Name <> '' then
    Add(AItem, 'Name: "' + LTexture.Name + '"');

  if LTexture.Source <> GLTF_UNDEFINED_INDEX then
    AddImageRef(AItem, LTexture.Source)
  else
    Add(AItem, 'Image: (none - may be supplied by an extension)');

  if LTexture.Sampler <> GLTF_UNDEFINED_INDEX then
    Add(AItem, SamplerText(LTexture.Sampler))
  else
    Add(AItem, 'Sampler: (default - REPEAT wrapping, automatic filtering)');

  AddMeta(AItem, LTexture, 'Texture ');
end;

function TglTFTreeBuilder.AddImageRef(AParent: TFmxObject; AIndex: Integer): TTreeViewItem;
var
  LImage: TglTFImage;
  LItem: TTreeViewItem;
begin
  if not ValidIndex(AIndex, FRoot.Images.Count) then
    Exit(Add(AParent, Missing('Image', AIndex, FRoot.Images.Count)));

  LImage := FRoot.Images[AIndex];
  LItem := Add(AParent, Format('%s: %s', [Caption('Image', AIndex, LImage.Name),
    ImageSourceText(LImage)]));
  if LImage.IsDefined('uri') and not LImage.IsDataUri then
    Add(LItem, 'File: ' + FDoc.ResolveUri(LImage.Uri));
  if LImage.IsDefined('mimeType') then
    Add(LItem, 'MIME type: ' + LImage.MimeType);
  AddMeta(LItem, LImage);
  Result := LItem;
end;

{ Sections }

procedure TglTFTreeBuilder.AddAsset(AParent: TFmxObject);
var
  LAsset: TglTFAsset;
  LItem: TTreeViewItem;
begin
  LAsset := FRoot.Asset;
  if LAsset = nil then
    Exit;

  LItem := Add(AParent, 'Asset (glTF ' + LAsset.Version + ')');
  if LAsset.IsDefined('minVersion') then
    Add(LItem, 'Minimum version: ' + LAsset.MinVersion);
  if LAsset.Generator <> '' then
    Add(LItem, 'Generator: ' + LAsset.Generator);
  if LAsset.Copyright <> '' then
    Add(LItem, 'Copyright: ' + LAsset.Copyright);
  AddMeta(LItem, LAsset);
end;

procedure TglTFTreeBuilder.AddExtensionsUsed(AParent: TFmxObject);
var
  LItem: TTreeViewItem;
  LName: string;
begin
  if Length(FRoot.ExtensionsUsed) = 0 then
    Exit;

  LItem := Section(AParent, 'Extensions used', Length(FRoot.ExtensionsUsed));
  for LName in FRoot.ExtensionsUsed do
    if FRoot.IsExtensionRequired(LName) then
      Add(LItem, LName + ' (required)')
    else
      Add(LItem, LName);
end;

procedure TglTFTreeBuilder.AddScenes(AParent: TFmxObject);
var
  LSection, LItem, LNodeItem: TTreeViewItem;
  LScene: TglTFScene;
  LIsDefault: Boolean;
  LNodeIndex, I: Integer;
  LText: string;
begin
  LSection := Section(AParent, 'Scenes', FRoot.Scenes.Count);

  if not FRoot.IsDefined('scene') then
  begin
    if FRoot.Scenes.Count > 0 then
      Add(LSection, '(no default scene defined)');
  end
  else if not ValidIndex(FRoot.Scene, FRoot.Scenes.Count) then
    Add(LSection, WARN + Format('Default scene %d does not exist (%d defined)',
      [FRoot.Scene, FRoot.Scenes.Count]));

  for I := 0 to FRoot.Scenes.Count - 1 do
  begin
    LScene := FRoot.Scenes[I];
    LIsDefault := FRoot.IsDefined('scene') and (I = FRoot.Scene);

    LText := Format('%s (%d root node(s))', [Caption('Scene', I, LScene.Name), Length(LScene.Nodes)]);
    if LIsDefault then
      LText := LText + ' - default scene';
    LItem := Add(LSection, LText);

    for LNodeIndex in LScene.Nodes do
    begin
      LNodeItem := AddNodeHierarchy(LItem, LNodeIndex);
      if LIsDefault then
        LNodeItem.IsExpanded := True;
    end;
    AddMeta(LItem, LScene);

    if LIsDefault then
    begin
      MakeBold(LItem);
      LItem.IsExpanded := True;
    end;
  end;

  LSection.IsExpanded := True;
end;

procedure TglTFTreeBuilder.AddNodes(AParent: TFmxObject);
var
  LSection, LItem: TTreeViewItem;
  LParent, I: Integer;
begin
  LSection := Section(AParent, 'Nodes', FRoot.Nodes.Count);
  for I := 0 to FRoot.Nodes.Count - 1 do
  begin
    if I = MAX_LISTED then
    begin
      Add(LSection, MoreText(FRoot.Nodes.Count - I, 'nodes'));
      Break;
    end;
    LItem := Add(LSection, Caption('Node', I, FRoot.Nodes[I].Name));
    LParent := NodeParent(I);
    if LParent <> GLTF_UNDEFINED_INDEX then
      Add(LItem, 'Parent: ' + Caption('Node', LParent, FRoot.Nodes[LParent].Name));
    AddNodeContent(LItem, FRoot.Nodes[I], False);
  end;
end;

procedure TglTFTreeBuilder.AddMaterials(AParent: TFmxObject);
var
  LSection: TTreeViewItem;
  I: Integer;
begin
  LSection := Section(AParent, 'Materials', FRoot.Materials.Count);
  for I := 0 to FRoot.Materials.Count - 1 do
    AddMaterialRef(LSection, I);
  LSection.IsExpanded := True;
end;

procedure TglTFTreeBuilder.AddTextures(AParent: TFmxObject);
var
  LSection, LItem: TTreeViewItem;
  LUsers: string;
  I: Integer;
begin
  LSection := Section(AParent, 'Textures', FRoot.Textures.Count);
  for I := 0 to FRoot.Textures.Count - 1 do
  begin
    LItem := Add(LSection, Caption('Texture', I, FRoot.Textures[I].Name));
    LUsers := TextureUsers(I);
    if LUsers = '' then
      Add(LItem, 'Used by: (no material)')
    else
      Add(LItem, 'Used by: ' + LUsers);
    AddTextureContent(LItem, I);
  end;
  LSection.IsExpanded := True;
end;

procedure TglTFTreeBuilder.AddImages(AParent: TFmxObject);
var
  LSection, LItem: TTreeViewItem;
  LUsers: string;
  I: Integer;
begin
  LSection := Section(AParent, 'Images', FRoot.Images.Count);
  for I := 0 to FRoot.Images.Count - 1 do
  begin
    LItem := AddImageRef(LSection, I);
    LUsers := ImageUsers(I);
    if LUsers = '' then
      LUsers := '(no texture)';
    Add(LItem, 'Used by: ' + LUsers);
  end;
  LSection.IsExpanded := True;
end;

procedure TglTFTreeBuilder.AddSamplers(AParent: TFmxObject);
var
  LSection: TTreeViewItem;
  I: Integer;
begin
  LSection := Section(AParent, 'Samplers', FRoot.Samplers.Count);
  for I := 0 to FRoot.Samplers.Count - 1 do
    AddMeta(Add(LSection, SamplerText(I)), FRoot.Samplers[I]);
end;

procedure TglTFTreeBuilder.AddMeshes(AParent: TFmxObject);
var
  LSection: TTreeViewItem;
  I: Integer;
begin
  LSection := Section(AParent, 'Meshes', FRoot.Meshes.Count);
  for I := 0 to FRoot.Meshes.Count - 1 do
    AddMeshRef(LSection, I);
end;

procedure TglTFTreeBuilder.AddCameras(AParent: TFmxObject);
var
  LSection, LItem: TTreeViewItem;
  LCamera: TglTFCamera;
  I: Integer;
begin
  LSection := Section(AParent, 'Cameras', FRoot.Cameras.Count);
  for I := 0 to FRoot.Cameras.Count - 1 do
  begin
    LCamera := FRoot.Cameras[I];
    LItem := Add(LSection, Format('%s (%s)', [Caption('Camera', I, LCamera.Name), LCamera.&Type]));
    if Assigned(LCamera.Perspective) then
      Add(LItem, Format('yfov %s, znear %s, zfar %s, aspect %s',
        [FloatText(LCamera.Perspective.YFov), FloatText(LCamera.Perspective.ZNear),
         FloatText(LCamera.Perspective.ZFar), FloatText(LCamera.Perspective.AspectRatio)]));
    if Assigned(LCamera.Orthographic) then
      Add(LItem, Format('xmag %s, ymag %s, znear %s, zfar %s',
        [FloatText(LCamera.Orthographic.XMag), FloatText(LCamera.Orthographic.YMag),
         FloatText(LCamera.Orthographic.ZNear), FloatText(LCamera.Orthographic.ZFar)]));
    AddMeta(LItem, LCamera);
  end;
end;

procedure TglTFTreeBuilder.AddSkins(AParent: TFmxObject);
var
  LSection, LItem: TTreeViewItem;
  LSkin: TglTFSkin;
  I: Integer;
begin
  LSection := Section(AParent, 'Skins', FRoot.Skins.Count);
  for I := 0 to FRoot.Skins.Count - 1 do
  begin
    LSkin := FRoot.Skins[I];
    LItem := Add(LSection, Format('%s (%d joints)', [Caption('Skin', I, LSkin.Name), Length(LSkin.Joints)]));
    if LSkin.Skeleton <> GLTF_UNDEFINED_INDEX then
      Add(LItem, Format('Skeleton root: Node %d', [LSkin.Skeleton]));
    if LSkin.InverseBindMatrices <> GLTF_UNDEFINED_INDEX then
      Add(LItem, 'Inverse bind matrices' + ARROW + AccessorText(LSkin.InverseBindMatrices));
    AddMeta(LItem, LSkin);
  end;
end;

procedure TglTFTreeBuilder.AddAnimations(AParent: TFmxObject);
var
  LSection, LItem: TTreeViewItem;
  LAnimation: TglTFAnimation;
  LChannel: TglTFAnimationChannel;
  LInterpolation: string;
  I, J: Integer;
begin
  LSection := Section(AParent, 'Animations', FRoot.Animations.Count);
  for I := 0 to FRoot.Animations.Count - 1 do
  begin
    LAnimation := FRoot.Animations[I];
    LItem := Add(LSection, Format('%s (%d channels, %d samplers)',
      [Caption('Animation', I, LAnimation.Name), LAnimation.Channels.Count, LAnimation.Samplers.Count]));
    if LAnimation.Origin <> '' then
      LItem.Text := LItem.Text + ' - imported from ' + LAnimation.Origin;
    for J := 0 to LAnimation.Channels.Count - 1 do
    begin
      if J = MAX_CHANNELS then
      begin
        Add(LItem, MoreText(LAnimation.Channels.Count - J, 'channels'));
        Break;
      end;
      LChannel := LAnimation.Channels[J];
      if ValidIndex(LChannel.Sampler, LAnimation.Samplers.Count) then
        LInterpolation := LAnimation.Samplers[LChannel.Sampler].Interpolation
      else
        LInterpolation := WARN + 'sampler ' + IntToStr(LChannel.Sampler) + ' does not exist';
      if LChannel.Target.Node <> GLTF_UNDEFINED_INDEX then
        Add(LItem, Format('Node %d%s%s (%s)',
          [LChannel.Target.Node, ARROW, LChannel.Target.Path, LInterpolation]))
      else
        Add(LItem, Format('(no node)%s%s (%s)', [ARROW, LChannel.Target.Path, LInterpolation]));
    end;
    AddMeta(LItem, LAnimation);
  end;
end;

procedure TglTFTreeBuilder.AddAccessors(AParent: TFmxObject);
var
  LSection, LItem: TTreeViewItem;
  LAccessor: TglTFAccessor;
  I: Integer;
begin
  LSection := Section(AParent, 'Accessors', FRoot.Accessors.Count);
  for I := 0 to FRoot.Accessors.Count - 1 do
  begin
    if I = MAX_LISTED then
    begin
      Add(LSection, MoreText(FRoot.Accessors.Count - I, 'accessors'));
      Break;
    end;
    LAccessor := FRoot.Accessors[I];
    LItem := Add(LSection, AccessorText(I));
    if LAccessor.BufferView <> GLTF_UNDEFINED_INDEX then
      Add(LItem, Format('bufferView %d, byte offset %d', [LAccessor.BufferView, LAccessor.ByteOffset]))
    else
      Add(LItem, 'No bufferView (all zeros unless sparse)');
    if LAccessor.IsDefined('min') then
      Add(LItem, 'min: ' + FloatArrayText(LAccessor.Min));
    if LAccessor.IsDefined('max') then
      Add(LItem, 'max: ' + FloatArrayText(LAccessor.Max));
    AddMeta(LItem, LAccessor);
  end;
end;

procedure TglTFTreeBuilder.AddBufferViews(AParent: TFmxObject);
var
  LSection, LItem: TTreeViewItem;
  LView: TglTFBufferView;
  LText: string;
  I: Integer;
begin
  LSection := Section(AParent, 'Buffer views', FRoot.BufferViews.Count);
  for I := 0 to FRoot.BufferViews.Count - 1 do
  begin
    if I = MAX_LISTED then
    begin
      Add(LSection, MoreText(FRoot.BufferViews.Count - I, 'bufferViews'));
      Break;
    end;
    LView := FRoot.BufferViews[I];
    LText := Format('%s: buffer %d, offset %d, length %d',
      [Caption('BufferView', I, LView.Name), LView.Buffer, LView.ByteOffset, LView.ByteLength]);
    if LView.IsDefined('byteStride') then
      LText := LText + ', stride ' + IntToStr(LView.ByteStride);
    if LView.IsDefined('target') then
      LText := LText + ', ' + TargetName(LView.Target);
    LItem := Add(LSection, LText);
    AddMeta(LItem, LView);
  end;
end;

procedure TglTFTreeBuilder.AddBuffers(AParent: TFmxObject);
var
  LSection, LItem: TTreeViewItem;
  LBuffer: TglTFBuffer;
  I: Integer;
begin
  LSection := Section(AParent, 'Buffers', FRoot.Buffers.Count);
  for I := 0 to FRoot.Buffers.Count - 1 do
  begin
    LBuffer := FRoot.Buffers[I];
    if LBuffer.IsDefined('uri') then
      LItem := Add(LSection, Format('%s: %d bytes, %s',
        [Caption('Buffer', I, LBuffer.Name), LBuffer.ByteLength, UriText(LBuffer.Uri)]))
    else if (I = 0) and FDoc.HasBinaryChunk then
      LItem := Add(LSection, Format('%s: %d bytes in the GLB BIN chunk (%d bytes)',
        [Caption('Buffer', I, LBuffer.Name), LBuffer.ByteLength, FDoc.BinaryChunkLength]))
    else
      LItem := Add(LSection, Format('%s%s: %d bytes, no uri and no GLB BIN chunk',
        [WARN, Caption('Buffer', I, LBuffer.Name), LBuffer.ByteLength]));
    AddMeta(LItem, LBuffer);
  end;
end;

procedure TglTFTreeBuilder.BuildTree;
var
  LTop: TTreeViewItem;
  LTitle: string;
begin
  FTree.BeginUpdate;
  try
    FTree.Clear;

    if FDoc.FileName <> '' then
      LTitle := ExtractFileName(FDoc.FileName)
    else
      LTitle := '(not loaded from a file)';
    if FDoc.FileFormat = gffGLB then
      LTitle := 'GLB - ' + LTitle
    else
      LTitle := '- ' + LTitle;
    if Assigned(FRoot.Asset) then
      LTitle := 'glTF ' + FRoot.Asset.Version + ' ' + LTitle;

    LTop := Add(FTree, LTitle);
    MakeBold(LTop);

    AddAsset(LTop);
    AddExtensionsUsed(LTop);
    AddScenes(LTop);
    AddNodes(LTop);
    AddMaterials(LTop);
    AddTextures(LTop);
    AddImages(LTop);
    AddSamplers(LTop);
    AddMeshes(LTop);
    AddCameras(LTop);
    AddSkins(LTop);
    AddAnimations(LTop);
    AddAccessors(LTop);
    AddBufferViews(LTop);
    AddBuffers(LTop);
    AddMeta(LTop, FRoot);

    LTop.IsExpanded := True;
  finally
    FTree.EndUpdate;
  end;
end;

end.
