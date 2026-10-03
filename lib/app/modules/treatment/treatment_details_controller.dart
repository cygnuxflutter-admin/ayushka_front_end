import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../data/models/treatment_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';
import '../notification/notification_controller.dart';
import 'dialogs/administer_dose_dialog.dart';
import 'dialogs/change_status_dialog.dart';
import 'widgets/print_treatment_summary_dialog.dart';

/// Controller for Treatment Case Details & Chronological Dose Stepper Timeline
class TreatmentDetailsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  final Rxn<CowTreatmentModel> treatment = Rxn<CowTreatmentModel>();
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxInt selectedViewTab = 0.obs; // 0: Dose Timeline, 1: Medicine History, 2: Case Details

  final RxBool isSidebarCollapsed = false.obs;
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  String treatmentId = '';

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _storageService.getUser();

    final args = Get.arguments;
    if (args is Map) {
      treatmentId = args['treatmentId']?.toString() ?? '';
      if (args['treatment'] is CowTreatmentModel) {
        treatment.value = args['treatment'] as CowTreatmentModel;
      }
    } else if (Get.parameters.containsKey('id')) {
      treatmentId = Get.parameters['id'] ?? '';
    }

    if (treatmentId.isNotEmpty) {
      loadTreatmentDetails();
    } else if (treatment.value != null) {
      treatmentId = treatment.value!.id;
      isLoading.value = false;
    } else {
      isLoading.value = false;
    }
  }

  void toggleSidebar() {
    isSidebarCollapsed.toggle();
  }

  void logout() {
    _storageService.removeToken();
    _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }

  /// Loads full populated treatment case from backend API
  Future<void> loadTreatmentDetails({bool isSilent = false}) async {
    if (treatmentId.isEmpty) return;

    if (!isSilent) isLoading.value = true;

    try {
      final t = await _apiService.getTreatmentById(treatmentId);
      if (t != null) {
        treatment.value = t;
      } else {
        CustomSnackbar.showError(
          title: 'Not Found',
          message: 'Treatment case could not be retrieved',
        );
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to fetch treatment case details',
      );
    } finally {
      if (!isSilent) isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshDetails() async {
    isRefreshing.value = true;
    await loadTreatmentDetails(isSilent: true);
  }

  /// Opens the administer dose dialog for a specific dose number
  Future<void> administerDose(BuildContext context, int doseNumber) async {
    final t = treatment.value;
    if (t == null) return;

    final updated = await AdministerDoseDialog.show(
      context,
      treatment: t,
      doseNumber: doseNumber,
    );

    if (updated == true) {
      await loadTreatmentDetails(isSilent: true);
      // Synchronize notifications
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().fetchUnreadCount();
      }
    }
  }

  /// Opens status change dialog
  Future<void> changeStatus(BuildContext context) async {
    final t = treatment.value;
    if (t == null) return;

    final updated = await ChangeStatusDialog.show(
      context,
      treatment: t,
    );

    if (updated == true) {
      await loadTreatmentDetails(isSilent: true);
    }
  }

  /// Opens print & export medical summary modal
  void printMedicalSummary(BuildContext context) {
    final t = treatment.value;
    if (t == null) return;
    PrintTreatmentSummaryDialog.show(context, treatment: t);
  }

  void backToTreatments() {
    if (Get.previousRoute.isNotEmpty && Get.previousRoute != AppRoutes.initial) {
      Get.back();
    } else {
      Get.offNamed(AppRoutes.treatments);
    }
  }
}
