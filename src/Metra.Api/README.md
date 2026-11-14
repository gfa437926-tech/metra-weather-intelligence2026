# METRA API

Initial .NET 10 API host scaffold.

## Current implemented surface

- `GET /health/live`: process liveness.
- `GET /api/v1/me`: returns the `sub` claim only after Supabase JWT validation.

The identity endpoint is intentionally not an application-profile endpoint. It does not read `iam.user_profiles`, memberships, role assignments or permission grants. No domain workflow is enabled yet.

## Configuration

Set `SUPABASE_URL` to the URL of the new METRA Supabase project. Configure `Cors:AllowedOrigins` with the exact deployed Flutter Web origins. Leave it empty for deployments that do not need browser CORS. Do not use wildcard origins with credentials.

Database credentials are not part of this scaffold. Add them only to the API hosting secret store when the data-access layer is implemented. Never put a database password, Supabase secret key or `service_role` key in Flutter, source control, or public build arguments.

## Local run

```bash
dotnet restore src/Metra.Api/Metra.Api.csproj
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co dotnet run --project src/Metra.Api/Metra.Api.csproj
```

The API requires HTTPS metadata for JWT discovery. Do not disable issuer, audience, lifetime or signing-key validation in production.
