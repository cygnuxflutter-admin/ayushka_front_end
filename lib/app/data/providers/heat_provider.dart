import 'package:get/get.dart';
import '../models/cow_heat_model.dart';
import '../services/api_service.dart';

/// Provider / Repository layer for Cow Heat operations.
class HeatProvider {
  final ApiService _apiService = Get.find<ApiService>();

  Future<HeatPaginatedResult> getHeats({
    required String gaushalaId,
    String? cowId,
    String? status,
    String? heatStage,
    String? intensity,
    bool? isRepeatHeatAlert,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    int page = 1,
    int limit = 10,
  }) {
    return _apiService.getHeats(
      gaushalaId: gaushalaId,
      cowId: cowId,
      status: status,
      heatStage: heatStage,
      intensity: intensity,
      isRepeatHeatAlert: isRepeatHeatAlert,
      startDate: startDate,
      endDate: endDate,
      search: search,
      page: page,
      limit: limit,
    );
  }

  Future<List<CowHeatModel>> getActiveHeatAlerts({required String gaushalaId}) {
    return _apiService.getActiveHeatAlerts(gaushalaId: gaushalaId);
  }

  Future<List<CowHeatModel>> getRepeatHeatAlerts({required String gaushalaId}) {
    return _apiService.getRepeatHeatAlerts(gaushalaId: gaushalaId);
  }

  Future<CowHeatModel?> getHeatById(String id) {
    return _apiService.getHeatById(id);
  }

  Future<CowHeatModel> createHeat(Map<String, dynamic> data) {
    return _apiService.createHeat(data);
  }

  Future<CowHeatModel> updateHeat(String id, Map<String, dynamic> data) {
    return _apiService.updateHeat(id, data);
  }

  Future<bool> deleteHeat(String id) {
    return _apiService.deleteHeat(id);
  }
}
