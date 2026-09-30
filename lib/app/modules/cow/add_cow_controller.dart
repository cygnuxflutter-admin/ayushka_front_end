import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../data/models/breed_model.dart';
import '../../data/models/cow_model.dart';
import '../../data/models/gaushala_model.dart';
import '../../data/models/shed_model.dart';
import '../../data/models/type_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';

/// Controller managing Add Cow form state, catalog loading, and submission.
class AddCowController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  // User
  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isSidebarCollapsed = false.obs;

  // Edit mode
  final Rxn<CowModel> editingCow = Rxn<CowModel>();
  bool get isEditMode => editingCow.value != null;

  // Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController tagIdController = TextEditingController();
  final TextEditingController calfNameController = TextEditingController();
  final TextEditingController calfWeightController = TextEditingController();
  final TextEditingController avatarUrlController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();
  final TextEditingController damIdController = TextEditingController();
  final TextEditingController sireIdController = TextEditingController();

  // Observable form state
  final RxBool isFemale = true.obs;
  final Rxn<DateTime> dob = Rxn<DateTime>();
  final Rxn<TimeOfDay> deliveryTime = Rxn<TimeOfDay>();
  final Rxn<DateTime> purchaseDate = Rxn<DateTime>();
  final Rxn<DateTime> sendDiedDate = Rxn<DateTime>();

  // Dropdown selections
  final Rxn<BreedModel> selectedBreed = Rxn<BreedModel>();
  final Rxn<GaushalaModel> selectedGaushala = Rxn<GaushalaModel>();
  final Rxn<TypeModel> selectedType = Rxn<TypeModel>();
  final Rxn<ShedModel> selectedShed = Rxn<ShedModel>();
  final Rxn<CowModel> selectedDam = Rxn<CowModel>();
  final Rxn<CowModel> selectedSire = Rxn<CowModel>();

  // Catalog data
  final RxList<BreedModel> breeds = <BreedModel>[].obs;
  final RxList<GaushalaModel> gaushalas = <GaushalaModel>[].obs;
  final RxList<TypeModel> types = <TypeModel>[].obs;
  final RxList<ShedModel> sheds = <ShedModel>[].obs;
  final RxList<CowModel> allGaushalaCows = <CowModel>[].obs;
  final RxList<CowModel> damCows = <CowModel>[].obs;
  final RxList<CowModel> sireCows = <CowModel>[].obs;
  final RxBool isLoadingCows = false.obs;

  // Search filter for breed dropdown
  final RxString breedSearchQuery = ''.obs;

  List<BreedModel> get filteredBreeds {
    final query = breedSearchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return breeds;
    return breeds.where((b) => b.breedName.toLowerCase().contains(query)).toList();
  }

  // Loading states
  final RxBool isLoadingCatalogs = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool catalogsLoaded = false.obs;
  final RxString catalogError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    _checkEditMode();
    _fetchCatalogs();
    ever(isFemale, (bool female) {
      if (!female) {
        _autoSelectNaType();
      } else {
        if (selectedType.value != null && _isNaType(selectedType.value!)) {
          selectedType.value = null;
        }
      }
    });
    ever(selectedGaushala, (GaushalaModel? g) {
      fetchShedsForGaushala(g?.id);
      fetchCowsForGaushala(g?.id);
    });
    if (Get.isRegistered<GaushalaSessionService>()) {
      ever(Get.find<GaushalaSessionService>().selectedGaushala, (GaushalaModel? g) {
        if (!isEditMode && g != null && selectedGaushala.value?.id != g.id) {
          final match = findGaushala(g.id);
          if (match != null) {
            selectedGaushala.value = match;
          }
        }
      });
    }
  }

  void _checkEditMode() {
    final dynamic args = Get.arguments;
    if (args is Map && args['cow'] is CowModel) {
      editingCow.value = args['cow'] as CowModel;
    } else if (args is CowModel) {
      editingCow.value = args;
    }

    if (isEditMode) {
      final cow = editingCow.value!;
      tagIdController.text = cow.tagId;
      calfNameController.text = cow.calfName ?? '';
      calfWeightController.text = cow.calfWeight > 0 ? cow.calfWeight.toString() : '';
      avatarUrlController.text = cow.avatarUrl ?? '';
      remarkController.text = cow.remark ?? '';
      isFemale.value = cow.isFemale;

      if (cow.dob != null && cow.dob!.isNotEmpty) {
        dob.value = DateTime.tryParse(cow.dob!);
      }
      if (cow.purchaseDate != null && cow.purchaseDate!.isNotEmpty) {
        purchaseDate.value = DateTime.tryParse(cow.purchaseDate!);
      }
      if (cow.sendDiedDate != null && cow.sendDiedDate!.isNotEmpty) {
        sendDiedDate.value = DateTime.tryParse(cow.sendDiedDate!);
      }
      if (cow.deliveryTime != null && cow.deliveryTime!.isNotEmpty) {
        final parts = cow.deliveryTime!.split(':');
        if (parts.length >= 2) {
          final h = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          if (h != null && m != null) {
            deliveryTime.value = TimeOfDay(hour: h, minute: m);
          }
        }
      }
    }
  }

  String? _lastLoadedGaushalaId = '';

  Future<void> fetchShedsForGaushala(String? gaushalaId) async {
    final cleanId = (gaushalaId != null && gaushalaId.trim().isNotEmpty) ? gaushalaId.trim() : null;
    if (_lastLoadedGaushalaId == cleanId && sheds.isNotEmpty) return;
    _lastLoadedGaushalaId = cleanId;

    try {
      final list = await _apiService.getSheds(gaushalaId: cleanId);
      sheds.assignAll(list);
      if (isEditMode && selectedShed.value == null && editingCow.value?.shed != null) {
        final match = list.firstWhereOrNull(
          (s) => s.id == editingCow.value!.shed!.id || s.shedName.toLowerCase() == editingCow.value!.shed!.shedName.toLowerCase(),
        );
        if (match != null) {
          selectedShed.value = match;
        }
      } else if (selectedShed.value != null && !list.any((s) => s.id == selectedShed.value!.id)) {
        selectedShed.value = null;
      }
    } catch (_) {}
  }

  String? _lastLoadedCowsGaushalaId;

  Future<void> fetchCowsForGaushala(String? gaushalaId) async {
    final cleanId = (gaushalaId != null && gaushalaId.trim().isNotEmpty) ? gaushalaId.trim() : null;
    if (cleanId == null) {
      allGaushalaCows.clear();
      damCows.clear();
      sireCows.clear();
      selectedDam.value = null;
      selectedSire.value = null;
      damIdController.clear();
      sireIdController.clear();
      _lastLoadedCowsGaushalaId = null;
      return;
    }

    if (_lastLoadedCowsGaushalaId == cleanId && allGaushalaCows.isNotEmpty) return;
    _lastLoadedCowsGaushalaId = cleanId;

    isLoadingCows.value = true;
    try {
      final response = await _apiService.getCows(gaushalaId: cleanId);
      final list = response.allCows;
      allGaushalaCows.assignAll(list);

      final females = list.where((c) => c.isFemale).toList();
      final males = list.where((c) => !c.isFemale).toList();

      damCows.assignAll(females.isNotEmpty ? females : list);
      sireCows.assignAll(males.isNotEmpty ? males : list);

      if (isEditMode) {
        if (selectedDam.value == null && editingCow.value?.dam != null) {
          final match = damCows.firstWhereOrNull(
            (c) => c.id == editingCow.value!.dam!.id || c.tagId.toLowerCase() == editingCow.value!.dam!.tagId.toLowerCase(),
          );
          if (match != null) {
            selectedDam.value = match;
          }
        }
        if (selectedSire.value == null && editingCow.value?.sire != null) {
          final match = sireCows.firstWhereOrNull(
            (c) => c.id == editingCow.value!.sire!.id || c.tagId.toLowerCase() == editingCow.value!.sire!.tagId.toLowerCase(),
          );
          if (match != null) {
            selectedSire.value = match;
          }
        }
      }

      if (selectedDam.value != null && !damCows.any((c) => c.id == selectedDam.value!.id)) {
        selectedDam.value = null;
        damIdController.clear();
      }
      if (selectedSire.value != null && !sireCows.any((c) => c.id == selectedSire.value!.id)) {
        selectedSire.value = null;
        sireIdController.clear();
      }
    } catch (_) {
    } finally {
      isLoadingCows.value = false;
    }
  }

  @override
  void onClose() {
    tagIdController.dispose();
    calfNameController.dispose();
    calfWeightController.dispose();
    avatarUrlController.dispose();
    remarkController.dispose();
    damIdController.dispose();
    sireIdController.dispose();
    super.onClose();
  }

  void _loadUser() {
    currentUser.value = _storageService.getUser();
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Future<void> logout() async {
    await _storageService.removeToken();
    await _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }

  // -------------------------------------------------------------------
  // CATALOG LOADING — parallel fetch of breed, gaushala, type, shed
  // -------------------------------------------------------------------
  Future<void> _fetchCatalogs() async {
    isLoadingCatalogs.value = true;
    catalogError.value = '';

    try {
      final results = await Future.wait([
        _apiService.getBreedTypes(),
        _apiService.getGaushalas(),
        _apiService.getTypes(),
        _apiService.getSheds(),
      ]);

      breeds.assignAll(results[0] as List<BreedModel>);
      gaushalas.assignAll(results[1] as List<GaushalaModel>);
      types.assignAll(results[2] as List<TypeModel>);
      sheds.assignAll(results[3] as List<ShedModel>);

      catalogsLoaded.value = true;

      // Pre-select user's gaushala if available
      _preselectGaushala();

      // Fetch cows for Dam and Sire dropdowns if gaushala is selected
      if (selectedGaushala.value != null) {
        await Future.wait([
          fetchShedsForGaushala(selectedGaushala.value!.id),
          fetchCowsForGaushala(selectedGaushala.value!.id),
        ]);
      }

      if (isEditMode) {
        _populateEditSelections();
      } else {
        // If male is already selected when catalogs finish loading, auto-select N/A
        if (!isFemale.value) {
          _autoSelectNaType();
        }
      }
    } catch (e) {
      catalogError.value = 'Failed to load form data. Please try again.';
    } finally {
      isLoadingCatalogs.value = false;
    }
  }

  void _populateEditSelections() {
    final cow = editingCow.value;
    if (cow == null) return;

    if (cow.breed != null) {
      final match = breeds.firstWhereOrNull(
        (b) => b.id == cow.breed!.id || b.breedName.toLowerCase() == cow.breed!.breedName.toLowerCase(),
      );
      if (match != null) {
        selectedBreed.value = match;
      }
    }

    if (cow.cowType != null) {
      final match = types.firstWhereOrNull(
        (t) => t.id == cow.cowType!.id || t.typeName.toLowerCase() == cow.cowType!.typeName.toLowerCase(),
      );
      if (match != null) {
        selectedType.value = match;
      }
    }

    if (cow.shed != null) {
      final match = sheds.firstWhereOrNull(
        (s) => s.id == cow.shed!.id || s.shedName.toLowerCase() == cow.shed!.shedName.toLowerCase(),
      );
      if (match != null) {
        selectedShed.value = match;
      }
    }

    if (cow.dam != null) {
      final match = damCows.firstWhereOrNull(
        (d) => d.id == cow.dam!.id || d.tagId.toLowerCase() == cow.dam!.tagId.toLowerCase(),
      );
      if (match != null) {
        selectedDam.value = match;
      }
    }

    if (cow.sire != null) {
      final match = sireCows.firstWhereOrNull(
        (s) => s.id == cow.sire!.id || s.tagId.toLowerCase() == cow.sire!.tagId.toLowerCase(),
      );
      if (match != null) {
        selectedSire.value = match;
      }
    }
  }

  bool get canChangeGaushala => currentUser.value?.isAdmin ?? false;

  GaushalaModel? findGaushala(String? query) {
    if (query == null || query.trim().isEmpty) return null;
    final q = query.trim().toLowerCase();

    var match = gaushalas.firstWhereOrNull((g) => g.id.toLowerCase() == q);
    if (match != null) return match;

    match = gaushalas.firstWhereOrNull((g) => g.gaushalaName.trim().toLowerCase() == q);
    if (match != null) return match;

    final qNorm = q.replaceAll('_', '').replaceAll(' ', '').replaceAll('-', '');
    match = gaushalas.firstWhereOrNull((g) {
      final nameNorm = g.gaushalaName.toLowerCase().replaceAll('_', '').replaceAll(' ', '').replaceAll('-', '');
      return nameNorm == qNorm;
    });
    if (match != null) return match;

    return null;
  }

  void _preselectGaushala() {
    final user = currentUser.value;
    final isUserAdmin = canChangeGaushala;

    // 0. If in edit mode, strictly select the cow's gaushala
    if (isEditMode && editingCow.value?.gaushala != null) {
      final gId = editingCow.value!.gaushala!.id;
      final gName = editingCow.value!.gaushala!.gaushalaName;
      final match = findGaushala(gId) ?? findGaushala(gName);
      if (match != null) {
        selectedGaushala.value = match;
        return;
      }
    }

    // 1. If non-admin user, strictly pre-select their assigned gaushala
    if (!isUserAdmin) {
      final userGId = user?.gaushalaId;
      final match = findGaushala(userGId);
      if (match != null) {
        selectedGaushala.value = match;
        return;
      }
    }

    // 2. Check if gaushalaId was passed via navigation arguments
    final dynamic args = Get.arguments;
    String? passedGaushalaId;
    if (args is Map && args['gaushalaId'] != null) {
      passedGaushalaId = args['gaushalaId'].toString();
    } else if (args is String && args.isNotEmpty) {
      passedGaushalaId = args;
    }

    if (passedGaushalaId != null && passedGaushalaId.isNotEmpty) {
      final match = findGaushala(passedGaushalaId);
      if (match != null) {
        selectedGaushala.value = match;
        return;
      }
    }

    // 2.5 Check global session gaushala
    if (Get.isRegistered<GaushalaSessionService>()) {
      final globalG = Get.find<GaushalaSessionService>().selectedGaushala.value;
      if (globalG != null) {
        final match = findGaushala(globalG.id);
        if (match != null) {
          selectedGaushala.value = match;
          return;
        }
      }
    }

    // 3. Check user's assigned gaushala (for admin)
    if (user?.gaushalaId != null && user!.gaushalaId!.isNotEmpty) {
      final match = findGaushala(user.gaushalaId);
      if (match != null) {
        selectedGaushala.value = match;
        return;
      }
    }

    // 4. Fallback: If gaushalas exist, select the first one
    if (gaushalas.isNotEmpty) {
      selectedGaushala.value = gaushalas.first;
    }
  }

  void setGender(bool female) {
    isFemale.value = female;
    if (!female) {
      _autoSelectNaType();
    } else {
      if (selectedType.value != null && _isNaType(selectedType.value!)) {
        selectedType.value = null;
      }
    }
  }

  void _autoSelectNaType() {
    if (types.isEmpty) return;
    final naType = types.firstWhereOrNull((t) => _isNaType(t)) ??
        types.firstWhereOrNull((t) => t.typeName.toLowerCase().contains('n/a'));
    if (naType != null) {
      selectedType.value = naType;
    }
  }

  bool _isNaType(TypeModel type) {
    final clean = type.typeName.trim().toLowerCase().replaceAll(' ', '');
    return clean == 'n/a' || clean == 'na' || clean == 'notapplicable';
  }

  Future<void> retryCatalogs() async {
    await _fetchCatalogs();
  }

  // -------------------------------------------------------------------
  // DATE & TIME PICKERS
  // -------------------------------------------------------------------
  Future<void> pickDob(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dob.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );
    if (picked != null) {
      dob.value = picked;
    }
  }

  Future<void> pickPurchaseDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: purchaseDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Purchase Date',
    );
    if (picked != null) {
      purchaseDate.value = picked;
    }
  }

  Future<void> pickSendDiedDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: sendDiedDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Send/Died Date',
    );
    if (picked != null) {
      sendDiedDate.value = picked;
    }
  }

  Future<void> pickDeliveryTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: deliveryTime.value ?? const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Select Delivery Time',
    );
    if (picked != null) {
      deliveryTime.value = picked;
    }
  }

  // -------------------------------------------------------------------
  // FORMATTING HELPERS
  // -------------------------------------------------------------------
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String get dobDisplay => dob.value != null ? DateFormat('dd MMM yyyy').format(dob.value!) : '';
  String get purchaseDateDisplay =>
      purchaseDate.value != null ? DateFormat('dd MMM yyyy').format(purchaseDate.value!) : '';
  String get sendDiedDateDisplay =>
      sendDiedDate.value != null ? DateFormat('dd MMM yyyy').format(sendDiedDate.value!) : '';
  String get deliveryTimeDisplay {
    final t = deliveryTime.value;
    if (t == null) return '';
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // -------------------------------------------------------------------
  // FORM VALIDATION
  // -------------------------------------------------------------------
  bool _validateForm() {
    if (!(formKey.currentState?.validate() ?? false)) {
      return false;
    }

    if (dob.value == null) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please select Date of Birth.',
      );
      return false;
    }

    if (selectedBreed.value == null) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please select a breed.',
      );
      return false;
    }

    if (selectedGaushala.value == null) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please select a gaushala.',
      );
      return false;
    }

    if (!isFemale.value && selectedType.value == null) {
      _autoSelectNaType();
    }

    if (selectedType.value == null) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: isFemale.value ? 'Please select a cow type.' : 'Cow type (N/A) could not be resolved.',
      );
      return false;
    }

    if (selectedShed.value == null) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please select a shed.',
      );
      return false;
    }

    return true;
  }

  // -------------------------------------------------------------------
  // SUBMIT — POST /api/v1/cows
  // -------------------------------------------------------------------
  Future<void> submitAddCow() async {
    if (isSubmitting.value) return; // Prevent duplicate calls

    if (!_validateForm()) return;

    final user = currentUser.value;
    if (user == null || user.id.isEmpty) {
      CustomSnackbar.showError(
        title: 'Authentication Error',
        message: 'Logged-in user not found. Please sign in again.',
      );
      return;
    }

    isSubmitting.value = true;

    final request = AddCowRequestModel(
      breed: selectedBreed.value!.id,
      gaushalaId: selectedGaushala.value!.id,
      type: selectedType.value!.id,
      shedId: selectedShed.value?.id,
      tagId: tagIdController.text.trim().toUpperCase(),
      dob: _formatDate(dob.value),
      calfName: calfNameController.text.trim(),
      isFemale: isFemale.value,
      addedBy: user.id,
      calfWeight: num.tryParse(calfWeightController.text.trim()) ?? 0,
      avatarUrl: avatarUrlController.text.trim(),
      damId: selectedDam.value?.id ?? (damIdController.text.trim().isNotEmpty ? damIdController.text.trim() : null),
      sairId: selectedSire.value?.id ?? (sireIdController.text.trim().isNotEmpty ? sireIdController.text.trim() : null),
      deliveryTime: _formatTime(deliveryTime.value),
      sendDiedDate: _formatDate(sendDiedDate.value),
      purchaseDate: _formatDate(purchaseDate.value),
      remark: remarkController.text.trim(),
    );

    try {
      if (isEditMode) {
        await _apiService.updateCow(editingCow.value!.id, request);
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: 'Cattle updated successfully',
        );
      } else {
        await _apiService.addCow(request);
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: 'Cow added successfully',
        );
        // Reset form after success only in add mode
        _resetForm();
      }

      Future.delayed(const Duration(milliseconds: 700), () {
        if (Get.previousRoute.isNotEmpty &&
            Get.previousRoute != AppRoutes.addCow &&
            Get.previousRoute != AppRoutes.editCow) {
          Get.back(result: true);
        } else {
          Get.offNamed(AppRoutes.cows);
        }
      });
    } on DioException catch (_) {
      // Error snackbar already shown by ApiService._handleHttpError interceptor
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'An unexpected error occurred. Please try again.',
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void _resetForm() {
    formKey.currentState?.reset();
    tagIdController.clear();
    calfNameController.clear();
    calfWeightController.clear();
    avatarUrlController.clear();
    remarkController.clear();
    damIdController.clear();
    sireIdController.clear();
    selectedDam.value = null;
    selectedSire.value = null;
    isFemale.value = true;
    dob.value = null;
    deliveryTime.value = null;
    purchaseDate.value = null;
    sendDiedDate.value = null;
    selectedBreed.value = null;
    selectedType.value = null;
    selectedShed.value = null;
    breedSearchQuery.value = '';
    // Re-select user's gaushala
    _preselectGaushala();
  }

  void cancelForm() {
    if (Get.previousRoute.isNotEmpty && Get.previousRoute != AppRoutes.addCow) {
      Get.back();
    } else {
      Get.offNamed(AppRoutes.cows);
    }
  }
}

