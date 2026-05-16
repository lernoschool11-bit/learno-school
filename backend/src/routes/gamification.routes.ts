import { Router } from 'express';
import { 
  createQuest, 
  submitAnswer, 
  validateAnswer, 
  getQuests, 
  getLeaderboard,
  getQuestAnswers 
} from '../controllers/gamificationController';
import { requireAuth } from '../middleware/auth';

const router = Router();

router.use(requireAuth);

router.get('/quests', getQuests);
router.post('/quests', createQuest);
router.get('/quests/:questId/answers', getQuestAnswers);
router.post('/quests/:questId/submit', submitAnswer);
router.post('/quests/validate', validateAnswer);
router.get('/leaderboard', getLeaderboard);

export default router;
