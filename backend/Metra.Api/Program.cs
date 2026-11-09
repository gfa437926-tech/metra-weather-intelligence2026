using System.Security.Claims;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.IdentityModel.Tokens;
using Metra.Api.Configuration;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddProblemDetails();
builder.Services.AddOptions<SupabaseAuthOptions>()
    .BindConfiguration(SupabaseAuthOptions.SectionName)
    .Validate(options =>
        Uri.TryCreate(options.Authority, UriKind.Absolute, out var authority) &&
        authority.Scheme == Uri.UriSchemeHttps &&
        !string.IsNullOrWhiteSpace(options.Audience),
        "SupabaseAuth:Authority must be an HTTPS URL and Audience must be configured.")
    .ValidateOnStart();

var authOptions = builder.Configuration
    .GetSection(SupabaseAuthOptions.SectionName)
    .Get<SupabaseAuthOptions>() ?? new SupabaseAuthOptions();

if (!Uri.TryCreate(authOptions.Authority, UriKind.Absolute, out var authAuthority) ||
    authAuthority.Scheme != Uri.UriSchemeHttps ||
    string.IsNullOrWhiteSpace(authOptions.Audience))
{
    throw new InvalidOperationException(
        "Configure SupabaseAuth:Authority (HTTPS) and SupabaseAuth:Audience before starting the API.");
}

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = authAuthority.ToString().TrimEnd('/');
        options.Audience = authOptions.Audience;
        options.RequireHttpsMetadata = true;
        options.MapInboundClaims = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            NameClaimType = "sub",
            ClockSkew = TimeSpan.FromMinutes(1)
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("metra-user", policy =>
    {
        policy.RequireAuthenticatedUser();
        policy.RequireClaim("sub");
    });
});

var allowedOrigins = builder.Configuration
    .GetSection("Cors:AllowedOrigins")
    .Get<string[]>() ?? [];

if (allowedOrigins.Any(origin =>
        !Uri.TryCreate(origin, UriKind.Absolute, out var uri) ||
        (uri.Scheme != Uri.UriSchemeHttps && !builder.Environment.IsDevelopment())))
{
    throw new InvalidOperationException(
        "Cors:AllowedOrigins must contain valid HTTPS origins (HTTP is allowed only in Development).");
}

builder.Services.AddCors(options =>
{
    options.AddPolicy("metra-web", policy =>
    {
        if (allowedOrigins.Length == 0)
        {
            policy.SetIsOriginAllowed(_ => false);
            return;
        }

        policy.WithOrigins(allowedOrigins)
            .AllowAnyHeader()
            .WithMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS");
    });
});

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy("metra-api", context =>
    {
        var partitionKey = context.User.FindFirstValue("sub")
            ?? context.Connection.RemoteIpAddress?.ToString()
            ?? "unknown";

        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey,
            _ => new FixedWindowRateLimiterOptions
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
    app.UseHsts();
}

app.Use(async (context, next) =>
{
    context.Response.Headers["X-Content-Type-Options"] = "nosniff";
    context.Response.Headers["X-Frame-Options"] = "DENY";
    context.Response.Headers["Referrer-Policy"] = "no-referrer";
    context.Response.Headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()";
    context.Response.Headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'";
    await next();
});

app.UseExceptionHandler();
app.UseHttpsRedirection();
app.UseCors("metra-web");
app.UseAuthentication();
app.UseRateLimiter();
app.UseAuthorization();

app.MapGet("/health/live", () => Results.Ok(new { status = "live" }))
    .AllowAnonymous();

var api = app.MapGroup("/api/v1")
    .RequireRateLimiting("metra-api");

api.MapGet("/me", (ClaimsPrincipal principal) =>
{
    var subject = principal.FindFirstValue("sub");
    if (!Guid.TryParse(subject, out var userId))
    {
        return Results.Forbid();
    }

    return Results.Ok(new CurrentUserResponse(userId));
})
.RequireAuthorization("metra-user");

app.Run();

public sealed record CurrentUserResponse(Guid UserId);

public partial class Program
{
}
