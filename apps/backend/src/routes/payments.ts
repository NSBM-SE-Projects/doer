import { Router, Response } from 'express';
import { z } from 'zod';
import prisma from '../config/prisma';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';
import { createNotification } from './notifications';

const router = Router();

// POST /api/payments/:jobId — create a payment for a job
router.post(
  '/:jobId',
  authenticate,
  authorize('CUSTOMER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const jobId = req.params.jobId as string;

    const job = await prisma.job.findUnique({
      where: { id: jobId },
      include: { customer: true, payment: true },
    });
    if (!job) throw AppError.notFound('Job not found');
    if (job.customer.userId !== req.user!.userId) throw AppError.forbidden('Not your job');
    if (job.payment) throw AppError.conflict('Payment already exists for this job');
    if (!job.price) throw AppError.badRequest('Job has no price set');

    const payment = await prisma.payment.create({
      data: {
        amount: job.price,
        jobId,
        status: 'PENDING',
      },
    });

    res.status(201).json({ payment });
  })
);

// GET /api/payments/:jobId — get payment for a job
router.get(
  '/:jobId',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const jobId = req.params.jobId as string;

    const payment = await prisma.payment.findUnique({
      where: { jobId },
      include: {
        job: {
          select: { id: true, title: true, status: true, price: true },
        },
      },
    });
    if (!payment) throw AppError.notFound('Payment not found');

    res.json({ payment });
  })
);

// PATCH /api/payments/:jobId/status — update payment status (for PayHere webhook or manual)
router.patch(
  '/:jobId/status',
  asyncHandler(async (req, res) => {
    const jobId = req.params.jobId as string;
    const { status, payhereRef } = z.object({
      status: z.enum(['PENDING', 'COMPLETED', 'FAILED', 'REFUNDED']),
      payhereRef: z.string().optional(),
    }).parse(req.body);

    const payment = await prisma.payment.findUnique({
      where: { jobId },
    });
    if (!payment) throw AppError.notFound('Payment not found');

    const updated = await prisma.payment.update({
      where: { jobId },
      data: { status, payhereRef },
    });

    // Notify both parties on payment status change
    if (status === 'COMPLETED') {
      const job = await prisma.job.findUnique({
        where: { id: jobId },
        include: { customer: true, worker: true },
      });
      if (job) {
        if (job.customer) {
          await createNotification(
            job.customer.userId,
            'Payment Confirmed',
            `Payment of Rs. ${payment.amount} for "${job.title}" has been confirmed`
          );
        }
        if (job.worker) {
          await createNotification(
            job.worker.userId,
            'Payment Received',
            `Rs. ${payment.amount} has been added to your earnings for "${job.title}"`
          );
        }
      }
    }

    res.json({ payment: updated });
  })
);

// GET /api/payments — get all payments for current user's jobs
router.get(
  '/',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const userId = req.user!.userId;

    const payments = await prisma.payment.findMany({
      where: {
        job: {
          OR: [
            { customer: { userId } },
            { worker: { userId } },
          ],
        },
      },
      include: {
        job: {
          select: {
            id: true,
            title: true,
            status: true,
            customer: { include: { user: { select: { name: true } } } },
            worker: { include: { user: { select: { name: true } } } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ payments });
  })
);

export default router;
