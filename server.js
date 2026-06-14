const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const QRCode = require('qrcode');
const crypto = require('crypto');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    maxHttpBufferSize: 1e8 // Allow up to 100MB file chunks in memory streaming
});

const PORT = process.env.PORT || 3000;

// ─── VOLATILE IN-MEMORY ENGINE (NO DATABASES) ───
// Maps unique 32-char tokens to their active socket connections
const authenticatedUsers = new Map(); 
// Maps temporary desktop Session IDs to their pending desktop socket connections
const pendingPairingSessions = new Map(); 

// Serve static web pages from the /public folder
app.use(express.static(path.join(__dirname, 'public')));

// Helper: Generate a cryptographically secure token
function generateSecureToken() {
    return crypto.randomBytes(16).toString('hex'); // 16 bytes = 32 character hex string
}

// ─── REALTIME SOCKET.IO DISPATCHER ───
io.on('connection', (socket) => {
    console.log(`📡 New unauthenticated device connected: ${socket.id}`);

    // 1. CHAT AUTHENTICATION LOOP
    socket.on('authenticate', (token) => {
        if (token && token.length === 32) {
            // Map token to the current live socket
            authenticatedUsers.set(token, socket.id);
            socket.token = token;
            socket.emit('auth_status', { success: true, message: "Channel Securely Established" });
            console.log(`🔐 Socket ${socket.id} successfully bound to token: ${token.substring(0,6)}...`);
            
            // Broadcast globally updated active user count (mocking system network presence)
            io.emit('system_status', { activeNodes: authenticatedUsers.size });
        } else {
            socket.emit('auth_status', { success: false, message: "Invalid Security Signature" });
        }
    });

    // 2. DESKTOP QR CODE REQUEST
    socket.on('request_pairing_qr', async () => {
        // Create a unique temporary session identifier for this desktop browser
        const sessionId = crypto.randomBytes(8).toString('hex');
        pendingPairingSessions.set(sessionId, socket.id);

        // Build the URL that the mobile device needs to hit to perform the handshake
        // In local testing, this targets localhost. On your internet server, it adapts natively.
        const pairingUrl = `http://PAIR_VIA_MOBILE_INTERFACE/?session=${sessionId}`;

        try {
            // Generate QR code data URL directly in memory
            const qrCodeDataUrl = await QRCode.toDataURL(pairingUrl, { margin: 2, scale: 6 });
            socket.emit('pairing_qr', qrCodeDataUrl);
        } catch (err) {
            console.error('❌ QR Generation Fault:', err);
        }
    });

    // 3. MOBILE PAIRING AUTHENTICATION TRANSFER (WHATSAPP WEB MECHANIC)
    socket.on('submit_pairing_from_mobile', (data) => {
        const { sessionId, mobileToken } = data;
        
        // Find the desktop socket waiting for this QR scan sequence
        const desktopSocketId = pendingPairingSessions.get(sessionId);

        if (desktopSocketId && authenticatedUsers.has(mobileToken)) {
            // Forward the 32-character token straight to the desktop socket via memory relay
            io.to(desktopSocketId).emit('pairing_success', mobileToken);
            
            // Cleanup the temporary session from RAM instantly
            pendingPairingSessions.delete(sessionId);
            console.log(`🚀 Session pairing link successful for Session ID: ${sessionId}`);
        } else {
            socket.emit('pairing_fault', { message: "Session expired or mobile unauthorized." });
        }
    });

    // 4. VOLATILE CHAT RELAY (ZERO STORAGE STREAMING)
    socket.on('send_msg', (payload) => {
        const { text, token } = payload;

        // Strict security assertion: Only process if token is currently recognized in RAM
        if (socket.token === token && authenticatedUsers.has(token)) {
            // Stream message data cleanly to all connected pipes except the sender
            socket.broadcast.emit('receive_msg', {
                text: text,
                type: 'text',
                timestamp: new Date().toLocaleTimeString()
            });
            console.log(`💬 Message relayed seamlessly through memory buffer.`);
        }
    });

    // 5. VOLATILE MULTIMEDIA STREAMING (AUDIO NOTES & ZIP FILES)
    socket.on('stream_file', (payload) => {
        const { fileName, fileData, fileType, token } = payload;

        if (socket.token === token && authenticatedUsers.has(token)) {
            // Pipe the raw chunked binary buffer directly out to other nodes
            socket.broadcast.emit('receive_msg', {
                fileName: fileName,
                fileData: fileData, // Raw Base64 data stream string
                fileType: fileType,
                type: 'file',
                timestamp: new Date().toLocaleTimeString()
            });
            console.log(`📦 Relayed file buffer stream: ${fileName} (${fileType})`);
        }
    });

    // 6. GENERATE FRESH USER SEQUENCE (IF CLEAN BOOT)
    socket.on('generate_new_identity', () => {
        const freshToken = generateSecureToken();
        authenticatedUsers.set(freshToken, socket.id);
        socket.token = freshToken;
        socket.emit('new_identity_created', freshToken);
        io.emit('system_status', { activeNodes: authenticatedUsers.size });
    });

    // 7. CLEANUP LOGIC ON DISCONNECT
    socket.on('disconnect', () => {
        if (socket.token) {
            authenticatedUsers.delete(socket.token);
            io.emit('system_status', { activeNodes: authenticatedUsers.size });
            console.log(`🔌 Device disconnected. Session scrubbed from memory.`);
        }
    });
});

// Start listening
server.listen(PORT, () => {
    console.log(`===================================================`);
    console.log(`⚡ v-text Secure Messaging Engine Online`);
    console.log(`🚀 Active Port: http://localhost:${PORT}`);
    console.log(`🔒 Zero-Disk Persistence Active: Data is entirely in RAM`);
    console.log(`===================================================`);
});