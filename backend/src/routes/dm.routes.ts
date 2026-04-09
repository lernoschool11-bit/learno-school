import { Router } from 'express';
import { requireAuth } from '../middleware/auth';
import prisma from '../lib/prisma';
import { Request, Response } from 'express';

const router = Router();

// إرسال طلب محادثة
router.post('/request/:receiverId', requireAuth, async (req: Request, res: Response) => {
  try {
    const senderId = (req as any).user.id;
    const receiverId = req.params.receiverId;

    if (senderId === receiverId) {
      return res.status(400).json({ message: 'لا يمكنك مراسلة نفسك' });
    }

    const existing = await prisma.conversation.findFirst({
      where: {
        OR: [
          { senderId, receiverId },
          { senderId: receiverId, receiverId: senderId },
        ],
      },
    });

    if (existing) return res.json(existing);

    const conversation = await prisma.conversation.create({
      data: { senderId, receiverId, status: 'PENDING' },
    });

    res.status(201).json(conversation);
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
});

// قبول أو رفض طلب المحادثة
router.put('/request/:conversationId', requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { action } = req.body; // 'ACCEPTED' or 'REJECTED'

    const conversation = await prisma.conversation.findFirst({
      where: { id: req.params.conversationId, receiverId: userId },
    });

    if (!conversation) return res.status(404).json({ message: 'الطلب غير موجود' });

    const updated = await prisma.conversation.update({
      where: { id: conversation.id },
      data: { status: action },
    });

    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
});

// جلب كل المحادثات
router.get('/', requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;

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
      orderBy: { updatedAt: 'desc' },
    });

    res.json(conversations);
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
});

// جلب الطلبات الواردة
router.get('/requests', requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;

    const requests = await prisma.conversation.findMany({
      where: { receiverId: userId, status: 'PENDING' },
      include: {
        sender: { select: { id: true, fullName: true, username: true, avatarUrl: true } },
      },
    });

    res.json(requests);
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
});

// جلب رسائل محادثة معينة
router.get('/:conversationId/messages', requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;

    const conversation = await prisma.conversation.findFirst({
      where: {
        id: req.params.conversationId,
        status: 'ACCEPTED',
        OR: [{ senderId: userId }, { receiverId: userId }],
      },
    });

    if (!conversation) return res.status(403).json({ message: 'غير مصرح' });

    const messages = await prisma.directMessage.findMany({
      where: { conversationId: req.params.conversationId },
      orderBy: { createdAt: 'asc' },
      include: {
        sender: { select: { id: true, fullName: true, username: true, avatarUrl: true } },
      },
    });

    res.json(messages);
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
});

export default router;
