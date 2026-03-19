import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import * as jobService from '../services/job.service';
import prisma from '../utils/prisma';
import { success, error } from '../utils/response';
import { JobStatus } from '@prisma/client';

export const createJob = async (req: AuthRequest, res: Response) => {
  try {
    const customerProfile = await prisma.customerProfile.findUnique({
      where: { userId: req.user!.dbUserId },
    });
    if (!customerProfile) return error(res, 'Customer profile not found', 404);

    const { title, description, price, latitude, longitude, address, scheduledAt, categoryId } =
      req.body;
    if (!title || !description || !categoryId) {
      return error(res, 'title, description, and categoryId are required');
    }

    const job = await jobService.createJob({
      title,
      description,
      price: price !== undefined ? Number(price) : undefined,
      latitude: latitude !== undefined ? Number(latitude) : undefined,
      longitude: longitude !== undefined ? Number(longitude) : undefined,
      address,
      scheduledAt,
      categoryId,
      customerId: customerProfile.id,
    });
    return success(res, job, 201);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to create job';
    return error(res, message, 500);
  }
};

export const browseJobs = async (req: AuthRequest, res: Response) => {
  try {
    const { role, dbUserId } = req.user!;
    const { categoryId, lat, lng } = req.query;

    let customerId: string | undefined;
    let workerId: string | undefined;

    if (role === 'CUSTOMER') {
      const profile = await prisma.customerProfile.findUnique({ where: { userId: dbUserId } });
      customerId = profile?.id;
    } else if (role === 'WORKER') {
      const profile = await prisma.workerProfile.findUnique({ where: { userId: dbUserId } });
      workerId = profile?.id;
    }

    const jobs = await jobService.browseJobs({
      role,
      customerId,
      workerId,
      categoryId: categoryId as string | undefined,
      lat: lat ? Number(lat) : undefined,
      lng: lng ? Number(lng) : undefined,
    });
    return success(res, jobs);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to browse jobs';
    return error(res, message, 500);
  }
};

export const getJobById = async (req: AuthRequest, res: Response) => {
  try {
    const job = await jobService.getJobById(req.params.id);
    if (!job) return error(res, 'Job not found', 404);
    return success(res, job);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to get job';
    return error(res, message, 500);
  }
};

export const applyToJob = async (req: AuthRequest, res: Response) => {
  try {
    const workerProfile = await prisma.workerProfile.findUnique({
      where: { userId: req.user!.dbUserId },
    });
    if (!workerProfile) return error(res, 'Worker profile not found', 404);

    const { message } = req.body;
    const application = await jobService.applyToJob(req.params.id, workerProfile.id, message);
    return success(res, application, 201);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to apply to job';
    return error(res, message, 500);
  }
};

export const getJobApplications = async (req: AuthRequest, res: Response) => {
  try {
    const applications = await jobService.getJobApplications(req.params.id);
    return success(res, applications);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to get applications';
    return error(res, message, 500);
  }
};

export const assignWorker = async (req: AuthRequest, res: Response) => {
  try {
    const { workerId } = req.body;
    if (!workerId) return error(res, 'workerId is required');

    const job = await jobService.assignWorker(req.params.id, workerId);
    return success(res, job);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to assign worker';
    return error(res, message, 500);
  }
};

export const updateJobStatus = async (req: AuthRequest, res: Response) => {
  try {
    const { status } = req.body;
    const validStatuses: JobStatus[] = ['IN_PROGRESS', 'COMPLETED', 'CANCELLED'];
    if (!status || !validStatuses.includes(status)) {
      return error(res, 'Valid status required: IN_PROGRESS, COMPLETED, or CANCELLED');
    }

    const job = await jobService.updateJobStatus(req.params.id, status);
    return success(res, job);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to update job status';
    return error(res, message, 500);
  }
};
