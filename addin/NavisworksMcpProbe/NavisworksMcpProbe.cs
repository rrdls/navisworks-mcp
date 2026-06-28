using System;
using System.IO;
using System.Reflection;
using Autodesk.Navisworks.Api.Plugins;

namespace NavisworksMcpProbe;

[Plugin(
    "NavisworksMcpProbe.AutoStart",
    "RRDL",
    DisplayName = "Navisworks MCP Probe Auto Start",
    ToolTip = "Writes a diagnostic log when Navisworks loads the MCP probe.")]
public sealed class NavisworksMcpProbeEventWatcher : EventWatcherPlugin
{
    static NavisworksMcpProbeEventWatcher()
    {
        ProbeLog.Write("EventWatcher static constructor reached.");
    }

    public NavisworksMcpProbeEventWatcher()
    {
        ProbeLog.Write("EventWatcher instance constructed.");
    }

    public override void OnLoaded()
    {
        ProbeLog.Write("EventWatcher OnLoaded reached.");
    }

    public override void OnUnloading()
    {
        ProbeLog.Write("EventWatcher OnUnloading reached.");
    }
}

[Plugin(
    "NavisworksMcpProbe.Plugin",
    "RRDL",
    DisplayName = "Navisworks MCP Probe",
    ToolTip = "Writes a diagnostic log entry for Navisworks MCP.")]
[AddInPlugin(AddInLocation.AddIn)]
public sealed class NavisworksMcpProbePlugin : AddInPlugin
{
    static NavisworksMcpProbePlugin()
    {
        ProbeLog.Write("AddInPlugin static constructor reached.");
    }

    public NavisworksMcpProbePlugin()
    {
        ProbeLog.Write("AddInPlugin instance constructed.");
    }

    public override int Execute(params string[] parameters)
    {
        ProbeLog.Write("AddInPlugin Execute reached.");
        return 0;
    }
}

internal static class ProbeLog
{
    private static readonly object LockObject = new();

    static ProbeLog()
    {
        Write("ProbeLog static constructor reached.");
        Write($"Assembly: {Assembly.GetExecutingAssembly().Location}");
        Write($"Process: {Environment.CommandLine}");
        Write($".NET: {Environment.Version}");
    }

    public static void Write(string message)
    {
        try
        {
            var directory = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "NavisworksMcp");
            Directory.CreateDirectory(directory);

            var line = $"{DateTimeOffset.Now:O} [PROBE] {message}{Environment.NewLine}";
            lock (LockObject)
            {
                File.AppendAllText(Path.Combine(directory, "probe.log"), line);
            }
        }
        catch
        {
            // Diagnostics must never interfere with Navisworks plugin loading.
        }
    }
}
