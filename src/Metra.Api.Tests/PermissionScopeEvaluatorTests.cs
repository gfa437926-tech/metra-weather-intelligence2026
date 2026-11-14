using Xunit;
using Metra.Api.Identity;

namespace Metra.Api.Tests;

public sealed class PermissionScopeEvaluatorTests
{
    private static readonly Guid OrganizationA = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    private static readonly Guid OrganizationB = Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
    private static readonly Guid UnitA = Guid.Parse("11111111-1111-1111-1111-111111111111");
    private static readonly Guid UnitB = Guid.Parse("22222222-2222-2222-2222-222222222222");
    private static readonly Guid StationA = Guid.Parse("33333333-3333-3333-3333-333333333333");
    private static readonly Guid StationB = Guid.Parse("44444444-4444-4444-4444-444444444444");

    [Fact]
    public void Global_permission_allows_resources_in_any_organization()
    {
        var permissions = new[]
        {
            new PermissionScopeResponse("stations.read", "global", null, null, null, "role")
        };

        Assert.True(PermissionScopeEvaluator.Allows(
            permissions, "stations.read", OrganizationB, UnitB, StationB));
    }

    [Fact]
    public void Organization_permission_does_not_cross_organization_boundary()
    {
        var permissions = new[]
        {
            new PermissionScopeResponse("stations.read", "organization", OrganizationA, null, null, "role")
        };

        Assert.True(PermissionScopeEvaluator.Allows(
            permissions, "stations.read", OrganizationA, UnitA, StationA));
        Assert.False(PermissionScopeEvaluator.Allows(
            permissions, "stations.read", OrganizationB, UnitB, StationB));
    }

    [Fact]
    public void Unit_permission_requires_exact_organization_and_unit()
    {
        var permissions = new[]
        {
            new PermissionScopeResponse("observations.read_station", "unit", OrganizationA, UnitA, null, "role")
        };

        Assert.True(PermissionScopeEvaluator.Allows(
            permissions, "observations.read_station", OrganizationA, UnitA, StationA));
        Assert.False(PermissionScopeEvaluator.Allows(
            permissions, "observations.read_station", OrganizationA, UnitB, StationB));
        Assert.False(PermissionScopeEvaluator.Allows(
            permissions, "observations.read_station", OrganizationB, UnitA, StationA));
    }

    [Fact]
    public void Station_permission_is_limited_to_the_exact_station()
    {
        var permissions = new[]
        {
            new PermissionScopeResponse("observations.review", "station", OrganizationA, null, StationA, "role")
        };

        Assert.True(PermissionScopeEvaluator.Allows(
            permissions, "observations.review", OrganizationA, UnitA, StationA));
        Assert.False(PermissionScopeEvaluator.Allows(
            permissions, "observations.review", OrganizationA, UnitA, StationB));
        Assert.False(PermissionScopeEvaluator.Allows(
            permissions, "observations.review", OrganizationB, UnitA, StationA));
    }

    [Fact]
    public void Malformed_scope_is_denied()
    {
        var permissions = new[]
        {
            new PermissionScopeResponse("stations.read", "organization", OrganizationA, UnitA, null, "role")
        };

        Assert.False(PermissionScopeEvaluator.Allows(
            permissions, "stations.read", OrganizationA, UnitA, StationA));
    }
    [Fact]
    public void Station_registration_review_is_limited_to_the_assigned_station()
    {
        var permissions = new[]
        {
            new PermissionScopeResponse(
                "registrations.review_station", "station", OrganizationA, null, StationA, "role")
        };

        Assert.True(PermissionScopeEvaluator.Allows(
            permissions, "registrations.review_station", OrganizationA, null, StationA));
        Assert.False(PermissionScopeEvaluator.Allows(
            permissions, "registrations.review_station", OrganizationA, null, StationB));
    }

    [Fact]
    public void Organization_registration_review_cannot_cross_organization_boundary()
    {
        var permissions = new[]
        {
            new PermissionScopeResponse(
                "registrations.review_organization", "organization", OrganizationA, null, null, "role")
        };

        Assert.True(PermissionScopeEvaluator.Allows(
            permissions, "registrations.review_organization", OrganizationA, UnitA, StationA));
        Assert.False(PermissionScopeEvaluator.Allows(
            permissions, "registrations.review_organization", OrganizationB, UnitB, StationB));
    }

    [Fact]
    public void Global_registration_review_requires_a_truly_global_scope()
    {
        var globalPermission = new[]
        {
            new PermissionScopeResponse(
                "registrations.review_station", "global", null, null, null, "role")
        };
        var malformedGlobalPermission = new[]
        {
            new PermissionScopeResponse(
                "registrations.review_station", "global", OrganizationA, null, null, "role")
        };

        Assert.True(PermissionScopeEvaluator.Allows(
            globalPermission, "registrations.review_station", OrganizationB, UnitB, StationB));
        Assert.False(PermissionScopeEvaluator.Allows(
            malformedGlobalPermission, "registrations.review_station", OrganizationB, UnitB, StationB));
    }

}
