# Smart Stroke — Skrip SQL

Jalankan skrip di **Supabase Dashboard → SQL Editor** sesuai urutan di bawah.

> **Database sudah pernah di-setup?** Lewati `smart_stroke_schema.sql` (akan error *relation already exists*). Lanjutkan dari file yang belum dijalankan, atau jalankan ulang file seed/extension saja.

## Urutan eksekusi

| No | File | Keterangan |
|----|------|------------|
| 1 | `smart_stroke_schema.sql` | Schema utama (tabel, RLS dasar, trigger) |
| 2 | `smart_stroke_admin_extension.sql` | Tabel & kebijakan admin |
| 3 | `smart_stroke_seed_pnpk.sql` | Data PNPK (rehab, kuis, edukasi obat) |
| 4 | `smart_stroke_seed_dummy.sql` | Data dummy lengkap — **wajib setelah baris 1–3** |
| 5 | `smart_stroke_seed_auth.sql` | Akun login Supabase Auth (wajib untuk login) |
| 6 | `smart_stroke_storage_setup.sql` | Bucket storage untuk upload gambar komunitas |
| 7 | `smart_stroke_staff_presence.sql` | Status online apoteker/dokter |
| 8 | `smart_stroke_admin_rls_extension.sql` | RLS tambahan untuk admin |
| 9 | `smart_stroke_medication_stock.sql` | Stok obat apoteker |
| 10 | `smart_stroke_chat_read_receipts.sql` | Read receipt chat (centang biru) |
| 11 | `smart_stroke_push_notifications.sql` | Kolom FCM token + kebijakan dokter |
| 12 | `smart_stroke_doctor_mobile.sql` | RLS mobile dokter |
| 13 | `smart_stroke_education_seed.sql` | Konten edukasi stroke |

## Realtime (wajib untuk chat & notifikasi)

Di **Supabase Dashboard → Database → Replication**, aktifkan replication untuk:

- `messages`
- `chat_rooms`
- `notifications`

## Catatan

- Skrip seed (`seed_dummy`, `seed_auth`, `education_seed`) aman dijalankan ulang.
- Password semua akun dummy: `SmartStroke123!` (lihat `smart_stroke_seed_auth.sql`).
- Kode undangan registrasi: `APOTEK01`, `APOTEK02`, `DOKTOR01`, `DOKTOR02` (lihat `smart_stroke_seed_dummy.sql`).
