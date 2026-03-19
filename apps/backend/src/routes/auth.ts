import { Router, Response } from 'express';
import jwt from 'jsonwebtoken';
import type { StringValue } from 'ms';
import { z } from 'zod';
import prisma from '../config/prisma';
import { env } from '../config/env';
import { verifyFirebaseToken } from '../config/firebase';
import { authenticate, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';

const router = Router();

const registerSchema = z.object({
  firebaseToken: z.string(),
  firebaseUid: z.string().optional(),
  email: z.string().email(),
  name: z.string().min(1),
  phone: z.string().optional(),
  role: z.enum(['CUSTOMER', 'WORKER']),
});

const loginSchema = z.object({
  firebaseToken: z.string(),
  firebaseUid: z.string().optional(),
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

    // Verify Firebase token — falls back to dev UID in non-production
    const decoded = await verifyFirebaseToken(body.firebaseToken);
    const firebaseUid = decoded?.uid || body.firebaseUid || body.firebaseToken;

    // Check if user already exists
    const existing = await prisma.user.findFirst({
      where: {
        OR: [{ firebaseUid }, { email: body.email }],
      },
    });
    if (existing) throw AppError.conflict('User already exists');

    // Create user with profile
    const user = await prisma.user.create({
      data: {
        firebaseUid,
        email: body.email,
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

    // Verify Firebase token — falls back to dev UID in non-production
    const decoded = await verifyFirebaseToken(body.firebaseToken);
    const firebaseUid = decoded?.uid || body.firebaseUid || body.firebaseToken;

    const user = await prisma.user.findUnique({
      where: { firebaseUid },
      include: {
        customerProfile: true,
        workerProfile: true,
      },
    });

    if (!user) throw AppError.notFound('User not found. Please register first.');
    if (!user.isActive) throw AppError.forbidden('Account is deactivated');

    const token = signJwt(user.id, user.role);

    res.json({ token, user });
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

export default router;
