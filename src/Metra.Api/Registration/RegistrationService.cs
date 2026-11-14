using Metra.Api.Data;
using Npgsql;

namespace Metra.Api.Registration;

public interface IRegistrationService
{
    Task<RegistrationCatalogResponse> GetCatalogAsync(CancellationToken cancellationToken);
    Task<RegistrationStatusResponse> GetStatusAsync(Guid userId, CancellationToken cancellationToken);
    Task<RegistrationSubmissionResponse> SubmitAsync(
        Guid userId,
        RegistrationSubmissionRequest request,
        CancellationToken cancellationToken);
}

public sealed class RegistrationService(MetraDatabase database) : IRegistrationService
{
    private const string CurrentTermsVersion = "metra-terms-2026-11";

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
                   s.operational_status, s.approval_status, s.owner_organization_id
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
                    reader.GetGuid(7)));
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
                family_name = @family_name,
                display_name = @display_name,
                phone_e164 = @phone_e164,
                updated_at = now()
            where user_id = @user_id;
            """;
        await using (var command = new NpgsqlCommand(updateProfileSql, connection, transaction))
        {
            command.Parameters.AddWithValue("given_name", request.GivenName.Trim());
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
