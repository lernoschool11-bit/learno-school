import { Server } from 'socket.io';
import { Server as HttpServer } from 'http';
import jwt from 'jsonwebtoken';
import prisma from './lib/prisma';
import { createNotification } from './controllers/notificationController';

const JWT_SECRET = process.env.JWT_SECRET || 'fallback-secret-for-dev';

export const initSocket = (httpServer: HttpServer) => {
  const io = new Server(httpServer, {
    cors: {
      origin: true,
      methods: ['GET', 'POST'],
      credentials: true,
    },
  });

  // التحقق من التوكن
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      if (!token) return next(new Error('Authentication required'));

      const decoded = jwt.verify(token, JWT_SECRET) as any;
      const user = await prisma.user.findUnique({
        where: { id: decoded.id },
        select: { id: true, fullName: true, username: true, role: true },
      });

      if (!user) return next(new Error('User not found'));
      (socket as any).user = user;
      next();
    } catch (err) {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    const user = (socket as any).user;
    console.log(`✅ ${user.fullName} connected`);

    // ════════ الغرف العامة (موجود مسبقاً) ════════

    socket.on('join_room', async ({ roomId }) => {
      // Authorization Check
      const [roomSchool, roomGrade, roomSection] = roomId.split('_');
      const currentUser = await prisma.user.findUnique({ where: { id: user.id } });

      if (!currentUser || currentUser.school !== roomSchool) {
        console.warn(`❌ Unauthorized access attempt by ${user.fullName} to room: ${roomId}`);
        return socket.emit('error', 'غير مصرح لك بدخول هذه الغرفة');
      }

      if (currentUser.role === 'STUDENT') {
        if (currentUser.grade !== roomGrade || currentUser.section !== roomSection) {
          return socket.emit('error', 'يمكنك فقط دخول غرفة صفك');
        }
      } else if (currentUser.role === 'TEACHER') {
        const classes = JSON.parse(currentUser.classes || '[]');
        const canJoin = classes.some((c: any) => c.grade === roomGrade && c.section === roomSection);
        if (!canJoin) return socket.emit('error', 'لا تدرس هذا الصف');
      } else if (currentUser.role === 'PRINCIPAL') {
        // Principals can join any room in their school
        console.log(`👁️ Principal monitoring enabled for room: ${roomId}`);
      }

      socket.join(roomId);
      console.log(`✅ ${user.fullName} joined room: ${roomId}`);

      try {
        const messages = await prisma.message.findMany({
          where: { roomId },
          orderBy: { createdAt: 'asc' },
          take: 50,
          include: {
            user: {
              select: { fullName: true, username: true, role: true },
            },
          },
        });

        const history = messages.map((m: any) => ({
          id: m.id,
          roomId: m.roomId,
          content: m.content,
          type: m.type,
          userId: m.userId,
          fullName: m.user.fullName,
          username: m.user.username,
          role: m.user.role,
          time: `${m.createdAt.getHours()}:${m.createdAt.getMinutes().toString().padStart(2, '0')}`,
        }));

        socket.emit('room_history', history);
      } catch (err) {
        console.error('Error fetching messages:', err);
        socket.emit('room_history', []);
      }
    });

    socket.on('send_message', async ({ roomId, content, type = 'text' }) => {
      if (!content || !roomId) return;

      try {
        const saved = await prisma.message.create({
          data: {
            roomId,
            content,
            type,
            userId: user.id,
          },
          include: {
            user: {
              select: { fullName: true, username: true, role: true },
            },
          },
        });

        const message = {
          id: saved.id,
          roomId: saved.roomId,
          content: saved.content,
          type: saved.type,
          userId: saved.userId,
          fullName: saved.user.fullName,
          username: saved.user.username,
          role: saved.user.role,
          time: `${saved.createdAt.getHours()}:${saved.createdAt.getMinutes().toString().padStart(2, '0')}`,
        };

        io.to(roomId).emit('new_message', message);
      } catch (err) {
        console.error('Error saving message:', err);
      }
    });

    // ════════ الرسائل الخاصة (جديد) ════════
    // المستخدم ينضم لغرفته الخاصة
    socket.on('join_direct', () => {
      socket.join(`dm_${user.id}`);
      console.log(`${user.fullName} joined DM room`);
    });

    // إرسال رسالة خاصة
    socket.on('send_direct_message', async ({ conversationId, content }) => {
      if (!content || !conversationId) return;

      try {
        const conversation = await prisma.conversation.findFirst({
          where: {
            id: conversationId,
            status: 'ACCEPTED',
            OR: [{ senderId: user.id }, { receiverId: user.id }],
          },
        });

        if (!conversation) return;

        const saved = await prisma.directMessage.create({
          data: { conversationId, senderId: user.id, content },
          include: {
            sender: { select: { id: true, fullName: true, username: true, avatarUrl: true } },
          },
        });

        const message = {
          id: saved.id,
          conversationId: saved.conversationId,
          content: saved.content,
          senderId: saved.senderId,
          sender: saved.sender,
          createdAt: saved.createdAt,
        };

        const receiverId =
          conversation.senderId === user.id
            ? conversation.receiverId
            : conversation.senderId;

        // إرسال الإشعار
        await createNotification({
          userId: receiverId,
          actorId: user.id,
          type: 'MESSAGE',
          message: `أرسل لك ${user.fullName} رسالة جديدة`,
        });

        io.to(`dm_${user.id}`).emit('new_direct_message', message);
        io.to(`dm_${receiverId}`).emit('new_direct_message', message);
      } catch (err) {
        console.error('Error saving direct message:', err);
      }
    });

    // إشعار بطلب محادثة جديد
    socket.on('notify_dm_request', ({ receiverId }) => {
      io.to(`dm_${receiverId}`).emit('new_dm_request');
    });

    socket.on('disconnect', () => {
      console.log(`❌ ${user.fullName} disconnected`);
    });
  });

  return io;
};
