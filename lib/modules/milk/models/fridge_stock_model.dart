/// Model representing remaining fridge/leftover milk stock for past dates
/// Endpoint: GET /api/v1/milk/fridge-stock?gaushalaId={id}
class FridgeStockModel {
  final String milkDate;
  final String gaushalaId;
  final double totalProduced;
  final double totalDistributed;
  final double totalDisposed;
  final double remainingFridgeMilk;

  const FridgeStockModel({
    required this.milkDate,
    this.gaushalaId = '',
    this.totalProduced = 0.0,
    this.totalDistributed = 0.0,
    this.totalDisposed = 0.0,
    this.remainingFridgeMilk = 0.0,
  });

  factory FridgeStockModel.fromJson(Map<String, dynamic> json) {
    return FridgeStockModel(
      milkDate: json['milkDate']?.toString() ?? json['date']?.toString() ?? '',
      gaushalaId: json['gaushalaId']?.toString() ?? json['gaushala_id']?.toString() ?? '',
      totalProduced: _toDouble(json['totalProduced'] ?? json['total_produced']),
      totalDistributed: _toDouble(json['totalDistributed'] ?? json['total_distributed']),
      totalDisposed: _toDouble(json['totalDisposed'] ?? json['total_disposed']),
      remainingFridgeMilk: _toDouble(json['remainingFridgeMilk'] ?? json['remaining_fridge_milk'] ?? json['remainingStock'] ?? json['remaining_stock']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'milkDate': milkDate,
      'gaushalaId': gaushalaId,
      'totalProduced': totalProduced,
      'totalDistributed': totalDistributed,
      'totalDisposed': totalDisposed,
      'remainingFridgeMilk': remainingFridgeMilk,
    };
  }
}

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}
