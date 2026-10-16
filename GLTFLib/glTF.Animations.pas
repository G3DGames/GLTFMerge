//** @abstract(Imports animations from other .gltf or .glb files into a loaded model.)
//**
//** Animation files are often exported separately from the model they animate, one or
//** several animations per file, sometimes with a copy of the model. Only the animations
//** are taken: each with the samplers it uses, their accessors and bufferViews, and the
//** bytes of those, which are appended to the model's buffer. Meshes, materials, images
//** and the rest of the source file are ignored.
//**
//** An animation targets nodes by index, and the indices of the source file mean nothing
//** in the model. So each channel's node is matched to a node of the model by name,
//** exactly first and then ignoring case. An unnamed node matches the node with the same
//** index, but only when both files have the same number of nodes. A channel whose node
//** cannot be matched is skipped; an animation with no channel left is not imported.
//**
//** The import works one animation at a time: each file is loaded, then each of its
//** animations is matched, checked for a duplicate name and added to the model straight
//** away. A duplicate is settled through @link(TglTFAnimationImporter.OnDuplicate). An
//** abort, requested with @link(TglTFAnimationImporter.RequestAbort) or answered to a
//** duplicate, stops the import after the animation being added; everything added so far
//** stays and the model is always valid.
//**
//** @preformatted(
//** for each file:       load  -> match its nodes
//**   for each animation: duplicate? -> OnDuplicate -> add to the model
//** at the end:          remove the data of replaced animations
//** )
//**
//** Progress is reported through @link(TglTFAnimationImporter.OnProgress), so the import
//** can run in a background thread with a progress bar. Use an importer from one thread at a
//** time; only RequestAbort and AbortRequested may be used from another.
unit glTF.Animations;

{
  Imports animations from other .gltf or .glb files into a loaded model.

  Animation files are often exported separately from the model they animate,
  one or several animations per file, sometimes with a copy of the model. Only
  the animations are taken: each with the samplers it uses, their accessors
  and bufferViews, and the bytes of those, which are appended to the model's
  buffer. Meshes, materials, images and the rest of the source file are
  ignored.

  An animation targets nodes by index, and the indices of the source file mean
  nothing in the model. So each channel's node is matched to a node of the
  model by name, exactly first and then ignoring case. An unnamed node matches
  the node with the same index, but only when both files have the same number
  of nodes. A channel whose node cannot be matched is skipped; an animation
  with no channel left is not imported.

  The import works one animation at a time: each file is loaded, then each of
  its animations is matched, checked for a duplicate name and added to the
  model straight away. A duplicate is settled through
  TglTFAnimationImporter.OnDuplicate. An abort, requested with
  TglTFAnimationImporter.RequestAbort or answered to a duplicate, stops the
  import after the animation being added; everything added so far stays and
  the model is always valid.

    for each file:       load  -> match its nodes
      for each animation: duplicate? -> OnDuplicate -> add to the model
    at the end:          remove the data of replaced animations

  Progress is reported through TglTFAnimationImporter.OnProgress, so the
  import can run in a background thread with a progress bar. Use an importer
  from one thread at a time; only RequestAbort and AbortRequested may be used
  from another.
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,

  glTF.Base,
  glTF.Classes,
  glTF.Document;

type
  //** @abstract(What to do with an imported animation whose name is already used.)
  /// <summary>What to do with an imported animation whose name is already used.</summary>
  TglTFDuplicateAction = (
    //** @abstract(The imported animation replaces the one with the same name, taking its
    //** place in the list; the data only the old one used is removed at the end of the
    //** import.)
    /// <summary>The imported animation replaces the one with the same name, taking its place
    /// in the list; the data only the old one used is removed at the end of the
    /// import.</summary>
    daReplace,

    //** @abstract(The animation already there is kept and the imported one is ignored.)
    /// <summary>The animation already there is kept and the imported one is ignored.</summary>
    daKeep,

    //** @abstract(The imported animation is added under a new, unique name.)
    /// <summary>The imported animation is added under a new, unique name.</summary>
    daRename,

    //** @abstract(The imported animation is ignored and the import stops; what was added so
    //** far stays.)
    /// <summary>The imported animation is ignored and the import stops; what was added so far
    /// stays.</summary>
    daAbort);

  //** @abstract(One animation found in a file being imported, and what happened to it.)
  //**
  //** Created and owned by @link(TglTFAnimationImporter); read-only for its users.
  /// <summary>One animation found in a file being imported, and what happened to
  /// it.</summary>
  /// <remarks>Created and owned by <see cref="TglTFAnimationImporter"/>; read-only for its
  /// users.</remarks>
  TglTFAnimationCandidate = class
  private
    FSourceFile: TObject;
    FSource: TglTFDocument;
    FFileName: string;
    FSourceIndex: Integer;
    FOriginalName: string;
    FName: string;
    FWillImport: Boolean;
    FImported: Boolean;
    FReplaced: Integer;
    FTargets: TArray<Integer>;
    FMatchedChannels: Integer;
    FError: string;
    FNotes: TStringList;
    function GetChannelCount: Integer;
  public
    //** @abstract(Creates an empty candidate.)
    /// <summary>Creates an empty candidate.</summary>
    constructor Create;

    //** @abstract(Frees the candidate.)
    /// <summary>Frees the candidate.</summary>
    destructor Destroy; override;

    //** @abstract(Returns a short description for messages.)
    //**
    //** @returns(For example: "Walk" from run.glb.)
    /// <summary>Returns a short description for messages.</summary>
    /// <returns>For example: "Walk" from run.glb.</returns>
    function Description: string;

    //** @abstract(The document the animation is in; owned by the importer.)
    /// <summary>The document the animation is in; owned by the importer.</summary>
    property Source: TglTFDocument read FSource;

    //** @abstract(The file the animation is in.)
    /// <summary>The file the animation is in.</summary>
    property FileName: string read FFileName;

    //** @abstract(Index of the animation in @code(Source.Root.Animations).)
    /// <summary>Index of the animation in <c>Source.Root.Animations</c>.</summary>
    property SourceIndex: Integer read FSourceIndex;

    //** @abstract(The animation's name in its file; empty when it has none.)
    /// <summary>The animation's name in its file; empty when it has none.</summary>
    property OriginalName: string read FOriginalName;

    //** @abstract(The name it has, or would have, in the model.)
    //**
    //** The original name, or for an unnamed animation the file name without its extension,
    //** followed by "_" and the animation's number when the file has several. Changed by a
    //** rename.
    /// <summary>The name it has, or would have, in the model.</summary>
    /// <remarks>The original name, or for an unnamed animation the file name without its
    /// extension, followed by "_" and the animation's number when the file has several.
    /// Changed by a rename.</remarks>
    property Name: string read FName;

    //** @abstract(Whether it can be imported: some channel matched and its data is there.)
    /// <summary>Whether it can be imported: some channel matched and its data is
    /// there.</summary>
    property WillImport: Boolean read FWillImport;

    //** @abstract(Whether it was added to the model.)
    /// <summary>Whether it was added to the model.</summary>
    property Imported: Boolean read FImported;

    //** @abstract(Index of the model's animation it replaced; GLTF_UNDEFINED_INDEX when it
    //** replaced none.)
    /// <summary>Index of the model's animation it replaced; GLTF_UNDEFINED_INDEX when it
    /// replaced none.</summary>
    property Replaced: Integer read FReplaced;

    //** @abstract(Number of channels the animation has in its file.)
    /// <summary>Number of channels the animation has in its file.</summary>
    property ChannelCount: Integer read GetChannelCount;

    //** @abstract(Number of channels whose node was matched in the model; only these are
    //** imported.)
    /// <summary>Number of channels whose node was matched in the model; only these are
    /// imported.</summary>
    property MatchedChannels: Integer read FMatchedChannels;

    //** @abstract(Why the animation cannot be imported; empty when it can.)
    /// <summary>Why the animation cannot be imported; empty when it can.</summary>
    property Error: string read FError;

    //** @abstract(One line per channel skipped, saying why.)
    /// <summary>One line per channel skipped, saying why.</summary>
    property Notes: TStringList read FNotes;
  end;

  TglTFAnimationImporter = class;

  //** @abstract(Asks what to do with an animation whose name the model already uses.)
  //**
  //** Called on the importing thread, which waits for the answer. A handler that asks the
  //** user from a background import must show the question on the main thread and wait for
  //** it, for example with a TEvent; it must not be called on the main thread itself then.
  //** Reading the model, for example through NameProblem, is safe while the importer waits.
  //**
  //** @param(AImporter The importer.)
  //**
  //** @param(ACandidate The animation being imported.)
  //**
  //** @param(AExisting Index of the model's animation with the same name.)
  //**
  //** @param(AAction The answer; daKeep when unchanged.)
  //**
  //** @param(ANewName For daRename: the new name; it holds a suggested unique name on entry.
  //** A name that cannot be used is replaced by the suggestion.)
  /// <summary>Asks what to do with an animation whose name the model already uses.</summary>
  /// <param name="AImporter">The importer.</param>
  /// <param name="ACandidate">The animation being imported.</param>
  /// <param name="AExisting">Index of the model's animation with the same name.</param>
  /// <param name="AAction">The answer; daKeep when unchanged.</param>
  /// <param name="ANewName">For daRename: the new name; it holds a suggested unique name on
  /// entry. A name that cannot be used is replaced by the suggestion.</param>
  /// <remarks>Called on the importing thread, which waits for the answer. A handler that asks
  /// the user from a background import must show the question on the main thread and wait for
  /// it, for example with a TEvent; it must not be called on the main thread itself then.
  /// Reading the model, for example through NameProblem, is safe while the importer
  /// waits.</remarks>
  TglTFDuplicateEvent = reference to procedure(AImporter: TglTFAnimationImporter;
    ACandidate: TglTFAnimationCandidate; AExisting: Integer;
    var AAction: TglTFDuplicateAction; var ANewName: string);

  //** @abstract(Imports the animations of other glTF files into a document, one animation at
  //** a time.)
  //**
  //** Set OnDuplicate, and OnProgress if wanted, then call ImportFiles. Duplicates are
  //** found by name, ignoring case, among the model's animations, including those added
  //** earlier in the same import. Without an OnDuplicate handler, duplicates keep the old
  //** animation. The importer owns the documents it loads; free it after the import.
  //**
  //** @longCode(#
  //** Importer := TglTFAnimationImporter.Create(Doc);
  //** try
  //**   Importer.OnDuplicate :=
  //**     procedure(AImporter: TglTFAnimationImporter; ACandidate: TglTFAnimationCandidate;
  //**       AExisting: Integer; var AAction: TglTFDuplicateAction; var ANewName: string)
  //**     begin
  //**       AAction := daRename; // keep both, under the suggested name
  //**     end;
  //**   Importer.ImportFiles(['walk.glb', 'run.glb']);
  //** finally
  //**   Importer.Free;
  //** end;
  //** #)
  /// <summary>Imports the animations of other glTF files into a document, one animation at a
  /// time.</summary>
  /// <remarks>Set OnDuplicate, and OnProgress if wanted, then call ImportFiles. Duplicates are
  /// found by name, ignoring case, among the model's animations, including those added
  /// earlier in the same import. Without an OnDuplicate handler, duplicates keep the old
  /// animation. The importer owns the documents it loads; free it after the
  /// import.</remarks>
  /// <example><code>
  /// Importer := TglTFAnimationImporter.Create(Doc);
  /// try
  ///   Importer.OnDuplicate :=
  ///     procedure(AImporter: TglTFAnimationImporter; ACandidate: TglTFAnimationCandidate;
  ///       AExisting: Integer; var AAction: TglTFDuplicateAction; var ANewName: string)
  ///     begin
  ///       AAction := daRename; // keep both, under the suggested name
  ///     end;
  ///   Importer.ImportFiles(['walk.glb', 'run.glb']);
  /// finally
  ///   Importer.Free;
  /// end;
  /// </code></example>
  TglTFAnimationImporter = class
  private
    FTarget: TglTFDocument;
    FSources: TObjectList<TObject>;
    FCandidates: TObjectList<TglTFAnimationCandidate>;
    FLog: TStringList;
    FOnProgress: TglTFProgressEvent;
    FOnDuplicate: TglTFDuplicateEvent;
    // 0 or 1; set and read with TInterlocked, as RequestAbort is called from
    // another thread
    FAbortFlag: Integer;
    FModelIndex: Integer;
    FModelCount: Integer;
    FLoadingName: string;
    FBuffer: Integer;
    FPending: TMemoryStream;
    FPendingBase: Int64;
    FOldAccessors: TArray<Integer>;
    FImportedCount: Integer;
    function GetCount: Integer;
    function GetAbortRequested: Boolean;
    function GetCandidate(AIndex: Integer): TglTFAnimationCandidate;
    procedure Report(const AStage: string; ADone: Double);
    procedure SourceProgress(Sender: TObject; const AProgress: TglTFProgress);
    function MatchNodes(ASource: TglTFDocument; const AFileName: string): TArray<Integer>;
    procedure Analyze(ACandidate: TglTFAnimationCandidate);
    function FindDuplicate(const AName: string): Integer;
    function ImportSource(ASource: TglTFDocument; const AFileName: string): Integer;
    function ImportCandidate(ACandidate: TglTFAnimationCandidate): Boolean;
    function CopyAnimation(ACandidate: TglTFAnimationCandidate;
      var ABuffer: Integer): TglTFAnimation;
    function AppendPending(const AData: TBytes): Int64;
    procedure FlushPending;
    procedure RemoveReplacedData;
  public
    //** @abstract(Creates an importer for a document.)
    //**
    //** @param(ATarget The document that receives the animations; not owned. Nothing else
    //** may change it during the import.)
    /// <summary>Creates an importer for a document.</summary>
    /// <param name="ATarget">The document that receives the animations; not owned. Nothing
    /// else may change it during the import.</param>
    constructor Create(ATarget: TglTFDocument);

    //** @abstract(Frees the importer, the documents it loaded and its candidates.)
    /// <summary>Frees the importer, the documents it loaded and its candidates.</summary>
    destructor Destroy; override;

    //** @abstract(Imports the animations of several .gltf or .glb files.)
    //**
    //** Each file is loaded and its animations matched and added in turn; see the unit
    //** description. A file that cannot be loaded, or has no animations, adds a line to
    //** @link(Log) and the import goes on. Stops early on an abort. At the end, the data
    //** only replaced animations used is removed from the model.
    //**
    //** @param(AFileNames The files, in the order their animations are to be added.)
    //**
    //** @returns(The number of animations added or replaced.)
    /// <summary>Imports the animations of several .gltf or .glb files.</summary>
    /// <param name="AFileNames">The files, in the order their animations are to be
    /// added.</param>
    /// <returns>The number of animations added or replaced.</returns>
    /// <remarks>Each file is loaded and its animations matched and added in turn; see the
    /// unit description. A file that cannot be loaded, or has no animations, adds a line to
    /// <see cref="Log"/> and the import goes on. Stops early on an abort. At the end, the data
    /// only replaced animations used is removed from the model.</remarks>
    function ImportFiles(const AFileNames: TArray<string>): Integer;

    //** @abstract(Imports the animations of an already loaded document.)
    //**
    //** Like ImportFiles for one file, including the removal of replaced data at the end.
    //**
    //** @param(ASource The document; the importer owns it from now on, even when this raises.)
    //**
    //** @param(AFileName The name to show and to derive names of unnamed animations from;
    //** may be empty.)
    //**
    //** @returns(The number of animations added or replaced.)
    /// <summary>Imports the animations of an already loaded document.</summary>
    /// <param name="ASource">The document; the importer owns it from now on, even when this
    /// raises.</param>
    /// <param name="AFileName">The name to show and to derive names of unnamed animations
    /// from; may be empty.</param>
    /// <returns>The number of animations added or replaced.</returns>
    /// <remarks>Like ImportFiles for one file, including the removal of replaced data at the
    /// end.</remarks>
    function ImportDocument(ASource: TglTFDocument; const AFileName: string): Integer;

    //** @abstract(Asks the import to stop once the animation being added is finished.)
    //**
    //** May be called from any thread, typically the main thread while the import runs in a
    //** background thread. The remaining animations and files are not imported; those
    //** already added stay.
    /// <summary>Asks the import to stop once the animation being added is finished.</summary>
    /// <remarks>May be called from any thread, typically the main thread while the import runs
    /// in a background thread. The remaining animations and files are not imported; those
    /// already added stay.</remarks>
    procedure RequestAbort;

    //** @abstract(Tells whether a name can be given to an imported animation.)
    //**
    //** @param(AName The name wanted; leading and trailing spaces are ignored.)
    //**
    //** @returns(Empty when the name is fine, otherwise why it is not.)
    /// <summary>Tells whether a name can be given to an imported animation.</summary>
    /// <param name="AName">The name wanted; leading and trailing spaces are ignored.</param>
    /// <returns>Empty when the name is fine, otherwise why it is not.</returns>
    function NameProblem(const AName: string): string;

    //** @abstract(Suggests a name the model does not use yet.)
    //**
    //** @param(AName The name wanted.)
    //**
    //** @returns(AName followed by "_2", "_3" and so on: the first the model does not use. A
    //** "_N" already at the end of AName is replaced.)
    /// <summary>Suggests a name the model does not use yet.</summary>
    /// <param name="AName">The name wanted.</param>
    /// <returns>AName followed by "_2", "_3" and so on: the first the model does not use. A
    /// "_N" already at the end of AName is replaced.</returns>
    function SuggestName(const AName: string): string;

    //** @abstract(The document receiving the animations.)
    /// <summary>The document receiving the animations.</summary>
    property Target: TglTFDocument read FTarget;

    //** @abstract(Number of animations found in the files so far.)
    /// <summary>Number of animations found in the files so far.</summary>
    property Count: Integer read GetCount;

    //** @abstract(The animations found, in the order the files and their animations were
    //** read.)
    /// <summary>The animations found, in the order the files and their animations were
    /// read.</summary>
    property Candidates[AIndex: Integer]: TglTFAnimationCandidate read GetCandidate; default;

    //** @abstract(Number of animations added or replaced so far.)
    /// <summary>Number of animations added or replaced so far.</summary>
    property ImportedCount: Integer read FImportedCount;

    //** @abstract(Whether the import was asked to stop.)
    //**
    //** May be read from any thread.
    /// <summary>Whether the import was asked to stop.</summary>
    /// <remarks>May be read from any thread.</remarks>
    property AbortRequested: Boolean read GetAbortRequested;

    //** @abstract(Occurs as files are loaded and animations added.)
    //**
    //** Each file is one model: its load takes the first half, adding its animations the
    //** second. Called on the importing thread; see TglTFProgressEvent.
    /// <summary>Occurs as files are loaded and animations added.</summary>
    /// <remarks>Each file is one model: its load takes the first half, adding its animations
    /// the second. Called on the importing thread; see TglTFProgressEvent.</remarks>
    property OnProgress: TglTFProgressEvent read FOnProgress write FOnProgress;

    //** @abstract(Asks what to do with each duplicate; see @link(TglTFDuplicateEvent).)
    /// <summary>Asks what to do with each duplicate; see
    /// <see cref="TglTFDuplicateEvent"/>.</summary>
    property OnDuplicate: TglTFDuplicateEvent read FOnDuplicate write FOnDuplicate;

    //** @abstract(What happened: files loaded or not, channels skipped, animations added,
    //** replaced, renamed or kept, and any abort.)
    /// <summary>What happened: files loaded or not, channels skipped, animations added,
    /// replaced, renamed or kept, and any abort.</summary>
    property Log: TStringList read FLog;
  end;

implementation

uses
  System.IOUtils, System.JSON, System.RegularExpressions, System.SyncObjs,
  glTF.Edit;

type
  // One file being imported: its document and the indices of what was
  // already copied from it, so data two animations share is copied once
  TSourceFile = class
  public
    Doc: TglTFDocument;
    FileName: string;
    NodeMap: TArray<Integer>;
    Accessors: TDictionary<Integer, Integer>;
    Views: TDictionary<Integer, Integer>;
    constructor Create(ADoc: TglTFDocument; const AFileName: string);
    destructor Destroy; override;
  end;

constructor TSourceFile.Create(ADoc: TglTFDocument; const AFileName: string);
begin
  inherited Create;
  Doc := ADoc;
  FileName := AFileName;
  Accessors := TDictionary<Integer, Integer>.Create;
  Views := TDictionary<Integer, Integer>.Create;
end;

destructor TSourceFile.Destroy;
begin
  Views.Free;
  Accessors.Free;
  Doc.Free;
  inherited;
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

function NodeLabel(ARoot: TglTF; AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex < ARoot.Nodes.Count) and (ARoot.Nodes[AIndex].Name <> '') then
    Result := Format('node %d "%s"', [AIndex, ARoot.Nodes[AIndex].Name])
  else
    Result := Format('node %d', [AIndex]);
end;

{ TglTFAnimationCandidate }

constructor TglTFAnimationCandidate.Create;
begin
  inherited Create;
  FNotes := TStringList.Create;
  FReplaced := GLTF_UNDEFINED_INDEX;
end;

destructor TglTFAnimationCandidate.Destroy;
begin
  FNotes.Free;
  inherited;
end;

function TglTFAnimationCandidate.Description: string;
begin
  if FOriginalName <> '' then
    Result := Format('"%s"', [FOriginalName])
  else
    Result := Format('unnamed animation %d', [FSourceIndex]);
  if FFileName <> '' then
    Result := Result + ' from ' + ExtractFileName(FFileName);
end;

function TglTFAnimationCandidate.GetChannelCount: Integer;
begin
  Result := Length(FTargets);
end;

{ TglTFAnimationImporter }

constructor TglTFAnimationImporter.Create(ATarget: TglTFDocument);
begin
  inherited Create;
  FTarget := ATarget;
  FSources := TObjectList<TObject>.Create(True);
  FCandidates := TObjectList<TglTFAnimationCandidate>.Create(True);
  FLog := TStringList.Create;
  FBuffer := GLTF_UNDEFINED_INDEX;
  FModelIndex := 1;
  FModelCount := 1;
end;

destructor TglTFAnimationImporter.Destroy;
begin
  FPending.Free;
  FCandidates.Free;
  FSources.Free;
  FLog.Free;
  inherited;
end;

function TglTFAnimationImporter.GetCount: Integer;
begin
  Result := FCandidates.Count;
end;

function TglTFAnimationImporter.GetCandidate(AIndex: Integer): TglTFAnimationCandidate;
begin
  Result := FCandidates[AIndex];
end;

procedure TglTFAnimationImporter.RequestAbort;
begin
  // Interlocked, so the flag is seen at once by the importing thread on
  // every platform, ARM included; the importer reads it between animations
  TInterlocked.Exchange(FAbortFlag, 1);
end;

function TglTFAnimationImporter.GetAbortRequested: Boolean;
begin
  Result := TInterlocked.CompareExchange(FAbortFlag, 0, 0) <> 0;
end;

procedure TglTFAnimationImporter.Report(const AStage: string; ADone: Double);
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

procedure TglTFAnimationImporter.SourceProgress(Sender: TObject; const AProgress: TglTFProgress);
begin
  // A file's own load is the first half of its model
  Report(AProgress.Stage, 0.5 * AProgress.Done);
end;

function TglTFAnimationImporter.ImportFiles(const AFileNames: TArray<string>): Integer;
var
  LDoc: TglTFDocument;
  I: Integer;
begin
  Result := 0;
  FModelCount := Length(AFileNames);
  try
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
          Report('Not loaded', 1);
          Continue;
        end;
      end;
      Inc(Result, ImportSource(LDoc, AFileNames[I]));
    end;
  finally
    // Also after an error: the model keeps what was added
    RemoveReplacedData;
  end;
end;

function TglTFAnimationImporter.ImportDocument(ASource: TglTFDocument;
  const AFileName: string): Integer;
begin
  FModelIndex := 1;
  FModelCount := 1;
  FLoadingName := ExtractFileName(AFileName);
  try
    Result := ImportSource(ASource, AFileName);
  finally
    RemoveReplacedData;
  end;
end;

function TglTFAnimationImporter.MatchNodes(ASource: TglTFDocument;
  const AFileName: string): TArray<Integer>;
var
  LModel: TglTF;
  LName: string;
  I, J, LFound: Integer;
  LSameLayout: Boolean;
begin
  // For each node of the source, the model's node it stands for, or -1
  LModel := FTarget.Root;
  SetLength(Result, ASource.Root.Nodes.Count);
  LSameLayout := ASource.Root.Nodes.Count = LModel.Nodes.Count;
  for I := 0 to ASource.Root.Nodes.Count - 1 do
  begin
    LName := ASource.Root.Nodes[I].Name;
    LFound := GLTF_UNDEFINED_INDEX;
    if LName <> '' then
    begin
      for J := 0 to LModel.Nodes.Count - 1 do
        if LModel.Nodes[J].Name = LName then
        begin
          LFound := J;
          Break;
        end;
      if LFound < 0 then
        for J := 0 to LModel.Nodes.Count - 1 do
          if SameText(LModel.Nodes[J].Name, LName) then
          begin
            LFound := J;
            Break;
          end;
    end
    else if LSameLayout then
      LFound := I; // unnamed: same position in a file of the same layout
    Result[I] := LFound;
  end;
end;

procedure TglTFAnimationImporter.Analyze(ACandidate: TglTFAnimationCandidate);
var
  LFile: TSourceFile;
  LSource, LModel: TglTF;
  LAnimation: TglTFAnimation;
  LChannel: TglTFAnimationChannel;
  LSamplers: TList<Integer>;
  LTarget, LNode, I: Integer;
  LProblem: string;

  function ViewProblem(AView: Integer): string;
  var
    LView: TglTFBufferView;
    LBuffer: TglTFBuffer;
    LNames: TArray<string>;
  begin
    Result := '';
    if AView = GLTF_UNDEFINED_INDEX then
      Exit;
    if (AView < 0) or (AView >= LSource.BufferViews.Count) then
      Exit(Format('bufferView %d does not exist', [AView]));
    LView := LSource.BufferViews[AView];
    if LView.HasExtensions then
    begin
      LNames := LView.ExtensionNames;
      Exit(Format('bufferView %d uses the %s extension, which cannot be imported',
        [AView, string.Join(', ', LNames)]));
    end;
    if (LView.Buffer < 0) or (LView.Buffer >= LSource.Buffers.Count) then
      Exit(Format('bufferView %d refers to buffer %d, which does not exist', [AView, LView.Buffer]));
    LBuffer := LSource.Buffers[LView.Buffer];
    if LBuffer.Data = nil then
      Exit(Format('the data of buffer %d is not available (%s)', [LView.Buffer, LBuffer.Uri]));
    if (LView.ByteOffset < 0) or (LView.ByteOffset + LView.ByteLength > Length(LBuffer.Data)) then
      Exit(Format('bufferView %d is outside its buffer', [AView]));
  end;

  function AccessorProblem(AAccessor: Integer): string;
  var
    LAccessor: TglTFAccessor;
  begin
    if (AAccessor < 0) or (AAccessor >= LSource.Accessors.Count) then
      Exit(Format('accessor %d does not exist', [AAccessor]));
    LAccessor := LSource.Accessors[AAccessor];
    Result := ViewProblem(LAccessor.BufferView);
    if (Result = '') and Assigned(LAccessor.Sparse) then
    begin
      if Assigned(LAccessor.Sparse.Indices) then
        Result := ViewProblem(LAccessor.Sparse.Indices.BufferView);
      if (Result = '') and Assigned(LAccessor.Sparse.Values) then
        Result := ViewProblem(LAccessor.Sparse.Values.BufferView);
    end;
  end;

begin
  LFile := TSourceFile(ACandidate.FSourceFile);
  LSource := LFile.Doc.Root;
  LModel := FTarget.Root;
  LAnimation := LSource.Animations[ACandidate.SourceIndex];
  SetLength(ACandidate.FTargets, LAnimation.Channels.Count);
  ACandidate.FMatchedChannels := 0;

  LSamplers := TList<Integer>.Create;
  try
    // 1. Which model node each channel animates
    for I := 0 to LAnimation.Channels.Count - 1 do
    begin
      LChannel := LAnimation.Channels[I];
      LTarget := GLTF_UNDEFINED_INDEX;
      LNode := LChannel.Target.Node;
      if (LChannel.Sampler < 0) or (LChannel.Sampler >= LAnimation.Samplers.Count) then
        ACandidate.FNotes.Add(Format('channel %d skipped: sampler %d does not exist',
          [I, LChannel.Sampler]))
      else if LNode = GLTF_UNDEFINED_INDEX then
        ACandidate.FNotes.Add(Format('channel %d skipped: it has no node, so it cannot be ' +
          'matched to the model', [I]))
      else if LChannel.Target.AnimationPath = apUnknown then
        ACandidate.FNotes.Add(Format('channel %d skipped: the path "%s" is not supported',
          [I, LChannel.Target.Path]))
      else if (LNode < 0) or (LNode >= Length(LFile.NodeMap)) then
        ACandidate.FNotes.Add(Format('channel %d skipped: node %d does not exist', [I, LNode]))
      else if LFile.NodeMap[LNode] < 0 then
        ACandidate.FNotes.Add(Format('channel %d skipped: %s is not in the model',
          [I, NodeLabel(LSource, LNode)]))
      else if (LChannel.Target.AnimationPath = apWeights) and
              (LModel.Nodes[LFile.NodeMap[LNode]].Mesh = GLTF_UNDEFINED_INDEX) then
        ACandidate.FNotes.Add(Format('channel %d skipped: %s of the model has no mesh, so ' +
          'its morph weights cannot be animated', [I, NodeLabel(LModel, LFile.NodeMap[LNode])]))
      else
      begin
        LTarget := LFile.NodeMap[LNode];
        Inc(ACandidate.FMatchedChannels);
        if not LSamplers.Contains(LChannel.Sampler) then
          LSamplers.Add(LChannel.Sampler);
      end;
      ACandidate.FTargets[I] := LTarget;
    end;

    // 2. The data of the samplers kept must be there to copy
    if ACandidate.FMatchedChannels = 0 then
      ACandidate.FError := 'none of its channels animates a node of the model'
    else
      for I in LSamplers do
      begin
        LProblem := AccessorProblem(LAnimation.Samplers[I].Input);
        if LProblem = '' then
          LProblem := AccessorProblem(LAnimation.Samplers[I].Output);
        if LProblem <> '' then
        begin
          ACandidate.FError := LProblem;
          Break;
        end;
      end;
  finally
    LSamplers.Free;
  end;

  ACandidate.FWillImport := ACandidate.FError = '';
  if ACandidate.FError <> '' then
    FLog.Add(Format('%s: not imported: %s', [ACandidate.Description, ACandidate.FError]))
  else if ACandidate.FNotes.Count > 0 then
    FLog.Add(Format('%s: %d of %d channels matched the model', [ACandidate.Description,
      ACandidate.FMatchedChannels, ACandidate.ChannelCount]));
  for LProblem in ACandidate.FNotes do
    FLog.Add('  ' + LProblem);
end;

function TglTFAnimationImporter.ImportSource(ASource: TglTFDocument;
  const AFileName: string): Integer;
var
  LFile: TSourceFile;
  LCandidate: TglTFAnimationCandidate;
  LShort, LStem, LWarning: string;
  I, LCount: Integer;
begin
  Result := 0;
  LFile := TSourceFile.Create(ASource, AFileName);
  FSources.Add(LFile);

  LShort := ExtractFileName(AFileName);
  if LShort = '' then
    LShort := 'stream';
  LStem := TPath.GetFileNameWithoutExtension(AFileName);
  if LStem = '' then
    LStem := 'animation';

  for LWarning in ASource.Warnings do
    FLog.Add(Format('%s: %s', [LShort, LWarning]));

  LCount := ASource.Root.Animations.Count;
  if LCount = 0 then
  begin
    FLog.Add(Format('%s: has no animations', [LShort]));
    Report('No animations', 1);
    Exit;
  end;
  FLog.Add(Format('%s: %d animation(s)', [LShort, LCount]));

  LFile.NodeMap := MatchNodes(ASource, AFileName);

  for I := 0 to LCount - 1 do
  begin
    // An abort stops between animations
    if AbortRequested then
    begin
      FLog.Add(Format('Aborted: %d animation(s) of %s not imported', [LCount - I, LShort]));
      Break;
    end;

    LCandidate := TglTFAnimationCandidate.Create;
    FCandidates.Add(LCandidate);
    LCandidate.FSourceFile := LFile;
    LCandidate.FSource := ASource;
    LCandidate.FFileName := AFileName;
    LCandidate.FSourceIndex := I;
    LCandidate.FOriginalName := ASource.Root.Animations[I].Name;
    if LCandidate.FOriginalName <> '' then
      LCandidate.FName := LCandidate.FOriginalName
    else if LCount = 1 then
      LCandidate.FName := LStem
    else
      LCandidate.FName := Format('%s_%d', [LStem, I + 1]);

    Report(Format('Adding animation "%s" (%d of %d)', [LCandidate.Name, I + 1, LCount]),
      0.5 + 0.5 * I / LCount);
    Analyze(LCandidate);
    if LCandidate.WillImport and ImportCandidate(LCandidate) then
      Inc(Result);
  end;
  Report(Format('%d of %d animation(s) added', [Result, LCount]), 1);
end;

function TglTFAnimationImporter.FindDuplicate(const AName: string): Integer;
begin
  // Case ignored, as by every duplicate check (TglTFEdit.SameName)
  Result := TglTFEdit.FindAnimation(FTarget.Root, AName);
  if Result < 0 then
    Result := GLTF_UNDEFINED_INDEX;
end;

function TglTFAnimationImporter.NameProblem(const AName: string): string;
begin
  Result := TglTFEdit.AnimationNameProblem(FTarget.Root, AName);
end;

function TglTFAnimationImporter.SuggestName(const AName: string): string;
var
  LBase: string;
  N: Integer;
begin
  LBase := TRegEx.Replace(Trim(AName), '_\d+$', '');
  if LBase = '' then
    LBase := 'animation';
  N := 2;
  repeat
    Result := Format('%s_%d', [LBase, N]);
    Inc(N);
  until NameProblem(Result) = '';
end;

function TglTFAnimationImporter.ImportCandidate(ACandidate: TglTFAnimationCandidate): Boolean;
var
  LExisting: Integer;
  LAction: TglTFDuplicateAction;
  LNewName: string;
  LAnimation: TglTFAnimation;
begin
  Result := False;

  // 1. A duplicate name: ask
  LExisting := FindDuplicate(ACandidate.Name);
  LAction := daRename;
  if LExisting <> GLTF_UNDEFINED_INDEX then
  begin
    LAction := daKeep;
    LNewName := SuggestName(ACandidate.Name);
    if Assigned(FOnDuplicate) then
      FOnDuplicate(Self, ACandidate, LExisting, LAction, LNewName);
    case LAction of
      daKeep:
      begin
        FLog.Add(Format('%s: not imported, the model''s "%s" is kept', [ACandidate.Description,
          FTarget.Root.Animations[LExisting].Name]));
        Exit;
      end;
      daAbort:
      begin
        FLog.Add(Format('%s: not imported; import aborted', [ACandidate.Description]));
        RequestAbort;
        Exit;
      end;
      daRename:
      begin
        if NameProblem(LNewName) <> '' then
          LNewName := SuggestName(ACandidate.Name);
        ACandidate.FName := Trim(LNewName);
      end;
    end;
  end;

  // 2. Into the model now: replacing keeps the old one's place in the list.
  //    The old one's data is removed at the end, as removing it renumbers
  //    accessors that the copies of later animations are mapped to
  LAnimation := CopyAnimation(ACandidate, FBuffer);
  if (LExisting <> GLTF_UNDEFINED_INDEX) and (LAction = daReplace) then
  begin
    FOldAccessors := FOldAccessors +
      TglTFEdit.AnimationAccessors(FTarget.Root.Animations[LExisting]);
    FTarget.Root.Animations.Delete(LExisting);
    FTarget.Root.Animations.Insert(LExisting, LAnimation);
    ACandidate.FReplaced := LExisting;
    FLog.Add(Format('%s: replaced animation %d', [ACandidate.Description, LExisting]));
  end
  else
  begin
    FTarget.Root.Animations.Add(LAnimation);
    FLog.Add(Format('%s: added as animation %d "%s"', [ACandidate.Description,
      FTarget.Root.Animations.Count - 1, ACandidate.Name]));
  end;
  ACandidate.FImported := True;
  Inc(FImportedCount);
  Result := True;
end;

function TglTFAnimationImporter.AppendPending(const AData: TBytes): Int64;
const
  ZEROS: array[0..3] of Byte = (0, 0, 0, 0);
var
  LLength: Int64;
  LPadding: Integer;
begin
  // The bytes collect in a stream and go into the buffer once, at the end
  // of the import: appending to the buffer each time would copy it for
  // every bufferView
  if FPending = nil then
  begin
    FPending := TMemoryStream.Create;
    LLength := Length(FTarget.Root.Buffers[FBuffer].Data);
    FPendingBase := LLength + (4 - LLength mod 4) mod 4;
  end;
  LPadding := (4 - FPending.Size mod 4) mod 4;
  if LPadding > 0 then
    FPending.WriteBuffer(ZEROS[0], LPadding);
  Result := FPendingBase + FPending.Size;
  if Length(AData) > 0 then
    FPending.WriteBuffer(AData[0], Length(AData));
end;

procedure TglTFAnimationImporter.FlushPending;
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
      LBuffer := FTarget.Root.Buffers[FBuffer];
      LLength := Length(LBuffer.Data);
      SetLength(LData, FPendingBase + FPending.Size);
      if LLength > 0 then
        Move(LBuffer.Data[0], LData[0], LLength);
      if FPendingBase > LLength then
        FillChar(LData[LLength], FPendingBase - LLength, 0);
      Move(FPending.Memory^, LData[FPendingBase], FPending.Size);
      LBuffer.Data := LData;
      LBuffer.ByteLength := Length(LData);
    end;
  finally
    FreeAndNil(FPending);
  end;
end;

procedure TglTFAnimationImporter.RemoveReplacedData;
begin
  // The new bytes first: the views added point into them
  FlushPending;

  // Data only the replaced animations used
  if FOldAccessors <> nil then
    TglTFEdit.DeleteUnusedData(FTarget.Root, FOldAccessors, FLog);
  FOldAccessors := nil;
end;

function TglTFAnimationImporter.CopyAnimation(ACandidate: TglTFAnimationCandidate;
  var ABuffer: Integer): TglTFAnimation;
var
  LFile: TSourceFile;
  LSource, LModel: TglTF;
  LSamplerMap: TArray<Integer>;
  LChannel: TglTFAnimationChannel;
  LSampler: TglTFAnimationSampler;
  I, LNext: Integer;

  procedure AddExtensionsOf(AProperty: TglTFProperty);
  var
    LName: string;
  begin
    if (AProperty = nil) or not AProperty.HasExtensions then
      Exit;
    for LName in AProperty.ExtensionNames do
    begin
      TglTFEdit.AddExtensionUsed(LModel, LName);
      if LSource.IsExtensionRequired(LName) and not LModel.IsExtensionRequired(LName) then
        LModel.ExtensionsRequired := LModel.ExtensionsRequired + [LName];
    end;
  end;

  function CopyView(AView: Integer): Integer;
  var
    LView, LNew: TglTFBufferView;
    LData: TBytes;
  begin
    if AView = GLTF_UNDEFINED_INDEX then
      Exit(GLTF_UNDEFINED_INDEX);
    if LFile.Views.TryGetValue(AView, Result) then
      Exit;

    LView := LSource.BufferViews[AView];
    LData := Copy(LSource.Buffers[LView.Buffer].Data, Integer(LView.ByteOffset),
      Integer(LView.ByteLength));
    if ABuffer = GLTF_UNDEFINED_INDEX then
      ABuffer := TglTFEdit.DataBuffer(LModel);
    FBuffer := ABuffer;

    LNew := CloneProperty(LView, Format('bufferViews[%d]', [LModel.BufferViews.Count]))
      as TglTFBufferView;
    LNew.Buffer := ABuffer;
    LNew.ByteOffset := AppendPending(LData);
    LModel.BufferViews.Add(LNew);
    Result := LModel.BufferViews.Count - 1;
    LFile.Views.Add(AView, Result);
  end;

  function CopyAccessor(AAccessor: Integer): Integer;
  var
    LAccessor, LNew: TglTFAccessor;
  begin
    if LFile.Accessors.TryGetValue(AAccessor, Result) then
      Exit;

    LAccessor := LSource.Accessors[AAccessor];
    LNew := CloneProperty(LAccessor, Format('accessors[%d]', [LModel.Accessors.Count]))
      as TglTFAccessor;
    try
      LNew.BufferView := CopyView(LAccessor.BufferView);
      if Assigned(LAccessor.Sparse) and Assigned(LNew.Sparse) then
      begin
        if Assigned(LAccessor.Sparse.Indices) then
          LNew.Sparse.Indices.BufferView := CopyView(LAccessor.Sparse.Indices.BufferView);
        if Assigned(LAccessor.Sparse.Values) then
          LNew.Sparse.Values.BufferView := CopyView(LAccessor.Sparse.Values.BufferView);
        AddExtensionsOf(LNew.Sparse);
        AddExtensionsOf(LNew.Sparse.Indices);
        AddExtensionsOf(LNew.Sparse.Values);
      end;
      AddExtensionsOf(LNew);
    except
      LNew.Free;
      raise;
    end;
    LModel.Accessors.Add(LNew);
    Result := LModel.Accessors.Count - 1;
    LFile.Accessors.Add(AAccessor, Result);
  end;

begin
  LFile := TSourceFile(ACandidate.FSourceFile);
  LSource := LFile.Doc.Root;
  LModel := FTarget.Root;

  Result := CloneProperty(LSource.Animations[ACandidate.SourceIndex],
    Format('animations[%d]', [LModel.Animations.Count])) as TglTFAnimation;
  try
    // Channels: the skipped ones go, the others now animate the model's nodes
    for I := Result.Channels.Count - 1 downto 0 do
      if ACandidate.FTargets[I] = GLTF_UNDEFINED_INDEX then
        Result.Channels.Delete(I)
      else
        Result.Channels[I].Target.Node := ACandidate.FTargets[I];

    // Samplers: only those a remaining channel uses, in their original order
    SetLength(LSamplerMap, Result.Samplers.Count);
    for I := 0 to High(LSamplerMap) do
      LSamplerMap[I] := GLTF_UNDEFINED_INDEX;
    for LChannel in Result.Channels do
      LSamplerMap[LChannel.Sampler] := 0;
    LNext := 0;
    for I := 0 to High(LSamplerMap) do
      if LSamplerMap[I] = 0 then
      begin
        LSamplerMap[I] := LNext;
        Inc(LNext);
      end;
    for LChannel in Result.Channels do
      LChannel.Sampler := LSamplerMap[LChannel.Sampler];
    for I := Result.Samplers.Count - 1 downto 0 do
      if LSamplerMap[I] = GLTF_UNDEFINED_INDEX then
        Result.Samplers.Delete(I);

    // Their data, copied into the model
    for LSampler in Result.Samplers do
    begin
      LSampler.Input := CopyAccessor(LSampler.Input);
      LSampler.Output := CopyAccessor(LSampler.Output);
      AddExtensionsOf(LSampler);
    end;
    for LChannel in Result.Channels do
    begin
      AddExtensionsOf(LChannel);
      AddExtensionsOf(LChannel.Target);
    end;
    AddExtensionsOf(Result);

    Result.Name := ACandidate.Name;
    Result.Origin := ExtractFileName(ACandidate.FileName);
    Result.ExportOnSave := True;
  except
    Result.Free;
    raise;
  end;
end;

end.
