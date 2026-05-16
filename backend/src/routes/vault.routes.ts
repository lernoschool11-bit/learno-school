import { Router } from 'express';
import { 
  uploadSummary, 
  getApprovedSummaries, 
  getPendingSummaries, 
  approveSummary, 
  rejectSummary 
} from '../controllers/vaultController';
import { requireAuth } from '../middleware/auth';

const router = Router();

router.use(requireAuth);

router.post('/upload', uploadSummary);
router.get('/approved', getApprovedSummaries);
router.get('/pending', getPendingSummaries);
router.post('/approve', approveSummary);
router.post('/reject', rejectSummary);

export default router;
