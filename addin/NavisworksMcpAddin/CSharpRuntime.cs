using System;
using System.CodeDom.Compiler;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.ExceptionServices;
using Autodesk.Navisworks.Api;
using Microsoft.CSharp;

namespace NavisworksMcpAddin;

public static class CSharpRuntime
{
    public static string Execute(string code, Document doc)
    {
        var source = BuildSource(code);
        using var provider = new CSharpCodeProvider();
        var parameters = new CompilerParameters
        {
            GenerateExecutable = false,
            GenerateInMemory = true,
            IncludeDebugInformation = false,
            TreatWarningsAsErrors = false
        };
        foreach (var reference in BuildReferences())
        {
            parameters.ReferencedAssemblies.Add(reference);
        }

        var compileResult = provider.CompileAssemblyFromSource(parameters, source);
        if (compileResult.Errors.HasErrors)
        {
            var sourcePath = WriteFailedSource(source);
            var diagnostics = string.Join(
                Environment.NewLine,
                compileResult.Errors
                    .Cast<CompilerError>()
                    .Where(error => !error.IsWarning)
                    .Select(error => error.ToString()));

            throw new InvalidOperationException(
                $"Compilation failed. Generated source: {sourcePath}{Environment.NewLine}{diagnostics}");
        }

        var assembly = compileResult.CompiledAssembly;
        var scriptType = assembly.GetType("NavisworksMcpRuntime.Script")
            ?? throw new InvalidOperationException("Compiled script type was not found.");
        var script = Activator.CreateInstance(scriptType)
            ?? throw new InvalidOperationException("Could not create compiled script instance.");
        var run = scriptType.GetMethod("Run")
            ?? throw new InvalidOperationException("Compiled script Run method was not found.");

        try
        {
            var value = run.Invoke(script, new object[] { doc });
            return value?.ToString() ?? string.Empty;
        }
        catch (TargetInvocationException ex) when (ex.InnerException is not null)
        {
            ExceptionDispatchInfo.Capture(ex.InnerException).Throw();
            throw;
        }
    }

    private static string BuildSource(string code)
    {
        return @"
using Autodesk.Navisworks.Api;
using System;
using System.Collections.Generic;
using System.Linq;

namespace NavisworksMcpRuntime
{
    public sealed class Script
    {
        public string Run(Document doc)
        {
" + Indent(code, 12) + @"
        }
    }
}
";
    }

    private static string WriteFailedSource(string source)
    {
        try
        {
            var directory = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "NavisworksMcp",
                "failed-sources");
            Directory.CreateDirectory(directory);

            var path = Path.Combine(directory, $"failed-{DateTimeOffset.Now:yyyyMMdd-HHmmss-fff}.cs");
            File.WriteAllText(path, source);
            return path;
        }
        catch (Exception ex)
        {
            return $"<could not write generated source: {ex.Message}>";
        }
    }

    private static string Indent(string text, int spaces)
    {
        var prefix = new string(' ', spaces);
        return string.Join(
            Environment.NewLine,
            text.Replace("\r\n", "\n").Replace('\r', '\n').Split('\n').Select(line => prefix + line));
    }

    private static IReadOnlyList<string> BuildReferences()
    {
        var paths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        if (AppContext.GetData("TRUSTED_PLATFORM_ASSEMBLIES") is string trustedPlatformAssemblies)
        {
            foreach (var path in trustedPlatformAssemblies.Split(Path.PathSeparator))
            {
                if (!string.IsNullOrWhiteSpace(path) && File.Exists(path))
                {
                    paths.Add(path);
                }
            }
        }

        foreach (var assembly in AppDomain.CurrentDomain.GetAssemblies())
        {
            if (!assembly.IsDynamic && !string.IsNullOrWhiteSpace(assembly.Location) && File.Exists(assembly.Location))
            {
                paths.Add(assembly.Location);
            }
        }

        return paths.ToList();
    }
}
