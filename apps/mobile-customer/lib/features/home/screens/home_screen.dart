import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';

// ──────────────────────────────────────────────────────────────
// HOME SCREEN
// The main dashboard customers see. Sections from top to bottom:
//   1. Header: greeting + location badge + notification bell
//   2. Hero text: "What do you need done today?"
//   3. Search bar (tappable → navigates to search screen)
//   4. Categories: horizontal scroll of service types
//   5. Active jobs banner: gold card showing ongoing jobs count
//   6. Top rated workers: list of nearby high-rated workers
//   7. Recent jobs: latest job cards with status
// ──────────────────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    // Greeting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning,',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text('Ashen', style: AppTypography.displaySmall),
                        ],
                      ),
                    ),
                    // Location badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Colombo',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Notification bell with red dot
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Stack(
                          children: [
                            const Center(
                              child: Icon(Icons.notifications_outlined,
                                  size: 20, color: AppColors.textPrimary),
                            ),
                            // Unread notification dot
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 2. Hero Text ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'What do you need\ndone today?',
                  style: AppTypography.displayLarge,
                ),
              ),

              const SizedBox(height: 18),

              // ── 3. Search Bar (tap to navigate) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DoerSearchBar(
                  onTap: () {
                    Navigator.pushNamed(context, '/search');
                  },
                ),
              ),

              const SizedBox(height: 28),

              // ── 4. Service Categories (horizontal scroll) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(
                  title: 'Services',
                  actionText: 'See all',
                  onAction: () {},
                ),
              ),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: AppCategories.all.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final cat = AppCategories.all[index];
                    return CategoryChip(
                      category: cat,
                      compact: true,
                      onTap: () {
                        // TODO: Navigate to category detail
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              // ── 5. Active Jobs Banner ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () {
                    // TODO: Navigate to my jobs
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.work_outline_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You have 2 active jobs',
                                style: AppTypography.headlineSmall.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Track progress and chat with workers',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.white, size: 24),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── 6. Top Rated Workers ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(
                  title: 'Top rated near you',
                  actionText: 'See all',
                  onAction: () {
                    Navigator.pushNamed(context, '/browse-workers');
                  },
                ),
              ),
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
                    const SizedBox(height: 12),
                    WorkerCard(
                      name: 'Saman Fernando',
                      skill: 'Plumber',
                      badge: BadgeLevel.silver,
                      rating: 4.5,
                      distance: 3.4,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
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

              const SizedBox(height: 28),

              // ── 7. Recent Jobs ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(
                  title: 'Recent jobs',
                  actionText: 'View all',
                  onAction: () {},
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    JobCard(
                      title: 'Fix kitchen sink leak',
                      category: 'Plumbing',
                      categoryIcon: '🔧',
                      status: JobStatus.inProgress,
                      budget: 'Rs. 5,000',
                      date: 'Today',
                      workerName: 'Saman F.',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    JobCard(
                      title: 'Rewire living room',
                      category: 'Electrical',
                      categoryIcon: '⚡',
                      status: JobStatus.completed,
                      budget: 'Rs. 12,000',
                      date: 'Yesterday',
                      workerName: 'Nimal P.',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              // Bottom padding for nav bar
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
