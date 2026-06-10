-- ============================================================
-- SMART STROKE – RLS tambahan untuk dashboard admin
-- Jalankan setelah smart_stroke_schema.sql + admin_extension.sql
-- AMAN dijalankan ulang (idempotent)
-- ============================================================

-- Admin boleh baca statistik chat & pengingat obat
DROP POLICY IF EXISTS chat_rooms_admin ON chat_rooms;
CREATE POLICY chat_rooms_admin ON chat_rooms
  FOR SELECT USING (auth_is_admin());

DROP POLICY IF EXISTS med_rem_admin ON medication_reminders;
CREATE POLICY med_rem_admin ON medication_reminders
  FOR SELECT USING (auth_is_admin());

DROP POLICY IF EXISTS med_log_admin ON medication_logs;
CREATE POLICY med_log_admin ON medication_logs
  FOR SELECT USING (auth_is_admin());

-- Admin boleh kelola semua pasien (read/update untuk konsol)
DROP POLICY IF EXISTS users_admin_all ON users;
CREATE POLICY users_admin_all ON users
  FOR ALL USING (auth_is_admin())
  WITH CHECK (auth_is_admin());
