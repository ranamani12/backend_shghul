import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'add_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const AddScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      extendBody: true,

      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      bottomNavigationBar: _buildBottomNavigationBar(l10n),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildBottomNavigationBar(AppLocalizations l10n) {
    return CurvedNavigationBar(
      index: _selectedIndex,
      onTap: _onItemTapped,

      backgroundColor: AppTheme.secondaryColor,
      color: AppTheme.primaryColor,
      buttonBackgroundColor: AppTheme.primaryColor,

      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),

      items: [
        _navItem(
          iconPath: 'assets/images/icons/home_icon.png',
          fallbackIcon: Icons.home_outlined,
          label: l10n.home,
          index: 0,
        ),
        _navItem(
          iconPath: 'assets/images/icons/add_icon.png',
          fallbackIcon: Icons.add,
          label: l10n.add,
          index: 1,
        ),
        _navItem(
          iconPath: 'assets/images/icons/profile_icon.png',
          fallbackIcon: Icons.person_outline,
          label: l10n.profile,
          index: 2,
        ),
      ],
    );
  }

  Widget _navItem({
    required String iconPath,
    required IconData fallbackIcon,
    required String label,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          iconPath,
          width: 24,
          height: 24,
          color: AppTheme.white,
          errorBuilder: (_, __, ___) => Icon(
            fallbackIcon,
            size: 24,
            color: AppTheme.white,
          ),
        ),
        const SizedBox(height: 4),
        if (!isSelected)
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}
