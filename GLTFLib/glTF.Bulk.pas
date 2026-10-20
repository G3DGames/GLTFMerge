//** @abstract(Re-orients every model in a folder tree, saving the turned copies in another folder
//** with the same sub-folders.)
//**
//** @link(TglTFBulkReorienter) looks for .glb and/or .gltf files in an input folder and all its
//** sub-folders, then loads each one, turns it as TglTFReorienter does and saves it under the
//** output folder at the same relative path, as .glb or .gltf. The input files are never
//** changed. Saving follows the rules of @code(TglTFDocument.SaveToFile): a GLB holds its
//** images, a glTF writes them as separate files next to it, images no mesh shows are left
//** out, missing media are saved as references with a warning, and an image file never
//** replaces a different file already there.
//**
//** Two input files that would be saved under the same name, such as walk.glb and walk.gltf
//** saved as GLB, are told apart by adding the input extension: walk_gltf.glb. A model that
//** cannot be loaded or saved is reported and the others carry on.
//**
//** The work is meant for a background thread: @link(TglTFBulkReorienter.OnProgress)
//** reports each model and @link(TglTFBulkReorienter.RequestAbort) stops after the model
//** being saved. The class has no user interface.
unit glTF.Bulk;

{
  Re-orients every model in a folder tree, saving the turned copies in
  another folder with the same sub-folders.

  TglTFBulkReorienter looks for .glb and/or .gltf files in an input folder and
  all its sub-folders, then loads each one, turns it as TglTFReorienter does
  and saves it under the output folder at the same relative path, as .glb or
  .gltf. The input files are never changed. Saving follows the rules of
  TglTFDocument.SaveToFile: a GLB holds its images, a glTF writes them as
  separate files next to it, images no mesh shows are left out, missing media
  are saved as references with a warning, and an image file never replaces a
  different file already there.

  Two input files that would be saved under the same name, such as walk.glb
  and walk.gltf saved as GLB, are told apart by adding the input extension:
  walk_gltf.glb. A model that cannot be loaded or saved is reported and the
  others carry on.

  The work is meant for a background thread: OnProgress reports each model and
  RequestAbort stops after the model being saved. The class has no user
  interface.
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  System.Generics.Defaults,

  glTF.Document;

type
  //** @abstract(Which input files are converted.)
  /// <summary>Which input files are converted.</summary>
  TglTFBulkInput = (
    //** @abstract(.glb files only.)
    /// <summary>.glb files only.</summary>
    biGLB,

    //** @abstract(.gltf files only.)
    /// <summary>.gltf files only.</summary>
    biGLTF,

    //** @abstract(Both .glb and .gltf files.)
    /// <summary>Both .glb and .gltf files.</summary>
    biBoth);

  //** @abstract(What a bulk re-orientation does.)
  /// <summary>What a bulk re-orientation does.</summary>
  TglTFBulkOptions = record
    //** @abstract(The folder searched, with all its sub-folders.)
    /// <summary>The folder searched, with all its sub-folders.</summary>
    InputFolder: string;

    //** @abstract(Which files in it are converted.)
    /// <summary>Which files in it are converted.</summary>
    Input: TglTFBulkInput;

    //** @abstract(The folder the turned copies go in, created when needed.)
    /// <summary>The folder the turned copies go in, created when needed.</summary>
    OutputFolder: string;

    //** @abstract(The format saved: gffGLB or gffJSON.)
    /// <summary>The format saved: gffGLB or gffJSON.</summary>
    OutputFormat: TglTFFileFormat;

    //** @abstract(Degrees about the X axis, applied first.)
    /// <summary>Degrees about the X axis, applied first.</summary>
    RotateX: Double;

    //** @abstract(Degrees about the Y axis, applied second.)
    /// <summary>Degrees about the Y axis, applied second.</summary>
    RotateY: Double;

    //** @abstract(Degrees about the Z axis, applied last.)
    /// <summary>Degrees about the Z axis, applied last.</summary>
    RotateZ: Double;

    //** @abstract(Saves the images without their EXIF data; see
    //** @code(TglTFSaveOptions.StripExif).)
    /// <summary>Saves the images without their EXIF data; see
    /// <c>TglTFSaveOptions.StripExif</c>.</summary>
    StripExif: Boolean;

    //** @abstract(Returns options for both input types, saved as GLB, with no turn, EXIF data
    //** kept and no folders.)
    //**
    //** @returns(The options.)
    /// <summary>Returns options for both input types, saved as GLB, with no turn, EXIF data
    /// kept and no folders.</summary>
    /// <returns>The options.</returns>
    class function Default: TglTFBulkOptions; static;
  end;

  //** @abstract(One model to convert: where it is read from and where it is saved.)
  /// <summary>One model to convert: where it is read from and where it is saved.</summary>
  TglTFBulkItem = record
    //** @abstract(The input file.)
    /// <summary>The input file.</summary>
    Source: string;

    //** @abstract(The output file, at the same relative path under the output folder.)
    /// <summary>The output file, at the same relative path under the output folder.</summary>
    Target: string;

    //** @abstract(The input file's path relative to the input folder, for messages.)
    /// <summary>The input file's path relative to the input folder, for messages.</summary>
    RelativePath: string;
  end;

  //** @abstract(Finds the models in a folder tree and saves re-oriented copies of them.)
  //**
  //** Call @link(FindModels), then @link(Run), usually from a background thread; read
  //** @link(Log) and the counts afterwards.
  /// <summary>Finds the models in a folder tree and saves re-oriented copies of
  /// them.</summary>
  /// <remarks>Call <see cref="FindModels"/>, then <see cref="Run"/>, usually from a
  /// background thread; read <see cref="Log"/> and the counts afterwards.</remarks>
  TglTFBulkReorienter = class
  private
    FOptions: TglTFBulkOptions;
    FItems: TArray<TglTFBulkItem>;
    FLog: TStringList;
    FSaved: Integer;
    FFailed: Integer;
    FWarned: Integer;
    FCurrent: Integer;
    FAbortRequested: Boolean;
    FOnProgress: TglTFProgressEvent;
    procedure Report(const AStage: string; ADone: Double);
    procedure DocumentProgress(Sender: TObject; const AProgress: TglTFProgress);
    function Wanted(const AFileName: string): Boolean;
    procedure Search(const AFolder, AOutput: string; AFiles: TList<string>);
  public
    //** @abstract(Creates the re-orienter.)
    //**
    //** @param(AOptions What to convert and how.)
    /// <summary>Creates the re-orienter.</summary>
    /// <param name="AOptions">What to convert and how.</param>
    constructor Create(const AOptions: TglTFBulkOptions);

    //** @abstract(Frees the re-orienter.)
    /// <summary>Frees the re-orienter.</summary>
    destructor Destroy; override;

    //** @abstract(Tells why options cannot be used.)
    //**
    //** The input folder must exist and the output folder must be given. They must not be the
    //** same folder, and the input folder must not be inside the output folder, so no input
    //** file can be replaced. The output folder may be inside the input folder: it is then
    //** left out of the search. The angles must be from -360 to 360 and the output format GLB
    //** or glTF.
    //**
    //** @param(AOptions The options.)
    //**
    //** @returns(The reason, or an empty string when the options can be used.)
    /// <summary>Tells why options cannot be used.</summary>
    /// <param name="AOptions">The options.</param>
    /// <returns>The reason, or an empty string when the options can be used.</returns>
    /// <remarks>The input folder must exist and the output folder must be given. They must not
    /// be the same folder, and the input folder must not be inside the output folder, so no
    /// input file can be replaced. The output folder may be inside the input folder: it is
    /// then left out of the search. The angles must be from -360 to 360 and the output format
    /// GLB or glTF.</remarks>
    class function Problem(const AOptions: TglTFBulkOptions): string; static;

    //** @abstract(Returns the extension of a format: .glb or .gltf.)
    //**
    //** @param(AFormat gffGLB or gffJSON.)
    //**
    //** @returns(The extension, with its dot.)
    /// <summary>Returns the extension of a format: .glb or .gltf.</summary>
    /// <param name="AFormat">gffGLB or gffJSON.</param>
    /// <returns>The extension, with its dot.</returns>
    class function Extension(AFormat: TglTFFileFormat): string; static;

    //** @abstract(Searches the input folder and its sub-folders for the models to convert.)
    //**
    //** Folders that cannot be read are skipped and noted in the log. The models are sorted by
    //** path, and each gets its output file; two that would share one are told apart.
    //** RequestAbort stops the search early, with the models found so far.
    //**
    //** @returns(The number of models found; see @link(Items).)
    //**
    //** @raises(EArgumentException The options cannot be used; see @link(Problem).)
    /// <summary>Searches the input folder and its sub-folders for the models to
    /// convert.</summary>
    /// <returns>The number of models found; see <see cref="Items"/>.</returns>
    /// <remarks>Folders that cannot be read are skipped and noted in the log. The models are
    /// sorted by path, and each gets its output file; two that would share one are told
    /// apart. RequestAbort stops the search early, with the models found so far.</remarks>
    function FindModels: Integer;

    //** @abstract(Counts the output files that already exist and would be replaced.)
    //**
    //** @returns(The count, among @link(Items).)
    /// <summary>Counts the output files that already exist and would be replaced.</summary>
    /// <returns>The count, among <see cref="Items"/>.</returns>
    function ExistingTargets: Integer;

    //** @abstract(Loads, turns and saves every model found.)
    //**
    //** Each model is loaded into its own document, saved to its output file with the turn
    //** and then freed. A failure is logged and counted, and the next model is done. Stops
    //** early, after the model being saved, when @link(RequestAbort) was called.
    //**
    //** @returns(The number of models saved.)
    /// <summary>Loads, turns and saves every model found.</summary>
    /// <returns>The number of models saved.</returns>
    /// <remarks>Each model is loaded into its own document, saved to its output file with the
    /// turn and then freed. A failure is logged and counted, and the next model is done.
    /// Stops early, after the model being saved, when <see cref="RequestAbort"/> was
    /// called.</remarks>
    function Run: Integer;

    //** @abstract(Asks Run to stop after the model it is on; may be called from any thread.)
    /// <summary>Asks Run to stop after the model it is on; may be called from any
    /// thread.</summary>
    procedure RequestAbort;

    //** @abstract(The options given.)
    /// <summary>The options given.</summary>
    property Options: TglTFBulkOptions read FOptions;

    //** @abstract(The models found by FindModels, in the order Run converts them.)
    /// <summary>The models found by FindModels, in the order Run converts them.</summary>
    property Items: TArray<TglTFBulkItem> read FItems;

    //** @abstract(One line per model and per warning, for the user.)
    /// <summary>One line per model and per warning, for the user.</summary>
    property Log: TStringList read FLog;

    //** @abstract(The models saved by Run.)
    /// <summary>The models saved by Run.</summary>
    property Saved: Integer read FSaved;

    //** @abstract(The models that could not be loaded or saved.)
    /// <summary>The models that could not be loaded or saved.</summary>
    property Failed: Integer read FFailed;

    //** @abstract(The models saved with warnings, for example missing media.)
    /// <summary>The models saved with warnings, for example missing media.</summary>
    property Warned: Integer read FWarned;

    //** @abstract(Whether RequestAbort was called.)
    /// <summary>Whether RequestAbort was called.</summary>
    property AbortRequested: Boolean read FAbortRequested;

    //** @abstract(Reports each model and how far its load and save have got; called on the
    //** thread that runs FindModels or Run.)
    /// <summary>Reports each model and how far its load and save have got; called on the
    /// thread that runs FindModels or Run.</summary>
    property OnProgress: TglTFProgressEvent read FOnProgress write FOnProgress;
  end;

implementation

// A folder's full path ending in a separator, so that "C:\A" is not taken
// to contain "C:\AB"
function FolderKey(const AFolder: string): string;
begin
  Result := IncludeTrailingPathDelimiter(TPath.GetFullPath(AFolder));
end;

// Whether AInner is AOuter or a folder inside it; case is ignored, as on
// Windows and macOS, which errs on the safe side elsewhere
function FolderWithin(const AInner, AOuter: string): Boolean;
begin
  Result := AnsiLowerCase(FolderKey(AInner)).StartsWith(AnsiLowerCase(FolderKey(AOuter)));
end;

{ TglTFBulkOptions }

class function TglTFBulkOptions.Default: TglTFBulkOptions;
begin
  Result.InputFolder := '';
  Result.Input := biBoth;
  Result.OutputFolder := '';
  Result.OutputFormat := gffGLB;
  Result.RotateX := 0;
  Result.RotateY := 0;
  Result.RotateZ := 0;
  Result.StripExif := False;
end;

{ TglTFBulkReorienter }

constructor TglTFBulkReorienter.Create(const AOptions: TglTFBulkOptions);
begin
  inherited Create;
  FOptions := AOptions;
  FLog := TStringList.Create;
end;

destructor TglTFBulkReorienter.Destroy;
begin
  FLog.Free;
  inherited;
end;

class function TglTFBulkReorienter.Extension(AFormat: TglTFFileFormat): string;
begin
  if AFormat = gffJSON then
    Result := '.gltf'
  else
    Result := '.glb';
end;

class function TglTFBulkReorienter.Problem(const AOptions: TglTFBulkOptions): string;

  function BadAngle(AValue: Double): Boolean;
  begin
    Result := (AValue < -360) or (AValue > 360);
  end;

begin
  if Trim(AOptions.InputFolder) = '' then
    Exit('Choose the input folder');
  if not TDirectory.Exists(AOptions.InputFolder) then
    Exit('The input folder does not exist');
  if Trim(AOptions.OutputFolder) = '' then
    Exit('Choose the output folder');
  try
    if FolderWithin(AOptions.InputFolder, AOptions.OutputFolder) then
    begin
      if FolderWithin(AOptions.OutputFolder, AOptions.InputFolder) then
        Exit('The output folder must not be the input folder');
      Exit('The input folder must not be inside the output folder');
    end;
  except
    on E: Exception do
      Exit('The output folder is not a valid path: ' + E.Message);
  end;
  if not (AOptions.OutputFormat in [gffGLB, gffJSON]) then
    Exit('Choose GLB or glTF to save as');
  if BadAngle(AOptions.RotateX) or BadAngle(AOptions.RotateY) or BadAngle(AOptions.RotateZ) then
    Exit('Each angle must be from -360 to 360');
  Result := '';
end;

function TglTFBulkReorienter.Wanted(const AFileName: string): Boolean;
var
  LExt: string;
begin
  LExt := ExtractFileExt(AFileName);
  case FOptions.Input of
    biGLB: Result := SameText(LExt, '.glb');
    biGLTF: Result := SameText(LExt, '.gltf');
  else
    Result := SameText(LExt, '.glb') or SameText(LExt, '.gltf');
  end;
end;

procedure TglTFBulkReorienter.Search(const AFolder, AOutput: string; AFiles: TList<string>);
var
  LEntries: TArray<string>;
  LEntry: string;
begin
  // The output folder may be inside the input folder: its files are results
  if FAbortRequested or FolderWithin(AFolder, AOutput) then
    Exit;
  Report('Searching ' + AFolder, 0);
  try
    LEntries := TDirectory.GetFiles(AFolder);
  except
    on E: Exception do
    begin
      FLog.Add(Format('Skipped %s: %s', [AFolder, E.Message]));
      Exit;
    end;
  end;
  for LEntry in LEntries do
    if Wanted(LEntry) then
      AFiles.Add(LEntry);

  try
    LEntries := TDirectory.GetDirectories(AFolder);
  except
    on E: Exception do
    begin
      FLog.Add(Format('Skipped the sub-folders of %s: %s', [AFolder, E.Message]));
      Exit;
    end;
  end;
  for LEntry in LEntries do
    Search(LEntry, AOutput, AFiles);
end;

function TglTFBulkReorienter.FindModels: Integer;
var
  LFiles: TList<string>;
  LTargets: TDictionary<string, Integer>;
  LInput, LOutput, LExt, LRelative, LTarget, LKey: string;
  I: Integer;
begin
  LExt := Problem(FOptions);
  if LExt <> '' then
    raise EArgumentException.Create(LExt);

  FItems := nil;
  LInput := FolderKey(FOptions.InputFolder);
  LOutput := FolderKey(FOptions.OutputFolder);
  LExt := Extension(FOptions.OutputFormat);
  FCurrent := 0;

  LFiles := TList<string>.Create;
  // Output paths already taken, lower case as file systems that ignore case
  // would see them
  LTargets := TDictionary<string, Integer>.Create;
  try
    Search(ExcludeTrailingPathDelimiter(LInput), LOutput, LFiles);
    LFiles.Sort(TComparer<string>.Construct(
      function(const A, B: string): Integer
      begin
        Result := CompareText(A, B);
      end));

    SetLength(FItems, LFiles.Count);
    for I := 0 to LFiles.Count - 1 do
    begin
      LRelative := ExtractRelativePath(LInput, LFiles[I]);
      LTarget := TPath.Combine(LOutput, ChangeFileExt(LRelative, LExt));
      LKey := AnsiLowerCase(LTarget);
      if LTargets.ContainsKey(LKey) then
      begin
        // e.g. walk.glb and walk.gltf both saved as GLB: walk_gltf.glb
        LTarget := TPath.Combine(LOutput, ChangeFileExt(LRelative, '') + '_' +
          ExtractFileExt(LRelative).Substring(1).ToLower + LExt);
        LKey := AnsiLowerCase(LTarget);
        FLog.Add(Format('%s is saved as %s, as another model has its name',
          [LRelative, ExtractRelativePath(LOutput, LTarget)]));
      end;
      LTargets.AddOrSetValue(LKey, I);
      FItems[I].Source := LFiles[I];
      FItems[I].Target := LTarget;
      FItems[I].RelativePath := LRelative;
    end;
  finally
    LTargets.Free;
    LFiles.Free;
  end;
  Result := Length(FItems);
end;

function TglTFBulkReorienter.ExistingTargets: Integer;
var
  LItem: TglTFBulkItem;
begin
  Result := 0;
  for LItem in FItems do
    if TFile.Exists(LItem.Target) then
      Inc(Result);
end;

procedure TglTFBulkReorienter.RequestAbort;
begin
  FAbortRequested := True;
end;

procedure TglTFBulkReorienter.Report(const AStage: string; ADone: Double);
var
  LProgress: TglTFProgress;
begin
  if not Assigned(FOnProgress) then
    Exit;
  LProgress.ModelIndex := FCurrent + 1;
  LProgress.ModelCount := Length(FItems);
  if LProgress.ModelCount = 0 then
  begin
    // Still searching: no model yet
    LProgress.ModelIndex := 0;
    LProgress.ModelName := '';
  end
  else
    LProgress.ModelName := FItems[FCurrent].RelativePath;
  LProgress.Stage := AStage;
  LProgress.Done := ADone;
  FOnProgress(Self, LProgress);
end;

procedure TglTFBulkReorienter.DocumentProgress(Sender: TObject; const AProgress: TglTFProgress);
begin
  // Loading takes most of a model's time; saving the rest
  Report(AProgress.Stage, 0.8 * AProgress.Done);
end;

function TglTFBulkReorienter.Run: Integer;
var
  LDoc: TglTFDocument;
  LSave: TglTFSaveOptions;
  LItem: TglTFBulkItem;
  LWarning, LOutput: string;
  I: Integer;
begin
  FSaved := 0;
  FFailed := 0;
  FWarned := 0;
  LOutput := FolderKey(FOptions.OutputFolder);
  LSave := TglTFSaveOptions.Default;
  LSave.RotateX := FOptions.RotateX;
  LSave.RotateY := FOptions.RotateY;
  LSave.RotateZ := FOptions.RotateZ;
  LSave.StripExif := FOptions.StripExif;

  for I := 0 to High(FItems) do
  begin
    if FAbortRequested then
    begin
      FLog.Add(Format('Aborted: %d model(s) not done', [Length(FItems) - I]));
      Break;
    end;
    FCurrent := I;
    LItem := FItems[I];
    Report('Loading', 0);
    LDoc := TglTFDocument.Create;
    try
      try
        LDoc.OnProgress := DocumentProgress;
        LDoc.LoadFromFile(LItem.Source);
        LDoc.OnProgress := nil;
        Report('Saving', 0.8);
        ForceDirectories(ExtractFileDir(LItem.Target));
        LDoc.SaveToFile(LItem.Target, LSave);
        Inc(FSaved);
        FLog.Add(Format('Saved %s as %s', [LItem.RelativePath,
          ExtractRelativePath(LOutput, LItem.Target)]));
        if LDoc.ExifRemoved > 0 then
          FLog.Add(Format('  EXIF data removed from %d image(s)', [LDoc.ExifRemoved]));
        for LWarning in LDoc.Warnings do
          FLog.Add('  Warning: ' + LWarning);
        for LWarning in LDoc.SaveWarnings do
          FLog.Add('  Warning: ' + LWarning);
        if (LDoc.Warnings.Count > 0) or (LDoc.SaveWarnings.Count > 0) then
          Inc(FWarned);
      except
        on E: Exception do
        begin
          Inc(FFailed);
          FLog.Add(Format('FAILED %s: %s', [LItem.RelativePath, E.Message]));
        end;
      end;
    finally
      LDoc.Free;
    end;
    Report('Done', 1);
  end;
  Result := FSaved;
end;

end.
