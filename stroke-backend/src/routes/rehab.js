const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken, isAdmin } = require('../middleware/auth');

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
            'SELECT * FROM rehab_exercises WHERE phase_id = $1 ORDER BY order_index ASC',
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
    const { exercise_id, duration_seconds, repetitions } = req.body;
    const user_id = req.user.id;
    try {
        const { rows } = await db.query(
            'INSERT INTO rehab_exercise_logs (user_id, exercise_id, duration_seconds, repetitions) VALUES ($1, $2, $3, $4) RETURNING *',
            [user_id, exercise_id, duration_seconds, repetitions]
        );
        res.status(201).json(rows[0]);
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

module.exports = router;
