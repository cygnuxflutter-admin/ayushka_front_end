import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';

import 'app/core/theme/app_theme.dart';
import 'app/core/values/app_colors.dart';
import 'app/core/values/app_constants.dart';
import 'app/data/services/api_service.dart';
import 'app/data/services/connectivity_service.dart';
import 'app/data/services/gaushala_session_service.dart';
import 'app/data/services/storage_service.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

void main() async {
  // 1. Ensure Flutter widget bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Configure clean URL strategy for Web (removes `#` from URL paths)
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // 3. Initialize persistent core singletons
  final storageService = await Get.putAsync(() => StorageService().init());
  Get.put(ConnectivityService());
  Get.put(ApiService());
  final gaushalaService = Get.put(GaushalaSessionService());

  if (storageService.hasToken) {
    await gaushalaService.initSession(user: storageService.getUser());
  }

  // 4. Determine initial route:
  // On Web, skip splash completely! Direct to Dashboard if logged in, else Auth.
  final String initialRoute = kIsWeb
      ? (storageService.hasToken ? AppRoutes.dashboard : AppRoutes.auth)
      : AppRoutes.splash;

  // 5. Run the GetX application
  runApp(AyushkaApp(
    isDarkMode: storageService.isDarkMode,
    initialRoute: initialRoute,
  ));
}

/// Root Application Widget configuring GetMaterialApp, themes, and modular routing.
class AyushkaApp extends StatelessWidget {
  final bool isDarkMode;
  final String initialRoute;

  const AyushkaApp({
    super.key,
    this.isDarkMode = false,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      defaultTransition: kIsWeb ? Transition.fadeIn : Transition.cupertino,
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const _NotFoundScreen(),
      ),
    );
  }
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 64,
                width: 64,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(AppConstants.logoIconPath, fit: BoxFit.contain),
              ),
              const SizedBox(height: 20),
              const Text(
                '404 - Page Not Found',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'The page you are looking for does not exist or has been moved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.dashboard_rounded, size: 18),
                label: const Text('Back to Dashboard'),
                onPressed: () => Get.offAllNamed(AppRoutes.dashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
