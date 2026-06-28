using System.Diagnostics;
using System.IO;
using System.Net.Sockets;

namespace NavisworksMcpAddin;

public sealed class McpProcessManager
{
    private readonly object _lockObject = new();
    private Process? _process;

    public bool StartedByAddin
    {
        get
        {
            lock (_lockObject)
            {
                return _process is { HasExited: false };
            }
        }
    }

    public string Status
    {
        get
        {
            var httpOpen = IsPortOpen("127.0.0.1", NavisworksMcpRuntime.HttpPort);
            var wsOpen = IsPortOpen("127.0.0.1", NavisworksMcpRuntime.WebSocketPort);

            if (httpOpen && wsOpen)
            {
                var state = NavisworksMcpRuntime.LoadRuntimeState();
                var pid = state.ServerProcessId > 0 ? $" PID {state.ServerProcessId}." : "";
                return StartedByAddin ? "MCP server is running and was started by this Navisworks session." : "MCP server appears to be running." + pid;
            }

            if (httpOpen || wsOpen)
            {
                return $"Partial MCP server state. HTTP {OpenClosed(httpOpen)}, WebSocket {OpenClosed(wsOpen)}.";
            }

            return "MCP server is stopped.";
        }
    }

    public McpProcessResult Start()
    {
        lock (_lockObject)
        {
            var serverPath = FindServerExecutable();
            if (serverPath is null)
            {
                return McpProcessResult.Failure("Could not find NavisworksMcpServer.exe. Reinstall Navisworks MCP or build the release package.");
            }

            CleanupStaleRuntimeProcess(serverPath);

            if (_process is { HasExited: false })
            {
                return McpProcessResult.Success("MCP server is already running from this Navisworks session.");
            }

            var httpOpen = IsPortOpen("127.0.0.1", NavisworksMcpRuntime.HttpPort);
            var wsOpen = IsPortOpen("127.0.0.1", NavisworksMcpRuntime.WebSocketPort);
            if (httpOpen && wsOpen)
            {
                var state = NavisworksMcpRuntime.LoadRuntimeState();
                if (state.ServerProcessId > 0)
                {
                    CleanupSiblingServerProcesses(serverPath, state.ServerProcessId);
                    return McpProcessResult.Success($"MCP server is already running on PID {state.ServerProcessId}.");
                }

                return McpProcessResult.Success("MCP server appears to already be running, but it was not started by this add-in.");
            }

            if (httpOpen || wsOpen)
            {
                return McpProcessResult.Failure($"Cannot start MCP server because ports are partially busy. HTTP {OpenClosed(httpOpen)}, WebSocket {OpenClosed(wsOpen)}.");
            }

            var settings = NavisworksMcpRuntime.LoadSettings();
            var startInfo = new ProcessStartInfo
            {
                FileName = serverPath,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };

            startInfo.EnvironmentVariables["MCP_TRANSPORT"] = "streamable-http";
            startInfo.EnvironmentVariables["MCP_HTTP_HOST"] = "127.0.0.1";
            startInfo.EnvironmentVariables["MCP_HTTP_PORT"] = NavisworksMcpRuntime.HttpPort.ToString();
            startInfo.EnvironmentVariables["MCP_HTTP_PATH"] = NavisworksMcpRuntime.BuildMcpPath(settings);
            startInfo.EnvironmentVariables["MCP_DISABLE_DNS_REBINDING_PROTECTION"] = "true";
            startInfo.EnvironmentVariables["NAVISWORKS_MCP_HOST"] = "127.0.0.1";
            startInfo.EnvironmentVariables["NAVISWORKS_MCP_PORT"] = NavisworksMcpRuntime.WebSocketPort.ToString();
            startInfo.EnvironmentVariables["NAVISWORKS_MCP_TOKEN"] = settings.McpAuthToken;

            var process = new Process
            {
                StartInfo = startInfo,
                EnableRaisingEvents = true
            };
            process.OutputDataReceived += (_, args) => LogProcessLine(args.Data);
            process.ErrorDataReceived += (_, args) => LogProcessLine(args.Data);
            process.Exited += (_, _) => McpLog.Info($"NavisworksMcpServer.exe exited with code {process.ExitCode}.");

            try
            {
                process.Start();
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
                _process = process;

                var runtimeState = NavisworksMcpRuntime.LoadRuntimeState();
                runtimeState.ServerProcessId = process.Id;
                runtimeState.ServerPath = serverPath;
                runtimeState.ServerStartedAt = DateTimeOffset.Now;
                NavisworksMcpRuntime.SaveRuntimeState(runtimeState);

                McpLog.Info($"Started MCP server process {process.Id}: {serverPath}");
                return McpProcessResult.Success($"MCP server started on PID {process.Id}.");
            }
            catch (Exception ex)
            {
                process.Dispose();
                McpLog.Error("Could not start MCP server.", ex);
                return McpProcessResult.Failure($"Could not start MCP server: {ex.Message}");
            }
        }
    }

    public McpProcessResult Stop()
    {
        lock (_lockObject)
        {
            var serverPath = FindServerExecutable();

            if (_process is null || _process.HasExited)
            {
                _process?.Dispose();
                _process = null;
                var state = NavisworksMcpRuntime.LoadRuntimeState();
                if (TryStopRuntimeProcess(state.ServerProcessId, state.ServerPath))
                {
                    ClearServerRuntimeState();
                    return McpProcessResult.Success($"Stopped MCP server process PID {state.ServerProcessId}.");
                }

                var stoppedCount = StopMatchingServerProcesses(serverPath);
                if (stoppedCount > 0)
                {
                    ClearServerRuntimeState();
                    return McpProcessResult.Success($"Stopped {stoppedCount} stale MCP server process(es).");
                }

                ClearServerRuntimeState();
                return McpProcessResult.Success("No MCP server process started by this Navisworks session was found.");
            }

            try
            {
                KillProcessTree(_process);
                _process.WaitForExit(3000);
                McpLog.Info("Stopped MCP server process started by this Navisworks session.");
                _process.Dispose();
                _process = null;
                StopMatchingServerProcesses(serverPath);
                ClearServerRuntimeState();
                return McpProcessResult.Success("MCP server stopped.");
            }
            catch (Exception ex)
            {
                McpLog.Error("Could not stop MCP server.", ex);
                return McpProcessResult.Failure($"Could not stop MCP server: {ex.Message}");
            }
        }
    }

    public void StopOnShutdown()
    {
        lock (_lockObject)
        {
            if (_process is { HasExited: false })
            {
                try
                {
                    KillProcessTree(_process);
                    _process.WaitForExit(1500);
                    McpLog.Info("Stopped MCP server during Navisworks shutdown.");
                }
                catch (Exception ex)
                {
                    McpLog.Error("Could not stop MCP server during Navisworks shutdown.", ex);
                }
                finally
                {
                    _process.Dispose();
                    _process = null;
                    ClearServerRuntimeState();
                }
            }

            var serverPath = FindServerExecutable();
            var state = NavisworksMcpRuntime.LoadRuntimeState();
            if (TryStopRuntimeProcess(state.ServerProcessId, state.ServerPath))
            {
                McpLog.Info($"Stopped MCP server process PID {state.ServerProcessId} during Navisworks shutdown.");
                ClearServerRuntimeState();
                return;
            }

            var stoppedCount = StopMatchingServerProcesses(serverPath);
            if (stoppedCount > 0)
            {
                McpLog.Info($"Stopped {stoppedCount} stale MCP server process(es) during Navisworks shutdown.");
                ClearServerRuntimeState();
                return;
            }

            ClearServerRuntimeState();
        }
    }

    private static string? FindServerExecutable()
    {
        var localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        var candidates = new[]
        {
            Path.Combine(localAppData, "NavisworksMcp", "app", "NavisworksMcpServer.exe"),
            Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "NavisworksMcpServer.exe")
        };

        return candidates.FirstOrDefault(File.Exists);
    }

    private static bool IsPortOpen(string host, int port)
    {
        try
        {
            using var client = new TcpClient();
            var result = client.BeginConnect(host, port, null, null);
            var success = result.AsyncWaitHandle.WaitOne(TimeSpan.FromMilliseconds(350));
            if (!success)
            {
                return false;
            }

            client.EndConnect(result);
            return true;
        }
        catch
        {
            return false;
        }
    }

    internal static bool PortIsOpen(string host, int port)
    {
        return IsPortOpen(host, port);
    }

    private static void CleanupStaleRuntimeProcess(string expectedServerPath)
    {
        var state = NavisworksMcpRuntime.LoadRuntimeState();
        if (state.ServerProcessId <= 0)
        {
            return;
        }

        var process = GetProcessById(state.ServerProcessId);
        if (process is null)
        {
            ClearServerRuntimeState();
            return;
        }

        using (process)
        {
            if (!SamePath(SafeProcessPath(process), expectedServerPath))
            {
                return;
            }

            var httpOpen = IsPortOpen("127.0.0.1", NavisworksMcpRuntime.HttpPort);
            var wsOpen = IsPortOpen("127.0.0.1", NavisworksMcpRuntime.WebSocketPort);
            if (httpOpen && wsOpen)
            {
                return;
            }

            try
            {
                KillProcessTree(process);
                process.WaitForExit(2000);
                McpLog.Info($"Stopped stale MCP server process PID {state.ServerProcessId}.");
                ClearServerRuntimeState();
            }
            catch (Exception ex)
            {
                McpLog.Error($"Could not stop stale MCP server process PID {state.ServerProcessId}.", ex);
            }
        }
    }

    private static void CleanupSiblingServerProcesses(string expectedServerPath, int keepProcessId)
    {
        foreach (var process in Process.GetProcessesByName("NavisworksMcpServer"))
        {
            using (process)
            {
                if (process.Id == keepProcessId)
                {
                    continue;
                }

                if (!SamePath(SafeProcessPath(process), expectedServerPath))
                {
                    continue;
                }

                try
                {
                    KillProcessTree(process);
                    process.WaitForExit(2000);
                    McpLog.Info($"Stopped orphan NavisworksMcpServer.exe sibling PID {process.Id}; keeping PID {keepProcessId}.");
                }
                catch (Exception ex)
                {
                    McpLog.Error($"Could not stop orphan NavisworksMcpServer.exe sibling PID {process.Id}.", ex);
                }
            }
        }
    }

    private static bool TryStopRuntimeProcess(int processId, string expectedPath)
    {
        if (processId <= 0)
        {
            return false;
        }

        var process = GetProcessById(processId);
        if (process is null)
        {
            return false;
        }

        using (process)
        {
            if (!SamePath(SafeProcessPath(process), expectedPath))
            {
                return false;
            }

            try
            {
                KillProcessTree(process);
                process.WaitForExit(3000);
                return true;
            }
            catch (Exception ex)
            {
                McpLog.Error($"Could not stop runtime MCP process PID {processId}.", ex);
                return false;
            }
        }
    }

    private static int StopMatchingServerProcesses(string? expectedServerPath)
    {
        var expectedPath = expectedServerPath ?? "";
        var stopped = 0;
        foreach (var process in Process.GetProcessesByName("NavisworksMcpServer"))
        {
            using (process)
            {
                if (process.HasExited)
                {
                    continue;
                }

                if (!string.IsNullOrWhiteSpace(expectedPath) && !SamePath(SafeProcessPath(process), expectedPath))
                {
                    continue;
                }

                try
                {
                    KillProcessTree(process);
                    process.WaitForExit(3000);
                    stopped++;
                    McpLog.Info($"Stopped stale NavisworksMcpServer.exe process PID {process.Id}.");
                }
                catch (Exception ex)
                {
                    McpLog.Error($"Could not stop stale NavisworksMcpServer.exe process PID {process.Id}.", ex);
                }
            }
        }

        return stopped;
    }

    private static void KillProcessTree(Process process)
    {
        try
        {
            using var taskkill = Process.Start(new ProcessStartInfo
            {
                FileName = "taskkill.exe",
                Arguments = $"/PID {process.Id} /T /F",
                CreateNoWindow = true,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            });
            taskkill?.WaitForExit(3000);
        }
        catch (Exception ex)
        {
            McpLog.Error($"Could not stop process tree for PID {process.Id}; falling back to direct kill.", ex);
            process.Kill();
        }
    }

    private static Process? GetProcessById(int processId)
    {
        try
        {
            var process = Process.GetProcessById(processId);
            return process.HasExited ? null : process;
        }
        catch
        {
            return null;
        }
    }

    private static string SafeProcessPath(Process process)
    {
        try
        {
            return process.MainModule?.FileName ?? "";
        }
        catch
        {
            return "";
        }
    }

    private static bool SamePath(string left, string right)
    {
        if (string.IsNullOrWhiteSpace(left) || string.IsNullOrWhiteSpace(right))
        {
            return false;
        }

        return string.Equals(
            Path.GetFullPath(left).TrimEnd('\\'),
            Path.GetFullPath(right).TrimEnd('\\'),
            StringComparison.OrdinalIgnoreCase);
    }

    private static void ClearServerRuntimeState()
    {
        var state = NavisworksMcpRuntime.LoadRuntimeState();
        state.ServerProcessId = 0;
        state.ServerPath = "";
        state.ServerStartedAt = default;
        NavisworksMcpRuntime.SaveRuntimeState(state);
    }

    private static string OpenClosed(bool open)
    {
        return open ? "open" : "closed";
    }

    private static void LogProcessLine(string? line)
    {
        if (!string.IsNullOrWhiteSpace(line))
        {
            McpLog.Info("[server] " + line);
        }
    }
}

public sealed class McpProcessResult
{
    public McpProcessResult(bool ok, string message)
    {
        Ok = ok;
        Message = message;
    }

    public bool Ok { get; }
    public string Message { get; }

    public static McpProcessResult Success(string message)
    {
        return new McpProcessResult(true, message);
    }

    public static McpProcessResult Failure(string message)
    {
        return new McpProcessResult(false, message);
    }
}
