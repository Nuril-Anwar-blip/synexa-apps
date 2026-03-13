/**
 * socketManager.js
 *
 * Modul ini menyimpan instance 'io' Socket.io secara global agar bisa
 * diakses oleh semua route tanpa harus di-pass secara manual.
 *
 * Cara pemakaian:
 *   const { getIO } = require('../config/socketManager');
 *   getIO().to(userId).emit('event_name', data);
 */

let _io = null;

/**
 * Inisialisasi Socket Manager dengan instance io dari index.js.
 * Dipanggil SEKALI saat server pertama kali dijalankan.
 * @param {import('socket.io').Server} io
 */
const initSocket = (io) => {
    _io = io;
};

/**
 * Mendapatkan instance io yang sudah diinisialisasi.
 * Melempar error jika dipanggil sebelum initSocket().
 * @returns {import('socket.io').Server}
 */
const getIO = () => {
    if (!_io) {
        throw new Error('Socket.io has not been initialized! Call initSocket(io) first in index.js');
    }
    return _io;
};

module.exports = { initSocket, getIO };
