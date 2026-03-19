import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';

// ──────────────────────────────────────────────────────────────
// POST JOB SCREEN
// 5-step wizard for creating a new job posting:
//   Step 1: Pick service category
//   Step 2: Title + description + location
//   Step 3: Budget range + urgency + date/time
//   Step 4: Upload reference photos
//   Step 5: Review everything before posting
// Progress bar at top shows which step you're on.
// Back/Continue buttons at bottom navigate between steps.
// ──────────────────────────────────────────────────────────────
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
  String _urgency = 'normal';
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;

  final _steps = ['Category', 'Details', 'Budget & Time', 'Photos', 'Review'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
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
          // ── Progress bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: List.generate(_steps.length, (i) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.only(
                            right: i < _steps.length - 1 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: i <= _step
                              ? AppColors.primary
                              : AppColors.border,
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
                    Text('Step ${_step + 1} of ${_steps.length}',
                        style: AppTypography.labelSmall),
                    Text(_steps[_step],
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),

          // ── Step content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStep(),
            ),
          ),

          // ── Bottom buttons ──
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
                    label:
                        _step == _steps.length - 1 ? 'Post Job' : 'Continue',
                    onPressed: () {
                      if (_step < _steps.length - 1) {
                        setState(() => _step++);
                      } else {
                        // TODO: Submit job to backend
                        Navigator.pop(context);
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

  // Routes to the correct step widget
  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildCategoryStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildBudgetStep();
      case 3:
        return _buildPhotosStep();
      case 4:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  // ── Step 1: Pick category ──
  Widget _buildCategoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What service do you need?', style: AppTypography.displaySmall),
        const SizedBox(height: 8),
        Text('Choose the category that best matches your job.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        ...AppCategories.all.map((cat) {
          final selected = _selectedCategory == cat.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat.id),
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
                    Expanded(
                        child: Text(cat.name,
                            style: AppTypography.headlineMedium)),
                    if (selected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 22),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Step 2: Job details ──
  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Describe your job', style: AppTypography.displaySmall),
        const SizedBox(height: 8),
        Text('Provide details to help workers understand the job.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Text('Job Title', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          style: AppTypography.bodyMedium,
          decoration:
              const InputDecoration(hintText: 'e.g. Fix kitchen sink leak'),
        ),
        const SizedBox(height: 20),
        Text('Description', style: AppTypography.labelMedium),
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
        Text('Location', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // TODO: Open Google Maps picker
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Use current location',
                          style: AppTypography.headlineSmall),
                      Text('Colombo 03, Western Province',
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: Budget & schedule ──
  Widget _buildBudgetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budget & Schedule', style: AppTypography.displaySmall),
        const SizedBox(height: 8),
        Text('Set your budget range and preferred time.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Text('Budget Range (LKR)', style: AppTypography.labelMedium),
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
              child:
                  Text('—', style: TextStyle(color: AppColors.textTertiary)),
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
            _UrgencyChip(
                label: 'Low',
                icon: Icons.schedule_outlined,
                selected: _urgency == 'low',
                onTap: () => setState(() => _urgency = 'low')),
            const SizedBox(width: 8),
            _UrgencyChip(
                label: 'Normal',
                icon: Icons.access_time_rounded,
                selected: _urgency == 'normal',
                onTap: () => setState(() => _urgency = 'normal')),
            const SizedBox(width: 8),
            _UrgencyChip(
                label: 'Urgent',
                icon: Icons.bolt_rounded,
                selected: _urgency == 'urgent',
                color: AppColors.error,
                onTap: () => setState(() => _urgency = 'urgent')),
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
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.textTertiary),
                const SizedBox(width: 12),
                Text(
                  _preferredDate != null
                      ? '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}'
                      : 'Select a date',
                  style: AppTypography.bodyMedium.copyWith(
                    color: _preferredDate != null
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Preferred Time', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) setState(() => _preferredTime = time);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 18, color: AppColors.textTertiary),
                const SizedBox(width: 12),
                Text(
                  _preferredTime != null
                      ? _preferredTime!.format(context)
                      : 'Select a time',
                  style: AppTypography.bodyMedium.copyWith(
                    color: _preferredTime != null
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 4: Photos ──
  Widget _buildPhotosStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add reference photos', style: AppTypography.displaySmall),
        const SizedBox(height: 8),
        Text(
            'Upload photos to help workers understand the job better. This reduces pricing disputes.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            // TODO: Open image picker
          },
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(height: 12),
                Text('Tap to upload photos',
                    style: AppTypography.headlineSmall),
                const SizedBox(height: 4),
                Text('JPEG or PNG, max 5MB each',
                    style: AppTypography.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Info tip
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.info, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Photos help workers estimate the job accurately and avoid pricing disputes.',
                  style:
                      AppTypography.bodySmall.copyWith(color: AppColors.info),
                ),
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
      (c) => c.id == _selectedCategory,
      orElse: () => AppCategories.all.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review your job', style: AppTypography.displaySmall),
        const SizedBox(height: 8),
        Text('Make sure everything looks correct before posting.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
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
              // Category + title header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: category.iconBgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                        child: Text(category.icon,
                            style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.name,
                            style: AppTypography.labelMedium),
                        Text(
                          _titleController.text.isEmpty
                              ? 'No title'
                              : _titleController.text,
                          style: AppTypography.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.borderLight),
              const SizedBox(height: 16),
              // Summary rows
              _ReviewRow(
                  icon: Icons.description_outlined,
                  label: 'Description',
                  value: _descController.text.isEmpty
                      ? 'No description'
                      : _descController.text),
              const SizedBox(height: 14),
              _ReviewRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Budget',
                  value:
                      'Rs. ${_budgetMinController.text.isEmpty ? '0' : _budgetMinController.text} — Rs. ${_budgetMaxController.text.isEmpty ? '0' : _budgetMaxController.text}'),
              const SizedBox(height: 14),
              _ReviewRow(
                  icon: Icons.bolt_rounded,
                  label: 'Urgency',
                  value: _urgency[0].toUpperCase() + _urgency.substring(1)),
              const SizedBox(height: 14),
              _ReviewRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: _preferredDate != null
                      ? '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}'
                      : 'Not set'),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Urgency selector chip ──
class _UrgencyChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _UrgencyChip({
    required this.label,
    required this.icon,
    required this.selected,
    this.color,
    required this.onTap,
  });

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
            color: selected ? c.withOpacity(0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? c : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? c : AppColors.textTertiary),
              const SizedBox(height: 6),
              Text(label,
                  style: AppTypography.labelMedium.copyWith(
                    color: selected ? c : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Review summary row ──
class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        SizedBox(
            width: 80,
            child: Text(label, style: AppTypography.labelSmall)),
        Expanded(
          child: Text(value,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
