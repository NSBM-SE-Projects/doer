import { BadgeLevel } from '@prisma/client';
import prisma from '../utils/prisma';

const computeBadgeLevel = (rating: number, totalJobs: number): BadgeLevel => {
  if (rating >= 4.8 && totalJobs >= 100) return 'PLATINUM';
  if (rating >= 4.5 && totalJobs >= 50) return 'GOLD';
  if (rating >= 4.0 && totalJobs >= 20) return 'SILVER';
  if (rating >= 3.5 && totalJobs >= 5) return 'BRONZE';
  return 'TRAINEE';
};

export const submitReview = async (data: {
  jobId: string;
  customerId: string;
  workerId: string;
  rating: number;
  comment?: string;
}) => {
  const { jobId, customerId, workerId, rating, comment } = data;

  const review = await prisma.review.create({
    data: { jobId, customerId, workerId, rating, comment },
  });

  // Recalculate worker rating
  const allReviews = await prisma.review.findMany({
    where: { workerId },
    select: { rating: true },
  });
  const avgRating = allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length;

  const workerProfile = await prisma.workerProfile.findUnique({
    where: { id: workerId },
    select: { totalJobs: true },
  });

  const newBadge = computeBadgeLevel(avgRating, workerProfile?.totalJobs || 0);

  await prisma.workerProfile.update({
    where: { id: workerId },
    data: { rating: avgRating, badgeLevel: newBadge },
  });

  return review;
};

export const getWorkerReviews = async (workerId: string) => {
  return prisma.review.findMany({
    where: { workerId },
    include: {
      customer: {
        include: { user: { select: { id: true, name: true, avatarUrl: true } } },
      },
    },
    orderBy: { createdAt: 'desc' },
  });
};
