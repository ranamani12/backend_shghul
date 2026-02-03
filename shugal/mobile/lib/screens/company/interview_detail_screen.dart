import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_header.dart';
import 'reschedule_interview_screen.dart';

class InterviewDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? interview;
  final Map<String, dynamic>? meeting; // Original meeting data for rescheduling

  const InterviewDetailScreen({super.key, this.interview, this.meeting});

  @override
  State<InterviewDetailScreen> createState() => _InterviewDetailScreenState();
}

class _InterviewDetailScreenState extends State<InterviewDetailScreen> {
  bool _isUpdating = false;

  Future<void> _updateMeetingStatus(String status) async {
    if (_isUpdating) return;

    final meetingId = widget.interview?['id'];
    if (meetingId == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to continue'),
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
            content: Text('Interview marked as $status'),
            backgroundColor: Colors.green,
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
            content: Text('Failed to update: $e'),
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

  Future<void> _makePhoneCall(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    if (email.isEmpty) return;
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openLink(String link) async {
    if (link.isEmpty) return;
    String url = link;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _getStatusColor(String? status) {
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

  String _buildNotesFromInterview() {
    final data = widget.interview ?? {};
    final notesParts = <String>[];

    final type = data['type'] as String? ?? '';
    if (type.isNotEmpty) {
      // Extract just the interview type (Physical, Online, Phone)
      String interviewType = 'Physical';
      if (type.contains('Online')) {
        interviewType = 'Online';
      } else if (type.contains('Phone')) {
        interviewType = 'Phone';
      }
      notesParts.add('Interview Type: $interviewType');
    }

    final link = data['link'] as String? ?? '';
    if (link.isNotEmpty) {
      notesParts.add('Location: $link');
    }

    final notes = data['notes'] as String? ?? '';
    if (notes.isNotEmpty) {
      notesParts.add('Notes: $notes');
    }

    final job = data['job'] as String? ?? '';
    if (job.isNotEmpty) {
      notesParts.add('Job: $job');
    }

    return notesParts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.interview ?? {};

    final name = data['name'] as String? ?? 'Unknown';
    final title = data['title'] as String? ?? 'Job Seeker';
    final type = data['type'] as String? ?? 'Interview';
    final date = data['date'] as String? ?? 'Not scheduled';
    final time = data['time'] as String? ?? '';
    final profileImagePath = data['image'] as String?;
    final address = data['address'] as String? ?? '';
    final phone = data['phone'] as String? ?? '';
    final email = data['email'] as String? ?? '';
    final link = data['link'] as String? ?? '';
    final status = data['status'] as String? ?? 'requested';
    final notes = data['notes'] as String? ?? '';
    final job = data['job'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(showLanguageWithActions: true),
            // Main Content Container
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gray indicator bar
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

                    // Back button and Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back,
                              color: AppTheme.textPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Interview Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Interview Details Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Status Badge
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Status',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          status.substring(0, 1).toUpperCase() + status.substring(1),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Interview Date Row
                                  _buildInfoRow(
                                    'Interview Date',
                                    date,
                                    isHighlighted: true,
                                  ),

                                  if (time.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      'Time',
                                      time,
                                      isHighlighted: true,
                                    ),
                                  ],

                                  const SizedBox(height: 12),

                                  // Interview Type Row
                                  _buildInfoRow(
                                    'Interview Type',
                                    type,
                                    isHighlighted: false,
                                  ),

                                  if (job.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      'Position',
                                      job,
                                      isHighlighted: false,
                                    ),
                                  ],

                                  const SizedBox(height: 20),

                                  // Candidate Profile
                                  Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: profileImagePath != null
                                            ? ClipOval(
                                                child: Image.network(
                                                  ApiService.normalizeUrl(profileImagePath),
                                                  fit: BoxFit.cover,
                                                  width: 56,
                                                  height: 56,
                                                  errorBuilder: (_, __, ___) => const Icon(
                                                    Icons.person,
                                                    color: AppTheme.primaryColor,
                                                    size: 28,
                                                  ),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.person,
                                                color: AppTheme.primaryColor,
                                                size: 28,
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            title,
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Contact Section
                                  const Text(
                                    'Contact',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Address
                                  if (address.isNotEmpty)
                                    _buildContactItem(
                                      icon: Icons.location_on_outlined,
                                      text: address,
                                    ),

                                  // Phone
                                  if (phone.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () => _makePhoneCall(phone),
                                      child: _buildContactItem(
                                        icon: Icons.phone_outlined,
                                        text: phone,
                                        isLink: true,
                                      ),
                                    ),
                                  ],

                                  // Email
                                  if (email.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () => _sendEmail(email),
                                      child: _buildContactItem(
                                        icon: Icons.email_outlined,
                                        text: email,
                                        isLink: true,
                                      ),
                                    ),
                                  ],

                                  // Meeting Link
                                  if (link.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () => _openLink(link),
                                      child: _buildContactItem(
                                        icon: type.contains('Online')
                                            ? Icons.videocam_outlined
                                            : Icons.location_on_outlined,
                                        text: link,
                                        isLink: true,
                                      ),
                                    ),
                                  ],

                                  // Notes Section
                                  if (notes.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    Divider(
                                      color: Colors.grey.shade200,
                                      thickness: 1,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Notes',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      notes,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Action Buttons
                            if (status == 'requested' || status == 'accepted') ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        // Use original meeting data if available, otherwise construct from interview data
                                        final meetingData = widget.meeting ?? {
                                          'id': widget.interview?['id'],
                                          'scheduled_at': widget.interview?['scheduled_at'],
                                          'notes': _buildNotesFromInterview(),
                                          'candidate': {
                                            'id': widget.interview?['candidate_id'],
                                            'name': widget.interview?['name'],
                                            'email': widget.interview?['email'],
                                            'candidate_profile': {
                                              'mobile_number': widget.interview?['phone'],
                                              'profession_title': widget.interview?['title'],
                                              'profile_image_path': widget.interview?['image'],
                                              'address': widget.interview?['address'],
                                            },
                                          },
                                        };
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RescheduleInterviewScreen(
                                              meeting: meetingData,
                                            ),
                                          ),
                                        ).then((result) {
                                          if (result == true) {
                                            Navigator.pop(context, true);
                                          }
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primaryColor,
                                        side: const BorderSide(color: AppTheme.primaryColor),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      child: const Text(
                                        'Reschedule',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isUpdating
                                          ? null
                                          : () => _updateMeetingStatus('completed'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
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
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Mark Complete',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _isUpdating
                                      ? null
                                      : () => _updateMeetingStatus('cancelled'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text(
                                    'Cancel Interview',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppTheme.blue.withOpacity(0.1)
                : AppTheme.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isHighlighted ? AppTheme.blue : AppTheme.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String text,
    bool isLink = false,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isLink ? AppTheme.primaryColor : AppTheme.textPrimary,
              fontWeight: isLink ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
        if (isLink)
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.grey.shade400,
          ),
      ],
    );
  }
}
