import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { prisma } from '../lib/prisma';

const router = Router();

// middleware يتحقق إن المستخدم PRINCIPAL
const principalOnly = async (req: any, res: any, next: any) => {
  if (req.user?.role !== 'PRINCIPAL') {
    return res.status(403).json({ message: 'غير مصرح' });
  }
  next();
};

// إحصائيات المدرسة
router.get('/stats', authMiddleware, principalOnly, async (req: any, res) => {
  try {
    const school = req.user.school;
    const [teacherCount, studentCount] = await Promise.all([
      prisma.user.count({ where: { school, role: 'TEACHER' } }),
      prisma.user.count({ where: { school, role: 'STUDENT' } }),
    ]);
    res.json({ teacherCount, studentCount });
  } catch (e) {
    res.status(500).json({ message: 'خطأ في السيرفر' });
  }
});

// قائمة المستخدمين
router.get('/users', authMiddleware, principalOnly, async (req: any, res) => {
  try {
    const school = req.user.school;
    const role = req.query.role as string;
    const users = await prisma.user.findMany({
      where: { school, role: role as any },
      select: { id: true, fullName: true, email: true, role: true, grade: true, section: true },
    });
    res.json(users);
  } catch (e) {
    res.status(500).json({ message: 'خطأ في السيرفر' });
  }
});

// حذف مستخدم
router.delete('/users/:id', authMiddleware, principalOnly, async (req: any, res) => {
  try {
    await prisma.user.delete({ where: { id: req.params.id as string } });
    res.json({ message: 'تم الحذف' });
  } catch (e) {
    res.status(500).json({ message: 'خطأ في الحذف' });
  }
});

export default router;