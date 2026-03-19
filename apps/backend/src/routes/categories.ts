import { Router } from 'express';
import { z } from 'zod';
import prisma from '../config/prisma';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';

const router = Router();

const createCategorySchema = z.object({
  name: z.string().min(1),
  description: z.string().optional(),
  iconUrl: z.string().url().optional(),
});

const updateCategorySchema = createCategorySchema.partial();

// GET /api/categories — list all categories (public)
router.get(
  '/',
  asyncHandler(async (_req, res) => {
    const categories = await prisma.serviceCategory.findMany({
      orderBy: { name: 'asc' },
      include: {
        _count: { select: { workers: true, jobs: true } },
      },
    });
    res.json({ categories });
  })
);

// GET /api/categories/:id — get single category with workers
router.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const category = await prisma.serviceCategory.findUnique({
      where: { id: req.params.id as string },
      include: {
        workers: {
          include: {
            worker: {
              include: {
                user: { select: { id: true, name: true, avatarUrl: true } },
              },
            },
          },
        },
        _count: { select: { jobs: true } },
      },
    });

    if (!category) throw AppError.notFound('Category not found');

    res.json({ category });
  })
);

// POST /api/categories — create category (admin only)
router.post(
  '/',
  authenticate,
  authorize('ADMIN'),
  asyncHandler(async (req, res) => {
    const body = createCategorySchema.parse(req.body);

    const category = await prisma.serviceCategory.create({
      data: body,
    });

    res.status(201).json({ category });
  })
);

// PUT /api/categories/:id — update category (admin only)
router.put(
  '/:id',
  authenticate,
  authorize('ADMIN'),
  asyncHandler(async (req, res) => {
    const body = updateCategorySchema.parse(req.body);

    const existing = await prisma.serviceCategory.findUnique({
      where: { id: req.params.id as string },
    });
    if (!existing) throw AppError.notFound('Category not found');

    const category = await prisma.serviceCategory.update({
      where: { id: req.params.id as string },
      data: body,
    });

    res.json({ category });
  })
);

// DELETE /api/categories/:id — delete category (admin only)
router.delete(
  '/:id',
  authenticate,
  authorize('ADMIN'),
  asyncHandler(async (req, res) => {
    const existing = await prisma.serviceCategory.findUnique({
      where: { id: req.params.id as string },
    });
    if (!existing) throw AppError.notFound('Category not found');

    await prisma.serviceCategory.delete({
      where: { id: req.params.id as string },
    });

    res.json({ message: 'Category deleted' });
  })
);

// POST /api/categories/seed — seed default categories (admin only)
router.post(
  '/seed',
  authenticate,
  authorize('ADMIN'),
  asyncHandler(async (_req, res) => {
    const defaults = [
      { name: 'Plumbing', description: 'Pipe repairs, installations, and maintenance' },
      { name: 'Electrical', description: 'Wiring, fixtures, and electrical repairs' },
      { name: 'Cleaning', description: 'Home and office cleaning services' },
      { name: 'Painting', description: 'Interior and exterior painting' },
      { name: 'Gardening', description: 'Lawn care, landscaping, and garden maintenance' },
      { name: 'Moving', description: 'Packing, loading, and relocation services' },
      { name: 'Carpentry', description: 'Furniture repair, woodwork, and installations' },
      { name: 'Appliance Repair', description: 'Repair and maintenance of home appliances' },
    ];

    const categories = await Promise.all(
      defaults.map((cat) =>
        prisma.serviceCategory.upsert({
          where: { name: cat.name },
          update: {},
          create: cat,
        })
      )
    );

    res.status(201).json({ categories, count: categories.length });
  })
);

export default router;
