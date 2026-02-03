import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_header.dart';
import '../../l10n/app_localizations.dart';
import 'applicant_detail_screen.dart';
import '../shared/chat_screen.dart';

class JobApplicantsScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobApplicantsScreen({
    super.key,
    required this.job,
  });

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _applicants = [];

  List<Map<String, String>> _getFilters(AppLocalizations l10n) => [
    {'label': l10n.all, 'icon': ''},
    {'label': l10n.pending, 'icon': ''},
    {'label': l10n.reviewed, 'icon': ''},
    {'label': l10n.shortlisted, 'icon': ''},
  ];

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
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

      final jobId = widget.job['id'];
      final response = await ApiService.get(
        'mobile/company/jobs/$jobId/applicants',
        token: token,
      );

      if (mounted) {
        setState(() {
          if (response['data'] != null) {
            _applicants = List<Map<String, dynamic>>.from(response['data']);
          } else {
            _applicants = [];
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
          _errorMessage = l10n.failedToLoadApplicants;
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredApplicants {
    final query = _searchController.text.toLowerCase();
    var filtered = _applicants;

    // Filter by status
    if (_selectedFilterIndex == 1) {
      filtered = filtered.where((a) => a['status'] == 'pending').toList();
    } else if (_selectedFilterIndex == 2) {
      filtered = filtered.where((a) => a['status'] == 'reviewed').toList();
    } else if (_selectedFilterIndex == 3) {
      filtered = filtered.where((a) => a['status'] == 'shortlisted').toList();
    }

    // Filter by search query
    if (query.isNotEmpty) {
      filtered = filtered.where((a) {
        final candidate = a['candidate'] as Map<String, dynamic>?;
        final name = (candidate?['name'] as String? ?? '').toLowerCase();
        final profile = candidate?['candidate_profile'] as Map<String, dynamic>?;
        final jobTitle = (profile?['profession_title'] as String? ?? '').toLowerCase();
        return name.contains(query) || jobTitle.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getJobTitle(AppLocalizations l10n) {
    return widget.job['title'] as String? ?? l10n.job;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back button and title
                          Row(
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.jobApplicants,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getJobTitle(l10n),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Search Bar
                          _buildSearchBar(l10n),
                          const SizedBox(height: 16),

                          // Filter Chips
                          _buildFilterChips(l10n),
                          const SizedBox(height: 20),

                          // Applicants Count
                          Text(
                            _filteredApplicants.length == 1
                                ? l10n.applicantCount(_filteredApplicants.length)
                                : l10n.applicantCountPlural(_filteredApplicants.length),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Applicant List
                    Expanded(
                      child: _buildContent(l10n),
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
                onPressed: _loadApplicants,
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

    final applicants = _filteredApplicants;

    if (applicants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noApplicantsYet,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.applicationsWillAppearHere,
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
      onRefresh: _loadApplicants,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: applicants.length,
        itemBuilder: (context, index) {
          return _buildApplicantCard(
            applicants[index],
            index,
            l10n,
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Image.asset(
            'assets/images/icons/search.png',
            height: 20,
            width: 20,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.search,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.searchApplicants,
                border: InputBorder.none,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.transparent,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n) {
    final filters = _getFilters(l10n);
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilterIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index == 0)
                    Icon(
                      Icons.menu,
                      size: 18,
                      color: isSelected ? AppTheme.white : AppTheme.textPrimary,
                    ),
                  if (index == 1)
                    Icon(
                      Icons.hourglass_empty,
                      size: 18,
                      color: isSelected ? AppTheme.white : AppTheme.textPrimary,
                    ),
                  if (index == 2)
                    Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: isSelected ? AppTheme.white : AppTheme.textPrimary,
                    ),
                  if (index == 3)
                    Icon(
                      Icons.star_outline,
                      size: 18,
                      color: isSelected ? AppTheme.white : AppTheme.textPrimary,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    filter['label']!,
                    style: TextStyle(
                      color: isSelected ? AppTheme.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicantCard(Map<String, dynamic> application, int index, AppLocalizations l10n) {
    const double cardHeight = 140.0;
    const double notchRadius = 12.0;

    final candidate = application['candidate'] as Map<String, dynamic>?;
    final candidateProfile = candidate?['candidate_profile'] as Map<String, dynamic>?;
    final status = application['status'] as String? ?? 'pending';
    final appliedAt = application['created_at'] as String?;
    final coverLetter = application['cover_letter'] as String?;

    // Get candidate info
    final name = candidate?['name'] as String? ?? l10n.unknown;
    final professionTitle = candidateProfile?['profession_title'] as String? ??
                            candidateProfile?['job_title'] as String? ?? l10n.jobSeeker;
    final profileImagePath = candidateProfile?['profile_image_path'] as String?;

    // Format applied date
    String appliedDateStr = l10n.recently;
    if (appliedAt != null) {
      try {
        final date = DateTime.parse(appliedAt);
        final now = DateTime.now();
        final diff = now.difference(date);
        if (diff.inDays == 0) {
          if (diff.inHours == 0) {
            appliedDateStr = l10n.minutesAgo(diff.inMinutes);
          } else {
            appliedDateStr = l10n.hoursAgo(diff.inHours);
          }
        } else if (diff.inDays == 1) {
          appliedDateStr = l10n.dayAgo;
        } else if (diff.inDays < 7) {
          appliedDateStr = l10n.daysAgo(diff.inDays);
        } else {
          appliedDateStr = l10n.weeksAgo((diff.inDays / 7).floor());
        }
      } catch (e) {
        appliedDateStr = l10n.recently;
      }
    }

    // Get status color
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

    // Determine card color based on index
    final colors = [Colors.blue, Colors.pink, Colors.green, Colors.orange, Colors.purple];
    final colorIndex = index % colors.length;
    final iconColor = colors[colorIndex];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Ticket-style card
        Container(
          height: cardHeight,
          margin: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              // Main card with ticket shape
              ClipPath(
                clipper: _TicketClipper(notchRadius: notchRadius),
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
                            children: [
                              // Profile Image
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: profileImagePath != null
                                    ? ClipOval(
                                        child: Image.network(
                                          ApiService.normalizeUrl(profileImagePath),
                                          fit: BoxFit.cover,
                                          width: 52,
                                          height: 52,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.person,
                                            color: iconColor,
                                            size: 28,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        color: iconColor,
                                        size: 28,
                                      ),
                              ),
                              const SizedBox(width: 10),

                              // Name, Title, Status
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppTheme.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      professionTitle,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.access_time,
                                          size: 12,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          appliedDateStr,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (coverLetter != null && coverLetter.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.message_outlined,
                                            size: 12,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              l10n.hasCoverLetter,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade500,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 25),
                      // Dotted divider line inside card
                      SizedBox(
                        height: cardHeight,
                        child: CustomPaint(
                          size: const Size(1, cardHeight),
                          painter: _DottedLinePainter(color: Colors.grey.shade300),
                        ),
                      ),

                      // Right button area
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Chat button
                            GestureDetector(
                              onTap: () {
                                final candidateId = candidate?['id'] as int?;
                                if (candidateId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        userId: candidateId,
                                        userName: name,
                                        userImage: profileImagePath,
                                        userRole: 'candidate',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline,
                                  color: AppTheme.primaryColor,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // View button
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ApplicantDetailScreen(
                                      application: application,
                                      job: widget.job,
                                    ),
                                  ),
                                ).then((result) {
                                  if (result == true) {
                                    _loadApplicants();
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  l10n.view,
                                  style: const TextStyle(
                                    color: AppTheme.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

// Custom clipper for ticket shape with notches
class _TicketClipper extends CustomClipper<Path> {
  final double notchRadius;

  _TicketClipper({this.notchRadius = 12.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final notchX = size.width * 0.72;

    path.moveTo(0, 16);
    path.quadraticBezierTo(0, 0, 16, 0);
    path.lineTo(notchX - notchRadius, 0);

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
class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({this.color = const Color(0xFFBDBDBD)});

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
