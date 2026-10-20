//** @abstract(Removes EXIF data from JPEG, PNG and WebP images, leaving the picture itself
//** untouched.)
//**
//** EXIF data can hold the camera, the date, the place a photo was taken and a thumbnail;
//** glTF viewers ignore it. @link(TglTFExif.Strip) removes it without decoding the picture:
//**
//** @unorderedList(
//**   @item(JPEG: the APP1 segments that start with "Exif".)
//**   @item(PNG: the eXIf chunk, and the tEXt, zTXt and iTXt chunks with the keywords "Raw
//**     profile type exif" and "Raw profile type APP1", where some tools keep EXIF.)
//**   @item(WebP: the EXIF chunk; the extended header's EXIF flag is cleared and the file size
//**     corrected.)
//** )
//**
//** Everything else is copied byte for byte, so the image looks exactly the same. Other
//** metadata, such as XMP and colour profiles, is kept. Images in other formats, such as KTX2,
//** and images whose structure cannot be followed are returned unchanged.
unit glTF.Exif;

{
  Removes EXIF data from JPEG, PNG and WebP images, leaving the picture
  itself untouched.

  EXIF data can hold the camera, the date, the place a photo was taken and a
  thumbnail; glTF viewers ignore it. TglTFExif.Strip removes it without
  decoding the picture:

    JPEG: the APP1 segments that start with "Exif".
    PNG:  the eXIf chunk, and the tEXt, zTXt and iTXt chunks with the
          keywords "Raw profile type exif" and "Raw profile type APP1",
          where some tools keep EXIF.
    WebP: the EXIF chunk; the extended header's EXIF flag is cleared and the
          file size corrected.

  Everything else is copied byte for byte, so the image looks exactly the
  same. Other metadata, such as XMP and colour profiles, is kept. Images in
  other formats, such as KTX2, and images whose structure cannot be followed
  are returned unchanged.
}

interface

uses
  System.SysUtils, System.Classes;

type
  //** @abstract(Finds and removes EXIF data in image files held in memory.)
  //**
  //** All methods are class methods and may be called from any thread.
  /// <summary>Finds and removes EXIF data in image files held in memory.</summary>
  /// <remarks>All methods are class methods and may be called from any thread.</remarks>
  TglTFExif = class sealed
  public
    //** @abstract(Returns an image without its EXIF data.)
    //**
    //** @param(AData The image file: JPEG, PNG or WebP; anything else is left alone.)
    //**
    //** @param(AStripped The image without EXIF data; AData itself when there was none.)
    //**
    //** @returns(True when EXIF data was found and removed.)
    /// <summary>Returns an image without its EXIF data.</summary>
    /// <param name="AData">The image file: JPEG, PNG or WebP; anything else is left
    /// alone.</param>
    /// <param name="AStripped">The image without EXIF data; AData itself when there was
    /// none.</param>
    /// <returns>True when EXIF data was found and removed.</returns>
    class function Strip(const AData: TBytes; out AStripped: TBytes): Boolean; static;

    //** @abstract(Tells whether an image holds EXIF data that Strip would remove.)
    //**
    //** @param(AData The image file.)
    //**
    //** @returns(True when it does.)
    /// <summary>Tells whether an image holds EXIF data that Strip would remove.</summary>
    /// <param name="AData">The image file.</param>
    /// <returns>True when it does.</returns>
    class function HasExif(const AData: TBytes): Boolean; static;
  end;

implementation

const
  PNG_SIGNATURE: array[0..7] of Byte = ($89, $50, $4E, $47, $0D, $0A, $1A, $0A);

// Copies bytes into a growing output; the result is trimmed at the end
procedure Append(var AOut: TBytes; var ALength: Integer; const AData: TBytes;
  AStart, ACount: Integer);
begin
  if ACount <= 0 then
    Exit;
  if ALength + ACount > Length(AOut) then
    SetLength(AOut, (ALength + ACount) * 2);
  Move(AData[AStart], AOut[ALength], ACount);
  Inc(ALength, ACount);
end;

function ReadBE32(const AData: TBytes; AAt: Integer): Cardinal;
begin
  Result := (Cardinal(AData[AAt]) shl 24) or (Cardinal(AData[AAt + 1]) shl 16) or
    (Cardinal(AData[AAt + 2]) shl 8) or Cardinal(AData[AAt + 3]);
end;

function ReadLE32(const AData: TBytes; AAt: Integer): Cardinal;
begin
  Result := Cardinal(AData[AAt]) or (Cardinal(AData[AAt + 1]) shl 8) or
    (Cardinal(AData[AAt + 2]) shl 16) or (Cardinal(AData[AAt + 3]) shl 24);
end;

procedure WriteLE32(var AData: TBytes; AAt: Integer; AValue: Cardinal);
begin
  AData[AAt] := Byte(AValue);
  AData[AAt + 1] := Byte(AValue shr 8);
  AData[AAt + 2] := Byte(AValue shr 16);
  AData[AAt + 3] := Byte(AValue shr 24);
end;

// True when AData holds the ASCII text AText at AAt
function HasText(const AData: TBytes; AAt: Integer; const AText: AnsiString): Boolean;
var
  I: Integer;
begin
  if (AAt < 0) or (AAt + Length(AText) > Length(AData)) then
    Exit(False);
  for I := 1 to Length(AText) do
    if AData[AAt + I - 1] <> Byte(AText[I]) then
      Exit(False);
  Result := True;
end;

// JPEG: the segments before the image data, without the APP1 "Exif" ones;
// from the start of scan on, everything is copied as it is
function StripJpeg(const AData: TBytes; out AStripped: TBytes): Boolean;
var
  LOut: TBytes;
  LLength, P, LSegment: Integer;
  LMarker: Byte;
begin
  Result := False;
  AStripped := AData;
  if (Length(AData) < 4) or (AData[0] <> $FF) or (AData[1] <> $D8) then
    Exit;
  SetLength(LOut, Length(AData));
  LLength := 0;
  Append(LOut, LLength, AData, 0, 2); // SOI
  P := 2;
  while P < Length(AData) do
  begin
    if AData[P] <> $FF then
      Exit; // not a marker where one must be: leave the image alone
    // Fill bytes: any number of FF before the marker
    while (P + 1 < Length(AData)) and (AData[P + 1] = $FF) do
      Inc(P);
    if P + 1 >= Length(AData) then
      Exit;
    LMarker := AData[P + 1];
    // Markers without a length: TEM and RST0 to RST7
    if (LMarker = $01) or ((LMarker >= $D0) and (LMarker <= $D7)) then
    begin
      Append(LOut, LLength, AData, P, 2);
      Inc(P, 2);
      Continue;
    end;
    if LMarker = $D9 then
    begin
      // EOI: the end, and anything after it is copied
      Append(LOut, LLength, AData, P, Length(AData) - P);
      Break;
    end;
    if P + 4 > Length(AData) then
      Exit;
    LSegment := (AData[P + 2] shl 8) or AData[P + 3]; // includes the two length bytes
    if (LSegment < 2) or (P + 2 + LSegment > Length(AData)) then
      Exit;
    if LMarker = $DA then
    begin
      // Start of scan: the image data follows, to the end
      Append(LOut, LLength, AData, P, Length(AData) - P);
      Break;
    end;
    if (LMarker = $E1) and HasText(AData, P + 4, 'Exif'#0) then
      Result := True // left out
    else
      Append(LOut, LLength, AData, P, 2 + LSegment);
    Inc(P, 2 + LSegment);
  end;
  if Result then
  begin
    SetLength(LOut, LLength);
    AStripped := LOut;
  end;
end;

// PNG: the chunks without eXIf and the text chunks holding EXIF
function StripPng(const AData: TBytes; out AStripped: TBytes): Boolean;
var
  LOut: TBytes;
  LLength, P, I, LChunk: Integer;
  LSize: Cardinal;
  LKeyword: string;
  LDrop: Boolean;
begin
  Result := False;
  AStripped := AData;
  if Length(AData) < 8 then
    Exit;
  for I := 0 to 7 do
    if AData[I] <> PNG_SIGNATURE[I] then
      Exit;
  SetLength(LOut, Length(AData));
  LLength := 0;
  Append(LOut, LLength, AData, 0, 8);
  P := 8;
  while P < Length(AData) do
  begin
    if P + 12 > Length(AData) then
      Exit; // a cut chunk: leave the image alone
    LSize := ReadBE32(AData, P);
    if LSize > Cardinal(Length(AData) - P - 12) then
      Exit;
    LChunk := 12 + Integer(LSize); // length, type, data, CRC
    LDrop := HasText(AData, P + 4, 'eXIf');
    if not LDrop and (HasText(AData, P + 4, 'tEXt') or HasText(AData, P + 4, 'zTXt') or
       HasText(AData, P + 4, 'iTXt')) then
    begin
      // The keyword runs to the first zero byte
      LKeyword := '';
      I := P + 8;
      while (I < P + 8 + Integer(LSize)) and (AData[I] <> 0) and (Length(LKeyword) < 80) do
      begin
        LKeyword := LKeyword + Char(AData[I]);
        Inc(I);
      end;
      LDrop := SameText(LKeyword, 'Raw profile type exif') or
        SameText(LKeyword, 'Raw profile type APP1');
    end;
    if LDrop then
      Result := True
    else
      Append(LOut, LLength, AData, P, LChunk);
    if HasText(AData, P + 4, 'IEND') then
    begin
      // Anything after the end is copied as it is
      Append(LOut, LLength, AData, P + LChunk, Length(AData) - P - LChunk);
      Break;
    end;
    Inc(P, LChunk);
  end;
  if Result then
  begin
    SetLength(LOut, LLength);
    AStripped := LOut;
  end;
end;

// WebP: the RIFF chunks without EXIF; VP8X's EXIF flag cleared
function StripWebp(const AData: TBytes; out AStripped: TBytes): Boolean;
const
  VP8X_EXIF_FLAG = $08;
var
  LOut: TBytes;
  LLength, P, LChunk, LVp8x: Integer;
  LSize: Cardinal;
begin
  Result := False;
  AStripped := AData;
  if (Length(AData) < 12) or not HasText(AData, 0, 'RIFF') or not HasText(AData, 8, 'WEBP') then
    Exit;
  SetLength(LOut, Length(AData));
  LLength := 0;
  Append(LOut, LLength, AData, 0, 12);
  LVp8x := -1;
  P := 12;
  while P + 8 <= Length(AData) do
  begin
    LSize := ReadLE32(AData, P + 4);
    if LSize > Cardinal(Length(AData) - P - 8) then
      Exit; // a cut chunk: leave the image alone
    LChunk := 8 + Integer(LSize) + Integer(LSize and 1); // padded to an even size
    if P + LChunk > Length(AData) then
      LChunk := Length(AData) - P; // a last chunk without its pad byte
    if HasText(AData, P, 'EXIF') then
      Result := True
    else
    begin
      if HasText(AData, P, 'VP8X') and (LSize >= 1) then
        LVp8x := LLength;
      Append(LOut, LLength, AData, P, LChunk);
    end;
    Inc(P, LChunk);
  end;
  // A few stray bytes after the last chunk are kept
  if P < Length(AData) then
    Append(LOut, LLength, AData, P, Length(AData) - P);
  if Result then
  begin
    SetLength(LOut, LLength);
    if LVp8x >= 0 then
      LOut[LVp8x + 8] := LOut[LVp8x + 8] and not VP8X_EXIF_FLAG;
    WriteLE32(LOut, 4, Cardinal(LLength - 8));
    AStripped := LOut;
  end;
end;

{ TglTFExif }

class function TglTFExif.Strip(const AData: TBytes; out AStripped: TBytes): Boolean;
begin
  // Each format checks its own signature; at most one matches
  Result := StripJpeg(AData, AStripped) or StripPng(AData, AStripped) or
    StripWebp(AData, AStripped);
  if not Result then
    AStripped := AData;
end;

class function TglTFExif.HasExif(const AData: TBytes): Boolean;
var
  LStripped: TBytes;
begin
  Result := Strip(AData, LStripped);
end;

end.
