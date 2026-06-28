using System.Diagnostics;
using System.IO;
using System.Web.Script.Serialization;

namespace NavisworksMcpAddin;

public static class NavisworksMcpRuntime
{
    public const int HttpPort = 8000;
    public const int WebSocketPort = 8765;

    private static readonly object LockObject = new();
    private static readonly JavaScriptSerializer JsonSerializer = new();

    public static McpProcessManager McpProcess { get; } = new();
    public static NgrokProcessManager NgrokProcess { get; } = new();

    public static string AppDataDirectory
    {
        get
        {
            var directory = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "NavisworksMcp");
            Directory.CreateDirectory(directory);
            return directory;
        }
    }

    public static string SettingsPath => Path.Combine(AppDataDirectory, "settings.json");
    public static string RuntimePath => Path.Combine(AppDataDirectory, "runtime.json");
    public static string NgrokConfigPath => Path.Combine(AppDataDirectory, "ngrok.yml");

    public static string LocalMcpUrl => BuildLocalMcpUrl(LoadSettings());

    public static string BuildMcpPath(NavisworksMcpSettings settings)
    {
        return "/" + settings.EffectiveMcpAuthToken.Trim('/') + "/mcp";
    }

    public static string BuildLocalMcpUrl(NavisworksMcpSettings settings)
    {
        return "http://127.0.0.1:" + HttpPort + BuildMcpPath(settings);
    }

    public static string? BuildPublicMcpUrl(NavisworksMcpSettings settings)
    {
        if (string.IsNullOrWhiteSpace(settings.NgrokDomain))
        {
            return null;
        }

        return "https://" + NormalizeDomain(settings.NgrokDomain) + BuildMcpPath(settings);
    }

    public static void Initialize()
    {
        EnsureSettings();
    }

    public static NavisworksMcpSettings LoadSettings()
    {
        lock (LockObject)
        {
            EnsureSettings();
            try
            {
                var json = File.ReadAllText(SettingsPath);
                return JsonSerializer.Deserialize<NavisworksMcpSettings>(json) ?? NavisworksMcpSettings.CreateDefault();
            }
            catch
            {
                var settings = NavisworksMcpSettings.CreateDefault();
                SaveSettings(settings);
                return settings;
            }
        }
    }

    public static void SaveSettings(NavisworksMcpSettings settings)
    {
        lock (LockObject)
        {
            Directory.CreateDirectory(AppDataDirectory);
            File.WriteAllText(SettingsPath, JsonSerializer.Serialize(settings));
        }
    }

    public static NavisworksMcpRuntimeState LoadRuntimeState()
    {
        lock (LockObject)
        {
            if (!File.Exists(RuntimePath))
            {
                return new NavisworksMcpRuntimeState();
            }

            try
            {
                var json = File.ReadAllText(RuntimePath);
                return JsonSerializer.Deserialize<NavisworksMcpRuntimeState>(json) ?? new NavisworksMcpRuntimeState();
            }
            catch
            {
                return new NavisworksMcpRuntimeState();
            }
        }
    }

    public static void SaveRuntimeState(NavisworksMcpRuntimeState state)
    {
        lock (LockObject)
        {
            Directory.CreateDirectory(AppDataDirectory);
            File.WriteAllText(RuntimePath, JsonSerializer.Serialize(state));
        }
    }

    public static void OpenAppDataDirectory()
    {
        Directory.CreateDirectory(AppDataDirectory);
        Process.Start(new ProcessStartInfo
        {
            FileName = AppDataDirectory,
            UseShellExecute = true
        });
    }

    public static string NormalizeDomain(string value)
    {
        var domain = value.Trim();
        if (domain.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            domain = domain.Substring("https://".Length);
        }
        else if (domain.StartsWith("http://", StringComparison.OrdinalIgnoreCase))
        {
            domain = domain.Substring("http://".Length);
        }

        return domain.Trim().TrimEnd('/');
    }

    private static void EnsureSettings()
    {
        if (File.Exists(SettingsPath))
        {
            return;
        }

        SaveSettings(NavisworksMcpSettings.CreateDefault());
    }
}

public sealed class NavisworksMcpSettings
{
    public string NgrokAuthToken { get; set; } = "";
    public string NgrokDomain { get; set; } = "";
    public string McpAuthToken { get; set; } = "";

    public string EffectiveMcpAuthToken
    {
        get
        {
            if (!string.IsNullOrWhiteSpace(McpAuthToken))
            {
                return McpAuthToken.Trim();
            }

            McpAuthToken = Guid.NewGuid().ToString("N");
            return McpAuthToken;
        }
    }

    public static NavisworksMcpSettings CreateDefault()
    {
        return new NavisworksMcpSettings
        {
            McpAuthToken = Guid.NewGuid().ToString("N")
        };
    }
}

public sealed class NavisworksMcpRuntimeState
{
    public int ServerProcessId { get; set; }
    public string ServerPath { get; set; } = "";
    public DateTimeOffset ServerStartedAt { get; set; }
    public int NgrokProcessId { get; set; }
    public string NgrokPath { get; set; } = "";
    public DateTimeOffset NgrokStartedAt { get; set; }
}
