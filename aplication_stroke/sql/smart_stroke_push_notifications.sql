-- ============================================================
-- SMART STROKE – Push notifications extension
-- Jalankan setelah smart_stroke_schema.sql
-- ============================================================

ALTER TABLE doctors
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;

CREATE INDEX IF NOT EXISTS idx_users_fcm_token
  ON users(fcm_token) WHERE fcm_token IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_pharmacists_fcm_token
  ON pharmacists(fcm_token) WHERE fcm_token IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_doctors_fcm_token
  ON doctors(fcm_token) WHERE fcm_token IS NOT NULL;

-- Dokter boleh update token sendiri
DROP POLICY IF EXISTS doctors_self_update ON doctors;
CREATE POLICY doctors_self_update ON doctors
  FOR UPDATE USING (auth_id = auth.uid())
  WITH CHECK (auth_id = auth.uid());
