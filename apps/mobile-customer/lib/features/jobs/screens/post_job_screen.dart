import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/api_service.dart';
import 'location_picker_screen.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  int _step = 0;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  String? _selectedCategory;
  String? _selectedCategoryId;
  String _urgency = 'NORMAL';
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;
  bool _isSubmitting = false;
  List<dynamic> _apiCategories = [];

  // Location
  String? _address;
  double? _latitude;
  double? _longitude;

  // Photos
  final List<XFile> _photos = [];
  final _picker = ImagePicker();

  final _steps = ['Category', 'Details', 'Budget & Time', 'Photos', 'Review'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      _apiCategories = await ApiService().getCategories();
      if (mounted) setState(() {});
    } catch (_) {
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }

  /// Validate current step before proceeding
  bool _validateStep() {
    switch (_step) {
      case 0: // Category
        if (_selectedCategory == null) {
          _showError('Please select a service category');
          return false;
        }
        return true;
      case 1: // Details
        if (_titleController.text.trim().isEmpty) {
          _showError('Please enter a job title');
          return false;
        }
        if (_titleController.text.trim().length < 5) {
          _showError('Job title must be at least 5 characters');
          return false;
        }
        if (_descController.text.trim().isEmpty) {
          _showError('Please describe the job');
          return false;
        }
        if (_descController.text.trim().length < 10) {
          _showError('Description must be at least 10 characters');
          return false;
        }
        if (_address == null) {
          _showError('Please select a location');
          return false;
        }
        return true;
      case 2: // Budget
        if (_budgetMinController.text.isEmpty && _budgetMaxController.text.isEmpty) {
          _showError('Please enter a budget range');
          return false;
        }
        final min = double.tryParse(_budgetMinController.text);
        final max = double.tryParse(_budgetMaxController.text);
        if (min != null && max != null && min > max) {
          _showError('Minimum budget cannot exceed maximum');
          return false;
        }
        return true;
      case 3: // Photos (optional)
        return true;
      default:
        return true;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  Future<void> _pickPhotos() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    if (source == ImageSource.camera) {
      final photo = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1200, imageQuality: 80);
      if (photo != null) setState(() => _photos.add(photo));
    } else {
      final photos = await _picker.pickMultiImage(maxWidth: 1200, imageQuality: 80);
      if (photos.isNotEmpty) setState(() => _photos.addAll(photos));
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (result != null) {
      setState(() {
        _address = result['address'];
        _latitude = result['lat']?.toDouble();
        _longitude = result['lng']?.toDouble();
      });
    }
  }

  Future<void> _submitJob() async {
    String? catId = _selectedCategoryId;
    if (catId == null && _selectedCategory != null) {
      // Retry loading categories if we don't have them yet
      if (_apiCategories.isEmpty) {
        try {
          _apiCategories = await ApiService().getCategories();
        } catch (_) {}
      }
      final match = _apiCategories.where((c) =>
        (c['name'] as String).toLowerCase() == _selectedCategory!.toLowerCase());
      if (match.isNotEmpty) catId = match.first['id'];
    }
    if (catId == null) {
      _showError('Category not available. Check your internet connection and try again.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final budgetMin = double.tryParse(_budgetMinController.text);
      final budgetMax = double.tryParse(_budgetMaxController.text);

      DateTime? scheduledAt;
      if (_preferredDate != null) {
        final time = _preferredTime ?? const TimeOfDay(hour: 9, minute: 0);
        scheduledAt = DateTime(
          _preferredDate!.year, _preferredDate!.month, _preferredDate!.day,
          time.hour, time.minute,
        );
      }

      // Upload photos to Cloudinary if any
      List<String>? imageUrls;
      if (_photos.isNotEmpty) {
        try {
          final base64Images = <String>[];
          for (final photo in _photos) {
            final bytes = await File(photo.path).readAsBytes();
            final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
            base64Images.add(b64);
          }
          imageUrls = await ApiService().uploadImages(base64Images);
        } catch (_) {
          // Continue without images if upload fails
        }
      }

      await ApiService().createJob(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        categoryId: catId,
        price: budgetMax ?? budgetMin,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        urgency: _urgency,
        latitude: _latitude,
        longitude: _longitude,
        address: _address,
        scheduledAt: scheduledAt?.toUtc().toIso8601String(),
        imageUrls: imageUrls,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully!'), backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showError(ApiService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Post a Job'),
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: List.generate(_steps.length, (i) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.only(right: i < _steps.length - 1 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: i <= _step ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Step ${_step + 1} of ${_steps.length}', style: AppTypography.labelSmall),
                    Text(_steps[_step], style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStep(),
            ),
          ),

          // Bottom buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: DoerButton(
                      label: 'Back',
                      isOutlined: true,
                      onPressed: () => setState(() => _step--),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: DoerButton(
                    label: _step == _steps.length - 1 ? 'Post Job' : 'Continue',
                    isLoading: _isSubmitting,
                    onPressed: () async {
                      if (_step < _steps.length - 1) {
                        if (_validateStep()) setState(() => _step++);
                      } else {
                        await _submitJob();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildCategoryStep();
      case 1: return _buildDetailsStep();
      case 2: return _buildBudgetStep();
      case 3: return _buildPhotosStep();
      case 4: return _buildReviewStep();
      default: return const SizedBox();
    }
  }

  // ── Step 1: Category ──
  Widget _buildCategoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What service do you need?', style: AppTypography.displaySmall),
        const SizedBox(height: 8),
        Text('Choose the category that best matches your job.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        ...AppCategories.all.map((cat) {
          final selected = _selectedCategory == cat.name;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = cat.name);
                // Try to match API category ID
                final match = _apiCategories.where((c) =>
                  (c['name'] as String).toLowerCase() == cat.name.toLowerCase());
                if (match.isNotEmpty) _selectedCategoryId = match.first['id'];
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? cat.iconBgColor : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(cat.icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(child: Text(cat.name, style: AppTypography.headlineMedium)),
                    if (selected)
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Step 2: Details + Location ──
  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Describe your job', style: AppTypography.displaySmall),
        const SizedBox(height: 8),
        Text('Provide details to help workers understand the job.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Text('Job Title *', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          style: AppTypography.bodyMedium,
          decoration: const InputDecoration(hintText: 'e.g. Fix kitchen sink leak'),
        ),
        const SizedBox(height: 20),
        Text('Description *', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _descController,
          style: AppTypography.bodyMedium,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Describe the issue in detail. What needs to be done?',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        Text('Location *', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openLocationPicker,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _address != null ? AppColors.primary : AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _address != null ? 'Location selected' : 'Select location',
                        style: AppTypography.headlineSmall,
                      ),
                      Text(
                        _address ?? 'Tap to search for an address',
                        style: AppTypography.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  _address != null ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                  color: _address != null ? AppColors.success : AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: Budget & Schedule ──
  Widget _buildBudgetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budget & Schedule', style: AppTypography.displaySmall),
        const SizedBox(height: 8),
        Text('Set your budget range and preferred time.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Text('Budget Range (LKR) *', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _budgetMinController,
                keyboardType: TextInputType.number,
                style: AppTypography.bodyMedium,
                decoration: const InputDecoration(hintText: 'Min'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('—', style: TextStyle(color: AppColors.textTertiary)),
            ),
            Expanded(
              child: TextField(
                controller: _budgetMaxController,
                keyboardType: TextInputType.number,
                style: AppTypography.bodyMedium,
                decoration: const InputDecoration(hintText: 'Max'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Urgency', style: AppTypography.labelMedium),
        const SizedBox(height: 10),
        Row(
          children: [
            _UrgencyChip(label: 'Low', icon: Icons.schedule_outlined,
                selected: _urgency == 'LOW', onTap: () => setState(() => _urgency = 'LOW')),
            const SizedBox(width: 8),
            _UrgencyChip(label: 'Normal', icon: Icons.access_time_rounded,
                selected: _urgency == 'NORMAL', onTap: () => setState(() => _urgency = 'NORMAL')),
            const SizedBox(width: 8),
            _UrgencyChip(label: 'Urgent', icon: Icons.bolt_rounded,
                selected: _urgency == 'URGENT', color: AppColors.warning,
                onTap: () => setState(() => _urgency = 'URGENT')),
            const SizedBox(width: 8),
            _UrgencyChip(label: 'Emergency', icon: Icons.emergency_rounded,
                selected: _urgency == 'EMERGENCY', color: AppColors.error,
                onTap: () => setState(() => _urgency = 'EMERGENCY')),
          ],
        ),
        const SizedBox(height: 24),
        Text('Preferred Date', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (date != null) setState(() => _preferredDate = date);
          },
          child: _buildDateTimeBox(
            Icons.calendar_today_outlined,
            _preferredDate != null
                ? '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}'
                : 'Select a date',
            _preferredDate != null,
          ),
        ),
        const SizedBox(height: 16),
        Text('Preferred Time', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
            if (time != null) setState(() => _preferredTime = time);
          },
          child: _buildDateTimeBox(
            Icons.access_time_rounded,
            _preferredTime != null ? _preferredTime!.format(context) : 'Select a time',
            _preferredTime != null,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeBox(IconData icon, String text, bool hasValue) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Text(text, style: AppTypography.bodyMedium.copyWith(
            color: hasValue ? AppColors.textPrimary : AppColors.textTertiary)),
        ],
      ),
    );
  }

  // ── Step 4: Photos ──
  Widget _buildPhotosStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add reference photos', style: AppTypography.displaySmall),
        const SizedBox(height: 8),
        Text('Upload photos to help workers understand the job better.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),

        // Photo grid
        if (_photos.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_photos[index].path),
                      width: double.infinity, height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _photos.removeAt(index)),
                      child: Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Upload button
        GestureDetector(
          onTap: _pickPhotos,
          child: Container(
            width: double.infinity,
            height: _photos.isEmpty ? 160 : 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_photos.isEmpty) ...[
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(_photos.isEmpty ? 'Tap to upload photos' : 'Add more photos',
                    style: AppTypography.headlineSmall),
                if (_photos.isEmpty) ...[
                  const SizedBox(height: 4),
                  Text('JPEG or PNG, max 5MB each', style: AppTypography.bodySmall),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('${_photos.length} photo${_photos.length == 1 ? '' : 's'} selected',
            style: AppTypography.labelSmall),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.infoLight, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Photos help workers estimate the job accurately and avoid pricing disputes.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.info)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 5: Review ──
  Widget _buildReviewStep() {
    final category = AppCategories.all.firstWhere(
      (c) => c.name == _selectedCategory,
      orElse: () => AppCategories.all.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review your job', style: AppTypography.displaySmall),
        const SizedBox(height: 8),
        Text('Make sure everything looks correct before posting.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: category.iconBgColor, borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text(category.icon, style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.name, style: AppTypography.labelMedium),
                        Text(_titleController.text.isEmpty ? 'No title' : _titleController.text,
                            style: AppTypography.headlineMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.borderLight),
              const SizedBox(height: 16),
              _ReviewRow(icon: Icons.description_outlined, label: 'Description',
                  value: _descController.text.isEmpty ? 'No description' : _descController.text),
              const SizedBox(height: 14),
              _ReviewRow(icon: Icons.location_on_outlined, label: 'Location',
                  value: _address ?? 'Not set'),
              const SizedBox(height: 14),
              _ReviewRow(icon: Icons.account_balance_wallet_outlined, label: 'Budget',
                  value: 'Rs. ${_budgetMinController.text.isEmpty ? '0' : _budgetMinController.text} — Rs. ${_budgetMaxController.text.isEmpty ? '0' : _budgetMaxController.text}'),
              const SizedBox(height: 14),
              _ReviewRow(icon: Icons.bolt_rounded, label: 'Urgency', value: _urgency),
              const SizedBox(height: 14),
              _ReviewRow(icon: Icons.calendar_today_outlined, label: 'Date',
                  value: _preferredDate != null
                      ? '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}'
                      : 'Not set'),
              if (_preferredTime != null) ...[
                const SizedBox(height: 14),
                _ReviewRow(icon: Icons.access_time_rounded, label: 'Time',
                    value: _preferredTime!.format(context)),
              ],
              if (_photos.isNotEmpty) ...[
                const SizedBox(height: 14),
                _ReviewRow(icon: Icons.photo_outlined, label: 'Photos',
                    value: '${_photos.length} photo${_photos.length == 1 ? '' : 's'} attached'),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _UrgencyChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _UrgencyChip({required this.label, required this.icon, required this.selected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? c.withValues(alpha: 0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? c : AppColors.border, width: selected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? c : AppColors.textTertiary),
              const SizedBox(height: 6),
              Text(label, style: AppTypography.labelSmall.copyWith(
                color: selected ? c : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ReviewRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        SizedBox(width: 80, child: Text(label, style: AppTypography.labelSmall)),
        Expanded(child: Text(value,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary))),
      ],
    );
  }
}
