using System.Text.Json;
using Metra.Api.Data;
using Metra.Api.Identity;
using Npgsql;
using NpgsqlTypes;

namespace Metra.Api.Stations;

public interface IStationReviewService
{
    Task<StationReviewQueueResponse> GetQueueAsync(Guid userId, CancellationToken cancellationToken);
    Task<StationReviewDecisionResponse> DecideAsync(
        Guid userId,
        Guid stationId,
        StationReviewDecisionRequest request,
        CancellationToken cancellationToken);
}

public sealed class StationReviewService(
    MetraDatabase database,
    ICurrentUserService currentUserService) : IStationReviewService
{
    public async Task<StationReviewQueueResponse> GetQueueAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var user = await currentUserService.GetAsync(userId, cancellationToken);
        if (user is null || user.ProfileState != "active")
            throw new StationReviewAccessDeniedException();

        var scopes = ResolveScopes(user.Permissions, "stations.review");
        if (!scopes.IsGlobal && scopes.OrganizationIds.Length == 0 && scopes.StationIds.Length == 0)
            throw new StationReviewAccessDeniedException();

        await using var connection = await database.OpenConnectionAsync(cancellationToken);
        const string sql = """
            select s.id, s.station_code, s.name_ar, s.name_en, st.type_code,
                   s.operational_status, s.approval_status, s.owner_organization_id,
                   location.latitude, location.longitude,
                   location.location_source, location.source_reference
            from catalog.stations s
            join catalog.station_types st on st.id = s.station_type_id
            left join lateral (
                select sl.latitude, sl.longitude, sl.location_source, sl.source_reference
                from catalog.station_locations sl
                where sl.station_id = s.id
                  and sl.valid_from <= now()
                  and (sl.valid_to is null or sl.valid_to > now())
                order by sl.valid_from desc, sl.id desc
                limit 1
            ) location on true
            where s.approval_status in ('pending', 'changes_requested')
              and (
                @is_global
                or s.owner_organization_id = any(@organization_ids)
                or s.id = any(@station_ids)
              )
            order by s.created_at, s.id
            limit 500;
            """;

        await using var command = new NpgsqlCommand(sql, connection);
        command.Parameters.AddWithValue("is_global", scopes.IsGlobal);
        command.Parameters.AddWithValue("organization_ids", scopes.OrganizationIds);
        command.Parameters.AddWithValue("station_ids", scopes.StationIds);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var stations = new List<StationReviewItem>();
        while (await reader.ReadAsync(cancellationToken))
        {
            StationCoordinate? coordinate = null;
            if (!reader.IsDBNull(8) && !reader.IsDBNull(9) && !reader.IsDBNull(10))
            {
                coordinate = new StationCoordinate(
                    reader.GetDecimal(8),
                    reader.GetDecimal(9),
                    reader.GetString(10),
                    reader.IsDBNull(11) ? null : reader.GetString(11));
            }

            stations.Add(new StationReviewItem(
                reader.GetGuid(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetString(3),
                reader.GetString(4),
                reader.GetString(5),
                reader.GetString(6),
                reader.GetGuid(7),
                coordinate));
        }

        return new StationReviewQueueResponse(stations);
    }

    public async Task<StationReviewDecisionResponse> DecideAsync(
        Guid userId,
        Guid stationId,
        StationReviewDecisionRequest request,
        CancellationToken cancellationToken)
    {
        Validate(request);
        var user = await currentUserService.GetAsync(userId, cancellationToken);
        if (user is null || user.ProfileState != "active")
            throw new StationReviewAccessDeniedException();

        await using var connection = await database.OpenConnectionAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

        const string lockSql = """
            select owner_organization_id, approval_status, created_by
            from catalog.stations
            where id = @station_id
            for update;
            """;
        Guid organizationId;
        string previousStatus;
        Guid? createdBy;
        await using (var command = new NpgsqlCommand(lockSql, connection, transaction))
        {
            command.Parameters.AddWithValue("station_id", stationId);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
                throw new StationReviewConflictException("المحطة غير موجودة أو لم تعد متاحة.");

            organizationId = reader.GetGuid(0);
            previousStatus = reader.GetString(1);
            createdBy = reader.IsDBNull(2) ? null : reader.GetGuid(2);
        }

        if (createdBy == userId)
            throw new StationReviewAccessDeniedException();

        var scopes = ResolveScopes(user.Permissions, "stations.review");
        if (!PermissionScopeEvaluator.Allows(
            user.Permissions, "stations.review", organizationId, null, stationId))
        {
            throw new StationReviewAccessDeniedException();
        }

        if (previousStatus is not ("pending" or "changes_requested"))
            throw new StationReviewConflictException("تغيرت حالة المحطة؛ حدّث قائمة المراجعة قبل اتخاذ القرار.");

        const string updateSql = """
            update catalog.stations
            set approval_status = @decision,
                updated_by = @reviewer_id,
                updated_at = now()
            where id = @station_id
              and approval_status = @expected_status;
            """;
        await using (var command = new NpgsqlCommand(updateSql, connection, transaction))
        {
            command.Parameters.AddWithValue("decision", request.Decision.Trim());
            command.Parameters.AddWithValue("reviewer_id", userId);
            command.Parameters.AddWithValue("station_id", stationId);
            command.Parameters.AddWithValue("expected_status", previousStatus);
            if (await command.ExecuteNonQueryAsync(cancellationToken) != 1)
                throw new StationReviewConflictException("تغيرت حالة المحطة أثناء المراجعة.");
        }

        const string reviewSql = """
            insert into catalog.station_reviews (
                station_id, reviewer_user_id, decision, reason,
                previous_status, resulting_status, decided_at
            )
            values (
                @station_id, @reviewer_id, @decision, @reason,
                @previous_status, @resulting_status, now()
            );
            """;
        await using (var command = new NpgsqlCommand(reviewSql, connection, transaction))
        {
            command.Parameters.AddWithValue("station_id", stationId);
            command.Parameters.AddWithValue("reviewer_id", userId);
            command.Parameters.AddWithValue("decision", request.Decision.Trim());
            command.Parameters.AddWithValue("reason", request.Reason.Trim());
            command.Parameters.AddWithValue("previous_status", previousStatus);
            command.Parameters.AddWithValue("resulting_status", request.Decision.Trim());
            await command.ExecuteNonQueryAsync(cancellationToken);
        }

        var metadata = JsonSerializer.Serialize(new
        {
            previous_status = previousStatus,
            resulting_status = request.Decision.Trim()
        });
        const string auditSql = """
            insert into audit.events (
                occurred_at, actor_user_id, action_code, entity_schema, entity_table,
                entity_id, organization_id, station_id, outcome, correlation_id, metadata
            )
            values (
                now(), @actor_user_id, 'station.review_decided', 'catalog', 'stations',
                @entity_id, @organization_id, @station_id, 'success', @correlation_id, @metadata
            );
            """;
        await using (var command = new NpgsqlCommand(auditSql, connection, transaction))
        {
            command.Parameters.AddWithValue("actor_user_id", userId);
            command.Parameters.AddWithValue("entity_id", stationId);
            command.Parameters.AddWithValue("organization_id", organizationId);
            command.Parameters.AddWithValue("station_id", stationId);
            command.Parameters.AddWithValue("correlation_id", Guid.NewGuid());
            command.Parameters.Add(new NpgsqlParameter("metadata", NpgsqlDbType.Jsonb) { Value = metadata });
            await command.ExecuteNonQueryAsync(cancellationToken);
        }

        await transaction.CommitAsync(cancellationToken);
        return new StationReviewDecisionResponse("updated", stationId, request.Decision.Trim());
    }

    private static (bool IsGlobal, Guid[] OrganizationIds, Guid[] StationIds) ResolveScopes(
        IEnumerable<PermissionScopeResponse> permissions,
        string permissionCode)
    {
        var scopes = permissions.Where(p =>
            string.Equals(p.PermissionCode, permissionCode, StringComparison.Ordinal)).ToArray();
        var global = scopes.Any(p => p.ScopeType == "global" &&
            p.OrganizationId is null && p.UnitId is null && p.StationId is null);
        var organizations = scopes
            .Where(p => p.ScopeType == "organization" && p.OrganizationId is not null
                && p.UnitId is null && p.StationId is null)
            .Select(p => p.OrganizationId!.Value).Distinct().ToArray();
        var stations = scopes
            .Where(p => p.ScopeType == "station" && p.StationId is not null
                && p.OrganizationId is not null && p.UnitId is null)
            .Select(p => p.StationId!.Value).Distinct().ToArray();
        return (global, organizations, stations);
    }

    private static void Validate(StationReviewDecisionRequest request)
    {
        if (request.Decision is not ("approved" or "rejected" or "changes_requested" or "suspended"))
            throw new StationReviewValidationException("قرار مراجعة المحطة غير مدعوم.");
        if (string.IsNullOrWhiteSpace(request.Reason) || request.Reason.Trim().Length < 5 ||
            request.Reason.Trim().Length > 2000)
            throw new StationReviewValidationException("سبب القرار يجب أن يكون بين 5 و2000 محرف.");
    }
}
