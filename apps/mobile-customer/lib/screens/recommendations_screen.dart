// lib/screens/recommendations_screen.dart
//
// Shows ML-ranked worker cards with match score,
// distance, services, rating and a Book button.

import 'package:flutter/material.dart';
import '../services/location_service.dart';

class RecommendationsScreen extends StatefulWidget {
  final String householdId;
  final String district;
  final List<String> neededServices;

  const RecommendationsScreen({
    super.key,
    required this.householdId,
    required this.district,
    required this.neededServices,
  });

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  List<Map<String, dynamic>> _workers = [];
  bool _loading = true;
  String _error  = '';

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() { _loading = true; _error = ''; });
    try {
      // Try to get GPS for better distance-based recommendations
      final pos = await LocationService.getCurrentPosition();
      final results = await LocationService.getRecommendations(
        householdId:    widget.householdId,
        district:       widget.district,
        neededServices: widget.neededServices,
        lat:            pos?.latitude,
        lng:            pos?.longitude,
      );
      setState(() { _workers = results; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Could not load recommendations. Please try again.'; _loading = false; });
    }
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Workers'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRecommendations),
        ],
      ),
      body: _loading
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.green),
                SizedBox(height: 16),
                Text('Finding best workers near you…'),
              ],
            ))
          : _error.isNotEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(_error, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadRecommendations, child: const Text('Retry')),
                ]))
              : _workers.isEmpty
                  ? const Center(child: Text('No workers found in your area.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _workers.length,
                      itemBuilder: (_, i) => _WorkerCard(
                        worker: _workers[i],
                        rank:   i + 1,
                      ),
                    ),
    );
  }
}

// ── Worker Card Widget ────────────────────────────────────────────
class _WorkerCard extends StatelessWidget {
  final Map<String, dynamic> worker;
  final int rank;

  const _WorkerCard({required this.worker, required this.rank});

  @override
  Widget build(BuildContext context) {
    final score   = worker['match_score'] ?? 0;
    final reasons = List<String>.from(worker['why_recommended'] ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            // Rank badge
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: rank == 1 ? Colors.amber : rank == 2 ? Colors.grey.shade300 : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('#$rank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 10),
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.green.shade100,
              child: Text(
                worker['name'][0],
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade700),
              ),
            ),
            const SizedBox(width: 12),
            // Name + district
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(worker['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                if (worker['verified'] == true)
                  const Icon(Icons.verified, color: Colors.blue, size: 16),
              ]),
              Text(worker['district'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ])),
            // Match score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _scoreColor(score).withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _scoreColor(score).withValues(alpha:0.4)),
              ),
              child: Text(
                '$score%',
                style: TextStyle(color: _scoreColor(score), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ]),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Stats row
          Row(children: [
            _stat(Icons.star,         '${worker['rating']}/5',                Colors.amber),
            _stat(Icons.attach_money, 'LKR ${worker['hourly_rate']}/hr',      Colors.green),
            if (worker['distance_km'] != null)
              _stat(Icons.directions_car, worker['duration_text'] ?? '',       Colors.blue),
          ]),

          const SizedBox(height: 10),

          // Services chips
          Wrap(
            spacing: 6, runSpacing: 4,
            children: List<String>.from(worker['services'] ?? []).map((s) => Chip(
              label: Text(s, style: const TextStyle(fontSize: 11)),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: Colors.green.shade50,
            )).toList(),
          ),

          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Why recommended
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: reasons.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(r, style: const TextStyle(fontSize: 12)),
                )).toList(),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Book button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: navigate to booking screen with worker data
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Booking ${worker['name']}…')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Book Now', style: TextStyle(color: Colors.white, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stat(IconData icon, String text, Color color) => Expanded(
    child: Row(children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 4),
      Flexible(child: Text(text, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
    ]),
  );

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.grey;
  }
}
