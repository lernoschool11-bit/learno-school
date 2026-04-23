import express from 'express';
import { authMiddleware } from '../middleware/auth';
import { addGrade, getMyGrades, getClassGrades } from '../controllers/gradeController';

const router = express.Router();

// معلم يدخل علامة
router.post('/', authMiddleware, addGrade);

// طالب يشوف علاماته
router.get('/my', authMiddleware, getMyGrades);

// معلم/مدير يشوف الصف
router.get('/class', authMiddleware, getClassGrades);

export default router;
