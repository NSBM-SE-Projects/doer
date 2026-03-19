import { Router, Request, Response } from 'express';
import authRoutes from './auth.routes';
import workerRoutes, { getNearbyWorkers } from './worker.routes';
import jobRoutes from './job.routes';
import earningsRoutes, { paymentRouter } from './earnings.routes';
import messageRoutes from './message.routes';
import reviewRoutes from './review.routes';
import notificationRoutes from './notification.routes';
import { authenticate } from '../middleware/auth';
import prisma from '../utils/prisma';
import { success, error } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

const router = Router();

router.use('/auth', authRoutes);
router.use('/workers', workerRoutes);
router.use('/jobs', jobRoutes);
router.use('/earnings', earningsRoutes);
router.use('/payments', paymentRouter);
router.use('/messages', messageRoutes);
router.use('/reviews', reviewRoutes);
router.use('/notifications', notificationRoutes);

router.post('/location/nearby-workers', authenticate, getNearbyWorkers);

// Recommendation endpoint
router.post('/recommend', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { lat, lng, categoryId, limit = 10 } = req.body;

    const badgeWeights: Record<string, number> = {
      PLATINUM: 5,
      GOLD: 4,
      SILVER: 3,
      BRONZE: 2,
      TRAINEE: 1,
    };

    const workers = await prisma.workerProfile.findMany({
      where: {
        isAvailable: true,
        ...(categoryId && { categories: { some: { categoryId } } }),
      },
      include: {
        user: { select: { id: true, name: true, avatarUrl: true } },
        categories: { include: { category: true } },
      },
    });

    const scored = workers.map((worker) => {
      const badgeWeight = badgeWeights[worker.badgeLevel] || 1;
      let distanceDecay = 1;

      if (lat && lng && worker.latitude && worker.longitude) {
        const dLat = ((worker.latitude - Number(lat)) * Math.PI) / 180;
        const dLng = ((worker.longitude - Number(lng)) * Math.PI) / 180;
        const a =
          Math.sin(dLat / 2) ** 2 +
          Math.cos((Number(lat) * Math.PI) / 180) *
            Math.cos((worker.latitude * Math.PI) / 180) *
            Math.sin(dLng / 2) ** 2;
        const distanceKm = 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        distanceDecay = 1 / (1 + distanceKm / 10);
      }

      const score = badgeWeight * (worker.rating || 1) * distanceDecay;
      return { ...worker, score };
    });

    scored.sort((a, b) => b.score - a.score);
    return success(res, scored.slice(0, Number(limit)));
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Recommendation failed';
    return error(res, message, 500);
  }
});

// Google Places autocomplete proxy
router.post('/location/autocomplete', authenticate, async (req: Request, res: Response) => {
  try {
    const { input, sessionToken } = req.body;
    if (!input) return error(res as Response, 'input is required');

    const apiKey = process.env.GOOGLE_PLACES_API_KEY;
    const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(input)}&key=${apiKey}&components=country:lk${sessionToken ? `&sessiontoken=${sessionToken}` : ''}`;

    const response = await fetch(url);
    const data = await response.json();
    return success(res as Response, data);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Autocomplete failed';
    return error(res as Response, message, 500);
  }
});

// Google Places details proxy
router.post('/location/place-details', authenticate, async (req: Request, res: Response) => {
  try {
    const { placeId, sessionToken } = req.body;
    if (!placeId) return error(res as Response, 'placeId is required');

    const apiKey = process.env.GOOGLE_PLACES_API_KEY;
    const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=geometry,formatted_address,name&key=${apiKey}${sessionToken ? `&sessiontoken=${sessionToken}` : ''}`;

    const response = await fetch(url);
    const data = await response.json();
    return success(res as Response, data);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Place details failed';
    return error(res as Response, message, 500);
  }
});

export default router;
