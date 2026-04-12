import { Request, Response } from "express";
import prisma from "../lib/prisma";
import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";
import { AuthRequest } from "../middleware/auth";

// ==================== تطبيع اسم المدرسة ====================
const normalizeSchoolName = (name: string): string => {
  return name
    .trim()
    .toLowerCase()
    .replace(/مدرسة\s*/g, '')
    .replace(/مدرسه\s*/g, '')
    .replace(/school\s*/g, '')
    .replace(/\s*للبنين/g, '')
    .replace(/\s*للبنات/g, '')
    .replace(/\s*للذكور/g, '')
    .replace(/\s*للاناث/g, '')
    .replace(/\s*للإناث/g, '')
    .replace(/\s+/g, ' ')
    .trim();
};

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

    const normalizedSchool = school ? normalizeSchoolName(school) : null;

    const user = await prisma.user.create({
      data: {
        nationalId: finalNationalId,
        fullName,
        username,
        dob,
        email,
        password: hashedPassword,
        role: role || 'STUDENT',
        school: normalizedSchool,
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
        _count: { select: { posts: true, followers: true, following: true } }
      }
    });

    if (!user) return res.status(404).json({ message: "المستخدم غير موجود" });

    return res.json({ 
      ...user, 
      postsCount: user._count.posts,
      followersCount: user._count.followers,
      followingCount: user._count.following,
    });
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

// ==================== GET USER BY ID ====================
export const getUserById = async (req: AuthRequest, res: Response) => {
  try {
    const id = req.params.id as string;

    const user = await prisma.user.findUnique({
      where: { id },
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
        createdAt: true,
        _count: { select: { posts: true, followers: true, following: true } },
        posts: {
          orderBy: { createdAt: 'desc' },
          include: {
            author: { select: { id: true, fullName: true, username: true, avatarUrl: true, role: true } },
            _count: { select: { likes: true, comments: true } }
          }
        },
        followers: {
          take: 50,
          include: {
            follower: {
              select: { id: true, fullName: true, username: true, avatarUrl: true, role: true }
            }
          }
        },
        following: {
          take: 50,
          include: {
            following: {
              select: { id: true, fullName: true, username: true, avatarUrl: true, role: true }
            }
          }
        }
      }
    });

    if (!user) return res.status(404).json({ message: "المستخدم غير موجود" });

    // التحقق هل المستخدم العالمي يتابع هذا المستخدم
    const isFollowing = await prisma.follow.findFirst({
      where: {
        followerId: req.user!.id,
        followingId: id,
      },
    });

    const flattenedPosts = (user.posts as any[]).map(post => ({
      ...post,
      likesCount: post._count.likes,
      commentsCount: post._count.comments,
      isLiked: false, // سنتركها false حالياً أو يمكن فحصها إذا لزم الأمر
    }));

    // تحسين لفحص الإعجاب لكل منشور
    const userLikes = await prisma.like.findMany({
      where: {
        userId: req.user!.id,
        postId: { in: (user.posts as any[]).map(p => p.id) }
      }
    });

    const postsWithLiked = flattenedPosts.map(post => ({
      ...post,
      isLiked: userLikes.some(like => like.postId === post.id)
    }));

    return res.json({ 
      ...user, 
      postsCount: user._count.posts,
      followersCount: user._count.followers,
      followingCount: user._count.following,
      isFollowing: !!isFollowing,
      followers: user.followers.map(f => f.follower),
      following: user.following.map(f => f.following),
      posts: postsWithLiked,
    });
  } catch (error) {
    console.error("getUserById error:", error);
    return res.status(500).json({ message: "خطأ في السيرفر" });
  }
};

// ==================== TOGGLE FOLLOW ====================
export const toggleFollow = async (req: Request, res: Response) => {
  try {
    const followerId = (req as any).user.id as string;
    const followingId = req.params.userId as string;

    if (followerId === followingId) {
      return res.status(400).json({ message: 'لا يمكنك متابعة نفسك' });
    }

    const existing = await prisma.follow.findFirst({
      where: {
        followerId: followerId,
        followingId: followingId,
      },
    });

    if (existing) {
      await prisma.follow.delete({ where: { id: existing.id } });
    } else {
      await prisma.follow.create({
        data: {
          followerId: followerId,
          followingId: followingId,
        },
      });

      await prisma.notification.create({
        data: {
          userId: followingId,
          actorId: followerId,
          type: 'FOLLOW',
          message: 'بدأ بمتابعتك',
        },
      });
    }

    const followersCount = await prisma.follow.count({
      where: { followingId: followingId },
    });

    res.json({
      isFollowing: !existing,
      followersCount,
    });
  } catch (err) {
    console.error('toggleFollow error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};
