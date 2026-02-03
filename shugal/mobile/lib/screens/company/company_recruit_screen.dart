import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/job_service.dart';
import '../../services/api_service.dart';
import '../../services/lookup_service.dart';
import '../../widgets/app_header.dart';
import 'create_job_screen.dart';
import 'company_job_detail_screen.dart';

class CompanyRecruitScreen extends StatefulWidget {
  const CompanyRecruitScreen({super.key});

  @override
  State<CompanyRecruitScreen> createState() => _CompanyRecruitScreenState();
}

class _CompanyRecruitScreenState extends State<CompanyRecruitScreen> {
  int? _selectedMajorId;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isLoadingMajors = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _allJobs = [];
  List<Map<String, dynamic>> _majorsData = [];

  @override
  void initState() {
    super.initState();
    _loadMajors();
    _loadJobs();
  }

  Future<void> _loadMajors() async {
    try {
      final majors = await LookupService.getMajors();
      if (mounted) {
        setState(() {
          _majorsData = majors;
          _isLoadingMajors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMajors = false;
        });
      }
    }
  }

  Future<void> _loadJobs() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await JobService.getCompanyJobs(perPage: 50);
      if (mounted) {
        setState(() {
          // Handle paginated response
          if (response['data'] != null) {
            _allJobs = List<Map<String, dynamic>>.from(response['data']);
            _applyFilters();
          } else {
            _allJobs = [];
            _jobs = [];
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
          _errorMessage = 'Failed to load jobs. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    if (_selectedMajorId == null) {
      _jobs = List.from(_allJobs);
    } else {
      _jobs = _allJobs.where((job) {
        final majorIds = job['major_ids'] as List<dynamic>?;
        if (majorIds == null) return false;
        return majorIds.contains(_selectedMajorId);
      }).toList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddJobDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateJobScreen(),
      ),
    );

    // Refresh list if job was created
    if (result == true) {
      _loadJobs();
    }
  }

  void _showEditJobDialog(Map<String, dynamic> job) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateJobScreen(job: job, isEdit: true),
      ),
    );

    // Refresh list if job was updated
    if (result == true) {
      _loadJobs();
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Job'),
        content: Text('Are you sure you want to delete "${job['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteJob(job);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteJob(Map<String, dynamic> job) async {
    final jobId = job['id'] as int?;
    if (jobId == null) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await JobService.deleteJob(jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Job deleted successfully'),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _loadJobs();
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
            content: const Text('Failed to delete job. Please try again.'),
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
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

                  // Search Bar and Add Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(child: _buildSearchBar()),
                        const SizedBox(width: 12),
                        _buildAddButton(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filter Chips
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: _buildFilterChips(),
                  ),

                  const SizedBox(height: 20),

                  // Job Postings List
                  Expanded(
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                onPressed: _loadJobs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: AppTheme.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_off_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No job postings yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first job',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadJobs,
          color: AppTheme.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _jobs.length,
            itemBuilder: (context, index) {
              return _buildJobCard(_jobs[index]);
            },
          ),
        ),
        if (_isDeleting)
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
            errorBuilder: (_, __, ___) => Icon(
              Icons.search,
              size: 22,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: Image.asset(
              'assets/images/icons/filter.png',
              height: 18,
              width: 18,
              errorBuilder: (_, __, ___) => Icon(
                Icons.tune,
                size: 20,
                color: Colors.grey.shade500,
              ),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showAddJobDialog,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.add,
          color: AppTheme.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    if (_isLoadingMajors) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _majorsData.length + 1, // +1 for "All" option
        itemBuilder: (context, index) {
          // First item is "All"
          if (index == 0) {
            final isSelected = _selectedMajorId == null;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMajorId = null;
                  _applyFilters();
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  'All',
                  style: TextStyle(
                    color: isSelected ? AppTheme.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }

          final major = _majorsData[index - 1];
          final majorId = major['id'] as int;
          final majorName = major['name'] as String? ?? '';
          final isSelected = _selectedMajorId == majorId;

          return GestureDetector(
            onTap: () {
              setState(() {
                if (_selectedMajorId == majorId) {
                  _selectedMajorId = null; // Deselect
                } else {
                  _selectedMajorId = majorId;
                }
                _applyFilters();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                ),
              ),
              child: Text(
                majorName,
                style: TextStyle(
                  color: isSelected ? AppTheme.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final title = job['title'] as String? ?? 'No Title';
    final experienceLevel = job['experience_level'] as String? ?? '';
    final salaryRange = job['salary_range'] as String? ?? '';
    final hiringType = job['hiring_type'] as String? ?? '';
    final applicationsCount = job['applications_count'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CompanyJobDetailScreen(job: job),
          ),
        ).then((result) {
          if (result == true) {
            _loadJobs();
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Title and Status
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (job['is_active'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Experience & Salary
          if (experienceLevel.isNotEmpty || salaryRange.isNotEmpty)
            Row(
              children: [
                if (experienceLevel.isNotEmpty) ...[
                  Icon(
                    Icons.work_outline,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    experienceLevel,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (experienceLevel.isNotEmpty && salaryRange.isNotEmpty)
                  Text(
                    '  •  ',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                if (salaryRange.isNotEmpty) ...[
                  Icon(
                    Icons.attach_money,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  Text(
                    salaryRange,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),

          if (hiringType.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  hiringType,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],

          // Applications count
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 14,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                '$applicationsCount applications',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Edit Button
              GestureDetector(
                onTap: () => _showEditJobDialog(job),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppTheme.green,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Edit',
                        style: TextStyle(
                          color: AppTheme.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Delete Button
              GestureDetector(
                onTap: () => _showDeleteConfirmation(job),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
    );
  }
}
