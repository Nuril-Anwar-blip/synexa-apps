/**
 * ======================================================================
 * SYNEXA STROKE REHABILITATION - BACKEND SERVER
 * ======================================================================
 * 
 * Deskripsi:
 * Aplikasi backend ini menyediakan API untuk aplikasi mobile Flutter
 * dalam fitur rehabilitasi stroke. Menggunakan Node.js dengan Express
 * dan Socket.io untuk real-time communication.
 * 
 * Fitur Utama:
 * - Authentication & Authorization (JWT)
 * - Manajemen User (Pasien, Apoteker, Admin)
 * - Log Kesehatan (Tekanan darah, dll)
 * - Pengingat Obat
 * - Rehabilitasi & Latihan
 * - Komunitas (Post, Komentar, Like)
 * - Chat Real-time antara Pasien dan Apoteker
 * - Notifikasi
 * - Data Sensor dari Smartwatch
 * - Emergency (SOS)
 * 
 * Cara Menjalankan:
 * 1. Pastikan PostgreSQL sudah berjalan dan DATABASE_URL dikonfigurasi di .env
 * 2. Jalankan: npm install
 * 3. Jalankan: npm start
 * 4. Server akan running di port 3000
 * 
 * ======================================================================
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const http = require('http');
const { Server } = require('socket.io');
const { authenticateToken } = require('./middleware/auth');
const db = require('./config/db');

// Routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const healthRoutes = require('./routes/health');
const sensorRoutes = require('./routes/sensor');
const medicationRoutes = require('./routes/medication');
const communityRoutes = require('./routes/community');
const educationRoutes = require('./routes/education');
const rehabRoutes = require('./routes/rehab');
const emergencyRoutes = require('./routes/emergency');
const notificationsRoutes = require('./routes/notifications');
const chatRoutes = require('./routes/chat');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: { origin: '*' }
});

// Middlewares
app.use(cors());
app.use(bodyParser.json());

// Public Routes
app.use('/auth', authRoutes);

// Protected Routes (Require JWT)
app.use('/users', authenticateToken, userRoutes);
app.use('/health', authenticateToken, healthRoutes);
app.use('/sensor', authenticateToken, sensorRoutes);
app.use('/medication', authenticateToken, medicationRoutes);
app.use('/community', authenticateToken, communityRoutes);
app.use('/education', authenticateToken, educationRoutes);
app.use('/rehab', authenticateToken, rehabRoutes);
app.use('/emergency', authenticateToken, emergencyRoutes);
app.use('/notifications', authenticateToken, notificationsRoutes);
app.use('/chat', authenticateToken, chatRoutes);

// Inisialisasi socketManager agar bisa diakses di semua route
const { initSocket } = require('./config/socketManager');
initSocket(io);

// Socket.io Real-time Chat
io.on('connection', (socket) => {
    console.log('User connected:', socket.id);

    // Event register_user: Flutter mengirim userId agar socket ini
    // masuk ke room bernama userId-nya, sehingga backend bisa kirim
    // event real-time hanya ke user yang tepat.
    socket.on('register_user', (userId) => {
        if (userId) {
            socket.join(userId);
            console.log(`Socket ${socket.id} registered to user room: ${userId}`);
        }
    });

    // Event join_room: bergabung ke chat room tertentu
    socket.on('join_room', (roomId) => {
        socket.join(roomId);
        console.log(`Socket ${socket.id} joined chat room ${roomId}`);
    });

    socket.on('send_message', async (data) => {
        // Data: { roomId, senderId, content, senderName }
        try {
            const { roomId, senderId, content } = data;
            if (roomId && senderId && content) {
                await db.query(
                    'INSERT INTO messages (room_id, sender_id, content) VALUES ($1, $2, $3)',
                    [roomId, senderId, content]
                );
            }
            io.to(data.roomId).emit('receive_message', data);
        } catch (err) {
            console.error('Socket send_message error:', err);
        }
    });

    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
    });
});

// Basic Health Check
app.get('/', (req, res) => {
    res.json({ status: 'Synexa Data Center (Standalone SQL) is active' });
});

// Start Server
const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT}`);
});

module.exports = { app, server, io };
