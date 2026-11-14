# METRA Supabase migration source

The active migration directory is reconciled against the new METRA Supabase project's
`supabase_migrations.schema_migrations` ledger.

- The active chain contains **86** migration files, one per applied migration version.
- The restored SQL was recovered from the exact `statements` arrays retained by the
  Supabase migration ledger. One replay-only correction is documented below.
- `ledger.manifest` records the expected version/name set. CI verifies that every
  expected source exists exactly once and that no unreviewed or empty migration
  is added to the active chain.
- `supabase/pending-migrations/` is intentionally outside the active chain.

## Replay-only correction

Migration `20261103002006_fix_pending_registration_replay_classification.sql` now
checks whether the immediately preceding migration has already put the pending
request branch first. If so, it verifies the ordering and safely does nothing;
otherwise it performs the original verified replacement. This makes clean replay
idempotent without changing the already-applied production migration ledger.

Migration `20261103162738_seed_conservative_observation_role_permissions.sql` now
seeds four temporary role-catalogue rows before its allow-list insert. Those rows
were present when the migration ran on the live project but were not represented
by an earlier migration source. They exist only in the transitional `public`
schema and are replaced by the greenfield `iam.roles` catalogue later in the chain.

## Important duplicate names

Versions `20261114204909` and `20261114204951` both use the migration name
`metra_api_runtime_privileges`, but their SQL differs. Keep both files and their
timestamps: the earlier version grants the original runtime scope; the later
version extends it to alert reads. Do not deduplicate them by name.

## Quarantined migration

`supabase/pending-migrations/20261110120000_honor_scheduled_permission_revocation.sql`
is retained for audit but is not an active migration. It references legacy
`public.*` permission functions that are absent from the greenfield METRA schema.
It must not be moved back into the active chain without a separate schema review.

## Safe rebuild policy

Never replay this chain against the existing project as a repair operation.
Validate a fresh local Supabase stack first with `supabase start` and
`supabase db reset --local --yes`. Production migration history and application
data remain untouched during local verification.
