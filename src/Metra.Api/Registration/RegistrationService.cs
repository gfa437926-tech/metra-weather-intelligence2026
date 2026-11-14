using System.Text.Json;
using Metra.Api.Data;
using Metra.Api.Identity;
using Npgsql;
using NpgsqlTypes;

namespace Metra.Api.Registration;

public interface IRegistrationService
{
    Task<RegistrationCatalogResponse> GetCatalogAsync(CancellationToken cancellationToken);
    Task<RegistrationStatusResponse> GetStatusAsync(Guid userId, CancellationToken cancellationToken);
    Task<RegistrationSubmissionResponse> SubmitAsync(
        Guid userId,
        RegistrationSubmissionRequest request,
        CancellationToken cancellationToken);
    Task<RegistrationApprovalQueueResponse> GetApprovalQueueAsync(
        Guid userId, int page, int pageSize, CancellationToken cancellationToken);
    Task<RegistrationApprovalDecisionResponse> DecideAsync(
        Guid userId, Guid requestId, RegistrationApprovalDecisionRequest request,
        CancellationToken cancellationToken);
}

public sealed class RegistrationService(
    MetraDatabase database,
    ICurrentUserService currentUserService) : IRegistrationService
{
    private const string CurrentTermsVersion = "metra-terms-2026-11";

    public async Task<RegistrationApprovalQueueResponse> GetApprovalQueueAsync(
        Guid userId,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        var user = await currentUserService.GetAsync(userId, cancellationToken);
        if (user is null || user.ProfileState != "active")
            throw new RegistrationApprovalAccessDeniedException();

        var scopes = ResolveApprovalScopes(user.Permissions);
        if (!scopes.StationGlobal && scopes.StationIds.Length == 0 &&
            !scopes.OrganizationGlobal && scopes.OrganizationIds.Length == 0)
            throw new RegistrationApprovalAccessDeniedException();

        await using var connection = await database.OpenConnectionAsync(cancellationToken);
        const string filter = """
            from iam.registration_requests rr
            where (
                rr.request_state = 'pending_station_review'
                and (@station_global or rr.requested_station_id = any(@station_ids))
            ) or (
                rr.request_state = 'pending_system_review'
                and (@organization_global or rr.organization_id = any(@organization_ids))
            )
            """;
        long total;
        await using (var countCommand = new NpgsqlCommand($"select count(*) {filter}", connection))
        {
            countCommand.Parameters.AddWithValue("station_global", scopes.StationGlobal);
            countCommand.Parameters.AddWithValue("station_ids", scopes.StationIds);
            countCommand.Parameters.AddWithValue("organization_global", scopes.OrganizationGlobal);
            countCommand.Parameters.AddWithValue("organization_ids", scopes.OrganizationIds);
            total = Convert.ToInt64(await countCommand.ExecuteScalarAsync(cancellationToken));
        }

        const string sql = """
            select rr.id, rr.request_state,
                   p.given_name, p.father_name, p.family_name,
                   s.name_ar, s.station_code, r.name_ar, r.role_code, rr.submitted_at
            from iam.registration_requests rr
            join iam.user_profiles p on p.user_id = rr.applicant_user_id
            join catalog.stations s on s.id = rr.requested_station_id
            join iam.roles r on r.id = rr.requested_role_id
            where (
                rr.request_state = 'pending_station_review'
                and (@station_global or rr.requested_station_id = any(@station_ids))
            ) or (
                rr.request_state = 'pending_system_review'
                and (@organization_global or rr.organization_id = any(@organization_ids))
            )
            order by rr.submitted_at, rr.id
            limit @page_size offset @offset;
            """;

        await using var command = new NpgsqlCommand(sql, connection);
        command.Parameters.AddWithValue("station_global", scopes.StationGlobal);
        command.Parameters.AddWithValue("station_ids", scopes.StationIds);
        command.Parameters.AddWithValue("organization_global", scopes.OrganizationGlobal);
        command.Parameters.AddWithValue("organization_ids", scopes.OrganizationIds);
        command.Parameters.AddWithValue("page_size", pageSize);
        command.Parameters.AddWithValue("offset", checked((page - 1) * pageSize));
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var items = new List<RegistrationApprovalItem>();
        while (await reader.ReadAsync(cancellationToken))
        {
            var requestState = reader.GetString(1);
            items.Add(new RegistrationApprovalItem(
                reader.GetGuid(0),
                requestState == "pending_station_review"
                    ? "pending_station_approval"
                    : "pending_system_approval",
                requestState == "pending_station_review" ? "station" : "organization",
                new RegistrationApprovalApplicant(
                    reader.IsDBNull(2) ? null : reader.GetString(2),
                    reader.IsDBNull(3) ? null : reader.GetString(3),
                    reader.IsDBNull(4) ? null : reader.GetString(4)),
                new RegistrationApprovalStation(reader.GetString(5), reader.GetString(6)),
                new RegistrationApprovalRole(reader.GetString(7)),
                reader.GetString(8),
                reader.GetFieldValue<DateTimeOffset>(9)));
        }

        return new RegistrationApprovalQueueResponse(items, total, page, pageSize);
    }

    public async Task<RegistrationApprovalDecisionResponse> DecideAsync(
        Guid userId,
        Guid requestId,
        RegistrationApprovalDecisionRequest request,
        CancellationToken cancellationToken)
    {
        ValidateApprovalDecision(request);
        var user = await currentUserService.GetAsync(userId, cancellationToken);
        if (user is null || user.ProfileState != "active")
            throw new RegistrationApprovalAccessDeniedException();

        await using var connection = await database.OpenConnectionAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

        const string lockSql = """
            select rr.applicant_user_id, rr.organization_id, rr.requested_station_id,
                   rr.requested_unit_id, rr.requested_role_id, rr.request_state,
                   r.role_code, r.role_state, r.is_assignable
            from iam.registration_requests rr
            join iam.roles r on r.id = rr.requested_role_id
            where rr.id = @request_id
            for update of rr;
            """;

        Guid applicantUserId;
        Guid organizationId;
        Guid stationId;
        Guid? unitId;
        Guid roleId;
        string requestState;
        string roleCode;
        string roleState;
        bool roleAssignable;
        await using (var command = new NpgsqlCommand(lockSql, connection, transaction))
        {
            command.Parameters.AddWithValue("request_id", requestId);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
                throw new RegistrationApprovalConflictException("طلب الانتساب غير موجود أو لم يعد متاحاً.");

            applicantUserId = reader.GetGuid(0);
            organizationId = reader.GetGuid(1);
            stationId = reader.GetGuid(2);
            unitId = reader.IsDBNull(3) ? null : reader.GetGuid(3);
            roleId = reader.GetGuid(4);
            requestState = reader.GetString(5);
            roleCode = reader.GetString(6);
            roleState = reader.GetString(7);
            roleAssignable = reader.GetBoolean(8);
        }

        if (applicantUserId == userId)
            throw new RegistrationApprovalAccessDeniedException();

        var stage = requestState switch
        {
            "pending_station_review" => "station",
            "pending_system_review" => "organization",
            _ => throw new RegistrationApprovalConflictException(
                "تغيرت حالة الطلب أو تمت معالجته مسبقاً.")
        };

        var expectedStatus = stage == "station"
            ? "pending_station_approval"
            : "pending_system_approval";
        if (!string.Equals(request.ExpectedStatus, expectedStatus, StringComparison.Ordinal))
            throw new RegistrationApprovalConflictException("تغيرت حالة الطلب؛ حدّث القائمة قبل اتخاذ القرار.");

        var permissionCode = stage == "station"
            ? "registrations.review_station"
            : "registrations.review_organization";
        if (!PermissionScopeEvaluator.Allows(
            user.Permissions, permissionCode, organizationId, unitId, stationId))
            throw new RegistrationApprovalAccessDeniedException();

        if (request.Decision == "approve" && (roleState != "active" || !roleAssignable))
            throw new RegistrationApprovalConflictException("الدور المطلوب لم يعد قابلاً للتعيين.");

        var decision = request.Decision == "approve" ? "approved" : "rejected";
        var reason = string.IsNullOrWhiteSpace(request.Note)
            ? decision == "approved" ? "تمت المراجعة والموافقة" : "تم رفض الطلب"
            : request.Note.Trim();

        const string sequenceSql = """
            select coalesce(max(decision_sequence), 0) + 1
            from iam.registration_decisions
            where request_id = @request_id and stage = @stage;
            """;
        int sequence;
        await using (var command = new NpgsqlCommand(sequenceSql, connection, transaction))
        {
            command.Parameters.AddWithValue("request_id", requestId);
            command.Parameters.AddWithValue("stage", stage);
            sequence = Convert.ToInt32(await command.ExecuteScalarAsync(cancellationToken));
        }

        const string decisionSql = """
            insert into iam.registration_decisions (
                request_id, stage, decision_sequence, reviewer_user_id, decision, reason, decided_at
            )
            values (@request_id, @stage, @sequence, @reviewer_id, @decision, @reason, now());
            """;
        await using (var command = new NpgsqlCommand(decisionSql, connection, transaction))
        {
            command.Parameters.AddWithValue("request_id", requestId);
            command.Parameters.AddWithValue("stage", stage);
            command.Parameters.AddWithValue("sequence", sequence);
            command.Parameters.AddWithValue("reviewer_id", userId);
            command.Parameters.AddWithValue("decision", decision);
            command.Parameters.AddWithValue("reason", reason);
            await command.ExecuteNonQueryAsync(cancellationToken);
        }

        string resultingStatus;
        if (decision == "rejected")
        {
            const string rejectSql = """
                update iam.registration_requests
                set request_state = 'rejected', resolved_at = now()
                where id = @request_id and request_state = @expected_state;
                """;
            await using var command = new NpgsqlCommand(rejectSql, connection, transaction);
            command.Parameters.AddWithValue("request_id", requestId);
            command.Parameters.AddWithValue("expected_state", requestState);
            if (await command.ExecuteNonQueryAsync(cancellationToken) != 1)
                throw new RegistrationApprovalConflictException("تغيرت حالة الطلب أثناء المراجعة.");
            resultingStatus = "rejected";
        }
        else if (stage == "station")
        {
            const string advanceSql = """
                update iam.registration_requests
                set request_state = 'pending_system_review'
                where id = @request_id and request_state = 'pending_station_review';
                """;
            await using var command = new NpgsqlCommand(advanceSql, connection, transaction);
            command.Parameters.AddWithValue("request_id", requestId);
            if (await command.ExecuteNonQueryAsync(cancellationToken) != 1)
                throw new RegistrationApprovalConflictException("تغيرت حالة الطلب أثناء المراجعة.");
            resultingStatus = "pending_system_approval";
        }
        else
        {
            const string existingMembershipSql = """
                select id
                from iam.memberships
                where user_id = @user_id
                  and organization_id = @organization_id
                  and unit_id is not distinct from @unit_id
                  and membership_state = 'active'
                  and valid_from <= now()
                  and (valid_to is null or valid_to > now())
                order by created_at
                limit 1
                for update;
                """;
            Guid membershipId;
            await using (var command = new NpgsqlCommand(existingMembershipSql, connection, transaction))
            {
                command.Parameters.AddWithValue("user_id", applicantUserId);
                command.Parameters.AddWithValue("organization_id", organizationId);
                command.Parameters.AddWithValue("unit_id", (object?)unitId ?? DBNull.Value);
                var existing = await command.ExecuteScalarAsync(cancellationToken);
                if (existing is Guid existingId)
                {
                    membershipId = existingId;
                }
                else
                {
                    const string membershipInsertSql = """
                        insert into iam.memberships (
                            user_id, organization_id, unit_id, membership_state,
                            valid_from, requested_at, approved_at, approved_by
                        )
                        values (
                            @user_id, @organization_id, @unit_id, 'active',
                            now(), now(), now(), @approved_by
                        )
                        returning id;
                        """;
                    await using var membershipCommand = new NpgsqlCommand(
                        membershipInsertSql, connection, transaction);
                    membershipCommand.Parameters.AddWithValue("user_id", applicantUserId);
                    membershipCommand.Parameters.AddWithValue("organization_id", organizationId);
                    membershipCommand.Parameters.AddWithValue("unit_id", (object?)unitId ?? DBNull.Value);
                    membershipCommand.Parameters.AddWithValue("approved_by", userId);
                    membershipId = (Guid)(await membershipCommand.ExecuteScalarAsync(cancellationToken)
                        ?? throw new RegistrationApprovalConflictException("تعذر إنشاء العضوية."));
                }
            }

            var scopeType = unitId is not null
                ? "unit"
                : roleCode is "observer" or "station_manager" or "data_reviewer" or "maintenance_technician"
                    ? "station"
                    : "organization";
            var assignmentUnitId = scopeType == "unit" ? unitId : null;
            var assignmentStationId = scopeType == "station" ? stationId : null;

            const string assignmentSql = """
                insert into iam.role_assignments (
                    membership_id, organization_id, unit_id, station_id,
                    role_id, scope_type, assignment_state, valid_from, assigned_by
                )
                select @membership_id, @organization_id, @unit_id, @station_id,
                       @role_id, @scope_type, 'active', now(), @assigned_by
                where not exists (
                    select 1 from iam.role_assignments ra
                    where ra.membership_id = @membership_id
                      and ra.role_id = @role_id
                      and ra.scope_type = @scope_type
                      and ra.organization_id is not distinct from @organization_id
                      and ra.unit_id is not distinct from @unit_id
                      and ra.station_id is not distinct from @station_id
                      and ra.assignment_state = 'active'
                      and ra.valid_from <= now()
                      and (ra.valid_to is null or ra.valid_to > now())
                );
                """;
            await using (var command = new NpgsqlCommand(assignmentSql, connection, transaction))
            {
                command.Parameters.AddWithValue("membership_id", membershipId);
                command.Parameters.AddWithValue("organization_id", organizationId);
                command.Parameters.AddWithValue("unit_id", (object?)assignmentUnitId ?? DBNull.Value);
                command.Parameters.AddWithValue("station_id", (object?)assignmentStationId ?? DBNull.Value);
                command.Parameters.AddWithValue("role_id", roleId);
                command.Parameters.AddWithValue("scope_type", scopeType);
                command.Parameters.AddWithValue("assigned_by", userId);
                await command.ExecuteNonQueryAsync(cancellationToken);
            }

            const string approveSql = """
                update iam.registration_requests
                set request_state = 'approved', resolved_at = now()
                where id = @request_id and request_state = 'pending_system_review';
                """;
            await using (var command = new NpgsqlCommand(approveSql, connection, transaction))
            {
                command.Parameters.AddWithValue("request_id", requestId);
                if (await command.ExecuteNonQueryAsync(cancellationToken) != 1)
                    throw new RegistrationApprovalConflictException("تغيرت حالة الطلب أثناء المراجعة.");
            }
            resultingStatus = "active";
        }

        var metadata = JsonSerializer.Serialize(new
        {
            stage,
            decision,
            resulting_status = resultingStatus
        });
        const string auditSql = """
            insert into audit.events (
                occurred_at, actor_user_id, action_code, entity_schema, entity_table,
                entity_id, organization_id, station_id, outcome, correlation_id, metadata
            )
            values (
                now(), @actor_user_id, 'registration.review_decided', 'iam', 'registration_requests',
                @entity_id, @organization_id, @station_id, 'success', @correlation_id, @metadata
            );
            """;
        await using (var command = new NpgsqlCommand(auditSql, connection, transaction))
        {
            command.Parameters.AddWithValue("actor_user_id", userId);
            command.Parameters.AddWithValue("entity_id", requestId);
            command.Parameters.AddWithValue("organization_id", organizationId);
            command.Parameters.AddWithValue("station_id", stationId);
            command.Parameters.AddWithValue("correlation_id", Guid.NewGuid());
            command.Parameters.Add(new NpgsqlParameter("metadata", NpgsqlDbType.Jsonb) { Value = metadata });
            await command.ExecuteNonQueryAsync(cancellationToken);
        }

        await transaction.CommitAsync(cancellationToken);
        return new RegistrationApprovalDecisionResponse("committed", resultingStatus);
    }

    private static (
        bool StationGlobal,
        Guid[] StationIds,
        bool OrganizationGlobal,
        Guid[] OrganizationIds) ResolveApprovalScopes(IEnumerable<PermissionScopeResponse> permissions)
    {
        var station = permissions.Where(p => p.PermissionCode == "registrations.review_station").ToArray();
        var organization = permissions.Where(p => p.PermissionCode == "registrations.review_organization").ToArray();
        var stationGlobal = station.Any(p => p.ScopeType == "global" &&
            p.OrganizationId is null && p.UnitId is null && p.StationId is null);
        var stationIds = station.Where(p => p.ScopeType == "station" &&
                p.OrganizationId is not null && p.UnitId is null && p.StationId is not null)
            .Select(p => p.StationId!.Value).Distinct().ToArray();
        var organizationGlobal = organization.Any(p => p.ScopeType == "global" &&
            p.OrganizationId is null && p.UnitId is null && p.StationId is null);
        var organizationIds = organization.Where(p => p.ScopeType == "organization" &&
                p.OrganizationId is not null && p.UnitId is null && p.StationId is null)
            .Select(p => p.OrganizationId!.Value).Distinct().ToArray();
        return (stationGlobal, stationIds, organizationGlobal, organizationIds);
    }

    private static void ValidateApprovalDecision(RegistrationApprovalDecisionRequest request)
    {
        if (request.ExpectedStatus is not ("pending_station_approval" or "pending_system_approval") ||
            request.Decision is not ("approve" or "reject"))
            throw new RegistrationApprovalValidationException("مرحلة الاعتماد أو القرار غير صالحين.");
        if (request.Decision == "reject" &&
            (string.IsNullOrWhiteSpace(request.Note) || request.Note.Trim().Length < 3))
            throw new RegistrationApprovalValidationException("سبب الرفض مطلوب ويجب ألا يقل عن 3 محارف.");
        if (request.Note is { Length: > 2000 })
            throw new RegistrationApprovalValidationException("ملاحظة المراجعة تتجاوز الحد المسموح.");
    }

    public async Task<RegistrationCatalogResponse> GetCatalogAsync(
        CancellationToken cancellationToken)
    {
        await using var connection = await database.OpenConnectionAsync(cancellationToken);
        var roles = new List<RegistrationRole>();
        const string rolesSql = """
            select role_code, name_ar, name_en
            from iam.roles
            where role_state = 'active' and is_requestable = true
            order by name_ar, role_code;
            """;
        await using (var command = new NpgsqlCommand(rolesSql, connection))
        await using (var reader = await command.ExecuteReaderAsync(cancellationToken))
        {
            while (await reader.ReadAsync(cancellationToken))
            {
                roles.Add(new RegistrationRole(
                    reader.GetString(0), reader.GetString(1), reader.GetString(2)));
            }
        }

        var stations = new List<RegistrationStation>();
        const string stationsSql = """
            select s.id, s.station_code, s.name_ar, s.name_en, st.type_code,
                   s.operational_status, s.approval_status, s.owner_organization_id, o.name_ar
            from catalog.stations s
            join catalog.station_types st on st.id = s.station_type_id and st.is_active = true
            join iam.organizations o on o.id = s.owner_organization_id and o.organization_state = 'active'
            where s.approval_status = 'approved'
              and s.operational_status = 'active'
            order by s.name_ar, s.id;
            """;
        await using (var command = new NpgsqlCommand(stationsSql, connection))
        await using (var reader = await command.ExecuteReaderAsync(cancellationToken))
        {
            while (await reader.ReadAsync(cancellationToken))
            {
                stations.Add(new RegistrationStation(
                    reader.GetGuid(0),
                    reader.GetString(1),
                    reader.GetString(2),
                    reader.GetString(3),
                    reader.GetString(4),
                    reader.GetString(5),
                    reader.GetString(6),
                    reader.GetGuid(7),
                    reader.GetString(8)));
            }
        }

        return new RegistrationCatalogResponse(roles, stations);
    }

    public async Task<RegistrationStatusResponse> GetStatusAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        await using var connection = await database.OpenConnectionAsync(cancellationToken);
        const string sql = """
            select p.profile_state,
              (
                select rr.request_state
                from iam.registration_requests rr
                where rr.applicant_user_id = p.user_id
                order by rr.submitted_at desc, rr.id desc
                limit 1
              ) as request_state,
              exists (
                select 1
                from iam.memberships m
                join iam.organizations o on o.id = m.organization_id
                where m.user_id = p.user_id
                  and m.membership_state = 'active'
                  and m.valid_from <= now()
                  and (m.valid_to is null or m.valid_to > now())
                  and o.organization_state = 'active'
              ) as has_active_membership
            from iam.user_profiles p
            where p.user_id = @user_id
            limit 1;
            """;

        await using var command = new NpgsqlCommand(sql, connection);
        command.Parameters.AddWithValue("user_id", userId);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return new RegistrationStatusResponse("needs_registration", null, null);
        }

        var profileState = reader.GetString(0);
        var requestState = reader.IsDBNull(1) ? null : reader.GetString(1);
        var hasMembership = reader.GetBoolean(2);

        var accountState = profileState != "active"
            ? "blocked"
            : hasMembership
                ? "active"
                : requestState switch
                {
                    "submitted" or "pending_station_review" => "pending_station_approval",
                    "pending_system_review" => "pending_system_approval",
                    "rejected" => "rejected",
                    "withdrawn" => "needs_registration",
                    _ => "needs_registration"
                };

        return new RegistrationStatusResponse(accountState, null, requestState);
    }

    public async Task<RegistrationSubmissionResponse> SubmitAsync(
        Guid userId,
        RegistrationSubmissionRequest request,
        CancellationToken cancellationToken)
    {
        Validate(request);
        await using var connection = await database.OpenConnectionAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

        const string profileSql = """
            select profile_state
            from iam.user_profiles
            where user_id = @user_id
            for update;
            """;
        await using (var command = new NpgsqlCommand(profileSql, connection, transaction))
        {
            command.Parameters.AddWithValue("user_id", userId);
            var profileState = await command.ExecuteScalarAsync(cancellationToken) as string;
            if (profileState is null || profileState != "active")
            {
                throw new RegistrationValidationException("الحساب غير نشط أو لم يكتمل إنشاؤه.");
            }
        }

        const string existingSql = """
            select id, request_state, requested_station_id, requested_role_id
            from iam.registration_requests
            where applicant_user_id = @user_id and idempotency_key = @idempotency_key
            limit 1;
            """;
        Guid? existingId = null;
        string? existingState = null;
        Guid? existingStationId = null;
        Guid? existingRoleId = null;
        await using (var command = new NpgsqlCommand(existingSql, connection, transaction))
        {
            command.Parameters.AddWithValue("user_id", userId);
            command.Parameters.AddWithValue("idempotency_key", request.IdempotencyKey.Trim());
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (await reader.ReadAsync(cancellationToken))
            {
                existingId = reader.GetGuid(0);
                existingState = reader.GetString(1);
                existingStationId = reader.GetGuid(2);
                existingRoleId = reader.GetGuid(3);
            }
        }

        if (existingId is not null)
        {
            var expected = await ResolveSelectionAsync(connection, transaction, request, cancellationToken);
            if (existingStationId != request.StationId || existingRoleId != expected.RoleId)
            {
                throw new RegistrationConflictException("مفتاح منع التكرار مستخدم لطلب مختلف.");
            }

            await transaction.CommitAsync(cancellationToken);
            return new RegistrationSubmissionResponse("already_created", existingId.Value, existingState!);
        }

        var selection = await ResolveSelectionAsync(connection, transaction, request, cancellationToken);

        var fullDisplayName = string.Join(' ', new[]
        {
            request.GivenName.Trim(),
            request.FatherName.Trim(),
            request.FamilyName.Trim()
        });

        const string updateProfileSql = """
            update iam.user_profiles
            set given_name = @given_name,
                father_name = @father_name,
                family_name = @family_name,
                display_name = @display_name,
                phone_e164 = @phone_e164,
                updated_at = now()
            where user_id = @user_id;
            """;
        await using (var command = new NpgsqlCommand(updateProfileSql, connection, transaction))
        {
            command.Parameters.AddWithValue("given_name", request.GivenName.Trim());
            command.Parameters.AddWithValue("father_name", request.FatherName.Trim());
            command.Parameters.AddWithValue("family_name", request.FamilyName.Trim());
            command.Parameters.AddWithValue("display_name", fullDisplayName);
            command.Parameters.AddWithValue("phone_e164", (object?)NormalizePhone(request.Phone) ?? DBNull.Value);
            command.Parameters.AddWithValue("user_id", userId);
            await command.ExecuteNonQueryAsync(cancellationToken);
        }

        const string insertSql = """
            insert into iam.registration_requests (
                applicant_user_id, organization_id, requested_station_id,
                requested_role_id, request_state, terms_version,
                idempotency_key, submitted_at
            )
            values (
                @user_id, @organization_id, @station_id,
                @role_id, 'pending_station_review', @terms_version,
                @idempotency_key, now()
            )
            on conflict (applicant_user_id, idempotency_key) do nothing
            returning id, request_state;
            """;

        Guid requestId;
        string requestState;
        await using (var command = new NpgsqlCommand(insertSql, connection, transaction))
        {
            command.Parameters.AddWithValue("user_id", userId);
            command.Parameters.AddWithValue("organization_id", selection.OrganizationId);
            command.Parameters.AddWithValue("station_id", request.StationId);
            command.Parameters.AddWithValue("role_id", selection.RoleId);
            command.Parameters.AddWithValue("terms_version", CurrentTermsVersion);
            command.Parameters.AddWithValue("idempotency_key", request.IdempotencyKey.Trim());
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
            {
                throw new RegistrationConflictException("تعذر تأكيد إنشاء طلب الانتساب. أعد تحميل الحالة قبل المحاولة.");
            }

            requestId = reader.GetGuid(0);
            requestState = reader.GetString(1);
        }

        await transaction.CommitAsync(cancellationToken);
        return new RegistrationSubmissionResponse("created", requestId, requestState);
    }

    private static async Task<(Guid OrganizationId, Guid RoleId)> ResolveSelectionAsync(
        NpgsqlConnection connection,
        NpgsqlTransaction transaction,
        RegistrationSubmissionRequest request,
        CancellationToken cancellationToken)
    {
        const string sql = """
            select s.owner_organization_id, r.id
            from catalog.stations s
            join iam.organizations o on o.id = s.owner_organization_id
            join iam.roles r on r.role_code = @role_code
            where s.id = @station_id
              and s.approval_status = 'approved'
              and s.operational_status = 'active'
              and o.organization_state = 'active'
              and r.role_state = 'active'
              and r.is_requestable = true
            for share of s, o, r;
            """;

        await using var command = new NpgsqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("station_id", request.StationId);
        command.Parameters.AddWithValue("role_code", request.RoleCode.Trim());
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            throw new RegistrationValidationException("المحطة أو الدور غير متاحين لطلب الانتساب.");
        }

        return (reader.GetGuid(0), reader.GetGuid(1));
    }

    private static void Validate(RegistrationSubmissionRequest request)
    {
        if (request.StationId == Guid.Empty ||
            string.IsNullOrWhiteSpace(request.RoleCode) ||
            request.RoleCode.Length > 80 ||
            string.IsNullOrWhiteSpace(request.GivenName) ||
            request.GivenName.Trim().Length > 120 ||
            string.IsNullOrWhiteSpace(request.FatherName) ||
            request.FatherName.Trim().Length > 120 ||
            string.IsNullOrWhiteSpace(request.FamilyName) ||
            request.FamilyName.Trim().Length > 120 ||
            string.IsNullOrWhiteSpace(request.IdempotencyKey) ||
            request.IdempotencyKey.Trim().Length is < 8 or > 128 ||
            request.TermsVersion != CurrentTermsVersion)
        {
            throw new RegistrationValidationException("بيانات طلب الانتساب غير مكتملة أو غير صالحة.");
        }

        var phone = NormalizePhone(request.Phone);
        if (phone is not null &&
            (phone.Length is < 8 or > 16 || phone[0] != '+' || phone[1..].Any(c => !char.IsAsciiDigit(c))))
        {
            throw new RegistrationValidationException("رقم الهاتف يجب أن يكون بصيغة دولية صحيحة.");
        }
    }

    private static string? NormalizePhone(string? phone)
    {
        var value = phone?.Trim();
        return string.IsNullOrEmpty(value) ? null : value;
    }
}
