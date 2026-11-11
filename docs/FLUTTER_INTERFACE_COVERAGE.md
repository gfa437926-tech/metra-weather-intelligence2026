# Flutter interface coverage and completion gates

**Updated:** 2026-11-11T13:33:51.777Z UTC  
**Scope order:** Flutter first. Angular work is deferred until Flutter UI acceptance.

This matrix distinguishes a screen being present from its service integration being complete. Empty, disabled or disconnected states are intentional where no approved service contract exists; they must not be replaced with fabricated data.

| Area | Flutter interface coverage | Current integration boundary / acceptance gate |
|---|---|---|
| Sign-in and registration | Sign-in, registration, approval/activation and recovery flow screens | Requires approved identity provider configuration, redirect and recovery URLs, and secrets supplied through deployment configuration |
| Home dashboard | Main navigation, dashboard cards and shortcuts | Confirm live data sources and station-context authorization |
| Map and stations | Station map/list and station detail entry points | Verify complete approved station coordinates, elevation metadata and telemetry feed |
| Observation entry | 12 detailed forms including hourly, daily, synoptic, soil and special forms | Save/submit remains disabled until the approved API contract, server-side validation and station scope are available |
| Station review | Review queue and decision interface | Requires backend authorization and atomic approve/return plus audit transaction tests |
| Forecast centre | Station directory, coordinate/elevation filters, station detail sheet and requested measurement slots | Directory metadata is read from the protected station-directory service. Live rain/wind/pressure/temperature readings and bulletin feed/parser are not connected |
| Forecaster | Forecast product form, UTC validity fields and cross-field checks | Local validation only; persistence, approval workflow and scientific thresholds require approved contracts |
| Bulletins | Draft/review/approved/returned workspaces and raw-text preview | Raw text preview only; no approved parser, decoded observation payload or persistence endpoint connected |
| Electronic audit | Advanced filters and read-only event detail layout | Audit read-model endpoint, pagination and immutable source verification are pending |
| Paper/mechanical audit | Three-source comparison and review workspace | File upload, original evidence storage, OCR/recorder ingestion and decision persistence pending |
| AFTN | Message composition fields, field validation, local preview, outbox/inbox/delivery workspaces | Preview is local and explicitly non-final. Gateway, routing, acknowledgements and final protocol framing are not enabled |
| Quality control | Rule-group filters and rejected/warning/correction/processed queues | Approved rule catalogue, scientific validation service and correction workflow pending |
| Alerts | Official-alert search, severity/type/validity filters and lifecycle tabs | Official trusted alert feed and authorized issuer workflow pending |
| CLIMATOL | CLIMAT, CLIMAT TEMP and statistics workspaces | R execution environment, variable dictionary, WMO mapping and approved climate definitions pending |
| Climate homogenization | Raw/adjusted series and break-point review workspace | Homogenization engine, reference-station selection and approval workflow pending |
| Reports | Station, period, element, aggregation and export-format filters; daily/monthly/yearly tabs | Approved aggregation definitions and reporting API pending; export is intentionally disabled |
| Climate archive | Raw, derived and corrected-series search workspaces | Read API and lineage/version source pending; raw data remains read-only |
| Users and permissions | Account, role and permission-domain workspaces | Read-only descriptive role catalogue; identity/authorization APIs and delegation-ceiling enforcement pending |
| AI model management | Model library, training and version workspace | Model registry, execution service and governance approvals pending |
| Settings | Account and app preference screens | Persisted preferences and production identity configuration pending |

## Forecast-centre integration note

See [FORECAST_CENTRE_UI_AND_DATA_CONTRACT.md](FORECAST_CENTRE_UI_AND_DATA_CONTRACT.md) for the exact fields already returned by the station directory and a **proposed, not approved** telemetry response shape.

## Mobile packaging gate

The repository tree currently contains no `android/` or `ios/` native platform projects. The current workflow validates Flutter analysis/tests and the web build; it does not produce an Android APK/AAB or an iOS archive. Native scaffolding, approved reverse-domain application identifier, signing/provisioning and platform builds are required before calling the Flutter app a distributable standalone mobile release. No identifier, signing certificate or secret was invented or added in this round.

## Acceptance principles

1. Screen completeness is not claimed as service completeness.
2. No live-looking placeholder values, fake station readings, invented station coordinates or fabricated audit events.
3. Null/missing values remain distinct from numeric zero.
4. UTC issue/observation/receipt timestamps remain distinct.
5. Raw observations and evidence remain immutable; derived/corrected values retain lineage.
6. Role checks are enforced by the server, not merely hidden UI controls.
7. No database/schema/migration/secret changes without explicit approval.
8. Flutter UI acceptance precedes Angular UI implementation.
