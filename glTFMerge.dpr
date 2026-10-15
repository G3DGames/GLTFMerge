//** @abstract(glTF viewer: a FireMonkey application that opens, inspects and saves glTF and GLB
//** files.)
//**
//** The units glTF.Base, glTF.Classes, glTF.SourceMap, glTF.Document, glTF.Edit,
//** glTF.Animations, glTF.AnimationSplit, glTF.Parts and glTF.Orient are the glTF reader,
//** writer, animation importer and splitter, part swapper and re-orienter and have no user
//** interface; they are in the GLTFLib folder. The glTFViewer units and the form are the
//** application, in the src folder. Neon
//** @(https://github.com/paolo-rossi/delphi-neon@) is expected in the delphi-neon folder next
//** to this file; its units are listed below. Needs Delphi 10.4 or later. Memory leaks are
//** reported on shutdown.
//**
//** Targets Windows, macOS, Linux @(with FMXLinux@), iOS and Android. On iOS and Android, files
//** are opened from and saved to the app's documents folder by default; on iOS, set
//** UIFileSharingEnabled in the project's version information so that files can be copied there
//** with the Files app or Finder.
//**
//** @preformatted(
//** Command line @(desktop@):  glTFDemo [file.gltf|file.glb] [--selftest]
//** )
program glTFMerge;

{
  glTF viewer: a FireMonkey application that opens, inspects and saves glTF
  and GLB files.

  The units glTF.Base, glTF.Classes, glTF.SourceMap, glTF.Document, glTF.Edit,
  glTF.Animations, glTF.AnimationSplit, glTF.Parts and glTF.Orient are the
  glTF reader, writer, animation importer and splitter, part swapper and
  re-orienter and have no user interface; they are in the GLTFLib folder. The glTFViewer units and the
  form are the application, in the src folder. Neon
  (https://github.com/paolo-rossi/delphi-neon) is expected in the
  delphi-neon folder next to this file; its units are listed below. Needs
  Delphi 10.4 or later. Memory leaks are reported on shutdown.

  Targets Windows, macOS, Linux (with FMXLinux), iOS and Android. On iOS and
  Android, files are opened from and saved to the app's documents folder by
  default; on iOS, set UIFileSharingEnabled in the project's version
  information so that files can be copied there with the Files app or Finder.

    Command line (desktop):  glTFDemo [file.gltf|file.glb] [--selftest]
}

uses
  System.StartUpCopy,
  FMX.Forms,
  Neon.Core.Attributes in 'delphi-neon\Source\Neon.Core.Attributes.pas',
  Neon.Core.DynamicTypes in 'delphi-neon\Source\Neon.Core.DynamicTypes.pas',
  Neon.Core.Persistence.JSON in 'delphi-neon\Source\Neon.Core.Persistence.JSON.pas',
  Neon.Core.Persistence in 'delphi-neon\Source\Neon.Core.Persistence.pas',
  Neon.Core.Tags in 'delphi-neon\Source\Neon.Core.Tags.pas',
  Neon.Core.Types in 'delphi-neon\Source\Neon.Core.Types.pas',
  Neon.Core.Utils in 'delphi-neon\Source\Neon.Core.Utils.pas',
  glTF.Base in 'GLTFLib\glTF.Base.pas',
  glTF.Classes in 'GLTFLib\glTF.Classes.pas',
  glTF.SourceMap in 'GLTFLib\glTF.SourceMap.pas',
  glTF.Document in 'GLTFLib\glTF.Document.pas',
  glTF.Edit in 'GLTFLib\glTF.Edit.pas',
  glTF.Animations in 'GLTFLib\glTF.Animations.pas',
  glTF.Parts in 'GLTFLib\glTF.Parts.pas',
  glTF.AnimationSplit in 'GLTFLib\glTF.AnimationSplit.pas',
  glTF.Orient in 'GLTFLib\glTF.Orient.pas',
  glTFViewer.Tree in 'src\glTFViewer.Tree.pas',
  glTFViewer.Dialogs in 'src\glTFViewer.Dialogs.pas',
  glTFViewer.Missing in 'src\glTFViewer.Missing.pas',
  glTFViewer.Columns in 'src\glTFViewer.Columns.pas',
  glTFViewer.Progress in 'src\glTFViewer.Progress.pas',
  glTFViewer.Images in 'src\glTFViewer.Images.pas',
  glTFViewer.Animations in 'src\glTFViewer.Animations.pas',
  glTFViewer.Duplicates in 'src\glTFViewer.Duplicates.pas',
  glTFViewer.Parts in 'src\glTFViewer.Parts.pas',
  glTFViewer.Split in 'src\glTFViewer.Split.pas',
  glTFViewer.Orient in 'src\glTFViewer.Orient.pas',
  glTFViewer.Main in 'src\glTFViewer.Main.pas' {glTFMainForm};

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.CreateForm(TglTFMainForm, glTFMainForm);
  Application.Run;
end.
