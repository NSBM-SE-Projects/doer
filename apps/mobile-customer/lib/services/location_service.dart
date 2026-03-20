// lib/services/location_service.dart
//
// Handles all location + recommendation API calls.
// Replace BASE_URL with your Railway deployment URL.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../core/config/app_config.dart';

// Uses the main backend base URL. ML recommendation endpoints
// (e.g. /recommend, /bookings/add) require a separate service.
String get baseUrl => AppConfig.socketUrl;

class LocationService {
  // ── Get device GPS location ──────────────────────────────────
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  // ── Address autocomplete (as user types) ─────────────────────
  static Future<List<Map<String, dynamic>>> getAddressSuggestions(
      String inputText) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/location/autocomplete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'input_text': inputText}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['suggestions']);
      }
    } catch (e) {
      debugPrint('Autocomplete error: $e');
    }
    return [];
  }

  // ── Get coordinates for a selected address suggestion ─────────
  static Future<Map<String, dynamic>?> getPlaceCoordinates(
      String placeId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/location/place-details'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'place_id': placeId}),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Place details error: $e');
    }
    return null;
  }

  // ── Get workers near a location (for map pins) ────────────────
  static Future<List<Map<String, dynamic>>> getNearbyWorkers({
    required double lat,
    required double lng,
    double radiusKm = 20.0,
    List<String>? services,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/location/nearby-workers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': lat,
          'lng': lng,
          'radius_km': radiusKm,
          if (services != null) 'services': services,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['workers']);
      }
    } catch (e) {
      debugPrint('Nearby workers error: $e');
    }
    return [];
  }

  // ── Get ML recommendations ────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getRecommendations({
    required String householdId,
    required String district,
    required List<String> neededServices,
    double? lat,
    double? lng,
    double? maxBudget,
    double radiusKm = 20.0,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'household_id':    householdId,
          'district':        district,
          'needed_services': neededServices,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (maxBudget != null) 'max_budget': maxBudget,
          'radius_km':       radiusKm,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['recommendations']);
      }
    } catch (e) {
      debugPrint('Recommendations error: $e');
    }
    return [];
  }

  // ── Record a completed booking (improves future recommendations) ─
  static Future<void> recordBooking({
    required String householdId,
    required String workerId,
    required double ratingGiven,
  }) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/bookings/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'household_id': householdId,
          'worker_id':    workerId,
          'rating_given': ratingGiven,
        }),
      );
    } catch (e) {
      debugPrint('Record booking error: $e');
    }
  }
}
