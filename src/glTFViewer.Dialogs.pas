//** @abstract(File and confirmation dialogs that work the same way on every FireMonkey
//** platform.)
//**
//** @link(TPlatformDialogs) offers open-file @(one or several@), save-file, select-folder and
//** confirmation dialogs. On Windows, macOS and Linux they are the native dialogs. iOS and
//** Android have no FireMonkey file dialogs, so there the file browser of
//** glTFViewer.FileBrowser is shown instead: it starts in the app's documents folder, which
//** needs no storage permission, and can switch to the shared Documents and Downloads folders
//** where the system allows access.
//**
//** Each file dialog is given a key naming its kind, such as "openModel": the folder chosen is
//** remembered under it in the settings file @(see glTFViewer.Settings@) and offered the next
//** time, so opening and saving each keep their own folder. A dialog never used before starts
//** in the folder any dialog used most recently, and with no settings at all in the
//** platform's usual folder.
//**
//** Every dialog reports its result through a callback rather than a return value, because
//** dialogs do not block on Android. On the desktop the callback runs before the call returns;
//** on mobile it runs later, when the user closes the dialog. Code that follows a dialog must
//** therefore go in the callback. Call these routines on the main thread only.
//**
//** @preformatted(
//** Windows, macOS, Linux:  native dialogs
//** iOS, Android:           built-in file browser
//** Confirm:                TDialogService on every platform
//** )
unit glTFViewer.Dialogs;

{
  File and confirmation dialogs that work the same way on every FireMonkey
  platform.

  TPlatformDialogs offers open-file (one or several), save-file, select-folder
  and confirmation dialogs. On Windows, macOS and Linux they are the native
  dialogs. iOS and Android have no FireMonkey file dialogs, so there the file
  browser of glTFViewer.FileBrowser is shown instead: it starts in the app's
  documents folder, which needs no storage permission, and can switch to the
  shared Documents and Downloads folders where the system allows access.

  Each file dialog is given a key naming its kind, such as "openModel": the
  folder chosen is remembered under it in the settings file (see
  glTFViewer.Settings) and offered the next time, so opening and saving each
  keep their own folder. A dialog never used before starts in the folder any
  dialog used most recently, and with no settings at all in the platform's
  usual folder.

  Every dialog reports its result through a callback rather than a return
  value, because dialogs do not block on Android. On the desktop the callback
  runs before the call returns; on mobile it runs later, when the user closes
  the dialog. Code that follows a dialog must therefore go in the callback.
  Call these routines on the main thread only.

    Windows, macOS, Linux:  native dialogs
    iOS, Android:           built-in file browser
    Confirm:                TDialogService on every platform
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.IOUtils,
  System.Generics.Collections, System.Generics.Defaults,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Layouts, FMX.ListBox,
  FMX.Edit, FMX.Dialogs, FMX.DialogService, FMX.Controls.Presentation;

type
  //** @abstract(A file type a dialog offers: a description and its extensions.)
  /// <summary>A file type a dialog offers: a description and its extensions.</summary>
  TFileType = record
    //** @abstract(Text shown for the type, for example "Binary glTF".)
    /// <summary>Text shown for the type, for example "Binary glTF".</summary>
    Description: string;
    //** @abstract(Extensions including the dot, for example ".glb"; "*" matches every file.)
    /// <summary>Extensions including the dot, for example ".glb"; "*" matches every
    /// file.</summary>
    Extensions: TArray<string>;
    //** @abstract(Returns a file type.)
    //**
    //** @param(ADescription Text shown for the type.)
    //**
    //** @param(AExtensions Extensions including the dot; "*" for every file.)
    //**
    //** @returns(The new file type.)
    //**
    //** @longCode(#
    //** TFileType.Create('glTF files', ['.gltf', '.glb'])
    //** #)
    /// <summary>Returns a file type.</summary>
    /// <param name="ADescription">Text shown for the type.</param>
    /// <param name="AExtensions">Extensions including the dot; "*" for every file.</param>
    /// <returns>The new file type.</returns>
    /// <example><code>
    /// TFileType.Create('glTF files', ['.gltf', '.glb'])
    /// </code></example>
    class function Create(const ADescription: string;
      const AExtensions: array of string): TFileType; static;
    //** @abstract(Tells whether a file name has one of the type's extensions.)
    //**
    //** The comparison ignores case on every platform.
    //**
    //** @param(AFileName A file name or path.)
    //**
    //** @returns(True when an extension matches or the type has "*".)
    /// <summary>Tells whether a file name has one of the type's extensions.</summary>
    /// <param name="AFileName">A file name or path.</param>
    /// <returns>True when an extension matches or the type has "*".</returns>
    /// <remarks>The comparison ignores case on every platform.</remarks>
    function Matches(const AFileName: string): Boolean;
  end;

  //** @abstract(Open, save, folder and confirmation dialogs for every FireMonkey platform.)
  //**
  //** All routines are class methods; use them on the main thread. Results arrive through a
  //** callback: immediately on the desktop, after the user closes the dialog on iOS and
  //** Android.
  /// <summary>Open, save, folder and confirmation dialogs for every FireMonkey
  /// platform.</summary>
  /// <remarks>All routines are class methods; use them on the main thread. Results arrive
  /// through a callback: immediately on the desktop, after the user closes the dialog on iOS
  /// and Android.</remarks>
  TPlatformDialogs = class sealed
  private
    class procedure RememberFolder(const AKey, AFolder: string); static;
    class procedure DoOpenFile(const ATitle: string; const ATypes: TArray<TFileType>;
      const AInitialDir, AFileName: string; const ADone: TProc<string>); static;
    class procedure DoOpenFiles(const ATitle: string; const ATypes: TArray<TFileType>;
      const AInitialDir: string; const ADone: TProc<TArray<string>>); static;
    class procedure DoSaveFile(const ATitle: string; const ATypes: TArray<TFileType>;
      ATypeIndex: Integer; const AInitialDir, AFileName: string;
      const ADone: TProc<string, Integer>); static;
    class procedure DoSelectFolder(const ATitle, AInitialDir: string;
      const ADone: TProc<string>); static;
  public
    //** @abstract(Tells whether the native dialogs are used.)
    //**
    //** @returns(True on Windows, macOS and Linux; False on iOS and Android, where the built-in
    //** browser is shown.)
    /// <summary>Tells whether the native dialogs are used.</summary>
    /// <returns>True on Windows, macOS and Linux; False on iOS and Android, where the built-in
    /// browser is shown.</returns>
    class function UsesNativeDialogs: Boolean; static;
    //** @abstract(Returns the folder dialogs start in when no other is given.)
    //**
    //** @returns(The user's documents folder on the desktop; the app's own documents folder on
    //** iOS and Android.)
    /// <summary>Returns the folder dialogs start in when no other is given.</summary>
    /// <returns>The user's documents folder on the desktop; the app's own documents folder on
    /// iOS and Android.</returns>
    class function DefaultFolder: string; static;

    //** @abstract(Returns the folder a dialog starts in.)
    //**
    //** In this order: AInitialDir; the folder remembered for AKey; the folder any dialog used
    //** most recently; and when none of them exists, an empty string, which leaves the choice
    //** to the platform @(the native dialog's own folder on the desktop, DefaultFolder on iOS
    //** and Android@).
    //**
    //** @param(AKey The kind of dialog.)
    //**
    //** @param(AInitialDir The caller's own choice; may be empty.)
    //**
    //** @returns(An existing folder, or an empty string.)
    /// <summary>Returns the folder a dialog starts in.</summary>
    /// <param name="AKey">The kind of dialog.</param>
    /// <param name="AInitialDir">The caller's own choice; may be empty.</param>
    /// <returns>An existing folder, or an empty string.</returns>
    /// <remarks>In this order: AInitialDir; the folder remembered for AKey; the folder any
    /// dialog used most recently; and when none of them exists, an empty string, which leaves
    /// the choice to the platform (the native dialog's own folder on the desktop,
    /// DefaultFolder on iOS and Android).</remarks>
    class function StartFolder(const AKey, AInitialDir: string): string; static;
    //** @abstract(Lets the user choose an existing file.)
    //**
    //** On iOS and Android, tapping a file chooses it.
    //**
    //** @param(AKey The kind of dialog, for example "openModel": the folder chosen is
    //** remembered under it, in the settings file, for the next time.)
    //**
    //** @param(ATitle Title of the dialog.)
    //**
    //** @param(ATypes File types offered; the first is selected.)
    //**
    //** @param(AInitialDir Folder to start in, when the caller knows a better one than the one
    //** remembered; empty to use StartFolder.)
    //**
    //** @param(AFileName File name to suggest; may be empty.)
    //**
    //** @param(ADone Called with the chosen file's full path, or an empty string when
    //** cancelled.)
    /// <summary>Lets the user choose an existing file.</summary>
    /// <param name="AKey">The kind of dialog, for example "openModel": the folder chosen is
    /// remembered under it, in the settings file, for the next time.</param>
    /// <param name="ATitle">Title of the dialog.</param>
    /// <param name="ATypes">File types offered; the first is selected.</param>
    /// <param name="AInitialDir">Folder to start in, when the caller knows a better one than the
    /// one remembered; empty to use StartFolder.</param>
    /// <param name="AFileName">File name to suggest; may be empty.</param>
    /// <param name="ADone">Called with the chosen file's full path, or an empty string when
    /// cancelled.</param>
    /// <remarks>On iOS and Android, tapping a file chooses it.</remarks>
    class procedure OpenFile(const AKey, ATitle: string; const ATypes: TArray<TFileType>;
      const AInitialDir, AFileName: string; const ADone: TProc<string>); static;
    //** @abstract(Lets the user choose one or more existing files.)
    //**
    //** On the desktop, the native dialog with multiple selection. On iOS and Android,
    //** tapping a file ticks or unticks it, a tick shown before its name; files can be ticked
    //** in several folders before choosing Open.
    //**
    //** @param(AKey The kind of dialog, for example "openModel": the folder chosen is
    //** remembered under it, in the settings file, for the next time.)
    //**
    //** @param(ATitle Title of the dialog.)
    //**
    //** @param(ATypes File types offered; the first is selected.)
    //**
    //** @param(AInitialDir Folder to start in, when the caller knows a better one than the one
    //** remembered; empty to use StartFolder.)
    //**
    //** @param(ADone Called with the full paths of the chosen files, in the order they were
    //** chosen on mobile; an empty array when cancelled.)
    /// <summary>Lets the user choose one or more existing files.</summary>
    /// <param name="AKey">The kind of dialog, for example "openModel": the folder chosen is
    /// remembered under it, in the settings file, for the next time.</param>
    /// <param name="ATitle">Title of the dialog.</param>
    /// <param name="ATypes">File types offered; the first is selected.</param>
    /// <param name="AInitialDir">Folder to start in, when the caller knows a better one than the
    /// one remembered; empty to use StartFolder.</param>
    /// <param name="ADone">Called with the full paths of the chosen files, in the order they
    /// were chosen on mobile; an empty array when cancelled.</param>
    /// <remarks>On the desktop, the native dialog with multiple selection. On iOS and Android,
    /// tapping a file ticks or unticks it, a tick shown before its name; files can be ticked
    /// in several folders before choosing Open.</remarks>
    class procedure OpenFiles(const AKey, ATitle: string; const ATypes: TArray<TFileType>;
      const AInitialDir: string; const ADone: TProc<TArray<string>>); static;
    //** @abstract(Lets the user choose a file name to save to.)
    //**
    //** Replacing an existing file is not confirmed here, so that the caller can first adjust
    //** the name, for example its extension, and then use @link(Confirm).
    //**
    //** @param(AKey The kind of dialog, for example "openModel": the folder chosen is
    //** remembered under it, in the settings file, for the next time.)
    //**
    //** @param(ATitle Title of the dialog.)
    //**
    //** @param(ATypes File types offered.)
    //**
    //** @param(ATypeIndex Index in ATypes of the type selected at first.)
    //**
    //** @param(AInitialDir Folder to start in, when the caller knows a better one than the one
    //** remembered; empty to use StartFolder.)
    //**
    //** @param(AFileName File name to suggest; may be empty.)
    //**
    //** @param(ADone Called with the chosen full path and the index of the chosen type; with an
    //** empty string and -1 when cancelled.)
    /// <summary>Lets the user choose a file name to save to.</summary>
    /// <param name="AKey">The kind of dialog, for example "openModel": the folder chosen is
    /// remembered under it, in the settings file, for the next time.</param>
    /// <param name="ATitle">Title of the dialog.</param>
    /// <param name="ATypes">File types offered.</param>
    /// <param name="ATypeIndex">Index in ATypes of the type selected at first.</param>
    /// <param name="AInitialDir">Folder to start in, when the caller knows a better one than the
    /// one remembered; empty to use StartFolder.</param>
    /// <param name="AFileName">File name to suggest; may be empty.</param>
    /// <param name="ADone">Called with the chosen full path and the index of the chosen type;
    /// with an empty string and -1 when cancelled.</param>
    /// <remarks>Replacing an existing file is not confirmed here, so that the caller can first
    /// adjust the name, for example its extension, and then use <see
    /// cref="Confirm"/>.</remarks>
    class procedure SaveFile(const AKey, ATitle: string; const ATypes: TArray<TFileType>;
      ATypeIndex: Integer; const AInitialDir, AFileName: string;
      const ADone: TProc<string, Integer>); static;
    //** @abstract(Lets the user choose a folder.)
    //**
    //** @param(AKey The kind of dialog, for example "openModel": the folder chosen is
    //** remembered under it, in the settings file, for the next time.)
    //**
    //** @param(ATitle Title of the dialog.)
    //**
    //** @param(AInitialDir Folder to start in, when the caller knows a better one than the one
    //** remembered; empty to use StartFolder.)
    //**
    //** @param(ADone Called with the chosen folder, or an empty string when cancelled.)
    /// <summary>Lets the user choose a folder.</summary>
    /// <param name="AKey">The kind of dialog, for example "openModel": the folder chosen is
    /// remembered under it, in the settings file, for the next time.</param>
    /// <param name="ATitle">Title of the dialog.</param>
    /// <param name="AInitialDir">Folder to start in, when the caller knows a better one than the
    /// one remembered; empty to use StartFolder.</param>
    /// <param name="ADone">Called with the chosen folder, or an empty string when
    /// cancelled.</param>
    class procedure SelectFolder(const AKey, ATitle, AInitialDir: string;
      const ADone: TProc<string>); static;
    //** @abstract(Asks a yes or no question.)
    //**
    //** Uses TDialogService, which works on every platform.
    //**
    //** @param(AMessage The question.)
    //**
    //** @param(ADone Called with True when the user answered Yes.)
    /// <summary>Asks a yes or no question.</summary>
    /// <param name="AMessage">The question.</param>
    /// <param name="ADone">Called with True when the user answered Yes.</param>
    /// <remarks>Uses TDialogService, which works on every platform.</remarks>
    class procedure Confirm(const AMessage: string; const ADone: TProc<Boolean>); static;
  end;

implementation

{$IF DEFINED(ANDROID) or DEFINED(IOS)}
  {$DEFINE GLTF_MOBILE}
{$ENDIF}

uses
{$IFDEF GLTF_MOBILE}
  glTFViewer.FileBrowser,
{$ENDIF}
  glTFViewer.Settings;

{ TFileType }

class function TFileType.Create(const ADescription: string;
  const AExtensions: array of string): TFileType;
var
  I: Integer;
begin
  Result.Description := ADescription;
  SetLength(Result.Extensions, Length(AExtensions));
  for I := 0 to High(AExtensions) do
    Result.Extensions[I] := AExtensions[I];
end;

function TFileType.Matches(const AFileName: string): Boolean;
var
  LExt: string;
begin
  for LExt in Extensions do
    if (LExt = '*') or SameText(ExtractFileExt(AFileName), LExt) then
      Exit(True);
  Result := False;
end;

{$IFNDEF GLTF_MOBILE}

// Desktop: native dialogs. "Description (*.a;*.b)|*.a;*.b|..."
function FilterText(const ATypes: TArray<TFileType>): string;
var
  LType: TFileType;
  LExt, LMasks: string;
begin
  Result := '';
  for LType in ATypes do
  begin
    LMasks := '';
    for LExt in LType.Extensions do
    begin
      if LMasks <> '' then
        LMasks := LMasks + ';';
      if LExt = '*' then
        LMasks := LMasks + '*.*'
      else
        LMasks := LMasks + '*' + LExt;
    end;
    if Result <> '' then
      Result := Result + '|';
    Result := Result + Format('%s (%s)|%s', [LType.Description, LMasks, LMasks]);
  end;
end;

{$ENDIF}

{ TPlatformDialogs }

class function TPlatformDialogs.UsesNativeDialogs: Boolean;
begin
{$IFDEF GLTF_MOBILE}
  Result := False;
{$ELSE}
  Result := True;
{$ENDIF}
end;

class function TPlatformDialogs.DefaultFolder: string;
begin
  // Desktop: the user's documents folder. Mobile: the app's own documents
  // folder, which needs no storage permission
  Result := TPath.GetDocumentsPath;
end;

class procedure TPlatformDialogs.DoOpenFile(const ATitle: string; const ATypes: TArray<TFileType>;
  const AInitialDir, AFileName: string; const ADone: TProc<string>);
{$IFDEF GLTF_MOBILE}
var
  LForm: TFileBrowserForm;
begin
  LForm := TFileBrowserForm.CreateBrowser(bmOpen, ATitle, ATypes, 0, AInitialDir, AFileName);
  LForm.ShowModal(
    procedure(AResult: TModalResult)
    begin
      if AResult = mrOk then
        ADone(LForm.ResultPath)
      else
        ADone('');
    end);
end;
{$ELSE}
var
  LDialog: TOpenDialog;
  LFileName: string;
begin
  LFileName := '';
  LDialog := TOpenDialog.Create(nil);
  try
    LDialog.Title := ATitle;
    LDialog.Filter := FilterText(ATypes);
    LDialog.InitialDir := AInitialDir;
    LDialog.FileName := AFileName;
    if LDialog.Execute then
      LFileName := LDialog.FileName;
  finally
    LDialog.Free;
  end;
  ADone(LFileName);
end;
{$ENDIF}

class procedure TPlatformDialogs.DoOpenFiles(const ATitle: string; const ATypes: TArray<TFileType>;
  const AInitialDir: string; const ADone: TProc<TArray<string>>);
{$IFDEF GLTF_MOBILE}
var
  LForm: TFileBrowserForm;
begin
  LForm := TFileBrowserForm.CreateBrowser(bmOpenMany, ATitle, ATypes, 0, AInitialDir, '');
  LForm.ShowModal(
    procedure(AResult: TModalResult)
    begin
      if AResult = mrOk then
        ADone(LForm.Chosen)
      else
        ADone(nil);
    end);
end;
{$ELSE}
var
  LDialog: TOpenDialog;
  LFiles: TArray<string>;
begin
  LFiles := nil;
  LDialog := TOpenDialog.Create(nil);
  try
    LDialog.Title := ATitle;
    LDialog.Filter := FilterText(ATypes);
    LDialog.InitialDir := AInitialDir;
    LDialog.Options := LDialog.Options + [TOpenOption.ofAllowMultiSelect,
      TOpenOption.ofFileMustExist];
    if LDialog.Execute then
      LFiles := LDialog.Files.ToStringArray;
  finally
    LDialog.Free;
  end;
  ADone(LFiles);
end;
{$ENDIF}

class procedure TPlatformDialogs.DoSaveFile(const ATitle: string; const ATypes: TArray<TFileType>;
  ATypeIndex: Integer; const AInitialDir, AFileName: string; const ADone: TProc<string, Integer>);
{$IFDEF GLTF_MOBILE}
var
  LForm: TFileBrowserForm;
begin
  LForm := TFileBrowserForm.CreateBrowser(bmSave, ATitle, ATypes, ATypeIndex, AInitialDir, AFileName);
  LForm.ShowModal(
    procedure(AResult: TModalResult)
    begin
      if AResult = mrOk then
        ADone(LForm.ResultPath, LForm.TypeIndex)
      else
        ADone('', -1);
    end);
end;
{$ELSE}
var
  LDialog: TSaveDialog;
  LFileName: string;
  LType: Integer;
begin
  LFileName := '';
  LType := -1;
  LDialog := TSaveDialog.Create(nil);
  try
    LDialog.Title := ATitle;
    LDialog.Filter := FilterText(ATypes);
    LDialog.FilterIndex := ATypeIndex + 1;
    LDialog.InitialDir := AInitialDir;
    LDialog.FileName := AFileName;
    // Overwriting is confirmed by the caller, once the final name is known
    LDialog.Options := LDialog.Options - [TOpenOption.ofOverwritePrompt];
    if LDialog.Execute then
    begin
      LFileName := LDialog.FileName;
      LType := LDialog.FilterIndex - 1;
    end;
  finally
    LDialog.Free;
  end;
  ADone(LFileName, LType);
end;
{$ENDIF}

class procedure TPlatformDialogs.DoSelectFolder(const ATitle, AInitialDir: string;
  const ADone: TProc<string>);
{$IFDEF GLTF_MOBILE}
var
  LForm: TFileBrowserForm;
begin
  LForm := TFileBrowserForm.CreateBrowser(bmFolder, ATitle, nil, -1, AInitialDir, '');
  LForm.ShowModal(
    procedure(AResult: TModalResult)
    begin
      if AResult = mrOk then
        ADone(LForm.ResultPath)
      else
        ADone('');
    end);
end;
{$ELSE}
var
  LDir: string;
begin
  LDir := AInitialDir;
  if not SelectDirectory(ATitle, '', LDir) then
    LDir := '';
  ADone(LDir);
end;
{$ENDIF}

class function TPlatformDialogs.StartFolder(const AKey, AInitialDir: string): string;
begin
  if (AInitialDir <> '') and TDirectory.Exists(AInitialDir) then
    Exit(AInitialDir);
  // Remembered for this kind of dialog, else for any
  Result := AppSettings.GetFolder(AKey);
  if (Result <> '') and TDirectory.Exists(Result) then
    Exit;
  Result := AppSettings.LastFolder;
  if (Result <> '') and TDirectory.Exists(Result) then
    Exit;
  // Nothing remembered yet: the platform's own choice
  Result := '';
end;

class procedure TPlatformDialogs.RememberFolder(const AKey, AFolder: string);
begin
  if AFolder <> '' then
    AppSettings.SetFolder(AKey, AFolder);
end;

class procedure TPlatformDialogs.OpenFile(const AKey, ATitle: string;
  const ATypes: TArray<TFileType>; const AInitialDir, AFileName: string;
  const ADone: TProc<string>);
begin
  DoOpenFile(ATitle, ATypes, StartFolder(AKey, AInitialDir), AFileName,
    procedure(AChosen: string)
    begin
      if AChosen <> '' then
        RememberFolder(AKey, ExtractFileDir(AChosen));
      ADone(AChosen);
    end);
end;

class procedure TPlatformDialogs.OpenFiles(const AKey, ATitle: string;
  const ATypes: TArray<TFileType>; const AInitialDir: string;
  const ADone: TProc<TArray<string>>);
begin
  DoOpenFiles(ATitle, ATypes, StartFolder(AKey, AInitialDir),
    procedure(AChosen: TArray<string>)
    begin
      if Length(AChosen) > 0 then
        RememberFolder(AKey, ExtractFileDir(AChosen[High(AChosen)]));
      ADone(AChosen);
    end);
end;

class procedure TPlatformDialogs.SaveFile(const AKey, ATitle: string;
  const ATypes: TArray<TFileType>; ATypeIndex: Integer; const AInitialDir, AFileName: string;
  const ADone: TProc<string, Integer>);
begin
  DoSaveFile(ATitle, ATypes, ATypeIndex, StartFolder(AKey, AInitialDir), AFileName,
    procedure(AChosen: string; AChosenType: Integer)
    begin
      if AChosen <> '' then
        RememberFolder(AKey, ExtractFileDir(AChosen));
      ADone(AChosen, AChosenType);
    end);
end;

class procedure TPlatformDialogs.SelectFolder(const AKey, ATitle, AInitialDir: string;
  const ADone: TProc<string>);
begin
  DoSelectFolder(ATitle, StartFolder(AKey, AInitialDir),
    procedure(AChosen: string)
    begin
      if AChosen <> '' then
        RememberFolder(AKey, AChosen);
      ADone(AChosen);
    end);
end;

class procedure TPlatformDialogs.Confirm(const AMessage: string; const ADone: TProc<Boolean>);
begin
  TDialogService.MessageDialog(AMessage, TMsgDlgType.mtConfirmation,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      ADone(AResult = mrYes);
    end);
end;

end.
