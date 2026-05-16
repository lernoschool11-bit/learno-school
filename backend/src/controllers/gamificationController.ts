import { Response } from 'express';
import { Role } from '@prisma/client';
import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth';
import { getIO } from '../socket';
import { createNotification } from './notificationController';

// ==================== CREATE QUEST (Teacher Only) ====================
export const createQuest = async (req: AuthRequest, res: Response) => {
  try {
    const user = req.user!;
    if (user.role !== Role.TEACHER && user.role !== Role.PRINCIPAL) {
      return res.status(403).json({ error: 'Only teachers can create quests' });
    }

    const { title, content, points } = req.body;

    if (!title || !content) {
      return res.status(400).json({ error: 'Title and content are required' });
    }

    const quest = await prisma.quest.create({
      data: {
        title,
        content,
        points: points || 50,
        authorId: user.id,
        schoolId: user.schoolId!,
      },
      include: {
        author: {
          select: { fullName: true, avatarUrl: true }
        }
      }
    });

    // Broadcast via Socket.io to the school room
    const io = getIO();
    io.to(user.schoolId!).emit('new_quest', {
      ...quest,
      message: `تحدي جديد من الأستاذ ${user.fullName}!`
    });

    return res.status(201).json(quest);
  } catch (error) {
    console.error('createQuest error:', error);
    return res.status(500).json({ error: 'Failed to create quest' });
  }
};

// ==================== SUBMIT ANSWER (Student Only) ====================
export const submitAnswer = async (req: AuthRequest, res: Response) => {
  try {
    const user = req.user!;
    const questId = req.params.questId as string;
    const { content } = req.body;

    if (!content) return res.status(400).json({ error: 'Answer content is required' });

    const quest = await prisma.quest.findUnique({
      where: { id: questId },
    });

    if (!quest || !quest.isActive) {
      return res.status(400).json({ error: 'This quest is closed or not found' });
    }

    // Check if already answered
    const existingAnswer = await prisma.questAnswer.findUnique({
      where: {
        questId_userId: { questId, userId: user.id }
      }
    });

    if (existingAnswer) {
      return res.status(400).json({ error: 'You have already submitted an answer' });
    }

    const answer = await prisma.questAnswer.create({
      data: {
        content,
        questId,
        userId: user.id
      }
    });

    return res.status(201).json(answer);
  } catch (error) {
    console.error('submitAnswer error:', error);
    return res.status(500).json({ error: 'Failed to submit answer' });
  }
};

// ==================== VALIDATE ANSWER (Teacher Only) ====================
export const validateAnswer = async (req: AuthRequest, res: Response) => {
  try {
    const user = req.user!;
    const { questId, answerId } = req.body;

    const quest = await prisma.quest.findUnique({
      where: { id: questId },
      include: { answers: true }
    });

    if (!quest || !quest.isActive) {
      return res.status(400).json({ error: 'Quest not found or already closed' });
    }

    if (quest.authorId !== user.id && user.role !== Role.PRINCIPAL) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    const winnerAnswer = await prisma.questAnswer.findUnique({
      where: { id: answerId },
      include: { user: true }
    });

    if (!winnerAnswer || winnerAnswer.questId !== questId) {
      return res.status(404).json({ error: 'Answer not found' });
    }

    // DB TRANSACTION: Close Quest + Award Points + Update Rank
    const result = await prisma.$transaction(async (tx) => {
      // 1. Close Quest
      const updatedQuest = await tx.quest.update({
        where: { id: questId },
        data: { isActive: false, winnerId: winnerAnswer.userId }
      });

      // 2. Mark Answer as Correct
      await tx.questAnswer.update({
        where: { id: answerId },
        data: { isCorrect: true }
      });

      // 3. Award Points to Student
      const newPoints = winnerAnswer.user.points + quest.points;
      
      // Calculate Rank (Simple Logic)
      let newRank = winnerAnswer.user.rank;
      if (newPoints >= 1000) newRank = "خبير تعليمي";
      else if (newPoints >= 500) newRank = "مستشار ذهبي";
      else if (newPoints >= 200) newRank = "طالب متميز";

      const updatedStudent = await tx.user.update({
        where: { id: winnerAnswer.userId },
        data: { 
          points: newPoints,
          rank: newRank
        }
      });

      return { updatedQuest, updatedStudent };
    });

    // Broadcast the "Pulse Effect" to the school room
    const io = getIO();
    io.to(quest.schoolId).emit('quest_resolved', {
      questId,
      winnerName: winnerAnswer.user.fullName,
      points: quest.points,
      newRank: result.updatedStudent.rank
    });

    // Notify the winner
    await createNotification({
      userId: winnerAnswer.userId,
      actorId: user.id,
      type: 'QUEST_WIN',
      message: `مبروك! إجابتك في تحدي "${quest.title}" كانت صحيحة. حصلت على ${quest.points} نقطة!`
    });

    return res.status(200).json(result);
  } catch (error) {
    console.error('validateAnswer error:', error);
    return res.status(500).json({ error: 'Failed to validate answer' });
  }
};

// ==================== GET ACTIVE QUESTS ====================
export const getQuests = async (req: AuthRequest, res: Response) => {
  try {
    const quests = await prisma.quest.findMany({
      where: { 
        schoolId: req.user!.schoolId!,
        isActive: true 
      },
      include: {
        author: {
          select: { fullName: true, avatarUrl: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    });
    return res.json(quests);
  } catch (error) {
    return res.status(500).json({ error: 'Failed to get quests' });
  }
};

// ==================== GET LEADERBOARD ====================
export const getLeaderboard = async (req: AuthRequest, res: Response) => {
  try {
    const topStudents = await prisma.user.findMany({
      where: { 
        schoolId: req.user!.schoolId!,
        role: Role.STUDENT
      },
      select: {
        id: true,
        fullName: true,
        username: true,
        points: true,
        rank: true,
        avatarUrl: true
      },
      orderBy: { points: 'desc' },
      take: 20
    });
    return res.json(topStudents);
  } catch (error) {
    return res.status(500).json({ error: 'Failed to get leaderboard' });
  }
};

// ==================== GET QUEST ANSWERS (Teacher Only) ====================
export const getQuestAnswers = async (req: AuthRequest, res: Response) => {
  try {
    const questId = req.params.questId as string;
    const user = req.user!;

    const quest = await prisma.quest.findUnique({
      where: { id: questId }
    });

    if (!quest) return res.status(404).json({ error: 'Quest not found' });

    // Students can only see their own answer (if any)
    if (user.role === Role.STUDENT) {
      const myAnswer = await prisma.questAnswer.findMany({
        where: { questId, userId: user.id },
        include: { user: { select: { fullName: true, avatarUrl: true } } }
      });
      return res.json(myAnswer);
    }

    // Teachers/Principals see all answers
    const answers = await prisma.questAnswer.findMany({
      where: { questId },
      include: { user: { select: { fullName: true, avatarUrl: true, id: true } } },
      orderBy: { createdAt: 'asc' }
    });

    return res.json(answers);
  } catch (error) {
    return res.status(500).json({ error: 'Failed to get answers' });
  }
};
