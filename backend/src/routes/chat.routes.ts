import { Router } from 'express';
import { requireAuth } from '../middleware/auth';
import {
  sendRequest,
  respondRequest,
  getConversations,
  getPendingRequests,
  getMessages,
} from '../controllers/chatController';

const router = Router();

router.use(requireAuth);

router.post('/request', sendRequest);
router.put('/request/respond', respondRequest);
router.get('/conversations', getConversations);
router.get('/pending', getPendingRequests);
router.get('/:conversationId/messages', getMessages);

export default router;
