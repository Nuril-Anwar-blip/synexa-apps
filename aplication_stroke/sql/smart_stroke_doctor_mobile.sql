-- ============================================================
-- SMART STROKE – Doctor mobile app extension
-- Jalankan setelah smart_stroke_admin_extension.sql
-- ============================================================

-- Dokter bisa insert profil sendiri saat registrasi
DROP POLICY IF EXISTS doctors_self_insert ON doctors;
CREATE POLICY doctors_self_insert ON doctors
  FOR INSERT WITH CHECK (auth_id = auth.uid());

-- Dokter aktif boleh melihat daftar pasien (read-only)
DROP POLICY IF EXISTS users_doctor_read_patients ON users;
CREATE POLICY users_doctor_read_patients ON users
  FOR SELECT USING (
    role = 'patient'
    AND EXISTS (
      SELECT 1 FROM doctors d
      WHERE d.auth_id = auth.uid() AND d.is_active = TRUE
    )
  );

-- Dokter boleh melihat health_logs pasien
DROP POLICY IF EXISTS health_logs_doctor_read ON health_logs;
CREATE POLICY health_logs_doctor_read ON health_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM doctors d
      WHERE d.auth_id = auth.uid() AND d.is_active = TRUE
    )
  );
