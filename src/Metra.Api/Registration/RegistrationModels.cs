using System.Text.Json.Serialization;

namespace Metra.Api.Registration;

public sealed record RegistrationCatalogResponse(
    [property: JsonPropertyName("roles")] IReadOnlyList<RegistrationRole> Roles,
    [property: JsonPropertyName("stations")] IReadOnlyList<RegistrationStation> Stations);

public sealed record RegistrationRole(
    [property: JsonPropertyName("role_code")] string RoleCode,
    [property: JsonPropertyName("name_ar")] string NameAr,
    [property: JsonPropertyName("name_en")] string NameEn);

public sealed record RegistrationStation(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("local_station_code")] string LocalStationCode,
    [property: JsonPropertyName("name_ar")] string NameAr,
    [property: JsonPropertyName("name_en")] string NameEn,
    [property: JsonPropertyName("station_type")] string StationType,
    [property: JsonPropertyName("operational_status")] string OperationalStatus,
    [property: JsonPropertyName("approval_status")] string ApprovalStatus,
    [property: JsonPropertyName("owner_organization_id")] Guid OwnerOrganizationId);

public sealed record RegistrationStatusResponse(
    [property: JsonPropertyName("account_state")] string AccountState,
    [property: JsonPropertyName("state_reason")] string? StateReason,
    [property: JsonPropertyName("request_state")] string? RequestState);

public sealed record RegistrationSubmissionRequest(
    Guid StationId,
    string RoleCode,
    string GivenName,
    string FatherName,
    string FamilyName,
    string? Phone,
    string TermsVersion,
    string IdempotencyKey);

public sealed record RegistrationSubmissionResponse(
    [property: JsonPropertyName("result_status")] string ResultStatus,
    [property: JsonPropertyName("request_id")] Guid RequestId,
    [property: JsonPropertyName("request_state")] string RequestState);

public sealed class RegistrationValidationException(string message) : Exception(message);
public sealed class RegistrationConflictException(string message) : Exception(message);
