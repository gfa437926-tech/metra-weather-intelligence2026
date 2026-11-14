using Npgsql;
using System.Net;

namespace Metra.Api.Data;

public sealed class MetraDatabase : IAsyncDisposable
{
    private readonly NpgsqlDataSource? _dataSource;

    public MetraDatabase(IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("Metra")
            ?? configuration["METRA_DATABASE_CONNECTION_STRING"]
            ?? Environment.GetEnvironmentVariable("METRA_DATABASE_CONNECTION_STRING");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return;
        }

        var builder = new NpgsqlConnectionStringBuilder(connectionString);
        var allowInsecureLocalhost = configuration.GetValue<bool>(
            "MetraDatabase:AllowInsecureLocalhost");
        var isLoopbackHost = builder.Host.Equals("localhost", StringComparison.OrdinalIgnoreCase)
            || (IPAddress.TryParse(builder.Host, out var address) && IPAddress.IsLoopback(address));

        builder.SslMode = allowInsecureLocalhost && isLoopbackHost
            ? SslMode.Disable
            : SslMode.VerifyFull;
        builder.Timeout = 15;
        builder.CommandTimeout = 30;
        builder.Pooling = true;
        builder.MaxPoolSize = 20;
        _dataSource = NpgsqlDataSource.Create(builder.ConnectionString);
    }

    public bool IsConfigured => _dataSource is not null;

    public async ValueTask<NpgsqlConnection> OpenConnectionAsync(
        CancellationToken cancellationToken = default)
    {
        if (_dataSource is null)
        {
            throw new DatabaseNotConfiguredException();
        }

        return await _dataSource.OpenConnectionAsync(cancellationToken);
    }

    public async Task<bool> ProbeAsync(CancellationToken cancellationToken = default)
    {
        if (_dataSource is null)
        {
            return false;
        }

        await using var connection = await _dataSource.OpenConnectionAsync(cancellationToken);
        await using var command = new NpgsqlCommand("select 1", connection);
        return await command.ExecuteScalarAsync(cancellationToken) is int value && value == 1;
    }

    public async ValueTask DisposeAsync()
    {
        if (_dataSource is not null)
        {
            await _dataSource.DisposeAsync();
        }
    }
}

public sealed class DatabaseNotConfiguredException : Exception
{
    public DatabaseNotConfiguredException()
        : base("The server-side METRA database connection is not configured.")
    {
    }
}
