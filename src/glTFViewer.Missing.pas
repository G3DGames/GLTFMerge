//** @abstract(Dialog that helps the user find the external media files a glTF document is
//** missing.)
//**
//** @link(TMissingFilesForm) lists the buffer and image files that could not be read. "Search
//** folder..." looks for all of them in a folder and its sub-folders; "Locate file..." picks
//** the file for one entry and then looks for the rest in the same folder. Found files are
//** loaded into the document's objects; the uris in the glTF are not changed.
//**
//** The form is built in code, so the unit needs no .fmx file.
unit glTFViewer.Missing;

{
  Dialog that helps the user find the external media files a glTF document is
  missing.

  TMissingFilesForm lists the buffer and image files that could not be read.
  "Search folder..." looks for all of them in a folder and its sub-folders;
  "Locate file..." picks the file for one entry and then looks for the rest in
  the same folder. Found files are loaded into the document's objects; the
  uris in the glTF are not changed.

  The form is built in code, so the unit needs no .fmx file.
}

interface

uses
  System.SysUtils, System.Types, System.Classes, System.UITypes, System.IOUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Layouts, FMX.ListBox,
  FMX.Controls.Presentation,

  glTF.Document;

type
  //** @abstract(Modal dialog listing a document's missing media files, with ways to find them.)
  //**
  //** Use @link(Execute) rather than creating it directly. Must be used on the main thread.
  /// <summary>Modal dialog listing a document's missing media files, with ways to find
  /// them.</summary>
  /// <remarks>Use <see cref="Execute"/> rather than creating it directly. Must be used on the
  /// main thread.</remarks>
  TMissingFilesForm = class(TForm)
  private
    FDoc: TglTFDocument;
    FLog: TProc<string>;
    FMissing: TArray<TglTFMissingResource>;
    FLastDir: string;
    FInfo: TLabel;
    FStatus: TLabel;
    FList: TListBox;
    FBtnFolder: TButton;
    FBtnFile: TButton;
    FBtnClose: TButton;
    procedure BuildControls(const AContext: string);
    procedure RefreshList;
    procedure SetStatus(const AText: string);
    function IsLoaded(const AItem: TglTFMissingResource): Boolean;
    procedure LogLocated(const ABefore: TArray<TglTFMissingResource>; const AWhere: string);
    procedure FolderClick(Sender: TObject);
    procedure FileClick(Sender: TObject);
    procedure ListChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FileChosen(const AItem: TglTFMissingResource; AItemIndex: Integer;
      const AFileName: string);
  public
    //** @abstract(Creates the dialog for a document.)
    //**
    //** @param(AOwner Owner of the form.)
    //**
    //** @param(ADoc The document whose missing files are listed; not owned.)
    //**
    //** @param(AContext First line of the explanation at the top, for example why the dialog is
    //** shown now.)
    //**
    //** @param(ALog Receives one line for every file found; may be nil.)
    /// <summary>Creates the dialog for a document.</summary>
    /// <param name="AOwner">Owner of the form.</param>
    /// <param name="ADoc">The document whose missing files are listed; not owned.</param>
    /// <param name="AContext">First line of the explanation at the top, for example why the
    /// dialog is shown now.</param>
    /// <param name="ALog">Receives one line for every file found; may be nil.</param>
    constructor CreateFor(AOwner: TComponent; ADoc: TglTFDocument;
      const AContext: string; const ALog: TProc<string>);

    //** @abstract(Shows the dialog when a document has missing files.)
    //**
    //** The dialog frees itself when it closes. It does not block: on the desktop and on mobile
    //** alike, code that must run after it goes in ADone. When nothing is missing, no dialog is
    //** shown and ADone is called at once. Call it on the main thread.
    //**
    //** @param(ADoc The document; files found are loaded into its objects.)
    //**
    //** @param(AContext First line of the explanation, for example why the dialog is shown
    //** now.)
    //**
    //** @param(ALog Receives one line for every file found; may be nil.)
    //**
    //** @param(ADone Called when the dialog has closed, with how many files are still missing;
    //** may be nil.)
    /// <summary>Shows the dialog when a document has missing files.</summary>
    /// <param name="ADoc">The document; files found are loaded into its objects.</param>
    /// <param name="AContext">First line of the explanation, for example why the dialog is
    /// shown now.</param>
    /// <param name="ALog">Receives one line for every file found; may be nil.</param>
    /// <param name="ADone">Called when the dialog has closed, with how many files are still
    /// missing; may be nil.</param>
    /// <remarks>The dialog frees itself when it closes. It does not block: on the desktop and
    /// on mobile alike, code that must run after it goes in ADone. When nothing is missing, no
    /// dialog is shown and ADone is called at once. Call it on the main thread.</remarks>
    class procedure Execute(ADoc: TglTFDocument; const AContext: string;
      const ALog: TProc<string>; const ADone: TProc<Integer> = nil);
  end;

implementation

uses
  glTFViewer.Dialogs;

{ TMissingFilesForm }

class procedure TMissingFilesForm.Execute(ADoc: TglTFDocument; const AContext: string;
  const ALog: TProc<string>; const ADone: TProc<Integer>);
var
  LForm: TMissingFilesForm;
begin
  if not ADoc.HasMissingResources then
  begin
    if Assigned(ADone) then
      ADone(0);
    Exit;
  end;

  // ShowModal with a result procedure works on every platform, including
  // Android, where a blocking ShowModal is not available. The form frees
  // itself when it closes (FormClose)
  LForm := TMissingFilesForm.CreateFor(Application, ADoc, AContext, ALog);
  LForm.ShowModal(
    procedure(AResult: TModalResult)
    begin
      if Assigned(ADone) then
        ADone(Length(ADoc.MissingResources));
    end);
end;

procedure TMissingFilesForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

constructor TMissingFilesForm.CreateFor(AOwner: TComponent; ADoc: TglTFDocument;
  const AContext: string; const ALog: TProc<string>);
begin
  inherited CreateNew(AOwner);
  OnClose := FormClose;
  FDoc := ADoc;
  FLog := ALog;
  FLastDir := ADoc.BaseDirectory;
  BuildControls(AContext);
  RefreshList;
end;

procedure TMissingFilesForm.BuildControls(const AContext: string);
var
  LButtons: TLayout;
begin
  Caption := 'Missing media files';
  Width := 720;
  Height := 400;
  Position := TFormPosition.MainFormCenter;
  BorderIcons := [TBorderIcon.biSystemMenu];

  FInfo := TLabel.Create(Self);
  FInfo.Parent := Self;
  FInfo.Align := TAlignLayout.Top;
  FInfo.Margins.Rect := TRectF.Create(10, 10, 10, 4);
  FInfo.Height := 54;
  FInfo.WordWrap := True;
  FInfo.VertTextAlign := TTextAlign.Leading;
  FInfo.Text := AContext + sLineBreak +
    'Search a folder, or select an entry and locate its file. ' +
    'Files that stay missing are saved as uri references only.';

  LButtons := TLayout.Create(Self);
  LButtons.Parent := Self;
  LButtons.Align := TAlignLayout.Bottom;
  LButtons.Height := 46;
  LButtons.Padding.Rect := TRectF.Create(10, 8, 10, 10);

  FBtnFolder := TButton.Create(Self);
  FBtnFolder.Parent := LButtons;
  FBtnFolder.Align := TAlignLayout.Left;
  FBtnFolder.Width := 130;
  FBtnFolder.Text := 'Search folder...';
  FBtnFolder.OnClick := FolderClick;

  FBtnFile := TButton.Create(Self);
  FBtnFile.Parent := LButtons;
  FBtnFile.Align := TAlignLayout.Left;
  FBtnFile.Margins.Left := 8;
  FBtnFile.Width := 130;
  FBtnFile.Text := 'Locate file...';
  FBtnFile.OnClick := FileClick;

  FBtnClose := TButton.Create(Self);
  FBtnClose.Parent := LButtons;
  FBtnClose.Align := TAlignLayout.Right;
  FBtnClose.Width := 100;
  FBtnClose.Text := 'Continue';
  FBtnClose.ModalResult := mrOk;

  FStatus := TLabel.Create(Self);
  FStatus.Parent := Self;
  FStatus.Align := TAlignLayout.Bottom;
  FStatus.Margins.Rect := TRectF.Create(10, 2, 10, 0);
  FStatus.Height := 22;

  FList := TListBox.Create(Self);
  FList.Parent := Self;
  FList.Align := TAlignLayout.Client;
  FList.Margins.Rect := TRectF.Create(10, 4, 10, 4);
  FList.OnChange := ListChange;
end;

procedure TMissingFilesForm.RefreshList;
var
  LItem: TglTFMissingResource;
begin
  FMissing := FDoc.MissingResources;

  FList.BeginUpdate;
  try
    FList.Clear;
    for LItem in FMissing do
      FList.Items.Add(Format('%s  -  expected at %s', [LItem.Description, LItem.ExpectedPath]));
  finally
    FList.EndUpdate;
  end;

  if Length(FMissing) > 0 then
    FList.ItemIndex := 0;

  FBtnFolder.Enabled := Length(FMissing) > 0;
  FBtnFile.Enabled := FList.ItemIndex >= 0;
  if Length(FMissing) = 0 then
  begin
    SetStatus('All files located.');
    FBtnClose.Text := 'Close';
  end;
end;

procedure TMissingFilesForm.SetStatus(const AText: string);
begin
  FStatus.Text := AText;
end;

function TMissingFilesForm.IsLoaded(const AItem: TglTFMissingResource): Boolean;
begin
  if AItem.Kind = rkBuffer then
    Result := FDoc.Root.Buffers[AItem.Index].Data <> nil
  else
    Result := FDoc.Root.Images[AItem.Index].Data <> nil;
end;

procedure TMissingFilesForm.LogLocated(const ABefore: TArray<TglTFMissingResource>;
  const AWhere: string);
var
  LItem: TglTFMissingResource;
begin
  if not Assigned(FLog) then
    Exit;
  for LItem in ABefore do
    if IsLoaded(LItem) then
      FLog(Format('Located %s in %s', [LItem.Description, AWhere]));
end;

procedure TMissingFilesForm.ListChange(Sender: TObject);
begin
  FBtnFile.Enabled := FList.ItemIndex >= 0;
end;

procedure TMissingFilesForm.FolderClick(Sender: TObject);
begin
  TPlatformDialogs.SelectFolder('Folder containing the missing files', FLastDir,
    procedure(ADir: string)
    var
      LFound: Integer;
      LBefore: TArray<TglTFMissingResource>;
    begin
      if ADir = '' then
        Exit;
      FLastDir := ADir;

      LBefore := FMissing;
      LFound := FDoc.SearchMissingResources(ADir, True);
      LogLocated(LBefore, ADir);
      RefreshList;

      if Length(FMissing) > 0 then
        SetStatus(Format('Found %d file(s) in %s; %d still missing.', [LFound, ADir, Length(FMissing)]));
    end);
end;

procedure TMissingFilesForm.FileClick(Sender: TObject);
var
  LItem: TglTFMissingResource;
  LItemIndex: Integer;
  LTypes: TArray<TFileType>;
begin
  LItemIndex := FList.ItemIndex;
  if (LItemIndex < 0) or (LItemIndex > High(FMissing)) then
    Exit;
  LItem := FMissing[LItemIndex];

  if LItem.Kind = rkImage then
    LTypes := [TFileType.Create('Images', ['.png', '.jpg', '.jpeg', '.webp', '.ktx2']),
               TFileType.Create('All files', ['*'])]
  else
    LTypes := [TFileType.Create('Binary buffers', ['.bin']), TFileType.Create('All files', ['*'])];

  TPlatformDialogs.OpenFile('Locate ' + LItem.Description, LTypes, FLastDir, LItem.FileName,
    procedure(AFileName: string)
    begin
      if AFileName <> '' then
        FileChosen(LItem, LItemIndex, AFileName);
    end);
end;

procedure TMissingFilesForm.FileChosen(const AItem: TglTFMissingResource; AItemIndex: Integer;
  const AFileName: string);
var
  LBefore: TArray<TglTFMissingResource>;
  LFound: Integer;
begin
  LBefore := FMissing;
  try
    FDoc.SupplyResourceFile(AItem.Kind, AItem.Index, AFileName);
  except
    on E: Exception do
    begin
      SetStatus('Not used: ' + E.Message);
      Exit;
    end;
  end;

  if Assigned(FLog) then
    FLog(Format('Located %s: %s', [AItem.Description, AFileName]));
  if AItemIndex <= High(LBefore) then
    Delete(LBefore, AItemIndex, 1); // logged above

  // The other missing files are often in the same folder
  FLastDir := ExtractFileDir(AFileName);
  LFound := FDoc.SearchMissingResources(FLastDir, False);
  LogLocated(LBefore, FLastDir);
  RefreshList;
  if Length(FMissing) > 0 then
  begin
    if LFound > 0 then
      SetStatus(Format('Located %s, and %d more in the same folder; %d still missing.',
        [AItem.Description, LFound, Length(FMissing)]))
    else
      SetStatus(Format('Located %s; %d still missing.', [AItem.Description, Length(FMissing)]));
  end;
end;

end.
