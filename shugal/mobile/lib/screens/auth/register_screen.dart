import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shghul/services/localization_service.dart';
import 'package:shghul/services/lookup_service.dart';
import 'package:shghul/services/auth_service.dart';
import 'package:shghul/services/api_service.dart';
import 'package:shghul/constants/app_constants.dart';
import 'package:shghul/theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../l10n/app_localizations.dart';

import 'login_screen.dart';
import 'otp_verification_screen.dart';
import '../candidate/candidate_main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialRole = LoginRole.company});

  final LoginRole initialRole;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late LoginRole _role = widget.initialRole;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  Country _country = CountryService().findByCode('KW')!;

  // Company fields
  final _companyNameController = TextEditingController();

  // Job seeker fields
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  String? _nationality;
  String? _residenceCountry;
  List<String> _selectedMajors = []; // Changed to list for multiple selection
  String? _education;
  String? _experience;
  
  // Registration state
  bool _isRegistering = false;
  String? _registerError;

  // Dropdown data from API
  List<String> _nationalityOptions = [];
  List<String> _residenceCountryOptions = [];
  List<String> _majorOptions = [];
  List<Map<String, dynamic>> _majorsData = []; // Store full major data for ID mapping
  List<Map<String, dynamic>> _countriesData = []; // Store full country data for ID mapping
  List<Map<String, dynamic>> _educationData = []; // Store full education data for ID mapping
  List<Map<String, dynamic>> _experienceData = []; // Store full experience data for ID mapping
  List<String> _educationOptions = [];
  List<String> _experienceOptions = [];
  bool _isLoadingDropdowns = false;
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
      _loadDropdownData();
    }
  }

  /// Get the current locale code from context
  String _getLocale() {
    return _currentLocale ?? Localizations.localeOf(context).languageCode;
  }

  Future<void> _loadDropdownData() async {
    setState(() {
      _isLoadingDropdowns = true;
    });

    try {
      final locale = _getLocale();

      // Load countries for nationality and residence with locale
      final countries = await LookupService.getCountries(locale: locale);
      _countriesData = countries; // Store full data for ID mapping
      final countryNames = LookupService.getLocalizedNames(countries, locale);

      // Load lookup data with locale (these require auth, but will be available after login)
      final majors = await LookupService.getMajors(locale: locale);
      final educationLevels = await LookupService.getEducationLevels(locale: locale);
      final experienceYears = await LookupService.getExperienceYears(locale: locale);

      if (mounted) {
        setState(() {
          _nationalityOptions = countryNames.isNotEmpty
              ? countryNames
              : ['Kuwait', 'Saudi Arabia', 'UAE', 'Qatar', 'Bahrain', 'Oman'];
          _residenceCountryOptions = countryNames.isNotEmpty
              ? countryNames
              : ['Kuwait', 'Saudi Arabia', 'UAE', 'Qatar', 'Bahrain', 'Oman'];

          _majorsData = majors; // Store full data for ID mapping
          final majorNames = LookupService.getLocalizedNames(majors, locale);
          _majorOptions = majorNames.isNotEmpty
              ? majorNames
              : ['Computer Science', 'Business', 'Engineering', 'Medicine', 'Law', 'Education', 'Arts', 'Other'];

          _educationData = educationLevels; // Store full data for ID mapping
          final educationNames = LookupService.getLocalizedNames(educationLevels, locale);
          _educationOptions = educationNames.isNotEmpty
              ? educationNames
              : ['High School', 'Bachelor', 'Master', 'PhD'];

          _experienceData = experienceYears; // Store full data for ID mapping
          final experienceNames = LookupService.getLocalizedNames(experienceYears, locale);
          _experienceOptions = experienceNames.isNotEmpty
              ? experienceNames
              : ['0-1 Years', '1-5 Years', '5-10 Years', '10+ Years'];

          _isLoadingDropdowns = false;
        });
      }
    } catch (e) {
      // If lookup API fails (no auth), use defaults
      if (mounted) {
        setState(() {
          _countriesData = []; // Empty if API fails
          _nationalityOptions = ['Kuwait', 'Saudi Arabia', 'UAE', 'Qatar', 'Bahrain', 'Oman'];
          _residenceCountryOptions = ['Kuwait', 'Saudi Arabia', 'UAE', 'Qatar', 'Bahrain', 'Oman'];
          _majorsData = []; // Empty if API fails
          _majorOptions = ['Computer Science', 'Business', 'Engineering', 'Medicine', 'Law', 'Education', 'Arts', 'Other'];
          _educationData = []; // Empty if API fails
          _educationOptions = ['High School', 'Bachelor', 'Master', 'PhD'];
          _experienceData = []; // Empty if API fails
          _experienceOptions = ['0-1 Years', '1-5 Years', '5-10 Years', '10+ Years'];
          _isLoadingDropdowns = false;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    final isCompany = _role == LoginRole.company;
    
    final l10n = AppLocalizations.of(context)!;

    // Basic validation
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _registerError = l10n.pleaseEnterEmail;
      });
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _registerError = l10n.pleaseEnterPhone;
      });
      return;
    }

    if (isCompany && _companyNameController.text.trim().isEmpty) {
      setState(() {
        _registerError = l10n.pleaseEnterCompanyName;
      });
      return;
    }

    if (!isCompany && _nameController.text.trim().isEmpty) {
      setState(() {
        _registerError = l10n.pleaseEnterName;
      });
      return;
    }

    setState(() {
      _isRegistering = true;
      _registerError = null;
    });

    try {
      // Format DOB if provided
      String? dateOfBirth;
      if (_dobController.text.isNotEmpty) {
        dateOfBirth = _dobController.text;
      }

      // Convert selected values to IDs for candidate profile
      int? nationalityCountryId;
      int? residentCountryId;
      List<int>? majorIds;
      int? educationId;
      int? yearsOfExperienceId;
      String? mobileNumber;

      if (!isCompany) {
        final locale = _getLocale();

        // Convert nationality country name to ID
        if (_nationality != null && _nationality!.isNotEmpty && _countriesData.isNotEmpty) {
          nationalityCountryId = LookupService.getIdByLocalizedName(_countriesData, _nationality!, locale);
        }

        // Convert residence country name to ID
        if (_residenceCountry != null && _residenceCountry!.isNotEmpty && _countriesData.isNotEmpty) {
          residentCountryId = LookupService.getIdByLocalizedName(_countriesData, _residenceCountry!, locale);
        }

        // Convert major names to IDs
        if (_selectedMajors.isNotEmpty && _majorsData.isNotEmpty) {
          majorIds = _selectedMajors
              .map((majorName) => LookupService.getIdByLocalizedName(_majorsData, majorName, locale))
              .where((id) => id != null)
              .cast<int>()
              .toList();
        }

        // Convert education name to ID
        if (_education != null && _education!.isNotEmpty && _educationData.isNotEmpty) {
          educationId = LookupService.getIdByLocalizedName(_educationData, _education!, locale);
        }

        // Convert experience name to ID
        if (_experience != null && _experience!.isNotEmpty && _experienceData.isNotEmpty) {
          yearsOfExperienceId = LookupService.getIdByLocalizedName(_experienceData, _experience!, locale);
        }

        // Format mobile number with country code
        if (_phoneController.text.trim().isNotEmpty) {
          mobileNumber = '+${_country.phoneCode}${_phoneController.text.trim()}';
        }
      } else {
        // For company, also format mobile number
        if (_phoneController.text.trim().isNotEmpty) {
          mobileNumber = '+${_country.phoneCode}${_phoneController.text.trim()}';
        }
      }

      final result = await AuthService.register(
        name: isCompany ? _companyNameController.text.trim() : _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: 'TempPassword123!', // TODO: Add password fields
        passwordConfirmation: 'TempPassword123!',
        role: isCompany ? 'company' : 'candidate',
        companyName: isCompany ? _companyNameController.text.trim() : null,
        dateOfBirth: dateOfBirth,
        mobileNumber: mobileNumber,
        nationalityCountryId: nationalityCountryId,
        residentCountryId: residentCountryId,
        majorIds: majorIds,
        educationId: educationId,
        yearsOfExperienceId: yearsOfExperienceId,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Navigate to OTP verification screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      } else {
        setState(() {
          _isRegistering = false;
          _registerError = result['message'] ?? l10n.registrationFailed;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRegistering = false;
        _registerError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompany = _role == LoginRole.company;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              showLanguageIcon: true,
              showBackButton: true,
              onRightIconTap: () => _showLanguageDialog(context),
            ),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      _RoleToggle(
                        value: _role,
                        onChanged: (v) => setState(() => _role = v),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.letsGetYouStarted,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.fillDetailsToCreateAccount,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Email
                      _Label(l10n.email),
                      const SizedBox(height: 8),
                      _AuthInputField(
                        controller: _emailController,
                        hintText: l10n.enterEmailAddress,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),

                      // Phone
                      _Label(l10n.phoneNumber),
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

                      if (isCompany) ...[
                        _Label(l10n.companyName),
                        const SizedBox(height: 8),
                        _AuthInputField(
                          controller: _companyNameController,
                          hintText: l10n.enterCompanyName,
                        ),
                        const SizedBox(height: 14),
                      ] else ...[
                        _Label(l10n.name),
                        const SizedBox(height: 8),
                        _AuthInputField(
                          controller: _nameController,
                          hintText: l10n.enterYourName,
                          keyboardType: TextInputType.name,
                        ),
                        const SizedBox(height: 14),
                        _Label(l10n.dateOfBirth),
                        const SizedBox(height: 8),
                        _AuthInputField(
                          controller: _dobController,
                          hintText: l10n.select,
                          readOnly: true,
                          suffix: const Icon(
                            Icons.calendar_month_outlined,
                            color: AppTheme.textMuted,
                          ),
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(now.year - 70),
                              lastDate: now,
                              initialDate: DateTime(now.year - 20),
                            );
                            if (picked != null) {
                              setState(() {
                                _dobController.text =
                                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        _Label(l10n.nationality),
                        const SizedBox(height: 8),
                        _DropdownField(
                          value: _nationality,
                          hintText: l10n.choose,
                          loadingText: l10n.loading,
                          noItemsText: l10n.noItemsFound,
                          searchText: l10n.search,
                          items: _nationalityOptions.isEmpty
                              ? [l10n.loading]
                              : _nationalityOptions,
                          onChanged: _nationalityOptions.isEmpty
                              ? null
                              : (v) => setState(() => _nationality = v),
                        ),
                        const SizedBox(height: 14),
                        _Label(l10n.residentsCountry),
                        const SizedBox(height: 8),
                        _DropdownField(
                          value: _residenceCountry,
                          hintText: l10n.choose,
                          loadingText: l10n.loading,
                          noItemsText: l10n.noItemsFound,
                          searchText: l10n.search,
                          items: _residenceCountryOptions.isEmpty
                              ? [l10n.loading]
                              : _residenceCountryOptions,
                          onChanged: _residenceCountryOptions.isEmpty
                              ? null
                              : (v) => setState(() => _residenceCountry = v),
                        ),
                        const SizedBox(height: 14),
                        _Label(l10n.major),
                        const SizedBox(height: 8),
                        _MultiSelectMajorField(
                          selectedMajors: _selectedMajors,
                          chooseText: l10n.choose,
                          selectedText: l10n.selected,
                          searchText: l10n.search,
                          cancelText: l10n.cancel,
                          doneText: l10n.done,
                          items: _majorOptions.isEmpty
                              ? [l10n.loading]
                              : _majorOptions,
                          onChanged: _majorOptions.isEmpty
                              ? null
                              : (selected) => setState(() => _selectedMajors = selected),
                        ),
                        const SizedBox(height: 14),
                        _Label(l10n.educationalLevel),
                        const SizedBox(height: 8),
                        _DropdownField(
                          value: _education,
                          hintText: l10n.choose,
                          loadingText: l10n.loading,
                          noItemsText: l10n.noItemsFound,
                          searchText: l10n.search,
                          items: _educationOptions.isEmpty
                              ? [l10n.loading]
                              : _educationOptions,
                          onChanged: _educationOptions.isEmpty
                              ? null
                              : (v) => setState(() => _education = v),
                        ),
                        const SizedBox(height: 14),
                        _Label(l10n.yearsOfExperience),
                        const SizedBox(height: 8),
                        _DropdownField(
                          value: _experience,
                          hintText: l10n.choose,
                          loadingText: l10n.loading,
                          noItemsText: l10n.noItemsFound,
                          searchText: l10n.search,
                          items: _experienceOptions.isEmpty
                              ? [l10n.loading]
                              : _experienceOptions,
                          onChanged: _experienceOptions.isEmpty
                              ? null
                              : (v) => setState(() => _experience = v),
                        ),
                      ],

                      if (_registerError != null) ...[
                        const SizedBox(height: 12),
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
                                  _registerError!,
                                  style: const TextStyle(
                                    color: AppTheme.errorColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isRegistering ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppTheme.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: _isRegistering
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
                              : Text(
                                  l10n.register,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            children: [
                              TextSpan(text: '${l10n.haveAnAccount} '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Text(
                                    l10n.login,
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w700,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final saved = await LocalizationService.getSavedLocale();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        Locale temp = saved ?? LocalizationService.defaultLocale;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          contentPadding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          content: StatefulBuilder(
            builder: (innerContext, setInnerState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.chooseLanguage,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _LangRow(
                    label: l10n.english,
                    selected: temp.languageCode == 'en',
                    onTap: () => setInnerState(() => temp = const Locale('en')),
                  ),
                  _LangRow(
                    label: l10n.arabic,
                    selected: temp.languageCode == 'ar',
                    onTap: () => setInnerState(() => temp = const Locale('ar')),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () async {
                        await LocalizationService.saveLocale(temp);
                        if (!mounted) return;
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.languageChanged),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.save,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class CompanyRegisterScreen extends StatelessWidget {
  const CompanyRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RegisterScreen(initialRole: LoginRole.company);
  }
}

class JobSeekerRegisterScreen extends StatelessWidget {
  const JobSeekerRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RegisterScreen(initialRole: LoginRole.jobSeeker);
  }
}

class _RoleToggle extends StatelessWidget {
  const _RoleToggle({required this.value, required this.onChanged});

  final LoginRole value;
  final ValueChanged<LoginRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.bodySurfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleChip(
              label: l10n.company,
              selected: value == LoginRole.company,
              onTap: () => onChanged(LoginRole.company),
            ),
          ),
          Expanded(
            child: _RoleChip(
              label: l10n.jobSeeker,
              selected: value == LoginRole.jobSeeker,
              onTap: () => onChanged(LoginRole.jobSeeker),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.white : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppTheme.textPrimary : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  _Label(this.text);
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

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    this.onChanged,
    required this.hintText,
    this.loadingText = 'Loading...',
    this.noItemsText = 'No items found',
    this.searchText = 'Search...',
  });

  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final String hintText;
  final String loadingText;
  final String noItemsText;
  final String searchText;

  Future<void> _showSearchableDialog(BuildContext context) async {
    // Filter out loading text from items
    final validItems = items.where((item) => item != loadingText).toList();
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
                        hintText: searchText,
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
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  noItemsText,
                                  style: const TextStyle(
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
    // Filter out loading text to check if we have valid items
    final validItems = items.where((item) => item != loadingText).toList();
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

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.dashSpace,
  });

  final Color color;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MultiSelectMajorField extends StatelessWidget {
  const _MultiSelectMajorField({
    required this.selectedMajors,
    required this.items,
    this.onChanged,
    this.chooseText = 'Choose',
    this.selectedText = 'selected',
    this.searchText = 'Search...',
    this.cancelText = 'Cancel',
    this.doneText = 'Done',
  });

  final List<String> selectedMajors;
  final List<String> items;
  final ValueChanged<List<String>>? onChanged;
  final String chooseText;
  final String selectedText;
  final String searchText;
  final String cancelText;
  final String doneText;

  Future<void> _showMultiSelectDialog(BuildContext context) async {
    // Filter out loading text from items
    final validItems = items.where((item) => !item.contains('...')).toList();
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
                        hintText: searchText,
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
                          child: Text(cancelText),
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
                          child: Text(doneText),
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
    final validItems = items.where((item) => !item.contains('...')).toList();
    final displayText = selectedMajors.isEmpty
        ? chooseText
        : selectedMajors.length == 1
            ? selectedMajors.first
            : '${selectedMajors.length} $selectedText';

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

class _LangRow extends StatelessWidget {
  const _LangRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.textMuted),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
