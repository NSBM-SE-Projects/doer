import { Router, Response } from 'express';
import { z } from 'zod';
import prisma from '../config/prisma';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';

const router = Router();

const updateProfileSchema = z.object({
  name: z.string().min(1).optional(),
  phone: z.string().optional(),
  avatarUrl: z.string().url().optional(),
});

const updateCustomerProfileSchema = z.object({
  address: z.string().optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
});

const updateWorkerProfileSchema = z.object({
  bio: z.string().optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  nicNumber: z.string().optional(),
  isAvailable: z.boolean().optional(),
  categoryIds: z.array(z.string()).optional(),
});

// GET /api/users/me — get own profile (authenticated)
router.get(
  '/me',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.userId },
      include: {
        customerProfile: true,
        workerProfile: {
          include: {
            categories: {
              include: { category: true },
            },
            reviews: {
              include: {
                customer: {
                  include: { user: { select: { name: true, avatarUrl: true } } },
                },
                job: { select: { title: true } },
              },
              orderBy: { createdAt: 'desc' },
              take: 20,
            },
            portfolio: {
              include: { category: true },
              orderBy: { createdAt: 'desc' },
              take: 20,
            },
          },
        },
      },
    });

    if (!user) throw AppError.notFound('User not found');

    res.json({ user });
  })
);

// PUT /api/users/me — update own base profile
router.put(
  '/me',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const body = updateProfileSchema.parse(req.body);

    const user = await prisma.user.update({
      where: { id: req.user!.userId },
      data: body,
      include: {
        customerProfile: true,
        workerProfile: true,
      },
    });

    res.json({ user });
  })
);

// PUT /api/users/me/customer — update customer-specific profile
router.put(
  '/me/customer',
  authenticate,
  authorize('CUSTOMER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const body = updateCustomerProfileSchema.parse(req.body);

    const profile = await prisma.customerProfile.update({
      where: { userId: req.user!.userId },
      data: body,
    });

    res.json({ profile });
  })
);

// PUT /api/users/me/worker — update worker-specific profile
router.put(
  '/me/worker',
  authenticate,
  authorize('WORKER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { categoryIds, ...profileData } = updateWorkerProfileSchema.parse(req.body);

    const workerProfile = await prisma.workerProfile.findUnique({
      where: { userId: req.user!.userId },
    });
    if (!workerProfile) throw AppError.notFound('Worker profile not found');

    // Update categories if provided
    if (categoryIds) {
      await prisma.workerCategory.deleteMany({
        where: { workerId: workerProfile.id },
      });
      await prisma.workerCategory.createMany({
        data: categoryIds.map((categoryId) => ({
          workerId: workerProfile.id,
          categoryId,
        })),
      });
    }

    const profile = await prisma.workerProfile.update({
      where: { userId: req.user!.userId },
      data: profileData,
      include: {
        categories: { include: { category: true } },
        user: { select: { id: true, name: true, email: true, avatarUrl: true } },
      },
    });

    res.json({ profile });
  })
);

// GET /api/users/workers — list workers (public, with filters)
router.get(
  '/workers',
  asyncHandler(async (req, res) => {
    const { categoryId, available, lat, lng, radius } = req.query;

    const where: any = {};

    if (available === 'true') where.isAvailable = true;
    if (categoryId) {
      where.categories = { some: { categoryId: categoryId as string } };
    }

    const workers = await prisma.workerProfile.findMany({
      where,
      include: {
        user: { select: { id: true, name: true, avatarUrl: true, phone: true } },
        categories: { include: { category: true } },
      },
      orderBy: { rating: 'desc' },
    });

    res.json({ workers });
  })
);

// GET /api/users/workers/:id — get single worker profile
router.get(
  '/workers/:id',
  asyncHandler(async (req, res) => {
    const worker = await prisma.workerProfile.findUnique({
      where: { id: req.params.id as string },
      include: {
        user: { select: { id: true, name: true, avatarUrl: true, phone: true } },
        categories: { include: { category: true } },
        reviews: {
          include: {
            customer: {
              include: {
                user: { select: { name: true, avatarUrl: true } },
              },
            },
            job: { select: { title: true } },
          },
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
        portfolio: {
          include: { category: true },
          orderBy: { createdAt: 'desc' },
          take: 20,
        },
      },
    });

    if (!worker) throw AppError.notFound('Worker not found');

    res.json({ worker });
  })
);

// PATCH /api/users/:id/verify — admin verify/reject worker
router.patch(
  '/:id/verify',
  authenticate,
  authorize('ADMIN'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { status } = z.object({
      status: z.enum(['VERIFIED', 'REJECTED']),
    }).parse(req.body);

    const profile = await prisma.workerProfile.update({
      where: { userId: req.params.id as string },
      data: { verificationStatus: status },
      include: {
        user: { select: { id: true, name: true, email: true } },
      },
    });

    res.json({ profile });
  })
);

export default router;
