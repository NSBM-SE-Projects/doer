import { Router, Response } from 'express';
import { z } from 'zod';
import prisma from '../config/prisma';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';
import { createNotification } from './notifications';

const router = Router();

// ── Static routes MUST come before /:jobId param routes ──

// GET /api/payments/earnings — worker earnings summary
router.get(
  '/earnings',
  authenticate,
  authorize('WORKER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const userId = req.user!.userId;

    const payments = await prisma.payment.findMany({
      where: { job: { worker: { userId } } },
      include: {
        job: {
          select: {
            id: true,
            title: true,
            status: true,
            customer: { include: { user: { select: { name: true } } } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const released = payments.filter(p => p.status === 'RELEASED');
    const held = payments.filter(p => p.status === 'HELD');
    const disputed = payments.filter(p => p.status === 'DISPUTED');

    const now = new Date();
    const thisMonthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const thisMonthReleased = released.filter(p => p.releasedAt && p.releasedAt >= thisMonthStart);

    res.json({
      totalEarnings: released.reduce((sum, p) => sum + p.amount, 0),
      pendingEarnings: held.reduce((sum, p) => sum + p.amount, 0),
      disputedAmount: disputed.reduce((sum, p) => sum + p.amount, 0),
      thisMonthEarnings: thisMonthReleased.reduce((sum, p) => sum + p.amount, 0),
      thisMonthCount: thisMonthReleased.length,
      payments,
    });
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
        dispute: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ payments });
  })
);

// ── Param routes ──

// POST /api/payments/:jobId — create payment and hold in escrow
router.post(
  '/:jobId',
  authenticate,
  authorize('CUSTOMER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const jobId = req.params.jobId as string;

    const job = await prisma.job.findUnique({
      where: { id: jobId },
      include: { customer: true, worker: true, payment: true },
    });
    if (!job) throw AppError.notFound('Job not found');
    if (job.customer.userId !== req.user!.userId) throw AppError.forbidden('Not your job');
    if (job.payment) throw AppError.conflict('Payment already exists for this job');
    if (!job.price) throw AppError.badRequest('Job has no price set');

    // Create payment in HELD status (escrow)
    const payment = await prisma.payment.create({
      data: {
        amount: job.price,
        jobId,
        status: 'HELD',
        heldAt: new Date(),
      },
    });

    // Move job to REVIEWING
    await prisma.job.update({
      where: { id: jobId },
      data: { status: 'REVIEWING' },
    });

    // Notify the worker
    if (job.worker) {
      await createNotification(
        job.worker.userId,
        'Payment Held in Escrow',
        `Rs. ${job.price.toLocaleString()} has been held in escrow for "${job.title}". It will be released in 48 hours.`
      );
    }

    // Notify customer
    await createNotification(
      req.user!.userId,
      'Payment Held',
      `Rs. ${job.price.toLocaleString()} is held securely in escrow for "${job.title}". It will be released to the worker in 48 hours if no dispute is raised.`
    );

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
        dispute: true,
      },
    });
    if (!payment) throw AppError.notFound('Payment not found');

    res.json({ payment });
  })
);

// POST /api/payments/:jobId/release — release funds to worker
router.post(
  '/:jobId/release',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const jobId = req.params.jobId as string;

    const payment = await prisma.payment.findUnique({
      where: { jobId },
      include: { job: { include: { customer: true, worker: true } } },
    });
    if (!payment) throw AppError.notFound('Payment not found');
    if (payment.status !== 'HELD') throw AppError.badRequest('Payment must be in HELD status to release');

    // Only admin or customer can manually release
    const isAdmin = req.user!.role === 'ADMIN';
    const isCustomer = payment.job.customer.userId === req.user!.userId;
    if (!isAdmin && !isCustomer) throw AppError.forbidden('Not authorized to release payment');

    const updated = await prisma.payment.update({
      where: { id: payment.id },
      data: { status: 'RELEASED', releasedAt: new Date() },
    });

    // Close the job if review exists
    const review = await prisma.review.findUnique({ where: { jobId } });
    await prisma.job.update({
      where: { id: jobId },
      data: { status: review ? 'CLOSED' : 'REVIEWING' },
    });

    // Notify worker
    if (payment.job.worker) {
      await createNotification(
        payment.job.worker.userId,
        'Payment Released',
        `Rs. ${payment.amount.toLocaleString()} has been released to your earnings for "${payment.job.title}".`
      );
    }

    // Notify customer
    await createNotification(
      payment.job.customer.userId,
      'Payment Released',
      `Rs. ${payment.amount.toLocaleString()} has been released to the worker for "${payment.job.title}".`
    );

    res.json({ payment: updated });
  })
);

// POST /api/payments/:jobId/dispute — raise a dispute
router.post(
  '/:jobId/dispute',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const jobId = req.params.jobId as string;
    const { reason, description, evidence } = z.object({
      reason: z.string().min(1),
      description: z.string().min(1),
      evidence: z.array(z.string()).optional(),
    }).parse(req.body);

    const payment = await prisma.payment.findUnique({
      where: { jobId },
      include: {
        job: { include: { customer: true, worker: true } },
        dispute: true,
      },
    });
    if (!payment) throw AppError.notFound('Payment not found');
    if (payment.status !== 'HELD') throw AppError.badRequest('Can only dispute payments that are held in escrow');
    if (payment.dispute) throw AppError.conflict('A dispute already exists for this payment');

    const isCustomer = payment.job.customer.userId === req.user!.userId;
    const isWorker = payment.job.worker?.userId === req.user!.userId;
    if (!isCustomer && !isWorker) throw AppError.forbidden('Not authorized to dispute this payment');

    const dispute = await prisma.dispute.create({
      data: {
        reason,
        description,
        customerEvidence: isCustomer ? (evidence || []) : [],
        workerEvidence: isWorker ? (evidence || []) : [],
        paymentId: payment.id,
        raisedBy: req.user!.userId,
      },
    });

    await prisma.payment.update({
      where: { id: payment.id },
      data: { status: 'DISPUTED', disputedAt: new Date() },
    });

    // Notify both parties
    const raisedByRole = isCustomer ? 'customer' : 'worker';
    if (payment.job.worker) {
      await createNotification(
        payment.job.worker.userId,
        'Dispute Raised',
        `A dispute has been raised by the ${raisedByRole} on "${payment.job.title}". An admin will review it.`
      );
    }
    await createNotification(
      payment.job.customer.userId,
      'Dispute Raised',
      `A dispute has been raised by the ${raisedByRole} on "${payment.job.title}". An admin will review it.`
    );

    res.status(201).json({ dispute });
  })
);

// POST /api/payments/:jobId/dispute/respond — respond to a dispute
router.post(
  '/:jobId/dispute/respond',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const jobId = req.params.jobId as string;
    const { response, evidence } = z.object({
      response: z.string().min(1),
      evidence: z.array(z.string()).optional(),
    }).parse(req.body);

    const payment = await prisma.payment.findUnique({
      where: { jobId },
      include: {
        job: { include: { customer: true, worker: true } },
        dispute: true,
      },
    });
    if (!payment) throw AppError.notFound('Payment not found');
    if (!payment.dispute) throw AppError.notFound('No dispute found for this payment');
    if (payment.status !== 'DISPUTED') throw AppError.badRequest('Payment is not in disputed status');

    const isCustomer = payment.job.customer.userId === req.user!.userId;
    const isWorker = payment.job.worker?.userId === req.user!.userId;
    if (!isCustomer && !isWorker) throw AppError.forbidden('Not authorized');

    if (payment.dispute.raisedBy === req.user!.userId) {
      throw AppError.badRequest('You cannot respond to your own dispute');
    }

    const updateData: any = { workerResponse: response };
    if (isWorker) {
      updateData.workerEvidence = evidence || [];
    } else {
      updateData.customerEvidence = evidence || [];
    }

    const updated = await prisma.dispute.update({
      where: { id: payment.dispute.id },
      data: updateData,
    });

    res.json({ dispute: updated });
  })
);

// PATCH /api/payments/:jobId/status — update payment status (legacy/webhook)
router.patch(
  '/:jobId/status',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const jobId = req.params.jobId as string;
    const { status, payhereRef } = z.object({
      status: z.enum(['PENDING', 'HELD', 'RELEASED', 'DISPUTED', 'REFUNDED']),
      payhereRef: z.string().optional(),
    }).parse(req.body);

    const payment = await prisma.payment.findUnique({ where: { jobId } });
    if (!payment) throw AppError.notFound('Payment not found');

    const data: any = { status, payhereRef };
    if (status === 'HELD') data.heldAt = new Date();
    if (status === 'RELEASED') data.releasedAt = new Date();
    if (status === 'DISPUTED') data.disputedAt = new Date();
    if (status === 'REFUNDED') data.refundedAt = new Date();

    const updated = await prisma.payment.update({
      where: { jobId },
      data,
    });

    res.json({ payment: updated });
  })
);

export default router;
