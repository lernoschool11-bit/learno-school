import { Router } from 'express';
import { 
  createPost, 
  getFeed, 
  toggleLike, 
  getComments, 
  addComment, 
  deleteComment,
  deletePost
} from '../controllers/postController';
import { requireAuth } from '../middleware/auth';

const router = Router();

router.use(requireAuth);

// Feed & Create
router.get('/feed', getFeed);
router.post('/', createPost);

// Delete Post
router.delete('/:id', deletePost);

// Like
router.post('/:id/like', toggleLike);

// Comments
router.get('/:id/comments', getComments);
router.post('/:id/comments', addComment);
router.delete('/:id/comments/:commentId', deleteComment);

export default router;