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
      w.full_name as pharmacist_name, w.photo_url as pharmacist_photo
      FROM chat_rooms cr
      JOIN users p ON cr.patient_id = p.id
      JOIN users w ON cr.pharmacist_id = w.id
      WHERE cr.patient_id = $1 OR cr.pharmacist_id = $1
    `, [userId]);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
