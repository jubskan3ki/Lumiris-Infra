BEGIN;

CREATE TABLE IF NOT EXISTS _seed_audit (
    filename    TEXT PRIMARY KEY,
    applied_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'plan') THEN
        RAISE NOTICE 'Table plan not found — skipping plan seed';
        RETURN;
    END IF;

    INSERT INTO plan (code, label, monthly_price_cents, currency, features, created_at, updated_at)
    VALUES
        ('FREE',       'Decouverte',  0,    'EUR', '{"audits_per_month":3,"max_artisans":1}'::jsonb,         NOW(), NOW()),
        ('ARTISAN',    'Artisan',     2900, 'EUR', '{"audits_per_month":50,"max_artisans":3}'::jsonb,        NOW(), NOW()),
        ('ENTERPRISE', 'Entreprise',  9900, 'EUR', '{"audits_per_month":-1,"max_artisans":-1,"sla":true}'::jsonb, NOW(), NOW())
    ON CONFLICT (code) DO NOTHING;
END$$;

INSERT INTO _seed_audit (filename) VALUES ('002_plans.sql')
ON CONFLICT (filename) DO NOTHING;

COMMIT;
