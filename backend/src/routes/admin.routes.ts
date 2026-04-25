import { Router } from 'express';
import { requireAuth, requireRole } from '../middleware/auth';
import { Role } from '@prisma/client';
import prisma from '../lib/prisma';
import * as schoolController from '../controllers/schoolController';

const router = Router();

// ==================== PRINCIPAL ROUTES ====================

// Force Change Initial Password
router.post('/force-password-change', requireAuth, requireRole([Role.PRINCIPAL]), schoolController.changeInitialPassword);

// Teacher Secret Code Management
router.get('/teacher-code', requireAuth, requireRole([Role.PRINCIPAL]), schoolController.getTeacherSecretCode);
router.put('/teacher-code', requireAuth, requireRole([Role.PRINCIPAL]), schoolController.updateTeacherSecretCode);

// User Management
router.get('/school-users', requireAuth, requireRole([Role.PRINCIPAL, Role.TEACHER]), schoolController.getSchoolUsers);
router.delete('/school-users/:userId', requireAuth, requireRole([Role.PRINCIPAL]), schoolController.deleteSchoolUser);
router.put('/school-users/:userId/toggle-status', requireAuth, requireRole([Role.PRINCIPAL]), schoolController.toggleUserStatus);

// Post Moderation
router.get('/school-posts', requireAuth, requireRole([Role.PRINCIPAL]), schoolController.getSchoolPosts);

// Classes Management
router.get('/school-classes', requireAuth, requireRole([Role.PRINCIPAL, Role.TEACHER]), schoolController.getSchoolClasses);

// School Stats
router.get('/school-stats', requireAuth, schoolController.getSchoolStats);


// Verify Teacher Code (Public - used during registration)
router.post('/verify-teacher-code', async (req, res) => {
    try {
        const { code, name } = req.body;
        if (!code || !name) return res.json({ valid: false, message: 'الكود واسم المدرسة مطلوبان' });

        const school = await prisma.school.findFirst({
            where: { name: name }
        });
        
        if (!school) return res.json({ valid: false, message: 'المدرسة غير موجودة' });
        
        const isValid = school.teacherSecretCode === code;
        res.json({ 
            valid: isValid,
            schoolId: school.id,
            schoolName: school.name
        });
    } catch (e) {
        res.status(500).json({ message: 'خطأ في الخادم' });
    }
});

export default router;