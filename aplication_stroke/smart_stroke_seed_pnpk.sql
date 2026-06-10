-- ============================================================
-- SMART STROKE – Seed PNPK 2019 (Obat + Rehab Fase 1–3 + Quiz)
-- Jalankan di Supabase SQL Editor SETELAH smart_stroke_schema.sql
-- ============================================================

-- Kolom tambahan untuk latihan per sesi (pagi/siang/sore)
ALTER TABLE rehab_exercises
  ADD COLUMN IF NOT EXISTS session_period TEXT
    CHECK (session_period IN ('pagi','siang','sore')),
  ADD COLUMN IF NOT EXISTS duration_text TEXT;

-- ============================================================
-- OBAT STROKE ORAL (PNPK 2019)
-- ============================================================
DELETE FROM medications;

INSERT INTO medications (name, generic_name, category, dosage_form, strength, description) VALUES
  ('Aspirin',               'Asam Asetilsalisilat',  'antiplatelet',        'tablet', '80mg',   'Pencegahan sekunder stroke iskemik non-kardioemboli'),
  ('Clopidogrel',           'Clopidogrel',           'antiplatelet',        'tablet', '75mg',   'Alternatif bila alergi aspirin'),
  ('Dipiridamol',           'Dipiridamol',           'antiplatelet',        'tablet', '200mg',  'Kombinasi dengan aspirin'),
  ('Aspirin + Dipiridamol', 'Asam Asetilsalisilat + Dipiridamol', 'antiplatelet', 'tablet', '25/200mg', 'Pencegahan sekunder stroke'),
  ('Warfarin',              'Warfarin Natrium',      'antikoagulan',        'tablet', '2mg',    'Stroke kardioemboli — Vitamin K antagonist'),
  ('Dabigatran',            'Dabigatran Etexilat',   'antikoagulan',        'kapsul', '110mg',  'Stroke kardioemboli — NOAC'),
  ('Apixaban',              'Apixaban',              'antikoagulan',        'tablet', '5mg',    'Stroke kardioemboli — NOAC'),
  ('Rivaroxaban',           'Rivaroxaban',           'antikoagulan',        'tablet', '20mg',   'Stroke kardioemboli — NOAC'),
  ('Captopril',             'Captopril',             'antihipertensi',      'tablet', '25mg',   'ACE inhibitor'),
  ('Lisinopril',            'Lisinopril',            'antihipertensi',      'tablet', '10mg',   'ACE inhibitor'),
  ('Amlodipin',             'Amlodipine Besilat',    'antihipertensi',      'tablet', '5mg',    'Calcium channel blocker'),
  ('Diltiazem',             'Diltiazem',             'antihipertensi',      'tablet', '60mg',   'Calcium channel blocker'),
  ('Simvastatin',           'Simvastatin',           'statin',              'tablet', '20mg',   'Pencegahan stroke pada dislipidemia'),
  ('Atorvastatin',          'Atorvastatin Kalsium',  'statin',              'tablet', '20mg',   'Pencegahan stroke pada dislipidemia'),
  ('Karbamazepin',          'Karbamazepin',          'antiepileptik',       'tablet', '200mg',  'Kejang pasca stroke'),
  ('Fenitoin',              'Fenitoin',              'antiepileptik',       'tablet', '100mg',  'Kejang pasca stroke'),
  ('Amitriptilin',          'Amitriptilin',          'nyeri_neuropatik',    'tablet', '25mg',   'Nyeri neuropatik pasca stroke'),
  ('Gabapentin',            'Gabapentin',            'nyeri_neuropatik',    'tablet', '300mg',  'Nyeri neuropatik pasca stroke'),
  ('Lamotrigin',            'Lamotrigin',            'nyeri_neuropatik',    'tablet', '25mg',   'Nyeri neuropatik pasca stroke'),
  ('Senna',                 'Sennosida',             'laksatif',            'tablet', '7.5mg',  'Konstipasi pasien stroke — stimulan'),
  ('Laktulosa',             'Laktulosa',             'laksatif',            'sirup',  '15mL',   'Konstipasi pasien stroke — osmotik'),
  ('Polyethylene glycol',   'Macrogol',              'laksatif',            'tablet', '17g',    'Konstipasi pasien stroke — osmotik'),
  ('Hydroxyurea',           'Hydroxyurea',           'pencegahan_risiko',   'kapsul', '500mg',  'Sickle cell — mengurangi risiko stroke');

-- ============================================================
-- FASE REHABILITASI (PNPK)
-- ============================================================
DELETE FROM rehab_quiz_questions;
DELETE FROM rehab_exercise_logs;
DELETE FROM rehab_exercises;
DELETE FROM rehab_phases;

INSERT INTO rehab_phases (phase_number, name, description, duration_weeks, required_score) VALUES
(1, 'Fase 1 (7–14 Hari)',
 'Latihan 10–15 menit/sesi. Tujuan: tubuh tetap bergerak, cegah kekakuan, latih duduk & gerak dasar. '
 'Ingat: gerakan pelan, gunakan pegangan kokoh, alas kaki anti-selip, hentikan bila pusing/sesak/nyeri dada.',
 2, 7),
(2, 'Fase 2 (2–4 Minggu)',
 'Latihan 10–20 menit/sesi. Tujuan: gerak aktif, cegah kekakuan, latihan ADL, kemandirian. '
 'Aturan keselamatan sama seperti fase 1.',
 4, 9),
(3, 'Fase 3 (4–8 Minggu)',
 'Latihan 20–25 menit/sesi. Tujuan: kemandirian penuh & kembali ke rutinitas. '
 'Aturan keselamatan sama seperti fase 1. Fokus menjaga keamanan & konsistensi.',
 8, 6);

-- ============================================================
-- LATIHAN FASE 1
-- ============================================================
INSERT INTO rehab_exercises (phase_id, name, instructions, duration_text, duration_seconds, repetitions, session_period, category, difficulty, order_index)
SELECT p.id, v.name, v.instructions, v.duration_text, v.duration_seconds, v.repetitions, v.session_period, 'motorik', 'mudah', v.ord
FROM rehab_phases p,
(VALUES
  -- PAGI
  ('Duduk di Tepi Tempat Tidur', E'Miringkan badan ke samping\nTurunkan kaki ke lantai\nDorong badan dengan tangan\nDuduk tegak, kaki menapak lantai', '1–2 menit', 90, NULL::int, 'pagi', 1),
  ('Meraih Benda di Depan', E'Duduk tegak\nLetakkan botol/handuk di depan\nRaih perlahan, lalu kembalikan', '5–8 kali', 300, 6, 'pagi', 2),
  ('Gerakan Seperti Menyeka Badan', E'Duduk santai\nGerakkan tangan seperti mengusap lengan & dada', '1–2 menit', 90, NULL, 'pagi', 3),
  ('Gerakan Kaki Menekuk dan Lurus', E'Dalam posisi berbaring\nLutut menekuk dan diluruskan', '8 kali', 240, 8, 'pagi', 4),
  ('Latihan Pernapasan', E'Tarik napas melalui hidung\nTahan 2 detik\nBuang melalui mulut dengan perlahan', '5 kali', 150, 5, 'pagi', 5),
  -- SIANG
  ('Duduk Tegak di Kursi', E'Duduk di kursi kokoh\nPunggung lurus\nKaki menapak lantai', '3 menit', 180, NULL, 'siang', 6),
  ('Berdiri dengan Pegangan', E'Pegang sandaran kursi/meja\nBerdiri perlahan\nTahan posisi', '2 kali', 180, 2, 'siang', 7),
  ('Memindahkan Benda Ringan', E'Ambil benda ringan\nPindahkan ke tempat lain', '5 menit', 300, NULL, 'siang', 8),
  ('Putar Pergelangan Kaki', E'Putar pergelangan kaki searah dan berlawanan arah jarum jam', '8 kali', 180, 8, 'siang', 9),
  ('Latihan Pernapasan (Siang)', E'Tarik napas melalui hidung\nTahan 2 detik\nBuang melalui mulut dengan perlahan', '5 kali', 150, 5, 'siang', 10),
  -- SORE
  ('Meremas Handuk', E'Pegang handuk\nRemas dan lepaskan', '10 kali', 180, 10, 'sore', 11),
  ('Gerakan Seperti Makan', E'Gerakkan tangan seperti menyuap\nLakukan perlahan', '5–8 kali', 240, 6, 'sore', 12),
  ('Berjinjit', E'Duduk baik di kursi atau tepi bed\nAngkat tumit, ujung jari kaki tetap di lantai', '10 kali', 180, 10, 'sore', 13),
  ('Latihan Pernapasan (Sore)', E'Tarik napas melalui hidung\nTahan 2 detik\nBuang melalui mulut dengan perlahan', '5 kali', 150, 5, 'sore', 14)
) AS v(name, instructions, duration_text, duration_seconds, repetitions, session_period, ord)
WHERE p.phase_number = 1;

-- ============================================================
-- LATIHAN FASE 2
-- ============================================================
INSERT INTO rehab_exercises (phase_id, name, instructions, duration_text, duration_seconds, repetitions, session_period, category, difficulty, order_index)
SELECT p.id, v.name, v.instructions, v.duration_text, v.duration_seconds, v.repetitions, v.session_period, 'motorik', 'sedang', v.ord
FROM rehab_phases p,
(VALUES
  ('Duduk → Berdiri dari Kursi', E'Duduk di kursi\nCondongkan badan ke depan\nBerdiri perlahan', '5–10 kali', 420, 8, 'pagi', 1),
  ('Simulasi Memakai Baju', E'Gerakkan tangan seperti memakai baju', '5 menit', 300, NULL, 'pagi', 2),
  ('Simulasi Aktivitas Makan', E'Gerakkan tangan seperti menyuap', '10 kali', 240, 10, 'pagi', 3),
  ('Mengambil Barang Samping', E'Ambil barang di samping kanan/kiri\nPindahkan ke tempat lain', '8–10 kali', 300, 9, 'pagi', 4),
  ('Jalan di Dalam Rumah', E'Gunakan alat bantu jika diperlukan', '5–10 menit', 420, NULL, 'siang', 5),
  ('Membawa Benda Ringan', E'Bawa gelas/piring sambil berjalan', '5 menit', 300, NULL, 'siang', 6),
  ('Menoleh Kanan & Kiri', E'Putar kepala perlahan ke kiri dan kanan', '8 kali', 180, 8, 'siang', 7),
  ('Memindahkan Benda Kecil', E'Ambil koin/kancing\nPindahkan ke dalam wadah', '5 menit', 300, NULL, 'sore', 8),
  ('Meremas Bola/Handuk', E'Remas bola atau handuk dengan kuat lalu lepaskan', '10–15 kali', 240, 12, 'sore', 9)
) AS v(name, instructions, duration_text, duration_seconds, repetitions, session_period, ord)
WHERE p.phase_number = 2;

-- ============================================================
-- LATIHAN FASE 3
-- ============================================================
INSERT INTO rehab_exercises (phase_id, name, instructions, duration_text, duration_seconds, repetitions, session_period, category, difficulty, order_index)
SELECT p.id, v.name, v.instructions, v.duration_text, v.duration_seconds, v.repetitions, v.session_period, 'motorik', 'sedang', v.ord
FROM rehab_phases p,
(VALUES
  ('Menyapu Ringan / Lap Meja', E'Lakukan gerakan menyapu atau mengelap meja secara ringan', '5–10 menit', 420, NULL, 'pagi', 1),
  ('Mengambil & Menyimpan Barang', E'Ambil barang dari tempat rendah\nSimpan kembali ke tempat semula', '5 menit', 300, NULL, 'pagi', 2),
  ('Jalan Lebih Jauh', E'Berjalan di area yang aman dengan tempo pelan', '10–15 menit', 750, NULL, 'siang', 3),
  ('Naik Tangga (bila aman)', E'Pegang pengangan tangga\nNaik dan turun perlahan', '3–5 kali', 360, 4, 'siang', 4),
  ('Menulis / Mengancingkan Baju', E'Duduk tegak dan nyaman\nLakukan perlahan', '5–10 menit', 420, NULL, 'sore', 5)
) AS v(name, instructions, duration_text, duration_seconds, repetitions, session_period, ord)
WHERE p.phase_number = 3;

-- ============================================================
-- QUIZ MINGGUAN (self-assessment PNPK)
-- Skor: 😊=2 | 😐=1 | 😟=0
-- ============================================================
INSERT INTO rehab_quiz_questions (phase_id, question_text, question_type, options, correct_answer, explanation, points, order_index)
SELECT p.id, q.text, 'multiple_choice', q.opts::jsonb, 'self_assessment', q.expl, 10, q.ord
FROM rehab_phases p,
(VALUES
  -- Fase 1 → 2 (skor maks 10, lulus ≥7, tanpa 😟 pada duduk & aman, konsisten 3 hari)
  (1, 'Apakah hari ini bisa duduk tegak di kursi / tepi tempat tidur selama 5 menit?',
   '[{"key":"good","text":"😊 Bisa","points":2},{"key":"ok","text":"😐 Bisa tapi masih dibantu","points":1},{"key":"bad","text":"😟 Belum bisa","points":0}]',
   'Lulus fase 1→2: skor ≥7, tidak ada 😟 pada pertanyaan duduk & aman, konsisten 3 hari.', 1),
  (1, 'Saat bangun dari tempat tidur, apakah terasa aman?',
   '[{"key":"good","text":"😊 Aman","points":2},{"key":"ok","text":"😐 Kadang goyah","points":1},{"key":"bad","text":"😟 Takut jatuh","points":0}]',
   'Pertanyaan kunci keamanan — jawaban 😟 menghalangi naik fase.', 2),
  (1, 'Apakah bisa makan atau minum sendiri?',
   '[{"key":"good","text":"😊 Bisa","points":2},{"key":"ok","text":"😐 Sedikit dibantu","points":1},{"key":"bad","text":"😟 Belum bisa","points":0}]',
   NULL, 3),
  (1, 'Apakah bisa meraih benda di depan (misalnya botol)?',
   '[{"key":"good","text":"😊 Bisa","points":2},{"key":"ok","text":"😐 Pelan / dibantu","points":1},{"key":"bad","text":"😟 Belum bisa","points":0}]',
   NULL, 4),
  (1, 'Setelah latihan, badan terasa:',
   '[{"key":"good","text":"😊 Enak / ringan","points":2},{"key":"ok","text":"😐 Biasa saja","points":1},{"key":"bad","text":"😟 Capek / pusing","points":0}]',
   'Hentikan latihan bila pusing, sesak, atau nyeri dada.', 5),
  -- Fase 2 → 3 (skor maks 12, lulus ≥9, tanpa 😟 pada jatuh, konsisten 5–7 hari)
  (2, 'Apakah bisa berdiri dari kursi 10 kali tanpa berhenti lama?',
   '[{"key":"good","text":"😊 Bisa","points":2},{"key":"ok","text":"😐 Bisa tapi capek","points":1},{"key":"bad","text":"😟 Belum bisa","points":0}]',
   'Lulus fase 2→3: skor ≥9, tidak ada 😟 pada pertanyaan jatuh, konsisten 5–7 hari.', 1),
  (2, 'Apakah bisa berjalan di rumah ±5 menit?',
   '[{"key":"good","text":"😊 Bisa","points":2},{"key":"ok","text":"😐 Pelan / berpegangan","points":1},{"key":"bad","text":"😟 Belum bisa","points":0}]',
   NULL, 2),
  (2, 'Apakah bisa mandi atau berpakaian dengan sedikit bantuan?',
   '[{"key":"good","text":"😊 Bisa","points":2},{"key":"ok","text":"😐 Masih banyak dibantu","points":1},{"key":"bad","text":"😟 Belum bisa","points":0}]',
   NULL, 3),
  (2, 'Apakah bisa membawa benda ringan sambil berjalan?',
   '[{"key":"good","text":"😊 Bisa","points":2},{"key":"ok","text":"😐 Pelan","points":1},{"key":"bad","text":"😟 Belum bisa","points":0}]',
   NULL, 4),
  (2, 'Apakah sering hampir jatuh hari ini?',
   '[{"key":"good","text":"😊 Tidak","points":2},{"key":"ok","text":"😐 Hampir","points":1},{"key":"bad","text":"😟 Ya","points":0}]',
   'Pertanyaan kunci keamanan jatuh.', 5),
  (2, 'Napas kembali normal setelah latihan dalam:',
   '[{"key":"good","text":"😊 < 5 menit","points":2},{"key":"ok","text":"😐 5–10 menit","points":1},{"key":"bad","text":"😟 > 10 menit","points":0}]',
   NULL, 6),
  -- Fase 3 (skor maks 8, ≥6 lanjut fase 3, ≤4 turun ke fase 2)
  (3, 'Apakah hari ini bisa melakukan aktivitas rumah ringan (menyapu, lap meja)?',
   '[{"key":"good","text":"😊 Bisa","points":2},{"key":"ok","text":"😐 Sebagian","points":1},{"key":"bad","text":"😟 Tidak","points":0}]',
   'Fase 3: skor ≥6 lanjut, skor ≤4 kurangi intensitas / kembali fase 2.', 1),
  (3, 'Apakah bisa berjalan lebih dari 10 menit?',
   '[{"key":"good","text":"😊 Bisa","points":2},{"key":"ok","text":"😐 Perlu istirahat","points":1},{"key":"bad","text":"😟 Tidak","points":0}]',
   NULL, 2),
  (3, 'Apakah hari ini merasa aman saat bergerak?',
   '[{"key":"good","text":"😊 Aman","points":2},{"key":"ok","text":"😐 Kadang takut","points":1},{"key":"bad","text":"😟 Takut jatuh","points":0}]',
   NULL, 3),
  (3, 'Setelah latihan, badan terasa:',
   '[{"key":"good","text":"😊 Lebih segar","points":2},{"key":"ok","text":"😐 Biasa","points":1},{"key":"bad","text":"😟 Lelah sekali","points":0}]',
   NULL, 4)
) AS q(phase_num, text, opts, expl, ord)
WHERE p.phase_number = q.phase_num;

-- Edukasi obat di education_contents
INSERT INTO education_contents (title, slug, category, content_type, summary, content, source, is_published, published_at)
VALUES
(
  'Obat Stroke Oral PNPK 2019',
  'obat-stroke-pnpk-2019',
  'obat',
  'article',
  'Ringkasan terapi farmakologis stroke berdasarkan PNPK 2019 Kemenkes.',
  E'Antiplatelet: Aspirin, Clopidogrel, Dipiridamol.\nAntikoagulan: Warfarin, Dabigatran, Apixaban, Rivaroxaban.\nAntihipertensi: Captopril, Lisinopril, Amlodipin, Diltiazem.\nStatin untuk dislipidemia.\nAntiepileptik bila kejang pasca stroke.\nObat nyeri neuropatik: Amitriptilin, Gabapentin, Lamotrigin.\nLaksatif: Senna, Laktulosa, PEG.\nHydroxyurea untuk sickle cell disease.',
  'Kemenkes PNPK 2019',
  TRUE,
  NOW()
)
ON CONFLICT (slug) DO UPDATE SET
  content = EXCLUDED.content,
  summary = EXCLUDED.summary;
