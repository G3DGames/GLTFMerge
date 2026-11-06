//** @abstract(Base classes and exceptions of the glTF 2.0 reader and writer.)
//**
//** @link(TglTFProperty) is the abstract base of every glTF object: it loads an object from
//** JSON, checks the properties the schema requires, keeps extensions, extras and
//** non-standard properties so they can be queried, and writes the object back to JSON.
//** @link(TglTFList) holds the arrays of glTF objects. Errors are reported with
//** @link(EglTFError) and its descendants, which carry the JSON path and, when the text is
//** known, the line of the problem.
//**
//** JSON values are read and written with the Neon library
//** @(https://github.com/paolo-rossi/delphi-neon@). The unit has no VCL or FMX
//** dependencies, so it works on every target. Specification:
//** https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html
//**
//** @preformatted(
//** EglTFError
//** |-- EglTFParseError             malformed JSON or an invalid value
//** `-- EglTFMissingPropertyError   a required property is missing
//**
//** TglTFProperty @(abstract@)          load, validate, save; extensions and extras
//** `-- TglTFChildOfRootProperty @(abstract@)   adds "name"
//** )
unit glTF.Base;

{
  Base classes and exceptions of the glTF 2.0 reader and writer.

  TglTFProperty is the abstract base of every glTF object: it loads an object
  from JSON, checks the properties the schema requires, keeps extensions,
  extras and non-standard properties so they can be queried, and writes the
  object back to JSON. TglTFList holds the arrays of glTF objects. Errors are
  reported with EglTFError and its descendants, which carry the JSON path and,
  when the text is known, the line of the problem.

  JSON values are read and written with the Neon library
  (https://github.com/paolo-rossi/delphi-neon). The unit has no VCL or FMX
  dependencies, so it works on every target. Specification:
  https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html

    EglTFError
    |-- EglTFParseError             malformed JSON or an invalid value
    `-- EglTFMissingPropertyError   a required property is missing

    TglTFProperty (abstract)          load, validate, save; extensions and extras
    `-- TglTFChildOfRootProperty (abstract)   adds "name"
}

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.TypInfo, System.JSON,
  System.Generics.Collections,

  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON;

type
  {$REGION 'Exceptions'}

  //** @abstract(Base class of every exception raised by the glTF reader and writer.)
  //**
  //** Carries where the problem is: @link(JSONPath) always when known, and the line and
  //** column in the source text when the document was loaded from text. The location is
  //** appended to the message by @link(SetSourceLocation).
  EglTFError = class(Exception)
  private
    FJSONPath: string;
    FSourceName: string;
    FLine: Integer;
    FColumn: Integer;
    FEndLine: Integer;
    function GetHasSourceLocation: Boolean;
  public
    //** @abstract(Records where the error is in the source text and appends it to the
    //** message.)
    //**
    //** The message gets for example " [model.gltf, line 74, column 13]", or
    //** " [lines 72-79]" when AEndLine is after ALine. Only the first call has an effect;
    //** a line of 0 or less is ignored. Called by TglTFDocument while loading.
    //**
    //** @param(ASourceName File name to show; empty when not loaded from a file.)
    //**
    //** @param(ALine 1-based line of the start of the problem.)
    //**
    //** @param(AColumn 1-based column of the start of the problem.)
    //**
    //** @param(AEndLine Last line of the offending value, to report a range; 0 for a
    //** single position.)
    procedure SetSourceLocation(const ASourceName: string; ALine, AColumn: Integer;
      AEndLine: Integer = 0);

    //** @abstract(Location of the problem in the document, for example
    //** "meshes[0].primitives[2]".)
    //**
    //** Empty for the root object or when unknown.
    property JSONPath: string read FJSONPath;

    //** @abstract(Name of the loaded file, with ", JSON chunk" for a GLB; empty otherwise.)
    property SourceName: string read FSourceName;

    //** @abstract(1-based line of the problem in the glTF text; 0 when unknown.)
    property Line: Integer read FLine;

    //** @abstract(1-based column of the problem in the glTF text; 0 when unknown.)
    property Column: Integer read FColumn;

    //** @abstract(Last line of the offending value; equal to @link(Line) for one-line
    //** values.)
    property EndLine: Integer read FEndLine;

    //** @abstract(True when @link(Line) and @link(Column) are known.)
    property HasSourceLocation: Boolean read GetHasSourceLocation;
  end;

  //** @abstract(Raised when the JSON is malformed or a value has the wrong type or shape.)
  EglTFParseError = class(EglTFError)
  public
    //** @abstract(Creates the exception for a location in the document.)
    //**
    //** The message becomes AMessage followed by the path, for example
    //** 'Invalid value (at "accessors[1].count")'.
    //**
    //** @param(AJSONPath Location of the problem; empty for the root.)
    //**
    //** @param(AMessage What is wrong.)
    constructor Create(const AJSONPath, AMessage: string);
  end;

  //** @abstract(Raised when a property the glTF 2.0 schema requires is not present.)
  //**
  //** @link(EglTFError.JSONPath) and the line point at the object that should contain the
  //** property.
  EglTFMissingPropertyError = class(EglTFError)
  private
    FObjectType: string;
    FPropertyName: string;
  public
    //** @abstract(Creates the exception for a missing property.)
    //**
    //** @param(AObjectType glTF object type, for example "accessor".)
    //**
    //** @param(APropertyName JSON name of the missing property, for example
    //** "componentType".)
    //**
    //** @param(AJSONPath Location of the object that is missing it.)
    constructor Create(const AObjectType, APropertyName, AJSONPath: string);

    //** @abstract(glTF object type, for example "accessor".)
    property ObjectType: string read FObjectType;

    //** @abstract(JSON name of the missing property, for example "componentType".)
    property PropertyName: string read FPropertyName;
  end;

  {$ENDREGION}

  //** @abstract(Marks a property as required by the glTF 2.0 schema.)
  //**
  //** Use together with @code([NeonProperty@('jsonName'@)]), which gives the JSON name that
  //** is checked. Loading an object without that property raises
  //** @link(EglTFMissingPropertyError); saving always writes it.
  glTFRequiredAttribute = class(TCustomAttribute);

  TglTFProperty = class;

  //** @abstract(Class reference to a glTF object class, used to create nested objects.)
  TglTFPropertyClass = class of TglTFProperty;

  //** @abstract(Describes one simple-value property that is read from and written to JSON.)
  //**
  //** Collected once per class through RTTI; used when saving and when reporting an
  //** invalid value.
  TglTFMemberInfo = record
    //** @abstract(The property's name in the glTF JSON, from @code([NeonProperty]).)
    JSONName: string;

    //** @abstract(The Delphi property name.)
    PropertyName: string;

    //** @abstract(The property's type.)
    TypeInfo: PTypeInfo;

    //** @abstract(True when the property has @code([glTFRequired]).)
    Required: Boolean;
  end;

  //** @abstract(Metadata of one glTF object class, collected once through RTTI.)
  //**
  //** Created and owned by @link(TglTFProperty), one per class, and kept until the
  //** program ends. Not meant to be used directly.
  TglTFTypeInfo = class
  private
    FKnown: TDictionary<string, Boolean>;
    FRequired: TList<string>;
    // Writable [NeonProperty] properties, in declaration order
    FWritable: TList<TglTFMemberInfo>;
    // A freshly constructed instance: its values are the spec defaults
    // that are left out when saving
    FDefaults: TObject;
    // Parallel to FWritable: the property, and its value in FDefaults
    FProps: TList<TRttiProperty>;
    FDefaultValues: TList<TValue>;
  public
    //** @abstract(Creates empty metadata.)
    constructor Create;

    //** @abstract(Frees the metadata and its default instance.)
    destructor Destroy; override;
  end;

  //** @abstract(Abstract base of every glTF object, glTFProperty in the schema.)
  //**
  //** @link(LoadFromJSON) runs these steps: (1) the properties marked @code([glTFRequired]) are
  //** checked; (2) simple values @(numbers, strings, booleans, arrays@) are read into the
  //** writable properties marked @code([NeonProperty]), directly through RTTI cached per class,
  //** as this is done for every object of a file; (3) "extensions", "extras" and any property
  //** not in the schema are kept as JSON so they can be queried; (4) @link(ReadChildren) loads
  //** nested glTF objects; (5) @link(Validate) applies rules an attribute cannot express.
  //**
  //** @link(SaveToJSON) does the reverse from the current property values. Objects are
  //** not thread-safe; the per-class metadata is shared and guarded by a monitor.
  //**
  //** To add an object type: derive from this class, declare its values as properties
  //** with @code([NeonProperty]) and, where required, @code([glTFRequired]); override
  //** @link(ReadChildren) and @link(WriteChildren) for nested objects, @link(Validate) for
  //** other rules and @link(glTFTypeName) for messages.
  TglTFProperty = class abstract
  private
    class var FTypeInfos: TObjectDictionary<TClass, TglTFTypeInfo>;
    class var FNeonConfig: INeonConfiguration;
    class var FExtrasNeonConfig: INeonConfiguration;
    // Kept for the program's life, so the cached TRttiProperty objects stay valid
    class var FRtti: TRttiContext;
    class constructor ClassCreate;
    class destructor ClassDestroy;
    class function GetglTFTypeInfo(AClass: TClass): TglTFTypeInfo; static;
  private
    FJSONPath: string;
    FDefinedProperties: TArray<string>;
    FExtensions: TJSONObject;
    FExtras: TJSONValue;
    FUnknownProperties: TJSONObject;
    procedure ClearCapturedJSON;
    procedure CheckRequired(AJSON: TJSONObject);
    procedure ReadValues(AJSON: TJSONObject);
    procedure WriteValues(AJSON: TJSONObject);
    procedure WriteCapturedJSON(AJSON: TJSONObject);
    procedure CaptureExtraJSON(AJSON: TJSONObject);
  protected
    //** @abstract(Returns the JSON path of a direct child of this object.)
    //**
    //** @param(AName JSON name of the child property.)
    //**
    //** @returns(For example "meshes[0].primitives" for AName "primitives" on meshes[0].)
    function ChildPath(const AName: string): string;

    //** @abstract(Creates and loads a nested glTF object from a property of AJSON.)
    //**
    //** Whether the property is required is checked earlier through
    //** @code([glTFRequired]), so an absent property is not an error here.
    //**
    //** @param(AJSON This object's JSON.)
    //**
    //** @param(AName JSON name of the nested object.)
    //**
    //** @param(AClass Class of the object to create.)
    //**
    //** @returns(The new object, owned by the caller; nil when the property is absent or
    //** null.)
    //**
    //** @raises(EglTFError The nested object is invalid.)
    function ReadObject(AJSON: TJSONObject; const AName: string;
      AClass: TglTFPropertyClass): TglTFProperty;

    //** @abstract(Loads nested glTF objects, lists and maps; does nothing by default.)
    //**
    //** Called by @link(LoadFromJSON) after the simple values have been read. Free any
    //** previously loaded children first, as an object can be loaded more than once.
    //**
    //** @param(AJSON This object's JSON.)
    procedure ReadChildren(AJSON: TJSONObject); virtual;

    //** @abstract(Checks rules beyond "property X is required"; does nothing by default.)
    //**
    //** Called last by @link(LoadFromJSON). For example camera.type "perspective"
    //** requires camera.perspective. Raise with @link(RaiseMissing) or @link(RaiseInvalid).
    procedure Validate; virtual;

    //** @abstract(Raises @link(EglTFMissingPropertyError) for a property of this object.)
    //**
    //** @param(AJSONName JSON name of the missing property.)
    //**
    //** @raises(EglTFMissingPropertyError Always.)
    procedure RaiseMissing(const AJSONName: string);

    //** @abstract(Raises @link(EglTFParseError) for an invalid property of this object.)
    //**
    //** @param(AJSONName JSON name of the invalid property.)
    //**
    //** @param(AMessage Why it is invalid, for example "must be >= 1".)
    //**
    //** @raises(EglTFParseError Always.)
    procedure RaiseInvalid(const AJSONName, AMessage: string);

    //** @abstract(Writes nested glTF objects, lists and maps; does nothing by default.)
    //**
    //** The counterpart of @link(ReadChildren), called by @link(SaveToJSON) after the
    //** simple values have been written.
    //**
    //** @param(AJSON The JSON being built for this object.)
    procedure WriteChildren(AJSON: TJSONObject); virtual;

    //** @abstract(Writes a nested glTF object when it is assigned.)
    //**
    //** @param(AJSON The JSON being built for this object.)
    //**
    //** @param(AName JSON name to write it under.)
    //**
    //** @param(AChild The nested object; nothing is written when nil.)
    procedure WriteObject(AJSON: TJSONObject; const AName: string; AChild: TglTFProperty);
  public
    //** @abstract(Creates the object with the spec's default values.)
    //**
    //** Descendants set their defaults here; @link(SaveToJSON) leaves out values equal to
    //** them.
    constructor Create; virtual;

    //** @abstract(Frees the object and the JSON it keeps.)
    destructor Destroy; override;

    //** @abstract(Returns the object's name in the glTF specification.)
    //**
    //** @returns(For example "accessor"; used in error messages. The class name unless
    //** overridden.)
    class function glTFTypeName: string; virtual;

    //** @abstract(Loads this object from a JSON object.)
    //**
    //** Replaces everything loaded before. The JSON is not kept, except copies of
    //** extensions, extras and non-standard properties.
    //**
    //** @param(AJSON A JSON object; the caller keeps ownership.)
    //**
    //** @param(AJSONPath This object's location in the document, used in error messages
    //** and by @link(ChildPath).)
    //**
    //** @raises(EglTFParseError AJSON is not an object or a value is invalid.)
    //**
    //** @raises(EglTFMissingPropertyError A required property is missing.)
    procedure LoadFromJSON(AJSON: TJSONValue; const AJSONPath: string = '');

    //** @abstract(Builds the JSON for this object from its current property values.)
    //**
    //** Nothing comes from the JSON the object was loaded from. A simple value is written
    //** when it is required or differs from the spec default @(the value a new instance
    //** has@), so values changed in code are written whether or not they were in the
    //** original file. Nested objects come from @link(WriteChildren); extensions, extras
    //** and non-standard properties are written last.
    //**
    //** @returns(A new JSON object, owned by the caller.)
    //**
    //** @raises(EglTFError A value cannot be converted to JSON.)
    function SaveToJSON: TJSONObject; virtual;

    //** @abstract(Tells whether the loaded JSON contained a property.)
    //**
    //** Useful for optional values whose default could also appear explicitly, such as
    //** node.matrix. Reflects the last load only, not later changes; a JSON null counts as
    //** absent.
    //**
    //** @param(AJSONName JSON name of the property.)
    //**
    //** @returns(True when the property was present and not null.)
    function IsDefined(const AJSONName: string): Boolean;

    {$REGION 'Extensions'}
    //** @abstract(Tells whether the object has at least one extension.)
    //**
    //** @returns(True when "extensions" has at least one entry.)
    function HasExtensions: Boolean;

    //** @abstract(Tells whether the object has a given extension.)
    //**
    //** @param(AName Extension name, for example "KHR_materials_emissive_strength".)
    //**
    //** @returns(True when the extension is present.)
    function HasExtension(const AName: string): Boolean;

    //** @abstract(Returns the JSON of an extension.)
    //**
    //** @param(AName Extension name.)
    //**
    //** @returns(The extension's JSON, owned by this object; nil when absent.)
    function FindExtension(const AName: string): TJSONValue;

    //** @abstract(Returns the names of the object's extensions.)
    //**
    //** @returns(The names in file order; empty when there are none.)
    function ExtensionNames: TArray<string>;

    //** @abstract(Reads a typed value inside an extension.)
    //**
    //** @param(AExtension Extension name.)
    //**
    //** @param(APath Path inside the extension in System.JSON syntax, for example
    //** "a.b[0]"; empty for the extension itself.)
    //**
    //** @param(AValue The value; Default@(T@) when not found.)
    //**
    //** @returns(True when the value exists and converts to T.)
    function TryGetExtensionValue<T>(const AExtension, APath: string; out AValue: T): Boolean;

    //** @abstract(Deserialises an extension into an object of your own class with Neon.)
    //**
    //** @param(AName Extension name.)
    //**
    //** @param(AConfig Neon configuration; nil uses @link(ExtrasNeonConfig).)
    //**
    //** @returns(A new T, owned by the caller; nil when the extension is absent.)
    //**
    //** @raises(Exception Neon cannot map the JSON onto T.)
    function ExtensionAs<T: class, constructor>(const AName: string;
      const AConfig: INeonConfiguration = nil): T;
    {$ENDREGION}

    {$REGION 'Extras (application specific data)'}
    //** @abstract(Tells whether the object has an "extras" value.)
    //**
    //** @returns(True when "extras" was present.)
    function HasExtras: Boolean;

    //** @abstract(Tells whether a value exists inside "extras".)
    //**
    //** @param(APath Path in System.JSON syntax, for example "author.name".)
    //**
    //** @returns(True when the value exists.)
    function HasExtra(const APath: string): Boolean;

    //** @abstract(Returns the JSON at a path inside "extras".)
    //**
    //** @param(APath Path in System.JSON syntax; empty for "extras" itself.)
    //**
    //** @returns(The JSON, owned by this object; nil when absent.)
    function FindExtra(const APath: string): TJSONValue;

    //** @abstract(Returns the top-level names inside "extras".)
    //**
    //** @returns(The names in file order; empty when "extras" is absent or not a JSON
    //** object.)
    function ExtraNames: TArray<string>;

    //** @abstract(Reads a typed value inside "extras".)
    //**
    //** @param(APath Path in System.JSON syntax, for example "author.name".)
    //**
    //** @param(AValue The value; Default@(T@) when not found.)
    //**
    //** @returns(True when the value exists and converts to T.)
    function TryGetExtra<T>(const APath: string; out AValue: T): Boolean;

    //** @abstract(Reads a typed value inside "extras", with a fallback.)
    //**
    //** @param(APath Path in System.JSON syntax.)
    //**
    //** @param(ADefault Returned when the value is absent or does not convert to T.)
    //**
    //** @returns(The value, or ADefault.)
    //**
    //** @longCode(#
    //** Author := Asset.GetExtra<string>('author.name', '(unknown)');
    //** #)
    function GetExtra<T>(const APath: string; const ADefault: T): T;

    //** @abstract(Deserialises "extras", or a part of it, into an object of your own class
    //** with Neon.)
    //**
    //** @param(APath Path in System.JSON syntax; empty for "extras" itself.)
    //**
    //** @param(AConfig Neon configuration; nil uses @link(ExtrasNeonConfig).)
    //**
    //** @returns(A new T, owned by the caller; nil when absent.)
    //**
    //** @raises(Exception Neon cannot map the JSON onto T.)
    function ExtraAs<T: class, constructor>(const APath: string = '';
      const AConfig: INeonConfiguration = nil): T;
    {$ENDREGION}

    {$REGION 'Properties not in the glTF schema'}
    //** @abstract(Tells whether the object had a property the glTF schema does not
    //** define.)
    //**
    //** @param(AName JSON name of the property.)
    //**
    //** @returns(True when it was present.)
    function HasUnknownProperty(const AName: string): Boolean;

    //** @abstract(Returns the JSON of a property the glTF schema does not define.)
    //**
    //** @param(AName JSON name of the property.)
    //**
    //** @returns(The JSON, owned by this object; nil when absent.)
    function FindUnknownProperty(const AName: string): TJSONValue;
    {$ENDREGION}

    //** @abstract(This object's location in the document, for example "nodes[3]".)
    //**
    //** Empty for the root object.
    property JSONPath: string read FJSONPath;

    //** @abstract(JSON names of the properties present in the loaded JSON.)
    //**
    //** Null values are not included. See @link(IsDefined).
    property DefinedProperties: TArray<string> read FDefinedProperties;

    //** @abstract(Sets one member of the "extras" JSON object.)
    //**
    //** Creates "extras" as an object when it is absent and replaces a member with the same
    //** name. Written back by @link(SaveToJSON).
    //**
    //** @param(AName The member name.)
    //**
    //** @param(AValue The value; this object owns it from now on.)
    //**
    //** @raises(EglTFError "extras" is present but is not a JSON object; AValue is freed.)
    procedure SetExtra(const AName: string; AValue: TJSONValue);

    //** @abstract(The "extensions" JSON object; nil when absent.)
    //**
    //** Owned by this object and written back by @link(SaveToJSON).
    property Extensions: TJSONObject read FExtensions;

    //** @abstract(The "extras" JSON value; nil when absent.)
    //**
    //** Owned by this object and written back by @link(SaveToJSON).
    property Extras: TJSONValue read FExtras;

    //** @abstract(Properties the glTF schema does not define; nil when there are none.)
    //**
    //** Owned by this object and written back by @link(SaveToJSON).
    property UnknownProperties: TJSONObject read FUnknownProperties;

    //** @abstract(Neon configuration used by @link(ExtraAs) and @link(ExtensionAs) when
    //** none is passed.)
    //**
    //** Defaults to camelCase member names with exceptions raised. Shared by all objects;
    //** set it at start-up, not while other threads load documents.
    class property ExtrasNeonConfig: INeonConfiguration read FExtrasNeonConfig write FExtrasNeonConfig;
  end;

  //** @abstract(Abstract base of the objects stored in the root's arrays,
  //** glTFChildOfRootProperty in the schema.)
  //**
  //** Adds the optional "name".
  TglTFChildOfRootProperty = class abstract(TglTFProperty)
  private
    FName: string;
  public
    //** @abstract(The glTF "name": a user-defined name; empty when not set.)
    //**
    //** Not required to be unique.
    [NeonProperty('name')]
    property Name: string read FName write FName;
  end;

  //** @abstract(Owning list of glTF objects, loaded from and saved to a JSON array.)
  //**
  //** Frees its items. The index of an item is its glTF index, which other objects use to
  //** refer to it, so removing or reordering items changes those references.
  TglTFList<T: TglTFProperty, constructor> = class(TObjectList<T>)
  public
    //** @abstract(Creates an empty list that owns its items.)
    constructor Create;

    //** @abstract(Clears the list, then loads one item per element of a JSON array.)
    //**
    //** @param(AJSON The JSON array; nil or null gives an empty list.)
    //**
    //** @param(AJSONPath Location of the array, for example "meshes"; items get
    //** "meshes[0]" and so on.)
    //**
    //** @raises(EglTFParseError AJSON is not an array, or an item is invalid.)
    //**
    //** @raises(EglTFMissingPropertyError An item lacks a required property.)
    procedure LoadFromJSON(AJSON: TJSONValue; const AJSONPath: string);

    //** @abstract(Returns a JSON array with every item's @code(SaveToJSON).)
    //**
    //** @returns(A new array, owned by the caller.)
    function SaveToJSON: TJSONArray;

    //** @abstract(Adds the list as a JSON array to a JSON object.)
    //**
    //** @param(AJSON The object to add to; it owns the new array.)
    //**
    //** @param(AName JSON name of the array.)
    //**
    //** @param(AAlways Also write an empty list, for arrays the schema requires.)
    procedure WriteTo(AJSON: TJSONObject; const AName: string; AAlways: Boolean = False);
  end;


implementation

function DisplayPath(const APath: string): string;
begin
  if APath = '' then
    Result := '<root>'
  else
    Result := APath;
end;

{ EglTFError }

function EglTFError.GetHasSourceLocation: Boolean;
begin
  Result := FLine > 0;
end;

procedure EglTFError.SetSourceLocation(const ASourceName: string; ALine, AColumn,
  AEndLine: Integer);
var
  LWhere: string;
begin
  if HasSourceLocation or (ALine <= 0) then
    Exit;

  FSourceName := ASourceName;
  FLine := ALine;
  FColumn := AColumn;
  if AEndLine > ALine then
    FEndLine := AEndLine
  else
    FEndLine := ALine;

  if FEndLine > FLine then
    LWhere := Format('lines %d-%d', [FLine, FEndLine])
  else
    LWhere := Format('line %d, column %d', [FLine, FColumn]);
  if FSourceName <> '' then
    LWhere := FSourceName + ', ' + LWhere;

  Message := Message + ' [' + LWhere + ']';
end;

{ EglTFParseError }

constructor EglTFParseError.Create(const AJSONPath, AMessage: string);
begin
  inherited CreateFmt('%s (at "%s")', [AMessage, DisplayPath(AJSONPath)]);
  FJSONPath := AJSONPath;
end;

{ EglTFMissingPropertyError }

constructor EglTFMissingPropertyError.Create(const AObjectType, APropertyName, AJSONPath: string);
begin
  inherited CreateFmt('Required glTF property "%s" is missing from %s (at "%s")',
    [APropertyName, AObjectType, DisplayPath(AJSONPath)]);
  FObjectType := AObjectType;
  FPropertyName := APropertyName;
  FJSONPath := AJSONPath;
end;

{ TglTFTypeInfo }

constructor TglTFTypeInfo.Create;
begin
  inherited Create;
  FKnown := TDictionary<string, Boolean>.Create;
  FRequired := TList<string>.Create;
  FWritable := TList<TglTFMemberInfo>.Create;
  FProps := TList<TRttiProperty>.Create;
  FDefaultValues := TList<TValue>.Create;
end;

destructor TglTFTypeInfo.Destroy;
begin
  FDefaultValues.Free;
  FProps.Free;
  FDefaults.Free;
  FWritable.Free;
  FRequired.Free;
  FKnown.Free;
  inherited;
end;

{ TglTFProperty }

class constructor TglTFProperty.ClassCreate;
begin
  FTypeInfos := TObjectDictionary<TClass, TglTFTypeInfo>.Create([doOwnsValues]);

  // Simple values are read and written by ReadValues and WriteValues, and
  // nested objects, lists and maps by ReadChildren and WriteChildren. Neon is
  // only used for a property of some other type (none in glTF.Classes) and
  // for mapping extras and extensions onto classes
  FNeonConfig := TNeonConfiguration.Camel
    .SetMembers([TNeonMembers.Properties])
    .SetVisibility([mvPublic, mvPublished])
    .SetStrictTypes(True)
    .SetAutoCreate(False)
    .SetRaiseExceptions(True);

  FExtrasNeonConfig := TNeonConfiguration.Camel
    .SetRaiseExceptions(True);

  FRtti := TRttiContext.Create;
end;

class destructor TglTFProperty.ClassDestroy;
begin
  FNeonConfig := nil;
  FExtrasNeonConfig := nil;
  FTypeInfos.Free;
  FRtti.Free;
end;

class function TglTFProperty.GetglTFTypeInfo(AClass: TClass): TglTFTypeInfo;
var
  LProp: TRttiProperty;
  LAttr: TCustomAttribute;
  LName: string;
  LRequired: Boolean;
  LMember: TglTFMemberInfo;
begin
  TMonitor.Enter(FTypeInfos);
  try
    if FTypeInfos.TryGetValue(AClass, Result) then
      Exit;

    Result := TglTFTypeInfo.Create;
    try
      // GetProperties includes the inherited ones (most derived first)
      for LProp in FRtti.GetType(AClass).GetProperties do
      begin
        if not (LProp.Visibility in [mvPublic, mvPublished]) then
          Continue;

        LName := '';
        LRequired := False;
        for LAttr in LProp.GetAttributes do
        begin
          if LAttr is NeonPropertyAttribute then
            LName := NeonPropertyAttribute(LAttr).Value
          else if LAttr is glTFRequiredAttribute then
            LRequired := True;
        end;

        if (LName = '') or Result.FKnown.ContainsKey(LName) then
          Continue;

        Result.FKnown.Add(LName, LRequired);
        if LRequired then
          Result.FRequired.Add(LName);

        if LProp.IsWritable and Assigned(LProp.PropertyType) then
        begin
          LMember.JSONName := LName;
          LMember.PropertyName := LProp.Name;
          LMember.TypeInfo := LProp.PropertyType.Handle;
          LMember.Required := LRequired;
          Result.FWritable.Add(LMember);
          Result.FProps.Add(LProp);
        end;
      end;
      // Only requested for the class of a real instance, so this is concrete
      Result.FDefaults := TglTFPropertyClass(AClass).Create;
      for LProp in Result.FProps do
        Result.FDefaultValues.Add(LProp.GetValue(Result.FDefaults));
    except
      Result.Free;
      raise;
    end;

    FTypeInfos.Add(AClass, Result);
  finally
    TMonitor.Exit(FTypeInfos);
  end;
end;

constructor TglTFProperty.Create;
begin
  inherited Create;
end;

destructor TglTFProperty.Destroy;
begin
  ClearCapturedJSON;
  inherited;
end;

class function TglTFProperty.glTFTypeName: string;
begin
  Result := ClassName;
end;

procedure TglTFProperty.ClearCapturedJSON;
begin
  FreeAndNil(FExtensions);
  FreeAndNil(FExtras);
  FreeAndNil(FUnknownProperties);
  FDefinedProperties := nil;
end;

function TglTFProperty.ChildPath(const AName: string): string;
begin
  if FJSONPath = '' then
    Result := AName
  else
    Result := FJSONPath + '.' + AName;
end;

procedure TglTFProperty.RaiseMissing(const AJSONName: string);
begin
  raise EglTFMissingPropertyError.Create(glTFTypeName, AJSONName, FJSONPath);
end;

procedure TglTFProperty.RaiseInvalid(const AJSONName, AMessage: string);
begin
  raise EglTFParseError.Create(ChildPath(AJSONName),
    Format('Invalid %s.%s: %s', [glTFTypeName, AJSONName, AMessage]));
end;

procedure TglTFProperty.LoadFromJSON(AJSON: TJSONValue; const AJSONPath: string);
var
  LObject: TJSONObject;
  LCount, I: Integer;
begin
  ClearCapturedJSON;
  FJSONPath := AJSONPath;

  if not (AJSON is TJSONObject) then
    raise EglTFParseError.Create(AJSONPath,
      Format('Expected a JSON object for glTF %s', [glTFTypeName]));

  LObject := TJSONObject(AJSON);

  // Remember which properties were present (JSON null counts as absent)
  SetLength(FDefinedProperties, LObject.Count);
  LCount := 0;
  for I := 0 to LObject.Count - 1 do
    if not (LObject.Pairs[I].JsonValue is TJSONNull) then
    begin
      FDefinedProperties[LCount] := LObject.Pairs[I].JsonString.Value;
      Inc(LCount);
    end;
  SetLength(FDefinedProperties, LCount);

  CheckRequired(LObject);
  ReadValues(LObject);
  CaptureExtraJSON(LObject);
  ReadChildren(LObject);
  Validate;
end;

procedure TglTFProperty.CheckRequired(AJSON: TJSONObject);
var
  LName: string;
  LValue: TJSONValue;
begin
  for LName in GetglTFTypeInfo(ClassType).FRequired do
  begin
    LValue := AJSON.GetValue(LName);
    if (LValue = nil) or (LValue is TJSONNull) then
      RaiseMissing(LName);
  end;
end;

// Reads a JSON value as a whole number
function JSONToInt64(AJSON: TJSONValue; out AValue: Int64; out AError: string): Boolean;
var
  LDouble: Double;
begin
  Result := False;
  if not (AJSON is TJSONNumber) then
  begin
    AError := 'a number is expected';
    Exit;
  end;
  if TryStrToInt64(TJSONNumber(AJSON).Value, AValue) then
    Exit(True);
  // 3.0 or 3e0 is a whole number too
  LDouble := TJSONNumber(AJSON).AsDouble;
  if (Frac(LDouble) <> 0) or (Abs(LDouble) > 9.0e18) then
  begin
    AError := 'a whole number is expected';
    Exit;
  end;
  AValue := Trunc(LDouble);
  Result := True;
end;

// Converts a JSON value to a value of a simple property type. Neon handles
// any other type, which the glTF classes do not use
function JSONToTValue(AJSON: TJSONValue; AType: TRttiType; const AConfig: INeonConfiguration;
  out AResult: TValue; out AError: string): Boolean;
var
  L64: Int64;
  LArray: TJSONArray;
  LElementType: TRttiType;
  LElements: TArray<TValue>;
  I: Integer;
begin
  Result := False;
  AError := '';
  case AType.TypeKind of
    tkInteger:
    begin
      if not JSONToInt64(AJSON, L64, AError) then
        Exit;
      if (L64 < Low(Integer)) or (L64 > High(Integer)) then
      begin
        AError := 'the number is out of range';
        Exit;
      end;
      AResult := TValue.FromOrdinal(AType.Handle, L64);
    end;

    tkInt64:
    begin
      if not JSONToInt64(AJSON, L64, AError) then
        Exit;
      AResult := TValue.From<Int64>(L64);
    end;

    tkFloat:
    begin
      if not (AJSON is TJSONNumber) then
      begin
        AError := 'a number is expected';
        Exit;
      end;
      if AType.Handle = System.TypeInfo(Double) then
        AResult := TValue.From<Double>(TJSONNumber(AJSON).AsDouble)
      else if AType.Handle = System.TypeInfo(Single) then
        AResult := TValue.From<Single>(TJSONNumber(AJSON).AsDouble)
      else
        AResult := TValue.From<Extended>(TJSONNumber(AJSON).AsDouble);
    end;

    tkUString, tkString, tkLString, tkWString:
    begin
      // TJSONNumber derives from TJSONString
      if not (AJSON is TJSONString) or (AJSON is TJSONNumber) then
      begin
        AError := 'a string is expected';
        Exit;
      end;
      AResult := TValue.From<string>(TJSONString(AJSON).Value);
    end;

    tkDynArray:
    begin
      if not (AJSON is TJSONArray) then
      begin
        AError := 'an array is expected';
        Exit;
      end;
      LArray := TJSONArray(AJSON);
      LElementType := TRttiDynamicArrayType(AType).ElementType;
      SetLength(LElements, LArray.Count);
      for I := 0 to LArray.Count - 1 do
        if not JSONToTValue(LArray.Items[I], LElementType, AConfig, LElements[I], AError) then
        begin
          AError := Format('element %d: %s', [I, AError]);
          Exit;
        end;
      AResult := TValue.FromArray(AType.Handle, LElements);
    end;
  else
    if AType.Handle = System.TypeInfo(Boolean) then
    begin
      if not (AJSON is TJSONBool) then
      begin
        AError := 'true or false is expected';
        Exit;
      end;
      AResult := TValue.From<Boolean>(TJSONBool(AJSON).AsBoolean);
    end
    else
      try
        AResult := TNeon.JSONToValue(AType, AJSON, AConfig);
      except
        on E: Exception do
        begin
          AError := E.Message;
          Exit;
        end;
      end;
  end;
  Result := True;
end;

procedure TglTFProperty.ReadValues(AJSON: TJSONObject);
var
  LInfo: TglTFTypeInfo;
  LMember: TglTFMemberInfo;
  LJSON: TJSONValue;
  LValue: TValue;
  LError: string;
  I: Integer;
begin
  // Every object of a file comes through here, so this reads the values
  // itself with the RTTI cached for the class, rather than through Neon
  LInfo := GetglTFTypeInfo(ClassType);
  for I := 0 to LInfo.FWritable.Count - 1 do
  begin
    LMember := LInfo.FWritable[I];
    LJSON := AJSON.GetValue(LMember.JSONName);
    if (LJSON = nil) or (LJSON is TJSONNull) then
      Continue;
    if not JSONToTValue(LJSON, LInfo.FProps[I].PropertyType, FNeonConfig, LValue, LError) then
      raise EglTFParseError.Create(ChildPath(LMember.JSONName),
        Format('Invalid value for glTF %s.%s: %s', [glTFTypeName, LMember.JSONName, LError]));
    LInfo.FProps[I].SetValue(Self, LValue);
  end;
end;

procedure TglTFProperty.CaptureExtraJSON(AJSON: TJSONObject);
var
  LInfo: TglTFTypeInfo;
  LPair: TJSONPair;
  LName: string;
  I: Integer;
begin
  LInfo := GetglTFTypeInfo(ClassType);

  for I := 0 to AJSON.Count - 1 do
  begin
    LPair := AJSON.Pairs[I];
    LName := LPair.JsonString.Value;

    if LName = 'extensions' then
    begin
      if not (LPair.JsonValue is TJSONObject) then
        RaiseInvalid('extensions', 'must be a JSON object');
      FExtensions := LPair.JsonValue.Clone as TJSONObject;
    end
    else if LName = 'extras' then
      FExtras := LPair.JsonValue.Clone as TJSONValue
    else if not LInfo.FKnown.ContainsKey(LName) then
    begin
      if FUnknownProperties = nil then
        FUnknownProperties := TJSONObject.Create;
      FUnknownProperties.AddPair(LName, LPair.JsonValue.Clone as TJSONValue);
    end;
  end;
end;

function TglTFProperty.ReadObject(AJSON: TJSONObject; const AName: string;
  AClass: TglTFPropertyClass): TglTFProperty;
var
  LValue: TJSONValue;
begin
  Result := nil;
  LValue := AJSON.GetValue(AName);
  if (LValue = nil) or (LValue is TJSONNull) then
    Exit;

  Result := AClass.Create;
  try
    Result.LoadFromJSON(LValue, ChildPath(AName));
  except
    Result.Free;
    raise;
  end;
end;

procedure TglTFProperty.ReadChildren(AJSON: TJSONObject);
begin
  // Nothing to do by default
end;

procedure TglTFProperty.WriteChildren(AJSON: TJSONObject);
begin
  // Nothing to do by default
end;

procedure TglTFProperty.WriteObject(AJSON: TJSONObject; const AName: string;
  AChild: TglTFProperty);
begin
  if Assigned(AChild) then
    AJSON.AddPair(AName, AChild.SaveToJSON);
end;

// Value equality used to leave out values equal to the spec default
function SameTValue(const A, B: TValue): Boolean;
var
  I: Integer;
begin
  if A.Kind <> B.Kind then
    Exit(False);

  case A.Kind of
    tkDynArray, tkArray:
    begin
      if A.GetArrayLength <> B.GetArrayLength then
        Exit(False);
      for I := 0 to A.GetArrayLength - 1 do
        if not SameTValue(A.GetArrayElement(I), B.GetArrayElement(I)) then
          Exit(False);
      Result := True;
    end;
    tkInteger, tkInt64, tkEnumeration, tkChar, tkWChar:
      Result := A.AsOrdinal = B.AsOrdinal;
    tkFloat:
      Result := A.AsExtended = B.AsExtended;
    tkString, tkLString, tkWString, tkUString:
      Result := A.AsString = B.AsString;
  else
    Result := False; // anything else is always written
  end;
end;

// Shortest text that reads back as exactly the same Double (15 to 17
// significant digits), so saving never loses precision
function FloatToJSONText(AValue: Double): string;
var
  LPrecision: Integer;
begin
  for LPrecision := 15 to 17 do
  begin
    Result := FloatToStrF(AValue, ffGeneral, LPrecision, 0, TFormatSettings.Invariant);
    if StrToFloat(Result, TFormatSettings.Invariant) = AValue then
      Exit;
  end;
end;

// JSON for a property value: floats (and float arrays) exactly, anything
// else through Neon
function ValueToJSON(const AValue: TValue; const AConfig: INeonConfiguration): TJSONValue;
var
  LArray: TJSONArray;
  I: Integer;
begin
  case AValue.Kind of
    tkFloat:
      Exit(TJSONNumber.Create(FloatToJSONText(AValue.AsExtended)));
    tkInteger, tkInt64:
      Exit(TJSONNumber.Create(AValue.AsInt64));
    tkUString, tkString, tkLString, tkWString:
      Exit(TJSONString.Create(AValue.AsString));
    tkDynArray:
    begin
      LArray := TJSONArray.Create;
      try
        for I := 0 to AValue.GetArrayLength - 1 do
          LArray.AddElement(ValueToJSON(AValue.GetArrayElement(I), AConfig));
      except
        LArray.Free;
        raise;
      end;
      Exit(LArray);
    end;
  end;
  if AValue.TypeInfo = System.TypeInfo(Boolean) then
    Exit(TJSONBool.Create(AValue.AsBoolean));
  Result := TNeon.ValueToJSON(AValue, AConfig);
end;

function TglTFProperty.SaveToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    WriteValues(Result);
    WriteChildren(Result);
    WriteCapturedJSON(Result);
  except
    Result.Free;
    raise;
  end;
end;

procedure TglTFProperty.WriteValues(AJSON: TJSONObject);
var
  LInfo: TglTFTypeInfo;
  LMember: TglTFMemberInfo;
  LValue: TValue;
  LJSON: TJSONValue;
  I: Integer;
begin
  LInfo := GetglTFTypeInfo(ClassType);
  for I := 0 to LInfo.FWritable.Count - 1 do
  begin
    LMember := LInfo.FWritable[I];
    LValue := LInfo.FProps[I].GetValue(Self);

    // Values equal to the spec default are left out, unless required
    if not LMember.Required and SameTValue(LValue, LInfo.FDefaultValues[I]) then
      Continue;

    try
      LJSON := ValueToJSON(LValue, FNeonConfig);
    except
      on E: Exception do
        raise EglTFError.CreateFmt('Cannot write glTF %s.%s: %s',
          [glTFTypeName, LMember.JSONName, E.Message]);
    end;
    if Assigned(LJSON) then
      AJSON.AddPair(LMember.JSONName, LJSON);
  end;
end;

procedure TglTFProperty.WriteCapturedJSON(AJSON: TJSONObject);
var
  I: Integer;
begin
  if Assigned(FExtensions) and (FExtensions.Count > 0) then
    AJSON.AddPair('extensions', FExtensions.Clone as TJSONObject);
  if Assigned(FExtras) then
    AJSON.AddPair('extras', FExtras.Clone as TJSONValue);
  if Assigned(FUnknownProperties) then
    for I := 0 to FUnknownProperties.Count - 1 do
      AJSON.AddPair(FUnknownProperties.Pairs[I].JsonString.Value,
        FUnknownProperties.Pairs[I].JsonValue.Clone as TJSONValue);
end;

procedure TglTFProperty.Validate;
begin
  // Nothing to do by default
end;

function TglTFProperty.IsDefined(const AJSONName: string): Boolean;
var
  LName: string;
begin
  for LName in FDefinedProperties do
    if LName = AJSONName then
      Exit(True);
  Result := False;
end;

{ Extensions }

function TglTFProperty.HasExtensions: Boolean;
begin
  Result := Assigned(FExtensions) and (FExtensions.Count > 0);
end;

function TglTFProperty.HasExtension(const AName: string): Boolean;
begin
  Result := FindExtension(AName) <> nil;
end;

function TglTFProperty.FindExtension(const AName: string): TJSONValue;
begin
  if FExtensions = nil then
    Result := nil
  else
    Result := FExtensions.GetValue(AName);
end;

function TglTFProperty.ExtensionNames: TArray<string>;
var
  I: Integer;
begin
  Result := nil;
  if FExtensions = nil then
    Exit;
  SetLength(Result, FExtensions.Count);
  for I := 0 to FExtensions.Count - 1 do
    Result[I] := FExtensions.Pairs[I].JsonString.Value;
end;

function TglTFProperty.TryGetExtensionValue<T>(const AExtension, APath: string; out AValue: T): Boolean;
var
  LExtension: TJSONValue;
begin
  AValue := Default(T);
  LExtension := FindExtension(AExtension);
  if LExtension = nil then
    Exit(False);

  if APath = '' then
    Result := LExtension.TryGetValue<T>(AValue)
  else
    Result := LExtension.TryGetValue<T>(APath, AValue);
end;

function TglTFProperty.ExtensionAs<T>(const AName: string; const AConfig: INeonConfiguration): T;
var
  LValue: TJSONValue;
  LConfig: INeonConfiguration;
begin
  Result := nil;
  LValue := FindExtension(AName);
  if LValue = nil then
    Exit;

  LConfig := AConfig;
  if LConfig = nil then
    LConfig := FExtrasNeonConfig;
  Result := TNeon.JSONToObject<T>(LValue, LConfig);
end;

{ Extras }

function TglTFProperty.HasExtras: Boolean;
begin
  Result := Assigned(FExtras);
end;

function TglTFProperty.HasExtra(const APath: string): Boolean;
begin
  Result := FindExtra(APath) <> nil;
end;

function TglTFProperty.FindExtra(const APath: string): TJSONValue;
begin
  if FExtras = nil then
    Result := nil
  else if APath = '' then
    Result := FExtras
  else
    Result := FExtras.FindValue(APath);
end;

function TglTFProperty.ExtraNames: TArray<string>;
var
  LObject: TJSONObject;
  I: Integer;
begin
  Result := nil;
  if not (FExtras is TJSONObject) then
    Exit;
  LObject := TJSONObject(FExtras);
  SetLength(Result, LObject.Count);
  for I := 0 to LObject.Count - 1 do
    Result[I] := LObject.Pairs[I].JsonString.Value;
end;

function TglTFProperty.TryGetExtra<T>(const APath: string; out AValue: T): Boolean;
var
  LValue: TJSONValue;
begin
  AValue := Default(T);
  LValue := FindExtra(APath);
  if LValue = nil then
    Exit(False);
  Result := LValue.TryGetValue<T>(AValue);
end;

function TglTFProperty.GetExtra<T>(const APath: string; const ADefault: T): T;
begin
  if not TryGetExtra<T>(APath, Result) then
    Result := ADefault;
end;

function TglTFProperty.ExtraAs<T>(const APath: string; const AConfig: INeonConfiguration): T;
var
  LValue: TJSONValue;
  LConfig: INeonConfiguration;
begin
  Result := nil;
  LValue := FindExtra(APath);
  if LValue = nil then
    Exit;

  LConfig := AConfig;
  if LConfig = nil then
    LConfig := FExtrasNeonConfig;
  Result := TNeon.JSONToObject<T>(LValue, LConfig);
end;

{ Unknown properties }

procedure TglTFProperty.SetExtra(const AName: string; AValue: TJSONValue);
begin
  if FExtras = nil then
    FExtras := TJSONObject.Create
  else if not (FExtras is TJSONObject) then
  begin
    AValue.Free;
    raise EglTFError.CreateFmt('The extras of this glTF %s are not a JSON object', [glTFTypeName]);
  end;
  TJSONObject(FExtras).RemovePair(AName).Free;
  TJSONObject(FExtras).AddPair(AName, AValue);
end;

function TglTFProperty.HasUnknownProperty(const AName: string): Boolean;
begin
  Result := FindUnknownProperty(AName) <> nil;
end;

function TglTFProperty.FindUnknownProperty(const AName: string): TJSONValue;
begin
  if FUnknownProperties = nil then
    Result := nil
  else
    Result := FUnknownProperties.GetValue(AName);
end;

{ TglTFList<T> }

constructor TglTFList<T>.Create;
begin
  inherited Create(True);
end;

procedure TglTFList<T>.LoadFromJSON(AJSON: TJSONValue; const AJSONPath: string);
var
  LArray: TJSONArray;
  LItem: T;
  I: Integer;
begin
  Clear;
  if (AJSON = nil) or (AJSON is TJSONNull) then
    Exit;

  if not (AJSON is TJSONArray) then
    raise EglTFParseError.Create(AJSONPath, 'Expected a JSON array');

  LArray := TJSONArray(AJSON);
  for I := 0 to LArray.Count - 1 do
  begin
    LItem := T.Create;
    try
      LItem.LoadFromJSON(LArray.Items[I], Format('%s[%d]', [AJSONPath, I]));
    except
      LItem.Free;
      raise;
    end;
    Add(LItem);
  end;
end;

function TglTFList<T>.SaveToJSON: TJSONArray;
var
  LItem: T;
begin
  Result := TJSONArray.Create;
  try
    for LItem in Self do
      Result.AddElement(LItem.SaveToJSON);
  except
    Result.Free;
    raise;
  end;
end;

procedure TglTFList<T>.WriteTo(AJSON: TJSONObject; const AName: string; AAlways: Boolean);
begin
  if (Count > 0) or AAlways then
    AJSON.AddPair(AName, SaveToJSON);
end;

end.
