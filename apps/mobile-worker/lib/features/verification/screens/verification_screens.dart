import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';

// ──────────────────────────────────────────────────────────────
// VERIFICATION SCREEN
// Worker submits identity and qualification documents:
//   - NIC (front + back photo)
//   - Qualification certificates
//   - Background check consent
// Each item shows its current status (pending/submitted/approved/rejected).
// Progress bar shows overall verification level → badge tier.
// ──────────────────────────────────────────────────────────────
class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current badge + progress
            _BadgeProgressCard(),

            const SizedBox(height: 24),

            Text('Verification Documents', style: AppTypography.headlineLarge),
            const SizedBox(height: 4),
            Text(
              'Complete each step to unlock higher trust badge levels.',
              style: AppTypography.bodySmall,
            ),

            const SizedBox(height: 16),

            // NIC Verification
            VerificationCard(
              title: 'National Identity Card',
              subtitle: 'Upload front & back of your NIC',
              status: VerificationStatus.submitted,
              icon: Icons.badge_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NicUploadScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Qualification documents
            VerificationCard(
              title: 'Qualifications & Certificates',
              subtitle: 'Upload skill certificates or trade licenses',
              status: VerificationStatus.pending,
              icon: Icons.workspace_premium_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QualificationUploadScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Background check
            VerificationCard(
              title: 'Background Check',
              subtitle: 'Police clearance certificate',
              status: VerificationStatus.pending,
              icon: Icons.security_outlined,
              onTap: () {
                _showBackgroundCheckInfo(context);
              },
            ),

            const SizedBox(height: 24),

            // Badge progression guide
            Text('Badge Levels', style: AppTypography.headlineLarge),
            const SizedBox(height: 12),
            _BadgeLevelGuide(),
          ],
        ),
      ),
    );
  }

  void _showBackgroundCheckInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Background Check', style: AppTypography.headlineLarge),
            const SizedBox(height: 12),
            Text(
              'A background check requires submitting a Police Clearance Certificate (PCC) from your local police station.\n\nThis is reviewed manually by our team within 3-5 business days.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            DoerButton(
              label: 'Upload Police Certificate',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// BADGE PROGRESS CARD
// Shows current badge and progress to next level.
// ──────────────────────────────────────────────────────────────
class _BadgeProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const currentBadge = BadgeLevel.trainee;
    const nextBadge = BadgeLevel.bronze;
    const progress = 0.4; // 40% toward bronze

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BadgePill(badge: currentBadge),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Level', style: AppTypography.labelSmall),
                    Text(BadgeLevel.label(currentBadge),
                        style: AppTypography.headlineMedium),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Next Level', style: AppTypography.labelSmall),
                  BadgePill(badge: nextBadge),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceVariant,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Submit NIC to reach Bronze level',
            style: AppTypography.labelSmall,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// BADGE LEVEL GUIDE
// Shows what each badge requires.
// ──────────────────────────────────────────────────────────────
class _BadgeLevelGuide extends StatelessWidget {
  static const _levels = [
    _BadgeInfo(BadgeLevel.trainee, 'Account created', 'Default level'),
    _BadgeInfo(BadgeLevel.bronze, 'NIC verified', 'Identity confirmed'),
    _BadgeInfo(BadgeLevel.silver, 'NIC + Qualifications', 'Skills verified'),
    _BadgeInfo(BadgeLevel.gold, 'All docs + 10 reviews ≥ 4.0', 'Trusted worker'),
    _BadgeInfo(BadgeLevel.platinum, 'Gold + background check', 'Elite worker'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _levels.map((l) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              BadgePill(badge: l.badge),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.requirement, style: AppTypography.headlineSmall),
                    Text(l.description, style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _BadgeInfo {
  final String badge;
  final String requirement;
  final String description;
  const _BadgeInfo(this.badge, this.requirement, this.description);
}

// ──────────────────────────────────────────────────────────────
// NIC UPLOAD SCREEN
// ──────────────────────────────────────────────────────────────
class NicUploadScreen extends StatefulWidget {
  const NicUploadScreen({super.key});

  @override
  State<NicUploadScreen> createState() => _NicUploadScreenState();
}

class _NicUploadScreenState extends State<NicUploadScreen> {
  bool _frontUploaded = false;
  bool _backUploaded = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NIC Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload your NIC', style: AppTypography.displaySmall),
            const SizedBox(height: 8),
            Text(
              'We need both sides of your National Identity Card to verify your identity.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),

            const SizedBox(height: 24),

            _UploadCard(
              label: 'NIC Front',
              icon: Icons.credit_card_outlined,
              isUploaded: _frontUploaded,
              onTap: () => setState(() => _frontUploaded = true),
            ),

            const SizedBox(height: 12),

            _UploadCard(
              label: 'NIC Back',
              icon: Icons.credit_card_outlined,
              isUploaded: _backUploaded,
              onTap: () => setState(() => _backUploaded = true),
            ),

            const Spacer(),

            DoerButton(
              label: 'Submit for Verification',
              isLoading: _isSubmitting,
              onPressed: (_frontUploaded && _backUploaded)
                  ? () {
                      setState(() => _isSubmitting = true);
                      // TODO: Upload NIC to backend
                    }
                  : null,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// QUALIFICATION UPLOAD SCREEN
// ──────────────────────────────────────────────────────────────
class QualificationUploadScreen extends StatefulWidget {
  const QualificationUploadScreen({super.key});

  @override
  State<QualificationUploadScreen> createState() =>
      _QualificationUploadScreenState();
}

class _QualificationUploadScreenState
    extends State<QualificationUploadScreen> {
  final List<String> _uploadedDocs = [];
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Qualifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Qualification Documents', style: AppTypography.displaySmall),
            const SizedBox(height: 8),
            Text(
              'Upload any certificates, trade licenses, or training records relevant to your services.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),

            const SizedBox(height: 24),

            // Uploaded docs list
            ..._uploadedDocs.map((doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined,
                            color: AppColors.success, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(doc,
                                style: AppTypography.bodyMedium)),
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 18),
                      ],
                    ),
                  ),
                )),

            // Add document button
            GestureDetector(
              onTap: () {
                setState(() {
                  _uploadedDocs.add('Certificate ${_uploadedDocs.length + 1}.pdf');
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.border, style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline_rounded,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Add Document',
                      style: AppTypography.labelLarge
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            DoerButton(
              label: 'Submit Documents',
              isLoading: _isSubmitting,
              onPressed: _uploadedDocs.isNotEmpty
                  ? () {
                      setState(() => _isSubmitting = true);
                      // TODO: Upload documents to backend
                    }
                  : null,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// UPLOAD CARD WIDGET
// ──────────────────────────────────────────────────────────────
class _UploadCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isUploaded;
  final VoidCallback onTap;

  const _UploadCard({
    required this.label,
    required this.icon,
    required this.isUploaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploaded ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isUploaded ? AppColors.successLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUploaded
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isUploaded ? Icons.check_circle_rounded : icon,
              size: 36,
              color: isUploaded ? AppColors.success : AppColors.textTertiary,
            ),
            const SizedBox(height: 10),
            Text(
              isUploaded ? '$label uploaded' : 'Tap to upload $label',
              style: AppTypography.headlineSmall.copyWith(
                color: isUploaded ? AppColors.success : AppColors.textSecondary,
              ),
            ),
            if (!isUploaded) ...[
              const SizedBox(height: 4),
              Text(
                'JPG, PNG or PDF • Max 5MB',
                style: AppTypography.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
