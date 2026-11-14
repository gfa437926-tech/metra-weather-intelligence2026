# METRA API

.NET 10 API host for the new METRA Supabase project.

## Implemented endpoints

- `GET /health/live`: process liveness; does not assert database availability.
- `GET /health/ready`: verifies that a server-side PostgreSQL connection is configured and can execute a probe.
- `GET /api/v1/me`: validates the Supabase access token, resolves the profile, active memberships, scoped role assignments and direct permission grants from the new `iam` schema.
- `GET /api/v1/stations?page=1&page_size=100`: returns approved station metadata and the current valid location, filtered by the caller's current `stations.read` organization/global/station scopes. Page size is limited to 200.

All domain endpoints require a cryptographically validated Supabase access token. The actor is derived only from the token `sub`; no actor ID is accepted from the request body.

## Server configuration

Required environment variables:

- `SUPABASE_URL`: URL of the new METRA Supabase project.
- `METRA_DATABASE_CONNECTION_STRING`: server-only PostgreSQL connection string supplied by the deployment secret manager. TLS is enforced with certificate and hostname verification. Use a dedicated least-privilege backend database role; do not use a superuser connection for routine application traffic.

Optional configuration:

- `Cors:AllowedOrigins`: exact Flutter Web origins. Keep empty when browser CORS is not needed. Do not use wildcard origins.

No database credential, Supabase secret key, or `service_role` key belongs in Flutter, source control, or public build arguments.

The database connection secret and a deployable .NET hosting target have not yet been configured. Without them, `/health/ready` and database-backed routes intentionally return 503 rather than presenting empty or fabricated data.

## Local build and test

```bash
dotnet restore src/Metra.Api.Tests/Metra.Api.Tests.csproj
dotnet test src/Metra.Api.Tests/Metra.Api.Tests.csproj --configuration Release
dotnet build src/Metra.Api/Metra.Api.csproj --configuration Release
```

## Security notes

- JWT issuer, audience, lifetime and signing key are validated.
- Authorization data is loaded from current database state, not user-editable JWT metadata.
- Station reads are constrained server-side by permission scope.
- Unit-scoped station reads remain denied until the new catalogue has an explicit station-to-unit relationship; the current schema does not provide one.
- The API must run with a backend role that can read the required `iam`, `catalog` and `ref` tables. The live project currently has no configured login credential for this API and the `metra_api_runtime` role does not yet have the grants required by this implementation.

## Remaining API work

Registration submission and approval, station review, observation lifecycle, forecast ingestion, alerts, operations, file authorization, audit writes, and integration tests against a disposable database are not yet implemented. Do not enable legacy Edge Function callers against the new schema.
