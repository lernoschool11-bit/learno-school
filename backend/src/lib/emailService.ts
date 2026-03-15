import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL,
    pass: process.env.EMAIL_PASSWORD,
  },
});

export const sendResetCode = async (toEmail: string, code: string, name: string) => {
  const mailOptions = {
    from: `"Learno" <${process.env.EMAIL}>`,
    to: toEmail,
    subject: 'رمز إعادة تعيين كلمة المرور - Learno',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 500px; margin: auto; padding: 24px; border: 1px solid #eee; border-radius: 12px;">
        <h2 style="color: #0A2342; text-align: center;">Learno</h2>
        <p style="font-size: 16px;">مرحباً <strong>${name}</strong>،</p>
        <p>تلقينا طلباً لإعادة تعيين كلمة المرور الخاصة بك.</p>
        <p>رمز التحقق الخاص بك هو:</p>
        <div style="text-align: center; margin: 24px 0;">
          <span style="font-size: 36px; font-weight: bold; color: #0A2342; letter-spacing: 8px;">${code}</span>
        </div>
        <p style="color: #888;">هذا الرمز صالح لمدة <strong>10 دقائق</strong> فقط.</p>
        <p style="color: #888;">إذا لم تطلب إعادة تعيين كلمة المرور، تجاهل هذا الإيميل.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;">
        <p style="text-align: center; color: #aaa; font-size: 12px;">Learno - منصة تعليمية</p>
      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
};
