import { Router } from 'express';
import {
  createJob,
  browseJobs,
  getJobById,
  applyToJob,
  getJobApplications,
  assignWorker,
  updateJobStatus,
} from '../controllers/job.controller';
import { authenticate, requireRole } from '../middleware/auth';

const router = Router();

router.post('/', authenticate, requireRole('CUSTOMER'), createJob);
router.get('/', authenticate, browseJobs);
router.get('/:id', authenticate, getJobById);
router.post('/:id/apply', authenticate, requireRole('WORKER'), applyToJob);
router.get('/:id/applications', authenticate, requireRole('CUSTOMER'), getJobApplications);
router.patch('/:id/assign', authenticate, requireRole('CUSTOMER'), assignWorker);
router.patch('/:id/status', authenticate, updateJobStatus);

export default router;
