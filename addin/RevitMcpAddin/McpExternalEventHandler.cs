using System.Collections.Concurrent;
using Autodesk.Revit.UI;

namespace RevitMcpAddin;

public sealed class McpExternalEventHandler : IExternalEventHandler
{
    private readonly ConcurrentQueue<RevitCommandRequest> _commandQueue;
    private McpWebSocketClient? _webSocketClient;

    public McpExternalEventHandler(ConcurrentQueue<RevitCommandRequest> commandQueue)
    {
        _commandQueue = commandQueue;
    }

    public void SetWebSocketClient(McpWebSocketClient webSocketClient)
    {
        _webSocketClient = webSocketClient;
    }

    public void Execute(UIApplication app)
    {
        while (_commandQueue.TryDequeue(out var request))
        {
            var response = ExecuteOne(app, request);
            _ = _webSocketClient?.SendAsync(response);
        }
    }

    public string GetName() => "MCP Revit Handler";

    private static RevitCommandResponse ExecuteOne(UIApplication app, RevitCommandRequest request)
    {
        try
        {
            var uidoc = app.ActiveUIDocument;
            if (uidoc is null)
            {
                return new RevitCommandResponse
                {
                    Id = request.Id,
                    Ok = false,
                    Error = "No active Revit document."
                };
            }

            var result = CSharpRuntime.Execute(request.Code, app, uidoc, uidoc.Document);
            return new RevitCommandResponse
            {
                Id = request.Id,
                Ok = true,
                Result = result
            };
        }
        catch (Exception ex)
        {
            McpLog.Error($"MCP command {request.Id} failed.", ex);
            return new RevitCommandResponse
            {
                Id = request.Id,
                Ok = false,
                Error = ex.Message,
                Details = ex.ToString()
            };
        }
    }
}
