import { Router } from 'express';
import authRoutes from './auth.routes';
import workerRoutes, { getNearbyWorkers } from './worker.routes';
import jobRoutes from './job.routes';
import { authenticate } from '../middleware/auth';

const router = Router();

router.use('/auth', authRoutes);
router.use('/workers', workerRoutes);
router.use('/jobs', jobRoutes);
router.post('/location/nearby-workers', authenticate, getNearbyWorkers);

export default router;
