import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../data/services/api_service.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/permission_service.dart';
import '../../data/services/storage_service.dart';
import '../cow/cow_controller.dart';
import '../../routes/app_routes.dart';

/// Controller handling login authentication and validation with default autofill.
class AuthController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController userIdController =
      TextEditingController();
  TextEditingController get emailController => userIdController;
  final TextEditingController passwordController =
      TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool rememberMe = true.obs;
  final RxBool isPasswordHidden = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() {
    rememberMe.value = _storageService.isRememberMe;
    if (rememberMe.value) {
      final savedUser = _storageService.getSavedUserId();
      if (savedUser != null && savedUser.isNotEmpty && savedUser.toLowerCase() != 'admin') {
        userIdController.text = savedUser;
      }
    }
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  String? validateUserId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your username or email';
    }
    return null;
  }

  String? validateEmail(String? value) => validateUserId(value);

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  bool _isSubmitting = false;

  Future<void> login() async {
    if (_isSubmitting || isLoading.value) return;
    _isSubmitting = true;
    try {
      if (formKey.currentState?.validate() != true) return;

      final username = userIdController.text.trim();
      final password = passwordController.text;

      isLoading.value = true;
      try {
        final user = await _apiService.login(username: username, password: password);

        // Save credentials if Remember Me is checked
        await _storageService.setRememberMe(rememberMe.value);
        if (rememberMe.value) {
          await _storageService.saveUserId(username);
        }

        // Initialize global active gaushala session from user profile
        if (Get.isRegistered<GaushalaSessionService>()) {
          await Get.find<GaushalaSessionService>().initSession(user: user, isLogin: true);
        } else {
          final service = Get.put(GaushalaSessionService());
          await service.initSession(user: user, isLogin: true);
        }

        // Fetch role & submodule permissions for RBAC
        if (Get.isRegistered<PermissionService>()) {
          await Get.find<PermissionService>().initPermissions();
        } else {
          final pService = Get.put(PermissionService(), permanent: true);
          await pService.initPermissions();
        }

        // Clear in-memory cache so fresh data loads for this user session
        CowController.clearCache();

        CustomSnackbar.showSuccess(
          title: 'Authentication Successful',
          message: 'Welcome back, ${user.name}!',
        );

        // Navigate to Dashboard
        Get.offAllNamed(AppRoutes.dashboard);
      } catch (_) {
        // Handled in api_service interceptor
      } finally {
        isLoading.value = false;
      }
    } finally {
      _isSubmitting = false;
    }
  }

  @override
  void onClose() {
    userIdController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
