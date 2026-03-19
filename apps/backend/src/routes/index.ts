import { Router } from 'express';
import authRoutes from './auth';
import categoryRoutes from './categories';
import userRoutes from './users';
import jobRoutes from './jobs';
import messageRoutes from './messages';
import notificationRoutes from './notifications';
import paymentRoutes from './payments';

const router = Router();

router.use('/auth', authRoutes);
router.use('/categories', categoryRoutes);
router.use('/users', userRoutes);
router.use('/jobs', jobRoutes);
router.use('/messages', messageRoutes);
router.use('/notifications', notificationRoutes);
router.use('/payments', paymentRoutes);

export default router;
