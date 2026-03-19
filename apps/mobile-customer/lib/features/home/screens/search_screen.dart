import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';

// ──────────────────────────────────────────────────────────────
// SEARCH SCREEN
// Two states controlled by _hasQuery:
//   Empty → shows recent searches, popular services, trending
//   Typing → shows filtered categories + matching workers
// The search bar auto-focuses when this screen opens.
// ──────────────────────────────────────────────────────────────
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  bool _hasQuery = false;

  final _recentSearches = [
    'Plumber near me',
    'Electrician Colombo',
    'House cleaning',
    'AC repair',
  ];

  final _popularServices = [
    AppCategories.all[0], // Plumbing
    AppCategories.all[1], // Electrical
    AppCategories.all[2], // Cleaning
    AppCategories.all[4], // Gardening
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        // Search input in the app bar
        title: SizedBox(
          height: 44,
          child: TextField(
            controller: _controller,
            autofocus: true, // keyboard opens immediately
            style: AppTypography.bodyMedium,
            onChanged: (v) => setState(() => _hasQuery = v.isNotEmpty),
            decoration: InputDecoration(
              hintText: 'Search services or workers...',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 20, color: AppColors.textTertiary),
              // Show X button only when there's text
              suffixIcon: _hasQuery
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textTertiary),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _hasQuery = false);
                      },
                    )
                  : null,
              hintStyle: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textTertiary),
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      // Toggle between suggestions and results
      body: _hasQuery ? _buildResults() : _buildSuggestions(),
    );
  }

  // ── Empty state: suggestions ──
  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches header with clear button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Searches', style: AppTypography.headlineMedium),
              GestureDetector(
                onTap: () => setState(() => _recentSearches.clear()),
                child: Text(
                  'Clear',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Each recent search is tappable
          ..._recentSearches.map((search) => GestureDetector(
                onTap: () {
                  _controller.text = search;
                  setState(() => _hasQuery = true);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded,
                          size: 18, color: AppColors.textTertiary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(search, style: AppTypography.bodyMedium),
                      ),
                      const Icon(Icons.north_west_rounded,
                          size: 14, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 28),

          // Popular services as colored chips
          Text('Popular Services', style: AppTypography.headlineMedium),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _popularServices
                .map((cat) => GestureDetector(
                      onTap: () {
                        _controller.text = cat.name;
                        setState(() => _hasQuery = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: cat.iconBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat.icon,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(cat.name, style: AppTypography.labelLarge),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 28),

          // Trending searches with rank numbers
          Text('Trending Now', style: AppTypography.headlineMedium),
          const SizedBox(height: 14),
          _TrendingItem(rank: 1, text: 'AC Repair', change: '+12%'),
          _TrendingItem(rank: 2, text: 'Pipe Leak Fix', change: '+8%'),
          _TrendingItem(rank: 3, text: 'House Painting', change: '+5%'),
          _TrendingItem(rank: 4, text: 'Roof Repair', change: 'New'),
        ],
      ),
    );
  }

  // ── Typing state: filtered results ──
  Widget _buildResults() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Matching service categories
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Services', style: AppTypography.labelMedium),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: AppCategories.all
                  .where((c) => c.name
                      .toLowerCase()
                      .contains(_controller.text.toLowerCase()))
                  .map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: cat.iconBgColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Text(cat.icon,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(cat.name,
                                    style: AppTypography.labelMedium),
                              ],
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Matching workers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Workers', style: AppTypography.labelMedium),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                WorkerCard(
                  name: 'Nimal Perera',
                  skill: 'Electrician',
                  badge: BadgeLevel.gold,
                  rating: 4.8,
                  distance: 2.1,
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                WorkerCard(
                  name: 'Saman Fernando',
                  skill: 'Plumber',
                  badge: BadgeLevel.silver,
                  rating: 4.5,
                  distance: 3.4,
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                WorkerCard(
                  name: 'Kumari Silva',
                  skill: 'House Cleaning',
                  badge: BadgeLevel.platinum,
                  rating: 4.9,
                  distance: 1.8,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Trending item row with rank number ──
class _TrendingItem extends StatelessWidget {
  final int rank;
  final String text;
  final String change;

  const _TrendingItem({
    required this.rank,
    required this.text,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Rank number (gold for top 3)
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: AppTypography.headlineMedium.copyWith(
                color: rank <= 3 ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: AppTypography.bodyMedium),
          ),
          // Change percentage badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              change,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
