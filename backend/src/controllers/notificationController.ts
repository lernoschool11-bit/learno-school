import { Response } from 'express';
import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth';

// ==================== GET NOTIFICATIONS ====================
export const getNotifications = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.id;

    const notifications = await prisma.notification.findMany({
      where: { userId },
      include: {
        actor: {
          select: {
            id: true,
            fullName: true,
            username: true,
            role: true,
          }
        }
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    return res.status(200).json(notifications);
  } catch (error) {
    console.error('getNotifications error:', error);
    return res.status(500).json({ error: 'Failed to get notifications' });
  }
};

// ==================== GET UNREAD COUNT ====================
export const getUnreadCount = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.id;

    const count = await prisma.notification.count({
      where: { userId, isRead: false },
    });

    return res.status(200).json({ count });
  } catch (error) {
    console.error('getUnreadCount error:', error);
    return res.status(500).json({ error: 'Failed to get unread count' });
  }
};

// ==================== MARK ALL AS READ ====================
export const markAllAsRead = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.id;

    await prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });

    return res.status(200).json({ message: 'All notifications marked as read' });
  } catch (error) {
    console.error('markAllAsRead error:', error);
    return res.status(500).json({ error: 'Failed to mark notifications as read' });
  }
};

// ==================== MARK ONE AS READ ====================
export const markAsRead = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const notificationId = String(req.params.id);

    await prisma.notification.updateMany({
      where: { id: notificationId, userId },
      data: { isRead: true },
    });

    return res.status(200).json({ message: 'Notification marked as read' });
  } catch (error) {
    console.error('markAsRead error:', error);
    return res.status(500).json({ error: 'Failed to mark notification as read' });
  }
};

// ==================== CREATE NOTIFICATION (internal) ====================
export const createNotification = async ({
  userId,
  actorId,
  type,
  message,
  postId,
}: {
  userId: string;
  actorId: string;
  type: string;
  message: string;
  postId?: string;
}) => {
  try {
    // ما نرسل إشعار لنفسك
    if (userId === actorId) return;

    await prisma.notification.create({
      data: {
        userId,
        actorId,
        type,
        message,
        postId: postId || null,
      },
    });
  } catch (error) {
    console.error('createNotification error:', error);
  }
};