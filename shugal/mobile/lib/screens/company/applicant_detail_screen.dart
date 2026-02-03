import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/app_header.dart';
import '../../l10n/app_localizations.dart';
import 'schedule_interview_screen.dart';

class ApplicantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> application;
  final Map<String, dynamic> job;

  const ApplicantDetailScreen({
    super.key,
    required this.application,
    required this.job,
  });

  @override
  State<ApplicantDetailScreen> createState() => _ApplicantDetailScreenState();
}

class _ApplicantDetailScreenState extends State<ApplicantDetailScreen> {
  Future<void> _openCV(String cvPath) async {
    final normalizedPath = ApiService.normalizeUrl(cvPath);
    final uri = Uri.parse(normalizedPath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.couldNotOpenCv),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final candidate = widget.application['candidate'] as Map<String, dynamic>?;
    final candidateProfile = candidate?['candidate_profile'] as Map<String, dynamic>?;
    final status = widget.application['status'] as String? ?? 'pending';
    final appliedAt = widget.application['created_at'] as String?;
    final coverLetter = widget.application['cover_letter'] as String?;

    // Get candidate info
    final name = candidate?['name'] as String? ?? l10n.unknown;
    final email = candidate?['email'] as String? ?? '';
    final mobileNumber = candidateProfile?['mobile_number'] as String? ?? '';
    final professionTitle = candidateProfile?['profession_title'] as String? ??
                            candidateProfile?['job_title'] as String? ?? l10n.jobSeeker;
    final profileImagePath = candidateProfile?['profile_image_path'] as String?;
    final summary = candidateProfile?['summary'] as String? ?? '';
    final address = candidateProfile?['address'] as String? ?? '';
    final cvPath = candidateProfile?['cv_path'] as String?;
    final skills = List<String>.from(candidateProfile?['skills'] ?? []);

    // Format applied date
    String appliedDateStr = l10n.recently;
    if (appliedAt != null) {
      try {
        final date = DateTime.parse(appliedAt);
        appliedDateStr = '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        appliedDateStr = l10n.recently;
      }
    }

    // Get status color and text
    Color statusColor;
    String statusText;
    switch (status) {
      case 'reviewed':
        statusColor = Colors.blue;
        statusText = l10n.reviewed;
        break;
      case 'shortlisted':
        statusColor = Colors.green;
        statusText = l10n.shortlisted;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = l10n.rejected;
        break;
      default:
        statusColor = Colors.orange;
        statusText = l10n.pending;
    }

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
                  color: AppTheme.bodySurfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(48),
                    topRight: Radius.circular(48),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        height: 5,
                        width: 50,
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(3),
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
                              l10n.applicantDetails,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 40),
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
                            // Profile Header Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Profile Image
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primaryColor.withOpacity(0.3),
                                        width: 3,
                                      ),
                                    ),
                                    child: profileImagePath != null
                                        ? ClipOval(
                                            child: Image.network(
                                              ApiService.normalizeUrl(profileImagePath),
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                Icons.person,
                                                color: AppTheme.primaryColor,
                                                size: 50,
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            color: AppTheme.primaryColor,
                                            size: 50,
                                          ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Name
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Profession Title
                                  Text(
                                    professionTitle,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Application Status
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getStatusIcon(status),
                                          size: 16,
                                          color: statusColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          statusText,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Contact Info
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 12),

                                  // Email
                                  if (email.isNotEmpty)
                                    _buildContactRow(
                                      icon: Icons.email_outlined,
                                      value: email,
                                      onTap: () => _sendEmail(email),
                                    ),

                                  // Phone
                                  if (mobileNumber.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _buildContactRow(
                                      icon: Icons.phone_outlined,
                                      value: mobileNumber,
                                      onTap: () => _callPhone(mobileNumber),
                                    ),
                                  ],

                                  // Address
                                  if (address.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _buildContactRow(
                                      icon: Icons.location_on_outlined,
                                      value: address,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Application Info
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.applicationInfo,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(l10n.appliedFor, widget.job['title'] as String? ?? l10n.job),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(l10n.appliedOn, appliedDateStr),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(l10n.status, statusText),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Cover Letter
                            if (coverLetter != null && coverLetter.isNotEmpty) ...[
                              Text(
                                l10n.coverLetter,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  coverLetter,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Summary
                            if (summary.isNotEmpty) ...[
                              Text(
                                l10n.about,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  summary,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Skills
                            if (skills.isNotEmpty) ...[
                              Text(
                                l10n.skills,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: skills.map((skill) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        skill,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // CV / Resume Section
                            if (cvPath != null && cvPath.isNotEmpty) ...[
                              Text(
                                l10n.cvResume,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => _openCV(cvPath),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.shade100,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.picture_as_pdf,
                                          color: Colors.red.shade400,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.applicantResume,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              l10n.tapToViewOrDownload,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.download_outlined,
                                          color: AppTheme.primaryColor,
                                          size: 22,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              color: AppTheme.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SafeArea(
                child: Row(
                  children: [
                    // Message Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Navigate to chat
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.message,
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
                    // Call Button
                    if (mobileNumber.isNotEmpty)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => _callPhone(mobileNumber),
                          icon: Icon(
                            Icons.phone_outlined,
                            color: Colors.green.shade600,
                            size: 24,
                          ),
                        ),
                      ),
                    if (mobileNumber.isNotEmpty) const SizedBox(width: 12),
                    // Schedule Interview Button
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScheduleInterviewScreen(
                                application: widget.application,
                                job: widget.job,
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.calendar_today_outlined,
                          color: AppTheme.green,
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'reviewed':
        return Icons.visibility_outlined;
      case 'shortlisted':
        return Icons.star_outline;
      case 'rejected':
        return Icons.close;
      default:
        return Icons.hourglass_empty;
    }
  }

  Widget _buildContactRow({
    required IconData icon,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: onTap != null ? AppTheme.primaryColor : Colors.grey.shade600,
                fontWeight: onTap != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
