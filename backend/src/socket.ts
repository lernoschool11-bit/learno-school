import { Server } from 'socket.io';
import { Server as HttpServer } from 'http';
import jwt from 'jsonwebtoken';
import prisma from './lib/prisma';

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

    // انضم لغرفة
    socket.on('join_room', async ({ roomId }) => {
      socket.join(roomId);
      console.log(`${user.fullName} joined room: ${roomId}`);

      // جيب آخر 50 رسالة من قاعدة البيانات
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

        const history = messages.map((m) => ({
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

    // استقبل رسالة جديدة
    socket.on('send_message', async ({ roomId, content, type = 'text' }) => {
      if (!content || !roomId) return;

      try {
        // احفظ الرسالة في قاعدة البيانات
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

        // أرسل الرسالة لكل أعضاء الغرفة
        io.to(roomId).emit('new_message', message);
      } catch (err) {
        console.error('Error saving message:', err);
      }
    });

    socket.on('disconnect', () => {
      console.log(`❌ ${user.fullName} disconnected`);
    });
  });

  return io;
};
