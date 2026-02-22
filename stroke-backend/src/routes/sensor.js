const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken } = require('../middleware/auth');

/**
 * Simpan Data Sensor (Lokal PostgreSQL)
 */
router.post('/', authenticateToken, async (req, res) => {
    const { type, value } = req.body;
    const user_id = req.user.id;

    try {
        const { rows } = await db.query(
            'INSERT INTO sensor_data (user_id, type, value) VALUES ($1, $2, $3) RETURNING *',
            [user_id, type, JSON.stringify(value)]
        );
        res.status(201).json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Riwayat Sensor (Isolated for Patient, Full for Admin)
 */
router.get('/history/:userId', authenticateToken, async (req, res) => {
    const { userId } = req.params;
    const { type } = req.query;

    if (req.user.role !== 'admin' && req.user.id !== userId) {
        return res.status(403).json({ error: "Access Denied" });
    }

    try {
        let query = 'SELECT * FROM sensor_data WHERE user_id = $1';
        let params = [userId];

        if (type) {
            query += ' AND type = $2';
            params.push(type);
        }

        query += ' ORDER BY timestamp DESC LIMIT 50';

        const { rows } = await db.query(query, params);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
