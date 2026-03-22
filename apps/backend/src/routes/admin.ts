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
      // Total revenue (sum of COMPLETED payments)
      prisma.payment.aggregate({
        where: { status: 'COMPLETED' },
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
        WHERE status = 'COMPLETED'
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
// DELETE /admin/users/:id — Soft delete user (set isActive: false)
// ---------------------------------------------------------------------------
router.delete(
  '/users/:id',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const user = await prisma.user.findUnique({
      where: { id: req.params.id as string },
    });
    if (!user) throw AppError.notFound('User not found');

    const updated = await prisma.user.update({
      where: { id: req.params.id as string },
      data: { isActive: false },
    });

    res.json({ message: 'User deactivated', user: updated });
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
  status: z.enum(['PENDING', 'COMPLETED', 'FAILED', 'REFUNDED']).optional(),
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
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.payment.count({ where }),
      prisma.payment.aggregate({
        where: { status: 'COMPLETED' },
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
// GET /admin/disputes — List disputed/cancelled jobs
// ---------------------------------------------------------------------------
router.get(
  '/disputes',
  asyncHandler(async (_req: AuthRequest, res: Response) => {
    const disputes = await prisma.job.findMany({
      where: {
        status: 'CANCELLED',
        OR: [
          { review: { isNot: null } },
          { messages: { some: {} } },
        ],
      },
      include: {
        category: true,
        customer: {
          include: { user: { select: { id: true, name: true, avatarUrl: true } } },
        },
        worker: {
          include: { user: { select: { id: true, name: true, avatarUrl: true } } },
        },
        review: true,
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 5,
          include: {
            sender: { select: { id: true, name: true } },
          },
        },
        payment: true,
      },
      orderBy: { updatedAt: 'desc' },
    });

    res.json({ disputes });
  })
);

export default router;
