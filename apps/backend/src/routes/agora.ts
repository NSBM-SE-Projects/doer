import { Router, Response } from 'express';
import { RtcTokenBuilder, RtcRole } from 'agora-token';
import { authenticate, AuthRequest } from '../middleware/auth';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';
import { env } from '../config/env';

const router = Router();

// GET /api/agora/token?channelName=xxx
router.get(
  '/token',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { channelName } = req.query;
    if (!channelName || typeof channelName !== 'string') {
      throw AppError.badRequest('channelName query parameter is required');
    }

    const appId = env.AGORA_APP_ID;
    const appCertificate = env.AGORA_APP_CERTIFICATE;

    if (!appId || !appCertificate) {
      throw AppError.badRequest('Agora is not configured. Set AGORA_APP_ID and AGORA_APP_CERTIFICATE in .env');
    }

    const uid = 0; // 0 means Agora assigns one
    const role = RtcRole.PUBLISHER;
    const expirationTimeInSeconds = 3600; // 1 hour
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      uid,
      role,
      expirationTimeInSeconds,
      privilegeExpiredTs,
    );

    res.json({ token, appId, channelName, uid });
  })
);

export default router;
