#define MyAppName "Navisworks MCP"
#define MyAppVersion "0.1.0"
#define MyAppPublisher "Navisworks MCP"
#define SourceRoot "..\dist\NavisworksMcp"

[Setup]
AppId={{B407B8B3-B544-41D1-9D36-A60D92493036}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\NavisworksMcp
DefaultGroupName=Navisworks MCP
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64
OutputDir=..\dist\installer
OutputBaseFilename=NavisworksMcpSetup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Files]
Source: "{#SourceRoot}\app\*"; DestDir: "{app}\app"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#SourceRoot}\addins\*"; DestDir: "{app}\addins"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Navisworks MCP"; Filename: "{app}\app\NavisworksMcpLauncher.exe"
Name: "{userdesktop}\Navisworks MCP"; Filename: "{app}\app\NavisworksMcpLauncher.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"

[Run]
Filename: "{app}\app\NavisworksMcpLauncher.exe"; Description: "Launch Navisworks MCP"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{localappdata}\NavisworksMcp"
Type: filesandordirs; Name: "{userappdata}\Autodesk\ApplicationPlugins\NavisworksMcp.bundle"

[Code]
procedure CopyDirectoryContents(const SourceDir, DestDir: string);
var
  FindRec: TFindRec;
begin
  ForceDirectories(DestDir);
  if FindFirst(SourceDir + '\*', FindRec) then
  begin
    try
      repeat
        if (FindRec.Name <> '.') and (FindRec.Name <> '..') then
        begin
          if FindRec.Attributes and FILE_ATTRIBUTE_DIRECTORY <> 0 then
            CopyDirectoryContents(SourceDir + '\' + FindRec.Name, DestDir + '\' + FindRec.Name)
          else
            FileCopy(SourceDir + '\' + FindRec.Name, DestDir + '\' + FindRec.Name, False);
        end;
      until not FindNext(FindRec);
    finally
      FindClose(FindRec);
    end;
  end;
end;

procedure InstallBundleForVersion(const Version: string);
var
  ApiPath: string;
  SourceDir: string;
  BundleDir: string;
  ContentsDir: string;
begin
  ApiPath := ExpandConstant('{pf}\Autodesk\Navisworks Manage ' + Version + '\Autodesk.Navisworks.Api.dll');
  SourceDir := ExpandConstant('{app}\addins\' + Version);

  if FileExists(ApiPath) and DirExists(SourceDir) then
  begin
    BundleDir := ExpandConstant('{userappdata}\Autodesk\ApplicationPlugins\NavisworksMcp.bundle');
    ContentsDir := BundleDir + '\Contents';
    DelTree(BundleDir, True, True, True);
    ForceDirectories(ContentsDir);
    CopyDirectoryContents(SourceDir + '\Contents', ContentsDir);
    FileCopy(SourceDir + '\PackageContents.xml', BundleDir + '\PackageContents.xml', False);
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    InstallBundleForVersion('2021');
    InstallBundleForVersion('2022');
    InstallBundleForVersion('2023');
    InstallBundleForVersion('2024');
    InstallBundleForVersion('2025');
    InstallBundleForVersion('2026');
  end;
end;
