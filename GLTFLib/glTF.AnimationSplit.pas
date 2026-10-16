//** @abstract(Splits one long animation into several, by frame ranges.)
//**
//** Animation files often hold a single long animation, typically called "Take001", that is
//** really a series of separate moves played one after the other. @link(TglTFAnimationSplitter)
//** cuts such an animation into named animations, one per frame range, and replaces it with
//** them. Gaps between the ranges, and before the first or after the last, are simply left
//** out.
//**
//** glTF stores times in seconds and has no frame rate, so the frame rate is detected from
//** the spacing of the key frames, typically 30 or 24 frames per second, and can be
//** overridden. Frame 0 is time 0 and the last frame is the frame rate times the length of
//** the animation in seconds.
//**
//** For each range, every channel gets the key frames inside the range, plus a key frame at
//** each end of the range computed from the animation itself: linear interpolation, with
//** spherical interpolation for rotations, the previous value for STEP, and the curve itself
//** for CUBICSPLINE, so each part plays exactly as that stretch of the original did. Times
//** start again at 0 in every new animation. The new key frames are written as floats,
//** whatever the original component type.
//**
//** @preformatted(
//** Take001  |--walk--|   |---run---|--jump--|      |
//**          0       90  120       300      390    450   frames
//** becomes  walk 0-90, run 120-300, jump 300-390
//** )
unit glTF.AnimationSplit;

{
  Splits one long animation into several, by frame ranges.

  Animation files often hold a single long animation, typically called
  "Take001", that is really a series of separate moves played one after the
  other. TglTFAnimationSplitter cuts such an animation into named animations,
  one per frame range, and replaces it with them. Gaps between the ranges, and
  before the first or after the last, are simply left out.

  glTF stores times in seconds and has no frame rate, so the frame rate is
  detected from the spacing of the key frames, typically 30 or 24 frames per
  second, and can be overridden. Frame 0 is time 0 and the last frame is the
  frame rate times the length of the animation in seconds.

  For each range, every channel gets the key frames inside the range, plus a
  key frame at each end of the range computed from the animation itself:
  linear interpolation, with spherical interpolation for rotations, the
  previous value for STEP, and the curve itself for CUBICSPLINE, so each part
  plays exactly as that stretch of the original did. Times start again at 0 in
  every new animation. The new key frames are written as floats, whatever the
  original component type.

    Take001  |--walk--|   |---run---|--jump--|      |
             0       90  120       300      390    450   frames
    becomes  walk 0-90, run 120-300, jump 300-390
}

interface

uses
  System.SysUtils, System.Classes, System.Math, System.JSON, System.Generics.Collections,

  glTF.Base,
  glTF.Classes;

type
  //** @abstract(One part of a long animation: a name and a frame range.)
  /// <summary>One part of a long animation: a name and a frame range.</summary>
  TglTFAnimationRange = record
    //** @abstract(Name of the new animation; required and unique.)
    /// <summary>Name of the new animation; required and unique.</summary>
    Name: string;

    //** @abstract(First frame, from 0.)
    /// <summary>First frame, from 0.</summary>
    StartFrame: Integer;

    //** @abstract(Last frame; after StartFrame and at most the last frame of the animation.)
    /// <summary>Last frame; after StartFrame and at most the last frame of the
    /// animation.</summary>
    EndFrame: Integer;

    //** @abstract(Optional notes; stored in the new animation's extras as "notes".)
    /// <summary>Optional notes; stored in the new animation's extras as "notes".</summary>
    Notes: string;

    //** @abstract(Returns a range.)
    //**
    //** @param(AName Name of the new animation.)
    //**
    //** @param(AStartFrame First frame.)
    //**
    //** @param(AEndFrame Last frame.)
    //**
    //** @param(ANotes Optional notes.)
    //**
    //** @returns(The range.)
    /// <summary>Returns a range.</summary>
    /// <param name="AName">Name of the new animation.</param>
    /// <param name="AStartFrame">First frame.</param>
    /// <param name="AEndFrame">Last frame.</param>
    /// <param name="ANotes">Optional notes.</param>
    /// <returns>The range.</returns>
    class function Create(const AName: string; AStartFrame, AEndFrame: Integer;
      const ANotes: string = ''): TglTFAnimationRange; static;
  end;

  //** @abstract(The parts a long animation is split into, in the order they are to appear.)
  /// <summary>The parts a long animation is split into, in the order they are to
  /// appear.</summary>
  TglTFAnimationRanges = TArray<TglTFAnimationRange>;

  //** @abstract(What @link(TglTFAnimationSplitter.ParseRangeList) found in a text.)
  /// <summary>What <see cref="TglTFAnimationSplitter.ParseRangeList"/> found in a
  /// text.</summary>
  TglTFRangeList = record
    //** @abstract(The ranges, in the order of the lines.)
    /// <summary>The ranges, in the order of the lines.</summary>
    Ranges: TglTFAnimationRanges;

    //** @abstract(Line number, from 1, of the first range; 0 when none was found.)
    /// <summary>Line number, from 1, of the first range; 0 when none was found.</summary>
    FirstLine: Integer;

    //** @abstract(Line number, from 1, of the last range; 0 when none was found.)
    /// <summary>Line number, from 1, of the last range; 0 when none was found.</summary>
    LastLine: Integer;

    //** @abstract(Line numbers between the first and the last range that hold text but no
    //** range; they were skipped.)
    /// <summary>Line numbers between the first and the last range that hold text but no
    /// range; they were skipped.</summary>
    SkippedLines: TArray<Integer>;
  end;

  //** @abstract(Finds long animations and splits them by frame ranges.)
  //**
  //** All methods are class methods. They work on a TglTF whose buffer data is loaded.
  //**
  //** @longCode(#
  //** Index := TglTFAnimationSplitter.FindLongAnimation(Doc.Root);
  //** if Index >= 0 then
  //** begin
  //**   Fps := TglTFAnimationSplitter.DetectFrameRate(Doc.Root, Doc.Root.Animations[Index]);
  //**   TglTFAnimationSplitter.Split(Doc.Root, Index, Fps,
  //**     [TglTFAnimationRange.Create('walk', 0, 90),
  //**      TglTFAnimationRange.Create('run', 120, 300)], nil);
  //** end;
  //** #)
  /// <summary>Finds long animations and splits them by frame ranges.</summary>
  /// <remarks>All methods are class methods. They work on a TglTF whose buffer data is
  /// loaded.</remarks>
  /// <example><code>
  /// Index := TglTFAnimationSplitter.FindLongAnimation(Doc.Root);
  /// if Index >= 0 then
  /// begin
  ///   Fps := TglTFAnimationSplitter.DetectFrameRate(Doc.Root, Doc.Root.Animations[Index]);
  ///   TglTFAnimationSplitter.Split(Doc.Root, Index, Fps,
  ///     [TglTFAnimationRange.Create('walk', 0, 90),
  ///      TglTFAnimationRange.Create('run', 120, 300)], nil);
  /// end;
  /// </code></example>
  TglTFAnimationSplitter = class sealed
  public
    //** @abstract(Length in seconds above which an animation is likely to be several joined
    //** together.)
    /// <summary>Length in seconds above which an animation is likely to be several joined
    /// together.</summary>
    const LongAnimationSeconds = 10.0;

    //** @abstract(Reads an accessor's elements as floats.)
    //**
    //** Handles every component type, normalized integers @(converted to -1..1 or 0..1@),
    //** byteStride and sparse accessors. An accessor without a bufferView starts as zeros.
    //**
    //** @param(ARoot The tree.)
    //**
    //** @param(AIndex Index in @code(ARoot.Accessors).)
    //**
    //** @returns(Count times the number of components floats, element after element.)
    //**
    //** @raises(EglTFError The accessor's data is missing or lies outside its buffer.)
    /// <summary>Reads an accessor's elements as floats.</summary>
    /// <param name="ARoot">The tree.</param>
    /// <param name="AIndex">Index in <c>ARoot.Accessors</c>.</param>
    /// <returns>Count times the number of components floats, element after
    /// element.</returns>
    /// <exception cref="EglTFError">The accessor's data is missing or lies outside its
    /// buffer.</exception>
    /// <remarks>Handles every component type, normalized integers (converted to -1..1 or
    /// 0..1), byteStride and sparse accessors. An accessor without a bufferView starts as
    /// zeros.</remarks>
    class function ReadAccessor(ARoot: TglTF; AIndex: Integer): TArray<Single>; static;

    //** @abstract(Returns the length of an animation in seconds.)
    //**
    //** @param(ARoot The tree.)
    //**
    //** @param(AAnimation The animation.)
    //**
    //** @returns(The time of its last key frame: the largest "max" of its sampler inputs, or
    //** the largest time in their data when "max" is missing; 0 when unknown.)
    /// <summary>Returns the length of an animation in seconds.</summary>
    /// <param name="ARoot">The tree.</param>
    /// <param name="AAnimation">The animation.</param>
    /// <returns>The time of its last key frame: the largest "max" of its sampler inputs, or the
    /// largest time in their data when "max" is missing; 0 when unknown.</returns>
    class function Duration(ARoot: TglTF; AAnimation: TglTFAnimation): Double; static;

    //** @abstract(Estimates the frame rate an animation was made at.)
    //**
    //** Uses the median gap between two key frames, over all samplers. A result within 1% of a
    //** usual rate @(12, 15, 23.976, 24, 25, 29.97, 30, 48, 50, 59.94, 60, 120@) is snapped to
    //** it; otherwise it is rounded to a whole number.
    //**
    //** @param(ARoot The tree.)
    //**
    //** @param(AAnimation The animation.)
    //**
    //** @returns(Frames per second; 30 when it cannot be told.)
    /// <summary>Estimates the frame rate an animation was made at.</summary>
    /// <param name="ARoot">The tree.</param>
    /// <param name="AAnimation">The animation.</param>
    /// <returns>Frames per second; 30 when it cannot be told.</returns>
    /// <remarks>Uses the median gap between two key frames, over all samplers. A result within
    /// 1% of a usual rate (12, 15, 23.976, 24, 25, 29.97, 30, 48, 50, 59.94, 60, 120) is
    /// snapped to it; otherwise it is rounded to a whole number.</remarks>
    class function DetectFrameRate(ARoot: TglTF; AAnimation: TglTFAnimation): Double; static;

    //** @abstract(Returns the last frame of an animation.)
    //**
    //** @param(ADuration Length in seconds.)
    //**
    //** @param(AFrameRate Frames per second.)
    //**
    //** @returns(ADuration times AFrameRate, rounded; frames run from 0 to this.)
    /// <summary>Returns the last frame of an animation.</summary>
    /// <param name="ADuration">Length in seconds.</param>
    /// <param name="AFrameRate">Frames per second.</param>
    /// <returns>ADuration times AFrameRate, rounded; frames run from 0 to this.</returns>
    class function LastFrame(ADuration, AFrameRate: Double): Integer; static;

    //** @abstract(Finds the longest animation that is likely to be several joined together.)
    //**
    //** @param(ARoot The tree.)
    //**
    //** @param(AMinSeconds Only animations longer than this count.)
    //**
    //** @returns(Index in @code(ARoot.Animations); -1 when no animation is that long.)
    /// <summary>Finds the longest animation that is likely to be several joined
    /// together.</summary>
    /// <param name="ARoot">The tree.</param>
    /// <param name="AMinSeconds">Only animations longer than this count.</param>
    /// <returns>Index in <c>ARoot.Animations</c>; -1 when no animation is that
    /// long.</returns>
    class function FindLongAnimation(ARoot: TglTF;
      AMinSeconds: Double = LongAnimationSeconds): Integer; static;

    //** @abstract(Checks the ranges an animation is to be split into.)
    //**
    //** Each name is required and must be unique, ignoring case, among the ranges and among
    //** the model's other animations. Frames must be from 0 to ALastFrame, and EndFrame must
    //** be after StartFrame. Gaps and overlaps between ranges are allowed.
    //**
    //** @param(ARoot The tree.)
    //**
    //** @param(AIndex Index in @code(ARoot.Animations) of the animation to split.)
    //**
    //** @param(ALastFrame The animation's last frame.)
    //**
    //** @param(ARanges The ranges.)
    //**
    //** @param(AProblems One entry per range: empty when it is fine, otherwise what is wrong.)
    //**
    //** @returns(True when there is at least one range and none has a problem.)
    /// <summary>Checks the ranges an animation is to be split into.</summary>
    /// <param name="ARoot">The tree.</param>
    /// <param name="AIndex">Index in <c>ARoot.Animations</c> of the animation to
    /// split.</param>
    /// <param name="ALastFrame">The animation's last frame.</param>
    /// <param name="ARanges">The ranges.</param>
    /// <param name="AProblems">One entry per range: empty when it is fine, otherwise what is
    /// wrong.</param>
    /// <returns>True when there is at least one range and none has a problem.</returns>
    /// <remarks>Each name is required and must be unique, ignoring case, among the ranges and
    /// among the model's other animations. Frames must be from 0 to ALastFrame, and EndFrame
    /// must be after StartFrame. Gaps and overlaps between ranges are allowed.</remarks>
    class function ValidateRanges(ARoot: TglTF; AIndex, ALastFrame: Integer;
      const ARanges: TglTFAnimationRanges; out AProblems: TArray<string>): Boolean; static;

    //** @abstract(Reads animation ranges from a text, such as the list that comes with an
    //** animation file.)
    //**
    //** A line holds a range when it has two whole numbers, the start frame and then the end
    //** frame, separated only by spaces, tabs and signs such as "-", "~", ":" or "..", or by
    //** the word "to"; a "-" is never a minus sign, as frames are never negative. The name is
    //** the text before the numbers or, when there is none, the text after them. It ends at a
    //** tab, two spaces, "@(", "[", "#", ";" or "//", so notes after it are ignored, and must
    //** contain a letter. Quotes are removed, and so are a leading list number such as "3."
    //** and surrounding signs such as ":" or ",". Digits inside a name, as in walk_01, are part
    //** of it.
    //**
    //** Lines before the first range and after the last, such as a title or a note, are
    //** ignored. Lines between them that hold text but no range are skipped and listed.
    //** The ranges are not checked; see ValidateRanges.
    //**
    //** @param(AText The text, with any line ends.)
    //**
    //** @param(AList What was found.)
    //**
    //** @returns(True when at least one range was found.)
    //**
    //** @longCode(#
    //** 10 - 40  walk_01           -> walk_01, 10, 40
    //** Look Around    415 - 555  -> Look Around, 415, 555
    //** "Run" 625-685 (3 loops)   -> Run, 625, 685
    //** #)
    /// <summary>Reads animation ranges from a text, such as the list that comes with an
    /// animation file.</summary>
    /// <param name="AText">The text, with any line ends.</param>
    /// <param name="AList">What was found.</param>
    /// <returns>True when at least one range was found.</returns>
    /// <remarks>
    /// <para>A line holds a range when it has two whole numbers, the start frame and then the
    /// end frame, separated only by spaces, tabs and signs such as "-", "~", ":" or "..", or
    /// by the word "to"; a "-" is never a minus sign, as frames are never negative. The name is
    /// the text before the numbers or, when there is none, the text after them. It ends at a
    /// tab, two spaces, "(", "[", "#", ";" or "//", so notes after it are ignored, and must
    /// contain a letter. Quotes are removed, and so are a leading list number such as "3." and
    /// surrounding signs such as ":" or ",". Digits inside a name, as in walk_01, are part of
    /// it.</para>
    /// <para>Lines before the first range and after the last, such as a title or a note, are
    /// ignored. Lines between them that hold text but no range are skipped and listed. The
    /// ranges are not checked; see ValidateRanges.</para>
    /// </remarks>
    /// <example><code>
    /// 10 - 40  walk_01           -> walk_01, 10, 40
    /// Look Around    415 - 555  -> Look Around, 415, 555
    /// "Run" 625-685 (3 loops)   -> Run, 625, 685
    /// </code></example>
    class function ParseRangeList(const AText: string; out AList: TglTFRangeList): Boolean;
      static;

    //** @abstract(Replaces an animation with one new animation per range.)
    //**
    //** The new animations take the old one's place in the list, in the order of ARanges,
    //** with its Origin and with ExportOnSave True. Their key frame data is appended to the
    //** model's buffer in one go, and the data only the old animation used is removed. The
    //** ranges are checked first; nothing changes when they are invalid or the data cannot be
    //** read.
    //**
    //** @param(ARoot The tree to change.)
    //**
    //** @param(AIndex Index in @code(ARoot.Animations) of the animation to split.)
    //**
    //** @param(AFrameRate Frames per second used to turn frames into seconds.)
    //**
    //** @param(ARanges The parts, see ValidateRanges.)
    //**
    //** @param(AWarnings Receives a line for each clean-up step skipped; may be nil.)
    //**
    //** @returns(The number of animations created.)
    //**
    //** @raises(EglTFError The ranges are invalid, or the animation's data cannot be read.)
    /// <summary>Replaces an animation with one new animation per range.</summary>
    /// <param name="ARoot">The tree to change.</param>
    /// <param name="AIndex">Index in <c>ARoot.Animations</c> of the animation to
    /// split.</param>
    /// <param name="AFrameRate">Frames per second used to turn frames into seconds.</param>
    /// <param name="ARanges">The parts, see ValidateRanges.</param>
    /// <param name="AWarnings">Receives a line for each clean-up step skipped; may be
    /// nil.</param>
    /// <returns>The number of animations created.</returns>
    /// <exception cref="EglTFError">The ranges are invalid, or the animation's data cannot be
    /// read.</exception>
    /// <remarks>The new animations take the old one's place in the list, in the order of
    /// ARanges, with its Origin and with ExportOnSave True. Their key frame data is appended
    /// to the model's buffer in one go, and the data only the old animation used is removed.
    /// The ranges are checked first; nothing changes when they are invalid or the data cannot
    /// be read.</remarks>
    class function Split(ARoot: TglTF; AIndex: Integer; AFrameRate: Double;
      const ARanges: TglTFAnimationRanges; AWarnings: TStrings): Integer; static;
  end;

implementation

uses
  System.RegularExpressions, System.Character,
  glTF.Edit;

const
  // Key frames this close to a range's end are taken as being on it
  TIME_EPSILON = 1e-4;

type
  // One sampler of the animation being split, read into floats
  TSamplerData = record
    Used: Boolean;
    Times: TArray<Single>;
    Values: TArray<Single>;
    Width: Integer;        // floats per value (components x morph targets)
    Components: Integer;   // floats per element of the output accessor
    Cubic: Boolean;        // values hold in-tangent, value, out-tangent per key
    Step: Boolean;
    Rotation: Boolean;     // a quaternion: spherical interpolation
    OutputType: string;    // accessor type of the output, e.g. VEC4
    Interpolation: string;
  end;

{ TglTFAnimationRange }

class function TglTFAnimationRange.Create(const AName: string; AStartFrame, AEndFrame: Integer;
  const ANotes: string): TglTFAnimationRange;
begin
  Result.Name := AName;
  Result.StartFrame := AStartFrame;
  Result.EndFrame := AEndFrame;
  Result.Notes := ANotes;
end;

{ Helpers }

function ReadComponent(const AData: TBytes; AOffset: Int64; AComponentType: Integer;
  ANormalized: Boolean): Single;
var
  LShortInt: ShortInt;
  LSmallInt: SmallInt;
  LWord: Word;
  LCardinal: Cardinal;
begin
  case AComponentType of
    GLTF_COMPONENT_BYTE:
    begin
      LShortInt := ShortInt(AData[AOffset]);
      if ANormalized then
        Result := Max(LShortInt / 127, -1)
      else
        Result := LShortInt;
    end;
    GLTF_COMPONENT_UNSIGNED_BYTE:
      if ANormalized then
        Result := AData[AOffset] / 255
      else
        Result := AData[AOffset];
    GLTF_COMPONENT_SHORT:
    begin
      Move(AData[AOffset], LSmallInt, 2);
      if ANormalized then
        Result := Max(LSmallInt / 32767, -1)
      else
        Result := LSmallInt;
    end;
    GLTF_COMPONENT_UNSIGNED_SHORT:
    begin
      Move(AData[AOffset], LWord, 2);
      if ANormalized then
        Result := LWord / 65535
      else
        Result := LWord;
    end;
    GLTF_COMPONENT_UNSIGNED_INT:
    begin
      Move(AData[AOffset], LCardinal, 4);
      Result := LCardinal;
    end;
    GLTF_COMPONENT_FLOAT:
      Move(AData[AOffset], Result, 4);
  else
    raise EglTFError.CreateFmt('Unknown componentType %d', [AComponentType]);
  end;
end;

function ComponentSize(AComponentType: Integer): Integer;
begin
  case AComponentType of
    GLTF_COMPONENT_BYTE, GLTF_COMPONENT_UNSIGNED_BYTE: Result := 1;
    GLTF_COMPONENT_SHORT, GLTF_COMPONENT_UNSIGNED_SHORT: Result := 2;
  else
    Result := 4;
  end;
end;

// The bytes of a bufferView's buffer, checked to hold AEnd bytes
function ViewData(ARoot: TglTF; AView: Integer; AEnd: Int64): TBytes;
var
  LView: TglTFBufferView;
begin
  if (AView < 0) or (AView >= ARoot.BufferViews.Count) then
    raise EglTFError.CreateFmt('bufferView %d does not exist', [AView]);
  LView := ARoot.BufferViews[AView];
  if (LView.Buffer < 0) or (LView.Buffer >= ARoot.Buffers.Count) or
     (ARoot.Buffers[LView.Buffer].Data = nil) then
    raise EglTFError.CreateFmt('The data of bufferView %d is not available', [AView]);
  Result := ARoot.Buffers[LView.Buffer].Data;
  if AEnd > Length(Result) then
    raise EglTFError.CreateFmt('bufferView %d lies outside its buffer', [AView]);
end;

function CloneChannel(AChannel: TglTFAnimationChannel): TglTFAnimationChannel;
var
  LJSON: TJSONObject;
begin
  LJSON := AChannel.SaveToJSON;
  try
    Result := TglTFAnimationChannel.Create;
    try
      Result.LoadFromJSON(LJSON, '');
    except
      Result.Free;
      raise;
    end;
  finally
    LJSON.Free;
  end;
end;

// Spherical interpolation of two quaternions, along the shorter arc
procedure Slerp(const A, B: TArray<Single>; AOffsetA, AOffsetB: Integer; S: Double;
  var AOut: TArray<Single>; AOutOffset: Integer);
var
  LDot, LTheta, LSin, LWa, LWb, LLength: Double;
  LB: array[0..3] of Double;
  I: Integer;
begin
  LDot := 0;
  for I := 0 to 3 do
  begin
    LB[I] := B[AOffsetB + I];
    LDot := LDot + A[AOffsetA + I] * LB[I];
  end;
  if LDot < 0 then
  begin
    for I := 0 to 3 do
      LB[I] := -LB[I];
    LDot := -LDot;
  end;
  if LDot > 0.9995 then
  begin
    LWa := 1 - S;
    LWb := S;
  end
  else
  begin
    LTheta := ArcCos(Min(LDot, 1));
    LSin := Sin(LTheta);
    LWa := Sin((1 - S) * LTheta) / LSin;
    LWb := Sin(S * LTheta) / LSin;
  end;
  LLength := 0;
  for I := 0 to 3 do
  begin
    AOut[AOutOffset + I] := LWa * A[AOffsetA + I] + LWb * LB[I];
    LLength := LLength + Sqr(AOut[AOutOffset + I]);
  end;
  LLength := Sqrt(LLength);
  if LLength > 0 then
    for I := 0 to 3 do
      AOut[AOutOffset + I] := AOut[AOutOffset + I] / LLength;
end;

// The key (or the segment) a time falls in: K with Times[K] <= T < Times[K + 1]
function FindKey(const ATimes: TArray<Single>; T: Double): Integer;
var
  L, H, M: Integer;
begin
  L := 0;
  H := High(ATimes);
  while L < H do
  begin
    M := (L + H + 1) div 2;
    if ATimes[M] <= T then
      L := M
    else
      H := M - 1;
  end;
  Result := L;
end;

// Appends to AOut the key at time T computed from the sampler: for a cubic
// spline also its in- and out-tangents (the slope there, per second)
procedure AppendEvaluated(const ASampler: TSamplerData; T: Double; var AOut: TArray<Single>);
var
  LKeys, K, I, W, LStart: Integer;
  T0, T1, TD, S, S2, S3: Double;
  V0, V1, B0, A1: Double;
begin
  W := ASampler.Width;
  LKeys := Length(ASampler.Times);
  LStart := Length(AOut);
  if ASampler.Cubic then
    SetLength(AOut, LStart + 3 * W)
  else
    SetLength(AOut, LStart + W);

  // Before the first or after the last key: that key's value, held
  if (T <= ASampler.Times[0]) or (T >= ASampler.Times[LKeys - 1]) or (LKeys = 1) then
  begin
    if T <= ASampler.Times[0] then
      K := 0
    else
      K := LKeys - 1;
    if ASampler.Cubic then
      for I := 0 to W - 1 do
      begin
        AOut[LStart + I] := 0;
        AOut[LStart + W + I] := ASampler.Values[(3 * K + 1) * W + I];
        AOut[LStart + 2 * W + I] := 0;
      end
    else
      for I := 0 to W - 1 do
        AOut[LStart + I] := ASampler.Values[K * W + I];
    Exit;
  end;

  K := FindKey(ASampler.Times, T);
  T0 := ASampler.Times[K];
  T1 := ASampler.Times[K + 1];
  TD := T1 - T0;
  if TD <= 0 then
    S := 0
  else
    S := (T - T0) / TD;

  if ASampler.Step then
    for I := 0 to W - 1 do
      AOut[LStart + I] := ASampler.Values[K * W + I]
  else if ASampler.Cubic then
  begin
    // Hermite curve of the segment; tangents in glTF are per second
    S2 := S * S;
    S3 := S2 * S;
    for I := 0 to W - 1 do
    begin
      V0 := ASampler.Values[(3 * K + 1) * W + I];
      B0 := ASampler.Values[(3 * K + 2) * W + I];
      A1 := ASampler.Values[(3 * (K + 1)) * W + I];
      V1 := ASampler.Values[(3 * (K + 1) + 1) * W + I];
      AOut[LStart + W + I] := (2 * S3 - 3 * S2 + 1) * V0 + (S3 - 2 * S2 + S) * TD * B0 +
        (-2 * S3 + 3 * S2) * V1 + (S3 - S2) * TD * A1;
      // The slope at T, the same coming in and going out
      AOut[LStart + I] := ((6 * S2 - 6 * S) * V0 + (3 * S2 - 4 * S + 1) * TD * B0 +
        (-6 * S2 + 6 * S) * V1 + (3 * S2 - 2 * S) * TD * A1) / Max(TD, 1e-9);
      AOut[LStart + 2 * W + I] := AOut[LStart + I];
    end;
  end
  else if ASampler.Rotation and (W = 4) then
    Slerp(ASampler.Values, ASampler.Values, K * W, (K + 1) * W, S, AOut, LStart)
  else
    for I := 0 to W - 1 do
      AOut[LStart + I] := ASampler.Values[K * W + I] +
        S * (ASampler.Values[(K + 1) * W + I] - ASampler.Values[K * W + I]);
end;

// Appends key K of the sampler as it is
procedure AppendKey(const ASampler: TSamplerData; K: Integer; var AOut: TArray<Single>);
var
  LCount, LStart, I: Integer;
begin
  if ASampler.Cubic then
    LCount := 3 * ASampler.Width
  else
    LCount := ASampler.Width;
  LStart := Length(AOut);
  SetLength(AOut, LStart + LCount);
  for I := 0 to LCount - 1 do
    AOut[LStart + I] := ASampler.Values[K * LCount + I];
end;

// The part of a sampler from T0 to T1, with times starting at 0
procedure ClipSampler(const ASampler: TSamplerData; T0, T1: Double;
  out ATimes, AValues: TArray<Single>);
var
  K, LFirst, W, I: Integer;
  LStartDone: Boolean;
begin
  ATimes := nil;
  AValues := nil;

  // The start: an existing key on it, or one computed there
  LFirst := 0;
  LStartDone := False;
  for K := 0 to High(ASampler.Times) do
    if Abs(ASampler.Times[K] - T0) <= TIME_EPSILON then
    begin
      ATimes := [0];
      AppendKey(ASampler, K, AValues);
      LFirst := K + 1;
      LStartDone := True;
      Break;
    end
    else if ASampler.Times[K] > T0 then
    begin
      LFirst := K;
      Break;
    end
    else
      LFirst := K + 1;
  if not LStartDone then
  begin
    ATimes := [0];
    AppendEvaluated(ASampler, T0, AValues);
  end;

  // The keys inside
  K := LFirst;
  while (K <= High(ASampler.Times)) and (ASampler.Times[K] < T1 - TIME_EPSILON) do
  begin
    ATimes := ATimes + [ASampler.Times[K] - T0];
    AppendKey(ASampler, K, AValues);
    Inc(K);
  end;

  // The end: an existing key on it, or one computed there
  ATimes := ATimes + [T1 - T0];
  if (K <= High(ASampler.Times)) and (Abs(ASampler.Times[K] - T1) <= TIME_EPSILON) then
    AppendKey(ASampler, K, AValues)
  else
    AppendEvaluated(ASampler, T1, AValues);

  // Before its first key and after its last, the original holds still: the
  // clip's keys next to those stretches must not curve into them
  if ASampler.Cubic then
  begin
    W := ASampler.Width;
    if T0 < ASampler.Times[0] - TIME_EPSILON then
      for I := 0 to W - 1 do
        AValues[3 * W + I] := 0; // in-tangent of the second key
    if T1 > ASampler.Times[High(ASampler.Times)] + TIME_EPSILON then
      for I := 0 to W - 1 do
        AValues[Length(AValues) - 4 * W + I] := 0; // out-tangent of the key before last
  end;
end;

{ TglTFAnimationSplitter }

class function TglTFAnimationSplitter.ReadAccessor(ARoot: TglTF;
  AIndex: Integer): TArray<Single>;
var
  LAccessor: TglTFAccessor;
  LView: TglTFBufferView;
  LData: TBytes;
  LComponents, LSize, LStride, I, C, LIndex: Integer;
  LBase: Int64;
  LIndices, LValues: TArray<Single>;
begin
  if (AIndex < 0) or (AIndex >= ARoot.Accessors.Count) then
    raise EglTFError.CreateFmt('Accessor %d does not exist', [AIndex]);
  LAccessor := ARoot.Accessors[AIndex];
  LComponents := LAccessor.ComponentCount;
  LSize := ComponentSize(LAccessor.ComponentType);
  SetLength(Result, LAccessor.Count * LComponents);

  // 1. The dense data
  if LAccessor.BufferView <> GLTF_UNDEFINED_INDEX then
  begin
    LView := ARoot.BufferViews[LAccessor.BufferView];
    LStride := LView.ByteStride;
    if LStride <= 0 then
      LStride := LSize * LComponents;
    LBase := LView.ByteOffset + LAccessor.ByteOffset;
    if LAccessor.Count > 0 then
      LData := ViewData(ARoot, LAccessor.BufferView,
        LBase + Int64(LAccessor.Count - 1) * LStride + LSize * LComponents);
    for I := 0 to LAccessor.Count - 1 do
      for C := 0 to LComponents - 1 do
        Result[I * LComponents + C] := ReadComponent(LData,
          LBase + Int64(I) * LStride + C * LSize, LAccessor.ComponentType, LAccessor.Normalized);
  end;

  // 2. Sparse replacements
  if Assigned(LAccessor.Sparse) and (LAccessor.Sparse.Count > 0) then
  begin
    SetLength(LIndices, LAccessor.Sparse.Count);
    LSize := ComponentSize(LAccessor.Sparse.Indices.ComponentType);
    LBase := ARoot.BufferViews[LAccessor.Sparse.Indices.BufferView].ByteOffset +
      LAccessor.Sparse.Indices.ByteOffset;
    LData := ViewData(ARoot, LAccessor.Sparse.Indices.BufferView,
      LBase + Int64(LAccessor.Sparse.Count) * LSize);
    for I := 0 to LAccessor.Sparse.Count - 1 do
      LIndices[I] := ReadComponent(LData, LBase + Int64(I) * LSize,
        LAccessor.Sparse.Indices.ComponentType, False);

    SetLength(LValues, LAccessor.Sparse.Count * LComponents);
    LSize := ComponentSize(LAccessor.ComponentType);
    LBase := ARoot.BufferViews[LAccessor.Sparse.Values.BufferView].ByteOffset +
      LAccessor.Sparse.Values.ByteOffset;
    LData := ViewData(ARoot, LAccessor.Sparse.Values.BufferView,
      LBase + Int64(LAccessor.Sparse.Count) * LComponents * LSize);
    for I := 0 to LAccessor.Sparse.Count - 1 do
    begin
      LIndex := Round(LIndices[I]);
      if (LIndex < 0) or (LIndex >= LAccessor.Count) then
        Continue;
      for C := 0 to LComponents - 1 do
        Result[LIndex * LComponents + C] := ReadComponent(LData,
          LBase + (Int64(I) * LComponents + C) * LSize, LAccessor.ComponentType,
          LAccessor.Normalized);
    end;
  end;
end;

class function TglTFAnimationSplitter.Duration(ARoot: TglTF;
  AAnimation: TglTFAnimation): Double;
var
  LSampler: TglTFAnimationSampler;
  LAccessor: TglTFAccessor;
  LTimes: TArray<Single>;
  LTime: Single;
begin
  Result := 0;
  for LSampler in AAnimation.Samplers do
  begin
    if (LSampler.Input < 0) or (LSampler.Input >= ARoot.Accessors.Count) then
      Continue;
    LAccessor := ARoot.Accessors[LSampler.Input];
    if Length(LAccessor.Max) > 0 then
      Result := Max(Result, LAccessor.Max[0])
    else
      try
        LTimes := ReadAccessor(ARoot, LSampler.Input);
        for LTime in LTimes do
          Result := Max(Result, LTime);
      except
        on EglTFError do
          ; // data not available: this sampler does not count
      end;
  end;
end;

class function TglTFAnimationSplitter.DetectFrameRate(ARoot: TglTF;
  AAnimation: TglTFAnimation): Double;
const
  USUAL_RATES: array[0..11] of Double = (12, 15, 23.976, 24, 25, 29.97, 30, 48, 50, 59.94,
    60, 120);
var
  LSampler: TglTFAnimationSampler;
  LTimes: TArray<Single>;
  LGaps: TList<Double>;
  LGap, LRate: Double;
  I: Integer;
begin
  // The usual gap between key frames: the median, so a few odd gaps (a key
  // added between frames, rounding in the exporter) do not decide
  LGaps := TList<Double>.Create;
  try
    for LSampler in AAnimation.Samplers do
      try
        LTimes := ReadAccessor(ARoot, LSampler.Input);
        for I := 1 to High(LTimes) do
          if LTimes[I] - LTimes[I - 1] > 1e-5 then
            LGaps.Add(LTimes[I] - LTimes[I - 1]);
      except
        on EglTFError do
          ; // data not available: this sampler does not count
      end;
    if LGaps.Count = 0 then
      Exit(30);
    LGaps.Sort;
    LGap := LGaps[LGaps.Count div 2];
  finally
    LGaps.Free;
  end;
  LRate := 1 / LGap;
  for I := 0 to High(USUAL_RATES) do
    if Abs(LRate - USUAL_RATES[I]) <= USUAL_RATES[I] * 0.01 then
      Exit(USUAL_RATES[I]);
  Result := EnsureRange(Round(LRate), 1, 1000);
end;

class function TglTFAnimationSplitter.LastFrame(ADuration, AFrameRate: Double): Integer;
begin
  Result := Max(0, Round(ADuration * AFrameRate));
end;

class function TglTFAnimationSplitter.FindLongAnimation(ARoot: TglTF;
  AMinSeconds: Double): Integer;
var
  LLongest, LDuration: Double;
  I: Integer;
begin
  Result := -1;
  LLongest := AMinSeconds;
  for I := 0 to ARoot.Animations.Count - 1 do
  begin
    LDuration := Duration(ARoot, ARoot.Animations[I]);
    if LDuration > LLongest then
    begin
      LLongest := LDuration;
      Result := I;
    end;
  end;
end;

class function TglTFAnimationSplitter.ValidateRanges(ARoot: TglTF; AIndex, ALastFrame: Integer;
  const ARanges: TglTFAnimationRanges; out AProblems: TArray<string>): Boolean;
var
  LName: string;
  I, J: Integer;
begin
  SetLength(AProblems, Length(ARanges));
  Result := Length(ARanges) > 0;
  for I := 0 to High(ARanges) do
  begin
    LName := Trim(ARanges[I].Name);
    if LName = '' then
      AProblems[I] := 'the animation name is missing'
    else if (ARanges[I].StartFrame < 0) or (ARanges[I].StartFrame > ALastFrame) then
      AProblems[I] := Format('Start Frame must be from 0 to %d', [ALastFrame])
    else if (ARanges[I].EndFrame < 0) or (ARanges[I].EndFrame > ALastFrame) then
      AProblems[I] := Format('End Frame must be from 0 to %d', [ALastFrame])
    else if ARanges[I].EndFrame <= ARanges[I].StartFrame then
      AProblems[I] := 'End Frame must be after Start Frame'
    else
    begin
      for J := 0 to I - 1 do
        if TglTFEdit.SameName(ARanges[J].Name, LName) then
        begin
          AProblems[I] := Format('the name "%s" is already used in row %d', [LName, J + 1]);
          Break;
        end;
      if AProblems[I] = '' then
        for J := 0 to ARoot.Animations.Count - 1 do
          if (J <> AIndex) and TglTFEdit.SameName(ARoot.Animations[J].Name, LName) then
          begin
            AProblems[I] := Format('the model already has an animation called "%s"',
              [ARoot.Animations[J].Name]);
            Break;
          end;
    end;
    if AProblems[I] <> '' then
      Result := False;
  end;
end;

// The name in the text before or after a range: up to a tab, two spaces or
// the start of a note, without a list number or surrounding signs
function CleanRangeName(const AText: string): string;
var
  LMatch: TMatch;
begin
  Result := Trim(AText);
  Result := TRegEx.Replace(Result, '^\d+[.)]\s+', '');
  LMatch := TRegEx.Match(Result, '\t|\s{2,}|\(|\[|#|;|//');
  if LMatch.Success then
    Result := Copy(Result, 1, LMatch.Index - 1);
  Result := Trim(Result).Trim([' ', #9, ':', '-', '=', '|', '.', ',']);
end;

function HasLetter(const AText: string): Boolean;
var
  C: Char;
begin
  for C in AText do
    if C.IsLetter then
      Exit(True);
  Result := False;
end;

// One line as a range; False when it holds none
function ParseRangeLine(const ALine: string; out ARange: TglTFAnimationRange): Boolean;
const
  // Two whole numbers, not part of a word or a decimal, apart by up to 12
  // signs or spaces, or by "to"
  RANGE_PATTERN = '(?<![\w\-.])(\d+)(?:[^\w]{1,12}|[^\w]{0,6}to[^\w]{0,6})(\d+)(?![\w.])';
  QUOTES: array[0..6] of string = ('"', '''', '`', #$201C, #$201D, #$2018, #$2019);
var
  LLine, LBefore: string;
  LMatch: TMatch;
  I: Integer;
begin
  Result := False;
  LLine := ALine;
  for I := Low(QUOTES) to High(QUOTES) do
    LLine := LLine.Replace(QUOTES[I], '');

  LMatch := TRegEx.Match(LLine, RANGE_PATTERN, [roIgnoreCase]);
  if not LMatch.Success or not TryStrToInt(LMatch.Groups[1].Value, ARange.StartFrame) or
     not TryStrToInt(LMatch.Groups[2].Value, ARange.EndFrame) then
    Exit;

  LBefore := Copy(LLine, 1, LMatch.Index - 1);
  if HasLetter(LBefore) then
    ARange.Name := CleanRangeName(LBefore)
  else
    ARange.Name := CleanRangeName(Copy(LLine, LMatch.Index + LMatch.Length, MaxInt));
  ARange.Notes := '';
  Result := HasLetter(ARange.Name);
end;

class function TglTFAnimationSplitter.ParseRangeList(const AText: string;
  out AList: TglTFRangeList): Boolean;
var
  LLines: TArray<string>;
  LParsed: TArray<Boolean>;
  LRanges: TArray<TglTFAnimationRange>;
  LRange: TglTFAnimationRange;
  I: Integer;
begin
  AList.Ranges := nil;
  AList.FirstLine := 0;
  AList.LastLine := 0;
  AList.SkippedLines := nil;

  LLines := AText.Replace(#13#10, #10).Replace(#13, #10).Split([#10]);
  SetLength(LParsed, Length(LLines));
  SetLength(LRanges, Length(LLines));
  for I := 0 to High(LLines) do
    if ParseRangeLine(LLines[I], LRange) then
    begin
      LParsed[I] := True;
      LRanges[I] := LRange;
      if AList.FirstLine = 0 then
        AList.FirstLine := I + 1;
      AList.LastLine := I + 1;
    end;

  // The block from the first range to the last; text around it is ignored
  if AList.FirstLine > 0 then
    for I := AList.FirstLine - 1 to AList.LastLine - 1 do
      if LParsed[I] then
        AList.Ranges := AList.Ranges + [LRanges[I]]
      else if Trim(LLines[I]) <> '' then
        AList.SkippedLines := AList.SkippedLines + [I + 1];
  Result := AList.Ranges <> nil;
end;

class function TglTFAnimationSplitter.Split(ARoot: TglTF; AIndex: Integer; AFrameRate: Double;
  const ARanges: TglTFAnimationRanges; AWarnings: TStrings): Integer;
var
  LSource, LAnimation: TglTFAnimation;
  LSamplers: TArray<TSamplerData>;
  LSampler: TglTFAnimationSampler;
  LChannel, LNewChannel: TglTFAnimationChannel;
  LInput, LOutput: TglTFAccessor;
  LNewAnimations: TObjectList<TglTFAnimation>;
  LNewViews: TList<TglTFBufferView>;
  LNewAccessors: TList<TglTFAccessor>;
  LBlock: TBytesStream;
  LProblems: TArray<string>;
  LTimes, LValues: TArray<Single>;
  LMap: TArray<Integer>;
  LOldAccessors: TArray<Integer>;
  LBuffer, LKeys, LPerKey, I, S, R: Integer;
  LOffset: Int64;
  T0, T1: Double;
  LView: TglTFBufferView;
  LAccessor: TglTFAccessor;

  // A new bufferView and accessor for some floats, the bytes going into the
  // block; both are added to the model in step 3
  function AddFloats(const AFloats: TArray<Single>; ACount: Integer;
    const AType: string; AWithMinMax: Boolean): TglTFAccessor;
  var
    LNewView: TglTFBufferView;
  begin
    LNewView := TglTFBufferView.Create;
    LNewView.Buffer := LBuffer;
    LNewView.ByteOffset := LBlock.Size; // made absolute when the block is appended
    LNewView.ByteLength := Length(AFloats) * SizeOf(Single);
    LNewViews.Add(LNewView);
    if Length(AFloats) > 0 then
      LBlock.WriteBuffer(AFloats[0], Length(AFloats) * SizeOf(Single));

    Result := TglTFAccessor.Create;
    Result.BufferView := -1; // set once the views are added
    Result.ComponentType := GLTF_COMPONENT_FLOAT;
    Result.Count := ACount;
    Result.&Type := AType;
    if AWithMinMax then
    begin
      Result.Min := [AFloats[0]];
      Result.Max := [AFloats[High(AFloats)]];
    end;
    LNewAccessors.Add(Result);
  end;

begin
  if (AIndex < 0) or (AIndex >= ARoot.Animations.Count) then
    raise EglTFError.CreateFmt('Animation %d does not exist', [AIndex]);
  if AFrameRate <= 0 then
    raise EglTFError.Create('The frame rate must be above 0');
  LSource := ARoot.Animations[AIndex];
  if not ValidateRanges(ARoot, AIndex,
     LastFrame(Duration(ARoot, LSource), AFrameRate), ARanges, LProblems) then
    raise EglTFError.Create('The animation ranges are not valid');

  // 1. Every sampler a channel uses, read before anything changes
  SetLength(LSamplers, LSource.Samplers.Count);
  for LChannel in LSource.Channels do
    if (LChannel.Sampler >= 0) and (LChannel.Sampler < Length(LSamplers)) then
    begin
      LSamplers[LChannel.Sampler].Used := True;
      if LChannel.Target.AnimationPath = apRotation then
        LSamplers[LChannel.Sampler].Rotation := True;
    end;
  for S := 0 to High(LSamplers) do
  begin
    if not LSamplers[S].Used then
      Continue;
    LSampler := LSource.Samplers[S];
    LInput := ARoot.Accessors[LSampler.Input];
    LOutput := ARoot.Accessors[LSampler.Output];
    LSamplers[S].Times := ReadAccessor(ARoot, LSampler.Input);
    LSamplers[S].Values := ReadAccessor(ARoot, LSampler.Output);
    LSamplers[S].Interpolation := LSampler.Interpolation;
    LSamplers[S].Cubic := LSampler.InterpolationKind = ipCubicSpline;
    LSamplers[S].Step := LSampler.InterpolationKind = ipStep;
    LSamplers[S].OutputType := LOutput.&Type;
    LKeys := LInput.Count;
    if LKeys = 0 then
      raise EglTFError.CreateFmt('Sampler %d has no key frames', [S]);
    // Elements per key: 1, or the number of morph targets for weights
    LPerKey := LOutput.Count div LKeys;
    if LSamplers[S].Cubic then
      LPerKey := LPerKey div 3;
    if (LPerKey < 1) or (LOutput.Count mod LKeys <> 0) then
      raise EglTFError.CreateFmt('Sampler %d: output count %d does not fit %d key frames',
        [S, LOutput.Count, LKeys]);
    LSamplers[S].Components := LOutput.ComponentCount;
    LSamplers[S].Width := LPerKey * LOutput.ComponentCount;
  end;
  LKeys := 0;
  for S := 0 to High(LSamplers) do
    if LSamplers[S].Used then
      Inc(LKeys);
  if LKeys = 0 then
    raise EglTFError.Create('The animation has no channels to split');

  // 2. The new animations, their key frames collected in one block of bytes
  LBuffer := TglTFEdit.DataBuffer(ARoot);
  LNewAnimations := TObjectList<TglTFAnimation>.Create(False);
  LNewViews := TList<TglTFBufferView>.Create;
  LNewAccessors := TList<TglTFAccessor>.Create;
  LBlock := TBytesStream.Create;
  try
    try
      for R := 0 to High(ARanges) do
      begin
        T0 := ARanges[R].StartFrame / AFrameRate;
        T1 := ARanges[R].EndFrame / AFrameRate;
        LAnimation := TglTFAnimation.Create;
        LNewAnimations.Add(LAnimation);
        LAnimation.Name := Trim(ARanges[R].Name);
        LAnimation.Origin := LSource.Origin;
        LAnimation.ExportOnSave := True;
        if Trim(ARanges[R].Notes) <> '' then
          LAnimation.SetExtra('notes', TJSONString.Create(Trim(ARanges[R].Notes)));

        // Samplers: one per sampler used, in the original order
        SetLength(LMap, Length(LSamplers));
        for S := 0 to High(LSamplers) do
        begin
          LMap[S] := -1;
          if not LSamplers[S].Used then
            Continue;
          ClipSampler(LSamplers[S], T0, T1, LTimes, LValues);
          LSampler := TglTFAnimationSampler.Create;
          LSampler.Interpolation := LSamplers[S].Interpolation;
          // Accessor indices are set in step 3; keep the objects for now
          LSampler.Input := LNewAccessors.Count;
          AddFloats(LTimes, Length(LTimes), 'SCALAR', True);
          LSampler.Output := LNewAccessors.Count;
          AddFloats(LValues, Length(LValues) div LSamplers[S].Components,
            LSamplers[S].OutputType, False);
          LAnimation.Samplers.Add(LSampler);
          LMap[S] := LAnimation.Samplers.Count - 1;
        end;

        // Channels: the same targets, on the new samplers
        for LChannel in LSource.Channels do
          if (LChannel.Sampler >= 0) and (LChannel.Sampler < Length(LMap)) and
             (LMap[LChannel.Sampler] >= 0) then
          begin
            LNewChannel := CloneChannel(LChannel);
            LNewChannel.Sampler := LMap[LChannel.Sampler];
            LAnimation.Channels.Add(LNewChannel);
          end;
      end;
    except
      for LAnimation in LNewAnimations do
        LAnimation.Free;
      for LView in LNewViews do
        LView.Free;
      for LAccessor in LNewAccessors do
        LAccessor.Free;
      raise;
    end;

    // 3. Into the model: the bytes in one go, then the views, the accessors
    //    and the animations in the old one's place
    LOffset := TglTFEdit.AppendBufferData(ARoot, LBuffer, Copy(LBlock.Bytes, 0, LBlock.Size));
    for LView in LNewViews do
    begin
      LView.ByteOffset := LView.ByteOffset + LOffset;
      ARoot.BufferViews.Add(LView);
    end;
    for I := 0 to LNewAccessors.Count - 1 do
    begin
      LNewAccessors[I].BufferView := ARoot.BufferViews.Count - LNewViews.Count + I;
      ARoot.Accessors.Add(LNewAccessors[I]);
    end;
    // The samplers held positions in LNewAccessors: make them model indices
    for LAnimation in LNewAnimations do
      for LSampler in LAnimation.Samplers do
      begin
        LSampler.Input := ARoot.Accessors.Count - LNewAccessors.Count + LSampler.Input;
        LSampler.Output := ARoot.Accessors.Count - LNewAccessors.Count + LSampler.Output;
      end;

    LOldAccessors := TglTFEdit.AnimationAccessors(LSource);
    ARoot.Animations.Delete(AIndex);
    for I := 0 to LNewAnimations.Count - 1 do
      ARoot.Animations.Insert(AIndex + I, LNewAnimations[I]);
    Result := LNewAnimations.Count;
    TglTFEdit.DeleteUnusedData(ARoot, LOldAccessors, AWarnings);
  finally
    LBlock.Free;
    LNewAccessors.Free;
    LNewViews.Free;
    LNewAnimations.Free;
  end;
end;

end.
