import prisma from '../config/prisma';
import redisClient from '../config/redis';

// ═══════════════════════════════════════════════════════════════════════════════
// DOER — Intelligent Job Duration & Completion Time Estimation Engine
// ═══════════════════════════════════════════════════════════════════════════════
//
// Three-layer self-improving algorithm:
//   Layer 1: Rule-Based     — works with zero data (day one)
//   Layer 2: Historical Avg — kicks in at 10+ data points
//   Layer 3: Weighted Regression — kicks in at 30+ data points
//
// Factors: category, description keywords, complexity, urgency, worker experience,
//          worker rating, badge level, time-of-day, historical variance
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Types ──────────────────────────────────────────────────────────────────

type ComplexityLevel = 'SIMPLE' | 'MODERATE' | 'COMPLEX' | 'EXPERT';
type UrgencyLevel = 'LOW' | 'NORMAL' | 'URGENT' | 'EMERGENCY';
type EstimationMethod = 'RULE_BASED' | 'HISTORICAL_AVG' | 'WEIGHTED_REGRESSION';
type EstimationTier = 'PERFECT' | 'GREAT' | 'GOOD' | 'FAIR';

interface EstimationResult {
  estimatedMinutes: number;
  confidenceScore: number;
  delayRiskPercent: number;
  complexity: ComplexityLevel;
  tier: EstimationTier;
  method: EstimationMethod;
  dataPointsUsed: number;
  estimatedStartAt: Date | null;
  estimatedEndAt: Date | null;
  factors: FactorBreakdown;
}

interface FactorBreakdown {
  baseDuration: number;
  categoryName: string;
  complexityMultiplier: number;
  keywordMultiplier: number;
  urgencyMultiplier: number;
  workerSpeedMultiplier: number;
  timeOfDayMultiplier: number;
  keywordsDetected: string[];
  complexityReason: string;
  historicalAvg: number | null;
  historicalMedian: number | null;
  historicalStdDev: number | null;
  adjustments: string[];
}

interface WorkerContext {
  totalJobs: number;
  rating: number;
  badgeLevel: string;
  completionRate: number;
}

interface EstimationOptions {
  workerId?: string;
  complexity?: ComplexityLevel;
  scheduledStartAt?: Date;
}

// ─── Constants ──────────────────────────────────────────────────────────────

const MIN_HISTORICAL_SAMPLES = 10;
const REGRESSION_THRESHOLD = 30;
const MIN_DURATION = 15;
const MAX_DURATION = 720; // 12 hours
const CACHE_TTL = 1800; // 30 minutes
const BASELINE_CACHE_TTL = 3600; // 1 hour

// Default durations per category (minutes) — Sri Lankan home services
const DEFAULT_CATEGORY_DURATIONS: Record<string, number> = {
  'Plumbing': 90,
  'Electrical': 75,
  'Cleaning': 120,
  'Painting': 240,
  'Carpentry': 180,
  'Appliance Repair': 60,
  'Gardening': 90,
  'Pest Control': 45,
  'AC Service': 60,
  'Moving': 180,
  'Masonry': 300,
  'Roofing': 360,
  'Tiling': 240,
  'Welding': 120,
  'Glass Work': 90,
};
const FALLBACK_DURATION = 90;

// Complexity multipliers
const COMPLEXITY_MULTIPLIERS: Record<ComplexityLevel, number> = {
  SIMPLE: 0.5,
  MODERATE: 1.0,
  COMPLEX: 1.8,
  EXPERT: 2.5,
};

// Urgency speed factors — emergency workers work faster but with higher delay risk
const URGENCY_SPEED_FACTORS: Record<UrgencyLevel, number> = {
  LOW: 1.1,
  NORMAL: 1.0,
  URGENT: 0.9,
  EMERGENCY: 0.85,
};

// Urgency delay risk base multipliers
const URGENCY_DELAY_MULTIPLIERS: Record<UrgencyLevel, number> = {
  LOW: 0.7,
  NORMAL: 1.0,
  URGENT: 1.4,
  EMERGENCY: 1.8,
};

// Keywords that indicate job complexity/duration modifiers
const KEYWORD_DURATION_MODIFIERS: Record<string, number> = {
  // Duration increasers
  'install': 1.3, 'installation': 1.3, 'installing': 1.3,
  'full': 1.5, 'complete': 1.5, 'whole': 1.4, 'entire': 1.5,
  'deep': 1.4, 'thorough': 1.3, 'detailed': 1.3,
  'multiple': 1.6, 'several': 1.5, 'many': 1.5,
  'rewire': 2.0, 'rewiring': 2.0,
  'renovation': 2.5, 'renovate': 2.5, 'remodel': 2.5,
  'replace': 1.2, 'replacement': 1.2, 'replacing': 1.2,
  'construct': 2.0, 'construction': 2.0, 'build': 1.8, 'building': 1.8,
  'overhaul': 1.8, 'upgrade': 1.4, 'extend': 1.5, 'extension': 1.5,
  'floor': 1.3, 'floors': 1.6,
  'rooms': 1.4, 'house': 1.5, 'apartment': 1.3,
  'bathroom': 1.2, 'kitchen': 1.2,
  'commercial': 1.6, 'office': 1.3,
  'outdoor': 1.2, 'garden': 1.2,
  'heavy': 1.3, 'large': 1.3, 'big': 1.2,

  // Duration reducers
  'repair': 0.8, 'fix': 0.8, 'fixing': 0.8,
  'small': 0.6, 'minor': 0.6, 'tiny': 0.5,
  'quick': 0.5, 'fast': 0.5, 'simple': 0.6,
  'single': 0.7, 'one': 0.8,
  'leak': 0.7, 'leaking': 0.7, 'drip': 0.5, 'dripping': 0.5,
  'check': 0.5, 'inspect': 0.5, 'inspection': 0.5,
  'adjust': 0.5, 'tighten': 0.4,
  'clean': 0.6, 'unclog': 0.6,
  'touch-up': 0.4, 'touchup': 0.4, 'patch': 0.5,
  'emergency': 0.7,
};

// Keywords that indicate complexity level
const COMPLEXITY_INDICATORS: Record<string, ComplexityLevel> = {
  // EXPERT
  'rewire': 'EXPERT', 'rewiring': 'EXPERT',
  'renovation': 'EXPERT', 'renovate': 'EXPERT', 'remodel': 'EXPERT',
  'construction': 'EXPERT', 'construct': 'EXPERT',
  'overhaul': 'EXPERT',

  // COMPLEX
  'install': 'COMPLEX', 'installation': 'COMPLEX',
  'replace': 'COMPLEX', 'replacement': 'COMPLEX',
  'full': 'COMPLEX', 'complete': 'COMPLEX', 'entire': 'COMPLEX',
  'multiple': 'COMPLEX', 'several': 'COMPLEX',
  'build': 'COMPLEX', 'extend': 'COMPLEX',
  'upgrade': 'COMPLEX',

  // SIMPLE
  'fix': 'SIMPLE', 'repair': 'SIMPLE',
  'small': 'SIMPLE', 'minor': 'SIMPLE', 'quick': 'SIMPLE',
  'leak': 'SIMPLE', 'drip': 'SIMPLE',
  'check': 'SIMPLE', 'inspect': 'SIMPLE',
  'adjust': 'SIMPLE', 'tighten': 'SIMPLE',
  'clean': 'SIMPLE', 'unclog': 'SIMPLE',
  'touch-up': 'SIMPLE', 'patch': 'SIMPLE',
};

// Time-of-day multiplier (some jobs take longer in certain conditions)
function getTimeOfDayMultiplier(hour: number): number {
  if (hour >= 6 && hour < 10) return 0.95;  // morning — fresh workers, efficient
  if (hour >= 10 && hour < 14) return 1.0;  // midday — standard
  if (hour >= 14 && hour < 17) return 1.05; // afternoon — slight fatigue
  if (hour >= 17 && hour < 20) return 1.1;  // evening — reduced daylight
  return 1.15;                               // night — harder conditions
}

// Stop words to filter out from keyword extraction
const STOP_WORDS = new Set([
  'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
  'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'shall',
  'should', 'may', 'might', 'must', 'can', 'could', 'i', 'me', 'my',
  'we', 'our', 'you', 'your', 'he', 'she', 'it', 'they', 'them',
  'this', 'that', 'these', 'those', 'of', 'in', 'on', 'at', 'to',
  'for', 'with', 'from', 'by', 'as', 'into', 'about', 'up', 'out',
  'and', 'but', 'or', 'not', 'no', 'so', 'if', 'then', 'than',
  'very', 'just', 'also', 'there', 'here', 'need', 'needs', 'needed',
  'want', 'wants', 'wanted', 'please', 'help', 'get', 'got',
]);

// ─── Core Functions ─────────────────────────────────────────────────────────

/**
 * Extract meaningful keywords from a job description.
 */
function extractKeywords(description: string): string[] {
  const words = description
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, ' ')
    .split(/\s+/)
    .filter((w) => w.length > 2 && !STOP_WORDS.has(w));

  return [...new Set(words)];
}

/**
 * Auto-detect job complexity from description keywords.
 * Uses a voting system — counts indicators for each level and picks the winner.
 */
function detectComplexity(keywords: string[]): { level: ComplexityLevel; reason: string } {
  const votes: Record<ComplexityLevel, number> = {
    SIMPLE: 0,
    MODERATE: 0,
    COMPLEX: 0,
    EXPERT: 0,
  };

  const reasons: string[] = [];

  for (const keyword of keywords) {
    const level = COMPLEXITY_INDICATORS[keyword];
    if (level) {
      votes[level]++;
      reasons.push(`"${keyword}" → ${level}`);
    }
  }

  // If no indicators found, default to MODERATE
  const totalVotes = Object.values(votes).reduce((a, b) => a + b, 0);
  if (totalVotes === 0) {
    return { level: 'MODERATE', reason: 'No complexity indicators found — defaulting to MODERATE' };
  }

  // Pick the highest complexity level with votes (bias toward higher complexity for safety)
  // If EXPERT has any votes, it wins. Then COMPLEX, etc.
  let winner: ComplexityLevel = 'MODERATE';
  if (votes.EXPERT > 0) winner = 'EXPERT';
  else if (votes.COMPLEX > 0 && votes.COMPLEX >= votes.SIMPLE) winner = 'COMPLEX';
  else if (votes.SIMPLE > votes.COMPLEX) winner = 'SIMPLE';

  return {
    level: winner,
    reason: `Detected from keywords: ${reasons.join(', ')}`,
  };
}

/**
 * Calculate the keyword-based duration multiplier.
 * Combines all matching keyword modifiers using geometric mean for stability.
 */
function calculateKeywordMultiplier(keywords: string[]): { multiplier: number; matched: string[] } {
  const matchedKeywords: string[] = [];
  const modifiers: number[] = [];

  for (const keyword of keywords) {
    const modifier = KEYWORD_DURATION_MODIFIERS[keyword];
    if (modifier !== undefined) {
      matchedKeywords.push(keyword);
      modifiers.push(modifier);
    }
  }

  if (modifiers.length === 0) {
    return { multiplier: 1.0, matched: [] };
  }

  // Geometric mean — prevents extreme outliers when many keywords match
  const product = modifiers.reduce((acc, m) => acc * m, 1);
  const geometricMean = Math.pow(product, 1 / modifiers.length);

  // Clamp between 0.3 and 3.0
  const clamped = Math.max(0.3, Math.min(3.0, geometricMean));

  return { multiplier: Math.round(clamped * 100) / 100, matched: matchedKeywords };
}

/**
 * Calculate worker speed factor based on experience and rating.
 * Experienced, high-rated workers complete jobs faster.
 */
function getWorkerSpeedFactor(worker: WorkerContext | null): number {
  if (!worker) return 1.0; // No worker context — neutral

  const { totalJobs, rating, badgeLevel } = worker;

  // Base speed from experience
  let speedFactor: number;
  if (totalJobs >= 100 && rating >= 4.5) speedFactor = 0.75;
  else if (totalJobs >= 50 && rating >= 4.0) speedFactor = 0.82;
  else if (totalJobs >= 20 && rating >= 3.5) speedFactor = 0.90;
  else if (totalJobs >= 10) speedFactor = 0.95;
  else if (totalJobs >= 5) speedFactor = 1.0;
  else speedFactor = 1.15; // New workers take longer

  // Badge level bonus
  const badgeBonuses: Record<string, number> = {
    PLATINUM: -0.05,
    GOLD: -0.03,
    SILVER: 0,
    BRONZE: 0.02,
    TRAINEE: 0.05,
  };
  speedFactor += badgeBonuses[badgeLevel] ?? 0;

  // Completion rate penalty — unreliable workers may need rework
  if (worker.completionRate < 0.7) speedFactor += 0.1;
  else if (worker.completionRate < 0.85) speedFactor += 0.05;

  return Math.max(0.6, Math.min(1.5, speedFactor));
}

/**
 * Calculate delay risk percentage (0-100).
 */
function calculateDelayRisk(
  complexity: ComplexityLevel,
  urgency: UrgencyLevel,
  worker: WorkerContext | null,
  historicalStdDev: number | null,
  historicalAvg: number | null,
): number {
  // Base risk by complexity
  const complexityBaseRisk: Record<ComplexityLevel, number> = {
    SIMPLE: 8,
    MODERATE: 18,
    COMPLEX: 32,
    EXPERT: 48,
  };
  let risk = complexityBaseRisk[complexity];

  // Urgency multiplier
  risk *= URGENCY_DELAY_MULTIPLIERS[urgency];

  // Worker experience factor
  if (worker) {
    if (worker.totalJobs >= 100 && worker.rating >= 4.5) risk *= 0.6;
    else if (worker.totalJobs >= 50 && worker.rating >= 4.0) risk *= 0.75;
    else if (worker.totalJobs >= 20) risk *= 0.85;
    else if (worker.totalJobs >= 5) risk *= 1.0;
    else risk *= 1.4; // New workers = higher delay risk

    // Low completion rate = higher delay risk
    if (worker.completionRate < 0.7) risk *= 1.3;
    else if (worker.completionRate < 0.85) risk *= 1.15;
  } else {
    risk *= 1.1; // No worker context = slightly higher risk
  }

  // Historical variance factor
  if (historicalStdDev != null && historicalAvg != null && historicalAvg > 0) {
    const coefficientOfVariation = historicalStdDev / historicalAvg;
    if (coefficientOfVariation > 0.5) risk *= 1.3;      // highly variable category
    else if (coefficientOfVariation > 0.3) risk *= 1.15; // moderately variable
    else risk *= 0.9;                                     // consistent category
  }

  // Time of day factor
  const hour = new Date().getHours();
  if (hour >= 17 || hour < 6) risk *= 1.15; // evening/night = higher delay risk

  return Math.round(Math.max(0, Math.min(100, risk)));
}

/**
 * Determine estimation tier from confidence score.
 */
function getTier(confidence: number): EstimationTier {
  if (confidence >= 0.85) return 'PERFECT';
  if (confidence >= 0.70) return 'GREAT';
  if (confidence >= 0.50) return 'GOOD';
  return 'FAIR';
}

/**
 * Get category duration baseline from DB or cache.
 */
async function getCategoryBaseline(categoryId: string): Promise<{
  defaultMinutes: number;
  avgMinutes: number | null;
  medianMinutes: number | null;
  stdDevMinutes: number | null;
  p90Minutes: number | null;
  sampleCount: number;
  complexityMultipliers: Record<ComplexityLevel, number> | null;
  keywordModifiers: Record<string, number> | null;
} | null> {
  // Check Redis cache first
  const cacheKey = `baseline:category:${categoryId}`;
  try {
    const cached = await redisClient.get(cacheKey);
    if (cached) return JSON.parse(cached);
  } catch (_) { /* Redis might not be connected */ }

  const baseline = await prisma.categoryDurationBaseline.findUnique({
    where: { categoryId },
  });

  if (!baseline) return null;

  const result = {
    defaultMinutes: baseline.defaultMinutes,
    avgMinutes: baseline.avgMinutes,
    medianMinutes: baseline.medianMinutes,
    stdDevMinutes: baseline.stdDevMinutes,
    p90Minutes: baseline.p90Minutes,
    sampleCount: baseline.sampleCount,
    complexityMultipliers: baseline.complexityMultipliers
      ? JSON.parse(baseline.complexityMultipliers)
      : null,
    keywordModifiers: baseline.keywordModifiers
      ? JSON.parse(baseline.keywordModifiers)
      : null,
  };

  // Cache it
  try {
    await redisClient.set(cacheKey, JSON.stringify(result), { EX: BASELINE_CACHE_TTL });
  } catch (_) { /* non-critical */ }

  return result;
}

/**
 * Get worker profile context for estimation.
 */
async function getWorkerContext(workerId: string): Promise<WorkerContext | null> {
  const worker = await prisma.workerProfile.findUnique({
    where: { id: workerId },
    select: { totalJobs: true, rating: true, badgeLevel: true, completionRate: true },
  });

  if (!worker) return null;

  return {
    totalJobs: worker.totalJobs,
    rating: worker.rating,
    badgeLevel: worker.badgeLevel,
    completionRate: worker.completionRate,
  };
}

// ─── Layer 1: Rule-Based Estimation ─────────────────────────────────────────

function ruleBasedEstimate(
  categoryName: string,
  complexity: ComplexityLevel,
  urgency: UrgencyLevel,
  keywordMultiplier: number,
  workerSpeedFactor: number,
  timeOfDayMultiplier: number,
): number {
  const baseDuration = DEFAULT_CATEGORY_DURATIONS[categoryName] ?? FALLBACK_DURATION;
  const complexityMult = COMPLEXITY_MULTIPLIERS[complexity];
  const urgencyMult = URGENCY_SPEED_FACTORS[urgency];

  let estimated = baseDuration * complexityMult * keywordMultiplier * urgencyMult * workerSpeedFactor * timeOfDayMultiplier;

  return Math.round(Math.max(MIN_DURATION, Math.min(MAX_DURATION, estimated)));
}

// ─── Layer 2: Historical Average Estimation ─────────────────────────────────

function historicalAvgEstimate(
  avgMinutes: number,
  complexity: ComplexityLevel,
  urgency: UrgencyLevel,
  workerSpeedFactor: number,
  timeOfDayMultiplier: number,
  baselineComplexityMultipliers: Record<ComplexityLevel, number> | null,
): number {
  // Use learned complexity multipliers if available, otherwise defaults
  const complexityMult = baselineComplexityMultipliers?.[complexity] ?? COMPLEXITY_MULTIPLIERS[complexity];
  const urgencyMult = URGENCY_SPEED_FACTORS[urgency];

  // Historical average already captures the "normal" baseline, so we apply
  // relative adjustments for this specific job's complexity/urgency/worker
  let estimated = avgMinutes * (complexityMult / COMPLEXITY_MULTIPLIERS.MODERATE) * urgencyMult * workerSpeedFactor * timeOfDayMultiplier;

  return Math.round(Math.max(MIN_DURATION, Math.min(MAX_DURATION, estimated)));
}

// ─── Layer 3: Weighted Regression Estimation ────────────────────────────────

async function weightedRegressionEstimate(
  categoryId: string,
  complexity: ComplexityLevel,
  urgency: UrgencyLevel,
  keywords: string[],
  worker: WorkerContext | null,
  timeOfDayMultiplier: number,
): Promise<number> {
  // Fetch recent logs for this category, giving more weight to recent ones
  const logs = await prisma.jobDurationLog.findMany({
    where: { categoryId },
    orderBy: { completedAt: 'desc' },
    take: 200, // Use up to 200 most recent records
  });

  if (logs.length < REGRESSION_THRESHOLD) {
    // Shouldn't reach here, but fallback
    return FALLBACK_DURATION;
  }

  // Weight by recency — newer records matter more
  const now = Date.now();
  const maxAge = 365 * 24 * 60 * 60 * 1000; // 1 year

  let weightedSum = 0;
  let weightTotal = 0;

  for (let i = 0; i < logs.length; i++) {
    const log = logs[i];
    const age = now - log.completedAt.getTime();
    const recencyWeight = Math.max(0.1, 1 - age / maxAge);

    // Similarity weight — match complexity and urgency
    let similarityWeight = 1.0;
    if (log.complexity === complexity) similarityWeight += 0.5;
    if (log.urgency === urgency) similarityWeight += 0.3;

    // Keyword overlap weight
    const logKeywords = new Set(log.descriptionKeywords);
    const overlap = keywords.filter((k) => logKeywords.has(k)).length;
    similarityWeight += overlap * 0.1;

    // Worker similarity weight
    if (worker && log.workerTotalJobs > 0) {
      const expDiff = Math.abs(worker.totalJobs - log.workerTotalJobs);
      if (expDiff < 20) similarityWeight += 0.3;
      else if (expDiff < 50) similarityWeight += 0.15;
    }

    // Synthetic data gets lower weight when we have enough real data
    const syntheticPenalty = log.isSynthetic ? 0.5 : 1.0;

    const totalWeight = recencyWeight * similarityWeight * syntheticPenalty;
    weightedSum += log.actualMinutes * totalWeight;
    weightTotal += totalWeight;
  }

  let estimated = weightTotal > 0 ? weightedSum / weightTotal : FALLBACK_DURATION;

  // Apply worker-specific adjustment
  const workerMult = getWorkerSpeedFactor(worker);
  estimated *= workerMult;

  // Apply time-of-day adjustment
  estimated *= timeOfDayMultiplier;

  return Math.round(Math.max(MIN_DURATION, Math.min(MAX_DURATION, estimated)));
}

// ─── Main Estimation Function ───────────────────────────────────────────────

/**
 * Estimate job duration for a given job.
 * This is the main entry point of the estimation engine.
 */
export async function estimateJobDuration(
  jobId: string,
  options: EstimationOptions = {},
): Promise<EstimationResult> {
  // 1. Load job data
  const job = await prisma.job.findUnique({
    where: { id: jobId },
    include: { category: true },
  });
  if (!job) throw new Error('Job not found');

  // 2. Extract keywords from description
  const keywords = extractKeywords(job.description);

  // 3. Determine complexity
  let complexity: ComplexityLevel;
  let complexityReason: string;
  if (options.complexity) {
    complexity = options.complexity;
    complexityReason = 'Manually specified by user';
  } else {
    const detected = detectComplexity(keywords);
    complexity = detected.level;
    complexityReason = detected.reason;
  }

  // 4. Get keyword multiplier
  const { multiplier: keywordMultiplier, matched: matchedKeywords } = calculateKeywordMultiplier(keywords);

  // 5. Get worker context
  const workerId = options.workerId || job.workerId;
  const workerCtx = workerId ? await getWorkerContext(workerId) : null;
  const workerSpeed = getWorkerSpeedFactor(workerCtx);

  // 6. Get category baseline
  const baseline = await getCategoryBaseline(job.categoryId);

  // 7. Time-of-day factor
  const startTime = options.scheduledStartAt || job.scheduledAt || new Date();
  const todMultiplier = getTimeOfDayMultiplier(startTime.getHours());

  // 8. Determine which estimation method to use
  const urgency = job.urgency as UrgencyLevel;
  const sampleCount = baseline?.sampleCount ?? 0;
  let method: EstimationMethod;
  let estimatedMinutes: number;
  let confidenceScore: number;

  if (sampleCount >= REGRESSION_THRESHOLD && baseline) {
    // Layer 3: Weighted Regression
    method = 'WEIGHTED_REGRESSION';
    estimatedMinutes = await weightedRegressionEstimate(
      job.categoryId, complexity, urgency, keywords, workerCtx, todMultiplier,
    );

    // Confidence based on sample count and variance
    const baseConfidence = 0.75;
    const sampleBonus = Math.min(0.2, (sampleCount - REGRESSION_THRESHOLD) / 500);
    const varianceAdjust = baseline.stdDevMinutes && baseline.avgMinutes
      ? Math.max(-0.15, -0.3 * (baseline.stdDevMinutes / baseline.avgMinutes))
      : 0;
    confidenceScore = Math.min(0.95, baseConfidence + sampleBonus + varianceAdjust);

  } else if (sampleCount >= MIN_HISTORICAL_SAMPLES && baseline?.avgMinutes) {
    // Layer 2: Historical Average
    method = 'HISTORICAL_AVG';
    estimatedMinutes = historicalAvgEstimate(
      baseline.avgMinutes, complexity, urgency, workerSpeed, todMultiplier,
      baseline.complexityMultipliers as Record<ComplexityLevel, number> | null,
    );

    const baseConfidence = 0.6;
    const sampleBonus = Math.min(0.15, (sampleCount - MIN_HISTORICAL_SAMPLES) / 200);
    confidenceScore = Math.min(0.80, baseConfidence + sampleBonus);

  } else {
    // Layer 1: Rule-Based
    method = 'RULE_BASED';
    estimatedMinutes = ruleBasedEstimate(
      job.category.name, complexity, urgency, keywordMultiplier, workerSpeed, todMultiplier,
    );

    confidenceScore = sampleCount > 0
      ? Math.min(0.55, 0.40 + sampleCount * 0.015)
      : 0.40;
  }

  // 9. Calculate delay risk
  const delayRiskPercent = calculateDelayRisk(
    complexity, urgency, workerCtx,
    baseline?.stdDevMinutes ?? null,
    baseline?.avgMinutes ?? null,
  );

  // 10. Compute ETA
  const estimatedStartAt = options.scheduledStartAt || job.scheduledAt || null;
  const estimatedEndAt = estimatedStartAt
    ? new Date(estimatedStartAt.getTime() + estimatedMinutes * 60 * 1000)
    : null;

  // 11. Determine tier
  const tier = getTier(confidenceScore);

  // 12. Build factor breakdown
  const baseDuration = DEFAULT_CATEGORY_DURATIONS[job.category.name] ?? FALLBACK_DURATION;
  const adjustments: string[] = [];
  if (workerCtx) {
    adjustments.push(`Worker speed: ${workerSpeed < 1 ? 'faster' : workerSpeed > 1 ? 'slower' : 'average'} (×${workerSpeed.toFixed(2)})`);
    adjustments.push(`Worker: ${workerCtx.totalJobs} jobs, ${workerCtx.rating}★, ${workerCtx.badgeLevel}`);
  }
  if (todMultiplier !== 1.0) {
    adjustments.push(`Time-of-day: ×${todMultiplier.toFixed(2)}`);
  }
  if (sampleCount > 0) {
    adjustments.push(`Based on ${sampleCount} historical data points`);
  }

  const factors: FactorBreakdown = {
    baseDuration,
    categoryName: job.category.name,
    complexityMultiplier: COMPLEXITY_MULTIPLIERS[complexity],
    keywordMultiplier,
    urgencyMultiplier: URGENCY_SPEED_FACTORS[urgency],
    workerSpeedMultiplier: workerSpeed,
    timeOfDayMultiplier: todMultiplier,
    keywordsDetected: matchedKeywords,
    complexityReason,
    historicalAvg: baseline?.avgMinutes ?? null,
    historicalMedian: baseline?.medianMinutes ?? null,
    historicalStdDev: baseline?.stdDevMinutes ?? null,
    adjustments,
  };

  // 13. Save to database (upsert)
  await prisma.jobDurationEstimate.upsert({
    where: { jobId },
    create: {
      jobId,
      estimatedMinutes,
      confidenceScore: Math.round(confidenceScore * 100) / 100,
      delayRiskPercent,
      estimatedStartAt,
      estimatedEndAt,
      complexity,
      tier,
      method,
      dataPointsUsed: sampleCount,
      factors: JSON.stringify(factors),
    },
    update: {
      estimatedMinutes,
      confidenceScore: Math.round(confidenceScore * 100) / 100,
      delayRiskPercent,
      estimatedStartAt,
      estimatedEndAt,
      complexity,
      tier,
      method,
      dataPointsUsed: sampleCount,
      factors: JSON.stringify(factors),
    },
  });

  // 14. Cache the result
  const result: EstimationResult = {
    estimatedMinutes,
    confidenceScore: Math.round(confidenceScore * 100) / 100,
    delayRiskPercent,
    complexity,
    tier,
    method,
    dataPointsUsed: sampleCount,
    estimatedStartAt,
    estimatedEndAt,
    factors,
  };

  try {
    await redisClient.set(`estimate:job:${jobId}`, JSON.stringify(result), { EX: CACHE_TTL });
  } catch (_) { /* non-critical */ }

  return result;
}

// ─── Compare Estimates for Multiple Workers ─────────────────────────────────

/**
 * Generate side-by-side estimates for multiple workers on the same job.
 */
export async function compareWorkerEstimates(
  jobId: string,
  workerIds: string[],
): Promise<{ workerId: string; estimate: EstimationResult }[]> {
  const results: { workerId: string; estimate: EstimationResult }[] = [];

  for (const workerId of workerIds.slice(0, 5)) { // Max 5 comparisons
    const estimate = await estimateJobDuration(jobId, { workerId });
    results.push({ workerId, estimate });
  }

  // Sort by estimated minutes ascending (fastest first)
  results.sort((a, b) => a.estimate.estimatedMinutes - b.estimate.estimatedMinutes);

  return results;
}

// ─── Record Actual Duration (Learning Pipeline) ─────────────────────────────

/**
 * Called when a job is completed. Records the actual duration and
 * triggers baseline recalculation for the category.
 */
export async function recordActualDuration(jobId: string): Promise<void> {
  const job = await prisma.job.findUnique({
    where: { id: jobId },
    include: {
      category: true,
      worker: true,
      durationEstimate: true,
    },
  });

  if (!job || !job.completedAt) return;

  // Calculate actual duration: from IN_PROGRESS start to completedAt
  // We use updatedAt as proxy for when status changed to IN_PROGRESS
  // A better approach would be to store startedAt, but we work with what we have
  const startTime = job.scheduledAt || job.updatedAt;
  const actualMinutes = Math.round(
    (job.completedAt.getTime() - startTime.getTime()) / (60 * 1000)
  );

  if (actualMinutes <= 0 || actualMinutes > MAX_DURATION * 2) return; // Invalid duration

  // Extract keywords
  const keywords = extractKeywords(job.description);
  const { level: complexity } = detectComplexity(keywords);

  // Get worker context at time of completion
  const workerProfile = job.worker;

  // Record the log
  await prisma.jobDurationLog.upsert({
    where: { jobId },
    create: {
      jobId,
      actualMinutes,
      estimatedMinutes: job.durationEstimate?.estimatedMinutes ?? null,
      complexity,
      urgency: job.urgency,
      descriptionKeywords: keywords,
      workerTotalJobs: workerProfile?.totalJobs ?? 0,
      workerRating: workerProfile?.rating ?? 0,
      workerBadgeLevel: workerProfile?.badgeLevel ?? 'TRAINEE',
      isSynthetic: false,
      completedAt: job.completedAt,
      categoryId: job.categoryId,
      workerId: job.workerId,
    },
    update: {
      actualMinutes,
      estimatedMinutes: job.durationEstimate?.estimatedMinutes ?? null,
    },
  });

  // Recalculate category baseline
  await updateCategoryBaseline(job.categoryId);
}

// ─── Update Category Baseline (Self-Learning) ──────────────────────────────

/**
 * Recalculates statistical baselines for a category from all duration logs.
 */
export async function updateCategoryBaseline(categoryId: string): Promise<void> {
  const category = await prisma.serviceCategory.findUnique({
    where: { id: categoryId },
  });
  if (!category) return;

  const logs = await prisma.jobDurationLog.findMany({
    where: { categoryId },
    orderBy: { completedAt: 'desc' },
  });

  if (logs.length === 0) return;

  // Calculate statistics
  const durations = logs.map((l) => l.actualMinutes);
  const sorted = [...durations].sort((a, b) => a - b);

  const sum = durations.reduce((a, b) => a + b, 0);
  const avg = sum / durations.length;
  const median = sorted.length % 2 === 0
    ? (sorted[sorted.length / 2 - 1] + sorted[sorted.length / 2]) / 2
    : sorted[Math.floor(sorted.length / 2)];

  const variance = durations.reduce((acc, d) => acc + Math.pow(d - avg, 2), 0) / durations.length;
  const stdDev = Math.sqrt(variance);

  // 90th percentile
  const p90Index = Math.ceil(0.9 * sorted.length) - 1;
  const p90 = sorted[Math.min(p90Index, sorted.length - 1)];

  // Calculate learned complexity multipliers
  const complexityGroups: Record<string, number[]> = {};
  for (const log of logs) {
    if (!complexityGroups[log.complexity]) complexityGroups[log.complexity] = [];
    complexityGroups[log.complexity].push(log.actualMinutes);
  }

  const learnedMultipliers: Record<string, number> = {};
  for (const [level, times] of Object.entries(complexityGroups)) {
    const levelAvg = times.reduce((a, b) => a + b, 0) / times.length;
    learnedMultipliers[level] = Math.round((levelAvg / avg) * 100) / 100;
  }

  // Calculate learned keyword modifiers
  const keywordDurations: Record<string, number[]> = {};
  for (const log of logs) {
    for (const keyword of log.descriptionKeywords) {
      if (!keywordDurations[keyword]) keywordDurations[keyword] = [];
      keywordDurations[keyword].push(log.actualMinutes);
    }
  }

  const learnedKeywordModifiers: Record<string, number> = {};
  for (const [keyword, times] of Object.entries(keywordDurations)) {
    if (times.length >= 5) { // Only learn from keywords with enough samples
      const kwAvg = times.reduce((a, b) => a + b, 0) / times.length;
      learnedKeywordModifiers[keyword] = Math.round((kwAvg / avg) * 100) / 100;
    }
  }

  const defaultMinutes = DEFAULT_CATEGORY_DURATIONS[category.name] ?? FALLBACK_DURATION;

  await prisma.categoryDurationBaseline.upsert({
    where: { categoryId },
    create: {
      categoryId,
      defaultMinutes,
      avgMinutes: Math.round(avg * 10) / 10,
      medianMinutes: Math.round(median * 10) / 10,
      stdDevMinutes: Math.round(stdDev * 10) / 10,
      p90Minutes: Math.round(p90 * 10) / 10,
      sampleCount: logs.length,
      complexityMultipliers: JSON.stringify(learnedMultipliers),
      keywordModifiers: JSON.stringify(learnedKeywordModifiers),
    },
    update: {
      defaultMinutes,
      avgMinutes: Math.round(avg * 10) / 10,
      medianMinutes: Math.round(median * 10) / 10,
      stdDevMinutes: Math.round(stdDev * 10) / 10,
      p90Minutes: Math.round(p90 * 10) / 10,
      sampleCount: logs.length,
      complexityMultipliers: JSON.stringify(learnedMultipliers),
      keywordModifiers: JSON.stringify(learnedKeywordModifiers),
    },
  });

  // Invalidate cache
  try {
    await redisClient.del(`baseline:category:${categoryId}`);
  } catch (_) { /* non-critical */ }
}

// ─── Estimation Accuracy Stats ──────────────────────────────────────────────

/**
 * Calculate estimation accuracy metrics across all jobs.
 */
export async function getEstimationStats(): Promise<{
  totalPredictions: number;
  totalWithActual: number;
  meanAbsoluteError: number;
  meanPercentageError: number;
  accuracyWithin20Pct: number;
  accuracyWithin10Pct: number;
  byCategory: Array<{
    categoryId: string;
    categoryName: string;
    sampleCount: number;
    avgMinutes: number;
    medianMinutes: number;
    stdDevMinutes: number;
    accuracy20Pct: number;
  }>;
  byMethod: Record<string, { count: number; avgError: number }>;
}> {
  // Get all logs that have both actual and estimated durations
  const logs = await prisma.jobDurationLog.findMany({
    where: {
      estimatedMinutes: { not: null },
    },
    include: { category: true },
  });

  const totalPredictions = await prisma.jobDurationEstimate.count();
  const totalWithActual = logs.length;

  if (totalWithActual === 0) {
    return {
      totalPredictions,
      totalWithActual: 0,
      meanAbsoluteError: 0,
      meanPercentageError: 0,
      accuracyWithin20Pct: 0,
      accuracyWithin10Pct: 0,
      byCategory: [],
      byMethod: {},
    };
  }

  // Calculate global metrics
  let totalAbsError = 0;
  let totalPctError = 0;
  let within20 = 0;
  let within10 = 0;

  const categoryStats: Record<string, {
    categoryName: string;
    durations: number[];
    errors: number[];
    within20: number;
    total: number;
  }> = {};

  for (const log of logs) {
    const absError = Math.abs(log.actualMinutes - log.estimatedMinutes!);
    const pctError = log.actualMinutes > 0 ? absError / log.actualMinutes : 0;

    totalAbsError += absError;
    totalPctError += pctError;

    if (pctError <= 0.2) within20++;
    if (pctError <= 0.1) within10++;

    // Category grouping
    if (!categoryStats[log.categoryId]) {
      categoryStats[log.categoryId] = {
        categoryName: log.category.name,
        durations: [],
        errors: [],
        within20: 0,
        total: 0,
      };
    }
    categoryStats[log.categoryId].durations.push(log.actualMinutes);
    categoryStats[log.categoryId].errors.push(pctError);
    categoryStats[log.categoryId].total++;
    if (pctError <= 0.2) categoryStats[log.categoryId].within20++;
  }

  // Build category breakdown
  const byCategory = Object.entries(categoryStats).map(([categoryId, stats]) => {
    const sorted = [...stats.durations].sort((a, b) => a - b);
    const avg = stats.durations.reduce((a, b) => a + b, 0) / stats.durations.length;
    const median = sorted.length % 2 === 0
      ? (sorted[sorted.length / 2 - 1] + sorted[sorted.length / 2]) / 2
      : sorted[Math.floor(sorted.length / 2)];
    const variance = stats.durations.reduce((acc, d) => acc + Math.pow(d - avg, 2), 0) / stats.durations.length;

    return {
      categoryId,
      categoryName: stats.categoryName,
      sampleCount: stats.total,
      avgMinutes: Math.round(avg * 10) / 10,
      medianMinutes: Math.round(median * 10) / 10,
      stdDevMinutes: Math.round(Math.sqrt(variance) * 10) / 10,
      accuracy20Pct: Math.round((stats.within20 / stats.total) * 100),
    };
  });

  return {
    totalPredictions,
    totalWithActual,
    meanAbsoluteError: Math.round((totalAbsError / totalWithActual) * 10) / 10,
    meanPercentageError: Math.round((totalPctError / totalWithActual) * 100),
    accuracyWithin20Pct: Math.round((within20 / totalWithActual) * 100),
    accuracyWithin10Pct: Math.round((within10 / totalWithActual) * 100),
    byCategory,
    byMethod: {}, // Can be extended to track per-method accuracy
  };
}

/**
 * Get the cached or stored estimate for a job.
 */
export async function getStoredEstimate(jobId: string): Promise<EstimationResult | null> {
  // Check Redis cache first
  try {
    const cached = await redisClient.get(`estimate:job:${jobId}`);
    if (cached) return JSON.parse(cached);
  } catch (_) { /* Redis might not be connected */ }

  // Fallback to database
  const estimate = await prisma.jobDurationEstimate.findUnique({
    where: { jobId },
  });

  if (!estimate) return null;

  return {
    estimatedMinutes: estimate.estimatedMinutes,
    confidenceScore: estimate.confidenceScore,
    delayRiskPercent: estimate.delayRiskPercent,
    complexity: estimate.complexity as ComplexityLevel,
    tier: estimate.tier as EstimationTier,
    method: estimate.method as EstimationMethod,
    dataPointsUsed: estimate.dataPointsUsed,
    estimatedStartAt: estimate.estimatedStartAt,
    estimatedEndAt: estimate.estimatedEndAt,
    factors: estimate.factors ? JSON.parse(estimate.factors) : null,
  };
}
