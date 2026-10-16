//** @abstract(The file browser shown on iOS and Android, which have no FireMonkey file dialogs.)
//**
//** @link(TFileBrowserForm) lists the folders and files of one folder at a time. Up goes to the
//** parent folder; App files, Documents and Downloads go to those folders and are shown only
//** where they exist. Depending on its @link(TBrowseMode) it opens one file, ticks several,
//** asks for a name to save under, or chooses a folder. glTFViewer.Dialogs shows it; use
//** TPlatformDialogs rather than this form.
//**
//** The form is designed in glTFViewer.FileBrowser.fmx. The name box and the type list are
//** hidden in the modes that do not use them.
unit glTFViewer.FileBrowser;

{
  The file browser shown on iOS and Android, which have no FireMonkey file
  dialogs.

  TFileBrowserForm lists the folders and files of one folder at a time. Up
  goes to the parent folder; App files, Documents and Downloads go to those
  folders and are shown only where they exist. Depending on its TBrowseMode it
  opens one file, ticks several, asks for a name to save under, or chooses a
  folder. glTFViewer.Dialogs shows it; use TPlatformDialogs rather than this
  form.

  The form is designed in glTFViewer.FileBrowser.fmx. The name box and the
  type list are hidden in the modes that do not use them.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.IOUtils,
  System.Generics.Collections, System.Generics.Defaults,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Layouts, FMX.ListBox,
  FMX.Edit, FMX.Controls.Presentation,

  glTFViewer.Dialogs;

type
  //** @abstract(What the file browser is for.)
  /// <summary>What the file browser is for.</summary>
  TBrowseMode = (
    //** @abstract(Open one file: tapping a file chooses it.)
    /// <summary>Open one file: tapping a file chooses it.</summary>
    bmOpen,

    //** @abstract(Open several files: tapping a file ticks or unticks it.)
    /// <summary>Open several files: tapping a file ticks or unticks it.</summary>
    bmOpenMany,

    //** @abstract(Save: a file name is typed, or taken from a file tapped.)
    /// <summary>Save: a file name is typed, or taken from a file tapped.</summary>
    bmSave,

    //** @abstract(Choose the folder shown.)
    /// <summary>Choose the folder shown.</summary>
    bmFolder);

  //** @abstract(A file browser for platforms without file dialogs.)
  //**
  //** Create it with @link(CreateBrowser) and show it with ShowModal and a result procedure;
  //** it frees itself when it closes. Must be used on the main thread.
  /// <summary>A file browser for platforms without file dialogs.</summary>
  /// <remarks>Create it with <see cref="CreateBrowser"/> and show it with ShowModal and a
  /// result procedure; it frees itself when it closes. Must be used on the main
  /// thread.</remarks>
  TFileBrowserForm = class(TForm)
    //** @abstract(The title, the folder buttons and the path, at the top.)
    /// <summary>The title, the folder buttons and the path, at the top.</summary>
    layTop: TLayout;

    //** @abstract(What the browser is asking for.)
    /// <summary>What the browser is asking for.</summary>
    lblTitle: TLabel;

    //** @abstract(Holds Up and the buttons of the usual folders.)
    /// <summary>Holds Up and the buttons of the usual folders.</summary>
    layLocations: TLayout;

    //** @abstract(Goes to the parent folder.)
    /// <summary>Goes to the parent folder.</summary>
    btnUp: TButton;

    //** @abstract(Goes to the app's own documents folder.)
    /// <summary>Goes to the app's own documents folder.</summary>
    btnAppFiles: TButton;

    //** @abstract(Goes to the shared Documents folder; hidden when it is the app's own.)
    /// <summary>Goes to the shared Documents folder; hidden when it is the app's
    /// own.</summary>
    btnDocuments: TButton;

    //** @abstract(Goes to the shared Downloads folder.)
    /// <summary>Goes to the shared Downloads folder.</summary>
    btnDownloads: TButton;

    //** @abstract(The folder shown.)
    /// <summary>The folder shown.</summary>
    lblPath: TLabel;

    //** @abstract(The folders, then the files of the type chosen.)
    /// <summary>The folders, then the files of the type chosen.</summary>
    lstFiles: TListBox;

    //** @abstract(The name box, the type list and the buttons, at the bottom.)
    /// <summary>The name box, the type list and the buttons, at the bottom.</summary>
    layBottom: TLayout;

    //** @abstract(The file name to save under; shown when saving.)
    /// <summary>The file name to save under; shown when saving.</summary>
    edtName: TEdit;

    //** @abstract(The file types; hidden when choosing a folder.)
    /// <summary>The file types; hidden when choosing a folder.</summary>
    cbType: TComboBox;

    //** @abstract(Holds the OK and Cancel buttons.)
    /// <summary>Holds the OK and Cancel buttons.</summary>
    layOKCancel: TLayout;

    //** @abstract(Closes the browser without a choice.)
    /// <summary>Closes the browser without a choice.</summary>
    btnCancel: TButton;

    //** @abstract(Open, Save or Use folder, depending on the mode.)
    /// <summary>Open, Save or Use folder, depending on the mode.</summary>
    btnOK: TButton;

    //** @abstract(Goes to the parent folder.)
    //**
    //** @param(Sender The button.)
    /// <summary>Goes to the parent folder.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnUpClick(Sender: TObject);

    //** @abstract(Goes to the folder in the button's TagString.)
    //**
    //** @param(Sender The button.)
    /// <summary>Goes to the folder in the button's TagString.</summary>
    /// <param name="Sender">The button.</param>
    procedure LocationClick(Sender: TObject);

    //** @abstract(Lists the files of the type chosen.)
    //**
    //** @param(Sender The type list.)
    /// <summary>Lists the files of the type chosen.</summary>
    /// <param name="Sender">The type list.</param>
    procedure cbTypeChange(Sender: TObject);

    //** @abstract(Opens a folder tapped, or chooses, ticks or names a file tapped.)
    //**
    //** @param(Sender The list.)
    //**
    //** @param(AItem The row tapped.)
    /// <summary>Opens a folder tapped, or chooses, ticks or names a file tapped.</summary>
    /// <param name="Sender">The list.</param>
    /// <param name="AItem">The row tapped.</param>
    procedure lstFilesItemClick(const Sender: TCustomListBox; const AItem: TListBoxItem);

    //** @abstract(Closes the browser with mrOk once a choice is made.)
    //**
    //** @param(Sender The button.)
    /// <summary>Closes the browser with mrOk once a choice is made.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnOKClick(Sender: TObject);

    //** @abstract(Frees the form when it closes.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Set to caFree.)
    /// <summary>Frees the form when it closes.</summary>
    /// <param name="Sender">The form.</param>
    /// <param name="Action">Set to caFree.</param>
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FMode: TBrowseMode;
    FTypes: TArray<TFileType>;
    FDir: string;
    FResult: string;
    FChosen: TStringList;
    procedure Prepare(const ATitle: string; ATypeIndex: Integer; const AFileName: string);
    procedure SetLocation(AButton: TButton; const APath: string);
    procedure Fill;
    procedure Navigate(const ADir: string);
    function GetTypeIndex: Integer;
    function GetChosen: TArray<string>;
    function ItemText(const APath: string): string;
  public
    //** @abstract(Creates the browser.)
    //**
    //** @param(AMode What the browser is for.)
    //**
    //** @param(ATitle What it asks for, shown at the top.)
    //**
    //** @param(ATypes The file types offered; empty to list every file.)
    //**
    //** @param(ATypeIndex The type chosen at first.)
    //**
    //** @param(AInitialDir The folder shown at first; the default folder when it does not
    //** exist.)
    //**
    //** @param(AFileName The file name offered when saving.)
    /// <summary>Creates the browser.</summary>
    /// <param name="AMode">What the browser is for.</param>
    /// <param name="ATitle">What it asks for, shown at the top.</param>
    /// <param name="ATypes">The file types offered; empty to list every file.</param>
    /// <param name="ATypeIndex">The type chosen at first.</param>
    /// <param name="AInitialDir">The folder shown at first; the default folder when it does
    /// not exist.</param>
    /// <param name="AFileName">The file name offered when saving.</param>
    constructor CreateBrowser(AMode: TBrowseMode; const ATitle: string;
      const ATypes: TArray<TFileType>; ATypeIndex: Integer;
      const AInitialDir, AFileName: string);

    //** @abstract(Frees the browser.)
    /// <summary>Frees the browser.</summary>
    destructor Destroy; override;

    //** @abstract(The file or folder chosen, after mrOk in the modes bmOpen, bmSave and
    //** bmFolder.)
    /// <summary>The file or folder chosen, after mrOk in the modes bmOpen, bmSave and
    /// bmFolder.</summary>
    property ResultPath: string read FResult;

    //** @abstract(The files ticked, after mrOk in the mode bmOpenMany.)
    /// <summary>The files ticked, after mrOk in the mode bmOpenMany.</summary>
    property Chosen: TArray<string> read GetChosen;

    //** @abstract(The index of the file type chosen; -1 when no types are offered.)
    /// <summary>The index of the file type chosen; -1 when no types are offered.</summary>
    property TypeIndex: Integer read GetTypeIndex;
  end;

implementation

{$R *.fmx}

const
  // Heights of the bottom bar's parts
  BUTTONS_HEIGHT = 48;
  ROW_HEIGHT = 40;

constructor TFileBrowserForm.CreateBrowser(AMode: TBrowseMode; const ATitle: string;
  const ATypes: TArray<TFileType>; ATypeIndex: Integer; const AInitialDir, AFileName: string);
begin
  inherited Create(Application);
  FMode := AMode;
  FChosen := TStringList.Create;
  FTypes := ATypes;
  Prepare(ATitle, ATypeIndex, AFileName);
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

procedure TFileBrowserForm.Prepare(const ATitle: string; ATypeIndex: Integer;
  const AFileName: string);
var
  LType: TFileType;
  LHeight: Single;
begin
  Caption := ATitle;
  lblTitle.Text := ATitle;

  SetLocation(btnAppFiles, TPath.GetDocumentsPath);
  if TPath.GetSharedDocumentsPath <> TPath.GetDocumentsPath then
    SetLocation(btnDocuments, TPath.GetSharedDocumentsPath)
  else
    btnDocuments.Visible := False;
  SetLocation(btnDownloads, TPath.GetSharedDownloadsPath);

  // The bottom bar has the parts the mode uses
  LHeight := BUTTONS_HEIGHT;
  edtName.Visible := FMode = bmSave;
  if edtName.Visible then
  begin
    edtName.Text := AFileName;
    LHeight := LHeight + ROW_HEIGHT;
  end;
  cbType.Visible := (FMode <> bmFolder) and (Length(FTypes) > 0);
  if cbType.Visible then
  begin
    for LType in FTypes do
      cbType.Items.Add(LType.Description);
    if (ATypeIndex >= 0) and (ATypeIndex < Length(FTypes)) then
      cbType.ItemIndex := ATypeIndex
    else
      cbType.ItemIndex := 0;
    LHeight := LHeight + ROW_HEIGHT;
  end;
  layBottom.Height := LHeight;

  case FMode of
    bmOpen, bmOpenMany: btnOK.Text := 'Open';
    bmSave: btnOK.Text := 'Save';
  else
    btnOK.Text := 'Use folder';
  end;
end;

procedure TFileBrowserForm.SetLocation(AButton: TButton; const APath: string);
begin
  // Shown only for folders that exist here
  AButton.Visible := (APath <> '') and TDirectory.Exists(APath);
  AButton.TagString := APath;
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

function TFileBrowserForm.GetTypeIndex: Integer;
begin
  if cbType.Visible then
    Result := cbType.ItemIndex
  else
    Result := -1;
end;

function TFileBrowserForm.GetChosen: TArray<string>;
begin
  Result := FChosen.ToStringArray;
end;

procedure TFileBrowserForm.Fill;
var
  LEntries: TArray<string>;
  LEntry: string;
  LItem: TListBoxItem;
  LType: Integer;
begin
  lblPath.Text := FDir;
  LType := TypeIndex;

  lstFiles.BeginUpdate;
  try
    lstFiles.Clear;

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
      LItem := TListBoxItem.Create(lstFiles);
      LItem.Parent := lstFiles;
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
        LItem := TListBoxItem.Create(lstFiles);
        LItem.Parent := lstFiles;
        LItem.Text := ItemText(LEntry);
        LItem.TagString := LEntry;
        LItem.Tag := 0; // file
      end;
  finally
    lstFiles.EndUpdate;
  end;
end;

procedure TFileBrowserForm.Navigate(const ADir: string);
begin
  FDir := ExcludeTrailingPathDelimiter(ADir);
  if FDir = '' then
    FDir := ADir;
  Fill;
end;

procedure TFileBrowserForm.btnUpClick(Sender: TObject);
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

procedure TFileBrowserForm.cbTypeChange(Sender: TObject);
begin
  if FDir <> '' then // empty while the form is set up
    Fill;
end;

procedure TFileBrowserForm.lstFilesItemClick(const Sender: TCustomListBox;
  const AItem: TListBoxItem);
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
    edtName.Text := TPath.GetFileName(AItem.TagString);
end;

procedure TFileBrowserForm.btnOKClick(Sender: TObject);
begin
  case FMode of
    bmOpen:
      if Assigned(lstFiles.Selected) and (lstFiles.Selected.Tag = 0) then
        FResult := lstFiles.Selected.TagString
      else
        Exit; // tap a file to open it
    bmOpenMany:
      if FChosen.Count = 0 then
        Exit; // tap files to tick them first
    bmSave:
      if Trim(edtName.Text) <> '' then
        FResult := TPath.Combine(FDir, Trim(edtName.Text))
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

end.
