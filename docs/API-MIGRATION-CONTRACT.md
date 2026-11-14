# .NET API Migration Contract

Status: design contract derived from the live greenfield schema and current Flutter/Edge Function callers. This document does not claim that API endpoints are implemented.

## Security boundary

- Flutter authenticates with Supabase Auth and sends the user's access token as a Bearer token to the .NET API.
- The API validates signature, issuer, audience, expiry and not-before against the configured Supabase project.
- The API derives the actor exclusively from the validated JWT `sub`; never accept an actor/user ID from request bodies.
- PostgreSQL credentials remain server-side. Flutter must never receive a database password, Supabase secret key or `service_role` key.
- Domain schemas (`iam`, `catalog`, `ref`, `observations`, etc.) are not exposed to the public Data API. All domain reads/writes go through the trusted API.
- Every operation must resolve authorization from current database state: active profile, active membership, valid role assignment and/or permission grant, and matching organization/unit/station scope. JWT user metadata is not an authorization source.
- Every mutation uses parameterized SQL, a database transaction, an idempotency strategy where retryable, and an append-only audit event. Return generic client errors; log details with a correlation ID.

## Live schema vocabulary

The current model uses these names; do not reintroduce the retired `public` names from old Edge Functions:

- Identity: `iam.user_profiles`, `iam.organizations`, `iam.organization_units`, `iam.memberships`, `iam.roles`, `iam.permissions`, `iam.role_permissions`, `iam.role_assignments`, `iam.permission_grants`.
- Registration: `iam.registration_requests`, `iam.registration_decisions`.
- Station catalogue: `catalog.stations`, `catalog.station_types`, `catalog.station_locations`, `catalog.station_capabilities`, `catalog.station_operating_periods`, `catalog.station_reviews`.
- Reference data: `ref.units`, `ref.parameters`, `ref.observation_types`.
- Observations: `observations.submissions`, `observations.values`, `observations.revisions`, `observations.review_decisions`, `observations.quality_flags`, `observations.attachments`.
- Audit: `audit.events`.

## Endpoint contract to implement

All routes are versioned under `/api/v1`. Except health endpoints, require a valid Supabase access token.

| Route | Purpose | Required authorization |
|---|---|---|
| `GET /health/live` | Process liveness only | Public |
| `GET /health/ready` | Verify required configuration and DB connectivity without exposing details | Internal/hosting probe |
| `GET /api/v1/me` | Current profile, active memberships, scoped roles and permissions | Authenticated actor |
| `GET /api/v1/registration/catalog` | Requestable roles and eligible organizations/stations | Authenticated actor; expose only active approved catalogue rows |
| `GET /api/v1/registration/status` | Own account/registration state only | Actor owns the request |
| `POST /api/v1/registration` | Create an application using actor ID from JWT and a client idempotency key | Authenticated actor; validate selected station/organization consistency and requestable role |
| `GET /api/v1/stations` | Paginated station directory with current valid location | `stations.read` in the requested scope |
| `GET /api/v1/stations/review-queue` | Pending station review queue | `stations.catalogue.review` in authorized scope |
| `POST /api/v1/stations/{id}/decisions` | Approve/return/reject station catalogue submission | Same scoped review permission; append review decision |
| `GET /api/v1/observations` | Own submissions and review queue, separately scoped | `observations.read` and/or review permission |
| `POST /api/v1/observations` | Create draft or submit a measurement set | `observations.create` for the selected station |
| `POST /api/v1/observations/{id}/decisions` | Approve, return or reject a submission | Review permission for that station |
| `GET /api/v1/reference/observation-types` | Active observation types | Authenticated actor |
| `GET /api/v1/reference/parameters` | Approved active measurement definitions and units | Authenticated actor |

Pagination must be cursor- or keyset-based with a bounded page size. Do not silently truncate review queues.

## Authorization algorithm

For each protected operation:

1. Validate JWT cryptographically and obtain immutable actor ID from `sub`.
2. Load `iam.user_profiles`; require `profile_state = 'active'`.
3. Resolve active memberships where `membership_state = 'active'`, `valid_from <= now()`, and `valid_to` is null or in the future.
4. Resolve active role assignments tied to those memberships, with valid date range and the requested organization/unit/station scope.
5. Resolve permissions through `iam.role_permissions` + `iam.permissions`, and direct `iam.permission_grants` only when `grant_state` and validity dates allow them.
6. Apply resource ownership/scope predicates in the same query or transaction as the read/write. A permission code alone is insufficient: prevent BOLA/IDOR by checking organization, unit and station scope against the target row.
7. Re-check critical authorization inside the transaction immediately before the mutation. Never trust client-supplied role codes or station ownership.

## Contract gaps to resolve before enabling legacy screens

1. **Registration name fields:** the current Flutter form collects first, father and last names. The new `iam.user_profiles` schema has `given_name` and `family_name`, not a separate father-name column. Do not silently discard or merge the father name. Decide whether to change the form or approve a schema extension before shipping registration.
2. **Registration organization:** `iam.registration_requests` requires `organization_id` as well as `requested_station_id` and `requested_role_id`. Derive and validate the organization from the selected station on the server; never accept an arbitrary organization/station pairing.
3. **Role identifiers:** the new schema uses UUID `requested_role_id` referencing `iam.roles.id`; the legacy client sends a string `role_code`. The API may accept a public code only after looking it up server-side and checking `is_requestable` and `role_state`.
4. **Observation parameter catalogue:** `ref.parameters` is intentionally not populated with meteorological parameter definitions yet. The existing Flutter screen hard-codes temperature, humidity, wind, pressure and precipitation names/ranges. Do not write those values into the typed observation model until the scientific parameter definitions, units, value kinds, precision and validation rules are formally approved. Do not infer scientific limits.
5. **Observation types:** map UI choices to active rows in `ref.observation_types` by `type_code`; do not assume old string enums are database IDs.
6. **Old Edge Functions:** `station-directory`, `registration`, `registration-approvals`, `observations`, and `station-review` contain queries/RPCs against the retired schema. They must remain treated as incompatible until replaced and end-to-end tested against this contract.

## Delivery gates

- Add API unit tests for token claims, permission scope and request validation.
- Add integration tests against a disposable PostgreSQL/Supabase-compatible test database for registration idempotency, station organization matching, observation revision lifecycle and review decisions.
- Add negative BOLA/IDOR tests across two organizations and two stations.
- Add replay tests for duplicate idempotency keys and conflicting payloads.
- Run .NET build/test and Flutter analyze/test/build in CI.
- Do not enable the old client flows or claim production readiness until all tests pass.
- Keep the new project independent; no import or migration from any legacy METRA database.
