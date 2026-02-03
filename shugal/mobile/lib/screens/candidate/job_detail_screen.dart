import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_header.dart';
import '../../l10n/app_localizations.dart';
import '../shared/chat_screen.dart';
import '../auth/login_screen.dart';
import 'payment_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? jobData;

  const JobDetailScreen({
    super.key,
    this.jobData,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isCompanyDescriptionExpanded = false;
  bool _hasApplied = false;
  bool _isCheckingApplication = true;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyApplied();
  }

  Future<void> _checkIfAlreadyApplied() async {
    // Check if has_applied field is already in jobData
    final hasAppliedFromData = widget.jobData?['has_applied'] as bool?;
    if (hasAppliedFromData != null) {
      if (mounted) {
        setState(() {
          _hasApplied = hasAppliedFromData;
          _isCheckingApplication = false;
        });
      }
      return;
    }

    // Otherwise check via API
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _isCheckingApplication = false;
          });
        }
        return;
      }

      final jobId = widget.jobData?['id'];
      if (jobId == null) {
        if (mounted) {
          setState(() {
            _isCheckingApplication = false;
          });
        }
        return;
      }

      // Check candidate's applications
      final response = await ApiService.get(
        'mobile/candidate/applications',
        token: token,
      );

      final applications = response['data'] as List<dynamic>? ?? [];
      final hasApplied = applications.any((app) {
        final job = app['job'] as Map<String, dynamic>?;
        return job?['id'] == jobId;
      });

      if (mounted) {
        setState(() {
          _hasApplied = hasApplied;
          _isCheckingApplication = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking application status: $e');
      if (mounted) {
        setState(() {
          _isCheckingApplication = false;
        });
      }
    }
  }

  // Helper methods to extract data from API response
  String _getJobTitle(AppLocalizations l10n) {
    return widget.jobData?['title'] as String? ?? l10n.jobTitle;
  }

  String _getLocation() {
    return widget.jobData?['location'] as String? ?? 'Kuwait';
  }

  String _getCompanyName() {
    final company = widget.jobData?['company'] as Map<String, dynamic>?;
    if (company != null) {
      final companyProfile = company['company_profile'] as Map<String, dynamic>?;
      if (companyProfile != null && companyProfile['company_name'] != null) {
        return companyProfile['company_name'] as String;
      }
      return company['name'] as String? ?? 'Company';
    }
    return 'Company';
  }

  String? _getCompanyLogo() {
    final company = widget.jobData?['company'] as Map<String, dynamic>?;
    if (company != null) {
      final companyProfile = company['company_profile'] as Map<String, dynamic>?;
      if (companyProfile != null && companyProfile['logo_path'] != null) {
        return ApiService.normalizeUrl(companyProfile['logo_path'] as String);
      }
    }
    return null;
  }

  String _getCompanyInitials() {
    final companyName = _getCompanyName();
    if (companyName.isEmpty || companyName == 'Company') return '?';

    final words = companyName.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return companyName.substring(0, companyName.length >= 2 ? 2 : 1).toUpperCase();
  }

  int? _getCompanyUserId() {
    final company = widget.jobData?['company'] as Map<String, dynamic>?;
    return company?['id'] as int?;
  }

  String _getSalary(AppLocalizations l10n) {
    final salaryRange = widget.jobData?['salary_range'] as String?;
    if (salaryRange != null && salaryRange.isNotEmpty) {
      return '$salaryRange KWD';
    }
    return l10n.salaryTbd;
  }

  String _getEmploymentType(AppLocalizations l10n) {
    final hiringType = widget.jobData?['hiring_type'] as String?;
    if (hiringType != null && hiringType.isNotEmpty) {
      // Capitalize first letter
      return hiringType[0].toUpperCase() + hiringType.substring(1);
    }
    return l10n.fullTime;
  }

  String _getWorkingHours() {
    final workingHours = widget.jobData?['working_hours'] as String?;
    if (workingHours != null && workingHours.isNotEmpty) {
      return workingHours;
    }
    return '9am - 5pm';
  }

  String _getWorkLocation(AppLocalizations l10n) {
    final jobType = widget.jobData?['job_type'] as String?;
    if (jobType != null && jobType.isNotEmpty) {
      return jobType[0].toUpperCase() + jobType.substring(1);
    }
    return l10n.onSite;
  }

  String _getDescription(AppLocalizations l10n) {
    final description = widget.jobData?['description'] as String?;
    if (description != null && description.isNotEmpty) {
      return description;
    }
    return l10n.noDescriptionAvailable;
  }

  List<String> _getRequirements() {
    final requirements = widget.jobData?['requirements'];
    if (requirements != null) {
      if (requirements is List) {
        return requirements.map((e) => e.toString()).toList();
      } else if (requirements is String && requirements.isNotEmpty) {
        // Split by newlines or bullet points
        return requirements
            .split(RegExp(r'[\n•\-]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return [];
  }

  String _getCompanyDescription(AppLocalizations l10n) {
    final company = widget.jobData?['company'] as Map<String, dynamic>?;
    if (company != null) {
      final companyProfile = company['company_profile'] as Map<String, dynamic>?;
      if (companyProfile != null && companyProfile['description'] != null) {
        return companyProfile['description'] as String;
      }
    }
    return l10n.noCompanyDescriptionAvailable;
  }

  String _getPostedTime(AppLocalizations l10n) {
    final createdAt = widget.jobData?['created_at'] as String?;
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        final now = DateTime.now();
        final difference = now.difference(date);

        if (difference.inDays == 0) {
          if (difference.inHours == 0) {
            return l10n.minutesAgoLabel(difference.inMinutes);
          }
          return l10n.hoursAgoLabel(difference.inHours);
        } else if (difference.inDays == 1) {
          return l10n.oneDayAgo;
        } else if (difference.inDays < 30) {
          return l10n.daysAgoLabel(difference.inDays);
        } else {
          final months = (difference.inDays / 30).floor();
          return months > 1 ? l10n.monthsAgoPlural(months) : l10n.monthsAgo(months);
        }
      } catch (e) {
        return l10n.recently;
      }
    }
    return l10n.recently;
  }

  int _getApplicantCount() {
    return widget.jobData?['applicants_count'] as int? ?? 0;
  }

  Future<void> _showApplyModal() async {
    // Check if user is logged in
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _ApplyJobModal(
        jobData: widget.jobData,
        onSuccess: () {
          setState(() {
            _hasApplied = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onActivationRequired: () {
          // Close the modal first
          Navigator.of(modalContext).pop();
          // Then show the activation dialog
          _showActivationRequiredDialog();
        },
      ),
    );
  }

  void _showLoginRequiredDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(l10n.loginRequired),
          ],
        ),
        content: Text(
          l10n.pleaseLoginToApplyForJobs,
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(l10n.login),
          ),
        ],
      ),
    );
  }

  void _showActivationRequiredDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n.profileActivationRequired,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          l10n.activateProfileDescription,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Navigate to payment screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PaymentScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.activateNow,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final companyLogo = _getCompanyLogo();
    final requirements = _getRequirements();

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(showLanguageWithActions: true),
            // Main Content Area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(56),
                    topRight: Radius.circular(56),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        height: 6,
                        width: 60,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // App Bar with Back Button and Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppTheme.textPrimary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Expanded(
                            child: Text(
                              l10n.jobDetails,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 40), // Balance the back button
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Job Summary
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Company Logo
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppTheme.bodySurfaceColor,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: companyLogo != null
                                      ? ClipOval(
                                          child: Image.network(
                                            companyLogo,
                                            fit: BoxFit.cover,
                                            width: 60,
                                            height: 60,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Text(
                                                _getCompanyInitials(),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            _getCompanyInitials(),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 16),
                                // Job Title and Location
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getJobTitle(l10n),
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 16,
                                            color: AppTheme.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _getLocation(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Job Metrics
                            Row(
                              children: [
                                Text(
                                  _getPostedTime(l10n),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '•',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.applicantsLabel(_getApplicantCount()),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Job Specifications
                            Text(
                              l10n.jobSpecifications,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // 2x2 Grid
                            Row(
                              children: [
                                Expanded(
                                  child: _SpecItem(
                                    icon: 'assets/images/icons/moneys.png',
                                    label: l10n.expectedSalary,
                                    value: _getSalary(l10n),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SpecItem(
                                    icon: 'assets/images/icons/briefcase.png',
                                    label: l10n.employmentType,
                                    value: _getEmploymentType(l10n),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _SpecItem(
                                    icon: 'assets/images/icons/clock.png',
                                    label: l10n.workingHours,
                                    value: _getWorkingHours(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SpecItem(
                                    icon: 'assets/images/icons/job_type.png',
                                    label: l10n.workLocation,
                                    value: _getWorkLocation(l10n),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Description
                            Text(
                              l10n.description,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getDescription(l10n),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Requirements/Responsibilities
                            if (requirements.isNotEmpty) ...[
                              Text(
                                '${l10n.requirements}:',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...requirements.map((req) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _ResponsibilityItem(text: req),
                                  )),
                              const SizedBox(height: 32),
                            ],

                            // About Company
                            Text(
                              l10n.aboutCompany,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Company Info Row
                            Row(
                              children: [
                                // Company Logo
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppTheme.bodySurfaceColor,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: companyLogo != null
                                      ? ClipOval(
                                          child: Image.network(
                                            companyLogo,
                                            fit: BoxFit.cover,
                                            width: 50,
                                            height: 50,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Text(
                                                _getCompanyInitials(),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            _getCompanyInitials(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                // Company Name and Location
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getCompanyName(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: AppTheme.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _getLocation(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Follow Button
                                OutlinedButton(
                                  onPressed: () {
                                    // TODO: Handle follow
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    side: const BorderSide(
                                      color: AppTheme.primaryColor,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: Text(
                                    l10n.follow,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.secondaryColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Company Description
                            AnimatedCrossFade(
                              firstChild: Text(
                                _getCompanyDescription(l10n),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              secondChild: Text(
                                _getCompanyDescription(l10n),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              crossFadeState: _isCompanyDescriptionExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 200),
                            ),
                            const SizedBox(height: 8),
                            // Read More / Read Less
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isCompanyDescriptionExpanded = !_isCompanyDescriptionExpanded;
                                  });
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isCompanyDescriptionExpanded ? l10n.readLess : l10n.readMore,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _isCompanyDescriptionExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: 20,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 100), // Space for bottom bar
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar (Sticky)
            Container(
              color: AppTheme.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SafeArea(
                child: Row(
                  children: [
                    // Chat Button (only shown when already applied)
                    if (_hasApplied) ...[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            final companyId = _getCompanyUserId();
                            if (companyId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    userId: companyId,
                                    userName: _getCompanyName(),
                                    userImage: _getCompanyLogo(),
                                    userRole: 'company',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    // Apply Now Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _hasApplied || _isCheckingApplication ? null : _showApplyModal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasApplied ? Colors.grey.shade400 : AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isCheckingApplication
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_hasApplied) ...[
                                    const Icon(Icons.check_circle, size: 20),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    _hasApplied ? l10n.alreadyApplied : l10n.applyNow,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bookmark Button
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () {
                          // TODO: Handle bookmark
                        },
                        icon: const Icon(
                          Icons.bookmark_border,
                          color: Colors.white,
                          size: 24,
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
    );
  }
}

class _SpecItem extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _SpecItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(30), // Pill shape
      ),
      child: Row(
        children: [
          // Icon in light grey circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(.4), // Light grey background
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(
                icon,
                height: 10,
                width: 10,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.info_outline, size: 20, color: AppTheme.textMuted),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsibilityItem extends StatelessWidget {
  final String text;

  const _ResponsibilityItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '•',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _ApplyJobModal extends StatefulWidget {
  final Map<String, dynamic>? jobData;
  final VoidCallback onSuccess;
  final VoidCallback onActivationRequired;

  const _ApplyJobModal({
    this.jobData,
    required this.onSuccess,
    required this.onActivationRequired,
  });

  @override
  State<_ApplyJobModal> createState() => _ApplyJobModalState();
}

class _ApplyJobModalState extends State<_ApplyJobModal> {
  final TextEditingController _coverLetterController = TextEditingController();
  bool _isApplying = false;

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  String _getJobTitle(AppLocalizations l10n) {
    return widget.jobData?['title'] as String? ?? l10n.jobTitle;
  }

  String _getLocation() {
    return widget.jobData?['location'] as String? ?? 'Kuwait';
  }

  String? _getCompanyLogo() {
    final company = widget.jobData?['company'] as Map<String, dynamic>?;
    if (company != null) {
      final companyProfile = company['company_profile'] as Map<String, dynamic>?;
      if (companyProfile != null && companyProfile['logo_path'] != null) {
        return ApiService.normalizeUrl(companyProfile['logo_path'] as String);
      }
    }
    return null;
  }

  String _getCompanyInitials() {
    final company = widget.jobData?['company'] as Map<String, dynamic>?;
    String companyName = 'Company';
    if (company != null) {
      final companyProfile = company['company_profile'] as Map<String, dynamic>?;
      if (companyProfile != null && companyProfile['company_name'] != null) {
        companyName = companyProfile['company_name'] as String;
      } else {
        companyName = company['name'] as String? ?? 'Company';
      }
    }

    if (companyName.isEmpty || companyName == 'Company') return '?';

    final words = companyName.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return companyName.substring(0, companyName.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _getSalary(AppLocalizations l10n) {
    final salaryRange = widget.jobData?['salary_range'] as String?;
    if (salaryRange != null && salaryRange.isNotEmpty) {
      return '$salaryRange KWD';
    }
    return l10n.salaryTbd;
  }

  String _getEmploymentType(AppLocalizations l10n) {
    final hiringType = widget.jobData?['hiring_type'] as String?;
    if (hiringType != null && hiringType.isNotEmpty) {
      return hiringType[0].toUpperCase() + hiringType.substring(1);
    }
    return l10n.fullTime;
  }

  String _getWorkingHours() {
    final workingHours = widget.jobData?['working_hours'] as String?;
    if (workingHours != null && workingHours.isNotEmpty) {
      return workingHours;
    }
    return '9am - 5pm';
  }

  String _getWorkLocation(AppLocalizations l10n) {
    final jobType = widget.jobData?['job_type'] as String?;
    if (jobType != null && jobType.isNotEmpty) {
      return jobType[0].toUpperCase() + jobType.substring(1);
    }
    return l10n.onSite;
  }

  String _getPostedTime(AppLocalizations l10n) {
    final createdAt = widget.jobData?['created_at'] as String?;
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        final now = DateTime.now();
        final difference = now.difference(date);

        if (difference.inDays == 0) {
          if (difference.inHours == 0) {
            return l10n.minutesAgoLabel(difference.inMinutes);
          }
          return l10n.hoursAgoLabel(difference.inHours);
        } else if (difference.inDays == 1) {
          return l10n.oneDayAgo;
        } else if (difference.inDays < 30) {
          return l10n.daysAgoLabel(difference.inDays);
        } else {
          final months = (difference.inDays / 30).floor();
          return months > 1 ? l10n.monthsAgoPlural(months) : l10n.monthsAgo(months);
        }
      } catch (e) {
        return l10n.recently;
      }
    }
    return l10n.recently;
  }

  int _getApplicantCount() {
    return widget.jobData?['applicants_count'] as int? ?? 0;
  }

  Future<void> _applyForJob() async {
    final l10n = AppLocalizations.of(context)!;
    final jobId = widget.jobData?['id'];
    debugPrint('Applying for job: $jobId');

    if (jobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidJob)),
      );
      return;
    }

    setState(() => _isApplying = true);

    try {
      final token = await AuthService.getToken();
      debugPrint('Token retrieved: ${token != null ? 'Yes' : 'No'}');

      if (token == null) {
        if (mounted) {
          setState(() => _isApplying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.pleaseLoginToApply)),
          );
        }
        return;
      }

      final body = <String, dynamic>{};
      final coverLetter = _coverLetterController.text.trim();
      if (coverLetter.isNotEmpty) {
        body['cover_letter'] = coverLetter;
      }

      debugPrint('Sending apply request to: mobile/candidate/jobs/$jobId/apply');
      debugPrint('Body: $body');

      final response = await ApiService.post(
        'mobile/candidate/jobs/$jobId/apply',
        body,
        token: token,
      );

      debugPrint('Apply response: $response');

      if (mounted) {
        Navigator.of(context).pop(); // Close modal
        widget.onSuccess();
      }
    } on ApiException catch (e) {
      debugPrint('ApiException: ${e.statusCode} - ${e.message}');
      if (mounted) {
        String message = e.message;
        // Handle specific error cases
        if (e.statusCode == 403) {
          // Call the callback which will close modal and show activation dialog
          widget.onActivationRequired();
          return;
        } else if (e.statusCode == 409) {
          message = l10n.alreadyAppliedForJob;
        } else if (e.statusCode == 404) {
          message = l10n.jobNoLongerAvailable;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('General error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final companyLogo = _getCompanyLogo();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Close button and title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: AppTheme.textPrimary,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Expanded(
                  child: Text(
                    l10n.applyThisJob,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 40), // Balance the close button
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Job Summary
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company Logo
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.bodySurfaceColor,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: companyLogo != null
                            ? ClipOval(
                                child: Image.network(
                                  companyLogo,
                                  fit: BoxFit.cover,
                                  width: 60,
                                  height: 60,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      _getCompanyInitials(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  _getCompanyInitials(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      // Job Title and Location
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getJobTitle(l10n),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getLocation(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Job Metrics
                            Text(
                              '${_getPostedTime(l10n)} • ${l10n.applicantsLabel(_getApplicantCount())}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Job Specifications
                  Text(
                    l10n.jobSpecifications,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 2x2 Grid
                  Row(
                    children: [
                      Expanded(
                        child: _SpecItem(
                          icon: 'assets/images/icons/moneys.png',
                          label: l10n.expectedSalary,
                          value: _getSalary(l10n),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SpecItem(
                          icon: 'assets/images/icons/briefcase.png',
                          label: l10n.employmentType,
                          value: _getEmploymentType(l10n),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SpecItem(
                          icon: 'assets/images/icons/clock.png',
                          label: l10n.workingHours,
                          value: _getWorkingHours(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SpecItem(
                          icon: 'assets/images/icons/job_type.png',
                          label: l10n.workLocation,
                          value: _getWorkLocation(l10n),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Cover Letter Field
                  Text(
                    l10n.coverLetterOptional,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _coverLetterController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: l10n.coverLetterHint,
                      hintStyle: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppTheme.bodySurfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isApplying ? null : _applyForJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isApplying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          l10n.submitApplication,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
