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
ArchitecturesInstallIn64BitMode=x64compatible
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
Name: "{userstartup}\Navisworks MCP Autoloader"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\app\watch-navisworks-addin.ps1"""; WorkingDir: "{app}\app"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"

[InstallDelete]
Type: files; Name: "{app}\app\cloudflared.exe"
Type: files; Name: "{userstartup}\Navisworks MCP Autoloader.lnk"

[UninstallDelete]
Type: filesandordirs; Name: "{localappdata}\NavisworksMcp"
Type: files; Name: "{userstartup}\Navisworks MCP Autoloader.lnk"
Type: filesandordirs; Name: "{userappdata}\Autodesk\ApplicationPlugins\NavisworksMcp.bundle"
Type: filesandordirs; Name: "{commonappdata}\Autodesk\ApplicationPlugins\NavisworksMcp.bundle"
Type: filesandordirs; Name: "{commonpf}\Autodesk\Navisworks Manage 2021\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{commonpf}\Autodesk\Navisworks Manage 2022\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{commonpf}\Autodesk\Navisworks Manage 2023\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{commonpf}\Autodesk\Navisworks Manage 2024\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{commonpf}\Autodesk\Navisworks Manage 2025\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{commonpf}\Autodesk\Navisworks Manage 2026\Plugins\NavisworksMcp"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2021\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2022\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2023\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2024\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2025\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2026\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2021\NavisworksMcpAddin.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2022\NavisworksMcpAddin.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2023\NavisworksMcpAddin.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2024\NavisworksMcpAddin.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2025\NavisworksMcpAddin.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2026\NavisworksMcpAddin.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2021\Plugins\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2022\Plugins\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2023\Plugins\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2024\Plugins\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2025\Plugins\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2026\Plugins\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2021\NavisworksMcpProbe.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2022\NavisworksMcpProbe.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2023\NavisworksMcpProbe.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2024\NavisworksMcpProbe.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2025\NavisworksMcpProbe.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Manage 2026\NavisworksMcpProbe.Plugin.dll"
Type: filesandordirs; Name: "{commonpf}\Autodesk\Navisworks Simulate 2021\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{commonpf}\Autodesk\Navisworks Simulate 2022\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{commonpf}\Autodesk\Navisworks Simulate 2023\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{commonpf}\Autodesk\Navisworks Simulate 2024\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{commonpf}\Autodesk\Navisworks Simulate 2025\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{commonpf}\Autodesk\Navisworks Simulate 2026\Plugins\NavisworksMcp"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2021\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2022\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2023\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2024\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2025\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2026\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2021\NavisworksMcpAddin.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2022\NavisworksMcpAddin.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2023\NavisworksMcpAddin.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2024\NavisworksMcpAddin.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2025\NavisworksMcpAddin.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2026\NavisworksMcpAddin.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2021\Plugins\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2022\Plugins\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2023\Plugins\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2024\Plugins\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2025\Plugins\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2026\Plugins\NavisworksMcp.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2021\NavisworksMcpProbe.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2022\NavisworksMcpProbe.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2023\NavisworksMcpProbe.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2024\NavisworksMcpProbe.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2025\NavisworksMcpProbe.Plugin.dll"
Type: files; Name: "{commonpf}\Autodesk\Navisworks Simulate 2026\NavisworksMcpProbe.Plugin.dll"

[Run]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\app\watch-navisworks-addin.ps1"""; WorkingDir: "{app}\app"; Flags: runhidden nowait

[Code]
procedure StopProcessByImageName(const ImageName: string);
var
  ResultCode: Integer;
begin
  Exec(ExpandConstant('{cmd}'), '/C taskkill /IM "' + ImageName + '" /T /F', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

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
            CopyFile(SourceDir + '\' + FindRec.Name, DestDir + '\' + FindRec.Name, False);
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
  InstallDir := ExpandConstant('{commonpf}\Autodesk\Navisworks Manage ' + Version);
  ApiPath := InstallDir + '\Autodesk.Navisworks.Api.dll';
  if not FileExists(ApiPath) then
  begin
    InstallDir := ExpandConstant('{commonpf}\Autodesk\Navisworks Simulate ' + Version);
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
    CopyFile(SourceDir + '\PackageContents.xml', BundleDir + '\PackageContents.xml', False);

    ProgramDataBundleDir := ExpandConstant('{commonappdata}\Autodesk\ApplicationPlugins\NavisworksMcp.bundle');
    ProgramDataContentsDir := ProgramDataBundleDir + '\Contents';
    DelTree(ProgramDataBundleDir, True, True, True);
    ForceDirectories(ProgramDataContentsDir);
    CopyDirectoryContents(SourceDir + '\Contents', ProgramDataContentsDir);
    CopyFile(SourceDir + '\PackageContents.xml', ProgramDataBundleDir + '\PackageContents.xml', False);

    ProductPluginDir := InstallDir + '\Plugins\NavisworksMcp';
    DelTree(ProductPluginDir, True, True, True);

    ProductPluginFlatDir := InstallDir + '\Plugins';
    DeleteFile(ProductPluginFlatDir + '\NavisworksMcp.Plugin.dll');
    DeleteFile(ProductPluginFlatDir + '\NavisworksMcpAddin.dll');
    DeleteFile(ProductPluginFlatDir + '\NavisworksMcpAddin.pdb');
    DeleteFile(ProductPluginFlatDir + '\NavisworksMcpAddin.Plugin.dll');
    DeleteFile(ProductPluginFlatDir + '\NavisworksMcpAddin.Plugin.pdb');
    DeleteFile(ProductPluginFlatDir + '\NavisworksMcpProbe.dll');
    DeleteFile(ProductPluginFlatDir + '\NavisworksMcpProbe.pdb');
    DeleteFile(ProductPluginFlatDir + '\NavisworksMcpProbe.Plugin.dll');
    DeleteFile(ProductPluginFlatDir + '\NavisworksMcpProbe.Plugin.pdb');

    DeleteFile(InstallDir + '\NavisworksMcp.Plugin.dll');
    DeleteFile(InstallDir + '\NavisworksMcpAddin.Plugin.dll');
    DeleteFile(InstallDir + '\NavisworksMcpProbe.Plugin.dll');
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
  begin
    StopProcessByImageName('NavisworksMcpServer.exe');
    StopProcessByImageName('ngrok.exe');
  end;

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
