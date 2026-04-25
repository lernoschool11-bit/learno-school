import { Request, Response } from "express";
import prisma from "../lib/prisma";
import bcrypt from "bcrypt";
import { AuthRequest } from "../middleware/auth";

// ==================== FORCE PASSWORD CHANGE ====================
export const changeInitialPassword = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.id;
        const { newPassword } = req.body;

        if (!newPassword || newPassword.length < 6) {
            return res.status(400).json({ message: "كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل" });
        }

        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: { linkedSchool: true }
        });

        if (!user || user.role !== 'PRINCIPAL' || !user.linkedSchool) {
            return res.status(403).json({ message: "غير مسموح لهذا المستخدم" });
        }

        const hashedPassword = await bcrypt.hash(newPassword, 10);

        // Update User password
        await prisma.user.update({
            where: { id: userId },
            data: { password: hashedPassword }
        });

        // Update School isPasswordChanged
        await prisma.school.update({
            where: { id: user.schoolId! },
            data: { 
                isPasswordChanged: true,
                adminPassword: hashedPassword // Syncing school admin password
            }
        });

        return res.json({ message: "تم تغيير كلمة المرور بنجاح" });
    } catch (error) {
        console.error("changeInitialPassword error:", error);
        return res.status(500).json({ message: "خطأ في السيرفر" });
    }
};

// ==================== UPDATE TEACHER SECRET CODE ====================
export const updateTeacherSecretCode = async (req: AuthRequest, res: Response) => {
    try {
        const { schoolId } = req.user!;
        const { newCode } = req.body;

        if (!schoolId) return res.status(403).json({ message: "مطلوب معرف المدرسة" });

        await prisma.school.update({
            where: { id: schoolId },
            data: { teacherSecretCode: newCode }
        });

        return res.json({ message: "تم تحديث رمز التحقق للمعلمين بنجاح" });
    } catch (error) {
        console.error("updateTeacherSecretCode error:", error);
        return res.status(500).json({ message: "خطأ في السيرفر" });
    }
};

// ==================== GET SCHOOL TEACHER CODE ====================
export const getTeacherSecretCode = async (req: AuthRequest, res: Response) => {
    try {
        const { schoolId } = req.user!;
        if (!schoolId) return res.status(403).json({ message: "مطلوب معرف المدرسة" });

        const school = await prisma.school.findUnique({
            where: { id: schoolId },
            select: { teacherSecretCode: true }
        });

        return res.json({ code: school?.teacherSecretCode });
    } catch (error) {
        console.error("getTeacherSecretCode error:", error);
        return res.status(500).json({ message: "خطأ في السيرفر" });
    }
};

// ==================== GET SCHOOL USERS ====================
export const getSchoolUsers = async (req: AuthRequest, res: Response) => {
    try {
        const { schoolId } = req.user!;
        if (!schoolId) return res.status(403).json({ message: "مطلوب معرف المدرسة" });

        const users = await prisma.user.findMany({
            where: { schoolId },
            select: {
                id: true,
                fullName: true,
                username: true,
                role: true,
                email: true,
                avatarUrl: true,
                isActive: true,
                createdAt: true,
                grade: true,
                section: true,
            },
            orderBy: { createdAt: 'desc' }
        });

        return res.json(users);
    } catch (error) {
        console.error("getSchoolUsers error:", error);
        return res.status(500).json({ message: "خطأ في السيرفر" });
    }
};

// ==================== KICK/DELETE USER ====================
export const deleteSchoolUser = async (req: AuthRequest, res: Response) => {
    try {
        const { schoolId } = req.user!;
        const targetUserId = String(req.params.userId);

        if (!schoolId) return res.status(403).json({ message: "مطلوب معرف المدرسة" });

        const targetUser = await prisma.user.findUnique({
            where: { id: targetUserId }
        });

        if (!targetUser || targetUser.schoolId !== schoolId) {
            return res.status(403).json({ message: "لا يمكنك حذف هذا المستخدم" });
        }

        if (targetUser.role === 'PRINCIPAL') {
            return res.status(403).json({ message: "لا يمكنك حذف مدير المدرسة" });
        }

        await prisma.user.delete({
            where: { id: targetUserId }
        });

        return res.json({ message: "تم حذف المستخدم بنجاح" });
    } catch (error) {
        console.error("deleteSchoolUser error:", error);
        return res.status(500).json({ message: "خطأ في السيرفر" });
    }
};

// ==================== FREEZE/UNFREEZE USER ====================
export const toggleUserStatus = async (req: AuthRequest, res: Response) => {
    try {
        const { schoolId } = req.user!;
        const targetUserId = String(req.params.userId);

        if (!schoolId) return res.status(403).json({ message: "مطلوب معرف المدرسة" });

        const targetUser = await prisma.user.findUnique({
            where: { id: targetUserId }
        });

        if (!targetUser || targetUser.schoolId !== schoolId) {
            return res.status(403).json({ message: "لا يمكنك تعديل هذا المستخدم" });
        }

        if (targetUser.role === 'PRINCIPAL') {
            return res.status(403).json({ message: "لا يمكنك تجميد مدير المدرسة" });
        }

        const updatedUser = await prisma.user.update({
            where: { id: targetUserId },
            data: { isActive: !targetUser.isActive }
        });

        return res.json({ 
            message: updatedUser.isActive ? "تم تفعيل الحساب" : "تم تجميد الحساب",
            isActive: updatedUser.isActive 
        });
    } catch (error) {
        console.error("toggleUserStatus error:", error);
        return res.status(500).json({ message: "خطأ في السيرفر" });
    }
};

// ==================== GET SCHOOL POSTS ====================
export const getSchoolPosts = async (req: AuthRequest, res: Response) => {
    try {
        const { schoolId } = req.user!;
        if (!schoolId) return res.status(403).json({ message: "مطلوب معرف المدرسة" });

        const posts = await prisma.post.findMany({
            where: { schoolId },
            include: {
                author: {
                    select: {
                        id: true,
                        fullName: true,
                        username: true,
                        avatarUrl: true,
                    }
                }
            },
            orderBy: { createdAt: 'desc' }
        });

        return res.json(posts);
    } catch (error) {
        console.error("getSchoolPosts error:", error);
        return res.status(500).json({ message: "خطأ في السيرفر" });
    }
};

// ==================== GET SCHOOL CLASSES ====================
export const getSchoolClasses = async (req: AuthRequest, res: Response) => {
    try {
        const { schoolId, role } = req.user!;
        if (!schoolId) return res.status(403).json({ message: "مطلوب معرف المدرسة" });

        // Get student counts for existing classes
        const studentCounts = await prisma.user.groupBy({
            by: ['grade', 'section'],
            where: {
                schoolId,
                role: 'STUDENT',
                grade: { not: null },
                section: { not: null }
            },
            _count: { id: true }
        });

        const countsMap: Record<string, number> = {};
        studentCounts.forEach(c => {
            countsMap[`${c.grade}-${c.section}`] = c._count.id;
        });

        // If Principal, return all possible classes from 4-A to 10-D
        if (role === 'PRINCIPAL') {
            const allPossibleClasses = [];
            const grades = ['4', '5', '6', '7', '8', '9', '10'];
            const sections = ['أ', 'ب', 'ج', 'د'];

            for (const g of grades) {
                for (const s of sections) {
                    allPossibleClasses.push({
                        grade: g,
                        section: s,
                        studentCount: countsMap[`${g}-${s}`] || 0
                    });
                }
            }
            return res.json(allPossibleClasses);
        }

        // For others (Teachers), return only classes that have students or are assigned to them
        // (For simplicity, returning all with students)
        const formattedClasses = studentCounts.map(c => ({
            grade: c.grade,
            section: c.section,
            studentCount: c._count.id
        }));

        return res.json(formattedClasses);
    } catch (error) {
        console.error("getSchoolClasses error:", error);
        return res.status(500).json({ message: "خطأ في السيرفر" });
    }
};


// ==================== GET SCHOOL STATS ====================
export const getSchoolStats = async (req: AuthRequest, res: Response) => {
    try {
        const { schoolId } = req.user!;
        if (!schoolId) return res.status(403).json({ message: "????? ???? ???????" });

        const [userCount, teacherCount, postCount, commentCount] = await Promise.all([
            prisma.user.count({ where: { schoolId, role: 'STUDENT' } }),
            prisma.user.count({ where: { schoolId, role: 'TEACHER' } }),
            prisma.post.count({ where: { schoolId } }),
            prisma.comment.count({ where: { post: { schoolId } } })
        ]);

        const totalUsers = userCount + teacherCount;
        const engagementRate = totalUsers > 0 ? ((postCount + commentCount) / totalUsers) : 0;
        const activityScore = Math.min(100, (engagementRate / 5) * 100);

        return res.json({
            students: userCount,
            teachers: teacherCount,
            posts: postCount,
            comments: commentCount,
            engagementRate: engagementRate.toFixed(1),
            activityScore: Math.round(activityScore),
            status: engagementRate > 5 ? 'ممتاز' : (engagementRate > 2 ? 'جيد جدا' : 'جيد')
        });
    } catch (error) {
        console.error("getSchoolStats error:", error);
        return res.status(500).json({ message: "??? ?? ???????" });
    }
};
