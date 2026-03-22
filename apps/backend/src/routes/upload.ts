import { Router, Response } from 'express';
import cloudinary, { isCloudinaryConfigured } from '../config/cloudinary';
import { authenticate, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';

const router = Router();

// POST /api/upload — upload a base64 image to Cloudinary
router.post(
  '/',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    if (!isCloudinaryConfigured) {
      throw AppError.badRequest('Image upload is not configured');
    }

    const { image, folder } = req.body;
    if (!image) throw AppError.badRequest('image (base64) is required');

    const result = await cloudinary.uploader.upload(image, {
      folder: folder || 'doer',
      resource_type: 'image',
      transformation: [
        { width: 1200, crop: 'limit' },
        { quality: 'auto' },
        { fetch_format: 'auto' },
      ],
    });

    res.json({
      url: result.secure_url,
      publicId: result.public_id,
      width: result.width,
      height: result.height,
    });
  })
);

// POST /api/upload/multiple — upload multiple base64 images
router.post(
  '/multiple',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    if (!isCloudinaryConfigured) {
      throw AppError.badRequest('Image upload is not configured');
    }

    const { images, folder } = req.body;
    if (!images || !Array.isArray(images) || images.length === 0) {
      throw AppError.badRequest('images (array of base64 strings) is required');
    }

    if (images.length > 10) {
      throw AppError.badRequest('Maximum 10 images per upload');
    }

    const results = await Promise.all(
      images.map((img: string) =>
        cloudinary.uploader.upload(img, {
          folder: folder || 'doer',
          resource_type: 'image',
          transformation: [
            { width: 1200, crop: 'limit' },
            { quality: 'auto' },
            { fetch_format: 'auto' },
          ],
        })
      )
    );

    res.json({
      urls: results.map((r) => r.secure_url),
    });
  })
);

export default router;
