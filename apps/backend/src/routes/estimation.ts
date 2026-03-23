import { Router, Response } from 'express';
import { z } from 'zod';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';
import prisma from '../config/prisma';
import {
  estimateJobDuration,
  getStoredEstimate,
  compareWorkerEstimates,
  getEstimationStats,
} from '../services/estimation.service';

const router = Router();

// ─── POST /api/jobs/:jobId/estimate — Generate/refresh a duration estimate ──

router.post(
  '/:jobId/estimate',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const job = await prisma.job.findUnique({
      where: { id: req.params.jobId as string },
      include: { customer: true, worker: true },
    });
    if (!job) throw AppError.notFound('Job not found');

    // Parse optional body
    const bodySchema = z.object({
      complexity: z.enum(['SIMPLE', 'MODERATE', 'COMPLEX', 'EXPERT']).optional(),
      workerId: z.string().optional(),
      scheduledStartAt: z.string().datetime().optional(),
    }).optional();

    const body = bodySchema.parse(req.body) || {};

    const result = await estimateJobDuration(job.id, {
      complexity: body.complexity as any,
      workerId: body.workerId,
      scheduledStartAt: body.scheduledStartAt ? new Date(body.scheduledStartAt) : undefined,
    });

    res.json({
      jobId: job.id,
      estimate: result,
    });
  })
);

// ─── GET /api/jobs/:jobId/estimate — Get stored estimate for a job ──────────

router.get(
  '/:jobId/estimate',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const job = await prisma.job.findUnique({
      where: { id: req.params.jobId as string },
    });
    if (!job) throw AppError.notFound('Job not found');

    const estimate = await getStoredEstimate(job.id);
    if (!estimate) throw AppError.notFound('No estimate found for this job');

    res.json({
      jobId: job.id,
      estimate,
    });
  })
);

// ─── POST /api/jobs/:jobId/estimate/compare — Compare estimates with different workers

router.post(
  '/:jobId/estimate/compare',
  authenticate,
  authorize('CUSTOMER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const job = await prisma.job.findUnique({
      where: { id: req.params.jobId as string },
      include: { customer: true },
    });
    if (!job) throw AppError.notFound('Job not found');
    if (job.customer.userId !== req.user!.userId) throw AppError.forbidden('Not your job');

    const { workerIds } = z.object({
      workerIds: z.array(z.string()).min(1).max(5),
    }).parse(req.body);

    const comparisons = await compareWorkerEstimates(job.id, workerIds);

    // Enrich with worker info
    const enriched = await Promise.all(
      comparisons.map(async (c) => {
        const worker = await prisma.workerProfile.findUnique({
          where: { id: c.workerId },
          include: {
            user: { select: { id: true, name: true, avatarUrl: true } },
          },
        });
        return {
          worker: worker ? {
            id: worker.id,
            name: worker.user.name,
            avatarUrl: worker.user.avatarUrl,
            rating: worker.rating,
            totalJobs: worker.totalJobs,
            badgeLevel: worker.badgeLevel,
          } : null,
          estimate: c.estimate,
        };
      })
    );

    res.json({
      jobId: job.id,
      comparisons: enriched,
    });
  })
);

export default router;
