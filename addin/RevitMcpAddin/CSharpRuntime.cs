using System.IO;
using System.Reflection;
using System.Runtime.ExceptionServices;
using Autodesk.Revit.DB;
using Autodesk.Revit.UI;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;

namespace RevitMcpAddin;

public static class CSharpRuntime
{
    public static string Execute(string code, UIApplication app, UIDocument uidoc, Document doc)
    {
        var source = BuildSource(code);
        var syntaxTree = CSharpSyntaxTree.ParseText(source, new CSharpParseOptions(LanguageVersion.Latest));
        var references = BuildReferences();
        var compilation = CSharpCompilation.Create(
            assemblyName: $"RevitMcpScript_{Guid.NewGuid():N}",
            syntaxTrees: new[] { syntaxTree },
            references: references,
            options: new CSharpCompilationOptions(OutputKind.DynamicallyLinkedLibrary));

        using var stream = new MemoryStream();
        var emitResult = compilation.Emit(stream);
        if (!emitResult.Success)
        {
            var diagnostics = string.Join(
                Environment.NewLine,
                emitResult.Diagnostics
                    .Where(diagnostic => diagnostic.Severity is DiagnosticSeverity.Error or DiagnosticSeverity.Warning)
                    .Select(diagnostic => diagnostic.ToString()));

            throw new InvalidOperationException($"Compilation failed:{Environment.NewLine}{diagnostics}");
        }

        stream.Position = 0;
        var assembly = Assembly.Load(stream.ToArray());
        var scriptType = assembly.GetType("RevitMcpRuntime.Script")
            ?? throw new InvalidOperationException("Compiled script type was not found.");
        var script = Activator.CreateInstance(scriptType)
            ?? throw new InvalidOperationException("Could not create compiled script instance.");
        var run = scriptType.GetMethod("Run")
            ?? throw new InvalidOperationException("Compiled script Run method was not found.");

        try
        {
            var value = run.Invoke(script, new object[] { app, uidoc, doc });
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
        return $$"""
using Autodesk.Revit.DB;
using Autodesk.Revit.UI;
using System;
using System.Collections.Generic;
using System.Linq;

namespace RevitMcpRuntime
{
    public sealed class Script
    {
        public string Run(UIApplication app, UIDocument uidoc, Document doc)
        {
{{Indent(code, 12)}}
        }
    }
}
""";
    }

    private static string Indent(string text, int spaces)
    {
        var prefix = new string(' ', spaces);
        return string.Join(
            Environment.NewLine,
            text.Replace("\r\n", "\n").Replace('\r', '\n').Split('\n').Select(line => prefix + line));
    }

    private static IReadOnlyList<MetadataReference> BuildReferences()
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

        return paths
            .Select(path => MetadataReference.CreateFromFile(path))
            .Cast<MetadataReference>()
            .ToList();
    }
}
