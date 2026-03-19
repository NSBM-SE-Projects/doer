import { JobStatus } from '@prisma/client';
import prisma from '../utils/prisma';

const jobInclude = {
  customer: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } },
  worker: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } },
  category: true,
};

export const createJob = async (data: {
  title: string;
  description: string;
  price?: number;
  latitude?: number;
  longitude?: number;
  address?: string;
  scheduledAt?: string;
  categoryId: string;
  customerId: string;
}) => {
  return prisma.job.create({
    data: {
      ...data,
      scheduledAt: data.scheduledAt ? new Date(data.scheduledAt) : undefined,
    },
    include: jobInclude,
  });
};

export const browseJobs = async (params: {
  role: string;
  customerId?: string;
  workerId?: string;
  categoryId?: string;
  lat?: number;
  lng?: number;
}) => {
  const { role, customerId, categoryId } = params;

  if (role === 'CUSTOMER' && customerId) {
    return prisma.job.findMany({
      where: { customerId },
      include: jobInclude,
      orderBy: { createdAt: 'desc' },
    });
  }

  // WORKER sees OPEN jobs
  return prisma.job.findMany({
    where: {
      status: 'OPEN',
      ...(categoryId && { categoryId }),
    },
    include: jobInclude,
    orderBy: { createdAt: 'desc' },
  });
};

export const getJobById = async (jobId: string) => {
  return prisma.job.findUnique({
    where: { id: jobId },
    include: {
      ...jobInclude,
      applications: {
        include: {
          worker: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } },
        },
      },
      review: true,
      payment: true,
    },
  });
};

export const applyToJob = async (jobId: string, workerId: string, message?: string) => {
  return prisma.jobApplication.create({
    data: { jobId, workerId, message },
  });
};

export const getJobApplications = async (jobId: string) => {
  return prisma.jobApplication.findMany({
    where: { jobId },
    include: {
      worker: {
        include: {
          user: { select: { id: true, name: true, avatarUrl: true, phone: true } },
          categories: { include: { category: true } },
        },
      },
    },
    orderBy: { createdAt: 'desc' },
  });
};

export const assignWorker = async (jobId: string, workerId: string) => {
  return prisma.job.update({
    where: { id: jobId },
    data: { workerId, status: 'ASSIGNED' },
    include: jobInclude,
  });
};

export const updateJobStatus = async (jobId: string, status: JobStatus) => {
  const data: Record<string, unknown> = { status };
  if (status === 'COMPLETED') {
    data.completedAt = new Date();
  }
  return prisma.job.update({
    where: { id: jobId },
    data,
    include: jobInclude,
  });
};
