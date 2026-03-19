import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const categories = [
    { name: 'Plumbing', description: 'Pipe repairs, installations, and plumbing services' },
    { name: 'Electrical', description: 'Wiring, repairs, and electrical installations' },
    { name: 'Cleaning', description: 'Home and office cleaning services' },
    { name: 'Painting', description: 'Interior and exterior painting services' },
    { name: 'Gardening', description: 'Lawn care, landscaping, and garden maintenance' },
    { name: 'Moving', description: 'Furniture moving and relocation services' },
    { name: 'Carpentry', description: 'Woodwork, furniture repair, and carpentry services' },
    { name: 'Appliance', description: 'Appliance repair and installation services' },
  ];

  for (const category of categories) {
    await prisma.serviceCategory.upsert({
      where: { name: category.name },
      update: {},
      create: category,
    });
  }

  console.log('Seeded 8 service categories');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
