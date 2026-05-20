-- Requires :admin_email and :admin_pw_hash (bcrypt $2a$ cost 12) from apply-seed.sh.

BEGIN;

CREATE TABLE IF NOT EXISTS _seed_audit (
    filename    TEXT PRIMARY KEY,
    applied_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'app_user') THEN
        RAISE NOTICE 'Table app_user not found — skipping admin seed';
        RETURN;
    END IF;

    INSERT INTO app_user (email, password_hash, role, created_at, updated_at, enabled)
    VALUES (:'admin_email', :'admin_pw_hash', 'ADMIN', NOW(), NOW(), true)
    ON CONFLICT (email) DO NOTHING;
END$$;

INSERT INTO _seed_audit (filename) VALUES ('001_prod_admin.sql')
ON CONFLICT (filename) DO NOTHING;

COMMIT;
