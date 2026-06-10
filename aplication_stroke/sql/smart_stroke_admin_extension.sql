-- ============================================================
-- SMART STROKE – Admin extension: Dokter + undangan dokter
-- Jalankan setelah smart_stroke_schema.sql
-- AMAN dijalankan ulang (idempotent)
-- ============================================================

CREATE TABLE IF NOT EXISTS doctors (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id          UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  email            TEXT UNIQUE NOT NULL,
  name             TEXT NOT NULL,
  phone            TEXT,
  license_number   TEXT UNIQUE,
  specialization   TEXT,
  hospital_name    TEXT,
  profile_picture  TEXT,
  is_verified      BOOLEAN NOT NULL DEFAULT FALSE,
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS doctor_invitations (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  token      TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(16), 'hex'),
  email      TEXT,
  name       TEXT,
  license_number TEXT,
  specialization TEXT,
  hospital_name  TEXT,
  created_by UUID NOT NULL REFERENCES admins(id),
  used_by    UUID REFERENCES doctors(id),
  used_at    TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
  is_used    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE pharmacist_invitations
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS license_number TEXT,
  ADD COLUMN IF NOT EXISTS pharmacy_name TEXT;

-- Kolom tambahan jika tabel doctor_invitations sudah dibuat versi lama
ALTER TABLE doctor_invitations
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS license_number TEXT,
  ADD COLUMN IF NOT EXISTS specialization TEXT,
  ADD COLUMN IF NOT EXISTS hospital_name TEXT;

ALTER TABLE doctors
  ADD COLUMN IF NOT EXISTS hospital_name TEXT,
  ADD COLUMN IF NOT EXISTS specialization TEXT;

ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctor_invitations ENABLE ROW LEVEL SECURITY;

-- Policies (drop dulu agar tidak error 42710 saat re-run)
DROP POLICY IF EXISTS doctors_read_verified ON doctors;
DROP POLICY IF EXISTS doctors_admin_all ON doctors;
DROP POLICY IF EXISTS doctor_inv_admin ON doctor_invitations;
DROP POLICY IF EXISTS doctor_inv_read ON doctor_invitations;

CREATE POLICY doctors_read_verified ON doctors
  FOR SELECT USING (is_verified = TRUE OR auth_id = auth.uid() OR auth_is_admin());

CREATE POLICY doctors_admin_all ON doctors
  FOR ALL USING (auth_is_admin());

CREATE POLICY doctor_inv_admin ON doctor_invitations
  FOR ALL USING (auth_is_admin());

CREATE POLICY doctor_inv_read ON doctor_invitations
  FOR SELECT USING (TRUE);

DROP TRIGGER IF EXISTS trg_doctors_updated ON doctors;
CREATE TRIGGER trg_doctors_updated
  BEFORE UPDATE ON doctors
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
