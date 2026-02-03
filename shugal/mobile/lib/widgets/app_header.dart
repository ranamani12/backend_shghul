import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/shared/notification_screen.dart';
import '../screens/shared/conversations_screen.dart';
import '../screens/auth/login_screen.dart';
import '../services/notification_service.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../l10n/app_localizations.dart';

/// A consistent header widget for all screens.
/// Contains logo on the left (or back button) and action icons on the right.
/// By default shows chat and notification icons, but can show language icon for auth screens.
class AppHeader extends StatefulWidget {
  final VoidCallback? onRightIconTap;
  final bool showLanguageIcon;
  final bool showBackButton;
  final bool centerLogo;
  final bool showLanguageWithActions;

  const AppHeader({
    super.key,
    this.onRightIconTap,
    this.showLanguageIcon = false,
    this.showBackButton = false,
    this.centerLogo = false,
    this.showLanguageWithActions = false,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  int _notificationUnreadCount = 0;
  int _messageUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.showLanguageIcon) {
      _loadUnreadCounts();
    }
  }

  Future<void> _loadUnreadCounts() async {
    try {
      final notificationCount = await NotificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _notificationUnreadCount = notificationCount;
        });
      }
    } catch (e) {
      // Silently fail - user may not be logged in
    }

    try {
      final messageCount = await ChatService.getUnreadCount();
      if (mounted) {
        setState(() {
          _messageUnreadCount = messageCount;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _navigateToNotifications(BuildContext context) async {
    // Check if user is logged in
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      _showLoginRequiredDialog(context, 'notifications');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationScreen(),
      ),
    );
    // Refresh unread count when returning from notification screen
    _loadUnreadCounts();
  }

  Future<void> _navigateToChat(BuildContext context) async {
    // Check if user is logged in
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      _showLoginRequiredDialog(context, 'chat');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConversationsScreen(),
      ),
    );
    // Refresh unread count when returning from chat screen
    _loadUnreadCounts();
  }

  void _showLoginRequiredDialog(BuildContext context, String feature) {
    final l10n = AppLocalizations.of(context)!;
    final featureName = feature == 'notifications' ? l10n.notifications : l10n.chat;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(l10n.loginRequired),
          ],
        ),
        content: Text(
          l10n.pleaseLoginToAccess(featureName),
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(l10n.login),
          ),
        ],
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
                  _buildLangRow(
                    label: l10n.english,
                    selected: temp.languageCode == 'en',
                    onTap: () => setInnerState(() => temp = const Locale('en')),
                  ),
                  _buildLangRow(
                    label: l10n.arabic,
                    selected: temp.languageCode == 'ar',
                    onTap: () => setInnerState(() => temp = const Locale('ar')),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await LocalizationService.saveLocale(temp);
                        if (!mounted) return;
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
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

  Widget _buildLangRow({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppTheme.primaryColor : AppTheme.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.showBackButton)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.arrow_back,
                color: AppTheme.white,
                size: 28,
              ),
            )
          else if (widget.centerLogo)
            const SizedBox(width: 28)
          else
            Image.asset(
              'assets/images/logo.png',
              height: 80,
              width: 80,
              errorBuilder: (context, error, stackTrace) {
                return const Text(
                  'Shugal',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          if (widget.centerLogo || widget.showBackButton)
            Image.asset(
              'assets/images/logo.png',
              height: 70,
              width: 70,
              errorBuilder: (context, error, stackTrace) {
                return const Text(
                  'Shugal',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          if (widget.showLanguageIcon)
            GestureDetector(
              onTap: widget.onRightIconTap ?? () => _showLanguageDialog(context),
              child: const Icon(
                Icons.language,
                color: AppTheme.white,
                size: 28,
              ),
            )
          else
            Row(
              children: [
                // Language icon (shown with other actions when showLanguageWithActions is true)
                if (widget.showLanguageWithActions) ...[
                  GestureDetector(
                    onTap: () => _showLanguageDialog(context),
                    child: const Icon(
                      Icons.language,
                      color: AppTheme.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                // Chat icon
                GestureDetector(
                  onTap: () => _navigateToChat(context),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: Image.asset(
                          'assets/images/icons/chat.png',
                          color: AppTheme.white,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.chat_bubble_outline,
                              color: AppTheme.white,
                              size: 26,
                            );
                          },
                        ),
                      ),
                      if (_messageUnreadCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.errorColor,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                _messageUnreadCount > 99 ? '99+' : _messageUnreadCount.toString(),
                                style: const TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Notification icon
                GestureDetector(
                  onTap: widget.onRightIconTap ?? () => _navigateToNotifications(context),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.asset(
                          'assets/images/icons/bell.png',
                          color: AppTheme.white,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.notifications_none,
                              color: AppTheme.white,
                              size: 26,
                            );
                          },
                        ),
                      ),
                      if (_notificationUnreadCount > 0)
                        Positioned(
                          right: 1,
                          top: 5,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.errorColor,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                _notificationUnreadCount > 99 ? '99+' : _notificationUnreadCount.toString(),
                                style: const TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
