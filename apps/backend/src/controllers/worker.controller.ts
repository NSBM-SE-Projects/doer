import { Response } from 'express';
import { v2 as cloudinary } from 'cloudinary';
import { AuthRequest } from '../middleware/auth';
import * as workerService from '../services/worker.service';
import prisma from '../utils/prisma';
import { success, error } from '../utils/response';

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

export const listWorkers = async (req: AuthRequest, res: Response) => {
  try {
    const { categoryId, isAvailable, serviceArea } = req.query;
    const workers = await workerService.listWorkers({
      categoryId: categoryId as string | undefined,
      isAvailable: isAvailable !== undefined ? isAvailable === 'true' : undefined,
      serviceArea: serviceArea as string | undefined,
    });
    return success(res, workers);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to list workers';
    return error(res, message, 500);
  }
};

export const getWorkerById = async (req: AuthRequest, res: Response) => {
  try {
    const worker = await workerService.getWorkerById(req.params.id);
    if (!worker) return error(res, 'Worker not found', 404);
    return success(res, worker);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to get worker';
    return error(res, message, 500);
  }
};

export const updateMyProfile = async (req: AuthRequest, res: Response) => {
  try {
    const workerProfile = await prisma.workerProfile.findUnique({
      where: { userId: req.user!.dbUserId },
    });
    if (!workerProfile) return error(res, 'Worker profile not found', 404);

    const { bio, hourlyRate, languages, serviceArea, serviceRadius, categoryIds } = req.body;
    const updated = await workerService.updateWorkerProfile(workerProfile.id, {
      bio,
      hourlyRate: hourlyRate !== undefined ? Number(hourlyRate) : undefined,
      languages,
      serviceArea,
      serviceRadius: serviceRadius !== undefined ? Number(serviceRadius) : undefined,
      categoryIds,
    });
    return success(res, updated);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to update profile';
    return error(res, message, 500);
  }
};

export const toggleAvailability = async (req: AuthRequest, res: Response) => {
  try {
    const workerProfile = await prisma.workerProfile.findUnique({
      where: { userId: req.user!.dbUserId },
    });
    if (!workerProfile) return error(res, 'Worker profile not found', 404);

    const { isAvailable } = req.body;
    if (typeof isAvailable !== 'boolean') {
      return error(res, 'isAvailable must be a boolean');
    }

    const updated = await workerService.toggleAvailability(workerProfile.id, isAvailable);
    return success(res, updated);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to update availability';
    return error(res, message, 500);
  }
};

export const uploadDocument = async (req: AuthRequest, res: Response) => {
  try {
    const workerProfile = await prisma.workerProfile.findUnique({
      where: { userId: req.user!.dbUserId },
    });
    if (!workerProfile) return error(res, 'Worker profile not found', 404);

    const { type, fileBase64 } = req.body;
    const validTypes = ['NIC_FRONT', 'NIC_BACK', 'QUALIFICATION', 'BACKGROUND'];
    if (!type || !validTypes.includes(type)) {
      return error(res, 'Valid document type required');
    }
    if (!fileBase64) {
      return error(res, 'File data required');
    }

    const uploadResult = await cloudinary.uploader.upload(fileBase64, {
      folder: `doer/verification/${workerProfile.id}`,
      resource_type: 'auto',
    });

    const doc = await workerService.uploadVerificationDocument(
      workerProfile.id,
      type,
      uploadResult.secure_url
    );
    return success(res, doc, 201);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to upload document';
    return error(res, message, 500);
  }
};

export const getMyDocuments = async (req: AuthRequest, res: Response) => {
  try {
    const workerProfile = await prisma.workerProfile.findUnique({
      where: { userId: req.user!.dbUserId },
    });
    if (!workerProfile) return error(res, 'Worker profile not found', 404);

    const docs = await workerService.getVerificationDocuments(workerProfile.id);
    return success(res, docs);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to get documents';
    return error(res, message, 500);
  }
};

export const getNearbyWorkers = async (req: AuthRequest, res: Response) => {
  try {
    const { lat, lng, radius, categoryId } = req.body;
    if (!lat || !lng) return error(res, 'lat and lng are required');

    const workers = await workerService.getNearbyWorkers({
      lat: Number(lat),
      lng: Number(lng),
      radius: Number(radius) || 25,
      categoryId: categoryId as string | undefined,
    });
    return success(res, workers);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to get nearby workers';
    return error(res, message, 500);
  }
};
