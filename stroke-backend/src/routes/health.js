/**
 * ======================================================================
 * Routes: Health Logs
 * ======================================================================
 * 
 * Deskripsi:
 * Routes untuk mengelola log kesehatan pasien seperti tekanan darah,
 * denyut jantung, dan metrik kesehatan lainnya.
 * 
 * Endpoint:
 * - POST /health - Tambah log kesehatan baru
 * - GET /health/user/:userId - Ambil riwayat kesehatan user
 * 
 * Tipe Log yang Didukung:
 * - "blood_pressure" - Tekanan darah (systolic/diastolic)
 * - "heart_rate" - Detak jantung
 * - "weight" - Berat badan
 * - "blood_sugar" - Gula darah
 * 
 * Real-time: Menggunakan Socket.io untuk memberi tahu Flutter
 * saat ada data kesehatan baru.
 * 
 * ======================================================================
 */

const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken, isAdmin } = require('../middleware/auth');
const { getIO } = require('../config/socketManager');

/**
 * Log Data Kesehatan Baru (Lokal PostgreSQL)
 */
router.post('/', authenticateToken, async (req, res) => {
    const { log_type, value_systolic, value_diastolic, value_numeric, note } = req.body;
    const user_id = req.user.id; // Enforce logged in user id

    try {
        const { rows } = await db.query(
            'INSERT INTO health_logs (user_id, log_type, value_systolic, value_diastolic, value_numeric, note) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
            [user_id, log_type, value_systolic, value_diastolic, value_numeric, note]
        );
        res.status(201).json(rows[0]);
        // Emit real-time ke user yang bersangkutan
        getIO().to(user_id).emit('health_updated', { action: 'created', data: rows[0] });
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
