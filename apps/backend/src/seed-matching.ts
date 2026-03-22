import prisma from './config/prisma';

/**
 * Seed data for testing the matching algorithm.
 * 15 workers around Colombo, 3 categories, 1 test job.
 *
 * Run: npx ts-node src/seed-matching.ts
 */

// Colombo-area coordinates with slight offsets
const COLOMBO = { lat: 6.9271, lng: 79.8612 };

const CATEGORIES = [
  { name: 'Plumbing', description: 'Pipe repairs, installations, and maintenance' },
  { name: 'Electrical', description: 'Wiring, repairs, and electrical installations' },
  { name: 'Cleaning', description: 'Home and office cleaning services' },
];

interface WorkerSeed {
  name: string;
  email: string;
  lat: number;
  lng: number;
  rating: number;
  totalJobs: number;
  completionRate: number;
  badgeLevel: string;
  verified: boolean;
  categoryIndex: number; // index into CATEGORIES
}

const WORKERS: WorkerSeed[] = [
  // Plumbing workers (category 0)
  { name: 'Kamal Perera',     email: 'kamal@test.lk',     lat: 6.9300, lng: 79.8650, rating: 4.8, totalJobs: 120, completionRate: 0.95, badgeLevel: 'PLATINUM', verified: true,  categoryIndex: 0 },
  { name: 'Nimal Silva',      email: 'nimal@test.lk',     lat: 6.9180, lng: 79.8580, rating: 4.2, totalJobs: 65,  completionRate: 0.88, badgeLevel: 'GOLD',     verified: true,  categoryIndex: 0 },
  { name: 'Sunil Fernando',   email: 'sunil@test.lk',     lat: 6.9350, lng: 79.8700, rating: 3.5, totalJobs: 30,  completionRate: 0.80, badgeLevel: 'SILVER',   verified: true,  categoryIndex: 0 },
  { name: 'Ruwan Jayasena',   email: 'ruwan@test.lk',     lat: 6.9100, lng: 79.8500, rating: 3.0, totalJobs: 8,   completionRate: 0.75, badgeLevel: 'BRONZE',   verified: true,  categoryIndex: 0 },
  { name: 'Chaminda Bandara', email: 'chaminda@test.lk',  lat: 6.9400, lng: 79.8800, rating: 0,   totalJobs: 2,   completionRate: 1.0,  badgeLevel: 'TRAINEE',  verified: false, categoryIndex: 0 },

  // Electrical workers (category 1)
  { name: 'Ashan Wijesinghe', email: 'ashan@test.lk',     lat: 6.9220, lng: 79.8550, rating: 4.9, totalJobs: 150, completionRate: 0.97, badgeLevel: 'PLATINUM', verified: true,  categoryIndex: 1 },
  { name: 'Dilshan Kumara',   email: 'dilshan@test.lk',   lat: 6.9280, lng: 79.8630, rating: 4.5, totalJobs: 55,  completionRate: 0.90, badgeLevel: 'GOLD',     verified: true,  categoryIndex: 1 },
  { name: 'Pradeep Ranatunga',email: 'pradeep@test.lk',   lat: 6.9150, lng: 79.8480, rating: 3.8, totalJobs: 25,  completionRate: 0.84, badgeLevel: 'SILVER',   verified: true,  categoryIndex: 1 },
  { name: 'Lahiru Mendis',    email: 'lahiru@test.lk',    lat: 6.9370, lng: 79.8750, rating: 2.5, totalJobs: 10,  completionRate: 0.70, badgeLevel: 'BRONZE',   verified: true,  categoryIndex: 1 },
  { name: 'Tharindu Dias',    email: 'tharindu@test.lk',  lat: 6.9450, lng: 79.8900, rating: 0,   totalJobs: 1,   completionRate: 1.0,  badgeLevel: 'TRAINEE',  verified: false, categoryIndex: 1 },

  // Cleaning workers (category 2)
  { name: 'Malini Herath',    email: 'malini@test.lk',    lat: 6.9250, lng: 79.8600, rating: 4.7, totalJobs: 110, completionRate: 0.93, badgeLevel: 'PLATINUM', verified: true,  categoryIndex: 2 },
  { name: 'Sanduni Gamage',   email: 'sanduni@test.lk',   lat: 6.9200, lng: 79.8520, rating: 4.3, totalJobs: 52,  completionRate: 0.89, badgeLevel: 'GOLD',     verified: true,  categoryIndex: 2 },
  { name: 'Kumari Rajapaksa', email: 'kumari@test.lk',    lat: 6.9330, lng: 79.8680, rating: 3.6, totalJobs: 22,  completionRate: 0.82, badgeLevel: 'SILVER',   verified: true,  categoryIndex: 2 },
  { name: 'Nimali Weerasinghe',email:'nimali@test.lk',    lat: 6.9120, lng: 79.8450, rating: 2.8, totalJobs: 6,   completionRate: 0.67, badgeLevel: 'BRONZE',   verified: false, categoryIndex: 2 },
  { name: 'Iresha Samaraweera',email:'iresha@test.lk',    lat: 6.9500, lng: 79.8950, rating: 0,   totalJobs: 0,   completionRate: 0,    badgeLevel: 'TRAINEE',  verified: false, categoryIndex: 2 },
];

async function seed() {
  console.log('Seeding matching test data...\n');

  // 1. Create categories
  const categories = [];
  for (const cat of CATEGORIES) {
    const created = await prisma.serviceCategory.upsert({
      where: { name: cat.name },
      update: {},
      create: cat,
    });
    categories.push(created);
    console.log(`  Category: ${created.name} (${created.id})`);
  }

  // 2. Create workers
  const workerProfiles = [];
  for (const w of WORKERS) {
    const user = await prisma.user.upsert({
      where: { email: w.email },
      update: {},
      create: {
        firebaseUid: `test_${w.email}`,
        email: w.email,
        name: w.name,
        role: 'WORKER',
      },
    });

    const profile = await prisma.workerProfile.upsert({
      where: { userId: user.id },
      update: {
        latitude: w.lat,
        longitude: w.lng,
        rating: w.rating,
        totalJobs: w.totalJobs,
        completionRate: w.completionRate,
        badgeLevel: w.badgeLevel,
        verificationStatus: w.verified ? 'VERIFIED' : 'PENDING',
        isAvailable: true,
      },
      create: {
        userId: user.id,
        latitude: w.lat,
        longitude: w.lng,
        rating: w.rating,
        totalJobs: w.totalJobs,
        completionRate: w.completionRate,
        badgeLevel: w.badgeLevel,
        verificationStatus: w.verified ? 'VERIFIED' : 'PENDING',
        isAvailable: true,
      },
    });

    // Link to category
    const catId = categories[w.categoryIndex].id;
    await prisma.workerCategory.upsert({
      where: { workerId_categoryId: { workerId: profile.id, categoryId: catId } },
      update: {},
      create: { workerId: profile.id, categoryId: catId },
    });

    workerProfiles.push(profile);
    console.log(`  Worker: ${w.name} [${w.badgeLevel}] — ${categories[w.categoryIndex].name}`);
  }

  // 3. Create a test customer + job (Plumbing, near Colombo Fort)
  const customer = await prisma.user.upsert({
    where: { email: 'testcustomer@test.lk' },
    update: {},
    create: {
      firebaseUid: 'test_customer_001',
      email: 'testcustomer@test.lk',
      name: 'Test Customer',
      role: 'CUSTOMER',
    },
  });

  const customerProfile = await prisma.customerProfile.upsert({
    where: { userId: customer.id },
    update: {},
    create: {
      userId: customer.id,
      address: 'Colombo Fort, Sri Lanka',
      latitude: COLOMBO.lat,
      longitude: COLOMBO.lng,
    },
  });

  const job = await prisma.job.create({
    data: {
      title: 'Fix leaking kitchen tap',
      description: 'Kitchen tap has been dripping for a week. Need a plumber ASAP.',
      urgency: 'URGENT',
      latitude: COLOMBO.lat,
      longitude: COLOMBO.lng,
      address: 'Colombo Fort, Sri Lanka',
      customerId: customerProfile.id,
      categoryId: categories[0].id, // Plumbing
    },
  });

  console.log(`\n  Test job: "${job.title}" (${job.id})`);
  console.log(`    Category: ${CATEGORIES[0].name}`);
  console.log(`    Location: ${COLOMBO.lat}, ${COLOMBO.lng}`);
  console.log(`    Status: ${job.status}`);

  console.log('\nSeed complete!');
  console.log(`  ${categories.length} categories`);
  console.log(`  ${workerProfiles.length} workers`);
  console.log(`  1 test job`);

  process.exit(0);
}

seed().catch((e) => {
  console.error('Seed failed:', e);
  process.exit(1);
});
