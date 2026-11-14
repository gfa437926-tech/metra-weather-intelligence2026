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
- `GET /api/v1/alerts?page=1&page_size=50`: returns alert events addressed to the authenticated user, or to an organization/station covered by the user's `alerts.read` scope.
- `POST /api/v1/observations`: typed, idempotent observation draft/submission using the active parameter definitions, canonical units and declared precision. No meteorological min/max thresholds are invented in the API.

All domain endpoints require a cryptographically validated Supabase access token. The actor is derived only from the token `sub`; no actor ID is accepted from request bodies.

## Server configuration

Required environment variables:

- `SUPABASE_URL`: URL of the new METRA Supabase project.
- `METRA_DATABASE_CONNECTION_STRING`: server-only PostgreSQL connection string supplied by the deployment secret manager. TLS is enforced with certificate and hostname verification. Use a dedicated least-privilege backend database role.

Flutter build-time configuration:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `METRA_API_URL` (must use HTTPS; the Flutter API client rejects plaintext HTTP endpoints and unsafe absolute request paths).

The publishable key and API URL are public client configuration. Never put a Supabase secret/service-role key or PostgreSQL password in Flutter, source control, or public build arguments.

The `metra_api_runtime` role has been provisioned as `NOLOGIN`, `NOBYPASSRLS`, with schema/table grants and internal RLS policies for the API's current read/write paths. Application-level authorization remains mandatory because these policies intentionally permit the trusted runtime role to access the tables it needs. A separate managed login role that inherits `metra_api_runtime`, its password, a hosting secret and a deployable API host are still not configured. Therefore `/health/ready` and database-backed routes intentionally return 503 until a least-privilege connection is provisioned. No database password is stored in source control.

## Local build and test

```bash
dotnet restore src/Metra.Api.Tests/Metra.Api.Tests.csproj
dotnet test src/Metra.Api.Tests/Metra.Api.Tests.csproj --configuration Release
dotnet build src/Metra.Api/Metra.Api.csproj --configuration Release
```

The API CI additionally starts an isolated local Supabase stack, replays the complete migration set into its empty database, creates a disposable login role that inherits `metra_api_runtime` without superuser or RLS-bypass privileges, and runs `MetraApiIntegrationTests` against that role. The local test password exists only inside that disposable CI database; it is never reused for hosted environments. Integration tests are automatically skipped in ordinary unit-test runs unless `METRA_TEST_DATABASE_CONNECTION_STRING` is supplied.

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

- Provision a dedicated managed login role that inherits `metra_api_runtime`, store its connection string in the hosting secret manager, and deploy the .NET API.
- Configure production `METRA_API_URL` and exact Flutter Web CORS origins.
- Implement station creation/update, organization bootstrap, full user/role administration, observation revision/edit workflow, file authorization, forecast ingestion, alert ingestion/rule management, operations, exports and audit query endpoints.
- Migration source coverage is reconciled at the version/file-name level: the new METRA database reports 86 applied migration versions, and the active branch contains 86 SQL migration files with an exact one-to-one version match (no missing remote versions, local-only versions or duplicate version numbers).
- `supabase/migrations/ledger.manifest` is checked against the active SQL files by `scripts/verify_migration_source.py`. The dedicated migration CI workflow replays all migrations into an isolated, empty local Supabase database and verifies 86 ledger rows, 46 METRA tables with RLS enabled, the expected IAM seed counts, and empty station/user/observation operational catalogues.
- This verifies reproducible source coverage and a clean local rebuild; it does not execute or rewrite the hosted migration ledger. The hosted project has been inspected read-only, and no production migration was applied during reconciliation.
