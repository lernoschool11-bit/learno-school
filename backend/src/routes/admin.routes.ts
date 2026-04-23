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
router.get('/school-users', requireAuth, requireRole([Role.PRINCIPAL]), schoolController.getSchoolUsers);
router.delete('/school-users/:userId', requireAuth, requireRole([Role.PRINCIPAL]), schoolController.deleteSchoolUser);
router.put('/school-users/:userId/toggle-status', requireAuth, requireRole([Role.PRINCIPAL]), schoolController.toggleUserStatus);

// Post Moderation
router.get('/school-posts', requireAuth, requireRole([Role.PRINCIPAL]), schoolController.getSchoolPosts);

// Classes Management
router.get('/school-classes', requireAuth, requireRole([Role.PRINCIPAL]), schoolController.getSchoolClasses);


// Verify Teacher Code (Public - used during registration)
router.post('/verify-teacher-code', async (req, res) => {
    try {
        const { code, name } = req.body;
        // In a multi-school system, we should verify it against the specific school
        // But for now, if name is provided, find that school
        const school = await prisma.school.findFirst({
            where: {
                OR: [
                    { name: name },
                    { teacherSecretCode: code }
                ]
            }
        });
        
        if (!school) return res.json({ valid: false });
        
        res.json({ 
            valid: school.teacherSecretCode === code,
            schoolId: school.id,
            schoolName: school.name
        });
    } catch (e) {
        res.status(500).json({ message: 'خطأ' });
    }
});

export default router;