import { Router, Response } from 'express';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';
import prisma from '../config/prisma';
import { matchWorkersForJob } from '../services/matching.service';

const router = Router();

// POST /api/jobs/:jobId/match — trigger matching for a job
router.post(
  '/:jobId/match',
  authenticate,
  authorize('CUSTOMER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const job = await prisma.job.findUnique({
      where: { id: req.params.jobId as string },
      include: { customer: true },
    });
    if (!job) throw AppError.notFound('Job not found');
    if (job.customer.userId !== req.user!.userId) throw AppError.forbidden('Not your job');
    if (job.status !== 'OPEN') throw AppError.badRequest('Can only match open jobs');

    const result = await matchWorkersForJob(job.id);

    res.json(result);
  })
);

// GET /api/jobs/:jobId/matches — get match results for a job
router.get(
  '/:jobId/matches',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const job = await prisma.job.findUnique({
      where: { id: req.params.jobId as string },
      include: { customer: true },
    });
    if (!job) throw AppError.notFound('Job not found');

    const matches = await prisma.jobMatch.findMany({
      where: { jobId: req.params.jobId as string },
      include: {
        worker: {
          include: {
            user: { select: { id: true, name: true, avatarUrl: true, phone: true } },
            categories: { include: { category: true } },
          },
        },
      },
      orderBy: { matchScore: 'desc' },
    });

    res.json({ jobId: job.id, matches });
  })
);

export default router;
