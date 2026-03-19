import { Router } from 'express';
import authRoutes from './auth';
import categoryRoutes from './categories';
import userRoutes from './users';
import jobRoutes from './jobs';

const router = Router();

router.use('/auth', authRoutes);
router.use('/categories', categoryRoutes);
router.use('/users', userRoutes);
router.use('/jobs', jobRoutes);

export default router;
