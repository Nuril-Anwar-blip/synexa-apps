require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const http = require('http');
const { Server } = require('socket.io');
const { authenticateToken } = require('./middleware/auth');

// Routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const healthRoutes = require('./routes/health');
const sensorRoutes = require('./routes/sensor');
const medicationRoutes = require('./routes/medication');
const communityRoutes = require('./routes/community');
const educationRoutes = require('./routes/education');
const rehabRoutes = require('./routes/rehab');
const emergencyRoutes = require('./routes/emergency');
const notificationsRoutes = require('./routes/notifications');
const chatRoutes = require('./routes/chat');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: { origin: '*' }
});

// Middlewares
app.use(cors());
app.use(bodyParser.json());

// Public Routes
app.use('/auth', authRoutes);

// Protected Routes (Require JWT)
app.use('/users', authenticateToken, userRoutes);
app.use('/health', authenticateToken, healthRoutes);
app.use('/sensor', authenticateToken, sensorRoutes);
app.use('/medication', authenticateToken, medicationRoutes);
app.use('/community', authenticateToken, communityRoutes);
app.use('/education', authenticateToken, educationRoutes);
app.use('/rehab', authenticateToken, rehabRoutes);
app.use('/emergency', authenticateToken, emergencyRoutes);
app.use('/notifications', authenticateToken, notificationsRoutes);
app.use('/chat', authenticateToken, chatRoutes);

// Socket.io Real-time Chat
io.on('connection', (socket) => {
    console.log('User connected:', socket.id);

    socket.on('join_room', (roomId) => {
        socket.join(roomId);
        console.log(`User joined room ${roomId}`);
    });

    socket.on('send_message', (data) => {
        // Data: { roomId, senderId, content, senderName }
        io.to(data.roomId).emit('receive_message', data);
    });

    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
    });
});

// Basic Health Check
app.get('/', (req, res) => {
    res.json({ status: 'Synexa Data Center (Standalone SQL) is active' });
});

// Start Server
const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT}`);
});

module.exports = { app, server, io };
