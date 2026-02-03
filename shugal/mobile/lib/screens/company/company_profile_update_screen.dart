import 'dart:io';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/lookup_service.dart';
import '../../widgets/app_header.dart';

class CompanyProfileUpdateScreen extends StatefulWidget {
  const CompanyProfileUpdateScreen({super.key});

  @override
  State<CompanyProfileUpdateScreen> createState() => _CompanyProfileUpdateScreenState();
}

class _CompanyProfileUpdateScreenState extends State<CompanyProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _civilIdController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();

  Country _country = CountryService().findByCode('KW')!;
  String? _selectedCountry;
  List<String> _selectedMajors = [];

  // Dropdown data from API
  List<String> _countryOptions = [];
  List<String> _majorOptions = [];

  // Store full lookup data for ID mapping
  List<Map<String, dynamic>> _countriesData = [];
  List<Map<String, dynamic>> _majorsData = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  bool _isUploadingLicense = false;
  String? _errorMessage;

  // Logo and License
  File? _selectedLogo;
  String? _logoUrl;
  String? _licenseUrl;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
    _loadProfile();
  }

  Future<void> _loadDropdownData() async {
    try {
      // Load countries
      final countries = await LookupService.getCountries();
      final countryNames = countries.map((e) => e['name'] as String? ?? '').where((name) => name.isNotEmpty).toList();

      // Load majors
      final majors = await LookupService.getMajors();

      if (mounted) {
        setState(() {
          _countriesData = countries;
          _majorsData = majors;

          _countryOptions = countryNames;
          _majorOptions = majors.map((e) => e['name'] as String? ?? '').where((name) => name.isNotEmpty).toList();
        });
      }
    } catch (e) {
      // Use defaults if API fails
      if (mounted) {
        setState(() {
          _countryOptions = ['Kuwait', 'Saudi Arabia', 'UAE', 'Qatar', 'Bahrain', 'Oman'];
          _majorOptions = ['Computer Science', 'Business', 'Engineering', 'Medicine', 'Law', 'Education', 'Arts', 'Other'];
        });
      }
    }
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load dropdown data first
      await _loadDropdownData();

      final token = await AuthService.getToken();
      if (token != null) {
        try {
          final profileResponse = await ApiService.get(
            'mobile/company/profile',
            token: token,
          );
          // Backend returns user with company_profile relation
          if (profileResponse.containsKey('company_profile') && profileResponse['company_profile'] != null) {
            final profile = profileResponse['company_profile'] as Map<String, dynamic>;
            await _populateFormFromProfile(profile);
          }
        } catch (e) {
          // If profile endpoint fails, continue with empty form
          debugPrint('Failed to load company profile: $e');
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load profile: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _populateFormFromProfile(Map<String, dynamic> profile) async {
    _companyNameController.text = profile['company_name'] ?? '';
    _contactEmailController.text = profile['contact_email'] ?? '';
    _civilIdController.text = profile['civil_id'] ?? '';
    _websiteController.text = profile['website'] ?? '';
    _descriptionController.text = profile['description'] ?? '';

    // Parse contact phone
    final contactPhone = profile['contact_phone'] as String?;
    if (contactPhone != null && contactPhone.isNotEmpty) {
      _contactPhoneController.text = contactPhone;
    }

    // Parse mobile number with country code
    final mobileNumber = profile['mobile_number'] as String?;
    if (mobileNumber != null && mobileNumber.isNotEmpty) {
      _parseMobileNumber(mobileNumber);
    }

    // Map country ID to name
    if (profile.containsKey('country_id') && profile['country_id'] != null) {
      final countryId = profile['country_id'] as int;
      final countries = _countriesData.isNotEmpty ? _countriesData : await LookupService.getCountries();
      final country = countries.firstWhere(
        (c) => c['id'] == countryId,
        orElse: () => <String, dynamic>{},
      );
      if (country.isNotEmpty && country.containsKey('name')) {
        _selectedCountry = country['name'] as String;
      }
    }

    // Map major IDs to names (backend stores as 'majors' array)
    if (profile.containsKey('majors') && profile['majors'] != null) {
      final majorIds = profile['majors'] as List<dynamic>;
      if (majorIds.isNotEmpty) {
        final majors = _majorsData.isNotEmpty ? _majorsData : await LookupService.getMajors();
        _selectedMajors = majorIds
            .map((majorId) {
              final major = majors.firstWhere(
                (m) => m['id'] == majorId,
                orElse: () => <String, dynamic>{},
              );
              return major['name'] as String?;
            })
            .where((name) => name != null && name.isNotEmpty)
            .cast<String>()
            .toList();
      }
    }

    // Load logo URL
    if (profile.containsKey('logo_path') && profile['logo_path'] != null) {
      _logoUrl = ApiService.normalizeUrl(profile['logo_path'] as String);
    }

    // Load license URL
    if (profile.containsKey('license_path') && profile['license_path'] != null) {
      _licenseUrl = ApiService.normalizeUrl(profile['license_path'] as String);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _parseMobileNumber(String phone) {
    if (phone.startsWith('+')) {
      final withoutPlus = phone.substring(1);

      // Try codes from 1 to 4 digits (longest first)
      for (int len = 4; len >= 1; len--) {
        if (withoutPlus.length >= len) {
          final possibleCode = withoutPlus.substring(0, len);
          try {
            final country = CountryService().findByPhoneCode(possibleCode);
            if (country != null) {
              _country = country;
              _mobileNumberController.text = withoutPlus.substring(len).trim();
              return;
            }
          } catch (e) {
            // Continue trying
          }
        }
      }
      _mobileNumberController.text = withoutPlus;
    } else {
      _mobileNumberController.text = phone;
    }
  }

  Future<void> _pickAndUploadLogo() async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      final file = File(image.path);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected image file not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedLogo = file;
        _isUploadingLogo = true;
        _errorMessage = null;
      });

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await ApiService.uploadFile(
        'mobile/company/profile/logo',
        file,
        'logo',
        token: token,
      );

      if (response.containsKey('url')) {
        _logoUrl = ApiService.normalizeUrl(response['url'] as String);
      }

      if (!mounted) return;

      setState(() {
        _isUploadingLogo = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logo updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingLogo = false;
          _errorMessage = e.message;
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
          _isUploadingLogo = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
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

  Future<void> _pickAndUploadLicense() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
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
        _isUploadingLicense = true;
        _errorMessage = null;
      });

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await ApiService.uploadFile(
        'mobile/company/profile/license',
        file,
        'license',
        token: token,
      );

      if (response.containsKey('url')) {
        _licenseUrl = ApiService.normalizeUrl(response['url'] as String);
      }

      if (!mounted) return;

      setState(() {
        _isUploadingLicense = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('License uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingLicense = false;
          _errorMessage = e.message;
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
          _isUploadingLicense = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
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

  Future<void> _openLicense() async {
    if (_licenseUrl == null || _licenseUrl!.isEmpty) return;

    final uri = Uri.parse(_licenseUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open license file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final payload = <String, dynamic>{
        'company_name': _companyNameController.text.trim(),
        'contact_email': _contactEmailController.text.trim(),
        'contact_phone': _contactPhoneController.text.trim(),
        'civil_id': _civilIdController.text.trim(),
        'website': _websiteController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      // Add mobile number with country code
      final mobileNumber = _mobileNumberController.text.trim();
      if (mobileNumber.isNotEmpty) {
        payload['mobile_number'] = '+${_country.phoneCode}$mobileNumber';
      }

      // Convert country name to ID
      if (_selectedCountry != null && _selectedCountry!.isNotEmpty) {
        final country = _countriesData.firstWhere(
          (c) => c['name'] == _selectedCountry,
          orElse: () => <String, dynamic>{},
        );
        if (country.isNotEmpty && country.containsKey('id')) {
          payload['country_id'] = country['id'];
        }
      }

      // Convert major names to IDs (backend expects 'majors' field)
      if (_selectedMajors.isNotEmpty) {
        final majorIds = _selectedMajors
            .map((majorName) {
              final major = _majorsData.firstWhere(
                (m) => m['name'] == majorName,
                orElse: () => <String, dynamic>{},
              );
              return major['id'] as int?;
            })
            .where((id) => id != null)
            .cast<int>()
            .toList();

        if (majorIds.isNotEmpty) {
          payload['majors'] = majorIds;
        }
      }

      // Debug: Print payload before sending
      debugPrint('Company profile update payload: $payload');

      await ApiService.put(
        'mobile/company/profile',
        payload,
        token: token,
      );

      // Refresh user data
      await AuthService.getCurrentUser();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _mobileNumberController.dispose();
    _civilIdController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const AppHeader(showLanguageWithActions: true),

            // Content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(56),
                    topRight: Radius.circular(56),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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

                              // Back button and title
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    icon: const Icon(Icons.arrow_back),
                                    color: AppTheme.textPrimary,
                                  ),
                                  const Text(
                                    'Company Profile',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Company Logo
                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.grey.shade300,
                                        backgroundImage: _selectedLogo != null
                                            ? FileImage(_selectedLogo!)
                                            : (_logoUrl != null && _logoUrl!.isNotEmpty
                                                ? NetworkImage(_logoUrl!)
                                                : null),
                                        child: _selectedLogo == null &&
                                                (_logoUrl == null || _logoUrl!.isEmpty)
                                            ? const Icon(
                                                Icons.business,
                                                size: 50,
                                                color: Colors.grey,
                                              )
                                            : null,
                                      ),
                                      if (_isUploadingLogo)
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isUploadingLogo ? null : _pickAndUploadLogo,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.textPrimary,
                                        side: BorderSide(color: Colors.grey.shade400),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text(
                                        'Change Logo',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Error message
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.errorColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: AppTheme.errorColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: AppTheme.errorColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Company Name
                              const _Label('Company Name'),
                              const SizedBox(height: 8),
                              _AuthInputField(
                                controller: _companyNameController,
                                hintText: 'Enter Company Name',
                                keyboardType: TextInputType.name,
                              ),
                              const SizedBox(height: 14),

                              // Country
                              const _Label('Country'),
                              const SizedBox(height: 8),
                              _DropdownField(
                                value: _selectedCountry,
                                hintText: 'Choose',
                                items: _countryOptions.isEmpty
                                    ? ['Loading...']
                                    : _countryOptions,
                                onChanged: _countryOptions.isEmpty
                                    ? null
                                    : (v) => setState(() => _selectedCountry = v),
                              ),
                              const SizedBox(height: 14),

                              // Contact Email
                              const _Label('Contact Email'),
                              const SizedBox(height: 8),
                              _AuthInputField(
                                controller: _contactEmailController,
                                hintText: 'Enter Contact Email',
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),

                              // Contact Phone
                              const _Label('Contact Phone'),
                              const SizedBox(height: 8),
                              _AuthInputField(
                                controller: _contactPhoneController,
                                hintText: 'Enter Contact Phone',
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 14),

                              // Mobile Number
                              const _Label('Mobile Number'),
                              const SizedBox(height: 8),
                              _PhoneField(
                                controller: _mobileNumberController,
                                country: _country,
                                onPickCountry: () {
                                  showCountryPicker(
                                    context: context,
                                    showPhoneCode: true,
                                    favorite: const ['KW', 'SA', 'AE', 'QA', 'BH', 'OM'],
                                    onSelect: (c) => setState(() => _country = c),
                                  );
                                },
                              ),
                              const SizedBox(height: 14),

                              // Civil ID
                              const _Label('Civil ID'),
                              const SizedBox(height: 8),
                              _AuthInputField(
                                controller: _civilIdController,
                                hintText: 'Enter Civil ID',
                                keyboardType: TextInputType.text,
                              ),
                              const SizedBox(height: 14),

                              // Majors (Multi-select)
                              const _Label('Majors/Industries'),
                              const SizedBox(height: 8),
                              _MultiSelectMajorField(
                                selectedMajors: _selectedMajors,
                                items: _majorOptions.isEmpty
                                    ? ['Loading...']
                                    : _majorOptions,
                                onChanged: _majorOptions.isEmpty
                                    ? null
                                    : (selected) => setState(() => _selectedMajors = selected),
                              ),
                              const SizedBox(height: 14),

                              // Website
                              const _Label('Website'),
                              const SizedBox(height: 8),
                              _AuthInputField(
                                controller: _websiteController,
                                hintText: 'https://example.com',
                                keyboardType: TextInputType.url,
                              ),
                              const SizedBox(height: 14),

                              // Description
                              const _Label('Description'),
                              const SizedBox(height: 8),
                              _AuthInputField(
                                controller: _descriptionController,
                                hintText: 'Enter company description',
                                keyboardType: TextInputType.multiline,
                                maxLines: 4,
                              ),
                              const SizedBox(height: 14),

                              // License Upload
                              const _Label('Business License'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.borderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_licenseUrl != null && _licenseUrl!.isNotEmpty) ...[
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.description,
                                            color: AppTheme.primaryColor,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'License uploaded',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _openLicense,
                                            child: const Text('View'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _isUploadingLicense ? null : _pickAndUploadLicense,
                                        icon: _isUploadingLicense
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Icon(Icons.upload_file),
                                        label: Text(_licenseUrl != null ? 'Replace License' : 'Upload License'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.textPrimary,
                                          side: BorderSide(color: Colors.grey.shade400),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Save Button
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _handleUpdateProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: AppTheme.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              AppTheme.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Save Profile',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
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

// Reusable components
class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _AuthInputField extends StatelessWidget {
  const _AuthInputField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.readOnly = false,
    this.suffix,
    this.onTap,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool readOnly;
  final Widget? suffix;
  final VoidCallback? onTap;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppTheme.white,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.country,
    required this.onPickCountry,
  });
  final TextEditingController controller;
  final Country country;
  final VoidCallback onPickCountry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        color: AppTheme.white,
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          InkWell(
            onTap: onPickCountry,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.bodySurfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    country.flagEmoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+${country.phoneCode}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '123 4567 84321',
                hintStyle: TextStyle(color: AppTheme.textMuted),
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _MultiSelectMajorField extends StatelessWidget {
  const _MultiSelectMajorField({
    required this.selectedMajors,
    required this.items,
    this.onChanged,
  });

  final List<String> selectedMajors;
  final List<String> items;
  final ValueChanged<List<String>>? onChanged;

  Future<void> _showMultiSelectDialog(BuildContext context) async {
    final validItems = items.where((item) => item != 'Loading...').toList();
    if (onChanged == null || validItems.isEmpty) return;

    final searchController = TextEditingController();
    List<String> filteredItems = List<String>.from(validItems);
    List<String> tempSelected = List<String>.from(selectedMajors);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 500),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (query) {
                        setDialogState(() {
                          if (query.isEmpty) {
                            filteredItems = List<String>.from(validItems);
                          } else {
                            filteredItems = validItems
                                .where((item) => item
                                    .toLowerCase()
                                    .contains(query.toLowerCase()))
                                .toList();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isSelected = tempSelected.contains(item);
                          return CheckboxListTile(
                            title: Text(item),
                            value: isSelected,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  if (!tempSelected.contains(item)) {
                                    tempSelected.add(item);
                                  }
                                } else {
                                  tempSelected.remove(item);
                                }
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            onChanged?.call(tempSelected);
                            Navigator.of(dialogContext).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppTheme.white,
                          ),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final validItems = items.where((item) => item != 'Loading...').toList();
    final displayText = selectedMajors.isEmpty
        ? 'Choose'
        : selectedMajors.length == 1
            ? selectedMajors.first
            : '${selectedMajors.length} selected';

    return InkWell(
      onTap: validItems.isEmpty || onChanged == null
          ? null
          : () => _showMultiSelectDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 14,
                  color: selectedMajors.isEmpty
                      ? AppTheme.textMuted
                      : AppTheme.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    this.onChanged,
    required this.hintText,
  });

  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final String hintText;

  Future<void> _showSearchableDialog(BuildContext context) async {
    final validItems = items.where((item) => item != 'Loading...').toList();
    if (onChanged == null || validItems.isEmpty) return;

    final searchController = TextEditingController();
    List<String> filteredItems = List<String>.from(validItems);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 500),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (query) {
                        setDialogState(() {
                          if (query.isEmpty) {
                            filteredItems = List<String>.from(validItems);
                          } else {
                            filteredItems = validItems
                                .where((item) => item
                                    .toLowerCase()
                                    .contains(query.toLowerCase()))
                                .toList();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filteredItems.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'No items found',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final isSelected = item == value;
                                return InkWell(
                                  onTap: () {
                                    onChanged?.call(item);
                                    Navigator.of(context).pop();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryColor.withOpacity(0.1)
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isSelected
                                                  ? AppTheme.primaryColor
                                                  : AppTheme.textPrimary,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check,
                                            color: AppTheme.primaryColor,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final validItems = items.where((item) => item != 'Loading...').toList();
    return InkWell(
      onTap: onChanged != null && validItems.isNotEmpty
          ? () => _showSearchableDialog(context)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hintText,
                style: TextStyle(
                  color: value != null
                      ? AppTheme.textPrimary
                      : AppTheme.textMuted,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
