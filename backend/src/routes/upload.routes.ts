import { Router } from 'express';
import { uploadFile } from '../controllers/uploadController';
import { requireAuth } from '../middleware/auth';
import { upload } from '../lib/uploadService';

const router = Router();

router.post('/', requireAuth, upload.single('file'), uploadFile);

export default router;
