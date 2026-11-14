using System.Text.Json.Serialization;

namespace Metra.Api.Observations;

public sealed record ObservationValueInput(
    [property: JsonPropertyName("parameter_code")] string ParameterCode,
    [property: JsonPropertyName("value_kind")] string ValueKind,
    [property: JsonPropertyName("value_decimal")] decimal? ValueDecimal,
    [property: JsonPropertyName("value_integer")] long? ValueInteger,
    [property: JsonPropertyName("value_text")] string? ValueText,
    [property: JsonPropertyName("value_boolean")] bool? ValueBoolean,
    [property: JsonPropertyName("sequence_number")] int SequenceNumber = 1);

public sealed record ObservationSubmissionRequest(
    [property: JsonPropertyName("station_id")] Guid StationId,
    [property: JsonPropertyName("observation_type")] string ObservationTypeCode,
    [property: JsonPropertyName("observed_at")] DateTimeOffset ObservedAt,
    [property: JsonPropertyName("timezone_name")] string? TimezoneName,
    [property: JsonPropertyName("idempotency_key")] string IdempotencyKey,
    [property: JsonPropertyName("payload")] IReadOnlyList<ObservationValueInput> Values,
    [property: JsonPropertyName("submit")] bool Submit);

public sealed record ObservationSubmissionResponse(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("status")] string Status,
    [property: JsonPropertyName("replayed")] bool Replayed);

public sealed record ObservationListItem(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("station_id")] Guid StationId,
    [property: JsonPropertyName("station_code")] string StationCode,
    [property: JsonPropertyName("station_name")] string StationName,
    [property: JsonPropertyName("observation_type")] string ObservationType,
    [property: JsonPropertyName("observed_at")] DateTimeOffset ObservedAt,
    [property: JsonPropertyName("submission_state")] string SubmissionState,
    [property: JsonPropertyName("revision_number")] int RevisionNumber,
    [property: JsonPropertyName("created_at")] DateTimeOffset CreatedAt);

public sealed record ObservationListResponse(
    [property: JsonPropertyName("items")] IReadOnlyList<ObservationListItem> Items,
    [property: JsonPropertyName("total")] long Total,
    [property: JsonPropertyName("page")] int Page,
    [property: JsonPropertyName("page_size")] int PageSize);

public sealed class ObservationAccessDeniedException : Exception
{
    public ObservationAccessDeniedException() : base("The current user cannot access this observation resource.") { }
}
public sealed class ObservationValidationException(string message) : Exception(message);
public sealed class ObservationConflictException(string message) : Exception(message);
