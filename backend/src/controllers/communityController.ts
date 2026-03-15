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

    if (currentUser.role === 'STUDENT') {
      const { school, grade, section } = currentUser;

      if (!grade || !section) {
        return res.status(400).json({ message: 'لم يتم تحديد الصف والشعبة' });
      }

      const students = await prisma.user.findMany({
        where: { role: 'STUDENT', school, grade, section, id: { not: userId } },
        select: {
          id: true,
          fullName: true,
          username: true,
          avatarUrl: true,
        },
        orderBy: { fullName: 'asc' },
      });

      const allTeachers = await prisma.user.findMany({
        where: { role: 'TEACHER', school },
        select: {
          id: true,
          fullName: true,
          username: true,
          subjects: true,
          classes: true,
          avatarUrl: true,
        },
      });

      const teachers = allTeachers.filter((teacher) => {
        if (!teacher.classes) return false;
        try {
          const classList = JSON.parse(teacher.classes) as Array<{ grade: string; section: string }>;
          return classList.some((cls) => cls.grade === grade && cls.section === section);
        } catch { return false; }
      }).map((t) => ({
        id: t.id,
        fullName: t.fullName,
        username: t.username,
        subjects: t.subjects,
        avatarUrl: t.avatarUrl,
      }));

      return res.json({ school, grade, section, students, teachers });

    } else if (currentUser.role === 'TEACHER') {
      let classList: Array<{ grade: string; section: string }> = [];
      try {
        classList = JSON.parse(currentUser.classes || '[]');
      } catch { classList = []; }

      if (classList.length === 0) {
        return res.status(400).json({ message: 'لم يتم تحديد أي صف' });
      }

      const firstClass = classList[0];
      const { grade, section } = firstClass;
      const school = currentUser.school;

      const students = await prisma.user.findMany({
        where: { role: 'STUDENT', school, grade, section },
        select: {
          id: true,
          fullName: true,
          username: true,
          avatarUrl: true,
        },
        orderBy: { fullName: 'asc' },
      });

      const allTeachers = await prisma.user.findMany({
        where: { role: 'TEACHER', school },
        select: {
          id: true,
          fullName: true,
          username: true,
          subjects: true,
          classes: true,
          avatarUrl: true,
        },
      });

      const teachers = allTeachers.filter((teacher) => {
        if (!teacher.classes) return false;
        try {
          const cl = JSON.parse(teacher.classes) as Array<{ grade: string; section: string }>;
          return cl.some((c) => c.grade === grade && c.section === section);
        } catch { return false; }
      }).map((t) => ({
        id: t.id,
        fullName: t.fullName,
        username: t.username,
        subjects: t.subjects,
        avatarUrl: t.avatarUrl,
      }));

      return res.json({
        school,
        grade,
        section,
        students,
        teachers,
        availableClasses: classList,
      });
    }

    return res.status(400).json({ message: 'دور غير معروف' });
  } catch (error) {
    console.error('Community error:', error);
    return res.status(500).json({ message: 'خطأ في السيرفر' });
  }
};