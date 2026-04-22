import { Router } from 'express';
import authRoutes from './auth.routes';
import postRoutes from './post.routes';
import academicRoutes from './academic.routes';
import communityRoutes from './community.routes';
import uploadRoutes from './upload.routes';
import userRoutes from './user.routes';
import notificationRoutes from './notification.routes';
import chatRoutes from './chat.routes';
import dmRoutes from './dm.routes';
import adminRoutes from './admin.routes';
import aiRoutes from './ai.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/posts', postRoutes);
router.use('/academic', academicRoutes);
router.use('/community', communityRoutes);
router.use('/upload', uploadRoutes);
router.use('/users', userRoutes);
router.use('/notifications', notificationRoutes);
// router.use('/chat', chatRoutes);
router.use('/dm', dmRoutes);
router.use('/admin', adminRoutes);
router.use('/ai', aiRoutes);

export default router;