class AppConstants {
  // App Info
  static const String appName = 'Shugal';
  static const String appVersion = '1.0.0';

  // API Configuration
  // IMPORTANT: Change the _apiHost based on your testing environment:
  // - Android Emulator: '10.0.2.2:8000'
  // - iOS Simulator: 'localhost:8000' or '127.0.0.1:8000'
  // - Physical device: Your computer's local IP (e.g., '192.168.1.16:8000')
  //   Run 'ipconfig' (Windows) or 'ifconfig' (Mac/Linux) to find your IP

  // Change this line based on your environment:
  // static const String _apiHost = '10.0.2.2:8000'; // Android Emulator
  // static const String _apiHost = 'localhost:8000'; // iOS Simulator
  // static const String _apiHost = '192.168.1.3:8000'; // Physical device (update IP)
  static const String _serverIp = 'staging.shghul.com'; // Server IP only (for WebSocket)

  static const String _apiHost = 'staging.shghul.com'; // Physical device (update IP)

  static const String baseUrl = 'https://$_apiHost/api';
  static const String apiVersion = 'v1';

  // Storage URL for images/files (without /api)
  static const String storageUrl = 'https://$_apiHost/storage';

  // WebSocket Configuration (Laravel Reverb)
  static const String reverbHost = _serverIp;
  static const int reverbPort = 8080;
  static const String reverbAppKey = 'jprklrye2o5k0ugmvdus';
  static const String reverbScheme = 'https'; // Use 'https' for production
  
  // Asset Paths
  static const String logoPath = 'assets/images/logo.png';

  // Localization
  static const String defaultLocale = 'en';
  static const List<String> supportedLocales = ['en', 'ar'];
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String languageKey = 'language';
  static const String themeKey = 'theme_mode';
  
  // Pagination
  static const int defaultPageSize = 15;
  static const int maxPageSize = 50;
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 255;
  static const int maxEmailLength = 255;
  
  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  
  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];
}
