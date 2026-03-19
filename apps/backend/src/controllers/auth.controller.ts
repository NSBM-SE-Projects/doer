import { Request, Response } from 'express';
import admin from '../config/firebase';
import { AuthRequest } from '../middleware/auth';
import * as authService from '../services/auth.service';
import { success, error } from '../utils/response';
import { Role } from '@prisma/client';

export const register = async (req: Request, res: Response) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return error(res, 'Firebase token required', 401);
  }

  const idToken = authHeader.split(' ')[1];
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    const { email, name, role } = req.body;

    if (!role || !['CUSTOMER', 'WORKER'].includes(role)) {
      return error(res, 'Valid role required (CUSTOMER or WORKER)');
    }

    const { user, created } = await authService.registerUser(
      decoded.uid,
      email || decoded.email || '',
      name || decoded.name || '',
      role as Role,
      req.body.phone,
      decoded.picture
    );

    const token = authService.generateJWT(decoded.uid, user.role, user.id);
    return success(res, { user, token }, created ? 201 : 200);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Registration failed';
    return error(res, message, 401);
  }
};

export const login = async (req: Request, res: Response) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return error(res, 'Firebase token required', 401);
  }

  const idToken = authHeader.split(' ')[1];
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    const user = await authService.loginUser(decoded.uid);

    if (!user) {
      return error(res, 'User not found. Please register first.', 404);
    }

    const token = authService.generateJWT(decoded.uid, user.role, user.id);
    return success(res, { user, token });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Login failed';
    return error(res, message, 401);
  }
};

export const getMe = async (req: AuthRequest, res: Response) => {
  try {
    const user = await authService.getMe(req.user!.dbUserId);
    if (!user) return error(res, 'User not found', 404);
    return success(res, user);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to get user';
    return error(res, message, 500);
  }
};

export const updateMe = async (req: AuthRequest, res: Response) => {
  try {
    const { name, phone, avatarUrl } = req.body;
    const user = await authService.updateMe(req.user!.dbUserId, { name, phone, avatarUrl });
    return success(res, user);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to update user';
    return error(res, message, 500);
  }
};
