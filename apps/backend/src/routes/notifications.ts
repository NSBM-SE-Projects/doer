import { Router, Response } from 'express';
import prisma from '../config/prisma';
import { authenticate, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';
import { getIO } from '../sockets';

const router = Router();

// GET /api/notifications — get notifications for current user
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

// PATCH /api/notifications/:id/read — mark single notification as read
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

// PATCH /api/notifications/read-all — mark all as read
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

// Helper: create a notification and push via Socket.IO
export async function createNotification(
  userId: string,
  title: string,
  body: string
) {
  const notification = await prisma.notification.create({
    data: { userId, title, body },
  });

  const io = getIO();
  if (io) {
    io.to(`user:${userId}`).emit('new_notification', notification);
  }

  return notification;
}

export default router;
