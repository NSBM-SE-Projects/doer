import { Request, Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import * as earningsService from '../services/earnings.service';
import prisma from '../utils/prisma';
import { success, error } from '../utils/response';

export const getEarningsSummary = async (req: AuthRequest, res: Response) => {
  try {
    const workerProfile = await prisma.workerProfile.findUnique({
      where: { userId: req.user!.dbUserId },
    });
    if (!workerProfile) return error(res, 'Worker profile not found', 404);

    const summary = await earningsService.getEarningsSummary(workerProfile.id);
    return success(res, summary);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to get earnings';
    return error(res, message, 500);
  }
};

export const getPayoutHistory = async (req: AuthRequest, res: Response) => {
  try {
    const workerProfile = await prisma.workerProfile.findUnique({
      where: { userId: req.user!.dbUserId },
    });
    if (!workerProfile) return error(res, 'Worker profile not found', 404);

    const history = await earningsService.getPayoutHistory(workerProfile.id);
    return success(res, history);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to get payout history';
    return error(res, message, 500);
  }
};

export const requestPayout = async (req: AuthRequest, res: Response) => {
  try {
    const workerProfile = await prisma.workerProfile.findUnique({
      where: { userId: req.user!.dbUserId },
    });
    if (!workerProfile) return error(res, 'Worker profile not found', 404);

    const { amount } = req.body;
    if (!amount || Number(amount) <= 0) return error(res, 'Valid amount required');

    const payout = await earningsService.requestPayout(workerProfile.id, Number(amount));
    return success(res, payout, 201);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to request payout';
    return error(res, message, 500);
  }
};

export const getSubscription = async (req: AuthRequest, res: Response) => {
  try {
    const workerProfile = await prisma.workerProfile.findUnique({
      where: { userId: req.user!.dbUserId },
    });
    if (!workerProfile) return error(res, 'Worker profile not found', 404);

    const subscription = await earningsService.getSubscription(workerProfile.id);
    return success(res, subscription);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to get subscription';
    return error(res, message, 500);
  }
};

export const initiatePayment = async (req: AuthRequest, res: Response) => {
  try {
    const { jobId, amount } = req.body;
    if (!jobId || !amount) return error(res, 'jobId and amount are required');

    const payment = await earningsService.initiatePayment(jobId, Number(amount));
    return success(res, payment, 201);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to initiate payment';
    return error(res, message, 500);
  }
};

export const payhereWebhook = async (req: Request, res: Response) => {
  try {
    const { order_id, payment_id, status_code } = req.body;

    if (!order_id || !payment_id || !status_code) {
      return res.status(400).json({ message: 'Invalid webhook payload' });
    }

    await earningsService.handlePayhereWebhook({
      orderId: order_id,
      payhereRef: payment_id,
      statusCode: String(status_code),
    });

    return res.status(200).json({ message: 'Webhook processed' });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Webhook processing failed';
    return res.status(500).json({ message });
  }
};

export const getJobPayment = async (req: AuthRequest, res: Response) => {
  try {
    const payment = await earningsService.getJobPayment(req.params.jobId);
    if (!payment) return error(res, 'Payment not found', 404);
    return success(res, payment);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to get payment';
    return error(res, message, 500);
  }
};
