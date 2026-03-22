import { Server } from 'socket.io';
import { Server as HttpServer } from 'http';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import redisClient from '../config/redis';
import prisma from '../config/prisma';

const LOCATION_TTL = 35 * 60; // 35 minutes in seconds
const STATUS_TTL = 30 * 60;   // 30 minutes in seconds

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

  io.on('connection', async (socket) => {
    const userId = socket.data.userId;
    const role = socket.data.role;
    console.log(`User ${userId} connected (socket: ${socket.id})`);

    // Join user's personal room for notifications
    socket.join(`user:${userId}`);

    // Worker presence: mark online + store location on connect
    if (role === 'WORKER') {
      const worker = await prisma.workerProfile.findUnique({ where: { userId } });
      if (worker) {
        await redisClient.set(`worker:status:${worker.id}`, 'online', { EX: LOCATION_TTL });
        // Seed location from profile if available
        if (worker.latitude && worker.longitude) {
          await redisClient.set(
            `worker:location:${worker.id}`,
            JSON.stringify({ lat: worker.latitude, lng: worker.longitude }),
            { EX: LOCATION_TTL }
          );
        }
        socket.data.workerProfileId = worker.id;
      }
    }

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

    // Video call — ring the other user
    socket.on('call_user', (data: { targetUserId: string; channelName: string; callerName: string }) => {
      io!.to(`user:${data.targetUserId}`).emit('incoming_call', {
        callerId: userId,
        callerName: data.callerName,
        channelName: data.channelName,
      });
    });

    // Video call — caller cancelled or call ended
    socket.on('call_end', (data: { targetUserId: string }) => {
      io!.to(`user:${data.targetUserId}`).emit('call_ended', { callerId: userId });
    });

    // Video call — callee declined
    socket.on('call_decline', (data: { targetUserId: string }) => {
      io!.to(`user:${data.targetUserId}`).emit('call_declined', { userId });
    });

    // Worker location update (sent every 5 min from worker app)
    socket.on('location_update', async (data: { lat: number; lng: number }) => {
      const wpId = socket.data.workerProfileId;
      if (!wpId) return;
      await redisClient.set(
        `worker:location:${wpId}`,
        JSON.stringify({ lat: data.lat, lng: data.lng }),
        { EX: LOCATION_TTL }
      );
      await redisClient.set(`worker:status:${wpId}`, 'online', { EX: LOCATION_TTL });
    });

    socket.on('disconnect', async () => {
      console.log(`User ${userId} disconnected`);
      // Mark worker as "away" — Redis TTL will auto-expire after 30min (= offline)
      const wpId = socket.data.workerProfileId;
      if (wpId) {
        await redisClient.set(`worker:status:${wpId}`, 'away', { EX: STATUS_TTL });
      }
    });
  });

  return io;
};
