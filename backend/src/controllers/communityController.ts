import { Response } from 'express';
import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth';

export const getCommunity = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;

    const currentUser = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        role: true,
        school: true,
        grade: true,
        section: true,
        classes: true,
      },
    });

    if (!currentUser) {
      return res.status(404).json({ message: 'المستخدم غير موجود' });
    }

    const { grade: reqGrade, section: reqSection } = req.query;
    
    if (currentUser.role === 'STUDENT') {
      const { school, grade, section } = currentUser;
      if (!grade || !section) return res.status(400).json({ message: 'لم يتم تحديد الصف والشعبة' });

      const students = await prisma.user.findMany({
        where: { role: 'STUDENT', school, grade, section, id: { not: userId } },
        select: { id: true, fullName: true, username: true, avatarUrl: true },
        orderBy: { fullName: 'asc' },
      });

      const allTeachers = await prisma.user.findMany({
        where: { role: 'TEACHER', school },
        select: { id: true, fullName: true, username: true, subjects: true, classes: true, avatarUrl: true },
      });

      const teachers = allTeachers.filter((t) => {
        try {
          const list = JSON.parse(t.classes || '[]');
          return list.some((cls: any) => cls.grade === grade && cls.section === section);
        } catch { return false; }
      }).map(t => ({ id: t.id, fullName: t.fullName, username: t.username, subjects: t.subjects, avatarUrl: t.avatarUrl }));

      return res.json({ school, grade, section, students, teachers });

    } else if (currentUser.role === 'TEACHER' || currentUser.role === 'PRINCIPAL') {
      const school = currentUser.school;
      let classList: Array<{ grade: string; section: string }> = [];

      if (currentUser.role === 'TEACHER') {
        try { classList = JSON.parse(currentUser.classes || '[]'); } catch { classList = []; }
      } else {
        // Principal: Get all unique classes in this school
        const users = await prisma.user.findMany({
          where: { school, role: 'STUDENT', NOT: { grade: null, section: null } },
          select: { grade: true, section: true },
          distinct: ['grade', 'section'],
        });
        classList = users.map(u => ({ grade: u.grade!, section: u.section! }));
      }

      if (classList.length === 0) return res.status(200).json({ school, availableClasses: [], students: [], teachers: [] });

      // Determine which class to show
      let activeClass = classList[0];
      if (reqGrade && reqSection) {
        const found = classList.find(c => c.grade === reqGrade && c.section === reqSection);
        if (found) activeClass = found;
        else if (currentUser.role === 'TEACHER') return res.status(403).json({ message: 'لا تملك صلاحية لهذا الصف' });
        else activeClass = { grade: reqGrade as string, section: reqSection as string }; 
      }

      const { grade, section } = activeClass;

      const students = await prisma.user.findMany({
        where: { role: 'STUDENT', school, grade, section },
        select: { id: true, fullName: true, username: true, avatarUrl: true },
        orderBy: { fullName: 'asc' },
      });

      const allTeachers = await prisma.user.findMany({
        where: { role: 'TEACHER', school },
        select: { id: true, fullName: true, username: true, subjects: true, classes: true, avatarUrl: true },
      });

      const teachers = allTeachers.filter((t) => {
        try {
          const cl = JSON.parse(t.classes || '[]');
          return cl.some((c: any) => c.grade === grade && c.section === section);
        } catch { return false; }
      }).map(t => ({ id: t.id, fullName: t.fullName, username: t.username, subjects: t.subjects, avatarUrl: t.avatarUrl }));

      return res.json({ school, grade, section, students, teachers, availableClasses: classList });
    }

    return res.status(400).json({ message: 'دور غير معروف' });
  } catch (error) {
    console.error('Community error:', error);
    return res.status(500).json({ message: 'خطأ في السيرفر' });
  }
};