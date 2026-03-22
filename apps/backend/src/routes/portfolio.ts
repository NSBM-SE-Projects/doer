import { Router, Response } from 'express';
import { z } from 'zod';
import prisma from '../config/prisma';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';

const router = Router();

// GET /api/portfolio/:workerId — get a worker's portfolio (public)
router.get(
  '/:workerId',
  asyncHandler(async (req, res) => {
    const items = await prisma.portfolioItem.findMany({
      where: { workerId: req.params.workerId as string },
      include: { category: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ portfolio: items });
  })
);

// POST /api/portfolio — add portfolio item (worker only)
router.post(
  '/',
  authenticate,
  authorize('WORKER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { imageUrl, caption, categoryId } = z.object({
      imageUrl: z.string(),
      caption: z.string().optional(),
      categoryId: z.string().optional(),
    }).parse(req.body);

    const worker = await prisma.workerProfile.findUnique({
      where: { userId: req.user!.userId },
    });
    if (!worker) throw AppError.notFound('Worker profile not found');

    const item = await prisma.portfolioItem.create({
      data: {
        imageUrl,
        caption,
        workerId: worker.id,
        categoryId,
      },
      include: { category: true },
    });

    res.status(201).json({ item });
  })
);

// DELETE /api/portfolio/:id — remove portfolio item (worker only)
router.delete(
  '/:id',
  authenticate,
  authorize('WORKER'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const item = await prisma.portfolioItem.findUnique({
      where: { id: req.params.id as string },
      include: { worker: true },
    });
    if (!item) throw AppError.notFound('Portfolio item not found');
    if (item.worker.userId !== req.user!.userId) throw AppError.forbidden('Not your portfolio item');

    await prisma.portfolioItem.delete({ where: { id: item.id } });
    res.json({ message: 'Portfolio item deleted' });
  })
);

export default router;
