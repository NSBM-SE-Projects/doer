import bcrypt from 'bcryptjs';
import prisma from './config/prisma';

async function seedAdmin() {
  const email = 'admin@doer.lk';
  const password = 'admin123456';
  const name = 'Doer Admin';

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    console.log(`Admin user already exists: ${email}`);
    console.log(`  Email: ${email}`);
    console.log(`  Password: ${password}`);
    process.exit(0);
  }

  const passwordHash = await bcrypt.hash(password, 12);

  const user = await prisma.user.create({
    data: {
      firebaseUid: `admin_${Date.now()}`,
      email,
      passwordHash,
      name,
      role: 'ADMIN',
    },
  });

  console.log('Admin user created successfully!');
  console.log(`  Email: ${email}`);
  console.log(`  Password: ${password}`);
  console.log(`  User ID: ${user.id}`);
  console.log(`  Role: ${user.role}`);
  process.exit(0);
}

seedAdmin().catch((e) => {
  console.error('Failed to seed admin:', e);
  process.exit(1);
});
