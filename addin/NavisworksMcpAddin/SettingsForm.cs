using System.Diagnostics;
using System.Windows.Forms;

namespace NavisworksMcpAddin;

public sealed class SettingsForm : Form
{
    private readonly TextBox _mcpAuthToken = new();
    private readonly TextBox _ngrokAuthToken = new();
    private readonly TextBox _ngrokDomain = new();

    public SettingsForm()
    {
        Text = "Navisworks MCP Settings";
        Width = 560;
        Height = 320;
        MinimizeBox = false;
        MaximizeBox = false;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        StartPosition = FormStartPosition.CenterScreen;

        var settings = NavisworksMcpRuntime.LoadSettings();
        _mcpAuthToken.Text = settings.EffectiveMcpAuthToken;
        _ngrokAuthToken.Text = settings.NgrokAuthToken;
        _ngrokDomain.Text = settings.NgrokDomain;

        var table = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            Padding = new Padding(12),
            ColumnCount = 3,
            RowCount = 7
        };
        table.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 130));
        table.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        table.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 120));

        AddRow(table, 0, "MCP auth token", _mcpAuthToken, Button("Generate", GenerateToken));
        AddRow(table, 1, "ngrok authtoken", _ngrokAuthToken, null);
        AddRow(table, 2, "ngrok domain", _ngrokDomain, Button("Dashboard", OpenNgrokDashboard));

        table.Controls.Add(Button("Copy Local URL", CopyLocalUrl), 1, 4);
        table.Controls.Add(Button("Copy Public URL", CopyPublicUrl), 2, 4);

        var save = Button("Save", Save);
        var cancel = Button("Cancel", (_, _) => Close());
        table.Controls.Add(save, 1, 6);
        table.Controls.Add(cancel, 2, 6);

        Controls.Add(table);
    }

    private static void AddRow(TableLayoutPanel table, int row, string label, Control input, Control? button)
    {
        table.RowStyles.Add(new RowStyle(SizeType.Absolute, 36));
        table.Controls.Add(new Label
        {
            Text = label,
            AutoSize = true,
            Anchor = AnchorStyles.Left
        }, 0, row);

        input.Anchor = AnchorStyles.Left | AnchorStyles.Right;
        table.Controls.Add(input, 1, row);

        if (button is not null)
        {
            table.Controls.Add(button, 2, row);
        }
    }

    private static Button Button(string text, EventHandler click)
    {
        var button = new Button
        {
            Text = text,
            AutoSize = true,
            Anchor = AnchorStyles.Left
        };
        button.Click += click;
        return button;
    }

    private void GenerateToken(object? sender, EventArgs args)
    {
        _mcpAuthToken.Text = Guid.NewGuid().ToString("N");
    }

    private void CopyLocalUrl(object? sender, EventArgs args)
    {
        Clipboard.SetText(NavisworksMcpRuntime.BuildLocalMcpUrl(BuildSettingsFromForm()));
    }

    private void CopyPublicUrl(object? sender, EventArgs args)
    {
        var publicUrl = NavisworksMcpRuntime.BuildPublicMcpUrl(BuildSettingsFromForm());
        if (string.IsNullOrWhiteSpace(publicUrl))
        {
            MessageBox.Show("Configure your fixed ngrok domain first.", "Navisworks MCP");
            return;
        }

        Clipboard.SetText(publicUrl);
    }

    private static void OpenNgrokDashboard(object? sender, EventArgs args)
    {
        Process.Start(new ProcessStartInfo
        {
            FileName = "https://dashboard.ngrok.com/domains",
            UseShellExecute = true
        });
    }

    private void Save(object? sender, EventArgs args)
    {
        var settings = BuildSettingsFromForm();
        settings.NgrokDomain = NavisworksMcpRuntime.NormalizeDomain(settings.NgrokDomain);
        NavisworksMcpRuntime.SaveSettings(settings);
        McpLog.Info("Saved Navisworks MCP settings.");
        Close();
    }

    private NavisworksMcpSettings BuildSettingsFromForm()
    {
        return new NavisworksMcpSettings
        {
            McpAuthToken = _mcpAuthToken.Text.Trim(),
            NgrokAuthToken = _ngrokAuthToken.Text.Trim(),
            NgrokDomain = _ngrokDomain.Text.Trim()
        };
    }
}
