/**
 * ======================================================================
 * Middleware Authentication & Authorization
 * ======================================================================
 * 
 * Deskripsi:
 * Modul ini menyediakan middleware untuk memverifikasi token JWT
 * dan membatasi akses berdasarkan role user.
 * 
 * Middleware yang tersedia:
 * - authenticateToken: Memverifikasi token JWT dan menambahkan data user ke request
 * - isAdmin: Memeriksa apakah user memiliki role 'admin'
 * - isApoteker: Memeriksa apakah user memiliki role 'apoteker' atau 'admin'
 * 
 * Cara Penggunaan:
 * const { authenticateToken, isAdmin, isApoteker } = require('./middleware/auth');
 * 
 * app.get('/protected', authenticateToken, (req, res) => {
 *     // req.user berisi data dari token JWT
 * });
 * 
 * app.get('/admin-only', authenticateToken, isAdmin, (req, res) => {
 *     // Hanya admin yang bisa akses
 * });
 * 
 * ======================================================================
 */

const jwt = require('jsonwebtoken');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'your-default-secret-key';

/**
 * Middleware to verify JWT and authenticate user
 */
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) return res.status(401).json({ error: "Access token required" });

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ error: "Invalid or expired token" });
        req.user = user;
        next();
    });
};

/**
 * Middleware to restrict access to Admins only
 */
const isAdmin = (req, res, next) => {
    if (req.user && req.user.role === 'admin') {
        next();
    } else {
        res.status(403).json({ error: "Admin access required" });
    }
};

/**
 * Middleware untuk membatasi akses ke Apoteker dan Admin
 */
const isApoteker = (req, res, next) => {
    if (req.user && (req.user.role === 'apoteker' || req.user.role === 'admin')) {
        next();
    } else {
        res.status(403).json({ error: "Apoteker or Admin access required" });
    }
};

module.exports = { authenticateToken, isAdmin, isApoteker };
