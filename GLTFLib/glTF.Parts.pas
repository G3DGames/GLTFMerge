//** @abstract(Swaps body parts and outfit pieces between glTF models that share a skeleton.)
//**
//** Modular character kits, such as the Quaternius outfits, come as skinned meshes rigged to
//** the same skeleton as a base character: a pair of boots, trousers, a hood. This unit puts
//** such pieces on a loaded model, hides the body under them and takes off what they replace.
//**
//** @link(TglTFPartLibrary) loads part files and lists every skinned mesh in them as a
//** @link(TglTFPart), with the bones that drive it: for each triangle, the bone with the most
//** weight on its three corners. The bones that drive a good share of a part's triangles are
//** the ones it @italic(covers); see @link(TglTFPartOptions).
//**
//** @link(TglTFPartApplier) puts parts on a model:
//** @unorderedList(
//**   @item(Each part is copied in with its mesh, materials, textures and images, and bound to
//**     the model's skeleton by bone name, so it follows the model's bones.)
//**   @item(A part put on earlier that the new part covers for the most part, such as the old
//**     boots, is taken off: deleted with whatever only it used. This goes by bones, as new
//**     sandals do not lie over the old boots.)
//**   @item(The body triangles a part's surface lies over are hidden: left out of the index
//**     list. This goes by shape, not by bone, as a bone is often only partly covered: trousers
//**     that end at mid-calf leave the shin below them. Both the body and the parts are skinned
//**     to the model's skeleton at rest, and a body vertex is covered when a part's surface
//**     crosses the line along its normal within a small gap, on either side, so body that
//**     pokes through the cloth is hidden too. The body keeps all its vertices, and the hidden
//**     triangles come back when the part covering them is taken off.)
//** )
//** Parts added are marked in their node's extras @(see @link(GLTF_PART_EXTRA)@), so they are
//** recognised after the model is saved and loaded again. The model's other skinned meshes,
//** such as hair under a hood, are hidden where covered like the body; they are never deleted.
//**
//** The applier remembers each body primitive's triangles from before the first change, so
//** taking parts off and putting others on never loses any. That memory lasts as long as the
//** applier: after the model is saved and loaded again, its triangles as saved are the starting
//** point.
//**
//** @preformatted(
//** part files --> TglTFPartLibrary --> TglTFPart @(mesh + bones it covers@)
//** TglTFPartApplier.Apply@(parts@):
//**   for each part:  take off the parts it replaces --> copy it in, bound by bone name
//**   then:           hide the body where the parts lie over it --> delete unused data
//** )
//**
//** Progress is reported through OnProgress, so loading and applying can run in a background
//** thread. Use a library or an applier from one thread at a time; only RequestAbort and
//** AbortRequested may be used from another.
unit glTF.Parts;

{
  Swaps body parts and outfit pieces between glTF models that share a
  skeleton.

  Modular character kits, such as the Quaternius outfits, come as skinned
  meshes rigged to the same skeleton as a base character: a pair of boots,
  trousers, a hood. This unit puts such pieces on a loaded model, hides the
  body under them and takes off what they replace.

  TglTFPartLibrary loads part files and lists every skinned mesh in them as a
  TglTFPart, with the bones that drive it: for each triangle, the bone with
  the most weight on its three corners. The bones that drive a good share of a
  part's triangles are the ones it covers; see TglTFPartOptions.

  TglTFPartApplier puts parts on a model:
  - Each part is copied in with its mesh, materials, textures and images, and
    bound to the model's skeleton by bone name, so it follows the model's
    bones.
  - A part put on earlier that the new part covers for the most part, such as
    the old boots, is taken off: deleted with whatever only it used. This goes
    by bones, as new sandals do not lie over the old boots.
  - The body triangles a part's surface lies over are hidden: left out of the
    index list. This goes by shape, not by bone, as a bone is often only
    partly covered: trousers that end at mid-calf leave the shin below them.
    Both the body and the parts are skinned to the model's skeleton at rest,
    and a body vertex is covered when a part's surface crosses the line along
    its normal within a small gap, on either side, so body that pokes through
    the cloth is hidden too. The body keeps all its vertices, and the hidden
    triangles come back when the part covering them is taken off.
  Parts added are marked in their node's extras (see GLTF_PART_EXTRA), so they
  are recognised after the model is saved and loaded again. The model's other
  skinned meshes, such as hair under a hood, are hidden where covered like the
  body; they are never deleted.

  The applier remembers each body primitive's triangles from before the first
  change, so taking parts off and putting others on never loses any. That
  memory lasts as long as the applier: after the model is saved and loaded
  again, its triangles as saved are the starting point.

    part files --> TglTFPartLibrary --> TglTFPart (mesh + bones it covers)
    TglTFPartApplier.Apply(parts):
      for each part:  take off the parts it replaces --> copy it in, bound by bone name
      then:           hide the body where the parts lie over it --> delete unused data

  Progress is reported through OnProgress, so loading and applying can run in
  a background thread. Use a library or an applier from one thread at a time;
  only RequestAbort and AbortRequested may be used from another.
}

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections,

  glTF.Base,
  glTF.Classes,
  glTF.Document;

const
  //** @abstract(Name of the extras entry that marks a node as a part put on by
  //** TglTFPartApplier.)
  //**
  //** Its value is an object with "file", the part file's name, and "part", the part's name.
  /// <summary>Name of the extras entry that marks a node as a part put on by
  /// TglTFPartApplier.</summary>
  /// <remarks>Its value is an object with "file", the part file's name, and "part", the part's
  /// name.</remarks>
  GLTF_PART_EXTRA = 'glTFViewerPart';

type
  //** @abstract(Settings that decide which bones a part covers and what it replaces.)
  //**
  //** Start from @link(TglTFPartOptions.Default) and change what you need.
  /// <summary>Settings that decide which bones a part covers and what it replaces.</summary>
  /// <remarks>Start from <see cref="TglTFPartOptions.Default"/> and change what you
  /// need.</remarks>
  TglTFPartOptions = record
    //** @abstract(How close a part's surface must come to the body for the body to be hidden
    //** there, as a share of the body's height; 0.03 by default.)
    //**
    //** A body vertex is covered when a part's surface crosses the line along its normal no
    //** further than this from it, on either side: outside the skin, or inside it where the body
    //** pokes through the cloth. A triangle is hidden when its three corners are covered. Larger
    //** values hide the body under looser clothes too; smaller ones keep more of it, at the risk
    //** of skin showing through.
    /// <summary>How close a part's surface must come to the body for the body to be hidden
    /// there, as a share of the body's height; 0.03 by default.</summary>
    /// <remarks>A body vertex is covered when a part's surface crosses the line along its normal
    /// no further than this from it, on either side: outside the skin, or inside it where the
    /// body pokes through the cloth. A triangle is hidden when its three corners are covered.
    /// Larger values hide the body under looser clothes too; smaller ones keep more of it, at the
    /// risk of skin showing through.</remarks>
    CoverGap: Double;

    //** @abstract(Share of a part's triangles a bone must drive for the part to cover that bone,
    //** from 0 to 1; 0.02 by default.)
    //**
    //** The bones a part covers decide which parts it replaces @(see @link(ReplaceShare)@) and
    //** are listed for it; they do not decide what of the body is hidden @(see
    //** @link(CoverGap)@).
    /// <summary>Share of a part's triangles a bone must drive for the part to cover that bone,
    /// from 0 to 1; 0.02 by default.</summary>
    /// <remarks>The bones a part covers decide which parts it replaces (see
    /// <see cref="ReplaceShare"/>) and are listed for it; they do not decide what of the body is
    /// hidden (see <see cref="CoverGap"/>).</remarks>
    MinShare: Double;

    //** @abstract(Share of a part's triangles on the bones a new part covers for the new part to
    //** replace it, from 0 to 1; 0.5 by default.)
    //**
    //** Only parts put on earlier are replaced; the body and the model's other meshes are hidden
    //** where covered instead.
    /// <summary>Share of a part's triangles on the bones a new part covers for the new part to
    /// replace it, from 0 to 1; 0.5 by default.</summary>
    /// <remarks>Only parts put on earlier are replaced; the body and the model's other meshes are
    /// hidden where covered instead.</remarks>
    ReplaceShare: Double;

    //** @abstract(Bones never covered, compared ignoring case; none by default.)
    //**
    //** Body vertices whose strongest bone is one of these are never hidden, and parts do not
    //** replace each other on account of these bones. For example Head keeps the whole head
    //** under a hood.
    /// <summary>Bones never covered, compared ignoring case; none by default.</summary>
    /// <remarks>Body vertices whose strongest bone is one of these are never hidden, and parts do
    /// not replace each other on account of these bones. For example Head keeps the whole head
    /// under a hood.</remarks>
    KeepBones: TArray<string>;

    //** @abstract(Returns the default settings.)
    //**
    //** @returns(CoverGap 0.03, MinShare 0.02, ReplaceShare 0.5, no KeepBones.)
    /// <summary>Returns the default settings.</summary>
    /// <returns>CoverGap 0.03, MinShare 0.02, ReplaceShare 0.5, no KeepBones.</returns>
    class function Default: TglTFPartOptions; static;

    //** @abstract(Tells whether a bone is one of @link(KeepBones).)
    //**
    //** @param(ABone The bone's node name.)
    //**
    //** @returns(True when the bone is never covered.)
    /// <summary>Tells whether a bone is one of <see cref="KeepBones"/>.</summary>
    /// <param name="ABone">The bone's node name.</param>
    /// <returns>True when the bone is never covered.</returns>
    function IsKept(const ABone: string): Boolean;
  end;

  //** @abstract(One skinned mesh found in a part file: a piece that can be put on a model.)
  //**
  //** Created and owned by @link(TglTFPartLibrary); read-only for its users.
  /// <summary>One skinned mesh found in a part file: a piece that can be put on a
  /// model.</summary>
  /// <remarks>Created and owned by <see cref="TglTFPartLibrary"/>; read-only for its
  /// users.</remarks>
  TglTFPart = class
  private
    FSource: TglTFDocument;
    FFileName: string;
    FNodeIndex: Integer;
    FName: string;
    FTriangleCount: Integer;
    FBones: TArray<string>;
    FBoneTriangles: TArray<Integer>;
    FUsedJoints: TArray<Boolean>;
    FError: string;
  public
    //** @abstract(Returns a short description for messages.)
    //**
    //** @returns(For example: "Peasant_Feet" from Peasant.gltf.)
    /// <summary>Returns a short description for messages.</summary>
    /// <returns>For example: "Peasant_Feet" from Peasant.gltf.</returns>
    function Description: string;

    //** @abstract(Returns the bones the part covers with the given settings.)
    //**
    //** @param(AOptions Decide the share a bone needs and the bones never covered.)
    //**
    //** @returns(The bone names, the one driving the most triangles first.)
    /// <summary>Returns the bones the part covers with the given settings.</summary>
    /// <param name="AOptions">Decide the share a bone needs and the bones never
    /// covered.</param>
    /// <returns>The bone names, the one driving the most triangles first.</returns>
    function CoveredBones(const AOptions: TglTFPartOptions): TArray<string>;

    //** @abstract(Returns the bones the part covers with their shares, for display.)
    //**
    //** @param(AOptions Decide the share a bone needs and the bones never covered.)
    //**
    //** @param(AMax Most bones listed; the rest are counted.)
    //**
    //** @returns(For example "foot_l 64%, ball_l 30%"; "none" when it covers no bone.)
    /// <summary>Returns the bones the part covers with their shares, for display.</summary>
    /// <param name="AOptions">Decide the share a bone needs and the bones never
    /// covered.</param>
    /// <param name="AMax">Most bones listed; the rest are counted.</param>
    /// <returns>For example "foot_l 64%, ball_l 30%"; "none" when it covers no
    /// bone.</returns>
    function CoveredText(const AOptions: TglTFPartOptions; AMax: Integer = 4): string;

    //** @abstract(The document the part is in; owned by the library.)
    /// <summary>The document the part is in; owned by the library.</summary>
    property Source: TglTFDocument read FSource;

    //** @abstract(The file the part is in.)
    /// <summary>The file the part is in.</summary>
    property FileName: string read FFileName;

    //** @abstract(Index of the part's node in @code(Source.Root.Nodes).)
    /// <summary>Index of the part's node in <c>Source.Root.Nodes</c>.</summary>
    property NodeIndex: Integer read FNodeIndex;

    //** @abstract(The part's name: its node's name, else its mesh's, else "node N".)
    /// <summary>The part's name: its node's name, else its mesh's, else "node N".</summary>
    property Name: string read FName;

    //** @abstract(Number of triangles of the part.)
    /// <summary>Number of triangles of the part.</summary>
    property TriangleCount: Integer read FTriangleCount;

    //** @abstract(Every bone that drives some of the part's triangles, the one driving the most
    //** first.)
    /// <summary>Every bone that drives some of the part's triangles, the one driving the most
    /// first.</summary>
    property Bones: TArray<string> read FBones;

    //** @abstract(Parallel to @link(Bones): the number of triangles each one drives.)
    /// <summary>Parallel to <see cref="Bones"/>: the number of triangles each one
    /// drives.</summary>
    property BoneTriangles: TArray<Integer> read FBoneTriangles;

    //** @abstract(Why the part cannot be put on a model; empty when it can.)
    /// <summary>Why the part cannot be put on a model; empty when it can.</summary>
    property Error: string read FError;
  end;

  //** @abstract(The part files loaded and the parts found in them.)
  //**
  //** Every node with both a mesh and a skin is a part. Load files with @link(LoadFiles), or
  //** add documents already loaded with @link(AddDocument). The library owns the documents
  //** and the parts.
  /// <summary>The part files loaded and the parts found in them.</summary>
  /// <remarks>Every node with both a mesh and a skin is a part. Load files with
  /// <see cref="LoadFiles"/>, or add documents already loaded with
  /// <see cref="AddDocument"/>. The library owns the documents and the parts.</remarks>
  TglTFPartLibrary = class
  private
    FDocuments: TObjectList<TglTFDocument>;
    FParts: TObjectList<TglTFPart>;
    FLog: TStringList;
    FOnProgress: TglTFProgressEvent;
    // 0 or 1; set and read with TInterlocked
    FAbortFlag: Integer;
    FModelIndex: Integer;
    FModelCount: Integer;
    FLoadingName: string;
    function GetCount: Integer;
    function GetPart(AIndex: Integer): TglTFPart;
    function GetAbortRequested: Boolean;
    procedure Report(const AStage: string; ADone: Double);
    procedure SourceProgress(Sender: TObject; const AProgress: TglTFProgress);
  public
    //** @abstract(Creates an empty library.)
    /// <summary>Creates an empty library.</summary>
    constructor Create;

    //** @abstract(Frees the library, its documents and its parts.)
    /// <summary>Frees the library, its documents and its parts.</summary>
    destructor Destroy; override;

    //** @abstract(Loads part files and adds the parts found in them.)
    //**
    //** A file that cannot be loaded adds a line to @link(Log) and the others are still
    //** loaded. Stops early on an abort.
    //**
    //** @param(AFileNames The .gltf or .glb files.)
    //**
    //** @returns(The number of parts added.)
    /// <summary>Loads part files and adds the parts found in them.</summary>
    /// <param name="AFileNames">The .gltf or .glb files.</param>
    /// <returns>The number of parts added.</returns>
    /// <remarks>A file that cannot be loaded adds a line to <see cref="Log"/> and the others
    /// are still loaded. Stops early on an abort.</remarks>
    function LoadFiles(const AFileNames: TArray<string>): Integer;

    //** @abstract(Adds the parts of a document already loaded.)
    //**
    //** @param(ADoc The document; the library owns it from now on, even when this raises.)
    //**
    //** @param(AFileName The name to show; may be empty.)
    //**
    //** @returns(The number of parts added, those that cannot be put on a model included.)
    /// <summary>Adds the parts of a document already loaded.</summary>
    /// <param name="ADoc">The document; the library owns it from now on, even when this
    /// raises.</param>
    /// <param name="AFileName">The name to show; may be empty.</param>
    /// <returns>The number of parts added, those that cannot be put on a model
    /// included.</returns>
    function AddDocument(ADoc: TglTFDocument; const AFileName: string): Integer;

    //** @abstract(Removes every part and frees every document.)
    /// <summary>Removes every part and frees every document.</summary>
    procedure Clear;

    //** @abstract(Asks LoadFiles to stop after the file it is loading.)
    //**
    //** May be called from any thread.
    /// <summary>Asks LoadFiles to stop after the file it is loading.</summary>
    /// <remarks>May be called from any thread.</remarks>
    procedure RequestAbort;

    //** @abstract(Number of parts.)
    /// <summary>Number of parts.</summary>
    property Count: Integer read GetCount;

    //** @abstract(The parts, in the order of the files and of their nodes.)
    /// <summary>The parts, in the order of the files and of their nodes.</summary>
    property Parts[AIndex: Integer]: TglTFPart read GetPart; default;

    //** @abstract(What happened while loading; cleared by each LoadFiles.)
    /// <summary>What happened while loading; cleared by each LoadFiles.</summary>
    property Log: TStringList read FLog;

    //** @abstract(Whether LoadFiles was asked to stop. May be read from any thread.)
    /// <summary>Whether LoadFiles was asked to stop. May be read from any thread.</summary>
    property AbortRequested: Boolean read GetAbortRequested;

    //** @abstract(Occurs as files are loaded. Called on the loading thread; see
    //** TglTFProgressEvent.)
    /// <summary>Occurs as files are loaded. Called on the loading thread; see
    /// TglTFProgressEvent.</summary>
    property OnProgress: TglTFProgressEvent read FOnProgress write FOnProgress;
  end;

  //** @abstract(A part on a model, as listed by @link(TglTFPartApplier.AppliedParts).)
  /// <summary>A part on a model, as listed by
  /// <see cref="TglTFPartApplier.AppliedParts"/>.</summary>
  TglTFAppliedPart = record
    //** @abstract(Index of its node in the model's @code(Root.Nodes).)
    /// <summary>Index of its node in the model's <c>Root.Nodes</c>.</summary>
    NodeIndex: Integer;

    //** @abstract(The part's name, from the mark in its extras, else its node's name.)
    /// <summary>The part's name, from the mark in its extras, else its node's name.</summary>
    Name: string;

    //** @abstract(The file the part came from, from the mark in its extras.)
    /// <summary>The file the part came from, from the mark in its extras.</summary>
    FileName: string;

    //** @abstract(Number of triangles of the part.)
    /// <summary>Number of triangles of the part.</summary>
    TriangleCount: Integer;

    //** @abstract(The bones it covers with their shares, as TglTFPart.CoveredText gives them.)
    /// <summary>The bones it covers with their shares, as TglTFPart.CoveredText gives
    /// them.</summary>
    CoveredText: string;
  end;

  //** @abstract(Puts parts on a model and takes them off again.)
  //**
  //** Create one per model and keep it as long as the model is open: it remembers the body's
  //** triangles from before the first change, so that hidden triangles can come back. Create
  //** a new one when another model is loaded. See the unit description for what Apply does.
  //**
  //** @longCode(#
  //** Applier := TglTFPartApplier.Create(Doc);
  //** Applier.Apply([Library[0], Library[3]], TglTFPartOptions.Default);
  //** #)
  /// <summary>Puts parts on a model and takes them off again.</summary>
  /// <remarks>Create one per model and keep it as long as the model is open: it remembers the
  /// body's triangles from before the first change, so that hidden triangles can come back.
  /// Create a new one when another model is loaded. See the unit description for what Apply
  /// does.</remarks>
  /// <example><code>
  /// Applier := TglTFPartApplier.Create(Doc);
  /// Applier.Apply([Library[0], Library[3]], TglTFPartOptions.Default);
  /// </code></example>
  TglTFPartApplier = class
  private
    FTarget: TglTFDocument;
    // Keyed by the primitive object's address, not the object: entries of
    // primitives deleted are pruned without touching them
    FOriginals: TDictionary<Pointer, TArray<Cardinal>>;
    FLog: TStringList;
    FOnProgress: TglTFProgressEvent;
    // 0 or 1; set and read with TInterlocked
    FAbortFlag: Integer;
    function GetAbortRequested: Boolean;
    procedure Report(const AStage: string; ADone: Double);
    function ModelTriangles(APrimitive: TglTFMeshPrimitive): TArray<Cardinal>;
    function FindBody(AContext: TObject): Integer;
    procedure TakeOffReplaced(AContext: TObject; APart: TglTFPart; const AOptions: TglTFPartOptions);
    function AddPart(AContext: TObject; APart: TglTFPart): Integer;
    procedure UpdateHidden(AContext: TObject; const AOptions: TglTFPartOptions);
    procedure Finish(AContext: TObject);
  public
    //** @abstract(Creates an applier for a model.)
    //**
    //** @param(ATarget The model; not owned. Nothing else may change its meshes while the
    //** applier is used.)
    /// <summary>Creates an applier for a model.</summary>
    /// <param name="ATarget">The model; not owned. Nothing else may change its meshes while the
    /// applier is used.</param>
    constructor Create(ATarget: TglTFDocument);

    //** @abstract(Frees the applier; the model is not changed.)
    /// <summary>Frees the applier; the model is not changed.</summary>
    destructor Destroy; override;

    //** @abstract(Puts parts on the model.)
    //**
    //** The parts are put on in turn, each taking off the pieces it replaces, so of two parts
    //** that cover the same bones the later one stays. A part that cannot be put on adds a
    //** line to @link(Log) and the others are still put on. Then the body triangles the parts
    //** on the model lie over are hidden and the data no longer used is deleted. An abort stops
    //** between parts; the model is always left valid.
    //**
    //** @param(AParts The parts, from one or more libraries, which must stay alive meanwhile.)
    //**
    //** @param(AOptions Decide which bones each part covers and what it replaces.)
    //**
    //** @returns(The number of parts put on.)
    /// <summary>Puts parts on the model.</summary>
    /// <param name="AParts">The parts, from one or more libraries, which must stay alive
    /// meanwhile.</param>
    /// <param name="AOptions">Decide which bones each part covers and what it
    /// replaces.</param>
    /// <returns>The number of parts put on.</returns>
    /// <remarks>The parts are put on in turn, each taking off the pieces it replaces, so of two
    /// parts that cover the same bones the later one stays. A part that cannot be put on adds a
    /// line to <see cref="Log"/> and the others are still put on. Then the body triangles the
    /// parts on the model lie over are hidden and the data no longer used is deleted. An abort
    /// stops between parts; the model is always left valid.</remarks>
    function Apply(const AParts: TArray<TglTFPart>; const AOptions: TglTFPartOptions): Integer;

    //** @abstract(Takes parts off the model.)
    //**
    //** The parts' nodes are deleted with whatever only they used, and the body triangles
    //** they covered come back unless another part covers them.
    //**
    //** @param(ANodes Indices of part nodes in the model's @code(Root.Nodes), as
    //** @link(AppliedParts) gives them; nodes that are not parts are ignored.)
    //**
    //** @param(AOptions Decide which bones the remaining parts cover.)
    //**
    //** @returns(The number of parts taken off.)
    /// <summary>Takes parts off the model.</summary>
    /// <param name="ANodes">Indices of part nodes in the model's <c>Root.Nodes</c>, as
    /// <see cref="AppliedParts"/> gives them; nodes that are not parts are ignored.</param>
    /// <param name="AOptions">Decide which bones the remaining parts cover.</param>
    /// <returns>The number of parts taken off.</returns>
    /// <remarks>The parts' nodes are deleted with whatever only they used, and the body
    /// triangles they covered come back unless another part covers them.</remarks>
    function Remove(const ANodes: TArray<Integer>; const AOptions: TglTFPartOptions): Integer;

    //** @abstract(Hides the body triangles again with new settings, without putting on or
    //** taking off any part.)
    //**
    //** @param(AOptions Decide which bones the parts on the model cover.)
    /// <summary>Hides the body triangles again with new settings, without putting on or taking
    /// off any part.</summary>
    /// <param name="AOptions">Decide which bones the parts on the model cover.</param>
    procedure Refresh(const AOptions: TglTFPartOptions);

    //** @abstract(Lists the parts on the model.)
    //**
    //** @param(AOptions Decide the bones listed as covered.)
    //**
    //** @returns(One entry per node marked as a part, in node order.)
    /// <summary>Lists the parts on the model.</summary>
    /// <param name="AOptions">Decide the bones listed as covered.</param>
    /// <returns>One entry per node marked as a part, in node order.</returns>
    function AppliedParts(const AOptions: TglTFPartOptions): TArray<TglTFAppliedPart>;

    //** @abstract(Tells whether a node is a part put on by an applier.)
    //**
    //** @param(ANode The node.)
    //**
    //** @returns(True when its extras have the @link(GLTF_PART_EXTRA) mark.)
    /// <summary>Tells whether a node is a part put on by an applier.</summary>
    /// <param name="ANode">The node.</param>
    /// <returns>True when its extras have the <see cref="GLTF_PART_EXTRA"/> mark.</returns>
    class function IsPartNode(ANode: TglTFNode): Boolean; static;

    //** @abstract(Asks Apply to stop after the part it is putting on.)
    //**
    //** May be called from any thread.
    /// <summary>Asks Apply to stop after the part it is putting on.</summary>
    /// <remarks>May be called from any thread.</remarks>
    procedure RequestAbort;

    //** @abstract(The model.)
    /// <summary>The model.</summary>
    property Target: TglTFDocument read FTarget;

    //** @abstract(What happened: parts put on, taken off and replaced, triangles hidden;
    //** cleared by each Apply, Remove and Refresh.)
    /// <summary>What happened: parts put on, taken off and replaced, triangles hidden; cleared
    /// by each Apply, Remove and Refresh.</summary>
    property Log: TStringList read FLog;

    //** @abstract(Whether Apply was asked to stop. May be read from any thread.)
    /// <summary>Whether Apply was asked to stop. May be read from any thread.</summary>
    property AbortRequested: Boolean read GetAbortRequested;

    //** @abstract(Occurs as parts are put on. Called on the applying thread; see
    //** TglTFProgressEvent.)
    /// <summary>Occurs as parts are put on. Called on the applying thread; see
    /// TglTFProgressEvent.</summary>
    property OnProgress: TglTFProgressEvent read FOnProgress write FOnProgress;
  end;

//** @abstract(Reads the triangles of a mesh primitive.)
//**
//** Triangle strips and fans are turned into separate triangles. A primitive without indices
//** uses its vertices in order.
//**
//** @param(ARoot The tree the primitive is in.)
//**
//** @param(APrimitive The primitive.)
//**
//** @returns(Three vertex indices per triangle; nil for points and lines.)
//**
//** @raises(EglTFError The data is missing or does not fit.)
/// <summary>Reads the triangles of a mesh primitive.</summary>
/// <param name="ARoot">The tree the primitive is in.</param>
/// <param name="APrimitive">The primitive.</param>
/// <returns>Three vertex indices per triangle; nil for points and lines.</returns>
/// <exception cref="EglTFError">The data is missing or does not fit.</exception>
/// <remarks>Triangle strips and fans are turned into separate triangles. A primitive without
/// indices uses its vertices in order.</remarks>
function ReadPrimitiveTriangles(ARoot: TglTF; APrimitive: TglTFMeshPrimitive): TArray<Cardinal>;

//** @abstract(Reads the values of an accessor as numbers.)
//**
//** Normalized integers are turned into 0..1 or -1..1, as the glTF specification says; sparse
//** values are applied. Matrices are read as their components in order, without the padding
//** some small matrix types have.
//**
//** @param(ARoot The tree the accessor is in.)
//**
//** @param(AIndex Index in @code(ARoot.Accessors).)
//**
//** @returns(Count times the number of components values; element I's component C is at
//** I * components + C.)
//**
//** @raises(EglTFError The data is missing or does not fit.)
/// <summary>Reads the values of an accessor as numbers.</summary>
/// <param name="ARoot">The tree the accessor is in.</param>
/// <param name="AIndex">Index in <c>ARoot.Accessors</c>.</param>
/// <returns>Count times the number of components values; element I's component C is at
/// I * components + C.</returns>
/// <exception cref="EglTFError">The data is missing or does not fit.</exception>
/// <remarks>Normalized integers are turned into 0..1 or -1..1, as the glTF specification says;
/// sparse values are applied. Matrices are read as their components in order, without the
/// padding some small matrix types have.</remarks>
function ReadAccessorValues(ARoot: TglTF; AIndex: Integer): TArray<Double>;

implementation

uses
  System.Math, System.SyncObjs, System.Generics.Defaults,
  glTF.Edit;

const
  // The bone of a triangle without weights
  NO_BONE = GLTF_UNDEFINED_INDEX;

  // Most JOINTS_n / WEIGHTS_n pairs read per vertex
  MAX_WEIGHT_SETS = 4;

type
  // The triangles of one primitive of a skinned mesh node, with the node
  // (bone) that drives each one
  TPrimitiveTriangles = record
    Primitive: TglTFMeshPrimitive;
    Triangles: TArray<Cardinal>;
    Bones: TArray<Integer>;
  end;

  // Returns the triangles to use for a primitive
  TTriangleSource = reference to function(APrimitive: TglTFMeshPrimitive): TArray<Cardinal>;

  // Bone names to anything, ignoring case
  TBoneSet = TDictionary<string, Boolean>;

{ Reading data }

function ReadComponent(const AData: TBytes; APos: Int64; AType: Integer;
  ANormalized: Boolean): Double;
var
  LShort: SmallInt;
  LWord: Word;
  LCardinal: Cardinal;
  LSingle: Single;
begin
  // Moved into locals: no unaligned loads on ARM
  case AType of
    GLTF_COMPONENT_BYTE:
    begin
      Result := ShortInt(AData[APos]);
      if ANormalized then
        Result := Max(Result / 127, -1);
    end;
    GLTF_COMPONENT_UNSIGNED_BYTE:
    begin
      Result := AData[APos];
      if ANormalized then
        Result := Result / 255;
    end;
    GLTF_COMPONENT_SHORT:
    begin
      Move(AData[APos], LShort, SizeOf(LShort));
      Result := LShort;
      if ANormalized then
        Result := Max(Result / 32767, -1);
    end;
    GLTF_COMPONENT_UNSIGNED_SHORT:
    begin
      Move(AData[APos], LWord, SizeOf(LWord));
      Result := LWord;
      if ANormalized then
        Result := Result / 65535;
    end;
    GLTF_COMPONENT_UNSIGNED_INT:
    begin
      Move(AData[APos], LCardinal, SizeOf(LCardinal));
      Result := LCardinal;
    end;
    GLTF_COMPONENT_FLOAT:
    begin
      Move(AData[APos], LSingle, SizeOf(LSingle));
      Result := LSingle;
    end;
  else
    raise EglTFError.CreateFmt('componentType %d is not supported', [AType]);
  end;
end;

function ComponentSize(AType: Integer): Integer;
begin
  case AType of
    GLTF_COMPONENT_BYTE, GLTF_COMPONENT_UNSIGNED_BYTE: Result := 1;
    GLTF_COMPONENT_SHORT, GLTF_COMPONENT_UNSIGNED_SHORT: Result := 2;
    GLTF_COMPONENT_UNSIGNED_INT, GLTF_COMPONENT_FLOAT: Result := 4;
  else
    raise EglTFError.CreateFmt('componentType %d is not supported', [AType]);
  end;
end;

// The data of the buffer a bufferView is in, checked to hold the view
function ViewData(ARoot: TglTF; AView: Integer; out AViewObject: TglTFBufferView): TBytes;
begin
  if (AView < 0) or (AView >= ARoot.BufferViews.Count) then
    raise EglTFError.CreateFmt('bufferView %d does not exist', [AView]);
  AViewObject := ARoot.BufferViews[AView];
  if (AViewObject.Buffer < 0) or (AViewObject.Buffer >= ARoot.Buffers.Count) then
    raise EglTFError.CreateFmt('bufferView %d refers to buffer %d, which does not exist',
      [AView, AViewObject.Buffer]);
  Result := ARoot.Buffers[AViewObject.Buffer].Data;
  if Result = nil then
    raise EglTFError.CreateFmt('The data of buffer %d is not loaded', [AViewObject.Buffer]);
  if (AViewObject.ByteOffset < 0) or (AViewObject.ByteLength < 0) or
     (AViewObject.ByteOffset + AViewObject.ByteLength > Length(Result)) then
    raise EglTFError.CreateFmt('bufferView %d is outside its buffer', [AView]);
end;

function ReadAccessorValues(ARoot: TglTF; AIndex: Integer): TArray<Double>;
var
  LAccessor: TglTFAccessor;
  LView: TglTFBufferView;
  LData: TBytes;
  LTargets: TArray<Int64>;
  LComps, LSize, LStride, LIndexSize, I, C: Integer;
  LStart, LPos, LViewEnd: Int64;
begin
  if (AIndex < 0) or (AIndex >= ARoot.Accessors.Count) then
    raise EglTFError.CreateFmt('accessor %d does not exist', [AIndex]);
  LAccessor := ARoot.Accessors[AIndex];
  LComps := LAccessor.ComponentCount;
  LSize := LAccessor.ComponentByteSize;
  if (LComps <= 0) or (LSize <= 0) or (LAccessor.Count < 0) then
    raise EglTFError.CreateFmt('accessor %d has a type that cannot be read', [AIndex]);
  SetLength(Result, LAccessor.Count * LComps); // zeros without a bufferView

  // 1. The values in the bufferView
  if (LAccessor.BufferView <> GLTF_UNDEFINED_INDEX) and (LAccessor.Count > 0) then
  begin
    LData := ViewData(ARoot, LAccessor.BufferView, LView);
    LStride := LView.ByteStride;
    if LStride = 0 then
      LStride := LComps * LSize;
    LStart := LView.ByteOffset + LAccessor.ByteOffset;
    LViewEnd := LView.ByteOffset + LView.ByteLength;
    if (LAccessor.ByteOffset < 0) or
       (LStart + Int64(LAccessor.Count - 1) * LStride + LComps * LSize > LViewEnd) then
      raise EglTFError.CreateFmt('accessor %d is outside its bufferView', [AIndex]);
    for I := 0 to LAccessor.Count - 1 do
    begin
      LPos := LStart + Int64(I) * LStride;
      for C := 0 to LComps - 1 do
        Result[I * LComps + C] := ReadComponent(LData, LPos + C * LSize,
          LAccessor.ComponentType, LAccessor.Normalized);
    end;
  end;

  // 2. Sparse values replace some of them
  if Assigned(LAccessor.Sparse) and (LAccessor.Sparse.Count > 0) and
     Assigned(LAccessor.Sparse.Indices) and Assigned(LAccessor.Sparse.Values) then
  begin
    LData := ViewData(ARoot, LAccessor.Sparse.Indices.BufferView, LView);
    LIndexSize := ComponentSize(LAccessor.Sparse.Indices.ComponentType);
    LStart := LView.ByteOffset + LAccessor.Sparse.Indices.ByteOffset;
    if LStart + Int64(LAccessor.Sparse.Count) * LIndexSize > LView.ByteOffset + LView.ByteLength then
      raise EglTFError.CreateFmt('the sparse indices of accessor %d are outside their bufferView',
        [AIndex]);
    SetLength(LTargets, LAccessor.Sparse.Count);
    for I := 0 to LAccessor.Sparse.Count - 1 do
    begin
      LTargets[I] := Trunc(ReadComponent(LData, LStart + Int64(I) * LIndexSize,
        LAccessor.Sparse.Indices.ComponentType, False));
      if (LTargets[I] < 0) or (LTargets[I] >= LAccessor.Count) then
        raise EglTFError.CreateFmt('a sparse index of accessor %d is out of range', [AIndex]);
    end;

    LData := ViewData(ARoot, LAccessor.Sparse.Values.BufferView, LView);
    LStart := LView.ByteOffset + LAccessor.Sparse.Values.ByteOffset;
    if LStart + Int64(LAccessor.Sparse.Count) * LComps * LSize > LView.ByteOffset + LView.ByteLength then
      raise EglTFError.CreateFmt('the sparse values of accessor %d are outside their bufferView',
        [AIndex]);
    for I := 0 to LAccessor.Sparse.Count - 1 do
      for C := 0 to LComps - 1 do
        Result[LTargets[I] * LComps + C] := ReadComponent(LData,
          LStart + (Int64(I) * LComps + C) * LSize, LAccessor.ComponentType, LAccessor.Normalized);
  end;
end;

function VertexCount(ARoot: TglTF; APrimitive: TglTFMeshPrimitive): Integer;
var
  LIndex: Integer;
begin
  LIndex := APrimitive.GetAttribute('POSITION');
  if LIndex = GLTF_UNDEFINED_INDEX then
    for LIndex in APrimitive.Attributes.Values do
      Break;
  if (LIndex < 0) or (LIndex >= ARoot.Accessors.Count) then
    raise EglTFError.Create('A primitive has no attribute that can be read');
  Result := ARoot.Accessors[LIndex].Count;
end;

function IsTriangleMode(AMode: Integer): Boolean;
begin
  Result := (AMode = GLTF_MODE_TRIANGLES) or (AMode = GLTF_MODE_TRIANGLE_STRIP) or
    (AMode = GLTF_MODE_TRIANGLE_FAN);
end;

function ReadPrimitiveTriangles(ARoot: TglTF; APrimitive: TglTFMeshPrimitive): TArray<Cardinal>;
var
  LIndices: TArray<Cardinal>;
  LValues: TArray<Double>;
  LVertices, N, I: Integer;
  LIndex: Cardinal;
begin
  Result := nil;
  if not IsTriangleMode(APrimitive.Mode) then
    Exit;

  LVertices := VertexCount(ARoot, APrimitive);
  if APrimitive.Indices <> GLTF_UNDEFINED_INDEX then
  begin
    LValues := ReadAccessorValues(ARoot, APrimitive.Indices);
    SetLength(LIndices, Length(LValues));
    for I := 0 to High(LValues) do
      LIndices[I] := Cardinal(Trunc(LValues[I]));
  end
  else
  begin
    SetLength(LIndices, LVertices);
    for I := 0 to LVertices - 1 do
      LIndices[I] := I;
  end;
  for LIndex in LIndices do
    if LIndex >= Cardinal(LVertices) then
      raise EglTFError.CreateFmt('A primitive refers to vertex %d of %d', [LIndex, LVertices]);

  // As in the glTF specification, 3.7.2.1
  N := Length(LIndices);
  case APrimitive.Mode of
    GLTF_MODE_TRIANGLES:
      Result := Copy(LIndices, 0, (N div 3) * 3);
    GLTF_MODE_TRIANGLE_STRIP:
      if N >= 3 then
      begin
        SetLength(Result, (N - 2) * 3);
        for I := 0 to N - 3 do
        begin
          Result[I * 3] := LIndices[I];
          Result[I * 3 + 1] := LIndices[I + 1 + I mod 2];
          Result[I * 3 + 2] := LIndices[I + 2 - I mod 2];
        end;
      end;
    GLTF_MODE_TRIANGLE_FAN:
      if N >= 3 then
      begin
        SetLength(Result, (N - 2) * 3);
        for I := 0 to N - 3 do
        begin
          Result[I * 3] := LIndices[I + 1];
          Result[I * 3 + 1] := LIndices[I + 2];
          Result[I * 3 + 2] := LIndices[0];
        end;
      end;
  end;
end;

// For each triangle, the node of the joint with the most weight on its three
// corners; NO_BONE when it has no weights. AUsed is set for every joint with
// a weight on a corner of a triangle
function DominantBones(ARoot: TglTF; ASkin: TglTFSkin; APrimitive: TglTFMeshPrimitive;
  const ATriangles: TArray<Cardinal>; var AUsed: TArray<Boolean>): TArray<Integer>;
var
  LJoints, LWeights: array[0..MAX_WEIGHT_SETS - 1] of TArray<Double>;
  LCandidates: array[0..3 * 4 * MAX_WEIGHT_SETS - 1] of Integer;
  LSums: array[0..3 * 4 * MAX_WEIGHT_SETS - 1] of Double;
  LSets, LVertices, LCount, LBest, LJoint, T, V, S, K, I: Integer;
  LWeight: Double;
  LFound: Boolean;
begin
  SetLength(Result, Length(ATriangles) div 3);
  for T := 0 to High(Result) do
    Result[T] := NO_BONE;
  if Length(AUsed) < Length(ASkin.Joints) then
    SetLength(AUsed, Length(ASkin.Joints));

  LSets := 0;
  while (LSets < MAX_WEIGHT_SETS) and APrimitive.HasAttribute('JOINTS_' + IntToStr(LSets)) and
        APrimitive.HasAttribute('WEIGHTS_' + IntToStr(LSets)) do
  begin
    LJoints[LSets] := ReadAccessorValues(ARoot, APrimitive.GetAttribute('JOINTS_' + IntToStr(LSets)));
    LWeights[LSets] := ReadAccessorValues(ARoot, APrimitive.GetAttribute('WEIGHTS_' + IntToStr(LSets)));
    Inc(LSets);
  end;
  if LSets = 0 then
    Exit;

  LVertices := MaxInt;
  for S := 0 to LSets - 1 do
    LVertices := Min(LVertices, Min(Length(LJoints[S]), Length(LWeights[S])) div 4);

  for T := 0 to High(Result) do
  begin
    LCount := 0;
    for K := 0 to 2 do
    begin
      V := ATriangles[T * 3 + K];
      if V >= LVertices then
        raise EglTFError.CreateFmt('Vertex %d has no joints or weights', [V]);
      for S := 0 to LSets - 1 do
        for I := 0 to 3 do
        begin
          LWeight := LWeights[S][V * 4 + I];
          if LWeight <= 0 then
            Continue;
          LJoint := Round(LJoints[S][V * 4 + I]);
          if (LJoint < 0) or (LJoint >= Length(ASkin.Joints)) then
            raise EglTFError.CreateFmt('Vertex %d uses joint %d of a skin with %d',
              [V, LJoint, Length(ASkin.Joints)]);
          AUsed[LJoint] := True;
          LFound := False;
          for LBest := 0 to LCount - 1 do
            if LCandidates[LBest] = LJoint then
            begin
              LSums[LBest] := LSums[LBest] + LWeight;
              LFound := True;
              Break;
            end;
          if not LFound then
          begin
            LCandidates[LCount] := LJoint;
            LSums[LCount] := LWeight;
            Inc(LCount);
          end;
        end;
    end;
    if LCount = 0 then
      Continue;
    LBest := 0;
    for I := 1 to LCount - 1 do
      if LSums[I] > LSums[LBest] then
        LBest := I;
    Result[T] := ASkin.Joints[LCandidates[LBest]];
  end;
end;

function HasSkinnedMesh(ARoot: TglTF; ANode: Integer): Boolean;
var
  LNode: TglTFNode;
begin
  LNode := ARoot.Nodes[ANode];
  Result := (LNode.Mesh >= 0) and (LNode.Mesh < ARoot.Meshes.Count) and
    (LNode.Skin >= 0) and (LNode.Skin < ARoot.Skins.Count);
end;

// The triangles of every triangle primitive of a skinned mesh node, with the
// bone of each one. ASource gives the triangles; nil reads them
function AnalyzeNode(ARoot: TglTF; ANode: Integer; const ASource: TTriangleSource;
  var AUsed: TArray<Boolean>): TArray<TPrimitiveTriangles>;
var
  LNode: TglTFNode;
  LSkin: TglTFSkin;
  LPrimitive: TglTFMeshPrimitive;
  LItem: TPrimitiveTriangles;
begin
  Result := nil;
  if not HasSkinnedMesh(ARoot, ANode) then
    Exit;
  LNode := ARoot.Nodes[ANode];
  LSkin := ARoot.Skins[LNode.Skin];
  for LPrimitive in ARoot.Meshes[LNode.Mesh].Primitives do
  begin
    if not IsTriangleMode(LPrimitive.Mode) then
      Continue;
    LItem.Primitive := LPrimitive;
    if Assigned(ASource) then
      LItem.Triangles := ASource(LPrimitive)
    else
      LItem.Triangles := ReadPrimitiveTriangles(ARoot, LPrimitive);
    LItem.Bones := DominantBones(ARoot, LSkin, LPrimitive, LItem.Triangles, AUsed);
    Result := Result + [LItem];
  end;
end;

function BoneName(ARoot: TglTF; ANode: Integer): string;
begin
  if (ANode >= 0) and (ANode < ARoot.Nodes.Count) and (ARoot.Nodes[ANode].Name <> '') then
    Result := ARoot.Nodes[ANode].Name
  else
    Result := Format('node %d', [ANode]);
end;

function NewBoneSet: TBoneSet;
begin
  Result := TBoneSet.Create(TIStringComparer.Ordinal);
end;

// Triangles per bone, the bone driving the most first; ATotal counts every
// triangle, those without a bone included
procedure CountBones(ARoot: TglTF; const APrimitives: TArray<TPrimitiveTriangles>;
  out ANames: TArray<string>; out ACounts: TArray<Integer>; out ATotal: Integer);
var
  LCounts: TDictionary<string, Integer>;
  LPairs: TArray<TPair<string, Integer>>;
  LItem: TPrimitiveTriangles;
  LBone, LCount, I: Integer;
  LName: string;
begin
  ATotal := 0;
  LCounts := TDictionary<string, Integer>.Create(TIStringComparer.Ordinal);
  try
    for LItem in APrimitives do
      for LBone in LItem.Bones do
      begin
        Inc(ATotal);
        if LBone = NO_BONE then
          Continue;
        LName := BoneName(ARoot, LBone);
        if LCounts.TryGetValue(LName, LCount) then
          LCounts[LName] := LCount + 1
        else
          LCounts.Add(LName, 1);
      end;
    LPairs := LCounts.ToArray;
  finally
    LCounts.Free;
  end;

  TArray.Sort<TPair<string, Integer>>(LPairs, TComparer<TPair<string, Integer>>.Construct(
    function(const A, B: TPair<string, Integer>): Integer
    begin
      Result := B.Value - A.Value;
      if Result = 0 then
        Result := CompareText(A.Key, B.Key);
    end));
  SetLength(ANames, Length(LPairs));
  SetLength(ACounts, Length(LPairs));
  for I := 0 to High(LPairs) do
  begin
    ANames[I] := LPairs[I].Key;
    ACounts[I] := LPairs[I].Value;
  end;
end;

// The bones that drive at least MinShare of the triangles, KeepBones left out
function CoveredOf(const ANames: TArray<string>; const ACounts: TArray<Integer>;
  ATotal: Integer; const AOptions: TglTFPartOptions): TArray<string>;
var
  I: Integer;
begin
  Result := nil;
  if ATotal <= 0 then
    Exit;
  for I := 0 to High(ANames) do
    if (ACounts[I] > 0) and (ACounts[I] / ATotal >= AOptions.MinShare) and
       not AOptions.IsKept(ANames[I]) then
      Result := Result + [ANames[I]];
end;

function CoveredTextOf(const ANames: TArray<string>; const ACounts: TArray<Integer>;
  ATotal: Integer; const AOptions: TglTFPartOptions; AMax: Integer): string;
var
  LCovered: TArray<string>;
  LTexts: TArray<string>;
  I, J: Integer;
begin
  LCovered := CoveredOf(ANames, ACounts, ATotal, AOptions);
  if LCovered = nil then
    Exit('none');
  LTexts := nil;
  for I := 0 to Min(High(LCovered), AMax - 1) do
    for J := 0 to High(ANames) do
      if ANames[J] = LCovered[I] then
      begin
        LTexts := LTexts + [Format('%s %d%%', [ANames[J], Round(100 * ACounts[J] / ATotal)])];
        Break;
      end;
  Result := string.Join(', ', LTexts);
  if Length(LCovered) > AMax then
    Result := Result + Format(' +%d more', [Length(LCovered) - AMax]);
end;

function SameTriangles(const A, B: TArray<Cardinal>): Boolean;
begin
  Result := (Length(A) = Length(B)) and
    ((Length(A) = 0) or CompareMem(@A[0], @B[0], Length(A) * SizeOf(Cardinal)));
end;

function SameBytes(const A, B: TBytes): Boolean;
begin
  Result := (Length(A) = Length(B)) and
    ((Length(A) = 0) or CompareMem(@A[0], @B[0], Length(A)));
end;

// A copy of a glTF object made through its JSON, so extras and extensions
// come along
function CloneProperty(ASource: TglTFProperty; const AJSONPath: string): TglTFProperty;
var
  LJSON: TJSONObject;
begin
  LJSON := ASource.SaveToJSON;
  try
    Result := TglTFPropertyClass(ASource.ClassType).Create;
    try
      Result.LoadFromJSON(LJSON, AJSONPath);
    except
      Result.Free;
      raise;
    end;
  finally
    LJSON.Free;
  end;
end;

// The last segment of a uri, for example "wood.png" for "textures/wood.png"
function UriFileName(const AUri: string): string;
var
  LPos: Integer;
begin
  LPos := Max(AUri.LastIndexOf('/'), AUri.LastIndexOf('\'));
  Result := AUri.Substring(LPos + 1);
end;

{ Geometry: where the vertices are at rest }

type
  TVec3 = record
    X, Y, Z: Double;
  end;

  // Column-major, as glTF stores matrices: element (row R, column C) is at C * 4 + R
  TMat4 = array[0..15] of Double;

function Vec3(AX, AY, AZ: Double): TVec3;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
end;

function VSub(const A, B: TVec3): TVec3;
begin
  Result := Vec3(A.X - B.X, A.Y - B.Y, A.Z - B.Z);
end;

function VAdd(const A, B: TVec3): TVec3;
begin
  Result := Vec3(A.X + B.X, A.Y + B.Y, A.Z + B.Z);
end;

function VScale(const A: TVec3; AFactor: Double): TVec3;
begin
  Result := Vec3(A.X * AFactor, A.Y * AFactor, A.Z * AFactor);
end;

function VDot(const A, B: TVec3): Double;
begin
  Result := A.X * B.X + A.Y * B.Y + A.Z * B.Z;
end;

function VCross(const A, B: TVec3): TVec3;
begin
  Result := Vec3(A.Y * B.Z - A.Z * B.Y, A.Z * B.X - A.X * B.Z, A.X * B.Y - A.Y * B.X);
end;

function VNormalized(const A: TVec3): TVec3;
var
  LLength: Double;
begin
  LLength := Sqrt(VDot(A, A));
  if LLength > 1E-12 then
    Result := VScale(A, 1 / LLength)
  else
    Result := Vec3(0, 0, 0);
end;

function MatIdentity: TMat4;
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

function MatMul(const A, B: TMat4): TMat4;
var
  R, C, K: Integer;
  LSum: Double;
begin
  for C := 0 to 3 do
    for R := 0 to 3 do
    begin
      LSum := 0;
      for K := 0 to 3 do
        LSum := LSum + A[K * 4 + R] * B[C * 4 + K];
      Result[C * 4 + R] := LSum;
    end;
end;

function MatPoint(const M: TMat4; const P: TVec3): TVec3;
begin
  Result := Vec3(M[0] * P.X + M[4] * P.Y + M[8] * P.Z + M[12],
                 M[1] * P.X + M[5] * P.Y + M[9] * P.Z + M[13],
                 M[2] * P.X + M[6] * P.Y + M[10] * P.Z + M[14]);
end;

function MatDirection(const M: TMat4; const D: TVec3): TVec3;
begin
  Result := Vec3(M[0] * D.X + M[4] * D.Y + M[8] * D.Z,
                 M[1] * D.X + M[5] * D.Y + M[9] * D.Z,
                 M[2] * D.X + M[6] * D.Y + M[10] * D.Z);
end;

// A node's own transform: its matrix, or translation, rotation and scale
function NodeLocalMatrix(ANode: TglTFNode): TMat4;
var
  LX, LY, LZ, LW, LSX, LSY, LSZ: Double;
  I: Integer;
begin
  if ANode.HasMatrix and (Length(ANode.Matrix) = 16) then
  begin
    for I := 0 to 15 do
      Result[I] := ANode.Matrix[I];
    Exit;
  end;
  LX := 0; LY := 0; LZ := 0; LW := 1;
  if Length(ANode.Rotation) = 4 then
  begin
    LX := ANode.Rotation[0]; LY := ANode.Rotation[1]; LZ := ANode.Rotation[2]; LW := ANode.Rotation[3];
  end;
  LSX := 1; LSY := 1; LSZ := 1;
  if Length(ANode.Scale) = 3 then
  begin
    LSX := ANode.Scale[0]; LSY := ANode.Scale[1]; LSZ := ANode.Scale[2];
  end;
  // T * R * S
  Result := MatIdentity;
  Result[0] := (1 - 2 * (LY * LY + LZ * LZ)) * LSX;
  Result[1] := (2 * (LX * LY + LZ * LW)) * LSX;
  Result[2] := (2 * (LX * LZ - LY * LW)) * LSX;
  Result[4] := (2 * (LX * LY - LZ * LW)) * LSY;
  Result[5] := (1 - 2 * (LX * LX + LZ * LZ)) * LSY;
  Result[6] := (2 * (LY * LZ + LX * LW)) * LSY;
  Result[8] := (2 * (LX * LZ + LY * LW)) * LSZ;
  Result[9] := (2 * (LY * LZ - LX * LW)) * LSZ;
  Result[10] := (1 - 2 * (LX * LX + LY * LY)) * LSZ;
  if Length(ANode.Translation) = 3 then
  begin
    Result[12] := ANode.Translation[0];
    Result[13] := ANode.Translation[1];
    Result[14] := ANode.Translation[2];
  end;
end;

// Every node's transform in the scene, at rest
function NodeWorldMatrices(ARoot: TglTF): TArray<TMat4>;
var
  LWorld: TArray<TMat4>;
  LParent: TArray<Integer>;
  LDone: TArray<Boolean>;
  LChild, I: Integer;

  procedure Resolve(AIndex, ADepth: Integer);
  begin
    if LDone[AIndex] then
      Exit;
    LDone[AIndex] := True; // set first: a cycle (invalid glTF) ends here
    LWorld[AIndex] := NodeLocalMatrix(ARoot.Nodes[AIndex]);
    if (LParent[AIndex] >= 0) and (ADepth < ARoot.Nodes.Count) then
    begin
      Resolve(LParent[AIndex], ADepth + 1);
      LWorld[AIndex] := MatMul(LWorld[LParent[AIndex]], LWorld[AIndex]);
    end;
  end;

begin
  SetLength(LWorld, ARoot.Nodes.Count);
  SetLength(LParent, ARoot.Nodes.Count);
  SetLength(LDone, ARoot.Nodes.Count);
  for I := 0 to High(LParent) do
    LParent[I] := GLTF_UNDEFINED_INDEX;
  for I := 0 to ARoot.Nodes.Count - 1 do
    for LChild in ARoot.Nodes[I].Children do
      if (LChild >= 0) and (LChild < ARoot.Nodes.Count) then
        LParent[LChild] := I;
  for I := 0 to ARoot.Nodes.Count - 1 do
    Resolve(I, 0);
  Result := LWorld;
end;

type
  // A primitive's vertices skinned to the skeleton at rest
  TSkinnedVertices = record
    Positions: TArray<TVec3>;
    Normals: TArray<TVec3>;
    // The vertex's strongest bone is one of KeepBones
    Kept: TArray<Boolean>;
  end;

// Where a skinned primitive's vertices are with the skeleton at rest: each
// vertex moved by its joints' world matrices times their inverse bind
// matrices, as a renderer does. Parts copied into the model use the model's
// bones, so body and parts end up in the same space whatever their rest
// poses. Normals come from NORMAL, or from ATriangles when it is missing
function SkinVertices(ARoot: TglTF; ASkin: TglTFSkin; APrimitive: TglTFMeshPrimitive;
  const AWorld: TArray<TMat4>; const ATriangles: TArray<Cardinal>;
  const AOptions: TglTFPartOptions): TSkinnedVertices;
var
  LJointMatrices: TArray<TMat4>;
  LInverse, LPositions, LNormals: TArray<Double>;
  LJoints, LWeights: array[0..MAX_WEIGHT_SETS - 1] of TArray<Double>;
  LMatrix: TMat4;
  LKeptJoint: TArray<Boolean>;
  LSets, LCount, LJoint, LStrongest, V, S, K, I: Integer;
  LWeight, LSum, LBest: Double;
  LA, LB, LC, LFace: TVec3;
begin
  // 1. Each joint's world matrix times its inverse bind matrix
  SetLength(LJointMatrices, Length(ASkin.Joints));
  SetLength(LKeptJoint, Length(ASkin.Joints));
  LInverse := nil;
  if ASkin.InverseBindMatrices <> GLTF_UNDEFINED_INDEX then
    LInverse := ReadAccessorValues(ARoot, ASkin.InverseBindMatrices);
  for K := 0 to High(ASkin.Joints) do
  begin
    if (ASkin.Joints[K] >= 0) and (ASkin.Joints[K] < Length(AWorld)) then
      LJointMatrices[K] := AWorld[ASkin.Joints[K]]
    else
      LJointMatrices[K] := MatIdentity;
    if Length(LInverse) >= (K + 1) * 16 then
    begin
      for I := 0 to 15 do
        LMatrix[I] := LInverse[K * 16 + I];
      LJointMatrices[K] := MatMul(LJointMatrices[K], LMatrix);
    end;
    LKeptJoint[K] := AOptions.IsKept(BoneName(ARoot, ASkin.Joints[K]));
  end;

  // 2. The vertex data
  LPositions := ReadAccessorValues(ARoot, APrimitive.GetAttribute('POSITION'));
  LCount := Length(LPositions) div 3;
  LNormals := nil;
  if APrimitive.HasAttribute('NORMAL') then
    LNormals := ReadAccessorValues(ARoot, APrimitive.GetAttribute('NORMAL'));
  LSets := 0;
  while (LSets < MAX_WEIGHT_SETS) and APrimitive.HasAttribute('JOINTS_' + IntToStr(LSets)) and
        APrimitive.HasAttribute('WEIGHTS_' + IntToStr(LSets)) do
  begin
    LJoints[LSets] := ReadAccessorValues(ARoot, APrimitive.GetAttribute('JOINTS_' + IntToStr(LSets)));
    LWeights[LSets] := ReadAccessorValues(ARoot, APrimitive.GetAttribute('WEIGHTS_' + IntToStr(LSets)));
    if (Length(LJoints[LSets]) < LCount * 4) or (Length(LWeights[LSets]) < LCount * 4) then
      raise EglTFError.Create('A primitive has fewer joints or weights than vertices');
    Inc(LSets);
  end;

  // 3. Each vertex, by the weighted sum of its joints' matrices
  SetLength(Result.Positions, LCount);
  SetLength(Result.Normals, LCount);
  SetLength(Result.Kept, LCount);
  for V := 0 to LCount - 1 do
  begin
    for I := 0 to 15 do
      LMatrix[I] := 0;
    LSum := 0;
    LBest := 0;
    LStrongest := GLTF_UNDEFINED_INDEX;
    for S := 0 to LSets - 1 do
      for K := 0 to 3 do
      begin
        LWeight := LWeights[S][V * 4 + K];
        if LWeight <= 0 then
          Continue;
        LJoint := Round(LJoints[S][V * 4 + K]);
        if (LJoint < 0) or (LJoint >= Length(LJointMatrices)) then
          raise EglTFError.CreateFmt('Vertex %d uses joint %d of a skin with %d',
            [V, LJoint, Length(LJointMatrices)]);
        for I := 0 to 15 do
          LMatrix[I] := LMatrix[I] + LWeight * LJointMatrices[LJoint][I];
        LSum := LSum + LWeight;
        if LWeight > LBest then
        begin
          LBest := LWeight;
          LStrongest := LJoint;
        end;
      end;
    if LSum > 0 then
      for I := 0 to 15 do
        LMatrix[I] := LMatrix[I] / LSum
    else
      LMatrix := MatIdentity;
    Result.Positions[V] := MatPoint(LMatrix,
      Vec3(LPositions[V * 3], LPositions[V * 3 + 1], LPositions[V * 3 + 2]));
    if Length(LNormals) >= (V + 1) * 3 then
      Result.Normals[V] := VNormalized(MatDirection(LMatrix,
        Vec3(LNormals[V * 3], LNormals[V * 3 + 1], LNormals[V * 3 + 2])));
    Result.Kept[V] := (LStrongest >= 0) and LKeptJoint[LStrongest];
  end;

  // 4. Without NORMAL: each vertex's triangles, weighted by their area
  if LNormals = nil then
  begin
    for I := 0 to (Length(ATriangles) div 3) - 1 do
    begin
      LA := Result.Positions[ATriangles[I * 3]];
      LB := Result.Positions[ATriangles[I * 3 + 1]];
      LC := Result.Positions[ATriangles[I * 3 + 2]];
      LFace := VCross(VSub(LB, LA), VSub(LC, LA));
      for K := 0 to 2 do
        Result.Normals[ATriangles[I * 3 + K]] := VAdd(Result.Normals[ATriangles[I * 3 + K]], LFace);
    end;
    for V := 0 to LCount - 1 do
      Result.Normals[V] := VNormalized(Result.Normals[V]);
  end;
end;

type
  // The triangles of the parts, sorted into a grid of cells, so that a line
  // is only tested against the triangles near it
  TTriangleGrid = class
  private
    FA, FEdge1, FEdge2, FLow, FHigh: TList<TVec3>;
    FCells: TArray<TArray<Integer>>;
    FStamp: TArray<Integer>;
    FStampValue: Integer;
    FMin, FMax: TVec3;
    FCell: Double;
    FDims: array[0..2] of Integer;
    function CellOf(AValue: Double; AAxis: Integer): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddTriangle(const A, B, C: TVec3);
    procedure Build;
    function HitsLine(const AOrigin, ADirection: TVec3; AReach: Double): Boolean;
    function Count: Integer;
  end;

constructor TTriangleGrid.Create;
begin
  inherited Create;
  FA := TList<TVec3>.Create;
  FEdge1 := TList<TVec3>.Create;
  FEdge2 := TList<TVec3>.Create;
  FLow := TList<TVec3>.Create;
  FHigh := TList<TVec3>.Create;
end;

destructor TTriangleGrid.Destroy;
begin
  FHigh.Free;
  FLow.Free;
  FEdge2.Free;
  FEdge1.Free;
  FA.Free;
  inherited;
end;

function TTriangleGrid.Count: Integer;
begin
  Result := FA.Count;
end;

procedure TTriangleGrid.AddTriangle(const A, B, C: TVec3);
begin
  FA.Add(A);
  FEdge1.Add(VSub(B, A));
  FEdge2.Add(VSub(C, A));
  FLow.Add(Vec3(Min(A.X, Min(B.X, C.X)), Min(A.Y, Min(B.Y, C.Y)), Min(A.Z, Min(B.Z, C.Z))));
  FHigh.Add(Vec3(Max(A.X, Max(B.X, C.X)), Max(A.Y, Max(B.Y, C.Y)), Max(A.Z, Max(B.Z, C.Z))));
end;

function TTriangleGrid.CellOf(AValue: Double; AAxis: Integer): Integer;
var
  LLow: Double;
begin
  case AAxis of
    0: LLow := FMin.X;
    1: LLow := FMin.Y;
  else
    LLow := FMin.Z;
  end;
  Result := EnsureRange(Floor((AValue - LLow) / FCell), 0, FDims[AAxis] - 1);
end;

procedure TTriangleGrid.Build;
const
  MAX_CELLS = 48; // per axis
var
  LExtent: Double;
  LLists: TArray<TList<Integer>>;
  X0, X1, Y0, Y1, Z0, Z1, X, Y, Z, T, I: Integer;
begin
  if FA.Count = 0 then
    Exit;
  FMin := FLow[0];
  FMax := FHigh[0];
  for T := 1 to FA.Count - 1 do
  begin
    FMin := Vec3(Min(FMin.X, FLow[T].X), Min(FMin.Y, FLow[T].Y), Min(FMin.Z, FLow[T].Z));
    FMax := Vec3(Max(FMax.X, FHigh[T].X), Max(FMax.Y, FHigh[T].Y), Max(FMax.Z, FHigh[T].Z));
  end;
  LExtent := Max(FMax.X - FMin.X, Max(FMax.Y - FMin.Y, FMax.Z - FMin.Z));
  FCell := Max(LExtent / MAX_CELLS, 1E-9);
  FDims[0] := EnsureRange(Ceil((FMax.X - FMin.X) / FCell) + 1, 1, MAX_CELLS + 1);
  FDims[1] := EnsureRange(Ceil((FMax.Y - FMin.Y) / FCell) + 1, 1, MAX_CELLS + 1);
  FDims[2] := EnsureRange(Ceil((FMax.Z - FMin.Z) / FCell) + 1, 1, MAX_CELLS + 1);

  SetLength(LLists, FDims[0] * FDims[1] * FDims[2]);
  try
    for T := 0 to FA.Count - 1 do
    begin
      X0 := CellOf(FLow[T].X, 0); X1 := CellOf(FHigh[T].X, 0);
      Y0 := CellOf(FLow[T].Y, 1); Y1 := CellOf(FHigh[T].Y, 1);
      Z0 := CellOf(FLow[T].Z, 2); Z1 := CellOf(FHigh[T].Z, 2);
      for X := X0 to X1 do
        for Y := Y0 to Y1 do
          for Z := Z0 to Z1 do
          begin
            I := (Z * FDims[1] + Y) * FDims[0] + X;
            if LLists[I] = nil then
              LLists[I] := TList<Integer>.Create;
            LLists[I].Add(T);
          end;
    end;
    SetLength(FCells, Length(LLists));
    for I := 0 to High(LLists) do
      if LLists[I] <> nil then
        FCells[I] := LLists[I].ToArray;
  finally
    for I := 0 to High(LLists) do
      LLists[I].Free;
  end;
  SetLength(FStamp, FA.Count);
end;

function TTriangleGrid.HitsLine(const AOrigin, ADirection: TVec3; AReach: Double): Boolean;
const
  EPSILON = 1E-9;
var
  LStart, LEnd, LP, LS, LQ: TVec3;
  LDet, LInv, U, W, T: Double;
  X0, X1, Y0, Y1, Z0, Z1, X, Y, Z, LTri: Integer;
begin
  // Does the line through AOrigin along ADirection meet a triangle within
  // AReach either side of AOrigin?
  Result := False;
  if (FA.Count = 0) or (VDot(ADirection, ADirection) < EPSILON) then
    Exit;
  LStart := VSub(AOrigin, VScale(ADirection, AReach));
  LEnd := VAdd(AOrigin, VScale(ADirection, AReach));
  if (Max(LStart.X, LEnd.X) < FMin.X) or (Min(LStart.X, LEnd.X) > FMax.X) or
     (Max(LStart.Y, LEnd.Y) < FMin.Y) or (Min(LStart.Y, LEnd.Y) > FMax.Y) or
     (Max(LStart.Z, LEnd.Z) < FMin.Z) or (Min(LStart.Z, LEnd.Z) > FMax.Z) then
    Exit;
  X0 := CellOf(Min(LStart.X, LEnd.X), 0); X1 := CellOf(Max(LStart.X, LEnd.X), 0);
  Y0 := CellOf(Min(LStart.Y, LEnd.Y), 1); Y1 := CellOf(Max(LStart.Y, LEnd.Y), 1);
  Z0 := CellOf(Min(LStart.Z, LEnd.Z), 2); Z1 := CellOf(Max(LStart.Z, LEnd.Z), 2);

  Inc(FStampValue);
  for X := X0 to X1 do
    for Y := Y0 to Y1 do
      for Z := Z0 to Z1 do
        for LTri in FCells[(Z * FDims[1] + Y) * FDims[0] + X] do
        begin
          if FStamp[LTri] = FStampValue then
            Continue; // already tested from another cell
          FStamp[LTri] := FStampValue;
          // Moller-Trumbore
          LP := VCross(ADirection, FEdge2[LTri]);
          LDet := VDot(FEdge1[LTri], LP);
          if Abs(LDet) < EPSILON then
            Continue;
          LInv := 1 / LDet;
          LS := VSub(AOrigin, FA[LTri]);
          U := VDot(LS, LP) * LInv;
          if (U < -EPSILON) or (U > 1 + EPSILON) then
            Continue;
          LQ := VCross(LS, FEdge1[LTri]);
          W := VDot(ADirection, LQ) * LInv;
          if (W < -EPSILON) or (U + W > 1 + EPSILON) then
            Continue;
          T := VDot(FEdge2[LTri], LQ) * LInv;
          if Abs(T) <= AReach then
            Exit(True);
        end;
end;

{ TglTFPartOptions }

class function TglTFPartOptions.Default: TglTFPartOptions;
begin
  Result.CoverGap := 0.03;
  Result.MinShare := 0.02;
  Result.ReplaceShare := 0.5;
  Result.KeepBones := nil;
end;

function TglTFPartOptions.IsKept(const ABone: string): Boolean;
var
  LBone: string;
begin
  for LBone in KeepBones do
    if SameText(Trim(LBone), ABone) then
      Exit(True);
  Result := False;
end;

{ TglTFPart }

function TglTFPart.Description: string;
begin
  Result := Format('"%s"', [FName]);
  if FFileName <> '' then
    Result := Result + ' from ' + ExtractFileName(FFileName);
end;

function TglTFPart.CoveredBones(const AOptions: TglTFPartOptions): TArray<string>;
begin
  Result := CoveredOf(FBones, FBoneTriangles, FTriangleCount, AOptions);
end;

function TglTFPart.CoveredText(const AOptions: TglTFPartOptions; AMax: Integer): string;
begin
  Result := CoveredTextOf(FBones, FBoneTriangles, FTriangleCount, AOptions, AMax);
end;

{ TglTFPartLibrary }

constructor TglTFPartLibrary.Create;
begin
  inherited Create;
  FDocuments := TObjectList<TglTFDocument>.Create(True);
  FParts := TObjectList<TglTFPart>.Create(True);
  FLog := TStringList.Create;
  FModelIndex := 1;
  FModelCount := 1;
end;

destructor TglTFPartLibrary.Destroy;
begin
  FParts.Free;
  FDocuments.Free;
  FLog.Free;
  inherited;
end;

function TglTFPartLibrary.GetCount: Integer;
begin
  Result := FParts.Count;
end;

function TglTFPartLibrary.GetPart(AIndex: Integer): TglTFPart;
begin
  Result := FParts[AIndex];
end;

function TglTFPartLibrary.GetAbortRequested: Boolean;
begin
  Result := TInterlocked.CompareExchange(FAbortFlag, 0, 0) <> 0;
end;

procedure TglTFPartLibrary.RequestAbort;
begin
  TInterlocked.Exchange(FAbortFlag, 1);
end;

procedure TglTFPartLibrary.Report(const AStage: string; ADone: Double);
var
  LProgress: TglTFProgress;
begin
  if not Assigned(FOnProgress) then
    Exit;
  LProgress.ModelIndex := FModelIndex;
  LProgress.ModelCount := FModelCount;
  LProgress.ModelName := FLoadingName;
  LProgress.Stage := AStage;
  LProgress.Done := ADone;
  FOnProgress(Self, LProgress);
end;

procedure TglTFPartLibrary.SourceProgress(Sender: TObject; const AProgress: TglTFProgress);
begin
  // A file's load is most of its model; finding its parts the rest
  Report(AProgress.Stage, 0.9 * AProgress.Done);
end;

procedure TglTFPartLibrary.Clear;
begin
  FParts.Clear;
  FDocuments.Clear;
end;

function TglTFPartLibrary.LoadFiles(const AFileNames: TArray<string>): Integer;
var
  LDoc: TglTFDocument;
  I: Integer;
begin
  Result := 0;
  FLog.Clear;
  TInterlocked.Exchange(FAbortFlag, 0);
  FModelCount := Length(AFileNames);
  for I := 0 to High(AFileNames) do
  begin
    if AbortRequested then
    begin
      FLog.Add(Format('Aborted: %d file(s) not read', [Length(AFileNames) - I]));
      Break;
    end;
    FModelIndex := I + 1;
    FLoadingName := ExtractFileName(AFileNames[I]);
    LDoc := TglTFDocument.Create;
    try
      LDoc.OnProgress := SourceProgress;
      LDoc.LoadFromFile(AFileNames[I]);
      LDoc.OnProgress := nil;
    except
      on E: Exception do
      begin
        LDoc.Free;
        FLog.Add(Format('%s: not loaded: %s', [FLoadingName, E.Message]));
        Continue;
      end;
    end;
    Report('Finding the parts', 0.9);
    Inc(Result, AddDocument(LDoc, AFileNames[I]));
    Report('Done', 1);
  end;
end;

function TglTFPartLibrary.AddDocument(ADoc: TglTFDocument; const AFileName: string): Integer;
var
  LRoot: TglTF;
  LNode: TglTFNode;
  LPart: TglTFPart;
  LPrimitives: TArray<TPrimitiveTriangles>;
  LUsed: TArray<Boolean>;
  LShort, LExtension: string;
  LCompressed: Boolean;
  LUnskinned, I: Integer;
begin
  Result := 0;
  FDocuments.Add(ADoc);
  LRoot := ADoc.Root;
  LShort := ExtractFileName(AFileName);
  if LShort = '' then
    LShort := 'stream';
  LCompressed := TglTFEdit.UsesBufferViewExtension(LRoot, LExtension);
  LUnskinned := 0;

  for I := 0 to LRoot.Nodes.Count - 1 do
  begin
    LNode := LRoot.Nodes[I];
    if LNode.Mesh = GLTF_UNDEFINED_INDEX then
      Continue;
    if LNode.Skin = GLTF_UNDEFINED_INDEX then
    begin
      Inc(LUnskinned);
      Continue;
    end;

    LPart := TglTFPart.Create;
    FParts.Add(LPart);
    Inc(Result);
    LPart.FSource := ADoc;
    LPart.FFileName := AFileName;
    LPart.FNodeIndex := I;
    LPart.FName := LNode.Name;
    if (LPart.FName = '') and (LNode.Mesh < LRoot.Meshes.Count) then
      LPart.FName := LRoot.Meshes[LNode.Mesh].Name;
    if LPart.FName = '' then
      LPart.FName := Format('node %d', [I]);

    try
      if LCompressed then
        raise EglTFError.CreateFmt('the file uses %s, whose compressed data cannot be copied',
          [LExtension]);
      if not HasSkinnedMesh(LRoot, I) then
        raise EglTFError.Create('its mesh or skin does not exist');
      LUsed := nil;
      LPrimitives := AnalyzeNode(LRoot, I, nil, LUsed);
      CountBones(LRoot, LPrimitives, LPart.FBones, LPart.FBoneTriangles, LPart.FTriangleCount);
      LPart.FUsedJoints := LUsed;
      if LPart.FTriangleCount = 0 then
        raise EglTFError.Create('it has no triangles');
      if LPart.FBones = nil then
        raise EglTFError.Create('none of its vertices has bone weights');
    except
      on E: Exception do
      begin
        LPart.FError := E.Message;
        FLog.Add(Format('%s: part "%s" cannot be used: %s', [LShort, LPart.FName, E.Message]));
      end;
    end;
  end;

  FLog.Add(Format('%s: %d part(s)', [LShort, Result]));
  if LUnskinned > 0 then
    FLog.Add(Format('%s: %d mesh node(s) without a skin ignored: only skinned meshes follow ' +
      'the model''s bones', [LShort, LUnskinned]));
end;

{ Applying }

type
  // Data appended to the model while applying: collected, then written to
  // the model's data buffer once (appending each time would copy the buffer
  // for every bufferView)
  TDataAppender = class
  private
    FRoot: TglTF;
    FBuffer: Integer;
    FPending: TMemoryStream;
    FBase: Int64;
  public
    constructor Create(ARoot: TglTF);
    destructor Destroy; override;
    function AddView(const AData: TBytes; ATarget, AStride: Integer): Integer;
    procedure Flush;
  end;

  // What was copied from one part file in one Apply: its index -> the model's
  TSourceMaps = class
  public
    Views: TDictionary<Integer, Integer>;
    Accessors: TDictionary<Integer, Integer>;
    Materials: TDictionary<Integer, Integer>;
    Textures: TDictionary<Integer, Integer>;
    Images: TDictionary<Integer, Integer>;
    Samplers: TDictionary<Integer, Integer>;
    Skins: TDictionary<Integer, Integer>;
    constructor Create;
    destructor Destroy; override;
  end;

  // One Apply, Remove or Refresh. Nothing in the model is deleted until
  // Finish, so the indices kept here stay valid until then
  TApplyContext = class
  public
    Root: TglTF;
    Appender: TDataAppender;
    Maps: TObjectDictionary<TglTFDocument, TSourceMaps>;
    // Nodes to delete in Finish
    Doomed: TList<TglTFNode>;
    // May have become unused; looked at in Finish
    Meshes, Skins, Materials, Accessors: TList<Integer>;
    // Bone name -> node, exactly and ignoring case: joints of the model's
    // skins, then nodes without a mesh
    JointsExact, JointsAnyCase, NodesExact, NodesAnyCase: TDictionary<string, Integer>;
    Body: Integer;
    constructor Create(ARoot: TglTF);
    destructor Destroy; override;
    function MapsFor(ADoc: TglTFDocument): TSourceMaps;
    function IsDoomed(ANode: Integer): Boolean;
    function FindNode(const AName: string; out AIndex: Integer): Boolean;
    function SpareJoint(AUsed: TDictionary<Integer, Boolean>): Integer;
  end;

{ TDataAppender }

constructor TDataAppender.Create(ARoot: TglTF);
begin
  inherited Create;
  FRoot := ARoot;
  FBuffer := GLTF_UNDEFINED_INDEX;
end;

destructor TDataAppender.Destroy;
begin
  FPending.Free;
  inherited;
end;

function TDataAppender.AddView(const AData: TBytes; ATarget, AStride: Integer): Integer;
const
  ZEROS: array[0..3] of Byte = (0, 0, 0, 0);
var
  LView: TglTFBufferView;
  LLength: Int64;
  LPadding: Integer;
begin
  if Length(AData) = 0 then
    raise EglTFError.Create('Cannot add an empty bufferView');
  if FPending = nil then
  begin
    // The same buffer after each Flush: nothing is deleted until Finish, so
    // its index holds, and DataBuffer would add another when buffers[0] has
    // no data
    if FBuffer = GLTF_UNDEFINED_INDEX then
      FBuffer := TglTFEdit.DataBuffer(FRoot);
    FPending := TMemoryStream.Create;
    LLength := Length(FRoot.Buffers[FBuffer].Data);
    FBase := LLength + (4 - LLength mod 4) mod 4;
  end;
  LPadding := (4 - FPending.Size mod 4) mod 4;
  if LPadding > 0 then
    FPending.WriteBuffer(ZEROS[0], LPadding);

  LView := TglTFBufferView.Create;
  LView.Buffer := FBuffer;
  LView.ByteOffset := FBase + FPending.Size;
  LView.ByteLength := Length(AData);
  LView.ByteStride := AStride;
  LView.Target := ATarget;
  FRoot.BufferViews.Add(LView);
  Result := FRoot.BufferViews.Count - 1;
  FPending.WriteBuffer(AData[0], Length(AData));
end;

procedure TDataAppender.Flush;
var
  LBuffer: TglTFBuffer;
  LData: TBytes;
  LLength: Int64;
begin
  if FPending = nil then
    Exit;
  try
    if FPending.Size > 0 then
    begin
      LBuffer := FRoot.Buffers[FBuffer];
      LLength := Length(LBuffer.Data);
      SetLength(LData, FBase + FPending.Size);
      if LLength > 0 then
        Move(LBuffer.Data[0], LData[0], LLength);
      if FBase > LLength then
        FillChar(LData[LLength], FBase - LLength, 0);
      Move(FPending.Memory^, LData[FBase], FPending.Size);
      LBuffer.Data := LData;
      LBuffer.ByteLength := Length(LData);
    end;
  finally
    FreeAndNil(FPending);
  end;
end;

{ TSourceMaps }

constructor TSourceMaps.Create;
begin
  inherited Create;
  Views := TDictionary<Integer, Integer>.Create;
  Accessors := TDictionary<Integer, Integer>.Create;
  Materials := TDictionary<Integer, Integer>.Create;
  Textures := TDictionary<Integer, Integer>.Create;
  Images := TDictionary<Integer, Integer>.Create;
  Samplers := TDictionary<Integer, Integer>.Create;
  Skins := TDictionary<Integer, Integer>.Create;
end;

destructor TSourceMaps.Destroy;
begin
  Skins.Free;
  Samplers.Free;
  Images.Free;
  Textures.Free;
  Materials.Free;
  Accessors.Free;
  Views.Free;
  inherited;
end;

{ TApplyContext }

constructor TApplyContext.Create(ARoot: TglTF);
var
  LSkin: TglTFSkin;
  LJoint, I: Integer;
  LName: string;

  procedure AddName(ADictionary: TDictionary<string, Integer>; const AName: string; AIndex: Integer);
  begin
    if (AName <> '') and not ADictionary.ContainsKey(AName) then
      ADictionary.Add(AName, AIndex);
  end;

begin
  inherited Create;
  Root := ARoot;
  Appender := TDataAppender.Create(ARoot);
  Maps := TObjectDictionary<TglTFDocument, TSourceMaps>.Create([doOwnsValues]);
  Doomed := TList<TglTFNode>.Create;
  Meshes := TList<Integer>.Create;
  Skins := TList<Integer>.Create;
  Materials := TList<Integer>.Create;
  Accessors := TList<Integer>.Create;
  JointsExact := TDictionary<string, Integer>.Create;
  JointsAnyCase := TDictionary<string, Integer>.Create(TIStringComparer.Ordinal);
  NodesExact := TDictionary<string, Integer>.Create;
  NodesAnyCase := TDictionary<string, Integer>.Create(TIStringComparer.Ordinal);
  Body := GLTF_UNDEFINED_INDEX;

  for LSkin in ARoot.Skins do
    for LJoint in LSkin.Joints do
      if (LJoint >= 0) and (LJoint < ARoot.Nodes.Count) then
      begin
        LName := ARoot.Nodes[LJoint].Name;
        AddName(JointsExact, LName, LJoint);
        AddName(JointsAnyCase, LName, LJoint);
      end;
  for I := 0 to ARoot.Nodes.Count - 1 do
    if ARoot.Nodes[I].Mesh = GLTF_UNDEFINED_INDEX then
    begin
      LName := ARoot.Nodes[I].Name;
      AddName(NodesExact, LName, I);
      AddName(NodesAnyCase, LName, I);
    end;
end;

destructor TApplyContext.Destroy;
begin
  NodesAnyCase.Free;
  NodesExact.Free;
  JointsAnyCase.Free;
  JointsExact.Free;
  Accessors.Free;
  Materials.Free;
  Skins.Free;
  Meshes.Free;
  Doomed.Free;
  Maps.Free;
  Appender.Free;
  inherited;
end;

function TApplyContext.MapsFor(ADoc: TglTFDocument): TSourceMaps;
begin
  if not Maps.TryGetValue(ADoc, Result) then
  begin
    Result := TSourceMaps.Create;
    Maps.Add(ADoc, Result);
  end;
end;

function TApplyContext.IsDoomed(ANode: Integer): Boolean;
begin
  Result := (ANode >= 0) and (ANode < Root.Nodes.Count) and Doomed.Contains(Root.Nodes[ANode]);
end;

function TApplyContext.FindNode(const AName: string; out AIndex: Integer): Boolean;
begin
  Result := (AName <> '') and (JointsExact.TryGetValue(AName, AIndex) or
    JointsAnyCase.TryGetValue(AName, AIndex) or NodesExact.TryGetValue(AName, AIndex) or
    NodesAnyCase.TryGetValue(AName, AIndex));
end;

function TApplyContext.SpareJoint(AUsed: TDictionary<Integer, Boolean>): Integer;
var
  LIndex: Integer;
begin
  // A joint that has no weights still needs a node, one not used yet: the
  // model's joints first, then its nodes without a mesh
  for LIndex in JointsExact.Values do
    if not AUsed.ContainsKey(LIndex) then
      Exit(LIndex);
  for LIndex in NodesExact.Values do
    if not AUsed.ContainsKey(LIndex) then
      Exit(LIndex);
  Result := GLTF_UNDEFINED_INDEX;
end;

{ TglTFPartApplier }

constructor TglTFPartApplier.Create(ATarget: TglTFDocument);
begin
  inherited Create;
  FTarget := ATarget;
  FOriginals := TDictionary<Pointer, TArray<Cardinal>>.Create;
  FLog := TStringList.Create;
end;

destructor TglTFPartApplier.Destroy;
begin
  FLog.Free;
  FOriginals.Free;
  inherited;
end;

class function TglTFPartApplier.IsPartNode(ANode: TglTFNode): Boolean;
begin
  Result := ANode.FindExtra(GLTF_PART_EXTRA) is TJSONObject;
end;

function TglTFPartApplier.GetAbortRequested: Boolean;
begin
  Result := TInterlocked.CompareExchange(FAbortFlag, 0, 0) <> 0;
end;

procedure TglTFPartApplier.RequestAbort;
begin
  TInterlocked.Exchange(FAbortFlag, 1);
end;

procedure TglTFPartApplier.Report(const AStage: string; ADone: Double);
var
  LProgress: TglTFProgress;
begin
  if not Assigned(FOnProgress) then
    Exit;
  LProgress.ModelIndex := 1;
  LProgress.ModelCount := 1;
  LProgress.ModelName := ExtractFileName(FTarget.FileName);
  LProgress.Stage := AStage;
  LProgress.Done := ADone;
  FOnProgress(Self, LProgress);
end;

function TglTFPartApplier.ModelTriangles(APrimitive: TglTFMeshPrimitive): TArray<Cardinal>;
begin
  // The triangles from before the first change, when there was one
  if not FOriginals.TryGetValue(Pointer(APrimitive), Result) then
    Result := ReadPrimitiveTriangles(FTarget.Root, APrimitive);
end;

function TglTFPartApplier.FindBody(AContext: TObject): Integer;
var
  LContext: TApplyContext;
  LRoot: TglTF;
  LPrimitives: TArray<TPrimitiveTriangles>;
  LUsed: TArray<Boolean>;
  LNames: TArray<string>;
  LCounts: TArray<Integer>;
  LTotal, LBestBones, LBestTriangles, I: Integer;
begin
  // The skinned mesh that is not a part and is driven by the most bones
  LContext := TApplyContext(AContext);
  LRoot := LContext.Root;
  Result := GLTF_UNDEFINED_INDEX;
  LBestBones := -1;
  LBestTriangles := -1;
  for I := 0 to LRoot.Nodes.Count - 1 do
  begin
    if not HasSkinnedMesh(LRoot, I) or IsPartNode(LRoot.Nodes[I]) then
      Continue;
    try
      LUsed := nil;
      LPrimitives := AnalyzeNode(LRoot, I, ModelTriangles, LUsed);
      CountBones(LRoot, LPrimitives, LNames, LCounts, LTotal);
    except
      on E: Exception do
      begin
        FLog.Add(Format('Node %d "%s" is left as it is: %s', [I, LRoot.Nodes[I].Name, E.Message]));
        Continue;
      end;
    end;
    if (Length(LNames) > LBestBones) or
       ((Length(LNames) = LBestBones) and (LTotal > LBestTriangles)) then
    begin
      Result := I;
      LBestBones := Length(LNames);
      LBestTriangles := LTotal;
    end;
  end;
end;

procedure TglTFPartApplier.TakeOffReplaced(AContext: TObject; APart: TglTFPart;
  const AOptions: TglTFPartOptions);
var
  LContext: TApplyContext;
  LRoot: TglTF;
  LCovered: TBoneSet;
  LBone: string;
  LPrimitives: TArray<TPrimitiveTriangles>;
  LItem: TPrimitiveTriangles;
  LUsed: TArray<Boolean>;
  LTotal, LInside, LNodeBone, I: Integer;
begin
  LContext := TApplyContext(AContext);
  LRoot := LContext.Root;
  LCovered := NewBoneSet;
  try
    for LBone in APart.CoveredBones(AOptions) do
      LCovered.AddOrSetValue(LBone, True);
    if LCovered.Count = 0 then
      Exit;

    // Every other piece: taken off when the part covers most of it
    for I := 0 to LRoot.Nodes.Count - 1 do
    begin
      // Only parts replace parts: the body, hair and other meshes of the
      // model are hidden where covered instead (UpdateHidden)
      if not HasSkinnedMesh(LRoot, I) or not IsPartNode(LRoot.Nodes[I]) or LContext.IsDoomed(I) then
        Continue;
      try
        LUsed := nil;
        LPrimitives := AnalyzeNode(LRoot, I, ModelTriangles, LUsed);
      except
        Continue; // reported by FindBody
      end;
      LTotal := 0;
      LInside := 0;
      for LItem in LPrimitives do
        for LNodeBone in LItem.Bones do
        begin
          Inc(LTotal);
          if (LNodeBone <> NO_BONE) and LCovered.ContainsKey(BoneName(LRoot, LNodeBone)) then
            Inc(LInside);
        end;
      if (LTotal > 0) and (LInside / LTotal >= AOptions.ReplaceShare) then
      begin
        LContext.Doomed.Add(LRoot.Nodes[I]);
        FLog.Add(Format('%s replaces node %d "%s" (%d%% of it is on the same bones)',
          [APart.Description, I, LRoot.Nodes[I].Name, Round(100 * LInside / LTotal)]));
      end;
    end;
  finally
    LCovered.Free;
  end;
end;

type
  // Copies one part into the model. A class rather than nested routines, as
  // the anonymous methods that walk the JSON call back into it
  TPartCopier = class
  private
    FContext: TApplyContext;
    FRoot: TglTF;
    FSource: TglTF;
    FMaps: TSourceMaps;
    FPart: TglTFPart;
    FLog: TStrings;
    FSkinIndex: Integer;
    FMeshIndex: Integer;
    procedure NoteExtensions(AValue: TJSONValue);
    procedure NoteObject(AObject: TglTFProperty);
    function FindSame(ACount: Integer; const AGet: TFunc<Integer, TglTFProperty>;
      AJSON: TJSONObject): Integer;
    function CopyView(AView: Integer): Integer;
    function CopyAccessor(AAccessor: Integer): Integer;
    function CopyImage(AImage: Integer): Integer;
    function CopySampler(ASampler: Integer): Integer;
    function CopyTexture(ATexture: Integer): Integer;
    function CopyMaterial(AMaterial: Integer): Integer;
    function MapJoints(ASkin: TglTFSkin): TArray<Integer>;
    function SameMatrices(AModelAccessor, ASourceAccessor: Integer): Boolean;
    function CopySkin(ASkin: Integer): Integer;
    function CopyMesh(AMesh: Integer): Integer;
    procedure Attach(ANode: Integer);
    function AddNode: Integer;
  public
    constructor Create(AContext: TApplyContext; APart: TglTFPart; ALog: TStrings);
    function Run: Integer;
  end;

constructor TPartCopier.Create(AContext: TApplyContext; APart: TglTFPart; ALog: TStrings);
begin
  inherited Create;
  FContext := AContext;
  FRoot := AContext.Root;
  FPart := APart;
  FSource := APart.Source.Root;
  FMaps := AContext.MapsFor(APart.Source);
  FLog := ALog;
end;

function TPartCopier.Run: Integer;
var
  LSourceNode: TglTFNode;
begin
  LSourceNode := FSource.Nodes[FPart.NodeIndex];
  // The node comes last, so a part that fails leaves only unused objects,
  // which Finish deletes
  FSkinIndex := CopySkin(LSourceNode.Skin);
  FMeshIndex := CopyMesh(LSourceNode.Mesh);
  Result := AddNode;
end;

procedure TPartCopier.NoteExtensions(AValue: TJSONValue);
var
  LObject, LExtensions: TJSONObject;
  LName: string;
  I: Integer;
begin
  // Every extension a copied object uses is declared in the model, and
  // required there when the part file requires it
  if AValue is TJSONObject then
  begin
    LObject := TJSONObject(AValue);
    if LObject.GetValue('extensions') is TJSONObject then
    begin
      LExtensions := TJSONObject(LObject.GetValue('extensions'));
      for I := 0 to LExtensions.Count - 1 do
      begin
        LName := LExtensions.Pairs[I].JsonString.Value;
        TglTFEdit.AddExtensionUsed(FRoot, LName);
        if FSource.IsExtensionRequired(LName) and not FRoot.IsExtensionRequired(LName) then
          FRoot.ExtensionsRequired := FRoot.ExtensionsRequired + [LName];
      end;
    end;
    for I := 0 to LObject.Count - 1 do
      NoteExtensions(LObject.Pairs[I].JsonValue);
  end
  else if AValue is TJSONArray then
    for I := 0 to TJSONArray(AValue).Count - 1 do
      NoteExtensions(TJSONArray(AValue).Items[I]);
end;

procedure TPartCopier.NoteObject(AObject: TglTFProperty);
var
  LJSON: TJSONObject;
begin
  LJSON := AObject.SaveToJSON;
  try
    NoteExtensions(LJSON);
  finally
    LJSON.Free;
  end;
end;

function TPartCopier.FindSame(ACount: Integer; const AGet: TFunc<Integer, TglTFProperty>;
  AJSON: TJSONObject): Integer;
var
  LText: string;
  LOther: TJSONObject;
  I: Integer;
begin
  // The index of an object already in the model whose JSON is the same
  LText := AJSON.ToJSON;
  for I := 0 to ACount - 1 do
  begin
    LOther := AGet(I).SaveToJSON;
    try
      if LOther.ToJSON = LText then
        Exit(I);
    finally
      LOther.Free;
    end;
  end;
  Result := GLTF_UNDEFINED_INDEX;
end;

function TPartCopier.CopyView(AView: Integer): Integer;
var
  LView: TglTFBufferView;
  LData: TBytes;
begin
  if AView = GLTF_UNDEFINED_INDEX then
    Exit(GLTF_UNDEFINED_INDEX);
  if FMaps.Views.TryGetValue(AView, Result) then
    Exit;
  LData := ViewData(FSource, AView, LView);
  Result := FContext.Appender.AddView(Copy(LData, Integer(LView.ByteOffset),
    Integer(LView.ByteLength)), LView.Target, LView.ByteStride);
  FMaps.Views.Add(AView, Result);
end;

function TPartCopier.CopyAccessor(AAccessor: Integer): Integer;
var
  LAccessor, LNew: TglTFAccessor;
begin
  if AAccessor = GLTF_UNDEFINED_INDEX then
    Exit(GLTF_UNDEFINED_INDEX);
  if FMaps.Accessors.TryGetValue(AAccessor, Result) then
    Exit;
  if (AAccessor < 0) or (AAccessor >= FSource.Accessors.Count) then
    raise EglTFError.CreateFmt('accessor %d does not exist', [AAccessor]);
  LAccessor := FSource.Accessors[AAccessor];
  LNew := CloneProperty(LAccessor, Format('accessors[%d]', [FRoot.Accessors.Count])) as TglTFAccessor;
  try
    LNew.BufferView := CopyView(LAccessor.BufferView);
    if Assigned(LAccessor.Sparse) and Assigned(LNew.Sparse) then
    begin
      if Assigned(LAccessor.Sparse.Indices) then
        LNew.Sparse.Indices.BufferView := CopyView(LAccessor.Sparse.Indices.BufferView);
      if Assigned(LAccessor.Sparse.Values) then
        LNew.Sparse.Values.BufferView := CopyView(LAccessor.Sparse.Values.BufferView);
    end;
  except
    LNew.Free;
    raise;
  end;
  FRoot.Accessors.Add(LNew);
  Result := FRoot.Accessors.Count - 1;
  FMaps.Accessors.Add(AAccessor, Result);
  FContext.Accessors.Add(Result);
  NoteObject(LNew);
end;

function TPartCopier.CopyImage(AImage: Integer): Integer;
var
  LImage, LNew: TglTFImage;
  LJSON: TJSONObject;
  LEmbedded: Boolean;
  LMime: string;
  I: Integer;
begin
  if FMaps.Images.TryGetValue(AImage, Result) then
    Exit;
  if (AImage < 0) or (AImage >= FSource.Images.Count) then
    raise EglTFError.CreateFmt('image %d does not exist', [AImage]);
  LImage := FSource.Images[AImage];

  // The same picture already in the model, such as a shared texture atlas
  if LImage.Data <> nil then
    for I := 0 to FRoot.Images.Count - 1 do
      if SameBytes(FRoot.Images[I].Data, LImage.Data) then
      begin
        FMaps.Images.Add(AImage, I);
        Exit(I);
      end;

  LEmbedded := (LImage.BufferView <> GLTF_UNDEFINED_INDEX) or LImage.IsDataUri;
  LJSON := LImage.SaveToJSON;
  try
    LJSON.RemovePair('uri').Free;
    LJSON.RemovePair('bufferView').Free;
    if LEmbedded then
    begin
      // Inside the model too, in a bufferView of its own, as when loaded
      // from a GLB: a valid glTF image needs a uri or a bufferView
      if LImage.Data = nil then
        raise EglTFError.CreateFmt('the data of image %d is not loaded', [AImage]);
      LMime := LImage.EffectiveMimeType;
      if LMime = '' then
        raise EglTFError.CreateFmt('the type of image %d is not known', [AImage]);
      LJSON.RemovePair('mimeType').Free;
      LJSON.AddPair('mimeType', LMime);
      LJSON.AddPair('bufferView', TJSONNumber.Create(
        FContext.Appender.AddView(LImage.Data, 0, 0)));
    end
    else
      // A file: saved next to the model, under its own name
      LJSON.AddPair('uri', UriFileName(LImage.Uri));

    LNew := TglTFImage.Create;
    try
      LNew.LoadFromJSON(LJSON, Format('images[%d]', [FRoot.Images.Count]));
    except
      LNew.Free;
      raise;
    end;
  finally
    LJSON.Free;
  end;
  LNew.Data := LImage.Data;
  LNew.Embed := LEmbedded;
  LNew.Shared := LImage.Shared;
  LNew.SourceFile := LImage.SourceFile;
  if (LNew.SourceFile = '') and not LEmbedded and (LImage.Uri <> '') then
    LNew.SourceFile := FPart.Source.ResolveUri(LImage.Uri);
  FRoot.Images.Add(LNew);
  Result := FRoot.Images.Count - 1;
  FMaps.Images.Add(AImage, Result);
  NoteObject(LNew);
end;

function TPartCopier.CopySampler(ASampler: Integer): Integer;
var
  LJSON: TJSONObject;
  LNew: TglTFSampler;
begin
  if FMaps.Samplers.TryGetValue(ASampler, Result) then
    Exit;
  if (ASampler < 0) or (ASampler >= FSource.Samplers.Count) then
    raise EglTFError.CreateFmt('sampler %d does not exist', [ASampler]);
  LJSON := FSource.Samplers[ASampler].SaveToJSON;
  try
    Result := FindSame(FRoot.Samplers.Count,
      function(AIndex: Integer): TglTFProperty
      begin
        Result := FRoot.Samplers[AIndex];
      end, LJSON);
    if Result = GLTF_UNDEFINED_INDEX then
    begin
      LNew := TglTFSampler.Create;
      try
        LNew.LoadFromJSON(LJSON, Format('samplers[%d]', [FRoot.Samplers.Count]));
      except
        LNew.Free;
        raise;
      end;
      FRoot.Samplers.Add(LNew);
      Result := FRoot.Samplers.Count - 1;
      NoteObject(LNew);
    end;
  finally
    LJSON.Free;
  end;
  FMaps.Samplers.Add(ASampler, Result);
end;

function TPartCopier.CopyTexture(ATexture: Integer): Integer;
var
  LJSON: TJSONObject;
  LNew: TglTFTexture;
  LSampler: Integer;
begin
  if FMaps.Textures.TryGetValue(ATexture, Result) then
    Exit;
  if (ATexture < 0) or (ATexture >= FSource.Textures.Count) then
    raise EglTFError.CreateFmt('texture %d does not exist', [ATexture]);
  LJSON := FSource.Textures[ATexture].SaveToJSON;
  try
    // Its images, those of its extensions (EXT_texture_webp...) included
    TglTFEdit.RemapNamedRefs(LJSON, 'source',
      function(AIndex: Integer): Integer
      begin
        Result := CopyImage(AIndex);
      end);
    if LJSON.GetValue('sampler') is TJSONNumber then
    begin
      LSampler := CopySampler(TJSONNumber(LJSON.GetValue('sampler')).AsInt);
      LJSON.RemovePair('sampler').Free;
      LJSON.AddPair('sampler', TJSONNumber.Create(LSampler));
    end;
    Result := FindSame(FRoot.Textures.Count,
      function(AIndex: Integer): TglTFProperty
      begin
        Result := FRoot.Textures[AIndex];
      end, LJSON);
    if Result = GLTF_UNDEFINED_INDEX then
    begin
      LNew := TglTFTexture.Create;
      try
        LNew.LoadFromJSON(LJSON, Format('textures[%d]', [FRoot.Textures.Count]));
      except
        LNew.Free;
        raise;
      end;
      FRoot.Textures.Add(LNew);
      Result := FRoot.Textures.Count - 1;
      NoteObject(LNew);
    end;
  finally
    LJSON.Free;
  end;
  FMaps.Textures.Add(ATexture, Result);
end;

function TPartCopier.CopyMaterial(AMaterial: Integer): Integer;
var
  LJSON: TJSONObject;
  LNew: TglTFMaterial;
begin
  if AMaterial = GLTF_UNDEFINED_INDEX then
    Exit(GLTF_UNDEFINED_INDEX);
  if FMaps.Materials.TryGetValue(AMaterial, Result) then
    Exit;
  if (AMaterial < 0) or (AMaterial >= FSource.Materials.Count) then
    raise EglTFError.CreateFmt('material %d does not exist', [AMaterial]);
  LJSON := FSource.Materials[AMaterial].SaveToJSON;
  try
    // Its textures, those of its extensions included
    TglTFEdit.RemapTextureRefs(LJSON,
      function(AIndex: Integer): Integer
      begin
        Result := CopyTexture(AIndex);
      end);
    // The same material already in the model, such as one an earlier part
    // of the same outfit brought
    Result := FindSame(FRoot.Materials.Count,
      function(AIndex: Integer): TglTFProperty
      begin
        Result := FRoot.Materials[AIndex];
      end, LJSON);
    if Result = GLTF_UNDEFINED_INDEX then
    begin
      LNew := TglTFMaterial.Create;
      try
        LNew.LoadFromJSON(LJSON, Format('materials[%d]', [FRoot.Materials.Count]));
      except
        LNew.Free;
        raise;
      end;
      FRoot.Materials.Add(LNew);
      Result := FRoot.Materials.Count - 1;
      FContext.Materials.Add(Result);
      NoteObject(LNew);
    end;
  finally
    LJSON.Free;
  end;
  FMaps.Materials.Add(AMaterial, Result);
end;

function TPartCopier.MapJoints(ASkin: TglTFSkin): TArray<Integer>;
var
  LTaken: TDictionary<Integer, Boolean>;
  LMissing: TArray<string>;
  LName: string;
  LIndex, J: Integer;
begin
  // The model's node for each joint of the part's skin, matched by name
  SetLength(Result, Length(ASkin.Joints));
  LMissing := nil;
  LTaken := TDictionary<Integer, Boolean>.Create;
  try
    for J := 0 to High(ASkin.Joints) do
    begin
      LName := BoneName(FSource, ASkin.Joints[J]);
      if FContext.FindNode(LName, LIndex) then
      begin
        if LTaken.ContainsKey(LIndex) then
          raise EglTFError.CreateFmt('two of its bones match the model''s bone "%s"',
            [FRoot.Nodes[LIndex].Name]);
        LTaken.Add(LIndex, True);
        Result[J] := LIndex;
      end
      else
      begin
        Result[J] := GLTF_UNDEFINED_INDEX;
        if (J < Length(FPart.FUsedJoints)) and FPart.FUsedJoints[J] then
          LMissing := LMissing + [LName];
      end;
    end;
    if LMissing <> nil then
    begin
      if Length(LMissing) > 5 then
        LMissing := Copy(LMissing, 0, 5) + ['...'];
      raise EglTFError.CreateFmt('the model has no bone called %s',
        [string.Join(', ', LMissing)]);
    end;

    // Joints without weights still need a node each, one not used yet
    // (the joints of a skin must differ)
    for J := 0 to High(Result) do
      if Result[J] = GLTF_UNDEFINED_INDEX then
      begin
        Result[J] := FContext.SpareJoint(LTaken);
        if Result[J] = GLTF_UNDEFINED_INDEX then
          raise EglTFError.CreateFmt('the model has no node for its bone "%s"',
            [BoneName(FSource, ASkin.Joints[J])]);
        LTaken.Add(Result[J], True);
      end;
  finally
    LTaken.Free;
  end;
end;

function TPartCopier.SameMatrices(AModelAccessor, ASourceAccessor: Integer): Boolean;
var
  A, B: TArray<Double>;
  I: Integer;
begin
  if (AModelAccessor = GLTF_UNDEFINED_INDEX) or (ASourceAccessor = GLTF_UNDEFINED_INDEX) then
    Exit(AModelAccessor = ASourceAccessor);
  try
    A := ReadAccessorValues(FRoot, AModelAccessor);
    B := ReadAccessorValues(FSource, ASourceAccessor);
  except
    Exit(False);
  end;
  if Length(A) <> Length(B) then
    Exit(False);
  for I := 0 to High(A) do
    if Abs(A[I] - B[I]) > 1E-6 * Max(1, Abs(A[I])) then
      Exit(False);
  Result := True;
end;

function SameJoints(const A, B: TArray<Integer>): Boolean;
var
  I: Integer;
begin
  Result := Length(A) = Length(B);
  if Result then
    for I := 0 to High(A) do
      if A[I] <> B[I] then
        Exit(False);
end;

function TPartCopier.CopySkin(ASkin: Integer): Integer;
var
  LSkin, LNew: TglTFSkin;
  LJoints: TArray<Integer>;
  LJSON: TJSONObject;
  LArray: TJSONArray;
  LJoint, LSkeleton, I: Integer;
begin
  // The model's skin for the part: one with the same joints and matrices,
  // else a copy of the part's own, bound to the model's bones
  if FMaps.Skins.TryGetValue(ASkin, Result) then
    Exit;
  LSkin := FSource.Skins[ASkin];
  LJoints := MapJoints(LSkin);

  for I := 0 to FRoot.Skins.Count - 1 do
    if SameJoints(FRoot.Skins[I].Joints, LJoints) and
       SameMatrices(FRoot.Skins[I].InverseBindMatrices, LSkin.InverseBindMatrices) then
    begin
      FMaps.Skins.Add(ASkin, I);
      Exit(I);
    end;

  LJSON := LSkin.SaveToJSON;
  try
    LJSON.RemovePair('joints').Free;
    LJSON.RemovePair('inverseBindMatrices').Free;
    LJSON.RemovePair('skeleton').Free;
    LArray := TJSONArray.Create;
    for LJoint in LJoints do
      LArray.Add(LJoint);
    LJSON.AddPair('joints', LArray);
    LNew := TglTFSkin.Create;
    try
      LNew.LoadFromJSON(LJSON, Format('skins[%d]', [FRoot.Skins.Count]));
    except
      LNew.Free;
      raise;
    end;
  finally
    LJSON.Free;
  end;
  try
    // The part's own inverse bind matrices: the part keeps its shape
    // relative to each bone, as it would in any engine that binds it to
    // this skeleton by name
    LNew.InverseBindMatrices := CopyAccessor(LSkin.InverseBindMatrices);
    LNew.Skeleton := GLTF_UNDEFINED_INDEX;
    if (LSkin.Skeleton <> GLTF_UNDEFINED_INDEX) and
       FContext.FindNode(BoneName(FSource, LSkin.Skeleton), LSkeleton) then
      LNew.Skeleton := LSkeleton;
  except
    LNew.Free;
    raise;
  end;
  FRoot.Skins.Add(LNew);
  Result := FRoot.Skins.Count - 1;
  FMaps.Skins.Add(ASkin, Result);
  FContext.Skins.Add(Result);
  NoteObject(LNew);
end;

function TPartCopier.CopyMesh(AMesh: Integer): Integer;
var
  LMesh: TglTFMesh;
  LPrimitive: TglTFMeshPrimitive;
  LTarget: TglTFAttributeMap;
  LKey: string;
begin
  LMesh := CloneProperty(FSource.Meshes[AMesh], Format('meshes[%d]', [FRoot.Meshes.Count])) as TglTFMesh;
  try
    for LPrimitive in LMesh.Primitives do
    begin
      for LKey in LPrimitive.Attributes.Keys.ToArray do
        LPrimitive.Attributes[LKey] := CopyAccessor(LPrimitive.Attributes[LKey]);
      LPrimitive.Indices := CopyAccessor(LPrimitive.Indices);
      for LTarget in LPrimitive.Targets do
        for LKey in LTarget.Keys.ToArray do
          LTarget[LKey] := CopyAccessor(LTarget[LKey]);
      LPrimitive.Material := CopyMaterial(LPrimitive.Material);
      // Its variants refer to the part file's own list of variants
      if Assigned(LPrimitive.Extensions) and
         (LPrimitive.Extensions.GetValue('KHR_materials_variants') <> nil) then
      begin
        LPrimitive.Extensions.RemovePair('KHR_materials_variants').Free;
        FLog.Add(Format('%s: its material variants were left out', [FPart.Description]));
      end;
    end;
  except
    LMesh.Free;
    raise;
  end;
  FRoot.Meshes.Add(LMesh);
  Result := FRoot.Meshes.Count - 1;
  FContext.Meshes.Add(Result);
  NoteObject(LMesh);
end;

procedure TPartCopier.Attach(ANode: Integer);
var
  LScene: TglTFScene;
  LPlaced: Boolean;
  LChild, LSceneIndex, I: Integer;
begin
  // Next to the body: in the body's parent, or among the root nodes of the
  // scenes the body is in; else in the default scene
  LPlaced := False;
  if FContext.Body <> GLTF_UNDEFINED_INDEX then
  begin
    for I := 0 to FRoot.Nodes.Count - 1 do
      for LChild in FRoot.Nodes[I].Children do
        if LChild = FContext.Body then
        begin
          FRoot.Nodes[I].Children := FRoot.Nodes[I].Children + [ANode];
          Exit;
        end;
    for LScene in FRoot.Scenes do
      for LChild in LScene.Nodes do
        if LChild = FContext.Body then
        begin
          LScene.Nodes := LScene.Nodes + [ANode];
          LPlaced := True;
          Break;
        end;
  end;
  if LPlaced then
    Exit;
  if FRoot.Scenes.Count = 0 then
  begin
    FRoot.Scenes.Add(TglTFScene.Create);
    FRoot.Scene := 0;
  end;
  LSceneIndex := FRoot.Scene;
  if (LSceneIndex < 0) or (LSceneIndex >= FRoot.Scenes.Count) then
    LSceneIndex := 0;
  FRoot.Scenes[LSceneIndex].Nodes := FRoot.Scenes[LSceneIndex].Nodes + [ANode];
end;

function TPartCopier.AddNode: Integer;
const
  DROPPED: array[0..7] of string = ('children', 'camera', 'mesh', 'skin', 'matrix',
    'translation', 'rotation', 'scale');
var
  LJSON, LMark: TJSONObject;
  LExtras: TJSONValue;
  LNode: TglTFNode;
  LName: string;
begin
  // The part's node without its place in the part file: a skinned mesh
  // ignores its node's transform, and its children are not part of it
  LJSON := FSource.Nodes[FPart.NodeIndex].SaveToJSON;
  try
    for LName in DROPPED do
      LJSON.RemovePair(LName).Free;
    LJSON.AddPair('mesh', TJSONNumber.Create(FMeshIndex));
    LJSON.AddPair('skin', TJSONNumber.Create(FSkinIndex));
    if LJSON.GetValue('name') = nil then
      LJSON.AddPair('name', FPart.Name);

    LMark := TJSONObject.Create;
    LMark.AddPair('file', ExtractFileName(FPart.FileName));
    LMark.AddPair('part', FPart.Name);
    LExtras := LJSON.GetValue('extras');
    if LExtras is TJSONObject then
    begin
      TJSONObject(LExtras).RemovePair(GLTF_PART_EXTRA).Free;
      TJSONObject(LExtras).AddPair(GLTF_PART_EXTRA, LMark);
    end
    else
    begin
      LJSON.RemovePair('extras').Free;
      LJSON.AddPair('extras', TJSONObject.Create.AddPair(GLTF_PART_EXTRA, LMark));
    end;

    LNode := TglTFNode.Create;
    try
      LNode.LoadFromJSON(LJSON, Format('nodes[%d]', [FRoot.Nodes.Count]));
    except
      LNode.Free;
      raise;
    end;
  finally
    LJSON.Free;
  end;
  FRoot.Nodes.Add(LNode);
  Result := FRoot.Nodes.Count - 1;
  NoteObject(LNode);
  Attach(Result);
end;

function TglTFPartApplier.AddPart(AContext: TObject; APart: TglTFPart): Integer;
var
  LCopier: TPartCopier;
begin
  LCopier := TPartCopier.Create(TApplyContext(AContext), APart, FLog);
  try
    try
      Result := LCopier.Run;
    finally
      // Into the buffer now, also after a failure: what is added next, and
      // the next parts, read what this one brought
      TApplyContext(AContext).Appender.Flush;
    end;
  finally
    LCopier.Free;
  end;
end;

procedure TglTFPartApplier.UpdateHidden(AContext: TObject; const AOptions: TglTFPartOptions);
var
  LContext: TApplyContext;
  LRoot: TglTF;
  LWorld: TArray<TMat4>;
  LGrid: TTriangleGrid;
  LNode: TglTFNode;
  LSkin: TglTFSkin;
  LPrimitive: TglTFMeshPrimitive;
  LVertices: TSkinnedVertices;
  LCovered: TArray<Boolean>;
  LOriginal, LKept, LCurrent: TArray<Cardinal>;
  LGap: Double;
  LTotal, LHidden, LCount, T, V, I: Integer;

  // The height of a skinned mesh node at rest: its extent along Y, which
  // glTF makes up
  function Extent(ANode: Integer): Double;
  var
    LPrim: TglTFMeshPrimitive;
    LSkinned: TSkinnedVertices;
    LLow, LHigh: Double;
    LFirst: Boolean;
    K: Integer;
  begin
    Result := 0;
    LLow := 0;
    LHigh := 0;
    LFirst := True;
    for LPrim in LRoot.Meshes[LRoot.Nodes[ANode].Mesh].Primitives do
    begin
      if not IsTriangleMode(LPrim.Mode) or not LPrim.HasAttribute('POSITION') then
        Continue;
      LSkinned := SkinVertices(LRoot, LRoot.Skins[LRoot.Nodes[ANode].Skin], LPrim, LWorld, nil,
        AOptions);
      for K := 0 to High(LSkinned.Positions) do
      begin
        if LFirst then
        begin
          LLow := LSkinned.Positions[K].Y;
          LHigh := LLow;
          LFirst := False;
        end;
        LLow := Min(LLow, LSkinned.Positions[K].Y);
        LHigh := Max(LHigh, LSkinned.Positions[K].Y);
      end;
    end;
    Result := LHigh - LLow;
  end;

  // A new index accessor for a list of triangles
  function NewIndices(const ATriangles: TArray<Cardinal>): Integer;
  var
    LAccessor: TglTFAccessor;
    LData: TBytes;
    LMax, LIndex: Cardinal;
    LWord: Word;
    K: Integer;
  begin
    LMax := 0;
    for LIndex in ATriangles do
      if LIndex > LMax then
        LMax := LIndex;
    LAccessor := TglTFAccessor.Create;
    try
      // The largest value of a type is not allowed: it restarts primitives
      if LMax < $FFFF then
      begin
        SetLength(LData, Length(ATriangles) * 2);
        for K := 0 to High(ATriangles) do
        begin
          LWord := ATriangles[K];
          Move(LWord, LData[K * 2], 2);
        end;
        LAccessor.ComponentType := GLTF_COMPONENT_UNSIGNED_SHORT;
      end
      else
      begin
        SetLength(LData, Length(ATriangles) * 4);
        Move(ATriangles[0], LData[0], Length(LData));
        LAccessor.ComponentType := GLTF_COMPONENT_UNSIGNED_INT;
      end;
      LAccessor.Count := Length(ATriangles);
      LAccessor.&Type := 'SCALAR';
      LAccessor.BufferView := LContext.Appender.AddView(LData, GLTF_TARGET_ELEMENT_ARRAY_BUFFER, 0);
    except
      LAccessor.Free;
      raise;
    end;
    LRoot.Accessors.Add(LAccessor);
    Result := LRoot.Accessors.Count - 1;
  end;

begin
  LContext := TApplyContext(AContext);
  LRoot := LContext.Root;
  LWorld := NodeWorldMatrices(LRoot);
  if LContext.Body = GLTF_UNDEFINED_INDEX then
    LContext.Body := FindBody(LContext);

  // How close a part must be to the skin to hide it: a share of the body's
  // height, so that it suits models in metres and in centimetres alike
  LGap := 0;
  if LContext.Body <> GLTF_UNDEFINED_INDEX then
    try
      LGap := AOptions.CoverGap * Extent(LContext.Body);
    except
      LGap := 0; // FindBody reported why the body cannot be read
    end;

  LGrid := TTriangleGrid.Create;
  try
    // 1. The surfaces of the parts on the model, at rest on the model's
    //    skeleton
    for I := 0 to LRoot.Nodes.Count - 1 do
      if HasSkinnedMesh(LRoot, I) and IsPartNode(LRoot.Nodes[I]) and not LContext.IsDoomed(I) then
        try
          LNode := LRoot.Nodes[I];
          for LPrimitive in LRoot.Meshes[LNode.Mesh].Primitives do
          begin
            if not IsTriangleMode(LPrimitive.Mode) then
              Continue;
            LOriginal := ReadPrimitiveTriangles(LRoot, LPrimitive);
            LVertices := SkinVertices(LRoot, LRoot.Skins[LNode.Skin], LPrimitive, LWorld,
              LOriginal, AOptions);
            for T := 0 to (Length(LOriginal) div 3) - 1 do
              LGrid.AddTriangle(LVertices.Positions[LOriginal[T * 3]],
                LVertices.Positions[LOriginal[T * 3 + 1]], LVertices.Positions[LOriginal[T * 3 + 2]]);
          end;
        except
          on E: Exception do
            FLog.Add(Format('Part node %d "%s" hides nothing: %s', [I, LRoot.Nodes[I].Name,
              E.Message]));
        end;
    LGrid.Build;

    // 2. The other skinned meshes, the body among them. A vertex is covered
    //    when a part's surface crosses the line along its normal within the
    //    gap: just outside the skin, or just inside where the body pokes
    //    through the cloth. A triangle is hidden when its three corners are
    //    covered, so the skin stays right up to a sleeve or a hem. Triangles
    //    start from those the mesh had before the first change
    for I := 0 to LRoot.Nodes.Count - 1 do
    begin
      if not HasSkinnedMesh(LRoot, I) or IsPartNode(LRoot.Nodes[I]) or LContext.IsDoomed(I) then
        Continue;
      LNode := LRoot.Nodes[I];
      LSkin := LRoot.Skins[LNode.Skin];
      LTotal := 0;
      LHidden := 0;
      try
        for LPrimitive in LRoot.Meshes[LNode.Mesh].Primitives do
        begin
          if not IsTriangleMode(LPrimitive.Mode) then
            Continue;
          LOriginal := ModelTriangles(LPrimitive);
          if Length(LOriginal) = 0 then
            Continue;
          SetLength(LCovered, 0);
          if (LGrid.Count > 0) and (LGap > 0) then
          begin
            LVertices := SkinVertices(LRoot, LSkin, LPrimitive, LWorld, LOriginal, AOptions);
            SetLength(LCovered, Length(LVertices.Positions));
            for V := 0 to High(LCovered) do
              LCovered[V] := not LVertices.Kept[V] and
                LGrid.HitsLine(LVertices.Positions[V], LVertices.Normals[V], LGap);
          end;

          SetLength(LKept, Length(LOriginal));
          LCount := 0;
          for T := 0 to (Length(LOriginal) div 3) - 1 do
            if (LCovered = nil) or not (LCovered[LOriginal[T * 3]] and
               LCovered[LOriginal[T * 3 + 1]] and LCovered[LOriginal[T * 3 + 2]]) then
            begin
              LKept[LCount * 3] := LOriginal[T * 3];
              LKept[LCount * 3 + 1] := LOriginal[T * 3 + 1];
              LKept[LCount * 3 + 2] := LOriginal[T * 3 + 2];
              Inc(LCount);
            end;
          SetLength(LKept, LCount * 3);
          Inc(LTotal, Length(LOriginal) div 3);
          Inc(LHidden, Length(LOriginal) div 3 - LCount);
          // A primitive needs at least one triangle: an empty one stays,
          // drawing nothing, so that its triangles can come back
          if LCount = 0 then
            LKept := [LOriginal[0], LOriginal[0], LOriginal[0]];

          LCurrent := ReadPrimitiveTriangles(LRoot, LPrimitive);
          if SameTriangles(LKept, LCurrent) then
            Continue;
          if not FOriginals.ContainsKey(Pointer(LPrimitive)) then
            FOriginals.Add(Pointer(LPrimitive), LOriginal);
          if LPrimitive.Indices <> GLTF_UNDEFINED_INDEX then
            LContext.Accessors.Add(LPrimitive.Indices);
          LPrimitive.Indices := NewIndices(LKept);
          LPrimitive.Mode := GLTF_MODE_TRIANGLES;
        end;
      except
        on E: Exception do
          FLog.Add(Format('Node %d "%s" is left as it is: %s', [I, LNode.Name, E.Message]));
      end;
      // Into the buffer now: a mesh that another node shares is read again
      LContext.Appender.Flush;
      if LHidden > 0 then
        FLog.Add(Format('Node %d "%s": %d of %d triangles hidden under parts', [I, LNode.Name,
          LHidden, LTotal]));
    end;
  finally
    LGrid.Free;
  end;
end;

procedure TglTFPartApplier.Finish(AContext: TObject);
var
  LContext: TApplyContext;
  LRoot: TglTF;
  LNodes, LMeshes, LSkins: TArray<Integer>;
  LPrimitives: TDictionary<Pointer, Boolean>;
  LMesh: TglTFMesh;
  LPrimitive: TglTFMeshPrimitive;
  LKey: Pointer;
  I: Integer;
begin
  LContext := TApplyContext(AContext);
  LRoot := LContext.Root;

  // 1. The new data into the buffer, before anything is cut out of it
  LContext.Appender.Flush;

  // 2. The pieces taken off, then what only they used
  LNodes := nil;
  LMeshes := LContext.Meshes.ToArray;
  LSkins := LContext.Skins.ToArray;
  for I := 0 to LRoot.Nodes.Count - 1 do
    if LContext.Doomed.Contains(LRoot.Nodes[I]) then
    begin
      LNodes := LNodes + [I];
      LMeshes := LMeshes + [LRoot.Nodes[I].Mesh];
      LSkins := LSkins + [LRoot.Nodes[I].Skin];
    end;
  TglTFEdit.DeleteNodes(LRoot, LNodes, FLog);
  TglTFEdit.DeleteUnusedObjects(LRoot, LMeshes, LSkins, LContext.Materials.ToArray,
    LContext.Accessors.ToArray, FLog);

  // 3. Forget the triangles of primitives that are gone: their addresses
  //    may be reused by new ones
  LPrimitives := TDictionary<Pointer, Boolean>.Create;
  try
    for LMesh in LRoot.Meshes do
      for LPrimitive in LMesh.Primitives do
        LPrimitives.AddOrSetValue(Pointer(LPrimitive), True);
    for LKey in FOriginals.Keys.ToArray do
      if not LPrimitives.ContainsKey(LKey) then
        FOriginals.Remove(LKey);
  finally
    LPrimitives.Free;
  end;
end;

function TglTFPartApplier.Apply(const AParts: TArray<TglTFPart>;
  const AOptions: TglTFPartOptions): Integer;
var
  LContext: TApplyContext;
  LPart: TglTFPart;
  I: Integer;
begin
  Result := 0;
  FLog.Clear;
  TInterlocked.Exchange(FAbortFlag, 0);
  LContext := TApplyContext.Create(FTarget.Root);
  try
    Report('Looking at the model', 0);
    LContext.Body := FindBody(LContext);
    if LContext.Body <> GLTF_UNDEFINED_INDEX then
      FLog.Add(Format('The body is node %d "%s"', [LContext.Body,
        FTarget.Root.Nodes[LContext.Body].Name]))
    else
      FLog.Add('The model has no skinned mesh that is not a part: nothing to hide');

    for I := 0 to High(AParts) do
    begin
      if AbortRequested then
      begin
        FLog.Add(Format('Aborted: %d part(s) not put on', [Length(AParts) - I]));
        Break;
      end;
      LPart := AParts[I];
      Report(Format('Putting on %s (%d of %d)', [LPart.Description, I + 1, Length(AParts)]),
        0.1 + 0.7 * I / Length(AParts));
      if LPart.Error <> '' then
      begin
        FLog.Add(Format('%s: not put on: %s', [LPart.Description, LPart.Error]));
        Continue;
      end;
      try
        TakeOffReplaced(LContext, LPart, AOptions);
        AddPart(LContext, LPart);
        FLog.Add(Format('%s: put on, covering %s', [LPart.Description,
          LPart.CoveredText(AOptions)]));
        Inc(Result);
      except
        on E: Exception do
          FLog.Add(Format('%s: not put on: %s', [LPart.Description, E.Message]));
      end;
    end;

    // Always, also after an abort: the model is left consistent
    Report('Hiding what the parts cover', 0.8);
    UpdateHidden(LContext, AOptions);
    Report('Removing unused data', 0.9);
    Finish(LContext);
    Report('Done', 1);
  finally
    LContext.Free;
  end;
end;

function TglTFPartApplier.Remove(const ANodes: TArray<Integer>;
  const AOptions: TglTFPartOptions): Integer;
var
  LContext: TApplyContext;
  LIndex: Integer;
begin
  Result := 0;
  FLog.Clear;
  LContext := TApplyContext.Create(FTarget.Root);
  try
    for LIndex in ANodes do
      if (LIndex >= 0) and (LIndex < FTarget.Root.Nodes.Count) and
         IsPartNode(FTarget.Root.Nodes[LIndex]) and not LContext.IsDoomed(LIndex) then
      begin
        LContext.Doomed.Add(FTarget.Root.Nodes[LIndex]);
        FLog.Add(Format('Node %d "%s" taken off', [LIndex, FTarget.Root.Nodes[LIndex].Name]));
        Inc(Result);
      end;
    UpdateHidden(LContext, AOptions);
    Finish(LContext);
  finally
    LContext.Free;
  end;
end;

procedure TglTFPartApplier.Refresh(const AOptions: TglTFPartOptions);
var
  LContext: TApplyContext;
begin
  FLog.Clear;
  LContext := TApplyContext.Create(FTarget.Root);
  try
    UpdateHidden(LContext, AOptions);
    Finish(LContext);
  finally
    LContext.Free;
  end;
end;

function TglTFPartApplier.AppliedParts(const AOptions: TglTFPartOptions): TArray<TglTFAppliedPart>;
var
  LRoot: TglTF;
  LNode: TglTFNode;
  LItem: TglTFAppliedPart;
  LPrimitives: TArray<TPrimitiveTriangles>;
  LUsed: TArray<Boolean>;
  LNames: TArray<string>;
  LCounts: TArray<Integer>;
  LMark: TJSONValue;
  I: Integer;
begin
  Result := nil;
  LRoot := FTarget.Root;
  for I := 0 to LRoot.Nodes.Count - 1 do
  begin
    LNode := LRoot.Nodes[I];
    if not IsPartNode(LNode) then
      Continue;
    LItem.NodeIndex := I;
    LItem.Name := LNode.Name;
    LItem.FileName := '';
    LMark := LNode.FindExtra(GLTF_PART_EXTRA + '.part');
    if LMark is TJSONString then
      LItem.Name := TJSONString(LMark).Value;
    LMark := LNode.FindExtra(GLTF_PART_EXTRA + '.file');
    if LMark is TJSONString then
      LItem.FileName := TJSONString(LMark).Value;
    LItem.TriangleCount := 0;
    LItem.CoveredText := '?';
    try
      LUsed := nil;
      LPrimitives := AnalyzeNode(LRoot, I, nil, LUsed);
      CountBones(LRoot, LPrimitives, LNames, LCounts, LItem.TriangleCount);
      LItem.CoveredText := CoveredTextOf(LNames, LCounts, LItem.TriangleCount, AOptions, 4);
    except
      on E: Exception do
        LItem.CoveredText := E.Message;
    end;
    Result := Result + [LItem];
  end;
end;

end.
