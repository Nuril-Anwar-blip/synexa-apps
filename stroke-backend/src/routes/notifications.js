const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken } = require('../middleware/auth');

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
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
