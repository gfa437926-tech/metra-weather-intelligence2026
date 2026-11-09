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


## Migration-source recovery pass — 2026-11-10

- Rechecked the current `main` branch and the available searchable commit history for the two role-permission migration names and the `metra_role_permissions` symbol. No exact source file or matching source-recovery commit was found in the searchable results.
- The only visible branch returned by the repository branch search was `main`. This does not prove that no unreachable Git object, local developer copy, deployment artifact, or external backup exists; it means this repository-only pass did not recover a verifiable original.
- The six outstanding candidates remain unchanged. In particular, do not infer a table definition from Edge Function query usage or from seed references, and do not create a replacement migration pretending to be the historical source.
- The migration inventory was 51 files at the prior 2026-11-10 inventory checkpoint; the new scheduled-revocation forward migration adds one source file after that checkpoint. This is a repository file count, not a live migration-ledger count.
- The CI run `42704651926` completed with its `analyze-test-build` job and all reported steps successful. Its returned job summary did not expose the tested `head_sha`; the later audit-document commit `e358850c5cbb50e9128316e4a25afd5dd53d1f39` is therefore not claimed to have been covered by that run.
- No database was queried or modified, no SQL was applied, and no legacy repository or database was accessed in this pass.

### Recovery decision

Keep the migration-chain blocker open until an exact trusted source is recovered. If that cannot be recovered, handle a future schema baseline as a separately named, explicitly reconstructed migration set after approval and catalog-level comparison on a disposable NEW METRA staging database. Do not silently substitute reconstructed SQL into historical migration versions.


## Role authorization deep-dive — 2026-11-10

### Evidence reviewed
- Read the current station-directory, observations, registration-approvals, and station-review Edge Function sources and the station-directory permission helper.
- Read the source migrations for observation review, station-catalogue review (including its later null-validation hardening), station-bound registration decisions, station assignment workflow, and station assignment revocation.
- This is a source-only review of checked-in files and commit diffs. No hosted database, migration ledger, deployed Edge Function, or secret store was queried.

### Permission provenance and effective permissions
- station-directory derives the actor from auth.getUser(token) and requires an active metra_account_states row.
- Role-derived permissions originate from approved, time-valid authority_memberships, are restricted to active metra_role_catalogue roles, and are then read from metra_role_permissions.
- Individual permissions originate from approved permission_grants for the authenticated user, with valid_from <= now, valid_to IS NULL OR valid_to > now, and revoked_at IS NULL OR revoked_at > now.
- The endpoint unions role permissions and individual grants. This is additive, not an intersection: an individual grant can add a permission not present in the user's role. The database-side grant-creation and approval workflow must therefore enforce the grantor's authority ceiling; that invariant is not proven by the files reviewed in this pass.
- The two dependency-critical historical migrations that define/secure metra_role_permissions and seed its conservative allow-list remain absent from the checked-in migration chain. Consequently, the complete role-to-permission source of truth, constraints, RLS/ACL, and seed contents cannot yet be independently reconstructed or certified.

### Station isolation and read/write/review boundaries
- Observation entry is scoped to approved, active, non-demo station assignments. The Edge Function separately checks observation.create, observation.approve, and observation.return_for_correction for each station through metra_user_has_station_permission; submit and decision RPCs receive the authenticated actor ID and station ID, and the SQL decision function locks the observation by both observation ID and station ID.
- Observation history returned by the Edge Function is split into the user's own records and reviewable submitted records for stations where the user has review permission. Self-review is excluded from the review queue.
- Station-catalogue review requires the individual stations.catalogue.review grant in the Edge Function and again in the privileged SQL transaction. The transaction locks the target station and records an audit event.
- Station assignment workflow is explicitly limited to assigning observer or station_auditor; it checks the actor's users.station.manage permission for the target station, requires an active station and authority, and requires the target user to hold an approved, time-valid membership in that authority. Approval is station-bound, rejects self-approval/requester approval, and records an audit event. This is a useful hard ceiling on this station-manager workflow.
- The station directory endpoint, however, returns every non-demo station in the catalogue to a user with stations.read (or legacy alias station.read). That is a global catalogue-read permission, not station-scoped operational access. Confirm explicitly that all users assigned this permission are intended to see the full non-demo station directory; otherwise split global catalogue visibility from assigned-station visibility.
- Registration approval queue logic scopes station-stage requests to the reviewer's approved station assignments. System-stage review is global for holders of registrations.system.approve and uses a separate prior station-approval audit event as a workflow gate. This is consistent with a deliberately global system-review role, but its assignment must be restricted to the intended authority tier.

### SECURITY DEFINER, execution grants, and search_path
- Reviewed privileged SQL functions use SECURITY DEFINER with explicit fixed search paths, typically pg_catalog, public, private (or pg_catalog, public); reviewed table references are schema-qualified.
- Reviewed observation decision, station review, station-bound registration decision, and station assignment functions revoke execution from PUBLIC, anon, and authenticated, then grant execution to service_role. The private station-review implementation also revokes execution from service_role; only its public wrapper is executable by service_role.
- Edge Functions validate the bearer token with Supabase Auth and derive actor IDs from the verified user object before making service-role RPC calls. The service-role key is read server-side. This supports the current trust boundary, but it is not a live deployed-secret or deployed-ACL verification.
- A fixed search_path alone is not the complete SECURITY DEFINER sign-off. Still required: verify function owners, schema CREATE privileges, default privileges, exact EXECUTE ACLs after the full ordered migration chain, and that no untrusted role can create shadow objects in searched schemas. Those catalog-level checks cannot be performed from source files alone.

### Findings and unresolved authorization gates
1. HIGH-PRIORITY unresolved — grantor authority ceiling: role permissions and individual grants are combined additively. The reviewed source does not establish that a station manager, system administrator, or other grantor can only assign permissions at or below their own authority level. Locate and review the exact permission-grant/role-assignment write transactions before approving this workflow.
2. HIGH-PRIORITY unresolved — role permission schema provenance: the missing metra_role_permissions creation/allow-list migration and seed migration prevent certification of role permission integrity and default-deny behavior.
3. Policy confirmation required — global station directory: stations.read exposes the full non-demo catalogue; confirm this is intended for every role receiving it, distinct from station-bound operational data.
4. Production hardening required — CORS: the reviewed Edge Function entry points still return Access-Control-Allow-Origin: *. Replace with exact approved application origins before production; do not guess the origin list.
5. No end-to-end proof yet: no negative tests were run against staging for cross-station reads/writes, forged actor IDs, self-approval, expired/future-revoked grants, inactive roles, or grantor privilege escalation. CI unit tests do not substitute for these database-backed cases.

### Required acceptance tests before approval
- User assigned to station A cannot list, read, create, edit, submit, review, approve, return, or manage assignments for station B unless a separately approved global permission explicitly authorizes that action.
- A grantor cannot grant a permission, role, authority membership, or station assignment exceeding their own delegated scope; test both direct-grant and role-derived paths.
- A station manager cannot assign management, reviewer, system, or director roles through the station assignment RPC; cannot approve their own request; and cannot approve a request they submitted.
- A role deactivation, membership expiry, grant expiry, and scheduled revocation each remove effective access at the correct instant.
- PUBLIC, anon, and authenticated cannot execute privileged RPCs directly; only the intended server role can execute them.
- Verify function owner, proconfig/search_path, schema ACL/CREATE grants, and function ACLs from the final schema on the NEW METRA staging project after source recovery and approval.

No SQL was applied, no hosted database was queried, and no legacy repository or database was accessed or modified during this review.


## Permission-grant and authority-ceiling follow-up — 2026-11-10

### Grant creation and approval path inventory
- The restored identity foundation migration 20261102165436_add_identity_membership_and_station_assignment.sql creates permission_grants with target user, permission code, approval state, validity window, scheduled revocation, requester, approver, review timestamp, and reason.
- The companion migration 20261102165505_lock_identity_tables_and_index_foreign_keys.sql enables deny policies for anon and authenticated, and the identity foundation grants table-level ALL to service_role.
- The least-privilege runtime migration 20261103000332_provision_least_privilege_api_runtime_role.sql grants metra_api_runtime SELECT (not INSERT/UPDATE/DELETE) on permission_grants and adds a read policy. In the reviewed migration set, no permission-grant write/approval RPC or grantor-ceiling predicate was identified.
- Checked-in Edge Functions reviewed in this pass include station-directory, observations, registration-approvals, and station-review. Their relevant permission-grant usage is read/evaluation; registration-approvals checks the actor's registrations.station.approve or registrations.system.approve grant. Guessed endpoints such as permission-grants, permission-management, user-management, and identity-admin were checked and do not exist at those paths.
- Therefore, no complete permission-grant creation/approval route was located in the reviewed checked-in Edge Functions or migration sources. This is a repository-scope finding, not proof that no external ASP.NET service or unindexed artifact exists. The ASP.NET API source and deployment artifacts still need a separate inventory if they are part of this repository/deployment.
- Because no grant-write transaction was located, no evidence currently proves that the grantor can only assign permissions within their own delegated ceiling. Direct table writes must remain unavailable to the runtime role until a reviewed transactional API is implemented. Do not grant broad write privileges as a workaround.

### Role and authority findings
- metra_role_catalogue is created by the registration workflow migration with is_requestable and is_active; the registration trigger and final system-stage decision check both flags before activating a requested role.
- The two-stage registration decision uses explicit stage permissions, station assignment at the station stage, a different system reviewer, an approved active station/authority, and an active requestable role. It creates the station assignment atomically on final approval.
- The station assignment RPC remains hard-limited to observer and station_auditor. It does not implement authority-level management-role assignment.
- The source migration that creates metra_role_permissions, its integrity constraints/policies, and the conservative role-permission allow-list seed remains absent. The original source was not recovered in this pass. No role-permission table or seed was fabricated.
- The six source-recovery candidates remain open; in particular 20261103162707_enforce_explicit_role_permission_allowlist.sql and 20261103162738_seed_conservative_observation_role_permissions.sql.

### Security consequences and required controls
1. Keep permission-grant writes closed to browser roles and to metra_api_runtime until an authenticated server-side transactional workflow is reviewed.
2. The eventual grant transaction must validate the grantor's active account, approved and time-valid authority membership, exact resource/authority scope, and a permission-delegation ceiling. It must reject self-grant, self-approval, grantor/approver conflicts, unknown/inactive permission codes, and any grant above the actor's own explicitly delegable permissions.
3. Role assignment must use an explicit role hierarchy/delegation matrix; do not infer authority from display labels, account activation, or a client-supplied role code.
4. Direct permission grants and role-derived permissions must share the same canonical permission registry and must not allow arbitrary free-text permission codes to become effective.
5. Preserve a separation-of-duties rule: requester, approver, and target must be compared in the database transaction, not trusted from the client.

### Negative test implementation status
- Added a separate staging acceptance matrix at docs/ROLE_AUTHORIZATION_NEGATIVE_TEST_PLAN.md.
- These are prepared test cases, not executed test results. They require a disposable NEW METRA staging project, synthetic identities, and explicit staging authorization.
- No SQL, migration, or live grant was applied; no legacy repository or database was accessed.



### Authorization composition inconsistency — confirmed from source
- The restored source migration 20261103025556_003_add_station_permission_check.sql defines metra_user_has_station_permission as a conjunction: an active account, approved/time-valid authority membership, approved/time-valid station assignment, active role, matching row in metra_role_permissions, and a matching approved/time-valid individual permission_grants row are all required.
- Therefore, for station-scoped operations, a role permission alone is insufficient and an individual grant alone is also insufficient. Both are required.
- In contrast, station-directory computes effective permissions as the UNION of role-derived permissions and individual grants. A direct grant alone can therefore satisfy the station-directory read check, even though it cannot satisfy metra_user_has_station_permission for station-scoped observation/assignment checks.
- registration-approvals currently authorizes station/system review from individual permission_grants and applies separate station-assignment and workflow checks; it does not use the same role-permission conjunction as metra_user_has_station_permission.
- This is a material policy inconsistency, not automatically a vulnerability: each endpoint has different semantics. The canonical intended model must be decided and documented before role seeds or direct grants are approved. The negative-test plan now explicitly tests direct-grant-only and role-only cases against each endpoint.
- The station permission helper is SECURITY DEFINER, fixed search_path pg_catalog, public, schema-qualified table references, and explicit EXECUTE revoke from PUBLIC/anon/authenticated with EXECUTE granted to service_role. Its exact runtime ACL and owner still require catalog verification in approved staging.
