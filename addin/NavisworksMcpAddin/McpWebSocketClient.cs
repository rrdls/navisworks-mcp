using System;
using System.IO;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace NavisworksMcpAddin;

public sealed class McpWebSocketClient : IDisposable
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true
    };

    private readonly Func<NavisworksCommandRequest, NavisworksCommandResponse> _execute;
    private readonly SynchronizationContext? _syncContext;
    private readonly Uri _serverUri;
    private readonly string? _token;
    private readonly CancellationTokenSource _cts = new();
    private readonly SemaphoreSlim _sendLock = new(1, 1);

    private ClientWebSocket? _socket;
    private Task? _runTask;

    public McpWebSocketClient(
        Func<NavisworksCommandRequest, NavisworksCommandResponse> execute,
        SynchronizationContext? syncContext)
    {
        _execute = execute;
        _syncContext = syncContext;
        var url = Environment.GetEnvironmentVariable("NAVISWORKS_MCP_WS_URL")
            ?? "ws://127.0.0.1:8765";
        _serverUri = new Uri(url);
        _token = Environment.GetEnvironmentVariable("NAVISWORKS_MCP_TOKEN");
    }

    public void Start()
    {
        if (_runTask is not null && !_runTask.IsCompleted)
        {
            return;
        }

        _runTask = Task.Run(RunAsync);
    }

    public void Dispose()
    {
        _cts.Cancel();
        _socket?.Dispose();
        _sendLock.Dispose();
        _cts.Dispose();
    }

    private async Task RunAsync()
    {
        while (!_cts.IsCancellationRequested)
        {
            try
            {
                using var socket = new ClientWebSocket();
                _socket = socket;
                McpLog.Info($"Connecting to MCP server at {_serverUri}.");
                await socket.ConnectAsync(_serverUri, _cts.Token).ConfigureAwait(false);
                McpLog.Info("Connected to MCP server.");
                await SendHelloAsync(socket).ConfigureAwait(false);
                await ReceiveLoopAsync(socket).ConfigureAwait(false);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                McpLog.Error("MCP server connection failed. Retrying.", ex);
                await Task.Delay(TimeSpan.FromSeconds(2), _cts.Token).ConfigureAwait(false);
            }
            finally
            {
                _socket = null;
            }
        }
    }

    private async Task SendHelloAsync(ClientWebSocket socket)
    {
        var hello = JsonSerializer.Serialize(new { type = "hello", token = _token }, JsonOptions);
        var buffer = Encoding.UTF8.GetBytes(hello);
        await socket.SendAsync(new ArraySegment<byte>(buffer), WebSocketMessageType.Text, true, _cts.Token).ConfigureAwait(false);
    }

    private async Task ReceiveLoopAsync(ClientWebSocket socket)
    {
        var buffer = new byte[64 * 1024];

        while (!_cts.IsCancellationRequested && socket.State == WebSocketState.Open)
        {
            using var message = new MemoryStream();
            WebSocketReceiveResult result;

            do
            {
                result = await socket.ReceiveAsync(new ArraySegment<byte>(buffer), _cts.Token).ConfigureAwait(false);
                if (result.MessageType == WebSocketMessageType.Close)
                {
                    await socket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closing", _cts.Token).ConfigureAwait(false);
                    return;
                }

                message.Write(buffer, 0, result.Count);
            }
            while (!result.EndOfMessage);

            var json = Encoding.UTF8.GetString(message.ToArray());
            var request = JsonSerializer.Deserialize<NavisworksCommandRequest>(json, JsonOptions);
            if (request is null || string.IsNullOrWhiteSpace(request.Id) || string.IsNullOrWhiteSpace(request.Code))
            {
                McpLog.Error($"Ignored invalid MCP request payload: {json}");
                continue;
            }

            McpLog.Info($"Received MCP command {request.Id}.");
            var response = await ExecuteAsync(request).ConfigureAwait(false);
            await SendAsync(response).ConfigureAwait(false);
        }
    }

    private Task<NavisworksCommandResponse> ExecuteAsync(NavisworksCommandRequest request)
    {
        if (_syncContext is null)
        {
            return Task.FromResult(_execute(request));
        }

        var completion = new TaskCompletionSource<NavisworksCommandResponse>();
        _syncContext.Post(
            _ =>
            {
                try
                {
                    completion.SetResult(_execute(request));
                }
                catch (Exception ex)
                {
                    completion.SetException(ex);
                }
            },
            null);
        return completion.Task;
    }

    private async Task SendAsync(NavisworksCommandResponse response)
    {
        var socket = _socket;
        if (socket is null || socket.State != WebSocketState.Open)
        {
            return;
        }

        var json = JsonSerializer.Serialize(response, JsonOptions);
        var buffer = Encoding.UTF8.GetBytes(json);

        await _sendLock.WaitAsync(_cts.Token).ConfigureAwait(false);
        try
        {
            await socket.SendAsync(new ArraySegment<byte>(buffer), WebSocketMessageType.Text, true, _cts.Token).ConfigureAwait(false);
        }
        catch
        {
            // The receive loop handles reconnects. Dropping a response is preferable to blocking Navisworks.
        }
        finally
        {
            _sendLock.Release();
        }
    }
}
