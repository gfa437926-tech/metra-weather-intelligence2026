using System.Security.Claims;
using System.Threading.RateLimiting;
using Metra.Api.Data;
using Metra.Api.Identity;
using Metra.Api.Stations;
using Metra.Api.Registration;
using Metra.Api.Reference;
using Metra.Api.Observations;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.IdentityModel.Tokens;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);

var supabaseUrl = builder.Configuration["Supabase:Url"]
    ?? Environment.GetEnvironmentVariable("SUPABASE_URL");
if (string.IsNullOrWhiteSpace(supabaseUrl))
{
    throw new InvalidOperationException("SUPABASE_URL must be configured for JWT issuer validation.");
}

var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
    ?? [];

builder.Services.AddProblemDetails();
builder.Services.AddHealthChecks();
builder.Services.AddSingleton<MetraDatabase>();
builder.Services.AddScoped<ICurrentUserService, CurrentUserService>();
builder.Services.AddScoped<IStationDirectoryService, StationDirectoryService>();
builder.Services.AddScoped<IStationReviewService, StationReviewService>();
builder.Services.AddScoped<IRegistrationService, RegistrationService>();
builder.Services.AddScoped<IReferenceDataService, ReferenceDataService>();
builder.Services.AddScoped<IObservationService, ObservationService>();

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = $"{supabaseUrl.TrimEnd('/')}/auth/v1";
        options.Audience = "authenticated";
        options.RequireHttpsMetadata = true;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ClockSkew = TimeSpan.FromSeconds(60),
            NameClaimType = "sub"
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddCors(options =>
{
    options.AddPolicy("ConfiguredClients", policy =>
    {
        if (allowedOrigins.Length > 0)
        {
            policy.WithOrigins(allowedOrigins)
                .AllowAnyHeader()
                .AllowAnyMethod();
        }
    });
});

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
    {
        var partitionKey = context.User.FindFirstValue("sub")
            ?? context.Connection.RemoteIpAddress?.ToString()
            ?? "unknown";
        return RateLimitPartition.GetFixedWindowLimiter(partitionKey, _ =>
            new FixedWindowRateLimiterOptions
            {
                PermitLimit = 120,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
                AutoReplenishment = true
            });
    });
});

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler();
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseCors("ConfiguredClients");
app.UseAuthentication();
app.UseRateLimiter();
app.UseAuthorization();

app.MapHealthChecks("/health/live").AllowAnonymous();

app.MapGet("/health/ready", async (MetraDatabase database, CancellationToken cancellationToken) =>
{
    try
    {
        return await database.ProbeAsync(cancellationToken)
            ? Results.Ok(new { status = "ready" })
            : Results.Problem(
                title: "Database is not configured or unavailable",
                statusCode: StatusCodes.Status503ServiceUnavailable);
    }
    catch (NpgsqlException)
    {
        return Results.Problem(
            title: "Database is not configured or unavailable",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
    catch (DatabaseNotConfiguredException)
    {
        return Results.Problem(
            title: "Database is not configured or unavailable",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
}).AllowAnonymous();

app.MapGet("/api/v1/me", async (
    ClaimsPrincipal principal,
    ICurrentUserService currentUserService,
    CancellationToken cancellationToken) =>
{
    var subject = principal.FindFirstValue("sub");
    if (!Guid.TryParse(subject, out var userId))
    {
        return Results.Unauthorized();
    }

    try
    {
        var currentUser = await currentUserService.GetAsync(userId, cancellationToken);
        if (currentUser is null || !string.Equals(
                currentUser.ProfileState, "active", StringComparison.Ordinal))
        {
            return Results.Forbid();
        }

        return Results.Ok(currentUser);
    }
    catch (DatabaseNotConfiguredException)
    {
        return Results.Problem(
            title: "The identity service is temporarily unavailable",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
    catch (NpgsqlException)
    {
        return Results.Problem(
            title: "The identity service is temporarily unavailable",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
})
.RequireAuthorization();

app.MapGet("/api/v1/stations", async (
    HttpRequest request,
    ClaimsPrincipal principal,
    IStationDirectoryService stationDirectory,
    CancellationToken cancellationToken) =>
{
    var subject = principal.FindFirstValue("sub");
    if (!Guid.TryParse(subject, out var userId))
    {
        return Results.Unauthorized();
    }

    if (!int.TryParse(request.Query["page"], out var page)) page = 1;
    if (!int.TryParse(request.Query["page_size"], out var pageSize)) pageSize = 100;
    if (page < 1 || pageSize is < 1 or > 200)
    {
        return Results.ValidationProblem(new Dictionary<string, string[]>
        {
            ["pagination"] = ["page must be positive and page_size must be between 1 and 200."]
        });
    }

    try
    {
        return Results.Ok(await stationDirectory.GetAsync(
            userId, page, pageSize, cancellationToken));
    }
    catch (StationDirectoryAccessDeniedException)
    {
        return Results.Forbid();
    }
    catch (DatabaseNotConfiguredException)
    {
        return Results.Problem(
            title: "The station directory is temporarily unavailable",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
    catch (NpgsqlException)
    {
        return Results.Problem(
            title: "The station directory is temporarily unavailable",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
})
.RequireAuthorization();


app.MapGet("/api/v1/registration/status", async (
    ClaimsPrincipal principal,
    IRegistrationService registrationService,
    CancellationToken cancellationToken) =>
{
    var subject = principal.FindFirstValue("sub");
    if (!Guid.TryParse(subject, out var userId))
    {
        return Results.Unauthorized();
    }

    try
    {
        return Results.Ok(await registrationService.GetStatusAsync(userId, cancellationToken));
    }
    catch (DatabaseNotConfiguredException)
    {
        return Results.Problem(
            title: "Registration status is temporarily unavailable",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
    catch (NpgsqlException)
    {
        return Results.Problem(
            title: "Registration status is temporarily unavailable",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
})
.RequireAuthorization();

app.MapGet("/api/v1/registration/catalog", async (
    ClaimsPrincipal principal,
    ICurrentUserService currentUserService,
    IRegistrationService registrationService,
    CancellationToken cancellationToken) =>
{
    var subject = principal.FindFirstValue("sub");
    if (!Guid.TryParse(subject, out var userId))
    {
        return Results.Unauthorized();
    }

    try
    {
        var currentUser = await currentUserService.GetAsync(userId, cancellationToken);
        if (currentUser is null || currentUser.ProfileState != "active")
        {
            return Results.Forbid();
        }

        return Results.Ok(await registrationService.GetCatalogAsync(cancellationToken));
    }
    catch (DatabaseNotConfiguredException)
    {
        return Results.Problem(
            title: "Registration catalogue is temporarily unavailable",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
    catch (NpgsqlException)
    {
        return Results.Problem(
            title: "Registration catalogue is temporarily unavailable",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
})
.RequireAuthorization();

app.MapPost("/api/v1/registration", async (
    RegistrationSubmissionRequest request,
    ClaimsPrincipal principal,
    IRegistrationService registrationService,
    CancellationToken cancellationToken) =>
{
    var subject = principal.FindFirstValue("sub");
    if (!Guid.TryParse(subject, out var userId))
    {
        return Results.Unauthorized();
    }

    try
    {
        return Results.Ok(await registrationService.SubmitAsync(userId, request, cancellationToken));
    }
    catch (RegistrationValidationException exception)
    {
        return Results.ValidationProblem(new Dictionary<string, string[]>
        {
            ["registration"] = [exception.Message]
        });
    }
    catch (RegistrationConflictException exception)
    {
        return Results.Problem(
            title: exception.Message,
            statusCode: StatusCodes.Status409Conflict);
    }
    catch (DatabaseNotConfiguredException)
    {
        return Results.Problem(
            title: "Registration service is temporarily unavailable",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
    catch (NpgsqlException)
    {
        return Results.Problem(
            title: "Registration service is temporarily unavailable",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
})
.RequireAuthorization();


app.MapGet("/api/v1/reference/observation-types", async (
    ClaimsPrincipal principal,
    ICurrentUserService currentUserService,
    IReferenceDataService referenceData,
    CancellationToken cancellationToken) =>
{
    var subject = principal.FindFirstValue("sub");
    if (!Guid.TryParse(subject, out var userId)) return Results.Unauthorized();
    try
    {
        var user = await currentUserService.GetAsync(userId, cancellationToken);
        if (user is null || user.ProfileState != "active") return Results.Forbid();
        return Results.Ok(await referenceData.GetObservationTypesAsync(cancellationToken));
    }
    catch (DatabaseNotConfiguredException)
    {
        return Results.Problem(title: "Reference catalogue unavailable", statusCode: 503);
    }
    catch (NpgsqlException)
    {
        return Results.Problem(title: "Reference catalogue unavailable", statusCode: 503);
    }
})
.RequireAuthorization();

app.MapGet("/api/v1/reference/parameters", async (
    ClaimsPrincipal principal,
    ICurrentUserService currentUserService,
    IReferenceDataService referenceData,
    CancellationToken cancellationToken) =>
{
    var subject = principal.FindFirstValue("sub");
    if (!Guid.TryParse(subject, out var userId)) return Results.Unauthorized();
    try
    {
        var user = await currentUserService.GetAsync(userId, cancellationToken);
        if (user is null || user.ProfileState != "active") return Results.Forbid();
        return Results.Ok(await referenceData.GetParametersAsync(cancellationToken));
    }
    catch (DatabaseNotConfiguredException)
    {
        return Results.Problem(title: "Reference catalogue unavailable", statusCode: 503);
    }
    catch (NpgsqlException)
    {
        return Results.Problem(title: "Reference catalogue unavailable", statusCode: 503);
    }
})
.RequireAuthorization();


app.MapGet("/api/v1/stations/review-queue", async (
    HttpRequest request,
    ClaimsPrincipal principal,
    IStationReviewService stationReview,
    CancellationToken cancellationToken) =>
{
    var subject = principal.FindFirstValue("sub");
    if (!Guid.TryParse(subject, out var userId)) return Results.Unauthorized();
    if (!int.TryParse(request.Query["page"], out var page)) page = 1;
    if (!int.TryParse(request.Query["page_size"], out var pageSize)) pageSize = 100;
    if (page < 1 || pageSize is < 1 or > 200)
    {
        return Results.ValidationProblem(new Dictionary<string, string[]>
        {
            ["pagination"] = ["page must be positive and page_size must be between 1 and 200."]
        });
    }
    try
    {
        return Results.Ok(await stationReview.GetQueueAsync(
            userId, page, pageSize, cancellationToken));
    }
    catch (StationReviewAccessDeniedException)
    {
        return Results.Forbid();
    }
    catch (DatabaseNotConfiguredException)
    {
        return Results.Problem(title: "Station review service unavailable", statusCode: 503);
    }
    catch (NpgsqlException)
    {
        return Results.Problem(title: "Station review service unavailable", statusCode: 503);
    }
})
.RequireAuthorization();

app.MapPost("/api/v1/stations/{stationId:guid}/decisions", async (
    Guid stationId,
    StationReviewDecisionRequest request,
    ClaimsPrincipal principal,
    IStationReviewService stationReview,
    CancellationToken cancellationToken) =>
{
    var subject = principal.FindFirstValue("sub");
    if (!Guid.TryParse(subject, out var userId)) return Results.Unauthorized();
    try
    {
        return Results.Ok(await stationReview.DecideAsync(
            userId, stationId, request, cancellationToken));
    }
    catch (StationReviewAccessDeniedException)
    {
        return Results.Forbid();
    }
    catch (StationReviewValidationException exception)
    {
        return Results.ValidationProblem(new Dictionary<string, string[]>
        {
            ["decision"] = [exception.Message]
        });
    }
    catch (StationReviewConflictException exception)
    {
        return Results.Problem(title: exception.Message, statusCode: 409);
    }
    catch (DatabaseNotConfiguredException)
    {
        return Results.Problem(title: "Station review service unavailable", statusCode: 503);
    }
    catch (NpgsqlException)
    {
        return Results.Problem(title: "Station review service unavailable", statusCode: 503);
    }
})
.RequireAuthorization();


app.MapGet("/api/v1/observations/mine", async (
    HttpRequest request,
    ClaimsPrincipal principal,
    IObservationService observations,
    CancellationToken cancellationToken) =>
{
    var subject = principal.FindFirstValue("sub");
    if (!Guid.TryParse(subject, out var userId)) return Results.Unauthorized();
    if (!int.TryParse(request.Query["page"], out var page)) page = 1;
    if (!int.TryParse(request.Query["page_size"], out var pageSize)) pageSize = 50;
    if (page < 1 || pageSize is < 1 or > 200)
    {
        return Results.ValidationProblem(new Dictionary<string, string[]>
        {
            ["pagination"] = ["page must be positive and page_size must be between 1 and 200."]
        });
    }

    try
    {
        return Results.Ok(await observations.GetOwnAsync(
            userId, page, pageSize, cancellationToken));
    }
    catch (ObservationAccessDeniedException)
    {
        return Results.Forbid();
    }
    catch (DatabaseNotConfiguredException)
    {
        return Results.Problem(title: "Observation service unavailable", statusCode: 503);
    }
    catch (NpgsqlException)
    {
        return Results.Problem(title: "Observation service unavailable", statusCode: 503);
    }
})
.RequireAuthorization();

app.MapPost("/api/v1/observations", async (
    ObservationSubmissionRequest request,
    ClaimsPrincipal principal,
    IObservationService observations,
    CancellationToken cancellationToken) =>
{
    var subject = principal.FindFirstValue("sub");
    if (!Guid.TryParse(subject, out var userId)) return Results.Unauthorized();

    try
    {
        return Results.Ok(await observations.SubmitAsync(userId, request, cancellationToken));
    }
    catch (ObservationAccessDeniedException)
    {
        return Results.Forbid();
    }
    catch (ObservationValidationException exception)
    {
        return Results.ValidationProblem(new Dictionary<string, string[]>
        {
            ["observation"] = [exception.Message]
        });
    }
    catch (ObservationConflictException exception)
    {
        return Results.Problem(title: exception.Message, statusCode: 409);
    }
    catch (DatabaseNotConfiguredException)
    {
        return Results.Problem(title: "Observation service unavailable", statusCode: 503);
    }
    catch (NpgsqlException)
    {
        return Results.Problem(title: "Observation service unavailable", statusCode: 503);
    }
})
.RequireAuthorization();

app.Run();

public partial class Program { }
