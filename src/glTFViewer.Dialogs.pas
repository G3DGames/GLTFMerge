//** @abstract(File and confirmation dialogs that work the same way on every FireMonkey
//** platform.)
//**
//** @link(TPlatformDialogs) offers open-file @(one or several@), save-file, select-folder and
//** confirmation dialogs. On Windows, macOS and Linux they are the native dialogs. iOS and
//** Android have no FireMonkey file dialogs, so there a file browser built into this unit is
//** shown instead: it
//** starts in the app's documents folder, which needs no storage permission, and can switch to
//** the shared Documents and Downloads folders where the system allows access.
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
  and confirmation dialogs. On Windows, macOS and Linux they are the native dialogs. iOS and
  Android have no FireMonkey file dialogs, so there a file browser built into
  this unit is shown instead: it starts in the app's documents folder, which
  needs no storage permission, and can switch to the shared Documents and
  Downloads folders where the system allows access.

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
    //** @abstract(Lets the user choose an existing file.)
    //**
    //** On iOS and Android, tapping a file chooses it.
    //**
    //** @param(ATitle Title of the dialog.)
    //**
    //** @param(ATypes File types offered; the first is selected.)
    //**
    //** @param(AInitialDir Folder to start in; empty or missing uses DefaultFolder on mobile.)
    //**
    //** @param(AFileName File name to suggest; may be empty.)
    //**
    //** @param(ADone Called with the chosen file's full path, or an empty string when
    //** cancelled.)
    /// <summary>Lets the user choose an existing file.</summary>
    /// <param name="ATitle">Title of the dialog.</param>
    /// <param name="ATypes">File types offered; the first is selected.</param>
    /// <param name="AInitialDir">Folder to start in; empty or missing uses DefaultFolder on
    /// mobile.</param>
    /// <param name="AFileName">File name to suggest; may be empty.</param>
    /// <param name="ADone">Called with the chosen file's full path, or an empty string when
    /// cancelled.</param>
    /// <remarks>On iOS and Android, tapping a file chooses it.</remarks>
    class procedure OpenFile(const ATitle: string; const ATypes: TArray<TFileType>;
      const AInitialDir, AFileName: string; const ADone: TProc<string>); static;
    //** @abstract(Lets the user choose one or more existing files.)
    //**
    //** On the desktop, the native dialog with multiple selection. On iOS and Android,
    //** tapping a file ticks or unticks it, a tick shown before its name; files can be ticked
    //** in several folders before choosing Open.
    //**
    //** @param(ATitle Title of the dialog.)
    //**
    //** @param(ATypes File types offered; the first is selected.)
    //**
    //** @param(AInitialDir Folder to start in; empty or missing uses DefaultFolder on mobile.)
    //**
    //** @param(ADone Called with the full paths of the chosen files, in the order they were
    //** chosen on mobile; an empty array when cancelled.)
    /// <summary>Lets the user choose one or more existing files.</summary>
    /// <param name="ATitle">Title of the dialog.</param>
    /// <param name="ATypes">File types offered; the first is selected.</param>
    /// <param name="AInitialDir">Folder to start in; empty or missing uses DefaultFolder on
    /// mobile.</param>
    /// <param name="ADone">Called with the full paths of the chosen files, in the order they
    /// were chosen on mobile; an empty array when cancelled.</param>
    /// <remarks>On the desktop, the native dialog with multiple selection. On iOS and Android,
    /// tapping a file ticks or unticks it, a tick shown before its name; files can be ticked
    /// in several folders before choosing Open.</remarks>
    class procedure OpenFiles(const ATitle: string; const ATypes: TArray<TFileType>;
      const AInitialDir: string; const ADone: TProc<TArray<string>>); static;
    //** @abstract(Lets the user choose a file name to save to.)
    //**
    //** Replacing an existing file is not confirmed here, so that the caller can first adjust
    //** the name, for example its extension, and then use @link(Confirm).
    //**
    //** @param(ATitle Title of the dialog.)
    //**
    //** @param(ATypes File types offered.)
    //**
    //** @param(ATypeIndex Index in ATypes of the type selected at first.)
    //**
    //** @param(AInitialDir Folder to start in.)
    //**
    //** @param(AFileName File name to suggest; may be empty.)
    //**
    //** @param(ADone Called with the chosen full path and the index of the chosen type; with an
    //** empty string and -1 when cancelled.)
    /// <summary>Lets the user choose a file name to save to.</summary>
    /// <param name="ATitle">Title of the dialog.</param>
    /// <param name="ATypes">File types offered.</param>
    /// <param name="ATypeIndex">Index in ATypes of the type selected at first.</param>
    /// <param name="AInitialDir">Folder to start in.</param>
    /// <param name="AFileName">File name to suggest; may be empty.</param>
    /// <param name="ADone">Called with the chosen full path and the index of the chosen type;
    /// with an empty string and -1 when cancelled.</param>
    /// <remarks>Replacing an existing file is not confirmed here, so that the caller can first
    /// adjust the name, for example its extension, and then use <see
    /// cref="Confirm"/>.</remarks>
    class procedure SaveFile(const ATitle: string; const ATypes: TArray<TFileType>;
      ATypeIndex: Integer; const AInitialDir, AFileName: string;
      const ADone: TProc<string, Integer>); static;
    //** @abstract(Lets the user choose a folder.)
    //**
    //** @param(ATitle Title of the dialog.)
    //**
    //** @param(AInitialDir Folder to start in.)
    //**
    //** @param(ADone Called with the chosen folder, or an empty string when cancelled.)
    /// <summary>Lets the user choose a folder.</summary>
    /// <param name="ATitle">Title of the dialog.</param>
    /// <param name="AInitialDir">Folder to start in.</param>
    /// <param name="ADone">Called with the chosen folder, or an empty string when
    /// cancelled.</param>
    class procedure SelectFolder(const ATitle, AInitialDir: string;
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

{$ELSE}

// Mobile: a file browser built in code, as FMX has no file dialogs there

type
  TBrowseMode = (bmOpen, bmOpenMany, bmSave, bmFolder);

  TFileBrowserForm = class(TForm)
  private
    FMode: TBrowseMode;
    FTypes: TArray<TFileType>;
    FDir: string;
    FResult: string;
    FChosen: TStringList;
    FPathLabel: TLabel;
    FList: TListBox;
    FNameEdit: TEdit;
    FTypeBox: TComboBox;
    procedure Build(const ATitle: string; ATypeIndex: Integer; const AFileName: string);
    procedure AddLocation(AParent: TFmxObject; const ACaption, APath: string);
    procedure Fill;
    procedure Navigate(const ADir: string);
    function CurrentType: Integer;
    procedure UpClick(Sender: TObject);
    procedure LocationClick(Sender: TObject);
    procedure TypeChange(Sender: TObject);
    procedure ItemClick(const Sender: TCustomListBox; const AItem: TListBoxItem);
    procedure OKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    function ItemText(const APath: string): string;
  public
    destructor Destroy; override;
    constructor CreateBrowser(AMode: TBrowseMode; const ATitle: string;
      const ATypes: TArray<TFileType>; ATypeIndex: Integer;
      const AInitialDir, AFileName: string);
  end;

constructor TFileBrowserForm.CreateBrowser(AMode: TBrowseMode; const ATitle: string;
  const ATypes: TArray<TFileType>; ATypeIndex: Integer; const AInitialDir, AFileName: string);
begin
  inherited CreateNew(Application);
  FMode := AMode;
  FChosen := TStringList.Create;
  FTypes := ATypes;
  OnClose := FormClose;
  Build(ATitle, ATypeIndex, AFileName);
  if (AInitialDir <> '') and TDirectory.Exists(AInitialDir) then
    Navigate(AInitialDir)
  else
    Navigate(TPlatformDialogs.DefaultFolder);
end;

destructor TFileBrowserForm.Destroy;
begin
  FChosen.Free;
  inherited;
end;

// A file's text in the list: ticked files of a multiple choice start with a tick
function TFileBrowserForm.ItemText(const APath: string): string;
begin
  Result := TPath.GetFileName(APath);
  if FMode = bmOpenMany then
    if FChosen.IndexOf(APath) >= 0 then
      Result := #$2713' ' + Result
    else
      Result := '    ' + Result;
end;

procedure TFileBrowserForm.AddLocation(AParent: TFmxObject; const ACaption, APath: string);
var
  LButton: TButton;
begin
  if (APath = '') or not TDirectory.Exists(APath) then
    Exit;
  LButton := TButton.Create(Self);
  LButton.Parent := AParent;
  LButton.Align := TAlignLayout.Left;
  LButton.Margins.Left := 4;
  LButton.Width := 100;
  LButton.Position.X := 1000 + AParent.ChildrenCount;
  LButton.Text := ACaption;
  LButton.TagString := APath;
  LButton.OnClick := LocationClick;
end;

procedure TFileBrowserForm.Build(const ATitle: string; ATypeIndex: Integer;
  const AFileName: string);
var
  LTop, LBottom, LRow: TLayout;
  LTitle: TLabel;
  LButton: TButton;
  LType: TFileType;
begin
  Caption := ATitle;

  LTop := TLayout.Create(Self);
  LTop.Parent := Self;
  LTop.Align := TAlignLayout.Top;
  LTop.Height := 116;
  LTop.Padding.Rect := TRectF.Create(8, 8, 8, 4);

  LTitle := TLabel.Create(Self);
  LTitle.Parent := LTop;
  LTitle.Align := TAlignLayout.Top;
  LTitle.Height := 28;
  LTitle.Text := ATitle;
  LTitle.StyledSettings := LTitle.StyledSettings - [TStyledSetting.Style];
  LTitle.TextSettings.Font.Style := [TFontStyle.fsBold];

  LRow := TLayout.Create(Self);
  LRow.Parent := LTop;
  LRow.Align := TAlignLayout.Top;
  LRow.Position.Y := 100;
  LRow.Height := 40;
  LRow.Padding.Rect := TRectF.Create(0, 4, 0, 4);

  LButton := TButton.Create(Self);
  LButton.Parent := LRow;
  LButton.Align := TAlignLayout.Left;
  LButton.Width := 60;
  LButton.Text := 'Up';
  LButton.OnClick := UpClick;

  AddLocation(LRow, 'App files', TPath.GetDocumentsPath);
  if TPath.GetSharedDocumentsPath <> TPath.GetDocumentsPath then
    AddLocation(LRow, 'Documents', TPath.GetSharedDocumentsPath);
  AddLocation(LRow, 'Downloads', TPath.GetSharedDownloadsPath);

  FPathLabel := TLabel.Create(Self);
  FPathLabel.Parent := LTop;
  FPathLabel.Align := TAlignLayout.Client;
  FPathLabel.Trimming := TTextTrimming.Character;

  LBottom := TLayout.Create(Self);
  LBottom.Parent := Self;
  LBottom.Align := TAlignLayout.Bottom;
  LBottom.Padding.Rect := TRectF.Create(8, 4, 8, 8);
  LBottom.Height := 48;

  if FMode = bmSave then
  begin
    LBottom.Height := LBottom.Height + 40;
    FNameEdit := TEdit.Create(Self);
    FNameEdit.Parent := LBottom;
    FNameEdit.Align := TAlignLayout.Top;
    FNameEdit.Margins.Bottom := 6;
    FNameEdit.Text := AFileName;
    FNameEdit.TextPrompt := 'File name';
  end;

  if (FMode <> bmFolder) and (Length(FTypes) > 0) then
  begin
    LBottom.Height := LBottom.Height + 40;
    FTypeBox := TComboBox.Create(Self);
    FTypeBox.Parent := LBottom;
    FTypeBox.Align := TAlignLayout.Top;
    FTypeBox.Position.Y := 100;
    FTypeBox.Margins.Bottom := 6;
    for LType in FTypes do
      FTypeBox.Items.Add(LType.Description);
    if (ATypeIndex >= 0) and (ATypeIndex < Length(FTypes)) then
      FTypeBox.ItemIndex := ATypeIndex
    else
      FTypeBox.ItemIndex := 0;
    FTypeBox.OnChange := TypeChange;
  end;

  LRow := TLayout.Create(Self);
  LRow.Parent := LBottom;
  LRow.Align := TAlignLayout.Client;

  LButton := TButton.Create(Self);
  LButton.Parent := LRow;
  LButton.Align := TAlignLayout.Right;
  LButton.Width := 100;
  LButton.Position.X := 2000;
  case FMode of
    bmOpen, bmOpenMany: LButton.Text := 'Open';
    bmSave: LButton.Text := 'Save';
  else
    LButton.Text := 'Use folder';
  end;
  LButton.OnClick := OKClick;

  LButton := TButton.Create(Self);
  LButton.Parent := LRow;
  LButton.Align := TAlignLayout.Right;
  LButton.Width := 100;
  LButton.Position.X := 1000;
  LButton.Margins.Right := 8;
  LButton.Text := 'Cancel';
  LButton.ModalResult := mrCancel;

  FList := TListBox.Create(Self);
  FList.Parent := Self;
  FList.Align := TAlignLayout.Client;
  FList.Margins.Rect := TRectF.Create(8, 0, 8, 0);
  FList.OnItemClick := ItemClick;
end;

function TFileBrowserForm.CurrentType: Integer;
begin
  if Assigned(FTypeBox) then
    Result := FTypeBox.ItemIndex
  else
    Result := -1;
end;

procedure TFileBrowserForm.Fill;
var
  LEntries: TArray<string>;
  LEntry: string;
  LItem: TListBoxItem;
  LType: Integer;
begin
  FPathLabel.Text := FDir;
  LType := CurrentType;

  FList.BeginUpdate;
  try
    FList.Clear;

    try
      LEntries := TDirectory.GetDirectories(FDir);
    except
      LEntries := nil; // no access
    end;
    TArray.Sort<string>(LEntries, TComparer<string>.Construct(
      function(const A, B: string): Integer
      begin
        Result := CompareText(A, B);
      end));
    for LEntry in LEntries do
    begin
      LItem := TListBoxItem.Create(FList);
      LItem.Parent := FList;
      LItem.Text := TPath.GetFileName(LEntry) + '/';
      LItem.TagString := LEntry;
      LItem.Tag := 1; // folder
    end;

    if FMode = bmFolder then
      Exit;

    try
      LEntries := TDirectory.GetFiles(FDir);
    except
      LEntries := nil;
    end;
    TArray.Sort<string>(LEntries, TComparer<string>.Construct(
      function(const A, B: string): Integer
      begin
        Result := CompareText(A, B);
      end));
    for LEntry in LEntries do
      if (LType < 0) or FTypes[LType].Matches(LEntry) then
      begin
        LItem := TListBoxItem.Create(FList);
        LItem.Parent := FList;
        LItem.Text := ItemText(LEntry);
        LItem.TagString := LEntry;
        LItem.Tag := 0; // file
      end;
  finally
    FList.EndUpdate;
  end;
end;

procedure TFileBrowserForm.Navigate(const ADir: string);
begin
  FDir := ExcludeTrailingPathDelimiter(ADir);
  if FDir = '' then
    FDir := ADir;
  Fill;
end;

procedure TFileBrowserForm.UpClick(Sender: TObject);
var
  LParent: string;
begin
  LParent := TPath.GetDirectoryName(FDir);
  if (LParent <> '') and (LParent <> FDir) and TDirectory.Exists(LParent) then
    Navigate(LParent);
end;

procedure TFileBrowserForm.LocationClick(Sender: TObject);
begin
  Navigate((Sender as TButton).TagString);
end;

procedure TFileBrowserForm.TypeChange(Sender: TObject);
begin
  Fill;
end;

procedure TFileBrowserForm.ItemClick(const Sender: TCustomListBox; const AItem: TListBoxItem);
begin
  if AItem.Tag = 1 then
    Navigate(AItem.TagString)
  else if FMode = bmOpen then
  begin
    FResult := AItem.TagString;
    ModalResult := mrOk;
  end
  else if FMode = bmOpenMany then
  begin
    // Tapping ticks or unticks; ticks are kept while browsing other folders
    if FChosen.IndexOf(AItem.TagString) >= 0 then
      FChosen.Delete(FChosen.IndexOf(AItem.TagString))
    else
      FChosen.Add(AItem.TagString);
    AItem.Text := ItemText(AItem.TagString);
  end
  else if FMode = bmSave then
    FNameEdit.Text := TPath.GetFileName(AItem.TagString);
end;

procedure TFileBrowserForm.OKClick(Sender: TObject);
begin
  case FMode of
    bmOpen:
      if Assigned(FList.Selected) and (FList.Selected.Tag = 0) then
        FResult := FList.Selected.TagString
      else
        Exit; // tap a file to open it
    bmOpenMany:
      if FChosen.Count = 0 then
        Exit; // tap files to tick them first
    bmSave:
      if Trim(FNameEdit.Text) <> '' then
        FResult := TPath.Combine(FDir, Trim(FNameEdit.Text))
      else
        Exit;
    bmFolder:
      FResult := FDir;
  end;
  ModalResult := mrOk;
end;

procedure TFileBrowserForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
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

class procedure TPlatformDialogs.OpenFile(const ATitle: string; const ATypes: TArray<TFileType>;
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
        ADone(LForm.FResult)
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

class procedure TPlatformDialogs.OpenFiles(const ATitle: string; const ATypes: TArray<TFileType>;
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
        ADone(LForm.FChosen.ToStringArray)
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

class procedure TPlatformDialogs.SaveFile(const ATitle: string; const ATypes: TArray<TFileType>;
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
        ADone(LForm.FResult, LForm.CurrentType)
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

class procedure TPlatformDialogs.SelectFolder(const ATitle, AInitialDir: string;
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
        ADone(LForm.FResult)
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
