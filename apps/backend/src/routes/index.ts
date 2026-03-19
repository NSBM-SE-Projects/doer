import { Router } from 'express';
import authRoutes from './auth.routes';
import workerRoutes, { getNearbyWorkers } from './worker.routes';
import jobRoutes from './job.routes';
import earningsRoutes, { paymentRouter } from './earnings.routes';
import messageRoutes from './message.routes';
import { authenticate } from '../middleware/auth';

const router = Router();

router.use('/auth', authRoutes);
router.use('/workers', workerRoutes);
router.use('/jobs', jobRoutes);
router.use('/earnings', earningsRoutes);
router.use('/payments', paymentRouter);
router.use('/messages', messageRoutes);
router.get('/conversations', authenticate, (req, res) => res.redirect('/api/messages/conversations'));
router.post('/location/nearby-workers', authenticate, getNearbyWorkers);

export default router;
