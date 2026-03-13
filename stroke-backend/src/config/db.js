/**
 * ======================================================================
 * Konfigurasi Database PostgreSQL
 * ======================================================================
 * 
 * Deskripsi:
 * Modul ini menangani koneksi ke database PostgreSQL menggunakan
 * library pg (node-postgres). Menggunakan connection pooling untuk
 * performa yang lebih baik.
 * 
 * Cara Penggunaan:
 * const db = require('./config/db');
 * const result = await db.query('SELECT * FROM users');
 * 
 * Catatan:
 * - Pastikan DATABASE_URL sudah dikonfigurasi di file .env
 * - Pool akan otomatis terhubung saat module di-import
 * - Jika terjadi error pada koneksi, proses akan berhenti dengan exit code -1
 * 
 * ======================================================================
 */

const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
});

pool.on('connect', () => {
    console.log('Connected to PostgreSQL successfully');
});

pool.on('error', (err) => {
    console.error('Unexpected error on idle client', err);
    process.exit(-1);
});

module.exports = {
    query: (text, params) => pool.query(text, params),
    pool
};
