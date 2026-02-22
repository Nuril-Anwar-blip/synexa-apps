const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken } = require('../middleware/auth');

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
    const { name, time, total_stock, current_stock } = req.body;
    const user_id = req.user.id;

    try {
        const { rows } = await db.query(
            'INSERT INTO medication_reminders (user_id, name, time, total_stock, current_stock) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [user_id, name, time, total_stock, current_stock]
        );
        res.status(201).json(rows[0]);
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

        const newStock = Math.max(0, reminders[0].current_stock - 1);

        const { rows: updated } = await db.query(
            'UPDATE medication_reminders SET taken = TRUE, current_stock = $1 WHERE id = $2 RETURNING *',
            [newStock, id]
        );
        res.json(updated[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
