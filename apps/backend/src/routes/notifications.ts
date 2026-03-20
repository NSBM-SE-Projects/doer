import { Router, Response } from 'express';
import prisma from '../config/prisma';
import { authenticate, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';
import { getIO } from '../sockets';
import admin, { isFirebaseConfigured } from '../config/firebase';

const router = Router();

// GET /api/notifications
router.get(
  '/',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.user!.userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    const unreadCount = await prisma.notification.count({
      where: { userId: req.user!.userId, isRead: false },
    });

    res.json({ notifications, unreadCount });
  })
);

// PATCH /api/notifications/:id/read
router.patch(
  '/:id/read',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const notification = await prisma.notification.findUnique({
      where: { id: req.params.id as string },
    });
    if (!notification) throw AppError.notFound('Notification not found');
    if (notification.userId !== req.user!.userId) throw AppError.forbidden();

    const updated = await prisma.notification.update({
      where: { id: req.params.id as string },
      data: { isRead: true },
    });

    res.json({ notification: updated });
  })
);

// PATCH /api/notifications/read-all
router.patch(
  '/read-all',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    await prisma.notification.updateMany({
      where: { userId: req.user!.userId, isRead: false },
      data: { isRead: true },
    });

    res.json({ message: 'All notifications marked as read' });
  })
);

// POST /api/notifications/register-token — store FCM device token
router.post(
  '/register-token',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { fcmToken } = req.body;
    if (!fcmToken) throw AppError.badRequest('fcmToken is required');

    // Store FCM token on the user (we'll add this field to schema)
    // For now, store in Redis for quick lookup
    const redisClient = (await import('../config/redis')).default;
    await redisClient.set(`fcm:${req.user!.userId}`, fcmToken);

    res.json({ message: 'Token registered' });
  })
);

// Helper: create notification + Socket.IO push + FCM push
export async function createNotification(
  userId: string,
  title: string,
  body: string
) {
  const notification = await prisma.notification.create({
    data: { userId, title, body },
  });

  // Push via Socket.IO (real-time, if user is connected)
  const io = getIO();
  if (io) {
    io.to(`user:${userId}`).emit('new_notification', notification);
  }

  // Push via FCM (works even when app is in background/closed)
  if (isFirebaseConfigured) {
    try {
      const redisClient = (await import('../config/redis')).default;
      const fcmToken = await redisClient.get(`fcm:${userId}`);
      if (fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: { title, body },
          data: {
            notificationId: notification.id,
            type: 'notification',
          },
          android: {
            priority: 'high',
            notification: { sound: 'default', channelId: 'doer_notifications' },
          },
          apns: {
            payload: { aps: { sound: 'default', badge: 1 } },
          },
        });
      }
    } catch (e) {
      // FCM push is best-effort — don't fail the whole operation
      console.warn('FCM push failed:', e);
    }
  }

  return notification;
}

export default router;
