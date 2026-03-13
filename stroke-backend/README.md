# 🏥 Synexa Stroke Rehabilitation Backend

<p align="center">
  <img src="https://img.shields.io/badge/Node.js-18+-green?style=for-the-badge&logo=node.js" alt="Node.js">
  <img src="https://img.shields.io/badge/Express-4.x-blue?style=for-the-badge&logo=express" alt="Express">
  <img src="https://img.shields.io/badge/PostgreSQL-15+-blue?style=for-the-badge&logo=postgresql" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/Socket.io-4.x-purple?style=for-the-badge&logo=socket.io" alt="Socket.io">
</p>

---

## 📋 Deskripsi Proyek

**Synexa** adalah aplikasi rehabilitasi stroke berbasis mobile yang membantu pasien stroke dalam proses pemulihan mereka. Backend ini menyediakan API untuk menghubungkan aplikasi Flutter dengan database PostgreSQL, serta mendukung komunikasi real-time menggunakan Socket.io.

### 🎯 Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 🔐 **Authentication** | Registrasi dan login user dengan JWT |
| 👥 **Manajemen User** | Mengelola data pasien, apoteker, dan admin |
| 💊 **Pengingat Obat** | Pengingat jadwal minum obat dengan notifikasi real-time |
| 📊 **Log Kesehatan** | Pencatatan tekanan darah, denyut jantung, dll |
| 🏋️ **Rehabilitasi** | Program latihan rehabilitasi stroke per fase |
| 👥 **Komunitas** | Forum berbagi pengalaman antar pasien |
| 💬 **Chat** | Konsultasi pasien dengan apoteker |
| 🚨 **Emergency (SOS)** | Sinyal darurat dengan lokasi |
| 📱 **Sensor Data** | Data dari smartwatch (detak jantung, langkah, lokasi) |
| 🔔 **Notifikasi** | Notifikasi real-time ke aplikasi Flutter |

---

## 🚀 Cara Menjalankan

### Prerequisites

- Node.js v18 atau lebih tinggi
- PostgreSQL v15 atau lebih tinggi
- npm atau yarn

### Installation

```bash
# Clone repository
git clone <repository-url>
cd stroke-backend

# Install dependencies
npm install

# Konfigurasi environment
cp .env.example .env
# Edit file .env dengan konfigurasi database Anda
```

### Konfigurasi `.env`

```env
# Database PostgreSQL (Ganti dengan kredensial Anda)
DATABASE_URL=postgresql://postgres:[PASSWORD]@localhost:5432/postgres

# Port Server
PORT=3000

# JWT Secret (Ganti dengan secret key yang aman)
JWT_SECRET=super-secret-key-change-me-later
```

### Menjalankan Server

```bash
# Mode development
npm run dev

# Mode production
npm start
```

Server akan berjalan di `http://localhost:3000`

---

## 🗄️ Setup Database

### Menggunakan pgAdmin 4

1. Buka pgAdmin 4 dan buat database baru
2. Klik kanan pada database → Query Tool
3. Copy semua isi file [`schema.sql`](schema.sql)
4. Paste dan jalankan (Execute)

### Menggunakan psql CLI

```bash
psql -U postgres -d synexa -f schema.sql
```

---

## 📚 Dokumentasi API

### Endpoint Utama

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| POST | `/auth/register` | Registrasi user baru |
| POST | `/auth/login` | Login user |
| GET | `/users/:id` | Ambil profil user |
| POST | `/health` | Tambah log kesehatan |
| GET | `/health/user/:userId` | Ambil riwayat kesehatan |
| GET | `/medication/user/:userId` | Ambil pengingat obat |
| POST | `/medication` | Tambah pengingat obat |
| GET | `/rehab/phases` | Ambil fase rehabilitasi |
| GET | `/community/posts` | Ambil semua postingan |
| POST | `/community/posts` | Buat postingan baru |
| POST | `/emergency` | Kirim sinyal darurat |
| GET | `/sensor/history/:userId` | Ambil data sensor |

**Catatan**: Semua endpoint (kecuali `/auth/*`) memerlukan token JWT di header:
```
Authorization: Bearer <token_jwt>
```

---

## 🔌 Socket.io Events

### Untuk Real-time Communication

```javascript
// Di Flutter/Dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

IO.Socket socket = IO.io('http://localhost:3000', <String, dynamic>{
  'transports': ['websocket'],
});

// Connect
socket.connect();

// Register user ke room
socket.emit('register_user', userId);

// Listen events
socket.on('health_updated', (data) {
  print('Health data updated: $data');
});

socket.on('medication_updated', (data) {
  print('Medication updated: $data');
});

socket.on('emergency_alert', (data) {
  print('Emergency alert: $data');
});
```

### Event yang Didukung

| Event | Arah | Deskripsi |
|-------|------|-----------|
| `register_user` | Client → Server | Daftar user ke room |
| `join_room` | Client → Server | Join chat room |
| `send_message` | Client → Server | Kirim pesan chat |
| `receive_message` | Server → Client | Terima pesan |
| `health_updated` | Server → Client | Update data kesehatan |
| `medication_updated` | Server → Client | Update obat |
| `emergency_alert` | Server → Client | Sinyal darurat |
| `community_updated` | Server → Client | Update komunitas |

---

## 🏗️ Arsitektur Projekt

```
stroke-backend/
├── src/
│   ├── index.js              # Entry point server
│   ├── config/
│   │   ├── db.js             # Konfigurasi PostgreSQL
│   │   └── socketManager.js  # Socket.io manager
│   ├── middleware/
│   │   └── auth.js           # JWT authentication
│   └── routes/
│       ├── auth.js           # Authentication
│       ├── users.js          # User management
│       ├── health.js         # Health logs
│       ├── medication.js    # Medication reminders
│       ├── rehab.js          # Rehabilitation
│       ├── community.js      # Community posts
│       ├── education.js      # Education content
│       ├── emergency.js      # Emergency/SOS
│       ├── notifications.js  # Notifications
│       ├── sensor.js         # Sensor data
│       └── chat.js           # Chat
├── schema.sql                # Database schema
├── package.json              # Dependencies
├── .env                      # Environment variables
└── README.md                 # Dokumentasi
```

---

## 👥 User Roles

| Role | Akses |
|------|-------|
| `pasien` | Akses data sendiri, komunitas, obat, rehabilitasi |
| `apoteker` | Akses pasien, chat, notifikasi |
| `admin` | Akses penuh semua data |

---

## 🛠️ Teknologi yang Digunakan

- **Runtime**: Node.js v18+
- **Framework**: Express.js
- **Database**: PostgreSQL with pg driver
- **Real-time**: Socket.io
- **Authentication**: JWT (jsonwebtoken)
- **Password Hashing**: bcrypt
- **Environment**: dotenv

---

## 📄 Lisensi

ISC License - See LICENSE file for details

---

## 👨‍💻 Author

Synexa Team - MTE Malaysia Competition

---

<div align="center">
  <p>Dibuat dengan ❤️ untuk membantu pemulihan pasien stroke</p>
  <p><strong>Synexa - Stroke Rehabilitation App</strong></p>
</div>
