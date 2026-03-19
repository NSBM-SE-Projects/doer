import prisma from '../utils/prisma';

export const getEarningsSummary = async (workerId: string) => {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  const completedJobs = await prisma.job.findMany({
    where: { workerId, status: 'COMPLETED' },
    include: { payment: true },
  });

  const total = completedJobs.reduce((sum, job) => sum + (job.payment?.amount || 0), 0);

  const thisMonthJobs = completedJobs.filter(
    (job) => job.completedAt && job.completedAt >= startOfMonth
  );
  const thisMonth = thisMonthJobs.reduce((sum, job) => sum + (job.payment?.amount || 0), 0);

  const pendingPayouts = await prisma.payout.findMany({
    where: { workerId, status: 'PENDING' },
  });
  const pending = pendingPayouts.reduce((sum, p) => sum + p.amount, 0);

  return { total, thisMonth, pending, completedJobsCount: completedJobs.length };
};

export const getPayoutHistory = async (workerId: string) => {
  return prisma.payout.findMany({
    where: { workerId },
    orderBy: { requestedAt: 'desc' },
  });
};

export const requestPayout = async (workerId: string, amount: number) => {
  return prisma.payout.create({
    data: { workerId, amount },
  });
};

export const getSubscription = async (workerId: string) => {
  return prisma.subscription.findUnique({ where: { workerId } });
};

export const initiatePayment = async (jobId: string, amount: number) => {
  const existing = await prisma.payment.findUnique({ where: { jobId } });
  if (existing) return existing;

  return prisma.payment.create({
    data: { jobId, amount, status: 'PENDING' },
  });
};

export const handlePayhereWebhook = async (data: {
  orderId: string;
  payhereRef: string;
  statusCode: string;
}) => {
  const { orderId, payhereRef, statusCode } = data;

  // statusCode: 2 = success, 0 = pending, -1 = cancelled, -2 = failed
  const statusMap: Record<string, string> = {
    '2': 'COMPLETED',
    '0': 'PENDING',
    '-1': 'CANCELLED',
    '-2': 'FAILED',
  };

  const status = statusMap[statusCode] || 'PENDING';

  const payment = await prisma.payment.update({
    where: { jobId: orderId },
    data: { status, payhereRef },
    include: { job: { include: { worker: true } } },
  });

  if (status === 'COMPLETED' && payment.job.workerId) {
    // Worker earns 85% of payment (15% platform fee)
    const workerEarning = payment.amount * 0.85;
    await prisma.payout.create({
      data: {
        workerId: payment.job.workerId,
        amount: workerEarning,
        status: 'PENDING',
        reference: payhereRef,
      },
    });

    // Update worker stats
    await prisma.workerProfile.update({
      where: { id: payment.job.workerId },
      data: { totalJobs: { increment: 1 } },
    });
  }

  return payment;
};

export const getJobPayment = async (jobId: string) => {
  return prisma.payment.findUnique({ where: { jobId } });
};
