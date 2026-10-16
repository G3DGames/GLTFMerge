//** @abstract(The Bulk Re-Orient dialog: the folders, file types and turn for re-orienting
//** every model in a folder tree.)
//**
//** @link(TBulkOrientForm) asks for the input folder, which models in it to turn @(GLB, glTF
//** or both@), the output folder and the format to save as @(GLB unless changed@), and the
//** turn itself, with the same angles and preset buttons as the Re-Orient tab @(a
//** TglTFOrientFrame@). "Re-Orient models" is enabled only while every field is valid
//** @(see @code(TglTFBulkReorienter.Problem)@); the reason is shown in red otherwise. Cancel
//** or Escape closes the dialog at any time.
//**
//** The choices are remembered in the settings file for the next time, and the Browse buttons
//** remember their folders like every file dialog. The dialog only collects the options: the
//** caller does the work, with TglTFBulkReorienter. The form is designed in
//** glTFViewer.BulkOrient.fmx and frees itself.
unit glTFViewer.BulkOrient;

{
  The Bulk Re-Orient dialog: the folders, file types and turn for
  re-orienting every model in a folder tree.

  TBulkOrientForm asks for the input folder, which models in it to turn (GLB,
  glTF or both), the output folder and the format to save as (GLB unless
  changed), and the turn itself, with the same angles and preset buttons as
  the Re-Orient tab (a TglTFOrientFrame). "Re-Orient models" is enabled only
  while every field is valid (see TglTFBulkReorienter.Problem); the reason is
  shown in red otherwise. Cancel or Escape closes the dialog at any time.

  The choices are remembered in the settings file for the next time, and the
  Browse buttons remember their folders like every file dialog. The dialog
  only collects the options: the caller does the work, with
  TglTFBulkReorienter. The form is designed in glTFViewer.BulkOrient.fmx and
  frees itself.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Layouts, FMX.Edit,
  FMX.Graphics, FMX.Controls.Presentation,

  glTF.Bulk, glTFViewer.Orient;

type
  //** @abstract(Called with the options chosen in the Bulk Re-Orient dialog.)
  //**
  //** @param(AOptions The options; they pass @code(TglTFBulkReorienter.Problem).)
  /// <summary>Called with the options chosen in the Bulk Re-Orient dialog.</summary>
  /// <param name="AOptions">The options; they pass
  /// <c>TglTFBulkReorienter.Problem</c>.</param>
  TBulkOrientDoneProc = reference to procedure(const AOptions: TglTFBulkOptions);

  //** @abstract(Asks for the folders, file types and turn of a bulk re-orientation.)
  //**
  //** Use @link(Execute) rather than creating it directly. Must be used on the main thread.
  /// <summary>Asks for the folders, file types and turn of a bulk
  /// re-orientation.</summary>
  /// <remarks>Use <see cref="Execute"/> rather than creating it directly. Must be used on the
  /// main thread.</remarks>
  TBulkOrientForm = class(TForm)
    //** @abstract(The folders and file types, at the top.)
    /// <summary>The folders and file types, at the top.</summary>
    layFields: TLayout;

    //** @abstract(The row of the input folder.)
    /// <summary>The row of the input folder.</summary>
    layInput: TLayout;

    //** @abstract(The caption of the input folder.)
    /// <summary>The caption of the input folder.</summary>
    lblInput: TLabel;

    //** @abstract(Chooses the input folder.)
    /// <summary>Chooses the input folder.</summary>
    btnInputBrowse: TButton;

    //** @abstract(The folder searched, with its sub-folders.)
    /// <summary>The folder searched, with its sub-folders.</summary>
    edtInput: TEdit;

    //** @abstract(The row of the input file types.)
    /// <summary>The row of the input file types.</summary>
    layInputTypes: TLayout;

    //** @abstract(The caption of the input file types.)
    /// <summary>The caption of the input file types.</summary>
    lblInputTypes: TLabel;

    //** @abstract(Turn .glb files only.)
    /// <summary>Turn .glb files only.</summary>
    rbInputGLB: TRadioButton;

    //** @abstract(Turn .gltf files only.)
    /// <summary>Turn .gltf files only.</summary>
    rbInputGLTF: TRadioButton;

    //** @abstract(Turn both .glb and .gltf files.)
    /// <summary>Turn both .glb and .gltf files.</summary>
    rbInputBoth: TRadioButton;

    //** @abstract(The row of the output folder.)
    /// <summary>The row of the output folder.</summary>
    layOutput: TLayout;

    //** @abstract(The caption of the output folder.)
    /// <summary>The caption of the output folder.</summary>
    lblOutput: TLabel;

    //** @abstract(Chooses the output folder.)
    /// <summary>Chooses the output folder.</summary>
    btnOutputBrowse: TButton;

    //** @abstract(The folder the turned copies go in.)
    /// <summary>The folder the turned copies go in.</summary>
    edtOutput: TEdit;

    //** @abstract(The row of the format saved.)
    /// <summary>The row of the format saved.</summary>
    layOutputType: TLayout;

    //** @abstract(The caption of the format saved.)
    /// <summary>The caption of the format saved.</summary>
    lblOutputType: TLabel;

    //** @abstract(Save as .glb, the default.)
    /// <summary>Save as .glb, the default.</summary>
    rbOutputGLB: TRadioButton;

    //** @abstract(Save as .gltf, with separate image and buffer files.)
    /// <summary>Save as .gltf, with separate image and buffer files.</summary>
    rbOutputGLTF: TRadioButton;

    //** @abstract(How the folders are used.)
    /// <summary>How the folders are used.</summary>
    lblFolders: TLabel;

    //** @abstract(Holds the Re-Orient frame, created at run time.)
    /// <summary>Holds the Re-Orient frame, created at run time.</summary>
    layOrient: TLayout;

    //** @abstract(Why the options cannot be used yet.)
    /// <summary>Why the options cannot be used yet.</summary>
    lblProblem: TLabel;

    //** @abstract(Holds the buttons, at the bottom.)
    /// <summary>Holds the buttons, at the bottom.</summary>
    layButtons: TLayout;

    //** @abstract(Closes the dialog without doing anything.)
    /// <summary>Closes the dialog without doing anything.</summary>
    btnCancel: TButton;

    //** @abstract(Closes the dialog and starts the work; enabled while every field is valid.)
    /// <summary>Closes the dialog and starts the work; enabled while every field is
    /// valid.</summary>
    btnRun: TButton;

    //** @abstract(Chooses the input folder.)
    //**
    //** @param(Sender The button.)
    /// <summary>Chooses the input folder.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnInputBrowseClick(Sender: TObject);

    //** @abstract(Chooses the output folder.)
    //**
    //** @param(Sender The button.)
    /// <summary>Chooses the output folder.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnOutputBrowseClick(Sender: TObject);

    //** @abstract(Checks the fields again after any change.)
    //**
    //** @param(Sender The field changed.)
    /// <summary>Checks the fields again after any change.</summary>
    /// <param name="Sender">The field changed.</param>
    procedure FieldChange(Sender: TObject);

    //** @abstract(Remembers the choices and closes the dialog with mrOk, when they are valid.)
    //**
    //** @param(Sender The button.)
    /// <summary>Remembers the choices and closes the dialog with mrOk, when they are
    /// valid.</summary>
    /// <param name="Sender">The button.</param>
    procedure btnRunClick(Sender: TObject);

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
    FOrient: TglTFOrientFrame;
    FOptions: TglTFBulkOptions;
    FLoaded: Boolean;
    function ReadOptions(out AOptions: TglTFBulkOptions): string;
    procedure LoadChoices;
    procedure SaveChoices;
  public
    //** @abstract(Creates the dialog with the choices made last time.)
    //**
    //** @param(AOwner Owner of the form.)
    /// <summary>Creates the dialog with the choices made last time.</summary>
    /// <param name="AOwner">Owner of the form.</param>
    constructor Create(AOwner: TComponent); override;

    //** @abstract(Shows the dialog modally, centred on the main form.)
    //**
    //** It does not block: ADone is called once the user presses "Re-Orient models", and not
    //** at all on Cancel. The dialog frees itself.
    //**
    //** @param(ADone Called with the options chosen.)
    /// <summary>Shows the dialog modally, centred on the main form.</summary>
    /// <param name="ADone">Called with the options chosen.</param>
    /// <remarks>It does not block: ADone is called once the user presses "Re-Orient models",
    /// and not at all on Cancel. The dialog frees itself.</remarks>
    class procedure Execute(const ADone: TBulkOrientDoneProc);
  end;

implementation

{$R *.fmx}

uses
  glTF.Document, glTF.Orient,
  glTFViewer.Dialogs, glTFViewer.Settings;

const
  // The kinds of dialog, each with its own folder in the settings
  KEY_INPUT = 'bulkInputFolder';
  KEY_OUTPUT = 'bulkOutputFolder';

  // The choices remembered for the next time
  VALUE_INPUT = 'bulk.inputFolder';
  VALUE_INPUT_TYPES = 'bulk.inputTypes';
  VALUE_OUTPUT = 'bulk.outputFolder';
  VALUE_OUTPUT_TYPE = 'bulk.outputType';
  VALUE_TURN = 'bulk.turn';

function AngleText(AValue: Double): string;
begin
  Result := FormatFloat('0.###', AValue, TFormatSettings.Invariant);
end;

{ TBulkOrientForm }

class procedure TBulkOrientForm.Execute(const ADone: TBulkOrientDoneProc);
var
  LForm: TBulkOrientForm;
begin
  LForm := TBulkOrientForm.Create(Application);
  // ShowModal with a result procedure works on every platform; the form
  // frees itself in OnClose
  LForm.ShowModal(
    procedure(AResult: TModalResult)
    begin
      if (AResult = mrOk) and Assigned(ADone) then
        ADone(LForm.FOptions);
    end);
end;

constructor TBulkOrientForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // The same angles and presets as the Re-Orient tab
  FOrient := TglTFOrientFrame.Create(Self);
  FOrient.Parent := layOrient;
  FOrient.Align := TAlignLayout.Client;
  FOrient.lblInfo.Visible := False;
  FOrient.OnChange := FieldChange;
  LoadChoices;
  FLoaded := True;
  FieldChange(nil);
end;

procedure TBulkOrientForm.LoadChoices;
var
  LSettings: TglTFSettings;
  LParts: TArray<string>;
  LX, LY, LZ: Double;
begin
  LSettings := AppSettings;
  edtInput.Text := LSettings.ReadString(VALUE_INPUT);
  edtOutput.Text := LSettings.ReadString(VALUE_OUTPUT);
  case StrToIntDef(LSettings.ReadString(VALUE_INPUT_TYPES), Ord(biBoth)) of
    Ord(biGLB): rbInputGLB.IsChecked := True;
    Ord(biGLTF): rbInputGLTF.IsChecked := True;
  else
    rbInputBoth.IsChecked := True;
  end;
  // GLB unless glTF was chosen last time
  if LSettings.ReadString(VALUE_OUTPUT_TYPE) = 'gltf' then
    rbOutputGLTF.IsChecked := True
  else
    rbOutputGLB.IsChecked := True;
  LParts := LSettings.ReadString(VALUE_TURN).Split([';']);
  if (Length(LParts) = 3) and
     TryStrToFloat(LParts[0], LX, TFormatSettings.Invariant) and
     TryStrToFloat(LParts[1], LY, TFormatSettings.Invariant) and
     TryStrToFloat(LParts[2], LZ, TFormatSettings.Invariant) then
    FOrient.SetAngles(LX, LY, LZ);
end;

procedure TBulkOrientForm.SaveChoices;
var
  LSettings: TglTFSettings;
begin
  LSettings := AppSettings;
  LSettings.WriteString(VALUE_INPUT, FOptions.InputFolder);
  LSettings.WriteString(VALUE_OUTPUT, FOptions.OutputFolder);
  LSettings.WriteString(VALUE_INPUT_TYPES, IntToStr(Ord(FOptions.Input)));
  if FOptions.OutputFormat = gffJSON then
    LSettings.WriteString(VALUE_OUTPUT_TYPE, 'gltf')
  else
    LSettings.WriteString(VALUE_OUTPUT_TYPE, 'glb');
  LSettings.WriteString(VALUE_TURN, Format('%s;%s;%s', [AngleText(FOptions.RotateX),
    AngleText(FOptions.RotateY), AngleText(FOptions.RotateZ)]));
end;

function TBulkOrientForm.ReadOptions(out AOptions: TglTFBulkOptions): string;
begin
  AOptions := TglTFBulkOptions.Default;
  AOptions.InputFolder := Trim(edtInput.Text);
  AOptions.OutputFolder := Trim(edtOutput.Text);
  if rbInputGLB.IsChecked then
    AOptions.Input := biGLB
  else if rbInputGLTF.IsChecked then
    AOptions.Input := biGLTF
  else
    AOptions.Input := biBoth;
  if rbOutputGLTF.IsChecked then
    AOptions.OutputFormat := gffJSON
  else
    AOptions.OutputFormat := gffGLB;
  if not FOrient.GetAngles(AOptions.RotateX, AOptions.RotateY, AOptions.RotateZ) then
    Exit('Each angle must be a number from -360 to 360');
  Result := TglTFBulkReorienter.Problem(AOptions);
end;

procedure TBulkOrientForm.FieldChange(Sender: TObject);
var
  LOptions: TglTFBulkOptions;
  LProblem: string;
begin
  if not FLoaded then
    Exit; // while the form is loaded and set up
  LProblem := ReadOptions(LOptions);
  btnRun.Enabled := LProblem = '';
  if LProblem <> '' then
  begin
    lblProblem.StyledSettings := lblProblem.StyledSettings - [TStyledSetting.FontColor];
    lblProblem.TextSettings.FontColor := TAlphaColors.Red;
    lblProblem.Text := LProblem;
  end
  else
  begin
    // A turn of nothing still converts, so say so
    lblProblem.StyledSettings := lblProblem.StyledSettings + [TStyledSetting.FontColor];
    if TglTFReorienter.IsIdentity(LOptions.RotateX, LOptions.RotateY, LOptions.RotateZ) then
      lblProblem.Text := 'No turn: the models are only saved again, in the format chosen.'
    else
      lblProblem.Text := 'Ready.';
  end;
end;

procedure TBulkOrientForm.btnInputBrowseClick(Sender: TObject);
begin
  TPlatformDialogs.SelectFolder(KEY_INPUT, 'Folder of the models to re-orient',
    Trim(edtInput.Text),
    procedure(AFolder: string)
    begin
      if AFolder <> '' then
        edtInput.Text := AFolder;
      FieldChange(nil);
    end);
end;

procedure TBulkOrientForm.btnOutputBrowseClick(Sender: TObject);
begin
  TPlatformDialogs.SelectFolder(KEY_OUTPUT, 'Folder for the re-oriented copies',
    Trim(edtOutput.Text),
    procedure(AFolder: string)
    begin
      if AFolder <> '' then
        edtOutput.Text := AFolder;
      FieldChange(nil);
    end);
end;

procedure TBulkOrientForm.btnRunClick(Sender: TObject);
begin
  // Checked again: a folder may have gone since it was typed
  if ReadOptions(FOptions) <> '' then
  begin
    FieldChange(nil);
    Exit;
  end;
  SaveChoices;
  ModalResult := mrOk;
end;

procedure TBulkOrientForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

end.
