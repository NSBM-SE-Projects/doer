import { Router } from 'express';
import authRoutes from './auth';
import categoryRoutes from './categories';
import userRoutes from './users';
import jobRoutes from './jobs';
import applicationRoutes from './applications';
import messageRoutes from './messages';
import notificationRoutes from './notifications';
import paymentRoutes from './payments';
import mapRoutes from './maps';
import agoraRoutes from './agora';
import uploadRoutes from './upload';
import portfolioRoutes from './portfolio';
import adminRoutes from './admin';

const router = Router();

router.use('/auth', authRoutes);
router.use('/categories', categoryRoutes);
router.use('/users', userRoutes);
router.use('/jobs', jobRoutes);
router.use('/applications', applicationRoutes);
router.use('/messages', messageRoutes);
router.use('/notifications', notificationRoutes);
router.use('/payments', paymentRoutes);
router.use('/maps', mapRoutes);
router.use('/agora', agoraRoutes);
router.use('/upload', uploadRoutes);
router.use('/portfolio', portfolioRoutes);
router.use('/admin', adminRoutes);

export default router;
