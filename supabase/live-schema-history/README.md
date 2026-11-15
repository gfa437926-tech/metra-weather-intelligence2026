# Recovered live Supabase migration history

**Project:** `tbdnklyxjvbrilvnwgmq`  
**Captured:** 2026-11-15  
**Source:** read-only export of `supabase_migrations.schema_migrations`.

This directory contains all **86** SQL statements recovered from the live project's migration-history table. Each recorded migration had exactly one non-null SQL statement. Files use the exact live version/name identifiers:

`<version>_<name>.sql`

The archive spans `20261102154652` through `20261114204951`.

## Archive only — do not apply

This is a forensic/source-recovery snapshot, **not** the canonical Supabase CLI migration directory. Do not run `supabase db push`, `supabase migration up`, or otherwise apply this directory wholesale. Some historical migrations are context-dependent and include destructive operations against application-owned objects in the new project. In particular, the greenfield rebuild migration drops the `metra_migration` schema with CASCADE. Its presence records what the live database says was applied; it is not approval to replay it against a populated environment.

## Current repository reconciliation

At capture time, this repository's active `supabase/migrations/` directory contained 52 SQL files:
- 51 active migration version identifiers also exist in the live history archive.
- One active migration (`20261110120000_honor_scheduled_permission_revocation.sql`) is not present in the live applied history and must be treated as pending/unapplied until separately reviewed.
- The 51 shared-version files are not all byte-identical to the live SQL archive. A version match alone does not prove that the migration contents are equivalent.
- The archive contains 35 additional live migration versions not represented by the active directory.

Do not overwrite active migration files or promote the archive wholesale. Keep both sets until exact SQL comparison, version mapping, destructive-operation review and clean replay validation determine the canonical history.

## Reconciliation procedure

1. Compare every shared-version active file with the archived live SQL; distinguish whitespace/comment-only differences from semantic drift.
2. Review the one active-only pending migration and determine whether it was superseded or intentionally not applied.
3. Review all 35 live-only migrations, especially the greenfield rebuild and runtime privilege changes.
4. Build a curated ordered migration sequence on a disposable Supabase/PostgreSQL environment.
5. Compare resulting tables, columns, constraints, indexes, triggers, functions, grants, RLS policies and exposed-schema settings with the live project.
6. Promote only the reviewed canonical sequence into `supabase/migrations/` after reproducibility and security tests pass.

No database writes were performed to create this archive. The live project was not changed.
