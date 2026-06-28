namespace NavisworksMcpAddin;

public sealed class NavisworksCommandResponse
{
    public string Id { get; set; } = string.Empty;
    public bool Ok { get; set; }
    public string? Result { get; set; }
    public string? Error { get; set; }
    public string? Details { get; set; }
}
