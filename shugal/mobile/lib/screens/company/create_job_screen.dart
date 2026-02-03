import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/job_service.dart';
import '../../services/api_service.dart';
import '../../services/lookup_service.dart';
import '../../widgets/app_header.dart';
import '../../l10n/app_localizations.dart';

class CreateJobScreen extends StatefulWidget {
  final Map<String, dynamic>? job;
  final bool isEdit;

  const CreateJobScreen({super.key, this.job, this.isEdit = false});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _salaryRangeController = TextEditingController();
  final TextEditingController _jobDescriptionController = TextEditingController();

  String? _selectedExperience;
  String? _selectedHiringType;
  String? _selectedEmploymentType;
  String? _selectedJobType;
  String _selectedInterviewType = 'Physical';
  bool _isLoading = false;
  bool _isLoadingMajors = true;

  List<Map<String, dynamic>> _majors = [];
  List<int> _selectedMajorIds = [];
  String? _currentLocale;

  final List<String> _experienceLevels = [
    '0-1 Years',
    '1-3 Years',
    '3-5 Years',
    '5-7 Years',
    '7+ Years',
  ];

  final List<String> _hiringTypes = [
    'Immediate',
    'Within 1 Month',
    'Within 3 Months',
    'Flexible',
  ];

  final List<String> _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
  ];

  final List<String> _jobTypes = [
    'Remote',
    'On-site',
    'Hybrid',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill data if editing
    if (widget.isEdit && widget.job != null) {
      _jobTitleController.text = widget.job!['title'] ?? '';
      _salaryRangeController.text = widget.job!['salary_range'] ?? widget.job!['salaryRange'] ?? '';
      _jobDescriptionController.text = widget.job!['description'] ?? '';
      _selectedExperience = widget.job!['experience_level'] ?? widget.job!['experience'];
      _selectedHiringType = widget.job!['hiring_type'] ?? widget.job!['hiringType'];
      _selectedInterviewType = widget.job!['interview_type'] ?? widget.job!['interviewType'] ?? 'Physical';
      // Pre-fill employment type
      final empType = widget.job!['employment_type'] as String?;
      if (empType != null && empType.isNotEmpty) {
        _selectedEmploymentType = empType[0].toUpperCase() + empType.substring(1);
      }
      // Pre-fill job type (work location)
      final jobType = widget.job!['job_type'] as String?;
      if (jobType != null && jobType.isNotEmpty) {
        _selectedJobType = jobType[0].toUpperCase() + jobType.substring(1);
      }
      // Pre-fill selected major IDs if editing
      if (widget.job!['major_ids'] != null) {
        _selectedMajorIds = List<int>.from(widget.job!['major_ids']);
      } else if (widget.job!['majors'] != null) {
        _selectedMajorIds = (widget.job!['majors'] as List)
            .map((m) => m['id'] as int)
            .toList();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLocale = Localizations.localeOf(context).languageCode;
    // Reload majors if locale changed or first load
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      _loadMajors(newLocale);
    }
  }

  Future<void> _loadMajors(String locale) async {
    try {
      final majors = await LookupService.getMajors(locale: locale);
      if (mounted) {
        setState(() {
          _majors = majors;
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

  @override
  void dispose() {
    _jobTitleController.dispose();
    _salaryRangeController.dispose();
    _jobDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Logo and Notification
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
                          Text(
                            widget.isEdit ? AppLocalizations.of(context)!.editJob : AppLocalizations.of(context)!.createJob,
                            style: const TextStyle(
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
                            // Form Card
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
                                  // Fill it header
                                  Text(
                                    AppLocalizations.of(context)!.fillIt,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Job Title
                                  _buildLabel(AppLocalizations.of(context)!.jobTitle),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _jobTitleController,
                                    hintText: AppLocalizations.of(context)!.enterJobTitle,
                                  ),

                                  const SizedBox(height: 16),

                                  // Salary Range
                                  _buildLabel(AppLocalizations.of(context)!.salaryRange),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _salaryRangeController,
                                    hintText: AppLocalizations.of(context)!.salaryRangeHint,
                                  ),

                                  const SizedBox(height: 16),

                                  // Years of Experience
                                  _buildLabel(AppLocalizations.of(context)!.yearsOfExperience),
                                  const SizedBox(height: 8),
                                  _buildDropdown(
                                    value: _selectedExperience,
                                    hintText: AppLocalizations.of(context)!.selectExperienceLevel,
                                    items: _experienceLevels,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedExperience = value;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Type of Hiring
                                  _buildLabel(AppLocalizations.of(context)!.typeOfHiring),
                                  const SizedBox(height: 8),
                                  _buildDropdown(
                                    value: _selectedHiringType,
                                    hintText: AppLocalizations.of(context)!.selectHiringTimeframe,
                                    items: _hiringTypes,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedHiringType = value;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Employment Type
                                  _buildLabel(AppLocalizations.of(context)!.employmentType),
                                  const SizedBox(height: 8),
                                  _buildDropdown(
                                    value: _selectedEmploymentType,
                                    hintText: AppLocalizations.of(context)!.selectEmploymentType,
                                    items: _employmentTypes,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedEmploymentType = value;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Work Location
                                  _buildLabel(AppLocalizations.of(context)!.workLocation),
                                  const SizedBox(height: 8),
                                  _buildDropdown(
                                    value: _selectedJobType,
                                    hintText: AppLocalizations.of(context)!.selectWorkLocation,
                                    items: _jobTypes,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedJobType = value;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Job Description
                                  _buildLabel(AppLocalizations.of(context)!.jobDescription),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _jobDescriptionController,
                                    hintText: AppLocalizations.of(context)!.writeJobDescription,
                                    maxLines: 6,
                                  ),

                                  const SizedBox(height: 16),

                                  // Type of Interview
                                  _buildLabel(AppLocalizations.of(context)!.typeOfInterview),
                                  const SizedBox(height: 12),
                                  _buildInterviewTypeSelector(),

                                  const SizedBox(height: 20),

                                  // Major (Multi-select)
                                  _buildLabel(AppLocalizations.of(context)!.major),
                                  const SizedBox(height: 8),
                                  _buildMajorSelector(),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Create/Update Job Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleCreateJob,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: AppTheme.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        widget.isEdit ? AppLocalizations.of(context)!.updateJob : AppLocalizations.of(context)!.createJob,
                                        style: const TextStyle(
                                          color: AppTheme.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimary,
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
        color: AppTheme.bodySurfaceColor,
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

  Widget _buildDropdown({
    required String? value,
    required String hintText,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.bodySurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hintText,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey.shade500,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInterviewTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bodySurfaceColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedInterviewType = 'Physical';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedInterviewType == 'Physical'
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.physical,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _selectedInterviewType == 'Physical'
                          ? AppTheme.white
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedInterviewType = 'Online';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedInterviewType == 'Online'
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.online,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _selectedInterviewType == 'Online'
                          ? AppTheme.white
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMajorSelector() {
    if (_isLoadingMajors) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bodySurfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.loadingMajors,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _showMajorSelectionDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bodySurfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _selectedMajorIds.isEmpty
            ? Text(
                AppLocalizations.of(context)!.selectMajors,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedMajorIds.map((id) {
                  final major = _majors.firstWhere(
                    (m) => m['id'] == id,
                    orElse: () => {'name': 'Unknown'},
                  );
                  final locale = Localizations.localeOf(context).languageCode;
                  final majorName = LookupService.getLocalizedName(major, locale);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          majorName.isNotEmpty ? majorName : 'Unknown',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMajorIds.remove(id);
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  void _showMajorSelectionDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        List<int> tempSelectedIds = List.from(_selectedMajorIds);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                l10n.selectMajors,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _majors.length,
                  itemBuilder: (context, index) {
                    final major = _majors[index];
                    final majorId = major['id'] as int;
                    final locale = Localizations.localeOf(context).languageCode;
                    final majorName = LookupService.getLocalizedName(major, locale);
                    final isSelected = tempSelectedIds.contains(majorId);
                    return CheckboxListTile(
                      title: Text(
                        majorName,
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: isSelected,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelectedIds.add(majorId);
                          } else {
                            tempSelectedIds.remove(majorId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedMajorIds = tempSelectedIds;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: Text(
                    l10n.done,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleCreateJob() async {
    final l10n = AppLocalizations.of(context)!;
    // Validate form
    if (_jobTitleController.text.isEmpty) {
      _showSnackBar(l10n.pleaseEnterJobTitle);
      return;
    }

    if (_jobDescriptionController.text.isEmpty) {
      _showSnackBar(l10n.pleaseEnterJobDescription);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isEdit && widget.job != null) {
        // Update existing job
        final jobId = widget.job!['id'] as int?;
        if (jobId != null) {
          await JobService.updateJob(
            jobId: jobId,
            title: _jobTitleController.text,
            description: _jobDescriptionController.text,
            experienceLevel: _selectedExperience,
            salaryRange: _salaryRangeController.text,
            hiringType: _selectedHiringType,
            interviewType: _selectedInterviewType,
            jobType: _selectedJobType,
            majorIds: _selectedMajorIds.isNotEmpty ? _selectedMajorIds : null,
          );
          _showSnackBar(l10n.jobUpdatedSuccessfully);
        }
      } else {
        // Create new job
        await JobService.createJob(
          title: _jobTitleController.text,
          description: _jobDescriptionController.text,
          experienceLevel: _selectedExperience,
          salaryRange: _salaryRangeController.text,
          hiringType: _selectedHiringType,
          interviewType: _selectedInterviewType,
          jobType: _selectedJobType,
          majorIds: _selectedMajorIds.isNotEmpty ? _selectedMajorIds : null,
        );
        _showSnackBar(l10n.jobCreatedSuccessfully);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } on ApiException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar(l10n.anErrorOccurred);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
