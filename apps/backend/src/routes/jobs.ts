import { Router, Response } from 'express';
import { z } from 'zod';
import prisma from '../config/prisma';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';
import { createNotification } from './notifications';
import { getIO } from '../sockets';
import { geocode } from '../config/maps';

const router = Router();

const createJobSchema = z.object({
  title: z.string().min(1),
  description: z.string().min(1),
  categoryId: z.string(),
  price: z.number().positive().optional(),
  budgetMin: z.number().positive().optional(),
  budgetMax: z.number().positive().optional(),
  urgency: z.enum(['LOW', 'NORMAL', 'URGENT', 'EMERGENCY']).optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  address: z.string().optional(),
  scheduledAt: z.string().datetime().optional(),
  scheduledEnd: z.string().datetime().optional(),
});

const updateJobSchema = z.object({
  title: z.string().min(1).optional(),
  description: z.string().min(1).optional(),
  price: z.number().positive().optional(),
  budgetMin: z.number().positive().optional(),
  budgetMax: z.number().positive().optional(),
  urgency: z.enum(['LOW', 'NORMAL', 'URGENT', 'EMERGENCY']).optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  address: z.string().optional(),
  scheduledAt: z.string().datetime().optional(),
  scheduledEnd: z.string().datetime().optional(),
});

// POST /api/jobs — create a job (customer only)
router.post(
  '/',
  authenticate,
  authorize('CUSTOMER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const body = createJobSchema.parse(req.body);

    const customerProfile = await prisma.customerProfile.findUnique({
      where: { userId: req.user!.userId },
    });
    if (!customerProfile) throw AppError.notFound('Customer profile not found');

    // Verify category exists
    const category = await prisma.serviceCategory.findUnique({
      where: { id: body.categoryId },
    });
    if (!category) throw AppError.badRequest('Invalid category');

    // Auto-geocode address if provided without coordinates
    let { latitude, longitude } = body;
    if (body.address && !latitude && !longitude) {
      try {
        const geo = await geocode(body.address);
        if (geo) {
          latitude = geo.lat;
          longitude = geo.lng;
        }
      } catch (_) {}
    }

    const job = await prisma.job.create({
      data: {
        title: body.title,
        description: body.description,
        price: body.price,
        budgetMin: body.budgetMin,
        budgetMax: body.budgetMax,
        urgency: body.urgency || 'NORMAL',
        latitude,
        longitude,
        address: body.address,
        scheduledAt: body.scheduledAt ? new Date(body.scheduledAt) : undefined,
        scheduledEnd: body.scheduledEnd ? new Date(body.scheduledEnd) : undefined,
        customerId: customerProfile.id,
        categoryId: body.categoryId,
      },
      include: {
        category: true,
        customer: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } },
      },
    });

    res.status(201).json({ job });
  })
);

// GET /api/jobs — list jobs with filters
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const { status, categoryId, customerId, workerId, page = '1', limit = '20' } = req.query;

    const where: any = {};
    if (status) where.status = status;
    if (categoryId) where.categoryId = categoryId;
    if (customerId) where.customerId = customerId;
    if (workerId) where.workerId = workerId;

    const skip = (Number(page) - 1) * Number(limit);

    const [jobs, total] = await Promise.all([
      prisma.job.findMany({
        where,
        include: {
          category: true,
          customer: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } },
          worker: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: Number(limit),
      }),
      prisma.job.count({ where }),
    ]);

    res.json({ jobs, total, page: Number(page), limit: Number(limit) });
  })
);

// GET /api/jobs/my — get jobs for current user (customer or worker)
router.get(
  '/my',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { status } = req.query;
    const where: any = {};
    if (status) where.status = status;

    if (req.user!.role === 'CUSTOMER') {
      const profile = await prisma.customerProfile.findUnique({
        where: { userId: req.user!.userId },
      });
      if (!profile) throw AppError.notFound('Profile not found');
      where.customerId = profile.id;
    } else if (req.user!.role === 'WORKER') {
      const profile = await prisma.workerProfile.findUnique({
        where: { userId: req.user!.userId },
      });
      if (!profile) throw AppError.notFound('Profile not found');
      where.workerId = profile.id;
    }

    const jobs = await prisma.job.findMany({
      where,
      include: {
        category: true,
        customer: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } },
        worker: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } },
        payment: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ jobs });
  })
);

// GET /api/jobs/available — open jobs for workers to browse
router.get(
  '/available',
  asyncHandler(async (req, res) => {
    const { categoryId } = req.query;

    const where: any = { status: { in: ['OPEN', 'APPLICATIONS_RECEIVED'] } };
    if (categoryId) where.categoryId = categoryId;

    const jobs = await prisma.job.findMany({
      where,
      include: {
        category: true,
        customer: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ jobs });
  })
);

// GET /api/jobs/:id — get single job
router.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const job = await prisma.job.findUnique({
      where: { id: req.params.id as string },
      include: {
        category: true,
        customer: { include: { user: { select: { id: true, name: true, avatarUrl: true, phone: true } } } },
        worker: { include: { user: { select: { id: true, name: true, avatarUrl: true, phone: true } } } },
        review: true,
        payment: true,
      },
    });

    if (!job) throw AppError.notFound('Job not found');

    res.json({ job });
  })
);

// PUT /api/jobs/:id — update job details (customer only, while OPEN)
router.put(
  '/:id',
  authenticate,
  authorize('CUSTOMER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const body = updateJobSchema.parse(req.body);

    const job = await prisma.job.findUnique({
      where: { id: req.params.id as string },
      include: { customer: true },
    });
    if (!job) throw AppError.notFound('Job not found');
    if (job.customer.userId !== req.user!.userId) throw AppError.forbidden('Not your job');
    if (job.status !== 'OPEN') throw AppError.badRequest('Can only edit open jobs');

    const updated = await prisma.job.update({
      where: { id: req.params.id as string },
      data: {
        ...body,
        scheduledAt: body.scheduledAt ? new Date(body.scheduledAt) : undefined,
      },
      include: { category: true },
    });

    res.json({ job: updated });
  })
);

// PATCH /api/jobs/:id/assign — worker accepts a job
router.patch(
  '/:id/assign',
  authenticate,
  authorize('WORKER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const job = await prisma.job.findUnique({
      where: { id: req.params.id as string },
    });
    if (!job) throw AppError.notFound('Job not found');
    if (job.status !== 'OPEN') throw AppError.badRequest('Job is no longer open');

    const workerProfile = await prisma.workerProfile.findUnique({
      where: { userId: req.user!.userId },
    });
    if (!workerProfile) throw AppError.notFound('Worker profile not found');

    const updated = await prisma.job.update({
      where: { id: req.params.id as string },
      data: {
        status: 'ASSIGNED',
        workerId: workerProfile.id,
      },
      include: {
        category: true,
        customer: { include: { user: { select: { id: true, name: true } } } },
        worker: { include: { user: { select: { id: true, name: true } } } },
      },
    });

    // Notify customer
    const customerProfile = await prisma.customerProfile.findUnique({ where: { id: job.customerId } });
    if (customerProfile) {
      await createNotification(
        customerProfile.userId,
        'Worker Assigned',
        `${updated.worker?.user.name} accepted your job "${job.title}"`
      );
    }

    res.json({ job: updated });
  })
);

// PATCH /api/jobs/:id/start — worker starts the job
router.patch(
  '/:id/start',
  authenticate,
  authorize('WORKER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const job = await prisma.job.findUnique({
      where: { id: req.params.id as string },
      include: { worker: true },
    });
    if (!job) throw AppError.notFound('Job not found');
    if (job.worker?.userId !== req.user!.userId) throw AppError.forbidden('Not your job');
    if (job.status !== 'ASSIGNED') throw AppError.badRequest('Job must be assigned first');

    const updated = await prisma.job.update({
      where: { id: req.params.id as string },
      data: { status: 'IN_PROGRESS' },
    });

    // Notify customer
    const custProfile = await prisma.customerProfile.findUnique({ where: { id: job.customerId } });
    if (custProfile) {
      await createNotification(custProfile.userId, 'Job Started', `Work has begun on "${job.title}"`);
      // Real-time status update
      const io = getIO();
      if (io) io.to(`user:${custProfile.userId}`).emit('job_status_update', { jobId: job.id, status: 'IN_PROGRESS' });
    }

    res.json({ job: updated });
  })
);

// PATCH /api/jobs/:id/complete — worker completes the job
router.patch(
  '/:id/complete',
  authenticate,
  authorize('WORKER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const job = await prisma.job.findUnique({
      where: { id: req.params.id as string },
      include: { worker: true },
    });
    if (!job) throw AppError.notFound('Job not found');
    if (job.worker?.userId !== req.user!.userId) throw AppError.forbidden('Not your job');
    if (job.status !== 'IN_PROGRESS') throw AppError.badRequest('Job must be in progress');

    const updated = await prisma.job.update({
      where: { id: req.params.id as string },
      data: { status: 'COMPLETED', completedAt: new Date() },
    });

    // Increment worker's totalJobs
    await prisma.workerProfile.update({
      where: { id: job.workerId! },
      data: { totalJobs: { increment: 1 } },
    });

    // Notify customer
    const cp = await prisma.customerProfile.findUnique({ where: { id: job.customerId } });
    if (cp) {
      await createNotification(cp.userId, 'Job Completed', `"${job.title}" has been completed. Please confirm and leave a review!`);
      // Real-time status update
      const io = getIO();
      if (io) io.to(`user:${cp.userId}`).emit('job_status_update', { jobId: job.id, status: 'COMPLETED' });
    }

    res.json({ job: updated });
  })
);

// PATCH /api/jobs/:id/cancel — cancel a job (customer or worker)
router.patch(
  '/:id/cancel',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const job = await prisma.job.findUnique({
      where: { id: req.params.id as string },
      include: { customer: true, worker: true },
    });
    if (!job) throw AppError.notFound('Job not found');

    // Only the customer or assigned worker can cancel
    const isCustomer = job.customer.userId === req.user!.userId;
    const isWorker = job.worker?.userId === req.user!.userId;
    if (!isCustomer && !isWorker) throw AppError.forbidden('Not authorized to cancel');

    if (job.status === 'COMPLETED' || job.status === 'CANCELLED') {
      throw AppError.badRequest('Job is already ' + job.status.toLowerCase());
    }

    const updated = await prisma.job.update({
      where: { id: req.params.id as string },
      data: {
        status: 'CANCELLED',
        // If worker cancels, unassign them
        ...(isWorker ? { workerId: null } : {}),
      },
    });

    // Notify the other party
    if (isCustomer && job.worker) {
      await createNotification(
        job.worker.userId,
        'Job Cancelled',
        `The customer cancelled "${job.title}"`
      );
    } else if (isWorker) {
      await createNotification(
        job.customer.userId,
        'Job Cancelled',
        `The worker cancelled "${job.title}". You can accept another application.`
      );
    }

    res.json({ job: updated });
  })
);

// POST /api/jobs/:id/review — leave a review (customer only, after completion)
router.post(
  '/:id/review',
  authenticate,
  authorize('CUSTOMER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { rating, comment, photoUrls } = z.object({
      rating: z.number().int().min(1).max(5),
      comment: z.string().optional(),
      photoUrls: z.array(z.string()).optional(),
    }).parse(req.body);

    const job = await prisma.job.findUnique({
      where: { id: req.params.id as string },
      include: { customer: true, review: true },
    });
    if (!job) throw AppError.notFound('Job not found');
    if (job.customer.userId !== req.user!.userId) throw AppError.forbidden('Not your job');
    if (job.status !== 'COMPLETED' && job.status !== 'REVIEWING') {
      throw AppError.badRequest('Can only review completed or reviewing jobs');
    }
    if (job.review) throw AppError.conflict('Review already exists');
    if (!job.workerId) throw AppError.badRequest('No worker assigned');

    const review = await prisma.review.create({
      data: {
        rating,
        comment,
        photoUrls: photoUrls || [],
        jobId: job.id,
        customerId: job.customerId,
        workerId: job.workerId,
      },
    });

    // Update worker's average rating
    const avgResult = await prisma.review.aggregate({
      where: { workerId: job.workerId },
      _avg: { rating: true },
    });
    await prisma.workerProfile.update({
      where: { id: job.workerId },
      data: { rating: avgResult._avg.rating || 0 },
    });

    // Check if payment is also done — if so, auto-close the job
    const payment = await prisma.payment.findUnique({ where: { jobId: job.id } });
    const newStatus = payment?.status === 'RELEASED' ? 'CLOSED' : 'REVIEWING';

    await prisma.job.update({
      where: { id: req.params.id as string },
      data: { status: newStatus },
    });

    res.status(201).json({ review });
  })
);

// PATCH /api/jobs/:id/close — close a reviewed job (customer)
router.patch(
  '/:id/close',
  authenticate,
  authorize('CUSTOMER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const job = await prisma.job.findUnique({
      where: { id: req.params.id as string },
      include: { customer: true },
    });
    if (!job) throw AppError.notFound('Job not found');
    if (job.customer.userId !== req.user!.userId) throw AppError.forbidden('Not your job');
    if (job.status !== 'REVIEWING' && job.status !== 'COMPLETED') {
      throw AppError.badRequest('Job must be completed or reviewed first');
    }

    const updated = await prisma.job.update({
      where: { id: req.params.id as string },
      data: { status: 'CLOSED' },
    });

    res.json({ job: updated });
  })
);

export default router;
