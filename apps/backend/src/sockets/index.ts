import { Server } from 'socket.io';
import { Server as HttpServer } from 'http';
import { sendMessage } from '../services/message.service';

export const initSocket = (httpServer: HttpServer) => {
  const io = new Server(httpServer, {
    cors: {
      origin: '*',
    },
  });

  io.on('connection', (socket) => {
    console.log('Client connected:', socket.id);

    socket.on('join-room', (jobId: string) => {
      socket.join(`job:${jobId}`);
      console.log(`Socket ${socket.id} joined room job:${jobId}`);
    });

    socket.on(
      'send-message',
      async (data: { jobId: string; senderId: string; content: string }) => {
        try {
          const { jobId, senderId, content } = data;
          if (!jobId || !senderId || !content) return;

          const message = await sendMessage(jobId, senderId, content);
          io.to(`job:${jobId}`).emit('message-received', message);
        } catch (err) {
          console.error('Socket send-message error:', err);
          socket.emit('error', { message: 'Failed to send message' });
        }
      }
    );

    socket.on('typing', (data: { jobId: string; userId: string; name: string }) => {
      const { jobId, userId, name } = data;
      socket.to(`job:${jobId}`).emit('user-typing', { userId, name });
    });

    socket.on('leave-room', (jobId: string) => {
      socket.leave(`job:${jobId}`);
      console.log(`Socket ${socket.id} left room job:${jobId}`);
    });

    socket.on('disconnect', () => {
      console.log('Client disconnected:', socket.id);
    });
  });

  return io;
};
