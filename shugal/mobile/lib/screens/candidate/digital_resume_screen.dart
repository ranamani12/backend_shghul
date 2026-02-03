import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/lookup_service.dart';
import '../../services/api_service.dart';
import '../../widgets/app_header.dart';
import '../../l10n/app_localizations.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class DigitalResumeScreen extends StatefulWidget {
  const DigitalResumeScreen({super.key});

  @override
  State<DigitalResumeScreen> createState() => _DigitalResumeScreenState();
}

class _DigitalResumeScreenState extends State<DigitalResumeScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUploadingCV = false;

  // Lookup data for mapping IDs to names
  List<Map<String, dynamic>> _countriesData = [];
  List<Map<String, dynamic>> _majorsData = [];
  List<Map<String, dynamic>> _educationData = [];
  List<Map<String, dynamic>> _experienceData = [];

  String? _currentLocale;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLocale = Localizations.localeOf(context).languageCode;
    // Reload data if locale changed or first load
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final locale = Localizations.localeOf(context).languageCode;

    try {
      // First, try to get fresh data from API
      final token = await AuthService.getToken();
      Map<String, dynamic>? userData;

      if (token != null) {
        try {
          // Fetch fresh profile data from API
          final response = await ApiService.get('mobile/candidate/profile', token: token);
          userData = response;
        } catch (e) {
          // Fallback to cached data
          userData = await AuthService.getUser();
        }
      } else {
        userData = await AuthService.getUser();
      }

      // Load lookup data in parallel with locale
      final results = await Future.wait([
        LookupService.getCountries(locale: locale),
        LookupService.getMajors(locale: locale),
        LookupService.getEducationLevels(locale: locale),
        LookupService.getExperienceYears(locale: locale),
      ]);

      setState(() {
        _userData = userData;
        _countriesData = results[0];
        _majorsData = results[1];
        _educationData = results[2];
        _experienceData = results[3];
        _isLoading = false;
      });
    } catch (e) {
      // If API fails, try to use cached data
      try {
        final userData = await AuthService.getUser();
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      } catch (e2) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// Get the current locale code from context
  String _getLocale(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }

  String? _getCountryName(int? countryId, String locale) {
    if (countryId == null || _countriesData.isEmpty) return null;
    return LookupService.getLocalizedNameById(_countriesData, countryId, locale);
  }

  String? _getMajorNames(List<dynamic>? majorIds, String locale) {
    if (majorIds == null || majorIds.isEmpty || _majorsData.isEmpty) return null;
    try {
      final names = majorIds.map((id) {
        return LookupService.getLocalizedNameById(_majorsData, id as int?, locale);
      }).where((name) => name != null && name.isNotEmpty).cast<String>().toList();
      return names.isEmpty ? null : names.join(', ');
    } catch (e) {
      return null;
    }
  }

  String? _getLookupName(int? lookupId, List<Map<String, dynamic>> lookupData, String locale) {
    if (lookupId == null || lookupData.isEmpty) return null;
    return LookupService.getLocalizedNameById(lookupData, lookupId, locale);
  }

  Future<void> _pickAndUploadCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected file not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _isUploadingCV = true;
      });

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await ApiService.uploadFile(
        'mobile/candidate/profile/cv',
        file,
        'cv',
        token: token,
      );

      if (response.containsKey('url')) {
        // Refresh user data
        await _loadData();
      }

      if (!mounted) return;

      setState(() {
        _isUploadingCV = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CV uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingCV = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingCV = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openCV(String cvPath) async {
    final normalizedPath = ApiService.normalizeUrl(cvPath);
    final uri = Uri.parse(normalizedPath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open CV'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final profileData = _userData?['candidate_profile'] ?? {};
    final userName = _userData?['name'] ?? '';
    final userEmail = _userData?['email'] ?? '';
    final profileImage = profileData['profile_image_path'];
    final jobTitle = profileData['profession_title'] ?? 
                     profileData['job_title'] ?? 
                     profileData['title'] ?? 
                     '';
    final address = profileData['address'];
    final phone = profileData['mobile_number'];
    final website = profileData['upwork_profile_url'] ?? profileData['website'];
    final description = profileData['summary'];
    final qrCodePath = profileData['qr_code_path'];
    final cvPath = profileData['cv_path'];
    final availability = profileData['availability'];
    final publicSlug = profileData['public_slug'];

    // Additional fields - handle different data types
    final dateOfBirth = profileData['date_of_birth'];
    final nationalityId = profileData['nationality_country_id'] is int 
        ? profileData['nationality_country_id'] as int?
        : (profileData['nationality_country_id'] != null 
            ? int.tryParse(profileData['nationality_country_id'].toString()) 
            : null);
    final residenceId = profileData['resident_country_id'] is int
        ? profileData['resident_country_id'] as int?
        : (profileData['resident_country_id'] != null
            ? int.tryParse(profileData['resident_country_id'].toString())
            : null);
    final majorIds = profileData['major_ids'];
    final educationId = profileData['education_id'] is int
        ? profileData['education_id'] as int?
        : (profileData['education_id'] != null
            ? int.tryParse(profileData['education_id'].toString())
            : null);
    final experienceId = profileData['years_of_experience_id'] is int
        ? profileData['years_of_experience_id'] as int?
        : (profileData['years_of_experience_id'] != null
            ? int.tryParse(profileData['years_of_experience_id'].toString())
            : null);
    final skills = profileData['skills'];
    
    // Convert major_ids to List if it's not already
    List<dynamic>? majorIdsList;
    if (majorIds != null) {
      if (majorIds is List) {
        majorIdsList = majorIds;
      } else if (majorIds is String) {
        try {
          majorIdsList = (majorIds.split(',') as List).map((id) => int.tryParse(id.trim())).where((id) => id != null).toList();
        } catch (e) {
          majorIdsList = null;
        }
      }
    }
    
    final locale = _getLocale(context);
    final nationality = _getCountryName(nationalityId, locale);
    final residence = _getCountryName(residenceId, locale);
    final majors = _getMajorNames(majorIdsList, locale);
    final education = _getLookupName(educationId, _educationData, locale);
    final experience = _getLookupName(experienceId, _experienceData, locale);
    
    List<String> skillsList = [];
    if (skills != null) {
      if (skills is List) {
        skillsList = skills.map((s) => s.toString()).where((s) => s.isNotEmpty).toList();
      } else if (skills is String) {
        skillsList = skills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
    }

    return SafeArea(
      child: Column(
        children: [
          const AppHeader(showLanguageWithActions: true),

          // Main Content Area with White Card
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.bodySurfaceColor, // Light gray background for the container
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(56),
                  topRight: Radius.circular(56),
                ),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      height: 6,
                      width: 60,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // White Card containing all resume content
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.white, // White card background
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          // Screen Title with Edit Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Digital Resume',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _showEditModal(context),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                            // Profile Summary Section
                            Row(
                              children: [
                                // Profile Picture
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: AppTheme.bodySurfaceColor,
                                  backgroundImage: profileImage != null
                                      ? NetworkImage(ApiService.normalizeUrl(profileImage))
                                      : null,
                                  child: profileImage == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 30,
                                          color: AppTheme.textSecondary,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                // Name and Title
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        jobTitle,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Contact Information Section
                            const Text(
                              'Contact',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (address != null && address.toString().isNotEmpty) ...[
                              _ContactItem(
                                icon: Icons.location_on_outlined,
                                text: address.toString(),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (phone != null && phone.toString().isNotEmpty) ...[
                              _ContactItem(
                                icon: Icons.phone_outlined,
                                text: phone.toString(),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (userEmail.isNotEmpty) ...[
                              _ContactItem(
                                icon: Icons.email_outlined,
                                text: userEmail,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (website != null && website.toString().isNotEmpty) ...[
                              _ContactItem(
                                icon: Icons.language_outlined,
                                text: website.toString(),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 32),

                            // Personal Information Section
                            if (dateOfBirth != null || nationalityId != null || residenceId != null) ...[
                              const Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (dateOfBirth != null) ...[
                                _ContactItem(
                                  icon: Icons.calendar_today_outlined,
                                  text: _formatDate(dateOfBirth.toString()),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (nationalityId != null) ...[
                                _ContactItem(
                                  icon: Icons.flag_outlined,
                                  text: 'Nationality: ${nationality ?? "Country ID: $nationalityId"}',
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (residenceId != null) ...[
                                _ContactItem(
                                  icon: Icons.home_outlined,
                                  text: 'Residence: ${residence ?? "Country ID: $residenceId"}',
                                ),
                                const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 32),
                            ],

                            // Professional Information Section
                            if (majorIdsList != null || educationId != null || experienceId != null) ...[
                              const Text(
                                'Professional Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (majorIdsList != null && majorIdsList!.isNotEmpty) ...[
                                _ContactItem(
                                  icon: Icons.school_outlined,
                                  text: 'Majors: ${majors ?? majorIdsList!.join(", ")}',
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (educationId != null) ...[
                                _ContactItem(
                                  icon: Icons.menu_book_outlined,
                                  text: 'Education: ${education ?? "Education ID: $educationId"}',
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (experienceId != null) ...[
                                _ContactItem(
                                  icon: Icons.work_history_outlined,
                                  text: 'Experience: ${experience ?? "Experience ID: $experienceId"}',
                                ),
                                const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 32),
                            ],

                            // Skills Section
                            if (skillsList.isNotEmpty) ...[
                              const Text(
                                'Skills',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: skillsList.map((skill) {
                                  return Chip(
                                    label: Text(skill),
                                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                    labelStyle: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 32),
                            ],

                            // Description Section
                            if (description != null && description.toString().isNotEmpty) ...[
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                description.toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],

                            // CV/Resume Section
                            const Text(
                              'CV / Resume',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      cvPath != null ? Icons.description : Icons.upload_file,
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
                                          cvPath != null ? 'CV Uploaded' : 'No CV uploaded yet',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: cvPath != null
                                                ? AppTheme.textPrimary
                                                : AppTheme.textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'PDF, DOC, DOCX (Max 10MB)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (cvPath != null)
                                    IconButton(
                                      onPressed: () => _openCV(cvPath),
                                      icon: const Icon(
                                        Icons.visibility,
                                        color: AppTheme.primaryColor,
                                      ),
                                      tooltip: 'View CV',
                                    ),
                                  _isUploadingCV
                                      ? const SizedBox(
                                          width: 36,
                                          height: 36,
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                        )
                                      : IconButton(
                                          onPressed: _pickAndUploadCV,
                                          icon: Icon(
                                            cvPath != null ? Icons.edit : Icons.upload,
                                            color: AppTheme.primaryColor,
                                          ),
                                          tooltip: cvPath != null ? 'Change CV' : 'Upload CV',
                                        ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Availability & Public Profile Section
                            if (availability != null || publicSlug != null) ...[
                              const Text(
                                'Additional Info',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (availability != null)
                                _ContactItem(
                                  icon: Icons.access_time,
                                  text: 'Availability: $availability',
                                ),
                              if (availability != null && publicSlug != null)
                                const SizedBox(height: 8),
                              if (publicSlug != null)
                                _ContactItem(
                                  icon: Icons.link,
                                  text: 'shoghl.com/c/$publicSlug',
                                ),
                              const SizedBox(height: 32),
                            ],

                            // QR Code Section
                            const Center(
                              child: Text(
                                'Scan Here',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Container(
                                width: 200,
                                height: 200,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.bodySurfaceColor,
                                    width: 1,
                                  ),
                                ),
                                child: qrCodePath != null
                                    ? Image.network(
                                        ApiService.normalizeUrl(qrCodePath),
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            _buildPlaceholderQR(),
                                      )
                                    : _buildPlaceholderQR(),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderQR() {
    // Placeholder QR code - you can replace this with actual QR code generation
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bodySurfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.qr_code,
          size: 100,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  void _showEditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditDigitalResumeModal(
        userData: _userData,
        onUpdate: () {
          _loadData(); // Reload data after update
        },
      ),
    );
  }
  
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditDigitalResumeModal extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onUpdate;

  const _EditDigitalResumeModal({
    required this.userData,
    required this.onUpdate,
  });

  @override
  State<_EditDigitalResumeModal> createState() => _EditDigitalResumeModalState();
}

class _EditDigitalResumeModalState extends State<_EditDigitalResumeModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _summaryController = TextEditingController();
  final _addressController = TextEditingController();
  final _upworkUrlController = TextEditingController();
  final _professionTitleController = TextEditingController();
  final _skillInputController = TextEditingController();
  final _publicSlugController = TextEditingController();

  Country _country = CountryService().findByCode('KW')!;
  String? _nationality;
  String? _residenceCountry;
  List<String> _selectedMajors = [];
  List<String> _skills = [];
  String? _education;
  String? _experience;
  String? _availability;

  List<String> _nationalityOptions = [];
  List<String> _residenceCountryOptions = [];
  List<String> _majorOptions = [];
  List<String> _educationOptions = [];
  List<String> _experienceOptions = [];

  List<Map<String, dynamic>> _countriesData = [];
  List<Map<String, dynamic>> _majorsData = [];
  List<Map<String, dynamic>> _educationData = [];
  List<Map<String, dynamic>> _experienceData = [];

  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedImage;
  String? _profileImageUrl;
  String? _currentLocale;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLocale = Localizations.localeOf(context).languageCode;
    // Reload data if locale changed or first load
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      _initializeData();
    }
  }

  Future<void> _initializeData() async {
    await _loadDropdownData();
    _populateForm();
  }

  /// Get the current locale code from context
  String _getLocale() {
    return _currentLocale ?? Localizations.localeOf(context).languageCode;
  }

  Future<void> _loadDropdownData() async {
    try {
      final locale = _getLocale();

      // Pass locale to API to get localized names
      final countries = await LookupService.getCountries(locale: locale);
      final majors = await LookupService.getMajors(locale: locale);
      final educationLevels = await LookupService.getEducationLevels(locale: locale);
      final experienceYears = await LookupService.getExperienceYears(locale: locale);

      if (mounted) {
        setState(() {
          _countriesData = countries;
          _majorsData = majors;
          _educationData = educationLevels;
          _experienceData = experienceYears;

          // Names are already in the correct locale from API
          _nationalityOptions = LookupService.getLocalizedNames(countries, locale);
          _residenceCountryOptions = LookupService.getLocalizedNames(countries, locale);
          _majorOptions = LookupService.getLocalizedNames(majors, locale);
          _educationOptions = LookupService.getLocalizedNames(educationLevels, locale);
          _experienceOptions = LookupService.getLocalizedNames(experienceYears, locale);
        });

        // Now populate form after data is loaded
        _populateForm();
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _populateForm() {
    final user = widget.userData;
    final profile = user?['candidate_profile'] ?? {};

    _nameController.text = user?['name'] ?? '';
    _emailController.text = user?['email'] ?? '';
    _summaryController.text = profile['summary'] ?? '';
    _addressController.text = profile['address'] ?? '';
    _upworkUrlController.text = profile['upwork_profile_url'] ?? profile['website'] ?? '';
    _professionTitleController.text = profile['profession_title'] ?? 
                                      profile['job_title'] ?? 
                                      profile['title'] ?? 
                                      '';
    
    // Load skills
    if (profile.containsKey('skills') && profile['skills'] != null) {
      final skillsData = profile['skills'];
      if (skillsData is List) {
        _skills = skillsData.map((skill) => skill.toString()).toList();
      } else if (skillsData is String) {
        // If skills is stored as comma-separated string
        _skills = skillsData.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
    }

    if (profile.containsKey('date_of_birth') && profile['date_of_birth'] != null) {
      try {
        final dob = DateTime.parse(profile['date_of_birth'].toString());
        _dobController.text = DateFormat('yyyy/MM/dd').format(dob);
      } catch (e) {
        // Ignore
      }
    }

    if (profile.containsKey('mobile_number') && profile['mobile_number'] != null) {
      final phoneStr = profile['mobile_number'] as String;
      if (phoneStr.startsWith('+')) {
        // Try to extract country code (usually 1-3 digits)
        try {
          // Try 3 digits first
          if (phoneStr.length > 3) {
            final countryCode = phoneStr.substring(1, 4);
            final country = CountryService().findByPhoneCode(countryCode);
            if (country != null) {
              _country = country;
              _phoneController.text = phoneStr.substring(4);
            } else {
              // Try 2 digits
              final countryCode2 = phoneStr.substring(1, 3);
              final country2 = CountryService().findByPhoneCode(countryCode2);
              if (country2 != null) {
                _country = country2;
                _phoneController.text = phoneStr.substring(3);
              } else {
                // Try 1 digit
                final countryCode1 = phoneStr.substring(1, 2);
                final country1 = CountryService().findByPhoneCode(countryCode1);
                if (country1 != null) {
                  _country = country1;
                  _phoneController.text = phoneStr.substring(2);
                } else {
                  _phoneController.text = phoneStr.replaceFirst('+', '');
                }
              }
            }
          } else {
            _phoneController.text = phoneStr.replaceFirst('+', '');
          }
        } catch (e) {
          _phoneController.text = phoneStr.replaceFirst('+', '');
        }
      } else {
        _phoneController.text = phoneStr;
      }
    }

    if (profile.containsKey('profile_image_path') && profile['profile_image_path'] != null) {
      _profileImageUrl = profile['profile_image_path'] as String;
    }

    // Load availability
    if (profile.containsKey('availability') && profile['availability'] != null) {
      _availability = profile['availability'] as String;
    }

    // Load public slug
    if (profile.containsKey('public_slug') && profile['public_slug'] != null) {
      _publicSlugController.text = profile['public_slug'] as String;
    }

    // Map IDs to names for dropdowns - now that data is loaded
    _mapIdsToNames(profile);
  }

  void _mapIdsToNames(Map<String, dynamic> profile) {
    final locale = _getLocale();

    if (profile.containsKey('nationality_country_id') && profile['nationality_country_id'] != null) {
      final countryId = profile['nationality_country_id'] as int;
      _nationality = LookupService.getLocalizedNameById(_countriesData, countryId, locale);
    }

    if (profile.containsKey('resident_country_id') && profile['resident_country_id'] != null) {
      final countryId = profile['resident_country_id'] as int;
      _residenceCountry = LookupService.getLocalizedNameById(_countriesData, countryId, locale);
    }

    if (profile.containsKey('major_ids') && profile['major_ids'] != null) {
      final majorIds = profile['major_ids'] as List<dynamic>;
      if (majorIds.isNotEmpty) {
        _selectedMajors = majorIds
            .map((majorId) => LookupService.getLocalizedNameById(_majorsData, majorId as int?, locale))
            .where((name) => name != null && name.isNotEmpty)
            .cast<String>()
            .toList();
      }
    }

    if (profile.containsKey('education_id') && profile['education_id'] != null) {
      final educationId = profile['education_id'] as int;
      _education = LookupService.getLocalizedNameById(_educationData, educationId, locale);
    }

    if (profile.containsKey('years_of_experience_id') && profile['years_of_experience_id'] != null) {
      final experienceId = profile['years_of_experience_id'] as int;
      _experience = LookupService.getLocalizedNameById(_experienceData, experienceId, locale);
    }

    if (mounted) {
      setState(() {});
    }
  }


  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy/MM/dd').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Not authenticated');

      // Upload image if selected
      if (_selectedImage != null) {
        await ApiService.uploadFile(
          'mobile/candidate/profile/image',
          _selectedImage!,
          'image',
          token: token,
        );
      }

      // Map localized names back to IDs
      final locale = _getLocale();

      final nationalityId = _nationality != null
          ? LookupService.getIdByLocalizedName(_countriesData, _nationality!, locale)
          : null;

      final residenceId = _residenceCountry != null
          ? LookupService.getIdByLocalizedName(_countriesData, _residenceCountry!, locale)
          : null;

      final majorIds = _selectedMajors
          .map((name) => LookupService.getIdByLocalizedName(_majorsData, name, locale))
          .where((id) => id != null)
          .cast<int>()
          .toList();

      final educationId = _education != null
          ? LookupService.getIdByLocalizedName(_educationData, _education!, locale)
          : null;

      final experienceId = _experience != null
          ? LookupService.getIdByLocalizedName(_experienceData, _experience!, locale)
          : null;

      // Prepare update data
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'mobile_number': '+${_country.phoneCode}${_phoneController.text.trim()}',
        if (nationalityId != null) 'nationality_country_id': nationalityId,
        if (residenceId != null) 'resident_country_id': residenceId,
        if (majorIds.isNotEmpty) 'major_ids': majorIds,
        if (educationId != null) 'education_id': educationId,
        if (experienceId != null) 'years_of_experience_id': experienceId,
        if (_summaryController.text.trim().isNotEmpty) 'summary': _summaryController.text.trim(),
        if (_dobController.text.isNotEmpty) 'date_of_birth': _dobController.text,
        if (_addressController.text.trim().isNotEmpty) 'address': _addressController.text.trim(),
        if (_upworkUrlController.text.trim().isNotEmpty) 'upwork_profile_url': _upworkUrlController.text.trim(),
        if (_professionTitleController.text.trim().isNotEmpty) 'profession_title': _professionTitleController.text.trim(),
        'skills': _skills,
        if (_availability != null && _availability!.isNotEmpty) 'availability': _availability,
        if (_publicSlugController.text.trim().isNotEmpty) 'public_slug': _publicSlugController.text.trim(),
      };

      await ApiService.put(
        'mobile/candidate/profile',
        updateData,
        token: token,
      );

      // Refresh user data
      await AuthService.getCurrentUser();

      if (mounted) {
        Navigator.of(context).pop();
        widget.onUpdate();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _summaryController.dispose();
    _addressController.dispose();
    _upworkUrlController.dispose();
    _professionTitleController.dispose();
    _skillInputController.dispose();
    _publicSlugController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Digital Resume',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Image
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppTheme.bodySurfaceColor,
                                  backgroundImage: _selectedImage != null
                                      ? FileImage(_selectedImage!)
                                      : (_profileImageUrl != null
                                          ? NetworkImage(ApiService.normalizeUrl(_profileImageUrl!))
                                          : null) as ImageProvider?,
                                  child: _selectedImage == null && _profileImageUrl == null
                                      ? const Icon(Icons.person, size: 50)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: IconButton(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppTheme.white,
                                      shape: const CircleBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Name
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Profession Title
                          TextFormField(
                            controller: _professionTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Profession Title',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., UI UX Designer, Software Engineer',
                              prefixIcon: Icon(Icons.work_outline),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email (read-only)
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              enabled: false,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Phone
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    showCountryPicker(
                                      context: context,
                                      onSelect: (Country country) {
                                        setState(() {
                                          _country = country;
                                        });
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('+${_country.phoneCode}'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone Number',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter phone number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Date of Birth
                          TextFormField(
                            controller: _dobController,
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: _selectDate,
                          ),
                          const SizedBox(height: 16),

                          // Address
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),

                          // Upwork Profile URL
                          TextFormField(
                            controller: _upworkUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Upwork Profile URL',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.link_outlined),
                              hintText: 'e.g., uptowork.com/mycv/j.smith',
                            ),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),

                          // Nationality
                          _SearchableDropdown(
                            label: 'Nationality',
                            value: _nationality,
                            options: _nationalityOptions,
                            onChanged: (String? newValue) {
                              setState(() {
                                _nationality = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Residence Country
                          _SearchableDropdown(
                            label: 'Residence Country',
                            value: _residenceCountry,
                            options: _residenceCountryOptions,
                            onChanged: (String? newValue) {
                              setState(() {
                                _residenceCountry = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Majors (Multi-select)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Majors',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _majorOptions.map((major) {
                                    final isSelected = _selectedMajors.contains(major);
                                    return FilterChip(
                                      label: Text(
                                        major,
                                        style: TextStyle(
                                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: AppTheme.white,
                                      checkmarkColor: AppTheme.primaryColor,
                                      backgroundColor: AppTheme.bodySurfaceColor,
                                      side: BorderSide(
                                        color: isSelected ? AppTheme.primaryColor : Colors.grey,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedMajors.add(major);
                                          } else {
                                            _selectedMajors.remove(major);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Education
                          _SearchableDropdown(
                            label: 'Education Level',
                            value: _education,
                            options: _educationOptions,
                            onChanged: (String? newValue) {
                              setState(() {
                                _education = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Experience
                          _SearchableDropdown(
                            label: 'Years of Experience',
                            value: _experience,
                            options: _experienceOptions,
                            onChanged: (String? newValue) {
                              setState(() {
                                _experience = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Availability
                          _SearchableDropdown(
                            label: 'Availability',
                            value: _availability,
                            options: const [
                              'Immediately',
                              'Within 1 week',
                              'Within 2 weeks',
                              'Within 1 month',
                              'Not available',
                            ],
                            onChanged: (String? newValue) {
                              setState(() {
                                _availability = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Public Slug
                          TextFormField(
                            controller: _publicSlugController,
                            decoration: InputDecoration(
                              labelText: 'Public Profile URL',
                              hintText: 'your-unique-slug',
                              border: const OutlineInputBorder(),
                              helperText: 'shoghl.com/c/${_publicSlugController.text.isEmpty ? "your-slug" : _publicSlugController.text}',
                            ),
                            onChanged: (value) {
                              setState(() {}); // Update helper text
                            },
                          ),
                          const SizedBox(height: 16),

                          // Skills
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Skills',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Skill input field
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _skillInputController,
                                        decoration: InputDecoration(
                                          hintText: 'Enter a skill and press Enter',
                                          border: const OutlineInputBorder(),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                        ),
                                        onSubmitted: (value) {
                                          if (value.trim().isNotEmpty) {
                                            setState(() {
                                              if (!_skills.contains(value.trim())) {
                                                _skills.add(value.trim());
                                              }
                                              _skillInputController.clear();
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        if (_skillInputController.text.trim().isNotEmpty) {
                                          setState(() {
                                            if (!_skills.contains(_skillInputController.text.trim())) {
                                              _skills.add(_skillInputController.text.trim());
                                            }
                                            _skillInputController.clear();
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.add_circle_outline),
                                      color: AppTheme.primaryColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Skills tags
                                if (_skills.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _skills.map((skill) {
                                      return Chip(
                                        label: Text(skill),
                                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                        labelStyle: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        deleteIcon: const Icon(
                                          Icons.close,
                                          size: 18,
                                          color: AppTheme.primaryColor,
                                        ),
                                        onDeleted: () {
                                          setState(() {
                                            _skills.remove(skill);
                                          });
                                        },
                                      );
                                    }).toList(),
                                  )
                                else
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'No skills added yet',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Summary/Description
                          TextFormField(
                            controller: _summaryController,
                            decoration: const InputDecoration(
                              labelText: 'Summary/Description',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 5,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
          ),
          // Save Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
}

extension MapExtension on Map {
  T? tryGet<T>(dynamic key) {
    return containsKey(key) ? this[key] as T? : null;
  }
}

class _SearchableDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _SearchableDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  Future<void> _showSearchDialog(BuildContext context) async {
    final searchController = TextEditingController();
    List<String> filteredOptions = List.from(options);
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Select $label'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (query) {
                    setDialogState(() {
                      filteredOptions = options
                          .where((option) => option
                              .toLowerCase()
                              .contains(query.toLowerCase()))
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredOptions.length,
                    itemBuilder: (context, index) {
                      final option = filteredOptions[index];
                      final isSelected = value == option;
                      return ListTile(
                        title: Text(option),
                        selected: isSelected,
                        selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: AppTheme.primaryColor)
                            : null,
                        onTap: () {
                          onChanged(option);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            if (value != null)
              TextButton(
                onPressed: () {
                  onChanged(null);
                  Navigator.of(context).pop();
                },
                child: const Text('Clear'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSearchDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? 'Select $label',
                    style: TextStyle(
                      fontSize: 16,
                      color: value != null ? AppTheme.textPrimary : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
