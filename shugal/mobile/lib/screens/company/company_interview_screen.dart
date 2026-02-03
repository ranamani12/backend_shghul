import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_header.dart';
import '../../l10n/app_localizations.dart';
import 'interview_detail_screen.dart';
import 'reschedule_interview_screen.dart';

class CompanyInterviewScreen extends StatefulWidget {
  const CompanyInterviewScreen({super.key});

  @override
  State<CompanyInterviewScreen> createState() => _CompanyInterviewScreenState();
}

class _CompanyInterviewScreenState extends State<CompanyInterviewScreen> {
  int _selectedDayIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _meetings = [];
  DateTime _selectedDate = DateTime.now();

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
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          setState(() {
            _errorMessage = l10n.pleaseLoginToContinue;
            _isLoading = false;
          });
        }
        return;
      }

      final response = await ApiService.get(
        'mobile/meetings',
        token: token,
      );

      print('DEBUG: Meetings API response: $response');

      if (mounted) {
        setState(() {
          if (response['data'] != null) {
            _meetings = List<Map<String, dynamic>>.from(response['data']);
            print('DEBUG: Loaded ${_meetings.length} meetings');
            for (var meeting in _meetings) {
              print('DEBUG: Meeting ID: ${meeting['id']}, scheduled_at: ${meeting['scheduled_at']}, job_id: ${meeting['job_id']}');
            }
          } else {
            _meetings = [];
            print('DEBUG: No meetings data in response');
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
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _errorMessage = l10n.failedToLoadMeetings;
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

  // Get candidate info from meeting
  Map<String, dynamic> _getCandidateInfo(Map<String, dynamic> meeting, AppLocalizations l10n) {
    final candidate = meeting['candidate'] as Map<String, dynamic>?;
    final candidateProfile = candidate?['candidate_profile'] as Map<String, dynamic>?;

    return {
      'id': candidate?['id'],
      'name': candidate?['name'] as String? ?? l10n.unknown,
      'email': candidate?['email'] as String? ?? '',
      'phone': candidateProfile?['mobile_number'] as String? ?? '',
      'title': candidateProfile?['profession_title'] as String? ??
               candidateProfile?['job_title'] as String? ?? l10n.jobSeeker,
      'image': candidateProfile?['profile_image_path'] as String?,
      'address': candidateProfile?['address'] as String? ?? '',
    };
  }

  // Get meeting details from dedicated fields (with fallback to parsing notes for backward compatibility)
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
      // Convert from lowercase API format to display format
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

    // Fall back to parsing notes if dedicated fields are not set (backward compatibility)
    if (interviewType == null || interviewType.isEmpty) {
      final notesStr = meeting['notes'] as String? ?? '';
      if (notesStr.contains('Interview Type:')) {
        final lines = notesStr.split('\n');
        for (final line in lines) {
          if (line.startsWith('Interview Type:')) {
            result['type'] = line.replaceFirst('Interview Type:', '').trim();
          } else if (line.startsWith('Location:') && result['location']!.isEmpty) {
            result['location'] = line.replaceFirst('Location:', '').trim();
          } else if (line.startsWith('Notes:') && result['notes']!.isEmpty) {
            result['notes'] = line.replaceFirst('Notes:', '').trim();
          } else if (line.startsWith('Job:') && result['job']!.isEmpty) {
            result['job'] = line.replaceFirst('Job:', '').trim();
          }
        }
      }
    }

    return result;
  }

  // Format scheduled time
  String _formatTime(String? scheduledAt, [AppLocalizations? l10n]) {
    if (scheduledAt == null) return l10n?.notScheduled ?? 'Not scheduled';

    try {
      final date = DateTime.parse(scheduledAt);
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (e) {
      return 'Not scheduled';
    }
  }

  // Format scheduled date
  String _formatDate(String? scheduledAt) {
    if (scheduledAt == null) return '';

    try {
      final date = DateTime.parse(scheduledAt);
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return '';
    }
  }

  // Get status color
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
    final days = _getDays();

    return SafeArea(
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

                  const SizedBox(height: 20),

                  // Interview Header with Calendar Icon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.interviews,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (!_isLoading)
                              Text(
                                '${_meetings.length} ${l10n.scheduled}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _loadMeetings,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Icon(
                                  Icons.refresh,
                                  size: 22,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: AppTheme.primaryColor,
                                          onPrimary: Colors.white,
                                          onSurface: AppTheme.textPrimary,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Icon(
                                  Icons.calendar_today_outlined,
                                  size: 22,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Day Selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildDaySelector(days),
                  ),

                  const SizedBox(height: 20),

                  // Interview List
                  Expanded(
                    child: _buildContent(l10n),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMeetings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  l10n.retry,
                  style: const TextStyle(color: AppTheme.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final interviews = _filteredMeetings;

    if (interviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noInterviewsScheduledShort,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.interviewsWillAppearHere,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMeetings,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: interviews.length,
        itemBuilder: (context, index) {
          return _buildInterviewCard(
            interviews[index],
            isLast: index == interviews.length - 1,
            l10n: l10n,
          );
        },
      ),
    );
  }

  Widget _buildDaySelector(List<Map<String, dynamic>> days) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length > 7 ? 7 : days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _selectedDayIndex == index;

          // Count meetings for this day
          final dayDate = day['fullDate'] as DateTime;
          final meetingsCount = _meetings.where((meeting) {
            final scheduledAt = meeting['scheduled_at'] as String?;
            if (scheduledAt == null) return false;
            try {
              final meetingDate = DateTime.parse(scheduledAt);
              return meetingDate.year == dayDate.year &&
                  meetingDate.month == dayDate.month &&
                  meetingDate.day == dayDate.day;
            } catch (e) {
              return false;
            }
          }).length;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: isSelected
                    ? null
                    : Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${day['day']} ${day['date']}',
                    style: TextStyle(
                      color: isSelected ? AppTheme.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (meetingsCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.3)
                            : AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$meetingsCount',
                        style: TextStyle(
                          color: isSelected ? AppTheme.white : AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInterviewCard(Map<String, dynamic> meeting, {bool isLast = false, required AppLocalizations l10n}) {
    const double cardHeight = 130.0;
    const double notchRadius = 12.0;

    final candidateInfo = _getCandidateInfo(meeting, l10n);
    final meetingDetails = _getMeetingDetails(meeting);
    final status = meeting['status'] as String? ?? 'requested';
    final scheduledAt = meeting['scheduled_at'] as String?;
    final profileImagePath = candidateInfo['image'] as String?;

    // Determine interview type display
    String interviewType = meetingDetails['type'] ?? l10n.interview;
    if (interviewType == 'Physical') {
      interviewType = l10n.physicalInterview;
    } else if (interviewType == 'Online') {
      interviewType = l10n.onlineInterview;
    } else if (interviewType == 'Phone') {
      interviewType = l10n.phoneInterview;
    }

    // Get location or meeting link
    String locationOrLink = meetingDetails['location'] ?? '';
    if (locationOrLink.isEmpty) {
      locationOrLink = _formatTime(scheduledAt, l10n);
    }

    return GestureDetector(
      onTap: () {
        // Build interview data for detail screen
        final interviewData = {
          'id': meeting['id'],
          'name': candidateInfo['name'],
          'title': candidateInfo['title'],
          'type': interviewType,
          'link': meetingDetails['location'] ?? '',
          'image': profileImagePath,
          'date': _formatDate(scheduledAt),
          'time': _formatTime(scheduledAt),
          'address': candidateInfo['address'],
          'phone': candidateInfo['phone'],
          'email': candidateInfo['email'],
          'status': status,
          'notes': meetingDetails['notes'],
          'job': meetingDetails['job'],
          'scheduled_at': scheduledAt,
          'candidate_id': candidateInfo['id'],
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InterviewDetailScreen(
              interview: interviewData,
              meeting: meeting, // Pass original meeting data for rescheduling
            ),
          ),
        ).then((result) {
          if (result == true) {
            _loadMeetings();
          }
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ticket-style card
          Container(
            height: cardHeight,
            margin: const EdgeInsets.only(bottom: 12),
            child: ClipPath(
              clipper: TicketClipper(notchRadius: notchRadius),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left content area
                    Expanded(
                      flex: 7,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Image
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: profileImagePath != null
                                  ? ClipOval(
                                      child: Image.network(
                                        ApiService.normalizeUrl(profileImagePath),
                                        fit: BoxFit.cover,
                                        width: 48,
                                        height: 48,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.person,
                                          color: AppTheme.primaryColor,
                                          size: 24,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      color: AppTheme.primaryColor,
                                      size: 24,
                                    ),
                            ),
                            const SizedBox(width: 10),

                            // Name, Type, Link
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  // Name and Status row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          candidateInfo['name'] as String,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: AppTheme.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          status.substring(0, 1).toUpperCase() + status.substring(1),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    interviewType,
                                    style: TextStyle(
                                      color: AppTheme.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Time and Job
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatTime(scheduledAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (meetingDetails['job']?.isNotEmpty == true) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        meetingDetails['job']!,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                    // Dotted divider line inside card
                    SizedBox(
                      height: cardHeight,
                      child: CustomPaint(
                        size: const Size(1, cardHeight),
                        painter: DottedLinePainter(color: Colors.grey.shade300),
                      ),
                    ),

                    // Right button area - Chat and Call buttons
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildActionButton(
                                icon: Icons.chat_bubble_outline,
                                onTap: () {
                                  // Open chat
                                },
                              ),
                              const SizedBox(width: 10),
                              _buildActionButton(
                                icon: Icons.phone,
                                onTap: () {
                                  final phone = candidateInfo['phone'] as String?;
                                  if (phone != null && phone.isNotEmpty) {
                                    _makePhoneCall(phone);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppTheme.white,
        ),
      ),
    );
  }
}

// Custom clipper for ticket shape with notches
class TicketClipper extends CustomClipper<Path> {
  final double notchRadius;

  TicketClipper({this.notchRadius = 12.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final notchX = size.width * 0.72;

    path.moveTo(0, 16);
    path.quadraticBezierTo(0, 0, 16, 0);
    path.lineTo(notchX - notchRadius, 0);

    // Top notch (semicircle cutout)
    path.arcToPoint(
      Offset(notchX + notchRadius, 0),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    path.lineTo(size.width - 16, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 16);
    path.lineTo(size.width, size.height - 16);
    path.quadraticBezierTo(size.width, size.height, size.width - 16, size.height);
    path.lineTo(notchX + notchRadius, size.height);

    // Bottom notch (semicircle cutout)
    path.arcToPoint(
      Offset(notchX - notchRadius, size.height),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    path.lineTo(16, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - 16);
    path.lineTo(0, 16);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Custom painter for dotted line
class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter({this.color = const Color(0xFFBDBDBD)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashHeight = 5.0;
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
