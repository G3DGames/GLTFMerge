//** @abstract(Loads and saves glTF 2.0 documents as .gltf JSON or .glb binary files.)
//**
//** @link(TglTFDocument) is the entry point. Loading reads a .gltf or .glb asset from a
//** file, a stream, a string, bytes or an already parsed TJSONValue into a TglTF object
//** tree. The format is detected from the content, not the file name. Buffer and image
//** bytes are copied into the objects (@code(TglTFBuffer.Data), @code(TglTFImage.Data))
//** from the GLB BIN chunk, data URIs or external files.
//**
//** Saving writes .gltf or .glb, chosen by the file extension (or explicitly for
//** streams). Everything written comes from the objects: the JSON from
//** @code(TglTF.SaveToJSON) and the binary data from the Data properties. Nothing is
//** copied from the file that was loaded. By default a GLB stores every image inside it, in
//** the BIN chunk, and a glTF writes every image as a separate file next to it; with
//** @link(TglTFSaveOptions.ImageSaveMode) set to ismPerImage, each image's Embed flag decides
//** instead whether it goes into a buffer (GLB: the BIN chunk; glTF: a new base64 data-URI
//** buffer) or into a separate file. Animations whose @code(ExportOnSave) is False are left
//** out, together with the accessors, bufferViews and buffer bytes only they used, and so are
//** images no mesh shows @(see @link(TglTFSaveOptions.LeaveOutUnusedImages)@). The saved model
//** can also be turned about the X, Y and Z axes, baked into its data @(see
//** @link(TglTFSaveOptions.RotateX)@).
//**
//** A save to a file is made file-complete: every separate buffer and image file the
//** saved glTF refers to is written or copied next to it, unless it is already there
//** with the same bytes. Files that could not be found are reported in
//** @link(TglTFDocument.SaveWarnings) and @link(TglTFDocument.SaveComplete) is False.
//**
//** @preformatted(
//** Load:  file / stream / string / bytes --> TglTF objects + Data
//** Save:  TglTF objects + Data --> copy --> storage chosen per buffer / image --> output
//**        separate files: written next to the output @(SavedFiles lists them@)
//** )
//**
//** None of the classes in this unit are thread-safe; use a document from one thread at a
//** time.
unit glTF.Document;

{
  Loads and saves glTF 2.0 documents as .gltf JSON or .glb binary files.

  TglTFDocument is the entry point. Loading reads a .gltf or .glb asset from a
  file, a stream, a string, bytes or an already parsed TJSONValue into a TglTF
  object tree. The format is detected from the content, not the file name.
  Buffer and image bytes are copied into the objects (TglTFBuffer.Data,
  TglTFImage.Data) from the GLB BIN chunk, data URIs or external files.

  Saving writes .gltf or .glb, chosen by the file extension (or explicitly for
  streams). Everything written comes from the objects: the JSON from
  TglTF.SaveToJSON and the binary data from the Data properties. Nothing is
  copied from the file that was loaded. By default a GLB stores every image
  inside it, in the BIN chunk, and a glTF writes every image as a separate file
  next to it; with TglTFSaveOptions.ImageSaveMode set to ismPerImage, each
  image's Embed flag decides instead whether it goes into a buffer (GLB: the
  BIN chunk; glTF: a new base64 data-URI buffer) or into a separate file. Animations whose
  ExportOnSave is False are left out, together with the accessors, bufferViews
  and buffer bytes only they used, and so are images no mesh shows (see
  TglTFSaveOptions.LeaveOutUnusedImages). The saved model can also be turned
  about the X, Y and Z axes, baked into its data (see
  TglTFSaveOptions.RotateX).

  A save to a file is made file-complete: every separate buffer and image file
  the saved glTF refers to is written or copied next to it, unless it is
  already there with the same bytes. Files that could not be found are
  reported in SaveWarnings and SaveComplete is False.

    Load:  file / stream / string / bytes --> TglTF objects + Data
    Save:  TglTF objects + Data --> copy --> storage chosen per buffer / image --> output
           separate files: written next to the output (SavedFiles lists them)

  None of the classes in this unit are thread-safe; use a document from one
  thread at a time.
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.JSON,
  System.Generics.Collections,

  glTF.Base,
  glTF.Classes,
  glTF.SourceMap;

type
  //** @abstract(Raised when the GLB container itself is invalid: its header or chunk layout.)
  //**
  //** Errors in the JSON chunk's content are reported as EglTFParseError or
  //** EglTFMissingPropertyError instead, with a line number.
  /// <summary>Raised when the GLB container itself is invalid: its header or chunk layout.</summary>
  /// <remarks>Errors in the JSON chunk's content are reported as EglTFParseError or
  /// EglTFMissingPropertyError instead, with a line number.</remarks>
  EglTFGLBError = class(EglTFError)
  private
    FByteOffset: Int64;
  public
    //** @abstract(Creates the exception with a message and the offset of the problem.)
    //**
    //** The message is prefixed with "Invalid GLB:" and followed by the byte offset.
    //**
    //** @param(AMessage What is wrong with the container.)
    //**
    //** @param(AByteOffset Byte offset in the GLB data where the problem was found.)
    /// <summary>Creates the exception with a message and the offset of the problem.</summary>
    /// <param name="AMessage">What is wrong with the container.</param>
    /// <param name="AByteOffset">Byte offset in the GLB data where the problem was found.</param>
    /// <remarks>The message is prefixed with "Invalid GLB:" and followed by the byte offset.</remarks>
    constructor Create(const AMessage: string; AByteOffset: Int64);

    //** @abstract(Byte offset in the GLB data where the problem was found.)
    /// <summary>Byte offset in the GLB data where the problem was found.</summary>
    property ByteOffset: Int64 read FByteOffset;
  end;

  //** @abstract(The two glTF file formats.)
  /// <summary>The two glTF file formats.</summary>
  TglTFFileFormat = (
    //** @abstract(No format: nothing is loaded, or the file name has no .gltf or .glb extension.)
    /// <summary>No format: nothing is loaded, or the file name has no .gltf or .glb extension.</summary>
    gffNone,

    //** @abstract(glTF JSON text, usually a .gltf file.)
    /// <summary>glTF JSON text, usually a .gltf file.</summary>
    gffJSON,

    //** @abstract(Binary glTF, a .glb file.)
    /// <summary>Binary glTF, a .glb file.</summary>
    gffGLB);

  //** @abstract(Where the data of a buffer goes when saving.)
  //**
  //** Applies to buffers only; images follow @link(TglTFImageSaveMode). In a GLB,
  //** buffers[0] always goes into the BIN chunk whatever the mode.
  /// <summary>Where the data of a buffer goes when saving.</summary>
  /// <remarks>Applies to buffers only; images follow <see cref="TglTFImageSaveMode"/>. In a
  /// GLB, buffers[0] always goes into the BIN chunk whatever the mode.</remarks>
  TglTFResourceMode = (
    //** @abstract(Keeps each buffer's kind: data URIs stay data URIs, external files stay
    //** external files, written next to the output.)
    //**
    //** A buffer that was in a GLB BIN chunk becomes "<name>.bin" when saving .gltf.
    /// <summary>Keeps each buffer's kind: data URIs stay data URIs, external files stay
    /// external files, written next to the output.</summary>
    /// <remarks>A buffer that was in a GLB BIN chunk becomes "&lt;name&gt;.bin" when saving
    /// .gltf.</remarks>
    rmKeep,

    //** @abstract(Embeds every buffer as a base64 data URI.)
    /// <summary>Embeds every buffer as a base64 data URI.</summary>
    rmEmbed,

    //** @abstract(Writes every buffer as a file next to the output.)
    /// <summary>Writes every buffer as a file next to the output.</summary>
    rmExternal);

  //** @abstract(Where the images go when saving.)
  /// <summary>Where the images go when saving.</summary>
  TglTFImageSaveMode = (
    //** @abstract(The format decides: a GLB stores every image inside it, in the BIN chunk; a
    //** glTF writes every image as a separate file next to it.)
    //**
    //** The images' Embed flags are ignored. A glTF saved to a stream, which has no folder for
    //** files, still holds its images as data URIs.
    /// <summary>The format decides: a GLB stores every image inside it, in the BIN chunk; a
    /// glTF writes every image as a separate file next to it.</summary>
    /// <remarks>The images' Embed flags are ignored. A glTF saved to a stream, which has no
    /// folder for files, still holds its images as data URIs.</remarks>
    ismByFormat,

    //** @abstract(Each image's @code(TglTFImage.Embed) flag decides, in either format.)
    /// <summary>Each image's <c>TglTFImage.Embed</c> flag decides, in either
    /// format.</summary>
    ismPerImage);

  //** @abstract(Settings for @link(TglTFDocument.SaveToFile) and
  //** @link(TglTFDocument.SaveToStream).)
  //**
  //** Start from @link(TglTFSaveOptions.Default) and change what you need.
  /// <summary>Settings for <see cref="TglTFDocument.SaveToFile"/> and
  /// <see cref="TglTFDocument.SaveToStream"/>.</summary>
  /// <remarks>Start from <see cref="TglTFSaveOptions.Default"/> and change what you
  /// need.</remarks>
  TglTFSaveOptions = record
    //** @abstract(Where the data of each buffer goes; see @link(TglTFResourceMode).)
    /// <summary>Where the data of each buffer goes; see <see cref="TglTFResourceMode"/>.</summary>
    Buffers: TglTFResourceMode;

    //** @abstract(Writes indented JSON for .gltf.)
    //**
    //** GLB JSON is always written compact.
    /// <summary>Writes indented JSON for .gltf.</summary>
    /// <remarks>GLB JSON is always written compact.</remarks>
    PrettyPrint: Boolean;

    //** @abstract(Leaves out the images the model does not need, with the materials, textures and
    //** samplers that lead only to them; True by default.)
    //**
    //** An image is needed when a mesh shows it, through a material and a texture; see
    //** @code(TglTFEdit.ImagesInUse). The others, such as those of a part taken off, or of
    //** materials no mesh uses, are neither embedded nor written as separate files. The
    //** document itself keeps them.
    /// <summary>Leaves out the images the model does not need, with the materials, textures and
    /// samplers that lead only to them; True by default.</summary>
    /// <remarks>An image is needed when a mesh shows it, through a material and a texture; see
    /// <c>TglTFEdit.ImagesInUse</c>. The others, such as those of a part taken off, or of
    /// materials no mesh uses, are neither embedded nor written as separate files. The document
    /// itself keeps them.</remarks>
    LeaveOutUnusedImages: Boolean;

    //** @abstract(Where the images go; ismByFormat by default.)
    /// <summary>Where the images go; ismByFormat by default.</summary>
    ImageSaveMode: TglTFImageSaveMode;

    //** @abstract(Degrees to turn the whole model about the X axis; 0 by default.)
    //**
    //** With RotateY and RotateZ: when any of them turns the model, the saved model is
    //** re-oriented, its meshes, nodes, animations and skins turned, by
    //** @code(TglTFReorienter) in glTF.Orient. X is applied first, then Y, then Z. The
    //** document itself is not changed.
    /// <summary>Degrees to turn the whole model about the X axis; 0 by default.</summary>
    /// <remarks>With RotateY and RotateZ: when any of them turns the model, the saved model is
    /// re-oriented, its meshes, nodes, animations and skins turned, by
    /// <c>TglTFReorienter</c> in glTF.Orient. X is applied first, then Y, then Z. The document
    /// itself is not changed.</remarks>
    RotateX: Double;

    //** @abstract(Degrees to turn the whole model about the Y axis; 0 by default.)
    //**
    //** See RotateX.
    /// <summary>Degrees to turn the whole model about the Y axis; 0 by default.</summary>
    /// <remarks>See RotateX.</remarks>
    RotateY: Double;

    //** @abstract(Degrees to turn the whole model about the Z axis; 0 by default.)
    //**
    //** See RotateX.
    /// <summary>Degrees to turn the whole model about the Z axis; 0 by default.</summary>
    /// <remarks>See RotateX.</remarks>
    RotateZ: Double;

    //** @abstract(Returns the default settings.)
    //**
    //** @returns(Buffers = rmKeep, PrettyPrint = True, LeaveOutUnusedImages = True,
    //** ImageSaveMode = ismByFormat and no turn.)
    /// <summary>Returns the default settings.</summary>
    /// <returns>Buffers = rmKeep, PrettyPrint = True, LeaveOutUnusedImages = True,
    /// ImageSaveMode = ismByFormat and no turn.</returns>
    class function Default: TglTFSaveOptions; static;
  end;

  //** @abstract(The two kinds of external file a glTF can refer to.)
  /// <summary>The two kinds of external file a glTF can refer to.</summary>
  TglTFResourceKind = (
    //** @abstract(A buffer, an entry of @code(TglTF.Buffers).)
    /// <summary>A buffer, an entry of <c>TglTF.Buffers</c>.</summary>
    rkBuffer,

    //** @abstract(An image, an entry of @code(TglTF.Images).)
    /// <summary>An image, an entry of <c>TglTF.Images</c>.</summary>
    rkImage);

  //** @abstract(An external buffer or image file whose data is not loaded.)
  //**
  //** Returned by @link(TglTFDocument.MissingResources). It is a snapshot: it does not
  //** change when the file is found later.
  /// <summary>An external buffer or image file whose data is not loaded.</summary>
  /// <remarks>Returned by <see cref="TglTFDocument.MissingResources"/>. It is a snapshot:
  /// it does not change when the file is found later.</remarks>
  TglTFMissingResource = record
    //** @abstract(Whether this is a buffer or an image.)
    /// <summary>Whether this is a buffer or an image.</summary>
    Kind: TglTFResourceKind;

    //** @abstract(Index in @code(Root.Buffers) or @code(Root.Images), depending on Kind.)
    /// <summary>Index in <c>Root.Buffers</c> or <c>Root.Images</c>, depending on Kind.</summary>
    Index: Integer;

    //** @abstract(The uri as written in the glTF, still percent-encoded.)
    /// <summary>The uri as written in the glTF, still percent-encoded.</summary>
    Uri: string;

    //** @abstract(Where the file was looked for: the uri resolved against
    //** @code(BaseDirectory).)
    /// <summary>Where the file was looked for: the uri resolved against
    /// <c>BaseDirectory</c>.</summary>
    ExpectedPath: string;

    //** @abstract(Returns the file name part of the uri, decoded.)
    //**
    //** @returns(For example @code(brick.png) for the uri @code(textures/brick.png).)
    /// <summary>Returns the file name part of the uri, decoded.</summary>
    /// <returns>For example <c>brick.png</c> for the uri <c>textures/brick.png</c>.</returns>
    function FileName: string;

    //** @abstract(Returns a short description for messages.)
    //**
    //** @returns(For example: Image 2 "brick.png".)
    /// <summary>Returns a short description for messages.</summary>
    /// <returns>For example: Image 2 "brick.png".</returns>
    function Description: string;
  end;

  //** @abstract(How far a long operation has got: which model, which stage, how much of it.)
  //**
  //** Passed to @link(TglTFProgressEvent) handlers by TglTFDocument while loading and by
  //** TglTFAnimationImporter while importing. A document reports itself as model 1 of 1; an
  //** importer numbers the files it loads.
  /// <summary>How far a long operation has got: which model, which stage, how much of
  /// it.</summary>
  /// <remarks>Passed to <see cref="TglTFProgressEvent"/> handlers by TglTFDocument while
  /// loading and by TglTFAnimationImporter while importing. A document reports itself as model
  /// 1 of 1; an importer numbers the files it loads.</remarks>
  TglTFProgress = record
    //** @abstract(Number of the current model, from 1.)
    /// <summary>Number of the current model, from 1.</summary>
    ModelIndex: Integer;

    //** @abstract(Number of models in the whole operation.)
    /// <summary>Number of models in the whole operation.</summary>
    ModelCount: Integer;

    //** @abstract(File name of the current model, without its folder; empty when it was not
    //** loaded from a file.)
    /// <summary>File name of the current model, without its folder; empty when it was not
    /// loaded from a file.</summary>
    ModelName: string;

    //** @abstract(What is being done now, for example "Loading image 3 of 8".)
    /// <summary>What is being done now, for example "Loading image 3 of 8".</summary>
    Stage: string;

    //** @abstract(How much of the current model is done, from 0 to 1.)
    /// <summary>How much of the current model is done, from 0 to 1.</summary>
    Done: Double;

    //** @abstract(Returns how much of the whole operation is done.)
    //**
    //** @returns(From 0 to 1: the models finished plus the part of the current one done,
    //** divided by the number of models.)
    /// <summary>Returns how much of the whole operation is done.</summary>
    /// <returns>From 0 to 1: the models finished plus the part of the current one done,
    /// divided by the number of models.</returns>
    function Overall: Double;

    //** @abstract(Returns the model line for a progress display.)
    //**
    //** @returns(For example: Model 2 of 5: walk.glb.)
    /// <summary>Returns the model line for a progress display.</summary>
    /// <returns>For example: Model 2 of 5: walk.glb.</returns>
    function ModelText: string;
  end;

  //** @abstract(Event reporting progress, like TNotifyEvent with the progress added.)
  //**
  //** Called on the thread doing the work: when loading runs in a background thread, a
  //** handler that updates the user interface must pass the update to the main thread, for
  //** example with TThread.Queue. The handler must not change the document.
  //**
  //** @param(Sender The document or importer doing the work.)
  //**
  //** @param(AProgress How far it has got.)
  /// <summary>Event reporting progress, like TNotifyEvent with the progress added.</summary>
  /// <param name="Sender">The document or importer doing the work.</param>
  /// <param name="AProgress">How far it has got.</param>
  /// <remarks>Called on the thread doing the work: when loading runs in a background thread,
  /// a handler that updates the user interface must pass the update to the main thread, for
  /// example with TThread.Queue. The handler must not change the document.</remarks>
  TglTFProgressEvent = procedure(Sender: TObject; const AProgress: TglTFProgress) of object;

  //** @abstract(A glTF 2.0 document: its object tree and loading and saving.)
  //**
  //** Holds a @code(TglTF) object tree in @link(Root), which is never nil. Loading replaces
  //** the tree only when the load succeeds, so a failed load leaves the previous asset in
  //** place. Saving never changes the tree: it works on a copy.
  //**
  //** Not thread-safe; use an instance from one thread at a time. Every method blocks
  //** until it finishes, including the file reads and writes it does.
  //**
  //** @longCode(#
  //** Doc := TglTFDocument.CreateFromFile('model.gltf');
  //** try
  //**   Doc.SaveToFile('model.glb'); // every image inside the GLB
  //** finally
  //**   Doc.Free;
  //** end;
  //** #)
  /// <summary>A glTF 2.0 document: its object tree and loading and saving.</summary>
  /// <remarks>
  /// <para>Holds a <c>TglTF</c> object tree in <see cref="Root"/>, which is never nil.
  /// Loading replaces the tree only when the load succeeds, so a failed load leaves the
  /// previous asset in place. Saving never changes the tree: it works on a copy.</para>
  /// <para>Not thread-safe; use an instance from one thread at a time. Every method blocks
  /// until it finishes, including the file reads and writes it does.</para>
  /// </remarks>
  /// <example><code>
  /// Doc := TglTFDocument.CreateFromFile('model.gltf');
  /// try
  ///   Doc.SaveToFile('model.glb'); // every image inside the GLB
  /// finally
  ///   Doc.Free;
  /// end;
  /// </code></example>
  TglTFDocument = class
  private
    FRoot: TglTF;
    FFileName: string;
    FBaseDirectory: string;
    FFormat: TglTFFileFormat;
    FHasBinaryChunk: Boolean;
    FBinaryChunkLength: Int64;
    FJSONChunkLength: Int64;
    FLoadExternalResources: Boolean;
    FWarnings: TStringList;
    FSaveWarnings: TStringList;
    FSavedFiles: TStringList;
    FSaveComplete: Boolean;
    FOnProgress: TglTFProgressEvent;
    FProgressName: string;
    procedure DoProgress(const AStage: string; ADone: Double);
    procedure ReplaceRoot(ANewRoot: TglTF);
    function CreateRoot(AJSON: TJSONValue): TglTF;
    procedure ValidateGLBBuffers(ARoot: TglTF; const ABinary: TBytes; AHasBinary: Boolean);
    procedure LoadResources(ARoot: TglTF; const ABinary: TBytes; AHasBinary: Boolean;
      const ABaseDir: string; AWarnings: TStrings);
    procedure LoadText(const AJSONText, ASourceName, ABaseDir: string;
      AFormat: TglTFFileFormat; const ABinary: TBytes; AHasBinary: Boolean);
    procedure LoadGLB(const ABytes: TBytes; const ASourceName, ABaseDir: string);
    procedure LoadStream(AStream: TStream; const ASourceName, ABaseDir: string);
    function CreateSaveCopy: TglTF;
    procedure ReadUnloadedFiles(AOut: TglTF);
    procedure TakeSeparateImagesOutOfBuffers(AOut: TglTF);
    procedure LeaveOutUnexportedAnimations(AOut: TglTF);
    procedure SaveInternal(AStream: TStream; AFormat: TglTFFileFormat;
      const AOptions: TglTFSaveOptions; const AOutDir, ABaseName: string);
  public
    //** @abstract(Creates an empty document.)
    //**
    //** @link(Root) is an empty @code(TglTF) and @link(FileFormat) is gffNone.
    /// <summary>Creates an empty document.</summary>
    /// <remarks><see cref="Root"/> is an empty <c>TglTF</c> and <see cref="FileFormat"/> is
    /// gffNone.</remarks>
    constructor Create;

    //** @abstract(Frees the document and its whole object tree.)
    /// <summary>Frees the document and its whole object tree.</summary>
    destructor Destroy; override;

    //** @abstract(Creates a document and loads a .gltf or .glb file into it.)
    //**
    //** The caller owns the result. Nothing is returned when loading fails.
    //**
    //** @param(AFileName The file to load; see @link(LoadFromFile).)
    //**
    //** @returns(The new document.)
    //**
    //** @raises(EglTFError The file is not valid glTF; see @link(LoadFromFile).)
    /// <summary>Creates a document and loads a .gltf or .glb file into it.</summary>
    /// <param name="AFileName">The file to load; see <see cref="LoadFromFile"/>.</param>
    /// <returns>The new document.</returns>
    /// <exception cref="EglTFError">The file is not valid glTF; see
    /// <see cref="LoadFromFile"/>.</exception>
    /// <remarks>The caller owns the result. Nothing is returned when loading fails.</remarks>
    class function CreateFromFile(const AFileName: string): TglTFDocument;

    //** @abstract(Creates a document and loads glTF JSON or GLB from a stream into it.)
    //**
    //** The caller owns the result. Nothing is returned when loading fails.
    //**
    //** @param(AStream Read from its current position to its end; see @link(LoadFromStream).)
    //**
    //** @returns(The new document.)
    //**
    //** @raises(EglTFError The data is not valid glTF.)
    /// <summary>Creates a document and loads glTF JSON or GLB from a stream into it.</summary>
    /// <param name="AStream">Read from its current position to its end; see
    /// <see cref="LoadFromStream"/>.</param>
    /// <returns>The new document.</returns>
    /// <exception cref="EglTFError">The data is not valid glTF.</exception>
    /// <remarks>The caller owns the result. Nothing is returned when loading fails.</remarks>
    class function CreateFromStream(AStream: TStream): TglTFDocument;

    //** @abstract(Tells whether bytes start with the GLB magic "glTF".)
    //**
    //** @param(ABytes The start of the data, at least 4 bytes to be recognised.)
    //**
    //** @returns(True for GLB data, False otherwise.)
    /// <summary>Tells whether bytes start with the GLB magic "glTF".</summary>
    /// <param name="ABytes">The start of the data, at least 4 bytes to be recognised.</param>
    /// <returns>True for GLB data, False otherwise.</returns>
    class function IsGLBData(const ABytes: TBytes): Boolean; static;

    //** @abstract(Returns the format a file name's extension stands for.)
    //**
    //** The comparison ignores case.
    //**
    //** @param(AFileName A file name or path.)
    //**
    //** @returns(gffGLB for .glb, gffJSON for .gltf, gffNone for anything else.)
    /// <summary>Returns the format a file name's extension stands for.</summary>
    /// <param name="AFileName">A file name or path.</param>
    /// <returns>gffGLB for .glb, gffJSON for .gltf, gffNone for anything else.</returns>
    /// <remarks>The comparison ignores case.</remarks>
    class function FormatFromFileName(const AFileName: string): TglTFFileFormat; static;

    //** @abstract(Discards the loaded asset.)
    //**
    //** @link(Root) becomes an empty @code(TglTF); the file name, base directory, format
    //** and load warnings are cleared. Objects of the old tree become invalid.
    /// <summary>Discards the loaded asset.</summary>
    /// <remarks><see cref="Root"/> becomes an empty <c>TglTF</c>; the file name, base
    /// directory, format and load warnings are cleared. Objects of the old tree become
    /// invalid.</remarks>
    procedure Clear;

    {$REGION 'Loading'}
    //** @abstract(Loads a .gltf or .glb file.)
    //**
    //** The format is detected from the content. External buffers and images are read
    //** relative to the file's folder, which becomes @link(BaseDirectory). Missing external
    //** files do not fail the load: they are listed in @link(Warnings) and
    //** @link(MissingResources). Errors in the JSON report their line, within the JSON
    //** chunk for a GLB.
    //**
    //** When a referenced file is not found under its exact name, folder and file names are
    //** matched ignoring case, as glTF files made on Windows often differ in case from the
    //** files on case-sensitive file systems @(Linux, Android, iOS@).
    //**
    //** @param(AFileName The file to load.)
    //**
    //** @raises(EglTFParseError The JSON is malformed or a value is invalid.)
    //**
    //** @raises(EglTFMissingPropertyError A property the glTF schema requires is missing.)
    //**
    //** @raises(EglTFGLBError The GLB container is invalid.)
    //**
    //** @raises(EFOpenError The file cannot be opened.)
    /// <summary>Loads a .gltf or .glb file.</summary>
    /// <param name="AFileName">The file to load.</param>
    /// <exception cref="EglTFParseError">The JSON is malformed or a value is invalid.</exception>
    /// <exception cref="EglTFMissingPropertyError">A property the glTF schema requires is
    /// missing.</exception>
    /// <exception cref="EglTFGLBError">The GLB container is invalid.</exception>
    /// <exception cref="EFOpenError">The file cannot be opened.</exception>
    /// <remarks>The format is detected from the content. External buffers and images are
    /// read relative to the file's folder, which becomes <see cref="BaseDirectory"/>.
    /// Missing external files do not fail the load: they are listed in
    /// <see cref="Warnings"/> and <see cref="MissingResources"/>. Errors in the JSON report
    /// their line, within the JSON chunk for a GLB. When a referenced file is not found
    /// under its exact name, folder and file names are matched ignoring case, as glTF files
    /// made on Windows often differ in case from the files on case-sensitive file systems
    /// (Linux, Android, iOS).</remarks>
    procedure LoadFromFile(const AFileName: string);

    //** @abstract(Loads glTF JSON or GLB from a stream.)
    //**
    //** Reads from the stream's current position to its end; the format is detected from
    //** the content. External files are read relative to @link(BaseDirectory), so set it
    //** first if the asset has any. @link(FileName) becomes empty.
    //**
    //** @param(AStream The data; the caller keeps ownership.)
    //**
    //** @raises(EglTFError The data is empty or not valid glTF; see @link(LoadFromFile).)
    /// <summary>Loads glTF JSON or GLB from a stream.</summary>
    /// <param name="AStream">The data; the caller keeps ownership.</param>
    /// <exception cref="EglTFError">The data is empty or not valid glTF; see
    /// <see cref="LoadFromFile"/>.</exception>
    /// <remarks>Reads from the stream's current position to its end; the format is
    /// detected from the content. External files are read relative to
    /// <see cref="BaseDirectory"/>, so set it first if the asset has any.
    /// <see cref="FileName"/> becomes empty.</remarks>
    procedure LoadFromStream(AStream: TStream);

    //** @abstract(Loads glTF JSON text.)
    //**
    //** External files are read relative to @link(BaseDirectory). @link(FileName) becomes
    //** empty.
    //**
    //** @param(AJSONText The JSON of a glTF asset.)
    //**
    //** @raises(EglTFError The text is not valid glTF; see @link(LoadFromFile).)
    /// <summary>Loads glTF JSON text.</summary>
    /// <param name="AJSONText">The JSON of a glTF asset.</param>
    /// <exception cref="EglTFError">The text is not valid glTF; see
    /// <see cref="LoadFromFile"/>.</exception>
    /// <remarks>External files are read relative to <see cref="BaseDirectory"/>.
    /// <see cref="FileName"/> becomes empty.</remarks>
    procedure LoadFromString(const AJSONText: string);

    //** @abstract(Loads GLB data held in memory.)
    //**
    //** External files are read relative to @link(BaseDirectory). @link(FileName) becomes
    //** empty.
    //**
    //** @param(ABytes The whole GLB file.)
    //**
    //** @raises(EglTFError The data is not valid GLB; see @link(LoadFromFile).)
    /// <summary>Loads GLB data held in memory.</summary>
    /// <param name="ABytes">The whole GLB file.</param>
    /// <exception cref="EglTFError">The data is not valid GLB; see
    /// <see cref="LoadFromFile"/>.</exception>
    /// <remarks>External files are read relative to <see cref="BaseDirectory"/>.
    /// <see cref="FileName"/> becomes empty.</remarks>
    procedure LoadFromGLBBytes(const ABytes: TBytes);

    //** @abstract(Loads already parsed glTF JSON.)
    //**
    //** Errors cannot report line numbers, as the original text is not available. Buffer
    //** data can only come from data URIs and from external files relative to
    //** @link(BaseDirectory).
    //**
    //** @param(AJSON The glTF root object; the caller keeps ownership.)
    //**
    //** @raises(EglTFError The JSON is not valid glTF.)
    /// <summary>Loads already parsed glTF JSON.</summary>
    /// <param name="AJSON">The glTF root object; the caller keeps ownership.</param>
    /// <exception cref="EglTFError">The JSON is not valid glTF.</exception>
    /// <remarks>Errors cannot report line numbers, as the original text is not available.
    /// Buffer data can only come from data URIs and from external files relative to
    /// <see cref="BaseDirectory"/>.</remarks>
    procedure LoadFromJSON(AJSON: TJSONValue);
    {$ENDREGION}

    {$REGION 'Saving'}
    //** @abstract(Saves as .gltf or .glb, chosen by the file extension, with default
    //** options.)
    //**
    //** Same as @link(SaveToFile) with @link(TglTFSaveOptions.Default).
    //**
    //** @param(AFileName The output file; its extension must be .gltf or .glb.)
    //**
    //** @raises(EglTFError See the overload with options.)
    /// <summary>Saves as .gltf or .glb, chosen by the file extension, with default
    /// options.</summary>
    /// <param name="AFileName">The output file; its extension must be .gltf or .glb.</param>
    /// <exception cref="EglTFError">See the overload with options.</exception>
    /// <remarks>Same as <see cref="SaveToFile"/> with
    /// <see cref="TglTFSaveOptions.Default"/>.</remarks>
    procedure SaveToFile(const AFileName: string); overload;

    //** @abstract(Saves as .gltf or .glb, chosen by the file extension.)
    //**
    //** The output is made file-complete. Every buffer and image stored as a separate file
    //** is written next to it, at the path its uri gives relative to the output, creating
    //** sub-folders as needed. A file whose data was not loaded is copied from where it
    //** was found, or from its original location. A file already there with the same
    //** bytes is left alone. @link(SavedFiles) lists what was done for each file. A file
    //** that cannot be found anywhere is written as a uri reference only, reported in
    //** @link(SaveWarnings), and makes @link(SaveComplete) False.
    //**
    //** An image saved as a separate file is not also kept in a buffer: when it was inside
    //** one, its bytes are cut out, the later data moves down and every bufferView index is
    //** renumbered. Files using Draco or meshopt compression are the exception, as those
    //** extensions refer to bufferViews in their own JSON; the bytes then stay and
    //** @link(SaveWarnings) says so. The document itself is never changed.
    //**
    //** An image saved as a separate file is named, in order of preference: after its uri
    //** @(keeping the uri's folders when they stay inside the output folder, otherwise only
    //** the file name@); after its name, made safe for every platform's file system, with an
    //** extension from its MIME type; or <model>_image<N>. Names are unique within a save,
    //** ignoring case: images with identical bytes share one file, others get "_2", "_3"
    //** and so on before the extension. Buffer files follow the same rule, and nothing may
    //** take the name of the output file itself.
    //**
    //** An image file never replaces a different file already on disk: it is renamed the same
    //** way instead. The exception is an image with @code(TglTFImage.Shared) set, whose file
    //** may be shared with other models: when it already exists it is used as it is, even if
    //** its bytes differ, and its uri may lead outside the output folder.
    //**
    //** The separate files are written first and the main file last, so a failure leaves
    //** any existing main file untouched. Existing files of the same names are replaced.
    //**
    //** @param(AFileName The output file; its extension must be .gltf or .glb.)
    //**
    //** @param(AOptions Where buffer data goes and how the JSON is laid out.)
    //**
    //** @raises(EglTFError The extension is not .gltf or .glb, the objects are not valid
    //** glTF, or a GLB's buffers[0] has no data.)
    //**
    //** @raises(EInOutError A file cannot be written.)
    /// <summary>Saves as .gltf or .glb, chosen by the file extension.</summary>
    /// <param name="AFileName">The output file; its extension must be .gltf or .glb.</param>
    /// <param name="AOptions">Where buffer data goes and how the JSON is laid out.</param>
    /// <exception cref="EglTFError">The extension is not .gltf or .glb, the objects are not
    /// valid glTF, or a GLB's buffers[0] has no data.</exception>
    /// <exception cref="EInOutError">A file cannot be written.</exception>
    /// <remarks>
    /// <para>The output is made file-complete. Every buffer and image stored as a separate
    /// file is written next to it, at the path its uri gives relative to the output,
    /// creating sub-folders as needed. A file whose data was not loaded is copied from
    /// where it was found, or from its original location. A file already there with the
    /// same bytes is left alone. <see cref="SavedFiles"/> lists what was done for each
    /// file. A file that cannot be found anywhere is written as a uri reference only,
    /// reported in <see cref="SaveWarnings"/>, and makes <see cref="SaveComplete"/>
    /// False.</para>
    /// <para>An image saved as a separate file is not also kept in a buffer: when it was
    /// inside one, its bytes are cut out, the later data moves down and every bufferView index
    /// is renumbered. Files using Draco or meshopt compression are the exception, as those
    /// extensions refer to bufferViews in their own JSON; the bytes then stay and
    /// <see cref="SaveWarnings"/> says so. The document itself is never changed.</para>
    /// <para>An image saved as a separate file is named, in order of preference: after its
    /// uri (keeping the uri's folders when they stay inside the output folder, otherwise only
    /// the file name); after its name, made safe for every platform's file system, with an
    /// extension from its MIME type; or &lt;model&gt;_image&lt;N&gt;. Names are unique within a
    /// save, ignoring case: images with identical bytes share one file, others get "_2", "_3"
    /// and so on before the extension. Buffer files follow the same rule, and nothing may take
    /// the name of the output file itself.</para>
    /// <para>An image file never replaces a different file already on disk: it is renamed the
    /// same way instead. The exception is an image with <c>TglTFImage.Shared</c> set, whose file
    /// may be shared with other models: when it already exists it is used as it is, even if its
    /// bytes differ, and its uri may lead outside the output folder.</para>
    /// <para>The separate files are written first and the main file last, so a failure
    /// leaves any existing main file untouched. Existing files of the same names are
    /// replaced.</para>
    /// </remarks>
    procedure SaveToFile(const AFileName: string; const AOptions: TglTFSaveOptions); overload;

    //** @abstract(Saves to a stream in the given format, with default options.)
    //**
    //** Same as @link(SaveToStream) with @link(TglTFSaveOptions.Default).
    //**
    //** @param(AStream Written from its current position; the caller keeps ownership.)
    //**
    //** @param(AFormat gffJSON or gffGLB.)
    //**
    //** @raises(EglTFError See the overload with options.)
    /// <summary>Saves to a stream in the given format, with default options.</summary>
    /// <param name="AStream">Written from its current position; the caller keeps
    /// ownership.</param>
    /// <param name="AFormat">gffJSON or gffGLB.</param>
    /// <exception cref="EglTFError">See the overload with options.</exception>
    /// <remarks>Same as <see cref="SaveToStream"/> with
    /// <see cref="TglTFSaveOptions.Default"/>.</remarks>
    procedure SaveToStream(AStream: TStream; AFormat: TglTFFileFormat); overload;

    //** @abstract(Saves to a stream in the given format.)
    //**
    //** A stream has no folder for separate files, so every buffer and image that has data
    //** is put inside it: in a GLB, buffers[0] goes into the BIN chunk; everything else
    //** becomes a data URI, or a buffer for images with Embed set. Only files that could
    //** not be found stay as uri references, which makes @link(SaveComplete) False.
    //**
    //** @param(AStream Written from its current position; the caller keeps ownership.)
    //**
    //** @param(AFormat gffJSON or gffGLB.)
    //**
    //** @param(AOptions How the JSON is laid out; Buffers is ignored.)
    //**
    //** @raises(EglTFError AFormat is gffNone, the objects are not valid glTF, or a GLB's
    //** buffers[0] has no data.)
    /// <summary>Saves to a stream in the given format.</summary>
    /// <param name="AStream">Written from its current position; the caller keeps
    /// ownership.</param>
    /// <param name="AFormat">gffJSON or gffGLB.</param>
    /// <param name="AOptions">How the JSON is laid out; Buffers is ignored.</param>
    /// <exception cref="EglTFError">AFormat is gffNone, the objects are not valid glTF, or a
    /// GLB's buffers[0] has no data.</exception>
    /// <remarks>A stream has no folder for separate files, so every buffer and image that
    /// has data is put inside it: in a GLB, buffers[0] goes into the BIN chunk; everything
    /// else becomes a data URI, or a buffer for images with Embed set. Only files that
    /// could not be found stay as uri references, which makes <see cref="SaveComplete"/>
    /// False.</remarks>
    procedure SaveToStream(AStream: TStream; AFormat: TglTFFileFormat;
      const AOptions: TglTFSaveOptions); overload;
    {$ENDREGION}

    //** @abstract(Resolves a buffer or image uri to a file path.)
    //**
    //** The uri is percent-decoded and resolved against @link(BaseDirectory). Data URIs
    //** and absolute paths are returned unchanged. The file does not have to exist.
    //**
    //** @param(AUri A uri as written in the glTF.)
    //**
    //** @returns(The file path, or AUri itself for a data URI.)
    /// <summary>Resolves a buffer or image uri to a file path.</summary>
    /// <param name="AUri">A uri as written in the glTF.</param>
    /// <returns>The file path, or AUri itself for a data URI.</returns>
    /// <remarks>The uri is percent-decoded and resolved against
    /// <see cref="BaseDirectory"/>. Data URIs and absolute paths are returned unchanged.
    /// The file does not have to exist.</remarks>
    function ResolveUri(const AUri: string): string;

    //** @abstract(Returns the bytes of a buffer.)
    //**
    //** The array is the buffer's own Data, not a copy.
    //**
    //** @param(AIndex Index in @code(Root.Buffers).)
    //**
    //** @returns(The buffer's Data, byteLength bytes long.)
    //**
    //** @raises(EglTFError The buffer does not exist or its data is not loaded.)
    /// <summary>Returns the bytes of a buffer.</summary>
    /// <param name="AIndex">Index in <c>Root.Buffers</c>.</param>
    /// <returns>The buffer's Data, byteLength bytes long.</returns>
    /// <exception cref="EglTFError">The buffer does not exist or its data is not
    /// loaded.</exception>
    /// <remarks>The array is the buffer's own Data, not a copy.</remarks>
    function GetBufferData(AIndex: Integer): TBytes;

    {$REGION 'Missing external files'}
    //** @abstract(Lists the external buffer and image files whose data is not loaded.)
    //**
    //** Computed from the current objects each time it is called: every buffer or image
    //** with a uri that is not a data URI and no Data. Images inside a bufferView are not
    //** included.
    //**
    //** @returns(One entry per missing file, buffers first; empty when none is missing.)
    /// <summary>Lists the external buffer and image files whose data is not loaded.</summary>
    /// <returns>One entry per missing file, buffers first; empty when none is
    /// missing.</returns>
    /// <remarks>Computed from the current objects each time it is called: every buffer or
    /// image with a uri that is not a data URI and no Data. Images inside a bufferView are
    /// not included.</remarks>
    function MissingResources: TArray<TglTFMissingResource>;

    //** @abstract(Tells whether any external buffer or image file is missing.)
    //**
    //** @returns(True when @link(MissingResources) is not empty.)
    /// <summary>Tells whether any external buffer or image file is missing.</summary>
    /// <returns>True when <see cref="MissingResources"/> is not empty.</returns>
    function HasMissingResources: Boolean;

    //** @abstract(Loads the data of a buffer or image from a file the caller found.)
    //**
    //** The uri in the glTF is not changed. The file becomes the object's SourceFile, so a
    //** later save copies it next to the output if it is to be a separate file there.
    //**
    //** @param(AKind Whether AIndex is a buffer or an image.)
    //**
    //** @param(AIndex Index in @code(Root.Buffers) or @code(Root.Images).)
    //**
    //** @param(AFileName The file to read.)
    //**
    //** @raises(EglTFError The file does not exist, AIndex is out of range, or a buffer
    //** file is smaller than the buffer's byteLength.)
    /// <summary>Loads the data of a buffer or image from a file the caller found.</summary>
    /// <param name="AKind">Whether AIndex is a buffer or an image.</param>
    /// <param name="AIndex">Index in <c>Root.Buffers</c> or <c>Root.Images</c>.</param>
    /// <param name="AFileName">The file to read.</param>
    /// <exception cref="EglTFError">The file does not exist, AIndex is out of range, or a
    /// buffer file is smaller than the buffer's byteLength.</exception>
    /// <remarks>The uri in the glTF is not changed. The file becomes the object's
    /// SourceFile, so a later save copies it next to the output if it is to be a separate
    /// file there.</remarks>
    procedure SupplyResourceFile(AKind: TglTFResourceKind; AIndex: Integer;
      const AFileName: string);

    //** @abstract(Looks for every missing file in a folder and loads those it finds.)
    //**
    //** For each missing file it tries, in order: the uri's relative path inside
    //** ADirectory, the file name directly in ADirectory, then (when ARecursive) the file
    //** name in any sub-folder. Names are compared ignoring case on every platform. A
    //** candidate that cannot be used, such as a buffer file that is too small, is skipped.
    //** Sub-folders that cannot be read are ignored.
    //**
    //** @param(ADirectory The folder to search.)
    //**
    //** @param(ARecursive Also search sub-folders; this can be slow on large folders.)
    //**
    //** @returns(How many missing files were found and loaded; 0 when ADirectory does
    //** not exist.)
    /// <summary>Looks for every missing file in a folder and loads those it finds.</summary>
    /// <param name="ADirectory">The folder to search.</param>
    /// <param name="ARecursive">Also search sub-folders; this can be slow on large
    /// folders.</param>
    /// <returns>How many missing files were found and loaded; 0 when ADirectory does not
    /// exist.</returns>
    /// <remarks>For each missing file it tries, in order: the uri's relative path inside
    /// ADirectory, the file name directly in ADirectory, then (when ARecursive) the file
    /// name in any sub-folder. Names are compared ignoring case on every platform. A
    /// candidate that cannot be used, such as a buffer file that is too small, is skipped.
    /// Sub-folders that cannot be read are ignored.</remarks>
    function SearchMissingResources(const ADirectory: string; ARecursive: Boolean = True): Integer;
    {$ENDREGION}

    //** @abstract(The glTF object tree; never nil.)
    //**
    //** Owned by the document. Replaced by every successful load and by @link(Clear), which
    //** makes references to the old tree's objects invalid.
    /// <summary>The glTF object tree; never nil.</summary>
    /// <remarks>Owned by the document. Replaced by every successful load and by
    /// <see cref="Clear"/>, which makes references to the old tree's objects
    /// invalid.</remarks>
    property Root: TglTF read FRoot;

    //** @abstract(Full path of the loaded file; empty when loaded from anything else.)
    /// <summary>Full path of the loaded file; empty when loaded from anything else.</summary>
    property FileName: string read FFileName;

    //** @abstract(Folder that relative uris are resolved against.)
    //**
    //** Set by @link(LoadFromFile) to the file's folder. Set it before the other load
    //** methods when the asset refers to external files.
    /// <summary>Folder that relative uris are resolved against.</summary>
    /// <remarks>Set by <see cref="LoadFromFile"/> to the file's folder. Set it before the
    /// other load methods when the asset refers to external files.</remarks>
    property BaseDirectory: string read FBaseDirectory write FBaseDirectory;

    //** @abstract(Format of the loaded asset; gffNone when nothing is loaded.)
    /// <summary>Format of the loaded asset; gffNone when nothing is loaded.</summary>
    property FileFormat: TglTFFileFormat read FFormat;

    //** @abstract(True when the loaded GLB had a BIN chunk.)
    /// <summary>True when the loaded GLB had a BIN chunk.</summary>
    property HasBinaryChunk: Boolean read FHasBinaryChunk;

    //** @abstract(Size of the loaded GLB BIN chunk in bytes, padding included; 0 otherwise.)
    /// <summary>Size of the loaded GLB BIN chunk in bytes, padding included; 0
    /// otherwise.</summary>
    property BinaryChunkLength: Int64 read FBinaryChunkLength;

    //** @abstract(Size of the loaded GLB JSON chunk in bytes; 0 for .gltf.)
    /// <summary>Size of the loaded GLB JSON chunk in bytes; 0 for .gltf.</summary>
    property JSONChunkLength: Int64 read FJSONChunkLength;

    //** @abstract(Reads external buffer and image files while loading; True by default.)
    //**
    //** When False, external files are not read and appear in @link(MissingResources).
    //** A later save to a file still copies them from their original location.
    /// <summary>Reads external buffer and image files while loading; True by
    /// default.</summary>
    /// <remarks>When False, external files are not read and appear in
    /// <see cref="MissingResources"/>. A later save to a file still copies them from their
    /// original location.</remarks>
    property LoadExternalResources: Boolean read FLoadExternalResources write FLoadExternalResources;

    //** @abstract(Occurs as loading progresses: reading, parsing, building the objects and
    //** loading each buffer and image.)
    //**
    //** Called on the thread that loads; see @link(TglTFProgressEvent). The last call of a
    //** successful load has Done = 1 and says how many animations the model has.
    /// <summary>Occurs as loading progresses: reading, parsing, building the objects and
    /// loading each buffer and image.</summary>
    /// <remarks>Called on the thread that loads; see <see cref="TglTFProgressEvent"/>. The
    /// last call of a successful load has Done = 1 and says how many animations the model
    /// has.</remarks>
    property OnProgress: TglTFProgressEvent read FOnProgress write FOnProgress;

    //** @abstract(Non-fatal problems found by the last load, one per line.)
    //**
    //** For example a missing texture file. Owned by the document.
    /// <summary>Non-fatal problems found by the last load, one per line.</summary>
    /// <remarks>For example a missing texture file. Owned by the document.</remarks>
    property Warnings: TStringList read FWarnings;

    //** @abstract(Non-fatal problems found by the last save, one per line.)
    //**
    //** Includes every file the saved glTF refers to that could not be found. Owned by the
    //** document; cleared at the start of each save.
    /// <summary>Non-fatal problems found by the last save, one per line.</summary>
    /// <remarks>Includes every file the saved glTF refers to that could not be found. Owned
    /// by the document; cleared at the start of each save.</remarks>
    property SaveWarnings: TStringList read FSaveWarnings;

    //** @abstract(What the last save did with each separate buffer and image file.)
    //**
    //** One line per file, for example "textures/brick.png: copied from D:\found\brick.png",
    //** "...: written from embedded data" or "...: already in place". Empty after a save to
    //** a stream. Owned by the document; cleared at the start of each save.
    /// <summary>What the last save did with each separate buffer and image file.</summary>
    /// <remarks>One line per file, for example "textures/brick.png: copied from
    /// D:\found\brick.png", "...: written from embedded data" or "...: already in place".
    /// Empty after a save to a stream. Owned by the document; cleared at the start of each
    /// save.</remarks>
    property SavedFiles: TStringList read FSavedFiles;

    //** @abstract(True when the last save is file-complete.)
    //**
    //** File-complete means every file the saved glTF refers to exists next to it, so it
    //** loads without missing files. False when a referenced file could not be found;
    //** @link(SaveWarnings) names it.
    /// <summary>True when the last save is file-complete.</summary>
    /// <remarks>File-complete means every file the saved glTF refers to exists next to it,
    /// so it loads without missing files. False when a referenced file could not be found;
    /// <see cref="SaveWarnings"/> names it.</remarks>
    property SaveComplete: Boolean read FSaveComplete;
  end;


implementation

uses
  System.NetEncoding, System.StrUtils,
  Neon.Core.Persistence.JSON,
  glTF.Edit, glTF.Orient;

const
  GLB_MAGIC: array[0..3] of Byte = ($67, $6C, $54, $46); // 'glTF'
  UTF8_BOM: array[0..2] of Byte = ($EF, $BB, $BF);

  GLB_HEADER_SIZE = 12;
  GLB_CHUNK_HEADER_SIZE = 8;
  GLB_VERSION = 2;
  GLB_CHUNK_JSON = $4E4F534A; // 'JSON'
  GLB_CHUNK_BIN  = $004E4942; // 'BIN'#0

  OCTET_STREAM = 'application/octet-stream';

{ Helpers }

// <summary>
//   RFC 3986 percent-decoding (UTF-8). Unlike form decoding, '+' is kept
// </summary>
function PercentDecode(const AValue: string): string;
var
  LSource: TBytes;
  LResult: TBytes;
  LCount, I, LByte: Integer;
begin
  if AValue.IndexOf('%') < 0 then
    Exit(AValue);

  LSource := TEncoding.UTF8.GetBytes(AValue);
  SetLength(LResult, Length(LSource));
  LCount := 0;
  I := 0;
  while I < Length(LSource) do
  begin
    if (LSource[I] = Ord('%')) and (I + 2 < Length(LSource)) and
       TryStrToInt('$' + Char(LSource[I + 1]) + Char(LSource[I + 2]), LByte) then
    begin
      LResult[LCount] := Byte(LByte);
      Inc(I, 3);
    end
    else
    begin
      LResult[LCount] := LSource[I];
      Inc(I);
    end;
    Inc(LCount);
  end;
  Result := TEncoding.UTF8.GetString(LResult, 0, LCount);
end;

// <summary>Percent-encodes a relative path for use as a URI ('/' is kept)</summary>
function PercentEncodePath(const APath: string): string;
var
  LByte: Byte;
begin
  Result := '';
  for LByte in TEncoding.UTF8.GetBytes(APath.Replace('\', '/')) do
    if CharInSet(Char(LByte), ['A'..'Z', 'a'..'z', '0'..'9', '-', '.', '_', '~', '/']) then
      Result := Result + Char(LByte)
    else
      Result := Result + '%' + IntToHex(LByte, 2);
end;

function ReadUInt32LE(const ABytes: TBytes; AOffset: Int64): Cardinal;
begin
  Result := Cardinal(ABytes[AOffset]) or
    (Cardinal(ABytes[AOffset + 1]) shl 8) or
    (Cardinal(ABytes[AOffset + 2]) shl 16) or
    (Cardinal(ABytes[AOffset + 3]) shl 24);
end;

procedure WriteUInt32LE(AStream: TStream; AValue: Cardinal);
var
  LBytes: array[0..3] of Byte;
begin
  LBytes[0] := Byte(AValue);
  LBytes[1] := Byte(AValue shr 8);
  LBytes[2] := Byte(AValue shr 16);
  LBytes[3] := Byte(AValue shr 24);
  AStream.WriteBuffer(LBytes, 4);
end;

function ChunkTypeName(AType: Cardinal): string;
begin
  case AType of
    GLB_CHUNK_JSON: Result := 'JSON';
    GLB_CHUNK_BIN: Result := 'BIN';
  else
    Result := '0x' + IntToHex(AType, 8);
  end;
end;

function ResolveUriAgainst(const ABaseDir, AUri: string): string;
var
  LPath: string;
begin
  // URIs in glTF are percent-encoded and use '/' as separator
  LPath := PercentDecode(AUri).Replace('/', PathDelim);
  if (ABaseDir = '') or TPath.IsPathRooted(LPath) then
    Result := LPath
  else
    Result := TPath.Combine(ABaseDir, LPath);
end;

// <summary>
//   A relative URI that stays inside the output folder (no scheme, not
//   rooted, no ".."), so it can be written next to the output
// </summary>
// An existing folder matching APath; where the exact name is not found the
// names are compared without case, folder by folder, as glTF files made on
// Windows often differ in case from the files on case-sensitive file systems
// (Linux, Android, iOS). '' when there is none
function ExistingDirectory(const APath: string): string;
var
  LParent, LName, LEntry: string;
begin
  Result := '';
  if APath = '' then
    Exit;
  if TDirectory.Exists(APath) then
    Exit(APath);
  LParent := TPath.GetDirectoryName(APath);
  LName := TPath.GetFileName(APath);
  if (LParent = '') or (LParent = APath) or (LName = '') then
    Exit;
  LParent := ExistingDirectory(LParent);
  if LParent = '' then
    Exit;
  try
    for LEntry in TDirectory.GetDirectories(LParent) do
      if SameText(TPath.GetFileName(LEntry), LName) then
        Exit(LEntry);
  except
    // a folder that cannot be listed: no match
  end;
end;

// An existing file matching APath, with the same case-insensitive fallback
// as ExistingDirectory; '' when there is none
function ExistingFile(const APath: string): string;
var
  LDir, LName, LEntry: string;
begin
  Result := '';
  if APath = '' then
    Exit;
  if TFile.Exists(APath) then
    Exit(APath);
  LName := TPath.GetFileName(APath);
  LDir := ExistingDirectory(TPath.GetDirectoryName(APath));
  if (LDir = '') or (LName = '') then
    Exit;
  try
    for LEntry in TDirectory.GetFiles(LDir) do
      if SameText(TPath.GetFileName(LEntry), LName) then
        Exit(LEntry);
  except
    // a folder that cannot be listed: no match
  end;
end;

// A relative uri without a scheme; unlike IsSafeRelativeUri it may lead
// outside the output folder with ".."
function IsRelativeUri(const AUri: string): Boolean;
begin
  Result := (AUri <> '') and not AUri.StartsWith('data:', True) and (AUri.IndexOf(':') < 0) and
    not PercentDecode(AUri).Replace('\', '/').StartsWith('/');
end;

function IsSafeRelativeUri(const AUri: string): Boolean;
var
  LPath: string;
  LPart: string;
begin
  if (AUri = '') or AUri.StartsWith('data:', True) or (AUri.IndexOf(':') >= 0) then
    Exit(False);
  LPath := PercentDecode(AUri).Replace('\', '/');
  if LPath.StartsWith('/') then
    Exit(False);
  for LPart in LPath.Split(['/']) do
    if LPart = '..' then
      Exit(False);
  Result := True;
end;

// <summary>Decodes a base64 data URI; APath locates it for error messages</summary>
function DecodeDataUri(const AUri, APath: string): TBytes;
var
  LComma: Integer;
begin
  LComma := AUri.IndexOf(',');
  if LComma < 0 then
    raise EglTFParseError.Create(APath, 'Malformed data URI (no comma)');
  if not AUri.Substring(0, LComma).EndsWith(';base64', True) then
    raise EglTFParseError.Create(APath, 'Only base64 data URIs are supported');
  Result := TNetEncoding.Base64.DecodeStringToBytes(AUri.Substring(LComma + 1));
end;

function EncodeDataUri(const AMimeType: string; const AData: TBytes): string;
var
  LEncoding: TBase64Encoding;
  LMime: string;
begin
  LMime := AMimeType;
  if LMime = '' then
    LMime := OCTET_STREAM;
  // No line breaks inside a URI
  LEncoding := TBase64Encoding.Create(0, '');
  try
    Result := 'data:' + LMime + ';base64,' + LEncoding.EncodeBytesToString(AData);
  finally
    LEncoding.Free;
  end;
end;

// A name that is a valid file name on every platform: characters Windows
// does not allow become "_", leading/trailing spaces and dots go, and names
// Windows reserves get a "_" in front. '' when nothing usable is left
function SafeFileName(const AName: string): string;
const
  RESERVED: array[0..21] of string = ('CON', 'PRN', 'AUX', 'NUL',
    'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
    'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9');
var
  LChar: Char;
  LBase, LReserved: string;
begin
  Result := '';
  for LChar in AName do
    if (LChar < ' ') or CharInSet(LChar, ['\', '/', ':', '*', '?', '"', '<', '>', '|']) then
      Result := Result + '_'
    else
      Result := Result + LChar;
  Result := Result.Trim([' ', '.']);
  if Length(Result) > 100 then
    Result := Result.Substring(0, 100).TrimRight([' ', '.']);
  if Result = '' then
    Exit;
  LBase := Result;
  if LBase.IndexOf('.') >= 0 then
    LBase := LBase.Substring(0, LBase.IndexOf('.'));
  for LReserved in RESERVED do
    if SameText(LBase, LReserved) then
      Exit('_' + Result);
end;

// Splits "dir/name.ext" into "dir/name" and ".ext" (separators are "/")
procedure SplitExtension(const APath: string; out AStem, AExt: string);
var
  LSlash, LDot: Integer;
begin
  LSlash := APath.LastIndexOf('/');
  LDot := APath.LastIndexOf('.');
  if LDot > LSlash + 1 then
  begin
    AStem := APath.Substring(0, LDot);
    AExt := APath.Substring(LDot);
  end
  else
  begin
    AStem := APath;
    AExt := '';
  end;
end;

function BytesEqual(const A, B: TBytes): Boolean;
begin
  Result := (Length(A) = Length(B)) and
    ((Length(A) = 0) or CompareMem(@A[0], @B[0], Length(A)));
end;

function ImageExtension(const AMimeType: string): string;
begin
  if SameText(AMimeType, 'image/png') then Result := '.png'
  else if SameText(AMimeType, 'image/jpeg') then Result := '.jpg'
  else if SameText(AMimeType, 'image/webp') then Result := '.webp'
  else if SameText(AMimeType, 'image/ktx2') then Result := '.ktx2'
  else Result := '.bin';
end;

{ EglTFGLBError }

constructor EglTFGLBError.Create(const AMessage: string; AByteOffset: Int64);
begin
  inherited CreateFmt('Invalid GLB: %s (byte offset %d)', [AMessage, AByteOffset]);
  FByteOffset := AByteOffset;
end;

{ TglTFSaveOptions }

function TglTFProgress.Overall: Double;
begin
  if ModelCount <= 0 then
    Exit(0);
  Result := (ModelIndex - 1 + Done) / ModelCount;
  if Result < 0 then
    Result := 0
  else if Result > 1 then
    Result := 1;
end;

function TglTFProgress.ModelText: string;
begin
  Result := Format('Model %d of %d', [ModelIndex, ModelCount]);
  if ModelName <> '' then
    Result := Result + ': ' + ModelName;
end;

class function TglTFSaveOptions.Default: TglTFSaveOptions;
begin
  Result.Buffers := rmKeep;
  Result.PrettyPrint := True;
  Result.LeaveOutUnusedImages := True;
  Result.ImageSaveMode := ismByFormat;
  Result.RotateX := 0;
  Result.RotateY := 0;
  Result.RotateZ := 0;
end;

{ TglTFMissingResource }

function TglTFMissingResource.FileName: string;
begin
  Result := ExtractFileName(PercentDecode(Uri).Replace('/', PathDelim));
end;

function TglTFMissingResource.Description: string;
const
  KIND_NAMES: array[TglTFResourceKind] of string = ('Buffer', 'Image');
begin
  Result := Format('%s %d "%s"', [KIND_NAMES[Kind], Index, FileName]);
end;

{ TglTFDocument }

constructor TglTFDocument.Create;
begin
  inherited Create;
  FRoot := TglTF.Create;
  FWarnings := TStringList.Create;
  FSaveWarnings := TStringList.Create;
  FSavedFiles := TStringList.Create;
  FLoadExternalResources := True;
end;

destructor TglTFDocument.Destroy;
begin
  FSavedFiles.Free;
  FSaveWarnings.Free;
  FWarnings.Free;
  FRoot.Free;
  inherited;
end;

class function TglTFDocument.CreateFromFile(const AFileName: string): TglTFDocument;
begin
  Result := TglTFDocument.Create;
  try
    Result.LoadFromFile(AFileName);
  except
    Result.Free;
    raise;
  end;
end;

class function TglTFDocument.CreateFromStream(AStream: TStream): TglTFDocument;
begin
  Result := TglTFDocument.Create;
  try
    Result.LoadFromStream(AStream);
  except
    Result.Free;
    raise;
  end;
end;

class function TglTFDocument.IsGLBData(const ABytes: TBytes): Boolean;
begin
  Result := (Length(ABytes) >= 4) and CompareMem(@ABytes[0], @GLB_MAGIC[0], 4);
end;

class function TglTFDocument.FormatFromFileName(const AFileName: string): TglTFFileFormat;
var
  LExt: string;
begin
  LExt := LowerCase(ExtractFileExt(AFileName));
  if LExt = '.glb' then
    Result := gffGLB
  else if LExt = '.gltf' then
    Result := gffJSON
  else
    Result := gffNone;
end;

procedure TglTFDocument.ReplaceRoot(ANewRoot: TglTF);
begin
  FRoot.Free;
  FRoot := ANewRoot;
end;

procedure TglTFDocument.DoProgress(const AStage: string; ADone: Double);
var
  LProgress: TglTFProgress;
begin
  if not Assigned(FOnProgress) then
    Exit;
  LProgress.ModelIndex := 1;
  LProgress.ModelCount := 1;
  LProgress.ModelName := FProgressName;
  LProgress.Stage := AStage;
  LProgress.Done := ADone;
  FOnProgress(Self, LProgress);
end;

procedure TglTFDocument.Clear;
begin
  ReplaceRoot(TglTF.Create);
  FFileName := '';
  FBaseDirectory := '';
  FFormat := gffNone;
  FHasBinaryChunk := False;
  FBinaryChunkLength := 0;
  FJSONChunkLength := 0;
  FWarnings.Clear;
end;

{ Loading }

procedure TglTFDocument.LoadFromFile(const AFileName: string);
var
  LStream: TFileStream;
  LFullName, LDir: string;
begin
  LFullName := TPath.GetFullPath(AFileName);
  LDir := TPath.GetDirectoryName(LFullName);
  FProgressName := TPath.GetFileName(LFullName);
  DoProgress('Reading the file', 0);
  LStream := TFileStream.Create(LFullName, fmOpenRead or fmShareDenyWrite);
  try
    LoadStream(LStream, TPath.GetFileName(LFullName), LDir);
  finally
    LStream.Free;
  end;
  FFileName := LFullName;
  FBaseDirectory := LDir;
end;

procedure TglTFDocument.LoadFromStream(AStream: TStream);
begin
  LoadStream(AStream, '', FBaseDirectory);
  FFileName := '';
end;

procedure TglTFDocument.LoadFromString(const AJSONText: string);
begin
  LoadText(AJSONText, '', FBaseDirectory, gffJSON, nil, False);
  FFileName := '';
end;

procedure TglTFDocument.LoadFromGLBBytes(const ABytes: TBytes);
begin
  LoadGLB(ABytes, '', FBaseDirectory);
  FFileName := '';
end;

procedure TglTFDocument.LoadStream(AStream: TStream; const ASourceName, ABaseDir: string);
var
  LBytes: TBytes;
  LSize: Int64;
  LOffset: Integer;
begin
  if AStream = nil then
    raise EglTFError.Create('glTF stream is nil');

  LSize := AStream.Size - AStream.Position;
  if LSize <= 0 then
    raise EglTFParseError.Create('', 'glTF stream is empty');

  SetLength(LBytes, LSize);
  AStream.ReadBuffer(LBytes[0], LSize);

  if IsGLBData(LBytes) then
  begin
    LoadGLB(LBytes, ASourceName, ABaseDir);
    Exit;
  end;

  // glTF JSON must be UTF-8 without BOM; tolerate a BOM anyway
  LOffset := 0;
  if (LSize >= 3) and CompareMem(@LBytes[0], @UTF8_BOM[0], 3) then
    LOffset := 3;

  LoadText(TEncoding.UTF8.GetString(LBytes, LOffset, Length(LBytes) - LOffset),
    ASourceName, ABaseDir, gffJSON, nil, False);
end;

procedure TglTFDocument.LoadGLB(const ABytes: TBytes; const ASourceName, ABaseDir: string);
var
  LTotal, LOffset: Int64;
  LVersion, LDeclared, LChunkLength, LChunkType: Cardinal;
  LChunkIndex: Integer;
  LJSONText, LSourceName: string;
  LHasJSON, LHasBinary: Boolean;
  LBinary: TBytes;
  LJSONLength: Int64;
begin
  LTotal := Length(ABytes);
  if LTotal < GLB_HEADER_SIZE then
    raise EglTFGLBError.Create(Format('the data is %d bytes, too short for the 12-byte GLB header',
      [LTotal]), 0);
  if not IsGLBData(ABytes) then
    raise EglTFGLBError.Create('missing "glTF" magic', 0);

  LVersion := ReadUInt32LE(ABytes, 4);
  if LVersion <> GLB_VERSION then
    raise EglTFGLBError.Create(Format('unsupported GLB container version %d (only %d is supported)',
      [LVersion, GLB_VERSION]), 4);

  // header.length is the size of the whole GLB, header included
  LDeclared := ReadUInt32LE(ABytes, 8);
  if LDeclared < GLB_HEADER_SIZE then
    raise EglTFGLBError.Create(Format('header length %d is smaller than the header itself',
      [LDeclared]), 8);
  if LDeclared > LTotal then
    raise EglTFGLBError.Create(Format('header length is %d bytes but only %d are available (truncated file?)',
      [LDeclared, LTotal]), 8);
  LTotal := LDeclared;

  LOffset := GLB_HEADER_SIZE;
  LChunkIndex := 0;
  LHasJSON := False;
  LHasBinary := False;
  LBinary := nil;
  LJSONLength := 0;

  while LOffset < LTotal do
  begin
    if LTotal - LOffset < GLB_CHUNK_HEADER_SIZE then
      raise EglTFGLBError.Create(Format('incomplete header for chunk %d', [LChunkIndex]), LOffset);

    LChunkLength := ReadUInt32LE(ABytes, LOffset);
    LChunkType := ReadUInt32LE(ABytes, LOffset + 4);
    if LChunkLength > LTotal - LOffset - GLB_CHUNK_HEADER_SIZE then
      raise EglTFGLBError.Create(Format('chunk %d (%s) declares %d bytes but only %d remain',
        [LChunkIndex, ChunkTypeName(LChunkType), LChunkLength,
         LTotal - LOffset - GLB_CHUNK_HEADER_SIZE]), LOffset);
    Inc(LOffset, GLB_CHUNK_HEADER_SIZE);

    if LChunkIndex = 0 then
    begin
      if LChunkType <> GLB_CHUNK_JSON then
        raise EglTFGLBError.Create(Format('the first chunk must be JSON, found %s',
          [ChunkTypeName(LChunkType)]), LOffset - GLB_CHUNK_HEADER_SIZE);
      if LChunkLength > 0 then
        LJSONText := TEncoding.UTF8.GetString(ABytes, LOffset, LChunkLength).TrimRight
      else
        LJSONText := '';
      LJSONLength := LChunkLength;
      LHasJSON := True;
    end
    else if LChunkType = GLB_CHUNK_JSON then
      raise EglTFGLBError.Create('more than one JSON chunk', LOffset - GLB_CHUNK_HEADER_SIZE)
    else if LChunkType = GLB_CHUNK_BIN then
    begin
      if LHasBinary then
        raise EglTFGLBError.Create('more than one BIN chunk', LOffset - GLB_CHUNK_HEADER_SIZE);
      if LChunkIndex <> 1 then
        raise EglTFGLBError.Create('the BIN chunk must directly follow the JSON chunk',
          LOffset - GLB_CHUNK_HEADER_SIZE);
      SetLength(LBinary, LChunkLength);
      if LChunkLength > 0 then
        Move(ABytes[LOffset], LBinary[0], LChunkLength);
      LHasBinary := True;
    end;
    // Chunks of any other type are ignored, as the spec requires

    Inc(LOffset, LChunkLength);
    Inc(LChunkIndex);
  end;

  if not LHasJSON then
    raise EglTFGLBError.Create('no JSON chunk', GLB_HEADER_SIZE);

  if ASourceName <> '' then
    LSourceName := ASourceName + ', JSON chunk'
  else
    LSourceName := 'GLB JSON chunk';

  LoadText(LJSONText, LSourceName, ABaseDir, gffGLB, LBinary, LHasBinary);
  FJSONChunkLength := LJSONLength;
  FBinaryChunkLength := Length(LBinary);
end;

function TglTFDocument.CreateRoot(AJSON: TJSONValue): TglTF;
begin
  Result := TglTF.Create;
  try
    Result.LoadFromJSON(AJSON, '');
  except
    Result.Free;
    raise;
  end;
end;

procedure TglTFDocument.ValidateGLBBuffers(ARoot: TglTF; const ABinary: TBytes;
  AHasBinary: Boolean);
var
  LBuffer: TglTFBuffer;
begin
  // Only buffers[0] may refer to the BIN chunk, by leaving uri undefined
  if (ARoot.Buffers.Count = 0) or ARoot.Buffers[0].IsDefined('uri') then
    Exit;

  LBuffer := ARoot.Buffers[0];
  if not AHasBinary then
    raise EglTFParseError.Create('buffers[0]',
      'buffers[0] has no uri, so its data must be in the GLB BIN chunk, but the file has no BIN chunk');

  if LBuffer.ByteLength > Length(ABinary) then
    raise EglTFParseError.Create('buffers[0].byteLength', Format(
      'buffers[0].byteLength is %d but the GLB BIN chunk only holds %d bytes',
      [LBuffer.ByteLength, Length(ABinary)]));

  // The chunk may only be longer by its 4-byte alignment padding
  if Length(ABinary) - LBuffer.ByteLength > 3 then
    raise EglTFParseError.Create('buffers[0].byteLength', Format(
      'the GLB BIN chunk (%d bytes) is more than 3 bytes larger than buffers[0].byteLength (%d)',
      [Length(ABinary), LBuffer.ByteLength]));
end;

procedure TglTFDocument.LoadResources(ARoot: TglTF; const ABinary: TBytes;
  AHasBinary: Boolean; const ABaseDir: string; AWarnings: TStrings);
var
  I: Integer;
  LBuffer: TglTFBuffer;
  LImage: TglTFImage;
  LView: TglTFBufferView;
  LData, LSource: TBytes;
  LPath: string;
  LTotal: Integer;
begin
  // Progress: the data takes the part of the load from 0.5 to 1
  LTotal := ARoot.Buffers.Count + ARoot.Images.Count;
  for I := 0 to ARoot.Buffers.Count - 1 do
  begin
    DoProgress(Format('Loading buffer %d of %d', [I + 1, ARoot.Buffers.Count]),
      0.5 + 0.5 * I / LTotal);
    LBuffer := ARoot.Buffers[I];
    LData := nil;

    if not LBuffer.IsDefined('uri') then
    begin
      if (I = 0) and AHasBinary then
        LData := Copy(ABinary, 0, LBuffer.ByteLength)
      else
        AWarnings.Add(Format('Buffer %d has no uri and no GLB BIN chunk: its data is not available', [I]));
    end
    else if LBuffer.IsDataUri then
    begin
      LData := DecodeDataUri(LBuffer.Uri, Format('buffers[%d].uri', [I]));
      if Length(LData) < LBuffer.ByteLength then
        raise EglTFParseError.Create(Format('buffers[%d].byteLength', [I]), Format(
          'byteLength is %d but the data URI only holds %d bytes', [LBuffer.ByteLength, Length(LData)]));
      SetLength(LData, LBuffer.ByteLength);
    end
    else if FLoadExternalResources then
    begin
      LPath := ResolveUriAgainst(ABaseDir, LBuffer.Uri);
      if ExistingFile(LPath) <> '' then
        LPath := ExistingFile(LPath);
      if TFile.Exists(LPath) then
      begin
        LData := TFile.ReadAllBytes(LPath);
        if Length(LData) < LBuffer.ByteLength then
        begin
          AWarnings.Add(Format('Buffer %d: %s holds %d bytes, byteLength is %d',
            [I, LPath, Length(LData), LBuffer.ByteLength]));
          LData := nil;
        end
        else
        begin
          SetLength(LData, LBuffer.ByteLength);
          LBuffer.SourceFile := LPath;
        end;
      end
      else
        AWarnings.Add(Format('Buffer %d: file not found: %s', [I, LPath]));
    end;

    LBuffer.Data := LData;
  end;

  for I := 0 to ARoot.Images.Count - 1 do
  begin
    DoProgress(Format('Loading image %d of %d', [I + 1, ARoot.Images.Count]),
      0.5 + 0.5 * (ARoot.Buffers.Count + I) / LTotal);
    LImage := ARoot.Images[I];
    LData := nil;
    // Images that are inside the file start out embedded
    LImage.Embed := LImage.IsDataUri or (LImage.BufferView <> GLTF_UNDEFINED_INDEX);

    if LImage.BufferView <> GLTF_UNDEFINED_INDEX then
    begin
      // A copy of the bytes, so the image can also be written as a file
      if (LImage.BufferView < ARoot.BufferViews.Count) then
      begin
        LView := ARoot.BufferViews[LImage.BufferView];
        if (LView.Buffer >= 0) and (LView.Buffer < ARoot.Buffers.Count) then
        begin
          LSource := ARoot.Buffers[LView.Buffer].Data;
          if (LSource <> nil) and (LView.ByteOffset + LView.ByteLength <= Length(LSource)) then
            LData := Copy(LSource, LView.ByteOffset, LView.ByteLength)
          else if LSource <> nil then
            AWarnings.Add(Format('Image %d: bufferView %d lies outside buffer %d',
              [I, LImage.BufferView, LView.Buffer]));
        end;
      end;
    end
    else if LImage.IsDefined('uri') then
    begin
      if LImage.IsDataUri then
        LData := DecodeDataUri(LImage.Uri, Format('images[%d].uri', [I]))
      else if FLoadExternalResources then
      begin
        LPath := ResolveUriAgainst(ABaseDir, LImage.Uri);
        if ExistingFile(LPath) <> '' then
          LPath := ExistingFile(LPath);
        if TFile.Exists(LPath) then
        begin
          LData := TFile.ReadAllBytes(LPath);
          LImage.SourceFile := LPath;
        end
        else
          AWarnings.Add(Format('Image %d: file not found: %s', [I, LPath]));
      end;
    end;
    LImage.Data := LData;
  end;
end;

procedure TglTFDocument.LoadText(const AJSONText, ASourceName, ABaseDir: string;
  AFormat: TglTFFileFormat; const ABinary: TBytes; AHasBinary: Boolean);
var
  LJSON: TJSONValue;
  LError: EglTFParseError;
  LMap: TglTFSourceMap;
  LSpan: TglTFSourceSpan;
  LNewRoot: TglTF;
  LWarnings: TStringList;
begin
  FProgressName := ASourceName;
  DoProgress('Parsing the JSON', 0.1);

  // 1. JSON syntax: System.JSON reports its own line and position
  try
    LJSON := TJSONObject.ParseJSONValue(AJSONText, False, True);
  except
    on E: EJSONParseException do
    begin
      LError := EglTFParseError.Create('', 'Invalid JSON: ' + E.Message);
      LError.SetSourceLocation(ASourceName, E.Line, E.Position);
      raise LError;
    end;
    on E: EJSONException do
      raise EglTFParseError.Create('', 'Invalid JSON: ' + E.Message);
  end;

  if LJSON = nil then
    raise EglTFParseError.Create('', 'Invalid JSON');

  LWarnings := TStringList.Create;
  try
    // 2. glTF content, GLB buffer rules and resource data: map the error's
    //    JSON path back to the text. The new tree replaces the current one
    //    only on success
    try
      try
        DoProgress('Building the objects', 0.3);
        LNewRoot := CreateRoot(LJSON);
        try
          DoProgress(Format('Found %d animation(s); loading the data',
            [LNewRoot.Animations.Count]), 0.5);
          if AFormat = gffGLB then
            ValidateGLBBuffers(LNewRoot, ABinary, AHasBinary);
          LoadResources(LNewRoot, ABinary, AHasBinary, ABaseDir, LWarnings);
        except
          LNewRoot.Free;
          raise;
        end;
      except
        on E: EglTFError do
        begin
          if not E.HasSourceLocation then
          begin
            LMap := TglTFSourceMap.Create(AJSONText);
            try
              if LMap.TryFind(E.JSONPath, LSpan) then
                E.SetSourceLocation(ASourceName, LSpan.StartLine, LSpan.StartColumn,
                  LSpan.EndLine);
            finally
              LMap.Free;
            end;
          end;
          raise;
        end;
      end;
    finally
      LJSON.Free;
    end;

    ReplaceRoot(LNewRoot);
    FFormat := AFormat;
    FHasBinaryChunk := AHasBinary;
    FBinaryChunkLength := 0;
    FJSONChunkLength := 0;
    FWarnings.Assign(LWarnings);
  finally
    LWarnings.Free;
  end;
  DoProgress(Format('Loaded: %d animation(s)', [FRoot.Animations.Count]), 1);
end;

procedure TglTFDocument.LoadFromJSON(AJSON: TJSONValue);
var
  LNewRoot: TglTF;
  LWarnings: TStringList;
begin
  LWarnings := TStringList.Create;
  try
    LNewRoot := CreateRoot(AJSON);
    try
      LoadResources(LNewRoot, nil, False, FBaseDirectory, LWarnings);
    except
      LNewRoot.Free;
      raise;
    end;
    ReplaceRoot(LNewRoot);
    FFormat := gffJSON;
    FHasBinaryChunk := False;
    FBinaryChunkLength := 0;
    FJSONChunkLength := 0;
    FWarnings.Assign(LWarnings);
  finally
    LWarnings.Free;
  end;
end;

{ Saving }

procedure TglTFDocument.SaveToFile(const AFileName: string);
begin
  SaveToFile(AFileName, TglTFSaveOptions.Default);
end;

procedure TglTFDocument.SaveToFile(const AFileName: string; const AOptions: TglTFSaveOptions);
var
  LFormat: TglTFFileFormat;
  LFullName: string;
  LStream: TMemoryStream;
begin
  LFormat := FormatFromFileName(AFileName);
  if LFormat = gffNone then
    raise EglTFError.CreateFmt('Cannot tell the glTF format from "%s": use a .gltf or .glb extension',
      [ExtractFileName(AFileName)]);

  LFullName := TPath.GetFullPath(AFileName);
  LStream := TMemoryStream.Create;
  try
    // Built in memory first: external files are written by SaveInternal,
    // the main file only once everything succeeded
    SaveInternal(LStream, LFormat, AOptions, TPath.GetDirectoryName(LFullName),
      TPath.GetFileNameWithoutExtension(LFullName));
    LStream.SaveToFile(LFullName);
  finally
    LStream.Free;
  end;
end;

procedure TglTFDocument.SaveToStream(AStream: TStream; AFormat: TglTFFileFormat);
begin
  SaveToStream(AStream, AFormat, TglTFSaveOptions.Default);
end;

procedure TglTFDocument.SaveToStream(AStream: TStream; AFormat: TglTFFileFormat;
  const AOptions: TglTFSaveOptions);
begin
  if AFormat = gffNone then
    raise EglTFError.Create('Choose gffJSON or gffGLB to save a glTF stream');
  SaveInternal(AStream, AFormat, AOptions, '', '');
end;

function TglTFDocument.CreateSaveCopy: TglTF;
var
  LJSON: TJSONObject;
  I: Integer;
begin
  // A copy of the objects (not of the loaded file): their JSON read back,
  // which also checks the current objects are valid glTF before writing
  LJSON := FRoot.SaveToJSON;
  try
    Result := TglTF.Create;
    try
      try
        Result.LoadFromJSON(LJSON, '');
      except
        on E: EglTFError do
          raise EglTFError.Create('The objects are not valid glTF, nothing was saved: ' + E.Message);
      end;
    except
      Result.Free;
      raise;
    end;
  finally
    LJSON.Free;
  end;

  // Data and the embed choice are not part of the JSON
  for I := 0 to FRoot.Buffers.Count - 1 do
  begin
    Result.Buffers[I].Data := FRoot.Buffers[I].Data;
    Result.Buffers[I].SourceFile := FRoot.Buffers[I].SourceFile;
  end;
  for I := 0 to FRoot.Images.Count - 1 do
  begin
    Result.Images[I].Data := FRoot.Images[I].Data;
    Result.Images[I].Embed := FRoot.Images[I].Embed;
    Result.Images[I].Shared := FRoot.Images[I].Shared;
    Result.Images[I].SourceFile := FRoot.Images[I].SourceFile;
  end;
  for I := 0 to FRoot.Animations.Count - 1 do
  begin
    Result.Animations[I].ExportOnSave := FRoot.Animations[I].ExportOnSave;
    Result.Animations[I].Origin := FRoot.Animations[I].Origin;
  end;
end;

procedure TglTFDocument.LeaveOutUnexportedAnimations(AOut: TglTF);
var
  LAccessors: TArray<Integer>;
  I: Integer;
begin
  // The animations go first, then in one pass the data only they used.
  // Works on the save copy only
  LAccessors := nil;
  for I := AOut.Animations.Count - 1 downto 0 do
    if not AOut.Animations[I].ExportOnSave then
    begin
      LAccessors := LAccessors + TglTFEdit.AnimationAccessors(AOut.Animations[I]);
      AOut.Animations.Delete(I);
    end;
  if LAccessors <> nil then
    TglTFEdit.DeleteUnusedData(AOut, LAccessors, FSaveWarnings);
end;

// The candidate files for an external uri whose data is not loaded: where it
// was found or read from, then its original location
function UnloadedCandidates(const ASourceFile, ABaseDir, AUri: string): TArray<string>;
begin
  Result := nil;
  if ExistingFile(ASourceFile) <> '' then
    Result := Result + [ExistingFile(ASourceFile)];
  if (ABaseDir <> '') and (AUri <> '') and not AUri.StartsWith('data:', True) and
     (ExistingFile(ResolveUriAgainst(ABaseDir, AUri)) <> '') then
    Result := Result + [ExistingFile(ResolveUriAgainst(ABaseDir, AUri))];
end;

procedure TglTFDocument.ReadUnloadedFiles(AOut: TglTF);
var
  LBuffer: TglTFBuffer;
  LImage: TglTFImage;
  LPath: string;
  LData: TBytes;
begin
  // External files not read when loading (LoadExternalResources off, or
  // created since): read them now so the output can be file-complete.
  // Only the save copy gets the data; the document is not changed
  for LBuffer in AOut.Buffers do
    if (LBuffer.Data = nil) and (LBuffer.Uri <> '') and not LBuffer.IsDataUri then
      for LPath in UnloadedCandidates(LBuffer.SourceFile, FBaseDirectory, LBuffer.Uri) do
        if TFile.Exists(LPath) then
        begin
          LData := TFile.ReadAllBytes(LPath);
          if Length(LData) < LBuffer.ByteLength then
            Continue;
          SetLength(LData, LBuffer.ByteLength);
          LBuffer.Data := LData;
          LBuffer.SourceFile := LPath;
          Break;
        end;

  for LImage in AOut.Images do
    if (LImage.Data = nil) and (LImage.BufferView = GLTF_UNDEFINED_INDEX) and
       (LImage.Uri <> '') and not LImage.IsDataUri then
      for LPath in UnloadedCandidates(LImage.SourceFile, FBaseDirectory, LImage.Uri) do
        if TFile.Exists(LPath) then
        begin
          LImage.Data := TFile.ReadAllBytes(LPath);
          LImage.SourceFile := LPath;
          Break;
        end;
end;

procedure TglTFDocument.TakeSeparateImagesOutOfBuffers(AOut: TglTF);
var
  LViews: TList<Integer>;
  LImage: TglTFImage;
  LAccessor: TglTFAccessor;
  LName: string;

  procedure KeepIfUsed(AView: Integer);
  begin
    LViews.Remove(AView);
  end;

begin
  // An image with Embed off is written as a separate file, so its bytes must
  // not stay in a buffer as well. Works on the save copy only
  LViews := TList<Integer>.Create;
  try
    for LImage in AOut.Images do
      if not LImage.Embed and (LImage.Data <> nil) and
         (LImage.BufferView >= 0) and (LImage.BufferView < AOut.BufferViews.Count) and
         not LViews.Contains(LImage.BufferView) then
        LViews.Add(LImage.BufferView);
    if LViews.Count = 0 then
      Exit;

    if TglTFEdit.UsesBufferViewExtension(AOut, LName) then
    begin
      FSaveWarnings.Add(Format('The file uses %s, which refers to bufferViews in a way this ' +
        'program cannot renumber, so images saved as separate files also stay in their buffers',
        [LName]));
      Exit;
    end;

    // The images move out of their bufferViews...
    for LImage in AOut.Images do
      if not LImage.Embed and (LImage.Data <> nil) and LViews.Contains(LImage.BufferView) then
      begin
        LImage.BufferView := GLTF_UNDEFINED_INDEX;
        LImage.Uri := '';
      end;

    // ...and a view anything else still uses is kept
    for LImage in AOut.Images do
      KeepIfUsed(LImage.BufferView);
    for LAccessor in AOut.Accessors do
    begin
      KeepIfUsed(LAccessor.BufferView);
      if Assigned(LAccessor.Sparse) then
      begin
        if Assigned(LAccessor.Sparse.Indices) then
          KeepIfUsed(LAccessor.Sparse.Indices.BufferView);
        if Assigned(LAccessor.Sparse.Values) then
          KeepIfUsed(LAccessor.Sparse.Values.BufferView);
      end;
    end;

    // All in one pass, so each buffer is rebuilt once
    TglTFEdit.DeleteBufferViews(AOut, LViews.ToArray);
  finally
    LViews.Free;
  end;
end;

// True when APath exists and holds exactly AData
function FileHoldsBytes(const APath: string; const AData: TBytes): Boolean;
var
  LExisting: TBytes;
begin
  Result := False;
  if (APath = '') or not TFile.Exists(APath) or (TFile.GetSize(APath) <> Length(AData)) then
    Exit;
  LExisting := TFile.ReadAllBytes(APath);
  Result := (Length(AData) = 0) or CompareMem(@LExisting[0], @AData[0], Length(AData));
end;

procedure TglTFDocument.SaveInternal(AStream: TStream; AFormat: TglTFFileFormat;
  const AOptions: TglTFSaveOptions; const AOutDir, ABaseName: string);
type
  TExternalFile = record
    Path: string;   // where it goes
    Uri: string;    // as written in the glTF
    Data: TBytes;
    Source: string; // the file the data was read from, '' for embedded data
    Shared: Boolean; // an existing file is used as it is (TglTFImage.Shared)
    Note: string;    // added to the SavedFiles line, e.g. why it was renamed
  end;
  TClaimedName = record
    Path: string;   // as first claimed, with its case
    Data: TBytes;   // nil for the reserved output names
  end;
var
  LOut: TglTF;
  LJSON: TJSONObject;
  LFiles: TList<TExternalFile>;
  LBinary, LJSONBytes, LPadding: TBytes;
  LHasBinary: Boolean;
  LText: string;
  LMode: TglTFResourceMode;
  LBuffer, LImageBuffer: TglTFBuffer;
  LImage: TglTFImage;
  LFile: TExternalFile;
  LTotal: Int64;
  LMime, LName: string;
  LShared: Boolean;
  // Relative paths (lower case) of the files this save writes, with their bytes
  LUsed: TDictionary<string, TClaimedName>;
  LExisting: TClaimedName;
  I: Integer;

  function NewFileName(const ASuffix, AExt: string): string;
  begin
    Result := ABaseName + ASuffix + AExt;
  end;

  // Makes a relative file path (decoded, "/" separators) unique among the
  // files of this save, ignoring case as Windows and macOS file systems do.
  // A path already claimed for the same bytes is shared (AShared = True);
  // for other bytes "_2", "_3", ... is added before the extension
  // True when another file is already on disk at APath (relative to the
  // output folder) with bytes other than AData; names are compared ignoring
  // case, as Windows and macOS would overwrite such a file
  function TakenOnDisk(const APath: string; const AData: TBytes): Boolean;
  var
    LDisk: string;
  begin
    if AOutDir = '' then
      Exit(False);
    LDisk := ExistingFile(TPath.Combine(AOutDir, APath.Replace('/', PathDelim)));
    Result := (LDisk <> '') and not FileHoldsBytes(LDisk, AData);
  end;

  function ClaimName(const APath: string; const AData: TBytes; out AShared: Boolean;
    ASharedFile: Boolean = False; ACheckDisk: Boolean = False): string;
  var
    LStem, LExt: string;
    LExisting, LNew: TClaimedName;
    N: Integer;
  begin
    AShared := False;
    Result := APath;
    if LUsed.TryGetValue(LowerCase(Result), LExisting) and (LExisting.Data <> nil) and
       (ASharedFile or BytesEqual(LExisting.Data, AData)) then
    begin
      // The same file: refer to it exactly as claimed, as case matters on
      // Linux, Android and iOS. A shared file is used whatever it holds
      AShared := True;
      Exit(LExisting.Path);
    end;

    // A shared file may already exist on disk; any other may not replace a
    // different file, there or in this save
    if LUsed.ContainsKey(LowerCase(Result)) or
       (ACheckDisk and not ASharedFile and TakenOnDisk(Result, AData)) then
    begin
      SplitExtension(APath, LStem, LExt);
      N := 2;
      repeat
        Result := Format('%s_%d%s', [LStem, N, LExt]);
        Inc(N);
      until not LUsed.ContainsKey(LowerCase(Result)) and
        not (ACheckDisk and not ASharedFile and TakenOnDisk(Result, AData));
    end;
    LNew.Path := Result;
    LNew.Data := AData;
    LUsed.Add(LowerCase(Result), LNew);
  end;

  // The relative path (decoded) for an image saved as a separate file:
  // 1. its uri's file name (with the uri's folders when they stay inside
  //    the output folder); 2. its name with an extension from the MIME type;
  // 3. <model>_image<N>
  function ImageFileName(AIndex: Integer; AImage: TglTFImage; const AMime: string): string;
  var
    LExt, LName: string;
  begin
    LExt := ImageExtension(AMime);
    Result := '';

    if (AImage.Uri <> '') and not AImage.IsDataUri then
    begin
      if IsSafeRelativeUri(AImage.Uri) or (AImage.Shared and IsRelativeUri(AImage.Uri)) then
        Result := PercentDecode(AImage.Uri).Replace('\', '/')
      else
      begin
        // e.g. an absolute path or "../x.png": keep only the file name
        LName := PercentDecode(AImage.Uri).Replace('\', '/');
        LName := SafeFileName(LName.Substring(LName.LastIndexOf('/') + 1));
        if LName <> '' then
          Result := LName;
      end;
    end;

    if Result = '' then
    begin
      LName := SafeFileName(AImage.Name);
      if LName <> '' then
      begin
        if SameText(ExtractFileExt(LName), LExt) then
          Result := LName
        else
          Result := LName + LExt;
      end;
    end;

    if Result = '' then
      Result := NewFileName('_image' + IntToStr(AIndex), LExt);
  end;

  procedure AddExternal(const AUri: string; const AData: TBytes; const ASource: string;
    AShared: Boolean = False; const ANote: string = '');
  var
    LFile: TExternalFile;
  begin
    LFile.Path := ResolveUriAgainst(AOutDir, AUri);
    LFile.Uri := AUri;
    LFile.Data := AData;
    LFile.Source := ASource;
    LFile.Shared := AShared;
    LFile.Note := ANote;
    LFiles.Add(LFile);
  end;

  // Every file the saved glTF refers to must exist next to it
  procedure CheckComplete;
  var
    J: Integer;

    procedure Check(const AKind: string; AIndex: Integer; const AUri: string);
    begin
      if (AUri = '') or AUri.StartsWith('data:', True) then
        Exit;
      if (AOutDir <> '') and TFile.Exists(ResolveUriAgainst(AOutDir, AUri)) then
        Exit;
      FSaveComplete := False;
      FSaveWarnings.Add(Format('%s %d: "%s" could not be found, so the saved file refers to ' +
        'a file that is not next to it (locate it and save again)',
        [AKind, AIndex, PercentDecode(AUri)]));
    end;

  begin
    for J := 0 to LOut.Buffers.Count - 1 do
      Check('Buffer', J, LOut.Buffers[J].Uri);
    for J := 0 to LOut.Images.Count - 1 do
      Check('Image', J, LOut.Images[J].Uri);
  end;

  // <summary>
  //   Appends AData to ABuffer's Data on a 4-byte boundary and adds a
  //   bufferView for it. Returns the new bufferView's index
  // </summary>
  function AppendToBuffer(ABuffer: TglTFBuffer; ABufferIndex: Integer; const AData: TBytes): Integer;
  var
    LBytes: TBytes;
    LOffset: Integer;
    LView: TglTFBufferView;
  begin
    LBytes := Copy(ABuffer.Data); // never change the document's own array
    LOffset := Length(LBytes);
    LOffset := LOffset + (4 - LOffset mod 4) mod 4;
    SetLength(LBytes, LOffset + Length(AData)); // the gap is zero filled
    if Length(AData) > 0 then
      Move(AData[0], LBytes[LOffset], Length(AData));
    ABuffer.Data := LBytes;
    ABuffer.ByteLength := Length(LBytes);

    LView := TglTFBufferView.Create;
    LView.Buffer := ABufferIndex;
    LView.ByteOffset := LOffset;
    LView.ByteLength := Length(AData);
    LOut.BufferViews.Add(LView);
    Result := LOut.BufferViews.Count - 1;
  end;

  // <summary>The buffer embedded images go into (created when needed)</summary>
  function ImageTarget(out AIndex: Integer): TglTFBuffer;
  begin
    if AFormat = gffGLB then
    begin
      // GLB: the BIN chunk, i.e. buffers[0]
      if LOut.Buffers.Count = 0 then
        LOut.Buffers.Add(TglTFBuffer.Create);
      AIndex := 0;
      Exit(LOut.Buffers[0]);
    end;

    // glTF: one new buffer, written as a base64 data URI
    if LImageBuffer = nil then
    begin
      LImageBuffer := TglTFBuffer.Create;
      LImageBuffer.Name := 'embedded images';
      LOut.Buffers.Add(LImageBuffer);
    end;
    AIndex := LOut.Buffers.IndexOf(LImageBuffer);
    Result := LImageBuffer;
  end;

  procedure EmbedImage(AImage: TglTFImage; const AMime: string);
  var
    LTarget: TglTFBuffer;
    LIndex: Integer;
  begin
    LTarget := ImageTarget(LIndex);
    AImage.BufferView := AppendToBuffer(LTarget, LIndex, AImage.Data);
    AImage.MimeType := AMime;
    AImage.Uri := '';
  end;

  procedure ExternalImage(AIndex: Integer; AImage: TglTFImage; const AMime: string);
  var
    LUri, LWanted, LNote: string;
    LShared: Boolean;
  begin
    if AOutDir = '' then
    begin
      // A stream has no folder for files: the image stays in the stream
      LUri := EncodeDataUri(AMime, AImage.Data);
    end
    else
    begin
      LWanted := ImageFileName(AIndex, AImage, AMime);
      LUri := ClaimName(LWanted, AImage.Data, LShared, AImage.Shared, True);
      if LUri <> LWanted then
        LNote := Format(' (renamed: %s is already used by another file)', [LWanted])
      else
        LNote := '';
      LUri := PercentEncodePath(LUri);
      if not LShared then
        AddExternal(LUri, AImage.Data, AImage.SourceFile, AImage.Shared, LNote);
    end;

    // Only when TakeSeparateImagesOutOfBuffers could not take it out
    if AImage.BufferView <> GLTF_UNDEFINED_INDEX then
      FSaveWarnings.Add(Format('Image %d: written to "%s"; its bytes also remain in bufferView %d ' +
        '(now unused)', [AIndex, PercentDecode(LUri).Substring(0, 60), AImage.BufferView]));
    AImage.BufferView := GLTF_UNDEFINED_INDEX;
    AImage.Uri := LUri;
  end;

begin
  FSaveWarnings.Clear;
  FSavedFiles.Clear;
  FSaveComplete := True;
  LBinary := nil;
  LHasBinary := False;
  LImageBuffer := nil;

  LUsed := TDictionary<string, TClaimedName>.Create;
  LFiles := TList<TExternalFile>.Create;
  LOut := CreateSaveCopy;
  try
    // The output file itself is never to be overwritten by an image or buffer
    if ABaseName <> '' then
    begin
      LExisting.Path := ABaseName + '.gltf';
      LExisting.Data := nil;
      LUsed.Add(LowerCase(LExisting.Path), LExisting);
      LExisting.Path := ABaseName + '.glb';
      LUsed.Add(LowerCase(LExisting.Path), LExisting);
    end;

    ReadUnloadedFiles(LOut);
    LeaveOutUnexportedAnimations(LOut);
    // The model the right way up, baked into the copy's data
    TglTFReorienter.Apply(LOut, AOptions.RotateX, AOptions.RotateY, AOptions.RotateZ,
      FSaveWarnings);
    // Before the images are placed: only those the model needs are saved
    if AOptions.LeaveOutUnusedImages then
      TglTFEdit.DeleteUnusedImages(LOut, FSaveWarnings);
    // The format decides where the images go, unless each image is to
    // decide; only the copy's flags change
    if AOptions.ImageSaveMode = ismByFormat then
      for I := 0 to LOut.Images.Count - 1 do
        LOut.Images[I].Embed := AFormat = gffGLB;
    TakeSeparateImagesOutOfBuffers(LOut);

    if (AFormat = gffGLB) and (LOut.Buffers.Count > 0) and (LOut.Buffers[0].Data = nil) then
      raise EglTFError.Create('Cannot write the GLB BIN chunk: the data of buffers[0] is not available');

    // 1. Images: where each one's bytes go, following its Embed flag
    for I := 0 to LOut.Images.Count - 1 do
    begin
      LImage := LOut.Images[I];

      if LImage.Data = nil then
      begin
        // A missing file stays a uri reference; CheckComplete reports it
        if LImage.BufferView <> GLTF_UNDEFINED_INDEX then
          FSaveWarnings.Add(Format('Image %d: the buffer holding it is missing', [I]));
        Continue;
      end;

      LMime := LImage.EffectiveMimeType;

      if LImage.Embed then
      begin
        if LImage.BufferView <> GLTF_UNDEFINED_INDEX then
          Continue; // already inside a buffer
        if LMime <> '' then
        begin
          EmbedImage(LImage, LMime);
          Continue;
        end;
        FSaveWarnings.Add(Format('Image %d: unknown image type, so it cannot be stored in a ' +
          'buffer (a mimeType is required there); written as a separate file instead', [I]));
      end;

      ExternalImage(I, LImage, LMime);
    end;

    // 2. Buffers: where each one's Data goes. byteLength follows the data
    for I := 0 to LOut.Buffers.Count - 1 do
    begin
      LBuffer := LOut.Buffers[I];

      if LBuffer.Data = nil then
      begin
        if LBuffer.Uri = '' then
          raise EglTFError.CreateFmt('Cannot save buffers[%d]: it has neither data nor a uri', [I]);
        Continue; // a uri reference only; CheckComplete reports it
      end;

      LBuffer.ByteLength := Length(LBuffer.Data);

      if (AFormat = gffGLB) and (I = 0) then
      begin
        // GLB: buffers[0] is the BIN chunk and has no uri
        LBuffer.Uri := '';
        LBinary := LBuffer.Data;
        LHasBinary := True;
        Continue;
      end;

      if LBuffer = LImageBuffer then
        LMode := rmEmbed
      else if AOutDir = '' then
        LMode := rmEmbed // a stream has no folder for files
      else
      begin
        LMode := AOptions.Buffers;
        if (LMode = rmKeep) and LBuffer.IsDataUri then
          LMode := rmEmbed;
      end;

      if LMode = rmEmbed then
        LBuffer.Uri := EncodeDataUri(LBuffer.DataUriMimeType, LBuffer.Data)
      else
      begin
        if (LMode = rmKeep) and IsSafeRelativeUri(LBuffer.Uri) then
          LName := PercentDecode(LBuffer.Uri).Replace('\', '/')
        else if I = 0 then
          LName := NewFileName('', '.bin')
        else
          LName := NewFileName('_' + IntToStr(I), '.bin');
        LBuffer.Uri := PercentEncodePath(ClaimName(LName, LBuffer.Data, LShared));
        if not LShared then
          AddExternal(LBuffer.Uri, LBuffer.Data, LBuffer.SourceFile);
      end;
    end;

    // 3. The JSON, entirely from the (adjusted) copy of the objects
    LJSON := LOut.SaveToJSON;
    try
      if (AFormat = gffJSON) and AOptions.PrettyPrint then
        LText := TNeon.Print(LJSON, True)
      else
        LText := LJSON.ToJSON;
    finally
      LJSON.Free;
    end;

    // 4. External files first, then the main output. A file already in place
    //    with the same bytes is left alone
    for LFile in LFiles do
    begin
      if FileHoldsBytes(LFile.Path, LFile.Data) then
      begin
        FSavedFiles.Add(Format('%s: already in place%s', [PercentDecode(LFile.Uri),
          IfThen(LFile.Shared, ' (shared)', '')]));
        Continue;
      end;

      if LFile.Shared and (ExistingFile(LFile.Path) <> '') then
      begin
        // Other models rely on a shared file: it is used as it is
        FSavedFiles.Add(Format('%s: shared file already exists and was left unchanged; it ' +
          'differs from this model''s image', [PercentDecode(LFile.Uri)]));
        Continue;
      end;

      TDirectory.CreateDirectory(TPath.GetDirectoryName(LFile.Path));
      TFile.WriteAllBytes(LFile.Path, LFile.Data);

      if (LFile.Source <> '') and FileHoldsBytes(LFile.Source, LFile.Data) then
        FSavedFiles.Add(Format('%s: copied from %s', [PercentDecode(LFile.Uri), LFile.Source]))
      else if LFile.Source <> '' then
        FSavedFiles.Add(Format('%s: written from the data in memory (read from %s)',
          [PercentDecode(LFile.Uri), LFile.Source]))
      else
        FSavedFiles.Add(Format('%s: written from embedded data', [PercentDecode(LFile.Uri)]));
      if LFile.Shared or (LFile.Note <> '') then
        FSavedFiles[FSavedFiles.Count - 1] := FSavedFiles[FSavedFiles.Count - 1] +
          IfThen(LFile.Shared, ' (shared)', '') + LFile.Note;
    end;
    CheckComplete;

    LJSONBytes := TEncoding.UTF8.GetBytes(LText);

    if AFormat = gffJSON then
    begin
      if Length(LJSONBytes) > 0 then
        AStream.WriteBuffer(LJSONBytes[0], Length(LJSONBytes));
      Exit;
    end;

    // GLB: chunks start and end on 4-byte boundaries; JSON is padded with
    // spaces, BIN with zeros
    SetLength(LPadding, (4 - Length(LJSONBytes) mod 4) mod 4);
    if Length(LPadding) > 0 then
    begin
      FillChar(LPadding[0], Length(LPadding), $20);
      LJSONBytes := LJSONBytes + LPadding;
    end;

    if LHasBinary then
    begin
      SetLength(LPadding, (4 - Length(LBinary) mod 4) mod 4);
      if Length(LPadding) > 0 then
      begin
        FillChar(LPadding[0], Length(LPadding), 0);
        LBinary := LBinary + LPadding;
      end;
    end;

    LTotal := GLB_HEADER_SIZE + GLB_CHUNK_HEADER_SIZE + Length(LJSONBytes);
    if LHasBinary then
      Inc(LTotal, GLB_CHUNK_HEADER_SIZE + Length(LBinary));
    if LTotal > High(Cardinal) then
      raise EglTFError.Create('The GLB would be larger than 4 GB, which the format does not allow');

    AStream.WriteBuffer(GLB_MAGIC, 4);
    WriteUInt32LE(AStream, GLB_VERSION);
    WriteUInt32LE(AStream, Cardinal(LTotal));

    WriteUInt32LE(AStream, Length(LJSONBytes));
    WriteUInt32LE(AStream, GLB_CHUNK_JSON);
    AStream.WriteBuffer(LJSONBytes[0], Length(LJSONBytes));

    if LHasBinary then
    begin
      WriteUInt32LE(AStream, Length(LBinary));
      WriteUInt32LE(AStream, GLB_CHUNK_BIN);
      if Length(LBinary) > 0 then
        AStream.WriteBuffer(LBinary[0], Length(LBinary));
    end;
  finally
    LOut.Free;
    LFiles.Free;
    LUsed.Free;
  end;
end;

{ Other }

function TglTFDocument.ResolveUri(const AUri: string): string;
begin
  if AUri.StartsWith('data:', True) then
    Result := AUri
  else
    Result := ResolveUriAgainst(FBaseDirectory, AUri);
end;

function TglTFDocument.MissingResources: TArray<TglTFMissingResource>;
var
  LList: TList<TglTFMissingResource>;
  LItem: TglTFMissingResource;
  I: Integer;
begin
  LList := TList<TglTFMissingResource>.Create;
  try
    for I := 0 to FRoot.Buffers.Count - 1 do
      if (FRoot.Buffers[I].Uri <> '') and not FRoot.Buffers[I].IsDataUri and
         (FRoot.Buffers[I].Data = nil) then
      begin
        LItem.Kind := rkBuffer;
        LItem.Index := I;
        LItem.Uri := FRoot.Buffers[I].Uri;
        LItem.ExpectedPath := ResolveUriAgainst(FBaseDirectory, LItem.Uri);
        LList.Add(LItem);
      end;

    for I := 0 to FRoot.Images.Count - 1 do
      if (FRoot.Images[I].Uri <> '') and not FRoot.Images[I].IsDataUri and
         (FRoot.Images[I].BufferView = GLTF_UNDEFINED_INDEX) and
         (FRoot.Images[I].Data = nil) then
      begin
        LItem.Kind := rkImage;
        LItem.Index := I;
        LItem.Uri := FRoot.Images[I].Uri;
        LItem.ExpectedPath := ResolveUriAgainst(FBaseDirectory, LItem.Uri);
        LList.Add(LItem);
      end;

    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TglTFDocument.HasMissingResources: Boolean;
begin
  Result := Length(MissingResources) > 0;
end;

procedure TglTFDocument.SupplyResourceFile(AKind: TglTFResourceKind; AIndex: Integer;
  const AFileName: string);
var
  LData: TBytes;
  LBuffer: TglTFBuffer;
begin
  if not TFile.Exists(AFileName) then
    raise EglTFError.CreateFmt('File not found: %s', [AFileName]);

  case AKind of
    rkBuffer:
    begin
      if (AIndex < 0) or (AIndex >= FRoot.Buffers.Count) then
        raise EglTFError.CreateFmt('Buffer %d does not exist', [AIndex]);
      LBuffer := FRoot.Buffers[AIndex];
      LData := TFile.ReadAllBytes(AFileName);
      if Length(LData) < LBuffer.ByteLength then
        raise EglTFError.CreateFmt('%s holds %d bytes but buffer %d needs %d (byteLength)',
          [ExtractFileName(AFileName), Length(LData), AIndex, LBuffer.ByteLength]);
      SetLength(LData, LBuffer.ByteLength);
      LBuffer.Data := LData;
      LBuffer.SourceFile := TPath.GetFullPath(AFileName);
    end;
    rkImage:
    begin
      if (AIndex < 0) or (AIndex >= FRoot.Images.Count) then
        raise EglTFError.CreateFmt('Image %d does not exist', [AIndex]);
      FRoot.Images[AIndex].Data := TFile.ReadAllBytes(AFileName);
      FRoot.Images[AIndex].SourceFile := TPath.GetFullPath(AFileName);
    end;
  end;
end;

function TglTFDocument.SearchMissingResources(const ADirectory: string;
  ARecursive: Boolean): Integer;
var
  LMissing: TglTFMissingResource;
  LCandidates: TList<string>;
  LCandidate, LEntry: string;
  LAllFiles: TArray<string>;
begin
  Result := 0;
  if not TDirectory.Exists(ADirectory) then
    Exit;

  // Listed once; names are compared without case, as file name patterns are
  // case-sensitive on Linux, Android and iOS
  LAllFiles := nil;
  if ARecursive then
  try
    LAllFiles := TDirectory.GetFiles(ADirectory, '*', TSearchOption.soAllDirectories);
  except
    LAllFiles := nil; // e.g. a sub-folder without access
  end;

  LCandidates := TList<string>.Create;
  try
    for LMissing in MissingResources do
    begin
      LCandidates.Clear;
      // 1. The uri's relative path (keeps sub-folders such as textures/)
      if IsSafeRelativeUri(LMissing.Uri) then
        LCandidates.Add(ExistingFile(ResolveUriAgainst(ADirectory, LMissing.Uri)));
      // 2. Just the file name
      LCandidates.Add(ExistingFile(TPath.Combine(ADirectory, LMissing.FileName)));
      // 3. The file name anywhere below
      for LEntry in LAllFiles do
        if SameText(TPath.GetFileName(LEntry), LMissing.FileName) then
          LCandidates.Add(LEntry);

      for LCandidate in LCandidates do
        if (LCandidate <> '') and TFile.Exists(LCandidate) then
        try
          SupplyResourceFile(LMissing.Kind, LMissing.Index, LCandidate);
          Inc(Result);
          Break;
        except
          on EglTFError do
            ; // e.g. too small for the buffer: try the next candidate
        end;
    end;
  finally
    LCandidates.Free;
  end;
end;

function TglTFDocument.GetBufferData(AIndex: Integer): TBytes;
begin
  if (AIndex < 0) or (AIndex >= FRoot.Buffers.Count) then
    raise EglTFError.CreateFmt('Buffer %d does not exist (%d defined)', [AIndex, FRoot.Buffers.Count]);
  Result := FRoot.Buffers[AIndex].Data;
  if Result = nil then
    raise EglTFError.CreateFmt('The data of buffer %d is not available (see Warnings)', [AIndex]);
end;

end.
