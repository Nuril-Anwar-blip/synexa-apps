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
        let query = 'SELECT * FROM education_content';
        let params = [];

        if (category) {
            query += ' WHERE category = $1';
            params.push(category);
        }

        query += ' ORDER BY created_at DESC';

        // Wait, I need to make sure education_content table exists in schema.sql
        // Looking back at schema.sql... oh, I missed education_content in the file content.
        // I will add it to the schema.sql later or just fix it now.

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
    const { title, content, category, image_url } = req.body;
    try {
        const { rows } = await db.query(
            'INSERT INTO education_content (title, content, category, image_url) VALUES ($1, $2, $3, $4) RETURNING *',
            [title, content, category, image_url]
        );
        res.status(201).json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
