import prisma from '../config/prisma';
import redisClient from '../config/redis';

const MAX_DISTANCE_KM = 25;
const TOP_MATCHES = 10;

// Scoring weights
const W_DISTANCE = 0.40;
const W_RATING = 0.25;
const W_COMPLETION = 0.20;
const W_BADGE = 0.15;

const BADGE_SCORES: Record<string, number> = {
  platinum: 1.0,
  gold: 0.8,
  silver: 0.6,
  bronze: 0.4,
  trainee: 0.2,
};

// Haversine distance in km
function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

interface WorkerWithLocation {
  id: string;
  rating: number;
  completionRate: number;
  badgeLevel: string;
  lat: number;
  lng: number;
  distanceKm: number;
}

export async function matchWorkersForJob(jobId: string) {
  const job = await prisma.job.findUnique({
    where: { id: jobId },
    include: { category: true },
  });
  if (!job) throw new Error('Job not found');
  if (job.latitude == null || job.longitude == null) {
    throw new Error('Job has no location — cannot match');
  }

  // Phase 1: Find nearby, available, category-matching workers
  // Get all workers in the job's category who are available
  const candidates = await prisma.workerProfile.findMany({
    where: {
      isAvailable: true,
      categories: { some: { categoryId: job.categoryId } },
    },
    select: {
      id: true,
      rating: true,
      completionRate: true,
      badgeLevel: true,
    },
  });

  // Filter by Redis presence (online/away) and location within 25km
  const nearbyWorkers: WorkerWithLocation[] = [];

  for (const worker of candidates) {
    // Check presence — must be online or away (key exists)
    const status = await redisClient.get(`worker:status:${worker.id}`);
    if (!status) continue; // offline — key expired

    // Get live location from Redis
    const locationRaw = await redisClient.get(`worker:location:${worker.id}`);
    if (!locationRaw) continue; // no location data

    const { lat, lng } = JSON.parse(locationRaw) as { lat: number; lng: number };
    const distanceKm = haversineKm(job.latitude, job.longitude, lat, lng);

    if (distanceKm <= MAX_DISTANCE_KM) {
      nearbyWorkers.push({
        ...worker,
        lat,
        lng,
        distanceKm,
      });
    }
  }

  if (nearbyWorkers.length === 0) {
    return { jobId, matches: [] };
  }

  // Phase 2: Score each worker
  // Normalize distance — closer is better (0km = 1.0, 25km = 0.0)
  const maxDist = MAX_DISTANCE_KM;
  // Find max rating across candidates for normalization (cap at 5)
  const maxRating = 5;

  const scored = nearbyWorkers.map((w) => {
    const distScore = 1 - w.distanceKm / maxDist;
    const ratingScore = w.rating / maxRating;
    const completionScore = w.completionRate; // already 0-1
    const badgeScore = BADGE_SCORES[w.badgeLevel] ?? 0.2;

    const matchScore =
      W_DISTANCE * distScore +
      W_RATING * ratingScore +
      W_COMPLETION * completionScore +
      W_BADGE * badgeScore;

    return {
      workerId: w.id,
      distanceKm: Math.round(w.distanceKm * 100) / 100,
      matchScore: Math.round(matchScore * 1000) / 1000,
    };
  });

  // Sort by score descending, take top 10
  scored.sort((a, b) => b.matchScore - a.matchScore);
  const topMatches = scored.slice(0, TOP_MATCHES);

  // Save to JobMatch table (upsert to allow re-matching)
  const saved = await Promise.all(
    topMatches.map((m) =>
      prisma.jobMatch.upsert({
        where: { jobId_workerId: { jobId, workerId: m.workerId } },
        create: {
          jobId,
          workerId: m.workerId,
          matchScore: m.matchScore,
          distanceKm: m.distanceKm,
        },
        update: {
          matchScore: m.matchScore,
          distanceKm: m.distanceKm,
          status: 'PENDING',
        },
      })
    )
  );

  return { jobId, matches: saved };
}
