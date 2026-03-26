/**
 * ======================================================================
 * Routes: Notifications
 * ======================================================================
 * 
 * Deskripsi:
 * Routes untuk mengelola notifikasi yang diterima oleh user.
 * Notifikasi dapat berupa pengingat obat, jadwal latihan, atau
 * pesan dari sistem.
 * 
 * Endpoint:
 * - GET /notifications/user/:userId - Ambil semua notifikasi user
 * - PATCH /notifications/:id/read - Tandai notifikasi sudah dibaca
 * - POST /notifications - Buat notifikasi baru (admin only)
 * 
 * Real-time: Menggunakan Socket.io untuk notifikasi real-time
 * 
 * ======================================================================
 */

const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken, isAdmin } = require('../middleware/auth');
const { getIO } = require('../config/socketManager');

/**
 * Notifikasi User (Isolated)
 */
router.get('/user/:userId', authenticateToken, async (req, res) => {
    const { userId } = req.params;
    if (req.user.role !== 'admin' && req.user.id !== userId) {
        return res.status(403).json({ error: "Access Denied" });
    }

    try {
        const { rows } = await db.query(
            'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC',
            [userId]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Baca Notifikasi
 */
router.patch('/:id/read', authenticateToken, async (req, res) => {
    const { id } = req.params;
    try {
        const { rows } = await db.query(
            'UPDATE notifications SET is_read = TRUE WHERE id = $1 AND user_id = $2 RETURNING *',
            [id, req.user.id]
        );
        res.json(rows[0]);

        // Emit real-time update
        getIO().to(req.user.id).emit('notification_updated', { action: 'read', data: rows[0] });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Buat Notifikasi Baru (Admin only)
 */
router.post('/', authenticateToken, isAdmin, async (req, res) => {
    const { user_id, title, body, type } = req.body;

    try {
        const { rows } = await db.query(
            'INSERT INTO notifications (user_id, title, body, type) VALUES ($1, $2, $3, $4) RETURNING *',
            [user_id, title, body, type]
        );
        res.status(201).json(rows[0]);

        // Emit real-time notification to the user
        getIO().to(user_id).emit('new_notification', rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
