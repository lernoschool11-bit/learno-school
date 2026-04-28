import { Router } from 'express';
import { createOnlineClass, getActiveOnlineClasses, endOnlineClass } from '../controllers/onlineClassController';
import { requireAuth } from '../middleware/auth';

const router = Router();

router.use(requireAuth);

router.post('/', createOnlineClass);
router.get('/active', getActiveOnlineClasses);
router.patch('/:id/end', endOnlineClass);

export default router;
