/// Global constants used throughout the Ayushka application.
abstract class AppConstants {
  // Application Info
  static const String appName = 'ayushka';
  static const String appTagline = 'Organic Living & Happiness';
  static const String appVersion = '1.0.0';

  // Assets
  static const String logoPath = 'assets/images/logo.png';
  static const String logoIconPath = 'assets/images/logo_icon.png';

  // Network & API Config
  static const String baseUrl = 'http://192.168.0.207:7070/api/v1';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  // Storage Keys (SharedPreferences)
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';
  static const String keyIsDarkMode = 'is_dark_mode';
  static const String keyRememberMe = 'remember_me';
  static const String keySavedEmail = 'saved_email';
  static const String keySelectedGaushalaId = 'selected_gaushala_id';
  static const String keyUserPermissions = 'user_permissions';
  static const String keyIsAdminPermission = 'is_admin_permission';

  // Responsive Breakpoints (px)
  static const double mobileBreakpoint = 650.0;
  static const double tabletBreakpoint = 1100.0;

  // UI Dimensions
  static const double desktopSidebarWidth = 260.0;
  static const double desktopSidebarCollapsedWidth = 76.0;
  static const double maxContentWidth = 1440.0;
  static const double defaultBorderRadius = 12.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Default Autofill Credentials
  static const String defaultUsername = 'ayushka@yopmail.com';
  static const String defaultPassword = 'Admin@123';
}
