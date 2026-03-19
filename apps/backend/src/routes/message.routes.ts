import { Router } from 'express';
import { getMessageHistory, sendMessage, getConversations } from '../controllers/message.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

router.get('/conversations', authenticate, getConversations);
router.get('/:jobId', authenticate, getMessageHistory);
router.post('/', authenticate, sendMessage);

export default router;
