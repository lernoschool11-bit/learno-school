import { Request, Response } from "express";
import prisma from "../lib/prisma";
import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";
import { AuthRequest } from "../middleware/auth";

export const register = async (req: Request, res: Response) => {
  try {
    const {
      fullName, dob, username, email, password,
      role, school, grade, section, subjects, classes
    } = req.body;

    const nationalId = req.body.national_id || req.body.nationalId || null;

    if (!password || !fullName || !username || !email) {
      return res.status(400).json({ message: "جميع الحقول المطلوبة يجب ملؤها" });
    }

    const whereConditions: any[] = [{ username }, { email }];
    if (nationalId) whereConditions.push({ nationalId });

    const existingUser = await prisma.user.findFirst({
      where: { OR: whereConditions },
    });

    if (existingUser) {
      if (nationalId && existingUser.nationalId === nationalId)
        return res.status(400).json({ message: "الرقم الوطني مستخدم مسبقاً" });
      if (existingUser.username === username)
        return res.status(400).json({ message: "اسم المستخدم مستخدم مسبقاً" });
      if (existingUser.email === email)
        return res.status(400).json({ message: "البريد الإلكتروني مستخدم مسبقاً" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const subjectsArray = Array.isArray(subjects)
      ? subjects
      : subjects ? Object.values(subjects) : [];
    const classesArray = Array.isArray(classes)
      ? classes
      : classes ? Object.values(classes) : [];

    const finalNationalId = nationalId || `AUTO_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    const user = await prisma.user.create({
      data: {
        nationalId: finalNationalId,
        fullName,
        username,
        dob,
        email,
        password: hashedPassword,
        role: role || 'STUDENT',
        school: school || null,
        grade: role === 'STUDENT' ? grade : null,
        section: role === 'STUDENT' ? section : null,
        subjects: { set: role === 'TEACHER' ? subjectsArray : [] },
        classes: role === 'TEACHER' ? JSON.stringify(classesArray) : null,
      },
    });

    return res.status(201).json({
      message: "تم إنشاء الحساب بنجاح",
      user: {
        id: user.id,
        fullName: user.fullName,
        username: user.username,
        role: user.role,
      },
    });
  } catch (error) {
    console.error("Register error:", error);
    return res.status(500).json({ message: "خطأ في السيرفر" });
  }
};

export const login = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "البريد الإلكتروني وكلمة المرور مطلوبان" });
    }

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) return res.status(401).json({ error: "البريد الإلكتروني غير موجود" });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ error: "كلمة المرور غير صحيحة" });

    const token = jwt.sign(
      { id: user.id, nationalId: user.nationalId, role: user.role },
      process.env.JWT_SECRET || 'fallback_secret',
      { expiresIn: '30d' }
    );

    return res.json({
      message: "تم تسجيل الدخول بنجاح",
      token,
      user: { name: user.fullName, role: user.role },
    });
  } catch (error) {
    console.error("Login error:", error);
    return res.status(500).json({ message: "خطأ في السيرفر" });
  }
};

export const getMe = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        fullName: true,
        username: true,
        email: true,
        role: true,
        school: true,
        grade: true,
        section: true,
        subjects: true,
        avatarUrl: true,
        dob: true,
        createdAt: true,
        _count: { select: { posts: true } }
      }
    });

    if (!user) return res.status(404).json({ message: "المستخدم غير موجود" });

    return res.json({ ...user, postsCount: user._count.posts });
  } catch (error) {
    console.error("GetMe error:", error);
    return res.status(500).json({ message: "خطأ في السيرفر" });
  }
};

export const searchUsers = async (req: AuthRequest, res: Response) => {
  try {
    const query = (req.query.q as string || '').trim();

    if (!query) return res.json([]);

    const users = await prisma.user.findMany({
      where: {
        OR: [
          { username: { contains: query, mode: 'insensitive' } },
          { fullName: { contains: query, mode: 'insensitive' } },
        ],
        id: { not: req.user?.id },
      },
      select: {
        id: true,
        fullName: true,
        username: true,
        role: true,
        school: true,
        grade: true,
        section: true,
        subjects: true,
        avatarUrl: true,
        _count: { select: { posts: true } },
      },
      take: 20,
    });

    return res.json(users);
  } catch (error) {
    console.error("Search users error:", error);
    return res.status(500).json({ message: "خطأ في السيرفر" });
  }
};

// ==================== UPDATE PROFILE ====================
export const updateProfile = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const { fullName, username, email, avatarUrl } = req.body;

    if (username) {
      const existing = await prisma.user.findFirst({
        where: { username, id: { not: userId } }
      });
      if (existing) return res.status(400).json({ message: "اسم المستخدم مستخدم مسبقاً" });
    }

    if (email) {
      const existing = await prisma.user.findFirst({
        where: { email, id: { not: userId } }
      });
      if (existing) return res.status(400).json({ message: "البريد الإلكتروني مستخدم مسبقاً" });
    }

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        ...(fullName && { fullName }),
        ...(username && { username }),
        ...(email && { email }),
        ...(avatarUrl && { avatarUrl }),
      },
      select: {
        id: true,
        fullName: true,
        username: true,
        email: true,
        role: true,
        school: true,
        grade: true,
        section: true,
        subjects: true,
        avatarUrl: true,
      }
    });

    return res.json({ message: "تم تحديث البيانات بنجاح", user });
  } catch (error) {
    console.error("updateProfile error:", error);
    return res.status(500).json({ message: "خطأ في السيرفر" });
  }
};

// ==================== CHANGE PASSWORD ====================
export const changePassword = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: "كلمة المرور الحالية والجديدة مطلوبتان" });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ message: "كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل" });
    }

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ message: "المستخدم غير موجود" });

    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) return res.status(401).json({ message: "كلمة المرور الحالية غير صحيحة" });

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await prisma.user.update({
      where: { id: userId },
      data: { password: hashedPassword },
    });

    return res.json({ message: "تم تغيير كلمة المرور بنجاح" });
  } catch (error) {
    console.error("changePassword error:", error);
    return res.status(500).json({ message: "خطأ في السيرفر" });
  }
};