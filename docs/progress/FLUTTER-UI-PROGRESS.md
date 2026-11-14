# METRA Flutter UI Progress

Last updated: 2026-11-14 20:52 UTC

## Current branch state

- **Repository:** `gfa437926-tech/metra-weather-intelligence2026`
- **Branch:** `work/database-architecture-fresh-design-2026-11-14`
- **Scope:** Flutter Web + Android + iOS client for the new METRA database and .NET API.
- **No legacy repository or database was accessed or modified.**

## Implemented screens and connected flows

- Arabic RTL application shell and primary navigation.
- Dashboard weather cards and hourly forecast from Open-Meteo, explicitly labelled as model/provider forecasts rather than station telemetry.
- Interactive OpenStreetMap station map and station directory loaded through the authenticated .NET API.
- Registration, account-status gate and two-stage registration approval screens.
- Station review and decision flow.
- Observation form, own-submission history and scoped review queue. Fields are generated from the live reference catalogue; because scientific parameter/unit definitions are intentionally empty, operational measurement submission remains disabled instead of fabricating parameters or limits.
- Forecast-centres workspace showing verified station metadata only.
- Alert centre now reads alert events from `GET /api/v1/alerts`, filtered by the authenticated user's `alerts.read` scope. This is an internal alert-event feed, not an official weather-alert provider.
- Settings screen shows current role and permission context and supports sign-out.

## Verified checks

- `flutter analyze`: passed with no issues.
- `flutter test`: 45 passed.
- `flutter build web --release`: passed.
- .NET API CI: 14 tests passed, Release build passed, Docker image build passed.
- Retained Edge Function source checks/tests: passed; deployed legacy functions are not called by migrated Flutter screens.

Android APK/App Bundle and unsigned iOS build jobs are enabled in CI. Their final results and artifact availability must be confirmed from the latest workflow run before claiming mobile release artifacts are ready.

## Remaining work

1. Deploy the .NET API to a connected hosting provider and configure its secret-only PostgreSQL connection string.
2. Provision a managed login role that inherits the non-login `metra_api_runtime` role; keep RLS bypass disabled.
3. Configure production `METRA_API_URL`, Flutter Web CORS origins and release environment values.
4. Add operational station create/update, full user/role administration, alert ingestion/rule management, forecast ingestion, operations, file access, exports and complete observation revision workflows.
5. Add integration/security tests against a disposable database, including transaction, BOLA/IDOR and lifecycle cases.
6. Reconcile migration history: 86 remote versions, 55 local files, 32 remote versions without source files, and one local-only file.
7. Verify end-to-end login, station-scoped access, registration approval, observation submission/review and alert feed against the deployed service.

## Progress accounting

The Flutter UI and its current client-side tests/build are substantially implemented, but a passing build is not proof of a live application. The client cannot be treated as production-ready until the API is hosted, database login is provisioned, and authenticated end-to-end workflows pass. Mobile signing is also not configured; the iOS artifact is intentionally unsigned.
