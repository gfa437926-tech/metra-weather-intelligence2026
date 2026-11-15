# METRA ASP.NET Core API

This is the independent .NET 10 API foundation for the METRA Flutter application.

## Current scope

- ASP.NET Core 10 / C#.
- Supabase Auth JWT validation using the configured HTTPS authority and the `authenticated` audience.
- A minimal authenticated identity endpoint: `GET /api/v1/me`.
- Anonymous liveness endpoint: `GET /health/live`.
- Explicit CORS allow-list, rate limiting, standard security headers, HTTPS redirection, HSTS outside Development, and generic Problem Details handling.
- Automated HTTP smoke tests using a test authentication handler.

## Configure locally

Set the following environment variables before running the API:

```powershell
$env:SupabaseAuth__Authority = "https://YOUR_NEW_PROJECT_REF.supabase.co/auth/v1"
$env:SupabaseAuth__Audience = "authenticated"
$env:Cors__AllowedOrigins__0 = "https://YOUR_METRA_WEB_ORIGIN"
dotnet run --project backend/Metra.Api/Metra.Api.csproj
```

For local Flutter web development, add the exact local origin (for example `http://localhost:PORT`) to the allow-list only while running in Development. Do not use wildcard origins with credentials.

## Test

```bash
dotnet restore backend/Metra.Api.Tests/Metra.Api.Tests.csproj
dotnet test backend/Metra.Api.Tests/Metra.Api.Tests.csproj --configuration Release
dotnet build backend/Metra.Api/Metra.Api.csproj --configuration Release --no-restore
```

## Security boundary — not production-ready yet

This initial foundation deliberately does **not** connect to PostgreSQL, Supabase PostgREST, or any database. It does not contain a service-role key, database password, signing secret, or other credential. It does not execute SQL or migrations.

Before adding business endpoints:

1. Validate the exact JWT issuer, audience, signing-key mode (Supabase asymmetric JWKS versus legacy HS256), and claim mapping against the new project's Auth configuration.
2. Keep the actor identifier derived only from the validated `sub` claim. Never accept `actor_user_id` from request JSON, query strings, headers, or route parameters.
3. Use narrowly scoped application services and call only reviewed server-side Edge Functions/RPCs. Do not connect as `postgres`, project owner, or `service_role`.
4. Reconcile the `metra_api_runtime` database role and its RPC grants against the approved schema before considering direct database access. The current API does not use that role.
5. Implement each permission check inside the database transaction or trusted server-side function that performs the write; controller/UI checks alone are insufficient.
6. Add negative integration tests for cross-station access, grantor delegation ceilings, self-approval, disabled accounts, expiry/revocation windows, and denied-write side effects.
7. Configure secrets in the deployment secret manager. Never commit them to this repository or Flutter build variables.

No business write, permission grant, station assignment, observation approval, or database migration is implemented by this foundation. Treat it as a secure starting point, not a completed production backend.
