import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/values/app_colors.dart';
import '../../routes/app_routes.dart';

/// Clean 403 Forbidden Access Screen displayed when a user attempts
/// to access a protected route without adequate role/sub-module permissions.
class ForbiddenScreen extends StatelessWidget {
  final String? attemptedRoute;

  const ForbiddenScreen({super.key, this.attemptedRoute});

  @override
  Widget build(BuildContext context) {
    final routeName = attemptedRoute ?? Get.parameters['route'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 42),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5ECE2), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Security Shield Icon Container
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEECEB),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFECDCA), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shield_outlined,
                      size: 42,
                      color: Color(0xFFD92D20),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Error Code Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFECDCA)),
                  ),
                  child: const Text(
                    'HTTP 403 • ACCESS DENIED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB42318),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  'Permission Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D2939),
                  ),
                ),
                const SizedBox(height: 10),

                // Descriptive Text
                Text(
                  routeName.isNotEmpty
                      ? 'You do not have administrative permission to view the requested page ($routeName).'
                      : 'You do not have the required role or permissions to access this feature.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEAECF0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Color(0xFF667085)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'If you believe this is an error, please reach out to your system administrator to adjust your permissions.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF344054),
                        side: const BorderSide(color: Color(0xFFD0D5DD)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Go Back'),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Get.offAllNamed(AppRoutes.dashboard);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.dashboard_rounded, size: 16),
                      label: const Text('Back to Dashboard'),
                      onPressed: () => Get.offAllNamed(AppRoutes.dashboard),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
