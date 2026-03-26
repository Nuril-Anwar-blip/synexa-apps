/**
 * ======================================================================
 * Routes: Rehabilitation
 * ======================================================================
 * 
 * Deskripsi:
 * Routes untuk mengelola program rehabilitasi stroke pasien. Meliputi
 * fase rehabilitasi, latihan, progress, dan kuis.
 * 
 * Endpoint:
 * - GET /rehab/phases - Ambil semua fase rehabilitasi
 * - GET /rehab/phases/:phaseId/exercises - Ambil latihan per fase
 * - POST /rehab/exercises/log - Catat hasil latihan
 * - GET /rehab/progress/:userId - Ambil progress rehabilitasi user
 * - GET /rehab/exercises/log/:userId - Ambil log latihan user
 * 
 * Fase Rehabilitasi:
 * 1. Fase Akut (0-1 minggu) - Latihan ringan
 * 2. Fase Sub-Akut (2-4 minggu) - Latihan menengah
 * 3. Fase Pemulihan (5-12 minggu) - Latihan intensif
 * 4. Fase Pemeliharaan (13-26 minggu) - Pemeliharaan
 * 
 * Real-time: Menggunakan Socket.io untuk notifikasi real-time
 * saat ada perubahan data rehabilitasi.
 * 
 * ======================================================================
 */

const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken, isAdmin } = require('../middleware/auth');
const { getIO } = require('../config/socketManager');

/**
 * Fase Rehabilitasi
 */
router.get('/phases', authenticateToken, async (req, res) => {
    try {
        const { rows } = await db.query('SELECT * FROM rehab_phases ORDER BY order_index ASC');
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Latihan per Fase
 */
router.get('/phases/:phaseId/exercises', authenticateToken, async (req, res) => {
    try {
        const { rows } = await db.query(
            'SELECT * FROM rehab_exercises WHERE phase_id = $1 ORDER BY time_category ASC, name ASC',
            [req.params.phaseId]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Log Latihan
 */
router.post('/exercises/log', authenticateToken, async (req, res) => {
    const { exercise_id, duration_actual_seconds, is_aborted, abort_reason } = req.body;
    const user_id = req.user.id;
    try {
        const { rows } = await db.query(
            'INSERT INTO rehab_exercise_logs (user_id, exercise_id, duration_actual_seconds, is_aborted, abort_reason) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [user_id, exercise_id, duration_actual_seconds, is_aborted || false, abort_reason || null]
        );
        res.status(201).json(rows[0]);

        // Emit real-time: beritahu Flutter bahwa ada log latihan baru
        getIO().to(user_id).emit('rehab_updated', { action: 'exercise_logged', data: rows[0] });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Progress User (Isolated)
 */
router.get('/progress/:userId', authenticateToken, async (req, res) => {
    const { userId } = req.params;
    if (req.user.role !== 'admin' && req.user.id !== userId) {
        return res.status(403).json({ error: "Access Denied" });
    }

    try {
        const { rows } = await db.query(
            'SELECT p.*, ph.name as phase_name FROM rehab_user_progress p JOIN rehab_phases ph ON p.current_phase_id = ph.id WHERE p.user_id = $1',
            [userId]
        );
        res.json(rows[0] || { message: "No progress found" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Log Latihan User
 */
router.get('/exercises/log/:userId', authenticateToken, async (req, res) => {
    const { userId } = req.params;
    if (req.user.role !== 'admin' && req.user.id !== userId) {
        return res.status(403).json({ error: "Access Denied" });
    }

    try {
        const { rows } = await db.query(
            `SELECT el.*, e.name as exercise_name, e.duration_text, e.media_url 
             FROM rehab_exercise_logs el 
             JOIN rehab_exercises e ON el.exercise_id = e.id 
             WHERE el.user_id = $1 
             ORDER BY el.completed_at DESC`,
            [userId]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Update Progress User
 */
router.patch('/progress/:userId', authenticateToken, async (req, res) => {
    const { userId } = req.params;
    const { current_phase_id, streak_count } = req.body;

    if (req.user.role !== 'admin' && req.user.id !== userId) {
        return res.status(403).json({ error: "Access Denied" });
    }

    try {
        let query = 'UPDATE rehab_user_progress SET updated_at = NOW()';
        let params = [];
        let paramIndex = 1;

        if (current_phase_id !== undefined) {
            query += `, current_phase_id = $${paramIndex++}`;
            params.push(current_phase_id);
        }
        if (streak_count !== undefined) {
            query += `, streak_count = $${paramIndex++}`;
            params.push(streak_count);
        }

        query += ` WHERE user_id = $${paramIndex++} RETURNING *`;
        params.push(userId);

        const { rows } = await db.query(query, params);

        if (rows.length === 0) {
            return res.status(404).json({ error: "Progress not found" });
        }

        res.json(rows[0]);

        // Emit real-time: beritahu Flutter bahwa progress berubah
        getIO().to(userId).emit('rehab_updated', { action: 'progress_updated', data: rows[0] });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
