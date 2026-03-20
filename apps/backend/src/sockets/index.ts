import { Server } from 'socket.io';
import { Server as HttpServer } from 'http';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';

let io: Server | null = null;

export const getIO = (): Server | null => io;

export const initSocket = (httpServer: HttpServer) => {
  io = new Server(httpServer, {
    cors: {
      origin: process.env.NODE_ENV === 'production' ? [] : '*',
      credentials: true,
    },
  });

  // Authenticate socket connections via JWT
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.split(' ')[1];
    if (!token) {
      return next(new Error('Authentication required'));
    }

    try {
      const decoded = jwt.verify(token, env.JWT_SECRET) as { userId: string; role: string };
      socket.data.userId = decoded.userId;
      socket.data.role = decoded.role;
      next();
    } catch {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.data.userId;
    console.log(`User ${userId} connected (socket: ${socket.id})`);

    // Join user's personal room for notifications
    socket.join(`user:${userId}`);

    // Join a job room for messaging
    socket.on('join_job', (jobId: string) => {
      socket.join(`job:${jobId}`);
      console.log(`User ${userId} joined job:${jobId}`);
    });

    // Leave a job room
    socket.on('leave_job', (jobId: string) => {
      socket.leave(`job:${jobId}`);
    });

    // Typing indicator
    socket.on('typing', (data: { jobId: string }) => {
      socket.to(`job:${data.jobId}`).emit('user_typing', {
        userId,
        jobId: data.jobId,
      });
    });

    socket.on('disconnect', () => {
      console.log(`User ${userId} disconnected`);
    });
  });

  return io;
};
