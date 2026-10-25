import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/storage/draft_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/campus_button.dart';
import '../../../core/widgets/campus_text_field.dart';
import '../data/models/issue_model.dart';
import '../data/repositories/issue_repository.dart';
import 'issues_notifier.dart';

class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  String _selectedCategory = kIssueCategories.first;
  String _selectedPriority = 'Medium';
  bool _isSubmitting = false;
  String? _errorMessage;
  IssueModel? _createdIssue;

  final List<XFile> _attachments = [];
  IssueDraft? _recoveredDraft;
  bool _draftDismissed = false;
  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onFieldChanged);
    _locationController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRecoverableDraft();
    });
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkRecoverableDraft() async {
    try {
      final draft = await ref.read(draftStorageServiceProvider).getDraft();
      if (draft != null && !draft.isEmpty && mounted) {
        if (_titleController.text.isEmpty &&
            _descriptionController.text.isEmpty &&
            _locationController.text.isEmpty) {
          setState(() {
            _recoveredDraft = draft;
          });
        }
      }
    } catch (_) {}
  }

  void _restoreDraft(IssueDraft draft) {
    setState(() {
      _titleController.text = draft.title;
      _locationController.text = draft.location;
      _descriptionController.text = draft.description;
      if (kIssueCategories.contains(draft.category)) {
        _selectedCategory = draft.category;
      }
      if (kIssuePriorities.contains(draft.priority)) {
        _selectedPriority = draft.priority;
      }
      _recoveredDraft = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unfinished report draft restored.')),
    );
  }

  Future<void> _discardDraft() async {
    setState(() {
      _recoveredDraft = null;
      _draftDismissed = true;
    });
    await ref.read(draftStorageServiceProvider).clearDraft();
  }

  void _onFieldChanged() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 800), () {
      _persistCurrentDraft();
    });
  }

  Future<void> _persistCurrentDraft() async {
    if (!mounted || _createdIssue != null || _isSubmitting) return;
    final draft = IssueDraft(
      title: _titleController.text,
      category: _selectedCategory,
      location: _locationController.text,
      priority: _selectedPriority,
      description: _descriptionController.text,
      attachmentPaths: _attachments.map((f) => f.path).toList(),
      lastModified: DateTime.now(),
    );
    try {
      await ref.read(draftStorageServiceProvider).saveDraft(draft);
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (file == null) return;

      final length = await file.length();
      if (length > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Selected image exceeds 5MB limit. Please choose a smaller photo.',
              ),
              backgroundColor: AppColors.statusCritical,
            ),
          );
        }
        return;
      }

      final ext = file.name.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unsupported image format. Allowed formats: JPG, PNG, WEBP.',
              ),
              backgroundColor: AppColors.statusCritical,
            ),
          );
        }
        return;
      }

      setState(() {
        _attachments.add(file);
      });
      await _persistCurrentDraft();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to capture or select image: $e'),
            backgroundColor: AppColors.statusCritical,
          ),
        );
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
    _persistCurrentDraft();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    _draftTimer?.cancel();
    _draftTimer = null;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final request = IssueCreateRequest(
      title: _titleController.text.trim(),
      category: _selectedCategory,
      location: _locationController.text.trim(),
      priority: _selectedPriority,
      description: _descriptionController.text.trim(),
      attachments: _attachments.map((f) => f.name).toList(),
    );

    try {
      final issue = await ref
          .read(issueRepositoryProvider)
          .createIssue(request);

      _titleController.removeListener(_onFieldChanged);
      _locationController.removeListener(_onFieldChanged);
      _descriptionController.removeListener(_onFieldChanged);
      _draftTimer?.cancel();
      _draftTimer = null;

      // Successfully submitted to server: clear draft
      try {
        await ref.read(draftStorageServiceProvider).clearDraft();
      } catch (_) {}

      // Trigger list refresh
      try {
        unawaited(ref.read(issuesNotifierProvider.notifier).loadInitial());
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _createdIssue = issue;
        });
      }
    } catch (e) {
      if (mounted) {
        final message = e is AppException
            ? e.message
            : 'Unable to submit incident report. Please try again.';
        setState(() {
          _isSubmitting = false;
          _errorMessage = message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_createdIssue != null) {
      return _buildSuccessView(context, isDark, _createdIssue!);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Report Campus Issue'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Incident Details',
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Provide detailed information to assist facility maintenance teams with prompt dispatch and repair.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                // Recovered draft banner
                if (_recoveredDraft != null && !_draftDismissed) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: AppRadius.mdBorderRadius,
                      border: Border.all(
                        color: isDark
                            ? AppColors.brandAmber.withValues(alpha: 0.5)
                            : AppColors.brandAmberHover,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.restore_page_outlined,
                              size: 20,
                              color: AppColors.brandAmber,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Recovered Unfinished Draft',
                                style: AppTypography.titleMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'You have an unsaved issue report from your last session.',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _discardDraft,
                              child: Text(
                                'Discard',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            ElevatedButton(
                              onPressed: () => _restoreDraft(_recoveredDraft!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandAmber,
                                foregroundColor: AppColors.deepNavy,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'Restore Draft',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Error banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.statusCriticalBgDark
                          : AppColors.statusCriticalBg,
                      borderRadius: AppRadius.mdBorderRadius,
                      border: Border.all(color: AppColors.statusCritical),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: AppColors.statusCritical,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.statusCritical,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Title Field (5 - 100 chars)
                CampusTextField(
                  label: 'Issue Title *',
                  hint: 'e.g., Broken projector HDMI port',
                  controller: _titleController,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().length < 5) {
                      return 'Title must be at least 5 characters.';
                    }
                    if (value.trim().length > 100) {
                      return 'Title cannot exceed 100 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Category Field
                Text(
                  'Category *',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: AppRadius.mdBorderRadius,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      dropdownColor: isDark
                          ? AppColors.darkCard
                          : AppColors.lightCard,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: kIssueCategories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(
                            cat,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Location Field (3 - 80 chars)
                CampusTextField(
                  label: 'Campus Location *',
                  hint: 'e.g., Science Block 302 or West Wing Restroom',
                  controller: _locationController,
                  maxLength: 80,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Location must be at least 3 characters.';
                    }
                    if (value.trim().length > 80) {
                      return 'Location cannot exceed 80 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Priority Choice Chips
                Text(
                  'Urgency Priority *',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: kIssuePriorities.map((p) {
                    final isSelected = _selectedPriority == p;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: InkWell(
                          onTap: () => setState(() => _selectedPriority = p),
                          borderRadius: AppRadius.mdBorderRadius,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandAmber
                                  : (isDark
                                        ? AppColors.darkCard
                                        : AppColors.lightCard),
                              borderRadius: AppRadius.mdBorderRadius,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.brandAmberHover
                                    : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              p,
                              style: AppTypography.labelMedium.copyWith(
                                color: isSelected
                                    ? AppColors.deepNavy
                                    : (isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Description Field (15 - 1000 chars)
                CampusTextField(
                  label: 'Detailed Description *',
                  hint: 'Provide comprehensive context (what happened, symptoms, equipment tag ID if applicable)...',
                  controller: _descriptionController,
                  maxLines: 5,
                  maxLength: 1000,
                  validator: (value) {
                    if (value == null || value.trim().length < 15) {
                      return 'Description must provide at least 15 characters of detail.';
                    }
                    if (value.trim().length > 1000) {
                      return 'Description cannot exceed 1000 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Photo Evidence & Attachments Section
                Text(
                  'Photo Evidence (Optional)',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Attach photos of damaged hardware, facilities, or maintenance areas (up to 5MB each).',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                Row(
                  children: [
                    Expanded(
                      child: CampusButton(
                        label: 'Take Photo',
                        icon: Icons.camera_alt_outlined,
                        variant: CampusButtonVariant.secondary,
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: CampusButton(
                        label: 'Choose Gallery',
                        icon: Icons.photo_library_outlined,
                        variant: CampusButtonVariant.secondary,
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),

                if (_attachments.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Column(
                    children: List.generate(_attachments.length, (index) {
                      final file = _attachments[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: AppRadius.mdBorderRadius,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: AppRadius.smBorderRadius,
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: kIsWeb
                                    ? Image.network(
                                        file.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(file.path),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.broken_image_outlined,
                                          size: 24,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file.name,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Attached Evidence',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.brandAmber
                                          : AppColors.brandAmberHover,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () => _removeAttachment(index),
                              tooltip: 'Remove',
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                CampusButton(
                  label: 'Submit Incident Report',
                  icon: Icons.send_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _handleSubmit,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(
    BuildContext context,
    bool isDark,
    IssueModel issue,
  ) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.statusResolvedBgDark
                            : AppColors.statusResolvedBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 54,
                        color: AppColors.statusResolved,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Incident Reported Successfully',
                    style: AppTypography.headlineSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your maintenance request has been recorded in the central database.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Reference code badge
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: AppRadius.lgBorderRadius,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'INCIDENT REFERENCE CODE',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          issue.referenceCode,
                          style: AppTypography.headlineMedium.copyWith(
                            color: isDark
                                ? AppColors.brandAmber
                                : AppColors.brandAmberHover,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          issue.title,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  CampusButton(
                    label: 'View Incident Details',
                    icon: Icons.visibility_outlined,
                    onPressed: () {
                      context.pushReplacement('/issues/${issue.id}');
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CampusButton(
                    label: 'Return to Issues Feed',
                    variant: CampusButtonVariant.secondary,
                    onPressed: () {
                      context.go('/issues');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
