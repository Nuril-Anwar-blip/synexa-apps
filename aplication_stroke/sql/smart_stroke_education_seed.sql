-- ============================================================
-- SMART STROKE – Education content seed
-- Jalankan setelah smart_stroke_seed_pnpk.sql
-- ============================================================

INSERT INTO education_contents (
  title, slug, category, content_type, summary, content, author, source, tags, is_published, published_at
) VALUES
(
  'Apa Itu Stroke?',
  'apa-itu-stroke',
  'lainnya',
  'article',
  'Stroke terjadi ketika aliran darah ke otak terganggu. Kenali jenis dan dampaknya.',
  E'Stroke adalah kondisi darurat medis ketika suplai darah ke otak berkurang atau terhenti.\n\nStroke Iskemik (±80%): terjadi karena penyumbatan pembuluh darah oleh bekuan atau plak.\nStroke Hemoragik (±20%): terjadi karena pecahnya pembuluh darah di otak.\n\nTanpa oksigen, sel otak mulai rusak dalam hitungan menit. Penanganan cepat sangat menentukan hasil pemulihan.',
  'Tim Smart Stroke',
  'Kemenkes RI',
  ARRAY['stroke','edukasi','dasar'],
  TRUE,
  NOW()
),
(
  'Metode FAST: Kenali Stroke dalam Detik',
  'metode-fast-stroke',
  'penanganan',
  'article',
  'Gunakan FAST untuk mengenali tanda stroke dan segera hubungi 119.',
  E'F – Face (Wajah): Minta senyum. Apakah wajah mencong?\nA – Arm (Lengan): Angkat kedua tangan. Apakah satu lengan melemah?\nS – Speech (Bicara): Minta ulangi kalimat. Apakah bicara pelo?\nT – Time (Waktu): Jika ada salah satu tanda, SEGERA hubungi 119.\n\nJangan menunggu gejala membaik. Catat waktu pertama gejala muncul untuk membantu tim medis.',
  'Tim Smart Stroke',
  'American Stroke Association',
  ARRAY['fast','gejala','darurat'],
  TRUE,
  NOW()
),
(
  'Tanda Stroke Selain FAST',
  'tanda-stroke-lainnya',
  'penanganan',
  'article',
  'Gejala lain yang perlu diwaspadai selain metode FAST.',
  E'• Mati rasa mendadak di wajah, lengan, atau kaki\n• Kebingungan atau sulit memahami pembicaraan\n• Gangguan penglihatan pada satu atau kedua mata\n• Sakit kepala hebat tanpa sebab jelas\n• Kehilangan keseimbangan atau koordinasi\n• TIA (mini stroke): gejala stroke sementara — jangan diabaikan!',
  'Tim Smart Stroke',
  NULL,
  ARRAY['gejala','tanda','stroke'],
  TRUE,
  NOW()
),
(
  '7 Cara Mencegah Stroke',
  'cara-mencegah-stroke',
  'pencegahan',
  'article',
  'Langkah praktis menurunkan risiko stroke sejak dini.',
  E'1. Kontrol tekanan darah (target <130/80 mmHg)\n2. Kelola diabetes dan kolesterol\n3. Berhenti merokok\n4. Olahraga minimal 150 menit/minggu\n5. Pola makan rendah garam dan lemak jenuh\n6. Batasi alkohol\n7. Cek kesehatan rutin minimal 1× setahun\n\nSekitar 87% stroke dapat dicegah dengan mengelola faktor risiko.',
  'Tim Smart Stroke',
  'WHO',
  ARRAY['pencegahan','risiko','gaya-hidup'],
  TRUE,
  NOW()
),
(
  'Faktor Risiko Stroke yang Bisa Dikontrol',
  'faktor-risiko-stroke',
  'pencegahan',
  'article',
  'Hipertensi, diabetes, merokok, dan obesitas adalah risiko utama yang bisa diubah.',
  E'Faktor risiko yang dapat dikontrol:\n• Hipertensi\n• Diabetes\n• Kolesterol tinggi\n• Merokok\n• Obesitas\n• Atrial fibrilasi\n\nFaktor yang tidak dapat diubah: usia >55 tahun dan riwayat keluarga. Meski demikian, gaya hidup sehat tetap sangat membantu.',
  'Tim Smart Stroke',
  NULL,
  ARRAY['risiko','hipertensi','diabetes'],
  TRUE,
  NOW()
),
(
  'Fase Pemulihan Pasca Stroke',
  'fase-pemulihan-stroke',
  'rehabilitasi',
  'article',
  'Pahami fase akut, subakut, dan kronis untuk optimalkan rehabilitasi.',
  E'Fase Akut (0–7 hari): Stabilisasi di rumah sakit, pencegahan komplikasi.\n\nFase Subakut (7 hari – 3 bulan): Rehabilitasi intensif — fisioterapi, terapi wicara, terapi okupasi. Ini periode emas pemulihan.\n\nFase Kronis (>3 bulan): Pemeliharaan fungsi dan adaptasi gaya hidup. Otak tetap bisa beradaptasi (neuroplastisitas) hingga bertahun-tahun.',
  'Tim Smart Stroke',
  NULL,
  ARRAY['rehabilitasi','pemulihan','fase'],
  TRUE,
  NOW()
),
(
  'Latihan Rehabilitasi di Rumah',
  'latihan-rehabilitasi-rumah',
  'olahraga',
  'article',
  'Gerakan aman yang bisa dilakukan pasien stroke di rumah dengan pengawasan.',
  E'• Latihan range of motion untuk sendi yang kaku\n• Latihan keseimbangan dengan pegangan kuat\n• Latihan berjalan bertahap dengan alat bantu\n• Latihan fine motor: menggenggam, menulis\n\nSelalu konsultasikan dengan fisioterapis sebelum memulai program baru. Konsistensi lebih penting daripada intensitas.',
  'Tim Smart Stroke',
  NULL,
  ARRAY['olahraga','rehab','latihan'],
  TRUE,
  NOW()
),
(
  'Nutrisi Sehat untuk Pencegahan Stroke Ulang',
  'nutrisi-pencegahan-stroke',
  'nutrisi',
  'article',
  'Pola makan yang mendukung pemulihan dan mencegah stroke berulang.',
  E'• Perbanyak sayur, buah, dan biji-bijian utuh\n• Pilih protein rendah lemak: ikan, ayam tanpa kulit, kacang-kacangan\n• Batasi garam (<5g/hari)\n• Hindari makanan olahan dan tinggi lemak jenuh\n• Cukupi kebutuhan air\n• Diet DASH dan Mediterranean terbukti baik untuk kesehatan jantung dan otak',
  'Tim Smart Stroke',
  'Kemenkes RI',
  ARRAY['nutrisi','diet','makanan'],
  TRUE,
  NOW()
)
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title,
  category = EXCLUDED.category,
  summary = EXCLUDED.summary,
  content = EXCLUDED.content,
  tags = EXCLUDED.tags,
  is_published = EXCLUDED.is_published,
  published_at = EXCLUDED.published_at;
