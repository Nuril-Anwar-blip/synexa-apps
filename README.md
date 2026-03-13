# 🏥 Synexa - Aplikasi Rehabilitasi Stroke

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Node.js-18+-green?style=for-the-badge&logo=node.js" alt="Node.js">
  <img src="https://img.shields.io/badge/PostgreSQL-15+-blue?style=for-the-badge&logo=postgresql" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/Supabase-Enabled-purple?style=for-the-badge&logo=supabase" alt="Supabase">
</p>

---

## 📋 Deskripsi Proyek

**Synexa** adalah aplikasi mobile rehabilitasi stroke yang dirancang untuk membantu pasien stroke dalam proses pemulihan mereka. Aplikasi ini menghubungkan pasien dengan apoteker dan admin melalui berbagai fitur like pengingat obat, rehabilitasi, komunitas, dan chat.

Proyek ini terdiri dari dua bagian utama:
1. **Frontend**: Aplikasi Flutter untuk pasien, apoteker, dan admin
2. **Backend**: Server Node.js dengan PostgreSQL untuk API dan real-time

---

## 📁 Struktur Projekt

```
synexa-aplication/
├── 📱 aplication_stroke/     # Aplikasi Flutter (Frontend)
├── 🖥️  stroke-backend/       # Backend Node.js (API Server)
├── ⌚ istroke-watch/         # Aplikasi Smartwatch
├── 📂 .github/               # Konfigurasi GitHub
└── 📄 README.md              # Dokumentasi ini
```

---

## 🏗️ Arsitektur Sistem

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRONTEND (Flutter)                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │ Pasien   │  │ Apoteker │  │  Admin   │  │Smartwatch│      │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘      │
└───────┼─────────────┼─────────────┼─────────────┼─────────────┘
        │             │             │             │
        ▼             ▼             ▼             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     BACKEND (Node.js + Express)                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │  Auth   │  │REST API  │  │ Socket.io│  │ WebSocket│      │
│  │ (JWT)   │  │          │  │ (Real-time)         │      │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────────┘      │
└───────┼─────────────┼─────────────┼───────────────────────────┘
        │             │             │
        ▼             ▼             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DATABASE (PostgreSQL)                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │  Users  │  │ Health   │  │ Medication│  │ Rehab    │      │
│  │          │  │  Logs    │  │ Reminders │  │ Progress │      │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📱 aplication_stroke - Aplikasi Flutter

### Fitur Utama

| Modul | Deskripsi |
|-------|-----------|
| 👤 **Auth** | Login, register, onboarding untuk pasien & apoteker |
| 🏠 **Dashboard** | Halaman utama dengan ringkasan data kesehatan |
| 💊 **Medication Reminder** | Pengingat jadwal minum obat |
| 🏋️ **Rehab/Exercise** | Program latihan rehabilitasi stroke |
| ❤️ **Health** | Pencatatan kesehatan (tekanan darah, denyut jantung) |
| 👥 **Community** | Forum diskusi antar pasien |
| 💬 **Consultation/Chat** | Chat dengan apoteker |
| 📚 **Education** | Konten edukasi tentang stroke |
| 🚨 **Emergency Call** | Sinyal darurat (SOS) dengan lokasi |
| ⚙️ **Settings** | Pengaturan aplikasi |
| 👨‍💼 **Admin** | Dashboard admin untuk mengelola pasien |

### Struktur Folder

```
aplication_stroke/
├── lib/
│   ├── auth/              # Modul autentikasi
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── widgets/       # Komponen UI auth
│   ├── modules/           # Fitur utama aplikasi
│   │   ├── dashboard/    # Halaman utama
│   │   ├── medication_reminder/  # Pengingat obat
│   │   ├── rehab/        # Rehabilitasi
│   │   ├── health/        # Kesehatan
│   │   ├── community/    # Komunitas
│   │   ├── consultation/ # Konsultasi/Chat
│   │   ├── education/    # Edukasi
│   │   ├── emergency_call/ # Darurat
│   │   ├── admin/        # Dashboard admin
│   │   └── settings/     # Pengaturan
│   ├── models/           # Model data
│   ├── services/        # Services (API calls)
│   ├── providers/       # State management
│   ├── widgets/         # Widget yang dapat digunakan ulang
│   ├── utils/           # Utility functions
│   ├── l10n/            # Localization (EN, ID, MS)
│   └── main.dart        # Entry point
├── android/             # Konfigurasi Android
├── ios/                 # Konfigurasi iOS
├── assets/              # Gambar, ikon, font
└── pubspec.yaml         # Dependencies
```

### Cara Menjalankan

```bash
cd aplication_stroke

# Install dependencies
flutter pub get

# Jalankan aplikasi
flutter run

# Build APK
flutter build apk --release
```

### Requirements

- Flutter SDK 3.x
- Dart 3.x
- Android SDK / iOS SDK

---

## 🖥️ stroke-backend - Backend Server

### Teknologi yang Digunakan

| Teknologi | Fungsi |
|-----------|--------|
| Node.js v18+ | Runtime server |
| Express.js | Framework API |
| PostgreSQL | Database |
| Socket.io | Real-time communication |
| JWT | Authentication |
| bcrypt | Password hashing |

### API Endpoints

#### Authentication
- `POST /auth/register` - Registrasi user
- `POST /auth/login` - Login

#### User Management
- `GET /users/:id` - Ambil profil user
- `PATCH /users/:id` - Update profil

#### Health
- `POST /health` - Tambah log kesehatan
- `GET /health/user/:userId` - Ambil riwayat kesehatan

#### Medication
- `GET /medication/user/:userId` - Ambil pengingat obat
- `POST /medication` - Tambah pengingat obat
- `PATCH /medication/:id/take` - Tandai obat diminum

#### Rehab
- `GET /rehab/phases` - Ambil fase rehabilitasi
- `GET /rehab/phases/:id/exercises` - Ambil latihan
- `POST /rehab/exercises/log` - Catat hasil latihan
- `GET /rehab/progress/:userId` - Ambil progress

#### Community
- `GET /community/posts` - Ambil postingan
- `POST /community/posts` - Buat postingan
- `POST /community/posts/:id/comments` - Tambah komentar
- `POST /community/posts/:id/like` - Like postingan

#### Emergency
- `POST /emergency` - Kirim sinyal darurat

#### Chat
- `GET /chat/rooms/:userId` - Ambil room chat
- `GET /chat/messages/:roomId` - Ambil pesan

#### Sensor
- `POST /sensor` - Simpan data sensor
- `GET /sensor/history/:userId` - Ambil data sensor

### Menjalankan Backend

```bash
cd stroke-backend

# Install dependencies
npm install

# Konfigurasi .env
# Edit DATABASE_URL, JWT_SECRET, dll

# Jalankan server
npm start  # production
npm run dev  # development
```

Server akan berjalan di `http://localhost:3000`

### Database Schema

Semua tabel database didefinisikan di [`stroke-backend/schema.sql`](stroke-backend/schema.sql). Jalankan file ini di PostgreSQL untuk membuat semua tabel.

---

## ⌚ istroke-watch - Aplikasi Smartwatch

Aplikasi ini digunakan untuk menghubungkan smartwatch dengan aplikasi utama. Berfungsi untuk:
- Mengirim data sensor (detak jantung, langkah)
- Notifikasi dari aplikasi utama
- Sinyal darurat (SOS)

---

## 🔌 Koneksi Real-time

### Socket.io Events

| Event | Deskripsi |
|-------|-----------|
| `register_user` | Daftar user ke socket room |
| `send_message` | Kirim pesan chat |
| `receive_message` | Terima pesan |
| `health_updated` | Update data kesehatan |
| `medication_updated` | Update pengingat obat |
| `emergency_alert` | Sinyal darurat |
| `community_updated` | Update komunitas |

---

## 🔧 Konfigurasi Environment

### Frontend (.env di aplication_stroke)
```
SUPABASE_URL=https://your-supabase-url.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### Backend (.env di stroke-backend)
```
DATABASE_URL=postgresql://user:password@host:5432/database
PORT=3000
JWT_SECRET=your-secret-key
```

---

## 📊 Fitur Berdasarkan Role

### 👤 Pasien
- Login/Register
- Lihat dashboard kesehatan
- Tambah log kesehatan
- Kelola pengingat obat
- Ikuti program rehabilitasi
- Bergabung komunitas
- Chat dengan apoteker
- Kirim sinyal darurat

### 👨‍⚕️ Apoteker
- Login
- Lihat pasien yang ditangani
- Chat dengan pasien
- Berikan rekomendasi obat

### 👨‍💼 Admin
- Login
- Kelola semua pasien
- Kelola apoteker
- Lihat semua data
- Kelola konten edukasi

---

## 🛠️ Pengembangan Lebih Lanjut

### Menambahkan Fitur Baru

1. **Backend**: Tambah route baru di `stroke-backend/src/routes/`
2. **Frontend**: Tambah module baru di `aplication_stroke/lib/modules/`
3. **Database**: Tambah tabel baru di `stroke-backend/schema.sql`

### Testing

```bash
# Backend
cd stroke-backend
npm test

# Frontend
cd aplication_stroke
flutter test
```

---

## 📄 Lisensi

ISC License - See LICENSE file for details

---

## 👨‍💻 Tim Pengembang

Synexa Team - MTE Malaysia Competition

---

<div align="center">
  <p>🇲🇾 Dibuat untuk kompetisi MTE Malaysia</p>
  <p>Dibuat dengan ❤️ untuk membantu pemulihan pasien stroke</p>
  <p><strong>Synexa - Stroke Rehabilitation App</strong></p>
</div>
