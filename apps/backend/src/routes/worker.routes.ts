import { Router } from 'express';
import {
  listWorkers,
  getWorkerById,
  updateMyProfile,
  toggleAvailability,
  uploadDocument,
  getMyDocuments,
  getNearbyWorkers,
} from '../controllers/worker.controller';
import { authenticate, requireRole } from '../middleware/auth';

const router = Router();

router.get('/', authenticate, listWorkers);
router.get('/:id', authenticate, getWorkerById);
router.put('/profile', authenticate, requireRole('WORKER'), updateMyProfile);
router.patch('/availability', authenticate, requireRole('WORKER'), toggleAvailability);
router.post('/verification', authenticate, requireRole('WORKER'), uploadDocument);
router.get('/verification', authenticate, requireRole('WORKER'), getMyDocuments);

export { getNearbyWorkers };
export default router;
