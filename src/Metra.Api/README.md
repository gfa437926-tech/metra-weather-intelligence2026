# METRA API

.NET 10 backend for the new METRA Supabase project.

## Implemented endpoints

- `GET /health/live`: process liveness.
- `GET /health/ready`: verifies server-side PostgreSQL connectivity.
- `GET /api/v1/me`: resolves the authenticated profile, memberships, scoped roles and effective permissions.
- `GET /api/v1/stations?page=1&page_size=100`: approved station directory filtered by `stations.read` scope.
- `GET /api/v1/stations/review-queue?page=1&page_size=100` and `POST /api/v1/stations/{id}/decisions`: scoped station review with separation-of-duties, optimistic state checks and append-only decision/audit records.
- `GET /api/v1/registration/status`, `GET /api/v1/registration/catalog`, `POST /api/v1/registration`: registration state, approved station/requestable-role catalogue and idempotent request submission.
- `GET /api/v1/registration/approvals?page=1&page_size=100` and `POST /api/v1/registration/{requestId}/decisions`: two-stage station then organization approval, scoped by the new `registrations.review_station` and `registrations.review_organization` permissions.
- `GET /api/v1/reference/observation-types` and `GET /api/v1/reference/parameters`: active reference catalogues only.
- `GET /api/v1/observations/stations?page=1&page_size=200`: active approved stations where the caller has `observations.create`.
- `GET /api/v1/observations/mine?page=1&page_size=50`: caller's own submissions and typed values.
- `GET /api/v1/observations/review-queue?page=1&page_size=50` and `POST /api/v1/observations/{submissionId}/decisions`: scoped review and append-only decision/audit records.
- `POST /api/v1/observations`: typed, idempotent observation draft/submission using the active parameter definitions, canonical units and declared precision. No meteorological min/max thresholds are invented in the API.

All domain endpoints require a cryptographically validated Supabase access token. The actor is derived only from the token `sub`; no actor ID is accepted from request bodies.

## Server configuration

Required environment variables:

- `SUPABASE_URL`: URL of the new METRA Supabase project.
- `METRA_DATABASE_CONNECTION_STRING`: server-only PostgreSQL connection string supplied by the deployment secret manager. TLS is enforced with certificate and hostname verification. Use a dedicated least-privilege backend database role.

Flutter build-time configuration:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `METRA_API_URL`

The publishable key and API URL are public client configuration. Never put a Supabase secret/service-role key or PostgreSQL password in Flutter, source control, or public build arguments.

The PostgreSQL runtime login and deployment secret are not configured yet. The existing `metra_api_runtime` role currently lacks the required schema/table grants and a login credential. Therefore `/health/ready` and database-backed routes intentionally return 503 until a least-privilege connection is provisioned. No database password has been generated or embedded in source control.

## Local build and test

```bash
dotnet restore src/Metra.Api.Tests/Metra.Api.Tests.csproj
dotnet test src/Metra.Api.Tests/Metra.Api.Tests.csproj --configuration Release
dotnet build src/Metra.Api/Metra.Api.csproj --configuration Release
```

## Security controls

- JWT issuer, audience, lifetime and signing key validation.
- Current database permissions are loaded per request; JWT role metadata is not trusted.
- Organization/station scope checks are enforced server-side on station, registration and observation operations.
- Self-review is blocked for station and observation decisions.
- State transitions use row locks and expected-state checks.
- Registration and observation submissions use idempotency keys.
- Registration, station and observation decisions write append-only decision/audit records.
- Typed observation values must match active `ref.parameters.value_kind`; decimal precision follows the declared parameter precision. No scientific range is assumed.
- Unit-scoped station access is denied until the station catalogue has an explicit station-to-unit relationship.

## Remaining backend work

- Provision a dedicated database login with explicit grants and RLS-bypass only for that restricted backend role, then store its connection string in a hosting secret manager.
- Deploy the .NET API and configure the production `METRA_API_URL`.
- Implement station creation/update, organization bootstrap, full user/role administration, observation revision/edit workflow, file authorization, forecast ingestion, alerts, operations, exports and audit query endpoints.
- Add integration tests against a disposable database for transactions, registration state transitions, observation idempotency and BOLA/IDOR boundaries.
- Reconstruct the source SQL for the three earlier greenfield rebuild migrations. Their remote migration history exists, but their SQL source files are still missing from Git.
