-- Pastikan kolom extension ada (jika tabel dibuat versi lama)
ALTER TABLE doctor_invitations
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS license_number TEXT,
  ADD COLUMN IF NOT EXISTS specialization TEXT,
  ADD COLUMN IF NOT EXISTS hospital_name TEXT;

ALTER TABLE pharmacist_invitations
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS license_number TEXT,
  ADD COLUMN IF NOT EXISTS pharmacy_name TEXT;

ALTER TABLE doctors
  ADD COLUMN IF NOT EXISTS hospital_name TEXT,
  ADD COLUMN IF NOT EXISTS specialization TEXT;

-- ============================================================
-- SMART STROKE – Data dummy lengkap (tanpa auth.users)
-- Jalankan SETELAH:
--   1. smart_stroke_schema.sql
--   2. smart_stroke_admin_extension.sql
--   3. smart_stroke_seed_pnpk.sql
--
-- AMAN dijalankan ulang — menghapus data dummy by ID tetap lalu insert ulang.
-- Catatan: auth_id sengaja NULL agar tidak perlu buat user di Auth dulu.
-- Untuk login, jalankan juga: smart_stroke_seed_auth.sql
-- Password semua akun dummy: SmartStroke123!
-- ============================================================

BEGIN;

-- ── Hapus data dummy (urutan FK) ─────────────────────────────
UPDATE chat_rooms SET last_message_id = NULL WHERE id IN (
  'e0000001-0000-4000-8000-000000000001',
  'e0000002-0000-4000-8000-000000000002'
);
DELETE FROM messages WHERE id IN (
  'e1000001-0000-4000-8000-000000000001',
  'e1000002-0000-4000-8000-000000000001',
  'e1000003-0000-4000-8000-000000000002',
  'e1000004-0000-4000-8000-000000000002'
);
DELETE FROM chat_rooms WHERE id IN (
  'e0000001-0000-4000-8000-000000000001',
  'e0000002-0000-4000-8000-000000000002'
);
DELETE FROM likes WHERE post_id IN (
  'f0000001-0000-4000-8000-000000000001',
  'f0000002-0000-4000-8000-000000000002'
);
DELETE FROM comments WHERE post_id IN (
  'f0000001-0000-4000-8000-000000000001',
  'f0000002-0000-4000-8000-000000000002'
);
DELETE FROM posts WHERE id IN (
  'f0000001-0000-4000-8000-000000000001',
  'f0000002-0000-4000-8000-000000000002'
);
DELETE FROM medication_logs WHERE user_id IN (
  'c0000001-0000-4000-8000-000000000001',
  'c0000002-0000-4000-8000-000000000002',
  'c0000003-0000-4000-8000-000000000003'
);

DELETE FROM user_medications WHERE id IN (
  '07000001-0000-4000-8000-000000000001',
  '07000002-0000-4000-8000-000000000002',
  '07000003-0000-4000-8000-000000000003'
);
DELETE FROM medication_reminders WHERE id IN (
  '07100001-0000-4000-8000-000000000001',
  '07100002-0000-4000-8000-000000000001',
  '07100003-0000-4000-8000-000000000002'
);
DELETE FROM rehab_quiz_attempts WHERE user_id IN (
  'c0000001-0000-4000-8000-000000000001',
  'c0000002-0000-4000-8000-000000000002'
);
DELETE FROM rehab_exercise_logs WHERE user_id IN (
  'c0000001-0000-4000-8000-000000000001',
  'c0000002-0000-4000-8000-000000000002'
);
DELETE FROM rehab_user_progress WHERE user_id IN (
  'c0000001-0000-4000-8000-000000000001',
  'c0000002-0000-4000-8000-000000000002'
);
DELETE FROM health_logs WHERE user_id IN (
  'c0000001-0000-4000-8000-000000000001',
  'c0000002-0000-4000-8000-000000000002',
  'c0000003-0000-4000-8000-000000000003'
);
DELETE FROM sensor_data WHERE user_id IN (
  'c0000001-0000-4000-8000-000000000001',
  'c0000002-0000-4000-8000-000000000002'
);
DELETE FROM notifications WHERE user_id IN (
  'c0000001-0000-4000-8000-000000000001',
  'c0000002-0000-4000-8000-000000000002',
  'c0000003-0000-4000-8000-000000000003'
);
DELETE FROM emergency_logs WHERE user_id IN (
  'c0000001-0000-4000-8000-000000000001',
  'c0000002-0000-4000-8000-000000000002'
);
DELETE FROM user_settings WHERE user_id IN (
  'c0000001-0000-4000-8000-000000000001',
  'c0000002-0000-4000-8000-000000000002',
  'c0000003-0000-4000-8000-000000000003'
);
DELETE FROM pairings WHERE id IN (
  'd1000001-0000-4000-8000-000000000001',
  'd1000002-0000-4000-8000-000000000002'
);
DELETE FROM doctor_invitations WHERE id IN (
  'd2000001-0000-4000-8000-000000000001',
  'd2000002-0000-4000-8000-000000000002',
  'd2000003-0000-4000-8000-000000000003'
);
DELETE FROM pharmacist_invitations WHERE id IN (
  'd3000001-0000-4000-8000-000000000001',
  'd3000002-0000-4000-8000-000000000002',
  'd3000003-0000-4000-8000-000000000003'
);
DELETE FROM users WHERE id IN (
  'c0000001-0000-4000-8000-000000000001',
  'c0000002-0000-4000-8000-000000000002',
  'c0000003-0000-4000-8000-000000000003'
);
DELETE FROM doctors WHERE id IN (
  'd0000001-0000-4000-8000-000000000001',
  'd0000002-0000-4000-8000-000000000002'
);
DELETE FROM pharmacists WHERE id IN (
  'b0000001-0000-4000-8000-000000000001',
  'b0000002-0000-4000-8000-000000000002'
);
DELETE FROM admins WHERE id = 'a0000001-0000-4000-8000-000000000001';

-- ── 1. ADMIN ─────────────────────────────────────────────────
INSERT INTO admins (id, email, name) VALUES
  ('a0000001-0000-4000-8000-000000000001', 'admin@smartstroke.id', 'Admin Smart Stroke');

-- ── 2. APOTEKER ──────────────────────────────────────────────
INSERT INTO pharmacists (id, email, name, phone, license_number, pharmacy_name, pharmacy_address, pharmacy_lat, pharmacy_lng, is_verified, is_active) VALUES
  ('b0000001-0000-4000-8000-000000000001', 'apoteker.sari@farmasi.id', 'Sari Wulandari, S.Farm., Apt.', '081234567801', 'SIPA-2024-001', 'Apotek Sehat Sentosa', 'Jl. Sudirman No. 45, Jakarta Pusat', -6.2088, 106.8456, TRUE, TRUE),
  ('b0000002-0000-4000-8000-000000000002', 'apoteker.budi@farmasi.id', 'Budi Santoso, S.Farm., Apt.', '081234567802', 'SIPA-2024-002', 'Apotek Mitra Stroke Care', 'Jl. Gatot Subroto No. 12, Bandung', -6.9175, 107.6191, TRUE, TRUE);

-- ── 3. DOKTER ──────────────────────────────────────────────────
INSERT INTO doctors (id, email, name, phone, license_number, specialization, hospital_name, is_verified, is_active) VALUES
  ('d0000001-0000-4000-8000-000000000001', 'dr.andi@rsstroke.id', 'dr. Andi Pratama, Sp.S(K)', '081234567901', 'STR-2020-1001', 'Neurologi', 'RS Stroke Nasional Jakarta', TRUE, TRUE),
  ('d0000002-0000-4000-8000-000000000002', 'dr.rina@rsstroke.id', 'dr. Rina Kusuma, Sp.PD', '081234567902', 'STR-2019-2045', 'Penyakit Dalam', 'RS Umum Pusat Surabaya', TRUE, TRUE);

-- ── 4. PASIEN ──────────────────────────────────────────────────
INSERT INTO users (id, email, name, phone, date_of_birth, gender, address, emergency_contact_name, emergency_contact_phone, stroke_date, stroke_type, blood_type, height_cm, weight_kg, paired_pharmacist_id, role) VALUES
  ('c0000001-0000-4000-8000-000000000001', 'pasien.ahmad@email.com', 'Ahmad Rizki', '081211111001', '1965-03-15', 'male', 'Jl. Melati No. 8, Depok', 'Siti Rizki', '081211111099', '2024-11-20', 'ischemic', 'A', 168.00, 72.50, 'b0000001-0000-4000-8000-000000000001', 'patient'),
  ('c0000002-0000-4000-8000-000000000002', 'pasien.dewi@email.com', 'Dewi Lestari', '081211111002', '1970-07-22', 'female', 'Jl. Mawar No. 3, Tangerang', 'Bambang Lestari', '081211111098', '2025-01-08', 'hemorrhagic', 'B', 155.00, 58.00, 'b0000001-0000-4000-8000-000000000001', 'patient'),
  ('c0000003-0000-4000-8000-000000000003', 'pasien.hasan@email.com', 'Hasan Basri', '081211111003', '1958-11-30', 'male', 'Jl. Kenanga No. 15, Bekasi', 'Fatimah Basri', '081211111097', '2025-02-14', 'tia', 'O', 172.00, 80.00, 'b0000002-0000-4000-8000-000000000002', 'patient');

-- ── 5. UNDANGAN APOTEKER & DOKTER ──────────────────────────────
INSERT INTO pharmacist_invitations (id, token, email, name, license_number, pharmacy_name, created_by, is_used, expires_at) VALUES
  ('d3000001-0000-4000-8000-000000000001', 'APOTEK01', 'apoteker.baru1@farmasi.id', 'Maya Indira, S.Farm.', 'SIPA-2025-010', 'Apotek Harapan Baru', 'a0000001-0000-4000-8000-000000000001', FALSE, NOW() + INTERVAL '7 days'),
  ('d3000002-0000-4000-8000-000000000002', 'APOTEK02', 'apoteker.baru2@farmasi.id', 'Rudi Hartono, S.Farm.', 'SIPA-2025-011', 'Apotek Medika Sejahtera', 'a0000001-0000-4000-8000-000000000001', FALSE, NOW() + INTERVAL '7 days'),
  ('d3000003-0000-4000-8000-000000000003', 'APOTEK99', 'apoteker.lama@farmasi.id', 'Eko Prasetyo, S.Farm.', 'SIPA-2024-099', 'Apotek Lama', 'a0000001-0000-4000-8000-000000000001', TRUE, NOW() - INTERVAL '1 day');

INSERT INTO doctor_invitations (id, token, email, name, license_number, specialization, hospital_name, created_by, used_by, is_used, expires_at) VALUES
  ('d2000001-0000-4000-8000-000000000001', 'DOKTOR01', 'dr.baru@rsstroke.id', 'dr. Fajar Nugroho', 'STR-2025-3001', 'Neurologi', 'RS Stroke Regional Medan', 'a0000001-0000-4000-8000-000000000001', NULL, FALSE, NOW() + INTERVAL '7 days'),
  ('d2000002-0000-4000-8000-000000000002', 'DOKTOR02', 'dr.nova@rsstroke.id', 'dr. Nova Anggraini', 'STR-2025-3002', 'Rehabilitasi Medik', 'RS Rehabilitasi Yogyakarta', 'a0000001-0000-4000-8000-000000000001', NULL, FALSE, NOW() + INTERVAL '7 days'),
  ('d2000003-0000-4000-8000-000000000003', 'DOKTOR99', 'dr.lama@rsstroke.id', 'dr. Lama Sejahtera', 'STR-2018-0099', 'Neurologi', 'RS Lama', 'a0000001-0000-4000-8000-000000000001', 'd0000001-0000-4000-8000-000000000001', TRUE, NOW() - INTERVAL '2 days');

-- ── 6. PAIRING ─────────────────────────────────────────────────
INSERT INTO pairings (id, patient_id, pharmacist_id, status, requested_at, responded_at) VALUES
  ('d1000001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', 'b0000001-0000-4000-8000-000000000001', 'accepted', NOW() - INTERVAL '30 days', NOW() - INTERVAL '29 days'),
  ('d1000002-0000-4000-8000-000000000002', 'c0000002-0000-4000-8000-000000000002', 'b0000001-0000-4000-8000-000000000001', 'accepted', NOW() - INTERVAL '20 days', NOW() - INTERVAL '19 days');

-- ── 7. CHAT & PESAN ────────────────────────────────────────────
INSERT INTO chat_rooms (id, patient_id, pharmacist_id, unread_by_patient, unread_by_pharmacist) VALUES
  ('e0000001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', 'b0000001-0000-4000-8000-000000000001', 0, 1),
  ('e0000002-0000-4000-8000-000000000002', 'c0000002-0000-4000-8000-000000000002', 'b0000001-0000-4000-8000-000000000001', 2, 0);

INSERT INTO messages (id, chat_room_id, sender_id, sender_role, content, is_read, created_at) VALUES
  ('e1000001-0000-4000-8000-000000000001', 'e0000001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', 'patient', 'Selamat pagi Bu Sari, tekanan darah saya pagi ini 140/90. Apakah perlu ubah dosis?', TRUE, NOW() - INTERVAL '2 hours'),
  ('e1000002-0000-4000-8000-000000000001', 'e0000001-0000-4000-8000-000000000001', 'b0000001-0000-4000-8000-000000000001', 'pharmacist', 'Pagi Pak Ahmad. Untuk sementara tetap minum obat sesuai jadwal. Jika 3 hari berturut-turut di atas 140/90, hubungi dokter.', FALSE, NOW() - INTERVAL '1 hour'),
  ('e1000003-0000-4000-8000-000000000002', 'e0000002-0000-4000-8000-000000000002', 'c0000002-0000-4000-8000-000000000002', 'patient', 'Bu, obat Clopidogrel saya tinggal 5 tablet lagi.', TRUE, NOW() - INTERVAL '5 hours'),
  ('e1000004-0000-4000-8000-000000000002', 'e0000002-0000-4000-8000-000000000002', 'b0000001-0000-4000-8000-000000000001', 'pharmacist', 'Baik Bu Dewi, saya catat. Bisa ambil di apotek besok pagi ya.', FALSE, NOW() - INTERVAL '4 hours');

UPDATE chat_rooms SET last_message_id = 'e1000002-0000-4000-8000-000000000001' WHERE id = 'e0000001-0000-4000-8000-000000000001';
UPDATE chat_rooms SET last_message_id = 'e1000004-0000-4000-8000-000000000002' WHERE id = 'e0000002-0000-4000-8000-000000000002';

-- ── 8. KOMUNITAS (POST, LIKE, KOMENTAR) ────────────────────────
INSERT INTO posts (id, user_id, content, category) VALUES
  ('f0000001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', 'Hari ini berhasil jalan 10 menit tanpa alat bantu! Terima kasih untuk semua dukungannya 💪', 'story'),
  ('f0000002-0000-4000-8000-000000000002', 'c0000002-0000-4000-8000-000000000002', 'Tips: minum air cukup dan jangan skip latihan pernapasan pagi hari. Sangat membantu!', 'tips');

INSERT INTO likes (id, post_id, user_id) VALUES
  ('f1000001-0000-4000-8000-000000000001', 'f0000001-0000-4000-8000-000000000001', 'c0000002-0000-4000-8000-000000000002');

INSERT INTO comments (id, post_id, user_id, content) VALUES
  ('f2000001-0000-4000-8000-000000000001', 'f0000001-0000-4000-8000-000000000001', 'c0000002-0000-4000-8000-000000000002', 'Selamat Pak Ahmad! Semangat terus ya 🙌');

-- ── 9. OBAT PASIEN & PENGINGAT ─────────────────────────────────
INSERT INTO user_medications (id, user_id, medication_id, dosage, unit, instructions, prescribed_by, start_date, is_active)
SELECT '07000001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', m.id, '1', 'tablet', 'Setelah makan pagi', 'b0000001-0000-4000-8000-000000000001', CURRENT_DATE - 30, TRUE
FROM medications m WHERE m.name = 'Aspirin' LIMIT 1;

INSERT INTO user_medications (id, user_id, medication_id, dosage, unit, instructions, prescribed_by, start_date, is_active)
SELECT '07000002-0000-4000-8000-000000000002', 'c0000001-0000-4000-8000-000000000001', m.id, '1', 'tablet', 'Malam hari', 'b0000001-0000-4000-8000-000000000001', CURRENT_DATE - 30, TRUE
FROM medications m WHERE m.name = 'Amlodipin' LIMIT 1;

INSERT INTO user_medications (id, user_id, medication_id, dosage, unit, instructions, prescribed_by, start_date, is_active)
SELECT '07000003-0000-4000-8000-000000000003', 'c0000002-0000-4000-8000-000000000002', m.id, '1', 'tablet', 'Setelah makan', 'b0000001-0000-4000-8000-000000000001', CURRENT_DATE - 20, TRUE
FROM medications m WHERE m.name = 'Clopidogrel' LIMIT 1;

INSERT INTO medication_reminders (id, user_id, user_medication_id, medication_name, dosage, reminder_times, is_active) VALUES
  ('07100001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', '07000001-0000-4000-8000-000000000001', 'Aspirin', '1 tablet', '["07:00","19:00"]', TRUE),
  ('07100002-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', '07000002-0000-4000-8000-000000000002', 'Amlodipin', '1 tablet', '["21:00"]', TRUE),
  ('07100003-0000-4000-8000-000000000002', 'c0000002-0000-4000-8000-000000000002', '07000003-0000-4000-8000-000000000003', 'Clopidogrel', '1 tablet', '["08:00","20:00"]', TRUE);

INSERT INTO medication_logs (id, user_id, reminder_id, medication_name, scheduled_time, taken_at, status) VALUES
  ('07200001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', '07100001-0000-4000-8000-000000000001', 'Aspirin', date_trunc('day', NOW()) + TIME '07:00', date_trunc('day', NOW()) + TIME '07:05', 'taken'),
  ('07200002-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', '07100001-0000-4000-8000-000000000001', 'Aspirin', date_trunc('day', NOW()) + TIME '19:00', NULL, 'pending'),
  ('07200003-0000-4000-8000-000000000002', 'c0000002-0000-4000-8000-000000000002', '07100003-0000-4000-8000-000000000002', 'Clopidogrel', date_trunc('day', NOW()) + TIME '08:00', date_trunc('day', NOW()) + TIME '08:12', 'taken');

-- ── 10. LOG KESEHATAN & SENSOR ─────────────────────────────────
INSERT INTO health_logs (id, user_id, log_date, systolic_bp, diastolic_bp, heart_rate, blood_sugar, has_dizziness, mood, notes) VALUES
  ('08000001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', CURRENT_DATE, 138, 88, 76, 110.00, FALSE, 'good', 'Kondisi stabil'),
  ('08000002-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', CURRENT_DATE - 1, 142, 90, 80, 115.00, TRUE, 'neutral', 'Sedikit pusing pagi hari'),
  ('08000003-0000-4000-8000-000000000002', 'c0000002-0000-4000-8000-000000000002', CURRENT_DATE, 125, 82, 72, 98.00, FALSE, 'very_good', 'Baik'),
  ('08000004-0000-4000-8000-000000000003', 'c0000003-0000-4000-8000-000000000003', CURRENT_DATE, 130, 85, 74, NULL, FALSE, 'good', NULL);

INSERT INTO sensor_data (id, user_id, device_id, sensor_type, value_raw, value_numeric, unit, recorded_at) VALUES
  ('08100001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', 'watch-001', 'heart_rate', '{"bpm": 76}', 76, 'bpm', NOW() - INTERVAL '30 minutes'),
  ('08100002-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', 'watch-001', 'spo2', '{"percent": 97}', 97, '%', NOW() - INTERVAL '30 minutes'),
  ('08100003-0000-4000-8000-000000000002', 'c0000002-0000-4000-8000-000000000002', 'watch-002', 'heart_rate', '{"bpm": 72}', 72, 'bpm', NOW() - INTERVAL '1 hour');

-- ── 11. REHAB PROGRESS & LOG ───────────────────────────────────
INSERT INTO rehab_user_progress (id, user_id, current_phase_id, total_score, total_sessions, total_minutes, streak_days, last_session_date)
SELECT '0a000001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', p.id, 45, 12, 180, 5, CURRENT_DATE
FROM rehab_phases p WHERE p.phase_number = 2 LIMIT 1;

INSERT INTO rehab_user_progress (id, user_id, current_phase_id, total_score, total_sessions, total_minutes, streak_days, last_session_date)
SELECT '0a000002-0000-4000-8000-000000000002', 'c0000002-0000-4000-8000-000000000002', p.id, 28, 8, 120, 3, CURRENT_DATE - 1
FROM rehab_phases p WHERE p.phase_number = 1 LIMIT 1;

INSERT INTO rehab_exercise_logs (id, user_id, exercise_id, session_date, duration_seconds, repetitions_done, score, is_completed)
SELECT '0a100001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', e.id, CURRENT_DATE, 300, 8, 8, TRUE
FROM rehab_exercises e
JOIN rehab_phases p ON p.id = e.phase_id
WHERE p.phase_number = 2 AND e.order_index = 1
LIMIT 1;

INSERT INTO rehab_quiz_attempts (id, user_id, phase_id, answers, score, total_questions, correct_answers, is_passed)
SELECT '0a200001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', p.id, '{"q1":"good","q2":"good"}', 8, 5, 4, TRUE
FROM rehab_phases p WHERE p.phase_number = 2 LIMIT 1;

-- ── 12. NOTIFIKASI & EMERGENCY ─────────────────────────────────
INSERT INTO notifications (id, user_id, title, body, type, is_read) VALUES
  ('09000001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', 'Waktunya minum obat', 'Aspirin 1 tablet — jangan lupa ya!', 'medication', FALSE),
  ('09000002-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', 'Latihan rehab pagi', 'Sesi latihan fase 2 menunggu Anda.', 'rehab', TRUE),
  ('09000003-0000-4000-8000-000000000002', 'c0000002-0000-4000-8000-000000000002', 'Pesan dari apoteker', 'Obat Clopidogrel siap diambil besok.', 'chat', FALSE);

INSERT INTO emergency_logs (id, user_id, event_type, latitude, longitude, address, contacted_name, contacted_number) VALUES
  ('09100001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', 'location_share', -6.4025, 106.7942, 'Depok, Jawa Barat', 'Siti Rizki', '081211111099');

-- ── 13. USER SETTINGS & APP CONFIG ─────────────────────────────
INSERT INTO user_settings (id, user_id, language, theme, font_size) VALUES
  ('0b000001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', 'id', 'light', 'medium'),
  ('0b000002-0000-4000-8000-000000000002', 'c0000002-0000-4000-8000-000000000002', 'id', 'system', 'large'),
  ('0b000003-0000-4000-8000-000000000003', 'c0000003-0000-4000-8000-000000000003', 'id', 'light', 'medium');

INSERT INTO app_config (id, key, value, description, is_public, updated_by) VALUES
  ('0b100001-0000-4000-8000-000000000001', 'app_version', '1.0.0', 'Versi aplikasi mobile', TRUE, 'a0000001-0000-4000-8000-000000000001'),
  ('0b100002-0000-4000-8000-000000000001', 'maintenance_mode', 'false', 'Mode maintenance', FALSE, 'a0000001-0000-4000-8000-000000000001'),
  ('0b100003-0000-4000-8000-000000000001', 'support_email', 'support@smartstroke.id', 'Email dukungan', TRUE, 'a0000001-0000-4000-8000-000000000001')
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value,
  description = EXCLUDED.description,
  updated_by = EXCLUDED.updated_by;

COMMIT;

-- ============================================================
-- RINGKASAN DATA DUMMY
-- ============================================================
-- Admin      : admin@smartstroke.id
-- Apoteker   : 2 (Sari, Budi) + 2 undangan aktif (APOTEK01, APOTEK02)
-- Dokter     : 2 (Andi, Rina) + 2 undangan aktif (DOKTOR01, DOKTOR02)
-- Pasien     : 3 (Ahmad, Dewi, Hasan)
-- Chat       : 2 room, 4 pesan
-- Post       : 2 + like + komentar
-- Obat/reminder/log kesehatan/rehab/notifikasi: tersedia
--
-- LOGIN (jalankan smart_stroke_seed_auth.sql dulu):
--   Password semua: SmartStroke123!
--   pasien.ahmad@email.com | pasien.dewi@email.com | pasien.hasan@email.com
--   admin@smartstroke.id | apoteker.sari@farmasi.id | dr.andi@rsstroke.id
-- ============================================================
