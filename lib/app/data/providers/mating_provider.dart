import 'package:get/get.dart';
import '../models/cow_mating_model.dart';
import '../services/api_service.dart';

/// Provider / Repository layer for Cow Mating operations.
class MatingProvider {
  final ApiService _apiService = Get.find<ApiService>();

  Future<MatingPaginatedResult> getMatings({
    required String gaushalaId,
    String? cowId,
    String? status,
    String? matingType,
    bool? isRepeatBreederAlert,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    int page = 1,
    int limit = 10,
  }) {
    return _apiService.getMatings(
      gaushalaId: gaushalaId,
      cowId: cowId,
      status: status,
      matingType: matingType,
      isRepeatBreederAlert: isRepeatBreederAlert,
      startDate: startDate,
      endDate: endDate,
      search: search,
      page: page,
      limit: limit,
    );
  }

  Future<List<CowMatingModel>> getRepeatBreederAlerts({required String gaushalaId}) {
    return _apiService.getRepeatBreederAlerts(gaushalaId: gaushalaId);
  }

  Future<List<CowMatingModel>> getPendingPDAlerts({required String gaushalaId}) {
    return _apiService.getPendingPDAlerts(gaushalaId: gaushalaId);
  }

  Future<CowMatingModel?> getMatingById(String id) {
    return _apiService.getMatingById(id);
  }

  Future<CowMatingModel> createMating(Map<String, dynamic> data) {
    return _apiService.createMating(data);
  }

  Future<CowMatingModel> updatePDStatus(
    String id, {
    required String pdResult,
    required String pdDate,
    String? pdPerformedBy,
    String? remarks,
  }) {
    return _apiService.updatePDStatus(
      id,
      pdResult: pdResult,
      pdDate: pdDate,
      pdPerformedBy: pdPerformedBy,
      remarks: remarks,
    );
  }

  Future<CowMatingModel> recordCalving(
    String id, {
    required String actualCalvingDate,
    String? remarks,
  }) {
    return _apiService.recordCalving(
      id,
      actualCalvingDate: actualCalvingDate,
      remarks: remarks,
    );
  }

  Future<CowMatingModel> updateMating(String id, Map<String, dynamic> data) {
    return _apiService.updateMating(id, data);
  }

  Future<bool> deleteMating(String id) {
    return _apiService.deleteMating(id);
  }
}
