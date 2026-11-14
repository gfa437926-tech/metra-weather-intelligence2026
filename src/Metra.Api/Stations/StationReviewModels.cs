using System.Text.Json.Serialization;

namespace Metra.Api.Stations;

public sealed record StationReviewQueueResponse(
    [property: JsonPropertyName("stations")] IReadOnlyList<StationReviewItem> Stations,
    [property: JsonPropertyName("total")] long Total,
    [property: JsonPropertyName("page")] int Page,
    [property: JsonPropertyName("page_size")] int PageSize);

public sealed record StationReviewItem(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("local_station_code")] string LocalStationCode,
    [property: JsonPropertyName("name_ar")] string NameAr,
    [property: JsonPropertyName("name_en")] string NameEn,
    [property: JsonPropertyName("station_type")] string StationType,
    [property: JsonPropertyName("operational_status")] string OperationalStatus,
    [property: JsonPropertyName("approval_status")] string ApprovalStatus,
    [property: JsonPropertyName("owner_organization_id")] Guid OwnerOrganizationId,
    [property: JsonPropertyName("current_coordinate")] StationCoordinate? CurrentCoordinate);

public sealed record StationCoordinate(
    [property: JsonPropertyName("latitude")] decimal Latitude,
    [property: JsonPropertyName("longitude")] decimal Longitude,
    [property: JsonPropertyName("location_source")] string LocationSource,
    [property: JsonPropertyName("source_reference")] string? SourceReference);

public sealed record StationReviewDecisionRequest(
    [property: JsonPropertyName("decision")] string Decision,
    [property: JsonPropertyName("reason")] string Reason);

public sealed record StationReviewDecisionResponse(
    [property: JsonPropertyName("result_status")] string ResultStatus,
    [property: JsonPropertyName("id")] Guid StationId,
    [property: JsonPropertyName("resulting_status")] string ResultingStatus);

public sealed class StationReviewAccessDeniedException : Exception
{
    public StationReviewAccessDeniedException() : base("The current user cannot review this station.") { }
}
public sealed class StationReviewConflictException(string message) : Exception(message);
public sealed class StationReviewValidationException(string message) : Exception(message);
