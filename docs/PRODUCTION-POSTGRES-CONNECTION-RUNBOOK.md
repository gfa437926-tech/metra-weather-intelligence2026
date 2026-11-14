# METRA .NET API — Production PostgreSQL Connection Runbook

Status: preparation only. This document does not create a database role, change a hosted project, deploy the API, or provision a secret.

## 1. Current verified boundary

- The database role `metra_api_runtime` exists as a non-login role with `NOSUPERUSER`, `NOCREATEDB`, `NOCREATEROLE`, `NOREPLICATION`, and `NOBYPASSRLS`.
- The role is intended to hold the API's narrowly granted schema/table/column privileges and internal RLS policies.
- The API must connect using a separate login role that is a member of `metra_api_runtime`.
- No production login role or production connection secret is provisioned by this runbook.
- Never connect as `postgres`, `service_role`, `supabase_admin`, or another administrative role.
- Never put PostgreSQL credentials, Supabase secret keys, or `service_role` keys in Flutter, web assets, source control, build arguments, or client-visible configuration.

## 2. Provisioning procedure (operator action, after explicit approval)

Use the managed database's administrative console or a protected DBA session. Confirm the target project ref is `tbdnklyxjvbrilvnwgmq` before any command. Do not run this against any legacy METRA project.

Create a distinct login per environment (for example, `metra_api_login_prod`); do not share a credential between staging and production:

```sql
CREATE ROLE metra_api_login_prod
  LOGIN
  INHERIT
  NOSUPERUSER
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  NOBYPASSRLS;

GRANT metra_api_runtime TO metra_api_login_prod;
```

Set a long, randomly generated password using the database provider's secure password workflow or an interactive `psql \\password metra_api_login_prod` session. Do not place the password in SQL files, shell history, tickets, chat, or CI logs.

Before issuing credentials, verify role attributes and membership:

```sql
SELECT rolname, rolcanlogin, rolsuper, rolcreatedb, rolcreaterole,
       rolreplication, rolbypassrls
FROM pg_roles
WHERE rolname IN ('metra_api_runtime', 'metra_api_login_prod');

SELECT pg_has_role(
  'metra_api_login_prod',
  'metra_api_runtime',
  'member'
) AS inherits_runtime_role;
```

Expected: `metra_api_runtime` is NOLOGIN and has no elevated attributes; `metra_api_login_prod` can login but has no elevated attributes; membership is true. If any check differs, stop and do not deploy.

## 3. Secret and connection configuration

Store the complete connection string only in the .NET hosting provider's secret manager under:

- `METRA_DATABASE_CONNECTION_STRING`

Use the provider's direct PostgreSQL endpoint or a session-capable pooler suitable for a long-lived Npgsql connection pool. Avoid putting credentials in a checked-in `appsettings.*.json`, Docker image, Flutter environment, or public GitHub Actions variable.

Required connection properties:

- Host, port, database, username = the environment-specific login role, password from secret manager.
- `SSL Mode=VerifyFull`; do not disable certificate or hostname validation in production.
- Keep the API's bounded timeout and pool settings; review pool size against the hosting instance and database connection limit before scaling replicas.
- Rotate the login password through the secret manager and database operator workflow; restart/recycle the API pool after rotation.

The API reads `METRA_DATABASE_CONNECTION_STRING` server-side and enforces `VerifyFull` except for an explicitly enabled loopback-only local test setting. Never set `MetraDatabase:AllowInsecureLocalhost=true` in staging or production.

Also configure server-side `SUPABASE_URL` to the exact new project's HTTPS URL for JWT issuer validation. Configure explicit `Cors:AllowedOrigins` for deployed client origins; do not use wildcard origins with credentials.

## 4. Pre-deployment verification gates

Run these checks against a disposable environment first, then against the approved production endpoint using read-only smoke tests:

1. Verify the connection's `current_user` is the environment-specific login and `current_role` is not an administrative role.
2. Verify `pg_has_role(current_user, 'metra_api_runtime', 'member')` is true.
3. Verify `rolsuper`, `rolcreatedb`, `rolcreaterole`, `rolreplication`, and `rolbypassrls` are all false for the login.
4. Verify a harmless `SELECT 1` and `GET /health/ready` succeed over TLS.
5. Verify the login cannot create roles/databases, bypass RLS, access unrelated schemas, or perform ungranted DDL.
6. Run API authorization and cross-tenant/station-scope negative tests (BOLA/IDOR), including two organizations and two stations, before enabling write endpoints.
7. Confirm logs never include connection strings, passwords, access tokens, or sensitive observation payloads.
8. Confirm backups, point-in-time recovery, alerting, and a tested credential-rotation procedure.

The runtime role's RLS policies intentionally authorize the trusted API role broadly within the tables it can access. Therefore the API is a security boundary: every data operation must enforce active profile, membership, permission, and organization/unit/station scope in SQL/transaction logic. Do not expose the database login to clients.

## 5. Deployment gates still outstanding

- Provision the production login role and secret only after explicit operator approval.
- Deploy the .NET API to a selected hosting target with HTTPS and secret-manager integration.
- Configure `SUPABASE_URL`, `METRA_DATABASE_CONNECTION_STRING`, and allowed CORS origins.
- Run TLS, readiness, JWT, authorization-scope, and database least-privilege smoke tests.
- Complete missing application workflows and security tests before describing the application as production-ready.

No action in this document authorizes changes to old METRA repositories or databases, importing legacy data, or applying migrations to the hosted database.
