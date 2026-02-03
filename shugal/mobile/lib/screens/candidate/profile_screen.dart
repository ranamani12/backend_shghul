import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/logout_dialog.dart';
import '../../widgets/app_header.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import '../guest/guest_main_screen.dart';
import 'profile_update_screen.dart';
import 'change_password_screen.dart';
import 'privacy_policy_screen.dart';
import 'customer_service_screen.dart';
import 'application_history_screen.dart';
import '../company/company_profile_update_screen.dart';
import '../company/application_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    Map<String, dynamic>? user;
    if (isLoggedIn) {
      user = await AuthService.getUser();
    }
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await LogoutDialog.show(context);
    
    if (shouldLogout == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await AuthService.logout();
        
        if (!mounted) return;

        Navigator.of(context).pop();

        // Navigate to guest home screen after logout
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const GuestMainScreen(),
          ),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.loggedOutSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.logoutFailed}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                color: AppTheme.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(56),
                  topRight: Radius.circular(56),
                ),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !_isLoggedIn
                      ? _buildGuestView()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                              const SizedBox(height: 24),
                              Text(
                                AppLocalizations.of(context)!.profile,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildProfileContent(),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestView() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
          const SizedBox(height: 24),
          Text(
            l10n.profile,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Guest welcome card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.welcomeGuest,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.loginToAccessAllFeatures,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      l10n.loginOrRegister,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Guest accessible options
          Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.borderColor,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _settingsTile(
                  leadingAsset: 'assets/images/icons/customer_support.png',
                  title: l10n.customerServiceSupport,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomerServiceScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                _settingsTile(
                  leadingAsset: 'assets/images/icons/privacy_policy.png',
                  title: l10n.privacyPolicy,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Login required features info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.loginRequiredToAccessLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _loginRequiredItem(l10n.editProfile),
                _loginRequiredItem(l10n.applyForJobs),
                _loginRequiredItem(l10n.chatWithCompanies),
                _loginRequiredItem(l10n.viewApplicationHistory),
                _loginRequiredItem(l10n.postAds),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginRequiredItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 4),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 14,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final role = _user?['role'] as String? ?? 'candidate';
    
    if (role == 'company') {
      return _buildCompanyProfile();
    } else {
      return _buildCandidateProfile();
    }
  }

  Widget _buildCandidateProfile() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _settingsTile(
            leadingAsset: 'assets/images/icons/profile_1.png',
            title: l10n.profileSetting,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileUpdateScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          _settingsTile(
            leadingAsset: 'assets/images/icons/lock.png',
            title: l10n.changePassword,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          _settingsTile(
            leadingAsset: 'assets/images/icons/history.png',
            title: l10n.history,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ApplicationHistoryScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          _settingsTile(
            leadingAsset: 'assets/images/icons/customer_support.png',
            title: l10n.customerServiceSupport,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CustomerServiceScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          _settingsTile(
            leadingAsset: 'assets/images/icons/privacy_policy.png',
            title: l10n.privacyPolicy,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          _settingsTile(
            leadingAsset: 'assets/images/icons/logout.png',
            title: l10n.logout,
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyProfile() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _settingsTile(
            leadingAsset: 'assets/images/icons/profile_1.png',
            title: l10n.companyProfileSetting,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CompanyProfileUpdateScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          _settingsTile(
            leadingAsset: 'assets/images/icons/lock.png',
            title: l10n.changePassword,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          _settingsTile(
            leadingAsset: 'assets/images/icons/history.png',
            title: l10n.applicationsReceived,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CompanyApplicationHistoryScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          _settingsTile(
            leadingAsset: 'assets/images/icons/customer_support.png',
            title: l10n.customerServiceSupport,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CustomerServiceScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          _settingsTile(
            leadingAsset: 'assets/images/icons/privacy_policy.png',
            title: l10n.privacyPolicy,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          _settingsTile(
            leadingAsset: 'assets/images/icons/logout.png',
            title: l10n.logout,
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    String? leadingAsset,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Image.asset(
                  leadingAsset!,
                  height: 50,
                  width: 50,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.notification_important_sharp,
                      size: 40,
                      color: AppTheme.primaryColor,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textMuted,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}
