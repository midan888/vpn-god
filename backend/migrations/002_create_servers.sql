CREATE TABLE IF NOT EXISTS servers (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name       VARCHAR(100) NOT NULL,
    country    VARCHAR(2) NOT NULL,
    host       VARCHAR(255) NOT NULL,
    port       INT NOT NULL DEFAULT 51820,
    public_key TEXT NOT NULL,
    is_active  BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seed data
INSERT INTO servers (id, name, country, host, port, public_key) VALUES
    ('a1b2c3d4-0001-4000-8000-000000000001', 'US East',    'US', '203.0.113.1',  51820, 'seed-key-us-east'),
    ('a1b2c3d4-0002-4000-8000-000000000002', 'US West',    'US', '203.0.113.2',  51820, 'seed-key-us-west'),
    ('a1b2c3d4-0003-4000-8000-000000000003', 'London',     'GB', '203.0.113.3',  51820, 'seed-key-london'),
    ('a1b2c3d4-0004-4000-8000-000000000004', 'Frankfurt',  'DE', '203.0.113.4',  51820, 'seed-key-frankfurt'),
    ('a1b2c3d4-0005-4000-8000-000000000005', 'Tokyo',      'JP', '203.0.113.5',  51820, 'seed-key-tokyo'),
    ('a1b2c3d4-0006-4000-8000-000000000006', 'Singapore',  'SG', '203.0.113.6',  51820, 'seed-key-singapore')
ON CONFLICT (id) DO NOTHING;
