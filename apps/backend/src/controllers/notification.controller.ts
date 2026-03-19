import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import * as notificationService from '../services/notification.service';
import { success, error } from '../utils/response';

export const getNotifications = async (req: AuthRequest, res: Response) => {
  try {
    const notifications = await notificationService.getUserNotifications(req.user!.dbUserId);
    return success(res, notifications);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to get notifications';
    return error(res, message, 500);
  }
};

export const markAsRead = async (req: AuthRequest, res: Response) => {
  try {
    await notificationService.markAsRead(req.params.id, req.user!.dbUserId);
    return success(res, { message: 'Notification marked as read' });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to mark notification';
    return error(res, message, 500);
  }
};

export const markAllAsRead = async (req: AuthRequest, res: Response) => {
  try {
    await notificationService.markAllAsRead(req.user!.dbUserId);
    return success(res, { message: 'All notifications marked as read' });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to mark notifications';
    return error(res, message, 500);
  }
};
