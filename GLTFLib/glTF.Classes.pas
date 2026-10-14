//** @abstract(The glTF 2.0 object types, one class per object of the glTF schema.)
//**
//** Property JSON names are given with @code([NeonProperty]) and properties the schema
//** requires with @code([glTFRequired]). Optional index properties, such as
//** accessor.bufferView or node.mesh, default to GLTF_UNDEFINED_INDEX @(-1@); every other
//** optional value defaults to the value the specification defines. IsDefined tells
//** whether a value was present in the loaded file.
//**
//** TglTFBuffer and TglTFImage also carry their binary data and save choices, which are
//** not part of the glTF JSON: Data, SourceFile and, for images, Embed.
unit glTF.Classes;

{
  The glTF 2.0 object types, one class per object of the glTF schema.

  Property JSON names are given with [NeonProperty] and properties the schema
  requires with [glTFRequired]. Optional index properties, such as
  accessor.bufferView or node.mesh, default to GLTF_UNDEFINED_INDEX (-1); every
  other optional value defaults to the value the specification defines.
  IsDefined tells whether a value was present in the loaded file.

  TglTFBuffer and TglTFImage also carry their binary data and save choices,
  which are not part of the glTF JSON: Data, SourceFile and, for images, Embed.
}

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections,

  Neon.Core.Attributes,

  glTF.Base;

const
  //** @abstract(Value of an optional index property that is not set.)
  //**
  //** Index properties such as @code(TglTFNode.Mesh) hold -1 when the glTF does not give them.
  /// <summary>Value of an optional index property that is not set.</summary>
  /// <remarks>Index properties such as <c>TglTFNode.Mesh</c> hold -1 when the glTF does not
  /// give them.</remarks>
  GLTF_UNDEFINED_INDEX = -1;

  // accessor.componentType / accessor.sparse.indices.componentType

  //** @abstract(Component type 5120: signed 8-bit integer.)
  /// <summary>Component type 5120: signed 8-bit integer.</summary>
  GLTF_COMPONENT_BYTE           = 5120;

  //** @abstract(Component type 5121: unsigned 8-bit integer.)
  /// <summary>Component type 5121: unsigned 8-bit integer.</summary>
  GLTF_COMPONENT_UNSIGNED_BYTE  = 5121;

  //** @abstract(Component type 5122: signed 16-bit integer.)
  /// <summary>Component type 5122: signed 16-bit integer.</summary>
  GLTF_COMPONENT_SHORT          = 5122;

  //** @abstract(Component type 5123: unsigned 16-bit integer.)
  /// <summary>Component type 5123: unsigned 16-bit integer.</summary>
  GLTF_COMPONENT_UNSIGNED_SHORT = 5123;

  //** @abstract(Component type 5125: unsigned 32-bit integer.)
  /// <summary>Component type 5125: unsigned 32-bit integer.</summary>
  GLTF_COMPONENT_UNSIGNED_INT   = 5125;

  //** @abstract(Component type 5126: 32-bit IEEE float.)
  /// <summary>Component type 5126: 32-bit IEEE float.</summary>
  GLTF_COMPONENT_FLOAT          = 5126;

  // bufferView.target

  //** @abstract(bufferView target 34962: vertex attribute data.)
  /// <summary>bufferView target 34962: vertex attribute data.</summary>
  GLTF_TARGET_ARRAY_BUFFER         = 34962;

  //** @abstract(bufferView target 34963: vertex indices.)
  /// <summary>bufferView target 34963: vertex indices.</summary>
  GLTF_TARGET_ELEMENT_ARRAY_BUFFER = 34963;

  // mesh.primitive.mode

  //** @abstract(Primitive mode 0: points.)
  /// <summary>Primitive mode 0: points.</summary>
  GLTF_MODE_POINTS         = 0;

  //** @abstract(Primitive mode 1: separate lines.)
  /// <summary>Primitive mode 1: separate lines.</summary>
  GLTF_MODE_LINES          = 1;

  //** @abstract(Primitive mode 2: a closed line loop.)
  /// <summary>Primitive mode 2: a closed line loop.</summary>
  GLTF_MODE_LINE_LOOP      = 2;

  //** @abstract(Primitive mode 3: a line strip.)
  /// <summary>Primitive mode 3: a line strip.</summary>
  GLTF_MODE_LINE_STRIP     = 3;

  //** @abstract(Primitive mode 4: separate triangles; the default.)
  /// <summary>Primitive mode 4: separate triangles; the default.</summary>
  GLTF_MODE_TRIANGLES      = 4;

  //** @abstract(Primitive mode 5: a triangle strip.)
  /// <summary>Primitive mode 5: a triangle strip.</summary>
  GLTF_MODE_TRIANGLE_STRIP = 5;

  //** @abstract(Primitive mode 6: a triangle fan.)
  /// <summary>Primitive mode 6: a triangle fan.</summary>
  GLTF_MODE_TRIANGLE_FAN   = 6;

  // sampler.magFilter / sampler.minFilter

  //** @abstract(Sampler filter 9728: nearest texel.)
  /// <summary>Sampler filter 9728: nearest texel.</summary>
  GLTF_FILTER_NEAREST                = 9728;

  //** @abstract(Sampler filter 9729: linear interpolation.)
  /// <summary>Sampler filter 9729: linear interpolation.</summary>
  GLTF_FILTER_LINEAR                 = 9729;

  //** @abstract(Sampler minification filter 9984: nearest texel of the nearest mipmap.)
  /// <summary>Sampler minification filter 9984: nearest texel of the nearest mipmap.</summary>
  GLTF_FILTER_NEAREST_MIPMAP_NEAREST = 9984;

  //** @abstract(Sampler minification filter 9985: linear within the nearest mipmap.)
  /// <summary>Sampler minification filter 9985: linear within the nearest mipmap.</summary>
  GLTF_FILTER_LINEAR_MIPMAP_NEAREST  = 9985;

  //** @abstract(Sampler minification filter 9986: nearest texel, blended between two mipmaps.)
  /// <summary>Sampler minification filter 9986: nearest texel, blended between two
  /// mipmaps.</summary>
  GLTF_FILTER_NEAREST_MIPMAP_LINEAR  = 9986;

  //** @abstract(Sampler minification filter 9987: trilinear filtering.)
  /// <summary>Sampler minification filter 9987: trilinear filtering.</summary>
  GLTF_FILTER_LINEAR_MIPMAP_LINEAR   = 9987;

  // sampler.wrapS / sampler.wrapT

  //** @abstract(Sampler wrap mode 33071: clamp to the edge.)
  /// <summary>Sampler wrap mode 33071: clamp to the edge.</summary>
  GLTF_WRAP_CLAMP_TO_EDGE   = 33071;

  //** @abstract(Sampler wrap mode 33648: mirrored repeat.)
  /// <summary>Sampler wrap mode 33648: mirrored repeat.</summary>
  GLTF_WRAP_MIRRORED_REPEAT = 33648;

  //** @abstract(Sampler wrap mode 10497: repeat; the default.)
  /// <summary>Sampler wrap mode 10497: repeat; the default.</summary>
  GLTF_WRAP_REPEAT          = 10497;

type
  // Typed views of the string enums. The schema allows other strings (for
  // extensions), so unrecognised values map to the *Unknown member instead
  // of raising

  //** @abstract(The accessor "type" as an enumeration.)
  //**
  //** The schema allows other strings for extensions; those map to atUnknown.
  /// <summary>The accessor "type" as an enumeration.</summary>
  /// <remarks>The schema allows other strings for extensions; those map to atUnknown.</remarks>
  TglTFAccessorType = (
    //** @abstract(Any other string.)
    /// <summary>Any other string.</summary>
    atUnknown,

    //** @abstract("SCALAR": one component.)
    /// <summary>"SCALAR": one component.</summary>
    atScalar,

    //** @abstract("VEC2": two components.)
    /// <summary>"VEC2": two components.</summary>
    atVec2,

    //** @abstract("VEC3": three components.)
    /// <summary>"VEC3": three components.</summary>
    atVec3,

    //** @abstract("VEC4": four components.)
    /// <summary>"VEC4": four components.</summary>
    atVec4,

    //** @abstract("MAT2": a 2 by 2 matrix.)
    /// <summary>"MAT2": a 2 by 2 matrix.</summary>
    atMat2,

    //** @abstract("MAT3": a 3 by 3 matrix.)
    /// <summary>"MAT3": a 3 by 3 matrix.</summary>
    atMat3,

    //** @abstract("MAT4": a 4 by 4 matrix.)
    /// <summary>"MAT4": a 4 by 4 matrix.</summary>
    atMat4);

  //** @abstract(The material "alphaMode" as an enumeration.)
  /// <summary>The material "alphaMode" as an enumeration.</summary>
  TglTFAlphaMode = (
    //** @abstract(Any other string.)
    /// <summary>Any other string.</summary>
    amUnknown,

    //** @abstract("OPAQUE": alpha is ignored.)
    /// <summary>"OPAQUE": alpha is ignored.</summary>
    amOpaque,

    //** @abstract("MASK": fully opaque or fully transparent, by alphaCutoff.)
    /// <summary>"MASK": fully opaque or fully transparent, by alphaCutoff.</summary>
    amMask,

    //** @abstract("BLEND": alpha blends with the background.)
    /// <summary>"BLEND": alpha blends with the background.</summary>
    amBlend);

  //** @abstract(The animation target "path" as an enumeration.)
  /// <summary>The animation target "path" as an enumeration.</summary>
  TglTFAnimationPath = (
    //** @abstract(Any other string.)
    /// <summary>Any other string.</summary>
    apUnknown,

    //** @abstract("translation".)
    /// <summary>"translation".</summary>
    apTranslation,

    //** @abstract("rotation".)
    /// <summary>"rotation".</summary>
    apRotation,

    //** @abstract("scale".)
    /// <summary>"scale".</summary>
    apScale,

    //** @abstract("weights": morph target weights.)
    /// <summary>"weights": morph target weights.</summary>
    apWeights);

  //** @abstract(The animation sampler "interpolation" as an enumeration.)
  /// <summary>The animation sampler "interpolation" as an enumeration.</summary>
  TglTFInterpolation = (
    //** @abstract(Any other string.)
    /// <summary>Any other string.</summary>
    ipUnknown,

    //** @abstract("LINEAR".)
    /// <summary>"LINEAR".</summary>
    ipLinear,

    //** @abstract("STEP": values are held until the next key frame.)
    /// <summary>"STEP": values are held until the next key frame.</summary>
    ipStep,

    //** @abstract("CUBICSPLINE": cubic spline with tangents.)
    /// <summary>"CUBICSPLINE": cubic spline with tangents.</summary>
    ipCubicSpline);

  //** @abstract(The camera "type" as an enumeration.)
  /// <summary>The camera "type" as an enumeration.</summary>
  TglTFCameraType = (
    //** @abstract(Any other string.)
    /// <summary>Any other string.</summary>
    ctUnknown,

    //** @abstract("perspective".)
    /// <summary>"perspective".</summary>
    ctPerspective,

    //** @abstract("orthographic".)
    /// <summary>"orthographic".</summary>
    ctOrthographic);

  //** @abstract(Maps attribute semantics to accessor indices.)
  //**
  //** Keys are names such as POSITION, NORMAL or TEXCOORD_0; values are indices in
  //** @code(TglTF.Accessors).
  /// <summary>Maps attribute semantics to accessor indices.</summary>
  /// <remarks>Keys are names such as POSITION, NORMAL or TEXCOORD_0; values are indices in
  /// <c>TglTF.Accessors</c>.</remarks>
  TglTFAttributeMap = TDictionary<string, Integer>;

  {$REGION 'asset'}

  //** @abstract(The glTF "asset": metadata about the file, including the glTF version.)
  //**
  //** Required in every glTF file.
  /// <summary>The glTF "asset": metadata about the file, including the glTF version.</summary>
  /// <remarks>Required in every glTF file.</remarks>
  TglTFAsset = class(TglTFProperty)
  private
    FCopyright: string;
    FGenerator: string;
    FVersion: string;
    FMinVersion: string;
  protected
    procedure Validate; override;
  public
    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "asset"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "asset"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "copyright": a copyright message; empty when not set.)
    /// <summary>The glTF "copyright": a copyright message; empty when not set.</summary>
    [NeonProperty('copyright')]
    property Copyright: string read FCopyright write FCopyright;

    //** @abstract(The glTF "generator": the tool that created the file; empty when not set.)
    /// <summary>The glTF "generator": the tool that created the file; empty when not
    /// set.</summary>
    [NeonProperty('generator')]
    property Generator: string read FGenerator write FGenerator;

    //** @abstract(The glTF "version" the file targets, in the form major.minor; required.)
    //**
    //** Files whose major version is not 2 are rejected when loading.
    /// <summary>The glTF "version" the file targets, in the form major.minor;
    /// required.</summary>
    /// <remarks>Files whose major version is not 2 are rejected when loading.</remarks>
    [NeonProperty('version'), glTFRequired]
    property Version: string read FVersion write FVersion;

    //** @abstract(The glTF "minVersion" a reader needs; empty when not set.)
    //**
    //** Files that need more than 2.0 are rejected when loading.
    /// <summary>The glTF "minVersion" a reader needs; empty when not set.</summary>
    /// <remarks>Files that need more than 2.0 are rejected when loading.</remarks>
    [NeonProperty('minVersion')]
    property MinVersion: string read FMinVersion write FMinVersion;
  end;

  {$ENDREGION}

  {$REGION 'buffer / bufferView'}

  //** @abstract(A glTF buffer: a block of binary data that bufferViews point into.)
  //**
  //** The bytes themselves are in @link(Data), filled by TglTFDocument when loading. Where
  //** they are stored when saving is decided by TglTFDocument, not by @link(Uri).
  /// <summary>A glTF buffer: a block of binary data that bufferViews point into.</summary>
  /// <remarks>The bytes themselves are in <see cref="Data"/>, filled by TglTFDocument when
  /// loading. Where they are stored when saving is decided by TglTFDocument, not by
  /// <see cref="Uri"/>.</remarks>
  TglTFBuffer = class(TglTFChildOfRootProperty)
  private
    FUri: string;
    FByteLength: Int64;
    FData: TBytes;
    FSourceFile: string;
  protected
    procedure Validate; override;
  public
    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "buffer"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "buffer"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(Tells whether the uri holds the data itself as a "data:" URI.)
    //**
    //** @returns(True for a data URI, False for a file reference or no uri.)
    /// <summary>Tells whether the uri holds the data itself as a "data:" URI.</summary>
    /// <returns>True for a data URI, False for a file reference or no uri.</returns>
    function IsDataUri: Boolean;

    //** @abstract(Returns the MIME type written in a data URI.)
    //**
    //** @returns(For example @code(application/octet-stream); empty when the uri is not a
    //** data URI or names no type.)
    /// <summary>Returns the MIME type written in a data URI.</summary>
    /// <returns>For example <c>application/octet-stream</c>; empty when the uri is not a
    /// data URI or names no type.</returns>
    function DataUriMimeType: string;

    //** @abstract(The buffer's bytes; nil when they could not be loaded.)
    //**
    //** Filled by TglTFDocument when loading, from the GLB BIN chunk, a data URI or an
    //** external file, and used when saving. Saving writes byteLength from its length.
    //** Not part of the glTF JSON.
    /// <summary>The buffer's bytes; nil when they could not be loaded.</summary>
    /// <remarks>Filled by TglTFDocument when loading, from the GLB BIN chunk, a data URI or
    /// an external file, and used when saving. Saving writes byteLength from its length.
    /// Not part of the glTF JSON.</remarks>
    [NeonIgnore]
    property Data: TBytes read FData write FData;

    //** @abstract(The file @link(Data) was read from; empty for data that was inside the
    //** glTF.)
    //**
    //** Set when the data is loaded from an external file, or from a file found later with
    //** TglTFDocument.SupplyResourceFile. Saving copies from it when the buffer must be a
    //** separate file and its data is not loaded. Not part of the glTF JSON.
    /// <summary>The file <see cref="Data"/> was read from; empty for data that was inside
    /// the glTF.</summary>
    /// <remarks>Set when the data is loaded from an external file, or from a file found
    /// later with TglTFDocument.SupplyResourceFile. Saving copies from it when the buffer
    /// must be a separate file and its data is not loaded. Not part of the glTF
    /// JSON.</remarks>
    [NeonIgnore]
    property SourceFile: string read FSourceFile write FSourceFile;

    //** @abstract(The glTF "uri": a file path relative to the glTF, or a data URI.)
    //**
    //** Empty for the GLB BIN chunk.
    /// <summary>The glTF "uri": a file path relative to the glTF, or a data URI.</summary>
    /// <remarks>Empty for the GLB BIN chunk.</remarks>
    [NeonProperty('uri')]
    property Uri: string read FUri write FUri;

    //** @abstract(The glTF "byteLength": the buffer's size in bytes; required.)
    /// <summary>The glTF "byteLength": the buffer's size in bytes; required.</summary>
    [NeonProperty('byteLength'), glTFRequired]
    property ByteLength: Int64 read FByteLength write FByteLength;
  end;

  //** @abstract(A glTF bufferView: a range of bytes in a buffer.)
  /// <summary>A glTF bufferView: a range of bytes in a buffer.</summary>
  TglTFBufferView = class(TglTFChildOfRootProperty)
  private
    FBuffer: Integer;
    FByteOffset: Int64;
    FByteLength: Int64;
    FByteStride: Integer;
    FTarget: Integer;
  protected
    procedure Validate; override;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** Buffer is GLTF_UNDEFINED_INDEX; the other values are 0.
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>Buffer is GLTF_UNDEFINED_INDEX; the other values are 0.</remarks>
    constructor Create; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "bufferView"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "bufferView"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "buffer": index in @code(TglTF.Buffers) of the buffer holding the
    //** bytes; required.)
    /// <summary>The glTF "buffer": index in <c>TglTF.Buffers</c> of the buffer holding the
    /// bytes; required.</summary>
    [NeonProperty('buffer'), glTFRequired]
    property Buffer: Integer read FBuffer write FBuffer;

    //** @abstract(The glTF "byteOffset": where the range starts in the buffer; 0 by default.)
    /// <summary>The glTF "byteOffset": where the range starts in the buffer; 0 by
    /// default.</summary>
    [NeonProperty('byteOffset')]
    property ByteOffset: Int64 read FByteOffset write FByteOffset;

    //** @abstract(The glTF "byteLength": the length of the range in bytes; required.)
    /// <summary>The glTF "byteLength": the length of the range in bytes; required.</summary>
    [NeonProperty('byteLength'), glTFRequired]
    property ByteLength: Int64 read FByteLength write FByteLength;

    //** @abstract(The glTF "byteStride": bytes between the starts of two vertex elements; 0
    //** when not set.)
    //**
    //** 0 means the data is tightly packed. When set it must be between 4 and 252.
    /// <summary>The glTF "byteStride": bytes between the starts of two vertex elements; 0 when
    /// not set.</summary>
    /// <remarks>0 means the data is tightly packed. When set it must be between 4 and
    /// 252.</remarks>
    [NeonProperty('byteStride')]
    property ByteStride: Integer read FByteStride write FByteStride;

    //** @abstract(The glTF "target": the GPU buffer type the data is meant for; 0 when not
    //** set.)
    //**
    //** GLTF_TARGET_ARRAY_BUFFER or GLTF_TARGET_ELEMENT_ARRAY_BUFFER.
    /// <summary>The glTF "target": the GPU buffer type the data is meant for; 0 when not
    /// set.</summary>
    /// <remarks>GLTF_TARGET_ARRAY_BUFFER or GLTF_TARGET_ELEMENT_ARRAY_BUFFER.</remarks>
    [NeonProperty('target')]
    property Target: Integer read FTarget write FTarget;
  end;

  {$ENDREGION}

  {$REGION 'accessor'}

  //** @abstract(The indices of the elements a sparse accessor replaces.)
  /// <summary>The indices of the elements a sparse accessor replaces.</summary>
  TglTFAccessorSparseIndices = class(TglTFProperty)
  private
    FBufferView: Integer;
    FByteOffset: Int64;
    FComponentType: Integer;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** BufferView is GLTF_UNDEFINED_INDEX.
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>BufferView is GLTF_UNDEFINED_INDEX.</remarks>
    constructor Create; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "accessor.sparse.indices"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "accessor.sparse.indices"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "bufferView" holding the indices; required.)
    /// <summary>The glTF "bufferView" holding the indices; required.</summary>
    [NeonProperty('bufferView'), glTFRequired]
    property BufferView: Integer read FBufferView write FBufferView;

    //** @abstract(The glTF "byteOffset" of the indices in the bufferView; 0 by default.)
    /// <summary>The glTF "byteOffset" of the indices in the bufferView; 0 by default.</summary>
    [NeonProperty('byteOffset')]
    property ByteOffset: Int64 read FByteOffset write FByteOffset;

    //** @abstract(The glTF "componentType" of the indices; required.)
    //**
    //** One of GLTF_COMPONENT_UNSIGNED_BYTE, GLTF_COMPONENT_UNSIGNED_SHORT or
    //** GLTF_COMPONENT_UNSIGNED_INT.
    /// <summary>The glTF "componentType" of the indices; required.</summary>
    /// <remarks>One of GLTF_COMPONENT_UNSIGNED_BYTE, GLTF_COMPONENT_UNSIGNED_SHORT or
    /// GLTF_COMPONENT_UNSIGNED_INT.</remarks>
    [NeonProperty('componentType'), glTFRequired]
    property ComponentType: Integer read FComponentType write FComponentType;
  end;

  //** @abstract(The replacement values of a sparse accessor.)
  /// <summary>The replacement values of a sparse accessor.</summary>
  TglTFAccessorSparseValues = class(TglTFProperty)
  private
    FBufferView: Integer;
    FByteOffset: Int64;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** BufferView is GLTF_UNDEFINED_INDEX.
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>BufferView is GLTF_UNDEFINED_INDEX.</remarks>
    constructor Create; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "accessor.sparse.values"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "accessor.sparse.values"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "bufferView" holding the values; required.)
    /// <summary>The glTF "bufferView" holding the values; required.</summary>
    [NeonProperty('bufferView'), glTFRequired]
    property BufferView: Integer read FBufferView write FBufferView;

    //** @abstract(The glTF "byteOffset" of the values in the bufferView; 0 by default.)
    /// <summary>The glTF "byteOffset" of the values in the bufferView; 0 by default.</summary>
    [NeonProperty('byteOffset')]
    property ByteOffset: Int64 read FByteOffset write FByteOffset;
  end;

  //** @abstract(The glTF "sparse" storage of an accessor: values that replace some of its
  //** elements.)
  /// <summary>The glTF "sparse" storage of an accessor: values that replace some of its
  /// elements.</summary>
  TglTFAccessorSparse = class(TglTFProperty)
  private
    FCount: Integer;
    FIndices: TglTFAccessorSparseIndices;
    FValues: TglTFAccessorSparseValues;
  protected
    procedure ReadChildren(AJSON: TJSONObject); override;
    procedure WriteChildren(AJSON: TJSONObject); override;
    procedure Validate; override;
  public
    //** @abstract(Frees the object and its indices and values objects.)
    /// <summary>Frees the object and its indices and values objects.</summary>
    destructor Destroy; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "accessor.sparse"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "accessor.sparse"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "count": how many elements are replaced; required, at least 1.)
    /// <summary>The glTF "count": how many elements are replaced; required, at least
    /// 1.</summary>
    [NeonProperty('count'), glTFRequired]
    property Count: Integer read FCount write FCount;

    //** @abstract(The glTF "indices": which elements are replaced; required.)
    //**
    //** Owned by this object.
    /// <summary>The glTF "indices": which elements are replaced; required.</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('indices'), glTFRequired]
    property Indices: TglTFAccessorSparseIndices read FIndices;

    //** @abstract(The glTF "values": the replacement values; required.)
    //**
    //** Owned by this object.
    /// <summary>The glTF "values": the replacement values; required.</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('values'), glTFRequired]
    property Values: TglTFAccessorSparseValues read FValues;
  end;

  //** @abstract(A glTF accessor: how to read typed elements, such as vertex positions, from a
  //** bufferView.)
  /// <summary>A glTF accessor: how to read typed elements, such as vertex positions, from a
  /// bufferView.</summary>
  TglTFAccessor = class(TglTFChildOfRootProperty)
  private
    FBufferView: Integer;
    FByteOffset: Int64;
    FComponentType: Integer;
    FNormalized: Boolean;
    FCount: Integer;
    FType: string;
    FMax: TArray<Double>;
    FMin: TArray<Double>;
    FSparse: TglTFAccessorSparse;
    function GetAccessorType: TglTFAccessorType;
  protected
    procedure ReadChildren(AJSON: TJSONObject); override;
    procedure WriteChildren(AJSON: TJSONObject); override;
    procedure Validate; override;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** BufferView is GLTF_UNDEFINED_INDEX.
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>BufferView is GLTF_UNDEFINED_INDEX.</remarks>
    constructor Create; override;

    //** @abstract(Frees the object and its sparse object.)
    /// <summary>Frees the object and its sparse object.</summary>
    destructor Destroy; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "accessor"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "accessor"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(Returns how many components each element has.)
    //**
    //** @returns(1 for SCALAR, 2 to 4 for VEC2 to VEC4, 4, 9 or 16 for MAT2 to MAT4; 0 for an
    //** unknown type.)
    /// <summary>Returns how many components each element has.</summary>
    /// <returns>1 for SCALAR, 2 to 4 for VEC2 to VEC4, 4, 9 or 16 for MAT2 to MAT4; 0 for an
    /// unknown type.</returns>
    function ComponentCount: Integer;

    //** @abstract(Returns the size in bytes of one component.)
    //**
    //** @returns(1, 2 or 4; 0 for an unknown component type.)
    /// <summary>Returns the size in bytes of one component.</summary>
    /// <returns>1, 2 or 4; 0 for an unknown component type.</returns>
    function ComponentByteSize: Integer;

    //** @abstract(The glTF "bufferView" holding the data; GLTF_UNDEFINED_INDEX when not set.)
    //**
    //** Without a bufferView every element is zero unless replaced by sparse values.
    /// <summary>The glTF "bufferView" holding the data; GLTF_UNDEFINED_INDEX when not
    /// set.</summary>
    /// <remarks>Without a bufferView every element is zero unless replaced by sparse
    /// values.</remarks>
    [NeonProperty('bufferView')]
    property BufferView: Integer read FBufferView write FBufferView;

    //** @abstract(The glTF "byteOffset" of the data in the bufferView; 0 by default.)
    /// <summary>The glTF "byteOffset" of the data in the bufferView; 0 by default.</summary>
    [NeonProperty('byteOffset')]
    property ByteOffset: Int64 read FByteOffset write FByteOffset;

    //** @abstract(The glTF "componentType": the type of each component; required.)
    //**
    //** One of the GLTF_COMPONENT_* constants.
    /// <summary>The glTF "componentType": the type of each component; required.</summary>
    /// <remarks>One of the GLTF_COMPONENT_* constants.</remarks>
    [NeonProperty('componentType'), glTFRequired]
    property ComponentType: Integer read FComponentType write FComponentType;

    //** @abstract(The glTF "normalized": whether integer components map to the range 0..1 or
    //** -1..1; False by default.)
    /// <summary>The glTF "normalized": whether integer components map to the range 0..1 or
    /// -1..1; False by default.</summary>
    [NeonProperty('normalized')]
    property Normalized: Boolean read FNormalized write FNormalized;

    //** @abstract(The glTF "count": how many elements the accessor has; required, at least 1.)
    /// <summary>The glTF "count": how many elements the accessor has; required, at least
    /// 1.</summary>
    [NeonProperty('count'), glTFRequired]
    property Count: Integer read FCount write FCount;

    //** @abstract(The glTF "type": the shape of each element; required.)
    //**
    //** One of "SCALAR", "VEC2", "VEC3", "VEC4", "MAT2", "MAT3" or "MAT4". See
    //** @link(AccessorType) for a typed view.
    /// <summary>The glTF "type": the shape of each element; required.</summary>
    /// <remarks>One of "SCALAR", "VEC2", "VEC3", "VEC4", "MAT2", "MAT3" or "MAT4". See
    /// <see cref="AccessorType"/> for a typed view.</remarks>
    [NeonProperty('type'), glTFRequired]
    property &Type: string read FType write FType;

    //** @abstract(The glTF "max": the largest value of each component; empty when not set.)
    //**
    //** When set it has @link(ComponentCount) values.
    /// <summary>The glTF "max": the largest value of each component; empty when not
    /// set.</summary>
    /// <remarks>When set it has <see cref="ComponentCount"/> values.</remarks>
    [NeonProperty('max')]
    property Max: TArray<Double> read FMax write FMax;

    //** @abstract(The glTF "min": the smallest value of each component; empty when not set.)
    //**
    //** When set it has @link(ComponentCount) values.
    /// <summary>The glTF "min": the smallest value of each component; empty when not
    /// set.</summary>
    /// <remarks>When set it has <see cref="ComponentCount"/> values.</remarks>
    [NeonProperty('min')]
    property Min: TArray<Double> read FMin write FMin;

    //** @abstract(The glTF "sparse" storage; nil when not set.)
    //**
    //** Owned by this object.
    /// <summary>The glTF "sparse" storage; nil when not set.</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('sparse')]
    property Sparse: TglTFAccessorSparse read FSparse;

    //** @abstract(The "type" as an enumeration; atUnknown for any other string.)
    /// <summary>The "type" as an enumeration; atUnknown for any other string.</summary>
    property AccessorType: TglTFAccessorType read GetAccessorType;
  end;

  {$ENDREGION}

  {$REGION 'animation'}

  //** @abstract(The glTF "target" of an animation channel: the node and property it animates.)
  /// <summary>The glTF "target" of an animation channel: the node and property it
  /// animates.</summary>
  TglTFAnimationChannelTarget = class(TglTFProperty)
  private
    FNode: Integer;
    FPath: string;
    function GetAnimationPath: TglTFAnimationPath;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** Node is GLTF_UNDEFINED_INDEX.
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>Node is GLTF_UNDEFINED_INDEX.</remarks>
    constructor Create; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "animation.channel.target"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "animation.channel.target"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "node": index in @code(TglTF.Nodes) of the animated node;
    //** GLTF_UNDEFINED_INDEX when not set.)
    /// <summary>The glTF "node": index in <c>TglTF.Nodes</c> of the animated node;
    /// GLTF_UNDEFINED_INDEX when not set.</summary>
    [NeonProperty('node')]
    property Node: Integer read FNode write FNode;

    //** @abstract(The glTF "path": which property is animated; required.)
    //**
    //** One of "translation", "rotation", "scale" or "weights". See @link(AnimationPath) for a
    //** typed view.
    /// <summary>The glTF "path": which property is animated; required.</summary>
    /// <remarks>One of "translation", "rotation", "scale" or "weights". See
    /// <see cref="AnimationPath"/> for a typed view.</remarks>
    [NeonProperty('path'), glTFRequired]
    property Path: string read FPath write FPath;

    //** @abstract(The "path" as an enumeration; apUnknown for any other string.)
    /// <summary>The "path" as an enumeration; apUnknown for any other string.</summary>
    property AnimationPath: TglTFAnimationPath read GetAnimationPath;
  end;

  //** @abstract(A glTF animation channel: connects a sampler to the property it animates.)
  /// <summary>A glTF animation channel: connects a sampler to the property it
  /// animates.</summary>
  TglTFAnimationChannel = class(TglTFProperty)
  private
    FSampler: Integer;
    FTarget: TglTFAnimationChannelTarget;
  protected
    procedure ReadChildren(AJSON: TJSONObject); override;
    procedure WriteChildren(AJSON: TJSONObject); override;
  public
    //** @abstract(Frees the object and its target.)
    /// <summary>Frees the object and its target.</summary>
    destructor Destroy; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "animation.channel"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "animation.channel"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "sampler": index in the animation's Samplers; required.)
    /// <summary>The glTF "sampler": index in the animation's Samplers; required.</summary>
    [NeonProperty('sampler'), glTFRequired]
    property Sampler: Integer read FSampler write FSampler;

    //** @abstract(The glTF "target": the node and property animated; required.)
    //**
    //** Owned by this object.
    /// <summary>The glTF "target": the node and property animated; required.</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('target'), glTFRequired]
    property Target: TglTFAnimationChannelTarget read FTarget;
  end;

  //** @abstract(A glTF animation sampler: key frame times, values and how to interpolate
  //** between them.)
  /// <summary>A glTF animation sampler: key frame times, values and how to interpolate between
  /// them.</summary>
  TglTFAnimationSampler = class(TglTFProperty)
  private
    FInput: Integer;
    FInterpolation: string;
    FOutput: Integer;
    function GetInterpolationKind: TglTFInterpolation;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** Interpolation is "LINEAR".
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>Interpolation is "LINEAR".</remarks>
    constructor Create; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "animation.sampler"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "animation.sampler"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "input": index in @code(TglTF.Accessors) of the key frame times;
    //** required.)
    /// <summary>The glTF "input": index in <c>TglTF.Accessors</c> of the key frame times;
    /// required.</summary>
    [NeonProperty('input'), glTFRequired]
    property Input: Integer read FInput write FInput;

    //** @abstract(The glTF "interpolation": "LINEAR" @(the default@), "STEP" or "CUBICSPLINE".)
    /// <summary>The glTF "interpolation": "LINEAR" (the default), "STEP" or
    /// "CUBICSPLINE".</summary>
    [NeonProperty('interpolation')]
    property Interpolation: string read FInterpolation write FInterpolation;

    //** @abstract(The glTF "output": index in @code(TglTF.Accessors) of the key frame values;
    //** required.)
    /// <summary>The glTF "output": index in <c>TglTF.Accessors</c> of the key frame values;
    /// required.</summary>
    [NeonProperty('output'), glTFRequired]
    property Output: Integer read FOutput write FOutput;

    //** @abstract(The "interpolation" as an enumeration; ipUnknown for any other string.)
    /// <summary>The "interpolation" as an enumeration; ipUnknown for any other
    /// string.</summary>
    property InterpolationKind: TglTFInterpolation read GetInterpolationKind;
  end;

  //** @abstract(A glTF animation: a set of channels and the samplers they use.)
  /// <summary>A glTF animation: a set of channels and the samplers they use.</summary>
  TglTFAnimation = class(TglTFChildOfRootProperty)
  private
    FChannels: TglTFList<TglTFAnimationChannel>;
    FSamplers: TglTFList<TglTFAnimationSampler>;
    FExportOnSave: Boolean;
    FOrigin: string;
  protected
    procedure ReadChildren(AJSON: TJSONObject); override;
    procedure WriteChildren(AJSON: TJSONObject); override;
    procedure Validate; override;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** Channels and Samplers are empty lists and @link(ExportOnSave) is True.
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>Channels and Samplers are empty lists and <see cref="ExportOnSave"/> is
    /// True.</remarks>
    constructor Create; override;

    //** @abstract(Frees the object and its channels and samplers.)
    /// <summary>Frees the object and its channels and samplers.</summary>
    destructor Destroy; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "animation"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "animation"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "channels"; required, at least one.)
    //**
    //** Owned by this object.
    /// <summary>The glTF "channels"; required, at least one.</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('channels'), glTFRequired]
    property Channels: TglTFList<TglTFAnimationChannel> read FChannels;

    //** @abstract(The glTF "samplers"; required, at least one.)
    //**
    //** Owned by this object.
    /// <summary>The glTF "samplers"; required, at least one.</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('samplers'), glTFRequired]
    property Samplers: TglTFList<TglTFAnimationSampler> read FSamplers;

    //** @abstract(Whether a save writes this animation.)
    //**
    //** True by default. When False, TglTFDocument leaves the animation out of the saved
    //** file, together with the accessors, bufferViews and buffer bytes only it used; the
    //** document itself keeps them. A save choice, not part of the glTF JSON.
    /// <summary>Whether a save writes this animation.</summary>
    /// <remarks>True by default. When False, TglTFDocument leaves the animation out of the
    /// saved file, together with the accessors, bufferViews and buffer bytes only it used; the
    /// document itself keeps them. A save choice, not part of the glTF JSON.</remarks>
    [NeonIgnore]
    property ExportOnSave: Boolean read FExportOnSave write FExportOnSave;

    //** @abstract(Where the animation came from: empty for the loaded model, otherwise the
    //** name of the file it was imported from.)
    //**
    //** Set by TglTFAnimationImporter. For display only; not part of the glTF JSON.
    /// <summary>Where the animation came from: empty for the loaded model, otherwise the name
    /// of the file it was imported from.</summary>
    /// <remarks>Set by TglTFAnimationImporter. For display only; not part of the glTF
    /// JSON.</remarks>
    [NeonIgnore]
    property Origin: string read FOrigin write FOrigin;
  end;

  {$ENDREGION}

  {$REGION 'camera'}

  //** @abstract(The orthographic projection of a camera.)
  /// <summary>The orthographic projection of a camera.</summary>
  TglTFCameraOrthographic = class(TglTFProperty)
  private
    FXMag: Double;
    FYMag: Double;
    FZFar: Double;
    FZNear: Double;
  public
    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "camera.orthographic"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "camera.orthographic"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "xmag": horizontal magnification of the view; required.)
    /// <summary>The glTF "xmag": horizontal magnification of the view; required.</summary>
    [NeonProperty('xmag'), glTFRequired]
    property XMag: Double read FXMag write FXMag;

    //** @abstract(The glTF "ymag": vertical magnification of the view; required.)
    /// <summary>The glTF "ymag": vertical magnification of the view; required.</summary>
    [NeonProperty('ymag'), glTFRequired]
    property YMag: Double read FYMag write FYMag;

    //** @abstract(The glTF "zfar": distance to the far clipping plane; required.)
    /// <summary>The glTF "zfar": distance to the far clipping plane; required.</summary>
    [NeonProperty('zfar'), glTFRequired]
    property ZFar: Double read FZFar write FZFar;

    //** @abstract(The glTF "znear": distance to the near clipping plane; required.)
    /// <summary>The glTF "znear": distance to the near clipping plane; required.</summary>
    [NeonProperty('znear'), glTFRequired]
    property ZNear: Double read FZNear write FZNear;
  end;

  //** @abstract(The perspective projection of a camera.)
  /// <summary>The perspective projection of a camera.</summary>
  TglTFCameraPerspective = class(TglTFProperty)
  private
    FAspectRatio: Double;
    FYFov: Double;
    FZFar: Double;
    FZNear: Double;
  public
    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "camera.perspective"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "camera.perspective"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "aspectRatio": width divided by height; 0 when not set.)
    //**
    //** When not set, use the aspect ratio of the viewport.
    /// <summary>The glTF "aspectRatio": width divided by height; 0 when not set.</summary>
    /// <remarks>When not set, use the aspect ratio of the viewport.</remarks>
    [NeonProperty('aspectRatio')]
    property AspectRatio: Double read FAspectRatio write FAspectRatio;

    //** @abstract(The glTF "yfov": vertical field of view in radians; required.)
    /// <summary>The glTF "yfov": vertical field of view in radians; required.</summary>
    [NeonProperty('yfov'), glTFRequired]
    property YFov: Double read FYFov write FYFov;

    //** @abstract(The glTF "zfar": distance to the far clipping plane; 0 when not set.)
    //**
    //** When not set, the projection is infinite.
    /// <summary>The glTF "zfar": distance to the far clipping plane; 0 when not set.</summary>
    /// <remarks>When not set, the projection is infinite.</remarks>
    [NeonProperty('zfar')]
    property ZFar: Double read FZFar write FZFar;

    //** @abstract(The glTF "znear": distance to the near clipping plane; required.)
    /// <summary>The glTF "znear": distance to the near clipping plane; required.</summary>
    [NeonProperty('znear'), glTFRequired]
    property ZNear: Double read FZNear write FZNear;
  end;

  //** @abstract(A glTF camera: a perspective or orthographic projection.)
  //**
  //** The object matching @link(Type) is required: Perspective for "perspective", Orthographic
  //** for "orthographic".
  /// <summary>A glTF camera: a perspective or orthographic projection.</summary>
  /// <remarks>The object matching <see cref="Type"/> is required: Perspective for
  /// "perspective", Orthographic for "orthographic".</remarks>
  TglTFCamera = class(TglTFChildOfRootProperty)
  private
    FOrthographic: TglTFCameraOrthographic;
    FPerspective: TglTFCameraPerspective;
    FType: string;
    function GetCameraType: TglTFCameraType;
  protected
    procedure ReadChildren(AJSON: TJSONObject); override;
    procedure WriteChildren(AJSON: TJSONObject); override;
    procedure Validate; override;
  public
    //** @abstract(Frees the object and its projection objects.)
    /// <summary>Frees the object and its projection objects.</summary>
    destructor Destroy; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "camera"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "camera"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "orthographic" projection; nil when not set.)
    //**
    //** Owned by this object.
    /// <summary>The glTF "orthographic" projection; nil when not set.</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('orthographic')]
    property Orthographic: TglTFCameraOrthographic read FOrthographic;

    //** @abstract(The glTF "perspective" projection; nil when not set.)
    //**
    //** Owned by this object.
    /// <summary>The glTF "perspective" projection; nil when not set.</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('perspective')]
    property Perspective: TglTFCameraPerspective read FPerspective;

    //** @abstract(The glTF "type": "perspective" or "orthographic"; required.)
    //**
    //** See @link(CameraType) for a typed view.
    /// <summary>The glTF "type": "perspective" or "orthographic"; required.</summary>
    /// <remarks>See <see cref="CameraType"/> for a typed view.</remarks>
    [NeonProperty('type'), glTFRequired]
    property &Type: string read FType write FType;

    //** @abstract(The "type" as an enumeration; ctUnknown for any other string.)
    /// <summary>The "type" as an enumeration; ctUnknown for any other string.</summary>
    property CameraType: TglTFCameraType read GetCameraType;
  end;

  {$ENDREGION}

  {$REGION 'image / sampler / texture'}

  //** @abstract(A glTF image: texture data stored in a file, a data URI or a bufferView.)
  //**
  //** The bytes of the image file are in @link(Data). Whether a save stores them inside
  //** the glTF file or as a separate file is decided by @link(Embed).
  /// <summary>A glTF image: texture data stored in a file, a data URI or a
  /// bufferView.</summary>
  /// <remarks>The bytes of the image file are in <see cref="Data"/>. Whether a save stores
  /// them inside the glTF file or as a separate file is decided by
  /// <see cref="Embed"/>.</remarks>
  TglTFImage = class(TglTFChildOfRootProperty)
  private
    FUri: string;
    FMimeType: string;
    FBufferView: Integer;
    FData: TBytes;
    FEmbed: Boolean;
    FShared: Boolean;
    FSourceFile: string;
  protected
    procedure Validate; override;
  public
    //** @abstract(Creates an image with no uri and no bufferView.)
    //**
    //** @link(BufferView) is GLTF_UNDEFINED_INDEX and @link(Embed) is False.
    /// <summary>Creates an image with no uri and no bufferView.</summary>
    /// <remarks><see cref="BufferView"/> is GLTF_UNDEFINED_INDEX and <see cref="Embed"/> is
    /// False.</remarks>
    constructor Create; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "image"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "image"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(Tells whether the uri holds the image itself as a "data:" URI.)
    //**
    //** @returns(True for a data URI, False for a file reference or no uri.)
    /// <summary>Tells whether the uri holds the image itself as a "data:" URI.</summary>
    /// <returns>True for a data URI, False for a file reference or no uri.</returns>
    function IsDataUri: Boolean;

    //** @abstract(Returns the best known MIME type of the image.)
    //**
    //** Tries, in order: @link(MimeType), the data URI's type, the file extension of the
    //** uri, then the signature at the start of @link(Data) (PNG, JPEG, WebP).
    //**
    //** @returns(For example @code(image/png); empty when the type cannot be told.)
    /// <summary>Returns the best known MIME type of the image.</summary>
    /// <returns>For example <c>image/png</c>; empty when the type cannot be told.</returns>
    /// <remarks>Tries, in order: <see cref="MimeType"/>, the data URI's type, the file
    /// extension of the uri, then the signature at the start of <see cref="Data"/> (PNG,
    /// JPEG, WebP).</remarks>
    function EffectiveMimeType: string;

    //** @abstract(The bytes of the image file; nil when the file is missing.)
    //**
    //** Filled by TglTFDocument when loading, from a data URI, an external file or a copy
    //** of its bufferView, and used when saving. Not part of the glTF JSON.
    /// <summary>The bytes of the image file; nil when the file is missing.</summary>
    /// <remarks>Filled by TglTFDocument when loading, from a data URI, an external file or
    /// a copy of its bufferView, and used when saving. Not part of the glTF
    /// JSON.</remarks>
    [NeonIgnore]
    property Data: TBytes read FData write FData;

    //** @abstract(Whether a save stores the image inside the glTF file, when the save lets
    //** each image decide.)
    //**
    //** Only used by a save whose ImageSaveMode is ismPerImage; by default the format decides
    //** @(see TglTFSaveOptions in glTF.Document@). True stores it inside the saved file: in the
    //** BIN chunk for GLB, in a base64 data-URI buffer for glTF. False writes it as a separate
    //** file next to the saved file only; an image that was inside a buffer is taken out of it,
    //** so its bytes are not stored twice. Loading sets it to whether the image was already
    //** inside the file @(a data URI or a bufferView@). A save choice, not part of the glTF
    //** JSON.
    /// <summary>Whether a save stores the image inside the glTF file, when the save lets each
    /// image decide.</summary>
    /// <remarks>Only used by a save whose ImageSaveMode is ismPerImage; by default the format
    /// decides (see TglTFSaveOptions in glTF.Document). True stores it inside the saved file: in the BIN chunk for GLB, in a base64
    /// data-URI buffer for glTF. False writes it as a separate file next to the saved file
    /// only; an image that was inside a buffer is taken out of it, so its bytes are not stored
    /// twice. Loading sets it to whether the image was already inside the file (a data URI or a
    /// bufferView). A save choice, not part of the glTF JSON.</remarks>
    [NeonIgnore]
    property Embed: Boolean read FEmbed write FEmbed;

    //** @abstract(Whether the image file may be shared with other models when saved as a
    //** separate file.)
    //**
    //** Only used when @link(Embed) is False. When True and a file already exists where the
    //** image is to be saved, that file is used as it is: it is neither overwritten nor
    //** renamed, even if its bytes differ, as other models rely on it. A relative uri that
    //** leads outside the output folder, such as "../textures/wood.png", is kept, so that
    //** models can share a common texture folder. When False @(the default@), saving never
    //** overwrites a different file: the image gets a unique name instead. A save choice, not
    //** part of the glTF JSON.
    /// <summary>Whether the image file may be shared with other models when saved as a separate
    /// file.</summary>
    /// <remarks>Only used when <see cref="Embed"/> is False. When True and a file already
    /// exists where the image is to be saved, that file is used as it is: it is neither
    /// overwritten nor renamed, even if its bytes differ, as other models rely on it. A
    /// relative uri that leads outside the output folder, such as "../textures/wood.png", is
    /// kept, so that models can share a common texture folder. When False (the default), saving
    /// never overwrites a different file: the image gets a unique name instead. A save choice,
    /// not part of the glTF JSON.</remarks>
    [NeonIgnore]
    property Shared: Boolean read FShared write FShared;

    //** @abstract(The file @link(Data) was read from; empty for an image that was inside
    //** the glTF.)
    //**
    //** Set when the image is loaded from an external file, or from a file found later with
    //** TglTFDocument.SupplyResourceFile. Saving copies from it when the image must be a
    //** separate file and its data is not loaded. Not part of the glTF JSON.
    /// <summary>The file <see cref="Data"/> was read from; empty for an image that was
    /// inside the glTF.</summary>
    /// <remarks>Set when the image is loaded from an external file, or from a file found
    /// later with TglTFDocument.SupplyResourceFile. Saving copies from it when the image
    /// must be a separate file and its data is not loaded. Not part of the glTF
    /// JSON.</remarks>
    [NeonIgnore]
    property SourceFile: string read FSourceFile write FSourceFile;

    //** @abstract(The glTF "uri": a file path relative to the glTF, or a data URI.)
    //**
    //** Empty when the image is in a bufferView.
    /// <summary>The glTF "uri": a file path relative to the glTF, or a data URI.</summary>
    /// <remarks>Empty when the image is in a bufferView.</remarks>
    [NeonProperty('uri')]
    property Uri: string read FUri write FUri;

    //** @abstract(The glTF "mimeType", for example @code(image/png) or @code(image/jpeg).)
    //**
    //** Required when the image is in a bufferView.
    /// <summary>The glTF "mimeType", for example <c>image/png</c> or
    /// <c>image/jpeg</c>.</summary>
    /// <remarks>Required when the image is in a bufferView.</remarks>
    [NeonProperty('mimeType')]
    property MimeType: string read FMimeType write FMimeType;

    //** @abstract(The glTF "bufferView" holding the image; GLTF_UNDEFINED_INDEX when it
    //** has none.)
    /// <summary>The glTF "bufferView" holding the image; GLTF_UNDEFINED_INDEX when it has
    /// none.</summary>
    [NeonProperty('bufferView')]
    property BufferView: Integer read FBufferView write FBufferView;
  end;

  //** @abstract(A glTF sampler: texture filtering and wrapping.)
  /// <summary>A glTF sampler: texture filtering and wrapping.</summary>
  TglTFSampler = class(TglTFChildOfRootProperty)
  private
    FMagFilter: Integer;
    FMinFilter: Integer;
    FWrapS: Integer;
    FWrapT: Integer;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** WrapS and WrapT are GLTF_WRAP_REPEAT; the filters are 0 @(not set@).
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>WrapS and WrapT are GLTF_WRAP_REPEAT; the filters are 0 (not set).</remarks>
    constructor Create; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "sampler"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "sampler"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "magFilter": filter for magnification; 0 when not set.)
    //**
    //** GLTF_FILTER_NEAREST or GLTF_FILTER_LINEAR.
    /// <summary>The glTF "magFilter": filter for magnification; 0 when not set.</summary>
    /// <remarks>GLTF_FILTER_NEAREST or GLTF_FILTER_LINEAR.</remarks>
    [NeonProperty('magFilter')]
    property MagFilter: Integer read FMagFilter write FMagFilter;

    //** @abstract(The glTF "minFilter": filter for minification; 0 when not set.)
    //**
    //** One of the GLTF_FILTER_* constants.
    /// <summary>The glTF "minFilter": filter for minification; 0 when not set.</summary>
    /// <remarks>One of the GLTF_FILTER_* constants.</remarks>
    [NeonProperty('minFilter')]
    property MinFilter: Integer read FMinFilter write FMinFilter;

    //** @abstract(The glTF "wrapS": wrapping along U; GLTF_WRAP_REPEAT by default.)
    /// <summary>The glTF "wrapS": wrapping along U; GLTF_WRAP_REPEAT by default.</summary>
    [NeonProperty('wrapS')]
    property WrapS: Integer read FWrapS write FWrapS;

    //** @abstract(The glTF "wrapT": wrapping along V; GLTF_WRAP_REPEAT by default.)
    /// <summary>The glTF "wrapT": wrapping along V; GLTF_WRAP_REPEAT by default.</summary>
    [NeonProperty('wrapT')]
    property WrapT: Integer read FWrapT write FWrapT;
  end;

  //** @abstract(A glTF texture: an image combined with a sampler.)
  /// <summary>A glTF texture: an image combined with a sampler.</summary>
  TglTFTexture = class(TglTFChildOfRootProperty)
  private
    FSampler: Integer;
    FSource: Integer;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** Sampler and Source are GLTF_UNDEFINED_INDEX.
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>Sampler and Source are GLTF_UNDEFINED_INDEX.</remarks>
    constructor Create; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "texture"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "texture"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "sampler": index in @code(TglTF.Samplers); GLTF_UNDEFINED_INDEX when
    //** not set.)
    //**
    //** Without a sampler, use repeat wrapping and automatic filtering.
    /// <summary>The glTF "sampler": index in <c>TglTF.Samplers</c>; GLTF_UNDEFINED_INDEX when
    /// not set.</summary>
    /// <remarks>Without a sampler, use repeat wrapping and automatic filtering.</remarks>
    [NeonProperty('sampler')]
    property Sampler: Integer read FSampler write FSampler;

    //** @abstract(The glTF "source": index in @code(TglTF.Images); GLTF_UNDEFINED_INDEX when
    //** not set.)
    //**
    //** An extension may supply the image instead.
    /// <summary>The glTF "source": index in <c>TglTF.Images</c>; GLTF_UNDEFINED_INDEX when not
    /// set.</summary>
    /// <remarks>An extension may supply the image instead.</remarks>
    [NeonProperty('source')]
    property Source: Integer read FSource write FSource;
  end;

  {$ENDREGION}

  {$REGION 'material'}

  //** @abstract(A reference from a material to a texture.)
  /// <summary>A reference from a material to a texture.</summary>
  TglTFTextureInfo = class(TglTFProperty)
  private
    FIndex: Integer;
    FTexCoord: Integer;
  public
    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "textureInfo"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "textureInfo"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "index": index in @code(TglTF.Textures); required.)
    /// <summary>The glTF "index": index in <c>TglTF.Textures</c>; required.</summary>
    [NeonProperty('index'), glTFRequired]
    property Index: Integer read FIndex write FIndex;

    //** @abstract(The glTF "texCoord": which TEXCOORD_n attribute gives the coordinates; 0 by
    //** default.)
    /// <summary>The glTF "texCoord": which TEXCOORD_n attribute gives the coordinates; 0 by
    /// default.</summary>
    [NeonProperty('texCoord')]
    property TexCoord: Integer read FTexCoord write FTexCoord;
  end;

  //** @abstract(A reference to a normal map, with its scale.)
  /// <summary>A reference to a normal map, with its scale.</summary>
  TglTFNormalTextureInfo = class(TglTFTextureInfo)
  private
    FScale: Double;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** Scale is 1.
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>Scale is 1.</remarks>
    constructor Create; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "material.normalTextureInfo"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "material.normalTextureInfo"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "scale" applied to the normal vectors' X and Y; 1 by default.)
    /// <summary>The glTF "scale" applied to the normal vectors' X and Y; 1 by
    /// default.</summary>
    [NeonProperty('scale')]
    property Scale: Double read FScale write FScale;
  end;

  //** @abstract(A reference to an occlusion map, with its strength.)
  /// <summary>A reference to an occlusion map, with its strength.</summary>
  TglTFOcclusionTextureInfo = class(TglTFTextureInfo)
  private
    FStrength: Double;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** Strength is 1.
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>Strength is 1.</remarks>
    constructor Create; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "material.occlusionTextureInfo"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "material.occlusionTextureInfo"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "strength" of the occlusion, 0 to 1; 1 by default.)
    /// <summary>The glTF "strength" of the occlusion, 0 to 1; 1 by default.</summary>
    [NeonProperty('strength')]
    property Strength: Double read FStrength write FStrength;
  end;

  //** @abstract(The metallic-roughness parameters of a material.)
  /// <summary>The metallic-roughness parameters of a material.</summary>
  TglTFPbrMetallicRoughness = class(TglTFProperty)
  private
    FBaseColorFactor: TArray<Double>;
    FBaseColorTexture: TglTFTextureInfo;
    FMetallicFactor: Double;
    FRoughnessFactor: Double;
    FMetallicRoughnessTexture: TglTFTextureInfo;
  protected
    procedure ReadChildren(AJSON: TJSONObject); override;
    procedure WriteChildren(AJSON: TJSONObject); override;
    procedure Validate; override;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** BaseColorFactor is [1, 1, 1, 1]; MetallicFactor and RoughnessFactor are 1.
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>BaseColorFactor is [1, 1, 1, 1]; MetallicFactor and RoughnessFactor are
    /// 1.</remarks>
    constructor Create; override;

    //** @abstract(Frees the object and its texture references.)
    /// <summary>Frees the object and its texture references.</summary>
    destructor Destroy; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "material.pbrMetallicRoughness"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "material.pbrMetallicRoughness"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "baseColorFactor": linear RGBA multiplier of the base colour; [1, 1,
    //** 1, 1] by default.)
    //**
    //** Always 4 values.
    /// <summary>The glTF "baseColorFactor": linear RGBA multiplier of the base colour; [1, 1,
    /// 1, 1] by default.</summary>
    /// <remarks>Always 4 values.</remarks>
    [NeonProperty('baseColorFactor')]
    property BaseColorFactor: TArray<Double> read FBaseColorFactor write FBaseColorFactor;

    //** @abstract(The glTF "baseColorTexture"; nil when not set.)
    //**
    //** Owned by this object.
    /// <summary>The glTF "baseColorTexture"; nil when not set.</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('baseColorTexture')]
    property BaseColorTexture: TglTFTextureInfo read FBaseColorTexture;

    //** @abstract(The glTF "metallicFactor", 0 to 1; 1 by default.)
    /// <summary>The glTF "metallicFactor", 0 to 1; 1 by default.</summary>
    [NeonProperty('metallicFactor')]
    property MetallicFactor: Double read FMetallicFactor write FMetallicFactor;

    //** @abstract(The glTF "roughnessFactor", 0 to 1; 1 by default.)
    /// <summary>The glTF "roughnessFactor", 0 to 1; 1 by default.</summary>
    [NeonProperty('roughnessFactor')]
    property RoughnessFactor: Double read FRoughnessFactor write FRoughnessFactor;

    //** @abstract(The glTF "metallicRoughnessTexture"; nil when not set.)
    //**
    //** Metalness is read from the blue channel and roughness from the green channel. Owned by
    //** this object.
    /// <summary>The glTF "metallicRoughnessTexture"; nil when not set.</summary>
    /// <remarks>Metalness is read from the blue channel and roughness from the green channel.
    /// Owned by this object.</remarks>
    [NeonProperty('metallicRoughnessTexture')]
    property MetallicRoughnessTexture: TglTFTextureInfo read FMetallicRoughnessTexture;
  end;

  //** @abstract(A glTF material: how a surface looks.)
  /// <summary>A glTF material: how a surface looks.</summary>
  TglTFMaterial = class(TglTFChildOfRootProperty)
  private
    FPbrMetallicRoughness: TglTFPbrMetallicRoughness;
    FNormalTexture: TglTFNormalTextureInfo;
    FOcclusionTexture: TglTFOcclusionTextureInfo;
    FEmissiveTexture: TglTFTextureInfo;
    FEmissiveFactor: TArray<Double>;
    FAlphaMode: string;
    FAlphaCutoff: Double;
    FDoubleSided: Boolean;
    function GetAlphaModeKind: TglTFAlphaMode;
  protected
    procedure ReadChildren(AJSON: TJSONObject); override;
    procedure WriteChildren(AJSON: TJSONObject); override;
    procedure Validate; override;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** EmissiveFactor is [0, 0, 0], AlphaMode "OPAQUE", AlphaCutoff 0.5 and DoubleSided False.
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>EmissiveFactor is [0, 0, 0], AlphaMode "OPAQUE", AlphaCutoff 0.5 and
    /// DoubleSided False.</remarks>
    constructor Create; override;

    //** @abstract(Frees the object and its nested parameter and texture objects.)
    /// <summary>Frees the object and its nested parameter and texture objects.</summary>
    destructor Destroy; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "material"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "material"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "pbrMetallicRoughness" parameters; nil when not set.)
    //**
    //** When nil, the spec defaults apply. Owned by this object.
    /// <summary>The glTF "pbrMetallicRoughness" parameters; nil when not set.</summary>
    /// <remarks>When nil, the spec defaults apply. Owned by this object.</remarks>
    [NeonProperty('pbrMetallicRoughness')]
    property PbrMetallicRoughness: TglTFPbrMetallicRoughness read FPbrMetallicRoughness;

    //** @abstract(The glTF "normalTexture"; nil when not set.)
    //**
    //** Owned by this object.
    /// <summary>The glTF "normalTexture"; nil when not set.</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('normalTexture')]
    property NormalTexture: TglTFNormalTextureInfo read FNormalTexture;

    //** @abstract(The glTF "occlusionTexture"; nil when not set.)
    //**
    //** Owned by this object.
    /// <summary>The glTF "occlusionTexture"; nil when not set.</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('occlusionTexture')]
    property OcclusionTexture: TglTFOcclusionTextureInfo read FOcclusionTexture;

    //** @abstract(The glTF "emissiveTexture"; nil when not set.)
    //**
    //** Owned by this object.
    /// <summary>The glTF "emissiveTexture"; nil when not set.</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('emissiveTexture')]
    property EmissiveTexture: TglTFTextureInfo read FEmissiveTexture;

    //** @abstract(The glTF "emissiveFactor": linear RGB emitted light; [0, 0, 0] by default.)
    //**
    //** Always 3 values.
    /// <summary>The glTF "emissiveFactor": linear RGB emitted light; [0, 0, 0] by
    /// default.</summary>
    /// <remarks>Always 3 values.</remarks>
    [NeonProperty('emissiveFactor')]
    property EmissiveFactor: TArray<Double> read FEmissiveFactor write FEmissiveFactor;

    //** @abstract(The glTF "alphaMode": "OPAQUE" @(the default@), "MASK" or "BLEND".)
    //**
    //** See @link(AlphaModeKind) for a typed view.
    /// <summary>The glTF "alphaMode": "OPAQUE" (the default), "MASK" or "BLEND".</summary>
    /// <remarks>See <see cref="AlphaModeKind"/> for a typed view.</remarks>
    [NeonProperty('alphaMode')]
    property AlphaMode: string read FAlphaMode write FAlphaMode;

    //** @abstract(The glTF "alphaCutoff": alpha below which a MASK material is transparent; 0.5
    //** by default.)
    /// <summary>The glTF "alphaCutoff": alpha below which a MASK material is transparent; 0.5
    /// by default.</summary>
    [NeonProperty('alphaCutoff')]
    property AlphaCutoff: Double read FAlphaCutoff write FAlphaCutoff;

    //** @abstract(The glTF "doubleSided": whether back faces are drawn; False by default.)
    /// <summary>The glTF "doubleSided": whether back faces are drawn; False by
    /// default.</summary>
    [NeonProperty('doubleSided')]
    property DoubleSided: Boolean read FDoubleSided write FDoubleSided;

    //** @abstract(The "alphaMode" as an enumeration; amUnknown for any other string.)
    /// <summary>The "alphaMode" as an enumeration; amUnknown for any other string.</summary>
    property AlphaModeKind: TglTFAlphaMode read GetAlphaModeKind;
  end;

  {$ENDREGION}

  {$REGION 'mesh'}

  //** @abstract(A glTF mesh primitive: geometry drawn with one material.)
  /// <summary>A glTF mesh primitive: geometry drawn with one material.</summary>
  TglTFMeshPrimitive = class(TglTFProperty)
  private
    FAttributes: TglTFAttributeMap;
    FIndices: Integer;
    FMaterial: Integer;
    FMode: Integer;
    FTargets: TObjectList<TglTFAttributeMap>;
    procedure ReadAttributeMap(AJSON: TJSONValue; const APath: string; AMap: TglTFAttributeMap);
  protected
    procedure ReadChildren(AJSON: TJSONObject); override;
    procedure WriteChildren(AJSON: TJSONObject); override;
    procedure Validate; override;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** Indices and Material are GLTF_UNDEFINED_INDEX and Mode is GLTF_MODE_TRIANGLES;
    //** Attributes and Targets are empty.
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>Indices and Material are GLTF_UNDEFINED_INDEX and Mode is GLTF_MODE_TRIANGLES;
    /// Attributes and Targets are empty.</remarks>
    constructor Create; override;

    //** @abstract(Frees the object and its attribute maps.)
    /// <summary>Frees the object and its attribute maps.</summary>
    destructor Destroy; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "mesh.primitive"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "mesh.primitive"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(Tells whether the primitive has an attribute.)
    //**
    //** @param(ASemantic Attribute name, for example POSITION; case-sensitive.)
    //**
    //** @returns(True when the attribute is present.)
    /// <summary>Tells whether the primitive has an attribute.</summary>
    /// <param name="ASemantic">Attribute name, for example POSITION; case-sensitive.</param>
    /// <returns>True when the attribute is present.</returns>
    function HasAttribute(const ASemantic: string): Boolean;

    //** @abstract(Returns the accessor index of an attribute.)
    //**
    //** @param(ASemantic Attribute name, for example POSITION; case-sensitive.)
    //**
    //** @returns(Index in @code(TglTF.Accessors); GLTF_UNDEFINED_INDEX when the attribute is
    //** absent.)
    /// <summary>Returns the accessor index of an attribute.</summary>
    /// <param name="ASemantic">Attribute name, for example POSITION; case-sensitive.</param>
    /// <returns>Index in <c>TglTF.Accessors</c>; GLTF_UNDEFINED_INDEX when the attribute is
    /// absent.</returns>
    function GetAttribute(const ASemantic: string): Integer;

    //** @abstract(The glTF "attributes": attribute name to accessor index; required, at least
    //** one.)
    //**
    //** Owned by this object.
    /// <summary>The glTF "attributes": attribute name to accessor index; required, at least
    /// one.</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('attributes'), glTFRequired]
    property Attributes: TglTFAttributeMap read FAttributes;

    //** @abstract(The glTF "indices": index in @code(TglTF.Accessors) of the vertex indices;
    //** GLTF_UNDEFINED_INDEX when not set.)
    //**
    //** When not set, the geometry is not indexed.
    /// <summary>The glTF "indices": index in <c>TglTF.Accessors</c> of the vertex indices;
    /// GLTF_UNDEFINED_INDEX when not set.</summary>
    /// <remarks>When not set, the geometry is not indexed.</remarks>
    [NeonProperty('indices')]
    property Indices: Integer read FIndices write FIndices;

    //** @abstract(The glTF "material": index in @code(TglTF.Materials); GLTF_UNDEFINED_INDEX
    //** when not set.)
    //**
    //** When not set, the default material is used.
    /// <summary>The glTF "material": index in <c>TglTF.Materials</c>; GLTF_UNDEFINED_INDEX when
    /// not set.</summary>
    /// <remarks>When not set, the default material is used.</remarks>
    [NeonProperty('material')]
    property Material: Integer read FMaterial write FMaterial;

    //** @abstract(The glTF "mode": the kind of primitive; GLTF_MODE_TRIANGLES by default.)
    //**
    //** One of the GLTF_MODE_* constants.
    /// <summary>The glTF "mode": the kind of primitive; GLTF_MODE_TRIANGLES by
    /// default.</summary>
    /// <remarks>One of the GLTF_MODE_* constants.</remarks>
    [NeonProperty('mode')]
    property Mode: Integer read FMode write FMode;

    //** @abstract(The glTF "targets": the morph targets, each an attribute map; empty when
    //** none.)
    //**
    //** Owned by this object.
    /// <summary>The glTF "targets": the morph targets, each an attribute map; empty when
    /// none.</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('targets')]
    property Targets: TObjectList<TglTFAttributeMap> read FTargets;
  end;

  //** @abstract(A glTF mesh: a set of primitives drawn together.)
  /// <summary>A glTF mesh: a set of primitives drawn together.</summary>
  TglTFMesh = class(TglTFChildOfRootProperty)
  private
    FPrimitives: TglTFList<TglTFMeshPrimitive>;
    FWeights: TArray<Double>;
  protected
    procedure ReadChildren(AJSON: TJSONObject); override;
    procedure WriteChildren(AJSON: TJSONObject); override;
    procedure Validate; override;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** Primitives is an empty list.
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>Primitives is an empty list.</remarks>
    constructor Create; override;

    //** @abstract(Frees the object and its primitives.)
    /// <summary>Frees the object and its primitives.</summary>
    destructor Destroy; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "mesh"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "mesh"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "primitives"; required, at least one.)
    //**
    //** Owned by this object.
    /// <summary>The glTF "primitives"; required, at least one.</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('primitives'), glTFRequired]
    property Primitives: TglTFList<TglTFMeshPrimitive> read FPrimitives;

    //** @abstract(The glTF "weights": default morph target weights; empty when not set.)
    /// <summary>The glTF "weights": default morph target weights; empty when not set.</summary>
    [NeonProperty('weights')]
    property Weights: TArray<Double> read FWeights write FWeights;
  end;

  {$ENDREGION}

  {$REGION 'node / scene / skin'}

  //** @abstract(A glTF node: an element of the scene hierarchy with a transform.)
  //**
  //** The local transform is either @link(Matrix) or @link(Translation), @link(Rotation) and
  //** @link(Scale); see @link(HasMatrix).
  /// <summary>A glTF node: an element of the scene hierarchy with a transform.</summary>
  /// <remarks>The local transform is either <see cref="Matrix"/> or <see cref="Translation"/>,
  /// <see cref="Rotation"/> and <see cref="Scale"/>; see <see cref="HasMatrix"/>.</remarks>
  TglTFNode = class(TglTFChildOfRootProperty)
  private
    FCamera: Integer;
    FChildren: TArray<Integer>;
    FSkin: Integer;
    FMatrix: TArray<Double>;
    FMesh: Integer;
    FRotation: TArray<Double>;
    FScale: TArray<Double>;
    FTranslation: TArray<Double>;
    FWeights: TArray<Double>;
  protected
    procedure Validate; override;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** Camera, Skin and Mesh are GLTF_UNDEFINED_INDEX; Matrix is the identity, Rotation [0, 0,
    //** 0, 1], Scale [1, 1, 1] and Translation [0, 0, 0].
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>Camera, Skin and Mesh are GLTF_UNDEFINED_INDEX; Matrix is the identity,
    /// Rotation [0, 0, 0, 1], Scale [1, 1, 1] and Translation [0, 0, 0].</remarks>
    constructor Create; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "node"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "node"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(Tells whether the loaded node gave its transform as a matrix.)
    //**
    //** Reflects the loaded JSON, not later changes.
    //**
    //** @returns(True when "matrix" was present; False when the transform is translation,
    //** rotation and scale.)
    /// <summary>Tells whether the loaded node gave its transform as a matrix.</summary>
    /// <returns>True when "matrix" was present; False when the transform is translation,
    /// rotation and scale.</returns>
    /// <remarks>Reflects the loaded JSON, not later changes.</remarks>
    function HasMatrix: Boolean;

    //** @abstract(The glTF "camera": index in @code(TglTF.Cameras); GLTF_UNDEFINED_INDEX when
    //** not set.)
    /// <summary>The glTF "camera": index in <c>TglTF.Cameras</c>; GLTF_UNDEFINED_INDEX when not
    /// set.</summary>
    [NeonProperty('camera')]
    property Camera: Integer read FCamera write FCamera;

    //** @abstract(The glTF "children": indices in @code(TglTF.Nodes) of the child nodes; empty
    //** when none.)
    /// <summary>The glTF "children": indices in <c>TglTF.Nodes</c> of the child nodes; empty
    /// when none.</summary>
    [NeonProperty('children')]
    property Children: TArray<Integer> read FChildren write FChildren;

    //** @abstract(The glTF "skin": index in @code(TglTF.Skins); GLTF_UNDEFINED_INDEX when not
    //** set.)
    /// <summary>The glTF "skin": index in <c>TglTF.Skins</c>; GLTF_UNDEFINED_INDEX when not
    /// set.</summary>
    [NeonProperty('skin')]
    property Skin: Integer read FSkin write FSkin;

    //** @abstract(The glTF "matrix": the local transform as 16 numbers in column-major order;
    //** the identity by default.)
    /// <summary>The glTF "matrix": the local transform as 16 numbers in column-major order; the
    /// identity by default.</summary>
    [NeonProperty('matrix')]
    property Matrix: TArray<Double> read FMatrix write FMatrix;

    //** @abstract(The glTF "mesh": index in @code(TglTF.Meshes); GLTF_UNDEFINED_INDEX when not
    //** set.)
    /// <summary>The glTF "mesh": index in <c>TglTF.Meshes</c>; GLTF_UNDEFINED_INDEX when not
    /// set.</summary>
    [NeonProperty('mesh')]
    property Mesh: Integer read FMesh write FMesh;

    //** @abstract(The glTF "rotation": a unit quaternion x, y, z, w; [0, 0, 0, 1] by default.)
    /// <summary>The glTF "rotation": a unit quaternion x, y, z, w; [0, 0, 0, 1] by
    /// default.</summary>
    [NeonProperty('rotation')]
    property Rotation: TArray<Double> read FRotation write FRotation;

    //** @abstract(The glTF "scale" along x, y and z; [1, 1, 1] by default.)
    /// <summary>The glTF "scale" along x, y and z; [1, 1, 1] by default.</summary>
    [NeonProperty('scale')]
    property Scale: TArray<Double> read FScale write FScale;

    //** @abstract(The glTF "translation" along x, y and z; [0, 0, 0] by default.)
    /// <summary>The glTF "translation" along x, y and z; [0, 0, 0] by default.</summary>
    [NeonProperty('translation')]
    property Translation: TArray<Double> read FTranslation write FTranslation;

    //** @abstract(The glTF "weights": morph target weights of the node's mesh; empty when not
    //** set.)
    /// <summary>The glTF "weights": morph target weights of the node's mesh; empty when not
    /// set.</summary>
    [NeonProperty('weights')]
    property Weights: TArray<Double> read FWeights write FWeights;
  end;

  //** @abstract(A glTF scene: the root nodes of a hierarchy to show.)
  /// <summary>A glTF scene: the root nodes of a hierarchy to show.</summary>
  TglTFScene = class(TglTFChildOfRootProperty)
  private
    FNodes: TArray<Integer>;
  public
    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "scene"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "scene"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "nodes": indices in @code(TglTF.Nodes) of the root nodes; empty when
    //** none.)
    /// <summary>The glTF "nodes": indices in <c>TglTF.Nodes</c> of the root nodes; empty when
    /// none.</summary>
    [NeonProperty('nodes')]
    property Nodes: TArray<Integer> read FNodes write FNodes;
  end;

  //** @abstract(A glTF skin: the joints that deform a skinned mesh.)
  /// <summary>A glTF skin: the joints that deform a skinned mesh.</summary>
  TglTFSkin = class(TglTFChildOfRootProperty)
  private
    FInverseBindMatrices: Integer;
    FSkeleton: Integer;
    FJoints: TArray<Integer>;
  protected
    procedure Validate; override;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** InverseBindMatrices and Skeleton are GLTF_UNDEFINED_INDEX.
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>InverseBindMatrices and Skeleton are GLTF_UNDEFINED_INDEX.</remarks>
    constructor Create; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "skin"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "skin"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(The glTF "inverseBindMatrices": index in @code(TglTF.Accessors);
    //** GLTF_UNDEFINED_INDEX when not set.)
    //**
    //** When not set, every inverse bind matrix is the identity.
    /// <summary>The glTF "inverseBindMatrices": index in <c>TglTF.Accessors</c>;
    /// GLTF_UNDEFINED_INDEX when not set.</summary>
    /// <remarks>When not set, every inverse bind matrix is the identity.</remarks>
    [NeonProperty('inverseBindMatrices')]
    property InverseBindMatrices: Integer read FInverseBindMatrices write FInverseBindMatrices;

    //** @abstract(The glTF "skeleton": index in @code(TglTF.Nodes) of the skeleton root;
    //** GLTF_UNDEFINED_INDEX when not set.)
    /// <summary>The glTF "skeleton": index in <c>TglTF.Nodes</c> of the skeleton root;
    /// GLTF_UNDEFINED_INDEX when not set.</summary>
    [NeonProperty('skeleton')]
    property Skeleton: Integer read FSkeleton write FSkeleton;

    //** @abstract(The glTF "joints": indices in @code(TglTF.Nodes) of the joints; required, at
    //** least one.)
    /// <summary>The glTF "joints": indices in <c>TglTF.Nodes</c> of the joints; required, at
    /// least one.</summary>
    [NeonProperty('joints'), glTFRequired]
    property Joints: TArray<Integer> read FJoints write FJoints;
  end;

  {$ENDREGION}

  {$REGION 'glTF (root)'}

  //** @abstract(The root object of a glTF asset.)
  //**
  //** Owns every object of the document. Other objects refer to each other by index in these
  //** lists, so removing or reordering items changes those references. Usually held by a
  //** TglTFDocument.
  /// <summary>The root object of a glTF asset.</summary>
  /// <remarks>Owns every object of the document. Other objects refer to each other by index in
  /// these lists, so removing or reordering items changes those references. Usually held by a
  /// TglTFDocument.</remarks>
  TglTF = class(TglTFProperty)
  private
    FExtensionsUsed: TArray<string>;
    FExtensionsRequired: TArray<string>;
    FAccessors: TglTFList<TglTFAccessor>;
    FAnimations: TglTFList<TglTFAnimation>;
    FAsset: TglTFAsset;
    FBuffers: TglTFList<TglTFBuffer>;
    FBufferViews: TglTFList<TglTFBufferView>;
    FCameras: TglTFList<TglTFCamera>;
    FImages: TglTFList<TglTFImage>;
    FMaterials: TglTFList<TglTFMaterial>;
    FMeshes: TglTFList<TglTFMesh>;
    FNodes: TglTFList<TglTFNode>;
    FSamplers: TglTFList<TglTFSampler>;
    FScene: Integer;
    FScenes: TglTFList<TglTFScene>;
    FSkins: TglTFList<TglTFSkin>;
    FTextures: TglTFList<TglTFTexture>;
  protected
    procedure ReadChildren(AJSON: TJSONObject); override;
    procedure WriteChildren(AJSON: TJSONObject); override;
    procedure Validate; override;
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** Scene is GLTF_UNDEFINED_INDEX; every list is empty and Asset is nil until loaded.
    /// <summary>Creates the object with the spec's default values.</summary>
    /// <remarks>Scene is GLTF_UNDEFINED_INDEX; every list is empty and Asset is nil until
    /// loaded.</remarks>
    constructor Create; override;

    //** @abstract(Frees the object and every object it holds.)
    /// <summary>Frees the object and every object it holds.</summary>
    destructor Destroy; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(Always "glTF"; used in error messages.)
    /// <summary>Returns the object's name in the glTF specification.</summary>
    /// <returns>Always "glTF"; used in error messages.</returns>
    class function glTFTypeName: string; override;

    //** @abstract(Tells whether an extension is listed in "extensionsUsed".)
    //**
    //** @param(AName Extension name; case-sensitive.)
    //**
    //** @returns(True when listed.)
    /// <summary>Tells whether an extension is listed in "extensionsUsed".</summary>
    /// <param name="AName">Extension name; case-sensitive.</param>
    /// <returns>True when listed.</returns>
    function IsExtensionUsed(const AName: string): Boolean;

    //** @abstract(Tells whether an extension is listed in "extensionsRequired".)
    //**
    //** @param(AName Extension name; case-sensitive.)
    //**
    //** @returns(True when listed.)
    /// <summary>Tells whether an extension is listed in "extensionsRequired".</summary>
    /// <param name="AName">Extension name; case-sensitive.</param>
    /// <returns>True when listed.</returns>
    function IsExtensionRequired(const AName: string): Boolean;

    //** @abstract(Builds the JSON for the whole asset from the current objects.)
    //**
    //** As @code(TglTFProperty.SaveToJSON), with "asset" moved to the front as is conventional.
    //**
    //** @returns(A new JSON object, owned by the caller.)
    //**
    //** @raises(EglTFError A value cannot be converted to JSON.)
    /// <summary>Builds the JSON for the whole asset from the current objects.</summary>
    /// <returns>A new JSON object, owned by the caller.</returns>
    /// <exception cref="EglTFError">A value cannot be converted to JSON.</exception>
    /// <remarks>As <c>TglTFProperty.SaveToJSON</c>, with "asset" moved to the front as is
    /// conventional.</remarks>
    function SaveToJSON: TJSONObject; override;

    //** @abstract(The glTF "extensionsUsed": names of the extensions the file uses; empty when
    //** none.)
    /// <summary>The glTF "extensionsUsed": names of the extensions the file uses; empty when
    /// none.</summary>
    [NeonProperty('extensionsUsed')]
    property ExtensionsUsed: TArray<string> read FExtensionsUsed write FExtensionsUsed;

    //** @abstract(The glTF "extensionsRequired": names of the extensions a reader must support;
    //** empty when none.)
    //**
    //** Every name must also be in @link(ExtensionsUsed).
    /// <summary>The glTF "extensionsRequired": names of the extensions a reader must support;
    /// empty when none.</summary>
    /// <remarks>Every name must also be in <see cref="ExtensionsUsed"/>.</remarks>
    [NeonProperty('extensionsRequired')]
    property ExtensionsRequired: TArray<string> read FExtensionsRequired write FExtensionsRequired;

    //** @abstract(The glTF "accessors".)
    //**
    //** Owned by this object.
    /// <summary>The glTF "accessors".</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('accessors')]
    property Accessors: TglTFList<TglTFAccessor> read FAccessors;

    //** @abstract(The glTF "animations".)
    //**
    //** Owned by this object.
    /// <summary>The glTF "animations".</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('animations')]
    property Animations: TglTFList<TglTFAnimation> read FAnimations;

    //** @abstract(The glTF "asset": file metadata; required.)
    //**
    //** Nil until loaded. Owned by this object.
    /// <summary>The glTF "asset": file metadata; required.</summary>
    /// <remarks>Nil until loaded. Owned by this object.</remarks>
    [NeonProperty('asset'), glTFRequired]
    property Asset: TglTFAsset read FAsset;

    //** @abstract(The glTF "buffers".)
    //**
    //** Owned by this object.
    /// <summary>The glTF "buffers".</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('buffers')]
    property Buffers: TglTFList<TglTFBuffer> read FBuffers;

    //** @abstract(The glTF "bufferViews".)
    //**
    //** Owned by this object.
    /// <summary>The glTF "bufferViews".</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('bufferViews')]
    property BufferViews: TglTFList<TglTFBufferView> read FBufferViews;

    //** @abstract(The glTF "cameras".)
    //**
    //** Owned by this object.
    /// <summary>The glTF "cameras".</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('cameras')]
    property Cameras: TglTFList<TglTFCamera> read FCameras;

    //** @abstract(The glTF "images".)
    //**
    //** Owned by this object.
    /// <summary>The glTF "images".</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('images')]
    property Images: TglTFList<TglTFImage> read FImages;

    //** @abstract(The glTF "materials".)
    //**
    //** Owned by this object.
    /// <summary>The glTF "materials".</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('materials')]
    property Materials: TglTFList<TglTFMaterial> read FMaterials;

    //** @abstract(The glTF "meshes".)
    //**
    //** Owned by this object.
    /// <summary>The glTF "meshes".</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('meshes')]
    property Meshes: TglTFList<TglTFMesh> read FMeshes;

    //** @abstract(The glTF "nodes".)
    //**
    //** Owned by this object.
    /// <summary>The glTF "nodes".</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('nodes')]
    property Nodes: TglTFList<TglTFNode> read FNodes;

    //** @abstract(The glTF "samplers".)
    //**
    //** Owned by this object.
    /// <summary>The glTF "samplers".</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('samplers')]
    property Samplers: TglTFList<TglTFSampler> read FSamplers;

    //** @abstract(The glTF "scene": index in @link(Scenes) of the scene to show first;
    //** GLTF_UNDEFINED_INDEX when not set.)
    /// <summary>The glTF "scene": index in <see cref="Scenes"/> of the scene to show first;
    /// GLTF_UNDEFINED_INDEX when not set.</summary>
    [NeonProperty('scene')]
    property Scene: Integer read FScene write FScene;

    //** @abstract(The glTF "scenes".)
    //**
    //** Owned by this object.
    /// <summary>The glTF "scenes".</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('scenes')]
    property Scenes: TglTFList<TglTFScene> read FScenes;

    //** @abstract(The glTF "skins".)
    //**
    //** Owned by this object.
    /// <summary>The glTF "skins".</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('skins')]
    property Skins: TglTFList<TglTFSkin> read FSkins;

    //** @abstract(The glTF "textures".)
    //**
    //** Owned by this object.
    /// <summary>The glTF "textures".</summary>
    /// <remarks>Owned by this object.</remarks>
    [NeonProperty('textures')]
    property Textures: TglTFList<TglTFTexture> read FTextures;
  end;

  {$ENDREGION}

implementation

function TryParseglTFVersion(const AValue: string; out AMajor, AMinor: Integer): Boolean;
var
  LParts: TArray<string>;
begin
  LParts := AValue.Split(['.']);
  Result := (Length(LParts) = 2) and
    TryStrToInt(LParts[0], AMajor) and TryStrToInt(LParts[1], AMinor) and
    (AMajor >= 0) and (AMinor >= 0);
end;

function StartsWithDataUri(const AUri: string): Boolean;
begin
  Result := AUri.StartsWith('data:', True);
end;

function MimeTypeOfDataUri(const AUri: string): string;
var
  LEnd: Integer;
begin
  // data:[<mime>][;base64],<data>
  Result := '';
  if not StartsWithDataUri(AUri) then
    Exit;
  Result := AUri.Substring(5);
  LEnd := Result.IndexOfAny([';', ',']);
  if LEnd >= 0 then
    Result := Result.Substring(0, LEnd);
end;

// <summary>Attribute map as a JSON object, keys sorted. The caller owns it</summary>
function AttributeMapToJSON(AMap: TglTFAttributeMap): TJSONObject;
var
  LKeys: TArray<string>;
  LKey: string;
begin
  Result := TJSONObject.Create;
  try
    LKeys := AMap.Keys.ToArray;
    TArray.Sort<string>(LKeys);
    for LKey in LKeys do
      Result.AddPair(LKey, TJSONNumber.Create(AMap[LKey]));
  except
    Result.Free;
    raise;
  end;
end;

function ArrayContainsString(const AValues: TArray<string>; const AName: string): Boolean;
var
  LValue: string;
begin
  for LValue in AValues do
    if LValue = AName then
      Exit(True);
  Result := False;
end;

{ TglTFAsset }

class function TglTFAsset.glTFTypeName: string;
begin
  Result := 'asset';
end;

procedure TglTFAsset.Validate;
var
  LMajor, LMinor: Integer;
begin
  if not TryParseglTFVersion(FVersion, LMajor, LMinor) then
    RaiseInvalid('version', Format('"%s" is not in the form <major>.<minor>', [FVersion]));
  if IsDefined('minVersion') and not TryParseglTFVersion(FMinVersion, LMajor, LMinor) then
    RaiseInvalid('minVersion', Format('"%s" is not in the form <major>.<minor>', [FMinVersion]));
end;

{ TglTFBuffer }

class function TglTFBuffer.glTFTypeName: string;
begin
  Result := 'buffer';
end;

function TglTFBuffer.IsDataUri: Boolean;
begin
  Result := StartsWithDataUri(FUri);
end;

function TglTFBuffer.DataUriMimeType: string;
begin
  Result := MimeTypeOfDataUri(FUri);
end;

procedure TglTFBuffer.Validate;
begin
  if FByteLength < 1 then
    RaiseInvalid('byteLength', 'must be >= 1');
end;

{ TglTFBufferView }

constructor TglTFBufferView.Create;
begin
  inherited;
  FBuffer := GLTF_UNDEFINED_INDEX;
end;

class function TglTFBufferView.glTFTypeName: string;
begin
  Result := 'bufferView';
end;

procedure TglTFBufferView.Validate;
begin
  if FByteLength < 1 then
    RaiseInvalid('byteLength', 'must be >= 1');
  if IsDefined('byteStride') and ((FByteStride < 4) or (FByteStride > 252)) then
    RaiseInvalid('byteStride', 'must be between 4 and 252');
end;

{ TglTFAccessorSparseIndices }

constructor TglTFAccessorSparseIndices.Create;
begin
  inherited;
  FBufferView := GLTF_UNDEFINED_INDEX;
end;

class function TglTFAccessorSparseIndices.glTFTypeName: string;
begin
  Result := 'accessor.sparse.indices';
end;

{ TglTFAccessorSparseValues }

constructor TglTFAccessorSparseValues.Create;
begin
  inherited;
  FBufferView := GLTF_UNDEFINED_INDEX;
end;

class function TglTFAccessorSparseValues.glTFTypeName: string;
begin
  Result := 'accessor.sparse.values';
end;

{ TglTFAccessorSparse }

destructor TglTFAccessorSparse.Destroy;
begin
  FIndices.Free;
  FValues.Free;
  inherited;
end;

class function TglTFAccessorSparse.glTFTypeName: string;
begin
  Result := 'accessor.sparse';
end;

procedure TglTFAccessorSparse.ReadChildren(AJSON: TJSONObject);
begin
  FreeAndNil(FIndices);
  FreeAndNil(FValues);
  FIndices := ReadObject(AJSON, 'indices', TglTFAccessorSparseIndices) as TglTFAccessorSparseIndices;
  FValues := ReadObject(AJSON, 'values', TglTFAccessorSparseValues) as TglTFAccessorSparseValues;
end;

procedure TglTFAccessorSparse.WriteChildren(AJSON: TJSONObject);
begin
  WriteObject(AJSON, 'indices', FIndices);
  WriteObject(AJSON, 'values', FValues);
end;

procedure TglTFAccessorSparse.Validate;
begin
  if FCount < 1 then
    RaiseInvalid('count', 'must be >= 1');
end;

{ TglTFAccessor }

constructor TglTFAccessor.Create;
begin
  inherited;
  FBufferView := GLTF_UNDEFINED_INDEX;
end;

destructor TglTFAccessor.Destroy;
begin
  FSparse.Free;
  inherited;
end;

class function TglTFAccessor.glTFTypeName: string;
begin
  Result := 'accessor';
end;

procedure TglTFAccessor.ReadChildren(AJSON: TJSONObject);
begin
  FreeAndNil(FSparse);
  FSparse := ReadObject(AJSON, 'sparse', TglTFAccessorSparse) as TglTFAccessorSparse;
end;

procedure TglTFAccessor.WriteChildren(AJSON: TJSONObject);
begin
  WriteObject(AJSON, 'sparse', FSparse);
end;

procedure TglTFAccessor.Validate;
var
  LCount: Integer;
begin
  if FCount < 1 then
    RaiseInvalid('count', 'must be >= 1');

  LCount := ComponentCount;
  if LCount > 0 then
  begin
    if IsDefined('min') and (Length(FMin) <> LCount) then
      RaiseInvalid('min', Format('must contain %d values for type %s', [LCount, FType]));
    if IsDefined('max') and (Length(FMax) <> LCount) then
      RaiseInvalid('max', Format('must contain %d values for type %s', [LCount, FType]));
  end;
end;

function TglTFAccessor.GetAccessorType: TglTFAccessorType;
begin
  if FType = 'SCALAR' then Result := atScalar
  else if FType = 'VEC2' then Result := atVec2
  else if FType = 'VEC3' then Result := atVec3
  else if FType = 'VEC4' then Result := atVec4
  else if FType = 'MAT2' then Result := atMat2
  else if FType = 'MAT3' then Result := atMat3
  else if FType = 'MAT4' then Result := atMat4
  else Result := atUnknown;
end;

function TglTFAccessor.ComponentCount: Integer;
begin
  case GetAccessorType of
    atScalar: Result := 1;
    atVec2: Result := 2;
    atVec3: Result := 3;
    atVec4, atMat2: Result := 4;
    atMat3: Result := 9;
    atMat4: Result := 16;
  else
    Result := 0;
  end;
end;

function TglTFAccessor.ComponentByteSize: Integer;
begin
  case FComponentType of
    GLTF_COMPONENT_BYTE, GLTF_COMPONENT_UNSIGNED_BYTE: Result := 1;
    GLTF_COMPONENT_SHORT, GLTF_COMPONENT_UNSIGNED_SHORT: Result := 2;
    GLTF_COMPONENT_UNSIGNED_INT, GLTF_COMPONENT_FLOAT: Result := 4;
  else
    Result := 0;
  end;
end;

{ TglTFAnimationChannelTarget }

constructor TglTFAnimationChannelTarget.Create;
begin
  inherited;
  FNode := GLTF_UNDEFINED_INDEX;
end;

class function TglTFAnimationChannelTarget.glTFTypeName: string;
begin
  Result := 'animation.channel.target';
end;

function TglTFAnimationChannelTarget.GetAnimationPath: TglTFAnimationPath;
begin
  if FPath = 'translation' then Result := apTranslation
  else if FPath = 'rotation' then Result := apRotation
  else if FPath = 'scale' then Result := apScale
  else if FPath = 'weights' then Result := apWeights
  else Result := apUnknown;
end;

{ TglTFAnimationChannel }

destructor TglTFAnimationChannel.Destroy;
begin
  FTarget.Free;
  inherited;
end;

class function TglTFAnimationChannel.glTFTypeName: string;
begin
  Result := 'animation.channel';
end;

procedure TglTFAnimationChannel.ReadChildren(AJSON: TJSONObject);
begin
  FreeAndNil(FTarget);
  FTarget := ReadObject(AJSON, 'target', TglTFAnimationChannelTarget) as TglTFAnimationChannelTarget;
end;

procedure TglTFAnimationChannel.WriteChildren(AJSON: TJSONObject);
begin
  WriteObject(AJSON, 'target', FTarget);
end;

{ TglTFAnimationSampler }

constructor TglTFAnimationSampler.Create;
begin
  inherited;
  FInterpolation := 'LINEAR';
end;

class function TglTFAnimationSampler.glTFTypeName: string;
begin
  Result := 'animation.sampler';
end;

function TglTFAnimationSampler.GetInterpolationKind: TglTFInterpolation;
begin
  if FInterpolation = 'LINEAR' then Result := ipLinear
  else if FInterpolation = 'STEP' then Result := ipStep
  else if FInterpolation = 'CUBICSPLINE' then Result := ipCubicSpline
  else Result := ipUnknown;
end;

{ TglTFAnimation }

constructor TglTFAnimation.Create;
begin
  inherited;
  FChannels := TglTFList<TglTFAnimationChannel>.Create;
  FSamplers := TglTFList<TglTFAnimationSampler>.Create;
  FExportOnSave := True;
end;

destructor TglTFAnimation.Destroy;
begin
  FSamplers.Free;
  FChannels.Free;
  inherited;
end;

class function TglTFAnimation.glTFTypeName: string;
begin
  Result := 'animation';
end;

procedure TglTFAnimation.ReadChildren(AJSON: TJSONObject);
begin
  FChannels.LoadFromJSON(AJSON.GetValue('channels'), ChildPath('channels'));
  FSamplers.LoadFromJSON(AJSON.GetValue('samplers'), ChildPath('samplers'));
end;

procedure TglTFAnimation.WriteChildren(AJSON: TJSONObject);
begin
  FChannels.WriteTo(AJSON, 'channels', True);
  FSamplers.WriteTo(AJSON, 'samplers', True);
end;

procedure TglTFAnimation.Validate;
begin
  if FChannels.Count = 0 then
    RaiseInvalid('channels', 'must contain at least one channel');
  if FSamplers.Count = 0 then
    RaiseInvalid('samplers', 'must contain at least one sampler');
end;

{ TglTFCameraOrthographic }

class function TglTFCameraOrthographic.glTFTypeName: string;
begin
  Result := 'camera.orthographic';
end;

{ TglTFCameraPerspective }

class function TglTFCameraPerspective.glTFTypeName: string;
begin
  Result := 'camera.perspective';
end;

{ TglTFCamera }

destructor TglTFCamera.Destroy;
begin
  FOrthographic.Free;
  FPerspective.Free;
  inherited;
end;

class function TglTFCamera.glTFTypeName: string;
begin
  Result := 'camera';
end;

function TglTFCamera.GetCameraType: TglTFCameraType;
begin
  if FType = 'perspective' then Result := ctPerspective
  else if FType = 'orthographic' then Result := ctOrthographic
  else Result := ctUnknown;
end;

procedure TglTFCamera.ReadChildren(AJSON: TJSONObject);
begin
  FreeAndNil(FOrthographic);
  FreeAndNil(FPerspective);
  FOrthographic := ReadObject(AJSON, 'orthographic', TglTFCameraOrthographic) as TglTFCameraOrthographic;
  FPerspective := ReadObject(AJSON, 'perspective', TglTFCameraPerspective) as TglTFCameraPerspective;
end;

procedure TglTFCamera.WriteChildren(AJSON: TJSONObject);
begin
  WriteObject(AJSON, 'orthographic', FOrthographic);
  WriteObject(AJSON, 'perspective', FPerspective);
end;

procedure TglTFCamera.Validate;
begin
  // The object matching camera.type is required
  case GetCameraType of
    ctPerspective:
      if FPerspective = nil then
        RaiseMissing('perspective');
    ctOrthographic:
      if FOrthographic = nil then
        RaiseMissing('orthographic');
  end;
end;

{ TglTFImage }

constructor TglTFImage.Create;
begin
  inherited;
  FBufferView := GLTF_UNDEFINED_INDEX;
end;

class function TglTFImage.glTFTypeName: string;
begin
  Result := 'image';
end;

function TglTFImage.IsDataUri: Boolean;
begin
  Result := StartsWithDataUri(FUri);
end;

function TglTFImage.EffectiveMimeType: string;
var
  LExt: string;
begin
  if FMimeType <> '' then
    Exit(FMimeType);

  if IsDataUri then
  begin
    Result := MimeTypeOfDataUri(FUri);
    if Result <> '' then
      Exit;
  end
  else if FUri <> '' then
  begin
    LExt := LowerCase(ExtractFileExt(FUri));
    if LExt = '.png' then Exit('image/png');
    if (LExt = '.jpg') or (LExt = '.jpeg') then Exit('image/jpeg');
    if LExt = '.webp' then Exit('image/webp');
    if LExt = '.ktx2' then Exit('image/ktx2');
  end;

  // Image signatures
  if (Length(FData) >= 4) and (FData[0] = $89) and (FData[1] = $50) and
     (FData[2] = $4E) and (FData[3] = $47) then
    Exit('image/png');
  if (Length(FData) >= 3) and (FData[0] = $FF) and (FData[1] = $D8) and (FData[2] = $FF) then
    Exit('image/jpeg');
  if (Length(FData) >= 12) and (FData[0] = Ord('R')) and (FData[1] = Ord('I')) and
     (FData[8] = Ord('W')) and (FData[9] = Ord('E')) then
    Exit('image/webp');
  Result := '';
end;

procedure TglTFImage.Validate;
begin
  // Exactly one of uri / bufferView; bufferView needs mimeType
  if not IsDefined('uri') and not IsDefined('bufferView') then
    RaiseMissing('uri" or "bufferView');
  if IsDefined('uri') and IsDefined('bufferView') then
    RaiseInvalid('bufferView', 'uri and bufferView must not both be defined');
  if IsDefined('bufferView') and not IsDefined('mimeType') then
    RaiseMissing('mimeType');
end;

{ TglTFSampler }

constructor TglTFSampler.Create;
begin
  inherited;
  FWrapS := GLTF_WRAP_REPEAT;
  FWrapT := GLTF_WRAP_REPEAT;
end;

class function TglTFSampler.glTFTypeName: string;
begin
  Result := 'sampler';
end;

{ TglTFTexture }

constructor TglTFTexture.Create;
begin
  inherited;
  FSampler := GLTF_UNDEFINED_INDEX;
  FSource := GLTF_UNDEFINED_INDEX;
end;

class function TglTFTexture.glTFTypeName: string;
begin
  Result := 'texture';
end;

{ TglTFTextureInfo }

class function TglTFTextureInfo.glTFTypeName: string;
begin
  Result := 'textureInfo';
end;

{ TglTFNormalTextureInfo }

constructor TglTFNormalTextureInfo.Create;
begin
  inherited;
  FScale := 1.0;
end;

class function TglTFNormalTextureInfo.glTFTypeName: string;
begin
  Result := 'material.normalTextureInfo';
end;

{ TglTFOcclusionTextureInfo }

constructor TglTFOcclusionTextureInfo.Create;
begin
  inherited;
  FStrength := 1.0;
end;

class function TglTFOcclusionTextureInfo.glTFTypeName: string;
begin
  Result := 'material.occlusionTextureInfo';
end;

{ TglTFPbrMetallicRoughness }

constructor TglTFPbrMetallicRoughness.Create;
begin
  inherited;
  FBaseColorFactor := [1.0, 1.0, 1.0, 1.0];
  FMetallicFactor := 1.0;
  FRoughnessFactor := 1.0;
end;

destructor TglTFPbrMetallicRoughness.Destroy;
begin
  FBaseColorTexture.Free;
  FMetallicRoughnessTexture.Free;
  inherited;
end;

class function TglTFPbrMetallicRoughness.glTFTypeName: string;
begin
  Result := 'material.pbrMetallicRoughness';
end;

procedure TglTFPbrMetallicRoughness.ReadChildren(AJSON: TJSONObject);
begin
  FreeAndNil(FBaseColorTexture);
  FreeAndNil(FMetallicRoughnessTexture);
  FBaseColorTexture := ReadObject(AJSON, 'baseColorTexture', TglTFTextureInfo) as TglTFTextureInfo;
  FMetallicRoughnessTexture := ReadObject(AJSON, 'metallicRoughnessTexture', TglTFTextureInfo) as TglTFTextureInfo;
end;

procedure TglTFPbrMetallicRoughness.WriteChildren(AJSON: TJSONObject);
begin
  WriteObject(AJSON, 'baseColorTexture', FBaseColorTexture);
  WriteObject(AJSON, 'metallicRoughnessTexture', FMetallicRoughnessTexture);
end;

procedure TglTFPbrMetallicRoughness.Validate;
begin
  if Length(FBaseColorFactor) <> 4 then
    RaiseInvalid('baseColorFactor', 'must contain 4 numbers');
end;

{ TglTFMaterial }

constructor TglTFMaterial.Create;
begin
  inherited;
  FEmissiveFactor := [0.0, 0.0, 0.0];
  FAlphaMode := 'OPAQUE';
  FAlphaCutoff := 0.5;
  FDoubleSided := False;
end;

destructor TglTFMaterial.Destroy;
begin
  FPbrMetallicRoughness.Free;
  FNormalTexture.Free;
  FOcclusionTexture.Free;
  FEmissiveTexture.Free;
  inherited;
end;

class function TglTFMaterial.glTFTypeName: string;
begin
  Result := 'material';
end;

function TglTFMaterial.GetAlphaModeKind: TglTFAlphaMode;
begin
  if FAlphaMode = 'OPAQUE' then Result := amOpaque
  else if FAlphaMode = 'MASK' then Result := amMask
  else if FAlphaMode = 'BLEND' then Result := amBlend
  else Result := amUnknown;
end;

procedure TglTFMaterial.ReadChildren(AJSON: TJSONObject);
begin
  FreeAndNil(FPbrMetallicRoughness);
  FreeAndNil(FNormalTexture);
  FreeAndNil(FOcclusionTexture);
  FreeAndNil(FEmissiveTexture);
  FPbrMetallicRoughness := ReadObject(AJSON, 'pbrMetallicRoughness', TglTFPbrMetallicRoughness) as TglTFPbrMetallicRoughness;
  FNormalTexture := ReadObject(AJSON, 'normalTexture', TglTFNormalTextureInfo) as TglTFNormalTextureInfo;
  FOcclusionTexture := ReadObject(AJSON, 'occlusionTexture', TglTFOcclusionTextureInfo) as TglTFOcclusionTextureInfo;
  FEmissiveTexture := ReadObject(AJSON, 'emissiveTexture', TglTFTextureInfo) as TglTFTextureInfo;
end;

procedure TglTFMaterial.WriteChildren(AJSON: TJSONObject);
begin
  WriteObject(AJSON, 'pbrMetallicRoughness', FPbrMetallicRoughness);
  WriteObject(AJSON, 'normalTexture', FNormalTexture);
  WriteObject(AJSON, 'occlusionTexture', FOcclusionTexture);
  WriteObject(AJSON, 'emissiveTexture', FEmissiveTexture);
end;

procedure TglTFMaterial.Validate;
begin
  if Length(FEmissiveFactor) <> 3 then
    RaiseInvalid('emissiveFactor', 'must contain 3 numbers');
end;

{ TglTFMeshPrimitive }

constructor TglTFMeshPrimitive.Create;
begin
  inherited;
  FAttributes := TglTFAttributeMap.Create;
  FTargets := TObjectList<TglTFAttributeMap>.Create(True);
  FIndices := GLTF_UNDEFINED_INDEX;
  FMaterial := GLTF_UNDEFINED_INDEX;
  FMode := GLTF_MODE_TRIANGLES;
end;

destructor TglTFMeshPrimitive.Destroy;
begin
  FTargets.Free;
  FAttributes.Free;
  inherited;
end;

class function TglTFMeshPrimitive.glTFTypeName: string;
begin
  Result := 'mesh.primitive';
end;

procedure TglTFMeshPrimitive.ReadAttributeMap(AJSON: TJSONValue; const APath: string;
  AMap: TglTFAttributeMap);
var
  LObject: TJSONObject;
  LPair: TJSONPair;
  I: Integer;
begin
  if not (AJSON is TJSONObject) then
    raise EglTFParseError.Create(APath, 'Expected a JSON object mapping attribute names to accessor indices');

  LObject := TJSONObject(AJSON);
  for I := 0 to LObject.Count - 1 do
  begin
    LPair := LObject.Pairs[I];
    if not (LPair.JsonValue is TJSONNumber) then
      raise EglTFParseError.Create(APath + '.' + LPair.JsonString.Value,
        'Attribute value must be an accessor index');
    AMap.AddOrSetValue(LPair.JsonString.Value, TJSONNumber(LPair.JsonValue).AsInt);
  end;
end;

procedure TglTFMeshPrimitive.ReadChildren(AJSON: TJSONObject);
var
  LTargets: TJSONValue;
  LMap: TglTFAttributeMap;
  I: Integer;
begin
  FAttributes.Clear;
  FTargets.Clear;

  ReadAttributeMap(AJSON.GetValue('attributes'), ChildPath('attributes'), FAttributes);

  LTargets := AJSON.GetValue('targets');
  if (LTargets = nil) or (LTargets is TJSONNull) then
    Exit;
  if not (LTargets is TJSONArray) then
    RaiseInvalid('targets', 'must be a JSON array');

  for I := 0 to TJSONArray(LTargets).Count - 1 do
  begin
    LMap := TglTFAttributeMap.Create;
    try
      ReadAttributeMap(TJSONArray(LTargets).Items[I],
        Format('%s[%d]', [ChildPath('targets'), I]), LMap);
    except
      LMap.Free;
      raise;
    end;
    FTargets.Add(LMap);
  end;
end;

procedure TglTFMeshPrimitive.WriteChildren(AJSON: TJSONObject);
var
  LTargets: TJSONArray;
  LTarget: TglTFAttributeMap;
begin
  AJSON.AddPair('attributes', AttributeMapToJSON(FAttributes));

  if FTargets.Count = 0 then
    Exit;

  LTargets := TJSONArray.Create;
  try
    for LTarget in FTargets do
      LTargets.AddElement(AttributeMapToJSON(LTarget));
  except
    LTargets.Free;
    raise;
  end;
  AJSON.AddPair('targets', LTargets);
end;

procedure TglTFMeshPrimitive.Validate;
begin
  if FAttributes.Count = 0 then
    RaiseInvalid('attributes', 'must contain at least one attribute');
end;

function TglTFMeshPrimitive.HasAttribute(const ASemantic: string): Boolean;
begin
  Result := FAttributes.ContainsKey(ASemantic);
end;

function TglTFMeshPrimitive.GetAttribute(const ASemantic: string): Integer;
begin
  if not FAttributes.TryGetValue(ASemantic, Result) then
    Result := GLTF_UNDEFINED_INDEX;
end;

{ TglTFMesh }

constructor TglTFMesh.Create;
begin
  inherited;
  FPrimitives := TglTFList<TglTFMeshPrimitive>.Create;
end;

destructor TglTFMesh.Destroy;
begin
  FPrimitives.Free;
  inherited;
end;

class function TglTFMesh.glTFTypeName: string;
begin
  Result := 'mesh';
end;

procedure TglTFMesh.ReadChildren(AJSON: TJSONObject);
begin
  FPrimitives.LoadFromJSON(AJSON.GetValue('primitives'), ChildPath('primitives'));
end;

procedure TglTFMesh.WriteChildren(AJSON: TJSONObject);
begin
  FPrimitives.WriteTo(AJSON, 'primitives', True);
end;

procedure TglTFMesh.Validate;
begin
  if FPrimitives.Count = 0 then
    RaiseInvalid('primitives', 'must contain at least one primitive');
end;

{ TglTFNode }

constructor TglTFNode.Create;
begin
  inherited;
  FCamera := GLTF_UNDEFINED_INDEX;
  FSkin := GLTF_UNDEFINED_INDEX;
  FMesh := GLTF_UNDEFINED_INDEX;
  FMatrix := [1.0, 0.0, 0.0, 0.0,
              0.0, 1.0, 0.0, 0.0,
              0.0, 0.0, 1.0, 0.0,
              0.0, 0.0, 0.0, 1.0];
  FRotation := [0.0, 0.0, 0.0, 1.0];
  FScale := [1.0, 1.0, 1.0];
  FTranslation := [0.0, 0.0, 0.0];
end;

class function TglTFNode.glTFTypeName: string;
begin
  Result := 'node';
end;

function TglTFNode.HasMatrix: Boolean;
begin
  Result := IsDefined('matrix');
end;

procedure TglTFNode.Validate;
begin
  if Length(FMatrix) <> 16 then
    RaiseInvalid('matrix', 'must contain 16 numbers');
  if Length(FRotation) <> 4 then
    RaiseInvalid('rotation', 'must contain 4 numbers');
  if Length(FScale) <> 3 then
    RaiseInvalid('scale', 'must contain 3 numbers');
  if Length(FTranslation) <> 3 then
    RaiseInvalid('translation', 'must contain 3 numbers');
end;

{ TglTFScene }

class function TglTFScene.glTFTypeName: string;
begin
  Result := 'scene';
end;

{ TglTFSkin }

constructor TglTFSkin.Create;
begin
  inherited;
  FInverseBindMatrices := GLTF_UNDEFINED_INDEX;
  FSkeleton := GLTF_UNDEFINED_INDEX;
end;

class function TglTFSkin.glTFTypeName: string;
begin
  Result := 'skin';
end;

procedure TglTFSkin.Validate;
begin
  if Length(FJoints) = 0 then
    RaiseInvalid('joints', 'must contain at least one joint');
end;

{ TglTF }

constructor TglTF.Create;
begin
  inherited;
  FScene := GLTF_UNDEFINED_INDEX;
  FAccessors := TglTFList<TglTFAccessor>.Create;
  FAnimations := TglTFList<TglTFAnimation>.Create;
  FBuffers := TglTFList<TglTFBuffer>.Create;
  FBufferViews := TglTFList<TglTFBufferView>.Create;
  FCameras := TglTFList<TglTFCamera>.Create;
  FImages := TglTFList<TglTFImage>.Create;
  FMaterials := TglTFList<TglTFMaterial>.Create;
  FMeshes := TglTFList<TglTFMesh>.Create;
  FNodes := TglTFList<TglTFNode>.Create;
  FSamplers := TglTFList<TglTFSampler>.Create;
  FScenes := TglTFList<TglTFScene>.Create;
  FSkins := TglTFList<TglTFSkin>.Create;
  FTextures := TglTFList<TglTFTexture>.Create;
end;

destructor TglTF.Destroy;
begin
  FTextures.Free;
  FSkins.Free;
  FScenes.Free;
  FSamplers.Free;
  FNodes.Free;
  FMeshes.Free;
  FMaterials.Free;
  FImages.Free;
  FCameras.Free;
  FBufferViews.Free;
  FBuffers.Free;
  FAnimations.Free;
  FAccessors.Free;
  FAsset.Free;
  inherited;
end;

class function TglTF.glTFTypeName: string;
begin
  Result := 'glTF';
end;

procedure TglTF.ReadChildren(AJSON: TJSONObject);
begin
  FreeAndNil(FAsset);
  FAsset := ReadObject(AJSON, 'asset', TglTFAsset) as TglTFAsset;

  FAccessors.LoadFromJSON(AJSON.GetValue('accessors'), ChildPath('accessors'));
  FAnimations.LoadFromJSON(AJSON.GetValue('animations'), ChildPath('animations'));
  FBuffers.LoadFromJSON(AJSON.GetValue('buffers'), ChildPath('buffers'));
  FBufferViews.LoadFromJSON(AJSON.GetValue('bufferViews'), ChildPath('bufferViews'));
  FCameras.LoadFromJSON(AJSON.GetValue('cameras'), ChildPath('cameras'));
  FImages.LoadFromJSON(AJSON.GetValue('images'), ChildPath('images'));
  FMaterials.LoadFromJSON(AJSON.GetValue('materials'), ChildPath('materials'));
  FMeshes.LoadFromJSON(AJSON.GetValue('meshes'), ChildPath('meshes'));
  FNodes.LoadFromJSON(AJSON.GetValue('nodes'), ChildPath('nodes'));
  FSamplers.LoadFromJSON(AJSON.GetValue('samplers'), ChildPath('samplers'));
  FScenes.LoadFromJSON(AJSON.GetValue('scenes'), ChildPath('scenes'));
  FSkins.LoadFromJSON(AJSON.GetValue('skins'), ChildPath('skins'));
  FTextures.LoadFromJSON(AJSON.GetValue('textures'), ChildPath('textures'));
end;

procedure TglTF.WriteChildren(AJSON: TJSONObject);
begin
  WriteObject(AJSON, 'asset', FAsset);
  FAccessors.WriteTo(AJSON, 'accessors');
  FAnimations.WriteTo(AJSON, 'animations');
  FBuffers.WriteTo(AJSON, 'buffers');
  FBufferViews.WriteTo(AJSON, 'bufferViews');
  FCameras.WriteTo(AJSON, 'cameras');
  FImages.WriteTo(AJSON, 'images');
  FMaterials.WriteTo(AJSON, 'materials');
  FMeshes.WriteTo(AJSON, 'meshes');
  FNodes.WriteTo(AJSON, 'nodes');
  FSamplers.WriteTo(AJSON, 'samplers');
  FScenes.WriteTo(AJSON, 'scenes');
  FSkins.WriteTo(AJSON, 'skins');
  FTextures.WriteTo(AJSON, 'textures');
end;

function TglTF.SaveToJSON: TJSONObject;
var
  LBuilt: TJSONObject;
  LAsset: TJSONPair;
begin
  LBuilt := inherited SaveToJSON;
  LAsset := LBuilt.RemovePair('asset');
  if LAsset = nil then
    Exit(LBuilt);

  // Conventionally "asset" comes first
  Result := TJSONObject.Create;
  Result.AddPair(LAsset);
  while LBuilt.Count > 0 do
    Result.AddPair(LBuilt.RemovePair(LBuilt.Pairs[0].JsonString.Value));
  LBuilt.Free;
end;

procedure TglTF.Validate;
var
  LMajor, LMinor: Integer;
  LName: string;
begin
  // asset.version has been format-checked by TglTFAsset.Validate
  TryParseglTFVersion(FAsset.Version, LMajor, LMinor);
  if LMajor <> 2 then
    raise EglTFParseError.Create(ChildPath('asset.version'),
      Format('Unsupported glTF version "%s" (only 2.x is supported)', [FAsset.Version]));

  if FAsset.IsDefined('minVersion') then
  begin
    TryParseglTFVersion(FAsset.MinVersion, LMajor, LMinor);
    if (LMajor > 2) or ((LMajor = 2) and (LMinor > 0)) then
      raise EglTFParseError.Create(ChildPath('asset.minVersion'),
        Format('glTF asset requires minVersion %s (only 2.0 is supported)', [FAsset.MinVersion]));
  end;

  for LName in FExtensionsRequired do
    if not ArrayContainsString(FExtensionsUsed, LName) then
      RaiseInvalid('extensionsRequired',
        Format('"%s" must also be listed in extensionsUsed', [LName]));
end;

function TglTF.IsExtensionUsed(const AName: string): Boolean;
begin
  Result := ArrayContainsString(FExtensionsUsed, AName);
end;

function TglTF.IsExtensionRequired(const AName: string): Boolean;
begin
  Result := ArrayContainsString(FExtensionsRequired, AName);
end;

end.
