import prisma from '../config/prisma';
import { createNotification } from '../routes/notifications';

const ESCROW_HOLD_HOURS = 48;
const CHECK_INTERVAL_MS = 60 * 60 * 1000; // Check every hour

export function startEscrowCron() {
  console.log('Escrow auto-release cron started (checking every hour)');

  setInterval(async () => {
    try {
      const cutoff = new Date(Date.now() - ESCROW_HOLD_HOURS * 60 * 60 * 1000);

      // Find HELD payments older than 48 hours with no dispute
      const paymentsToRelease = await prisma.payment.findMany({
        where: {
          status: 'HELD',
          heldAt: { lte: cutoff },
          dispute: null,
        },
        include: {
          job: {
            include: {
              customer: true,
              worker: true,
              review: true,
            },
          },
        },
      });

      for (const payment of paymentsToRelease) {
        await prisma.payment.update({
          where: { id: payment.id },
          data: { status: 'RELEASED', releasedAt: new Date() },
        });

        // Close job if review exists
        const newJobStatus = payment.job.review ? 'CLOSED' : 'REVIEWING';
        await prisma.job.update({
          where: { id: payment.jobId },
          data: { status: newJobStatus as any },
        });

        // Notify worker
        if (payment.job.worker) {
          await createNotification(
            payment.job.worker.userId,
            'Payment Released',
            `Rs. ${payment.amount.toLocaleString()} has been automatically released to your earnings for "${payment.job.title}".`
          );
        }

        // Notify customer
        await createNotification(
          payment.job.customer.userId,
          'Payment Released',
          `Rs. ${payment.amount.toLocaleString()} has been automatically released to the worker for "${payment.job.title}".`
        );

        console.log(`Auto-released payment ${payment.id} for job "${payment.job.title}"`);
      }

      if (paymentsToRelease.length > 0) {
        console.log(`Auto-released ${paymentsToRelease.length} escrow payment(s)`);
      }
    } catch (err) {
      console.error('Escrow cron error:', err);
    }
  }, CHECK_INTERVAL_MS);
}
