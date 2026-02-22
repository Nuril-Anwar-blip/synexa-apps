const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken, isAdmin } = require('../middleware/auth');

/**
 * Log Data Kesehatan Baru (Lokal PostgreSQL)
 */
router.post('/', authenticateToken, async (req, res) => {
    const { log_type, value_numeric, value_text, note } = req.body;
    const user_id = req.user.id; // Enforce logged in user id

    try {
        const { rows } = await db.query(
            'INSERT INTO health_logs (user_id, log_type, value_numeric, value_text, note) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [user_id, log_type, value_numeric, value_text, note]
        );
        res.status(201).json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Ambil Riwayat Kesehatan (Isolated for Patient, Full for Admin)
 */
router.get('/user/:userId', authenticateToken, async (req, res) => {
    const { userId } = req.params;
    const { type } = req.query;

    // Access Control
    if (req.user.role !== 'admin' && req.user.id !== userId) {
        return res.status(403).json({ error: "Access Denied" });
    }

    try {
        let query = 'SELECT * FROM health_logs WHERE user_id = $1';
        let params = [userId];

        if (type) {
            query += ' AND log_type = $2';
            params.push(type);
        }

        query += ' ORDER BY recorded_at DESC';

        const { rows } = await db.query(query, params);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
