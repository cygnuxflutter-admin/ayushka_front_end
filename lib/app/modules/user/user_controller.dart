import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/values/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dropdown_search.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/utils/responsive_layout.dart';
import '../../data/models/gaushala_model.dart';
import '../../data/models/role_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';
import 'views/edit_user_screen.dart';

/// Controller managing User Master state, CRUD operations, filters, and dialogs.
class UserController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();

  // Static in-memory cache to prevent flickering on route navigation
  static final List<UserModel> _cachedUsers = [];

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isSidebarCollapsed = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isSubmitting = false.obs;

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxList<RoleModel> roles = <RoleModel>[].obs;
  final RxList<GaushalaModel> gaushalas = <GaushalaModel>[].obs;
  final RxBool isLoadingRoles = false.obs;
  final RxBool isLoadingGaushalas = false.obs;

  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    resetMobileLimit();
  }

  final Rxn<String> selectedGaushalaFilter = Rxn<String>();
  final Rxn<String> selectedRoleFilter = Rxn<String>();
  final RxString selectedStatusFilter = 'all'.obs; // 'all', 'active', 'inactive'

  /// Returns true if the logged-in user can change the active gaushala
  bool get canChangeGaushala => _gaushalaService.canChangeGaushala;

  /// Look up a Gaushala by ID, Name, or query
  GaushalaModel? findGaushala(String? query) {
    if (query == null || query.isEmpty) return null;
    final lower = query.toLowerCase().trim();
    return gaushalas.firstWhereOrNull(
      (g) => g.id.toLowerCase() == lower || g.gaushalaName.toLowerCase() == lower,
    );
  }

  /// Returns the display name for the currently filtered gaushala on this screen
  String get selectedGaushalaFilterName {
    final filterId = selectedGaushalaFilter.value;
    if (filterId == null || filterId.isEmpty || filterId == 'all') {
      return 'All Gaushalas';
    }
    final match = findGaushala(filterId);
    return match?.gaushalaName ?? filterId;
  }

  /// Set the gaushala filter on this screen
  void setGaushalaFilter(String? gaushalaId) {
    selectedGaushalaFilter.value = (gaushalaId == null || gaushalaId.isEmpty || gaushalaId == 'all')
        ? null
        : gaushalaId;
    currentPage.value = 1;
    resetMobileLimit();
  }

  // Pagination states
  final RxInt currentPage = 1.obs;
  final RxInt rowsPerPage = 5.obs;

  // Mobile infinite scroll state
  final RxInt mobileLimit = 10.obs;

  List<UserModel> get mobileUsers {
    final list = filteredUsers;
    return list.take(mobileLimit.value).toList();
  }

  bool get hasMoreMobile => mobileLimit.value < filteredUsers.length;

  void loadMoreMobile() {
    if (hasMoreMobile) {
      mobileLimit.value += 10;
    }
  }

  void resetMobileLimit() {
    mobileLimit.value = 10;
  }

  List<UserModel> get filteredUsers {
    final query = searchQuery.value.trim().toLowerCase();
    final filterGId = selectedGaushalaFilter.value;
    final filterRId = selectedRoleFilter.value;
    final status = selectedStatusFilter.value;

    return users.where((u) {
      // 1. Gaushala Filter
      if (filterGId != null && filterGId.isNotEmpty && filterGId != 'all') {
        final matchesId = u.gaushalaId == filterGId;
        final matchesName = u.gaushalaName != null &&
            gaushalas.any((g) => g.id == filterGId && g.gaushalaName.toLowerCase() == u.gaushalaName!.toLowerCase());
        if (!matchesId && !matchesName) {
          return false;
        }
      }

      // 2. Role Filter
      if (filterRId != null && filterRId.isNotEmpty && filterRId != 'all') {
        final matchesId = u.roleId == filterRId;
        final matchesName = roles.any((r) => r.id == filterRId && r.roleName.toLowerCase() == u.role.toLowerCase());
        if (!matchesId && !matchesName) {
          return false;
        }
      }

      // 3. Status Filter
      if (status == 'active' && !u.isActive) return false;
      if (status == 'inactive' && u.isActive) return false;

      // 4. Search Query Filter
      if (query.isEmpty) return true;
      final nameMatches = u.name.toLowerCase().contains(query);
      final usernameMatches = (u.username ?? '').toLowerCase().contains(query);
      final emailMatches = u.email.toLowerCase().contains(query);
      final roleMatches = u.role.toLowerCase().contains(query);
      final gaushalaMatches = (u.gaushalaName ?? '').toLowerCase().contains(query);

      return nameMatches || usernameMatches || emailMatches || roleMatches || gaushalaMatches;
    }).toList();
  }

  List<UserModel> get paginatedUsers {
    final list = filteredUsers;
    final int start = (currentPage.value - 1) * rowsPerPage.value;
    if (start >= list.length) {
      if (list.isNotEmpty && currentPage.value > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final maxPage = (list.length / rowsPerPage.value).ceil().clamp(1, 999999);
          if (currentPage.value > maxPage) {
            currentPage.value = maxPage;
          }
        });
      }
      return list.take(rowsPerPage.value).toList();
    }
    return list.skip(start).take(rowsPerPage.value).toList();
  }

  int get totalPages => (filteredUsers.isEmpty)
      ? 1
      : (filteredUsers.length / rowsPerPage.value).ceil();

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      currentPage.value = page;
    }
  }

  void setRowsPerPage(int count) {
    rowsPerPage.value = count;
    currentPage.value = 1;
  }

  @override
  void onInit() {
    super.onInit();
    _loadUser();

    debounce(searchQuery, (_) {
      currentPage.value = 1;
      resetMobileLimit();
    }, time: const Duration(milliseconds: 100));

    // Hydrate from cache immediately
    if (_cachedUsers.isNotEmpty) {
      users.assignAll(_cachedUsers);
    }

    // Fetch initial data
    loadDependenciesAndUsers(showLoading: _cachedUsers.isEmpty);

    // Sync filter with GlobalGaushalaSelector immediately and on future changes
    final initialGId = _gaushalaService.selectedGaushalaId;
    if (initialGId.isNotEmpty) {
      selectedGaushalaFilter.value = initialGId;
    }

    ever(_gaushalaService.selectedGaushala, (selected) {
      if (selected != null && selected.id.isNotEmpty) {
        selectedGaushalaFilter.value = selected.id;
        currentPage.value = 1;
      }
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void _loadUser() {
    currentUser.value = _storageService.getUser();
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Future<void> logout() async {
    _cachedUsers.clear();
    await _storageService.removeToken();
    await _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }

  Future<void> loadDependenciesAndUsers({bool showLoading = false}) async {
    await Future.wait([
      fetchRoles(),
      fetchGaushalas(),
      fetchUsers(showLoading: showLoading),
    ]);
    if ((selectedGaushalaFilter.value == null || selectedGaushalaFilter.value!.isEmpty) &&
        _gaushalaService.selectedGaushalaId.isNotEmpty) {
      selectedGaushalaFilter.value = _gaushalaService.selectedGaushalaId;
    }
  }

  /// Fetches system roles for dropdowns and filtering.
  Future<void> fetchRoles() async {
    isLoadingRoles.value = true;
    try {
      final list = await _apiService.getRoles();
      roles.assignAll(list);
    } catch (_) {
      // Dio interceptor handles toast
    } finally {
      isLoadingRoles.value = false;
    }
  }

  /// Fetches gaushalas for dropdowns and filtering.
  Future<void> fetchGaushalas() async {
    isLoadingGaushalas.value = true;
    try {
      final list = await _apiService.getGaushalas();
      gaushalas.assignAll(list);
    } catch (_) {
      // Dio interceptor handles toast
    } finally {
      isLoadingGaushalas.value = false;
    }
  }

  /// Fetches all users from backend API.
  Future<void> fetchUsers({
    bool showLoading = false,
    bool isManualRefresh = false,
  }) async {
    if (showLoading || users.isEmpty) {
      isLoading.value = true;
    }
    if (isManualRefresh) {
      isRefreshing.value = true;
    }

    try {
      final result = await _apiService.getUsers();
      _cachedUsers
        ..clear()
        ..addAll(result);
      users.assignAll(result);

      if (isManualRefresh) {
        CustomSnackbar.showSuccess(
          title: 'Refreshed',
          message: 'User list updated successfully.',
        );
      }
    } catch (e) {
      // Handled by dio interceptor
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// User-initiated refresh action
  Future<void> refreshUsers() async {
    if (isLoading.value || isRefreshing.value) return;
    await fetchRoles();
    await fetchGaushalas();
    await fetchUsers(showLoading: true, isManualRefresh: true);
  }

  /// Creates a new user via POST /api/v1/users
  Future<bool> createUser({
    required String name,
    required String username,
    required String emailId,
    required String password,
    required String roleId,
    required String gaushalaId,
    bool isActive = true,
  }) async {
    isSubmitting.value = true;
    try {
      final newUser = await _apiService.createUser(
        name: name.trim(),
        username: username.trim(),
        emailId: emailId.trim(),
        password: password,
        roleId: roleId.trim(),
        gaushalaId: gaushalaId.trim(),
        isActive: isActive,
      );

      _cachedUsers.insert(0, newUser);
      users.insert(0, newUser);
      return true;
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Updates an existing user via POST /api/v1/users/:id/update
  Future<bool> updateUser({
    required String id,
    required String name,
    required String username,
    required String emailId,
    String? password,
    required String roleId,
    required String gaushalaId,
    bool? isActive,
  }) async {
    isSubmitting.value = true;
    try {
      final updated = await _apiService.updateUser(
        id,
        name: name.trim(),
        username: username.trim(),
        emailId: emailId.trim(),
        password: (password != null && password.trim().isNotEmpty) ? password.trim() : null,
        roleId: roleId.trim(),
        gaushalaId: gaushalaId.trim(),
        isActive: isActive,
      );

      final index = users.indexWhere((u) => u.id == id);
      if (index != -1) {
        users[index] = updated;
      }
      final cacheIndex = _cachedUsers.indexWhere((u) => u.id == id);
      if (cacheIndex != -1) {
        _cachedUsers[cacheIndex] = updated;
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Deletes a user via DELETE /api/v1/users/:id
  Future<void> deleteUser(String id) async {
    isLoading.value = true;
    try {
      final success = await _apiService.deleteUser(id);
      if (success) {
        users.removeWhere((u) => u.id == id);
        _cachedUsers.removeWhere((u) => u.id == id);
        CustomSnackbar.showSuccess(
          title: 'User Deleted',
          message: 'User account removed successfully.',
        );
      }
    } catch (_) {
      // Interceptor handles
    } finally {
      isLoading.value = false;
    }
  }

  /// Changes user password via POST /auth/change-password
  Future<bool> changePassword({
    required String userId,
    String? oldPassword,
    required String newPassword,
  }) async {
    isSubmitting.value = true;
    try {
      final success = await _apiService.changePassword(
        userId: userId,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      return success;
    } catch (_) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Toggles a user's active status with optimistic update and rollback on failure.
  Future<void> toggleUserStatus(UserModel user, bool newStatus) async {
    final index = users.indexWhere((u) => u.id == user.id);
    if (index == -1) return;

    final oldUser = users[index];
    final updatedUser = oldUser.copyWith(isActive: newStatus);

    // Optimistic UI update
    users[index] = updatedUser;

    try {
      final success = await _apiService.updateUserStatus(user.id, newStatus);
      if (success) {
        final cIndex = _cachedUsers.indexWhere((u) => u.id == user.id);
        if (cIndex != -1) {
          _cachedUsers[cIndex] = updatedUser;
        }
        CustomSnackbar.showSuccess(
          title: 'Status Updated',
          message: '${user.name} is now ${newStatus ? 'Active' : 'Inactive'}.',
        );
      } else {
        // Rollback
        users[index] = oldUser;
      }
    } catch (e) {
      // Rollback
      users[index] = oldUser;
    }
  }

  // -------------------------------------------------------------
  // DIALOGS: ADD / EDIT / DELETE
  // -------------------------------------------------------------

  /// Opens Dialog to Add New User
  void openAddUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    final Rxn<RoleModel> selectedRole = Rxn<RoleModel>();
    final Rxn<GaushalaModel> selectedGaushala = Rxn<GaushalaModel>();
    final RxBool isActive = true.obs;

    // Pre-select active global gaushala if available
    if (_gaushalaService.selectedGaushala.value != null && gaushalas.isNotEmpty) {
      final activeG = _gaushalaService.selectedGaushala.value!;
      selectedGaushala.value = gaushalas.firstWhereOrNull((g) => g.id == activeG.id);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              PhosphorIconsRegular.userPlus,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add New User',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          if (Get.isDialogOpen ?? false) {
                            Get.back();
                          } else if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create a new staff or manager profile with specific gaushala and role credentials.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),

                  // Full Name
                  CustomTextField(
                    controller: nameController,
                    label: 'Full Name *',
                    hint: 'e.g. Ravi Sharma',
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Full name is required';
                      if (val.trim().length < 2) return 'Name must be at least 2 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Username & Email Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: usernameController,
                          label: 'Username *',
                          hint: 'e.g. ravi_sharma',
                          prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Username is required';
                            if (val.trim().length < 3) return 'Min 3 chars';
                            if (val.trim().contains(' ')) return 'No spaces allowed';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: CustomTextField(
                          controller: emailController,
                          label: 'Email ID *',
                          hint: 'e.g. ravi@example.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Email is required';
                            if (!GetUtils.isEmail(val.trim())) return 'Invalid email format';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Gaushala & Role Dropdowns Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gaushala Dropdown
                      Expanded(
                        child: Obx(() {
                          return CustomDropdownSearch<GaushalaModel>(
                            label: 'Gaushala',
                            isRequired: true,
                            hint: isLoadingGaushalas.value ? 'Loading...' : 'Select Gaushala',
                            prefixIcon: Icons.storefront_outlined,
                            selectedItem: selectedGaushala.value,
                            items: gaushalas.toList(),
                            itemAsString: (g) => g.gaushalaName,
                            compareFn: (g1, g2) => g1.id == g2.id,
                            searchable: true,
                            searchHint: 'Search gaushala...',
                            onChanged: (sel) => selectedGaushala.value = sel,
                            validator: (sel) => sel == null ? 'Gaushala is required' : null,
                          );
                        }),
                      ),
                      const SizedBox(width: 14),

                      // Role Dropdown
                      Expanded(
                        child: Obx(() {
                          return CustomDropdownSearch<RoleModel>(
                            label: 'Role',
                            isRequired: true,
                            hint: isLoadingRoles.value ? 'Loading...' : 'Select Role',
                            prefixIcon: PhosphorIconsRegular.shieldCheck,
                            selectedItem: selectedRole.value,
                            items: roles.toList(),
                            itemAsString: (r) => r.roleName,
                            compareFn: (r1, r2) => r1.id == r2.id,
                            searchable: true,
                            searchHint: 'Search role...',
                            onChanged: (sel) => selectedRole.value = sel,
                            validator: (sel) => sel == null ? 'Role is required' : null,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  CustomTextField(
                    controller: passwordController,
                    label: 'Password *',
                    hint: 'Minimum 6 characters',
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Password is required';
                      if (val.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Active Switch
                  Obx(
                    () => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isActive.value ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                                size: 18,
                                color: isActive.value ? AppColors.success : AppColors.textMutedLight,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Account Status: ${isActive.value ? 'Active' : 'Inactive'}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: isActive.value,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) => isActive.value = val,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dialog Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          if (Get.isDialogOpen ?? false) {
                            Get.back();
                          } else if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      Obx(
                        () => CustomButton(
                          text: 'Create User',
                          icon: Icons.add_rounded,
                          isLoading: isSubmitting.value,
                          width: 145,
                          height: 42,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              if (selectedGaushala.value == null) {
                                CustomSnackbar.showError(
                                  title: 'Gaushala Required',
                                  message: 'Please select a gaushala for this user.',
                                );
                                return;
                              }
                              if (selectedRole.value == null) {
                                CustomSnackbar.showError(
                                  title: 'Role Required',
                                  message: 'Please assign a role to this user.',
                                );
                                return;
                              }

                              final success = await createUser(
                                name: nameController.text.trim(),
                                username: usernameController.text.trim(),
                                emailId: emailController.text.trim(),
                                password: passwordController.text,
                                roleId: selectedRole.value!.id,
                                gaushalaId: selectedGaushala.value!.id,
                                isActive: isActive.value,
                              );

                              if (success) {
                                if (Get.isDialogOpen ?? false) {
                                  Get.back();
                                } else if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                }
                                CustomSnackbar.showSuccess(
                                  title: 'User Created',
                                  message: 'Account for "${nameController.text.trim()}" created successfully.',
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Opens Dialog to Edit User
  void openEditUserDialog(BuildContext context, UserModel user) {
    if (ResponsiveLayout.isMobile(context)) {
      Get.to(() => EditUserScreen(user: user));
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.name);
    final usernameController = TextEditingController(text: user.username ?? '');
    final emailController = TextEditingController(text: user.email);
    final passwordController = TextEditingController();

    // Match initial role and gaushala
    final initialRole = roles.firstWhereOrNull(
      (r) => r.id == user.roleId || r.roleName.toLowerCase() == user.role.toLowerCase(),
    );
    final initialGaushala = gaushalas.firstWhereOrNull(
      (g) => g.id == user.gaushalaId || (user.gaushalaName != null && g.gaushalaName.toLowerCase() == user.gaushalaName!.toLowerCase()),
    );

    final Rxn<RoleModel> selectedRole = Rxn<RoleModel>(initialRole);
    final Rxn<GaushalaModel> selectedGaushala = Rxn<GaushalaModel>(initialGaushala);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: AppColors.info,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Edit User Profile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          if (Get.isDialogOpen ?? false) {
                            Get.back();
                          } else if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Modify profile details, credentials, and facility permissions for "${user.name}".',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),

                  // Full Name
                  CustomTextField(
                    controller: nameController,
                    label: 'Full Name *',
                    hint: 'e.g. Ravi Sharma',
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Full name is required';
                      if (val.trim().length < 2) return 'Name must be at least 2 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Username & Email Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: usernameController,
                          label: 'Username *',
                          hint: 'e.g. ravi_sharma',
                          prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Username is required';
                            if (val.trim().length < 3) return 'Min 3 chars';
                            if (val.trim().contains(' ')) return 'No spaces allowed';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: CustomTextField(
                          controller: emailController,
                          label: 'Email ID *',
                          hint: 'e.g. ravi@example.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Email is required';
                            if (!GetUtils.isEmail(val.trim())) return 'Invalid email format';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Gaushala & Role Dropdowns Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gaushala Dropdown
                      Expanded(
                        child: Obx(() {
                          return CustomDropdownSearch<GaushalaModel>(
                            label: 'Gaushala',
                            isRequired: true,
                            hint: 'Select Gaushala',
                            prefixIcon: Icons.storefront_outlined,
                            selectedItem: selectedGaushala.value,
                            items: gaushalas.toList(),
                            itemAsString: (g) => g.gaushalaName,
                            compareFn: (g1, g2) => g1.id == g2.id,
                            searchable: true,
                            searchHint: 'Search gaushala...',
                            onChanged: (sel) => selectedGaushala.value = sel,
                            validator: (sel) => sel == null ? 'Gaushala is required' : null,
                          );
                        }),
                      ),
                      const SizedBox(width: 14),

                      // Role Dropdown
                      Expanded(
                        child: Obx(() {
                          return CustomDropdownSearch<RoleModel>(
                            label: 'Role',
                            isRequired: true,
                            hint: 'Select Role',
                            prefixIcon: PhosphorIconsRegular.shieldCheck,
                            selectedItem: selectedRole.value,
                            items: roles.toList(),
                            itemAsString: (r) => r.roleName,
                            compareFn: (r1, r2) => r1.id == r2.id,
                            searchable: true,
                            searchHint: 'Search role...',
                            onChanged: (sel) => selectedRole.value = sel,
                            validator: (sel) => sel == null ? 'Role is required' : null,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Password Field (Optional on Edit)
                  CustomTextField(
                    controller: passwordController,
                    label: 'New Password',
                    hint: 'Leave empty to keep current password',
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    validator: (val) {
                      if (val != null && val.isNotEmpty && val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Dialog Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          if (Get.isDialogOpen ?? false) {
                            Get.back();
                          } else if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      Obx(
                        () => CustomButton(
                          text: 'Save Changes',
                          icon: Icons.check_rounded,
                          isLoading: isSubmitting.value,
                          width: 150,
                          height: 42,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              if (selectedGaushala.value == null) {
                                CustomSnackbar.showError(
                                  title: 'Gaushala Required',
                                  message: 'Please select a gaushala for this user.',
                                );
                                return;
                              }
                              if (selectedRole.value == null) {
                                CustomSnackbar.showError(
                                  title: 'Role Required',
                                  message: 'Please assign a role to this user.',
                                );
                                return;
                              }

                              final success = await updateUser(
                                id: user.id,
                                name: nameController.text.trim(),
                                username: usernameController.text.trim(),
                                emailId: emailController.text.trim(),
                                password: passwordController.text.isNotEmpty ? passwordController.text : null,
                                roleId: selectedRole.value!.id,
                                gaushalaId: selectedGaushala.value!.id,
                                isActive: user.isActive,
                              );

                              if (success) {
                                if (Get.isDialogOpen ?? false) {
                                  Get.back();
                                } else if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                }
                                CustomSnackbar.showSuccess(
                                  title: 'User Updated',
                                  message: 'Profile for "${nameController.text.trim()}" updated successfully.',
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Opens Confirm Delete User dialog
  void confirmDeleteUser(BuildContext context, UserModel user) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Delete User'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete user account "${user.name}" (@${user.username ?? user.email})?',
            ),
            const SizedBox(height: 8),
            const Text(
              'This user will lose access to the portal immediately. This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              } else {
                Get.back();
              }
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              } else {
                Get.back();
              }
              deleteUser(user.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Opens Change / Reset Password dialog for a specific user.
  void openChangePasswordDialog(BuildContext context, UserModel user) {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final bool isAdmin = user.isAdmin;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: AppColors.warning,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Change Password',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${user.name} (${user.role})',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          if (Get.isDialogOpen ?? false) {
                            Get.back();
                          } else if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Old Password (Only for other non-admin users)
                  if (!isAdmin) ...[
                    CustomTextField(
                      controller: oldPasswordController,
                      label: 'Old Password *',
                      hint: 'Enter current password',
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Old password is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // New Password (Always present)
                  CustomTextField(
                    controller: newPasswordController,
                    label: 'New Password *',
                    hint: 'Enter new password',
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'New password is required';
                      }
                      if (val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      if (!isAdmin && val == oldPasswordController.text) {
                        return 'New password cannot be identical to old password';
                      }
                      return null;
                    },
                  ),

                  // Confirm New Password (Only for other non-admin users)
                  if (!isAdmin) ...[
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: confirmPasswordController,
                      label: 'Confirm New Password *',
                      hint: 'Re-enter new password',
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (val != newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Dialog Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          if (Get.isDialogOpen ?? false) {
                            Get.back();
                          } else if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      Obx(
                        () => CustomButton(
                          text: 'Change Password',
                          icon: Icons.check_rounded,
                          isLoading: isSubmitting.value,
                          width: 170,
                          height: 42,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final success = await changePassword(
                                userId: user.id,
                                oldPassword: isAdmin ? null : oldPasswordController.text.trim(),
                                newPassword: newPasswordController.text.trim(),
                              );

                              if (success) {
                                if (Get.isDialogOpen ?? false) {
                                  Get.back();
                                } else if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                }
                                CustomSnackbar.showSuccess(
                                  title: 'Password Changed',
                                  message: 'Password for "${user.name}" updated successfully.',
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

}
