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
