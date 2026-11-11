# ASP.NET Core API foundation — 2026-11-10

## Repository and branch

- Repository: `gfa437926-tech/metra-weather-intelligence2026`
- Branch: `feat/aspnet-core-api-foundation`
- Base: `main`
- Framework target: .NET 10 (LTS)
- Language: C#

## What was added

A new `backend/Metra.Api` ASP.NET Core Web API project with:
- Supabase Auth JWT bearer validation configured through HTTPS authority and audience.
- Authenticated `GET /api/v1/me`, deriving the account identifier only from the validated `sub` claim.
- Anonymous `GET /health/live`.
- Strict configured CORS origins, per-subject/IP fixed-window rate limiting, HTTPS redirection, HSTS outside Development, security headers, and Problem Details exception handling.
- A separate HTTP test project covering authenticated identity resolution and liveness.

## Explicit exclusions

- No database connection string or database client.
- No Supabase service-role key or project-owner credentials.
- No SQL execution, migration application, schema modification, or data access.
- No legacy repository or legacy database access.
- No permission-grant, station-assignment, observation, or approval write endpoints.
- No merge to `main`.

## Required validation before production

The new project's exact Supabase Auth issuer, audience, signing algorithm/key mode, and claims must be checked against the new project's Auth settings. This source foundation assumes the Supabase Auth OIDC authority supports metadata/JWKS discovery; if the project uses legacy HS256 signing, use a separately reviewed validation design rather than copying the JWT secret into source code.

The `metra_api_runtime` role exists in migration source but is not used by this API. Its role membership, login, and permissions remain unverified. Do not provision or grant it until the schema and access path have been reviewed and explicitly approved.

The CI workflow must restore, build, and test the API in addition to existing Flutter/Deno checks. A green source CI run does not prove staging or production readiness.
