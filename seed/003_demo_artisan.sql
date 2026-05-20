-- Optional demo data; delete this file for a clean production database.

BEGIN;

CREATE TABLE IF NOT EXISTS _seed_audit (
    filename    TEXT PRIMARY KEY,
    applied_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'artisan') THEN
        RAISE NOTICE 'Table artisan not found — skipping demo artisan';
        RETURN;
    END IF;

    INSERT INTO artisan (slug, display_name, city, postal_code, trade, public, score, created_at, updated_at)
    VALUES (
        'demo-artisan',
        'Demo Artisan',
        'Paris',
        '75001',
        'menuiserie',
        true,
        82.5,
        NOW(),
        NOW()
    )
    ON CONFLICT (slug) DO NOTHING;
END$$;

INSERT INTO _seed_audit (filename) VALUES ('003_demo_artisan.sql')
ON CONFLICT (filename) DO NOTHING;

COMMIT;
