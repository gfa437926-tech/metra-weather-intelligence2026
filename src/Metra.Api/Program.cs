using System.Security.Claims;
using System.Threading.RateLimiting;
using Metra.Api.Data;
using Metra.Api.Identity;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.IdentityModel.Tokens;

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
    catch (Npgsql.NpgsqlException)
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
    catch (Npgsql.NpgsqlException)
    {
        return Results.Problem(
            title: "The identity service is temporarily unavailable",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
})
.RequireAuthorization();

app.Run();

public partial class Program { }
