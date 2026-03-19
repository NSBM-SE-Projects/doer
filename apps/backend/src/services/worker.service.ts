import prisma from '../utils/prisma';

export const listWorkers = async (filters: {
  categoryId?: string;
  isAvailable?: boolean;
  serviceArea?: string;
}) => {
  const { categoryId, isAvailable, serviceArea } = filters;

  return prisma.workerProfile.findMany({
    where: {
      ...(isAvailable !== undefined && { isAvailable }),
      ...(serviceArea && { serviceArea: { contains: serviceArea, mode: 'insensitive' } }),
      ...(categoryId && {
        categories: { some: { categoryId } },
      }),
    },
    include: {
      user: { select: { id: true, name: true, email: true, avatarUrl: true, phone: true } },
      categories: { include: { category: true } },
    },
  });
};

export const getWorkerById = async (workerId: string) => {
  return prisma.workerProfile.findUnique({
    where: { id: workerId },
    include: {
      user: { select: { id: true, name: true, email: true, avatarUrl: true, phone: true } },
      categories: { include: { category: true } },
      reviews: { include: { customer: { include: { user: { select: { name: true, avatarUrl: true } } } } }, orderBy: { createdAt: 'desc' }, take: 10 },
    },
  });
};

export const updateWorkerProfile = async (
  workerId: string,
  data: {
    bio?: string;
    hourlyRate?: number;
    languages?: string[];
    serviceArea?: string;
    serviceRadius?: number;
    categoryIds?: string[];
  }
) => {
  const { categoryIds, ...profileData } = data;

  const updated = await prisma.workerProfile.update({
    where: { id: workerId },
    data: profileData,
    include: { categories: { include: { category: true } } },
  });

  if (categoryIds !== undefined) {
    await prisma.workerCategory.deleteMany({ where: { workerId } });
    if (categoryIds.length > 0) {
      await prisma.workerCategory.createMany({
        data: categoryIds.map((categoryId) => ({ workerId, categoryId })),
        skipDuplicates: true,
      });
    }
  }

  return prisma.workerProfile.findUnique({
    where: { id: workerId },
    include: { categories: { include: { category: true } } },
  });
};

export const toggleAvailability = async (workerId: string, isAvailable: boolean) => {
  return prisma.workerProfile.update({
    where: { id: workerId },
    data: { isAvailable },
    select: { id: true, isAvailable: true },
  });
};

export const uploadVerificationDocument = async (
  workerId: string,
  type: string,
  fileUrl: string
) => {
  return prisma.verificationDocument.create({
    data: {
      workerId,
      type: type as any,
      fileUrl,
    },
  });
};

export const getVerificationDocuments = async (workerId: string) => {
  return prisma.verificationDocument.findMany({
    where: { workerId },
    orderBy: { createdAt: 'desc' },
  });
};

export const getNearbyWorkers = async (params: {
  lat: number;
  lng: number;
  radius: number;
  categoryId?: string;
}) => {
  const { lat, lng, radius, categoryId } = params;

  const workers = await prisma.workerProfile.findMany({
    where: {
      isAvailable: true,
      latitude: { not: null },
      longitude: { not: null },
      ...(categoryId && { categories: { some: { categoryId } } }),
    },
    include: {
      user: { select: { id: true, name: true, avatarUrl: true } },
      categories: { include: { category: true } },
    },
  });

  // Filter by distance using Haversine formula
  const R = 6371; // Earth radius in km
  const nearby = workers.filter((worker) => {
    if (!worker.latitude || !worker.longitude) return false;
    const dLat = ((worker.latitude - lat) * Math.PI) / 180;
    const dLng = ((worker.longitude - lng) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat * Math.PI) / 180) *
        Math.cos((worker.latitude * Math.PI) / 180) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c;
    return distance <= radius;
  });

  return nearby;
};
