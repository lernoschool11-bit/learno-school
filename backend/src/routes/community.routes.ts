import { Router } from 'express';
import { getCommunity } from '../controllers/communityController';
import { requireAuth } from '../middleware/auth';

const router = Router();

router.get('/', requireAuth, getCommunity);

export default router;
