import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';

/// Full location picker with Google Map + Places Autocomplete search.
/// Returns {address, lat, lng} when user confirms.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _searchController = TextEditingController();
  final Completer<GoogleMapController> _mapController = Completer();

  // Default: Colombo, Sri Lanka
  LatLng _selectedPosition = const LatLng(6.9271, 79.8612);
  String? _selectedAddress;
  bool _isLoadingAddress = false;
  bool _showSearch = false;
  List<dynamic> _predictions = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _reverseGeocodeSelected();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _selectedPosition = LatLng(position.latitude, position.longitude);
      });
      _moveCamera(_selectedPosition);
      _reverseGeocodeSelected();
    } catch (_) {
      _reverseGeocodeSelected();
    }
  }

  Future<void> _moveCamera(LatLng pos) async {
    if (_mapController.isCompleted) {
      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
    }
  }

  Future<void> _reverseGeocodeSelected() async {
    setState(() => _isLoadingAddress = true);
    try {
      final result = await ApiService().reverseGeocode(
        _selectedPosition.latitude, _selectedPosition.longitude,
      );
      setState(() {
        _selectedAddress = result['address'];
        _isLoadingAddress = false;
      });
    } catch (_) {
      setState(() {
        _selectedAddress = '${_selectedPosition.latitude.toStringAsFixed(5)}, ${_selectedPosition.longitude.toStringAsFixed(5)}';
        _isLoadingAddress = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.length < 3) {
      setState(() => _predictions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      try {
        _predictions = await ApiService().placesAutocomplete(query);
      } catch (_) {
        _predictions = [];
      }
      if (mounted) setState(() => _isSearching = false);
    });
  }

  Future<void> _selectPrediction(String placeId, String description) async {
    try {
      final details = await ApiService().getPlaceDetails(placeId);
      final lat = (details['lat'] as num).toDouble();
      final lng = (details['lng'] as num).toDouble();
      setState(() {
        _selectedPosition = LatLng(lat, lng);
        _selectedAddress = details['address'] ?? description;
        _showSearch = false;
        _searchController.clear();
        _predictions = [];
      });
      _moveCamera(_selectedPosition);
    } catch (_) {}
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'address': _selectedAddress ?? 'Selected location',
      'lat': _selectedPosition.latitude,
      'lng': _selectedPosition.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
            onCameraMove: (position) {
              _selectedPosition = position.target;
            },
            onCameraIdle: () {
              _reverseGeocodeSelected();
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Center pin (always in the middle of the map)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36),
              child: Icon(Icons.location_on, color: AppColors.primary, size: 48),
            ),
          ),

          // Top bar with search
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: AppTypography.bodyMedium,
                              onChanged: (q) {
                                setState(() => _showSearch = q.isNotEmpty);
                                _onSearchChanged(q);
                              },
                              onTap: () => setState(() => _showSearch = true),
                              decoration: const InputDecoration(
                                hintText: 'Search address...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() { _showSearch = false; _predictions = []; });
                              },
                            ),
                        ],
                      ),
                    ),

                    // Search results dropdown
                    if (_showSearch && (_predictions.isNotEmpty || _isSearching))
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        constraints: const BoxConstraints(maxHeight: 250),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10, offset: const Offset(0, 2))],
                        ),
                        child: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: _predictions.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final p = _predictions[i];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.location_on_outlined,
                                      color: AppColors.primary, size: 18),
                                  title: Text(p['description'] ?? '',
                                      style: AppTypography.bodySmall, maxLines: 2),
                                  onTap: () => _selectPrediction(p['placeId'], p['description']),
                                );
                              },
                            ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // My location FAB
          Positioned(
            right: 16, bottom: 180,
            child: FloatingActionButton.small(
              heroTag: 'myLocation',
              backgroundColor: AppColors.surface,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
            ),
          ),

          // Bottom card with address + confirm button
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isLoadingAddress
                          ? Text('Finding address...', style: AppTypography.bodySmall)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Selected Location', style: AppTypography.labelMedium),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedAddress ?? 'Move the map to select',
                                  style: AppTypography.bodySmall,
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _selectedAddress != null ? _confirmLocation : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Confirm Location', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
