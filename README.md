# METRA Weather Intelligence

Flutter/Dart meteorological platform with an Arabic RTL interface. Flutter is the active client scope; Angular is deferred. The repository is independent of the legacy METRA application and must not import its station catalogue or operational records.

## Run locally

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://tbdnklyxjvbrilvnwgmq.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

Use only the Supabase publishable key in client applications. Never include a Supabase secret, service-role key, JWT signing secret or database password in Flutter, source control, web build arguments or client-visible configuration.

## Web release

```bash
flutter build web --release --dart-define=SUPABASE_URL=https://tbdnklyxjvbrilvnwgmq.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

The web build is generated in `build/web`. GitHub Actions uploads a CI artifact named `metra-web-release` after source checks and tests pass. The artifact is a build output, not an automatically hosted public website.

## Flutter interface coverage

The mobile shell uses five primary destinations: home, map, stations, observations, and work centre. The work centre groups the wider operational modules:

- Forecast-centre comparison with station search, type, coordinate and elevation filters, and station detail views.
- Detailed hourly, daily, 06/18 UTC synoptic, agricultural, rainfall, phenomena, soil-temperature and operational incident forms.
- Forecaster preparation and bulletin draft/review/approval/correction interfaces.
- Electronic audit, paper/mechanical recorder review and three-source comparison.
- AI device library, training-set governance and model-version surfaces.
- CLIMATOL, climate homogenization, climate archive, reports and quality-control queues.
- AFTN composition, inbox/outbox and delivery/ACK views.
- User, role and permission-domain workspaces, registration approvals and station review.
- Alerts lifecycle and account/password-recovery surfaces.

**Interface versus integration:** these screens do not imply live data. Station telemetry, official alerts, AFTN transmission, bulletin decoding, electronic audit reads, report aggregation/export, CLIMATOL execution, paper/recorder ingestion, AI training/inference and permission-grant management remain disconnected or approval-gated. The UI shows explicit unavailable states and does not fabricate station readings, alerts, users, climate products or approvals. Observation forms keep unsupported save/send operations disabled.

See:
- [Flutter interface coverage](docs/FLUTTER_INTERFACE_COVERAGE.md)
- [Flutter implementation tracker](docs/FLUTTER_UI_IMPLEMENTATION_TRACKER.md)
- [Forecast-centre UI and data contract](docs/FORECAST_CENTRE_UI_AND_DATA_CONTRACT.md)

## Live Supabase project — verified status (2026-11-15)

The configured project `tbdnklyxjvbrilvnwgmq` is **not empty**. A read-only inspection found PostgreSQL 17.11 with 46 application tables across 10 schemas: `iam`, `catalog`, `ref`, `files`, `observations`, `weather`, `alerts`, `operations`, `integration` and `audit`. All 46 inspected application tables have RLS enabled. The public schema has no application tables.

The current catalogue has **zero rows in `catalog.stations`**. The UI must not repopulate it from the legacy station list. The only reference data observed included 7 station types, 3 observation types, 10 roles, 27 permissions and 78 role-permission links. No station records or operational observations were seeded by this work.

### Supabase API and Edge Function compatibility

Five Edge Functions are currently deployed as ACTIVE and have `verify_jwt=true` plus `auth.getUser` checks:
- `station-directory`
- `registration`
- `registration-approvals`
- `observations`
- `station-review`

However, all five still query old public-schema tables such as `station_catalogue`, `metra_account_states`, `metra_observations` and old registration/permission tables, and call RPCs that are absent from the live database. The live schema instead uses normalized `iam`, `catalog` and `observations` tables. These functions must **not** be treated as operational merely because they are deployed or JWT-verified. Do not redeploy them until their contracts are rebuilt and tested against the new model.

All five current functions use the server-side `SUPABASE_SERVICE_ROLE_KEY` admin client and wildcard CORS. The service-role identity bypasses RLS. Restrict CORS to approved origins and move routine operations to a reviewed least-privilege runtime identity before production. Never send the service-role key to Flutter.

The current .NET API foundation in [PR #1](https://github.com/gfa437926-tech/metra-weather-intelligence2026/pull/1) provides JWT validation, `GET /api/v1/me` and liveness only; it has no database connection or business endpoints yet. It remains Draft and unmerged.

### Migration history and reproducibility

Supabase reports **86 applied migration records**. All 86 SQL statements have been recovered read-only into `supabase/live-schema-history/` using their exact live version/name identifiers. This directory is an archive only; **do not apply it wholesale**.

The active `supabase/migrations/` directory currently has 52 files:
- 51 active version IDs also exist in the live migration history.
- 45 of those 51 shared-version files are not byte-identical to the recovered live SQL; a version match does not prove content equivalence.
- `20261110120000_honor_scheduled_permission_revocation.sql` is present in Git but absent from the live applied migration history.
- The archive contains 35 additional live migration versions not represented in the active directory.

The greenfield rebuild migration `20261114184511_metra_greenfield_application_schema_rebuild` explicitly drops the `metra_migration` schema with CASCADE. The current project no longer has that schema. The separate legacy database was not accessed by this work.

A clean, curated migration sequence, SQL-content reconciliation, destructive-operation review and disposable-database replay are mandatory before schema certification or any new hosted DDL. The script `scripts/verify_live_schema_history.py` verifies archive inventory and version mapping only; it does not execute SQL or certify a replay.

### Runtime identity and authorization

- All 46 inspected application tables have RLS enabled.
- The inspected `anon` and `authenticated` roles have no table CRUD grants or application-domain function EXECUTE grants.
- Supabase `service_role` has `BYPASSRLS=true` and broad table access.
- The `metra_api_runtime` role is currently `NOLOGIN`, `NOBYPASSRLS`, and has no application-function EXECUTE grants. It is not yet a working API identity.
- Hosted Data API exposed-schema settings still require confirmation.

Before production, implement a least-privilege runtime identity or a narrowly bounded server-side RPC gateway, bind actor identity to the validated JWT subject, and test cross-authority/station denials under the actual runtime identity. Do not grant the runtime role service-role membership or BYPASSRLS as a shortcut.

## Data integrity and current integrations

- Home-screen conditions and hourly forecast use Open-Meteo model/provider values for Damascus (33.5138, 36.2765; `Asia/Damascus`). These are not METRA station telemetry.
- The map uses OpenStreetMap tiles. No station markers are fabricated when the approved catalogue is empty.
- Automatic precipitation, wind, pressure, humidity and visibility telemetry is not connected.
- Official weather alerts and radar/precipitation/temperature/wind map layers are not connected.
- AFTN transmission and final protocol framing are disabled pending a reviewed gateway.
- Bulletin decoding remains a raw-message preview only.
- CLIMATOL calculations, homogenization, corrected-series persistence and climate reports remain disabled pending approved scientific definitions and service contracts.
- Paper/mechanical recorder OCR, image extraction, confidence scoring and human approval workflows remain UI-only.
- AI training, evaluation, model registry and inference are not connected.
- No old station list or old operational data has been imported into the current build.

## CI and current verification status

GitHub Actions checks:
1. Recovered live migration archive inventory.
2. Deno type checks for the five Edge Functions.
3. Deno validation, permission and batching tests.
4. `flutter pub get`, `flutter analyze` and `flutter test`.
5. `flutter build web --release` and web artifact upload.

The previous Flutter CI run on PR #2 reported **65 tests passed and 3 widget tests failed** because three long workspace filter buttons were below the default test viewport. The tests now use the existing tall-viewport helper; assertions were retained. The fix commit is `3a47c1ade10dcaa65e6af63c44fcfd5ee9566896`. GitHub has not yet attached a new CI run to the latest PR head, so the fix is **not yet CI-verified**.

A green source CI run does not prove live database compatibility, a real authenticated user journey, hosted website deployment or mobile store readiness.

## Native mobile packaging gate

The repository does not yet contain `android/` or `ios/` platform projects. Current CI validates Flutter source and the web release only; it does not produce an APK/AAB or iOS archive. Native scaffolding, an approved reverse-domain application identifier, signing/provisioning and platform-specific builds remain release gates. No package identifier, certificate or signing secret has been invented or committed.

## Current pull requests

- [PR #2 — Flutter operational workspace](https://github.com/gfa437926-tech/metra-weather-intelligence2026/pull/2): open, Draft, unmerged.
- [PR #1 — .NET 10 API foundation](https://github.com/gfa437926-tech/metra-weather-intelligence2026/pull/1): open, Draft, unmerged.

No PR was merged, no deployment was performed, and no hosted database, role, grant, policy, secret or Edge Function was changed during the 2026-11-15 inspection and source-recovery work.
