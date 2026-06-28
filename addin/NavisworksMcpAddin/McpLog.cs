using System;
using System.IO;

namespace NavisworksMcpAddin;

public static class McpLog
{
    private static readonly object LockObject = new();

    public static void Info(string message)
    {
        Write("INFO", message);
    }

    public static void Error(string message, Exception? exception = null)
    {
        Write("ERROR", exception is null ? message : $"{message}{Environment.NewLine}{exception}");
    }

    private static void Write(string level, string message)
    {
        try
        {
            var directory = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "NavisworksMcp");
            Directory.CreateDirectory(directory);

            var line = $"{DateTimeOffset.Now:O} [{level}] {message}{Environment.NewLine}";
            lock (LockObject)
            {
                File.AppendAllText(Path.Combine(directory, "addin.log"), line);
            }
        }
        catch
        {
            // Logging must never interfere with Navisworks API execution.
        }
    }
}
