import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shghul/theme/app_theme.dart';
import 'package:shghul/screens/onboarding_screen.dart';
import 'package:shghul/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'candidate/candidate_main_screen.dart';
import 'company/company_main_screen.dart';
import 'guest/guest_main_screen.dart';
import 'auth/login_screen.dart';
import 'auth/otp_verification_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Check if user is logged in
    final isLoggedIn = await AuthService.isLoggedIn();
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    
    if (!mounted) return;
    
    if (isLoggedIn) {
      // User is logged in - check if email is verified
      final user = await AuthService.getUser();
      if (user != null) {
        final emailVerifiedAt = user['email_verified_at'];
        final email = user['email'] as String? ?? '';
        final role = user['role'] as String? ?? '';
        
        if (emailVerifiedAt == null && email.isNotEmpty) {
          // Email not verified - redirect to OTP screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(email: email),
            ),
          );
        } else {
          // Email verified - go to role-based main screen
          if (role == 'company') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const CompanyMainScreen()),
            );
          } else {
            // Default to candidate main screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const CandidateMainScreen()),
            );
          }
        }
      } else {
        // User data not found - go to guest home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GuestMainScreen()),
        );
      }
    } else if (hasSeenOnboarding) {
      // User has seen onboarding but not logged in - go to guest home (not login)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GuestMainScreen()),
      );
    } else {
      // First time - show onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context)  {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Stack(
        children: [
          // Centered Logo
          Center(
            child: Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/images/logo.png',
                height: 150,
                width: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.work,
                    size: 150,
                    color: AppTheme.white,
                  );
                },
              ),
            ),
          ),
          // Loading Indicator at Bottom
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.white),
                  strokeWidth: 3.5,
                  backgroundColor: AppTheme.white.withOpacity(0.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
