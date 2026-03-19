import { Router, Response } from 'express';
import { z } from 'zod';
import prisma from '../config/prisma';
import { authenticate, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';
import { getIO } from '../sockets';

const router = Router();

const sendMessageSchema = z.object({
  content: z.string().min(1),
});

// GET /api/messages/:jobId — get messages for a job
router.get(
  '/:jobId',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const jobId = req.params.jobId as string;

    // Verify user is part of this job
    const job = await prisma.job.findUnique({
      where: { id: jobId },
      include: { customer: true, worker: true },
    });
    if (!job) throw AppError.notFound('Job not found');

    const isCustomer = job.customer.userId === req.user!.userId;
    const isWorker = job.worker?.userId === req.user!.userId;
    if (!isCustomer && !isWorker) throw AppError.forbidden('Not part of this job');

    const messages = await prisma.message.findMany({
      where: { jobId },
      include: {
        sender: { select: { id: true, name: true, avatarUrl: true } },
      },
      orderBy: { createdAt: 'asc' },
    });

    res.json({ messages });
  })
);

// POST /api/messages/:jobId — send a message in a job
router.post(
  '/:jobId',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const jobId = req.params.jobId as string;
    const { content } = sendMessageSchema.parse(req.body);

    // Verify user is part of this job
    const job = await prisma.job.findUnique({
      where: { id: jobId },
      include: { customer: true, worker: true },
    });
    if (!job) throw AppError.notFound('Job not found');

    const isCustomer = job.customer.userId === req.user!.userId;
    const isWorker = job.worker?.userId === req.user!.userId;
    if (!isCustomer && !isWorker) throw AppError.forbidden('Not part of this job');

    const message = await prisma.message.create({
      data: {
        content,
        jobId,
        senderId: req.user!.userId,
      },
      include: {
        sender: { select: { id: true, name: true, avatarUrl: true } },
      },
    });

    // Emit via Socket.IO to the job room
    const io = getIO();
    if (io) {
      io.to(`job:${jobId}`).emit('new_message', message);
    }

    res.status(201).json({ message });
  })
);

// GET /api/messages — get all conversations for current user
router.get(
  '/',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const userId = req.user!.userId;

    // Find all jobs this user is part of that have messages
    const jobs = await prisma.job.findMany({
      where: {
        OR: [
          { customer: { userId } },
          { worker: { userId } },
        ],
        messages: { some: {} },
      },
      include: {
        customer: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } },
        worker: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          include: {
            sender: { select: { id: true, name: true } },
          },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });

    const conversations = jobs.map((job) => ({
      jobId: job.id,
      jobTitle: job.title,
      otherUser: job.customer.userId === userId ? job.worker?.user : job.customer.user,
      lastMessage: job.messages[0] || null,
    }));

    res.json({ conversations });
  })
);

export default router;
