# Smart Stroke

Aplikasi pemulihan stroke berbasis Flutter dengan backend Supabase. Mendukung peran **Pasien**, **Apoteker**, **Dokter**, dan **Admin Desktop**.

## Prasyarat

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (SDK `>=3.10.0`)
- Akun [Supabase](https://supabase.com) (project aktif)
- **Android:** device/emulator + `google-services.json` di `android/app/` (untuk push notification)
- **Windows:** Visual Studio dengan workload *Desktop development with C++* (untuk admin desktop)

## Setup proyek

### 1. Clone & dependensi

```bash
cd aplication_stroke
flutter pub get
```

### 2. Environment (`.env`)

Buat file `.env` di root folder `aplication_stroke/`:

```env
SUPABASE_URL=https://<project-id>.supabase.co
SUPABASE_ANON_KEY=<anon-key-anda>
```

Opsional (alias yang juga didukung):

```env
SUPABASE_PUBLISHABLE_KEY=<anon-key-anda>
```

> Jangan commit file `.env` ke repository.

### 3. Database Supabase

Jalankan skrip SQL di folder [`sql/`](sql/) sesuai urutan di [`sql/README.md`](sql/README.md).

Ringkasan urutan:

1. `smart_stroke_schema.sql`
2. `smart_stroke_admin_extension.sql`
3. `smart_stroke_seed_pnpk.sql`
4. `smart_stroke_seed_dummy.sql`
5. `smart_stroke_seed_auth.sql`
6. `smart_stroke_storage_setup.sql`
7. `smart_stroke_staff_presence.sql`
8. `smart_stroke_admin_rls_extension.sql`
9. `smart_stroke_medication_stock.sql`
10. `smart_stroke_chat_read_receipts.sql`
11. `smart_stroke_push_notifications.sql`
12. `smart_stroke_doctor_mobile.sql`
13. `smart_stroke_education_seed.sql`

Aktifkan **Realtime** untuk tabel `messages`, `chat_rooms`, dan `notifications`.

---

## Cara menjalankan aplikasi

### Mobile (Pasien / Apoteker / Dokter)

```bash
cd aplication_stroke
flutter run
```

Pilih device Android/iOS saat diminta. Contoh target spesifik:

```bash
flutter run -d <device-id>
flutter devices          # lihat daftar device
```

**Alur setelah launch:** Splash → cek sesi login → arahkan ke dashboard sesuai peran.

| Peran | Layar tujuan |
|-------|----------------|
| Pasien | Home dashboard (`UnifiedMainScreen`) |
| Apoteker | Dashboard apoteker + chat konsultasi |
| Dokter | Dashboard dokter + daftar pasien |
| Admin | Diblokir di mobile (gunakan desktop) |

### Admin Desktop (Windows)

```bash
cd aplication_stroke
flutter run -t lib/main_admin.dart -d windows
```

Juga tersedia di macOS/Linux:

```bash
flutter run -t lib/main_admin.dart -d macos
flutter run -t lib/main_admin.dart -d linux
```

Login admin hanya melalui entry point `main_admin.dart`.

### Build release (opsional)

```bash
# APK Android
flutter build apk

# Windows admin
flutter build windows -t lib/main_admin.dart
```

---

## Akun dummy

**Password semua akun:** `SmartStroke123!`

### Admin

| Email | Keterangan |
|-------|------------|
| `admin@smartstroke.id` | Admin desktop (CMS, undangan, manajemen data) |

### Pasien

| Email | Nama |
|-------|------|
| `pasien.ahmad@email.com` | Ahmad Rizki |
| `pasien.dewi@email.com` | Dewi Lestari |
| `pasien.hasan@email.com` | Hasan Basri |

### Apoteker

| Email | Nama |
|-------|------|
| `apoteker.sari@farmasi.id` | Sari Wulandari |
| `apoteker.budi@farmasi.id` | Budi Santoso |

### Dokter

| Email | Nama |
|-------|------|
| `dr.andi@rsstroke.id` | dr. Andi Pratama |
| `dr.rina@rsstroke.id` | dr. Rina Kusuma |

### Kode undangan (registrasi baru)

Digunakan saat **Daftar sebagai Dokter** atau undangan apoteker dari admin:

| Kode | Peran | Status |
|------|-------|--------|
| `DOKTOR01` | Dokter | Aktif |
| `DOKTOR02` | Dokter | Aktif |
| `APOTEK01` | Apoteker | Aktif |
| `APOTEK02` | Apoteker | Aktif |

---

## Panduan penggunaan per peran

### Pasien (mobile)

1. Login dengan akun pasien.
2. **Home** — ringkasan kesehatan, obat hari ini, latihan, tenaga medis online.
3. **Obat** — pengingat obat terhubung Supabase.
4. **Kesehatan** — log tekanan darah, gula, dll.
5. **Rehab / Latihan** — program pemulihan & log sesi.
6. **Edukasi** — artikel stroke per kategori (tap untuk detail).
7. **Komunitas** — posting, like, komentar.
8. **Chat Apoteker** — konsultasi obat dengan read receipt.
9. **Notifikasi** — ikon lonceng di Home atau menu di Profil.
10. **Darurat** — panggilan 119 & log ke database.

### Apoteker (mobile)

1. Login dengan akun apoteker.
2. Dashboard daftar pasien & chat konsultasi realtime.
3. Balas pesan pasien (centang biru saat dibaca pasien).

### Dokter (mobile)

1. Login dengan akun dokter, atau daftar baru dengan kode `DOKTOR01`.
2. Dashboard daftar pasien + tekanan darah terakhir.
3. Status kehadiran (heartbeat) untuk tampil online di Home pasien.

### Admin (Windows desktop)

1. Jalankan `flutter run -t lib/main_admin.dart -d windows`.
2. Login `admin@smartstroke.id`.
3. Kelola pasien, apoteker, dokter, undangan, konten, dan data operasional.

---

## Fitur utama

| Fitur | Status |
|-------|--------|
| Auth & profil pasien | ✅ Supabase |
| Pengingat obat | ✅ Supabase |
| Monitoring kesehatan | ✅ Supabase |
| Rehab & latihan | ✅ Supabase |
| Komunitas | ✅ Supabase + storage |
| Chat apoteker + read receipt | ✅ Realtime |
| Edukasi stroke | ✅ Supabase + seed |
| Notifikasi inbox | ✅ Supabase |
| Push notification (FCM) | ⚠️ Perlu `google-services.json` + Edge Function |
| Mobile dokter | ✅ Dashboard pasien |
| Admin desktop | ✅ Windows |

---

## Struktur folder penting

```
aplication_stroke/
├── lib/
│   ├── main.dart              # Entry mobile
│   ├── main_admin.dart        # Entry admin desktop
│   ├── auth/                  # Login, register, splash
│   ├── modules/               # Layar fitur per modul
│   └── services/              # Remote & local services
├── sql/                       # Semua skrip database
│   └── README.md              # Urutan eksekusi SQL
├── android/
├── windows/
└── .env                       # Kredensial Supabase (buat sendiri)
```

---

## Troubleshooting

| Masalah | Solusi |
|---------|--------|
| Login gagal | Pastikan `smart_stroke_seed_auth.sql` sudah dijalankan |
| Chat tidak realtime | Aktifkan replication `messages` & `chat_rooms` |
| Upload komunitas gagal | Jalankan `sql/smart_stroke_storage_setup.sql` |
| Push tidak masuk | Pastikan `google-services.json` ada; FCM server belum ada di Edge Function |
| Admin terbuka di HP | Normal — admin hanya untuk desktop |
| `SUPABASE_URL not found` | Buat/isi file `.env` di root `aplication_stroke/` |

---

## Lisensi

Proyek internal Synexa / PPM.
