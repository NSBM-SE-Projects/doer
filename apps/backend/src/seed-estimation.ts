import prisma from './config/prisma';
import type { BadgeLevel, ComplexityLevel, Urgency } from '@prisma/client';

/**
 * Seed 2000+ synthetic completed jobs for the Duration Estimation Engine.
 * Generates realistic job durations with natural variance across 10 categories.
 *
 * Run: npx ts-node src/seed-estimation.ts
 */

// ─── Configuration ──────────────────────────────────────────────────────────

const TOTAL_JOBS = 2200;
const COLOMBO = { lat: 6.9271, lng: 79.8612 };

// Sri Lankan cities with offsets for location variety
const LOCATIONS = [
  { name: 'Colombo Fort', lat: 6.9340, lng: 79.8428 },
  { name: 'Bambalapitiya', lat: 6.8936, lng: 79.8567 },
  { name: 'Dehiwala', lat: 6.8568, lng: 79.8658 },
  { name: 'Mount Lavinia', lat: 6.8381, lng: 79.8653 },
  { name: 'Nugegoda', lat: 6.8728, lng: 79.8892 },
  { name: 'Rajagiriya', lat: 6.9066, lng: 79.8958 },
  { name: 'Battaramulla', lat: 6.9000, lng: 79.9183 },
  { name: 'Malabe', lat: 6.9033, lng: 79.9553 },
  { name: 'Kaduwela', lat: 6.9306, lng: 79.9822 },
  { name: 'Moratuwa', lat: 6.7733, lng: 79.8817 },
  { name: 'Kandy', lat: 7.2906, lng: 80.6337 },
  { name: 'Galle', lat: 6.0535, lng: 80.2210 },
  { name: 'Negombo', lat: 7.2083, lng: 79.8358 },
  { name: 'Kotte', lat: 6.8914, lng: 79.9008 },
  { name: 'Panadura', lat: 6.7133, lng: 79.9042 },
];

// ─── Category Definitions ───────────────────────────────────────────────────

interface CategoryDef {
  name: string;
  description: string;
  baseDuration: number; // minutes
  jobTemplates: { title: string; description: string; complexity: string }[];
}

const CATEGORIES: CategoryDef[] = [
  {
    name: 'Plumbing',
    description: 'Pipe repairs, installations, and maintenance',
    baseDuration: 90,
    jobTemplates: [
      { title: 'Fix leaking kitchen tap', description: 'Kitchen tap has been dripping for days. Need someone to fix the leak quickly.', complexity: 'SIMPLE' },
      { title: 'Fix bathroom pipe leak', description: 'Small leak under the bathroom sink pipe. Needs quick repair.', complexity: 'SIMPLE' },
      { title: 'Unclog drain', description: 'Kitchen drain is completely blocked. Need to unclog it.', complexity: 'SIMPLE' },
      { title: 'Install new water heater', description: 'Need to install a new electric water heater in the bathroom. Complete installation with plumbing connections.', complexity: 'COMPLEX' },
      { title: 'Replace bathroom fixtures', description: 'Replace all bathroom taps, shower head, and basin. Full replacement needed.', complexity: 'COMPLEX' },
      { title: 'Install water tank', description: 'Install new overhead water tank with complete pipe connections to the house.', complexity: 'COMPLEX' },
      { title: 'Full house plumbing renovation', description: 'Complete renovation of plumbing system for entire house. Multiple bathrooms and kitchen. Rewiring all pipes.', complexity: 'EXPERT' },
      { title: 'Septic tank repair', description: 'Repair and maintain septic tank system. Heavy work required.', complexity: 'EXPERT' },
      { title: 'Tighten loose tap handle', description: 'Simple adjustment needed for loose tap handle in kitchen.', complexity: 'SIMPLE' },
      { title: 'Install washing machine outlet', description: 'Need plumbing connection for new washing machine installation.', complexity: 'MODERATE' },
    ],
  },
  {
    name: 'Electrical',
    description: 'Wiring, repairs, and electrical installations',
    baseDuration: 75,
    jobTemplates: [
      { title: 'Fix power outlet', description: 'One power outlet in the living room is not working. Quick fix needed.', complexity: 'SIMPLE' },
      { title: 'Replace light switch', description: 'Need to replace a broken light switch. Simple replacement.', complexity: 'SIMPLE' },
      { title: 'Install ceiling fan', description: 'Install a new ceiling fan in the bedroom with wiring.', complexity: 'MODERATE' },
      { title: 'Install new circuit breaker', description: 'Install additional circuit breaker for new appliances. Electrical panel upgrade.', complexity: 'COMPLEX' },
      { title: 'Full house rewiring', description: 'Complete rewiring of the entire house. Old wiring needs complete replacement. Multiple rooms and floors.', complexity: 'EXPERT' },
      { title: 'Install outdoor lighting', description: 'Install multiple outdoor garden lights with weatherproof wiring.', complexity: 'COMPLEX' },
      { title: 'Fix tripping breaker', description: 'Circuit breaker keeps tripping. Need inspection and quick repair.', complexity: 'SIMPLE' },
      { title: 'Install inverter system', description: 'Install solar inverter system with battery backup for the house.', complexity: 'EXPERT' },
      { title: 'Replace electrical panel', description: 'Full replacement of old electrical distribution panel. Heavy upgrade work.', complexity: 'EXPERT' },
      { title: 'Install smart home switches', description: 'Install smart switches in several rooms with Wi-Fi connectivity.', complexity: 'MODERATE' },
    ],
  },
  {
    name: 'Cleaning',
    description: 'Home and office cleaning services',
    baseDuration: 120,
    jobTemplates: [
      { title: 'Quick room clean', description: 'Clean one small bedroom. Quick dusting and mopping.', complexity: 'SIMPLE' },
      { title: 'Kitchen deep clean', description: 'Deep clean kitchen including appliances, cabinets, and floor. Thorough cleaning needed.', complexity: 'MODERATE' },
      { title: 'Full house cleaning', description: 'Complete house cleaning — all rooms, bathrooms, kitchen, and outdoor areas. Multiple floors.', complexity: 'COMPLEX' },
      { title: 'Office cleaning', description: 'Clean commercial office space. Multiple rooms, bathrooms, and common areas.', complexity: 'COMPLEX' },
      { title: 'Post-construction cleanup', description: 'Heavy cleaning after renovation. Remove all construction debris, dust, and clean entire house thoroughly.', complexity: 'EXPERT' },
      { title: 'Bathroom cleaning', description: 'Clean two bathrooms. Standard cleaning with tile scrubbing.', complexity: 'SIMPLE' },
      { title: 'Window cleaning', description: 'Clean all windows in the house, inside and outside. Several large windows.', complexity: 'MODERATE' },
      { title: 'Carpet deep cleaning', description: 'Deep clean multiple carpets and rugs. Remove stains and odors.', complexity: 'MODERATE' },
      { title: 'Garden cleanup', description: 'Clean up garden area. Remove fallen leaves, trim small bushes, general outdoor cleanup.', complexity: 'MODERATE' },
      { title: 'Move-out deep clean', description: 'Complete deep clean of entire apartment before moving out. Detailed and thorough. Every room.', complexity: 'EXPERT' },
    ],
  },
  {
    name: 'Painting',
    description: 'Interior and exterior painting services',
    baseDuration: 240,
    jobTemplates: [
      { title: 'Touch-up wall paint', description: 'Small touch-up painting on one wall. Minor patch and repaint.', complexity: 'SIMPLE' },
      { title: 'Paint single room', description: 'Paint one bedroom including walls and ceiling. Standard room size.', complexity: 'MODERATE' },
      { title: 'Paint living room', description: 'Paint large living room with high ceiling. Multiple coats needed.', complexity: 'MODERATE' },
      { title: 'Exterior house painting', description: 'Paint entire exterior of the house. Multiple floors, weatherproof paint needed.', complexity: 'EXPERT' },
      { title: 'Paint full apartment', description: 'Paint complete apartment — all rooms, kitchen, bathrooms. Full renovation painting.', complexity: 'COMPLEX' },
      { title: 'Paint fence', description: 'Paint garden fence. Quick outdoor painting job.', complexity: 'SIMPLE' },
      { title: 'Texture wall painting', description: 'Apply decorative texture paint on feature wall. Detailed artistic work.', complexity: 'COMPLEX' },
      { title: 'Paint office space', description: 'Paint commercial office. Several rooms and corridors. Professional finish needed.', complexity: 'COMPLEX' },
    ],
  },
  {
    name: 'Carpentry',
    description: 'Wood work, furniture repair, and installations',
    baseDuration: 180,
    jobTemplates: [
      { title: 'Fix squeaky door', description: 'Door is squeaking badly. Simple hinge adjustment needed.', complexity: 'SIMPLE' },
      { title: 'Install shelf', description: 'Install one wall shelf in the study room. Simple mounting.', complexity: 'SIMPLE' },
      { title: 'Repair wardrobe door', description: 'Wardrobe door hinge broken. Need repair and adjustment.', complexity: 'SIMPLE' },
      { title: 'Build custom bookshelf', description: 'Build and install a custom bookshelf for the living room. Multiple shelves.', complexity: 'COMPLEX' },
      { title: 'Kitchen cabinet installation', description: 'Install new kitchen cabinets. Multiple upper and lower cabinets. Complete installation.', complexity: 'COMPLEX' },
      { title: 'Full house wood work renovation', description: 'Complete renovation of all wooden doors, window frames, and built-in furniture. Entire house.', complexity: 'EXPERT' },
      { title: 'Build wooden deck', description: 'Construct outdoor wooden deck in garden area. Large area, heavy construction.', complexity: 'EXPERT' },
      { title: 'Repair wooden floor', description: 'Fix damaged wooden floorboards in multiple rooms.', complexity: 'MODERATE' },
    ],
  },
  {
    name: 'Appliance Repair',
    description: 'Repair and maintenance of home appliances',
    baseDuration: 60,
    jobTemplates: [
      { title: 'Fix washing machine', description: 'Washing machine not spinning. Quick inspection and repair needed.', complexity: 'SIMPLE' },
      { title: 'Repair refrigerator', description: 'Refrigerator not cooling properly. Need diagnostic and repair.', complexity: 'MODERATE' },
      { title: 'Fix microwave', description: 'Microwave not heating. Quick check and repair.', complexity: 'SIMPLE' },
      { title: 'AC unit repair', description: 'Air conditioner making noise and not cooling well. Full service and repair.', complexity: 'MODERATE' },
      { title: 'Oven repair', description: 'Electric oven not reaching correct temperature. Heating element may need replacement.', complexity: 'MODERATE' },
      { title: 'Install dishwasher', description: 'Install new dishwasher with plumbing and electrical connections. Complete installation.', complexity: 'COMPLEX' },
      { title: 'Repair dryer', description: 'Clothes dryer not heating. Quick fix needed.', complexity: 'SIMPLE' },
      { title: 'Service multiple appliances', description: 'Full service of washing machine, dryer, and refrigerator. Multiple appliance overhaul.', complexity: 'EXPERT' },
    ],
  },
  {
    name: 'Gardening',
    description: 'Lawn care, landscaping, and garden maintenance',
    baseDuration: 90,
    jobTemplates: [
      { title: 'Mow small lawn', description: 'Mow and trim small front yard lawn. Quick maintenance.', complexity: 'SIMPLE' },
      { title: 'Trim hedges', description: 'Trim garden hedges and small bushes. Simple garden maintenance.', complexity: 'SIMPLE' },
      { title: 'Plant flower bed', description: 'Prepare soil and plant new flower bed in the garden. Moderate gardening work.', complexity: 'MODERATE' },
      { title: 'Full garden landscaping', description: 'Complete garden redesign and landscaping. Multiple areas, new plants, pathways, and features.', complexity: 'EXPERT' },
      { title: 'Tree trimming', description: 'Trim several large trees in the garden. Need equipment for height.', complexity: 'COMPLEX' },
      { title: 'Install irrigation system', description: 'Install drip irrigation system for entire garden. Multiple zones.', complexity: 'COMPLEX' },
      { title: 'Weed removal', description: 'Remove weeds from garden beds. Simple cleanup work.', complexity: 'SIMPLE' },
      { title: 'Build raised garden beds', description: 'Construct and fill multiple raised garden beds with soil. Heavy building work.', complexity: 'COMPLEX' },
    ],
  },
  {
    name: 'Pest Control',
    description: 'Pest removal and prevention services',
    baseDuration: 45,
    jobTemplates: [
      { title: 'Ant treatment', description: 'Ant infestation in kitchen. Quick treatment needed.', complexity: 'SIMPLE' },
      { title: 'Cockroach treatment', description: 'Cockroach problem in kitchen and bathrooms. Spray treatment.', complexity: 'SIMPLE' },
      { title: 'Termite inspection', description: 'Inspect house for termite damage. Check all wooden structures.', complexity: 'MODERATE' },
      { title: 'Full house fumigation', description: 'Complete house fumigation for multiple pest types. All rooms and areas. Thorough treatment.', complexity: 'COMPLEX' },
      { title: 'Rat removal', description: 'Rat infestation in roof area. Need trap setting and removal.', complexity: 'MODERATE' },
      { title: 'Mosquito treatment', description: 'Full property mosquito treatment including outdoor areas.', complexity: 'MODERATE' },
      { title: 'Termite treatment full house', description: 'Complete termite treatment and prevention for entire building. Heavy professional treatment. Multiple floors.', complexity: 'EXPERT' },
      { title: 'Bee hive removal', description: 'Remove bee hive from roof area. Need protective equipment.', complexity: 'COMPLEX' },
    ],
  },
  {
    name: 'AC Service',
    description: 'Air conditioning installation, repair, and maintenance',
    baseDuration: 60,
    jobTemplates: [
      { title: 'AC cleaning', description: 'Clean and service one split AC unit. Filter cleaning and gas check.', complexity: 'SIMPLE' },
      { title: 'AC gas refill', description: 'Refill refrigerant gas in AC unit. Quick top-up.', complexity: 'SIMPLE' },
      { title: 'Install split AC', description: 'Install new split AC unit including mounting and piping.', complexity: 'COMPLEX' },
      { title: 'AC compressor repair', description: 'AC compressor not working. Need diagnosis and repair.', complexity: 'MODERATE' },
      { title: 'Multiple AC service', description: 'Service and clean several AC units throughout the house. Multiple rooms.', complexity: 'COMPLEX' },
      { title: 'Central AC installation', description: 'Install central air conditioning system for entire building. Heavy construction and installation work.', complexity: 'EXPERT' },
      { title: 'AC duct cleaning', description: 'Clean AC ducts and vents throughout the house. Thorough cleaning.', complexity: 'MODERATE' },
      { title: 'Fix AC water leak', description: 'AC unit leaking water. Quick fix for drain pipe.', complexity: 'SIMPLE' },
    ],
  },
  {
    name: 'Moving',
    description: 'House moving, packing, and transport services',
    baseDuration: 180,
    jobTemplates: [
      { title: 'Move small items', description: 'Move a few small furniture items to nearby location. Quick and simple.', complexity: 'SIMPLE' },
      { title: 'Move one room', description: 'Pack and move contents of one room to new location.', complexity: 'MODERATE' },
      { title: 'Move apartment', description: 'Full apartment move including packing, transport, and unpacking. Multiple rooms.', complexity: 'COMPLEX' },
      { title: 'Full house move', description: 'Complete house relocation. All furniture, appliances, and belongings. Multiple floors, large house. Heavy moving.', complexity: 'EXPERT' },
      { title: 'Office relocation', description: 'Move commercial office to new location. Desks, equipment, files. Several rooms.', complexity: 'EXPERT' },
      { title: 'Move heavy appliances', description: 'Move refrigerator, washing machine, and other heavy appliances. Need equipment.', complexity: 'MODERATE' },
      { title: 'Packing service only', description: 'Pack all items in the house for moving. Professional packing with materials.', complexity: 'MODERATE' },
      { title: 'Move piano', description: 'Move grand piano to new location. Specialized heavy item moving. Needs care.', complexity: 'COMPLEX' },
    ],
  },
];

// ─── Worker Definitions (extended from seed-matching) ───────────────────────

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
  categoryIndices: number[]; // some workers serve multiple categories
}

const WORKERS: WorkerSeed[] = [
  // Plumbing specialists
  { name: 'Kamal Perera',     email: 'kamal@test.lk',     lat: 6.9300, lng: 79.8650, rating: 4.8, totalJobs: 120, completionRate: 0.95, badgeLevel: 'PLATINUM', verified: true,  categoryIndices: [0] },
  { name: 'Nimal Silva',      email: 'nimal@test.lk',     lat: 6.9180, lng: 79.8580, rating: 4.2, totalJobs: 65,  completionRate: 0.88, badgeLevel: 'GOLD',     verified: true,  categoryIndices: [0] },
  { name: 'Sunil Fernando',   email: 'sunil@test.lk',     lat: 6.9350, lng: 79.8700, rating: 3.5, totalJobs: 30,  completionRate: 0.80, badgeLevel: 'SILVER',   verified: true,  categoryIndices: [0] },
  { name: 'Ruwan Jayasena',   email: 'ruwan@test.lk',     lat: 6.9100, lng: 79.8500, rating: 3.0, totalJobs: 8,   completionRate: 0.75, badgeLevel: 'BRONZE',   verified: true,  categoryIndices: [0] },
  { name: 'Chaminda Bandara', email: 'chaminda@test.lk',  lat: 6.9400, lng: 79.8800, rating: 1.5, totalJobs: 2,   completionRate: 1.0,  badgeLevel: 'TRAINEE',  verified: false, categoryIndices: [0] },

  // Electrical specialists
  { name: 'Ashan Wijesinghe', email: 'ashan@test.lk',     lat: 6.9220, lng: 79.8550, rating: 4.9, totalJobs: 150, completionRate: 0.97, badgeLevel: 'PLATINUM', verified: true,  categoryIndices: [1] },
  { name: 'Dilshan Kumara',   email: 'dilshan@test.lk',   lat: 6.9280, lng: 79.8630, rating: 4.5, totalJobs: 55,  completionRate: 0.90, badgeLevel: 'GOLD',     verified: true,  categoryIndices: [1] },
  { name: 'Pradeep Ranatunga',email: 'pradeep@test.lk',   lat: 6.9150, lng: 79.8480, rating: 3.8, totalJobs: 25,  completionRate: 0.84, badgeLevel: 'SILVER',   verified: true,  categoryIndices: [1] },
  { name: 'Lahiru Mendis',    email: 'lahiru@test.lk',    lat: 6.9370, lng: 79.8750, rating: 2.5, totalJobs: 10,  completionRate: 0.70, badgeLevel: 'BRONZE',   verified: true,  categoryIndices: [1] },
  { name: 'Tharindu Dias',    email: 'tharindu@test.lk',  lat: 6.9450, lng: 79.8900, rating: 1.0, totalJobs: 1,   completionRate: 1.0,  badgeLevel: 'TRAINEE',  verified: false, categoryIndices: [1] },

  // Cleaning specialists
  { name: 'Malini Herath',    email: 'malini@test.lk',    lat: 6.9250, lng: 79.8600, rating: 4.7, totalJobs: 110, completionRate: 0.93, badgeLevel: 'PLATINUM', verified: true,  categoryIndices: [2] },
  { name: 'Sanduni Gamage',   email: 'sanduni@test.lk',   lat: 6.9200, lng: 79.8520, rating: 4.3, totalJobs: 52,  completionRate: 0.89, badgeLevel: 'GOLD',     verified: true,  categoryIndices: [2] },
  { name: 'Kumari Rajapaksa', email: 'kumari@test.lk',    lat: 6.9330, lng: 79.8680, rating: 3.6, totalJobs: 22,  completionRate: 0.82, badgeLevel: 'SILVER',   verified: true,  categoryIndices: [2] },
  { name: 'Nimali Weerasinghe',email:'nimali@test.lk',    lat: 6.9120, lng: 79.8450, rating: 2.8, totalJobs: 6,   completionRate: 0.67, badgeLevel: 'BRONZE',   verified: false, categoryIndices: [2] },
  { name: 'Iresha Samaraweera',email:'iresha@test.lk',    lat: 6.9500, lng: 79.8950, rating: 1.2, totalJobs: 0,   completionRate: 0,    badgeLevel: 'TRAINEE',  verified: false, categoryIndices: [2] },

  // Multi-category workers (extended)
  { name: 'Saman Jayawardena',email: 'saman@test.lk',     lat: 6.8900, lng: 79.8700, rating: 4.4, totalJobs: 80,  completionRate: 0.91, badgeLevel: 'GOLD',     verified: true,  categoryIndices: [3, 4] },     // Painting + Carpentry
  { name: 'Ajith Bandara',    email: 'ajith@test.lk',     lat: 6.9050, lng: 79.8350, rating: 4.1, totalJobs: 45,  completionRate: 0.87, badgeLevel: 'SILVER',   verified: true,  categoryIndices: [5, 8] },     // Appliance + AC
  { name: 'Dinesh Kumar',     email: 'dinesh@test.lk',    lat: 6.8700, lng: 79.8900, rating: 4.6, totalJobs: 95,  completionRate: 0.94, badgeLevel: 'PLATINUM', verified: true,  categoryIndices: [6] },        // Gardening
  { name: 'Roshan Perera',    email: 'roshan@test.lk',    lat: 6.9400, lng: 79.8200, rating: 3.9, totalJobs: 35,  completionRate: 0.83, badgeLevel: 'SILVER',   verified: true,  categoryIndices: [7] },        // Pest Control
  { name: 'Nuwan Dissanayake',email: 'nuwan@test.lk',     lat: 6.8500, lng: 79.8600, rating: 4.0, totalJobs: 60,  completionRate: 0.88, badgeLevel: 'GOLD',     verified: true,  categoryIndices: [9] },        // Moving
  { name: 'Kasun Bandara',    email: 'kasun@test.lk',     lat: 6.9150, lng: 79.9100, rating: 3.3, totalJobs: 15,  completionRate: 0.80, badgeLevel: 'BRONZE',   verified: true,  categoryIndices: [3] },        // Painting
  { name: 'Prasanna Kumara',  email: 'prasanna@test.lk',  lat: 6.8800, lng: 79.8400, rating: 4.3, totalJobs: 70,  completionRate: 0.90, badgeLevel: 'GOLD',     verified: true,  categoryIndices: [4, 0] },     // Carpentry + Plumbing
  { name: 'Gayan Wijesinghe', email: 'gayan@test.lk',     lat: 6.9600, lng: 79.8500, rating: 3.7, totalJobs: 28,  completionRate: 0.85, badgeLevel: 'SILVER',   verified: true,  categoryIndices: [8, 5] },     // AC + Appliance
  { name: 'Ruwini Karunaratne',email:'ruwini@test.lk',    lat: 6.8650, lng: 79.8750, rating: 4.5, totalJobs: 88,  completionRate: 0.92, badgeLevel: 'GOLD',     verified: true,  categoryIndices: [2, 6] },     // Cleaning + Gardening
  { name: 'Thilini Perera',   email: 'thilini@test.lk',   lat: 6.9100, lng: 79.8650, rating: 3.4, totalJobs: 18,  completionRate: 0.78, badgeLevel: 'BRONZE',   verified: false, categoryIndices: [7, 2] },     // Pest + Cleaning
];

// ─── Customer Definitions ───────────────────────────────────────────────────

const CUSTOMERS = [
  { name: 'Amara Bandara',     email: 'amara.cust@test.lk',    address: 'Colombo 03' },
  { name: 'Dilini Jayasuriya', email: 'dilini.cust@test.lk',   address: 'Nugegoda' },
  { name: 'Kasun Rathnayake',  email: 'kasun.cust@test.lk',    address: 'Rajagiriya' },
  { name: 'Nethmi Fernando',   email: 'nethmi.cust@test.lk',   address: 'Dehiwala' },
  { name: 'Pasan Gunawardena', email: 'pasan.cust@test.lk',    address: 'Mount Lavinia' },
  { name: 'Sachini Silva',     email: 'sachini.cust@test.lk',  address: 'Battaramulla' },
  { name: 'Thushara Perera',   email: 'thushara.cust@test.lk', address: 'Malabe' },
  { name: 'Udaya Wickramasinghe',email:'udaya.cust@test.lk',   address: 'Moratuwa' },
  { name: 'Vimukthi Dias',     email: 'vimukthi.cust@test.lk', address: 'Kandy' },
  { name: 'Wasana Kumari',     email: 'wasana.cust@test.lk',   address: 'Galle' },
];

// ─── Utility Functions ──────────────────────────────────────────────────────

const URGENCIES = ['LOW', 'NORMAL', 'URGENT', 'EMERGENCY'] as const;
const URGENCY_WEIGHTS = [0.20, 0.50, 0.20, 0.10]; // distribution

function weightedRandom<T>(items: readonly T[], weights: number[]): T {
  const r = Math.random();
  let cumulative = 0;
  for (let i = 0; i < items.length; i++) {
    cumulative += weights[i];
    if (r <= cumulative) return items[i];
  }
  return items[items.length - 1];
}

function randomInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randomFloat(min: number, max: number): number {
  return Math.random() * (max - min) + min;
}

// Gaussian noise using Box-Muller transform
function gaussianNoise(mean: number, stdDev: number): number {
  const u1 = Math.random();
  const u2 = Math.random();
  const z = Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2);
  return mean + z * stdDev;
}

function randomDate(monthsBack: number): Date {
  const now = Date.now();
  const pastMs = monthsBack * 30 * 24 * 60 * 60 * 1000;
  return new Date(now - Math.random() * pastMs);
}

function extractKeywords(desc: string): string[] {
  const stopWords = new Set([
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
  return desc
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, ' ')
    .split(/\s+/)
    .filter((w) => w.length > 2 && !stopWords.has(w));
}

// ─── Duration Calculation ───────────────────────────────────────────────────

const COMPLEXITY_MULTIPLIERS: Record<string, number> = {
  SIMPLE: 0.5,
  MODERATE: 1.0,
  COMPLEX: 1.8,
  EXPERT: 2.5,
};

const URGENCY_SPEED: Record<string, number> = {
  LOW: 1.1,
  NORMAL: 1.0,
  URGENT: 0.9,
  EMERGENCY: 0.85,
};

function workerSpeedFactor(totalJobs: number, rating: number): number {
  if (totalJobs >= 100 && rating >= 4.5) return 0.75;
  if (totalJobs >= 50 && rating >= 4.0) return 0.82;
  if (totalJobs >= 20 && rating >= 3.5) return 0.90;
  if (totalJobs >= 10) return 0.95;
  if (totalJobs >= 5) return 1.0;
  return 1.15;
}

function calculateRealisticDuration(
  baseDuration: number,
  complexity: string,
  urgency: string,
  workerTotalJobs: number,
  workerRating: number,
): number {
  const complexityMult = COMPLEXITY_MULTIPLIERS[complexity] ?? 1.0;
  const urgencyMult = URGENCY_SPEED[urgency] ?? 1.0;
  const workerSpeed = workerSpeedFactor(workerTotalJobs, workerRating);

  let duration = baseDuration * complexityMult * urgencyMult * workerSpeed;

  // Add realistic variance:
  // 70% within 10% of expected, 20% within 20-40%, 10% outliers
  const varianceRoll = Math.random();
  if (varianceRoll < 0.70) {
    // Normal variance: ±10%
    duration = gaussianNoise(duration, duration * 0.08);
  } else if (varianceRoll < 0.90) {
    // Moderate variance: ±20-40%
    duration = gaussianNoise(duration, duration * 0.25);
  } else {
    // Outlier: ±40%+
    duration = gaussianNoise(duration, duration * 0.45);
  }

  return Math.round(Math.max(15, Math.min(720, duration)));
}

// ─── Main Seed Function ─────────────────────────────────────────────────────

async function seed() {
  console.log('═══════════════════════════════════════════════════════════════');
  console.log('  DOER — Seeding Duration Estimation Data');
  console.log('═══════════════════════════════════════════════════════════════\n');

  // 1. Create/upsert categories
  console.log('📁 Creating categories...');
  const categories: Array<{ id: string; name: string; baseDuration: number; templates: CategoryDef['jobTemplates'] }> = [];
  for (const cat of CATEGORIES) {
    const created = await prisma.serviceCategory.upsert({
      where: { name: cat.name },
      update: { description: cat.description },
      create: { name: cat.name, description: cat.description },
    });
    categories.push({ ...created, baseDuration: cat.baseDuration, templates: cat.jobTemplates });
    console.log(`  ✓ ${created.name} (${created.id})`);
  }

  // 2. Create/upsert workers
  console.log('\n👷 Creating workers...');
  const workerProfiles: Array<{
    id: string;
    totalJobs: number;
    rating: number;
    badgeLevel: string;
    completionRate: number;
    categoryIds: string[];
  }> = [];

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
        badgeLevel: w.badgeLevel as BadgeLevel,
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
        badgeLevel: w.badgeLevel as BadgeLevel,
        verificationStatus: w.verified ? 'VERIFIED' : 'PENDING',
        isAvailable: true,
      },
    });

    const categoryIds: string[] = [];
    for (const catIdx of w.categoryIndices) {
      const catId = categories[catIdx].id;
      categoryIds.push(catId);
      await prisma.workerCategory.upsert({
        where: { workerId_categoryId: { workerId: profile.id, categoryId: catId } },
        update: {},
        create: { workerId: profile.id, categoryId: catId },
      });
    }

    workerProfiles.push({
      id: profile.id,
      totalJobs: w.totalJobs,
      rating: w.rating,
      badgeLevel: w.badgeLevel,
      completionRate: w.completionRate,
      categoryIds,
    });

    console.log(`  ✓ ${w.name} [${w.badgeLevel}] — ${w.categoryIndices.map(i => categories[i].name).join(', ')}`);
  }

  // 3. Create customers
  console.log('\n🏠 Creating customers...');
  const customerProfiles = [];
  for (const cust of CUSTOMERS) {
    const user = await prisma.user.upsert({
      where: { email: cust.email },
      update: {},
      create: {
        firebaseUid: `test_cust_${cust.email}`,
        email: cust.email,
        name: cust.name,
        role: 'CUSTOMER',
      },
    });

    const loc = LOCATIONS[randomInt(0, LOCATIONS.length - 1)];
    const profile = await prisma.customerProfile.upsert({
      where: { userId: user.id },
      update: {},
      create: {
        userId: user.id,
        address: cust.address,
        latitude: loc.lat + randomFloat(-0.01, 0.01),
        longitude: loc.lng + randomFloat(-0.01, 0.01),
      },
    });
    customerProfiles.push(profile);
    console.log(`  ✓ ${cust.name} — ${cust.address}`);
  }

  // 4. Generate synthetic completed jobs
  console.log(`\n⚡ Generating ${TOTAL_JOBS} synthetic completed jobs...`);

  let created = 0;
  const batchSize = 50;
  const categoryDistribution = Array.from({ length: TOTAL_JOBS }, () => randomInt(0, categories.length - 1));

  for (let batch = 0; batch < Math.ceil(TOTAL_JOBS / batchSize); batch++) {
    const start = batch * batchSize;
    const end = Math.min(start + batchSize, TOTAL_JOBS);

    for (let i = start; i < end; i++) {
      const catIdx = categoryDistribution[i];
      const cat = categories[catIdx];

      // Pick a random template
      const template = cat.templates[randomInt(0, cat.templates.length - 1)];

      // Pick a random worker from this category
      const eligibleWorkers = workerProfiles.filter(w => w.categoryIds.includes(cat.id));
      if (eligibleWorkers.length === 0) continue;
      const worker = eligibleWorkers[randomInt(0, eligibleWorkers.length - 1)];

      // Pick a random customer
      const customer = customerProfiles[randomInt(0, customerProfiles.length - 1)];

      // Pick urgency
      const urgency = weightedRandom(URGENCIES, URGENCY_WEIGHTS) as Urgency;

      // Calculate realistic duration
      const actualMinutes = calculateRealisticDuration(
        cat.baseDuration,
        template.complexity,
        urgency,
        worker.totalJobs,
        worker.rating,
      );

      // Generate dates
      const completedAt = randomDate(12); // within last 12 months
      const scheduledAt = new Date(completedAt.getTime() - actualMinutes * 60 * 1000 - randomInt(0, 120) * 60 * 1000);

      // Location
      const loc = LOCATIONS[randomInt(0, LOCATIONS.length - 1)];
      const jobLat = loc.lat + randomFloat(-0.005, 0.005);
      const jobLng = loc.lng + randomFloat(-0.005, 0.005);

      // Create the completed job
      const job = await prisma.job.create({
        data: {
          title: template.title,
          description: template.description,
          status: Math.random() > 0.15 ? 'COMPLETED' : 'CLOSED',
          urgency,
          latitude: jobLat,
          longitude: jobLng,
          address: loc.name,
          scheduledAt,
          completedAt,
          customerId: customer.id,
          workerId: worker.id,
          categoryId: cat.id,
          price: randomFloat(1000, 25000),
        },
      });

      // Extract keywords
      const keywords = extractKeywords(template.description);

      // Create duration log entry
      await prisma.jobDurationLog.create({
        data: {
          jobId: job.id,
          actualMinutes,
          estimatedMinutes: null, // No estimate was made for synthetic jobs
          complexity: template.complexity as ComplexityLevel,
          urgency,
          descriptionKeywords: keywords,
          workerTotalJobs: worker.totalJobs,
          workerRating: worker.rating,
          workerBadgeLevel: worker.badgeLevel,
          isSynthetic: true,
          completedAt,
          categoryId: cat.id,
          workerId: worker.id,
        },
      });

      created++;
    }

    const progress = Math.round((end / TOTAL_JOBS) * 100);
    process.stdout.write(`\r  Progress: ${created}/${TOTAL_JOBS} jobs (${progress}%)`);
  }
  console.log(`\n  ✓ Created ${created} synthetic jobs with duration logs`);

  // 5. Calculate and store category baselines
  console.log('\n📊 Calculating category baselines...');

  for (const cat of categories) {
    const logs = await prisma.jobDurationLog.findMany({
      where: { categoryId: cat.id },
    });

    if (logs.length === 0) {
      console.log(`  ⚠ No logs for ${cat.name}, skipping baseline`);
      continue;
    }

    const durations = logs.map(l => l.actualMinutes);
    const sorted = [...durations].sort((a, b) => a - b);

    const sum = durations.reduce((a, b) => a + b, 0);
    const avg = sum / durations.length;
    const median = sorted.length % 2 === 0
      ? (sorted[sorted.length / 2 - 1] + sorted[sorted.length / 2]) / 2
      : sorted[Math.floor(sorted.length / 2)];
    const variance = durations.reduce((acc, d) => acc + Math.pow(d - avg, 2), 0) / durations.length;
    const stdDev = Math.sqrt(variance);
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
    const learnedKeywords: Record<string, number> = {};
    for (const [keyword, times] of Object.entries(keywordDurations)) {
      if (times.length >= 5) {
        const kwAvg = times.reduce((a, b) => a + b, 0) / times.length;
        learnedKeywords[keyword] = Math.round((kwAvg / avg) * 100) / 100;
      }
    }

    await prisma.categoryDurationBaseline.upsert({
      where: { categoryId: cat.id },
      create: {
        categoryId: cat.id,
        defaultMinutes: cat.baseDuration,
        avgMinutes: Math.round(avg * 10) / 10,
        medianMinutes: Math.round(median * 10) / 10,
        stdDevMinutes: Math.round(stdDev * 10) / 10,
        p90Minutes: Math.round(p90 * 10) / 10,
        sampleCount: logs.length,
        complexityMultipliers: JSON.stringify(learnedMultipliers),
        keywordModifiers: JSON.stringify(learnedKeywords),
      },
      update: {
        defaultMinutes: cat.baseDuration,
        avgMinutes: Math.round(avg * 10) / 10,
        medianMinutes: Math.round(median * 10) / 10,
        stdDevMinutes: Math.round(stdDev * 10) / 10,
        p90Minutes: Math.round(p90 * 10) / 10,
        sampleCount: logs.length,
        complexityMultipliers: JSON.stringify(learnedMultipliers),
        keywordModifiers: JSON.stringify(learnedKeywords),
      },
    });

    console.log(`  ✓ ${cat.name}: avg=${Math.round(avg)}min, median=${Math.round(median)}min, stdDev=${Math.round(stdDev)}min, samples=${logs.length}`);
  }

  // 6. Summary
  const totalLogs = await prisma.jobDurationLog.count();
  const totalBaselines = await prisma.categoryDurationBaseline.count();

  console.log('\n═══════════════════════════════════════════════════════════════');
  console.log('  Seed Complete!');
  console.log('═══════════════════════════════════════════════════════════════');
  console.log(`  ${categories.length} categories`);
  console.log(`  ${workerProfiles.length} workers`);
  console.log(`  ${customerProfiles.length} customers`);
  console.log(`  ${created} synthetic completed jobs`);
  console.log(`  ${totalLogs} duration log entries`);
  console.log(`  ${totalBaselines} category baselines calculated`);
  console.log('═══════════════════════════════════════════════════════════════\n');

  process.exit(0);
}

seed().catch((e) => {
  console.error('Seed failed:', e);
  process.exit(1);
});
