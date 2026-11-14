namespace Metra.Api.Identity;

public static class PermissionScopeEvaluator
{
    public static bool Allows(
        IEnumerable<PermissionScopeResponse> permissions,
        string requiredPermission,
        Guid organizationId,
        Guid? unitId,
        Guid stationId)
    {
        return permissions.Any(permission =>
            string.Equals(permission.PermissionCode, requiredPermission, StringComparison.Ordinal)
            && permission.ScopeType switch
            {
                "global" => permission.OrganizationId is null
                    && permission.UnitId is null
                    && permission.StationId is null,
                "organization" => permission.OrganizationId == organizationId
                    && permission.UnitId is null
                    && permission.StationId is null,
                "unit" => permission.OrganizationId == organizationId
                    && unitId is not null
                    && permission.UnitId == unitId
                    && permission.StationId is null,
                "station" => permission.OrganizationId == organizationId
                    && permission.UnitId is null
                    && permission.StationId == stationId,
                _ => false
            });
    }
}
