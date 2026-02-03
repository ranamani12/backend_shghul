import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_header.dart';
import '../../l10n/app_localizations.dart';
import 'interview_detail_screen.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  int _selectedDayIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _meetings = [];

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = null; // Will be set with localized string in build
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.get(
        'mobile/meetings',
        token: token,
      );

      if (mounted) {
        setState(() {
          if (response['data'] != null) {
            _meetings = List<Map<String, dynamic>>.from(response['data']);
          } else {
            _meetings = [];
          }
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'error'; // Will show localized string in build
          _isLoading = false;
        });
      }
    }
  }

  // Generate days for the week starting from today
  List<Map<String, dynamic>> _getDays() {
    final now = DateTime.now();
    final days = <Map<String, dynamic>>[];
    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      days.add({
        'day': dayNames[date.weekday % 7],
        'date': date.day.toString(),
        'fullDate': date,
      });
    }
    return days;
  }

  // Filter meetings by selected date
  List<Map<String, dynamic>> get _filteredMeetings {
    final days = _getDays();
    if (_selectedDayIndex >= days.length) return _meetings;

    final selectedDate = days[_selectedDayIndex]['fullDate'] as DateTime;

    return _meetings.where((meeting) {
      final scheduledAt = meeting['scheduled_at'] as String?;
      if (scheduledAt == null) return false;

      try {
        final meetingDate = DateTime.parse(scheduledAt);
        return meetingDate.year == selectedDate.year &&
            meetingDate.month == selectedDate.month &&
            meetingDate.day == selectedDate.day;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Get company info from meeting
  Map<String, dynamic> _getCompanyInfo(Map<String, dynamic> meeting, AppLocalizations l10n) {
    final company = meeting['company'] as Map<String, dynamic>?;
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
  Map<String, String> _getMeetingDetails(Map<String, dynamic> meeting) {
    final result = <String, String>{
      'type': 'Physical',
      'location': '',
      'notes': '',
      'job': '',
    };

    // Use dedicated fields first
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

    // Get job title from dedicated field or job relationship
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

  // Get status color
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

  @override
  Widget build(BuildContext context) {
    final days = _getDays();

    return SafeArea(
      child: Column(
        children: [
          const AppHeader(showLanguageWithActions: true),
          // Main Content Area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
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

                  // Title and Calendar Icon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.interview,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            color: AppTheme.textPrimary,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date Selector Chips
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: days.length,
                      itemBuilder: (context, index) {
                        final day = days[index];
                        final isSelected = _selectedDayIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDayIndex = index;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1E3A8A)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1E3A8A)
                                      : AppTheme.borderColor,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${day['day']} ${day['date']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Interview Cards List
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.failedToLoadInterviews,
                                      style: const TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadMeetings,
                                      child: Text(AppLocalizations.of(context)!.retry),
                                    ),
                                  ],
                                ),
                              )
                            : _filteredMeetings.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.event_busy,
                                          size: 64,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          AppLocalizations.of(context)!.noInterviewsScheduled,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadMeetings,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      itemCount: _filteredMeetings.length,
                                      itemBuilder: (context, index) {
                                        final meeting = _filteredMeetings[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 16),
                                          child: _buildInterviewCard(meeting),
                                        );
                                      },
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewCard(Map<String, dynamic> meeting) {
    final l10n = AppLocalizations.of(context)!;
    final companyInfo = _getCompanyInfo(meeting, l10n);
    final meetingDetails = _getMeetingDetails(meeting);
    final status = meeting['status'] as String? ?? 'requested';
    final scheduledAt = meeting['scheduled_at'] as String?;

    String interviewType = meetingDetails['type'] ?? 'Interview';
    if (interviewType == 'Physical') {
      interviewType = l10n.physicalInterview;
    } else if (interviewType == 'Online') {
      interviewType = l10n.onlineInterview;
    } else if (interviewType == 'Phone') {
      interviewType = l10n.phoneInterview;
    }

    final locationOrLink = meetingDetails['location'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InterviewDetailScreen(
              meeting: meeting,
            ),
          ),
        ).then((result) {
          if (result == true) {
            _loadMeetings();
          }
        });
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Left Section
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Company Name
                        Text(
                          companyInfo['name'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Interview Type
                        Text(
                          interviewType,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Time
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(scheduledAt, l10n),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        if (locationOrLink.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                locationOrLink,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Right Section with status
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          status == 'accepted'
                              ? Icons.check_circle
                              : status == 'rejected'
                                  ? Icons.cancel
                                  : status == 'completed'
                                      ? Icons.task_alt
                                      : status == 'cancelled'
                                          ? Icons.block
                                          : Icons.schedule,
                          size: 32,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status.substring(0, 1).toUpperCase() + status.substring(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Dashed vertical line separator
            Positioned(
              left: null,
              right: 100,
              top: 0,
              bottom: 0,
              child: CustomPaint(
                size: const Size(1, double.infinity),
                painter: _DashedLinePainter(),
              ),
            ),
            // Top semi-circular cutout
            Positioned(
              left: null,
              right: 95,
              top: -8,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Bottom semi-circular cutout
            Positioned(
              left: null,
              right: 95,
              bottom: -8,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for the dashed vertical line
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
