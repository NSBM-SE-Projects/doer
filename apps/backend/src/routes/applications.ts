import { Router, Response } from 'express';
import { z } from 'zod';
import prisma from '../config/prisma';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';
import { createNotification } from './notifications';

const router = Router();

const applySchema = z.object({
  message: z.string().optional(),
  price: z.number().positive().optional(),
});

// POST /api/applications/:jobId — worker applies to a job
router.post(
  '/:jobId',
  authenticate,
  authorize('WORKER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const jobId = req.params.jobId as string;
    const body = applySchema.parse(req.body);

    const job = await prisma.job.findUnique({ where: { id: jobId } });
    if (!job) throw AppError.notFound('Job not found');
    if (job.status !== 'OPEN' && job.status !== 'APPLICATIONS_RECEIVED') {
      throw AppError.badRequest('Job is not accepting applications');
    }

    const workerProfile = await prisma.workerProfile.findUnique({
      where: { userId: req.user!.userId },
    });
    if (!workerProfile) throw AppError.notFound('Worker profile not found');

    // Check if already applied
    const existing = await prisma.jobApplication.findUnique({
      where: { jobId_workerId: { jobId, workerId: workerProfile.id } },
    });
    if (existing) throw AppError.conflict('Already applied to this job');

    const application = await prisma.jobApplication.create({
      data: {
        jobId,
        workerId: workerProfile.id,
        message: body.message,
        price: body.price,
      },
      include: {
        worker: {
          include: {
            user: { select: { id: true, name: true, avatarUrl: true } },
            categories: { include: { category: true } },
          },
        },
      },
    });

    // Update job status to APPLICATIONS_RECEIVED if it's still OPEN
    if (job.status === 'OPEN') {
      await prisma.job.update({
        where: { id: jobId },
        data: { status: 'APPLICATIONS_RECEIVED' },
      });
    }

    // Notify the customer
    const customerProfile = await prisma.customerProfile.findUnique({
      where: { id: job.customerId },
    });
    if (customerProfile) {
      const workerName = application.worker.user.name;
      await createNotification(
        customerProfile.userId,
        'New Application',
        `${workerName} applied to your job "${job.title}"`
      );
    }

    res.status(201).json({ application });
  })
);

// GET /api/applications/job/:jobId — get all applications for a job (customer)
router.get(
  '/job/:jobId',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const jobId = req.params.jobId as string;

    const job = await prisma.job.findUnique({
      where: { id: jobId },
      include: { customer: true },
    });
    if (!job) throw AppError.notFound('Job not found');
    if (job.customer.userId !== req.user!.userId && req.user!.role !== 'ADMIN') {
      throw AppError.forbidden('Not your job');
    }

    const applications = await prisma.jobApplication.findMany({
      where: { jobId },
      include: {
        worker: {
          include: {
            user: { select: { id: true, name: true, avatarUrl: true, phone: true } },
            categories: { include: { category: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ applications });
  })
);

// GET /api/applications/my — get worker's own applications
router.get(
  '/my',
  authenticate,
  authorize('WORKER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const workerProfile = await prisma.workerProfile.findUnique({
      where: { userId: req.user!.userId },
    });
    if (!workerProfile) throw AppError.notFound('Worker profile not found');

    const applications = await prisma.jobApplication.findMany({
      where: { workerId: workerProfile.id },
      include: {
        job: {
          include: {
            category: true,
            customer: { include: { user: { select: { id: true, name: true } } } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ applications });
  })
);

// PATCH /api/applications/:id/accept — customer accepts an application
router.patch(
  '/:id/accept',
  authenticate,
  authorize('CUSTOMER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const application = await prisma.jobApplication.findUnique({
      where: { id: req.params.id as string },
      include: {
        job: { include: { customer: true } },
        worker: { include: { user: true } },
      },
    });
    if (!application) throw AppError.notFound('Application not found');
    if (application.job.customer.userId !== req.user!.userId) {
      throw AppError.forbidden('Not your job');
    }
    if (application.status !== 'PENDING') {
      throw AppError.badRequest('Application is no longer pending');
    }

    // Accept this application
    const updated = await prisma.jobApplication.update({
      where: { id: application.id },
      data: { status: 'ACCEPTED' },
    });

    // Assign worker to job and update status
    await prisma.job.update({
      where: { id: application.jobId },
      data: {
        status: 'ASSIGNED',
        workerId: application.workerId,
        price: application.price || application.job.price,
      },
    });

    // Reject all other pending applications
    await prisma.jobApplication.updateMany({
      where: {
        jobId: application.jobId,
        id: { not: application.id },
        status: 'PENDING',
      },
      data: { status: 'REJECTED' },
    });

    // Notify the accepted worker
    await createNotification(
      application.worker.userId,
      'Application Accepted!',
      `Your application for "${application.job.title}" was accepted!`
    );

    res.json({ application: updated });
  })
);

// PATCH /api/applications/:id/reject — customer rejects an application
router.patch(
  '/:id/reject',
  authenticate,
  authorize('CUSTOMER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const application = await prisma.jobApplication.findUnique({
      where: { id: req.params.id as string },
      include: { job: { include: { customer: true } } },
    });
    if (!application) throw AppError.notFound('Application not found');
    if (application.job.customer.userId !== req.user!.userId) {
      throw AppError.forbidden('Not your job');
    }

    const updated = await prisma.jobApplication.update({
      where: { id: application.id },
      data: { status: 'REJECTED' },
    });

    res.json({ application: updated });
  })
);

// DELETE /api/applications/:id/withdraw — worker withdraws application
router.delete(
  '/:id/withdraw',
  authenticate,
  authorize('WORKER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const application = await prisma.jobApplication.findUnique({
      where: { id: req.params.id as string },
      include: { worker: true },
    });
    if (!application) throw AppError.notFound('Application not found');
    if (application.worker.userId !== req.user!.userId) {
      throw AppError.forbidden('Not your application');
    }
    if (application.status !== 'PENDING') {
      throw AppError.badRequest('Can only withdraw pending applications');
    }

    const updated = await prisma.jobApplication.update({
      where: { id: application.id },
      data: { status: 'WITHDRAWN' },
    });

    res.json({ application: updated });
  })
);

export default router;
