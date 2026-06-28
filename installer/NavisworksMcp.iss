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
PrivilegesRequired=admin
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
Type: filesandordirs; Name: "{commonappdata}\Autodesk\ApplicationPlugins\NavisworksMcp.bundle"
Type: filesandordirs; Name: "{pf}\Autodesk\Navisworks Manage 2021\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{pf}\Autodesk\Navisworks Manage 2022\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{pf}\Autodesk\Navisworks Manage 2023\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{pf}\Autodesk\Navisworks Manage 2024\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{pf}\Autodesk\Navisworks Manage 2025\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{pf}\Autodesk\Navisworks Manage 2026\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{pf}\Autodesk\Navisworks Simulate 2021\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{pf}\Autodesk\Navisworks Simulate 2022\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{pf}\Autodesk\Navisworks Simulate 2023\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{pf}\Autodesk\Navisworks Simulate 2024\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{pf}\Autodesk\Navisworks Simulate 2025\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{pf}\Autodesk\Navisworks Simulate 2026\Plugins\NavisworksMcp"

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
  InstallDir: string;
  SourceDir: string;
  SourceContentsDir: string;
  BundleDir: string;
  ContentsDir: string;
  ProgramDataBundleDir: string;
  ProgramDataContentsDir: string;
  ProductPluginDir: string;
  ProductPluginFlatDir: string;
begin
  InstallDir := ExpandConstant('{pf}\Autodesk\Navisworks Manage ' + Version);
  ApiPath := InstallDir + '\Autodesk.Navisworks.Api.dll';
  if not FileExists(ApiPath) then
  begin
    InstallDir := ExpandConstant('{pf}\Autodesk\Navisworks Simulate ' + Version);
    ApiPath := InstallDir + '\Autodesk.Navisworks.Api.dll';
  end;

  SourceDir := ExpandConstant('{app}\addins\' + Version);
  SourceContentsDir := SourceDir + '\Contents';

  if FileExists(ApiPath) and DirExists(SourceDir) then
  begin
    BundleDir := ExpandConstant('{userappdata}\Autodesk\ApplicationPlugins\NavisworksMcp.bundle');
    ContentsDir := BundleDir + '\Contents';
    DelTree(BundleDir, True, True, True);
    ForceDirectories(ContentsDir);
    CopyDirectoryContents(SourceDir + '\Contents', ContentsDir);
    FileCopy(SourceDir + '\PackageContents.xml', BundleDir + '\PackageContents.xml', False);

    ProgramDataBundleDir := ExpandConstant('{commonappdata}\Autodesk\ApplicationPlugins\NavisworksMcp.bundle');
    ProgramDataContentsDir := ProgramDataBundleDir + '\Contents';
    DelTree(ProgramDataBundleDir, True, True, True);
    ForceDirectories(ProgramDataContentsDir);
    CopyDirectoryContents(SourceDir + '\Contents', ProgramDataContentsDir);
    FileCopy(SourceDir + '\PackageContents.xml', ProgramDataBundleDir + '\PackageContents.xml', False);

    ProductPluginDir := InstallDir + '\Plugins\NavisworksMcp';
    DelTree(ProductPluginDir, True, True, True);
    ForceDirectories(ProductPluginDir);
    CopyDirectoryContents(SourceContentsDir, ProductPluginDir);

    ProductPluginFlatDir := InstallDir + '\Plugins';
    CopyDirectoryContents(SourceContentsDir, ProductPluginFlatDir);
    if FileExists(ProductPluginFlatDir + '\NavisworksMcpAddin.dll') then
      FileCopy(ProductPluginFlatDir + '\NavisworksMcpAddin.dll', ProductPluginFlatDir + '\NavisworksMcp.Plugin.dll', False);
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
