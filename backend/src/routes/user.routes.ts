import { Router } from 'express';
import {
  getUserProfile,
  toggleFollow,
  getFollowers,
  getFollowing,
} from '../controllers/userController';
import { requireAuth } from '../middleware/auth';

const router = Router();

router.use(requireAuth);

router.get('/:userId', getUserProfile);
router.post('/:userId/follow', toggleFollow);
router.get('/:userId/followers', getFollowers);
router.get('/:userId/following', getFollowing);

export default router;