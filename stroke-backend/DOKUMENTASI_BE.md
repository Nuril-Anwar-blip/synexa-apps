# Dokumentasi Backend Stroke App (NestJS)

Backend ini dibangun menggunakan NestJS dangan arsitektur yang modular, stabil, dan mendukung fitur real-time menggunakan Socket.io.

## Teknologi Utama
- **Framework**: NestJS (Node.js)
- **Database**: PostgreSQL (Prisma ORM)
- **Real-time**: Socket.io (NestJS Gateway)
- **Autentikasi**: JWT (JSON Web Token) & Bcrypt

## Struktur Folder
- `prisma/`: Berisi skema database (`schema.prisma`)
- `src/auth/`: Modul untuk login dan registrasi
- `src/users/`: Pengelolaan profil dan data pengguna
- `src/community/`: Fitur forum (postingan, like, komentar)
- `src/medication/`: Pengingat obat dan manajemen stok
- `src/chat/`: Fitur chat real-time (WebSockets)
- `src/sensor/`: Pelacakan detak jantung dan lokasi GPS

## Cara Instalasi

1. **Clone project dan masuk ke direktori**:
   ```bash
   cd stroke-backend
   ```

2. **Instal dependensi**:
   ```bash
   npm install
   ```
   *(Penting: Jika instalasi gagal di lingkungan tertentu, pastikan koneksi internet stabil dan registry npm dapat diakses)*

3. **Konfigurasi Environment**:
   Edit file `.env` dan masukkan URL database PostgreSQL Anda:
   ```env
   DATABASE_URL="postgresql://username:password@localhost:5432/stroke_db?schema=public"
   JWT_SECRET="kunci-rahasia-anda"
   ```

4. **Inisialisasi Database (Prisma)**:
   ```bash
   npx prisma generate
   npx prisma db push
   ```

5. **Menjalankan Aplikasi**:
   ```bash
   npm run start:dev
   ```

## Fitur Real-time (Chat)
Gunakan Socket.io client untuk terhubung ke endpoint `/` (default port 3000).
- **Event: `join_room`**: Bergabung ke ruang percakapan (params: `roomId`).
- **Event: `send_message`**: Mengirim pesan (params: `{ roomId, senderId, content }`).
- **Event: `receive_message`**: Menerima pesan real-time dari server.

## Catatan Keamanan
- Pastikan untuk mengganti `JWT_SECRET` sebelum deployment.
- Gunakan HTTPS pada lingkungan produksi.
