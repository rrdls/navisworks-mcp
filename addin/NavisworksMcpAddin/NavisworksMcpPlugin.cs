using System;
using System.Threading;
using Autodesk.Navisworks.Api.Plugins;

namespace NavisworksMcpAddin;

[Plugin(
    "NavisworksMcpAddin.Plugin",
    "RRDLS",
    DisplayName = "Navisworks MCP",
    ToolTip = "Start the local MCP bridge for Navisworks.")]
public sealed class NavisworksMcpPlugin : AddInPlugin
{
    private static readonly object LockObject = new();
    private static McpWebSocketClient? _webSocketClient;

    public override int Execute(params string[] parameters)
    {
        lock (LockObject)
        {
            if (_webSocketClient is not null)
            {
                McpLog.Info("Navisworks MCP plugin already running.");
                return 0;
            }

            McpLog.Info("Starting Navisworks MCP plugin.");
            _webSocketClient = new McpWebSocketClient(ExecuteOne, SynchronizationContext.Current);
            _webSocketClient.Start();
        }

        return 0;
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
