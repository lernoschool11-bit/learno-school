import { Response } from 'express';
import { Role, SummaryStatus } from '@prisma/client';
import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth';
import { getIO } from '../socket';
import { createNotification } from './notificationController';

// ==================== UPLOAD SUMMARY (Student) ====================
export const uploadSummary = async (req: AuthRequest, res: Response) => {
  try {
    const user = req.user!;
    const { title, description, fileUrl, fileType, subject, grade } = req.body;

    if (!title || !fileUrl || !subject || !grade) {
      return res.status(400).json({ error: 'Title, fileUrl, subject, and grade are required' });
    }

    const summary = await prisma.summary.create({
      data: {
        title,
        description,
        fileUrl,
        fileType,
        subject,
        grade,
        studentId: user.id,
        schoolId: user.schoolId!,
        status: SummaryStatus.PENDING,
      },
      include: {
        student: { select: { fullName: true } }
      }
    });

    // Notify teachers of this subject (Optional but good for real-time)
    const io = getIO();
    // We can join teachers to subject-specific rooms if we want more precision
    // For now, let's broadcast to the school room or a specific teacher channel
    io.to(user.schoolId!).emit('new_pending_summary', {
      message: `تلخيص جديد للمراجعة: ${title}`,
      subject,
      authorName: user.fullName
    });

    return res.status(201).json(summary);
  } catch (error) {
    console.error('uploadSummary error:', error);
    return res.status(500).json({ error: 'Failed to upload summary' });
  }
};

// ==================== GET APPROVED SUMMARIES (Public in School) ====================
export const getApprovedSummaries = async (req: AuthRequest, res: Response) => {
  try {
    const { subject, grade } = req.query;

    const summaries = await prisma.summary.findMany({
      where: {
        schoolId: req.user!.schoolId!,
        status: SummaryStatus.APPROVED,
        ...(subject && { subject: String(subject) }),
        ...(grade && { grade: String(grade) }),
      },
      include: {
        student: { select: { fullName: true, avatarUrl: true, rank: true } },
        approvedBy: { select: { fullName: true } }
      },
      orderBy: { createdAt: 'desc' }
    });

    return res.json(summaries);
  } catch (error) {
    return res.status(500).json({ error: 'Failed to get summaries' });
  }
};

// ==================== GET PENDING SUMMARIES (Teacher Only) ====================
export const getPendingSummaries = async (req: AuthRequest, res: Response) => {
  try {
    const user = req.user!;
    if (user.role !== Role.TEACHER && user.role !== Role.PRINCIPAL) {
      return res.status(403).json({ error: 'Only teachers can review summaries' });
    }

    // In a production app, we would filter by the teacher's actual subjects
    // Here we'll return all pending summaries for the school, 
    // or allow filtering by subject if passed in query.
    const { subject } = req.query;

    const pending = await prisma.summary.findMany({
      where: {
        schoolId: user.schoolId!,
        status: SummaryStatus.PENDING,
        ...(subject && { subject: String(subject) })
      },
      include: {
        student: { select: { fullName: true, grade: true, section: true } }
      },
      orderBy: { createdAt: 'asc' }
    });

    return res.json(pending);
  } catch (error) {
    return res.status(500).json({ error: 'Failed to get pending summaries' });
  }
};

// ==================== APPROVE SUMMARY (Teacher Only) ====================
export const approveSummary = async (req: AuthRequest, res: Response) => {
  try {
    const user = req.user!;
    const summaryId = req.body.summaryId as string;

    if (user.role !== Role.TEACHER && user.role !== Role.PRINCIPAL) {
      return res.status(403).json({ error: 'Only teachers can approve summaries' });
    }

    const summary = await prisma.summary.findUnique({
      where: { id: summaryId },
      include: { student: true }
    });

    if (!summary || summary.status !== SummaryStatus.PENDING) {
      return res.status(400).json({ error: 'Summary not found or not in pending state' });
    }

    // AWARD POINTS: Quality Points for a verified summary (e.g., 100 points)
    const QUALITY_POINTS = 100;

    const result = await prisma.$transaction(async (tx) => {
      // 1. Approve Summary
      const updatedSummary = await tx.summary.update({
        where: { id: summaryId },
        data: { 
          status: SummaryStatus.APPROVED,
          teacherId: user.id
        }
      });

      // 2. Award Points to Student
      const newPoints = summary.student.points + QUALITY_POINTS;
      
      // Update Rank Logic
      let newRank = summary.student.rank;
      if (newPoints >= 1000) newRank = "خبير تعليمي";
      else if (newPoints >= 500) newRank = "مستشار ذهبي";
      else if (newPoints >= 200) newRank = "طالب متميز";

      await tx.user.update({
        where: { id: summary.studentId },
        data: { 
          points: newPoints,
          rank: newRank
        }
      });

      return updatedSummary;
    });

    // Broadcast the "Live Vault Feed" event
    const io = getIO();
    io.to(summary.schoolId).emit('summary_approved', {
      id: result.id,
      title: result.title,
      authorName: summary.student.fullName,
      teacherName: user.fullName,
      subject: result.subject
    });

    // Notify the student
    await createNotification({
      userId: summary.studentId,
      actorId: user.id,
      type: 'SUMMARY_APPROVED',
      message: `تم اعتماد ملخصك "${result.title}" من قبل الأستاذ ${user.fullName}. حصلت على ${QUALITY_POINTS} نقطة جودة!`
    });

    return res.status(200).json(result);
  } catch (error) {
    console.error('approveSummary error:', error);
    return res.status(500).json({ error: 'Failed to approve summary' });
  }
};

// ==================== REJECT SUMMARY (Teacher Only) ====================
export const rejectSummary = async (req: AuthRequest, res: Response) => {
  try {
    const user = req.user!;
    const summaryId = req.body.summaryId as string;

    if (user.role !== Role.TEACHER && user.role !== Role.PRINCIPAL) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    await prisma.summary.update({
      where: { id: summaryId },
      data: { status: SummaryStatus.REJECTED }
    });

    return res.json({ message: 'Summary rejected' });
  } catch (error) {
    return res.status(500).json({ error: 'Failed to reject summary' });
  }
};
