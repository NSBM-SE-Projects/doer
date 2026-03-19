import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import * as reviewService from '../services/review.service';
import prisma from '../utils/prisma';
import { success, error } from '../utils/response';

export const submitReview = async (req: AuthRequest, res: Response) => {
  try {
    const customerProfile = await prisma.customerProfile.findUnique({
      where: { userId: req.user!.dbUserId },
    });
    if (!customerProfile) return error(res, 'Customer profile not found', 404);

    const { jobId, workerId, rating, comment } = req.body;
    if (!jobId || !workerId || !rating) {
      return error(res, 'jobId, workerId, and rating are required');
    }
    if (Number(rating) < 1 || Number(rating) > 5) {
      return error(res, 'Rating must be between 1 and 5');
    }

    const review = await reviewService.submitReview({
      jobId,
      customerId: customerProfile.id,
      workerId,
      rating: Number(rating),
      comment,
    });
    return success(res, review, 201);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to submit review';
    return error(res, message, 500);
  }
};

export const getWorkerReviews = async (req: AuthRequest, res: Response) => {
  try {
    const reviews = await reviewService.getWorkerReviews(req.params.id);
    return success(res, reviews);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to get reviews';
    return error(res, message, 500);
  }
};
