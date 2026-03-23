import { Router, Response } from 'express';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';
import prisma from '../config/prisma';
import { getEstimationStats } from '../services/estimation.service';

const router = Router();

// ─── GET /api/estimation/stats — Global estimation accuracy stats (admin) ───

router.get(
  '/stats',
  authenticate,
  authorize('ADMIN'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const stats = await getEstimationStats();
    res.json(stats);
  })
);

// ─── GET /api/estimation/category/:categoryId — Category baseline info ──────

router.get(
  '/category/:categoryId',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const baseline = await prisma.categoryDurationBaseline.findUnique({
      where: { categoryId: req.params.categoryId as string },
      include: { category: true },
    });

    if (!baseline) throw AppError.notFound('No baseline data found for this category');

    res.json({
      category: baseline.category.name,
      defaultMinutes: baseline.defaultMinutes,
      avgMinutes: baseline.avgMinutes,
      medianMinutes: baseline.medianMinutes,
      stdDevMinutes: baseline.stdDevMinutes,
      p90Minutes: baseline.p90Minutes,
      sampleCount: baseline.sampleCount,
      complexityMultipliers: baseline.complexityMultipliers
        ? JSON.parse(baseline.complexityMultipliers)
        : null,
      keywordModifiers: baseline.keywordModifiers
        ? JSON.parse(baseline.keywordModifiers)
        : null,
    });
  })
);

// ─── GET /api/estimation/leaderboard — Workers ranked by estimation accuracy ─

router.get(
  '/leaderboard',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    // Find workers whose jobs have both estimates and actual durations
    const logs = await prisma.jobDurationLog.findMany({
      where: {
        estimatedMinutes: { not: null },
        workerId: { not: null },
        isSynthetic: false,
      },
    });

    // Group by worker
    const workerAccuracy: Record<string, { totalError: number; count: number; within20: number }> = {};
    for (const log of logs) {
      if (!log.workerId) continue;
      if (!workerAccuracy[log.workerId]) {
        workerAccuracy[log.workerId] = { totalError: 0, count: 0, within20: 0 };
      }
      const pctError = log.actualMinutes > 0
        ? Math.abs(log.actualMinutes - log.estimatedMinutes!) / log.actualMinutes
        : 0;
      workerAccuracy[log.workerId].totalError += pctError;
      workerAccuracy[log.workerId].count++;
      if (pctError <= 0.2) workerAccuracy[log.workerId].within20++;
    }

    // Build leaderboard
    const entries = await Promise.all(
      Object.entries(workerAccuracy)
        .filter(([_, stats]) => stats.count >= 3) // Minimum 3 jobs
        .map(async ([workerId, stats]) => {
          const worker = await prisma.workerProfile.findUnique({
            where: { id: workerId },
            include: { user: { select: { name: true } } },
          });
          return {
            workerId,
            workerName: worker?.user.name ?? 'Unknown',
            jobsTracked: stats.count,
            avgErrorPercent: Math.round((stats.totalError / stats.count) * 100),
            accuracyWithin20Pct: Math.round((stats.within20 / stats.count) * 100),
          };
        })
    );

    entries.sort((a, b) => a.avgErrorPercent - b.avgErrorPercent);

    res.json({ leaderboard: entries });
  })
);

export default router;
