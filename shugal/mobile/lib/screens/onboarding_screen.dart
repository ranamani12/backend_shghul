import 'package:flutter/material.dart';
import 'package:shghul/screens/guest/guest_main_screen.dart';
import 'package:shghul/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'candidate/candidate_main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingPage> _getPages() {
    return [
      OnboardingPage(
        image: 'assets/images/onboarding/onboard_two.png',
      ),
      OnboardingPage(
        image: 'assets/images/onboarding/onboard_three.png',
      ),
    ];
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const GuestMainScreen()),
    );
  }

  void _nextPage() { 
    final pages = _getPages();
    
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();
    
    return Scaffold(
      backgroundColor: AppTheme.bodySurfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Logo and Globe Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/green_logo.png',
                    height: 70,
                    width: 70,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.work,
                        size: 40,
                        color: AppTheme.primaryColor,
                      );
                    },
                  ),
                  // Globe Icon
                  IconButton(
                    icon: const Icon(
                      Icons.language,
                      color: AppTheme.textPrimary,
                      size: 24,
                    ),
                    onPressed: () {
                      // Handle language selection
                    },
                  ),
                ],
              ),
            ),
            
            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(pages[index]);
                },
              ),
            ),
            
            // Circular Next Button
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Center(
                child: InkWell(
                  onTap: _nextPage,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: AppTheme.white,
                      size: 28,
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

  Widget _buildPage(OnboardingPage page) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Image.asset(
          page.image,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.error,
              size: 200,
              color: AppTheme.primaryColor,
            );
          },
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String image;

  OnboardingPage({
    required this.image,
  });
}
