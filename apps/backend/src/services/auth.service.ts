import { Role } from '@prisma/client';
import jwt from 'jsonwebtoken';
import prisma from '../utils/prisma';

export const registerUser = async (
  firebaseUid: string,
  email: string,
  name: string,
  role: Role,
  phone?: string,
  avatarUrl?: string
) => {
  const existing = await prisma.user.findUnique({ where: { firebaseUid } });
  if (existing) {
    return { user: existing, created: false };
  }

  const user = await prisma.user.create({
    data: {
      firebaseUid,
      email,
      name,
      phone,
      avatarUrl,
      role,
      ...(role === 'CUSTOMER'
        ? { customerProfile: { create: {} } }
        : { workerProfile: { create: {} } }),
    },
    include: { customerProfile: true, workerProfile: true },
  });

  return { user, created: true };
};

export const loginUser = async (firebaseUid: string) => {
  const user = await prisma.user.findUnique({
    where: { firebaseUid },
    include: { customerProfile: true, workerProfile: true },
  });
  return user;
};

export const generateJWT = (uid: string, role: string, dbUserId: string) => {
  return jwt.sign(
    { uid, role, dbUserId },
    process.env.JWT_SECRET as string,
    { expiresIn: '30d' }
  );
};

export const getMe = async (dbUserId: string) => {
  return prisma.user.findUnique({
    where: { id: dbUserId },
    include: { customerProfile: true, workerProfile: true },
  });
};

export const updateMe = async (
  dbUserId: string,
  data: { name?: string; phone?: string; avatarUrl?: string }
) => {
  return prisma.user.update({
    where: { id: dbUserId },
    data,
    include: { customerProfile: true, workerProfile: true },
  });
};
