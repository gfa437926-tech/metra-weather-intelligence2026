using Metra.Api.Data;
using Npgsql;
using NpgsqlTypes;

namespace Metra.Api.Identity;

public interface ICurrentUserService
{
    Task<CurrentUserResponse?> GetAsync(Guid userId, CancellationToken cancellationToken);
}

public sealed class CurrentUserService(MetraDatabase database) : ICurrentUserService
{
    public async Task<CurrentUserResponse?> GetAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        await using var connection = await database.OpenConnectionAsync(cancellationToken);

        const string profileSql = """
            select user_id, email, display_name, given_name, father_name, family_name, profile_state
            from iam.user_profiles
            where user_id = @user_id
            limit 1;
            """;

        Guid profileUserId;
        string? email;
        string? displayName;
        string? givenName;
        string? fatherName;
        string? familyName;
        string profileState;

        await using (var command = new NpgsqlCommand(profileSql, connection))
        {
            command.Parameters.AddWithValue("user_id", userId);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
            {
                return null;
            }

            profileUserId = reader.GetGuid(0);
            email = reader.IsDBNull(1) ? null : reader.GetString(1);
            displayName = reader.IsDBNull(2) ? null : reader.GetString(2);
            givenName = reader.IsDBNull(3) ? null : reader.GetString(3);
            fatherName = reader.IsDBNull(4) ? null : reader.GetString(4);
            familyName = reader.IsDBNull(5) ? null : reader.GetString(5);
            profileState = reader.GetString(6);
        }

        if (!string.Equals(profileState, "active", StringComparison.Ordinal))
        {
            return new CurrentUserResponse(
                profileUserId, email, displayName, givenName, fatherName, familyName,
                profileState, [], []);
        }

        var memberships = new Dictionary<Guid, MembershipBuilder>();
        const string membershipsSql = """
            select m.id, m.organization_id, o.organization_code, o.name_ar,
                   m.unit_id, u.unit_code, u.name_ar
            from iam.memberships m
            join iam.organizations o on o.id = m.organization_id
            left join iam.organization_units u
              on u.id = m.unit_id and u.organization_id = m.organization_id
            where m.user_id = @user_id
              and m.membership_state = 'active'
              and m.valid_from <= now()
              and (m.valid_to is null or m.valid_to > now())
              and o.organization_state = 'active'
            order by o.name_ar, m.id;
            """;

        await using (var command = new NpgsqlCommand(membershipsSql, connection))
        {
            command.Parameters.AddWithValue("user_id", userId);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                var membershipId = reader.GetGuid(0);
                memberships[membershipId] = new MembershipBuilder(
                    membershipId,
                    reader.GetGuid(1),
                    reader.GetString(2),
                    reader.GetString(3),
                    reader.IsDBNull(4) ? null : reader.GetGuid(4),
                    reader.IsDBNull(5) ? null : reader.GetString(5),
                    reader.IsDBNull(6) ? null : reader.GetString(6));
            }
        }

        if (memberships.Count == 0)
        {
            return new CurrentUserResponse(
                profileUserId, email, displayName, givenName, fatherName, familyName,
                profileState, [], []);
        }

        var membershipIds = memberships.Keys.ToArray();
        const string assignmentsSql = """
            select ra.id, ra.membership_id, ra.scope_type,
                   ra.organization_id, ra.unit_id, ra.station_id,
                   r.role_code, r.name_ar, p.permission_code
            from iam.role_assignments ra
            join iam.roles r on r.id = ra.role_id and r.role_state = 'active'
            left join iam.role_permissions rp on rp.role_id = r.id
            left join iam.permissions p on p.id = rp.permission_id
            where ra.membership_id = any(@membership_ids)
              and ra.assignment_state = 'active'
              and ra.valid_from <= now()
              and (ra.valid_to is null or ra.valid_to > now())
            order by ra.id, p.permission_code;
            """;

        var assignments = new Dictionary<Guid, RoleAssignmentBuilder>();
        await using (var command = new NpgsqlCommand(assignmentsSql, connection))
        {
            command.Parameters.Add(new NpgsqlParameter<Guid[]>("membership_ids", NpgsqlDbType.Array | NpgsqlDbType.Uuid)
            {
                TypedValue = membershipIds
            });

            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                var assignmentId = reader.GetGuid(0);
                if (!assignments.TryGetValue(assignmentId, out var assignment))
                {
                    assignment = new RoleAssignmentBuilder(
                        assignmentId,
                        reader.GetGuid(1),
                        reader.GetString(2),
                        reader.IsDBNull(3) ? null : reader.GetGuid(3),
                        reader.IsDBNull(4) ? null : reader.GetGuid(4),
                        reader.IsDBNull(5) ? null : reader.GetGuid(5),
                        reader.GetString(6),
                        reader.GetString(7));
                    assignments.Add(assignmentId, assignment);
                }

                if (!reader.IsDBNull(8))
                {
                    assignment.Permissions.Add(reader.GetString(8));
                }
            }
        }

        foreach (var assignment in assignments.Values)
        {
            if (memberships.TryGetValue(assignment.MembershipId, out var membership))
            {
                membership.Roles.Add(new RoleAssignmentResponse(
                    assignment.Id,
                    assignment.RoleCode,
                    assignment.RoleNameAr,
                    assignment.ScopeType,
                    assignment.OrganizationId,
                    assignment.UnitId,
                    assignment.StationId,
                    assignment.Permissions.Order(StringComparer.Ordinal).ToArray()));
            }
        }

        var permissions = new List<PermissionScopeResponse>();
        foreach (var assignment in assignments.Values)
        {
            foreach (var permission in assignment.Permissions)
            {
                permissions.Add(new PermissionScopeResponse(
                    permission,
                    assignment.ScopeType,
                    assignment.OrganizationId,
                    assignment.UnitId,
                    assignment.StationId,
                    "role"));
            }
        }

        const string grantsSql = """
            select p.permission_code, pg.scope_type,
                   pg.organization_id, pg.unit_id, pg.station_id
            from iam.permission_grants pg
            join iam.permissions p on p.id = pg.permission_id
            where pg.user_id = @user_id
              and pg.grant_state = 'active'
              and pg.valid_from <= now()
              and (pg.valid_to is null or pg.valid_to > now())
            order by p.permission_code;
            """;

        await using (var command = new NpgsqlCommand(grantsSql, connection))
        {
            command.Parameters.AddWithValue("user_id", userId);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                permissions.Add(new PermissionScopeResponse(
                    reader.GetString(0),
                    reader.GetString(1),
                    reader.IsDBNull(2) ? null : reader.GetGuid(2),
                    reader.IsDBNull(3) ? null : reader.GetGuid(3),
                    reader.IsDBNull(4) ? null : reader.GetGuid(4),
                    "direct_grant"));
            }
        }

        return new CurrentUserResponse(
            profileUserId,
            email,
            displayName,
            givenName,
            fatherName,
            familyName,
            profileState,
            memberships.Values.Select(m => m.Build()).ToArray(),
            permissions
                .DistinctBy(p => (p.PermissionCode, p.ScopeType, p.OrganizationId, p.UnitId, p.StationId, p.Source))
                .OrderBy(p => p.PermissionCode, StringComparer.Ordinal)
                .ToArray());
    }

    private sealed class MembershipBuilder(
        Guid id,
        Guid organizationId,
        string organizationCode,
        string organizationNameAr,
        Guid? unitId,
        string? unitCode,
        string? unitNameAr)
    {
        public List<RoleAssignmentResponse> Roles { get; } = [];

        public MembershipResponse Build() => new(
            id, organizationId, organizationCode, organizationNameAr,
            unitId, unitCode, unitNameAr, Roles.OrderBy(r => r.RoleCode, StringComparer.Ordinal).ToArray());
    }

    private sealed class RoleAssignmentBuilder(
        Guid id,
        Guid membershipId,
        string scopeType,
        Guid? organizationId,
        Guid? unitId,
        Guid? stationId,
        string roleCode,
        string roleNameAr)
    {
        public Guid Id { get; } = id;
        public Guid MembershipId { get; } = membershipId;
        public string ScopeType { get; } = scopeType;
        public Guid? OrganizationId { get; } = organizationId;
        public Guid? UnitId { get; } = unitId;
        public Guid? StationId { get; } = stationId;
        public string RoleCode { get; } = roleCode;
        public string RoleNameAr { get; } = roleNameAr;
        public HashSet<string> Permissions { get; } = new(StringComparer.Ordinal);
    }
}
