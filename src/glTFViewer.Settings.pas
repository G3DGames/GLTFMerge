//** @abstract(The viewer's settings, kept between sessions in a JSON file where the platform
//** expects application settings.)
//**
//** @link(TglTFSettings) holds the folder each file dialog was last used in, under a key per
//** kind of dialog, the folder most recently used by any of them, and named text values for
//** anything else to remember. Every change is written to the file at once, so nothing is
//** lost when the application stops unexpectedly. @link(AppSettings) returns the one instance
//** the application uses.
//**
//** The file is settings.json in a glTFMerge folder:
//**
//** @preformatted(
//** Windows:  %APPDATA%\glTFMerge                      @(AppData\Roaming@)
//** macOS:    ~/Library/Application Support/glTFMerge
//** Linux:    $XDG_CONFIG_HOME/glTFMerge, else ~/.config/glTFMerge
//** iOS:      the app's Library folder
//** Android:  the app's private files folder
//** )
//**
//** A missing file means no settings yet. A file that cannot be read is renamed to
//** settings.json.bad and the settings start empty. Failing to write the file is not an error:
//** the settings then last for the session only. Use the settings on the main thread only.
unit glTFViewer.Settings;

{
  The viewer's settings, kept between sessions in a JSON file where the
  platform expects application settings.

  TglTFSettings holds the folder each file dialog was last used in, under a
  key per kind of dialog, the folder most recently used by any of them, and
  named text values for anything else to remember. Every change is written to
  the file at once, so nothing is lost when the application stops
  unexpectedly. AppSettings returns the one instance the application uses.

  The file is settings.json in a glTFMerge folder:

    Windows:  %APPDATA%\glTFMerge                      (AppData\Roaming)
    macOS:    ~/Library/Application Support/glTFMerge
    Linux:    $XDG_CONFIG_HOME/glTFMerge, else ~/.config/glTFMerge
    iOS:      the app's Library folder
    Android:  the app's private files folder

  A missing file means no settings yet. A file that cannot be read is renamed
  to settings.json.bad and the settings start empty. Failing to write the file
  is not an error: the settings then last for the session only. Use the
  settings on the main thread only.
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.JSON;

type
  //** @abstract(Settings kept in a JSON file between sessions.)
  //**
  //** Usually reached through @link(AppSettings). The file looks like this:
  //**
  //** @longCode(#
  //** {
  //**   "folders": { "openModel": "C:\\Models", "saveModel": "C:\\Out" },
  //**   "lastFolder": "C:\\Out",
  //**   "values": { "name": "text" }
  //** }
  //** #)
  /// <summary>Settings kept in a JSON file between sessions.</summary>
  /// <remarks>Usually reached through <see cref="AppSettings"/>. The file holds an object
  /// "folders" with a folder per key, "lastFolder" with the folder used most recently, and an
  /// object "values" with named text values.</remarks>
  TglTFSettings = class
  private
    FFileName: string;
    FData: TJSONObject;
    FLastError: string;
    procedure Load;
    procedure Save;
    function Section(const AName: string): TJSONObject;
    function ReadText(AObject: TJSONObject; const AName: string): string;
    procedure WriteText(AObject: TJSONObject; const AName, AValue: string);
  public
    //** @abstract(Reads the settings from a file.)
    //**
    //** @param(AFileName The settings file; it need not exist yet.)
    /// <summary>Reads the settings from a file.</summary>
    /// <param name="AFileName">The settings file; it need not exist yet.</param>
    constructor Create(const AFileName: string);

    //** @abstract(Frees the settings; they were already written.)
    /// <summary>Frees the settings; they were already written.</summary>
    destructor Destroy; override;

    //** @abstract(Returns where this platform keeps the application's settings file.)
    //**
    //** @returns(The full path of settings.json; its folder may not exist yet.)
    /// <summary>Returns where this platform keeps the application's settings file.</summary>
    /// <returns>The full path of settings.json; its folder may not exist yet.</returns>
    class function DefaultFileName: string; static;

    //** @abstract(Returns the folder last used for a kind of dialog.)
    //**
    //** @param(AKey The kind of dialog, for example "openModel".)
    //**
    //** @returns(The folder, or an empty string when none was stored.)
    /// <summary>Returns the folder last used for a kind of dialog.</summary>
    /// <param name="AKey">The kind of dialog, for example "openModel".</param>
    /// <returns>The folder, or an empty string when none was stored.</returns>
    function GetFolder(const AKey: string): string;

    //** @abstract(Stores the folder used for a kind of dialog, and as the folder used most
    //** recently.)
    //**
    //** @param(AKey The kind of dialog; empty to store the most recent folder only.)
    //**
    //** @param(AFolder The folder; an empty one is ignored.)
    /// <summary>Stores the folder used for a kind of dialog, and as the folder used most
    /// recently.</summary>
    /// <param name="AKey">The kind of dialog; empty to store the most recent folder
    /// only.</param>
    /// <param name="AFolder">The folder; an empty one is ignored.</param>
    procedure SetFolder(const AKey, AFolder: string);

    //** @abstract(Returns the folder any dialog used most recently.)
    //**
    //** @returns(The folder, or an empty string when none was stored.)
    /// <summary>Returns the folder any dialog used most recently.</summary>
    /// <returns>The folder, or an empty string when none was stored.</returns>
    function LastFolder: string;

    //** @abstract(Returns a named text value.)
    //**
    //** @param(AName The value's name.)
    //**
    //** @param(ADefault Returned when the value was never stored.)
    //**
    //** @returns(The value.)
    /// <summary>Returns a named text value.</summary>
    /// <param name="AName">The value's name.</param>
    /// <param name="ADefault">Returned when the value was never stored.</param>
    /// <returns>The value.</returns>
    function ReadString(const AName: string; const ADefault: string = ''): string;

    //** @abstract(Stores a named text value.)
    //**
    //** @param(AName The value's name.)
    //**
    //** @param(AValue The value.)
    /// <summary>Stores a named text value.</summary>
    /// <param name="AName">The value's name.</param>
    /// <param name="AValue">The value.</param>
    procedure WriteString(const AName, AValue: string);

    //** @abstract(The settings file.)
    /// <summary>The settings file.</summary>
    property FileName: string read FFileName;

    //** @abstract(Why the file could not last be read or written; empty when it could.)
    /// <summary>Why the file could not last be read or written; empty when it
    /// could.</summary>
    property LastError: string read FLastError;
  end;

//** @abstract(Returns the application's settings, read from @code(TglTFSettings.DefaultFileName)
//** on first use.)
//**
//** @returns(The settings; freed when the application ends.)
/// <summary>Returns the application's settings, read from
/// <c>TglTFSettings.DefaultFileName</c> on first use.</summary>
/// <returns>The settings; freed when the application ends.</returns>
function AppSettings: TglTFSettings;

implementation

const
  APP_FOLDER = 'glTFMerge';
  SETTINGS_FILE = 'settings.json';
  KEY_FOLDERS = 'folders';
  KEY_LAST_FOLDER = 'lastFolder';
  KEY_VALUES = 'values';

var
  GSettings: TglTFSettings;

function AppSettings: TglTFSettings;
begin
  if GSettings = nil then
    GSettings := TglTFSettings.Create(TglTFSettings.DefaultFileName);
  Result := GSettings;
end;

{ TglTFSettings }

class function TglTFSettings.DefaultFileName: string;
var
  LBase: string;
begin
{$IF DEFINED(MSWINDOWS)}
  // The roaming AppData folder
  LBase := TPath.Combine(TPath.GetHomePath, APP_FOLDER);
{$ELSEIF DEFINED(IOS)}
  LBase := TPath.Combine(TPath.GetLibraryPath, APP_FOLDER);
{$ELSEIF DEFINED(ANDROID)}
  LBase := TPath.Combine(TPath.GetHomePath, APP_FOLDER);
{$ELSEIF DEFINED(MACOS)}
  LBase := TPath.Combine(TPath.Combine(TPath.GetHomePath, 'Library/Application Support'),
    APP_FOLDER);
{$ELSE}
  // Linux: the XDG configuration folder
  LBase := GetEnvironmentVariable('XDG_CONFIG_HOME');
  if LBase = '' then
    LBase := TPath.Combine(TPath.GetHomePath, '.config');
  LBase := TPath.Combine(LBase, APP_FOLDER);
{$ENDIF}
  Result := TPath.Combine(LBase, SETTINGS_FILE);
end;

constructor TglTFSettings.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
  Load;
end;

destructor TglTFSettings.Destroy;
begin
  FData.Free;
  inherited;
end;

procedure TglTFSettings.Load;
var
  LValue: TJSONValue;
begin
  FData := nil;
  if TFile.Exists(FFileName) then
  begin
    try
      LValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(FFileName, TEncoding.UTF8));
      if LValue is TJSONObject then
        FData := TJSONObject(LValue)
      else
      begin
        LValue.Free;
        raise Exception.Create('not a JSON object');
      end;
    except
      on E: Exception do
      begin
        // Kept aside rather than overwritten, in case it matters to someone
        FLastError := Format('%s could not be read (%s)', [FFileName, E.Message]);
        try
          TFile.Copy(FFileName, FFileName + '.bad', True);
          TFile.Delete(FFileName);
        except
          // still unreadable: it is replaced on the next change
        end;
      end;
    end;
  end;
  if FData = nil then
    FData := TJSONObject.Create;
end;

procedure TglTFSettings.Save;
var
  LTemp: string;
begin
  // Written to a new file first, so a failure never leaves half a file
  try
    ForceDirectories(ExtractFileDir(FFileName));
    LTemp := FFileName + '.new';
    TFile.WriteAllText(LTemp, FData.Format(2), TEncoding.UTF8);
    if TFile.Exists(FFileName) then
      TFile.Delete(FFileName);
    TFile.Move(LTemp, FFileName);
    FLastError := '';
  except
    on E: Exception do
      FLastError := Format('%s could not be written (%s)', [FFileName, E.Message]);
  end;
end;

function TglTFSettings.Section(const AName: string): TJSONObject;
var
  LValue: TJSONValue;
begin
  LValue := FData.GetValue(AName);
  if LValue is TJSONObject then
    Exit(TJSONObject(LValue));
  if LValue <> nil then
    FData.RemovePair(AName).Free; // not an object: replaced
  Result := TJSONObject.Create;
  FData.AddPair(AName, Result);
end;

function TglTFSettings.ReadText(AObject: TJSONObject; const AName: string): string;
var
  LValue: TJSONValue;
begin
  LValue := AObject.GetValue(AName);
  if LValue is TJSONString then
    Result := TJSONString(LValue).Value
  else
    Result := '';
end;

procedure TglTFSettings.WriteText(AObject: TJSONObject; const AName, AValue: string);
begin
  AObject.RemovePair(AName).Free;
  AObject.AddPair(AName, AValue);
end;

function TglTFSettings.GetFolder(const AKey: string): string;
begin
  if AKey = '' then
    Exit('');
  Result := ReadText(Section(KEY_FOLDERS), AKey);
end;

procedure TglTFSettings.SetFolder(const AKey, AFolder: string);
begin
  if AFolder = '' then
    Exit;
  if (GetFolder(AKey) = AFolder) and (LastFolder = AFolder) then
    Exit; // unchanged: no need to write
  if AKey <> '' then
    WriteText(Section(KEY_FOLDERS), AKey, AFolder);
  WriteText(FData, KEY_LAST_FOLDER, AFolder);
  Save;
end;

function TglTFSettings.LastFolder: string;
begin
  Result := ReadText(FData, KEY_LAST_FOLDER);
end;

function TglTFSettings.ReadString(const AName, ADefault: string): string;
var
  LValues: TJSONObject;
begin
  LValues := Section(KEY_VALUES);
  if LValues.GetValue(AName) is TJSONString then
    Result := ReadText(LValues, AName)
  else
    Result := ADefault;
end;

procedure TglTFSettings.WriteString(const AName, AValue: string);
begin
  if (Section(KEY_VALUES).GetValue(AName) is TJSONString) and
     (ReadString(AName) = AValue) then
    Exit;
  WriteText(Section(KEY_VALUES), AName, AValue);
  Save;
end;

initialization

finalization
  FreeAndNil(GSettings);

end.
