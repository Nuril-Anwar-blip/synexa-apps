/**
 * ======================================================================
 * Routes: Chat (Patient-Pharmacist Communication)
 * ======================================================================
 * 
 * Deskripsi:
 * Routes untuk fitur chat antara pasien dan apoteker. Memungkinkan
 * komunikasi langsung untuk konsultasi tentang obat dan kesehatan.
 * 
 * Endpoint:
 * - GET /chat/messages/:roomId - Ambil riwayat pesan dalam room
 * - GET /chat/rooms/:userId - Ambil semua room chat user
 * - POST /chat/rooms - Buat chat room baru
 * - POST /chat/messages - Kirim pesan
 * 
 * Fitur:
 * - Room chat dibuat saat pasien pertama kali berkonsultasi
 * - Pesan disimpan di database untuk riwayat
 * - Menggunakan Socket.io untuk real-time messaging
 * 
 * ======================================================================
 */

const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken } = require('../middleware/auth');
const { getIO } = require('../config/socketManager');

/**
 * Riwayat Pesan dalam Room
 */
router.get('/messages/:roomId', authenticateToken, async (req, res) => {
    const { roomId } = req.params;
    try {
        // Check if user is part of the room
        const { rows: rooms } = await db.query(
            'SELECT * FROM chat_rooms WHERE id = $1',
            [roomId]
        );

        if (rooms.length === 0) return res.status(404).json({ error: "Room not found" });

        if (req.user.role !== 'admin' && rooms[0].patient_id !== req.user.id && rooms[0].pharmacist_id !== req.user.id) {
            return res.status(403).json({ error: "Access Denied" });
        }

        const { rows: messages } = await db.query(`
      SELECT m.*, u.full_name, u.photo_url
      FROM messages m
      JOIN users u ON m.sender_id = u.id
      WHERE m.room_id = $1
      ORDER BY m.created_at ASC
    `, [roomId]);

        res.json(messages);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Daftar Chat Room User
 */
router.get('/rooms/:userId', authenticateToken, async (req, res) => {
    const { userId } = req.params;
    if (req.user.role !== 'admin' && req.user.id !== userId) {
        return res.status(403).json({ error: "Access Denied" });
    }

    try {
        const { rows } = await db.query(`
      SELECT cr.*, 
      p.full_name as patient_name, p.photo_url as patient_photo,
      w.full_name as pharmacist_name, w.photo_url as pharmacist_photo,
      (SELECT content FROM messages WHERE room_id = cr.id ORDER BY created_at DESC LIMIT 1) as last_message,
      (SELECT created_at FROM messages WHERE room_id = cr.id ORDER BY created_at DESC LIMIT 1) as last_message_at
      FROM chat_rooms cr
      JOIN users p ON cr.patient_id = p.id
      JOIN users w ON cr.pharmacist_id = w.id
      WHERE cr.patient_id = $1 OR cr.pharmacist_id = $1
      ORDER BY last_message_at DESC NULLS LAST
    `, [userId]);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Buat Chat Room Baru
 */
router.post('/rooms', authenticateToken, async (req, res) => {
    const { pharmacist_id } = req.body;
    const patient_id = req.user.id;

    if (req.user.role !== 'pasien') {
        return res.status(403).json({ error: "Only patients can create chat rooms" });
    }

    try {
        // Check if room already exists
        const { rows: existing } = await db.query(
            'SELECT * FROM chat_rooms WHERE patient_id = $1 AND pharmacist_id = $2',
            [patient_id, pharmacist_id]
        );

        if (existing.length > 0) {
            return res.json(existing[0]);
        }

        const { rows } = await db.query(
            'INSERT INTO chat_rooms (patient_id, pharmacist_id) VALUES ($1, $2) RETURNING *',
            [patient_id, pharmacist_id]
        );

        res.status(201).json(rows[0]);

        // Notify pharmacist about new chat room
        getIO().to(pharmacist_id).emit('chat_updated', { action: 'new_room', data: rows[0] });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Kirim Pesan
 */
router.post('/messages', authenticateToken, async (req, res) => {
    const { room_id, content } = req.body;
    const sender_id = req.user.id;

    try {
        // Check if user is part of the room
        const { rows: rooms } = await db.query(
            'SELECT * FROM chat_rooms WHERE id = $1',
            [room_id]
        );

        if (rooms.length === 0) return res.status(404).json({ error: "Room not found" });

        if (req.user.role !== 'admin' && rooms[0].patient_id !== sender_id && rooms[0].pharmacist_id !== sender_id) {
            return res.status(403).json({ error: "Access Denied" });
        }

        const { rows } = await db.query(
            'INSERT INTO messages (room_id, sender_id, content) VALUES ($1, $2, $3) RETURNING *',
            [room_id, sender_id, content]
        );

        // Get sender info
        const { rows: users } = await db.query(
            'SELECT full_name, photo_url FROM users WHERE id = $1',
            [sender_id]
        );

        const messageWithSender = {
            ...rows[0],
            full_name: users[0].full_name,
            photo_url: users[0].photo_url
        };

        res.status(201).json(messageWithSender);

        // Emit to the chat room
        getIO().to(room_id).emit('receive_message', messageWithSender);

        // Also notify the other user in the room
        const otherUserId = rooms[0].patient_id === sender_id ? rooms[0].pharmacist_id : rooms[0].patient_id;
        getIO().to(otherUserId).emit('chat_updated', { action: 'new_message', data: messageWithSender });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
