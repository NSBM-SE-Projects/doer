import prisma from '../utils/prisma';

export const getMessageHistory = async (jobId: string) => {
  return prisma.message.findMany({
    where: { jobId },
    include: {
      sender: { select: { id: true, name: true, avatarUrl: true, role: true } },
    },
    orderBy: { createdAt: 'asc' },
  });
};

export const sendMessage = async (jobId: string, senderId: string, content: string) => {
  return prisma.message.create({
    data: { jobId, senderId, content },
    include: {
      sender: { select: { id: true, name: true, avatarUrl: true, role: true } },
    },
  });
};

export const getConversations = async (userId: string) => {
  // Get all jobs that have messages involving this user
  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: {
      customerProfile: { include: { jobs: { include: { messages: { orderBy: { createdAt: 'desc' }, take: 1 }, category: true, worker: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } } } } } },
      workerProfile: { include: { jobs: { include: { messages: { orderBy: { createdAt: 'desc' }, take: 1 }, category: true, customer: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } } } } } },
    },
  });

  const jobs = user?.customerProfile?.jobs || user?.workerProfile?.jobs || [];

  return jobs
    .filter((job) => job.messages.length > 0)
    .map((job) => ({
      jobId: job.id,
      jobTitle: job.title,
      lastMessage: job.messages[0],
      category: job.category,
    }));
};
