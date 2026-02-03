import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'home_screen.dart';
import 'jobs_screen.dart';
import 'interview_screen.dart';
import 'digital_resume_screen.dart';
import 'profile_screen.dart';

class CandidateMainScreen extends StatefulWidget {
  final int initialIndex;

  const CandidateMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<CandidateMainScreen> createState() => _CandidateMainScreenState();
}

class _CandidateMainScreenState extends State<CandidateMainScreen> {
  late int _selectedIndex;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _screens = [
      const JobsScreen(),
      const InterviewScreen(),
      const DigitalResumeScreen(),
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

      backgroundColor: AppTheme.white,
      color: AppTheme.primaryColor,
      buttonBackgroundColor: AppTheme.primaryColor,
      animationCurve: Curves.easeInOutCubic,
      animationDuration: const Duration(milliseconds: 300),

      items: [
        _navItem(
          iconPath: 'assets/images/icons/home_icon.png',
          fallbackIcon: Icons.work_outline,
          label: l10n.jobs,
          index: 0,
        ),
        _navItem(
          iconPath: 'assets/images/icons/interview.png',
          fallbackIcon: Icons.calendar_today_outlined,
          label: l10n.interview,
          index: 1,
        ),
        _navItem(
          iconPath: 'assets/images/icons/digital_resume.png',
          fallbackIcon: Icons.description_outlined,
          label: l10n.digitalResume,
          index: 2,
        ),
        _navItem(
          iconPath: 'assets/images/icons/profile_icon.png',
          fallbackIcon: Icons.person_outline,
          label: l10n.profile,
          index: 3,
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
