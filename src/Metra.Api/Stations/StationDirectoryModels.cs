using System.Text.Json.Serialization;

namespace Metra.Api.Stations;

public sealed record StationDirectoryResponse(
    [property: JsonPropertyName("stations")] IReadOnlyList<StationDirectoryItem> Stations,
    [property: JsonPropertyName("total")] long Total,
    [property: JsonPropertyName("page")] int Page,
    [property: JsonPropertyName("page_size")] int PageSize);

public sealed record StationDirectoryItem(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("local_station_code")] string LocalStationCode,
    [property: JsonPropertyName("name_ar")] string NameAr,
    [property: JsonPropertyName("name_en")] string NameEn,
    [property: JsonPropertyName("station_type")] string StationType,
    [property: JsonPropertyName("operational_status")] string OperationalStatus,
    [property: JsonPropertyName("approval_status")] string ApprovalStatus,
    [property: JsonPropertyName("latitude")] decimal? Latitude,
    [property: JsonPropertyName("longitude")] decimal? Longitude);

public sealed class StationDirectoryAccessDeniedException : Exception;
