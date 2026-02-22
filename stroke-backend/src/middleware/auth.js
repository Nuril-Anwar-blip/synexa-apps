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
 * Middleware to restrict access to Health Workers and Admins
 */
const isWorker = (req, res, next) => {
    if (req.user && (req.user.role === 'worker' || req.user.role === 'admin')) {
        next();
    } else {
        res.status(403).json({ error: "Worker or Admin access required" });
    }
};

module.exports = { authenticateToken, isAdmin, isWorker };
