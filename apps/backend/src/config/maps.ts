import { Client, TravelMode } from '@googlemaps/google-maps-services-js';
import { env } from './env';

const client = new Client({});
const apiKey = env.GOOGLE_MAPS_API_KEY || '';

const isConfigured = !!apiKey;

/**
 * Geocode: convert address → lat/lng
 * Restricted to Sri Lanka (region: lk, components: country:lk)
 */
export async function geocode(address: string): Promise<{
  lat: number;
  lng: number;
  formattedAddress: string;
} | null> {
  if (!isConfigured) return null;

  const response = await client.geocode({
    params: {
      address,
      key: apiKey,
      region: 'lk',
      components: { country: 'lk' },
    },
  });

  const result = response.data.results[0];
  if (!result) return null;

  return {
    lat: result.geometry.location.lat,
    lng: result.geometry.location.lng,
    formattedAddress: result.formatted_address,
  };
}

/**
 * Reverse geocode: convert lat/lng → readable address
 */
export async function reverseGeocode(
  lat: number,
  lng: number
): Promise<string | null> {
  if (!isConfigured) return null;

  const response = await client.reverseGeocode({
    params: {
      latlng: { lat, lng },
      key: apiKey,
      result_type: ['street_address' as any, 'route' as any, 'locality' as any],
    },
  });

  const result = response.data.results[0];
  return result?.formatted_address || null;
}

/**
 * Distance Matrix: get real road distance and driving duration between two points
 */
export async function getDistance(
  originLat: number,
  originLng: number,
  destLat: number,
  destLng: number
): Promise<{
  distanceText: string;
  distanceMeters: number;
  durationText: string;
  durationSeconds: number;
} | null> {
  if (!isConfigured) return null;

  const response = await client.distancematrix({
    params: {
      origins: [{ lat: originLat, lng: originLng }],
      destinations: [{ lat: destLat, lng: destLng }],
      mode: TravelMode.driving,
      key: apiKey,
      region: 'lk',
    },
  });

  const element = response.data.rows[0]?.elements[0];
  if (!element || element.status !== 'OK') return null;

  return {
    distanceText: element.distance.text,
    distanceMeters: element.distance.value,
    durationText: element.duration.text,
    durationSeconds: element.duration.value,
  };
}

/**
 * Places Autocomplete: power address search fields
 * Restricted to Sri Lanka for accuracy and cost
 */
export async function placesAutocomplete(
  input: string
): Promise<Array<{ placeId: string; description: string }>> {
  if (!isConfigured) return [];

  const response = await client.placeAutocomplete({
    params: {
      input,
      key: apiKey,
      components: ['country:lk'],
      types: 'address' as any,
    },
  });

  return response.data.predictions.map((p) => ({
    placeId: p.place_id,
    description: p.description,
  }));
}

/**
 * Get place details (lat/lng) from a Place ID
 */
export async function placeDetails(
  placeId: string
): Promise<{ lat: number; lng: number; address: string } | null> {
  if (!isConfigured) return null;

  const response = await client.placeDetails({
    params: {
      place_id: placeId,
      key: apiKey,
      fields: ['geometry', 'formatted_address'],
    },
  });

  const result = response.data.result;
  if (!result?.geometry?.location) return null;

  return {
    lat: result.geometry.location.lat,
    lng: result.geometry.location.lng,
    address: result.formatted_address || '',
  };
}

export { isConfigured as isMapsConfigured };
