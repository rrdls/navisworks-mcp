using System;
using System.Threading;
using Autodesk.Navisworks.Api.Plugins;

namespace NavisworksMcpAddin;

[Plugin(
    "NavisworksMcpAddin.AutoStart",
    "RRDL",
    DisplayName = "Navisworks MCP Auto Start",
    ToolTip = "Automatically starts the local MCP bridge for Navisworks.")]
public sealed class NavisworksMcpEventWatcher : EventWatcherPlugin
{
    public override void OnLoaded()
    {
        McpConnectionManager.Start(SynchronizationContext.Current, "event watcher");
    }

    public override void OnUnloading()
    {
        McpConnectionManager.Stop();
    }
}

[Plugin(
    "NavisworksMcpAddin.Plugin",
    "RRDL",
    DisplayName = "Navisworks MCP",
    ToolTip = "Start the local MCP bridge for Navisworks.")]
public sealed class NavisworksMcpPlugin : AddInPlugin
{
    public override int Execute(params string[] parameters)
    {
        McpConnectionManager.Start(SynchronizationContext.Current, "manual command");
        return 0;
    }
}

public static class McpConnectionManager
{
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

            McpLog.Info($"Starting Navisworks MCP plugin. Source: {source}.");
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
