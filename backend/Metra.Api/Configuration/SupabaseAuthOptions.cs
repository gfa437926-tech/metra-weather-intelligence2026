namespace Metra.Api.Configuration;

public sealed class SupabaseAuthOptions
{
    public const string SectionName = "SupabaseAuth";

    public string Authority { get; init; } = string.Empty;

    public string Audience { get; init; } = "authenticated";
}
