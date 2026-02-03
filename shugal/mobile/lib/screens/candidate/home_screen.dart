import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/app_header.dart';
import '../../l10n/app_localizations.dart';
import 'job_detail_screen.dart';
import 'jobs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _candidates = [];
  bool _isLoadingJobs = true;
  bool _isLoadingCandidates = true;
  String? _jobsError;
  String? _candidatesError;

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _loadCandidates();
  }

  Future<void> _loadJobs() async {
    try {
      setState(() {
        _isLoadingJobs = true;
        _jobsError = null;
      });

      final response = await ApiService.get('jobs', queryParams: {'per_page': '5'});

      List<Map<String, dynamic>> jobs = [];
      if (response.containsKey('data')) {
        jobs = (response['data'] as List).map((e) => e as Map<String, dynamic>).toList();
      }

      if (mounted) {
        setState(() {
          _jobs = jobs;
          _isLoadingJobs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingJobs = false;
          _jobsError = e.toString();
        });
      }
    }
  }

  Future<void> _loadCandidates() async {
    try {
      setState(() {
        _isLoadingCandidates = true;
        _candidatesError = null;
      });

      final response = await ApiService.get('candidates', queryParams: {'per_page': '5'});

      List<Map<String, dynamic>> candidates = [];
      if (response.containsKey('data')) {
        candidates = (response['data'] as List).map((e) => e as Map<String, dynamic>).toList();
      }

      if (mounted) {
        setState(() {
          _candidates = candidates;
          _isLoadingCandidates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCandidates = false;
          _candidatesError = e.toString();
        });
      }
    }
  }

  String _getCompanyName(Map<String, dynamic> job) {
    final company = job['company'] as Map<String, dynamic>?;
    if (company != null) {
      final companyProfile = company['company_profile'] as Map<String, dynamic>?;
      if (companyProfile != null && companyProfile['company_name'] != null) {
        return companyProfile['company_name'] as String;
      }
      return company['name'] as String? ?? '';
    }
    return '';
  }

  String? _getCompanyLogo(Map<String, dynamic> job) {
    final company = job['company'] as Map<String, dynamic>?;
    if (company != null) {
      final companyProfile = company['company_profile'] as Map<String, dynamic>?;
      if (companyProfile != null && companyProfile['logo_path'] != null) {
        return ApiService.normalizeUrl(companyProfile['logo_path'] as String);
      }
    }
    return null;
  }

  String _formatSalary(Map<String, dynamic> job, AppLocalizations l10n) {
    final salaryRange = job['salary_range'] as String?;
    if (salaryRange != null && salaryRange.isNotEmpty) {
      return salaryRange;
    }
    return l10n.salaryNotSpecified;
  }

  List<String> _getJobTags(Map<String, dynamic> job) {
    final tags = <String>[];

    final hiringType = job['hiring_type'] as String?;
    if (hiringType != null && hiringType.isNotEmpty) {
      tags.add(hiringType);
    }

    final experienceLevel = job['experience_level'] as String?;
    if (experienceLevel != null && experienceLevel.isNotEmpty) {
      tags.add(experienceLevel);
    }

    final location = job['location'] as String?;
    if (location != null && location.isNotEmpty && tags.length < 2) {
      tags.add(location);
    }

    return tags.take(2).toList();
  }

  String? _getCandidateImage(Map<String, dynamic> candidate) {
    final profile = candidate['candidate_profile'] as Map<String, dynamic>?;
    if (profile != null && profile['profile_image_path'] != null) {
      return ApiService.normalizeUrl(profile['profile_image_path'] as String);
    }
    return null;
  }

  String _getCandidateTitle(Map<String, dynamic> candidate, AppLocalizations l10n) {
    final profile = candidate['candidate_profile'] as Map<String, dynamic>?;
    if (profile != null) {
      final professionTitle = profile['profession_title'] as String?;
      if (professionTitle != null && professionTitle.isNotEmpty) {
        return professionTitle;
      }
    }
    return l10n.professional;
  }

  String _getCandidateLocation(Map<String, dynamic> candidate) {
    final profile = candidate['candidate_profile'] as Map<String, dynamic>?;
    if (profile != null) {
      final address = profile['address'] as String?;
      if (address != null && address.isNotEmpty) {
        return address;
      }
    }
    return 'Kuwait';
  }

  List<String> _getCandidateTags(Map<String, dynamic> candidate) {
    final tags = <String>[];
    final profile = candidate['candidate_profile'] as Map<String, dynamic>?;

    if (profile != null) {
      final skills = profile['skills'] as List<dynamic>?;
      if (skills != null && skills.isNotEmpty) {
        for (var skill in skills.take(2)) {
          tags.add(skill.toString());
        }
      }
    }

    return tags;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const AppHeader(showLanguageWithActions: true),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 0),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.bodySurfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(56),
                  topRight: Radius.circular(56),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 6,
                    width: 60,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: TextField(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  hintText: AppLocalizations.of(context)!.search,
                                  icon: const Icon(
                                    Icons.search,
                                    color: AppTheme.textMuted,
                                    size: 30,
                                  ),
                                  hintStyle: const TextStyle(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.tune,
                              color: AppTheme.textMuted,
                            ),
                            onPressed: () {
                              // Handle filter
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await Future.wait([
                          _loadJobs(),
                          _loadCandidates(),
                        ]);
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            // Job Offer Section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.jobOffer,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const JobsScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      AppLocalizations.of(context)!.seeAll,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Jobs List
                            SizedBox(
                              height: 240,
                              child: _isLoadingJobs
                                  ? const Center(child: CircularProgressIndicator())
                                  : _jobsError != null
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.error_outline,
                                                color: AppTheme.textMuted,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                AppLocalizations.of(context)!.failedToLoadJobs,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: _loadJobs,
                                                child: Text(AppLocalizations.of(context)!.retry),
                                              ),
                                            ],
                                          ),
                                        )
                                      : _jobs.isEmpty
                                          ? Center(
                                              child: Text(
                                                AppLocalizations.of(context)!.noJobsAvailable,
                                                style: const TextStyle(
                                                  color: AppTheme.textMuted,
                                                ),
                                              ),
                                            )
                                          : ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10.0,
                                              ),
                                              itemCount: _jobs.length,
                                              itemBuilder: (context, index) {
                                                final job = _jobs[index];
                                                return _buildJobCard(job);
                                              },
                                            ),
                            ),

                            const SizedBox(height: 24),

                            // Candidates Section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.candidates,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Navigate to all candidates
                                    },
                                    child: Text(
                                      AppLocalizations.of(context)!.seeAll,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Candidates List
                            SizedBox(
                              height: 280,
                              child: _isLoadingCandidates
                                  ? const Center(child: CircularProgressIndicator())
                                  : _candidatesError != null
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.error_outline,
                                                color: AppTheme.textMuted,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                AppLocalizations.of(context)!.failedToLoadCandidates,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: _loadCandidates,
                                                child: Text(AppLocalizations.of(context)!.retry),
                                              ),
                                            ],
                                          ),
                                        )
                                      : _candidates.isEmpty
                                          ? Center(
                                              child: Text(
                                                AppLocalizations.of(context)!.noCandidatesAvailable,
                                                style: const TextStyle(
                                                  color: AppTheme.textMuted,
                                                ),
                                              ),
                                            )
                                          : ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                              ),
                                              itemCount: _candidates.length,
                                              itemBuilder: (context, index) {
                                                final candidate = _candidates[index];
                                                return _buildCandidateCard(candidate);
                                              },
                                            ),
                            ),
                            const SizedBox(height: 80),
                          ],
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
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final l10n = AppLocalizations.of(context)!;
    var companyName = _getCompanyName(job);
    if (companyName.isEmpty) companyName = l10n.unknownCompany;
    final companyLogo = _getCompanyLogo(job);
    final title = job['title'] as String? ?? l10n.jobTitle;
    final salary = _formatSalary(job, l10n);
    final tags = _getJobTags(job);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JobDetailScreen(jobData: job),
          ),
        );
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Icon, Name, and Favorite
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: companyLogo != null
                        ? ClipOval(
                            child: Image.network(
                              companyLogo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.business,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.business,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          companyName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(
                      Icons.favorite_border,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Job Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Salary
              Text(
                salary,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Tags
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.bodySurfaceColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 8),
              const Divider(color: AppTheme.bodySurfaceColor, thickness: 1),
              const SizedBox(height: 8),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: 'assets/images/icons/view.png',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => JobDetailScreen(jobData: job),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: 'assets/images/icons/chat.png',
                    onPressed: () {
                      // Handle chat
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCandidateCard(Map<String, dynamic> candidate) {
    final l10n = AppLocalizations.of(context)!;
    final name = candidate['name'] as String? ?? 'Candidate';
    final imageUrl = _getCandidateImage(candidate);
    final title = _getCandidateTitle(candidate, l10n);
    final location = _getCandidateLocation(candidate);
    final tags = _getCandidateTags(candidate);
    final isBlurred = candidate['is_blurred'] as bool? ?? false;

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Icon, Name, and Favorite
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: imageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBlurred ? '********' : name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.favorite_border,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                  onPressed: () {
                    // Handle favorite
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Candidate Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Location
            Text(
              location,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Tags
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bodySurfaceColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 15),
            const Divider(color: AppTheme.bodySurfaceColor, thickness: 2),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: 'assets/images/icons/view.png',
                  onPressed: () {
                    // Handle view
                  },
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: 'assets/images/icons/chat.png',
                  onPressed: () {
                    // Handle chat
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 80,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.bodySurfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: Center(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              AppTheme.primaryColor,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              icon,
              width: 18,
              height: 18,
              errorBuilder: (_, __, ___) => Icon(
                Icons.visibility_outlined,
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
