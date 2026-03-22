import { Router, Response } from 'express';
import { z } from 'zod';
import prisma from '../config/prisma';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';
import { recalculateAndNotifyBadge } from '../utils/badgeCalculator';
import { createNotification } from './notifications';
import { upload } from '../middleware/upload';
import { uploadToCloudinary } from '../config/cloudinary';

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

// POST /api/users/me/worker/documents — upload verification documents
router.post(
  '/me/worker/documents',
  authenticate,
  authorize('WORKER'),
  upload.fields([
    { name: 'nicFront', maxCount: 1 },
    { name: 'nicBack', maxCount: 1 },
    { name: 'backgroundCheck', maxCount: 1 },
    { name: 'qualifications', maxCount: 10 },
  ]),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const workerProfile = await prisma.workerProfile.findUnique({
      where: { userId: req.user!.userId },
    });
    if (!workerProfile) throw AppError.notFound('Worker profile not found');

    const files = req.files as Record<string, Express.Multer.File[]>;
    const updateData: any = {};

    if (files.nicFront?.[0]) {
      updateData.nicFrontUrl = await uploadToCloudinary(files.nicFront[0].buffer, 'verification/nic');
    }
    if (files.nicBack?.[0]) {
      updateData.nicBackUrl = await uploadToCloudinary(files.nicBack[0].buffer, 'verification/nic');
    }
    if (files.backgroundCheck?.[0]) {
      updateData.backgroundCheckUrl = await uploadToCloudinary(files.backgroundCheck[0].buffer, 'verification/background');
    }

    if (files.qualifications?.length) {
      for (const file of files.qualifications) {
        const url = await uploadToCloudinary(file.buffer, 'verification/qualifications');
        await prisma.qualificationDoc.create({
          data: {
            title: file.originalname,
            url,
            workerId: workerProfile.id,
          },
        });
      }
    }

    // Set status to PENDING for admin review
    updateData.verificationStatus = 'PENDING';
    updateData.rejectionReason = null;

    const profile = await prisma.workerProfile.update({
      where: { id: workerProfile.id },
      data: updateData,
      include: { qualificationDocs: true },
    });

    res.json({ profile });
  })
);

// GET /api/users/me/worker/verification — get worker's verification status and documents
router.get(
  '/me/worker/verification',
  authenticate,
  authorize('WORKER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const worker = await prisma.workerProfile.findUnique({
      where: { userId: req.user!.userId },
      include: {
        qualificationDocs: true,
      },
    });
    if (!worker) throw AppError.notFound('Worker profile not found');

    const BADGE_ORDER = ['TRAINEE', 'BRONZE', 'SILVER', 'GOLD', 'PLATINUM'] as const;
    const currentIndex = BADGE_ORDER.indexOf(worker.badgeLevel);
    const nextBadge = currentIndex < BADGE_ORDER.length - 1 ? BADGE_ORDER[currentIndex + 1] : null;

    const nextBadgeInfo: Record<string, string> = {
      BRONZE: 'Get your NIC verified',
      SILVER: 'Get NIC + qualifications verified',
      GOLD: 'Full verification + 10 jobs + 4.0 rating',
      PLATINUM: 'Full verification + background check + 50 jobs + 4.5 rating',
    };

    res.json({
      verificationStatus: worker.verificationStatus,
      badgeLevel: worker.badgeLevel,
      rejectionReason: worker.rejectionReason,
      nicNumber: worker.nicNumber,
      nicFrontUrl: worker.nicFrontUrl,
      nicBackUrl: worker.nicBackUrl,
      nicVerified: worker.nicVerified,
      qualificationsVerified: worker.qualificationsVerified,
      backgroundCheckUrl: worker.backgroundCheckUrl,
      backgroundCheckVerified: worker.backgroundCheckVerified,
      qualificationDocs: worker.qualificationDocs,
      nextBadge,
      nextBadgeHint: nextBadge ? nextBadgeInfo[nextBadge] : 'You have reached the highest level!',
    });
  })
);

// PATCH /api/users/:id/verify — admin verify individual document types or overall status
router.patch(
  '/:id/verify',
  authenticate,
  authorize('ADMIN'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const body = z.object({
      // Overall status (legacy support)
      status: z.enum(['VERIFIED', 'REJECTED', 'PENDING']).optional(),
      rejectionReason: z.string().optional(),
      // Granular verification flags
      nicVerified: z.boolean().optional(),
      qualificationsVerified: z.boolean().optional(),
      backgroundCheckVerified: z.boolean().optional(),
    }).parse(req.body);

    const updateData: any = {};

    // Granular flags
    if (body.nicVerified !== undefined) updateData.nicVerified = body.nicVerified;
    if (body.qualificationsVerified !== undefined) updateData.qualificationsVerified = body.qualificationsVerified;
    if (body.backgroundCheckVerified !== undefined) updateData.backgroundCheckVerified = body.backgroundCheckVerified;

    // Overall status
    if (body.status) {
      updateData.verificationStatus = body.status;
      updateData.rejectionReason = body.status === 'REJECTED' ? (body.rejectionReason || null) : null;
      // Reset all flags when setting to PENDING or REJECTED
      if (body.status === 'PENDING' || body.status === 'REJECTED') {
        updateData.nicVerified = false;
        updateData.qualificationsVerified = false;
        updateData.backgroundCheckVerified = false;
      }
    }

    // Auto-set overall status to VERIFIED if any doc is verified
    if (body.nicVerified === true || body.qualificationsVerified === true || body.backgroundCheckVerified === true) {
      updateData.verificationStatus = 'VERIFIED';
      updateData.rejectionReason = null;
    }

    // Auto-downgrade overall status if any doc is revoked
    if (body.nicVerified === false || body.qualificationsVerified === false || body.backgroundCheckVerified === false) {
      updateData.verificationStatus = 'PENDING';
      updateData.rejectionReason = null;
    }

    const profile = await prisma.workerProfile.update({
      where: { userId: req.params.id as string },
      data: updateData,
      include: {
        user: { select: { id: true, name: true, email: true } },
      },
    });

    // Recalculate badge based on new verification state
    await recalculateAndNotifyBadge(profile.id);

    // Notify worker
    if (body.status === 'REJECTED') {
      await createNotification(
        profile.userId,
        'Verification Rejected',
        body.rejectionReason ? `Reason: ${body.rejectionReason}` : 'Please re-submit your documents.'
      );
    } else if (body.nicVerified || body.qualificationsVerified || body.backgroundCheckVerified) {
      const verified = [];
      if (body.nicVerified) verified.push('NIC');
      if (body.qualificationsVerified) verified.push('Qualifications');
      if (body.backgroundCheckVerified) verified.push('Background Check');
      await createNotification(
        profile.userId,
        'Document Verified',
        `Your ${verified.join(', ')} ${verified.length > 1 ? 'have' : 'has'} been verified!`
      );
    }

    res.json({ profile });
  })
);

export default router;
