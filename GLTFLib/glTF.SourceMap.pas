//** @abstract(Maps JSON paths of a glTF text to lines and columns, for error messages.)
//**
//** System.JSON does not keep positions, so @link(TglTFSourceMap) scans the original text
//** itself and records where every value is, keyed by the same path syntax as
//** @code(TglTFProperty.JSONPath), for example "accessors[1].count".
//**
//** TglTFDocument builds a map only when an error has to be reported, so a successful load
//** costs nothing extra.
unit glTF.SourceMap;

{
  Maps JSON paths of a glTF text to lines and columns, for error messages.

  System.JSON does not keep positions, so TglTFSourceMap scans the original
  text itself and records where every value is, keyed by the same path syntax
  as TglTFProperty.JSONPath, for example "accessors[1].count".

  TglTFDocument builds a map only when an error has to be reported, so a
  successful load costs nothing extra.
}

// Strings are indexed from 1 on every platform
{$ZEROBASEDSTRINGS OFF}

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  //** @abstract(Where a value is in the source text; all positions are 1-based.)
  /// <summary>Where a value is in the source text; all positions are 1-based.</summary>
  TglTFSourceSpan = record
    //** @abstract(Line where the value starts; for an object member, the line of its key.)
    /// <summary>Line where the value starts; for an object member, the line of its
    /// key.</summary>
    StartLine: Integer;

    //** @abstract(Column where the value starts; for an object member, the column of its key.)
    /// <summary>Column where the value starts; for an object member, the column of its
    /// key.</summary>
    StartColumn: Integer;

    //** @abstract(Line of the value's last character.)
    /// <summary>Line of the value's last character.</summary>
    EndLine: Integer;

    //** @abstract(Column of the value's last character.)
    /// <summary>Column of the value's last character.</summary>
    EndColumn: Integer;
  end;

  //** @abstract(Positions of every value of a JSON text, looked up by JSON path.)
  //**
  //** The whole text is scanned once, in the constructor. It tolerates malformed JSON: mapping
  //** stops where the text stops making sense. Not thread-safe.
  /// <summary>Positions of every value of a JSON text, looked up by JSON path.</summary>
  /// <remarks>The whole text is scanned once, in the constructor. It tolerates malformed JSON:
  /// mapping stops where the text stops making sense. Not thread-safe.</remarks>
  TglTFSourceMap = class
  private
    FText: string;
    FLength: Integer;
    FPos: Integer;
    FLine: Integer;
    FColumn: Integer;
    FPrevLine: Integer;
    FPrevColumn: Integer;
    FSpans: TDictionary<string, TglTFSourceSpan>;
    function Current: Char; inline;
    function AtEnd: Boolean; inline;
    procedure Advance;
    procedure SkipWhitespace;
    function ReadString: string;
    procedure SkipLiteral;
    function ParseValue(const APath: string; ARecord: Boolean): TglTFSourceSpan;
    procedure ParseObject(const APath: string);
    procedure ParseArray(const APath: string);
    class function MemberPath(const AParent, AName: string): string; static;
    class function ParentPath(const APath: string): string; static;
  public
    //** @abstract(Scans a JSON text and records the position of every value.)
    //**
    //** @param(AText The JSON text, as loaded; LF, CRLF and CR line ends are all counted.)
    /// <summary>Scans a JSON text and records the position of every value.</summary>
    /// <param name="AText">The JSON text, as loaded; LF, CRLF and CR line ends are all
    /// counted.</param>
    constructor Create(const AText: string);

    //** @abstract(Frees the map.)
    /// <summary>Frees the map.</summary>
    destructor Destroy; override;

    //** @abstract(Finds where a value is in the text.)
    //**
    //** When the path itself is not in the text, for example a property that is missing, the
    //** nearest enclosing value is returned, up to the root.
    //**
    //** @param(AJSONPath Path of the value, for example "meshes[0].primitives[2]"; empty for
    //** the root.)
    //**
    //** @param(ASpan Where the value, or its nearest enclosing value, is.)
    //**
    //** @returns(False only when not even the root was found.)
    /// <summary>Finds where a value is in the text.</summary>
    /// <param name="AJSONPath">Path of the value, for example "meshes[0].primitives[2]"; empty
    /// for the root.</param>
    /// <param name="ASpan">Where the value, or its nearest enclosing value, is.</param>
    /// <returns>False only when not even the root was found.</returns>
    /// <remarks>When the path itself is not in the text, for example a property that is
    /// missing, the nearest enclosing value is returned, up to the root.</remarks>
    function TryFind(const AJSONPath: string; out ASpan: TglTFSourceSpan): Boolean;
  end;

implementation

{ TglTFSourceMap }

constructor TglTFSourceMap.Create(const AText: string);
begin
  inherited Create;
  FSpans := TDictionary<string, TglTFSourceSpan>.Create;
  FText := AText;
  FLength := Length(AText);
  FPos := 1;
  FLine := 1;
  FColumn := 1;
  FPrevLine := 1;
  FPrevColumn := 1;
  ParseValue('', True);
end;

destructor TglTFSourceMap.Destroy;
begin
  FSpans.Free;
  inherited;
end;

function TglTFSourceMap.AtEnd: Boolean;
begin
  Result := FPos > FLength;
end;

function TglTFSourceMap.Current: Char;
begin
  if FPos <= FLength then
    Result := FText[FPos]
  else
    Result := #0;
end;

procedure TglTFSourceMap.Advance;
begin
  if AtEnd then
    Exit;

  FPrevLine := FLine;
  FPrevColumn := FColumn;

  // LF, CRLF and a lone CR all end a line
  if FText[FPos] = #10 then
  begin
    Inc(FLine);
    FColumn := 1;
  end
  else if FText[FPos] = #13 then
  begin
    if (FPos < FLength) and (FText[FPos + 1] = #10) then
      Inc(FColumn)
    else
    begin
      Inc(FLine);
      FColumn := 1;
    end;
  end
  else
    Inc(FColumn);

  Inc(FPos);
end;

procedure TglTFSourceMap.SkipWhitespace;
begin
  while CharInSet(Current, [' ', #9, #10, #13]) do
    Advance;
end;

function TglTFSourceMap.ReadString: string;
var
  LBuilder: TStringBuilder;
  LCode: Integer;
  LHex: string;
begin
  // Assumes Current = '"'
  LBuilder := TStringBuilder.Create;
  try
    Advance;
    while not AtEnd and (Current <> '"') do
    begin
      if Current = '\' then
      begin
        Advance;
        case Current of
          'n': LBuilder.Append(#10);
          'r': LBuilder.Append(#13);
          't': LBuilder.Append(#9);
          'b': LBuilder.Append(#8);
          'f': LBuilder.Append(#12);
          'u':
          begin
            LHex := Copy(FText, FPos + 1, 4);
            if TryStrToInt('$' + LHex, LCode) then
            begin
              LBuilder.Append(Char(LCode));
              Advance; Advance; Advance; Advance;
            end;
          end;
        else
          LBuilder.Append(Current); // \" \\ \/
        end;
      end
      else
        LBuilder.Append(Current);
      Advance;
    end;
    Advance; // closing quote
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

procedure TglTFSourceMap.SkipLiteral;
begin
  // numbers, true, false, null
  while not AtEnd and not CharInSet(Current, [',', '}', ']', ' ', #9, #10, #13]) do
    Advance;
end;

function TglTFSourceMap.ParseValue(const APath: string; ARecord: Boolean): TglTFSourceSpan;
begin
  SkipWhitespace;
  Result.StartLine := FLine;
  Result.StartColumn := FColumn;

  case Current of
    '{': ParseObject(APath);
    '[': ParseArray(APath);
    '"': ReadString;
  else
    SkipLiteral;
  end;

  Result.EndLine := FPrevLine;
  Result.EndColumn := FPrevColumn;
  if ARecord then
    if not FSpans.ContainsKey(APath) then
      FSpans.Add(APath, Result);
end;

procedure TglTFSourceMap.ParseObject(const APath: string);
var
  LKeyLine, LKeyColumn: Integer;
  LName, LPath: string;
  LValueSpan, LSpan: TglTFSourceSpan;
begin
  Advance; // {
  SkipWhitespace;
  if Current = '}' then
  begin
    Advance;
    Exit;
  end;

  while not AtEnd do
  begin
    SkipWhitespace;
    if Current <> '"' then
      Exit; // malformed: stop mapping
    LKeyLine := FLine;
    LKeyColumn := FColumn;
    LName := ReadString;

    SkipWhitespace;
    if Current <> ':' then
      Exit;
    Advance;

    LPath := MemberPath(APath, LName);
    LValueSpan := ParseValue(LPath, False);

    // A member is reported from its key to the end of its value
    LSpan.StartLine := LKeyLine;
    LSpan.StartColumn := LKeyColumn;
    LSpan.EndLine := LValueSpan.EndLine;
    LSpan.EndColumn := LValueSpan.EndColumn;
    // First occurrence wins, like TJSONObject.GetValue
    if not FSpans.ContainsKey(LPath) then
      FSpans.Add(LPath, LSpan);

    SkipWhitespace;
    if Current = ',' then
      Advance
    else
    begin
      if Current = '}' then
        Advance;
      Exit;
    end;
  end;
end;

procedure TglTFSourceMap.ParseArray(const APath: string);
var
  LIndex: Integer;
begin
  Advance; // [
  SkipWhitespace;
  if Current = ']' then
  begin
    Advance;
    Exit;
  end;

  LIndex := 0;
  while not AtEnd do
  begin
    ParseValue(Format('%s[%d]', [APath, LIndex]), True);
    Inc(LIndex);

    SkipWhitespace;
    if Current = ',' then
      Advance
    else
    begin
      if Current = ']' then
        Advance;
      Exit;
    end;
  end;
end;

class function TglTFSourceMap.MemberPath(const AParent, AName: string): string;
begin
  // Same rule as TglTFProperty.ChildPath
  if AParent = '' then
    Result := AName
  else
    Result := AParent + '.' + AName;
end;

class function TglTFSourceMap.ParentPath(const APath: string): string;
var
  I: Integer;
begin
  // "a.b[2]" -> "a.b" ; "a.b" -> "a" ; "a" -> ""
  for I := Length(APath) downto 1 do
    if (APath[I] = '.') or (APath[I] = '[') then
      Exit(Copy(APath, 1, I - 1));
  Result := '';
end;

function TglTFSourceMap.TryFind(const AJSONPath: string; out ASpan: TglTFSourceSpan): Boolean;
var
  LPath: string;
begin
  LPath := AJSONPath;
  while True do
  begin
    if FSpans.TryGetValue(LPath, ASpan) then
      Exit(True);
    if LPath = '' then
      Exit(False);
    LPath := ParentPath(LPath);
  end;
end;

end.
