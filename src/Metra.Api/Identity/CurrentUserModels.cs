namespace Metra.Api.Identity;

public sealed record CurrentUserResponse(
    Guid UserId,
    string? Email,
    string? DisplayName,
    string? GivenName,
    string? FatherName,
    string? FamilyName,
    string ProfileState,
    IReadOnlyList<MembershipResponse> Memberships,
    IReadOnlyList<PermissionScopeResponse> Permissions);

public sealed record MembershipResponse(
    Guid MembershipId,
    Guid OrganizationId,
    string OrganizationCode,
    string OrganizationNameAr,
    Guid? UnitId,
    string? UnitCode,
    string? UnitNameAr,
    IReadOnlyList<RoleAssignmentResponse> Roles);

public sealed record RoleAssignmentResponse(
    Guid AssignmentId,
    string RoleCode,
    string RoleNameAr,
    string ScopeType,
    Guid? OrganizationId,
    Guid? UnitId,
    Guid? StationId,
    IReadOnlyList<string> Permissions);

public sealed record PermissionScopeResponse(
    string PermissionCode,
    string ScopeType,
    Guid? OrganizationId,
    Guid? UnitId,
    Guid? StationId,
    string Source);
