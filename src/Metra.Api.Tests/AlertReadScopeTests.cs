using Metra.Api.Alerts;
using Metra.Api.Identity;
using Xunit;

namespace Metra.Api.Tests;

public sealed class AlertReadScopeTests
{
    private static readonly Guid OrganizationA = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    private static readonly Guid StationA = Guid.Parse("33333333-3333-3333-3333-333333333333");

    [Fact]
    public void Missing_alert_permission_is_denied()
    {
        Assert.Null(AlertReadScope.TryResolve([
            new PermissionScopeResponse("stations.read", "global", null, null, null, "role")
        ]));
    }

    [Fact]
    public void Malformed_global_scope_is_denied()
    {
        Assert.Null(AlertReadScope.TryResolve([
            new PermissionScopeResponse("alerts.read", "global", OrganizationA, null, null, "role")
        ]));
    }

    [Fact]
    public void Organization_scope_is_restricted_to_its_organization()
    {
        var scope = AlertReadScope.TryResolve([
            new PermissionScopeResponse("alerts.read", "organization", OrganizationA, null, null, "role")
        ]);

        Assert.NotNull(scope);
        Assert.False(scope.IsGlobal);
        Assert.Equal([OrganizationA], scope.OrganizationIds);
        Assert.Empty(scope.StationIds);
    }

    [Fact]
    public void Station_scope_is_restricted_to_the_assigned_station()
    {
        var scope = AlertReadScope.TryResolve([
            new PermissionScopeResponse("alerts.read", "station", OrganizationA, null, StationA, "role")
        ]);

        Assert.NotNull(scope);
        Assert.False(scope.IsGlobal);
        Assert.Empty(scope.OrganizationIds);
        Assert.Equal([StationA], scope.StationIds);
    }

    [Fact]
    public void Unit_only_scope_is_not_widened_to_organization_alerts()
    {
        Assert.Null(AlertReadScope.TryResolve([
            new PermissionScopeResponse("alerts.read", "unit", OrganizationA,
                Guid.NewGuid(), null, "role")
        ]));
    }

    [Fact]
    public void Global_scope_requires_all_scope_columns_to_be_null()
    {
        var scope = AlertReadScope.TryResolve([
            new PermissionScopeResponse("alerts.read", "global", null, null, null, "role")
        ]);

        Assert.NotNull(scope);
        Assert.True(scope.IsGlobal);
    }
}
