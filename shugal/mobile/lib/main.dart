import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shghul/theme/app_theme.dart';
import 'package:shghul/screens/splash_screen.dart';
import 'package:shghul/services/localization_service.dart';

import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.primaryColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Get saved locale
  final savedLocale = await LocalizationService.getSavedLocale();
  
  runApp(ShugalApp(locale: savedLocale));
}

class ShugalApp extends StatefulWidget {
  final Locale? locale;

  const ShugalApp({super.key, this.locale});

  @override
  State<ShugalApp> createState() => _ShugalAppState();
}

class _ShugalAppState extends State<ShugalApp> {
  late Locale _currentLocale;

  @override
  void initState() {
    super.initState();
    _currentLocale = widget.locale ?? LocalizationService.defaultLocale;

    // Register callback for locale changes
    LocalizationService.setLocaleChangeCallback(_onLocaleChanged);
  }

  @override
  void dispose() {
    // Clean up the callback
    LocalizationService.removeLocaleChangeCallback();
    super.dispose();
  }

  void _onLocaleChanged(Locale newLocale) {
    setState(() {
      _currentLocale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shugal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Localization
      locale: _currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocalizationService.supportedLocales,

      home: const SplashScreen(),
    );
  }
}
