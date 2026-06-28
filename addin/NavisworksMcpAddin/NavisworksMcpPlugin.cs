using System;
using System.Threading;
using System.Windows.Forms;
using Autodesk.Navisworks.Api;
using Autodesk.Navisworks.Api.Plugins;

namespace NavisworksMcpAddin;

[Plugin(
    "NavisworksMcpAddin.AutoStart",
    "RRDL",
    DisplayName = "Navisworks MCP Auto Start",
    ToolTip = "Automatically starts the local MCP bridge for Navisworks.")]
public sealed class NavisworksMcpEventWatcher : EventWatcherPlugin
{
    public NavisworksMcpEventWatcher()
    {
        McpLog.Info("Navisworks MCP event watcher instance constructed.");
    }

    public override void OnLoaded()
    {
        McpLog.Info("Navisworks MCP event watcher OnLoaded reached.");
        NavisworksMcpRuntime.Initialize();
        McpLog.Info("Navisworks MCP Tool add-ins commands registered: Start MCP; Stop MCP; Start Public URL; Stop Public URL; Copy Local URL; Copy Public URL; MCP Status; MCP Settings; Open MCP Logs.");
        NavisworksMcpDiagnostics.LogPluginRecordsIfEnabled();
        if (McpProcessManager.PortIsOpen("127.0.0.1", NavisworksMcpRuntime.WebSocketPort))
        {
            McpConnectionManager.Start(SynchronizationContext.Current, "event watcher");
        }
    }

    public override void OnUnloading()
    {
        McpConnectionManager.Stop();
        NavisworksMcpRuntime.NgrokProcess.StopOnShutdown();
        NavisworksMcpRuntime.McpProcess.StopOnShutdown();
    }
}

internal static class NavisworksMcpDiagnostics
{
    public static void LogPluginRecordsIfEnabled()
    {
        var enabled = Environment.GetEnvironmentVariable("NAVISWORKS_MCP_PLUGIN_DIAGNOSTICS");
        if (!string.Equals(enabled, "1", StringComparison.OrdinalIgnoreCase)
            && !string.Equals(enabled, "true", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        LogPluginRecords();
    }

    private static void LogPluginRecords()
    {
        try
        {
            McpLog.Info("Navisworks MCP plugin record diagnostics begin.");
            foreach (var record in Autodesk.Navisworks.Api.Application.Plugins.PluginRecords)
            {
                if (!IsRelevant(record))
                {
                    continue;
                }

                McpLog.Info(
                    $"PluginRecord: id={record.Id}; name={record.Name}; developerId={record.DeveloperId}; " +
                    $"displayName={record.DisplayName}; type={record.GetType().FullName}; isLoaded={record.IsLoaded}; " +
                    $"hasFailedCreate={record.HasFailedCreate}; hasAttemptedCreate={record.HasAttemptedCreate}");

                if (record is CommandHandlerPluginRecord commandRecord)
                {
                    foreach (var command in commandRecord.CommandRecords)
                    {
                        McpLog.Info($"  CommandRecord: id={command.Id}; displayName={command.DisplayName}");
                    }

                    foreach (var ribbonTab in commandRecord.RibbonTabRecords)
                    {
                        McpLog.Info($"  RibbonTabRecord: id={ribbonTab.Id}; displayName={ribbonTab.DisplayName}");
                    }

                    foreach (var ribbonLayout in commandRecord.RibbonLayoutRecords)
                    {
                        McpLog.Info($"  RibbonLayoutRecord: xaml={ribbonLayout.Xaml}");
                    }
                }
            }

            McpLog.Info("Navisworks MCP plugin record diagnostics end.");
        }
        catch (Exception ex)
        {
            McpLog.Error("Navisworks MCP plugin record diagnostics failed.", ex);
        }
    }

    private static bool IsRelevant(PluginRecord record)
    {
        return Contains(record.Id, "NavisworksMcp")
            || Contains(record.Name, "NavisworksMcp")
            || Contains(record.DisplayName, "Navisworks MCP")
            || Contains(record.DeveloperId, "RRDL");
    }

    private static bool Contains(string? value, string expected)
    {
        return value?.IndexOf(expected, StringComparison.OrdinalIgnoreCase) >= 0;
    }
}

[Plugin(
    "NavisworksMcpAddin.Plugin",
    "RRDL",
    DisplayName = "Start MCP",
    ToolTip = "Start the local MCP server for Navisworks.")]
[AddInPlugin(AddInLocation.AddIn)]
public sealed class StartMcpPlugin : AddInPlugin
{
    public override int Execute(params string[] parameters)
    {
        return NavisworksMcpActions.Start();
    }
}

[Plugin(
    "NavisworksMcpAddin.Stop",
    "RRDL",
    DisplayName = "Stop MCP",
    ToolTip = "Stop the local MCP server for Navisworks.")]
[AddInPlugin(AddInLocation.AddIn)]
public sealed class StopMcpPlugin : AddInPlugin
{
    public override int Execute(params string[] parameters)
    {
        return NavisworksMcpActions.Stop();
    }
}

[Plugin(
    "NavisworksMcpAddin.StartPublicUrl",
    "RRDL",
    DisplayName = "Start Public URL",
    ToolTip = "Start the fixed ngrok public URL for Navisworks MCP.")]
[AddInPlugin(AddInLocation.AddIn)]
public sealed class StartPublicUrlPlugin : AddInPlugin
{
    public override int Execute(params string[] parameters)
    {
        return NavisworksMcpActions.StartPublicUrl();
    }
}

[Plugin(
    "NavisworksMcpAddin.StopPublicUrl",
    "RRDL",
    DisplayName = "Stop Public URL",
    ToolTip = "Stop the fixed ngrok public URL for Navisworks MCP.")]
[AddInPlugin(AddInLocation.AddIn)]
public sealed class StopPublicUrlPlugin : AddInPlugin
{
    public override int Execute(params string[] parameters)
    {
        return NavisworksMcpActions.StopPublicUrl();
    }
}

[Plugin(
    "NavisworksMcpAddin.CopyLocalUrl",
    "RRDL",
    DisplayName = "Copy Local URL",
    ToolTip = "Copy the local Navisworks MCP URL.")]
[AddInPlugin(AddInLocation.AddIn)]
public sealed class CopyLocalUrlPlugin : AddInPlugin
{
    public override int Execute(params string[] parameters)
    {
        return NavisworksMcpActions.CopyLocalUrl();
    }
}

[Plugin(
    "NavisworksMcpAddin.CopyPublicUrl",
    "RRDL",
    DisplayName = "Copy Public URL",
    ToolTip = "Copy the configured public Navisworks MCP URL.")]
[AddInPlugin(AddInLocation.AddIn)]
public sealed class CopyPublicUrlPlugin : AddInPlugin
{
    public override int Execute(params string[] parameters)
    {
        return NavisworksMcpActions.CopyPublicUrl();
    }
}

[Plugin(
    "NavisworksMcpAddin.Status",
    "RRDL",
    DisplayName = "MCP Status",
    ToolTip = "Show Navisworks MCP status.")]
[AddInPlugin(AddInLocation.AddIn)]
public sealed class StatusPlugin : AddInPlugin
{
    public override int Execute(params string[] parameters)
    {
        return NavisworksMcpActions.Status();
    }
}

[Plugin(
    "NavisworksMcpAddin.Settings",
    "RRDL",
    DisplayName = "MCP Settings",
    ToolTip = "Edit Navisworks MCP settings.")]
[AddInPlugin(AddInLocation.AddIn)]
public sealed class SettingsPlugin : AddInPlugin
{
    public override int Execute(params string[] parameters)
    {
        return NavisworksMcpActions.Settings();
    }
}

[Plugin(
    "NavisworksMcpAddin.OpenLogs",
    "RRDL",
    DisplayName = "Open MCP Logs",
    ToolTip = "Open the Navisworks MCP logs folder.")]
[AddInPlugin(AddInLocation.AddIn)]
public sealed class OpenLogsPlugin : AddInPlugin
{
    public override int Execute(params string[] parameters)
    {
        return NavisworksMcpActions.OpenLogs();
    }
}

internal static class NavisworksMcpActions
{
    public static int Start()
    {
        var result = NavisworksMcpRuntime.McpProcess.Start();
        if (result.Ok)
        {
            McpConnectionManager.Start(SynchronizationContext.Current, "start command");
        }

        NavisworksMcpDialogs.Show("Start MCP", result.Message);
        return result.Ok ? 0 : 1;
    }

    public static int Stop()
    {
        McpConnectionManager.Stop();
        var result = NavisworksMcpRuntime.McpProcess.Stop();
        NavisworksMcpDialogs.Show("Stop MCP", result.Message);
        return result.Ok ? 0 : 1;
    }

    public static int StartPublicUrl()
    {
        var result = NavisworksMcpRuntime.NgrokProcess.Start();
        NavisworksMcpDialogs.Show("Start Public URL", result.Message);
        return result.Ok ? 0 : 1;
    }

    public static int StopPublicUrl()
    {
        var result = NavisworksMcpRuntime.NgrokProcess.Stop();
        NavisworksMcpDialogs.Show("Stop Public URL", result.Message);
        return result.Ok ? 0 : 1;
    }

    public static int CopyLocalUrl()
    {
        Clipboard.SetText(NavisworksMcpRuntime.LocalMcpUrl);
        NavisworksMcpDialogs.Show("Copy Local URL", $"Copied local MCP URL:{Environment.NewLine}{NavisworksMcpRuntime.LocalMcpUrl}");
        return 0;
    }

    public static int CopyPublicUrl()
    {
        var settings = NavisworksMcpRuntime.LoadSettings();
        var publicUrl = NavisworksMcpRuntime.BuildPublicMcpUrl(settings);
        if (string.IsNullOrWhiteSpace(publicUrl))
        {
            NavisworksMcpDialogs.Show("Copy Public URL", "Configure your fixed ngrok domain in Settings first.");
            return 1;
        }

        Clipboard.SetText(publicUrl);
        NavisworksMcpDialogs.Show("Copy Public URL", $"Copied public MCP URL:{Environment.NewLine}{publicUrl}");
        return 0;
    }

    public static int Status()
    {
        var settings = NavisworksMcpRuntime.LoadSettings();
        var publicUrl = string.IsNullOrWhiteSpace(settings.NgrokDomain)
            ? "Not configured"
            : NavisworksMcpRuntime.BuildPublicMcpUrl(settings);

        NavisworksMcpDialogs.Show(
            "Navisworks MCP Status",
            $"{NavisworksMcpRuntime.McpProcess.Status}{Environment.NewLine}{Environment.NewLine}" +
            $"{NavisworksMcpRuntime.NgrokProcess.Status}{Environment.NewLine}{Environment.NewLine}" +
            $"Local URL: {NavisworksMcpRuntime.LocalMcpUrl}{Environment.NewLine}" +
            $"Public URL: {publicUrl}{Environment.NewLine}" +
            $"Settings: {NavisworksMcpRuntime.SettingsPath}");
        return 0;
    }

    public static int Settings()
    {
        using var form = new SettingsForm();
        form.ShowDialog();
        return 0;
    }

    public static int OpenLogs()
    {
        NavisworksMcpRuntime.OpenAppDataDirectory();
        return 0;
    }
}

internal static class NavisworksMcpDialogs
{
    public static void Show(string title, string message)
    {
        MessageBox.Show(message, title, MessageBoxButtons.OK, MessageBoxIcon.Information);
    }
}

public static class McpConnectionManager
{
    private const string BuildMarker = "Navisworks MCP addin build: no-system-text-json";
    private static readonly object LockObject = new();
    private static McpWebSocketClient? _webSocketClient;

    public static void Start(SynchronizationContext? synchronizationContext, string source)
    {
        lock (LockObject)
        {
            if (_webSocketClient is not null)
            {
                McpLog.Info($"Navisworks MCP plugin already running. Source: {source}.");
                return;
            }

            McpLog.Info(BuildMarker);
            McpLog.Info($"Starting Navisworks MCP plugin. Source: {source}.");
            NavisworksMcpRuntime.Initialize();
            _webSocketClient = new McpWebSocketClient(ExecuteOne, synchronizationContext);
            _webSocketClient.Start();
        }
    }

    public static void Stop()
    {
        lock (LockObject)
        {
            if (_webSocketClient is null)
            {
                return;
            }

            McpLog.Info("Stopping Navisworks MCP plugin.");
            _webSocketClient.Stop();
            _webSocketClient.Dispose();
            _webSocketClient = null;
        }
    }

    private static NavisworksCommandResponse ExecuteOne(NavisworksCommandRequest request)
    {
        try
        {
            var doc = Autodesk.Navisworks.Api.Application.ActiveDocument;
            if (doc is null)
            {
                return new NavisworksCommandResponse
                {
                    Id = request.Id,
                    Ok = false,
                    Error = "No active Navisworks document."
                };
            }

            var result = CSharpRuntime.Execute(request.Code, doc);
            return new NavisworksCommandResponse
            {
                Id = request.Id,
                Ok = true,
                Result = result
            };
        }
        catch (Exception ex)
        {
            McpLog.Error($"MCP command {request.Id} failed.", ex);
            return new NavisworksCommandResponse
            {
                Id = request.Id,
                Ok = false,
                Error = ex.Message,
                Details = ex.ToString()
            };
        }
    }
}
