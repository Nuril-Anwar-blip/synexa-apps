/**
 * ======================================================================
 * Routes: Authentication
 * ======================================================================
 * 
 * Deskripsi:
 * Routes untuk registrasi dan login user. Menggunakan sistem auth lokal
 * dengan password yang di-hash menggunakan bcrypt.
 * 
 * Endpoint:
 * - POST /auth/register - Registrasi user baru
 * - POST /auth/login - Login user dan mendapatkan JWT token
 * 
 * Body Request (Register):
 * {
 *   "email": "user@example.com",
 *   "password": "password123",
 *   "full_name": "Nama Lengkap",
 *   "phone_number": "081234567890",
 *   "role": "pasien" // atau "apoteker"
 * }
 * 
 * Body Response (Success):
 * {
 *   "user": { "id", "email", "full_name", "role" },
 *   "access_token": "jwt_token"
 * }
 * 
 * ======================================================================
 */

const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'your-default-secret-key';

/**
 * Registrasi User Baru (Lokal PostgreSQL)
 */
router.post('/register', async (req, res) => {
    const { email, password, full_name, phone_number, role } = req.body;

    try {
        // Hash password
        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(password, salt);

        const checkUser = await db.query('SELECT id FROM users WHERE email = $1', [email]);
        if (checkUser.rows.length > 0) {
            return res.status(400).json({ error: "Email sudah terdaftar" });
        }

        const { rows } = await db.query(
            'INSERT INTO users (email, password_hash, full_name, phone_number, role) VALUES ($1, $2, $3, $4, $5) RETURNING id, email, full_name, role',
            [email, passwordHash, full_name, phone_number, role || 'pasien']
        );

        const user = rows[0];
        const token = jwt.sign({ id: user.id, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '24h' });

        res.status(201).json({ user, access_token: token });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

/**
 * Login User (Lokal PostgreSQL)
 */
router.post('/login', async (req, res) => {
    const { email, password } = req.body;

    try {
        const { rows } = await db.query('SELECT * FROM users WHERE email = $1', [email]);
        const user = rows[0];

        if (!user) {
            return res.status(401).json({ error: "Email atau password salah" });
        }

        const validPassword = await bcrypt.compare(password, user.password_hash);
        if (!validPassword) {
            return res.status(401).json({ error: "Email atau password salah" });
        }

        const token = jwt.sign({ id: user.id, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '24h' });

        // Remove password hash from response
        delete user.password_hash;

        res.json({ access_token: token, user });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

module.exports = router;
