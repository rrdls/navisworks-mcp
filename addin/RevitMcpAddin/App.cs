using System.Collections.Concurrent;
using Autodesk.Revit.UI;

namespace RevitMcpAddin;

public sealed class App : IExternalApplication
{
    private readonly ConcurrentQueue<RevitCommandRequest> _commandQueue = new();
    private McpExternalEventHandler? _handler;
    private ExternalEvent? _externalEvent;
    private McpWebSocketClient? _webSocketClient;

    public Result OnStartup(UIControlledApplication application)
    {
        McpLog.Info("Starting Revit MCP add-in.");
        _handler = new McpExternalEventHandler(_commandQueue);
        _externalEvent = ExternalEvent.Create(_handler);
        _webSocketClient = new McpWebSocketClient(_commandQueue, _externalEvent);
        _handler.SetWebSocketClient(_webSocketClient);
        _webSocketClient.Start();

        return Result.Succeeded;
    }

    public Result OnShutdown(UIControlledApplication application)
    {
        McpLog.Info("Stopping Revit MCP add-in.");
        _webSocketClient?.Dispose();
        _externalEvent?.Dispose();
        return Result.Succeeded;
    }
}
