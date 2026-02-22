const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken } = require('../middleware/auth');

/**
 * Daftar Postingan (Public with User Info)
 */
router.get('/posts', authenticateToken, async (req, res) => {
    try {
        const { rows } = await db.query(`
      SELECT p.*, u.full_name, u.photo_url,
      (SELECT COUNT(*) FROM comments WHERE post_id = p.id) as comment_count,
      (SELECT COUNT(*) FROM likes WHERE post_id = p.id) as like_count
      FROM posts p
      JOIN users u ON p.user_id = u.id
      ORDER BY p.created_at DESC
    `);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Buat Postingan
 */
router.post('/posts', authenticateToken, async (req, res) => {
    const { content, image_url } = req.body;
    const user_id = req.user.id;

    try {
        const { rows } = await db.query(
            'INSERT INTO posts (user_id, content, image_url) VALUES ($1, $2, $3) RETURNING *',
            [user_id, content, image_url]
        );
        res.status(201).json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Tambah Komentar
 */
router.post('/posts/:id/comments', authenticateToken, async (req, res) => {
    const { content } = req.body;
    const post_id = req.params.id;
    const user_id = req.user.id;

    try {
        const { rows } = await db.query(
            'INSERT INTO comments (post_id, user_id, content) VALUES ($1, $2, $3) RETURNING *',
            [post_id, user_id, content]
        );
        res.status(201).json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Like Postingan
 */
router.post('/posts/:id/like', authenticateToken, async (req, res) => {
    const post_id = req.params.id;
    const user_id = req.user.id;

    try {
        const { rows } = await db.query(
            'INSERT INTO likes (post_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING RETURNING *',
            [post_id, user_id]
        );
        res.status(201).json(rows[0] || { message: "Already liked" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
