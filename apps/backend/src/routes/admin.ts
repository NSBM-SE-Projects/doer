import { Router, Response } from 'express';
import { z } from 'zod';
import prisma from '../config/prisma';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';

const router = Router();

// All admin routes require authentication + ADMIN role
router.use(authenticate, authorize('ADMIN'));

// ---------------------------------------------------------------------------
// GET /admin/stats — Dashboard statistics
// ---------------------------------------------------------------------------
router.get(
  '/stats',
  asyncHandler(async (_req: AuthRequest, res: Response) => {
    const now = new Date();
    const sixMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 5, 1);

    const [
      totalUsers,
      usersByRole,
      totalJobs,
      jobsByStatus,
      totalPayments,
      revenueResult,
      pendingVerification,
      recentJobs,
      monthlyRevenue,
    ] = await Promise.all([
      // Total users
      prisma.user.count(),
      // Users grouped by role
      prisma.user.groupBy({ by: ['role'], _count: { id: true } }),
      // Total jobs
      prisma.job.count(),
      // Jobs grouped by status
      prisma.job.groupBy({ by: ['status'], _count: { id: true } }),
      // Total payments count
      prisma.payment.count(),
      // Total revenue (sum of RELEASED payments)
      prisma.payment.aggregate({
        where: { status: 'RELEASED' },
        _sum: { amount: true },
      }),
      // Workers pending verification
      prisma.workerProfile.count({
        where: { verificationStatus: 'PENDING' },
      }),
      // Recent 5 jobs
      prisma.job.findMany({
        orderBy: { createdAt: 'desc' },
        take: 5,
        include: {
          category: true,
          customer: {
            include: { user: { select: { id: true, name: true, avatarUrl: true } } },
          },
          worker: {
            include: { user: { select: { id: true, name: true, avatarUrl: true } } },
          },
        },
      }),
      // Monthly revenue (last 6 months)
      prisma.$queryRaw<{ month: string; revenue: number }[]>`
        SELECT
          TO_CHAR(DATE_TRUNC('month', "createdAt"), 'YYYY-MM') AS month,
          COALESCE(SUM(amount), 0)::float AS revenue
        FROM "Payment"
        WHERE status = 'RELEASED'
          AND "createdAt" >= ${sixMonthsAgo}
        GROUP BY DATE_TRUNC('month', "createdAt")
        ORDER BY DATE_TRUNC('month', "createdAt") ASC
      `,
    ]);

    const roleBreakdown = Object.fromEntries(
      usersByRole.map((r) => [r.role, r._count.id])
    );

    const statusBreakdown = Object.fromEntries(
      jobsByStatus.map((s) => [s.status, s._count.id])
    );

    res.json({
      users: { total: totalUsers, byRole: roleBreakdown },
      jobs: { total: totalJobs, byStatus: statusBreakdown },
      payments: {
        total: totalPayments,
        revenue: revenueResult._sum.amount ?? 0,
      },
      pendingVerification,
      recentJobs,
      monthlyRevenue,
    });
  })
);

// ---------------------------------------------------------------------------
// GET /admin/users — List all users with pagination
// ---------------------------------------------------------------------------
const listUsersQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  role: z.enum(['CUSTOMER', 'WORKER', 'ADMIN']).optional(),
  search: z.string().optional(),
  status: z.enum(['active', 'inactive']).optional(),
});

router.get(
  '/users',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { page, limit, role, search, status } = listUsersQuerySchema.parse(req.query);

    const where: any = {};
    if (role) where.role = role;
    if (status) where.isActive = status === 'active';
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
      ];
    }

    const skip = (page - 1) * limit;

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        include: {
          customerProfile: true,
          workerProfile: true,
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.user.count({ where }),
    ]);

    res.json({ users, total, page, limit });
  })
);

// ---------------------------------------------------------------------------
// GET /admin/users/:id — Get single user details
// ---------------------------------------------------------------------------
router.get(
  '/users/:id',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const user = await prisma.user.findUnique({
      where: { id: req.params.id as string },
      include: {
        customerProfile: {
          include: {
            jobs: {
              orderBy: { createdAt: 'desc' },
              take: 10,
              include: { category: true, payment: true },
            },
            reviews: {
              orderBy: { createdAt: 'desc' },
              take: 10,
            },
          },
        },
        workerProfile: {
          include: {
            categories: { include: { category: true } },
            jobs: {
              orderBy: { createdAt: 'desc' },
              take: 10,
              include: { category: true, payment: true },
            },
            reviews: {
              orderBy: { createdAt: 'desc' },
              take: 10,
            },
          },
        },
      },
    });

    if (!user) throw AppError.notFound('User not found');

    res.json({ user });
  })
);

// ---------------------------------------------------------------------------
// PATCH /admin/users/:id/status — Toggle user active/inactive
// ---------------------------------------------------------------------------
const updateStatusSchema = z.object({
  isActive: z.boolean(),
});

router.patch(
  '/users/:id/status',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { isActive } = updateStatusSchema.parse(req.body);

    const user = await prisma.user.findUnique({
      where: { id: req.params.id as string },
    });
    if (!user) throw AppError.notFound('User not found');

    const updated = await prisma.user.update({
      where: { id: req.params.id as string },
      data: { isActive },
    });

    res.json({ user: updated });
  })
);

// ---------------------------------------------------------------------------
// DELETE /admin/users/:id — Delete user and all associated data
// ---------------------------------------------------------------------------
router.delete(
  '/users/:id',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const userId = req.params.id as string;
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { customerProfile: true, workerProfile: true },
    });
    if (!user) throw AppError.notFound('User not found');

    await prisma.$transaction(async (tx) => {
      await tx.message.deleteMany({ where: { senderId: userId } });
      await tx.notification.deleteMany({ where: { userId } });

      if (user.customerProfile) {
        const profileId = user.customerProfile.id;
        const jobs = await tx.job.findMany({ where: { customerId: profileId }, select: { id: true } });
        const jobIds = jobs.map((j) => j.id);
        if (jobIds.length > 0) {
          await tx.payment.deleteMany({ where: { jobId: { in: jobIds } } });
          await tx.review.deleteMany({ where: { jobId: { in: jobIds } } });
          await tx.message.deleteMany({ where: { jobId: { in: jobIds } } });
          await tx.jobApplication.deleteMany({ where: { jobId: { in: jobIds } } });
          await tx.job.deleteMany({ where: { id: { in: jobIds } } });
        }
        await tx.review.deleteMany({ where: { customerId: profileId } });
        await tx.customerProfile.delete({ where: { id: profileId } });
      }

      if (user.workerProfile) {
        const profileId = user.workerProfile.id;
        await tx.workerCategory.deleteMany({ where: { workerId: profileId } });
        await tx.jobApplication.deleteMany({ where: { workerId: profileId } });
        await tx.review.deleteMany({ where: { workerId: profileId } });
        await tx.portfolioItem.deleteMany({ where: { workerId: profileId } });
        await tx.job.updateMany({
          where: { workerId: profileId },
          data: { workerId: null, status: 'CANCELLED' },
        });
        await tx.workerProfile.delete({ where: { id: profileId } });
      }

      await tx.user.delete({ where: { id: userId } });
    });

    res.json({ message: 'User deleted' });
  })
);

// ---------------------------------------------------------------------------
// GET /admin/workers/pending — List workers pending verification
// ---------------------------------------------------------------------------
router.get(
  '/workers/pending',
  asyncHandler(async (_req: AuthRequest, res: Response) => {
    const workers = await prisma.workerProfile.findMany({
      where: { verificationStatus: 'PENDING' },
      include: {
        user: {
          select: { id: true, name: true, email: true, phone: true, avatarUrl: true, createdAt: true },
        },
        categories: { include: { category: true } },
        qualificationDocs: true,
      },
      orderBy: { user: { createdAt: 'asc' } },
    });

    res.json({ workers });
  })
);

// ---------------------------------------------------------------------------
// GET /admin/workers — List all workers with optional status filter
// ---------------------------------------------------------------------------
router.get(
  '/workers',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { status } = req.query;

    const where: any = {};
    if (status && typeof status === 'string') {
      where.verificationStatus = status;
    }

    const workers = await prisma.workerProfile.findMany({
      where,
      include: {
        user: {
          select: { id: true, name: true, email: true, phone: true, avatarUrl: true, createdAt: true },
        },
        categories: { include: { category: true } },
        qualificationDocs: true,
      },
      orderBy: { user: { createdAt: 'desc' } },
    });

    res.json({ workers });
  })
);

// ---------------------------------------------------------------------------
// GET /admin/jobs — List all jobs with filters
// ---------------------------------------------------------------------------
const listJobsQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  status: z
    .enum(['OPEN', 'APPLICATIONS_RECEIVED', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'REVIEWING', 'CLOSED', 'CANCELLED'])
    .optional(),
  categoryId: z.string().optional(),
  search: z.string().optional(),
});

router.get(
  '/jobs',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { page, limit, status, categoryId, search } = listJobsQuerySchema.parse(req.query);

    const where: any = {};
    if (status) where.status = status;
    if (categoryId) where.categoryId = categoryId;
    if (search) {
      where.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }

    const skip = (page - 1) * limit;

    const [jobs, total] = await Promise.all([
      prisma.job.findMany({
        where,
        include: {
          category: true,
          customer: {
            include: { user: { select: { id: true, name: true, avatarUrl: true } } },
          },
          worker: {
            include: { user: { select: { id: true, name: true, avatarUrl: true } } },
          },
          payment: true,
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.job.count({ where }),
    ]);

    res.json({ jobs, total, page, limit });
  })
);

// ---------------------------------------------------------------------------
// GET /admin/payments — List all payments
// ---------------------------------------------------------------------------
const listPaymentsQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  status: z.enum(['PENDING', 'HELD', 'RELEASED', 'DISPUTED', 'REFUNDED']).optional(),
});

router.get(
  '/payments',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { page, limit, status } = listPaymentsQuerySchema.parse(req.query);

    const where: any = {};
    if (status) where.status = status;

    const skip = (page - 1) * limit;

    const [payments, total, revenueResult] = await Promise.all([
      prisma.payment.findMany({
        where,
        include: {
          job: {
            select: {
              id: true,
              title: true,
              status: true,
              customer: {
                include: { user: { select: { id: true, name: true } } },
              },
              worker: {
                include: { user: { select: { id: true, name: true } } },
              },
            },
          },
          dispute: true,
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.payment.count({ where }),
      prisma.payment.aggregate({
        where: { status: 'RELEASED' },
        _sum: { amount: true },
      }),
    ]);

    res.json({
      payments,
      total,
      page,
      limit,
      totalRevenue: revenueResult._sum.amount ?? 0,
    });
  })
);

// ---------------------------------------------------------------------------
// PATCH /admin/jobs/:id/close — Admin closes a REVIEWING or COMPLETED job
// ---------------------------------------------------------------------------
router.patch(
  '/jobs/:id/close',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const job = await prisma.job.findUnique({
      where: { id: req.params.id as string },
      include: {
        customer: { include: { user: { select: { id: true, name: true } } } },
        worker: { include: { user: { select: { id: true, name: true } } } },
      },
    });
    if (!job) throw AppError.notFound('Job not found');
    if (job.status !== 'REVIEWING' && job.status !== 'COMPLETED') {
      throw AppError.badRequest('Job must be in REVIEWING or COMPLETED status to close');
    }

    const updated = await prisma.job.update({
      where: { id: req.params.id as string },
      data: { status: 'CLOSED' },
      include: {
        category: true,
        customer: { include: { user: { select: { id: true, name: true } } } },
        worker: { include: { user: { select: { id: true, name: true } } } },
        payment: true,
      },
    });

    // Notify both parties
    const { createNotification } = await import('./notifications');
    await createNotification(
      job.customer.userId,
      'Job Closed',
      `Your job "${job.title}" has been closed by an administrator.`
    );
    if (job.worker) {
      await createNotification(
        job.worker.userId,
        'Job Closed',
        `The job "${job.title}" has been closed by an administrator.`
      );
    }

    res.json({ job: updated });
  })
);

// ---------------------------------------------------------------------------
// PATCH /admin/disputes/:id/resolve — Resolve a dispute with compensation
// Accepts either a job ID (cancelled job) or payment ID (escrow dispute)
// ---------------------------------------------------------------------------
const resolveDisputeSchema = z.object({
  resolution: z.enum(['refund_customer', 'pay_worker', 'no_compensation']),
  notes: z.string().optional(),
});

router.patch(
  '/disputes/:id/resolve',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { resolution, notes } = resolveDisputeSchema.parse(req.body);
    const id = req.params.id as string;

    // Try to find as a payment dispute first (new escrow flow)
    const disputeRecord = await prisma.dispute.findFirst({
      where: { payment: { jobId: id } },
      include: {
        payment: {
          include: {
            job: {
              include: {
                customer: { include: { user: { select: { id: true, name: true } } } },
                worker: { include: { user: { select: { id: true, name: true } } } },
              },
            },
          },
        },
      },
    });

    // Fall back to job-level dispute (cancelled job with worker)
    const job = disputeRecord?.payment.job ?? await prisma.job.findUnique({
      where: { id },
      include: {
        customer: { include: { user: { select: { id: true, name: true } } } },
        worker: { include: { user: { select: { id: true, name: true } } } },
        payment: { include: { dispute: true } },
      },
    });
    if (!job) throw AppError.notFound('Job not found');

    const payment = disputeRecord?.payment ?? (job as any).payment;

    // Update payment status based on resolution
    if (payment) {
      let newStatus: string = payment.status;
      const timestamps: any = {};
      if (resolution === 'refund_customer') {
        newStatus = 'REFUNDED';
        timestamps.refundedAt = new Date();
      } else if (resolution === 'pay_worker') {
        newStatus = 'RELEASED';
        timestamps.releasedAt = new Date();
      }

      if (newStatus !== payment.status) {
        await prisma.payment.update({
          where: { id: payment.id },
          data: { status: newStatus as any, ...timestamps },
        });
      }
    }

    // Mark dispute record as resolved
    if (disputeRecord) {
      await prisma.dispute.update({
        where: { id: disputeRecord.id },
        data: {
          resolution: `${resolution}${notes ? ': ' + notes : ''}`,
          resolvedBy: req.user!.userId,
          resolvedAt: new Date(),
        },
      });
    }

    // Close the job if payment dispute is resolved
    if (job.status !== 'CANCELLED' && job.status !== 'CLOSED') {
      await prisma.job.update({
        where: { id: job.id },
        data: { status: 'CLOSED' },
      });
    }

    // Notify both parties
    const { createNotification } = await import('./notifications');
    const resolutionText =
      resolution === 'refund_customer'
        ? 'A refund will be issued to the customer.'
        : resolution === 'pay_worker'
        ? 'The worker will be compensated for their work.'
        : 'No compensation will be issued.';

    await createNotification(
      job.customer.userId,
      'Dispute Resolved',
      `The dispute for "${job.title}" has been resolved. ${resolutionText}`
    );
    if (job.worker) {
      await createNotification(
        job.worker.userId,
        'Dispute Resolved',
        `The dispute for "${job.title}" has been resolved. ${resolutionText}`
      );
    }

    res.json({
      message: 'Dispute resolved',
      resolution,
      notes,
    });
  })
);

// ---------------------------------------------------------------------------
// GET /admin/disputes — List disputed/cancelled jobs + escrow disputes
// ---------------------------------------------------------------------------
router.get(
  '/disputes',
  asyncHandler(async (_req: AuthRequest, res: Response) => {
    // Get cancelled jobs with assigned workers
    const cancelledJobs = await prisma.job.findMany({
      where: {
        status: 'CANCELLED',
        workerId: { not: null },
      },
      include: {
        category: true,
        customer: {
          include: { user: { select: { id: true, name: true, email: true, avatarUrl: true } } },
        },
        worker: {
          include: { user: { select: { id: true, name: true, email: true, avatarUrl: true } } },
        },
        review: true,
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 5,
          include: {
            sender: { select: { id: true, name: true } },
          },
        },
        payment: { include: { dispute: true } },
      },
      orderBy: { updatedAt: 'desc' },
    });

    // Get jobs with disputed payments (escrow disputes)
    const disputedPaymentJobs = await prisma.job.findMany({
      where: {
        payment: { status: 'DISPUTED' },
        status: { not: 'CANCELLED' },
      },
      include: {
        category: true,
        customer: {
          include: { user: { select: { id: true, name: true, email: true, avatarUrl: true } } },
        },
        worker: {
          include: { user: { select: { id: true, name: true, email: true, avatarUrl: true } } },
        },
        review: true,
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 5,
          include: {
            sender: { select: { id: true, name: true } },
          },
        },
        payment: { include: { dispute: true } },
      },
      orderBy: { updatedAt: 'desc' },
    });

    // Merge and deduplicate by job ID
    const seen = new Set<string>();
    const disputes = [...disputedPaymentJobs, ...cancelledJobs].filter(j => {
      if (seen.has(j.id)) return false;
      seen.add(j.id);
      return true;
    });

    res.json({ disputes });
  })
);

// ---------------------------------------------------------------------------
// MATCHING DEMO ENDPOINTS
// ---------------------------------------------------------------------------

// GET /admin/matching/workers — get all workers with locations for map display
router.get(
  '/matching/workers',
  asyncHandler(async (_req: AuthRequest, res: Response) => {
    const workers = await prisma.workerProfile.findMany({
      where: { latitude: { not: null }, longitude: { not: null } },
      include: {
        user: { select: { id: true, name: true, email: true } },
        categories: { include: { category: true } },
      },
    });

    // Check Redis presence for each worker
    const redisClient = (await import('../config/redis')).default;
    const workersWithPresence = await Promise.all(
      workers.map(async (w) => {
        const status = await redisClient.get(`worker:status:${w.id}`);
        const locationRaw = await redisClient.get(`worker:location:${w.id}`);
        const liveLocation = locationRaw ? JSON.parse(locationRaw) : null;
        return {
          ...w,
          presence: status || 'offline',
          liveLocation,
        };
      })
    );

    res.json({ workers: workersWithPresence });
  })
);

// POST /admin/matching/simulate — seed Redis presence for all workers with locations
router.post(
  '/matching/simulate',
  asyncHandler(async (_req: AuthRequest, res: Response) => {
    const workers = await prisma.workerProfile.findMany({
      where: {
        latitude: { not: null },
        longitude: { not: null },
        isAvailable: true,
      },
      select: { id: true, latitude: true, longitude: true },
    });

    const redisClient = (await import('../config/redis')).default;
    const TTL = 35 * 60; // 35 minutes

    for (const w of workers) {
      await redisClient.set(`worker:status:${w.id}`, 'online', { EX: TTL });
      await redisClient.set(
        `worker:location:${w.id}`,
        JSON.stringify({ lat: w.latitude, lng: w.longitude }),
        { EX: TTL }
      );
    }

    res.json({ message: `Simulated presence for ${workers.length} workers`, count: workers.length });
  })
);

// POST /admin/matching/run/:jobId — simulate presence + trigger matching
router.post(
  '/matching/run/:jobId',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const jobId = req.params.id || req.params.jobId;

    const job = await prisma.job.findUnique({
      where: { id: jobId as string },
      include: { category: true },
    });
    if (!job) throw AppError.notFound('Job not found');

    // Simulate presence first
    const workers = await prisma.workerProfile.findMany({
      where: {
        latitude: { not: null },
        longitude: { not: null },
        isAvailable: true,
      },
      select: { id: true, latitude: true, longitude: true },
    });

    const redisClient = (await import('../config/redis')).default;
    const TTL = 35 * 60;
    for (const w of workers) {
      await redisClient.set(`worker:status:${w.id}`, 'online', { EX: TTL });
      await redisClient.set(
        `worker:location:${w.id}`,
        JSON.stringify({ lat: w.latitude, lng: w.longitude }),
        { EX: TTL }
      );
    }

    // Run matching
    const { matchWorkersForJob } = await import('../services/matching.service');
    const result = await matchWorkersForJob(jobId as string);

    // Fetch full match details
    const matches = await prisma.jobMatch.findMany({
      where: { jobId: jobId as string },
      include: {
        worker: {
          include: {
            user: { select: { id: true, name: true } },
            categories: { include: { category: true } },
          },
        },
      },
      orderBy: { matchScore: 'desc' },
    });

    res.json({ job, matches, simulatedWorkers: workers.length });
  })
);

// GET /admin/matching/jobs — get jobs with locations for demo picker
router.get(
  '/matching/jobs',
  asyncHandler(async (_req: AuthRequest, res: Response) => {
    const jobs = await prisma.job.findMany({
      where: {
        latitude: { not: null },
        longitude: { not: null },
        status: { in: ['OPEN', 'APPLICATIONS_RECEIVED'] },
      },
      include: {
        category: true,
        customer: { include: { user: { select: { name: true } } } },
      },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });
    res.json({ jobs });
  })
);

export default router;
