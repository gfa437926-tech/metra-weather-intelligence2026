using Metra.Api.Data;
using Metra.Api.Identity;
using Npgsql;

namespace Metra.Api.Stations;

public interface IStationDirectoryService
{
    Task<StationDirectoryResponse> GetAsync(
        Guid userId,
        int page,
        int pageSize,
        CancellationToken cancellationToken);
}

public sealed class StationDirectoryService(
    MetraDatabase database,
    ICurrentUserService currentUserService) : IStationDirectoryService
{
    public async Task<StationDirectoryResponse> GetAsync(
        Guid userId,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        var currentUser = await currentUserService.GetAsync(userId, cancellationToken);
        if (currentUser is null ||
            !string.Equals(currentUser.ProfileState, "active", StringComparison.Ordinal))
        {
            throw new StationDirectoryAccessDeniedException();
        }

        var stationPermissions = currentUser.Permissions
            .Where(p => string.Equals(p.PermissionCode, "stations.read", StringComparison.Ordinal))
            .ToArray();

        var isGlobal = stationPermissions.Any(p =>
            p.ScopeType == "global" &&
            p.OrganizationId is null &&
            p.UnitId is null &&
            p.StationId is null);

        var organizationIds = stationPermissions
            .Where(p => p.ScopeType == "organization" && p.OrganizationId is not null
                && p.UnitId is null && p.StationId is null)
            .Select(p => p.OrganizationId!.Value)
            .Distinct()
            .ToArray();

        var stationIds = stationPermissions
            .Where(p => p.ScopeType == "station" && p.OrganizationId is not null
                && p.UnitId is null && p.StationId is not null)
            .Select(p => p.StationId!.Value)
            .Distinct()
            .ToArray();

        if (!isGlobal && organizationIds.Length == 0 && stationIds.Length == 0)
        {
            throw new StationDirectoryAccessDeniedException();
        }

        await using var connection = await database.OpenConnectionAsync(cancellationToken);

        const string countSql = """
            select count(*)
            from catalog.stations s
            where s.approval_status = 'approved'
              and (
                @is_global
                or s.owner_organization_id = any(@organization_ids)
                or s.id = any(@station_ids)
              );
            """;

        long total;
        await using (var countCommand = new NpgsqlCommand(countSql, connection))
        {
            countCommand.Parameters.AddWithValue("is_global", isGlobal);
            countCommand.Parameters.AddWithValue("organization_ids", organizationIds);
            countCommand.Parameters.AddWithValue("station_ids", stationIds);
            total = Convert.ToInt64(await countCommand.ExecuteScalarAsync(cancellationToken));
        }

        const string stationSql = """
            select s.id, s.station_code, s.name_ar, s.name_en, st.type_code,
                   s.operational_status, s.approval_status,
                   location.latitude, location.longitude
            from catalog.stations s
            join catalog.station_types st on st.id = s.station_type_id
            left join lateral (
                select sl.latitude, sl.longitude
                from catalog.station_locations sl
                where sl.station_id = s.id
                  and sl.valid_from <= now()
                  and (sl.valid_to is null or sl.valid_to > now())
                order by sl.valid_from desc, sl.id desc
                limit 1
            ) location on true
            where s.approval_status = 'approved'
              and (
                @is_global
                or s.owner_organization_id = any(@organization_ids)
                or s.id = any(@station_ids)
              )
            order by s.name_ar, s.id
            limit @page_size offset @offset;
            """;

        var stations = new List<StationDirectoryItem>();
        await using (var command = new NpgsqlCommand(stationSql, connection))
        {
            command.Parameters.AddWithValue("is_global", isGlobal);
            command.Parameters.AddWithValue("organization_ids", organizationIds);
            command.Parameters.AddWithValue("station_ids", stationIds);
            command.Parameters.AddWithValue("page_size", pageSize);
            command.Parameters.AddWithValue("offset", checked((page - 1) * pageSize));

            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                stations.Add(new StationDirectoryItem(
                    reader.GetGuid(0),
                    reader.GetString(1),
                    reader.GetString(2),
                    reader.GetString(3),
                    reader.GetString(4),
                    reader.GetString(5),
                    reader.GetString(6),
                    reader.IsDBNull(7) ? null : reader.GetDecimal(7),
                    reader.IsDBNull(8) ? null : reader.GetDecimal(8)));
            }
        }

        return new StationDirectoryResponse(stations, total, page, pageSize);
    }
}
