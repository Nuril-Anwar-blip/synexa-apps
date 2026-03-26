-- ==========================================================
-- DUMMY DATA UNTUK PENGUJIAN LOKAL (pgAdmin 4)
-- ==========================================================
-- Hapus semua data (opsional, jika ingin mengulang dari awal)
-- TRUNCATE TABLE public.users CASCADE;
-- TRUNCATE TABLE public.rehab_exercises CASCADE;

-- 1. Buat Dummy Akun Pasien & Apoteker (Password = rahasia123, hash palsu)
INSERT INTO public.users (id, email, password_hash, full_name, role, gender, age) VALUES 
('11111111-1111-1111-1111-111111111111', 'pasien@test.com', 'dummyhash123', 'Budi Santoso (Pasien)', 'pasien', 'male', 55),
('22222222-2222-2222-2222-222222222222', 'apoteker@test.com', 'dummyhash123', 'Apoteker Azizah', 'apoteker', 'female', 30)
ON CONFLICT (email) DO NOTHING;

-- 2. Buat Dummy Data Obat (Terhubung ke Pasien Budi)
INSERT INTO public.medication_reminders (user_id, name, dose, note, time, period, frequency, taken) VALUES
('11111111-1111-1111-1111-111111111111', 'Aspirin', '100mg', 'Diminum setelah makan', '08:00:00', 'Pagi', 1, false),
('11111111-1111-1111-1111-111111111111', 'Amlodipine', '5mg', 'Untuk darah tinggi', '13:00:00', 'Siang', 1, false),
('11111111-1111-1111-1111-111111111111', 'Clopidogrel', '75mg', 'Sebelum tidur', '20:00:00', 'Malam', 1, true);

-- 3. Buat Dummy Data Latihan / Rehab Exercises
-- Perhatikan format array JSON yang wajib menggunakan [ ... ] dan petik ganda
INSERT INTO public.rehab_exercises (id, name, category, media_url, instructions) VALUES
('33333333-3333-3333-3333-333333333333', 'Peregangan Jari & Tangan', 'Motorik Halus', 'https://www.youtube.com/watch?v=dummy1', '["Buka telapak tangan lebar-lebar", "Kepalkan tangan perlahan", "Tahan 5 detik", "Ulangi 10 kali"]'::jsonb),
('44444444-4444-4444-4444-444444444444', 'Latihan Berjalan Singkat', 'Motorik Kasar', 'https://www.youtube.com/watch?v=dummy2', '["Berdiri tegak", "Angkat kaki kiri perlahan", "Langkah kecil 10 kali"]'::jsonb),
('55555555-5555-5555-5555-555555555555', 'Latihan Menelan (Disfagia)', 'Otot Wajah/Leher', 'https://www.youtube.com/watch?v=dummy3', '["Tarik napas dalam", "Telan perlahan tanpa makanan", "Lakukan 5 set"]'::jsonb);

-- 4. Buat History Latihan Pasien (Logs)
INSERT INTO public.rehab_exercise_logs (user_id, exercise_id, duration_actual_seconds, is_aborted) VALUES
('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 300, false),
('11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 120, true);

-- 5. Buat Post Komunitas Dummy
INSERT INTO public.posts (id, user_id, content, media_type) VALUES
('66666666-6666-6666-6666-666666666666', '11111111-1111-1111-1111-111111111111', 'Hari ini puji Tuhan saya sudah bisa menggenggam gelas lagi setelah stroke 6 bulan yang lalu.', 'text'),
('77777777-7777-7777-7777-777777777777', '22222222-2222-2222-2222-222222222222', 'Semangat Bapak Budi! Jangan lupa minum obat pengencer darahnya rutin ya.', 'text');

-- Hubungkan komentar ke post
INSERT INTO public.comments (post_id, user_id, content) VALUES
('66666666-6666-6666-6666-666666666666', '22222222-2222-2222-2222-222222222222', 'Alhamdulillah! Lanjutkan latihannya pak, pelan-pelan saja.');
