# seed/

Production seed data — idempotent SQL applied once after the first migration
runs against an empty database. Designed to be safe to re-run: every statement
uses `ON CONFLICT DO NOTHING` or guarded `IF NOT EXISTS` blocks, and an
`_seed_audit` table records which file ran when.

## Files

- `001_prod_admin.sql` — required. First admin user (email + bcrypt'd password from env vars).
- `002_plans.sql` — required. Plan reference data (FREE / ARTISAN / ENTERPRISE) if the table exists.
- `003_demo_artisan.sql` — optional. One public demo artisan; remove the file (or wrap in `-- DISABLED`) for "real prod".

## Running

```bash
./seed/apply-seed.sh prod
```

The script:

1. Loads `SPRING_DATASOURCE_*` from Infisical (`infisical export --env=prod`).
2. Generates a fresh `SEED_ADMIN_PASSWORD` (`openssl rand -base64 32`).
3. Bcrypts it (cost 12) via `htpasswd -nbB` so Spring Security accepts it
   (the `$2a$` flavour).
4. For each `00*.sql`: `psql -v ON_ERROR_STOP=1 -v admin_email=… -v admin_pw_hash=…`.
5. Pushes `SEED_ADMIN_PASSWORD_GENERATED` to Infisical so a human can fetch it
   exactly once, then deletes it.
6. `shred`s temporary files holding the password.
7. Prints next-step instructions (rotate the password, delete the Infisical entry).

## Idempotency

Every SQL file ends with:

```sql
INSERT INTO _seed_audit (filename, applied_at)
VALUES ('001_prod_admin.sql', NOW())
ON CONFLICT (filename) DO NOTHING;
```

`_seed_audit` is created by `apply-seed.sh` before any file runs, so the second
run is a series of no-ops.
