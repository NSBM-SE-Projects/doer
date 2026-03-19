import { Router } from 'express';
import {
  getEarningsSummary,
  getPayoutHistory,
  requestPayout,
  getSubscription,
  initiatePayment,
  payhereWebhook,
  getJobPayment,
} from '../controllers/earnings.controller';
import { authenticate, requireRole } from '../middleware/auth';

const router = Router();

router.get('/', authenticate, requireRole('WORKER'), getEarningsSummary);
router.get('/history', authenticate, requireRole('WORKER'), getPayoutHistory);
router.post('/payout', authenticate, requireRole('WORKER'), requestPayout);
router.get('/subscription', authenticate, requireRole('WORKER'), getSubscription);

export default router;

export const paymentRouter = Router();
paymentRouter.post('/', authenticate, requireRole('CUSTOMER'), initiatePayment);
paymentRouter.post('/webhook', payhereWebhook);
paymentRouter.get('/:jobId', authenticate, getJobPayment);
