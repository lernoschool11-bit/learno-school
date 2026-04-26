import { Response } from 'express';
import { Role } from '@prisma/client';
import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth';

// ==================== ADD GRADE (Teacher Only) ====================
export const addGrade = async (req: AuthRequest, res: Response) => {
  try {
    const teacherId = req.user!.id;
    const { schoolId, school } = req.user!;
    const { studentId, subject, title, score, maxScore } = req.body;

    // 1. تأكد إن المستخدم معلم
    if (req.user!.role !== Role.TEACHER) {
      return res.status(403).json({ error: 'Only teachers can add grades' });
    }

    // 2. التحقق من وجود الطالب في نفس المدرسة
    const student = await prisma.user.findUnique({
      where: { id: studentId }
    });

    const isSameSchool = schoolId 
        ? (student?.schoolId === schoolId || student?.school === school)
        : (student?.school === school);

    if (!student || !isSameSchool) {
      return res.status(404).json({ error: 'Student not found in your school' });
    }

    // 3. تأكد إن المعلم بدرس هاي المادة
    if (!req.user!.subjects.includes(subject)) {
      return res.status(403).json({ error: `You are not authorized to add grades for ${subject}` });
    }

    // 4. حفظ العلامة
    const grade = await prisma.grade.create({
      data: {
        studentId,
        teacherId,
        subject,
        title,
        score: parseFloat(score),
        maxScore: parseFloat(maxScore),
      },
      include: {
        student: {
          select: { fullName: true }
        }
      }
    });

    return res.status(201).json(grade);
  } catch (error) {
    console.error('addGrade error:', error);
    return res.status(500).json({ error: 'Failed to add grade' });
  }
};

// ==================== GET MY GRADES (Student Only) ====================
export const getMyGrades = async (req: AuthRequest, res: Response) => {
  try {
    const studentId = req.user!.id;

    const grades = await prisma.grade.findMany({
      where: { studentId },
      include: {
        teacher: {
          select: { fullName: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    // إضافة النسبة المئوية واسم المعلم لكل علامة كما هو مطلوب في الـ SOP
    const formattedGrades = grades.map(g => ({
      id: g.id,
      subject: g.subject,
      title: g.title,
      score: g.score,
      maxScore: g.maxScore,
      percentage: (g.score / g.maxScore) * 100,
      teacherName: g.teacher.fullName,
      createdAt: g.createdAt
    }));

    return res.status(200).json({ grades: formattedGrades });
  } catch (error) {
    console.error('getMyGrades error:', error);
    return res.status(500).json({ error: 'Failed to get your grades' });
  }
};

// ==================== GET CLASS GRADES (Teacher/Admin/Principal) ====================
export const getClassGrades = async (req: AuthRequest, res: Response) => {
  try {
    const { grade, section, subject } = req.query;
    const { schoolId, school } = req.user!;

    if (req.user!.role === Role.STUDENT) {
      return res.status(403).json({ error: 'Students cannot view class grades' });
    }

    const whereClause: any = {
      student: schoolId 
          ? { OR: [{ schoolId: schoolId }, { school: school || undefined }] }
          : { school: school! }
    };

    // Since Prisma nested relations inside `where` with `OR` can be tricky, 
    // it's better to structure it carefully.
    
    // Instead of putting OR inside student, we put student inside OR
    const studentWhereCondition = schoolId 
        ? { OR: [{ schoolId: schoolId }, { school: school || undefined }] }
        : { school: school! };

    const finalWhere: any = {
        student: {
            ...studentWhereCondition,
            ...(grade ? { grade: String(grade) } : {}),
            ...(section ? { section: String(section) } : {})
        },
        ...(subject ? { subject: String(subject) } : {})
    };

    const grades = await prisma.grade.findMany({
      where: finalWhere,
      include: {
        student: {
          select: { 
            id: true,
            fullName: true,
            grade: true,
            section: true
          }
        },
        teacher: {
          select: { fullName: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    return res.status(200).json(grades);
  } catch (error) {
    console.error('getClassGrades error:', error);
    return res.status(500).json({ error: 'Failed to get class grades' });
  }
};
