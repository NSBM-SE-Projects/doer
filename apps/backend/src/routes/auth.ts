import { Router, Response } from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import type { StringValue } from 'ms';
import { z } from 'zod';
import prisma from '../config/prisma';
import { env } from '../config/env';
import { authenticate, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';

const router = Router();

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  name: z.string().min(1),
  phone: z.string().optional(),
  role: z.enum(['CUSTOMER', 'WORKER']),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

function signJwt(userId: string, role: string): string {
  return jwt.sign({ userId, role }, env.JWT_SECRET, {
    expiresIn: env.JWT_EXPIRES_IN as StringValue,
  });
}

// POST /api/auth/register
router.post(
  '/register',
  asyncHandler(async (req, res) => {
    const body = registerSchema.parse(req.body);

    // Check if user already exists
    const existing = await prisma.user.findUnique({
      where: { email: body.email },
    });
    if (existing) throw AppError.conflict('User already exists');

    // Hash password
    const passwordHash = await bcrypt.hash(body.password, 12);

    // Create user with profile
    const user = await prisma.user.create({
      data: {
        firebaseUid: `local_${Date.now()}_${Math.random().toString(36).slice(2)}`,
        email: body.email,
        passwordHash,
        name: body.name,
        phone: body.phone,
        role: body.role,
        ...(body.role === 'CUSTOMER'
          ? { customerProfile: { create: {} } }
          : { workerProfile: { create: {} } }),
      },
      include: {
        customerProfile: true,
        workerProfile: true,
      },
    });

    const token = signJwt(user.id, user.role);

    res.status(201).json({ token, user });
  })
);

// POST /api/auth/login
router.post(
  '/login',
  asyncHandler(async (req, res) => {
    const body = loginSchema.parse(req.body);

    const user = await prisma.user.findUnique({
      where: { email: body.email },
      include: {
        customerProfile: true,
        workerProfile: true,
      },
    });

    if (!user) throw AppError.notFound('No account found with this email.');
    if (!user.isActive) throw AppError.forbidden('Account is deactivated');

    // If user has a password hash, verify it
    if (user.passwordHash) {
      const valid = await bcrypt.compare(body.password, user.passwordHash);
      if (!valid) throw AppError.unauthorized('Incorrect password.');
    } else {
      // Legacy user without password — set password on first login
      const passwordHash = await bcrypt.hash(body.password, 12);
      await prisma.user.update({
        where: { id: user.id },
        data: { passwordHash },
      });
    }

    const token = signJwt(user.id, user.role);

    res.json({ token, user });
  })
);

// POST /api/auth/google — sign in or register with Google
router.post(
  '/google',
  asyncHandler(async (req, res) => {
    const { email, name, googleId, role } = req.body;
    if (!email || !googleId) throw AppError.badRequest('email and googleId are required');

    let user = await prisma.user.findUnique({
      where: { email },
      include: { customerProfile: true, workerProfile: true },
    });

    if (user) {
      // Existing user — just log them in
      if (!user.isActive) throw AppError.forbidden('Account is deactivated');
    } else {
      // New user — create account
      const userRole = role === 'WORKER' ? 'WORKER' : 'CUSTOMER';
      user = await prisma.user.create({
        data: {
          firebaseUid: `google_${googleId}`,
          email,
          name: name || email.split('@')[0],
          role: userRole as any,
          ...(userRole === 'CUSTOMER'
            ? { customerProfile: { create: {} } }
            : { workerProfile: { create: {} } }),
        },
        include: { customerProfile: true, workerProfile: true },
      });
    }

    const token = signJwt(user.id, user.role);
    res.json({ token, user });
  })
);

// PUT /api/auth/change-password
router.put(
  '/change-password',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const schema = z.object({
      currentPassword: z.string().min(1),
      newPassword: z.string().min(6),
    });
    const { currentPassword, newPassword } = schema.parse(req.body);

    const user = await prisma.user.findUnique({
      where: { id: req.user!.userId },
    });
    if (!user) throw AppError.notFound('User not found');

    if (user.passwordHash) {
      const valid = await bcrypt.compare(currentPassword, user.passwordHash);
      if (!valid) throw AppError.unauthorized('Current password is incorrect');
    }

    const passwordHash = await bcrypt.hash(newPassword, 12);
    await prisma.user.update({
      where: { id: req.user!.userId },
      data: { passwordHash },
    });

    res.json({ message: 'Password updated successfully' });
  })
);

// GET /api/auth/me — get current user from JWT
router.get(
  '/me',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.userId },
      include: {
        customerProfile: true,
        workerProfile: true,
      },
    });

    if (!user) throw AppError.notFound('User not found');

    res.json({ user });
  })
);

// DELETE /api/auth/account — delete current user and all associated data
router.delete(
  '/account',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const userId = req.user!.userId;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { customerProfile: true, workerProfile: true },
    });
    if (!user) throw AppError.notFound('User not found');

    await prisma.$transaction(async (tx) => {
      // Delete messages sent by this user
      await tx.message.deleteMany({ where: { senderId: userId } });

      // Delete notifications
      await tx.notification.deleteMany({ where: { userId } });

      if (user.customerProfile) {
        const profileId = user.customerProfile.id;

        // Get all jobs owned by this customer
        const jobs = await tx.job.findMany({ where: { customerId: profileId }, select: { id: true } });
        const jobIds = jobs.map((j) => j.id);

        if (jobIds.length > 0) {
          // Delete dependent records on customer's jobs
          await tx.payment.deleteMany({ where: { jobId: { in: jobIds } } });
          await tx.review.deleteMany({ where: { jobId: { in: jobIds } } });
          await tx.message.deleteMany({ where: { jobId: { in: jobIds } } });
          await tx.jobApplication.deleteMany({ where: { jobId: { in: jobIds } } });
          await tx.job.deleteMany({ where: { id: { in: jobIds } } });
        }

        // Delete reviews written by this customer
        await tx.review.deleteMany({ where: { customerId: profileId } });

        await tx.customerProfile.delete({ where: { id: profileId } });
      }

      if (user.workerProfile) {
        const profileId = user.workerProfile.id;

        // Delete worker categories
        await tx.workerCategory.deleteMany({ where: { workerId: profileId } });

        // Delete applications by this worker
        await tx.jobApplication.deleteMany({ where: { workerId: profileId } });

        // Delete reviews received by this worker
        await tx.review.deleteMany({ where: { workerId: profileId } });

        // Unassign jobs assigned to this worker (don't delete customer's jobs)
        await tx.job.updateMany({
          where: { workerId: profileId },
          data: { workerId: null, status: 'CANCELLED' },
        });

        await tx.workerProfile.delete({ where: { id: profileId } });
      }

      await tx.user.delete({ where: { id: userId } });
    });

    res.json({ message: 'Account deleted' });
  })
);

// POST /api/auth/reset-password — reset password (dev: returns temp password)
router.post(
  '/reset-password',
  asyncHandler(async (req, res) => {
    const { email } = z.object({ email: z.string().email() }).parse(req.body);

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) throw AppError.notFound('No account found with this email');

    const tempPassword = Math.random().toString(36).slice(2) + Math.random().toString(36).slice(2);
    const passwordHash = await bcrypt.hash(tempPassword, 12);

    await prisma.user.update({
      where: { id: user.id },
      data: { passwordHash },
    });

    res.json({
      message: 'Password has been reset. Check your email.',
      tempPassword,
    });
  })
);

export default router;
