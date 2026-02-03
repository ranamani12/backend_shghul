import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/lookup_service.dart';
import '../../widgets/app_header.dart';
import '../../l10n/app_localizations.dart';
import 'job_detail_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String? _userName;

  // Jobs from API
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalJobs = 0;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;

  // Majors from API for filtering
  List<Map<String, dynamic>> _majorsData = [];
  List<Map<String, dynamic>> _countriesData = [];
  List<Map<String, dynamic>> _educationLevelsData = [];
  List<Map<String, dynamic>> _experienceYearsData = [];
  List<int> _selectedMajorIds = [];
  String? _selectedLocation;
  String? _selectedHiringType;
  String? _selectedJobType;
  String? _selectedEducationLevel;
  String? _selectedExperience;
  bool _hasActiveFilters = false;
  String? _currentLocale;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadJobs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLocale = Localizations.localeOf(context).languageCode;
    // Reload lookup data if locale changed or first load
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      _loadLookupData(newLocale);
    }
  }

  Future<void> _loadLookupData(String locale) async {
    await Future.wait([
      _loadMajors(locale),
      _loadCountries(locale),
      _loadEducationLevels(locale),
      _loadExperienceYears(locale),
    ]);
  }

  Future<void> _loadMajors(String locale) async {
    try {
      final majors = await LookupService.getMajors(locale: locale);
      if (mounted) {
        setState(() {
          _majorsData = majors;
        });
      }
    } catch (e) {
      // Ignore errors, filters will just not be available
    }
  }

  Future<void> _loadCountries(String locale) async {
    try {
      final countries = await LookupService.getCountries(locale: locale);
      if (mounted) {
        setState(() {
          _countriesData = countries;
        });
      }
    } catch (e) {
      // Ignore errors, filters will just not be available
    }
  }

  Future<void> _loadEducationLevels(String locale) async {
    try {
      final levels = await LookupService.getEducationLevels(locale: locale);
      if (mounted) {
        setState(() {
          _educationLevelsData = levels;
        });
      }
    } catch (e) {
      // Ignore errors, filters will just not be available
    }
  }

  Future<void> _loadExperienceYears(String locale) async {
    try {
      final years = await LookupService.getExperienceYears(locale: locale);
      if (mounted) {
        setState(() {
          _experienceYearsData = years;
        });
      }
    } catch (e) {
      // Ignore errors, filters will just not be available
    }
  }

  Future<void> _loadUserName() async {
    final user = await AuthService.getUser();
    if (mounted) {
      setState(() {
        _userName = user?['name'] as String?;
      });
    }
  }

  Future<void> _loadJobs({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMorePages = true;
      });
    }

    if (!_hasMorePages && !refresh) return;

    try {
      setState(() {
        if (_currentPage == 1) {
          _isLoading = true;
        } else {
          _isLoadingMore = true;
        }
        _errorMessage = null;
      });

      final queryParams = <String, String>{
        'per_page': '15',
        'page': _currentPage.toString(),
      };

      // Add search query if present
      final searchQuery = _searchController.text.trim();
      if (searchQuery.isNotEmpty) {
        queryParams['q'] = searchQuery;
      }

      // Add major filter if selected
      if (_selectedMajorIds.isNotEmpty) {
        queryParams['major_ids'] = _selectedMajorIds.join(',');
      }

      // Add location filter if selected
      if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
        queryParams['location'] = _selectedLocation!;
      }

      // Add hiring type filter if selected
      if (_selectedHiringType != null && _selectedHiringType!.isNotEmpty) {
        queryParams['hiring_type'] = _selectedHiringType!;
      }

      // Add education level filter if selected
      if (_selectedEducationLevel != null && _selectedEducationLevel!.isNotEmpty) {
        queryParams['education_level'] = _selectedEducationLevel!;
      }

      // Add experience filter if selected
      if (_selectedExperience != null && _selectedExperience!.isNotEmpty) {
        queryParams['experience_level'] = _selectedExperience!;
      }

      // Add job type filter if selected
      if (_selectedJobType != null && _selectedJobType!.isNotEmpty) {
        queryParams['job_type'] = _selectedJobType!;
      }

      final response = await ApiService.get('jobs', queryParams: queryParams);

      List<Map<String, dynamic>> jobs = [];
      if (response.containsKey('data')) {
        jobs = (response['data'] as List).map((e) => e as Map<String, dynamic>).toList();
      }

      // Get pagination info
      final lastPage = response['last_page'] as int? ?? 1;
      final total = response['total'] as int? ?? jobs.length;

      if (mounted) {
        setState(() {
          if (_currentPage == 1) {
            _jobs = jobs;
          } else {
            _jobs.addAll(jobs);
          }
          _totalJobs = total;
          _hasMorePages = _currentPage < lastPage;
          _currentPage++;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _refreshJobs() async {
    await _loadJobs(refresh: true);
  }

  void _onSearch() {
    _loadJobs(refresh: true);
  }

  void _updateFilterStatus() {
    setState(() {
      _hasActiveFilters = _selectedMajorIds.isNotEmpty ||
          (_selectedLocation != null && _selectedLocation!.isNotEmpty) ||
          (_selectedHiringType != null && _selectedHiringType!.isNotEmpty) ||
          (_selectedJobType != null && _selectedJobType!.isNotEmpty) ||
          (_selectedEducationLevel != null && _selectedEducationLevel!.isNotEmpty) ||
          (_selectedExperience != null && _selectedExperience!.isNotEmpty);
    });
  }

  void _showFilterModal() {
    final l10n = AppLocalizations.of(context)!;
    // Create temporary copies for the modal
    List<int> tempSelectedMajorIds = List.from(_selectedMajorIds);
    String? tempSelectedLocation = _selectedLocation;
    String? tempSelectedHiringType = _selectedHiringType;
    String? tempSelectedJobType = _selectedJobType;
    String? tempSelectedEducationLevel = _selectedEducationLevel;
    String? tempSelectedExperience = _selectedExperience;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.filterJobs,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempSelectedMajorIds.clear();
                            tempSelectedLocation = null;
                            tempSelectedHiringType = null;
                            tempSelectedJobType = null;
                            tempSelectedEducationLevel = null;
                            tempSelectedExperience = null;
                          });
                        },
                        child: Text(
                          l10n.clearAll,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Filter content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Majors section
                        Text(
                          l10n.majorField,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_majorsData.isEmpty)
                          Text(
                            l10n.loadingMajors,
                            style: const TextStyle(color: AppTheme.textMuted),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _majorsData.map((major) {
                              final locale = Localizations.localeOf(context).languageCode;
                              final majorId = major['id'] as int;
                              final majorName = LookupService.getLocalizedName(major, locale);
                              final isSelected = tempSelectedMajorIds.contains(majorId);
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      tempSelectedMajorIds.remove(majorId);
                                    } else {
                                      tempSelectedMajorIds.add(majorId);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    majorName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 24),

                        // Location section
                        Text(
                          l10n.location,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_countriesData.isEmpty)
                          Text(
                            l10n.loadingLocations,
                            style: const TextStyle(color: AppTheme.textMuted),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _countriesData.map((country) {
                              final locale = Localizations.localeOf(context).languageCode;
                              final countryName = LookupService.getLocalizedName(country, locale);
                              final isSelected = tempSelectedLocation == countryName;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      tempSelectedLocation = null;
                                    } else {
                                      tempSelectedLocation = countryName;
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    countryName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 24),

                        // Hiring Type section (Employment Type: Full-time, Part-time, Contract)
                        Text(
                          l10n.employmentType,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['Full-time', 'Part-time', 'Contract'].map((type) {
                            final isSelected = tempSelectedHiringType == type.toLowerCase();
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    tempSelectedHiringType = null;
                                  } else {
                                    tempSelectedHiringType = type.toLowerCase();
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Job Type section (Work Location: Remote, On-site, Hybrid)
                        Text(
                          l10n.workLocation,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['Remote', 'On-site', 'Hybrid'].map((type) {
                            final isSelected = tempSelectedJobType == type.toLowerCase();
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    tempSelectedJobType = null;
                                  } else {
                                    tempSelectedJobType = type.toLowerCase();
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Education Level section
                        Text(
                          l10n.educationLevel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_educationLevelsData.isEmpty)
                          Text(
                            l10n.loadingEducationLevels,
                            style: const TextStyle(color: AppTheme.textMuted),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _educationLevelsData.map((level) {
                              final locale = Localizations.localeOf(context).languageCode;
                              final levelName = LookupService.getLocalizedName(level, locale);
                              final isSelected = tempSelectedEducationLevel == levelName;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      tempSelectedEducationLevel = null;
                                    } else {
                                      tempSelectedEducationLevel = levelName;
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    levelName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 24),

                        // Experience section
                        Text(
                          l10n.experience,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_experienceYearsData.isEmpty)
                          Text(
                            l10n.loadingExperienceLevels,
                            style: const TextStyle(color: AppTheme.textMuted),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _experienceYearsData.map((exp) {
                              final locale = Localizations.localeOf(context).languageCode;
                              final expName = LookupService.getLocalizedName(exp, locale);
                              final isSelected = tempSelectedExperience == expName;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      tempSelectedExperience = null;
                                    } else {
                                      tempSelectedExperience = expName;
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    expName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
                // Apply button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedMajorIds = tempSelectedMajorIds;
                            _selectedLocation = tempSelectedLocation;
                            _selectedHiringType = tempSelectedHiringType;
                            _selectedJobType = tempSelectedJobType;
                            _selectedEducationLevel = tempSelectedEducationLevel;
                            _selectedExperience = tempSelectedExperience;
                          });
                          _updateFilterStatus();
                          Navigator.pop(context);
                          _loadJobs(refresh: true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.applyFilters,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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

  String _getCompanyInitials(Map<String, dynamic> job) {
    final companyName = _getCompanyName(job);
    if (companyName.isEmpty) return '?';

    final words = companyName.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return companyName.substring(0, companyName.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatSalary(Map<String, dynamic> job, AppLocalizations l10n) {
    final salaryRange = job['salary_range'] as String?;
    if (salaryRange != null && salaryRange.isNotEmpty) {
      return salaryRange;
    }
    return l10n.salaryTbd;
  }

  String _getLocation(Map<String, dynamic> job) {
    final location = job['location'] as String?;
    if (location != null && location.isNotEmpty) {
      return location;
    }
    return 'Kuwait';
  }

  Color _getLogoColor(int index) {
    final colors = [
      const Color(0xFFE53935), // Red
      const Color(0xFF1DA1F2), // Blue
      const Color(0xFF1E1E1E), // Black
      const Color(0xFF10B981), // Green
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFFF9800), // Orange
      const Color(0xFF00BCD4), // Cyan
    ];
    return colors[index % colors.length];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n.goodMorning;
    } else if (hour < 17) {
      return l10n.goodAfternoon;
    } else {
      return l10n.goodEvening;
    }
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
            // ===================== MAIN CONTENT =====================
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
                child: RefreshIndicator(
                  onRefresh: _refreshJobs,
                  child: CustomScrollView(
                    slivers: [
                      // ===================== STATIC CONTENT =====================
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            // Drag handle
                            Center(
                              child: Container(
                                height: 6,
                                width: 60,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Greeting
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade200,
                                    ),
                                    child: const Icon(Icons.person),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getGreeting(l10n),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          _userName ?? l10n.user,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Search bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                        size: 20,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: TextField(
                                          controller: _searchController,
                                          onSubmitted: (_) => _onSearch(),
                                          decoration: InputDecoration(
                                            hintText: l10n.searchJobs,
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
                                    ),
                                    Stack(
                                      children: [
                                        IconButton(
                                          icon: Image.asset(
                                            'assets/images/icons/filter.png',
                                            height: 15,
                                            width: 15,
                                            errorBuilder: (_, __, ___) => Icon(
                                              Icons.tune,
                                              size: 20,
                                              color: _hasActiveFilters
                                                  ? AppTheme.primaryColor
                                                  : AppTheme.textMuted,
                                            ),
                                          ),
                                          onPressed: _showFilterModal,
                                        ),
                                        if (_hasActiveFilters)
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppTheme.primaryColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Majors horizontal list
                            SizedBox(
                              height: 50,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _majorsData.length + 1, // +1 for "All" option
                                itemBuilder: (context, index) {
                                  // First item is "All"
                                  if (index == 0) {
                                    final isSelected = _selectedMajorIds.isEmpty;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedMajorIds.clear();
                                          });
                                          _updateFilterStatus();
                                          _loadJobs(refresh: true);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppTheme.darkPrimaryColor
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(25),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppTheme.primaryColor
                                                  : AppTheme.borderColor,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.menu,
                                                size: 18,
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppTheme.textPrimary,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                l10n.all,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : AppTheme.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  // Major items
                                  final major = _majorsData[index - 1];
                                  final majorId = major['id'] as int;
                                  final majorName = major['name'] as String? ?? '';
                                  final isSelected = _selectedMajorIds.contains(majorId);

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedMajorIds.remove(majorId);
                                          } else {
                                            _selectedMajorIds.add(majorId);
                                          }
                                        });
                                        _updateFilterStatus();
                                        _loadJobs(refresh: true);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.darkPrimaryColor
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(25),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primaryColor
                                                : AppTheme.borderColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.school_outlined,
                                              size: 18,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppTheme.textPrimary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              majorName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Job count
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  l10n.jobsCount(_totalJobs),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),

                      // ===================== JOB LIST =====================
                      if (_isLoading)
                        const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_errorMessage != null)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppTheme.textMuted,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.failedToLoadJobs,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _refreshJobs,
                                  child: Text(l10n.retry),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_jobs.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.work_off_outlined,
                                  color: AppTheme.textMuted,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.noJobsFound,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((context, index) {
                              // Load more when reaching the end
                              if (index == _jobs.length - 3 && _hasMorePages && !_isLoadingMore) {
                                _loadJobs();
                              }

                              if (index == _jobs.length) {
                                // Loading indicator at the bottom
                                if (_isLoadingMore) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }

                              final job = _jobs[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => JobDetailScreen(
                                          jobData: job,
                                        ),
                                      ),
                                    );
                                  },
                                  child: _JobCard(
                                    job: job,
                                    companyName: _getCompanyName(job).isNotEmpty ? _getCompanyName(job) : l10n.unknownCompany,
                                    companyLogo: _getCompanyLogo(job),
                                    companyInitials: _getCompanyInitials(job),
                                    jobTitle: job['title'] as String? ?? l10n.jobTitle,
                                    location: _getLocation(job),
                                    salary: "${_formatSalary(job, l10n)} KWD",
                                    logoColor: _getLogoColor(index),
                                    applyText: l10n.apply,
                                  ),
                                ),
                              );
                            }, childCount: _jobs.length + (_isLoadingMore ? 1 : 0)),
                          ),
                        ),

                      // Bottom padding
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 80),
                      ),
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
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final String companyName;
  final String? companyLogo;
  final String companyInitials;
  final String jobTitle;
  final String location;
  final String salary;
  final Color logoColor;
  final String applyText;

  const _JobCard({
    required this.job,
    required this.companyName,
    required this.companyLogo,
    required this.companyInitials,
    required this.jobTitle,
    required this.location,
    required this.salary,
    required this.logoColor,
    required this.applyText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              // Left Section (Main Content)
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Company Logo and Job Title Row
                      Row(
                        children: [
                          // Company Logo (Circular)
                          Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: logoColor,
                              shape: BoxShape.circle,
                            ),
                            child: companyLogo != null
                                ? ClipOval(
                                    child: Image.network(
                                      companyLogo!,
                                      fit: BoxFit.cover,
                                      width: 55,
                                      height: 55,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          companyInitials,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      companyInitials,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          // Job Title
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  jobTitle,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: AppTheme.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Location
                      const SizedBox(height: 12),
                      // Salary
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.bodySurfaceColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 1,
                                    ),
                                    child: Center(
                                      child: Text(
                                        textAlign: TextAlign.start,
                                        salary,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black,
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
                    ],
                  ),
                ),
              ),

              // Right Section (Apply Button - Ticket Stub)
              Container(
                width: 100,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.darkPrimaryColor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      applyText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
