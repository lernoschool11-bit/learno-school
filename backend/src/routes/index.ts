import { Router } from 'express';
import authRoutes from './auth.routes';
import postRoutes from './post.routes';
import academicRoutes from './academic.routes';
import communityRoutes from './community.routes';
import uploadRoutes from './upload.routes';
import userRoutes from './user.routes';
import notificationRoutes from './notification.routes';
import chatRoutes from './chat.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/posts', postRoutes);
router.use('/academic', academicRoutes);
router.use('/community', communityRoutes);
router.use('/upload', uploadRoutes);
router.use('/users', userRoutes);
router.use('/notifications', notificationRoutes);
router.use('/chat', chatRoutes);

export default router;
