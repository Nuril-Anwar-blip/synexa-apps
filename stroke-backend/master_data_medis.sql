-- ==========================================================
-- UPDATE SCHEMA & MASTER DATA (KEMENKES PNPK 2019 STROKE)
-- File ini dibuat agar sesuai dengan Flutter UI Anda yang 
-- menggunakan tipe data UUID (bukan BigInt).
-- ==========================================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================================
-- 1. PENYESUAIAN TABEL YANG SUDAH ADA
-- ==========================================
-- Menambahkan kolom 'phase' dan 'time_of_day' ke tabel latihan 
-- agar sesuai dengan panduan Kemenkes (Fase 1, 2, 3)
ALTER TABLE public.rehab_exercises ADD COLUMN IF NOT EXISTS phase integer DEFAULT 1;
ALTER TABLE public.rehab_exercises ADD COLUMN IF NOT EXISTS time_of_day text;

-- ==========================================
-- 2. TABEL BARU: MASTER OBAT STROKE
-- (Menjadi referensi saat pasien menambah pengingat obat)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.master_medications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  category text,
  name text NOT NULL,
  description text,
  CONSTRAINT master_medications_pkey PRIMARY KEY (id)
);

-- ==========================================
-- 3. TABEL BARU: KUIS EVALUASI FASE REHAB
-- ==========================================
CREATE TABLE IF NOT EXISTS public.rehab_quizzes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id),
  from_phase integer,
  to_phase integer,
  total_score integer,
  passed boolean,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT rehab_quizzes_pkey PRIMARY KEY (id)
);

-- Hapus data master lama jika ingin di-reset
TRUNCATE TABLE public.master_medications CASCADE;
-- Jangan truncate rehab_exercises jika user sudah punya log, tapi kita update data master saja
-- Hapus data dummy sebelumnya khusus untuk exercises agar tidak dobel
DELETE FROM public.rehab_exercises; 

-- ==========================================
-- INSERT DATA OBAT STROKE (PNPK 2019)
-- ==========================================
INSERT INTO public.master_medications (category, name, description) VALUES
('Antiplatelet', 'Aspirin', 'Pencegahan sekunder stroke'),
('Antiplatelet', 'Clopidogrel', 'Alternatif bila alergi aspirin'),
('Antiplatelet', 'Dipiridamol', 'Kombinasi dengan aspirin'),
('Antiplatelet', 'Aspirin + Dipiridamol', 'Tablet kombinasi Pencegahan sekunder'),
('Antikoagulan', 'Warfarin', 'Vitamin K antagonist untuk stroke kardioemboli'),
('Antikoagulan', 'Dabigatran', 'NOAC'),
('Antikoagulan', 'Apixaban', 'NOAC'),
('Antikoagulan', 'Rivaroxaban', 'NOAC'),
('Antihipertensi', 'Captopril', 'ACE inhibitor'),
('Antihipertensi', 'Lisinopril', 'ACE inhibitor'),
('Antihipertensi', 'Amlodipin', 'Calcium channel blocker'),
('Antihipertensi', 'Diltiazem', 'Calcium channel blocker'),
('Penurun Lipid', 'Simvastatin', 'Statin HMG-CoA reductase inhibitor'),
('Penurun Lipid', 'Atorvastatin', 'Statin HMG-CoA reductase inhibitor'),
('Antiepileptik', 'Karbamazepin', 'Digunakan bila terjadi kejang setelah stroke'),
('Antiepileptik', 'Fenitoin', 'Digunakan bila terjadi kejang setelah stroke'),
('Nyeri Neuropatik', 'Amitriptilin', 'Antidepresan trisiklik pasca-stroke'),
('Nyeri Neuropatik', 'Lamotrigin', 'Antikonvulsan pasca-stroke'),
('Nyeri Neuropatik', 'Gabapentin', 'Antikonvulsan pasca-stroke'),
('Laksatif', 'Senna', 'Laksatif stimulant (sulit BAB akibat imobilisasi)'),
('Laksatif', 'Laktulosa', 'Laksatif osmotik'),
('Laksatif', 'Polyethylene glycol', 'Laksatif osmotik'),
('Pencegahan Lain', 'Hydroxyurea', 'Mengurangi risiko stroke pada Sickle Cell Disease');

-- ==========================================
-- INSERT DATA REHAB EXERCISES BERDASARKAN FASE
-- ==========================================
/* FASE 1 (7-14 Hari) */
INSERT INTO public.rehab_exercises (id, phase, time_of_day, name, category, instructions, media_url) VALUES
(gen_random_uuid(), 1, 'Pagi', 'Duduk di Tepi Tempat Tidur', 'Gerak Dasar', '["Miringkan badan ke samping", "Turunkan kaki ke lantai", "Dorong badan dengan tangan", "Duduk tegak, kaki menapak lantai"]', 'Lakukan 1-2 menit'),
(gen_random_uuid(), 1, 'Pagi', 'Meraih Benda di Depan', 'Motorik Kasar', '["Duduk tegak", "Letakkan benda ringan di depan", "Raih perlahan, lalu kembalikan"]', '5-8 Kali'),
(gen_random_uuid(), 1, 'Pagi', 'Gerakan Seperti Menyeka Badan', 'Mobilitas', '["Duduk santai", "Gerakkan tangan seperti mengusap lengan & dada"]', 'Lakukan 1-2 menit'),
(gen_random_uuid(), 1, 'Pagi', 'Gerakan kaki menekuk dan lurus', 'Motorik Kasar', '["Dalam posisi berbaring, lutut menekuk dan diluruskan"]', '8 Kali'),
(gen_random_uuid(), 1, 'Pagi', 'Latihan Pernapasan (Pagi)', 'Pernafasan', '["Tarik nafas melalui hidung", "Tahan 2 detik", "Buang melalui mulut perlahan"]', '5 Kali'),

(gen_random_uuid(), 1, 'Siang', 'Duduk Tegak di Kursi', 'Postur', '["Duduk di kursi kokoh", "Punggung lurus", "Kaki menapak lantai"]', '3 Menit'),
(gen_random_uuid(), 1, 'Siang', 'Berdiri dengan Pegangan', 'Keseimbangan', '["Pegang sandaran kursi/meja", "Berdiri perlahan", "Tahan posisi selama 1 menit"]', '2 Kali'),
(gen_random_uuid(), 1, 'Siang', 'Memindahkan Benda Ringan', 'Motorik Halus', '["Ambil benda ringan", "Pindahkan ke tempat lain"]', '5 Menit'),
(gen_random_uuid(), 1, 'Siang', 'Putar Pergelangan Kaki', 'Sendi', '["Putar pergelangan kaki searah dan berlawanan arah jarum jam"]', '8 Kali'),
(gen_random_uuid(), 1, 'Siang', 'Latihan Pernapasan (Siang)', 'Pernafasan', '["Tarik nafas melalui hidung", "Tahan 2 detik", "Buang melalui mulut perlahan"]', '5 Kali'),

(gen_random_uuid(), 1, 'Sore', 'Meremas Handuk', 'Motorik Halus', '["Pegang handuk", "Remas dan lepaskan"]', '10 Kali'),
(gen_random_uuid(), 1, 'Sore', 'Gerakan Seperti Makan', 'Kemandirian', '["Gerakkan tangan seperti menyuap", "Lakukan perlahan"]', '5-8 Kali'),
(gen_random_uuid(), 1, 'Sore', 'Berjinjit', 'Keseimbangan', '["Duduk baik di kursi dengan kaki menapak", "Angkat tumit, sehingga ujung jari kaki dilantai"]', '10 Kali'),
(gen_random_uuid(), 1, 'Sore', 'Latihan Pernapasan (Sore)', 'Pernafasan', '["Tarik nafas melalui hidung", "Tahan 2 detik", "Buang melalui mulut perlahan"]', '5 Kali');


/* FASE 2 (2-4 Minggu) */
INSERT INTO public.rehab_exercises (id, phase, time_of_day, name, category, instructions, media_url) VALUES
(gen_random_uuid(), 2, 'Pagi', 'Duduk -> Berdiri dari Kursi', 'Mobilitas', '["Duduk di kursi", "Condongkan badan ke depan", "Berdiri perlahan"]', '5-10 Kali'),
(gen_random_uuid(), 2, 'Pagi', 'Simulasi Memakai Baju', 'Kemandirian', '["Gerakkan tangan seperti memakai baju"]', '5 Menit'),
(gen_random_uuid(), 2, 'Pagi', 'Simulasi Aktivitas Makan', 'Kemandirian', '["Gerakkan tangan seperti menyuap"]', '10 Kali'),
(gen_random_uuid(), 2, 'Pagi', 'Mengambil Barang Samping', 'Mobilitas', '["Ambil barang yang berada di samping kanan/kiri", "Pindahkan ke tempat lainnya"]', '8-10 Kali'),

(gen_random_uuid(), 2, 'Siang', 'Jalan di Dalam Rumah', 'Keseimbangan', '["Berjalan perlahan", "Gunakan alat bantu jika diperlukan"]', '5-10 Menit'),
(gen_random_uuid(), 2, 'Siang', 'Membawa Benda Ringan', 'Keseimbangan', '["Bawa gelas/piring/benda ringan", "Berjalan stabil"]', '5 Menit'),
(gen_random_uuid(), 2, 'Siang', 'Menoleh Kanan & Kiri', 'Sendi Leher', '["Putar kepala perlahan kearah kiri dan kanan"]', '8 Kali'),

(gen_random_uuid(), 2, 'Sore', 'Memindahkan Benda Kecil', 'Motorik Halus', '["Ambil koin/kancing", "Pindahkan ke dalam wadah"]', '5 Menit'),
(gen_random_uuid(), 2, 'Sore', 'Meremas Bola', 'Kekuatan Otot', '["Remas bola karet pelan-pelan"]', '10-15 Kali');


/* FASE 3 (4-8 Minggu) */
INSERT INTO public.rehab_exercises (id, phase, time_of_day, name, category, instructions, media_url) VALUES
(gen_random_uuid(), 3, 'Pagi', 'Menyapu Ringan / Lap Meja', 'Aktivitas Domestik', '["Gunakan alat sedanya", "Lakukan pelan tidak berlebihan"]', '5-10 Menit'),
(gen_random_uuid(), 3, 'Pagi', 'Mengambil & Menyimpan Barang Berdiri', 'Keseimbangan', '["Ambil suatu barang dari tempat rendah", "Simpan ke tempat semula"]', '5 Menit'),

(gen_random_uuid(), 3, 'Siang', 'Jalan Lebih Jauh', 'Daya Tahan', '["Jalan ke luar rumah atau jarak lebih panjang"]', '10-15 Menit'),
(gen_random_uuid(), 3, 'Siang', 'Naik Tangga (Jika Aman)', 'Mobilitas Lanjut', '["Pegang pegangan tangga", "Naik dan turun perlahan"]', '3-5 Kali'),

(gen_random_uuid(), 3, 'Sore', 'Menulis / Mengancingkan Baju', 'Motorik Halus Lanjut', '["Duduk tegak", "Lakukan perlahan"]', '5-10 Menit');

-- Selesai
