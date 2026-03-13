/**
 * ======================================================================
 * Routes: User Management
 * ======================================================================
 * 
 * Deskripsi:
 * Routes untuk mengelola data user (profil). Mendukung role-based access:
 * - Pasien hanya bisa melihat dan mengubah data dirinya sendiri
 * - Admin bisa melihat dan mengubah semua user
 * 
 * Endpoint:
 * - GET /users/:id - Ambil profil user berdasarkan ID
 * - GET /users/admin/patients - Ambil semua pasien (Admin only)
 * - GET /users/admin/apotekers - Ambil semua apoteker (Admin only)
 * - PATCH /users/:id - Update profil user
 * 
 * Autentikasi: Memerlukan JWT token di header Authorization
 * 
 * ======================================================================
 */

const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { isAdmin } = require('../middleware/auth');

/**
 * Mengambil Profil User (Isolated per Patient, Full for Admin)
 */
router.get('/:id', async (req, res) => {
    const { id } = req.params;

    // Access Control: User only sees self, Admin sees everyone
    if (req.user.role !== 'admin' && req.user.id !== id) {
        return res.status(403).json({ error: "Access Denied" });
    }

    try {
        const { rows } = await db.query('SELECT id, email, full_name, phone_number, role, photo_url, created_at FROM users WHERE id = $1', [id]);
        if (rows.length === 0) return res.status(404).json({ error: "User tidak ditemukan" });
        res.json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Admin Only: Lihat semua pasien
 */
router.get('/admin/patients', isAdmin, async (req, res) => {
    try {
        const { rows } = await db.query("SELECT id, email, full_name, phone_number, created_at FROM users WHERE role = 'pasien'");
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Admin Only: Lihat semua apoteker
 */
router.get('/admin/apotekers', isAdmin, async (req, res) => {
    try {
        const { rows } = await db.query("SELECT id, email, full_name, phone_number, created_at FROM users WHERE role = 'apoteker'");
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Update Profil
 */
router.patch('/:id', async (req, res) => {
    const { id } = req.params;
    if (req.user.role !== 'admin' && req.user.id !== id) {
        return res.status(403).json({ error: "Access Denied" });
    }

    const fields = Object.keys(req.body);
    const values = Object.values(req.body);
    if (fields.length === 0) return res.status(400).json({ error: "No fields to update" });

    const setClause = fields.map((field, i) => `${field} = $${i + 1}`).join(', ');

    try {
        const { rows } = await db.query(
            `UPDATE users SET ${setClause} WHERE id = $${fields.length + 1} RETURNING id, email, full_name, role`,
            [...values, id]
        );
        res.json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
