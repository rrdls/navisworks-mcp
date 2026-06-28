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

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"

[InstallDelete]
Type: files; Name: "{app}\app\cloudflared.exe"
Type: files; Name: "{userstartup}\Navisworks MCP Autoloader.lnk"
Type: filesandordirs; Name: "{userappdata}\Autodesk\ApplicationPlugins\NavisworksMcp.bundle"
Type: filesandordirs; Name: "{commonappdata}\Autodesk\ApplicationPlugins\NavisworksMcp.bundle"
Type: filesandordirs; Name: "{commonpf}\Autodesk\Navisworks Manage 2024\Plugins\NavisworksMcp"
Type: filesandordirs; Name: "{commonpf}\Autodesk\Navisworks Manage 2024\Plugins\NavisworksMcpAddin.Plugin"

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

[Code]
function IsRoamerRunning(): Boolean;
var
  ResultCode: Integer;
begin
  Exec(
    ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
    '-NoProfile -ExecutionPolicy Bypass -Command "if (Get-Process Roamer -ErrorAction SilentlyContinue) { exit 1 } else { exit 0 }"',
    '',
    SW_HIDE,
    ewWaitUntilTerminated,
    ResultCode);
  Result := ResultCode <> 0;
end;

function InitializeSetup(): Boolean;
begin
  if IsRoamerRunning() then
  begin
    MsgBox(
      'Close Navisworks before installing Navisworks MCP. The plugin DLLs cannot be replaced while Navisworks is running.',
      mbError,
      MB_OK);
    Result := False;
  end
  else
    Result := True;
end;

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

procedure DeleteStalePluginFiles(const Dir: string);
begin
  DeleteFile(Dir + '\NavisworksMcpAddin.dll');
  DeleteFile(Dir + '\NavisworksMcpAddin.pdb');
  DeleteFile(Dir + '\NavisworksMcpProbe.dll');
  DeleteFile(Dir + '\NavisworksMcpProbe.pdb');
  DeleteFile(Dir + '\NavisworksMcpRibbon.xaml');
  DeleteFile(Dir + '\NavisworksMcp.Plugin.dll');
  DeleteFile(Dir + '\Microsoft.CodeAnalysis.dll');
  DeleteFile(Dir + '\Microsoft.CodeAnalysis.CSharp.dll');
  DeleteFile(Dir + '\System.Collections.Immutable.dll');
  DeleteFile(Dir + '\System.Reflection.Metadata.dll');
  DeleteFile(Dir + '\System.Runtime.CompilerServices.Unsafe.dll');
  DeleteFile(Dir + '\System.Text.Json.dll');
end;

procedure DeleteStaleFlatPluginFiles(const Dir: string);
begin
  DeleteStalePluginFiles(Dir);
  DeleteFile(Dir + '\NavisworksMcpAddin.Plugin.dll');
  DeleteFile(Dir + '\NavisworksMcpAddin.Plugin.pdb');
  DeleteFile(Dir + '\NavisworksMcpProbe.Plugin.dll');
  DeleteFile(Dir + '\NavisworksMcpProbe.Plugin.pdb');
  DeleteFile(Dir + '\Microsoft.Bcl.AsyncInterfaces.dll');
  DeleteFile(Dir + '\System.Buffers.dll');
  DeleteFile(Dir + '\System.Memory.dll');
  DeleteFile(Dir + '\System.Numerics.Vectors.dll');
  DeleteFile(Dir + '\System.Text.Encoding.CodePages.dll');
  DeleteFile(Dir + '\System.Text.Encodings.Web.dll');
  DeleteFile(Dir + '\System.Threading.Tasks.Extensions.dll');
  DeleteFile(Dir + '\System.ValueTuple.dll');
end;

procedure FailIfExists(const Path: string);
begin
  if FileExists(Path) then
    RaiseException('Navisworks MCP installer left a stale or forbidden plugin file: ' + Path);
end;

procedure ValidateCleanPluginDir(const Dir: string);
begin
  FailIfExists(Dir + '\NavisworksMcpAddin.dll');
  FailIfExists(Dir + '\NavisworksMcpProbe.dll');
  FailIfExists(Dir + '\NavisworksMcpRibbon.xaml');
  FailIfExists(Dir + '\NavisworksMcp.Plugin.dll');
  FailIfExists(Dir + '\Microsoft.CodeAnalysis.dll');
  FailIfExists(Dir + '\Microsoft.CodeAnalysis.CSharp.dll');
  FailIfExists(Dir + '\System.Collections.Immutable.dll');
  FailIfExists(Dir + '\System.Reflection.Metadata.dll');
  FailIfExists(Dir + '\System.Runtime.CompilerServices.Unsafe.dll');
  FailIfExists(Dir + '\System.Text.Json.dll');
end;

procedure InstallBundleForVersion(const Version: string);
var
  ApiPath: string;
  InstallDir: string;
  SourceDir: string;
  SourceContentsDir: string;
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
    DelTree(ExpandConstant('{userappdata}\Autodesk\ApplicationPlugins\NavisworksMcp.bundle'), True, True, True);
    DelTree(ExpandConstant('{commonappdata}\Autodesk\ApplicationPlugins\NavisworksMcp.bundle'), True, True, True);
    DelTree(InstallDir + '\Plugins\NavisworksMcp', True, True, True);

    ProductPluginDir := InstallDir + '\Plugins\NavisworksMcpAddin.Plugin';
    DelTree(ProductPluginDir, True, True, True);
    ForceDirectories(ProductPluginDir);
    CopyDirectoryContents(SourceContentsDir, ProductPluginDir);
    DeleteStalePluginFiles(ProductPluginDir);
    ValidateCleanPluginDir(ProductPluginDir);

    ProductPluginFlatDir := InstallDir + '\Plugins';
    DeleteStaleFlatPluginFiles(ProductPluginFlatDir);

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
