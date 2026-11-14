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
    [property: JsonPropertyName("owner_organization_id")] Guid OwnerOrganizationId,
    [property: JsonPropertyName("authority_name")] string AuthorityName);

public sealed record RegistrationStatusResponse(
    [property: JsonPropertyName("account_state")] string AccountState,
    [property: JsonPropertyName("state_reason")] string? StateReason,
    [property: JsonPropertyName("request_state")] string? RequestState);

public sealed record RegistrationSubmissionRequest(
    [property: JsonPropertyName("station_id")] Guid StationId,
    [property: JsonPropertyName("role_code")] string RoleCode,
    [property: JsonPropertyName("first_name")] string GivenName,
    [property: JsonPropertyName("father_name")] string FatherName,
    [property: JsonPropertyName("last_name")] string FamilyName,
    [property: JsonPropertyName("phone")] string? Phone,
    [property: JsonPropertyName("terms_version")] string TermsVersion,
    [property: JsonPropertyName("idempotency_key")] string IdempotencyKey);

public sealed record RegistrationSubmissionResponse(
    [property: JsonPropertyName("result_status")] string ResultStatus,
    [property: JsonPropertyName("request_id")] Guid RequestId,
    [property: JsonPropertyName("request_state")] string RequestState);

public sealed class RegistrationValidationException(string message) : Exception(message);
public sealed class RegistrationConflictException(string message) : Exception(message);

public sealed record RegistrationApprovalApplicant(
    [property: JsonPropertyName("first_name")] string? FirstName,
    [property: JsonPropertyName("father_name")] string? FatherName,
    [property: JsonPropertyName("last_name")] string? LastName);

public sealed record RegistrationApprovalStation(
    [property: JsonPropertyName("name_ar")] string NameAr,
    [property: JsonPropertyName("local_station_code")] string LocalStationCode);

public sealed record RegistrationApprovalRole(
    [property: JsonPropertyName("name_ar")] string NameAr);

public sealed record RegistrationApprovalItem(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("status")] string Status,
    [property: JsonPropertyName("review_stage")] string ReviewStage,
    [property: JsonPropertyName("applicant")] RegistrationApprovalApplicant Applicant,
    [property: JsonPropertyName("station")] RegistrationApprovalStation Station,
    [property: JsonPropertyName("requested_role")] RegistrationApprovalRole RequestedRole,
    [property: JsonPropertyName("requested_role_code")] string RequestedRoleCode,
    [property: JsonPropertyName("submitted_at")] DateTimeOffset SubmittedAt);

public sealed record RegistrationApprovalQueueResponse(
    [property: JsonPropertyName("items")] IReadOnlyList<RegistrationApprovalItem> Items,
    [property: JsonPropertyName("total")] long Total,
    [property: JsonPropertyName("page")] int Page,
    [property: JsonPropertyName("page_size")] int PageSize);

public sealed record RegistrationApprovalDecisionRequest(
    [property: JsonPropertyName("expected_status")] string ExpectedStatus,
    [property: JsonPropertyName("decision")] string Decision,
    [property: JsonPropertyName("note")] string? Note);

public sealed record RegistrationApprovalDecisionResponse(
    [property: JsonPropertyName("result_status")] string ResultStatus,
    [property: JsonPropertyName("resulting_status")] string ResultingStatus);

public sealed class RegistrationApprovalAccessDeniedException : Exception
{
    public RegistrationApprovalAccessDeniedException() : base("The current user cannot review this registration request.") { }
}
public sealed class RegistrationApprovalConflictException(string message) : Exception(message);
public sealed class RegistrationApprovalValidationException(string message) : Exception(message);
