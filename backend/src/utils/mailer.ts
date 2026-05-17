import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL || 'learnoschool.no.reply@gmail.com',
        pass: process.env.EMAIL_PASSWORD || 'your_app_password',
    },
});

export const sendPasswordResetEmail = async (to: string, resetToken: string) => {
    const mailOptions = {
        from: '"Learno School" <no-reply@learnoschool.com>',
        to,
        subject: 'إعادة تعيين كلمة المرور - Learno School',
        html: `
            <div dir="rtl" style="font-family: Arial, sans-serif; padding: 20px; line-height: 1.6;">
                <h2 style="color: #56877A;">طلب إعادة تعيين كلمة المرور</h2>
                <p>لقد تلقينا طلباً لإعادة تعيين كلمة المرور الخاصة بحسابك في منصة Learno.</p>
                <p>رمز التحقق الخاص بك هو:</p>
                <h1 style="background: #eee; padding: 10px; text-align: center; letter-spacing: 5px; color: #333;">${resetToken}</h1>
                <p>هذا الرمز صالح لمدة <strong>15 دقيقة</strong> فقط.</p>
                <p>إذا لم تطلب تغيير كلمة المرور، يرجى تجاهل هذه الرسالة.</p>
                <br />
                <p>مع تحيات،<br />فريق Learno School</p>
            </div>
        `,
    };

    try {
        await transporter.sendMail(mailOptions);
        console.log(`Reset email sent to ${to}`);
    } catch (error) {
        console.error('Error sending reset email:', error);
        throw new Error('فشل إرسال البريد الإلكتروني');
    }
};
