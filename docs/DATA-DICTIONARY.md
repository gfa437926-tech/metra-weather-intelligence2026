# METRA Weather Intelligence — Data Dictionary

**Status:** Draft for review; not a production schema contract  
**Related ERD:** [DATABASE-ERD.md](DATABASE-ERD.md)  
**Design mode:** Greenfield only; no legacy schema/data import.  
**Type notation:** PostgreSQL types are proposed physical types unless marked TBD. All IDs are UUID. All timestamps are `timestamptz`. All constraints below are logical proposals; SQL is deferred until approval.

## 1. Conventions

- `PK`: primary key; `FK`: foreign key; `UQ`: unique; `NN`: NOT NULL.
- `created_at` / `updated_at` are UTC instants maintained by the trusted server/database. Append-only records omit `updated_at`.
- `valid_from` inclusive and `valid_to` exclusive; NULL `valid_to` means open-ended.
- Status values shown are provisional workflow labels observed in current application code, not an approved global enum.
- Scientific parameters, valid ranges, precision, units, formulas and QC thresholds are TBD until approved by the meteorological domain owner.
- “Synthetic” means explicitly marked test fixture data; it must never be confused with operational observations.

## 2. IAM schema

### 2.1 `iam.user_profiles` — MVP

**Purpose:** App profile linked 1:1 to the immutable identity-provider subject. Passwords, access tokens and secrets are never stored here.

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| auth_subject | uuid | No | — | UQ; immutable external Auth user UUID |
| display_name | text | Yes | — | Display-only; not an authorization input |
| preferred_language | varchar(16) | No | 'ar' | Locale code; allowed values TBD |
| account_state | varchar(32) | No | 'pending' | CHECK from approved account lifecycle (e.g. pending, active, blocked, rejected) |
| state_reason | text | Yes | — | Administrative explanation; access restricted |
| created_at | timestamptz | No | now() | Creation instant |
| updated_at | timestamptz | No | now() | Server-maintained |

**Indexes:** unique(auth_subject); index(account_state).  
**Relationships:** 1:N memberships, role_assignments, permission_grants as subject/grantor, station_reviews, observation_submissions, observation_revisions, observation_review_decisions, audit events.  
**Open issue:** profile display name source and retention.

### 2.2 `iam.organizations` — MVP

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| code | varchar(64) | No | — | UQ; stable organization code |
| name_ar | text | No | — | Arabic display name |
| name_en | text | Yes | — | English display name |
| organization_state | varchar(24) | No | 'active' | CHECK; active/suspended/closed pending approval |
| created_at | timestamptz | No | now() | Creation instant |
| updated_at | timestamptz | No | now() | Server-maintained |

**Relationships:** 1:N organization_units, memberships, stations, and organization-scoped role assignments/grants.  
**Open issue:** official organization taxonomy and owner are TBD.

### 2.3 `iam.organization_units` — MVP (optional hierarchy)

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| organization_id | uuid | No | — | FK → organizations.id |
| parent_unit_id | uuid | Yes | — | Self-FK; parent must belong to same organization |
| code | varchar(64) | No | — | UQ within organization |
| name_ar | text | No | — | Arabic label |
| name_en | text | Yes | — | English label |
| created_at | timestamptz | No | now() | Creation instant |
| updated_at | timestamptz | No | now() | Server-maintained |

**Constraints:** unique(organization_id, code); no self-parent; prevent hierarchy cycles in trusted transaction.  
**Relationships:** N:1 organization; 1:N child units, memberships and stations.

### 2.4 `iam.memberships` — MVP

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| user_id | uuid | No | — | FK → user_profiles.id |
| organization_id | uuid | No | — | FK → organizations.id |
| organization_unit_id | uuid | Yes | — | FK → organization_units.id; same organization |
| membership_state | varchar(24) | No | 'pending' | CHECK; pending/active/suspended/rejected/ended TBD |
| requested_at | timestamptz | No | now() | Request time |
| approved_at | timestamptz | Yes | — | Approval time |
| approved_by | uuid | Yes | — | FK → user_profiles.id |
| valid_from | timestamptz | No | now() | Inclusive |
| valid_to | timestamptz | Yes | — | Exclusive; must exceed valid_from |
| created_at | timestamptz | No | now() | Creation instant |
| updated_at | timestamptz | No | now() | Server-maintained |

**Indexes:** (user_id, membership_state), (organization_id, membership_state), FK indexes.  
**Constraints:** valid_from < valid_to; unit belongs to organization; approval actor required when state=active.  
**Open issue:** whether repeated membership creates a new row or reactivates a historical row.

### 2.5 `iam.roles` — MVP

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| code | varchar(80) | No | — | UQ immutable role code |
| name_ar | text | No | — | Arabic label |
| name_en | text | Yes | — | English label |
| is_requestable | boolean | No | false | Whether user may request this role |
| is_system_role | boolean | No | false | Reserved/system-controlled role |
| is_active | boolean | No | true | Registry lifecycle |
| created_at | timestamptz | No | now() | Creation instant |

**Constraints:** code format TBD; inactive roles cannot receive new assignments. Exact role set requires approval.

### 2.6 `iam.permissions` — MVP

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| code | varchar(120) | No | — | UQ immutable permission code |
| description | text | No | — | Precise action/resource semantics |
| is_sensitive | boolean | No | false | Requires privileged review |
| is_active | boolean | No | true | Registry lifecycle |
| created_at | timestamptz | No | now() | Creation instant |

**Constraints:** permission code is namespaced (e.g. resource.action); exact catalogue TBD.

### 2.7 `iam.role_permissions` — MVP

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| role_id | uuid | No | — | PK part; FK → roles.id |
| permission_id | uuid | No | — | PK part; FK → permissions.id |
| created_at | timestamptz | No | now() | Mapping creation |

**Constraints:** PK(role_id, permission_id); only active registry entries can be assigned by administrative transaction.

### 2.8 `iam.role_assignments` — MVP

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| user_id | uuid | No | — | FK → user_profiles.id |
| membership_id | uuid | Yes | — | FK → memberships.id; required for organization/station scopes if policy says so |
| role_id | uuid | No | — | FK → roles.id |
| scope_type | varchar(16) | No | — | CHECK: global / organization / station |
| organization_id | uuid | Conditional | — | FK → organizations.id; required only for organization scope |
| station_id | uuid | Conditional | — | FK → catalog.stations.id; required only for station scope |
| assigned_by | uuid | No | — | FK → user_profiles.id |
| valid_from | timestamptz | No | now() | Inclusive |
| valid_to | timestamptz | Yes | — | Exclusive |
| revoked_at | timestamptz | Yes | — | Revocation instant |
| revocation_reason | text | Yes | — | Required when revoked |
| created_at | timestamptz | No | now() | Creation instant |

**Constraints:** exactly one scope target consistent with scope_type; valid_from < valid_to; revocation fields paired; actor cannot be client asserted.  
**Indexes:** (user_id, valid_from, valid_to), (organization_id), (station_id), (role_id).  
**Open issue:** whether assignments attach to membership or can be independent at global scope.

### 2.9 `iam.permission_grants` — MVP, privileged

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| subject_user_id | uuid | No | — | FK → user_profiles.id |
| permission_id | uuid | No | — | FK → permissions.id |
| scope_type | varchar(16) | No | — | CHECK: global / organization / station |
| organization_id | uuid | Conditional | — | FK → organizations.id |
| station_id | uuid | Conditional | — | FK → catalog.stations.id |
| granted_by | uuid | No | — | FK → user_profiles.id |
| valid_from | timestamptz | No | now() | Inclusive |
| valid_to | timestamptz | Yes | — | Exclusive |
| revoked_at | timestamptz | Yes | — | Revocation instant |
| reason | text | No | — | Audit rationale |
| created_at | timestamptz | No | now() | Creation instant |

**Constraints:** exactly one scope target; valid interval; subject != grantor by default; revocation cannot precede grant.  
**Indexes:** subject + permission + scope; expiry/revocation lookup.  
**Open issue:** delegation ceiling and approval workflow.

## 3. Catalog schema

### 3.1 `catalog.station_types` — MVP

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| code | varchar(40) | No | — | UQ stable code |
| name_ar | text | No | — | Arabic label |
| name_en | text | Yes | — | English label |
| is_active | boolean | No | true | Registry lifecycle |

**Open issue:** exact type catalogue (classic/automatic are visible in UI; do not assume exhaustive).

### 3.2 `catalog.stations` — MVP

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| organization_id | uuid | No | — | FK → iam.organizations.id; owner |
| operating_unit_id | uuid | Yes | — | FK → iam.organization_units.id; same organization |
| station_type_id | uuid | Yes | — | FK → station_types.id; nullable only until classified |
| local_station_code | varchar(80) | No | — | Authority-scoped unique code |
| name_ar | text | No | — | Arabic name |
| name_en | text | Yes | — | English name |
| approval_status | varchar(24) | No | 'pending' | CHECK: pending/approved/rejected/changes_requested |
| operational_status | varchar(24) | No | 'unverified' | CHECK: unverified/active/inactive/suspended/decommissioned |
| timezone_name | varchar(64) | Yes | — | IANA zone; TBD source/requirement |
| created_at | timestamptz | No | now() | Creation instant |
| updated_at | timestamptz | No | now() | Server-maintained |
| archived_at | timestamptz | Yes | — | Archive only; not hard delete |

**Constraints:** unique(organization_id, local_station_code); organization unit belongs to organization; approved/active are separate.  
**Indexes:** (organization_id, approval_status), (operational_status), FK indexes.  
**Relationships:** 1:N identifiers, locations, reviews, observation submissions; 1:N station-scoped role assignments/grants.  
**Open issue:** code reuse policy after decommissioning; whether station timezone is mandatory.

### 3.3 `catalog.station_identifiers` — MVP

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| station_id | uuid | No | — | FK → stations.id |
| namespace | varchar(64) | No | — | Identifier issuing namespace |
| identifier_value | varchar(128) | No | — | Original identifier |
| normalized_value | varchar(128) | No | — | Normalized for uniqueness |
| source_name | text | Yes | — | Registry/provider label |
| valid_from | timestamptz | No | now() | Inclusive |
| valid_to | timestamptz | Yes | — | Exclusive |
| created_at | timestamptz | No | now() | Creation instant |

**Constraints:** positive validity interval; uniqueness across namespace/value and overlapping effective intervals according to namespace contract.  
**Open issue:** approved namespaces and normalization rules.

### 3.4 `catalog.station_locations` — MVP

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| station_id | uuid | No | — | FK → stations.id |
| latitude | numeric(9,6) | No | — | CHECK -90..90 |
| longitude | numeric(9,6) | No | — | CHECK -180..180 |
| elevation_m | numeric(8,2) | Yes | — | Unit fixed to metres; source required if supplied |
| coordinate_source | varchar(80) | No | — | Source registry/code; controlled values TBD |
| source_reference | text | Yes | — | Source record/reference |
| verification_state | varchar(24) | No | 'unverified' | CHECK: unverified/pending/verified/rejected |
| verified_by | uuid | Yes | — | FK → iam.user_profiles.id |
| verified_at | timestamptz | Yes | — | Required iff verification_state=verified |
| valid_from | timestamptz | No | now() | Inclusive |
| valid_to | timestamptz | Yes | — | Exclusive |
| created_at | timestamptz | No | now() | Creation instant |

**Constraints:** valid_from < valid_to; verified actor/time pairing; no overlapping active location periods per station; at most one current verified location per station.  
**Indexes:** station_id + valid_from desc; optional PostGIS point index only if extension and spatial use approved.  
**Open issue:** coordinate reference system is WGS84 (EPSG:4326) proposal; source accuracy metadata and elevation provenance require approval.

### 3.5 `catalog.station_reviews` — MVP, append-only

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| station_id | uuid | No | — | FK → stations.id |
| reviewer_user_id | uuid | No | — | FK → iam.user_profiles.id |
| decision | varchar(24) | No | — | CHECK approved/rejected/changes_requested |
| reason | text | No | — | Non-empty; current UI requires at least 5 chars; final policy TBD |
| prior_approval_status | varchar(24) | No | — | Snapshot before decision |
| resulting_approval_status | varchar(24) | No | — | Snapshot after decision |
| decided_at | timestamptz | No | now() | Decision instant |
| request_id | uuid | Yes | — | Correlation/idempotency link; exact API contract TBD |

**Constraints:** append-only; no UPDATE/DELETE to ordinary roles; decision and resulting state consistent; concurrency uses expected-state check.  
**Indexes:** (station_id, decided_at desc), (reviewer_user_id, decided_at desc).

## 4. Reference and observation schemas

### 4.1 `ref.units` — MVP foundation

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| code | varchar(48) | No | — | UQ stable unit code |
| symbol | varchar(32) | No | — | Display symbol |
| quantity_kind | varchar(64) | No | — | E.g. temperature, pressure; controlled vocabulary TBD |
| is_canonical | boolean | No | false | Canonical unit for quantity kind |
| is_active | boolean | No | true | Registry lifecycle |

**Open issue:** unit registry, conversion factors/algorithms, affine conversions, precision and rounding policy must be approved; no conversion logic is implied by this table.

### 4.2 `ref.meteorological_parameters` — MVP foundation

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| code | varchar(80) | No | — | UQ stable parameter code |
| name_ar | text | No | — | Arabic display name |
| name_en | text | Yes | — | English display name |
| quantity_kind | varchar(64) | No | — | Controlled quantity category |
| value_kind | varchar(16) | No | — | CHECK numeric/text/boolean/code; final set TBD |
| canonical_unit_id | uuid | Yes | — | FK → units.id; required for dimensional numeric parameters |
| precision_scale | smallint | Yes | — | TBD until scientific contract; >=0 if defined |
| valid_min | numeric | Yes | — | TBD; only populate from approved specification |
| valid_max | numeric | Yes | — | TBD; only populate from approved specification |
| effective_from | timestamptz | No | now() | Definition validity start |
| effective_to | timestamptz | Yes | — | Definition validity end |
| definition_source | text | Yes | — | Approved source/specification reference |
| definition_version | varchar(80) | Yes | — | Source version |
| is_active | boolean | No | true | Registry lifecycle |

**Constraints:** valid_min <= valid_max when both exist; precision_scale >= 0; effective_from < effective_to; unit quantity_kind compatible.  
**Critical gate:** no parameter rows or scientific limits are seeded until domain-owner approval.

### 4.3 `observations.observation_types` — MVP

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| code | varchar(40) | No | — | UQ; candidate labels visible in UI include daily and phenomenon; complete list TBD |
| name_ar | text | No | — | Arabic label |
| name_en | text | Yes | — | English label |
| requires_measurement | boolean | No | true | Form-level rule; exact semantics TBD |
| is_active | boolean | No | true | Registry lifecycle |

**Open issue:** cadence, scheduled local observation times and form-specific required fields are not yet defined.

### 4.4 `observations.submissions` — MVP

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| station_id | uuid | No | — | FK → catalog.stations.id |
| author_user_id | uuid | No | — | FK → iam.user_profiles.id; derived from verified identity |
| observation_type_id | uuid | No | — | FK → observation_types.id |
| status | varchar(24) | No | 'draft' | CHECK draft/submitted/approved/returned/rejected |
| observed_at | timestamptz | No | — | Actual observation instant, not insertion time |
| submitted_at | timestamptz | Yes | — | First/last submission semantics TBD |
| idempotency_key | varchar(160) | No | — | Client-generated request key; unique per author |
| request_fingerprint | char(64) | No | — | Server-calculated hash of canonical request |
| source_kind | varchar(24) | No | 'manual' | CHECK manual/imported/sensor/system |
| source_reference | text | Yes | — | Provenance reference; no secret |
| note | text | Yes | — | General observation note |
| created_at | timestamptz | No | now() | Insertion instant |
| updated_at | timestamptz | No | now() | Server-maintained |
| created_revision_no | integer | No | 1 | Current accepted revision pointer/sequence; transactionally maintained |

**Constraints:** unique(author_user_id, idempotency_key); revision_no > 0; status transition only through guarded server transaction; station eligible and author assigned/authorized at submission time.  
**Indexes:** (station_id, observed_at desc), (author_user_id, created_at desc), (status, submitted_at), FK indexes.  
**Open issue:** retention, whether drafts may be deleted, and how station assignment is evaluated historically.

### 4.5 `observations.values` — MVP

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| submission_id | uuid | No | — | FK → submissions.id |
| parameter_id | uuid | No | — | FK → ref.meteorological_parameters.id |
| unit_id | uuid | Yes | — | FK → ref.units.id; required for dimensional numeric values |
| numeric_value | numeric | Conditional | — | Used only for numeric parameters |
| text_value | text | Conditional | — | Used only for text/code parameters |
| boolean_value | boolean | Conditional | — | Used only for boolean parameters |
| reported_value_text | text | Yes | — | Original submitted representation if normalization is performed |
| value_observed_at | timestamptz | Yes | — | NULL means inherit submission.observed_at; confirm policy |
| value_qualifier | varchar(32) | Yes | — | Missing/trace/estimated/etc. only after controlled vocabulary approval |
| created_at | timestamptz | No | now() | Creation instant |

**Constraints:** exactly one typed value column populated; populated type matches parameter.value_kind; parameter/unit quantity compatibility; no NaN/Infinity; one parameter per submission unless repeatable parameter contract explicitly allows multiple readings (then add sequence/level key).  
**Indexes:** (submission_id), (parameter_id), (parameter_id, value_observed_at).  
**Scientific gate:** units, ranges, precision, qualifiers and repeatability rules are TBD.

### 4.6 `observations.revisions` — MVP, append-only

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| submission_id | uuid | No | — | FK → submissions.id |
| revision_no | integer | No | — | Sequence starting at 1 |
| changed_by | uuid | No | — | FK → iam.user_profiles.id |
| change_reason | text | No | — | Required reason |
| snapshot | jsonb | No | — | Canonical typed snapshot of submission and values; schema versioned |
| snapshot_schema_version | varchar(32) | No | — | Version of snapshot contract |
| created_at | timestamptz | No | now() | Revision instant |

**Constraints:** unique(submission_id, revision_no); revision_no > 0; append-only; JSON schema validated by API/DB contract. Snapshot is history, not a substitute for normalized current values.

### 4.7 `observations.review_decisions` — MVP, append-only

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| submission_id | uuid | No | — | FK → submissions.id |
| reviewer_user_id | uuid | No | — | FK → iam.user_profiles.id |
| decision | varchar(32) | No | — | CHECK approve/return_for_correction/reject |
| note | text | Yes | — | Required for return/reject; exact minimum length TBD |
| expected_status | varchar(24) | No | — | Optimistic concurrency guard |
| resulting_status | varchar(24) | No | — | Resulting lifecycle state |
| decided_at | timestamptz | No | now() | Decision instant |
| request_id | uuid | Yes | — | Correlation/idempotency reference |

**Constraints:** append-only; reviewer != author when separation-of-duties applies; expected state must match current state; only authorized station-scoped reviewer may decide.  
**Indexes:** (submission_id, decided_at desc), (reviewer_user_id, decided_at desc).

## 5. Audit schema

### 5.1 `audit.events` — MVP, append-only

| Column | Type | Null | Default | Constraints / meaning |
|---|---|---:|---|---|
| id | uuid | No | generated | PK |
| occurred_at | timestamptz | No | now() | Database/server timestamp |
| actor_user_id | uuid | Yes | — | FK → iam.user_profiles.id; NULL for system |
| actor_kind | varchar(16) | No | 'user' | CHECK user/system/service |
| action_code | varchar(120) | No | — | Controlled event code |
| resource_schema | varchar(63) | No | — | Logical schema |
| resource_type | varchar(80) | No | — | Entity type |
| resource_id | uuid | Yes | — | Resource UUID when applicable |
| organization_id | uuid | Yes | — | Scope snapshot |
| station_id | uuid | Yes | — | Scope snapshot |
| correlation_id | uuid | Yes | — | Request/trace correlation |
| outcome | varchar(16) | No | — | CHECK success/denied/failure |
| details | jsonb | No | '{}' | Allow-listed non-secret metadata only |

**Constraints:** INSERT only for application roles; no UPDATE/DELETE; payload must exclude credentials, tokens, secrets and unnecessary personal data.  
**Indexes:** (occurred_at desc), (actor_user_id, occurred_at desc), (resource_type, resource_id, occurred_at desc), (correlation_id).

## 6. Future weather-provider schema (not MVP DDL)

These are logical entities only. Do not generate their migration until a provider contract and product requirements are approved.

### 6.1 `weather.providers`
Proposed columns: `id uuid PK`, `code varchar UQ`, `display_name text`, `provider_kind varchar`, `terms_reference text`, `is_active boolean`, `created_at timestamptz`. No credentials/secrets.

### 6.2 `weather.ingestion_runs`
Proposed columns: `id uuid PK`, `provider_id uuid FK`, `started_at timestamptz`, `finished_at timestamptz NULL`, `outcome varchar`, `correlation_id uuid`, `records_received integer`, `error_code varchar NULL`, `safe_error_summary text NULL`. Never store bearer tokens or secret payloads.

### 6.3 `weather.forecast_runs`
Proposed columns: `id uuid PK`, `provider_id uuid FK`, `ingestion_run_id uuid FK`, `provider_run_ref text NULL`, `issued_at timestamptz`, `model_name varchar NULL`, `model_version varchar NULL`, `payload_hash char(64) NULL`, `created_at timestamptz`.

### 6.4 `weather.forecast_points`
Proposed columns: `id uuid PK`, `forecast_run_id uuid FK`, `location_kind varchar`, `station_id uuid NULL FK`, `latitude numeric NULL`, `longitude numeric NULL`, `valid_at timestamptz`, `lead_duration_seconds integer NULL`. Exactly one of station_id or coordinate pair according to location_kind.

### 6.5 `weather.forecast_values`
Proposed columns: `id uuid PK`, `forecast_point_id uuid FK`, `parameter_id uuid FK`, `unit_id uuid NULL FK`, `numeric_value numeric NULL`, `text_value text NULL`, `provider_parameter_code varchar`. Typed-value and unit rules align with approved parameter definitions.

## 7. Explicitly deferred entities

| Domain | Candidate entities | Why deferred |
|---|---|---|
| alerts | warning_products, warning_versions, warning_areas, warning_station_links | Official source/API, lifecycle, geometry, severity taxonomy and legal attribution are not yet approved |
| climate | datasets, dataset_versions, analysis_jobs, analysis_results, quality_reports | Scientific methods, input lineage, reproducibility and validation specifications required |
| files | objects, attachment_links | Current workflow does not yet establish a required attachment feature; storage provider and retention policy needed |
| integration | provider_registry, integration_runs | Can be folded into weather.providers/ingestion_runs for MVP; avoid duplicate registries until integration scope is confirmed |

## 8. Cross-table FK and index plan

- Every FK receives an index unless a leading composite index already covers the FK access pattern.
- Use restrictive FK deletion for identity, station, observation, review and audit history. Hard-delete cascades are not permitted for approved operational records.
- Use unique indexes for immutable codes and idempotency keys.
- Use partial unique indexes for “current” rows only where the approved lifecycle defines current unambiguously.
- Use exclusion constraints for non-overlapping temporal location/identifier periods only after PostgreSQL extension/constraint strategy is validated on the target version.
- Avoid premature partitioning; measure data volume and query patterns first.

## 9. Data ownership, provenance and retention

| Data family | Authoritative writer | Provenance required | Retention |
|---|---|---|---|
| Identity profile | Auth + trusted .NET API | external subject, account lifecycle actor/time | TBD legal/privacy policy |
| Membership/access | trusted .NET API/admin workflow | requester, approver/grantor, validity and reason | TBD; privileged audit retention |
| Station catalogue | approved catalogue authority | source system/reference, reviewer, coordinate verification | Historical versions retained; duration TBD |
| Manual observations | assigned observer via .NET API | author, station, observed_at, submitted_at, revision and decisions | Scientific/archive policy TBD |
| Forecasts | provider ingestion service | provider, issue time, ingestion run, model/version, payload hash | Provider license and product policy TBD |
| Audit | database/server | actor, action, resource, outcome, correlation | Security/legal policy TBD |

## 10. Review checklist before DDL

- [ ] Confirm organization model and ownership.
- [ ] Confirm station catalogue source, identifiers, station classes, timezone and coordinate provenance.
- [ ] Approve roles, permissions, scope rules and reviewer separation.
- [ ] Approve account/membership states and onboarding/approval workflow.
- [ ] Approve observation forms, cadence and lifecycle transitions.
- [ ] Approve parameter catalogue, value kinds, units, ranges, precision, formulas and QC rules.
- [ ] Decide per-value observation timestamps and repeatable parameters.
- [ ] Approve audit content, retention, privacy and deletion policy.
- [ ] Confirm .NET-only trusted writer vs transitional Edge Functions.
- [ ] Approve exposed schemas, grants, RLS and service runtime role.
- [ ] Confirm PostgreSQL version, extensions and PostGIS need.
- [ ] Review every FK, unique/check/exclusion constraint and delete behavior.

**No migration files are included in this phase.** After written review/approval of this dictionary and ERD, create a new ordered migration chain, then rebuild it against a disposable empty PostgreSQL database and run schema/security/integration tests. Do not apply it to hosted Supabase as part of that test.

## 11. Migration-chain isolation

The repository currently contains a prior `supabase/migrations` history for the running application. It is not automatically the greenfield migration baseline described here. After review approval, create a separately isolated clean migration chain and CLI configuration for the new model, then prove a from-empty rebuild on a disposable PostgreSQL instance. Do not append these proposed DDL changes to the old chain, replay the old chain against the new empty database, or apply anything to hosted Supabase as part of local verification.
