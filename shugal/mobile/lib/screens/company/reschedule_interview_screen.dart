import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_header.dart';

class RescheduleInterviewScreen extends StatefulWidget {
  final Map<String, dynamic> meeting;

  const RescheduleInterviewScreen({super.key, required this.meeting});

  @override
  State<RescheduleInterviewScreen> createState() => _RescheduleInterviewScreenState();
}

class _RescheduleInterviewScreenState extends State<RescheduleInterviewScreen> {
  String _selectedInterviewType = 'Physical';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  final List<String> _interviewTypes = ['Physical', 'Online', 'Phone'];

  @override
  void initState() {
    super.initState();
    _initializeFromMeeting();
  }

  void _initializeFromMeeting() {
    // Parse scheduled_at to set date and time
    final scheduledAt = widget.meeting['scheduled_at'] as String?;
    if (scheduledAt != null) {
      try {
        final dateTime = DateTime.parse(scheduledAt);
        _selectedDate = dateTime;
        _selectedTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
      } catch (e) {
        // Keep defaults
      }
    }

    // Use dedicated fields first, fall back to parsing notes for backward compatibility
    final interviewType = widget.meeting['interview_type'] as String?;
    if (interviewType != null) {
      // Convert from lowercase API format to display format
      _selectedInterviewType = interviewType.substring(0, 1).toUpperCase() + interviewType.substring(1);
      if (!_interviewTypes.contains(_selectedInterviewType)) {
        _selectedInterviewType = 'Physical';
      }
    } else {
      // Fall back to parsing notes for backward compatibility
      final notes = widget.meeting['notes'] as String? ?? '';
      final parsedNotes = _parseNotes(notes);
      _selectedInterviewType = parsedNotes['interviewType'] ?? 'Physical';
      if (!_interviewTypes.contains(_selectedInterviewType)) {
        _selectedInterviewType = 'Physical';
      }
    }

    // Use dedicated location field first
    final location = widget.meeting['location'] as String?;
    if (location != null && location.isNotEmpty) {
      _addressController.text = location;
    } else {
      final notes = widget.meeting['notes'] as String? ?? '';
      final parsedNotes = _parseNotes(notes);
      _addressController.text = parsedNotes['location'] ?? '';
    }

    // Notes field
    _noteController.text = widget.meeting['notes'] as String? ?? '';
  }

  Map<String, String> _parseNotes(String notes) {
    final result = <String, String>{};
    final lines = notes.split('\n');

    for (final line in lines) {
      if (line.startsWith('Interview Type: ')) {
        result['interviewType'] = line.substring('Interview Type: '.length);
      } else if (line.startsWith('Location: ')) {
        result['location'] = line.substring('Location: '.length);
      } else if (line.startsWith('Notes: ')) {
        result['notes'] = line.substring('Notes: '.length);
      } else if (line.startsWith('Job: ')) {
        result['job'] = line.substring('Job: '.length);
      }
    }

    return result;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _rescheduleInterview() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
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

      final meetingId = widget.meeting['id'];
      if (meetingId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid meeting'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Combine date and time
      final scheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Build request body with dedicated fields
      final body = {
        'scheduled_at': scheduledAt.toIso8601String(),
        'interview_type': _selectedInterviewType.toLowerCase(),
        'location': _addressController.text.isNotEmpty ? _addressController.text : null,
        'notes': _noteController.text.isNotEmpty ? _noteController.text : null,
      };

      await ApiService.patch(
        'mobile/meetings/$meetingId',
        body,
        token: token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interview rescheduled successfully!'),
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
            content: Text('Failed to reschedule interview: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidate = widget.meeting['candidate'] as Map<String, dynamic>?;
    final candidateProfile = candidate?['candidate_profile'] as Map<String, dynamic>?;

    final name = candidate?['name'] as String? ?? 'Unknown';
    final email = candidate?['email'] as String? ?? '';
    final mobileNumber = candidateProfile?['mobile_number'] as String? ?? '';
    final professionTitle = candidateProfile?['profession_title'] as String? ??
                            candidateProfile?['job_title'] as String? ?? 'Job Seeker';
    final profileImagePath = candidateProfile?['profile_image_path'] as String?;
    final address = candidateProfile?['address'] as String? ?? '';

    // Get job title from dedicated field or job relationship
    final job = widget.meeting['job'] as Map<String, dynamic>?;
    String jobTitle = widget.meeting['job_title'] as String? ??
                      job?['title'] as String? ??
                      'Interview';

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
                            'Reschedule Interview',
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
                            // Candidate Profile Section
                            Container(
                              padding: const EdgeInsets.all(16),
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
                              child: Row(
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
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
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
                                          professionTitle,
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            jobTitle,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Contact Section
                            const Text(
                              'Contact Information',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  if (email.isNotEmpty)
                                    _buildContactItem(
                                      icon: Icons.email_outlined,
                                      text: email,
                                    ),
                                  if (email.isNotEmpty && mobileNumber.isNotEmpty)
                                    const SizedBox(height: 12),
                                  if (mobileNumber.isNotEmpty)
                                    _buildContactItem(
                                      icon: Icons.phone_outlined,
                                      text: mobileNumber,
                                    ),
                                  if ((email.isNotEmpty || mobileNumber.isNotEmpty) && address.isNotEmpty)
                                    const SizedBox(height: 12),
                                  if (address.isNotEmpty)
                                    _buildContactItem(
                                      icon: Icons.location_on_outlined,
                                      text: address,
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Interview Schedule Section
                            const Text(
                              'New Interview Schedule',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Type of Interview Dropdown
                            const Text(
                              'Type Of Interview',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDropdown(),

                            const SizedBox(height: 16),

                            // Date and Time Row
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Interview Date',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDatePicker(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Time',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildTimePicker(),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Detail Address / Meeting Link
                            Text(
                              _selectedInterviewType == 'Online'
                                  ? 'Meeting Link'
                                  : 'Interview Location',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _addressController,
                              hintText: _selectedInterviewType == 'Online'
                                  ? 'Enter meeting link (Zoom, Google Meet, etc.)'
                                  : 'Enter interview location address',
                            ),

                            const SizedBox(height: 16),

                            // Note
                            const Text(
                              'Additional Notes (Optional)',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _noteController,
                              hintText: 'Add any additional information for the candidate...',
                              maxLines: 4,
                            ),

                            const SizedBox(height: 30),

                            // Reschedule Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _rescheduleInterview,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Reschedule Interview',
                                        style: TextStyle(
                                          color: AppTheme.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 30),
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

  Widget _buildContactItem({
    required IconData icon,
    required String text,
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
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedInterviewType,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey.shade500,
          ),
          items: _interviewTypes.map((String type) {
            IconData icon;
            switch (type) {
              case 'Online':
                icon = Icons.videocam_outlined;
                break;
              case 'Phone':
                icon = Icons.phone_outlined;
                break;
              default:
                icon = Icons.location_on_outlined;
            }
            return DropdownMenuItem<String>(
              value: type,
              child: Row(
                children: [
                  Icon(icon, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    type,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedInterviewType = newValue;
                _addressController.clear();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _formatDate(_selectedDate),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: () => _selectTime(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatTime(_selectedTime),
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
            Icon(
              Icons.access_time,
              size: 18,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
