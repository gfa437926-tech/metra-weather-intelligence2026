using Metra.Api.Data;
using Metra.Api.Identity;
using Npgsql;
using NpgsqlTypes;

namespace Metra.Api.Alerts;

public interface IAlertService
{
    Task<AlertListResponse> GetForUserAsync(
        Guid userId, int page, int pageSize, CancellationToken cancellationToken);
}

public sealed class AlertService(
    MetraDatabase database,
    ICurrentUserService currentUserService) : IAlertService
{
    public async Task<AlertListResponse> GetForUserAsync(
        Guid userId,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        var user = await currentUserService.GetAsync(userId, cancellationToken);
        if (user is null || user.ProfileState != "active")
            throw new AlertAccessDeniedException();

        var scope = AlertReadScope.TryResolve(user.Permissions);
        if (scope is null)
            throw new AlertAccessDeniedException();

        await using var connection = await database.OpenConnectionAsync(cancellationToken);
        const string filter = """
            from alerts.alert_events ae
            join alerts.alert_recipients ar on ar.alert_event_id = ae.id
            where (
                ar.user_id = @user_id
                or @is_global
                or ar.organization_id = any(@organization_ids)
                or ar.station_id = any(@station_ids)
            )
            """;

        long total;
        await using (var countCommand = new NpgsqlCommand($"select count(distinct ae.id) {filter}", connection))
        {
            AddScopeParameters(countCommand, userId, scope);
            total = Convert.ToInt64(await countCommand.ExecuteScalarAsync(cancellationToken));
        }

        const string sql = """
            select ae.id, ae.alert_code, ae.severity, ae.headline, ae.description,
                   ae.area_reference, ae.starts_at, ae.ends_at, ae.event_state,
                   ae.created_at, max(ar.acknowledged_at) filter (where ar.user_id = @user_id)
            from alerts.alert_events ae
            join alerts.alert_recipients ar on ar.alert_event_id = ae.id
            where (
                ar.user_id = @user_id
                or @is_global
                or ar.organization_id = any(@organization_ids)
                or ar.station_id = any(@station_ids)
            )
            group by ae.id
            order by coalesce(ae.starts_at, ae.created_at) desc, ae.id
            limit @page_size offset @offset;
            """;

        await using var command = new NpgsqlCommand(sql, connection);
        AddScopeParameters(command, userId, scope);
        command.Parameters.AddWithValue("page_size", pageSize);
        command.Parameters.AddWithValue("offset", checked((page - 1) * pageSize));

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var items = new List<AlertListItem>();
        while (await reader.ReadAsync(cancellationToken))
        {
            items.Add(new AlertListItem(
                reader.GetGuid(0),
                reader.IsDBNull(1) ? null : reader.GetString(1),
                reader.GetString(2),
                reader.GetString(3),
                reader.IsDBNull(4) ? null : reader.GetString(4),
                reader.IsDBNull(5) ? null : reader.GetString(5),
                reader.IsDBNull(6) ? null : reader.GetFieldValue<DateTimeOffset>(6),
                reader.IsDBNull(7) ? null : reader.GetFieldValue<DateTimeOffset>(7),
                reader.GetString(8),
                reader.GetFieldValue<DateTimeOffset>(9),
                reader.IsDBNull(10) ? null : reader.GetFieldValue<DateTimeOffset>(10)));
        }

        return new AlertListResponse(items, total, page, pageSize);
    }

    private static void AddScopeParameters(
        NpgsqlCommand command,
        Guid userId,
        AlertReadScope scope)
    {
        command.Parameters.AddWithValue("user_id", userId);
        command.Parameters.AddWithValue("is_global", scope.IsGlobal);
        command.Parameters.Add(new NpgsqlParameter<Guid[]>(
            "organization_ids", NpgsqlDbType.Array | NpgsqlDbType.Uuid)
        {
            TypedValue = scope.OrganizationIds
        });
        command.Parameters.Add(new NpgsqlParameter<Guid[]>(
            "station_ids", NpgsqlDbType.Array | NpgsqlDbType.Uuid)
        {
            TypedValue = scope.StationIds
        });
    }
}
