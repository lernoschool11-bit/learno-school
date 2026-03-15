import { Request, Response } from 'express';
import prisma from '../lib/prisma';
import bcrypt from 'bcrypt';
import { sendResetCode } from '../lib/emailService';

// كود مؤقت في الذاكرة: { email -> { code, expiry } }
const resetCodes: Map<string, { code: string; expiry: number; userId: string }> = new Map();

// 1️⃣ طلب إعادة تعيين كلمة المرور
export const forgotPassword = async (req: Request, res: Response) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: 'الرجاء إدخال البريد الإلكتروني' });
    }

    const user = await prisma.user.findUnique({ where: { email } });

    if (!user) {
      return res.status(404).json({ message: 'هذا البريد الإلكتروني غير مسجل' });
    }

    // توليد رمز عشوائي من 6 أرقام
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiry = Date.now() + 10 * 60 * 1000; // 10 دقائق

    resetCodes.set(email, { code, expiry, userId: user.id });

    await sendResetCode(email, code, user.fullName);

    return res.status(200).json({ message: 'تم إرسال رمز التحقق على بريدك الإلكتروني' });
  } catch (error) {
    console.error('Forgot password error:', error);
    return res.status(500).json({ message: 'خطأ في السيرفر' });
  }
};

// 2️⃣ التحقق من الرمز وتغيير كلمة المرور
export const resetPassword = async (req: Request, res: Response) => {
  try {
    const { email, code, newPassword } = req.body;

    if (!email || !code || !newPassword) {
      return res.status(400).json({ message: 'جميع الحقول مطلوبة' });
    }

    const resetData = resetCodes.get(email);

    if (!resetData) {
      return res.status(400).json({ message: 'لم يتم طلب إعادة تعيين لهذا الإيميل' });
    }

    if (Date.now() > resetData.expiry) {
      resetCodes.delete(email);
      return res.status(400).json({ message: 'انتهت صلاحية الرمز، يرجى طلب رمز جديد' });
    }

    if (resetData.code !== code) {
      return res.status(400).json({ message: 'الرمز غير صحيح' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await prisma.user.update({
      where: { id: resetData.userId },
      data: { password: hashedPassword },
    });

    resetCodes.delete(email);

    return res.status(200).json({ message: 'تم تغيير كلمة المرور بنجاح' });
  } catch (error) {
    console.error('Reset password error:', error);
    return res.status(500).json({ message: 'خطأ في السيرفر' });
  }
};
