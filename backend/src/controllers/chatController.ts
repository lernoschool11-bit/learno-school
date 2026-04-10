import { Request, Response } from 'express';
import prisma from '../lib/prisma';

// إرسال طلب محادثة
export const sendRequest = async (req: Request, res: Response) => {
  try {
    const senderId = (req as any).user.id as string;
    const receiverId = req.body.receiverId as string;

    if (senderId === receiverId)
      return res.status(400).json({ message: 'لا يمكنك مراسلة نفسك' });

    const existing = await prisma.conversation.findFirst({
      where: {
        OR: [
          { senderId: senderId, receiverId: receiverId },
          { senderId: receiverId, receiverId: senderId },
        ],
      },
    });

    if (existing)
      return res.status(400).json({ message: 'الطلب موجود مسبقاً', conversation: existing });

    const conversation = await prisma.conversation.create({
      data: { senderId: senderId, receiverId: receiverId },
      include: {
        sender: { select: { id: true, fullName: true, username: true, avatarUrl: true } },
        receiver: { select: { id: true, fullName: true, username: true, avatarUrl: true } },
      },
    });

    res.status(201).json(conversation);
  } catch (err) {
    res.status(500).json({ message: 'خطأ في الخادم' });
  }
};

// قبول أو رفض الطلب
export const respondRequest = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id as string;
    const conversationId = req.body.conversationId as string;
    const status = req.body.status as string;

    const conversation = await prisma.conversation.findFirst({
      where: { id: conversationId, receiverId: userId, status: 'PENDING' },
    });

    if (!conversation)
      return res.status(404).json({ message: 'الطلب غير موجود' });

    const updated = await prisma.conversation.update({
      where: { id: conversationId },
      data: { status: status as any },
      include: {
        sender: { select: { id: true, fullName: true, username: true, avatarUrl: true } },
        receiver: { select: { id: true, fullName: true, username: true, avatarUrl: true } },
      },
    });

    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: 'خطأ في الخادم' });
  }
};

// جلب المحادثات المقبولة
export const getConversations = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id as string;

    const conversations = await prisma.conversation.findMany({
      where: {
        OR: [{ senderId: userId }, { receiverId: userId }],
        status: 'ACCEPTED',
      },
      include: {
        sender: { select: { id: true, fullName: true, username: true, avatarUrl: true } },
        receiver: { select: { id: true, fullName: true, username: true, avatarUrl: true } },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(conversations);
  } catch (err) {
    res.status(500).json({ message: 'خطأ في الخادم' });
  }
};

// جلب الطلبات الواردة
export const getPendingRequests = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id as string;

    const requests = await prisma.conversation.findMany({
      where: { receiverId: userId, status: 'PENDING' },
      include: {
        sender: { select: { id: true, fullName: true, username: true, avatarUrl: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(requests);
  } catch (err) {
    res.status(500).json({ message: 'خطأ في الخادم' });
  }
};

// جلب رسائل محادثة
export const getMessages = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id as string;
    const conversationId = req.params.conversationId as string;

    const conversation = await prisma.conversation.findFirst({
      where: {
        id: conversationId,
        OR: [{ senderId: userId }, { receiverId: userId }],
        status: 'ACCEPTED',
      },
    });

    if (!conversation)
      return res.status(403).json({ message: 'غير مسموح' });

    const messages = await prisma.directMessage.findMany({
      where: { conversationId: conversationId },
      include: {
        sender: { select: { id: true, fullName: true, username: true, avatarUrl: true } },
      },
      orderBy: { createdAt: 'asc' },
      take: 50,
    });

    res.json(messages);
  } catch (err) {
    res.status(500).json({ message: 'خطأ في الخادم' });
  }
};
