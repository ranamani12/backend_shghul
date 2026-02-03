import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/company_service.dart';
import '../../services/api_service.dart';
import '../../widgets/app_header.dart';
import '../../l10n/app_localizations.dart';
import 'company_candidate_detail_screen.dart';

class CandidateListScreen extends StatefulWidget {
  const CandidateListScreen({super.key});

  @override
  State<CandidateListScreen> createState() => _CandidateListScreenState();
}

class _CandidateListScreenState extends State<CandidateListScreen> {
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isUnlocking = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _candidates = [];

  List<Map<String, String>> _getFilters(AppLocalizations l10n) => [
    {'label': l10n.all, 'icon': ''},
    {'label': l10n.unlocked, 'icon': 'assets/images/icons/lock.png'},
    {'label': l10n.locked, 'icon': 'assets/images/icons/lock.png'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await CompanyService.getCandidates(perPage: 50);
      if (mounted) {
        setState(() {
          if (response['data'] != null) {
            _candidates = List<Map<String, dynamic>>.from(response['data']);
          } else {
            _candidates = [];
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
          _errorMessage = AppLocalizations.of(context)!.failedToLoadCandidates;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unlockCandidate(Map<String, dynamic> candidate) async {
    final candidateId = candidate['id'] as int?;
    if (candidateId == null) return;

    setState(() {
      _isUnlocking = true;
    });

    try {
      await CompanyService.unlockCandidate(candidateId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.candidateUnlockedSuccessfully),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _loadCandidates();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToUnlockCandidate),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUnlocking = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredCandidates {
    if (_selectedFilterIndex == 0) {
      return _candidates;
    } else if (_selectedFilterIndex == 1) {
      // Unlocked only
      return _candidates.where((c) => c['is_unlocked'] == true).toList();
    } else {
      // Locked only
      return _candidates.where((c) => c['is_unlocked'] != true).toList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          // Back button
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back,
                              color: AppTheme.textPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Search Bar
                          _buildSearchBar(),
                          const SizedBox(height: 16),

                          // Filter Chips
                          _buildFilterChips(),
                          const SizedBox(height: 20),

                          // Candidate Title
                          Text(
                            AppLocalizations.of(context)!.candidates,
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

                    // Candidate List
                    Expanded(
                      child: _buildContent(),
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

  Widget _buildContent() {
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
                onPressed: _loadCandidates,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.retry,
                  style: const TextStyle(color: AppTheme.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final candidates = _filteredCandidates;

    if (candidates.isEmpty) {
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
              AppLocalizations.of(context)!.noCandidatesFound,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadCandidates,
          color: AppTheme.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              return _buildCandidateCard(
                candidates[index],
                isLast: index == candidates.length - 1,
              );
            },
          ),
        ),
        if (_isUnlocking)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppTheme.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
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
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.search,
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
            IconButton(
              icon: Image.asset(
                'assets/images/icons/filter.png',
                height: 15,
                width: 15,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.tune,
                  size: 20,
                ),
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = _getFilters(AppLocalizations.of(context)!);
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
                      Icons.lock_open,
                      size: 18,
                      color: isSelected ? AppTheme.white : AppTheme.textPrimary,
                    ),
                  if (index == 2)
                    Icon(
                      Icons.lock,
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

  Widget _buildCandidateCard(Map<String, dynamic> candidate, {bool isLast = false}) {
    final l10n = AppLocalizations.of(context)!;
    const double cardHeight = 120.0;
    const double notchRadius = 12.0;

    final isUnlocked = candidate['is_unlocked'] as bool? ?? false;
    final candidateProfile = candidate['candidate_profile'] as Map<String, dynamic>?;

    // Get candidate info
    String name = l10n.unknown;
    String jobTitle = l10n.jobSeeker;
    String experience = '';
    String? profileImagePath;

    // Profile image can be at different locations in the response
    profileImagePath = candidate['profile_image_path'] as String? ??
                       candidateProfile?['profile_image_path'] as String?;

    if (isUnlocked) {
      name = candidate['name'] as String? ?? l10n.unknown;
      jobTitle = candidateProfile?['job_title'] as String? ??
                 candidate['job_title'] as String? ?? l10n.jobSeeker;
      final experienceName = candidate['experience_name'] as String? ??
                             candidateProfile?['experience_name'] as String?;
      if (experienceName != null && experienceName.isNotEmpty) {
        experience = experienceName;
      }
    } else {
      // For locked candidates, show limited info
      jobTitle = candidateProfile?['job_title'] as String? ??
                 candidate['job_title'] as String? ?? l10n.jobSeeker;
    }

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
                            children: [
                              // Profile Image
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: profileImagePath != null
                                    ? ClipOval(
                                        child: Image.network(
                                          ApiService.normalizeUrl(profileImagePath),
                                          fit: BoxFit.cover,
                                          width: 48,
                                          height: 48,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.person,
                                            color: Colors.grey.shade400,
                                            size: 24,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        color: Colors.grey.shade400,
                                        size: 24,
                                      ),
                              ),
                              const SizedBox(width: 10),

                              // Name, Title, Experience
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            isUnlocked ? name : '••••••••',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: isUnlocked
                                                  ? AppTheme.textPrimary
                                                  : Colors.grey.shade400,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (!isUnlocked)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              l10n.locked,
                                              style: const TextStyle(
                                                fontSize: 9,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      jobTitle,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (experience.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F5F5),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Text(
                                          experience,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textPrimary,
                                          ),
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
                      const SizedBox(width: 25),
                      // Dotted divider line inside card
                      SizedBox(
                        height: cardHeight,
                        child: CustomPaint(
                          size: const Size(1, cardHeight),
                          painter: DottedLinePainter(color: Colors.grey.shade300),
                        ),
                      ),

                      // Right button area
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: GestureDetector(
                            onTap: () {
                              if (isUnlocked) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CompanyCandidateDetailScreen(candidate: candidate),
                                  ),
                                );
                              } else {
                                // Show unlock confirmation
                                _showUnlockConfirmation(candidate);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isUnlocked
                                    ? AppTheme.primaryColor
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isUnlocked ? l10n.detail : l10n.unlock,
                                style: const TextStyle(
                                  color: AppTheme.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
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
      ],
    );
  }

  void _showUnlockConfirmation(Map<String, dynamic> candidate) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(l10n.unlockCandidate),
        content: Text(l10n.unlockCandidateConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _unlockCandidate(candidate);
            },
            child: Text(
              l10n.unlock,
              style: const TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
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
    final notchX = size.width * 0.72; // Position of the notch

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
