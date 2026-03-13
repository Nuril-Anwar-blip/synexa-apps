/**
 * ======================================================================
 * Routes: Medication Reminders
 * ======================================================================
 * 
 * Deskripsi:
 * Routes untuk mengelola pengingat obat pasien. Pasien dapat menambah,
 * melihat, dan menandai obat sudah diminum.
 * 
 * Endpoint:
 * - GET /medication/user/:userId - Ambil semua pengingat obat user
 * - POST /medication - Tambah pengingat obat baru
 * - PATCH /medication/:id/take - Tandai obat sudah diminum
 * 
 * Periode Obat:
 * - "Pagi" - Diminum pagi hari
 * - "Siang" - Diminum siang hari
 * - "Sore" - Diminum sore hari
 * - "Malam" - Diminum malam hari
 * 
 * Real-time: Menggunakan Socket.io untuk notifikasi real-time
 * saat ada perubahan data obat.
 * 
 * ======================================================================
 */

const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken } = require('../middleware/auth');
const { getIO } = require('../config/socketManager');

/**
 * Daftar Pengingat Obat (Isolated)
 */
router.get('/user/:userId', authenticateToken, async (req, res) => {
    const { userId } = req.params;
    if (req.user.role !== 'admin' && req.user.id !== userId) {
        return res.status(403).json({ error: "Access Denied" });
    }

    try {
        const { rows } = await db.query(
            'SELECT * FROM medication_reminders WHERE user_id = $1 ORDER BY time ASC',
            [userId]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Tambah Pengingat
 */
router.post('/', authenticateToken, async (req, res) => {
    const { name, time, dose, note, period, frequency } = req.body;
    const user_id = req.user.id;

    try {
        const { rows } = await db.query(
            'INSERT INTO medication_reminders (user_id, name, time, dose, note, period, frequency) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
            [user_id, name, time, dose, note, period, frequency]
        );
        res.status(201).json(rows[0]);
        // Emit real-time: beritahu Flutter bahwa data obat user ini berubah
        getIO().to(user_id).emit('medication_updated', { action: 'created', data: rows[0] });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Tandai Sudah Diminum
 */
router.patch('/:id/take', authenticateToken, async (req, res) => {
    const { id } = req.params;

    try {
        // Check ownership
        const { rows: reminders } = await db.query('SELECT * FROM medication_reminders WHERE id = $1', [id]);
        if (reminders.length === 0) return res.status(404).json({ error: "Not found" });

        if (req.user.role !== 'admin' && reminders[0].user_id !== req.user.id) {
            return res.status(403).json({ error: "Access Denied" });
        }

        const { rows: updated } = await db.query(
            'UPDATE medication_reminders SET taken = TRUE, updated_at = NOW() WHERE id = $1 RETURNING *',
            [id]
        );
        res.json(updated[0]);
        // Emit real-time: beritahu Flutter bahwa status obat sudah di-take
        getIO().to(updated[0].user_id).emit('medication_updated', { action: 'taken', data: updated[0] });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
