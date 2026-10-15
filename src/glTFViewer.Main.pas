//** @abstract(Main form of the glTF viewer: open, inspect and save glTF and GLB files.)
//**
//** The Structure tab shows the document as a tree @(see glTFViewer.Tree@); it is shown at
//** start-up and after every successful load. The Images tab lists every image and whether a
//** mesh uses it; a GLB is saved with its images inside, a glTF with separate image files,
//** unless "Alter image save mode" is ticked there to choose per image @(see
//** glTFViewer.Images@). The Animations tab lists every animation with its Export
//** choice and imports animations from other files @(see glTFViewer.Animations@); duplicate
//** names are resolved with glTFViewer.Duplicates. The Parts tab loads body parts and outfit
//** pieces from other files and puts them on the model in place of the parts they replace @(see
//** glTFViewer.Parts and glTF.Parts@). The Re-Orient tab turns the model about X, Y and Z
//** when it is saved @(see glTFViewer.Orient and glTF.Orient@). The Output tab logs loading,
//** saving and the
//** self-tests,
//** and shows errors with their line in the glTF text; it comes to the front when a load fails,
//** when saving and when the self-tests run.
//**
//** Missing media files are offered for locating after a load and before a save @(see
//** glTFViewer.Missing@). Self-tests run only when asked for, with the "Run self-tests" button
//** or --selftest.
//**
//** Loading a model, importing animations, loading part files and putting parts on run in a
//** background thread, with a progress box
//** over the form @(see glTFViewer.Progress@) showing the model number, model count and
//** stage. The form takes no input meanwhile, from the mouse, touch or the keyboard: the tabs
//** are disabled, and every handler that uses the document checks that no work is running.
//** Closing the form during the work stops an import and closes once the work has finished.
//**
//** Runs on Windows, macOS, Linux, iOS and Android. File dialogs come from glTFViewer.Dialogs:
//** native on the desktop, a built-in browser on iOS and Android. As dialogs do not block on
//** every platform, opening and saving continue in callbacks. There is no command line on iOS
//** and Android.
//**
//** @preformatted(
//** Command line @(desktop@):  glTFDemo [file.gltf|file.glb] [--selftest]
//** )
unit glTFViewer.Main;

{
  Main form of the glTF viewer: open, inspect and save glTF and GLB files.

  The Structure tab shows the document as a tree (see glTFViewer.Tree); it is
  shown at start-up and after every successful load. The Images tab lists
  every image and whether a mesh uses it; a GLB is saved with its images
  inside, a glTF with separate image files, unless "Alter image save mode" is
  ticked there to choose per image (see glTFViewer.Images). The Animations
  tab lists every animation with its Export choice and imports animations from
  other files (see glTFViewer.Animations); duplicate names are resolved with
  glTFViewer.Duplicates. The Parts tab loads body parts and outfit pieces from
  other files and puts them on the model in place of the parts they replace
  (see glTFViewer.Parts and glTF.Parts). The Re-Orient tab turns the model
  about X, Y and Z when it is saved (see glTFViewer.Orient and glTF.Orient).
  The Output tab logs loading, saving and the
  self-tests, and shows errors with their line in
  the glTF text; it comes to the front when a load fails, when saving and when
  the self-tests run.

  Missing media files are offered for locating after a load and before a save
  (see glTFViewer.Missing). Self-tests run only when asked for, with the "Run
  self-tests" button or --selftest.

  Loading a model, importing animations, loading part files and putting parts
  on run in a background thread, with a progress box over the form (see glTFViewer.Progress) showing the model
  number, model count and stage. The form takes no input meanwhile, from the
  mouse, touch or the keyboard: the tabs are disabled, and every handler that
  uses the document checks that no work is running. Closing the form during
  the work stops an import and closes once the work has finished.

  Runs on Windows, macOS, Linux, iOS and Android. File dialogs come from
  glTFViewer.Dialogs: native on the desktop, a built-in browser on iOS and
  Android. As dialogs do not block on every platform, opening and saving
  continue in callbacks. There is no command line on iOS and Android.

    Command line (desktop):  glTFDemo [file.gltf|file.glb] [--selftest]
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.IOUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.TabControl, FMX.Memo.Types, FMX.ScrollBox,
  FMX.Memo, FMX.Layouts, FMX.TreeView,

  glTF.Base, glTF.Classes, glTF.Document, glTF.Animations, glTF.Parts,
  glTFViewer.Images, glTFViewer.Animations, glTFViewer.Progress, glTFViewer.Duplicates,
  glTFViewer.Parts, glTFViewer.Orient;

type
  //** @abstract(The viewer's main window.)
  //**
  //** Holds one TglTFDocument at a time; a successful load replaces it. Loading a model and
  //** importing animations run in a background thread while a progress box blocks the
  //** window; everything else, saving included, runs on the main thread.
  /// <summary>The viewer's main window.</summary>
  /// <remarks>Holds one TglTFDocument at a time; a successful load replaces it. Loading a
  /// model and importing animations run in a background thread while a progress box blocks
  /// the window; everything else, saving included, runs on the main thread.</remarks>
  TglTFMainForm = class(TForm)
    //** @abstract(Toolbar with the Open, Save as and self-test buttons and the file name.)
    /// <summary>Toolbar with the Open, Save as and self-test buttons and the file
    /// name.</summary>
    ToolBar: TToolBar;

    //** @abstract(Opens a .gltf or .glb file.)
    /// <summary>Opens a .gltf or .glb file.</summary>
    btnOpen: TButton;

    //** @abstract(Saves the document as .gltf or .glb; enabled once a file is loaded.)
    /// <summary>Saves the document as .gltf or .glb; enabled once a file is loaded.</summary>
    btnSave: TButton;

    //** @abstract(Runs the self-tests and shows their results on the Output tab.)
    /// <summary>Runs the self-tests and shows their results on the Output tab.</summary>
    btnSelfTest: TButton;

    //** @abstract(Shows the loaded file's path, or why it failed to load.)
    /// <summary>Shows the loaded file's path, or why it failed to load.</summary>
    lblFile: TLabel;

    //** @abstract(Holds the Structure, Images, Animations, Parts, Re-Orient and Output tabs.)
    /// <summary>Holds the Structure, Images, Animations, Parts, Re-Orient and Output
    /// tabs.</summary>
    TabControl: TTabControl;

    //** @abstract(The Output tab, holding the log.)
    /// <summary>The Output tab, holding the log.</summary>
    tabOutput: TTabItem;

    //** @abstract(The Structure tab, holding the tree.)
    /// <summary>The Structure tab, holding the tree.</summary>
    tabStructure: TTabItem;

    //** @abstract(The Images tab, holding the images panel created at start-up.)
    /// <summary>The Images tab, holding the images panel created at start-up.</summary>
    tabImages: TTabItem;

    //** @abstract(The Animations tab, holding the animations panel created at start-up.)
    /// <summary>The Animations tab, holding the animations panel created at
    /// start-up.</summary>
    tabAnimations: TTabItem;

    //** @abstract(The Parts tab, holding the parts panel created at start-up.)
    /// <summary>The Parts tab, holding the parts panel created at start-up.</summary>
    tabParts: TTabItem;

    //** @abstract(The Re-Orient tab, holding the panel with the turn applied when saving.)
    /// <summary>The Re-Orient tab, holding the panel with the turn applied when
    /// saving.</summary>
    tabOrient: TTabItem;

    //** @abstract(The log: load results, document summary, save results and self-test results.)
    /// <summary>The log: load results, document summary, save results and self-test
    /// results.</summary>
    memOutput: TMemo;

    //** @abstract(The structure tree of the loaded document.)
    /// <summary>The structure tree of the loaded document.</summary>
    tvStructure: TTreeView;

    //** @abstract(Sets up the dialogs and the Images, Animations and Parts tabs, then loads
    //** the file and runs the self-tests given on the command line.)
    //**
    //** Command line: an optional file name and an optional --selftest, -selftest or /selftest,
    //** in any order.
    //**
    //** @param(Sender The control that raised the event.)
    /// <summary>Sets up the dialogs and the Images, Animations and Parts tabs, then loads the
    /// file and runs the self-tests given on the command line.</summary>
    /// <param name="Sender">The control that raised the event.</param>
    /// <remarks>Command line: an optional file name and an optional --selftest, -selftest or
    /// /selftest, in any order.</remarks>
    procedure FormCreate(Sender: TObject);

    //** @abstract(Frees the document.)
    //**
    //** Closing while a model loads or animations are imported is put off until the work
    //** has finished; see FormCloseQuery.
    //**
    //** @param(Sender The control that raised the event.)
    /// <summary>Frees the document.</summary>
    /// <remarks>Closing while a model loads or animations are imported is put off until the
    /// work has finished; see FormCloseQuery.</remarks>
    /// <param name="Sender">The control that raised the event.</param>
    procedure FormDestroy(Sender: TObject);

    //** @abstract(Asks for a .gltf or .glb file and loads it.)
    //**
    //** @param(Sender The control that raised the event.)
    /// <summary>Asks for a .gltf or .glb file and loads it.</summary>
    /// <param name="Sender">The control that raised the event.</param>
    procedure btnOpenClick(Sender: TObject);

    //** @abstract(Asks for a file name and saves the document.)
    //**
    //** Missing media files are offered for locating first, except the images no mesh shows,
    //** which are left out of the save. The dialog suggests GLB; the file type chosen in it
    //** decides the extension and format, whatever was typed; replacing an existing file is
    //** confirmed. The result, every file written or copied and any warnings are logged.
    //**
    //** @param(Sender The control that raised the event.)
    /// <summary>Asks for a file name and saves the document.</summary>
    /// <param name="Sender">The control that raised the event.</param>
    /// <remarks>Missing media files are offered for locating first, except the images no mesh
    /// shows, which are left out of the save. The dialog suggests GLB; the file type chosen in
    /// it decides the extension and format, whatever was typed; replacing an existing file is
    /// confirmed. The result, every file written or copied and any warnings are
    /// logged.</remarks>
    procedure btnSaveClick(Sender: TObject);

    //** @abstract(Shows the Output tab and runs the self-tests.)
    //**
    //** @param(Sender The control that raised the event.)
    /// <summary>Shows the Output tab and runs the self-tests.</summary>
    /// <param name="Sender">The control that raised the event.</param>
    procedure btnSelfTestClick(Sender: TObject);
  private
    FDoc: TglTFDocument;
    FImages: TglTFImagesPanel;
    FAnimations: TglTFAnimationsPanel;
    FProgress: TProgressOverlay;
    FDuplicates: TDuplicatePanel;
    FParts: TglTFPartsPanel;
    FOrient: TglTFOrientPanel;
    // The part files loaded; kept across model loads
    FPartLibrary: TglTFPartLibrary;
    // Puts parts on FDoc; replaced with the document
    FPartApplier: TglTFPartApplier;
    FDuplicateForAll: Boolean;
    FDuplicateAction: TglTFDuplicateAction;
    // True from BeginWork to EndWork, while a background task uses a document
    // and reports to this form. Read and written on the main thread only
    FBusy: Boolean;
    // The form was asked to close during the work; it closes when EndWork runs
    FCloseRequested: Boolean;
    FSelfTestAfterLoad: Boolean;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure BeginWork(const ATitle: string; const AOnAbort: TProc = nil);
    procedure EndWork;
    procedure WorkProgress(Sender: TObject; const AProgress: TglTFProgress);
    procedure LoadFinished(ADoc: TglTFDocument; const AFileName, AError, AErrorClass: string;
      AIsglTFError: Boolean);
    procedure ImagesLocateMissing(Sender: TObject);
    procedure AnimationsImport(Sender: TObject);
    procedure AnimationsClear(Sender: TObject);
    procedure AnimationsSplit(Sender: TObject);
    procedure LogLongAnimationHint;
    procedure ImportAnimationFiles(const AFiles: TArray<string>);
    procedure AskDuplicate(AImporter: TglTFAnimationImporter;
      ACandidate: TglTFAnimationCandidate; AExisting: Integer;
      var AAction: TglTFDuplicateAction; var ANewName: string);
    procedure ImportFinished(AImporter: TglTFAnimationImporter; const AError: string);
    procedure PartsAddFiles(Sender: TObject);
    procedure PartsLoadFiles(const AFiles: TArray<string>);
    procedure PartsLoadFinished(ACount: Integer; const AError: string);
    procedure PartsClearList(Sender: TObject);
    procedure PartsApply(Sender: TObject);
    procedure PartsApplyFinished(ACount: Integer; const AError: string);
    procedure PartsRemove(Sender: TObject);
    procedure PartsRefreshModel(Sender: TObject);
    procedure LogPartChanges;
    procedure ModelChanged;
    procedure Log(const AText: string = ''); overload;
    procedure Log(const AFormat: string; const AArgs: array of const); overload;
    procedure LoadFile(const AFileName: string);
    procedure LocateMissingFiles(const AContext: string; const ADone: TProc = nil);
    procedure ChooseSaveFile;
    procedure SaveAs(const AFileName: string);
    function StartFolder: string;
    procedure DumpDocument;
    procedure ExpectError(const ATitle: string; const ALines: array of string;
      AExpected: ExceptClass);
    procedure RoundTripTest(AFormat: TglTFFileFormat);
    procedure AnimationImportTest;
    procedure AnimationSplitTest;
    procedure ReorientTest;
    procedure PartsTest;
    procedure UnusedImagesTest;
    procedure RunSelfTests;
  end;

var
  //** @abstract(The main form instance, created by the project file.)
  /// <summary>The main form instance, created by the project file.</summary>
  glTFMainForm: TglTFMainForm;

implementation

{$R *.fmx}

uses
  System.StrUtils, System.Math, System.JSON,
  System.NetEncoding, System.Threading,
  System.SyncObjs,
  glTF.Edit, glTF.AnimationSplit, glTF.Orient,
  glTFViewer.Split, glTFViewer.Tree, glTFViewer.Missing, glTFViewer.Dialogs;

type
  // Example of mapping an extension onto your own class (see DumpDocument)
  TEmissiveStrength = class
  private
    FEmissiveStrength: Double;
  public
    property EmissiveStrength: Double read FEmissiveStrength write FEmissiveStrength;
  end;

const
  EMISSIVE_STRENGTH = 'KHR_materials_emissive_strength';

  // Most nodes and accessors listed on the Output tab after a load
  DUMP_MAX = 100;

function FloatText(AValue: Double): string;
begin
  Result := FloatToStr(AValue, TFormatSettings.Invariant);
end;

{ TglTFMainForm }

procedure TglTFMainForm.FormCreate(Sender: TObject);
var
  LFileName, LParam: string;
  LSelfTest: Boolean;
  I: Integer;
begin
  FDoc := TglTFDocument.Create;

  // Fixed-width font so the output lines up
  memOutput.StyledSettings := memOutput.StyledSettings - [TStyledSetting.Family];
{$IF DEFINED(MSWINDOWS)}
  memOutput.TextSettings.Font.Family := 'Consolas';
{$ELSEIF DEFINED(MACOS)}
  memOutput.TextSettings.Font.Family := 'Menlo';
{$ELSE}
  memOutput.TextSettings.Font.Family := 'monospace';
{$ENDIF}

  FImages := TglTFImagesPanel.Create(Self);
  FImages.Parent := tabImages;
  FImages.Align := TAlignLayout.Client;
  FImages.OnLocateMissing := ImagesLocateMissing;

  FAnimations := TglTFAnimationsPanel.Create(Self);
  FAnimations.Parent := tabAnimations;
  FAnimations.Align := TAlignLayout.Client;
  FAnimations.OnImport := AnimationsImport;
  FAnimations.OnClear := AnimationsClear;
  FAnimations.OnSplit := AnimationsSplit;

  FPartLibrary := TglTFPartLibrary.Create;
  FPartApplier := TglTFPartApplier.Create(FDoc);
  FParts := TglTFPartsPanel.Create(Self);
  FParts.Parent := tabParts;
  FParts.Align := TAlignLayout.Client;
  FParts.PartLibrary := FPartLibrary;
  FParts.OnAddFiles := PartsAddFiles;
  FParts.OnClearList := PartsClearList;
  FParts.OnApply := PartsApply;
  FParts.OnRemove := PartsRemove;

  FOrient := TglTFOrientPanel.Create(Self);
  FOrient.Parent := tabOrient;
  FOrient.Align := TAlignLayout.Client;
  FParts.OnRefreshModel := PartsRefreshModel;
  FParts.Bind(FDoc, FPartApplier);

  // Shown over everything while a model loads or animations are imported
  FProgress := TProgressOverlay.Create(Self);
  FProgress.Parent := Self;
  // The duplicate question, over the progress box while an import waits
  FDuplicates := TDuplicatePanel.Create(Self);
  FDuplicates.Parent := Self;
  OnCloseQuery := FormCloseQuery;

  TabControl.ActiveTab := tabStructure;
  TglTFTreeBuilder.ShowMessage(tvStructure, 'No glTF file loaded - use "Open..."');

  // Command line: [file.gltf] [--selftest]
  LFileName := '';
  LSelfTest := False;
  for I := 1 to ParamCount do
  begin
    LParam := ParamStr(I);
    if SameText(LParam, '--selftest') or SameText(LParam, '-selftest') or
       SameText(LParam, '/selftest') then
      LSelfTest := True
    else
      LFileName := LParam;
  end;

  // Loading runs in the background, so the self-tests wait for it to finish
  if LFileName <> '' then
  begin
    FSelfTestAfterLoad := LSelfTest;
    LoadFile(LFileName);
  end
  else
  begin
    Log('Use "Open..." to load a .gltf file.');
    if LSelfTest then
      RunSelfTests;
  end;
end;

procedure TglTFMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // The background work uses the document and reports to this form, so the
  // form must outlive it. Instead of refusing, the close is put off: an
  // import is asked to stop (a duplicate question waiting for an answer is
  // answered with Abort) and a load runs to its end; EndWork then closes
  CanClose := not FBusy;
  if CanClose or FCloseRequested then
    Exit;
  FCloseRequested := True;
  FDuplicates.Cancel;
  if FProgress.Abort then
    Log('Closing: the import stops after the animation being added')
  else
    Log('Closing once the model has loaded');
end;

procedure TglTFMainForm.BeginWork(const ATitle: string; const AOnAbort: TProc);
begin
  FBusy := True;
  btnOpen.Enabled := False;
  btnSave.Enabled := False;
  btnSelfTest.Enabled := False;
  // The progress box takes the mouse and touch input, not the keyboard: a
  // focused checkbox or button on a tab would still change the document
  // (Space on an Export tick, Enter on "Export all") while the import thread
  // changes it too. So the tabs are disabled and lose the focus
  Focused := nil;
  TabControl.Enabled := False;
  FProgress.Start(ATitle, AOnAbort);
end;

procedure TglTFMainForm.EndWork;
begin
  FProgress.Finish;
  FBusy := False;
  TabControl.Enabled := True;
  btnOpen.Enabled := True;
  btnSave.Enabled := FDoc.FileFormat <> gffNone;
  btnSelfTest.Enabled := True;

  // Closed during the work: close now, after the caller has finished. The
  // task has queued its last call (the caller), so nothing more arrives
  if FCloseRequested then
    TThread.ForceQueue(nil,
      procedure
      begin
        Close;
      end);
end;

procedure TglTFMainForm.WorkProgress(Sender: TObject; const AProgress: TglTFProgress);
var
  LProgress: TglTFProgress;
begin
  // Reported on the worker thread: the display is updated on the main thread
  // (Queue runs it at once when already there)
  LProgress := AProgress;
  TThread.Queue(nil,
    procedure
    begin
      FProgress.ShowProgress(LProgress);
    end);
end;

procedure TglTFMainForm.FormDestroy(Sender: TObject);
begin
  // The panel is freed later, with the form: it lets go of these first
  FParts.Bind(nil, nil);
  FParts.PartLibrary := nil;
  FPartApplier.Free;
  FPartLibrary.Free;
  FDoc.Free;
end;

function TglTFMainForm.StartFolder: string;
begin
  // The loaded file's folder, else the platform default (on iOS and Android
  // the app's documents folder)
  Result := FDoc.BaseDirectory;
  if (Result = '') or not TDirectory.Exists(Result) then
    Result := TPlatformDialogs.DefaultFolder;
end;

procedure TglTFMainForm.btnOpenClick(Sender: TObject);
begin
  if FBusy then
    Exit;
  TPlatformDialogs.OpenFile('Open glTF file',
    [TFileType.Create('glTF files', ['.gltf', '.glb']),
     TFileType.Create('glTF JSON', ['.gltf']),
     TFileType.Create('Binary glTF', ['.glb']),
     TFileType.Create('All files', ['*'])],
    StartFolder, '',
    procedure(AFileName: string)
    begin
      if AFileName <> '' then
        LoadFile(AFileName);
    end);
end;

procedure TglTFMainForm.btnSaveClick(Sender: TObject);
var
  LUsed: TArray<Boolean>;
  LItem: TglTFMissingResource;
  LMissing: Integer;
begin
  if FBusy then
    Exit;
  // Missing media can still be located now; otherwise it is saved as a uri
  // reference only. Images no mesh shows are left out of the save, so their
  // files do not count. Each step continues in a callback, as dialogs do not
  // block on every platform
  LUsed := TglTFEdit.ImagesInUse(FDoc.Root);
  LMissing := 0;
  for LItem in FDoc.MissingResources do
    if (LItem.Kind = rkBuffer) or ((LItem.Index < Length(LUsed)) and LUsed[LItem.Index]) then
      Inc(LMissing);
  if LMissing > 0 then
    LocateMissingFiles(Format('%d media file(s) are still missing and would be saved as ' +
      'references only.', [LMissing]), ChooseSaveFile)
  else
    ChooseSaveFile;
end;

procedure TglTFMainForm.ChooseSaveFile;
const
  TYPE_GLB = 0;
  TYPE_GLTF = 1;
var
  LType: Integer;
begin
  // GLB by default, whatever was loaded: one self-contained file; the
  // loaded file's name (without extension) is suggested
  LType := TYPE_GLB;

  TPlatformDialogs.SaveFile('Save glTF file',
    [TFileType.Create('Binary glTF', ['.glb']), TFileType.Create('glTF JSON', ['.gltf'])],
    LType, StartFolder, TPath.GetFileNameWithoutExtension(FDoc.FileName),
    procedure(AFileName: string; ATypeIndex: Integer)
    var
      LFileName, LExt: string;
    begin
      if AFileName = '' then
        Exit;

      // The format chosen in the dialog decides the extension, whatever was typed
      if ATypeIndex = TYPE_GLB then
        LExt := '.glb'
      else
        LExt := '.gltf';
      LFileName := AFileName;
      if TglTFDocument.FormatFromFileName(LFileName) <> gffNone then
        LFileName := ChangeFileExt(LFileName, LExt)   // replace .gltf/.glb
      else if not LFileName.EndsWith(LExt, True) then
        LFileName := LFileName + LExt;                // keep e.g. "model.v2"

      if not TFile.Exists(LFileName) then
        SaveAs(LFileName)
      else
        TPlatformDialogs.Confirm(Format('%s already exists.' + sLineBreak +
          'Do you want to replace it?', [ExtractFileName(LFileName)]),
          procedure(AConfirmed: Boolean)
          begin
            if AConfirmed then
              SaveAs(LFileName);
          end);
    end);
end;

procedure TglTFMainForm.SaveAs(const AFileName: string);
var
  LWarning: string;
  LOptions: TglTFSaveOptions;
  LImage: TglTFImage;
  LAnimation: TglTFAnimation;
  LUsed: TArray<Boolean>;
  LEmbedded, LExported, LSaved, I: Integer;
  LGLB: Boolean;
begin
  // Reached from a dialog callback: check again
  if FBusy then
    Exit;
  // Only the images a mesh shows are saved (LeaveOutUnusedImages). The
  // format decides where they go, a GLB inside it, a glTF as separate files,
  // unless "Alter image save mode" is ticked on the Images tab
  LOptions := TglTFSaveOptions.Default;
  if FImages.AlterSaveMode then
    LOptions.ImageSaveMode := ismPerImage;
  // The turn on the Re-Orient tab; nothing is saved while it is not valid
  if not FOrient.GetAngles(LOptions.RotateX, LOptions.RotateY, LOptions.RotateZ) then
  begin
    TabControl.ActiveTab := tabOrient;
    Log;
    Log('Not saved: the angles on the Re-Orient tab must be numbers from -360 to 360');
    Exit;
  end;
  LGLB := TglTFDocument.FormatFromFileName(AFileName) = gffGLB;
  LEmbedded := 0;
  LExported := 0;
  LSaved := 0;
  for LAnimation in FDoc.Root.Animations do
    if LAnimation.ExportOnSave then
      Inc(LExported);
  LUsed := TglTFEdit.ImagesInUse(FDoc.Root);
  for I := 0 to FDoc.Root.Images.Count - 1 do
  begin
    if not LUsed[I] then
      Continue;
    Inc(LSaved);
    LImage := FDoc.Root.Images[I];
    if LOptions.ImageSaveMode = ismPerImage then
    begin
      if LImage.Embed then
        Inc(LEmbedded);
    end
    else if LGLB then
      Inc(LEmbedded);
  end;

  TabControl.ActiveTab := tabOutput;
  Log;
  Log('Saving %s', [AFileName]);
  if FDoc.Root.Images.Count > 0 then
  begin
    if LOptions.ImageSaveMode = ismPerImage then
      Log('Images: %d embedded, %d as separate files, as chosen on the Images tab',
        [LEmbedded, LSaved - LEmbedded])
    else
      Log('Images: %d embedded, %d as separate files (%s)', [LEmbedded, LSaved - LEmbedded,
        System.StrUtils.IfThen(LGLB, 'a GLB holds its images', 'a glTF refers to image files')]);
    if LSaved < FDoc.Root.Images.Count then
      Log('Images: %d no mesh shows are left out', [FDoc.Root.Images.Count - LSaved]);
  end;
  if FDoc.Root.Animations.Count > 0 then
    Log('Animations: %d of %d saved (see the Animations tab)',
      [LExported, FDoc.Root.Animations.Count]);
  if not TglTFReorienter.IsIdentity(LOptions.RotateX, LOptions.RotateY, LOptions.RotateZ) then
    Log('Re-oriented: turned by X %s, Y %s, Z %s degrees (see the Re-Orient tab)',
      [FloatText(LOptions.RotateX), FloatText(LOptions.RotateY), FloatText(LOptions.RotateZ)]);
  try
    FDoc.SaveToFile(AFileName, LOptions);
  except
    on E: Exception do
    begin
      Log('ERROR: %s', [E.Message]);
      Exit;
    end;
  end;

  if TglTFDocument.FormatFromFileName(AFileName) = gffGLB then
    Log('Saved as GLB, %d bytes', [TFile.GetSize(AFileName)])
  else
    Log('Saved as glTF JSON, %d bytes', [TFile.GetSize(AFileName)]);
  for LWarning in FDoc.SavedFiles do
    Log('  %s', [LWarning]);
  for LWarning in FDoc.SaveWarnings do
    Log('Warning: %s', [LWarning]);
  if FDoc.SaveComplete then
    Log('The saved file is file-complete: everything it refers to is next to it')
  else
    Log('Warning: the saved file is NOT file-complete (see the warnings above)');
end;

procedure TglTFMainForm.ImagesLocateMissing(Sender: TObject);
begin
  LocateMissingFiles(Format('%d media file(s) could not be found.',
    [Length(FDoc.MissingResources)]));
end;

procedure TglTFMainForm.LocateMissingFiles(const AContext: string; const ADone: TProc);
begin
  // The missing files form changes the document
  if FBusy or FCloseRequested then
    Exit;
  TMissingFilesForm.Execute(FDoc, AContext,
    procedure(AText: string)
    begin
      Log(AText);
    end,
    procedure(ARemaining: Integer)
    begin
      if ARemaining > 0 then
        Log('Warning: %d media file(s) still missing', [ARemaining]);
      FImages.RefreshList;
      if Assigned(ADone) then
        ADone;
    end);
end;

procedure TglTFMainForm.AnimationsImport(Sender: TObject);
begin
  if FBusy then
    Exit;
  TPlatformDialogs.OpenFiles('Import animations',
    [TFileType.Create('glTF files', ['.gltf', '.glb']),
     TFileType.Create('All files', ['*'])],
    StartFolder,
    procedure(AFiles: TArray<string>)
    begin
      if Length(AFiles) > 0 then
        ImportAnimationFiles(AFiles);
    end);
end;

procedure TglTFMainForm.ImportAnimationFiles(const AFiles: TArray<string>);
var
  LImporter: TglTFAnimationImporter;
begin
  if FBusy then
    Exit;
  Log;
  Log('Importing animations from %d file(s) into %s', [Length(AFiles),
    ExtractFileName(FDoc.FileName)]);

  // One background task loads each file and adds its animations one at a
  // time; the form stays responsive. Abort stops after the animation being
  // added, and what was added stays
  FDuplicateForAll := False;
  LImporter := TglTFAnimationImporter.Create(FDoc);
  LImporter.OnProgress := WorkProgress;
  LImporter.OnDuplicate := AskDuplicate;
  BeginWork('Importing animations',
    procedure
    begin
      LImporter.RequestAbort;
    end);
  TTask.Run(
    procedure
    var
      LError: string;
    begin
      LError := '';
      try
        LImporter.ImportFiles(AFiles);
      except
        on E: Exception do
          LError := E.Message;
      end;
      TThread.Queue(nil,
        procedure
        begin
          ImportFinished(LImporter, LError);
        end);
    end);
end;

procedure TglTFMainForm.AskDuplicate(AImporter: TglTFAnimationImporter;
  ACandidate: TglTFAnimationCandidate; AExisting: Integer;
  var AAction: TglTFDuplicateAction; var ANewName: string);
var
  LEvent: TEvent;
  LChoice: TDuplicateChoice;
  LMessage, LSuggested, LOrigin: string;
begin
  // Runs on the import thread, which waits here while the question is shown
  // on the main thread; the main thread itself never waits.
  //
  // Abort pressed (or the form closed) before this duplicate came up: no
  // question, the import stops here
  if AImporter.AbortRequested then
  begin
    AAction := daAbort;
    Exit;
  end;

  // FDuplicateForAll and FDuplicateAction are used by the import thread
  // only (reset on the main thread before the task starts)
  if FDuplicateForAll then
  begin
    AAction := FDuplicateAction; // renamed ones keep the suggested ANewName
    Exit;
  end;

  LOrigin := FDoc.Root.Animations[AExisting].Origin;
  if LOrigin = '' then
    LOrigin := 'the model'
  else
    LOrigin := 'imported from ' + LOrigin;
  LMessage := Format('%s has the same name as animation %d "%s" (%s).',
    [ACandidate.Description, AExisting, FDoc.Root.Animations[AExisting].Name, LOrigin]);
  LSuggested := ANewName;
  LChoice.Action := daAbort;

  LEvent := TEvent.Create(nil, True, False, '');
  try
    TThread.Queue(nil,
      procedure
      begin
        // Abort pressed, or the form closed, while this was queued: answer
        // at once rather than ask
        if FCloseRequested or AImporter.AbortRequested then
        begin
          LChoice.Action := daAbort;
          LEvent.SetEvent;
          Exit;
        end;
        FDuplicates.Ask(LMessage, LSuggested,
          function(AName: string): string
          begin
            // Safe: the import thread is waiting
            Result := AImporter.NameProblem(AName);
          end,
          procedure(AChoice: TDuplicateChoice)
          begin
            // Written before SetEvent and read after WaitFor: the event
            // orders the two threads' memory accesses
            LChoice := AChoice;
            LEvent.SetEvent;
          end);
      end);
    // Without a time limit: an answer always comes, as the form cannot close
    // before the import ends (FormCloseQuery answers a shown question with
    // Abort, and the check above one that is still queued)
    LEvent.WaitFor(INFINITE);
  finally
    LEvent.Free;
  end;

  AAction := LChoice.Action;
  if LChoice.Action = daRename then
    ANewName := LChoice.NewName;
  if LChoice.ForAll and (LChoice.Action <> daAbort) then
  begin
    FDuplicateForAll := True;
    FDuplicateAction := LChoice.Action;
  end;
end;

procedure TglTFMainForm.ImportFinished(AImporter: TglTFAnimationImporter; const AError: string);
var
  LLine: string;
begin
  EndWork;
  for LLine in AImporter.Log do
    Log('  %s', [LLine]);
  if AError <> '' then
    Log('ERROR: %s', [AError]);
  if AImporter.AbortRequested then
    Log('Import aborted: %d animation(s) were added before it stopped and stay in the model',
      [AImporter.ImportedCount])
  else
    Log('%d animation(s) imported', [AImporter.ImportedCount]);
  Log('The model now has %d animation(s)', [FDoc.Root.Animations.Count]);
  LogLongAnimationHint;
  AImporter.Free;

  TglTFTreeBuilder.Build(tvStructure, FDoc);
  FAnimations.RefreshList;
  TabControl.ActiveTab := tabAnimations;
end;

procedure TglTFMainForm.LogLongAnimationHint;
var
  LIndex: Integer;
begin
  LIndex := TglTFAnimationSplitter.FindLongAnimation(FDoc.Root);
  if LIndex >= 0 then
    Log('Animation %d "%s" is %.1f seconds long and may be several animations joined ' +
      'together: "Split long animation..." on the Animations tab cuts it into frame ranges',
      [LIndex, FDoc.Root.Animations[LIndex].Name,
       TglTFAnimationSplitter.Duration(FDoc.Root, FDoc.Root.Animations[LIndex])]);
end;

procedure TglTFMainForm.AnimationsSplit(Sender: TObject);
var
  LIndex: Integer;
  LName: string;
begin
  if FBusy then
    Exit;
  LIndex := TglTFAnimationSplitter.FindLongAnimation(FDoc.Root);
  if LIndex < 0 then
    Exit;
  LName := FDoc.Root.Animations[LIndex].Name;
  TSplitAnimationForm.Execute(FDoc.Root, LIndex, StartFolder,
    procedure(const ARanges: TglTFAnimationRanges; AFrameRate: Double)
    var
      LWarnings: TStringList;
      LWarning: string;
      LCount: Integer;
    begin
      LWarnings := TStringList.Create;
      try
        try
          LCount := TglTFAnimationSplitter.Split(FDoc.Root, LIndex, AFrameRate, ARanges,
            LWarnings);
          Log;
          Log('Split "%s" into %d animation(s) at %s frames per second', [LName, LCount,
            FloatToStr(AFrameRate, TFormatSettings.Invariant)]);
          for LWarning in LWarnings do
            Log('Warning: %s', [LWarning]);
        except
          on E: Exception do
            Log('ERROR: could not split "%s": %s', [LName, E.Message]);
        end;
      finally
        LWarnings.Free;
      end;
      TglTFTreeBuilder.Build(tvStructure, FDoc);
      FAnimations.RefreshList;
    end);
end;

procedure TglTFMainForm.AnimationsClear(Sender: TObject);
begin
  if FBusy or (FDoc.Root.Animations.Count = 0) then
    Exit;
  TPlatformDialogs.Confirm(Format('Remove all %d animation(s) from the model?' + sLineBreak +
    'Data used only by them is removed too.', [FDoc.Root.Animations.Count]),
    procedure(AConfirmed: Boolean)
    var
      LWarnings: TStringList;
      LWarning: string;
      LCount: Integer;
    begin
      // Reached from a dialog callback: check again
      if not AConfirmed or FBusy then
        Exit;
      LWarnings := TStringList.Create;
      try
        LCount := TglTFEdit.ClearAnimations(FDoc.Root, LWarnings);
        Log;
        Log('Cleared %d animation(s)', [LCount]);
        for LWarning in LWarnings do
          Log('Warning: %s', [LWarning]);
      finally
        LWarnings.Free;
      end;
      TglTFTreeBuilder.Build(tvStructure, FDoc);
      FAnimations.RefreshList;
    end);
end;

procedure TglTFMainForm.PartsAddFiles(Sender: TObject);
begin
  if FBusy then
    Exit;
  TPlatformDialogs.OpenFiles('Add part files',
    [TFileType.Create('glTF files', ['.gltf', '.glb']),
     TFileType.Create('All files', ['*'])],
    StartFolder,
    procedure(AFiles: TArray<string>)
    begin
      if Length(AFiles) > 0 then
        PartsLoadFiles(AFiles);
    end);
end;

procedure TglTFMainForm.PartsLoadFiles(const AFiles: TArray<string>);
begin
  if FBusy then
    Exit;
  Log;
  Log('Loading %d part file(s)', [Length(AFiles)]);

  // The library is only read by the panel, which takes no input meanwhile
  FPartLibrary.OnProgress := WorkProgress;
  BeginWork('Loading part files',
    procedure
    begin
      FPartLibrary.RequestAbort;
    end);
  TTask.Run(
    procedure
    var
      LError: string;
      LCount: Integer;
    begin
      LError := '';
      LCount := 0;
      try
        LCount := FPartLibrary.LoadFiles(AFiles);
      except
        on E: Exception do
          LError := E.Message;
      end;
      TThread.Queue(nil,
        procedure
        begin
          PartsLoadFinished(LCount, LError);
        end);
    end);
end;

procedure TglTFMainForm.PartsLoadFinished(ACount: Integer; const AError: string);
var
  LLine: string;
begin
  FPartLibrary.OnProgress := nil;
  EndWork;
  for LLine in FPartLibrary.Log do
    Log('  %s', [LLine]);
  if AError <> '' then
    Log('ERROR: %s', [AError]);
  Log('%d part(s) added; %d in the list', [ACount, FPartLibrary.Count]);
  FParts.RefreshList;
  TabControl.ActiveTab := tabParts;
end;

procedure TglTFMainForm.PartsClearList(Sender: TObject);
begin
  if FBusy then
    Exit;
  // Parts already on the model stay: they were copied into it
  FPartLibrary.Clear;
  FParts.RefreshList;
end;

procedure TglTFMainForm.PartsApply(Sender: TObject);
var
  LParts: TArray<TglTFPart>;
  LOptions: TglTFPartOptions;
  LApplier: TglTFPartApplier;
begin
  if FBusy then
    Exit;
  LParts := FParts.TickedParts;
  if Length(LParts) = 0 then
    Exit;
  LOptions := FParts.Options;
  LApplier := FPartApplier;
  TabControl.ActiveTab := tabOutput;
  Log;
  Log('Putting %d part(s) on %s', [Length(LParts), ExtractFileName(FDoc.FileName)]);

  // One background task puts the parts on in turn; Abort stops after the
  // part being put on, and the model is left consistent
  LApplier.OnProgress := WorkProgress;
  BeginWork('Putting on parts',
    procedure
    begin
      LApplier.RequestAbort;
    end);
  TTask.Run(
    procedure
    var
      LError: string;
      LCount: Integer;
    begin
      LError := '';
      LCount := 0;
      try
        LCount := LApplier.Apply(LParts, LOptions);
      except
        on E: Exception do
          LError := E.Message;
      end;
      TThread.Queue(nil,
        procedure
        begin
          PartsApplyFinished(LCount, LError);
        end);
    end);
end;

procedure TglTFMainForm.PartsApplyFinished(ACount: Integer; const AError: string);
begin
  FPartApplier.OnProgress := nil;
  EndWork;
  LogPartChanges;
  if AError <> '' then
    Log('ERROR: %s', [AError]);
  if FPartApplier.AbortRequested then
    Log('Aborted: %d part(s) were put on before it stopped and stay on the model', [ACount])
  else
    Log('%d part(s) put on', [ACount]);
  FParts.UntickParts;
  ModelChanged;
  TabControl.ActiveTab := tabParts;
end;

procedure TglTFMainForm.PartsRemove(Sender: TObject);
var
  LNodes: TArray<Integer>;
  LCount: Integer;
begin
  if FBusy then
    Exit;
  LNodes := FParts.TickedApplied;
  if Length(LNodes) = 0 then
    Exit;
  // Quick enough for the main thread: nothing is loaded or copied
  Log;
  Log('Taking %d part(s) off', [Length(LNodes)]);
  try
    LCount := FPartApplier.Remove(LNodes, FParts.Options);
    LogPartChanges;
    Log('%d part(s) taken off', [LCount]);
  except
    on E: Exception do
    begin
      LogPartChanges;
      Log('ERROR: %s', [E.Message]);
    end;
  end;
  ModelChanged;
end;

procedure TglTFMainForm.PartsRefreshModel(Sender: TObject);
begin
  if FBusy then
    Exit;
  Log;
  Log('Hiding the body under the parts again with the new settings');
  try
    FPartApplier.Refresh(FParts.Options);
    LogPartChanges;
  except
    on E: Exception do
    begin
      LogPartChanges;
      Log('ERROR: %s', [E.Message]);
    end;
  end;
  ModelChanged;
end;

procedure TglTFMainForm.LogPartChanges;
var
  LLine: string;
begin
  for LLine in FPartApplier.Log do
    Log('  %s', [LLine]);
end;

procedure TglTFMainForm.ModelChanged;
begin
  // Parts bring and take away nodes, meshes, materials and images
  TglTFTreeBuilder.Build(tvStructure, FDoc);
  FImages.RefreshList;
  FAnimations.RefreshList;
  FParts.RefreshList;
  if FDoc.HasMissingResources then
    Log('Warning: %d media file(s) are missing; see the Images tab',
      [Length(FDoc.MissingResources)]);
end;

procedure TglTFMainForm.btnSelfTestClick(Sender: TObject);
begin
  if FBusy then
    Exit;
  TabControl.ActiveTab := tabOutput;
  RunSelfTests;
end;

procedure TglTFMainForm.Log(const AText: string);
begin
  memOutput.Lines.Add(AText);
  memOutput.GoToTextEnd;
end;

procedure TglTFMainForm.Log(const AFormat: string; const AArgs: array of const);
begin
  Log(Format(AFormat, AArgs));
end;

procedure TglTFMainForm.LoadFile(const AFileName: string);
var
  LDoc: TglTFDocument;
begin
  if FBusy then
    Exit;
  memOutput.Lines.Clear;
  Log('Loading %s', [TPath.GetFullPath(AFileName)]);

  // Loaded into a new document in the background, with progress shown; it
  // replaces the current one only when the load succeeds
  BeginWork('Loading model');
  LDoc := TglTFDocument.Create;
  LDoc.OnProgress := WorkProgress;
  TTask.Run(
    procedure
    var
      LError, LErrorClass: string;
      LIsglTFError: Boolean;
    begin
      LError := '';
      LErrorClass := '';
      LIsglTFError := False;
      try
        LDoc.LoadFromFile(AFileName);
      except
        on E: Exception do
        begin
          LError := E.Message;
          LErrorClass := E.ClassName;
          LIsglTFError := E is EglTFError;
        end;
      end;
      TThread.Queue(nil,
        procedure
        begin
          LoadFinished(LDoc, AFileName, LError, LErrorClass, LIsglTFError);
        end);
    end);
end;

procedure TglTFMainForm.LoadFinished(ADoc: TglTFDocument; const AFileName, AError,
  AErrorClass: string; AIsglTFError: Boolean);
var
  LWarning: string;
begin
  ADoc.OnProgress := nil;
  if AError <> '' then
  begin
    ADoc.Free;
    EndWork;
    Log;
    if AIsglTFError then
      Log('ERROR: %s', [AError])
    else
      Log('ERROR (%s): %s', [AErrorClass, AError]);
    lblFile.Text := ExtractFileName(AFileName) + ' - failed to load';
    TglTFTreeBuilder.ShowMessage(tvStructure, 'Load failed: ' + AError);
    TabControl.ActiveTab := tabOutput;
  end
  else
  begin
    // The panels let go of the old document before it is freed. The
    // applier remembers the old body's triangles, so a new one is made
    FImages.Bind(nil);
    FAnimations.Bind(nil);
    FParts.Bind(nil, nil);
    FreeAndNil(FPartApplier);
    FDoc.Free;
    FDoc := ADoc;
    FPartApplier := TglTFPartApplier.Create(FDoc);
    EndWork;

    lblFile.Text := FDoc.FileName;
    Log('Loaded OK');
    for LWarning in FDoc.Warnings do
      Log('Warning: %s', [LWarning]);
    if FDoc.FileFormat = gffGLB then
    begin
      Log('Format: GLB (binary glTF), JSON chunk %d bytes', [FDoc.JSONChunkLength]);
      if FDoc.HasBinaryChunk then
        Log('BIN chunk: %d bytes', [FDoc.BinaryChunkLength])
      else
        Log('BIN chunk: none');
    end
    else
      Log('Format: glTF JSON');
    Log('%d animation(s) (see the Animations tab)', [FDoc.Root.Animations.Count]);
    LogLongAnimationHint;
    Log;
    DumpDocument;
    TglTFTreeBuilder.Build(tvStructure, FDoc);
    TabControl.ActiveTab := tabStructure;
    FImages.Bind(FDoc);
    FAnimations.Bind(FDoc);
    FParts.Bind(FDoc, FPartApplier);

    // Offer to locate missing media, once the form has settled (not when
    // the form is closing)
    if FDoc.HasMissingResources and not FCloseRequested then
      TThread.ForceQueue(nil,
        procedure
        begin
          LocateMissingFiles(Format('%d media file(s) referenced by %s could not be found.',
            [Length(FDoc.MissingResources), ExtractFileName(FDoc.FileName)]));
        end);
  end;

  // --selftest on the command line: run once the file is in
  if FSelfTestAfterLoad and not FCloseRequested then
  begin
    FSelfTestAfterLoad := False;
    TabControl.ActiveTab := tabOutput;
    RunSelfTests;
  end;
end;

procedure TglTFMainForm.DumpDocument;
var
  LRoot: TglTF;
  LNode: TglTFNode;
  LMaterial: TglTFMaterial;
  LAccessor: TglTFAccessor;
  LValue: Boolean;
  LStrength: Double;
  LExt: TEmissiveStrength;
  LName: string;
  I: Integer;
begin
  LRoot := FDoc.Root;
  memOutput.Lines.BeginUpdate;
  try
    Log('glTF %s generated by "%s"', [LRoot.Asset.Version, LRoot.Asset.Generator]);
    if LRoot.Asset.HasExtras then
      Log('Asset extras: %s', [LRoot.Asset.Extras.ToJSON]);

    Log('%d scene(s), %d node(s), %d mesh(es), %d material(s), %d texture(s), %d image(s)',
      [LRoot.Scenes.Count, LRoot.Nodes.Count, LRoot.Meshes.Count,
       LRoot.Materials.Count, LRoot.Textures.Count, LRoot.Images.Count]);
    if LRoot.IsDefined('scene') then
      Log('Default scene: %d', [LRoot.Scene])
    else
      Log('Default scene: (not defined)');
    for I := 0 to LRoot.Buffers.Count - 1 do
      if not LRoot.Buffers[I].IsDefined('uri') then
        Log('Buffer %d: %d bytes in the GLB BIN chunk', [I, LRoot.Buffers[I].ByteLength])
      else if LRoot.Buffers[I].IsDataUri then
        Log('Buffer %d: %d bytes in a data URI', [I, LRoot.Buffers[I].ByteLength])
      else
        Log('Buffer %d: %d bytes in %s', [I, LRoot.Buffers[I].ByteLength,
          FDoc.ResolveUri(LRoot.Buffers[I].Uri)]);
    for LName in LRoot.ExtensionsUsed do
      Log('Extension used: %s%s', [LName,
        System.StrUtils.IfThen(LRoot.IsExtensionRequired(LName), ' (required)', '')]);

    // Long lists are cut short: a memo line per accessor of a file full of
    // animations would only slow the load down
    Log;
    for I := 0 to LRoot.Nodes.Count - 1 do
    begin
      if I = DUMP_MAX then
      begin
        Log('... %d more node(s)', [LRoot.Nodes.Count - I]);
        Break;
      end;
      LNode := LRoot.Nodes[I];
      Log('Node %d "%s" mesh=%d translation=%s', [I, LNode.Name, LNode.Mesh,
        Format('(%s, %s, %s)', [FloatText(LNode.Translation[0]),
          FloatText(LNode.Translation[1]), FloatText(LNode.Translation[2])])]);
      // Extras: typed query by path
      if LNode.TryGetExtra<Boolean>('selectable', LValue) then
        Log('  extras.selectable: %s', [BoolToStr(LValue, True)]);
      for LName in LNode.ExtraNames do
        Log('  extras.%s = %s', [LName, LNode.FindExtra(LName).ToJSON]);
    end;

    Log;
    for I := 0 to LRoot.Accessors.Count - 1 do
    begin
      if I = DUMP_MAX then
      begin
        Log('... %d more accessor(s)', [LRoot.Accessors.Count - I]);
        Break;
      end;
      LAccessor := LRoot.Accessors[I];
      Log('Accessor %d: %s x%d, %d component(s) of %d byte(s), bufferView=%d',
        [I, LAccessor.&Type, LAccessor.Count, LAccessor.ComponentCount,
         LAccessor.ComponentByteSize, LAccessor.BufferView]);
    end;

    Log;
    for I := 0 to LRoot.Materials.Count - 1 do
    begin
      LMaterial := LRoot.Materials[I];
      Log('Material %d "%s" alphaMode=%s doubleSided=%s', [I, LMaterial.Name,
        LMaterial.AlphaMode, BoolToStr(LMaterial.DoubleSided, True)]);
      for LName in LMaterial.ExtensionNames do
        Log('  extension %s', [LName]);

      // Extensions: read one value by path...
      if LMaterial.TryGetExtensionValue<Double>(EMISSIVE_STRENGTH, 'emissiveStrength', LStrength) then
        Log('  emissiveStrength (by path): %s', [FloatText(LStrength)]);

      // ...or map the whole extension onto your own class
      LExt := LMaterial.ExtensionAs<TEmissiveStrength>(EMISSIVE_STRENGTH);
      try
        if Assigned(LExt) then
          Log('  emissiveStrength (by class): %s', [FloatText(LExt.EmissiveStrength)]);
      finally
        LExt.Free;
      end;
    end;

    if Assigned(LRoot.UnknownProperties) then
    begin
      Log;
      for I := 0 to LRoot.UnknownProperties.Count - 1 do
        Log('Non-standard root property "%s": %s',
          [LRoot.UnknownProperties.Pairs[I].JsonString.Value,
           LRoot.UnknownProperties.Pairs[I].JsonValue.ToJSON]);
    end;
  finally
    memOutput.Lines.EndUpdate;
  end;
  memOutput.GoToTextEnd;
end;

procedure TglTFMainForm.ExpectError(const ATitle: string; const ALines: array of string;
  AExpected: ExceptClass);
var
  LDoc: TglTFDocument;
  LText: string;
  I: Integer;
begin
  Log;
  Log('Self-test: %s', [ATitle]);
  LText := '';
  for I := 0 to High(ALines) do
  begin
    LText := LText + ALines[I] + sLineBreak;
    Log('  %3d | %s', [I + 1, ALines[I]]);
  end;

  // A separate document, so the loaded file is not affected
  LDoc := TglTFDocument.Create;
  try
    try
      LDoc.LoadFromString(LText);
      Log('  FAIL: the invalid asset was accepted');
    except
      on E: EglTFError do
        if E is AExpected then
        begin
          Log('  PASS: %s (line %d, column %d)', [E.ClassName, E.Line, E.Column]);
          Log('        %s', [E.Message]);
        end
        else
          Log('  FAIL: unexpected %s: %s', [E.ClassName, E.Message]);
    end;
  finally
    LDoc.Free;
  end;
end;

// <summary>
//   JSON written from the objects, without where the data is stored
//   (buffer/image uri and buffer byteLength), which legitimately changes
//   between formats. Data is compared separately
// </summary>
function ComparableJSON(ADoc: TglTFDocument; ABufferCount, AViewCount: Integer): string;
var
  LJSON: TJSONObject;

  procedure Truncate(const AArrayName: string; ACount: Integer);
  var
    LArray: TJSONArray;
  begin
    // Embedding images adds buffers / bufferViews at the end
    LArray := LJSON.GetValue(AArrayName) as TJSONArray;
    if LArray = nil then
      Exit;
    while LArray.Count > ACount do
      LArray.Remove(LArray.Count - 1).Free;
    if LArray.Count = 0 then
      LJSON.RemovePair(AArrayName).Free;
  end;

  procedure Strip(const AArrayName: string; const ANames: array of string);
  var
    LArray: TJSONArray;
    LName: string;
    I: Integer;
  begin
    LArray := LJSON.GetValue(AArrayName) as TJSONArray;
    if LArray = nil then
      Exit;
    for I := 0 to LArray.Count - 1 do
      for LName in ANames do
        (LArray.Items[I] as TJSONObject).RemovePair(LName).Free;
  end;

begin
  LJSON := ADoc.Root.SaveToJSON;
  try
    Truncate('buffers', ABufferCount);
    Truncate('bufferViews', AViewCount);
    Strip('buffers', ['uri', 'byteLength']);
    Strip('images', ['uri', 'bufferView', 'mimeType']);
    Result := LJSON.ToJSON;
  finally
    LJSON.Free;
  end;
end;

function SameBytes(const A, B: TBytes): Boolean;
begin
  Result := (Length(A) = Length(B)) and
    ((Length(A) = 0) or CompareMem(@A[0], @B[0], Length(A)));
end;

function FirstDifference(const A, B: string): string;
var
  I: Integer;
begin
  I := 1;
  while (I <= Length(A)) and (I <= Length(B)) and (A[I] = B[I]) do
    Inc(I);
  Result := Format('at character %d: "%s" vs "%s"',
    [I, Copy(A, Max(1, I - 30), 60), Copy(B, Max(1, I - 30), 60)]);
end;

procedure TglTFMainForm.RoundTripTest(AFormat: TglTFFileFormat);
var
  LFirst, LSecond: TMemoryStream;
  LCopy: TglTFDocument;
  LName, LExpected, LActual: string;
  LFailures: Integer;
  LExports: TArray<Boolean>;
  LOptions: TglTFSaveOptions;
  I: Integer;

  procedure Fail(const AText: string);
  begin
    Inc(LFailures);
    Log('  FAIL: %s', [AText]);
  end;

begin
  if AFormat = gffGLB then
    LName := 'GLB'
  else
    LName := 'glTF JSON';
  Log;
  Log('Self-test: round trip of the loaded document through %s', [LName]);

  LFailures := 0;
  // Everything is written, unused images included, so the objects can be
  // compared one for one (UnusedImagesTest covers leaving them out)
  LOptions := TglTFSaveOptions.Default;
  LOptions.LeaveOutUnusedImages := False;
  // Every animation takes part in the round trip; the Export choices are
  // restored afterwards
  SetLength(LExports, FDoc.Root.Animations.Count);
  for I := 0 to High(LExports) do
  begin
    LExports[I] := FDoc.Root.Animations[I].ExportOnSave;
    FDoc.Root.Animations[I].ExportOnSave := True;
  end;
  LFirst := TMemoryStream.Create;
  LSecond := TMemoryStream.Create;
  LCopy := TglTFDocument.Create;
  try
    try
      // 1. Write from the objects, read the result back
      FDoc.SaveToStream(LFirst, AFormat, LOptions);
      LFirst.Position := 0;
      LCopy.LoadFromStream(LFirst);
      Log('  written and re-read: %d bytes', [LFirst.Size]);

      // The embed choices are save settings, not glTF: carry them over so
      // the re-save below makes the same choices
      for I := 0 to Min(FDoc.Root.Images.Count, LCopy.Root.Images.Count) - 1 do
        LCopy.Root.Images[I].Embed := FDoc.Root.Images[I].Embed;

      // 2. Same objects? (where the data is stored may differ)
      LExpected := ComparableJSON(FDoc, FDoc.Root.Buffers.Count, FDoc.Root.BufferViews.Count);
      LActual := ComparableJSON(LCopy, FDoc.Root.Buffers.Count, FDoc.Root.BufferViews.Count);
      if LExpected <> LActual then
        Fail('object tree differs ' + FirstDifference(LExpected, LActual));

      // 3. Same data?
      if LCopy.Root.Buffers.Count < FDoc.Root.Buffers.Count then
        Fail('buffers are missing')
      else
        for I := 0 to FDoc.Root.Buffers.Count - 1 do
          // Embedded images may have been appended after the original bytes
          if not SameBytes(FDoc.Root.Buffers[I].Data,
             Copy(LCopy.Root.Buffers[I].Data, 0, Length(FDoc.Root.Buffers[I].Data))) then
            Fail(Format('buffer %d data differs (%d vs %d bytes)', [I,
              Length(FDoc.Root.Buffers[I].Data), Length(LCopy.Root.Buffers[I].Data)]));

      if LCopy.Root.Images.Count <> FDoc.Root.Images.Count then
        Fail('image count differs')
      else
        for I := 0 to FDoc.Root.Images.Count - 1 do
          if not SameBytes(FDoc.Root.Images[I].Data, LCopy.Root.Images[I].Data) then
            Fail(Format('image %d data differs', [I]));

      // 4. Stable? Writing the re-read document must give identical bytes
      LCopy.SaveToStream(LSecond, AFormat, LOptions);
      if (LFirst.Size <> LSecond.Size) or
         not CompareMem(LFirst.Memory, LSecond.Memory, LFirst.Size) then
        Fail('writing the re-read document gives different bytes');

      if LFailures = 0 then
        Log('  PASS: same objects, same buffer/image data, identical output on re-save');
    except
      on E: Exception do
        Fail(E.ClassName + ': ' + E.Message);
    end;
  finally
    LCopy.Free;
    LSecond.Free;
    LFirst.Free;
    for I := 0 to High(LExports) do
      FDoc.Root.Animations[I].ExportOnSave := LExports[I];
  end;
end;

// Bytes that differ from position to position, so a misplaced byte shows
function PatternBytes(ACount, ASeed: Integer): TBytes;
var
  I: Integer;
begin
  SetLength(Result, ACount);
  for I := 0 to ACount - 1 do
    Result[I] := Byte(I * 7 + ASeed);
end;

function PatternDataUri(ACount, ASeed: Integer): string;
var
  LEncoding: TBase64Encoding;
begin
  // No line breaks: a data URI is one line
  LEncoding := TBase64Encoding.Create(0);
  try
    Result := 'data:application/octet-stream;base64,' +
      LEncoding.EncodeBytesToString(PatternBytes(ACount, ASeed));
  finally
    LEncoding.Free;
  end;
end;

function FloatsDataUri(const AFloats: TArray<Single>): string;
var
  LBytes: TBytes;
  LEncoding: TBase64Encoding;
begin
  SetLength(LBytes, Length(AFloats) * SizeOf(Single));
  if Length(LBytes) > 0 then
    Move(AFloats[0], LBytes[0], Length(LBytes));
  LEncoding := TBase64Encoding.Create(0);
  try
    Result := 'data:application/octet-stream;base64,' + LEncoding.EncodeBytesToString(LBytes);
  finally
    LEncoding.Free;
  end;
end;

procedure TglTFMainForm.ReorientTest;
var
  LDoc, LCopy: TglTFDocument;
  LOptions: TglTFSaveOptions;
  LStream: TMemoryStream;
  LValues: TArray<Single>;
  LJSON: string;
  LFailures: Integer;

  procedure Check(ACondition: Boolean; const AText: string);
  begin
    if not ACondition then
    begin
      Inc(LFailures);
      Log('  FAIL: %s', [AText]);
    end;
  end;

  function Near(const AValues: TArray<Single>; AFirst: Integer;
    const AExpected: array of Double): Boolean;
  var
    I: Integer;
  begin
    Result := Length(AValues) >= AFirst + Length(AExpected);
    if Result then
      for I := 0 to High(AExpected) do
        if Abs(AValues[AFirst + I] - AExpected[I]) > 1e-5 then
          Exit(False);
  end;

  function NearArray(const AValues: TArray<Double>; const AExpected: array of Double): Boolean;
  var
    I: Integer;
  begin
    Result := Length(AValues) = Length(AExpected);
    if Result then
      for I := 0 to High(AExpected) do
        if Abs(AValues[I] - AExpected[I]) > 1e-6 then
          Exit(False);
  end;

begin
  Log;
  Log('Self-test: re-orienting a Z-up model to Y-up (X -90) when saving');

  // Root node "Root" at (1, 2, 3), animated along Z; its child shows a mesh
  // whose three points lie on the axes
  LJSON :=
    '{"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],' +
    '"nodes":[{"name":"Root","translation":[1,2,3],"children":[1]},{"mesh":0}],' +
    '"meshes":[{"primitives":[{"attributes":{"POSITION":0,"NORMAL":1}}]}],' +
    '"buffers":[{"byteLength":104,"uri":"' + FloatsDataUri([1, 0, 0, 0, 1, 0, 0, 0, 1,
      1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 5, 0, 0, 5]) + '"}],' +
    '"bufferViews":[{"buffer":0,"byteLength":36},{"buffer":0,"byteOffset":36,"byteLength":36},' +
    '{"buffer":0,"byteOffset":72,"byteLength":8},{"buffer":0,"byteOffset":80,"byteLength":24}],' +
    '"accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3",' +
      '"min":[0,0,0],"max":[1,1,1]},' +
    '{"bufferView":1,"componentType":5126,"count":3,"type":"VEC3"},' +
    '{"bufferView":2,"componentType":5126,"count":2,"type":"SCALAR","min":[0],"max":[1]},' +
    '{"bufferView":3,"componentType":5126,"count":2,"type":"VEC3"}],' +
    '"animations":[{"name":"Rise","channels":[{"sampler":0,"target":{"node":0,' +
      '"path":"translation"}}],"samplers":[{"input":2,"output":3}]}]}';

  LFailures := 0;
  LDoc := TglTFDocument.Create;
  LCopy := TglTFDocument.Create;
  LStream := TMemoryStream.Create;
  try
    try
      LDoc.LoadFromString(LJSON);
      Check(TglTFReorienter.IsIdentity(0, 360, 0), '360 degrees should be no turn');
      Check(not TglTFReorienter.IsIdentity(-90, 0, 0), '-90 degrees should be a turn');

      LOptions := TglTFSaveOptions.Default;
      LOptions.RotateX := -90;
      LDoc.SaveToStream(LStream, gffGLB, LOptions);
      LStream.Position := 0;
      LCopy.LoadFromStream(LStream);

      // X -90 takes (x, y, z) to (x, z, -y)
      Check(NearArray(LCopy.Root.Nodes[0].Translation, [1, 3, -2]),
        'the root node should move from (1, 2, 3) to (1, 3, -2)');
      Check(NearArray(LCopy.Root.Nodes[1].Rotation, [0, 0, 0, 1]),
        'the child node should keep no rotation of its own');
      LValues := TglTFAnimationSplitter.ReadAccessor(LCopy.Root, 0);
      Check(Near(LValues, 0, [1, 0, 0]) and Near(LValues, 3, [0, 0, -1]) and
        Near(LValues, 6, [0, 1, 0]), 'the positions should be turned');
      Check(NearArray(LCopy.Root.Accessors[0].Min, [0, 0, -1]) and
        NearArray(LCopy.Root.Accessors[0].Max, [1, 1, 0]), 'min and max should be recomputed');
      LValues := TglTFAnimationSplitter.ReadAccessor(LCopy.Root, 1);
      Check(Near(LValues, 6, [0, 1, 0]), 'the normals should be turned');
      LValues := TglTFAnimationSplitter.ReadAccessor(LCopy.Root, 3);
      Check(Near(LValues, 3, [0, 5, 0]), 'the animation should rise along Y now');

      // The loaded document is not changed by the save
      LValues := TglTFAnimationSplitter.ReadAccessor(LDoc.Root, 0);
      Check(Near(LValues, 6, [0, 0, 1]) and
        NearArray(LDoc.Root.Nodes[0].Translation, [1, 2, 3]), 'the document should not change');

      if LFailures = 0 then
        Log('  PASS: nodes, mesh data, min/max and animation turned; document unchanged');
    except
      on E: Exception do
        Check(False, E.ClassName + ': ' + E.Message);
    end;
  finally
    LStream.Free;
    LCopy.Free;
    LDoc.Free;
  end;
end;

procedure TglTFMainForm.AnimationSplitTest;
const
  KEYS = 25; // 0 to 12 seconds, every half second
var
  LDoc: TglTFDocument;
  LFloats, LTimes, LValues: TArray<Single>;
  LProblems: TArray<string>;
  LJSON: string;
  LFailures, I: Integer;
  LSaved: TMemoryStream;
  LList: TglTFRangeList;

  procedure Check(ACondition: Boolean; const AText: string);
  begin
    if not ACondition then
    begin
      Inc(LFailures);
      Log('  FAIL: %s', [AText]);
    end;
  end;

begin
  Log;
  Log('Self-test: splitting a 12-second animation into frame ranges');

  // "Take001" moves node 0 along x: x = time, so values are easy to check
  SetLength(LFloats, KEYS + KEYS * 3);
  for I := 0 to KEYS - 1 do
  begin
    LFloats[I] := I * 0.5;
    LFloats[KEYS + I * 3] := I * 0.5;
  end;
  LJSON :=
    '{"asset":{"version":"2.0"},"nodes":[{"name":"Hips"}],' +
    '"buffers":[{"byteLength":' + IntToStr(Length(LFloats) * 4) + ',"uri":"' +
      FloatsDataUri(LFloats) + '"}],' +
    '"bufferViews":[{"buffer":0,"byteLength":' + IntToStr(KEYS * 4) + '},' +
    '{"buffer":0,"byteOffset":' + IntToStr(KEYS * 4) + ',"byteLength":' + IntToStr(KEYS * 12) + '}],' +
    '"accessors":[{"bufferView":0,"componentType":5126,"count":' + IntToStr(KEYS) +
      ',"type":"SCALAR","min":[0],"max":[12]},' +
    '{"bufferView":1,"componentType":5126,"count":' + IntToStr(KEYS) + ',"type":"VEC3"}],' +
    '"animations":[{"name":"Take001","channels":[{"sampler":0,"target":{"node":0,' +
      '"path":"translation"}}],"samplers":[{"input":0,"output":1}]}]}';

  LFailures := 0;
  LDoc := TglTFDocument.Create;
  LSaved := TMemoryStream.Create;
  try
    try
      LDoc.LoadFromString(LJSON);
      Check(TglTFAnimationSplitter.FindLongAnimation(LDoc.Root) = 0,
        'Take001 should be found as a long animation');
      Check(SameValue(TglTFAnimationSplitter.DetectFrameRate(LDoc.Root,
        LDoc.Root.Animations[0]), 2), 'key frames every 0.5 s should give 2 frames per second');

      // At 10 frames per second the frames run 0..120. Duplicate names and
      // reversed ranges are refused
      TglTFAnimationSplitter.ValidateRanges(LDoc.Root, 0, 120,
        [TglTFAnimationRange.Create('a', 0, 10), TglTFAnimationRange.Create('A', 20, 10),
         TglTFAnimationRange.Create('b', 0, 121)], LProblems);
      Check((LProblems[0] = '') and (LProblems[1] <> '') and (LProblems[2] <> ''),
        'invalid ranges should be refused');

      // walk 0-40 (0-4 s), a gap, run 63-120 (6.3-12 s)
      Check(TglTFAnimationSplitter.Split(LDoc.Root, 0, 10,
        [TglTFAnimationRange.Create('walk', 0, 40, 'start'),
         TglTFAnimationRange.Create('run', 63, 120)], nil) = 2, 'two animations expected');
      Check((LDoc.Root.Animations.Count = 2) and (LDoc.Root.Animations[0].Name = 'walk') and
        (LDoc.Root.Animations[1].Name = 'run'), 'the parts should replace Take001, in order');
      Check(LDoc.Root.Animations[0].HasExtra('notes'), 'notes should be kept in the extras');

      // run: starts at x = 6.3, computed between the keys at 6.0 and 6.5,
      // and ends on the key at 12
      LTimes := TglTFAnimationSplitter.ReadAccessor(LDoc.Root,
        LDoc.Root.Animations[1].Samplers[0].Input);
      LValues := TglTFAnimationSplitter.ReadAccessor(LDoc.Root,
        LDoc.Root.Animations[1].Samplers[0].Output);
      Check((Length(LTimes) = 13) and SameValue(LTimes[0], 0) and
        SameValue(LTimes[High(LTimes)], 5.7, 1e-5), 'run should last 5.7 s with 13 keys');
      Check(SameValue(LValues[0], 6.3, 1e-5) and SameValue(LValues[High(LValues) - 2], 12, 1e-5),
        'run should go from x = 6.3 to x = 12');
      Check(LDoc.Root.Accessors.Count = 4, 'Take001''s own data should be removed');

      // Range lists as they come with animation files: the name after the
      // numbers or before them, a title and notes around, quotes removed
      Check(TglTFAnimationSplitter.ParseRangeList('Animation ranges' + sLineBreak + sLineBreak +
        '1 - 5  t-pose' + sLineBreak + '10 - 40  "walk_01"' + sLineBreak +
        '380 - 415  run_jump-360', LList) and (Length(LList.Ranges) = 3) and
        (LList.FirstLine = 3) and (LList.Ranges[1].Name = 'walk_01') and
        (LList.Ranges[2].Name = 'run_jump-360') and (LList.Ranges[2].StartFrame = 380) and
        (LList.Ranges[2].EndFrame = 415), 'a list with the names after the numbers');
      Check(TglTFAnimationSplitter.ParseRangeList('Walk In Place'#9#9'560'#9'-'#9'620 ' +
        '(repeated 3 times) 20 frame animation', LList) and
        (LList.Ranges[0].Name = 'Walk In Place') and (LList.Ranges[0].StartFrame = 560) and
        (LList.Ranges[0].EndFrame = 620), 'a list with the names before the numbers');
      Check(not TglTFAnimationSplitter.ParseRangeList('No ranges here' + sLineBreak +
        'IMPORTANT: none at all', LList), 'a text without ranges');

      // The result saves and loads
      LDoc.SaveToStream(LSaved, gffGLB);
      LSaved.Position := 0;
      LDoc.LoadFromStream(LSaved);
      Check(LDoc.Root.Animations.Count = 2, 'the split animations should survive a save');

      if LFailures = 0 then
        Log('  PASS: found, frame rate detected, ranges checked, split at and between keys, ' +
          'range lists read');
    except
      on E: Exception do
        Check(False, E.ClassName + ': ' + E.Message);
    end;
  finally
    LSaved.Free;
    LDoc.Free;
  end;
end;

procedure TglTFMainForm.AnimationImportTest;
const
  MODEL_SEED = 1;
  MOVES_SEED = 100;
var
  LModelJSON, LMovesJSON: string;
  LModel, LCopy, LFresh: TglTFDocument;
  LImporter: TglTFAnimationImporter;
  LOriginal, LSaved: TMemoryStream;
  LAccessor: TglTFAccessor;
  LView: TglTFBufferView;
  LFailures, LAdded, LAsked: Integer;
  LSuggested: string;

  procedure Check(ACondition: Boolean; const AText: string);
  begin
    if not ACondition then
    begin
      Inc(LFailures);
      Log('  FAIL: %s', [AText]);
    end;
  end;

  function SameStreams(A, B: TMemoryStream): Boolean;
  begin
    Result := (A.Size = B.Size) and CompareMem(A.Memory, B.Memory, A.Size);
  end;

  function NewMoves: TglTFDocument;
  begin
    Result := TglTFDocument.Create;
    try
      Result.LoadFromString(LMovesJSON);
    except
      Result.Free;
      raise;
    end;
  end;

begin
  Log;
  Log('Self-test: importing animations, then saving with and without them');

  // The model: Root > Arm, with a "Wave" animation on Arm (40 bytes of data)
  LModelJSON :=
    '{"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],' +
    '"nodes":[{"name":"Root","children":[1]},{"name":"Arm"}],' +
    '"buffers":[{"byteLength":40,"uri":"' + PatternDataUri(40, MODEL_SEED) + '"}],' +
    '"bufferViews":[{"buffer":0,"byteLength":8},{"buffer":0,"byteOffset":8,"byteLength":32}],' +
    '"accessors":[{"bufferView":0,"componentType":5126,"count":2,"type":"SCALAR","min":[0],"max":[1]},' +
    '{"bufferView":1,"componentType":5126,"count":2,"type":"VEC4"}],' +
    '"animations":[{"name":"Wave","channels":[{"sampler":0,"target":{"node":1,"path":"rotation"}}],' +
    '"samplers":[{"input":0,"output":1}]}]}';

  // An animation file with its own copy of the skeleton: "arm" (other case)
  // and "Leg", which the model does not have. "Wave" clashes with the model
  LMovesJSON :=
    '{"asset":{"version":"2.0"},"nodes":[{"name":"arm"},{"name":"Leg"}],' +
    '"buffers":[{"byteLength":64,"uri":"' + PatternDataUri(64, MOVES_SEED) + '"}],' +
    '"bufferViews":[{"buffer":0,"byteLength":8},{"buffer":0,"byteOffset":8,"byteLength":32},' +
    '{"buffer":0,"byteOffset":40,"byteLength":24}],' +
    '"accessors":[{"bufferView":0,"componentType":5126,"count":2,"type":"SCALAR","min":[0],"max":[2]},' +
    '{"bufferView":1,"componentType":5126,"count":2,"type":"VEC4"},' +
    '{"bufferView":2,"componentType":5126,"count":2,"type":"VEC3"}],' +
    '"animations":[' +
    '{"name":"Wave","channels":[{"sampler":0,"target":{"node":0,"path":"rotation"}},' +
    '{"sampler":1,"target":{"node":1,"path":"translation"}}],' +
    '"samplers":[{"input":0,"output":1},{"input":0,"output":2}]},' +
    '{"name":"Jump","channels":[{"sampler":0,"target":{"node":0,"path":"translation"}}],' +
    '"samplers":[{"input":0,"output":2}]}]}';

  LFailures := 0;
  LModel := TglTFDocument.Create;
  LCopy := TglTFDocument.Create;
  LOriginal := TMemoryStream.Create;
  LSaved := TMemoryStream.Create;
  try
    try
      LModel.LoadFromString(LModelJSON);
      LModel.SaveToStream(LOriginal, gffJSON);

      // 1. Import, renaming the duplicate. The duplicate handler answers
      //    directly: this import runs on the main thread
      LAsked := 0;
      LSuggested := '';
      LImporter := TglTFAnimationImporter.Create(LModel);
      try
        LImporter.OnDuplicate :=
          procedure(AImporter: TglTFAnimationImporter; ACandidate: TglTFAnimationCandidate;
            AExisting: Integer; var AAction: TglTFDuplicateAction; var ANewName: string)
          begin
            Inc(LAsked);
            LSuggested := ANewName;
            AAction := daRename;
          end;
        LAdded := LImporter.ImportDocument(NewMoves, 'moves.gltf');
        Check(LAdded = 2, Format('2 animations should be added, not %d', [LAdded]));
        Check(LAsked = 1, Format('one duplicate expected, not %d', [LAsked]));
        Check(LSuggested = 'Wave_2', 'suggested name should be Wave_2, not ' + LSuggested);
        Check((LImporter.Count = 2) and (LImporter[0].MatchedChannels = 1),
          '"Wave": only the arm channel should match');
        Check(LImporter.NameProblem('wave') <> '', '"wave" should be refused');
      finally
        LImporter.Free;
      end;

      Check(LModel.Root.Animations.Count = 3, 'the model should have 3 animations');
      if LModel.Root.Animations.Count = 3 then
      begin
        Check(LModel.Root.Animations[1].Name = 'Wave_2', 'animation 1 should be Wave_2');
        Check(LModel.Root.Animations[1].Channels.Count = 1, 'Wave_2 should have 1 channel');
        Check(LModel.Root.Animations[1].Channels[0].Target.Node = 1, 'Wave_2 should animate Arm');
        Check(LModel.Root.Animations[2].Origin = 'moves.gltf', 'Jump should come from moves.gltf');
        // The rotation keys, copied byte for byte
        LAccessor := LModel.Root.Accessors[LModel.Root.Animations[1].Samplers[0].Output];
        LView := LModel.Root.BufferViews[LAccessor.BufferView];
        Check(SameBytes(Copy(LModel.Root.Buffers[0].Data, Integer(LView.ByteOffset), 32),
          Copy(PatternBytes(64, MOVES_SEED), 8, 32)), 'the copied key frames differ');
      end;
      Check(LModel.Root.Accessors.Count = 5, 'shared key frame times should be copied once');

      // 2. None of the imported ones exported: the output is the original model
      LModel.Root.Animations[1].ExportOnSave := False;
      LModel.Root.Animations[2].ExportOnSave := False;
      LModel.SaveToStream(LSaved, gffJSON);
      Check(SameStreams(LOriginal, LSaved),
        'with the imported animations not exported, the output should equal the original');

      // 3. All exported: everything survives a GLB round trip
      LModel.Root.Animations[1].ExportOnSave := True;
      LModel.Root.Animations[2].ExportOnSave := True;
      LSaved.Clear;
      LModel.SaveToStream(LSaved, gffGLB);
      LSaved.Position := 0;
      LCopy.LoadFromStream(LSaved);
      Check((LCopy.Root.Animations.Count = 3) and (LCopy.Root.Accessors.Count = 5),
        'the GLB should hold all 3 animations');

      // 4. Import again: replace "Wave", keep the existing "Jump"
      LImporter := TglTFAnimationImporter.Create(LModel);
      try
        LImporter.OnDuplicate :=
          procedure(AImporter: TglTFAnimationImporter; ACandidate: TglTFAnimationCandidate;
            AExisting: Integer; var AAction: TglTFDuplicateAction; var ANewName: string)
          begin
            if SameText(ACandidate.Name, 'Wave') then
              AAction := daReplace
            else
              AAction := daKeep;
          end;
        LAdded := LImporter.ImportDocument(NewMoves, 'moves.gltf');
        Check(LAdded = 1, Format('1 animation should be replaced, not %d', [LAdded]));
      finally
        LImporter.Free;
      end;
      Check(LModel.Root.Animations.Count = 3, 'still 3 animations after replacing');
      Check(LModel.Root.Animations[0].Origin = 'moves.gltf', '"Wave" should now be the imported one');
      Check(LModel.Root.Accessors.Count = 5, 'the replaced animation''s data should be removed');
      Check(LModel.Root.Buffers[0].ByteLength = 104, Format('buffer should be 104 bytes, not %d',
        [LModel.Root.Buffers[0].ByteLength]));
      LSaved.Clear;
      LModel.SaveToStream(LSaved, gffGLB);
      LSaved.Position := 0;
      LCopy.LoadFromStream(LSaved);

      // 5. Abort at the first duplicate: nothing is added
      LFresh := TglTFDocument.Create;
      try
        LFresh.LoadFromString(LModelJSON);
        LImporter := TglTFAnimationImporter.Create(LFresh);
        try
          LImporter.OnDuplicate :=
            procedure(AImporter: TglTFAnimationImporter; ACandidate: TglTFAnimationCandidate;
              AExisting: Integer; var AAction: TglTFDuplicateAction; var ANewName: string)
            begin
              AAction := daAbort;
            end;
          LAdded := LImporter.ImportDocument(NewMoves, 'moves.gltf');
          Check((LAdded = 0) and LImporter.AbortRequested, 'an abort should add nothing more');
        finally
          LImporter.Free;
        end;
        Check((LFresh.Root.Animations.Count = 1) and (LFresh.Root.Accessors.Count = 2),
          'after an abort at the first animation the model should be unchanged');
      finally
        LFresh.Free;
      end;

      // 6. Clear: no animations, and no data left that only they used
      TglTFEdit.ClearAnimations(LModel.Root, nil);
      Check((LModel.Root.Animations.Count = 0) and (LModel.Root.Accessors.Count = 0) and
        (LModel.Root.BufferViews.Count = 0) and (LModel.Root.Buffers.Count = 0),
        'clearing should leave no animation data');
      LSaved.Clear;
      LModel.SaveToStream(LSaved, gffGLB);
      LSaved.Position := 0;
      LCopy.LoadFromStream(LSaved);

      if LFailures = 0 then
        Log('  PASS: matched by name, duplicate renamed and replaced, shared data copied once, ' +
          'unexported animations left out, abort and clear');
    except
      on E: Exception do
        Check(False, E.ClassName + ': ' + E.Message);
    end;
  finally
    LSaved.Free;
    LOriginal.Free;
    LCopy.Free;
    LModel.Free;
  end;
end;

// The bytes written to a stream, as a data URI
function StreamDataUri(AStream: TMemoryStream): string;
var
  LBytes: TBytes;
  LEncoding: TBase64Encoding;
begin
  SetLength(LBytes, AStream.Size);
  if AStream.Size > 0 then
    Move(AStream.Memory^, LBytes[0], AStream.Size);
  LEncoding := TBase64Encoding.Create(0);
  try
    Result := 'data:application/octet-stream;base64,' + LEncoding.EncodeBytesToString(LBytes);
  finally
    LEncoding.Free;
  end;
end;

procedure WriteSingles(AStream: TStream; const AValues: array of Single);
var
  LValue: Single;
  I: Integer;
begin
  for I := 0 to High(AValues) do
  begin
    LValue := AValues[I];
    AStream.WriteBuffer(LValue, SizeOf(LValue));
  end;
end;

procedure WriteBytes(AStream: TStream; const AValues: array of Byte);
var
  LValue: Byte;
  I: Integer;
begin
  for I := 0 to High(AValues) do
  begin
    LValue := AValues[I];
    AStream.WriteBuffer(LValue, SizeOf(LValue));
  end;
end;

procedure WriteWords(AStream: TStream; const AValues: array of Word);
var
  LValue: Word;
  I: Integer;
begin
  for I := 0 to High(AValues) do
  begin
    LValue := AValues[I];
    AStream.WriteBuffer(LValue, SizeOf(LValue));
  end;
end;

procedure WriteIdentities(AStream: TStream; ACount: Integer);
var
  I: Integer;
begin
  for I := 1 to ACount do
    WriteSingles(AStream, [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
end;

procedure TglTFMainForm.PartsTest;
var
  LModelJSON, LPartsJSON: string;
  LData: TMemoryStream;
  LModel, LCopy, LPartsDoc: TglTFDocument;
  LLibrary: TglTFPartLibrary;
  LApplier: TglTFPartApplier;
  LOptions: TglTFPartOptions;
  LSaved: TMemoryStream;
  LFailures: Integer;

  procedure Check(ACondition: Boolean; const AText: string);
  begin
    if not ACondition then
    begin
      Inc(LFailures);
      Log('  FAIL: %s', [AText]);
    end;
  end;

  // The triangles of the body (node 4) as a list of vertex numbers
  function BodyTriangles(ADoc: TglTFDocument): string;
  var
    LTriangles: TArray<Cardinal>;
    LIndex: Cardinal;
  begin
    LTriangles := ReadPrimitiveTriangles(ADoc.Root,
      ADoc.Root.Meshes[ADoc.Root.Nodes[4].Mesh].Primitives[0]);
    Result := '';
    for LIndex in LTriangles do
      Result := Result + IntToStr(LIndex);
  end;

begin
  Log;
  Log('Self-test: putting parts on a skinned body, replacing them and taking them off');

  // The model: Root > pelvis > calf_l > foot_l, and Body, a mesh of two
  // triangles: 0-1-2 on calf_l and 3-4-5 on foot_l
  LData := TMemoryStream.Create;
  try
    WriteSingles(LData, [0, 1, 0,  1, 1, 0,  0, 2, 0,  0, 0, 0,  1, 0, 0,  0, 0.5, 0]); // 72
    WriteBytes(LData, [1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,
                       2, 0, 0, 0,  2, 0, 0, 0,  2, 0, 0, 0]);                         // 24
    WriteSingles(LData, [1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,
                         1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0]);                       // 96
    WriteWords(LData, [0, 1, 2, 3, 4, 5]);                                             // 12
    WriteIdentities(LData, 3);                                                         // 192
    LModelJSON :=
      '{"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],' +
      '"nodes":[{"name":"Root","children":[1,4]},{"name":"pelvis","children":[2]},' +
      '{"name":"calf_l","children":[3]},{"name":"foot_l"},{"name":"Body","mesh":0,"skin":0}],' +
      '"skins":[{"joints":[1,2,3],"inverseBindMatrices":4,"skeleton":1}],' +
      '"meshes":[{"primitives":[{"attributes":{"POSITION":0,"JOINTS_0":1,"WEIGHTS_0":2},"indices":3}]}],' +
      '"buffers":[{"byteLength":396,"uri":"' + StreamDataUri(LData) + '"}],' +
      '"bufferViews":[{"buffer":0,"byteLength":72},{"buffer":0,"byteOffset":72,"byteLength":24},' +
      '{"buffer":0,"byteOffset":96,"byteLength":96},{"buffer":0,"byteOffset":192,"byteLength":12},' +
      '{"buffer":0,"byteOffset":204,"byteLength":192}],' +
      '"accessors":[{"bufferView":0,"componentType":5126,"count":6,"type":"VEC3","min":[0,0,0],"max":[1,2,0]},' +
      '{"bufferView":1,"componentType":5121,"count":6,"type":"VEC4"},' +
      '{"bufferView":2,"componentType":5126,"count":6,"type":"VEC4"},' +
      '{"bufferView":3,"componentType":5123,"count":6,"type":"SCALAR"},' +
      '{"bufferView":4,"componentType":5126,"count":3,"type":"MAT4"}]}';
  finally
    LData.Free;
  end;

  // The part file: its own copy of the skeleton and two foot pieces, Boot
  // and Sandal, each a triangle on foot_l, sharing a skin and a material.
  // The triangle lies 0.03 in front of the body's foot triangle, which it
  // spans, and well below its calf triangle; the body is 2 high, so with the
  // default gap of 3% (0.06) it hides the foot only
  LData := TMemoryStream.Create;
  try
    WriteSingles(LData, [-0.5, -0.5, 0.03,  2.5, -0.5, 0.03,  -0.5, 0.8, 0.03]);     // 36
    WriteBytes(LData, [0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0]);                        // 12
    WriteSingles(LData, [1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0]);                      // 48
    WriteIdentities(LData, 1);                                                        // 64
    LPartsJSON :=
      '{"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0,3,4]}],' +
      '"nodes":[{"name":"pelvis","children":[1]},{"name":"calf_l","children":[2]},' +
      '{"name":"foot_l"},{"name":"Boot","mesh":0,"skin":0},{"name":"Sandal","mesh":1,"skin":0}],' +
      '"skins":[{"joints":[2],"inverseBindMatrices":3}],' +
      '"materials":[{"name":"Leather","pbrMetallicRoughness":{"baseColorFactor":[0.5,0.3,0.1,1]}}],' +
      '"meshes":[{"name":"Boot","primitives":[{"attributes":{"POSITION":0,"JOINTS_0":1,"WEIGHTS_0":2},"material":0}]},' +
      '{"name":"Sandal","primitives":[{"attributes":{"POSITION":0,"JOINTS_0":1,"WEIGHTS_0":2},"material":0}]}],' +
      '"buffers":[{"byteLength":160,"uri":"' + StreamDataUri(LData) + '"}],' +
      '"bufferViews":[{"buffer":0,"byteLength":36},{"buffer":0,"byteOffset":36,"byteLength":12},' +
      '{"buffer":0,"byteOffset":48,"byteLength":48},{"buffer":0,"byteOffset":96,"byteLength":64}],' +
      '"accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3","min":[-0.5,-0.5,0.03],"max":[2.5,0.8,0.03]},' +
      '{"bufferView":1,"componentType":5121,"count":3,"type":"VEC4"},' +
      '{"bufferView":2,"componentType":5126,"count":3,"type":"VEC4"},' +
      '{"bufferView":3,"componentType":5126,"count":1,"type":"MAT4"}]}';
  finally
    LData.Free;
  end;

  LFailures := 0;
  LOptions := TglTFPartOptions.Default;
  LModel := TglTFDocument.Create;
  LCopy := TglTFDocument.Create;
  LSaved := TMemoryStream.Create;
  LLibrary := TglTFPartLibrary.Create;
  LApplier := nil;
  try
    try
      LModel.LoadFromString(LModelJSON);
      LApplier := TglTFPartApplier.Create(LModel);
      LPartsDoc := TglTFDocument.Create;
      try
        LPartsDoc.LoadFromString(LPartsJSON);
      except
        LPartsDoc.Free;
        raise;
      end;

      // 1. The parts found, and the bones they cover
      Check(LLibrary.AddDocument(LPartsDoc, 'feet.gltf') = 2, 'the part file should have 2 parts');
      Check((LLibrary.Count = 2) and (LLibrary[0].Name = 'Boot') and (LLibrary[0].Error = ''),
        'the first part should be a usable "Boot"');
      Check((Length(LLibrary[0].CoveredBones(LOptions)) = 1) and
        (LLibrary[0].CoveredBones(LOptions)[0] = 'foot_l'), 'Boot should cover foot_l');

      // 2. Boot on: bound to the model's foot_l, next to the body, which
      //    loses its foot triangle
      Check(LApplier.Apply([LLibrary[0]], LOptions) = 1, 'Boot should be put on');
      Check((LModel.Root.Nodes.Count = 6) and TglTFPartApplier.IsPartNode(LModel.Root.Nodes[5]) and
        (LModel.Root.Nodes[5].Name = 'Boot'), 'node 5 should be the Boot part');
      Check(BodyTriangles(LModel) = '012', 'the body should keep only its calf triangle, not ' +
        BodyTriangles(LModel));
      Check((LModel.Root.Skins.Count = 2) and (Length(LModel.Root.Skins[1].Joints) = 1) and
        (LModel.Root.Skins[1].Joints[0] = 3), 'Boot should be bound to the model''s foot_l');
      Check((Length(LModel.Root.Nodes[0].Children) = 3) and (LModel.Root.Nodes[0].Children[2] = 5),
        'Boot should be placed next to the body');
      Check(LModel.Root.Materials.Count = 1, 'Boot should bring its material');

      // 3. Sandal on: it replaces Boot, reusing its skin and material
      Check(LApplier.Apply([LLibrary[1]], LOptions) = 1, 'Sandal should be put on');
      Check((LModel.Root.Nodes.Count = 6) and (LModel.Root.Nodes[5].Name = 'Sandal'),
        'Sandal should replace Boot');
      Check((LModel.Root.Meshes.Count = 2) and (LModel.Root.Skins.Count = 2) and
        (LModel.Root.Materials.Count = 1), 'Boot''s mesh should go, its skin and material stay');
      Check(BodyTriangles(LModel) = '012', 'the body''s foot should stay hidden');

      // 4. Sandal off: the model is as it was, its foot triangle back
      Check(LApplier.Remove([5], LOptions) = 1, 'Sandal should be taken off');
      Check((LModel.Root.Nodes.Count = 5) and (LModel.Root.Meshes.Count = 1) and
        (LModel.Root.Skins.Count = 1) and (LModel.Root.Materials.Count = 0) and
        (LModel.Root.Accessors.Count = 5), 'taking it off should leave nothing of it');
      Check(BodyTriangles(LModel) = '012345', 'the body''s foot should be back, not ' +
        BodyTriangles(LModel));

      // 5. Bones kept are never hidden: Boot then hides nothing
      LOptions.KeepBones := ['FOOT_L'];
      Check(LApplier.Apply([LLibrary[0]], LOptions) = 1, 'Boot should be put on again');
      Check(BodyTriangles(LModel) = '012345', 'with foot_l kept the body should be whole');

      // 6. Hidden again with the defaults, then a GLB round trip: the part is
      //    still recognised and the body still without its foot
      LOptions := TglTFPartOptions.Default;
      LApplier.Refresh(LOptions);
      Check(BodyTriangles(LModel) = '012', 'Refresh should hide the foot');
      LModel.SaveToStream(LSaved, gffGLB);
      LSaved.Position := 0;
      LCopy.LoadFromStream(LSaved);
      Check((LCopy.Root.Nodes.Count = 6) and TglTFPartApplier.IsPartNode(LCopy.Root.Nodes[5]) and
        (BodyTriangles(LCopy) = '012'), 'the saved GLB should keep the part and the hidden foot');

      if LFailures = 0 then
        Log('  PASS: covered bones found, part bound by bone name, body hidden where it lies, ' +
          'replaced, taken off with nothing left over, kept bones, GLB round trip');
    except
      on E: Exception do
        Check(False, E.ClassName + ': ' + E.Message);
    end;
  finally
    LApplier.Free;
    LLibrary.Free;
    LSaved.Free;
    LCopy.Free;
    LModel.Free;
  end;
end;

procedure TglTFMainForm.UnusedImagesTest;
var
  LJSON, LPng0, LPng1: string;
  LData: TMemoryStream;
  LModel, LCopy: TglTFDocument;
  LSaved: TMemoryStream;
  LUsed: TArray<Boolean>;
  LFailures: Integer;

  procedure Check(ACondition: Boolean; const AText: string);
  begin
    if not ACondition then
    begin
      Inc(LFailures);
      Log('  FAIL: %s', [AText]);
    end;
  end;

  // A small "PNG": the signature and a few bytes that tell it apart
  function PngUri(ASeed: Byte): string;
  var
    LBytes: TMemoryStream;
  begin
    LBytes := TMemoryStream.Create;
    try
      WriteBytes(LBytes, [$89, $50, $4E, $47, $0D, $0A, $1A, $0A, ASeed, ASeed, ASeed, ASeed]);
      Result := StreamDataUri(LBytes).Replace('application/octet-stream', 'image/png');
    finally
      LBytes.Free;
    end;
  end;

begin
  Log;
  Log('Self-test: saving only the images the model shows');

  // Material 0 is used and shows texture 0 (image 0). Material 1 is not
  // used: its texture 1 (image 1) goes, while texture 0, which unused
  // material 2 shares with material 0, stays
  LPng0 := PngUri(1);
  LPng1 := PngUri(2);
  LData := TMemoryStream.Create;
  try
    WriteSingles(LData, [0, 0, 0,  1, 0, 0,  0, 1, 0]);
    LJSON :=
      '{"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],' +
      '"nodes":[{"mesh":0}],' +
      '"meshes":[{"primitives":[{"attributes":{"POSITION":0},"material":0}]}],' +
      '"materials":[{"name":"Used","pbrMetallicRoughness":{"baseColorTexture":{"index":0}}},' +
      '{"name":"Unused","pbrMetallicRoughness":{"baseColorTexture":{"index":1}}},' +
      '{"name":"Unused too","emissiveTexture":{"index":0}}],' +
      '"textures":[{"source":0,"sampler":0},{"source":1,"sampler":0}],' +
      '"samplers":[{}],' +
      '"images":[{"uri":"' + LPng0 + '"},{"uri":"' + LPng1 + '"}],' +
      '"buffers":[{"byteLength":36,"uri":"' + StreamDataUri(LData) + '"}],' +
      '"bufferViews":[{"buffer":0,"byteLength":36}],' +
      '"accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3",' +
      '"min":[0,0,0],"max":[1,1,0]}]}';
  finally
    LData.Free;
  end;

  LFailures := 0;
  LModel := TglTFDocument.Create;
  LCopy := TglTFDocument.Create;
  LSaved := TMemoryStream.Create;
  try
    try
      LModel.LoadFromString(LJSON);
      LUsed := TglTFEdit.ImagesInUse(LModel.Root);
      Check((Length(LUsed) = 2) and LUsed[0] and not LUsed[1],
        'image 0 should be used and image 1 not');

      LModel.SaveToStream(LSaved, gffGLB);
      LSaved.Position := 0;
      LCopy.LoadFromStream(LSaved);
      Check(LCopy.Root.Images.Count = 1, Format('the GLB should hold 1 image, not %d',
        [LCopy.Root.Images.Count]));
      Check((LCopy.Root.Images.Count = 1) and (Length(LCopy.Root.Images[0].Data) = 12) and
        (LCopy.Root.Images[0].Data[8] = 1), 'the image saved should be image 0');
      Check((LCopy.Root.Materials.Count = 1) and (LCopy.Root.Textures.Count = 1) and
        (LCopy.Root.Samplers.Count = 1), 'only the used material, its texture and sampler ' +
        'should be saved');
      Check((LCopy.Root.Meshes.Count = 1) and
        (LCopy.Root.Meshes[0].Primitives[0].Material = 0), 'the mesh should keep its material');
      Check(LModel.Root.Images.Count = 2, 'the document itself should keep both images');

      if LFailures = 0 then
        Log('  PASS: unused image, material and texture left out, shared texture kept, ' +
          'document unchanged');
    except
      on E: Exception do
        Check(False, E.ClassName + ': ' + E.Message);
    end;
  finally
    LSaved.Free;
    LCopy.Free;
    LModel.Free;
  end;
end;

procedure TglTFMainForm.RunSelfTests;
begin
  Log;
  Log('==== Self-tests (inline test assets, not the loaded file) ====');

  ExpectError('accessor without componentType', [
    '{',
    '  "asset": { "version": "2.0" },',
    '  "accessors": [',
    '    {',
    '      "count": 3,',
    '      "type": "VEC3"',
    '    }',
    '  ]',
    '}'], EglTFMissingPropertyError);

  ExpectError('accessor count given as a string', [
    '{',
    '  "asset": { "version": "2.0" },',
    '  "accessors": [',
    '    {',
    '      "componentType": 5126,',
    '      "count": "three",',
    '      "type": "VEC3"',
    '    }',
    '  ]',
    '}'], EglTFParseError);

  ExpectError('JSON syntax error (missing comma)', [
    '{',
    '  "asset": { "version": "2.0" }',
    '  "scene": 0',
    '}'], EglTFParseError);

  AnimationImportTest;
  AnimationSplitTest;
  ReorientTest;
  PartsTest;
  UnusedImagesTest;

  if FDoc.FileFormat <> gffNone then
  begin
    RoundTripTest(gffJSON);
    RoundTripTest(gffGLB);
  end
  else
  begin
    Log;
    Log('(Load a file to include the save/load round-trip tests)');
  end;

  Log;
  Log('==== Self-tests finished ====');
end;

end.
