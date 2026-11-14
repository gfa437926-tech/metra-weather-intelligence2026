using Metra.Api.Identity;

namespace Metra.Api.Alerts;

public sealed record AlertReadScope(
    bool IsGlobal,
    Guid[] OrganizationIds,
    Guid[] StationIds)
{
    public static AlertReadScope? TryResolve(IEnumerable<PermissionScopeResponse> permissions)
    {
        var relevant = permissions
            .Where(permission => permission.PermissionCode == "alerts.read")
            .ToArray();

        var global = relevant.Any(permission =>
            permission.ScopeType == "global"
            && permission.OrganizationId is null
            && permission.UnitId is null
            && permission.StationId is null);

        var organizations = relevant
            .Where(permission =>
                permission.ScopeType == "organization"
                && permission.OrganizationId is not null
                && permission.UnitId is null
                && permission.StationId is null)
            .Select(permission => permission.OrganizationId!.Value)
            .Distinct()
            .ToArray();

        var stations = relevant
            .Where(permission =>
                permission.ScopeType == "station"
                && permission.OrganizationId is not null
                && permission.UnitId is null
                && permission.StationId is not null)
            .Select(permission => permission.StationId!.Value)
            .Distinct()
            .ToArray();

        return global || organizations.Length > 0 || stations.Length > 0
            ? new AlertReadScope(global, organizations, stations)
            : null;
    }
}
