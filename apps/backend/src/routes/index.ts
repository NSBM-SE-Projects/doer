import { Router } from 'express';
import authRoutes from './auth.routes';
import workerRoutes, { getNearbyWorkers } from './worker.routes';
import { authenticate } from '../middleware/auth';

const router = Router();

router.use('/auth', authRoutes);
router.use('/workers', workerRoutes);
router.post('/location/nearby-workers', authenticate, getNearbyWorkers);

export default router;
