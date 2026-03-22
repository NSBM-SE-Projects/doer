import { BadgeLevel, VerificationStatus } from '@prisma/client';
import prisma from '../config/prisma';
import { createNotification } from '../routes/notifications';

interface WorkerForBadge {
  id: string;
  userId: string;
  verificationStatus: VerificationStatus;
  backgroundCheckUrl: string | null;
  rating: number;
  totalJobs: number;
  badgeLevel: BadgeLevel;
  qualificationDocs: { id: string }[];
}

export function calculateBadgeLevel(worker: WorkerForBadge): BadgeLevel {
  const isVerified = worker.verificationStatus === 'VERIFIED';
  const hasQualifications = worker.qualificationDocs.length > 0;
  const hasBackgroundCheck = !!worker.backgroundCheckUrl;

  // Platinum: Full verification + background check + 50+ jobs + 4.5+ rating
  if (
    isVerified &&
    hasQualifications &&
    hasBackgroundCheck &&
    worker.totalJobs >= 50 &&
    worker.rating >= 4.5
  ) {
    return BadgeLevel.PLATINUM;
  }

  // Gold: Full verification + 10+ jobs + 4.0+ rating
  if (
    isVerified &&
    hasQualifications &&
    worker.totalJobs >= 10 &&
    worker.rating >= 4.0
  ) {
    return BadgeLevel.GOLD;
  }

  // Silver: NIC + qualifications verified
  if (isVerified && hasQualifications) {
    return BadgeLevel.SILVER;
  }

  // Bronze: NIC verified
  if (isVerified) {
    return BadgeLevel.BRONZE;
  }

  return BadgeLevel.TRAINEE;
}

const BADGE_LABELS: Record<BadgeLevel, string> = {
  TRAINEE: 'Trainee',
  BRONZE: 'Bronze',
  SILVER: 'Silver',
  GOLD: 'Gold',
  PLATINUM: 'Platinum',
};

export async function recalculateAndNotifyBadge(workerId: string): Promise<BadgeLevel> {
  const worker = await prisma.workerProfile.findUnique({
    where: { id: workerId },
    include: { qualificationDocs: { select: { id: true } } },
  });

  if (!worker) return BadgeLevel.TRAINEE;

  const newLevel = calculateBadgeLevel(worker);

  if (newLevel !== worker.badgeLevel) {
    await prisma.workerProfile.update({
      where: { id: workerId },
      data: { badgeLevel: newLevel },
    });

    await createNotification(
      worker.userId,
      'Badge Level Up!',
      `Congratulations! You've reached ${BADGE_LABELS[newLevel]} level.`
    );
  }

  return newLevel;
}
