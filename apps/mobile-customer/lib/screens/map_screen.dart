// lib/screens/map_screen.dart
//
// Full-screen map showing nearby workers as pins.
// Tapping a pin shows worker details.
// Uses the household's GPS or typed address to center the map.

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class MapScreen extends StatefulWidget {
  final String householdId;
  final String district;

  const MapScreen({
    Key? key,
    required this.householdId,
    required this.district,
  }) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker>          _markers        = {};
  bool                 _loading        = true;
  String               _searchText     = '';
  List<Map<String, dynamic>> _suggestions = [];
  double?              _lat;
  double?              _lng;

  // Default: center of Sri Lanka
  static const LatLng _defaultCenter = LatLng(7.8731, 80.7718);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // ── Get GPS location then load workers ───────────────────────
  Future<void> _initLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      setState(() { _lat = pos.latitude; _lng = pos.longitude; });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 13),
      );
      await _loadNearbyWorkers(pos.latitude, pos.longitude);
    } else {
      setState(() => _loading = false);
    }
  }

  // ── Load worker pins ──────────────────────────────────────────
  Future<void> _loadNearbyWorkers(double lat, double lng) async {
    setState(() => _loading = true);
    final workers = await LocationService.getNearbyWorkers(lat: lat, lng: lng);
    final markers = <Marker>{};

    // Blue pin for current location
    markers.add(Marker(
      markerId: const MarkerId('me'),
      position: LatLng(lat, lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'Your Location'),
    ));

    // Worker pins
    for (final w in workers) {
      if (w['lat'] == null || w['lng'] == null) continue;
      final hue = w['verified'] == true
          ? BitmapDescriptor.hueGreen
          : BitmapDescriptor.hueOrange;
      markers.add(Marker(
        markerId: MarkerId(w['worker_id']),
        position: LatLng(w['lat'], w['lng']),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: w['name'],
          snippet:
              '⭐ ${w['rating']} · LKR ${w['hourly_rate']}/hr · ${w['distance_text'] ?? ''}',
          onTap: () => _showWorkerSheet(w),
        ),
      ));
    }

    setState(() { _markers = markers; _loading = false; });
  }

  // ── Address autocomplete ──────────────────────────────────────
  Future<void> _onSearchChanged(String text) async {
    if (text.length < 3) { setState(() => _suggestions = []); return; }
    final s = await LocationService.getAddressSuggestions(text);
    setState(() => _suggestions = s);
  }

  Future<void> _onSuggestionTapped(Map<String, dynamic> s) async {
    final details = await LocationService.getPlaceCoordinates(s['place_id']);
    if (details == null) return;
    final lat = details['lat'] as double;
    final lng = details['lng'] as double;
    setState(() { _lat = lat; _lng = lng; _suggestions = []; _searchText = s['description']; });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14));
    await _loadNearbyWorkers(lat, lng);
  }

  // ── Worker bottom sheet ───────────────────────────────────────
  void _showWorkerSheet(Map<String, dynamic> w) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.green.shade100,
              child: Text(w['name'][0], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(w['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                if (w['verified'] == true)
                  const Icon(Icons.verified, color: Colors.blue, size: 18),
              ]),
              Text(w['district'] ?? '', style: TextStyle(color: Colors.grey.shade600)),
            ])),
          ]),
          const SizedBox(height: 16),
          _infoRow(Icons.star,         '${w['rating']}/5  (${w['total_reviews']} reviews)'),
          _infoRow(Icons.attach_money, 'LKR ${w['hourly_rate']}/hr'),
          _infoRow(Icons.location_on,  w['distance_text'] ?? 'Distance unknown'),
          _infoRow(Icons.build,        (w['services'] as List).join(', ')),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: navigate to full worker profile / booking screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Profile & Book', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Icon(icon, size: 18, color: Colors.grey.shade600),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
    ]),
  );

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // Map
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _defaultCenter, zoom: 8),
          onMapCreated: (c) { _mapController = c; },
          markers:          _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),

        // Search bar
        SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                onChanged:  _onSearchChanged,
                decoration: InputDecoration(
                  hintText:      'Search your address…',
                  prefixIcon:    const Icon(Icons.search),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _searchText = ''; _suggestions = []; }))
                      : null,
                  border:        InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          // Suggestions dropdown
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final s = _suggestions[i];
                  return ListTile(
                    leading:  const Icon(Icons.location_on_outlined),
                    title:    Text(s['main_text'],  style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(s['description'], style: const TextStyle(fontSize: 12)),
                    onTap:    () => _onSuggestionTapped(s),
                  );
                },
              ),
            ),
        ])),

        // Loading overlay
        if (_loading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),

        // My location FAB
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'locate',
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _initLocation,
            child: const Icon(Icons.my_location, color: Colors.green),
          ),
        ),
      ]),
    );
  }
}
