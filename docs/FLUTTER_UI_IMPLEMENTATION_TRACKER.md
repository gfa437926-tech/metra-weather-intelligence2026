# METRA Flutter interface completion tracker

- **Task:** FLUTTER-UI-01 — establish complete operational workspace navigation and first-pass module interfaces.
- **Status:** In progress.
- **Updated (UTC):** 2026-11-11T12:41:54.028Z
- **Repository:** `gfa437926-tech/metra-weather-intelligence2026`
- **Branch:** `feat/flutter-complete-interface-suite`
- **Base:** `main`
- **Scope order:** Flutter first. Angular work is explicitly deferred until Flutter UI acceptance.
- **Safety:** no merge, deployment, database access/write, SQL execution, schema/migration change, secret change, legacy repository/database access, or invented live station/alert values.

## Delivered in this round

1. Replaced the seven-item bottom navigation with a compact five-destination mobile navigation: home, map, stations, observations, and work centre.
2. Added a categorized work-centre catalogue for forecast centres, forecaster, bulletins, electronic audit, quality control, AFTN, CLIMATOL, reports, climate archive, users/permissions, station review, registration approvals, alerts, and account settings.
3. Added a detailed observation form catalogue with hourly/daily/synoptic and operational incident forms; source-required flags are rendered as required fields, UTC labels are explicit, conditional source notes are visible, and save/send remain disabled until the current API accepts the full payload contracts.
4. Added a forecast-centre comparison screen with station search, region/elevation filters, and explicit fields/empty states for coordinates, rainfall, wind speed/direction/gusts, timestamp, and received bulletin details.
5. Added local-only forecaster and bulletin preparation screens with required-field checks; no server write is represented as completed.
6. Added electronic-audit read-only shell, AFTN message composition and local address/priority validation, CLIMATOL analysis setup, report tabs, role overview, and account settings.
7. Added password-recovery UI through Supabase Auth.
8. Preserved existing station directory, map, observation, station review, and registration approval flows; exposed existing station-review and two-stage registration-approval interfaces from the work centre when configured.
9. Added paper/mechanical record audit, three-source comparison, device library, AI training/model-version, and climate-homogenization interface groups while preserving the raw-series immutability boundary.
10. Added tests for detailed observation forms, module catalogue coverage, AFTN address/priority validation, forecast-centre controls, paper audit and climate homogenization, and disabled AFTN transmission.
9. Updated README with interface scope and integration boundaries.

## Files changed

- `lib/main.dart`
- `lib/screens/operations_workspace.dart` (new)
- `test/widget_test.dart`
- `test/operations_workspace_test.dart` (new)
- `README.md`

## Acceptance and evidence

- Static source changes are committed on the feature branch.
- GitHub Actions Flutter analyze/test/web build is required on the PR head before any code-level acceptance claim.
- Mobile Android/iOS device acceptance, authenticated end-to-end tests, and screen-by-screen visual review remain open.
- No hosted service was queried or changed by this UI-only task.

## Remaining Flutter interface work

- Add full field-level hourly/daily observation editors matching the approved meteorological forms and validation catalogue.
- Complete sign-in/registration/approval/forgot-password journey and account-state handling.
- Replace preview-only map/alert surfaces only after approved official source contracts and credentials exist.
- Complete forecast-centre details and bulletin parsing against the agreed WMO/code formats and station feed contract.
- Complete electronic audit event detail and filters against the approved audit read model; complete original-file upload, extraction, three-source comparison, confidence and human approval workflows for paper/mechanical audits.
- Complete AFTN message queue, routing, delivery acknowledgements and operational controls after gateway/API approval.
- Complete CLIMATOL workflows and reports only after scientific variable dictionary, periods, units, quality rules and aggregation methods are approved; implement R/CLIMATOL execution, breakpoint analysis and corrected-series persistence only through approved backend contracts.
- Complete user/role/permission administration only after a reviewed grantor authority-ceiling API exists.
- Run responsive layout checks, accessibility checks, localization review, Flutter analyze/tests, Android and iOS builds, and staging acceptance.

## Release gate

This task remains **in progress**. The first-pass interfaces are not equivalent to fully integrated operational modules. No overall project percentage is changed by this UI branch.


## Follow-up round — detailed observation forms (2026-11-11T12:51:25.909Z UTC)

- Added `lib/screens/observation_forms_catalogue_page.dart` with 12 detailed form variants: standard hourly, synoptic 06 UTC, synoptic 18 UTC, daily 24h, agricultural, rainfall, weather phenomenon, agricultural phenomena, soil temperature, observation-equipment faults, telecommunications faults, and IT incidents.
- Exposed the catalogue from the operational observation screen and the work-centre navigation.
- Rendered source-required fields, grouped field labels, units, boolean controls, known fixed choice lists, UTC date/time hints, and source-specific conditional notes.
- The catalogue is a UI/domain field inventory only. It does not claim server validation, scientific limit approval, persistence or API support. Save/send remain disabled because the current observation Edge Function accepts only its narrow generic payload keys; sending these extended fields would be rejected or silently unsupported.
- Added tests for catalogue coverage, key hourly/daily fields, UTC synoptic variants and screen rendering.


## Follow-up round — forecast centre coordinates and AFTN workflow (2026-11-11T12:57:19.420Z UTC)

- Expanded forecast-centre filters to include decimal latitude/longitude bounds, elevation band, region and time windows (10 minutes, 1/3/6/24 hours), with metric slots for rainfall accumulation, wind speed/direction/gust, temperature/dew point, pressure, humidity, visibility and clouds.
- Expanded AFTN workspace to separate compose, outbox, inbox, and delivery/ACK tracking tabs. Transmission remains disabled without a reviewed gateway.
- Corrected AFTN address shape validation to eight Latin letters (ICAO address indicator); tests use generic non-operational strings, not invented station addresses.
- Added widget coverage for the new forecast coordinate/time filters and AFTN tabs.
- UTC: 2026-11-11T12:57:19.420Z.


## Follow-up round — bulletin review workflow (2026-11-11T12:58:30.486Z UTC)

- Split the bulletin interface into create/draft, pending review, approved, and returned-for-correction tabs.
- Added station, observation UTC date/time, message text, and decoded-message preview areas.
- Local completeness check is limited to required UI fields; saving, transmitting, and approval remain server-only and disabled until the bulletin contract and audit trail are approved.
- Added widget test for the four bulletin workflow states.


## Follow-up round — CLIMATOL product workspaces (2026-11-11T12:59:50.060Z UTC)

- Split climate processing into series/quality, CLIMAT, CLIMAT TEMP and statistics/report tabs.
- Added day/month/season/year period selection, element selection and an unopinionated year input rather than imposing a guessed climatological normal period.
- Exposed placeholders for missing-data/QC flags, station provenance, coded message review, monthly/seasonal/annual rainfall/temperature/wind/humidity statistics, climate indicators, trends, geographic comparisons and reports.
- Execution and report generation remain disabled until the scientific variable dictionary, units, normal periods, missing-value rules and R/CLIMATOL service contract are approved.
