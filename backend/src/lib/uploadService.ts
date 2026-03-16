import 'dotenv/config';
import { v2 as cloudinary } from 'cloudinary';
import { Request } from 'express';
import multer from 'multer';

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'dlvxe1bjn',
  api_key: process.env.CLOUDINARY_API_KEY || '376373595363176',
  api_secret: process.env.CLOUDINARY_API_SECRET || '2UbvNvw7PgitHxlsWSm1uM3AhQA',
});

const storage = multer.memoryStorage();

export const upload = multer({
  storage,
  limits: { fileSize: 200 * 1024 * 1024 }, // 200MB
  fileFilter: (req: Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
    const allowed = [
      'image/jpeg', 'image/png', 'image/gif', 'image/webp',
      'video/mp4', 'video/quicktime', 'video/avi', 'video/mov'
    ];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('نوع الملف غير مدعوم'));
    }
  },
});

export const uploadToCloudinary = (
  buffer: Buffer,
  mimetype: string,
  folder: string = 'learno'
): Promise<string> => {
  return new Promise((resolve, reject) => {
    const resourceType = mimetype.startsWith('video') ? 'video' : 'image';

    const stream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: resourceType,
        timeout: 120000, // 2 دقيقة
        chunk_size: 6000000, // 6MB chunks
      },
      (error, result) => {
        if (error) return reject(error);
        resolve(result!.secure_url);
      }
    );

    stream.end(buffer);
  });
};

export default cloudinary;