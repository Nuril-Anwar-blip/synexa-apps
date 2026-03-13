/**
 * ======================================================================
 * Routes: Education Content
 * ======================================================================
 * 
 * Deskripsi:
 * Routes untuk mengelola konten edukasi tentang stroke, pencegahan,
 * rehabilitasi, dan kesehatan umum. Konten dapat diakses oleh semua
 * user yang sudah login.
 * 
 * Endpoint:
 * - GET /education - Ambil semua konten edukasi (bisa filter berdasarkan kategori)
 * - POST /education - Tambah konten edukasi baru (Admin only)
 * 
 * Kategori Konten:
 * - "Dasar" - Pengetahuan dasar tentang stroke
 * - "Pencegahan" - Cara mencegah stroke
 * - "Rehab" - Informasi rehabilitasi
 * - "Nutrisi" - Panduan nutrisi
 * - "Kesehatan Mental" - Tips kesehatan mental
 * 
 * ======================================================================
 */

const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken, isAdmin } = require('../middleware/auth');

/**
 * Konten Edukasi (Public for Auth Users)
 */
router.get('/', authenticateToken, async (req, res) => {
    const { category } = req.query;
    try {
        let query = 'SELECT * FROM education_contents';
        let params = [];

        if (category) {
            query += ' WHERE category = $1';
            params.push(category);
        }

        query += ' ORDER BY created_at DESC';

        const { rows } = await db.query(query, params);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Tambah Konten Edukasi (Admin Only)
 */
router.post('/', authenticateToken, isAdmin, async (req, res) => {
    const { title, content, category, media_url } = req.body;
    try {
        const { rows } = await db.query(
            'INSERT INTO education_contents (title, content, category, media_url) VALUES ($1, $2, $3, $4) RETURNING *',
            [title, content, category, media_url]
        );
        res.status(201).json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
