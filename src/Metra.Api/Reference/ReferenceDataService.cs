using Metra.Api.Data;
using Npgsql;

namespace Metra.Api.Reference;

public interface IReferenceDataService
{
    Task<IReadOnlyList<ObservationTypeItem>> GetObservationTypesAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<ParameterItem>> GetParametersAsync(CancellationToken cancellationToken);
}

public sealed class ReferenceDataService(MetraDatabase database) : IReferenceDataService
{
    public async Task<IReadOnlyList<ObservationTypeItem>> GetObservationTypesAsync(
        CancellationToken cancellationToken)
    {
        await using var connection = await database.OpenConnectionAsync(cancellationToken);
        const string sql = """
            select id, type_code, name_ar, name_en, cadence_code, schema_version
            from ref.observation_types
            where is_active = true
            order by type_code;
            """;
        await using var command = new NpgsqlCommand(sql, connection);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var items = new List<ObservationTypeItem>();
        while (await reader.ReadAsync(cancellationToken))
        {
            items.Add(new ObservationTypeItem(
                reader.GetGuid(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetString(3),
                reader.IsDBNull(4) ? null : reader.GetString(4),
                reader.GetString(5)));
        }
        return items;
    }

    public async Task<IReadOnlyList<ParameterItem>> GetParametersAsync(
        CancellationToken cancellationToken)
    {
        await using var connection = await database.OpenConnectionAsync(cancellationToken);
        const string sql = """
            select p.id, p.parameter_code, p.name_ar, p.name_en, p.description,
                   p.value_kind, p.canonical_unit_id, u.unit_code, u.symbol,
                   p.precision_scale, p.definition_version
            from ref.parameters p
            left join ref.units u on u.id = p.canonical_unit_id
            where p.is_active = true
            order by p.parameter_code;
            """;
        await using var command = new NpgsqlCommand(sql, connection);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var items = new List<ParameterItem>();
        while (await reader.ReadAsync(cancellationToken))
        {
            items.Add(new ParameterItem(
                reader.GetGuid(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetString(3),
                reader.IsDBNull(4) ? null : reader.GetString(4),
                reader.GetString(5),
                reader.IsDBNull(6) ? null : reader.GetGuid(6),
                reader.IsDBNull(7) ? null : reader.GetString(7),
                reader.IsDBNull(8) ? null : reader.GetString(8),
                reader.IsDBNull(9) ? null : reader.GetInt16(9),
                reader.GetString(10)));
        }
        return items;
    }
}
