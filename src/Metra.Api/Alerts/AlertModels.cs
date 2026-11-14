using System.Text.Json.Serialization;

namespace Metra.Api.Alerts;

public sealed record AlertListResponse(
    [property: JsonPropertyName("items")] IReadOnlyList<AlertListItem> Items,
    [property: JsonPropertyName("total")] long Total,
    [property: JsonPropertyName("page")] int Page,
    [property: JsonPropertyName("page_size")] int PageSize);

public sealed record AlertListItem(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("alert_code")] string? AlertCode,
    [property: JsonPropertyName("severity")] string Severity,
    [property: JsonPropertyName("headline")] string Headline,
    [property: JsonPropertyName("description")] string? Description,
    [property: JsonPropertyName("area_reference")] string? AreaReference,
    [property: JsonPropertyName("starts_at")] DateTimeOffset? StartsAt,
    [property: JsonPropertyName("ends_at")] DateTimeOffset? EndsAt,
    [property: JsonPropertyName("event_state")] string EventState,
    [property: JsonPropertyName("created_at")] DateTimeOffset CreatedAt,
    [property: JsonPropertyName("acknowledged_at")] DateTimeOffset? AcknowledgedAt);

public sealed class AlertAccessDeniedException : Exception
{
    public AlertAccessDeniedException() : base("The current user cannot read alerts in the requested scope.") { }
}
