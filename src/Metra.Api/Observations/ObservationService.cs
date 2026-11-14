using System.Text.Json;
using Metra.Api.Data;
using Metra.Api.Identity;
using Npgsql;
using NpgsqlTypes;

namespace Metra.Api.Observations;

public interface IObservationService
{
    Task<ObservationListResponse> GetOwnAsync(
        Guid userId, int page, int pageSize, CancellationToken cancellationToken);
    Task<ObservationSubmissionResponse> SubmitAsync(
        Guid userId, ObservationSubmissionRequest request, CancellationToken cancellationToken);
}

public sealed class ObservationService(
    MetraDatabase database,
    ICurrentUserService currentUserService) : IObservationService
{
    public async Task<ObservationListResponse> GetOwnAsync(
        Guid userId,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        var user = await currentUserService.GetAsync(userId, cancellationToken);
        if (user is null || user.ProfileState != "active")
            throw new ObservationAccessDeniedException();

        await using var connection = await database.OpenConnectionAsync(cancellationToken);
        const string countSql = """
            select count(*)
            from observations.submissions
            where author_user_id = @user_id;
            """;
        long total;
        await using (var command = new NpgsqlCommand(countSql, connection))
        {
            command.Parameters.AddWithValue("user_id", userId);
            total = Convert.ToInt64(await command.ExecuteScalarAsync(cancellationToken));
        }

        const string sql = """
            select s.id, s.station_id, st.station_code, st.name_ar,
                   ot.type_code, s.observed_at, s.submission_state,
                   s.revision_number, s.created_at
            from observations.submissions s
            join catalog.stations st on st.id = s.station_id
            join ref.observation_types ot on ot.id = s.observation_type_id
            where s.author_user_id = @user_id
            order by s.observed_at desc, s.id desc
            limit @page_size offset @offset;
            """;
        await using var listCommand = new NpgsqlCommand(sql, connection);
        listCommand.Parameters.AddWithValue("user_id", userId);
        listCommand.Parameters.AddWithValue("page_size", pageSize);
        listCommand.Parameters.AddWithValue("offset", checked((page - 1) * pageSize));
        await using var reader = await listCommand.ExecuteReaderAsync(cancellationToken);
        var items = new List<ObservationListItem>();
        while (await reader.ReadAsync(cancellationToken))
        {
            items.Add(new ObservationListItem(
                reader.GetGuid(0),
                reader.GetGuid(1),
                reader.GetString(2),
                reader.GetString(3),
                reader.GetString(4),
                reader.GetFieldValue<DateTimeOffset>(5),
                reader.GetString(6),
                reader.GetInt32(7),
                reader.GetFieldValue<DateTimeOffset>(8)));
        }

        return new ObservationListResponse(items, total, page, pageSize);
    }

    public async Task<ObservationSubmissionResponse> SubmitAsync(
        Guid userId,
        ObservationSubmissionRequest request,
        CancellationToken cancellationToken)
    {
        Validate(request);
        var user = await currentUserService.GetAsync(userId, cancellationToken);
        if (user is null || user.ProfileState != "active")
            throw new ObservationAccessDeniedException();

        await using var connection = await database.OpenConnectionAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

        Guid organizationId;
        const string stationSql = """
            select owner_organization_id
            from catalog.stations
            where id = @station_id
              and approval_status = 'approved'
              and operational_status = 'active'
            for share;
            """;
        await using (var command = new NpgsqlCommand(stationSql, connection, transaction))
        {
            command.Parameters.AddWithValue("station_id", request.StationId);
            var value = await command.ExecuteScalarAsync(cancellationToken);
            if (value is not Guid stationOrganizationId)
                throw new ObservationValidationException("المحطة غير معتمدة أو غير فعالة تشغيلياً.");
            organizationId = stationOrganizationId;
        }

        if (!PermissionScopeEvaluator.Allows(
            user.Permissions, "observations.create", organizationId, null, request.StationId))
            throw new ObservationAccessDeniedException();

        Guid observationTypeId;
        const string typeSql = """
            select id
            from ref.observation_types
            where type_code = @type_code and is_active = true
            limit 1;
            """;
        await using (var command = new NpgsqlCommand(typeSql, connection, transaction))
        {
            command.Parameters.AddWithValue("type_code", request.ObservationTypeCode.Trim());
            var value = await command.ExecuteScalarAsync(cancellationToken);
            if (value is not Guid typeId)
                throw new ObservationValidationException("نوع الرصد غير معتمد في القاموس المرجعي.");
            observationTypeId = typeId;
        }

        var parameters = new Dictionary<string, ParameterDefinition>(StringComparer.Ordinal);
        const string parameterSql = """
            select p.id, p.parameter_code, p.value_kind, p.canonical_unit_id, p.precision_scale
            from ref.parameters p
            where p.parameter_code = @parameter_code and p.is_active = true
            limit 1;
            """;
        foreach (var input in request.Values)
        {
            if (parameters.ContainsKey(input.ParameterCode.Trim())) continue;
            await using var command = new NpgsqlCommand(parameterSql, connection, transaction);
            command.Parameters.AddWithValue("parameter_code", input.ParameterCode.Trim());
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
                throw new ObservationValidationException(
                    $"المعيار {input.ParameterCode} غير موجود أو غير معتمد.");
            parameters.Add(input.ParameterCode.Trim(), new ParameterDefinition(
                reader.GetGuid(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.IsDBNull(3) ? null : reader.GetGuid(3),
                reader.IsDBNull(4) ? null : reader.GetInt16(4)));
        }

        foreach (var input in request.Values)
        {
            var definition = parameters[input.ParameterCode.Trim()];
            ValidateValue(input, definition);
        }

        var snapshot = JsonSerializer.Serialize(new
        {
            station_id = request.StationId,
            observation_type = request.ObservationTypeCode.Trim(),
            observed_at = request.ObservedAt,
            timezone_name = request.TimezoneName,
            values = request.Values.Select(v => new
            {
                parameter_code = v.ParameterCode.Trim(),
                value_kind = v.ValueKind,
                value_decimal = v.ValueDecimal,
                value_integer = v.ValueInteger,
                value_text = v.ValueText,
                value_boolean = v.ValueBoolean,
                sequence_number = v.SequenceNumber,
                unit_id = parameters[v.ParameterCode.Trim()].CanonicalUnitId
            }).ToArray()
        });

        const string replaySql = """
            select s.id, s.station_id, s.observation_type_id, s.observed_at,
                   s.submission_state,
                   exists (
                     select 1 from observations.revisions r
                     where r.submission_id = s.id
                       and r.revision_number = s.revision_number
                       and r.snapshot = @snapshot
                   ) as same_payload
            from observations.submissions s
            where s.author_user_id = @user_id
              and s.idempotency_key = @idempotency_key
            limit 1;
            """;
        await using (var command = new NpgsqlCommand(replaySql, connection, transaction))
        {
            command.Parameters.AddWithValue("user_id", userId);
            command.Parameters.AddWithValue("idempotency_key", request.IdempotencyKey.Trim());
            command.Parameters.Add(new NpgsqlParameter("snapshot", NpgsqlDbType.Jsonb) { Value = snapshot });
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (await reader.ReadAsync(cancellationToken))
            {
                var same = reader.GetGuid(1) == request.StationId
                    && reader.GetGuid(2) == observationTypeId
                    && reader.GetFieldValue<DateTimeOffset>(3) == request.ObservedAt
                    && reader.GetBoolean(5);
                if (!same)
                    throw new ObservationConflictException("مفتاح منع التكرار مستخدم لبيانات رصد مختلفة.");

                var existingId = reader.GetGuid(0);
                var existingStatus = reader.GetString(4);
                await reader.CloseAsync();
                await transaction.CommitAsync(cancellationToken);
                return new ObservationSubmissionResponse(existingId, existingStatus, true);
            }
        }

        var submissionId = Guid.NewGuid();
        var submissionState = request.Submit ? "submitted" : "draft";
        const string insertSql = """
            insert into observations.submissions (
                id, station_id, author_user_id, observation_type_id,
                observed_at, timezone_name, submission_state, revision_number,
                idempotency_key, submitted_at
            )
            values (
                @id, @station_id, @user_id, @type_id,
                @observed_at, @timezone_name, @state, 1,
                @idempotency_key, case when @submit then now() else null end
            );
            """;
        await using (var command = new NpgsqlCommand(insertSql, connection, transaction))
        {
            command.Parameters.AddWithValue("id", submissionId);
            command.Parameters.AddWithValue("station_id", request.StationId);
            command.Parameters.AddWithValue("user_id", userId);
            command.Parameters.AddWithValue("type_id", observationTypeId);
            command.Parameters.AddWithValue("observed_at", request.ObservedAt);
            command.Parameters.AddWithValue("timezone_name", (object?)request.TimezoneName ?? DBNull.Value);
            command.Parameters.AddWithValue("state", submissionState);
            command.Parameters.AddWithValue("idempotency_key", request.IdempotencyKey.Trim());
            command.Parameters.AddWithValue("submit", request.Submit);
            await command.ExecuteNonQueryAsync(cancellationToken);
        }

        const string insertValueSql = """
            insert into observations."values" (
                submission_id, parameter_id, value_kind,
                value_decimal, value_integer, value_text, value_boolean,
                unit_id, sequence_number, quality_state
            )
            values (
                @submission_id, @parameter_id, @value_kind,
                @value_decimal, @value_integer, @value_text, @value_boolean,
                @unit_id, @sequence_number, 'unchecked'
            );
            """;
        foreach (var input in request.Values)
        {
            var definition = parameters[input.ParameterCode.Trim()];
            await using var command = new NpgsqlCommand(insertValueSql, connection, transaction);
            command.Parameters.AddWithValue("submission_id", submissionId);
            command.Parameters.AddWithValue("parameter_id", definition.Id);
            command.Parameters.AddWithValue("value_kind", definition.ValueKind);
            command.Parameters.AddWithValue("value_decimal", (object?)input.ValueDecimal ?? DBNull.Value);
            command.Parameters.AddWithValue("value_integer", (object?)input.ValueInteger ?? DBNull.Value);
            command.Parameters.AddWithValue("value_text", (object?)input.ValueText?.Trim() ?? DBNull.Value);
            command.Parameters.AddWithValue("value_boolean", (object?)input.ValueBoolean ?? DBNull.Value);
            command.Parameters.AddWithValue("unit_id", (object?)definition.CanonicalUnitId ?? DBNull.Value);
            command.Parameters.AddWithValue("sequence_number", input.SequenceNumber);
            await command.ExecuteNonQueryAsync(cancellationToken);
        }

        const string revisionSql = """
            insert into observations.revisions (
                submission_id, revision_number, snapshot, changed_by, change_reason
            )
            values (@submission_id, 1, @snapshot, @user_id, 'initial_submission');
            """;
        await using (var command = new NpgsqlCommand(revisionSql, connection, transaction))
        {
            command.Parameters.AddWithValue("submission_id", submissionId);
            command.Parameters.Add(new NpgsqlParameter("snapshot", NpgsqlDbType.Jsonb) { Value = snapshot });
            command.Parameters.AddWithValue("user_id", userId);
            await command.ExecuteNonQueryAsync(cancellationToken);
        }

        var metadata = JsonSerializer.Serialize(new
        {
            submission_state = submissionState,
            observation_type = request.ObservationTypeCode.Trim(),
            value_count = request.Values.Count
        });
        const string auditSql = """
            insert into audit.events (
                occurred_at, actor_user_id, action_code, entity_schema, entity_table,
                entity_id, organization_id, station_id, outcome, correlation_id, metadata
            )
            values (
                now(), @actor_user_id, 'observation.created', 'observations', 'submissions',
                @entity_id, @organization_id, @station_id, 'success', @correlation_id, @metadata
            );
            """;
        await using (var command = new NpgsqlCommand(auditSql, connection, transaction))
        {
            command.Parameters.AddWithValue("actor_user_id", userId);
            command.Parameters.AddWithValue("entity_id", submissionId);
            command.Parameters.AddWithValue("organization_id", organizationId);
            command.Parameters.AddWithValue("station_id", request.StationId);
            command.Parameters.AddWithValue("correlation_id", Guid.NewGuid());
            command.Parameters.Add(new NpgsqlParameter("metadata", NpgsqlDbType.Jsonb) { Value = metadata });
            await command.ExecuteNonQueryAsync(cancellationToken);
        }

        await transaction.CommitAsync(cancellationToken);
        return new ObservationSubmissionResponse(submissionId, submissionState, false);
    }

    private static void Validate(ObservationSubmissionRequest request)
    {
        if (request.StationId == Guid.Empty ||
            string.IsNullOrWhiteSpace(request.ObservationTypeCode) ||
            request.ObservationTypeCode.Trim().Length > 80 ||
            string.IsNullOrWhiteSpace(request.IdempotencyKey) ||
            request.IdempotencyKey.Trim().Length is < 8 or > 128 ||
            request.ObservedAt == default ||
            request.Values is null ||
            request.Values.Count is < 1 or > 100 ||
            request.Values.Any(v => v is null || string.IsNullOrWhiteSpace(v.ParameterCode)))
        {
            throw new ObservationValidationException("بيانات الرصد غير مكتملة أو غير صالحة.");
        }

        if (request.TimezoneName is { Length: > 100 })
            throw new ObservationValidationException("اسم المنطقة الزمنية أطول من الحد المسموح.");

        var duplicate = request.Values
            .GroupBy(v => (v.ParameterCode.Trim(), v.SequenceNumber))
            .Any(group => group.Count() > 1);
        if (duplicate)
            throw new ObservationValidationException("يوجد تكرار في معيار الرصد ورقم التسلسل.");
    }

    private static void ValidateValue(ObservationValueInput input, ParameterDefinition definition)
    {
        if (string.IsNullOrWhiteSpace(input.ParameterCode) ||
            input.ParameterCode.Trim().Length > 100 ||
            input.SequenceNumber < 1 ||
            !string.Equals(input.ValueKind, definition.ValueKind, StringComparison.Ordinal))
        {
            throw new ObservationValidationException("نوع القيمة أو تعريف المعيار غير متطابق.");
        }

        var validShape = definition.ValueKind switch
        {
            "decimal" => input.ValueDecimal is not null && input.ValueInteger is null
                && input.ValueText is null && input.ValueBoolean is null,
            "integer" => input.ValueDecimal is null && input.ValueInteger is not null
                && input.ValueText is null && input.ValueBoolean is null,
            "text" => input.ValueDecimal is null && input.ValueInteger is null
                && input.ValueText is not null && input.ValueBoolean is null,
            "boolean" => input.ValueDecimal is null && input.ValueInteger is null
                && input.ValueText is null && input.ValueBoolean is not null,
            _ => false
        };
        if (!validShape)
            throw new ObservationValidationException("يجب إرسال قيمة واحدة فقط وبالنوع المعتمد للمعيار.");

        if (definition.ValueKind == "decimal" &&
            definition.PrecisionScale is short scale &&
            decimal.Round(input.ValueDecimal!.Value, scale) != input.ValueDecimal.Value)
        {
            throw new ObservationValidationException("عدد المنازل العشرية يتجاوز دقة المعيار المعتمدة.");
        }

        if (definition.ValueKind == "text" && input.ValueText!.Length > 10000)
            throw new ObservationValidationException("النص المرسل يتجاوز الحد المسموح.");
    }

    private sealed record ParameterDefinition(
        Guid Id,
        string Code,
        string ValueKind,
        Guid? CanonicalUnitId,
        short? PrecisionScale);
}
