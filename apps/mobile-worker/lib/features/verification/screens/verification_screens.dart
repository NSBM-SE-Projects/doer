import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/api_service.dart';

// ──────────────────────────────────────────────────────────────
// VERIFICATION SCREEN
// Worker submits identity and qualification documents:
//   - NIC (front + back photo)
//   - Qualification certificates
//   - Background check consent
// Each item shows its current status (pending/submitted/approved/rejected).
// Progress bar shows overall verification level -> badge tier.
// ──────────────────────────────────────────────────────────────
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _api = ApiService();
  bool _loading = true;
  String _verificationStatus = 'NOT_SUBMITTED';
  String _badgeLevel = BadgeLevel.trainee;
  String? _rejectionReason;
  String? _nicFrontUrl;
  String? _nicBackUrl;
  bool _nicVerified = false;
  bool _qualificationsVerified = false;
  String? _backgroundCheckUrl;
  bool _backgroundCheckVerified = false;
  List<dynamic> _qualificationDocs = [];
  String? _nextBadge;
  String _nextBadgeHint = '';

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getVerificationStatus();
      setState(() {
        _verificationStatus = data['verificationStatus'] ?? 'NOT_SUBMITTED';
        _badgeLevel = _mapBadgeLevel(data['badgeLevel']);
        _rejectionReason = data['rejectionReason'];
        _nicFrontUrl = data['nicFrontUrl'];
        _nicBackUrl = data['nicBackUrl'];
        _nicVerified = data['nicVerified'] == true;
        _qualificationsVerified = data['qualificationsVerified'] == true;
        _backgroundCheckUrl = data['backgroundCheckUrl'];
        _backgroundCheckVerified = data['backgroundCheckVerified'] == true;
        _qualificationDocs = data['qualificationDocs'] ?? [];
        _nextBadge = data['nextBadge'];
        _nextBadgeHint = data['nextBadgeHint'] ?? '';
      });
    } catch (e) {
      // If endpoint not available yet, use defaults
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapBadgeLevel(String? level) {
    switch (level) {
      case 'TRAINEE': return BadgeLevel.trainee;
      case 'BRONZE': return BadgeLevel.bronze;
      case 'SILVER': return BadgeLevel.silver;
      case 'GOLD': return BadgeLevel.gold;
      case 'PLATINUM': return BadgeLevel.platinum;
      default: return BadgeLevel.trainee;
    }
  }

  String _mapVerificationDisplay(String status) {
    switch (status) {
      case 'NOT_SUBMITTED': return VerificationStatus.pending;
      case 'PENDING': return VerificationStatus.submitted;
      case 'VERIFIED': return VerificationStatus.approved;
      case 'REJECTED': return VerificationStatus.rejected;
      default: return VerificationStatus.pending;
    }
  }

  double _badgeProgress() {
    const levels = [BadgeLevel.trainee, BadgeLevel.bronze, BadgeLevel.silver, BadgeLevel.gold, BadgeLevel.platinum];
    final idx = levels.indexOf(_badgeLevel);
    if (idx < 0) return 0;
    return idx / (levels.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Verification')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
            _buildBadgeProgressCard(),

            // Rejection banner
            if (_verificationStatus == 'REJECTED' && _rejectionReason != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Verification Rejected', style: AppTypography.headlineSmall.copyWith(color: AppColors.error)),
                          const SizedBox(height: 4),
                          Text(_rejectionReason!, style: AppTypography.bodySmall),
                          const SizedBox(height: 8),
                          Text('Please re-submit your documents.', style: AppTypography.labelSmall.copyWith(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
              subtitle: _nicVerified ? 'Verified' : _nicFrontUrl != null ? 'Pending review' : 'Upload front & back of your NIC',
              status: _nicVerified ? VerificationStatus.approved : _nicFrontUrl != null ? VerificationStatus.submitted : VerificationStatus.pending,
              icon: Icons.badge_outlined,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NicUploadScreen()),
                );
                if (result == true) _loadStatus();
              },
            ),

            const SizedBox(height: 12),

            // Qualification documents
            VerificationCard(
              title: 'Qualifications & Certificates',
              subtitle: _qualificationsVerified ? 'Verified' : _qualificationDocs.isNotEmpty
                  ? '${_qualificationDocs.length} document(s) — pending review'
                  : 'Upload skill certificates or trade licenses',
              status: _qualificationsVerified ? VerificationStatus.approved : _qualificationDocs.isNotEmpty ? VerificationStatus.submitted : VerificationStatus.pending,
              icon: Icons.workspace_premium_outlined,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QualificationUploadScreen()),
                );
                if (result == true) _loadStatus();
              },
            ),

            const SizedBox(height: 12),

            // Background check
            VerificationCard(
              title: 'Background Check',
              subtitle: _backgroundCheckVerified ? 'Verified' : _backgroundCheckUrl != null ? 'Pending review' : 'Police clearance certificate',
              status: _backgroundCheckVerified ? VerificationStatus.approved : _backgroundCheckUrl != null ? VerificationStatus.submitted : VerificationStatus.pending,
              icon: Icons.security_outlined,
              onTap: () {
                _showBackgroundCheckUpload(context);
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

  Widget _buildBadgeProgressCard() {
    const badgeOrder = [BadgeLevel.trainee, BadgeLevel.bronze, BadgeLevel.silver, BadgeLevel.gold, BadgeLevel.platinum];
    final currentIndex = badgeOrder.indexOf(_badgeLevel);
    final nextBadgeLabel = currentIndex < badgeOrder.length - 1 ? badgeOrder[currentIndex + 1] : null;

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
              BadgePill(badge: _badgeLevel),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Level', style: AppTypography.labelSmall),
                    Text(BadgeLevel.label(_badgeLevel), style: AppTypography.headlineMedium),
                  ],
                ),
              ),
              if (nextBadgeLabel != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Next Level', style: AppTypography.labelSmall),
                    BadgePill(badge: nextBadgeLabel),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _badgeProgress(),
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _nextBadgeHint.isNotEmpty ? _nextBadgeHint : 'Submit documents to progress',
            style: AppTypography.labelSmall,
          ),
        ],
      ),
    );
  }

  void _showBackgroundCheckUpload(BuildContext context) {
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
            if (_backgroundCheckUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _backgroundCheckVerified ? AppColors.successLight : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(
                    _backgroundCheckVerified ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                    color: _backgroundCheckVerified ? AppColors.success : AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _backgroundCheckVerified ? 'Certificate verified' : 'Certificate uploaded — pending review',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
                          body: Center(child: InteractiveViewer(child: Image.network(_backgroundCheckUrl!, fit: BoxFit.contain))),
                        ),
                      ));
                    },
                    child: Text('View', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Text(
                'A background check requires submitting a Police Clearance Certificate (PCC) from your local police station.\n\nThis is reviewed manually by our team within 3-5 business days.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 20),
            DoerButton(
              label: _backgroundCheckUrl != null ? 'Re-upload Certificate' : 'Upload Police Certificate',
              onPressed: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (picked == null) return;
                try {
                  await _api.uploadVerificationDocuments(backgroundCheckPath: picked.path);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Background check uploaded successfully')),
                    );
                    _loadStatus();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Upload failed: ${ApiService.errorMessage(e)}')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
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
    _BadgeInfo(BadgeLevel.gold, 'All docs + 10 jobs + 4.0 rating', 'Trusted worker'),
    _BadgeInfo(BadgeLevel.platinum, 'Gold + background check + 50 jobs', 'Elite worker'),
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
  File? _frontFile;
  File? _backFile;
  bool _isSubmitting = false;
  final _nicController = TextEditingController();
  final _picker = ImagePicker();
  String? _existingFrontUrl;
  String? _existingBackUrl;
  bool _nicVerified = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final data = await ApiService().getVerificationStatus();
      if (mounted) {
        setState(() {
          _nicController.text = data['nicNumber'] ?? '';
          _existingFrontUrl = data['nicFrontUrl'];
          _existingBackUrl = data['nicBackUrl'];
          _nicVerified = data['nicVerified'] == true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nicController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      if (isFront) {
        _frontFile = File(picked.path);
      } else {
        _backFile = File(picked.path);
      }
    });
  }

  Future<void> _submitNic() async {
    final nicNumber = _nicController.text.trim();
    if (nicNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your NIC number')),
      );
      return;
    }
    if (_frontFile == null || _backFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both NIC front and back')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // First update NIC number
      await ApiService().updateWorkerProfile(nicNumber: nicNumber);
      // Then upload document images
      await ApiService().uploadVerificationDocuments(
        nicFrontPath: _frontFile!.path,
        nicBackPath: _backFile!.path,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NIC submitted for verification')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${ApiService.errorMessage(e)}')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nicFilled = _nicController.text.trim().isNotEmpty;
    final canSubmit = (_frontFile != null || _backFile != null) && nicFilled;

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
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),

            const SizedBox(height: 24),

            // NIC number input
            TextField(
              controller: _nicController,
              decoration: InputDecoration(
                labelText: 'NIC Number',
                hintText: 'e.g. 200012345678 or 901234567V',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            _ImageUploadCard(
              label: 'NIC Front',
              icon: Icons.credit_card_outlined,
              file: _frontFile,
              existingUrl: _existingFrontUrl,
              onTap: () => _pickImage(true),
            ),

            const SizedBox(height: 12),

            _ImageUploadCard(
              label: 'NIC Back',
              icon: Icons.credit_card_outlined,
              file: _backFile,
              existingUrl: _existingBackUrl,
              onTap: () => _pickImage(false),
            ),

            if (_nicVerified)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text('NIC Verified', style: AppTypography.headlineSmall.copyWith(color: AppColors.success)),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            DoerButton(
              label: 'Submit for Verification',
              isLoading: _isSubmitting,
              onPressed: canSubmit ? _submitNic : null,
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
  final List<File> _selectedFiles = [];
  List<dynamic> _existingDocs = [];
  bool _qualificationsVerified = false;
  bool _isSubmitting = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final data = await ApiService().getVerificationStatus();
      if (mounted) {
        setState(() {
          _existingDocs = data['qualificationDocs'] ?? [];
          _qualificationsVerified = data['qualificationsVerified'] == true;
        });
      }
    } catch (_) {}
  }

  Future<void> _addDocument() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _selectedFiles.add(File(picked.path)));
  }

  Future<void> _submitDocuments() async {
    if (_selectedFiles.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await ApiService().uploadVerificationDocuments(
        qualificationPaths: _selectedFiles.map((f) => f.path).toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Qualifications submitted for review')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${ApiService.errorMessage(e)}')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

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
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),

            if (_qualificationsVerified)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text('Qualifications Verified', style: AppTypography.headlineSmall.copyWith(color: AppColors.success)),
                  ]),
                ),
              ),

            const SizedBox(height: 24),

            // Existing uploaded docs
            if (_existingDocs.isNotEmpty) ...[
              Text('Previously Uploaded', style: AppTypography.labelMedium),
              const SizedBox(height: 8),
              ..._existingDocs.map((doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        if (doc['url'] != null) {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => Scaffold(
                              backgroundColor: Colors.black,
                              appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
                              body: Center(child: InteractiveViewer(child: Image.network(doc['url'], fit: BoxFit.contain))),
                            ),
                          ));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(children: [
                          const Icon(Icons.description_outlined, size: 20, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(child: Text(doc['title'] ?? 'Document', style: AppTypography.bodyMedium)),
                          const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.textTertiary),
                        ]),
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // Selected files list
            ..._selectedFiles.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(entry.value, width: 40, height: 40, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.value.path.split('/').last,
                            style: AppTypography.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                          onPressed: () => setState(() => _selectedFiles.removeAt(entry.key)),
                        ),
                      ],
                    ),
                  ),
                )),

            // Add document button
            GestureDetector(
              onTap: _addDocument,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Add Document',
                      style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            DoerButton(
              label: 'Submit Documents',
              isLoading: _isSubmitting,
              onPressed: _selectedFiles.isNotEmpty ? _submitDocuments : null,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// IMAGE UPLOAD CARD (with preview)
// ──────────────────────────────────────────────────────────────
class _ImageUploadCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final File? file;
  final String? existingUrl;
  final VoidCallback onTap;

  const _ImageUploadCard({
    required this.label,
    required this.icon,
    required this.file,
    this.existingUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocal = file != null;
    final hasRemote = existingUrl != null && existingUrl!.isNotEmpty;
    final hasImage = hasLocal || hasRemote;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hasImage ? AppColors.successLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: hasImage
            ? Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: hasLocal
                        ? Image.file(file!, width: 60, height: 60, fit: BoxFit.cover)
                        : Image.network(existingUrl!, width: 60, height: 60, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60, height: 60, color: AppColors.surfaceVariant,
                              child: const Icon(Icons.image_outlined, color: AppColors.textTertiary),
                            )),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hasLocal ? '$label ready to upload' : '$label uploaded',
                            style: AppTypography.headlineSmall.copyWith(color: AppColors.success)),
                        const SizedBox(height: 2),
                        Text('Tap to change', style: AppTypography.labelSmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                ],
              )
            : Column(
                children: [
                  Icon(icon, size: 36, color: AppColors.textTertiary),
                  const SizedBox(height: 10),
                  Text(
                    'Tap to upload $label',
                    style: AppTypography.headlineSmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text('JPG, PNG or PDF - Max 5MB', style: AppTypography.labelSmall),
                ],
              ),
      ),
    );
  }
}
