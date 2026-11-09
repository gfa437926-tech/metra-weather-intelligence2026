# METRA Weather Intelligence — implementation audit

**Audit date:** 2026-11-10  
**Repository:** `gfa437926-tech/metra-weather-intelligence2026`  
**Branch:** `main`  
**Audited source head:** `37f8689e521be13a457d513037ae30dd530fe52a`  
**Audit report commit:** `61ff6c4972a7fb4122992d24f4ebc56838a28d5f`  
**Latest verified CI run:** `42702476174` — Flutter CI — success  
**Scope:** read-only source and CI review; no hosted database operations.

## Verified implementation

- Flutter application uses Arabic RTL layout and Material 3.
- Authentication uses Supabase email/password when URL and publishable key are supplied at build time.
- Authenticated users pass through a registration/account-state gate; pending or inactive accounts are not admitted to the app shell.
- Station directory is loaded through the authenticated `station-directory` Edge Function; protected tables are not queried directly from Flutter.
- Station map uses OpenStreetMap tiles, valid stored coordinates, and coordinate clustering so multiple station records at identical coordinates remain discoverable.
- Station list distinguishes station type, catalogue approval, operational verification, and missing coordinates.
- Observation workflow supports draft/submission and station-scoped review/approval/return through the `observations` Edge Function.
- Station catalogue review is routed through the `station-review` Edge Function.
- Damascus current conditions and hourly forecast are fetched from Open-Meteo; the app documentation correctly distinguishes forecast-provider values from METRA station telemetry.
- Flutter tests cover weather parsing, station-domain parsing, station clustering/status, access-context parsing, registration eligibility, and core widgets.

## CI evidence

Run `41774118934` on source head `37f8689e521be13a457d513037ae30dd530fe52a` completed successfully.

The newer run `42702476174`, triggered by audit report commit `61ff6c4972a7fb4122992d24f4ebc56838a28d5f`, also completed successfully. All 20 workflow steps passed, including Deno type checks, registration/approval/permission/payload/catalogue tests, Flutter dependency resolution, analysis, tests, web release build, and artifact upload.

A successful CI run is source/build evidence only. It does not establish a live authenticated user journey, live database correctness, Android/iOS device validation, store deployment, or production readiness.

## Gaps and release blockers

1. **Official alerts and operational weather layers:** no verified official alert provider, radar, precipitation, temperature, or wind layer is connected. The UI must continue to disclose this rather than display fabricated alerts.
2. **Station approval and activation:** the last recorded operational snapshot (2026-11-04) showed 62 non-demo stations pending catalogue approval and operational verification. This is historical evidence, not a current count. Reconfirm through an approved read-only review before activation; do not bulk-approve.
3. **Real identity journey:** the 2026-11-04 snapshot recorded zero Auth users and zero registration requests. This is historical evidence; real account onboarding, reviewer separation, and permission checks still need controlled end-to-end acceptance.
4. **Historical archive reconciliation:** 1,251 archive envelopes had no `station_id` in the 2026-11-04 snapshot; names alone are not sufficient to map them. Keep unresolved rows unlinked until source-backed review.
5. **Migration reproducibility:** the repository currently contains 51 migration SQL files. I compared these filenames against the 33 missing applied versions explicitly listed in `docs/MIGRATION_SOURCE_RECONCILIATION_2026-11-04.md`: 27 of those 33 now have same-name source files, while six remain absent from the current tree: `20261102172226_create_provenance_preserving_observation_store.sql`, `20261103122944_grant_runtime_station_coordinate_read.sql`, `20261103123005_link_membership_and_assignment_roles.sql`, `20261103123127_index_role_catalogue_foreign_keys.sql`, `20261103162707_enforce_explicit_role_permission_allowlist.sql`, and `20261103162738_seed_conservative_observation_role_permissions.sql`. This is a repository-to-historical-report comparison, not a fresh read of the hosted migration ledger; therefore it establishes six outstanding source-recovery candidates against the last recorded inventory, not current live-ledger truth. Several restored files are explicitly reconstructed rather than proven byte-for-byte originals, so their SQL semantics still need verification. Do not reset, replay, or modify any migration or database to close this gap.
6. **Mobile release validation:** CI builds the web target. Android/iOS builds, device-specific auth, map, accessibility, offline/network recovery, and store packaging still require separate device/build validation.
7. **Design parity:** this source audit does not prove pixel-level parity with the original METRA screens. Complete a screen-by-screen comparison against the approved reference screenshots before calling the UI finished.
8. **Security acceptance:** verify production origin policy, secrets configuration, edge-function abuse/rate controls, session lifecycle, device storage policy, and audit visibility in an approved staging environment.

## Migration source inventory review (2026-11-10)

- Read the `main` branch `supabase/migrations` directory through GitHub's repository contents API.
- Counted 51 SQL migration files; all filenames begin with a unique 14-digit version prefix. Two filenames also contain a second 14-digit token in the descriptive portion, so those embedded values must not be mistaken for additional migration versions.
- Read the Git commit history for that directory: 36 commits were returned, including commits explicitly restoring batches of applied station, identity, registration, observation, and audit migration sources.
- This is repository-only evidence. The hosted migration ledger was not queried in this continuation, so no claim is made that all 57 historically applied versions now match the source tree. Exact SQL equivalence for reconstructed files, including any historical filename/version rename, remains unverified.
- No migration was executed, edited, deleted, replayed, or applied.

## Protected boundaries

- No SQL was applied to the hosted Supabase project during this audit.
- No legacy database or legacy repository was accessed or modified.
- No station was approved, activated, reassigned, or geocoded.
- No user, administrator, reviewer, permission grant, or synthetic observation was created.
- No production deployment was performed.

## Next execution order

1. Recover and reconcile the migration source history without touching the hosted database.
2. Build an approved staging acceptance plan for authentication, registration, station review, observation entry/review, and audit trails.
3. Complete the screenshot-based UI parity review and implement only evidenced differences.
4. Validate Android and iOS builds on test devices.
5. Integrate official alerts and additional map layers only after obtaining provider approval and credentials.
6. Reassess production readiness after all preceding gates pass.


## Follow-up review — CI and reconstructed SQL (2026-11-10)

### CI confirmation
- Workflow runs `42703391423` and `42703421107` were rechecked after the previous audit note; both completed successfully.
- Both runs passed Deno type checks, registration approval and permission/payload tests, Flutter dependency resolution, analysis, tests, web release build, and artifact upload.
- This remains CI evidence only; it does not replace authenticated staging acceptance or Android/iOS device testing.

### Reconstructed SQL review
- The current tree contains 51 migration SQL files.
- The six source-recovery candidates listed above are still absent from `main`; path-specific Git commit history returned no commits for any of the six exact filenames. Do not fabricate replacement historical migrations.
- Reviewed the reconstructed station-catalogue review function, the station-bound registration decision wrapper, and the associated role allow-list entries.
- Positive controls observed in source: fixed `search_path` on privileged functions; execution of server-side decision RPCs restricted to `service_role`; explicit revokes from `PUBLIC`, `anon`, and `authenticated`; active-account and time-valid individual permission checks; station assignment checks in the underlying registration transaction; distinct station/system reviewers; and audit-event insertion in the registration transaction.
- The initial reconstructed station-review function version uses a nullable comparison for the expected state; the later migration `20261104024652_harden_station_catalogue_review_null_validation.sql` replaces this with `IS DISTINCT FROM` and explicit null validation. Review the ordered migration chain, not the earlier file in isolation.
- The Edge Functions reviewed derive actor IDs from a verified Supabase Auth JWT before calling service-role RPCs. The service-role key is read from server environment and is not returned to Flutter. This is source inspection, not a live deployed-secret audit.
- Remaining review caveats: reconstructed files are not proven byte-for-byte originals; the station-review RPC accepts an `occurred_at` parameter but records the database clock instead (appropriate for authoritative audit time, but the unused parameter should be documented or removed only through an approved forward migration); wildcard CORS origins remain in the reviewed Edge Functions and should be narrowed to approved application origins before production.
- No SQL was applied, no migration was replayed, and no hosted project or legacy database was queried or modified in this follow-up.


### Native platform and screenshot inventory
- The repository tree currently contains only the Flutter `web/` platform scaffold; no `android/` or `ios/` platform directories are present. Therefore native Android/iOS builds cannot yet be treated as available or validated.
- No original reference screenshots or image assets are present in the repository tree. Pixel-level parity cannot be assessed from repository contents alone; approved reference screenshots must be supplied or located in the project artifacts.
- The committed CI workflow builds only `flutter build web --release`; it does not run Android or iOS builds.


## Full migration and Edge Function follow-up (2026-11-10)

### Scope inspected
- Inspected all 51 SQL migration files present in `supabase/migrations` and the 15 TypeScript files under `supabase/functions` (entry points, validation, permission helpers, and tests).
- This is a source review of the current `main` tree only. No database connection was opened and no SQL was applied.

### Confirmed defect: scheduled permission revocation was inconsistent
- The registration decision transaction already treats a future `permission_grants.revoked_at` as effective until that timestamp.
- The shared `metra_user_has_station_permission` SQL predicate instead required `revoked_at IS NULL`, which made a future-dated revocation take effect immediately for station operations, including observation create/review and assignment management.
- The station-catalogue review transaction had the same immediate-revocation predicate.
- The station-directory, registration-approvals, and station-review Edge Functions also filtered with `revoked_at IS NULL`, disagreeing with the documented scheduled-revocation semantics.
- Source fixes committed:
  - `supabase/migrations/20261110120000_honor_scheduled_permission_revocation.sql` updates the shared station permission predicate and station-review transaction, with exact-occurrence guards that abort rather than silently altering an unexpected function definition.
  - `supabase/functions/station-directory/index.ts`
  - `supabase/functions/registration-approvals/index.ts`
  - `supabase/functions/station-review/index.ts`
- The corrected rule is: a grant with `revoked_at IS NULL` or `revoked_at > now` remains valid; it ceases to be valid at or after its revocation timestamp.
- This is a source change only. The new migration has not been applied to any hosted database.

### Migration source-chain blocker
- The current tree references `public.metra_role_permissions` from station authorization and role-seed migrations. The historically reported source migration `20261103162707_enforce_explicit_role_permission_allowlist.sql` remains absent, as does the following seed migration `20261103162738_seed_conservative_observation_role_permissions.sql`.
- The missing allow-list migration is a dependency-critical source-recovery gap: the checked-in migration chain does not provide a verifiable creation/definition of that table and its constraints/policies in the current repository. Do not fabricate the historical source. Recover it from a trusted backup or original artifact before staging schema reconstruction.
- The other four absent historical files also remain unrecovered. No substitutes were generated.

### Remaining security/release gates
- Wildcard CORS origins remain in the reviewed Edge Function entry points. Restrict them to the approved production/staging application origins once those exact origins are known; do not guess them.
- Reconstructed SQL files remain unverified against byte-identical applied originals.
- No deployed-secret inspection, authenticated staging test, or live permission test was performed.
- CI must pass on the latest source commits before this review can be considered code-verified.


## CI follow-up — 2026-11-10

- Rechecked workflow run `42704651926`: the single `analyze-test-build` job completed successfully and all 24 reported steps passed.
- Passing steps include Deno type checks for Edge Functions, registration/approval/permission/payload/catalogue tests, Flutter dependency resolution, static analysis, Flutter tests, web release build, and artifact upload.
- This confirms that run's CI pipeline is green. The GitHub Actions connector did not expose the run's `head_sha` in the returned job summary, so do not use this run alone to claim verification of a later commit unless its source SHA is independently matched.
- No staging deployment or hosted database operation was performed. The migration source-chain blockers, wildcard CORS configuration, native Android/iOS validation, and authenticated staging acceptance remain open.
