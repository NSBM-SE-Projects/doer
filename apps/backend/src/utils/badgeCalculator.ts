import { BadgeLevel } from '@prisma/client';
import prisma from '../config/prisma';
import { createNotification } from '../routes/notifications';

interface WorkerForBadge {
  id: string;
  userId: string;
  nicVerified: boolean;
  qualificationsVerified: boolean;
  backgroundCheckVerified: boolean;
  rating: number;
  totalJobs: number;
  badgeLevel: BadgeLevel;
}

export function calculateBadgeLevel(worker: WorkerForBadge): BadgeLevel {
  // Platinum: All 3 verified + background check + 50+ jobs + 4.5+ rating
  if (
    worker.nicVerified &&
    worker.qualificationsVerified &&
    worker.backgroundCheckVerified &&
    worker.totalJobs >= 50 &&
    worker.rating >= 4.5
  ) {
    return BadgeLevel.PLATINUM;
  }

  // Gold: NIC + qualifications verified + 10+ jobs + 4.0+ rating
  if (
    worker.nicVerified &&
    worker.qualificationsVerified &&
    worker.totalJobs >= 10 &&
    worker.rating >= 4.0
  ) {
    return BadgeLevel.GOLD;
  }

  // Silver: NIC + qualifications verified
  if (worker.nicVerified && worker.qualificationsVerified) {
    return BadgeLevel.SILVER;
  }

  // Bronze: NIC verified
  if (worker.nicVerified) {
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
  });

  if (!worker) return BadgeLevel.TRAINEE;

  const newLevel = calculateBadgeLevel(worker);

  if (newLevel !== worker.badgeLevel) {
    const oldLevel = worker.badgeLevel;
    await prisma.workerProfile.update({
      where: { id: workerId },
      data: { badgeLevel: newLevel },
    });

    // Only notify on level up, not down
    const levels = [BadgeLevel.TRAINEE, BadgeLevel.BRONZE, BadgeLevel.SILVER, BadgeLevel.GOLD, BadgeLevel.PLATINUM];
    if (levels.indexOf(newLevel) > levels.indexOf(oldLevel)) {
      await createNotification(
        worker.userId,
        'Badge Level Up!',
        `Congratulations! You've reached ${BADGE_LABELS[newLevel]} level.`
      );
    }
  }

  return newLevel;
}
