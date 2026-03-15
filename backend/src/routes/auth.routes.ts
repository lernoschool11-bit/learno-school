import { Router } from 'express';
import {
  register,
  login,
  getMe,
  searchUsers,
  updateProfile,
  changePassword,
} from '../controllers/authController';
import { forgotPassword, resetPassword } from '../controllers/passwordResetController';
import { requireAuth } from '../middleware/auth';

const router = Router();

router.post("/login", login);
router.post("/register", register);
router.get("/me", requireAuth, getMe);
router.get("/search", requireAuth, searchUsers);
router.post("/forgot-password", forgotPassword);
router.post("/reset-password", resetPassword);
router.put("/update-profile", requireAuth, updateProfile);
router.put("/change-password", requireAuth, changePassword);

export default router;