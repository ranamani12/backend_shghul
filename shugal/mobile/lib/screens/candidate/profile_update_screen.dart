import 'dart:io';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/lookup_service.dart';
import '../../constants/app_constants.dart';
import '../../widgets/app_header.dart';
import 'package:shghul/services/localization_service.dart';

class ProfileUpdateScreen extends StatefulWidget {
  const ProfileUpdateScreen({super.key});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  Country _country = CountryService().findByCode('KW')!;
  String? _nationality;
  String? _residenceCountry;
  List<String> _selectedMajors = []; // Changed to list for multiple selection
  String? _education;
  String? _experience;

  // Dropdown data from API
  List<String> _nationalityOptions = [];
  List<String> _residenceCountryOptions = [];
  List<String> _majorOptions = [];
  List<String> _educationOptions = [];
  List<String> _experienceOptions = [];
  
  // Store full lookup data for ID mapping
  List<Map<String, dynamic>> _countriesData = [];
  List<Map<String, dynamic>> _majorsData = [];
  List<Map<String, dynamic>> _educationData = [];
  List<Map<String, dynamic>> _experienceData = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  String? _errorMessage;

  // Profile image
  File? _selectedImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
    _loadProfile();
  }

  Future<void> _loadDropdownData() async {
    try {
      // Load countries for nationality and residence
      final countries = await LookupService.getCountries();
      final countryNames = countries.map((e) => e['name'] as String? ?? '').where((name) => name.isNotEmpty).toList();
      
      // Load lookup data
      final majors = await LookupService.getMajors();
      final educationLevels = await LookupService.getEducationLevels();
      final experienceYears = await LookupService.getExperienceYears();

      if (mounted) {
        setState(() {
          _countriesData = countries;
          _majorsData = majors;
          _educationData = educationLevels;
          _experienceData = experienceYears;
          
          _nationalityOptions = countryNames;
          _residenceCountryOptions = countryNames;
          _majorOptions = majors.map((e) => e['name'] as String? ?? '').where((name) => name.isNotEmpty).toList();
          _educationOptions = educationLevels.map((e) => e['name'] as String? ?? '').where((name) => name.isNotEmpty).toList();
          _experienceOptions = experienceYears.map((e) => e['name'] as String? ?? '').where((name) => name.isNotEmpty).toList();
        });
      }
    } catch (e) {
      // Use defaults if API fails
      if (mounted) {
        setState(() {
          _nationalityOptions = ['Kuwait', 'Saudi Arabia', 'UAE', 'Qatar', 'Bahrain', 'Oman'];
          _residenceCountryOptions = ['Kuwait', 'Saudi Arabia', 'UAE', 'Qatar', 'Bahrain', 'Oman'];
          _majorOptions = ['Computer Science', 'Business', 'Engineering', 'Medicine', 'Law', 'Education', 'Arts', 'Other'];
          _educationOptions = ['High School', 'Bachelor', 'Master', 'PhD'];
          _experienceOptions = ['0-1 Years', '1-5 Years', '5-10 Years', '10+ Years'];
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

      // Try to get user from auth service first
      final user = await AuthService.getUser();
      
      if (user != null) {
        await _populateForm(user);
        
        // Also fetch full profile from API if needed (will re-populate with IDs mapped to names)
        final token = await AuthService.getToken();
        if (token != null) {
          try {
            final profileResponse = await ApiService.get(
              'mobile/candidate/profile',
              token: token,
            );
            if (profileResponse.containsKey('profile')) {
              final profile = profileResponse['profile'] as Map<String, dynamic>;
              await _populateFormFromProfile(profile);
            }
          } catch (e) {
            // If profile endpoint fails, continue with user data
          }
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

  Future<void> _populateForm(Map<String, dynamic> user) async {
    _nameController.text = user['name'] ?? '';
    _emailController.text = user['email'] ?? '';
    
    // Parse phone number from candidate_profile
    if (user.containsKey('candidate_profile')) {
      final candidateProfile = user['candidate_profile'] as Map<String, dynamic>?;
      if (candidateProfile != null) {
        final phone = candidateProfile['mobile_number'] as String?;
        if (phone != null && phone.isNotEmpty) {
          // Try to extract country code and number
          final phoneStr = phone.toString();
          if (phoneStr.startsWith('+')) {
            // Extract country code and number
            // Format can be: +1234567890 or +1 234567890 or +1 234 567 890
            // Remove the + and try to find country code
            final withoutPlus = phoneStr.substring(1);
            
            // Try to find country by matching phone code (try longest codes first)
            Country? foundCountry;
            String? phoneNumber;
            
            // Try codes from 1 to 4 digits (longest first)
            for (int len = 4; len >= 1; len--) {
              if (withoutPlus.length >= len) {
                final possibleCode = withoutPlus.substring(0, len);
                try {
                  final country = CountryService().findByPhoneCode(possibleCode);
                  if (country != null) {
                    foundCountry = country;
                    phoneNumber = withoutPlus.substring(len).trim();
                    break;
                  }
                } catch (e) {
                  // Continue trying
                }
              }
            }
            
            if (foundCountry != null && phoneNumber != null) {
              _country = foundCountry;
              _phoneController.text = phoneNumber;
            } else {
              // Fallback: try splitting by space
              final parts = phoneStr.split(' ');
              if (parts.length > 1) {
                final countryCode = parts[0].replaceAll('+', '');
                final number = parts.sublist(1).join(' ');
                _phoneController.text = number;
                
                try {
                  final country = CountryService().findByPhoneCode(countryCode);
                  if (country != null) {
                    _country = country;
                  }
                } catch (e) {
                  // Keep default country
                }
              } else {
                // If no space, try to extract manually
                _phoneController.text = phoneStr.replaceFirst('+', '');
              }
            }
          } else {
            _phoneController.text = phoneStr;
          }
        }
        
        // Populate profile data (async function)
        await _populateFormFromProfile(candidateProfile);
      }
    }
  }

  Future<void> _populateFormFromProfile(Map<String, dynamic> profile) async {
    // Load lookup data first to map IDs to names
    await _loadDropdownData();
    
    if (profile.containsKey('date_of_birth') && profile['date_of_birth'] != null) {
      try {
        final dob = DateTime.parse(profile['date_of_birth'].toString());
        _dobController.text = DateFormat('yyyy/MM/dd').format(dob);
      } catch (e) {
        // Ignore date parsing errors
      }
    }
    
      // Map country IDs to names (use already loaded data if available)
      if (profile.containsKey('nationality_country_id') && profile['nationality_country_id'] != null) {
        final countryId = profile['nationality_country_id'] as int;
        final countries = _countriesData.isNotEmpty ? _countriesData : await LookupService.getCountries();
        final country = countries.firstWhere(
          (c) => c['id'] == countryId,
          orElse: () => <String, dynamic>{},
        );
        if (country.isNotEmpty && country.containsKey('name')) {
          _nationality = country['name'] as String;
        }
      }
      
      if (profile.containsKey('resident_country_id') && profile['resident_country_id'] != null) {
        final countryId = profile['resident_country_id'] as int;
        final countries = _countriesData.isNotEmpty ? _countriesData : await LookupService.getCountries();
        final country = countries.firstWhere(
          (c) => c['id'] == countryId,
          orElse: () => <String, dynamic>{},
        );
        if (country.isNotEmpty && country.containsKey('name')) {
          _residenceCountry = country['name'] as String;
        }
      }
      
      // Map major IDs to names (can be array)
      if (profile.containsKey('major_ids') && profile['major_ids'] != null) {
        final majorIds = profile['major_ids'] as List<dynamic>;
        if (majorIds.isNotEmpty) {
          final majors = _majorsData.isNotEmpty ? _majorsData : await LookupService.getMajors();
          // Map all major IDs to names
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
      
      // Map education ID to name
      if (profile.containsKey('education_id') && profile['education_id'] != null) {
        final educationId = profile['education_id'] as int;
        final educationLevels = _educationData.isNotEmpty ? _educationData : await LookupService.getEducationLevels();
        final education = educationLevels.firstWhere(
          (e) => e['id'] == educationId,
          orElse: () => <String, dynamic>{},
        );
        if (education.isNotEmpty && education.containsKey('name')) {
          _education = education['name'] as String;
        }
      }
      
    // Map experience ID to name
    if (profile.containsKey('years_of_experience_id') && profile['years_of_experience_id'] != null) {
      final experienceId = profile['years_of_experience_id'] as int;
      final experienceYears = _experienceData.isNotEmpty ? _experienceData : await LookupService.getExperienceYears();
      final experience = experienceYears.firstWhere(
        (e) => e['id'] == experienceId,
        orElse: () => <String, dynamic>{},
      );
      if (experience.isNotEmpty && experience.containsKey('name')) {
        _experience = experience['name'] as String;
      }
    }
    
    // Load profile image URL
    if (profile.containsKey('profile_image_path') && profile['profile_image_path'] != null) {
      _profileImageUrl = _normalizeImageUrl(profile['profile_image_path'] as String);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Request permission and pick image
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      ).catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error picking image: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      });

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
        _selectedImage = file;
        _isUploadingImage = true;
        _errorMessage = null;
      });

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await ApiService.uploadFile(
        'mobile/candidate/profile/image',
        file,
        'image',
        token: token,
      );

      if (response.containsKey('url')) {
        _profileImageUrl = _normalizeImageUrl(response['url'] as String);
        
        // Refresh user data to get updated profile
        await AuthService.getCurrentUser();
      }

      if (!mounted) return;

      setState(() {
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
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
          _isUploadingImage = false;
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

  String _normalizeImageUrl(String url) {
    return ApiService.normalizeUrl(url);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dobController.text.isNotEmpty
          ? DateFormat('yyyy/MM/dd').tryParse(_dobController.text) ?? DateTime.now()
          : DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy/MM/dd').format(picked);
      });
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

      // Build update payload - need to convert names back to IDs
      final phoneNumber = _phoneController.text.trim();
      if (phoneNumber.isEmpty) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Please enter your phone number';
        });
        return;
      }

      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile_number': '+${_country.phoneCode}$phoneNumber', // No space between code and number
      };

      if (_dobController.text.isNotEmpty) {
        try {
          // Parse DOB from yyyy/MM/dd format
          final dob = DateFormat('yyyy/MM/dd').parse(_dobController.text);
          // Convert to yyyy-MM-dd format for API
          payload['date_of_birth'] = DateFormat('yyyy-MM-dd').format(dob);
        } catch (e) {
          // If parsing fails, try alternative format
          try {
            final dob = DateTime.parse(_dobController.text);
            payload['date_of_birth'] = DateFormat('yyyy-MM-dd').format(dob);
          } catch (e2) {
            // Log error but don't fail the request
            debugPrint('Failed to parse DOB: ${_dobController.text}');
          }
        }
      }

      // Convert names back to IDs for submission
      if (_nationality != null && _nationality!.isNotEmpty) {
        final country = _countriesData.firstWhere(
          (c) => c['name'] == _nationality,
          orElse: () => <String, dynamic>{},
        );
        if (country.isNotEmpty && country.containsKey('id')) {
          payload['nationality_country_id'] = country['id'];
        }
      }
      
      if (_residenceCountry != null && _residenceCountry!.isNotEmpty) {
        final country = _countriesData.firstWhere(
          (c) => c['name'] == _residenceCountry,
          orElse: () => <String, dynamic>{},
        );
        if (country.isNotEmpty && country.containsKey('id')) {
          payload['resident_country_id'] = country['id'];
        }
      }
      
      if (_selectedMajors.isNotEmpty) {
        // Convert major names to IDs
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
          payload['major_ids'] = majorIds;
        }
      }
      
      if (_education != null && _education!.isNotEmpty) {
        final education = _educationData.firstWhere(
          (e) => e['name'] == _education,
          orElse: () => <String, dynamic>{},
        );
        if (education.isNotEmpty && education.containsKey('id')) {
          payload['education_id'] = education['id'];
        }
      }
      
      if (_experience != null && _experience!.isNotEmpty) {
        final experience = _experienceData.firstWhere(
          (e) => e['name'] == _experience,
          orElse: () => <String, dynamic>{},
        );
        if (experience.isNotEmpty && experience.containsKey('id')) {
          payload['years_of_experience_id'] = experience['id'];
        }
      }

      await ApiService.put(
        'mobile/candidate/profile',
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
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
                                    'Profile',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Profile image
                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.grey.shade300,
                                        backgroundImage: _selectedImage != null
                                            ? FileImage(_selectedImage!)
                                            : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                                ? NetworkImage(_profileImageUrl!)
                                                : null),
                                        child: _selectedImage == null &&
                                                (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                                            ? const Icon(
                                                Icons.person,
                                                size: 50,
                                                color: Colors.grey,
                                              )
                                            : null,
                                      ),
                                      if (_isUploadingImage)
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
                                      onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.textPrimary,
                                        side: BorderSide(color: Colors.grey.shade400),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text(
                                        'Change Profile',
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

                              // Name
                              const _Label('Name'),
                              const SizedBox(height: 8),
                              _AuthInputField(
                                controller: _nameController,
                                hintText: 'Enter Your Name',
                                keyboardType: TextInputType.name,
                              ),
                              const SizedBox(height: 14),

                              // Email
                              const _Label('Email'),
                              const SizedBox(height: 8),
                              _AuthInputField(
                                controller: _emailController,
                                hintText: 'Enter Email Address',
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),

                              // Phone Number
                              const _Label('Phone Number'),
                              const SizedBox(height: 8),
                              _PhoneField(
                                controller: _phoneController,
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

                              // Date of Birth
                              const _Label('Date of Birth'),
                              const SizedBox(height: 8),
                              _AuthInputField(
                                controller: _dobController,
                                hintText: 'YYYY/MM/DD',
                                readOnly: true,
                                suffix: const Icon(
                                  Icons.calendar_today,
                                  color: AppTheme.textMuted,
                                  size: 20,
                                ),
                                onTap: _selectDate,
                              ),
                              const SizedBox(height: 14),

                              // Nationality
                              const _Label('Nationality'),
                              const SizedBox(height: 8),
                              _DropdownField(
                                value: _nationality,
                                hintText: 'Choose',
                                items: _nationalityOptions.isEmpty 
                                    ? ['Loading...'] 
                                    : _nationalityOptions,
                                onChanged: _nationalityOptions.isEmpty 
                                    ? null 
                                    : (v) => setState(() => _nationality = v),
                              ),
                              const SizedBox(height: 14),

                              // Residents Country
                              const _Label('Residents Country'),
                              const SizedBox(height: 8),
                              _DropdownField(
                                value: _residenceCountry,
                                hintText: 'Choose',
                                items: _residenceCountryOptions.isEmpty 
                                    ? ['Loading...'] 
                                    : _residenceCountryOptions,
                                onChanged: _residenceCountryOptions.isEmpty 
                                    ? null 
                                    : (v) => setState(() => _residenceCountry = v),
                              ),
                              const SizedBox(height: 14),

                              // Major (Multi-select)
                              const _Label('Major'),
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

                              // Educational Level
                              const _Label('Educational Level'),
                              const SizedBox(height: 8),
                              _DropdownField(
                                value: _education,
                                hintText: 'Choose',
                                items: _educationOptions.isEmpty 
                                    ? ['Loading...'] 
                                    : _educationOptions,
                                onChanged: _educationOptions.isEmpty 
                                    ? null 
                                    : (v) => setState(() => _education = v),
                              ),
                              const SizedBox(height: 14),

                              // Years of Experience
                              const _Label('Years of Experiences'),
                              const SizedBox(height: 8),
                              _DropdownField(
                                value: _experience,
                                hintText: '1-5 Years',
                                items: _experienceOptions.isEmpty
                                    ? ['Loading...']
                                    : _experienceOptions,
                                onChanged: _experienceOptions.isEmpty
                                    ? null
                                    : (v) => setState(() => _experience = v),
                              ),
                              const SizedBox(height: 24),

                              // Edit Profile Button
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
                                          'Edit Profile',
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

// Reusable components (same as register screen)
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
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool readOnly;
  final Widget? suffix;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
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
    // Filter out 'Loading...' from items
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
                    // Search field
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
                    // List of items with checkboxes
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
                    // Buttons
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
            Icon(
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
    // Filter out 'Loading...' from items
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
                    // Search field
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
                    // List of items
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
    // Filter out 'Loading...' to check if we have valid items
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
