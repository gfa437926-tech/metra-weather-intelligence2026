using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Xunit;

namespace Metra.Api.Tests;

public sealed class DatabaseFactAttribute : FactAttribute
{
    public DatabaseFactAttribute()
    {
        if (string.IsNullOrWhiteSpace(
                Environment.GetEnvironmentVariable("METRA_TEST_DATABASE_CONNECTION_STRING")))
        {
            Skip = "Requires the disposable, migrated Supabase integration database.";
        }
    }
}

public sealed class MetraApiIntegrationTests
{
    [DatabaseFact]
    public async Task Readiness_probes_the_disposable_database_through_the_runtime_login()
    {
        using var factory = CreateFactory();
        using var client = factory.CreateClient();

        using var response = await client.GetAsync("/health/ready");

        Assert.Equal(System.Net.HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("\"ready\"", body, StringComparison.Ordinal);
    }

    [DatabaseFact]
    public async Task Current_user_endpoint_executes_profile_query_with_least_privilege_role()
    {
        using var factory = CreateFactory();
        using var client = factory.CreateClient();

        using var response = await client.GetAsync("/api/v1/me");

        // The database is intentionally empty. A 403 means the authenticated request
        // reached the profile query and found no profile; 503 would indicate a DB/schema
        // or connection failure, and 200 would indicate unexpected seeded user data.
        Assert.Equal(System.Net.HttpStatusCode.Forbidden, response.StatusCode);
    }

    private static MetraApiFactory CreateFactory()
    {
        var connectionString = Environment.GetEnvironmentVariable(
            "METRA_TEST_DATABASE_CONNECTION_STRING");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "METRA_TEST_DATABASE_CONNECTION_STRING is required for database integration tests.");
        }

        return new MetraApiFactory(connectionString);
    }
}

internal sealed class MetraApiFactory(string connectionString) : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.ConfigureAppConfiguration((_, configuration) =>
        {
            configuration.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Supabase:Url"] = "https://integration-test.supabase.co",
                ["METRA_DATABASE_CONNECTION_STRING"] = connectionString,
                ["MetraDatabase:AllowInsecureLocalhost"] = "true"
            });
        });

        builder.ConfigureTestServices(services =>
        {
            services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = IntegrationAuthenticationHandler.Scheme;
                options.DefaultChallengeScheme = IntegrationAuthenticationHandler.Scheme;
                options.DefaultForbidScheme = IntegrationAuthenticationHandler.Scheme;
            }).AddScheme<AuthenticationSchemeOptions, IntegrationAuthenticationHandler>(
                IntegrationAuthenticationHandler.Scheme, _ => { });
        });
    }
}

internal sealed class IntegrationAuthenticationHandler(
    IOptionsMonitor<AuthenticationSchemeOptions> options,
    ILoggerFactory logger,
    UrlEncoder encoder)
    : AuthenticationHandler<AuthenticationSchemeOptions>(options, logger, encoder)
{
    public const string Scheme = "METRA-Integration";

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var userId = Guid.Parse("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa");
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
            new Claim("sub", userId.ToString())
        };
        var identity = new ClaimsIdentity(claims, Scheme);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, Scheme);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
