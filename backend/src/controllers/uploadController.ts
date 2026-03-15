import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { uploadToCloudinary } from '../lib/uploadService';

export const uploadFile = async (req: AuthRequest, res: Response) => {
  try {
    const file = req.file;
    const userRole = req.user?.role;

    if (!file) {
      return res.status(400).json({ message: 'لم يتم رفع أي ملف' });
    }

    const isVideo = file.mimetype.startsWith('video');

    // الفيديو للمعلمين فقط
    if (isVideo && userRole !== 'TEACHER') {
      return res.status(403).json({ message: 'رفع الفيديو متاح للمعلمين فقط' });
    }

    const folder = isVideo ? 'learno/videos' : 'learno/images';
    const url = await uploadToCloudinary(file.buffer, file.mimetype, folder);

    return res.json({
      url,
      type: isVideo ? 'VIDEO' : 'IMAGE',
      message: 'تم رفع الملف بنجاح',
    });
  } catch (error) {
    console.error('Upload error:', error);
    return res.status(500).json({ message: 'فشل رفع الملف' });
  }
};
