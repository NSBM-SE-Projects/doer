import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import * as messageService from '../services/message.service';
import { success, error } from '../utils/response';

export const getMessageHistory = async (req: AuthRequest, res: Response) => {
  try {
    const messages = await messageService.getMessageHistory(req.params.jobId);
    return success(res, messages);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to get messages';
    return error(res, message, 500);
  }
};

export const sendMessage = async (req: AuthRequest, res: Response) => {
  try {
    const { jobId, content } = req.body;
    if (!jobId || !content) return error(res, 'jobId and content are required');

    const message = await messageService.sendMessage(jobId, req.user!.dbUserId, content);
    return success(res, message, 201);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to send message';
    return error(res, message, 500);
  }
};

export const getConversations = async (req: AuthRequest, res: Response) => {
  try {
    const conversations = await messageService.getConversations(req.user!.dbUserId);
    return success(res, conversations);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to get conversations';
    return error(res, message, 500);
  }
};
