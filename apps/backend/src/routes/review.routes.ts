import { Router } from 'express';
import { submitReview, getWorkerReviews } from '../controllers/review.controller';
import { authenticate, requireRole } from '../middleware/auth';

const router = Router();

router.post('/', authenticate, requireRole('CUSTOMER'), submitReview);
router.get('/worker/:id', authenticate, getWorkerReviews);

export default router;
