import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_header.dart';
import '../../l10n/app_localizations.dart';

class InterviewDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? meeting;
  final Map<String, dynamic>? interviewData; // Legacy support

  const InterviewDetailScreen({
    super.key,
    this.meeting,
    this.interviewData,
  });

  @override
  State<InterviewDetailScreen> createState() => _InterviewDetailScreenState();
}

class _InterviewDetailScreenState extends State<InterviewDetailScreen> {
  bool _isUpdating = false;

  // Get company info from meeting
  Map<String, dynamic> _getCompanyInfo(AppLocalizations l10n) {
    if (widget.meeting == null) return {};
    final company = widget.meeting!['company'] as Map<String, dynamic>?;
    final companyProfile = company?['company_profile'] as Map<String, dynamic>?;

    return {
      'id': company?['id'],
      'name': company?['name'] as String? ?? companyProfile?['company_name'] as String? ?? l10n.unknownCompany,
      'email': company?['email'] as String? ?? '',
      'phone': companyProfile?['phone_number'] as String? ?? '',
      'image': companyProfile?['logo_path'] as String?,
      'address': companyProfile?['address'] as String? ?? '',
    };
  }

  // Get meeting details from dedicated fields
  Map<String, String> _getMeetingDetails() {
    if (widget.meeting == null) return {};
    final meeting = widget.meeting!;
    final result = <String, String>{
      'type': 'Physical',
      'location': '',
      'notes': '',
      'job': '',
    };

    final interviewType = meeting['interview_type'] as String?;
    if (interviewType != null) {
      result['type'] = interviewType.substring(0, 1).toUpperCase() + interviewType.substring(1);
    }

    final location = meeting['location'] as String?;
    if (location != null && location.isNotEmpty) {
      result['location'] = location;
    }

    final notes = meeting['notes'] as String?;
    if (notes != null && notes.isNotEmpty) {
      result['notes'] = notes;
    }

    final jobTitle = meeting['job_title'] as String?;
    final job = meeting['job'] as Map<String, dynamic>?;
    result['job'] = jobTitle ?? job?['title'] as String? ?? '';

    return result;
  }

  // Format scheduled time
  String _formatTime(String? scheduledAt, AppLocalizations l10n) {
    if (scheduledAt == null) return l10n.notScheduled;
    try {
      final dateTime = DateTime.parse(scheduledAt);
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (e) {
      return l10n.invalidTime;
    }
  }

  // Format date
  String _formatDate(String? scheduledAt, AppLocalizations l10n) {
    if (scheduledAt == null) return l10n.notScheduled;
    try {
      final dateTime = DateTime.parse(scheduledAt);
      final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    } catch (e) {
      return l10n.invalidDate;
    }
  }

  Future<void> _updateMeetingStatus(String status) async {
    if (_isUpdating) return;

    final l10n = AppLocalizations.of(context)!;
    final meetingId = widget.meeting?['id'];
    if (meetingId == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.pleaseLoginToContinue),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await ApiService.patch(
        'mobile/meetings/$meetingId',
        {'status': status},
        token: token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'accepted' ? l10n.interviewAccepted : l10n.interviewRejected),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToUpdateInterview}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _openLink(String url) async {
    if (url.isEmpty) return;
    
    Uri uri;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      uri = Uri.parse(url);
    } else {
      uri = Uri.parse('https://$url');
    }
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Use new meeting data format or fall back to legacy interviewData
    final companyInfo = _getCompanyInfo(l10n);
    final meetingDetails = _getMeetingDetails();
    final scheduledAt = widget.meeting?['scheduled_at'] as String?;
    final status = widget.meeting?['status'] as String? ?? 'requested';

    // Legacy support
    final companyName = companyInfo['name'] as String? ??
        widget.interviewData?['companyName'] as String? ??
        l10n.unknownCompany;
    final jobTitle = meetingDetails['job']?.isNotEmpty == true
        ? meetingDetails['job']!
        : widget.interviewData?['jobTitle'] as String? ?? l10n.interview;

    String interviewType = meetingDetails['type'] ?? 'Physical';
    if (widget.interviewData != null && meetingDetails['type'] == 'Physical') {
      interviewType = widget.interviewData?['interviewType'] as String? ?? 'Physical';
    }
    if (interviewType == 'Physical') {
      interviewType = l10n.physicalInterview;
    } else if (interviewType == 'Online') {
      interviewType = l10n.onlineInterview;
    } else if (interviewType == 'Phone') {
      interviewType = l10n.phoneInterview;
    }

    final date = _formatDate(scheduledAt, l10n);
    final time = _formatTime(scheduledAt, l10n);
    final location = meetingDetails['location']?.isNotEmpty == true
        ? meetingDetails['location']!
        : widget.interviewData?['meetingLink'] as String? ?? '';
    final contact = companyInfo['phone'] as String? ??
        widget.interviewData?['contact'] as String? ?? '';
    final notes = meetingDetails['notes']?.isNotEmpty == true
        ? meetingDetails['notes']!
        : widget.interviewData?['additionalNotes'] as String? ?? '';
    final profileImage = companyInfo['image'] as String? ??
        widget.interviewData?['profileImage'] as String?;

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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

                      // Navigation Bar
                      Row(
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              l10n.interviewSummary,
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
                      const SizedBox(height: 24),

                      // Company Information Card
                      Row(
                        children: [
                          // Profile Picture
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade200,
                            ),
                            child: profileImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      ApiService.normalizeUrl(profileImage),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.business,
                                          size: 40,
                                          color: AppTheme.textMuted,
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.business,
                                    size: 40,
                                    color: AppTheme.textMuted,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          // Company Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  companyName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  jobTitle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Interview Type Tag
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    interviewType,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Date and Time Section
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 20,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    date,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 20,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    time,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Interview Details Heading
                      Text(
                        l10n.interviewDetails,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Location
                      if (location.isNotEmpty)
                        _DetailItem(
                          icon: Icons.location_on,
                          title: interviewType.contains(l10n.onlineInterview) ? l10n.meetingLink : l10n.location,
                          content: location,
                          isLink: interviewType.contains(l10n.onlineInterview),
                          onTap: interviewType.contains(l10n.onlineInterview) ? () => _openLink(location) : null,
                        ),
                      if (location.isNotEmpty) const SizedBox(height: 20),

                      // Contact
                      if (contact.isNotEmpty)
                        _DetailItem(
                          icon: Icons.phone,
                          title: l10n.contact,
                          content: contact,
                          onTap: () => _makePhoneCall(contact),
                        ),
                      if (contact.isNotEmpty) const SizedBox(height: 20),

                      // Additional Notes
                      if (notes.isNotEmpty)
                        _DetailItem(
                          icon: Icons.note_outlined,
                          title: l10n.additionalNotes,
                          content: notes,
                        ),
                      if (notes.isNotEmpty) const SizedBox(height: 32),

                      // Status Badge
                      if (widget.meeting != null) ...[
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getStatusColor(status),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(status),
                                  size: 20,
                                  color: _getStatusColor(status),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.statusLabel('${status.substring(0, 1).toUpperCase()}${status.substring(1)}'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Action Buttons - Only show for requested status
                      if (status == 'requested') ...[
                        Row(
                          children: [
                            // Reject Button
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isUpdating ? null : () => _updateMeetingStatus('rejected'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(
                                    color: Colors.red,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _isUpdating
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.red,
                                        ),
                                      )
                                    : Text(
                                        l10n.reject,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Accept Interview Button
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isUpdating ? null : () => _updateMeetingStatus('accepted'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: AppTheme.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _isUpdating
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        l10n.acceptInterview,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.schedule;
    }
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final bool isLink;
  final VoidCallback? onTap;

  const _DetailItem({
    required this.icon,
    required this.title,
    required this.content,
    this.isLink = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onTap,
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isLink || onTap != null ? AppTheme.primaryColor : AppTheme.textSecondary,
                    decoration: isLink ? TextDecoration.underline : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
