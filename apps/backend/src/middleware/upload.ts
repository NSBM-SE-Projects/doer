import multer from 'multer';
import { AppError } from '../utils/AppError';

const ALLOWED_MIMES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'application/pdf',
];

const storage = multer.memoryStorage();

export const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (_req, file, cb) => {
    if (ALLOWED_MIMES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(AppError.badRequest('Only JPEG, PNG, WebP and PDF files are allowed'));
    }
  },
});
