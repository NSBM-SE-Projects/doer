import { Router } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { AppError } from '../utils/AppError';
import {
  geocode,
  reverseGeocode,
  getDistance,
  placesAutocomplete,
  placeDetails,
  isMapsConfigured,
} from '../config/maps';

const router = Router();

// GET /api/maps/geocode?address=...
router.get(
  '/geocode',
  asyncHandler(async (req, res) => {
    if (!isMapsConfigured) throw AppError.badRequest('Google Maps not configured');
    const { address } = req.query;
    if (!address) throw AppError.badRequest('address query param required');

    const result = await geocode(address as string);
    if (!result) throw AppError.notFound('Address not found');

    res.json(result);
  })
);

// GET /api/maps/reverse-geocode?lat=...&lng=...
router.get(
  '/reverse-geocode',
  asyncHandler(async (req, res) => {
    if (!isMapsConfigured) throw AppError.badRequest('Google Maps not configured');
    const { lat, lng } = req.query;
    if (!lat || !lng) throw AppError.badRequest('lat and lng required');

    const address = await reverseGeocode(Number(lat), Number(lng));
    if (!address) throw AppError.notFound('No address found for coordinates');

    res.json({ address });
  })
);

// GET /api/maps/distance?originLat=...&originLng=...&destLat=...&destLng=...
router.get(
  '/distance',
  asyncHandler(async (req, res) => {
    if (!isMapsConfigured) throw AppError.badRequest('Google Maps not configured');
    const { originLat, originLng, destLat, destLng } = req.query;
    if (!originLat || !originLng || !destLat || !destLng) {
      throw AppError.badRequest('originLat, originLng, destLat, destLng required');
    }

    const result = await getDistance(
      Number(originLat), Number(originLng),
      Number(destLat), Number(destLng)
    );
    if (!result) throw AppError.notFound('Could not calculate distance');

    res.json(result);
  })
);

// GET /api/maps/autocomplete?input=...
router.get(
  '/autocomplete',
  asyncHandler(async (req, res) => {
    if (!isMapsConfigured) throw AppError.badRequest('Google Maps not configured');
    const { input } = req.query;
    if (!input) throw AppError.badRequest('input query param required');

    const predictions = await placesAutocomplete(input as string);
    res.json({ predictions });
  })
);

// GET /api/maps/place-details?placeId=...
router.get(
  '/place-details',
  asyncHandler(async (req, res) => {
    if (!isMapsConfigured) throw AppError.badRequest('Google Maps not configured');
    const { placeId } = req.query;
    if (!placeId) throw AppError.badRequest('placeId required');

    const result = await placeDetails(placeId as string);
    if (!result) throw AppError.notFound('Place not found');

    res.json(result);
  })
);

export default router;
