/**
 * ======================================================================
 * Routes: Emergency (SOS)
 * ======================================================================
 * 
 * Deskripsi:
 * Routes untuk menangani situasi darurat (SOS). Pasien dapat
 * mengirim sinyal darurat dengan lokasi mereka, dan admin/apoteker
 * dapat melihat dan menangani permintaan darurat.
 * 
 * Endpoint:
 * - POST /emergency - Kirim sinyal darurat baru
 * - PATCH /emergency/:id/status - Update status darurat (Admin/Apoteker)
 * - GET /emergency/user/:userId - Ambil riwayat darurat user
 * 
 * Status Darurat:
 * - "active" - Sedang aktif, belum ditangani
 * - "acknowledged" - Sudah dilihat oleh admin/apoteker
 * - "resolved" - Sudah ditangani/selesai
 * 
 * Real-time: Sinyal darurat dikirim ke semua admin menggunakan Socket.io
 * 
 * ======================================================================
 */

const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken, isAdmin } = require('../middleware/auth');
const { getIO } = require('../config/socketManager');

/**
 * Buat Log Darurat Baru (Lokal SQL)
 */
router.post('/', authenticateToken, async (req, res) => {
    const { location_lat, location_long } = req.body;
    const user_id = req.user.id;
    try {
        const { rows } = await db.query(
            'INSERT INTO emergency_logs (user_id, location_lat, location_long, status) VALUES ($1, $2, $3, $4) RETURNING *',
            [user_id, location_lat, location_long, 'active']
        );
        res.status(201).json(rows[0]);
        // Broadcast emergency_alert ke SEMUA socket (admin dan petugas harus melihat ini)
        getIO().emit('emergency_alert', { action: 'sos_triggered', data: rows[0] });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Update Status Darurat (Admin/Apoteker)
 */
router.patch('/:id/status', authenticateToken, async (req, res) => {
    const { status } = req.body;
    try {
        const { rows } = await db.query(
            'UPDATE emergency_logs SET status = $1 WHERE id = $2 RETURNING *',
            [status, req.params.id]
        );
        res.json(rows[0]);
        // Emit ke pasien (user_id terkait) bahwa status darurat sudah diperbarui
        if (rows[0]) getIO().to(rows[0].user_id).emit('emergency_alert', { action: 'status_updated', data: rows[0] });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Riwayat SOS (Isolated or Full for Admin)
 */
router.get('/user/:userId', authenticateToken, async (req, res) => {
    const { userId } = req.params;
    if (req.user.role !== 'admin' && req.user.id !== userId) {
        return res.status(403).json({ error: "Access Denied" });
    }

    try {
        const { rows } = await db.query(
            'SELECT * FROM emergency_logs WHERE user_id = $1 ORDER BY triggered_at DESC',
            [userId]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
